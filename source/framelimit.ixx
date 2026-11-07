module;

#include <common.hxx>
#include <atomic>
#include <thread>

export module framelimit;

import common;
import comvars;
import settings;
import natives;

// Frame rate limit (MAIN.FPSLimit): 0 = unlimited, -1 = the refresh rate of the display the game is on, else 30 to 1000
// frames per second. The wait comes right before the render thread presents the frame, which keeps the presents evenly
// spaced; waiting in the main loop instead leaves them to the render thread's varying work. Each frame gets its time
// slot after the one before, so the pace doesn't drift; a late frame starts the count anew instead of rushing the next
// ones. While the game loads behind a faded out screen or a transition movie it runs unlimited like the original game,
// which loads in steps of its frames.
namespace
{
    std::atomic<bool> Loading{};

    LONGLONG Frequency()
    {
        static const LONGLONG frequency = []
        {
            LARGE_INTEGER value{};
            QueryPerformanceFrequency(&value);
            return value.QuadPart;
        }();
        return frequency;
    }

    LONGLONG Now()
    {
        LARGE_INTEGER now{};
        QueryPerformanceCounter(&now);
        return now.QuadPart;
    }

    uint32_t RefreshRate()
    {
        MONITORINFOEXW monitor{};
        monitor.cbSize = sizeof(monitor);
        DEVMODEW mode{};
        mode.dmSize = sizeof(mode);
        if (GetMonitorInfoW(MonitorFromWindow(gWnd, MONITOR_DEFAULTTOPRIMARY), &monitor) &&
            EnumDisplaySettingsW(monitor.szDevice, ENUM_CURRENT_SETTINGS, &mode) && mode.dmDisplayFrequency >= 30)
            return mode.dmDisplayFrequency;
        return 60;
    }

    // Sleeps on a high resolution timer until shortly before the target, then spins the rest
    void WaitUntil(LONGLONG target)
    {
        static const HANDLE timer = CreateWaitableTimerExW(nullptr, nullptr, CREATE_WAITABLE_TIMER_HIGH_RESOLUTION, TIMER_ALL_ACCESS);
        constexpr double SpinTime = 0.0015;
        const double seconds = double(target - Now()) / double(Frequency());
        if (seconds > SpinTime)
        {
            LARGE_INTEGER due{};
            due.QuadPart = -static_cast<LONGLONG>((seconds - SpinTime) * 10000000.0);
            if (timer && SetWaitableTimer(timer, &due, 0, nullptr, nullptr, FALSE))
                WaitForSingleObject(timer, INFINITE);
            else
                Sleep(static_cast<DWORD>((seconds - SpinTime) * 1000.0));
        }
        while (Now() < target)
            YieldProcessor();
    }

}

export namespace FrameLimit
{
    // Called once a frame on the render thread, before the frame is presented (all renderers)
    void BeforePresent()
    {
        static LONGLONG next = 0;
        const int32_t limit = FusionFixSettings.GetInt(PREF_FPSLIMIT);
        if (limit == 0 || Loading)
        {
            next = 0;
            return;
        }

        // The refresh rate is looked up again now and then beside the game (it takes long enough to stall a frame): the
        // window can move to another display
        static std::atomic<uint32_t> refreshRate{ 0 };
        static std::atomic<bool> reading{};
        static ULONGLONG refreshRateTime = 0;
        if (limit < 0 && (!refreshRate || GetTickCount64() - refreshRateTime > 2000) && !reading.exchange(true))
        {
            refreshRateTime = GetTickCount64();
            std::thread([] { refreshRate = RefreshRate(); reading = false; }).detach();
        }

        const int32_t fps = limit < 0 ? int32_t(refreshRate ? refreshRate.load() : 60) : std::clamp(limit, 30, 1000);
        const LONGLONG period = Frequency() / fps;
        const LONGLONG now = Now();
        if (next == 0 || now > next + period)
        {
            next = now + period;
            return;
        }
        WaitUntil(next);
        next += period;
    }
}

class FrameLimitInit
{
public:
    FrameLimitInit()
    {
        static auto update = [] { Loading = Natives::IsScreenFadedOut() || Natives::IsTransitionMoviePlaying(); };
        FusionFix::onGameProcessEvent() += update;
        FusionFix::onMenuDrawingEvent() += update;
    }
} FrameLimitInit;
