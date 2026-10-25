module;
#include <common.hxx>
#include "OverlayInput.hpp"
#include <charconv>
#include <cmath>
#include <cstddef>
#include <safetyhook.hpp>
#include <unordered_map>
#include <atomic>
#include <mutex>
#include <array>
#include <deque>
#include <memory>
#include <optional>
#include <asi_settings/asi_settings.hpp>

export module menu;
import common;
import settings;

namespace FusionMenu
{
    enum class Control { Choices, Slider };
    // value is the setting's value as text in the settings file's syntax, number the same value for numeric settings
    struct Choice { std::string value; std::string text; float number = 0; };
    inline int DecimalPlaces(float value)
    {
        double scaled = value;
        for (int places = 0; places < 6; ++places, scaled *= 10)
            if (std::abs(scaled - std::round(scaled)) < 0.00001) return places;
        return 6;
    }
    inline std::string FormatNumber(float value, int places)
    {
        char buffer[64];
        auto result = std::to_chars(buffer, buffer + sizeof(buffer), value, std::chars_format::fixed, places);
        if (result.ec != std::errc{}) return "?";
        std::string text(buffer, result.ptr);
        if (text.find('.') != std::string::npos)
        {
            text.erase(text.find_last_not_of('0') + 1);
            if (text.back() == '.') text.pop_back();
        }
        return text == "-0" ? "0" : text;
    }
    inline float ToNumber(const std::string& text)
    {
        char* end = nullptr;
        const float value = std::strtof(text.c_str(), &end);
        return end != text.c_str() && std::isfinite(value) ? value : 0.0f;
    }
    // One row of a page. Values cross as text, like the runtime interface of ASI Settings.
    struct Option
    {
        std::string label;
        std::string help;
        std::vector<Choice> choices;
        std::string other;              // the list's extra last entry, shown for values that aren't in it
        std::string defaultValue;       // empty for rows that aren't settings
        std::function<std::string()> get;
        std::function<void(const std::string&)> set;
        std::function<bool()> enabled;  // enabledIf of the setting, none when always enabled
        bool numeric = true;
        Control control = Control::Choices;
        int decimalPlaces = 0;

        bool Matches(const Choice& choice, const std::string& value) const
        {
            if (!numeric) return asi_settings::text::IEquals(choice.value, value);
            char* end = nullptr;
            const float number = std::strtof(value.c_str(), &end);
            return end != value.c_str() && std::abs(number - choice.number) <= 0.00001f;
        }

        bool Enabled() const { return !enabled || enabled(); }

        std::string SliderText() const { return FormatNumber(ToNumber(get()), decimalPlaces); }

        int SliderPosition() const
        {
            const float value = ToNumber(get());
            auto nearest = std::min_element(choices.begin(), choices.end(), [value](const Choice& a, const Choice& b)
            {
                return std::abs(a.number - value) < std::abs(b.number - value);
            });
            return static_cast<int>(nearest - choices.begin());
        }

        int Position() const
        {
            const auto value = get();
            auto it = std::find_if(choices.begin(), choices.end(), [&](const Choice& c) { return Matches(c, value); });
            return static_cast<int>(it - choices.begin()); // one extra position for other values
        }
        // Disabled rows refuse changes; the list then shows the value again
        void Select(int position) const
        {
            if (position >= 0 && position < static_cast<int>(choices.size()) && Enabled() && !Matches(choices[position], get()))
                set(choices[position].value);
        }
    };
}

namespace
{
// UTF-8 text resolved in the game's GXT language (not the Windows locale) when a
// page is built, from the ASISETTINGS_TEXT resources of the plugin it belongs to.
const unsigned int* gameLanguage = nullptr;
// BCP 47 tags of the game's languages, by the number of its GXT language
constexpr const char* languageTags[] = { "en", "fr", "de", "it", "es", "ja", "ru", "pt-BR", "pl", "ko" };
const char* LanguageTag()
{
    const unsigned int language = gameLanguage && *gameLanguage < std::size(languageTags) ? *gameLanguage : 0;
    return languageTags[language];
}
struct MenuText { std::string token; std::wstring text; };
std::unordered_map<std::string, MenuText> menuText;
std::unordered_map<std::string, const MenuText*> gxtText;
std::mutex textMutex;
safetyhook::InlineHook gxtHook;
std::wstring WideText(std::string_view text)
{
    // Text from other plugins' resources isn't checked, invalid UTF-8 shows as replacement characters
    const auto count = MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), nullptr, 0);
    std::wstring result(count, L'\0');
    MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), result.data(), count);
    return result;
}
// Labels and titles are upper case like the game's own rows, in the casing rules of the game's language
std::string Upper(std::string_view text)
{
    const auto wide = WideText(text);
    const auto locale = WideText(LanguageTag());
    const DWORD flags = LCMAP_UPPERCASE | LCMAP_LINGUISTIC_CASING;
    const auto length = LCMapStringEx(locale.c_str(), flags, wide.data(), static_cast<int>(wide.size()), nullptr, 0, nullptr, nullptr, 0);
    if (length <= 0) return std::string(text);
    std::wstring upper(length, L'\0');
    LCMapStringEx(locale.c_str(), flags, wide.data(), static_cast<int>(wide.size()), upper.data(), length, nullptr, nullptr, 0);
    const auto count = WideCharToMultiByte(CP_UTF8, 0, upper.data(), length, nullptr, 0, nullptr, nullptr);
    std::string result(count, '\0');
    WideCharToMultiByte(CP_UTF8, 0, upper.data(), length, result.data(), count, nullptr, nullptr);
    return result;
}
// Store only a short key in the native 256-byte UIFontString buffer. Like IV's
// GXT extension, the lookup returns full UTF-16 text with the game's fallback.
const char* Text(const std::string& text)
{
    std::lock_guard lock(textMutex);
    auto& entry = menuText[text];
    if (entry.token.empty())
    {
        entry.token = "FFMENU_" + std::to_string(gxtText.size());
        entry.text = WideText(text);
        gxtText.emplace(entry.token, &entry);
    }
    return entry.token.c_str();
}
const wchar_t* __fastcall GetMenuText(void* text, void*, const char* key)
{
    if (key && std::strncmp(key, "FFMENU_", 7) == 0)
    {
        std::lock_guard lock(textMutex);
        auto found = gxtText.find(key);
        if (found != gxtText.end()) return found->second->text.c_str();
    }
    return gxtHook.thiscall<const wchar_t*>(text, key);
}

// ---------------------------------------------------------------------------
// Plugins with ASI Settings (docs/settings.md). Fusion Fix is a menu host: its
// own pages come first, then the pages of every other plugin with a description,
// in the order of the specification. Values cross through each plugin's
// AsiSettingsApi, Fusion Fix's own included.

// The plugins found when the Options screen was built. Screens keep the snapshot
// they were built from, so descriptions and tables outlive every row using them.
struct Snapshot
{
    std::vector<asi_settings::LoadedPlugin> plugins;
    asi_settings::Texts texts; // Fusion Fix's own, for the rows the menu adds
    std::string Host(std::string_view key) const { return texts.Resolve("@" + std::string(key)); }
};
std::shared_ptr<Snapshot> snapshot;
HMODULE thisModule = nullptr;
std::map<HMODULE, int32_t> subscriptions;
// Set by plugins from any thread, handled once per frame on the game thread
std::atomic<bool> settingsChanged = false;

void __cdecl OnSettingChanged(void*, const char*) { settingsChanged = true; }

// Functions past the plugin's table don't exist (SPEC.md, Compatibility)
bool HasFunction(const AsiSettingsApi* api, size_t offset)
{
    return api && api->size >= offset + sizeof(void*);
}

std::string GetValue(const AsiSettingsApi* api, const std::string& id)
{
    char buffer[256];
    int32_t length = api->Get(id.c_str(), buffer, sizeof(buffer));
    if (length < 0) return {};
    if (length < static_cast<int32_t>(sizeof(buffer))) return std::string(buffer, length);
    std::string value(static_cast<size_t>(length) + 1, '\0');
    length = api->Get(id.c_str(), value.data(), static_cast<uint32_t>(value.size()));
    value.resize(length >= 0 ? std::min<size_t>(length, value.size() - 1) : 0);
    return value;
}

