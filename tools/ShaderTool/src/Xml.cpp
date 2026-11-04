#include "Xml.h"
#include <stdexcept>
#include <sstream>
#include <cctype>
#include <cstdlib>

namespace shadertool {

const std::string* XmlNode::attr(const std::string& key) const {
    for (const auto& a : attrs) if (a.first == key) return &a.second;
    return nullptr;
}
const XmlNode* XmlNode::child(const std::string& tag) const {
    for (const auto& c : children) if (c.name == tag) return &c;
    return nullptr;
}
std::string XmlNode::childText(const std::string& tag, const std::string& def) const {
    const XmlNode* c = child(tag);
    return c ? c->text : def;
}

std::string xmlEscape(const std::string& s) {
    std::string out; out.reserve(s.size());
    for (char c : s) {
        switch (c) {
            case '&': out += "&amp;"; break;
            case '<': out += "&lt;"; break;
            case '>': out += "&gt;"; break;
            case '"': out += "&quot;"; break;
            case '\'': out += "&apos;"; break;
            default: out.push_back(c); break;
        }
    }
    return out;
}

std::string xmlUnescape(const std::string& s) {
    std::string out; out.reserve(s.size());
    for (size_t i = 0; i < s.size(); ++i) {
        if (s[i] != '&') { out.push_back(s[i]); continue; }
        size_t semi = s.find(';', i + 1);
        if (semi == std::string::npos) { out.push_back('&'); continue; }
        std::string ent = s.substr(i + 1, semi - i - 1);
        if (ent == "amp") out.push_back('&');
        else if (ent == "lt") out.push_back('<');
        else if (ent == "gt") out.push_back('>');
        else if (ent == "quot") out.push_back('"');
        else if (ent == "apos") out.push_back('\'');
        else if (!ent.empty() && ent[0] == '#') {
            long cp = 0;
            if (ent.size() > 1 && (ent[1] == 'x' || ent[1] == 'X')) cp = std::strtol(ent.c_str() + 2, nullptr, 16);
            else cp = std::strtol(ent.c_str() + 1, nullptr, 10);
            if (cp > 0 && cp < 0x80) out.push_back(char(cp));
            else if (cp >= 0x80 && cp <= 0x7FF) { out.push_back(char(0xC0 | (cp >> 6))); out.push_back(char(0x80 | (cp & 0x3F))); }
            else if (cp >= 0x800 && cp <= 0xFFFF) { out.push_back(char(0xE0 | (cp >> 12))); out.push_back(char(0x80 | ((cp >> 6) & 0x3F))); out.push_back(char(0x80 | (cp & 0x3F))); }
            else out.push_back('?');
        } else { out.append(s, i, semi - i + 1); }
        i = semi;
    }
    return out;
}

namespace {
struct Parser {
    const std::string& s;
    size_t p = 0;
    explicit Parser(const std::string& text) : s(text) {}
    bool eof() const { return p >= s.size(); }
    void skipWs() { while (!eof() && std::isspace(static_cast<unsigned char>(s[p]))) ++p; }
    void skipMisc() {
        for (;;) {
            skipWs();
            if (s.compare(p, 2, "<?") == 0) { size_t e = s.find("?>", p); if (e == std::string::npos) throw std::runtime_error("unterminated XML declaration"); p = e + 2; }
            else if (s.compare(p, 4, "<!--") == 0) { size_t e = s.find("-->", p); if (e == std::string::npos) throw std::runtime_error("unterminated XML comment"); p = e + 3; }
            else if (s.compare(p, 9, "<!DOCTYPE") == 0) { size_t e = s.find('>', p); if (e == std::string::npos) throw std::runtime_error("unterminated DOCTYPE"); p = e + 1; }
            else break;
        }
    }
    std::string name() {
        size_t start = p;
        while (!eof() && (std::isalnum(static_cast<unsigned char>(s[p])) || s[p] == '_' || s[p] == '-' || s[p] == ':')) ++p;
        if (start == p) throw std::runtime_error("expected XML name at offset " + std::to_string(p));
        return s.substr(start, p - start);
    }
    std::string quoted() {
        if (eof() || (s[p] != '"' && s[p] != '\'')) throw std::runtime_error("expected quoted XML attribute at offset " + std::to_string(p));
        char q = s[p++];
        size_t start = p;
        while (!eof() && s[p] != q) ++p;
        if (eof()) throw std::runtime_error("unterminated XML attribute");
        std::string v = s.substr(start, p - start);
        ++p;
        return xmlUnescape(v);
    }
    XmlNode element() {
        if (eof() || s[p] != '<') throw std::runtime_error("expected '<' at offset " + std::to_string(p));
        ++p;
        XmlNode node;
        node.name = name();
        for (;;) {
            skipWs();
            if (eof()) throw std::runtime_error("unterminated XML tag");
            if (s.compare(p, 2, "/>") == 0) { p += 2; return node; }
            if (s[p] == '>') { ++p; break; }
            std::string key = name();
            skipWs();
            if (eof() || s[p] != '=') throw std::runtime_error("expected '=' in XML attribute");
            ++p; skipWs();
            node.attrs.emplace_back(key, quoted());
        }
        std::string text;
        for (;;) {
            if (eof()) throw std::runtime_error("unterminated XML element <" + node.name + ">");
            if (s[p] == '<') {
                if (s.compare(p, 2, "</") == 0) {
                    p += 2;
                    std::string close = name();
                    skipWs();
                    if (eof() || s[p] != '>') throw std::runtime_error("expected '>' in closing tag");
                    ++p;
                    if (close != node.name) throw std::runtime_error("mismatched XML tag </" + close + "> for <" + node.name + ">");
                    break;
                }
                if (s.compare(p, 4, "<!--") == 0) { size_t e = s.find("-->", p); if (e == std::string::npos) throw std::runtime_error("unterminated XML comment"); p = e + 3; continue; }
                node.children.push_back(element());
            } else {
                size_t start = p;
                while (!eof() && s[p] != '<') ++p;
                text.append(s, start, p - start);
            }
        }
        // Trim surrounding whitespace; keep internal text intact.
        size_t a = 0, b = text.size();
        while (a < b && std::isspace(static_cast<unsigned char>(text[a]))) ++a;
        while (b > a && std::isspace(static_cast<unsigned char>(text[b-1]))) --b;
        node.text = xmlUnescape(text.substr(a, b - a));
        return node;
    }
};
} // namespace

XmlNode parseXml(const std::string& text) {
    Parser parser(text);
    parser.skipMisc();
    XmlNode root = parser.element();
    parser.skipMisc();
    if (!parser.eof()) throw std::runtime_error("trailing data after XML root element");
    return root;
}

XmlWriter::XmlWriter() { buf_ = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"; }
void XmlWriter::indent() { for (int i = 0; i < depth_; ++i) buf_ += "  "; }
void XmlWriter::open(const std::string& tag, const std::vector<std::pair<std::string,std::string>>& attrs) {
    indent();
    buf_ += "<" + tag;
    for (const auto& a : attrs) buf_ += " " + a.first + "=\"" + xmlEscape(a.second) + "\"";
    buf_ += ">\n";
    ++depth_;
    stack_.push_back(tag);
}
void XmlWriter::close() {
    if (stack_.empty()) return;
    --depth_;
    std::string tag = stack_.back(); stack_.pop_back();
    indent();
    buf_ += "</" + tag + ">\n";
}
void XmlWriter::leaf(const std::string& tag, const std::string& text, const std::vector<std::pair<std::string,std::string>>& attrs) {
    indent();
    buf_ += "<" + tag;
    for (const auto& a : attrs) buf_ += " " + a.first + "=\"" + xmlEscape(a.second) + "\"";
    buf_ += ">" + xmlEscape(text) + "</" + tag + ">\n";
}
void XmlWriter::empty(const std::string& tag, const std::vector<std::pair<std::string,std::string>>& attrs) {
    indent();
    buf_ += "<" + tag;
    for (const auto& a : attrs) buf_ += " " + a.first + "=\"" + xmlEscape(a.second) + "\"";
    buf_ += "/>\n";
}

} // namespace shadertool
