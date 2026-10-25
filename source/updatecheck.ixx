module;

#include <common.hxx>
#include <winhttp.h>
#include <asi_settings/asi_settings.hpp>

#pragma comment(lib, "winhttp.lib")
#pragma comment(lib, "version.lib")

export module updatecheck;

import common;
import comvars;
import natives;
import settings;
import menu;

// "Check for updates" (UPDATE.CheckForUpdates, off by default), as in GTA IV's Fusion Fix. FusionFixHub is the only
// updater; the fix only tells the player:
// - off: nothing at all, no network request;
// - on (at the start, or when turned on while playing): one request to https://fusionfix.io/api/versions on a thread of
//   its own; when its MaxPayne3.FusionFix version is newer than this build, a help text once the game is playable:
//   "Fusion Fix x.y.z is available, FusionFixHub opens when you close the game" when FusionFixHub.exe is in the game's
//   folder, else a pointer to fusionfix.io;
// - with the hub, when the game exits: FusionFixHub.exe --show-update MaxPayne3.FusionFix --wait-pid <pid>, which opens
//   on this game's update page (the player updates there). Never while the game runs; turning the option off cancels it.
class UpdateCheck
{
    enum class State { Idle, Checking, Available, Shown };
    static inline std::atomic<State> state = State::Idle;
    static inline std::atomic<bool> hubAtExit = false;
    static inline std::mutex lock;
    static inline std::string latest;

    static bool Enabled()
    {
        return SettingsPlugin().Int("UPDATE.CheckForUpdates") != 0;
    }

    // https://fusionfix.io/api/versions; FUSIONFIX_VERSIONS_URL in the environment points it elsewhere (tests)
    static std::string Fetch()
    {
        std::string body;
        std::wstring url = L"https://fusionfix.io/api/versions";
        wchar_t env[512] = {};
        if (GetEnvironmentVariableW(L"FUSIONFIX_VERSIONS_URL", env, DWORD(std::size(env))) && env[0])
            url = env;
        URL_COMPONENTS parts{ sizeof(parts) };
        wchar_t host[256] = {}, path[1024] = {};
        parts.lpszHostName = host;
        parts.dwHostNameLength = DWORD(std::size(host));
        parts.lpszUrlPath = path;
        parts.dwUrlPathLength = DWORD(std::size(path));
        if (!WinHttpCrackUrl(url.c_str(), 0, 0, &parts))
            return body;
        auto ua = std::wstring(L"MaxPayne3.FusionFix/") + asi_settings::text::Widen(rsc_FileVersion);
        HINTERNET session = WinHttpOpen(ua.c_str(), WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY, WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, 0);
        if (!session)
            return body;
        WinHttpSetTimeouts(session, 10000, 10000, 10000, 15000);
        if (HINTERNET connect = WinHttpConnect(session, host, parts.nPort, 0))
        {
            DWORD flags = parts.nScheme == INTERNET_SCHEME_HTTPS ? WINHTTP_FLAG_SECURE : 0;
            if (HINTERNET request = WinHttpOpenRequest(connect, L"GET", path, nullptr, WINHTTP_NO_REFERER, WINHTTP_DEFAULT_ACCEPT_TYPES, flags))
            {
                DWORD status = 0, size = sizeof(status);
                if (WinHttpSendRequest(request, WINHTTP_NO_ADDITIONAL_HEADERS, 0, WINHTTP_NO_REQUEST_DATA, 0, 0, 0) && WinHttpReceiveResponse(request, nullptr) &&
                    WinHttpQueryHeaders(request, WINHTTP_QUERY_STATUS_CODE | WINHTTP_QUERY_FLAG_NUMBER, WINHTTP_HEADER_NAME_BY_INDEX, &status, &size, WINHTTP_NO_HEADER_INDEX) &&
                    status == 200)
                {
                    DWORD available = 0;
                    while (WinHttpQueryDataAvailable(request, &available) && available && body.size() < (1u << 20))
                    {
                        std::string chunk(available, '\0');
                        DWORD read = 0;
                        if (!WinHttpReadData(request, chunk.data(), available, &read) || !read)
                            break;
                        body.append(chunk.data(), read);
                    }
                }
                WinHttpCloseHandle(request);
            }
            WinHttpCloseHandle(connect);
        }
        WinHttpCloseHandle(session);
        return body;
    }