// The values a setting can take now (SPEC.md, Availability), or nothing when every value can
std::optional<std::vector<asi_settings::Labelled>> UsableValues(const AsiSettingsApi* api, const std::string& id)
{
    if (!HasFunction(api, offsetof(AsiSettingsApi, GetChoices)) || !api->GetChoices) return std::nullopt;
    char buffer[1024];
    int32_t length = api->GetChoices(id.c_str(), buffer, sizeof(buffer));
    if (length < 0) return std::nullopt;
    std::string json(buffer, std::min<size_t>(length, sizeof(buffer) - 1));
    if (length >= static_cast<int32_t>(sizeof(buffer)))
    {
        json.assign(static_cast<size_t>(length) + 1, '\0');
        length = api->GetChoices(id.c_str(), json.data(), static_cast<uint32_t>(json.size()));
        json.resize(length >= 0 ? std::min<size_t>(length, json.size() - 1) : 0);
    }
    asi_settings::json::Value root;
    if (!asi_settings::json::Parse(json, root) || !root.IsArray()) return std::nullopt;
    std::vector<asi_settings::Labelled> values;
    for (auto& item : root.items)
        if (auto value = item.Find("value")) values.push_back({*value, std::string(item.Str("label"))});
    return values;
}

// A plugin's values as the menu sees them, to evaluate conditions and presets
std::vector<asi_settings::Slot> ReadSlots(const asi_settings::LoadedPlugin& plugin)
{
    std::vector<asi_settings::Slot> slots;
    for (auto& setting : plugin.file.description.settings)
    {
        if (!setting.HasValue()) continue;
        asi_settings::Slot slot;
        slot.setting = &setting;
        asi_settings::SetDefault(slot);
        asi_settings::ParseValue(slot, GetValue(plugin.api, setting.id), false);
        slots.push_back(std::move(slot));
    }
    return slots;
}

bool Evaluate(const asi_settings::Condition& condition, const std::vector<asi_settings::Slot>& slots)
{
    return asi_settings::Evaluate(condition, [&](std::string_view id) -> const asi_settings::Slot*
    {
        for (auto& slot : slots)
            if (asi_settings::text::IEquals(slot.setting->id, id)) return &slot;
        return nullptr;
    });
}

// Whether a setting has a value of the description, compared as the setting's type reads it
bool HasValue(const asi_settings::Slot& slot, const asi_settings::json::Value& value)
{
    asi_settings::Slot wanted;
    wanted.setting = slot.setting;
    asi_settings::SetDefault(wanted);
    return asi_settings::ParseValue(wanted, asi_settings::detail::JsonToText(value), false) &&
        asi_settings::text::IEquals(asi_settings::FormatValue(wanted), asi_settings::FormatValue(slot));
}

bool HasPresets(const asi_settings::LoadedPlugin& plugin)
{
    auto& settings = plugin.file.description.settings;
    return std::any_of(settings.begin(), settings.end(), [](auto& s) { return s.presets && s.HasValue(); });
}

// The preset all the plugin's preset settings match, or -1 for Custom
int CurrentPreset(const asi_settings::LoadedPlugin& plugin)
{
    const auto slots = ReadSlots(plugin);
    for (int preset = 0; preset < 3; ++preset)
        if (std::all_of(slots.begin(), slots.end(), [preset](auto& slot)
            { return !slot.setting->presets || HasValue(slot, (*slot.setting->presets)[preset]); }))
            return preset;
    return -1;
}

void ApplyPreset(const asi_settings::LoadedPlugin& plugin, int preset)
{
    for (auto& slot : ReadSlots(plugin))
    {
        auto& presets = slot.setting->presets;
        if (presets && !HasValue(slot, (*presets)[preset]))
            plugin.api->Set(slot.setting->id.c_str(), asi_settings::detail::JsonToText((*presets)[preset]).c_str());
    }
}

// A row that runs something when it's selected
struct Action
{
    std::string label;
    std::function<std::string()> help;
    std::function<void()> run;
    std::function<void()> leave; // the row lost the focus
    std::optional<size_t> target; // a link: the page it opens instead of running
};
struct PresetSelector
{
    const asi_settings::LoadedPlugin* plugin = nullptr;
    int pending = -1;   // the preset chosen in the list, set by the Apply row
    bool armed = false; // Apply was selected once and waits for the confirmation
};
struct Row { const FusionMenu::Option* option = nullptr; Action* action = nullptr; };
struct PageContent
{
    std::deque<FusionMenu::Option> options;
    std::deque<Action> actions;
    std::deque<PresetSelector> presets;
    std::vector<Row> rows;
    std::string signature; // which rows and values are shown, the page is built again when it changes
};
struct PageRef
{
    const asi_settings::LoadedPlugin* plugin = nullptr;
    std::vector<std::string> ids; // the description's pages shown together, an empty id for a plugin without pages
    std::string title;
    std::string help;   // shown on links to the page
    bool first = false; // the plugin's first page, which starts with its preset selector
    std::vector<size_t> links; // pages opened from rows at the end of this one
};

// Pages that would like to be shown inside the game's own pages (SPEC.md, Pages)
enum class NativePage { Display, Graphics, Controls, Audio };
std::optional<NativePage> NativePageOf(const asi_settings::Page& page)
{
    if (!page.join) return std::nullopt;
    if (page.section == "display") return NativePage::Display;
    if (page.section == "graphics") return NativePage::Graphics;
    if (page.section == "controls" || page.section == "gamepad") return NativePage::Controls;
    if (page.section == "audio") return NativePage::Audio;
    return std::nullopt;
}

// A row for a setting, built from its description: bool and choice settings, and numbers and
// text with special values or suggestions, use the list control; numbers with a range use the
// slider. Settings this menu can't show remain in editors and the file.
bool BuildOption(const Snapshot& snap, const asi_settings::LoadedPlugin& plugin, const asi_settings::Setting& setting,
    const std::vector<asi_settings::Slot>& slots, FusionMenu::Option& option, std::string& signature)
{
    using asi_settings::Type;
    auto api = plugin.api;
    if (setting.visibility != "menu" || !setting.HasValue()) return false;
    if (HasFunction(api, offsetof(AsiSettingsApi, GetState)) && api->GetState &&
        api->GetState(setting.id.c_str(), nullptr, 0) == ASI_SETTINGS_STATE_HIDDEN) return false;
    if (setting.visibleIf && !Evaluate(*setting.visibleIf, slots)) return false;

    auto& texts = plugin.file.texts;
    const std::string id = setting.id;
    option.label = texts.Resolve(setting.label);
    option.help = texts.Resolve(setting.description);
    option.numeric = !setting.StringValued();
    option.defaultValue = asi_settings::detail::JsonToText(setting.defaultValue);
    option.get = [api, id] { return GetValue(api, id); };
    option.set = [api, id](const std::string& value) { api->Set(id.c_str(), value.c_str()); };
    if (setting.enabledIf)
        option.enabled = [&plugin, condition = *setting.enabledIf] { return Evaluate(condition, ReadSlots(plugin)); };

    // Menus offer only the values usable now (SPEC.md, Availability)
    const auto usable = UsableValues(api, id);
    auto add = [&](const asi_settings::json::Value& value, std::string text)
    {
        const auto valueText = asi_settings::detail::JsonToText(value);
        if (usable && std::none_of(usable->begin(), usable->end(), [&](auto& u)
            { return asi_settings::detail::JsonEquals(u.value, valueText, option.numeric); })) return;
        option.choices.push_back({valueText, text.empty() ? valueText : std::move(text), FusionMenu::ToNumber(valueText)});
    };
    auto addLabelled = [&](const std::vector<asi_settings::Labelled>& list)
    {
        for (auto& item : list) add(item.value, texts.Resolve(item.label));
    };
    auto preferred = [&](std::initializer_list<std::string_view> controls)
    {
        for (auto& c : setting.controls)
        {
            if (std::find(controls.begin(), controls.end(), c) != controls.end()) return true;
            if (c == "cycler" || c == "dropdown" || c == "segmented" || c == "switch" || c == "checkbox") return false;
        }
        return false;
    };

    switch (setting.type)
    {
        case Type::Bool:
        {
            asi_settings::json::Value value;
            value.kind = asi_settings::json::Value::Kind::Number;
            add(value, snap.Host("off"));
            value.number = 1;
            add(value, snap.Host("on"));
            break;
        }
        case Type::Choice:
        {
            if (setting.dynamic && usable)
            {
                // Labels the plugin gives, else those of the description's choices, else the value itself
                for (auto& item : *usable)
                {
                    auto text = texts.Resolve(item.label);
                    for (auto& known : setting.choices)
                        if (text.empty() && asi_settings::detail::JsonEquals(known.value, asi_settings::detail::JsonToText(item.value), option.numeric))
                            text = texts.Resolve(known.label);
                    add(item.value, text);
                }
            }
            else addLabelled(setting.choices);
            break;
        }
        case Type::Int:
        case Type::Float:
        case Type::Unknown:
        {
            const bool list = !setting.special.empty() || !setting.suggestions.empty();
            const bool range = setting.min && setting.max && *setting.min < *setting.max && option.numeric;
            if (range && (!list || preferred({"slider", "stepper"})))
            {
                const double minimum = *setting.min, maximum = *setting.max;
                const double step = setting.step ? *setting.step : setting.type == Type::Int ? 1.0 : (maximum - minimum) / 20;
                const auto steps = std::ceil((maximum - minimum) / step - 0.000001);
                if (steps < 1 || steps > 253) return false;
                option.control = FusionMenu::Control::Slider;
                option.decimalPlaces = setting.decimals >= 0 ? setting.decimals : setting.type == Type::Int ? 0 :
                    std::max({FusionMenu::DecimalPlaces(float(minimum)), FusionMenu::DecimalPlaces(float(maximum)), FusionMenu::DecimalPlaces(float(step))});
                for (int i = 0; i <= static_cast<int>(steps); ++i)
                {
                    const float value = i == static_cast<int>(steps) ? float(maximum) : float(minimum + i * step);
                    const auto text = FusionMenu::FormatNumber(value, option.decimalPlaces);
                    option.choices.push_back({text, text, value});
                }
            }
            else if (list)
            {
                addLabelled(setting.special);
                addLabelled(setting.suggestions);
            }
            break;
        }
        default:
            // Text, paths, keys and colours: their special values and suggestions, a menu can't enter others
            addLabelled(setting.special);
            addLabelled(setting.suggestions);
            break;
    }
    if (option.choices.empty()) return false;

    // A value outside the list shows as Custom, or as the label of a special value
    option.other = snap.Host("menu.custom");
    if (auto current = std::find_if(slots.begin(), slots.end(), [&](auto& s) { return s.setting == &setting; }); current != slots.end())
        for (auto& special : setting.special)
            if (HasValue(*current, special.value)) option.other = texts.Resolve(special.label);

    signature += id + "=";
    for (auto& choice : option.choices) signature += choice.value + ",";
    signature += ";";
    return true;
}

