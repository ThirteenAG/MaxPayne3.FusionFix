#pragma once

#include <windows.h>
#include <algorithm>
#include <array>
#include <atomic>
#include <cmath>
#include <cstdarg>
#include <cstdio>
#include <cstring>
#include <filesystem>
#include <share.h>
#include <mutex>
#include <string>
#include <upscaler/upscaler_bridge_client.h>

namespace Antialiasing
{
    enum class Backend : uint32_t
    {
        DLSS = static_cast<uint32_t>(UpscalerBridge::Backend::DLSS),
        FSR = static_cast<uint32_t>(UpscalerBridge::Backend::FSR),
    };


    struct Matrix
    {
        double m[4][4]{};

        static Matrix Identity()
        {
            Matrix r;
            for (int i = 0; i < 4; ++i)
                r.m[i][i] = 1.0;
            return r;
        }

        static Matrix From(const float* f)
        {
            Matrix r;
            for (int i = 0; i < 4; ++i)
                for (int j = 0; j < 4; ++j)
                    r.m[i][j] = f[i * 4 + j];
            return r;
        }

        void To(float* f) const
        {
            for (int i = 0; i < 4; ++i)
                for (int j = 0; j < 4; ++j)
                    f[i * 4 + j] = static_cast<float>(m[i][j]);
        }

        Matrix operator*(const Matrix& b) const
        {
            Matrix r;
            for (int i = 0; i < 4; ++i)
                for (int j = 0; j < 4; ++j)
                    r.m[i][j] = m[i][0] * b.m[0][j] + m[i][1] * b.m[1][j] + m[i][2] * b.m[2][j] + m[i][3] * b.m[3][j];
            return r;
        }

        Matrix Inverse() const
        {
            Matrix a = *this;
            Matrix r = Identity();
            for (int c = 0; c < 4; ++c)
            {
                int pivot = c;
                for (int i = c + 1; i < 4; ++i)
                    if (std::abs(a.m[i][c]) > std::abs(a.m[pivot][c]))
                        pivot = i;
                if (std::abs(a.m[pivot][c]) < 1e-12)
                    return Identity();
                std::swap(a.m[c], a.m[pivot]);
                std::swap(r.m[c], r.m[pivot]);
                double inv = 1.0 / a.m[c][c];
                for (int j = 0; j < 4; ++j)
                {
                    a.m[c][j] *= inv;
                    r.m[c][j] *= inv;
                }
                for (int i = 0; i < 4; ++i)
                {
                    if (i == c)
                        continue;
                    double f = a.m[i][c];
                    for (int j = 0; j < 4; ++j)
                    {
                        a.m[i][j] -= f * a.m[c][j];
                        r.m[i][j] -= f * r.m[c][j];
                    }
                }
            }
            return r;
        }
    };

    inline float Halton(uint32_t index, uint32_t base)
    {
        float f = 1.0f;
        float r = 0.0f;
        while (index > 0)
        {
            f /= static_cast<float>(base);
            r += f * static_cast<float>(index % base);
            index /= base;
        }
        return r;
    }

    struct Jitter
    {
        float X = 0.0f;
        float Y = 0.0f;
    };

    struct Options
    {
        std::wstring BridgeName;
        std::string ClientName;
        std::filesystem::path Log;
        std::filesystem::path HubLog;
        uint32_t DLSSPreset{};
        bool LowDynamicRange{ true };
    };

    namespace detail
    {
        inline Options& Config()
        {
            static Options options;
            return options;
        }

        inline void Log([[maybe_unused]] const char* format, ...)
        {
#ifdef _DEBUG
            static std::mutex mutex;
            static FILE* file = nullptr;
            static bool opened = false;
            std::lock_guard lock(mutex);
            if (!opened)
            {
                opened = true;
                if (!Config().Log.empty())
                    file = _wfsopen(Config().Log.c_str(), L"w", _SH_DENYWR);
            }
            if (!file)
                return;
            SYSTEMTIME t;
            GetLocalTime(&t);
            fprintf(file, "%02d:%02d:%02d.%03d ", t.wHour, t.wMinute, t.wSecond, t.wMilliseconds);
            va_list args;
            va_start(args, format);
            vfprintf(file, format, args);
            va_end(args);
            fputc('\n', file);
            fflush(file);
#endif
        }

        template <typename T>
        void SafeRelease(T*& p)
        {
            if (p)
            {
                p->Release();
                p = nullptr;
            }
        }


    }
}

namespace Antialiasing::detail
{
    namespace Protocol = UpscalerBridge;
    inline constexpr size_t TextureCount = static_cast<size_t>(Protocol::Texture::Count);
    inline constexpr size_t InputCount = Protocol::InputCount;
    inline constexpr size_t OutputIndex = static_cast<size_t>(Protocol::Texture::Output);

    inline void CloseSharedHandles(Protocol::Shared& shared)
    {
        for (auto& handle : shared.TextureHandles)
        {
            if (handle)
                CloseHandle(reinterpret_cast<HANDLE>(handle));
            handle = 0;
        }
        if (shared.FenceHandle)
            CloseHandle(reinterpret_cast<HANDLE>(shared.FenceHandle));
        shared.FenceHandle = 0;
    }
}

#include "UpscalerD3D11.inl"
