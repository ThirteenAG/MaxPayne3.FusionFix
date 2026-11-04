#pragma once
#include <string>
#include <vector>
#include <cstdint>

namespace shadertool {
// Disassembles DX9 or DXBC bytecode using the Microsoft D3D tools.
// Returns false and fills error on failure.
bool disassembleShader(const std::vector<uint8_t>& bytecode, std::string& out, std::string& error);
// Locates the repository's 32-bit D3DX9/D3DCompiler DLLs when present.
void initializeD3DTools(const char* argv0);
// Hash of the loaded compiler DLL, used to invalidate compiled HLSL caches.
std::string compilerFingerprint();

// Compiles HLSL in-process with d3dcompiler (D3DCompile). This supports both
// DXBC (SM4/SM5) and the legacy SM3 profiles, and avoids one fxc process per
// shader. Returns false and fills error on failure.
bool compileHlslInProcess(const std::string& source, const std::string& profile,
                          std::vector<uint8_t>& out, std::string& error);
}