    // "2026-10-13T09:40:00Z" (also with fractions or "+00:00") as seconds since 1970, -1 when it isn't one
    static int64_t ParseUtc(std::string_view text)
    {
        std::tm tm{};
        int y = 0, mo = 0, d = 0, h = 0, mi = 0, s = 0;
        if (sscanf_s(std::string(text).c_str(), "%4d-%2d-%2dT%2d:%2d:%2d", &y, &mo, &d, &h, &mi, &s) != 6)
            return -1;
        tm.tm_year = y - 1900;
        tm.tm_mon = mo - 1;
        tm.tm_mday = d;
        tm.tm_hour = h;
        tm.tm_min = mi;
        tm.tm_sec = s;
        return int64_t(_mkgmtime(&tm));
    }

    // The file's last write, seconds since 1970, -1 when unknown
    static int64_t FileTime(const wchar_t* path)
    {
        WIN32_FILE_ATTRIBUTE_DATA data{};
        if (!GetFileAttributesExW(path, GetFileExInfoStandard, &data))
            return -1;
        ULARGE_INTEGER t{ data.ftLastWriteTime.dwLowDateTime, data.ftLastWriteTime.dwHighDateTime };
        return int64_t((t.QuadPart - 116444736000000000ull) / 10000000ull);
    }

