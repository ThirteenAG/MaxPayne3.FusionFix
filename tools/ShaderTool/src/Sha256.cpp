#include "Sha256.h"
#include <cstring>
#include <cstdio>

namespace shadertool {
namespace {
constexpr uint32_t K[64] = {
    0x428a2f98u,0x71374491u,0xb5c0fbcfu,0xe9b5dba5u,0x3956c25bu,0x59f111f1u,0x923f82a4u,0xab1c5ed5u,
    0xd807aa98u,0x12835b01u,0x243185beu,0x550c7dc3u,0x72be5d74u,0x80deb1feu,0x9bdc06a7u,0xc19bf174u,
    0xe49b69c1u,0xefbe4786u,0x0fc19dc6u,0x240ca1ccu,0x2de92c6fu,0x4a7484aau,0x5cb0a9dcu,0x76f988dau,
    0x983e5152u,0xa831c66du,0xb00327c8u,0xbf597fc7u,0xc6e00bf3u,0xd5a79147u,0x06ca6351u,0x14292967u,
    0x27b70a85u,0x2e1b2138u,0x4d2c6dfcu,0x53380d13u,0x650a7354u,0x766a0abbu,0x81c2c92eu,0x92722c85u,
    0xa2bfe8a1u,0xa81a664bu,0xc24b8b70u,0xc76c51a3u,0xd192e819u,0xd6990624u,0xf40e3585u,0x106aa070u,
    0x19a4c116u,0x1e376c08u,0x2748774cu,0x34b0bcb5u,0x391c0cb3u,0x4ed8aa4au,0x5b9cca4fu,0x682e6ff3u,
    0x748f82eeu,0x78a5636fu,0x84c87814u,0x8cc70208u,0x90befffau,0xa4506cebu,0xbef9a3f7u,0xc67178f2u};
inline uint32_t rotr(uint32_t x, int n){ return (x >> n) | (x << (32 - n)); }
}
void Sha256::reset() {
    state_[0]=0x6a09e667u;state_[1]=0xbb67ae85u;state_[2]=0x3c6ef372u;state_[3]=0xa54ff53au;
    state_[4]=0x510e527fu;state_[5]=0x9b05688cu;state_[6]=0x1f83d9abu;state_[7]=0x5be0cd19u;
    bitlen_=0; bufferLen_=0; std::memset(buffer_,0,sizeof(buffer_));
}
void Sha256::transform(const uint8_t* block) {
    uint32_t w[64];
    for (int i=0;i<16;i++) w[i]=(uint32_t(block[i*4])<<24)|(uint32_t(block[i*4+1])<<16)|(uint32_t(block[i*4+2])<<8)|uint32_t(block[i*4+3]);
    for (int i=16;i<64;i++) {
        uint32_t s0=rotr(w[i-15],7)^rotr(w[i-15],18)^(w[i-15]>>3);
        uint32_t s1=rotr(w[i-2],17)^rotr(w[i-2],19)^(w[i-2]>>10);
        w[i]=w[i-16]+s0+w[i-7]+s1;
    }
    uint32_t a=state_[0],b=state_[1],c=state_[2],d=state_[3],e=state_[4],f=state_[5],g=state_[6],h=state_[7];
    for (int i=0;i<64;i++) {
        uint32_t S1=rotr(e,6)^rotr(e,11)^rotr(e,25);
        uint32_t ch=(e&f)^((~e)&g);
        uint32_t t1=h+S1+ch+K[i]+w[i];
        uint32_t S0=rotr(a,2)^rotr(a,13)^rotr(a,22);
        uint32_t maj=(a&b)^(a&c)^(b&c);
        uint32_t t2=S0+maj;
        h=g;g=f;f=e;e=d+t1;d=c;c=b;b=a;a=t1+t2;
    }
    state_[0]+=a;state_[1]+=b;state_[2]+=c;state_[3]+=d;state_[4]+=e;state_[5]+=f;state_[6]+=g;state_[7]+=h;
}
void Sha256::update(const void* data, size_t len) {
    const uint8_t* p = static_cast<const uint8_t*>(data);
    bitlen_ += uint64_t(len) * 8;
    while (len > 0) {
        size_t n = 64 - bufferLen_;
        if (n > len) n = len;
        std::memcpy(buffer_ + bufferLen_, p, n);
        bufferLen_ += n; p += n; len -= n;
        if (bufferLen_ == 64) { transform(buffer_); bufferLen_ = 0; }
    }
}
std::array<uint8_t,32> Sha256::finish() {
    uint64_t bits = bitlen_;
    uint8_t pad = 0x80;
    update(&pad, 1);
    uint8_t zero = 0;
    while (bufferLen_ != 56) update(&zero, 1);
    uint8_t lenbuf[8];
    for (int i=0;i<8;i++) lenbuf[i]=uint8_t(bits >> (56 - i*8));
    update(lenbuf, 8);
    std::array<uint8_t,32> out{};
    for (int i=0;i<8;i++) {
        out[i*4]  =uint8_t(state_[i]>>24); out[i*4+1]=uint8_t(state_[i]>>16);
        out[i*4+2]=uint8_t(state_[i]>>8);  out[i*4+3]=uint8_t(state_[i]);
    }
    reset();
    return out;
}
std::array<uint8_t,32> Sha256::hash(const void* data, size_t len) { Sha256 s; s.update(data,len); return s.finish(); }
std::string Sha256::hex(const std::array<uint8_t,32>& d) {
    static const char* h="0123456789abcdef";
    std::string s; s.resize(64);
    for (int i=0;i<32;i++){ s[i*2]=h[d[i]>>4]; s[i*2+1]=h[d[i]&15]; }
    return s;
}
} // namespace shadertool
