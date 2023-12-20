module;

#include <common.hxx>

export module natives;

import common;
import comvars;

export using Any = int32_t;
export using Weapon = int32_t;
export using Player = int32_t;
export using FireId = int32_t;
export using Ped = int32_t;
export using Vehicle = int32_t;
export using Cam = int32_t;
export using CarGenerator = int32_t;
export using Group = int32_t;
export using Train = int32_t;
export using Pickup = int32_t;
export using Object = int32_t;
export using Interior = int32_t;
export using Blip = int32_t;
export using Texture = int32_t;
export using TextureDict = int32_t;
export using CoverPoint = int32_t;
export using DecisionMaker = int32_t;
export using Camera = int32_t;
export using TaskSequence = int32_t;
export using Char = int32_t;
export using Car = int32_t;
export using ColourIndex = int32_t;
export using Sphere = int32_t;
export using ExplosionType = int32_t;
export using ShootMode = int32_t;
export using RelationshipGroup = int32_t;
export using QuadChar = int32_t;
export using GtaThread = int32_t;

export struct Vector3 
{
    float fX;
    float fY;
    float fZ;
};

export struct Vector4
 {
    float fX;
    float fY;
    float fZ;
    float fW;
};

export struct Color32
 {
    uint8_t b;
    uint8_t g;
    uint8_t r;
    uint8_t a;
};


static GtaThread dummyThread[1024];
export class scrNativeCallContext
{
protected:
    GtaThread* m_pThread = dummyThread;
    void* m_pReturn;
    uint32_t m_nArgCount;
    void* m_pArgs;
    uint32_t m_nDataCount;
    Vector3* m_pOriginalData[4];
    Vector4  m_TemporaryData[4];

public:
    template<typename T>
    inline T GetArgument(int idx)
    {
        auto arguments = (intptr_t*)m_pArgs;
        return *reinterpret_cast<T*>(&arguments[idx]);
    }

    inline void* GetArgumentBuffer()
    {
        return m_pArgs;
    }

    template<typename T>
    inline void SetResult(int idx, T value)
    {
        auto returnValues = (intptr_t*)m_pReturn;
        *reinterpret_cast<T*>(&returnValues[idx]) = value;
    }

    inline int GetArgumentCount()
    {
        return m_nArgCount;
    }

    template<typename T>
    inline T GetResult(int idx)
    {
        while (m_nDataCount > 0)
        {
            m_nDataCount--;
            Vector3* pVec3 = m_pOriginalData[m_nDataCount];
            Vector4* pVec4 = &m_TemporaryData[m_nDataCount];
            pVec3->fX = pVec4->fX;
            pVec3->fY = pVec4->fY;
            pVec3->fZ = pVec4->fZ;
        }
        auto returnValues = (intptr_t*)m_pReturn;
        return *reinterpret_cast<T*>(&returnValues[idx]);
    }
};

export class NativeContext : public scrNativeCallContext
{
private:
    // Configuration
    enum
    {
        MaxNativeParams = 16,
        ArgSize = 4,
    };

    // Anything temporary that we need
    uint8_t m_TempStack[MaxNativeParams * ArgSize] = {};

public:
    inline NativeContext()
    {
        m_pArgs = &m_TempStack;
        m_pReturn = &m_TempStack;		// It's okay to point both args and return at the same pointer. The game should handle this.
        m_nArgCount = 0;
        m_nDataCount = 0;
    }

    template <typename T>
    inline void Push(T value)
    {
        if (sizeof(T) > ArgSize)
        {
            // We only accept sized 4 or less arguments... that means no double/f64 or large structs are allowed.
            throw "Argument has an invalid size";
        }
        else if (sizeof(T) < ArgSize)
        {
            // Ensure we don't have any stray data
            *reinterpret_cast<uintptr_t*>(m_TempStack + ArgSize * m_nArgCount) = 0;
        }

        *reinterpret_cast<T*>(m_TempStack + ArgSize * m_nArgCount) = value;
        m_nArgCount++;
    }

    template <typename T>
    inline T GetResult()
    {
        return *reinterpret_cast<T*>(m_TempStack);
    }
};

export class NativeInvoke
{
private:
    struct sncall 
	{
        int32_t i;
        int32_t(*fun)(NativeContext*);
    };

    static inline auto m_IndexTable = std::vector<sncall*>(4000, nullptr);
public:
    static sncall* GetNativeHandler(uint32_t Hash)
    {
        if (getNativeAddress)
            return reinterpret_cast<sncall*>(getNativeAddress(nativeHandlerPtrAddress, 0, Hash));

        return nullptr;
    }
public:
    template<uint32_t Index, uint32_t Hash, typename R, typename... Args>
    static inline R Invoke(Args... args)
    {
        NativeContext cxt;
        (cxt.Push(args), ...);

        //if (CTimer__m_CodePause && !*CTimer__m_CodePause)
        //{
            if (!m_IndexTable[Index])
            {
                auto fn = GetNativeHandler(Hash);
                if (fn) {
                    m_IndexTable[Index] = fn;
                    fn->fun(&cxt);
                }
            }
            else
            {
                m_IndexTable[Index]->fun(&cxt);
            }
        //}

        if constexpr (!std::is_void_v<R>)
        {
            return cxt.GetResult<R>();
        }
    }
};

export class NativeOverride
{
public:
    static auto Register(auto hash, auto fn, std::string_view dest_pattern_str, size_t fn_size)
    {
        auto nativeHash = std::to_underlying(hash);
        auto pattern = hook::pattern(pattern_str(0x68, to_bytes(nativeHash))); // push 0x...
        auto addr = *pattern.get_first<uintptr_t>(-4);
        auto range = hook::range_pattern(addr, addr + fn_size, dest_pattern_str);
        if (!range.empty())
        {
            if (dest_pattern_str.starts_with("E8"))
                return injector::MakeCALL(range.get_first(0), fn, true).get();
            else if (dest_pattern_str.starts_with("E9"))
                return injector::MakeJMP(range.get_first(0), fn, true).get();
        }
        return injector::auto_pointer(nullptr);
    }
};

export class Natives 
{
public:
	// Temp natives
    static int32_t GET_REAL_TIME() {
        return NativeInvoke::Invoke<0, 0xCBB4CA94, int32_t>();
    }
    static float GET_TIME_SCALE() {
        return NativeInvoke::Invoke<1, 0x8CFD581F, float>();
    }
    static float GET_CURRENT_FPS() {
        return NativeInvoke::Invoke<2, 0x7030FB99, float>();
    }
    static bool IS_KEYBOARD_KEY_JUST_PRESSED(int key) {
        return NativeInvoke::Invoke<3, 0xEAC23998, bool>(key);
    }

};
