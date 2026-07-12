module;

#include <common.hxx>

export module fixes;
import common;

class Fixes
{
public:
    Fixes()
    {
        FusionFix::onInitEventAsync() += []()
            {
                auto pattern = hook::pattern("F3 0F 59 CC F3 0F 59 C4 F3 0F 59 DC");

                // for the renderer command 0xB6 both v22 and console sample around the center
                // whereas v28 and above on PC calculate the sampling center from the coords which breaks panels
                injector::MakeNOP(pattern.get_first(), 8, true);
                static auto FixCutscenePanels = safetyhook::create_mid(pattern.get_first(), [](SafetyHookContext& regs)
                    {
                        regs.xmm1 = regs.xmm4;
                        regs.xmm0 = regs.xmm4;
                    });
            };
    }
} Fixes;