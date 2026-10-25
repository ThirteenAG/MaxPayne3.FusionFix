# Settings and the Fusion Fix menu

Fusion Fix describes its settings with [ASI Settings](https://github.com/ThirteenAG/FusionFixUtils/tree/main/asi_settings) ([specification](https://github.com/ThirteenAG/FusionFixUtils/blob/main/asi_settings/SPEC.md)). The old `FusionFix_Menu*` exports are gone; plugins don't call Fusion Fix any more.

## Fusion Fix's own settings

- `settings/MaxPayne3.FusionFix.json` is the description: every setting, its type, range, default, page and presets. It is embedded as the resource `ASISETTINGS/SETTINGS` by `source/resources/Settings.rc`.
- `settings/MaxPayne3.FusionFix.<language>.json` are the translations, one per BCP 47 tag (`en`, `fr`, `de`, `it`, `es`, `ja`, `ru`, `pt-BR`, `pl`, `ko`), embedded as `ASISETTINGS_TEXT/<tag>`. They also hold the text of the rows the menu adds itself (`menu.*`). English is required; missing keys fall back to it.
- `external/FusionFixUtils/asi_settings` (the FusionFixUtils submodule) is the shared implementation; change it there only. `source/settings.ixx` loads the settings with `asi_settings::Plugin`, which writes `MaxPayne3.FusionFix.cfg` next to the plugin, and exports `AsiSettings_GetApi`.
- Run `asi-settings-validate` from the specification's tools on the description and translations (or on the built `.asi`) after changing them.

A new setting is one entry in the description, its texts in the translations, and a `Pref` with its id in `source/settings.ixx`.

## Menu host

Fusion Fix adds one row to the game's Settings, Plugins, after Graphics. Each time the Options screen is built, it claims the menu host role (`asi_settings::ClaimHostRole`) and finds every loaded module with the `AsiSettings_GetApi` export (`asi_settings::FindLoadedPlugins`), with texts in the game's language. Without the host role (another plugin draws the menu) it shows only its own settings.

- Plugins opens the list of plugins with menu rows: Fusion Fix first, then the others by `plugin.priority`, then by name. Each entry opens one page of that plugin with the settings of all its pages, its compatibility settings at the end. Back returns one level at a time.
- Rows are built from the description and use the game's controls: `bool` and `choice` settings and values with `special` or `suggestions` cycle through a list, numbers with `min`, `max` and `step` use the slider. A value outside the list shows as Custom. Settings with `visibility` other than `menu`, and types the menu can't edit, stay in editors and the file.
- `visibleIf` hides rows, `enabledIf` keeps changes from being made. Settings the plugin reports as hidden (`GetState`) are left out, and lists only offer the values usable now (`GetChoices`).
- A plugin's first page starts with its preset selector (Vanilla, Recommended, Enhanced, or Custom when the values match none) and Apply preset, which asks for a confirmation in the help text.
- Restore Defaults sets the page's settings to their defaults.
- Pages with `"join": true` and the section `display`, `graphics`, `controls` (or `gamepad`) or `audio` are shown inside the game's own page instead of a page of their own. Display's own Restore Defaults also restores the rows joined to it (Graphics and Controls have none).

Values cross through the plugin's `Get` and `Set`; the plugin stores and applies them. Fusion Fix subscribes to every plugin's changes and builds an open page again when its rows change.
