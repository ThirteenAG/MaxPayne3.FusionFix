#include "Disasm.h"
#include "FxcFormat.h"
#include "Sha256.h"
#include <windows.h>
#include <d3dx9.h>
#include <d3dcompiler.h>
#include <filesystem>
#include <cstdio>
#include <cstring>
#include <vector>
#include <string>
#include <fstream>
#include <iterator>
#include <stdexcept>

namespace shadertool {
namespace {
namespace fs = std::filesystem;

using FnD3DXDisassemble = HRESULT(WINAPI*)(const DWORD*, BOOL, LPCSTR, ID3DXBuffer**);
using FnD3DDisassemble = HRESULT(WINAPI*)(LPCVOID, SIZE_T, UINT, LPCSTR, ID3DBlob**);
using FnD3DCompile = HRESULT(WINAPI*)(LPCVOID, SIZE_T, LPCSTR, const D3D_SHADER_MACRO*, ID3DInclude*,
                                      LPCSTR, LPCSTR, UINT, UINT, ID3DBlob**, ID3DBlob**);

HMODULE g_compiler = nullptr;
HMODULE g_d3dx9 = nullptr;
FnD3DDisassemble g_disassembleDxbc = nullptr;
FnD3DXDisassemble g_disassembleDx9 = nullptr;
FnD3DCompile g_compile = nullptr;

std::string blobText(ID3DXBuffer* b) {
    if (!b) return {};
    const char* p = static_cast<const char*>(b->GetBufferPointer());
    size_t n = b->GetBufferSize();
    size_t len = 0;
    while (len < n && p[len] != '\0') ++len;
    return std::string(p, len);
}
std::string blobText(ID3DBlob* b) {
    if (!b) return {};
    const char* p = static_cast<const char*>(b->GetBufferPointer());
    size_t n = b->GetBufferSize();
    size_t len = 0;
    while (len < n && p[len] != '\0') ++len;
    return std::string(p, len);
}

std::string normalize(std::string text) {
    std::string out;
    out.reserve(text.size() + 1);
    for (size_t i = 0; i < text.size(); ++i) {
        if (text[i] == '\r') {
            if (i + 1 < text.size() && text[i + 1] == '\n') continue;
            out.push_back('\n');
        } else out.push_back(text[i]);
    }
    while (!out.empty() && (out.back() == '\n' || out.back() == ' ' || out.back() == '\t')) out.pop_back();
    out.push_back('\n');
    return out;
}

fs::path findDxSdk(const char* argv0) {
    std::vector<fs::path> starts;
    std::error_code ec;
    starts.push_back(fs::current_path(ec));
    if (argv0) {
        fs::path exe = fs::absolute(fs::path(argv0), ec);
        if (!ec) starts.push_back(exe.parent_path());
    }
    for (const auto& start : starts) {
        fs::path p = start;
        for (int i = 0; i < 10 && !p.empty(); ++i) {
            fs::path candidate = p / "source" / "dxsdk" / "lib" / "x86";
            if (fs::exists(candidate / "D3DX9_43.dll", ec)) return candidate;
            fs::path parent = p.parent_path();
            if (parent == p) break;
            p = parent;
        }
    }
    return {};
}

HMODULE loadFrom(const fs::path& dir, const char* name, const char* fallback) {
    if (!dir.empty()) {
        std::error_code ec;
        fs::path full = dir / name;
        if (fs::exists(full, ec)) {
            HMODULE m = LoadLibraryW(full.wstring().c_str());
            if (m) return m;
        }
    }
    return LoadLibraryA(fallback);
}
} // namespace

void initializeD3DTools(const char* argv0) {
    if (g_disassembleDxbc || g_disassembleDx9) return;
    fs::path sdk = findDxSdk(argv0);
    g_compiler = loadFrom(sdk, "D3DCompiler_47.dll", "d3dcompiler_47.dll");
    if (!g_compiler) g_compiler = loadFrom(sdk, "D3DCompiler_43.dll", "d3dcompiler_43.dll");
    g_d3dx9 = loadFrom(sdk, "D3DX9_43.dll", "d3dx9_43.dll");
    if (g_compiler) g_disassembleDxbc = reinterpret_cast<FnD3DDisassemble>(GetProcAddress(g_compiler, "D3DDisassemble"));
    if (g_compiler) g_compile = reinterpret_cast<FnD3DCompile>(GetProcAddress(g_compiler, "D3DCompile"));
    if (g_d3dx9) g_disassembleDx9 = reinterpret_cast<FnD3DXDisassemble>(GetProcAddress(g_d3dx9, "D3DXDisassembleShader"));
}

std::string compilerFingerprint() {
    static const std::string fingerprint = []() {
        if (!g_compiler) return std::string("no-in-process-compiler");
        wchar_t filename[32768];
        DWORD length = GetModuleFileNameW(g_compiler, filename, static_cast<DWORD>(std::size(filename)));
        if (!length || length == std::size(filename)) throw std::runtime_error("cannot identify shader compiler");
        std::ifstream file(std::filesystem::path(filename), std::ios::binary);
        if (!file) throw std::runtime_error("cannot read shader compiler for cache identity");
        std::vector<uint8_t> bytes((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
        return Sha256::hex(bytes);
    }();
    return fingerprint;
}


bool compileHlslInProcess(const std::string& source, const std::string& profile,
                          std::vector<uint8_t>& out, std::string& error) {
    out.clear();
    error.clear();
    if (!g_compile) { error = "D3DCompile is not available"; return false; }
    ID3DBlob* code = nullptr;
    ID3DBlob* messages = nullptr;
    HRESULT hr = g_compile(source.data(), source.size(), nullptr, nullptr, nullptr, "main",
                           profile.c_str(), 0, 0, &code, &messages);
    if (FAILED(hr) || !code) {
        if (messages && messages->GetBufferPointer())
            error.assign(static_cast<const char*>(messages->GetBufferPointer()), messages->GetBufferSize());
        if (error.empty()) {
            char buf[64];
            std::snprintf(buf, sizeof(buf), "D3DCompile failed (0x%08X)", unsigned(hr));
            error = buf;
        }
        if (code) code->Release();
        if (messages) messages->Release();
        return false;
    }
    const uint8_t* p = static_cast<const uint8_t*>(code->GetBufferPointer());
    out.assign(p, p + code->GetBufferSize());
    code->Release();
    if (messages) messages->Release();
    return true;
}

bool disassembleShader(const std::vector<uint8_t>& bytecode, std::string& out, std::string& error) {
    out.clear();
    error.clear();
    if (bytecode.empty()) { error = "empty bytecode"; return false; }
    if (isDxbc(bytecode)) {
        if (!g_disassembleDxbc) { error = "d3dcompiler_47.dll (D3DDisassemble) is not available"; return false; }
        ID3DBlob* dis = nullptr;
        HRESULT hr = g_disassembleDxbc(bytecode.data(), static_cast<SIZE_T>(bytecode.size()), 0, nullptr, &dis);
        if (FAILED(hr) || !dis) {
            char buf[64]; std::snprintf(buf, sizeof(buf), "D3DDisassemble failed (0x%08X)", unsigned(hr));
            error = buf;
            if (dis) dis->Release();
            return false;
        }
        out = normalize(blobText(dis));
        dis->Release();
        return true;
    }
    if (!isDx9Bytecode(bytecode)) { error = "not a recognized DX9 or DXBC shader"; return false; }
    if (bytecode.size() % 4 != 0) { error = "DX9 bytecode length is not a multiple of 4"; return false; }
    if (!g_disassembleDx9) { error = "d3dx9_43.dll (D3DXDisassembleShader) is not available"; return false; }
    ID3DXBuffer* dis = nullptr;
    HRESULT hr = g_disassembleDx9(reinterpret_cast<const DWORD*>(bytecode.data()), FALSE, nullptr, &dis);
    if (FAILED(hr) || !dis) {
        char buf[64]; std::snprintf(buf, sizeof(buf), "D3DXDisassembleShader failed (0x%08X)", unsigned(hr));
        error = buf;
        if (dis) dis->Release();
        return false;
    }
    out = normalize(blobText(dis));
    dis->Release();
    return true;
}

} // namespace shadertool