void AddPresetRows(const Snapshot& snap, PageContent& content, const asi_settings::LoadedPlugin& plugin)
{
    auto selector = &content.presets.emplace_back(PresetSelector{&plugin});
    FusionMenu::Option option;
    option.label = snap.Host("menu.preset");
    option.help = snap.Host("menu.preset.description");
    const char* names[] = {"menu.preset.vanilla", "menu.preset.recommended", "menu.preset.enhanced"};
    for (int i = 0; i < 3; ++i) option.choices.push_back({std::to_string(i), snap.Host(names[i]), static_cast<float>(i)});
    option.other = snap.Host("menu.custom");
    option.get = [selector] { return std::to_string(selector->pending >= 0 ? selector->pending : CurrentPreset(*selector->plugin)); };
    option.set = [selector](const std::string& value) { selector->pending = std::atoi(value.c_str()); selector->armed = false; };
    content.rows.push_back({&content.options.emplace_back(std::move(option)), nullptr});

    // Apply asks for a confirmation in the help text: it sets the preset when it's selected again
    Action apply;
    apply.label = snap.Host("menu.apply");
    apply.help = [selector, help = snap.Host("menu.apply.description"), confirm = snap.Host("menu.apply.confirm")]
    { return selector->armed ? confirm : help; };
    apply.run = [selector]
    {
        if (selector->pending < 0) return;
        if (!selector->armed) { selector->armed = true; return; }
        const int preset = selector->pending;
        selector->armed = false;
        selector->pending = -1;
        ApplyPreset(*selector->plugin, preset);
    };
    apply.leave = [selector] { selector->armed = false; };
    content.rows.push_back({nullptr, &content.actions.emplace_back(std::move(apply))});
}

// Sets the settings shown from the row start on to their defaults, the plugins store and apply them
void RestoreDefaults(const PageContent& content, size_t start = 0)
{
    for (size_t i = start; i < content.rows.size(); ++i)
        if (auto option = content.rows[i].option; option && !option->defaultValue.empty() && option->get() != option->defaultValue)
            option->set(option->defaultValue);
}

// The rows of one page. full: a page of its own, with the preset selector on the plugin's first
// page, its links and Restore Defaults; otherwise the settings only, for the game's own pages.
void AddPageRows(const Snapshot& snap, const PageRef& ref, bool full, PageContent& content, const std::vector<PageRef>* pages = nullptr)
{
    auto& plugin = *ref.plugin;
    const size_t start = content.rows.size();
    if (full && ref.first && HasPresets(plugin)) AddPresetRows(snap, content, plugin);
    std::vector<const asi_settings::Setting*> settings;
    for (auto& id : ref.ids)
    {
        const auto begin = settings.size();
        for (auto& setting : plugin.file.description.settings)
            if (asi_settings::text::IEquals(setting.page, id)) settings.push_back(&setting);
        std::stable_sort(settings.begin() + begin, settings.end(), [](auto a, auto b) { return a->order < b->order; });
    }
    const auto slots = ReadSlots(plugin);
    bool any = false;
    for (auto setting : settings)
    {
        if (setting->type == asi_settings::Type::Action)
        {
            if (!full || setting->visibility != "menu" || (setting->visibleIf && !Evaluate(*setting->visibleIf, slots))) continue;
            Action action;
            action.label = plugin.file.texts.Resolve(setting->label);
            action.help = [help = plugin.file.texts.Resolve(setting->description)] { return help; };
            action.run = [api = plugin.api, id = setting->id] { if (api->Invoke) api->Invoke(id.c_str()); };
            content.rows.push_back({nullptr, &content.actions.emplace_back(std::move(action))});
            content.signature += setting->id + ";";
            continue;
        }
        FusionMenu::Option option;
        if (!BuildOption(snap, plugin, *setting, slots, option, content.signature)) continue;
        content.rows.push_back({&content.options.emplace_back(std::move(option)), nullptr});
        any = true;
    }
    if (full && pages)
        for (auto target : ref.links)
        {
            Action link;
            link.label = pages->at(target).title;
            link.help = [help = pages->at(target).help] { return help; };
            link.target = target;
            content.rows.push_back({nullptr, &content.actions.emplace_back(std::move(link))});
            content.signature += "link" + std::to_string(target) + ";";
        }
    if (full && any)
    {
        // Restores the settings shown on this page, the plugin stores and applies them
        Action reset;
        reset.label = snap.Host("menu.restoredefaults");
        reset.help = [help = snap.Host("menu.restoredefaults.description")] { return help; };
        reset.run = [&content, start] { RestoreDefaults(content, start); };
        content.rows.push_back({nullptr, &content.actions.emplace_back(std::move(reset))});
    }
}

std::shared_ptr<PageContent> BuildContent(const Snapshot& snap, const std::vector<PageRef>& pages, size_t page)
{
    auto content = std::make_shared<PageContent>();
    AddPageRows(snap, pages.at(page), true, *content, &pages);
    return content;
}

bool HasRows(const Snapshot& snap, const PageRef& ref)
{
    PageContent content;
    AddPageRows(snap, ref, true, content);
    return !content.rows.empty();
}

