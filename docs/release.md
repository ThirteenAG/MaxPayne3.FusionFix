# Release packages and secrets

The release contains only zips: `MaxPayne3.FusionFix.zip` with `FusionFixHub.exe` at the game's root. The installer is
made on fusionfix.io for each download (the signed hub with a tag the site signs), never by this workflow. The zip never
contains `vulkan.dll`, `nvngx_dlss.dll`, `amd_fidelityfx_*.dll` or the settings file; `release.bat` fails if one gets in.

- **Locally**, `release.bat` takes the hub from `HUB_EXE` (default: `FusionFixHub.exe` next to `release.bat`) and stops
  with a message when it's missing: `set HUB_EXE=D:\path\to\FusionFixHub.exe` before running it.
- **In the workflow**, the hub comes from the latest release of the private repository `ThirteenAG/FusionFixHub-App`,
  read with the secret `HUB_RELEASE_TOKEN`. The download must pass the Authenticode check and be signed with the pinned
  `CN=FusionFix` key; any other signer, or a signature that doesn't verify, fails the build. Without the secret, a
  release run fails; a push or pull request (forks) builds the zip without the hub, with a warning.

Setting up `HUB_RELEASE_TOKEN` (once):

1. GitHub, Settings > Developer settings > Personal access tokens > **Fine-grained tokens** > Generate new token.
2. Resource owner: `ThirteenAG`. Repository access: **Only select repositories** > `ThirteenAG/FusionFixHub-App`.
3. Repository permissions: **Contents: Read-only** (Metadata: Read-only is added automatically). Nothing else.
4. Pick an expiration (and a reminder to renew it), generate, copy the token.
5. In this repository: Settings > Secrets and variables > Actions > **New repository secret**, name
   `HUB_RELEASE_TOKEN`, paste the token.
6. Check: run the workflow (Actions > GitHub Actions Build > Run workflow); the "Download FusionFixHub" step prints
   the hub's signature and the zip contains `FusionFixHub.exe`.
