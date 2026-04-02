module;

#include <common.hxx>

export module comvars;

import common;

export HWND gWnd;
export RECT gRect;
export void* (__fastcall* getNativeAddress)(uintptr_t*, uint32_t, uint32_t);
export uintptr_t* nativeHandlerPtrAddress;
export constexpr auto gLastControllerTextureIndex = 7;

export enum eControllerButtons
{
    BUTTON_BUMPER_LEFT = 4,
    BUTTON_TRIGGER_LEFT = 5,
    BUTTON_BUMPER_RIGHT = 6,
    BUTTON_TRIGGER_RIGHT = 7,
    BUTTON_DPAD_UP = 8,
    BUTTON_DPAD_DOWN = 9,
    BUTTON_DPAD_LEFT = 10,
    BUTTON_DPAD_RIGHT = 11,
    BUTTON_START = 12,
    BUTTON_BACK = 13,
    BUTTON_X = 14,
    BUTTON_Y = 15,
    BUTTON_A = 16,
    BUTTON_B = 17,
    BUTTON_STICK_LEFT = 18,
    BUTTON_STICK_RIGHT = 19,
};

export std::optional<float> ParseWidescreenHudOffset(std::string_view input)
{
    if (input.empty())
        return std::nullopt;

    std::string str(input);

    // Trim whitespace
    str.erase(0, str.find_first_not_of(" \t\r\n"));
    str.erase(str.find_last_not_of(" \t\r\n") + 1);

    if (str.empty())
        return std::nullopt;

    // Case-insensitive "Auto" check
    std::string lower = str;
    std::transform(lower.begin(), lower.end(), lower.begin(), ::tolower);
    if (lower == "auto")
        return std::nullopt;

    // Try direct float conversion
    {
        char* end = nullptr;
        float value = std::strtof(str.c_str(), &end);
        if (end != str.c_str() && *end == '\0')
            return value;
    }

    // Try "1280x720" format
    {
        int width = 0, height = 0;
        if (sscanf_s(str.c_str(), "%dx%d", &width, &height) == 2 && width > 0)
            return static_cast<float>(width);
    }

    // Try "16:9" format
    {
        float aspect1 = 0.0f, aspect2 = 0.0f;
        if (sscanf_s(str.c_str(), "%f:%f", &aspect1, &aspect2) == 2 && aspect2 > 0.0f && aspect1 > 0.0f)
        {
            return aspect1 / aspect2;
        }
    }

    // Try "21/9" format
    {
        float aspect1 = 0.0f, aspect2 = 0.0f;
        if (sscanf_s(str.c_str(), "%f/%f", &aspect1, &aspect2) == 2 && aspect2 > 0.0f && aspect1 > 0.0f)
        {
            return aspect1 / aspect2;
        }
    }

    return std::nullopt;
}

void* KeyboardBuffer = nullptr;
bool (__fastcall* pIsKeyboardKeyPressed)(void* buffer, void* edx, int keycode, int type, const char* hint) = nullptr;

export bool IsKeyboardKeyPressed(int vkeycode, int type = 1, const char* hint = nullptr)
{
    static auto VKToDIK = [](int vk) -> int
    {
        switch (vk)
        {
            case VK_LSHIFT: return 0x2A; // DIK_LSHIFT
            case VK_RSHIFT: return 0x36; // DIK_RSHIFT
            case VK_LCONTROL: return 0x1D; // DIK_LCONTROL
            case VK_RCONTROL: return 0x9D; // DIK_RCONTROL
            case VK_LMENU: return 0x38; // DIK_LALT
            case VK_RMENU: return 0xB8; // DIK_RALT
            case VK_RETURN: return 0x1C; // DIK_RETURN
            case VK_SPACE: return 0x39; // DIK_SPACE
            case VK_LEFT: return 0xCB; // DIK_LEFT
            case VK_UP: return 0xC8; // DIK_UP
            case VK_RIGHT: return 0xCD; // DIK_RIGHT
            case VK_DOWN: return 0xD0; // DIK_DOWN
            case VK_ESCAPE: return 0x01; // DIK_ESCAPE
            case VK_TAB: return 0x0F; // DIK_TAB
            case VK_BACK: return 0x0E; // DIK_BACK
            case VK_DELETE: return 0xD3; // DIK_DELETE
            case VK_HOME: return 0xC7; // DIK_HOME
            case VK_END: return 0xCF; // DIK_END
            case VK_PRIOR: return 0xC9; // DIK_PGUP
            case VK_NEXT: return 0xD1; // DIK_PGDN
            case VK_INSERT: return 0xD2; // DIK_INSERT
            case VK_F1: return 0x3B; // DIK_F1
            case VK_F2: return 0x3C; // DIK_F2
            case VK_F3: return 0x3D; // DIK_F3
            case VK_F4: return 0x3E; // DIK_F4
            case VK_F5: return 0x3F; // DIK_F5
            case VK_F6: return 0x40; // DIK_F6
            case VK_F7: return 0x41; // DIK_F7
            case VK_F8: return 0x42; // DIK_F8
            case VK_F9: return 0x43; // DIK_F9
            case VK_F10: return 0x44; // DIK_F10
            case VK_F11: return 0x57; // DIK_F11
            case VK_F12: return 0x58; // DIK_F12
            case 'A': return 0x1E;
            case 'B': return 0x30;
            case 'C': return 0x2E;
            case 'D': return 0x20;
            case 'E': return 0x12;
            case 'F': return 0x21;
            case 'G': return 0x22;
            case 'H': return 0x23;
            case 'I': return 0x17;
            case 'J': return 0x24;
            case 'K': return 0x25;
            case 'L': return 0x26;
            case 'M': return 0x32;
            case 'N': return 0x31;
            case 'O': return 0x18;
            case 'P': return 0x19;
            case 'Q': return 0x10;
            case 'R': return 0x13;
            case 'S': return 0x1F;
            case 'T': return 0x14;
            case 'U': return 0x16;
            case 'V': return 0x2F;
            case 'W': return 0x11;
            case 'X': return 0x2D;
            case 'Y': return 0x15;
            case 'Z': return 0x2C;
            case '0': return 0x0B;
            case '1': return 0x02;
            case '2': return 0x03;
            case '3': return 0x04;
            case '4': return 0x05;
            case '5': return 0x06;
            case '6': return 0x07;
            case '7': return 0x08;
            case '8': return 0x09;
            case '9': return 0x0A;
            default: return -1;
        }
    };

    int dik = VKToDIK(vkeycode);
    if (dik != -1)
    {
        return pIsKeyboardKeyPressed(KeyboardBuffer, nullptr, dik, type, hint);
    }
    else
    {
        return (GetAsyncKeyState(vkeycode) & 0x8000) != 0;
    }
}

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

            pattern = hook::pattern("B9 ? ? ? ? E8 ? ? ? ? 84 C0 74 ? E8 ? ? ? ? 2B 86");
            KeyboardBuffer = *pattern.get_first<void**>(1);
            pIsKeyboardKeyPressed = (decltype(pIsKeyboardKeyPressed))injector::GetBranchDestination(pattern.get_first(5)).as_int();
        };
    }
} Common;
