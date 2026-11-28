"""Read Max Payne 3 PC RPF4/RSC5 files and export original DDS mip chains."""
import argparse
import ctypes
import csv
import io
import json
import os
import re
import struct
import sys
import time
import zlib
from pathlib import Path


def u32(data, offset=0):
    return struct.unpack_from('<I', data, offset)[0]


class WindowsAES:
    """AES-256 ECB through Windows CNG; no third-party crypto dependency."""
    def __init__(self, key):
        if os.name != 'nt':
            raise ValueError('Encrypted archive support requires Windows')
        self.api = ctypes.WinDLL('bcrypt')
        pointer, uint = ctypes.c_void_p, ctypes.c_ulong
        self.api.BCryptOpenAlgorithmProvider.argtypes = [ctypes.POINTER(pointer), ctypes.c_wchar_p, ctypes.c_wchar_p, uint]
        self.api.BCryptSetProperty.argtypes = [pointer, ctypes.c_wchar_p, pointer, uint, uint]
        self.api.BCryptGenerateSymmetricKey.argtypes = [pointer, ctypes.POINTER(pointer), pointer, uint, pointer, uint, uint]
        self.api.BCryptDecrypt.argtypes = [pointer, pointer, uint, pointer, pointer, uint, pointer, uint, ctypes.POINTER(uint), uint]
        self.api.BCryptDestroyKey.argtypes = [pointer]
        self.api.BCryptCloseAlgorithmProvider.argtypes = [pointer, uint]
        self.algorithm, self.key = pointer(), pointer()
        self.check(self.api.BCryptOpenAlgorithmProvider(ctypes.byref(self.algorithm), 'AES', None, 0))
        mode = ctypes.create_unicode_buffer('ChainingModeECB')
        self.check(self.api.BCryptSetProperty(self.algorithm, 'ChainingMode', mode, ctypes.sizeof(mode), 0))
        raw = ctypes.create_string_buffer(key)
        self.check(self.api.BCryptGenerateSymmetricKey(self.algorithm, ctypes.byref(self.key), None, 0, raw, len(key), 0))

    @staticmethod
    def check(result):
        if result:
            raise ValueError('Windows AES failed (0x%08x)' % (result & 0xffffffff))

    def decrypt(self, data):
        size = len(data) // 16 * 16
        if not size:
            return data
        source = ctypes.create_string_buffer(data[:size])
        output = ctypes.create_string_buffer(size)
        written = ctypes.c_ulong()
        # RPF2/4 applies the complete AES transform sixteen times.
        for _ in range(16):
            self.check(self.api.BCryptDecrypt(self.key, source, size, None, None, 0,
                                             output, size, ctypes.byref(written), 0))
            source, output = output, source
        return source.raw[:size] + data[size:]

    def close(self):
        if self.key:
            self.api.BCryptDestroyKey(self.key); self.key = None
        if self.algorithm:
            self.api.BCryptCloseAlgorithmProvider(self.algorithm, 0); self.algorithm = None


def find_keys(executable):
    """Locate the two PC archive keys by fingerprint, without shipping them."""
    raw = executable.read_bytes()
    if raw[:2] != b'MZ' or len(raw) < 64:
        raise ValueError('Archive key source is not a PE executable')
    pe = u32(raw, 60)
    if raw[pe:pe+4] != b'PE\0\0':
        raise ValueError('Invalid executable header')
    count = struct.unpack_from('<H', raw, pe+6)[0]
    sections = pe+24+struct.unpack_from('<H', raw, pe+20)[0]
    ranges = []
    for i in range(count):
        entry = sections+i*40
        name = raw[entry:entry+8].rstrip(b'\0')
        size, offset = struct.unpack_from('<II', raw, entry+16)
        if name in (b'.data', b'.rdata'):
            ranges.append((offset, size))
    # Swage's public MP3-PC key identifier describes this 32-byte polynomial
    # fingerprint. The recovered bytes stay in memory; they are never logged.
    factor, targets, mask = 0x9e3779b1, {177864599, 1221648812}, 0xffffffff
    found = {}
    remove = pow(factor, 32, 1 << 32)
    for offset, size in ranges:
        data = raw[offset:offset+size]
        value = 0
        for byte in data[:31]:
            value = ((value+byte)*factor) & mask
        for i in range(max(0, len(data)-31)):
            value = ((value+data[i+31])*factor) & mask
            if value in targets:
                found[value] = data[i:i+32]
                if len(found) == len(targets):
                    return list(found.values())
            value = (value-data[i]*remove) & mask
    if found:
        return list(found.values())
    raise ValueError('Archive keys not found; use --exe with your unpacked MaxPayne3.exe')


