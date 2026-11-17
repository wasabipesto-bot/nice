// G2 benchmark: one base-64 super-unit (digits 4..8 fixed = PIP, all 64 units of digit 9), shape (f0 4, k 10).
// Throwaway. Build on the box:  nvcc -O3 -arch=sm_86 -std=c++17 -o g2bench g2bench.cu
// CPU-only test build (ivory):   g++ -O2 -std=c++17 -x c++ -DCPU_ONLY -o g2bench_cpu g2bench.cu
// Usage: g2bench DIR [reps]   (DIR holds tops.bin, surv.bin, meta.txt from `g2proto dumpsu 64 4 10 PIP DIR`)
//
// Base 64 is a power of two: digit j of x is (x >> 6j) & 63, and everything mod 64^10 is mod 2^60, so the
// whole bottom side is u64 arithmetic with shifts and masks.
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <vector>
#include <algorithm>
#include <string>
#include <chrono>
#include <map>
#ifndef CPU_ONLY
#include <cuda_runtime.h>
#include <cub/cub.cuh>
#endif
typedef unsigned long long u64;
typedef unsigned int u32;
typedef unsigned __int128 u128;

static const int B = 64, M = 63, NROOT = 8;
static const int ROOTS[NROOT] = {0, 6, 21, 27, 35, 42, 48, 62};
static const u64 MASK60 = (1ULL << 60) - 1;

struct Top { u32 d; u64 h, mask; u128 lo, hi; };

// ---------------------------------------------------------------- host: inputs
static std::vector<Top> load_tops(const std::string &dir) {
    std::vector<Top> v;
    FILE *f = fopen((dir + "/tops.bin").c_str(), "rb");
    if (!f) { perror("tops.bin"); exit(1); }
    unsigned char rec[52];
    while (fread(rec, 52, 1, f) == 1) {
        Top t; memcpy(&t.d, rec, 4); memcpy(&t.h, rec + 4, 8); memcpy(&t.mask, rec + 12, 8);
        memcpy(&t.lo, rec + 20, 16); memcpy(&t.hi, rec + 36, 16); v.push_back(t);
    }
    fclose(f);
    return v;
}
static std::vector<std::vector<u128>> load_surv(const std::string &dir, std::vector<long> &cnt, u64 &pip, u128 &start, u128 &end) {
    FILE *m = fopen((dir + "/meta.txt").c_str(), "r");
    char line[512]; cnt.assign(64, 0);
    while (fgets(line, sizeof line, m)) {
        unsigned long long a, b2, c, d, e, g; char sbuf[64], ebuf[64];
        int f0, k;
        if (sscanf(line, "b %llu f0 %d k %d pip %llu start %63s end %63s", &a, &f0, &k, &b2, sbuf, ebuf) == 6) {
            pip = b2; start = 0; end = 0;
            for (char *p = sbuf; *p; p++) start = start * 10 + (*p - '0');
            for (char *p = ebuf; *p; p++) end = end * 10 + (*p - '0');
        }
        long s;
        if (sscanf(line, "unit %llu uval %llu tops %llu tops_tested %llu bottoms %llu pairs %llu surv %ld", &a, &b2, &c, &d, &e, &g, &s) == 7) cnt[a] = s;
    }
    fclose(m);
    std::vector<std::vector<u128>> out(64);
    FILE *f = fopen((dir + "/surv.bin").c_str(), "rb");
    for (int d = 0; d < 64; d++) { out[d].resize(cnt[d]); if (cnt[d] && fread(out[d].data(), 16, cnt[d], f) != (size_t)cnt[d]) { fprintf(stderr, "short surv\n"); exit(1); } }
    fclose(f);
    return out;
}

// ---------------------------------------------------------------- shared arithmetic (host and device)
#ifdef CPU_ONLY
#define HD
#else
#define HD __host__ __device__
#endif
static HD inline int dig(u64 x, int j) { return (int)((x >> (6 * j)) & 63); }

// depth-4 root: r4 < 2^24 with digits 0..3 of r4^2 and r4^3 all distinct -> mask, else 0
static HD inline u64 root_mask(u64 r4) {
    u64 s = (r4 * r4) & MASK60, c = (s * r4) & MASK60, m = 0;
    for (int j = 0; j < 4; j++) {
        u64 a = 1ULL << dig(s, j), b = 1ULL << dig(c, j);
        if ((m & a) || (m & b) || a == b) return 0;
        m |= a | b;
    }
    return m;
}
struct Parent { u64 r, mask; u32 cacc; /* c2 | c3<<8 | a2<<16 | a3<<24 */ int cls; };
// extend a root by the super-unit's digits 4..8 (r = r4 + pip*2^24); returns false if a digit repeats
static HD inline bool make_parent(u64 r4, u64 rmask, u64 pip, Parent &p) {
    u64 r = r4 + (pip << 24);
    u64 s = (r * r) & MASK60, c = (s * r) & MASK60, m = rmask;
    for (int j = 4; j < 9; j++) {
        u64 a = 1ULL << dig(s, j), b = 1ULL << dig(c, j);
        if ((m & a) || (m & b) || a == b) return false;
        m |= a | b;
    }
    u64 r0 = r & 63;
    p.r = r; p.mask = m; p.cls = (int)(r % 63);
    p.cacc = (u32)dig(s, 9) | ((u32)dig(c, 9) << 8) | ((u32)((2 * r0) & 63) << 16) | ((u32)((3 * r0 * r0) & 63) << 24);
    return true;
}
// child for unit digit d: returns child mask or 0 if not certified
static HD inline u64 child_mask(u64 pm, u32 cacc, u32 d) {
    u32 e2 = ((cacc & 63) + ((cacc >> 16) & 63) * d) & 63;
    u32 e3 = (((cacc >> 8) & 63) + ((cacc >> 24) & 63) * d) & 63;
    u64 add = (1ULL << e2) | (1ULL << e3);
    if (e2 == e3 || (pm & add)) return 0;
    return pm | add;
}
static HD inline u32 key8(u64 mask, const unsigned char *rankdig) {
    u32 k = 0;
    for (int i = 0; i < 8; i++) k |= (u32)((mask >> rankdig[i]) & 1) << (7 - i);
    return k;
}

// ---------------------------------------------------------------- the per-(class, unit) algorithm, CPU reference
struct Counts { u64 children = 0, chunks = 0, flat = 0, kept = 0, surv = 0; };
// tops arranged per (d, ct): tseg[(d*63+ct)*2] = begin, +1 = end into tmask/tidx
static void cpu_block(int c, u32 d, const std::vector<Parent> &P, const std::vector<int> &pseg,
                      const std::vector<u64> &tmask, const std::vector<int> &tseg, bool skip,
                      Counts &cnt, std::vector<std::pair<u32, u32>> &out) {
    int cc = (c + (int)d) % M;
    std::vector<int> probes;
    for (int i = 0; i < NROOT; i++) {
        int ct = (ROOTS[i] - cc + M) % M;
        for (int t = tseg[(d * M + ct) * 2]; t < tseg[(d * M + ct) * 2 + 1]; t++) probes.push_back(t);
    }
    std::vector<u64> cm; std::vector<u32> cp;
    for (int p = pseg[c]; p < pseg[c + 1]; p++) {
        u64 m = child_mask(P[p].mask, P[p].cacc, d);
        if (m) { cm.push_back(m); cp.push_back(p); }
    }
    cnt.children += cm.size();
    int nch = (int)((cm.size() + 63) / 64);
    cnt.chunks += nch;
    for (int q = 0; q < nch; q++) {
        int n0 = q * 64, n = std::min<int>(64, (int)cm.size() - n0);
        u64 sl[64] = {0}, common = ~0ULL, valid = (n == 64) ? ~0ULL : ((1ULL << n) - 1);
        for (int i = 0; i < n; i++) { u64 m = cm[n0 + i]; common &= m; for (int v = 0; v < 64; v++) if ((m >> v) & 1) sl[v] |= 1ULL << i; }
        cnt.flat += probes.size();
        for (int t : probes) {
            u64 tm = tmask[t];
            if (skip && (common & tm)) continue;
            cnt.kept++;
            u64 acc = 0, x = tm;
            while (x) { acc |= sl[__builtin_ctzll(x)]; x &= x - 1; }
            u64 w = ~acc & valid;
            while (w) { int i = __builtin_ctzll(w); out.push_back({(u32)t, cp[n0 + i]}); cnt.surv++; w &= w - 1; }
        }
    }
}

// ---------------------------------------------------------------- device
#ifndef CPU_ONLY
#define CK(x) do { cudaError_t e_ = (x); if (e_ != cudaSuccess) { fprintf(stderr, "CUDA %s at %s:%d\n", cudaGetErrorString(e_), __FILE__, __LINE__); exit(1); } } while (0)
__constant__ unsigned char c_rank[8];
__constant__ int c_roots[NROOT];

// K1: parents from roots (flag + record per root, compacted later by cub::DeviceSelect, stable)
__global__ void k_parents(const u32 *r4, const u64 *rmask, int nroots, u64 pip, u64 *pr, u64 *pm, u32 *pcacc,
                          unsigned short *pkey, unsigned char *flag) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= nroots) return;
    Parent p;
    bool ok = make_parent(r4[i], rmask[i], pip, p);
    flag[i] = ok;
    if (ok) {
        pr[i] = p.r; pm[i] = p.mask; pcacc[i] = p.cacc;
        pkey[i] = (unsigned short)(p.cls * 256 + (255 - key8(p.mask, c_rank)));
    }
}
__global__ void k_gather(const u32 *perm, int n, const u64 *pr, const u64 *pm, const u32 *pcacc,
                         u64 *sr, u64 *sm, u32 *scacc) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= n) return;
    u32 j = perm[i]; sr[i] = pr[j]; sm[i] = pm[j]; scacc[i] = pcacc[j];
}
__global__ void k_segments(const unsigned short *skey, int n, int *pseg) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= n) return;
    int c = skey[i] >> 8;
    int prev = (i == 0) ? -1 : (skey[i - 1] >> 8);
    for (int x = prev + 1; x <= c; x++) pseg[x] = i;
    if (i == n - 1) for (int x = c + 1; x <= M; x++) pseg[x] = n;
}

// prep v2: one stable cub::DeviceSelect::If over the roots with make_parent as the predicate, then build the selected
// parents compactly (recomputing make_parent), so the 9.3M-root pass writes nothing but the selected indices.
// prep v3: roots stored as r4 only (the root mask is recomputed), select-if on the r4 values, build (key, 16-byte value)
// for the selected parents, one radix sort of pairs carrying the parent record, then a sequential split (no gather).
struct SelPar3 {
    u64 pip;
    __host__ __device__ bool operator()(const u32 &r4) const { Parent p; u64 m = root_mask(r4); return make_parent(r4, m, pip, p); }
};
__global__ void k_build3(const u32 *r4c, const int *nsel, u64 pip, unsigned short *pkey, uint4 *pval) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= *nsel) return;
    u32 r4 = r4c[i]; Parent p; make_parent(r4, root_mask(r4), pip, p);
    pkey[i] = (unsigned short)(p.cls * 256 + (255 - key8(p.mask, c_rank)));
    pval[i] = make_uint4((u32)p.mask, (u32)(p.mask >> 32), p.cacc, r4);
}
__global__ void k_split3(const uint4 *sval, int n, u64 pip, u64 *sr, u64 *sm, u32 *scacc) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= n) return;
    uint4 v = sval[i]; sm[i] = (u64)v.x | ((u64)v.y << 32); scacc[i] = v.z; sr[i] = (u64)v.w + (pip << 24);
}
struct SelPar {
    const u32 *r4; const u64 *rm; u64 pip;
    __host__ __device__ bool operator()(const u32 &i) const { Parent p; return make_parent(r4[i], rm[i], pip, p); }
};
__global__ void k_build(const u32 *idxc, const int *nsel, const u32 *r4, const u64 *rmask, u64 pip, u64 *pr, u64 *pm, u32 *pcacc,
                        unsigned short *pkey) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= *nsel) return;
    u32 j = idxc[i]; Parent p; make_parent(r4[j], rmask[j], pip, p);
    pr[i] = p.r; pm[i] = p.mask; pcacc[i] = p.cacc; pkey[i] = (unsigned short)(p.cls * 256 + (255 - key8(p.mask, c_rank)));
}
#ifndef NT
#define NT 256
#endif
#ifndef MINB
#define MINB 1
#endif
#ifndef NOOUT
#define NOOUT 0   // 1: count survivors only (no append), for costing the append; sets are not checked
#endif
#ifndef TILE
#define TILE 1024
#endif
#ifndef AGG
#define AGG 1   // 1: warp-aggregated survivor append (one atomic per warp-iteration); 0: v1 (one atomic per survivor)
#endif
#define PEND (TILE + 64)
#define MAXCH (PEND / 64)
#define PMAX 1024
#define SLW 65  // padded slice stride (u64 words) against bank conflicts

