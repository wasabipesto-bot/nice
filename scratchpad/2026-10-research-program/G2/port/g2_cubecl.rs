//! G2 transversal join, kernel v10 of `scratchpad/2026-10-research-program/G2/bench/g2bench.cu`, ported to CubeCL
//! (scratch; local branch `g2-cubecl-local`, never pushed). One base-64 super-unit (digits 4..8 = π′, all 64 units
//! of digit 9), shape (f0 4, k 10).
//!
//! The host builds what the CUDA prep built (depth-4 roots, the super-unit's parents, the 8-bit key, a stable sort by
//! (class, key)); the GPU runs the main kernel over a list of (class, unit) jobs. Survivors leave the kernel as one
//! 16-byte record per nonzero 64-pair word (unit << 16 | probe slot, first parent of the chunk, word lo, word hi) in
//! plane-private slabs; the host expands them and checks every job's survivor set against the prototype's (the
//! staged `surv.bin`, filtered to the job's parent classes) and the counts against a CPU reference with the same
//! chunking.
//!
//! Plane width `W` is a comptime parameter (8 on lavapipe, 32 on CUDA, 64 on RDNA4), checked against `PLANE_DIM`
//! and the unit-to-lane mapping at run time (Vulkan does not promise full planes; this benchmark assumes them and
//! counts any violation). Only phase 2's slice stores depend on W: W >= 32 stores whole ballot words; W < 32 ORs
//! W-bit segments into an atomic staging array first.
//!
//! usage: g2_cubecl DIR [--jobs all | --jobs C0-C1:D0-D1] [--reps N] [--modes 0,1,2] [--noout] [--cpu-full]
#![allow(
    clippy::cast_possible_truncation,
    clippy::cast_possible_wrap,
    clippy::cast_lossless,
    clippy::too_many_arguments,
    clippy::too_many_lines,
    clippy::similar_names,
    clippy::many_single_char_names,
    clippy::needless_range_loop,
    clippy::unreadable_literal,
    clippy::collapsible_if,
    clippy::collapsible_else_if,
    clippy::manual_is_multiple_of,
    clippy::trivially_copy_pass_by_ref
)]

use anyhow::{Result, anyhow, bail};
use cubecl::prelude::*;
use nice_common::cubecl_backend::CubeclContext;
use std::time::Instant;

const M: u32 = 63;
const NROOT: usize = 8;
const ROOTS: [u32; NROOT] = [0, 6, 21, 27, 35, 42, 48, 62];
const MASK60: u64 = (1u64 << 60) - 1;
/// Threads per cube.
const NT: u32 = 256;
/// Children per round: 16 full chunks.
const FILL: u32 = 1024;
/// Probe table rows (this super-unit's max is 561; the second's 535).
const PMAX: u32 = 576;
/// Max top-mask popcount at b64 f0 4.
const MAXPOP: u32 = 17;
/// Records per plane-private output slab.
const SLAB: u32 = 256;
/// Slice words in shared memory: 16 chunks x 64 digits x 2 halves at row stride 65 (65 x 15 + 64 rows of 2 words).
const SLW: u32 = 2080;
/// Counter layout: 64 units x 5 (children, chunks, flat, kept, surv), then extras.
const C_LSLOTS: usize = 320;
const C_ERR_PLANE: usize = 321;
const C_ERR_PMAX: usize = 322;
const C_ERR_SLAB: usize = 323;
const NCNT: usize = 328;

// ------------------------------------------------------------------------------------------------ device
mod kernels {
    use super::{C_ERR_PLANE, C_ERR_PMAX, C_ERR_SLAB, C_LSLOTS, M, MAXPOP, NT, PMAX, SLAB, SLW};
    use cubecl::prelude::*;

    /// Bits of a u64 whose index has bit j set (the shuffle transpose's stage-j mask; j < 64, a power of two).
    pub const fn stage_mask(j: u32) -> u64 {
        let mut m = 0u64;
        let mut b = 0;
        while b < 64 {
            if b & j != 0 {
                m |= 1u64 << b;
            }
            b += 1;
        }
        m
    }

    /// Exclusive rank of this lane's flag in its plane: a ballot and population counts (ranks 1), or the plane scan
    /// (ranks 0; CubeCL lowers it to shuffle loops on CUDA). The ballot's second word only when W = 64.
    #[cube]
    fn plane_rank(flag: bool, f: u32, #[comptime] w: u32, #[comptime] ranks: u32) -> u32 {
        let mut r = 0u32;
        if comptime!(ranks == 0) {
            r = plane_exclusive_sum(f);
        } else {
            let b = plane_ballot(flag);
            let l = UNIT_POS_PLANE;
            let lo = select(l >= 32u32, 0xFFFF_FFFFu32, (1u32 << min(l, 31u32)) - 1u32);
            r = (b[0usize] & lo).count_ones();
            if comptime!(w > 32) {
                let hi = select(l >= 32u32, (1u32 << (l & 31u32)) - 1u32, 0u32);
                r += (b[1usize] & hi).count_ones();
            }
        }
        r
    }

    /// plane_rank (ranks 1) with the lane's masks below it made once, outside the loop: ACO recomputed them in every
    /// 3b step. (lo, hi) = (rank_masks().0, rank_masks().1).
    #[cube]
    fn plane_rank_m(flag: bool, lo: u32, hi: u32, #[comptime] w: u32) -> u32 {
        let b = plane_ballot(flag);
        let mut r = (b[0usize] & lo).count_ones();
        if comptime!(w > 32) {
            r += (b[1usize] & hi).count_ones();
        }
        r
    }

    #[cube]
    fn plane_count(flag: bool, f: u32, #[comptime] w: u32, #[comptime] ranks: u32) -> u32 {
        let mut n = 0u32;
        if comptime!(ranks == 0) {
            n = plane_sum(f);
        } else {
            let b = plane_ballot(flag);
            n = b[0usize].count_ones();
            if comptime!(w > 32) {
                n += b[1usize].count_ones();
            }
        }
        n
    }

    #[cube]
    fn child_mask(pm: u64, cacc: u32, d: u32) -> u64 {
        // d & 63 (d < 64 anyway): both factors < 64, so ACO emits a full-rate 24-bit multiply, not v_mul_lo_u32
        let d6 = d & 63u32;
        let e2 = ((cacc & 63u32) + ((cacc >> 16u32) & 63u32) * d6) & 63u32;
        let e3 = (((cacc >> 8u32) & 63u32) + ((cacc >> 24u32) & 63u32) * d6) & 63u32;
        let add = (1u64 << u64::cast_from(e2)) | (1u64 << u64::cast_from(e3));
        let mut out = pm | add;
        if e2 == e3 || (pm & add) != 0u64 {
            out = 0u64;
        }
        out
    }

