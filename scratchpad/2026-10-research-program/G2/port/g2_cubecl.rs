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
/// Counter layout: 64 units x 5 (children, chunks, flat, kept, surv), then extras.
const C_LSLOTS: usize = 320;
const C_ERR_PLANE: usize = 321;
const C_ERR_PMAX: usize = 322;
const C_ERR_SLAB: usize = 323;
const NCNT: usize = 328;

// ------------------------------------------------------------------------------------------------ device
mod kernels {
    use super::{C_ERR_PLANE, C_ERR_PMAX, C_ERR_SLAB, C_LSLOTS, M, MAXPOP, NT, PMAX, SLAB};
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

    #[cube]
    fn child_mask(pm: u64, cacc: u32, d: u32) -> u64 {
        let e2 = ((cacc & 63u32) + ((cacc >> 16u32) & 63u32) * d) & 63u32;
        let e3 = (((cacc >> 8u32) & 63u32) + ((cacc >> 24u32) & 63u32) * d) & 63u32;
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
        par_m: &Array<u64>,
        par_c: &Array<u32>,
        pseg: &Array<u32>,
        tmask: &Array<u64>,
        tseg: &Array<u32>,
        roots: &Array<u32>,
        jobs: &Array<u32>,
        cnt: &mut Array<Atomic<u32>>,
        out: &mut Array<u32>,
        slabn: &mut Array<Atomic<u32>>,
        slabcnt: &mut Array<u32>,
        nslab_cap: u32,
        #[comptime] mode: u32,
        #[comptime] noout: bool,
        #[comptime] w: u32,
        #[comptime] fill: u32,
        #[comptime] xpose: u32,
        #[comptime] ept: u32,
    ) {
        let npl = comptime!(NT / w);
        let segs = comptime!(64 / w); // ballot segments per chunk (W <= 64)
        let mut pend_p = SharedMemory::<u32>::new(comptime!((fill + NT) as usize));
        let mut sl = SharedMemory::<u32>::new(comptime!((64 * 16 * 2) as usize)); // [(v*16+q)*2 + half]
        let slt = SharedMemory::<Atomic<u32>>::new(comptime!((if w < 32 { 64 * 16 * 2 } else { 1 }) as usize));
        let comm = SharedMemory::<Atomic<u32>>::new(32usize); // [2q + half]
        let mut prob_d = SharedMemory::<u32>::new(comptime!((PMAX * 4) as usize));
        let mut plist = SharedMemory::<u32>::new(comptime!(PMAX as usize));
        let mut wcnt = SharedMemory::<u32>::new(comptime!((2 * NT / w) as usize));
        let s_nl = SharedMemory::<Atomic<u32>>::new(1usize);
        let mut s_np = SharedMemory::<u32>::new(1usize);

        let t = UNIT_POS_X;
        let lane = UNIT_POS_PLANE;
        let pl = t / w;
        let c = jobs[(2u32 * CUBE_POS_X) as usize];
        let d = jobs[(2u32 * CUBE_POS_X + 1u32) as usize];
        let cc = (c + d) % M;

        if PLANE_DIM != w || t % w != lane {
            cnt[C_ERR_PLANE].fetch_add(1u32);
        }
        if comptime!(mode == 0) {
            // lane map of cube 0, for the host's --debug-lanes (mode 0 writes no records)
            if CUBE_POS_X == 0u32 {
                out[(t * 4u32) as usize] = t;
                out[(t * 4u32 + 1u32) as usize] = lane;
                out[(t * 4u32 + 2u32) as usize] = PLANE_DIM;
                out[(t * 4u32 + 3u32) as usize] = plane_sum(1u32);
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
            comm[t as usize].store(0u32);
        }
        sync_cube();
        // probes: the 8 compatible top classes of unit d, each probe's digits as 20 6-bit fields (5 per word),
        // padded with its first digit (OR is idempotent)
        let mut base = 0u32;
        for i in 0..8u32 {
            let ct = (roots[i as usize] + M - cc) % M;
            let s = (d * M + ct) * 2u32;
            let b0 = tseg[s as usize];
            let b1 = tseg[(s + 1u32) as usize];
            let mut j = t;
            while j < b1 - b0 {
                if base + j < PMAX {
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
                    #[unroll]
                    for k in 0..4u32 {
                        prob_d[((base + j) * 4u32 + k) as usize] = dw[k as usize];
                    }
                }
                j += NT;
            }
            base += b1 - b0;
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
        let mut par = 0u32;
        // no `loop`/`break`: cubecl-spirv 0.10 emitted a conditional branch without OpSelectionMerge for them
        let mut going = true;
        while going {
            // phase 1: append children of NT parents at a time (ordered) until 16 chunks are pending or the class ends
            while npend < fill && cur < pe {
                let idx = cur + t;
                let mut m = 0u64;
                if idx < pe {
                    m = child_mask(par_m[idx as usize], par_c[idx as usize], d);
                }
                let f = select(m != 0u64, 1u32, 0u32);
                let r = plane_exclusive_sum(f);
                let tot = plane_sum(f);
                if lane == 0u32 {
                    wcnt[(par * npl + pl) as usize] = tot;
                }
                sync_cube();
                let mut off = 0u32;
                let mut all = 0u32;
                for i in 0..npl {
                    let x = wcnt[(par * npl + i) as usize];
                    off += select(i < pl, x, 0u32);
                    all += x;
                }
                if m != 0u64 {
                    pend_p[(npend + off + r) as usize] = idx;
                }
                npend += all;
                par ^= 1u32;
                cur += NT;
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
                    while z < 2048u32 {
                        slt[z as usize].store(0u32);
                        z += NT;
                    }
                    sync_cube();
                }
                // phase 2: transpose by ballots. Plane task i covers chunk q, segment s (members s*W .. s*W+W-1).
                for i in 0..4u32 {
                    let task = pl + npl * i;
                    let q = task / segs;
                    let sg = task % segs;
                    let mi = q * 64u32 + sg * w + lane;
                    let mut m = 0u64;
                    if q < nch && mi < ntake {
                        let pi = pend_p[mi as usize];
                        m = child_mask(par_m[pi as usize], par_c[pi as usize], d);
                    }
                    if comptime!(xpose == 0) {
                        for v in 0..64u32 {
                            let bal = plane_ballot(((m >> u64::cast_from(v)) & 1u64) != 0u64);
                            if lane == v % w && q < nch {
                                let row = (v * 16u32 + q) * 2u32;
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
                        let mut x = m;
                        #[unroll]
                        for st in 0..comptime!(w.trailing_zeros()) {
                            let j = comptime!(w >> (st + 1));
                            let mj = comptime!(stage_mask(w >> (st + 1)));
                            let ylo = plane_shuffle_xor(u32::cast_from(x & 0xFFFF_FFFFu64), j);
                            let yhi = plane_shuffle_xor(u32::cast_from(x >> 32u64), j);
                            let y = u64::cast_from(ylo) | (u64::cast_from(yhi) << 32u64);
                            if (lane & j) != 0u32 {
                                x = (x & mj) | ((y >> comptime!(j as u64)) & comptime!(!stage_mask(w >> (st + 1))));
                            } else {
                                x = (x & comptime!(!stage_mask(w >> (st + 1)))) | ((y << comptime!(j as u64)) & mj);
                            }
                        }
                        if q < nch {
                            #[unroll]
                            for sb in 0..segs {
                                let v = comptime!(sb * w) + lane;
                                let row = (v * 16u32 + q) * 2u32;
                                if comptime!(w == 64) {
                                    sl[row as usize] = u32::cast_from(x & 0xFFFF_FFFFu64);
                                    sl[(row + 1u32) as usize] = u32::cast_from(x >> 32u64);
                                } else if comptime!(w == 32) {
                                    sl[(row + sg) as usize] = u32::cast_from((x >> comptime!((sb * 32) as u64)) & 0xFFFF_FFFFu64);
                                } else {
                                    let bit = sg * w;
                                    let piece = u32::cast_from((x >> comptime!((sb * w) as u64)) & comptime!((1u64 << w) - 1));
                                    slt[(row + bit / 32u32) as usize].fetch_or(piece << (bit % 32u32));
                                }
                            }
                        }
                    }
                }
                sync_cube();
                if comptime!(w < 32) {
                    let mut z = t;
                    while z < 2048u32 {
                        sl[z as usize] = slt[z as usize].load();
                        z += NT;
                    }
                    sync_cube();
                }
                // common masks: digit v is common to chunk q iff its slice equals the chunk's valid mask
                {
                    let mut j = t;
                    while j < 1024u32 {
                        let q = j / 64u32;
                        let v = j % 64u32;
                        if q < nch {
                            let nq = min(64u32, ntake - q * 64u32);
                            let vlo = select(nq >= 32u32, 0xFFFF_FFFFu32, (1u32 << (nq % 32u32)) - 1u32);
                            let vhi = select(nq == 64u32, 0xFFFF_FFFFu32, select(nq > 32u32, (1u32 << (nq % 32u32)) - 1u32, 0u32));
                            let row = (v * 16u32 + q) * 2u32;
                            if sl[row as usize] == vlo && sl[(row + 1u32) as usize] == vhi {
                                comm[(2u32 * q + v / 32u32) as usize].fetch_or(1u32 << (v % 32u32));
                            }
                        }
                        j += NT;
                    }
                }
                sync_cube();
                if comptime!(mode != 0) {
                    // phase 3a: per probe, its 16-bit mask of chunks kept by the common-mask skip -> list
                    let mut pp = t;
                    while pp < nprobe {
                        let mut tlo = 0u32;
                        let mut thi = 0u32;
                        #[unroll]
                        for k in 0..MAXPOP {
                            let dg = (prob_d[(pp * 4u32 + comptime!(k / 5)) as usize] >> comptime!(6 * (k % 5))) & 63u32;
                            if dg < 32u32 {
                                tlo |= 1u32 << dg;
                            } else {
                                thi |= 1u32 << (dg - 32u32);
                            }
                        }
                        let mut km = 0u32;
                        for qq in 0..nch {
                            let hit = (comm[(2u32 * qq) as usize].load() & tlo) | (comm[(2u32 * qq + 1u32) as usize].load() & thi);
                            let mut keepq = hit == 0u32;
                            if comptime!(mode == 1) {
                                keepq = true;
                            }
                            if keepq {
                                km |= 1u32 << qq;
                            }
                        }
                        if km != 0u32 {
                            let slot = s_nl[0usize].fetch_add(1u32);
                            plist[slot as usize] = pp | (km << 16u32);
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
                    let pend0 = pend_p[min(q * 64u32, comptime!(fill + NT - 1)) as usize];
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
                            let e = e0 + st + comptime!(16 * h);
                            if e < nlist {
                                let ent = plist[e as usize];
                                let p = ent & 0xFFFFu32;
                                pk[h as usize] = p;
                                if ((ent >> (16u32 + q)) & 1u32) != 0u32 {
                                    my_kept += 1u32;
                                    let mut alo = 0u32;
                                    let mut ahi = 0u32;
                                    let mut dws = Array::<u32>::new(4usize);
                                    #[unroll]
                                    for k4 in 0..4u32 {
                                        dws[k4 as usize] = prob_d[(p * 4u32 + k4) as usize];
                                    }
                                    #[unroll]
                                    for k in 0..MAXPOP {
                                        let dg = (dws[comptime!(k / 5) as usize] >> comptime!(6 * (k % 5))) & 63u32;
                                        let row = (dg * 16u32 + q) * 2u32;
                                        alo |= sl[row as usize];
                                        ahi |= sl[(row + 1u32) as usize];
                                    }
                                    wlo[h as usize] = !alo & vlo;
                                    whi[h as usize] = !ahi & vhi;
                                }
                            }
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
                            let na = plane_sum(fa);
                            let nn = na + plane_sum(fb);
                            let ra = plane_exclusive_sum(fa);
                            let rb = plane_exclusive_sum(fb);
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
                                        let o = (sbase + ra) * 4u32;
                                        out[o as usize] = pk[0usize] | (d << 16u32);
                                        out[(o + 1u32) as usize] = pend0;
                                        out[(o + 2u32) as usize] = wlo[0usize];
                                        out[(o + 3u32) as usize] = whi[0usize];
                                    }
                                    if nzb {
                                        let o = (sbase + na + rb) * 4u32;
                                        out[o as usize] = pk[1usize] | (d << 16u32);
                                        out[(o + 1u32) as usize] = pend0;
                                        out[(o + 2u32) as usize] = wlo[1usize];
                                        out[(o + 3u32) as usize] = whi[1usize];
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
                let mut keep = 0u32;
                if t < left {
                    keep = pend_p[(ntake + t) as usize];
                }
                sync_cube();
                if t < left {
                    pend_p[t as usize] = keep;
                }
                if t == 0u32 {
                    s_nl[0usize].store(0u32);
                }
                if t >= 32u32 && t < 64u32 {
                    comm[(t - 32u32) as usize].store(0u32);
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

    /// The parent of root r4 under π′ (pip): (mask, cacc, key), or mask 0 when a digit 0..8 repeats.
    #[cube]
    fn parent(r4: u32, pip: u64, rank: &Array<u32>) -> (u64, u32, u32) {
        let mask60 = (1u64 << 60u64) - 1u64;
        let r = u64::cast_from(r4) + (pip << 24u64);
        let s = (r * r) & mask60;
        let c = (s * r) & mask60;
        let mut m = 0u64;
        let mut ok = true;
        #[unroll]
        for j in 0..9u32 {
            let a = 1u64 << u64::cast_from(dig(s, j));
            let b = 1u64 << u64::cast_from(dig(c, j));
            if (m & a) != 0u64 || (m & b) != 0u64 || a == b {
                ok = false;
            }
            m |= a | b;
        }
        let r0 = u32::cast_from(r & 63u64);
        let cacc = dig(s, 9u32) | (dig(c, 9u32) << 8u32) | (((2u32 * r0) & 63u32) << 16u32) | (((3u32 * r0 * r0) & 63u32) << 24u32);
        let cls = u32::cast_from(r % 63u64);
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
        par_m: &mut Array<u64>,
        par_c: &mut Array<u32>,
        par_r: &mut Array<u32>,
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
                par_m[slot as usize] = m;
                par_c[slot as usize] = c;
                par_r[slot as usize] = r4;
            }
        }
    }

    /// One unit per bucket: insertion sort of its segment by r4 (the CPU's stable order).
    #[cube(launch_unchecked)]
    pub fn bsort_kernel(off: &Array<u32>, hist: &Array<u32>, par_m: &mut Array<u64>, par_c: &mut Array<u32>, par_r: &mut Array<u32>) {
        let k = ABSOLUTE_POS_X;
        if k < 16128u32 {
            let b0 = off[k as usize];
            let n = hist[k as usize];
            let mut i = 1u32;
            while i < n {
                let rr = par_r[(b0 + i) as usize];
                let mm = par_m[(b0 + i) as usize];
                let cc = par_c[(b0 + i) as usize];
                let mut j = i;
                let mut moving = true;
                while moving {
                    if j == 0u32 {
                        moving = false;
                    } else if par_r[(b0 + j - 1u32) as usize] <= rr {
                        moving = false;
                    } else {
                        par_r[(b0 + j) as usize] = par_r[(b0 + j - 1u32) as usize];
                        par_m[(b0 + j) as usize] = par_m[(b0 + j - 1u32) as usize];
                        par_c[(b0 + j) as usize] = par_c[(b0 + j - 1u32) as usize];
                        j -= 1u32;
                    }
                }
                par_r[(b0 + j) as usize] = rr;
                par_m[(b0 + j) as usize] = mm;
                par_c[(b0 + j) as usize] = cc;
                i += 1u32;
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

    // ---------------- GPU
    let ctx = CubeclContext::new_default()?;
    let name = ctx.device_name();
    #[allow(irrefutable_let_patterns)]
    let CubeclContext::Wgpu { client, .. } = ctx else { unreachable!() };
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
    println!("device: {name}; plane size min {wmin} max {w}; compiler: {}", if cfg!(feature = "cubecl-spirv") { "SPIR-V (cubecl-spirv)" } else { "WGSL (naga)" });
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
    let dbg = std::env::var("G2_DEBUG_SYNC").is_ok();
    let chk = |what: &str| {
        if dbg {
            let r = cubecl::future::block_on(client.sync());
            eprintln!("debug sync after {what}: {:?}", r.is_ok());
        }
    };
    chk("init");
    let mk = |v: Vec<u32>| client.create(cubecl::bytes::Bytes::from_elems(v));
    let mut all_prep_bad = false;
    let par_m = client.create(cubecl::bytes::Bytes::from_elems(inp.par.iter().map(|p| p.mask).collect::<Vec<u64>>()));
    chk("par_m");
    let par_c = mk(inp.par.iter().map(|p| p.cacc).collect());
    chk("par_c");
    let pseg = mk(inp.pseg.clone());
    let tmask = client.create(cubecl::bytes::Bytes::from_elems(inp.ts.iter().map(|t| t.mask).collect::<Vec<u64>>()));
    let tseg = mk(inp.tseg.clone());
    let roots = mk(ROOTS.to_vec());
    chk("tseg/roots/tmask");
    // jobs in launches of `--batch` (default: all at once; lavapipe needs smaller output buffers)
    let batch: usize = opt("--batch").map_or(Ok(jobs.len()), |s| s.parse())?;
    let batches: Vec<&[(u32, u32)]> = jobs.chunks(batch.max(1)).collect();
    let mut nslab_cap = 0u32;
    for bj in &batches {
        let mut cb = Counts::default();
        let mut scratch = Vec::new();
        for &(c, d) in bj.iter() {
            cpu_job(&inp, c, d, &mut cb, &mut scratch);
        }
        nslab_cap = nslab_cap.max(((cb.surv as usize / SLAB as usize) + bj.len() * (NT / w) as usize + 64) as u32);
    }
    let jobs_h: Vec<_> = batches.iter().map(|bj| mk(bj.iter().flat_map(|&(c, d)| [c, d]).collect())).collect();
    chk("jobs");
    let out = client.empty(nslab_cap as usize * SLAB as usize * 16);
    let slabcnt = client.empty(nslab_cap as usize * 4);
    chk("out/slabcnt");
    // ---- GPU preparation (timed, then checked against the host's sorted parents; the kernel runs on its arrays)
    let par_m = par_m;
    let par_c = par_c;
    let mut prep_secs = 0f64;
    let (par_m, par_c, pseg) = if args.iter().any(|a| a == "--gpu-prep") {
        let r4s: Vec<u32> = (0..(1u32 << 24)).filter(|&r| root_mask(r as u64) != 0).collect();
        let nroots = r4s.len() as u32;
        let r4h = mk(r4s);
        let rankh = mk(inp.rank.to_vec());
        let npar = inp.par.len();
        let g_m = client.empty(npar * 8);
        let g_c = client.empty(npar * 4);
        let g_r = client.empty(npar * 4);
        let off = client.empty(16128 * 4);
        let curh = client.empty(16128 * 4);
        let g_pseg = client.empty(64 * 4);
        let mut tv = Vec::new();
        let mut histh = mk(vec![0u32; 16128]);
        for _ in 0..reps.max(1) {
            histh = mk(vec![0u32; 16128]);
            cubecl::future::block_on(client.sync()).map_err(|e| anyhow!("sync: {e:?}"))?;
            let tl = Instant::now();
            let cubes = nroots.div_ceil(NT);
            unsafe {
                prep::hist_kernel::launch_unchecked::<cubecl::wgpu::WgpuRuntime>(
                    &client, CubeCount::Static(cubes, 1, 1), CubeDim::new_1d(NT),
                    ArrayArg::from_raw_parts(r4h.clone(), nroots as usize), ArrayArg::from_raw_parts(rankh.clone(), 8),
                    ArrayArg::from_raw_parts(histh.clone(), 16128), nroots, inp.pip as u32, (inp.pip >> 32) as u32,
                );
                prep::scan_kernel::launch_unchecked::<cubecl::wgpu::WgpuRuntime>(
                    &client, CubeCount::Static(1, 1, 1), CubeDim::new_1d(256),
                    ArrayArg::from_raw_parts(histh.clone(), 16128), ArrayArg::from_raw_parts(off.clone(), 16128),
                    ArrayArg::from_raw_parts(curh.clone(), 16128), ArrayArg::from_raw_parts(g_pseg.clone(), 64),
                );
                prep::scatter_kernel::launch_unchecked::<cubecl::wgpu::WgpuRuntime>(
                    &client, CubeCount::Static(cubes, 1, 1), CubeDim::new_1d(NT),
                    ArrayArg::from_raw_parts(r4h.clone(), nroots as usize), ArrayArg::from_raw_parts(rankh.clone(), 8),
                    ArrayArg::from_raw_parts(curh.clone(), 16128), ArrayArg::from_raw_parts(g_m.clone(), npar),
                    ArrayArg::from_raw_parts(g_c.clone(), npar), ArrayArg::from_raw_parts(g_r.clone(), npar),
                    nroots, inp.pip as u32, (inp.pip >> 32) as u32,
                );
                prep::bsort_kernel::launch_unchecked::<cubecl::wgpu::WgpuRuntime>(
                    &client, CubeCount::Static(16128u32.div_ceil(64), 1, 1), CubeDim::new_1d(64),
                    ArrayArg::from_raw_parts(off.clone(), 16128), ArrayArg::from_raw_parts(histh.clone(), 16128),
                    ArrayArg::from_raw_parts(g_m.clone(), npar), ArrayArg::from_raw_parts(g_c.clone(), npar),
                    ArrayArg::from_raw_parts(g_r.clone(), npar),
                );
            }
            cubecl::future::block_on(client.sync()).map_err(|e| anyhow!("sync: {e:?}"))?;
            tv.push(tl.elapsed().as_secs_f64());
        }
        tv.sort_by(|a, b| a.partial_cmp(b).unwrap());
        prep_secs = tv[tv.len() / 2];
        let gm = u64::from_bytes(&client.read_one(g_m.clone()).map_err(|e| anyhow!("{e:?}"))?).to_vec();
        let gc = u32::from_bytes(&client.read_one(g_c.clone()).map_err(|e| anyhow!("{e:?}"))?).to_vec();
        let gp = u32::from_bytes(&client.read_one(g_pseg.clone()).map_err(|e| anyhow!("{e:?}"))?).to_vec();
        let gh = u32::from_bytes(&client.read_one(histh.clone()).map_err(|e| anyhow!("{e:?}"))?).to_vec();
        let total: u64 = gh.iter().map(|&x| x as u64).sum();
        let ok = total == npar as u64
            && gp == inp.pseg
            && (0..npar).all(|i| gm[i] == inp.par[i].mask && gc[i] == inp.par[i].cacc);
        println!(
            "PREP (GPU, 4 launches) median {:.3} ms ({} reps) for {npar} parents from {nroots} roots: {:.1} ps per parent; order and class segments {}",
            prep_secs * 1e3,
            tv.len(),
            prep_secs * 1e12 / npar as f64,
            if ok { "EQUAL to the CPU's" } else { "DIFFER from the CPU's" }
        );
        if !ok {
            all_prep_bad = true;
        }
        (g_m, g_c, g_pseg)
    } else {
        (par_m, par_c, pseg)
    };
    println!("{} launches of up to {} jobs; output {} slabs of {SLAB} records ({:.1} MB)", batches.len(), batch, nslab_cap, nslab_cap as f64 * SLAB as f64 * 16.0 / 1e6);
    let names = ["probes off", "skip off", "full"];
    let mut times = [0f64; 3];
    let mut all_ok = !all_prep_bad;
    for &mode in &modes {
        let mut tv = Vec::new();
        let mut s = Counts::default();
        let mut hc_tot = vec![0u64; NCNT];
        let mut pairs = Vec::new();
        let mut nrec = 0u64;
        let mut nslabs = 0u64;
        for rep in 0..reps.max(1) {
            let last_rep = rep + 1 == reps.max(1);
            let mut tsum = 0f64;
            for (bi, bj) in batches.iter().enumerate() {
                let cnt = mk(vec![0u32; NCNT]);
                let slabn = mk(vec![0u32; 1]);
                let tl = Instant::now();
                unsafe {
                    macro_rules! go {
                        ($m:expr, $no:expr) => {
                            kernels::g2_kernel::launch_unchecked::<cubecl::wgpu::WgpuRuntime>(
                                &client,
                                CubeCount::Static(bj.len() as u32, 1, 1),
                                CubeDim::new_1d(NT),
                                ArrayArg::from_raw_parts(par_m.clone(), inp.par.len()),
                                ArrayArg::from_raw_parts(par_c.clone(), inp.par.len()),
                                ArrayArg::from_raw_parts(pseg.clone(), 64),
                                ArrayArg::from_raw_parts(tmask.clone(), inp.ts.len()),
                                ArrayArg::from_raw_parts(tseg.clone(), inp.tseg.len()),
                                ArrayArg::from_raw_parts(roots.clone(), NROOT),
                                ArrayArg::from_raw_parts(jobs_h[bi].clone(), 2 * bj.len()),
                                ArrayArg::from_raw_parts(cnt.clone(), NCNT),
                                ArrayArg::from_raw_parts(out.clone(), nslab_cap as usize * SLAB as usize * 4),
                                ArrayArg::from_raw_parts(slabn.clone(), 1),
                                ArrayArg::from_raw_parts(slabcnt.clone(), nslab_cap as usize),
                                nslab_cap,
                                $m,
                                $no,
                                w,
                                fill,
                                xpose,
                                ept,
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
                            let pr = probes(&inp, cl, du);
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
            tv.push(tsum);
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
            let (g, cl) = sets(&inp, &pairs);
            all_ok &= compare(names[mode as usize], &g, &want, cl);
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
