#include "EffectXml.h"
#include "Xml.h"
#include <stdexcept>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <charconv>
#include <limits>

namespace shadertool {
namespace {
std::string boolStr(bool v) { return v ? "true" : "false"; }
bool parseBool(const std::string& s) { return s == "true" || s == "1" || s == "True"; }
uint32_t parseU32(const std::string& s, uint32_t def = 0) {
    if (s.empty()) return def;
    try { return uint32_t(std::stoul(s, nullptr, 0)); } catch (...) { return def; }
}
int32_t parseI32(const std::string& s, int32_t def = 0) {
    if (s.empty()) return def;
    try { return int32_t(std::stol(s, nullptr, 0)); } catch (...) { return def; }
}
std::vector<std::string> split(const std::string& s, char sep) {
    std::vector<std::string> out;
    std::string cur;
    for (char c : s) {
        if (c == sep) { if (!cur.empty()) out.push_back(cur); cur.clear(); }
        else if (!std::isspace(static_cast<unsigned char>(c))) cur.push_back(c);
    }
    if (!cur.empty()) out.push_back(cur);
    return out;
}

void writeCBuffers(XmlWriter& w, const char* tag, const std::vector<CBuffer>& list, ContainerFormat fmt) {
    w.open(tag);
    for (const auto& cb : list) {
        std::vector<std::pair<std::string,std::string>> a = {
            {"Name", cb.name}, {"Size", std::to_string(cb.size)},
            {"VS", std::to_string(cb.slots[0])}, {"PS", std::to_string(cb.slots[1])}
        };
        if (fmt == ContainerFormat::Modern) {
            a.push_back({"CS", std::to_string(cb.slots[2])});
            a.push_back({"DS", std::to_string(cb.slots[3])});
            a.push_back({"GS", std::to_string(cb.slots[4])});
            a.push_back({"HS", std::to_string(cb.slots[5])});
        }
        w.empty("CBuffer", a);
    }
    w.close();
}

std::vector<CBuffer> readCBuffers(const XmlNode& n, ContainerFormat fmt) {
    std::vector<CBuffer> out;
    for (const auto& c : n.children) {
        if (c.name != "CBuffer") continue;
        CBuffer cb;
        if (auto a = c.attr("Name")) cb.name = *a;
        if (auto a = c.attr("Size")) cb.size = parseU32(*a);
        if (auto a = c.attr("VS")) cb.slots[0] = uint16_t(parseU32(*a));
        if (auto a = c.attr("PS")) cb.slots[1] = uint16_t(parseU32(*a));
        if (fmt == ContainerFormat::Modern) {
            if (auto a = c.attr("CS")) cb.slots[2] = uint16_t(parseU32(*a));
            if (auto a = c.attr("DS")) cb.slots[3] = uint16_t(parseU32(*a));
            if (auto a = c.attr("GS")) cb.slots[4] = uint16_t(parseU32(*a));
            if (auto a = c.attr("HS")) cb.slots[5] = uint16_t(parseU32(*a));
        }
        out.push_back(std::move(cb));
    }
    return out;
}

void writeVariables(XmlWriter& w, const char* tag, const std::vector<Variable>& list) {
    w.open(tag);
    for (const auto& v : list) {
        std::vector<std::pair<std::string,std::string>> a = {
            {"Type", variableTypeName(v.varType)}, {"Count", std::to_string(v.count)},
            {"Slot", std::to_string(v.slot)}, {"Group", std::to_string(v.group)},
            {"FirstName", v.name1}, {"SecondName", v.name2},
            {"Offset", std::to_string(v.offset)}, {"Variant", std::to_string(v.variant)},
            {"Unused0", std::to_string(v.unused0)}, {"Unused1", std::to_string(v.unused1)},
            {"CBufferNameHash", std::to_string(v.cbufferNameHash)}
        };
        bool hasBody = !v.params.empty() || !v.values.empty();
        if (!hasBody) { w.empty("Variable", a); continue; }
        w.open("Variable", a);
        if (!v.params.empty()) {
            w.open("Annotations");
            for (const auto& p : v.params) {
                std::string type, value;
                if (p.type == ParamValueType::Int) { type = "int"; value = std::to_string(p.intValue); }
                else if (p.type == ParamValueType::Float) { type = "float"; value = formatFloat(p.floatValue); }
                else { type = "string"; value = p.stringValue; }
                w.empty("Annotation", {{"Name", p.name}, {"Type", type}, {"Value", value}});
            }
            w.close();
        }
        if (!v.values.empty()) {
            bool useUint = variableUsesUintValues(v.varType);
            std::string text;
            for (size_t i = 0; i < v.values.size(); ++i) {
                if (i) text.push_back(';');
                if (useUint) text += std::to_string(v.values[i]);
                else { float f; std::memcpy(&f, &v.values[i], 4); text += formatFloat(f); }
            }
            w.leaf("Values", text);
        }
        w.close();
    }
    w.close();
}

std::vector<Variable> readVariables(const XmlNode& n) {
    std::vector<Variable> out;
    for (const auto& c : n.children) {
        if (c.name != "Variable") continue;
        Variable v;
        if (auto a = c.attr("Type")) v.varType = variableTypeFromName(*a);
        if (auto a = c.attr("Count")) v.count = uint8_t(parseU32(*a));
        if (auto a = c.attr("Slot")) v.slot = uint8_t(parseU32(*a));
        if (auto a = c.attr("Group")) v.group = uint8_t(parseU32(*a));
        if (auto a = c.attr("FirstName")) v.name1 = *a;
        if (auto a = c.attr("SecondName")) v.name2 = *a;
        if (auto a = c.attr("Offset")) v.offset = uint8_t(parseU32(*a));
        if (auto a = c.attr("Variant")) v.variant = uint8_t(parseU32(*a));
        if (auto a = c.attr("Unused0")) v.unused0 = uint8_t(parseU32(*a));
        if (auto a = c.attr("Unused1")) v.unused1 = uint8_t(parseU32(*a));
        if (auto a = c.attr("CBufferNameHash")) v.cbufferNameHash = parseU32(*a);
        if (const XmlNode* ann = c.child("Annotations")) {
            for (const auto& an : ann->children) {
                if (an.name != "Annotation") continue;
                VariableParam p;
                if (auto a = an.attr("Name")) p.name = *a;
                std::string type = an.attr("Type") ? *an.attr("Type") : "string";
                std::string value = an.attr("Value") ? *an.attr("Value") : "";
                if (type == "int") { p.type = ParamValueType::Int; p.intValue = parseI32(value); }
                else if (type == "float") { p.type = ParamValueType::Float; p.floatValue = parseFloat(value); }
                else { p.type = ParamValueType::String; p.stringValue = value; }
                v.params.push_back(std::move(p));
            }
        }
        if (const XmlNode* vals = c.child("Values")) {
            bool useUint = variableUsesUintValues(v.varType);
            for (const auto& s : split(vals->text, ';')) {
                if (useUint) v.values.push_back(parseU32(s));
                else { uint32_t bits; float f = parseFloat(s); std::memcpy(&bits, &f, 4); v.values.push_back(bits); }
            }
        }
        out.push_back(std::move(v));
    }
    return out;
}
} // namespace

std::string formatFloat(float value) {
    if (std::isnan(value)) return "nan";
    if (std::isinf(value)) return value < 0 ? "-inf" : "inf";
    char buf[64];
    auto res = std::to_chars(buf, buf + sizeof(buf), value, std::chars_format::general, 9);
    if (res.ec != std::errc()) { std::snprintf(buf, sizeof(buf), "%.9g", double(value)); return buf; }
    return std::string(buf, res.ptr);
}
float parseFloat(const std::string& text) {
    if (text == "nan" || text == "NaN") return std::numeric_limits<float>::quiet_NaN();
    if (text == "inf" || text == "+inf" || text == "Infinity") return std::numeric_limits<float>::infinity();
    if (text == "-inf" || text == "-Infinity") return -std::numeric_limits<float>::infinity();
    if (text.rfind("0x", 0) == 0 || text.rfind("0X", 0) == 0) {
        uint32_t bits = uint32_t(std::strtoul(text.c_str(), nullptr, 16));
        float f; std::memcpy(&f, &bits, 4); return f;
    }
    return std::strtof(text.c_str(), nullptr);
}

std::string effectToXml(const Effect& e, const std::vector<ShaderSourceRef>& sources) {
    XmlWriter w;
    w.open("Effect", {{"Format", e.format == ContainerFormat::Modern ? "modern" : "legacy"},
                      {"VertexType", std::to_string(e.vertexType)}});
    if (!e.presetParams.empty()) {
        w.open("PresetParams");
        for (const auto& p : e.presetParams)
            w.empty("Preset", {{"Name", p.name}, {"Unused0", std::to_string(p.unused0)}, {"Value", std::to_string(p.value)}});
        w.close();
    }
    size_t sourceIndex = 0;
    w.open("ShaderGroups");
    for (int gi = 0; gi < 6; ++gi) {
        const ShaderGroup& g = e.groups[gi];
        w.open("Group", {{"Stage", stageName(gi)}, {"RawCount", std::to_string(g.rawCount)},
                         {"OffsetBy1", boolStr(g.offsetBy1)}, {"Name", g.name},
                         {"Unk1", std::to_string(g.unk1)}, {"Unk2", std::to_string(g.unk2)},
                         {"Unk3", std::to_string(g.unk3)}});
        w.open("Shaders");
        for (const auto& s : g.shaders) {
            ShaderSourceRef source;
            if (sourceIndex < sources.size()) source = sources[sourceIndex];
            ++sourceIndex;
            w.open("Shader", {{"Name", s.name}, {"OffsetBy1", boolStr(s.offsetBy1)},
                              {"File", source.file}, {"DataType", source.dataType},
                              {"Model", s.model.empty() ? shaderModel(s.bytecode) : s.model},
                              {"Length", std::to_string(s.bytecode.size())}});
            if (!s.variables.empty()) {
                w.open("Variables");
                for (const auto& v : s.variables) w.leaf("Variable", v);
                w.close();
            }
            if (!s.buffers.empty()) {
                w.open("Buffers");
                for (const auto& b : s.buffers)
                    w.empty("Buffer", {{"Name", b.name}, {"Slot", std::to_string(b.slot)}});
                w.close();
            }
            w.close();
        }
        w.close();
        w.close();
    }
    w.close();

    writeCBuffers(w, "CBuffers1", e.cbuffers1, e.format);
    writeVariables(w, "Variables1", e.variables1);
    writeCBuffers(w, "CBuffers2", e.cbuffers2, e.format);
    writeVariables(w, "Variables2", e.variables2);

    w.open("Techniques");
    for (const auto& t : e.techniques) {
        w.open("Technique", {{"Name", t.name}});
        for (const auto& p : t.passes) {
            w.open("Pass", {{"VS", std::to_string(p.stages[0])}, {"PS", std::to_string(p.stages[1])},
                            {"CS", std::to_string(p.stages[2])}, {"DS", std::to_string(p.stages[3])},
                            {"GS", std::to_string(p.stages[4])}, {"HS", std::to_string(p.stages[5])}});
            if (!p.params.empty()) {
                w.open("Params");
                for (const auto& pp : p.params)
                    w.empty("Param", {{"Type", std::to_string(pp.first)}, {"Value", std::to_string(pp.second)}});
                w.close();
            }
            w.close();
        }
        w.close();
    }
    w.close();
    w.close();
    return w.str();
}

ParsedEffectSource xmlToEffect(const std::string& xml) {
    XmlNode root = parseXml(xml);
    if (root.name != "Effect") throw std::runtime_error("XML root is not <Effect>");
    ParsedEffectSource result;
    Effect& e = result.effect;
    if (auto a = root.attr("Format")) e.format = (*a == "legacy") ? ContainerFormat::Legacy : ContainerFormat::Modern;
    if (auto a = root.attr("VertexType")) e.vertexType = parseU32(*a);
    if (const XmlNode* presets = root.child("PresetParams")) {
        for (const auto& p : presets->children) {
            if (p.name != "Preset") continue;
            PresetParam pp;
            if (auto a = p.attr("Name")) pp.name = *a;
            if (auto a = p.attr("Unused0")) pp.unused0 = uint8_t(parseU32(*a));
            if (auto a = p.attr("Value")) pp.value = parseU32(*a);
            e.presetParams.push_back(std::move(pp));
        }
    }
    if (const XmlNode* groups = root.child("ShaderGroups")) {
        int gi = 0;
        for (const auto& g : groups->children) {
            if (g.name != "Group") continue;
            if (gi >= 6) throw std::runtime_error("too many shader groups");
            ShaderGroup& sg = e.groups[gi];
            if (auto a = g.attr("RawCount")) sg.rawCount = uint8_t(parseU32(*a));
            if (auto a = g.attr("OffsetBy1")) sg.offsetBy1 = parseBool(*a);
            if (auto a = g.attr("Name")) sg.name = *a;
            if (auto a = g.attr("Unk1")) sg.unk1 = uint8_t(parseU32(*a));
            if (auto a = g.attr("Unk2")) sg.unk2 = uint8_t(parseU32(*a));
            if (auto a = g.attr("Unk3")) sg.unk3 = parseU32(*a);
            if (const XmlNode* shaders = g.child("Shaders")) {
                for (const auto& s : shaders->children) {
                    if (s.name != "Shader") continue;
                    Shader sh;
                    if (auto a = s.attr("Name")) sh.name = *a;
                    if (auto a = s.attr("OffsetBy1")) sh.offsetBy1 = parseBool(*a);
                    if (auto a = s.attr("Model")) sh.model = *a;
                    ShaderSourceRef ref;
                    if (auto a = s.attr("File")) ref.file = *a;
                    if (auto a = s.attr("DataType")) ref.dataType = *a;
                    if (ref.dataType.empty() && !ref.file.empty()) {
                        ref.dataType = (ref.file.size() >= 5 && ref.file.substr(ref.file.size() - 5) == ".hlsl") ? "hlsl" : "cso";
                    }
                    // Backwards compatibility with the first source layout, which used
                    // Source="<sha256>" and a separate _source store.
                    if (ref.file.empty()) {
                        if (auto a = s.attr("Source")) { ref.file = *a; ref.dataType = "cso"; }
                    }
                    result.shaderSources.push_back(std::move(ref));
                    if (const XmlNode* vars = s.child("Variables"))
                        for (const auto& v : vars->children) if (v.name == "Variable") sh.variables.push_back(v.text);
                    if (const XmlNode* bufs = s.child("Buffers")) {
                        for (const auto& b : bufs->children) {
                            if (b.name != "Buffer") continue;
                            BufferRef br;
                            if (auto a = b.attr("Name")) br.name = *a;
                            if (auto a = b.attr("Slot")) br.slot = uint16_t(parseU32(*a));
                            sh.buffers.push_back(std::move(br));
                        }
                    }
                    sg.shaders.push_back(std::move(sh));
                }
            }
            ++gi;
        }
        if (gi != 6) throw std::runtime_error("expected exactly 6 shader groups, got " + std::to_string(gi));
    }
    if (const XmlNode* n = root.child("CBuffers1")) e.cbuffers1 = readCBuffers(*n, e.format);
    if (const XmlNode* n = root.child("Variables1")) e.variables1 = readVariables(*n);
    if (const XmlNode* n = root.child("CBuffers2")) e.cbuffers2 = readCBuffers(*n, e.format);
    if (const XmlNode* n = root.child("Variables2")) e.variables2 = readVariables(*n);
    if (const XmlNode* techs = root.child("Techniques")) {
        for (const auto& t : techs->children) {
            if (t.name != "Technique") continue;
            Technique tt;
            if (auto a = t.attr("Name")) tt.name = *a;
            for (const auto& p : t.children) {
                if (p.name != "Pass") continue;
                Pass pp;
                if (auto a = p.attr("VS")) pp.stages[0] = uint8_t(parseU32(*a));
                if (auto a = p.attr("PS")) pp.stages[1] = uint8_t(parseU32(*a));
                if (auto a = p.attr("CS")) pp.stages[2] = uint8_t(parseU32(*a));
                if (auto a = p.attr("DS")) pp.stages[3] = uint8_t(parseU32(*a));
                if (auto a = p.attr("GS")) pp.stages[4] = uint8_t(parseU32(*a));
                if (auto a = p.attr("HS")) pp.stages[5] = uint8_t(parseU32(*a));
                if (const XmlNode* params = p.child("Params")) {
                    for (const auto& q : params->children) {
                        if (q.name != "Param") continue;
                        uint32_t type = 0, value = 0;
                        if (auto a = q.attr("Type")) type = parseU32(*a);
                        if (auto a = q.attr("Value")) value = parseU32(*a);
                        pp.params.emplace_back(type, value);
                    }
                }
                tt.passes.push_back(std::move(pp));
            }
            e.techniques.push_back(std::move(tt));
        }
    }
    return result;
}

} // namespace shadertool