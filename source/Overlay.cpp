#include <common.hxx>
#include <Commctrl.h>
#define DIRECTINPUT_VERSION 0x0800
#include <dinput.h>
#include <Xinput.h>
#include "OverlayInput.hpp"
#include <overlay/OverlayD3D11.hpp>

import common;
import settings;

// The native Fusion Fix menu remains the game's menu. This independent adapter
// owns the hotkey alternative and blocks the game's input at its API boundaries.
namespace MP3Overlay
{
    namespace
    {
        asi_overlay::D3D11Overlay overlay;
        HMODULE host = nullptr;
        HWND attachedWindow = nullptr;
        const unsigned int* gameLanguage = nullptr;
        constexpr const char* languages[] = { "en", "fr", "de", "it", "es", "ja", "ru", "pt-BR", "pl", "ko" };
        constexpr UINT_PTR subclassId = 0x46464F56;
        std::recursive_mutex inputMutex;
        // Device implementations can share methods. Hook each implementation
        // once and retain its trampoline; never alter or retain a COM object's vtable.
        std::map<void*, SafetyHookInline> createDeviceHooks, stateHooks, dataHooks;
        std::set<void*> mice;
        bool bufferedMouse = false;
        using CreateDI = HRESULT(WINAPI*)(HINSTANCE, DWORD, REFIID, LPVOID*, LPUNKNOWN);
        CreateDI createDI = nullptr;
        using GetPad = DWORD(WINAPI*)(DWORD, XINPUT_STATE*);
        std::atomic<GetPad> getPad = nullptr;
        std::atomic<DWORD> activePad = 0;
        void FeedPad(const XINPUT_GAMEPAD& pad);
        decltype(&GetProcAddress) resolveProc = GetProcAddress;
        decltype(&GetKeyboardState) keyboardState = GetKeyboardState;
        decltype(&GetKeyState) keyState = GetKeyState;
        decltype(&GetAsyncKeyState) asyncKeyState = GetAsyncKeyState;
        decltype(&SetCursorPos) cursorPosition = SetCursorPos;
        decltype(&ClipCursor) cursorClip = ClipCursor;

        void* Method(void* object, size_t slot) { return (*static_cast<void***>(object))[slot]; }

        HRESULT WINAPI DeviceState(IDirectInputDevice8W* device, DWORD size, void* data)
        {
            std::lock_guard lock(inputMutex);
            auto& hook = stateHooks.at(Method(device, 9));
            auto result = hook.stdcall<HRESULT>(device, size, data);
            // The game reads the mouse exclusively: window messages carry no clicks, so feed the overlay here.
            if (SUCCEEDED(result) && data && overlay.IsOpen() && (size == sizeof(DIMOUSESTATE) || size == sizeof(DIMOUSESTATE2)))
            {
                auto mouse = static_cast<const DIMOUSESTATE*>(data);
                for (int i = 0; i < 3; ++i) overlay.MouseButton(i, (mouse->rgbButtons[i] & 0x80) != 0);
                if (!bufferedMouse) overlay.MouseWheel(float(mouse->lZ) / WHEEL_DELTA);
            }
            if (SUCCEEDED(result) && data && BlocksInput() && (size == 256 || size == sizeof(DIMOUSESTATE) || size == sizeof(DIMOUSESTATE2))) memset(data, 0, size);
            return result;
        }

        HRESULT WINAPI DeviceData(IDirectInputDevice8W* device, DWORD size, DIDEVICEOBJECTDATA* data, DWORD* count, DWORD flags)
        {
            std::lock_guard lock(inputMutex);
            if (BlocksInput()) flags &= ~DIGDD_PEEK;
            auto result = dataHooks.at(Method(device, 10)).stdcall<HRESULT>(device, size, data, count, flags);
            if (SUCCEEDED(result) && data && count && overlay.IsOpen() && mice.contains(device))
            {
                bufferedMouse = true;
                for (DWORD i = 0; i < *count; ++i)
                {
                    auto& event = *reinterpret_cast<const DIDEVICEOBJECTDATA*>(reinterpret_cast<const char*>(data) + i * size);
                    if (event.dwOfs >= DIMOFS_BUTTON0 && event.dwOfs <= DIMOFS_BUTTON2) overlay.MouseButton(int(event.dwOfs - DIMOFS_BUTTON0), (event.dwData & 0x80) != 0);
                    else if (event.dwOfs == DIMOFS_Z) overlay.MouseWheel(float(LONG(event.dwData)) / WHEEL_DELTA);
                }
            }
            // Drain the original queue while open, so closing cannot replay clicks.
            if (SUCCEEDED(result) && count && BlocksInput()) *count = 0;
            return result;
        }

