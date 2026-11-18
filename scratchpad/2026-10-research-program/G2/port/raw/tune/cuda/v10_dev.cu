typedef unsigned long long u64;
typedef unsigned int u32;
static const int M = 63, NROOT = 8;
__constant__ int c_roots[NROOT];
static __device__ inline u64 child_mask(u64 pm, u32 cacc, u32 d) {
    u32 e2 = ((cacc & 63) + ((cacc >> 16) & 63) * d) & 63;
    u32 e3 = (((cacc >> 8) & 63) + ((cacc >> 24) & 63) * d) & 63;
    u64 add = (1ULL << e2) | (1ULL << e3);
    if (e2 == e3 || (pm & add)) return 0;
    return pm | add;
}
#define NT 256
#define MINB 1
#define NOOUT 0
#define FILL3 1024
#define PEND3 (FILL3 + NT)
#define MAXPOP 17
#define SLAB 256
#define PMAX8 576
__device__ u32 *g_slabcnt;
template <int MODE>
__global__ void __launch_bounds__(NT, MINB) k_main10(const u64 *sm, const u32 *scacc, const int *pseg,
                                              const u64 *tmask, const int *tseg,
                                              u64 *cnt, u32 *outbuf, u64 *outn, u64 outcap) {
    __shared__ u32 pend_p[PEND3];
    __shared__ u64 slices3[65 * 16];  // row 64 = zero slice (padding digit)
    __shared__ uint4 prob_d4[PMAX8];
    __shared__ u32 prob_dx[PMAX8];  // probe digits, 4 per word, padded with 64
    __shared__ u64 commonm[16], validm[16];
    __shared__ u64 prob_m[PMAX8];
    __shared__ int wcnt2[2][NT / 32];
    __shared__ int s_pend, s_nprobe, s_tot, s_nlist;
    __shared__ u32 plist[PMAX8];
    const int c = blockIdx.x / 64;
    const u32 d = blockIdx.x % 64;
    const int t = threadIdx.x, lane = t & 31, w = t >> 5;
    const uint4 *PV = reinterpret_cast<const uint4 *>(sm);  // v10: sorted parent records straight from the sort
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
            for (int j = t; j < b1 - b0; j += NT) if (base + j < PMAX8) {
                u64 x = tmask[b0 + j]; prob_m[base + j] = x;
                u32 dw[5] = {0x40404040u, 0x40404040u, 0x40404040u, 0x40404040u, 0x40404040u};
                for (int k = 0; x && k < 20; k++) { u32 v = __ffsll((long long)x) - 1; dw[k >> 2] = (dw[k >> 2] & ~(0xffu << (8 * (k & 3)))) | (v << (8 * (k & 3))); x &= x - 1; }
                prob_d4[base + j] = make_uint4(dw[0], dw[1], dw[2], dw[3]); prob_dx[base + j] = dw[4];
            }
            base += b1 - b0;
        }
    }
    __syncthreads();
    const int nprobe = min(s_nprobe, PMAX8);
    u64 my_children = 0, my_chunks = 0, my_flat = 0, my_kept = 0, my_surv = 0, my_lslots = 0;
    int slab_id = -1; int slab_used = SLAB;  // full: the first record allocates
    const int pb = pseg[c], pe = pseg[c + 1];
    int cur = pb, npend_r = 0, par = 0;
    while (true) {
        // phase 1 (v6): one barrier per NT parents; warp counts double-buffered, pend count kept block-uniform in a register
        while (npend_r < FILL3 && cur < pe) {
            int idx = cur + t;
            u64 m = 0;
            if (idx < pe) { const uint4 v = PV[idx]; m = child_mask((u64)v.x | ((u64)v.y << 32), v.z, d); }
            unsigned bal = __ballot_sync(0xffffffffu, m != 0);
            if (lane == 0) wcnt2[par][w] = __popc(bal);
            __syncthreads();
            int off = 0, tot = 0;
#pragma unroll
            for (int i = 0; i < NT / 32; i++) { int x = wcnt2[par][i]; off += (i < w) ? x : 0; tot += x; }
            if (m) { int pos = npend_r + off + __popc(bal & ((1u << lane) - 1)); pend_p[pos] = idx; }
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
            u64 m0 = 0, m1 = 0;  // v8: child masks recomputed from the (cached) parent records
            if (v0) { const uint4 v = PV[pend_p[i0]]; m0 = child_mask((u64)v.x | ((u64)v.y << 32), v.z, d); }
            if (v1) { const uint4 v = PV[pend_p[i1]]; m1 = child_mask((u64)v.x | ((u64)v.y << 32), v.z, d); }
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
            auto word = [&](int e, u32 &pk) -> u64 {
                pk = 0;
                if (e >= nlist) return 0;
                const u32 ent = plist[e];
                pk = ent & 0xffffu;
                if (!((ent >> (16 + q)) & 1u)) return 0;
                my_kept++;
                const uint4 d4 = prob_d4[pk];
                const u32 dws[5] = {d4.x, d4.y, d4.z, d4.w, (MAXPOP > 16) ? prob_dx[pk] : 0u};
                u64 acc = 0;
#pragma unroll
                for (int k5 = 0; k5 < 5; k5++) {
                    const u32 dw = dws[k5];
#pragma unroll
                    for (int k = 0; k < 4; k++) if (k5 * 4 + k < MAXPOP) acc |= slices3[((dw >> (8 * k)) & 0xffu) * 16 + q];
                }
                return ~acc & vmq;
            };
            const int pend0 = pend_p[q * 64];
            for (int e0 = 0; e0 < nlist; e0 += NT / 8) {   // block-uniform; two list entries per lane per step
                const int ea = e0 + w * 2 + (lane >> 4), eb = ea + NT / 16;
                u32 pa, pb2;
                const u64 wa = word(ea, pa), wb = word(eb, pb2);
                if (t == 0) my_lslots += (u64)min(NT / 8, nlist - e0) * nch;
#if NOOUT
                my_surv += __popcll(wa) + __popcll(wb);
#else
                const unsigned za = __ballot_sync(0xffffffffu, wa != 0), zb = __ballot_sync(0xffffffffu, wb != 0);
                if (za | zb) {
                    const int na = __popc(za), nn = na + __popc(zb);
                    if (slab_used + nn > SLAB) {
                        if (slab_id >= 0 && lane == 0) g_slabcnt[slab_id] = slab_used;
                        int sid = 0;
                        if (lane == 0) sid = (int)atomicAdd(outn, 1ULL);
                        slab_id = __shfl_sync(0xffffffffu, sid, 0); slab_used = 0;
                    }
                    const unsigned lt = (1u << lane) - 1;
                    const u64 sbase = (u64)slab_id * SLAB + slab_used;
                    if (wa) {
                        const u64 slot = sbase + __popc(za & lt);
                        if (slot < outcap) reinterpret_cast<uint4 *>(outbuf)[slot] = make_uint4(pa | (d << 16), pend0, (u32)wa, (u32)(wa >> 32));
                        my_surv += __popcll(wa);
                    }
                    if (wb) {
                        const u64 slot = sbase + na + __popc(zb & lt);
                        if (slot < outcap) reinterpret_cast<uint4 *>(outbuf)[slot] = make_uint4(pb2 | (d << 16), pend0, (u32)wb, (u32)(wb >> 32));
                        my_surv += __popcll(wb);
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
        if (t < left) { u32 pp = pend_p[ntake + t]; pend_p[t] = pp; }
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