// The pages reached from the one link in Options (SPEC.md, Pages): the list of plugins, then one page for each of
// them with its compatibility settings at the end. Pages that join the game's own pages aren't among them.
std::vector<PageRef> BuildPages(Snapshot& snap)
{
    std::vector<PageRef> pages(1);
    for (auto& plugin : snap.plugins)
    {
        auto& description = plugin.file.description;
        std::vector<std::string> ids, compatibility;
        if (description.pages.empty()) ids.emplace_back();
        for (auto& page : description.pages)
            if (!NativePageOf(page)) (page.section == "compatibility" ? compatibility : ids).push_back(page.id);
        ids.insert(ids.end(), compatibility.begin(), compatibility.end());
        const auto name = plugin.file.texts.Resolve(description.name);
        auto help = plugin.module == thisModule ? snap.Host("menu.page.description") : snap.Host("menu.plugin.description");
        if (auto at = help.find("{}"); at != help.npos) help.replace(at, 2, name);
        PageRef ref{&plugin, std::move(ids), name, std::move(help), true};
        if (!HasRows(snap, ref)) continue;
        pages[0].links.push_back(pages.size());
        pages.push_back(std::move(ref));
    }
    if (pages.size() == 1) return {};
    pages[0] = {pages[1].plugin, {}, snap.Host("menu.plugins"), snap.Host("menu.plugins.description"), false, std::move(pages[0].links)};
    return pages;
}

std::shared_ptr<Snapshot> FindPlugins()
{
    auto found = std::make_shared<Snapshot>();
    // Only one menu host draws other plugins' pages; without the role only Fusion Fix's own are shown
    const bool host = asi_settings::ClaimHostRole();
    for (auto& plugin : asi_settings::FindLoadedPlugins(thisModule, LanguageTag()))
        if (host || plugin.module == thisModule) found->plugins.push_back(std::move(plugin));
    for (auto& plugin : found->plugins)
    {
        if (plugin.module == thisModule) found->texts = plugin.file.texts;
        // Pages follow changes made elsewhere: presets, other hosts, editors through Reload
        if (!subscriptions.contains(plugin.module) && HasFunction(plugin.api, offsetof(AsiSettingsApi, Subscribe)) && plugin.api->Subscribe)
        {
            const auto token = plugin.api->Subscribe(OnSettingChanged, nullptr);
            if (token > 0) subscriptions[plugin.module] = token;
        }
    }
    return found;
}

// RAGE UI classes are owned by the game. Offsets and virtual slots were checked
// against MS_Display, UISimpleList and UIScrollingStackLayout in MaxPayne3.exe.
using UI = void*;
constexpr float HelpGap = -8.0f; // between the help text and the title
template<class T> T& Field(UI object, size_t offset)
{ return *reinterpret_cast<T*>(static_cast<char*>(object) + offset); }
template<class R = void, class... A> R Virtual(UI object, size_t slot, A... args)
{ return reinterpret_cast<R(__thiscall*)(UI, A...)>((*reinterpret_cast<void***>(object))[slot / 4])(object, args...); }

void* (__cdecl* Allocate)(size_t);
UI (__thiscall* ConstructRow)(UI, const char*, const char*);
UI (__thiscall* ConstructList)(UI, const char*, const char*);
UI (__thiscall* ConstructScroll)(UI, const char*, const char*);
UI (__thiscall* ConstructBar)(UI, const char*, const char*);
void (__thiscall* InitializeBar)(UI, float, float, int, int, const char*, int, const char*, int, const char*);
void (__thiscall* SetBar)(UI, float);
void (__thiscall* InitializeList)(UI, int, const char*, int, int);
void (__thiscall* InitializeScroll)(UI, int, float, int);
void (__thiscall* AddChoice)(UI, const char*, int, int);
void (__thiscall* SelectChoice)(UI, int);
float (__stdcall* TuningFloat)(int);
const float* (__stdcall* TuningVector)(int);
int (__thiscall* FindTextureDictionary)(UI, const char*);
UI textureDictionary;
safetyhook::InlineHook findHook, updateHook, barUpdateHook;
safetyhook::InlineHook optionsBuildHook, optionsCloseHook, optionsInputHook, optionsClickHook, optionsHoverHook;
UI (__thiscall* GetInput)(UI);
void (__cdecl* PlayMenuSelect)();
void (__cdecl* PlayMenuBack)();
const int* (__thiscall* ReadInput)(UI, int, int);
void (__thiscall* ConsumeInput)(UI, int);
UI inputManager;
// Names of UI elements must be unique while the old ones are still being destroyed
unsigned int generation = 0;

struct OptionsState
{
    std::shared_ptr<Snapshot> snapshot;
    std::vector<PageRef> pages;
    std::vector<std::pair<UI, size_t>> links;
    UI focus = nullptr;
    bool open = false;
    bool canSave = true;
    size_t page = 0;
    std::vector<std::pair<size_t, int>> trail; // the pages Back returns to, with their selected rows
};
std::unordered_map<UI, OptionsState> optionsScreens;
struct PageAdapter
{
    NativePage page;
    size_t stack, header, help;
    safetyhook::InlineHook build, close;
};
PageAdapter pages[] = {
    {NativePage::Display, 268, 288, 292}, {NativePage::Graphics, 340, 344, 348},
    {NativePage::Controls, 272, 264, 268}, {NativePage::Audio, 280, 272, 276}
};

struct Binding { const FusionMenu::Option* option; int shown; UI row; };
struct Screen
{
    UI scroll;
    UI stack;
    UI help;
    std::string stackName;
    std::unordered_map<UI, Binding> lists;
    std::vector<std::pair<UI, Action*>> actions;
    std::shared_ptr<Snapshot> snapshot;
    std::shared_ptr<PageContent> content;
};
std::unordered_map<UI, Screen> screens;

void Anchor(UI object, int point, UI relative, int relativePoint, float x = 0, float y = 0)
{
    // UIOffset consists of two { float pixels; float scale; uint32_t reference; } axes.
    Virtual(object, 276, point, Virtual<uint32_t>(relative, 88), relativePoint, x, 0.0f, 0, y, 0.0f, 0);
}

// Help text ends just above the title and grows upward, so longer text never runs into the title or the list
void AnchorHelp(UI help, UI header, UI list)
{
    Virtual(help, 296);
    Anchor(help, 18, header, 6, TuningVector(8)[0], HelpGap);
    Anchor(help, 8, list, 8);
}

// Scrolling lists show as many rows as the stock Graphics page, the tallest of the game's pages
int VisibleRows(size_t rows)
{
    return static_cast<int>(std::min<size_t>(rows, 17));
}

void __cdecl Debug(const char* text) { OutputDebugStringA(text); }

UI __cdecl FindUI(const char* name)
{
    // The stock Display input handlers find their stack by this literal name.
    // Redirect only while that screen's scrolling replacement is alive.
    for (auto& [owner, state] : screens)
        if (name && state.stackName == name) return state.stack;
    return findHook.call<UI>(name);
}

void AddRow(UI screen, Screen& state, const FusionMenu::Option& option, size_t index, int dictionary)
{
    auto prefix = std::string("FF.") + Virtual<const char*>(screen, 84) + "." + std::to_string(generation) + "." + std::to_string(index);
    auto listName = prefix + ".List";
    const bool slider = option.control == FusionMenu::Control::Slider;
    auto list = slider ? ConstructBar(Allocate(328), listName.c_str(), Virtual<const char*>(screen, 84)) :
        ConstructList(Allocate(340), listName.c_str(), Virtual<const char*>(screen, 84));
    auto row = ConstructRow(Allocate(316), prefix.c_str(), Virtual<const char*>(state.scroll, 84));
    Virtual(row, 656, Text(Upper(option.label)));
    // Localized labels use the native GXT lookup, including UTF-16 fonts.
    Field<uint8_t>(Field<UI>(row, 224), 474) = 0;
    Virtual(row, 684, 0);
    Virtual(row, 672, 4, 10, 8);
    Virtual(row, 56, 1);
    Virtual(row, 712, list, 0, 0.0f);
    Virtual(row, 724, static_cast<int>(0x100 + index));
    Virtual(row, 520, Virtual<uint32_t>(state.scroll, 88));
    // Scrolling stacks enable row activation when attaching children. Settings
    // labels must not invoke the stack's page-navigation action; only their
    // value controls handle clicks. Keep hover/focus enabled independently.
    Virtual(row, 740, 0); // prevent SetSelectable from enabling clicks again
    Virtual(row, 548, 0);
    const auto position = slider ? option.SliderPosition() : option.Position();
    if (slider)
    {
        InitializeBar(list, 0.0f, static_cast<float>(option.choices.size() - 1), 0,
            dictionary, "bar_fill", dictionary, "bar_fill", dictionary, "bar_icon");
        Virtual(list, 156, 1.0f, Virtual<uint32_t>(row, 88));
        Virtual(list, 148, TuningFloat(62));
        Virtual(Field<UI>(list, 256), 348, 13);
        Virtual(Field<UI>(list, 252), 348, 14);
        SetBar(list, static_cast<float>(position));
        const auto text = option.SliderText();
        Virtual(Field<UI>(list, 264), 92, text.c_str());
        // The stock bar (about 98 units wide) leaves room for two digits before its value. For longer values
        // it ends further left and is shortened by as much, so it keeps clear of both the value and the label.
        size_t widest = 0;
        for (const auto& choice : option.choices) widest = std::max(widest, choice.text.size());
        if (widest > 2)
        {
            const float extra = std::min(12.0f * static_cast<float>(widest - 2), 60.0f);
            auto background = Field<UI>(list, 252);
            Virtual(background, 296);
            Virtual(background, 144, (98.0f - extra) / 98.0f, Virtual<uint32_t>(list, 88));
            Anchor(background, 8, Field<UI>(list, 264), 8, -30.0f - extra);
        }
    }
    else
    {
        InitializeList(list, dictionary, "list_arrow", 1, 0);
        Virtual(Field<UI>(list, 232), 360, 0);
        for (const auto& choice : option.choices) AddChoice(list, Text(choice.text), -1, 0);
        AddChoice(list, Text(option.other), -1, 0);
        SelectChoice(list, position);
    }
    Virtual(list, 56, 0);
    state.lists.emplace(list, Binding{&option, position, row});
}

