module;

#include <common.hxx>

export module skipintro;

import common;
import settings;

class SkipIntro
{
public:
    SkipIntro()
    {
        FusionFix::onInitEvent() += []()
        {
            if (FusionFixSettings.GetInt("PREF_SKIPINTRO"))
            {
                // legal screens
                auto pattern = hook::pattern("81 FF ? ? ? ? 0F 86 ? ? ? ? E8 ? ? ? ? 89 86 ? ? ? ? 05 ? ? ? ? 89 86 ? ? ? ? C6 86 ? ? ? ? ? E9 ? ? ? ? 3C 01");
                injector::WriteMemory(pattern.get_first(2), 0, true);
                pattern = hook::pattern("05 ? ? ? ? 89 86 ? ? ? ? C6 86 ? ? ? ? ? E9 ? ? ? ? 3C 01");
                injector::WriteMemory(pattern.get_first(1), 0, true);
                pattern = hook::pattern("81 FF ? ? ? ? 0F 86 ? ? ? ? E8 ? ? ? ? 89 86 ? ? ? ? 05 ? ? ? ? 89 86 ? ? ? ? C6 86 ? ? ? ? ? E9 ? ? ? ? 3C 02");
                injector::WriteMemory(pattern.get_first(2), 0, true);
                pattern = hook::pattern("05 ? ? ? ? 89 86 ? ? ? ? C6 86 ? ? ? ? ? E9 ? ? ? ? 3C 02");
                injector::WriteMemory(pattern.get_first(1), 0, true);
                pattern = hook::pattern("81 FF ? ? ? ? 76 66");
                injector::WriteMemory(pattern.get_first(2), 0, true);
                pattern = hook::pattern("05 ? ? ? ? 89 86 ? ? ? ? 8B 11");
                injector::WriteMemory(pattern.get_first(1), 0, true);

                pattern = hook::pattern("81 FF ? ? ? ? 76 4B");
                injector::WriteMemory(pattern.get_first(2), 0, true);
                pattern = hook::pattern("3D ? ? ? ? 7D 0A E8");
                injector::WriteMemory(pattern.get_first(1), 0, true);

                // video
                pattern = hook::pattern("74 25 6A 00 B9");
                injector::WriteMemory<uint8_t>(pattern.get_first(), 0xEB, true);
                pattern = hook::pattern("75 21 53 B9");
                injector::WriteMemory<uint8_t>(pattern.get_first(), 0xEB, true);
            }
        };
    }
} SkipIntro;