# Shaders

`fixedshaders/` contains the shaders FusionFix changes, in the same layout as
the separate [MaxPayne3.FusionShaders](https://github.com/ThirteenAG/MaxPayne3.FusionShaders)
repository:

```
fixedshaders/win32_50/default.fxc.xml
fixedshaders/win32_50/default/VS_Transform.hlsl
fixedshaders/win32_50/default/PS_Textured_Eight.hlsl
```

One XML per container, with every shader program next to it as ordinary HLSL;
no hashes, assembly or binary shader files.

The complete unmodified reference set is not part of this repository. To add a
fix, copy the container's `.fxc.xml` and its folder from MaxPayne3.FusionShaders
into `fixedshaders/`, edit the HLSL, and run:

```
buildshaders.bat
```

The script compiles only `fixedshaders/` into
`data/update/common/shaders`; that folder is generated and git-ignored. The
first build fills `build/shadertool/hlsl-cache`, and later builds only
recompile shaders whose content changed. CI runs the same script and packages
the generated shaders.

The compiler is [tools/ShaderTool](../tools/ShaderTool), a premake console
project built by the main solution.
