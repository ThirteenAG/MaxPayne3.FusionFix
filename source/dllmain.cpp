#include <misc.h>

float fOutlinesSizeMultiplier;
float* dword_1FCA9A8;
void __fastcall sub_010AFD30(float* _this, void* edx, float a2)
{
    a2 *= fOutlinesSizeMultiplier;

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

void Init()
{
    CIniReader iniReader("");
    bool bHideSkipButton = iniReader.ReadInteger("MAIN", "HideSkipButton", 1) != 0;
    fOutlinesSizeMultiplier = iniReader.ReadFloat("MAIN", "OutlinesSizeMultiplier", 0.0f);

    if (bHideSkipButton)
    {
        auto pattern = hook::pattern("8B C8 89 86 ? ? ? ? E8 ? ? ? ? D9 EE 8B 86 ? ? ? ? 8B 38 83 EC 08 D9 54 24 04 8D 4C 24 3C D9 1C 24 E8 ? ? ? ? F3 0F 7E 00 8B 97 ? ? ? ? 83 EC 18 8B CC 66 0F D6 01 F3 0F 7E 40 ? 66 0F D6 41 ? F3 0F 7E 40 ? 6A 18 68");
        injector::MakeNOP(pattern.get_first(8), 5, true);
        pattern = hook::pattern("8B C8 89 86 ? ? ? ? E8 ? ? ? ? D9 EE 8B 86 ? ? ? ? 8B 38 83 EC 08 D9 54 24 04 8D 4C 24 20 D9 1C 24 E8 ? ? ? ? F3 0F 7E 00 8B 97 ? ? ? ? 83 EC 18 8B CC 66 0F D6 01 F3 0F 7E 40 ? 66 0F D6 41 ? F3 0F 7E 40 ? 6A 18 68 ? ? ? ? 66 0F D6 41 ? 8B 8E ? ? ? ? 6A 18");
        injector::MakeNOP(pattern.get_first(8), 5, true);
    }

    if (fOutlinesSizeMultiplier)
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
    }
}

CEXP void InitializeASI()
{
    std::call_once(CallbackHandler::flag, []()
    {
        CallbackHandler::RegisterCallback(Init, hook::pattern("C6 44 24 ? ? F3 0F 11 44 24 ? F3 0F 11 44 24 ? 89 4C 24 54"));
    });
}

BOOL APIENTRY DllMain(HMODULE hModule, DWORD reason, LPVOID lpReserved)
{
    if (reason == DLL_PROCESS_ATTACH)
    {
        if (!IsUALPresent()) { InitializeASI(); }
    }
    return TRUE;
}