UI AddAction(UI screen, UI parent, const std::string& name, const std::string& label, int id)
{
    auto row = ConstructRow(Allocate(316), name.c_str(), Virtual<const char*>(parent, 84));
    Virtual(row, 656, Text(Upper(label)));
    Field<uint8_t>(Field<UI>(row, 224), 474) = 0;
    Virtual(row, 684, 0);
    Virtual(row, 672, 4, 10, 8);
    Virtual(row, 56, 1);
    Virtual(row, 724, id);
    Virtual(row, 548, 1);
    Virtual(row, 520, Virtual<uint32_t>(screen, 88));
    Virtual(row, 532, Virtual<uint32_t>(screen, 88));
    return row;
}

void PositionOptionsHeader(UI screen, bool custom)
{
    auto header = Field<UI>(screen, 264);
    auto offset = TuningVector(custom ? 5 : 2);
    Virtual(header, 296);
    Virtual(header, 276, 2, uint32_t(2139856676), 2, offset[0], 0.0f, 0,
        offset[1] - (custom ? 60.0f : 0.0f), 0.0f, 0);
}

void OpenFusionPage(UI screen, size_t page, bool sound = true)
{
    auto& options = optionsScreens.at(screen);
    if (options.open || page >= options.pages.size()) return;
    options.open = true;
    options.page = page;
    options.focus = Field<UI>(screen, 232);
    const auto& ref = options.pages[page];
    // Saving can only fail for Fusion Fix's own file, other plugins report nothing about theirs
    options.canSave = ref.plugin->module != thisModule || CSettings::CanSave();
    ++generation;
    auto oldStack = Field<UI>(screen, 272);
    Virtual(oldStack, 60, 0);
    Virtual(oldStack, 308, 0);
    auto content = BuildContent(*options.snapshot, options.pages, page);
    const auto scrollName = "FF.Options.Scroll." + std::to_string(generation);
    auto scroll = ConstructScroll(Allocate(344), scrollName.c_str(), Virtual<const char*>(screen, 84));
    InitializeScroll(scroll, 0, TuningFloat(6), 0);
    Field<int>(scroll, 264) = VisibleRows(content->rows.size());
    Field<uint8_t>(scroll, 277) = 1;
    Field<uint8_t>(scroll, 278) = 1;
    auto stack = Field<UI>(scroll, 288);
    auto header = Field<UI>(screen, 264);
    auto help = Field<UI>(screen, 268);
    auto& state = screens[screen];
    state = {scroll, stack, help, "FF.Options.Stack", {}, {}, options.snapshot, content};
    PositionOptionsHeader(screen, true);
    Virtual(header, 92, Text(Upper(ref.title)));
    Field<uint8_t>(header, 474) = 0;
    auto offset = TuningVector(0);
    Anchor(scroll, 6, header, 18, offset[0], offset[1]);
    std::memcpy(static_cast<char*>(stack) + 264, static_cast<char*>(oldStack) + 264, 20);
    int dictionary = FindTextureDictionary(textureDictionary, "titlescreen");
    if (dictionary == -1) dictionary = FindTextureDictionary(textureDictionary, "pausemenu");
    auto& rows = state.content->rows;
    for (size_t i = 0; i < rows.size(); ++i)
    {
        if (rows[i].option) AddRow(screen, state, *rows[i].option, i, dictionary);
        else
        {
            const auto name = "FF.Options.Action." + std::to_string(generation) + "." + std::to_string(i);
            state.actions.emplace_back(AddAction(screen, scroll, name, rows[i].action->label, static_cast<int>(0x400 + i)), rows[i].action);
        }
    }
    AnchorHelp(help, header, scroll);
    Field<UI>(screen, 232) = stack;
    Virtual(stack, 764, 0);
    Virtual(scroll, 308, 1);
    Virtual(scroll, 488);
    Virtual(scroll, 60, 1);
    if (sound) PlayMenuSelect();
}

void CloseFusionPage(UI screen)
{
    auto& options = optionsScreens.at(screen);
    if (!options.open) return;
    auto state = screens.at(screen);
    screens.erase(screen);
    options.open = false;
    Field<UI>(screen, 232) = options.focus;
    Virtual(state.scroll, 60, 0);
    Virtual(state.scroll, 308, 0);
    Virtual(state.scroll, 332, 1);
    auto header = Field<UI>(screen, 264);
    auto stack = Field<UI>(screen, 272);
    PositionOptionsHeader(screen, false);
    Virtual(header, 92, "MO_OPTIONS");
    Field<uint8_t>(header, 474) = 0;
    Virtual(state.help, 296);
    auto offset = TuningVector(8);
    Anchor(state.help, 6, header, 6, offset[0], offset[1]);
    Anchor(state.help, 8, stack, 8);
    Virtual(stack, 308, 1);
    Virtual(stack, 488);
    Virtual(stack, 60, 1);
}

// Builds an open page again when its rows change: a setting became visible or
// hidden, or the values usable now changed. The same row keeps the focus.
int SelectedIndex(UI stack)
{
    const auto selected = Virtual<UI>(stack, 768);
    for (int i = 0, n = Virtual<int>(stack, 612); i < n; ++i)
        if (Virtual<UI>(stack, 632, i) == selected) return i;
    return -1;
}

void Select(UI stack, int index)
{
    const int count = Virtual<int>(stack, 612);
    if (count > 0 && index >= 0) Virtual(stack, 696, std::min(index, count - 1), 1);
}

void RebuildFusionPage(UI screen)
{
    auto& options = optionsScreens.at(screen);
    const int index = SelectedIndex(screens.at(screen).stack);
    const auto page = options.page;
    CloseFusionPage(screen);
    OpenFusionPage(screen, page, false);
    Select(screens.at(screen).stack, index);
}

// Links open their page one level down, Back returns one level up
void OpenLink(UI screen, size_t page)
{
    auto& options = optionsScreens.at(screen);
    options.trail.emplace_back(options.page, SelectedIndex(screens.at(screen).stack));
    CloseFusionPage(screen);
    OpenFusionPage(screen, page);
}

void GoBack(UI screen)
{
    auto& options = optionsScreens.at(screen);
    CloseFusionPage(screen);
    if (!options.trail.empty())
    {
        const auto [page, index] = options.trail.back();
        options.trail.pop_back();
        OpenFusionPage(screen, page, false);
        Select(screens.at(screen).stack, index);
    }
    PlayMenuBack();
}

void RunAction(UI screen, Action& action)
{
    if (action.target) OpenLink(screen, *action.target);
    else action.run();
}

