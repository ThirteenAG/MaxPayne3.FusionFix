module;

#include <common.hxx>
#include <algorithm>
#include "ConsoleSubtitleKerning.hpp"

export module outlines;

import common;
import comvars;
import settings;

namespace
{
    constexpr float ConsoleDialogueY = 613.0f / 720.0f;
    constexpr float ConsoleChapterTitleY = 64.0f / 720.0f;

    constexpr uint8_t ConsoleFontBit = 0x80;
    thread_local bool consoleSubtitle = false;
    thread_local bool renderConsoleSubtitle = false;
    char (__thiscall* GetFontKerning)(void*, uint16_t, uint16_t);
    int (__thiscall* MeasureSubtitle)(void*, float*, float, float, const wchar_t*);
    int (__thiscall* DrawSubtitle)(void*, const float*, const wchar_t*, int, int);
    void (__thiscall* SetFontOutline)(void*, float);

    struct SubtitleLayoutScope
    {
        const bool previous = consoleSubtitle;

        explicit SubtitleLayoutScope(bool subtitle)
        {
            consoleSubtitle = subtitle && FusionFixSettings.GetInt(PREF_CONSOLESUBTITLES) != 0;
        }

        ~SubtitleLayoutScope()
        {
            consoleSubtitle = previous;
        }
    };

    char __fastcall MeasureKerning(void* font, void*, uint16_t first, uint16_t second)
    {
        // The Xbox line breaker sums glyph advances. Kerning is applied when it draws the line.
        return consoleSubtitle ? 0 : GetFontKerning(font, first, second);
    }

    char __fastcall RenderKerning(void* font, void*, uint16_t first, uint16_t second)
    {
        if (renderConsoleSubtitle)
        {
            const auto key = (uint32_t{ first } << 16) | second;
            for (const auto& pair : ConsoleSubtitleKerning::XboxPairs)
            {
                if (pair.key == key)
                    return pair.adjustment;
            }

            const auto& pcOnly = ConsoleSubtitleKerning::PcOnlyPairs;
            if (std::binary_search(std::begin(pcOnly), std::end(pcOnly), key))
                return 0;
        }
        return GetFontKerning(font, first, second);
    }

    void ReadQueuedFont(SafetyHookContext& regs)
    {
        // Each entry copies its font index in the low byte of this register.
        auto& font = regs.xmm0.u8[0];
        renderConsoleSubtitle = (font & ConsoleFontBit) != 0;
        font &= ~ConsoleFontBit;
    }

    int __fastcall MeasureQueuedSubtitle(void* format, void*, float* bounds, float x, float y, const wchar_t* text)
    {
        SubtitleLayoutScope scope(true);
        return MeasureSubtitle(format, bounds, x, y, text);
    }

    int __fastcall DrawQueuedSubtitle(void* format, void*, const float* position, const wchar_t* text, int start, int length)
    {
        SubtitleLayoutScope scope(true);
        return DrawSubtitle(format, position, text, start, length);
    }

    void ScaleSubtitleLayout(float& width, float& height, float* wrap, bool consoleLayout, bool queued)
    {
        if (consoleLayout)
        {
            // The Xbox dialogue renderer hardcodes a separate size from the HUD subtitle entries.
            width = queued ? 0.30f : 0.28f;
            height = queued ? 0.45f : 0.43f;

            // Xbox applies its 4:3-reference aspect correction to queued wrap bounds on wide output.
            const auto viewportWidth = gRect.right - gRect.left;
            const auto viewportHeight = gRect.bottom - gRect.top;
            const auto aspect = viewportHeight > 0 && viewportWidth > 0
                ? static_cast<float>(viewportWidth) / viewportHeight : 16.0f / 9.0f;
            if (aspect >= 1.5f)
            {
                const auto wrapAspect = queued ? 4.0f / 3.0f : 16.0f / 9.0f;
                const auto widthScale = std::min(1.0f, wrapAspect / aspect);
                wrap[0] = 0.5f + (wrap[0] - 0.5f) * widthScale;
                wrap[1] = 0.5f + (wrap[1] - 0.5f) * widthScale;
            }
        }

        const auto scale = FusionFixSettings.GetFloat(PREF_SUBTITLESIZE);
        width *= scale;
        height *= scale;
    }

    bool IsSubtitleHudType(uintptr_t hudElement)
    {
        const auto type = *reinterpret_cast<const int*>(hudElement + 8);
        return type == 6 || type == 7;
    }

