import hashlib
import importlib.util
import json
import struct
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image

spec = importlib.util.spec_from_file_location('scan', str(Path(__file__).with_name('scan.py')))
scan = importlib.util.module_from_spec(spec)
spec.loader.exec_module(scan)


def write_dds(path, image, mips=2):
    header = [0] * 32
    header[0], header[1], header[2] = 0x20534444, 124, 0x2100f
    header[3], header[4], header[5], header[7] = image.height, image.width, image.width*4, mips
    header[19:28] = [32, 0x41, 0, 32, 255, 65280, 16711680, 4278190080, 0x401008]
    raw = bytearray(struct.pack('<32I', *header))
    for level in range(mips):
        raw.extend(image.resize((max(1, image.width >> level), max(1, image.height >> level)), Image.BOX).tobytes())
    path.write_bytes(raw)


class ScannerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        rng = np.random.RandomState(912)
        cls.image = Image.fromarray(rng.randint(0, 256, (64, 64, 4), dtype=np.uint8), 'RGBA')
        cls.image.putalpha(255)

    def test_nearest_half_size_matches_but_filtered_mip_does_not(self):
        top = self.image.resize((128, 128), Image.NEAREST)
        result = scan.compare_mips(top, self.image, 0)
        self.assertEqual(result['score'], 100)
        self.assertEqual(result['exact_match_pct'], 100)
        self.assertEqual(result['mae'], 0)
        native = self.image
        filtered = native.resize((32, 32), Image.BOX)
        self.assertLess(scan.compare_mips(native, filtered)['score'], 30)

    def test_all_rgba_channels_are_compared_and_tolerance_is_explicit(self):
        top = Image.new('RGBA', (16, 16), (80, 90, 100, 255))
        lower = Image.new('RGBA', (8, 8), (84, 90, 100, 255))
        self.assertEqual(scan.compare_mips(top, lower, 4)['score'], 100)
        self.assertEqual(scan.compare_mips(top, lower, 3)['score'], 0)
        self.assertEqual(scan.compare_mips(top, lower, 4)['exact_match_pct'], 0)
        lower.putalpha(0)
        self.assertEqual(scan.compare_mips(top, lower, 8)['score'], 0)

    def test_1024_texture_uses_every_pixel_of_512_mip(self):
        base = self.image.resize((512, 512), Image.NEAREST)
        top = base.resize((1024, 1024), Image.NEAREST)
        self.assertEqual(scan.compare_mips(top, base, 0)['score'], 100)
        base.putpixel((511, 511), (1, 2, 3, 4))
        result = scan.compare_mips(top, base, 0)
        self.assertEqual(result['comparison_pixels'], 512*512)
        self.assertLess(result['exact_match_pct'], 100)
        self.assertGreater(result['max_error'], 0)

    def test_bc4_and_bc5_decode(self):
        # Constant first palette endpoint in every texel.
        r = np.array([[120, 10, 0, 0, 0, 0, 0, 0]], dtype=np.uint8)
        self.assertTrue(np.all(scan.decode_bc4(r, 4, 4) == 120))
        # Palette endpoint 1 in every texel: index bits repeat 001.
        indices = sum(1 << (3*i) for i in range(16))
        r[0, 2:] = list(indices.to_bytes(6, 'little'))
        self.assertTrue(np.all(scan.decode_bc4(r, 4, 4) == 10))

    def test_dx10_bc5_and_legacy_bc1_files(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary)/'compressed.dds'
            header = [0]*32
            header[0:5] = [0x20534444, 124, 0xA1007, 8, 8]
            header[7], header[19], header[20] = 2, 32, 4
            header[21] = struct.unpack('<I', b'DX10')[0]
            bc4 = bytes([128, 0, 0, 0, 0, 0, 0, 0])
            path.write_bytes(struct.pack('<32I', *header) + struct.pack('<5I', 83, 3, 0, 1, 0) + bc4*10)
            dds = scan.DDS(path)
            self.assertEqual(dds.image(0).size, (8, 8))
            self.assertEqual(dds.image(1).size, (4, 4))
            self.assertEqual(dds.image(1).getpixel((0, 0)), (128, 128, 254, 255))
            header[21] = struct.unpack('<I', b'DXT1')[0]
            red_block = struct.pack('<HHI', 0xf800, 0, 0)
            path.write_bytes(struct.pack('<32I', *header) + red_block*5)
            self.assertEqual(scan.DDS(path).image(1).getpixel((0, 0)), (255, 0, 0, 255))

    def test_dds_mip_selection_and_scan_report(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary); source = root/'dds'; source.mkdir()
            image = self.image.resize((128, 128), Image.NEAREST)
            write_dds(source/'wall_01b_dm.dds', image)
            write_dds(source/'wall_01_nm.dds', self.image)
            write_dds(source/'single.dds', image, mips=1)
            (source/'broken.dds').write_bytes(b'DDS nope')
            original = (source/'wall_01b_dm.dds').read_bytes()
            dds = scan.DDS(source/'wall_01b_dm.dds')
            self.assertEqual(dds.image(0).tobytes(), image.tobytes())
            self.assertEqual(dds.image(1).tobytes(), self.image.tobytes())
            with self.assertRaises(ValueError): dds.image(2)
            output = root/'report'
            self.assertEqual(scan.main([str(source), '--output', str(output)]), 0)
            summary = json.loads((output/'summary.json').read_text())
            self.assertEqual(summary['files'], 4)
            self.assertEqual(summary['candidates'], 1)
            self.assertEqual(summary['ineligible'], 1)
            self.assertEqual(summary['errors'], 1)
            page = (output/'index.html').read_text(encoding='utf-8')
            self.assertIn('wall_01_nm', page)
            self.assertIn('Export selected names', page)
            self.assertIn('All textures', page)
            self.assertEqual(len(list((output/'previews').glob('*.png'))), 3)
            self.assertEqual(summary['unique_versions'], 4)
            self.assertEqual(summary['previews'], 3)
            self.assertEqual(hashlib.sha256(original).digest(), hashlib.sha256((source/'wall_01b_dm.dds').read_bytes()).digest())
            with self.assertRaises(SystemExit): scan.main([str(source), '--output', str(output)])

    def test_reject_cube_and_truncated_mips(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary)/'x.dds'; write_dds(path, self.image)
            raw = bytearray(path.read_bytes()); struct.pack_into('<I', raw, 28*4, 0x200)
            path.write_bytes(raw)
            with self.assertRaises(ValueError): scan.DDS(path)
            struct.pack_into('<I', raw, 28*4, 0)
            path.write_bytes(raw[:130])
            with self.assertRaises(ValueError): scan.DDS(path).image(0)

    def test_duplicates_collapse_but_same_name_variants_remain(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary); source = root/'dds'; source.mkdir()
            for folder in ('a.wtd', 'b.wdr', 'c.wtd', 'd.wtd'):
                (source/folder).mkdir()
            original = self.image.resize((128, 128), Image.NEAREST)
            write_dds(source/'a.wtd/shared.dds', original)
            raw = bytearray((source/'a.wtd/shared.dds').read_bytes())
            # Irrelevant reserved/header fields must not create another variant.
            struct.pack_into('<I', raw, 8*4, 1234567)
            (source/'b.wdr/shared.dds').write_bytes(raw)
            different = original.copy(); different.putpixel((20, 20), (1, 2, 3, 255))
            write_dds(source/'c.wtd/shared.dds', different)
            # Same mip 0 but a genuinely different mip 1 remains a distinct version.
            raw = bytearray((source/'a.wtd/shared.dds').read_bytes())
            raw[128+128*128*4] ^= 1
            (source/'d.wtd/shared.dds').write_bytes(raw)
            output = root/'report'
            self.assertEqual(scan.main([str(source), '--output', str(output)]), 0)
            summary = json.loads((output/'summary.json').read_text())
            self.assertEqual(summary['files'], 4)
            self.assertEqual(summary['unique_versions'], 3)
            self.assertEqual(summary['unique_names'], 1)
            self.assertEqual(summary['duplicates'], 1)
            import csv
            with (output/'ranking.csv').open(encoding='utf-8-sig') as stream:
                rows = list(csv.DictReader(stream))
            self.assertEqual(sorted(int(row['copies']) for row in rows), [1, 1, 2])
            self.assertEqual({row['variants'] for row in rows}, {'3'})
            self.assertEqual(len(list((output/'previews').glob('*.png'))), 3)

    def test_equivalent_pixels_in_different_dds_encodings_merge(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary); source = root/'dds'; source.mkdir()
            (source/'rgb').mkdir(); (source/'bc1').mkdir()
            write_dds(source/'rgb/red.dds', Image.new('RGBA', (8, 8), (255, 0, 0, 255)))
            header = [0]*32
            header[:5] = [0x20534444, 124, 0xA1007, 8, 8]
            header[7], header[19], header[20] = 2, 32, 4
            header[21] = struct.unpack('<I', b'DXT1')[0]
            block = struct.pack('<HHI', 0xf800, 0, 0)
            (source/'bc1/red.dds').write_bytes(struct.pack('<32I', *header)+block*5)
            groups = scan.index_files(sorted(source.rglob('*.dds')), source, 1)
            self.assertEqual(len(groups), 2)
            rows = scan.merge_versions([scan.analyze(group, source) for group in groups])
            self.assertEqual(len(rows), 1)
            self.assertEqual(rows[0]['copies'], 2)

    def test_preview_limit_does_not_hide_report_rows(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary); source = root/'dds'; source.mkdir()
            for name in ('one', 'two', 'three'):
                write_dds(source/(name+'.dds'), self.image)
            output = root/'report'
            scan.main([str(source), '--output', str(output), '--report-limit', '1'])
            summary = json.loads((output/'summary.json').read_text())
            self.assertEqual(summary['unique_versions'], 3)
            self.assertEqual(summary['previews'], 1)
            page = (output/'index.html').read_text(encoding='utf-8')
            for name in ('one', 'two', 'three'):
                self.assertIn('"name":"'+name+'"', page)

    def test_reuse_report_keeps_fresh_scores_for_modified_files(self):
        import os
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary); source = root/'dds'; source.mkdir()
            path = source/'same.dds'
            write_dds(path, self.image.resize((128, 128), Image.NEAREST))
            first = root/'first'; scan.main([str(source), '--output', str(first)])
            second = root/'second'
            scan.main([str(source), '--output', str(second), '--reuse-report', str(first)])
            self.assertEqual(json.loads((second/'summary.json').read_text())['reused_scores'], 1)
            write_dds(path, self.image.resize((128, 128), Image.BILINEAR))
            newer = (first/'ranking.csv').stat().st_mtime_ns+1000000000
            os.utime(str(path), ns=(newer, newer))
            third = root/'third'
            scan.main([str(source), '--output', str(third), '--reuse-report', str(first)])
            summary = json.loads((third/'summary.json').read_text())
            self.assertEqual(summary['reused_scores'], 0)
            self.assertEqual(summary['candidates'], 0)

    def test_embedded_report_data_preserves_special_names_safely(self):
        import re
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            name = 'sample </script> & "quoted"'
            row = dict(name=name, path='folder/test.dds', sources=['folder/test.dds'],
                       id='test', variant=1, variants=1, copies=1, score=0,
                       content_hash='hash', eligible=False, status='error', preview='', error='Unsupported')
            scan.report([row], root, 60, 1)
            page = (root/'index.html').read_text(encoding='utf-8')
            payload = re.search(r'<script id="texture-data" type="application/json">(.*?)</script>', page, re.S).group(1)
            self.assertNotIn('</script>', payload)
            self.assertEqual(json.loads(payload)['rows'][0]['name'], name)

    def test_recompare_report_replaces_legacy_grid_scores(self):
        import re
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary); source = root/'dds'; source.mkdir()
            write_dds(source/'sample.dds', self.image.resize((128, 128), Image.NEAREST))
            first = root/'first'; scan.main([str(source), '--output', str(first)])
            page = (first/'index.html').read_text(encoding='utf-8')
            match = re.search(r'(<script id="texture-data" type="application/json">)(.*?)(</script>)', page, re.S)
            data = json.loads(match.group(2))
            data['rows'][0].update(score=1, metric='legacy-grid', grid=2, axis='xy')
            (first/'index.html').write_text(page[:match.start(2)]+json.dumps(data)+page[match.end(2):], encoding='utf-8')
            second = root/'second'
            scan.main([str(source), '--output', str(second), '--from-report', str(first)])
            summary = json.loads((second/'summary.json').read_text())
            self.assertEqual(summary['metric'], 'nearest-mip1')
            self.assertEqual(summary['candidates'], 1)
            self.assertEqual(summary['unique_versions'], 1)
            payload = re.search(r'<script id="texture-data" type="application/json">(.*?)</script>',
                                (second/'index.html').read_text(encoding='utf-8'), re.S).group(1)
            row = json.loads(payload)['rows'][0]
            self.assertEqual(row['score'], 100)
            self.assertNotIn('axis', row)
            self.assertEqual(Image.open(str(second/row['preview'])).size, (512, 128))
            write_dds(source/'added.dds', self.image)
            with self.assertRaises(ValueError):
                scan.main([str(source), '--output', str(root/'third'), '--from-report', str(first)])


if __name__ == '__main__':
    unittest.main()
