#pragma once
#include <string>
#include <vector>
#include <utility>

namespace shadertool {

struct XmlNode {
    std::string name;
    std::vector<std::pair<std::string, std::string>> attrs;
    std::vector<XmlNode> children;
    std::string text;

    const std::string* attr(const std::string& key) const;
    const XmlNode* child(const std::string& tag) const;
    std::string childText(const std::string& tag, const std::string& def = {}) const;
};

XmlNode parseXml(const std::string& text);
std::string xmlEscape(const std::string& s);
std::string xmlUnescape(const std::string& s);

class XmlWriter {
public:
    XmlWriter();
    void open(const std::string& tag, const std::vector<std::pair<std::string, std::string>>& attrs = {});
    void close();
    void leaf(const std::string& tag, const std::string& text,
              const std::vector<std::pair<std::string, std::string>>& attrs = {});
    void empty(const std::string& tag, const std::vector<std::pair<std::string, std::string>>& attrs = {});
    const std::string& str() const { return buf_; }
private:
    void indent();
    std::string buf_;
    int depth_ = 0;
    std::vector<std::string> stack_;
};

} // namespace shadertool
