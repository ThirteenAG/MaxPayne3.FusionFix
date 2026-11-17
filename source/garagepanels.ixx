module;

#include <common.hxx>
#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstring>

export module garagepanels;

import common;

// The garage panel of a chapter 10 cutscene slides across the screen (LockSlide from 0,0,1,1 to -0.3,0,1,1). Its slide
// is drawn from a copy of the composited panel taken early in the slide, the screenshot marker that ends it waits until
// the slide is done, and the area right of the panel is cleared.
namespace GaragePanels
{
    const uint8_t* newPanelFlag = nullptr;
    thread_local bool newPanel = false;
    thread_local bool activeGarageSlide = false;
    thread_local bool maskingGarageSlide = false;
    thread_local bool deferringMarker = false;
    using CopyTexture = void (__cdecl*)(uintptr_t, uintptr_t);
    CopyTexture copyTexture = nullptr;
    using FillRectangle = void (__cdecl*)(const float*, const uint32_t*);
    FillRectangle fillRectangle = nullptr;
    using ReleaseReference = int (__cdecl*)(volatile LONG*);
    ReleaseReference releaseReference = nullptr;
    std::atomic<uintptr_t> slideScratch{ 0 };
    struct Point { float x, y; };
    thread_local uintptr_t pendingAtlas = 0;
    thread_local float pendingOffset = 0.0f;
    thread_local float capturedOffset = 0.0f;
    thread_local uintptr_t originalSource = 0;
    thread_local std::array<Point, 4> slideUv{};
    thread_local std::array<Point, 4> slidePosition{};
    thread_local float firstRetainedRight = 0.0f;
    thread_local uintptr_t capturedScratch = 0;
    // The B6 command has padding between its flags and the next float. Carry the
    // garage slide state in that padding from the producer to the render thread.
    constexpr size_t slideTextureMode = 126;
    enum SlideMode : uint8_t
    {
        Inactive,
        CapturePanel,
        DrawCapturedPanel,
        DrawLivePanel,
        HoldFinalPanel
    };

    void ReadNewPanelFlag(SafetyHookContext&)
    {
        newPanel = *newPanelFlag != 0;
    }

    void CreateSlideScratch(SafetyHookContext& regs)
    {
        using CreateTexture = uintptr_t (__thiscall*)(uintptr_t, const char*, uint32_t, uint32_t, uint32_t, uint32_t, const void*);
        const auto arguments = reinterpret_cast<const uintptr_t*>(regs.esp);
        const auto create = reinterpret_cast<CreateTexture>(regs.edx);
        const auto scratch = create(regs.ecx, "PANEL_GARAGE_SCRATCH", arguments[1], arguments[2],
                                    arguments[3], arguments[4], reinterpret_cast<const void*>(arguments[5]));
        slideScratch.store(scratch, std::memory_order_release);
    }

    void ReleaseSlideScratch(SafetyHookContext&)
    {
        const auto scratch = slideScratch.exchange(0, std::memory_order_acq_rel);
        if (!scratch || releaseReference(reinterpret_cast<volatile LONG*>(scratch + 8)) != 0)
            return;

        using DestroyTexture = void (__thiscall*)(uintptr_t, int);
        const auto vtable = *reinterpret_cast<const DestroyTexture* const*>(scratch);
        vtable[0](scratch, 1);
    }

    uintptr_t ReadTexture(const uint8_t* command, size_t offset)
    {
        uintptr_t texture{};
        std::memcpy(&texture, command + offset, sizeof(texture));
        return texture;
    }

    void BeginSlideCommand(SafetyHookContext& regs)
    {
        pendingAtlas = 0;
        originalSource = 0;
        const auto command = reinterpret_cast<const uint8_t* const*>(regs.esp)[1];
        if (command[slideTextureMode] != DrawCapturedPanel)
            firstRetainedRight = 0.0f;
        if (!command[slideTextureMode])
            capturedScratch = 0;
    }

