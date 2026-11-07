"""Prepare deferred motion-vector shader replacements from FusionShaders."""
import argparse
import re
import shutil
from pathlib import Path
import xml.etree.ElementTree as ET


# Decompilation errors of the reference set, checked against the original bytecode
CORRECTIONS = [
    # Plant collision spheres keep their radius in w
    (re.compile(r'(g_vCollisionSpheres\[[^\]]+\])\.x\b'), r'\1.w'),
]


def repair(source):
    for pattern, replacement in CORRECTIONS:
        source = pattern.sub(replacement, source)
    return source


def read(path):
    return repair(Path(path).read_text(encoding='utf8'))


def structure(source, name, field):
    pattern = rf'(struct {name}\s*\{{)(.*?)(\n\}};)'
    source, count = re.subn(pattern, lambda m: m[1] + m[2] + '\n\t' + field + m[3], source, flags=re.S)
    if count != 1:
        raise ValueError(f'Missing structure {name}')
    return source


def uniform_rows(kind, count):
    matrix = re.fullmatch(r'\w+(\d)x(\d)', kind)
    return (int(matrix[1]) if matrix else 1) * count


def buffer_slot(source):
    occupied = {int(slot) for slot in re.findall(r'register\(b(\d+)\)', source)}
    return next(slot for slot in range(13, -1, -1) if slot not in occupied)


def previous_uniforms(source):
    fields = []
    blocks = re.finditer(r'cbuffer \w+\s*:\s*register\(b(\d+)\)\s*\{(.*?)\};', source, re.S)
    for block in blocks:
        for m in re.finditer(r'(?:(row_major)\s+)?((?:float|int|uint|bool)\w*)\s+(\w+)(?:\[(\d+)\])?\s*:\s*packoffset\(c(\d+)(?:\.([xyzw]))?\)', block[2]):
            offset = int(m[5]) * 16 + 'xyzw'.index(m[6] or 'x') * 4
            fields.append((m[1], m[2], m[3], int(m[4] or 1), f'b{block[1]}_o{offset}'))
    declarations, replacements, row = ['\tfloat4 TemporalState : packoffset(c0);'], {}, 1
    for major, kind, name, count, origin in fields:
        previous = f'Temporal_{origin}_{name}'
        array = f'[{count}]' if count > 1 else ''
        declarations.append(f'\t{major + " " if major else ""}{kind} {previous}{array} : packoffset(c{row});')
        replacements[name] = previous
        row += uniform_rows(kind, count)
    resources = []
    occupied = {int(slot) for slot in re.findall(r'register\(t(\d+)\)', source)}
    for resource in re.finditer(r'((?:Texture\w*|Buffer|StructuredBuffer)\s*(?:<[^>]+>)?)\s+(\w+)\s*:\s*register\(t(\d+)\)\s*;', source):
        slot = next(slot for slot in range(127, -1, -1) if slot not in occupied)
        occupied.add(slot)
        name = f'TemporalResource_t{resource[3]}_{resource[2]}'
        resources.append(f'{resource[1]} {name} : register(t{slot});')
        replacements[resource[2]] = name
    if row > 4096:
        raise ValueError('Previous constants exceed the constant-buffer limit')
    return f'cbuffer TemporalPrevious : register(b{buffer_slot(source)})\n{{\n' + '\n'.join(declarations) + '\n};\n' + '\n'.join(resources) + '\n', replacements


def replace_uniforms(body, replacements):
    for name in sorted(replacements, key=len, reverse=True):
        body = re.sub(rf'\b{name}\b', replacements[name], body)
    return body


def structured_input(source):
    entry = re.search(r'(\w+)\s+main\((.*?)\)\s*\{', source, re.S)
    if not entry or ':' not in entry[2]:
        return source
    fields = [part.strip() for part in entry[2].split(',')]
    names = [re.search(r'(\w+)\s*:', part)[1] for part in fields]
    source = source[:entry.start()] + 'struct TemporalInput\n{\n' + '\n'.join('\t' + field + ';' for field in fields) + '\n};\n\n' + source[entry.start():]
    source = re.sub(r'\bmain\(.*?\)\s*\{', 'main(TemporalInput i)\n{', source, count=1, flags=re.S)
    start = source.index('main(TemporalInput i)')
    body = source[start:]
    for name in names:
        body = re.sub(rf'(?<![.\w]){name}\b', 'i.' + name, body)
    return source[:start] + body