int __fastcall BuildOptions(UI screen, void*, UI previous)
{
    auto result = optionsBuildHook.thiscall<int>(screen, previous);
    // Plugins are looked for each time, so load order doesn't matter and late plugins are found
    snapshot = FindPlugins();
    auto& options = optionsScreens[screen];
    options.snapshot = snapshot;
    options.pages = BuildPages(*snapshot);
    auto stack = Field<UI>(screen, 272);
    std::vector<UI> tail;
    bool afterGraphics = false;
    for (int i = 0, n = Virtual<int>(stack, 612); i < n; ++i)
    {
        auto row = Virtual<UI>(stack, 632, i);
        if (afterGraphics) tail.push_back(row);
        if (std::string_view(Virtual<const char*>(row, 84)) == "MS_Options.Graphics") afterGraphics = true;
    }
    for (auto row : tail) Virtual(stack, 620, Virtual<uint32_t>(row, 88));
    // One link to the list of plugins
    if (!options.pages.empty())
        options.links.emplace_back(AddAction(screen, stack, "FF.Options.Link.0", options.pages[0].title, 0x400), 0);
    for (auto row : tail) Virtual(stack, 616, Virtual<uint32_t>(row, 88));
    Virtual(stack, 488);
    return result;
}

int __fastcall CloseOptions(UI screen, void*)
{
    if (optionsScreens.contains(screen)) CloseFusionPage(screen);
    optionsScreens.erase(screen);
    return optionsCloseHook.thiscall<int>(screen);
}

Action* SelectedAction(const Screen& state, UI row)
{
    for (const auto& [actionRow, action] : state.actions)
        if (actionRow == row) return action;
    return nullptr;
}

int __fastcall OptionsInput(UI screen, void*)
{
    if (MP3Overlay::BlocksInput()) return 0;
    auto found = optionsScreens.find(screen);
    if (found == optionsScreens.end()) return optionsInputHook.thiscall<int>(screen);
    auto& options = found->second;
    auto input = GetInput(inputManager);
    const int event = *ReadInput(input, 96, 0);
    if (options.open)
    {
        if (event == 7 || event == 13) GoBack(screen);
        else if (event == 8)
        {
            auto& state = screens.at(screen);
            if (auto action = SelectedAction(state, Virtual<UI>(state.stack, 768))) RunAction(screen, *action);
        }
        else return 0;
        ConsumeInput(input, 1);
        return 1;
    }
    if (event == 8)
        for (const auto& [link, page] : options.links)
            if (Virtual<UI>(Field<UI>(screen, 272), 768) == link)
            {
                options.trail.clear();
                OpenFusionPage(screen, page);
                ConsumeInput(input, 1);
                return 1;
            }
    return optionsInputHook.thiscall<int>(screen);
}

int __fastcall OptionsClick(UI screen, void*, uint32_t hash)
{
    auto found = optionsScreens.find(screen);
    if (found != optionsScreens.end())
    {
        if (found->second.open)
        {
            for (const auto& [row, action] : screens.at(screen).actions)
                if (hash == Virtual<uint32_t>(row, 88)) { RunAction(screen, *action); break; }
            return 1;
        }
        for (const auto& [link, page] : found->second.links)
            if (hash == Virtual<uint32_t>(link, 88))
            {
                found->second.trail.clear();
                OpenFusionPage(screen, page);
                return 1;
            }
    }
    return optionsClickHook.thiscall<int>(screen, hash);
}

int __fastcall OptionsHover(UI screen, void*, uint32_t hash)
{
    auto found = optionsScreens.find(screen);
    if (found == optionsScreens.end()) return optionsHoverHook.thiscall<int>(screen, hash);
    auto stack = found->second.open ? screens.at(screen).stack : Field<UI>(screen, 272);
    for (int i = 0, n = Virtual<int>(stack, 612); i < n; ++i)
        if (Virtual<uint32_t>(Virtual<UI>(stack, 632, i), 88) == hash)
        { Virtual(stack, 696, i, 1); break; }
    return 1;
}

// The rows of plugin pages that join one of the game's own pages
std::shared_ptr<PageContent> BuildNativeContent(const Snapshot& snap, NativePage native)
{
    auto content = std::make_shared<PageContent>();
    for (auto& plugin : snap.plugins)
        for (auto& page : plugin.file.description.pages)
            if (NativePageOf(page) == native)
                AddPageRows(snap, PageRef{&plugin, {page.id}}, false, *content);
    return content;
}

template<size_t P> int __fastcall BuildPage(UI screen, void*, UI previous)
{
    auto& page = pages[P];
    auto result = page.build.thiscall<int>(screen, previous);
    if (screens.contains(screen) || !snapshot) return result;
    auto content = BuildNativeContent(*snapshot, page.page);
    if (content->rows.empty()) return result;

    auto oldStack = Field<UI>(screen, page.stack);
    if (!oldStack) return result;
    ++generation;
    const std::string stackName = Virtual<const char*>(oldStack, 84);
    std::vector<UI> stockRows;
    auto count = Virtual<int>(oldStack, 612);
    for (int i = 0; i < count; ++i) stockRows.push_back(Virtual<UI>(oldStack, 632, i));
    auto scrollName = std::string("FF.") + Virtual<const char*>(screen, 84) + ".Scroll." + std::to_string(generation);
    auto scroll = ConstructScroll(Allocate(344), scrollName.c_str(), Virtual<const char*>(screen, 84));
    InitializeScroll(scroll, 0, TuningFloat(6), 0);
    Field<int>(scroll, 264) = VisibleRows(stockRows.size() + content->rows.size()); // native clipping, arrows, mouse wheel and controller navigation
    Field<uint8_t>(scroll, 277) = 1;
    Field<uint8_t>(scroll, 278) = 1;
    auto stack = Field<UI>(scroll, 288);
    auto& state = screens[screen];
    state = {scroll, stack, Field<UI>(screen, page.help), stackName, {}, {}, snapshot, content};
    auto offset = TuningVector(0);
    auto header = Field<UI>(screen, page.header);
    // Use the native Graphics page's higher title position for the scrolling area.
    auto titleOffset = TuningVector(5);
    Virtual(header, 296);
    Virtual(header, 276, 2, uint32_t(2139856676), 2, titleOffset[0], 0.0f, 0,
        titleOffset[1] - 60.0f, 0.0f, 0);
    Anchor(scroll, 6, header, 18, offset[0], offset[1]);

    int dictionary = FindTextureDictionary(textureDictionary, "titlescreen");
    if (dictionary == -1) dictionary = FindTextureDictionary(textureDictionary, "pausemenu");
    auto footer = std::find_if(stockRows.begin(), stockRows.end(), [](UI row)
    { return std::string_view(Virtual<const char*>(row, 84)).ends_with(".RestoreDefaults"); });
    // Keep the native separator with the reset action at the bottom.
    if (footer != stockRows.end() && footer != stockRows.begin())
    {
        const std::string_view name = Virtual<const char*>(*(footer - 1), 84);
        if (name.find(".Empty") != name.npos || name.find(".Space") != name.npos) --footer;
    }
    auto addOptions = [&]
    {
        for (size_t i = 0; i < content->rows.size(); ++i)
            if (content->rows[i].option) AddRow(screen, state, *content->rows[i].option, i, dictionary);
    };

    // Reparent through the native container APIs, so clipping and focus targets
    // are installed by UIScrollingStackLayout rather than copied by hand.
    for (auto it = stockRows.begin(); it != stockRows.end(); ++it)
    {
        if (it == footer) addOptions();
        auto row = *it;
        const auto id = Virtual<uint32_t>(row, 88);
        Virtual(oldStack, 620, id);
        Virtual(row, 104, Virtual<uint32_t>(scroll, 88));
        Virtual(scroll, 616, id);
    }
    // Keep the stock selection sound callback on the new inner stack.
    std::memcpy(static_cast<char*>(stack) + 264, static_cast<char*>(oldStack) + 264, 20);
    if (footer == stockRows.end()) addOptions();

    Field<UI>(screen, page.stack) = stack;
    Field<UI>(screen, 232) = stack;
    // Help text follows the visible container, not the full scrollable content.
    AnchorHelp(state.help, header, scroll);
    if (page.page == NativePage::Graphics)
    {
        auto memoryTitle = Field<UI>(screen, 364);
        Virtual(memoryTitle, 296);
        Anchor(memoryTitle, 6, scroll, 18, 4.0f, 20.0f);
    }
    Virtual(oldStack, 300, 0);
    Virtual(oldStack, 332, 1);
    Virtual(scroll, 308, 1);
    Virtual(scroll, 488);
    Virtual(scroll, 60, 1);
    return result;
}

