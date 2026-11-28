import importlib.util
import io
import json
import os
import struct
import tempfile
import unittest
import zlib
from pathlib import Path

spec = importlib.util.spec_from_file_location('extract', str(Path(__file__).with_name('extract.py')))
extract = importlib.util.module_from_spec(spec); spec.loader.exec_module(extract)


def make_resource(name='test_dm', kind=0):
    body = bytearray(8192)
    struct.pack_into('<I', body, 24, 0x50000100)
    struct.pack_into('<H', body, 28, 1)
    struct.pack_into('<I', body, 256, 0x50000040)
    struct.pack_into('<I', body, 64+24, 0x50000200)
    struct.pack_into('<4H', body, 64+32, 8, 8, 1, 4)
    body[64+40:64+44] = b'DXT1'
    body[64+44], body[64+45] = kind, 2
    struct.pack_into('<I', body, 64+80, 0x60000000)
    encoded = name.encode('ascii')+b'\0'; body[512:512+len(encoded)] = encoded
    pixels = bytes(range(40))
    body[4096:4136] = pixels
    return struct.pack('<4sII', b'RSC\x05', 11, 0xc0080010)+zlib.compress(body), pixels


def make_archive(files):
    """Stored binary and RSC5 entries in an unencrypted synthetic RPF4."""
    names, rows, payload = bytearray(b'/\0'), [], bytearray(4096)
    for name, data, resource in files:
        name_offset = len(names); names.extend(name.encode('utf-8')+b'\0')
        address = (len(payload)+2047)//2048*2048
        payload.extend(b'\0'*(address-len(payload))); payload.extend(data)
        flags = extract.u32(data, 8) if resource else len(data)
        offset = (address//8) | 11 if resource else address//8
        rows.append((name_offset, len(data), offset, flags))
    rows.insert(0, (0, len(files), 0x80000001, len(files)))
    toc = b''.join(struct.pack('<4I', *row) for row in rows)+names
    toc += b'\0'*((-len(toc)) % 16)
    assert len(toc) <= 2048
    payload[:24] = struct.pack('<4s5I', b'RPF4', len(toc), len(rows), 0, 0, 0)
    payload[2048:2048+len(toc)] = toc
    return bytes(payload)


class ExtractTests(unittest.TestCase):
    def test_resource_mips_and_dds_are_byte_preserving(self):
        data, pixels = make_resource('pack:/test_dm.dds')
        body, virtual, physical = extract.resource(data)
        descriptors = list(extract.textures(body, virtual, physical))
        self.assertEqual(len(descriptors), 1)
        self.assertEqual(descriptors[0]['name'], 'test_dm')
        dds = extract.dds_bytes(body, virtual, physical, descriptors[0])
        self.assertEqual(dds[:4], b'DDS ')
        self.assertEqual(extract.u32(dds, 28), 2)
        self.assertEqual(dds[128:], pixels)

    def test_nested_archives_preserve_container_paths(self):
        resource, _ = make_resource()
        nested = make_archive([('same.wtd', resource, True), ('embedded.wdr', resource, True)])
        archive = make_archive([('inside.rpf', nested, False), ('same.wtd', resource, True)])
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary)
            e = extract.Extractor(output)
            e.archive(extract.Reader(io.BytesIO(archive), len(archive)), Path('outer.rpf'))
            self.assertEqual(len(e.rows), 3); self.assertFalse(e.errors)
            self.assertTrue((output/'outer.rpf/inside.rpf/same.wtd/test_dm.dds').exists())
            self.assertTrue((output/'outer.rpf/inside.rpf/embedded.wdr/test_dm.dds').exists())
            self.assertTrue((output/'outer.rpf/same.wtd/test_dm.dds').exists())

    def test_traversal_and_repeated_output_are_safe(self):
        resource, _ = make_resource()
        archive = make_archive([('../../escape.wtd', resource, True)])
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary); output = root/'output'; output.mkdir()
            e = extract.Extractor(output)
            e.archive(extract.Reader(io.BytesIO(archive), len(archive)), Path('outer.rpf'))
            self.assertEqual(len(e.rows), 1)
            self.assertTrue((output/'outer.rpf/.._.._escape.wtd/test_dm.dds').exists())
            e.archive(extract.Reader(io.BytesIO(archive), len(archive)), Path('outer.rpf'))
            self.assertTrue(e.errors)
            self.assertFalse((root/'escape.wtd').exists())
            self.assertEqual(extract.safe_part('CON'), '_CON')

    def test_invalid_bounds_and_compression(self):
        with self.assertRaises(ValueError): extract.Reader(io.BytesIO(b'abc'), 3).read(2, 2)
        data, _ = make_resource()
        with self.assertRaises(ValueError): extract.resource(data[:-5])
        with self.assertRaises(ValueError): extract.inflate(zlib.compress(b'abc'), 2)

    def test_cli_inventory_and_output_exclusion(self):
        resource, _ = make_resource()
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary); source = root/'game'; source.mkdir()
            (source/'test.wtd').write_bytes(resource)
            output = source/'extract'
            self.assertEqual(extract.main([str(source), '--output', str(output), '--inventory']), 0)
            self.assertFalse(list(output.rglob('*.dds')))
            self.assertEqual(json.loads((output/'summary.json').read_text())['textures'], 1)
            self.assertEqual(list(extract.input_files(source)), [source/'test.wtd'])

    @unittest.skipUnless(os.name == 'nt', 'Windows AES provider')
    def test_archive_aes_roundtrip(self):
        cipher = extract.WindowsAES(bytes(range(32)))
        data = bytes(range(64))
        try:
            import ctypes
            api = cipher.api
            api.BCryptEncrypt.argtypes = api.BCryptDecrypt.argtypes
            source = ctypes.create_string_buffer(data); output = ctypes.create_string_buffer(len(data)); count = ctypes.c_ulong()
            for _ in range(16):
                cipher.check(api.BCryptEncrypt(cipher.key, source, len(data), None, None, 0, output, len(data), ctypes.byref(count), 0))
                source, output = output, source
            self.assertEqual(cipher.decrypt(source.raw[:len(data)]), data)
        finally:
            cipher.close()

    def test_base_and_dlc_key_fallback(self):
        data, _ = make_resource()
        archive = bytearray(make_archive([('test.wtd', data, True)]))
        struct.pack_into('<I', archive, 16, 0xffffffff)
        class Wrong:
            def decrypt(self, raw): return bytes(len(raw))
        class Correct:
            def decrypt(self, raw): return raw
        with tempfile.TemporaryDirectory() as temporary:
            e = extract.Extractor(Path(temporary), [Wrong(), Correct()], inventory=True)
            e.archive(extract.Reader(io.BytesIO(archive), len(archive)), Path('dlc.rpf'))
            self.assertEqual(len(e.rows), 1)
            self.assertFalse(e.errors)

    def test_cube_and_volume_dds_headers(self):
        for kind in (1, 3):
            data, _ = make_resource(kind=kind)
            body, virtual, physical = extract.resource(data)
            if kind == 3:
                body = bytearray(body); struct.pack_into('<H', body, 64+36, 4)
            texture = list(extract.textures(body, virtual, physical))[0]
            dds = extract.dds_bytes(body, virtual, physical, texture)
            if kind == 1:
                self.assertEqual(extract.u32(dds, 28*4), 0xfe00)
                self.assertEqual(len(dds), 128+6*40)
            else:
                self.assertEqual(extract.u32(dds, 28*4), 0x200000)
                self.assertEqual(extract.u32(dds, 6*4), 4)
                self.assertEqual(len(dds), 128+144)


if __name__ == '__main__': unittest.main()
