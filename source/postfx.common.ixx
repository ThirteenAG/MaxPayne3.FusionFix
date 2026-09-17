module;

#include <common.hxx>

export module postfxcommon;

// ---------------------------------------------------------------------------
// Options are re-read from MaxPayne3.FusionFix.ini once per frame, so toggling
// any of them, including the console gamma preset, never needs a shader reload.
// The right shader is simply picked while rendering.
// ---------------------------------------------------------------------------
export struct PostFXOptions
{
    bool  bSmaa = false;
    bool  bSmaaDebug = false;   // show what the SMAA edge detection finds
    bool  bBlur = false;
    int   nConsoleGamma = 0;    // 0 = off, 1 = Xenon (Xbox 360), 2 = Cell (PlayStation 3)
    float fBlurStrength = 1.0f; // 0 = off, 1 = base strength

    bool AnyEnabled() const
    {
        return bSmaa || bBlur || nConsoleGamma != 0;
    }
};

export enum PostFXStage
{
    POSTFX_STAGE_SMAA = 1 << 0,
    POSTFX_STAGE_BLUR = 1 << 1,
    POSTFX_STAGE_GAMMA = 1 << 2,
    POSTFX_STAGE_ALL = POSTFX_STAGE_SMAA | POSTFX_STAGE_BLUR | POSTFX_STAGE_GAMMA,
};

export inline IUnknown** ppPostFXDevice = nullptr;
export inline IUnknown** ppPostFXSwapChain = nullptr;

export inline constexpr GUID IID_PostFXDirect3DDevice9 = { 0xd0223b96, 0xbf7a, 0x43fd, { 0x92, 0xbd, 0xa4, 0x3b, 0x0d, 0x82, 0xb9, 0xeb } };
// ---------------------------------------------------------------------------
// Constant block shared by all passes, layout must match PostFXCommon.hlsl:
//   vec4SMAARTMetrics  xy = 1 / size, zw = size in pixels
//   vec4PostFXParams   xy = 1 / size, z  = blur strength
// Direct3D 9 receives it in c0 / c1 (no constant buffers there), Direct3D 10
// and above in the constant buffer b0.
// ---------------------------------------------------------------------------
export struct PostFXConstants
{
    float fMetrics[4];
    float fParams[4];
};

export inline PostFXConstants MakePostFXConstants(UINT uWidth, UINT uHeight, float fBlurStrength)
{
    const float fWidth = (float)uWidth;
    const float fHeight = (float)uHeight;

    PostFXConstants constants{};
    constants.fMetrics[0] = 1.0f / fWidth;
    constants.fMetrics[1] = 1.0f / fHeight;
    constants.fMetrics[2] = fWidth;
    constants.fMetrics[3] = fHeight;
    constants.fParams[0] = 1.0f / fWidth;
    constants.fParams[1] = 1.0f / fHeight;
    constants.fParams[2] = fBlurStrength;
    return constants;
}

export inline HMODULE GetPostFXModuleHandle(const void* pAddress)
{
    HMODULE hModule = nullptr;
    GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
        (LPCSTR)pAddress, &hModule);
    return hModule;
}

export inline bool LoadPostFXResource(HMODULE hModule, int iResourceId, const void** ppData, UINT* puSize)
{
    HRSRC hResource = FindResourceW(hModule, MAKEINTRESOURCEW(iResourceId), RT_RCDATA);
    if (!hResource)
        return false;

    HGLOBAL hGlobal = LoadResource(hModule, hResource);
    if (!hGlobal)
        return false;

    *ppData = LockResource(hGlobal);
    if (!*ppData)
        return false;

    *puSize = SizeofResource(hModule, hResource);
    return *puSize != 0;
}

// ---------------------------------------------------------------------------
// The two SMAA precomputed textures (AreaTex 160x560, SearchTex 64x16) are
// shipped as plain DDS files. The header is parsed here so that neither D3DX9
// textures nor D3DX11 are required at runtime:
//   AreaTex   - 16 bit luminance/alpha, D3DFMT_A8L8 / DXGI_FORMAT_R8G8_UNORM
//   SearchTex - 8 bit luminance,        D3DFMT_L8   / DXGI_FORMAT_R8_UNORM
// ---------------------------------------------------------------------------
export struct PostFXTextureData
{
    UINT uWidth = 0;
    UINT uHeight = 0;
    UINT uBytesPerPixel = 0;
    const BYTE* pPixels = nullptr;
};

