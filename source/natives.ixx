module;

#include <common.hxx>

export module natives;

import common;
import comvars;

export using Any = int32_t;
export using Weapon = int32_t;
export using Player = int32_t;
export using Entity = int32_t;
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

export struct Request
{
	int32_t index;
	int32_t field_2;
};

export class scrNativeCallContext
{
protected:
    GtaThread* m_pThread;
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
        m_pThread = (GtaThread*)&m_TempStack;
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

    static inline auto m_IndexTable = std::unordered_map<uint32_t, sncall*>();
public:
    static sncall* GetNativeHandler(uint32_t Hash)
    {
        if (getNativeAddress)
            return reinterpret_cast<sncall*>(getNativeAddress(nativeHandlerPtrAddress, 0, Hash));

        return nullptr;
    }
public:
    template<typename R, typename... Args>
    static inline R Invoke(uint32_t Hash, Args... args)
    {
        NativeContext cxt;
        (cxt.Push(args), ...);

        //if (CTimer__m_CodePause && !*CTimer__m_CodePause)
        //{
            if (!m_IndexTable[Hash])
            {
                auto fn = GetNativeHandler(Hash);
                if (fn) {
                    m_IndexTable[Hash] = fn;
                    fn->fun(&cxt);
                }
            }
            else
            {
                m_IndexTable[Hash]->fun(&cxt);
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
	static Any ACTIVATE_BULLET_TIME_AS_PLAYER() { return NativeInvoke::Invoke<Any>(0x25B796C8); }
 	static Any ACTIVATE_LOADOUT_SCREEN() { return NativeInvoke::Invoke<Any>(0xD3C74E5D); }
	static Any ADD_COVER_BLOCKING_AREA() { return NativeInvoke::Invoke<Any>(0x3536946F); }
	static Any ADD_KILLXP_RULE() { return NativeInvoke::Invoke<Any>(0x216F295D); }
	static Any ADD_PED_DECISION_MAKER_EVENT_RESPONSE() { return NativeInvoke::Invoke<Any>(0x2B02F9D4); }
	static Any ADD_PED_IGNORE_COVER_ENTRY() { return NativeInvoke::Invoke<Any>(0x89C1F145); }
	static Any ADD_ROPE(Vector3* coords, Vector3* rot, float length, int32_t ropeType) { return NativeInvoke::Invoke<Any>(0xA592EC74, coords, rot, length, ropeType); }
	static Any ADD_SPATIALDATA_COVER_POINT(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9) { return NativeInvoke::Invoke<Any>(0x184DE0A6, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9); }
	static Any ADD_TO_PREVIOUS_BRIEF() { return NativeInvoke::Invoke<Any>(0xFE33CF4A); }
	static Any ADD_TO_PREVIOUS_BRIEF_WITH_UNDERSCORE() { return NativeInvoke::Invoke<Any>(0xB12B4573); }
	static Any ADD_VEHICLE_SUBTASK_ATTACK_COORD() { return NativeInvoke::Invoke<Any>(0x50779A2C); }
	static Any ADD_VEHICLE_SUBTASK_ATTACK_PED() { return NativeInvoke::Invoke<Any>(0x80461113); }
	static Any ADD_VEHICLE_SUBTASK_STRAFE_COORDS() { return NativeInvoke::Invoke<Any>(0xDDA8AA23); }
	static Any ADD_WIDGET_FLOAT_READ_ONLY(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0xEF2D8DEA, p0, p1); }
	static Any ADD_WIDGET_FLOAT_SLIDER(Any p0, Any p1, Any p2, Any p3, Any p4) { return NativeInvoke::Invoke<Any>(0x67865135, p0, p1, p2, p3, p4); }
	static Any ADD_WIDGET_INT_READ_ONLY(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0xB3F4D0DF, p0, p1); }
	static Any ADD_WIDGET_INT_SLIDER(Any p0, Any p1, Any p2, Any p3, Any p4) { return NativeInvoke::Invoke<Any>(0xF6A6C926, p0, p1, p2, p3, p4); }
	static Any ADD_WIDGET_bool(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0xECBF5BB2, p0, p1); }
	static Any ADD_WIND_THERMAL() { return NativeInvoke::Invoke<Any>(0xF355A848); }
	static Any ARE_PLAYER_FLASHING_STARS_ABOUT_TO_DROP() { return NativeInvoke::Invoke<Any>(0xE13A71C7); }
	static Any ARE_PLAYER_STARS_GREYED_OUT() { return NativeInvoke::Invoke<Any>(0x5E72AB72); }
	static Any ATTACH_OBJECT_TO_OBJECT_PHYSICALLY() { return NativeInvoke::Invoke<Any>(0x7C98BD8E); }
	static Any ATTACH_OBJECT_TO_VEHICLE_PHYSICALLY() { return NativeInvoke::Invoke<Any>(0xF903C741); }
	static Any ATTACH_PED_TO_OBJECT_PHYSICALLY() { return NativeInvoke::Invoke<Any>(0x37F17899); }
	static Any ATTACH_PED_TO_PED() { return NativeInvoke::Invoke<Any>(0xAFB33CC2); }
	static Any ATTACH_PED_TO_PED_PHYSICALLY() { return NativeInvoke::Invoke<Any>(0x10673612); }
	static Any AUDIO_CHANGE_PORTAL_SETTINGS() { return NativeInvoke::Invoke<Any>(0xD0DF16AD); } 
	static Any AUDIO_DISABLE_WADING_SOUNDS() { return NativeInvoke::Invoke<Any>(0x6A9FF2B8); } 
	static Any AUDIO_IS_CUTSCENE_PLAYING() { return NativeInvoke::Invoke<Any>(0xE026C62E); } 
	static Any AUDIO_IS_FRONTEND_MUSIC_PLAYING() { return NativeInvoke::Invoke<Any>(0x9EC502D6); } 
	static Any AUDIO_LOAD_BANK() { return NativeInvoke::Invoke<Any>(0xF418A70); } 
	static Any AUDIO_LOAD_METADATA() { return NativeInvoke::Invoke<Any>(0xE8424B87); } 
	static Any AUDIO_LOAD_SPEECH_DATA() { return NativeInvoke::Invoke<Any>(0x94C4FDB5); } 
	static Any AUDIO_MAKE_SLOT_STATIC() { return NativeInvoke::Invoke<Any>(0x943F7EB0); } 
	static Any AUDIO_MUSIC_CLEAR_AUDIO_SYNC_VARIABLES() { return NativeInvoke::Invoke<Any>(0xE73CA44B); } 
	static Any AUDIO_MUSIC_FORCE_TRACK_HASH() { return NativeInvoke::Invoke<Any>(0x6CEFA97A); } 
	static Any AUDIO_MUSIC_GET_MS_UNTIL_AUDIO_SYNC() { return NativeInvoke::Invoke<Any>(0x2CBEC97); } 
	static Any AUDIO_MUSIC_IS_AUDIO_SYNC_NOW() { return NativeInvoke::Invoke<Any>(0xED9CA16F); } 
	static Any AUDIO_MUSIC_IS_MARKER_IN_RANGE() { return NativeInvoke::Invoke<Any>(0xAAB5C232); } 
	static Any AUDIO_MUSIC_IS_ONESHOT_PREPARED(Any p0) { return NativeInvoke::Invoke<Any>(0xCF2727F, p0); }
	static Any AUDIO_MUSIC_IS_PREPARED() { return NativeInvoke::Invoke<Any>(0xBF316157); } 
	static Any AUDIO_MUSIC_ONE_SHOT() { return NativeInvoke::Invoke<Any>(0x714DA5BB); } 
	static Any AUDIO_MUSIC_PLAY_PREPARED() { return NativeInvoke::Invoke<Any>(0x7CC2738F); } 
	static Any AUDIO_MUSIC_PLAY_UNSCRIPTED_NOW() { return NativeInvoke::Invoke<Any>(0xE2A37056); } 
	static Any AUDIO_MUSIC_PRELOAD_ONESHOT(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0x404A0AE6, p0, p1); }
	static Any AUDIO_MUSIC_RELEASE_CONTROL() { return NativeInvoke::Invoke<Any>(0xA3A2984E); } 
	static Any AUDIO_MUSIC_REQUEST_ONESHOT(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0x607773A0, p0, p1); }
	static Any AUDIO_MUSIC_RESUME() { return NativeInvoke::Invoke<Any>(0x5F48A85B); } 
	static Any AUDIO_MUSIC_SET_STATE() { return NativeInvoke::Invoke<Any>(0x789C753C); } 
	static Any AUDIO_MUSIC_SET_SUSPENSE_ALLOWED() { return NativeInvoke::Invoke<Any>(0xE0DE16BD); } 
	static Any AUDIO_SET_BREATHING_STATUS() { return NativeInvoke::Invoke<Any>(0x22A622F1); } 
	static Any AUDIO_SET_PED_FOOTSTEPS_ROLLOFF() { return NativeInvoke::Invoke<Any>(0xB125E896); } 
	static Any AUDIO_SET_PLAYER_PAIN_NAME() { return NativeInvoke::Invoke<Any>(0xE8A10A1A); } 
	static Any AUDIO_SET_SIDEKICK_PAIN_NAME() { return NativeInvoke::Invoke<Any>(0x7C64FB16); } 
	static Any AUDIO_SET_SINGLE_PED_FOOTSTEPS_ON() { return NativeInvoke::Invoke<Any>(0xB15ADFA); } 
	static Any AUDIO_UNLOAD_METADATA() { return NativeInvoke::Invoke<Any>(0xD1A72EA2); } 
	static Any BG_SCRIPT_ADJUST_BY_UNIT(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0x6124EBD6, p0, p1); }
	static Any BROADCAST_UNIT_TEST_MESSAGE() { return NativeInvoke::Invoke<Any>(0x44E68F92); }
	static Any CAMERA_ANIMATED_CURRENT_TIME() { return NativeInvoke::Invoke<Any>(0x79AF1166); }
	static Any CAMERA_ANIMATED_LENGTH(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0xA6DA5494, p0, p1); }
	static Any CAMERA_ANIMATED_START_FOV(Any p0, Any p1, Any p2) { return NativeInvoke::Invoke<Any>(0x83EC5A3, p0, p1, p2); }
	static Any CAMERA_ANIMATED_START_HEADING(Any p0, Any p1, Any p2) { return NativeInvoke::Invoke<Any>(0xA7596ABA, p0, p1, p2); }
	static Any CAMERA_ANIMATED_START_POSITION(Any p0, Any p1, Any p2) { return NativeInvoke::Invoke<Any>(0xCA7616AE, p0, p1, p2); }
	static Any CAMERA_ANIMATED_USE_DOF() { return NativeInvoke::Invoke<Any>(0xFB7557B5); } 
	static Any CAMERA_IS_POINTING_AT_TARGET() { return NativeInvoke::Invoke<Any>(0x6C7043F0); } 
	static Any CHANGE_AMBIENT_STREAM_SOUND() { return NativeInvoke::Invoke<Any>(0xAAA16BCB); } 
	static Any CLEAR_NAMED_DEBUG_FILE() { return NativeInvoke::Invoke<Any>(0xD62B95EB); } 
	static Any CLEAR_PED_DECISION_MAKER_EVENT_RESPONSE() { return NativeInvoke::Invoke<Any>(0x6BEC1C96); }
	static Any CLEAR_SCRIPT_ARRAY_FROM_SCRATCHPAD() { return NativeInvoke::Invoke<Any>(0x50770E90); }
	static Any CLEAR_SCRIPT_STREAM_REQUESTS() { return NativeInvoke::Invoke<Any>(0x108F237A); } 
	static Any CLEAR_SMALL_PRINTS() { return NativeInvoke::Invoke<Any>(0xA869A238); }
	static Any CLEAR_THIS_PRINT() { return NativeInvoke::Invoke<Any>(0x6878327); }
	static Any CLOSE_DEBUG_FILE() { return NativeInvoke::Invoke<Any>(0xAFDE128D); } 
	static Any COMMIT_EXPERIENCE() { return NativeInvoke::Invoke<Any>(0x494CD629); }
	static Any COPY_GROUP_PED_DECISION_MAKER() { return NativeInvoke::Invoke<Any>(0xFC573D85); }
	static Any COPY_PED_DECISION_MAKER() { return NativeInvoke::Invoke<Any>(0x95C28AAA); }
	static Any CREATE_AMMOBAG_PLACEMENT() { return NativeInvoke::Invoke<Any>(0x4976E3EC); }
	static Any CREATE_AMMOBAG_PLACEMENT_ROTATE(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9) { return NativeInvoke::Invoke<Any>(0x85481503, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9); }
	static Any CREATE_CHECKPOINT(int32_t type, float posX1, float posY1, float posZ1, float posX2, float posY2, float posZ2, float radius) { return NativeInvoke::Invoke<Any>(0xF541B690, type, posX1, posY1, posZ1, posX2, posY2, posZ2, radius); }
	static Any CREATE_LOADOUT_SCREEN() { return NativeInvoke::Invoke<Any>(0xD6A8ACE); }
	static Any CREATE_PLACEMENT() { return NativeInvoke::Invoke<Any>(0xD8BC413C); }
	static Any CREATE_PLACEMENT_ROTATE(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9, Any p10) { return NativeInvoke::Invoke<Any>(0xA460F7A8, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10); }
	static Any CREATE_PLAYER(Any p0, float x, float y, float z) { return NativeInvoke::Invoke<Any>(0x584BA966, p0, x, y, z); }
	static Any CREATE_PLAYER_WITH_AVATAR(uint32_t avatarHash, float x, float y, float z, bool p4) { return NativeInvoke::Invoke<Any>(0x3A072305, avatarHash, x, y, z, p4); }
	static Any CREATE_PLAYER_WITH_MODEL(uint32_t modelHash, float x, float y, float z) { return NativeInvoke::Invoke<Any>(0xE043534F, modelHash, x, y, z); }
	static Any CUTSCENE_REGISTER_OBJECT_ANIM(Object object, const char* animName, const char* animDict, float p3, bool p4, bool p5) { return NativeInvoke::Invoke<Any>(0x5D7E7FD3, object, animName, animDict, p3, p4, p5); }
	static Any DEACTIVATE_BULLET_TIME_AS_PLAYER() { return NativeInvoke::Invoke<Any>(0xF73F2994); }
	static Any DEATHRECORDS_GET_PLAYERDETAILS_CLANTAG() { return NativeInvoke::Invoke<Any>(0x5D9852F1); }
	static Any DEATHRECORDS_GET_PLAYERDETAILS_TITLE() { return NativeInvoke::Invoke<Any>(0xC0E77C55); }
	static Any DEATHRECORD_ENABLE_ASSIST_XP() { return NativeInvoke::Invoke<Any>(0x7B57BCB4); }
	static Any DEATHRECORD_GET_NUM_SHOTS(Any p0) { return NativeInvoke::Invoke<Any>(0x2440E150, p0); }
	static Any DEATHRECORD_GET_RECORD_BULLETCOUNT() { return NativeInvoke::Invoke<Any>(0x32DF7A7C); }
	static Any DEATHRECORD_GET_RECORD_COMPONENT() { return NativeInvoke::Invoke<Any>(0x3206476F); }
	static Any DEATHRECORD_GET_RECORD_DAMAGE() { return NativeInvoke::Invoke<Any>(0x6E4BAE71); }
	static Any DEATHRECORD_GET_RECORD_FLAGS() { return NativeInvoke::Invoke<Any>(0x6757C77E); }
	static Any DEATHRECORD_GET_RECORD_FROM() { return NativeInvoke::Invoke<Any>(0x299D7260); }
	static Any DEATHRECORD_GET_RECORD_INJURER() { return NativeInvoke::Invoke<Any>(0x15AD04A8); }
	static Any DEATHRECORD_GET_RECORD_IS_CURRENT_LIFE() { return NativeInvoke::Invoke<Any>(0x856DC911); }
	static Any DEATHRECORD_GET_RECORD_TIME() { return NativeInvoke::Invoke<Any>(0x43885806); }
	static Any DEATHRECORD_GET_RECORD_WEAPON() { return NativeInvoke::Invoke<Any>(0x109F9168); }
	static Any DEATHRECORD_GET_SHOT_BULLETCOUNT(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0x64D92447, p0, p1); }
	static Any DEATHRECORD_GET_SHOT_COMPONENT(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0x627DC94C, p0, p1); }
	static Any DEATHRECORD_GET_SHOT_DAMAGE(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0x3C46098C, p0, p1); }
	static Any DEATHRECORD_GET_SHOT_FLAGS() { return NativeInvoke::Invoke<Any>(0x58F142F7); }
	static Any DEATHRECORD_GET_SHOT_FROM() { return NativeInvoke::Invoke<Any>(0x56969A61); }
	static Any DEATHRECORD_GET_SHOT_INJURER(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0xFECD86FE, p0, p1); }
	static Any DEATHRECORD_GET_SHOT_IS_CURRENT_LIFE(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0xF2CD43F4, p0, p1); }
	static Any DEATHRECORD_GET_SHOT_TIME(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0xF1CC37C, p0, p1); }
	static Any DEATHRECORD_GET_SHOT_WEAPON(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0x2EE4D113, p0, p1); }
	static Any DEATHRECORD_GET_SUB_KILLER_PERCENT() { return NativeInvoke::Invoke<Any>(0x664EC0F1); }
	static Any DEATHRECORD_GET_SUB_KILLER_PLAYER_INDEX(Any p0) { return NativeInvoke::Invoke<Any>(0x403EB684, p0); }
	static Any DEATHRECORD_GET_SUB_KILLER_PRIMARY() { return NativeInvoke::Invoke<Any>(0x1885BC2D); }
	static Any DEATHRECORD_GET_SUB_KILLER_RANK() { return NativeInvoke::Invoke<Any>(0x104186FD); }
	static Any DEATHRECORD_GET_SUB_KILLER_SECONDARY() { return NativeInvoke::Invoke<Any>(0x977DD5B6); }
	static Any DEBUGDRAW_GETSCREENSPACETEXTHEIGHT() { return NativeInvoke::Invoke<Any>(0x5DD864FD); }
	static Any DEBUG_SET_SELECTED_PED() { return NativeInvoke::Invoke<Any>(0x6F65ABB3); } 
	static Any DESTROY_LOADOUT_SCREEN() { return NativeInvoke::Invoke<Any>(0x660F22FF); }
	static Any DISPLAY_PLAYBACK_RECORDED_VEHICLE() { return NativeInvoke::Invoke<Any>(0x894D590B); }
	static Any DISPLAY_SEAMLESS_CUTSCENE_TRIGGER_AREA() { return NativeInvoke::Invoke<Any>(0xA080611B); }
	static Any DISPLAY_TEXT_WITH_2_NUMBERS() { return NativeInvoke::Invoke<Any>(0x6931FB7C); }
	static Any DISPLAY_TEXT_WITH_3_NUMBERS() { return NativeInvoke::Invoke<Any>(0x23EFF6DA); }
	static Any DISPLAY_TEXT_WITH_NUMBER() { return NativeInvoke::Invoke<Any>(0xECE5A56D); }
	static Any DISPLAY_TEXT_WITH_STRING() { return NativeInvoke::Invoke<Any>(0xB6BA7A8A); }
	static Any DISPLAY_TEXT_WITH_TWO_LITERAL_STRINGS() { return NativeInvoke::Invoke<Any>(0x4DA9DF6); }
	static Any DISPLAY_TEXT_WITH_TWO_STRINGS() { return NativeInvoke::Invoke<Any>(0xB07C454C); }
	static Any DOES_SCENARIO_EXIST_IN_AREA() { return NativeInvoke::Invoke<Any>(0xFA7F5047); }
	static Any DOES_SPATIALDATA_COVER_POINT_EXIST(Any p0) { return NativeInvoke::Invoke<Any>(0x2AFC1D34, p0); }
	static Any DOES_WIDGET_GROUP_EXIST() { return NativeInvoke::Invoke<Any>(0x2B1D2AF9); } 
	static Any DOOR_ACTIVATE_SPATIAL_DATA() { return NativeInvoke::Invoke<Any>(0x9EC0CA1C); }
	static Any DOOR_FIND_CLOSEST(Any p0, Any p1, Any p2, Any p3) { return NativeInvoke::Invoke<Any>(0x3D92CE51, p0, p1, p2, p3); }
	static Any DOOR_FIND_CLOSEST_GET_AUTO_CLOSE() { return NativeInvoke::Invoke<Any>(0xBD2B780C); }
	static Any DOOR_FIND_CLOSEST_GET_CLOSE() { return NativeInvoke::Invoke<Any>(0x6258B9D5); }
	static Any DOOR_FIND_CLOSEST_GET_LATCH() { return NativeInvoke::Invoke<Any>(0xE7771339); }
	static Any DOOR_FIND_CLOSEST_GET_LIMIT_MAX() { return NativeInvoke::Invoke<Any>(0x3CBDA1D0); }
	static Any DOOR_FIND_CLOSEST_GET_LIMIT_MIN() { return NativeInvoke::Invoke<Any>(0xF54D9BF1); }
	static Any DOOR_FIND_CLOSEST_SET_LIMIT() { return NativeInvoke::Invoke<Any>(0x335910F4); }
	static Any DOOR_GET_AUTO_CLOSE() { return NativeInvoke::Invoke<Any>(0x92765D98); }
	static Any DOOR_GET_CLOSE() { return NativeInvoke::Invoke<Any>(0x3C4E25B7); }
	static Any DOOR_GET_IS_AFFECTED_BY_BULLETS(Any p0) { return NativeInvoke::Invoke<Any>(0x7EE155C5, p0); }
	static Any DOOR_GET_LATCH() { return NativeInvoke::Invoke<Any>(0x2395F97B); }
	static Any DOOR_GET_LIMIT_MAX() { return NativeInvoke::Invoke<Any>(0xABF225B6); }
	static Any DOOR_GET_LIMIT_MIN() { return NativeInvoke::Invoke<Any>(0x6B267A5); }
	static Any DOOR_SET_AUTO_CLOSE() { return NativeInvoke::Invoke<Any>(0x2110CDEF); }
	static Any DOOR_SET_CLOSE() { return NativeInvoke::Invoke<Any>(0x8FB665F4); }
	static Any DOOR_SET_LATCH() { return NativeInvoke::Invoke<Any>(0x14F0F123); }
	static Any DOOR_SET_LIMIT() { return NativeInvoke::Invoke<Any>(0xB0F0CB71); }
	static Any DOOR_SET_LIMIT_MAX() { return NativeInvoke::Invoke<Any>(0xC14B5D0D); }
	static Any DOOR_SET_LIMIT_MIN() { return NativeInvoke::Invoke<Any>(0xEB21CBB9); }
	static Any DRAW_CHECKPOINT() { return NativeInvoke::Invoke<Any>(0x1B58B5C7); }
	static Any DRAW_CHECKPOINT_WITH_ALPHA() { return NativeInvoke::Invoke<Any>(0xCDC4B816); }
	static Any DRAW_DEBUG_BOX() { return NativeInvoke::Invoke<Any>(0x8524A848); }
	static Any DRAW_DEBUG_CROSS() { return NativeInvoke::Invoke<Any>(0xB6DF3709); }
	static Any DRAW_DEBUG_LINE_2D() { return NativeInvoke::Invoke<Any>(0x1C15B9B6); }
	static Any DRAW_DEBUG_LINE_2D_WITH_TWO_COLOURS() { return NativeInvoke::Invoke<Any>(0x1D4DFE1E); }
	static Any DRAW_DEBUG_LINE_WITH_TWO_COLOURS() { return NativeInvoke::Invoke<Any>(0xE8BFF632); }
	static Any DRAW_DEBUG_POLY_2D() { return NativeInvoke::Invoke<Any>(0x510260D0); }
	static Any DRAW_DEBUG_POLY_2D_WITH_THREE_COLOURS() { return NativeInvoke::Invoke<Any>(0x298064B4); }
	static Any DRAW_DEBUG_POLY_WITH_THREE_COLOURS() { return NativeInvoke::Invoke<Any>(0xDB93013); }
	static Any DRAW_DEBUG_TEXT_2D() { return NativeInvoke::Invoke<Any>(0x528B973B); }
	static Any DRAW_DEBUG_TEXT_WITH_OFFSET() { return NativeInvoke::Invoke<Any>(0xAF5808B4); }
	static Any DRAW_LINE() { return NativeInvoke::Invoke<Any>(0xB3426BCC); }
	static Any DRAW_SPHERE() { return NativeInvoke::Invoke<Any>(0x4DD1CB3A); }
	static Any DRAW_VECTOR_MAP_CIRCLE() { return NativeInvoke::Invoke<Any>(0x4B0C1539); }
	static Any DRAW_VECTOR_MAP_EVENT_RIPPLE() { return NativeInvoke::Invoke<Any>(0x3D542EE7); }
	static Any DRAW_VECTOR_MAP_LINE() { return NativeInvoke::Invoke<Any>(0x50D36E09); }
	static Any DRAW_VECTOR_MAP_LINE_THICK() { return NativeInvoke::Invoke<Any>(0x86018420); }
	static Any DRAW_VECTOR_MAP_LOCAL_PLAYER_CAM() { return NativeInvoke::Invoke<Any>(0xB8641116); }
	static Any DRAW_VECTOR_MAP_MARKER() { return NativeInvoke::Invoke<Any>(0x4A1EE5A8); }
	static Any DRAW_VECTOR_MAP_PED() { return NativeInvoke::Invoke<Any>(0x9A1D0BA2); }
	static Any DRAW_VECTOR_MAP_POLY() { return NativeInvoke::Invoke<Any>(0x53A77F35); }
	static Any DRAW_VECTOR_MAP_RECTANGLE() { return NativeInvoke::Invoke<Any>(0x2D241271); }
	static Any DRAW_VECTOR_MAP_TEXT() { return NativeInvoke::Invoke<Any>(0x7F083534); }
	static Any DRAW_VECTOR_MAP_VEHICLE() { return NativeInvoke::Invoke<Any>(0x3B0965C); }
	static Any DRAW_VECTOR_MAP_WEDGE() { return NativeInvoke::Invoke<Any>(0x2206BE27); }
	static Any GAMEPLAY_HELPER_BOX_ANGLED_CREATE_VER2() { return NativeInvoke::Invoke<Any>(0x8E89F378); }
	static Any GAMEPLAY_HELPER_VOLUME_SET_ENABLED() { return NativeInvoke::Invoke<Any>(0xEAA23DE7); }
	static Any GET_BULLET_CAMERA_MARKER(Any p0) { return NativeInvoke::Invoke<Any>(0xFE343BB0, p0); }
	static Any GET_BULLET_CAMERA_SCENE_START(Any p0) { return NativeInvoke::Invoke<Any>(0xF7334085, p0); }
	static Any GET_BULLET_CAM_PREF(Ped ped, int32_t index) { return NativeInvoke::Invoke<Any>(0xCA8E8FCC, ped, index); }
	static Any GET_CHECK_HASH_FROM_CONVERSATION_ID(Any p0) { return NativeInvoke::Invoke<Any>(0x312BFBAB, p0); }
	static Any GET_CURRENT_CONTROL_CONFIG() { return NativeInvoke::Invoke<Any>(0xA9B6DA66); }
	static Any GET_CURRENT_SCRIPTED_CONVERSATION_LINE() { return NativeInvoke::Invoke<Any>(0x9620E41F); } 
	static Any GET_GAMEPLAY_HELPER_CYLINDER_HEIGHT() { return NativeInvoke::Invoke<Any>(0xB5BE0139); }
	static Any GET_GAMEPLAY_HELPER_CYLINDER_RADIUS() { return NativeInvoke::Invoke<Any>(0x2F97E6C0); }
	static Any GET_GAME_TEXTURE_DICT(const char* dictName) { return NativeInvoke::Invoke<Any>(0x682D7B70, dictName); }
	static Any GET_HELP_MESSAGE_BOX_SIZE() { return NativeInvoke::Invoke<Any>(0x3F552D6C); }
	static Any GET_ICON_TEXTURE_DICTIONARY_FOR_BG_SCRIPT(Any p0) { return NativeInvoke::Invoke<Any>(0x424BE196, p0); }
	static Any GET_ICON_TEXTURE_FOR_BG_SCRIPT(Any p0) { return NativeInvoke::Invoke<Any>(0x4FB44F82, p0); }
	static Any GET_INTERACTION_VOLUME_POS(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0xAE7B9E7D, p0, p1); }
	static Any GET_INTERIOR_HEADING() { return NativeInvoke::Invoke<Any>(0xFB56D1AC); }
	static Any GET_LAST_SHOT_BY_PLAYER(Any p0) { return NativeInvoke::Invoke<Any>(0x9D48CB92, p0); }
	static Any GET_LAST_SHOT_TO_PLAYER(Any p0) { return NativeInvoke::Invoke<Any>(0x1279C3D4, p0); }
	static Any GET_MOTION_CONTROL_PREFERENCE() { return NativeInvoke::Invoke<Any>(0xA4CA9C1C); }
	static Any GET_NETWORK_RESTART_NODE_DEBUG() { return NativeInvoke::Invoke<Any>(0x9B999753); } 
	static Any GET_NUMBER_LINES_WITH_SUBSTRINGS() { return NativeInvoke::Invoke<Any>(0xD172184D); }
	static Any GET_NUMBER_OF_PICKUPS_AND_PLACEMENTS_OF_TYPE() { return NativeInvoke::Invoke<Any>(0x22DEA3F4); }
	static Any GET_OBJECT_ANIM_CURRENT_TIME(Any p0, Any p1, Any p2) { return NativeInvoke::Invoke<Any>(0x39F0D010, p0, p1, p2); }
	static Any GET_OFFSET_FROM_INTERIOR_IN_WORLD_COORDS() { return NativeInvoke::Invoke<Any>(0x7D8F26A1); }
	static Any GET_PICKUP_AMMO() { return NativeInvoke::Invoke<Any>(0x8B9EE98B); }
	static Any GET_PICKUP_LASER_SIGHT_ATTACHMENT() { return NativeInvoke::Invoke<Any>(0x5B17CB61); }
	static Any GET_PICKUP_TYPE_FROM_WEAPON_TYPE(Any p0) { return NativeInvoke::Invoke<Any>(0x3F2D18CE, p0); }
	static Any GET_PREVIOUS_FONT_SETTINGS() { return NativeInvoke::Invoke<Any>(0xA6BC3F4F); }
	static Any GET_RECENT_WEAPON_LEVEL_UP() { return NativeInvoke::Invoke<Any>(0x304C0CF0); }
	static Any GET_ROOM_AT_COORDS(float x, float y, float z) { return NativeInvoke::Invoke<Any>(0xAE7AA07B, x, y, z); }
	static Any GET_ROOM_KEY_FROM_OBJECT(Object object) { return NativeInvoke::Invoke<Any>(0xFC452887, object); }
	static Any GET_ROOM_KEY_FROM_PLACEMENT() { return NativeInvoke::Invoke<Any>(0x3B9A0C3D); }
	static Any GET_SAFE_PLACEMENT_COORDS() { return NativeInvoke::Invoke<Any>(0x5491A6F9); }
	static Any GET_SCRIPT_STREAM_STATE(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0xE2F9A12A, p0, p1); }
	static Any GET_SPEECH_FOR_EMERGENCY_SERVICE_CALL() { return NativeInvoke::Invoke<Any>(0xEDE519D6); } 
	static Any GET_TEXTURE(Any dict, const char* textureName) { return NativeInvoke::Invoke<Any>(0x6DC9C895, dict, textureName); }
	static Any GET_TEXTURE_FROM_STREAMED_TEXTURE_DICT(const char* dictName, const char* textureName) { return NativeInvoke::Invoke<Any>(0xA8DAC5EC, dictName, textureName); }
	static Any GET_UI_DESCRIPTION_FOR_BG_SCRIPT(Any p0) { return NativeInvoke::Invoke<Any>(0xDAFCCF7F, p0); }
	static Any GET_UI_NAME_FOR_BG_SCRIPT(Any p0) { return NativeInvoke::Invoke<Any>(0x6873C76D, p0); }
	static Any GET_VEHICLE_DOOR_ANGLE_RATIO(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0xE399C26, p0, p1); }
	static Any GIVE_PED_FAKE_NETWORK_NAME() { return NativeInvoke::Invoke<Any>(0xBA223E7B); }
	static Any HUD_SCOREBOARD_GETPLAYERPOSITION(Any p0) { return NativeInvoke::Invoke<Any>(0x581C7D26, p0); }
	static Any HUD_SCOREBOARD_RESETALLPLAYERXP() { return NativeInvoke::Invoke<Any>(0x98AF4AB7); }
	static Any HUD_SCOREBOARD_RESETPLAYERXP() { return NativeInvoke::Invoke<Any>(0xC5437B8F); }
	static Any HUD_SCOREBOARD_SETPLAYERVALUES_XP2() { return NativeInvoke::Invoke<Any>(0x320884BF); }
	static Any HUD_SCOREBOARD_SETPROGRESS() { return NativeInvoke::Invoke<Any>(0xA6F24CFB); }
	static Any IS_ANYONE_INTERACTING_WITH_VOLUME(Any p0) { return NativeInvoke::Invoke<Any>(0x461C258F, p0); }
	static Any IS_BULLET_IN_AREA() { return NativeInvoke::Invoke<Any>(0xB54F46CA); }
	static Any IS_BULLET_IN_BOX() { return NativeInvoke::Invoke<Any>(0xAB73ED26); }
	static Any IS_CLOSEST_OBJECT_OF_TYPE_SMASHED_OR_DAMAGED() { return NativeInvoke::Invoke<Any>(0x7E3857CE); }
	static Any IS_GLASS_BROKEN_IN_RADIUS() { return NativeInvoke::Invoke<Any>(0x42A3F611); }
	static Any IS_GLASS_BROKEN_ON_OBJECT() { return NativeInvoke::Invoke<Any>(0xDAEAC978); }
	static Any IS_HELP_MESSAGE_BEING_DISPLAYED() { return NativeInvoke::Invoke<Any>(0xA65F262A); }
	static Any IS_LOCAL_PLAYER_READY_TO_INTERACT_WITH(Any p0) { return NativeInvoke::Invoke<Any>(0x303F8C07, p0); }
	static Any IS_PICKUP_ATTACHMENT_ENABLED() { return NativeInvoke::Invoke<Any>(0x565F0B42); }
	static Any IS_PICKUP_ATTACHMENT_TOGGLED() { return NativeInvoke::Invoke<Any>(0x89F779D5); }
	static Any IS_PLAYER_INTERACTING_WITH_VOLUME(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0x424D60A3, p0, p1); }
	static Any IS_PLAYER_WANTED_LEVEL_GREATER() { return NativeInvoke::Invoke<Any>(0x589A2661); }
	static Any IS_PROJECTILE_IN_AREA() { return NativeInvoke::Invoke<Any>(0x78E1A557); }
	static Any IS_PROJECTILE_TYPE_IN_AREA() { return NativeInvoke::Invoke<Any>(0x2B73BCF6); }
	static Any IS_SCRIPTED_CONVERSATION_ONGOING(Any p0) { return NativeInvoke::Invoke<Any>(0xCB8FD96F, p0); }
	static Any IS_SNIPER_BULLET_IN_AREA() { return NativeInvoke::Invoke<Any>(0x483715C); }
	static Any IS_THIS_HELP_MESSAGE_BEING_DISPLAYED() { return NativeInvoke::Invoke<Any>(0x792ECC8C); }
	static Any IS_THIS_HELP_MESSAGE_WITH_NUMBER_BEING_DISPLAYED() { return NativeInvoke::Invoke<Any>(0x7303D366); }
	static Any IS_THIS_HELP_MESSAGE_WITH_STRING_BEING_DISPLAYED() { return NativeInvoke::Invoke<Any>(0x8FDB39D4); }
	static Any IS_THIS_PRINT_BEING_DISPLAYED() { return NativeInvoke::Invoke<Any>(0xED8E2421); }
	static Any LAST_MAN_STANDING_REVIVE() { return NativeInvoke::Invoke<Any>(0x21192AE3); }
	static Any LEADERBOARDS_GET_COLUMN_ID() { return NativeInvoke::Invoke<Any>(0x3821A334); }
	static Any LEADERBOARDS_GET_NUMBER_OF_COLUMNS(Any p0) { return NativeInvoke::Invoke<Any>(0xA56EE34, p0); }
	static Any LEADERBOARDS_READ_BY_COMMUNITY(Any p0) { return NativeInvoke::Invoke<Any>(0x5023C8AB, p0); }
	static Any LEADERBOARDS_READ_BY_GAMER() { return NativeInvoke::Invoke<Any>(0x37338B11); }
	static Any LEADERBOARDS_READ_BY_RADIUS_EX() { return NativeInvoke::Invoke<Any>(0xCD659683); }
	static Any LEADERBOARDS_READ_BY_RANK_EX(Any p0, Any p1, Any p2, Any p3, Any p4) { return NativeInvoke::Invoke<Any>(0xB5F57E71, p0, p1, p2, p3, p4); }
	static Any LEADERBOARDS_READ_FINISHED_AND_SUCCEEDED(Any p0) { return NativeInvoke::Invoke<Any>(0x556A674E, p0); }
	static Any LEADERBOARDS_READ_FOR_LOCAL_GAMER_EX(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0xF872E9F6, p0, p1); }
	static Any LEADERBOARDS_READ_GET_NUM_ROWS_EX() { return NativeInvoke::Invoke<Any>(0xE60FFF5C); }
	static Any LEADERBOARDS_READ_GET_ROW_DATA_EX(Any p0, Any p1, Any p2, Any p3) { return NativeInvoke::Invoke<Any>(0x8B4ABFF9, p0, p1, p2, p3); }
	static Any LEADERBOARDS_READ_GET_ROW_DATA_FOR_LOCAL_GAMER_EX(Any p0, Any p1, Any p2) { return NativeInvoke::Invoke<Any>(0x680D09F3, p0, p1, p2); }
	static Any LEADERBOARDS_READ_PENDING(Any p0) { return NativeInvoke::Invoke<Any>(0xEEB8BF5C, p0); }
	static Any LEADERBOARDS_WRITE_FLUSH() { return NativeInvoke::Invoke<Any>(0x7579C0B4); }
	static Any LEADERBOARDS_WRITE_GROUP_DATA(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0xB7CBBFC1, p0, p1); }
	static Any LEADERBOARDS_WRITE_PLAYER_DATA(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0xFF8BA326, p0, p1); }
	static Any LEADERBOARDS_WRITE__ROS__PLAYER_DATA(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0x2A12675D, p0, p1); }
	static Any LOAD_BULLET_CAM_BANK() { return NativeInvoke::Invoke<Any>(0xCE805879); } 
	static Any LOAD_PED_DECISION_MAKER() { return NativeInvoke::Invoke<Any>(0xCEA92F74); }
	static Any LOAD_SCRIPT_STREAM(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0xB99CBFB5, p0, p1); }
	static Any LOAD_TEXTURE_DICT(const char* dictName) { return NativeInvoke::Invoke<Any>(0xAD3C963A, dictName); }
	static Any LOAD_TEXT_FONT() { return NativeInvoke::Invoke<Any>(0x9A4F5026); }
	static Any NETWORK_CHANGE_GAME_MODE_PENDING() { return NativeInvoke::Invoke<Any>(0x8226F769); }
	static Any NETWORK_CHANGE_GAME_MODE_SUCCEEDED() { return NativeInvoke::Invoke<Any>(0xFBA800BC); }
	static Any NETWORK_CHECK_INVITE_ARRIVAL() { return NativeInvoke::Invoke<Any>(0x686548FD); }
	static Any NETWORK_CLEAR_INVITE_ARRIVAL() { return NativeInvoke::Invoke<Any>(0xCE1CB74); }
	static Any NETWORK_GET_COUNTOF_RICH_PRESENCE() { return NativeInvoke::Invoke<Any>(0x1CE03E7B); }
	static Any NETWORK_GET_NUM_UNACCEPTED_INVITES() { return NativeInvoke::Invoke<Any>(0xE691321E); }
	static Any NETWORK_GET_PLAYER_STREAK_BLOCKED(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0x3663B7E0, p0, p1); }
	static Any NETWORK_GET_PLAYER_STREAK_EFFECT(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0x9E7A0C00, p0, p1); }
	static Any NETWORK_GET_PLAYER_STREAK_IN_SLOT(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0x3201F4A2, p0, p1); }
	static Any NETWORK_GET_RICH_PRESENCE_FIELD_INDEX() { return NativeInvoke::Invoke<Any>(0x3D42FEC4); }
	static Any NETWORK_GET_RICH_PRESENCE_ID() { return NativeInvoke::Invoke<Any>(0x661455A9); }
	static Any NETWORK_GET_RICH_PRESENCE_ID_FROM_INDEX() { return NativeInvoke::Invoke<Any>(0x4F08B53D); }
	static Any NETWORK_GET_RICH_PRESENCE_IS_VALID() { return NativeInvoke::Invoke<Any>(0xD47D4C49); }
	static Any NETWORK_GET_RICH_PRESENCE_LABEL() { return NativeInvoke::Invoke<Any>(0x2BF438BF); }
	static Any NETWORK_GET_STREAK_TEXTURE(Any p0) { return NativeInvoke::Invoke<Any>(0x277FB8F, p0); }
	static Any NETWORK_GET_UNACCEPTED_INVITER_NAME() { return NativeInvoke::Invoke<Any>(0x34A7E847); }
	static Any NETWORK_GET_UNACCEPTED_INVITE_GAME_MODE() { return NativeInvoke::Invoke<Any>(0xF66BCD00); }
	static Any NETWORK_KICK_PLAYER() { return NativeInvoke::Invoke<Any>(0x7EDD6266); }
	static Any NETWORK_LEVEL_DATA_GET_FLOAT() { return NativeInvoke::Invoke<Any>(0x4EF6A91C); }
	static Any NETWORK_LEVEL_DATA_GET_FLOAT_FROM_NODE(Any p0, Any p1, Any p2) { return NativeInvoke::Invoke<Any>(0xCA92A56, p0, p1, p2); }
	static Any NETWORK_LEVEL_DATA_GET_HASH() { return NativeInvoke::Invoke<Any>(0x758DEB4D); }
	static Any NETWORK_LEVEL_DATA_GET_HASH_FROM_NODE(Any p0, Any p1, Any p2) { return NativeInvoke::Invoke<Any>(0xA0DF848C, p0, p1, p2); }
	static Any NETWORK_LEVEL_DATA_GET_INT() { return NativeInvoke::Invoke<Any>(0x5D7A7AD); }
	static Any NETWORK_LEVEL_DATA_GET_INT_FROM_NODE(Any p0, Any p1, Any p2) { return NativeInvoke::Invoke<Any>(0xEDA5D3AA, p0, p1, p2); }
	static Any NETWORK_LEVEL_DATA_GET_NODE() { return NativeInvoke::Invoke<Any>(0x1D710204); }
	static Any NETWORK_LEVEL_DATA_GET_NODE_FROM_NODE(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0x78598AC7, p0, p1); }
	static Any NETWORK_LEVEL_DATA_GET_NUM_NODES_FROM_NODE(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0xC208F633, p0, p1); }
	static Any NETWORK_LEVEL_DATA_GET_SIBLING_COUNT_AFTER_NODE(Any p0) { return NativeInvoke::Invoke<Any>(0xD8F9D0B0, p0); }
	static Any NETWORK_LEVEL_DATA_GET_STRING() { return NativeInvoke::Invoke<Any>(0xCF99AF2B); }
	static Any NETWORK_LEVEL_DATA_GET_STRING_FROM_NODE(Any p0, Any p1, Any p2, Any p3) { return NativeInvoke::Invoke<Any>(0x1AB1ED65, p0, p1, p2, p3); }
	static Any NETWORK_LEVEL_DATA_GET_VECTOR() { return NativeInvoke::Invoke<Any>(0x532EBA1B); }
	static Any NETWORK_LEVEL_DATA_GET_VECTOR_FROM_NODE(Any p0, Any p1, Any p2) { return NativeInvoke::Invoke<Any>(0x9209CE38, p0, p1, p2); }
	static Any NETWORK_LEVEL_DATA_GET_bool() { return NativeInvoke::Invoke<Any>(0x282E20CB); }
	static Any NETWORK_LEVEL_DATA_GET_bool_FROM_NODE(Any p0, Any p1, Any p2) { return NativeInvoke::Invoke<Any>(0xC5F02A7E, p0, p1, p2); }
	static Any NETWORK_LEVEL_DATA_RUN_STORED_QUERY_COUNT(Any p0, Any p1, Any p2, Any p3) { return NativeInvoke::Invoke<Any>(0x7F3DAF76, p0, p1, p2, p3); }
	static Any NETWORK_LEVEL_DATA_RUN_STORED_QUERY_FLOAT() { return NativeInvoke::Invoke<Any>(0x7CBE1FD2); }
	static Any NETWORK_LEVEL_DATA_RUN_STORED_QUERY_HASH(Any p0, Any p1, Any p2, Any p3, Any p4) { return NativeInvoke::Invoke<Any>(0x776215C9, p0, p1, p2, p3, p4); }
	static Any NETWORK_LEVEL_DATA_RUN_STORED_QUERY_INT(Any p0, Any p1, Any p2, Any p3, Any p4) { return NativeInvoke::Invoke<Any>(0x4DAE6959, p0, p1, p2, p3, p4); }
	static Any NETWORK_LEVEL_DATA_RUN_STORED_QUERY_NODE(Any p0, Any p1, Any p2, Any p3) { return NativeInvoke::Invoke<Any>(0xEE658568, p0, p1, p2, p3); }
	static Any NETWORK_LEVEL_DATA_RUN_STORED_QUERY_STRING(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5) { return NativeInvoke::Invoke<Any>(0x9DF1E416, p0, p1, p2, p3, p4, p5); }
	static Any NETWORK_LEVEL_DATA_RUN_STORED_QUERY_VECTOR() { return NativeInvoke::Invoke<Any>(0xAC9F6193); }
	static Any NETWORK_LEVEL_DATA_RUN_STORED_QUERY_bool() { return NativeInvoke::Invoke<Any>(0x8DB64921); }
	static Any NETWORK_SET_FRIENDLY_FIRE_OPTION() { return NativeInvoke::Invoke<Any>(0x6BAF95FA); }
	static Any NETWORK_SET_PROFILESTATINTERVAL() { return NativeInvoke::Invoke<Any>(0x863D8EE5); }
	static Any NETWORK_SET_RADIOHUD_IN_LOBBY_OFF() { return NativeInvoke::Invoke<Any>(0x4FDBF664); }
	static Any NETWORK_SET_RICH_PRESENCE() { return NativeInvoke::Invoke<Any>(0x932A6CED); }
	static Any OBJECT_ANIM_EVENT() { return NativeInvoke::Invoke<Any>(0x105F06CB); }
	static Any OBJECT_ANIM_EVENT_OLD() { return NativeInvoke::Invoke<Any>(0xBF0BC0D); }
	static Any OPEN_DEBUG_FILE() { return NativeInvoke::Invoke<Any>(0xA754055A); } 
	static Any OPEN_NAMED_DEBUG_FILE() { return NativeInvoke::Invoke<Any>(0xE817E336); } 
	static Any PAUSE_SCRIPTED_CONVERSATION() { return NativeInvoke::Invoke<Any>(0xE2C9C6F8); } 
	static Any PEDGROUPTASK_ADVANCE_CREATE(Any p0) { return NativeInvoke::Invoke<Any>(0x54436897, p0); }
	static Any PEDGROUPTASK_ADVANCE_SETCOVERSEARCHOFFSETFORWARD() { return NativeInvoke::Invoke<Any>(0x82FE5DEA); }
	static Any PEDGROUPTASK_ADVANCE_SETTARGET_POS() { return NativeInvoke::Invoke<Any>(0x97D7FBD1); }
	static Any PEDGROUPTASK_COVERFIRE_ASSIGNPED() { return NativeInvoke::Invoke<Any>(0x9F362EA8); }
	static Any PEDGROUPTASK_COVERFIRE_CREATE() { return NativeInvoke::Invoke<Any>(0xB12779C8); }
	static Any PEDGROUPTASK_COVERFIRE_SETTARGET_PED() { return NativeInvoke::Invoke<Any>(0x131D9EE9); }
	static Any PEDGROUPTASK_COVERFIRE_SETTARGET_POS() { return NativeInvoke::Invoke<Any>(0xBF55758E); }
	static Any PEDGROUPTASK_COVERFIRE_STOP_FIRING() { return NativeInvoke::Invoke<Any>(0x935C7975); }
	static Any PEDGROUPTASK_COVERFIRE_TRIGGER_FIRE() { return NativeInvoke::Invoke<Any>(0xA546FB73); }
	static Any PEDGROUPTASK_COVERFIRE_TRIGGER_HIDE() { return NativeInvoke::Invoke<Any>(0xCAC7EFC1); }
	static Any PEDGROUPTASK_FLANK_ASSIGNPEDTOCOVERFIRE() { return NativeInvoke::Invoke<Any>(0xFAD36337); }
	static Any PEDGROUPTASK_FLANK_ASSIGNPEDTOFLANK() { return NativeInvoke::Invoke<Any>(0x8370A7AC); }
	static Any PEDGROUPTASK_FLANK_CREATE() { return NativeInvoke::Invoke<Any>(0x8A7938A8); }
	static Any PEDGROUPTASK_FLANK_FLANKVOLUME() { return NativeInvoke::Invoke<Any>(0x6262EDA); }
	static Any PEDGROUPTASK_FLANK_TRIGGERVOLUME() { return NativeInvoke::Invoke<Any>(0xB5D4C0FE); }
	static Any PEDGROUPTASK_FLANK_TUNE_TARGETOUTSIDETRIGGERVOLUMETOCANCEL() { return NativeInvoke::Invoke<Any>(0xDBFC2F3); }
	static Any PEDGROUPTASK_FLANK_TUNE_TIMEREADYTRIGGERMOVE() { return NativeInvoke::Invoke<Any>(0x70DCAB00); }
	static Any PEDGROUPTASK_FLANK_TUNE_TIMETARGETINSIDETRIGGERVOLUMETOSTART() { return NativeInvoke::Invoke<Any>(0x4D888CFB); }
	static Any PEDGROUPTASK_TACTICALCORNER_CREATE(Any p0, Any p1, Any p2) { return NativeInvoke::Invoke<Any>(0x165687CB, p0, p1, p2); }
	static Any PEDGROUPTASK_TACTICALCORNER_SETTARGET_POS() { return NativeInvoke::Invoke<Any>(0xB54BDB46); }
	static Any PICKUPS_PASS_TIME() { return NativeInvoke::Invoke<Any>(0xA629E201); }
	static Any PLAYER_USE_COVERLINE() { return NativeInvoke::Invoke<Any>(0x04C99D6); }
	static Any PLAYER_USE_COVERPOINT(Any p0, Any p1, Any p2, Any p3) { return NativeInvoke::Invoke<Any>(0x822F99DE, p0, p1, p2, p3); }
	static Any PLAY_AUDIO_EVENT() { return NativeInvoke::Invoke<Any>(0x4B31CE89); } 
	static Any PLAY_AUDIO_EVENT_FROM_VEHICLE() { return NativeInvoke::Invoke<Any>(0xB7DC5C8); } 
	static Any PRINT_HELP_FOREVER() { return NativeInvoke::Invoke<Any>(0xB7AC63C3); }
	static Any PRINT_HELP_FOREVER_WITH_NUMBER() { return NativeInvoke::Invoke<Any>(0xADE2E873); }
	static Any PRINT_HELP_FOREVER_WITH_STRING() { return NativeInvoke::Invoke<Any>(0xDB159D05); }
	static Any PRINT_HELP_FOREVER_WITH_STRING_NO_SOUND() { return NativeInvoke::Invoke<Any>(0x63049363); }
	static Any PRINT_HELP_WITH_NUMBER() { return NativeInvoke::Invoke<Any>(0x215A5FCC); }
	static Any PRINT_HELP_WITH_STRING_NO_SOUND() { return NativeInvoke::Invoke<Any>(0x89A0FF88); }
	static Any PRINT_MISSION_DESCRIPTION() { return NativeInvoke::Invoke<Any>(0x61668A58); } 
	static Any PRINT_STRING_IN_STRING() { return NativeInvoke::Invoke<Any>(0x31026991); }
	static Any PRINT_STRING_IN_STRING_NOW() { return NativeInvoke::Invoke<Any>(0x610BDA9E); }
	static Any PRINT_WITH_2_NUMBERS() { return NativeInvoke::Invoke<Any>(0x1D5F8E7A); }
	static Any PRINT_WITH_2_NUMBERS_NOW() { return NativeInvoke::Invoke<Any>(0x4F62BE65); }
	static Any PRINT_WITH_NUMBER() { return NativeInvoke::Invoke<Any>(0x9FBDDD94); }
	static Any PRINT_WITH_NUMBER_NOW() { return NativeInvoke::Invoke<Any>(0x7FFF2957); }
	static Any PRIVATE_SKIP_TO_NEXT_SCRIPTED_CONVERSATION_LINE() { return NativeInvoke::Invoke<Any>(0xB528AEA6); } 
	static Any PROFILER_DUMP_VALUES() { return NativeInvoke::Invoke<Any>(0x604930BC); }
	static Any QUERY_MONITORED_STAT_ENTRY(int32_t p0, int32_t p1) { return NativeInvoke::Invoke<Any>(0xA18210A2, p0, p1); }
	static Any REGISTER_INJURY() { return NativeInvoke::Invoke<Any>(0x33B0E8E6); }
	static Any RELEASE_STREAMING_MEMORY() { return NativeInvoke::Invoke<Any>(0x53CB7864); }
	static Any REMOVE_ALL_COVER_BLOCKING_AREAS() { return NativeInvoke::Invoke<Any>(0xCF9221A7); }
	static Any REMOVE_PED_IGNORE_COVER_ENTRY() { return NativeInvoke::Invoke<Any>(0xC5D2232C); }
	static Any REMOVE_PED_USE_COVER_ENTRY() { return NativeInvoke::Invoke<Any>(0xADE53B26); }
	static Any REMOVE_PLAYER_HELMET() { return NativeInvoke::Invoke<Any>(0x6255F3B4); }
	static Any REMOVE_WIND_THERMAL() { return NativeInvoke::Invoke<Any>(0xD1B522B6); }
	static Any REQUEST_SCRIPT_STREAM(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0xD5782CC7, p0, p1); }
	static Any RESERVE_STREAMING_MEMORY() { return NativeInvoke::Invoke<Any>(0xACD474EB); }
	static Any RESET_BULLET_CAMERA_TIMEWARP_SCALE() { return NativeInvoke::Invoke<Any>(0x69EE7ED4); } 
	static Any RESET_PAYNEKILLER_RECHARGE_RATE() { return NativeInvoke::Invoke<Any>(0x89413073); }
	static Any RESTORE_SCRIPT_ARRAY_FROM_SCRATCHPAD() { return NativeInvoke::Invoke<Any>(0x5AB30FE1); }
	static Any SAVE_FLOAT_TO_DEBUG_FILE() { return NativeInvoke::Invoke<Any>(0xAE315350); } 
	static Any SAVE_FLOAT_TO_NAMED_DEBUG_FILE() { return NativeInvoke::Invoke<Any>(0x72E3DA94); } 
	static Any SAVE_INT_TO_DEBUG_FILE() { return NativeInvoke::Invoke<Any>(0x13F0037D); } 
	static Any SAVE_INT_TO_NAMED_DEBUG_FILE() { return NativeInvoke::Invoke<Any>(0xC59156BD); } 
	static Any SAVE_NEWLINE_TO_DEBUG_FILE() { return NativeInvoke::Invoke<Any>(0x36383B18); } 
	static Any SAVE_NEWLINE_TO_NAMED_DEBUG_FILE() { return NativeInvoke::Invoke<Any>(0xC41A4082); } 
	static Any SAVE_SCRIPT_ARRAY_IN_SCRATCHPAD() { return NativeInvoke::Invoke<Any>(0x8A3A3C98); }
	static Any SAVE_STRING_TO_DEBUG_FILE() { return NativeInvoke::Invoke<Any>(0x1BC43E17); } 
	static Any SAVE_STRING_TO_NAMED_DEBUG_FILE() { return NativeInvoke::Invoke<Any>(0xD7B91218); } 
	static Any SCRIPT_VAR_HASH_WAIT_FOR_CHANGE_FLOAT() { return NativeInvoke::Invoke<Any>(0xEC96E1B4); }
	static Any SCRIPT_VAR_HASH_WAIT_FOR_CHANGE_INT() { return NativeInvoke::Invoke<Any>(0xFF735813); }
	static Any SCRIPT_VAR_WAIT_FOR_CHANGE_FLOAT() { return NativeInvoke::Invoke<Any>(0xB4123E01); }
	static Any SCRIPT_VAR_WAIT_FOR_CHANGE_INT() { return NativeInvoke::Invoke<Any>(0x2A05F0E3); }
	static Any SETUP_BULLET_CAMERA_SCENE(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9, Any p10, Any p11, Any p12, Any p13, Any p14, Any p15, Any p16, Any p17, Any p18, Any p19, Any p20, Any p21) { return NativeInvoke::Invoke<Any>(0x536FD4DA, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21); }
	static Any SET_ALL_MOTION_CONTROL_PREFERENCES() { return NativeInvoke::Invoke<Any>(0x94FF7903); }
	static Any SET_BLIP_ROUTE() { return NativeInvoke::Invoke<Any>(0x3E160C90); }
	static Any SET_BULLET_CAMERA_OBJECT_TRACKER() { return NativeInvoke::Invoke<Any>(0x4E75A262); } 
	static Any SET_BULLET_CAMERA_TRACKED_PED() { return NativeInvoke::Invoke<Any>(0x450D1234); } 
	static Any SET_COLLISION_AUDIO_DISABLED() { return NativeInvoke::Invoke<Any>(0xB8DD4243); } 
	static Any SET_CUTSCENE_EXTRA_ROOM_POS() { return NativeInvoke::Invoke<Any>(0x6EB9A03); }
	static Any SET_DEAD_PEDS_DROP_WEAPONS() { return NativeInvoke::Invoke<Any>(0x197472B9); }
	static Any SET_DEBUG_TEXT_VISIBLE() { return NativeInvoke::Invoke<Any>(0x50017383); } 
	static Any SET_DISPATCH_COPS_FOR_PLAYER() { return NativeInvoke::Invoke<Any>(0x48A18913); }
	static Any SET_DRIVE_TASK_CRUISE_SPEED() { return NativeInvoke::Invoke<Any>(0x3CEC07B1); }
	static Any SET_GAMEPLAY_COORD_HINT() { return NativeInvoke::Invoke<Any>(0xF27483C9); } 
	static Any SET_GAMEPLAY_HELPER_CYLINDER_HEIGHT() { return NativeInvoke::Invoke<Any>(0xB6B24984); }
	static Any SET_GAMEPLAY_HELPER_CYLINDER_RADIUS() { return NativeInvoke::Invoke<Any>(0x4EBFD673); }
	static Any SET_GAMEPLAY_HINT_FOV() { return NativeInvoke::Invoke<Any>(0x96FD173B); } 
	static Any SET_GAMEPLAY_HINT_RELATIVE_PITCH() { return NativeInvoke::Invoke<Any>(0x7D04320E); } 
	static Any SET_GAMEPLAY_OBJECT_HINT() { return NativeInvoke::Invoke<Any>(0x2ED5E2F8); } 
	static Any SET_GAMEPLAY_PED_HINT() { return NativeInvoke::Invoke<Any>(0x7C27343E); } 
	static Any SET_GAMEPLAY_VEHICLE_HINT() { return NativeInvoke::Invoke<Any>(0x2C9A11D8); } 
	static Any SET_GROUP_PED_DECISION_MAKER() { return NativeInvoke::Invoke<Any>(0xD93095B3); }
	static Any SET_HELI_AUDIO_MAX_OCCLUSION() { return NativeInvoke::Invoke<Any>(0x57125C3F); } 
	static Any SET_HELP_MESSAGE_BOX_SIZE() { return NativeInvoke::Invoke<Any>(0x138D7BB9); }
	static Any SET_IN_SPECTATOR_MODE() { return NativeInvoke::Invoke<Any>(0x74DBC1BF); }
	static Any SET_LOBBY_MUTE_OVERRIDE() { return NativeInvoke::Invoke<Any>(0x35BA6682); } 
	static Any SET_MAX_AMMO_CAP() { return NativeInvoke::Invoke<Any>(0x4C898C45); }
	static Any SET_MULTIPLE_DRIVEBY_PICKUPS() { return NativeInvoke::Invoke<Any>(0xC619A53A); }
	static Any SET_NEXT_TICKER_MESSAGE_BACKGROUND_COLOR() { return NativeInvoke::Invoke<Any>(0x4BD59DD4); }
	static Any SET_OBJECT_ALPHA() { return NativeInvoke::Invoke<Any>(0x98E5B61D); }
	static Any SET_PAYNEKILLER_BOTTLE_COUNT() { return NativeInvoke::Invoke<Any>(0xF3DE9E5D); }
	static Any SET_PAYNEKILLER_RECHARGE_RATE() { return NativeInvoke::Invoke<Any>(0x54A5A6C3); }
	static Any SET_PED_ADVANCE_DELAY_OVERRIDE() { return NativeInvoke::Invoke<Any>(0xE8B068A7); }
	static Any SET_PED_ALPHA() { return NativeInvoke::Invoke<Any>(0xB94DA9B3); }
	static Any SET_PED_BLEND_FROM_NM_WITH_ANIM() { return NativeInvoke::Invoke<Any>(0x6C433786); }
	static Any SET_PED_CHARGE_DELAY_OVERRIDE() { return NativeInvoke::Invoke<Any>(0x3B2E3E6B); }
	static Any SET_PED_COVER_TARGET_PED_WITH_BONE_AND_OFFSET() { return NativeInvoke::Invoke<Any>(0x3A6625BB); }
	static Any SET_PED_COVER_TARGET_PED_WITH_OFFSET() { return NativeInvoke::Invoke<Any>(0x94B495D); }
	static Any SET_PED_DECISION_MAKER() { return NativeInvoke::Invoke<Any>(0x13A0D6D5); }
	static Any SET_PED_DECISION_MAKER_TO_DEFAULT() { return NativeInvoke::Invoke<Any>(0xDD2DEE0A); }
	static Any SET_PED_DROPS_OBJECT() { return NativeInvoke::Invoke<Any>(0x4D75C27C); }
	static Any SET_PED_FORCE_USE_MUZZLE_DIRECTION() { return NativeInvoke::Invoke<Any>(0x3D6DECE5); }
	static Any SET_PED_PINNED_DOWN(Ped ped, bool toggle, int32_t p2) { return NativeInvoke::Invoke<Any>(0xCC78999D, ped, toggle, p2); }
	static Any SET_PED_STEALTH_ATTRIBUTES() { return NativeInvoke::Invoke<Any>(0xB24394CA); }
	static Any SET_PHONE_HUD_ITEM() { return NativeInvoke::Invoke<Any>(0x7FD60931); }
	static Any SET_PICKUP_LASER_SIGHT_ATTACHMENT() { return NativeInvoke::Invoke<Any>(0xB3C7B87A); }
	static Any SET_PICKUP_LIMIT_ANGLE() { return NativeInvoke::Invoke<Any>(0x12177009); }
	static Any SET_PLAYERS_DROP_MONEY_IN_NETWORK_GAME() { return NativeInvoke::Invoke<Any>(0x806204B); }
	static Any SET_ROCKET_LAUNCHER_FREEBIE_IN_HELI() { return NativeInvoke::Invoke<Any>(0x62F3E0F3); }
	static Any SET_ROUTE_FLASHES() { return NativeInvoke::Invoke<Any>(0x93BD3E80); }
	static Any SET_TEXT_LINE_DISPLAY() { return NativeInvoke::Invoke<Any>(0x5AE8AF79); }
	static Any SET_TRAIN_AUDIO_ROLLOFF() { return NativeInvoke::Invoke<Any>(0x56F2F2E9); } 
	static Any SET_VEHICLE_ALPHA() { return NativeInvoke::Invoke<Any>(0x5D4A2BC2); }
	static Any SET_XBOX_SCREEN_SAVER() { return NativeInvoke::Invoke<Any>(0xD121D3DE); }
	static Any SEV_BINDC(Any p0, Any p1, Any p2, Any p3, Any p4) { return NativeInvoke::Invoke<Any>(0x4F8EBA7E, p0, p1, p2, p3, p4); }
	static Any SEV_CONDITION(Any p0, Any p1, Any p2) { return NativeInvoke::Invoke<Any>(0xBE758B0C, p0, p1, p2); }
	static Any SEV_CONSTRUCT_EVENT() { return NativeInvoke::Invoke<Any>(0xA9A14FD3); }
	static Any SEV_CURRENT_EVENT(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0x1D049619, p0, p1); }
	static Any SEV_GET_PLAYER_FRIENDLY_FIRE() { return NativeInvoke::Invoke<Any>(0x52A421F3); }
	static Any SEV_GET_UNIQUE_PLAYER_MODEL_VARIATION() { return NativeInvoke::Invoke<Any>(0xCD0F2DB8); }
	static Any SEV_INT_TO_WATCHER() { return NativeInvoke::Invoke<Any>(0x98A92C54); }
	static Any SEV_INVALID_EVENT_ID() { return NativeInvoke::Invoke<Any>(0xAE382401); }
	static Any SEV_IS_POINT_VISIBLE_TO_POSITION_LIST(Any p0, Any p1, Any p2, Any p3) { return NativeInvoke::Invoke<Any>(0x7C932981, p0, p1, p2, p3); }
	static Any SEV_IS_SPHERE_VISIBLE_TO_OTHER_TEAM_PLAYERS() { return NativeInvoke::Invoke<Any>(0x6A1BA8C6); }
	static Any SEV_IS_SPHERE_VISIBLE_TO_PLAYER_LIST(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9) { return NativeInvoke::Invoke<Any>(0x48990418, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9); }
	static Any SEV_MAP_PLAYER_PED(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0x2E6A11AD, p0, p1); }
	static Any SEV_OBSERVE_FLOAT(Any p0) { return NativeInvoke::Invoke<Any>(0xB8084395, p0); }
	static Any SEV_OBSERVE_INT(Any p0) { return NativeInvoke::Invoke<Any>(0x55FCE28A, p0); }
	static Any SEV_ON_ANY_PED_CREATED() { return NativeInvoke::Invoke<Any>(0x9939785A); }
	static Any SEV_ON_ANY_PED_DELETED() { return NativeInvoke::Invoke<Any>(0xE47E14C1); }
	static Any SEV_ON_ANY_PED_DIED() { return NativeInvoke::Invoke<Any>(0x87EE778); }
	static Any SEV_ON_ANY_PED_JOINED_NETGAME() { return NativeInvoke::Invoke<Any>(0x4C3C6D6); }
	static Any SEV_ON_ANY_PED_LEFT_NETGAME() { return NativeInvoke::Invoke<Any>(0xABA66068); }
	static Any SEV_ON_ANY_VEHICLE_CREATED() { return NativeInvoke::Invoke<Any>(0xBFEF843); }
	static Any SEV_ON_ANY_VEHICLE_DELETED() { return NativeInvoke::Invoke<Any>(0x8A6CCF05); }
	static Any SEV_ON_ANY_VEHICLE_DESTROYED() { return NativeInvoke::Invoke<Any>(0xB841C0D6); }
	static Any SEV_ON_HOST_STATS_TABLE_VALID() { return NativeInvoke::Invoke<Any>(0x8B7EA849); }
	static Any SEV_ON_HOST_SYNC() { return NativeInvoke::Invoke<Any>(0x3CF8A812); }
	static Any SEV_ON_MP_INTERACTION_SUCCEEDED() { return NativeInvoke::Invoke<Any>(0xFAF50A5C); }
	static Any SEV_ON_MP_ITEM_PICKUP_ACTION(Any p0) { return NativeInvoke::Invoke<Any>(0x903D285A, p0); }
	static Any SEV_ON_OBJECT_DAMAGED() { return NativeInvoke::Invoke<Any>(0x7F5E8AD6); }
	static Any SEV_ON_PED_ASSIST(Any p0) { return NativeInvoke::Invoke<Any>(0xBD0068C6, p0); }
	static Any SEV_ON_PED_CREATED() { return NativeInvoke::Invoke<Any>(0xBD305A46); }
	static Any SEV_ON_PED_DELETED(Any p0) { return NativeInvoke::Invoke<Any>(0xFA377D19, p0); }
	static Any SEV_ON_PED_DIED(Any p0) { return NativeInvoke::Invoke<Any>(0x2C21F110, p0); }
	static Any SEV_ON_PED_ENTERED_VEHICLE() { return NativeInvoke::Invoke<Any>(0x93DAACB5); }
	static Any SEV_ON_PED_INJURED(Any p0) { return NativeInvoke::Invoke<Any>(0x2F4FA7AA, p0); }
	static Any SEV_ON_PED_LEFT_VEHICLE() { return NativeInvoke::Invoke<Any>(0xA70DCA9C); }
	static Any SEV_ON_PED_LMS_ACTIVATED(Any p0) { return NativeInvoke::Invoke<Any>(0x48AFCC46, p0); }
	static Any SEV_ON_PED_LMS_DEACTIVATED(Any p0) { return NativeInvoke::Invoke<Any>(0xD198A2D, p0); }
	static Any SEV_ON_PED_LOOK_TRIGGER_END() { return NativeInvoke::Invoke<Any>(0x360B2C36); }
	static Any SEV_ON_PED_LOOK_TRIGGER_START() { return NativeInvoke::Invoke<Any>(0x91C64482); }
	static Any SEV_ON_PED_RANK_UP(Any p0) { return NativeInvoke::Invoke<Any>(0x7B6F3CA4, p0); }
	static Any SEV_ON_PED_TASK_FINISHED(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0xF50C10DC, p0, p1); }
	static Any SEV_ON_PED_TASK_STARTED() { return NativeInvoke::Invoke<Any>(0x298AEAB1); }
	static Any SEV_ON_PED_TRIGGER_ENTERED(Any p0, Any p1, Any p2) { return NativeInvoke::Invoke<Any>(0x37DF6A31, p0, p1, p2); }
	static Any SEV_ON_PED_TRIGGER_LEFT(Any p0, Any p1, Any p2) { return NativeInvoke::Invoke<Any>(0xB18C949F, p0, p1, p2); }
	static Any SEV_ON_PED_TRIGGER_LIST_ENTERED(Any p0, Any p1, Any p2, Any p3) { return NativeInvoke::Invoke<Any>(0xFCEC8FDF, p0, p1, p2, p3); }
	static Any SEV_ON_PED_TRIGGER_LIST_LEFT(Any p0, Any p1, Any p2, Any p3) { return NativeInvoke::Invoke<Any>(0xA80054BD, p0, p1, p2, p3); }
	static Any SEV_ON_PED_USE_STREAK(Any p0) { return NativeInvoke::Invoke<Any>(0x43F36B61, p0); }
	static Any SEV_ON_TIMER(Any p0) { return NativeInvoke::Invoke<Any>(0x2FFAB17, p0); }
	static Any SEV_ON_TIN_CAN_COLLISION() { return NativeInvoke::Invoke<Any>(0x9AB7A935); }
	static Any SEV_ON_VEHICLE_CREATED() { return NativeInvoke::Invoke<Any>(0xE6097F09); }
	static Any SEV_ON_VEHICLE_DAMAGED() { return NativeInvoke::Invoke<Any>(0x98A611A6); }
	static Any SEV_ON_VEHICLE_DELETED() { return NativeInvoke::Invoke<Any>(0x1E04C1A2); }
	static Any SEV_ON_VEHICLE_DESTROYED() { return NativeInvoke::Invoke<Any>(0xDAF25B5E); }
	static Any SEV_PLAYER_INDEX_TO_SLOT(Any p0) { return NativeInvoke::Invoke<Any>(0xD5BDAF17, p0); }
	static Any SEV_PLAYER_IS_VALID_SLOT(Any p0) { return NativeInvoke::Invoke<Any>(0xD6E3E53, p0); }
	static Any SEV_PLAYER_SLOT_TO_INDEX(Any p0) { return NativeInvoke::Invoke<Any>(0x18E183E8, p0); }
	static Any SEV_RESET_UNIQUE_PLAYER_MODEL_VARIATIONS() { return NativeInvoke::Invoke<Any>(0x2772572D); }
	static Any SEV_SET_PLAYER_MODEL_DEFAULT_VARIATION() { return NativeInvoke::Invoke<Any>(0x86F9D4FF); }
	static Any SEV_WATCHER_TO_INT() { return NativeInvoke::Invoke<Any>(0x11A30848); }
	static Any SNAP_PLAYER_TO_COVERLINE(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6) { return NativeInvoke::Invoke<Any>(0x5A54CE7D, p0, p1, p2, p3, p4, p5, p6); }
	static Any SNAP_PLAYER_TO_COVERPOINT(Any p0, Any p1, Any p2, Any p3) { return NativeInvoke::Invoke<Any>(0x464B1DB1, p0, p1, p2, p3); }
	static Any SNAP_PLAYER_TO_COVER_COORDS(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5) { return NativeInvoke::Invoke<Any>(0xEC2D5CFB, p0, p1, p2, p3, p4, p5); }
	static Any START_PARTICLE_FX_LOOPED_AT_COORD(const char* ptfxName, float offsetX, float offsetY, float offsetZ, float rotX, float rotY, float rotZ, float scale) { return NativeInvoke::Invoke<Any>(0xD348E3E6, ptfxName, offsetX, offsetY, offsetZ, rotX, rotY, rotZ, scale); }
	static Any START_PARTICLE_FX_LOOPED_ON_OBJECT(const char* ptfxName, Object object, float offsetX, float offsetY, float offsetZ, float rotX, float rotY, float rotZ, float scale) { return NativeInvoke::Invoke<Any>(0x4B00E9F2, ptfxName, object, offsetX, offsetY, offsetZ, rotX, rotY, rotZ, scale); }
	static Any START_PARTICLE_FX_LOOPED_ON_OBJECT_BONE(const char* ptfxName, Object object, float offsetX, float offsetY, float offsetZ, float rotX, float rotY, float rotZ, int32_t bone, float scale) { return NativeInvoke::Invoke<Any>(0x1B34D211, ptfxName, object, offsetX, offsetY, offsetZ, rotX, rotY, rotZ, bone, scale); }
	static Any START_PARTICLE_FX_LOOPED_ON_PED_BONE(const char* ptfxName, Ped ped, float offsetX, float offsetY, float offsetZ, float rotX, float rotY, float rotZ, int32_t bone, float scale) { return NativeInvoke::Invoke<Any>(0xF8FC196F, ptfxName, ped, offsetX, offsetY, offsetZ, rotX, rotY, rotZ, bone, scale); }
	static Any START_PARTICLE_FX_LOOPED_ON_VEHICLE(const char* ptfxName, Vehicle vehicle, float offsetX, float offsetY, float offsetZ, float rotX, float rotY, float rotZ, float scale) { return NativeInvoke::Invoke<Any>(0x58AA9FC3, ptfxName, vehicle, offsetX, offsetY, offsetZ, rotX, rotY, rotZ, scale); }
	static Any START_PARTICLE_FX_NON_LOOPED_AT_COORD_WITH_GROUND_PLANE() { return NativeInvoke::Invoke<Any>(0xD120A4B4); }
	static Any START_PARTICLE_FX_NON_LOOPED_AT_COORD_WITH_NEARBY_COLLISION() { return NativeInvoke::Invoke<Any>(0x5EFBDD3E); }
	static Any START_PARTICLE_FX_NON_LOOPED_AT_COORD_WITH_OFFSET_GROUND_PLANE() { return NativeInvoke::Invoke<Any>(0xC691A67E); }
	static Any START_RECORDING_PED() { return NativeInvoke::Invoke<Any>(0x7AE7B65B); }
	static Any START_RECORDING_VEHICLE() { return NativeInvoke::Invoke<Any>(0x50117078); }
	static Any START_RECORDING_VEHICLE_TRANSITION_FROM_PLAYBACK() { return NativeInvoke::Invoke<Any>(0x1BDB2B3C); }
	static Any START_SCRIPTED_CONVERSATION() { return NativeInvoke::Invoke<Any>(0x7E4CB1E); } 
	static Any STOP_RECORDING_ALL_VEHICLES() { return NativeInvoke::Invoke<Any>(0x9A9A3735); }
	static Any STOP_RECORDING_PED() { return NativeInvoke::Invoke<Any>(0xEA90369A); }
	static Any STOP_RECORDING_PEDS() { return NativeInvoke::Invoke<Any>(0xDFEB5BF); }
	static Any STOP_RECORDING_VEHICLE() { return NativeInvoke::Invoke<Any>(0x3ED10195); }
	static Any STOP_SCRIPTED_CONVERSATION(Any p0, Any p1, Any p2) { return NativeInvoke::Invoke<Any>(0xAB77DA7D, p0, p1, p2); }
	static Any STOP_WIDGET_COMBO(Any p0, Any p1) { return NativeInvoke::Invoke<Any>(0x4159C9A0, p0, p1); }
	static Any TASK_CAUTIOUS_ADVANCE() { return NativeInvoke::Invoke<Any>(0xC559BB30); }
	static Any TASK_COMBAT_HATED_TARGETS_AROUND_PED_TIMED() { return NativeInvoke::Invoke<Any>(0xF127AD6A); }
	static Any TASK_COMBAT_HATED_TARGETS_IN_AREA() { return NativeInvoke::Invoke<Any>(0xDF099E18); }
	static Any TASK_DRIVE_POINT_ROUTE_ADVANCED() { return NativeInvoke::Invoke<Any>(0x5BE99735); }
	static Any TASK_EXTEND_ROUTE() { return NativeInvoke::Invoke<Any>(0x43271F69); }
	static Any TASK_FOLLOW_POINT_ROUTE() { return NativeInvoke::Invoke<Any>(0xB837C816); }
	static Any TASK_FOLLOW_TO_OFFSET_OF_PED() { return NativeInvoke::Invoke<Any>(0x8F10A775); }
	static Any TASK_GET_OFF_CUSTOM_BOAT() { return NativeInvoke::Invoke<Any>(0x9A082E32); }
	static Any TASK_GET_ON_CUSTOM_BOAT() { return NativeInvoke::Invoke<Any>(0x39E721B7); }
	static Any TASK_GOTO_PED_AIMING() { return NativeInvoke::Invoke<Any>(0x676649DA); }
	static Any TASK_GO_STRAIGHT_TO_COORD_RELATIVE_TO_VEHICLE() { return NativeInvoke::Invoke<Any>(0x5BE44EF2); }
	static Any TASK_GO_TO_COORD_WHILE_AIMING_AT_OBJECT() { return NativeInvoke::Invoke<Any>(0xEA0E01E5); }
	static Any TASK_GO_TO_PED_WHILE_AIMING_AT_COORD() { return NativeInvoke::Invoke<Any>(0x4DF287BB); }
	static Any TASK_GO_TO_PED_WHILE_AIMING_AT_OBJECT() { return NativeInvoke::Invoke<Any>(0x1A817446); }
	static Any TASK_GO_TO_PED_WHILE_AIMING_AT_VEHICLE() { return NativeInvoke::Invoke<Any>(0x572F5FDF); }
	static Any TASK_GUARD_ANGLED_DEFENSIVE_AREA() { return NativeInvoke::Invoke<Any>(0xD2062CA9); }
	static Any TASK_GUARD_ASSIGNED_DEFENSIVE_AREA() { return NativeInvoke::Invoke<Any>(0x7AF0133D); }
	static Any TASK_GUARD_CURRENT_POSITION() { return NativeInvoke::Invoke<Any>(0x2FB099E9); }
	static Any TASK_GUARD_SPHERE_DEFENSIVE_AREA() { return NativeInvoke::Invoke<Any>(0x86B76CB7); }
	static Any TASK_LEAVE_VEHICLE_AND_FLEE() { return NativeInvoke::Invoke<Any>(0x8626D6F8); }
	static Any TASK_NAVIGATE_THROUGH_TRAM_CARS() { return NativeInvoke::Invoke<Any>(0x2E63F94A); }
	static Any TASK_PED_SLIDE_TO_COORD() { return NativeInvoke::Invoke<Any>(0x225380EF); }
	static Any TASK_PED_SLIDE_TO_COORD_AND_PLAY_ANIM() { return NativeInvoke::Invoke<Any>(0x94BBE5C4); }
	static Any TASK_PED_SLIDE_TO_COORD_AND_PLAY_ANIM_HDG_RATE() { return NativeInvoke::Invoke<Any>(0x95ABC676); }
	static Any TASK_PED_SLIDE_TO_COORD_HDG_RATE() { return NativeInvoke::Invoke<Any>(0x38A995C1); }
	static Any TASK_SET_PED_DECISION_MAKER() { return NativeInvoke::Invoke<Any>(0xB6C665A7); }
	static Any TASK_SMART_FLEE_COORD() { return NativeInvoke::Invoke<Any>(0xB2E686FC); }
	static Any TASK_STAND_GUARD() { return NativeInvoke::Invoke<Any>(0xD130F636); }
	static Any TASK_START_SCENARIO_AT_POSITION() { return NativeInvoke::Invoke<Any>(0xAA2C4AC2); }
	static Any TASK_START_SCENARIO_IN_PLACE() { return NativeInvoke::Invoke<Any>(0xE50D6DDE); }
	static Any TASK_STATIONARY_STRAFE_ATTACK() { return NativeInvoke::Invoke<Any>(0xAC987362); }
	static Any TASK_USE_DPV() { return NativeInvoke::Invoke<Any>(0x518F8CF2); }
	static Any TASK_USE_NEAREST_SCENARIO_TO_COORD() { return NativeInvoke::Invoke<Any>(0x9C50FBF0); }
	static Any TASK_USE_NEAREST_SCENARIO_TO_COORD_WARP() { return NativeInvoke::Invoke<Any>(0x1BE9D65C); }
	static Any TASK_VEHICLE_DRIVE_TO_COORD_RUBBER_BAND() { return NativeInvoke::Invoke<Any>(0x72960B42); }
	static Any TASK_VEHICLE_DRIVE_WANDER() { return NativeInvoke::Invoke<Any>(0x36EC0EB0); }
	static Any TASK_VEHICLE_MISSION_COORS_TARGET() { return NativeInvoke::Invoke<Any>(0x6719C109); }
	static Any TASK_VEHICLE_MISSION_PED_TARGET() { return NativeInvoke::Invoke<Any>(0xC81C4677); }
	static Any TASK_WANDER_STANDARD() { return NativeInvoke::Invoke<Any>(0xAF59151A); }
	static Any TASK_WEAPON_ROLL() { return NativeInvoke::Invoke<Any>(0x123B2716); }
	static Any TOGGLE_NM_BINDPOSE_TASK() { return NativeInvoke::Invoke<Any>(0x8F0F700B); }
	static Any TRIGGER_EXPLOSION_AUDIO_FROM_OBJECT() { return NativeInvoke::Invoke<Any>(0xD4807989); } 
	static Blip ADD_BLIP_FOR_CONTACT(float x, float y, float z) { return NativeInvoke::Invoke<Blip>(0x6295B365, x, y, z); }
	static Blip ADD_BLIP_FOR_COORD(float x, float y, float z) { return NativeInvoke::Invoke<Blip>(0xC6F43D0E, x, y, z); }
	static Blip ADD_BLIP_FOR_GANG_TERRITORY(float x, float y, float z) { return NativeInvoke::Invoke<Blip>(0x63EBC4FA, x, y, z); }
	static Blip ADD_BLIP_FOR_OBJECT(Object object) { return NativeInvoke::Invoke<Blip>(0xE5372EC, object); }
	static Blip ADD_BLIP_FOR_PED(Ped ped) { return NativeInvoke::Invoke<Blip>(0x8A6ED1DF, ped); }
	static Blip ADD_BLIP_FOR_PICKUP(Pickup pickup) { return NativeInvoke::Invoke<Blip>(0x16693C3A, pickup); }
	static Blip ADD_BLIP_FOR_VEHICLE(Vehicle vehicle) { return NativeInvoke::Invoke<Blip>(0xA338238C, vehicle); }
	static Blip GET_CENTRE_BLIP_ID() { return NativeInvoke::Invoke<Blip>(0x45EDA627); }
	static Blip GET_FIRST_BLIP_INFO_ID(int32_t sprite) { return NativeInvoke::Invoke<Blip>(0x64C0273D, sprite); }
	static Blip GET_NEXT_BLIP_INFO_ID(int32_t sprite) { return NativeInvoke::Invoke<Blip>(0x9356E92F, sprite); }
	static Cam CREATE_CAM(const char* camName, bool p1) { return NativeInvoke::Invoke<Cam>(0xE9BF2A7D, camName, p1); }
	static Cam CREATE_CAM_WITH_PARAMS(const char* camName, float posX, float posY, float posZ, float rotX, float rotY, float rotZ, float fieldOfView, bool p8) { return NativeInvoke::Invoke<Cam>(0x23B02F15, camName, posX, posY, posZ, rotX, rotY, rotZ, fieldOfView, p8); }
	static Cam GET_DEBUG_CAM() { return NativeInvoke::Invoke<Cam>(0x76A50592); }
	static Cam GET_RENDERING_CAM() { return NativeInvoke::Invoke<Cam>(0xFCF4DF1); }
	static FireId START_PED_FIRE(Ped ped, float unk) { return NativeInvoke::Invoke<FireId>(0x604950EB, ped, unk); }
	static FireId START_SCRIPT_FIRE(float x, float y, float z, int32_t maxChildren) { return NativeInvoke::Invoke<FireId>(0xE7529357, x, y, z, maxChildren); }
	static Group CREATE_GROUP(int32_t unused, bool p1) { return NativeInvoke::Invoke<Group>(0x8DC0368D, unused, p1); }
	static Group GET_PED_GROUP_INDEX(Ped ped) { return NativeInvoke::Invoke<Group>(0x134E0785, ped); }
	static Group GET_PLAYER_GROUP(Player player) { return NativeInvoke::Invoke<Group>(0xA5EDCDE8, player); }
	static Interior GET_INTERIOR_AT_COORDS(float x, float y, float z) { return NativeInvoke::Invoke<Interior>(0xA17FBF37, x, y, z); }
	static Interior GET_INTERIOR_FROM_NAME(const char* name, int32_t numAttempts) { return NativeInvoke::Invoke<Interior>(0x572A936, name, numAttempts); }
	static Interior GET_INTERIOR_FROM_PED(Ped ped) { return NativeInvoke::Invoke<Interior>(0xC5F6B455, ped); }
	static Interior GET_INTERIOR_FROM_VEHICLE(Vehicle vehicle) { return NativeInvoke::Invoke<Interior>(0x50768666, vehicle); }
	static Object CREATE_OBJECT(uint32_t modelHash, float x, float y, float z, bool dynamic, bool dontOwn) { return NativeInvoke::Invoke<Object>(0x2F7AA05C, modelHash, x, y, z, dynamic, dontOwn); }
	static Object CREATE_OBJECT_MOVER(uint32_t modelHash, float x, float y, float z, bool dynamic, const char* pathName, bool dontOwn) { return NativeInvoke::Invoke<Object>(0x757194AC, modelHash, x, y, z, dynamic, pathName, dontOwn); }
	static Object CREATE_OBJECT_NO_OFFSET(uint32_t modelHash, float x, float y, float z, bool dynamic, bool dontOwn) { return NativeInvoke::Invoke<Object>(0x58040420, modelHash, x, y, z, dynamic, dontOwn); }
	static Object CREATE_SIMPLE_PED(uint32_t modelHash, float x, float y, float z, float heading, uint32_t p6, bool p7) { return NativeInvoke::Invoke<Object>(0x43010177, modelHash, x, y, z, heading, p6, p7); }
	static Object FIND_OBJECT_AT_POSITION(const char* modelName, float x, float y, float z, float radius) { return NativeInvoke::Invoke<Object>(0x77984D34, modelName, x, y, z, radius); }
	static Object GET_BLIP_INFO_ID_OBJECT_INDEX(Blip blip) { return NativeInvoke::Invoke<Object>(0x27AB7110, blip); }
	static Object GET_NEARBY_OBJECT_WITH_SPECIAL_ATTRIBUTE(int32_t index) { return NativeInvoke::Invoke<Object>(0x7BAE3F92, index); }
	static Object GET_OBJECT_PLAYER_WILL_PICKUP(Player player) { return NativeInvoke::Invoke<Object>(0x45A04432, player); }
	static Object GET_REGISTERED_OBJECT_INDEX_POST_CUTSCENE(const char* name) { return NativeInvoke::Invoke<Object>(0x17F49810, name); }
	static Ped CREATE_PED(int32_t pedType, uint32_t modelHash, float x, float y, float z, float heading, bool isNetwork, bool dontOwn) { return NativeInvoke::Invoke<Ped>(0x389EF71, pedType, modelHash, x, y, z, heading, isNetwork, dontOwn); }
	static Ped CREATE_PED_INSIDE_VEHICLE(Vehicle vehicle, int32_t pedType, uint32_t modelHash, int32_t seatIndex, const char* p4, bool p5) { return NativeInvoke::Invoke<Ped>(0x3000F092, vehicle, pedType, modelHash, seatIndex, p4, p5); }
	static Ped CREATE_RANDOM_FEMALE_PED(float x, float y, float z) { return NativeInvoke::Invoke<Ped>(0x5847ADE0, x, y, z); }
	static Ped CREATE_RANDOM_MALE_PED(float x, float y, float z) { return NativeInvoke::Invoke<Ped>(0xD5E380F3, x, y, z); }
	static Ped CREATE_RANDOM_PED(float x, float y, float z) { return NativeInvoke::Invoke<Ped>(0x5A949543, x, y, z); }
	static Ped CREATE_RANDOM_PED_AS_DRIVER(Vehicle vehicle) { return NativeInvoke::Invoke<Ped>(0xB927CE9A, vehicle); }
	static Ped GET_BLIP_INFO_ID_PED_INDEX(Blip blip) { return NativeInvoke::Invoke<Ped>(0xDD57007, blip); }
	static Ped GET_PEDS_LAST_ATTACKER(Ped ped) { return NativeInvoke::Invoke<Ped>(0xB82351F, ped); }
	static Ped GET_PED_AS_GROUP_LEADER(Group group) { return NativeInvoke::Invoke<Ped>(0x52873C6A, group); }
	static Ped GET_PED_AS_GROUP_MEMBER(Group group, int32_t memberIndex) { return NativeInvoke::Invoke<Ped>(0x9AA3CC8C, group, memberIndex); }
	static Ped GET_PED_IN_VEHICLE_SEAT(Vehicle vehicle, int32_t seatIndex) { return NativeInvoke::Invoke<Ped>(0x388FDE9A, vehicle, seatIndex); }
	static Ped GET_PED_OBJECT_IS_ATTACHED_TO(Object object) { return NativeInvoke::Invoke<Ped>(0x72ADF3FC, object); }
	static Ped GET_PLAYER_PED(Player player) { return NativeInvoke::Invoke<Ped>(0x6E31E993, player); }
	static Ped GET_RANDOM_PED_AT_COORD(float x, float y, float z, float xRadius, float yRadius, float zRadius) { return NativeInvoke::Invoke<Ped>(0xDC8239EB, x, y, z, xRadius, yRadius, zRadius); }
	static Ped GET_REGISTERED_PED_INDEX_POST_CUTSCENE(const char* name) { return NativeInvoke::Invoke<Ped>(0xF6595859, name); }
	static Pickup GET_BLIP_INFO_ID_PICKUP_INDEX(Blip blip) { return NativeInvoke::Invoke<Pickup>(0x86913D37, blip); }
	static Pickup GET_PICKUP_FROM_PLACEMENT(int32_t index) { return NativeInvoke::Invoke<Pickup>(0x59A39BA3, index); }
	static Player GET_PLAYER_ID() { return NativeInvoke::Invoke<Player>(0x1CC648EA); }
	static Player GET_PLAYER_KILLER(Player player) { return NativeInvoke::Invoke<Player>(0x7A2356DA, player); }
	static Player INT_TO_PLAYERINDEX(int32_t value) { return NativeInvoke::Invoke<Player>(0x98DD98F1, value); }
	static Player NETWORK_GET_KILLER_OF_PLAYER(Player player) { return NativeInvoke::Invoke<Player>(0x9809FB6F, player); }
	static Player NET_PARTY_GET_LEADER_PLAYER() { return NativeInvoke::Invoke<Player>(0x6F29E2F9); }
	static Player SEV_GET_MY_PLAYER() { return NativeInvoke::Invoke<Player>(0x43BE716F); }
	static Request REQUEST_ANIM_DICT(const char* dictName, bool p1) { return NativeInvoke::Invoke<Request>(0xDCA96950, dictName, p1); }
	static Request REQUEST_MODEL(uint32_t modelHash) { return NativeInvoke::Invoke<Request>(0xFFF1B500, modelHash); }
	static Request REQUEST_SCRIPT(const char* name) { return NativeInvoke::Invoke<Request>(0xE26B2666, name); }
	static Vector3 GET_BLIP_COORDS(Blip blip) { return NativeInvoke::Invoke<Vector3>(0xEF6FF47B, blip); }
	static Vector3 GET_BLIP_INFO_ID_COORD(Blip blip) { return NativeInvoke::Invoke<Vector3>(0xB7374A66, blip); }
	static Vector3 GET_BULLET_IMPACT_AREA(float x, float y, float z, float radius, Ped* outPed) { return NativeInvoke::Invoke<Vector3>(0x4AB5B015, x, y, z, radius, outPed); }
	static Vector3 GET_CAM_COORD(Cam cam) { return NativeInvoke::Invoke<Vector3>(0x7C40F09C, cam); }
	static Vector3 GET_CAM_ROT(Cam cam) { return NativeInvoke::Invoke<Vector3>(0xDAC84C9F, cam); }
	static Vector3 GET_CORPSE_COORDS(Ped ped) { return NativeInvoke::Invoke<Vector3>(0xAAA4C65, ped); }
	static Vector3 GET_CUTSCENE_PED_COORD(Any p0) { return NativeInvoke::Invoke<Vector3>(0xEDF371D0, p0); }
	static Vector3 GET_DEAD_PED_COORDS(Ped ped) { return NativeInvoke::Invoke<Vector3>(0xD5BB9787, ped); }
	static Vector3 GET_DEAD_PED_PICKUP_COORDS(Ped ped) { return NativeInvoke::Invoke<Vector3>(0x129F9DC1, ped); }
	static Vector3 GET_DEAD_VEHICLE_COORDS(Vehicle vehicle) { return NativeInvoke::Invoke<Vector3>(0x3C076D19, vehicle); }
	static Vector3 GET_GAMEPLAY_CAM_COORD() { return NativeInvoke::Invoke<Vector3>(0x9388CF79); }
	static Vector3 GET_GAMEPLAY_CAM_ROT() { return NativeInvoke::Invoke<Vector3>(0x13A010B5); }
	static Vector3 GET_GAMEPLAY_HELPER_BOX_COORD(const char* boxName) { return NativeInvoke::Invoke<Vector3>(0xF0C17F9A, boxName); }
	static Vector3 GET_GAMEPLAY_HELPER_VOLUME_COORD(const char* volumeName) { return NativeInvoke::Invoke<Vector3>(0x2A9EA7D3, volumeName); }
	static Vector3 GET_OBJECT_BONE_COORDS(Object object, int32_t boneId, bool p2) { return NativeInvoke::Invoke<Vector3>(0x2046F7A6, object, boneId, p2); }
	static Vector3 GET_OBJECT_BONE_ORIENTATION(Object object, int32_t boneId, bool p2) { return NativeInvoke::Invoke<Vector3>(0x4B9341F4, object, boneId, p2); }
	static Vector3 GET_OBJECT_COORDS(Object object) { return NativeInvoke::Invoke<Vector3>(0x7CA0C8FB, object); }
	static Vector3 GET_OBJECT_MATRIX_VECTOR(Object object, const char* axisName) { return NativeInvoke::Invoke<Vector3>(0x8B83EE94, object, axisName); }
	static Vector3 GET_OBJECT_ROTATION(Object object) { return NativeInvoke::Invoke<Vector3>(0x28567FDD, object); }
	static Vector3 GET_OBJECT_ROTATION_VELOCITY(Object object) { return NativeInvoke::Invoke<Vector3>(0x5B075C62, object); }
	static Vector3 GET_OBJECT_VELOCITY(Object object) { return NativeInvoke::Invoke<Vector3>(0x2A8801CB, object); }
	static Vector3 GET_OFFSET_FROM_OBJECT_IN_WORLD_COORDS(Object object, float offsetX, float offsetY, float offsetZ) { return NativeInvoke::Invoke<Vector3>(0x66DF1BF5, object, offsetX, offsetY, offsetZ); }
	static Vector3 GET_OFFSET_FROM_PED_IN_WORLD_COORDS(Ped ped, float x, float y, float z) { return NativeInvoke::Invoke<Vector3>(0xAD515B68, ped, x, y, z); }
	static Vector3 GET_OFFSET_FROM_VEHICLE_GIVEN_WORLD_COORDS(Vehicle vehicle, float offsetX, float offsetY, float offsetZ) { return NativeInvoke::Invoke<Vector3>(0x912027D9, vehicle, offsetX, offsetY, offsetZ); }
	static Vector3 GET_OFFSET_FROM_VEHICLE_IN_WORLD_COORDS(Vehicle vehicle, float offsetX, float offsetY, float offsetZ) { return NativeInvoke::Invoke<Vector3>(0x724D8621, vehicle, offsetX, offsetY, offsetZ); }
	static Vector3 GET_PED_BONE_COORDS(Ped ped, int32_t boneId, float offsetX, float offsetY, float offsetZ) { return NativeInvoke::Invoke<Vector3>(0x4579CAB1, ped, boneId, offsetX, offsetY, offsetZ); }
	static Vector3 GET_PED_COORDS(Ped ped) { return NativeInvoke::Invoke<Vector3>(0x9E3ED6AF, ped); }
	static Vector3 GET_PED_DIRECTION(Ped ped, int32_t p1) { return NativeInvoke::Invoke<Vector3>(0x6F0BCEAC, ped, p1); }
	static Vector3 GET_PED_EXTRACTED_DISPLACEMENT(Ped ped, bool worldSpace) { return NativeInvoke::Invoke<Vector3>(0x5231F901, ped, worldSpace); }
	static Vector3 GET_PED_PROP_POSITION(Ped ped, int32_t propIndex) { return NativeInvoke::Invoke<Vector3>(0x7277314C, ped, propIndex); }
	static Vector3 GET_PED_VELOCITY(Ped ped) { return NativeInvoke::Invoke<Vector3>(0xB954696C, ped); }
	static Vector3 GET_PEP_PROP_ROTATION(Ped ped, int32_t propIndex) { return NativeInvoke::Invoke<Vector3>(0x2B4DECF4, ped, propIndex); }
	static Vector3 GET_PLACEMENT_COORDS(int32_t index) { return NativeInvoke::Invoke<Vector3>(0x8E2F0A39, index); }
	static Vector3 GET_POSITION_OF_LAST_MOUSECLICK() { return NativeInvoke::Invoke<Vector3>(0x5EBC23BF); } 
	static Vector3 GET_POSITION_OF_VEHICLE_RECORDING_AT_TIME(int32_t recordingIndex, float time) { return NativeInvoke::Invoke<Vector3>(0x7178558D, recordingIndex, time); }
	static Vector3 GET_VEHICLE_COORDS(Vehicle vehicle) { return NativeInvoke::Invoke<Vector3>(0x1935124, vehicle); }
	static Vector3 GET_VEHICLE_DEFORMATION_AT_POS(Vehicle vehicle, float offsetX, float offsetY, float offsetZ) { return NativeInvoke::Invoke<Vector3>(0xABF02075, vehicle, offsetX, offsetY, offsetZ); }
	static Vector3 GET_VEHICLE_FORWARD_VECTOR(Vehicle vehicle) { return NativeInvoke::Invoke<Vector3>(0xEE053B15, vehicle); }
	static Vector3 GET_VEHICLE_SPEED_VECTOR(Vehicle vehicle, bool relative) { return NativeInvoke::Invoke<Vector3>(0x2E52BB9A, vehicle, relative); }
	static Vector3 VECTOR_ROTATE_AXIS(float x, float y, float z, float rotate, const char* axis) { return NativeInvoke::Invoke<Vector3>(0x649E57A6, x, y, z, rotate, axis); }
	static Vehicle CREATE_MISSION_TRAIN(int32_t variation, float x, float y, float z, bool direction) { return NativeInvoke::Invoke<Vehicle>(0xD4C2EAFD, variation, x, y, z, direction); }
	static Vehicle CREATE_VEHICLE(uint32_t modelHash, float x, float y, float z, float heading, bool isNetwork, bool dontOwn) { return NativeInvoke::Invoke<Vehicle>(0xDD75460A, modelHash, x, y, z, heading, isNetwork, dontOwn); }
	static Vehicle GET_BLIP_INFO_ID_VEHICLE_INDEX(Blip blip) { return NativeInvoke::Invoke<Vehicle>(0x6CB45104, blip); }
	static Vehicle GET_CLOSEST_VEHICLE(float x, float y, float z, float radius, uint32_t modelHash, int32_t flags) { return NativeInvoke::Invoke<Vehicle>(0xD7E26B2C, x, y, z, radius, modelHash, flags); }
	static Vehicle GET_NEAREST_CABLE_CAR(float x, float y, float z, float radius) { return NativeInvoke::Invoke<Vehicle>(0xF2218830, x, y, z, radius); }
	static Vehicle GET_PLAYERS_LAST_VEHICLE() { return NativeInvoke::Invoke<Vehicle>(0xE2757AC1); }
	static Vehicle GET_RANDOM_VEHICLE_BACK_BUMPER_IN_SPHERE(float x, float y, float z, float radius, uint32_t modelHash, int32_t flags) { return NativeInvoke::Invoke<Vehicle>(0xD6343F6B, x, y, z, radius, modelHash, flags); }
	static Vehicle GET_RANDOM_VEHICLE_FRONT_BUMPER_IN_SPHERE(float x, float y, float z, float radius, uint32_t modelHash, int32_t flags) { return NativeInvoke::Invoke<Vehicle>(0xDCADEB66, x, y, z, radius, modelHash, flags); }
	static Vehicle GET_RANDOM_VEHICLE_IN_SPHERE(float x, float y, float z, float radius, uint32_t modelHash, int32_t flags) { return NativeInvoke::Invoke<Vehicle>(0x57216D03, x, y, z, radius, modelHash, flags); }
	static Vehicle GET_RANDOM_VEHICLE_OF_TYPE_IN_AREA(float x, float y, float z, float radius, uint32_t modelHash) { return NativeInvoke::Invoke<Vehicle>(0x2FA2DADF, x, y, z, radius, modelHash); }
	static Vehicle GET_REGISTERED_VEHICLE_INDEX_POST_CUTSCENE(const char* name) { return NativeInvoke::Invoke<Vehicle>(0x27400942, name); }
	static Vehicle GET_TRAIN_CABOOSE(Vehicle train) { return NativeInvoke::Invoke<Vehicle>(0xD717AD46, train); }
	static Vehicle GET_TRAIN_CARRIAGE(Vehicle train, int32_t carriage) { return NativeInvoke::Invoke<Vehicle>(0x2544E7A6, train, carriage); }
	static Vehicle GET_TRAIN_PLAYER_WOULD_ENTER() { return NativeInvoke::Invoke<Vehicle>(0xCB979EE4); }
	static Vehicle GET_VEHICLE_OBJECT_IS_ATTACHED_TO(Object object) { return NativeInvoke::Invoke<Vehicle>(0x5DFD6E29, object); }
	static Vehicle GET_VEHICLE_PED_IS_IN(Ped ped) { return NativeInvoke::Invoke<Vehicle>(0xAFE92319, ped); }
	static Vehicle GET_VEHICLE_PED_IS_USING(Ped ped) { return NativeInvoke::Invoke<Vehicle>(0x6DE3AADA, ped); }
	static Weapon GET_REGISTERED_WEAPON_INDEX_POST_CUTSCENE(const char* name) { return NativeInvoke::Invoke<Weapon>(0xDB0F31B2, name); }
	static Weapon GET_WEAPON_FROM_HAND(Ped ped, int32_t handType, bool p2) { return NativeInvoke::Invoke<Weapon>(0xF5A9F0F9, ped, handType, p2); }
	static Weapon GET_WEAPON_FROM_HOLSTER(Ped ped, int32_t holsterType) { return NativeInvoke::Invoke<Weapon>(0x4F1AB270, ped, holsterType); }
	static Weapon GET_WEAPON_FROM_SLOT(Ped ped, int32_t holsterType) { return NativeInvoke::Invoke<Weapon>(0x363C0973, ped, holsterType); }
	static Weapon GIVE_DELAYED_WEAPON_TO_PED(Ped ped, uint32_t weaponHash, int32_t ammo, bool equipNow) { return NativeInvoke::Invoke<Weapon>(0x5868D20D, ped, weaponHash, ammo, equipNow); }
	static Weapon GIVE_WEAPON_TO_PED(Ped ped, uint32_t weaponHash, int32_t ammo, bool equipNow) { return NativeInvoke::Invoke<Weapon>(0xC4D88A85, ped, weaponHash, ammo, equipNow); }
	static Weapon GIVE_WEAPON_TO_PED_HAND(Ped ped, uint32_t weaponHash, int32_t ammo, int32_t handType) { return NativeInvoke::Invoke<Weapon>(0xD2103032, ped, weaponHash, ammo, handType); }
	static Weapon GIVE_WEAPON_TO_PED_HOLSTER(Ped ped, uint32_t weaponHash, int32_t ammo, int32_t holsterType) { return NativeInvoke::Invoke<Weapon>(0x865E839A, ped, weaponHash, ammo, holsterType); }
	static Weapon SET_PED_DROPS_WEAPON(Ped ped, Weapon weapon) { return NativeInvoke::Invoke<Weapon>(0x3D3329FA, ped, weapon); }
	static bool ACTION_TREE_FORCE_UNLOAD(const char* name) { return NativeInvoke::Invoke<bool>(0xD99BD3AF, name); }
	static bool ACTION_TREE_LOAD(const char* name) { return NativeInvoke::Invoke<bool>(0x8520911A, name); }
	static bool ACTION_TREE_UNLOAD(const char* name) { return NativeInvoke::Invoke<bool>(0x620BE3A3, name); }
	static bool ADD_SCRIPT_TUNABLE_CRC_FLOAT(uint32_t tunableHash, float value) { return NativeInvoke::Invoke<bool>(0xB16DFC67, tunableHash, value); }
	static bool ADD_SCRIPT_TUNABLE_CRC_INT(uint32_t tunableHash, int32_t value) { return NativeInvoke::Invoke<bool>(0x7A49981, tunableHash, value); }
	static bool ADD_SCRIPT_TUNABLE_CRC_bool(uint32_t tunableHash, bool value) { return NativeInvoke::Invoke<bool>(0x754B769B, tunableHash, value); }
	static bool ADD_SCRIPT_TUNABLE_FLOAT(const char* context, const char* name, float value) { return NativeInvoke::Invoke<bool>(0x7DA01BE3, context, name, value); }
	static bool ADD_SCRIPT_TUNABLE_INT(const char* context, const char* name, int32_t value) { return NativeInvoke::Invoke<bool>(0x84C024B8, context, name, value); }
	static bool ADD_SCRIPT_TUNABLE_bool(const char* context, const char* name, bool value) { return NativeInvoke::Invoke<bool>(0x9F25E66C, context, name, value); }
	static bool ARE_ALL_NAVMESH_REGIONS_LOADED() { return NativeInvoke::Invoke<bool>(0x34C4E789); }
	static bool ARE_CREDITS_ACTIVE() { return NativeInvoke::Invoke<bool>(0xD53CA5A2); }
	static bool ARE_MP_STATS_LOADED() { return NativeInvoke::Invoke<bool>(0x2469CD25); }
	static bool ARE_PLAYER_COVER_MOVEMENT_TRANSITIONS_BLOCKED() { return NativeInvoke::Invoke<bool>(0x47D2668); }
	static bool ARE_SP_STATS_LOADED() { return NativeInvoke::Invoke<bool>(0xA73A7E53); }
	static bool ARE_STRINGS_EQUAL(const char* str1, const char* str2) { return NativeInvoke::Invoke<bool>(0x877C0BC5, str1, str2); }
	static bool ARE_UNIT_TESTS_RUNNING() { return NativeInvoke::Invoke<bool>(0x4F4C7FA4); }
	static bool ARE_VEHICLE_HEADLIGHTS_BROKEN(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0xE9C0A5A0, vehicle); }
	static bool ARE_WIDESCREEN_BORDERS_ACTIVE() { return NativeInvoke::Invoke<bool>(0x4E26746C); } 
	static bool ASSISTED_MOVEMENT_IS_ON_ANY_ROUTE() { return NativeInvoke::Invoke<bool>(0x7B3F0F02); }
	static bool AUDIO_IS_MUSIC_PLAYING() { return NativeInvoke::Invoke<bool>(0x84435231); }
	static bool AUDIO_IS_SCRIPTED_MUSIC_PLAYING() { return NativeInvoke::Invoke<bool>(0x86E995D1); }
	static bool CAMERA_SETTINGS_IS_HARD_LOCK_ENABLED() { return NativeInvoke::Invoke<bool>(0x1A2E23B0); }
	static bool CAN_CREATE_RANDOM_COPS() { return NativeInvoke::Invoke<bool>(0xAA73DAD9); }
	static bool CAN_CREATE_RANDOM_PED() { return NativeInvoke::Invoke<bool>(0xF9ABE88F); }
	static bool CAN_PED_SEE_OTHER_PED(Ped ped, Ped ped2, float p2, float p3) { return NativeInvoke::Invoke<bool>(0xFF36A652, ped, ped2, p2, p3); }
	static bool CAN_PLAYER_START_MISSION(Player player) { return NativeInvoke::Invoke<bool>(0x39E3CB3F, player); }
	static bool CAN_SET_ENTER_STATE_FOR_CUTSCENE_PED(const char* name) { return NativeInvoke::Invoke<bool>(0xE3F828A8, name); }
	static bool CAN_SET_EXIT_STATE_FOR_CUTSCENE_PED(const char* name) { return NativeInvoke::Invoke<bool>(0xDD1F0C79, name); }
	static bool CHECKPOINT_STORAGE_LOAD(Any* data, int32_t dataSize) { return NativeInvoke::Invoke<bool>(0x8FE3BFF, data, dataSize); }
	static bool COMPARE_AGAINST_SCORE_PARAM(int32_t p0, int32_t p1, const char* paramName) { return NativeInvoke::Invoke<bool>(0xD79D2DA4, p0, p1, paramName); }
	static bool CUTSCENE_EXIST(const char* cutsceneName) { return NativeInvoke::Invoke<bool>(0xE3978BF6, cutsceneName); }
	static bool CUTSCENE_IS_LOADED(const char* cutsceneName) { return NativeInvoke::Invoke<bool>(0xDFC021D1, cutsceneName); }
	static bool CUTSCENE_IS_LOADING() { return NativeInvoke::Invoke<bool>(0x8515977D); }
	static bool CUTSCENE_IS_WAITING_FOR_MOVIE() { return NativeInvoke::Invoke<bool>(0x4C1C831); }
	static bool CUTSCENE_NAMED_IS_LOADING(const char* cutsceneName) { return NativeInvoke::Invoke<bool>(0x9DE1B716, cutsceneName); }
	static bool CUTSCENE_SHOW_UNAPPROVED() { return NativeInvoke::Invoke<bool>(0xD17DDF9); }
	static bool DB_GET_bool(const char* name, const char* entryName) { return NativeInvoke::Invoke<bool>(0x7195DC58, name, entryName); }
	static bool DB_IS_FLOAT_VALID(const char* name, const char* entryName) { return NativeInvoke::Invoke<bool>(0x85027555, name, entryName); }
	static bool DB_IS_INT_VALID(const char* name, const char* entryName) { return NativeInvoke::Invoke<bool>(0x206CC15, name, entryName); }
	static bool DB_IS_bool_VALID(const char* name, const char* entryName) { return NativeInvoke::Invoke<bool>(0x991BC5CF, name, entryName); }
	static bool DID_PLAYER_QUIT_LEVEL(Any p0) { return NativeInvoke::Invoke<bool>(0x28041AC7, p0); }
	static bool DOES_BLIP_EXIST(Blip blip) { return NativeInvoke::Invoke<bool>(0xAE92DD96, blip); }
	static bool DOES_CAM_EXIST(Cam cam) { return NativeInvoke::Invoke<bool>(0x1EF89DC0, cam); }
	static bool DOES_CORPSE_EXIST(Ped ped) { return NativeInvoke::Invoke<bool>(0x109EAB3D, ped); }
	static bool DOES_DECISION_MAKER_EXIST(Any decisionMaker) { return NativeInvoke::Invoke<bool>(0x5F912485, decisionMaker); }
	static bool DOES_GLINT_EXIST(int32_t glint) { return NativeInvoke::Invoke<bool>(0x81AF036B, glint); }
	static bool DOES_GROUP_EXIST(Group group) { return NativeInvoke::Invoke<bool>(0x935C978D, group); }
	static bool DOES_LAUNCH_PARAM_EXIST(int32_t p0, const char* paramName) { return NativeInvoke::Invoke<bool>(0x4EE8FFA2, p0, paramName); }
	static bool DOES_LOADOUT_SLOT_HAVE_CUSTOM_NAME(int32_t index) { return NativeInvoke::Invoke<bool>(0x6AC41269, index); }
	static bool DOES_MAIN_PLAYER_EXIST() { return NativeInvoke::Invoke<bool>(0x2528378B); }
	static bool DOES_OBJECT_EXIST(Object object) { return NativeInvoke::Invoke<bool>(0xB2A3021E, object); }
	static bool DOES_OBJECT_HAVE_PHYSICS(Object object) { return NativeInvoke::Invoke<bool>(0x45D1813F, object); }
	static bool DOES_OBJECT_OF_TYPE_EXIST_AT_COORDS(float x, float y, float z, float radius, uint32_t modelHash) { return NativeInvoke::Invoke<bool>(0x23FF2BA4, x, y, z, radius, modelHash); }
	static bool DOES_PAD_EXIST(int32_t padIndex) { return NativeInvoke::Invoke<bool>(0x435A85E0, padIndex); }
	static bool DOES_PED_EXIST(Ped ped) { return NativeInvoke::Invoke<bool>(0xF7C8D072, ped); }
	static bool DOES_PICKUP_EXIST(Pickup pickup) { return NativeInvoke::Invoke<bool>(0x9C6DA0B3, pickup); }
	static bool DOES_PLACEMENT_EXIST(int32_t index) { return NativeInvoke::Invoke<bool>(0x02D7902, index); }
	static bool DOES_SCRIPT_EXIST(const char* name) { return NativeInvoke::Invoke<bool>(0xDEAB87AB, name); }
	static bool DOES_TEXT_LABEL_EXIST(const char* textLabel) { return NativeInvoke::Invoke<bool>(0x6ECAE560, textLabel); }
	static bool DOES_THIS_MINIGAME_SCRIPT_ALLOW_NON_MINIGAME_HELP_MESSAGES() { return NativeInvoke::Invoke<bool>(0xE667A6D1); }
	static bool DOES_VEHICLE_EXIST(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x8737CC23, vehicle); }
	static bool DOES_VEHICLE_HAVE_ROOF(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0xDB817403, vehicle); }
	static bool DOES_VEHICLE_HAVE_STUCK_VEHICLE_CHECK(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x5D91D9AC, vehicle); }
	static bool EXISTS_SCRIPT_TUNABLE_VARIABLE_CRC_bool(uint32_t tunableHash) { return NativeInvoke::Invoke<bool>(0xA8D360E2, tunableHash); }
	static bool EXISTS_SCRIPT_TUNABLE_VARIABLE_bool(const char* context, const char* name) { return NativeInvoke::Invoke<bool>(0x34E79A7D, context, name); }
	static bool GET_ALLOWED_TO_FAIL_COVER_FOR_BLOCKING_LINE_OF_FIRE() { return NativeInvoke::Invoke<bool>(0xCB1E7ADE); }
	static bool GET_AMMO_IN_CLIP(Ped ped, uint32_t weaponHash, int32_t* ammo) { return NativeInvoke::Invoke<bool>(0x73C100C3, ped, weaponHash, ammo); }
	static bool GET_BG_SCRIPT_LEADERBOARD_NAME(int32_t index, int32_t bufferSize, char* buffer) { return NativeInvoke::Invoke<bool>(0x2694F2B0, index, bufferSize, buffer); }
	static bool GET_BLOCKING_OF_NON_TEMPORARY_EVENTS(Ped ped) { return NativeInvoke::Invoke<bool>(0xC38F2076, ped); }
	static bool GET_BLOCKING_OF_PED_TARGETTING(Ped ped) { return NativeInvoke::Invoke<bool>(0x8C2FD714, ped); }
	static bool GET_CAN_PED_CAN_SLOW_DOWN_WHEN_TURNING(Ped ped) { return NativeInvoke::Invoke<bool>(0x45E894EA, ped); }
	static bool GET_CAN_PED_PLAY_LOCO_FLAVOR_STARTS(Ped ped) { return NativeInvoke::Invoke<bool>(0xD8BE7688, ped); }
	static bool GET_CHALLENGE_FAILED_STATE(int32_t challengeId) { return NativeInvoke::Invoke<bool>(0x8BD57283, challengeId); }
	static bool GET_CLOSEST_ENEMY_PED(Ped ped, float p1, float p2, float p3, float p4, bool p5, bool p6, bool p7, bool p8, bool p9, bool p10, Ped* outPed) { return NativeInvoke::Invoke<bool>(0x3E184D2D, ped, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, outPed); }
	static bool GET_CLOSEST_MAJOR_VEHICLE_NODE(float x, float y, float z, Vector3* coords) { return NativeInvoke::Invoke<bool>(0x4B5F15B, x, y, z, coords); }
	static bool GET_CLOSEST_NETWORK_RESTART_NODE(float x, float y, float z, Vector3* coords, float* heading) { return NativeInvoke::Invoke<bool>(0xFFF0E04A, x, y, z, coords, heading); }
	static bool GET_CLOSEST_PED(float x, float y, float z, float radius, bool p4, bool p5, Ped* outPed) { return NativeInvoke::Invoke<bool>(0x8F6C1F55, x, y, z, radius, p4, p5, outPed); }
	static bool GET_CLOSEST_ROAD(float x, float y, float z, float p3, Any p4, Vector3* p5, Vector3* p6, Any* p7, Any* p8, Any* p9) { return NativeInvoke::Invoke<bool>(0x567B0E11, x, y, z, p3, p4, p5, p6, p7, p8, p9); }
	static bool GET_CLOSEST_VEHICLE_NODE(float x, float y, float z, Vector3* coords) { return NativeInvoke::Invoke<bool>(0x6F5F1E6C, x, y, z, coords); }
	static bool GET_CLOSEST_VEHICLE_NODE_WITH_HEADING(float x, float y, float z, Vector3* coords, float* heading) { return NativeInvoke::Invoke<bool>(0x8BD5759B, x, y, z, coords, heading); }
	static bool GET_CURRENT_PED_WEAPON(Ped ped, uint32_t* weaponHash, int32_t handType) { return NativeInvoke::Invoke<bool>(0xB0237302, ped, weaponHash, handType); }
	static bool GET_CUTSCENE_CAPTURE_REQUEST(int32_t bufferSize, char* buffer) { return NativeInvoke::Invoke<bool>(0xB2A87EE9, bufferSize, buffer); }
	static bool GET_DOES_WEAPON_EXIST(Weapon weapon) { return NativeInvoke::Invoke<bool>(0x66A14D7, weapon); }
	static bool GET_EXISTS_IN_PLAYER_SAVE(const char* unlockSemantic) { return NativeInvoke::Invoke<bool>(0x2F849928, unlockSemantic); }
	static bool GET_GROUND_Z_FOR_3D_COORD(float x, float y, float z, float* groundZ) { return NativeInvoke::Invoke<bool>(0xA1BFD5E0, x, y, z, groundZ); }
	static bool GET_INFO_ABOUT_NEARBY_ENTITY_WITH_SPECIAL_ATTRIBUTE(int32_t index, Vector3* coords, float* p2, bool* p3, uint32_t* modelHash, float* p5) { return NativeInvoke::Invoke<bool>(0x111F28AD, index, coords, p2, p3, modelHash, p5); }
	static bool GET_IS_DETONATOR_FIRED(Ped ped) { return NativeInvoke::Invoke<bool>(0x897A3AE, ped); }
	static bool GET_IS_HIDEF() { return NativeInvoke::Invoke<bool>(0x1C340359); }
	static bool GET_IS_PED_FORCED_TO_RUN(Ped ped) { return NativeInvoke::Invoke<bool>(0x8E3AA72A, ped); }
	static bool GET_IS_PED_FORCED_TO_WALK(Ped ped) { return NativeInvoke::Invoke<bool>(0xB947D1CE, ped); }
	static bool GET_IS_PED_PHOTOGRAPHING_COORD(Ped ped, float x, float y, float z, float p4, bool p5) { return NativeInvoke::Invoke<bool>(0xF34F8AF0, ped, x, y, z, p4, p5); }
	static bool GET_IS_PLAYER_IN_AIR(Player player) { return NativeInvoke::Invoke<bool>(0x2BDCB6E, player); }
	static bool GET_IS_PLAYER_IN_BULLET_TIME(Player player) { return NativeInvoke::Invoke<bool>(0x8E5084AD, player); }
	static bool GET_IS_PLAYER_IN_LAST_STAND(Player player) { return NativeInvoke::Invoke<bool>(0x35EE1682, player); }
	static bool GET_IS_PLAYER_SHOOT_DODGING(Player player) { return NativeInvoke::Invoke<bool>(0x1E8970C1, player); }
	static bool GET_IS_UNLOCKED(const char* unlockSemantic) { return NativeInvoke::Invoke<bool>(0x2B86B773, unlockSemantic); }
	static bool GET_IS_WIDESCREEN() { return NativeInvoke::Invoke<bool>(0xEC717AEF); }
	static bool GET_LOCAL_PLAYER_SPRINT_METER(float* outValue) { return NativeInvoke::Invoke<bool>(0x50A43014, outValue); }
	static bool GET_MAX_AMMO(Ped ped, uint32_t weaponHash, int32_t* ammo) { return NativeInvoke::Invoke<bool>(0xB294796, ped, weaponHash, ammo); }
	static bool GET_MELEE_GRAPPLE_FAIL_CHECK_ON(Ped ped) { return NativeInvoke::Invoke<bool>(0xAE5FA062, ped); }
	static bool GET_MISSION_FLAG() { return NativeInvoke::Invoke<bool>(0x95115F97); }
	static bool GET_MOBILE_PHONE_TASK_SUB_TASK(Ped ped, int32_t* subtask) { return NativeInvoke::Invoke<bool>(0xB47C4CF0, ped, subtask); }
	static bool GET_NAME_OF_CURRENT_LEVEL(int32_t bufferSize, char* buffer) { return NativeInvoke::Invoke<bool>(0x4EFC439F, bufferSize, buffer); }
	static bool GET_NEXT_CLOSEST_VEHICLE_NODE_WITH_HEADING_ON_ISLAND(float x, float y, float z, int32_t p3, Vector3* coords, float* heading) { return NativeInvoke::Invoke<bool>(0xC70C3E6F, x, y, z, p3, coords, heading); }
	static bool GET_NTH_CLOSEST_VEHICLE_NODE(float x, float y, float z, int32_t n, Vector3* coords) { return NativeInvoke::Invoke<bool>(0xF125BFCC, x, y, z, n, coords); }
	static bool GET_NTH_CLOSEST_VEHICLE_NODE_FAVOUR_DIRECTION(float x1, float y1, float z1, float x2, float y2, float z2, int32_t n, Vector3* coords, float* heading) { return NativeInvoke::Invoke<bool>(0x928A4DEC, x1, y1, z1, x2, y2, z2, n, coords, heading); }
	static bool GET_NTH_CLOSEST_VEHICLE_NODE_WITH_HEADING(float x, float y, float z, int32_t n, Vector3* coords, float* heading) { return NativeInvoke::Invoke<bool>(0x7349C856, x, y, z, n, coords, heading); }
	static bool GET_NTH_CLOSEST_VEHICLE_NODE_WITH_HEADING_ON_ISLAND(float x, float y, float z, int32_t n, Vector3* coords, float* heading) { return NativeInvoke::Invoke<bool>(0x39998BD2, x, y, z, n, coords, heading); }
	static bool GET_OBJECT_CAN_TRIGGER_BULLET_CAM(Object object) { return NativeInvoke::Invoke<bool>(0xBFD5EBD4, object); }
	static bool GET_OBJECT_REFLECTS(Object object) { return NativeInvoke::Invoke<bool>(0x8A60400E, object); }
	static bool GET_PAD_PITCH_ROLL(int32_t padIndex, Any* p1, Any* p2) { return NativeInvoke::Invoke<bool>(0x666EE1CB, padIndex, p1, p2); }
	static bool GET_PATROL_TASK_INFO(Ped ped, Any* p1, Any* p2) { return NativeInvoke::Invoke<bool>(0xFED7AA39, ped, p1, p2); }
	static bool GET_PED_AWARENESS_STATE(Ped ped, Ped targetPed, int32_t p2) { return NativeInvoke::Invoke<bool>(0x40877917, ped, targetPed, p2); }
	static bool GET_PED_CAN_INITIATE_BULLET_CAM(Ped ped) { return NativeInvoke::Invoke<bool>(0xC15F38C0, ped); }
	static bool GET_PED_CAN_TRIGGER_BULLET_CAM(Ped ped) { return NativeInvoke::Invoke<bool>(0x28EAACA6, ped); }
	static bool GET_PED_HAS_PALETTE_VARIATIONS(Ped ped, uint32_t p1, uint32_t p2) { return NativeInvoke::Invoke<bool>(0xFE522C50, ped, p1, p2); }
	static bool GET_PED_HAS_SEEN_DEAD_PED(Ped ped, bool p1, Ped* ped2) { return NativeInvoke::Invoke<bool>(0xD05D0C57, ped, p1, ped2); }
	static bool GET_PED_HAS_SURRENDERED(Ped ped) { return NativeInvoke::Invoke<bool>(0xAA538B02, ped); }
	static bool GET_PED_LAST_DAMAGE_BONE(Ped ped, int32_t* bone) { return NativeInvoke::Invoke<bool>(0xAB933841, ped, bone); }
	static bool GET_PED_LAST_WEAPON_IMPACT_COORD(Ped ped, Vector3* coord) { return NativeInvoke::Invoke<bool>(0x9B266079, ped, coord); }
	static bool GET_PED_MELEE_ACTION_FLAG0(Ped ped) { return NativeInvoke::Invoke<bool>(0x98A851EE, ped); }
	static bool GET_PED_MELEE_ACTION_FLAG1(Ped ped) { return NativeInvoke::Invoke<bool>(0xB4EF8A7C, ped); }
	static bool GET_PED_MODEL_FROM_INDEX(int32_t index, uint32_t* modelHash) { return NativeInvoke::Invoke<bool>(0xC4765BEE, index, modelHash); }
	static bool GET_PED_NM_FEEDBACK(Ped ped, int32_t p1, int32_t p2) { return NativeInvoke::Invoke<bool>(0x7A8E12C1, ped, p1, p2); }
	static bool GET_PED_REACHED_TARGETED_GRAVWELL_CENTER(Ped ped, const char* p1, const char* p2, bool p3) { return NativeInvoke::Invoke<bool>(0xA897DA4F, ped, p1, p2, p3); }
	static bool GET_PED_READY_TO_BE_EXECUTED(Ped ped) { return NativeInvoke::Invoke<bool>(0xC2D76D7, ped); }
	static bool GET_PED_READY_TO_BE_STUNNED(Ped ped) { return NativeInvoke::Invoke<bool>(0x82EF96E, ped); }
	static bool GET_PED_STEALTH_MOVEMENT(Ped ped) { return NativeInvoke::Invoke<bool>(0x40321B83, ped); }
	static bool GET_PED_STEERS_AROUND_OBJECTS(Ped ped) { return NativeInvoke::Invoke<bool>(0xE4E47CBF, ped); }
	static bool GET_PED_STEERS_AROUND_PEDS(Ped ped) { return NativeInvoke::Invoke<bool>(0x3FEB6AB3, ped); }
	static bool GET_PLAYER_COVER_FACING_LEFT(Player player) { return NativeInvoke::Invoke<bool>(0xD56D622D, player); }
	static bool GET_RANDOM_ENEMY_PED(Ped ped, float p1, float p2, float p3, float p4, bool p5, bool p6, bool p7, bool p8, bool p9, bool p10, Ped* outPed) { return NativeInvoke::Invoke<bool>(0xD48A59F0, ped, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, outPed); }
	static bool GET_RANDOM_NETWORK_RESTART_NODE(float x, float y, float z, float radius, Vector3* coords, int32_t* nodeId) { return NativeInvoke::Invoke<bool>(0x943F64AD, x, y, z, radius, coords, nodeId); }
	static bool GET_RANDOM_NETWORK_RESTART_NODE_USING_GROUP_LIST(float x, float y, float z, float radius, Vector3* coords, int32_t* nodeId) { return NativeInvoke::Invoke<bool>(0xB150397E, x, y, z, radius, coords, nodeId); }
	static bool GET_RANDOM_VEHICLE_NODE(float x, float y, float z, float radius, int32_t p4, bool p5, bool p6, Vector3* coords, int32_t* nodeId) { return NativeInvoke::Invoke<bool>(0xAD1476EA, x, y, z, radius, p4, p5, p6, coords, nodeId); }
	static bool GET_RANDOM_VEHICLE_NODE_INCLUDE_SWITCHED_OFF_NODES(float x, float y, float z, float radius, int32_t p4, bool p5, bool p6, Vector3* coords, int32_t* nodeId) { return NativeInvoke::Invoke<bool>(0x3D6947A3, x, y, z, radius, p4, p5, p6, coords, nodeId); }
	static bool GET_RANDOM_WATER_NODE(float x, float y, float z, float radius, int32_t p4, bool p5, bool p6, Vector3* coords, int32_t* nodeId) { return NativeInvoke::Invoke<bool>(0x869EE56F, x, y, z, radius, p4, p5, p6, coords, nodeId); }
	static bool GET_SAFE_COORD_FOR_PED(float x, float y, float z, bool p3, Vector3* coord) { return NativeInvoke::Invoke<bool>(0xB370270A, x, y, z, p3, coord); }
	static bool GET_SCRIPT_TUNABLE_VARIABLE_CRC_bool(uint32_t tunableHash) { return NativeInvoke::Invoke<bool>(0x29DC159B, tunableHash); }
	static bool GET_SCRIPT_TUNABLE_VARIABLE_bool(const char* context, const char* name) { return NativeInvoke::Invoke<bool>(0x12427628, context, name); }
	static bool GET_SORTED_NETWORK_RESTART_NODE(float x, float y, float z, float radius, Vector3* coords, int32_t* nodeId, int32_t p6, int32_t p7, float p8) { return NativeInvoke::Invoke<bool>(0x002B59A, x, y, z, radius, coords, nodeId, p6, p7, p8); }
	static bool GET_SORTED_NETWORK_RESTART_NODE_USING_GROUP_LIST(float x, float y, float z, float radius, Vector3* coords, int32_t* nodeId, int32_t p6, int32_t p7, float p8) { return NativeInvoke::Invoke<bool>(0x40D4FAA, x, y, z, radius, coords, nodeId, p6, p7, p8); }
	static bool GET_TRAIN_DIRECTION(Vehicle train) { return NativeInvoke::Invoke<bool>(0x8DAF79B6, train); }
	static bool GET_UNLOCK_EXISTS(const char* unlockSemantic) { return NativeInvoke::Invoke<bool>(0x55C1F862, unlockSemantic); }
	static bool GET_UNLOCK_IS_NEW(const char* unlockSemantic) { return NativeInvoke::Invoke<bool>(0xE2158FEF, unlockSemantic); }
	static bool GET_UNLOCK_IS_VISIBLE(const char* unlockSemantic) { return NativeInvoke::Invoke<bool>(0x2BFABD3, unlockSemantic); }
	static bool GET_VEHICLE_MODEL_FROM_INDEX(int32_t index, uint32_t* modelHash) { return NativeInvoke::Invoke<bool>(0x70691B3C, index, modelHash); }
	static bool GET_WATER_HEIGHT(float x, float y, float z, float* height) { return NativeInvoke::Invoke<bool>(0xD864E17C, x, y, z, height); }
	static bool GET_WATER_HEIGHT_NO_WAVES(float x, float y, float z, float* height) { return NativeInvoke::Invoke<bool>(0x262017F8, x, y, z, height); }
	static bool GET_WEAPON_SPAWNS_PICKUP(Weapon weapon) { return NativeInvoke::Invoke<bool>(0xCDFDA942, weapon); }
	static bool GET_XML_NAMED_NODE(const char* nodeName) { return NativeInvoke::Invoke<bool>(0xE5855B5, nodeName); }
	static bool GET_bool_FROM_XML_NODE_ATTRIBUTE(int32_t attributeIndex) { return NativeInvoke::Invoke<bool>(0x2D285BBA, attributeIndex); }
	static bool GIVE_ACHIEVEMENT_TO_PLAYER(int32_t index) { return NativeInvoke::Invoke<bool>(0x822BC992, index); }
	static bool HAS_ACHIEVEMENT_BEEN_PASSED(int32_t index) { return NativeInvoke::Invoke<bool>(0x136A5BE9, index); }
	static bool HAS_ACHIEVEMENT_HASH(int32_t p0) { return NativeInvoke::Invoke<bool>(0xCE0909E9, p0); }
	static bool HAS_ADDITIONAL_TEXT_LOADED(int32_t slot) { return NativeInvoke::Invoke<bool>(0xB0E56045, slot); }
	static bool HAS_ANIM_DICT_LOADED(const char* dictName, bool p1) { return NativeInvoke::Invoke<bool>(0x5E6763C, dictName, p1); }
	static bool HAS_BULLET_IMPACTED_IN_AREA(float x, float y, float z, float radius, Ped* outPed) { return NativeInvoke::Invoke<bool>(0x902BC7D9, x, y, z, radius, outPed); }
	static bool HAS_CLOSEST_OBJECT_OF_TYPE_BEEN_DAMAGED_BY_PED(float x, float y, float z, float radius, uint32_t modelHash, Ped ped) { return NativeInvoke::Invoke<bool>(0x25620891, x, y, z, radius, modelHash, ped); }
	static bool HAS_COLLISION_FOR_MODEL_LOADED(uint32_t modelHash) { return NativeInvoke::Invoke<bool>(0x41A094F8, modelHash); }
	static bool HAS_CUTSCENE_FINISHED() { return NativeInvoke::Invoke<bool>(0x5DED14B4); }
	static bool HAS_CUTSCENE_LOADED() { return NativeInvoke::Invoke<bool>(0xF9998582); }
	static bool HAS_CUTSCENE_UNLOADED() { return NativeInvoke::Invoke<bool>(0x5BBE8974); }
	static bool HAS_DEATHARREST_EXECUTED() { return NativeInvoke::Invoke<bool>(0x6DCD115A); }
	static bool HAS_EXPLORATION_ITEM_BEEN_FOUND(const char* name) { return NativeInvoke::Invoke<bool>(0xE8E8D39B, name); }
	static bool HAS_FRAGMENT_ANY_OF_OBJECT_BEEN_DAMAGED(Object object) { return NativeInvoke::Invoke<bool>(0x2AD2B87, object); }
	static bool HAS_FRAGMENT_ROOT_OF_CLOSEST_OBJECT_OF_TYPE_BEEN_DAMAGED(float x, float y, float z, float radius, uint32_t modelHash) { return NativeInvoke::Invoke<bool>(0x8DF011C, x, y, z, radius, modelHash); }
	static bool HAS_FRAGMENT_ROOT_OF_OBJECT_BEEN_DAMAGED(Object object) { return NativeInvoke::Invoke<bool>(0xD9EA7576, object); }
	static bool HAS_LOAD_JUST_OCCURRED() { return NativeInvoke::Invoke<bool>(0x12F1F57B); }
	static bool HAS_MODEL_LOADED(uint32_t modelHash) { return NativeInvoke::Invoke<bool>(0x62BFDB37, modelHash); }
	static bool HAS_OBJECT_BEEN_DAMAGED(Object object) { return NativeInvoke::Invoke<bool>(0x3B4FB8FD, object); }
	static bool HAS_OBJECT_BEEN_DAMAGED_BY_PED(Object object, Ped ped) { return NativeInvoke::Invoke<bool>(0x730EAA9E, object, ped); }
	static bool HAS_OBJECT_BEEN_DAMAGED_BY_VEHICLE(Object object, Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x7098F746, object, vehicle); }
	static bool HAS_OBJECT_BEEN_UPROOTED(Object object) { return NativeInvoke::Invoke<bool>(0xC220DB67, object); }
	static bool HAS_OBJECT_COLLIDED_WITH_ANYTHING(Object object) { return NativeInvoke::Invoke<bool>(0xD9B3DBC9, object); }
	static bool HAS_OVERRIDEN_SIT_IDLE_ANIM_FINISHED(Ped ped) { return NativeInvoke::Invoke<bool>(0xD8A5D041, ped); }
	static bool HAS_PED_ANIM_FINISHED(Ped ped, const char* animDict, const char* animName) { return NativeInvoke::Invoke<bool>(0xBB6C6A0B, ped, animDict, animName); }
	static bool HAS_PED_BEEN_DAMAGED_BY_PED(Ped ped, Ped ped2, bool p2) { return NativeInvoke::Invoke<bool>(0xEA58F6FB, ped, ped2, p2); }
	static bool HAS_PED_BEEN_DAMAGED_BY_VEHICLE(Ped ped, Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x437430FB, ped, vehicle); }
	static bool HAS_PED_BEEN_DAMAGED_BY_WEAPON(Ped ped, uint32_t weaponHash) { return NativeInvoke::Invoke<bool>(0xCDFBBCC6, ped, weaponHash); }
	static bool HAS_PED_CLEAR_LOS_TO_PED(Ped ped, Ped ped2) { return NativeInvoke::Invoke<bool>(0xED49888E, ped, ped2); }
	static bool HAS_PED_CLEAR_LOS_TO_PED_IN_FRONT(Ped ped, Ped ped2) { return NativeInvoke::Invoke<bool>(0xDDA4D00F, ped, ped2); }
	static bool HAS_PED_CLEAR_LOS_TO_SPHERE(Ped ped, float x, float y, float z, float radius) { return NativeInvoke::Invoke<bool>(0x7D2C95F, ped, x, y, z, radius); }
	static bool HAS_PED_GOT_SPECIFIC_WEAPON(Ped ped, uint32_t weaponHash) { return NativeInvoke::Invoke<bool>(0x8AF064CF, ped, weaponHash); }
	static bool HAS_PED_GOT_WEAPON(Ped ped, uint32_t weaponHash) { return NativeInvoke::Invoke<bool>(0x43D2FA82, ped, weaponHash); }
	static bool HAS_PED_RECORDING_BEEN_LOADED(int32_t recordingIndex) { return NativeInvoke::Invoke<bool>(0xAE24DA83, recordingIndex); }
	static bool HAS_PED_TRIGGERED_MPM(Ped ped) { return NativeInvoke::Invoke<bool>(0x78314008, ped); }
	static bool HAS_PLACEMENT_BEEN_COLLECTED(int32_t index) { return NativeInvoke::Invoke<bool>(0xC516E7D1, index); }
	static bool HAS_PLAYER_DAMAGED_AT_LEAST_ONE_PED(Player player) { return NativeInvoke::Invoke<bool>(0x14F52453, player); }
	static bool HAS_RELOADED_WITH_MOTION_CONTROL(Any p0, Any* p1) { return NativeInvoke::Invoke<bool>(0xE338B363, p0, p1); }
	static bool HAS_SCRIPT_LOADED(const char* name) { return NativeInvoke::Invoke<bool>(0x5D67F751, name); }
	static bool HAS_SELECTED_RETRY_CHECKPOINT() { return NativeInvoke::Invoke<bool>(0x64F307B9); }
	static bool HAS_SHOT_BEEN_FIRED_IN_AREA(float x, float y, float z, float radius, bool p4, Ped* outPed) { return NativeInvoke::Invoke<bool>(0xD08B8C7A, x, y, z, radius, p4, outPed); }
	static bool HAS_SOMETHING_EXPLODED_IN_AREA(float x, float y, float z, float radius) { return NativeInvoke::Invoke<bool>(0x8D098F9F, x, y, z, radius); }
	static bool HAS_SOUND_FINISHED(int32_t soundId) { return NativeInvoke::Invoke<bool>(0xE85AEC2E, soundId); }
	static bool HAS_STREAMED_TEXTURE_DICT_LOADED(const char* dictName) { return NativeInvoke::Invoke<bool>(0x3F436EEF, dictName); }
	static bool HAS_STREAMPED_LOADED(Ped ped) { return NativeInvoke::Invoke<bool>(0x216F12A4, ped); }
	static bool HAS_THIS_ADDITIONAL_TEXT_LOADED(const char* gxt) { return NativeInvoke::Invoke<bool>(0x80A52040, gxt); }
	static bool HAS_VEHICLE_BEEN_DAMAGED_BY_PED(Vehicle vehicle, Ped ped) { return NativeInvoke::Invoke<bool>(0x4C5F25C0, vehicle, ped); }
	static bool HAS_VEHICLE_BEEN_DAMAGED_BY_VEHICLE(Vehicle vehicle, Vehicle vehicle2) { return NativeInvoke::Invoke<bool>(0xBCE93004, vehicle, vehicle2); }
	static bool HAS_VEHICLE_BEEN_DAMAGED_BY_WEAPON(Vehicle vehicle, uint32_t weaponHash) { return NativeInvoke::Invoke<bool>(0xB14B7C18, vehicle, weaponHash); }
	static bool HAS_VEHICLE_BEEN_RESPRAYED(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x22F50111, vehicle); }
	static bool HAS_VEHICLE_GOT_PROJECTILE_ATTACHED(Ped ped, Vehicle vehicle, uint32_t projectileHash) { return NativeInvoke::Invoke<bool>(0xA57E2E80, ped, vehicle, projectileHash); }
	static bool HAS_VEHICLE_RECORDING_BEEN_LOADED(int32_t recordingIndex) { return NativeInvoke::Invoke<bool>(0xF52CD7F5, recordingIndex); }
	static bool HAS_VEHICLE_STOPPED_BECAUSE_OF_LIGHT(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0xCCA89C4C, vehicle); }
	static bool HAS_WEAPON_LOADED(uint32_t weaponHash) { return NativeInvoke::Invoke<bool>(0x4132E42F, weaponHash); }
	static bool HUD_ARE_GANGWARS_ANIMS_COMPLETE() { return NativeInvoke::Invoke<bool>(0x7C4C7D45); }
	static bool ISEQ_DOES_EXIST(uint32_t hash) { return NativeInvoke::Invoke<bool>(0x7AA95EAB, hash); }
	static bool ISEQ_IS_LOADED(uint32_t hash) { return NativeInvoke::Invoke<bool>(0x56DDD872, hash); }
	static bool ISEQ_QUERY_ENTITY_STATE(uint32_t hash, const char* entityName, int32_t state) { return NativeInvoke::Invoke<bool>(0xF6526797, hash, entityName, state); }
	static bool ISEQ_QUERY_STATE(uint32_t hash, int32_t state) { return NativeInvoke::Invoke<bool>(0x64BC279E, hash, state); }
	static bool ISEQ_REGISTER_ENTITY(uint32_t hash, const char* entityName, Entity entity, int32_t entityType) { return NativeInvoke::Invoke<bool>(0xB52B39BB, hash, entityName, entity, entityType); }
	static bool ISTOASTANIMATING() { return NativeInvoke::Invoke<bool>(0x23C45638); }
	static bool IS_2PLAYER_GAME_GOING_ON() { return NativeInvoke::Invoke<bool>(0xD60115D4); }
	static bool IS_ACTION_CONSUMED(int32_t action) { return NativeInvoke::Invoke<bool>(0x2253B4DA, action); }
	static bool IS_ACTION_TREE_LOADED(const char* name) { return NativeInvoke::Invoke<bool>(0x79A8621E, name); }
	static bool IS_AIM_CAM_ACTIVE() { return NativeInvoke::Invoke<bool>(0xC24B4F6F); }
	static bool IS_AMBIENT_SPEECH_DISABLED(Ped ped) { return NativeInvoke::Invoke<bool>(0x109D1F89, ped); } 
	static bool IS_AMBIENT_SPEECH_PLAYING(Ped ped) { return NativeInvoke::Invoke<bool>(0x1972E8AA, ped); } 
	static bool IS_AMED_ENABLED() { return NativeInvoke::Invoke<bool>(0xEA4F2A84); }
	static bool IS_ANIMATED_CAMERA_PLAYING() { return NativeInvoke::Invoke<bool>(0x7FB6E861); }
	static bool IS_ANY_GRENADE_IN_HELPER_BOX(float x1, float y1, float z1, float x2, float y2, float z2) { return NativeInvoke::Invoke<bool>(0x6171AE9F, x1, y1, z1, x2, y2, z2); }
	static bool IS_ANY_PED_SHOOTING_IN_AREA(float x1, float y1, float z1, float x2, float y2, float z2, bool p6, bool p7) { return NativeInvoke::Invoke<bool>(0x91833867, x1, y1, z1, x2, y2, z2, p6, p7); }
	static bool IS_ANY_SPEECH_PLAYING(Ped ped) { return NativeInvoke::Invoke<bool>(0x2B74A6D6, ped); }
	static bool IS_ARCADE_MODE_ACTIVE() { return NativeInvoke::Invoke<bool>(0x93A9462E); }
	static bool IS_AREA_OCCUPIED(float x1, float y1, float z1, float x2, float y2, float z2, bool p6, bool p7, bool p8, bool p9, bool p10) { return NativeInvoke::Invoke<bool>(0xC013972F, x1, y1, z1, x2, y2, z2, p6, p7, p8, p9, p10); }
	static bool IS_AUSSIE_VERSION() { return NativeInvoke::Invoke<bool>(0x944BA1DC); }
	static bool IS_BIG_VEHICLE(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x9CDBA8DE, vehicle); }
	static bool IS_BIT_SET(int32_t data, int32_t bit) { return NativeInvoke::Invoke<bool>(0x902E26AC, data, bit); }
	static bool IS_BLIP_SHORT_RANGE(Blip blip) { return NativeInvoke::Invoke<bool>(0x1226765A, blip); }
	static bool IS_BULLET_CAMERA_ACTIVE() { return NativeInvoke::Invoke<bool>(0xB5B03846); }
	static bool IS_BULLET_CAMERA_RUNNING(bool p0) { return NativeInvoke::Invoke<bool>(0xC0B3AD61, p0); }
	static bool IS_BULLET_CAMERA_SCENE_ACTIVE(Cam cam) { return NativeInvoke::Invoke<bool>(0x5D6EAC4, cam); }
	static bool IS_BULLET_CAMERA_TO_GAMEPLAY_ALLOWED() { return NativeInvoke::Invoke<bool>(0x60EBB1EB); }
	static bool IS_BULLET_CAMERA_WIPE_ENABLED() { return NativeInvoke::Invoke<bool>(0x7E5F8C2D); }
	static bool IS_BULLET_CAMERA_WIPE_STOPPED() { return NativeInvoke::Invoke<bool>(0xB271F669); }
	static bool IS_BULLET_TIME_ACTIVE(bool p0) { return NativeInvoke::Invoke<bool>(0xCDC1B8A3, p0); }
	static bool IS_BUTTON_JUST_PRESSED(int32_t padIndex, int32_t buttonId) { return NativeInvoke::Invoke<bool>(0x7FCD1FA1, padIndex, buttonId); }
	static bool IS_BUTTON_PRESSED(int32_t padIndex, int32_t buttonId) { return NativeInvoke::Invoke<bool>(0x7BCB3F15, padIndex, buttonId); }
	static bool IS_CAMERA_AIMING_AT_ENEMY() { return NativeInvoke::Invoke<bool>(0x7AD6405B); }
	static bool IS_CAM_ACTIVE(Cam cam) { return NativeInvoke::Invoke<bool>(0x4B58F177, cam); }
	static bool IS_CAM_INTERPOLATING(Cam cam) { return NativeInvoke::Invoke<bool>(0x7159CB5D, cam); } 
	static bool IS_CAM_RENDERING(Cam cam) { return NativeInvoke::Invoke<bool>(0x6EC6B5B2, cam); } 
	static bool IS_CAM_SHAKING(Cam cam) { return NativeInvoke::Invoke<bool>(0x961FD9B, cam); }
	static bool IS_COLLECTABLE_ENABLED() { return NativeInvoke::Invoke<bool>(0x473FF184); }
	static bool IS_CONTROL_JUST_PRESSED(int32_t padIndex, int32_t controlId) { return NativeInvoke::Invoke<bool>(0x4487F579, padIndex, controlId); }
	static bool IS_CONTROL_PRESSED(int32_t padIndex, int32_t controlId) { return NativeInvoke::Invoke<bool>(0x517A4384, padIndex, controlId); }
	static bool IS_COP_VEHICLE_IN_AREA_3D(float x1, float y1, float z1, float x2, float y2, float z2) { return NativeInvoke::Invoke<bool>(0xFB16C6D1, x1, y1, z1, x2, y2, z2); }
	static bool IS_CUSTOM_PLAYER_VARIATION() { return NativeInvoke::Invoke<bool>(0x2E325641); }
	static bool IS_DAMAGE_BY_PROJECTILE(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x16BE6900, vehicle); }
	static bool IS_DEATH_PANEL_WIPE_ALLOWED() { return NativeInvoke::Invoke<bool>(0xFA0FC3B6); }
	static bool IS_EXITFLAG_SET(int32_t threadId) { return NativeInvoke::Invoke<bool>(0x687ECC3C, threadId); }
	static bool IS_EXPLOSION_IN_AREA(int32_t explosionType, float x1, float y1, float z1, float x2, float y2, float z2) { return NativeInvoke::Invoke<bool>(0xFB40075B, explosionType, x1, y1, z1, x2, y2, z2); }
	static bool IS_EXPLOSION_IN_SPHERE(int32_t explosionType, float x, float y, float z, float radius) { return NativeInvoke::Invoke<bool>(0xD455A7F3, explosionType, x, y, z, radius); }
	static bool IS_FOLLOW_PED_CAM_ACTIVE() { return NativeInvoke::Invoke<bool>(0x9F9E856C); } 
	static bool IS_FOLLOW_VEHICLE_CAM_ACTIVE() { return NativeInvoke::Invoke<bool>(0x8DD49B77); } 
	static bool IS_FRONTEND_FADING() { return NativeInvoke::Invoke<bool>(0x8FF6232C); }
	static bool IS_GAMEPLAY_CAM_SHAKING(const char* shakeName) { return NativeInvoke::Invoke<bool>(0x3457D681, shakeName); }
	static bool IS_GAMEPLAY_HINT_ACTIVE() { return NativeInvoke::Invoke<bool>(0xAD8DA205); } 
	static bool IS_GAME_IN_CONTROL_OF_MUSIC() { return NativeInvoke::Invoke<bool>(0x7643170D); } 
	static bool IS_GAME_KEYBOARD_KEY_JUST_PRESSED(int32_t key) { return NativeInvoke::Invoke<bool>(0x3FEEBF9C, key); }
	static bool IS_GAME_KEYBOARD_KEY_PRESSED(int32_t key) { return NativeInvoke::Invoke<bool>(0x958135C3, key); }
	static bool IS_GERMAN_VERSION() { return NativeInvoke::Invoke<bool>(0xE023A0AD); }
	static bool IS_GOLDEN_GUN_FINISHED(const char* name) { return NativeInvoke::Invoke<bool>(0xD92C7E81, name); }
	static bool IS_GRIND_COMPLETE(int32_t grindId) { return NativeInvoke::Invoke<bool>(0x81AB05BB, grindId); }
	static bool IS_HELI_PART_BROKEN(Vehicle heli, bool p1, bool p2, bool p3) { return NativeInvoke::Invoke<bool>(0xF4E4C439, heli, p1, p2, p3); }
	static bool IS_HUD_PREFERENCE_SWITCHED_ON() { return NativeInvoke::Invoke<bool>(0xC3BC1B4F); }
	static bool IS_HUD_RETICULE_COMPLEX() { return NativeInvoke::Invoke<bool>(0x9A99C9C7); }
	static bool IS_INTERACTIONTEXT_AVAILABLE() { return NativeInvoke::Invoke<bool>(0x419C48B7); }
	static bool IS_INTERACTIONTEXT_ONSCREEN() { return NativeInvoke::Invoke<bool>(0x22C325FB); }
	static bool IS_INTERIOR_SCENE() { return NativeInvoke::Invoke<bool>(0x55226C13); }
	static bool IS_INTRO_MOVIE_CANCELLED() { return NativeInvoke::Invoke<bool>(0xC5F70C9A); }
	static bool IS_IN_CPCHALLENGE_MODE() { return NativeInvoke::Invoke<bool>(0xE43D4E47); }
	static bool IS_IN_NYMINUTE_MODE() { return NativeInvoke::Invoke<bool>(0x62AE43CB); }
	static bool IS_IN_NYM_HARDCORE_MODE() { return NativeInvoke::Invoke<bool>(0x45C22E47); }
	static bool IS_IN_SCORE_ATTACK_MODE() { return NativeInvoke::Invoke<bool>(0x37A598E6); }
	static bool IS_IN_SOUTHPAW_MODE() { return NativeInvoke::Invoke<bool>(0x18D7934F); }
	static bool IS_IN_SPECTATOR_MODE() { return NativeInvoke::Invoke<bool>(0x1A8853B0); }
	static bool IS_IN_STORY_MODE() { return NativeInvoke::Invoke<bool>(0x442DD86B); }
	static bool IS_JAPANESE_GAME() { return NativeInvoke::Invoke<bool>(0x4F2A77E3); }
	static bool IS_KEYBOARD_KEY_JUST_PRESSED(int32_t key) { return NativeInvoke::Invoke<bool>(0xEAC23998, key); }
	static bool IS_KEYBOARD_KEY_PRESSED(int32_t key) { return NativeInvoke::Invoke<bool>(0xA644ED03, key); }
	static bool IS_LAST_MAN_STANDING_ACTIVE() { return NativeInvoke::Invoke<bool>(0xB9087B11); }
	static bool IS_LAST_MAN_STAND_ANIMATED_RECOVERY_BEING_HELD() { return NativeInvoke::Invoke<bool>(0x76DDD1A5); }
	static bool IS_LEFT_VEHICLE_HEADLIGHT_BROKEN(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x49A6D893, vehicle); }
	static bool IS_LMS_TUTORIAL_COMPLETE() { return NativeInvoke::Invoke<bool>(0x8357057A); }
	static bool IS_LOADOUT_SLOT_AVAILABLE(int32_t slot) { return NativeInvoke::Invoke<bool>(0xFA76A13A, slot); }
	static bool IS_LOADOUT_VALID(int32_t index) { return NativeInvoke::Invoke<bool>(0x5ACBCBF0, index); }
	static bool IS_LOCAL_PLAYER_IN_SOCIAL_CLUB() { return NativeInvoke::Invoke<bool>(0x167AF0DF); }
	static bool IS_LOCAL_PLAYER_SPRINTING() { return NativeInvoke::Invoke<bool>(0x4D6AC4DF); }
	static bool IS_LOCAL_PLAYER_STILL_SCANNING_WORLD() { return NativeInvoke::Invoke<bool>(0x6AADAD69); }
	static bool IS_LOOK_INVERTED() { return NativeInvoke::Invoke<bool>(0x313434B2); }
	static bool IS_MAGDEMO() { return NativeInvoke::Invoke<bool>(0x6A50485A); }
	static bool IS_MARKETING_KEYBOARD_KEY_JUST_PRESSED(int32_t key) { return NativeInvoke::Invoke<bool>(0xBA00B7F4, key); }
	static bool IS_MESSAGE_BEING_DISPLAYED() { return NativeInvoke::Invoke<bool>(0x6A77FE8D); }
	static bool IS_MINIGAME_IN_PROGRESS() { return NativeInvoke::Invoke<bool>(0x53A95E13); }
	static bool IS_MODEL_A_PED(uint32_t modelHash) { return NativeInvoke::Invoke<bool>(0x4B933365, modelHash); }
	static bool IS_MODEL_A_VEHICLE(uint32_t modelHash) { return NativeInvoke::Invoke<bool>(0xFFFC85D4, modelHash); }
	static bool IS_MODEL_IN_CDIMAGE(uint32_t modelHash) { return NativeInvoke::Invoke<bool>(0x1094782F, modelHash); }
	static bool IS_MONOLOGUE_PLAYING() { return NativeInvoke::Invoke<bool>(0xF6006ECB); }
	static bool IS_MP_TUTORIAL_MESSAGES_SHOWN() { return NativeInvoke::Invoke<bool>(0xF501D241); }
	static bool IS_NETWORK_SESSION() { return NativeInvoke::Invoke<bool>(0x1D8FEF54); }
	static bool IS_NEW_GAME_REQUESTED() { return NativeInvoke::Invoke<bool>(0xF994E7DC); }
	static bool IS_NON_FRAG_OBJECT_SMASHED(float x, float y, float z, float radius, uint32_t modelHash) { return NativeInvoke::Invoke<bool>(0xF7AE77B6, x, y, z, radius, modelHash); }
	static bool IS_OBJECT_ATTACHED(Object object) { return NativeInvoke::Invoke<bool>(0xAD08BA79, object); }
	static bool IS_OBJECT_AT_COORD(Object object, float p1, float p2, float p3, float p4, float p5, float p6, bool p7, bool p8) { return NativeInvoke::Invoke<bool>(0xC1C0A8B, object, p1, p2, p3, p4, p5, p6, p7, p8); }
	static bool IS_OBJECT_FIXED_WAITING_FOR_COLLISION(Object object) { return NativeInvoke::Invoke<bool>(0x56AD22D0, object); }
	static bool IS_OBJECT_IN_ANGLED_AREA(Object object, float x1, float y1, float z1, float x2, float y2, float z2, float p7, bool p8, bool p9) { return NativeInvoke::Invoke<bool>(0xABF09CB4, object, x1, y1, z1, x2, y2, z2, p7, p8, p9); }
	static bool IS_OBJECT_IN_AREA(Object object, float x1, float y1, float z1, float x2, float y2, float z2, bool p7, bool p8) { return NativeInvoke::Invoke<bool>(0x3DDBD2DE, object, x1, y1, z1, x2, y2, z2, p7, p8); }
	static bool IS_OBJECT_IN_CROSSHAIR_CYLINDER(Object object, float p1, float p2, bool p3) { return NativeInvoke::Invoke<bool>(0xBA48CEA, object, p1, p2, p3); }
	static bool IS_OBJECT_IN_GAMEPLAY_HELPER_BOX(Object object, const char* boxName) { return NativeInvoke::Invoke<bool>(0xB51CBB2F, object, boxName); }
	static bool IS_OBJECT_IN_WATER(Object object) { return NativeInvoke::Invoke<bool>(0xEB448F66, object); }
	static bool IS_OBJECT_ON_FIRE(Object object) { return NativeInvoke::Invoke<bool>(0xAC830162, object); }
	static bool IS_OBJECT_ON_SCREEN(Object object) { return NativeInvoke::Invoke<bool>(0x2AE883EB, object); }
	static bool IS_OBJECT_PLAYING_ANIM(Object object, const char* animName, const char* animDict) { return NativeInvoke::Invoke<bool>(0x8CA17B14, object, animName, animDict); }
	static bool IS_OBJECT_REASSIGNMENT_IN_PROGRESS() { return NativeInvoke::Invoke<bool>(0x127EE29C); }
	static bool IS_OBJECT_STATIC(Object object) { return NativeInvoke::Invoke<bool>(0x49A1DD0E, object); }
	static bool IS_OBJECT_UPRIGHT(Object object, float p1) { return NativeInvoke::Invoke<bool>(0x45D7281E, object, p1); }
	static bool IS_OBJECT_WITHIN_BRAIN_ACTIVATION_RANGE(Object object) { return NativeInvoke::Invoke<bool>(0xBA4CAA56, object); }
	static bool IS_PAUSE_MENU_ACTIVE() { return NativeInvoke::Invoke<bool>(0xD3600591); }
	static bool IS_PC_BUILD() { return NativeInvoke::Invoke<bool>(0xE6A62D57); }
	static bool IS_PED_ARMED(Ped ped) { return NativeInvoke::Invoke<bool>(0xBFC892C, ped); }
	static bool IS_PED_ATTACHED_TO_ANY_VEHICLE(Ped ped) { return NativeInvoke::Invoke<bool>(0x679A04D, ped); }
	static bool IS_PED_ATTACHED_TO_OBJECT(Ped ped, Object object) { return NativeInvoke::Invoke<bool>(0xEA085F14, ped, object); }
	static bool IS_PED_AT_COORD(Ped ped, float x1, float y1, float z1, float x2, float y2, float z2, bool p7, int32_t p8) { return NativeInvoke::Invoke<bool>(0x2DCD8806, ped, x1, y1, z1, x2, y2, z2, p7, p8); }
	static bool IS_PED_AT_OBJECT(Ped ped, Object object, float p2, float p3, float p4, bool p5, int32_t p6) { return NativeInvoke::Invoke<bool>(0x7CE82D5F, ped, object, p2, p3, p4, p5, p6); }
	static bool IS_PED_AT_PED(Ped ped, Ped ped2, float p2, float p3, float p4, bool p5, int32_t p6) { return NativeInvoke::Invoke<bool>(0xCD0373CE, ped, ped2, p2, p3, p4, p5, p6); }
	static bool IS_PED_AT_VEHICLE(Ped ped, Vehicle vehicle, float p2, float p3, float p4, bool p5, int32_t p6) { return NativeInvoke::Invoke<bool>(0xA9191096, ped, vehicle, p2, p3, p4, p5, p6); }
	static bool IS_PED_A_MISSION_PED(Ped ped) { return NativeInvoke::Invoke<bool>(0xB653748D, ped); }
	static bool IS_PED_BEING_GRAPPLED(Ped ped) { return NativeInvoke::Invoke<bool>(0x67C09EDB, ped); }
	static bool IS_PED_BEING_JACKED(Ped ped) { return NativeInvoke::Invoke<bool>(0xD45D605C, ped); }
	static bool IS_PED_BLINDFIRING_IN_COVER(Ped ped) { return NativeInvoke::Invoke<bool>(0x12A8D4BA, ped); }
	static bool IS_PED_CLONED_EVERYWHERE(Ped ped) { return NativeInvoke::Invoke<bool>(0xEBA43DE8, ped); }
	static bool IS_PED_DEAD(Ped ped) { return NativeInvoke::Invoke<bool>(0xF990EBB2, ped); }
	static bool IS_PED_DOING_DRIVEBY(Ped ped) { return NativeInvoke::Invoke<bool>(0xAC3CEB9C, ped); }
	static bool IS_PED_DUAL_WIELDING(Ped ped) { return NativeInvoke::Invoke<bool>(0x3418403, ped); }
	static bool IS_PED_DUCKING(Ped ped) { return NativeInvoke::Invoke<bool>(0x9199C77D, ped); }
	static bool IS_PED_FACING_PED(Ped ped, Ped ped2, float angle) { return NativeInvoke::Invoke<bool>(0xB775838, ped, ped2, angle); }
	static bool IS_PED_FATALLY_INJURED(Ped ped) { return NativeInvoke::Invoke<bool>(0xBADA0093, ped); }
	static bool IS_PED_FLEEING(Ped ped) { return NativeInvoke::Invoke<bool>(0x85D813C6, ped); }
	static bool IS_PED_GESTURING(Ped ped) { return NativeInvoke::Invoke<bool>(0x28ADE9BC, ped); }
	static bool IS_PED_GETTING_INTO_A_VEHICLE(Ped ped) { return NativeInvoke::Invoke<bool>(0x90E805AC, ped); }
	static bool IS_PED_GETTING_UP(Ped ped) { return NativeInvoke::Invoke<bool>(0x320813E6, ped); }
	static bool IS_PED_GROUP_LEADER(Ped ped, Group group) { return NativeInvoke::Invoke<bool>(0xC8A9FB5A, ped, group); }
	static bool IS_PED_GROUP_MEMBER(Ped ped, Group group) { return NativeInvoke::Invoke<bool>(0x876D5363, ped, group); }
	static bool IS_PED_HEADTRACKING_PED(Ped ped1, Ped ped2) { return NativeInvoke::Invoke<bool>(0x2A5DF721, ped1, ped2); }
	static bool IS_PED_HIDING_IN_COVER(Ped ped) { return NativeInvoke::Invoke<bool>(0x931B95B5, ped); }
	static bool IS_PED_INJURED(Ped ped) { return NativeInvoke::Invoke<bool>(0x2530A087, ped); }
	static bool IS_PED_INSIDE_TRAIN(Ped ped, Vehicle train) { return NativeInvoke::Invoke<bool>(0x84D170A5, ped, train); }
	static bool IS_PED_INVESTIGATING(Ped ped) { return NativeInvoke::Invoke<bool>(0x53806A49, ped); }
	static bool IS_PED_IN_AIR(Ped ped) { return NativeInvoke::Invoke<bool>(0xD0060B64, ped); }
	static bool IS_PED_IN_ANGLED_AREA(Ped ped, float x1, float y1, float z1, float x2, float y2, float z2, float angle, bool p8, int32_t p9) { return NativeInvoke::Invoke<bool>(0x67D32AF9, ped, x1, y1, z1, x2, y2, z2, angle, p8, p9); }
	static bool IS_PED_IN_ANY_BOAT(Ped ped) { return NativeInvoke::Invoke<bool>(0x1118A947, ped); }
	static bool IS_PED_IN_ANY_HELI(Ped ped) { return NativeInvoke::Invoke<bool>(0x7AB5523B, ped); }
	static bool IS_PED_IN_ANY_PLANE(Ped ped) { return NativeInvoke::Invoke<bool>(0x51BBCE7E, ped); }
	static bool IS_PED_IN_ANY_POLICE_VEHICLE(Ped ped) { return NativeInvoke::Invoke<bool>(0x84FA790D, ped); }
	static bool IS_PED_IN_ANY_TAXI(Ped ped) { return NativeInvoke::Invoke<bool>(0x16FD386C, ped); }
	static bool IS_PED_IN_ANY_TRAIN(Ped ped) { return NativeInvoke::Invoke<bool>(0x759EF63A, ped); }
	static bool IS_PED_IN_ANY_VEHICLE(Ped ped) { return NativeInvoke::Invoke<bool>(0x3B0171EE, ped); }
	static bool IS_PED_IN_AREA(Ped ped, float x1, float y1, float z1, float x2, float y2, float z2, bool p7, int32_t p8) { return NativeInvoke::Invoke<bool>(0x1B4FD43E, ped, x1, y1, z1, x2, y2, z2, p7, p8); }
	static bool IS_PED_IN_COMBAT(Ped ped) { return NativeInvoke::Invoke<bool>(0xFE027CB5, ped); }
	static bool IS_PED_IN_COVER(Ped ped) { return NativeInvoke::Invoke<bool>(0x972C5A8B, ped); }
	static bool IS_PED_IN_CROSSHAIR_CONE(Ped ped, float p1, float p2) { return NativeInvoke::Invoke<bool>(0x21C18EA9, ped, p1, p2); }
	static bool IS_PED_IN_CROSSHAIR_CYLINDER(Ped ped, float p1, float p2, bool p3, float p4) { return NativeInvoke::Invoke<bool>(0xC98A0FFA, ped, p1, p2, p3, p4); }
	static bool IS_PED_IN_CROSSHAIR_CYLINDER_OFFSET(Ped ped, float p1, float p2, float p3, float p4, float p5, float p6, bool p7) { return NativeInvoke::Invoke<bool>(0xCA2F07C7, ped, p1, p2, p3, p4, p5, p6, p7); }
	static bool IS_PED_IN_FLYING_VEHICLE(Ped ped) { return NativeInvoke::Invoke<bool>(0xCA072485, ped); }
	static bool IS_PED_IN_GAMEPLAY_HELPER_BOX(Ped ped, const char* name) { return NativeInvoke::Invoke<bool>(0xEEC61845, ped, name); }
	static bool IS_PED_IN_GAMEPLAY_HELPER_VOLUME(Ped ped, const char* name) { return NativeInvoke::Invoke<bool>(0xF6AC4889, ped, name); }
	static bool IS_PED_IN_GROUP(Ped ped, Group group) { return NativeInvoke::Invoke<bool>(0x836D9795, ped, group); }
	static bool IS_PED_IN_MELEE_COMBAT(Ped ped) { return NativeInvoke::Invoke<bool>(0xFD7814A5, ped); }
	static bool IS_PED_IN_MODEL(Ped ped, uint32_t modelHash) { return NativeInvoke::Invoke<bool>(0xA6438D4B, ped, modelHash); }
	static bool IS_PED_IN_SEAMLESS_TRIGGER_AREA() { return NativeInvoke::Invoke<bool>(0xF6589F70); }
	static bool IS_PED_IN_SPHERE_AREA_OF_ANY_ENEMY_PEDS(Ped ped, float x, float y, float z, float radius, bool p5) { return NativeInvoke::Invoke<bool>(0xA76F4AE, ped, x, y, z, radius, p5); }
	static bool IS_PED_IN_VEHICLE(Ped ped, Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x7DA6BC83, ped, vehicle); }
	static bool IS_PED_IN_WATER(Ped ped) { return NativeInvoke::Invoke<bool>(0x2A7FBBDF, ped); }
	static bool IS_PED_IN_ZONE(Ped ped, const char* zoneName) { return NativeInvoke::Invoke<bool>(0x4EECB942, ped, zoneName); }
	static bool IS_PED_JACKING(Ped ped) { return NativeInvoke::Invoke<bool>(0x3B321816, ped); }
	static bool IS_PED_LOS_CLEAR_TO_TARGET_PED(Ped ped, Ped ped2) { return NativeInvoke::Invoke<bool>(0xBEE1E2F1, ped, ped2); }
	static bool IS_PED_MALE(Ped ped) { return NativeInvoke::Invoke<bool>(0x90950455, ped); }
	static bool IS_PED_MODEL(Ped ped, uint32_t modelHash) { return NativeInvoke::Invoke<bool>(0x5F1DDFCB, ped, modelHash); }
	static bool IS_PED_ON_ANY_BIKE(Ped ped) { return NativeInvoke::Invoke<bool>(0x4D885B2E, ped); }
	static bool IS_PED_ON_FIRE(Ped ped) { return NativeInvoke::Invoke<bool>(0x5EC1A4D3, ped); }
	static bool IS_PED_ON_FOOT(Ped ped) { return NativeInvoke::Invoke<bool>(0xC60D0785, ped); }
	static bool IS_PED_ON_SCREEN(Ped ped, bool unk) { return NativeInvoke::Invoke<bool>(0xDF7C1119, ped, unk); }
	static bool IS_PED_PEEKING_IN_COVER(Ped ped) { return NativeInvoke::Invoke<bool>(0xA612B87E, ped); }
	static bool IS_PED_PICKING_UP_PICKUP(Ped ped) { return NativeInvoke::Invoke<bool>(0xC213D3FA, ped); }
	static bool IS_PED_PLAYING_ANIM(Ped ped, const char* animDict, const char* animName) { return NativeInvoke::Invoke<bool>(0xC504868, ped, animDict, animName); }
	static bool IS_PED_PROCESSING_FROZEN(Ped ped) { return NativeInvoke::Invoke<bool>(0xE1203F37, ped); }
	static bool IS_PED_RAGDOLL(Ped ped, bool p1) { return NativeInvoke::Invoke<bool>(0xC833BBE1, ped, p1); }
	static bool IS_PED_RELOADING(Ped ped) { return NativeInvoke::Invoke<bool>(0x961E1745, ped); }
	static bool IS_PED_RESPONDING_TO_EVENT(Ped ped, int32_t event) { return NativeInvoke::Invoke<bool>(0x7A877554, ped, event); }
	static bool IS_PED_RETREATING(Ped ped) { return NativeInvoke::Invoke<bool>(0x27240BFE, ped); }
	static bool IS_PED_RUNNING_TASK(Ped ped, int32_t task) { return NativeInvoke::Invoke<bool>(0x10BF1163, ped, task); }
	static bool IS_PED_SHOOTING(Ped ped) { return NativeInvoke::Invoke<bool>(0xE7C3405E, ped); }
	static bool IS_PED_SHOOTING_IN_AREA(Ped ped, float x1, float y1, float z1, float x2, float y2, float z2, bool p7, bool p8) { return NativeInvoke::Invoke<bool>(0x741BF04F, ped, x1, y1, z1, x2, y2, z2, p7, p8); }
	static bool IS_PED_SITTING_IDLE(Ped ped) { return NativeInvoke::Invoke<bool>(0x98F2F27D, ped); }
	static bool IS_PED_SITTING_IN_ANY_VEHICLE(Ped ped) { return NativeInvoke::Invoke<bool>(0xEA9CA03, ped); }
	static bool IS_PED_SITTING_IN_VEHICLE(Ped ped, Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0xDDDE26FA, ped, vehicle); }
	static bool IS_PED_STOPPED(Ped ped) { return NativeInvoke::Invoke<bool>(0xA0DC0B87, ped); }
	static bool IS_PED_STUCK_UNDER_VEHICLE(Ped ped) { return NativeInvoke::Invoke<bool>(0x2645971C, ped); }
	static bool IS_PED_SWIMMING(Ped ped) { return NativeInvoke::Invoke<bool>(0x7AB43DB8, ped); }
	static bool IS_PED_TOUCHING_OBJECT(Ped ped, Object object) { return NativeInvoke::Invoke<bool>(0xA82C348, ped, object); }
	static bool IS_PED_TOUCHING_PED(Ped ped, Ped ped2) { return NativeInvoke::Invoke<bool>(0x12C5484A, ped, ped2); }
	static bool IS_PED_TOUCHING_VEHICLE(Ped ped, Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x22D9AC0C, ped, vehicle); }
	static bool IS_PED_TRYING_TO_ENTER_A_LOCKED_VEHICLE(Ped ped) { return NativeInvoke::Invoke<bool>(0x46828B4E, ped); }
	static bool IS_PED_USING_ANY_SCENARIO(Ped ped) { return NativeInvoke::Invoke<bool>(0x195EF5B7, ped); }
	static bool IS_PED_USING_MP3_COVER_TASK(Ped ped) { return NativeInvoke::Invoke<bool>(0x3ACBC86C, ped); }
	static bool IS_PED_USING_SCENARIO(Ped ped, const char* scenarioName) { return NativeInvoke::Invoke<bool>(0xF65B0D4, ped, scenarioName); }
	static bool IS_PED_VAULTING(Ped ped) { return NativeInvoke::Invoke<bool>(0xC3169BDA, ped); }
	static bool IS_PED_VISIBLE(Ped ped) { return NativeInvoke::Invoke<bool>(0xE285085A, ped); }
	static bool IS_PED_WAITING_FOR_WORLD_COLLISION(Ped ped) { return NativeInvoke::Invoke<bool>(0x28BCF200, ped); }
	static bool IS_PICKUP_CONSUMED(int32_t pickup) { return NativeInvoke::Invoke<bool>(0x21F50584, pickup); }
	static bool IS_PLAYBACK_GOING_ON_FOR_PED(Ped ped) { return NativeInvoke::Invoke<bool>(0xEAD70A7A, ped); }
	static bool IS_PLAYBACK_GOING_ON_FOR_VEHICLE(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x61F7650D, vehicle); }
	static bool IS_PLAYBACK_USING_AI_GOING_ON_FOR_VEHICLE(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x63022C58, vehicle); }
	static bool IS_PLAYER_BEING_ARRESTED() { return NativeInvoke::Invoke<bool>(0x7F6A60D3); }
	static bool IS_PLAYER_CLIMBING(Player player) { return NativeInvoke::Invoke<bool>(0x4A9E9AE0, player); }
	static bool IS_PLAYER_CONTROL_ON(Player player) { return NativeInvoke::Invoke<bool>(0x618857F2, player); }
	static bool IS_PLAYER_DEAD(Player player) { return NativeInvoke::Invoke<bool>(0x140CA5A8, player); }
	static bool IS_PLAYER_DOING_MELEE_GRAPPLE(Player player) { return NativeInvoke::Invoke<bool>(0x5EECF4E4, player); }
	static bool IS_PLAYER_FREE_AIMING_AT_PED(Player player, Ped ped) { return NativeInvoke::Invoke<bool>(0x571529AE, player, ped); }
	static bool IS_PLAYER_FREE_FOR_AMBIENT_TASK(Player player) { return NativeInvoke::Invoke<bool>(0x85C7E232, player); }
	static bool IS_PLAYER_GUN_RAISED(Player player) { return NativeInvoke::Invoke<bool>(0x94985FF7, player); }
	static bool IS_PLAYER_LOCKED_IN_COVER(Player player) { return NativeInvoke::Invoke<bool>(0x78A1970D, player); }
	static bool IS_PLAYER_LOGGING_IN_NP() { return NativeInvoke::Invoke<bool>(0x8F72FAD0); }
	static bool IS_PLAYER_ONLINE() { return NativeInvoke::Invoke<bool>(0x9FAB6729); }
	static bool IS_PLAYER_ONLINE_GAMESPY() { return NativeInvoke::Invoke<bool>(0x86D608A4); }
	static bool IS_PLAYER_ONLINE_NP() { return NativeInvoke::Invoke<bool>(0x41FAD3E2); }
	static bool IS_PLAYER_PED_FREE_AIMING_AT_PED(Ped playerPed, Ped ped) { return NativeInvoke::Invoke<bool>(0x8E8B926C, playerPed, ped); }
	static bool IS_PLAYER_PISSED_OFF(Player player) { return NativeInvoke::Invoke<bool>(0x21A65E2F, player); }
	static bool IS_PLAYER_PLAYING(Player player) { return NativeInvoke::Invoke<bool>(0xE15D777F, player); }
	static bool IS_PLAYER_PRESSING_HORN(Player player) { return NativeInvoke::Invoke<bool>(0xED1D1662, player); }
	static bool IS_PLAYER_READY_FOR_CUTSCENE(Player player) { return NativeInvoke::Invoke<bool>(0xBB77E9CD, player); }
	static bool IS_PLAYER_SCORE_GREATER(Player player, int32_t score) { return NativeInvoke::Invoke<bool>(0xFA624B66, player, score); }
	static bool IS_PLAYER_SCRIPT_CONTROL_ON(Player player) { return NativeInvoke::Invoke<bool>(0x61B00A84, player); }
	static bool IS_PLAYER_SHOOTDODGING() { return NativeInvoke::Invoke<bool>(0xEEA47566); }
	static bool IS_PLAYER_TARGETTING_ANYTHING(Player player) { return NativeInvoke::Invoke<bool>(0x456DB50D, player); }
	static bool IS_PLAYER_TARGETTING_OBJECT(Player player, Object object) { return NativeInvoke::Invoke<bool>(0x622796D5, player, object); }
	static bool IS_PLAYER_TARGETTING_PED(Player player, Ped ped) { return NativeInvoke::Invoke<bool>(0xDBE470DD, player, ped); }
	static bool IS_POINT_OBSCURED_BY_A_MISSION_ENTITY(float x1, float y1, float z1, float x2, float y2, float z2) { return NativeInvoke::Invoke<bool>(0xC161558D, x1, y1, z1, x2, y2, z2); }
	static bool IS_QUIT_CONFIRMING() { return NativeInvoke::Invoke<bool>(0xDBA589AE); }
	static bool IS_RECORDING_GOING_ON_FOR_PED(Ped ped) { return NativeInvoke::Invoke<bool>(0x520CCC09, ped); }
	static bool IS_RECORDING_GOING_ON_FOR_VEHICLE(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x19F57601, vehicle); }
	static bool IS_RESTARTCHECKPOINT_DISABLED_BY_SCRIPT() { return NativeInvoke::Invoke<bool>(0x6F67E592); }
	static bool IS_RESTARTING_FE_FOR_NEW_GAME() { return NativeInvoke::Invoke<bool>(0x7D3CB0CB); }
	static bool IS_RIGHT_VEHICLE_HEADLIGHT_BROKEN(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x9D508577, vehicle); }
	static bool IS_ROBO_TESTING() { return NativeInvoke::Invoke<bool>(0x326798C); }
	static bool IS_ROCKET_IN_FLIGHT() { return NativeInvoke::Invoke<bool>(0x2EC8C1B9); }
	static bool IS_SAFE_TO_KILL_PLAYER() { return NativeInvoke::Invoke<bool>(0x6702E169); }
	static bool IS_SCREEN_FADED_IN() { return NativeInvoke::Invoke<bool>(0x4F37276D); }
	static bool IS_SCREEN_FADED_OUT() { return NativeInvoke::Invoke<bool>(0x9CAA05FA); }
	static bool IS_SCREEN_FADING_IN() { return NativeInvoke::Invoke<bool>(0xC7C82800); }
	static bool IS_SCREEN_FADING_OUT() { return NativeInvoke::Invoke<bool>(0x79275A57); }
	static bool IS_SCRIPTEDFX_ENABLED() { return NativeInvoke::Invoke<bool>(0x36B7B213); }
	static bool IS_SCRIPTED_SPEECH_PLAYING(Ped ped) { return NativeInvoke::Invoke<bool>(0x2C653904, ped); }
	static bool IS_SCRIPT_AUDIO_BANK_LOADED(const char* name, bool p1) { return NativeInvoke::Invoke<bool>(0x8CCF6840, name, p1); }
	static bool IS_SCRIPT_DATABASE_BOUND(const char* name) { return NativeInvoke::Invoke<bool>(0x9168F4B2, name); }
	static bool IS_SCRIPT_MOVIE_PLAYING(int32_t p0) { return NativeInvoke::Invoke<bool>(0x772006AE, p0); }
	static bool IS_SITTING_OBJECT_NEAR(float x, float y, float z, uint32_t modelHash) { return NativeInvoke::Invoke<bool>(0xD81F06C2, x, y, z, modelHash); }
	static bool IS_SNIPER_INVERTED() { return NativeInvoke::Invoke<bool>(0x5C3BF51B); }
	static bool IS_SNIPER_SCOPE_VISIBLE() { return NativeInvoke::Invoke<bool>(0xBC59557E); }
	static bool IS_SPHERE_VISIBLE(float x, float y, float z, float radius, bool p4) { return NativeInvoke::Invoke<bool>(0xDD1329E2, x, y, z, radius, p4); }
	static bool IS_SPHERE_VISIBLE_TO_ANOTHER_MACHINE(float x, float y, float z, float radius) { return NativeInvoke::Invoke<bool>(0x23C5274E, x, y, z, radius); }
	static bool IS_SP_LEVEL_REPLAY() { return NativeInvoke::Invoke<bool>(0x842386F7); }
	static bool IS_STAT_FLOAT(const char* statName) { return NativeInvoke::Invoke<bool>(0xE0AB836, statName); }
	static bool IS_STAT_HASH_FLOAT(uint32_t statHash) { return NativeInvoke::Invoke<bool>(0xEF26133B, statHash); }
	static bool IS_STREAMING_ADDITIONAL_TEXT(int32_t slot) { return NativeInvoke::Invoke<bool>(0xF079E4EB, slot); }
	static bool IS_STREAMING_PRIORITY_REQUESTS() { return NativeInvoke::Invoke<bool>(0xD2E1E5DC); }
	static bool IS_STRING_NULL(const char* str) { return NativeInvoke::Invoke<bool>(0x8E71E00F, str); }
	static bool IS_SYSTEM_UI_BEING_DISPLAYED() { return NativeInvoke::Invoke<bool>(0xE495B6DA); }
	static bool IS_TARGET_IN_VALID_COVER_FROM_PED(Ped ped, Ped ped2) { return NativeInvoke::Invoke<bool>(0x7DFDA8DA, ped, ped2); }
	static bool IS_TAXI_LIGHT_ON(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x6FC4924A, vehicle); }
	static bool IS_TEXT_FONT_LOADED(int32_t font) { return NativeInvoke::Invoke<bool>(0xD82F8828, font); }
	static bool IS_THIS_A_MINIGAME_SCRIPT() { return NativeInvoke::Invoke<bool>(0x7605EF6F); }
	static bool IS_THIS_MODEL_A_BIKE(uint32_t modelHash) { return NativeInvoke::Invoke<bool>(0x7E702CDD, modelHash); }
	static bool IS_THIS_MODEL_A_BOAT(uint32_t modelHash) { return NativeInvoke::Invoke<bool>(0x10F6085C, modelHash); }
	static bool IS_THIS_MODEL_A_CAR(uint32_t modelHash) { return NativeInvoke::Invoke<bool>(0x60E4C22F, modelHash); }
	static bool IS_THIS_MODEL_A_HELI(uint32_t modelHash) { return NativeInvoke::Invoke<bool>(0x8AF7F568, modelHash); }
	static bool IS_THIS_MODEL_A_PLANE(uint32_t modelHash) { return NativeInvoke::Invoke<bool>(0x3B3907BB, modelHash); }
	static bool IS_THIS_MODEL_A_TRAIN(uint32_t modelHash) { return NativeInvoke::Invoke<bool>(0xF87DCFFD, modelHash); }
	static bool IS_THIS_THREAD_CONNECTED(int32_t threadId) { return NativeInvoke::Invoke<bool>(0x5DE08B39, threadId); }
	static bool IS_THIS_THREAD_ISOLATED(int32_t threadId) { return NativeInvoke::Invoke<bool>(0x79C9D9AF, threadId); }
	static bool IS_THREAD_ACTIVE(int32_t threadId) { return NativeInvoke::Invoke<bool>(0x78D7A5A0, threadId); }
	static bool IS_THROWN_WEAPON(uint32_t weaponHash) { return NativeInvoke::Invoke<bool>(0x48EF964A, weaponHash); }
	static bool IS_TICKER_ACTIVITY_HIGH() { return NativeInvoke::Invoke<bool>(0x4BC91752); }
	static bool IS_TICKER_ACTIVITY_LOW() { return NativeInvoke::Invoke<bool>(0x238BCCB6); }
	static bool IS_TIME_OF_DAY_FROZEN() { return NativeInvoke::Invoke<bool>(0xE78ED130); }
	static bool IS_TRANSITION_MOVIE_PLAYING() { return NativeInvoke::Invoke<bool>(0x66BD2CB0); }
	static bool IS_TUTORIAL_COMPLETE() { return NativeInvoke::Invoke<bool>(0xB1E326FE); }
	static bool IS_USING_ANIMATED_LAST_MAN_STANDING() { return NativeInvoke::Invoke<bool>(0xC98EAAFC); }
	static bool IS_USING_CONTROLLER() { return NativeInvoke::Invoke<bool>(0x19064ED); }
	static bool IS_VEHICLE_ATTACHED(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x65ECB112, vehicle); }
	static bool IS_VEHICLE_AT_COORD(Vehicle vehicle, float xPos, float yPos, float zPos, float xSize, float ySize, float zSize, bool p7, bool p8) { return NativeInvoke::Invoke<bool>(0x8BC9D2F9, vehicle, xPos, yPos, zPos, xSize, ySize, zSize, p7, p8); }
	static bool IS_VEHICLE_A_MISSION_VEHICLE(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x7716B579, vehicle); }
	static bool IS_VEHICLE_DEAD(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x95D58E26, vehicle); }
	static bool IS_VEHICLE_DOOR_DAMAGED(Vehicle vehicle, int32_t door) { return NativeInvoke::Invoke<bool>(0x4999E3C3, vehicle, door); }
	static bool IS_VEHICLE_DOOR_FULLY_OPEN(Vehicle vehicle, int32_t door) { return NativeInvoke::Invoke<bool>(0xC2385B6F, vehicle, door); }
	static bool IS_VEHICLE_DRIVEABLE(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x41A7267A, vehicle); }
	static bool IS_VEHICLE_EXTRA_TURNED_ON(Vehicle vehicle, int32_t extra) { return NativeInvoke::Invoke<bool>(0x42098B5, vehicle, extra); }
	static bool IS_VEHICLE_IN_AIR_PROPER(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x36DA3EB9, vehicle); }
	static bool IS_VEHICLE_IN_AREA(Vehicle vehicle, float x1, float y1, float z1, float x2, float y2, float z2, bool p7, bool p8) { return NativeInvoke::Invoke<bool>(0xEAC5449E, vehicle, x1, y1, z1, x2, y2, z2, p7, p8); }
	static bool IS_VEHICLE_IN_WATER(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x20B649B6, vehicle); }
	static bool IS_VEHICLE_MODEL(Vehicle vehicle, uint32_t modelHash) { return NativeInvoke::Invoke<bool>(0x13B10B6, vehicle, modelHash); }
	static bool IS_VEHICLE_ON_ALL_WHEELS(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x10089F8E, vehicle); }
	static bool IS_VEHICLE_ON_FIRE(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x9818A08C, vehicle); }
	static bool IS_VEHICLE_ON_SCREEN(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x485E14C0, vehicle); }
	static bool IS_VEHICLE_SEAT_FREE(Vehicle vehicle, int32_t seatIndex) { return NativeInvoke::Invoke<bool>(0xDAF42B02, vehicle, seatIndex); }
	static bool IS_VEHICLE_SIREN_ON(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x25EB5873, vehicle); }
	static bool IS_VEHICLE_STOPPED(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x655F072C, vehicle); }
	static bool IS_VEHICLE_STOPPED_AT_TRAFFIC_LIGHTS(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x69200FA4, vehicle); }
	static bool IS_VEHICLE_STUCK_ON_ROOF(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x18D07C6C, vehicle); }
	static bool IS_VEHICLE_STUCK_TIMER_UP(Vehicle vehicle, int32_t index, int32_t time) { return NativeInvoke::Invoke<bool>(0x2FCF58C1, vehicle, index, time); }
	static bool IS_VEHICLE_TOUCHING_VEHICLE(Vehicle vehicle1, Vehicle vehicle2) { return NativeInvoke::Invoke<bool>(0xC86D447B, vehicle1, vehicle2); }
	static bool IS_VEHICLE_TYRE_BURST(Vehicle vehicle, int32_t tireIndex) { return NativeInvoke::Invoke<bool>(0x48C80210, vehicle, tireIndex); }
	static bool IS_VEHICLE_UPRIGHT(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x3E5E91E4, vehicle); }
	static bool IS_VEHICLE_UPSIDEDOWN(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0xD45346E7, vehicle); }
	static bool IS_VEHICLE_WAITING_FOR_WORLD_COLLISION(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0x4BEF6ADD, vehicle); }
	static bool IS_VEHICLE_WINDOW_INTACT(Vehicle vehicle, int32_t window) { return NativeInvoke::Invoke<bool>(0xAC4EF23D, vehicle, window); }
	static bool IS_WEAPON_ATTACHMENT_ENABLED(Weapon weapon, int32_t attachmentIndex) { return NativeInvoke::Invoke<bool>(0xE188437A, weapon, attachmentIndex); }
	static bool IS_WEAPON_ATTACHMENT_TOGGLED(Weapon weapon, int32_t attachmentIndex) { return NativeInvoke::Invoke<bool>(0x7AADF3E5, weapon, attachmentIndex); }
	static bool IS_WEAPON_PICKUP_VISIBLE() { return NativeInvoke::Invoke<bool>(0xD7492EEB); }
	static bool IS_WORLD_POINT_WITHIN_BRAIN_ACTIVATION_RANGE() { return NativeInvoke::Invoke<bool>(0x2CF305A0); }
	static bool IS_XBOX360_VERSION() { return NativeInvoke::Invoke<bool>(0x24005CC8); }
	static bool I_SEQUENCE_DOES_EXIST(const char* name) { return NativeInvoke::Invoke<bool>(0x50983774, name); }
	static bool I_SEQUENCE_IS_LOADED(const char* name) { return NativeInvoke::Invoke<bool>(0x94DBA0E6, name); }
	static bool I_SEQUENCE_QUERY_ENTITY_STATE(const char* name, const char* entityName, int32_t state) { return NativeInvoke::Invoke<bool>(0xF931337, name, entityName, state); }
	static bool I_SEQUENCE_QUERY_STATE(const char* name, int32_t state) { return NativeInvoke::Invoke<bool>(0xB4FE00D1, name, state); }
	static bool I_SEQUENCE_REGISTER_ENTITY(const char* name, const char* entityName, Entity entity, int32_t entityType) { return NativeInvoke::Invoke<bool>(0xB11EA6E2, name, entityName, entity, entityType); }
	static bool LEADERBOARDS_READ__ROS__FOR_LOCAL_GAMER(Any p0) { return NativeInvoke::Invoke<bool>(0x9349F590, p0); }
	static bool LOADOUT_CHANGED_DURING_GAME() { return NativeInvoke::Invoke<bool>(0xBE6FFEB1); }
	static bool LOAD_ALL_PATH_NODES(bool p0) { return NativeInvoke::Invoke<bool>(0xC66E28C3, p0); }
	static bool LOAD_SCRIPT_AUDIO_BANK(const char* name) { return NativeInvoke::Invoke<bool>(0xF0346449, name); }
	static bool LOAD_XML_FILE(const char* name) { return NativeInvoke::Invoke<bool>(0x1C084D18, name); }
	static bool LOBBY_GET_OPTION_EXISTS(int32_t gameMode, int32_t option) { return NativeInvoke::Invoke<bool>(0xFF3B14E9, gameMode, option); }
	static bool LOBBY_GET_OPTION_IS_ACTIVE(int32_t gameMode, int32_t option) { return NativeInvoke::Invoke<bool>(0xF79A7F40, gameMode, option); }
	static bool LOBBY_GET_OPTION_IS_DEACTIVE(int32_t gameMode, int32_t option) { return NativeInvoke::Invoke<bool>(0x600E3311, gameMode, option); }
	static bool LOBBY_GET_OPTION_IS_DISABLE(int32_t gameMode, int32_t option) { return NativeInvoke::Invoke<bool>(0x664091E2, gameMode, option); }
	static bool LOBBY_GET_OPTION_IS_KICK_LIST(int32_t gameMode, int32_t option) { return NativeInvoke::Invoke<bool>(0x349BA811, gameMode, option); }
	static bool LOBBY_GET_OPTION_IS_LIST(int32_t gameMode, int32_t option) { return NativeInvoke::Invoke<bool>(0x428DCDB, gameMode, option); }
	static bool LOBBY_GET_OPTION_IS_MODEL(int32_t gameMode, int32_t option) { return NativeInvoke::Invoke<bool>(0xEF2DEAA4, gameMode, option); }
	static bool LOBBY_GET_OPTION_IS_NUMBERS(int32_t gameMode, int32_t option) { return NativeInvoke::Invoke<bool>(0xBF4965C0, gameMode, option); }
	static bool LOBBY_HAS_MATCH_STARTED() { return NativeInvoke::Invoke<bool>(0xD5189EE8); }
	static bool LOCAL_PLAYER_CAN_DO_MP_INTERACTIONS() { return NativeInvoke::Invoke<bool>(0x6BBDF4CB); }
	static bool MANOGAMETESTER_DUMP_NOW() { return NativeInvoke::Invoke<bool>(0x409525B7); }
	static bool MODIFY_UNLOCK(const char* unlockSemantic, bool p1, bool p2, bool p3) { return NativeInvoke::Invoke<bool>(0xF203B6DD, unlockSemantic, p1, p2, p3); }
	static bool NETWORK_ACCEPT_INVITE(int32_t inviteIndex) { return NativeInvoke::Invoke<bool>(0xFB31FA9C, inviteIndex); }
	static bool NETWORK_AM_I_BLOCKED_BY_PLAYER(Player player) { return NativeInvoke::Invoke<bool>(0x953EF45E, player); }
	static bool NETWORK_AM_I_MUTED_BY_PLAYER(Player player) { return NativeInvoke::Invoke<bool>(0xE128F2B0, player); }
	static bool NETWORK_CHANGE_GAME_MODE(Any p0, Any p1, Any p2, Any p3) { return NativeInvoke::Invoke<bool>(0xCB8178A3, p0, p1, p2, p3); }
	static bool NETWORK_DID_INVITE_FRIEND(const char* friendName) { return NativeInvoke::Invoke<bool>(0x9C8802DA, friendName); }
	static bool NETWORK_DOES_PLAYER_HAVE_ANY_STREAK_ACTIVE(Player player) { return NativeInvoke::Invoke<bool>(0x75602443, player); }
	static bool NETWORK_FIND_GAME_PENDING() { return NativeInvoke::Invoke<bool>(0x3AE44227); }
	static bool NETWORK_GET_PLAYER_STREAK_ACTIVE(Player player, int32_t p1) { return NativeInvoke::Invoke<bool>(0x1C4B4492, player, p1); }
	static bool NETWORK_HAS_PLAYER_COLLECTED_PICKUP(Player player, Any p1) { return NativeInvoke::Invoke<bool>(0xDA423334, player, p1); }
	static bool NETWORK_HAS_PLAYER_HAS_DIED_RECENTLY(Player player) { return NativeInvoke::Invoke<bool>(0x362078F3, player); }
	static bool NETWORK_HAVE_ACCEPTED_INVITE() { return NativeInvoke::Invoke<bool>(0xD780795D); }
	static bool NETWORK_HAVE_ONLINE_PRIVILEGES() { return NativeInvoke::Invoke<bool>(0xEF63BFDF); }
	static bool NETWORK_HAVE_SUMMONS() { return NativeInvoke::Invoke<bool>(0x9060239E); }
	static bool NETWORK_HOST_GAME(Any p0, bool p1, Any p2, Any p3, Any p4, Any p5) { return NativeInvoke::Invoke<bool>(0x79A5F0C4, p0, p1, p2, p3, p4, p5); }
	static bool NETWORK_INVITE_FRIEND(const char* friendName, const char* inviteMsg) { return NativeInvoke::Invoke<bool>(0x81A2A4CA, friendName, inviteMsg); }
	static bool NETWORK_IS_AVATAR_PAYNEKILLER_CHARACTER(uint32_t avatarHash) { return NativeInvoke::Invoke<bool>(0x8F49794B, avatarHash); }
	static bool NETWORK_IS_ENABLED() { return NativeInvoke::Invoke<bool>(0x9E8F9F53); }
	static bool NETWORK_IS_FRIEND_IN_SAME_TITLE(const char* friendName) { return NativeInvoke::Invoke<bool>(0xC54365C2, friendName); }
	static bool NETWORK_IS_FRIEND_ONLINE(const char* friendName) { return NativeInvoke::Invoke<bool>(0xE0A42430, friendName); }
	static bool NETWORK_IS_GAME_IN_PROGRESS() { return NativeInvoke::Invoke<bool>(0x9B88E3E); }
	static bool NETWORK_IS_GAME_RANKED() { return NativeInvoke::Invoke<bool>(0xAB1DB6B6); }
	static bool NETWORK_IS_HOST() { return NativeInvoke::Invoke<bool>(0xE46AC10F); }
	static bool NETWORK_IS_HOST_OF_SCRIPT(uint32_t scriptHash) { return NativeInvoke::Invoke<bool>(0x553CF087, scriptHash); }
	static bool NETWORK_IS_HOST_OF_THIS_SCRIPT() { return NativeInvoke::Invoke<bool>(0x6970BA94); }
	static bool NETWORK_IS_INVITEE_ONLINE() { return NativeInvoke::Invoke<bool>(0x95B2C62F); }
	static bool NETWORK_IS_OPERATION_PENDING() { return NativeInvoke::Invoke<bool>(0x6895F923); }
	static bool NETWORK_IS_PLAYER_ACTIVE(Player player) { return NativeInvoke::Invoke<bool>(0x43657B17, player); }
	static bool NETWORK_IS_PLAYER_BLOCKED_BY_ME(Player player) { return NativeInvoke::Invoke<bool>(0xAE4F4560, player); }
	static bool NETWORK_IS_PLAYER_MUTED_BY_ME(Player player) { return NativeInvoke::Invoke<bool>(0x7A21050E, player); }
	static bool NETWORK_IS_PLAYER_PHYSICAL(Player player) { return NativeInvoke::Invoke<bool>(0x75645571, player); }
	static bool NETWORK_IS_PLAYER_TALKING(Player player) { return NativeInvoke::Invoke<bool>(0xDA9FD9DB, player); }
	static bool NETWORK_IS_PLAYER_VALID(Player player) { return NativeInvoke::Invoke<bool>(0x7F65AF0B, player); }
	static bool NETWORK_IS_PLAYER_VISIBLE(Any p0, Any p1, Any p2) { return NativeInvoke::Invoke<bool>(0x56D96854, p0, p1, p2); }
	static bool NETWORK_IS_PLAYER_VISIBLE_TO_TEAM(Any p0, Any p1, Any p2) { return NativeInvoke::Invoke<bool>(0xC459CF02, p0, p1, p2); }
	static bool NETWORK_IS_SESSION_INVITABLE() { return NativeInvoke::Invoke<bool>(0x91E81052); }
	static bool NETWORK_JOINING_IN_PROGRESS_GAME() { return NativeInvoke::Invoke<bool>(0x6D3ADAB3); }
	static bool NETWORK_JOIN_SUMMONS() { return NativeInvoke::Invoke<bool>(0x68C293F4); }
	static bool NETWORK_PARAM_ALLOW_WIN_BUTTON() { return NativeInvoke::Invoke<bool>(0x6C49E55C); }
	static bool NETWORK_PARAM_JUST_RESPAWN() { return NativeInvoke::Invoke<bool>(0x2F09AA8A); }
	static bool NETWORK_PLAYER_HAS_HEADSET(Player player) { return NativeInvoke::Invoke<bool>(0x451FB6B6, player); }
	static bool NETWORK_PLAYER_HAS_PED(Player player) { return NativeInvoke::Invoke<bool>(0x1D185E7D, player); }
	static bool NETWORK_REQUIRE_STORED_QUERIES(const char* fileName) { return NativeInvoke::Invoke<bool>(0x1C183BC8, fileName); }
	static bool NETWORK_SET_PLAYER_MUTED(Player player, bool toggle) { return NativeInvoke::Invoke<bool>(0xCE451908, player, toggle); }
	static bool NETWORK_STORE_SINGLE_PLAYER_GAME() { return NativeInvoke::Invoke<bool>(0xA52597AE); }
	static bool NETWORK_UPDATE_LOAD_SCENE() { return NativeInvoke::Invoke<bool>(0xC76E023C); }
	static bool NET_ARE_PLAYERS_IN_SAME_GANG(Player player1, Player player2) { return NativeInvoke::Invoke<bool>(0xD1B34A9E, player1, player2); }
	static bool NET_ARE_PLAYERS_IN_SAME_PARTY(Player player1, Player player2) { return NativeInvoke::Invoke<bool>(0x58A5D90C, player1, player2); }
	static bool NET_GET_FLOAT_ROS_GAMER_DATA(uint32_t hash, float* value) { return NativeInvoke::Invoke<bool>(0xEF912D19, hash, value); }
	static bool NET_GET_GAMER_NAME_WITH_GANG_TAG(Player player, int32_t bufferSize, char* buffer) { return NativeInvoke::Invoke<bool>(0x10AB1606, player, bufferSize, buffer); }
	static bool NET_GET_GAMER_ROS_XP_BONUS(float* value) { return NativeInvoke::Invoke<bool>(0x60D4317D, value); }
	static bool NET_GET_INT_ROS_GAMER_DATA(uint32_t hash, int32_t* value) { return NativeInvoke::Invoke<bool>(0x6670CF02, hash, value); }
	static bool NET_GET_IS_ROCKSTAR_DEV() { return NativeInvoke::Invoke<bool>(0xCFFFC689); }
	static bool NET_GET_IS_ROS_CHEATER() { return NativeInvoke::Invoke<bool>(0x7ABA6A5E); }
	static bool NET_GET_PLAYER_GANG_NAME(Player player, int32_t bufferSize, char* buffer) { return NativeInvoke::Invoke<bool>(0xA4BF53A, player, bufferSize, buffer); }
	static bool NET_GET_PLAYER_GANG_TAG(Player player, int32_t bufferSize, char* buffer) { return NativeInvoke::Invoke<bool>(0x4F64907A, player, bufferSize, buffer); }
	static bool NET_GET_PLAYER_GANG_TAG_UI(Player player, int32_t bufferSize, char* buffer) { return NativeInvoke::Invoke<bool>(0xF2008295, player, bufferSize, buffer); }
	static bool NET_GET_bool_ROS_GAMER_DATA(uint32_t hash) { return NativeInvoke::Invoke<bool>(0xDBF081C9, hash); }
	static bool NET_IS_GANG_INFO_VALID(Player player) { return NativeInvoke::Invoke<bool>(0x6D648816, player); }
	static bool NET_IS_PLAYER_IN_GANG(Player player) { return NativeInvoke::Invoke<bool>(0x45A0B35B, player); }
	static bool PED_ACTION_TREE_PLAY_NODE(Ped ped, const char* name) { return NativeInvoke::Invoke<bool>(0x95DEDF47, ped, name); }
	static bool PED_ANIM_EVENT(Ped ped, uint32_t p1) { return NativeInvoke::Invoke<bool>(0xC0D17E4F, ped, p1); }
	static bool PED_ANIM_EVENT_OLD(Ped ped, int32_t p1) { return NativeInvoke::Invoke<bool>(0x27F99158, ped, p1); }
	static bool PED_HACK_DISABLE_INAIR_EVENT(Ped ped, bool toggle) { return NativeInvoke::Invoke<bool>(0x7400CF35, ped, toggle); }
	static bool PED_HAS_VALID_THROW_TRAJECTORY_TO_POS(Ped ped, Vector3* pos) { return NativeInvoke::Invoke<bool>(0xBF561175, ped, pos); }
	static bool PLAYER_HAS_MP_SPECIAL_ITEM(Player player, int32_t item) { return NativeInvoke::Invoke<bool>(0x1FE6D589, player, item); }
	static bool PLAY_OBJECT_ANIM(Object object, const char* animDict, const char* animName, float speedMultiplier, bool p4, bool p5) { return NativeInvoke::Invoke<bool>(0x853E879E, object, animDict, animName, speedMultiplier, p4, p5); }
	static bool PLAY_SIMPLE_PED_ANIM(Object ped, const char* animDict, const char* animName, float speedMultiplier, bool p4, bool p5) { return NativeInvoke::Invoke<bool>(0x5DC2CC31, ped, animDict, animName, speedMultiplier, p4, p5); }
	static bool PLAY_VEHICLE_ANIM(Vehicle vehicle, const char* animName, const char* animDict, float speedMultiplier, bool p4, bool p5) { return NativeInvoke::Invoke<bool>(0x6EB2CA78, vehicle, animName, animDict, speedMultiplier, p4, p5); }
	static bool QUERY_MONITORED_STATS(int32_t p0, Any* p1) { return NativeInvoke::Invoke<bool>(0x264C2677, p0, p1); }
	static bool REGISTER_SCRIPT_TUNABLE_VARIABLE_CRC_FLOAT(uint32_t tunableHash, float* value) { return NativeInvoke::Invoke<bool>(0x5EB671C0, tunableHash, value); }
	static bool REGISTER_SCRIPT_TUNABLE_VARIABLE_CRC_INT(uint32_t tunableHash, int32_t* value) { return NativeInvoke::Invoke<bool>(0x9E87D9D6, tunableHash, value); }
	static bool REGISTER_SCRIPT_TUNABLE_VARIABLE_FLOAT(const char* context, const char* name, float* value) { return NativeInvoke::Invoke<bool>(0xF6F9855F, context, name, value); }
	static bool REGISTER_SCRIPT_TUNABLE_VARIABLE_INT(const char* context, const char* name, int32_t* value) { return NativeInvoke::Invoke<bool>(0xFA39724D, context, name, value); }
	static bool REQUEST_LOAD() { return NativeInvoke::Invoke<bool>(0xE35F54A); }
	static bool REQUEST_SAVE() { return NativeInvoke::Invoke<bool>(0x681BE79F); }
	static bool REQUEST_SCRIPT_AUDIO_BANK(const char* name) { return NativeInvoke::Invoke<bool>(0x21322887, name); }
	static bool RESET_LEVEL_ANIM_DICTIONARIES() { return NativeInvoke::Invoke<bool>(0xC76D45D7); }
	static bool ROTATE_OBJECT(Object object, float p1, float p2, bool p3) { return NativeInvoke::Invoke<bool>(0x2F4D8D44, object, p1, p2, p3); }
	static bool SCRIPT_VAR_EXISTS(const char* name) { return NativeInvoke::Invoke<bool>(0x9073311E, name); }
	static bool SCRIPT_VAR_HASH_EXISTS(uint32_t hash) { return NativeInvoke::Invoke<bool>(0x1046A414, hash); }
	static bool SET_AMMO_IN_CLIP(Ped ped, uint32_t weaponHash, int32_t ammo) { return NativeInvoke::Invoke<bool>(0xA54B0B10, ped, weaponHash, ammo); }
	static bool SET_CHALLENGE_FAILED_STATE(int32_t challengeId, bool state) { return NativeInvoke::Invoke<bool>(0x6DDDD8C3, challengeId, state); }
	static bool SET_CHALLENGE_PROGRESS(int32_t challengeId) { return NativeInvoke::Invoke<bool>(0x45052DC3, challengeId); }
	static bool SET_GRIND_PROGRESS(int32_t grindId, int32_t progress) { return NativeInvoke::Invoke<bool>(0xC97141EE, grindId, progress); }
	static bool SET_ONE_TIME_ONLY_COMMANDS_TO_RUN() { return NativeInvoke::Invoke<bool>(0x840BD987); }
	static bool SET_PED_TO_RAGDOLL(Ped ped, int32_t time1, int32_t time2, int32_t p3, bool p4, bool p5, bool p6, float p7) { return NativeInvoke::Invoke<bool>(0x83CB5052, ped, time1, time2, p3, p4, p5, p6, p7); }
	static bool SET_PED_TO_RAGDOLL_WITH_EXPLOSION(Ped ped, int32_t time1, int32_t time2, float x, float y, float z) { return NativeInvoke::Invoke<bool>(0xF561B007, ped, time1, time2, x, y, z); }
	static bool SET_PED_TO_RAGDOLL_WITH_FALL(Ped ped, int32_t time1, int32_t time2, int32_t ragdollType, float p4, float p5, float p6, float p7, float p8, float p9, float p10, float p11, float p12, float p13) { return NativeInvoke::Invoke<bool>(0xFA12E286, ped, time1, time2, ragdollType, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13); }
	static bool SET_PRESET_TEXT(const char* presetName, int32_t p1, int32_t p2, const char* p3) { return NativeInvoke::Invoke<bool>(0x58439F1A, presetName, p1, p2, p3); }
	static bool SET_PRESET_TEXTVIDEO(const char* presetName, int32_t p1, int32_t p2, const char* p3) { return NativeInvoke::Invoke<bool>(0x292E48B3, presetName, p1, p2, p3); } 
	static bool SET_PRESET_TEXT_TIMING(const char* presetName, int32_t p1, int32_t p2, int32_t p3, float p4, int32_t p5, float p6, int32_t p7, float p8, int32_t p9, float p10, int32_t p11, float p12, int32_t p13, float p14) { return NativeInvoke::Invoke<bool>(0xCA682A7E, presetName, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14); } 
	static bool SET_PROFILE_SETTING(uint32_t hash, int32_t value) { return NativeInvoke::Invoke<bool>(0xF6FA0CA6, hash, value); }
	static bool SET_VEHICLE_ON_GROUND_PROPERLY(Vehicle vehicle) { return NativeInvoke::Invoke<bool>(0xE14FDBA6, vehicle); }
	static bool SEV_IS_PRIMARY() { return NativeInvoke::Invoke<bool>(0x2147F5F2); }
	static bool SLIDE_OBJECT(Object object, float toX, float toY, float toZ, float speedX, float speedY, float speedZ, bool collision) { return NativeInvoke::Invoke<bool>(0x63BFA7A0, object, toX, toY, toZ, speedX, speedY, speedZ, collision); }
	static bool SMASH_GLASS_ON_OBJECT(float x, float y, float z, float radius, uint32_t modelHash, float p5) { return NativeInvoke::Invoke<bool>(0x4CB06A9F, x, y, z, radius, modelHash, p5); }
	static bool SNAP_PLAYER_TO_COVERPOINT_FROM_UID(Player player, uint32_t coverSectionUID, uint32_t coverUID, bool p3) { return NativeInvoke::Invoke<bool>(0x4548143F, player, coverSectionUID, coverUID, p3); }
	static bool START_PARTICLE_FX_NON_LOOPED_AT_COORD(const char* ptfxName, float posX, float posY, float posZ, float rotX, float rotY, float rotZ, float scale) { return NativeInvoke::Invoke<bool>(0xDD79D679, ptfxName, posX, posY, posZ, rotX, rotY, rotZ, scale); }
	static bool START_PARTICLE_FX_NON_LOOPED_ON_OBJECT(const char* ptfxName, Object object, float offsetX, float offsetY, float offsetZ, float rotX, float rotY, float rotZ, float scale) { return NativeInvoke::Invoke<bool>(0xF9617406, ptfxName, object, offsetX, offsetY, offsetZ, rotX, rotY, rotZ, scale); }
	static bool START_PARTICLE_FX_NON_LOOPED_ON_PED_BONE(const char* ptfxName, Ped ped, float offsetX, float offsetY, float offsetZ, float rotX, float rotY, float rotZ, int32_t bone, float scale) { return NativeInvoke::Invoke<bool>(0x53DAEF4E, ptfxName, ped, offsetX, offsetY, offsetZ, rotX, rotY, rotZ, bone, scale); }
	static bool START_PARTICLE_FX_NON_LOOPED_ON_VEHICLE(const char* ptfxName, Vehicle vehicle, float offsetX, float offsetY, float offsetZ, float rotX, float rotY, float rotZ, float scale) { return NativeInvoke::Invoke<bool>(0x7C714DA3, ptfxName, vehicle, offsetX, offsetY, offsetZ, rotX, rotY, rotZ, scale); }
	static bool STAT_EXISTS(const char* statName) { return NativeInvoke::Invoke<bool>(0x3076C37C, statName); }
	static bool STAT_HASH_EXISTS(uint32_t statHash) { return NativeInvoke::Invoke<bool>(0x2146FEC9, statHash); }
	static bool STRING_TO_INT(const char* str, int32_t* outInt) { return NativeInvoke::Invoke<bool>(0x590A8160, str, outInt); }
	static bool SYNCH_RECORDING_WITH_WATER() { return NativeInvoke::Invoke<bool>(0x74537488); }
	static bool THROW_MOLOTOV(Ped ped, float p1, float p2, float p3) { return NativeInvoke::Invoke<bool>(0x86770AD0, ped, p1, p2, p3); }
	static bool UI_DOES_FRAME_EXIST_HASH(uint32_t frameHash) { return NativeInvoke::Invoke<bool>(0x32852FD0, frameHash); }
	static bool UI_DOES_FRAME_EXIST_NAME(const char* frameName) { return NativeInvoke::Invoke<bool>(0x279B59AB, frameName); } 
	static bool UI_IS_QTE_MINIGAME_FAILURE() { return NativeInvoke::Invoke<bool>(0xEFEEDC60); }
	static bool UI_IS_QTE_MINIGAME_FINISHED() { return NativeInvoke::Invoke<bool>(0xC55DA3BB); }
	static bool UI_IS_QTE_MINIGAME_IN_WINDOW() { return NativeInvoke::Invoke<bool>(0xD6D05C65); }
	static bool UI_IS_QTE_MINIGAME_SUCCESS() { return NativeInvoke::Invoke<bool>(0xF664AEA4); }
	static bool UI_IS_TOOLTIP_SHOWING() { return NativeInvoke::Invoke<bool>(0x71C43A04); }
	static bool UI_LOAD_AFTER_ACTION_REPORT(const char* name) { return NativeInvoke::Invoke<bool>(0x2399616B, name); }
	static bool UI_SHOW_TOOLTIP(int32_t p0, const char* p1) { return NativeInvoke::Invoke<bool>(0x6A99EF9C, p0, p1); }
	static bool UNLOCK(const char* unlockSemantic, bool p1, bool p2) { return NativeInvoke::Invoke<bool>(0x98BAB591, unlockSemantic, p1, p2); }
	static bool WAS_CUTSCENE_SKIPPED() { return NativeInvoke::Invoke<bool>(0xC9B6949D); }
	static bool WAS_SINGLE_PLAYER_TITLE_SCREEN_ENTERED() { return NativeInvoke::Invoke<bool>(0x3912FB64); }
	static float ABSF(float value) { return NativeInvoke::Invoke<float>(0xAF6F6E0B, value); }
	static float ACOS(float x) { return NativeInvoke::Invoke<float>(0xF4038776, x); }
	static float ASIN(float x) { return NativeInvoke::Invoke<float>(0x998E5CAD, x); }
	static float ATAN(float x) { return NativeInvoke::Invoke<float>(0x7A03CC8E, x); }
	static float ATAN2(float y, float x) { return NativeInvoke::Invoke<float>(0x2508AC81, y, x); }
	static float COS(float value) { return NativeInvoke::Invoke<float>(0x0238FE9, value); }
	static float DB_GET_FLOAT(const char* name, const char* entryName) { return NativeInvoke::Invoke<float>(0x7315F901, name, entryName); }
	static float EXP(float value) { return NativeInvoke::Invoke<float>(0xE2313450, value); } 
	static float GET_ADRENALINE_AMT() { return NativeInvoke::Invoke<float>(0x1D2B1092); }
	static float GET_ANGLE_BETWEEN_2D_VECTORS(float x1, float y1, float x2, float y2) { return NativeInvoke::Invoke<float>(0xDBF75E58, x1, y1, x2, y2); }
	static float GET_ANIMATED_TEXT_HEIGHT() { return NativeInvoke::Invoke<float>(0x71223133); }
	static float GET_ANIMATED_TEXT_WIDTH() { return NativeInvoke::Invoke<float>(0x8276E3F9); }
	static float GET_BEST_HEADING_IF_POSSIBLE(float p0, float p1, float p2, float p3, float p4, float p5, float p6, float p7, float p8, float p9) { return NativeInvoke::Invoke<float>(0x7A1EF9BD, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9); }
	static float GET_CAM_DOF_STRENGTH(Cam cam) { return NativeInvoke::Invoke<float>(0x64E6B290, cam); } 
	static float GET_CAM_FAR_CLIP(Cam cam) { return NativeInvoke::Invoke<float>(0x9F119B8, cam); } 
	static float GET_CAM_FAR_DOF(Cam cam) { return NativeInvoke::Invoke<float>(0x98C5CCE9, cam); } 
	static float GET_CAM_FOV(Cam cam) { return NativeInvoke::Invoke<float>(0xD6E9FCF5, cam); } 
	static float GET_CAM_MOTION_BLUR_STRENGTH(Cam cam) { return NativeInvoke::Invoke<float>(0x54EA722E, cam); } 
	static float GET_CAM_NEAR_CLIP(Cam cam) { return NativeInvoke::Invoke<float>(0xCFCD35EE, cam); } 
	static float GET_CAM_NEAR_DOF(Cam cam) { return NativeInvoke::Invoke<float>(0x3F627534, cam); } 
	static float GET_CURRENT_FPS() { return NativeInvoke::Invoke<float>(0x7030FB99); }
	static float GET_DISTANCE_BETWEEN_COORDS(float x1, float y1, float z1, float x2, float y2, float z2, bool useZ) { return NativeInvoke::Invoke<float>(0xF698765E, x1, y1, z1, x2, y2, z2, useZ); }
	static float GET_FLOAT_FROM_XML_NODE_ATTRIBUTE(int32_t attributeIndex) { return NativeInvoke::Invoke<float>(0x9C58C97F, attributeIndex); }
	static float GET_FRAME_TIME() { return NativeInvoke::Invoke<float>(0x96374262); }
	static float GET_GAMEPLAY_CAM_FOV() { return NativeInvoke::Invoke<float>(0x4D6B3BFA); }
	static float GET_GAMEPLAY_CAM_RELATIVE_HEADING() { return NativeInvoke::Invoke<float>(0xCAF839C2); }
	static float GET_GAMEPLAY_CAM_RELATIVE_PITCH() { return NativeInvoke::Invoke<float>(0xFC5A4946); }
	static float GET_HEADING_FROM_VECTOR_2D(float dx, float dy) { return NativeInvoke::Invoke<float>(0xD209D52B, dx, dy); }
	static float GET_HEIGHT_OF_VEHICLE(Vehicle vehicle, float x, float y, float z, bool p4, bool p5) { return NativeInvoke::Invoke<float>(0x62990CD4, vehicle, x, y, z, p4, p5); }
	static float GET_IS_PED_LISTENING_TO_PED(Ped ped, Ped ped2) { return NativeInvoke::Invoke<float>(0xBDCBAABF, ped, ped2); }
	static float GET_NETWORK_TIMER() { return NativeInvoke::Invoke<float>(0xF733052C); }
	static float GET_OBJECT_FRAGMENT_DAMAGE_HEALTH(Object object, bool p1) { return NativeInvoke::Invoke<float>(0xF0B330AD, object, p1); }
	static float GET_OBJECT_HEADING(Object object) { return NativeInvoke::Invoke<float>(0x1C02D2F8, object); }
	static float GET_OBJECT_HEALTH(Object object) { return NativeInvoke::Invoke<float>(0xF9D59802, object); }
	static float GET_OBJECT_MASS(Object object) { return NativeInvoke::Invoke<float>(0x449F0820, object); }
	static float GET_OBJECT_SPEED(Object object) { return NativeInvoke::Invoke<float>(0xA059FF6B, object); }
	static float GET_PED_ANIM_CURRENT_TIME(Ped ped, const char* animDict, const char* animName) { return NativeInvoke::Invoke<float>(0x1BAAE533, ped, animDict, animName); }
	static float GET_PED_ANIM_TOTAL_TIME(Ped ped, const char* animDict, const char* animName) { return NativeInvoke::Invoke<float>(0xB8945721, ped, animDict, animName); }
	static float GET_PED_COMBAT_RANGE_HALF_HEIGHT(Ped ped) { return NativeInvoke::Invoke<float>(0x6E4808B0, ped); }
	static float GET_PED_COMBAT_RANGE_MAX(Ped ped) { return NativeInvoke::Invoke<float>(0x647EA0D6, ped); }
	static float GET_PED_COMBAT_RANGE_MIN(Ped ped) { return NativeInvoke::Invoke<float>(0x6BEBA6A8, ped); }
	static float GET_PED_HEADING(Ped ped) { return NativeInvoke::Invoke<float>(0xD8D707C6, ped); }
	static float GET_PED_HEIGHT_ABOVE_GROUND(Ped ped) { return NativeInvoke::Invoke<float>(0x1E853FEC, ped); }
	static float GET_PED_SPEED(Ped ped) { return NativeInvoke::Invoke<float>(0xBB824586, ped); }
	static float GET_PED_SWEAT(Ped ped) { return NativeInvoke::Invoke<float>(0x44B91E94, ped); }
	static float GET_PED_TOXICITY_LEVEL(Ped ped) { return NativeInvoke::Invoke<float>(0xD9809ECA, ped); }
	static float GET_PED_WETNESS(Ped ped) { return NativeInvoke::Invoke<float>(0xF402C171, ped); }
	static float GET_PED_WET_HEIGHT(Ped ped) { return NativeInvoke::Invoke<float>(0x5DBBFF35, ped); }
	static float GET_POSITION_IN_PED_RECORDING(Ped ped) { return NativeInvoke::Invoke<float>(0xC722356B, ped); }
	static float GET_POSITION_IN_RECORDING(Vehicle vehicle) { return NativeInvoke::Invoke<float>(0x7DCD644C, vehicle); }
	static float GET_PROGRESS_BAR_PERCENT() { return NativeInvoke::Invoke<float>(0xA04FB35F); }
	static float GET_RANDOM_FLOAT_IN_RANGE(float min, float max) { return NativeInvoke::Invoke<float>(0x562C4D0, min, max); }
	static float GET_REAL_FRAME_TIME() { return NativeInvoke::Invoke<float>(0x4D12A84); }
	static float GET_SECONDARY_LIFE_BAR_PERCENT() { return NativeInvoke::Invoke<float>(0x3FBDD93D); }
	static float GET_STRING_WIDTH(const char* textLabel) { return NativeInvoke::Invoke<float>(0xBABDF3D6, textLabel); }
	static float GET_STRING_WIDTH_WITH_NUMBER(const char* textLabel, int32_t number) { return NativeInvoke::Invoke<float>(0xEAEB477D, textLabel, number); }
	static float GET_STRING_WIDTH_WITH_STRING(const char* textLabel, const char* string) { return NativeInvoke::Invoke<float>(0x48A2E6C, textLabel, string); }
	static float GET_TIME_POSITION_IN_PED_RECORDING(Ped ped) { return NativeInvoke::Invoke<float>(0x42BD5D0F, ped); }
	static float GET_TIME_POSITION_IN_RECORDED_RECORDING(Any p0) { return NativeInvoke::Invoke<float>(0xF6C0D8CA, p0); }
	static float GET_TIME_POSITION_IN_RECORDING(Vehicle vehicle) { return NativeInvoke::Invoke<float>(0xF8C3E4A2, vehicle); }
	static float GET_TIME_REMAINING() { return NativeInvoke::Invoke<float>(0x85FA3578); }
	static float GET_TIME_SCALE() { return NativeInvoke::Invoke<float>(0x8CFD581F); }
	static float GET_TOTAL_DURATION_OF_VEHICLE_RECORDING(int32_t recordingIndex) { return NativeInvoke::Invoke<float>(0x5B35EEB7, recordingIndex); }
	static float GET_VEHICLE_DIRT_LEVEL(Vehicle vehicle) { return NativeInvoke::Invoke<float>(0xFD15C065, vehicle); }
	static float GET_VEHICLE_ENGINE_HEALTH(Vehicle vehicle) { return NativeInvoke::Invoke<float>(0x8880038A, vehicle); }
	static float GET_VEHICLE_FIXED_WEAPON_ACCURACY(Vehicle vehicle, int32_t weaponIndex) { return NativeInvoke::Invoke<float>(0x5A18B080, vehicle, weaponIndex); }
	static float GET_VEHICLE_FIXED_WEAPON_DAMAGE(Vehicle vehicle, int32_t weaponIndex) { return NativeInvoke::Invoke<float>(0x5C718BD, vehicle, weaponIndex); }
	static float GET_VEHICLE_FORWARD_X(Vehicle vehicle) { return NativeInvoke::Invoke<float>(0x48F59C5E, vehicle); }
	static float GET_VEHICLE_FORWARD_Y(Vehicle vehicle) { return NativeInvoke::Invoke<float>(0x780C7A8B, vehicle); }
	static float GET_VEHICLE_HEADING(Vehicle vehicle) { return NativeInvoke::Invoke<float>(0x4155B124, vehicle); }
	static float GET_VEHICLE_PETROL_TANK_HEALTH(Vehicle vehicle) { return NativeInvoke::Invoke<float>(0xE41595CE, vehicle); }
	static float GET_VEHICLE_PITCH(Vehicle vehicle) { return NativeInvoke::Invoke<float>(0x2680C924, vehicle); }
	static float GET_VEHICLE_ROLL(Vehicle vehicle) { return NativeInvoke::Invoke<float>(0xD48A9E8B, vehicle); }
	static float GET_VEHICLE_SPEED(Vehicle vehicle) { return NativeInvoke::Invoke<float>(0x9B115A40, vehicle); }
	static float GET_VEHICLE_UPRIGHT_VALUE(Vehicle vehicle) { return NativeInvoke::Invoke<float>(0x1D761FBC, vehicle); }
	static float ISEQ_QUERY_ENTITY_ANIMATION_PHASE(uint32_t hash, const char* animDict, const char* animName) { return NativeInvoke::Invoke<float>(0x97141177, hash, animDict, animName); }
	static float PLAYER_GET_TIMEWARP_MODIFIER() { return NativeInvoke::Invoke<float>(0xEACC1A2); }
	static float POW(float base, float exponent) { return NativeInvoke::Invoke<float>(0x85D134F8, base, exponent); } 
	static float PROJECTED_DISTANCE(float p0, float p1, float p2, float p3, float p4, float p5, float p6, float p7, float p8) { return NativeInvoke::Invoke<float>(0xEC0E7C49, p0, p1, p2, p3, p4, p5, p6, p7, p8); }
	static float SCRIPT_VAR_GET_FLOAT(const char* name) { return NativeInvoke::Invoke<float>(0x7544B570, name); }
	static float SCRIPT_VAR_HASH_GET_FLOAT(uint32_t hash) { return NativeInvoke::Invoke<float>(0xBFADDD7B, hash); }
	static float SIN(float value) { return NativeInvoke::Invoke<float>(0xBF987F58, value); }
	static float SQRT(float value) { return NativeInvoke::Invoke<float>(0x145C7701, value); }
	static float STAT_GET_FLOAT(const char* statName) { return NativeInvoke::Invoke<float>(0xFCBDA612, statName); }
	static float STAT_HASH_GET_FLOAT(uint32_t statHash) { return NativeInvoke::Invoke<float>(0xE143F19A, statHash); }
	static float TAN(float x) { return NativeInvoke::Invoke<float>(0xD320CE5E, x); }
	static float TIMESTEP() { return NativeInvoke::Invoke<float>(0x50597EE2); }
	static float TIMESTEPUNWARPED() { return NativeInvoke::Invoke<float>(0x99B02B53); } 
	static float TO_FLOAT(int32_t value) { return NativeInvoke::Invoke<float>(0x67116627, value); }
	static float VDIST(float x1, float y1, float z1, float x2, float y2, float z2) { return NativeInvoke::Invoke<float>(0x3C08ECB7, x1, y1, z1, x2, y2, z2); }
	static float VDIST2(float x1, float y1, float z1, float x2, float y2, float z2) { return NativeInvoke::Invoke<float>(0xC85DEF1F, x1, y1, z1, x2, y2, z2); }
	static float VMAG(float x, float y, float z) { return NativeInvoke::Invoke<float>(0x1FCF1ECD, x, y, z); }
	static float VMAG2(float x, float y, float z) { return NativeInvoke::Invoke<float>(0xE796E629, x, y, z); }
	static float _GET_CHALLENGE_MODE_TIME_REMAINING() { return NativeInvoke::Invoke<float>(0xD91473DB); }
	static int32_t ABSI(int32_t value) { return NativeInvoke::Invoke<int32_t>(0xB44677C5, value); }
	static int32_t ADD_TEXT_WIDGET(const char* p0) { return NativeInvoke::Invoke<int32_t>(0xE178AA0F, p0); }
	static int32_t ASSISTED_MOVEMENT_IS_ON_SCRIPTED_ROUTE() { return NativeInvoke::Invoke<int32_t>(0x1EFF3C50); }
	static int32_t AUD_GET_ANIM_MARKER_LEVEL() { return NativeInvoke::Invoke<int32_t>(0x8A44F752); }
	static int32_t CEIL(float value) { return NativeInvoke::Invoke<int32_t>(0xD536A1DF, value); }
	static int32_t COMPARE_AND_SWAP(int32_t* p0, int32_t p1, int32_t p2) { return NativeInvoke::Invoke<int32_t>(0xC3FFAA9F, p0, p1, p2); }
	static int32_t CREATE_DYNAMIC_PATH_OBSTRUCTION(float x1, float y1, float z1, float x2, float y2, float z2, float p6) { return NativeInvoke::Invoke<int32_t>(0x94C84500, x1, y1, z1, x2, y2, z2, p6); }
	static int32_t CREATE_GLINT(uint32_t glintType, float x, float y, float z) { return NativeInvoke::Invoke<int32_t>(0x4D85E438, glintType, x, y, z); }
	static int32_t CREATE_LASER(const char* p0) { return NativeInvoke::Invoke<int32_t>(0xC530B3B5, p0); }
	static int32_t CREATE_NEW_SCRIPTED_CONVERSATION(int32_t p0) { return NativeInvoke::Invoke<int32_t>(0xB2BC25F8, p0); }
	static int32_t CREATE_SCRIPT_VEHICLE_GENERATOR(float x, float y, float z, float heading, float p4, float p5, uint32_t modelHash, int32_t p7, int32_t p8, int32_t p9, int32_t p10, bool p11, int32_t p12, int32_t p13) { return NativeInvoke::Invoke<int32_t>(0x25A9A261, x, y, z, heading, p4, p5, modelHash, p7, p8, p9, p10, p11, p12, p13); }
	static int32_t DB_GET_INT(const char* name, const char* entryName) { return NativeInvoke::Invoke<int32_t>(0xC7A9D359, name, entryName); }
	static int32_t DEATHRECORD_GET_NUM_KILLERS() { return NativeInvoke::Invoke<int32_t>(0x6DE9B0D2); }
	static int32_t DEATHRECORD_GET_NUM_RECORDS(int32_t index) { return NativeInvoke::Invoke<int32_t>(0x8A3C385E, index); }
	static int32_t FIND_LASER(const char* p0) { return NativeInvoke::Invoke<int32_t>(0xC1618EF5, p0); }
	static int32_t FLOOR(float value) { return NativeInvoke::Invoke<int32_t>(0x32E9BE04, value); }
	static int32_t GET_AIM_CAM_ZOOL_LEVEL() { return NativeInvoke::Invoke<int32_t>(0x8850B945); } 
	static int32_t GET_AMMO_IN_PED_WEAPON(Ped ped, uint32_t weaponHash) { return NativeInvoke::Invoke<int32_t>(0xC755733, ped, weaponHash); }
	static int32_t GET_BG_SCRIPT_UNIT(int32_t index) { return NativeInvoke::Invoke<int32_t>(0x46D59A47, index); }
	static int32_t GET_BITS_IN_RANGE(int32_t data, int32_t rangeStart, int32_t rangeEnd) { return NativeInvoke::Invoke<int32_t>(0xCA03A1E5, data, rangeStart, rangeEnd); }
	static int32_t GET_BLIP_ALPHA(Blip blip) { return NativeInvoke::Invoke<int32_t>(0x297AF6C8, blip); }
	static int32_t GET_BLIP_COLOUR(Blip blip) { return NativeInvoke::Invoke<int32_t>(0xDD6A1E54, blip); }
	static int32_t GET_BLIP_INFO_ID_DISPLAY(Blip blip) { return NativeInvoke::Invoke<int32_t>(0xD0FC19F4, blip); }
	static int32_t GET_BLIP_INFO_ID_TYPE(Blip blip) { return NativeInvoke::Invoke<int32_t>(0x501D7B4E, blip); }
	static int32_t GET_BLIP_SPRITE(Blip blip) { return NativeInvoke::Invoke<int32_t>(0x72FF2E73, blip); }
	static int32_t GET_BULLET_TIME_COUNT() { return NativeInvoke::Invoke<int32_t>(0x934E7F2D); }
	static int32_t GET_BULLET_TIME_TEAM_COUNT() { return NativeInvoke::Invoke<int32_t>(0x55EF252D); }
	static int32_t GET_CAM_VIEW_MODE() { return NativeInvoke::Invoke<int32_t>(0x5A502ADD); }
	static int32_t GET_CHALLENGE_PROGRESS(int32_t challengeId) { return NativeInvoke::Invoke<int32_t>(0x653D3616, challengeId); }
	static int32_t GET_CHECKPOINT_SELECTED() { return NativeInvoke::Invoke<int32_t>(0x2FA3742B); }
	static int32_t GET_COMPLETED_GRIND_GOAL(int32_t grindId) { return NativeInvoke::Invoke<int32_t>(0xEF6FE8F, grindId); }
	static int32_t GET_CURRENT_ARCADE_MODE() { return NativeInvoke::Invoke<int32_t>(0xD7FA564A); }
	static int32_t GET_CURRENT_DAY_OF_WEEK() { return NativeInvoke::Invoke<int32_t>(0xD4C86DC4); }
	static int32_t GET_CURRENT_LANGUAGE() { return NativeInvoke::Invoke<int32_t>(0x761BE00B); }
	static int32_t GET_CURRENT_LEVEL_FINISH() { return NativeInvoke::Invoke<int32_t>(0x64C8F354); }
	static int32_t GET_CURRENT_LEVEL_START() { return NativeInvoke::Invoke<int32_t>(0xF1AAFA7B); }
	static int32_t GET_CURRENT_LOADOUT_SLOT() { return NativeInvoke::Invoke<int32_t>(0x741531DA); }
	static int32_t GET_CURRENT_PLAYBACK_NUMBER_FOR_PED(Ped ped) { return NativeInvoke::Invoke<int32_t>(0x2BAA832F, ped); }
	static int32_t GET_CURRENT_PLAYBACK_NUMBER_FOR_VEHICLE(Vehicle vehicle) { return NativeInvoke::Invoke<int32_t>(0x748702A9, vehicle); }
	static int32_t GET_CURRENT_STATION_FOR_TRAIN(Vehicle train) { return NativeInvoke::Invoke<int32_t>(0x3B7DCCAA, train); }
	static int32_t GET_CUSTOM_PLAYER_VARIATION() { return NativeInvoke::Invoke<int32_t>(0x464688D7); }
	static int32_t GET_CUTSCENE_AUDIO_TIME_MS() { return NativeInvoke::Invoke<int32_t>(0xCA56C61D); }
	static int32_t GET_CUTSCENE_SECTION_PLAYING() { return NativeInvoke::Invoke<int32_t>(0x1026F0D6); }
	static int32_t GET_CUTSCENE_TIME() { return NativeInvoke::Invoke<int32_t>(0x53F5B5AB); }
	static int32_t GET_CUTSCENE_TIME_MS() { return NativeInvoke::Invoke<int32_t>(0x1552C564); }
	static int32_t GET_DIFFERENCE_IN_DAYS_BETWEEN_DATES(int32_t* p0, int32_t* p1, int32_t* p2, int32_t* p3) { return NativeInvoke::Invoke<int32_t>(0x79A447E5, p0, p1, p2, p3); }
	static int32_t GET_EXPERIENCE_FOR_RANK(int32_t rank) { return NativeInvoke::Invoke<int32_t>(0x16F1F9ED, rank); }
	static int32_t GET_EXPERIENCE_MAX_RANK() { return NativeInvoke::Invoke<int32_t>(0x4C0782C8); }
	static int32_t GET_FIRST_INDEX_OF(const char* str, const char* substr) { return NativeInvoke::Invoke<int32_t>(0x893E3C02, str, substr); }
	static int32_t GET_FOLLOW_PED_CAM_ZOOM_LEVEL() { return NativeInvoke::Invoke<int32_t>(0x57583DF1); } 
	static int32_t GET_FOLLOW_VEHICLE_CAM_ZOOM_LEVEL() { return NativeInvoke::Invoke<int32_t>(0x8CD67DE3); } 
	static int32_t GET_GAME_DIFFICULTY() { return NativeInvoke::Invoke<int32_t>(0x337B7E30); }
	static int32_t GET_GAME_IDLE_TIMER() { return NativeInvoke::Invoke<int32_t>(0x69FBFDC); }
	static int32_t GET_GAME_TIMER() { return NativeInvoke::Invoke<int32_t>(0xA4EA0691); }
	static int32_t GET_GRIND_GOAL(int32_t grindId) { return NativeInvoke::Invoke<int32_t>(0xCB12EA00, grindId); }
	static int32_t GET_GRIND_LEVEL(int32_t grindId) { return NativeInvoke::Invoke<int32_t>(0x20E6EB3A, grindId); }
	static int32_t GET_GRIND_PROGRESS(int32_t grindId) { return NativeInvoke::Invoke<int32_t>(0x455FF144, grindId); }
	static int32_t GET_GROUP_SIZE(Group group) { return NativeInvoke::Invoke<int32_t>(0xF7E1A691, group); }
	static int32_t GET_HOURS_OF_DAY() { return NativeInvoke::Invoke<int32_t>(0xD455AF99); }
	static int32_t GET_ID_OF_THIS_THREAD() { return NativeInvoke::Invoke<int32_t>(0xDE524830); }
	static int32_t GET_INDEX_OF_CURRENT_LEVEL() { return NativeInvoke::Invoke<int32_t>(0x6F203C6E); }
	static int32_t GET_INT_FROM_XML_NODE_ATTRIBUTE(int32_t attributeIndex) { return NativeInvoke::Invoke<int32_t>(0x1C524DBB, attributeIndex); }
	static int32_t GET_LAST_LEVEL_PLAYED() { return NativeInvoke::Invoke<int32_t>(0x1209CA49); }
	static int32_t GET_LAUNCH_PARAM_VALUE(int32_t p0, const char* paramName) { return NativeInvoke::Invoke<int32_t>(0x7C68A735, p0, paramName); }
	static int32_t GET_LENGTH_OF_LITERAL_STRING(const char* literalString) { return NativeInvoke::Invoke<int32_t>(0x99379D55, literalString); }
	static int32_t GET_LENGTH_OF_STRING_WITH_THIS_TEXT_LABEL(const char* textLabel) { return NativeInvoke::Invoke<int32_t>(0xA4CA7BE5, textLabel); }
	static int32_t GET_LEVEL_COMPLETION() { return NativeInvoke::Invoke<int32_t>(0xD58CA839); }
	static int32_t GET_LOCAL_PLAYER_AGILITY() { return NativeInvoke::Invoke<int32_t>(0xDE0266E7); }
	static int32_t GET_LOCAL_PLAYER_LEGEND_LEVEL() { return NativeInvoke::Invoke<int32_t>(0x495092E8); }
	static int32_t GET_LOCAL_PLAYER_XP() { return NativeInvoke::Invoke<int32_t>(0x788C69A2); }
	static int32_t GET_LOWEST_USED_GAME_DIFFICULTY() { return NativeInvoke::Invoke<int32_t>(0xE04CBBD5); }
	static int32_t GET_MAP_AREA_FROM_COORDS(float x, float y, float z) { return NativeInvoke::Invoke<int32_t>(0xC7191B29, x, y, z); }
	static int32_t GET_MAX_AMMO_IN_CLIP(Ped ped, uint32_t weaponHash) { return NativeInvoke::Invoke<int32_t>(0x6961E2A4, ped, weaponHash); }
	static int32_t GET_MAX_AMMO_IN_HAND_CLIP_MP(Ped ped, int32_t p1) { return NativeInvoke::Invoke<int32_t>(0xE29942BF, ped, p1); }
	static int32_t GET_MAX_WANTED_LEVEL() { return NativeInvoke::Invoke<int32_t>(0x457F1E44); }
	static int32_t GET_MINUTES_OF_DAY() { return NativeInvoke::Invoke<int32_t>(0xDA92D2D5); }
	static int32_t GET_MINUTES_TO_TIME_OF_DAY(int32_t hour, int32_t minute) { return NativeInvoke::Invoke<int32_t>(0x57CDC0FF, hour, minute); }
	static int32_t GET_NAVMESH_ROUTE_DISTANCE_REMAINING(Ped ped, float* p1, bool* p2) { return NativeInvoke::Invoke<int32_t>(0xD9281778, ped, p1, p2); }
	static int32_t GET_NETWORK_PLAYER_XP(Player player, bool p1) { return NativeInvoke::Invoke<int32_t>(0xF8BC3984, player, p1); }
	static int32_t GET_NEXT_STATION_FOR_TRAIN(Vehicle train) { return NativeInvoke::Invoke<int32_t>(0x234B1475, train); }
	static int32_t GET_NTH_INTEGER_IN_STRING(const char* textLabel, int32_t n) { return NativeInvoke::Invoke<int32_t>(0x258DD91D, textLabel, n); }
	static int32_t GET_NUMBER_OF_FIRES_IN_RANGE(float x, float y, float z, float radius) { return NativeInvoke::Invoke<int32_t>(0x654D93B7, x, y, z, radius); }
	static int32_t GET_NUMBER_OF_PED_DRAWABLE_VARIATIONS(Ped ped, int32_t componentId) { return NativeInvoke::Invoke<int32_t>(0x9754C27D, ped, componentId); }
	static int32_t GET_NUMBER_OF_PED_TEXTURE_VARIATIONS(Ped ped, int32_t componentId, int32_t drawableIndex) { return NativeInvoke::Invoke<int32_t>(0x83D9FBE7, ped, componentId, drawableIndex); }
	static int32_t GET_NUMBER_OF_PLAYERS() { return NativeInvoke::Invoke<int32_t>(0x4C1B8867); }
	static int32_t GET_NUMBER_OF_PLAYERS_IN_TEAM(int32_t team) { return NativeInvoke::Invoke<int32_t>(0x6435F71, team); }
	static int32_t GET_NUMBER_OF_STREAMING_REQUESTS() { return NativeInvoke::Invoke<int32_t>(0xC2EE9A02); }
	static int32_t GET_NUMBER_OF_THREADS_RUNNING_THIS_SCRIPT(const char* scriptName) { return NativeInvoke::Invoke<int32_t>(0x1E941253, scriptName); }
	static int32_t GET_NUMBER_OF_VEHICLE_COLOURS(Vehicle vehicle) { return NativeInvoke::Invoke<int32_t>(0xF2442EE2, vehicle); }
	static int32_t GET_NUMBER_OF_XML_NODES() { return NativeInvoke::Invoke<int32_t>(0x3CAACE0D); }
	static int32_t GET_NUMBER_OF_XML_NODE_ATTRIBUTES() { return NativeInvoke::Invoke<int32_t>(0xED658C76); }
	static int32_t GET_NUM_LOADOUT_SLOTS() { return NativeInvoke::Invoke<int32_t>(0xB197B3D2); }
	static int32_t GET_OBJECT_BONE_INDEX(Object object, const char* boneName) { return NativeInvoke::Invoke<int32_t>(0x59F98953, object, boneName); }
	static int32_t GET_PAYNEKILLER_AMT() { return NativeInvoke::Invoke<int32_t>(0x8DF47C9D); }
	static int32_t GET_PED_ALERTNESS(Ped ped) { return NativeInvoke::Invoke<int32_t>(0xF83E4DAF, ped); }
	static int32_t GET_PED_ARMOUR(Ped ped) { return NativeInvoke::Invoke<int32_t>(0x2CE311A7, ped); }
	static int32_t GET_PED_BODY_PART_DAMAGE(Ped ped, int32_t bodyPartId) { return NativeInvoke::Invoke<int32_t>(0x326CB003, ped, bodyPartId); }
	static int32_t GET_PED_BULLETTIME_STATUS(Ped ped) { return NativeInvoke::Invoke<int32_t>(0xD2B258C4, ped); }
	static int32_t GET_PED_COMBAT_ABILITY(Ped ped) { return NativeInvoke::Invoke<int32_t>(0xDCC779BB, ped); }
	static int32_t GET_PED_COMBAT_MOVEMENT(Ped ped) { return NativeInvoke::Invoke<int32_t>(0xF3E7730E, ped); }
	static int32_t GET_PED_DRAWABLE_VARIATION(Ped ped, int32_t componentId) { return NativeInvoke::Invoke<int32_t>(0x29850FE2, ped, componentId); }
	static int32_t GET_PED_EMOTION_STATE(Ped ped) { return NativeInvoke::Invoke<int32_t>(0x329F833E, ped); }
	static int32_t GET_PED_HEALTH(Ped ped) { return NativeInvoke::Invoke<int32_t>(0xECC91AC, ped); }
	static int32_t GET_PED_MAX_HEALTH(Ped ped) { return NativeInvoke::Invoke<int32_t>(0xA45B6C8D, ped); }
	static int32_t GET_PED_PALETTE_VARIATION(Ped ped, int32_t componentId) { return NativeInvoke::Invoke<int32_t>(0xEF1BC082, ped, componentId); }
	static int32_t GET_PED_PROP_INDEX(Ped ped, int32_t componentId) { return NativeInvoke::Invoke<int32_t>(0x746DDAC0, ped, componentId); }
	static int32_t GET_PED_TEXTURE_VARIATION(Ped ped, int32_t componentId) { return NativeInvoke::Invoke<int32_t>(0xC0A8590A, ped, componentId); }
	static int32_t GET_PED_TYPE(Ped ped) { return NativeInvoke::Invoke<int32_t>(0xB1460D43, ped); }
	static int32_t GET_PLAYER_BULLET_TIME_STATE(Player player) { return NativeInvoke::Invoke<int32_t>(0x105C960, player); }
	static int32_t GET_PLAYER_EXPERIENCE() { return NativeInvoke::Invoke<int32_t>(0x2100F7A5); }
	static int32_t GET_PLAYER_MAX_ARMOUR(Player player) { return NativeInvoke::Invoke<int32_t>(0x2A50657, player); }
	static int32_t GET_PLAYER_OXYGEN(Player player) { return NativeInvoke::Invoke<int32_t>(0x35EBD55D, player); }
	static int32_t GET_PLAYER_POINTS() { return NativeInvoke::Invoke<int32_t>(0x38111C8B); }
	static int32_t GET_PLAYER_RANK() { return NativeInvoke::Invoke<int32_t>(0x302394F); }
	static int32_t GET_PLAYER_SCORE(Player player) { return NativeInvoke::Invoke<int32_t>(0xA9FF2C40, player); }
	static int32_t GET_PLAYER_STREAK_ACTIVATION_LEVEL() { return NativeInvoke::Invoke<int32_t>(0x77C2EB66); }
	static int32_t GET_PLAYER_TEAM(Player player) { return NativeInvoke::Invoke<int32_t>(0x9873E404, player); }
	static int32_t GET_PLAYER_WANTED_LEVEL(Player player) { return NativeInvoke::Invoke<int32_t>(0xBDCDD163, player); }
	static int32_t GET_PRESET_DURATION(const char* presetName) { return NativeInvoke::Invoke<int32_t>(0xB61080D1, presetName); }
	static int32_t GET_PROFILE_SETTING(uint32_t hash) { return NativeInvoke::Invoke<int32_t>(0xD374BEBC, hash); }
	static int32_t GET_RANDOM_INT_IN_RANGE(int32_t min, int32_t max) { return NativeInvoke::Invoke<int32_t>(0x4051115B, min, max); }
	static int32_t GET_REAL_GAME_TIMER() { return NativeInvoke::Invoke<int32_t>(0x5FBEB0F6); }
	static int32_t GET_REAL_TIME() { return NativeInvoke::Invoke<int32_t>(0xCBB4CA94); }
	static int32_t GET_REQUESTED_LEVEL() { return NativeInvoke::Invoke<int32_t>(0xE4D2AEE3); }
	static int32_t GET_ROPE_VERTEX_COUNT(Any rope) { return NativeInvoke::Invoke<int32_t>(0x5131CD2C, rope); }
	static int32_t GET_SAVEGAME_LEVEL() { return NativeInvoke::Invoke<int32_t>(0x6BCE5E43); }
	static int32_t GET_SCRIPT_ID_FROM_NAME_HASH(uint32_t hash) { return NativeInvoke::Invoke<int32_t>(0xB28F8DC4, hash); }
	static int32_t GET_SCRIPT_MOVIE_FRAMES_REMAINING(int32_t p0) { return NativeInvoke::Invoke<int32_t>(0xA173AAD6, p0); }
	static int32_t GET_SCRIPT_RENDERTARGET_RENDER_ID() { return NativeInvoke::Invoke<int32_t>(0xE7617459); }
	static int32_t GET_SCRIPT_TASK_STATUS(Ped ped, int32_t task) { return NativeInvoke::Invoke<int32_t>(0xB2477B23, ped, task); }
	static int32_t GET_SEQUENCE_PROGRESS(Any taskSequence) { return NativeInvoke::Invoke<int32_t>(0xA3419909, taskSequence); }
	static int32_t GET_SOUND_ID() { return NativeInvoke::Invoke<int32_t>(0x6AE0AD56); }
	static int32_t GET_STABLE_NUM_OF_PRIORITY_REQUESTS() { return NativeInvoke::Invoke<int32_t>(0x84BBBC8B); }
	static int32_t GET_STABLE_NUM_OF_STREAMING_REQUESTS() { return NativeInvoke::Invoke<int32_t>(0xCDADFF5D); }
	static int32_t GET_STREAM_PED_PACK_ID(uint32_t hash) { return NativeInvoke::Invoke<int32_t>(0x70833487, hash); }
	static int32_t GET_SUPPRESSOR_DAMAGE_LEVEL(Weapon weapon) { return NativeInvoke::Invoke<int32_t>(0x34A03DCE, weapon); }
	static int32_t GET_TIME_SINCE_LAST_LMS_ACTIVATION() { return NativeInvoke::Invoke<int32_t>(0x9A1FA508); }
	static int32_t GET_TIME_SINCE_PED_MADE_NOISE(Ped ped, int32_t p1) { return NativeInvoke::Invoke<int32_t>(0x923C24E6, ped, p1); }
	static int32_t GET_TIME_SINCE_REMOTE_PED_MOVED(Ped ped) { return NativeInvoke::Invoke<int32_t>(0xA06F9B6C, ped); }
	static int32_t GET_TIME_TIL_NEXT_STATION(Vehicle train) { return NativeInvoke::Invoke<int32_t>(0x443BD51F, train); }
	static int32_t GET_TRANSITION_MOVIE_FRAMES_REMAINING() { return NativeInvoke::Invoke<int32_t>(0xC483FB4A); }
	static int32_t GET_VEHICLE_BONE_INDEX(Vehicle vehicle, const char* boneName) { return NativeInvoke::Invoke<int32_t>(0x235C4335, vehicle, boneName); }
	static int32_t GET_VEHICLE_DOOR_LOCK_STATUS(Vehicle vehicle) { return NativeInvoke::Invoke<int32_t>(0xD72CEF2, vehicle); }
	static int32_t GET_VEHICLE_FIXED_WEAPON_FIRING_PATTERN_MODE(Vehicle vehicle, int32_t weaponIndex) { return NativeInvoke::Invoke<int32_t>(0x38D33245, vehicle, weaponIndex); }
	static int32_t GET_VEHICLE_HEALTH(Vehicle vehicle) { return NativeInvoke::Invoke<int32_t>(0x3FBCAEB5, vehicle); }
	static int32_t GET_VEHICLE_MAX_NUMBER_OF_PASSENGERS(Vehicle vehicle) { return NativeInvoke::Invoke<int32_t>(0xA2FC08C, vehicle); }
	static int32_t GET_VEHICLE_MODEL_VALUE(uint32_t modelHash) { return NativeInvoke::Invoke<int32_t>(0x58FEFC3D, modelHash); }
	static int32_t GET_VEHICLE_NUMBER_OF_PASSENGERS(Vehicle vehicle) { return NativeInvoke::Invoke<int32_t>(0x1EF20849, vehicle); }
	static int32_t GET_VEHICLE_SIREN_HEALTH(Vehicle vehicle) { return NativeInvoke::Invoke<int32_t>(0x64F0CA0B, vehicle); }
	static int32_t GET_WEAPONTYPE_AMMO(uint32_t weaponHash) { return NativeInvoke::Invoke<int32_t>(0x687CABD1, weaponHash); }
	static int32_t GET_WEAPON_AMMO(Weapon weapon) { return NativeInvoke::Invoke<int32_t>(0x2AFE4788, weapon); }
	static int32_t GET_WEAPON_AMMO_IN_CLIP(Weapon weapon) { return NativeInvoke::Invoke<int32_t>(0x9E9F10F, weapon); }
	static int32_t GET_WEAPON_GUNTYPE(uint32_t weaponHash) { return NativeInvoke::Invoke<int32_t>(0x43AF022D, weaponHash); }
	static int32_t GET_WEAPON_LEVEL(uint32_t weaponHash) { return NativeInvoke::Invoke<int32_t>(0x4F06494C, weaponHash); }
	static int32_t GET_WEAPON_TYPE(Weapon weapon) { return NativeInvoke::Invoke<int32_t>(0x706A4B6F, weapon); }
	static int32_t ISEQ_GET_STATE(uint32_t hash) { return NativeInvoke::Invoke<int32_t>(0xC8599BDE, hash); }
	static int32_t LOBBY_GET_MIN_PLAYERS() { return NativeInvoke::Invoke<int32_t>(0xC5731817); }
	static int32_t LOBBY_GET_NUM_ACTIVE_OPTIONS() { return NativeInvoke::Invoke<int32_t>(0x8DB907E0); }
	static int32_t LOBBY_GET_NUM_GAME_MODES() { return NativeInvoke::Invoke<int32_t>(0xE30A3B07); }
	static int32_t LOBBY_GET_NUM_OPTIONS(int32_t gameMode) { return NativeInvoke::Invoke<int32_t>(0x1DBC1E68, gameMode); }
	static int32_t LOBBY_GET_NUM_SUB_OPTIONS(int32_t gameMode, int32_t option) { return NativeInvoke::Invoke<int32_t>(0x34332D95, gameMode, option); }
	static int32_t LOBBY_GET_OPTION_VALUE(int32_t gameMode, int32_t option) { return NativeInvoke::Invoke<int32_t>(0xFD0AF1D4, gameMode, option); }
	static int32_t LOBBY_GET_SELECTED_GAME_MODE() { return NativeInvoke::Invoke<int32_t>(0xE65EC1C1); }
	static int32_t NETWORK_GET_AVATAR_SLOT_SELECTED_SEX(uint32_t avatarHash) { return NativeInvoke::Invoke<int32_t>(0x7EF9234A, avatarHash); }
	static int32_t NETWORK_GET_FRIEND_COUNT() { return NativeInvoke::Invoke<int32_t>(0xA396ACDE); }
	static int32_t NETWORK_GET_GAME_MODE() { return NativeInvoke::Invoke<int32_t>(0x542F6097); }
	static int32_t NETWORK_GET_MAX_PRIVATE_SLOTS() { return NativeInvoke::Invoke<int32_t>(0xFF2121DE); }
	static int32_t NETWORK_GET_MAX_SLOTS() { return NativeInvoke::Invoke<int32_t>(0xE7DA761C); }
	static int32_t NETWORK_GET_NUMBER_OF_GAMES() { return NativeInvoke::Invoke<int32_t>(0x3429AFE6); }
	static int32_t NETWORK_GET_NUM_PLAYERS_MET() { return NativeInvoke::Invoke<int32_t>(0xB04FC561); }
	static int32_t NETWORK_GET_PARAM_NETTEST() { return NativeInvoke::Invoke<int32_t>(0x186725B); }
	static int32_t NETWORK_GET_PARAM_NETTEST_HOST() { return NativeInvoke::Invoke<int32_t>(0x6AA467E5); }
	static int32_t NETWORK_GET_PLAYER_ACTIVE_STREAK(Player player) { return NativeInvoke::Invoke<int32_t>(0xFE3BB23A, player); }
	static int32_t NETWORK_GET_PLAYER_ACTIVE_STREAK_LEVEL(Player player) { return NativeInvoke::Invoke<int32_t>(0x71168B1F, player); }
	static int32_t NETWORK_GET_PLAYER_AVATAR_SEX(Player player) { return NativeInvoke::Invoke<int32_t>(0xBD0930B9, player); }
	static int32_t NETWORK_GET_PLAYER_CASH() { return NativeInvoke::Invoke<int32_t>(0x9CE0F8F1); }
	static int32_t NETWORK_GET_TIME_PLAYER_HAS_BEEN_DEAD_FOR(Player player) { return NativeInvoke::Invoke<int32_t>(0xFD0966E3, player); }
	static int32_t NETWORK_LEVEL_DATA_GET_NUM_NODES(const char* name) { return NativeInvoke::Invoke<int32_t>(0xD0FD0BA0, name); }
	static int32_t NET_GET_PLAYER_GANG_ID(Player player) { return NativeInvoke::Invoke<int32_t>(0xBB7E7FFA, player); }
	static int32_t NET_GET_PLAYER_GANG_RANK(Player player) { return NativeInvoke::Invoke<int32_t>(0xD40B452C, player); }
	static int32_t PED_GET_ACTION_INTENTION_STATUS(Ped ped, int32_t actionId) { return NativeInvoke::Invoke<int32_t>(0x400A3649, ped, actionId); }
	static int32_t ROUND(float value) { return NativeInvoke::Invoke<int32_t>(0x323B0E24, value); }
	static int32_t SCRIPT_VAR_GET_INT(const char* name) { return NativeInvoke::Invoke<int32_t>(0x3CD83D18, name); }
	static int32_t SCRIPT_VAR_HASH_GET_INT(uint32_t hash) { return NativeInvoke::Invoke<int32_t>(0x0CF2FB4, hash); }
	static int32_t SEV_ID_TO_INDEX(int32_t sevId) { return NativeInvoke::Invoke<int32_t>(0x374F72FE, sevId); }
	static int32_t SEV_INDEX_TO_ID(int32_t sevIndex) { return NativeInvoke::Invoke<int32_t>(0x66169946, sevIndex); }
	static int32_t SHIFT_LEFT(int32_t value, int32_t bitShift) { return NativeInvoke::Invoke<int32_t>(0x314CC6CD, value, bitShift); } 
	static int32_t SHIFT_RIGHT(int32_t value, int32_t bitShift) { return NativeInvoke::Invoke<int32_t>(0x352633CA, value, bitShift); } 
	static int32_t START_NEW_SCRIPT(const char* scriptName, int32_t stackSize) { return NativeInvoke::Invoke<int32_t>(0x3F166D0E, scriptName, stackSize); }
	static int32_t START_NEW_SCRIPT_TYPED(const char* scriptName, int32_t stackSize, int32_t unk) { return NativeInvoke::Invoke<int32_t>(0x9EE416E7, scriptName, stackSize, unk); }
	static int32_t START_NEW_SCRIPT_TYPED_WITH_ARGS(const char* scriptName, Any* args, int32_t argCount, int32_t stackSize, int32_t unk) { return NativeInvoke::Invoke<int32_t>(0x50A1D455, scriptName, args, argCount, stackSize, unk); } 
	static int32_t START_NEW_SCRIPT_WITH_ARGS(const char* scriptName, Any* args, int32_t argCount, int32_t stackSize) { return NativeInvoke::Invoke<int32_t>(0x4A2100E4, scriptName, args, argCount, stackSize); } 
	static int32_t STAT_GET_INT(const char* statName) { return NativeInvoke::Invoke<int32_t>(0x1C6FE43E, statName); }
	static int32_t STAT_HASH_GET_INT(uint32_t statHash) { return NativeInvoke::Invoke<int32_t>(0xEC6F7181, statHash); }
	static int32_t TIMERA() { return NativeInvoke::Invoke<int32_t>(0x45C8C188); }
	static int32_t TIMERB() { return NativeInvoke::Invoke<int32_t>(0x330A9C0C); }
	static int32_t TIMERSYSTEM() { return NativeInvoke::Invoke<int32_t>(0x845A1774); }
	static int32_t TIME_SINCE_LAST_MONOLOGUE() { return NativeInvoke::Invoke<int32_t>(0x4B91ACE8); }
	static int32_t _GET_ARCADE_CHECKPOINT() { return NativeInvoke::Invoke<int32_t>(0x8F64EDF4); }
	static int32_t _GET_CHALLENGE_MODE_STREAK() { return NativeInvoke::Invoke<int32_t>(0xDBD7F6A3); }
	static uint32_t GET_ACHIEVEMENT_HASH(int32_t p0) { return NativeInvoke::Invoke<uint32_t>(0x902D558D, p0); }
	static uint32_t GET_CURRENT_BASIC_COP_MODEL() { return NativeInvoke::Invoke<uint32_t>(0xCDA04E40); }
	static uint32_t GET_CURRENT_BASIC_POLICE_VEHICLE_MODEL() { return NativeInvoke::Invoke<uint32_t>(0xE8F2B493); }
	static uint32_t GET_CURRENT_POLICE_VEHICLE_MODEL() { return NativeInvoke::Invoke<uint32_t>(0xAD1B93E5); }
	static uint32_t GET_CURRENT_TAXI_VEHICLE_MODEL() { return NativeInvoke::Invoke<uint32_t>(0x5CC9B637); }
	static uint32_t GET_FRONTEND_STATE_NAME(int32_t bufferSize, char* buffer) { return NativeInvoke::Invoke<uint32_t>(0x4695E609, bufferSize, buffer); }
	static uint32_t GET_HASH_KEY(const char* value) { return NativeInvoke::Invoke<uint32_t>(0x98EFF6F1, value); }
	static uint32_t GET_KEY_FOR_PED_IN_ROOM(Ped ped) { return NativeInvoke::Invoke<uint32_t>(0x2A870D57, ped); }
	static uint32_t GET_KEY_FOR_VEHICLE_IN_ROOM(Vehicle vehicle) { return NativeInvoke::Invoke<uint32_t>(0x660E2D00, vehicle); }
	static uint32_t GET_LASER_SIGHT_ATTACHMENT(Weapon weapon) { return NativeInvoke::Invoke<uint32_t>(0x5019DC1E, weapon); }
	static uint32_t GET_OBJECT_MODEL(Object object) { return NativeInvoke::Invoke<uint32_t>(0x70BECF6A, object); }
	static uint32_t GET_PED_DAMAGE_WEAPON_TYPE(Ped ped) { return NativeInvoke::Invoke<uint32_t>(0x93FBC5C1, ped); }
	static uint32_t GET_PED_MODEL(Ped ped) { return NativeInvoke::Invoke<uint32_t>(0x25F5E8E1, ped); }
	static uint32_t GET_PLAYER_CAUSE_OF_DEATH(Player player) { return NativeInvoke::Invoke<uint32_t>(0x07E3DE8, player); }
	static uint32_t GET_PLAYER_COVER_SECTION_UID(Player player) { return NativeInvoke::Invoke<uint32_t>(0x14288A76, player); }
	static uint32_t GET_PLAYER_COVER_UID(Player player) { return NativeInvoke::Invoke<uint32_t>(0xCDF4F42F, player); }
	static uint32_t GET_PLAYER_KILLER_WEAPON(Player player) { return NativeInvoke::Invoke<uint32_t>(0x46299DFB, player); }
	static uint32_t GET_SCENE_PED_MODEL(uint32_t unkHash) { return NativeInvoke::Invoke<uint32_t>(0x236815DF, unkHash); }
	static uint32_t GET_SELECTED_PED_GADGET(Ped ped) { return NativeInvoke::Invoke<uint32_t>(0x943379C2, ped); }
	static uint32_t GET_VEHICLE_MODEL(Vehicle vehicle) { return NativeInvoke::Invoke<uint32_t>(0x70FB6D3A, vehicle); }
	static uint32_t GET_WEAPONTYPE_MODEL(uint32_t weaponHash) { return NativeInvoke::Invoke<uint32_t>(0x44E1C269, weaponHash); }
	static uint32_t GET_WEAPON_HUD_TEXTURE(uint32_t weaponHash) { return NativeInvoke::Invoke<uint32_t>(0x9D6061F5, weaponHash); }
	static uint32_t NETWORK_GET_AVATAR_SELECTED_DEATHMATCH_SLOT_HASH() { return NativeInvoke::Invoke<uint32_t>(0x51611F4D); }
	static uint32_t NETWORK_GET_PLAYER_AVATAR_SLOT_HASH(Player player) { return NativeInvoke::Invoke<uint32_t>(0xEEFC5BFB, player); }
	static void ACTIVATE_BULLET_TIME(bool p0, float p1, bool p2) { NativeInvoke::Invoke<void>(0xFF9FE21C, p0, p1, p2); }
	static void ACTIVATE_DETONATOR(Ped ped, bool p1) { NativeInvoke::Invoke<void>(0x1C5D5D2D, ped, p1); }
	static void ADD_ADRENALINE(float amount, bool p1) { NativeInvoke::Invoke<void>(0x9818A492, amount, p1); }
	static void ADD_AMMO_TO_PED(Ped ped, uint32_t weaponHash, int32_t ammo, bool p3) { NativeInvoke::Invoke<void>(0x7F0580C7, ped, weaponHash, ammo, p3); }
	static void ADD_ARMOUR_TO_PED(Ped ped, int32_t armour) { NativeInvoke::Invoke<void>(0xF686B26E, ped, armour); }
	static void ADD_BLOOD_POOL(float x, float y, float z, float p3, float p4, float p5) { NativeInvoke::Invoke<void>(0xBD6B7E68, x, y, z, p3, p4, p5); }
	static void ADD_BULLET_CAM_TEXT(const char* text, float p1, float p2, int32_t p3, int32_t p4, float p5, float p6, int32_t p7, int32_t p8, int32_t p9, float p10, float p11, float p12, float p13) { NativeInvoke::Invoke<void>(0x3A5A1CDB, text, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13); }
	static void ADD_CAM_SPLINE_NODE(Cam cam, float x, float y, float z, float xRot, float yRot, float zRot, int32_t length) { NativeInvoke::Invoke<void>(0xAD3C7EAA, cam, x, y, z, xRot, yRot, zRot, length); } 
	static void ADD_EXPLOSION(float x, float y, float z, int32_t explosionType, float damageScale, bool isAudible, bool isInvisible, float unk) { NativeInvoke::Invoke<void>(0x10AF5258, x, y, z, explosionType, damageScale, isAudible, isInvisible, unk); }
	static void ADD_EXPLOSION_WITH_CAUSE(Player player, float x, float y, float z, int32_t explosionType, float damageScale, bool isAudible, bool isInvisible, float p8, bool p9) { NativeInvoke::Invoke<void>(0xBF9BBF0, player, x, y, z, explosionType, damageScale, isAudible, isInvisible, p8, p9); }
	static void ADD_FOLLOW_NAVMESH_TO_PHONE_TASK(Ped ped, float x, float y, float z) { NativeInvoke::Invoke<void>(0x0D7303F, ped, x, y, z); }
	static void ADD_GROUND_PLANE_COLLISION_TO_PARTICLE_FX(Any ptfxHandle, float p1, float p2, float p3, float p4, float p5) { NativeInvoke::Invoke<void>(0x6DF10D45, ptfxHandle, p1, p2, p3, p4, p5); }
	static void ADD_GROUP_TO_NETWORK_RESTART_NODE_GROUP_LIST(int32_t group) { NativeInvoke::Invoke<void>(0x3105DC1F, group); }
	static void ADD_KILLXP_RULE_ANYKILLER(Any p0, Any p1) { NativeInvoke::Invoke<void>(0xCEB6BD96, p0, p1); }
	static void ADD_KILLXP_RULE_ANYVICTIM(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x3558D8E8, p0, p1); }
	static void ADD_LINE_TO_CONVERSATION(int32_t index, int32_t p1, const char* p2, const char* p3, int32_t p4, int32_t p5, int32_t p6, bool p7, bool p8) { NativeInvoke::Invoke<void>(0x96CD0513, index, p1, p2, p3, p4, p5, p6, p7, p8); }
	static void ADD_MULTIPLAYER_MESSAGE(const char* message, bool belowTimer) { NativeInvoke::Invoke<void>(0xDFE98FBC, message, belowTimer); }
	static void ADD_NEARBY_COLLISION_TO_PARTICLE_FX(Any ptfxHandle, float x, float y, float z, float radius) { NativeInvoke::Invoke<void>(0xA3D7374F, ptfxHandle, x, y, z, radius); }
	static void ADD_NEXT_MESSAGE_TO_PREVIOUS_BRIEFS(bool toggle) { NativeInvoke::Invoke<void>(0xB58B25BD, toggle); }
	static void ADD_OBJECT_TO_EXPLOSION_OCCLUSION_TESTS(Object object, bool toggle) { NativeInvoke::Invoke<void>(0xC88787A4, object, toggle); }
	static void ADD_OBJECT_TO_INTERIOR_ROOM_BY_KEY(Object object, Any p1, Any p2) { NativeInvoke::Invoke<void>(0xF062047C, object, p1, p2); }
	static void ADD_OBJECT_TO_INTERIOR_ROOM_BY_NAME(Object object, const char* name) { NativeInvoke::Invoke<void>(0x27F07BD9, object, name); }
	static void ADD_PATROL_ROUTE_LINK(int32_t p0, int32_t p1) { NativeInvoke::Invoke<void>(0xD8761BB3, p0, p1); }
	static void ADD_PATROL_ROUTE_NODE(int32_t p0, const char* p1, float x1, float y1, float z1, float x2, float y2, float z2, int32_t p8) { NativeInvoke::Invoke<void>(0x21B48F10, p0, p1, x1, y1, z1, x2, y2, z2, p8); }
	static void ADD_PAYNEKILLER(int32_t amount) { NativeInvoke::Invoke<void>(0xEFBF6795, amount); }
	static void ADD_PED_CLONE(Ped ped, float x, float y, float z, float heading) { NativeInvoke::Invoke<void>(0x201A0FC, ped, x, y, z, heading); }
	static void ADD_PED_TO_CONVERSATION(int32_t index, int32_t speakerConversationIndex, Ped ped, const char* p3) { NativeInvoke::Invoke<void>(0xF8D5EB86, index, speakerConversationIndex, ped, p3); } 
	static void ADD_PED_TO_CONVERSATION_ENUM(int32_t index, int32_t speakerConversationIndex, Ped ped, uint32_t p3) { NativeInvoke::Invoke<void>(0x53CF1845, index, speakerConversationIndex, ped, p3); }
	static void ADD_PED_TO_MISSION_DELETION_LIST(Ped ped, bool p1) { NativeInvoke::Invoke<void>(0x302E8AC8, ped, p1); }
	static void ADD_PED_USE_COVER_ENTRY(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x71F647CC, p0, p1); }
	static void ADD_PLACEMENT_TO_INTERIOR_ROOM_BY_NAME(Any p0, Any p1) { NativeInvoke::Invoke<void>(0xE4961E79, p0, p1); }
	static void ADD_PLAYER_SCORE(Player player, int32_t amount) { NativeInvoke::Invoke<void>(0x692414AA, player, amount); }
	static void ADD_SCENARIO_BLOCKING_AREA(float x1, float y1, float z1, float x2, float y2, float z2) { NativeInvoke::Invoke<void>(0xA38C0234, x1, y1, z1, x2, y2, z2); }
	static void ADD_SCRIPTED_WEAPON_MODIFIER(Ped ped, Any p1) { NativeInvoke::Invoke<void>(0xDC9BD147, ped, p1); }
	static void ADD_SCRIPT_TO_OBJECT(const char* scriptName, uint32_t modelHash, int32_t p2, float p3, bool p4) { NativeInvoke::Invoke<void>(0x68D34980, scriptName, modelHash, p2, p3, p4); }
	static void ADD_SCRIPT_TO_RANDOM_PED(const char* scriptName, uint32_t modelHash, int32_t p2, bool p3) { NativeInvoke::Invoke<void>(0xECC76C3D, scriptName, modelHash, p2, p3); }
	static void ADD_SPAWN_BLOCKING_AREA(float x, float y, float z, float radius) { NativeInvoke::Invoke<void>(0xDAA55B46, x, y, z, radius); }
	static void ADD_SPECIAL_FX_MODIFIER(const char* name, float p1, float p2, float p3, float p4) { NativeInvoke::Invoke<void>(0xAC7F5BB8, name, p1, p2, p3, p4); }
	static void ADD_STRING_TO_NEWS_SCROLLBAR(const char* str) { NativeInvoke::Invoke<void>(0x0DDFD22, str); }
	static void ADD_TICKER_MESSAGE(Any* data) { NativeInvoke::Invoke<void>(0x151A8CA9, data); }
	static void ADD_TO_WIDGET_COMBO(Any p0) { NativeInvoke::Invoke<void>(0xE136E83E, p0); }
	static void ADD_VEHICLE_STUCK_CHECK(Vehicle vehicle, float p1, int32_t p2) { NativeInvoke::Invoke<void>(0x3619F647, vehicle, p1, p2); }
	static void ADD_VEHICLE_STUCK_CHECK_WITH_WARP(Vehicle vehicle, float p1, int32_t p2, bool p3, bool p4, bool p5, int32_t p6) { NativeInvoke::Invoke<void>(0xC8B789AD, vehicle, p1, p2, p3, p4, p5, p6); }
	static void ADD_VEHICLE_TO_MISSION_DELETION_LIST(Vehicle vehicle) { NativeInvoke::Invoke<void>(0xF6E45147, vehicle); }
	static void ADD_VEHICLE_UPSIDEDOWN_CHECK(Vehicle vehicle) { NativeInvoke::Invoke<void>(0x3A13D384, vehicle); }
	static void ADD_WIDGET_STRING(const char* string) { NativeInvoke::Invoke<void>(0xC541594C, string); }
	static void ADJUST_AMMO_ATTEMPTS() { NativeInvoke::Invoke<void>(0xF4BFDBAD); }
	static void ADJUST_PAIN_KILLERS_ATTEMPTS() { NativeInvoke::Invoke<void>(0x36620C4E); }
	static void ADJUST_TIMECYCLE_MODIFIER_OVERRIDE(float p0, float p1, int32_t p2) { NativeInvoke::Invoke<void>(0xFE471B6E, p0, p1, p2); }
	static void ALLOCATE_VEHICLE_INST_LIGHT_TUNE_DATA(Vehicle vehicle) { NativeInvoke::Invoke<void>(0x33837FD9, vehicle); }
	static void ALLOW_BULLET_CAMERA_CHEAT(bool toggle) { NativeInvoke::Invoke<void>(0x3A19D0D1, toggle); }
	static void ALLOW_BULLET_CAMERA_SLOWDOWN(bool toggle) { NativeInvoke::Invoke<void>(0xC6AB9205, toggle); }
	static void ALLOW_BULLET_CAMERA_TO_GAMEPLAY(bool p0, bool p1) { NativeInvoke::Invoke<void>(0x2BB2C58F, p0, p1); }
	static void ALLOW_BULLET_CAMERA_TUTORIAL_MSG(bool toggle) { NativeInvoke::Invoke<void>(0xB20B0BD2, toggle); }
	static void APPLY_DAMAGE_TO_PED(Ped ped, int32_t damageAmount, bool p2) { NativeInvoke::Invoke<void>(0x4DC27FCF, ped, damageAmount, p2); }
	static void APPLY_DAMAGE_TO_PED_BODY_PART(Ped ped, int32_t bodyPartId, int32_t amount) { NativeInvoke::Invoke<void>(0x6B997326, ped, bodyPartId, amount); }
	static void APPLY_DAMAGE_TO_PED_WITH_HASH(Ped ped, int32_t damageAmount, uint32_t damageTypeHash) { NativeInvoke::Invoke<void>(0x78C7D607, ped, damageAmount, damageTypeHash); }
	static void APPLY_FORCE_TO_OBJECT(Object object, int32_t forceType, float forceX, float forceY, float forceZ, float offX, float offY, float offZ, int32_t bone, bool isDirectionRel, bool ignoreUpVec, bool isForceRel) { NativeInvoke::Invoke<void>(0xB4FCA1F9, object, forceType, forceX, forceY, forceZ, offX, offY, offZ, bone, isDirectionRel, ignoreUpVec, isForceRel); }
	static void APPLY_FORCE_TO_PED(Ped ped, int32_t forceType, float forceX, float forceY, float forceZ, float offX, float offY, float offZ, int32_t bone, bool isDirectionRel, bool ignoreUpVec, bool isForceRel) { NativeInvoke::Invoke<void>(0x343ABB0E, ped, forceType, forceX, forceY, forceZ, offX, offY, offZ, bone, isDirectionRel, ignoreUpVec, isForceRel); }
	static void APPLY_FORCE_TO_VEHICLE(Vehicle vehicle, int32_t forceType, float forceX, float forceY, float forceZ, float offX, float offY, float offZ, int32_t bone, bool isDirectionRel, bool ignoreUpVec, bool isForceRel) { NativeInvoke::Invoke<void>(0x3130AB0A, vehicle, forceType, forceX, forceY, forceZ, offX, offY, offZ, bone, isDirectionRel, ignoreUpVec, isForceRel); }
	static void APPLY_LOADOUT_ITEM(Ped ped, uint32_t p1, uint32_t p2) { NativeInvoke::Invoke<void>(0x33EA6ABF, ped, p1, p2); }
	static void APPLY_PLAYER_PRELOAD_VARIATION(Ped ped, int32_t index) { NativeInvoke::Invoke<void>(0xAC6A7AD3, ped, index); }
	static void APPLY_UNIFORMLY_DISTRIBUTED_IMPULSE_TO_RAGDOLL(Ped ped, float xOffset, float yOffset, float zOffset) { NativeInvoke::Invoke<void>(0x5B121A4C, ped, xOffset, yOffset, zOffset); }
	static void ASSERTF(bool p0, const char* format, int32_t argCount, ...) {}
	static void ASSISTED_MOVEMENT_ADD_POINT(float x, float y, float z) { NativeInvoke::Invoke<void>(0xD48E643D, x, y, z); }
	static void ASSISTED_MOVEMENT_CLOSE_ROUTE() { NativeInvoke::Invoke<void>(0xF23277F3); }
	static void ASSISTED_MOVEMENT_FLUSH_ROUTE() { NativeInvoke::Invoke<void>(0xD04568B9); }
	static void ASSISTED_MOVEMENT_OPEN_ROUTE() { NativeInvoke::Invoke<void>(0x830DDFC9); }
	static void ASSISTED_MOVEMENT_SET_WIDTH(float width) { NativeInvoke::Invoke<void>(0x76FFD005, width); }
	static void ATTACH_CAM_TO_OBJECT(Cam cam, Object object, float offsetX, float offsetY, float offsetZ, bool heading) { NativeInvoke::Invoke<void>(0xD8AD0661, cam, object, offsetX, offsetY, offsetZ, heading); } 
	static void ATTACH_CAM_TO_PED(Cam cam, Ped ped, float offsetX, float offsetY, float offsetZ, bool heading) { NativeInvoke::Invoke<void>(0xAFE56AF8, cam, ped, offsetX, offsetY, offsetZ, heading); }
	static void ATTACH_CAM_TO_VEHICLE(Cam cam, Vehicle vehicle, float offsetX, float offsetY, float offsetZ, bool heading) { NativeInvoke::Invoke<void>(0x8D33A0B5, cam, vehicle, offsetX, offsetY, offsetZ, heading); }
	static void ATTACH_EXPLOSIVE_INTERACT_VOLUME_TO_PED(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9, Any p10, Any p11, Any p12) { NativeInvoke::Invoke<void>(0x13BAF8E2, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12); }
	static void ATTACH_INTERACT_VOLUME_TO_PED(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9, Any p10) { NativeInvoke::Invoke<void>(0x5167446, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10); }
	static void ATTACH_LASER_TO_OBJECT(int32_t laser, Object object) { NativeInvoke::Invoke<void>(0xCF6AD373, laser, object); }
	static void ATTACH_LASER_TO_OBJECT_BONE(int32_t laser, Object object, const char* boneName) { NativeInvoke::Invoke<void>(0xE3667257, laser, object, boneName); }
	static void ATTACH_OBJECTS_TO_ROPE(Any rope, Object object1, Object object2, Vector3* offset1, Vector3* offset2, float p5, int32_t p6, int32_t p7) { NativeInvoke::Invoke<void>(0xFCE5C3CF, rope, object1, object2, offset1, offset2, p5, p6, p7); }
	static void ATTACH_OBJECT_TO_OBJECT(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8) { NativeInvoke::Invoke<void>(0x75F6A13E, p0, p1, p2, p3, p4, p5, p6, p7, p8); }
	static void ATTACH_OBJECT_TO_PED(Object object, Ped ped, int32_t boneId, float p3, float p4, float p5, float p6, float p7, float p8, bool p9) { NativeInvoke::Invoke<void>(0xDB806B1D, object, ped, boneId, p3, p4, p5, p6, p7, p8, p9); }
	static void ATTACH_OBJECT_TO_VEHICLE(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8) { NativeInvoke::Invoke<void>(0x3DC7AC96, p0, p1, p2, p3, p4, p5, p6, p7, p8); }
	static void ATTACH_OBJECT_VEHICLE_TO_ROPE(Any rope, Object object, Vehicle vehicle, Vector3* offset1, Vector3* offset2, float p5, int32_t p6, int32_t p7) { NativeInvoke::Invoke<void>(0x81F6E920, rope, object, vehicle, offset1, offset2, p5, p6, p7); }
	static void ATTACH_PED_TO_OBJECT(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9) { NativeInvoke::Invoke<void>(0x107FDC53, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9); }
	static void ATTACH_PED_TO_VEHICLE(Ped ped, Vehicle vehicle, int32_t bone, float p3, float p4, float p5, float p6, float p7, bool p8, bool p9, bool p10, bool p11) { NativeInvoke::Invoke<void>(0x7A41569, ped, vehicle, bone, p3, p4, p5, p6, p7, p8, p9, p10, p11); }
	static void ATTACH_PED_TO_VEHICLE_PHYSICALLY(Ped ped, Vehicle vehicle, int32_t bone1, int32_t bone2, float p4, float p5, float p6, float p7, bool p8, bool p9) { NativeInvoke::Invoke<void>(0x7A9DBF0D, ped, vehicle, bone1, bone2, p4, p5, p6, p7, p8, p9); }
	static void ATTACH_PED_TO_WORLD_PHYSICALLY(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9) { NativeInvoke::Invoke<void>(0xAF7B92C2, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9); }
	static void ATTACH_ROPE_TO_OBJECT(Any rope, Object object, Vector3* offset, int32_t p3) { NativeInvoke::Invoke<void>(0x611D5E90, rope, object, offset, p3); }
	static void ATTACH_VEHICLES_TO_ROPE(Any rope, Vehicle vehicle1, Vehicle vehicle2, Vector3* offset1, Vector3* offset2, float p5, int32_t p6, int32_t p7) { NativeInvoke::Invoke<void>(0xA21BCE5F, rope, vehicle1, vehicle2, offset1, offset2, p5, p6, p7); }
	static void ATTACH_VEHICLE_TO_OBJECT(Vehicle vehicle, Object object, int32_t bone, float xPos, float yPos, float zPos, float xRot, float yRot, float zRot) { NativeInvoke::Invoke<void>(0x923DE0E, vehicle, object, bone, xPos, yPos, zPos, xRot, yRot, zRot); }
	static void ATTACH_VEHICLE_TO_VEHICLE(Vehicle vehicle1, Vehicle vehicle2, int32_t bone, float xPos, float yPos, float zPos, float xRot, float yRot, float zRot) { NativeInvoke::Invoke<void>(0x16B0817, vehicle1, vehicle2, bone, xPos, yPos, zPos, xRot, yRot, zRot); }
	static void ATTACH_VEHICLE_TO_VEHICLE_PHYSICALLY(Vehicle vehicle1, Vehicle vehicle2, int32_t bone1, int32_t bone2, float xPos1, float yPos1, float zPos1, float xPos2, float yPos2, float zPos2, float xRot, float yRot, float zRot, float breakForce, bool fixedRot) { NativeInvoke::Invoke<void>(0x9C548435, vehicle1, vehicle2, bone1, bone2, xPos1, yPos1, zPos1, xPos2, yPos2, zPos2, xRot, yRot, zRot, breakForce, fixedRot); }
	static void ATTACH_WEAPON_TO_VEHICLE(uint32_t weaponHash, Vehicle vehicle, int32_t p2, float p3, float p4, float p5, float p6, float p7) { NativeInvoke::Invoke<void>(0xA4A9A08, weaponHash, vehicle, p2, p3, p4, p5, p6, p7); }
	static void AUDIO_ENABLE_FE_MUSIC(bool toggle) { NativeInvoke::Invoke<void>(0x2F7AFED9, toggle); }
	static void AUDIO_ENABLE_HEALTH_MIX(bool toggle) { NativeInvoke::Invoke<void>(0xA7D06400, toggle); }
	static void AUDIO_ENABLE_TV_MOVIE(bool toggle) { NativeInvoke::Invoke<void>(0x63979E44, toggle); }
	static void AUDIO_IGNORE_NEXT_WARP_TRANSITION_SOUND() { NativeInvoke::Invoke<void>(0xA9CC919C); }
	static void AUDIO_MUSIC_ADJUST_VOLUME(Any p0) { NativeInvoke::Invoke<void>(0xA34A3F55, p0); }
	static void AUDIO_MUSIC_FORCE_TRACK(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7) { NativeInvoke::Invoke<void>(0xA2A356A7, p0, p1, p2, p3, p4, p5, p6, p7); }
	static void AUDIO_MUSIC_PLAY_ONESHOT() { NativeInvoke::Invoke<void>(0x8229B903); }
	static void AUDIO_MUSIC_SET_MOOD(const char* p0, const char* p1, float p2, int32_t p3, int32_t p4) { NativeInvoke::Invoke<void>(0x633B8905, p0, p1, p2, p3, p4); }
	static void AUDIO_MUSIC_STOP_ONESHOT() { NativeInvoke::Invoke<void>(0xD92E534F); }
	static void AUDIO_MUSIC_SUSPEND(int32_t p0) { NativeInvoke::Invoke<void>(0x56E3D235, p0); }
	static void AUDIO_RESET_PED_DEAD_SPEECH_FLAG(Ped ped) { NativeInvoke::Invoke<void>(0x15256E0C, ped); }
	static void AUDIO_SET_PED_FOOTSTEPS_ON(Any p0) { NativeInvoke::Invoke<void>(0x17FEF7EA, p0); }
	static void AUDIO_SET_PED_FOOTSTEPS_VOLUME(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x85DA7899, p0, p1); }
	static void AUDIO_SET_PED_HAS_MP_BURST_GROUNDED(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x4FF98558, p0, p1); }
	static void AUD_ENABLE_PRE_BINK_SHUTDOWN(Any p0) { NativeInvoke::Invoke<void>(0xC3BDC70F, p0); }
	static void AUD_SET_IS_POWER_ON(bool toggle) { NativeInvoke::Invoke<void>(0xAB429BE9, toggle); }
	static void BIND_SCRIPT_DATABASE(const char* name) { NativeInvoke::Invoke<void>(0x56D42F14, name); }
	static void BLOCK_PLAYER_COVER_MOVEMENT_TRANSITIONS(bool toggle) { NativeInvoke::Invoke<void>(0x51C32D10, toggle); }
	static void BLOOD_DECAL_ON_PED_BONE(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5) { NativeInvoke::Invoke<void>(0xF2372566, p0, p1, p2, p3, p4, p5); }
	static void BOOBY_TRAP_ALL_CORPSE_VOLUMES(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x3D89B3C3, p0, p1); }
	static void BOT_SET_INPUT(const char* p0, float p1) { NativeInvoke::Invoke<void>(0x3D8F266F, p0, p1); }
	static void BOT_UPDATE_INPUT() { NativeInvoke::Invoke<void>(0x3C4F17C); }
	static void BREAKPOINT() { NativeInvoke::Invoke<void>(0xEFEAFB91); } 
	static void BREAK_ROPE(Any* rope, int32_t* p1, int32_t* p2, float p3, float p4) { NativeInvoke::Invoke<void>(0xA5691881, rope, p1, p2, p3, p4); }
	static void BULLET_CAMERA_ALLOW_TRACK_BULLET(bool toggle) { NativeInvoke::Invoke<void>(0x5754CF87, toggle); }
	static void BULLET_CAMERA_PRELOAD_TEXT_BINK(const char* p0, bool p1) { NativeInvoke::Invoke<void>(0x8CD8006E, p0, p1); }
	static void BULLET_CAMERA_TRACK_UNTIL_GROUNDED(bool toggle) { NativeInvoke::Invoke<void>(0xF32B2C96, toggle); }
	static void CAMERA_AIM_OVERRIDE(bool toggle) { NativeInvoke::Invoke<void>(0x8DA8FA57, toggle); }
	static void CAMERA_ANIMATED_RECORD_SRL() { NativeInvoke::Invoke<void>(0x816DFBD); }
	static void CAMERA_ANIMATED_STOP(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x70990C57, p0, p1); }
	static void CAMERA_CAN_TARGET_OBJECT(bool toggle, Object object) { NativeInvoke::Invoke<void>(0x484A10F1, toggle, object); }
	static void CAMERA_CAN_TARGET_PROJECTILES(bool toggle) { NativeInvoke::Invoke<void>(0xA931C3F2, toggle); }
	static void CAMERA_CAN_TARGET_TIRES(bool toggle) { NativeInvoke::Invoke<void>(0x13CBB1CD, toggle); }
	static void CAMERA_CAN_TARGET_VEHICLE(bool toggle, Vehicle vehicle) { NativeInvoke::Invoke<void>(0x49845055, toggle, vehicle); } 
	static void CAMERA_CLEAR_POINT_AT_TARGET() { NativeInvoke::Invoke<void>(0x9013E7F); }
	static void CAMERA_ENABLE_FIRST_TIME_AIM_LOCK(bool toggle) { NativeInvoke::Invoke<void>(0x8F5BB594, toggle); }
	static void CAMERA_ENABLE_SHOULDER_MODE(bool toggle) { NativeInvoke::Invoke<void>(0xD33A2B48, toggle); }
	static void CAMERA_FIRST_PERSON_TRACK_RATE(float rate) { NativeInvoke::Invoke<void>(0xD9D54F5A, rate); }
	static void CAMERA_FREEZE_FRAME(bool p0, int32_t p1, int32_t p2, float p3) { NativeInvoke::Invoke<void>(0xDDFE747D, p0, p1, p2, p3); }
	static void CAMERA_OVERRIDE_EFFECT_OBSTRUCTION(bool toggle) { NativeInvoke::Invoke<void>(0x24770C0D, toggle); } 
	static void CAMERA_PLAY_ANIMATED(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8) { NativeInvoke::Invoke<void>(0x7481CC8, p0, p1, p2, p3, p4, p5, p6, p7, p8); }
	static void CAMERA_PLAY_ANIMATED_ATTACHED_PED_RELATIVE(Any p0, Any p1, Any p2, Any p3, Any p4) { NativeInvoke::Invoke<void>(0xC6F70F9A, p0, p1, p2, p3, p4); }
	static void CAMERA_PLAY_ANIMATED_ATTACHED_VEHICLE(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8) { NativeInvoke::Invoke<void>(0x26C4B9FA, p0, p1, p2, p3, p4, p5, p6, p7, p8); }
	static void CAMERA_PLAY_ANIMATED_ATTACHED_VEHICLE_RELATIVE(Any p0, Any p1, Any p2, Any p3, Any p4) { NativeInvoke::Invoke<void>(0xAE338F48, p0, p1, p2, p3, p4); }
	static void CAMERA_PLAY_ANIMATED_WITH_SRL(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9) { NativeInvoke::Invoke<void>(0xAE16D609, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9); }
	static void CAMERA_POINT_AT_COORD(float x, float y, float z, int32_t duration) { NativeInvoke::Invoke<void>(0x5F3C6D7A, x, y, z, duration); }
	static void CAMERA_POINT_AT_GRENADE(bool toggle) { NativeInvoke::Invoke<void>(0x57EB9828, toggle); }
	static void CAMERA_POINT_AT_OBJECT(Object object, int32_t duration) { NativeInvoke::Invoke<void>(0xFF7BF49E, object, duration); } 
	static void CAMERA_POINT_AT_PED(Ped ped, int32_t duration) { NativeInvoke::Invoke<void>(0x8B002BD2, ped, duration); }
	static void CAMERA_POINT_AT_VEHICLE(Vehicle vehicle, int32_t duration) { NativeInvoke::Invoke<void>(0xC006BBFD, vehicle, duration); }
	static void CAMERA_SET_HIGH_COVER_LOCK_ON_ANGLE_LIMIT(float limit) { NativeInvoke::Invoke<void>(0x18B57920, limit); } 
	static void CAMERA_SNAP_POINT_AT_COORD(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0x8025901F, p0, p1, p2); }
	static void CAMERA_USE_HANDY_CAM(bool p0, float p1, bool p2) { NativeInvoke::Invoke<void>(0x4AF9573A, p0, p1, p2); }
	static void CHANGE_STATIC_EMITTER_SOUND(const char* emitterName, const char* soundName) { NativeInvoke::Invoke<void>(0x5788865, emitterName, soundName); } 
	static void CHECKPOINT_STORAGE_SAVE(Any* data, int32_t dataSize, int32_t checkpoint) { NativeInvoke::Invoke<void>(0x2C0A7F20, data, dataSize, checkpoint); }
	static void CLEAR_ADDITIONAL_TEXT(int32_t slot, bool p1) { NativeInvoke::Invoke<void>(0x518141E0, slot, p1); }
	static void CLEAR_ALL_PED_PROPS(Ped ped) { NativeInvoke::Invoke<void>(0x81DF8B43, ped); }
	static void CLEAR_ALL_RINGICON_WORLD() { NativeInvoke::Invoke<void>(0xA87B2666); }
	static void CLEAR_ALL_SPAWN_BLOCKING_AREAS() { NativeInvoke::Invoke<void>(0xF00D7922); }
	static void CLEAR_ANGLED_AREA_OF_VEHICLES(float x1, float y1, float z1, float x2, float y2, float z2, float p6) { NativeInvoke::Invoke<void>(0xF11A3018, x1, y1, z1, x2, y2, z2, p6); }
	static void CLEAR_AREA(float x, float y, float z, float radius, bool dontIgnoreProjectiles) { NativeInvoke::Invoke<void>(0x854E9AB8, x, y, z, radius, dontIgnoreProjectiles); }
	static void CLEAR_AREA_OF_COPS(float x, float y, float z, float radius) { NativeInvoke::Invoke<void>(0x95C53824, x, y, z, radius); }
	static void CLEAR_AREA_OF_FIRES_AND_EXPLOSIONS(float x, float y, float z, float radius) { NativeInvoke::Invoke<void>(0xAE40D6A1, x, y, z, radius); }
	static void CLEAR_AREA_OF_OBJECTS(float x, float y, float z, float radius) { NativeInvoke::Invoke<void>(0xBB720FE7, x, y, z, radius); }
	static void CLEAR_AREA_OF_PEDS(float x, float y, float z, float radius) { NativeInvoke::Invoke<void>(0x25BE7FA8, x, y, z, radius); }
	static void CLEAR_AREA_OF_VEHICLES(float x, float y, float z, float radius) { NativeInvoke::Invoke<void>(0x63320F3C, x, y, z, radius); }
	static void CLEAR_BIT(int32_t* data, int32_t bit) { NativeInvoke::Invoke<void>(0x8BC9E618, data, bit); }
	static void CLEAR_BRIEF() { NativeInvoke::Invoke<void>(0x9F75A929); }
	static void CLEAR_CENTRAL_MESSAGES() { NativeInvoke::Invoke<void>(0x2BCCCD02); }
	static void CLEAR_COLLECTABLE_STATS() { NativeInvoke::Invoke<void>(0x9535509B); }
	static void CLEAR_CURRENT_WIDGET_GROUP(Any p0) { NativeInvoke::Invoke<void>(0x345CAE26, p0); }
	static void CLEAR_DEATH_RECORDS() { NativeInvoke::Invoke<void>(0x58BB6879); }
	static void CLEAR_HELP() { NativeInvoke::Invoke<void>(0xE6D85741); }
	static void CLEAR_IK_ATTACH_TARGET(Ped ped) { NativeInvoke::Invoke<void>(0x923D602F, ped); }
	static void CLEAR_INTERIOR_COLLISION_REQUIRED(Interior interior) { NativeInvoke::Invoke<void>(0xA868D193, interior); }
	static void CLEAR_KILLXP_RULES() { NativeInvoke::Invoke<void>(0x77886D8E); }
	static void CLEAR_KILL_STREAK_RECORDS() { NativeInvoke::Invoke<void>(0xD3B3E2DB); }
	static void CLEAR_LEVEL_COMPLETION() { NativeInvoke::Invoke<void>(0xCDA1884F); }
	static void CLEAR_LOCKED_TARGET(Ped ped) { NativeInvoke::Invoke<void>(0xCEC0CF8C, ped); }
	static void CLEAR_NAMED_CUTSCENE(const char* cutsceneName) { NativeInvoke::Invoke<void>(0x268CC696, cutsceneName); }
	static void CLEAR_NETWORK_OBJECT_TERRITORY_EFFECT(Object object) { NativeInvoke::Invoke<void>(0xE095DEAC, object); }
	static void CLEAR_NETWORK_RESTART_NODE_GROUP_LIST() { NativeInvoke::Invoke<void>(0x5B4D98C0); }
	static void CLEAR_NEWS_SCROLLBAR() { NativeInvoke::Invoke<void>(0xD70532E8); }
	static void CLEAR_OBJECT_LAST_DAMAGE_ENTITY(Object object) { NativeInvoke::Invoke<void>(0xFAB3AA7, object); }
	static void CLEAR_PED_DEFAULT_AIM(Ped ped) { NativeInvoke::Invoke<void>(0xC7E6D674, ped); }
	static void CLEAR_PED_LAST_DAMAGE_BONE(Ped ped) { NativeInvoke::Invoke<void>(0x56CB715E, ped); }
	static void CLEAR_PED_LAST_DAMAGE_ENTITY(Ped ped) { NativeInvoke::Invoke<void>(0xBDB4D36B, ped); }
	static void CLEAR_PED_LAST_WEAPON_DAMAGE(Ped ped) { NativeInvoke::Invoke<void>(0x52C68832, ped); }
	static void CLEAR_PED_NON_CREATION_AREA() { NativeInvoke::Invoke<void>(0x6F7043A3); }
	static void CLEAR_PED_NON_REMOVAL_AREA() { NativeInvoke::Invoke<void>(0xB5BA896B); }
	static void CLEAR_PED_PRIMARY_LOOKAT(Ped ped) { NativeInvoke::Invoke<void>(0xFFFE3FBF, ped); }
	static void CLEAR_PED_PROP(Ped ped, int32_t propIndex) { NativeInvoke::Invoke<void>(0x2D23D743, ped, propIndex); }
	static void CLEAR_PED_RELATIONSHIP(Ped ped, int32_t relGroupId, int32_t flags) { NativeInvoke::Invoke<void>(0xD7EF3057, ped, relGroupId, flags); }
	static void CLEAR_PED_SECONDARY_LOOKAT(Ped ped) { NativeInvoke::Invoke<void>(0xD7D2CA7, ped); }
	static void CLEAR_PED_SECONDARY_TASK(Ped ped) { NativeInvoke::Invoke<void>(0xA635F451, ped); }
	static void CLEAR_PED_TASKS(Ped ped) { NativeInvoke::Invoke<void>(0xDE3316AB, ped); }
	static void CLEAR_PED_TASKS_IMMEDIATELY(Ped ped) { NativeInvoke::Invoke<void>(0xBC045625, ped); }
	static void CLEAR_PLAYER_HAS_DAMAGED_AT_LEAST_ONE_PED(Player player) { NativeInvoke::Invoke<void>(0x1D31CBBD, player); }
	static void CLEAR_PLAYER_WANTED_LEVEL(Player player) { NativeInvoke::Invoke<void>(0x54EA5BCC, player); }
	static void CLEAR_PRINTS() { NativeInvoke::Invoke<void>(0x216CB1C5); }
	static void CLEAR_PROJECTILES() { NativeInvoke::Invoke<void>(0xDE0D76C3); }
	static void CLEAR_RELATIONSHIP_BETWEEN_REL_GROUPS(int32_t relGroupId1, int32_t relGroupId2, int32_t flags) { NativeInvoke::Invoke<void>(0x1AB5F830, relGroupId1, relGroupId2, flags); }
	static void CLEAR_RINGICON_OBJECT(Object object) { NativeInvoke::Invoke<void>(0x284B05F3, object); }
	static void CLEAR_RINGICON_PLAYER(Player player) { NativeInvoke::Invoke<void>(0x913B00BA, player); }
	static void CLEAR_RINGICON_WORLD(float x, float y, float z) { NativeInvoke::Invoke<void>(0x879CB1D1, x, y, z); }
	static void CLEAR_ROOM_FOR_OBJECT(Object object) { NativeInvoke::Invoke<void>(0x4CF50AEB, object); }
	static void CLEAR_ROOM_FOR_PED(Ped ped) { NativeInvoke::Invoke<void>(0xAABFC73C, ped); }
	static void CLEAR_ROOM_FOR_VEHICLE(Vehicle vehicle) { NativeInvoke::Invoke<void>(0x7F01E3CF, vehicle); }
	static void CLEAR_SCRIPTED_CONVERSION_COORD() { NativeInvoke::Invoke<void>(0xBFA2E595); }
	static void CLEAR_SEQUENCE_TASK(Any taskSequence) { NativeInvoke::Invoke<void>(0x47ED03CE, taskSequence); }
	static void CLEAR_TEXT_LABEL(const char* textLabel) { NativeInvoke::Invoke<void>(0xA66AAE8F, textLabel); } 
	static void CLEAR_TICKER_MESSAGES() { NativeInvoke::Invoke<void>(0xFACE788D); }
	static void CLEAR_TIMECYCLE_MODIFIER() { NativeInvoke::Invoke<void>(0x8D8DF8EE); }
	static void CLEAR_TIMECYCLE_MODIFIER_OVERRIDE(int32_t p0) { NativeInvoke::Invoke<void>(0xF1AE66DC, p0); }
	static void CLEAR_TUTORIAL_COMPLETE() { NativeInvoke::Invoke<void>(0xF29F7694); }
	static void CLEAR_VEHICLE_LAST_DAMAGE_ENTITY(Vehicle vehicle) { NativeInvoke::Invoke<void>(0xC041027A, vehicle); }
	static void CLEAR_VEHICLE_LAST_WEAPON_DAMAGE(Vehicle vehicle) { NativeInvoke::Invoke<void>(0xE59FA6AF, vehicle); }
	static void CLEAR_WEATHER_TYPE_PERSIST() { NativeInvoke::Invoke<void>(0x6AB757D8); }
	static void CLOSE_PATROL_ROUTE() { NativeInvoke::Invoke<void>(0x67305E59); }
	static void CLOSE_SEQUENCE_TASK(Any taskSequence) { NativeInvoke::Invoke<void>(0x1A7CEBD0, taskSequence); }
	static void COPY_ANIMATIONS(Ped ped, Ped ped2, float p2) { NativeInvoke::Invoke<void>(0x2ED971A5, ped, ped2, p2); }
	static void CREATE_AICOMBATACTION_COVERENTER(const char* p0, const char* p1, const char* p2) { NativeInvoke::Invoke<void>(0xB1F504D9, p0, p1, p2); } 
	static void CREATE_ANIMATED_TEXT(const char* text, float x, float y) { NativeInvoke::Invoke<void>(0xDF9EC686, text, x, y); }
	static void CREATE_COORD_INTERACTION_VOLUME(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9, Any p10, Any p11, Any p12) { NativeInvoke::Invoke<void>(0xBBB2AA68, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12); }
	static void CREATE_DIRECTIONS_TO_COORD(float x, float y, float z, int32_t* p3, int32_t* p4) { NativeInvoke::Invoke<void>(0xAE0E17F, x, y, z, p3, p4); }
	static void CREATE_NM_MESSAGE(int32_t flags, int32_t messageId) { NativeInvoke::Invoke<void>(0x1CFBFD4B, flags, messageId); }
	static void CREATE_PATROL_ROUTE() { NativeInvoke::Invoke<void>(0xA6C7864); }
	static void CREATE_PED_CORPSE(Ped ped, Ped dummyPed) { NativeInvoke::Invoke<void>(0x48B657A1, ped, dummyPed); }
	static void CUTSCENE_DISABLE_CROSSHAIR() { NativeInvoke::Invoke<void>(0x78181012); }
	static void CUTSCENE_DISABLE_FADE_IN_GAME_AT_END(bool toggle) { NativeInvoke::Invoke<void>(0xBAC5D71B, toggle); }
	static void CUTSCENE_ENABLE_SKIP(bool toggle) { NativeInvoke::Invoke<void>(0xE9BB90DF, toggle); }
	static void CUTSCENE_FORCE_GAMEPLAY_HEADING_PITCH_UPDATE() { NativeInvoke::Invoke<void>(0xA46CA588); }
	static void CUTSCENE_FORCE_PLAYER_INVISIBLE() { NativeInvoke::Invoke<void>(0xBB8277DA); }
	static void CUTSCENE_MODEL_NO_LONGER_NEEDED(uint32_t modelHash) { NativeInvoke::Invoke<void>(0xB8E657C2, modelHash); }
	static void CUTSCENE_OBJECT_OVERRIDE_VISIBILITY(const char* objectName) { NativeInvoke::Invoke<void>(0xC63BD13, objectName); }
	static void CUTSCENE_REGISTER_ACTION_TREE_PLAY_NODE(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x14FC9F8B, p0, p1); }
	static void CUTSCENE_REGISTER_INTERACTIVE_SEQUENCE(const char* name) { NativeInvoke::Invoke<void>(0x32062668, name); }
	static void CUTSCENE_REGISTER_ISEQ(uint32_t hash) { NativeInvoke::Invoke<void>(0x90CE65B1, hash); }
	static void CUTSCENE_REGISTER_PED_ACTION_INTENTION(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5) { NativeInvoke::Invoke<void>(0x737F461C, p0, p1, p2, p3, p4, p5); }
	static void CUTSCENE_REGISTER_PED_ATTACH_TO_VEHICLE(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9) { NativeInvoke::Invoke<void>(0xA1C12621, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9); }
	static void CUTSCENE_REGISTER_PED_TELEPORT(Any p0, Any p1, Any p2, Any p3, Any p4) { NativeInvoke::Invoke<void>(0x7D0480F2, p0, p1, p2, p3, p4); }
	static void CUTSCENE_REGISTER_PED_WEAPON_HAND(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0xE4D4A26B, p0, p1, p2); }
	static void CUTSCENE_REGISTER_SET_PED_IN_COVER(Ped ped, const char* p1, const char* p2, Ped ped2, bool p4) { NativeInvoke::Invoke<void>(0x7DCAE70A, ped, p1, p2, ped2, p4); }
	static void CUTSCENE_REGISTER_SET_PLAYER_IN_COVER(const char* p0, const char* p1, bool p2, bool p3) { NativeInvoke::Invoke<void>(0xDE14FB1B, p0, p1, p2, p3); }
	static void CUTSCENE_REGISTER_STREAM_HELPER(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0xA8181C23, p0, p1, p2); }
	static void CUTSCENE_REGISTER_SWITCH_TO_LEVEL(int32_t levelIndex) { NativeInvoke::Invoke<void>(0x529E9877, levelIndex); }
	static void CUTSCENE_REGISTER_SWITCH_TO_LEVEL_NAME(const char* levelName) { NativeInvoke::Invoke<void>(0x459608C7, levelName); }
	static void CUTSCENE_REGISTER_VEHICLE_COPY(Vehicle vehicle, const char* name) { NativeInvoke::Invoke<void>(0xF18EBF23, vehicle, name); }
	static void CUTSCENE_SET_COVER_CAMERA_DIRECTION(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x41B496A, p0, p1); }
	static void CUTSCENE_SET_IS_UNAPPROVED() { NativeInvoke::Invoke<void>(0xF0CC36A5); }
	static void CUTSCENE_SET_OVERLAY_TYPE(int32_t type) { NativeInvoke::Invoke<void>(0xC3E5AA5C, type); }
	static void CUTSCENE_SET_WAIT_FOR_MOVIE(int32_t p0) { NativeInvoke::Invoke<void>(0x8D86C813, p0); }
	static void DAMAGE_ALL_GROUPS_ON_OBJECT(Object object) { NativeInvoke::Invoke<void>(0x607F48DE, object); }
	static void DAMAGE_DECALS_ON_PED(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x44944D79, p0, p1); }
	static void DAMAGE_DECAL_ON_PED_BONE(Any p0, Any p1, Any p2, Any p3, Any p4) { NativeInvoke::Invoke<void>(0xC7915C3D, p0, p1, p2, p3, p4); }
	static void DAMAGE_GLASS_IN_RADIUS(Any p0, Any p1, Any p2, Any p3, Any p4) { NativeInvoke::Invoke<void>(0xE8F0A90E, p0, p1, p2, p3, p4); }
	static void DBG_ACTIVATE_BULLET_CAM_TIME(float p0) { NativeInvoke::Invoke<void>(0x1A5014DC, p0); }
	static void DBG_DEACTIVATE_BULLET_CAM_TIME(bool p0) { NativeInvoke::Invoke<void>(0x820C255, p0); }
	static void DB_DELETE_FLOAT(const char* name, const char* entryName) { NativeInvoke::Invoke<void>(0xC2872F67, name, entryName); }
	static void DB_DELETE_INT(const char* name, const char* entryName) { NativeInvoke::Invoke<void>(0x4EDB2D6B, name, entryName); }
	static void DB_DELETE_bool(const char* name, const char* entryName) { NativeInvoke::Invoke<void>(0x7487EDE0, name, entryName); }
	static void DB_INSERT_FLOAT(const char* name, const char* entryName, float value) { NativeInvoke::Invoke<void>(0x93EDC0A, name, entryName, value); }
	static void DB_INSERT_INT(const char* name, const char* entryName, int32_t value) { NativeInvoke::Invoke<void>(0x948427BA, name, entryName, value); }
	static void DB_INSERT_bool(const char* name, const char* entryName, bool value) { NativeInvoke::Invoke<void>(0x21DC485C, name, entryName, value); }
	static void DB_SET_FLOAT(const char* name, const char* entryName, float value) { NativeInvoke::Invoke<void>(0x2495C847, name, entryName, value); }
	static void DB_SET_INT(const char* name, const char* entryName, int32_t value) { NativeInvoke::Invoke<void>(0x55C238F1, name, entryName, value); }
	static void DB_SET_bool(const char* name, const char* entryName, bool value) { NativeInvoke::Invoke<void>(0x5557AA76, name, entryName, value); }
	static void DEACTIVATE_BULLET_TIME(bool toggle, bool ignoreScript) { NativeInvoke::Invoke<void>(0x3C85EF7C, toggle, ignoreScript); }
	static void DEACTIVATE_SPECIAL_FX_MODIFIER(const char* name) { NativeInvoke::Invoke<void>(0x2970F3E, name); }
	static void DEATHRECORDS_CLEAR_KILLSHOTDATA() { NativeInvoke::Invoke<void>(0x1A7995E3); }
	static void DEATHRECORDS_GET_PLAYERDETAILS_NAME(int32_t bufferSize, char* buffer, int32_t index) { NativeInvoke::Invoke<void>(0x9F80529A, bufferSize, buffer, index); }
	static void DEATHRECORD_CLEAR(int32_t index) { NativeInvoke::Invoke<void>(0xFA6E6250, index); }
	static void DEATHRECORD_CLEAR_ALL() { NativeInvoke::Invoke<void>(0x758D584E); }
	static void DEATHRECORD_GET_SUB_KILLER_NAME(int32_t bufferSize, char* buffer, int32_t p2) { NativeInvoke::Invoke<void>(0xE57A1FF2, bufferSize, buffer, p2); }
	static void DEBUG_GET_BG_SCRIPT_NAME(int32_t index, int32_t bufferSize, char* buffer) { NativeInvoke::Invoke<void>(0x3882657, index, bufferSize, buffer); }
	static void DELETE_ALL_PED_CORPSES() { NativeInvoke::Invoke<void>(0x632B0876); }
	static void DELETE_ALL_TRAINS() { NativeInvoke::Invoke<void>(0x83DE7ABF); }
	static void DELETE_CHECKPOINT(Any checkpoint) { NativeInvoke::Invoke<void>(0xB66CF3CA, checkpoint); }
	static void DELETE_MISSION_TRAIN(Vehicle train) { NativeInvoke::Invoke<void>(0x86C9497D, train); }
	static void DELETE_OBJECT(Object* object) { NativeInvoke::Invoke<void>(0xD6EF9DA7, object); }
	static void DELETE_PATROL_ROUTE(const char* patrolRouteName) { NativeInvoke::Invoke<void>(0x2A4E6706, patrolRouteName); }
	static void DELETE_PED(Ped* ped) { NativeInvoke::Invoke<void>(0x13EFB9A0, ped); }
	static void DELETE_PED_CORPSE(Ped ped) { NativeInvoke::Invoke<void>(0x85F66883, ped); }
	static void DELETE_ROPE(Any* rope) { NativeInvoke::Invoke<void>(0x748D72AF, rope); }
	static void DELETE_SCRIPT_VEHICLE_GENERATOR(int32_t scriptVehicleGenerator) { NativeInvoke::Invoke<void>(0xE4328E3F, scriptVehicleGenerator); }
	static void DELETE_SIMPLE_PED(Object* ped) { NativeInvoke::Invoke<void>(0x3A945159, ped); }
	static void DELETE_VEHICLE(Vehicle* vehicle) { NativeInvoke::Invoke<void>(0x9803AF60, vehicle); }
	static void DELETE_VEHICLE_ANIMATOR(Vehicle vehicle) { NativeInvoke::Invoke<void>(0xBD510181, vehicle); }
	static void DELETE_WIDGET(Any p0) { NativeInvoke::Invoke<void>(0xB3CAB5FB, p0); }
	static void DELETE_WIDGET_GROUP(Any p0) { NativeInvoke::Invoke<void>(0xD215BACE, p0); }
	static void DELETE_XML_FILE() { NativeInvoke::Invoke<void>(0xCA3AF245); }
	static void DESTROY_ALL_CAMS() { NativeInvoke::Invoke<void>(0x10C151CE); }
	static void DESTROY_CAM(Cam cam) { NativeInvoke::Invoke<void>(0xC39302BD, cam); }
	static void DESTROY_DYNAMIC_PATH_OBSTRUCTION(int32_t id) { NativeInvoke::Invoke<void>(0xCFBE7489, id); }
	static void DESTROY_FRAGMENT_OBJECT(Object object) { NativeInvoke::Invoke<void>(0x9A5285B6, object); }
	static void DESTROY_LASER(int32_t laser) { NativeInvoke::Invoke<void>(0xA4C87B72, laser); }
	static void DETACH_CAM(Cam cam) { NativeInvoke::Invoke<void>(0xF4FBF14A, cam); }
	static void DETACH_OBJECT(Object object, bool p1) { NativeInvoke::Invoke<void>(0x6A1DF29F, object, p1); }
	static void DETACH_PED(Ped ped, bool p1) { NativeInvoke::Invoke<void>(0xB65BD564, ped, p1); }
	static void DETACH_PED_FROM_WITHIN_VEHICLE(Ped ped, bool p1) { NativeInvoke::Invoke<void>(0x7ABAB86B, ped, p1); }
	static void DETACH_ROPE_FROM_OBJECT(Any rope, Object object) { NativeInvoke::Invoke<void>(0x32C45586, rope, object); }
	static void DETACH_VEHICLE(Vehicle vehicle) { NativeInvoke::Invoke<void>(0xCDDBE650, vehicle); }
	static void DISABLE_DIRECTIONAL_LIGHT(bool toggle) { NativeInvoke::Invoke<void>(0x63FA48FD, toggle); }
	static void DISABLE_FADE_BETWEEN_SP_LEVELS() { NativeInvoke::Invoke<void>(0xD2666E85); }
	static void DISABLE_PICKUPS_FOR_PLAYER(bool toggle) { NativeInvoke::Invoke<void>(0xD06B1A42, toggle); }
	static void DISABLE_RESTART_CHECKPOINT(bool toggle) { NativeInvoke::Invoke<void>(0x558A8538, toggle); }
	static void DISALLOW_JOINERS() { NativeInvoke::Invoke<void>(0x878854A3); }
	static void DISPLAYF(const char* format, int32_t argCount, ...){}
	static void DISPLAY_ARCADE_MODE_LEVEL_END(const char* levelName) { NativeInvoke::Invoke<void>(0xD64ABCEF, levelName); }
	static void DISPLAY_AREA_NAME(bool toggle) { NativeInvoke::Invoke<void>(0x489FDD41, toggle); }
	static void DISPLAY_FRONTEND_MAP_BLIPS(bool toggle) { NativeInvoke::Invoke<void>(0x2C01BA1E, toggle); }
	static void DISPLAY_HELP_TEXT_THIS_FRAME(const char* textLabel, bool p1) { NativeInvoke::Invoke<void>(0x18E3360A, textLabel, p1); }
	static void DISPLAY_HUD(bool toggle) { NativeInvoke::Invoke<void>(0xD10E4E31, toggle); }
	static void DISPLAY_LOADING_SCREEN_NOW(bool p0) { NativeInvoke::Invoke<void>(0x85DDA5F2, p0); }
	static void DISPLAY_NON_MINIGAME_HELP_MESSAGES(bool toggle) { NativeInvoke::Invoke<void>(0xDBD36A26, toggle); }
	static void DISPLAY_PLAYER_COMPONENT(int32_t component, bool toggle) { NativeInvoke::Invoke<void>(0xA57B18ED, component, toggle); }
	static void DISPLAY_PLAYER_NAMES(bool toggle) { NativeInvoke::Invoke<void>(0x8F01C7D0, toggle); }
	static void DISPLAY_SYSTEM_SIGNIN_UI() { NativeInvoke::Invoke<void>(0x4264CED2); }
	static void DISPLAY_TEXT(float x, float y, const char* text) { NativeInvoke::Invoke<void>(0xFC4541B5, x, y, text); }
	static void DISPLAY_TEXT_WITH_FLOAT(float x, float y, const char* textLabel, float value, int32_t p4) { NativeInvoke::Invoke<void>(0x9B4D3A1C, x, y, textLabel, value, p4); }
	static void DISPLAY_TEXT_WITH_LITERAL_STRING(float x, float y, const char* textLabel, const char* string) { NativeInvoke::Invoke<void>(0x247F4D85, x, y, textLabel, string); }
	static void DOOR_FIND_CLOSEST_ACTIVATE_SPATIAL_DATA(Any p0, Any p1, Any p2, Any p3, Any p4) { NativeInvoke::Invoke<void>(0xE902B02D, p0, p1, p2, p3, p4); }
	static void DOOR_FIND_CLOSEST_SET_AUTO_CLOSE(Any p0, Any p1, Any p2, Any p3, Any p4) { NativeInvoke::Invoke<void>(0x5742CA6E, p0, p1, p2, p3, p4); }
	static void DOOR_FIND_CLOSEST_SET_CLOSE(Any p0, Any p1, Any p2, Any p3, Any p4) { NativeInvoke::Invoke<void>(0xA38DC937, p0, p1, p2, p3, p4); }
	static void DOOR_FIND_CLOSEST_SET_FORCE_CLOSE(uint32_t modelHash, float x, float y, float z, bool p4, bool p5) { NativeInvoke::Invoke<void>(0xCBB6E705, modelHash, x, y, z, p4, p5); }
	static void DOOR_FIND_CLOSEST_SET_LATCH(Any p0, Any p1, Any p2, Any p3, Any p4) { NativeInvoke::Invoke<void>(0xF72AADBB, p0, p1, p2, p3, p4); }
	static void DOOR_FIND_CLOSEST_SET_LIMIT_MAX(Any p0, Any p1, Any p2, Any p3, Any p4) { NativeInvoke::Invoke<void>(0x12063620, p0, p1, p2, p3, p4); }
	static void DOOR_FIND_CLOSEST_SET_LIMIT_MIN(Any p0, Any p1, Any p2, Any p3, Any p4) { NativeInvoke::Invoke<void>(0x16F2B72D, p0, p1, p2, p3, p4); }
	static void DOOR_SET_IS_AFFECTED_BY_BULLETS(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x90E38365, p0, p1); }
	static void DO_SCREEN_FADE_IN(int32_t duration) { NativeInvoke::Invoke<void>(0x66C1BDEE, duration); }
	static void DO_SCREEN_FADE_OUT(int32_t duration) { NativeInvoke::Invoke<void>(0x89D01805, duration); }
	static void DRAW_ANIMATED_TEXT() { NativeInvoke::Invoke<void>(0xF8C0BE3E); }
	static void DRAW_BACKGROUND(int32_t p0, int32_t p1, int32_t r, int32_t g, int32_t b, int32_t a) { NativeInvoke::Invoke<void>(0x7B6E91AF, p0, p1, r, g, b, a); }
	static void DRAW_COLOURED_CYLINDER(float x, float y, float z, float p3, int32_t r, int32_t g, int32_t b, int32_t a) { NativeInvoke::Invoke<void>(0x6ECBA9ED, x, y, z, p3, r, g, b, a); }
	static void DRAW_CURVED_WINDOW(float screenX, float screenY, float width, float height, int32_t alpha) { NativeInvoke::Invoke<void>(0x91FEC4DF, screenX, screenY, width, height, alpha); }
	static void DRAW_DEBUG_LINE(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9) { NativeInvoke::Invoke<void>(0xABF783AB, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9); }
	static void DRAW_DEBUG_POLY(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9, Any p10, Any p11, Any p12) { NativeInvoke::Invoke<void>(0x4213626F, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12); }
	static void DRAW_DEBUG_SPHERE(Vector3 coords, float radius, int32_t r, int32_t g, int32_t b, int32_t a) { NativeInvoke::Invoke<void>(0x304D0EEF, coords, radius, r, g, b, a); }
	static void DRAW_DEBUG_TEXT(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7) { NativeInvoke::Invoke<void>(0x269B006F, p0, p1, p2, p3, p4, p5, p6, p7); }
	static void DRAW_MOVIE(float x, float y, float width, float height, float p4, int32_t r, int32_t g, int32_t b, int32_t a, bool p9) { NativeInvoke::Invoke<void>(0xF563194B, x, y, width, height, p4, r, g, b, a, p9); }
	static void DRAW_POINT_LIGHT(float x, float y, float z, int32_t r, int32_t g, int32_t b, float p6, float p7) { NativeInvoke::Invoke<void>(0xC3277E86, x, y, z, r, g, b, p6, p7); }
	static void DRAW_RECT(float x, float y, float width, float height, int32_t r, int32_t g, int32_t b, int32_t a) { NativeInvoke::Invoke<void>(0xDD2BFC77, x, y, width, height, r, g, b, a); }
	static void DRAW_SPOT_LIGHT(float posX, float posY, float posZ, float dirX, float dirY, float dirZ, int32_t r, int32_t g, int32_t b, float p9, float p10, float p11, float p12, float p13, float p14, bool p15) { NativeInvoke::Invoke<void>(0xBDBC410C, posX, posY, posZ, dirX, dirY, dirZ, r, g, b, p9, p10, p11, p12, p13, p14, p15); }
	static void DRAW_SPRITE(Any texture, float screenX, float screenY, float width, float height, float heading, int32_t red, int32_t green, int32_t blue, int32_t alpha) { NativeInvoke::Invoke<void>(0x1FEC16B0, texture, screenX, screenY, width, height, heading, red, green, blue, alpha); }
	static void ENABLE_ADRENALINE(int32_t index, bool toggle) { NativeInvoke::Invoke<void>(0xC399BC03, index, toggle); }
	static void ENABLE_AIM_ASSIST(bool toggle) { NativeInvoke::Invoke<void>(0x1283F44C, toggle); }
	static void ENABLE_ALL_ADRENALINE(bool toggle) { NativeInvoke::Invoke<void>(0x13B5D49D, toggle); }
	static void ENABLE_AMBIENT_STREAM(const char* streamName, bool toggle) { NativeInvoke::Invoke<void>(0xBBE7F424, streamName, toggle); }
	static void ENABLE_AMBIENT_ZONE(const char* zoneName, bool toggle) { NativeInvoke::Invoke<void>(0xD20ABC53, zoneName, toggle); }
	static void ENABLE_AMMOPICKUP(bool toggle) { NativeInvoke::Invoke<void>(0x2077903F, toggle); }
	static void ENABLE_AUDIO_MISSION_FLAG(int32_t p0, bool toggle) { NativeInvoke::Invoke<void>(0x5B1A1397, p0, toggle); }
	static void ENABLE_AUDIO_MIX_LAYER(int32_t p0, bool p1, float p2, int32_t p3) { NativeInvoke::Invoke<void>(0xE9DB6185, p0, p1, p2, p3); }
	static void ENABLE_BULLETTIMEMETER(bool toggle) { NativeInvoke::Invoke<void>(0x5FA15459, toggle); }
	static void ENABLE_BULLET_CAMERA_WIPE(bool toggle) { NativeInvoke::Invoke<void>(0xDCCD38E5, toggle); }
	static void ENABLE_CHECKPOINT_ICON() { NativeInvoke::Invoke<void>(0xAE5FF058); }
	static void ENABLE_COVERPOINTMP3(const char* p0, const char* p1, bool p2) { NativeInvoke::Invoke<void>(0xE01B6BF0, p0, p1, p2); }
	static void ENABLE_COVERPOINTMP3_GROUP(const char* p0, const char* p1, bool p2) { NativeInvoke::Invoke<void>(0x8C161165, p0, p1, p2); }
	static void ENABLE_COVERPOINTMP3_GROUP_FROM_LINE(uint32_t p0, uint32_t p1, bool p2) { NativeInvoke::Invoke<void>(0x36ABEF8C, p0, p1, p2); }
	static void ENABLE_CROSSHAIR(bool toggle) { NativeInvoke::Invoke<void>(0x6C40B100, toggle); }
	static void ENABLE_DEATHHELPERTEXT(bool p0, bool p1, int32_t p2) { NativeInvoke::Invoke<void>(0xB7067496, p0, p1, p2); }
	static void ENABLE_DIRECTIONAL_SHADOWS(bool toggle) { NativeInvoke::Invoke<void>(0x43ACC998, toggle); }
	static void ENABLE_DUAL_WIELD_IN_INVENTORY(bool toggle) { NativeInvoke::Invoke<void>(0x8625D99F, toggle); }
	static void ENABLE_EQUIPPEDWEAPON(bool toggle) { NativeInvoke::Invoke<void>(0x398E8CF1, toggle); }
	static void ENABLE_FIRST_TIME_LOCK(bool toggle) { NativeInvoke::Invoke<void>(0x969CF927, toggle); }
	static void ENABLE_GLINT(int32_t glint, bool toggle) { NativeInvoke::Invoke<void>(0xC0F842E8, glint, toggle); }
	static void ENABLE_GRAVITY_WELL(const char* p0, const char* p1, bool p2, bool p3, bool p4, float p5) { NativeInvoke::Invoke<void>(0x684742A6, p0, p1, p2, p3, p4, p5); }
	static void ENABLE_GRENADE_WARNING(bool toggle) { NativeInvoke::Invoke<void>(0x2C61E2B5, toggle); }
	static void ENABLE_HEARTBEAT_RUMBLE(bool toggle) { NativeInvoke::Invoke<void>(0xB6FC8F5, toggle); }
	static void ENABLE_HIT_DETECTION(bool toggle) { NativeInvoke::Invoke<void>(0xE476F1D1, toggle); }
	static void ENABLE_INVENTORY(bool toggle) { NativeInvoke::Invoke<void>(0x6B3C2DAC, toggle); }
	static void ENABLE_LAST_MAN_STANDING(bool toggle) { NativeInvoke::Invoke<void>(0x9E8A0C27, toggle); }
	static void ENABLE_MPM(bool toggle) { NativeInvoke::Invoke<void>(0x1A8BD82F, toggle); }
	static void ENABLE_MP_LAST_MAN_STANDING(bool toggle) { NativeInvoke::Invoke<void>(0x3324F915, toggle); }
	static void ENABLE_NORMAL_LINE(const char* p0, const char* p1, bool p2) { NativeInvoke::Invoke<void>(0x9F3B1DC, p0, p1, p2); }
	static void ENABLE_NORMAL_LINE_BY_HASH(uint32_t p0, uint32_t p1, bool p2) { NativeInvoke::Invoke<void>(0xF9850EDB, p0, p1, p2); }
	static void ENABLE_OVERHEAT_ICON(bool toggle, const char* iconName) { NativeInvoke::Invoke<void>(0x85921A0, toggle, iconName); }
	static void ENABLE_PAUSE_MENU(bool toggle) { NativeInvoke::Invoke<void>(0x7441D0DD, toggle); }
	static void ENABLE_PED_JUMPING(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x2B499736, ped, toggle); }
	static void ENABLE_PED_PAIN(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xB2AE469E, ped, toggle); }
	static void ENABLE_PICKUP_ATTACHMENT(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0xE7836549, p0, p1, p2); }
	static void ENABLE_PLAYERHEALTH(bool toggle) { NativeInvoke::Invoke<void>(0x2ACBE7FA, toggle); }
	static void ENABLE_PLAYER_TAUNT(bool toggle) { NativeInvoke::Invoke<void>(0x1BE48B46, toggle); }
	static void ENABLE_SHOOT_DODGE_HIGH_FALL_STAIRS_DETECTION(bool toggle) { NativeInvoke::Invoke<void>(0xD579FE07, toggle); }
	static void ENABLE_SNIPER_HUD(bool toggle) { NativeInvoke::Invoke<void>(0x8C6E1D09, toggle); }
	static void ENABLE_SOFT_TARGETING(bool toggle) { NativeInvoke::Invoke<void>(0x7EEB362A, toggle); }
	static void ENABLE_STATIC_EMITTER(const char* emitterName, bool toggle) { NativeInvoke::Invoke<void>(0x3A1AB545, emitterName, toggle); }
	static void ENABLE_TINNITUS(bool toggle) { NativeInvoke::Invoke<void>(0xBB3BD914, toggle); }
	static void ENABLE_TUTORIAL_HUD(bool toggle) { NativeInvoke::Invoke<void>(0xC8B35409, toggle); }
	static void ENABLE_WALLA_ZONE(const char* zoneName, bool toggle) { NativeInvoke::Invoke<void>(0x41CBE852, zoneName, toggle); }
	static void ENABLE_WEAPONPICKUP(bool toggle) { NativeInvoke::Invoke<void>(0x1C727DAA, toggle); }
	static void ENABLE_WEAPON_ATTACHMENT(Weapon weapon, int32_t attachmentIndex, bool toggle) { NativeInvoke::Invoke<void>(0x46AF0A59, weapon, attachmentIndex, toggle); }
	static void END_CONTEXT(const char* name) { NativeInvoke::Invoke<void>(0xDFFE2760, name); }
	static void END_CONTEXT_HASH(uint32_t hash) { NativeInvoke::Invoke<void>(0x1211D06C, hash); }
	static void END_POSTFX_BLENDER(int32_t p0, bool p1) { NativeInvoke::Invoke<void>(0x2307415F, p0, p1); }
	static void EXPERIENCE_CLEAR_POINT_PER_INJURY() { NativeInvoke::Invoke<void>(0x4BD7929); }
	static void EXPERIENCE_CLEAR_XP_PER_INJURY() { NativeInvoke::Invoke<void>(0x296B9C65); }
	static void EXPERIENCE_SET_POINT_PER_INJURY(int32_t p0, int32_t index, int32_t value) { NativeInvoke::Invoke<void>(0x3FE362FC, p0, index, value); }
	static void EXPERIENCE_SET_XP_PER_INJURY(int32_t p0, int32_t index, int32_t value) { NativeInvoke::Invoke<void>(0x21C0A6F5, p0, index, value); }
	static void EXPLODE_OBJECT(Object object) { NativeInvoke::Invoke<void>(0xD20EAA32, object); }
	static void EXPLODE_PED_HEAD(Ped ped) { NativeInvoke::Invoke<void>(0x5CC1380, ped); }
	static void EXPLODE_PROJECTILES(Ped ped, uint32_t weaponHash) { NativeInvoke::Invoke<void>(0x35A0B955, ped, weaponHash); }
	static void EXPLODE_VEHICLE(Vehicle vehicle, bool p1, bool p2) { NativeInvoke::Invoke<void>(0xBEDEACEB, vehicle, p1, p2); }
	static void EXPLODE_VEHICLE_IN_CUTSCENE(Vehicle vehicle, bool p1) { NativeInvoke::Invoke<void>(0xA85207B5, vehicle, p1); }
	static void FINALE_GRENADE_EXPLODE_ON_IMPACT(bool toggle) { NativeInvoke::Invoke<void>(0x28280ABC, toggle); }
	static void FINALE_GRENADE_LAUNCHER_SETTINGS(bool enabled, uint32_t modelHash1, uint32_t modelHash2, uint32_t modelHash3) { NativeInvoke::Invoke<void>(0x85C263C8, enabled, modelHash1, modelHash2, modelHash3); }
	static void FLUSH_DISCARDABLE_MEMORY(int32_t p0) { NativeInvoke::Invoke<void>(0x8C3169D5, p0); }
	static void FLUSH_STREAM_MEMORY() { NativeInvoke::Invoke<void>(0x59085E59); }
	static void FORCE_ALL_STREAMING_HELPERS_ACTIVE(bool toggle) { NativeInvoke::Invoke<void>(0xAD8BE232, toggle); }
	static void FORCE_CLOSE_NETWORK() { NativeInvoke::Invoke<void>(0xD63AEB80); }
	static void FORCE_CUSTOM_WIPE_BULLET_CAMERA(bool toggle) { NativeInvoke::Invoke<void>(0xDC58C1A2, toggle); }
	static void FORCE_INTERACTIONTEXT_VISIBLE(bool toggle) { NativeInvoke::Invoke<void>(0xD69DFC56, toggle); }
	static void FORCE_OPEN_NETWORK() { NativeInvoke::Invoke<void>(0x9B6F9F04); }
	static void FORCE_PAUSEMENU_OPEN() { NativeInvoke::Invoke<void>(0x495FD473); }
	static void FORCE_PED_TO_USE_DEATH_SUGGESTION_WHEN_SHOT(Ped ped, bool p1, bool p2, bool p3, bool p4, bool p5) { NativeInvoke::Invoke<void>(0x290EC656, ped, p1, p2, p3, p4, p5); }
	static void FORCE_QUICK_DEATH_CAMERAS(bool toggle) { NativeInvoke::Invoke<void>(0x60BBBAAD, toggle); }
	static void FORCE_RED_RETICULE(bool toggle) { NativeInvoke::Invoke<void>(0x12F5C34E, toggle); }
	static void FORCE_REMOVE_AND_ADD_OBJECT(Object object) { NativeInvoke::Invoke<void>(0x180D3A13, object); }
	static void FORCE_SKIP_ATTRACT_SCREEN(bool toggle) { NativeInvoke::Invoke<void>(0x87D28A29, toggle); }
	static void FORCE_SUBTITLES(bool toggle) { NativeInvoke::Invoke<void>(0x904213A2, toggle); }
	static void FORCE_TRAIN_DOOR_OPEN_CLOSE(Vehicle train, int32_t p1, bool p2, bool p3, bool p4) { NativeInvoke::Invoke<void>(0xD1E9352D, train, p1, p2, p3, p4); }
	static void FORCE_UPDATE_OBJECT_PHYSICAL_STATE(Object object) { NativeInvoke::Invoke<void>(0xD2BB4445, object); }
	static void FORCE_WEAPON_LOAD() { NativeInvoke::Invoke<void>(0xD97732B9); }
	static void FORCE_WEAPON_SCOPE(bool toggle) { NativeInvoke::Invoke<void>(0x543C127F, toggle); }
	static void FOUND_EXPLORATION_ITEM(const char* name) { NativeInvoke::Invoke<void>(0x1E09BCAC, name); }
	static void FREEZE_CURRENT_PANEL() { NativeInvoke::Invoke<void>(0xABE10E99); }
	static void FREEZE_OBJECT_POSITION(Object object, bool toggle) { NativeInvoke::Invoke<void>(0xAAFBDB10, object, toggle); }
	static void FREEZE_PED_POSITION(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xA34E3DEA, ped, toggle); }
	static void FREEZE_PED_POSITION_AND_DONT_LOAD_COLLISION(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xF99B8DE7, ped, toggle); }
	static void FREEZE_POSITION_OF_CLOSEST_OBJECT_OF_TYPE(float x, float y, float z, float radius, uint32_t modelHash, bool toggle) { NativeInvoke::Invoke<void>(0xE3709D6D, x, y, z, radius, modelHash, toggle); }
	static void FREEZE_TIME_OF_DAY(int32_t hour, int32_t minute) { NativeInvoke::Invoke<void>(0x4ED46002, hour, minute); }
	static void FREEZE_VEHICLE_POSITION(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x1112EFCE, vehicle, toggle); }
	static void FREEZE_VEHICLE_POSITION_AND_DONT_LOAD_COLLISION(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0xBF3DF0C9, vehicle, toggle); }
	static void FREE_VEHICLE_INST_LIGHT_TUNE_DATA(Vehicle vehicle) { NativeInvoke::Invoke<void>(0x8DA263E8, vehicle); }
	static void GAMEPLAY_HELPER_BOX_ANGLED_CREATE(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9, Any p10, Any p11) { NativeInvoke::Invoke<void>(0x66CF72BB, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11); }
	static void GAMEPLAY_HELPER_BOX_CREATE(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7) { NativeInvoke::Invoke<void>(0xC7341B47, p0, p1, p2, p3, p4, p5, p6, p7); }
	static void GAMEPLAY_HELPER_BOX_CREATE_PED_ATTACHED(int32_t p0, const char* name, Ped ped, float p3, float p4, float p5, float p6, float p7, float p8, float p9, float p10, float p11, bool p12, bool p13) { NativeInvoke::Invoke<void>(0x33AAB546, p0, name, ped, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13); }
	static void GAMEPLAY_HELPER_BOX_CREATE_VEHICLE_ATTACHED(int32_t p0, const char* boxName, Vehicle vehicle, float p3, float p4, float p5, float p6, float p7, float p8, float p9, float p10, float p11, bool p12, bool p13) { NativeInvoke::Invoke<void>(0x1859C65D, p0, boxName, vehicle, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13); }
	static void GAMEPLAY_HELPER_BOX_DESTROY(Any p0) { NativeInvoke::Invoke<void>(0x27C9E914, p0); }
	static void GAMEPLAY_HELPER_BOX_SET_ENABLED(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x75BF06F3, p0, p1); }
	static void GAMEPLAY_HELPER_CYLINDER_CREATE(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6) { NativeInvoke::Invoke<void>(0x5E76389, p0, p1, p2, p3, p4, p5, p6); }
	static void GAMEPLAY_HELPER_CYLINDER_CREATE_PED_ATTACHED(int32_t p0, const char* name, Ped ped, float p3, float p4, float p5, float p6) { NativeInvoke::Invoke<void>(0xF60A8C33, p0, name, ped, p3, p4, p5, p6); }
	static void GAMEPLAY_HELPER_VOLUME_DESTROY(Any p0) { NativeInvoke::Invoke<void>(0xD154D5DE, p0); }
	static void GENERATE_OBJECT_CRUSH_IMMINENT_EVENT(Object object) { NativeInvoke::Invoke<void>(0x7B18DE4C, object); }
	static void GET_ACTIONTREE_INFO(const char* name, int32_t bufferSize1, char* buffer1, int32_t bufferSize2, char* buffer2) { NativeInvoke::Invoke<void>(0x302A2839, name, bufferSize1, buffer1, bufferSize2, buffer2); } 
	static void GET_BG_TEXTURE_FOR_BG_SCRIPT(Any p0, Any* p1, Any* p2) { NativeInvoke::Invoke<void>(0x943C6E08, p0, p1, p2); }
	static void GET_CONTENTS_OF_COMBO_WIDGET_SELECTION(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0x96868B18, p0, p1, p2); }
	static void GET_CONTENTS_OF_TEXT_WIDGET(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0x28BE9702, p0, p1, p2); }
	static void GET_COORDS_FOR_NETWORK_RESTART_NODE(int32_t nodeId, Vector3* coords, float* heading) { NativeInvoke::Invoke<void>(0xBBC0C52C, nodeId, coords, heading); }
	static void GET_CORRECTED_COLOUR(int32_t r, int32_t g, int32_t b, int32_t* correctedR, int32_t* correctedG, int32_t* correctedB) { NativeInvoke::Invoke<void>(0xDB5AC03E, r, g, b, correctedR, correctedG, correctedB); }
	static void GET_CURRENT_COP_MODEL(uint32_t* modelHash) { NativeInvoke::Invoke<void>(0xB26E12B4, modelHash); }
	static void GET_CURRENT_DATE(int32_t* day, int32_t* month) { NativeInvoke::Invoke<void>(0x781D7C7D, day, month); }
	static void GET_CURRENT_LEVEL_NAME(int32_t bufferSize, char* buffer) { NativeInvoke::Invoke<void>(0xD11807A3, bufferSize, buffer); }
	static void GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(int32_t bufferSize, char* buffer, uint32_t modelHash) { NativeInvoke::Invoke<void>(0xEC86DF39, bufferSize, buffer, modelHash); }
	static void GET_HUD_COLOUR(int32_t hudColorIndex, int32_t* r, int32_t* g, int32_t* b, int32_t* a) { NativeInvoke::Invoke<void>(0x63F66A0B, hudColorIndex, r, g, b, a); }
	static void GET_LAUNCH_SCRIPT(int32_t bufferSize, char* buffer) { NativeInvoke::Invoke<void>(0xADB14C47, bufferSize, buffer); }
	static void GET_LOADOUT_SLOT_NAME(int32_t bufferSize, char* buffer, int32_t slot) { NativeInvoke::Invoke<void>(0x917F5D80, bufferSize, buffer, slot); }
	static void GET_LOCALISED_STRING(int32_t bufferSize, char* buffer, const char* textLabel) { NativeInvoke::Invoke<void>(0xEDB3726D, bufferSize, buffer, textLabel); }
	static void GET_MODEL_DIMENSIONS(uint32_t modelHash, Vector3* minimum, Vector3* maximum) { NativeInvoke::Invoke<void>(0x91ABB8E0, modelHash, minimum, maximum); }
	static void GET_MODEL_NAME(int32_t bufferSize, char* buffer, uint32_t modelHash) { NativeInvoke::Invoke<void>(0xCBDB1D12, bufferSize, buffer, modelHash); }
	static void GET_NAME_OF_INFO_ZONE(int32_t bufferSize, char* buffer, float x, float y, float z) { NativeInvoke::Invoke<void>(0xA8CB8BF6, bufferSize, buffer, x, y, z); }
	static void GET_NAME_OF_SCRIPT_TO_AUTOMATICALLY_START(int32_t bufferSize, char* buffer) { NativeInvoke::Invoke<void>(0x9183C7B7, bufferSize, buffer); } 
	static void GET_NAME_OF_ZONE(int32_t bufferSize, char* buffer, float x, float y, float z) { NativeInvoke::Invoke<void>(0x7875CE91, bufferSize, buffer, x, y, z); }
	static void GET_NEAREST_COLLECTABLE_BIN_BAGS(float x, float y, float z) { NativeInvoke::Invoke<void>(0xCAEBB272, x, y, z); }
	static void GET_NEXT_XML_NODE() { NativeInvoke::Invoke<void>(0xA9FDD7A1); }
	static void GET_OBJECT_MATRIX(Object object, Vector3* rightVector, Vector3* forwardVector, Vector3* upVector, Vector3* position) { NativeInvoke::Invoke<void>(0xF301B4FF, object, rightVector, forwardVector, upVector, position); }
	static void GET_OBJECT_QUATERNION(Object object, float* x, float* y, float* z, float* w) { NativeInvoke::Invoke<void>(0x9DAE7D3B, object, x, y, z, w); }
	static void GET_PED_ANIM_GROUP(int32_t bufferSize, char* buffer, Ped ped) { NativeInvoke::Invoke<void>(0xFAF5A3C5, bufferSize, buffer, ped); }
	static void GET_PLAYER_KILLER_NAME(int32_t bufferSize, char* buffer, Player player) { NativeInvoke::Invoke<void>(0xF160FA80, bufferSize, buffer, player); }
	static void GET_PLAYER_NAME(int32_t bufferSize, char* buffer, Player player, bool withGangTag) { NativeInvoke::Invoke<void>(0x406B4B20, bufferSize, buffer, player, withGangTag); }
	static void GET_PLAYER_RGB_COLOUR(Player player, int32_t* r, int32_t* g, int32_t* b) { NativeInvoke::Invoke<void>(0x6EF43BBB, player, r, g, b); }
	static void GET_POSITION_OF_ANALOGUE_STICKS(int32_t padIndex, int32_t* p1, int32_t* p2, int32_t* p3, int32_t* p4) { NativeInvoke::Invoke<void>(0x12713A99, padIndex, p1, p2, p3, p4); }
	static void GET_PRIMARY_POPULATION_ZONE_GROUP(int32_t* p0, int32_t* p1) { NativeInvoke::Invoke<void>(0xBBD63009, p0, p1); }
	static void GET_RANDOM_VEHICLE_MODEL_IN_MEMORY(bool p0, uint32_t* modelHash, int32_t* successIndicator) { NativeInvoke::Invoke<void>(0xE2C45631, p0, modelHash, successIndicator); }
	static void GET_SCREEN_RESOLUTION(int32_t* x, int32_t* y) { NativeInvoke::Invoke<void>(0x29F3572F, x, y); }
	static void GET_SPAWN_COORDS_FOR_VEHICLE_NODE(int32_t nodeId, float x, float y, float z, Vector3* coords, float* heading) { NativeInvoke::Invoke<void>(0xC72099BA, nodeId, x, y, z, coords, heading); }
	static void GET_STATE_OF_CLOSEST_DOOR_OF_TYPE(uint32_t modelHash, float x, float y, float z, bool* locked, float* heading) { NativeInvoke::Invoke<void>(0x4B44A83D, modelHash, x, y, z, locked, heading); }
	static void GET_STATION_NAME(int32_t bufferSize, char* buffer, Vehicle train, int32_t p3) { NativeInvoke::Invoke<void>(0x62D15DE6, bufferSize, buffer, train, p3); }
	static void GET_STREET_NAME_AT_COORD(float x, float y, float z, uint32_t* streetNameHash, uint32_t* crossingRoadHash) { NativeInvoke::Invoke<void>(0xDEBEEFCF, x, y, z, streetNameHash, crossingRoadHash); }
	static void GET_STRING_FROM_XML_NODE_ATTRIBUTE(int32_t bufferSize, char* buffer, int32_t attributeIndex) { NativeInvoke::Invoke<void>(0x60BF58D2, bufferSize, buffer, attributeIndex); }
	static void GET_THIS_THREAD_FRIENDLY_NAME(int32_t bufferSize, char* buffer) { NativeInvoke::Invoke<void>(0x277B10EE, bufferSize, buffer); }
	static void GET_TIME_OF_DAY(int32_t* hour, int32_t* minute) { NativeInvoke::Invoke<void>(0x4E1DE7A5, hour, minute); }
	static void GET_VEHICLE_COLOURS(Vehicle vehicle, int32_t* primaryColor, int32_t* secondaryColor) { NativeInvoke::Invoke<void>(0x40D82D88, vehicle, primaryColor, secondaryColor); }
	static void GET_VEHICLE_EXTRA_COLOURS(Vehicle vehicle, int32_t* pearlescentColor, int32_t* wheelColor) { NativeInvoke::Invoke<void>(0x80E4659B, vehicle, pearlescentColor, wheelColor); }
	static void GET_VEHICLE_QUATERNION(Vehicle vehicle, float* x, float* y, float* z, float* w) { NativeInvoke::Invoke<void>(0xD30891FA, vehicle, x, y, z, w); }
	static void GET_WEAPON_NAME(int32_t bufferSize, char* buffer, uint32_t weaponHash) { NativeInvoke::Invoke<void>(0xBE7A3F5, bufferSize, buffer, weaponHash); }
	static void GET_XML_NODE_ATTRIBUTE_NAME(int32_t bufferSize, char* buffer, int32_t attributeIndex) { NativeInvoke::Invoke<void>(0xC93DD4B8, bufferSize, buffer, attributeIndex); }
	static void GET_XML_NODE_NAME(int32_t bufferSize, char* buffer) { NativeInvoke::Invoke<void>(0x8450DBA1, bufferSize, buffer); }
	static void GIVE_BG_SCRIPT_AWARD(int32_t awardId, bool* p1) { NativeInvoke::Invoke<void>(0xDE4ECCE9, awardId, p1); }
	static void GIVE_PED_ARMOUR_MP_REWARD(Ped ped, uint32_t hash) { NativeInvoke::Invoke<void>(0x1DE9A391, ped, hash); }
	static void GIVE_PED_HELMET(Ped ped, bool cannotRemove) { NativeInvoke::Invoke<void>(0x1862A461, ped, cannotRemove); }
	static void GIVE_PED_HELMET_WITH_OPTS(Ped ped, bool cannotRemove) { NativeInvoke::Invoke<void>(0xBEC2729, ped, cannotRemove); }
	static void GIVE_PED_NM_MESSAGE(Ped ped) { NativeInvoke::Invoke<void>(0x737C3689, ped); }
	static void GIVE_PED_PICKUP_OBJECT(Ped ped, Object object, bool p2) { NativeInvoke::Invoke<void>(0x3B653867, ped, object, p2); }
	static void GIVE_PLAYER_MP_SPECIAL_ITEM(Player player, int32_t item) { NativeInvoke::Invoke<void>(0x778E0144, player, item); }
	static void GIVE_PLAYER_RAGDOLL_CONTROL(Player player, bool toggle) { NativeInvoke::Invoke<void>(0xC7B4D7AC, player, toggle); }
	static void HANDLE_CHECKPOINT_RESTART() { NativeInvoke::Invoke<void>(0x821221B4); }
	static void HELI_SPOTLIGHT_TRACK_PED(Vehicle heli, Ped ped, bool p2) { NativeInvoke::Invoke<void>(0x5F44E3E6, heli, ped, p2); }
	static void HIDE_HELP_TEXT_THIS_FRAME() { NativeInvoke::Invoke<void>(0xF3807BED); }
	static void HIDE_LOADING_ON_FADE_THIS_FRAME() { NativeInvoke::Invoke<void>(0x35087963); }
	static void HIDE_PED_WEAPON_FOR_SCRIPTED_CUTSCENE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x0CFD6E9, ped, toggle); }
	static void HOLD_LAST_MAN_STAND_ANIMATED_RECOVERY(Any p0) { NativeInvoke::Invoke<void>(0xB90B9868, p0); }
	static void HUD_SCOREBOARD_SETGWNODE(Any p0, Any p1) { NativeInvoke::Invoke<void>(0xBBB66CB1, p0, p1); }
	static void HUD_SCOREBOARD_SETGW_TALLY_SCORES(Any p0) { NativeInvoke::Invoke<void>(0xB4D65DD8, p0); }
	static void HUD_SCOREBOARD_SETPLAYERBASEXP(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x1742CD46, p0, p1); }
	static void HUD_SCOREBOARD_SETPLAYERVALUES_ASSISTS(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x7F885408, p0, p1); }
	static void HUD_SCOREBOARD_SETPLAYERVALUES_FAKE_ALIVE(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x96A91A36, p0, p1); }
	static void HUD_SCOREBOARD_SETPLAYERVALUES_FAKE_DEAD(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x64493D6D, p0, p1); }
	static void HUD_SCOREBOARD_SETPLAYERVALUES_KILLDEATH(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0x61D1AF52, p0, p1, p2); }
	static void HUD_SCOREBOARD_SETPLAYERVALUES_LIVES(Any p0, Any p1) { NativeInvoke::Invoke<void>(0xCA96230B, p0, p1); }
	static void HUD_SCOREBOARD_SETPLAYERVALUES_POINTS(Any p0, Any p1) { NativeInvoke::Invoke<void>(0xCAE15E7C, p0, p1); }
	static void HUD_SCOREBOARD_SETPLAYERVALUES_ROLE(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0xBD05410B, p0, p1, p2); }
	static void HUD_SCOREBOARD_SETPLAYERVALUES_TEAM(Any p0, Any p1) { NativeInvoke::Invoke<void>(0xFF4217BA, p0, p1); }
	static void HUD_SCOREBOARD_SETPLAYERVALUES_VENDETTA(Any p0, Any p1) { NativeInvoke::Invoke<void>(0xBAB504D, p0, p1); }
	static void HUD_SCOREBOARD_SETTEAMNAMES(const char* teamName1, const char* teamName2) { NativeInvoke::Invoke<void>(0x921D2407, teamName1, teamName2); }
	static void HUD_SCOREBOARD_SHOW(bool toggle) { NativeInvoke::Invoke<void>(0xF068DFC8, toggle); }
	static void HUD_SCOREBOARD_SORT_BY(const char* p0) { NativeInvoke::Invoke<void>(0xB19BBC22, p0); }
	static void HUD_SET_CURRENT_STREAK(bool p0, const char* p1, int32_t p2, int32_t p3, int32_t p4) { NativeInvoke::Invoke<void>(0x296B0492, p0, p1, p2, p3, p4); }
	static void HUD_SET_PLAYER_HEALTH_TEXTURE(const char* textureName) { NativeInvoke::Invoke<void>(0x954FDCD0, textureName); }
	static void HUD_SET_SCORETIMER(const char* name, bool p1) { NativeInvoke::Invoke<void>(0xDA7B6C20, name, p1); }
	static void INCREMENT_CHECKPOINT_ATTEMPT() { NativeInvoke::Invoke<void>(0xAF1C3055); }
	static void INCREMENT_STREAK_STAT(const char* statName, int32_t p1, int32_t p2) { NativeInvoke::Invoke<void>(0x3CBC4B74, statName, p1, p2); }
	static void INIT_RINGICON_DATA(Any* ringicon) { NativeInvoke::Invoke<void>(0xE7B01199, ringicon); }
	static void INIT_TICKER_DATA(Any* data) { NativeInvoke::Invoke<void>(0xDF4E6CEB, data); }
	static void INVOKE_SPECTATOR_CAM() { NativeInvoke::Invoke<void>(0xCFD752C6); }
	static void ISEQ_GET_NAME(int32_t bufferSize, char* buffer, uint32_t hash) { NativeInvoke::Invoke<void>(0xE066B0F, bufferSize, buffer, hash); }
	static void ISEQ_INTERRUPT(uint32_t hash) { NativeInvoke::Invoke<void>(0x64CE3D43, hash); }
	static void ISEQ_REQUEST(uint32_t hash) { NativeInvoke::Invoke<void>(0xF0E61D78, hash); }
	static void ISEQ_START(uint32_t hash) { NativeInvoke::Invoke<void>(0x4160F67D, hash); }
	static void ISEQ_TERMINATE(uint32_t hash) { NativeInvoke::Invoke<void>(0x9B0A93E3, hash); }
	static void ISEQ_UNREGISTER_ENTITY(uint32_t hash, const char* entityName) { NativeInvoke::Invoke<void>(0xAE50ACF9, hash, entityName); }
	static void I_SEQUENCE_INTERRUPT(const char* name) { NativeInvoke::Invoke<void>(0xA443351D, name); }
	static void I_SEQUENCE_LOAD_DATA(const char* name) { NativeInvoke::Invoke<void>(0x5DEB82E0, name); }
	static void I_SEQUENCE_PURGE_ALL() { NativeInvoke::Invoke<void>(0x45B60B4A); }
	static void I_SEQUENCE_SETUP(const char* name, const char* p1, const char* p2, const char* p3) { NativeInvoke::Invoke<void>(0x73701072, name, p1, p2, p3); }
	static void I_SEQUENCE_START(const char* name) { NativeInvoke::Invoke<void>(0x4B7BA507, name); }
	static void I_SEQUENCE_TERMINATE(const char* name) { NativeInvoke::Invoke<void>(0xE7C99C4C, name); }
	static void I_SEQUENCE_UNREGISTER_ENTITY(const char* name, const char* entityName) { NativeInvoke::Invoke<void>(0x760F4681, name, entityName); }
	static void KNOCK_OFF_PROP_AT_ANCHOR_POINT(Ped ped, int32_t propIndex) { NativeInvoke::Invoke<void>(0xDE473335, ped, propIndex); }
	static void KNOCK_PED_OFF_BIKE(Ped ped) { NativeInvoke::Invoke<void>(0x98200D3C, ped); }
	static void LAST_MAN_STANDING_RECOVER() { NativeInvoke::Invoke<void>(0xC383F5A3); }
	static void LEADERBOARDS_READ_RELEASE_DATA(Any p0) { NativeInvoke::Invoke<void>(0x18E901C2, p0); }
	static void LOAD_ADDITIONAL_TEXT(const char* gxt, int32_t slot) { NativeInvoke::Invoke<void>(0xF133AED9, gxt, slot); }
	static void LOAD_ALL_OBJECTS_NOW() { NativeInvoke::Invoke<void>(0xC9DBDA90); }
	static void LOAD_PATH_NODES_IN_AREA(float x1, float y1, float x2, float y2) { NativeInvoke::Invoke<void>(0x8BFF98AC, x1, y1, x2, y2); }
	static void LOAD_SCENE(float x, float y, float z) { NativeInvoke::Invoke<void>(0xB72403F5, x, y, z); }
	static void LOAD_SCENE_FOR_ROOM_BY_KEY(Interior interior, uint32_t roomHash) { NativeInvoke::Invoke<void>(0x2CE2EEF9, interior, roomHash); }
	static void LOBBY_GET_GAME_MODE_NAME(int32_t bufferSize, char* buffer, int32_t gameMode) { NativeInvoke::Invoke<void>(0x3CE1674C, bufferSize, buffer, gameMode); }
	static void LOBBY_GET_OPTION_NAME(int32_t bufferSize, char* buffer, int32_t gameMode, int32_t option) { NativeInvoke::Invoke<void>(0x73F8D7A, bufferSize, buffer, gameMode, option); }
	static void LOBBY_GET_SUB_OPTION_NAME(int32_t bufferSize, char* buffer, int32_t gameMode, int32_t option) { NativeInvoke::Invoke<void>(0x8D6AB46A, bufferSize, buffer, gameMode, option); }
	static void MANOGAMETESTER_DISABLE() { NativeInvoke::Invoke<void>(0x28CB5F76); }
	static void MANOGAMETESTER_ENABLE() { NativeInvoke::Invoke<void>(0x25B894F2); }
	static void MARK_COVEREDGEMP3_FORCE_FACE_LEFT_ON_ENTRY(const char* p0, const char* p1, bool p2) { NativeInvoke::Invoke<void>(0xF22304B7, p0, p1, p2); }
	static void MARK_COVEREDGEMP3_FORCE_FACE_RIGHT_ON_ENTRY(const char* p0, const char* p1, bool p2) { NativeInvoke::Invoke<void>(0x388489A, p0, p1, p2); }
	static void MARK_COVERPOINTMP3_SEARCHABLE(const char* p0, const char* p1, bool p2) { NativeInvoke::Invoke<void>(0xBF75FE38, p0, p1, p2); }
	static void MARK_INTERIOR_COLLISION_REQUIRED(Interior interior) { NativeInvoke::Invoke<void>(0x3CC6D319, interior); }
	static void MARK_UNLOCK_AS_SEEN(const char* unlockSemantic) { NativeInvoke::Invoke<void>(0xC2C8DA09, unlockSemantic); }
	static void MUTE_EXPLOSIONS() { NativeInvoke::Invoke<void>(0x325CC231); } 
	static void NETWORK_ADD_INWORLD_TEXT(int32_t value, const char* text, int32_t type) { NativeInvoke::Invoke<void>(0x836D59C3, value, text, type); }
	static void NETWORK_ADD_INWORLD_TEXT_OBJECT(int32_t value, const char* text, int32_t type, Object object) { NativeInvoke::Invoke<void>(0x925DE2A9, value, text, type, object); }
	static void NETWORK_ADD_INWORLD_TEXT_PED(int32_t value, const char* text, int32_t type, Ped ped) { NativeInvoke::Invoke<void>(0xEB30678, value, text, type, ped); }
	static void NETWORK_ADD_INWORLD_TEXT_PLAYER(int32_t value, const char* text, int32_t type, Player player) { NativeInvoke::Invoke<void>(0x1001CFE8, value, text, type, player); }
	static void NETWORK_ADD_INWORLD_TEXT_POS(int32_t value, const char* text, int32_t type, float x, float y, float z) { NativeInvoke::Invoke<void>(0xB3775AEA, value, text, type, x, y, z); }
	static void NETWORK_ADD_PLAYER_CASH(int32_t amount, const char* type) { NativeInvoke::Invoke<void>(0x44D320A, amount, type); }
	static void NETWORK_ADD_PLAYER_CASH_PLAYER(int32_t amount, const char* type, Player player) { NativeInvoke::Invoke<void>(0xE544D336, amount, type, player); }
	static void NETWORK_ADD_PLAYER_CASH_POS(int32_t amount, const char* type, float x, float y, float z) { NativeInvoke::Invoke<void>(0x431A0984, amount, type, x, y, z); }
	static void NETWORK_ADD_PLAYER_EXPERIENCE(int32_t amount, const char* type) { NativeInvoke::Invoke<void>(0x1C3663D9, amount, type); }
	static void NETWORK_ADD_PLAYER_EXPERIENCE_PLAYER(int32_t amount, const char* type, Player player) { NativeInvoke::Invoke<void>(0xB956912A, amount, type, player); }
	static void NETWORK_ADD_PLAYER_EXPERIENCE_POS(int32_t amount, const char* type, float x, float y, float z) { NativeInvoke::Invoke<void>(0xB7EB7A99, amount, type, x, y, z); }
	static void NETWORK_CLEAR_PLAYER_STREAK(Player player, int32_t p1) { NativeInvoke::Invoke<void>(0x9F165014, player, p1); }
	static void NETWORK_CLEAR_SUMMONS() { NativeInvoke::Invoke<void>(0x95A210E9); }
	static void NETWORK_CREATE_PED_CORPSE(Ped ped, int32_t p1) { NativeInvoke::Invoke<void>(0x2DC1E880, ped, p1); }
	static void NETWORK_CREATE_PICKUP_FROM_WEAPONS(Any p0) { NativeInvoke::Invoke<void>(0x186B190, p0); }
	static void NETWORK_DUMP_LEVEL_DATA() { NativeInvoke::Invoke<void>(0x987381E7); }
	static void NETWORK_DUMP_STORED_QUERIES() { NativeInvoke::Invoke<void>(0x53B6E465); }
	static void NETWORK_ENABLE_ASSIST_XP(bool toggle) { NativeInvoke::Invoke<void>(0x69E75430, toggle); }
	static void NETWORK_GET_FRIEND_NAME(int32_t bufferSize, char* buffer, int32_t friendIndex) { NativeInvoke::Invoke<void>(0x97420B6D, bufferSize, buffer, friendIndex); }
	static void NETWORK_GET_MET_PLAYER_NAME(int32_t bufferSize, char* buffer, int32_t metPlayerIndex) { NativeInvoke::Invoke<void>(0xA70BA410, bufferSize, buffer, metPlayerIndex); }
	static void NETWORK_GET_STREAK_NAME(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0xA973F1AB, p0, p1, p2); }
	static void NETWORK_GET_TEAM_RGB_COLOUR(int32_t team, int32_t* r, int32_t* g, int32_t* b) { NativeInvoke::Invoke<void>(0x1DA4FCE0, team, r, g, b); }
	static void NETWORK_PLAYER_FORCE_COLOR(Player player, int32_t p1, bool p2) { NativeInvoke::Invoke<void>(0x501D54BA, player, p1, p2); }
	static void NETWORK_PRELOAD_AVATAR(uint32_t avatarHash) { NativeInvoke::Invoke<void>(0x38209242, avatarHash); }
	static void NETWORK_READY_FOR_JIP() { NativeInvoke::Invoke<void>(0xBF325030); }
	static void NETWORK_RELEASE_PRELOADED_AVATAR(uint32_t avatarHash) { NativeInvoke::Invoke<void>(0x6B197E0D, avatarHash); }
	static void NETWORK_REMOVE_OLD_BLIPS_FROM_CLEANUP_LIST() { NativeInvoke::Invoke<void>(0x69DD331); }
	static void NETWORK_REQUIRE_LEVEL_DATA(const char* name) { NativeInvoke::Invoke<void>(0x378BA5C8, name); }
	static void NETWORK_RESET_PLAYER_STREAKS(Player player) { NativeInvoke::Invoke<void>(0x9B60B0AB, player); }
	static void NETWORK_RESURRECT_PLAYER(Player player, float x, float y, float z, float heading) { NativeInvoke::Invoke<void>(0x3EEC5461, player, x, y, z, heading); }
	static void NETWORK_SET_ALL_LOW_PRIORITY_VEHICLE_GENERATORS_WITH_HELI_ACTIVE(bool toggle) { NativeInvoke::Invoke<void>(0x35A050E1, toggle); }
	static void NETWORK_SET_BOT_PLAYER(bool toggle) { NativeInvoke::Invoke<void>(0x2ED349DE, toggle); }
	static void NETWORK_SET_HEALTH_RETICULE_OPTION(bool toggle) { NativeInvoke::Invoke<void>(0x18319AA8, toggle); }
	static void NETWORK_SET_NETWORK_PLAYER_AS_VIP(Player player, bool toggle) { NativeInvoke::Invoke<void>(0x42FEA7F6, player, toggle); }
	static void NETWORK_SET_PLAYER_STREAK_BLOCKED(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0x3BDDEEE2, p0, p1, p2); }
	static void NETWORK_SET_PLAYER_STREAK_EFFECT(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0xCEB8449D, p0, p1, p2); }
	static void NETWORK_SET_PLAYER_STREAK_IN_SLOT(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0xC0188F3F, p0, p1, p2); }
	static void NETWORK_SET_PLAYER_TRACER_COLOUR(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x34EDFF34, p0, p1); }
	static void NETWORK_SET_SCRIPT_IS_SAFE_FOR_NETWORK_GAME() { NativeInvoke::Invoke<void>(0x878486CE); }
	static void NETWORK_SET_TALKER_FOCUS(Player player) { NativeInvoke::Invoke<void>(0xDCDAC012, player); }
	static void NETWORK_SET_TALKER_PROXIMITY(float value) { NativeInvoke::Invoke<void>(0x67555C66, value); }
	static void NETWORK_SET_TEAM_COLOUR(int32_t team, int32_t colorIndex) { NativeInvoke::Invoke<void>(0x91F51C10, team, colorIndex); }
	static void NETWORK_SET_TEAM_KILL_EXPERIENCE(int32_t value) { NativeInvoke::Invoke<void>(0x58625E40, value); }
	static void NETWORK_SET_TEAM_ONLY_CHAT(bool toggle) { NativeInvoke::Invoke<void>(0x3813019A, toggle); }
	static void NETWORK_SET_THIS_SCRIPT_IS_NETWORK_SCRIPT() { NativeInvoke::Invoke<void>(0x470810ED); }
	static void NETWORK_SET_WEATHER(int32_t weatherTypeId, int32_t p1, bool persist) { NativeInvoke::Invoke<void>(0x85CCA432, weatherTypeId, p1, persist); }
	static void NETWORK_SHOW_FRIEND_PROFILE_UI(const char* friendName) { NativeInvoke::Invoke<void>(0x58D0361F, friendName); }
	static void NETWORK_SHOW_MET_PLAYER_FEEDBACK_UI(int32_t metPlayerIndex) { NativeInvoke::Invoke<void>(0x7759A85A, metPlayerIndex); }
	static void NETWORK_SHOW_MET_PLAYER_PROFILE_UI(int32_t metPlayerIndex) { NativeInvoke::Invoke<void>(0x2AB80821, metPlayerIndex); }
	static void NETWORK_SHOW_PLAYER_PROFILE_UI(Player player) { NativeInvoke::Invoke<void>(0x4F05A4BE, player); }
	static void NETWORK_START_LOAD_SCENE(float x, float y, float z) { NativeInvoke::Invoke<void>(0x4280D528, x, y, z); }
	static void NET_DEBUG(const char* message) { NativeInvoke::Invoke<void>(0xE1B51FE, message); }
	static void NET_DEBUG_FLOAT(const char* message, float value) { NativeInvoke::Invoke<void>(0xC11C0E6E, message, value); }
	static void NET_DEBUG_INT(const char* message, int32_t value) { NativeInvoke::Invoke<void>(0xADC31C4F, message, value); }
	static void NET_DEBUG_STRING(const char* message, const char* str) { NativeInvoke::Invoke<void>(0x5D3F0923, message, str); }
	static void NET_DEBUG_VECTOR(const char* message, float x, float y, float z) { NativeInvoke::Invoke<void>(0x8D271B46, message, x, y, z); }
	static void NET_ERROR(const char* message) { NativeInvoke::Invoke<void>(0xBD5919F3, message); }
	static void NET_ERROR_FLOAT(const char* message, float value) { NativeInvoke::Invoke<void>(0xE3ED73BA, message, value); }
	static void NET_ERROR_INT(const char* message, int32_t value) { NativeInvoke::Invoke<void>(0x83ABB62E, message, value); }
	static void NET_ERROR_STRING(const char* message, const char* str) { NativeInvoke::Invoke<void>(0xB8A3378F, message, str); }
	static void NET_ERROR_VECTOR(const char* message, float x, float y, float z) { NativeInvoke::Invoke<void>(0x757A4E3C, message, x, y, z); }
	static void NET_PLAYSTATS_CLAN_FEUD(Any p0, Any p1, Any p2, Any p3) { NativeInvoke::Invoke<void>(0xF5BC8A87, p0, p1, p2, p3); }
	static void NET_PLAYSTATS_GAMETYPE_ENDED(Any p0, Any p1, Any p2, Any p3, Any p4) { NativeInvoke::Invoke<void>(0xFACD7753, p0, p1, p2, p3, p4); }
	static void NET_PLAYSTATS_GAMETYPE_OBJECTIVE(Any p0, Any p1, Any p2, Any p3) { NativeInvoke::Invoke<void>(0x36B7CED, p0, p1, p2, p3); }
	static void NET_PLAYSTATS_GAMETYPE_STARTED(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5) { NativeInvoke::Invoke<void>(0x3F507595, p0, p1, p2, p3, p4, p5); }
	static void NET_PLAYSTATS_JOIN_TEAM(Any p0) { NativeInvoke::Invoke<void>(0xBA80875, p0); }
	static void NET_PLAYSTATS_PLAYER_SELECTED(Any p0) { NativeInvoke::Invoke<void>(0x1BD6A6D9, p0); }
	static void NET_PLAYSTATS_POST_MATCH_BLOB(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6) { NativeInvoke::Invoke<void>(0x21847D03, p0, p1, p2, p3, p4, p5, p6); }
	static void NET_PLAYSTATS_UPDATE(uint32_t hash, int32_t score) { NativeInvoke::Invoke<void>(0x5EDABB7, hash, score); }
	static void NET_SHOW_GAMER_TAGS(bool toggle) { NativeInvoke::Invoke<void>(0x5C8CBCE5, toggle); }
	static void NET_WARNING(const char* message) { NativeInvoke::Invoke<void>(0x2242923E, message); }
	static void NET_WARNING_FLOAT(const char* message, float value) { NativeInvoke::Invoke<void>(0xACCEE78, message, value); }
	static void NET_WARNING_INT(const char* message, int32_t value) { NativeInvoke::Invoke<void>(0xF025F2F5, message, value); }
	static void NET_WARNING_STRING(const char* message, const char* str) { NativeInvoke::Invoke<void>(0x1F02B90E, message, str); }
	static void NET_WARNING_VECTOR(const char* message, float x, float y, float z) { NativeInvoke::Invoke<void>(0x378FD17A, message, x, y, z); }
	static void OPEN_PATROL_ROUTE(const char* patrolRouteName) { NativeInvoke::Invoke<void>(0xF33F83CA, patrolRouteName); }
	static void OPEN_SEQUENCE_TASK(Any* taskSequence) { NativeInvoke::Invoke<void>(0xABA6923E, taskSequence); }
	static void OVERRIDE_ALREADY_PRESENT_MPITEM_BLIPS_WITH_LAST_PARAMS() { NativeInvoke::Invoke<void>(0x45E585DF); }
	static void OVERRIDE_FREEZE_FLAGS(bool toggle) { NativeInvoke::Invoke<void>(0x4B3DF87E, toggle); }
	static void OVERRIDE_MOVER_PHYSICS_ON_RAGDOLL_SLEEP(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xE396361C, ped, toggle); }
	static void OVERRIDE_PED_FIRING_PATTERN(Ped ped, uint32_t firingPatternHash) { NativeInvoke::Invoke<void>(0xC7DD4AA6, ped, firingPatternHash); }
	static void OVERRIDE_PED_FIRING_PATTERN_CUSTOM(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xD622F7DE, ped, toggle); }
	static void OVERRIDE_WARP_MODIFIER(bool toggle, float modifier) { NativeInvoke::Invoke<void>(0x6637FAB8, toggle, modifier); }
	static void OVERRIDE_WATER_SETTINGS(float p0, float p1, int32_t p2) { NativeInvoke::Invoke<void>(0x6B4457D5, p0, p1, p2); }
	static void OVERRIDE_WEAPON_VELOCITY(uint32_t weaponHash, float velocity) { NativeInvoke::Invoke<void>(0x386F64C0, weaponHash, velocity); }
	static void PAUSE_MP_LAST_MAN_STANDING(bool toggle) { NativeInvoke::Invoke<void>(0xD32E394C, toggle); }
	static void PAUSE_PLAYBACK_RECORDED_PED(Ped ped) { NativeInvoke::Invoke<void>(0x44240A58, ped); }
	static void PAUSE_PLAYBACK_RECORDED_VEHICLE(Vehicle vehicle) { NativeInvoke::Invoke<void>(0xCCF54912, vehicle); }
	static void PEDGROUPTASK_ADVANCE_ASSIGNPED(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0xC923DB84, p0, p1, p2); }
	static void PEDGROUPTASK_ADVANCE_SETADVANCEDISTANCE(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0x6F24894B, p0, p1, p2); }
	static void PEDGROUPTASK_ADVANCE_SETADVANCERELATIVETO(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0x7DF6683B, p0, p1, p2); }
	static void PEDGROUPTASK_ADVANCE_SETNUMPEDSTOADVANCE(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0xAC69B43, p0, p1, p2); }
	static void PEDGROUPTASK_ADVANCE_SETPEDCANADVANCE(Any p0, Any p1, Any p2, Any p3) { NativeInvoke::Invoke<void>(0x322E3B5D, p0, p1, p2, p3); }
	static void PEDGROUPTASK_ADVANCE_SETTARGET_PED(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0xB35F39A7, p0, p1, p2); }
	static void PEDGROUPTASK_ADVANCE_SETTARGET_PED_2(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0xA861186C, p0, p1, p2); }
	static void PEDGROUPTASK_ADVANCE_SETTIMERANGEFORALLPEDSTOSTARTFIRING(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0x4352BEF3, p0, p1, p2); }
	static void PEDGROUPTASK_ADVANCE_SETTIMETOHIDE(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0x926BAF07, p0, p1, p2); }
	static void PEDGROUPTASK_ADVANCE_SETTIMETOIDLE(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0xB8B227D4, p0, p1, p2); }
	static void PEDGROUPTASK_ADVANCE_TRIGGER_MOVE(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x20F68DB8, p0, p1); }
	static void PEDGROUPTASK_DESTROY(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x47AEEC8E, p0, p1); }
	static void PEDGROUPTASK_TACTICALCORNER_ASSIGNPED(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0x72DF209B, p0, p1, p2); }
	static void PEDGROUPTASK_TACTICALCORNER_SETTARGET_PED(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0xBDCD7309, p0, p1, p2); }
	static void PED_ACTION_TREE_RESET_HELPER(Ped ped) { NativeInvoke::Invoke<void>(0xA46CEFD8, ped); }
	static void PED_FINISH_ACTION_INTENTION(Ped ped, int32_t p1) { NativeInvoke::Invoke<void>(0x11128D62, ped, p1); }
	static void PED_FORCE_TARGETABLE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x4A9A29C4, ped, toggle); }
	static void PED_RESET_IK(Ped ped) { NativeInvoke::Invoke<void>(0xA42336C0, ped); }
	static void PED_SET_ACTION_DIRECTION(Ped ped, float xDir, float yDir, float zDir) { NativeInvoke::Invoke<void>(0xC04CEC0C, ped, xDir, yDir, zDir); }
	static void PED_SET_ACTION_INTENTION(Ped ped, int32_t actionId, int32_t duration, float p3, float p4, float p5) { NativeInvoke::Invoke<void>(0x6C7E6B6A, ped, actionId, duration, p3, p4, p5); }
	static void PED_SET_STRING_INPUT_SIGNAL(Ped ped, const char* inputSignal) { NativeInvoke::Invoke<void>(0x216656A0, ped, inputSignal); }
	static void PIN_ROPE_VERTEX(Any rope, int32_t vertex, Vector3* coords) { NativeInvoke::Invoke<void>(0xAE1D101B, rope, vertex, coords); }
	static void PLACE_LOADOUT_ITEMS_TO_INVENTORY() { NativeInvoke::Invoke<void>(0x3EBE60EF); }
	static void PLACE_LOADOUT_TO_INVENTORY() { NativeInvoke::Invoke<void>(0xA1EBA6BB); }
	static void PLAYER_ENABLE_COMPONENT(int32_t component, bool toggle) { NativeInvoke::Invoke<void>(0xCF91F01D, component, toggle); }
	static void PLAYER_SET_AIM_MODE(int32_t mode) { NativeInvoke::Invoke<void>(0x8E1BD7A4, mode); }
	static void PLAYER_SET_WARP_FIRE_SCALE(float scale) { NativeInvoke::Invoke<void>(0x13F1FCBC, scale); }
	static void PLAY_AUDIO_EVENT_FROM_OBJECT(Any p0, Any p1) { NativeInvoke::Invoke<void>(0xC5DB6A5, p0, p1); }
	static void PLAY_AUDIO_EVENT_FROM_PED(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x1AB792DA, p0, p1); }
	static void PLAY_COMPANION_DEATH_GUNSHOT(Ped ped) { NativeInvoke::Invoke<void>(0x52AEE5E6, ped); } 
	static void PLAY_DLC_SOUND_FRONTEND(int32_t soundId, const char* soundName, const char* categoryName) { NativeInvoke::Invoke<void>(0xBDE849F7, soundId, soundName, categoryName); } 
	static void PLAY_END_CREDITS_MUSIC(bool play) { NativeInvoke::Invoke<void>(0x8E88B3CC, play); }
	static void PLAY_FIRE_SOUND_FROM_COORD(int32_t soundId, float x, float y, float z) { NativeInvoke::Invoke<void>(0x2EFD64B3, soundId, x, y, z); } 
	static void PLAY_IMAGEFX(const char* fxName, int32_t p1, bool p2) { NativeInvoke::Invoke<void>(0x2CCAA179, fxName, p1, p2); }
	static void PLAY_KILLSTRIP_LOCAL(Ped ped1, Ped ped2) { NativeInvoke::Invoke<void>(0x492BDFA1, ped1, ped2); } 
	static void PLAY_MOVIE(int32_t p0, bool p1) { NativeInvoke::Invoke<void>(0x4F39ED7A, p0, p1); }
	static void PLAY_MUSIC(const char* musicName, int32_t p1) { NativeInvoke::Invoke<void>(0x28C17DAF, musicName, p1); } 
	static void PLAY_PED_AMBIENT_SPEECH(Ped ped, const char* speech, bool p2, bool p3, int32_t p4, bool p5, int32_t p6) { NativeInvoke::Invoke<void>(0xB4EB114E, ped, speech, p2, p3, p4, p5, p6); }
	static void PLAY_PED_AMBIENT_SPEECH_WITH_VOICE(Ped ped, const char* speech, const char* voice, bool p3, bool p4, int32_t p5, bool p6, int32_t p7) { NativeInvoke::Invoke<void>(0xA3E3390C, ped, speech, voice, p3, p4, p5, p6, p7); } 
	static void PLAY_PED_AUDIO_EVENT_ANIM(Ped ped, const char* p1) { NativeInvoke::Invoke<void>(0x2CDC0A7A, ped, p1); } 
	static void PLAY_PRELOADED_ANNOUNCER_SPEECH() { NativeInvoke::Invoke<void>(0x2B508AA3); }
	static void PLAY_PRELOADED_SPEECH(Ped ped) { NativeInvoke::Invoke<void>(0xC7F2260A, ped); } 
	static void PLAY_RELIEF_SIGH(Ped ped) { NativeInvoke::Invoke<void>(0x622C486D, ped); } 
	static void PLAY_SCRIPT_STREAM_FROM_COORD(Any p0, Any p1, Any p2, Any p3) { NativeInvoke::Invoke<void>(0x3C976ECC, p0, p1, p2, p3); }
	static void PLAY_SCRIPT_STREAM_FROM_OBJECT(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x53558097, p0, p1); }
	static void PLAY_SCRIPT_STREAM_FROM_PED(Any p0, Any p1) { NativeInvoke::Invoke<void>(0xD774E920, p0, p1); }
	static void PLAY_SCRIPT_STREAM_FROM_VEHICLE(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x23B01838, p0, p1); }
	static void PLAY_SCRIPT_STREAM_FRONTEND(Any p0) { NativeInvoke::Invoke<void>(0xFE8558E8, p0); }
	static void PLAY_SCRIPT_STREAM_FRONTEND_INT(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x73CB1718, p0, p1); }
	static void PLAY_SOUND(int32_t soundId, const char* soundName) { NativeInvoke::Invoke<void>(0xB6E1917F, soundId, soundName); } 
	static void PLAY_SOUND_FROM_COORD(int32_t soundId, const char* soundName, float x, float y, float z) { NativeInvoke::Invoke<void>(0xCAD3E2D5, soundId, soundName, x, y, z); }
	static void PLAY_SOUND_FROM_OBJECT(int32_t soundId, const char* soundName, Object object) { NativeInvoke::Invoke<void>(0x6A515A49, soundId, soundName, object); }
	static void PLAY_SOUND_FROM_PED(int32_t soundId, const char* soundName, Ped ped) { NativeInvoke::Invoke<void>(0x1D6D6AC3, soundId, soundName, ped); }
	static void PLAY_SOUND_FROM_VEHICLE(int32_t soundId, const char* soundName, Vehicle vehicle) { NativeInvoke::Invoke<void>(0x8A5F9685, soundId, soundName, vehicle); }
	static void PLAY_SOUND_FRONTEND(int32_t soundId, const char* soundName) { NativeInvoke::Invoke<void>(0x2E458F74, soundId, soundName); }
	static void POINT_CAM_AT_COORD(Cam cam, float x, float y, float z) { NativeInvoke::Invoke<void>(0x914BC21A, cam, x, y, z); }
	static void POINT_CAM_AT_OBJECT(Cam cam, Object object, float offsetX, float offsetY, float offsetZ, bool p5) { NativeInvoke::Invoke<void>(0xC2B50105, cam, object, offsetX, offsetY, offsetZ, p5); } 
	static void POINT_CAM_AT_PED(Cam cam, Ped ped, float offsetX, float offsetY, float offsetZ, bool p5) { NativeInvoke::Invoke<void>(0x81BC4966, cam, ped, offsetX, offsetY, offsetZ, p5); }
	static void POINT_CAM_AT_VEHICLE(Cam cam, Vehicle vehicle, float offsetX, float offsetY, float offsetZ, bool p5) { NativeInvoke::Invoke<void>(0x6DE50BF, cam, vehicle, offsetX, offsetY, offsetZ, p5); }
	static void POPULATE_NOW() { NativeInvoke::Invoke<void>(0x72C20700); }
	static void PRELOAD_ANNOUNCER_SPEECH(const char* name, bool p1) { NativeInvoke::Invoke<void>(0x92DE336C, name, p1); }
	static void PRELOAD_MOVIE(int32_t p0, const char* movieName, bool p2, bool p3) { NativeInvoke::Invoke<void>(0xC3182968, p0, movieName, p2, p3); }
	static void PRELOAD_PLAYER_VARIATION(Ped ped, int32_t componentId, int32_t drawableId, int32_t textureId, int32_t paletteId) { NativeInvoke::Invoke<void>(0x292A475A, ped, componentId, drawableId, textureId, paletteId); }
	static void PRELOAD_STREAM_COMPONENT(int32_t p0, int32_t p1, int32_t p2, int32_t p3) { NativeInvoke::Invoke<void>(0x1E1DCDC, p0, p1, p2, p3); }
	static void PRE_STREAM_SEAMLESS_CUTSCENE(const char* cutsceneName) { NativeInvoke::Invoke<void>(0x7E152B6, cutsceneName); }
	static void PRE_STREAM_SEAMLESS_CUTSCENE_AT_COORD(const char* cutsceneName, float x, float y, float z, float p4) { NativeInvoke::Invoke<void>(0xEEE3863E, cutsceneName, x, y, z, p4); }
	static void PRINT(const char* textLabel, int32_t duration, int32_t p2) { NativeInvoke::Invoke<void>(0x53C5F206, textLabel, duration, p2); }
	static void PRINTFLOAT(float value) { NativeInvoke::Invoke<void>(0xD48B90B6, value); }
	static void PRINTFLOAT2(Any p0, Any p1, float value) { NativeInvoke::Invoke<void>(0x3983593A, p0, p1, value); } 
	static void PRINTINT(int32_t value) { NativeInvoke::Invoke<void>(0x63651F03, value); }
	static void PRINTINT2(int32_t value, Any p1) { NativeInvoke::Invoke<void>(0x83B2E331, value, p1); } 
	static void PRINTNL() { NativeInvoke::Invoke<void>(0x868997DA); }
	static void PRINTSTRING(const char* str) { NativeInvoke::Invoke<void>(0xECF8EB5F, str); }
	static void PRINTVECTOR(float x, float y, float z) { NativeInvoke::Invoke<void>(0x85F31FB, x, y, z); }
	static void PRINT_HELP(const char* textLabel) { NativeInvoke::Invoke<void>(0x6A762B4E, textLabel); }
	static void PRINT_HELP_WITH_STRING(const char* p0, const char* p1) { NativeInvoke::Invoke<void>(0x66735DD7, p0, p1); }
	static void PRINT_MEMORY_STATS() { NativeInvoke::Invoke<void>(0xD6F9C65D); }
	static void PRINT_NOW(const char* textLabel, int32_t duration, int32_t p2) { NativeInvoke::Invoke<void>(0x2C60BF8C, textLabel, duration, p2); }
	static void PRINT_STRING_WITH_LITERAL_STRING(const char* textLabel, const char* literalString, int32_t duration, int32_t p3) { NativeInvoke::Invoke<void>(0x5BFD20CB, textLabel, literalString, duration, p3); }
	static void PRINT_STRING_WITH_LITERAL_STRING_NOW(const char* textLabel, const char* literalString, int32_t duration, int32_t p3) { NativeInvoke::Invoke<void>(0x40D7612D, textLabel, literalString, duration, p3); }
	static void PROCESS_MISSION_DELETION_LIST() { NativeInvoke::Invoke<void>(0xA5CB6B1B); }
	static void PULSE_CROSSHAIR(bool p0) { NativeInvoke::Invoke<void>(0x5FF866E9, p0); }
	static void REACT_TO_COLLISION(Ped ped, float p1, float p2, float p3) { NativeInvoke::Invoke<void>(0x17F1AAF6, ped, p1, p2, p3); }
	static void REENABLE_PLAYER_INPUT(int32_t index) { NativeInvoke::Invoke<void>(0x69A8E8A7, index); }
	static void REGISTER_BOAT_WAKE(Vehicle boat, float p1, float p2, float p3, float p4, float p5, float p6, float p7) { NativeInvoke::Invoke<void>(0x85F3727, boat, p1, p2, p3, p4, p5, p6, p7); }
	static void REGISTER_BRAIN_WITH_MISSION_OBJECT(Object object, const char* p1) { NativeInvoke::Invoke<void>(0xF8DD6151, object, p1); }
	static void REGISTER_DETACH_PLAYER_FOR_CUTSCENE() { NativeInvoke::Invoke<void>(0x57D2D26); }
	static void REGISTER_HATED_TARGETS_AROUND_PED(Ped ped, float radius) { NativeInvoke::Invoke<void>(0x7F87559E, ped, radius); }
	static void REGISTER_HATED_TARGETS_IN_AREA(Ped ped, float x, float y, float z, float radius) { NativeInvoke::Invoke<void>(0x53CEFAA1, ped, x, y, z, radius); }
	static void REGISTER_HIDE_ENTITY_AT_POSITION(uint32_t modelHash, float x, float y, float z) { NativeInvoke::Invoke<void>(0x58A08847, modelHash, x, y, z); }
	static void REGISTER_KILL_IN_MULTIPLAYER_GAME(Player player, Player player2, Any p2) { NativeInvoke::Invoke<void>(0xFE86190E, player, player2, p2); }
	static void REGISTER_OBJECT_POST_SEAMLESS_CUTSCENE(const char* name) { NativeInvoke::Invoke<void>(0xE0367303, name); }
	static void REGISTER_OBJECT_PRE_SEAMLESS_CUTSCENE(Object object, const char* name, bool p2) { NativeInvoke::Invoke<void>(0xF83BC836, object, name, p2); }
	static void REGISTER_PED_POST_SEAMLESS_CUTSCENE(const char* name) { NativeInvoke::Invoke<void>(0x6C2A0780, name); }
	static void REGISTER_PED_PRE_SEAMLESS_CUTSCENE(Ped ped, const char* name, bool p2) { NativeInvoke::Invoke<void>(0x7DD7BAB9, ped, name, p2); }
	static void REGISTER_PED_SHOT_TUNING_SPECIAL01(Ped ped) { NativeInvoke::Invoke<void>(0xCCC01196, ped); }
	static void REGISTER_PERSISTENT_GLOBAL_VARIABLES(Any* ptr, int32_t count) { NativeInvoke::Invoke<void>(0x42830D95, ptr, count); }
	static void REGISTER_PLAYER_RESPAWN_COORDS(float x, float y, float z) { NativeInvoke::Invoke<void>(0x7AC5FEDC, x, y, z); }
	static void REGISTER_SCENE_PED_SEAMLESS_CUTSCENE(Any p0, Any p1) { NativeInvoke::Invoke<void>(0xDAAF0CC6, p0, p1); }
	static void REGISTER_TARGET(Ped ped, Ped targetPed) { NativeInvoke::Invoke<void>(0x50A95442, ped, targetPed); }
	static void REGISTER_VEHICLE_POST_SEAMLESS_CUTSCENE(const char* name) { NativeInvoke::Invoke<void>(0x4B4BB60E, name); }
	static void REGISTER_VEHICLE_PRE_SEAMLESS_CUTSCENE(Vehicle vehicle, const char* name, bool p2) { NativeInvoke::Invoke<void>(0xECBB0F14, vehicle, name, p2); }
	static void REGISTER_WEAPON_POST_SEAMLESS_CUTSCENE(const char* name) { NativeInvoke::Invoke<void>(0x83402B86, name); }
	static void REGISTER_WEAPON_PRE_SEAMLESS_CUTSCENE(Weapon weapon, const char* name, bool p2) { NativeInvoke::Invoke<void>(0xB2BFDAE4, weapon, name, p2); }
	static void REGISTER_WORLD_POINT_SCRIPT_BRAIN(const char* p0) { NativeInvoke::Invoke<void>(0x725D91F7, p0); }
	static void RELEASE_MOVIE(int32_t p0) { NativeInvoke::Invoke<void>(0x9EAF5CA0, p0); }
	static void RELEASE_NAMED_SCRIPT_AUDIO_BANK(const char* name) { NativeInvoke::Invoke<void>(0x16707ABC, name); }
	static void RELEASE_PATH_NODES() { NativeInvoke::Invoke<void>(0xAD7744E9); }
	static void RELEASE_PED_ENTITY_SYNC_POINT(Ped ped) { NativeInvoke::Invoke<void>(0x60E94D19, ped); }
	static void RELEASE_PRELOADED_STREAM_COMPONENT(int32_t p0, int32_t p1, int32_t p2, int32_t p3) { NativeInvoke::Invoke<void>(0x2501E8E5, p0, p1, p2, p3); }
	static void RELEASE_SCRIPT_AUDIO_BANK() { NativeInvoke::Invoke<void>(0x22F865E5); }
	static void RELEASE_SOUND_ID(int32_t soundId) { NativeInvoke::Invoke<void>(0x9C080899, soundId); }
	static void RELEASE_TEXTURE(Any texture) { NativeInvoke::Invoke<void>(0xDB7643AC, texture); }
	static void RELEASE_TIME_OF_DAY() { NativeInvoke::Invoke<void>(0xC84E8398); }
	static void RELOAD_PED_WEAPONS(Ped ped) { NativeInvoke::Invoke<void>(0x9E1C4C76, ped); }
	static void REMOVE_ALL_ENVIRONMENT_BLOOD() { NativeInvoke::Invoke<void>(0x5DD738A7); }
	static void REMOVE_ALL_ENVIRONMENT_BLOOD_AT_COORD(float x, float y, float z, float radius) { NativeInvoke::Invoke<void>(0x66802B77, x, y, z, radius); }
	static void REMOVE_ALL_GLINTS() { NativeInvoke::Invoke<void>(0xA7D255E3); }
	static void REMOVE_ALL_INTERACTION_VOLUMES() { NativeInvoke::Invoke<void>(0x621AB3A0); }
	static void REMOVE_ALL_LOCAL_PLAYER_WEAPONS_KEEPING_MPITEMS() { NativeInvoke::Invoke<void>(0x5307093D); }
	static void REMOVE_ALL_PED_WEAPONS(Ped ped) { NativeInvoke::Invoke<void>(0xA44CE817, ped); }
	static void REMOVE_ALL_PICKUPS() { NativeInvoke::Invoke<void>(0x4BF00F0); }
	static void REMOVE_ALL_PICKUPS_AND_PLACEMENTS_OF_TYPE(Any p0) { NativeInvoke::Invoke<void>(0xC58DF6C6, p0); }
	static void REMOVE_ALL_PLACEMENTS() { NativeInvoke::Invoke<void>(0xDD8A1EE); }
	static void REMOVE_ALL_SCRIPTED_BLIPS() { NativeInvoke::Invoke<void>(0x1C339C34); }
	static void REMOVE_ALL_SCRIPTED_WEAPON_MODIFIER(Ped ped) { NativeInvoke::Invoke<void>(0xA59AF348, ped); }
	static void REMOVE_ANIM_DICT(const char* dictName, bool p1) { NativeInvoke::Invoke<void>(0xAE050B5, dictName, p1); }
	static void REMOVE_ATTACHED_WEAPONS_FROM_VEHICLE(Vehicle vehicle) { NativeInvoke::Invoke<void>(0xECB94CFD, vehicle); }
	static void REMOVE_BLIP(Blip blip) { NativeInvoke::Invoke<void>(0xD8C3C1CD, blip); }
	static void REMOVE_DECISION_MAKER(Any decisionMaker) { NativeInvoke::Invoke<void>(0x95465154, decisionMaker); }
	static void REMOVE_FAKE_NETWORK_NAME_FROM_PED(Ped ped) { NativeInvoke::Invoke<void>(0xAB07F041, ped); }
	static void REMOVE_GLINT(int32_t glint) { NativeInvoke::Invoke<void>(0xB6DA9D34, glint); }
	static void REMOVE_GROUP(Group group) { NativeInvoke::Invoke<void>(0x48D72B88, group); }
	static void REMOVE_INTERACTION_VOLUME_IF_EXISTS(Any p0) { NativeInvoke::Invoke<void>(0x7254F372, p0); }
	static void REMOVE_IPL(const char* iplName, bool p1) { NativeInvoke::Invoke<void>(0xDF7CBD36, iplName, p1); }
	static void REMOVE_LOCAL_PLAYER_ARMOUR_AND_SPECIAL_ITEMS() { NativeInvoke::Invoke<void>(0x6919A93C); }
	static void REMOVE_LOCAL_PLAYER_MP_SPECIAL_ITEM(int32_t item) { NativeInvoke::Invoke<void>(0xF13C1F3F, item); }
	static void REMOVE_PARTICLE_FX(Any ptfxHandle) { NativeInvoke::Invoke<void>(0x6BA48C7E, ptfxHandle); }
	static void REMOVE_PARTICLE_FX_FROM_OBJECT(Object object) { NativeInvoke::Invoke<void>(0xBC603FEC, object); }
	static void REMOVE_PARTICLE_FX_FROM_PED(Ped ped) { NativeInvoke::Invoke<void>(0x2CDB19BD, ped); }
	static void REMOVE_PARTICLE_FX_FROM_VEHICLE(Vehicle vehicle) { NativeInvoke::Invoke<void>(0x3C9F1B1C, vehicle); }
	static void REMOVE_PED_AMMO(Ped ped, uint32_t weaponHash) { NativeInvoke::Invoke<void>(0xBA4956D, ped, weaponHash); }
	static void REMOVE_PED_DEFENSIVE_AREA(Ped ped) { NativeInvoke::Invoke<void>(0x34AAAFA5, ped); }
	static void REMOVE_PED_ELEGANTLY(Ped* ped) { NativeInvoke::Invoke<void>(0x4FFB8C6C, ped); }
	static void REMOVE_PED_FROM_GROUP(Ped ped) { NativeInvoke::Invoke<void>(0x82697713, ped); }
	static void REMOVE_PED_HELMET(Ped ped, bool instantly) { NativeInvoke::Invoke<void>(0x2086B1F0, ped, instantly); }
	static void REMOVE_PED_RECORDING(int32_t recordingIndex) { NativeInvoke::Invoke<void>(0x3BBFFA45, recordingIndex); }
	static void REMOVE_PED_WEAPON(Ped ped, Weapon weapon) { NativeInvoke::Invoke<void>(0x1F98B093, ped, weapon); }
	static void REMOVE_PICKUP(Pickup pickup) { NativeInvoke::Invoke<void>(0x64A7A0E0, pickup); }
	static void REMOVE_PICKUPS_OF_TYPE_IN_GAMEPLAY_HELPER_BOX(uint32_t pickupHash, const char* boxName) { NativeInvoke::Invoke<void>(0xDBA0AF51, pickupHash, boxName); }
	static void REMOVE_PLACEMENT(int32_t index) { NativeInvoke::Invoke<void>(0xBDA43DD, index); }
	static void REMOVE_PROJTEX_FROM_OBJECT(Object object) { NativeInvoke::Invoke<void>(0x119A0327, object); }
	static void REMOVE_PROJTEX_IN_RANGE(float x, float y, float z, float radius) { NativeInvoke::Invoke<void>(0xB2842710, x, y, z, radius); }
	static void REMOVE_SCENARIO_BLOCKING_AREAS() { NativeInvoke::Invoke<void>(0x4DDF845F); }
	static void REMOVE_SCRIPTED_WEAPON_MODIFIER(Ped ped, Any p1) { NativeInvoke::Invoke<void>(0x7E83BE00, ped, p1); }
	static void REMOVE_SCRIPT_FIRE(FireId scriptFire) { NativeInvoke::Invoke<void>(0x6B21FE26, scriptFire); }
	static void REMOVE_SPATIALDATA_COVER_POINT(Any p0) { NativeInvoke::Invoke<void>(0xFDFDEF0, p0); }
	static void REMOVE_TEXTURE_DICT(Any dict) { NativeInvoke::Invoke<void>(0x98F30A1, dict); }
	static void REMOVE_VEHICLES_FROM_GENERATORS_IN_AREA(float x1, float y1, float z1, float x2, float y2, float z2) { NativeInvoke::Invoke<void>(0x42CC15E0, x1, y1, z1, x2, y2, z2); }
	static void REMOVE_VEHICLE_FROM_PARKED_VEHICLES_BUDGET(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0xF8CFFB40, vehicle, toggle); }
	static void REMOVE_VEHICLE_RECORDING(int32_t recordingIndex) { NativeInvoke::Invoke<void>(0xD3C05B00, recordingIndex); }
	static void REMOVE_VEHICLE_STUCK_CHECK(Vehicle vehicle) { NativeInvoke::Invoke<void>(0x81594917, vehicle); }
	static void REMOVE_VEHICLE_UPSIDEDOWN_CHECK(Vehicle vehicle) { NativeInvoke::Invoke<void>(0xF390BA1B, vehicle); }
	static void REMOVE_VEHICLE_WINDOW(Vehicle vehicle, int32_t window) { NativeInvoke::Invoke<void>(0xBB8104A3, vehicle, window); }
	static void REMOVE_WEAPON_FROM_PED(Ped ped, uint32_t weaponHash) { NativeInvoke::Invoke<void>(0x9C37F220, ped, weaponHash); }
	static void RENDER_SCRIPT_CAMS(bool render, bool ease, int32_t easeTime, bool p3) { NativeInvoke::Invoke<void>(0x74337969, render, ease, easeTime, p3); }
	static void REPLENISH_LOADOUT_IN_INVENTORY() { NativeInvoke::Invoke<void>(0x2FA924B7); }
	static void REQUEST_ADDITIONAL_TEXT(const char* gxt, int32_t slot) { NativeInvoke::Invoke<void>(0x9FA9175B, gxt, slot); }
	static void REQUEST_COLLISION_AT_COORD(float x, float y, float z) { NativeInvoke::Invoke<void>(0xCD9805E7, x, y, z); }
	static void REQUEST_COLLISION_FOR_MODEL(uint32_t modelHash) { NativeInvoke::Invoke<void>(0x3930C042, modelHash); }
	static void REQUEST_INTERIOR_MODELS(uint32_t modelHash, const char* p1) { NativeInvoke::Invoke<void>(0x514857A, modelHash, p1); }
	static void REQUEST_IPL(const char* iplName, bool p1) { NativeInvoke::Invoke<void>(0x3B70D1DB, iplName, p1); }
	static void REQUEST_PED_RECORDING(int32_t recordingIndex) { NativeInvoke::Invoke<void>(0x3974EC21, recordingIndex); }
	static void REQUEST_ROOM_MINIMAL_COLLISION_MESH_BY_KEY(uint32_t roomHash) { NativeInvoke::Invoke<void>(0x97E21CB0, roomHash); }
	static void REQUEST_STREAMED_TEXTURE_DICT(const char* dictName, bool p1) { NativeInvoke::Invoke<void>(0x4C9B035F, dictName, p1); }
	static void REQUEST_VEHICLE_RECORDING(int32_t recordingIndex) { NativeInvoke::Invoke<void>(0x91AFEFD9, recordingIndex); }
	static void REQUEST_WEAPON(uint32_t weaponHash) { NativeInvoke::Invoke<void>(0xA9D5ADEC, weaponHash); }
	static void RESERVE_BULLETS(int32_t amount) { NativeInvoke::Invoke<void>(0xA253D302, amount); }
	static void RESET_ADRENALINE_ENABLE() { NativeInvoke::Invoke<void>(0xB0E2ED32); }
	static void RESET_ADRENALINE_OVERRIDE(int32_t index) { NativeInvoke::Invoke<void>(0xEE8F876F, index); }
	static void RESET_ADRENALINE_OVERRIDES() { NativeInvoke::Invoke<void>(0xAE97DC89); }
	static void RESET_ALL_PTFX() { NativeInvoke::Invoke<void>(0x5080E987); }
	static void RESET_BLOOD_EFFECTS() { NativeInvoke::Invoke<void>(0x6FD09D15); }
	static void RESET_CHECKPOINT_ATTEMPTS() { NativeInvoke::Invoke<void>(0xD9591EC0); }
	static void RESET_DESTROYED_COVER() { NativeInvoke::Invoke<void>(0x656B8235); }
	static void RESET_FORCED_AIM_INTENTION_DIRECTION() { NativeInvoke::Invoke<void>(0x1C66206F); }
	static void RESET_FORCED_FORWARD_DIRECTION() { NativeInvoke::Invoke<void>(0x6FEAA869); }
	static void RESET_GAMEPLAY_CAM() { NativeInvoke::Invoke<void>(0x809999E5); }
	static void RESET_GAME_IDLE_TIMER() { NativeInvoke::Invoke<void>(0xB8B2853A); }
	static void RESET_LAST_MAN_STANDING() { NativeInvoke::Invoke<void>(0x3F47FAEA); }
	static void RESET_LOADOUT_CHANGED_DURING_GAME() { NativeInvoke::Invoke<void>(0xFE9542E3); }
	static void RESET_PAYNEKILLER_HEALTH_BOOST(float unused) { NativeInvoke::Invoke<void>(0xC19A5559, unused); }
	static void RESET_PED_BLOOD_SMEAR(Ped ped) { NativeInvoke::Invoke<void>(0x6CDF4A41, ped); }
	static void RESET_PED_CLONES(Ped ped) { NativeInvoke::Invoke<void>(0x1E0C9CBE, ped); }
	static void RESET_PED_FLEEZONE(Ped ped) { NativeInvoke::Invoke<void>(0xAE3D290C, ped); }
	static void RESET_PED_GORE(Ped ped) { NativeInvoke::Invoke<void>(0xA882A64A, ped); }
	static void RESET_PED_MODEL_LOD_DISTANCES(uint32_t modelHash) { NativeInvoke::Invoke<void>(0xDB778444, modelHash); }
	static void RESET_PED_SUGGESTED_COMBAT_AREA(Ped ped) { NativeInvoke::Invoke<void>(0xBF29DB3C, ped); }
	static void RESET_PED_TETHERING(Ped ped) { NativeInvoke::Invoke<void>(0x37E095B5, ped); }
	static void RESET_PED_VISIBLE_DAMAGE(Ped ped) { NativeInvoke::Invoke<void>(0xC4BC4841, ped); }
	static void RESET_PLAYER_INPUT_GAIT(Player player) { NativeInvoke::Invoke<void>(0x4A701EE1, player); }
	static void RESET_STREAMING_POINT_OF_INTEREST() { NativeInvoke::Invoke<void>(0x9364E0D4); }
	static void RESET_VEHICLE_STUCK_TIMER(Vehicle vehicle, int32_t index) { NativeInvoke::Invoke<void>(0xEF2A6016, vehicle, index); }
	static void RESET_VEHICLE_WHEELS(Vehicle vehicle, bool p1) { NativeInvoke::Invoke<void>(0xD5FFE779, vehicle, p1); }
	static void RESET_WATER_SIMULATION() { NativeInvoke::Invoke<void>(0x33E9C756); }
	static void RESTORE_PICKUPS() { NativeInvoke::Invoke<void>(0x15E96C6B); }
	static void RESUME_BULLET_CAMERA_WIPE() { NativeInvoke::Invoke<void>(0xACF3AD1F); }
	static void RESUME_BULLET_CAMERA_WIPE_ON_FADEIN() { NativeInvoke::Invoke<void>(0xC038C512); }
	static void RETURN_TO_MP_LOBBY(const char* reasonTextLabel) { NativeInvoke::Invoke<void>(0x782A6A92, reasonTextLabel); }
	static void RETURN_TO_TITLESCREEN(const char* reasonTextLabel) { NativeInvoke::Invoke<void>(0xB52B5F2D, reasonTextLabel); }
	static void REVIVE_INJURED_PED(Ped ped) { NativeInvoke::Invoke<void>(0x14D3E6E3, ped); }
	static void ROPE_SET_COLLISION_FLAGS(Any rope, int32_t flags1, int32_t flags2) { NativeInvoke::Invoke<void>(0x5AE8C8E0, rope, flags1, flags2); }
	static void SAVE_LOADOUT_TO_PROFILE() { NativeInvoke::Invoke<void>(0xC1CD7E2); }
	static void SAVE_PICKUPS() { NativeInvoke::Invoke<void>(0x4CED5E31); }
	static void SAVE_STORY_DISC_SWAP(const char* levelName) { NativeInvoke::Invoke<void>(0x96CBF1FE, levelName); }
	static void SCREAM(Ped ped) { NativeInvoke::Invoke<void>(0xD1956683, ped); } 
	static void SCRIPT_ASSERT(const char* format, int32_t argCount, ...) {}
	static void SCRIPT_VAR_ADD_FLOAT(const char* name) { NativeInvoke::Invoke<void>(0x1F48312D, name); }
	static void SCRIPT_VAR_ADD_INT(const char* name) { NativeInvoke::Invoke<void>(0xFC611F3C, name); }
	static void SCRIPT_VAR_HASH_ADD_FLOAT(uint32_t hash) { NativeInvoke::Invoke<void>(0x785C8236, hash); }
	static void SCRIPT_VAR_HASH_ADD_INT(uint32_t hash) { NativeInvoke::Invoke<void>(0xC8B588A8, hash); }
	static void SCRIPT_VAR_HASH_SET_FLOAT(uint32_t hash, float value) { NativeInvoke::Invoke<void>(0xE17F81DB, hash, value); }
	static void SCRIPT_VAR_HASH_SET_INT(uint32_t hash, int32_t value) { NativeInvoke::Invoke<void>(0x8298D3E8, hash, value); }
	static void SCRIPT_VAR_SET_FLOAT(uint32_t hash, float value) { NativeInvoke::Invoke<void>(0x31BE53D4, hash, value); }
	static void SCRIPT_VAR_SET_INT(uint32_t hash, int32_t value) { NativeInvoke::Invoke<void>(0x61EF16A0, hash, value); }
	static void SCRIPT_VAR_WAIT(int32_t argCount, ...) { }
	static void SCRIPT_VAR_WAIT_UNTIL_EXIST(int32_t argCount, ...) {}
	static void SEARCH_CRITERIA_CONSIDER_PEDS_WITH_FLAG_TRUE(int32_t flag) { NativeInvoke::Invoke<void>(0x611870D2, flag); }
	static void SEARCH_CRITERIA_REJECT_PEDS_WITH_FLAG_TRUE(int32_t flag) { NativeInvoke::Invoke<void>(0x44EC539, flag); }
	static void SELECT_WEAPON_TO_HAND(Ped ped, Weapon weapon, int32_t handType, bool p3) { NativeInvoke::Invoke<void>(0xEF918984, ped, weapon, handType, p3); }
	static void SETTIMERA(int32_t value) { NativeInvoke::Invoke<void>(0x35785333, value); }
	static void SETTIMERB(int32_t value) { NativeInvoke::Invoke<void>(0x27C1B7C6, value); } 
	static void SETTIMERSYSTEM(int32_t value) { NativeInvoke::Invoke<void>(0x12542514, value); } 
	static void SETUP_BULLET_CAMERA_ANIM_SCENE(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0xC527E29F, p0, p1, p2); }
	static void SETUP_HUD_SCOREBOARD(Any p0) { NativeInvoke::Invoke<void>(0xEE11C349, p0); }
	static void SET_ACTIONTREE_INFO(const char* name, const char* fileName, const char* shortName) { NativeInvoke::Invoke<void>(0xED7221F0, name, fileName, shortName); }
	static void SET_ACTION_CONSUMED(int32_t action, bool toggle) { NativeInvoke::Invoke<void>(0x52FAFA2B, action, toggle); }
	static void SET_ACTIVATE_FRAG_OBJECT_PHYSICS_AS_SOON_AS_IT_IS_UNFROZEN(Object object, bool toggle) { NativeInvoke::Invoke<void>(0x2E2212DD, object, toggle); }
	static void SET_ACTIVATE_OBJECT_PHYSICS_AS_SOON_AS_IT_IS_UNFROZEN(Object object, bool toggle) { NativeInvoke::Invoke<void>(0x3E263AE1, object, toggle); }
	static void SET_ACTTEST_ENABLED(const char* name, bool toggle) { NativeInvoke::Invoke<void>(0xF652E42A, name, toggle); } 
	static void SET_ADRENALINE_AMT(float amount) { NativeInvoke::Invoke<void>(0x9D4FBDF6, amount); }
	static void SET_ADRENALINE_NOT_ALLOW(bool toggle) { NativeInvoke::Invoke<void>(0x51D0A04A, toggle); }
	static void SET_ADRENALINE_OVERRIDE(int32_t index, float value) { NativeInvoke::Invoke<void>(0x4AAB8E1B, index, value); }
	static void SET_ADRENALINE_PAUSE(bool toggle) { NativeInvoke::Invoke<void>(0xE4D33791, toggle); }
	static void SET_ADRENALINE_STREAKTIME(int32_t time) { NativeInvoke::Invoke<void>(0xE6E47779, time); }
	static void SET_AIM_CAM_ZOOM_LEVEL(int32_t zoomLevel) { NativeInvoke::Invoke<void>(0x134C2026, zoomLevel); }
	static void SET_AIR_DRAG_MULTIPLIER_FOR_PLAYERS_VEHICLE(Player player, float multiplier) { NativeInvoke::Invoke<void>(0xF20F72E5, player, multiplier); }
	static void SET_AI_PROJECTILE_THROW_ENABLED(bool toggle) { NativeInvoke::Invoke<void>(0xEB576EAB, toggle); }
	static void SET_AI_PROJECTILE_THROW_USE_ACTION_TREE(bool toggle) { NativeInvoke::Invoke<void>(0x9E17D62C, toggle); }
	static void SET_AI_SHOULD_ALWAYS_MISS_PED(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x9B7A250B, ped, toggle); }
	static void SET_ALLOWED_TO_FAIL_COVER_FOR_BLOCKING_LINE_OF_FIRE(bool toggle) { NativeInvoke::Invoke<void>(0xD35CCB6, toggle); }
	static void SET_ALLOW_DUMMY_CONVERSIONS(bool toggle) { NativeInvoke::Invoke<void>(0x7F0D7E5B, toggle); }
	static void SET_ALLOW_MOLOTOV_DAMAGE(bool toggle) { NativeInvoke::Invoke<void>(0x791C4E27, toggle); }
	static void SET_ALLOW_PLAYER_DIE_FROM_SHOOT_DODGE(bool toggle) { NativeInvoke::Invoke<void>(0x1D0AAF37, toggle); }
	static void SET_ALLOW_PLAYER_REACT_TO_EXPLOSION(Ped ped, bool toggle, float p2) { NativeInvoke::Invoke<void>(0xEE93EDE, ped, toggle, p2); }
	static void SET_ALL_BOATS_WAKES_MAX_SPEED_EVO(bool toggle) { NativeInvoke::Invoke<void>(0x2806197D, toggle); }
	static void SET_ALL_LOW_PRIORITY_VEHICLE_GENERATORS_ACTIVE(bool toggle) { NativeInvoke::Invoke<void>(0x87F767F2, toggle); }
	static void SET_ALL_RANDOM_PEDS_FLEE(Player player, bool toggle) { NativeInvoke::Invoke<void>(0x49EAE968, player, toggle); }
	static void SET_ALL_VEHICLES_CAN_BE_DAMAGED(bool value) { NativeInvoke::Invoke<void>(0x74BF2EAA, value); }
	static void SET_ALL_VEHICLES_HIGH_LOD(bool toggle) { NativeInvoke::Invoke<void>(0xA2EEE161, toggle); }
	static void SET_ALL_VEHICLE_GENERATORS_ACTIVE() { NativeInvoke::Invoke<void>(0xAB1FDD76); }
	static void SET_ALL_VEHICLE_GENERATORS_ACTIVE_IN_AREA(float x1, float y1, float z1, float x2, float y2, float z2, bool toggle) { NativeInvoke::Invoke<void>(0xB4E0E69A, x1, y1, z1, x2, y2, z2, toggle); }
	static void SET_AMBIENT_VOICE_NAME(Ped ped, const char* voiceName, float p2) { NativeInvoke::Invoke<void>(0xBD2EA1A1, ped, voiceName, p2); } 
	static void SET_AMMOBAG_AMMO_AMOUNT(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0xD70FCA05, p0, p1, p2); }
	static void SET_AMMOBAG_ENABLED(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x95B7945E, p0, p1); }
	static void SET_AMMOBAG_REGEN_RANGE(Any p0, Any p1) { NativeInvoke::Invoke<void>(0xAEDBB3B9, p0, p1); }
	static void SET_AMMOBAG_REGEN_TIME(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x6599E1E4, p0, p1); }
	static void SET_ANIMATED_TEXT_ANIMATIONS(Any p0, Any p1, float p2, float p3, Any p4, Any p5, Any p6, float p7, float p8) { NativeInvoke::Invoke<void>(0x71899FF8, p0, p1, p2, p3, p4, p5, p6, p7, p8); }
	static void SET_ANIMATED_TEXT_COLOR(int32_t r, int32_t g, int32_t b, int32_t a) { NativeInvoke::Invoke<void>(0xA0AC3FD2, r, g, b, a); }
	static void SET_ANIMATED_TEXT_JUSTIFY(int32_t justifyType) { NativeInvoke::Invoke<void>(0x767DF0BA, justifyType); }
	static void SET_ANIMATED_TEXT_SCALE(float p0, float p1) { NativeInvoke::Invoke<void>(0xEF71D31B, p0, p1); }
	static void SET_ANIMATED_TEXT_TWITCH(float p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0xA98C2A3D, p0, p1, p2); }
	static void SET_APPLY_WATER_PHYSICS_TO_RAGDOLL(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xE0394FC2, ped, toggle); }
	static void SET_ARCADEMODE_EVENT(int32_t p0, Ped ped) { NativeInvoke::Invoke<void>(0xC56F72BA, p0, ped); }
	static void SET_ARROW_ABOVE_BLIPPED_PICKUPS(bool toggle) { NativeInvoke::Invoke<void>(0xEDE49B32, toggle); }
	static void SET_ATTACHED_PED_ROTATION(Ped ped, float xRot, float yRot, float zRot) { NativeInvoke::Invoke<void>(0xFFE0FCD5, ped, xRot, yRot, zRot); }
	static void SET_AUTODESTROY_MPITEMS_WHEN_PICKED_BY_AN_ENEMY(Any p0) { NativeInvoke::Invoke<void>(0x63309241, p0); }
	static void SET_BCAM_STR_HELPER_TRACK_PLAYER(bool toggle) { NativeInvoke::Invoke<void>(0x809B977E, toggle); }
	static void SET_BIG_BOATS_PROPELLOR_PTFX_MAX_SPEED_EVO(bool toggle) { NativeInvoke::Invoke<void>(0x4664B095, toggle); }
	static void SET_BIG_BOATS_PTFX_MAX_SPEED_EVO(bool toggle) { NativeInvoke::Invoke<void>(0xB2C4489, toggle); }
	static void SET_BIT(int32_t* data, int32_t bit) { NativeInvoke::Invoke<void>(0x4EFE7E6B, data, bit); }
	static void SET_BITS_IN_RANGE(int32_t* data, int32_t rangeStart, int32_t rangeEnd, int32_t p3) { NativeInvoke::Invoke<void>(0x32094719, data, rangeStart, rangeEnd, p3); }
	static void SET_BLIP_ALPHA(Blip blip, int32_t alpha) { NativeInvoke::Invoke<void>(0xA791FCCD, blip, alpha); }
	static void SET_BLIP_AS_FRIENDLY(Blip blip, bool toggle) { NativeInvoke::Invoke<void>(0xF290CFD8, blip, toggle); }
	static void SET_BLIP_AS_SHORT_RANGE(Blip blip, bool toggle) { NativeInvoke::Invoke<void>(0x5C67725E, blip, toggle); }
	static void SET_BLIP_COLOUR(Blip blip, int32_t color) { NativeInvoke::Invoke<void>(0xBB3C5A41, blip, color); }
	static void SET_BLIP_COORDS(Blip blip, float x, float y, float z) { NativeInvoke::Invoke<void>(0x680A34D4, blip, x, y, z); }
	static void SET_BLIP_DIM(Blip blip, int32_t dim) { NativeInvoke::Invoke<void>(0x8AC07C0E, blip, dim); }
	static void SET_BLIP_DISPLAY(Blip blip, int32_t display) { NativeInvoke::Invoke<void>(0x2B521F91, blip, display); }
	static void SET_BLIP_FLASHES(Blip blip, bool toggle) { NativeInvoke::Invoke<void>(0xC0047F15, blip, toggle); }
	static void SET_BLIP_FLASHES_ALTERNATE(Blip blip, bool toggle) { NativeInvoke::Invoke<void>(0x1A81202B, blip, toggle); }
	static void SET_BLIP_MARKER_LONG_DISTANCE(Blip blip, bool toggle) { NativeInvoke::Invoke<void>(0xD0C1675, blip, toggle); }
	static void SET_BLIP_NAME_FROM_ASCII(Blip blip, const char* name) { NativeInvoke::Invoke<void>(0x40279490, blip, name); }
	static void SET_BLIP_NAME_FROM_TEXT_FILE(Blip blip, const char* gxt) { NativeInvoke::Invoke<void>(0xAC8A5461, blip, gxt); }
	static void SET_BLIP_PRIORITY(Blip blip, int32_t priority) { NativeInvoke::Invoke<void>(0xCE87DA6F, blip, priority); }
	static void SET_BLIP_ROTATION(Blip blip, float rotation) { NativeInvoke::Invoke<void>(0x6B8F44FE, blip, rotation); }
	static void SET_BLIP_SCALE(Blip blip, float scale) { NativeInvoke::Invoke<void>(0x1E6EC434, blip, scale); }
	static void SET_BLIP_SPRITE(Blip blip, int32_t sprite) { NativeInvoke::Invoke<void>(0x8DBBB0B9, blip, sprite); }
	static void SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xDFE34E4A, ped, toggle); }
	static void SET_BLOCKING_OF_PED_TARGETTING(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xFB55CFD0, ped, toggle); }
	static void SET_BOAT_ANCHOR(Vehicle boat, bool toggle) { NativeInvoke::Invoke<void>(0xA3906284, boat, toggle); }
	static void SET_BOAT_OUT_OF_CONTROL_AND_BLOW_UP_WHEN_DRIVER_DEAD(bool toggle) { NativeInvoke::Invoke<void>(0x89B5EA50, toggle); }
	static void SET_BOAT_PETROLTANK_BURN_RATE(Vehicle boat, float rate) { NativeInvoke::Invoke<void>(0x2EC18514, boat, rate); }
	static void SET_BOAT_TILT_IN_AIR(Vehicle boat, bool p1, float p2, float p3) { NativeInvoke::Invoke<void>(0x2361ABFA, boat, p1, p2, p3); }
	static void SET_BOAT_WILL_SINK(Vehicle boat, bool toggle) { NativeInvoke::Invoke<void>(0x74A6548F, boat, toggle); }
	static void SET_BOSS_PECENT_DAMAGE(float percentage) { NativeInvoke::Invoke<void>(0xC95210CF, percentage); }
	static void SET_BULLETCAM_STREAMHELPERS_ENABLED(bool toggle) { NativeInvoke::Invoke<void>(0x19529920, toggle); }
	static void SET_BULLET_CAMERA_TRACKER(Any p0) { NativeInvoke::Invoke<void>(0xB09B233, p0); }
	static void SET_BULLET_CAMERA_VEHICLE(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x9754F23E, p0, p1); }
	static void SET_BULLET_CAMERA_VICTIM(Any p0, Any p1) { NativeInvoke::Invoke<void>(0xFB6C221F, p0, p1); }
	static void SET_BULLET_CAM_ON_NEXT_PROJECTILE(Ped ped, const char* p1) { NativeInvoke::Invoke<void>(0xE9B08533, ped, p1); }
	static void SET_BULLET_CAM_PREF(Ped ped, const char* p1, const char* p2, const char* p3, const char* p4, bool p5, const char* p6, const char* p7, const char* p8, const char* p9, const char* p10, const char* p11, const char* p12) { NativeInvoke::Invoke<void>(0xC82AD002, ped, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12); }
	static void SET_BULLET_VELOCITY_MODIFIER(Ped ped, float velocity) { NativeInvoke::Invoke<void>(0x4A55C2DF, ped, velocity); }
	static void SET_CAMERA_OVERRIDE(const char* camName, const char* camName2, bool p2, bool p3, bool p4) { NativeInvoke::Invoke<void>(0xF02D8E72, camName, camName2, p2, p3, p4); }
	static void SET_CAMERA_USE_COVER_FOR_AIMING(bool toggle) { NativeInvoke::Invoke<void>(0x8B40F1EA, toggle); }
	static void SET_CAM_ACTIVE(Cam cam, bool toggle) { NativeInvoke::Invoke<void>(0x64659C2, cam, toggle); }
	static void SET_CAM_ACTIVE_WITH_INTERP(Cam camTo, Cam camFrom, int32_t duration, int32_t easeLocation, int32_t easeRotation) { NativeInvoke::Invoke<void>(0x7983E7F0, camTo, camFrom, duration, easeLocation, easeRotation); }
	static void SET_CAM_COORD(Cam cam, float x, float y, float z) { NativeInvoke::Invoke<void>(0x7A8053AF, cam, x, y, z); }
	static void SET_CAM_DOF_STRENGTH(Cam cam, float strength) { NativeInvoke::Invoke<void>(0x3CC4EB3F, cam, strength); }
	static void SET_CAM_FAR_CLIP(Cam cam, float farClip) { NativeInvoke::Invoke<void>(0xD23E381, cam, farClip); } 
	static void SET_CAM_FAR_DOF(Cam cam, float p1, float p2) { NativeInvoke::Invoke<void>(0x58515E8E, cam, p1, p2); }
	static void SET_CAM_FORCE_LEFT_SIDE(bool toggle) { NativeInvoke::Invoke<void>(0xFD6D5D1D, toggle); }
	static void SET_CAM_FOV(Cam cam, float fov) { NativeInvoke::Invoke<void>(0xD3D5D74F, cam, fov); }
	static void SET_CAM_INHERIT_ROLL_OBJECT(Cam cam, Object object) { NativeInvoke::Invoke<void>(0x32453696, cam, object); } 
	static void SET_CAM_INHERIT_ROLL_VEHICLE(Cam cam, Vehicle vehicle) { NativeInvoke::Invoke<void>(0xE4BD5342, cam, vehicle); } 
	static void SET_CAM_MOTION_BLUR_STRENGTH(Cam cam, float strength) { NativeInvoke::Invoke<void>(0xFD6E0D67, cam, strength); } 
	static void SET_CAM_NEAR_CLIP(Cam cam, float nearClip) { NativeInvoke::Invoke<void>(0x46DB13B1, cam, nearClip); } 
	static void SET_CAM_NEAR_DOF(Cam cam, float p1, float p2) { NativeInvoke::Invoke<void>(0xF28254DF, cam, p1, p2); } 
	static void SET_CAM_PARAMS(Cam cam, float posX, float posY, float posZ, float rotX, float rotY, float rotZ, float fieldOfView, int32_t p8, int32_t p9, int32_t p10) { NativeInvoke::Invoke<void>(0x2167CEBF, cam, posX, posY, posZ, rotX, rotY, rotZ, fieldOfView, p8, p9, p10); }
	static void SET_CAM_ROT(Cam cam, float rotX, float rotY, float rotZ) { NativeInvoke::Invoke<void>(0xEE38B3C1, cam, rotX, rotY, rotZ); }
	static void SET_CAM_SHAKE_AMPLITUDE(Cam cam, float amplitude) { NativeInvoke::Invoke<void>(0x60FF6382, cam, amplitude); } 
	static void SET_CAM_SIDE_LEFT(bool toggle) { NativeInvoke::Invoke<void>(0xC14844A8, toggle); }
	static void SET_CAM_VIEW_MODE(int32_t mode) { NativeInvoke::Invoke<void>(0xADC5A34E, mode); }
	static void SET_CAN_AI_KICK_THROUGH_CORPSES(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xB17BD0FF, ped, toggle); }
	static void SET_CAN_RESPRAY_VEHICLE(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x37677590, vehicle, toggle); }
	static void SET_CAN_ROLLING_PICKUP(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x34638D43, ped, toggle); }
	static void SET_CAN_ROLL_DODGE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xBD808BA0, ped, toggle); }
	static void SET_CAR_BOOT_OPEN(Vehicle car) { NativeInvoke::Invoke<void>(0x72E346DD, car); }
	static void SET_CAR_OUT_OF_CONTROL_AND_BLOW_UP_WHEN_DRIVER_DEAD(bool toggle) { NativeInvoke::Invoke<void>(0xC981C67D, toggle); }
	static void SET_CASH_CLAN_DISCOUNT(float p0) { NativeInvoke::Invoke<void>(0xC838CD2, p0); }
	static void SET_CHALLENGE_MODE_STREAK(int32_t amount) { NativeInvoke::Invoke<void>(0xFD53580A, amount); }
	static void SET_CHALLENGE_MODE_TIME_REMAINING(float time) { NativeInvoke::Invoke<void>(0x493D0DA7, time); }
	static void SET_CHEAT_ACTIVE(int32_t cheatId) { NativeInvoke::Invoke<void>(0x83D97A32, cheatId); }
	static void SET_CHIQUITAS_ALWAYS_VISIBLE(bool toggle) { NativeInvoke::Invoke<void>(0x29132B80, toggle); } 
	static void SET_CHIQUITAS_ALWAYS_VISIBLE_ON_PLAYER(int32_t p0, bool toggle) { NativeInvoke::Invoke<void>(0xCA7E5546, p0, toggle); } 
	static void SET_CINEMATIC_BUTTON_ACTIVE(bool toggle) { NativeInvoke::Invoke<void>(0x3FBC5D00, toggle); } 
	static void SET_COLLISION_BETWEEN_PEDS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x2279CFD3, ped, toggle); }
	static void SET_CONTENTS_OF_TEXT_WIDGET(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x74E6F8F5, p0, p1); }
	static void SET_CONTROL_CONFIG_OPTION_DISABLED(bool toggle) { NativeInvoke::Invoke<void>(0xF569B90D, toggle); }
	static void SET_CONVERSATION_CHECK_HASH(int32_t index, uint32_t hash) { NativeInvoke::Invoke<void>(0x937CE9E, index, hash); }
	static void SET_CONVERTIBLE_ROOF(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0xC87B6A51, vehicle, toggle); }
	static void SET_COORD_PRIMARY_LOOKAT(Ped ped, float x, float y, float z) { NativeInvoke::Invoke<void>(0xEAA16410, ped, x, y, z); }
	static void SET_CREATE_RANDOM_COPS(bool toggle) { NativeInvoke::Invoke<void>(0x23441648, toggle); }
	static void SET_CREDITS_ACTIVE(bool toggle) { NativeInvoke::Invoke<void>(0xEC2A0ECF, toggle); }
	static void SET_CROSSHAIR_BLINK() { NativeInvoke::Invoke<void>(0x59868456); }
	static void SET_CROSSHAIR_PULSE() { NativeInvoke::Invoke<void>(0xB5B648B0); }
	static void SET_CUFF_HANDS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xF5B13A88, ped, toggle); }
	static void SET_CURRENT_LOADOUT_SLOT(int32_t slot) { NativeInvoke::Invoke<void>(0xAD2DF9C0, slot); }
	static void SET_CURRENT_PED_MOVE_STATE(Ped ped, int32_t moveState) { NativeInvoke::Invoke<void>(0x5D6384AC, ped, moveState); }
	static void SET_CURRENT_PED_WEAPON(Ped ped, uint32_t weaponHash, bool equipNow) { NativeInvoke::Invoke<void>(0xB8278882, ped, weaponHash, equipNow); }
	static void SET_CURRENT_WIDGET_GROUP(Any p0) { NativeInvoke::Invoke<void>(0xF1392227, p0); }
	static void SET_DAMAGE_BY_PROJECTILE(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x97468654, vehicle, toggle); }
	static void SET_DAMAGE_FROM_PLAYER_MULTIPLIER(float damage) { NativeInvoke::Invoke<void>(0xD88BF32D, damage); }
	static void SET_DAMAGE_TO_PLAYER_MULTIPLIER(float damage) { NativeInvoke::Invoke<void>(0xB871820B, damage); }
	static void SET_DEAD_FORCE_WATER_DEPTH(float depth) { NativeInvoke::Invoke<void>(0x4FBA6300, depth); }
	static void SET_DEAD_FORCE_WATER_DEPTH_TO_DEFAULT() { NativeInvoke::Invoke<void>(0x1333A7F3); }
	static void SET_DEAD_PED_COORDS(Ped ped, float x, float y, float z) { NativeInvoke::Invoke<void>(0xBE678A36, ped, x, y, z); }
	static void SET_DEATH_EFFECT_ENABLED(bool toggle) { NativeInvoke::Invoke<void>(0x4441BB4D, toggle); }
	static void SET_DEATH_STATE_ACTIVE(bool toggle) { NativeInvoke::Invoke<void>(0xD4CE933A, toggle); } 
	static void SET_DEBUG_ACTIVE(bool toggle) { NativeInvoke::Invoke<void>(0x7852439, toggle); }
	static void SET_DEBUG_LINES_AND_SPHERES_DRAWING_ACTIVE(bool active) { NativeInvoke::Invoke<void>(0x1418CA37, active); }
	static void SET_DEFAULT_GLOBAL_INSTANCE_PRIORITY() { NativeInvoke::Invoke<void>(0x47280F2D); }
	static void SET_DISABLE_CUTSCENE_CROSSHAIRS(bool toggle) { NativeInvoke::Invoke<void>(0xEFB0A45E, toggle); }
	static void SET_DISABLE_FADE(bool toggle) { NativeInvoke::Invoke<void>(0x83A90082, toggle); }
	static void SET_DISPLAY_FLAGS(int32_t flags, bool set) { NativeInvoke::Invoke<void>(0xE55CCC60, flags, set); }
	static void SET_DITCH_POLICE_MODELS(bool toggle) { NativeInvoke::Invoke<void>(0x3EA7FCE4, toggle); }
	static void SET_ENABLE_BULLET_IMPACT_WATER(bool toggle) { NativeInvoke::Invoke<void>(0x300D6EF7, toggle); }
	static void SET_ENABLE_PED_PROCESS_INTELLIGENCE(bool toggle) { NativeInvoke::Invoke<void>(0x6700C96C, toggle); } 
	static void SET_END_CREDITS_FADE_ACTIVE(bool toggle) { NativeInvoke::Invoke<void>(0xB8408EB9, toggle); } 
	static void SET_END_OF_PART_ONE() { NativeInvoke::Invoke<void>(0x46890BC0); }
	static void SET_EVERYONE_IGNORE_PLAYER(Player player, bool toggle) { NativeInvoke::Invoke<void>(0xC915285E, player, toggle); }
	static void SET_EXITFLAG_FOR_SCRIPT(int32_t threadId) { NativeInvoke::Invoke<void>(0x8A79C0E0, threadId); }
	static void SET_EXITFLAG_RESPONSE() { NativeInvoke::Invoke<void>(0x551125B9); }
	static void SET_EXPERIENCE_MULTIPLIER(int32_t multiplier) { NativeInvoke::Invoke<void>(0xC4E91E1D, multiplier); }
	static void SET_FADE_MUTE_OVERRIDE(Any p0) { NativeInvoke::Invoke<void>(0xA31CE81, p0); }
	static void SET_FAIL_PROMPT_BUTTON_AND_TEXT(Ped ped, int32_t button, const char* textLabel) { NativeInvoke::Invoke<void>(0x18EE1B87, ped, button, textLabel); }
	static void SET_FAKE_DEATHARREST() { NativeInvoke::Invoke<void>(0x4A21BA25); }
	static void SET_FAKE_WANTED_LEVEL(int32_t wantedLevel) { NativeInvoke::Invoke<void>(0x85B1C9FA, wantedLevel); }
	static void SET_FOLLOW_PED_CAM_ZOOM_LEVEL(int32_t zoomLevel) { NativeInvoke::Invoke<void>(0x9E686DC1, zoomLevel); } 
	static void SET_FOLLOW_VEHICLE_CAM_ZOOM_LEVEL(int32_t zoomLevel) { NativeInvoke::Invoke<void>(0x8F55EBBE, zoomLevel); } 
	static void SET_FOOT_STEP_AUDIO_MOVEMENT(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x1911F7DF, ped, toggle); }
	static void SET_FORCED_AIM_INTENTION_DIRECTION(float dirX, float dirY, float dirZ) { NativeInvoke::Invoke<void>(0xEE232DCC, dirX, dirY, dirZ); }
	static void SET_FORCED_FORWARD_DIRECTION(float dirX, float dirY, float dirZ) { NativeInvoke::Invoke<void>(0xCE0B5E35, dirX, dirY, dirZ); }
	static void SET_FORCE_PLAYER_GORE(bool toggle) { NativeInvoke::Invoke<void>(0x631DD85B, toggle); }
	static void SET_FREEBIES_IN_VEHICLE(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x84C8F466, vehicle, toggle); }
	static void SET_FREEZE_HEADING_BLEND(int32_t p0) { NativeInvoke::Invoke<void>(0xE2E61E48, p0); }
	static void SET_FREEZE_PED_AIM(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x4EA8E77C, ped, toggle); }
	static void SET_FRONTEND_ACTIVE(bool toggle) { NativeInvoke::Invoke<void>(0x81E1AD32, toggle); }
	static void SET_GAMEPLAY_CAM_RELATIVE_HEADING(float p0, float p1, bool p2) { NativeInvoke::Invoke<void>(0x20C6217C, p0, p1, p2); }
	static void SET_GAMEPLAY_CAM_RELATIVE_PITCH(float p0, float p1, bool p2) { NativeInvoke::Invoke<void>(0x6381B963, p0, p1, p2); }
	static void SET_GAMEPLAY_CAM_SHAKE_AMPLITUDE(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x9219D44A, p0, p1); }
	static void SET_GAMEPLAY_HELPER_VOLUME_COORD(const char* volumeName, float x, float y, float z) { NativeInvoke::Invoke<void>(0xAE3938DF, volumeName, x, y, z); }
	static void SET_GAMEWORLD_AUDIO_MUTE(bool toggle) { NativeInvoke::Invoke<void>(0xFAC2EDD0, toggle); }
	static void SET_GAME_PAUSED(bool toggle) { NativeInvoke::Invoke<void>(0x8230FF6C, toggle); }
	static void SET_GAME_PAUSES_FOR_STREAMING(bool toggle) { NativeInvoke::Invoke<void>(0x9211A28A, toggle); }
	static void SET_GANG_RELATIONSHIPS_CAN_BE_CHANGED_BY_NEXT_COMMAND(bool toggle) { NativeInvoke::Invoke<void>(0x2682B38B, toggle); }
	static void SET_GANG_VEHICLE(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x924C8DBE, vehicle, toggle); }
	static void SET_GARBAGE_TRUCKS(bool toggle) { NativeInvoke::Invoke<void>(0xD9ABB0FF, toggle); }
	static void SET_GENERATE_BULLET_SHELLS(bool toggle) { NativeInvoke::Invoke<void>(0xA61EEC65, toggle); }
	static void SET_GLOBAL_INSTANCE_PRIORITY(int32_t priority) { NativeInvoke::Invoke<void>(0xEA330E59, priority); }
	static void SET_GLOBAL_PHASE_OVERRIDE(float value) { NativeInvoke::Invoke<void>(0x80E71892, value); }
	static void SET_GLOBAL_SUGGESTED_COMBAT_AREA_WEIGHT(float value) { NativeInvoke::Invoke<void>(0x84ED684E, value); }
	static void SET_GROUP_FORMATION(Group group, int32_t formation) { NativeInvoke::Invoke<void>(0x8FAC739, group, formation); }
	static void SET_GROUP_FORMATION_MAX_MOVE_SPEED(Group group, int32_t speedIndex) { NativeInvoke::Invoke<void>(0x76EEE1E6, group, speedIndex); }
	static void SET_GROUP_FORMATION_SPACING(Group group, float spacing) { NativeInvoke::Invoke<void>(0xB1E086FF, group, spacing); }
	static void SET_GROUP_FORMATION_WALK_ALONGSIDE_LEADER_WHEN_CLOSE(Group group, bool toggle) { NativeInvoke::Invoke<void>(0x55D415AA, group, toggle); }
	static void SET_GROUP_GRENADE_PARAMS(Group group, int32_t params) { NativeInvoke::Invoke<void>(0xAB1DEE08, group, params); }
	static void SET_GROUP_LAST_ALIVE_AS_LONE_WOLF(Group group, bool toggle) { NativeInvoke::Invoke<void>(0x32F7BB3B, group, toggle); }
	static void SET_GROUP_MAX_NUMS_FIRING(Group group, int32_t* values) { NativeInvoke::Invoke<void>(0x291609A6, group, values); }
	static void SET_GROUP_MAX_NUM_ADVANCING(Group group, int32_t value) { NativeInvoke::Invoke<void>(0x85CE849, group, value); }
	static void SET_GROUP_MAX_NUM_MOVING(Group group, int32_t value) { NativeInvoke::Invoke<void>(0x8F0D887F, group, value); }
	static void SET_GROUP_PED_DUCKS_WHEN_AIMED_AT(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x13408C5, ped, toggle); }
	static void SET_GROUP_RATIO_FIRING_AT_INVISIBLE(Group group, float ratio) { NativeInvoke::Invoke<void>(0x4A7E7B71, group, ratio); }
	static void SET_GROUP_RATIO_FIRING_AT_VISIBLE(Group group, float ratio) { NativeInvoke::Invoke<void>(0x16BCC68E, group, ratio); }
	static void SET_GROUP_SEPARATION_RANGE(Group group, float range) { NativeInvoke::Invoke<void>(0x7B820CD5, group, range); }
	static void SET_HANDYCAM_SHAKE(Cam cam, bool p1, bool p2, int32_t p3, float p4, float p5, float p6, float p7, float p8, float p9, int32_t p10) { NativeInvoke::Invoke<void>(0xC64D1A59, cam, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10); } 
	static void SET_HANG_GLIDER_AIR_SPEED(Ped ped, float p1, float p2, float p3) { NativeInvoke::Invoke<void>(0x300EF97E, ped, p1, p2, p3); }
	static void SET_HEADING_LIMIT_FOR_ATTACHED_PED(Ped ped, float p1, float p2) { NativeInvoke::Invoke<void>(0xA7813774, ped, p1, p2); }
	static void SET_HEADING_OF_CLOSEST_OBJECT_OF_TYPE(float x, float y, float z, float radius, uint32_t modelHash, float heading, bool p6) { NativeInvoke::Invoke<void>(0xB74D0E1B, x, y, z, radius, modelHash, heading, p6); }
	static void SET_HELI_BLADES_FULL_SPEED(Vehicle heli) { NativeInvoke::Invoke<void>(0x33A9408, heli); }
	static void SET_HELI_SPEED_CHEAT(Vehicle heli, bool toggle) { NativeInvoke::Invoke<void>(0xA694F55D, heli, toggle); }
	static void SET_HELMET_KNOCK_OFF_HEALTH(Ped ped, float health) { NativeInvoke::Invoke<void>(0x844A6C50, ped, health); }
	static void SET_HELPER_ENABLED(const char* iplName, bool p1, bool p2) { NativeInvoke::Invoke<void>(0x7E9977FC, iplName, p1, p2); }
	static void SET_HELPER_TRACKING_MODE(int32_t mode) { NativeInvoke::Invoke<void>(0xC935A93D, mode); }
	static void SET_HIGHEST_ARCADE_LEVEL_UNLOCKED(int32_t levelId) { NativeInvoke::Invoke<void>(0xC6B59993, levelId); }
	static void SET_HIGHEST_DIFFICULTY_BEAT() { NativeInvoke::Invoke<void>(0x6196D0C8); }
	static void SET_HIGH_RAGDOLL_LOD_LIMIT(int32_t limit) { NativeInvoke::Invoke<void>(0x8E88A11B, limit); }
	static void SET_HIGH_RAGDOLL_LOD_LIMIT_TO_DEFAULT() { NativeInvoke::Invoke<void>(0xB6E56387); }
	static void SET_HOLSTER_VISIBLE(Ped ped, int32_t holsterType, bool toggle) { NativeInvoke::Invoke<void>(0x3AC29772, ped, holsterType, toggle); }
	static void SET_HUD_TIMER(int32_t p0, int32_t p1) { NativeInvoke::Invoke<void>(0x4E42A47B, p0, p1); }
	static void SET_IGNORE_LOW_PRIORITY_SHOCKING_EVENTS(Player player, bool toggle) { NativeInvoke::Invoke<void>(0xA3D675ED, player, toggle); }
	static void SET_IK_ATTACH_TARGET_OBJ(Ped ped, Vehicle targetVehicle, const char* boneName) { NativeInvoke::Invoke<void>(0x77315EBE, ped, targetVehicle, boneName); }
	static void SET_IK_ATTACH_TARGET_PED(Ped ped, Ped targetPed, const char* boneName) { NativeInvoke::Invoke<void>(0x14A13274, ped, targetPed, boneName); }
	static void SET_IK_ATTACH_TARGET_VEH(Ped ped, Object targetObject, const char* boneName) { NativeInvoke::Invoke<void>(0x0497A7F, ped, targetObject, boneName); }
	static void SET_IMAGEFX_ENABLED(bool toggle) { NativeInvoke::Invoke<void>(0x50E9EF0E, toggle); }
	static void SET_INFO_TIMER(const char* p0, int32_t p1) { NativeInvoke::Invoke<void>(0x2402EFB6, p0, p1); }
	static void SET_INSTANT_FIRE_FORCED(bool toggle) { NativeInvoke::Invoke<void>(0x9BBE36A1, toggle); }
	static void SET_INTERACTIONTEXT_AVAILABLE(bool toggle) { NativeInvoke::Invoke<void>(0xDDCFB33F, toggle); }
	static void SET_INTERACTIONTEXT_BUTTON(int32_t button) { NativeInvoke::Invoke<void>(0xD2AC407F, button); }
	static void SET_INTERACTIONTEXT_BUTTON_VISIBLE(bool toggle) { NativeInvoke::Invoke<void>(0x120A3F51, toggle); }
	static void SET_INTERACTIONTEXT_PULSE(bool toggle) { NativeInvoke::Invoke<void>(0x3825FF30, toggle); }
	static void SET_INTERACTIONTEXT_PULSE_PERIOD(float period) { NativeInvoke::Invoke<void>(0xFE5984FF, period); }
	static void SET_INTERACTIONTEXT_TEXT(const char* text) { NativeInvoke::Invoke<void>(0x4C2397BD, text); }
	static void SET_INTERACTIONTEXT_VISIBLE(bool toggle) { NativeInvoke::Invoke<void>(0x20538A42, toggle); }
	static void SET_INTERACTION_VOLUME_BLIP_PARAMS(int32_t p0, int32_t p1, int32_t p2, float p3, int32_t p4, int32_t p5) { NativeInvoke::Invoke<void>(0xA90BA3FA, p0, p1, p2, p3, p4, p5); }
	static void SET_INTERACTION_VOLUME_STATIC_VARIABLES(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0x931C72B3, p0, p1, p2); }
	static void SET_INTERIOR_ACTIVE(Interior interior, bool p1, bool p2) { NativeInvoke::Invoke<void>(0xE1013910, interior, p1, p2); }
	static void SET_INTERIOR_FORCE_INSTANTIATION(Interior interior, bool toggle) { NativeInvoke::Invoke<void>(0x449FEFDF, interior, toggle); }
	static void SET_IN_MP_TUTORIAL(bool toggle) { NativeInvoke::Invoke<void>(0x2FD05431, toggle); }
	static void SET_IPL_ALWAYS_SEES_EXPLOSION(const char* iplName) { NativeInvoke::Invoke<void>(0xC59C35A7, iplName); }
	static void SET_KILL_EFFECT_NAME(const char* name) { NativeInvoke::Invoke<void>(0xCB39A28D, name); }
	static void SET_KILL_HEIGHT(float height) { NativeInvoke::Invoke<void>(0x50D3FF0E, height); }
	static void SET_LASER_COLOR(int32_t laser, float r, float g, float b, float a) { NativeInvoke::Invoke<void>(0xB76E5912, laser, r, g, b, a); }
	static void SET_LASER_SIGHT_ATTACHMENT(Weapon weapon, uint32_t hash) { NativeInvoke::Invoke<void>(0xF55F503F, weapon, hash); }
	static void SET_LASER_SPREAD(int32_t laser, float spread) { NativeInvoke::Invoke<void>(0xDEDBE1AD, laser, spread); }
	static void SET_LASER_WIDTH(int32_t laser, float width) { NativeInvoke::Invoke<void>(0x72312BB1, laser, width); }
	static void SET_LEFT_TRIGGER_HOLD_TIME(int32_t time) { NativeInvoke::Invoke<void>(0xADE291A3, time); }
	static void SET_LEVEL_COMPLETION(int32_t value) { NativeInvoke::Invoke<void>(0x3C14716, value); }
	static void SET_LMS_TUTORIAL_COMPLETE() { NativeInvoke::Invoke<void>(0x6715E605); }
	static void SET_LOAD_COLLISION_FOR_PED_FLAG(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x887E7D88, ped, toggle); }
	static void SET_LOAD_COLLISION_FOR_VEHICLE_FLAG(Vehicle vehicle, bool flag) { NativeInvoke::Invoke<void>(0x3AEC5728, vehicle, flag); }
	static void SET_LOCAL_EXPERIENCE_MULTIPLIER(float multiplier) { NativeInvoke::Invoke<void>(0xECF21382, multiplier); }
	static void SET_LOCAL_PLAYER_CAN_USE_SHOOTDODGE(bool toggle) { NativeInvoke::Invoke<void>(0xC6BB1780, toggle); }
	static void SET_LOCKED_TARGET(Ped ped, Ped targetPed) { NativeInvoke::Invoke<void>(0xE0E4C21C, ped, targetPed); }
	static void SET_LOCKON_TO_FRIENDLY_PLAYERS(Player player, bool toggle) { NativeInvoke::Invoke<void>(0x60FFC7F8, player, toggle); }
	static void SET_LOOK_INVERT(bool toggle) { NativeInvoke::Invoke<void>(0xC6A53617, toggle); }
	static void SET_MAD_DRIVERS(bool toggle) { NativeInvoke::Invoke<void>(0x4B7E75DC, toggle); }
	static void SET_MASK_ACTIVE(bool toggle) { NativeInvoke::Invoke<void>(0xFC3F8FE9, toggle); }
	static void SET_MASK_ATTRIBUTES(float p0, float p1, float p2, float p3) { NativeInvoke::Invoke<void>(0x72C4D458, p0, p1, p2, p3); }
	static void SET_MAX_SUPPRESSOR_DAMAGE_LEVEL(Weapon weapon, int32_t damageLevel) { NativeInvoke::Invoke<void>(0x4E17C02F, weapon, damageLevel); }
	static void SET_MAX_WANTED_LEVEL(int32_t wantedLevel) { NativeInvoke::Invoke<void>(0x665A06F5, wantedLevel); }
	static void SET_MEDIUM_BOATS_PROPELLOR_PTFX_MAX_SPEED_EVO(bool toggle) { NativeInvoke::Invoke<void>(0x3F38479B, toggle); }
	static void SET_MEDIUM_BOATS_PTFX_MAX_SPEED_EVO(bool toggle) { NativeInvoke::Invoke<void>(0x4CF8B8D7, toggle); }
	static void SET_MELEE_GRAPPLE_FAIL(Ped ped) { NativeInvoke::Invoke<void>(0xE7360DE9, ped); }
	static void SET_MELEE_GRAPPLE_SUCCESS(Ped ped) { NativeInvoke::Invoke<void>(0xF8251BF3, ped); }
	static void SET_MESSAGES_WAITING(bool toggle) { NativeInvoke::Invoke<void>(0x15A9C493, toggle); }
	static void SET_MINIGAME_IN_PROGRESS(bool toggle) { NativeInvoke::Invoke<void>(0x348B9046, toggle); }
	static void SET_MISSION_FLAG(bool value) { NativeInvoke::Invoke<void>(0x57592D52, value); }
	static void SET_MISSION_TRAINS_AS_NO_LONGER_NEEDED() { NativeInvoke::Invoke<void>(0x22BEB86E); }
	static void SET_MISSION_TRAIN_AS_NO_LONGER_NEEDED(Vehicle train) { NativeInvoke::Invoke<void>(0x19808560, train); }
	static void SET_MISSION_TRAIN_COORDS(Vehicle train, float x, float y, float z) { NativeInvoke::Invoke<void>(0xD6D70803, train, x, y, z); }
	static void SET_MODEL_AS_NO_LONGER_NEEDED(uint32_t modelHash) { NativeInvoke::Invoke<void>(0xAE0F069E, modelHash); }
	static void SET_MONITORED_STATS(Any* p0) { NativeInvoke::Invoke<void>(0x2AC96CE9, p0); }
	static void SET_MOVER_ACTIVE(Object object, bool toggle) { NativeInvoke::Invoke<void>(0xD1064073, object, toggle); }
	static void SET_MOVER_SPEED(Object object, float p1, float p2) { NativeInvoke::Invoke<void>(0xACF9574C, object, p1, p2); }
	static void SET_MOVIE_FRAME(int32_t p0, int32_t frame) { NativeInvoke::Invoke<void>(0xFD8B4DAA, p0, frame); }
	static void SET_MOVIE_LOOP(int32_t p0, bool toggle) { NativeInvoke::Invoke<void>(0x14A87C9F, p0, toggle); }
	static void SET_MOVIE_TIME(int32_t p0, float time) { NativeInvoke::Invoke<void>(0xA1930880, p0, time); }
	static void SET_MOVIE_TINT(int32_t p0, float p1, float p2, float p3, float p4) { NativeInvoke::Invoke<void>(0x1E907D2D, p0, p1, p2, p3, p4); }
	static void SET_MOVIE_VOLUME(int32_t p0, float volume) { NativeInvoke::Invoke<void>(0x21D93ADF, p0, volume); }
	static void SET_MPBAG_OVERHEAD_PARAMS(int32_t p0, int32_t p1, int32_t p2, int32_t p3, bool p4, bool p5, const char* text) { NativeInvoke::Invoke<void>(0x1332298C, p0, p1, p2, p3, p4, p5, text); }
	static void SET_MPITEMS_OVERHEAD_ICONS_ENABLED(bool p0, bool p1) { NativeInvoke::Invoke<void>(0x13672AC9, p0, p1); }
	static void SET_MP_GAME_DIFFICULTY(int32_t difficulty) { NativeInvoke::Invoke<void>(0x86C7C8EF, difficulty); }
	static void SET_MP_LAST_MAN_STANDING_DOWN_TIME(int32_t time) { NativeInvoke::Invoke<void>(0x8E926913, time); }
	static void SET_MP_LAST_MAN_STANDING_FLAGS(bool p0, bool p1, bool p2, bool p3, int32_t p4) { NativeInvoke::Invoke<void>(0xAFF1FF49, p0, p1, p2, p3, p4); }
	static void SET_MP_LAST_MAN_STANDING_INVINCIBLE_TIME(int32_t time) { NativeInvoke::Invoke<void>(0x8261FB4, time); }
	static void SET_MSG_FOR_LOADING_SCREEN(const char* msg) { NativeInvoke::Invoke<void>(0xC128376, msg); }
	static void SET_MULTIPLAYER_HUD_CASH(int32_t cash) { NativeInvoke::Invoke<void>(0xA8DB435E, cash); }
	static void SET_MULTIPLAYER_HUD_SCORE_STATS(int32_t p0, int32_t p1) { NativeInvoke::Invoke<void>(0xA98EAAB3, p0, p1); }
	static void SET_MULTIPLAYER_HUD_TIME(const char* time) { NativeInvoke::Invoke<void>(0x72F2B585, time); }
	static void SET_NETWORK_OBJECT_TERRITORY_EFFECT(Object object, float p1, float p2, int32_t color) { NativeInvoke::Invoke<void>(0xB0A0AF9E, object, p1, p2, color); }
	static void SET_NETWORK_SETTINGS_MENU(bool p0) { NativeInvoke::Invoke<void>(0x21C7922C, p0); }
	static void SET_NEW_GAME_READY() { NativeInvoke::Invoke<void>(0x467EAD5A); }
	static void SET_NEXT_DESIRED_MOVE_STATE(int32_t moveState) { NativeInvoke::Invoke<void>(0x4E937D57, moveState); }
	static void SET_NEXT_MULTIPLAYER_MESSAGE_TIMEOUT(Any p0, Any p1) { NativeInvoke::Invoke<void>(0xB1EF9817, p0, p1); }
	static void SET_NEXT_STREAMING_REQUEST_A_PRIORITY() { NativeInvoke::Invoke<void>(0x20F0F689); }
	static void SET_NIGHTVISION(bool toggle) { NativeInvoke::Invoke<void>(0xD1E5565F, toggle); }
	static void SET_NM_MESSAGE_FLOAT(int32_t messageId, float value) { NativeInvoke::Invoke<void>(0xE2959702, messageId, value); }
	static void SET_NM_MESSAGE_INSTANCE_INDEX(int32_t messageId, Ped ped, Vehicle vehicle, Object object) { NativeInvoke::Invoke<void>(0xC8B5DFE3, messageId, ped, vehicle, object); }
	static void SET_NM_MESSAGE_INT(int32_t messageId, int32_t value) { NativeInvoke::Invoke<void>(0x7FA76EE4, messageId, value); }
	static void SET_NM_MESSAGE_STRING(int32_t messageId, const char* value) { NativeInvoke::Invoke<void>(0x7A0DF013, messageId, value); }
	static void SET_NM_MESSAGE_VEC3(int32_t messageId, float x, float y, float z) { NativeInvoke::Invoke<void>(0x535F6DCE, messageId, x, y, z); }
	static void SET_NM_MESSAGE_bool(int32_t messageId, bool value) { NativeInvoke::Invoke<void>(0xAEF25DC5, messageId, value); }
	static void SET_NOISEOVERIDE(bool toggle) { NativeInvoke::Invoke<void>(0xD576F5DD, toggle); }
	static void SET_NOISINESSOVERIDE(float value) { NativeInvoke::Invoke<void>(0x46B62D9, value); }
	static void SET_NO_COLLISION_TO_PED(Ped ped, Ped ped2, bool p2, bool p3) { NativeInvoke::Invoke<void>(0x16D410E1, ped, ped2, p2, p3); }
	static void SET_NUMBER_OF_PARKED_VEHICLES(int32_t value) { NativeInvoke::Invoke<void>(0x206A58E8, value); }
	static void SET_OBJECTS_AT_COORD_NOT_REMOVED_BY_STREAMING(float x, float y, float z) { NativeInvoke::Invoke<void>(0x45BDCE6D, x, y, z); }
	static void SET_OBJECT_ANCHOR(Object object, bool toggle, float p2) { NativeInvoke::Invoke<void>(0xC97C227A, object, toggle, p2); }
	static void SET_OBJECT_ANIM_CURRENT_TIME(Any p0, Any p1, Any p2, Any p3) { NativeInvoke::Invoke<void>(0xDFA5AD5A, p0, p1, p2, p3); }
	static void SET_OBJECT_ANIM_SPEED(Any p0, Any p1, Any p2, Any p3) { NativeInvoke::Invoke<void>(0x485459F9, p0, p1, p2, p3); }
	static void SET_OBJECT_AS_FLIPPABLE_TABLE(Object object, bool toggle) { NativeInvoke::Invoke<void>(0xBF817CCD, object, toggle); }
	static void SET_OBJECT_AS_NON_PATH_OBSTACLE(Object object) { NativeInvoke::Invoke<void>(0xB507654A, object); }
	static void SET_OBJECT_AS_NO_LONGER_NEEDED(Object* object) { NativeInvoke::Invoke<void>(0x3F6B949F, object); }
	static void SET_OBJECT_AS_PATH_OBSTACLE(Object object) { NativeInvoke::Invoke<void>(0x2AD60AF9, object); }
	static void SET_OBJECT_AS_STEALABLE(Object object, bool toggle) { NativeInvoke::Invoke<void>(0x23A96397, object, toggle); }
	static void SET_OBJECT_BULLET_CAM_PREF(Object object, const char* p1) { NativeInvoke::Invoke<void>(0x35B1DB56, object, p1); }
	static void SET_OBJECT_CAN_TRIGGER_BULLET_CAM(Object object, bool toggle) { NativeInvoke::Invoke<void>(0x9D9BD0D4, object, toggle); }
	static void SET_OBJECT_COLLIDE_WITH_NON_PLAYER_CHARACTER(Object object, bool toggle) { NativeInvoke::Invoke<void>(0xF77D385E, object, toggle); }
	static void SET_OBJECT_COLLIDE_WITH_OTHER_OBJECTS(Object object, bool toggle) { NativeInvoke::Invoke<void>(0x53B55EE5, object, toggle); }
	static void SET_OBJECT_COLLISION(Object object, bool toggle) { NativeInvoke::Invoke<void>(0xEDEA40E8, object, toggle); }
	static void SET_OBJECT_COORDS(Object object, float x, float y, float z) { NativeInvoke::Invoke<void>(0x3C07FE50, object, x, y, z); }
	static void SET_OBJECT_DYNAMIC(Object object, bool toggle) { NativeInvoke::Invoke<void>(0xD73719EF, object, toggle); }
	static void SET_OBJECT_HEADING(Object object, float heading) { NativeInvoke::Invoke<void>(0xE094E341, object, heading); }
	static void SET_OBJECT_HEALTH(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x6ACE668, p0, p1); }
	static void SET_OBJECT_INITIAL_VELOCITY(Object object, float x, float y, float z) { NativeInvoke::Invoke<void>(0xE20C80E4, object, x, y, z); }
	static void SET_OBJECT_INVINCIBLE(Object object, bool toggle) { NativeInvoke::Invoke<void>(0xEF19EDA6, object, toggle); }
	static void SET_OBJECT_LIGHTS(Object object, bool toggle) { NativeInvoke::Invoke<void>(0x88EB06E8, object, toggle); }
	static void SET_OBJECT_ONLY_DAMAGED_BY_PLAYER(Object object, bool toggle) { NativeInvoke::Invoke<void>(0x9D22CD69, object, toggle); }
	static void SET_OBJECT_PHYSICS_PARAMS(Object object, float p1, float p2, float p3, float p4, float p5, float p6, float p7, float p8, float p9, float p10) { NativeInvoke::Invoke<void>(0xE8D11C58, object, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10); }
	static void SET_OBJECT_PROOFS(Object object, bool p1, bool p2, bool p3, bool p4, bool p5) { NativeInvoke::Invoke<void>(0x7EA4940, object, p1, p2, p3, p4, p5); }
	static void SET_OBJECT_QUATERNION(Object object, float x, float y, float z, float w) { NativeInvoke::Invoke<void>(0x1BAC5DC1, object, x, y, z, w); }
	static void SET_OBJECT_RECORDS_COLLISIONS(Object object, bool toggle) { NativeInvoke::Invoke<void>(0x26461274, object, toggle); }
	static void SET_OBJECT_REFLECTS(Object object, bool toggle) { NativeInvoke::Invoke<void>(0x867B848E, object, toggle); }
	static void SET_OBJECT_ROTATION(Object object, float pitch, float roll, float yaw) { NativeInvoke::Invoke<void>(0xB9BF4EA7, object, pitch, roll, yaw); }
	static void SET_OBJECT_SILHOUETTE_COLOUR(Object object, int32_t color) { NativeInvoke::Invoke<void>(0x70F34A3E, object, color); }
	static void SET_OBJECT_SILHOUETTE_ENABLED(Object object, bool p1, bool p2) { NativeInvoke::Invoke<void>(0xB0533CEB, object, p1, p2); }
	static void SET_OBJECT_TARGETTABLE(Object object, bool toggle) { NativeInvoke::Invoke<void>(0x3F88CD86, object, toggle); }
	static void SET_OBJECT_USE_WATER_PARTICLES(Object object, bool toggle) { NativeInvoke::Invoke<void>(0x549C7D2A, object, toggle); }
	static void SET_OBJECT_VISIBLE(Object object, bool toggle) { NativeInvoke::Invoke<void>(0x9DB02973, object, toggle); }
	static void SET_OVERHEAT_AMOUNT(float amount) { NativeInvoke::Invoke<void>(0x624A49AE, amount); }
	static void SET_OVERRIDE_NO_SPRINTING_ON_PHONE_IN_MULTIPLAYER(bool toggle) { NativeInvoke::Invoke<void>(0xE9FDDA54, toggle); }
	static void SET_PAD_SHAKE(int32_t padIndex, int32_t duration, int32_t frequency) { NativeInvoke::Invoke<void>(0x5D38BD2F, padIndex, duration, frequency); }
	static void SET_PARKED_VEHICLE_DENSITY_MULTIPLIER(float multiplier) { NativeInvoke::Invoke<void>(0x98E5C8A7, multiplier); }
	static void SET_PARTICLE_FX_CAM_INSIDE_VEHICLE(bool toggle) { NativeInvoke::Invoke<void>(0x19EC0001, toggle); }
	static void SET_PARTICLE_FX_LOOPED_EVOLUTION(Any ptfxHandle, const char* propertyName, float value) { NativeInvoke::Invoke<void>(0x1CBC1373, ptfxHandle, propertyName, value); }
	static void SET_PARTICLE_FX_LOOPED_OFFSETS(Any ptfxHandle, float p1, float p2, float p3, float p4, float p5, float p6, float p7) { NativeInvoke::Invoke<void>(0x641F7790, ptfxHandle, p1, p2, p3, p4, p5, p6, p7); }
	static void SET_PAUSE_MENU_ACTIVE(bool toggle) { NativeInvoke::Invoke<void>(0x1DCD878E, toggle); }
	static void SET_PAYNEKILLER_AMT(int32_t amount) { NativeInvoke::Invoke<void>(0x3DE72BB3, amount); }
	static void SET_PAYNEKILLER_HEALTH_BOOST(float value) { NativeInvoke::Invoke<void>(0x5E231B87, value); }
	static void SET_PAYNE_BOAT_PROPELLOR_PTFX_MAX_SPEED_EVO(bool toggle) { NativeInvoke::Invoke<void>(0x3A35B972, toggle); }
	static void SET_PAYNE_BOAT_PTFX_CUTSCENE_EFFECT(bool toggle) { NativeInvoke::Invoke<void>(0xDBC06AE9, toggle); }
	static void SET_PAYNE_BOAT_PTFX_CUTSCENE_PROPELLOR_EFFECT(bool toggle) { NativeInvoke::Invoke<void>(0x58EBC01, toggle); }
	static void SET_PAYNE_BOAT_PTFX_MAX_SPEED_EVO(bool toggle) { NativeInvoke::Invoke<void>(0xD1BDFF84, toggle); }
	static void SET_PAYNE_BOAT_PTFX_SKIP(bool toggle) { NativeInvoke::Invoke<void>(0xE9719836, toggle); }
	static void SET_PED_ACCURACY(Ped ped, int32_t accuracy) { NativeInvoke::Invoke<void>(0x6C17122E, ped, accuracy); }
	static void SET_PED_AIM_LOCKONABLE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xF68161DB, ped, toggle); }
	static void SET_PED_AI_TEMPLATE(Ped ped, const char* name) { NativeInvoke::Invoke<void>(0x740A036E, ped, name); }
	static void SET_PED_ALERTNESS(Ped ped, int32_t alertness) { NativeInvoke::Invoke<void>(0x2C32D9AE, ped, alertness); }
	static void SET_PED_ALLOWED_TO_ATTACK_IF_SURRENDERED(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xDA7D361A, ped, toggle); }
	static void SET_PED_ALLOWED_TO_DESTROY_IF_SURRENDERED(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x6400B52C, ped, toggle); }
	static void SET_PED_ALLOWED_TO_DUCK(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xC4D122F8, ped, toggle); }
	static void SET_PED_ALLOWED_TO_KNEEL_AND_FIRE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x5A338B9, ped, toggle); }
	static void SET_PED_ALLOWED_TO_STAND(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x86A96807, ped, toggle); }
	static void SET_PED_ALLOWED_TO_SURRENDER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xBCFA8338, ped, toggle); }
	static void SET_PED_ALL_ANIMS_SPEED(Ped ped, float speed) { NativeInvoke::Invoke<void>(0x83C20759, ped, speed); }
	static void SET_PED_AMMO(Ped ped, uint32_t weaponHash, int32_t ammo) { NativeInvoke::Invoke<void>(0xBF90DF1A, ped, weaponHash, ammo); }
	static void SET_PED_ANGLED_DEFENSIVE_AREA(Ped ped, float x1, float y1, float z1, float x2, float y2, float z2, float angle) { NativeInvoke::Invoke<void>(0x3EFBDD9B, ped, x1, y1, z1, x2, y2, z2, angle); }
	static void SET_PED_ANIM_CURRENT_TIME(Ped ped, const char* animDict, const char* animName, float time) { NativeInvoke::Invoke<void>(0xF1C753D6, ped, animDict, animName, time); }
	static void SET_PED_ANIM_GROUP(Ped ped, const char* name) { NativeInvoke::Invoke<void>(0x55617E2A, ped, name); }
	static void SET_PED_ANIM_SPEED(Ped ped, const char* animDict, const char* animName, float speed) { NativeInvoke::Invoke<void>(0x40B81E24, ped, animDict, animName, speed); }
	static void SET_PED_AS_ENEMY(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xAE620A1B, ped, toggle); }
	static void SET_PED_AS_GROUP_LEADER(Ped ped, Group group) { NativeInvoke::Invoke<void>(0x7265BEA2, ped, group); }
	static void SET_PED_AS_GROUP_MEMBER(Ped ped, Group group) { NativeInvoke::Invoke<void>(0xEE13F92, ped, group); }
	static void SET_PED_AS_MISSION_PED(Ped ped) { NativeInvoke::Invoke<void>(0x8F46967F, ped); }
	static void SET_PED_AS_NO_LONGER_NEEDED(Ped* ped) { NativeInvoke::Invoke<void>(0x9A388380, ped); }
	static void SET_PED_AS_ONE_SHOT_KILL(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x46ED955A, ped, toggle); }
	static void SET_PED_AS_PRIMARY_CHAR(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x551FE4E8, ped, toggle); }
	static void SET_PED_AUTO_UPDATE_EMOTION_STATE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x50F22719, ped, toggle); }
	static void SET_PED_BLEND_TO_CROUCHING_FROM_NM(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xB16475C3, ped, toggle); }
	static void SET_PED_BLOODSPRAY_ENABLE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xAD56E6F2, ped, toggle); }
	static void SET_PED_BLOOD_SMEAR(Ped ped, int32_t smear) { NativeInvoke::Invoke<void>(0xEA3D0C15, ped, smear); }
	static void SET_PED_BOSS_PECENT_DAMAGED(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x90C7954A, ped, toggle); }
	static void SET_PED_BULLET_CAMERA_ON_NEXT_HIT(Ped ped) { NativeInvoke::Invoke<void>(0xF43737FB, ped); } 
	static void SET_PED_CAN_Avoid_DEATH_ZONES(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x712B78D8, ped, toggle); }
	static void SET_PED_CAN_BE_DAMAGED_BY_RELATIONSHIP_GROUP(Ped ped, bool toggle, int32_t relGroupId) { NativeInvoke::Invoke<void>(0x2F97988A, ped, toggle, relGroupId); }
	static void SET_PED_CAN_BE_DRAGGED_OUT(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xAA7F1131, ped, toggle); }
	static void SET_PED_CAN_BE_KNOCKED_OFF_BIKE(Ped ped, int32_t state) { NativeInvoke::Invoke<void>(0x83645D83, ped, state); }
	static void SET_PED_CAN_BE_MELEED(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x48AF2BA0, ped, toggle); }
	static void SET_PED_CAN_BE_SHOT_IN_VEHICLE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x5DB7B3A9, ped, toggle); }
	static void SET_PED_CAN_BE_SNAPPED_TO_GROUND(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xBE7D2E94, ped, toggle); }
	static void SET_PED_CAN_BE_TARGETED_WHEN_INJURED(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x6FD9A7CD, ped, toggle); }
	static void SET_PED_CAN_BE_TARGETED_WITHOUT_LOS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x7FDDC0A6, ped, toggle); }
	static void SET_PED_CAN_BE_TARGETTED(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x75C49F74, ped, toggle); }
	static void SET_PED_CAN_COWER_IN_COVER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x5194658B, ped, toggle); }
	static void SET_PED_CAN_EVASIVE_DIVE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x542FEB4D, ped, toggle); }
	static void SET_PED_CAN_FLY_THROUGH_WINDSCREEN(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x348F2753, ped, toggle); }
	static void SET_PED_CAN_HEAD_IK(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xD3B04476, ped, toggle); }
	static void SET_PED_CAN_INITIATE_BULLET_CAM(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x63621CC9, ped, toggle); }
	static void SET_PED_CAN_INTERACT_WITH_DOORS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x60055ED3, ped, toggle); }
	static void SET_PED_CAN_MELEE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xF4B9253B, ped, toggle); }
	static void SET_PED_CAN_MOVE_WHEN_INJURED(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xF6589BD1, ped, toggle); }
	static void SET_PED_CAN_PEEK_IN_COVER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xC1DAE216, ped, toggle); }
	static void SET_PED_CAN_PLAY_AMBIENT_ANIMS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xF8053081, ped, toggle); }
	static void SET_PED_CAN_PLAY_GESTURE_ANIMS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xE131E3B3, ped, toggle); }
	static void SET_PED_CAN_PLAY_LOCO_FLAVOR_STARTS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xAA96A1D3, ped, toggle); }
	static void SET_PED_CAN_PLAY_VISEME_ANIMS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xA2FDAF27, ped, toggle); }
	static void SET_PED_CAN_PUSH_PLAYER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xCEEB20E6, ped, toggle); }
	static void SET_PED_CAN_PUT_PLAYER_INTO_LMS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x6B2B3B17, ped, toggle); }
	static void SET_PED_CAN_RAGDOLL(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xCF1384C4, ped, toggle); }
	static void SET_PED_CAN_RAGDOLL_FROM_PLAYER_IMPACT(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xE9BD733A, ped, toggle); }
	static void SET_PED_CAN_REMAIN_ON_BOAT_AFTER_MISSION_ENDS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x3B9C6330, ped, toggle); }
	static void SET_PED_CAN_SLOW_DOWN_WHEN_TURNING(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xC7628C42, ped, toggle); }
	static void SET_PED_CAN_SMASH_GLASS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x149C60A8, ped, toggle); }
	static void SET_PED_CAN_SWITCH_WEAPON(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xB5F8BA28, ped, toggle); }
	static void SET_PED_CAN_TRIGGER_BULLET_CAM(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x7DF0538C, ped, toggle); }
	static void SET_PED_CAN_USE_AUTO_CONVERSATION_LOOKAT(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x584C5178, ped, toggle); }
	static void SET_PED_CHANCE_TO_REACT_TO_IMMINENT_DANGER(Ped ped, int32_t chance) { NativeInvoke::Invoke<void>(0x75959444, ped, chance); }
	static void SET_PED_CHANCE_TO_SHOOT_AT_DESTRUCTIBLES(Ped ped, int32_t chance) { NativeInvoke::Invoke<void>(0x4E22797C, ped, chance); }
	static void SET_PED_CLEAR_COVER_TARGET(Ped ped) { NativeInvoke::Invoke<void>(0xAE78C3AE, ped); }
	static void SET_PED_CLIMB_ANIM_RATE(Ped ped, float rate) { NativeInvoke::Invoke<void>(0x571A7C60, ped, rate); }
	static void SET_PED_COLLISION(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xDB1B8AAC, ped, toggle); }
	static void SET_PED_COMBAT_ABILITY(Ped ped, int32_t type) { NativeInvoke::Invoke<void>(0x6C23D329, ped, type); }
	static void SET_PED_COMBAT_ADVANCE_DELAY_TIME(Ped ped, float p1, float p2) { NativeInvoke::Invoke<void>(0x3561D19D, ped, p1, p2); }
	static void SET_PED_COMBAT_ATTRIBUTES(Ped ped, int32_t attributes, bool enabled) { NativeInvoke::Invoke<void>(0x81D64248, ped, attributes, enabled); }
	static void SET_PED_COMBAT_MOVEMENT(Ped ped, int32_t type) { NativeInvoke::Invoke<void>(0x12E62F9E, ped, type); }
	static void SET_PED_COMBAT_RANGE(Ped ped, int32_t type) { NativeInvoke::Invoke<void>(0x8818A959, ped, type); }
	static void SET_PED_COMBAT_RANGE_HALF_HEIGHT(Ped ped, float value) { NativeInvoke::Invoke<void>(0xC551CE6B, ped, value); }
	static void SET_PED_COMBAT_RANGE_MAX(Ped ped, float range) { NativeInvoke::Invoke<void>(0x7DC35B63, ped, range); }
	static void SET_PED_COMBAT_RANGE_MIN(Ped ped, float range) { NativeInvoke::Invoke<void>(0xFF2BE6DE, ped, range); }
	static void SET_PED_COMPONENT_VARIATION(Ped ped, int32_t componentId, int32_t drawableId, int32_t textureId, int32_t paletteId) { NativeInvoke::Invoke<void>(0xD4F7B05C, ped, componentId, drawableId, textureId, paletteId); }
	static void SET_PED_CONSUMING_AMMO(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xECFC30AE, ped, toggle); }
	static void SET_PED_COORDS(Ped ped, float x, float y, float z, bool unk) { NativeInvoke::Invoke<void>(0x16BE1EC7, ped, x, y, z, unk); }
	static void SET_PED_COORDS_NO_GANG(Ped ped, float x, float y, float z) { NativeInvoke::Invoke<void>(0x9561AD98, ped, x, y, z); }
	static void SET_PED_COORDS_NO_OFFSET(Ped ped, float x, float y, float z) { NativeInvoke::Invoke<void>(0x293C3D75, ped, x, y, z); }
	static void SET_PED_CORPSE(Ped ped, bool unk) { NativeInvoke::Invoke<void>(0x804AC45F, ped, unk); }
	static void SET_PED_CORPSE_FROM_ANIM(Ped ped, const char* dictName, const char* animName, float p3, bool p4) { NativeInvoke::Invoke<void>(0x73405D87, ped, dictName, animName, p3, p4); }
	static void SET_PED_COVER_REQUEST_BLINDFIRE(Ped ped) { NativeInvoke::Invoke<void>(0x9FF457F8, ped); }
	static void SET_PED_COVER_REQUEST_PEEK(Ped ped) { NativeInvoke::Invoke<void>(0xD00F7A1A, ped); }
	static void SET_PED_COVER_TARGET_COORD(Ped ped, float x, float y, float z) { NativeInvoke::Invoke<void>(0xA4AEF03C, ped, x, y, z); }
	static void SET_PED_COVER_TARGET_PED(Ped ped, Ped targetPed) { NativeInvoke::Invoke<void>(0x895736EF, ped, targetPed); }
	static void SET_PED_COVER_TARGET_VEHICLE(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5) { NativeInvoke::Invoke<void>(0xBA0BDD53, p0, p1, p2, p3, p4, p5); }
	static void SET_PED_CURRENT_WEAPON_VISIBLE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x0BECD77, ped, toggle); }
	static void SET_PED_CUSTOM_FIRING_PATTERN_SHOTS_PER_BURST(Ped ped, int32_t p1, int32_t p2) { NativeInvoke::Invoke<void>(0x91ACB728, ped, p1, p2); }
	static void SET_PED_CUSTOM_FIRING_PATTERN_TIME_BETWEEN_BURSTS(Ped ped, float p1, float p2) { NativeInvoke::Invoke<void>(0x8572A5F9, ped, p1, p2); }
	static void SET_PED_CUSTOM_FIRING_PATTERN_TIME_BETWEEN_SHOTS(Ped ped, float p1, float p2) { NativeInvoke::Invoke<void>(0x86B5FF2B, ped, p1, p2); }
	static void SET_PED_DAMAGED_BY_TEAR_GAS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x8C2C034A, ped, toggle); }
	static void SET_PED_DEFAULT_AIM_AHEAD(Ped ped) { NativeInvoke::Invoke<void>(0x68A4CCB, ped); }
	static void SET_PED_DEFAULT_AIM_AT_COORD(Ped ped, float x, float y, float z) { NativeInvoke::Invoke<void>(0x313066FE, ped, x, y, z); }
	static void SET_PED_DEFAULT_AIM_AT_PED(Ped ped, Ped targetPed) { NativeInvoke::Invoke<void>(0x32BF7F45, ped, targetPed); }
	static void SET_PED_DEFAULT_COMPONENT_VARIATION(Ped ped) { NativeInvoke::Invoke<void>(0xC866A984, ped); }
	static void SET_PED_DEFENSIVE_AREA_ATTACHED_TO_PED(Ped ped, Ped ped2, float x1, float y1, float z1, float x2, float y2, float z2, float angle, bool p9) { NativeInvoke::Invoke<void>(0x74BDA7CE, ped, ped2, x1, y1, z1, x2, y2, z2, angle, p9); }
	static void SET_PED_DEFENSIVE_AREA_DIRECTION(Ped ped, float xDir, float yDir, float zDir) { NativeInvoke::Invoke<void>(0xB66B0C9A, ped, xDir, yDir, zDir); }
	static void SET_PED_DENSITY_MULTIPLIER(float multiplier) { NativeInvoke::Invoke<void>(0x87FDB5D1, multiplier); }
	static void SET_PED_DESIRED_HEADING(Ped ped, float heading) { NativeInvoke::Invoke<void>(0x961458F9, ped, heading); }
	static void SET_PED_DIES_INSTANTLY_IN_WATER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xFE2554FC, ped, toggle); }
	static void SET_PED_DIES_IN_SINKING_VEHICLE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x8D4D9ABB, ped, toggle); }
	static void SET_PED_DIES_IN_VEHICLE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x6FE1E440, ped, toggle); }
	static void SET_PED_DIES_IN_WATER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x604C872B, ped, toggle); }
	static void SET_PED_DIES_WHEN_INJURED(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xE94E24D4, ped, toggle); }
	static void SET_PED_DONT_USE_VEHICLE_SPECIFIC_ANIMS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x23108373, ped, toggle); }
	static void SET_PED_DROPS_WEAPONS_WHEN_DEAD(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x8A444056, ped, toggle); }
	static void SET_PED_DRUGGED_UP(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xC89BFBED, ped, toggle); }
	static void SET_PED_DUCKING(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xB90353D7, ped, toggle); }
	static void SET_PED_EDGE_COVER_BLINDFIRE_ARC_OVERRIDE(Ped ped, float p1) { NativeInvoke::Invoke<void>(0xFDB77BC9, ped, p1); }
	static void SET_PED_EMOTION_STATE(Ped ped, int32_t state) { NativeInvoke::Invoke<void>(0xF8A51CEC, ped, state); }
	static void SET_PED_ENABLE_DISTANCE_INACCURACY(Ped ped, bool toggle, float p2) { NativeInvoke::Invoke<void>(0xB6B77BAC, ped, toggle, p2); }
	static void SET_PED_ENABLE_HEADLOOK_CONTROLLER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xD74C9BA1, ped, toggle); }
	static void SET_PED_ENABLE_SPAWN_INACCURACY(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x305CA230, ped, toggle); }
	static void SET_PED_FIELD_OF_VIEW(Ped ped, float p1, float p2, float p3) { NativeInvoke::Invoke<void>(0x57655E86, ped, p1, p2, p3); }
	static void SET_PED_FIRE_AT_COVER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x29AD93BB, ped, toggle); }
	static void SET_PED_FLAG_AGGRESSIVE_CHARGER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xAA129637, ped, toggle); }
	static void SET_PED_FLAG_ALWAYS_HIDE_WHEN_IN_COVER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x76529381, ped, toggle); }
	static void SET_PED_FLAG_BLOCK_BLINDFIRE_IN_COVER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xE80E66BF, ped, toggle); }
	static void SET_PED_FLAG_BLOCK_GORE_REACTION(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x3D64E5F1, ped, toggle); }
	static void SET_PED_FLAG_BLOCK_LEANFIRE_IN_COVER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x1335ACA9, ped, toggle); }
	static void SET_PED_FLAG_BLOCK_WOUNDED_MOVEMENT(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xCE23372D, ped, toggle); }
	static void SET_PED_FLAG_COMBAT_LEADER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x757654BD, ped, toggle); }
	static void SET_PED_FLAG_FIRE_UNTIL_EMPTY_IN_COVER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x852834FB, ped, toggle); }
	static void SET_PED_FLAG_FORCE_BLINDFIRE_IN_COVER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x28E044EB, ped, toggle); }
	static void SET_PED_FLAG_FORCE_LEANFIRE_IN_COVER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x25866265, ped, toggle); }
	static void SET_PED_FLAG_FORCE_THROW_PROJECTILE_IN_COVER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x70F9E56C, ped, toggle); }
	static void SET_PED_FLAG_LOCK_TO_COVER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xB845B91D, ped, toggle); }
	static void SET_PED_FLAG_SCRIPTED_PROJECTILE_USE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x5D1A0A76, ped, toggle); }
	static void SET_PED_FLAG_SNIPE_MOVING_TARGETS_OVERRIDE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xB1880102, ped, toggle); }
	static void SET_PED_FLEEZONE_ADD_BOX(Ped ped, const char* name) { NativeInvoke::Invoke<void>(0xDAC64BE1, ped, name); }
	static void SET_PED_FLEEZONE_OPTION(Ped ped, int32_t option) { NativeInvoke::Invoke<void>(0x3C2DBC49, ped, option); }
	static void SET_PED_FLEEZONE_REMOVE_BOX(Ped ped, const char* name) { NativeInvoke::Invoke<void>(0x17ED932A, ped, name); }
	static void SET_PED_FLEE_ATTRIBUTES(Ped ped, int32_t attributes, bool enabled) { NativeInvoke::Invoke<void>(0xA717A875, ped, attributes, enabled); }
	static void SET_PED_FORCED_TO_RUN(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xDA7588A3, ped, toggle); }
	static void SET_PED_FORCED_TO_WALK(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xA3D46847, ped, toggle); }
	static void SET_PED_FORCE_FIRE(Ped ped) { NativeInvoke::Invoke<void>(0x7FD3A5E9, ped); }
	static void SET_PED_FORCE_KNEEL_AND_FIRE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xDF8ACDEE, ped, toggle); }
	static void SET_PED_FORCE_START_FIRING_FROM_COVER(Any p0) { NativeInvoke::Invoke<void>(0xF8064C9C, p0); }
	static void SET_PED_FORCE_STOP_FIRING_FROM_COVER(Any p0) { NativeInvoke::Invoke<void>(0x26B05910, p0); }
	static void SET_PED_FORCE_USE_RAGDOLL(Ped ped, bool p1, bool p2) { NativeInvoke::Invoke<void>(0x9960303A, ped, p1, p2); }
	static void SET_PED_FREEZE_ORIENTATION(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x72F54163, ped, toggle); }
	static void SET_PED_FREEZE_PROCESSING(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x390BF58B, ped, toggle); }
	static void SET_PED_GADGET(Ped ped, uint32_t gadgetHash, bool p2) { NativeInvoke::Invoke<void>(0x8A256D0A, ped, gadgetHash, p2); }
	static void SET_PED_GENERATES_DEAD_BODY_EVENTS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xE9B97A2B, ped, toggle); }
	static void SET_PED_GESTURE_GROUP(Ped ped, const char* name) { NativeInvoke::Invoke<void>(0x170DA109, ped, name); }
	static void SET_PED_GET_OUT_UPSIDE_DOWN_VEHICLE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x89AD49FF, ped, toggle); }
	static void SET_PED_GIVE_POST_LMS_BREAK(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x2C7E761A, ped, toggle); }
	static void SET_PED_GLOBAL_KNEELING_ALLOWED(bool toggle) { NativeInvoke::Invoke<void>(0x954A05B9, toggle); }
	static void SET_PED_GLOBAL_PERCENT_DODGE_CHANCE(int32_t chance) { NativeInvoke::Invoke<void>(0xE4641DD3, chance); }
	static void SET_PED_GORE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xDA25E662, ped, toggle); }
	static void SET_PED_GORE_AS_ALLY(Ped ped) { NativeInvoke::Invoke<void>(0x5A64FA8B, ped); }
	static void SET_PED_GORE_AS_DEFAULT(Ped ped) { NativeInvoke::Invoke<void>(0xCBFA79EA, ped); }
	static void SET_PED_GORE_FROM_NPC(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x6CBAB679, ped, toggle); }
	static void SET_PED_GORE_FROM_PLAYER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x25A69B70, ped, toggle); }
	static void SET_PED_GRAVITY(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x3CA16652, ped, toggle); }
	static void SET_PED_GROUP_MEMBER_PASSENGER_INDEX(Ped ped, int32_t index) { NativeInvoke::Invoke<void>(0x2AB3670B, ped, index); }
	static void SET_PED_HAS_SPECIAL_GUN_SOUND(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x24A0BE24, ped, toggle); }
	static void SET_PED_HEADING(Ped ped, float heading) { NativeInvoke::Invoke<void>(0xE9288F19, ped, heading); }
	static void SET_PED_HEALTH(Ped ped, int32_t health, bool unk) { NativeInvoke::Invoke<void>(0xA325D05, ped, health, unk); }
	static void SET_PED_HEALTH_AS_BOOST(Ped ped, int32_t health, bool p2) { NativeInvoke::Invoke<void>(0xDE3B8D3B, ped, health, p2); }
	static void SET_PED_HEARING_RANGE(Ped ped, float range) { NativeInvoke::Invoke<void>(0xB32087E0, ped, range); }
	static void SET_PED_HEEDS_THE_EVERYONE_IGNORE_PLAYER_FLAG(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x31A06AF4, ped, toggle); }
	static void SET_PED_HELMET(Ped ped, bool canWearHelmet) { NativeInvoke::Invoke<void>(0xED366E53, ped, canWearHelmet); }
	static void SET_PED_ID_RANGE(Ped ped, float range) { NativeInvoke::Invoke<void>(0xEF3B4ED9, ped, range); }
	static void SET_PED_IGNORE_LOS_CHECKS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x07FED1F, ped, toggle); }
	static void SET_PED_INTO_VEHICLE(Ped ped, Vehicle vehicle, int32_t seatIndex) { NativeInvoke::Invoke<void>(0x7500C79, ped, vehicle, seatIndex); }
	static void SET_PED_INVINCIBLE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x1FC771E2, ped, toggle); }
	static void SET_PED_IN_CUTSCENE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x96937FF3, ped, toggle); }
	static void SET_PED_IS_HUMAN_SHIELD(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x697C85BD, ped, toggle); }
	static void SET_PED_IS_TARGET_PRIORITY(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xBA055544, ped, toggle); }
	static void SET_PED_KEEP_TASK(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xA7EC79CE, ped, toggle); }
	static void SET_PED_LEG_IK_MODE(Ped ped, int32_t mode) { NativeInvoke::Invoke<void>(0xFDDB042E, ped, mode); }
	static void SET_PED_LOD_THRESHOLD(Ped ped, float threshold) { NativeInvoke::Invoke<void>(0xEB6AC9D5, ped, threshold); }
	static void SET_PED_MAX_COVER_SEARCH_RADIUS(Ped ped, float radius) { NativeInvoke::Invoke<void>(0x69B6D9F0, ped, radius); }
	static void SET_PED_MAX_HEALTH(Ped ped, int32_t health) { NativeInvoke::Invoke<void>(0x5533F60B, ped, health); }
	static void SET_PED_MAX_TIME_IN_WATER(Ped ped, float time) { NativeInvoke::Invoke<void>(0xFE0A106B, ped, time); }
	static void SET_PED_MAX_TIME_UNDERWATER(Ped ped, float time) { NativeInvoke::Invoke<void>(0x82EF240, ped, time); }
	static void SET_PED_MELEE_ACTION_FLAG0(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x358850B0, ped, toggle); }
	static void SET_PED_MELEE_ACTION_FLAG1(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xEB55BC44, ped, toggle); }
	static void SET_PED_MELEE_MOVEMENT_CONSTRAINT_BOX(Ped ped, float x1, float y1, float z1, float x2, float y2, float z2) { NativeInvoke::Invoke<void>(0x3D3C9BB7, ped, x1, y1, z1, x2, y2, z2); }
	static void SET_PED_MELEE_TRIGGER_DIST_OVERRIDE(Any p0, Any p1) { NativeInvoke::Invoke<void>(0xA7222120, p0, p1); }
	static void SET_PED_MODEL_IS_SUPPRESSED(uint32_t modelHash, bool toggle) { NativeInvoke::Invoke<void>(0x7820CA43, modelHash, toggle); }
	static void SET_PED_MODEL_LOD_DISTANCES(uint32_t modelHash, float min, float max) { NativeInvoke::Invoke<void>(0x33659A97, modelHash, min, max); }
	static void SET_PED_MOVE_ANIMS_BLEND_OUT(Ped ped) { NativeInvoke::Invoke<void>(0x20E01957, ped); }
	static void SET_PED_NAME_DEBUG(Ped ped, const char* name) { NativeInvoke::Invoke<void>(0x20D6273E, ped, name); }
	static void SET_PED_NEVER_LEAVES_GROUP(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xE038813, ped, toggle); }
	static void SET_PED_NM_ANIM_POSE(Ped ped, const char* clipDictName, const char* animName, float p3) { NativeInvoke::Invoke<void>(0x2771F8D3, ped, clipDictName, animName, p3); }
	static void SET_PED_NON_CREATION_AREA(float x1, float y1, float z1, float x2, float y2, float z2) { NativeInvoke::Invoke<void>(0x7A97283F, x1, y1, z1, x2, y2, z2); }
	static void SET_PED_NON_REMOVAL_AREA(float x1, float y1, float z1, float x2, float y2, float z2) { NativeInvoke::Invoke<void>(0x599D82E7, x1, y1, z1, x2, y2, z2); }
	static void SET_PED_NO_RAGDOLL_TO_BULLET_UNLESS_DEAD(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xCEEE9EFE, ped, toggle); }
	static void SET_PED_NO_RAGDOLL_TO_EXPLOSION_UNLESS_DEAD(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x49CCB497, ped, toggle); }
	static void SET_PED_NUM_ADVANCERS_OVERRIDE(Any p0, Any p1) { NativeInvoke::Invoke<void>(0xB194E66C, p0, p1); }
	static void SET_PED_NUM_CHARGERS_OVERRIDE(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x1A7D00D1, p0, p1); }
	static void SET_PED_OBLIVIOUS_TO_DANGER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xCD1828FE, ped, toggle); }
	static void SET_PED_ONLY_COLLIDE_WITH_RAGDOLL_BOUNDS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x2B87EED7, ped, toggle); }
	static void SET_PED_ONLY_DAMAGED_BY_PLAYER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x785992AF, ped, toggle); }
	static void SET_PED_ONLY_DAMAGED_BY_RELATIONSHIP_GROUP(Ped ped, bool toggle, int32_t relGroupId) { NativeInvoke::Invoke<void>(0x7CC6EF33, ped, toggle, relGroupId); }
	static void SET_PED_OUT_OF_VEHICLE(Ped ped) { NativeInvoke::Invoke<void>(0x22AE6723, ped); }
	static void SET_PED_PANIC_RANGE_OVERRIDE(Ped ped, float range) { NativeInvoke::Invoke<void>(0xB83B634D, ped, range); }
	static void SET_PED_PATHS_BACK_TO_ORIGINAL(float x1, float y1, float z1, float x2, float y2, float z2) { NativeInvoke::Invoke<void>(0x3F1ABDA4, x1, y1, z1, x2, y2, z2); }
	static void SET_PED_PATHS_IN_AREA(float x1, float y1, float z1, float x2, float y2, float z2, bool missionFlag) { NativeInvoke::Invoke<void>(0x2148EA84, x1, y1, z1, x2, y2, z2, missionFlag); }
	static void SET_PED_PATH_CAN_Avoid_DYNAMIC_OBJECTS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x57A414E5, ped, toggle); }
	static void SET_PED_PATH_CAN_Avoid_LINE_OF_FIRE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x626D65F6, ped, toggle); }
	static void SET_PED_PATH_CAN_DROP_FROM_HEIGHT(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x394B7AC9, ped, toggle); }
	static void SET_PED_PATH_CAN_ENTER_WATER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xC61CA38D, ped, toggle); }
	static void SET_PED_PATH_CAN_OPEN_CLOSED_DOORS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x7C0C0376, ped, toggle); }
	static void SET_PED_PATH_CAN_USE_CLIMBOVERS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xB7B7D442, ped, toggle); }
	static void SET_PED_PATH_CAN_USE_LADDERS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x53A879EE, ped, toggle); }
	static void SET_PED_PATH_VAULTING_USAGE(Ped ped, int32_t p1, int32_t p2, int32_t p3) { NativeInvoke::Invoke<void>(0x1E7312D0, ped, p1, p2, p3); }
	static void SET_PED_PERFECT_ACCURACY_OVERRIDE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x136BA027, ped, toggle); }
	static void SET_PED_PLAYS_HEAD_ON_HORN_ANIM_WHEN_DIES_IN_VEHICLE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x7C563CD2, ped, toggle); }
	static void SET_PED_PRIMARY_LOOKAT(Ped ped, Ped lookat) { NativeInvoke::Invoke<void>(0x6DEF6F1C, ped, lookat); }
	static void SET_PED_PROJECTILE_OVERRIDE_PARAMETERS(Ped ped, bool p1, float p2, float p3, bool p4, bool p5) { NativeInvoke::Invoke<void>(0x708DE568, ped, p1, p2, p3, p4, p5); }
	static void SET_PED_PROOFS(Ped ped, bool p1, bool p2, bool p3, bool p4, bool p5) { NativeInvoke::Invoke<void>(0x94E8BC4, ped, p1, p2, p3, p4, p5); }
	static void SET_PED_PROP_INDEX(Ped ped, int32_t componentId, int32_t drawableId, int32_t textureId, int32_t unk) { NativeInvoke::Invoke<void>(0x829F2E2, ped, componentId, drawableId, textureId, unk); }
	static void SET_PED_PTFX_SPLASH_OUT_SPECIAL_EFFECT(bool toggle) { NativeInvoke::Invoke<void>(0xDE3F2565, toggle); }
	static void SET_PED_RANDOM_COMPONENT_VARIATION(Ped ped) { NativeInvoke::Invoke<void>(0x4111BA46, ped); }
	static void SET_PED_REACT_TO_CAR_COLLISION(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x6B4C2CC6, p0, p1); }
	static void SET_PED_READY_TO_BE_EXECUTED(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x4D19C95B, ped, toggle); }
	static void SET_PED_READY_TO_BE_STUNNED(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xC6787268, ped, toggle); }
	static void SET_PED_RECORDING_PLAYBACK_SPEED(Ped ped, float speed) { NativeInvoke::Invoke<void>(0x74C0A42E, ped, speed); }
	static void SET_PED_REDUCED_DAMAGE_IK(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x23754843, ped, toggle); }
	static void SET_PED_RELATIONSHIP(Ped ped, int32_t relGroupId, int32_t flags) { NativeInvoke::Invoke<void>(0x3326679D, ped, relGroupId, flags); }
	static void SET_PED_RELATIONSHIP_GROUP(Ped ped, int32_t relGroupIndex) { NativeInvoke::Invoke<void>(0x859990D1, ped, relGroupIndex); }
	static void SET_PED_REQUIRE_HEADSHOT_TO_KILL(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x12085B68, ped, toggle); }
	static void SET_PED_RESIST_TO_OBJECT_COLLISION(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x2720C246, ped, toggle); }
	static void SET_PED_ROTATION(Ped ped, float pitch, float roll, float yaw) { NativeInvoke::Invoke<void>(0xE0C7B6BB, ped, pitch, roll, yaw); }
	static void SET_PED_SECONDARY_LOOKAT(Ped ped, Ped lookat) { NativeInvoke::Invoke<void>(0x9B700AE, ped, lookat); }
	static void SET_PED_SEEING_RANGE(Ped ped, float range, int32_t p2) { NativeInvoke::Invoke<void>(0x4BD72FE8, ped, range, p2); }
	static void SET_PED_SENSE_RANGE(Ped ped, float range) { NativeInvoke::Invoke<void>(0x7AC6C04A, ped, range); }
	static void SET_PED_SHOOTS_AT_COORD(Ped ped, float x, float y, float z) { NativeInvoke::Invoke<void>(0xFD64EAE5, ped, x, y, z); }
	static void SET_PED_SHOOT_RATE(Ped ped, int32_t shootRate) { NativeInvoke::Invoke<void>(0xFB301746, ped, shootRate); }
	static void SET_PED_SILHOUETTE_COLOUR(Ped ped, int32_t color) { NativeInvoke::Invoke<void>(0x97F0EE26, ped, color); }
	static void SET_PED_SILHOUETTE_ENABLED(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x56FB3FFD, ped, toggle); }
	static void SET_PED_SILHOUETTE_WHENVISIBLE_ENABLED(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x3429857E, ped, toggle); }
	static void SET_PED_SIT_IDLE_ANIM(Ped ped, const char* animDict, const char* animName, bool p3) { NativeInvoke::Invoke<void>(0x1F0EFD92, ped, animDict, animName, p3); }
	static void SET_PED_SPHERE_DEFENSIVE_AREA(Ped ped, float x, float y, float z, float radius) { NativeInvoke::Invoke<void>(0xBD96D8E8, ped, x, y, z, radius); }
	static void SET_PED_STAND_GROUND_ON_PLAYER_IMPACT(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x9660FB67, p0, p1); }
	static void SET_PED_START_SUPPRESSIVE_FIRE(Ped ped, float p1, float p2, float p3, float p4) { NativeInvoke::Invoke<void>(0xE96A849D, ped, p1, p2, p3, p4); }
	static void SET_PED_STAY_IN_VEHICLE_WHEN_JACKED(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xB014A09C, ped, toggle); }
	static void SET_PED_STEALTH_MOVEMENT(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x67E28E1D, ped, toggle); }
	static void SET_PED_STEERS_AROUND_OBJECTS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x3BD9B0A6, ped, toggle); }
	static void SET_PED_STEERS_AROUND_PEDS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x797CAE4F, ped, toggle); }
	static void SET_PED_STOP_SUPPRESSIVE_FIRE(Ped ped) { NativeInvoke::Invoke<void>(0x601F77B7, ped); }
	static void SET_PED_SUFFERS_CRITICAL_HITS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x6F6FC7E6, ped, toggle); }
	static void SET_PED_SUGGESTED_COMBAT_AREA_ADD_BOX(Ped ped, const char* name) { NativeInvoke::Invoke<void>(0x4A92C506, ped, name); }
	static void SET_PED_SUGGESTED_COMBAT_AREA_REMOVE_BOX(Ped ped, const char* name) { NativeInvoke::Invoke<void>(0xF2C00944, ped, name); }
	static void SET_PED_SUGGESTED_COMBAT_AREA_STEP(Ped ped, float value) { NativeInvoke::Invoke<void>(0xD4781ED2, ped, value); }
	static void SET_PED_SUGGESTED_COVER_POINT(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0x198A63E4, p0, p1, p2); }
	static void SET_PED_SUPERLOD_THRESHOLD(Ped ped, float threshold) { NativeInvoke::Invoke<void>(0x666EC267, ped, threshold); }
	static void SET_PED_SWEAT(Ped ped, float sweat, float unused) { NativeInvoke::Invoke<void>(0x76A1DB9F, ped, sweat, unused); }
	static void SET_PED_SYNC_POINT(Ped ped, float x, float y, float z, float heading) { NativeInvoke::Invoke<void>(0x495AD422, ped, x, y, z, heading); }
	static void SET_PED_TETHERING_ADD_BOX(Ped ped, const char* name) { NativeInvoke::Invoke<void>(0xE697ED0, ped, name); }
	static void SET_PED_TETHERING_OPTION(Ped ped, int32_t option) { NativeInvoke::Invoke<void>(0x2FE1B82A, ped, option); }
	static void SET_PED_TETHERING_REMOVE_BOX(Ped ped, const char* name) { NativeInvoke::Invoke<void>(0x13DAB679, ped, name); }
	static void SET_PED_TO_ANIMATED(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x48ED4F81, ped, toggle); }
	static void SET_PED_TO_INFORM_RESPECTED_FRIENDS(Ped ped, float radius, int32_t maxFriends) { NativeInvoke::Invoke<void>(0xD78AC46C, ped, radius, maxFriends); }
	static void SET_PED_TO_LOAD_COVER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xCF94BA97, ped, toggle); }
	static void SET_PED_USES_ANIMATED_DEATH(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x7F575B71, ped, toggle); }
	static void SET_PED_USES_DEAFULT_ANIM_GROUP_WHEN_FLEEING(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xF604C9E2, ped, toggle); }
	static void SET_PED_USES_DYING_ANIM(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x4F0D8111, ped, toggle); }
	static void SET_PED_VALIDATE_BULLET_CAM_HIT(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xFBB7E5C8, ped, toggle); }
	static void SET_PED_VELOCITY(Ped ped, float x, float y, float z) { NativeInvoke::Invoke<void>(0xD34337FB, ped, x, y, z); }
	static void SET_PED_VISIBLE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xD599744F, ped, toggle); }
	static void SET_PED_VISIBLE_DURING_SEQUENCE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xA76C4A14, ped, toggle); }
	static void SET_PED_VOICE_FULL(Ped ped) { NativeInvoke::Invoke<void>(0x7A7C24DD, ped); } 
	static void SET_PED_WANTED_BY_POLICE(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xB255B830, ped, toggle); }
	static void SET_PED_WEAPON_BLOCK_CHECK(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x6519D09, ped, toggle); }
	static void SET_PED_WEAPON_OBSTRUCTION_CHECK_DISTANCE(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x6F1AC8DC, p0, p1); }
	static void SET_PED_WETNESS(Ped ped, float wetness, float wetHeight) { NativeInvoke::Invoke<void>(0x836E9462, ped, wetness, wetHeight); }
	static void SET_PED_WILL_ONLY_ATTACK_WANTED_PLAYER(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xF4C0C377, ped, toggle); }
	static void SET_PED_WITH_BRAIN_CAN_BE_CONVERTED_TO_DUMMY_PED(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x71060A53, ped, toggle); }
	static void SET_PERSISTENT_PED_VARIATION(Ped ped, const char* name) { NativeInvoke::Invoke<void>(0x3DDDB088, ped, name); }
	static void SET_PERSISTENT_PED_VARIATION_ENUM(Ped ped, uint32_t hash) { NativeInvoke::Invoke<void>(0x20485584, ped, hash); }
	static void SET_PERSISTENT_STREAM_PED_VARIATION(Ped ped, const char* name) { NativeInvoke::Invoke<void>(0x4206DB40, ped, name); }
	static void SET_PERSISTENT_STREAM_PED_VARIATION_ENUM(Ped ped, uint32_t hash) { NativeInvoke::Invoke<void>(0x91B49B0B, ped, hash); }
	static void SET_PETROLTANK_BURN_RATE(Vehicle vehicle, float rate) { NativeInvoke::Invoke<void>(0xC06ADE7A, vehicle, rate); }
	static void SET_PICKUP_AMMO(Any p0, Any p1) { NativeInvoke::Invoke<void>(0xCCA72391, p0, p1); }
	static void SET_PICKUP_BLIP_COLOUR(int32_t color) { NativeInvoke::Invoke<void>(0x8E3E6E45, color); }
	static void SET_PICKUP_BLIP_DISPLAY(int32_t display) { NativeInvoke::Invoke<void>(0xC7410B80, display); }
	static void SET_PICKUP_BLIP_PRIORITY(int32_t priority) { NativeInvoke::Invoke<void>(0x7E7DA662, priority); }
	static void SET_PICKUP_BLIP_SCALE(float scale) { NativeInvoke::Invoke<void>(0xD6A4F36B, scale); }
	static void SET_PICKUP_BLIP_SPRITE(int32_t sprite) { NativeInvoke::Invoke<void>(0xEE28B6FE, sprite); }
	static void SET_PICKUP_REMOVAL_TIMES(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x172FA186, p0, p1); }
	static void SET_PICKUP_WEAPON_DATA_FROM_WEAPON(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x0D3791A, p0, p1); }
	static void SET_PLACEMENT_CAN_BE_COLLECTED(int32_t index, bool toggle) { NativeInvoke::Invoke<void>(0x9AB53495, index, toggle); }
	static void SET_PLAYBACK_SPEED(Vehicle vehicle, float speed) { NativeInvoke::Invoke<void>(0x684E26E4, vehicle, speed); }
	static void SET_PLAYBACK_TO_USE_AI(Vehicle vehicle) { NativeInvoke::Invoke<void>(0xB536CCD7, vehicle); }
	static void SET_PLAYBACK_TO_USE_AI_TRY_TO_REVERT_BACK_LATER(Vehicle vehicle, int32_t p1) { NativeInvoke::Invoke<void>(0xC8ABAA4, vehicle, p1); }
	static void SET_PLAYERPAD_SHAKES_WHEN_CONTROLLER_DISABLED(bool toggle) { NativeInvoke::Invoke<void>(0xA86BD91F, toggle); }
	static void SET_PLAYER_ALT_HEALTH(float health) { NativeInvoke::Invoke<void>(0x4DB0855A, health); }
	static void SET_PLAYER_ALT_MAX_HEALTH(float health) { NativeInvoke::Invoke<void>(0x638660F0, health); }
	static void SET_PLAYER_CACHED_CAMERA_ORIENTATION(float orientation) { NativeInvoke::Invoke<void>(0x4B35E639, orientation); }
	static void SET_PLAYER_CAN_ACTIVATE_BULLET_TIME(Player player, bool toggle) { NativeInvoke::Invoke<void>(0xECD0EB64, player, toggle); }
	static void SET_PLAYER_CAN_BE_HASSLED_BY_GANGS(Player player, Object object) { NativeInvoke::Invoke<void>(0x71B305BB, player, object); }
	static void SET_PLAYER_CAN_BE_PINNED_IN_COVER(Player player, bool toggle) { NativeInvoke::Invoke<void>(0x2343733, player, toggle); }
	static void SET_PLAYER_CAN_CANCEL_SHOOTDODGE(bool toggle) { NativeInvoke::Invoke<void>(0x8FD7169A, toggle); }
	static void SET_PLAYER_CAN_CARRY_NON_MISSION_OBJECTS(Player player) { NativeInvoke::Invoke<void>(0x54B0C19B, player); }
	static void SET_PLAYER_CAN_DO_DRIVE_BY(Player player, Object object) { NativeInvoke::Invoke<void>(0xF4D99685, player, object); }
	static void SET_PLAYER_CAN_USE_COVER(Player player, bool toggle) { NativeInvoke::Invoke<void>(0x13CAFAFA, player, toggle); }
	static void SET_PLAYER_CAN_USE_FREEFORM_STRIKE(bool toggle) { NativeInvoke::Invoke<void>(0x21FC90F7, toggle); }
	static void SET_PLAYER_CAN_USE_SHOOTDODGE(Player player, bool toggle) { NativeInvoke::Invoke<void>(0x880FAED5, player, toggle); }
	static void SET_PLAYER_COLOUR(Player player, int32_t color) { NativeInvoke::Invoke<void>(0x24750296, player, color); }
	static void SET_PLAYER_COMBAT_TIMER_MODE(int32_t mode) { NativeInvoke::Invoke<void>(0x5E348DA2, mode); }
	static void SET_PLAYER_CONTROL(Player player, bool toggle, int32_t flags) { NativeInvoke::Invoke<void>(0xD17AFCD8, player, toggle, flags); }
	static void SET_PLAYER_CONTROL_FOR_NETWORK(Player player, bool toggle, bool p2) { NativeInvoke::Invoke<void>(0x4E33A0A, player, toggle, p2); }
	static void SET_PLAYER_CONTROL_ON_IN_MISSION_CLEANUP(bool toggle) { NativeInvoke::Invoke<void>(0xE886E2C5, toggle); }
	static void SET_PLAYER_FORCED_AIM(Any playerOrPed, bool p1, bool p2) { NativeInvoke::Invoke<void>(0x94E42E2E, playerOrPed, p1, p2); }
	static void SET_PLAYER_FORCED_AIM_MAINTAIN_DIRECTION(Any playerOrPed, bool p1, bool p2) { NativeInvoke::Invoke<void>(0xFE1EC142, playerOrPed, p1, p2); }
	static void SET_PLAYER_FORCE_PAIN_KILLER(bool toggle) { NativeInvoke::Invoke<void>(0x49F9AB61, toggle); }
	static void SET_PLAYER_GLOBAL_COMBAT_TIMER_STATE(bool state) { NativeInvoke::Invoke<void>(0xC02C4FE7, state); }
	static void SET_PLAYER_HEALTH_REGENERATION(bool toggle) { NativeInvoke::Invoke<void>(0xFB207BEA, toggle); }
	static void SET_PLAYER_HEALTH_REGENERATION_MAX(int32_t maxValue) { NativeInvoke::Invoke<void>(0xA94E6088, maxValue); }
	static void SET_PLAYER_HEALTH_REGENERATION_RATE(int32_t mpRate, int32_t spRate) { NativeInvoke::Invoke<void>(0x10182B3F, mpRate, spRate); }
	static void SET_PLAYER_ICON_COLOUR(int32_t color) { NativeInvoke::Invoke<void>(0x1630B64C, color); }
	static void SET_PLAYER_INFINTE_STAMINA(Player player, bool toggle) { NativeInvoke::Invoke<void>(0x44466C42, player, toggle); }
	static void SET_PLAYER_INVINCIBLE(Player player, bool toggle) { NativeInvoke::Invoke<void>(0xDFB9A2A2, player, toggle); }
	static void SET_PLAYER_IN_BECKER_BOSS_FIGHT(Player player, bool toggle) { NativeInvoke::Invoke<void>(0x31539EA2, player, toggle); }
	static void SET_PLAYER_KEEPS_WEAPONS_WHEN_RESPAWNED(Player player) { NativeInvoke::Invoke<void>(0xD10FC340, player); }
	static void SET_PLAYER_LOCKED_IN_COVER(Player player, bool toggle) { NativeInvoke::Invoke<void>(0xAFD8C788, player, toggle); }
	static void SET_PLAYER_LOCKON(Player player, bool toggle) { NativeInvoke::Invoke<void>(0xB270E0F, player, toggle); }
	static void SET_PLAYER_MAY_ONLY_ENTER_THIS_VEHICLE(Player player, Vehicle vehicle) { NativeInvoke::Invoke<void>(0xA454DD29, player, vehicle); }
	static void SET_PLAYER_MODEL(Player player, uint32_t modelHash) { NativeInvoke::Invoke<void>(0x774A4C54, player, modelHash); }
	static void SET_PLAYER_MOOD_NORMAL(Player player) { NativeInvoke::Invoke<void>(0xB1FF6041, player); }
	static void SET_PLAYER_MOOD_PISSED_OFF(Player player, int32_t seconds) { NativeInvoke::Invoke<void>(0x6F60E94E, player, seconds); }
	static void SET_PLAYER_OXYGEN(Player player, int32_t oxygen) { NativeInvoke::Invoke<void>(0x1B92B5E5, player, oxygen); }
	static void SET_PLAYER_PLAYER_TARGETTING(bool toggle) { NativeInvoke::Invoke<void>(0xF12A7F7D, toggle); }
	static void SET_PLAYER_POINTS(int32_t value) { NativeInvoke::Invoke<void>(0xAE5A0494, value); }
	static void SET_PLAYER_SAFE_FOR_CUTSCENE(Player player) { NativeInvoke::Invoke<void>(0x7EBFBB34, player); }
	static void SET_PLAYER_SHOOTDODGE_GET_UP_STATE(int32_t state) { NativeInvoke::Invoke<void>(0x5EDA74EA, state); }
	static void SET_PLAYER_SPRINT(Player player, bool toggle) { NativeInvoke::Invoke<void>(0x7DD7900C, player, toggle); }
	static void SET_PLAYER_SPRINT_SP(Player player, bool toggle) { NativeInvoke::Invoke<void>(0x92282FE2, player, toggle); }
	static void SET_PLAYER_TEAM(Player player, int32_t team) { NativeInvoke::Invoke<void>(0x725ADCF2, player, team); }
	static void SET_PLAYER_THREAT_REACTION(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xE050BAC4, ped, toggle); }
	static void SET_PLAYER_USING_COVER(Player player, bool toggle) { NativeInvoke::Invoke<void>(0x67A896B3, player, toggle); }
	static void SET_PLAYER_WANTED_LEVEL(Player player, int32_t wantedLevel) { NativeInvoke::Invoke<void>(0xB7A0914B, player, wantedLevel); }
	static void SET_PLAYER_WANTED_LEVEL_NOW(Player player) { NativeInvoke::Invoke<void>(0xAF3AFD83, player); }
	static void SET_PLAYER_WANTED_LEVEL_NO_DROP(Player player, int32_t wantedLevel) { NativeInvoke::Invoke<void>(0xED6F44F5, player, wantedLevel); }
	static void SET_POLICE_FOCUS_WILL_TRACK_VEHICLE(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x5690F6C3, vehicle, toggle); }
	static void SET_POLICE_IGNORE_PLAYER(bool toggle) { NativeInvoke::Invoke<void>(0xE6DE71B7, toggle); }
	static void SET_POLICE_RADAR_BLIPS(bool toggle) { NativeInvoke::Invoke<void>(0x8E114B10, toggle); }
	static void SET_PORTAL_TRACK_DEATH_CAMERA(bool toggle) { NativeInvoke::Invoke<void>(0x5B1065AF, toggle); }
	static void SET_POST_LMS_DAMAGE_TO_PLAYER_OVERRIDES(int32_t p0, float p1) { NativeInvoke::Invoke<void>(0xB9C2BFBD, p0, p1); }
	static void SET_PRE_CUTSCENE_OBJECT_NO_LONGER_NEEDED(Object* object) { NativeInvoke::Invoke<void>(0x2FB8D0E6, object); }
	static void SET_PRE_CUTSCENE_PED_NO_LONGER_NEEDED(Ped* ped) { NativeInvoke::Invoke<void>(0x54D1FACD, ped); }
	static void SET_PRE_CUTSCENE_VEHICLE_NO_LONGER_NEEDED(Vehicle* vehicle) { NativeInvoke::Invoke<void>(0x2A9FF799, vehicle); }
	static void SET_PRE_CUTSCENE_WEAPON_NO_LONGER_NEEDED(Weapon* weapon) { NativeInvoke::Invoke<void>(0x4F144C0B, weapon); }
	static void SET_PROGRESS_BAR_COLOURS(int32_t color1, int32_t color2) { NativeInvoke::Invoke<void>(0xE68944E3, color1, color2); }
	static void SET_PROGRESS_BAR_FLASH(bool toggle) { NativeInvoke::Invoke<void>(0x7CCD409B, toggle); }
	static void SET_PROGRESS_BAR_NAME(const char* name) { NativeInvoke::Invoke<void>(0x7284689, name); }
	static void SET_PROGRESS_BAR_PERCENT(float percent) { NativeInvoke::Invoke<void>(0x5D681AB9, percent); }
	static void SET_PROGRESS_BAR_POSITION(float x, float y) { NativeInvoke::Invoke<void>(0x7933FBC4, x, y); }
	static void SET_PROGRESS_BAR_START_FLASH_PERCENT(float percent) { NativeInvoke::Invoke<void>(0x29FF4235, percent); }
	static void SET_PROGRESS_BAR_VISIBLE(bool toggle) { NativeInvoke::Invoke<void>(0x7CA2A24F, toggle); }
	static void SET_PROJECTILE_THROW_USE_DAMPING_COMPENSATION(bool toggle) { NativeInvoke::Invoke<void>(0xBA40DC95, toggle); }
	static void SET_PUDDLES(float p0, float p1, float p2, float p3) { NativeInvoke::Invoke<void>(0x7B0E77C5, p0, p1, p2, p3); }
	static void SET_RADAR_AS_INTERIOR_THIS_FRAME() { NativeInvoke::Invoke<void>(0x6F2626E1); }
	static void SET_RADAR_ZOOM(int32_t zoomLevel) { NativeInvoke::Invoke<void>(0x2A50D1A6, zoomLevel); }
	static void SET_RAIL_RELATIVE_DIR(int32_t index, float dir) { NativeInvoke::Invoke<void>(0x69B9D3A5, index, dir); }
	static void SET_RANDOM_BOATS(bool toggle) { NativeInvoke::Invoke<void>(0xB505BD89, toggle); }
	static void SET_RANDOM_SEED(int32_t seed) { NativeInvoke::Invoke<void>(0xDB3FEB5C, seed); }
	static void SET_RANDOM_TRAINS(bool toggle) { NativeInvoke::Invoke<void>(0xD461CA7F, toggle); }
	static void SET_RANDOM_VEHICLE_DENSITY_MULTIPLIER(float multiplier) { NativeInvoke::Invoke<void>(0x876A0BCE, multiplier); }
	static void SET_RANDOM_WEATHER_TYPE() { NativeInvoke::Invoke<void>(0xE7AA1BC9); }
	static void SET_REDUCE_PED_MODEL_BUDGET(bool toggle) { NativeInvoke::Invoke<void>(0xAFCB2B86, toggle); }
	static void SET_REDUCE_VEHICLE_MODEL_BUDGET(bool toggle) { NativeInvoke::Invoke<void>(0xCDB4FB7E, toggle); }
	static void SET_RELATIONSHIP_BETWEEN_REL_GROUPS(int32_t relGroupId1, int32_t relGroupId2, int32_t flags) { NativeInvoke::Invoke<void>(0xDB37D46E, relGroupId1, relGroupId2, flags); }
	static void SET_RENDER_TRAIN_AS_DERAILED(Vehicle train, bool toggle) { NativeInvoke::Invoke<void>(0x899D9092, train, toggle); }
	static void SET_RICH_PRESENCE(Any* p0) { NativeInvoke::Invoke<void>(0x7BDCBD45, p0); }
	static void SET_RIGHT_TRIGGER_HOLD_TIME(int32_t time) { NativeInvoke::Invoke<void>(0xBD1F617, time); }
	static void SET_RINGICON_OBJECT(Object object, Any* ringicon) { NativeInvoke::Invoke<void>(0x8B6F801B, object, ringicon); }
	static void SET_RINGICON_OBJECT_PERCENT(Object object, float percent) { NativeInvoke::Invoke<void>(0x616D7ACC, object, percent); }
	static void SET_RINGICON_PLAYER(Player player, Any* ringicon) { NativeInvoke::Invoke<void>(0x9506F619, player, ringicon); }
	static void SET_RINGICON_PLAYER_PERCENT(Player player, float percent) { NativeInvoke::Invoke<void>(0x473ADD6D, player, percent); }
	static void SET_RINGICON_WORLD(float x, float y, float z, Any* ringicon) { NativeInvoke::Invoke<void>(0x32BE24DE, x, y, z, ringicon); }
	static void SET_RINGICON_WORLD_PERCENT(float x, float y, float z, float percent) { NativeInvoke::Invoke<void>(0x5BF34139, x, y, z, percent); }
	static void SET_ROADS_BACK_TO_ORIGINAL(float x1, float y1, float z1, float x2, float y2, float z2) { NativeInvoke::Invoke<void>(0x86AC4A85, x1, y1, z1, x2, y2, z2); }
	static void SET_ROADS_IN_AREA(float x1, float y1, float z1, float x2, float y2, float z2, bool missionFlag) { NativeInvoke::Invoke<void>(0xEBC7B918, x1, y1, z1, x2, y2, z2, missionFlag); }
	static void SET_ROOM_FOR_OBJECTS_IN_IPL(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0x2BE9CC9D, p0, p1, p2); }
	static void SET_ROOM_FOR_PED_BY_KEY(Ped ped, uint32_t hash) { NativeInvoke::Invoke<void>(0x41FC2A85, ped, hash); }
	static void SET_ROOM_FOR_PED_BY_NAME(Ped ped, const char* name) { NativeInvoke::Invoke<void>(0xD363B660, ped, name); }
	static void SET_ROOM_FOR_VEHICLE_BY_KEY(Vehicle vehicle, const char* name) { NativeInvoke::Invoke<void>(0x83AFEA05, vehicle, name); }
	static void SET_ROOM_FOR_VEHICLE_BY_NAME(Vehicle vehicle, const char* name) { NativeInvoke::Invoke<void>(0xCC9D85E7, vehicle, name); }
	static void SET_SAFE_TO_KILL_PLAYER(bool toggle) { NativeInvoke::Invoke<void>(0x1328332A, toggle); }
	static void SET_SCENARIO_PEDS_SPAWN_IN_SPHERE_AREA(float x, float y, float z, float radius, int32_t p4) { NativeInvoke::Invoke<void>(0x80EAD297, x, y, z, radius, p4); }
	static void SET_SCENARIO_PEDS_TO_BE_RETURNED_BY_NEXT_COMMAND(bool toggle) { NativeInvoke::Invoke<void>(0x85615FD0, toggle); }
	static void SET_SCENARIO_PED_DENSITY_MULTIPLIER(float p0, float p1) { NativeInvoke::Invoke<void>(0x874B05BE, p0, p1); }
	static void SET_SCENE_STREAMING(bool toggle) { NativeInvoke::Invoke<void>(0xC988470E, toggle); }
	static void SET_SCRIPTED_ANIM_SEAT_OFFSET(Ped ped, float offset) { NativeInvoke::Invoke<void>(0x7CEFFA45, ped, offset); }
	static void SET_SCRIPTED_CONVERSION_COORD(float x, float y, float z) { NativeInvoke::Invoke<void>(0x4A97C006, x, y, z); }
	static void SET_SCRIPT_AS_NO_LONGER_NEEDED(const char* name) { NativeInvoke::Invoke<void>(0x6FCB7795, name); }
	static void SET_SCRIPT_CONTROL_RESET_ON_PLAYER_DEATH(bool toggle) { NativeInvoke::Invoke<void>(0x107EA41E, toggle); }
	static void SET_SCRIPT_RENDERTARGET_SIZE_ID(int32_t p0, int32_t p1, int32_t p2) { NativeInvoke::Invoke<void>(0x5155F6F8, p0, p1, p2); }
	static void SET_SCRIPT_SHOULD_BE_SAVED() { NativeInvoke::Invoke<void>(0xC109699A); }
	static void SET_SCRIPT_VEHICLE_GENERATOR(int32_t scriptVehicleGenerator, int32_t p1) { NativeInvoke::Invoke<void>(0x40D73747, scriptVehicleGenerator, p1); }
	static void SET_SEAMLESS_CUTSCENE_COORDS(float x, float y, float z) { NativeInvoke::Invoke<void>(0xB7A469ED, x, y, z); }
	static void SET_SEAMLESS_CUTSCENE_TRIGGER_AREA(float x1, float y1, float z1, float x2, float y2, float z2) { NativeInvoke::Invoke<void>(0x96FF2315, x1, y1, z1, x2, y2, z2); }
	static void SET_SECONDARY_LIFE_BACKGROUND_COLOR(int32_t color) { NativeInvoke::Invoke<void>(0xC509E8EA, color); }
	static void SET_SECONDARY_LIFE_BACKGROUND_COLOR32(int32_t r, int32_t g, int32_t b) { NativeInvoke::Invoke<void>(0xE6330B74, r, g, b); }
	static void SET_SECONDARY_LIFE_BAR_ALPHA(int32_t alpha) { NativeInvoke::Invoke<void>(0xB0139147, alpha); }
	static void SET_SECONDARY_LIFE_BAR_COLOR(int32_t color) { NativeInvoke::Invoke<void>(0xBBB82D30, color); }
	static void SET_SECONDARY_LIFE_BAR_COLOR32(int32_t r, int32_t g, int32_t b) { NativeInvoke::Invoke<void>(0x502ECD4B, r, g, b); }
	static void SET_SECONDARY_LIFE_BAR_NAME(const char* name) { NativeInvoke::Invoke<void>(0x6CB9CEA9, name); }
	static void SET_SECONDARY_LIFE_BAR_PERCENT(float percent) { NativeInvoke::Invoke<void>(0x78474550, percent); }
	static void SET_SECONDARY_LIFE_BAR_START_FLASH_PERCENT(float percent) { NativeInvoke::Invoke<void>(0xB8BD396B, percent); }
	static void SET_SECONDARY_LIFE_ICON(const char* iconName) { NativeInvoke::Invoke<void>(0x161011A3, iconName); }
	static void SET_SECONDARY_LIFE_ICON_COLOR(int32_t color) { NativeInvoke::Invoke<void>(0x441B42D0, color); }
	static void SET_SECONDARY_LIFE_ICON_COLOR32(int32_t r, int32_t g, int32_t b) { NativeInvoke::Invoke<void>(0x585032B9, r, g, b); }
	static void SET_SECONDARY_LIFE_SCALE(float p0, float p1) { NativeInvoke::Invoke<void>(0x5CE97A69, p0, p1); }
	static void SET_SECONDARY_LIFE_TEXT_COLOR(int32_t color) { NativeInvoke::Invoke<void>(0x8333ADD4, color); }
	static void SET_SECONDARY_LIFE_TEXT_COLOR32(int32_t r, int32_t g, int32_t b) { NativeInvoke::Invoke<void>(0xADA42319, r, g, b); }
	static void SET_SEQUENCE_TO_REPEAT(Any taskSequence, bool repeat) { NativeInvoke::Invoke<void>(0xCDDF1508, taskSequence, repeat); }
	static void SET_SHELL_LOD_DIST_ENTITY(float value) { NativeInvoke::Invoke<void>(0xCE6C2A4E, value); }
	static void SET_SHELL_LOD_DIST_MESHFX(float value) { NativeInvoke::Invoke<void>(0xA17BA731, value); }
	static void SET_SILHOUETTE_ACTIVE(bool toggle) { NativeInvoke::Invoke<void>(0xBD11E03E, toggle); }
	static void SET_SILHOUETTE_DISTANCE_FALLOFF(float minDistance, float maxDistance) { NativeInvoke::Invoke<void>(0x5D9C6169, minDistance, maxDistance); }
	static void SET_SILHOUETTE_RENDER_SETTINGS(float intensity, Any unused) { NativeInvoke::Invoke<void>(0x251A1458, intensity, unused); }
	static void SET_SINGLE_PLAYER_TITLE_SCREEN_ENTRY_HANDLED() { NativeInvoke::Invoke<void>(0x9DF58C06); }
	static void SET_SIREN_WITH_NO_DRIVER(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x77182D58, vehicle, toggle); } 
	static void SET_SLEEP_MODE_ACTIVE(bool toggle) { NativeInvoke::Invoke<void>(0x8AC848BA, toggle); }
	static void SET_SMALL_BOATS_PROPELLOR_PTFX_MAX_SPEED_EVO(bool toggle) { NativeInvoke::Invoke<void>(0xEAB22432, toggle); }
	static void SET_SMALL_BOATS_PTFX_MAX_SPEED_EVO(bool toggle) { NativeInvoke::Invoke<void>(0xCC4E37B9, toggle); }
	static void SET_SMALL_BOAT_PTFX_CUTSCENE_EFFECT(bool toggle) { NativeInvoke::Invoke<void>(0x39101C7, toggle); }
	static void SET_SMALL_BOAT_PTFX_CUTSCENE_PROPELLOR_EFFECT(bool toggle) { NativeInvoke::Invoke<void>(0x3B6463A8, toggle); }
	static void SET_SNIPER_HUD_ALPHA(int32_t alpha) { NativeInvoke::Invoke<void>(0x13A2A389, alpha); }
	static void SET_SPECIAL_MPITEM_BLIP_PARAMS(int32_t p0, int32_t p1, int32_t p2, float p3, int32_t p4, int32_t p5, int32_t p6) { NativeInvoke::Invoke<void>(0x90FD2B14, p0, p1, p2, p3, p4, p5, p6); }
	static void SET_SPRITES_DRAW_BEFORE_FADE(bool toggle) { NativeInvoke::Invoke<void>(0x275DE46E, toggle); }
	static void SET_STATE_OF_CLOSEST_DOOR_OF_TYPE(uint32_t modelHash, float x, float y, float z, bool locked, float heading) { NativeInvoke::Invoke<void>(0x38C951A4, modelHash, x, y, z, locked, heading); }
	static void SET_STATIC_EMITTER_VOLUME(const char* emitterName, float volume) { NativeInvoke::Invoke<void>(0xFDF95AA4, emitterName, volume); }
	static void SET_STREAMED_TEXTURE_DICT_AS_NO_LONGER_NEEDED(const char* dictName) { NativeInvoke::Invoke<void>(0xF07DDA38, dictName); }
	static void SET_STREAMING(bool toggle) { NativeInvoke::Invoke<void>(0x27EF6CB2, toggle); }
	static void SET_STREAMING_POINT_OF_INTEREST(float p0, float p1, float p2, bool p3, float p4) { NativeInvoke::Invoke<void>(0x27BA0211, p0, p1, p2, p3, p4); }
	static void SET_STREAM_PED_COMPONENT_VARIATION(Ped ped, int32_t componentId, int32_t drawableId, int32_t textureId, int32_t paletteId) { NativeInvoke::Invoke<void>(0x9F59036F, ped, componentId, drawableId, textureId, paletteId); }
	static void SET_STREAM_PED_COMPONENT_VARIATION_2(Ped ped, int32_t componentId, int32_t drawableId, int32_t textureId, int32_t paletteId) { NativeInvoke::Invoke<void>(0x5C75CD2D, ped, componentId, drawableId, textureId, paletteId); }
	static void SET_STREAM_PED_CUSTOMISATION_DATA(Ped ped, uint32_t hash) { NativeInvoke::Invoke<void>(0xA3E802DD, ped, hash); }
	static void SET_SUPPRESSOR_DAMAGE_LEVEL(Weapon weapon, int32_t damageLevel) { NativeInvoke::Invoke<void>(0x5F580A8A, weapon, damageLevel); }
	static void SET_SWEAT_ENABLED(bool toggle) { NativeInvoke::Invoke<void>(0x296668CC, toggle); }
	static void SET_SYNC_WEATHER_AND_GAME_TIME(bool toggle) { NativeInvoke::Invoke<void>(0xB3A07403, toggle); }
	static void SET_TAXI_LIGHTS(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x68639D85, vehicle, toggle); }
	static void SET_TEAR_GAS_EFFECT_AUTO_END(bool toggle) { NativeInvoke::Invoke<void>(0xAA1C242F, toggle); }
	static void SET_TERRITORY_BLIP_SCALE(Blip blip, float p1, float p2) { NativeInvoke::Invoke<void>(0xAB843007, blip, p1, p2); }
	static void SET_TEXT_BACKGROUND(bool toggle) { NativeInvoke::Invoke<void>(0x14ADAD25, toggle); }
	static void SET_TEXT_CENTRE(bool toggle) { NativeInvoke::Invoke<void>(0xE26D39A1, toggle); }
	static void SET_TEXT_COLOUR(int32_t r, int32_t g, int32_t b, int32_t a) { NativeInvoke::Invoke<void>(0xE54DD2C8, r, g, b, a); }
	static void SET_TEXT_DRAW_BEFORE_FADE(bool toggle) { NativeInvoke::Invoke<void>(0x1B2BA35E, toggle); }
	static void SET_TEXT_DROPSHADOW(int32_t distance, int32_t r, int32_t g, int32_t b, int32_t a) { NativeInvoke::Invoke<void>(0xE6587517, distance, r, g, b, a); }
	static void SET_TEXT_EDGE(int32_t p0, int32_t r, int32_t g, int32_t b, int32_t a) { NativeInvoke::Invoke<void>(0x3F1A5DAB, p0, r, g, b, a); }
	static void SET_TEXT_FONT(int32_t font) { NativeInvoke::Invoke<void>(0x80BC530D, font); }
	static void SET_TEXT_JUSTIFY(bool toggle) { NativeInvoke::Invoke<void>(0xBC971139, toggle); }
	static void SET_TEXT_LINE_HEIGHT_MULT(float mult) { NativeInvoke::Invoke<void>(0x2F947549, mult); }
	static void SET_TEXT_PROPORTIONAL(bool toggle) { NativeInvoke::Invoke<void>(0xF49D8A08, toggle); }
	static void SET_TEXT_RENDER_ID(int32_t renderId) { NativeInvoke::Invoke<void>(0xC5C3B7F3, renderId); }
	static void SET_TEXT_RIGHT_JUSTIFY(bool toggle) { NativeInvoke::Invoke<void>(0x45B60520, toggle); }
	static void SET_TEXT_SCALE(float p0, float p1) { NativeInvoke::Invoke<void>(0xB6E15B23, p0, p1); }
	static void SET_TEXT_TO_USE_TEXT_FILE_COLOURS(bool toggle) { NativeInvoke::Invoke<void>(0xB95E39DE, toggle); }
	static void SET_TEXT_USE_UNDERSCORE(bool toggle) { NativeInvoke::Invoke<void>(0x95CD1881, toggle); }
	static void SET_TEXT_WRAP(float start, float end) { NativeInvoke::Invoke<void>(0x6F60AB54, start, end); }
	static void SET_THIS_MACHINE_RUNNING_SERVER_SCRIPT(bool toggle) { NativeInvoke::Invoke<void>(0x1626C5C3, toggle); }
	static void SET_THIS_SCRIPT_CAN_BE_PAUSED(bool toggle) { NativeInvoke::Invoke<void>(0xA0C3CE29, toggle); }
	static void SET_THIS_SCRIPT_CAN_REMOVE_BLIPS_CREATED_BY_ANY_SCRIPT(bool toggle) { NativeInvoke::Invoke<void>(0xD06F1720, toggle); }
	static void SET_TIMECYCLE_MODIFIER(const char* modifierName) { NativeInvoke::Invoke<void>(0xA81F3638, modifierName); }
	static void SET_TIMECYCLE_MODIFIER_OVERRIDE(const char* p0, const char* p1, float p2, float p3, int32_t p4) { NativeInvoke::Invoke<void>(0xBCB2D9B5, p0, p1, p2, p3, p4); }
	static void SET_TIMEWARP_FIRE_SCALE(Ped ped, float scale) { NativeInvoke::Invoke<void>(0x68883C5E, ped, scale); }
	static void SET_TIME_CYCLE_MODIFIERS_ENABLED(bool toggle) { NativeInvoke::Invoke<void>(0xF9665C8C, toggle); }
	static void SET_TIME_OF_DAY(int32_t hour, int32_t minute) { NativeInvoke::Invoke<void>(0xAD03186C, hour, minute); }
	static void SET_TIME_ONE_DAY_BACK() { NativeInvoke::Invoke<void>(0xDB2A037); }
	static void SET_TIME_ONE_DAY_FORWARD() { NativeInvoke::Invoke<void>(0xBB56C2E5); }
	static void SET_TIME_SCALE(float scale) { NativeInvoke::Invoke<void>(0xA7F84694, scale); }
	static void SET_TOXICITY_LEVEL_TIME(float p0, float p1, float p2) { NativeInvoke::Invoke<void>(0xAA9761E, p0, p1, p2); }
	static void SET_TRAFFIC_SYSTEM(bool toggle) { NativeInvoke::Invoke<void>(0xB0ABF560, toggle); }
	static void SET_TRAIN_CRUISE_SPEED(Vehicle train, float speed) { NativeInvoke::Invoke<void>(0xB507F51D, train, speed); }
	static void SET_TRAIN_FORCED_TO_SLOW_DOWN(Vehicle train, bool toggle) { NativeInvoke::Invoke<void>(0x7C3600D4, train, toggle); }
	static void SET_TRAIN_IS_STOPPED_AT_STATION(Vehicle train) { NativeInvoke::Invoke<void>(0xE276A20D, train); }
	static void SET_TRAIN_LEAVES_STATION(Vehicle train) { NativeInvoke::Invoke<void>(0x4438873D, train); }
	static void SET_TRAIN_SHAKE(Vehicle train, float p1, float p2, bool p3) { NativeInvoke::Invoke<void>(0x1C6901B3, train, p1, p2, p3); }
	static void SET_TRAIN_SPEED(Vehicle train, float speed) { NativeInvoke::Invoke<void>(0xDFC35E4D, train, speed); }
	static void SET_TRAIN_STOPS_FOR_STATIONS(Vehicle train, bool toggle) { NativeInvoke::Invoke<void>(0x43E5F109, train, toggle); }
	static void SET_TRANSITION_MOVIE_SKIPPABLE(bool toggle) { NativeInvoke::Invoke<void>(0x4278FA3D, toggle); }
	static void SET_TUTORIAL_COMPLETE() { NativeInvoke::Invoke<void>(0x854FAB50); }
	static void SET_UNK_AUDIO_MUTE(bool toggle) { NativeInvoke::Invoke<void>(0x9F3090EF, toggle); } 
	static void SET_UNK_LOCAL_PLAYER_bool(bool toggle) { NativeInvoke::Invoke<void>(0x06D3541, toggle); }
	static void SET_UNK_TEAR_GAS_MODIFIER(float modifier) { NativeInvoke::Invoke<void>(0x46CE66CF, modifier); }
	static void SET_USES_COLLISION_OF_CLOSEST_OBJECT_OF_TYPE(float x, float y, float z, float radius, uint32_t modelHash, bool toggle) { NativeInvoke::Invoke<void>(0x88042DC7, x, y, z, radius, modelHash, toggle); }
	static void SET_USE_ANIMATED_VELOCITY(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x92FE3DB8, ped, toggle); }
	static void SET_USE_WEAPON_BOUND(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xD1827431, ped, toggle); }
	static void SET_USING_ALT_HEALTH(bool toggle) { NativeInvoke::Invoke<void>(0xB135037B, toggle); }
	static void SET_VARIABLE_ON_SOUND(int32_t soundId, const char* variableName, float value) { NativeInvoke::Invoke<void>(0x606EE5FA, soundId, variableName, value); }
	static void SET_VEHICLE_ALARM(Vehicle vehicle, bool state) { NativeInvoke::Invoke<void>(0x24877D84, vehicle, state); }
	static void SET_VEHICLE_AS_CONVOY_VEHICLE(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x2CF62ABD, vehicle, toggle); }
	static void SET_VEHICLE_AS_ENTITY_SYNC_POINT(Vehicle vehicle, Ped ped) { NativeInvoke::Invoke<void>(0xAEB6D2DE, vehicle, ped); }
	static void SET_VEHICLE_AS_MISSION_VEHICLE(Vehicle vehicle) { NativeInvoke::Invoke<void>(0x73FA1219, vehicle); }
	static void SET_VEHICLE_AS_NO_LONGER_NEEDED(Vehicle* vehicle) { NativeInvoke::Invoke<void>(0x9B0E10BE, vehicle); }
	static void SET_VEHICLE_BLIP_THROTTLE_RANDOMLY(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0xC2F6FE4A, vehicle, toggle); }
	static void SET_VEHICLE_BLOWUP_ON_NEXT_COLLISION(Vehicle vehicle) { NativeInvoke::Invoke<void>(0xAF0FD67A, vehicle); }
	static void SET_VEHICLE_BULLET_CAMERA_ON_NEXT_HIT(Vehicle vehicle) { NativeInvoke::Invoke<void>(0x7394BC1C, vehicle); }
	static void SET_VEHICLE_BULLET_CAM_PREF(Vehicle vehicle, const char* p1) { NativeInvoke::Invoke<void>(0x84DA3B85, vehicle, p1); }
	static void SET_VEHICLE_CAN_BE_DAMAGED(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x2386C5B7, vehicle, toggle); }
	static void SET_VEHICLE_CAN_BE_TARGETTED(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x64B70B1D, vehicle, toggle); }
	static void SET_VEHICLE_CAN_BE_VISIBLY_DAMAGED(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0xC5D94017, vehicle, toggle); }
	static void SET_VEHICLE_CAN_BREAK(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x90A810D1, vehicle, toggle); }
	static void SET_VEHICLE_CAN_TRIGGER_BULLET_CAM(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0xDF932BC, vehicle, toggle); }
	static void SET_VEHICLE_COLLISION(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0xC7A6A137, vehicle, toggle); }
	static void SET_VEHICLE_COLOURS(Vehicle vehicle, int32_t primaryColor, int32_t secondaryColor) { NativeInvoke::Invoke<void>(0x57F24253, vehicle, primaryColor, secondaryColor); }
	static void SET_VEHICLE_COLOUR_COMBINATION(Vehicle vehicle, int32_t colorCombination) { NativeInvoke::Invoke<void>(0xA557AEAD, vehicle, colorCombination); }
	static void SET_VEHICLE_CONTROL_TO_PLAYER(Vehicle vehicle) { NativeInvoke::Invoke<void>(0x6BC7338F, vehicle); }
	static void SET_VEHICLE_COORDS(Vehicle vehicle, float x, float y, float z) { NativeInvoke::Invoke<void>(0x54C9AD1D, vehicle, x, y, z); }
	static void SET_VEHICLE_COORDS_NO_OFFSET(Vehicle vehicle, float x, float y, float z) { NativeInvoke::Invoke<void>(0x67714186, vehicle, x, y, z); }
	static void SET_VEHICLE_DAMAGE(Vehicle vehicle, float xOffset, float yOffset, float zOffset, float damage, float radius, bool p6) { NativeInvoke::Invoke<void>(0x21B458B2, vehicle, xOffset, yOffset, zOffset, damage, radius, p6); }
	static void SET_VEHICLE_DENSITY_MULTIPLIER(float multiplier) { NativeInvoke::Invoke<void>(0x8B289F79, multiplier); }
	static void SET_VEHICLE_DIRT_LEVEL(Vehicle vehicle, float dirtLevel) { NativeInvoke::Invoke<void>(0x2B39128B, vehicle, dirtLevel); }
	static void SET_VEHICLE_DOORS_LOCKED(Vehicle vehicle, int32_t status) { NativeInvoke::Invoke<void>(0x4CDD35D0, vehicle, status); }
	static void SET_VEHICLE_DOORS_SHUT(Vehicle vehicle) { NativeInvoke::Invoke<void>(0xBB1FF6E7, vehicle); }
	static void SET_VEHICLE_DOOR_BROKEN(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0x8147FEA7, p0, p1, p2); }
	static void SET_VEHICLE_DOOR_CONTROL(Any p0, Any p1, Any p2, Any p3) { NativeInvoke::Invoke<void>(0x572DD360, p0, p1, p2, p3); }
	static void SET_VEHICLE_DOOR_LATCHED(Any p0, Any p1, Any p2, Any p3) { NativeInvoke::Invoke<void>(0x4EB7BBFC, p0, p1, p2, p3); }
	static void SET_VEHICLE_DOOR_OPEN(Vehicle vehicle, int32_t door) { NativeInvoke::Invoke<void>(0xBB75D38B, vehicle, door); }
	static void SET_VEHICLE_DOOR_SHUT(Any p0, Any p1, Any p2, Any p3) { NativeInvoke::Invoke<void>(0x142606BD, p0, p1, p2, p3); }
	static void SET_VEHICLE_DRIVE_FORCE_IN_AIR(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x2B97EF1F, vehicle, toggle); }
	static void SET_VEHICLE_ENGINE_CAN_BE_DAMAGED(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x5AAB9674, vehicle, toggle); }
	static void SET_VEHICLE_ENGINE_HEALTH(Vehicle vehicle, float health) { NativeInvoke::Invoke<void>(0x1B760FB5, vehicle, health); }
	static void SET_VEHICLE_ENGINE_ON(Vehicle vehicle, bool value, bool instantly) { NativeInvoke::Invoke<void>(0x7FBC86F1, vehicle, value, instantly); }
	static void SET_VEHICLE_EXPLODES_ONLY_FROM_PROJECTILE_EXPLOSIONS(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x8D359F17, vehicle, toggle); }
	static void SET_VEHICLE_EXPLODES_ON_HIGH_EXPLOSION_DAMAGE(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x38CC692B, vehicle, toggle); }
	static void SET_VEHICLE_EXTRA(Vehicle vehicle, int32_t extra, bool p2) { NativeInvoke::Invoke<void>(0x642D065C, vehicle, extra, p2); }
	static void SET_VEHICLE_EXTRA_COLOURS(Vehicle vehicle, int32_t pearlescentColor, int32_t wheelColor) { NativeInvoke::Invoke<void>(0x515DB2A0, vehicle, pearlescentColor, wheelColor); }
	static void SET_VEHICLE_FIXED(Vehicle vehicle) { NativeInvoke::Invoke<void>(0x17469AA1, vehicle); }
	static void SET_VEHICLE_FIXED_WEAPON_ACCURACY(Vehicle vehicle, float accurary, int32_t weaponIndex) { NativeInvoke::Invoke<void>(0xC38EDA8A, vehicle, accurary, weaponIndex); }
	static void SET_VEHICLE_FIXED_WEAPON_DAMAGE(Vehicle vehicle, float damage, int32_t weaponIndex) { NativeInvoke::Invoke<void>(0x4F177788, vehicle, damage, weaponIndex); }
	static void SET_VEHICLE_FIXED_WEAPON_FIRING_PATTERN_MODE(Vehicle vehicle, int32_t mode, int32_t weaponIndex) { NativeInvoke::Invoke<void>(0xC8FF4A34, vehicle, mode, weaponIndex); }
	static void SET_VEHICLE_FIXED_WEAPON_FIRING_PATTERN_SET(Vehicle vehicle, int32_t weaponIndex, uint32_t firingPatternHash1, uint32_t firingPatternHash2, uint32_t firingPatternHash3, uint32_t firingPatternHash4, uint32_t firingPatternHash5, uint32_t firingPatternHash6, uint32_t firingPatternHash7, uint32_t firingPatternHash8, uint32_t firingPatternHash9, uint32_t firingPatternHash10) { NativeInvoke::Invoke<void>(0xB4F809D, vehicle, weaponIndex, firingPatternHash1, firingPatternHash2, firingPatternHash3, firingPatternHash4, firingPatternHash5, firingPatternHash6, firingPatternHash7, firingPatternHash8, firingPatternHash9, firingPatternHash10); }
	static void SET_VEHICLE_FORWARD_SPEED(Vehicle vehicle, float speed) { NativeInvoke::Invoke<void>(0x69880D14, vehicle, speed); }
	static void SET_VEHICLE_FREEZE_AFTER_BLOWING_UP(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0xFCD50E3D, vehicle, toggle); }
	static void SET_VEHICLE_HAS_BEEN_OWNED_BY_PLAYER(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0xB4D3DBFB, vehicle, toggle); }
	static void SET_VEHICLE_HAS_STRONG_AXLES(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0xD1CBC65, vehicle, toggle); }
	static void SET_VEHICLE_HEADING(Vehicle vehicle, float heading) { NativeInvoke::Invoke<void>(0x3E502113, vehicle, heading); }
	static void SET_VEHICLE_HEALTH(Vehicle vehicle, int32_t health) { NativeInvoke::Invoke<void>(0x3BCB0EA4, vehicle, health); }
	static void SET_VEHICLE_INST_LIGHT_TUNE_VALUES(Vehicle vehicle, Any* data) { NativeInvoke::Invoke<void>(0x3ADF1AAA, vehicle, data); }
	static void SET_VEHICLE_INTERIORLIGHT(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x9AD1FE1E, vehicle, toggle); }
	static void SET_VEHICLE_IN_CUTSCENE(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x25533564, vehicle, toggle); }
	static void SET_VEHICLE_IS_CONSIDERED_BY_PLAYER(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x14413319, vehicle, toggle); }
	static void SET_VEHICLE_LIGHTS(Vehicle vehicle, int32_t state) { NativeInvoke::Invoke<void>(0xE8930226, vehicle, state); }
	static void SET_VEHICLE_LIGHT_MULTIPLIER(Vehicle vehicle, float multiplier) { NativeInvoke::Invoke<void>(0x48039D6A, vehicle, multiplier); }
	static void SET_VEHICLE_LIVERY(Vehicle vehicle, int32_t liveryIndex) { NativeInvoke::Invoke<void>(0x7AD87059, vehicle, liveryIndex); }
	static void SET_VEHICLE_MODEL_IS_SUPPRESSED(uint32_t modelHash, bool toggle) { NativeInvoke::Invoke<void>(0x42A08C9B, modelHash, toggle); }
	static void SET_VEHICLE_NAME_DEBUG(Vehicle vehicle, const char* name) { NativeInvoke::Invoke<void>(0xA712FF5C, vehicle, name); }
	static void SET_VEHICLE_NEEDS_TO_BE_HOTWIRED(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0xD8260751, vehicle, toggle); }
	static void SET_VEHICLE_NOT_EXPLODABLE(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x5F2B2A1C, vehicle, toggle); }
	static void SET_VEHICLE_ONLY_DAMAGED_BY_PLAYER(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x5F6A171F, vehicle, toggle); }
	static void SET_VEHICLE_ONLY_DAMAGED_BY_RELATIONSHIP_GROUP(Vehicle vehicle, bool toggle, int32_t relGroupId) { NativeInvoke::Invoke<void>(0x5A7B778A, vehicle, toggle, relGroupId); }
	static void SET_VEHICLE_ONLY_EXPLODES_WHEN_HIT_BY_MULTIPLE_EXPLOSIONS(Vehicle vehicle, bool toggle, int32_t p2) { NativeInvoke::Invoke<void>(0x2A61C5E7, vehicle, toggle, p2); }
	static void SET_VEHICLE_PETROL_TANK_HEALTH(Vehicle vehicle, float health) { NativeInvoke::Invoke<void>(0x660A3692, vehicle, health); }
	static void SET_VEHICLE_PROOFS(Vehicle vehicle, bool p1, bool p2, bool p3, bool p4, bool p5) { NativeInvoke::Invoke<void>(0x23448784, vehicle, p1, p2, p3, p4, p5); }
	static void SET_VEHICLE_PROVIDES_COVER(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0xEFC01CA9, vehicle, toggle); }
	static void SET_VEHICLE_QUATERNION(Vehicle vehicle, float x, float y, float z, float w) { NativeInvoke::Invoke<void>(0x7A5B849E, vehicle, x, y, z, w); }
	static void SET_VEHICLE_RANDOM_ROUTE_SEED(Vehicle vehicle, int32_t seed) { NativeInvoke::Invoke<void>(0x18271E90, vehicle, seed); }
	static void SET_VEHICLE_REACT_TO_EXPLOSION(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0xB755CE11, vehicle, toggle); }
	static void SET_VEHICLE_SIREN(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x4AC1EFC7, vehicle, toggle); }
	static void SET_VEHICLE_STEER_BIAS(Vehicle vehicle, float value) { NativeInvoke::Invoke<void>(0x7357C1EB, vehicle, value); }
	static void SET_VEHICLE_STRONG(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0xC758D19F, vehicle, toggle); }
	static void SET_VEHICLE_TURNS_TO_FACE_COORD(Vehicle vehicle, float x, float y) { NativeInvoke::Invoke<void>(0x9F751407, vehicle, x, y); }
	static void SET_VEHICLE_TYRES_CAN_BURST(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0xA198DB54, vehicle, toggle); }
	static void SET_VEHICLE_TYRE_BURST(Vehicle vehicle, int32_t tire) { NativeInvoke::Invoke<void>(0x89D28068, vehicle, tire); }
	static void SET_VEHICLE_TYRE_FIXED(Vehicle vehicle, int32_t tire) { NativeInvoke::Invoke<void>(0xA42EFA6B, vehicle, tire); }
	static void SET_VEHICLE_VISIBLE(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0x33C606E, vehicle, toggle); }
	static void SET_VISIBILITY_OF_CLOSEST_OBJECT_OF_TYPE(float x, float y, float z, float radius, uint32_t modelHash, bool visible) { NativeInvoke::Invoke<void>(0x702FAEEB, x, y, z, radius, modelHash, visible); }
	static void SET_VOICE_ID_FROM_HEAD_COMPONENT(Ped ped, int32_t unused1, bool unused2) { NativeInvoke::Invoke<void>(0x84EDB1B8, ped, unused1, unused2); } 
	static void SET_WAITING_AT_STATION_TIME(Vehicle train, int32_t time) { NativeInvoke::Invoke<void>(0x745EA145, train, time); }
	static void SET_WAKES_SECTION(int32_t section) { NativeInvoke::Invoke<void>(0x75BA1528, section); }
	static void SET_WANTED_LEVEL_MULTIPLIER(float multiplier) { NativeInvoke::Invoke<void>(0x1359292F, multiplier); }
	static void SET_WEAPON_AMMO(Weapon weapon, int32_t ammo) { NativeInvoke::Invoke<void>(0x3A3DB7F1, weapon, ammo); }
	static void SET_WEAPON_AMMO_IN_CLIP(Weapon weapon, int32_t ammo) { NativeInvoke::Invoke<void>(0xA5F4270F, weapon, ammo); }
	static void SET_WEAPON_AS_NO_LONGER_NEEDED(uint32_t weaponHash) { NativeInvoke::Invoke<void>(0x9A0E29DE, weaponHash); }
	static void SET_WEAPON_CHANCE_TO_FIRE_BLANKS(Weapon weapon, int32_t chance) { NativeInvoke::Invoke<void>(0x40BA5A39, weapon, chance); }
	static void SET_WEAPON_LIGHT_DATA(Weapon weapon, int32_t index) { NativeInvoke::Invoke<void>(0x29E99A13, weapon, index); }
	static void SET_WEAPON_LIGHT_DATA_BY_NAME(Weapon weapon, const char* name) { NativeInvoke::Invoke<void>(0x7F9CE88, weapon, name); }
	static void SET_WEAPON_SLOT(Ped ped, Weapon weapon, int32_t holsterType) { NativeInvoke::Invoke<void>(0x16DBCD1, ped, weapon, holsterType); }
	static void SET_WEAPON_SPAWNS_PICKUP(Weapon weapon, bool toggle) { NativeInvoke::Invoke<void>(0x14645293, weapon, toggle); }
	static void SET_WEAPON_VISIBLE(Weapon weapon, bool toggle) { NativeInvoke::Invoke<void>(0x529A119E, weapon, toggle); }
	static void SET_WEATHER_TRANSITION_IMMEDIATE(bool toggle) { NativeInvoke::Invoke<void>(0x8DE31F0B, toggle); }
	static void SET_WEATHER_TRANSITION_SPEED(float speed) { NativeInvoke::Invoke<void>(0x17EB71A7, speed); }
	static void SET_WEATHER_TYPE_NOW_PERSIST(const char* weatherType) { NativeInvoke::Invoke<void>(0xC869FE97, weatherType); }
	static void SET_WEATHER_TYPE_PERSIST(const char* weatherType) { NativeInvoke::Invoke<void>(0xC6C04C75, weatherType); }
	static void SET_WIDESCREEN_BORDERS(bool toggle, int32_t p1) { NativeInvoke::Invoke<void>(0x1A75DC9A, toggle, p1); }
	static void SET_WIDESCREEN_FORMAT(int32_t format) { NativeInvoke::Invoke<void>(0xF016E08F, format); }
	static void SET_WIND(float speed) { NativeInvoke::Invoke<void>(0xC6294698, speed); }
	static void SET_ZONE_COPS_ACTIVE(const char* zoneName, bool toggle) { NativeInvoke::Invoke<void>(0xD604096C, zoneName, toggle); }
	static void SET_ZONE_POPULATION_TYPE(const char* zoneName, int32_t type) { NativeInvoke::Invoke<void>(0xFC30948B, zoneName, type); }
	static void SET_ZONE_SCUMMINESS(const char* zoneName, int32_t scumminess) { NativeInvoke::Invoke<void>(0x6E35CF9A, zoneName, scumminess); }
	static void SEV_CONNECTED_ONLY() { NativeInvoke::Invoke<void>(0x1BC7E9FB); }
	static void SEV_CREATE_OBJECT(Object object, uint32_t modelHash, float x, float y, float z) { NativeInvoke::Invoke<void>(0x7D9E2B5F, object, modelHash, x, y, z); }
	static void SEV_CREATE_PED(Ped ped, uint32_t modelHash, float x, float y, float z, float heading, bool isNetwork, bool dontOwn) { NativeInvoke::Invoke<void>(0xF9F0D9BB, ped, modelHash, x, y, z, heading, isNetwork, dontOwn); }
	static void SEV_CREATE_PICKUP(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9) { NativeInvoke::Invoke<void>(0x9DFDA816, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9); }
	static void SEV_CREATE_VEHICLE(Vehicle vehicle, uint32_t modelHash, float x, float y, float z, float heading) { NativeInvoke::Invoke<void>(0xD421FF04, vehicle, modelHash, x, y, z, heading); }
	static void SEV_DELETE_OBJECT(Object object) { NativeInvoke::Invoke<void>(0xBEB0FDDE, object); }
	static void SEV_INDUCE_EVENT(Any p0) { NativeInvoke::Invoke<void>(0xF7669E49, p0); }
	static void SEV_INDUCE_EVENT_ARGS(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0xF69FEF47, p0, p1, p2); }
	static void SEV_INDUCE_GATHER_EVENT(Any p0) { NativeInvoke::Invoke<void>(0x7FD7CD71, p0); }
	static void SEV_INDUCE_LOCAL_EVENT(Any p0) { NativeInvoke::Invoke<void>(0xF199C3EB, p0); }
	static void SEV_INDUCE_LOCAL_EVENT_ARGS(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0xA2793188, p0, p1, p2); }
	static void SEV_ISOLATE() { NativeInvoke::Invoke<void>(0xFC64AA42); }
	static void SEV_ISOLATED_ONLY() { NativeInvoke::Invoke<void>(0xBD5E1E6B); }
	static void SEV_ISOLATE_OFF() { NativeInvoke::Invoke<void>(0x821594DD); }
	static void SEV_NEXT_EVENT(Any p0, Any p1) { NativeInvoke::Invoke<void>(0xAFB40502, p0, p1); }
	static void SEV_ONCE_ONLY() { NativeInvoke::Invoke<void>(0x6DA448CC); }
	static void SEV_RESURRECT_PLAYER(Any p0, Any p1, Any p2, Any p3, Any p4) { NativeInvoke::Invoke<void>(0xC0AC4551, p0, p1, p2, p3, p4); }
	static void SEV_RESURRECT_PLAYER_FINISH(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0xD506CEF7, p0, p1, p2); }
	static void SEV_SET_PLAYER_AVATAR(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0x1778B6B6, p0, p1, p2); }
	static void SEV_SET_PLAYER_FRIENDLY_FIRE(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x1B65C378, p0, p1); }
	static void SEV_SET_PLAYER_MODEL(Player player, uint32_t modelHash) { NativeInvoke::Invoke<void>(0x4BAA35E9, player, modelHash); }
	static void SEV_THREAD_THIS(Any p0) { NativeInvoke::Invoke<void>(0xD494158C, p0); }
	static void SEV_UNBIND(Any p0) { NativeInvoke::Invoke<void>(0x34AD4192, p0); }
	static void SEV_UNBIND_ALL_FOR_PED(Any p0) { NativeInvoke::Invoke<void>(0x7561DF34, p0); }
	static void SEV_UNBIND_CATEGORY(Any p0) { NativeInvoke::Invoke<void>(0xEA305AC0, p0); }
	static void SEV_UNBIND_HANDLER(Any p0) { NativeInvoke::Invoke<void>(0xAA607425, p0); }
	static void SEV_WAIT_FOR(Any p0) { NativeInvoke::Invoke<void>(0xCD3036F5, p0); }
	static void SEV_YIELD() { NativeInvoke::Invoke<void>(0x7DE3579B); }
	static void SHAKE_CAM(Cam cam, const char* shakeName, float amplitude) { NativeInvoke::Invoke<void>(0x1D4211B0, cam, shakeName, amplitude); }
	static void SHAKE_GAMEPLAY_CAM(const char* shakeName, float intensity) { NativeInvoke::Invoke<void>(0xF2EFE660, shakeName, intensity); }
	static void SHOOT_SINGLE_BULLET_BETWEEN_COORDS(float x1, float y1, float z1, float x2, float y2, float z2, int32_t damage, bool p7, uint32_t weaponHash, Ped ownerPed) { NativeInvoke::Invoke<void>(0xCB7415AC, x1, y1, z1, x2, y2, z2, damage, p7, weaponHash, ownerPed); }
	static void SHOW_BLIP_ROTATION(Blip blip, bool toggle) { NativeInvoke::Invoke<void>(0x17773F15, blip, toggle); }
	static void SHUTDOWN_AND_LAUNCH_NETWORK_GAME(int32_t levelIndex) { NativeInvoke::Invoke<void>(0x691694D2, levelIndex); }
	static void SHUTDOWN_AND_LAUNCH_SINGLE_PLAYER_GAME() { NativeInvoke::Invoke<void>(0x92B7351C); }
	static void SILENCE_VEHICLE(Vehicle vehicle, bool toggle) { NativeInvoke::Invoke<void>(0xA7250DE3, vehicle, toggle); }
	static void SIMULATE_PLAYER_INPUT_GAIT(Player player, float amount, int32_t gaitType, float speed) { NativeInvoke::Invoke<void>(0xD77CC34, player, amount, gaitType, speed); }
	static void SKIP_FORWARD_TO_TIME_OF_DAY(int32_t hour, int32_t minute) { NativeInvoke::Invoke<void>(0x8B1C8A57, hour, minute); }
	static void SKIP_ROTOR_SHADOW(bool toggle) { NativeInvoke::Invoke<void>(0xC96B8836, toggle); }
	static void SKIP_TIME_IN_PLAYBACK_RECORDED_PED(Ped ped, float time) { NativeInvoke::Invoke<void>(0x699F9D74, ped, time); }
	static void SKIP_TIME_IN_PLAYBACK_RECORDED_VEHICLE(Vehicle vehicle, float time) { NativeInvoke::Invoke<void>(0xCF3EFA4B, vehicle, time); }
	static void SKIP_TO_END_AND_STOP_PLAYBACK_RECORDED_VEHICLE(Vehicle vehicle) { NativeInvoke::Invoke<void>(0x8DEA18C8, vehicle); }
	static void SKIP_TO_NEXT_ALLOWED_STATION(Vehicle train) { NativeInvoke::Invoke<void>(0xCF682EC7, train); }
	static void SMASH_GLASS_IN_RADIUS(Any p0, Any p1, Any p2, Any p3, Any p4) { NativeInvoke::Invoke<void>(0x71B56B9F, p0, p1, p2, p3, p4); }
	static void SMASH_VEHICLE_WINDOW(Vehicle vehicle, int32_t window) { NativeInvoke::Invoke<void>(0xDDD9A8C2, vehicle, window); }
	static void SNAPSHOT_GLOBALS() { NativeInvoke::Invoke<void>(0x5A25520E); } 
	static void SPAWN_GRENADE(Ped ped, uint32_t p1, float p2, float p3, float p4, float p5) { NativeInvoke::Invoke<void>(0x34E8E337, ped, p1, p2, p3, p4, p5); }
	static void SPLIT_LOCALISED_STRING(const char* textLabel, int32_t bufferSize1, char* buffer1, int32_t bufferSize2, char* buffer2, int32_t bufferSize3, char* buffer3, int32_t bufferSize4, char* buffer4) { NativeInvoke::Invoke<void>(0xE6102DD1, textLabel, bufferSize1, buffer1, bufferSize2, buffer2, bufferSize3, buffer3, bufferSize4, buffer4); }
	static void START_CONTEXT(const char* name) { NativeInvoke::Invoke<void>(0xF1A3B61A, name); }
	static void START_CONTEXT_HASH(uint32_t hash) { NativeInvoke::Invoke<void>(0x906945AC, hash); }
	static void START_CUTSCENE_CAPTURE(const char* cutsceneName) { NativeInvoke::Invoke<void>(0x5B705AC1, cutsceneName); }
	static void START_CUTSCENE_WITH_FADES(const char* cutsceneName) { NativeInvoke::Invoke<void>(0x1C21BE91, cutsceneName); }
	static void START_FIRING_AMNESTY() { NativeInvoke::Invoke<void>(0x5F8A22A6); }
	static void START_NEW_WIDGET_COMBO() { NativeInvoke::Invoke<void>(0x284A3C93); }
	static void START_PANEL_WIPE(int32_t p0, int32_t p1) { NativeInvoke::Invoke<void>(0x45E78975, p0, p1); }
	static void START_PED_SEARCH_CRITERIA() { NativeInvoke::Invoke<void>(0x12B1686A); }
	static void START_PLAYBACK_RECORDED_PED(Ped ped, int32_t recordingIndex) { NativeInvoke::Invoke<void>(0x436563F4, ped, recordingIndex); }
	static void START_PLAYBACK_RECORDED_VEHICLE(Vehicle vehicle, int32_t recordingIndex) { NativeInvoke::Invoke<void>(0xCF614CA8, vehicle, recordingIndex); }
	static void START_PLAYBACK_RECORDED_VEHICLE_USING_AI(Vehicle vehicle, int32_t recordingIndex) { NativeInvoke::Invoke<void>(0x8DE8E24E, vehicle, recordingIndex); }
	static void START_PLAYER_SHOOTDODGE(float p0, float p1, float p2, bool p3, bool p4, float p5, float p6) { NativeInvoke::Invoke<void>(0x96BB9783, p0, p1, p2, p3, p4, p5, p6); }
	static void START_POSTFX_BLENDER(int32_t p0) { NativeInvoke::Invoke<void>(0x817C43D7, p0); }
	static void START_SCRIPT_CONVERSATION(int32_t index, bool p1, bool p2) { NativeInvoke::Invoke<void>(0xE5DE7D9D, index, p1, p2); }
	static void START_SEAMLESS_CUTSCENE() { NativeInvoke::Invoke<void>(0x243A852E); }
	static void START_SEAMLESS_CUTSCENE_AT_COORDS(float x, float y, float z, float p3) { NativeInvoke::Invoke<void>(0x8FE348F, x, y, z, p3); }
	static void START_VEHICLE_ALARM(Vehicle vehicle) { NativeInvoke::Invoke<void>(0x5B451FF7, vehicle); }
	static void START_VEHICLE_HORN(Vehicle vehicle, int32_t duration) { NativeInvoke::Invoke<void>(0xDF5ADB3, vehicle, duration); }
	static void START_WIDGET_GROUP(const char* p0) { NativeInvoke::Invoke<void>(0xA782BE62, p0); }
	static void STAT_ADD_FLOAT(const char* statName, bool p1, bool p2) { NativeInvoke::Invoke<void>(0xA54780E8, statName, p1, p2); }
	static void STAT_ADD_INT(const char* statName, bool p1, bool p2) { NativeInvoke::Invoke<void>(0x528AA36E, statName, p1, p2); }
	static void STAT_DECREMENT_FLOAT(const char* statName, float value) { NativeInvoke::Invoke<void>(0xEEB7CFAD, statName, value); }
	static void STAT_DECREMENT_INT(const char* statName, int32_t value) { NativeInvoke::Invoke<void>(0x5C7AA25B, statName, value); }
	static void STAT_HASH_ADD_FLOAT(uint32_t statHash, bool p1, bool p2) { NativeInvoke::Invoke<void>(0xB5B89FD2, statHash, p1, p2); }
	static void STAT_HASH_ADD_INT(uint32_t statHash, bool p1, bool p2) { NativeInvoke::Invoke<void>(0xA820FB24, statHash, p1, p2); }
	static void STAT_HASH_DECREMENT_FLOAT(uint32_t statHash, float value) { NativeInvoke::Invoke<void>(0xBA1661EC, statHash, value); }
	static void STAT_HASH_DECREMENT_INT(uint32_t statHash, int32_t value) { NativeInvoke::Invoke<void>(0x4FBDB9F, statHash, value); }
	static void STAT_HASH_INCREMENT_FLOAT(uint32_t statHash, float value) { NativeInvoke::Invoke<void>(0x9130A032, statHash, value); }
	static void STAT_HASH_INCREMENT_INT(uint32_t statHash, int32_t value) { NativeInvoke::Invoke<void>(0xD2B83ECE, statHash, value); }
	static void STAT_HASH_SET_FLOAT(uint32_t statHash, float value) { NativeInvoke::Invoke<void>(0xF7291D39, statHash, value); }
	static void STAT_HASH_SET_INT(uint32_t statHash, int32_t value) { NativeInvoke::Invoke<void>(0x2D2ECF2D, statHash, value); }
	static void STAT_HASH_WAIT_FOR_CHANGE_FLOAT(uint32_t statHash, float value) { NativeInvoke::Invoke<void>(0xEA2D7D0D, statHash, value); }
	static void STAT_HASH_WAIT_FOR_CHANGE_INT(uint32_t statHash, int32_t value) { NativeInvoke::Invoke<void>(0x59D78FCB, statHash, value); }
	static void STAT_INCREMENT_FLOAT(const char* statName, float value) { NativeInvoke::Invoke<void>(0x562B69E2, statName, value); }
	static void STAT_INCREMENT_INT(const char* statName, int32_t value) { NativeInvoke::Invoke<void>(0x4470A2D3, statName, value); }
	static void STAT_SET_FLOAT(const char* statName, float value) { NativeInvoke::Invoke<void>(0x6CEA96F2, statName, value); }
	static void STAT_SET_INT(const char* statName, int32_t value) { NativeInvoke::Invoke<void>(0xC9CC1C5C, statName, value); }
	static void STAT_WAIT(int32_t argCount, ...) { }
	static void STAT_WAIT_FOR_CHANGE_FLOAT(const char* statName, float value) { NativeInvoke::Invoke<void>(0x48E0F996, statName, value); }
	static void STAT_WAIT_FOR_CHANGE_INT(const char* statName, int32_t value) { NativeInvoke::Invoke<void>(0x4E41F40, statName, value); }
	static void STAT_WAIT_UNTIL_EXIST(int32_t argCount, ...) {}
	static void STOP_ALL_IMAGEFX(bool p0) { NativeInvoke::Invoke<void>(0xB7BC77AB, p0); }
	static void STOP_ALL_SCRIPTED_CONVERSATIONS(Any p0) { NativeInvoke::Invoke<void>(0xCBE79A01, p0); }
	static void STOP_ANY_PED_MODEL_BEING_SUPPRESSED() { NativeInvoke::Invoke<void>(0x5AD7DC55); }
	static void STOP_CAM_POINTING(Cam cam) { NativeInvoke::Invoke<void>(0x5435F6A5, cam); }
	static void STOP_CAM_SHAKING(Cam cam, bool p1) { NativeInvoke::Invoke<void>(0x40D0EB87, cam, p1); }
	static void STOP_CURRENT_PLAYING_AMBIENT_SPEECH(Ped ped) { NativeInvoke::Invoke<void>(0xBB8E64BF, ped); }
	static void STOP_CUTSCENE_AUDIO() { NativeInvoke::Invoke<void>(0x55461BE6); }
	static void STOP_CUTSCENE_CAPTURE() { NativeInvoke::Invoke<void>(0x5BCC78E8); }
	static void STOP_FIRE_IN_RANGE(float x, float y, float z, float radius) { NativeInvoke::Invoke<void>(0x725C7205, x, y, z, radius); }
	static void STOP_GAMEPLAY_CAM_SHAKING(Any p0, Any p1) { NativeInvoke::Invoke<void>(0xFD569E4E, p0, p1); }
	static void STOP_GAMEPLAY_HINT() { NativeInvoke::Invoke<void>(0x1BC28B7B); } 
	static void STOP_IMAGEFX(int32_t p0, bool p1) { NativeInvoke::Invoke<void>(0xB27BC9FD, p0, p1); }
	static void STOP_MOVIE(int32_t p0) { NativeInvoke::Invoke<void>(0x7827E516, p0); }
	static void STOP_MUSIC() { NativeInvoke::Invoke<void>(0x84A658A1); } 
	static void STOP_OVERRIDING_PED_FIRING_PATTERN(Ped ped) { NativeInvoke::Invoke<void>(0x954F6D21, ped); }
	static void STOP_PARTICLE_FX_LOOPED(Any ptfxHandle) { NativeInvoke::Invoke<void>(0xD245455B, ptfxHandle); }
	static void STOP_PED_DOING_FALL_OFF_TESTS_WHEN_SHOT(Ped ped) { NativeInvoke::Invoke<void>(0x5B01902A, ped); }
	static void STOP_PED_FIRE(Ped ped) { NativeInvoke::Invoke<void>(0xABE73926, ped); }
	static void STOP_PED_SEARCH_CRITERIA() { NativeInvoke::Invoke<void>(0xE9AFE4DE); }
	static void STOP_PED_SPEAKING(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xFF92B49D, ped, toggle); }
	static void STOP_PED_WEAPON_FIRING_WHEN_DROPPED(Ped ped) { NativeInvoke::Invoke<void>(0x4AC3421E, ped); }
	static void STOP_PLAYBACK_RECORDED_PED(Ped ped) { NativeInvoke::Invoke<void>(0xD7358C69, ped); }
	static void STOP_PLAYBACK_RECORDED_VEHICLE(Vehicle vehicle) { NativeInvoke::Invoke<void>(0xAE99C57C, vehicle); }
	static void STOP_SCRIPT_STREAM(Any p0) { NativeInvoke::Invoke<void>(0xD6CA123C, p0); }
	static void STOP_SOUND(int32_t soundId, bool p1) { NativeInvoke::Invoke<void>(0xCD7F4030, soundId, p1); }
	static void STOP_VEHICLE_FIRE(Vehicle vehicle) { NativeInvoke::Invoke<void>(0xCEC13B6B, vehicle); }
	static void STOP_WIDGET_GROUP() { NativeInvoke::Invoke<void>(0xB7E25D55); }
	static void STORE_FRONTEND_TIMECYCLE_SETTINGS() { NativeInvoke::Invoke<void>(0x9BDAB003); }
	static void STREAM_HELPERS_DEACTIVATE() { NativeInvoke::Invoke<void>(0xBDA5C5F7); }
	static void STREAM_HELPERS_INIT() { NativeInvoke::Invoke<void>(0x13D43922); }
	static void STREAM_HELPERS_REACTIVATE() { NativeInvoke::Invoke<void>(0xE2E89E47); }
	static void STREAM_HELPERS_REQUEST_AT_LOC(float x, float y, float z, bool p3) { NativeInvoke::Invoke<void>(0x7C544BF3, x, y, z, p3); }
	static void STRING_APPEND(int32_t bufferSize, char* buffer, const char* formatOrTextLabel, int32_t argCount, ...) {}
	static void STRING_FORMAT(int32_t bufferSize, char* buffer, const char* formatOrTextLabel, int32_t argCount, ...) {}
	static void STRING_FORMAT_HASH(int32_t bufferSize, char* buffer, uint32_t textLabelHash, int32_t argCount, ...) {}
	static void STRING_STORE(const char* p0, const char* p1) { NativeInvoke::Invoke<void>(0xC1389FB0, p0, p1); }
	static void SWAP_NEAREST_BUILDING_MODEL(float x, float y, float z, float radius, uint32_t modelHashFrom, uint32_t modelHashTo) { NativeInvoke::Invoke<void>(0xFBD8341B, x, y, z, radius, modelHashFrom, modelHashTo); }
	static void SWITCH_TO_LEVEL(int32_t index) { NativeInvoke::Invoke<void>(0xFA085695, index); }
	static void SWITCH_TO_LEVEL_NAME(const char* name) { NativeInvoke::Invoke<void>(0xB0F99718, name); }
	static void SYNC_FRAGMENT_OBJECTS(uint32_t modelHash) { NativeInvoke::Invoke<void>(0x521555E5, modelHash); }
	static void SYNC_FRAGMENT_OBJECTS_IN_IPL(const char* iplName, bool toggle) { NativeInvoke::Invoke<void>(0xCD06F35C, iplName, toggle); }
	static void TASK_ACHIEVE_HEADING(Any p0, Any p1, Any p2, Any p3) { NativeInvoke::Invoke<void>(0xA0E9B42, p0, p1, p2, p3); }
	static void TASK_AIM_GUN_AT_COORD(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5) { NativeInvoke::Invoke<void>(0xFBF44AD3, p0, p1, p2, p3, p4, p5); }
	static void TASK_AIM_GUN_AT_PED(Ped ped, Ped targetPed, int32_t duration, bool p3) { NativeInvoke::Invoke<void>(0x3B4CA777, ped, targetPed, duration, p3); }
	static void TASK_AIM_GUN_AT_VEHICLE(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7) { NativeInvoke::Invoke<void>(0x217E69A2, p0, p1, p2, p3, p4, p5, p6, p7); }
	static void TASK_ATTACK_MOVE(Ped ped, float p1, float p2, float p3, float p4, float p5, float p6, int32_t p7) { NativeInvoke::Invoke<void>(0x72EA9C48, ped, p1, p2, p3, p4, p5, p6, p7); }
	static void TASK_ATTACK_MOVE_WHILE_AIMING_AT_COORD(Ped ped, float p1, float p2, float p3, float p4, float p5, float p6, bool p7, float p8, float p9, float p10, int32_t p11) { NativeInvoke::Invoke<void>(0xA08CC22F, ped, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11); }
	static void TASK_ATTACK_MOVE_WHILE_AIMING_AT_PED(Ped ped, float p1, float p2, float p3, Ped ped2, bool p5, float p6, float p7, float p8, int32_t p9) { NativeInvoke::Invoke<void>(0x1AD378CB, ped, p1, p2, p3, ped2, p5, p6, p7, p8, p9); }
	static void TASK_CAUTIOUS_MOVETO(Ped ped, float x, float y, float z) { NativeInvoke::Invoke<void>(0x77B12033, ped, x, y, z); }
	static void TASK_CHAT_TO_PED(Ped ped, Ped ped2, bool p2, bool p3) { NativeInvoke::Invoke<void>(0xA2BE1821, ped, ped2, p2, p3); }
	static void TASK_CHAT_WITH_PED(Ped ped, Ped ped2, bool p2, bool p3) { NativeInvoke::Invoke<void>(0xBECAED75, ped, ped2, p2, p3); }
	static void TASK_CLEAR_DEFAULT_AIM(Ped ped) { NativeInvoke::Invoke<void>(0x09F9B15, ped); }
	static void TASK_CLEAR_LOOK_AT(Any p0) { NativeInvoke::Invoke<void>(0x60EB4054, p0); }
	static void TASK_COMBAT_HATED_TARGETS_AROUND_PED(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x2E7064E4, p0, p1); }
	static void TASK_COMBAT_MOVE_TO_COVER(Ped ped, const char* p1, const char* p2, Ped ped2) { NativeInvoke::Invoke<void>(0x98F7B4E3, ped, p1, p2, ped2); }
	static void TASK_COMBAT_MOVE_TO_COVER_COORDS(Ped ped, float x, float y, float z, Ped ped2) { NativeInvoke::Invoke<void>(0xC219CD65, ped, x, y, z, ped2); }
	static void TASK_COMBAT_MOVE_TO_COVER_TACTICAL(Ped ped, const char* p1, const char* p2, bool p3, Ped ped2) { NativeInvoke::Invoke<void>(0xB54F8633, ped, p1, p2, p3, ped2); }
	static void TASK_COMBAT_MOVE_TO_COVER_TACTICAL_COORDS(Ped ped, float x, float y, float z, bool p4, Ped ped2) { NativeInvoke::Invoke<void>(0xA538B46E, ped, x, y, z, p4, ped2); }
	static void TASK_COMBAT_PED(Ped ped, Ped targetPed) { NativeInvoke::Invoke<void>(0xCB0D8932, ped, targetPed); }
	static void TASK_COMBAT_PED_TIMED(Ped ped, Ped targetPed, int32_t time) { NativeInvoke::Invoke<void>(0xF5CA2A45, ped, targetPed, time); }
	static void TASK_COMBAT_ROLL(Ped ped, int32_t p1) { NativeInvoke::Invoke<void>(0x8BB401CE, ped, p1); }
	static void TASK_COMBAT_SNAP_TO_COVER(Ped ped, const char* p1, const char* p2, Ped ped2) { NativeInvoke::Invoke<void>(0x62DA169D, ped, p1, p2, ped2); }
	static void TASK_COMBAT_SNAP_TO_COVER_AMBUSH(Ped ped, const char* p1, const char* p2, int32_t p3, int32_t p4, bool p5) { NativeInvoke::Invoke<void>(0xB42E30A0, ped, p1, p2, p3, p4, p5); }
	static void TASK_COMBAT_SNAP_TO_COVER_AMBUSH_COORDS(Ped ped, float x, float y, float z, int32_t p3, int32_t p4, bool p5) { NativeInvoke::Invoke<void>(0xC047B95C, ped, x, y, z, p3, p4, p5); }
	static void TASK_COMBAT_SNAP_TO_COVER_COORDS(Ped ped, float x, float y, float z, Ped ped2) { NativeInvoke::Invoke<void>(0x7342B8FD, ped, x, y, z, ped2); }
	static void TASK_COMBAT_SNAP_TO_COVER_TACTICAL(Ped ped, const char* p1, const char* p2, bool p3, Ped ped2) { NativeInvoke::Invoke<void>(0x60C0C2F7, ped, p1, p2, p3, ped2); }
	static void TASK_COMBAT_SNAP_TO_COVER_TACTICAL_COORDS(Ped ped, float x, float y, float z, bool p4, Ped ped2) { NativeInvoke::Invoke<void>(0x9BB448D7, ped, x, y, z, p4, ped2); }
	static void TASK_COWER(Ped ped) { NativeInvoke::Invoke<void>(0x9CF1C19B, ped); }
	static void TASK_DEFAULT_AIM_AHEAD(Ped ped) { NativeInvoke::Invoke<void>(0x5748EDC0, ped); }
	static void TASK_DEFAULT_AIM_AT_COORD(Ped ped, float x, float y, float z) { NativeInvoke::Invoke<void>(0x24190EC9, ped, x, y, z); }
	static void TASK_DEFAULT_AIM_AT_PED(Ped ped, Ped targetPed) { NativeInvoke::Invoke<void>(0x806DCEC3, ped, targetPed); }
	static void TASK_DODGE(Ped ped) { NativeInvoke::Invoke<void>(0xE1931B3A, ped); }
	static void TASK_DRIVER_COMBAT(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9, Any p10) { NativeInvoke::Invoke<void>(0xAB123B77, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10); }
	static void TASK_DRIVE_BY(Ped driverPed, Ped targetPed, Vehicle targetVehicle, float targetX, float targetY, float targetZ, float distanceToShoot, Any p7, bool p8, int32_t pedAccuracy) { NativeInvoke::Invoke<void>(0x2B84D1C4, driverPed, targetPed, targetVehicle, targetX, targetY, targetZ, distanceToShoot, p7, p8, pedAccuracy); }
	static void TASK_DRIVE_POINT_ROUTE(Ped driver, Vehicle vehicle, float p2) { NativeInvoke::Invoke<void>(0x4A2F3753, driver, vehicle, p2); }
	static void TASK_DROP_WEAPON(Ped ped, Weapon weapon) { NativeInvoke::Invoke<void>(0xBCC51D2B, ped, weapon); }
	static void TASK_DUCK(Ped ped, int32_t duration) { NativeInvoke::Invoke<void>(0x396A40E9, ped, duration); }
	static void TASK_ENTER_VEHICLE(Ped ped, Vehicle vehicle, int32_t timeout, int32_t doorIndex) { NativeInvoke::Invoke<void>(0xB8689B4E, ped, vehicle, timeout, doorIndex); }
	static void TASK_EVERYONE_LEAVE_VEHICLE(Ped ped) { NativeInvoke::Invoke<void>(0xC1971F30, ped); }
	static void TASK_FLUSH_ROUTE() { NativeInvoke::Invoke<void>(0x34219154); }
	static void TASK_FOLLOW_NAV_MESH_TO_COORD(Ped ped, float x, float y, float z, int32_t moveSpeedId, int32_t duration, float p6, int32_t flags, float p8) { NativeInvoke::Invoke<void>(0xFE4A10D9, ped, x, y, z, moveSpeedId, duration, p6, flags, p8); }
	static void TASK_FOLLOW_NAV_MESH_TO_COORD_ADVANCED(Ped ped, float x, float y, float z, int32_t moveSpeedId, int32_t duration, float p6, int32_t flags, Vector3* p8, float p9) { NativeInvoke::Invoke<void>(0x6BF6E296, ped, x, y, z, moveSpeedId, duration, p6, flags, p8, p9); }
	static void TASK_FOLLOW_PATROL_ROUTE(Ped ped, int32_t p1, int32_t p2) { NativeInvoke::Invoke<void>(0xADDF1C66, ped, p1, p2); }
	static void TASK_GET_OFF_BOAT(Vehicle boat, int32_t duration) { NativeInvoke::Invoke<void>(0x4293601F, boat, duration); }
	static void TASK_GET_ON_CUSTOM_VEHICLE(Vehicle vehicle, Ped ped, float p2, float p3, float p4, float p5, const char* p6, const char* p7) { NativeInvoke::Invoke<void>(0x87354C85, vehicle, ped, p2, p3, p4, p5, p6, p7); }
	static void TASK_GOTO_PED_OFFSET(Ped ped, Ped ped2, int32_t p2, float p3, float p4) { NativeInvoke::Invoke<void>(0x92B6581E, ped, ped2, p2, p3, p4); }
	static void TASK_GOTO_VEHICLE(Ped ped, Vehicle vehicle, int32_t p2, float p3) { NativeInvoke::Invoke<void>(0x8DE489D, ped, vehicle, p2, p3); }
	static void TASK_GO_STRAIGHT_TO_COORD(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5) { NativeInvoke::Invoke<void>(0x80A9E7A7, p0, p1, p2, p3, p4, p5); }
	static void TASK_GO_TO_COORD_ANY_MEANS(Ped ped, float x, float y, float z, int32_t p4, Vehicle vehicle) { NativeInvoke::Invoke<void>(0xF91DF93B, ped, x, y, z, p4, vehicle); }
	static void TASK_GO_TO_COORD_DPV(Ped ped, float x, float y, float z) { NativeInvoke::Invoke<void>(0xB374EC5, ped, x, y, z); }
	static void TASK_GO_TO_COORD_WHILE_AIMING_AT_COORD(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9, Any p10, Any p11, Any p12) { NativeInvoke::Invoke<void>(0x1552DC91, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12); }
	static void TASK_GO_TO_COORD_WHILE_AIMING_AT_PED(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9, Any p10) { NativeInvoke::Invoke<void>(0x19E32C2E, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10); }
	static void TASK_GO_TO_COORD_WHILE_AIMING_AT_VEHICLE(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9, Any p10) { NativeInvoke::Invoke<void>(0x56B67746, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10); }
	static void TASK_GO_TO_COORD_WHILE_SHOOTING(Ped ped, float x, float y, float z, int32_t a5, float a6, float a7, Ped ped2, bool a9) { NativeInvoke::Invoke<void>(0x424FED42, ped, x, y, z, a5, a6, a7, ped2, a9); }
	static void TASK_GO_TO_OBJECT(Ped ped, Object object, int32_t p2, float p3) { NativeInvoke::Invoke<void>(0x1BACD08, ped, object, p2, p3); }
	static void TASK_GO_TO_PED(Ped ped, Ped ped2, int32_t p2, float p3) { NativeInvoke::Invoke<void>(0xC2F0E987, ped, ped2, p2, p3); }
	static void TASK_GO_TO_PED_WHILE_AIMING_AT_PED(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8) { NativeInvoke::Invoke<void>(0x7068FC67, p0, p1, p2, p3, p4, p5, p6, p7, p8); }
	static void TASK_HANDS_UP(Ped ped, int32_t duration) { NativeInvoke::Invoke<void>(0x8DCC19C5, ped, duration); }
	static void TASK_HANG_GLIDER(Ped ped, Object object) { NativeInvoke::Invoke<void>(0xA0A33F8A, ped, object); }
	static void TASK_HELI_MISSION(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9, Any p10, Any p11, Any p12) { NativeInvoke::Invoke<void>(0xC143E97, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12); }
	static void TASK_JUMP(Ped ped, bool p1) { NativeInvoke::Invoke<void>(0x356E3CE, ped, p1); }
	static void TASK_JUMP_FORWARD(Ped ped) { NativeInvoke::Invoke<void>(0x3F5D4488, ped); }
	static void TASK_LEAVE_ANY_VEHICLE(Ped ped) { NativeInvoke::Invoke<void>(0xDBDD79FA, ped); }
	static void TASK_LEAVE_VEHICLE(Ped ped, Vehicle vehicle) { NativeInvoke::Invoke<void>(0x7B1141C6, ped, vehicle); }
	static void TASK_LEAVE_VEHICLE_DONT_CLOSE_DOOR(Ped ped, Vehicle vehicle) { NativeInvoke::Invoke<void>(0xF13827AD, ped, vehicle); }
	static void TASK_LEAVE_VEHICLE_IMMEDIATELY(Ped ped, Vehicle vehicle) { NativeInvoke::Invoke<void>(0x59CC2ED0, ped, vehicle); }
	static void TASK_LEAVE_VEHICLE_IN_DIRECTION(Ped ped, Vehicle vehicle, bool direction) { NativeInvoke::Invoke<void>(0x4D7BF56D, ped, vehicle, direction); }
	static void TASK_LOOK_AT_COORD(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5) { NativeInvoke::Invoke<void>(0x7B784DD8, p0, p1, p2, p3, p4, p5); }
	static void TASK_LOOK_AT_OBJECT(Ped ped, Object object, int32_t duration, int32_t flags) { NativeInvoke::Invoke<void>(0x44C5D95B, ped, object, duration, flags); }
	static void TASK_LOOK_AT_PED(Ped ped, Ped ped2, int32_t duration, int32_t flags) { NativeInvoke::Invoke<void>(0x930AE844, ped, ped2, duration, flags); }
	static void TASK_LOOK_AT_VEHICLE(Ped ped, Vehicle vehicle, int32_t duration, int32_t flags) { NativeInvoke::Invoke<void>(0x45651376, ped, vehicle, duration, flags); }
	static void TASK_MELEE_GRAPPLE(Ped ped, Ped targetPed, bool p2) { NativeInvoke::Invoke<void>(0x51B6927F, ped, targetPed, p2); }
	static void TASK_MELEE_LITE(Ped ped, Ped targetPed, bool p2) { NativeInvoke::Invoke<void>(0x91BAB133, ped, targetPed, p2); }
	static void TASK_MOBILE_CONVERSATION(Ped ped, bool wander) { NativeInvoke::Invoke<void>(0x60DA456, ped, wander); }
	static void TASK_OPEN_VEHICLE_DOOR(Ped ped, Vehicle vehicle, int32_t timeout, int32_t doorIndex) { NativeInvoke::Invoke<void>(0x8EE06BF4, ped, vehicle, timeout, doorIndex); }
	static void TASK_PATROL(Ped ped, const char* patrolRouteName, int32_t p2, bool p3, bool p4) { NativeInvoke::Invoke<void>(0xB92E5AF6, ped, patrolRouteName, p2, p3, p4); }
	static void TASK_PAUSE(Ped ped, int32_t duration) { NativeInvoke::Invoke<void>(0x17A64668, ped, duration); }
	static void TASK_PERFORM_SEQUENCE(Ped ped, Any taskSequence) { NativeInvoke::Invoke<void>(0x4D9FBD11, ped, taskSequence); }
	static void TASK_PERFORM_SEQUENCE_FROM_PROGRESS(Ped ped, Any taskSequence, int32_t p2, int32_t p3) { NativeInvoke::Invoke<void>(0xFA60601B, ped, taskSequence, p2, p3); }
	static void TASK_PERFORM_SEQUENCE_LOCALLY(Ped ped, Any taskSequence) { NativeInvoke::Invoke<void>(0x974D3D66, ped, taskSequence); }
	static void TASK_PICKUP_AND_CARRY_OBJECT(Ped ped, Object object, float x, float y, float z, bool p5) { NativeInvoke::Invoke<void>(0x6C47A7D6, ped, object, x, y, z, p5); }
	static void TASK_PLAY_ANIM(Ped ped, const char* animDict, const char* animName, float speed, float speedMultiplier, int32_t duration, int32_t flags) { NativeInvoke::Invoke<void>(0x5AB552C6, ped, animDict, animName, speed, speedMultiplier, duration, flags); }
	static void TASK_REACT_INITIAL(Ped ped, Ped ped2) { NativeInvoke::Invoke<void>(0x43A09C27, ped, ped2); }
	static void TASK_SEARCH_FOR_PED_AT_COVER_POINT(Ped ped, const char* p1, const char* p2, bool p3) { NativeInvoke::Invoke<void>(0x72C2B487, ped, p1, p2, p3); }
	static void TASK_SEARCH_FOR_UNSEEN_ENEMY(Ped ped, bool p1) { NativeInvoke::Invoke<void>(0x5246FFFA, ped, p1); }
	static void TASK_SELECT_WEAPON_TO_HAND(Ped ped, Weapon weapon, int32_t p2) { NativeInvoke::Invoke<void>(0xEF4D8FD9, ped, weapon, p2); }
	static void TASK_SET_ACTION_INTENTION(Ped ped, int32_t p1, int32_t p2, int32_t p3) { NativeInvoke::Invoke<void>(0x2E56473E, ped, p1, p2, p3); }
	static void TASK_SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0x1B54FB6B, ped, toggle); }
	static void TASK_SET_BLOCKING_OF_PED_TARGETTING(Ped ped, bool toggle) { NativeInvoke::Invoke<void>(0xC8CC8A7E, ped, toggle); }
	static void TASK_SET_PLAYER_CONTROL(Ped ped, bool p1, int32_t p2) { NativeInvoke::Invoke<void>(0x834490D1, ped, p1, p2); }
	static void TASK_SHOOTDODGE(Ped ped, bool p1, float p2, float p3) { NativeInvoke::Invoke<void>(0x1DBC90B4, ped, p1, p2, p3); }
	static void TASK_SHOOT_AT_COORD(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7) { NativeInvoke::Invoke<void>(0x601C22E3, p0, p1, p2, p3, p4, p5, p6, p7); }
	static void TASK_SHOOT_AT_PED(Ped ped, Ped targetPed, int32_t duration, uint32_t firingPatternHash, bool p4, bool p5, bool p6) { NativeInvoke::Invoke<void>(0xE878CC20, ped, targetPed, duration, firingPatternHash, p4, p5, p6); }
	static void TASK_SHOOT_AT_VEHICLE(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9) { NativeInvoke::Invoke<void>(0x09D5555, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9); }
	static void TASK_SHUFFLE_TO_NEXT_VEHICLE_SEAT(Ped ped, Vehicle vehicle) { NativeInvoke::Invoke<void>(0xBEAF8F67, ped, vehicle); }
	static void TASK_SIT_DOWN(Ped ped, int32_t p1, int32_t p2, int32_t p3) { NativeInvoke::Invoke<void>(0xB40FC847, ped, p1, p2, p3); }
	static void TASK_SIT_DOWN_INSTANTLY(Ped ped, int32_t p1, int32_t p2, int32_t p3) { NativeInvoke::Invoke<void>(0xCAC2792F, ped, p1, p2, p3); }
	static void TASK_SIT_DOWN_ON_NEAREST_OBJECT(Ped ped, int32_t p1, int32_t p2, float x, float y, float z, uint32_t modelHash, float p7, int32_t p8, bool p9) { NativeInvoke::Invoke<void>(0xA287D0BD, ped, p1, p2, x, y, z, modelHash, p7, p8, p9); }
	static void TASK_SIT_DOWN_ON_OBJECT(Ped ped, int32_t p1, int32_t p2, Object object, float x, float y, float z, float p7, int32_t p8, bool p9) { NativeInvoke::Invoke<void>(0x595E56B4, ped, p1, p2, object, x, y, z, p7, p8, p9); }
	static void TASK_SIT_DOWN_ON_SEAT(Ped ped, int32_t p1, int32_t p2, float x, float y, float z, float p6, int32_t p7) { NativeInvoke::Invoke<void>(0xB457570A, ped, p1, p2, x, y, z, p6, p7); }
	static void TASK_SMART_FLEE_PED(Any p0, Any p1, Any p2, Any p3, Any p4) { NativeInvoke::Invoke<void>(0xE52EB560, p0, p1, p2, p3, p4); }
	static void TASK_SMART_FOLLOW_PED(Ped ped, Ped ped2, float p2, float p3, float p4, Any p5, int32_t p6, float p7, bool p8, bool p9) { NativeInvoke::Invoke<void>(0x22CFC4BD, ped, ped2, p2, p3, p4, p5, p6, p7, p8, p9); }
	static void TASK_STAND_STILL(Ped ped, int32_t duration) { NativeInvoke::Invoke<void>(0x6F80965D, ped, duration); }
	static void TASK_SURRENDER(Ped ped, Ped targetPed, float heading) { NativeInvoke::Invoke<void>(0xC5FA9CD6, ped, targetPed, heading); }
	static void TASK_SWAP_WEAPON(Ped ped, bool p1) { NativeInvoke::Invoke<void>(0xDAF4F8FC, ped, p1); }
	static void TASK_TOGGLE_DUCK(Ped ped, int32_t p1) { NativeInvoke::Invoke<void>(0x61CFBCBF, ped, p1); }
	static void TASK_TURN_PED_TO_FACE_COORD(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5) { NativeInvoke::Invoke<void>(0x30463D73, p0, p1, p2, p3, p4, p5); }
	static void TASK_TURN_PED_TO_FACE_PED(Any p0, Any p1, Any p2, Any p3) { NativeInvoke::Invoke<void>(0xDE13490F, p0, p1, p2, p3); }
	static void TASK_USE_MOBILE_PHONE(Ped ped, bool p1) { NativeInvoke::Invoke<void>(0x225A38C8, ped, p1); }
	static void TASK_USE_MOBILE_PHONE_TIMED(Ped ped, int32_t time) { NativeInvoke::Invoke<void>(0xC99C19F5, ped, time); }
	static void TASK_USE_NEAREST_MOUNTED_WEAPON(Ped ped) { NativeInvoke::Invoke<void>(0xB9F6EB6C, ped); }
	static void TASK_USE_WALKIE_TALKIE(Ped ped, const char* p1) { NativeInvoke::Invoke<void>(0x3868BDE6, ped, p1); }
	static void TASK_VEHICLE_DRIVE_TO_COORD(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9, Any p10) { NativeInvoke::Invoke<void>(0xE4AC0387, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10); }
	static void TASK_VEHICLE_MISSION(Any p0, Any p1, Any p2, Any p3, Any p4, Any p5, Any p6, Any p7, Any p8, Any p9) { NativeInvoke::Invoke<void>(0x20609E56, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9); }
	static void TASK_VEHICLE_SHOOT_AT_COORD(Any p0, Any p1, Any p2, Any p3) { NativeInvoke::Invoke<void>(0xA7AAA4D6, p0, p1, p2, p3); }
	static void TASK_VEHICLE_SHOOT_AT_PED(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x59677BA0, p0, p1); }
	static void TASK_VEHICLE_TEMP_ACTION(Ped driver, Vehicle vehicle, int32_t action, int32_t time) { NativeInvoke::Invoke<void>(0x679DFB8, driver, vehicle, action, time); }
	static void TASK_WARP_PED_INTO_VEHICLE(Ped ped, Vehicle vehicle, int32_t seatIndex) { NativeInvoke::Invoke<void>(0x65D4A35D, ped, vehicle, seatIndex); }
	static void TEMPORARILY_DISABLE_PED_SELF_COLLISION(Ped ped, int32_t duration) { NativeInvoke::Invoke<void>(0x212533EF, ped, duration); }
	static void TERMINATE_ALL_SCRIPTS_FOR_NETWORK_GAME() { NativeInvoke::Invoke<void>(0x51C902BD); }
	static void TERMINATE_ALL_SCRIPTS_WITH_THIS_NAME(const char* name) { NativeInvoke::Invoke<void>(0x9F861FD4, name); }
	static void TERMINATE_GAME_BULLET_CAMERA() { NativeInvoke::Invoke<void>(0xEE7F2F5D); }
	static void TERMINATE_THIS_THREAD() { NativeInvoke::Invoke<void>(0x3CD9CBB7); }
	static void TERMINATE_THREAD(int32_t threadId) { NativeInvoke::Invoke<void>(0x253FD520, threadId); }
	static void TOGGLE_DISPLAY_AMMO(bool toggle) { NativeInvoke::Invoke<void>(0x8807D97, toggle); }
	static void TOGGLE_PICKUP_ATTACHMENT(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0xDB0A1DF3, p0, p1, p2); }
	static void TOGGLE_SECONDARY_LIFE_BAR(bool toggle) { NativeInvoke::Invoke<void>(0x5BD64BF5, toggle); }
	static void TOGGLE_SECONDARY_LIFE_BAR_FLASH(bool toggle) { NativeInvoke::Invoke<void>(0xE081A44C, toggle); }
	static void TOGGLE_TRACER(bool toggle) { NativeInvoke::Invoke<void>(0xA4D5C061, toggle); }
	static void TOGGLE_WEAPON_ATTACHMENT(Weapon weapon, int32_t attachmentIndex, bool toggle) { NativeInvoke::Invoke<void>(0xCDA89AA8, weapon, attachmentIndex, toggle); }
	static void TRANSFER_PED_BLOOD_HANDLE(Ped ped, Ped ped2) { NativeInvoke::Invoke<void>(0x1E3CF6F7, ped, ped2); }
	static void TRIGGER_EXPLOSION_AUDIO_FROM_COORDS(Any p0, Any p1, Any p2, Any p3) { NativeInvoke::Invoke<void>(0x2C7F4F0, p0, p1, p2, p3); }
	static void TRIGGER_EXPLOSION_AUDIO_FROM_PED(Any p0, Any p1) { NativeInvoke::Invoke<void>(0x7A936A56, p0, p1); }
	static void TRIGGER_EXPLOSION_AUDIO_MIX_LAYER(Any p0, Any p1, Any p2, Any p3) { NativeInvoke::Invoke<void>(0xDA1CBE98, p0, p1, p2, p3); }
	static void TRIGGER_LIGHTNING(bool p0) { NativeInvoke::Invoke<void>(0xB53EE377, p0); }
	static void TRIGGER_PED_PORTAL_RESCAN(Ped ped, float p1) { NativeInvoke::Invoke<void>(0xE1531B10, ped, p1); }
	static void TRIGGER_THUNDER(float p0, bool p1) { NativeInvoke::Invoke<void>(0x57360FB9, p0, p1); }
	static void UI_ADD_MP_HITMARK(int32_t p0, int32_t p1) { NativeInvoke::Invoke<void>(0xDA1F284A, p0, p1); }
	static void UI_CLEAR_TOOLTIP() { NativeInvoke::Invoke<void>(0xB6CA18C1); }
	static void UI_LOAD_MINIMAP_TXD(const char* txdName) { NativeInvoke::Invoke<void>(0xBA0CC379, txdName); }
	static void UI_REMOVE_MP_HITMARKS() { NativeInvoke::Invoke<void>(0x4155A12); }
	static void UI_SET_MP_BIG_NUMBER(int32_t p0, int32_t argCount, ...) {}
	static void UI_SET_WORLDCONTAINER_POS(float x, float y, float z, int32_t argCount, ...) {}
	static void UI_START_QTE_MINIGAME(float p0, float p1, float p2, int32_t p3) { NativeInvoke::Invoke<void>(0xA6F90D0, p0, p1, p2, p3); }
	static void UI_STOP_QTE_MINIGAME() { NativeInvoke::Invoke<void>(0x478F8D91); }
	static void UNBIND_SCRIPT_DATABASE(const char* name) { NativeInvoke::Invoke<void>(0xC6F9A3CD, name); }
	static void UNMUTE_EXPLOSIONS() { NativeInvoke::Invoke<void>(0x72A9758E); } 
	static void UNPAUSE_PLAYBACK_RECORDED_PED(Ped ped) { NativeInvoke::Invoke<void>(0x57988394, ped); }
	static void UNPAUSE_PLAYBACK_RECORDED_VEHICLE(Vehicle vehicle) { NativeInvoke::Invoke<void>(0x59060F75, vehicle); }
	static void UNPIN_ROPE_VERTEX(Any rope, int32_t vertex) { NativeInvoke::Invoke<void>(0xB30B552F, rope, vertex); }
	static void UPDATE_ARCADE_CHECK_POINT(int32_t p0) { NativeInvoke::Invoke<void>(0x131CE7C6, p0); }
	static void UPDATE_SPECIAL_FX_MODIFIER_STRENGTH(Any p0, Any p1, Any p2) { NativeInvoke::Invoke<void>(0x3D538351, p0, p1, p2); }
	static void USE_ANIMATED_LAST_MAN_STANDING(bool toggle) { NativeInvoke::Invoke<void>(0x3345BB01, toggle); }
	static void USE_DEFAULT_WATER_SETTINGS() { NativeInvoke::Invoke<void>(0x48C6519C); }
	static void WAIT(int32_t ms) { NativeInvoke::Invoke<void>(0x7715C03B, ms); }
	static void WAITUNPAUSED(int32_t ms) { NativeInvoke::Invoke<void>(0x7C496803, ms); } 
	static void WAITUNWARPED(int32_t ms) { NativeInvoke::Invoke<void>(0x1185F9B, ms); } 
	static void WAKE_RESTING_OBJECTS_AROUND(Object object) { NativeInvoke::Invoke<void>(0x14EF5CEE, object); }
	static void WASH_PROJTEX_FROM_VEHICLE(Vehicle vehicle, Any p1) { NativeInvoke::Invoke<void>(0x90EF385, vehicle, p1); }
};