// The stock Restore Defaults of a game page also restores the rows joined to it
safetyhook::InlineHook displayResetHook;
void __fastcall ResetDisplay(UI screen, void*)
{
    displayResetHook.thiscall<void>(screen);
    if (auto found = screens.find(screen); found != screens.end() && found->second.content) RestoreDefaults(*found->second.content);
}

template<size_t P> int __fastcall ClosePage(UI screen, void*)
{
    auto& page = pages[P];
    auto found = screens.find(screen);
    if (found == screens.end()) return page.close.thiscall<int>(screen);
    // MS_Display first saves the stock values, then destroys its stack. Let it
    // destroy the owning wrapper, including all rows, lists and the inner stack.
    Field<UI>(screen, page.stack) = found->second.scroll;
    Field<UI>(screen, 232) = nullptr;
    screens.erase(found);
    return page.close.thiscall<int>(screen);
}

void __fastcall UpdateBar(UI bar, void*)
{
    barUpdateHook.thiscall<void>(bar);
    for (auto& [owner, state] : screens)
    {
        auto found = state.lists.find(bar);
        if (found == state.lists.end()) continue;
        auto& binding = found->second;
        const int position = static_cast<int>(std::lround(Field<float>(bar, 216)));
        if (position != binding.shown) binding.option->Select(position);
        const int desired = binding.option->SliderPosition();
        if (position != desired) SetBar(bar, static_cast<float>(desired));
        binding.shown = desired;
        // Native bars count integer steps; show the actual setting, including decimals.
        const auto text = binding.option->SliderText();
        Virtual(Field<UI>(bar, 264), 92, text.c_str());
        break;
    }
}

void __fastcall UpdateList(UI list, void*)
{
    // Observe the final value AFTER wrapping and the game's deferred selection.
    // The old increment hooks observed count/-1 before the native wrap.
    updateHook.thiscall<void>(list);
    for (auto& [owner, state] : screens)
    {
        auto found = state.lists.find(list);
        if (found == state.lists.end()) continue;
        auto& binding = found->second;
        int position = Field<int>(list, 228);
        if (position != binding.shown)
        {
            if (position == static_cast<int>(binding.option->choices.size()))
            {
                position = binding.shown == position - 1 ? 0 : position - 1;
                SelectChoice(list, position);
            }
            binding.option->Select(position);
            binding.shown = position;
        }
        auto desired = binding.option->Position();
        if (desired != binding.shown)
        {
            SelectChoice(list, desired);
            binding.shown = desired;
        }
        break;
    }
}

// Changes reported by plugins: preset choices waiting for Apply are dropped, and
// open pages whose rows changed are built again.
void HandleChanges()
{
    if (!settingsChanged.exchange(false)) return;
    for (auto& [owner, state] : screens)
        if (state.content)
            for (auto& selector : state.content->presets) { selector.pending = -1; selector.armed = false; }
    std::vector<UI> rebuild;
    for (auto& [owner, options] : optionsScreens)
    {
        auto state = screens.find(owner);
        if (!options.open || state == screens.end()) continue;
        if (BuildContent(*options.snapshot, options.pages, options.page)->signature != state->second.content->signature)
            rebuild.push_back(owner);
    }
    for (auto owner : rebuild) RebuildFusionPage(owner);
}

void UpdateHelp()
{
    HandleChanges();
    for (auto& [owner, state] : screens)
    {
        auto selected = Virtual<UI>(state.stack, 768);
        for (auto& [row, action] : state.actions)
            if (row != selected && action->leave) action->leave();
        auto binding = std::find_if(state.lists.begin(), state.lists.end(), [selected](const auto& item)
        { return item.second.row == selected; });
        if (binding != state.lists.end())
        {
            auto& option = *binding->second.option;
            auto text = option.help;
            if (!option.Enabled()) text += (text.empty() ? "" : " ") + state.snapshot->Host("menu.disabled");
            if (auto options = optionsScreens.find(owner); options != optionsScreens.end() && options->second.open && !options->second.canSave)
                text = state.snapshot->Host("menu.savefailed");
            Virtual(state.help, 92, Text(text));
        }
        else if (auto action = SelectedAction(state, selected))
            Virtual(state.help, 92, Text(action->help ? action->help() : std::string()));
        Field<uint8_t>(state.help, 474) = 0;
    }
    for (auto& [owner, options] : optionsScreens)
    {
        if (options.open) continue;
        auto help = Field<UI>(owner, 268);
        for (const auto& [link, page] : options.links)
            if (Virtual<UI>(Field<UI>(owner, 272), 768) == link)
            {
                Virtual(help, 92, Text(options.pages.at(page).help));
                break;
            }
        Field<uint8_t>(help, 474) = 0;
    }
}

