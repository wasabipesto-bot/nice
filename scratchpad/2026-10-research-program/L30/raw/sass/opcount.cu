// Static SASS op counts of the per-survivor prefilter forms (base 62, f0 3, k 6, k2 8),
// mirroring common/src/cubecl_join.rs (mid_pass, walk_pf, walk_pf32). Fully unrolled: static = dynamic count.
// nvcc -arch=sm_86 -cubin -O3 opcount.cu -o opcount.cubin && cuobjdump -sass opcount.cubin
#include <stdint.h>
#define B 62u
#define F0 3
#define K2 8
__device__ __forceinline__ bool mid_pass(uint32_t t, uint32_t r0, const uint32_t* __restrict__ top_m, const uint32_t* __restrict__ top_x) {
    uint32_t pm = top_x[2 * t];
    uint64_t m = 0;
    if (top_x[2 * t + 1] != 0) m = ((uint64_t)top_m[2 * t + 1] << 32) | top_m[2 * t];
    uint32_t d[K2];
    uint32_t x = r0;
#pragma unroll
    for (int j = 0; j < F0; j++) { d[j] = x % B; x /= B; }
    uint32_t y = pm;
#pragma unroll
    for (int j = F0; j < K2; j++) { d[j] = y % B; y /= B; }
    uint32_t sq[K2]; uint32_t carry = 0;
#pragma unroll
    for (int pos = 0; pos < K2; pos++) {
        uint32_t col = carry;
#pragma unroll
        for (int i2 = 0; i2 <= pos; i2++) col += d[i2] * d[pos - i2];
        sq[pos] = col % B; carry = col / B;
    }
    bool ok = true; carry = 0;
#pragma unroll
    for (int pos = 0; pos < K2; pos++) {
        uint32_t col = carry;
#pragma unroll
        for (int i2 = 0; i2 <= pos; i2++) col += sq[i2] * d[pos - i2];
        uint32_t g3 = col % B; carry = col / B;
        uint32_t g2 = sq[pos];
        uint64_t bb = (1ull << g2) | (1ull << g3);
        if (g2 == g3 || (m & bb) != 0) ok = false;
        m |= bb;
    }
    return ok;
}
__device__ __forceinline__ bool walk_pf(uint32_t ac, uint32_t pc, uint32_t dmv, uint32_t mlo, uint32_t mhi, uint32_t tlo, uint32_t thi) {
    const uint32_t bb2 = B * B;
    uint32_t dm = dmv & 0xFFFF;
    uint64_t seen = ((uint64_t)mhi << 32) | mlo;
    if ((dmv >> 16) != 0) seen |= ((uint64_t)thi << 32) | tlo;
    uint32_t x2 = ((ac & 0xFFFF) + (pc & 0xFFFF) * dm) % bb2;
    uint32_t x3 = ((ac >> 16) + (pc >> 16) * dm) % bb2;
    uint32_t a2 = x2 % B, a3 = x3 % B, c2 = x2 / B, c3 = x3 / B;
    uint64_t b6 = (1ull << a2) | (1ull << a3), b7 = (1ull << c2) | (1ull << c3);
    return !(a2 == a3 || c2 == c3 || (seen & b6) != 0 || ((seen | b6) & b7) != 0);
}
__device__ __forceinline__ uint32_t bit_in(uint32_t lo, uint32_t hi, uint32_t g) { uint32_t w = g < 32 ? lo : hi; return (w >> (g & 31)) & 1; }
__device__ __forceinline__ bool walk_pf32(uint32_t ac, uint32_t pc, uint32_t dmv, uint32_t mlo, uint32_t mhi, uint32_t tlo, uint32_t thi) {
    const uint32_t bb2 = B * B;
    uint32_t dm = dmv & 0xFFFF;
    uint32_t sm = (dmv >> 16) != 0 ? 0xFFFFFFFFu : 0u;
    uint32_t lo = mlo | (tlo & sm), hi = mhi | (thi & sm);
    uint32_t x2 = ((ac & 0xFFFF) + (pc & 0xFFFF) * dm) % bb2;
    uint32_t x3 = ((ac >> 16) + (pc >> 16) * dm) % bb2;
    uint32_t a2 = x2 % B, a3 = x3 % B, c2 = x2 / B, c3 = x3 / B;
    uint32_t hit = bit_in(lo, hi, a2) | bit_in(lo, hi, a3) | bit_in(lo, hi, c2) | bit_in(lo, hi, c3);
    return !(hit || a2 == a3 || c2 == c3 || a2 == c2 || a2 == c3 || a3 == c2 || a3 == c3);
}
extern "C" __global__ void k_empty(const uint32_t* a, const uint32_t* b, uint32_t* out) {
    int i = threadIdx.x + blockIdx.x * blockDim.x; out[i] = a[i] ^ b[i];
}
extern "C" __global__ void k_mid(const uint32_t* s_t, const uint32_t* s_r, const uint32_t* top_m, const uint32_t* top_x, uint32_t* out) {
    int i = threadIdx.x + blockIdx.x * blockDim.x; out[i] = mid_pass(s_t[i], s_r[i], top_m, top_x);
}
extern "C" __global__ void k_pf(const uint32_t* v, uint32_t* out) {
    int i = threadIdx.x + blockIdx.x * blockDim.x; const uint32_t* p = v + 7 * i;
    out[i] = walk_pf(p[0], p[1], p[2], p[3], p[4], p[5], p[6]);
}
extern "C" __global__ void k_pf32(const uint32_t* v, uint32_t* out) {
    int i = threadIdx.x + blockIdx.x * blockDim.x; const uint32_t* p = v + 7 * i;
    out[i] = walk_pf32(p[0], p[1], p[2], p[3], p[4], p[5], p[6]);
}