    // BuildTimeUtc of this plugin's version resource (tools/buildtime.ps1 writes it before every build); a build
    // without it (an old one) counts from its file's time, as the hub does
    static int64_t BuildTime()
    {
        HMODULE self = nullptr;
        GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT, reinterpret_cast<LPCWSTR>(&BuildTime), &self);
        wchar_t path[MAX_PATH * 4] = {};
        GetModuleFileNameW(self, path, DWORD(std::size(path)));
        int64_t fromResource = -1;
        DWORD handle = 0, size = GetFileVersionInfoSizeW(path, &handle);
        std::vector<uint8_t> info(size);
        struct Translation { WORD language, codepage; }* translations = nullptr;
        UINT length = 0;
        wchar_t* value = nullptr;
        if (size && GetFileVersionInfoW(path, 0, size, info.data()) &&
            VerQueryValueW(info.data(), L"\\VarFileInfo\\Translation", reinterpret_cast<void**>(&translations), &length) && length >= sizeof(Translation))
        {
            wchar_t key[64];
            swprintf_s(key, L"\\StringFileInfo\\%04x%04x\\BuildTimeUtc", translations[0].language, translations[0].codepage);
            if (VerQueryValueW(info.data(), key, reinterpret_cast<void**>(&value), &length) && value)
                fromResource = ParseUtc(asi_settings::text::Narrow(value));
        }
        return fromResource >= 0 ? fromResource : FileTime(path);
    }

    static void Check()
    {
        State expected = State::Idle;
        if (!state.compare_exchange_strong(expected, State::Checking))
            return;
        std::thread([]()
        {
            // Newer = the release asset was uploaded more than 30 minutes after this build was made (a release's own
            // build is made just before its upload; a build without BuildTimeUtc counts from its file's time). The
            // version text is only shown.
            asi_settings::json::Value data;
            std::string version, uploaded;
            if (auto body = Fetch(); !body.empty() && asi_settings::json::Parse(body, data))
            {
                if (auto fixes = data.Find("fixes"))
                    if (auto own = fixes->Find("MaxPayne3.FusionFix"))
                    {
                        version = std::string(own->Str("version"));
                        if (auto asset = own->Find("asset"))
                            uploaded = std::string(asset->Str("updatedAt"));
                        if (uploaded.empty())
                            uploaded = std::string(own->Str("date"));
                    }
            }
            bool newer = false;
            int64_t built = BuildTime(), released = ParseUtc(uploaded);
            if (built >= 0 && released >= 0)
                newer = released > built + 30 * 60;
            if (newer)
            {
                std::lock_guard guard(lock);
                latest = version.empty() ? uploaded.substr(0, 10) : version;
                state = State::Available;
            }
            // Nothing newer or no answer: the next check is the next start (or the option turned on again)
            else
                state = State::Idle;
        }).detach();
    }

    static bool HubPresent()
    {
        std::error_code ec;
        return std::filesystem::exists(GetExeModulePath() / L"FusionFixHub.exe", ec);
    }

    // PRINT_HELP with a text key: the handlers read string arguments relative to the script thread (type 1 = the
    // thread's +0x40 plus an offset, sub_10FE020), so the context gets a thread of its own whose +0x40 is the string.
    // The help code also reads the current script thread (sub_10FE150, dword_12276778: +0x72, a flag), which is null
    // outside the scripts' run: it's that thread for the call.
    static void PrintHelp(const char* key)
    {
        static auto ppCurrentThread = []() -> void**
        {
            auto pattern = hook::pattern("A1 ? ? ? ? C3 CC CC CC CC CC CC CC CC CC CC 8B 44 24 04 56 8B F1");
            return pattern.empty() ? nullptr : *pattern.get_first<void**>(1);
        }();
        if (!getNativeAddress || !nativeHandlerPtrAddress || !ppCurrentThread)
            return;
        struct sncall { int32_t flag; void(__cdecl* fun)(void*); };
        auto handler = static_cast<sncall*>(getNativeAddress(nativeHandlerPtrAddress, 0, std::to_underlying(Natives::NativeHashes::PRINT_HELP)));
        if (!handler || !handler->fun)
            return;
        alignas(16) static uint8_t thread[0x100];
        static char text[64];
        strncpy_s(text, key, _TRUNCATE);
        *reinterpret_cast<char**>(thread + 0x40) = text;
        uint32_t args[4] = { 0x20000000u };
        uint32_t result[4] = {};
        uint8_t context[256] = {};
        *reinterpret_cast<void**>(context + 0x0) = thread;
        *reinterpret_cast<void**>(context + 0x4) = result;
        *reinterpret_cast<uint32_t*>(context + 0x8) = 1;
        *reinterpret_cast<void**>(context + 0xC) = args;
        void* previous = *ppCurrentThread;
        if (!previous)
            *ppCurrentThread = thread;
        handler->fun(context);
        *ppCurrentThread = previous;
    }

    // Once the game is playable: the help text
    static void ShowNotice()
    {
        if (state != State::Available || !Enabled())
            return;
        // In a level, playable: the title screen counts as playing but has no control and no help box
        auto player = Natives::GetPlayerId();
        if (Natives::IsPauseMenuActive() || Natives::IsHelpMessageBeingDisplayed() || !Natives::IsPlayerPlaying(player) ||
            !Natives::IsPlayerControlOn(player) || !Natives::IsScreenFadedIn())
            return;
        std::string version;
        {
            std::lock_guard guard(lock);
            version = latest;
        }
        bool hub = HubPresent();
        auto text = FusionFixText(hub ? "update.hub" : "update.site");
        if (auto at = text.find("{}"); at != std::string::npos)
            text.replace(at, 2, version);
        PrintHelp(GameTextKey(text));
        hubAtExit = hub;
        state = State::Shown;
    }

    // At exit, with the notice shown and the option still on: the hub on this game's update page, after the game is gone
    static void StartHub()
    {
        if (!hubAtExit || !Enabled())
            return;
        hubAtExit = false;
        auto hub = GetExeModulePath() / L"FusionFixHub.exe";
        std::wstring command = L"\"" + hub.wstring() + L"\" --show-update MaxPayne3.FusionFix --wait-pid " + std::to_wstring(GetCurrentProcessId());
        STARTUPINFOW si{ sizeof(si) };
        PROCESS_INFORMATION pi{};
        if (CreateProcessW(hub.c_str(), command.data(), nullptr, nullptr, FALSE, DETACHED_PROCESS | CREATE_NEW_PROCESS_GROUP, nullptr,
            GetExeModulePath().c_str(), &si, &pi))
        {
            CloseHandle(pi.hThread);
            CloseHandle(pi.hProcess);
        }
    }

public:
    UpdateCheck()
    {
        FusionFix::onInitEventAsync() += []()
        {
            if (Enabled())
                Check();
        };

        FusionFix::onInitEvent() += []()
        {
            // Turned on while playing: check now; shown before it was turned off: the hub opens at exit again
            SettingsPlugin().OnChange("UPDATE.CheckForUpdates", []()
            {
                if (Enabled())
                {
                    Check();
                    if (state == State::Shown)
                        hubAtExit = HubPresent();
                }
                else
                    hubAtExit = false;
            });
        };

        FusionFix::onGameProcessEvent() += []()
        {
            if (state == State::Available)
                ShowNotice();
        };

        // The game's ExitProcess (led.ixx hooks it); not DLL_PROCESS_DETACH, where CreateProcess doesn't start the hub
        FusionFix::onExitEvent() += []()
        {
            StartHub();
        };
    }
} UpdateCheck;