    int __fastcall DrawHudSubtitle(void* format, void*, const float* position, const wchar_t* text, int start, int length)
    {
        // This caller passes the inline text field of the HUD element at +0x6C.
        SubtitleLayoutScope scope(IsSubtitleHudType(reinterpret_cast<uintptr_t>(text) - 0x6C));
        return DrawSubtitle(format, position, text, start, length);
    }

    float ScaleOutline(float stockThickness, bool subtitle)
    {
        // The Xbox subtitle calls use 0.7 for dialogue and zero for chapter titles.
        const bool consoleLayout = subtitle && FusionFixSettings.GetInt(PREF_CONSOLESUBTITLES) != 0;
        const auto thickness = consoleLayout ? stockThickness : 1.0f;
        return thickness * FusionFixSettings.GetFloat(PREF_OUTLINESIZE) *
            FusionFixSettings.GetFloat(PREF_SUBTITLESIZE);
    }

    void __fastcall SetSubtitleOutline(void* textFormat, void*, float thickness)
    {
        SetFontOutline(textFormat, ScaleOutline(thickness, true));
    }
}

class Outlines
{
public:
    Outlines()
    {
        FusionFix::onInitEvent() += []()
        {
            auto spacing = hook::pattern("E8 ? ? ? ? 0F BE C0 85 C0 74 ? F3 0F 10 44 24 14 F3 0F 2A C8");
            GetFontKerning = reinterpret_cast<decltype(GetFontKerning)>(
                injector::GetBranchDestination(spacing.get_first()).as_int());
            injector::MakeCALL(spacing.get_first(), MeasureKerning, true);

            spacing = hook::pattern("E8 ? ? ? ? 0F B7 2E 0F BE C0 85 C0 74 ? F3 0F 10 0F");
            injector::MakeCALL(spacing.get_first(), MeasureKerning, true);

            spacing = hook::pattern("88 48 2A 83 05 ? ? ? ? 30 3B FD");
            static auto writeQueuedFont = safetyhook::create_mid(spacing.get_first(3), [](SafetyHookContext& regs)
            {
                // Keep the dialogue font choice with the entry until the renderer drains the queue.
                auto& font = *reinterpret_cast<uint8_t*>(regs.eax + 0x28);
                if (consoleSubtitle && font == 0) // Gotham
                    font |= ConsoleFontBit;
            });

            spacing = hook::pattern("66 0F D6 05 ? ? ? ? F3 0F 10 44 24 38 89 54 24 3C");
            static auto readFirstQueuedFont = safetyhook::create_mid(spacing.get_first(), ReadQueuedFont);

            spacing = hook::pattern("66 0F D6 05 ? ? ? ? 89 54 24 38 F3 0F 10 44 24 38 83 C0 30");
            static auto readNextQueuedFont = safetyhook::create_mid(spacing.get_first(), ReadQueuedFont);

            spacing = hook::pattern("E8 ? ? ? ? 0F B7 3E F3 0F 10 74 24 10 0F BE C0 85 C0");
            injector::MakeCALL(spacing.get_first(), RenderKerning, true);

            spacing = hook::pattern("E8 ? ? ? ? 0F BE C8 0F B7 06 0F B7 E8 85 C9");
            injector::MakeCALL(spacing.get_first(), RenderKerning, true);

            spacing = hook::pattern("E8 ? ? ? ? 0F BE C0 85 C0 74 ? F3 0F 10 4C 24 38 F3 0F 2A C0");
            injector::MakeCALL(spacing.get_first(), RenderKerning, true);

            spacing = hook::pattern("E8 ? ? ? ? F3 0F 10 44 24 40 F3 0F 5C 44 24 48 F3 0F 58 44 24 08 F3 0F 11 44 24 08");
            MeasureSubtitle = reinterpret_cast<decltype(MeasureSubtitle)>(
                injector::GetBranchDestination(spacing.get_first()).as_int());
            injector::MakeCALL(spacing.get_first(), MeasureQueuedSubtitle, true);

            spacing = hook::pattern("E8 ? ? ? ? 83 C6 44 81 FE ? ? ? ? 0F 8C ? ? ? ? E8");
            DrawSubtitle = reinterpret_cast<decltype(DrawSubtitle)>(
                injector::GetBranchDestination(spacing.get_first()).as_int());
            injector::MakeCALL(spacing.get_first(), DrawQueuedSubtitle, true);

            spacing = hook::pattern("83 C6 6C 56 8D 44 24 44 50 B9 ? ? ? ? 88 15 ? ? ? ? E8 ? ? ? ? 5E 5B 8B E5 5D C3");
            injector::MakeCALL(spacing.get_first(20), DrawHudSubtitle, true);

            auto pattern = hook::pattern("E8 ? ? ? ? 68 ? ? ? ? 8D 94 24 ? ? ? ? 6A 02");
            SetFontOutline = reinterpret_cast<decltype(SetFontOutline)>(
                injector::GetBranchDestination(pattern.get_first()).as_int());
            injector::MakeCALL(pattern.get_first(), SetSubtitleOutline, true);

            pattern = hook::pattern("D9 1C 24 E8 ? ? ? ? 68 ? ? ? ? 68");
            injector::MakeCALL(pattern.get_first(3), SetSubtitleOutline, true);

            pattern = hook::pattern("E8 ? ? ? ? 68 ? ? ? ? 8D 44 24 20 6A 03 50 88 1D ? ? ? ? C6 05 ? ? ? ? ? 88 1D ? ? ? ? E8 ? ? ? ? 8B 08");
            injector::MakeCALL(pattern.get_first(), SetSubtitleOutline, true);

            pattern = hook::pattern("E8 ? ? ? ? F3 0F 10 44 24 ? 8D 4C 24 30 F3 0F 11 05 ? ? ? ? F3 0F 10 44 24 ? 51 B9 ? ? ? ? F3 0F 11 05 ? ? ? ? E8 ? ? ? ? 8A 5C 24 0F 80 FB FF 75 0C");
            static auto hudOutline = safetyhook::create_mid(pattern.get_first(), [](SafetyHookContext& regs)
            {
                auto& thickness = *reinterpret_cast<float*>(regs.esp);
                thickness = ScaleOutline(thickness, IsSubtitleHudType(regs.eax));
            });

            pattern = hook::pattern("F3 0F 11 44 24 08 BE ? ? ? ? 33 DB ? 39 5E C4 0F 84");
            static auto queuedSubtitleAnchor = safetyhook::create_mid(pattern.get_first(), [](SafetyHookContext& regs)
            {
                // Set the initial anchor once so the queue still stacks simultaneous captions.
                if (FusionFixSettings.GetInt(PREF_CONSOLESUBTITLES))
                    regs.xmm0.f32[0] = ConsoleDialogueY;
            });

            pattern = hook::pattern("C6 44 24 ? ? F3 0F 11 44 24 ? F3 0F 11 44 24 ? 89 4C 24 54");
            static auto queuedSubtitleLayout = safetyhook::create_mid(pattern.get_first(5), [](SafetyHookContext& regs)
            {
                auto scale = reinterpret_cast<float*>(regs.esp + 0x24);
                auto wrap = reinterpret_cast<float*>(regs.esp + 0x2C);
                const bool consoleLayout = FusionFixSettings.GetInt(PREF_CONSOLESUBTITLES) != 0;
                if (consoleLayout)
                {
                    // Xbox positions queued captions from the top of the text block.
                    *reinterpret_cast<uint8_t*>(regs.esp + 0x77) = 0;
                    if (*reinterpret_cast<const int*>(regs.esi) == 2)
                        *reinterpret_cast<float*>(regs.esp + 0x18) = ConsoleChapterTitleY;
                    wrap[0] = 0.1f;
                    wrap[1] = 0.9f;
                }
                ScaleSubtitleLayout(scale[0], scale[1], wrap, consoleLayout, true);
            });

            pattern = hook::pattern("F3 0F 11 44 24 ? 39 58 30 75 08 F3 0F 10 44 24 ? EB 03 0F 28 C1 8B 40 08");
            static auto hudSubtitleLayout = safetyhook::create_mid(pattern.get_first(), [](SafetyHookContext& regs)
            {
                const bool consoleLayout = IsSubtitleHudType(regs.eax) &&
                    FusionFixSettings.GetInt(PREF_CONSOLESUBTITLES) != 0;
                auto& width = *reinterpret_cast<float*>(regs.esp + 0x30);
                auto wrap = reinterpret_cast<float*>(regs.esp + 0x28);
                // The HUD has already selected its wrap bounds, including the special cases shared with Xbox.
                ScaleSubtitleLayout(width, regs.xmm0.f32[0], wrap, consoleLayout, false);
            });
        };
    }
} Outlines;
