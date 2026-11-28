"""Rank DDS textures by how closely nearest-neighbor half-size mip 0 matches mip 1."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import csv
import hashlib
import json
import math
import os
import re
import struct
import sys
from pathlib import Path

import numpy as np
from PIL import Image


class DDS:
    def __init__(self, path):
        self.path = Path(path)
        self.data = self.path.read_bytes()
        if len(self.data) < 128 or self.data[:4] != b'DDS ':
            raise ValueError('Not a complete DDS header')
        self.header = list(struct.unpack('<32I', self.data[:128]))
        h = self.header
        if h[1] != 124 or h[19] != 32:
            raise ValueError('Invalid DDS header sizes')
        self.width, self.height, self.mips = h[4], h[3], max(1, h[7])
        if min(self.width, self.height) < 1 or max(self.width, self.height) > 16384:
            raise ValueError('Unsupported DDS dimensions')
        if self.mips > 1 + int(math.log2(max(self.width, self.height))):
            raise ValueError('Invalid mip count')
        if h[28] & (0xfe00 | 0x200000) or h[6] > 1:
            raise ValueError('Cube and volume textures are excluded')
        self.offset, self.block, self.bits = 128, 0, 0
        self.srgb = False
        fourcc = self.data[84:88]
        formats = {b'DXT1': (8, 1), b'DXT3': (16, 2), b'DXT5': (16, 3),
                   b'ATI1': (8, 4), b'BC4U': (8, 4), b'ATI2': (16, 5), b'BC5U': (16, 5)}
        if fourcc == b'DX10':
            if len(self.data) < 148:
                raise ValueError('Truncated DX10 header')
            fmt, dimension, flags, array, _ = struct.unpack('<5I', self.data[128:148])
            self.srgb = fmt in (29, 72, 75, 78, 91, 93, 99)
            if dimension != 3 or flags & 4 or array != 1:
                raise ValueError('Only single 2D textures are supported')
            self.offset = 148
            dxgi = {71: (8, 1), 72: (8, 1), 74: (16, 2), 75: (16, 2),
                    77: (16, 3), 78: (16, 3), 80: (8, 4), 83: (16, 5),
                    98: (16, 7), 99: (16, 7)}
            if fmt in dxgi:
                self.block, self.codec = dxgi[fmt]
                self.format = 'BC%d' % self.codec
            elif fmt in (28, 29, 87, 91, 88, 93):
                self.bits = 32
                self.masks = ((255, 65280, 16711680, 4278190080) if fmt in (28, 29)
                              else (16711680, 65280, 255, 0 if fmt in (88, 93) else 4278190080))
                self.format = 'RGBA8/BGRA8'
            else:
                raise ValueError('Unsupported DXGI format %d (reported, never silently decoded)' % fmt)
        elif fourcc in formats and h[20] & 4:
            self.block, self.codec = formats[fourcc]
            self.format = fourcc.decode('ascii')
        elif h[20] & 0x40 and h[22] in (16, 24, 32):
            self.bits, self.masks = h[22], tuple(h[23:27])
            self.format = 'RGB%d' % self.bits
        elif h[20] & 0x20000 and h[22] == 8:
            self.bits, self.masks = 8, (255, 255, 255, 0)
            self.format = 'L8'
        else:
            raise ValueError('Unsupported DDS pixel format %r' % fourcc)

    def layout(self, level):
        width, height = max(1, self.width >> level), max(1, self.height >> level)
        if self.block:
            pitch = max(1, (width + 3) // 4) * self.block
            return width, height, pitch, pitch * max(1, (height + 3) // 4)
        pitch = (width * self.bits + 7) // 8
        if level == 0 and self.header[2] & 8:
            pitch = max(pitch, self.header[5])
        return width, height, pitch, pitch * height

    def image(self, level):
        if level >= self.mips:
            raise ValueError('Mip %d does not exist' % level)
        offset = self.offset + sum(self.layout(i)[3] for i in range(level))
        width, height, pitch, size = self.layout(level)
        raw = self.data[offset:offset + size]
        if len(raw) != size:
            raise ValueError('Truncated mip %d' % level)
        if self.block and self.codec in (4, 5):
            blocks = np.frombuffer(raw, dtype=np.uint8).reshape(-1, self.block)
            r = decode_bc4(blocks[:, :8], width, height)
            if self.codec == 4:
                return Image.fromarray(np.dstack((r, r, r, np.full_like(r, 255))), 'RGBA')
            g = decode_bc4(blocks[:, 8:], width, height)
            x, y = r.astype(np.float32) / 127.5 - 1, g.astype(np.float32) / 127.5 - 1
            z = ((np.sqrt(np.maximum(0, 1 - x*x - y*y)) + 1) * 127.5).astype(np.uint8)
            return Image.fromarray(np.dstack((r, g, z, np.full_like(r, 255))), 'RGBA')
        if self.block:
            # Use Pillow's native BC decoder; unlike opening the entire DDS this
            # also supports selecting mip 1 on older Pillow versions.
            return Image.frombytes('RGBA', (width, height), raw, 'bcn', (self.codec,))
        rows = np.frombuffer(raw, dtype=np.uint8).reshape(height, pitch)
        pixels = rows[:, :width * (self.bits // 8)].reshape(height, width, self.bits // 8)
        packed = np.zeros((height, width), dtype=np.uint32)
        for i in range(self.bits // 8):
            packed |= pixels[:, :, i].astype(np.uint32) << (8*i)
        channels = []
        for i, mask in enumerate(self.masks):
            if not mask:
                channels.append(np.full((height, width), 255 if i == 3 else 0, dtype=np.uint8))
                continue
            shift = (mask & -mask).bit_length() - 1
            maximum = mask >> shift
            channels.append((((packed & mask) >> shift).astype(np.float64) * 255 / maximum).astype(np.uint8))
        return Image.fromarray(np.dstack(channels), 'RGBA')


def decode_bc4(blocks, width, height):
    """Vectorized BC4_UNORM, also used for the two BC5_UNORM channels."""
    a, b = blocks[:, 0].astype(np.uint16), blocks[:, 1].astype(np.uint16)
    palette = np.empty((len(blocks), 8), dtype=np.uint8)
    palette[:, 0], palette[:, 1] = a, b
    for i in range(2, 8):
        seven = ((8-i)*a + (i-1)*b) // 7
        five = ((6-i)*a + (i-1)*b) // 5 if i < 6 else (0 if i == 6 else 255)
        palette[:, i] = np.where(a > b, seven, five)
    packed = np.zeros(len(blocks), dtype=np.uint64)
    for i in range(6):
        packed |= blocks[:, i+2].astype(np.uint64) << (8*i)
    indices = ((packed[:, None] >> (3*np.arange(16, dtype=np.uint64))) & 7).astype(np.intp)
    decoded = np.take_along_axis(palette, indices, axis=1)
    bh, bw = (height+3)//4, (width+3)//4
    return decoded.reshape(bh, bw, 4, 4).transpose(0, 2, 1, 3).reshape(bh*4, bw*4)[:height, :width]


def compare_mips(top, lower, tolerance=8):
    """Compare every RGBA pixel after nearest-neighbor resizing mip 0 to mip 1."""
    expected = top.resize(lower.size, Image.NEAREST)
    delta = np.abs(np.asarray(expected, dtype=np.int16) - np.asarray(lower, dtype=np.int16))
    error = delta.max(axis=2)
    return dict(metric='nearest-mip1', tolerance=tolerance,
                score=round(100*float(np.mean(error <= tolerance)), 4),
                match_pct=round(100*float(np.mean(error <= tolerance)), 4),
                exact_match_pct=round(100*float(np.mean(error == 0)), 4),
                mae=round(float(delta.mean()), 5),
                p95_error=round(float(np.percentile(error, 95)), 3),
                max_error=int(error.max()), comparison_pixels=int(error.size))


def family(name):
    stem = re.sub(r'_(?:dm|nm|sm|d|n|s)$', '', name.lower())
    return re.sub(r'(?<=\d)[a-z]$', '', stem)


def storage_fingerprint(path):
    """Fast first pass: normalize headers, retain dimensions and every stored mip."""
    try:
        dds = DDS(path)
        size = sum(dds.layout(i)[3] for i in range(dds.mips))
        if dds.offset+size > len(dds.data):
            raise ValueError('Truncated mip chain')
        metadata = (dds.width, dds.height, dds.mips, dds.srgb, dds.block,
                    getattr(dds, 'codec', None), dds.bits, getattr(dds, 'masks', None))
        digest = hashlib.sha256(repr(metadata).encode('ascii'))
        digest.update(dds.data[dds.offset:dds.offset+size])
        return 'dds-'+digest.hexdigest()
    except Exception:
        # Keep unsupported/corrupt files visible, and collapse their exact copies.
        digest = hashlib.sha256()
        with path.open('rb') as stream:
            for chunk in iter(lambda: stream.read(1024*1024), b''):
                digest.update(chunk)
        return 'raw-'+digest.hexdigest()


def index_files(paths, root, jobs):
    groups = {}
    def identify(path):
        try:
            return path, storage_fingerprint(path)
        except OSError:
            return path, 'unreadable-'+hashlib.sha256(str(path).encode('utf-8')).hexdigest()
    with ThreadPoolExecutor(max_workers=jobs) as executor:
        for index, (path, digest) in enumerate(executor.map(identify, paths)):
            key = (path.stem.lower(), digest)
            if key not in groups:
                groups[key] = dict(name=path.stem, path=str(path.relative_to(root)), sources=[], storage_hash=digest)
            groups[key]['sources'].append(str(path.relative_to(root)))
            if (index+1) % 1000 == 0:
                print('Indexed %d / %d files; %d distinct stored versions' % (index+1, len(paths), len(groups)), flush=True)
    return list(groups.values())


def analyze(group, root, previous=None, tolerance=8):
    row = dict(group, score=0, mip1_score=0, status='error', preview='', eligible=False)
    try:
        dds = DDS(root/row['path'])
        row.update(width=dds.width, height=dds.height, mips=dds.mips, format=dds.format)
        top = dds.image(0)
        lower = dds.image(1) if dds.mips > 1 else None
        digest = hashlib.sha256(repr((dds.width, dds.height, dds.mips, dds.srgb)).encode('ascii'))
        # Deduplicate decoded pixels as well: different DDS encodings or unused
        # header values do not create separate versions. A change in ANY mip does.
        for level in range(dds.mips):
            image = top if level == 0 else (lower if level == 1 else dds.image(level))
            digest.update(image.tobytes())
        row['content_hash'] = digest.hexdigest()
        if dds.mips < 2 or min(dds.width, dds.height) < 8:
            row.update(status='ineligible', error='No usable lower mip')
        else:
            cached = previous.get(row['path']) if previous else None
            if (cached and cached.get('metric') == 'nearest-mip1'
                    and int(cached.get('tolerance', -1)) == tolerance
                    and all(str(row[key]) == cached.get(key) for key in ('width', 'height', 'mips', 'format'))):
                for key in ('score', 'match_pct', 'exact_match_pct', 'mae', 'p95_error'):
                    row[key] = float(cached[key])
                row.update(metric='nearest-mip1', tolerance=tolerance, max_error=int(cached['max_error']),
                           comparison_pixels=int(cached['comparison_pixels']), reused_score=True)
            else:
                row.update(compare_mips(top, lower, tolerance))
            row.update(status='ok', eligible=True)
    except Exception as error:
        row.update(status='error', error=str(error), content_hash=row['storage_hash'])
    return row


def merge_versions(rows):
    merged = {}
    for row in rows:
        key = (row['name'].lower(), row['content_hash'])
        if key in merged:
            merged[key]['sources'].extend(row['sources'])
        else:
            merged[key] = row
    rows = list(merged.values())
    names = {}
    for row in rows:
        row['sources'] = sorted(set(row['sources']), key=str.lower)
        row['copies'] = len(row['sources'])
        row['id'] = hashlib.sha256((row['name'].lower()+'\0'+row['content_hash']).encode('utf-8')).hexdigest()[:24]
        names.setdefault(row['name'].lower(), []).append(row)
    for versions in names.values():
        versions.sort(key=lambda r: r['path'].lower())
        for index, row in enumerate(versions):
            row.update(variant=index+1, variants=len(versions))
    return sorted(rows, key=lambda r: (r['name'].lower(), r['variant']))


def preview(top, lower, target):
    size = 128
    whole = top.copy(); whole.thumbnail((size, size), Image.BILINEAR)
    side = min(128, top.width, top.height)
    x, y = max(0, ((top.width-side)//4)*2), max(0, ((top.height-side)//4)*2)
    original = top.crop((x, y, x+side, y+side)).resize((size, size), Image.NEAREST)
    canvas = Image.new('RGBA', (size*4, size))
    canvas.paste(whole, ((size-whole.width)//2, (size-whole.height)//2))
    canvas.paste(original, (size, 0))
    if lower:
        box = (x//2, y//2, max(x//2+1, (x+side)//2), max(y//2+1, (y+side)//2))
        nearest = top.resize(lower.size, Image.NEAREST).crop(box).resize((size, size), Image.NEAREST)
        actual = lower.crop(box).resize((size, size), Image.NEAREST)
        canvas.paste(nearest, (size*2, 0)); canvas.paste(actual, (size*3, 0))
    canvas.save(str(target))


def generate_preview(row, root, output):
    if row['status'] == 'error':
        return row
    try:
        dds = DDS(root/row['path'])
        row['preview'] = 'previews/'+row['id']+'.png'
        preview(dds.image(0), dds.image(1) if dds.mips > 1 else None, output/row['preview'])
    except Exception as error:
        row.update(preview='', preview_error=str(error))
    return row


def report(rows, output, threshold, files, tolerance=8):
    families = {}
    for row in rows:
        families.setdefault(family(row['name']), set()).add(row['name'])
    for row in rows:
        row['companions'] = sorted(n for n in families.get(family(row['name']), set()) if n != row['name'])
        row['candidate'] = row['eligible'] and row['score'] >= threshold
    fields = ['name', 'variant', 'variants', 'copies', 'path', 'status', 'width', 'height', 'mips', 'format',
              'score', 'metric', 'match_pct', 'exact_match_pct', 'tolerance', 'mae', 'p95_error', 'max_error', 'comparison_pixels', 'candidate',
              'companions', 'content_hash', 'preview', 'preview_error', 'error']
    with (output/'ranking.csv').open('w', newline='', encoding='utf-8-sig') as stream:
        writer = csv.DictWriter(stream, fields, extrasaction='ignore'); writer.writeheader()
        for row in sorted(rows, key=lambda r: (-r['score'], r['name'].lower(), r['variant'])):
            writer.writerow(dict(row, companions='; '.join(row['companions'])))
    with (output/'sources.csv').open('w', newline='', encoding='utf-8-sig') as stream:
        writer = csv.writer(stream); writer.writerow(['name', 'variant', 'content_hash', 'source'])
        for row in rows:
            writer.writerows((row['name'], row['variant'], row['content_hash'], source) for source in row['sources'])
    with (output/'candidates-review.txt').open('w', encoding='utf-8') as stream:
        stream.write('# Unreviewed nearest-mip matches. Review index.html before using this list.\n')
        for name in sorted(set(row['name'] for row in rows if row['candidate'])):
            stream.write(name+'\n')
    summary = dict(files=files, unique_versions=len(rows), unique_names=len(set(r['name'].lower() for r in rows)),
                   duplicates=files-len(rows), candidates=sum(r['candidate'] for r in rows),
                   errors=sum(r['status']=='error' for r in rows),
                   ineligible=sum(r['status']=='ineligible' for r in rows), threshold=threshold,
                   metric='nearest-mip1', tolerance=tolerance,
                   previews=sum(bool(r['preview']) for r in rows),
                   reused_scores=sum(bool(r.get('reused_score')) for r in rows))
    data = json.dumps(dict(summary=summary, rows=rows), ensure_ascii=True, separators=(',', ':'))
    data = data.replace('<', '\\u003c').replace('>', '\\u003e').replace('&', '\\u0026')
    template = Path(__file__).with_name('review.html').read_text(encoding='utf-8')
    (output/'index.html').write_text(template.replace('__TEXTURE_DATA__', data), encoding='utf-8')
    (output/'review.js').write_bytes(Path(__file__).with_name('review.js').read_bytes())
    (output/'summary.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
    return summary


def rescore_report(args, paths):
    source = args.from_report/'index.html'
    page = source.read_text(encoding='utf-8')
    match = re.search(r'<script id="texture-data" type="application/json">(.*?)</script>', page, re.S)
    if not match:
        raise ValueError('Previous report has no distinct-version data; use a full scan')
    previous = json.loads(match.group(1))
    rows = previous['rows']
    sources = {name for row in rows for name in row['sources']}
    if sources != {str(path.relative_to(args.input)) for path in paths}:
        raise ValueError('Extraction file set changed; run a full scan to regroup versions')
    timestamp = source.stat().st_mtime_ns
    for name in sources:
        relative = Path(name)
        if relative.anchor or '..' in relative.parts or (args.input/relative).stat().st_mtime_ns > timestamp:
            raise ValueError('Extraction changed since the report; run a full scan')
    if any(row['path'] not in sources for row in rows):
        raise ValueError('Invalid representative paths in previous report')
    args.output.mkdir(parents=True); (args.output/'previews').mkdir()
    print('Comparing mip 0 / mip 1 for %d distinct versions; duplicate grouping preserved.' % len(rows), flush=True)

    def compare_row(row):
        for key in ('grid', 'axis', 'ratio_x', 'ratio_y', 'support', 'detail', 'mip1_score', 'reused_score'):
            row.pop(key, None)
        row.update(preview='', eligible=False, score=0)
        try:
            dds = DDS(args.input/row['path'])
            top = dds.image(0)
            lower = dds.image(1) if dds.mips > 1 else None
            row.update(width=dds.width, height=dds.height, mips=dds.mips, format=dds.format)
            if lower and min(dds.width, dds.height) >= 8:
                row.update(compare_mips(top, lower, args.tolerance), status='ok', eligible=True)
                row.pop('error', None)
            else:
                row.update(status='ineligible', error='No usable lower mip')
            row['preview'] = 'previews/'+row['id']+'.png'
            preview(top, lower, args.output/row['preview'])
        except Exception as error:
            row.update(status='error', error=str(error), preview='')
        return row

    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        for index, _ in enumerate(executor.map(compare_row, rows)):
            if (index+1) % 500 == 0:
                print('Compared and previewed %d / %d' % (index+1, len(rows)), flush=True)
    summary = report(rows, args.output, args.threshold, len(paths), args.tolerance)
    print(json.dumps(summary)); print('Review: '+str((args.output/'index.html').absolute()))
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', type=Path, help='Extracted DDS folder (searched recursively)')
    parser.add_argument('--output', type=Path, required=True, help='New report directory; must not already exist')
    parser.add_argument('--threshold', type=float, default=95, help='Minimum matching-pixel percentage to flag (default: 95; all textures stay visible)')
    parser.add_argument('--report-limit', type=int, default=0, help='Optional preview limit; 0 = all (does not hide rows)')
    parser.add_argument('--jobs', type=int, default=min(4, os.cpu_count() or 1), help='Concurrent decodes (default: up to 4)')
    parser.add_argument('--reuse-report', type=Path, help='Reuse scores from a previous ranking.csv when source metadata is unchanged; content is still rechecked')
    parser.add_argument('--tolerance', type=int, default=8, help='Maximum difference in each 8-bit RGBA channel (default: 8; use 0 for exact)')
    parser.add_argument('--from-report', type=Path, help='Reuse duplicate grouping from an unchanged extraction report and recompute mip comparisons')
    args = parser.parse_args(argv)
    if not args.input.is_dir(): parser.error('Input must be an existing directory')
    if not 0 <= args.threshold <= 100 or args.report_limit < 0 or not 1 <= args.jobs <= 32 or not 0 <= args.tolerance <= 255:
        parser.error('Invalid threshold, preview limit, or job count (1–32)')
    if args.output.exists(): parser.error('Output directory already exists; choose a new report directory')
    paths = sorted((p for p in args.input.rglob('*') if p.is_file() and p.suffix.lower() == '.dds'), key=str)
    if not paths: parser.error('No DDS files found')
    if args.from_report:
        if args.reuse_report:
            parser.error('Choose --from-report or --reuse-report, not both')
        if args.report_limit:
            parser.error('--from-report regenerates all comparisons and previews; omit --report-limit')
        return rescore_report(args, paths)
    previous = {}
    if args.reuse_report:
        ranking = args.reuse_report/'ranking.csv'
        if not ranking.is_file(): parser.error('Previous report has no ranking.csv')
        timestamp = ranking.stat().st_mtime_ns
        with ranking.open(encoding='utf-8-sig', newline='') as stream:
            for row in csv.DictReader(stream):
                if row.get('status') != 'ok' or row.get('metric') != 'nearest-mip1' or not all(row.get(key) for key in ('score', 'match_pct', 'exact_match_pct', 'mae', 'p95_error', 'max_error', 'comparison_pixels', 'tolerance')):
                    continue
                path = args.input/row['path']
                if path.is_file() and path.stat().st_mtime_ns <= timestamp:
                    previous[row['path']] = row
        print('Prior scores available for %d unchanged source paths; mip content will be rechecked.' % len(previous), flush=True)
    args.output.mkdir(parents=True); (args.output/'previews').mkdir()
    groups = index_files(paths, args.input, args.jobs)
    print('Analyzing %d distinct stored versions...' % len(groups), flush=True)
    rows = []
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        for index, row in enumerate(executor.map(lambda g: analyze(g, args.input, previous, args.tolerance), groups)):
            rows.append(row)
            if (index+1) % 100 == 0: print('Analyzed %d / %d' % (index+1, len(groups)), flush=True)
    rows = merge_versions(rows)
    previews = [row for row in rows if row['status'] != 'error']
    if args.report_limit:
        previews = sorted(previews, key=lambda r: -r['score'])[:args.report_limit]
    print('Generating %d previews for %d unique versions...' % (len(previews), len(rows)), flush=True)
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        for index, _ in enumerate(executor.map(lambda row: generate_preview(row, args.input, args.output), previews)):
            if (index+1) % 500 == 0: print('Previewed %d / %d' % (index+1, len(previews)), flush=True)
    summary = report(rows, args.output, args.threshold, len(paths), args.tolerance)
    print(json.dumps(summary)); print('Review: '+str((args.output/'index.html').absolute()))
    return 0


if __name__ == '__main__':
    sys.exit(main())