    /// One cube per job (class c, unit d). MODE 0: bottom side only; 1: skip off; 2: full.
    #[cube(launch_unchecked)]
    pub fn g2_kernel(
        par: &Array<Vector<u32, Const<4>>>, // parent records (mask lo, mask hi, cacc, r4), one 16-byte vector each (one LDG.128 on CUDA)
        pseg: &Array<u32>,
        tmask: &Array<u64>, // the tops' masks (only for --tdig 0: digits made in every cube, as before the fixes)
        tdig: &Array<u32>, // each top's digits, 20 6-bit fields in 4 words (`tdig_kernel`), computed once per super-unit
        tseg: &Array<u32>,
        roots: &Array<u32>,
        jobs: &Array<u32>,
        cnt: &mut Array<Atomic<u32>>,
        out: &mut Array<Vector<u32, Const<4>>>, // survivor records, one 16-byte vector each (one STG.128 on CUDA)
        slabn: &mut Array<Atomic<u32>>,
        slabcnt: &mut Array<u32>,
        nslab_cap: u32,
        #[comptime] mode: u32,
        #[comptime] noout: bool,
        #[comptime] w: u32,
        #[comptime] fill: u32,
        #[comptime] xpose: u32,
        #[comptime] ept: u32,
        #[comptime] ranks: u32,
        #[comptime] cut: u32,
        #[comptime] cmask: u32,
        #[comptime] tdg: u32,
    ) {
        let npl = comptime!(NT / w);
        let segs = comptime!(64 / w); // ballot segments per chunk (W <= 64)
        // pending children as u16 (parent index - class start) two per word, and the round's probe list (u32
        // entries) in the same words: the list is live only in 3a/3b, when the pending slots still needed (each
        // chunk's first, the carried rest) are already in registers. 12 waves per SIMD on RDNA4 need <= 21 KB.
        let mut pq = SharedMemory::<u32>::new(comptime!((if (fill + NT) / 2 > PMAX + 32 { (fill + NT) / 2 } else { PMAX + 64 }) as usize));
        // slices [(v + 65 q)*2 + half] (SROW = 65: the 3b address is one add and one shift of the digit, and a 16-lane group's
        // reads still fall on 16 distinct 8-byte bank pairs, (v + q) mod 16)
        let mut sl = SharedMemory::<u32>::new(comptime!((SLW) as usize));
        // every shared array a multiple of 128 bytes, so that every array starts 128-byte aligned whatever order
        // CubeCL places them in (its placement changed per build, and the full kernel's time with it)
        let slt = SharedMemory::<Atomic<u32>>::new(comptime!((if w < 32 { SLW } else { 32 }) as usize));
        let comm = SharedMemory::<Atomic<u32>>::new(32usize); // [2q + half]
        // each probe's 4 digit words as one 16-byte vector (one LDS.128 / ds_read_b128 per list entry)
        let mut prob_d = SharedMemory::<Vector<u32, Const<4>>>::new(comptime!(PMAX as usize));
        let mut wcnt = SharedMemory::<u32>::new(comptime!((if 2 * NT / w < 32 { 32 } else { 2 * NT / w }) as usize));
        let s_nl = SharedMemory::<Atomic<u32>>::new(32usize);
        let mut s_np = SharedMemory::<u32>::new(32usize);
        let mut cmv = SharedMemory::<u32>::new(64usize);

        let t = UNIT_POS_X;
        let lane = UNIT_POS_PLANE;
        // the plane's index as a uniform value (a reduction of lane 0's), so that ACO keeps it, the phase 1 offsets
        // and the phase 2 task numbers in scalar registers
        let pl = plane_sum(select(lane == 0u32, t / w, 0u32));
        // each lane's ballot masks below it, for the ordered compaction and the record ranks (made once)
        let rl = UNIT_POS_PLANE;
        let rlo = select(rl >= 32u32, 0xFFFF_FFFFu32, (1u32 << min(rl, 31u32)) - 1u32);
        let rhi = select(rl >= 32u32, (1u32 << (rl & 31u32)) - 1u32, 0u32);
        let c = jobs[(2u32 * CUBE_POS_X) as usize];
        let d = jobs[(2u32 * CUBE_POS_X + 1u32) as usize];
        let cc = (c + d) % M;

        if PLANE_DIM != w || t % w != lane {
            cnt[C_ERR_PLANE].fetch_add(1u32);
        }
        if comptime!(mode == 0) {
            // lane map of cube 0, for the host's --debug-lanes (mode 0 writes no records)
            if CUBE_POS_X == 0u32 {
                let mut lv = Vector::<u32, Const<4>>::empty();
                lv[0usize] = t;
                lv[1usize] = lane;
                lv[2usize] = PLANE_DIM;
                lv[3usize] = plane_sum(1u32);
                out[t as usize] = lv;
            }
        }
        if t == 0u32 {
            let mut n = 0u32;
            for i in 0..8u32 {
                let ct = (roots[i as usize] + M - cc) % M;
                let s = (d * M + ct) * 2u32;
                n += tseg[(s + 1u32) as usize] - tseg[s as usize];
            }
            s_np[0usize] = n;
            s_nl[0usize].store(0u32);
            if n > PMAX {
                cnt[C_ERR_PMAX].fetch_add(1u32);
            }
        }
        if t < 32u32 {
            comm[t as usize].store(comptime!(if xpose == 0 || cmask == 0 { 0u32 } else { u32::MAX }));
        }
        sync_cube();
        // probes: the 8 compatible top classes of unit d, each probe's digits as 20 6-bit fields (5 per word),
        // padded with its first digit (OR is idempotent)
        if comptime!(cut & 4 == 0) {
        let mut base = 0u32;
        for i in 0..8u32 {
            let ct = (roots[i as usize] + M - cc) % M;
            let s = (d * M + ct) * 2u32;
            let b0 = tseg[s as usize];
            let b1 = tseg[(s + 1u32) as usize];
            let mut j = t;
            while j < b1 - b0 {
                if base + j < PMAX {
                    if comptime!(tdg == 1) {
                        let mut pv = Vector::<u32, Const<4>>::empty();
                        #[unroll]
                        for k in 0..4u32 {
                            pv[k as usize] = tdig[((b0 + j) * 4u32 + k) as usize];
                        }
                        prob_d[(base + j) as usize] = pv;
                    } else {
                        let mut x = tmask[(b0 + j) as usize];
                        let first = x.trailing_zeros();
                        let mut dw = Array::<u32>::new(4usize);
                        #[unroll]
                        for k in 0..4u32 {
                            dw[k as usize] = 0u32;
                        }
                        #[unroll]
                        for k in 0..20u32 {
                            let v = select(x != 0u64, x.trailing_zeros(), first);
                            x &= x - select(x != 0u64, 1u64, 0u64);
                            dw[comptime!(k / 5) as usize] |= v << comptime!(6 * (k % 5));
                        }
                        let mut pv = Vector::<u32, Const<4>>::empty();
                        #[unroll]
                        for k in 0..4u32 {
                            pv[k as usize] = dw[k as usize];
                        }
                        prob_d[(base + j) as usize] = pv;
                    }
                }
                j += NT;
            }
            base += b1 - b0;
        }
        }
        sync_cube();
        let nprobe = min(s_np[0usize], PMAX);

        let mut my_kept = 0u32;
        let mut my_surv = 0u32;
        let mut my_children = 0u32;
        let mut my_chunks = 0u32;
        let mut my_flat = 0u32;
        let mut my_lslots = 0u32;
        let mut slab_id = 0u32;
        let mut slab_used = 256u32; // = SLAB (a literal: a const would be a comptime value); full: the first record allocates
        let mut have_slab = false;

        let pb = pseg[c as usize];
        let pe = pseg[(c + 1u32) as usize];
        let mut cur = pb;
        let mut npend = 0u32;
        let mut parity = 0u32;
        // no `loop`/`break`: cubecl-spirv 0.10 emitted a conditional branch without OpSelectionMerge for them
        let mut going = true;
        // a pending slot with odd index is ORed into its word after the next barrier (its even neighbour is written
        // by another lane, in this step or an earlier one); no atomics, no extra barrier per step
        let mut dsl = 0u32;
        let mut dv = 0u32;
        let mut dhave = false;
        let mut keep = 0u32;
        while going {
            // phase 1: append children of NT parents at a time (ordered) until 16 chunks are pending or the class ends
            while npend < fill && cur < pe {
                let idx = cur + t;
                let mut m = 0u64;
                if idx < pe {
                    let pv = par[idx as usize];
                    m = child_mask(u64::cast_from(pv[0usize]) | (u64::cast_from(pv[1usize]) << 32u64), pv[2usize], d);
                }
                let f = select(m != 0u64, 1u32, 0u32);
                let mut r = 0u32;
                if comptime!(ranks == 0) {
                    r = plane_rank(m != 0u64, f, w, ranks);
                } else {
                    r = plane_rank_m(m != 0u64, rlo, rhi, w);
                }
                let tot = plane_count(m != 0u64, f, w, ranks);
                if lane == 0u32 {
                    wcnt[(parity * npl + pl) as usize] = tot;
                }
                sync_cube();
                if dhave {
                    pq[dsl as usize] = pq[dsl as usize] | (dv << 16u32);
                    dhave = false;
                }
                let mut off = 0u32;
                let mut all = 0u32;
                for i in 0..npl {
                    let x = wcnt[(parity * npl + i) as usize];
                    off += select(i < pl, x, 0u32);
                    all += x;
                }
                if m != 0u64 {
                    let sl16 = npend + off + r;
                    if (sl16 & 1u32) == 0u32 {
                        pq[(sl16 >> 1u32) as usize] = idx - pb;
                    } else {
                        dsl = sl16 >> 1u32;
                        dv = idx - pb;
                        dhave = true;
                    }
                }
                npend += all;
                parity ^= 1u32;
                cur += NT;
            }
            sync_cube();
            if dhave {
                pq[dsl as usize] = pq[dsl as usize] | (dv << 16u32);
                dhave = false;
            }
            sync_cube();
            let done = cur >= pe;
            let nch = min(comptime!(fill / 64), select(done, (npend + 63u32) / 64u32, 64u32));
            if nch == 0u32 {
                going = false;
            } else {
                let ntake = min(npend, nch * 64u32);
                if comptime!(w < 32) {
                    let mut z = t;
                    while z < 2080u32 {
                        slt[z as usize].store(0u32);
                        z += NT;
                    }
                    sync_cube();
                }
                if comptime!(cut & 1 == 0) {
                // phase 2: transpose by ballots. Plane task i covers chunk q, segment s (members s*W .. s*W+W-1).
                for i in 0..4u32 {
                    let task = pl + npl * i;
                    let q = task / segs;
                    let sg = task % segs;
                    let mi = q * 64u32 + sg * w + lane;
                    let mut m = 0u64;
                    if q < nch && mi < ntake {
                        let pi = pb + ((pq[(mi >> 1u32) as usize] >> ((mi & 1u32) << 4u32)) & 0xFFFFu32);
                        let pv = par[pi as usize];
                        m = child_mask(u64::cast_from(pv[0usize]) | (u64::cast_from(pv[1usize]) << 32u64), pv[2usize], d);
                    }
                    if comptime!(xpose == 0) {
                        for v in 0..64u32 {
                            let bal = plane_ballot(((m >> u64::cast_from(v)) & 1u64) != 0u64);
                            if lane == v % w && q < nch {
                                let row = (v + 65u32 * q) * 2u32;
                                if comptime!(w == 64) {
                                    sl[row as usize] = bal[0usize];
                                    sl[(row + 1u32) as usize] = bal[1usize];
                                } else if comptime!(w == 32) {
                                    sl[(row + sg) as usize] = bal[0usize];
                                } else {
                                    let bit = sg * w;
                                    let seg = bal[0usize] & comptime!((1u32 << w) - 1);
                                    slt[(row + bit / 32u32) as usize].fetch_or(seg << (bit % 32u32));
                                }
                            }
                        }
                    } else {
                        // shuffle transpose: the plane's W rows, as 64/W blocks of W x W bits, each transposed in
                        // log2(W) shuffle_xor stages on the whole u64 (the stage masks are the same per block);
                        // lane l then holds, in block s, column s*W + l over this plane's rows.
                        // on the two 32-bit halves (ACO paid a v_lshlrev_b64 and two ORs per stage to rebuild the u64):
                        // for j < 32 the stage moves bits within each half, and (y >> j) & !mj, (y << j) & mj are a
                        // 32-bit rotation right by j or by 32 - j, masked: one v_alignbit and one v_bfi per half;
                        // j = 32 (W = 64) swaps halves between the lane pairs
                        let mut xl = u32::cast_from(m & 0xFFFF_FFFFu64);
                        let mut xh = u32::cast_from(m >> 32u64);
                        #[unroll]
                        for st in 0..comptime!(w.trailing_zeros()) {
                            let j = comptime!(w >> (st + 1));
                            let yl = plane_shuffle_xor(xl, j);
                            let yh = plane_shuffle_xor(xh, j);
                            let hit = (lane & j) != 0u32;
                            if comptime!(j == 32) {
                                xl = select(hit, yh, xl);
                                xh = select(hit, xh, yl);
                            } else {
                                let mj = comptime!(stage_mask(w >> (st + 1)) as u32);
                                let keep = select(hit, mj, !mj);
                                let sr = select(hit, j, 32u32 - j);
                                let rl = (yl >> sr) | (yl << (32u32 - sr));
                                let rh = (yh >> sr) | (yh << (32u32 - sr));
                                xl = (xl & keep) | (rl & !keep);
                                xh = (xh & keep) | (rh & !keep);
                            }
                        }
                        if comptime!(cmask == 1) {
                        if q < nch {
                            // common masks from the registers (no pass over the slices): digit v is common to the
                            // chunk iff, in every plane of it, the column holds all of that plane's valid rows
                            let nv = min(w, ntake - min(ntake, q * 64u32 + sg * w));
                            // valid rows as a u64, built from u32 shifts (a variable 64-bit shift crashed lavapipe's
                            // 512-bit JIT)
                            let vlo = select(nv >= 32u32, 0xFFFF_FFFFu32, (1u32 << min(nv, 31u32)) - 1u32);
                            let vhi = select(nv >= 64u32, 0xFFFF_FFFFu32, select(nv > 32u32, (1u32 << ((nv - min(nv, 32u32)) & 31u32)) - 1u32, 0u32));
                            #[unroll]
                            for sb in 0..segs {
                                // this segment's column piece (W bits), from the half that holds it
                                let mut hv = xh;
                                if comptime!(sb * w < 32) {
                                    hv = xl;
                                }
                                let mut eq = false;
                                if comptime!(w == 64) {
                                    eq = xl == vlo && xh == vhi;
                                } else if comptime!(w == 32) {
                                    eq = hv == vlo;
                                } else {
                                    eq = ((hv >> comptime!((sb * w) % 32)) & comptime!((1u32 << w) - 1)) == vlo;
                                }
                                let bal = plane_ballot(eq);
                                if lane == 0u32 {
                                    if comptime!(w == 64) {
                                        comm[(2u32 * q) as usize].fetch_and(bal[0usize]);
                                        comm[(2u32 * q + 1u32) as usize].fetch_and(bal[1usize]);
                                    } else if comptime!(w == 32) {
                                        comm[(2u32 * q + comptime!(sb)) as usize].fetch_and(bal[0usize]);
                                    } else {
                                        let wm = comptime!((1u32 << w) - 1);
                                        let sh = comptime!((sb * w) % 32);
                                        comm[(2u32 * q + comptime!((sb * w) / 32)) as usize].fetch_and(!(wm << sh) | ((bal[0usize] & wm) << sh));
                                    }
                                }
                            }
                        }
                        }
                        if q < nch {
                            #[unroll]
                            for sb in 0..segs {
                                let v = comptime!(sb * w) + lane;
                                let row = (v + 65u32 * q) * 2u32;
                                let mut hv = xh;
                                if comptime!(sb * w < 32) {
                                    hv = xl;
                                }
                                if comptime!(w == 64) {
                                    sl[row as usize] = xl;
                                    sl[(row + 1u32) as usize] = xh;
                                } else if comptime!(w == 32) {
                                    sl[(row + sg) as usize] = hv;
                                } else {
                                    let bit = sg * w;
                                    let piece = (hv >> comptime!((sb * w) % 32)) & comptime!((1u32 << w) - 1);
                                    slt[(row + bit / 32u32) as usize].fetch_or(piece << (bit % 32u32));
                                }
                            }
                        }
                    }
                }
                }
                // the pending slots needed after phase 2 (the carried rest; each chunk's first parent for the records)
                // into registers: 3a overwrites the words with the probe list
                let left0 = npend - ntake;
                keep = 0u32;
                if t < left0 {
                    let s16 = ntake + t;
                    keep = (pq[(s16 >> 1u32) as usize] >> ((s16 & 1u32) << 4u32)) & 0xFFFFu32;
                }
                let s0 = min((t % 16u32) * 64u32, comptime!(fill + NT - 1));
                let pend0 = pb + ((pq[(s0 >> 1u32) as usize] >> ((s0 & 1u32) << 4u32)) & 0xFFFFu32);
                sync_cube();
                if comptime!(w < 32) {
                    let mut z = t;
                    while z < 2080u32 {
                        sl[z as usize] = slt[z as usize].load();
                        z += NT;
                    }
                    sync_cube();
                }
                if comptime!(cut & 2 == 0 && (xpose == 0 || cmask == 0)) {
                // common masks (ballot transpose only): digit v is common to chunk q iff its slice equals the chunk's valid mask
                {
                    let mut j = t;
                    while j < 1024u32 {
                        let q = j / 64u32;
                        let v = j % 64u32;
                        if q < nch {
                            let nq = min(64u32, ntake - q * 64u32);
                            let vlo = select(nq >= 32u32, 0xFFFF_FFFFu32, (1u32 << (nq % 32u32)) - 1u32);
                            let vhi = select(nq == 64u32, 0xFFFF_FFFFu32, select(nq > 32u32, (1u32 << (nq % 32u32)) - 1u32, 0u32));
                            let row = (v + 65u32 * q) * 2u32;
                            if sl[row as usize] == vlo && sl[(row + 1u32) as usize] == vhi {
                                comm[(2u32 * q + v / 32u32) as usize].fetch_or(1u32 << (v % 32u32));
                            }
                        }
                        j += NT;
                    }
                }
                }
                sync_cube();
                if comptime!(mode == 2) {
                    // the common masks per digit: cmv[v] bit q = digit v is common to chunk q (one wave, once per
                    // round), so that 3a ORs one word per probe digit instead of testing every chunk's two words
                    if t < 64u32 {
                        let mut cmk = 0u32;
                        for qq in 0..nch {
                            let wv = comm[(2u32 * qq + t / 32u32) as usize].load();
                            cmk |= ((wv >> (t % 32u32)) & 1u32) << qq;
                        }
                        cmv[t as usize] = cmk;
                    }
                    sync_cube();
                }
                if comptime!(mode != 0) {
                    // phase 3a: per probe, its 16-bit mask of chunks kept by the common-mask skip -> list
                    let allq = (1u32 << nch) - 1u32; // nch <= 16
                    let mut pp = t;
                    while pp < nprobe {
                        let mut km = allq;
                        if comptime!(mode == 2) {
                            let mut hitm = 0u32;
                            let pv = prob_d[pp as usize];
                            #[unroll]
                            for k in 0..MAXPOP {
                                let dg = (pv[comptime!(k / 5) as usize] >> comptime!(6 * (k % 5))) & 63u32;
                                hitm |= cmv[dg as usize];
                            }
                            km = allq & !hitm;
                        }
                        my_kept += km.count_ones();
                        if km != 0u32 {
                            let slot = s_nl[0usize].fetch_add(1u32);
                            pq[slot as usize] = (pp * 16u32) | (km << 16u32); // the probe's byte offset in prob_d: no shift in 3b
                        }
                        pp += NT;
                    }
                    sync_cube();
                    let nlist = s_nl[0usize].load();
                    // phase 3b: lane = chunk (q = t % 16), 16 probe streams, two list entries per unit per step
                    let q = t % 16u32;
                    let st = t / 16u32;
                    let nq = select(q < nch, min(64u32, ntake - min(ntake, q * 64u32)), 0u32);
                    let vlo = select(nq >= 32u32, 0xFFFF_FFFFu32, (1u32 << (nq % 32u32)) - 1u32);
                    let vhi = select(nq == 64u32, 0xFFFF_FFFFu32, select(nq > 32u32, (1u32 << (nq % 32u32)) - 1u32, 0u32));
                    let q65 = 65u32 * q;
                    let qs = 16u32 + q;
                    let mut e0 = 0u32;
                    while e0 < nlist {
                        let mut wlo = Array::<u32>::new(2usize);
                        let mut whi = Array::<u32>::new(2usize);
                        let mut pk = Array::<u32>::new(2usize);
                        #[unroll]
                        for h0 in 0..2u32 {
                            wlo[h0 as usize] = 0u32;
                            whi[h0 as usize] = 0u32;
                            pk[h0 as usize] = 0u32;
                        }
                        #[unroll]
                        for h in 0..ept {
                            // branch-free: an entry past the list reads as 0 (probe 0, no chunk kept), and a lane whose
                            // chunk is not kept computes its word and masks it (a wave skipped only when all 64 lanes
                            // were idle, which is rare; the branches cost more than they saved). e < nlist + 31 <= pq's size.
                            let e = e0 + st + comptime!(16 * h);
                            let ent = select(e < nlist, pq[e as usize], 0u32);
                            let p16 = ent & 0xFFFFu32;
                            pk[h as usize] = p16;
                            let kmask = 0u32 - ((ent >> qs) & 1u32);
                            let mut alo = 0u32;
                            let mut ahi = 0u32;
                            let dws = prob_d[(p16 >> 4u32) as usize];
                            #[unroll]
                            for k in 0..MAXPOP {
                                let dg = (dws[comptime!(k / 5) as usize] >> comptime!(6 * (k % 5))) & 63u32;
                                let row = (dg + q65) * 2u32;
                                alo |= sl[row as usize];
                                ahi |= sl[(row + 1u32) as usize];
                            }
                            wlo[h as usize] = !alo & vlo & kmask;
                            whi[h as usize] = !ahi & vhi & kmask;
                        }
                        if t == 0u32 {
                            my_lslots += min(comptime!(16 * ept), nlist - e0) * nch;
                        }
                        let nza = (wlo[0usize] | whi[0usize]) != 0u32;
                        let nzb = (wlo[1usize] | whi[1usize]) != 0u32;
                        if comptime!(noout) {
                            my_surv += wlo[0usize].count_ones() + whi[0usize].count_ones() + wlo[1usize].count_ones() + whi[1usize].count_ones();
                        } else {
                            let fa = select(nza, 1u32, 0u32);
                            let fb = select(nzb, 1u32, 0u32);
                            let na = plane_count(nza, fa, w, ranks);
                            let nn = na + plane_count(nzb, fb, w, ranks);
                            let mut ra = 0u32;
                            let mut rb = 0u32;
                            if comptime!(ranks == 0) {
                                ra = plane_rank(nza, fa, w, ranks);
                                rb = plane_rank(nzb, fb, w, ranks);
                            } else {
                                ra = plane_rank_m(nza, rlo, rhi, w);
                                rb = plane_rank_m(nzb, rlo, rhi, w);
                            }
                            if nn > 0u32 {
                                if slab_used + nn > SLAB {
                                    if lane == 0u32 && have_slab {
                                        slabcnt[slab_id as usize] = slab_used;
                                    }
                                    let mut sid = 0u32;
                                    if lane == 0u32 {
                                        sid = slabn[0usize].fetch_add(1u32);
                                    }
                                    slab_id = plane_sum(sid); // only lane 0 holds it
                                    slab_used = 0u32;
                                    have_slab = true;
                                    if slab_id >= nslab_cap && lane == 0u32 {
                                        cnt[C_ERR_SLAB].fetch_add(1u32);
                                    }
                                }
                                let sbase = slab_id * SLAB + slab_used;
                                if slab_id < nslab_cap {
                                    if nza {
                                        let mut rv = Vector::<u32, Const<4>>::empty();
                                        rv[0usize] = (pk[0usize] >> 4u32) | (d << 16u32);
                                        rv[1usize] = pend0;
                                        rv[2usize] = wlo[0usize];
                                        rv[3usize] = whi[0usize];
                                        out[(sbase + ra) as usize] = rv;
                                    }
                                    if nzb {
                                        let mut rv = Vector::<u32, Const<4>>::empty();
                                        rv[0usize] = (pk[1usize] >> 4u32) | (d << 16u32);
                                        rv[1usize] = pend0;
                                        rv[2usize] = wlo[1usize];
                                        rv[3usize] = whi[1usize];
                                        out[(sbase + na + rb) as usize] = rv;
                                    }
                                }
                                my_surv += wlo[0usize].count_ones() + whi[0usize].count_ones() + wlo[1usize].count_ones() + whi[1usize].count_ones();
                                slab_used += nn;
                            }
                        }
                        e0 += comptime!(16 * ept);
                    }
                    if t == 0u32 {
                        my_flat += nprobe * nch;
                    }
                }
                if t == 0u32 {
                    my_chunks += nch;
                    my_children += ntake;
                }
                sync_cube();
                // phase 4: carry the rest (< NT) to the front; reset the round's list and common masks
                let left = npend - ntake;
                // slots t and t + 1 are lanes l and l ^ 1 of one plane: one store per word
                let nb = plane_shuffle_xor(keep, 1u32);
                if t < left && (t & 1u32) == 0u32 {
                    pq[(t >> 1u32) as usize] = keep | select(t + 1u32 < left, nb << 16u32, 0u32);
                }
                if t == 0u32 {
                    s_nl[0usize].store(0u32);
                }
                if t >= 32u32 && t < 64u32 {
                    comm[(t - 32u32) as usize].store(comptime!(if xpose == 0 || cmask == 0 { 0u32 } else { u32::MAX }));
                }
                npend = left;
                sync_cube();
                if done && left == 0u32 {
                    going = false;
                }
            }
        }
        if !comptime!(noout) {
            if lane == 0u32 && have_slab && slab_id < nslab_cap {
                slabcnt[slab_id as usize] = slab_used;
            }
        }
        let sk = plane_sum(my_kept);
        let ss = plane_sum(my_surv);
        if lane == 0u32 {
            if sk > 0u32 {
                cnt[(d * 5u32 + 3u32) as usize].fetch_add(sk);
            }
            if ss > 0u32 {
                cnt[(d * 5u32 + 4u32) as usize].fetch_add(ss);
            }
        }
        if t == 0u32 {
            cnt[(d * 5u32) as usize].fetch_add(my_children);
            cnt[(d * 5u32 + 1u32) as usize].fetch_add(my_chunks);
            cnt[(d * 5u32 + 2u32) as usize].fetch_add(my_flat);
            cnt[C_LSLOTS].fetch_add(my_lslots);
        }
    }
}


