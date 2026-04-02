module;

#include <common.hxx>

export module rawinput;

import common;
import comvars;
import settings;

class RawInput
{
public:
    RawInput()
    {
        FusionFix::onInitEventAsync() += []()
        {
            // Main menu cursor
            auto pattern = hook::pattern("74 ? 8D 44 24 ? 50 FF 15 ? ? ? ? 83 F8");
            injector::MakeNOP(pattern.get_first(), 2, true);
        };
    }
} RawInput;