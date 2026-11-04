#include "FxcFormat.h"
#include "EffectXml.h"
#include "Disasm.h"
#include "Sha256.h"
#include <windows.h>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>
#include <set>
#include <algorithm>
#include <stdexcept>
#include <cstdio>
#include <cstdlib>
#include <unordered_map>
#include <thread>
#include <atomic>
#include <mutex>

namespace fs = std::filesystem;
using namespace shadertool;

namespace {
std::unordered_map<std::string, std::vector<uint8_t>> g_hlslCache;
fs::path g_hlslCacheDir;

struct Options {
    fs::path store;
    fs::path fxc;
    fs::path hlslCache;
    bool noAsm = false;
    bool quiet = false;
    bool useHlsl = false;
    long limit = -1;
};

std::vector<uint8_t> readFile(const fs::path& p) {
    std::ifstream f(p, std::ios::binary);
    if (!f) throw std::runtime_error("cannot open " + p.string());
    f.seekg(0, std::ios::end);
    std::streamoff n = f.tellg();
    f.seekg(0, std::ios::beg);
    std::vector<uint8_t> data(static_cast<size_t>(n));
    if (n > 0) f.read(reinterpret_cast<char*>(data.data()), n);
    if (!f && n > 0) throw std::runtime_error("cannot read " + p.string());
    return data;
}
void writeFile(const fs::path& p, const void* data, size_t size) {
    std::error_code ec;
    if (p.has_parent_path()) fs::create_directories(p.parent_path(), ec);
    std::ofstream f(p, std::ios::binary | std::ios::trunc);
    if (!f) throw std::runtime_error("cannot write " + p.string());
    if (size) f.write(static_cast<const char*>(data), static_cast<std::streamsize>(size));
    if (!f) throw std::runtime_error("write failed " + p.string());
}
void writeFile(const fs::path& p, const std::vector<uint8_t>& data) { writeFile(p, data.data(), data.size()); }
void writeFile(const fs::path& p, const std::string& data) { writeFile(p, data.data(), data.size()); }

fs::path fxcPathForXml(const fs::path& xmlPath) {
    std::string name = xmlPath.filename().string();
    const std::string suffix = ".fxc.xml";
    if (name.size() > suffix.size() && name.compare(name.size() - suffix.size(), suffix.size(), suffix) == 0)
        return xmlPath.parent_path() / (name.substr(0, name.size() - suffix.size()) + ".fxc");
    fs::path out = xmlPath;
    out.replace_extension(".fxc");
    return out;
}

std::string relPath(const fs::path& root, const fs::path& p) {
    std::error_code ec;
    fs::path r = fs::relative(p, root, ec);
    if (ec) return p.string();
    return r.generic_string();
}

size_t shaderCount(const Effect& e) {
    size_t n = 0;
    for (const auto& g : e.groups) n += g.shaders.size();
    return n;
}

void fillHashes(const Effect& e, std::vector<std::string>& hashes) {
    hashes.clear();
    for (const auto& g : e.groups)
        for (const auto& s : g.shaders)
            hashes.push_back(Sha256::hex(s.bytecode));
}

fs::path findFxc(const char* argv0) {
    std::error_code ec;
    std::vector<fs::path> starts;
    starts.push_back(fs::current_path(ec));
    if (argv0) {
        fs::path exe = fs::absolute(fs::path(argv0), ec);
        if (!ec) starts.push_back(exe.parent_path());
    }
    for (const auto& start : starts) {
        fs::path p = start;
        for (int i = 0; i < 10 && !p.empty(); ++i) {
            fs::path candidate = p / "source" / "dxsdk" / "lib" / "x86" / "fxc.exe";
            if (fs::exists(candidate, ec)) return candidate;
            fs::path parent = p.parent_path();
            if (parent == p) break;
            p = parent;
        }
    }
    char buf[MAX_PATH] = {};
    if (SearchPathA(nullptr, "fxc.exe", nullptr, MAX_PATH, buf, nullptr)) return fs::path(buf);
    return {};
}

std::string stageProfile(int groupIndex, const std::string& model) {
    static const char* prefix[6] = {"vs", "ps", "cs", "ds", "gs", "hs"};
    int gi = (groupIndex >= 0 && groupIndex < 6) ? groupIndex : 0;
    std::string m = model;
    for (char& c : m) if (c == '.') c = '_';
    return std::string(prefix[gi]) + "_" + m;
}

std::string hlslCacheKey(const std::vector<uint8_t>& source, const std::string& profile, const fs::path& fxc) {
    // A source can be shared by SM4.0, SM4.1 and SM5.0. Its text alone does
    // not identify the compiled program. Version the key to retire old caches.
    static const std::string compiler = compilerFingerprint();
    static const std::string fallback = fxc.empty() ? "no-fxc" : Sha256::hex(readFile(fxc));
    const std::string settings = "mp3-hlsl-cache-v2;main;flags=0;" + profile + ";" + compiler + ";" + fallback;
    std::vector<uint8_t> key(settings.begin(), settings.end());
    key.push_back(0);
    key.insert(key.end(), source.begin(), source.end());
    return Sha256::hex(key);
}

bool compileHlsl(const fs::path& fxc, const fs::path& hlsl, const std::string& profile,
                 const std::string& tag, std::vector<uint8_t>& out, std::string& error) {
    out.clear();
    error.clear();
    {
        std::ifstream hf(hlsl, std::ios::binary);
        if (hf) {
            std::string source((std::istreambuf_iterator<char>(hf)), std::istreambuf_iterator<char>());
            if (compileHlslInProcess(source, profile, out, error)) return true;
        }
    }
    if (fxc.empty()) { error = "fxc.exe not found"; return false; }
    std::error_code ec;
    fs::path tempDir = fs::temp_directory_path(ec);
    if (ec) tempDir = fs::current_path(ec);
    fs::path outCso = tempDir / ("mp3shadertool_" + tag + "_" + profile + ".cso");
    fs::path logPath = tempDir / ("mp3shadertool_" + tag + "_" + profile + ".log");
    std::error_code ignored;
    fs::remove(outCso, ignored);
    fs::remove(logPath, ignored);
    std::string cmd = "\"" + fxc.string() + "\" /nologo /T " + profile + " /E main /Fo \"" +
                      outCso.string() + "\" \"" + hlsl.string() + "\" > \"" + logPath.string() + "\" 2>&1";
    // Run through a tiny .bat file: std::system prepends "cmd /c", and a command
    // that begins with a quoted executable hits cmd's quote-stripping rules.
    fs::path batPath = tempDir / ("mp3shadertool_" + tag + "_" + profile + ".bat");
    {
        std::ofstream bat(batPath, std::ios::binary | std::ios::trunc);
        bat << "@echo off\r\n" << cmd << "\r\n";
    }
    int rc = std::system(("call \"" + batPath.string() + "\"").c_str());
    std::ifstream log(logPath, std::ios::binary);
    std::string logText((std::istreambuf_iterator<char>(log)), std::istreambuf_iterator<char>());
    if (fs::exists(outCso, ec) && rc == 0) {
        out = readFile(outCso);
        fs::remove(outCso, ignored);
        fs::remove(logPath, ignored);
        return true;
    }
    error = logText.empty() ? ("fxc failed with exit code " + std::to_string(rc)) : logText;
    fs::remove(outCso, ignored);
    fs::remove(logPath, ignored);
    fs::remove(batPath, ignored);
    return false;
}

Effect loadEffectFromXml(const fs::path& xmlPath, const fs::path& fxc,
                          std::vector<ShaderSourceRef>* outSources = nullptr) {
    std::ifstream f(xmlPath, std::ios::binary);
    if (!f) throw std::runtime_error("cannot open " + xmlPath.string());
    std::string text((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
    ParsedEffectSource parsed = xmlToEffect(text);
    Effect& e = parsed.effect;
    size_t index = 0;
    fs::path base = xmlPath.parent_path();
    for (int gi = 0; gi < 6; ++gi) {
        for (auto& s : e.groups[gi].shaders) {
            if (index >= parsed.shaderSources.size()) throw std::runtime_error("missing shader source reference in " + xmlPath.string());
            const ShaderSourceRef ref = parsed.shaderSources[index++];
            if (ref.file.empty()) throw std::runtime_error("empty shader source reference in " + xmlPath.string());
            fs::path sourcePath = base / fs::path(ref.file);
            std::string model = s.model;
            if (ref.dataType == "hlsl") {
                std::vector<uint8_t> hlslBytes = readFile(sourcePath);
                if (model.empty()) throw std::runtime_error("missing Model attribute for " + s.name + " in " + xmlPath.string());
                std::string cacheKey = hlslCacheKey(hlslBytes, stageProfile(gi, model), fxc);
                auto cached = g_hlslCache.find(cacheKey);
                if (cached != g_hlslCache.end()) {
                    s.bytecode = cached->second;
                } else if (!g_hlslCacheDir.empty()) {
                    std::error_code ec;
                    fs::path cacheFile = g_hlslCacheDir / (cacheKey + ".cso");
                    if (fs::exists(cacheFile, ec)) {
                        s.bytecode = readFile(cacheFile);
                        g_hlslCache.emplace(cacheKey, s.bytecode);
                    } else {
                        std::vector<uint8_t> compiled;
                        std::string error;
                        std::string tagText = fs::path(ref.file).generic_string();
                        std::string tag = Sha256::hex(std::vector<uint8_t>(tagText.begin(), tagText.end()));
                        if (!compileHlsl(fxc, sourcePath, stageProfile(gi, model), tag, compiled, error))
                            throw std::runtime_error("HLSL compile failed for " + s.name + " (" + sourcePath.string() + "):\n" + error);
                        fs::create_directories(g_hlslCacheDir, ec);
                        writeFile(cacheFile, compiled);
                        g_hlslCache.emplace(cacheKey, compiled);
                        s.bytecode = std::move(compiled);
                    }
                } else {
                    std::vector<uint8_t> compiled;
                    std::string error;
                    // The tag only names the temporary fxc output; keep it filesystem-safe.
                    std::string tagText = fs::path(ref.file).generic_string();
                    std::string tag = Sha256::hex(std::vector<uint8_t>(tagText.begin(), tagText.end()));
                    if (!compileHlsl(fxc, sourcePath, stageProfile(gi, model), tag, compiled, error))
                        throw std::runtime_error("HLSL compile failed for " + s.name + " (" + sourcePath.string() + "):\n" + error);
                    g_hlslCache.emplace(cacheKey, compiled);
                    s.bytecode = std::move(compiled);
                }
            } else {
                s.bytecode = readFile(sourcePath);
            }
        }
    }
    if (index != parsed.shaderSources.size()) throw std::runtime_error("extra shader source references in " + xmlPath.string());
    if (outSources) *outSources = parsed.shaderSources;
    return e;
}

std::vector<uint8_t> buildEffectBytes(const fs::path& xmlPath, const fs::path& fxc) {
    Effect e = loadEffectFromXml(xmlPath, fxc);
    return serializeEffect(e);
}

void extractOne(const fs::path& fxcPath, const fs::path& xmlPath, const Options& opt, size_t& asmOk, size_t& asmFail) {
    std::vector<uint8_t> data = readFile(fxcPath);
    Effect e = parseEffect(data);
    std::vector<ShaderSourceRef> sources;
    sources.reserve(shaderCount(e));
    for (const auto& g : e.groups) {
        for (const auto& s : g.shaders) {
            std::string hash = Sha256::hex(s.bytecode);
            sources.push_back({hash + ".cso", "cso"});
            fs::path cso = opt.store / (hash + ".cso");
            std::error_code ec;
            if (!fs::exists(cso, ec)) writeFile(cso, s.bytecode);
            if (!opt.noAsm) {
                fs::path asmPath = opt.store / (hash + ".asm");
                if (!fs::exists(asmPath, ec)) {
                    std::string text, error;
                    if (disassembleShader(s.bytecode, text, error)) {
                        writeFile(asmPath, text);
                        ++asmOk;
                    } else {
                        ++asmFail;
                        if (!opt.quiet) std::cerr << "warning: " << relPath(opt.store, fxcPath) << " / " << s.name << ": " << error << "\n";
                    }
                } else ++asmOk;
            }
        }
    }
    std::string xml = effectToXml(e, sources);
    writeFile(xmlPath, xml);
}

bool isUnderSourceStore(const fs::path& root, const fs::path& p) {
    std::string rel = relPath(root, p);
    return rel.rfind("_source/", 0) == 0 || rel.find("/_source/") != std::string::npos;
}

int extractTree(const fs::path& input, const fs::path& output, Options opt) {
    if (!fs::is_directory(input)) { std::cerr << "error: input folder not found: " << input.string() << "\n"; return 2; }
    if (opt.store.empty()) opt.store = output / "_source";
    fs::create_directories(opt.store);
    std::vector<fs::path> files;
    for (auto it = fs::recursive_directory_iterator(input); it != fs::recursive_directory_iterator(); ++it) {
        if (!it->is_regular_file()) continue;
        if (it->path().extension() == ".fxc") files.push_back(it->path());
    }
    std::sort(files.begin(), files.end());
    size_t ok = 0, failed = 0, asmOk = 0, asmFail = 0;
    long processed = 0;
    for (const auto& f : files) {
        if (opt.limit >= 0 && processed >= opt.limit) break;
        std::string rel = relPath(input, f);
        fs::path out = output / fs::path(rel);
        out.replace_extension(".xml");
        try {
            extractOne(f, out, opt, asmOk, asmFail);
            ++ok;
        } catch (const std::exception& e) {
            ++failed;
            std::cerr << "error: " << f.string() << ": " << e.what() << "\n";
        }
        ++processed;
        if (!opt.quiet && (processed % 250 == 0)) std::cout << "  extracted " << processed << "/" << files.size() << "\n";
    }
    std::cout << "extract-tree: " << ok << " containers, " << failed << " failed, "
              << asmOk << " shader sources, " << asmFail << " disassembly failures\n";
    return failed ? 1 : 0;
}

int buildTree(const fs::path& source, const fs::path& output, Options opt) {
    if (!fs::is_directory(source)) { std::cerr << "error: source folder not found: " << source.string() << "\n"; return 2; }
    if (opt.store.empty()) opt.store = source / "_source";
    std::vector<fs::path> files;
    for (auto it = fs::recursive_directory_iterator(source); it != fs::recursive_directory_iterator(); ++it) {
        if (!it->is_regular_file()) continue;
        if (it->path().extension() != ".xml") continue;
        if (isUnderSourceStore(source, it->path())) continue;
        files.push_back(it->path());
    }
    std::sort(files.begin(), files.end());
    size_t ok = 0, failed = 0;
    long processed = 0;
    for (const auto& f : files) {
        if (opt.limit >= 0 && processed >= opt.limit) break;
        std::string rel = relPath(source, f);
        fs::path out = fxcPathForXml(output / fs::path(rel));
        try {
            std::vector<uint8_t> bytes = buildEffectBytes(f, opt.fxc);
            writeFile(out, bytes);
            ++ok;
        } catch (const std::exception& e) {
            ++failed;
            std::cerr << "error: " << f.string() << ": " << e.what() << "\n";
        }
        ++processed;
        if (!opt.quiet && (processed % 250 == 0)) std::cout << "  built " << processed << "/" << files.size() << "\n";
    }
    std::cout << "build-tree: " << ok << " containers, " << failed << " failed\n";
    return failed ? 1 : 0;
}

int verifyTree(const fs::path& source, const fs::path& reference, Options opt) {
    if (!fs::is_directory(source)) { std::cerr << "error: source folder not found: " << source.string() << "\n"; return 2; }
    if (!fs::is_directory(reference)) { std::cerr << "error: reference folder not found: " << reference.string() << "\n"; return 2; }
    if (opt.store.empty()) opt.store = source / "_source";
    std::vector<fs::path> files;
    for (auto it = fs::recursive_directory_iterator(source); it != fs::recursive_directory_iterator(); ++it) {
        if (!it->is_regular_file()) continue;
        if (it->path().extension() != ".xml") continue;
        if (isUnderSourceStore(source, it->path())) continue;
        files.push_back(it->path());
    }
    std::sort(files.begin(), files.end());
    size_t ok = 0, failed = 0, missing = 0;
    for (const auto& f : files) {
        std::string rel = relPath(source, f);
        fs::path ref = fxcPathForXml(reference / fs::path(rel));
        try {
            std::vector<uint8_t> bytes = buildEffectBytes(f, opt.fxc);
            if (!fs::exists(ref)) { ++missing; std::cerr << "missing reference: " << ref.string() << "\n"; continue; }
            std::vector<uint8_t> expected = readFile(ref);
            if (bytes == expected) ++ok;
            else { ++failed; std::cerr << "mismatch: " << rel << "\n"; }
        } catch (const std::exception& e) {
            ++failed;
            std::cerr << "error: " << f.string() << ": " << e.what() << "\n";
        }
    }
    std::cout << "verify-tree: " << ok << " identical, " << failed << " mismatched, " << missing << " missing\n";
    return (failed || missing) ? 1 : 0;
}


struct HlslJob {
    std::string hash;
    fs::path file;
    std::string profile;
};

int warmHlsl(const fs::path& source, const fs::path& cacheDir, const fs::path& fxc, int jobs) {
    if (!fs::is_directory(source)) { std::cerr << "error: source folder not found: " << source.string() << "\n"; return 2; }
    if (cacheDir.empty()) { std::cerr << "error: warm-hlsl needs --hlsl-cache DIR\n"; return 2; }
    std::error_code ec;
    fs::create_directories(cacheDir, ec);
    std::unordered_map<std::string, HlslJob> unique;
    std::vector<fs::path> xmls;
    for (auto it = fs::recursive_directory_iterator(source); it != fs::recursive_directory_iterator(); ++it) {
        if (it->is_regular_file() && it->path().extension() == ".xml") xmls.push_back(it->path());
    }
    std::sort(xmls.begin(), xmls.end());
    size_t missingModel = 0;
    for (const auto& xmlPath : xmls) {
        std::ifstream f(xmlPath, std::ios::binary);
        if (!f) continue;
        std::string text((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
        ParsedEffectSource parsed;
        try { parsed = xmlToEffect(text); }
        catch (const std::exception& e) { std::cerr << "warning: " << xmlPath.string() << ": " << e.what() << "\n"; continue; }
        fs::path base = xmlPath.parent_path();
        size_t index = 0;
        for (int gi = 0; gi < 6; ++gi) {
            for (const auto& sh : parsed.effect.groups[gi].shaders) {
                if (index >= parsed.shaderSources.size()) break;
                const ShaderSourceRef ref = parsed.shaderSources[index++];
                if (ref.dataType != "hlsl" || ref.file.empty()) continue;
                if (sh.model.empty()) { ++missingModel; continue; }
                fs::path file = base / fs::path(ref.file);
                std::vector<uint8_t> bytes;
                try { bytes = readFile(file); } catch (...) { continue; }
                std::string key = hlslCacheKey(bytes, stageProfile(gi, sh.model), fxc);
                if (unique.find(key) == unique.end())
                    unique.emplace(key, HlslJob{key, file, stageProfile(gi, sh.model)});
            }
        }
    }
    std::vector<HlslJob> todo;
    size_t cached = 0;
    for (auto& [key, job] : unique) {
        fs::path cacheFile = cacheDir / (key + ".cso");
        if (fs::exists(cacheFile, ec) && fs::file_size(cacheFile, ec) > 0) { ++cached; continue; }
        todo.push_back(job);
    }
    std::cout << "warm-hlsl: " << unique.size() << " unique HLSL, " << cached << " cached, " << todo.size() << " to compile\n";
    if (todo.empty()) return 0;
    if (jobs <= 0) jobs = 8;
    std::atomic<size_t> next{0};
    std::atomic<size_t> ok{0}, failed{0};
    std::mutex errorMutex;
    std::vector<std::string> errors;
    std::vector<std::thread> threads;
    for (int t = 0; t < jobs; ++t) {
        threads.emplace_back([&]() {
            for (;;) {
                size_t i = next.fetch_add(1);
                if (i >= todo.size()) break;
                const HlslJob& job = todo[i];
                std::vector<uint8_t> compiled;
                std::string error;
                std::ifstream hf(job.file, std::ios::binary);
                if (!hf) { ++failed; continue; }
                std::string sourceText((std::istreambuf_iterator<char>(hf)), std::istreambuf_iterator<char>());
                if (compileHlslInProcess(sourceText, job.profile, compiled, error)) {
                    writeFile(cacheDir / (job.hash + ".cso"), compiled);
                    ++ok;
                } else {
                    ++failed;
                    std::lock_guard<std::mutex> lock(errorMutex);
                    if (errors.size() < 50) errors.push_back(job.file.string() + " (" + job.profile + "): " + error);
                }
            }
        });
    }
    for (auto& th : threads) th.join();
    std::cout << "warm-hlsl: " << ok << " compiled, " << failed << " failed\n";
    for (const auto& e : errors) std::cerr << "error: " << e << "\n";
    if (missingModel) std::cerr << "warning: " << missingModel << " shaders have no Model attribute\n";
    return failed ? 1 : 0;
}

int manifestTree(const fs::path& root, const fs::path& output) {
    if (!fs::is_directory(root)) { std::cerr << "error: folder not found: " << root.string() << "\n"; return 2; }
    std::vector<fs::path> files;
    for (auto it = fs::recursive_directory_iterator(root); it != fs::recursive_directory_iterator(); ++it)
        if (it->is_regular_file()) files.push_back(it->path());
    std::sort(files.begin(), files.end());
    std::string text;
    for (const auto& f : files) {
        std::vector<uint8_t> data = readFile(f);
        text += relPath(root, f);
        text.push_back('\t');
        text += std::to_string(data.size());
        text.push_back('\t');
        text += Sha256::hex(data);
        text.push_back('\n');
    }
    if (output.empty()) std::cout << text;
    else writeFile(output, text);
    return 0;
}

void usage() {
    std::cout <<
        "mp3shadertool - Max Payne 3 rgxe shader tool\n\n"
        "USAGE:\n"
        "  mp3shadertool build-tree <source-dir> <output-dir> [--hlsl-cache DIR]\n"
        "  mp3shadertool warm-hlsl <source-dir> --hlsl-cache DIR\n"
        "  mp3shadertool verify-tree <source-dir> <reference-dir> [--hlsl-cache DIR]\n"
        "  mp3shadertool build <file.fxc.xml> <file.fxc> [--hlsl-cache DIR]\n"
        "  mp3shadertool extract-tree <game-shaders-dir> <source-dir> [--no-asm]\n"
        "  mp3shadertool extract <file.fxc> <file.xml> [--store DIR]\n"
        "  mp3shadertool manifest <dir> [file]\n"
        "  mp3shadertool hash <file>\n\n"
        "Source layout:\n"
        "  <profile>/<container>.fxc.xml\n"
        "  <profile>/<container>/<shader>.hlsl\n\n"
        "warm-hlsl compiles each unique HLSL content once into the cache. build-tree\n"
        "reconstructs every container from the XML and the HLSL (or a .cso when a\n"
        "shader is explicitly marked DataType=\"cso\").\n";
}

int realMain(int argc, char** argv) {
    if (argc < 2) { usage(); return 2; }
    initializeD3DTools(argv[0]);
    std::string command = argv[1];
    if (command == "help" || command == "-h" || command == "--help") { usage(); return 0; }

    std::vector<std::string> positional;
    Options opt;
    for (int i = 2; i < argc; ++i) {
        std::string a = argv[i];
        if (a == "--store") {
            if (i + 1 >= argc) { std::cerr << "error: --store needs a folder\n"; return 2; }
            opt.store = argv[++i];
        } else if (a == "--no-asm") opt.noAsm = true;
        else if (a == "--use-hlsl") opt.useHlsl = true;
        else if (a == "--hlsl-cache") {
            if (i + 1 >= argc) { std::cerr << "error: --hlsl-cache needs a folder\n"; return 2; }
            opt.hlslCache = argv[++i];
        }
        else if (a == "--fxc") {
            if (i + 1 >= argc) { std::cerr << "error: --fxc needs a path\n"; return 2; }
            opt.fxc = argv[++i];
        }
        else if (a == "--quiet") opt.quiet = true;
        else if (a == "--limit") {
            if (i + 1 >= argc) { std::cerr << "error: --limit needs a number\n"; return 2; }
            opt.limit = std::stol(argv[++i]);
        } else if (!a.empty() && a[0] == '-') {
            std::cerr << "error: unknown option " << a << "\n";
            return 2;
        } else positional.push_back(a);
    }

    if (opt.fxc.empty()) opt.fxc = findFxc(argv[0]);
    if (!opt.hlslCache.empty()) g_hlslCacheDir = opt.hlslCache;

    try {
        if (command == "warm-hlsl") {
            if (positional.size() != 1) { usage(); return 2; }
            int jobs = 8;
            if (const char* j = std::getenv("NUMBER_OF_PROCESSORS")) { int v = std::atoi(j); if (v > 0) jobs = v; }
            return warmHlsl(positional[0], opt.hlslCache, opt.fxc, jobs);
        }
        if (command == "manifest") {
            if (positional.size() < 1 || positional.size() > 2) { usage(); return 2; }
            return manifestTree(positional[0], positional.size() == 2 ? fs::path(positional[1]) : fs::path());
        }
        if (command == "hash") {
            if (positional.size() != 1) { usage(); return 2; }
            std::cout << Sha256::hex(readFile(positional[0])) << "\n";
            return 0;
        }
        if (command == "extract") {
            if (positional.size() != 2) { usage(); return 2; }
            fs::path xml = positional[1];
            if (opt.store.empty()) opt.store = xml.parent_path() / "_source";
            fs::create_directories(opt.store);
            size_t asmOk = 0, asmFail = 0;
            extractOne(positional[0], xml, opt, asmOk, asmFail);
            std::cout << "extracted " << positional[0] << " -> " << xml.string() << "\n";
            return 0;
        }
        if (command == "extract-tree") {
            if (positional.size() != 2) { usage(); return 2; }
            return extractTree(positional[0], positional[1], opt);
        }
        if (command == "build") {
            if (positional.size() != 2) { usage(); return 2; }
            fs::path xml = positional[0];
            if (opt.store.empty()) opt.store = xml.parent_path() / "_source";
            std::vector<uint8_t> bytes = buildEffectBytes(xml, opt.fxc);
            writeFile(positional[1], bytes);
            std::cout << "built " << positional[0] << " -> " << positional[1] << " (" << bytes.size() << " bytes)\n";
            return 0;
        }
        if (command == "build-tree") {
            if (positional.size() != 2) { usage(); return 2; }
            return buildTree(positional[0], positional[1], opt);
        }
        if (command == "verify-tree") {
            if (positional.size() != 2) { usage(); return 2; }
            return verifyTree(positional[0], positional[1], opt);
        }
        std::cerr << "error: unknown command " << command << "\n";
        usage();
        return 2;
    } catch (const std::exception& e) {
        std::cerr << "error: " << e.what() << "\n";
        return 1;
    }
}
} // namespace

int main(int argc, char** argv) {
    return realMain(argc, argv);
}