/// The per-super-unit preparation on the GPU: depth-4 roots (base-wide, uploaded once as r4 values) extended by π′'s
/// digits 4..8 to parents, then a counting sort by key = class·256 + (255 − key8): histogram, one-cube scan,
/// atomic scatter, and a per-bucket insertion sort by r4 that restores the CPU's stable order (parents are
/// generated in r4 order). Four launches.
mod prep {
    use cubecl::prelude::*;

    #[cube]
    fn dig(x: u64, #[comptime] j: u32) -> u32 {
        u32::cast_from((x >> comptime!(6 * j) as u64) & 63u64)
    }

    /// Digit j (6 bits) of a 60-bit value given as 32-bit halves (j comptime; digit 5 spans the halves).
    #[cube]
    fn dig2(lo: u32, hi: u32, #[comptime] j: u32) -> u32 {
        let mut v = 0u32;
        if comptime!(6 * j + 6 <= 32) {
            v = (lo >> comptime!(6 * j)) & 63u32;
        } else if comptime!(6 * j >= 32) {
            v = (hi >> comptime!(6 * j - 32)) & 63u32;
        } else {
            v = ((lo >> comptime!(6 * j)) | (hi << comptime!(32 - 6 * j))) & 63u32;
        }
        v
    }

    /// The parent of root r4 under π′ (pip): (mask, cacc, key), or mask 0 when a digit 0..8 repeats.
    /// (2026-11-18: digits from 32-bit halves; the 18 digits are distinct iff the mask has 18 bits, so no per-digit
    /// tests; r mod 63 = (r4 mod 63 + pip mod 63) mod 63, as 2^24 = 1 mod 63.)
    #[cube]
    fn parent(r4: u32, pip: u64, rank: &Array<u32>) -> (u64, u32, u32) {
        let mask60 = (1u64 << 60u64) - 1u64;
        let r = u64::cast_from(r4) + (pip << 24u64);
        let s = (r * r) & mask60;
        let c = (s * r) & mask60;
        let slo = u32::cast_from(s & 0xFFFF_FFFFu64);
        let shi = u32::cast_from(s >> 32u64);
        let clo = u32::cast_from(c & 0xFFFF_FFFFu64);
        let chi = u32::cast_from(c >> 32u64);
        let mut m = 0u64;
        #[unroll]
        for j in 0..9u32 {
            m |= (1u64 << u64::cast_from(dig2(slo, shi, j))) | (1u64 << u64::cast_from(dig2(clo, chi, j)));
        }
        let ok = m.count_ones() == 18u32;
        let r0 = r4 & 63u32;
        let cacc = dig2(slo, shi, 9u32) | (dig2(clo, chi, 9u32) << 8u32) | (((2u32 * r0) & 63u32) << 16u32) | (((3u32 * r0 * r0) & 63u32) << 24u32);
        // pip mod 63 from its halves (2^32 = 4 mod 63); uniform
        let pm63 = (u32::cast_from(pip >> 32u64) % 63u32 * 4u32 + u32::cast_from(pip & 0xFFFF_FFFFu64) % 63u32) % 63u32;
        let cls = (r4 % 63u32 + pm63) % 63u32;
        let mut k8 = 0u32;
        #[unroll]
        for i in 0..8u32 {
            k8 |= u32::cast_from((m >> u64::cast_from(rank[i as usize])) & 1u64) << comptime!(7 - i);
        }
        let key = cls * 256u32 + (255u32 - k8);
        let mut mm = m;
        if !ok {
            mm = 0u64;
        }
        (mm, cacc, key)
    }

    #[cube(launch_unchecked)]
    pub fn hist_kernel(r4s: &Array<u32>, rank: &Array<u32>, hist: &mut Array<Atomic<u32>>, nroots: u32, pip_lo: u32, pip_hi: u32) {
        let pip = u64::cast_from(pip_lo) | (u64::cast_from(pip_hi) << 32u64);
        let i = ABSOLUTE_POS_X;
        if i < nroots {
            let (m, _c, key) = parent(r4s[i as usize], pip, rank);
            if m != 0u64 {
                hist[key as usize].fetch_add(1u32);
            }
        }
    }

    /// --prep2 1 (default): the histogram pass also appends each parent's record and key to a compact list (one
    /// atomic per plane), so the scatter reads 1.04M list entries instead of making the parents of all 9.3M roots
    /// a second time. The list's order is arbitrary; the rank sort restores the CPU's order (ranks by r4).
    #[cube(launch_unchecked)]
    pub fn hist2_kernel(
        r4s: &Array<u32>,
        rank: &Array<u32>,
        hist: &mut Array<Atomic<u32>>,
        lst: &mut Array<Vector<u32, Const<4>>>,
        lkey: &mut Array<u32>,
        lcnt: &mut Array<Atomic<u32>>,
        nroots: u32,
        pip_lo: u32,
        pip_hi: u32,
        cap: u32,
        #[comptime] w: u32,
    ) {
        let pip = u64::cast_from(pip_lo) | (u64::cast_from(pip_hi) << 32u64);
        let i = ABSOLUTE_POS_X;
        let mut m = 0u64;
        let mut c = 0u32;
        let mut key = 0u32;
        let mut r4 = 0u32;
        if i < nroots {
            r4 = r4s[i as usize];
            let (mm, cc, kk) = parent(r4, pip, rank);
            m = mm;
            c = cc;
            key = kk;
        }
        let flag = m != 0u64;
        let b = plane_ballot(flag);
        let l = UNIT_POS_PLANE;
        let lo = select(l >= 32u32, 0xFFFF_FFFFu32, (1u32 << min(l, 31u32)) - 1u32);
        let mut r = (b[0usize] & lo).count_ones();
        let mut n = b[0usize].count_ones();
        if comptime!(w > 32) {
            let hi = select(l >= 32u32, (1u32 << (l & 31u32)) - 1u32, 0u32);
            r += (b[1usize] & hi).count_ones();
            n += b[1usize].count_ones();
        }
        let mut base0 = 0u32;
        if l == 0u32 && n > 0u32 {
            base0 = lcnt[0usize].fetch_add(n);
        }
        let base = plane_sum(base0); // only lane 0 holds it
        if flag {
            let slot = base + r;
            if slot < cap {
                let mut v = Vector::<u32, Const<4>>::empty();
                v[0usize] = u32::cast_from(m & 0xFFFF_FFFFu64);
                v[1usize] = u32::cast_from(m >> 32u64);
                v[2usize] = c;
                v[3usize] = r4;
                lst[slot as usize] = v;
                lkey[slot as usize] = key;
            }
            hist[key as usize].fetch_add(1u32);
        }
    }

    #[cube(launch_unchecked)]
    pub fn scatter2_kernel(lst: &Array<Vector<u32, Const<4>>>, lkey: &Array<u32>, cur: &mut Array<Atomic<u32>>, tmp: &mut Array<u32>, n: u32) {
        let i = ABSOLUTE_POS_X;
        if i < n {
            let key = lkey[i as usize];
            let slot = cur[key as usize].fetch_add(1u32);
            let v = lst[i as usize];
            tmp[(4u32 * slot) as usize] = v[0usize];
            tmp[(4u32 * slot + 1u32) as usize] = v[1usize];
            tmp[(4u32 * slot + 2u32) as usize] = v[2usize];
            tmp[(4u32 * slot + 3u32) as usize] = v[3usize];
        }
    }

    /// One cube of 256: exclusive scan of the 16,128 bucket counts (63 per unit) into `off` and `cur`, and the
    /// class segments `pseg[c] = off[256 c]`, `pseg[63]` = total.
    #[cube(launch_unchecked)]
    pub fn scan_kernel(hist: &Array<u32>, off: &mut Array<u32>, cur: &mut Array<Atomic<u32>>, pseg: &mut Array<u32>) {
        let mut sums = SharedMemory::<u32>::new(256usize);
        let t = UNIT_POS_X;
        let mut local = 0u32;
        for j in 0..63u32 {
            local += hist[(t * 63u32 + j) as usize];
        }
        sums[t as usize] = local;
        sync_cube();
        let mut step = 1u32;
        while step < 256u32 {
            let mut v = sums[t as usize];
            if t >= step {
                v += sums[(t - step) as usize];
            }
            sync_cube();
            sums[t as usize] = v;
            sync_cube();
            step *= 2u32;
        }
        let mut run = sums[t as usize] - local;
        for j in 0..63u32 {
            let k = t * 63u32 + j;
            off[k as usize] = run;
            cur[k as usize].store(run);
            if k % 256u32 == 0u32 {
                pseg[(k / 256u32) as usize] = run;
            }
            run += hist[k as usize];
        }
        if t == 255u32 {
            pseg[63usize] = run;
        }
    }

    #[cube(launch_unchecked)]
    pub fn scatter_kernel(
        r4s: &Array<u32>,
        rank: &Array<u32>,
        cur: &mut Array<Atomic<u32>>,
        tmp: &mut Array<u32>,
        nroots: u32,
        pip_lo: u32,
        pip_hi: u32,
    ) {
        let pip = u64::cast_from(pip_lo) | (u64::cast_from(pip_hi) << 32u64);
        let i = ABSOLUTE_POS_X;
        if i < nroots {
            let r4 = r4s[i as usize];
            let (m, c, key) = parent(r4, pip, rank);
            if m != 0u64 {
                let slot = cur[key as usize].fetch_add(1u32);
                tmp[(4u32 * slot) as usize] = u32::cast_from(m & 0xFFFF_FFFFu64);
                tmp[(4u32 * slot + 1u32) as usize] = u32::cast_from(m >> 32u64);
                tmp[(4u32 * slot + 2u32) as usize] = c;
                tmp[(4u32 * slot + 3u32) as usize] = r4;
            }
        }
    }

    /// One cube of 64 per bucket: each record's rank is the number of the bucket's records with a smaller r4 (r4s
    /// are distinct), so the records land in the CPU's stable order. Buckets up to RS_CAP are ranked from shared
    /// memory, larger ones from global memory.
    #[cube(launch_unchecked)]
    pub fn rsort_kernel(off: &Array<u32>, hist: &Array<u32>, tmp: &Array<u32>, rec: &mut Array<u32>) {
        let mut sr = SharedMemory::<u32>::new(2048usize);
        let k = CUBE_POS_X;
        let t = UNIT_POS_X;
        let b0 = off[k as usize];
        let n = hist[k as usize];
        let small = n <= 2048u32;
        if small {
            let mut i = t;
            while i < n {
                sr[i as usize] = tmp[(4u32 * (b0 + i) + 3u32) as usize];
                i += 64u32;
            }
        }
        sync_cube();
        let mut i = t;
        while i < n {
            let mine = tmp[(4u32 * (b0 + i) + 3u32) as usize];
            let mut rk = 0u32;
            if small {
                for j in 0..n {
                    rk += select(sr[j as usize] < mine, 1u32, 0u32);
                }
            } else {
                for j in 0..n {
                    rk += select(tmp[(4u32 * (b0 + j) + 3u32) as usize] < mine, 1u32, 0u32);
                }
            }
            let dst = 4u32 * (b0 + rk);
            let src = 4u32 * (b0 + i);
            rec[dst as usize] = tmp[src as usize];
            rec[(dst + 1u32) as usize] = tmp[(src + 1u32) as usize];
            rec[(dst + 2u32) as usize] = tmp[(src + 2u32) as usize];
            rec[(dst + 3u32) as usize] = mine;
            i += 64u32;
        }
    }

    /// --rsort 1: one cube of 256 per bucket; a bitonic sort of the bucket's
    /// (r4, index) pairs in shared memory (padded to a power of two with keys above every r4), then a gather of the
    /// records into r4 order: n log^2 n steps instead of the rank sort's n^2 compares, whose largest buckets
    /// (34 of 16,128 hold >= 512 parents, 178M compares in all) cost 1.14 ms on the RX 9070 XT. r4s are distinct
    /// within a bucket, so the order is the CPU's stable order exactly. Buckets over 2,048 fall back to the rank sort
    /// from global memory.
    #[cube(launch_unchecked)]
    pub fn bsort_kernel(off: &Array<u32>, hist: &Array<u32>, tmp: &Array<u32>, rec: &mut Array<u32>) {
        let mut sk = SharedMemory::<u32>::new(2048usize);
        let mut si = SharedMemory::<u32>::new(2048usize);
        let k = CUBE_POS_X;
        let t = UNIT_POS_X;
        let b0 = off[k as usize];
        let n = hist[k as usize];
        if n <= 2048u32 {
            let mut p = 2u32;
            while p < n {
                p *= 2u32;
            }
            let mut i = t;
            while i < p {
                let mut key = 0xFFFF_FFFFu32;
                if i < n {
                    key = tmp[(4u32 * (b0 + i) + 3u32) as usize];
                }
                sk[i as usize] = key;
                si[i as usize] = i;
                i += 256u32;
            }
            sync_cube();
            let mut kk = 2u32;
            while kk <= p {
                let mut j = kk / 2u32;
                while j > 0u32 {
                    let mut i = t;
                    while i < p {
                        let l = i ^ j;
                        if l > i {
                            let a = sk[i as usize];
                            let b = sk[l as usize];
                            let up = (i & kk) == 0u32;
                            if (a > b) == up {
                                let ia = si[i as usize];
                                let ib = si[l as usize];
                                sk[i as usize] = b;
                                sk[l as usize] = a;
                                si[i as usize] = ib;
                                si[l as usize] = ia;
                            }
                        }
                        i += 256u32;
                    }
                    sync_cube();
                    j /= 2u32;
                }
                kk *= 2u32;
            }
            let mut i = t;
            while i < n {
                let src = 4u32 * (b0 + si[i as usize]);
                let dst = 4u32 * (b0 + i);
                rec[dst as usize] = tmp[src as usize];
                rec[(dst + 1u32) as usize] = tmp[(src + 1u32) as usize];
                rec[(dst + 2u32) as usize] = tmp[(src + 2u32) as usize];
                rec[(dst + 3u32) as usize] = tmp[(src + 3u32) as usize];
                i += 256u32;
            }
        } else {
            let mut i = t;
            while i < n {
                let mine = tmp[(4u32 * (b0 + i) + 3u32) as usize];
                let mut rk = 0u32;
                for j in 0..n {
                    rk += select(tmp[(4u32 * (b0 + j) + 3u32) as usize] < mine, 1u32, 0u32);
                }
                let dst = 4u32 * (b0 + rk);
                let src = 4u32 * (b0 + i);
                rec[dst as usize] = tmp[src as usize];
                rec[(dst + 1u32) as usize] = tmp[(src + 1u32) as usize];
                rec[(dst + 2u32) as usize] = tmp[(src + 2u32) as usize];
                rec[(dst + 3u32) as usize] = mine;
                i += 256u32;
            }
        }
    }