def safe_part(value):
    value = re.sub(r'[<>:"/\\|?*\x00-\x1f]', '_', value).rstrip(' .')
    if not value or value in ('.', '..'):
        value = '_unnamed'
    if value.split('.')[0].upper() in {'CON', 'PRN', 'AUX', 'NUL'} | {
            kind+str(i) for kind in ('COM', 'LPT') for i in range(1, 10)}:
        value = '_'+value
    return value


class Reader:
    def __init__(self, stream, size, base=0):
        self.stream, self.size, self.base = stream, size, base

    def read(self, offset, size):
        if offset < 0 or size < 0 or offset+size > self.size:
            raise ValueError('Archive entry extends outside its parent')
        self.stream.seek(self.base+offset)
        data = self.stream.read(size)
        if len(data) != size:
            raise ValueError('Truncated archive entry')
        return data

    def sub(self, offset, size):
        if offset < 0 or size < 0 or offset+size > self.size:
            raise ValueError('Nested archive extends outside its parent')
        return Reader(self.stream, size, self.base+offset)


def inflate(data, expected, raw=False):
    if expected > 1024*1024*1024:
        raise ValueError('Resource exceeds 1 GiB decompression limit')
    decoder = zlib.decompressobj(-15 if raw else 15)
    result = decoder.decompress(data, expected+1)
    if len(result) != expected or not decoder.eof:
        raise ValueError('Decompressed size mismatch: expected %d, got %d' % (expected, len(result)))
    return result


def resource_sizes(flags):
    return ((flags & 0x7ff) << (((flags >> 11) & 15)+8),
            ((flags >> 15) & 0x7ff) << (((flags >> 26) & 15)+8))


def resource(data):
    if len(data) < 12 or data[:4] != b'RSC\x05':
        raise ValueError('Expected a PC RSC5 resource')
    flags = u32(data, 8)
    virtual, physical = resource_sizes(flags)
    if not virtual:
        raise ValueError('Resource has no virtual section')
    body = inflate(data[12:], virtual+physical) if flags & 0x40000000 else data[12:]
    if len(body) < virtual+physical:
        raise ValueError('Truncated resource sections')
    return body, virtual, physical


# D3D9 pixel layouts used by PC resource texture descriptors. Preserve format,
# compression and mip bytes, rather than decoding and recompressing an image.
RGB_FORMATS = {
    20: (24, (0xff0000, 0xff00, 0xff, 0)),
    21: (32, (0xff0000, 0xff00, 0xff, 0xff000000)),
    22: (32, (0xff0000, 0xff00, 0xff, 0)),
    23: (16, (0xf800, 0x7e0, 0x1f, 0)),
    24: (16, (0x7c00, 0x3e0, 0x1f, 0)),
    25: (16, (0x7c00, 0x3e0, 0x1f, 0x8000)),
    26: (16, (0xf00, 0xf0, 0xf, 0xf000)),
    30: (16, (0xf00, 0xf0, 0xf, 0)),
    31: (32, (0x3ff, 0xffc00, 0x3ff00000, 0xc0000000)),
    32: (32, (0xff, 0xff00, 0xff0000, 0xff000000)),
    33: (32, (0xff, 0xff00, 0xff0000, 0)),
    35: (32, (0x3ff00000, 0xffc00, 0x3ff, 0xc0000000)),
}
FOURCC_FORMATS = {struct.unpack('<I', code)[0]: (code.decode('ascii'), block)
                 for code, block in ((b'DXT1', 8), (b'DXT2', 16), (b'DXT3', 16),
                                     (b'DXT4', 16), (b'DXT5', 16), (b'ATI1', 8), (b'ATI2', 16))}
