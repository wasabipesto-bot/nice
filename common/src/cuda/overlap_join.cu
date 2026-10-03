// The overlap join's join kernel with its fused middle-digit prefilter, for
// NVRTC: a port of `cubecl_join::kernels::join_kernel` (and its
// `flush_survivors` and `mid_pass`) to hand-written CUDA. The buffers, their
// layouts and the outputs are the CubeCL kernel's, so the two run on the same
// inputs and must write the same survivors (in another order: the lists are
// filled through atomics).
//
// Compiled once per field shape, with these defines:
//   BASE         the base (40..=64: masks are one 64-bit word)
//   KEY_LEVEL    1 when the last bottom digit is the free key digit
//   KEY_AT_ZERO  1 when that digit is position 0 (k = 1; tests only)
//   EPT          bottom entries each thread holds in registers
//   F0, K2       digits of n below the top's block, and the prefilter's depth
//   TUNED        (optional) the two CUDA-specific changes measured against the
//                faithful port: each full chunk of 32 tops is unrolled with
//                constant bit positions, and tops sit in shared memory as one
//                64-bit word each (one load per top instead of two)

#ifndef BASE
#define BASE 57
#endif
#ifndef KEY_LEVEL
#define KEY_LEVEL 1
#endif
#ifndef KEY_AT_ZERO
#define KEY_AT_ZERO 0
#endif
#ifndef EPT
#define EPT 4
#endif
#ifndef F0
#define F0 3
#endif
#ifndef K2
#define K2 8
#endif

// The CubeCL kernel's constants (`cubecl_join`: JOIN_WG, TOP_CAP,
// SURV_SH_CAP, SURV_FLUSH).
#define JOIN_WG 256
#define TOP_CAP 256
#define SURV_SH_CAP 1024
#define SURV_FLUSH 512
#define WARPS (JOIN_WG / 32)

#define M1 (BASE - 1)
#if KEY_LEVEL
#define NKEYS BASE
#else
#define NKEYS 1
#endif
#define WAVE (EPT * JOIN_WG)

typedef unsigned int u32;
typedef unsigned long long u64;

// The middle-digit test for one survivor (top t, r0): digits 0..K2 of n^2 and
// n^3 from n's low K2 digits (r0 and the top's P mod b^(K2-F0)) must be
// distinct, and disjoint from the top's certificate when its seed flag says
// every certified position is >= K2.
__device__ __forceinline__ bool mid_pass(u32 t, u32 r0, const u32* __restrict__ top_m,
                                         const u32* __restrict__ top_x) {
    u32 pm = top_x[2 * t];
    u64 m = 0;
    if (top_x[2 * t + 1] != 0) {
        m = ((u64)top_m[2 * t + 1] << 32) | (u64)top_m[2 * t];
    }
    u32 d[K2];
    u32 x = r0;
#pragma unroll
    for (int j = 0; j < F0; j++) {
        d[j] = x % BASE;
        x /= BASE;
    }
    u32 y = pm;
#pragma unroll
    for (int j = F0; j < K2; j++) {
        d[j] = y % BASE;
        y /= BASE;
    }
    u32 sq[K2];
    u32 carry = 0;
#pragma unroll
    for (int pos = 0; pos < K2; pos++) {
        u32 col = carry;
#pragma unroll
        for (int i = 0; i <= pos; i++) {
            col += d[i] * d[pos - i];
        }
        sq[pos] = col % BASE;
        carry = col / BASE;
    }
    bool ok = true;
    carry = 0;
#pragma unroll
    for (int pos = 0; pos < K2; pos++) {
        u32 col = carry;
#pragma unroll
        for (int i = 0; i <= pos; i++) {
            col += sq[i] * d[pos - i];
        }
        u32 g3 = col % BASE;
        carry = col / BASE;
        u32 g2 = sq[pos];
        u64 bb = (1ull << g2) | (1ull << g3);
        if (g2 == g3 || (m & bb) != 0) {
            ok = false;
        }
        m |= bb;
    }
    return ok;
}

