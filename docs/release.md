# Release packages and secrets

The release contains only zips: `MaxPayne3.FusionFix.zip`. It never contains `FusionFixHub.exe`, which is distributed
through fusionfix.io, and never `vulkan.dll`, `nvngx_dlss.dll`, `amd_fidelityfx_*.dll` or the
settings file. The installer is made on fusionfix.io for each download, never by this workflow.

The workflow needs the code signing secrets `CODE_SIGNING_PFX` and `CODE_SIGNING_PASSWORD`; no other secret.
