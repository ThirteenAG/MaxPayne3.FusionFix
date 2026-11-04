# mp3shadertool

Max Payne 3 (RAGE) shader container tool. It reads the game's `.fxc` effect
containers, writes them as editable XML + HLSL, and rebuilds them with fxc.

## Source layout

The complete reference set lives in the separate MaxPayne3.FusionShaders repo.
`shaders/fixedshaders` in this repo uses the same layout:

```
shaders/fixedshaders/win32_50/default.fxc.xml
shaders/fixedshaders/win32_50/default/VS_Transform.hlsl
shaders/fixedshaders/win32_50/default/PS_Textured_Eight.hlsl
```

One `.fxc.xml` per container carries all effect metadata: vertex type, preset
parameters, shader groups, constant buffers, variables, annotations and
techniques. Every `<Shader>` has `File="<container>/<name>.hlsl"` and
`DataType="hlsl"`; the HLSL is compiled with the profile from its stage and
`Model` attribute. There are no hashes or binary shader files in the source
tree.

`shaders/fixedshaders` is the tree the build compiles; the unmodified originals
are in MaxPayne3.FusionShaders.

## Commands

```
mp3shadertool build-tree   <source-dir> <output-dir> [--hlsl-cache DIR]
mp3shadertool warm-hlsl    <source-dir> --hlsl-cache DIR
mp3shadertool verify-tree  <source-dir> <reference-dir> [--hlsl-cache DIR]
mp3shadertool build        <file.fxc.xml> <file.fxc> [--hlsl-cache DIR]
mp3shadertool extract-tree <game-shaders-dir> <source-dir>
mp3shadertool manifest     <dir> [file]
mp3shadertool hash         <file>
```

`warm-hlsl` compiles each unique HLSL/profile combination once into the cache directory.
`build-tree` uses that cache, so editing one shader recompiles only that
shader. The cache key includes the HLSL content, target stage/model, entry point,
compiler flags and hashes of the compiler DLL and fallback fxc executable.
The versioned key automatically ignores the older source-only cache entries.

`tools/buildshaders.ps1` runs warm-hlsl for `shaders/fixedshaders` and
builds that tree into `data/update/common/shaders`. The reference set in
MaxPayne3.FusionShaders is not compiled here.

## Rebuilding and editing

```
buildshaders.bat
```

Edit any `.hlsl` file and run it again. The first run fills
`build/shadertool/hlsl-cache`; later runs only compile changed sources. CI
caches that directory between workflow runs.

Recompilation does not reproduce byte-identical original programs. The binding
audit below checks their external resource and constant layouts; it is not a
formal proof of equivalence for every shader calculation. `extract-tree` remains available for dumping a
new game build's containers as XML plus bytecode; it is not used by the
committed source tree.

## HLSL generation

The committed HLSL was produced from the shipped `.fxc` bytecode with
[HlslDecompiler](https://github.com/AndresTraks/HlslDecompiler) for DX9, SM4
and SM5, plus a small compatibility fix for its hull-shader operand parser.
The declarations have subsequently been audited against every original binary.
Textures, samplers and other resources have explicit register bindings. Constant
buffers retain their original slots and their members' byte offsets, including
the formerly flattened `$Globals` blocks. DX9 constants retain CTAB registers.
The audit also corrected a relative DX9 matrix-row access in the static-blood
vertex shader that had been exported as scalar component indexing.

The source tree contains 142,610 shader files in 7,906 containers, representing
16,542 unique programs. HlslDecompiler is not a build dependency.

## Binding audit

`tools/auditshaderbindings.py` reads the original RAGE containers directly. It
uses DXBC reflection (RDEF) and DX9 constant tables (CTAB), without invoking a
decompiler. Windows Python and `d3dcompiler_47.dll` are required only for this
optional maintenance command, not for the normal shader build.

```
python tools/auditshaderbindings.py ../MaxPayne3.FusionShaders "C:/original/shaders" --output build/binding-audit
```

The default run computes declaration repairs in memory, compiles them, and
reports which files would change. Add `--fix` to write a shader only after its
repaired source passes validation. Compiler errors and layout mismatches fail
the command and are recorded in the output directory's `report.json`.

The checks cover stage/model, resource slots/counts/dimensions, and used
constants' buffer membership, offsets, sizes, matrix orientation, array shapes
and nested structure member layouts. Shared programs are compiled once per
source/profile combination, while every file is indexed against its original.

To check the actual rebuilt containers, including byte-for-byte preservation
of all non-bytecode container metadata:

```
python tools/auditshaderbindings.py ../MaxPayne3.FusionShaders "C:/original/shaders" --compiled build/reference-containers --output build/container-audit
```

For intentionally modified containers such as FusionFix's Bink replacements,
`--allow-metadata-changes` permits the sampler-state edits while still checking
all resource and constant layouts. Audit reports and generated bytecode stay
under `build/` and are not source assets.

## Container formats

Two rgxe layouts exist in the shipped data:

- **modern**: per-shader constant-buffer references, group headers with
  `Unk1`/`Unk2`/`Unk3`, and six constant-buffer stage slots
  (VS/PS/CS/DS/GS/HS). Used by the DX10/DX10.1/DX11 folders.
- **legacy**: no per-shader buffer references, group headers with only
  `Unk1`/`Unk3`, and two constant-buffer stage slots (VS/PS). Used by the
  DX9 folders, and by four early DX10 `micromovement` files.

The parser auto-detects the layout by requiring an exact end-of-file match,
so it handles all 7,906 shipped containers. A rebuild of the source tree
preserved every container's metadata exactly; only the shader bytecode
changed.

## Build

The tool is a premake console project, built with the rest of the repo:

```
premake5.bat
msbuild build\ShaderTool.vcxproj /property:Configuration=Release /property:Platform=Win32
```

The executable is written to `bin/tools`. It is 32-bit because it uses the
game's 32-bit D3DX9/D3DCompiler DLLs for disassembly; those are loaded at
runtime, and `source/dxsdk` supplies them.
