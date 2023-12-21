module;

#include <common.hxx>
#include "ledsdk/LogitechLEDLib.h"

export module led;

import common;
import settings;
import natives;

bool bLogiLedInitialized = false;

void AmbientLighting()
{
    LogiLedSetTargetDevice(LOGI_DEVICETYPE_ALL);
    LogiLedSetLighting(100, 0, 0);
}

void AmmoInClip()
{
    static std::vector<LogiLed::KeyName> keysLH = {
        LogiLed::KeyName::TILDE, LogiLed::KeyName::ONE, LogiLed::KeyName::TWO, LogiLed::KeyName::THREE,
        LogiLed::KeyName::FOUR,LogiLed::KeyName::FIVE,LogiLed::KeyName::SIX,LogiLed::KeyName::SEVEN,
        LogiLed::KeyName::EIGHT,LogiLed::KeyName::NINE,LogiLed::KeyName::ZERO,LogiLed::KeyName::MINUS,
        LogiLed::KeyName::EQUALS,
    };

    static std::vector<LogiLed::KeyName> keysRH = {
        LogiLed::KeyName::F1, LogiLed::KeyName::F2, LogiLed::KeyName::F3,
        LogiLed::KeyName::F4, LogiLed::KeyName::F5, LogiLed::KeyName::F6,
        LogiLed::KeyName::F7, LogiLed::KeyName::F8, LogiLed::KeyName::F9,
        LogiLed::KeyName::F10, LogiLed::KeyName::F11, LogiLed::KeyName::F12,
        LogiLed::KeyName::PRINT_SCREEN, LogiLed::KeyName::SCROLL_LOCK,
        LogiLed::KeyName::PAUSE_BREAK,
    };

    if (Natives::DoesMainPlayerExist())
    {
        auto pPlayerPed = Natives::GetPlayerPed(Natives::GetPlayerId());
        auto pPlayerWeaponRH = Natives::GetWeaponFromHand(pPlayerPed, 0, 0);
        auto pPlayerWeaponLH = Natives::GetWeaponFromHand(pPlayerPed, 1, 0);

        if (pPlayerWeaponRH)
        {
            static auto oldAmmoInClip = -1;
            auto ammoInClip = Natives::GetWeaponAmmoInClip(pPlayerWeaponRH);
            if (ammoInClip != oldAmmoInClip)
            {
                auto maxAmmoInClip = Natives::GetMaxAmmoInClip(pPlayerPed, Natives::GetWeaponType(pPlayerWeaponRH));
                auto ammoInClipPercent = ((float)ammoInClip / (float)maxAmmoInClip) * 100.0f;

                for (size_t i = 0; i < keysRH.size(); i++)
                {
                    auto indexInPercent = ((float)i / (float)keysRH.size()) * 100.0f;
                    if (ammoInClipPercent > indexInPercent)
                        LogiLedSetLightingForKeyWithKeyName(keysRH[i], 100, 100, 100);
                    else
                        LogiLedSetLightingForKeyWithKeyName(keysRH[i], 25, 25, 25);
                }
            }
            oldAmmoInClip = ammoInClip;
        }
        else
        {
            for (auto k : keysRH)
                LogiLedSetLightingForKeyWithKeyName(k, 25, 25, 25);
        }

        if (pPlayerWeaponLH)
        {
            static auto oldAmmoInClip = -1;
            auto ammoInClip = Natives::GetWeaponAmmoInClip(pPlayerWeaponLH);
            if (ammoInClip != oldAmmoInClip)
            {
                auto maxAmmoInClip = Natives::GetMaxAmmoInClip(pPlayerPed, Natives::GetWeaponType(pPlayerWeaponLH));
                auto ammoInClipPercent = ((float)ammoInClip / (float)maxAmmoInClip) * 100.0f;

                for (size_t i = 0; i < keysLH.size(); i++)
                {
                    auto indexInPercent = ((float)i / (float)keysLH.size()) * 100.0f;
                    if (ammoInClipPercent > indexInPercent)
                        LogiLedSetLightingForKeyWithKeyName(keysLH[i], 100, 100, 100);
                    else
                        LogiLedSetLightingForKeyWithKeyName(keysLH[i], 25, 25, 25);
                }
            }
            oldAmmoInClip = ammoInClip;
        }
        else
        {
            for (auto k : keysLH)
                LogiLedSetLightingForKeyWithKeyName(k, 25, 25, 25);
        }

        {
            static std::vector<LogiLed::KeyName> keys = {
                LogiLed::KeyName::NUM_ONE, LogiLed::KeyName::NUM_TWO, LogiLed::KeyName::NUM_THREE,
                LogiLed::KeyName::NUM_FOUR, LogiLed::KeyName::NUM_FIVE, LogiLed::KeyName::NUM_SIX,
                LogiLed::KeyName::NUM_SEVEN, LogiLed::KeyName::NUM_EIGHT, LogiLed::KeyName::NUM_NINE,
            };

            static auto oldPayneKillersAmt = -1;
            auto payneKillersAmt = Natives::GetPaynekillerAmt();
            if (payneKillersAmt != oldPayneKillersAmt)
            {
                constexpr auto maxPayneKillersAmt = 9;

                for (auto i = 0; i < maxPayneKillersAmt; i++)
                {
                    if (payneKillersAmt > i)
                        LogiLedSetLightingForKeyWithKeyName(keys[i], 100, 100, 100);
                    else
                        LogiLedSetLightingForKeyWithKeyName(keys[i], 25, 25, 25);
                }
            }
            oldPayneKillersAmt = payneKillersAmt;
        }
    }
}