    /// --rsort 2: one cube of 256 per bucket; buckets of at most RS2 (comptime 256) parents by rank (each thread one
    /// record, the bucket's r4s read from shared memory four at a time, padded with keys above every r4), larger
    /// ones by the bitonic sort of `bsort_kernel`'s form.
    #[cube(launch_unchecked)]
    pub fn hsort_kernel(off: &Array<u32>, hist: &Array<u32>, tmp: &Array<u32>, rec: &mut Array<u32>) {
        let mut sk = SharedMemory::<u32>::new(2048usize);
        let mut si = SharedMemory::<u32>::new(2048usize);
        let k = CUBE_POS_X;
        let t = UNIT_POS_X;
        let b0 = off[k as usize];
        let n = hist[k as usize];
        if n <= 256u32 {
            let n4 = (n + 3u32) & 0xFFFF_FFFCu32;
            let mut mine = 0xFFFF_FFFFu32;
            if t < n {
                mine = tmp[(4u32 * (b0 + t) + 3u32) as usize];
            }
            if t < n4 {
                sk[t as usize] = mine;
            }
            sync_cube();
            if t < n {
                let mut r0 = 0u32;
                let mut r1 = 0u32;
                let mut r2 = 0u32;
                let mut r3 = 0u32;
                let mut j = 0u32;
                while j < n4 {
                    r0 += select(sk[j as usize] < mine, 1u32, 0u32);
                    r1 += select(sk[(j + 1u32) as usize] < mine, 1u32, 0u32);
                    r2 += select(sk[(j + 2u32) as usize] < mine, 1u32, 0u32);
                    r3 += select(sk[(j + 3u32) as usize] < mine, 1u32, 0u32);
                    j += 4u32;
                }
                let rk = r0 + r1 + r2 + r3;
                let dst = 4u32 * (b0 + rk);
                let src = 4u32 * (b0 + t);
                rec[dst as usize] = tmp[src as usize];
                rec[(dst + 1u32) as usize] = tmp[(src + 1u32) as usize];
                rec[(dst + 2u32) as usize] = tmp[(src + 2u32) as usize];
                rec[(dst + 3u32) as usize] = mine;
            }
        } else if n <= 2048u32 {
            let mut p = 2u32;
            while p < n {
                p *= 2u32;
            }
            let mut i = t;
            while i < p {
                let mut key = 0xFFFF_FFFFu32;
                if i < n {
                    key = tmp[(4u32 * (b0 + i) + 3u32) as usize];
                }
                sk[i as usize] = key;
                si[i as usize] = i;
                i += 256u32;
            }
            sync_cube();
            let mut kk = 2u32;
            while kk <= p {
                let mut j = kk / 2u32;
                while j > 0u32 {
                    let mut i = t;
                    while i < p {
                        let l = i ^ j;
                        if l > i {
                            let a = sk[i as usize];
                            let b = sk[l as usize];
                            let up = (i & kk) == 0u32;
                            if (a > b) == up {
                                let ia = si[i as usize];
                                let ib = si[l as usize];
                                sk[i as usize] = b;
                                sk[l as usize] = a;
                                si[i as usize] = ib;
                                si[l as usize] = ia;
                            }
                        }
                        i += 256u32;
                    }
                    sync_cube();
                    j /= 2u32;
                }
                kk *= 2u32;
            }
            let mut i = t;
            while i < n {
                let src = 4u32 * (b0 + si[i as usize]);
                let dst = 4u32 * (b0 + i);
                rec[dst as usize] = tmp[src as usize];
                rec[(dst + 1u32) as usize] = tmp[(src + 1u32) as usize];
                rec[(dst + 2u32) as usize] = tmp[(src + 2u32) as usize];
                rec[(dst + 3u32) as usize] = tmp[(src + 3u32) as usize];
                i += 256u32;
            }
        } else {
            let mut i = t;
            while i < n {
                let mine = tmp[(4u32 * (b0 + i) + 3u32) as usize];
                let mut rk = 0u32;
                for j in 0..n {
                    rk += select(tmp[(4u32 * (b0 + j) + 3u32) as usize] < mine, 1u32, 0u32);
                }
                let dst = 4u32 * (b0 + rk);
                let src = 4u32 * (b0 + i);
                rec[dst as usize] = tmp[src as usize];
                rec[(dst + 1u32) as usize] = tmp[(src + 1u32) as usize];
                rec[(dst + 2u32) as usize] = tmp[(src + 2u32) as usize];
                rec[(dst + 3u32) as usize] = mine;
                i += 256u32;
            }
        }
    }

    /// --scan 1 (default since 2026-11-18): the scan of `scan_kernel` with 1,008 threads of 16 buckets each (63 x 16
    /// = 1,008 x 16 = 16,128) instead of 256 of 63: the single cube's serial chain is 4x shorter.
    #[cube(launch_unchecked)]
    pub fn scan16_kernel(hist: &Array<u32>, off: &mut Array<u32>, cur: &mut Array<Atomic<u32>>, pseg: &mut Array<u32>) {
        let mut sums = SharedMemory::<u32>::new(1024usize);
        let t = UNIT_POS_X;
        let mut local = 0u32;
        if t < 1008u32 {
            for j in 0..16u32 {
                local += hist[(t * 16u32 + j) as usize];
            }
        }
        sums[t as usize] = local;
        sync_cube();
        let mut step = 1u32;
        while step < 1024u32 {
            let mut v = sums[t as usize];
            if t >= step {
                v += sums[(t - step) as usize];
            }
            sync_cube();
            sums[t as usize] = v;
            sync_cube();
            step *= 2u32;
        }
        if t < 1008u32 {
            let mut run = sums[t as usize] - local;
            for j in 0..16u32 {
                let k = t * 16u32 + j;
                off[k as usize] = run;
                cur[k as usize].store(run);
                if k % 256u32 == 0u32 {
                    pseg[(k / 256u32) as usize] = run;
                }
                run += hist[k as usize];
            }
            if t == 1007u32 {
                pseg[63usize] = run;
            }
        }
    }

    /// --pipe-parts: zero one word (the slab counter between queued launches of a mode with records).
    #[cube(launch_unchecked)]
    pub fn zero1_kernel(a: &mut Array<u32>) {
        if ABSOLUTE_POS_X == 0u32 {
            a[0usize] = 0u32;
        }
    }

    /// --latency: a trivial kernel (one store), to price a launch and a synchronisation on the runtime.
    #[cube(launch_unchecked)]
    pub fn lat1_kernel(a: &mut Array<u32>) {
        if ABSOLUTE_POS_X == 0u32 {
            a[0usize] = a[0usize] + 1u32;
        }
    }

    /// --latency: the same with 12 storage bindings (the main kernel has 11 arrays), to see what bindings cost.
    #[cube(launch_unchecked)]
    pub fn lat12_kernel(
        a: &mut Array<u32>, b0: &Array<u32>, b1: &Array<u32>, b2: &Array<u32>, b3: &Array<u32>, b4: &Array<u32>,
        b5: &Array<u32>, b6: &Array<u32>, b7: &Array<u32>, b8: &Array<u32>, b9: &Array<u32>, b10: &Array<u32>,
    ) {
        if ABSOLUTE_POS_X == 0u32 {
            a[0usize] = a[0usize] + b0[0usize] + b1[0usize] + b2[0usize] + b3[0usize] + b4[0usize] + b5[0usize]
                + b6[0usize] + b7[0usize] + b8[0usize] + b9[0usize] + b10[0usize];
        }
    }

    /// --prep3 1 (default since 2026-11-18 on demoux): the top digits plus the zeroing that the host used to do by
    /// uploading fresh buffers every super-unit (the 16,128 bucket counts, the list count, and for the pipelined
    /// protocol the slab counter): no host write between super-units. Launched over max(ntops, 16128) threads.
    #[cube(launch_unchecked)]
    pub fn tdigz_kernel(tmask: &Array<u64>, tdig: &mut Array<u32>, hist: &mut Array<u32>, lcnt: &mut Array<u32>, slabn: &mut Array<u32>, ntops: u32) {
        let i = ABSOLUTE_POS_X;
        if i < 16128u32 {
            hist[i as usize] = 0u32;
        }
        if i == 0u32 {
            lcnt[0usize] = 0u32;
            slabn[0usize] = 0u32;
        }
        if i < ntops {
            let mut x = tmask[i as usize];
            let first = x.trailing_zeros();
            let mut dw = Array::<u32>::new(4usize);
            #[unroll]
            for k in 0..4u32 {
                dw[k as usize] = 0u32;
            }
            #[unroll]
            for k in 0..20u32 {
                let v = select(x != 0u64, x.trailing_zeros(), first);
                x &= x - select(x != 0u64, 1u64, 0u64);
                dw[comptime!(k / 5) as usize] |= v << comptime!(6 * (k % 5));
            }
            #[unroll]
            for k in 0..4u32 {
                tdig[(i * 4u32 + k) as usize] = dw[k as usize];
            }
        }
    }

    /// Each top's digits once per super-unit: 20 6-bit fields in 4 words, padded with the first digit.
    #[cube(launch_unchecked)]
    pub fn tdig_kernel(tmask: &Array<u64>, tdig: &mut Array<u32>, ntops: u32) {
        let i = ABSOLUTE_POS_X;
        if i < ntops {
            let mut x = tmask[i as usize];
            let first = x.trailing_zeros();
            let mut dw = Array::<u32>::new(4usize);
            #[unroll]
            for k in 0..4u32 {
                dw[k as usize] = 0u32;
            }
            #[unroll]
            for k in 0..20u32 {
                let v = select(x != 0u64, x.trailing_zeros(), first);
                x &= x - select(x != 0u64, 1u64, 0u64);
                dw[comptime!(k / 5) as usize] |= v << comptime!(6 * (k % 5));
            }
            #[unroll]
            for k in 0..4u32 {
                tdig[(i * 4u32 + k) as usize] = dw[k as usize];
            }
        }
    }
}
// ------------------------------------------------------------------------------------------------ host data
#[derive(Clone, Copy)]
struct Top {
    d: u32,
    h: u64,
    mask: u64,
    lo: u128,
    hi: u128,
}
#[derive(Clone, Copy)]
struct Parent {
    r: u64,
    mask: u64,
    cacc: u32,
    cls: u32,
}

fn dig(x: u64, j: u32) -> u32 {
    ((x >> (6 * j)) & 63) as u32
}
fn root_mask(r4: u64) -> u64 {
    let s = r4.wrapping_mul(r4) & MASK60;
    let c = s.wrapping_mul(r4) & MASK60;
    let mut m = 0u64;
    for j in 0..4 {
        let a = 1u64 << dig(s, j);
        let b = 1u64 << dig(c, j);
        if (m & a) != 0 || (m & b) != 0 || a == b {
            return 0;
        }
        m |= a | b;
    }
    m
}
fn make_parent(r4: u64, rmask: u64, pip: u64) -> Option<Parent> {
    let r = r4 + (pip << 24);
    let s = r.wrapping_mul(r) & MASK60;
    let c = s.wrapping_mul(r) & MASK60;
    let mut m = rmask;
    for j in 4..9 {
        let a = 1u64 << dig(s, j);
        let b = 1u64 << dig(c, j);
        if (m & a) != 0 || (m & b) != 0 || a == b {
            return None;
        }
        m |= a | b;
    }
    let r0 = r & 63;
    let cacc = dig(s, 9) | (dig(c, 9) << 8) | ((((2 * r0) & 63) as u32) << 16) | ((((3 * r0 * r0) & 63) as u32) << 24);
    Some(Parent { r, mask: m, cacc, cls: (r % 63) as u32 })
}
fn child_mask(pm: u64, cacc: u32, d: u32) -> u64 {
    let e2 = ((cacc & 63) + ((cacc >> 16) & 63) * d) & 63;
    let e3 = (((cacc >> 8) & 63) + ((cacc >> 24) & 63) * d) & 63;
    let add = (1u64 << e2) | (1u64 << e3);
    if e2 == e3 || (pm & add) != 0 { 0 } else { pm | add }
}
/// Each top's digit words as `tdig_kernel` makes them (20 6-bit fields, 5 per word, padded with the first digit),
/// in the sorted top order.
fn top_digits(inp: &Input) -> Vec<u32> {
    let mut out = Vec::with_capacity(inp.ts.len() * 4);
    for t in &inp.ts {
        let mut x = t.mask;
        let first = x.trailing_zeros();
        let mut dw = [0u32; 4];
        for k in 0..20 {
            let v = if x != 0 { x.trailing_zeros() } else { first };
            if x != 0 {
                x &= x - 1;
            }
            dw[k / 5] |= v << (6 * (k % 5));
        }
        out.extend(dw);
    }
    out
}

fn key8(mask: u64, rank: &[u32; 8]) -> u32 {
    let mut k = 0;
    for (i, &v) in rank.iter().enumerate() {
        k |= (((mask >> v) & 1) as u32) << (7 - i);
    }
    k
}

struct Input {
    pip: u64,
    ts: Vec<Top>,
    tseg: Vec<u32>,
    expect: Vec<Vec<u128>>, // per unit, sorted
    par: Vec<Parent>,       // sorted by (class, key desc), stable
    pseg: Vec<u32>,
    rank: [u32; 8],
    adm: f64,
}

