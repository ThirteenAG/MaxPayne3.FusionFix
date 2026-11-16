#pragma once
#include <cstdint>
#include <string>
#include <vector>
#include <array>

namespace shadertool {

// Max Payne 3 uses two closely related rgxe container layouts:
//   Legacy: no per-shader cbuffer list, group header has Unk1 + Unk3,
//           cbuffers carry only VS/PS slots. Used by the DX9 shader
//           folders (and by four early DX10 micromovement files).
//   Modern: per-shader cbuffer list, group header has Unk1 + Unk2 + Unk3,
//           cbuffers carry VS/PS/CS/DS/GS/HS slots.
enum class ContainerFormat { Legacy, Modern };

struct PresetParam {
    std::string name;
    uint8_t unused0 = 0;
    uint32_t value = 0;
};

struct BufferRef {
    std::string name;
    uint16_t slot = 0;
};

struct Shader {
    std::string name;
    bool offsetBy1 = false;
    std::vector<std::string> variables;
    std::vector<BufferRef> buffers;
    std::vector<uint8_t> bytecode;
    // From the source XML, for choosing the fxc profile. Not on-disk data.
    std::string model;
};

struct ShaderGroup {
    uint8_t rawCount = 0;
    bool offsetBy1 = false;
    std::string name;
    uint8_t unk1 = 0;
    uint8_t unk2 = 0;
    uint32_t unk3 = 0;
    std::vector<Shader> shaders;
};

struct CBuffer {
    uint32_t size = 0;
    std::array<uint16_t, 6> slots{}; // VS, PS, CS, DS, GS, HS
    std::string name;
};

enum class ParamValueType : uint8_t { Int = 0, Float = 1, String = 2 };

struct VariableParam {
    std::string name;
    ParamValueType type = ParamValueType::String;
    int32_t intValue = 0;
    float floatValue = 0.0f;
    std::string stringValue;
};

struct Variable {
    uint8_t varType = 0;
    uint8_t count = 0;
    uint8_t slot = 0;
    uint8_t group = 0;
    std::string name1;
    std::string name2;
    uint8_t offset = 0;
    uint8_t variant = 0;
    uint8_t unused0 = 0;
    uint8_t unused1 = 0;
    uint32_t cbufferNameHash = 0;
    std::vector<VariableParam> params;
    std::vector<uint32_t> values; // raw words; f32 bit patterns for float types
};

struct Pass {
    std::array<uint8_t, 6> stages{}; // VS, PS, CS, DS, GS, HS
    std::vector<std::pair<uint32_t, uint32_t>> params; // type, value
};

struct Technique {
    std::string name;
    std::vector<Pass> passes;
};

struct Effect {
    ContainerFormat format = ContainerFormat::Modern;
    uint32_t vertexType = 0;
    std::vector<PresetParam> presetParams;
    std::array<ShaderGroup, 6> groups;
    std::vector<CBuffer> cbuffers1;
    std::vector<Variable> variables1;
    std::vector<CBuffer> cbuffers2;
    std::vector<Variable> variables2;
    std::vector<Technique> techniques;
};

// Parses an rgxe container, auto-detecting the legacy/modern layout.
// Throws std::runtime_error with a descriptive message on failure.
Effect parseEffect(const std::vector<uint8_t>& data);

// Serializes back to the exact on-disk layout. Throws on format limits.
std::vector<uint8_t> serializeEffect(const Effect& effect);

// Returns "3.0", "4.0", "4.1", "5.0" or "?" for a shader bytecode blob.
std::string shaderModel(const std::vector<uint8_t>& bytecode);
bool isDxbc(const std::vector<uint8_t>& bytecode);
bool isDx9Bytecode(const std::vector<uint8_t>& bytecode);

std::string variableTypeName(uint8_t type);
uint8_t variableTypeFromName(const std::string& name);
bool variableUsesUintValues(uint8_t type);

const char* stageName(int index);

} // namespace shadertool