"""Repair and compile-check exported HLSL against the original RAGE containers.

Uses the original DXBC RDEF / DX9 CTAB, without a decompiler. Outputs and compile
cache belong outside the source tree. Requires Windows' d3dcompiler_47.dll.
"""
import argparse
import collections
import concurrent.futures
import ctypes as C
import hashlib
import json
from pathlib import Path
import re
import struct
import threading
import xml.etree.ElementTree as ET


class Reader:
    def __init__(self, data):
        self.data, self.pos = data, 0

    def take(self, count):
        value = self.data[self.pos:self.pos + count]
        self.pos += count
        if len(value) != count:
            raise ValueError("Truncated container")
        return value

    def integer(self, size):
        return int.from_bytes(self.take(size), "little")

    def string(self):
        count = self.integer(1)
        return self.take(count)[:-1].decode() if count else ""


def read_container(data, modern, metadata=False):
    r = Reader(data)
    if r.take(4) != b"rgxe":
        raise ValueError("Not a RAGE effect")
    r.take(4)
    for _ in range(r.integer(1)):
        r.string()
        r.take(5)
    shaders, code_spans = [], []
    for stage in range(6):
        count = r.integer(1)
        if stage:
            if not count:
                count = r.integer(1)
            r.string()
            r.take(6 if modern else 5)
            count -= 1
        for _ in range(count):
            name = r.string() or r.string()
            for _ in range(r.integer(1)):
                r.string()
            if modern:
                for _ in range(r.integer(1)):
                    r.string()
                    r.take(2)
            start = r.pos
            shaders.append((stage, name, r.take(r.integer(4))))
            code_spans.append((start, r.pos))
    for _ in range(2):
        for _ in range(r.integer(1)):
            r.take(16 if modern else 8)
            r.string()
        for _ in range(r.integer(1)):
            r.take(4)
            r.string()
            r.string()
            r.take(8)
            for _ in range(r.integer(1)):
                r.string()
                kind = r.integer(1)
                r.take(4) if kind < 2 else r.string()
            r.take(4 * r.integer(1))
    for _ in range(r.integer(1)):
        r.string()
        for _ in range(r.integer(1)):
            r.take(6)
            r.take(8 * r.integer(1))
    if r.pos != len(data):
        raise ValueError("Container layout does not consume all bytes")
    if metadata:
        parts, cursor = [], 0
        for start, end in code_spans:
            parts.extend([data[cursor:start], b'\0\0\0\0'])
            cursor = end
        parts.append(data[cursor:])
        return shaders, b''.join(parts)
    return shaders


def container_shaders(data, metadata=False):
    try:
        return read_container(data, True, metadata)
    except (ValueError, UnicodeError, IndexError):
        return read_container(data, False, metadata)


def cstring(data, offset):
    return data[offset:data.index(b"\0", offset)].decode()


def reflected_type(data, offset):
    fields = list(struct.unpack_from('<6H', data, offset))
    members = []
    table = struct.unpack_from('<I', data, offset + 12)[0]
    for i in range(fields[5]):
        name, member_type, position = struct.unpack_from('<3I', data, table + i * 12)
        members.append([cstring(data, name), position, reflected_type(data, member_type)])
    return dict(fields=fields, members=members)