def prior_attributes(source, name):
    fields = re.search(rf'struct {name}\s*\{{(.*?)\}};', source, re.S)[1]
    return [(kind, field) for kind, field in re.findall(r'(float\d?)\s+(\w+)\s*:', fields)]


def carry_attributes(source, name, fields):
    return structure(source, name, '\n\t'.join(f'{kind} temporalInput_{field} : TEMPORAL{i};' for i, (kind, field) in enumerate(fields)))


def vertex(source, tessellation=None):
    source = structured_input(source)
    match = re.search(r'(\w+)\s+main\((\w+)\s+(\w+)\)\s*\{', source)
    if not match:
        raise ValueError('Unsupported vertex entry point')
    output, argument_type, argument = match.groups()
    body = source[match.start():]
    if body.count('return o;') != 1 or not body.rstrip().endswith('}'):
        raise ValueError('Unsupported vertex function body')
    header = source[:match.start()]
    original_fields = dict((field, kind) for kind, field in prior_attributes(source, output))
    fields = prior_attributes(tessellation, 'HS_IN') if tessellation else []
    if fields:
        original = re.search(rf'struct {output}\s*\{{.*?\}};', header, re.S)[0]
        canonical = re.search(r'struct HS_IN\s*\{.*?\};', tessellation, re.S)[0].replace('struct HS_IN', f'struct {output}', 1)
        header = header.replace(original, original.replace(f'struct {output}', 'struct TemporalVertexResult', 1) + '\n' + canonical)
    position = re.search(rf'struct {output}\s*\{{.*?float4 (\w+)\s*:\s*(?:SV_Position|POSITION)\s*;', header, re.S)
    if not position and not re.search(r'\bgWorldViewProj\b', header):
        header = header.replace('cbuffer rage_matrices : register(b0)\n{',
            'cbuffer rage_matrices : register(b0)\n{\n\trow_major float4x4 gWorldViewProj : packoffset(c8);')
    previous, replacements = previous_uniforms(header)
    header = structure(header, output, 'float3 temporalPrevious : TEXCOORD15;')
    if fields:
        header = carry_attributes(header, output, fields)
    current = body.replace('main(', 'TemporalCurrent(', 1)
    previous_body = replace_uniforms(body.replace('main(', 'TemporalVertexPrevious(', 1), replacements)
    if fields:
        current = re.sub(rf'\b{output}\b', 'TemporalVertexResult', current)
        previous_body = re.sub(rf'\b{output}\b', 'TemporalVertexResult', previous_body)
    if position:
        previous_position = f'TemporalVertexPrevious({argument}).{position[1]}'
    else:
        if not re.search(r'float4 texcoord8\s*:\s*TEXCOORD8;', header):
            raise ValueError('Unsupported pre-tessellation position')
        previous_position = f'mul(TemporalVertexPrevious({argument}).texcoord8, {replacements["gWorldViewProj"]})'
    evaluation = f'o.temporalPrevious = {previous_position}.xyw;'
    initialize = ''
    current_evaluation = f'{output} o = TemporalCurrent({argument});'
    if fields:
        def convert(kind, field, result):
            original = original_fields.get(field)
            if not original:
                return '0'
            value = f'{result}.{field}'
            if original == kind:
                return value
            old, new = int(original[5:] or 1), int(kind[5:] or 1)
            return f'{kind}({value}, ' + ', '.join('0' for _ in range(new - old)) + ')' if old < new else value + '.' + 'xyzw'[:new]
        current_evaluation = f'TemporalVertexResult c = TemporalCurrent({argument});\n    {output} o;\n' + '\n'.join(f'    o.{field} = {convert(kind, field, "c")};' for kind, field in fields)
        initialize = '\n'.join(f'    o.temporalInput_{field} = o.{field};' for _, field in fields)
        evaluation = f'TemporalVertexResult p = TemporalVertexPrevious({argument});\n' + '\n'.join(f'        o.temporalInput_{field} = {convert(kind, field, "p")};' for kind, field in fields) + f'\n        o.temporalPrevious = {previous_position.replace(f"TemporalVertexPrevious({argument})", "p")}.xyw;'
    wrapper = f'''{output} main({argument_type} {argument})
{{
    {current_evaluation}
    o.temporalPrevious = float3(0, 0, -1);
{initialize}
    [branch] if (TemporalState.x > 0)
    {{
        {evaluation}
    }}
    return o;
}}
'''
    return header + previous + '\n' + current + '\n' + previous_body + '\n' + wrapper


