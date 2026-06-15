[![Actions Status: Release](https://github.com/ThirteenAG/MaxPayne3.FusionFix/actions/workflows/msvc_x86.yml/badge.svg)](https://github.com/ThirteenAG/MaxPayne3.FusionFix/actions)

<p align="center">
  <a href="https://github.com/ThirteenAG/MaxPayne3.FusionFix" target="_blank"><img width="600" src="https://github.com/user-attachments/assets/6b150869-9e5c-4463-aeb8-18a1d19076b0"></a>
  <br />
  <a href="https://patreon.fusionfix.io/" target="_blank"><img width="100%" src="https://fusionlegacyinitiative.com/sponsors-progress/sponsors-progress-ffmp3.svg"></a>
  <br />
  <a href="https://github.com/sponsors/ThirteenAG"><img src="https://raw.githubusercontent.com/ThirteenAG/thirteenag.github.io/refs/heads/master/img/buttons/github.svg" width="250"></a>
  <a href="https://ko-fi.com/thirteenag"><img src="https://raw.githubusercontent.com/ThirteenAG/thirteenag.github.io/refs/heads/master/img/buttons/kofi.svg" width="250"></a>
  <a href="https://paypal.me/SergeyP13"><img src="https://raw.githubusercontent.com/ThirteenAG/thirteenag.github.io/refs/heads/master/img/buttons/paypal.svg" width="250"></a>
  <a href="https://www.patreon.com/ThirteenAG"><img src="https://raw.githubusercontent.com/ThirteenAG/thirteenag.github.io/refs/heads/master/img/buttons/patreon.svg" width="250"></a>
  <a href="https://boosty.to/thirteenag"><img src="https://raw.githubusercontent.com/ThirteenAG/thirteenag.github.io/refs/heads/master/img/buttons/boosty.svg" width="250"></a><br><br>
  <a href="https://discord.gg/2ckFCS572Z" target="_blank"><img width="200" src="https://raw.githubusercontent.com/ThirteenAG/GTAIV.EFLC.FusionFix/refs/heads/master/installer/discord.svg"></a>
  &nbsp;&nbsp;&nbsp;
  <a href="https://t.me/fusionfix" target="_blank"><img width="200" src="https://raw.githubusercontent.com/ThirteenAG/GTAIV.EFLC.FusionFix/refs/heads/master/installer/telegram.svg"></a>
  &nbsp;&nbsp;&nbsp;
  <a href="https://www.youtube.com/@FusionFix10" target="_blank"><img width="200" src="https://raw.githubusercontent.com/ThirteenAG/GTAIV.EFLC.FusionFix/refs/heads/master/installer/youtube.svg"></a>
  &nbsp;&nbsp;&nbsp;
  <a href="https://x.com/fusionfix10" target="_blank"><img width="200" src="https://raw.githubusercontent.com/ThirteenAG/GTAIV.EFLC.FusionFix/refs/heads/master/installer/x.svg"></a>
  &nbsp;&nbsp;&nbsp;
</p>

This projects aims to add new features and fix some issues in Max Payne 3. Also available for [GTA IV: The Complete Edition](https://github.com/ThirteenAG/GTAIV.EFLC.FusionFix#readme).

<p align="center">
  <img src="https://github.com/ThirteenAG/MaxPayne3.FusionFix/assets/4904157/e0cdd907-f554-4685-93f7-17183237fe56">
</p>

## Installation:

> [!NOTE]
> Install Max Payne 3: The Complete Edition (v1.0.0.255 and above required)
>
> **Download**: [MaxPayne3.FusionFix](https://github.com/ThirteenAG/MaxPayne3.FusionFix/releases/latest/download/MaxPayne3.FusionFix.zip)
>
> Unpack content of the archive to your **Max Payne 3** root directory.

> [!WARNING]
> Non-Windows users (Proton/Wine) need to perform a [DLL override](https://cookieplmonster.github.io/setup-instructions/#proton-wine).

> [!IMPORTANT]
> This fix was tested only with latest official update and latest [ASI Loader](https://github.com/ThirteenAG/Ultimate-ASI-Loader/releases/latest/download/Ultimate-ASI-Loader.zip) (included in the archive).

---

### New menu options

- **BorderlessWindowed**, scroll through **SETTINGS -> GRAPHICS -> FULLSCREEN** to switch between windowed and borderless modes
- **GamepadIcons**, scroll through **SETTINGS -> CONTROLS -> GAMEPAD -> CONFIGURATION** to select various controller icon styles (Xbox 360, Xbox One, PS3, PS4, PS5, Nintendo Switch, Steam Deck, Steam Controller)

### New options

> [!NOTE]
> **MaxPayne3.FusionFix.ini** can be edited at any time, before and after the game is launched

- **SkipIntro**, added an option to skip intro
- **HideSkipButton**, added an option to hide ![skip](https://i.imgur.com/vwELI93.png) in cutscenes
- **DisableGlobalLeaderboards**, prevents Hoboken Alleys coop map from crashing the game
- **OutlinesSizeMultiplier**, added an option to increase the size of subtitle text outlines
- **DisableDeviceChangeEvent**, fixes an issue when the game randomly enters pause menu
- **LightSyncRGB**, only Logitech hardware is supported, requires Logitech G HUB app

  ![LightSyncRGB](https://github.com/ThirteenAG/MaxPayne3.FusionFix/assets/4904157/64f8da07-eef0-4410-a412-a0d1c0e0f3e0)

  [**Watch full clip on YouTube**](https://youtu.be/-gucoqZh0mI)

# Contributing

If you have an idea for a fix, add a module with its implementation to [source](https://github.com/ThirteenAG/MaxPayne3.FusionFix/tree/main/source) directory and open a pull request. See [contributing.ixx](https://github.com/ThirteenAG/MaxPayne3.FusionFix/blob/main/source/contributing.ixx) for reference.

# Reporting issues

If you've encountered an issue, report it [here](https://github.com/ThirteenAG/MaxPayne3.FusionFix/issues).