void Initialize()
{
    try
    {
        GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
            reinterpret_cast<LPCWSTR>(&Initialize), &thisModule);
        gameLanguage = *hook::get_pattern<const unsigned int*>("A1 ? ? ? ? 83 F8 09 77 43 FF 24 85 ? ? ? ? B8 ? ? ? ? C3 B8", 1);
        auto getText = hook::get_pattern("8B 44 24 04 83 EC 40 56 8B F1 85 C0 75 34 E8 ? ? ? ? C6 44 24 04 00 8D 44 24 04");
        auto build = hook::get_pattern("83 EC 38 53 55 56 8B F1 57 B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 8B E8 83 FD FF");
        auto close = hook::get_pattern("56 57 8B F1 E8 ? ? ? ? 8B 8E 20 01 00 00 33 FF 3B CF 74 12");
        auto optionsBuild = hook::get_pattern("81 EC 34 01 00 00 53 55 56 8B F1 57 B9 ? ? ? ? E8 ? ? ? ? 8B 0D");
        auto optionsClose = hook::get_pattern("56 8B F1 8B 8E 18 01 00 00 57 33 FF 3B CF 74 0E 8B 01 8B 10");
        auto optionsInput = hook::get_pattern("83 EC 0C 55 56 8B F1 B9 ? ? ? ? E8 ? ? ? ? 8B E8 6A 00 6A 60 8B CD E8 ? ? ? ? F3 0F 7E 00 8B 40 08 66 0F D6 44 24 08 89 44 24 10 8B 44 24 08 83 F8 07 0F 84 CC 00 00 00");
        auto optionsClick = hook::get_pattern("8B 44 24 04 53 56 57 50 8B F9 E8 ? ? ? ? 83 C4 04 8B F0 E8 ? ? ? ? 8B 16 8A D8");
        auto optionsHover = hook::get_pattern("56 8B F1 8B 8E 10 01 00 00 8B 01 8B 90 00 03 00 00 FF D2 8B 10 8B C8 8B 42 58 FF D0 8B 4C 24 08");
        inputManager = Field<UI>(optionsInput, 8);
        GetInput = injector::GetBranchDestination(static_cast<char*>(optionsInput) + 12).get();
        auto selectSoundCall = hook::get_pattern("FF D0 8B CF 89 87 F0 00 00 00 E8 ? ? ? ? 5F 5E 5B C2 04 00 83 F8 03", 10);
        PlayMenuSelect = injector::GetBranchDestination(selectSoundCall).get();
        auto backSoundCall = hook::get_pattern("8B CE C7 86 14 01 00 00 00 00 00 00 E8 ? ? ? ? 80 3D ? ? ? ? 00 74 7A", 12);
        PlayMenuBack = injector::GetBranchDestination(backSoundCall).get();
        ReadInput = reinterpret_cast<decltype(ReadInput)>(hook::get_pattern("83 B9 54 01 00 00 00 56 8D B1 54 01 00 00 74 17 80 B9 9C 01 00 00 00 75 0E"));
        ConsumeInput = reinterpret_cast<decltype(ConsumeInput)>(hook::get_pattern("8A 44 24 04 56 8B F1 88 86 9C 01 00 00 84 C0 74 15"));
        auto barUpdate = hook::get_pattern("56 8B F1 8B 86 00 01 00 00 8B 8E FC 00 00 00 8B 11 57 8B 38 8B 42 58 FF D0");
        ConstructBar = reinterpret_cast<decltype(ConstructBar)>(hook::get_pattern("8B 44 24 08 56 6A 00 8B F1 8B 4C 24 0C 50 51 8B CE E8 ? ? ? ? 68 FF 00 00 00 68 FF 00 00 00 68 FF 00 00 00 68 FF 00 00 00 8D 8E F4 00 00 00 C7 06 ? ? ? ? E8 ? ? ? ? 68 FF 00 00 00"));
        InitializeBar = reinterpret_cast<decltype(InitializeBar)>(hook::get_pattern("83 EC 2C 53 56 8B F1 8B 06 8B 90 74 01 00 00 57 FF D2 84 C0 0F 85"));
        SetBar = reinterpret_cast<decltype(SetBar)>(hook::get_pattern("F3 0F 10 54 24 04 83 EC 14 56 8B F1 F3 0F 10 86 DC 00 00 00"));
        void* builds[] = {build,
            hook::get_pattern("81 EC 04 01 00 00 53 55 56 8B F1 33 DB 57 38 9E 61 01 00 00 74 24"),
            hook::get_pattern("83 EC 34 55 56 8B F1 57 B9 ? ? ? ? E8 ? ? ? ? 8B 0D ? ? ? ? 6A 00"),
            hook::get_pattern("83 EC 38 53 55 56 8B F1 57 B9 ? ? ? ? E8 ? ? ? ? 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 8B 0D ? ? ? ? 6A 02 8B E8")};
        void* closes[] = {close,
            hook::get_pattern("56 57 8B F1 8B 06 8B 90 34 01 00 00 33 FF 57 FF D2 8B 06 8B 90 E8 01 00 00 8B CE FF D2"),
            hook::get_pattern("56 8B F1 8B 8E 10 01 00 00 85 C9 74 28 8B 01 8B 90 2C 01 00 00 6A 00"),
            hook::get_pattern("56 57 8B F1 E8 ? ? ? ? 8B 8E 18 01 00 00 33 FF 3B CF 74 23")};
        auto displayReset = hook::get_pattern("56 57 8B F1 E8 ? ? ? ? 68 ? ? ? ? E8 ? ? ? ? 8B 0D ? ? ? ? 83 C4 04 68 81 EF 82 94");
        auto update = hook::get_pattern("83 EC 0C 56 8B F1 80 BE 13 01 00 00 00 74 1C 83 BE 08 01 00 00 00 74 13");
        auto findCall = hook::get_pattern("E8 ? ? ? ? 8B 10 8B C8 8B 82 00 03 00 00 83 C4 04 FF D0 8B D8 8B 44 24 10 83 F8 07");
        void* find = injector::GetBranchDestination(findCall).get();
        Allocate = reinterpret_cast<decltype(Allocate)>(hook::get_pattern("B8 10 00 00 00 8B 4C 24 04 E9 ? ? ? ? CC CC 8B 4C 24 04 8B 44 24 08 3B C8"));
        ConstructRow = reinterpret_cast<decltype(ConstructRow)>(hook::get_pattern("8B 44 24 08 56 8B F1 8B 4C 24 08 50 51 8B CE E8 ? ? ? ? 33 C0 89 86 2C 01 00 00 89 86 34 01 00 00"));
        ConstructList = reinterpret_cast<decltype(ConstructList)>(hook::get_pattern("8B 44 24 08 53 56 33 DB 53 8B F1 8B 4C 24 10 50 51 8B CE E8 ? ? ? ? C7 06 ? ? ? ? 33 D2 33 C0 8D 8E 18 01 00 00"));
        ConstructScroll = reinterpret_cast<decltype(ConstructScroll)>(hook::get_pattern("8B 44 24 08 53 56 33 DB 53 8B F1 8B 4C 24 10 50 51 8B CE E8 ? ? ? ? 8D 8E D8 00 00 00 C7 06 ? ? ? ? E8 ? ? ? ? 8D 8E EC 00 00 00 E8 ? ? ? ? 0F 57 C0 88 9E 0C 01 00 00 88 9E 0D 01 00 00"));
        InitializeList = reinterpret_cast<decltype(InitializeList)>(hook::get_pattern("83 EC 18 56 57 8B F1 8B 0D ? ? ? ? 6A 04 E8 ? ? ? ? D9 5C 24 08 8A 44 24 2C"));
        InitializeScroll = reinterpret_cast<decltype(InitializeScroll)>(hook::get_pattern("83 EC 1C 53 55 56 33 DB 57 8B F1 38 1D ? ? ? ? 74 10 39 1D ? ? ? ? 75 0F 39 1D ? ? ? ? 75 07 68 ? ? ? ? EB 05 68 ? ? ? ? B9 ? ? ? ? E8 ? ? ? ? 8B E8 83 FD FF"));
        AddChoice = reinterpret_cast<decltype(AddChoice)>(hook::get_pattern("8B 44 24 0C 83 EC 0C 53 56 8B F1 83 F8 FF 75 0E 8B 86 E8 00 00 00"));
        SelectChoice = reinterpret_cast<decltype(SelectChoice)>(hook::get_pattern("0F B7 81 E0 00 00 00 66 85 C0 76 1A 0F B7 D0 8B 44 24 04 3B C2"));
        TuningFloat = reinterpret_cast<decltype(TuningFloat)>(hook::get_pattern("8B 44 24 04 D9 04 85 ? ? ? ? C2 04 00 CC CC"));
        TuningVector = reinterpret_cast<decltype(TuningVector)>(hook::get_pattern("8B 44 24 04 8D 04 C5 ? ? ? ? C2 04 00 CC CC"));
        textureDictionary = Field<UI>(build, 25);
        FindTextureDictionary = injector::GetBranchDestination(static_cast<char*>(build) + 29).get();
        // Find the required functions before installing hooks. Roll back on failure.
        gxtHook = safetyhook::create_inline(getText, GetMenuText);
        findHook = safetyhook::create_inline(find, FindUI);
        updateHook = safetyhook::create_inline(update, UpdateList);
        barUpdateHook = safetyhook::create_inline(barUpdate, UpdateBar);
        optionsBuildHook = safetyhook::create_inline(optionsBuild, BuildOptions);
        optionsCloseHook = safetyhook::create_inline(optionsClose, CloseOptions);
        optionsInputHook = safetyhook::create_inline(optionsInput, OptionsInput);
        optionsClickHook = safetyhook::create_inline(optionsClick, OptionsClick);
        optionsHoverHook = safetyhook::create_inline(optionsHover, OptionsHover);
        if (!optionsBuildHook || !optionsCloseHook || !optionsInputHook || !optionsClickHook || !optionsHoverHook)
            throw std::runtime_error("Could not install Fusion Fix page hooks");
        void* buildCallbacks[] = {BuildPage<0>, BuildPage<1>, BuildPage<2>, BuildPage<3>};
        void* closeCallbacks[] = {ClosePage<0>, ClosePage<1>, ClosePage<2>, ClosePage<3>};
        for (size_t i = 0; i < std::size(pages); ++i)
        {
            pages[i].close = safetyhook::create_inline(closes[i], closeCallbacks[i]);
            pages[i].build = safetyhook::create_inline(builds[i], buildCallbacks[i]);
            if (!pages[i].close || !pages[i].build) throw std::runtime_error("Could not install page hooks");
        }
        displayResetHook = safetyhook::create_inline(displayReset, ResetDisplay);
        if (!gxtHook || !findHook || !updateHook || !barUpdateHook || !displayResetHook) throw std::runtime_error("Could not install menu hooks");
        FusionFix::onMenuDrawingEvent() += UpdateHelp;
        FusionFix::onGameProcessEvent() += UpdateHelp; // title screen is not always reported as paused
    }
    catch (...)
    {
        for (auto& page : pages) { page.build.reset(); page.close.reset(); }
        updateHook.reset(); barUpdateHook.reset(); findHook.reset(); gxtHook.reset(); displayResetHook.reset();
        optionsBuildHook.reset(); optionsCloseHook.reset(); optionsInputHook.reset();
        optionsClickHook.reset(); optionsHoverHook.reset();
        Debug("Fusion Fix: settings menu unavailable for this executable. Settings remain available in the CFG.\n");
    }
}
struct Install
{
    Install() { FusionFix::onInitEvent() += Initialize; }
} install;
}

// For other modules: a key the game's text lookup turns into the text (help messages, labels)
export const char* GameTextKey(const std::string& text)
{
    return Text(text);
}

// For other modules: Fusion Fix's own text (its translations) in the game's language
export std::string FusionFixText(std::string_view key)
{
    asi_settings::Texts texts = SettingsPlugin().GetTexts();
    texts.Select(LanguageTag());
    return texts.Resolve("@" + std::string(key));
}
