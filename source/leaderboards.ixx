module;

#include <common.hxx>

export module leaderboards;

import common;
import settings;

class Leaderboards
{
public:
    Leaderboards()
    {
        FusionFix::onInitEvent() += []()
        {
            auto pattern = hook::pattern("8B 81 ? ? ? ? 83 F8 06");
            static raw_mem fnLeaderboards(pattern.get_first(0), { 0xC3 }); // ret

            FusionFix::onIniFileChange() += []()
            {
                if (FusionFixSettings.GetInt("PREF_DISABLELEADERBOARDS"))
                    fnLeaderboards.Write();
                else
                    fnLeaderboards.Restore();
            };
        };
    }
} Leaderboards;