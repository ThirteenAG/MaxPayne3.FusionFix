#pragma once
#include <Windows.h>
struct IDXGISwapChain;
// In-game settings overlay (source/Overlay.cpp), Debug builds only
namespace MP3Overlay
{
#ifdef ASI_OVERLAY
    void AttachWindow(HWND window);
    void Present(IDXGISwapChain* swapchain);
    bool BlocksInput();
    void Shutdown();
#else
    inline void AttachWindow(HWND) {}
    inline void Present(IDXGISwapChain*) {}
    constexpr bool BlocksInput() { return false; }
    inline void Shutdown() {}
#endif
}