NUMERIC_FORMATS = {36: 64, 60: 16, 63: 32, 64: 32, 67: 32, 81: 16,
                   110: 64, 111: 16, 112: 32, 113: 64, 114: 32, 115: 64, 116: 128}


def texture_descriptor(body, virtual, physical, offset):
    if offset < 0 or offset % 4 or offset+96 > virtual:
        return None
    name_pointer, pixel_pointer = u32(body, offset+24), u32(body, offset+80)
    if name_pointer >> 28 != 5 or pixel_pointer >> 28 != 6:
        return None
    name_offset, pixel_offset = name_pointer & 0xfffffff, pixel_pointer & 0xfffffff
    if name_offset >= virtual or pixel_offset >= physical:
        return None
    end = body.find(b'\0', name_offset, min(virtual, name_offset+512))
    if end < 0:
        return None
    name_raw = body[name_offset:end]
    if not name_raw or any(byte < 32 or byte > 126 for byte in name_raw):
        return None
    width, height, depth, stride = struct.unpack_from('<4H', body, offset+32)
    kind, mips = body[offset+44] & 31, body[offset+45]
    if not (1 <= width <= 16384 and 1 <= height <= 16384 and 1 <= depth <= 2048
            and kind in (0, 1, 3) and 1 <= mips <= max(width, height, depth).bit_length() and stride):
        return None
    name = name_raw.decode('ascii').replace('\\', '/').rsplit('/', 1)[-1]
    if name.lower().endswith('.dds'):
        name = name[:-4]
    return dict(name=name, width=width, height=height, depth=depth, kind=kind, mips=mips,
                stride=stride, format=u32(body, offset+40), offset=offset, pixel_offset=pixel_offset)


def textures(body, virtual, physical):
    # Every owned PC texture has a physical-data pointer at +80. Locating and
    # validating that descriptor also finds embedded textures in WDR/WDD/WFT/
    # particle resources, without assuming one root-object layout for all types.
    for match in re.finditer(b'[\x60-\x6f]', body[:virtual]):
        descriptor = texture_descriptor(body, virtual, physical, match.start()-83)
        if descriptor:
            yield descriptor