def reflection(data):
    if data[:4] != b"DXBC":
        return legacy_reflection(data)
    count = struct.unpack_from("<I", data, 28)[0]
    for offset in struct.unpack_from("<" + "I" * count, data, 32):
        if data[offset:offset + 4] == b"RDEF":
            r = data[offset + 8:offset + 8 + struct.unpack_from("<I", data, offset + 4)[0]]
            break
    else:
        raise ValueError("DXBC has no RDEF")
    cb_count, cb_offset, res_count, res_offset, target = struct.unpack_from("<5I", r)
    resources, buffers = [], []
    for i in range(res_count):
        name, kind, ret, dimension, samples, slot, length, flags = struct.unpack_from("<8I", r, res_offset + i * 32)
        resources.append(dict(name=cstring(r, name), kind=kind, slot=slot, count=length,
                              dimension=dimension, ret=ret, samples=samples))
    stride = 40 if (target & 0xffff) >= 0x500 else 24
    for i in range(cb_count):
        name, var_count, var_offset, size, flags, kind = struct.unpack_from("<6I", r, cb_offset + i * 24)
        variables = []
        for j in range(var_count):
            vname, start, vsize, vflags, vtype, default = struct.unpack_from("<6I", r, var_offset + j * stride)
            variables.append(dict(name=cstring(r, vname), offset=start, size=vsize, used=bool(vflags & 2),
                                  type=reflected_type(r, vtype)))
        buffers.append(dict(name=cstring(r, name), kind=kind, size=size, variables=variables))
    return dict(modern=True, resources=resources, buffers=buffers)


def shader_profile(data):
    if data[:4] == b'DXBC':
        count = struct.unpack_from('<I', data, 28)[0]
        for offset in struct.unpack_from('<' + 'I' * count, data, 32):
            if data[offset:offset + 4] in (b'SHDR', b'SHEX'):
                version = struct.unpack_from('<I', data, offset + 8)[0]
                return ['ps', 'vs', 'gs', 'hs', 'ds', 'cs'][version >> 16] + '_' + str((version >> 4) & 15) + '_' + str(version & 15)
        raise ValueError('DXBC has no shader program')
    version = struct.unpack_from('<I', data)[0]
    return ('vs' if version >> 16 == 0xfffe else 'ps') + '_' + str((version >> 8) & 255) + '_' + str(version & 255)


def legacy_reflection(data):
    # CTAB offsets are relative to the header just after the CTAB FourCC.
    pos = 4
    while pos + 4 <= len(data):
        token = struct.unpack_from("<I", data, pos)[0]
        if token & 0xffff == 0xfffe:
            words = (token >> 16) & 0x7fff
            if data[pos + 4:pos + 8] == b"CTAB":
                r = data[pos + 8:pos + 4 + words * 4]
                count, offset = struct.unpack_from("<2I", r, 12)
                constants = []
                for i in range(count):
                    name, register_set, slot, length, reserved, type_offset, default = struct.unpack_from("<I4H2I", r, offset + i * 20)
                    constants.append(dict(name=cstring(r, name), register_set=register_set, slot=slot, count=length,
                                          type=list(struct.unpack_from('<6H', r, type_offset))))
                return dict(modern=False, constants=constants)
            pos += 4 + words * 4
        elif token & 0xffff == 0xffff:
            break
        else:
            # SM3 instruction token contains the number of operand words.
            pos += 4 * (1 + ((token >> 24) & 15))
    raise ValueError("DX9 shader has no CTAB")


DECL = re.compile(r"^(?P<indent>[ \t]*)(?P<body>(?:(?:row_major|column_major|uniform|globallycoherent)\s+)*"
                  r"(?P<type>\w+(?:<[^;]+?>)?)\s+(?P<name>\w+)(?P<array>\s*\[[^\]]+\])?)"
                  r"(?:\s*:\s*(?:register|packoffset)\([^)]*\))?\s*;[ \t]*$")
CB = re.compile(r"^\s*(cbuffer|tbuffer)\s+(\w+)(?:\s*:\s*register\([^)]*\))?\s*$")


def declarations(lines):
    depth, active, pending = 0, None, None
    found, blocks = {}, {}
    for i, line in enumerate(lines):
        cb = CB.match(line)
        if cb and depth == 0:
            pending = cb[2]
            blocks[pending] = i
        match = DECL.match(line)
        if match and (depth == 0 or active is not None and depth == 1):
            if match['name'] in found:
                raise ValueError("Ambiguous declaration: " + match['name'])
            found[match['name']] = (i, match, active)
        if '{' in line and depth == 0 and pending:
            active, pending = pending, None
        depth += line.count('{') - line.count('}')
        if depth == 0:
            active = None
    return found, blocks