        HRESULT WINAPI CreateDevice(IDirectInput8W* input, REFGUID guid, IDirectInputDevice8W** device, IUnknown* outer)
        {
            std::lock_guard lock(inputMutex);
            // REFGUID must stay a pointer: the variadic trampoline call copies arguments by value.
            auto result = createDeviceHooks.at(Method(input, 3)).stdcall<HRESULT>(input, &guid, device, outer);
            if (SUCCEEDED(result) && device && *device)
            {
                // XInput handles pads. Keyboard and relative mouse packets have a
                // zero neutral state, unlike absolute DirectInput joystick axes.
                if (guid == GUID_SysKeyboard || guid == GUID_SysMouse)
                {
                    if (guid == GUID_SysMouse) mice.insert(*device);
                    auto state = Method(*device, 9), data = Method(*device, 10);
                    if (!stateHooks.contains(state)) stateHooks.emplace(state, safetyhook::create_inline(state, DeviceState));
                    if (!dataHooks.contains(data)) dataHooks.emplace(data, safetyhook::create_inline(data, DeviceData));
                }
            }
            return result;
        }

        HRESULT WINAPI DirectInputCreate(HINSTANCE instance, DWORD version, REFIID iid, void** input, IUnknown* outer)
        {
            auto result = createDI(instance, version, iid, input, outer);
            if (SUCCEEDED(result) && input && *input)
            {
                std::lock_guard lock(inputMutex);
                auto method = Method(*input, 3);
                if (!createDeviceHooks.contains(method)) createDeviceHooks.emplace(method, safetyhook::create_inline(method, CreateDevice));
            }
            return result;
        }

        DWORD WINAPI PadState(DWORD index, XINPUT_STATE* state)
        {
            auto original = getPad.load();
            auto result = original ? original(index, state) : ERROR_DEVICE_NOT_CONNECTED;
            if (result == ERROR_SUCCESS && state && index == activePad) FeedPad(state->Gamepad);
            if (result == ERROR_SUCCESS && state && BlocksInput()) state->Gamepad = {};
            return result;
        }

        FARPROC WINAPI ResolveProc(HMODULE module, LPCSTR name)
        {
            auto proc = resolveProc(module, name);
            if (reinterpret_cast<uintptr_t>(name) > 0xFFFF && strcmp(name, "XInputGetState") == 0 && proc)
            {
                getPad = reinterpret_cast<GetPad>(proc);
                return reinterpret_cast<FARPROC>(PadState);
            }
            return proc;
        }

        BOOL WINAPI KeyboardState(PBYTE keys)
        {
            auto result = keyboardState(keys);
            if (result && BlocksInput()) memset(keys, 0, 256);
            return result;
        }
        SHORT WINAPI KeyState(int key) { return BlocksInput() ? 0 : keyState(key); }
        SHORT WINAPI AsyncKeyState(int key) { return BlocksInput() ? 0 : asyncKeyState(key); }
        BOOL WINAPI CursorPosition(int x, int y) { return BlocksInput() ? TRUE : cursorPosition(x, y); }
        // The game clips to its whole window; Fusion Fix keeps the cursor in the client area itself (MAIN.ConfineCursor)
        BOOL WINAPI CursorClip(const RECT* rect) { return BlocksInput() || rect ? TRUE : cursorClip(rect); }

        LRESULT CALLBACK WindowProc(HWND hwnd, UINT message, WPARAM wp, LPARAM lp, UINT_PTR, DWORD_PTR)
        {
            LRESULT result = 0;
            if (overlay.Message(hwnd, message, wp, lp, result)) return result;
            if (message == WM_NCDESTROY)
            {
                overlay.SetOpen(false);
                RemoveWindowSubclass(hwnd, WindowProc, subclassId);
                attachedWindow = nullptr;
            }
            return DefSubclassProc(hwnd, message, wp, lp);
        }

        void FeedPad(const XINPUT_GAMEPAD& pad)
        {
            auto b = pad.wButtons;
            uint16_t mapped = 0;
            const WORD from[] = { XINPUT_GAMEPAD_BACK, XINPUT_GAMEPAD_START, XINPUT_GAMEPAD_DPAD_UP, XINPUT_GAMEPAD_DPAD_RIGHT,
                XINPUT_GAMEPAD_DPAD_DOWN, XINPUT_GAMEPAD_DPAD_LEFT, XINPUT_GAMEPAD_LEFT_SHOULDER, XINPUT_GAMEPAD_RIGHT_SHOULDER,
                XINPUT_GAMEPAD_Y, XINPUT_GAMEPAD_B, XINPUT_GAMEPAD_A, XINPUT_GAMEPAD_X };
            const uint16_t to[] = { 1, 8, 0x10, 0x20, 0x40, 0x80, 0x400, 0x800, 0x1000, 0x2000, 0x4000, 0x8000 };
            for (size_t i = 0; i < std::size(from); ++i) if (b & from[i]) mapped |= to[i];
            overlay.Gamepad(mapped, int8_t(pad.sThumbLX / 256), int8_t(-int(pad.sThumbLY) / 258));
        }

