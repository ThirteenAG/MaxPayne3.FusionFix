module;

#include <common.hxx>

export module hideskip;

import common;
import settings;

class HideSkip
{
public:
    HideSkip()
    {
        FusionFix::onInitEvent() += []()
        {
            auto pattern = hook::pattern("8B C8 89 86 ? ? ? ? E8 ? ? ? ? D9 EE 8B 86 ? ? ? ? 8B 38 83 EC 08 D9 54 24 04 8D 4C 24 3C D9 1C 24 E8 ? ? ? ? F3 0F 7E 00 8B 97 ? ? ? ? 83 EC 18 8B CC 66 0F D6 01 F3 0F 7E 40 ? 66 0F D6 41 ? F3 0F 7E 40 ? 6A 18 68");
            static raw_mem fnHideSkip1(pattern.get_first(8), { 0x90, 0x90, 0x90, 0x90, 0x90 }); // nop x5
            pattern = hook::pattern("8B C8 89 86 ? ? ? ? E8 ? ? ? ? D9 EE 8B 86 ? ? ? ? 8B 38 83 EC 08 D9 54 24 04 8D 4C 24 20 D9 1C 24 E8 ? ? ? ? F3 0F 7E 00 8B 97 ? ? ? ? 83 EC 18 8B CC 66 0F D6 01 F3 0F 7E 40 ? 66 0F D6 41 ? F3 0F 7E 40 ? 6A 18 68 ? ? ? ? 66 0F D6 41 ? 8B 8E ? ? ? ? 6A 18");
            static raw_mem fnHideSkip2(pattern.get_first(8), { 0x90, 0x90, 0x90, 0x90, 0x90 }); // nop x5

            static auto HideSkipCB = []()
            {
              if (FusionFixSettings.GetInt("PREF_HIDESKIP"))
              {
                  fnHideSkip1.Write();
                  fnHideSkip2.Write();
              }
              else
              {
                  fnHideSkip1.Restore();
                  fnHideSkip2.Restore();
              }
            };

            HideSkipCB();
            
            FusionFix::onIniFileChange() += []()
            {
                HideSkipCB();
            };
        };
    }
} HideSkip;