    void CaptureCompositedSlide(SafetyHookContext& regs)
    {
        if (!pendingAtlas)
            return;
        const auto command = reinterpret_cast<const uint8_t* const*>(regs.esp)[1];
        const auto atlas = pendingAtlas;
        pendingAtlas = 0;
        if (atlas != ReadTexture(command, 28))
            return;

        const auto scratch = slideScratch.load(std::memory_order_acquire);
        if (!scratch || scratch == atlas)
            return;
        copyTexture(scratch, atlas);
        capturedOffset = pendingOffset;
        capturedScratch = scratch;
    }

    void UseSlideSource(SafetyHookContext& regs)
    {
        const auto command = reinterpret_cast<const uint8_t*>(regs.edi);
        if (command[slideTextureMode] != DrawCapturedPanel || !capturedScratch ||
            capturedScratch != slideScratch.load(std::memory_order_acquire))
            return;
        originalSource = regs.ebp;
        regs.ebp = capturedScratch;
    }

    void UseSlideCoordinates(SafetyHookContext& regs)
    {
        const auto command = reinterpret_cast<const uint8_t*>(regs.edi);
        const auto mode = command[slideTextureMode];
        if (mode != CapturePanel && !originalSource)
            return;
        auto points = reinterpret_cast<const Point**>(regs.esp);
        if (mode == CapturePanel)
        {
            // The rendering pass maps source and destination at the same scale.
            pendingOffset = points[4]->x - points[0]->x;
            pendingAtlas = ReadTexture(command, 92);
            return;
        }

        float panelRight{};
        std::memcpy(&panelRight, command + 44, sizeof(panelRight));
        if (firstRetainedRight == 0.0f)
            firstRetainedRight = panelRight;
        constexpr float settledRight = 0.501f;
        const float easingRange = firstRetainedRight - settledRight;
        const float blend = easingRange > 0.0f
            ? std::clamp((firstRetainedRight - panelRight) / easingRange, 0.0f, 1.0f)
            : 1.0f;
        const auto originalRight = points[2]->x;
        const float extension = std::max(0.0f, panelRight - originalRight) * blend;

        for (size_t i = 0; i < slideUv.size(); ++i)
        {
            const auto horizontalShift = i >= 2 ? extension : 0.0f;
            slidePosition[i] = { points[i]->x + horizontalShift, points[i]->y };
            slideUv[i] = { points[4 + i]->x - capturedOffset + horizontalShift, 1.0f - points[i]->y };
            points[i] = &slidePosition[i];
            points[4 + i] = &slideUv[i];
        }
    }

    void RestoreSceneSource(SafetyHookContext& regs)
    {
        if (originalSource)
        {
            regs.ebp = originalSource;
            originalSource = 0;
        }
    }

    void ClearRightOfSlide(SafetyHookContext& regs)
    {
        const auto command = reinterpret_cast<const uint8_t*>(regs.edi);
        if (!command[slideTextureMode] || !command[123])
            return;

        float panelRight{};
        std::memcpy(&panelRight, command + 44, sizeof(panelRight));
        if (panelRight < 0.499f || panelRight >= 1.0f)
            return;

        const auto atlas = ReadTexture(command, 92);
        if (!atlas)
            return;

        using TextureDimension = unsigned (__thiscall*)(uintptr_t);
        const auto vtable = *reinterpret_cast<const TextureDimension* const*>(atlas);
        const auto width = static_cast<float>(vtable[5](atlas));
        const auto height = static_cast<float>(vtable[6](atlas));
        const auto firstUnusedPixel = std::ceil(panelRight * width);
        if (firstUnusedPixel >= width || height <= 0.0f)
            return;

        const std::array<float, 4> rectangle{ firstUnusedPixel, 0.0f, width, height };
        constexpr uint32_t black = 0xff000000;
        fillRectangle(rectangle.data(), &black);
    }