fn load(dir: &str) -> Result<Input> {
    let raw = std::fs::read(format!("{dir}/tops.bin"))?;
    let mut tops = Vec::new();
    for rec in raw.chunks_exact(52) {
        let u = |a: usize, b: usize| rec[a..b].to_vec();
        tops.push(Top {
            d: u32::from_le_bytes(u(0, 4).try_into().unwrap()),
            h: u64::from_le_bytes(u(4, 12).try_into().unwrap()),
            mask: u64::from_le_bytes(u(12, 20).try_into().unwrap()),
            lo: u128::from_le_bytes(u(20, 36).try_into().unwrap()),
            hi: u128::from_le_bytes(u(36, 52).try_into().unwrap()),
        });
    }
    let meta = std::fs::read_to_string(format!("{dir}/meta.txt"))?;
    let (mut pip, mut start, mut end) = (0u64, 0u128, 0u128);
    let mut cnt = vec![0usize; 64];
    for line in meta.lines() {
        let f: Vec<&str> = line.split_whitespace().collect();
        if f.first() == Some(&"b") {
            pip = f[7].parse()?;
            start = f[9].parse()?;
            end = f[11].parse()?;
        }
        if f.first() == Some(&"unit") {
            let u: usize = f[1].parse()?;
            cnt[u] = f[13].parse()?;
        }
    }
    let sraw = std::fs::read(format!("{dir}/surv.bin"))?;
    let mut expect = Vec::new();
    let mut off = 0;
    for &n in &cnt {
        let mut v: Vec<u128> =
            sraw[off..off + 16 * n].chunks_exact(16).map(|b| u128::from_le_bytes(b.try_into().unwrap())).collect();
        v.sort_unstable();
        expect.push(v);
        off += 16 * n;
    }
    // tops per (d, h mod 63), stable
    let mut ts = tops.clone();
    ts.sort_by_key(|t| (t.d, t.h % 63));
    let mut tseg = vec![0u32; 64 * 63 * 2];
    let mut i = 0usize;
    for dd in 0..64u32 {
        for ct in 0..63u64 {
            tseg[((dd * 63) as usize + ct as usize) * 2] = i as u32;
            while i < ts.len() && ts[i].d == dd && ts[i].h % 63 == ct {
                i += 1;
            }
            tseg[((dd * 63) as usize + ct as usize) * 2 + 1] = i as u32;
        }
    }
    if i != ts.len() {
        bail!("top segmentation failed");
    }
    // roots, parents, digit ranking (same rule as g2bench.cu), stable sort by (class, 255 - key)
    let mut p0 = Vec::new();
    for r4 in 0..(1u64 << 24) {
        let m = root_mask(r4);
        if m != 0 {
            if let Some(p) = make_parent(r4, m, pip) {
                p0.push(p);
            }
        }
    }
    let (mut fp, mut ft) = ([0f64; 64], [0f64; 64]);
    for p in &p0 {
        for v in 0..64 {
            fp[v] += ((p.mask >> v) & 1) as f64;
        }
    }
    for t in &tops {
        for v in 0..64 {
            ft[v] += ((t.mask >> v) & 1) as f64;
        }
    }
    let mut dg: Vec<u32> = (0..64).collect();
    dg.sort_by(|&a, &b| (fp[b as usize] * ft[b as usize]).partial_cmp(&(fp[a as usize] * ft[a as usize])).unwrap());
    let rank: [u32; 8] = dg[..8].try_into().unwrap();
    let mut par = p0;
    par.sort_by_key(|p| p.cls * 256 + (255 - key8(p.mask, &rank)));
    let mut pseg = vec![0u32; 64];
    let mut i = 0usize;
    for c in 0..63u32 {
        pseg[c as usize] = i as u32;
        while i < par.len() && par[i].cls == c {
            i += 1;
        }
    }
    pseg[63] = par.len() as u32;
    // the kernel keeps pending children as u16 offsets from their class's start
    let big = (0..63).map(|c| pseg[c + 1] - pseg[c]).max().unwrap_or(0);
    if big > 65536 {
        bail!("a parent class has {big} parents: the kernel's u16 pending slots need <= 65536");
    }
    let w = (end - start) as f64;
    let adm = w / (1u64 << 30) as f64 / 64.0 * 64.0 * 8.0 / 63.0;
    Ok(Input { pip, ts, tseg, expect, par, pseg, rank, adm })
}

#[derive(Default, Clone, Copy, Debug, PartialEq, Eq)]
struct Counts {
    children: u64,
    chunks: u64,
    flat: u64,
    kept: u64,
    surv: u64,
}

fn probes(inp: &Input, c: u32, d: u32) -> Vec<u32> {
    let cc = (c + d) % M;
    let mut v = Vec::new();
    for &r in &ROOTS {
        let ct = (r + M - cc) % M;
        let s = ((d * M + ct) * 2) as usize;
        v.extend(inp.tseg[s]..inp.tseg[s + 1]);
    }
    v
}

/// The CPU reference of one job (g2bench.cu's `cpu_block`, skip on).
fn cpu_job(inp: &Input, c: u32, d: u32, cn: &mut Counts, out: &mut Vec<(u32, u32)>) {
    let pr = probes(inp, c, d);
    let (mut cm, mut cp) = (Vec::new(), Vec::new());
    for p in inp.pseg[c as usize]..inp.pseg[c as usize + 1] {
        let m = child_mask(inp.par[p as usize].mask, inp.par[p as usize].cacc, d);
        if m != 0 {
            cm.push(m);
            cp.push(p);
        }
    }
    cn.children += cm.len() as u64;
    let nch = cm.len().div_ceil(64);
    cn.chunks += nch as u64;
    for q in 0..nch {
        let n0 = q * 64;
        let n = 64.min(cm.len() - n0);
        let mut sl = [0u64; 64];
        let mut common = !0u64;
        let valid = if n == 64 { !0u64 } else { (1u64 << n) - 1 };
        for i in 0..n {
            let m = cm[n0 + i];
            common &= m;
            for (v, s) in sl.iter_mut().enumerate() {
                if (m >> v) & 1 != 0 {
                    *s |= 1u64 << i;
                }
            }
        }
        cn.flat += pr.len() as u64;
        for &t in &pr {
            let tm = inp.ts[t as usize].mask;
            if common & tm != 0 {
                continue;
            }
            cn.kept += 1;
            let mut acc = 0u64;
            let mut x = tm;
            while x != 0 {
                acc |= sl[x.trailing_zeros() as usize];
                x &= x - 1;
            }
            let mut w = !acc & valid;
            while w != 0 {
                let i = w.trailing_zeros() as usize;
                out.push((t, cp[n0 + i]));
                cn.surv += 1;
                w &= w - 1;
            }
        }
    }
}

/// The kernel's dynamic loop counts for one job at `fill` children per round (for pricing on another device):
/// phase-1 steps (NT parents each), rounds, 3a iterations per unit (ceil(nprobe / NT) per round), 3b cube steps
/// (ceil(nlist / 32) per round), list entries, and probe-setup iterations.
#[derive(Default, Debug, Clone, Copy)]
struct Model {
    p1_steps: u64,
    rounds: u64,
    a3_iters: u64,
    b3_steps: u64,
    entries: u64,
    setup_iters: u64,
}
fn model_job(inp: &Input, c: u32, d: u32, fill: usize, md: &mut Model) {
    let pr = probes(inp, c, d);
    let cc = (c + d) % M;
    for &r in &ROOTS {
        let ct = (r + M - cc) % M;
        let s = ((d * M + ct) * 2) as usize;
        md.setup_iters = md.setup_iters.max(0);
        md.setup_iters += (inp.tseg[s + 1] - inp.tseg[s]).div_ceil(NT) as u64;
    }
    let (pb, pe) = (inp.pseg[c as usize] as usize, inp.pseg[c as usize + 1] as usize);
    let mut pend: Vec<u64> = Vec::new();
    let mut cur = pb;
    loop {
        while pend.len() < fill && cur < pe {
            for idx in cur..(cur + NT as usize).min(pe) {
                let m = child_mask(inp.par[idx].mask, inp.par[idx].cacc, d);
                if m != 0 {
                    pend.push(m);
                }
            }
            md.p1_steps += 1;
            cur += NT as usize;
        }
        let done = cur >= pe;
        let nch = if done { (fill / 64).min(pend.len().div_ceil(64)) } else { fill / 64 };
        if nch == 0 {
            break;
        }
        md.rounds += 1;
        let ntake = pend.len().min(nch * 64);
        let commons: Vec<u64> = (0..nch).map(|q| pend[q * 64..((q + 1) * 64).min(ntake)].iter().fold(!0u64, |a, &m| a & m)).collect();
        let nlist = pr.iter().filter(|&&t| commons.iter().any(|&cm| cm & inp.ts[t as usize].mask == 0)).count();
        md.entries += nlist as u64;
        md.b3_steps += nlist.div_ceil(32) as u64;
        md.a3_iters += pr.len().div_ceil(NT as usize) as u64;
        pend.drain(..ntake);
        if done && pend.is_empty() {
            break;
        }
    }
}

/// Survivor set per unit from (top, parent) pairs, n inside the top's clip.
fn sets(inp: &Input, pairs: &[(u32, u32)]) -> (Vec<Vec<u128>>, u64) {
    let mut got = vec![Vec::new(); 64];
    let mut clipped = 0;
    for &(t, p) in pairs {
        let tp = &inp.ts[t as usize];
        let n = ((tp.h as u128) << 60) + inp.par[p as usize].r as u128 + ((tp.d as u128) << 54);
        if n < tp.lo || n > tp.hi {
            clipped += 1;
            continue;
        }
        got[tp.d as usize].push(n);
    }
    for g in &mut got {
        g.sort_unstable();
    }
    (got, clipped)
}

/// The prototype's survivors of the jobs: unit d's set filtered to the jobs' classes (n's low 54 bits are the parent).
fn expected(inp: &Input, jobs: &[(u32, u32)]) -> Vec<Vec<u128>> {
    let mut want = vec![[false; 63]; 64];
    for &(c, d) in jobs {
        want[d as usize][c as usize] = true;
    }
    (0..64)
        .map(|d| inp.expect[d].iter().copied().filter(|&n| want[d][((n & ((1u128 << 54) - 1)) % 63) as usize]).collect())
        .collect()
}

fn compare(tag: &str, got: &[Vec<u128>], want: &[Vec<u128>], clipped: u64) -> bool {
    let mut ok = true;
    let mut tot = 0;
    for d in 0..64 {
        tot += got[d].len();
        if got[d] != want[d] {
            ok = false;
            eprintln!("{tag}: unit {d}: got {} expected {}", got[d].len(), want[d].len());
        }
    }
    println!(
        "VERIFY {tag}: {tot} survivors ({clipped} outside a clipped top), every job unit's set {}",
        if ok { "EQUAL to the prototype's" } else { "DIFFERS" }
    );
    ok
}

// ------------------------------------------------------------------------------------------------ main
fn main() -> Result<()> {
    env_logger::init();
    let args: Vec<String> = std::env::args().collect();
    let dir = args.get(1).ok_or_else(|| anyhow!("usage: g2_cubecl DIR [--jobs all|C0-C1:D0-D1] [--reps N] [--modes 0,1,2] [--noout] [--cpu-full]"))?;
    let opt = |name: &str| args.iter().position(|a| a == name).and_then(|i| args.get(i + 1)).cloned();
    let jobspec = opt("--jobs").unwrap_or_else(|| "all".into());
    let reps: usize = opt("--reps").map_or(Ok(1), |s| s.parse())?;
    let modes: Vec<u32> = opt("--modes").unwrap_or_else(|| "0,1,2".into()).split(',').map(|s| s.parse().unwrap()).collect();
    let noout = args.iter().any(|a| a == "--noout");
    let t0 = Instant::now();
    let inp = load(dir)?;
    println!(
        "loaded {} tops, pip {}, {} parents; key digits {:?}; admissible n in the super-unit {:.4e} ({:.1}s)",
        inp.ts.len(),
        inp.pip,
        inp.par.len(),
        inp.rank,
        inp.adm,
        t0.elapsed().as_secs_f64()
    );
    let jobs: Vec<(u32, u32)> = if jobspec == "all" {
        (0..63).flat_map(|c| (0..64).map(move |d| (c, d))).collect()
    } else {
        let (cs, ds) = jobspec.split_once(':').ok_or_else(|| anyhow!("--jobs C0-C1:D0-D1"))?;
        let rng = |s: &str| -> Result<(u32, u32)> {
            let (a, b) = s.split_once('-').unwrap_or((s, s));
            Ok((a.parse()?, b.parse()?))
        };
        let (c0, c1) = rng(cs)?;
        let (d0, d1) = rng(ds)?;
        (c0..=c1).flat_map(|c| (d0..=d1).map(move |d| (c, d))).collect()
    };
    println!("jobs: {} ({jobspec})", jobs.len());
    // CPU reference over the jobs (or the full super-unit with --cpu-full)
    let cpu_jobs: Vec<(u32, u32)> =
        if args.iter().any(|a| a == "--cpu-full") { (0..63).flat_map(|c| (0..64).map(move |d| (c, d))).collect() } else { jobs.clone() };
    let tc = Instant::now();
    let mut cref = Counts::default();
    let mut cpairs = Vec::new();
    for &(c, d) in &cpu_jobs {
        cpu_job(&inp, c, d, &mut cref, &mut cpairs);
    }
    println!("CPU ref ({} jobs): {:?} ({:.1}s)", cpu_jobs.len(), cref, tc.elapsed().as_secs_f64());
    // --no-sets: counts only (timing runs; the sets were checked in the exactness runs)
    let no_sets = args.iter().any(|a| a == "--no-sets");
    if !no_sets {
        let (g, cl) = sets(&inp, &cpairs);
        if !compare("cpu", &g, &expected(&inp, &cpu_jobs), cl) {
            bail!("CPU reference differs from the prototype");
        }
    }
    if cpu_jobs.len() != jobs.len() {
        // counts for the GPU's jobs only
        cref = Counts::default();
        cpairs.clear();
        for &(c, d) in &jobs {
            cpu_job(&inp, c, d, &mut cref, &mut cpairs);
        }
    }
    let want = if no_sets { vec![Vec::new(); 64] } else { expected(&inp, &jobs) };
    if let Some(f) = opt("--model") {
        let fill: usize = f.parse()?;
        let mut md = Model::default();
        for &(c, d) in &jobs {
            model_job(&inp, c, d, fill, &mut md);
        }
        println!("MODEL fill {fill}: {md:?} (jobs {})", jobs.len());
        return Ok(());
    }

    // ---------------- GPU (wgpu by default; --cuda: CubeCL's CUDA runtime, with the cubecl-cuda feature)
    let ctx = if args.iter().any(|a| a == "--cuda") {
        #[cfg(feature = "cubecl-cuda")]
        {
            CubeclContext::new_cuda(0)?
        }
        #[cfg(not(feature = "cubecl-cuda"))]
        {
            bail!("--cuda needs the cubecl-cuda feature")
        }
    } else {
        CubeclContext::new_default()?
    };
    let name = ctx.device_name();
    match ctx {
        CubeclContext::Wgpu { client, .. } => run_gpu(client, name, &inp, &jobs, &args, reps, &modes, noout, no_sets, cref, &want),
        #[cfg(feature = "cubecl-cuda")]
        CubeclContext::Cuda { client, .. } => run_gpu(client, name, &inp, &jobs, &args, reps, &modes, noout, no_sets, cref, &want),
        #[allow(unreachable_patterns)]
        _ => bail!("unsupported runtime"),
    }
}

