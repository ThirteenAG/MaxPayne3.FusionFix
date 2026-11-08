"""Prepare the multisample skin shader fixes from FusionShaders.

With the game's MSAA, the deferred skin programs turn the diffuse alpha into sample coverage, but skin textures keep
the subsurface scattering mask there: skin with a low mask, often whole faces, was not drawn at all. These programs
are rebuilt from the single-sample programs of the same container, which draw every sample and use the alpha as the
mask, with the multisample conventions kept: centroid position and the edge marker in the third target's alpha.
"""
import argparse
import re
import xml.etree.ElementTree as ET
from pathlib import Path


PROFILES = [f'win32_{model}_msaa{samples}{stereo}' for model in ('41', '50') for stereo in ('', '_nvstereo') for samples in (2, 4, 8)]
DEFERRED = {
    'PS_DeferredPedTextured': 'PS_DeferredPedTextured',
    'PS_DeferredPedTextured_AlphaClip': 'PS_DeferredPedTextured',
    'PS_DeferredPedTextured_NoDmg': 'PS_DeferredPedTextured_NoDmg',
    'PS_DeferredPedTextured_AlphaClip_NoDmg': 'PS_DeferredPedTextured_NoDmg',
}


def read(path):
    return Path(path).read_text(encoding='utf8')


def multisample(source):
    source, positions = re.subn(r'\n\tfloat4 sv_position : SV_Position;', '\n\tnoperspective centroid float4 sv_position : SV_Position;', source)
    source, edges = re.subn(r'\n\to\.sv_target2\.w = [^;]+;',
        '\n\to.sv_target2.w = dot(abs(frac(i.sv_position.xy) - 0.5), float2(1000, 1000));', source)
    if positions != 1 or edges != 1:
        raise ValueError('unexpected single-sample program layout')
    return source


def skin_containers(reference, model):
    # The containers whose deferred programs read the subsurface mask from the diffuse alpha
    return sorted(path.parent.name for path in (reference / model).glob('ped*/PS_DeferredPedTextured.hlsl') if 'SubColor' in read(path))


def prepare(reference, destination):
    total = 0
    for model in ('win32_41', 'win32_50'):
        shared = None
        for profile in [p for p in PROFILES if p.startswith(model + '_')]:
            shared = shared or profile
            for container in skin_containers(reference, model):
                xml = reference / profile / f'{container}.fxc.xml'
                doc = ET.parse(xml).getroot()
                for group in doc.findall('./ShaderGroups/Group'):
                    for shader in group.find('Shaders'):
                        path = shader.get('File')
                        name = Path(path).stem
                        if group.get('Stage') == 'Pixel' and name in DEFERRED:
                            if 'SV_Coverage' not in read(reference / profile / path):
                                raise ValueError(f'{xml}: {name} has no coverage output')
                            source = multisample(read(reference / model / container / f'{DEFERRED[name]}.hlsl'))
                        else:
                            source = read(reference / profile / path)
                        common = destination / shared / path
                        if profile != shared and common.exists() and read(common) == source:
                            shader.set('File', f'../{shared}/{path}')
                            continue
                        output = destination / profile / path
                        output.parent.mkdir(parents=True, exist_ok=True)
                        if not output.exists() or read(output) != source:
                            output.write_text(source, encoding='utf8')
                ET.indent(doc, space='  ')
                ET.ElementTree(doc).write(destination / profile / xml.name, encoding='utf-8', xml_declaration=True)
                total += 1
    print(f'{total} containers')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('reference', type=Path)
    parser.add_argument('destination', type=Path)
    args = parser.parse_args()
    prepare(args.reference, args.destination)