// Flush the shared survivor stage through the prefilter: the whole block
// tests the staged survivors and only those that pass go to `out`, compacted
// per warp (ballot) with one atomic per round. `staged` counts every survivor
// staged. Called by the whole block after a barrier; `sc` is the stage count
// read after it.
__device__ void flush_survivors(const u32* s_t, const u32* s_r, u32* s_cnt, u32* s_base,
                                u32* warp_tot, const u32* __restrict__ top_m,
                                const u32* __restrict__ top_x, u32* out, u32* out_count,
                                u32* staged, u32 out_cap, u32 sc) {
    u32 n = sc < SURV_SH_CAP ? sc : SURV_SH_CAP;  // the rest went straight to `out`
    if (threadIdx.x == 0) {
        atomicAdd(staged, n);
    }
    const u32 lane = threadIdx.x & 31;
    const u32 warp = threadIdx.x >> 5;
    for (u32 rb = 0; rb < n; rb += JOIN_WG) {
        u32 i = rb + threadIdx.x;
        bool pass = false;
        u32 t = 0, r0 = 0;
        if (i < n) {
            t = s_t[i];
            r0 = s_r[i];
            pass = mid_pass(t, r0, top_m, top_x);
        }
        u32 ballot = __ballot_sync(0xffffffffu, pass);
        u32 idx = __popc(ballot & ((1u << lane) - 1u));
        if (lane == 0) {
            warp_tot[warp] = __popc(ballot);
        }
        __syncthreads();
        u32 off = 0, all = 0;
#pragma unroll
        for (u32 p = 0; p < WARPS; p++) {
            u32 tp = warp_tot[p];
            if (p < warp) {
                off += tp;
            }
            all += tp;
        }
        if (threadIdx.x == 0 && all > 0) {
            *s_base = atomicAdd(out_count, all);
        }
        __syncthreads();
        if (pass) {
            u32 g = *s_base + off + idx;
            if (g < out_cap) {
                out[2 * g] = t;
                out[2 * g + 1] = r0;
            }
        }
    }
    __syncthreads();
    if (threadIdx.x == 0) {
        *s_cnt = 0;
    }
}

// Record a pair that passed the AND and lies inside the top's interval: to the
// shared stage, or past a full stage straight to the output, untested.
__device__ __forceinline__ void stage(u32 t, u32 r0, u32* s_cnt, u32* s_t, u32* s_r, u32* surv,
                                      u32* surv_count, u32 surv_cap) {
    u32 at = atomicAdd(s_cnt, 1u);
    if (at < SURV_SH_CAP) {
        s_t[at] = t;
        s_r[at] = r0;
    } else {
        u32 g = atomicAdd(surv_count, 1u);
        if (g < surv_cap) {
            surv[2 * g] = t;
            surv[2 * g + 1] = r0;
        }
    }
}