export inline bool ParsePostFXTexture(const void* pData, SIZE_T uSize, PostFXTextureData& texture)
{
    // 4 byte magic, then DDS_HEADER: dwSize, dwFlags, dwHeight, dwWidth,
    // dwPitchOrLinearSize, dwDepth, dwMipMapCount (7 DWORDs), dwReserved1 (11
    // DWORDs), DDS_PIXELFORMAT (32 bytes), dwCaps, dwCaps2, dwCaps3, dwCaps4,
    // dwReserved2. The pixel format sits 76 bytes into the file, the four DWORDs
    // after it are not part of it, which is why it is not at the end of the
    // header. The pixel data starts right after the 128 byte header.
    constexpr SIZE_T DDS_HEADER_SIZE = 4 + 124;
    constexpr SIZE_T DDS_HEADER_STRUCT_SIZE = 124;
    constexpr SIZE_T DDS_PIXELFORMAT_SIZE = 32;
    constexpr SIZE_T DDS_PIXELFORMAT_OFFSET = 4 + 7 * sizeof(UINT32) + 11 * sizeof(UINT32);

    if (!pData || uSize < DDS_HEADER_SIZE || memcmp(pData, "DDS ", 4) != 0)
        return false;

    const BYTE* pBytes = (const BYTE*)pData;
    auto ReadUInt32 = [pBytes](SIZE_T uOffset) { return *(const UINT32*)(pBytes + uOffset); };

    if (ReadUInt32(4) != DDS_HEADER_STRUCT_SIZE)
        return false;
    if (ReadUInt32(DDS_PIXELFORMAT_OFFSET) != DDS_PIXELFORMAT_SIZE)
        return false;

    const UINT32 uHeight = ReadUInt32(12);
    const UINT32 uWidth = ReadUInt32(16);
    const UINT32 uFourCC = ReadUInt32(DDS_PIXELFORMAT_OFFSET + 8);
    const UINT32 uBitCount = ReadUInt32(DDS_PIXELFORMAT_OFFSET + 12);
    const UINT32 uRMask = ReadUInt32(DDS_PIXELFORMAT_OFFSET + 16);
    const UINT32 uAMask = ReadUInt32(DDS_PIXELFORMAT_OFFSET + 28);

    // only the two uncompressed luminance layouts SMAA ships are expected
    if (uFourCC != 0 || uWidth == 0 || uHeight == 0)
        return false;
    if (!((uBitCount == 8 && uRMask == 0xFF) ||
        (uBitCount == 16 && uRMask == 0xFF && uAMask == 0xFF00)))
        return false;

    const UINT uBytesPerPixel = uBitCount / 8;
    const SIZE_T uDataSize = (SIZE_T)uWidth * uHeight * uBytesPerPixel;
    if (uSize < DDS_HEADER_SIZE + uDataSize)
        return false;

    texture.uWidth = uWidth;
    texture.uHeight = uHeight;
    texture.uBytesPerPixel = uBytesPerPixel;
    texture.pPixels = pBytes + DDS_HEADER_SIZE;
    return true;
}

// ---------------------------------------------------------------------------
// Diagnostics. A pass that cannot be set up is skipped without drawing
// anything, which looks exactly like the effect being switched off, so every
// distinct problem is written to a log file once. Nothing works being wrong
// means nothing being written, the file only shows up if something failed.
// The log sits next to the plugin, MaxPayne3.FusionFix.postfx.log.
// ---------------------------------------------------------------------------
export enum PostFXFailure
{
    POSTFX_FAILURE_DEVICE = 1 << 0,
    POSTFX_FAILURE_COMMON_SHADERS = 1 << 1,
    POSTFX_FAILURE_SMAA_SHADERS = 1 << 2,
    POSTFX_FAILURE_BLUR_SHADERS = 1 << 3,
    POSTFX_FAILURE_GAMMA_SHADERS = 1 << 4,
    POSTFX_FAILURE_SMAA_TEXTURES = 1 << 5,
    POSTFX_FAILURE_STATE_OBJECTS = 1 << 6,
    POSTFX_FAILURE_TARGETS = 1 << 7,
    POSTFX_FAILURE_BACKBUFFER = 1 << 8,
    POSTFX_FAILURE_SCENE_COPY = 1 << 9,
};

// Everything that has already been reported, module wide so that the two
// backends do not each write their own copy of the same line.
export inline unsigned int uReportedPostFXFailures = 0;

export inline void ReportPostFXFailure(unsigned int uFailure, const char* szMessage, int iValue = 0)
{
    if ((uReportedPostFXFailures & uFailure) || !szMessage)
        return;

    uReportedPostFXFailures |= uFailure;

    HMODULE hModule = GetPostFXModuleHandle((const void*)&ReportPostFXFailure);
    if (!hModule)
        return;

    char szPath[MAX_PATH] = {};
    const DWORD uLength = GetModuleFileNameA(hModule, szPath, MAX_PATH);
    if (uLength == 0 || uLength >= MAX_PATH)
        return;

    // swap the extension of the plugin file for the log one
    DWORD uExtension = uLength;
    while (uExtension > 0 && szPath[uExtension - 1] != '.')
        uExtension--;

    constexpr char szSuffix[] = "postfx.log";
    if (uExtension + sizeof(szSuffix) > MAX_PATH)
        return;

    for (SIZE_T i = 0; i < sizeof(szSuffix); i++)
        szPath[uExtension + i] = szSuffix[i];

    HANDLE hFile = CreateFileA(szPath, FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
        OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (hFile == INVALID_HANDLE_VALUE)
        return;

    char szLine[256] = {};
    const int iLineLength = wsprintfA(szLine, "%s (%d)\r\n", szMessage, iValue);
    if (iLineLength > 0)
    {
        DWORD uWritten = 0;
        WriteFile(hFile, szLine, (DWORD)iLineLength, &uWritten, nullptr);
    }

    CloseHandle(hFile);
}