// MODE 0: probes off (bottom side only), 1: skip off, 2: full
template <int MODE>
__global__ void __launch_bounds__(NT) k_main(const u64 *sm, const u32 *scacc, const int *pseg,
                                             const u64 *tmask, const int *tseg,
                                             u64 *cnt /* 64 units x 5 */, u32 *outbuf, u64 *outn, u64 outcap) {
    __shared__ u64 pend_m[PEND];
    __shared__ u32 pend_p[PEND];
    __shared__ u64 slices[MAXCH * SLW];
    __shared__ u64 commonm[MAXCH], validm[MAXCH];
    __shared__ u64 prob_m[PMAX];
    __shared__ u32 prob_i[PMAX];
    __shared__ int wcnt[NT / 32], woff[NT / 32];
    __shared__ int s_pend, s_nprobe, s_tot;
    const int c = blockIdx.x / 64;
    const u32 d = blockIdx.x % 64;
    const int t = threadIdx.x, lane = t & 31, w = t >> 5;
    const int cc = (c + (int)d) % M;
    // probes
    if (t == 0) {
        int n = 0;
        for (int i = 0; i < NROOT; i++) {
            int ct = (c_roots[i] - cc + M) % M;
            n += tseg[(d * M + ct) * 2 + 1] - tseg[(d * M + ct) * 2];
        }
        s_nprobe = n; s_pend = 0;
    }
    __syncthreads();
    {
        int base = 0;
        for (int i = 0; i < NROOT; i++) {
            int ct = (c_roots[i] - cc + M) % M;
            int b0 = tseg[(d * M + ct) * 2], b1 = tseg[(d * M + ct) * 2 + 1];
            for (int j = t; j < b1 - b0; j += NT) if (base + j < PMAX) { prob_m[base + j] = tmask[b0 + j]; prob_i[base + j] = b0 + j; }
            base += b1 - b0;
        }
    }
    __syncthreads();
    const int nprobe = min(s_nprobe, PMAX);
    u64 my_children = 0, my_chunks = 0, my_flat = 0, my_kept = 0, my_surv = 0;
    const int pb = pseg[c], pe = pseg[c + 1];
    for (int tb = pb; tb < pe; tb += TILE) {
        // phase 1: children of up to TILE parents, ordered compaction into pend
        for (int sub = 0; sub < TILE; sub += NT) {
            int idx = tb + sub + t;
            u64 m = 0;
            if (idx < pe) m = child_mask(sm[idx], scacc[idx], d);
            unsigned bal = __ballot_sync(0xffffffffu, m != 0);
            if (lane == 0) wcnt[w] = __popc(bal);
            __syncthreads();
            if (t == 0) { int s = 0; for (int i = 0; i < NT / 32; i++) { woff[i] = s; s += wcnt[i]; } s_tot = s; }
            __syncthreads();
            if (m) { int pos = s_pend + woff[w] + __popc(bal & ((1u << lane) - 1)); pend_m[pos] = m; pend_p[pos] = idx; }
            __syncthreads();
            if (t == 0) s_pend += s_tot;
            __syncthreads();
        }
        const bool last = (tb + TILE >= pe);
        const int npend = s_pend;
        const int nch = last ? (npend + 63) / 64 : npend / 64;
        if (t == 0) my_children += 0;  // counted below
        // phase 2: transpose chunks (warp per chunk) with ballots, common and valid masks
        for (int q = w; q < nch; q += NT / 32) {
            int i0 = q * 64 + lane, i1 = q * 64 + 32 + lane;
            bool v0 = i0 < npend, v1 = i1 < npend;
            u64 m0 = v0 ? pend_m[i0] : 0, m1 = v1 ? pend_m[i1] : 0;
            u64 my0 = 0, my1 = 0;
#pragma unroll 4
            for (int v = 0; v < 64; v++) {
                unsigned b0 = __ballot_sync(0xffffffffu, (m0 >> v) & 1);
                unsigned b1 = __ballot_sync(0xffffffffu, (m1 >> v) & 1);
                u64 s = (u64)b0 | ((u64)b1 << 32);
                if (v == lane) my0 = s;
                if (v == lane + 32) my1 = s;
            }
            slices[q * SLW + lane] = my0;
            slices[q * SLW + lane + 32] = my1;
            u64 cm = (v0 ? m0 : ~0ULL) & (v1 ? m1 : ~0ULL);
            for (int o = 16; o; o >>= 1) cm &= __shfl_xor_sync(0xffffffffu, cm, o);
            unsigned bv0 = __ballot_sync(0xffffffffu, v0), bv1 = __ballot_sync(0xffffffffu, v1);
            if (lane == 0) { commonm[q] = cm; validm[q] = (u64)bv0 | ((u64)bv1 << 32); }
        }
        __syncthreads();
        // phase 3: probes x chunks, lanes over chunks
        if (MODE != 0) {
            const int ninc = nprobe * nch;
#if AGG
            for (int i0 = 0; i0 < ninc; i0 += NT) {  // block-uniform trip count: shuffles below are converged
                const int i = i0 + t;
                u64 wd = 0; int p = 0, q = 0;
                if (i < ninc) {
                    p = i / nch; q = i - p * nch;
                    u64 tm = prob_m[p];
                    if (!(MODE == 2 && (commonm[q] & tm))) {
                        my_kept++;
                        u64 acc = 0, x = tm;
                        const u64 *sl = slices + q * SLW;
                        while (x) { acc |= sl[__ffsll((long long)x) - 1]; x &= x - 1; }
                        wd = ~acc & validm[q];
                    }
                }
                const int ns = __popcll(wd);
                int incl = ns;
                for (int o = 1; o < 32; o <<= 1) { int v = __shfl_up_sync(0xffffffffu, incl, o); if (lane >= o) incl += v; }
                const int tot = __shfl_sync(0xffffffffu, incl, 31);
                if (tot) {
                    u64 base = 0;
                    if (lane == 31) base = atomicAdd(outn, (u64)tot);
                    base = __shfl_sync(0xffffffffu, base, 31);
                    u64 slot = base + (u64)(incl - ns);
                    while (wd) {
                        int bi = __ffsll((long long)wd) - 1;
                        if (slot < outcap) { outbuf[2 * slot] = prob_i[p]; outbuf[2 * slot + 1] = pend_p[q * 64 + bi]; }
                        slot++; wd &= wd - 1;
                    }
                    my_surv += ns;
                }
            }
#else
            for (int i = t; i < ninc; i += NT) {
                int p = i / nch, q = i - p * nch;
                u64 tm = prob_m[p];
                if (MODE == 2 && (commonm[q] & tm)) continue;
                my_kept++;
                u64 acc = 0, x = tm;
                const u64 *sl = slices + q * SLW;
                while (x) { acc |= sl[__ffsll((long long)x) - 1]; x &= x - 1; }
                u64 wd = ~acc & validm[q];
                while (wd) {
                    int bi = __ffsll((long long)wd) - 1;
                    u64 slot = atomicAdd(outn, 1ULL);
                    if (slot < outcap) { outbuf[2 * slot] = prob_i[p]; outbuf[2 * slot + 1] = pend_p[q * 64 + bi]; }
                    my_surv++;
                    wd &= wd - 1;
                }
            }
#endif
            if (t == 0) my_flat += (u64)ninc;
        }
        if (t == 0) { my_chunks += nch; my_children += (u64)(last ? npend : nch * 64); }
        __syncthreads();
        // phase 4: move the partial chunk to the front
        if (!last) {
            int left = npend - nch * 64;
            if (t < left) { u64 m = pend_m[nch * 64 + t]; u32 pp = pend_p[nch * 64 + t]; pend_m[t] = m; pend_p[t] = pp; }
            __syncthreads();
            if (t == 0) s_pend = left;
        } else if (t == 0) s_pend = 0;
        __syncthreads();
    }
    if (my_children) atomicAdd(&cnt[d * 5 + 0], my_children);
    if (my_chunks) atomicAdd(&cnt[d * 5 + 1], my_chunks);
    if (my_flat) atomicAdd(&cnt[d * 5 + 2], my_flat);
    if (my_kept) atomicAdd(&cnt[d * 5 + 3], my_kept);
    if (my_surv) atomicAdd(&cnt[d * 5 + 4], my_surv);
}

