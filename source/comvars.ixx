module;

#include <common.hxx>

export module comvars;

import common;

export HWND gWnd;
export RECT gRect;

class Common
{
public:
    Common()
    {
        FusionFix::onInitEvent() += []()
        {

        };
    }
} Common;