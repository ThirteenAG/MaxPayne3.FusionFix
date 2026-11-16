// Minimal SHA-256 (public domain style implementation).
#pragma once
#include <cstdint>
#include <cstddef>
#include <array>
#include <string>
#include <vector>

namespace shadertool {

class Sha256 {
public:
    Sha256() { reset(); }
    void reset();
    void update(const void* data, size_t len);
    void update(const std::vector<uint8_t>& data) { if (!data.empty()) update(data.data(), data.size()); }
    std::array<uint8_t, 32> finish();
    static std::array<uint8_t, 32> hash(const void* data, size_t len);
    static std::array<uint8_t, 32> hash(const std::vector<uint8_t>& data) { return hash(data.data(), data.size()); }
    static std::string hex(const std::array<uint8_t, 32>& digest);
    static std::string hex(const std::vector<uint8_t>& data) { return hex(hash(data)); }
private:
    void transform(const uint8_t* block);
    uint32_t state_[8];
    uint64_t bitlen_;
    uint8_t buffer_[64];
    size_t bufferLen_;
};

} // namespace shadertool
