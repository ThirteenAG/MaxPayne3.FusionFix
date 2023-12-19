module;

#include <common.hxx>

export module outlines;

import common;
import settings;

float fOutlinesSizeMultiplier;
float* dword_1FCA9A8;
void __fastcall sub_010AFD30(float* _this, void* edx, float a2)
{
    a2 *= FusionFixSettings.GetFloat("PREF_OUTLINESIZE");

    if (a2 <= 0.0)
    {
        _this[8] = 0.0;
        _this[13] = 0.0;
    }
    else
    {
        _this[8] = a2 / *dword_1FCA9A8;
        _this[13] = a2 / *dword_1FCA9A8;
    }
}

class Outlines
{
public:
    Outlines()
    {
        FusionFix::onInitEvent() += []()
        {
            dword_1FCA9A8 = *hook::get_pattern<float*>("F3 0F 10 86 ? ? ? ? F3 0F 59 05 ? ? ? ? 51 8D 8C 24", 12);
            
            auto pattern = hook::pattern("E8 ? ? ? ? 68 ? ? ? ? 8D 94 24 ? ? ? ? 6A 02");
            injector::MakeCALL(pattern.get_first(0), sub_010AFD30, true);
            
            pattern = hook::pattern("D9 1C 24 E8 ? ? ? ? 68 ? ? ? ? 68");
            injector::MakeCALL(pattern.get_first(3), sub_010AFD30, true);
            
            pattern = hook::pattern("E8 ? ? ? ? 68 ? ? ? ? 8D 44 24 20 6A 03 50 88 1D ? ? ? ? C6 05 ? ? ? ? ? 88 1D ? ? ? ? E8 ? ? ? ? 8B 08");
            injector::MakeCALL(pattern.get_first(0), sub_010AFD30, true);
            
            pattern = hook::pattern("E8 ? ? ? ? F3 0F 10 44 24 ? 8D 4C 24 30 F3 0F 11 05 ? ? ? ? F3 0F 10 44 24 ? 51 B9 ? ? ? ? F3 0F 11 05 ? ? ? ? E8 ? ? ? ? 8A 5C 24 0F 80 FB FF 75 0C");
            injector::MakeCALL(pattern.get_first(0), sub_010AFD30, true);
        };
    }
} Outlines;