#include "FxcFormat.h"
#include <stdexcept>
#include <cstring>
#include <cstdio>
#include <limits>
#include <sstream>

namespace shadertool {
namespace {

constexpr uint32_t kMagic = 1702389618u; // 'rgxe'

struct Reader {
    const std::vector<uint8_t>& d;
    size_t p = 0;
    explicit Reader(const std::vector<uint8_t>& data) : d(data) {}
    void need(size_t n) const {
        if (p + n > d.size()) throw std::runtime_error("unexpected end of file at offset " + std::to_string(p));
    }
    uint8_t u8() { need(1); return d[p++]; }
    uint16_t u16() { need(2); uint16_t v = uint16_t(d[p]) | (uint16_t(d[p+1])<<8); p += 2; return v; }
    uint32_t u32() { need(4); uint32_t v = uint32_t(d[p]) | (uint32_t(d[p+1])<<8) | (uint32_t(d[p+2])<<16) | (uint32_t(d[p+3])<<24); p += 4; return v; }
    std::string pstring() {
        uint8_t n = u8();
        if (n == 0) return {};
        need(n);
        size_t len = size_t(n) - 1;
        std::string s(reinterpret_cast<const char*>(d.data() + p), len);
        p += n;
        return s;
    }
    std::vector<uint8_t> bytes(size_t n) { need(n); std::vector<uint8_t> v(d.begin() + p, d.begin() + p + n); p += n; return v; }
    size_t remaining() const { return d.size() - p; }
};

void writePString(std::vector<uint8_t>& out, const std::string& s) {
    if (s.empty()) { out.push_back(0); return; }
    size_t len = s.size() > 254 ? 254 : s.size();
    out.push_back(uint8_t(len + 1));
    out.insert(out.end(), s.begin(), s.begin() + len);
    out.push_back(0);
}
void putU16(std::vector<uint8_t>& out, uint16_t v) { out.push_back(uint8_t(v)); out.push_back(uint8_t(v>>8)); }
void putU32(std::vector<uint8_t>& out, uint32_t v) { out.push_back(uint8_t(v)); out.push_back(uint8_t(v>>8)); out.push_back(uint8_t(v>>16)); out.push_back(uint8_t(v>>24)); }

CBuffer readCBuffer(Reader& r, ContainerFormat fmt) {
    CBuffer cb;
    cb.size = r.u32();
    int slots = fmt == ContainerFormat::Modern ? 6 : 2;
    for (int i = 0; i < slots; ++i) cb.slots[i] = r.u16();
    cb.name = r.pstring();
    return cb;
}

Variable readVariable(Reader& r) {
    Variable v;
    v.varType = r.u8();
    v.count = r.u8();
    v.slot = r.u8();
    v.group = r.u8();
    v.name1 = r.pstring();
    v.name2 = r.pstring();
    v.offset = r.u8();
    v.variant = r.u8();
    v.unused0 = r.u8();
    v.unused1 = r.u8();
    v.cbufferNameHash = r.u32();
    uint8_t paramCount = r.u8();
    v.params.reserve(paramCount);
    for (uint8_t i = 0; i < paramCount; ++i) {
        VariableParam p;
        p.name = r.pstring();
        uint8_t t = r.u8();
        if (t == 0) { p.type = ParamValueType::Int; p.intValue = int32_t(r.u32()); }
        else if (t == 1) { p.type = ParamValueType::Float; uint32_t bits = r.u32(); std::memcpy(&p.floatValue, &bits, 4); }
        else { p.type = ParamValueType::String; p.stringValue = r.pstring(); }
        v.params.push_back(std::move(p));
    }
    uint8_t valueCount = r.u8();
    v.values.reserve(valueCount);
    for (uint8_t i = 0; i < valueCount; ++i) v.values.push_back(r.u32());
    return v;
}

Pass readPass(Reader& r) {
    Pass p;
    for (int i = 0; i < 6; ++i) p.stages[i] = r.u8();
    uint8_t count = r.u8();
    p.params.reserve(count);
    for (uint8_t i = 0; i < count; ++i) {
        uint32_t type = r.u32();
        uint32_t value = r.u32();
        p.params.emplace_back(type, value);
    }
    return p;
}

Technique readTechnique(Reader& r) {
    Technique t;
    t.name = r.pstring();
    uint8_t count = r.u8();
    t.passes.reserve(count);
    for (uint8_t i = 0; i < count; ++i) t.passes.push_back(readPass(r));
    return t;
}

Shader readShader(Reader& r, ContainerFormat fmt) {
    Shader s;
    s.name = r.pstring();
    if (s.name.empty()) { s.name = r.pstring(); s.offsetBy1 = true; }
    uint8_t varCount = r.u8();
    s.variables.reserve(varCount);
    for (uint8_t i = 0; i < varCount; ++i) s.variables.push_back(r.pstring());
    if (fmt == ContainerFormat::Modern) {
        uint8_t bufferCount = r.u8();
        s.buffers.reserve(bufferCount);
        for (uint8_t i = 0; i < bufferCount; ++i) {
            BufferRef b;
            b.name = r.pstring();
            b.slot = r.u16();
            s.buffers.push_back(std::move(b));
        }
    }
    uint32_t length = r.u32();
    s.bytecode = r.bytes(length);
    return s;
}

ShaderGroup readGroup(Reader& r, int index, ContainerFormat fmt) {
    ShaderGroup g;
    g.rawCount = r.u8();
    if (index == 0) {
        // The vertex group stores the real count directly and has no header.
        size_t count = g.rawCount;
        g.shaders.reserve(count);
        for (size_t i = 0; i < count; ++i) g.shaders.push_back(readShader(r, fmt));
        return g;
    }
    if (g.rawCount == 0) { g.rawCount = r.u8(); g.offsetBy1 = true; }
    g.name = r.pstring();
    g.unk1 = r.u8();
    if (fmt == ContainerFormat::Modern) g.unk2 = r.u8();
    g.unk3 = r.u32();
    size_t count = g.rawCount == 0 ? 0 : size_t(g.rawCount) - 1;
    g.shaders.reserve(count);
    for (size_t i = 0; i < count; ++i) g.shaders.push_back(readShader(r, fmt));
    return g;
}

Effect parseWithFormat(const std::vector<uint8_t>& data, ContainerFormat fmt) {
    Reader r(data);
    if (data.size() < 9 || std::memcmp(data.data(), "rgxe", 4) != 0) throw std::runtime_error("missing 'rgxe' magic");
    if (r.u32() != kMagic) throw std::runtime_error("bad rgxe magic");
    Effect e;
    e.format = fmt;
    e.vertexType = r.u32();
    uint8_t presetCount = r.u8();
    e.presetParams.reserve(presetCount);
    for (uint8_t i = 0; i < presetCount; ++i) {
        PresetParam p;
        p.name = r.pstring();
        p.unused0 = r.u8();
        p.value = r.u32();
        e.presetParams.push_back(std::move(p));
    }
    for (int gi = 0; gi < 6; ++gi) e.groups[gi] = readGroup(r, gi, fmt);

    uint8_t cb1 = r.u8();
    e.cbuffers1.reserve(cb1);
    for (uint8_t i = 0; i < cb1; ++i) e.cbuffers1.push_back(readCBuffer(r, fmt));
    uint8_t var1 = r.u8();
    e.variables1.reserve(var1);
    for (uint8_t i = 0; i < var1; ++i) e.variables1.push_back(readVariable(r));
    uint8_t cb2 = r.u8();
    e.cbuffers2.reserve(cb2);
    for (uint8_t i = 0; i < cb2; ++i) e.cbuffers2.push_back(readCBuffer(r, fmt));
    uint8_t var2 = r.u8();
    e.variables2.reserve(var2);
    for (uint8_t i = 0; i < var2; ++i) e.variables2.push_back(readVariable(r));
    uint8_t techCount = r.u8();
    e.techniques.reserve(techCount);
    for (uint8_t i = 0; i < techCount; ++i) e.techniques.push_back(readTechnique(r));

    if (r.remaining() != 0) throw std::runtime_error("trailing bytes after last technique (" + std::to_string(r.remaining()) + ")");
    return e;
}

void writeCBuffer(std::vector<uint8_t>& out, const CBuffer& cb, ContainerFormat fmt) {
    putU32(out, cb.size);
    int slots = fmt == ContainerFormat::Modern ? 6 : 2;
    for (int i = 0; i < slots; ++i) putU16(out, cb.slots[i]);
    writePString(out, cb.name);
}

void writeVariable(std::vector<uint8_t>& out, const Variable& v) {
    out.push_back(v.varType);
    out.push_back(v.count);
    out.push_back(v.slot);
    out.push_back(v.group);
    writePString(out, v.name1);
    writePString(out, v.name2);
    out.push_back(v.offset);
    out.push_back(v.variant);
    out.push_back(v.unused0);
    out.push_back(v.unused1);
    putU32(out, v.cbufferNameHash);
    if (v.params.size() > 255) throw std::runtime_error("too many variable params");
    out.push_back(uint8_t(v.params.size()));
    for (const auto& p : v.params) {
        writePString(out, p.name);
        if (p.type == ParamValueType::Int) { out.push_back(0); putU32(out, uint32_t(p.intValue)); }
        else if (p.type == ParamValueType::Float) { out.push_back(1); uint32_t bits; std::memcpy(&bits, &p.floatValue, 4); putU32(out, bits); }
        else { out.push_back(2); writePString(out, p.stringValue); }
    }
    if (v.values.size() > 255) throw std::runtime_error("too many variable values");
    out.push_back(uint8_t(v.values.size()));
    for (uint32_t w : v.values) putU32(out, w);
}

void writeShader(std::vector<uint8_t>& out, const Shader& s, ContainerFormat fmt) {
    if (s.offsetBy1) writePString(out, "");
    writePString(out, s.name);
    if (s.variables.size() > 255) throw std::runtime_error("too many shader variables");
    out.push_back(uint8_t(s.variables.size()));
    for (const auto& v : s.variables) writePString(out, v);
    if (fmt == ContainerFormat::Modern) {
        if (s.buffers.size() > 255) throw std::runtime_error("too many shader buffer refs");
        out.push_back(uint8_t(s.buffers.size()));
        for (const auto& b : s.buffers) { writePString(out, b.name); putU16(out, b.slot); }
    }
    if (s.bytecode.size() > std::numeric_limits<uint32_t>::max()) throw std::runtime_error("shader bytecode too large");
    putU32(out, uint32_t(s.bytecode.size()));
    out.insert(out.end(), s.bytecode.begin(), s.bytecode.end());
}

} // namespace

Effect parseEffect(const std::vector<uint8_t>& data) {
    std::string modernError, legacyError;
    try { return parseWithFormat(data, ContainerFormat::Modern); }
    catch (const std::exception& e) { modernError = e.what(); }
    try { return parseWithFormat(data, ContainerFormat::Legacy); }
    catch (const std::exception& e) { legacyError = e.what(); }
    throw std::runtime_error("not a valid MP3 rgxe container (modern: " + modernError + "; legacy: " + legacyError + ")");
}

std::vector<uint8_t> serializeEffect(const Effect& e) {
    std::vector<uint8_t> out;
    out.reserve(4096);
    out.insert(out.end(), {'r','g','x','e'});
    putU32(out, e.vertexType);
    if (e.presetParams.size() > 255) throw std::runtime_error("too many preset params");
    out.push_back(uint8_t(e.presetParams.size()));
    for (const auto& p : e.presetParams) { writePString(out, p.name); out.push_back(p.unused0); putU32(out, p.value); }

    for (int gi = 0; gi < 6; ++gi) {
        const ShaderGroup& g = e.groups[gi];
        size_t naturalRaw = gi == 0 ? g.shaders.size() : g.shaders.size() + 1;
        size_t raw = g.rawCount == naturalRaw ? g.rawCount : naturalRaw;
        if (raw > 255) throw std::runtime_error("too many shaders in group");
        if (gi > 0 && g.offsetBy1) out.push_back(0);
        out.push_back(uint8_t(raw));
        if (gi > 0) {
            writePString(out, g.name);
            out.push_back(g.unk1);
            if (e.format == ContainerFormat::Modern) out.push_back(g.unk2);
            putU32(out, g.unk3);
        }
        for (const auto& s : g.shaders) writeShader(out, s, e.format);
    }

    if (e.cbuffers1.size() > 255 || e.cbuffers2.size() > 255) throw std::runtime_error("too many cbuffers");
    if (e.variables1.size() > 255 || e.variables2.size() > 255) throw std::runtime_error("too many variables");
    out.push_back(uint8_t(e.cbuffers1.size()));
    for (const auto& cb : e.cbuffers1) writeCBuffer(out, cb, e.format);
    out.push_back(uint8_t(e.variables1.size()));
    for (const auto& v : e.variables1) writeVariable(out, v);
    out.push_back(uint8_t(e.cbuffers2.size()));
    for (const auto& cb : e.cbuffers2) writeCBuffer(out, cb, e.format);
    out.push_back(uint8_t(e.variables2.size()));
    for (const auto& v : e.variables2) writeVariable(out, v);
    if (e.techniques.size() > 255) throw std::runtime_error("too many techniques");
    out.push_back(uint8_t(e.techniques.size()));
    for (const auto& t : e.techniques) {
        writePString(out, t.name);
        if (t.passes.size() > 255) throw std::runtime_error("too many passes");
        out.push_back(uint8_t(t.passes.size()));
        for (const auto& p : t.passes) {
            for (int i = 0; i < 6; ++i) out.push_back(p.stages[i]);
            if (p.params.size() > 255) throw std::runtime_error("too many pass params");
            out.push_back(uint8_t(p.params.size()));
            for (const auto& pp : p.params) { putU32(out, pp.first); putU32(out, pp.second); }
        }
    }
    return out;
}

bool isDxbc(const std::vector<uint8_t>& b) { return b.size() >= 4 && std::memcmp(b.data(), "DXBC", 4) == 0; }
bool isDx9Bytecode(const std::vector<uint8_t>& b) {
    if (b.size() < 4 || isDxbc(b)) return false;
    uint32_t token = uint32_t(b[0]) | (uint32_t(b[1])<<8) | (uint32_t(b[2])<<16) | (uint32_t(b[3])<<24);
    return (token >> 16) == 0xFFFEu || (token >> 16) == 0xFFFFu;
}
std::string shaderModel(const std::vector<uint8_t>& b) {
    if (isDxbc(b) && b.size() >= 32) {
        uint32_t chunks = uint32_t(b[28]) | (uint32_t(b[29])<<8) | (uint32_t(b[30])<<16) | (uint32_t(b[31])<<24);
        for (uint32_t i = 0; i < chunks; ++i) {
            size_t offPos = 32 + size_t(i) * 4;
            if (offPos + 4 > b.size()) break;
            uint32_t off = uint32_t(b[offPos]) | (uint32_t(b[offPos+1])<<8) | (uint32_t(b[offPos+2])<<16) | (uint32_t(b[offPos+3])<<24);
            if (size_t(off) + 12 > b.size()) continue;
            if (std::memcmp(b.data() + off, "SHEX", 4) == 0 || std::memcmp(b.data() + off, "SHDR", 4) == 0) {
                uint32_t token = uint32_t(b[off+8]) | (uint32_t(b[off+9])<<8) | (uint32_t(b[off+10])<<16) | (uint32_t(b[off+11])<<24);
                int major = (token >> 4) & 0xF, minor = token & 0xF;
                return std::to_string(major) + "." + std::to_string(minor);
            }
        }
    } else if (isDx9Bytecode(b)) {
        uint32_t token = uint32_t(b[0]) | (uint32_t(b[1])<<8) | (uint32_t(b[2])<<16) | (uint32_t(b[3])<<24);
        int major = (token >> 8) & 0xFF, minor = token & 0xFF;
        return std::to_string(major) + "." + std::to_string(minor);
    }
    return "?";
}

std::string variableTypeName(uint8_t t) {
    switch (t) {
        case 2: return "Float"; case 3: return "Float2"; case 4: return "Float3"; case 5: return "Float4";
        case 6: return "Texture"; case 7: return "Boolean"; case 8: return "Float3x4"; case 9: return "Float4x4";
        case 11: return "Int"; case 14: return "Int4"; case 15: return "Buffer";
        case 17: return "Unused1"; case 18: return "Unused2"; case 19: return "Unused3"; case 20: return "Unused4";
        case 21: return "UAVBuffer"; case 22: return "UAVTexture";
        default: return "Unknown" + std::to_string(t);
    }
}
uint8_t variableTypeFromName(const std::string& s) {
    if (s == "Float") return 2; if (s == "Float2") return 3; if (s == "Float3") return 4; if (s == "Float4") return 5;
    if (s == "Texture") return 6; if (s == "Boolean") return 7; if (s == "Float3x4") return 8; if (s == "Float4x4") return 9;
    if (s == "Int") return 11; if (s == "Int4") return 14; if (s == "Buffer") return 15;
    if (s == "Unused1") return 17; if (s == "Unused2") return 18; if (s == "Unused3") return 19; if (s == "Unused4") return 20;
    if (s == "UAVBuffer") return 21; if (s == "UAVTexture") return 22;
    if (s.rfind("Unknown", 0) == 0) { try { return uint8_t(std::stoi(s.substr(7))); } catch (...) {} }
    return 0;
}
bool variableUsesUintValues(uint8_t t) {
    return t == 11 || t == 14 || t == 7 || t == 6 || t == 15 || t == 22 || t == 21;
}
const char* stageName(int i) {
    static const char* names[6] = {"Vertex","Pixel","Compute","Domain","Geometry","Hull"};
    return (i >= 0 && i < 6) ? names[i] : "?";
}

} // namespace shadertool
