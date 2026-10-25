#pragma once
#include <Windows.h>
struct IDXGISwapChain;
namespace MP3Overlay
{
    void AttachWindow(HWND window);
    void Present(IDXGISwapChain* swapchain);
    bool BlocksInput();
    void Shutdown();
}