// ---- v3: 16 chunks per round, slices stored v-major (slices3[v*16 + q]) so that a slice's LDS bank pair is q mod 16
// whatever the digit v; in phase 3 lane = chunk (q = lane & 15) and the block's 16 half-warps are 16 interleaved probe
// streams (p = s, s+16, ...). LOCKSTEP 0: each lane advances to its own next kept probe; 1: lanes step p together.
#ifndef LOCKSTEP
#define LOCKSTEP 0
#endif
#define FILL3 1024          // children per round = 16 full chunks
#define PEND3 (FILL3 + NT)  // pend never exceeds FILL3 - 1 + NT
template <int MODE>
__global__ void __launch_bounds__(NT) k_main3(const u64 *sm, const u32 *scacc, const int *pseg,
                                              const u64 *tmask, const int *tseg,
                                              u64 *cnt, u32 *outbuf, u64 *outn, u64 outcap) {
    __shared__ u64 pend_m[PEND3];
    __shared__ u32 pend_p[PEND3];
    __shared__ u64 slices3[64 * 16];
    __shared__ u64 commonm[16], validm[16];
    __shared__ u64 prob_m[PMAX];
    __shared__ u32 prob_i[PMAX];
    __shared__ int wcnt[NT / 32], woff[NT / 32];
    __shared__ int s_pend, s_nprobe, s_tot;
    const int c = blockIdx.x / 64;
    const u32 d = blockIdx.x % 64;
    const int t = threadIdx.x, lane = t & 31, w = t >> 5;
    const int cc = (c + (int)d) % M;
    if (t == 0) {
        int n = 0;
        for (int i = 0; i < NROOT; i++) {
            int ct = (c_roots[i] - cc + M) % M;
            n += tseg[(d * M + ct) * 2 + 1] - tseg[(d * M + ct) * 2];
        }
        s_nprobe = n; s_pend = 0;
    }
    __syncthreads();
    {
        int base = 0;
        for (int i = 0; i < NROOT; i++) {
            int ct = (c_roots[i] - cc + M) % M;
            int b0 = tseg[(d * M + ct) * 2], b1 = tseg[(d * M + ct) * 2 + 1];
            for (int j = t; j < b1 - b0; j += NT) if (base + j < PMAX) { prob_m[base + j] = tmask[b0 + j]; prob_i[base + j] = b0 + j; }
            base += b1 - b0;
        }
    }
    __syncthreads();
    const int nprobe = min(s_nprobe, PMAX);
    u64 my_children = 0, my_chunks = 0, my_flat = 0, my_kept = 0, my_surv = 0;
    const int pb = pseg[c], pe = pseg[c + 1];
    int cur = pb;
    while (true) {
        // phase 1: append children of NT parents at a time until 16 full chunks are pending or the class is done
        while (s_pend < FILL3 && cur < pe) {   // s_pend is block-uniform here (read after a barrier)
            int idx = cur + t;
            u64 m = 0;
            if (idx < pe) m = child_mask(sm[idx], scacc[idx], d);
            unsigned bal = __ballot_sync(0xffffffffu, m != 0);
            if (lane == 0) wcnt[w] = __popc(bal);
            __syncthreads();
            if (t == 0) { int s = 0; for (int i = 0; i < NT / 32; i++) { woff[i] = s; s += wcnt[i]; } s_tot = s; }
            __syncthreads();
            if (m) { int pos = s_pend + woff[w] + __popc(bal & ((1u << lane) - 1)); pend_m[pos] = m; pend_p[pos] = idx; }
            __syncthreads();
            if (t == 0) s_pend += s_tot;
            __syncthreads();
            cur += NT;
        }
        const bool done = cur >= pe;
        const int npend = s_pend;
        const int nch = done ? min(16, (npend + 63) / 64) : 16;
        if (nch == 0) break;
        const int ntake = min(npend, nch * 64);
        // phase 2: transpose (warp per chunk) with ballots into v-major slices
        for (int q = w; q < nch; q += NT / 32) {
            int i0 = q * 64 + lane, i1 = q * 64 + 32 + lane;
            bool v0 = i0 < ntake, v1 = i1 < ntake;
            u64 m0 = v0 ? pend_m[i0] : 0, m1 = v1 ? pend_m[i1] : 0;
            u64 my0 = 0, my1 = 0;
#pragma unroll 4
            for (int v = 0; v < 64; v++) {
                unsigned b0 = __ballot_sync(0xffffffffu, (m0 >> v) & 1);
                unsigned b1 = __ballot_sync(0xffffffffu, (m1 >> v) & 1);
                u64 sv = (u64)b0 | ((u64)b1 << 32);
                if (v == lane) my0 = sv;
                if (v == lane + 32) my1 = sv;
            }
            slices3[lane * 16 + q] = my0;
            slices3[(lane + 32) * 16 + q] = my1;
            u64 cm = (v0 ? m0 : ~0ULL) & (v1 ? m1 : ~0ULL);
            for (int o = 16; o; o >>= 1) cm &= __shfl_xor_sync(0xffffffffu, cm, o);
            unsigned bv0 = __ballot_sync(0xffffffffu, v0), bv1 = __ballot_sync(0xffffffffu, v1);
            if (lane == 0) { commonm[q] = cm; validm[q] = (u64)bv0 | ((u64)bv1 << 32); }
        }
        __syncthreads();
        // phase 3: lane = chunk, half-warp = probe stream
        if (MODE != 0) {
            const int q = lane & 15, st = w * 2 + (lane >> 4);
            const bool qa = q < nch;
            const u64 cmq = qa ? commonm[q] : ~0ULL, vmq = qa ? validm[q] : 0;
            int p = st;
            while (__any_sync(0xffffffffu, qa && p < nprobe)) {
                u64 wd = 0; int pk = 0;
#if LOCKSTEP
                if (qa && p < nprobe) {
                    u64 tm = prob_m[p];
                    if (!(MODE == 2 && (cmq & tm))) {
#else
                if (qa) {
                    u64 tm = 0;
                    while (p < nprobe) { tm = prob_m[p]; if (MODE == 2 && (cmq & tm)) { p += 16; continue; } break; }
                    if (p < nprobe) {
#endif
                        my_kept++;
                        u64 acc = 0, x = tm;
                        while (x) { acc |= slices3[(__ffsll((long long)x) - 1) * 16 + q]; x &= x - 1; }
                        wd = ~acc & vmq; pk = p;
                    }
                }
                p += 16;
                const int ns = __popcll(wd);
                int incl = ns;
                for (int o = 1; o < 32; o <<= 1) { int v = __shfl_up_sync(0xffffffffu, incl, o); if (lane >= o) incl += v; }
                const int tot = __shfl_sync(0xffffffffu, incl, 31);
                if (tot) {
                    u64 base = 0;
                    if (lane == 31) base = atomicAdd(outn, (u64)tot);
                    base = __shfl_sync(0xffffffffu, base, 31);
                    u64 slot = base + (u64)(incl - ns);
                    while (wd) {
                        int bi = __ffsll((long long)wd) - 1;
                        if (slot < outcap) { outbuf[2 * slot] = prob_i[pk]; outbuf[2 * slot + 1] = pend_p[q * 64 + bi]; }
                        slot++; wd &= wd - 1;
                    }
                    my_surv += ns;
                }
            }
            if (t == 0) my_flat += (u64)nprobe * nch;
        }
        if (t == 0) { my_chunks += nch; my_children += (u64)ntake; }
        __syncthreads();
        // phase 4: carry the rest (< NT + 64 - 1 ... at most PEND3 - FILL3) to the front; ranges are disjoint
        const int left = npend - ntake;
        if (t < left) { u64 m = pend_m[ntake + t]; u32 pp = pend_p[ntake + t]; pend_m[t] = m; pend_p[t] = pp; }
        __syncthreads();
        if (t == 0) s_pend = left;
        __syncthreads();
        if (done && left == 0) break;
    }
    if (my_children) atomicAdd(&cnt[d * 5 + 0], my_children);
    if (my_chunks) atomicAdd(&cnt[d * 5 + 1], my_chunks);
    if (my_flat) atomicAdd(&cnt[d * 5 + 2], my_flat);
    if (my_kept) atomicAdd(&cnt[d * 5 + 3], my_kept);
    if (my_surv) atomicAdd(&cnt[d * 5 + 4], my_surv);
}
// ---- v4: v3 plus each probe's digits precomputed as bytes (padded to MAXPOP with the zero slice 64), so the OR over the
// probe's digits is a fully unrolled run of independent LDS loads instead of a ffs-dependent loop.
#define PMAX4 640   // max probes per (class, unit) in this super-unit: 561
#ifndef MAXPOP
#define MAXPOP 17   // max top-mask popcount at b64 f0 4 (checked on the host)
#endif
template <int MODE>
__global__ void __launch_bounds__(NT, MINB) k_main4(const u64 *sm, const u32 *scacc, const int *pseg,
                                              const u64 *tmask, const int *tseg,
                                              u64 *cnt, u32 *outbuf, u64 *outn, u64 outcap) {
    __shared__ u64 pend_m[PEND3];
    __shared__ u32 pend_p[PEND3];
    __shared__ u64 slices3[65 * 16];  // row 64 = zero slice (padding digit)
    __shared__ u32 prob_d[PMAX4 * 5];  // probe digits, 4 per word, padded with 64
    __shared__ u64 commonm[16], validm[16];
    __shared__ u64 prob_m[PMAX4];
    __shared__ u32 prob_i[PMAX4];
    __shared__ int wcnt[NT / 32], woff[NT / 32];
    __shared__ int s_pend, s_nprobe, s_tot;
    const int c = blockIdx.x / 64;
    const u32 d = blockIdx.x % 64;
    const int t = threadIdx.x, lane = t & 31, w = t >> 5;
    const int cc = (c + (int)d) % M;
    if (t == 0) {
        int n = 0;
        for (int i = 0; i < NROOT; i++) {
            int ct = (c_roots[i] - cc + M) % M;
            n += tseg[(d * M + ct) * 2 + 1] - tseg[(d * M + ct) * 2];
        }
        s_nprobe = n; s_pend = 0;
    }
    if (t < 16) slices3[64 * 16 + t] = 0;
    __syncthreads();
    {
        int base = 0;
        for (int i = 0; i < NROOT; i++) {
            int ct = (c_roots[i] - cc + M) % M;
            int b0 = tseg[(d * M + ct) * 2], b1 = tseg[(d * M + ct) * 2 + 1];
            for (int j = t; j < b1 - b0; j += NT) if (base + j < PMAX4) {
                u64 x = tmask[b0 + j]; prob_m[base + j] = x; prob_i[base + j] = b0 + j;
                u32 dw[5] = {0x40404040u, 0x40404040u, 0x40404040u, 0x40404040u, 0x40404040u};
                for (int k = 0; x && k < 20; k++) { u32 v = __ffsll((long long)x) - 1; dw[k >> 2] = (dw[k >> 2] & ~(0xffu << (8 * (k & 3)))) | (v << (8 * (k & 3))); x &= x - 1; }
                for (int k = 0; k < 5; k++) prob_d[(base + j) * 5 + k] = dw[k];
            }
            base += b1 - b0;
        }
    }
    __syncthreads();
    const int nprobe = min(s_nprobe, PMAX4);
    u64 my_children = 0, my_chunks = 0, my_flat = 0, my_kept = 0, my_surv = 0;
    const int pb = pseg[c], pe = pseg[c + 1];
    int cur = pb;
    while (true) {
        // phase 1: append children of NT parents at a time until 16 full chunks are pending or the class is done
        while (s_pend < FILL3 && cur < pe) {   // s_pend is block-uniform here (read after a barrier)
            int idx = cur + t;
            u64 m = 0;
            if (idx < pe) m = child_mask(sm[idx], scacc[idx], d);
            unsigned bal = __ballot_sync(0xffffffffu, m != 0);
            if (lane == 0) wcnt[w] = __popc(bal);
            __syncthreads();
            if (t == 0) { int s = 0; for (int i = 0; i < NT / 32; i++) { woff[i] = s; s += wcnt[i]; } s_tot = s; }
            __syncthreads();
            if (m) { int pos = s_pend + woff[w] + __popc(bal & ((1u << lane) - 1)); pend_m[pos] = m; pend_p[pos] = idx; }
            __syncthreads();
            if (t == 0) s_pend += s_tot;
            __syncthreads();
            cur += NT;
        }
        const bool done = cur >= pe;
        const int npend = s_pend;
        const int nch = done ? min(16, (npend + 63) / 64) : 16;
        if (nch == 0) break;
        const int ntake = min(npend, nch * 64);
        // phase 2: transpose (warp per chunk) with ballots into v-major slices
        for (int q = w; q < nch; q += NT / 32) {
            int i0 = q * 64 + lane, i1 = q * 64 + 32 + lane;
            bool v0 = i0 < ntake, v1 = i1 < ntake;
            u64 m0 = v0 ? pend_m[i0] : 0, m1 = v1 ? pend_m[i1] : 0;
            u64 my0 = 0, my1 = 0;
#pragma unroll 4
            for (int v = 0; v < 64; v++) {
                unsigned b0 = __ballot_sync(0xffffffffu, (m0 >> v) & 1);
                unsigned b1 = __ballot_sync(0xffffffffu, (m1 >> v) & 1);
                u64 sv = (u64)b0 | ((u64)b1 << 32);
                if (v == lane) my0 = sv;
                if (v == lane + 32) my1 = sv;
            }
            slices3[lane * 16 + q] = my0;
            slices3[(lane + 32) * 16 + q] = my1;
            u64 cm = (v0 ? m0 : ~0ULL) & (v1 ? m1 : ~0ULL);
            for (int o = 16; o; o >>= 1) cm &= __shfl_xor_sync(0xffffffffu, cm, o);
            unsigned bv0 = __ballot_sync(0xffffffffu, v0), bv1 = __ballot_sync(0xffffffffu, v1);
            if (lane == 0) { commonm[q] = cm; validm[q] = (u64)bv0 | ((u64)bv1 << 32); }
        }
        __syncthreads();
        // phase 3: lane = chunk, half-warp = probe stream
        if (MODE != 0) {
            const int q = lane & 15, st = w * 2 + (lane >> 4);  // NT/16 probe streams
            const bool qa = q < nch;
            const u64 cmq = qa ? commonm[q] : ~0ULL, vmq = qa ? validm[q] : 0;
            int p = st;
            while (__any_sync(0xffffffffu, qa && p < nprobe)) {
                u64 wd = 0; int pk = 0;
#if LOCKSTEP
                if (qa && p < nprobe) {
                    u64 tm = prob_m[p];
                    if (!(MODE == 2 && (cmq & tm))) {
#else
                if (qa) {
                    u64 tm = 0;
                    while (p < nprobe) { tm = prob_m[p]; if (MODE == 2 && (cmq & tm)) { p += NT / 16; continue; } break; }
                    if (p < nprobe) {
#endif
                        my_kept++;
                        const u32 *dp = prob_d + p * 5;
                        u64 acc = 0;
#pragma unroll
                        for (int k5 = 0; k5 < 5; k5++) {
                            const u32 dw = dp[k5];
#pragma unroll
                            for (int k = 0; k < 4; k++) if (k5 * 4 + k < MAXPOP) acc |= slices3[((dw >> (8 * k)) & 0xffu) * 16 + q];
                        }
                        wd = ~acc & vmq; pk = p;
                    }
                }
                p += NT / 16;
                const int ns = __popcll(wd);
#if NOOUT
                my_surv += ns;
                continue;
#endif
                int incl = ns;
                for (int o = 1; o < 32; o <<= 1) { int v = __shfl_up_sync(0xffffffffu, incl, o); if (lane >= o) incl += v; }
                const int tot = __shfl_sync(0xffffffffu, incl, 31);
                if (tot) {
                    u64 base = 0;
                    if (lane == 31) base = atomicAdd(outn, (u64)tot);
                    base = __shfl_sync(0xffffffffu, base, 31);
                    u64 slot = base + (u64)(incl - ns);
                    while (wd) {
                        int bi = __ffsll((long long)wd) - 1;
                        if (slot < outcap) { outbuf[2 * slot] = prob_i[pk]; outbuf[2 * slot + 1] = pend_p[q * 64 + bi]; }
                        slot++; wd &= wd - 1;
                    }
                    my_surv += ns;
                }
            }
            if (t == 0) my_flat += (u64)nprobe * nch;
        }
        if (t == 0) { my_chunks += nch; my_children += (u64)ntake; }
        __syncthreads();
        // phase 4: carry the rest (< NT + 64 - 1 ... at most PEND3 - FILL3) to the front; ranges are disjoint
        const int left = npend - ntake;
        if (t < left) { u64 m = pend_m[ntake + t]; u32 pp = pend_p[ntake + t]; pend_m[t] = m; pend_p[t] = pp; }
        __syncthreads();
        if (t == 0) s_pend = left;
        __syncthreads();
        if (done && left == 0) break;
    }
    if (my_children) atomicAdd(&cnt[d * 5 + 0], my_children);
    if (my_chunks) atomicAdd(&cnt[d * 5 + 1], my_chunks);
    if (my_flat) atomicAdd(&cnt[d * 5 + 2], my_flat);
    if (my_kept) atomicAdd(&cnt[d * 5 + 3], my_kept);
    if (my_surv) atomicAdd(&cnt[d * 5 + 4], my_surv);
}
// ---- v5: v4 plus a per-round probe list (probes with any chunk kept, with their 16-bit chunk mask) so whole skipped
// probes cost no lane time; survivors are emitted as one 16-byte record per nonzero word (top, first parent of the chunk,
// word); the host expands a record by re-deriving the chunk's 64 members (as a survivor check would).
template <int MODE>
__global__ void __launch_bounds__(NT, MINB) k_main5(const u64 *sm, const u32 *scacc, const int *pseg,
                                              const u64 *tmask, const int *tseg,
                                              u64 *cnt, u32 *outbuf, u64 *outn, u64 outcap) {
    __shared__ u64 pend_m[PEND3];
    __shared__ u32 pend_p[PEND3];
    __shared__ u64 slices3[65 * 16];  // row 64 = zero slice (padding digit)
    __shared__ u32 prob_d[PMAX4 * 5];  // probe digits, 4 per word, padded with 64
    __shared__ u64 commonm[16], validm[16];
    __shared__ u64 prob_m[PMAX4];
    __shared__ u32 prob_i[PMAX4];
    __shared__ int wcnt[NT / 32], woff[NT / 32];
    __shared__ int s_pend, s_nprobe, s_tot, s_nlist;
    __shared__ u32 plist[PMAX4];
    const int c = blockIdx.x / 64;
    const u32 d = blockIdx.x % 64;
    const int t = threadIdx.x, lane = t & 31, w = t >> 5;
    const int cc = (c + (int)d) % M;
    if (t == 0) {
        int n = 0;
        for (int i = 0; i < NROOT; i++) {
            int ct = (c_roots[i] - cc + M) % M;
            n += tseg[(d * M + ct) * 2 + 1] - tseg[(d * M + ct) * 2];
        }
        s_nprobe = n; s_pend = 0; s_nlist = 0;
    }
    if (t < 16) slices3[64 * 16 + t] = 0;
    __syncthreads();
    {
        int base = 0;
        for (int i = 0; i < NROOT; i++) {
            int ct = (c_roots[i] - cc + M) % M;
            int b0 = tseg[(d * M + ct) * 2], b1 = tseg[(d * M + ct) * 2 + 1];
            for (int j = t; j < b1 - b0; j += NT) if (base + j < PMAX4) {
                u64 x = tmask[b0 + j]; prob_m[base + j] = x; prob_i[base + j] = b0 + j;
                u32 dw[5] = {0x40404040u, 0x40404040u, 0x40404040u, 0x40404040u, 0x40404040u};
                for (int k = 0; x && k < 20; k++) { u32 v = __ffsll((long long)x) - 1; dw[k >> 2] = (dw[k >> 2] & ~(0xffu << (8 * (k & 3)))) | (v << (8 * (k & 3))); x &= x - 1; }
                for (int k = 0; k < 5; k++) prob_d[(base + j) * 5 + k] = dw[k];
            }
            base += b1 - b0;
        }
    }
    __syncthreads();
    const int nprobe = min(s_nprobe, PMAX4);
    u64 my_children = 0, my_chunks = 0, my_flat = 0, my_kept = 0, my_surv = 0, my_lslots = 0;
    const int pb = pseg[c], pe = pseg[c + 1];
    int cur = pb;
    while (true) {
        // phase 1: append children of NT parents at a time until 16 full chunks are pending or the class is done
        while (s_pend < FILL3 && cur < pe) {   // s_pend is block-uniform here (read after a barrier)
            int idx = cur + t;
            u64 m = 0;
            if (idx < pe) m = child_mask(sm[idx], scacc[idx], d);
            unsigned bal = __ballot_sync(0xffffffffu, m != 0);
            if (lane == 0) wcnt[w] = __popc(bal);
            __syncthreads();
            if (t == 0) { int s = 0; for (int i = 0; i < NT / 32; i++) { woff[i] = s; s += wcnt[i]; } s_tot = s; }
            __syncthreads();
            if (m) { int pos = s_pend + woff[w] + __popc(bal & ((1u << lane) - 1)); pend_m[pos] = m; pend_p[pos] = idx; }
            __syncthreads();
            if (t == 0) s_pend += s_tot;
            __syncthreads();
            cur += NT;
        }
        const bool done = cur >= pe;
        const int npend = s_pend;
        const int nch = done ? min(16, (npend + 63) / 64) : 16;
        if (nch == 0) break;
        const int ntake = min(npend, nch * 64);
        // phase 2: transpose (warp per chunk) with ballots into v-major slices
        for (int q = w; q < nch; q += NT / 32) {
            int i0 = q * 64 + lane, i1 = q * 64 + 32 + lane;
            bool v0 = i0 < ntake, v1 = i1 < ntake;
            u64 m0 = v0 ? pend_m[i0] : 0, m1 = v1 ? pend_m[i1] : 0;
            u64 my0 = 0, my1 = 0;
#pragma unroll 4
            for (int v = 0; v < 64; v++) {
                unsigned b0 = __ballot_sync(0xffffffffu, (m0 >> v) & 1);
                unsigned b1 = __ballot_sync(0xffffffffu, (m1 >> v) & 1);
                u64 sv = (u64)b0 | ((u64)b1 << 32);
                if (v == lane) my0 = sv;
                if (v == lane + 32) my1 = sv;
            }
            slices3[lane * 16 + q] = my0;
            slices3[(lane + 32) * 16 + q] = my1;
            u64 cm = (v0 ? m0 : ~0ULL) & (v1 ? m1 : ~0ULL);
            for (int o = 16; o; o >>= 1) cm &= __shfl_xor_sync(0xffffffffu, cm, o);
            unsigned bv0 = __ballot_sync(0xffffffffu, v0), bv1 = __ballot_sync(0xffffffffu, v1);
            if (lane == 0) { commonm[q] = cm; validm[q] = (u64)bv0 | ((u64)bv1 << 32); }
        }
        __syncthreads();
        // phase 3a: per probe, the 16-bit mask of chunks that survive the common-mask skip; probes with any kept chunk
        // go to a list (unordered: the output is a set). 3b: half-warps take list entries, lane = chunk.
        if (MODE != 0) {
            for (int pp = t; pp < nprobe; pp += NT) {
                const u64 tm = prob_m[pp];
                u32 km = 0;
                for (int qq = 0; qq < nch; qq++) if (!(MODE == 2 && (commonm[qq] & tm))) km |= 1u << qq;
                if (km) { int sl = atomicAdd(&s_nlist, 1); plist[sl] = (u32)pp | (km << 16); }
            }
            __syncthreads();
            const int nlist = s_nlist;
            const int q = lane & 15;
            u64 vmq = q < nch ? validm[q] : 0;
            for (int e0 = 0; e0 < nlist; e0 += NT / 16) {   // block-uniform
                const int e = e0 + w * 2 + (lane >> 4);
                u64 wd = 0; u32 pk = 0;
                if (e < nlist) {
                    const u32 ent = plist[e];
                    pk = ent & 0xffffu;
                    if ((ent >> (16 + q)) & 1u) {
                        my_kept++;
                        const u32 *dp = prob_d + pk * 5;
                        u64 acc = 0;
#pragma unroll
                        for (int k5 = 0; k5 < 5; k5++) {
                            const u32 dw = dp[k5];
#pragma unroll
                            for (int k = 0; k < 4; k++) if (k5 * 4 + k < MAXPOP) acc |= slices3[((dw >> (8 * k)) & 0xffu) * 16 + q];
                        }
                        wd = ~acc & vmq;
                    }
                }
                if (t == 0) my_lslots += (u64)min(NT / 16, nlist - e0) * nch;
#if NOOUT
                my_surv += __popcll(wd);
#else
                const unsigned nzb = __ballot_sync(0xffffffffu, wd != 0);
                if (nzb) {
                    u64 base = 0;
                    if (lane == 0) base = atomicAdd(outn, (u64)__popc(nzb));
                    base = __shfl_sync(0xffffffffu, base, 0);
                    if (wd) {
                        u64 slot = base + __popc(nzb & ((1u << lane) - 1));
                        if (slot < outcap) {
                            uint4 r; r.x = prob_i[pk]; r.y = pend_p[q * 64]; r.z = (u32)wd; r.w = (u32)(wd >> 32);
                            reinterpret_cast<uint4 *>(outbuf)[slot] = r;
                        }
                        my_surv += __popcll(wd);
                    }
                }
#endif
            }
            if (t == 0) my_flat += (u64)nprobe * nch;
        }
        if (t == 0) { my_chunks += nch; my_children += (u64)ntake; }
        __syncthreads();
        // phase 4: carry the rest (< NT + 64 - 1 ... at most PEND3 - FILL3) to the front; ranges are disjoint
        const int left = npend - ntake;
        if (t < left) { u64 m = pend_m[ntake + t]; u32 pp = pend_p[ntake + t]; pend_m[t] = m; pend_p[t] = pp; }
        __syncthreads();
        if (t == 0) { s_pend = left; s_nlist = 0; }
        __syncthreads();
        if (done && left == 0) break;
    }
    if (my_children) atomicAdd(&cnt[d * 5 + 0], my_children);
    if (my_chunks) atomicAdd(&cnt[d * 5 + 1], my_chunks);
    if (my_flat) atomicAdd(&cnt[d * 5 + 2], my_flat);
    if (my_kept) atomicAdd(&cnt[d * 5 + 3], my_kept);
    if (my_surv) atomicAdd(&cnt[d * 5 + 4], my_surv);
    if (my_lslots) atomicAdd(&cnt[64 * 5], my_lslots);
}
// ---- v6: v5 with a one-barrier phase 1 and a shuffle (not ballot) transpose
template <int MODE>
__global__ void __launch_bounds__(NT, MINB) k_main6(const u64 *sm, const u32 *scacc, const int *pseg,
                                              const u64 *tmask, const int *tseg,
                                              u64 *cnt, u32 *outbuf, u64 *outn, u64 outcap) {
    __shared__ u64 pend_m[PEND3];
    __shared__ u32 pend_p[PEND3];
    __shared__ u64 slices3[65 * 16];  // row 64 = zero slice (padding digit)
    __shared__ u32 prob_d[PMAX4 * 5];  // probe digits, 4 per word, padded with 64
    __shared__ u64 commonm[16], validm[16];
    __shared__ u64 prob_m[PMAX4];
    __shared__ u32 prob_i[PMAX4];
    __shared__ int wcnt2[2][NT / 32];
    __shared__ int s_pend, s_nprobe, s_tot, s_nlist;
    __shared__ u32 plist[PMAX4];
    const int c = blockIdx.x / 64;
    const u32 d = blockIdx.x % 64;
    const int t = threadIdx.x, lane = t & 31, w = t >> 5;
    const int cc = (c + (int)d) % M;
    if (t == 0) {
        int n = 0;
        for (int i = 0; i < NROOT; i++) {
            int ct = (c_roots[i] - cc + M) % M;
            n += tseg[(d * M + ct) * 2 + 1] - tseg[(d * M + ct) * 2];
        }
        s_nprobe = n; s_pend = 0; s_nlist = 0;
    }
    if (t < 16) slices3[64 * 16 + t] = 0;
    __syncthreads();
    {
        int base = 0;
        for (int i = 0; i < NROOT; i++) {
            int ct = (c_roots[i] - cc + M) % M;
            int b0 = tseg[(d * M + ct) * 2], b1 = tseg[(d * M + ct) * 2 + 1];
            for (int j = t; j < b1 - b0; j += NT) if (base + j < PMAX4) {
                u64 x = tmask[b0 + j]; prob_m[base + j] = x; prob_i[base + j] = b0 + j;
                u32 dw[5] = {0x40404040u, 0x40404040u, 0x40404040u, 0x40404040u, 0x40404040u};
                for (int k = 0; x && k < 20; k++) { u32 v = __ffsll((long long)x) - 1; dw[k >> 2] = (dw[k >> 2] & ~(0xffu << (8 * (k & 3)))) | (v << (8 * (k & 3))); x &= x - 1; }
                for (int k = 0; k < 5; k++) prob_d[(base + j) * 5 + k] = dw[k];
            }
            base += b1 - b0;
        }
    }
    __syncthreads();
    const int nprobe = min(s_nprobe, PMAX4);
    u64 my_children = 0, my_chunks = 0, my_flat = 0, my_kept = 0, my_surv = 0, my_lslots = 0;
    const int pb = pseg[c], pe = pseg[c + 1];
    int cur = pb, npend_r = 0, par = 0;
    while (true) {
        // phase 1 (v6): one barrier per NT parents; warp counts double-buffered, pend count kept block-uniform in a register
        while (npend_r < FILL3 && cur < pe) {
            int idx = cur + t;
            u64 m = 0;
            if (idx < pe) m = child_mask(sm[idx], scacc[idx], d);
            unsigned bal = __ballot_sync(0xffffffffu, m != 0);
            if (lane == 0) wcnt2[par][w] = __popc(bal);
            __syncthreads();
            int off = 0, tot = 0;
#pragma unroll
            for (int i = 0; i < NT / 32; i++) { int x = wcnt2[par][i]; off += (i < w) ? x : 0; tot += x; }
            if (m) { int pos = npend_r + off + __popc(bal & ((1u << lane) - 1)); pend_m[pos] = m; pend_p[pos] = idx; }
            npend_r += tot; par ^= 1;
            cur += NT;
        }
        __syncthreads();
        const bool done = cur >= pe;
        const int npend = npend_r;
        const int nch = done ? min(16, (npend + 63) / 64) : 16;
        if (nch == 0) break;
        const int ntake = min(npend, nch * 64);
        // phase 2 (v6): 64x64 bit transpose per chunk by a local 32-block swap and 5 shfl_xor stages on four 32x32 blocks
        for (int q = w; q < nch; q += NT / 32) {
            int i0 = q * 64 + lane, i1 = q * 64 + 32 + lane;
            bool v0 = i0 < ntake, v1 = i1 < ntake;
            u64 m0 = v0 ? pend_m[i0] : 0, m1 = v1 ? pend_m[i1] : 0;
            u32 A = (u32)m0, Bk = (u32)(m0 >> 32), C = (u32)m1, D = (u32)(m1 >> 32);
#pragma unroll
            for (int j = 16; j; j >>= 1) {
                const u32 hi = (j == 16) ? 0xFFFF0000u : (j == 8) ? 0xFF00FF00u : (j == 4) ? 0xF0F0F0F0u : (j == 2) ? 0xCCCCCCCCu : 0xAAAAAAAAu;
                const u32 yA = __shfl_xor_sync(0xffffffffu, A, j), yB = __shfl_xor_sync(0xffffffffu, Bk, j);
                const u32 yC = __shfl_xor_sync(0xffffffffu, C, j), yD = __shfl_xor_sync(0xffffffffu, D, j);
                if (lane & j) { A = (A & hi) | ((yA >> j) & ~hi); Bk = (Bk & hi) | ((yB >> j) & ~hi); C = (C & hi) | ((yC >> j) & ~hi); D = (D & hi) | ((yD >> j) & ~hi); }
                else { A = (A & ~hi) | ((yA << j) & hi); Bk = (Bk & ~hi) | ((yB << j) & hi); C = (C & ~hi) | ((yC << j) & hi); D = (D & ~hi) | ((yD << j) & hi); }
            }
            slices3[lane * 16 + q] = (u64)A | ((u64)C << 32);
            slices3[(lane + 32) * 16 + q] = (u64)Bk | ((u64)D << 32);
            u64 cm = (v0 ? m0 : ~0ULL) & (v1 ? m1 : ~0ULL);
            for (int o = 16; o; o >>= 1) cm &= __shfl_xor_sync(0xffffffffu, cm, o);
            unsigned bv0 = __ballot_sync(0xffffffffu, v0), bv1 = __ballot_sync(0xffffffffu, v1);
            if (lane == 0) { commonm[q] = cm; validm[q] = (u64)bv0 | ((u64)bv1 << 32); }
        }
        __syncthreads();
        // phase 3a: per probe, the 16-bit mask of chunks that survive the common-mask skip; probes with any kept chunk
        // go to a list (unordered: the output is a set). 3b: half-warps take list entries, lane = chunk.
        if (MODE != 0) {
            for (int pp = t; pp < nprobe; pp += NT) {
                const u64 tm = prob_m[pp];
                u32 km = 0;
                for (int qq = 0; qq < nch; qq++) if (!(MODE == 2 && (commonm[qq] & tm))) km |= 1u << qq;
                if (km) { int sl = atomicAdd(&s_nlist, 1); plist[sl] = (u32)pp | (km << 16); }
            }
            __syncthreads();
            const int nlist = s_nlist;
            const int q = lane & 15;
            u64 vmq = q < nch ? validm[q] : 0;
            for (int e0 = 0; e0 < nlist; e0 += NT / 16) {   // block-uniform
                const int e = e0 + w * 2 + (lane >> 4);
                u64 wd = 0; u32 pk = 0;
                if (e < nlist) {
                    const u32 ent = plist[e];
                    pk = ent & 0xffffu;
                    if ((ent >> (16 + q)) & 1u) {
                        my_kept++;
                        const u32 *dp = prob_d + pk * 5;
                        u64 acc = 0;
#pragma unroll
                        for (int k5 = 0; k5 < 5; k5++) {
                            const u32 dw = dp[k5];
#pragma unroll
                            for (int k = 0; k < 4; k++) if (k5 * 4 + k < MAXPOP) acc |= slices3[((dw >> (8 * k)) & 0xffu) * 16 + q];
                        }
                        wd = ~acc & vmq;
                    }
                }
                if (t == 0) my_lslots += (u64)min(NT / 16, nlist - e0) * nch;
#if NOOUT
                my_surv += __popcll(wd);
#else
                const unsigned nzb = __ballot_sync(0xffffffffu, wd != 0);
                if (nzb) {
                    u64 base = 0;
                    if (lane == 0) base = atomicAdd(outn, (u64)__popc(nzb));
                    base = __shfl_sync(0xffffffffu, base, 0);
                    if (wd) {
                        u64 slot = base + __popc(nzb & ((1u << lane) - 1));
                        if (slot < outcap) {
                            uint4 r; r.x = prob_i[pk]; r.y = pend_p[q * 64]; r.z = (u32)wd; r.w = (u32)(wd >> 32);
                            reinterpret_cast<uint4 *>(outbuf)[slot] = r;
                        }
                        my_surv += __popcll(wd);
                    }
                }
#endif
            }
            if (t == 0) my_flat += (u64)nprobe * nch;
        }
        if (t == 0) { my_chunks += nch; my_children += (u64)ntake; }
        __syncthreads();
        // phase 4: carry the rest (< NT + 64 - 1 ... at most PEND3 - FILL3) to the front; ranges are disjoint
        const int left = npend - ntake;
        if (t < left) { u64 m = pend_m[ntake + t]; u32 pp = pend_p[ntake + t]; pend_m[t] = m; pend_p[t] = pp; }
        __syncthreads();
        npend_r = left;
        if (t == 0) s_nlist = 0;
        __syncthreads();
        if (done && left == 0) break;
    }
    if (my_children) atomicAdd(&cnt[d * 5 + 0], my_children);
    if (my_chunks) atomicAdd(&cnt[d * 5 + 1], my_chunks);
    if (my_flat) atomicAdd(&cnt[d * 5 + 2], my_flat);
    if (my_kept) atomicAdd(&cnt[d * 5 + 3], my_kept);
    if (my_surv) atomicAdd(&cnt[d * 5 + 4], my_surv);
    if (my_lslots) atomicAdd(&cnt[64 * 5], my_lslots);
}
// ---- v7: v6 with survivor records appended to warp-private slabs (one global atomic per SLAB records instead of a
// dependent atomic round trip on every warp step that has a nonzero word)
#define SLAB 256
__device__ u32 *g_slabcnt;
template <int MODE>
__global__ void __launch_bounds__(NT, MINB) k_main7(const u64 *sm, const u32 *scacc, const int *pseg,
                                              const u64 *tmask, const int *tseg,
                                              u64 *cnt, u32 *outbuf, u64 *outn, u64 outcap) {
    __shared__ u64 pend_m[PEND3];
    __shared__ u32 pend_p[PEND3];
    __shared__ u64 slices3[65 * 16];  // row 64 = zero slice (padding digit)
    __shared__ u32 prob_d[PMAX4 * 5];  // probe digits, 4 per word, padded with 64
    __shared__ u64 commonm[16], validm[16];
    __shared__ u64 prob_m[PMAX4];
    __shared__ u32 prob_i[PMAX4];
    __shared__ int wcnt2[2][NT / 32];
    __shared__ int s_pend, s_nprobe, s_tot, s_nlist;
    __shared__ u32 plist[PMAX4];
    const int c = blockIdx.x / 64;
    const u32 d = blockIdx.x % 64;
    const int t = threadIdx.x, lane = t & 31, w = t >> 5;
    const int cc = (c + (int)d) % M;
    if (t == 0) {
        int n = 0;
        for (int i = 0; i < NROOT; i++) {
            int ct = (c_roots[i] - cc + M) % M;
            n += tseg[(d * M + ct) * 2 + 1] - tseg[(d * M + ct) * 2];
        }
        s_nprobe = n; s_pend = 0; s_nlist = 0;
    }
    if (t < 16) slices3[64 * 16 + t] = 0;
    __syncthreads();
    {
        int base = 0;
        for (int i = 0; i < NROOT; i++) {
            int ct = (c_roots[i] - cc + M) % M;
            int b0 = tseg[(d * M + ct) * 2], b1 = tseg[(d * M + ct) * 2 + 1];
            for (int j = t; j < b1 - b0; j += NT) if (base + j < PMAX4) {
                u64 x = tmask[b0 + j]; prob_m[base + j] = x; prob_i[base + j] = b0 + j;
                u32 dw[5] = {0x40404040u, 0x40404040u, 0x40404040u, 0x40404040u, 0x40404040u};
                for (int k = 0; x && k < 20; k++) { u32 v = __ffsll((long long)x) - 1; dw[k >> 2] = (dw[k >> 2] & ~(0xffu << (8 * (k & 3)))) | (v << (8 * (k & 3))); x &= x - 1; }
                for (int k = 0; k < 5; k++) prob_d[(base + j) * 5 + k] = dw[k];
            }
            base += b1 - b0;
        }
    }
    __syncthreads();
    const int nprobe = min(s_nprobe, PMAX4);
    u64 my_children = 0, my_chunks = 0, my_flat = 0, my_kept = 0, my_surv = 0, my_lslots = 0;
    long long slab_id = -1; int slab_used = SLAB;  // full: the first record allocates
    const int pb = pseg[c], pe = pseg[c + 1];
    int cur = pb, npend_r = 0, par = 0;
    while (true) {
        // phase 1 (v6): one barrier per NT parents; warp counts double-buffered, pend count kept block-uniform in a register
        while (npend_r < FILL3 && cur < pe) {
            int idx = cur + t;
            u64 m = 0;
            if (idx < pe) m = child_mask(sm[idx], scacc[idx], d);
            unsigned bal = __ballot_sync(0xffffffffu, m != 0);
            if (lane == 0) wcnt2[par][w] = __popc(bal);
            __syncthreads();
            int off = 0, tot = 0;
#pragma unroll
            for (int i = 0; i < NT / 32; i++) { int x = wcnt2[par][i]; off += (i < w) ? x : 0; tot += x; }
            if (m) { int pos = npend_r + off + __popc(bal & ((1u << lane) - 1)); pend_m[pos] = m; pend_p[pos] = idx; }
            npend_r += tot; par ^= 1;
            cur += NT;
        }
        __syncthreads();
        const bool done = cur >= pe;
        const int npend = npend_r;
        const int nch = done ? min(16, (npend + 63) / 64) : 16;
        if (nch == 0) break;
        const int ntake = min(npend, nch * 64);
        // phase 2 (v6): 64x64 bit transpose per chunk by a local 32-block swap and 5 shfl_xor stages on four 32x32 blocks
        for (int q = w; q < nch; q += NT / 32) {
            int i0 = q * 64 + lane, i1 = q * 64 + 32 + lane;
            bool v0 = i0 < ntake, v1 = i1 < ntake;
            u64 m0 = v0 ? pend_m[i0] : 0, m1 = v1 ? pend_m[i1] : 0;
            u32 A = (u32)m0, Bk = (u32)(m0 >> 32), C = (u32)m1, D = (u32)(m1 >> 32);
#pragma unroll
            for (int j = 16; j; j >>= 1) {
                const u32 hi = (j == 16) ? 0xFFFF0000u : (j == 8) ? 0xFF00FF00u : (j == 4) ? 0xF0F0F0F0u : (j == 2) ? 0xCCCCCCCCu : 0xAAAAAAAAu;
                const u32 yA = __shfl_xor_sync(0xffffffffu, A, j), yB = __shfl_xor_sync(0xffffffffu, Bk, j);
                const u32 yC = __shfl_xor_sync(0xffffffffu, C, j), yD = __shfl_xor_sync(0xffffffffu, D, j);
                if (lane & j) { A = (A & hi) | ((yA >> j) & ~hi); Bk = (Bk & hi) | ((yB >> j) & ~hi); C = (C & hi) | ((yC >> j) & ~hi); D = (D & hi) | ((yD >> j) & ~hi); }
                else { A = (A & ~hi) | ((yA << j) & hi); Bk = (Bk & ~hi) | ((yB << j) & hi); C = (C & ~hi) | ((yC << j) & hi); D = (D & ~hi) | ((yD << j) & hi); }
            }
            slices3[lane * 16 + q] = (u64)A | ((u64)C << 32);
            slices3[(lane + 32) * 16 + q] = (u64)Bk | ((u64)D << 32);
            u64 cm = (v0 ? m0 : ~0ULL) & (v1 ? m1 : ~0ULL);
            for (int o = 16; o; o >>= 1) cm &= __shfl_xor_sync(0xffffffffu, cm, o);
            unsigned bv0 = __ballot_sync(0xffffffffu, v0), bv1 = __ballot_sync(0xffffffffu, v1);
            if (lane == 0) { commonm[q] = cm; validm[q] = (u64)bv0 | ((u64)bv1 << 32); }
        }
        __syncthreads();
        // phase 3a: per probe, the 16-bit mask of chunks that survive the common-mask skip; probes with any kept chunk
        // go to a list (unordered: the output is a set). 3b: half-warps take list entries, lane = chunk.
        if (MODE != 0) {
            for (int pp = t; pp < nprobe; pp += NT) {
                const u64 tm = prob_m[pp];
                u32 km = 0;
                for (int qq = 0; qq < nch; qq++) if (!(MODE == 2 && (commonm[qq] & tm))) km |= 1u << qq;
                if (km) { int sl = atomicAdd(&s_nlist, 1); plist[sl] = (u32)pp | (km << 16); }
            }
            __syncthreads();
            const int nlist = s_nlist;
            const int q = lane & 15;
            u64 vmq = q < nch ? validm[q] : 0;
            for (int e0 = 0; e0 < nlist; e0 += NT / 16) {   // block-uniform
                const int e = e0 + w * 2 + (lane >> 4);
                u64 wd = 0; u32 pk = 0;
                if (e < nlist) {
                    const u32 ent = plist[e];
                    pk = ent & 0xffffu;
                    if ((ent >> (16 + q)) & 1u) {
                        my_kept++;
                        const u32 *dp = prob_d + pk * 5;
                        u64 acc = 0;
#pragma unroll
                        for (int k5 = 0; k5 < 5; k5++) {
                            const u32 dw = dp[k5];
#pragma unroll
                            for (int k = 0; k < 4; k++) if (k5 * 4 + k < MAXPOP) acc |= slices3[((dw >> (8 * k)) & 0xffu) * 16 + q];
                        }
                        wd = ~acc & vmq;
                    }
                }
                if (t == 0) my_lslots += (u64)min(NT / 16, nlist - e0) * nch;
#if NOOUT
                my_surv += __popcll(wd);
#else
                const unsigned nzb = __ballot_sync(0xffffffffu, wd != 0);
                if (nzb) {   // warp-private slabs of SLAB records: a global atomic only when a slab is full
                    const int nn = __popc(nzb);
                    if (slab_used + nn > SLAB) {
                        if (slab_id >= 0 && lane == 0) g_slabcnt[slab_id] = slab_used;
                        long long sid = 0;
                        if (lane == 0) sid = (long long)atomicAdd(outn, 1ULL);
                        slab_id = __shfl_sync(0xffffffffu, sid, 0); slab_used = 0;
                    }
                    if (wd) {
                        const u64 slot = (u64)slab_id * SLAB + slab_used + __popc(nzb & ((1u << lane) - 1));
                        if (slot < outcap) {
                            uint4 r; r.x = prob_i[pk]; r.y = pend_p[q * 64]; r.z = (u32)wd; r.w = (u32)(wd >> 32);
                            reinterpret_cast<uint4 *>(outbuf)[slot] = r;
                        }
                        my_surv += __popcll(wd);
                    }
                    slab_used += nn;
                }
#endif
            }
            if (t == 0) my_flat += (u64)nprobe * nch;
        }
        if (t == 0) { my_chunks += nch; my_children += (u64)ntake; }
        __syncthreads();
        // phase 4: carry the rest (< NT + 64 - 1 ... at most PEND3 - FILL3) to the front; ranges are disjoint
        const int left = npend - ntake;
        if (t < left) { u64 m = pend_m[ntake + t]; u32 pp = pend_p[ntake + t]; pend_m[t] = m; pend_p[t] = pp; }
        __syncthreads();
        npend_r = left;
        if (t == 0) s_nlist = 0;
        __syncthreads();
        if (done && left == 0) break;
    }
    if (slab_id >= 0 && lane == 0) g_slabcnt[slab_id] = slab_used;
    if (my_children) atomicAdd(&cnt[d * 5 + 0], my_children);
    if (my_chunks) atomicAdd(&cnt[d * 5 + 1], my_chunks);
    if (my_flat) atomicAdd(&cnt[d * 5 + 2], my_flat);
    if (my_kept) atomicAdd(&cnt[d * 5 + 3], my_kept);
    if (my_surv) atomicAdd(&cnt[d * 5 + 4], my_surv);
    if (my_lslots) atomicAdd(&cnt[64 * 5], my_lslots);
}
#ifndef KVER
#define KVER 7
#endif
#if KVER == 7
#define KMAIN k_main7
#elif KVER == 6
#define KMAIN k_main6
#elif KVER == 5
#define KMAIN k_main5
#elif KVER == 4
#define KMAIN k_main4
#elif KVER == 3
#define KMAIN k_main3
#else
#define KMAIN k_main
#endif
#endif

// ---------------------------------------------------------------- main
int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: g2bench DIR [reps]\n"); return 1; }
    std::string dir = argv[1];
    int reps = argc > 2 ? atoi(argv[2]) : 3;
    auto T0 = std::chrono::steady_clock::now();
    auto secs = [&](std::chrono::steady_clock::time_point a) { return std::chrono::duration<double>(std::chrono::steady_clock::now() - a).count(); };
    std::vector<Top> tops = load_tops(dir);
    std::vector<long> scnt; u64 pip; u128 rstart, rend;
    auto expect = load_surv(dir, scnt, pip, rstart, rend);
    printf("loaded %zu tops, pip %llu, expected survivors %ld (unit 0: %ld)\n", tops.size(), pip, [&] { long s = 0; for (long x : scnt) s += x; return s; }(), scnt[0]);
    // tops per (d, ct)
    std::vector<int> order(tops.size());
    for (size_t i = 0; i < tops.size(); i++) order[i] = (int)i;
    std::stable_sort(order.begin(), order.end(), [&](int a, int b) {
        int ca = (int)(tops[a].h % 63), cb = (int)(tops[b].h % 63);
        return tops[a].d != tops[b].d ? tops[a].d < tops[b].d : ca < cb; });
    std::vector<u64> tmask(tops.size()); std::vector<int> tseg(64 * M * 2, 0);
    std::vector<Top> ts(tops.size());
    for (size_t i = 0; i < order.size(); i++) { ts[i] = tops[order[i]]; tmask[i] = ts[i].mask; }
    for (int s = 0; s < 64 * M; s++) { tseg[2 * s] = 0; tseg[2 * s + 1] = 0; }
    {
        size_t i = 0;
        for (int dd = 0; dd < 64; dd++) for (int ct = 0; ct < M; ct++) {
            tseg[(dd * M + ct) * 2] = (int)i;
            while (i < ts.size() && ts[i].d == (u32)dd && (int)(ts[i].h % 63) == ct) i++;
            tseg[(dd * M + ct) * 2 + 1] = (int)i;
        }
        if (i != ts.size()) { fprintf(stderr, "top segmentation failed\n"); return 1; }
    }
    // roots (base-wide, shared by every super-unit: not part of the per-super-unit cost)
    std::vector<u32> r4s; std::vector<u64> rms;
    for (u64 r = 0; r < (1ULL << 24); r++) { u64 m = root_mask(r); if (m) { r4s.push_back((u32)r); rms.push_back(m); } }
    printf("roots %zu (%.2fs)\n", r4s.size(), secs(T0));
    { int mp = 0; for (auto &x : tops) mp = std::max(mp, __builtin_popcountll(x.mask)); printf("max top popcount %d\n", mp);
#ifndef CPU_ONLY
      if (mp > MAXPOP) { fprintf(stderr, "top popcount above MAXPOP\n"); return 6; }
#endif
    }
    // CPU parents (reference) + digit ranking from parent and pooled top digit frequencies
    std::vector<Parent> P0;
    for (size_t i = 0; i < r4s.size(); i++) { Parent p; if (make_parent(r4s[i], rms[i], pip, p)) P0.push_back(p); }
    double fp[64] = {0}, ft[64] = {0};
    for (auto &p : P0) for (int v = 0; v < 64; v++) fp[v] += (p.mask >> v) & 1;
    for (auto &x : tops) for (int v = 0; v < 64; v++) ft[v] += (x.mask >> v) & 1;
    std::vector<int> dg(64); for (int v = 0; v < 64; v++) dg[v] = v;
    std::sort(dg.begin(), dg.end(), [&](int a, int b) { return fp[a] * ft[a] > fp[b] * ft[b]; });
    unsigned char rank[8]; for (int i = 0; i < 8; i++) rank[i] = (unsigned char)dg[i];
    printf("parents %zu; key digits:", P0.size()); for (int i = 0; i < 8; i++) printf(" %d", rank[i]); printf("\n");
    // stable sort by (class, key8 desc)
    std::vector<Parent> P(P0);
    std::stable_sort(P.begin(), P.end(), [&](const Parent &a, const Parent &b) {
        u32 ka = a.cls * 256 + (255 - key8(a.mask, rank)), kb = b.cls * 256 + (255 - key8(b.mask, rank)); return ka < kb; });
    std::vector<int> pseg(M + 1, 0);
    { size_t i = 0; for (int c = 0; c < M; c++) { pseg[c] = (int)i; while (i < P.size() && P[i].cls == c) i++; } pseg[M] = (int)P.size(); }

    // verification helper: survivor pairs -> n -> per unit sorted set vs expected
    auto verify = [&](const std::vector<std::pair<u32, u32>> &pairs, const char *tag) -> bool {
        std::vector<std::vector<u128>> got(64);
        long clipped = 0;
        for (auto &pr : pairs) {
            const Top &tp = ts[pr.first];
            u128 n = ((u128)tp.h << 60) + P[pr.second].r + ((u128)tp.d << 54);
            if (n < tp.lo || n > tp.hi) { clipped++; continue; }
            got[tp.d].push_back(n);
        }
        bool ok = true; long tot = 0;
        for (int dd = 0; dd < 64; dd++) {
            std::sort(got[dd].begin(), got[dd].end());
            tot += got[dd].size();
            if (got[dd] != expect[dd]) { ok = false; fprintf(stderr, "%s: unit %d: got %zu expected %zu\n", tag, dd, got[dd].size(), expect[dd].size()); }
        }
        printf("VERIFY %s: %ld survivors (%ld outside a clipped top), every unit's set %s\n", tag, tot, clipped, ok ? "EQUAL to the prototype's" : "DIFFERS");
        return ok;
    };
    double adm_su = 0;  // admissible n of the super-unit: n in [start,end) with digits 4..9 fixed, x 8/63
    { long double W = (long double)(rend - rstart); adm_su = (double)(W / (long double)(1ULL << 30) / 64.0L * 64.0L * 8.0L / 63.0L); }
    printf("admissible n in the super-unit ~ %.4e\n", adm_su);

    // CPU reference (env SKIPCPU=1 skips it on later variants; the GPU sets are still checked against the prototype's)
    if (!getenv("SKIPCPU")) {
        auto t0 = std::chrono::steady_clock::now();
        Counts cn; std::vector<std::pair<u32, u32>> out;
        for (int c = 0; c < M; c++) for (u32 dd = 0; dd < 64; dd++) cpu_block(c, dd, P, pseg, tmask, tseg, true, cn, out);
        double s = secs(t0);
        printf("CPU ref: children %llu chunks %llu flat %llu kept %llu (%.3f) surv %llu  %.1fs\n", cn.children, cn.chunks, cn.flat, cn.kept, (double)cn.kept / cn.flat, cn.surv, s);
        printf("CPU ref per adm: children %.3e flat %.3e kept %.3e surv %.3e\n", cn.children / adm_su, cn.flat / adm_su, cn.kept / adm_su, cn.surv / adm_su);
        if (!verify(out, "cpu")) return 2;
#ifdef CPU_ONLY
        return 0;
#endif
    }
#ifndef CPU_ONLY
    // ---------------- GPU
    cudaDeviceProp prop; CK(cudaGetDeviceProperties(&prop, 0));
    printf("GPU %s, %d SMs\n", prop.name, prop.multiProcessorCount);
    CK(cudaMemcpyToSymbol(c_rank, rank, 8));
    CK(cudaMemcpyToSymbol(c_roots, ROOTS, sizeof ROOTS));
    int nr = (int)r4s.size();
    u32 *d_r4; u64 *d_rm; CK(cudaMalloc(&d_r4, nr * 4)); CK(cudaMalloc(&d_rm, nr * 8));
    CK(cudaMemcpy(d_r4, r4s.data(), nr * 4, cudaMemcpyHostToDevice)); CK(cudaMemcpy(d_rm, rms.data(), nr * 8, cudaMemcpyHostToDevice));
    u64 *d_pr, *d_pm, *d_sr, *d_sm; u32 *d_pc, *d_sc; unsigned short *d_key, *d_keyc, *d_skey; unsigned char *d_flag;
    u32 *d_idx, *d_idxc, *d_perm; int *d_nsel, *d_pseg;
    CK(cudaMalloc(&d_pr, nr * 8)); CK(cudaMalloc(&d_pm, nr * 8)); CK(cudaMalloc(&d_pc, nr * 4)); CK(cudaMalloc(&d_key, nr * 2));
    CK(cudaMalloc(&d_flag, nr)); CK(cudaMalloc(&d_idx, nr * 4)); CK(cudaMalloc(&d_idxc, nr * 4)); CK(cudaMalloc(&d_keyc, nr * 2));
    CK(cudaMalloc(&d_skey, nr * 2)); CK(cudaMalloc(&d_perm, nr * 4)); CK(cudaMalloc(&d_sr, nr * 8)); CK(cudaMalloc(&d_sm, nr * 8));
    CK(cudaMalloc(&d_sc, nr * 4)); CK(cudaMalloc(&d_nsel, 4)); CK(cudaMalloc(&d_pseg, (M + 1) * 4));
    { std::vector<u32> id(nr); for (int i = 0; i < nr; i++) id[i] = i; CK(cudaMemcpy(d_idx, id.data(), nr * 4, cudaMemcpyHostToDevice)); }
    void *d_tmp = nullptr; size_t tmpb = 0, tb1 = 0, tb2 = 0, tb3 = 0;
    cub::DeviceSelect::Flagged(nullptr, tb1, d_idx, d_flag, d_idxc, d_nsel, nr);
    cub::DeviceSelect::Flagged(nullptr, tb3, d_key, d_flag, d_keyc, d_nsel, nr);
    cub::DeviceRadixSort::SortPairs(nullptr, tb2, d_keyc, d_skey, d_idxc, d_perm, nr, 0, 14);
    tmpb = std::max(tb1, std::max(tb2, tb3)); CK(cudaMalloc(&d_tmp, tmpb));
    int npar = 0;
    auto prep = [&]() {
        k_parents<<<(nr + 255) / 256, 256>>>(d_r4, d_rm, nr, pip, d_pr, d_pm, d_pc, d_key, d_flag);
        size_t a = tmpb; cub::DeviceSelect::Flagged(d_tmp, a, d_idx, d_flag, d_idxc, d_nsel, nr);
        a = tmpb; cub::DeviceSelect::Flagged(d_tmp, a, d_key, d_flag, d_keyc, d_nsel, nr);
        CK(cudaMemcpy(&npar, d_nsel, 4, cudaMemcpyDeviceToHost));
        a = tmpb; cub::DeviceRadixSort::SortPairs(d_tmp, a, d_keyc, d_skey, d_idxc, d_perm, npar, 0, 14);
        k_gather<<<(npar + 255) / 256, 256>>>(d_perm, npar, d_pr, d_pm, d_pc, d_sr, d_sm, d_sc);
        k_segments<<<(npar + 255) / 256, 256>>>(d_skey, npar, d_pseg);
    };
    size_t tb4 = 0;
    cub::DeviceSelect::If(nullptr, tb4, cub::CountingInputIterator<u32>(0), d_idxc, d_nsel, nr, SelPar{d_r4, d_rm, pip});
    if (tb4 > tmpb) { CK(cudaFree(d_tmp)); tmpb = tb4; CK(cudaMalloc(&d_tmp, tmpb)); }
    std::vector<cudaEvent_t> pev(8); for (auto &e : pev) CK(cudaEventCreate(&e));
    auto prep2 = [&](bool ev) {
        if (ev) CK(cudaEventRecord(pev[0]));
        size_t a = tmpb; cub::DeviceSelect::If(d_tmp, a, cub::CountingInputIterator<u32>(0), d_idxc, d_nsel, nr, SelPar{d_r4, d_rm, pip});
        if (ev) CK(cudaEventRecord(pev[1]));
        k_build<<<(nr / 8 + 255) / 256, 256>>>(d_idxc, d_nsel, d_r4, d_rm, pip, d_pr, d_pm, d_pc, d_keyc);
        if (ev) CK(cudaEventRecord(pev[2]));
        CK(cudaMemcpy(&npar, d_nsel, 4, cudaMemcpyDeviceToHost));
        if (ev) CK(cudaEventRecord(pev[3]));
        a = tmpb; cub::DeviceRadixSort::SortPairs(d_tmp, a, d_keyc, d_skey, d_idx, d_perm, npar, 0, 14);
        if (ev) CK(cudaEventRecord(pev[4]));
        k_gather<<<(npar + 255) / 256, 256>>>(d_perm, npar, d_pr, d_pm, d_pc, d_sr, d_sm, d_sc);
        if (ev) CK(cudaEventRecord(pev[5]));
        k_segments<<<(npar + 255) / 256, 256>>>(d_skey, npar, d_pseg);
        if (ev) CK(cudaEventRecord(pev[6]));
    };
    uint4 *d_val, *d_sval; u32 *d_r4c; CK(cudaMalloc(&d_val, nr / 8 * 16)); CK(cudaMalloc(&d_sval, nr / 8 * 16)); CK(cudaMalloc(&d_r4c, nr * 4));
    size_t tb5 = 0, tb6 = 0;
    cub::DeviceSelect::If(nullptr, tb5, d_r4, d_r4c, d_nsel, nr, SelPar3{pip});
    cub::DeviceRadixSort::SortPairs(nullptr, tb6, d_keyc, d_skey, d_val, d_sval, nr / 8, 0, 14);
    if (std::max(tb5, tb6) > tmpb) { CK(cudaFree(d_tmp)); tmpb = std::max(tb5, tb6); CK(cudaMalloc(&d_tmp, tmpb)); }
    auto prep3 = [&](bool ev) {
        if (ev) CK(cudaEventRecord(pev[0]));
        size_t a = tmpb; cub::DeviceSelect::If(d_tmp, a, d_r4, d_r4c, d_nsel, nr, SelPar3{pip});
        if (ev) CK(cudaEventRecord(pev[1]));
        k_build3<<<(nr / 8 + 255) / 256, 256>>>(d_r4c, d_nsel, pip, d_keyc, d_val);
        if (ev) CK(cudaEventRecord(pev[2]));
        CK(cudaMemcpy(&npar, d_nsel, 4, cudaMemcpyDeviceToHost));
        if (ev) CK(cudaEventRecord(pev[3]));
        a = tmpb; cub::DeviceRadixSort::SortPairs(d_tmp, a, d_keyc, d_skey, d_val, d_sval, npar, 0, 14);
        if (ev) CK(cudaEventRecord(pev[4]));
        k_split3<<<(npar + 255) / 256, 256>>>(d_sval, npar, pip, d_sr, d_sm, d_sc);
        if (ev) CK(cudaEventRecord(pev[5]));
        k_segments<<<(npar + 255) / 256, 256>>>(d_skey, npar, d_pseg);
        if (ev) CK(cudaEventRecord(pev[6]));
    };
    cudaEvent_t e0, e1; CK(cudaEventCreate(&e0)); CK(cudaEventCreate(&e1));
    const int prepv = getenv("PREP1") ? 1 : getenv("PREP2") ? 2 : 3;
    const bool use_prep2 = prepv >= 2;
    auto prepx = [&]() { if (prepv == 3) prep3(false); else if (prepv == 2) prep2(false); else prep(); };
    prepx(); CK(cudaDeviceSynchronize());
    if (use_prep2 && (nr / 8) < 1042046 + 1) { fprintf(stderr, "k_build grid too small\n"); return 7; }
    // exactness of the GPU parents: same order as the CPU stable sort
    {
        std::vector<u64> gr(npar); std::vector<int> gseg(M + 1);
        CK(cudaMemcpy(gr.data(), d_sr, npar * 8, cudaMemcpyDeviceToHost)); CK(cudaMemcpy(gseg.data(), d_pseg, (M + 1) * 4, cudaMemcpyDeviceToHost));
        bool ok = npar == (int)P.size() && gseg == pseg;
        for (int i = 0; ok && i < npar; i++) ok = gr[i] == P[i].r;
        printf("GPU parents %d, order and class segments %s the CPU's\n", npar, ok ? "EQUAL to" : "DIFFER from");
        if (!ok) return 3;
    }
    float ms; std::vector<float> tprep;
    if (use_prep2) {
        std::vector<std::vector<float>> st(6);
        for (int r = 0; r < reps + 1; r++) { if (prepv == 3) prep3(true); else prep2(true); CK(cudaEventSynchronize(pev[6])); for (int k = 0; k < 6; k++) { CK(cudaEventElapsedTime(&ms, pev[k], pev[k + 1])); if (r) st[k].push_back(ms); } }
        const char *nm[6] = {"select-if over roots", "build parents", "count to host", "radix sort 14 bit", prepv == 3 ? "split (sequential)" : "gather", "segments"};
        for (int k = 0; k < 6; k++) { std::sort(st[k].begin(), st[k].end()); printf("PREP2 step %-22s median %.3f ms\n", nm[k], st[k][st[k].size() / 2]); }
    }
    printf("prep version: %s\n", prepv == 3 ? "prep3 (r4-only select-if + build + sort pairs with the record + split)" : prepv == 2 ? "prep2 (select-if + build)" : "prep1 (flag + 2 selects, as staged)");
    for (int r = 0; r < reps + 1; r++) { CK(cudaEventRecord(e0)); prepx(); CK(cudaEventRecord(e1)); CK(cudaEventSynchronize(e1)); CK(cudaEventElapsedTime(&ms, e0, e1)); if (r) tprep.push_back(ms); }
    std::sort(tprep.begin(), tprep.end());
    printf("PREP: median %.3f ms (min %.3f) for %d parents from %d roots: %.1f ps per parent, %.2f ps per root\n",
           tprep[tprep.size() / 2], tprep[0], npar, nr, tprep[tprep.size() / 2] * 1e9 / npar, tprep[tprep.size() / 2] * 1e9 / nr);
    // tops and outputs
    u64 *d_tm; int *d_tseg; u64 *d_cnt, *d_outn; u32 *d_out;
    u64 outcap = 40000000;
    CK(cudaMalloc(&d_tm, tmask.size() * 8)); CK(cudaMalloc(&d_tseg, tseg.size() * 4)); CK(cudaMalloc(&d_cnt, (64 * 5 + 8) * 8));
    CK(cudaMalloc(&d_outn, 8)); CK(cudaMalloc(&d_out, outcap * 16));
    u32 *d_slabcnt = nullptr;
#if KVER >= 7
    CK(cudaMalloc(&d_slabcnt, (outcap / SLAB + 1) * 4)); CK(cudaMemcpyToSymbol(g_slabcnt, &d_slabcnt, sizeof(d_slabcnt)));
#endif
    CK(cudaMemcpy(d_tm, tmask.data(), tmask.size() * 8, cudaMemcpyHostToDevice));
    CK(cudaMemcpy(d_tseg, tseg.data(), tseg.size() * 4, cudaMemcpyHostToDevice));
    CK(cudaFuncSetAttribute(KMAIN<0>, cudaFuncAttributePreferredSharedMemoryCarveout, 100));
    CK(cudaFuncSetAttribute(KMAIN<1>, cudaFuncAttributePreferredSharedMemoryCarveout, 100));
    CK(cudaFuncSetAttribute(KMAIN<2>, cudaFuncAttributePreferredSharedMemoryCarveout, 100));
    printf("variant: KVER %d LOCKSTEP %d TILE %d AGG %d NT %d MINB %d NOOUT %d\n", KVER, LOCKSTEP, TILE, AGG, NT, MINB, NOOUT);
    {
        cudaFuncAttributes fa;
        CK(cudaFuncGetAttributes(&fa, KMAIN<2>)); int occ; CK(cudaOccupancyMaxActiveBlocksPerMultiprocessor(&occ, KMAIN<2>, NT, 0));
        printf("KMAIN<2>: %d registers, %zu B static shared, %d blocks/SM (%d warps of %d)\n", fa.numRegs, fa.sharedSizeBytes, occ, occ * NT / 32, prop.maxThreadsPerMultiProcessor / 32);
    }
    const char *names[3] = {"probes off", "skip off", "full"};
    double best[3];
    std::vector<u64> hc(64 * 5 + 8);
    for (int mode = 0; mode < 3; mode++) {
        std::vector<float> tv;
        for (int r = 0; r < reps + 1; r++) {
            CK(cudaMemset(d_cnt, 0, (64 * 5 + 8) * 8)); CK(cudaMemset(d_outn, 0, 8));
            CK(cudaEventRecord(e0));
            if (mode == 0) KMAIN<0><<<M * 64, NT>>>(d_sm, d_sc, d_pseg, d_tm, d_tseg, d_cnt, d_out, d_outn, outcap);
            if (mode == 1) KMAIN<1><<<M * 64, NT>>>(d_sm, d_sc, d_pseg, d_tm, d_tseg, d_cnt, d_out, d_outn, outcap);
            if (mode == 2) KMAIN<2><<<M * 64, NT>>>(d_sm, d_sc, d_pseg, d_tm, d_tseg, d_cnt, d_out, d_outn, outcap);
            CK(cudaEventRecord(e1)); CK(cudaEventSynchronize(e1)); CK(cudaGetLastError());
            CK(cudaEventElapsedTime(&ms, e0, e1));
            if (r) tv.push_back(ms);
        }
        std::sort(tv.begin(), tv.end());
        best[mode] = tv[tv.size() / 2];
        CK(cudaMemcpy(hc.data(), d_cnt, (64 * 5 + 8) * 8, cudaMemcpyDeviceToHost));
        u64 s[5] = {0}; for (int dd = 0; dd < 64; dd++) for (int j = 0; j < 5; j++) s[j] += hc[dd * 5 + j];
        u64 nout; CK(cudaMemcpy(&nout, d_outn, 8, cudaMemcpyDeviceToHost));
        printf("MODE %-10s median %.3f ms (min %.3f, max %.3f, %d reps) children %llu chunks %llu flat %llu kept %llu surv %llu\n",
               names[mode], best[mode], tv[0], tv.back(), reps, s[0], s[1], s[2], s[3], s[4]);
        if (mode >= 1) {
#if KVER >= 7
            if (nout * SLAB > outcap) { fprintf(stderr, "output overflow\n"); return 4; }
#else
            if (nout > outcap) { fprintf(stderr, "output overflow\n"); return 4; }
#endif
#if KVER >= 7
            const u64 nslab = nout;
            std::vector<u32> sc(nslab); CK(cudaMemcpy(sc.data(), d_slabcnt, nslab * 4, cudaMemcpyDeviceToHost));
            std::vector<u32> ob0(4 * nslab * SLAB); CK(cudaMemcpy(ob0.data(), d_out, nslab * SLAB * 16, cudaMemcpyDeviceToHost));
            std::vector<u32> ob; for (u64 i = 0; i < nslab; i++) ob.insert(ob.end(), ob0.begin() + 4 * i * SLAB, ob0.begin() + 4 * (i * SLAB + sc[i]));
            nout = ob.size() / 4;
            printf("slabs %llu of %d (fill %.3f)\n", nslab, SLAB, (double)nout / (nslab * SLAB));
#endif
#if KVER >= 5
#if KVER < 7
            std::vector<u32> ob(4 * nout); CK(cudaMemcpy(ob.data(), d_out, nout * 16, cudaMemcpyDeviceToHost));
#endif
            std::vector<std::pair<u32, u32>> pairs;
            for (u64 i = 0; i < nout; i++) {  // expand a word record: the chunk's members are the next 64 certified children
                u32 ti = ob[4 * i], pf = ob[4 * i + 1]; u64 wd = (u64)ob[4 * i + 2] | ((u64)ob[4 * i + 3] << 32);
                u32 dd = ts[ti].d; int cl = P[pf].cls; int k = 0;
                for (int j = (int)pf; j < pseg[cl + 1] && k < 64; j++) if (child_mask(P[j].mask, P[j].cacc, dd)) { if ((wd >> k) & 1) pairs.push_back({ti, (u32)j}); k++; }
            }
            printf("records %llu (%.2f survivors per nonzero word), lane slots %llu (kept/slots %.3f)\n", nout, (double)pairs.size() / nout, hc[320], (double)s[3] / hc[320]);
#else
            std::vector<u32> ob(2 * nout); CK(cudaMemcpy(ob.data(), d_out, nout * 8, cudaMemcpyDeviceToHost));
            std::vector<std::pair<u32, u32>> pairs(nout); for (u64 i = 0; i < nout; i++) pairs[i] = {ob[2 * i], ob[2 * i + 1]};
#endif
            if (NOOUT) printf("NOOUT: sets not checked\n"); else if (!verify(pairs, names[mode])) return 5;
        }
        if (mode == 2) {
            double kept = (double)s[3], flat = (double)s[2], ch = (double)s[0];
            printf("RESULT ps per child %.2f (probes-off time / children); ps per flat incidence %.2f (skip-off minus probes-off); ps per kept word all-in %.2f (full minus probes-off, / kept)\n",
                   best[0] * 1e9 / ch, (best[1] - best[0]) * 1e9 / flat, (best[2] - best[0]) * 1e9 / kept);
            double e2e = (tprep[tprep.size() / 2] + best[2]) * 1e-3;
            printf("RESULT end-to-end (prep + full) %.3f ms for %.4e admissible n = %.4f fs per admissible n (tops and survivor checks not included)\n",
                   e2e * 1e3, adm_su, e2e / adm_su * 1e15);
        }
    }
#endif
    return 0;
}