fn run_gpu<R: Runtime>(
    client: ComputeClient<R>,
    name: String,
    inp: &Input,
    jobs: &[(u32, u32)],
    args: &[String],
    reps: usize,
    modes: &[u32],
    noout: bool,
    no_sets: bool,
    cref: Counts,
    want: &[Vec<u128>],
) -> Result<()> {
    let opt = |name: &str| args.iter().position(|a| a == name).and_then(|i| args.get(i + 1)).cloned();
    let w_hw = client.properties().hardware.plane_size_max;
    // --force-w: compile the kernel for another plane width (to dump its SPIR-V for an offline compiler);
    // results are then invalid and only the module is wanted
    // --plane-w: run (and check) the kernel at this plane width instead of the device's plane_size_max (a device
    // that runs it with other planes than it reports; the kernel's plane check still applies)
    let w: u32 = opt("--force-w").or_else(|| opt("--plane-w")).map_or(Ok(w_hw), |s| s.parse())?;
    let compile_only = opt("--force-w").is_some() && w != w_hw;
    if compile_only {
        println!("COMPILE-ONLY: kernel compiled for W = {w} on a device with W = {w_hw}; results are not checked");
    }
    let wmin = client.properties().hardware.plane_size_min;
    println!("device: {name}; plane size min {wmin} max {w}; compiler: {}", if R::name(&client).contains("cuda") { "CUDA (cubecl-cpp)" } else if cfg!(feature = "cubecl-spirv") { "SPIR-V (cubecl-spirv)" } else { "WGSL (naga)" });
    if ![8u32, 16, 32, 64].contains(&w) {
        bail!("plane width {w} not supported");
    }
    // Children per round: 16 chunks; 8 where W < 32 needs the 8 KB ballot staging array (lavapipe: 32 KB of
    // shared memory). Chunking, kept incidences and survivors do not depend on it.
    let fill: u32 = opt("--fill").map_or(Ok(if w < 32 { 512 } else { FILL }), |s| s.parse())?;
    println!("fill {fill} children per round ({} chunks)", fill / 64);
    // phase 2: 0 = 64 ballots per chunk segment, 1 = log2(W) shuffle_xor stages
    let xpose: u32 = opt("--xpose").map_or(Ok(1), |s| s.parse())?;
    println!("transpose: {}", if xpose == 0 { "ballots" } else { "shuffle_xor stages" });
    // list entries per unit per 3b step (2 = v9/v10's form; 1 = fewer VGPRs)
    let ept: u32 = opt("--ept").map_or(Ok(2), |s| s.parse())?;
    println!("entries per unit per step: {ept}");
    // plane ranks for the ordered compaction and the record append: 1 = ballot + popcount (default), 0 = plane scans
    let ranks: u32 = opt("--ranks").map_or(Ok(1), |s| s.parse())?;
    println!("plane ranks: {}", if ranks == 1 { "ballot + popcount" } else { "plane scans" });
    // --cut BITS (timing only; results invalid): 1 skips the transpose, 2 the common masks, 4 the probe setup
    let cut: u32 = opt("--cut").map_or(Ok(0), |s| s.parse())?;
    // common masks: 1 = from the shuffle transpose's registers (default with --xpose 1), 0 = a pass over the slices
    let cmask: u32 = opt("--cmask").map_or(Ok(1), |s| s.parse())?;
    println!("common masks: {}", if cmask == 1 && xpose == 1 { "from the transpose" } else { "pass over the slices" });
    if cut != 0 {
        println!("CUT {cut}: phases skipped for timing; counts and sets are not valid");
    }
    let dbg = std::env::var("G2_DEBUG_SYNC").is_ok();
    let chk = |what: &str| {
        if dbg {
            let r = cubecl::future::block_on(client.sync());
            eprintln!("debug sync after {what}: {:?}", r.is_ok());
        }
    };
    chk("init");
    let mk = |v: Vec<u32>| client.create(cubecl::bytes::Bytes::from_elems(v));
    let sync = || cubecl::future::block_on(client.sync()).map_err(|e| anyhow!("sync: {e:?}"));
    let med = |v: &mut Vec<f64>| -> f64 {
        v.sort_by(|a, b| a.partial_cmp(b).unwrap());
        v[v.len() / 2]
    };
    // --latency N: the fixed cost of a launch and of a synchronisation on this runtime (2026-11-18, demoux): trivial
    // kernels (one cube of 64, one store), with 1 and with 12 storage bindings; synced after every launch, and N
    // launches queued with one synchronisation; and the device's own time for one launch (timestamp queries)
    if let Some(nl) = opt("--latency") {
        let nl: usize = nl.parse()?;
        let a = mk(vec![0u32; 16]);
        let bs: Vec<_> = (0..11).map(|_| mk(vec![1u32; 16])).collect();
        let l1 = || unsafe {
            prep::lat1_kernel::launch_unchecked::<R>(&client, CubeCount::Static(1, 1, 1), CubeDim::new_1d(64), ArrayArg::from_raw_parts(a.clone(), 16));
        };
        let l12 = || unsafe {
            let b = |i: usize| ArrayArg::from_raw_parts(bs[i].clone(), 16);
            prep::lat12_kernel::launch_unchecked::<R>(
                &client, CubeCount::Static(1, 1, 1), CubeDim::new_1d(64), ArrayArg::from_raw_parts(a.clone(), 16),
                b(0), b(1), b(2), b(3), b(4), b(5), b(6), b(7), b(8), b(9), b(10),
            );
        };
        // warm: compile both, then 0.5 s of synced launches
        l1();
        l12();
        sync()?;
        let tw = Instant::now();
        while tw.elapsed().as_secs_f64() < 0.5 {
            l1();
            sync()?;
        }
        let mut e = Vec::new();
        for _ in 0..nl {
            let t = Instant::now();
            sync()?;
            e.push(t.elapsed().as_secs_f64());
        }
        let mut s1 = Vec::new();
        let mut s12 = Vec::new();
        for _ in 0..nl {
            let t = Instant::now();
            l1();
            sync()?;
            s1.push(t.elapsed().as_secs_f64());
            let t = Instant::now();
            l12();
            sync()?;
            s12.push(t.elapsed().as_secs_f64());
        }
        let t = Instant::now();
        for _ in 0..nl {
            l1();
        }
        sync()?;
        let q1 = t.elapsed().as_secs_f64() / nl as f64;
        let t = Instant::now();
        for _ in 0..nl {
            l12();
        }
        sync()?;
        let q12 = t.elapsed().as_secs_f64() / nl as f64;
        let mut d1 = Vec::new();
        let mut d12 = Vec::new();
        let mut dq = Vec::new();
        let mut method = String::new();
        for _ in 0..nl.min(200) {
            let (_, d) = client.profile(l1, "lat1").map_err(|e| anyhow!("profile: {e:?}"))?;
            method = format!("{:?}", d.timing_method());
            d1.push(cubecl::future::block_on(d.resolve()).duration().as_secs_f64());
            let (_, d) = client.profile(l12, "lat12").map_err(|e| anyhow!("profile: {e:?}"))?;
            d12.push(cubecl::future::block_on(d.resolve()).duration().as_secs_f64());
            let (_, d) = client
                .profile(
                    || {
                        for _ in 0..64 {
                            l12();
                        }
                    },
                    "lat12x64",
                )
                .map_err(|e| anyhow!("profile: {e:?}"))?;
            dq.push(cubecl::future::block_on(d.resolve()).duration().as_secs_f64() / 64.0);
        }
        println!(
            "LATENCY ({nl} each, µs medians) empty sync {:.1}; launch+sync: 1 binding {:.1}, 12 bindings {:.1}; queued (N launches, one sync) per launch: 1 binding {:.2}, 12 bindings {:.2}; device ({method}) one launch: 1 binding {:.2}, 12 bindings {:.2}, 64 queued per launch {:.2}",
            med(&mut e) * 1e6, med(&mut s1) * 1e6, med(&mut s12) * 1e6, q1 * 1e6, q12 * 1e6,
            med(&mut d1) * 1e6, med(&mut d12) * 1e6, med(&mut dq) * 1e6
        );
        if args.iter().any(|a| a == "--latency-only") {
            return Ok(());
        }
    }
    let mut all_prep_bad = false;
    // parent records (mask lo, mask hi, cacc, r4) and each top's digit words, as the GPU preparation makes them
    let rec_host: Vec<u32> = inp
        .par
        .iter()
        .flat_map(|p| [p.mask as u32, (p.mask >> 32) as u32, p.cacc, (p.r - (inp.pip << 24)) as u32])
        .collect();
    let tdig_host = top_digits(inp);
    let rec = mk(rec_host.clone());
    let pseg = mk(inp.pseg.clone());
    let tdig = mk(tdig_host.clone());
    let tmask_k = client.create(cubecl::bytes::Bytes::from_elems(inp.ts.iter().map(|t| t.mask).collect::<Vec<u64>>()));
    // --tdig 0: the probe setup makes the digits in every cube (as before the fixes), for bisecting
    let tdg: u32 = opt("--tdig").map_or(Ok(0), |s| s.parse())?; // 0 by default: 1 slowed the full kernel by 2.8 ms on CUDA (cause unknown)
    let tseg = mk(inp.tseg.clone());
    let roots = mk(ROOTS.to_vec());
    chk("records/digits/tseg/roots");
    // jobs in launches of `--batch` (default: all at once; lavapipe needs smaller output buffers)
    let batch: usize = opt("--batch").map_or(Ok(jobs.len()), |s| s.parse())?;
    let batches: Vec<&[(u32, u32)]> = jobs.chunks(batch.max(1)).collect();
    let mut nslab_cap = 0u32;
    for bj in &batches {
        let mut cb = Counts::default();
        let mut scratch = Vec::new();
        for &(c, d) in bj.iter() {
            cpu_job(inp, c, d, &mut cb, &mut scratch);
        }
        nslab_cap = nslab_cap.max(((cb.surv as usize / SLAB as usize) + bj.len() * (NT / w) as usize + 64) as u32);
    }
    let jobs_h: Vec<_> = batches.iter().map(|bj| mk(bj.iter().flat_map(|&(c, d)| [c, d]).collect())).collect();
    chk("jobs");
    let out = client.empty(nslab_cap as usize * SLAB as usize * 16);
    let slabcnt = client.empty(nslab_cap as usize * 4);
    chk("out/slabcnt");
    // ---- GPU preparation (timed, then checked against the host's: the records' order and words, the class
    // segments, the top digits; the kernel then runs on the GPU's arrays). Five launches: top digits, histogram,
    // scan, scatter, rank sort per bucket.
    let mut prep_secs = 0f64;
    let (rec, pseg, tdig) = if args.iter().any(|a| a == "--gpu-prep") {
        let r4s: Vec<u32> = (0..(1u32 << 24)).filter(|&r| root_mask(r as u64) != 0).collect();
        let nroots = r4s.len() as u32;
        let ntops = inp.ts.len();
        let r4h = mk(r4s);
        let rankh = mk(inp.rank.to_vec());
        let tmask = client.create(cubecl::bytes::Bytes::from_elems(inp.ts.iter().map(|t| t.mask).collect::<Vec<u64>>()));
        let npar = inp.par.len();
        let g_tmp = client.empty(npar * 16);
        // --prep2 1 (default): one pass over the roots, a compact parent list, a scatter over the list
        let prep2: u32 = opt("--prep2").map_or(Ok(1), |s| s.parse())?;
        let g_lst = client.empty(npar * 16);
        let g_lkey = client.empty(npar * 4);
        let mut lcnt = mk(vec![0u32; 1]);
        let g_rec = client.empty(npar * 16);
        let g_tdig = client.empty(ntops * 16);
        let off = client.empty(16128 * 4);
        let curh = client.empty(16128 * 4);
        let g_pseg = client.empty(64 * 4);
        // --prep3 1 (default, 2026-11-18): the first launch also zeroes the bucket counts, the list count and the
        // pipelined protocol's slab counter, so a super-unit's preparation needs no host write; 0 = the window's
        // form (fresh zeroed buffers uploaded by the host before every preparation)
        let prep3: u32 = opt("--prep3").map_or(Ok(1), |s| s.parse())?;
        // --rsort 2 (default): rank sort from shared memory for buckets <= 256, bitonic above; 1 = bitonic for all; 0 = the
        // window's rank sort (one cube of 64 per bucket, n^2 compares: 1.14 ms of the 1.84 ms on the RX 9070 XT)
        let rsort: u32 = opt("--rsort").map_or(Ok(2), |s| s.parse())?;
        println!("bucket sort: {}", ["rank sort (rsort 0)", "bitonic in shared memory (rsort 1)", "rank <= 256 from shared, 4 per step, else bitonic (rsort 2)"][rsort.min(2) as usize]);
        let scan16: u32 = opt("--scan").map_or(Ok(1), |s| s.parse())?;
        println!("bucket scan: {}", if scan16 == 1 { "1008 threads x 16 (scan 1)" } else { "256 threads x 63 (scan 0)" });
        let slabz = mk(vec![0u32; 1]);
        let mut tv = Vec::new();
        let mut histh = mk(vec![0u32; 16128]);
        let pburst = args.iter().any(|a| a == "--burst");
        let mut pt0: Option<Instant> = None;
        let cubes = nroots.div_ceil(NT);
        // launch k of the preparation's five: 0 top digits (+ zeroing with --prep3 1), 1 histogram (+ list), 2 scan,
        // 3 scatter, 4 rank sort per bucket
        let launch_prep = |k: usize, histh: &cubecl::server::Handle, lcnt: &cubecl::server::Handle| unsafe {
            match k {
                0 => {
                    if prep3 == 1 {
                        prep::tdigz_kernel::launch_unchecked::<R>(
                            &client, CubeCount::Static((ntops as u32).max(16128).div_ceil(NT), 1, 1), CubeDim::new_1d(NT),
                            ArrayArg::from_raw_parts(tmask.clone(), ntops), ArrayArg::from_raw_parts(g_tdig.clone(), ntops * 4),
                            ArrayArg::from_raw_parts(histh.clone(), 16128), ArrayArg::from_raw_parts(lcnt.clone(), 1),
                            ArrayArg::from_raw_parts(slabz.clone(), 1), ntops as u32,
                        );
                    } else {
                        prep::tdig_kernel::launch_unchecked::<R>(
                            &client, CubeCount::Static((ntops as u32).div_ceil(NT), 1, 1), CubeDim::new_1d(NT),
                            ArrayArg::from_raw_parts(tmask.clone(), ntops), ArrayArg::from_raw_parts(g_tdig.clone(), ntops * 4),
                            ntops as u32,
                        );
                    }
                }
                1 => {
                    if prep2 == 1 {
                        prep::hist2_kernel::launch_unchecked::<R>(
                            &client, CubeCount::Static(cubes, 1, 1), CubeDim::new_1d(NT),
                            ArrayArg::from_raw_parts(r4h.clone(), nroots as usize), ArrayArg::from_raw_parts(rankh.clone(), 8),
                            ArrayArg::from_raw_parts(histh.clone(), 16128), ArrayArg::from_raw_parts(g_lst.clone(), npar),
                            ArrayArg::from_raw_parts(g_lkey.clone(), npar), ArrayArg::from_raw_parts(lcnt.clone(), 1),
                            nroots, inp.pip as u32, (inp.pip >> 32) as u32, npar as u32, w,
                        );
                    } else {
                        prep::hist_kernel::launch_unchecked::<R>(
                            &client, CubeCount::Static(cubes, 1, 1), CubeDim::new_1d(NT),
                            ArrayArg::from_raw_parts(r4h.clone(), nroots as usize), ArrayArg::from_raw_parts(rankh.clone(), 8),
                            ArrayArg::from_raw_parts(histh.clone(), 16128), nroots, inp.pip as u32, (inp.pip >> 32) as u32,
                        );
                    }
                }
                2 => {
                    if scan16 == 1 {
                        prep::scan16_kernel::launch_unchecked::<R>(
                            &client, CubeCount::Static(1, 1, 1), CubeDim::new_1d(1024),
                            ArrayArg::from_raw_parts(histh.clone(), 16128), ArrayArg::from_raw_parts(off.clone(), 16128),
                            ArrayArg::from_raw_parts(curh.clone(), 16128), ArrayArg::from_raw_parts(g_pseg.clone(), 64),
                        );
                    } else {
                        prep::scan_kernel::launch_unchecked::<R>(
                            &client, CubeCount::Static(1, 1, 1), CubeDim::new_1d(256),
                            ArrayArg::from_raw_parts(histh.clone(), 16128), ArrayArg::from_raw_parts(off.clone(), 16128),
                            ArrayArg::from_raw_parts(curh.clone(), 16128), ArrayArg::from_raw_parts(g_pseg.clone(), 64),
                        );
                    }
                }
                3 => {
                    if prep2 == 1 {
                        prep::scatter2_kernel::launch_unchecked::<R>(
                            &client, CubeCount::Static((npar as u32).div_ceil(NT), 1, 1), CubeDim::new_1d(NT),
                            ArrayArg::from_raw_parts(g_lst.clone(), npar), ArrayArg::from_raw_parts(g_lkey.clone(), npar),
                            ArrayArg::from_raw_parts(curh.clone(), 16128), ArrayArg::from_raw_parts(g_tmp.clone(), npar * 4),
                            npar as u32,
                        );
                    } else {
                        prep::scatter_kernel::launch_unchecked::<R>(
                            &client, CubeCount::Static(cubes, 1, 1), CubeDim::new_1d(NT),
                            ArrayArg::from_raw_parts(r4h.clone(), nroots as usize), ArrayArg::from_raw_parts(rankh.clone(), 8),
                            ArrayArg::from_raw_parts(curh.clone(), 16128), ArrayArg::from_raw_parts(g_tmp.clone(), npar * 4),
                            nroots, inp.pip as u32, (inp.pip >> 32) as u32,
                        );
                    }
                }
                _ => {
                    if rsort == 2 {
                        prep::hsort_kernel::launch_unchecked::<R>(
                            &client, CubeCount::Static(16128, 1, 1), CubeDim::new_1d(256),
                            ArrayArg::from_raw_parts(off.clone(), 16128), ArrayArg::from_raw_parts(histh.clone(), 16128),
                            ArrayArg::from_raw_parts(g_tmp.clone(), npar * 4), ArrayArg::from_raw_parts(g_rec.clone(), npar * 4),
                        );
                    } else if rsort == 1 {
                        prep::bsort_kernel::launch_unchecked::<R>(
                            &client, CubeCount::Static(16128, 1, 1), CubeDim::new_1d(256),
                            ArrayArg::from_raw_parts(off.clone(), 16128), ArrayArg::from_raw_parts(histh.clone(), 16128),
                            ArrayArg::from_raw_parts(g_tmp.clone(), npar * 4), ArrayArg::from_raw_parts(g_rec.clone(), npar * 4),
                        );
                    } else {
                        prep::rsort_kernel::launch_unchecked::<R>(
                            &client, CubeCount::Static(16128, 1, 1), CubeDim::new_1d(64),
                            ArrayArg::from_raw_parts(off.clone(), 16128), ArrayArg::from_raw_parts(histh.clone(), 16128),
                            ArrayArg::from_raw_parts(g_tmp.clone(), npar * 4), ArrayArg::from_raw_parts(g_rec.clone(), npar * 4),
                        );
                    }
                }
            }
        };
        // --warm S (2026-11-18): S seconds of preparations queued in groups of 16 (untimed) before the timed reps
        let warm: f64 = opt("--warm").map_or(Ok(0.0), |s| s.parse())?;
        let tw = Instant::now();
        while tw.elapsed().as_secs_f64() < warm {
            for _ in 0..16 {
                if prep3 == 0 {
                    histh = mk(vec![0u32; 16128]);
                    lcnt = mk(vec![0u32; 1]);
                }
                for k in 0..5 {
                    launch_prep(k, &histh, &lcnt);
                }
            }
            sync()?;
        }
        for prep_rep in 0..reps.max(1) {
            if prep3 == 0 {
                histh = mk(vec![0u32; 16128]);
                lcnt = mk(vec![0u32; 1]);
            }
            if !pburst || prep_rep == 0 {
                cubecl::future::block_on(client.sync()).map_err(|e| anyhow!("sync: {e:?}"))?;
            }
            let tl = Instant::now();
            if pt0.is_none() {
                pt0 = Some(tl);
            }
            for k in 0..5 {
                launch_prep(k, &histh, &lcnt);
            }
            if pburst {
                if prep_rep + 1 == reps.max(1) {
                    cubecl::future::block_on(client.sync()).map_err(|e| anyhow!("sync: {e:?}"))?;
                    tv.push(pt0.unwrap().elapsed().as_secs_f64() / reps.max(1) as f64);
                }
                continue;
            }
            cubecl::future::block_on(client.sync()).map_err(|e| anyhow!("sync: {e:?}"))?;
            tv.push(tl.elapsed().as_secs_f64());
        }
        tv.sort_by(|a, b| a.partial_cmp(b).unwrap());
        prep_secs = tv[tv.len() / 2];
        // --prep-prof: each of the five launches synced on its own (wall clock), and by the device's timestamps; the
        // chain of five by the device; and N chains queued with one synchronisation
        if args.iter().any(|a| a == "--prep-prof") {
            let n = reps.clamp(1, 200);
            let fresh = |h: &mut cubecl::server::Handle, l: &mut cubecl::server::Handle| {
                if prep3 == 0 {
                    *h = mk(vec![0u32; 16128]);
                    *l = mk(vec![0u32; 1]);
                }
            };
            let mut wall = vec![Vec::new(); 5];
            let mut dev = vec![Vec::new(); 5];
            let mut chain = Vec::new();
            for _ in 0..n {
                fresh(&mut histh, &mut lcnt);
                sync()?;
                for k in 0..5 {
                    let t = Instant::now();
                    launch_prep(k, &histh, &lcnt);
                    sync()?;
                    wall[k].push(t.elapsed().as_secs_f64());
                }
            }
            for _ in 0..n {
                fresh(&mut histh, &mut lcnt);
                sync()?;
                for k in 0..5 {
                    let (_, d) = client.profile(|| launch_prep(k, &histh, &lcnt), "prep").map_err(|e| anyhow!("profile: {e:?}"))?;
                    dev[k].push(cubecl::future::block_on(d.resolve()).duration().as_secs_f64());
                }
                fresh(&mut histh, &mut lcnt);
                sync()?;
                let (_, d) = client
                    .profile(
                        || {
                            for k in 0..5 {
                                launch_prep(k, &histh, &lcnt);
                            }
                        },
                        "chain",
                    )
                    .map_err(|e| anyhow!("profile: {e:?}"))?;
                chain.push(cubecl::future::block_on(d.resolve()).duration().as_secs_f64());
            }
            sync()?;
            let t = Instant::now();
            for _ in 0..n {
                fresh(&mut histh, &mut lcnt);
                for k in 0..5 {
                    launch_prep(k, &histh, &lcnt);
                }
            }
            sync()?;
            let q = t.elapsed().as_secs_f64() / n as f64;
            let pn = ["tdig", "hist", "scan", "scatter", "rsort"];
            let mut s = String::new();
            for k in 0..5 {
                s += &format!(" {} {:.1}/{:.1}", pn[k], med(&mut wall[k]) * 1e6, med(&mut dev[k]) * 1e6);
            }
            println!(
                "PREPPROF (prep3 {prep3}, {n} reps, µs medians, launch synced alone wall/device):{s}; chain of 5 device {:.1}; {n} chains queued, one sync, per chain {:.1}",
                med(&mut chain) * 1e6,
                q * 1e6
            );
        }
        // --pipe K: the production-like protocol. K super-units' preparation (5 launches) and main kernel (full mode,
        // records unless --noout) queued back to back with one synchronisation; every buffer allocated once and
        // reused (the first launch zeroes the per-super-unit counters, --prep3 1). The counts accumulate in one
        // buffer and must equal K times those of a single super-unit run the same way, which must equal the CPU
        // reference. --warm S: S seconds of the same work before (untimed) so the card is at its operating point.
        // Not included (a client would have them): the host's upload of each super-unit's tops (1.9 MB) and the
        // consumers of the records (the survivor checks, priced separately by the window's formula).
        if let Some(kp) = opt("--pipe") {
            let kp: usize = kp.parse()?;
            if prep3 != 1 || batches.len() != 1 || jobs.len() != 4032 {
                bail!("--pipe needs --prep3 1, the whole super-unit and one launch (--batch 4032)");
            }
            let warm: f64 = opt("--warm").map_or(Ok(0.0), |s| s.parse())?;
            let launch_main = |cnt: &cubecl::server::Handle, mode: u32, mnoout: bool| unsafe {
                macro_rules! go {
                    ($m:expr, $no:expr) => {
                        kernels::g2_kernel::launch_unchecked::<R>(
                            &client,
                            CubeCount::Static(4032, 1, 1),
                            CubeDim::new_1d(NT),
                            ArrayArg::from_raw_parts(g_rec.clone(), inp.par.len()),
                            ArrayArg::from_raw_parts(g_pseg.clone(), 64),
                            ArrayArg::from_raw_parts(tmask_k.clone(), inp.ts.len()),
                            ArrayArg::from_raw_parts(g_tdig.clone(), inp.ts.len() * 4),
                            ArrayArg::from_raw_parts(tseg.clone(), inp.tseg.len()),
                            ArrayArg::from_raw_parts(roots.clone(), NROOT),
                            ArrayArg::from_raw_parts(jobs_h[0].clone(), 2 * 4032),
                            ArrayArg::from_raw_parts(cnt.clone(), NCNT),
                            ArrayArg::from_raw_parts(out.clone(), nslab_cap as usize * SLAB as usize),
                            ArrayArg::from_raw_parts(slabz.clone(), 1),
                            ArrayArg::from_raw_parts(slabcnt.clone(), nslab_cap as usize),
                            nslab_cap,
                            $m,
                            $no,
                            w,
                            fill,
                            xpose,
                            ept,
                            ranks,
                            cut,
                            cmask,
                            tdg,
                        )
                    };
                }
                match (mode, mnoout) {
                    (0, _) => go!(0u32, true),
                    (1, false) => go!(1u32, false),
                    (1, true) => go!(1u32, true),
                    (_, false) => go!(2u32, false),
                    (_, true) => go!(2u32, true),
                }
            };
            let unit = |cnt: &cubecl::server::Handle| {
                for k in 0..5 {
                    launch_prep(k, &histh, &lcnt);
                }
                launch_main(cnt, 2, noout);
            };
            let rd = |h: &cubecl::server::Handle| -> Result<Vec<u64>> {
                Ok(u32::from_bytes(&client.read_one(h.clone()).map_err(|e| anyhow!("{e:?}"))?).iter().map(|&x| x as u64).collect())
            };
            let junk = mk(vec![0u32; NCNT]);
            let tw = Instant::now();
            let mut nw = 0usize;
            while tw.elapsed().as_secs_f64() < warm {
                for _ in 0..16 {
                    unit(&junk);
                }
                sync()?;
                nw += 16;
            }
            let c1 = mk(vec![0u32; NCNT]);
            unit(&c1);
            sync()?;
            let v1 = rd(&c1)?;
            let mut s1 = Counts::default();
            for d in 0..64 {
                s1.children += v1[d * 5];
                s1.chunks += v1[d * 5 + 1];
                s1.flat += v1[d * 5 + 2];
                s1.kept += v1[d * 5 + 3];
                s1.surv += v1[d * 5 + 4];
            }
            let one_ok = s1 == cref && v1[C_ERR_PLANE] + v1[C_ERR_PMAX] + v1[C_ERR_SLAB] == 0;
            // (the lane-slot counter wraps and is not compared; the 320 per-unit counters and the error counters are)
            let cmp_idx: Vec<usize> = (0..C_LSLOTS).chain([C_ERR_PLANE, C_ERR_PMAX, C_ERR_SLAB]).collect();
            // the K units' counts go to ceil(K / kb) buffers of at most kb units each, kb the most a u32 counter holds
            let kb = cmp_idx.iter().map(|&i| if v1[i] == 0 { u64::MAX } else { ((1u64 << 32) - 1) / v1[i] }).min().unwrap().min(kp as u64) as usize;
            let nb = kp.div_ceil(kb);
            let pcs: Vec<_> = (0..nb).map(|_| mk(vec![0u32; NCNT])).collect();
            sync()?;
            let t = Instant::now();
            for u in 0..kp {
                unit(&pcs[u / kb]);
            }
            sync()?;
            let el = t.elapsed().as_secs_f64();
            let mut k_ok = true;
            for (j, pc) in pcs.iter().enumerate() {
                let vk = rd(pc)?;
                let nu = (kp - j * kb).min(kb) as u64;
                k_ok &= cmp_idx.iter().all(|&i| vk[i] == v1[i] * nu);
            }
            // (a device-timestamp span over the K units read 0.016 ms per super-unit on RADV, against 3.4 ms of wall
            // clock: CubeCL's profile span over many submissions is not usable here, so it is not reported)
            let per = el / kp as f64;
            println!(
                "PIPE K {kp} super-units queued, one sync, buffers reused (counts in {nb} buffers; {}records; warm-up {nw} units in {:.1} s): wall {:.2} s, {:.3} ms per super-unit = {:.4} fs per admissible n; single unit's counts {} the CPU reference, K units' counts {} K x the single unit's",
                if noout { "no " } else { "" },
                tw.elapsed().as_secs_f64(),
                el,
                per * 1e3,
                per / inp.adm * 1e15,
                if one_ok { "EQUAL to" } else { "DIFFER from" },
                if k_ok { "EQUAL to" } else { "DIFFER from" }
            );
            if !(one_ok && k_ok) {
                all_prep_bad = true;
            }
            // --pipe-parts: the components at the same operating point, each queued K times with one sync (wall
            // per launch; the counters of each mode checked against K x the CPU reference's for that mode)
            if args.iter().any(|a| a == "--pipe-parts") {
                let zero1 = || unsafe {
                    prep::zero1_kernel::launch_unchecked::<R>(&client, CubeCount::Static(1, 1, 1), CubeDim::new_1d(64), ArrayArg::from_raw_parts(slabz.clone(), 1));
                };
                sync()?;
                let t = Instant::now();
                for _ in 0..kp {
                    for k in 0..5 {
                        launch_prep(k, &histh, &lcnt);
                    }
                }
                sync()?;
                let tprep = t.elapsed().as_secs_f64() / kp as f64;
                let mut parts = format!("prep {:.3}", tprep * 1e3);
                let mut parts_ok = true;
                // (K capped at the single buffer's limit for skip-off, whose kept = flat; the others like the pipe)
                let kq = kp.min(kb);
                for (mode, mno, nm) in [(0u32, true, "probes-off"), (1, false, "skip-off"), (2, true, "full-norec"), (2, false, "full")] {
                    let pcm = mk(vec![0u32; NCNT]);
                    sync()?;
                    let t = Instant::now();
                    for _ in 0..kq {
                        if !mno {
                            zero1();
                        }
                        launch_main(&pcm, mode, mno);
                    }
                    sync()?;
                    let tm = t.elapsed().as_secs_f64() / kq as f64;
                    let v = rd(&pcm)?;
                    let mut sc = Counts::default();
                    for d in 0..64 {
                        sc.children += v[d * 5];
                        sc.chunks += v[d * 5 + 1];
                        sc.flat += v[d * 5 + 2];
                        sc.kept += v[d * 5 + 3];
                        sc.surv += v[d * 5 + 4];
                    }
                    let k = kq as u64;
                    let want_c = Counts {
                        children: cref.children * k,
                        chunks: cref.chunks * k,
                        flat: if mode == 0 { 0 } else { cref.flat * k },
                        kept: if mode == 0 { 0 } else if mode == 1 { cref.flat * k } else { cref.kept * k },
                        surv: if mode == 0 { 0 } else { cref.surv * k },
                    };
                    let ok = sc == want_c && v[C_ERR_PLANE] + v[C_ERR_PMAX] + v[C_ERR_SLAB] == 0;
                    parts_ok &= ok;
                    parts += &format!(", {nm} {:.3}{}", tm * 1e3, if ok { "" } else { " (COUNTS DIFFER)" });
                }
                println!("PIPEPARTS K {kq} each queued, one sync, ms per launch: {parts}; counts {}", if parts_ok { "EQUAL to K x the CPU reference" } else { "DIFFER" });
                if !parts_ok {
                    all_prep_bad = true;
                }
            }
        }
        let gr = u32::from_bytes(&client.read_one(g_rec.clone()).map_err(|e| anyhow!("{e:?}"))?).to_vec();
        let gd = u32::from_bytes(&client.read_one(g_tdig.clone()).map_err(|e| anyhow!("{e:?}"))?).to_vec();
        let gp = u32::from_bytes(&client.read_one(g_pseg.clone()).map_err(|e| anyhow!("{e:?}"))?).to_vec();
        let gh = u32::from_bytes(&client.read_one(histh.clone()).map_err(|e| anyhow!("{e:?}"))?).to_vec();
        let total: u64 = gh.iter().map(|&x| x as u64).sum();
        let nl = u32::from_bytes(&client.read_one(lcnt.clone()).map_err(|e| anyhow!("{e:?}"))?)[0];
        let ok = total == npar as u64 && gp == inp.pseg && gr == rec_host && gd == tdig_host && (prep2 == 0 || nl as usize == npar);
        println!("prep: {}; {}", if prep2 == 1 { format!("one root pass + list scatter (list {nl} of {npar})") } else { "two root passes".into() }, if prep3 == 1 { "zeroing on the device (prep3 1)" } else { "zeroed buffers uploaded per prep (prep3 0)" });
        println!(
            "PREP (GPU, 5 launches) median {:.3} ms ({} reps) for {npar} parents from {nroots} roots: {:.1} ps per parent; largest bucket {}; order, records, class segments and top digits {}",
            prep_secs * 1e3,
            tv.len(),
            prep_secs * 1e12 / npar as f64,
            gh.iter().max().unwrap_or(&0),
            if ok { "EQUAL to the CPU's" } else { "DIFFER from the CPU's" }
        );
        if args.iter().any(|a| a == "--prep-prof") {
            // the bucket sizes (what the rank sort's cost depends on)
            let mut cls = [0u64; 8];
            let (mut s2, mut it64) = (0u64, 0u64);
            for &x in &gh {
                let x = x as u64;
                s2 += x * x;
                it64 += x.div_ceil(64) * x;
                cls[(64 - x.leading_zeros() as usize).min(7 + 3).saturating_sub(3).min(7)] += 1;
            }
            println!("BUCKETS 16128: sum n^2 {s2}, sum ceil(n/64)*n {it64}; by size <8,<16,<32,<64,<128,<256,<512,>=512: {cls:?}");
        }
        if !ok {
            all_prep_bad = true;
        }
        (g_rec, g_pseg, g_tdig)
    } else {
        (rec, pseg, tdig)
    };
    // --cuda-src DIR (with the cubecl-cuda feature, no CUDA device needed): the kernel's definition from this runtime,
    // compiled by CubeCL's CUDA compiler (as cubecl-cuda would for an sm_86 card: warp 32, grid constants, fast
    // math) and written to DIR/g2_m<mode>[_noout]_w<W>.cu, for NVRTC/ptxas offline; then exit
    #[cfg(feature = "cubecl-cuda")]
    if let Some(dir) = opt("--cuda-src") {
        use cubecl::Compiler;
        std::fs::create_dir_all(&dir)?;
        for &mode in modes {
            let mut settings = cubecl::prelude::KernelSettings::default().cube_dim(CubeDim::new_1d(NT));
            settings.address_type = cubecl::prelude::AddressType::U32;
            let mut launcher = cubecl::prelude::KernelLauncher::<R>::new(settings.clone());
            launcher.with_scope(|scope| scope.device_properties(client.properties()));
            let jl = jobs.len().min(batch);
            macro_rules! reg {
                ($t:ty, $h:expr, $n:expr) => {
                    <$t as LaunchArg>::register(unsafe { ArrayArg::from_raw_parts($h.clone(), $n) }, &mut launcher)
                };
            }
            let a0 = reg!(Array<Vector<u32, Const<4>>>, rec, inp.par.len());
            let a1 = reg!(Array<u32>, pseg, 64);
            let a2 = reg!(Array<u64>, tmask_k, inp.ts.len());
            let a3 = reg!(Array<u32>, tdig, inp.ts.len() * 4);
            let a4 = reg!(Array<u32>, tseg, inp.tseg.len());
            let a5 = reg!(Array<u32>, roots, NROOT);
            let a6 = reg!(Array<u32>, jobs_h[0], 2 * jl);
            let cnt = mk(vec![0u32; NCNT]);
            let slabn = mk(vec![0u32; 1]);
            let a7 = reg!(Array<Atomic<u32>>, cnt, NCNT);
            let a8 = reg!(Array<Vector<u32, Const<4>>>, out, nslab_cap as usize * SLAB as usize);
            let a9 = reg!(Array<Atomic<u32>>, slabn, 1);
            let a10 = reg!(Array<u32>, slabcnt, nslab_cap as usize);
            let a11 = <u32 as LaunchArg>::register(nslab_cap, &mut launcher);
            let k = kernels::g2_kernel::G2Kernel::<R>::new(
                settings, client.clone(), a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11,
                mode.min(2), noout || mode == 0, w, fill, xpose, ept, ranks, cut, cmask, tdg,
            );
            let def = k.define();
            let mut comp = cubecl::cuda::CudaCompiler::default();
            let mut o = <cubecl::cuda::CudaCompiler as Compiler>::CompilationOptions::default();
            o.warp_size = 32;
            o.supports_features.grid_constants = true;
            o.supports_features.fast_math = true;
            let src = comp
                .compile(def, &o, cubecl::prelude::ExecutionMode::Unchecked, k.address_type())
                .map_err(|e| anyhow!("cuda compile: {e:?}"))?;
            let f = format!("{dir}/g2_m{mode}{}_w{w}_tdig{tdg}.cu", if noout && mode != 0 { "_noout" } else { "" });
            std::fs::write(&f, format!("{src}"))?;
            println!("CUDA source: {f}");
        }
        return Ok(());
    }
    let names = ["probes off", "skip off", "full"];
    let mut times = [0f64; 3];
    let mut all_ok = !all_prep_bad;
    for &mode in modes {
        let mut tv = Vec::new();
        let mut s = Counts::default();
        let mut hc_tot = vec![0u64; NCNT];
        let mut pairs = Vec::new();
        let mut nrec = 0u64;
        let mut nslabs = 0u64;
        // --burst (with --no-sets): all reps' launches queued back to back and synced once, the time divided by the
        // reps: no per-sync latency of the runtime in the number (wall-clock syncs quantize CubeCL's timings)
        let burst = args.iter().any(|a| a == "--burst") && no_sets;
        let mut burst_t0: Option<Instant> = None;
        let mut burst_pending = Vec::new();
        // the launch of one batch in this mode (2026-11-18: a closure, shared by the warm-up and the timed reps)
        let launch_mode = |bi: usize, cnt: &cubecl::server::Handle, slabn: &cubecl::server::Handle| unsafe {
            let bj = batches[bi];
                macro_rules! go {
                    ($m:expr, $no:expr) => {
                        kernels::g2_kernel::launch_unchecked::<R>(
                            &client,
                            CubeCount::Static(bj.len() as u32, 1, 1),
                            CubeDim::new_1d(NT),
                            ArrayArg::from_raw_parts(rec.clone(), inp.par.len()),
                            ArrayArg::from_raw_parts(pseg.clone(), 64),
                            ArrayArg::from_raw_parts(tmask_k.clone(), inp.ts.len()),
                            ArrayArg::from_raw_parts(tdig.clone(), inp.ts.len() * 4),
                            ArrayArg::from_raw_parts(tseg.clone(), inp.tseg.len()),
                            ArrayArg::from_raw_parts(roots.clone(), NROOT),
                            ArrayArg::from_raw_parts(jobs_h[bi].clone(), 2 * bj.len()),
                            ArrayArg::from_raw_parts(cnt.clone(), NCNT),
                            ArrayArg::from_raw_parts(out.clone(), nslab_cap as usize * SLAB as usize),
                            ArrayArg::from_raw_parts(slabn.clone(), 1),
                            ArrayArg::from_raw_parts(slabcnt.clone(), nslab_cap as usize),
                            nslab_cap,
                            $m,
                            $no,
                            w,
                            fill,
                            xpose,
                            ept,
                            ranks,
                            cut,
                            cmask,
                            tdg,
                        )
                    };
                }
                match (mode, noout) {
                    (0, _) => go!(0u32, true),
                    (1, false) => go!(1u32, false),
                    (1, true) => go!(1u32, true),
                    (_, false) => go!(2u32, false),
                    (_, true) => go!(2u32, true),
                }
        };
        // --warm-mode S (2026-11-18): S seconds of this mode's launches before its timed reps (untimed, counts
        // discarded), so that the reps run at the card's operating point and not on its way up from idle
        let wm: f64 = opt("--warm-mode").map_or(Ok(0.0), |s| s.parse())?;
        let tw = Instant::now();
        while tw.elapsed().as_secs_f64() < wm {
            for bi in 0..batches.len() {
                let cnt = mk(vec![0u32; NCNT]);
                let slabn = mk(vec![0u32; 1]);
                launch_mode(bi, &cnt, &slabn);
                sync()?;
            }
        }
        for rep in 0..reps.max(1) {
            let last_rep = rep + 1 == reps.max(1);
            let mut tsum = 0f64;
            let mut rep_t0: Option<Instant> = None;
            let mut pending = Vec::new();
            for bi in 0..batches.len() {
                let cnt = mk(vec![0u32; NCNT]);
                let slabn = mk(vec![0u32; 1]);
                let tl = Instant::now();
                launch_mode(bi, &cnt, &slabn);
                if burst {
                    if burst_t0.is_none() {
                        burst_t0 = Some(tl);
                    }
                    if last_rep {
                        burst_pending.push(cnt);
                    }
                    if !(last_rep && bi + 1 == batches.len()) {
                        continue;
                    }
                    cubecl::future::block_on(client.sync()).map_err(|e| anyhow!("sync: {e:?}"))?;
                    let per = burst_t0.take().unwrap().elapsed().as_secs_f64() / reps.max(1) as f64;
                    for h in burst_pending.drain(..) {
                        let hc = u32::from_bytes(&client.read_one(h).map_err(|e| anyhow!("{e:?}"))?).to_vec();
                        for (i, &x) in hc.iter().enumerate() {
                            hc_tot[i] += x as u64;
                        }
                    }
                    tv.push(per);
                    continue;
                }
                if no_sets {
                    // timing runs: the launches of one rep are queued back to back and synced once (no tail per
                    // launch); their counters are read after the rep
                    if rep_t0.is_none() {
                        rep_t0 = Some(tl);
                    }
                    pending.push(cnt);
                    if bi + 1 < batches.len() {
                        continue;
                    }
                    cubecl::future::block_on(client.sync()).map_err(|e| anyhow!("sync: {e:?}"))?;
                    tsum += rep_t0.take().unwrap().elapsed().as_secs_f64();
                    if last_rep {
                        for h in pending.drain(..) {
                            let hc = u32::from_bytes(&client.read_one(h).map_err(|e| anyhow!("{e:?}"))?).to_vec();
                            for (i, &x) in hc.iter().enumerate() {
                                hc_tot[i] += x as u64;
                            }
                        }
                    }
                    pending.clear();
                    continue;
                }
                cubecl::future::block_on(client.sync()).map_err(|e| anyhow!("sync: {e:?}"))?;
                tsum += tl.elapsed().as_secs_f64();
                if !last_rep {
                    continue;
                }
                let hc = u32::from_bytes(&client.read_one(cnt).map_err(|e| anyhow!("{e:?}"))?).to_vec();
                if mode == 0 && bi == 0 && args.iter().any(|a| a == "--debug-lanes") {
                    let ob = u32::from_bytes(&client.read_one(out.clone()).map_err(|e| anyhow!("{e:?}"))?).to_vec();
                    for t in 0..NT as usize {
                        println!("LANE t {} lane {} plane_dim {} plane_sum(1) {}", ob[4 * t], ob[4 * t + 1], ob[4 * t + 2], ob[4 * t + 3]);
                    }
                }
                for (i, &x) in hc.iter().enumerate() {
                    hc_tot[i] += x as u64;
                }
                if mode >= 1 && !noout && !no_sets {
                    let ns = u32::from_bytes(&client.read_one(slabn).map_err(|e| anyhow!("{e:?}"))?)[0];
                    nslabs += ns as u64;
                    let sc = u32::from_bytes(&client.read_one(slabcnt.clone()).map_err(|e| anyhow!("{e:?}"))?).to_vec();
                    let ob = u32::from_bytes(&client.read_one(out.clone()).map_err(|e| anyhow!("{e:?}"))?).to_vec();
                    for sidx in 0..ns.min(nslab_cap) as usize {
                        for r in 0..sc[sidx] as usize {
                            let o = (sidx * SLAB as usize + r) * 4;
                            nrec += 1;
                            let (du, ps, pf) = (ob[o] >> 16, ob[o] & 0xFFFF, ob[o + 1]);
                            let wd = ob[o + 2] as u64 | ((ob[o + 3] as u64) << 32);
                            let cl = inp.par[pf as usize].cls;
                            let pr = probes(inp, cl, du);
                            let ti = pr[ps as usize];
                            let mut k = 0;
                            let mut j = pf as usize;
                            while j < inp.pseg[cl as usize + 1] as usize && k < 64 {
                                if child_mask(inp.par[j].mask, inp.par[j].cacc, du) != 0 {
                                    if (wd >> k) & 1 != 0 {
                                        pairs.push((ti, j as u32));
                                    }
                                    k += 1;
                                }
                                j += 1;
                            }
                        }
                    }
                }
            }
            if !burst {
                tv.push(tsum);
            }
        }
        tv.sort_by(|a, b| a.partial_cmp(b).unwrap());
        let med = tv[tv.len() / 2];
        times[mode as usize] = med;
        for d in 0..64 {
            s.children += hc_tot[d * 5];
            s.chunks += hc_tot[d * 5 + 1];
            s.flat += hc_tot[d * 5 + 2];
            s.kept += hc_tot[d * 5 + 3];
            s.surv += hc_tot[d * 5 + 4];
        }
        println!(
            "MODE {:<10} median {:.3} ms ({} reps) {:?} lane slots {} errors: plane {} pmax {} slab {}",
            names[mode as usize],
            med * 1e3,
            tv.len(),
            s,
            hc_tot[C_LSLOTS],
            hc_tot[C_ERR_PLANE],
            hc_tot[C_ERR_PMAX],
            hc_tot[C_ERR_SLAB]
        );
        if hc_tot[C_ERR_PLANE] + hc_tot[C_ERR_PMAX] + hc_tot[C_ERR_SLAB] != 0 {
            println!("ERRORS reported by the kernel: results not valid");
            all_ok = false;
        }
        let want_c = Counts {
            flat: if mode == 0 { 0 } else { cref.flat },
            kept: if mode == 0 { 0 } else if mode == 1 { cref.flat } else { cref.kept },
            surv: if mode == 0 { 0 } else { cref.surv },
            ..cref
        };
        let cok = s == want_c;
        println!("COUNTS {}: {}", names[mode as usize], if cok { "EQUAL to the CPU reference" } else { "DIFFER" });
        all_ok &= cok;
        if mode >= 1 && !noout && !no_sets {
            println!("records {nrec} in {nslabs} slabs ({:.2} survivors per record)", pairs.len() as f64 / nrec.max(1) as f64);
            let (g, cl) = sets(inp, &pairs);
            all_ok &= compare(names[mode as usize], &g, want, cl);
        }
    }
    if modes.contains(&0) && modes.contains(&2) {
        let kept = cref.kept as f64;
        println!(
            "RESULT ps per child {:.2}; ps per kept word all-in {:.2}; kernel full {:.4} fs per admissible n (scaled by jobs/4032)",
            times[0] * 1e12 / cref.children as f64,
            (times[2] - times[0]) * 1e12 / kept,
            times[2] / (inp.adm * jobs.len() as f64 / 4032.0) * 1e15
        );
        if prep_secs > 0.0 {
            // the prep is per super-unit: scale it to the jobs run as the kernel is (exact for the whole super-unit)
            let share = jobs.len() as f64 / 4032.0;
            let e2e = prep_secs * share + times[2];
            println!(
                "RESULT end-to-end (GPU prep + full) {:.3} ms = {:.4} fs per admissible n (tops and survivor checks not included){}",
                e2e * 1e3,
                e2e / (inp.adm * share) * 1e15,
                if jobs.len() == 4032 { "" } else { "; jobs scaled: a part of the super-unit" }
            );
        }
    }
    if compile_only {
        println!("COMPILE-ONLY run done");
        return Ok(());
    }
    println!("{}", if all_ok { "ALL CHECKS PASSED" } else { "SOME CHECK FAILED" });
    if !all_ok {
        std::process::exit(1);
    }
    Ok(())
}