    bool IsGarageSlide(const uint8_t* panel)
    {
        constexpr std::array<float, 8> garageSlide{ 0.0f, 0.0f, 1.0f, 1.0f, -0.3f, 0.0f, 1.0f, 1.0f };
        std::array<float, 8> authored{};
        std::memcpy(authored.data(), panel + 40, sizeof(authored));
        return authored == garageSlide;
    }

    void DeferGarageScreenshot(SafetyHookContext& regs)
    {
        constexpr uintptr_t carryFlag = 1;
        if (regs.eflags & carryFlag)
            return;

        // The controller has already selected the active LockSlide for this frame.
        const auto stack = reinterpret_cast<const uintptr_t*>(regs.esp);
        const int slideIndex = static_cast<int>(stack[0x30 / 4]);
        if (slideIndex < 0 || slideIndex >= 80)
            return;

        const auto panelTable = reinterpret_cast<const uint8_t* const*>(stack[0x1c / 4] + 1080);
        const auto panel = panelTable[slideIndex];
        if (!panel || !IsGarageSlide(panel))
            return;

        // Take the "marker time not reached" branch and re-evaluate on the next update.
        deferringMarker = true;
        regs.eflags |= carryFlag;
    }

    void ReadSlideSample(SafetyHookContext& regs)
    {
        activeGarageSlide = IsGarageSlide(reinterpret_cast<const uint8_t*>(regs.esi));
    }

    void SetPreserveFlag(SafetyHookContext& regs)
    {
        const bool startingPanel = newPanel;
        newPanel = false;
        auto* command = reinterpret_cast<uint8_t*>(regs.eax);
        const bool activeSlide = activeGarageSlide;
        const bool markerDeferred = deferringMarker;
        activeGarageSlide = false;
        deferringMarker = false;
        if (command)
            command[slideTextureMode] = Inactive;
        if (!command || !command[123])
            return;

        // Xbox omits the outgoing rectangle on the first frame of a new panel.
        // PC command B6 uses this byte to suppress the same rectangle clear.
        if (startingPanel)
            command[125] = 1;

        std::array<float, 4> viewport{};
        const size_t offsets[] = { 48, 36, 44, 40 };
        for (size_t i = 0; i < viewport.size(); ++i)
            std::memcpy(&viewport[i], command + offsets[i], sizeof(float));

        if (activeSlide && !startingPanel && command[118] && !command[119]
            && viewport[0] == 0.0f && viewport[1] == 0.0f && std::abs(viewport[3] - 0.585f) < 0.001f)
        {
            float cropX{};
            std::memcpy(&cropX, command + 28, sizeof(cropX));
            // Capture in the earlier part of the slide while its scanlines are present.
            command[slideTextureMode] = markerDeferred ? DrawCapturedPanel
                : (cropX >= 0.08f && cropX <= 0.18f ? CapturePanel : DrawLivePanel);
        }
        const bool holdingHalfPanel = maskingGarageSlide && !startingPanel
            && viewport[0] == 0.0f && viewport[1] == 0.0f
            && std::abs(viewport[2] - 0.5f) < 0.001f && std::abs(viewport[3] - 0.585f) < 0.001f;
        if (!command[slideTextureMode] && holdingHalfPanel)
            command[slideTextureMode] = HoldFinalPanel;
        maskingGarageSlide = command[slideTextureMode] != 0;
    }

