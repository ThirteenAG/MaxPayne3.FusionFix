# DDS mip comparison scanner

Reads extracted DDS textures and ranks how closely **mip 0 shrunk to half size
using nearest-neighbor sampling matches the file's actual mip 1**. This replaces
the previous repeated-grid heuristic.

Supports Python 3.7+, Pillow and NumPy. The installed versions on this machine work:

```powershell
python -m pip install -r requirements.txt
```

## Extract and scan

First use **ExtractDDS.cmd** to extract the game ([instructions](EXTRACT.md)). Then
drag the extracted DDS folder onto **ScanDDS.cmd**, or run:

```powershell
python scan.py "D:\ExtractedTextures" --output "D:\MipReview"
```

The output directory must be new. Source DDS files and game configuration are
read only. Images are decoded for comparison; nothing is recompressed in the game.

## What the percentage means

For each texture with a usable mip 1:

1. Decode the complete mip 0 and mip 1 images to 8-bit RGBA.
2. Resize mip 0 to mip 1's exact dimensions with Pillow's **NEAREST** sampler,
   with no averaging, bilinear filtering or sharpening.
3. Compare **every pixel**, including all four channels and transparent pixels.
4. Count pixels whose largest channel difference is within the selected tolerance.

The default score is the percentage of pixels matching within **8/255 per RGBA
channel**. A texture is flagged as a close match at **95%** or higher. Compression
can introduce small differences even when a high-resolution texture repeats a
lower-resolution image. The report separately includes the exact-match pixel
percentage, mean absolute RGBA error, 95th-percentile maximum-channel error and
maximum error. **Exact matches only** requires zero error everywhere, not a
rounded percentage of 100.

The image-wide comparison includes 256, 512, 1024, 2048 and other supported
resolutions. For example, a 1024×1024 mip 0 is compared with its 512×512 mip 1.
This does not compare mip 0 with a different DDS variant: each texture is compared
against its own stored mip 1.

The local `ah_cargometnew` samples provide a useful check: its 512×512 version
matches at 97.9675%, while the 256×256 version matches at 83.5144%, using tolerance
8. Neither is byte-exact because of compression differences.

A close match is evidence about those two images, not proof of a bad upscale.
Flat textures match naturally, and some blocky textures may fail this test if their
lower mip was generated with filtering. Review the images before exporting names.

## Browse and export

Open **index.html**. **All textures** includes every distinct version, paginated at
60 per page. It is not capped at 200 previews or restricted to high-scoring files.
The default sort is **Best mip match**. Textures smaller than 128 pixels in either
dimension are hidden by default, including narrow strips such as 1024×64. Choose
**All resolutions (include smaller)** to display them. Filters include:

- **Close matches only** and **Exact matches only**.
- **Names with different versions**.
- Minimum match percentage.
- **1024+ longest side** (and 512+/2048+) to focus on large textures.
- **Largest, then best match** sorting.
- Name and source-path search, single-mip entries and unsupported entries.

Four preview panels show the whole image, original mip 0 detail, nearest-half-size
mip 0 detail and actual mip 1 at the same UV region. Pixel crops are enlarged with
nearest-neighbor sampling so you can compare the result without display smoothing.

Identical copies of a case-insensitive name are grouped with their source paths.
Different versions of that name remain separate. Grouping compares dimensions,
color-space interpretation, mip count and decoded pixels across the **entire** mip
chain; irrelevant DDS header differences and equivalent encodings are ignored.
Different texture names remain separate game identities. Unsupported files can
only be grouped by identical file bytes.

Select approved entries and click **Export selected names**. The downloaded
`MaxPayne3.FusionFix.TextureMipSkip.txt` contains each selected name once. Merge it
with the list beside the ASI and restart the game at Very High texture quality.
Selections persist when browser local storage is available.
The source locations from the selected versions appear as comments directly below
each name. Repeated paths are included only once:

```text
brick_cinder_41b_dm
# Source: pc\levels\s_busdep\bus_bld1.rpf\bus_bld1_txd1.wtd\brick_cinder_41b_dm.dds
```

**FusionFix currently matches names, not resolution or content hashes. Exporting
one variant affects every variant of that name in the game.** Related map names
are suggestions inferred from naming; they are not selected automatically.

## Options and rebuilding a report

```powershell
# Strict pixel equality, with every pixel required to match
python scan.py "D:\ExtractedTextures" --output "D:\MipExact" --tolerance 0 --threshold 100

# Recompute comparisons using an unchanged extraction's existing duplicate groups
python scan.py "D:\ExtractedTextures" --output "D:\MipNewComparison" --from-report "D:\MipReview"

# Reuse compatible prior nearest-comparison scores for unmodified source paths
python scan.py "D:\ExtractedTextures" --output "D:\MipReview2" --reuse-report "D:\MipReview"

# Optional: cap preview generation, but keep every row in the report
python scan.py "D:\ExtractedTextures" --output "D:\MipReview3" --report-limit 500 --jobs 1
```

Defaults: tolerance 8, close-match cutoff 95%, all versions/previews, up to four
concurrent decodes. `--report-limit 0` means all previews. `--from-report` recomputes
all comparisons and previews; omit `--report-limit` with it. It verifies that the
source-file set and modification times still agree with that report. If files
changed, run a full scan to regenerate duplicate groups. `--reuse-report` never
reuses the previous grid-heuristic scores, or scores using a different tolerance.

Outputs:

- **ranking.csv**: each distinct version, ordered by match percentage, its metrics,
  dimensions, mip count, copy count, content hash and errors.
- **sources.csv**: every original DDS mapped to its texture name and version.
- **candidates-review.txt**: unreviewed names above the close-match cutoff.
- **summary.json**: coverage counts, comparison method and tolerance.
- **previews/**: PNG comparisons; the HTML loads only the current page's images.

## DDS support and verification

Supports ordinary 2D DDS with legacy DXT1/3/5, BC4/5 UNORM, DX10 BC1/2/3/4/5/7 UNORM
(and applicable sRGB variants), common RGB/BGRA/RGBA formats and 8-bit luminance.
Arrays, cubes, volumes, signed BC4/5, BC6H and unusual formats remain listed as
unsupported. Entries without a usable mip 1 remain visible but cannot be selected.

```powershell
python test_scan.py
node test_review.js
```

Tests cover nearest resizing, exact and tolerant RGBA comparisons, format decoding,
mip selection, malformed inputs, all-version pagination, duplicate grouping,
distinct same-name mip chains, compatible score reuse and report recomparison.
The two real `ah_cargometnew` variants were also checked directly.

DDS layout references: Microsoft's [DDS_HEADER](https://learn.microsoft.com/en-us/windows/win32/direct3ddds/dds-header)
and [DX10 extension](https://learn.microsoft.com/en-us/windows/win32/direct3ddds/dds-header-dxt10).
