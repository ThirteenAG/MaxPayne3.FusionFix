module;

#include <common.hxx>

export module devicechange;

import common;
import settings;

class DeviceChange
{
public:
    DeviceChange()
    {
        FusionFix::onInitEvent() += []()
        {
            // Disable WM_DEVICECHANGE message handler, since it happens randomly for some reason
            auto pattern = hook::pattern("74 63 83 E8 18 0F 85 ? ? ? ? E8 ? ? ? ? 84 C0");
            static raw_mem pDeviceChangeCheck(pattern.get_first(0), { 0x90, 0x90 }); // nop
            
            static auto DeviceChangeCB = []()
            {
                if (FusionFixSettings.GetInt("PREF_DEVICECHANGE"))
                    pDeviceChangeCheck.Write();
                else
                    pDeviceChangeCheck.Restore();
            };
            
            DeviceChangeCB();
            
            FusionFix::onIniFileChange() += []()
            {
                DeviceChangeCB();
            };
        };
    }
} DeviceChange;