def pixel(source):
    source = structured_input(source)
    match = re.search(r'(\w+)\s+main\((\w+)\s+(\w+)\)', source)
    if not match or source.count('return o;') != 1:
        raise ValueError('Unsupported deferred pixel entry point')
    output, argument_type, argument = match.groups()
    source = structure(source, argument_type, 'float3 temporalPrevious : TEXCOORD15;')
    source = structure(source, output, 'float2 temporalVelocity : SV_Target4;')
    position = re.search(r'float4 (\w+)\s*:\s*SV_Position\s*;', source)[1]
    params = f'cbuffer TemporalPixel : register(b{buffer_slot(source)}) {{ float4 TemporalSizeJitter; }};\n'
    motion = f'''float w = {argument}.temporalPrevious.z;
    float2 previousUV = {argument}.temporalPrevious.xy / (abs(w) > 0.000001 ? w : 0.000001) * float2(0.5, -0.5) + 0.5;
    float2 currentUV = {argument}.{position}.xy * TemporalSizeJitter.xy;
    o.temporalVelocity = float2(2, 2);
    if (TemporalSizeJitter.x > 0)
        o.temporalVelocity = w > 0 ? previousUV - currentUV + TemporalSizeJitter.zw : float2(2, 2);
    return o;'''
    return params + source.replace('return o;', motion)


def hull(source, fields):
    for name in ('HS_IN', 'HS_OUT'):
        source = structure(source, name, 'float3 temporalPrevious : TEXCOORD15;')
        source = carry_attributes(source, name, fields)
    return source.replace('o.texcoord8 = patch[sv_outputcontrolpointid].texcoord8;',
        'o.texcoord8 = patch[sv_outputcontrolpointid].texcoord8;\n\to.temporalPrevious = patch[sv_outputcontrolpointid].temporalPrevious;\n' + '\n'.join(f'\to.temporalInput_{field} = patch[sv_outputcontrolpointid].temporalInput_{field};' for _, field in fields))


def domain(source, hull_source, pixel_sources, previous_fields):
    original_fields = dict((field, kind) for kind, field in prior_attributes(source, 'DS_IN'))
    fields = re.search(r'struct HS_OUT\s*\{(.*?)\};', hull_source, re.S)[1]
    source = re.sub(r'(struct DS_IN\s*\{).*?(\};)', lambda m: m[1] + fields + '\n' + m[2], source, count=1, flags=re.S)
    for kind, field in prior_attributes(source, 'DS_IN'):
        original = original_fields.get(field)
        if original and original != kind:
            swizzle = 'xyzw'[:int(original[5:] or 1)]
            source = re.sub(rf'(patch\[[^]]+\]\.{field})\b', rf'\1.{swizzle}', source)
    required = set()
    for pixel_source in pixel_sources:
        entry = re.search(r'\w+\s+main\((\w+)\s+\w+\)', pixel_source)
        required |= {semantic.upper() for semantic in re.findall(r':\s*(\w+)\s*;', re.search(rf'struct {entry[1]}\s*\{{(.*?)\}};', pixel_source, re.S)[1])}
    output = re.search(r'struct DS_OUT\s*\{(.*?)\};', source, re.S)
    fields = output[1]
    for field in re.finditer(r'\s*\w+\s+(\w+)\s*:\s*(\w+)\s*;', output[1]):
        if field[2].upper() not in required:
            fields = fields.replace(field[0], '')
            source = re.sub(rf'\bo\.{field[1]}\s*=.*?;', '', source)
    source = source[:output.start(1)] + fields + source[output.end(1):]
    fields = previous_fields
    for name in ('DS_IN', 'DS_OUT'):
        source = structure(source, name, 'float3 temporalPrevious : TEXCOORD15;')
    source = carry_attributes(source, 'DS_IN', fields)
    match = re.search(r'(\w+) main\((.*?)\)\s*\{', source, re.S)
    header = source[:match.start()].replace('[domain("tri")]', '')
    declarations, replacements = previous_uniforms(header)
    body = source[match.start():]
    previous = replace_uniforms(body.replace('main(', 'TemporalDomainPrevious(', 1), replacements)
    for _, field in fields:
        previous = re.sub(rf'(patch\[[^]]+\]\.){field}\b', rf'\1temporalInput_{field}', previous)
    wrapper = f'''[domain("tri")]
{match[1]} main({match[2]})
{{
    {match[1]} o = TemporalDomainCurrent(constants, sv_domainlocation, patch);
    o.temporalPrevious = float3(0, 0, -1);
    [branch] if (TemporalState.x > 0 && patch[0].temporalPrevious.z > 0)
        o.temporalPrevious = TemporalDomainPrevious(constants, sv_domainlocation, patch).sv_position.xyw;
    return o;
}}
'''
    return header + declarations + body.replace('main(', 'TemporalDomainCurrent(', 1) + '\n' + previous + '\n' + wrapper


