#pragma once

#include <istream>
#include <set>
#include <string>
#include <string_view>

namespace TextureMips
{
    inline std::string_view TextureName(std::string_view name)
    {
        // Resource names can be stored as pack:/<name>.dds, while dictionary
        // tools show only <name>. Match the same texture in either spelling.
        const auto slash = name.find_last_of("/\\");
        if (slash != std::string_view::npos) name.remove_prefix(slash + 1);
        if (name.size() >= 4)
        {
            const auto suffix = name.substr(name.size() - 4);
            if (suffix[0] == '.' && (suffix[1] == 'd' || suffix[1] == 'D')
                && (suffix[2] == 'd' || suffix[2] == 'D') && (suffix[3] == 's' || suffix[3] == 'S'))
                name.remove_suffix(4);
        }
        return name;
    }

    struct NameLess
    {
        using is_transparent = void;
        static unsigned char Lower(unsigned char c) { return c >= 'A' && c <= 'Z' ? c + ('a' - 'A') : c; }
        bool operator()(std::string_view a, std::string_view b) const
        {
            const auto length = a.size() < b.size() ? a.size() : b.size();
            for (size_t i = 0; i < length; ++i)
            {
                const auto left = Lower(a[i]), right = Lower(b[i]);
                if (left != right) return left < right;
            }
            return a.size() < b.size();
        }
    };

    // Immutable after startup: textures can be loaded by several streaming threads.
    class NameList
    {
        std::set<std::string, NameLess> names;
    public:
        void Read(std::istream& input)
        {
            names.clear();
            std::string line;
            bool first = true;
            while (std::getline(input, line))
            {
                if (first && line.compare(0, 3, "\xEF\xBB\xBF") == 0) line.erase(0, 3);
                first = false;
                line.erase(line.find_first_of("#;") == std::string::npos ? line.size() : line.find_first_of("#;"));
                const auto start = line.find_first_not_of(" \t\r\n");
                if (start == std::string::npos) continue;
                const auto end = line.find_last_not_of(" \t\r\n");
                const auto name = TextureName(std::string_view(line).substr(start, end - start + 1));
                if (!name.empty()) names.emplace(name);
            }
        }
        bool Empty() const { return names.empty(); }
        bool Contains(std::string_view name) const { return names.find(TextureName(name)) != names.end(); }
    };

    inline bool CanSkip(int quality, unsigned nativeSkip, unsigned type, unsigned mips,
        unsigned width, unsigned height, unsigned stride)
    {
        // Type 0 is an ordinary 2D texture. Keep cube/volume textures, single-level
        // textures and the final compression block on the game's original path.
        return quality == 2 && nativeSkip == 0 && type == 0 && mips > 1
            && width >= 8 && height >= 8 && stride >= 2;
    }
}