def dds_bytes(body, virtual, physical, texture):
    t = texture
    fmt, bits, block = t['format'], 0, 0
    header = [0]*32
    header[:5] = [0x20534444, 124, 0x1007, t['height'], t['width']]
    header[7], header[19], header[27] = t['mips'], 32, 0x1000
    if t['mips'] > 1:
        header[2] |= 0x20000; header[27] |= 0x400008
    if fmt in FOURCC_FORMATS:
        _, block = FOURCC_FORMATS[fmt]
        header[20], header[21] = 4, fmt
        header[2] |= 0x80000
        header[5] = max(1, (t['width']+3)//4) * max(1, (t['height']+3)//4) * block
    elif fmt in RGB_FORMATS:
        bits, masks = RGB_FORMATS[fmt]
        header[20], header[22] = 0x40 | bool(masks[3]), bits
        header[23:27] = masks
    elif fmt in (28, 50, 51, 52):
        bits = 16 if fmt == 51 else 8
        header[20] = 2 if fmt == 28 else (0x20001 if fmt in (51, 52) else 0x20000)
        header[22], header[23], header[26] = bits, (15 if fmt == 52 else (0 if fmt == 28 else 255)), (255 if fmt == 28 else (0xff00 if fmt == 51 else (0xf0 if fmt == 52 else 0)))
    elif fmt in NUMERIC_FORMATS:
        bits = NUMERIC_FORMATS[fmt]
        header[20], header[21] = 4, fmt
    else:
        raise ValueError('Unsupported texture format 0x%08x' % fmt)
    if bits:
        header[2] |= 8
        header[5] = (t['width']*bits+7)//8
    # The native PC descriptors store linear data. Cube surfaces are face-major;
    # volume depths shrink with their mip levels.
    faces = 6 if t['kind'] == 1 else 1
    if t['kind'] == 1:
        header[27] |= 8; header[28] = 0xfe00
    elif t['kind'] == 3:
        header[2] |= 0x800000; header[6] = t['depth']; header[27] |= 8; header[28] = 0x200000
    elif t['depth'] != 1:
        raise ValueError('Unexpected array/depth on 2D texture')
    chunks = []
    position = virtual+t['pixel_offset']
    for _ in range(faces):
        for level in range(t['mips']):
            width, height = max(1, t['width'] >> level), max(1, t['height'] >> level)
            depth = max(1, t['depth'] >> level) if t['kind'] == 3 else 1
            size = (max(1, (width+3)//4)*max(1, (height+3)//4)*block if block else (width*bits+7)//8*height)*depth
            if position+size > virtual+physical:
                raise ValueError('Texture mip chain extends outside physical section')
            chunks.append(body[position:position+size]); position += size
    return struct.pack('<32I', *header)+b''.join(chunks)


class Extractor:
    def __init__(self, output, cipher=None, inventory=False, select=None):
        self.output, self.cipher, self.inventory, self.select = output, cipher, inventory, select
        self.rows, self.errors = [], []
        self.resources = self.archives = self.byte_count = 0
        self.interrupted = False
        self.next_progress = time.monotonic()+15

    def progress(self):
        if time.monotonic() >= self.next_progress:
            print('%d archives; %d resources; %d textures; %d errors' %
                  (self.archives, self.resources, len(self.rows), len(self.errors)), flush=True)
            self.next_progress = time.monotonic()+15

    def error(self, source, error):
        self.errors.append(dict(source=str(source), error=str(error)))

    def extract_resource(self, data, source):
        self.resources += 1
        try:
            body, virtual, physical = resource(data)
            found = list(textures(body, virtual, physical))
            # For WTDs, independently check the real dictionary's pointer array,
            # so a missed owned texture is reported instead of silently omitted.
            if source.suffix.lower() == '.wtd' and virtual >= 32:
                array, count = u32(body, 24), struct.unpack_from('<H', body, 28)[0]
                if count and array >> 28 == 5:
                    base = array & 0xfffffff
                    if base+count*4 > virtual:
                        raise ValueError('Texture dictionary pointer array is out of bounds')
                    seen = {t['offset'] for t in found}
                    for i in range(count):
                        pointer = u32(body, base+4*i)
                        if pointer >> 28 != 5:
                            raise ValueError('Invalid dictionary texture pointer')
                        offset = pointer & 0xfffffff
                        if offset+84 <= virtual and u32(body, offset+80) >> 28 == 6 and offset not in seen:
                            self.error(source, 'Owned dictionary texture at 0x%x was not recognized' % offset)
            used = set()
            for texture in found:
                try:
                    dds = dds_bytes(body, virtual, physical, texture)
                    name = safe_part(texture['name'])+'.dds'
                    duplicate = name.lower() in used
                    used.add(name.lower())
                    relative = source/'_duplicates'/('%08x' % texture['offset'])/name if duplicate else source/name
                    if not self.inventory:
                        target = self.output/relative
                        target.parent.mkdir(parents=True, exist_ok=True)
                        with target.open('xb') as stream:
                            stream.write(dds)
                    self.byte_count += len(dds)
                    self.rows.append(dict(source=str(source), texture=texture['name'], output=str(relative),
                                          width=texture['width'], height=texture['height'], depth=texture['depth'],
                                          mips=texture['mips'], kind=texture['kind'], format='0x%08x' % texture['format'],
                                          bytes=len(dds)))
                except Exception as error:
                    self.error(str(source)+' / '+texture['name'], error)
        except Exception as error:
            self.error(source, error)
        self.progress()

    def archive(self, reader, source, depth=0):
        self.archives += 1
        if depth > 16:
            raise ValueError('Nested archive depth exceeds 16')
        header = reader.read(0, 24)
        if header[:4] not in (b'RPF2', b'RPF4'):
            raise ValueError('Unsupported archive signature %r' % header[:4])
        size, count, _, tag, payload_tag = struct.unpack_from('<5I', header, 4)
        if not 1 <= count <= 2000000 or not count*16 <= size <= 128*1024*1024:
            raise ValueError('Invalid archive table size')
        if payload_tag:
            raise ValueError('Unsupported archive payload encryption tag')
        table = reader.read(0x800, size)
        if tag:
            if not self.cipher:
                raise ValueError('Archive table is encrypted; executable key is required')
            # Retail base archives and installed DLC use different keys. Validate
            # the root directory before accepting any decrypted table.
            pool = self.cipher if isinstance(self.cipher, (list, tuple)) else [self.cipher]
            for cipher in pool:
                decoded = cipher.decrypt(table)
                name, _, first, length = struct.unpack_from('<4I', decoded)
                if first & 0x80000000 and (first & 0x7fffffff)+(length & 0x3fffffff) <= count and name < size-count*16:
                    table = decoded
                    break
            else:
                raise ValueError('No executable key opened this archive table')
        entries = list(struct.iter_unpack('<4I', table[:count*16]))
        names = table[count*16:]
        visited = set()

        def walk(index, path):
            if index >= count or index in visited:
                raise ValueError('Invalid or cyclic archive directory')
            visited.add(index)
            _, _, first, length = entries[index]
            if not first & 0x80000000:
                raise ValueError('Expected archive directory (wrong key or corrupt table)')
            first, length = first & 0x7fffffff, length & 0x3fffffff
            if first+length > count:
                raise ValueError('Directory range extends outside archive table')
            for i in range(first, first+length):
                name, stored, offset, flags = entries[i]
                if name >= len(names):
                    raise ValueError('Invalid archive filename offset')
                end = names.find(b'\0', name)
                if end < 0:
                    raise ValueError('Unterminated archive filename')
                label = names[name:end].decode('utf-8', 'replace')
                child = path/safe_part(label)
                if offset & 0x80000000:
                    walk(i, child); continue
                is_resource = bool(flags & 0x80000000)
                compressed = bool(flags & 0x40000000)
                address = offset & (0x7fffff00 if is_resource else 0x7fffffff)
                if header[:4] == b'RPF4': address *= 8
                disk_size = stored if is_resource else flags & 0x3fffffff
                if self.select and self.select.lower() not in str(child).lower() and not label.lower().endswith('.rpf'):
                    continue
                try:
                    if is_resource:
                        self.extract_resource(reader.read(address, disk_size), child)
                    elif label.lower().endswith('.rpf'):
                        if compressed:
                            data = inflate(reader.read(address, disk_size), stored, raw=True)
                            self.archive(Reader(io.BytesIO(data), len(data)), child, depth+1)
                        else:
                            self.archive(reader.sub(address, disk_size), child, depth+1)
                    elif label.lower().endswith('.dds'):
                        data = reader.read(address, disk_size)
                        if compressed: data = inflate(data, stored, raw=True)
                        if data[:4] != b'DDS ': raise ValueError('Invalid loose DDS entry')
                        self.copy_dds(data, child)
                except Exception as error:
                    self.error(child, error)
                self.progress()
        walk(0, source)

    def copy_dds(self, data, source):
        if not self.inventory:
            target = self.output/source
            target.parent.mkdir(parents=True, exist_ok=True)
            with target.open('xb') as stream: stream.write(data)
        self.byte_count += len(data)
        self.rows.append(dict(source=str(source), texture=source.stem, output=str(source), bytes=len(data)))

    def save(self):
        fields = ['source', 'texture', 'output', 'width', 'height', 'depth', 'mips', 'kind', 'format', 'bytes']
        with (self.output/'manifest.csv').open('w', encoding='utf-8-sig', newline='') as stream:
            writer = csv.DictWriter(stream, fields); writer.writeheader(); writer.writerows(self.rows)
        with (self.output/'errors.csv').open('w', encoding='utf-8-sig', newline='') as stream:
            writer = csv.DictWriter(stream, ['source', 'error']); writer.writeheader(); writer.writerows(self.errors)
        summary = dict(archives=self.archives, resources=self.resources, textures=len(self.rows),
                       dds_bytes=self.byte_count, errors=len(self.errors), inventory_only=self.inventory,
                       interrupted=self.interrupted)
        (self.output/'summary.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
        return summary


def input_files(root):
    extensions = {'.rpf', '.wtd', '.wdr', '.wdd', '.wft', '.wfd', '.wpfl', '.wpf', '.dds'}
    for directory, folders, files in os.walk(str(root)):
        folders[:] = [name for name in folders if name.lower() not in ('.git', 'plugins', 'crashdumps', 'save')
                      and not (Path(directory)/name/'.mp3-texture-extraction').exists()]
        for name in files:
            path = Path(directory)/name
            if path.suffix.lower() in extensions:
                yield path


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', type=Path, help='Game folder, RPF archive, or loose resource')
    parser.add_argument('--output', type=Path, required=True, help='New extraction folder (must not exist)')
    parser.add_argument('--exe', type=Path, help='Local MaxPayne3.exe used for archive table key recovery')
    parser.add_argument('--inventory', action='store_true', help='Validate and list textures without writing DDS files')
    parser.add_argument('--select', help='Process only source paths containing this text, e.g. bus_bld1')
    args = parser.parse_args(argv)
    if not args.input.exists(): parser.error('Input does not exist')
    if args.output.exists(): parser.error('Output folder already exists; choose a new folder')
    root = args.input if args.input.is_dir() else args.input.parent
    paths = sorted(input_files(root), key=str) if args.input.is_dir() else [args.input]
    if args.select:
        paths = [p for p in paths if args.select.lower() in str(p.relative_to(root)).lower() or p.suffix.lower() == '.rpf']
    executable = args.exe
    if executable is None:
        for directory in [root]+list(root.parents):
            if (directory/'MaxPayne3.exe').is_file(): executable = directory/'MaxPayne3.exe'; break
    cipher = []
    if any(p.suffix.lower() == '.rpf' for p in paths) and executable:
        print('Locating archive-table keys in local executable...', flush=True)
        try: cipher = [WindowsAES(key) for key in find_keys(executable)]
        except Exception as error: parser.error(str(error))
    args.output.mkdir(parents=True)
    (args.output/'.mp3-texture-extraction').write_text('Max Payne 3 DDS extraction\n', encoding='ascii')
    extractor = Extractor(args.output, cipher, args.inventory, args.select)
    try:
        for path in paths:
            source = Path(*(safe_part(part) for part in path.relative_to(root).parts))
            try:
                if path.suffix.lower() == '.rpf':
                    with path.open('rb') as stream:
                        extractor.archive(Reader(stream, path.stat().st_size), source)
                elif path.suffix.lower() == '.dds':
                    extractor.copy_dds(path.read_bytes(), source)
                else:
                    extractor.extract_resource(path.read_bytes(), source)
            except Exception as error:
                extractor.error(source, error)
    except KeyboardInterrupt:
        extractor.interrupted = True
        print('\nStopped; saving the partial manifest.', flush=True)
    finally:
        summary = extractor.save()
        for item in cipher: item.close()
    print(json.dumps(summary)); print('Output: '+str(args.output.absolute()))
    return 130 if summary['interrupted'] else (1 if summary['errors'] else 0)


if __name__ == '__main__':
    sys.exit(main())