void CurrentHealth(bool bForce = false)
{
    static std::vector<LogiLed::KeyName> keys = {
        LogiLed::KeyName::G_1, LogiLed::KeyName::G_2, LogiLed::KeyName::G_3, LogiLed::KeyName::G_4, LogiLed::KeyName::G_5,
    };

    if (Natives::DoesMainPlayerExist())
    {
        auto pPlayerPed = Natives::GetPlayerPed(Natives::GetPlayerId());

        if (pPlayerPed)
        {
            auto pPlayerHealth = Natives::GetPedHealth(pPlayerPed);
            static auto oldHealth = 0;
            if (pPlayerHealth != oldHealth || bForce)
            {
                auto maxPlayerHealth = Natives::GetPedMaxHealth(pPlayerPed);
                float healthPercent = (((float)pPlayerHealth - 100.0f) / ((float)maxPlayerHealth - 100.0f)) * 100.0f;

                for (size_t i = 0; i < keys.size(); i++)
                {
                    auto indexInPercent = ((float)i / (float)keys.size()) * 100.0f;
                    if (healthPercent < indexInPercent)
                        LogiLedSetLightingForKeyWithKeyName(keys[i], 100, 0, 0);
                    else
                        LogiLedSetLightingForKeyWithKeyName(keys[i], 100, 100, 100);
                }
            }
            oldHealth = pPlayerHealth;
        }
    }
}

void ProcessLEDEvents()
{
    AmmoInClip();
    CurrentHealth();
}

class LED
{
public:
    LED()
    {
        FusionFix::onInitEvent() += []()
        {
            if (FusionFixSettings.GetInt("PREF_LEDILLUMINATION"))
            {
                bLogiLedInitialized = LogiLedInit();
                if (bLogiLedInitialized)
                    AmbientLighting();
            }

            FusionFix::onIniFileChange() += []()
            {
                if (FusionFixSettings.GetInt("PREF_LEDILLUMINATION"))
                {
                    if (!bLogiLedInitialized) {
                        bLogiLedInitialized = LogiLedInit();
                        if (bLogiLedInitialized)
                            AmbientLighting();
                    }
                }
                else if (bLogiLedInitialized) {
                    LogiLedShutdown();
                    bLogiLedInitialized = false;
                }
            };
        };

        FusionFix::onGameProcessEvent() += []()
        {
            if (bLogiLedInitialized)
            {
                ProcessLEDEvents();
            }
        };

        FusionFix::onMenuEnterEvent() += []()
        {
            LogiLedSaveCurrentLighting();
            LogiLedSetTargetDevice(LOGI_DEVICETYPE_ALL);
            AmbientLighting();
        };

        FusionFix::onMenuExitEvent() += []()
        {
            LogiLedRestoreLighting();
            CurrentHealth(true);
        };

        FusionFix::onShutdownEvent() += []()
        {
            if (bLogiLedInitialized) {
                LogiLedShutdown();
                bLogiLedInitialized = false;
            }
        };

        IATHook::Replace(GetModuleHandleA(NULL), "KERNEL32.DLL",
            std::forward_as_tuple("ExitProcess", static_cast<void(__stdcall*)(UINT)>([](UINT uExitCode) {
                if (bLogiLedInitialized) {
                    LogiLedShutdown();
                    bLogiLedInitialized = false;
                }
                ExitProcess(uExitCode);
            }))
        );
    }
} LED;