// One block per work item (slot, bucket, top range): the bucket's tops in
// shared memory, EPT entries per thread in registers, a branch-free AND over
// 32 tops at a time, survivors staged in shared memory and prefiltered as the
// stage is flushed.
extern "C" __global__ void __launch_bounds__(JOIN_WG)
    join_kernel(const u32* __restrict__ ext_m, const u32* __restrict__ ext_pk,
                const u32* __restrict__ bp_r, const u32* __restrict__ seg,
                const u32* __restrict__ lists, const u32* __restrict__ counts,
                const u32* __restrict__ work, const u32* __restrict__ tl,
                const u32* __restrict__ top_m, const u32* __restrict__ top_r, u32* surv,
                u32* surv_count, const u32* __restrict__ top_x, u32* staged, u32 nwork,
                u32 nbp, u32 surv_cap) {
    __shared__ u32 warp_tot[WARPS];
#ifdef TUNED
    __shared__ u64 t_m[TOP_CAP];
#else
    __shared__ u32 t_lo[TOP_CAP];
    __shared__ u32 t_hi[TOP_CAP];
#endif
    __shared__ u32 t_rlo[TOP_CAP];
    __shared__ u32 t_rhi[TOP_CAP];
    __shared__ u32 t_id[TOP_CAP];
    __shared__ u32 s_t[SURV_SH_CAP];
    __shared__ u32 s_r[SURV_SH_CAP];
    __shared__ u32 s_cnt;
    __shared__ u32 s_base;

    if (threadIdx.x == 0) {
        s_cnt = 0;
    }
    __syncthreads();

    for (u32 w = blockIdx.x; w < nwork; w += gridDim.x) {
        const u32 slot = work[4 * w];
        const u32 bx = work[4 * w + 1];
        const u32 ts = work[4 * w + 2];
        const u32 te = work[4 * w + 3];
        const u32 dkey = bx / M1;
        const u32 cls = bx - dkey * M1;
        const u32 cs = seg[cls];
        const u32 clen = seg[cls + 1] - cs;
        const u32 ne = counts[(slot * NKEYS + dkey) * M1 + cls];
        const u32 lbase = slot * BASE * nbp + BASE * cs + dkey * clen;
        const u32 ebase = slot * nbp;

        for (u32 tc = ts; tc < te; tc += TOP_CAP) {
            const u32 nt = min(te - tc, (u32)TOP_CAP);
            if (threadIdx.x < nt) {
                u32 t = tl[tc + threadIdx.x];
#ifdef TUNED
                t_m[threadIdx.x] = ((u64)top_m[2 * t + 1] << 32) | (u64)top_m[2 * t];
#else
                t_lo[threadIdx.x] = top_m[2 * t];
                t_hi[threadIdx.x] = top_m[2 * t + 1];
#endif
                t_rlo[threadIdx.x] = top_r[2 * t];
                t_rhi[threadIdx.x] = top_r[2 * t + 1];
                t_id[threadIdx.x] = t;
            }
            __syncthreads();

            for (u32 ws = 0; ws < ne; ws += WAVE) {
                u32 mlo[EPT], mhi[EPT], rr[EPT], vv[EPT];
#pragma unroll
                for (int j = 0; j < EPT; j++) {
                    u32 sl = ws + threadIdx.x + j * JOIN_WG;
                    mlo[j] = 0xffffffffu;
                    mhi[j] = 0xffffffffu;
                    rr[j] = 0;
                    // An empty slot must never pass, whatever the top's mask.
                    vv[j] = 0;
                    if (sl < ne) {
                        vv[j] = 0xffffffffu;
                        u32 e = lists[lbase + sl];
                        u32 gi = ebase + e;
                        u64 m = ((u64)ext_m[2 * gi + 1] << 32) | (u64)ext_m[2 * gi];
#if KEY_LEVEL
                        u32 pk = ext_pk[gi];
                        u32 g2 = ((pk & 255u) + dkey * ((pk >> 16) & 255u)) % BASE;
                        u32 g3 = (((pk >> 8) & 255u) + dkey * (pk >> 24)) % BASE;
#if KEY_AT_ZERO
                        g2 = (dkey * dkey) % BASE;
                        g3 = (g2 * dkey) % BASE;
#endif
                        m |= (1ull << g2) | (1ull << g3);
#endif
                        mlo[j] = (u32)m;
                        mhi[j] = (u32)(m >> 32);
                        rr[j] = bp_r[e];
                    }
                }
                for (u32 jc = 0; jc < nt; jc += 32) {
                    u32 pm[EPT];
#pragma unroll
                    for (int j = 0; j < EPT; j++) {
                        pm[j] = 0;
                    }
#ifdef TUNED
                    if (jc + 32 <= nt) {
#pragma unroll
                        for (int i = 0; i < 32; i++) {
                            u64 tm = t_m[jc + i];
                            u32 tlo = (u32)tm, thi = (u32)(tm >> 32);
#pragma unroll
                            for (int j = 0; j < EPT; j++) {
                                u32 z = (mlo[j] & tlo) | (mhi[j] & thi);
                                pm[j] |= (z == 0 ? 1u : 0u) << i;
                            }
                        }
                    } else {
                        u32 bit = 1;
                        for (u32 jt = jc; jt < nt; jt++) {
                            u64 tm = t_m[jt];
                            u32 tlo = (u32)tm, thi = (u32)(tm >> 32);
#pragma unroll
                            for (int j = 0; j < EPT; j++) {
                                u32 z = (mlo[j] & tlo) | (mhi[j] & thi);
                                pm[j] |= z == 0 ? bit : 0u;
                            }
                            bit <<= 1;
                        }
                    }
#else
                    const u32 cend = min(jc + 32, nt);
                    u32 bit = 1;
                    for (u32 jt = jc; jt < cend; jt++) {
                        u32 tlo = t_lo[jt], thi = t_hi[jt];
#pragma unroll
                        for (int j = 0; j < EPT; j++) {
                            u32 z = (mlo[j] & tlo) | (mhi[j] & thi);
                            pm[j] |= z == 0 ? bit : 0u;
                        }
                        bit <<= 1;
                    }
#endif
#pragma unroll
                    for (int j = 0; j < EPT; j++) {
                        u32 x = pm[j] & vv[j];
                        u32 r0 = rr[j];
#ifdef WALK_KEEP
                        // The pairs inside their top's interval, found with no
                        // atomic in the loop (ptxas puts a YIELD in a loop with
                        // atomics for sm_70+ targets), then staged with one
                        // atomic for all of them.
                        u32 keep = 0;
                        while (x != 0) {
                            u32 b = __ffs(x) - 1;
                            x &= x - 1;
                            if (r0 >= t_rlo[jc + b] && r0 < t_rhi[jc + b]) {
                                keep |= 1u << b;
                            }
                        }
                        if (keep != 0) {
                            u32 n = __popc(keep);
                            u32 at = atomicAdd(&s_cnt, n);
                            if (at + n <= SURV_SH_CAP) {
                                while (keep != 0) {
                                    u32 b = __ffs(keep) - 1;
                                    keep &= keep - 1;
                                    s_t[at] = t_id[jc + b];
                                    s_r[at] = r0;
                                    at++;
                                }
                            } else {
                                // The stage is full: what fits there, the rest
                                // straight to the output, untested.
                                while (keep != 0) {
                                    u32 b = __ffs(keep) - 1;
                                    keep &= keep - 1;
                                    if (at < SURV_SH_CAP) {
                                        s_t[at] = t_id[jc + b];
                                        s_r[at] = r0;
                                    } else {
                                        u32 g = atomicAdd(surv_count, 1u);
                                        if (g < surv_cap) {
                                            surv[2 * g] = t_id[jc + b];
                                            surv[2 * g + 1] = r0;
                                        }
                                    }
                                    at++;
                                }
                            }
                        }
#elif defined(WALK_INLINE2)
                        // The first two set bits inline (no loop, so no YIELD for
                        // sm_70+ targets); the loop only for chunks with more.
#pragma unroll
                        for (int k = 0; k < 2; k++) {
                            if (x != 0) {
                                u32 jt2 = jc + (__ffs(x) - 1);
                                x &= x - 1;
                                if (r0 >= t_rlo[jt2] && r0 < t_rhi[jt2]) {
                                    stage(t_id[jt2], r0, &s_cnt, s_t, s_r, surv, surv_count,
                                          surv_cap);
                                }
                            }
                        }
                        while (x != 0) {
                            u32 jt2 = jc + (__ffs(x) - 1);
                            x &= x - 1;
                            if (r0 >= t_rlo[jt2] && r0 < t_rhi[jt2]) {
                                stage(t_id[jt2], r0, &s_cnt, s_t, s_r, surv, surv_count, surv_cap);
                            }
                        }
#elif defined(WALK_SYNCWARP)
                        while (__any_sync(0xffffffffu, x != 0)) {
                            if (x != 0) {
                                u32 jt2 = jc + (__ffs(x) - 1);
                                x &= x - 1;
                                if (r0 >= t_rlo[jt2] && r0 < t_rhi[jt2]) {
                                    stage(t_id[jt2], r0, &s_cnt, s_t, s_r, surv, surv_count,
                                          surv_cap);
                                }
                            }
                            __syncwarp();
                        }
#elif defined(WALK_ANY)
                        // A warp-uniform exit: while any lane has a bit left,
                        // each lane takes at most one. ptxas puts a YIELD in a
                        // loop whose exit diverges (sm_70+ targets), not in
                        // this one.
                        while (__any_sync(0xffffffffu, x != 0)) {
                            if (x != 0) {
                                u32 jt2 = jc + (__ffs(x) - 1);
                                x &= x - 1;
                                if (r0 >= t_rlo[jt2] && r0 < t_rhi[jt2]) {
                                    stage(t_id[jt2], r0, &s_cnt, s_t, s_r, surv, surv_count,
                                          surv_cap);
                                }
                            }
                        }
#else
                        while (x != 0) {
                            u32 jt2 = jc + (__ffs(x) - 1);
                            x &= x - 1;
                            if (r0 >= t_rlo[jt2] && r0 < t_rhi[jt2]) {
                                stage(t_id[jt2], r0, &s_cnt, s_t, s_r, surv, surv_count, surv_cap);
                            }
                        }
#endif
                    }
                }
                __syncthreads();
                const u32 sc = s_cnt;
                if (sc >= SURV_FLUSH) {
                    flush_survivors(s_t, s_r, &s_cnt, &s_base, warp_tot, top_m, top_x, surv,
                                    surv_count, staged, surv_cap, sc);
                    __syncthreads();
                }
            }
            __syncthreads();
        }
    }
    __syncthreads();
    const u32 sc = s_cnt;
    if (sc > 0) {
        flush_survivors(s_t, s_r, &s_cnt, &s_base, warp_tot, top_m, top_x, surv, surv_count,
                        staged, surv_cap, sc);
    }
}
