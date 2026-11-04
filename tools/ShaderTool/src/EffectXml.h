#pragma once
#include "FxcFormat.h"
#include <string>
#include <vector>

namespace shadertool {

struct ShaderSourceRef {
    std::string file;      // path relative to the XML file
    std::string dataType;  // "hlsl" or "cso"
};

struct ParsedEffectSource {
    Effect effect;
    // One entry per shader, in group/stage order (group 0 shaders first).
    std::vector<ShaderSourceRef> shaderSources;
};

std::string effectToXml(const Effect& effect, const std::vector<ShaderSourceRef>& sources);

ParsedEffectSource xmlToEffect(const std::string& xml);

// Shortest round-trippable float text (handles inf/nan).
std::string formatFloat(float value);
float parseFloat(const std::string& text);

} // namespace shadertool