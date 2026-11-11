#pragma once

#include <Windows.h>
#include <dinput.h>
#include <cstdint>

namespace MouseMotion
{
    inline void UseImmediateState(uintptr_t stack, ptrdiff_t eventsOffset, const DIMOUSESTATE2& state)
    {
        auto& count = *reinterpret_cast<DWORD*>(stack + 4);
        auto events = reinterpret_cast<DIDEVICEOBJECTDATA*>(stack + eventsOffset);
        events[0] = { DIMOFS_X, static_cast<DWORD>(state.lX) };
        events[1] = { DIMOFS_Y, static_cast<DWORD>(state.lY) };
        events[2] = { DIMOFS_Z, static_cast<DWORD>(state.lZ) };
        count = 3;
    }
}