def semantics(source):
    output = re.search(r'(\w+)\s+main\(', source)[1]
    fields = re.search(rf'struct {output}\s*\{{(.*?)\}};', source, re.S)[1]
    return {semantic.upper() for semantic in re.findall(r':\s*(\w+)\s*;', fields)}


def prune_pixel_inputs(source, available):
    source = structured_input(source)
    entry = re.search(r'\w+\s+main\((\w+)\s+(\w+)\)', source)
    if not entry:
        return source
    structure_name, argument = entry.groups()
    structure = re.search(rf'struct {structure_name}\s*\{{(.*?)\}};', source, re.S)
    fields = structure[1]
    for field in re.finditer(r'\s*\w+\s+(\w+)\s*:\s*(\w+)\s*;', structure[1]):
        name, semantic = field.groups()
        if semantic.upper() not in available and not semantic.upper().startswith('SV_') and not re.search(rf'\b{argument}\.{name}\b', source[entry.end():]):
            fields = fields.replace(field[0], '')
    return source[:structure.start(1)] + fields + source[structure.end(1):]


def prepare(reference, destination, profiles):
    total = [0, 0, 0]
    for profile in profiles:
        for xml in sorted((reference / profile).glob('*.fxc.xml')):
            doc = ET.parse(xml).getroot()
            groups = {g.get('Stage'): list(g.find('Shaders')) for g in doc.findall('./ShaderGroups/Group')}
            all_passes = doc.findall('./Techniques/Technique/Pass')
            passes = [p for t in doc.findall('./Techniques/Technique') if 'deferred' in t.get('Name', '').lower() for p in t.findall('Pass')]
            if not passes:
                continue
            pixels = {p.get('PS') for p in passes}
            passes = [p for p in all_passes if p.get('PS') in pixels]
            passes = [p for p in passes if int(p.get('PS', '0')) and re.search(
                r':\s*SV_Target3\s*;',
                read(xml.parent / groups['Pixel'][int(p.get('PS')) - 1].get('File')))]
            if not passes:
                continue
            if any(int(p.get('GS', '0')) for p in passes):
                raise ValueError(f'Geometry deferred pass requires explicit handling: {xml}')
            shaders = {}
            for stage, key, transform in [('Vertex', 'VS', vertex), ('Pixel', 'PS', pixel), ('Hull', 'HS', hull), ('Domain', 'DS', domain)]:
                for index in sorted({int(p.get(key)) - (stage != 'Vertex') for p in passes if stage == 'Vertex' or int(p.get(key, '0'))}):
                    path = groups[stage][index].get('File')
                    try:
                        source = read(xml.parent / path)
                        if stage == 'Pixel':
                            available = None
                            for p in passes:
                                if int(p.get('PS')) - 1 != index:
                                    continue
                                before = groups['Domain'][int(p.get('DS')) - 1] if int(p.get('DS', '0')) else groups['Vertex'][int(p.get('VS'))]
                                output_semantics = semantics(read(xml.parent / before.get('File')))
                                available = output_semantics if available is None else available & output_semantics
                            source = prune_pixel_inputs(source, available)
                        tessellated = stage == 'Vertex' and any(int(p.get('VS')) == index and int(p.get('DS', '0')) for p in passes)
                        if stage == 'Domain':
                            hull_index = next(int(p.get('HS')) - 1 for p in passes if int(p.get('DS', '0')) - 1 == index)
                            hull_source = read(xml.parent / groups['Hull'][hull_index].get('File'))
                            pixel_sources = [shaders[groups['Pixel'][int(p.get('PS')) - 1].get('File')] for p in passes if int(p.get('DS', '0')) - 1 == index]
                            shaders[path] = domain(source, hull_source, pixel_sources, prior_attributes(hull_source, 'HS_IN'))
                        elif stage == 'Hull':
                            shaders[path] = hull(source, prior_attributes(source, 'HS_IN'))
                        else:
                            hull_source = None
                            if tessellated:
                                hull_index = next(int(p.get('HS')) - 1 for p in passes if int(p.get('VS')) == index and int(p.get('HS', '0')))
                                hull_source = read(xml.parent / groups['Hull'][hull_index].get('File'))
                            shaders[path] = vertex(source, hull_source) if stage == 'Vertex' else transform(source)
                    except (ValueError, TypeError, KeyError) as error:
                        raise ValueError(f'{xml.parent / path}: {error}') from error
                    if stage in ('Vertex', 'Pixel'):
                        total[1 if stage == 'Vertex' else 2] += 1
            for shader in groups['Pixel']:
                path = shader.get('File')
                if Path(path).stem == 'PS_BlitFakedGbuf':
                    source = read(xml.parent / path)
                    output = re.search(r'(\w+)\s+main\(', source)[1]
                    source = structure(source, output, 'float2 temporalVelocity : SV_Target4;')
                    shaders[path] = source.replace('return o;', 'o.temporalVelocity = float2(2, 2);\n\treturn o;')
            target = destination / profile
            folder = xml.name.removesuffix('.fxc.xml')
            base_profile = re.match(r'win32_\d+', profile)[0]
            if profile != base_profile:
                target.mkdir(parents=True, exist_ok=True)
                for group in groups.values():
                    for shader in group:
                        path = shader.get('File')
                        source = shaders.get(path)
                        if source is None:
                            source = read(xml.parent / path)
                        shared = destination / base_profile / path
                        if shared.exists() and shared.read_text(encoding='utf8') == source:
                            shader.set('File', f'../{base_profile}/{path}')
                        else:
                            output = target / path
                            output.parent.mkdir(parents=True, exist_ok=True)
                            output.write_text(source, encoding='utf8')
                ET.indent(doc, space='  ')
                ET.ElementTree(doc).write(target / xml.name, encoding='utf-8', xml_declaration=True)
                total[0] += 1
                continue
            def copy_missing(source, target):
                if Path(source).suffix == '.hlsl' and read(source) != Path(source).read_text(encoding='utf8'):
                    Path(target).write_text(read(source), encoding='utf8')
                elif not Path(target).exists():
                    shutil.copy2(source, target)
                return target
            shutil.copytree(xml.parent / folder, target / folder, dirs_exist_ok=True, copy_function=copy_missing)
            copy_missing(xml, target / xml.name)
            for path, source in shaders.items():
                output = target / path
                if output.read_text(encoding='utf8') != source:
                    output.write_text(source, encoding='utf8')
            total[0] += 1
    print(f'{total[0]} containers, {total[1]} vertex shaders, {total[2]} pixel shaders')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('reference', type=Path)
    parser.add_argument('destination', type=Path)
    parser.add_argument('--profiles', nargs='+', choices=['win32_50', 'win32_50_LQ', 'win32_50_displacement'], default=['win32_50', 'win32_50_LQ', 'win32_50_displacement'])
    args = parser.parse_args()
    prepare(args.reference, args.destination, args.profiles)