    export void Init()
    {
        // A new panel starts this frame
        auto pattern = hook::pattern("38 1D ? ? ? ? 74 0D C6 05 ? ? ? ? 01 88 1D");
        newPanelFlag = *pattern.get_first<const uint8_t*>(2);
        static auto ReadFlag = safetyhook::create_mid(pattern.get_first(), ReadNewPanelFlag);

        // The panel's B6 command is submitted
        pattern = hook::pattern("C6 40 03 B6 C7 05 ? ? ? ? 6E 00 00 00 8B 08 81 E1 FF DF 0D FF");
        static auto Preserve = safetyhook::create_mid(pattern.get_first(), SetPreserveFlag);

        // LockSlide samples its panel towards and from the target
        pattern = hook::pattern("E8 ? ? ? ? 83 C4 1C 5F 5E 59 C2 18 00 80 BE");
        static auto SlideTo = safetyhook::create_mid(pattern.get_first(), ReadSlideSample);
        pattern = hook::pattern("E8 ? ? ? ? 83 C4 1C 5F 5E 59 C2 18 00 F3 0F 11 AF");
        static auto SlideFrom = safetyhook::create_mid(pattern.get_first(), ReadSlideSample);

        // The screenshot marker checks of the previous and the current panel
        pattern = hook::pattern("72 1A 8A D1 FE CA C6 05 ? ? ? ? 01 C6 05 ? ? ? ? 00 88 97 10 06 00 00");
        static auto PreviousMarker = safetyhook::create_mid(pattern.get_first(), DeferGarageScreenshot);
        pattern = hook::pattern("72 14 C6 05 ? ? ? ? 01 C6 05 ? ? ? ? 00 88 8F 10 06 00 00");
        static auto CurrentMarker = safetyhook::create_mid(pattern.get_first(), DeferGarageScreenshot);

        // Render thread: the texture copy of command B5, commands B6 and B7, and the panel quad
        pattern = hook::pattern("E8 ? ? ? ? 83 C4 08 5E C3 CC CC CC CC CC CC CC CC CC CC CC CC CC CC 8B 0D");
        copyTexture = reinterpret_cast<CopyTexture>(injector::GetBranchDestination(pattern.get_first()).as_int());
        pattern = hook::pattern("8B 4C 24 04 E9 57 E0 FF FF CC CC CC CC CC CC CC");
        static auto Begin = safetyhook::create_mid(pattern.get_first(), BeginSlideCommand);
        pattern = hook::pattern("8B 4C 24 04 E9 77 F4 FF FF CC CC CC CC CC CC CC");
        static auto Capture = safetyhook::create_mid(pattern.get_first(), CaptureCompositedSlide);
        pattern = hook::pattern("F3 0F 10 77 38 F3 0F 10 3D ? ? ? ? F3 0F 10 6F 34");
        static auto Reuse = safetyhook::create_mid(pattern.get_first(), UseSlideSource);
        pattern = hook::pattern("E8 ? ? ? ? 83 C4 24 8D 4C 24 28 E8 ? ? ? ? 8D 44 24 74");
        static auto Quad = safetyhook::create_mid(pattern.get_first(), UseSlideCoordinates);
        static auto Restore = safetyhook::create_mid(pattern.get_first(5), RestoreSceneSource);

        pattern = hook::pattern("E8 ? ? ? ? 83 C4 08 F3 0F 10 05 ? ? ? ? 68");
        fillRectangle = reinterpret_cast<FillRectangle>(injector::GetBranchDestination(pattern.get_first()).as_int());
        static auto Clear = safetyhook::create_mid(pattern.get_first(8), ClearRightOfSlide);

        // A scratch texture of the panel texture's size is created and released along with it
        pattern = hook::pattern("56 8B 35 ? ? ? ? 57 85 F6 74 28 8D 46 08 50 E8 ? ? ? ? 83 C4 04");
        releaseReference = reinterpret_cast<ReleaseReference>(injector::GetBranchDestination(pattern.get_first(16)).as_int());
        static auto Release = safetyhook::create_mid(pattern.get_first(), ReleaseSlideScratch);
        pattern = hook::pattern("68 ? ? ? ? FF D2 8B 0D ? ? ? ? A3 ? ? ? ? 8B 01 8B 90 20 01 00 00");
        static auto Allocate = safetyhook::create_mid(pattern.get_first(5), CreateSlideScratch);
    }
}