def packoffset(offset):
    return "c" + str(offset // 16) + ("." + "xyzw"[(offset % 16) // 4] if offset % 16 else "")


def repair(text, info):
    lines = text.splitlines()
    found, blocks = declarations(lines)
    if not info['modern']:
        for constant in info['constants']:
            if constant['name'] not in found:
                continue
            i, match, block = found[constant['name']]
            register = "bics"[constant['register_set']] + str(constant['slot'])
            lines[i] = match['indent'] + match['body'] + " : register(" + register + ");"
        repaired = "\n".join(lines) + "\n"
        for constant in info['constants']:
            # A relative c-register access addresses a whole matrix row. The
            # old export represented this as scalar component indexing in the
            # first row, which also let fxc drop the remaining three registers.
            kind, base_type, rows, columns, elements, members = constant['type']
            if kind == 2 and columns == 4 and elements <= 1:
                repaired = re.sub(r'\b' + re.escape(constant['name']) + r'\[0\]\[(a0(?:\.[xyzw])?)\]',
                                  constant['name'] + r'[\1]', repaired)
        return repaired
    resources = {(r['kind'], r['name']): r for r in info['resources']}
    for resource in info['resources']:
        kind, name = resource['kind'], resource['name']
        if kind in (0, 1):
            continue
        name = re.sub(r"\[0\]$", "", name)
        candidates = [name + '_tex', name] if kind == 2 else [name, name + '_s'] if kind == 3 else [name]
        item = next((found[n] for n in candidates if n in found and
                     ((found[n][1]['type'].startswith('Sampler')) == (kind == 3))), None)
        if item is None:
            raise ValueError("Resource declaration missing: " + resource['name'])
        i, match, block = item
        letter = 's' if kind == 3 else 't' if kind in (2, 5, 7) else 'u'
        lines[i] = match['indent'] + match['body'] + " : register(" + letter + str(resource['slot']) + ");"
    for buffer in info['buffers']:
        if buffer['kind'] not in (0, 1):
            continue
        resource = resources.get((buffer['kind'], buffer['name']))
        if resource is None:
            # Unbound/unused buffers need not exist in the generated program.
            continue
        members, occupied = [], []
        for variable in buffer['variables']:
            item = found.get(variable['name'])
            if item is None:
                if variable['used']:
                    raise ValueError("Required constant declaration missing: " + variable['name'])
                continue
            i, match, block = item
            members.append('\t' + match['body'] + ' : packoffset(' + packoffset(variable['offset']) + ');')
            occupied.append((i, block))
        if not members:
            continue
        existing = {block for i, block in occupied if block is not None}
        global_members = [i for i, block in occupied if block is None]
        if len(existing) > 1 or existing and global_members:
            raise ValueError("Constants from one original buffer appear in multiple scopes: " + buffer['name'])
        keyword, letter = ('cbuffer', 'b') if buffer['kind'] == 0 else ('tbuffer', 't')
        header = keyword + ' ' + (next(iter(existing)) if existing else buffer['name'].replace('$', '_'))
        header += ' : register(' + letter + str(resource['slot']) + ')'
        if existing:
            lines[blocks[next(iter(existing))]] = header
            for (i, block), member in zip(occupied, members):
                lines[i] = member
        else:
            for i, block in occupied:
                lines[i] = None
            lines[min(global_members)] = '\n'.join([header, '{', *members, '};'])
    return '\n'.join(line for line in lines if line is not None) + '\n'


P = C.c_void_p


def method(obj, index, result, *args):
    return C.WINFUNCTYPE(result, P, *args)(C.cast(obj, C.POINTER(C.POINTER(P))).contents[index])


def blob(obj):
    return C.string_at(method(obj, 3, P)(obj), method(obj, 4, C.c_size_t)(obj))


def compile_source(source, profile, compiler):
    code, errors = P(), P()
    hr = compiler(source, len(source), None, None, None, b'main', profile.encode(), 0, 0,
                  C.byref(code), C.byref(errors))
    try:
        if hr < 0:
            raise ValueError(blob(errors).decode(errors='replace') if errors else 'D3DCompile failed')
        return blob(code)
    finally:
        for obj in (code, errors):
            if obj:
                method(obj, 2, C.c_ulong)(obj)


def validate(expected, actual):
    errors = []
    if not expected['modern']:
        constants = {v['name']: v for v in actual['constants']}
        for v in expected['constants']:
            other = constants.get(v['name'])
            if other is not None and any(v[k] != other[k] for k in ['register_set', 'slot', 'count']):
                errors.append('DX9 register differs: ' + v['name'])
        return errors
    # Resource names in original reflection can be duplicated for a texture and
    # its sampler. The exported HLSL uses a _tex suffix to disambiguate them.
    resources = {(v['kind'], v['name']): v for v in actual['resources']}
    for v in expected['resources']:
        candidates = [v['name'], v['name'] + '_tex'] if v['kind'] == 2 else [v['name'], v['name'] + '_s'] if v['kind'] == 3 else [v['name']]
        if v['kind'] in (0, 1):
            candidates += [v['name'].replace('$', '_')]
        other = next((resources[v['kind'], n] for n in candidates if (v['kind'], n) in resources), None)
        if other is None:
            errors.append('Compiled resource missing: ' + v['name'])
        elif any(v[k] != other[k] for k in ['slot', 'count', 'dimension']):
            errors.append('Compiled resource binding differs: ' + v['name'])
    variables = {v['name']: (b, v) for b in actual['buffers'] for v in b['variables']}
    for buffer in expected['buffers']:
        for v in buffer['variables']:
            if not v['used']:
                continue
            pair = variables.get(v['name'])
            if pair is None:
                errors.append('Compiled constant missing: ' + v['name'])
            elif any(v[k] != pair[1][k] for k in ['offset', 'size', 'type']):
                errors.append('Compiled constant layout differs: ' + v['name'])
            elif pair[0]['name'] not in (buffer['name'], buffer['name'].replace('$', '_')):
                errors.append('Compiled constant belongs to another buffer: ' + v['name'])
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('sources', type=Path)
    parser.add_argument('binaries', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--fix', action='store_true')
    parser.add_argument('--compiled', type=Path, help='Validate rebuilt containers instead of compiling source')
    parser.add_argument('--allow-metadata-changes', action='store_true',
                        help='Allow intentional effect changes when checking a modded subset')
    parser.add_argument('--jobs', type=int, default=8)
    parser.add_argument('--limit', type=int)
    args = parser.parse_args()
    if args.fix and args.compiled:
        parser.error('--fix and --compiled cannot be combined')
    args.output.mkdir(parents=True, exist_ok=True)
    dll = C.WinDLL('d3dcompiler_47.dll')
    compiler = dll.D3DCompile
    compiler.argtypes = [P, C.c_size_t, C.c_char_p, P, P, C.c_char_p, C.c_char_p,
                         C.c_uint, C.c_uint, C.POINTER(P), C.POINTER(P)]
    compiler.restype = C.c_long
    version = Path('C:/Windows/System32/d3dcompiler_47.dll').stat().st_mtime_ns
    cache = args.output / ('compiled-' + str(version))
    cache.mkdir(exist_ok=True)
    jobs, errors = {}, []
    total = 0
    xmls = sorted(args.sources.glob('*/*.fxc.xml'))
    if args.limit:
        xmls = xmls[:args.limit]
    print('Indexing', len(xmls), 'containers', flush=True)
    def index_container(xml):
        binary = args.binaries / xml.parent.name / xml.name.removesuffix('.xml')
        originals, metadata = container_shaders(binary.read_bytes(), True)
        compiled = None
        if args.compiled:
            compiled_file = args.compiled / xml.parent.name / binary.name
            compiled, compiled_metadata = container_shaders(compiled_file.read_bytes(), True)
            if metadata != compiled_metadata and not args.allow_metadata_changes:
                raise ValueError('Rebuilt container metadata differs from original')
        declarations_xml = ET.parse(xml).getroot().findall('./ShaderGroups/Group/Shaders/Shader')
        if len(originals) != len(declarations_xml):
            raise ValueError('Shader count mismatch')
        result = []
        for shader_index, ((stage, name, raw), declaration) in enumerate(zip(originals, declarations_xml)):
            if declaration.get('Name') != name:
                raise ValueError('Shader name/order mismatch')
            file = xml.parent / declaration.get('File')
            source = file.read_bytes() if compiled is None else b''
            profile = ['vs', 'ps', 'cs', 'ds', 'gs', 'hs'][stage] + '_' + declaration.get('Model').replace('.', '_')
            if shader_profile(raw) != profile:
                raise ValueError('Original bytecode stage/model disagrees with XML: ' + name)
            compiled_raw = compiled[shader_index][2] if compiled is not None else None
            key = hashlib.sha256(raw).hexdigest(), hashlib.sha256(compiled_raw if compiled_raw is not None else source).hexdigest(), profile
            result.append((key, raw, source, file, profile, compiled_raw))
        return result

    def safe_index(xml):
        try:
            return index_container(xml), None
        except Exception as e:
            return [], dict(file=str(xml), error=str(e))

    with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as pool:
        for number, (entries, error) in enumerate(pool.map(safe_index, xmls), 1):
            if error:
                errors.append(error)
            for key, raw, source, file, profile, compiled_raw in entries:
                if key not in jobs:
                    jobs[key] = dict(raw=raw, source=source, files=[], profile=profile, compiled=compiled_raw)
                jobs[key]['files'].append(file)
                total += 1
            if number % 500 == 0:
                print('Indexed', number, 'containers;', total, 'shaders;', len(jobs), 'unique jobs', flush=True)
    print('Indexed', total, 'shaders;', len(jobs), 'unique jobs;', len(errors), 'container errors', flush=True)
    lock = threading.Lock()
    cache_locks = {}
    statistics = collections.Counter(containers=len(xmls), shaders=total, unique_jobs=len(jobs))

    def process(job):
        try:
            expected = reflection(job['raw'])
            source = job['source']
            raw = job['compiled']
            if raw is None:
                before = source.decode('utf-8-sig')
                source = repair(before, expected).encode('utf-8')
                key = hashlib.sha256(job['profile'].encode() + b'\0' + source).hexdigest()
                path = cache / (key + '.cso')
                with lock:
                    cache_lock = cache_locks.setdefault(key, threading.Lock())
                with cache_lock:
                    if path.exists():
                        raw = path.read_bytes()
                    else:
                        raw = compile_source(source, job['profile'], compiler)
                        temporary = path.with_suffix('.' + str(threading.get_ident()) + '.tmp')
                        temporary.write_bytes(raw)
                        temporary.replace(path)
            if shader_profile(raw) != job['profile']:
                raise ValueError('Compiled bytecode has the wrong stage/model')
            issues = validate(expected, reflection(raw))
            if issues:
                raise ValueError('; '.join(issues))
            changed = source != job['source']
            if args.fix and changed:
                for file in job['files']:
                    file.write_bytes(source)
            with lock:
                statistics['validated_jobs'] += 1
                statistics['validated_shaders'] += len(job['files'])
                if changed:
                    statistics['changed_shaders' if args.fix else 'shaders_needing_changes'] += len(job['files'])
        except Exception as e:
            with lock:
                errors.append(dict(file=str(job['files'][0]), copies=len(job['files']), profile=job['profile'], error=str(e)))
                statistics['failed_jobs'] += 1
        with lock:
            statistics['processed_jobs'] += 1
            if statistics['processed_jobs'] % 250 == 0:
                print(dict(statistics), flush=True)

    with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as pool:
        list(pool.map(process, jobs.values()))
    report = dict(statistics=statistics, errors=errors)
    (args.output / 'report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps(statistics), 'errors:', len(errors), flush=True)
    for error in errors[:12]:
        print(error, flush=True)
    return 1 if errors else 0


if __name__ == '__main__':
    raise SystemExit(main())
