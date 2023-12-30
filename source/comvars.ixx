module;

#include <common.hxx>

export module comvars;

import common;

export HWND gWnd;
export RECT gRect;
export void* (__fastcall* getNativeAddress)(uintptr_t*, uint32_t, uint32_t);
export uintptr_t* nativeHandlerPtrAddress;
export constexpr auto gLastControllerTextureIndex = 7;

class Common
{
public:
    Common()
    {
        FusionFix::onInitEvent() += []()
        {
            auto pattern = hook::pattern("53 8B 59 04 85 DB");
            if (!pattern.empty())
                getNativeAddress = pattern.get_one().get<void* (__fastcall)(uintptr_t*, uint32_t, uint32_t)>(0);

            pattern = hook::pattern("B9 ? ? ? ? E8 ? ? ? ? 85 C0 75 07");
            nativeHandlerPtrAddress = *pattern.get_first<uintptr_t*>(1);
        };
    }
} Common;
