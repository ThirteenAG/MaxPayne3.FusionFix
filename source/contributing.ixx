module;

#include <common.hxx>

export module contributing;

import common;
import settings;

// A starting point for new features: this module does nothing until you add code below.
//
// Adding a setting takes four steps (the settings use ASI Settings from FusionFixUtils; the same description drives
// the in-game menu, FusionFixHub and fusionfix.io; details in docs/settings.md):
//
// 1. Describe it in settings/MaxPayne3.FusionFix.json. The id is SECTION.Key; label and description point to texts:
//        {
//          "id": "MAIN.MyFeature", "type": "bool", "default": 1,
//          "label": "@myfeature", "description": "@myfeature.description",
//          "page": "fusionfix", "control": [ "switch", "cycler" ],
//          "presets": { "vanilla": 0, "recommended": 1, "enhanced": 1 }
//        }
//    Numbers add "min", "max", "step"; lists use "type": "choice" with "choices". Add "apply": "restart" only when the
//    value can't change while the game runs. "visibility": "editor" keeps it out of the in-game menu (FusionFixHub and
//    fusionfix.io only). The default must equal the Recommended preset; Vanilla is the original game.
//
// 2. Add its texts to settings/MaxPayne3.FusionFix.en.json ("myfeature" and "myfeature.description") and to the other
//    languages' files; English is the fallback. Check them with asi-settings-validate.
//
// 3. Register it in source/settings.ixx: a PREF_MYFEATURE entry in enum Pref and "MAIN.MyFeature" at the same position
//    in CSettings::ids.
//
// 4. Read it in code; the value follows every change from the menu, FusionFixHub and the settings file:
//        if (FusionFixSettings.GetInt(PREF_MYFEATURE)) { ... }
//    Settings apply live by default; to react when a value changes (on the game thread, at most once per frame):
//        FusionFix::onIniFileChange() += [] { /* apply the new value */ };
//    Off must cost nothing: install hooks once and return early while the setting is off.
//
// The in-game menu builds its rows from the description: the setting appears on its "page" (pages with "join" show
// inside the game's own Display, Graphics or Controls screens) without any menu code.

class Contributing
{
public:
    Contributing()
    {
        FusionFix::onInitEvent() += []()
        {
            // Add your code here
        };
    }
} Contributing;