# Extract Max Payne 3 textures

**ExtractDDS.cmd** exports the original DDS pixel data and complete stored mip
chains from a Max Payne 3 **PC** installation. It handles RPF4 archives (including
nested archives), loose RSC5 resources, standalone texture dictionaries and
textures embedded in drawables, drawable dictionaries, fragments and other RSC5
resources. Referenced external textures are exported from their owning dictionary,
not copied into every model that references them.

Requires Windows and Python 3.7 or newer. No Pillow, NumPy, OpenIV, game process,
internet connection or third-party crypto package is needed for extraction.
Windows CNG opens the archive tables using key material located in your local
`MaxPayne3.exe`. Both base-game and DLC archive keys are recovered in memory; keys
and game files are not bundled with the tool.

## Whole game

Drag the folder containing **MaxPayne3.exe** onto **ExtractDDS.cmd**. It creates a
new `ExtractedDDS-*` folder inside the game folder. Original files are read only.
Keep enough free disk space: the decompressed DDS collection can occupy tens of
gigabytes. Files with the same name in different containers are kept separately.

For a custom destination, from this tools directory:

```powershell
python extract.py "G:\Games\Max Payne 3" --output "D:\MP3-Textures"
```

The output directory must not already exist. The layout retains the full source
archive chain, original container extension and texture name:

```text
MP3-Textures/
  pc/levels/s_busdep/bus_bld1.rpf/
    bus_bld1_txd1.wtd/
      brick_cinder_41b_dm.dds
    bd_fencedgate.wdr/
      bd_chainlink_dm.dds
  update.rpf/platform/textures/example.wtd/
    example.dds
  manifest.csv
  errors.csv
  summary.json
```

If a single container owns multiple textures with the same name, additional copies
go in `<container>/_duplicates/<descriptor-offset>/<name>.dds`. Their DDS basenames
stay unchanged, so the scanner still exports the correct logical name. Archive
components containing characters invalid in Windows filenames are sanitized.

## Validate first, or extract a subset

```powershell
# Read and validate all archives/resources; write manifests without DDS payloads
python extract.py "G:\Games\Max Payne 3" --output "D:\MP3-Inventory" --inventory

# Extract one archive, preserving its WTD/WDR source folders
python extract.py "G:\Games\Max Payne 3\pc\levels\s_busdep\bus_bld1.rpf" --output "D:\BusDepotTextures"

# Match source paths containing bus_bld1 (archive tables are still traversed)
python extract.py "G:\Games\Max Payne 3" --output "D:\BusDepotTextures2" --select bus_bld1

# Specify an unpacked executable if the local build's key cannot be located
python extract.py "G:\Games\Max Payne 3" --output "D:\MP3-Textures2" --exe "D:\MaxPayne3_dump.exe"
```

`summary.json` contains the texture count, estimated/written DDS byte total, error
count and completion state. `manifest.csv` records each texture's owning resource,
output path, dimensions, format and mip count. `errors.csv` records unsupported or
damaged inputs; an incomplete extraction returns a nonzero exit status. Ctrl+C
saves a partial manifest and marks the summary as interrupted.

The tool scans the actual installation, including base archives, installed DLC and
loose update resources. It preserves all versions; it does not resolve the game's
override/mount precedence or deduplicate texture data across containers. Existing
extractor output folders carry a marker and are skipped on subsequent whole-game
scans. Plugins, saves, crash dumps and Git metadata are excluded. Point the tool at
a specific file if you deliberately need an asset in one of those locations.

## Scan the result

Drag the extraction folder onto **ScanDDS.cmd**, or run:

```powershell
python scan.py "D:\MP3-Textures" --output "D:\MP3-MipReview"
```

The extractor preserves compressed BC/DXT data without recompressing it. It also
writes the game's uncompressed RGB/luminance, numeric D3D formats, cubes and volumes
as DDS. The candidate scanner intentionally excludes cubes and volumes, and may
report some unusual DDS formats as unsupported. Texture references with no owned
pixel storage are omitted. Invalid pointers, mip ranges, compression and dictionary
entries are checked and reported.

## Verification and format references

```powershell
python test_extract.py
```

Tests exercise byte-preserved mips, embedded resources, nested archives, path
containment, existing-file protection, invalid bounds/compression, inventory-only
mode, output exclusion and Windows AES. The bus-depot archive was also exported
and its brick texture's entire mip payload compared byte-for-byte with a game
upload capture; all 38 DDS files were accepted by the candidate scanner.
The complete local installation was inventoried as well: 128,929 texture entries,
zero errors and approximately 28.5 GiB of DDS output, counting separate copies in
different sources. Other installations and mod sets can differ.

Format research: [Swage RPF structures](https://github.com/0x1F9F1/Swage/blob/master/src/games/rage/rpf2.h),
[archive reader](https://github.com/0x1F9F1/Swage/blob/master/src/games/rage/rpf2.cpp),
[AES transform](https://github.com/0x1F9F1/Swage/blob/master/src/games/rage/cipher16.cpp)
and public key fingerprints. Resource/texture layouts were checked against this
installation's decompressed PC assets and FusionFix's game analysis.