        void PollPad()
        {
            auto original = getPad.load();
            if (!original)
            {
                if (auto module = GetModuleHandleW(L"xinput1_3.dll"))
                    getPad = original = reinterpret_cast<GetPad>(GetProcAddress(module, "XInputGetState"));
            }
            XINPUT_STATE state{};
            if (original) for (DWORD i = 0; i < 4; ++i) if (original(i, &state) == ERROR_SUCCESS) { activePad = i; break; }
            FeedPad(state.Gamepad);
        }
    }

    bool BlocksInput() { return overlay.BlocksInput(); }

    void AttachWindow(HWND window)
    {
        if (window && attachedWindow != window && SetWindowSubclass(window, WindowProc, subclassId, 0)) attachedWindow = window;
    }

    void Present(IDXGISwapChain* swapchain)
    {
        if (!swapchain) return;
        overlay.hotkey = SettingsPlugin().Int("MAIN.OverlayHotkey");
        overlay.fallbackLanguage = languages[gameLanguage && *gameLanguage < std::size(languages) ? *gameLanguage : 0];
        // D3D10 swapchains are intentionally unsupported. Release any previous
        // DX11 context when switching away so its input cannot remain captured.
        ID3D11Device* device = nullptr;
        if (FAILED(swapchain->GetDevice(__uuidof(ID3D11Device), reinterpret_cast<void**>(&device)))) { overlay.ShutdownRenderer(); return; }
        device->Release();
        PollPad();
        overlay.Present(swapchain, host);
    }

    void Shutdown()
    {
        overlay.ShutdownRenderer();
        if (attachedWindow) RemoveWindowSubclass(attachedWindow, WindowProc, subclassId);
    }

    class Adapter
    {
    public:
        Adapter()
        {
            FusionFix::onInitEvent() += []
            {
                GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                    reinterpret_cast<LPCWSTR>(&Present), &host);
                gameLanguage = *hook::get_pattern<const unsigned int*>("A1 ? ? ? ? 83 F8 09 77 43 FF 24 85 ? ? ? ? B8 ? ? ? ? C3 B8", 1);
                auto originals = IATHook::Replace(GetModuleHandleW(nullptr), "DINPUT8.DLL", std::forward_as_tuple("DirectInput8Create", DirectInputCreate));
                if (originals.contains("DirectInput8Create")) createDI = reinterpret_cast<CreateDI>(originals.at("DirectInput8Create").get());
                // Input devices may predate the callback that initializes the fix.
                // Probe the system implementations as well as intercepting future
                // game devices. No acquisition or cooperative-mode changes needed.
                if (createDI)
                {
                    IDirectInput8W* probe = nullptr;
                    if (SUCCEEDED(DirectInputCreate(GetModuleHandleW(nullptr), DIRECTINPUT_VERSION, IID_IDirectInput8W,
                        reinterpret_cast<void**>(&probe), nullptr)))
                    {
                        for (const auto& guid : { GUID_SysKeyboard, GUID_SysMouse })
                        {
                            IDirectInputDevice8W* device = nullptr;
                            if (SUCCEEDED(probe->CreateDevice(guid, &device, nullptr))) device->Release();
                        }
                        probe->Release();
                    }
                }
                auto kernel = IATHook::Replace(GetModuleHandleW(nullptr), "KERNEL32.DLL", std::forward_as_tuple("GetProcAddress", ResolveProc));
                if (kernel.contains("GetProcAddress")) resolveProc = reinterpret_cast<decltype(resolveProc)>(kernel.at("GetProcAddress").get());
                auto user = IATHook::Replace(GetModuleHandleW(nullptr), "USER32.DLL",
                    std::forward_as_tuple("GetKeyboardState", KeyboardState), std::forward_as_tuple("GetKeyState", KeyState),
                    std::forward_as_tuple("GetAsyncKeyState", AsyncKeyState), std::forward_as_tuple("SetCursorPos", CursorPosition),
                    std::forward_as_tuple("ClipCursor", CursorClip));
                auto retain = [&](const char* name, auto& original)
                {
                    if (user.contains(name)) original = reinterpret_cast<std::remove_reference_t<decltype(original)>>(user.at(name).get());
                };
                retain("GetKeyboardState", keyboardState); retain("GetKeyState", keyState);
                retain("GetAsyncKeyState", asyncKeyState); retain("SetCursorPos", cursorPosition); retain("ClipCursor", cursorClip);
            };
        }
    } adapter;
}
