module;

#include <common.hxx>
#include <fstream>
#include <TextureMipList.hpp>

export module texturemips;

import common;

namespace TextureMips
{
    NameList list;
    const int* textureQuality = nullptr;
    std::array<SafetyHookMid, 3> uploadHooks;

    void SelectMip(SafetyHookContext& regs)
    {
        // The three upload paths keep grcTexturePC in ESI and the native skip
        // count in EAX. The resource constructor has already relocated its name.
        const auto texture = reinterpret_cast<const uint8_t*>(regs.esi);
        const auto name = *reinterpret_cast<const char* const*>(texture + 24);
        if (!name || !list.Contains(name)) return;
        const bool skip = CanSkip(*textureQuality, regs.eax, texture[44] & 0x1f, texture[45],
            *reinterpret_cast<const uint16_t*>(texture + 32),
            *reinterpret_cast<const uint16_t*>(texture + 34),
            *reinterpret_cast<const uint16_t*>(texture + 38));
        if (skip) regs.eax = 1;
        // Let the game advance the pixel pointer and reduce dimensions, pitch
        // and mip count together. It also records the skip for recreation.
    }

    void Init()
    {
        const auto directory = GetThisModulePath();
        std::ifstream input(directory / L"MaxPayne3.FusionFix.TextureMipSkip.txt");
        list.Read(input);
        if (list.Empty()) return;

        auto quality = hook::pattern("83 EC 18 B8 02 00 00 00 2B 05 ? ? ? ? 89 44 24 0C 75 06 33 C0 83 C4 18 C3");
        auto uploads = hook::pattern("E8 ? ? ? ? 83 C4 18 33 D2 89 44 24 ? 88 46 2E 84 C0 76");
        auto entries = hook::pattern("83 EC ? 53 55 56 8B F1 8A 46 2C 8A C8 80 E1 1F");
        if (quality.size() != 1 || uploads.size() != uploadHooks.size() || entries.size() != 3)
        {
            return;
        }
        for (size_t i = 0; i < uploadHooks.size(); ++i)
        {
            const auto call = uploads.get(i).get<uint8_t>();
            const auto entry = entries.get(i).get<uint8_t>();
            if (injector::GetBranchDestination(call).as_int() != reinterpret_cast<uintptr_t>(quality.get_first())
                || call != entry + (i == 0 ? 0x5a : 0x50))
            {
                return;
            }
        }
        textureQuality = *quality.get_first<const int*>(10);
        for (size_t i = 0; i < uploadHooks.size(); ++i)
        {
            uploadHooks[i] = safetyhook::create_mid(uploads.get(i).get<void>(5), SelectMip);
            if (!uploadHooks[i])
            {
                for (auto& installed : uploadHooks) installed.reset();
                return;
            }
        }
    }
}

class TextureMipSkip
{
public:
    TextureMipSkip()
    {
        FusionFix::onInitEventAsync() += TextureMips::Init;
    }
} TextureMipSkip;
