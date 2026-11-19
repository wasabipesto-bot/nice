//! The device path of the middle-out join with masks wider than 64 bits:
//! bases 65–70, and (for its tests) any base 3–70 and any shape `(f0, k)`
//! whose numbers fit the layouts below. CubeCL, one source for CUDA and
//! Vulkan (SPIR-V).
//!
//! A second path, not a width parameter of [`super::gpu`]: base 64 keeps its
//! 64-bit kernels byte for byte (no tax by construction), and the trunk's
//! changes to the expansion, prefilter and tops of `gpu.rs` merge without
//! touching this file. The main kernel here is the base-64 kernel (form D,
//! the library's options fixed: shuffle transpose, two entries per step,
//! ballot ranks, common masks from registers, top digits from a table) with
//! these widenings:
//!
//! - **masks in two words**: a parent's or child's mask is `(lo: u64, hi:
//!   u32)`, digits 64..b in `hi`; a top's mask the same;
//! - **digits by division**: every digit of `r²`, `r³`, `n²`, `n³` is a
//!   division by `b` or `b²` (comptime constants) of base-`b²` limbs; the
//!   child's affine digits are `(c + a·d) mod b`;
//! - **7-bit digit fields**: a top's digits are 7-bit fields, 4 per word, in
//!   up to 5 words (20 digits; `maxpop` comptime, the fifth word only when
//!   `maxpop > 16`);
//! - **more slice rows**: 65 rows per chunk up to base 64, `(b + 1) | 1`
//!   above (67 at b65, 69 at b68, 71 at b69/b70), a zero row for the pad
//!   digit of an empty top mask; the digits 64..b are transposed by ballots
//!   (at most 6 per chunk segment) and their common masks taken from them;
//! - **the padded coordinate**: the range's ends are clipped per top
//!   (start's and end's low digits), and `h` runs over the leading values;
//! - **classes mod b − 1** and **roots** per base (`m`, `nroot` comptime);
//!   jobs run as `ninst` instances of `PMAX` probes each (day one's second
//!   instance, generalised: base 68 has 3.5k–6.3k probes per job).
//!
//! The full check is this file's own (`wcheck_kernel`): production's
//! `check_kernel` holds digits in one 64-bit mask and refuses bases above
//! 64. Survivor entries are `(top, r mod b^f0)`; the check rebuilds `n`
//! from the top's `(h, d)`, the slice's digits and the entry.

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
    clippy::trivially_copy_pass_by_ref,
    clippy::doc_markdown,
    clippy::if_not_else,
    clippy::items_after_statements,
    clippy::cast_precision_loss,
    clippy::cast_sign_loss,
    clippy::needless_pass_by_value,
    clippy::type_complexity,
    clippy::unnecessary_cast,
    clippy::erasing_op,
    clippy::identity_op,
    clippy::assign_op_pattern,
    clippy::manual_div_ceil,
    clippy::semicolon_if_nothing_returned,
    clippy::explicit_iter_loop,
    clippy::needless_late_init,
    clippy::missing_panics_doc,
    clippy::missing_errors_doc,
    clippy::must_use_candidate,
    clippy::bool_to_int_with_if,
    clippy::uninlined_format_args,
    unused_assignments,
    unused_mut
)]

use super::arith::{U384, roots as base_roots};
use super::coord::{Coord, ndigits};
use super::cpu::{Base, FieldOutcome, Shape, bottoms, key_digits};
use super::gpu::FieldTiming;
use anyhow::{Result, anyhow, bail, ensure};
use cubecl::prelude::*;
use cubecl::server::Handle;
use std::time::Instant;

/// Threads per cube.
const NT: u32 = 256;
/// Children per round: 16 full chunks (W >= 32).
const FILL: u32 = 1024;
/// Probe table rows per job instance.
pub const PMAX: u32 = 576;
/// Records per plane-private output slab.
const SLAB: u32 = 256;
/// The largest base: a mask's digits 64.. fit the 7 bits above r mod b^f0.
pub const MAXB: u32 = 70;
/// Counter layout: units × 5 (children, chunks, flat, kept, surv), then extras.
const C_LSLOTS: usize = 360;
const C_ERR_PLANE: usize = 361;
const C_ERR_PMAX: usize = 362;
const C_ERR_SLAB: usize = 363;
const C_ERR_CLASS: usize = 364;
/// Job instances that ran to their end (a launch that never ran leaves every other counter at a consistent zero).
const C_JOBS: usize = 365;
const NCNT: usize = 368;
/// The check's grid.
const CHECK_CUBES: u32 = 2048;
const CHECK_WG: u32 = 256;
const EXPAND_CUBES: u32 = 4096;
/// Words per top in the digit table.
const TDW: u32 = 5;
/// Nice-output words per n: (pip, top index, r mod b^f0, 1).
const NICE_STRIDE: usize = 4;
/// Bits of r mod b^f0 in a parent record's fourth word (the mask's digits 64.. above).
const RF_BITS: u32 = 25;

// ------------------------------------------------------------------------------------------------ device
mod wk {
    use super::{
        C_ERR_CLASS, C_ERR_PLANE, C_ERR_PMAX, C_ERR_SLAB, C_JOBS, C_LSLOTS, NT, PMAX, RF_BITS,
        SLAB, TDW,
    };
    use cubecl::prelude::*;

    /// Bits of a u64 whose index has bit j set (the shuffle transpose's stage-j mask).
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
    fn plane_rank_m(flag: bool, lo: u32, hi: u32, #[comptime] w: u32) -> u32 {
        let b = plane_ballot(flag);
        let mut r = (b[0usize] & lo).count_ones();
        if comptime!(w > 32) {
            r += (b[1usize] & hi).count_ones();
        }
        r
    }

    #[cube]
    fn plane_count(flag: bool, #[comptime] w: u32) -> u32 {
        let b = plane_ballot(flag);
        let mut n = b[0usize].count_ones();
        if comptime!(w > 32) {
            n += b[1usize].count_ones();
        }
        n
    }

    /// The bit of digit `v` as (lo, hi).
    #[cube]
    pub fn dbit(v: u32) -> (u64, u32) {
        let lo = select(v < 64u32, 1u64 << u64::cast_from(v & 63u32), 0u64);
        let hi = select(v >= 64u32, 1u32 << (v & 31u32), 0u32);
        (lo, hi)
    }

    /// The child of a parent (mask lo, hi; cacc = c2 | c3 << 8 | a2 << 16 | a3 << 24) at unit digit d, or 0.
    #[cube]
    fn child_w(pm: u64, ph: u32, cacc: u32, d: u32, #[comptime] b: u32) -> (u64, u32) {
        let e2 = ((cacc & 255u32) + ((cacc >> 16u32) & 255u32) * d) % b;
        let e3 = (((cacc >> 8u32) & 255u32) + ((cacc >> 24u32) & 255u32) * d) % b;
        let (l2, h2) = dbit(e2);
        let (l3, h3) = dbit(e3);
        let alo = l2 | l3;
        let ahi = h2 | h3;
        let mut olo = pm | alo;
        let mut ohi = ph | ahi;
        if e2 == e3 || (pm & alo) != 0u64 || (ph & ahi) != 0u32 {
            olo = 0u64;
            ohi = 0u32;
        }
        (olo, ohi)
    }

    /// One cube per job instance (class c, unit d, probes [poff, poff + PMAX)): the base-64 kernel's form D with
    /// two-word masks, `b | 1` slice rows, 7-bit probe digits and classes mod b − 1 (see the module notes).
    #[cube(launch_unchecked)]
    pub fn wide_kernel(
        par: &Array<Vector<u32, Const<4>>>, // (mask lo32, mask hi32, cacc, rf | mask digits 64.. << 25)
        pseg: &Array<u32>,
        tdig: &Array<u32>, // TDW words per top
        tseg: &Array<u32>,
        roots: &Array<u32>,
        jobs: &Array<u32>,
        cnt: &mut Array<Atomic<u32>>,
        out: &mut Array<Vector<u32, Const<4>>>,
        slabn: &mut Array<Atomic<u32>>,
        slabcnt: &mut Array<u32>,
        nslab_cap: u32,
        clst: &mut Array<u32>,
        c0: u32,
        plast: u32,
        #[comptime] w: u32,
        #[comptime] fill: u32,
        #[comptime] b: u32,
        #[comptime] nroot: u32,
        #[comptime] maxpop: u32,
    ) {
        let m = comptime!(b - 1);
        // rows per chunk: every digit 0..64 of the transpose has a row, and the pad digit (64 below base 65, b
        // above) a row of zeros, never common: an odd stride (65 below base 65, (b + 1) | 1 above)
        let srow = comptime!(if b > 64 { (b + 1) | 1 } else { 65 });
        let slw = comptime!((if b > 64 { (b + 1) | 1 } else { 65 }) * 32);
        let pad = comptime!(if b > 64 { b } else { 64 });
        let npl = comptime!(NT / w);
        let segs = comptime!(64 / w);
        let mut pq = SharedMemory::<u32>::new(comptime!(
            (if (fill + NT) / 2 > PMAX + 32 {
                (fill + NT) / 2
            } else {
                PMAX + 64
            }) as usize
        ));
        let mut sl = SharedMemory::<u32>::new(comptime!(slw as usize));
        let slt = SharedMemory::<Atomic<u32>>::new(comptime!(
            (if w < 32 {
                (if b > 64 { (b + 1) | 1 } else { 65 }) * 32
            } else {
                32
            }) as usize
        ));
        let comm = SharedMemory::<Atomic<u32>>::new(32usize); // [2q + half], digits 0..64
        let commh = SharedMemory::<Atomic<u32>>::new(32usize); // [q], digits 64..
        let mut prob_d = SharedMemory::<Vector<u32, Const<4>>>::new(comptime!(PMAX as usize));
        let mut prob_e =
            SharedMemory::<u32>::new(comptime!((if maxpop > 16 { PMAX } else { 32 }) as usize));
        let mut wcnt = SharedMemory::<u32>::new(comptime!(
            (if 2 * NT / w < 32 { 32 } else { 2 * NT / w }) as usize
        ));
        let s_nl = SharedMemory::<Atomic<u32>>::new(32usize);
        let mut s_np = SharedMemory::<u32>::new(32usize);
        let mut cmv = SharedMemory::<u32>::new(96usize);

        let t = UNIT_POS_X;
        let lane = UNIT_POS_PLANE;
        let pl = plane_sum(select(lane == 0u32, t / w, 0u32));
        let rl = UNIT_POS_PLANE;
        let rlo = select(rl >= 32u32, 0xFFFF_FFFFu32, (1u32 << min(rl, 31u32)) - 1u32);
        let rhi = select(rl >= 32u32, (1u32 << (rl & 31u32)) - 1u32, 0u32);
        let c = jobs[(2u32 * CUBE_POS_X) as usize];
        let dj = jobs[(2u32 * CUBE_POS_X + 1u32) as usize];
        let d = dj & 255u32;
        let poff = dj >> 8u32;
        let cc = (c + d) % m;

        if PLANE_DIM != w || t % w != lane {
            cnt[C_ERR_PLANE].fetch_add(1u32);
        }
        let pb = pseg[c as usize];
        let pe = pseg[(c + 1u32) as usize];
        if t == 0u32 {
            let mut n = 0u32;
            for i in 0..nroot {
                let ct = (roots[i as usize] + m - cc) % m;
                let s = (d * m + ct) * 2u32;
                n += tseg[(s + 1u32) as usize] - tseg[s as usize];
            }
            s_np[0usize] = n;
            s_nl[0usize].store(0u32);
            if poff == plast && n > poff + PMAX {
                cnt[C_ERR_PMAX].fetch_add(1u32);
            }
            if pe - pb > 65535u32 && poff == 0u32 {
                cnt[C_ERR_CLASS].fetch_add(1u32);
            }
        }
        if t < 32u32 {
            comm[t as usize].store(u32::MAX);
            commh[t as usize].store(u32::MAX);
            // the pad digit's row of every chunk: zeros (no round writes it at W >= 32)
            sl[(((t / 2u32) * srow + pad) * 2u32 + t % 2u32) as usize] = 0u32;
        }
        if t == 32u32 {
            cmv[pad as usize] = 0u32;
        }
        sync_cube();
        // probes: the compatible top classes of unit d, each probe's digits as 7-bit fields (4 per word)
        {
            let mut base = 0u32;
            for i in 0..nroot {
                let ct = (roots[i as usize] + m - cc) % m;
                let s = (d * m + ct) * 2u32;
                let b0 = tseg[s as usize];
                let b1 = tseg[(s + 1u32) as usize];
                let mut j = t;
                while j < b1 - b0 {
                    if base + j >= poff && base + j < poff + PMAX {
                        let mut pv = Vector::<u32, Const<4>>::empty();
                        #[unroll]
                        for k in 0..4u32 {
                            pv[k as usize] = tdig[((b0 + j) * TDW + k) as usize];
                        }
                        prob_d[(base + j - poff) as usize] = pv;
                        if comptime!(maxpop > 16) {
                            prob_e[(base + j - poff) as usize] =
                                tdig[((b0 + j) * TDW + 4u32) as usize];
                        }
                    }
                    j += NT;
                }
                base += b1 - b0;
            }
        }
        sync_cube();
        let nprobe = min(s_np[0usize] - min(s_np[0usize], poff), PMAX);

        let mut my_kept = 0u32;
        let mut my_surv = 0u32;
        let mut my_children = 0u32;
        let mut my_chunks = 0u32;
        let mut my_flat = 0u32;
        let mut my_lslots = 0u32;
        let mut slab_id = 0u32;
        let mut slab_used = 256u32;
        let mut have_slab = false;

        let mut cur = pb;
        let mut npend = 0u32;
        let mut parity = 0u32;
        let mut going = nprobe > 0u32 || poff == 0u32;
        let lb = (pb - pseg[c0 as usize]) * b + d * (pe - pb);
        let mut cdone = 0u32;
        let mut dsl = 0u32;
        let mut dv = 0u32;
        let mut dhave = false;
        let mut keep = 0u32;
        while going {
            // phase 1: append children of NT parents at a time (ordered)
            while npend < fill && cur < pe {
                let idx = cur + t;
                let mut nz = false;
                let mut r4v = 0u32;
                if idx < pe {
                    let pv = par[idx as usize];
                    r4v = pv[3usize] & comptime!((1u32 << RF_BITS) - 1);
                    let (ml, mh) = child_w(
                        u64::cast_from(pv[0usize]) | (u64::cast_from(pv[1usize]) << 32u64),
                        pv[3usize] >> comptime!(RF_BITS),
                        pv[2usize],
                        d,
                        b,
                    );
                    nz = ml != 0u64 || mh != 0u32;
                }
                let r = plane_rank_m(nz, rlo, rhi, w);
                let tot = plane_count(nz, w);
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
                if nz {
                    let sl16 = npend + off + r;
                    clst[(lb + cdone + sl16) as usize] = r4v;
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
            let nch = min(
                comptime!(fill / 64),
                select(done, (npend + 63u32) / 64u32, 64u32),
            );
            if nch == 0u32 {
                going = false;
            } else {
                let ntake = min(npend, nch * 64u32);
                if comptime!(w < 32) {
                    let mut z = t;
                    while z < slw {
                        slt[z as usize].store(0u32);
                        z += NT;
                    }
                    sync_cube();
                }
                // phase 2: plane task i covers chunk q, segment s (members s*W .. s*W+W-1)
                for i in 0..4u32 {
                    let task = pl + npl * i;
                    let q = task / segs;
                    let sg = task % segs;
                    let mi = q * 64u32 + sg * w + lane;
                    let mut ml = 0u64;
                    let mut mh = 0u32;
                    if q < nch && mi < ntake {
                        let pi =
                            pb + ((pq[(mi >> 1u32) as usize] >> ((mi & 1u32) << 4u32)) & 0xFFFFu32);
                        let pv = par[pi as usize];
                        let (a, bh) = child_w(
                            u64::cast_from(pv[0usize]) | (u64::cast_from(pv[1usize]) << 32u64),
                            pv[3usize] >> comptime!(RF_BITS),
                            pv[2usize],
                            d,
                            b,
                        );
                        ml = a;
                        mh = bh;
                    }
                    // shuffle transpose of digits 0..64 (the base-64 kernel's, unchanged)
                    let mut xl = u32::cast_from(ml & 0xFFFF_FFFFu64);
                    let mut xh = u32::cast_from(ml >> 32u64);
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
                            let kp = select(hit, mj, !mj);
                            let sr = select(hit, j, 32u32 - j);
                            let rl2 = (yl >> sr) | (yl << (32u32 - sr));
                            let rh2 = (yh >> sr) | (yh << (32u32 - sr));
                            xl = (xl & kp) | (rl2 & !kp);
                            xh = (xh & kp) | (rh2 & !kp);
                        }
                    }
                    let nv = min(w, ntake - min(ntake, q * 64u32 + sg * w));
                    let vlo = select(nv >= 32u32, 0xFFFF_FFFFu32, (1u32 << min(nv, 31u32)) - 1u32);
                    let vhi = select(
                        nv >= 64u32,
                        0xFFFF_FFFFu32,
                        select(
                            nv > 32u32,
                            (1u32 << ((nv - min(nv, 32u32)) & 31u32)) - 1u32,
                            0u32,
                        ),
                    );
                    if q < nch {
                        #[unroll]
                        for sb in 0..segs {
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
                                eq = ((hv >> comptime!((sb * w) % 32))
                                    & comptime!((1u32 << w) - 1))
                                    == vlo;
                            }
                            let bal = plane_ballot(eq);
                            if lane == 0u32 {
                                if comptime!(w == 64) {
                                    comm[(2u32 * q) as usize].fetch_and(bal[0usize]);
                                    comm[(2u32 * q + 1u32) as usize].fetch_and(bal[1usize]);
                                } else if comptime!(w == 32) {
                                    comm[(2u32 * q + comptime!(sb)) as usize]
                                        .fetch_and(bal[0usize]);
                                } else {
                                    let wm = comptime!((1u32 << w) - 1);
                                    let sh = comptime!((sb * w) % 32);
                                    comm[(2u32 * q + comptime!((sb * w) / 32)) as usize]
                                        .fetch_and(!(wm << sh) | ((bal[0usize] & wm) << sh));
                                }
                            }
                        }
                        #[unroll]
                        for sb in 0..segs {
                            let v = comptime!(sb * w) + lane;
                            let row = (v + q * srow) * 2u32;
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
                                let piece =
                                    (hv >> comptime!((sb * w) % 32)) & comptime!((1u32 << w) - 1);
                                slt[(row + bit / 32u32) as usize].fetch_or(piece << (bit % 32u32));
                            }
                        }
                    }
                    // (wide) digits 64..b by ballots: the slice row and the common bit per chunk segment
                    if comptime!(b > 64) {
                        #[unroll]
                        for xv in 0..comptime!(b - 64) {
                            let bal = plane_ballot(((mh >> comptime!(xv)) & 1u32) != 0u32);
                            if q < nch && lane == 0u32 {
                                let row = (q * srow + comptime!(64 + xv)) * 2u32;
                                let mut eq = false;
                                if comptime!(w == 64) {
                                    sl[row as usize] = bal[0usize];
                                    sl[(row + 1u32) as usize] = bal[1usize];
                                    eq = bal[0usize] == vlo && bal[1usize] == vhi;
                                } else if comptime!(w == 32) {
                                    sl[(row + sg) as usize] = bal[0usize];
                                    eq = bal[0usize] == vlo;
                                } else {
                                    let piece = bal[0usize] & comptime!((1u32 << w) - 1);
                                    let bit = sg * w;
                                    slt[(row + bit / 32u32) as usize]
                                        .fetch_or(piece << (bit % 32u32));
                                    eq = piece == vlo;
                                }
                                if !eq {
                                    commh[q as usize].fetch_and(comptime!(!(1u32 << xv)));
                                }
                            }
                        }
                    }
                }
                let left0 = npend - ntake;
                keep = 0u32;
                if t < left0 {
                    let s16 = ntake + t;
                    keep = (pq[(s16 >> 1u32) as usize] >> ((s16 & 1u32) << 4u32)) & 0xFFFFu32;
                }
                let cpos = cdone + (t % 16u32) * 64u32;
                sync_cube();
                if comptime!(w < 32) {
                    let mut z = t;
                    while z < slw {
                        sl[z as usize] = slt[z as usize].load();
                        z += NT;
                    }
                    sync_cube();
                }
                // the common masks per digit: cmv[v] bit q = digit v is common to chunk q
                if t < b {
                    let mut cmk = 0u32;
                    for qq in 0..nch {
                        let mut wv = 0u32;
                        if t < 64u32 {
                            wv = comm[(2u32 * qq + t / 32u32) as usize].load();
                        } else {
                            wv = commh[qq as usize].load();
                        }
                        cmk |= ((wv >> (t % 32u32)) & 1u32) << qq;
                    }
                    cmv[t as usize] = cmk;
                }
                sync_cube();
                // phase 3a: per probe, its 16-bit mask of chunks kept by the common-mask skip -> list
                let allq = (1u32 << nch) - 1u32;
                let mut pp = t;
                while pp < nprobe {
                    let mut hitm = 0u32;
                    let pv = prob_d[pp as usize];
                    let mut pe5 = 0u32;
                    if comptime!(maxpop > 16) {
                        pe5 = prob_e[pp as usize];
                    }
                    #[unroll]
                    for k in 0..maxpop {
                        let mut dg = 0u32;
                        if comptime!(k < 16) {
                            dg = (pv[comptime!(k / 4) as usize] >> comptime!(7 * (k % 4))) & 127u32;
                        } else {
                            dg = (pe5 >> comptime!(7 * (k - 16))) & 127u32;
                        }
                        hitm |= cmv[dg as usize];
                    }
                    let km = allq & !hitm;
                    my_kept += km.count_ones();
                    if km != 0u32 {
                        let slot = s_nl[0usize].fetch_add(1u32);
                        pq[slot as usize] = (pp * 16u32) | (km << 16u32);
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
                let vhi = select(
                    nq == 64u32,
                    0xFFFF_FFFFu32,
                    select(nq > 32u32, (1u32 << (nq % 32u32)) - 1u32, 0u32),
                );
                let qr = q * srow;
                let qs = 16u32 + q;
                let mut e0 = 0u32;
                while e0 < nlist {
                    let mut wlo = Array::<u32>::new(2usize);
                    let mut whi = Array::<u32>::new(2usize);
                    let mut pk = Array::<u32>::new(2usize);
                    #[unroll]
                    for h in 0..2u32 {
                        let e = e0 + st + comptime!(16 * h);
                        let ent = select(e < nlist, pq[e as usize], 0u32);
                        let p16 = ent & 0xFFFFu32;
                        pk[h as usize] = p16;
                        let kmask = 0u32 - ((ent >> qs) & 1u32);
                        let mut alo = 0u32;
                        let mut ahi = 0u32;
                        let dws = prob_d[(p16 >> 4u32) as usize];
                        let mut de = 0u32;
                        if comptime!(maxpop > 16) {
                            de = prob_e[(p16 >> 4u32) as usize];
                        }
                        #[unroll]
                        for k in 0..maxpop {
                            let mut dg = 0u32;
                            if comptime!(k < 16) {
                                dg = (dws[comptime!(k / 4) as usize] >> comptime!(7 * (k % 4)))
                                    & 127u32;
                            } else {
                                dg = (de >> comptime!(7 * (k - 16))) & 127u32;
                            }
                            let row = (dg + qr) * 2u32;
                            alo |= sl[row as usize];
                            ahi |= sl[(row + 1u32) as usize];
                        }
                        wlo[h as usize] = !alo & vlo & kmask;
                        whi[h as usize] = !ahi & vhi & kmask;
                    }
                    if t == 0u32 {
                        my_lslots += min(32u32, nlist - e0) * nch;
                    }
                    let nza = (wlo[0usize] | whi[0usize]) != 0u32;
                    let nzb = (wlo[1usize] | whi[1usize]) != 0u32;
                    let na = plane_count(nza, w);
                    let nn = na + plane_count(nzb, w);
                    let ra = plane_rank_m(nza, rlo, rhi, w);
                    let rb = plane_rank_m(nzb, rlo, rhi, w);
                    if nn > 0u32 {
                        if slab_used + nn > SLAB {
                            if lane == 0u32 && have_slab {
                                slabcnt[slab_id as usize] = slab_used;
                            }
                            let mut sid = 0u32;
                            if lane == 0u32 {
                                sid = slabn[0usize].fetch_add(1u32);
                            }
                            slab_id = plane_sum(sid);
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
                                rv[0usize] =
                                    ((pk[0usize] >> 4u32) + poff) | (d << 16u32) | (c << 24u32);
                                rv[1usize] = cpos;
                                rv[2usize] = wlo[0usize];
                                rv[3usize] = whi[0usize];
                                out[(sbase + ra) as usize] = rv;
                            }
                            if nzb {
                                let mut rv = Vector::<u32, Const<4>>::empty();
                                rv[0usize] =
                                    ((pk[1usize] >> 4u32) + poff) | (d << 16u32) | (c << 24u32);
                                rv[1usize] = cpos;
                                rv[2usize] = wlo[1usize];
                                rv[3usize] = whi[1usize];
                                out[(sbase + na + rb) as usize] = rv;
                            }
                        }
                        my_surv += wlo[0usize].count_ones()
                            + whi[0usize].count_ones()
                            + wlo[1usize].count_ones()
                            + whi[1usize].count_ones();
                        slab_used += nn;
                    }
                    e0 += 32u32;
                }
                if t == 0u32 {
                    my_flat += nprobe * nch;
                    my_chunks += nch;
                    my_children += ntake;
                }
                sync_cube();
                // phase 4: carry the rest (< NT) to the front; reset the round's list and common masks
                let left = npend - ntake;
                let nb = plane_shuffle_xor(keep, 1u32);
                if t < left && (t & 1u32) == 0u32 {
                    pq[(t >> 1u32) as usize] = keep | select(t + 1u32 < left, nb << 16u32, 0u32);
                }
                if t == 0u32 {
                    s_nl[0usize].store(0u32);
                }
                if t >= 32u32 && t < 64u32 {
                    comm[(t - 32u32) as usize].store(u32::MAX);
                }
                if t >= 64u32 && t < 96u32 {
                    commh[(t - 64u32) as usize].store(u32::MAX);
                }
                npend = left;
                cdone += ntake;
                sync_cube();
                if done && left == 0u32 {
                    going = false;
                }
            }
        }
        if lane == 0u32 && have_slab && slab_id < nslab_cap {
            slabcnt[slab_id as usize] = slab_used;
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
        if t == 0u32 && poff == 0u32 {
            cnt[(d * 5u32) as usize].fetch_add(my_children);
            cnt[(d * 5u32 + 1u32) as usize].fetch_add(my_chunks);
        }
        if t == 0u32 {
            cnt[(d * 5u32 + 2u32) as usize].fetch_add(my_flat);
            cnt[C_LSLOTS].fetch_add(my_lslots);
            cnt[C_JOBS].fetch_add(1u32);
        }
    }
}

/// Preparation, tops, expansion and check for wide masks: everything is
/// generic in (b, f0, k) and works on base-b digits and base-b² limbs.
mod wp {
    use super::wk::dbit;
    use super::{NT, RF_BITS, SLAB, TDW};
    use cubecl::prelude::*;

    /// `r = x·y` in base-b² limbs (comptime sizes; every column below 2^31).
    #[cube]
    fn mul_l(
        x: &Array<u32>,
        y: &Array<u32>,
        r: &mut Array<u32>,
        #[comptime] nx: u32,
        #[comptime] ny: u32,
        #[comptime] bb: u32,
    ) {
        let mut carry = 0u32;
        #[unroll]
        for kk in 0..comptime!(nx + ny) {
            let mut s = carry;
            #[unroll]
            for i in 0..nx {
                if comptime!(kk >= i && kk - i < ny) {
                    s += x[i as usize] * y[comptime!(kk - i) as usize];
                }
            }
            carry = s / bb;
            r[kk as usize] = s - carry * bb;
        }
    }

    /// Digit j (comptime) of a base-b² limb array.
    #[cube]
    fn dig_l(x: &Array<u32>, #[comptime] j: u32, #[comptime] b: u32) -> u32 {
        let y = x[comptime!(j / 2) as usize];
        let mut v = 0u32;
        if comptime!(j % 2 == 1) {
            v = y / b;
        } else {
            v = y % b;
        }
        v
    }

    /// Digits `[0, l)` (base b) into base-b² limbs.
    #[cube]
    fn limbs(dg: &Array<u32>, nn: &mut Array<u32>, #[comptime] l: u32, #[comptime] b: u32) {
        #[unroll]
        for i in 0..comptime!((l + 1) / 2) {
            let mut v = dg[comptime!(2 * i) as usize];
            if comptime!(2 * i + 1 < l) {
                v += dg[comptime!(2 * i + 1) as usize] * b;
            }
            nn[i as usize] = v;
        }
    }

    /// One power's part of a top certificate: digits s−1 down to k while x and y agree; (lo, hi, repeated).
    #[cube]
    fn cert_w(
        x: &Array<u32>,
        y: &Array<u32>,
        lo_in: u64,
        hi_in: u32,
        #[comptime] b: u32,
        #[comptime] s: u32,
        #[comptime] k: u32,
    ) -> (u64, u32, bool) {
        let mut lo = lo_in;
        let mut hi = hi_in;
        let mut live = true;
        let mut bad = false;
        #[unroll]
        for tt in 0..comptime!(s - k) {
            let dx = dig_l(x, comptime!(s - 1 - tt), b);
            let dy = dig_l(y, comptime!(s - 1 - tt), b);
            if live {
                if dx != dy {
                    live = false;
                } else {
                    let (bl, bh) = dbit(dx);
                    if (lo & bl) != 0u64 || (hi & bh) != 0u32 {
                        bad = true;
                        live = false;
                    }
                    lo |= bl;
                    hi |= bh;
                }
            }
        }
        (lo, hi, bad)
    }

    /// The digits of the parent of r_f = r mod b^f0 under the slice (digits [f0, k−1) = pipd): (mask lo, hi, cacc),
    /// mask 0 when a digit 0..k−2 of r² or r³ repeats.
    #[cube]
    fn parent_w(
        rf: u32,
        pipd: &Array<u32>,
        #[comptime] b: u32,
        #[comptime] f0: u32,
        #[comptime] k: u32,
    ) -> (u64, u32, u32) {
        let nd = comptime!(k - 1);
        let mut rd = Array::<u32>::new(comptime!(nd as usize));
        let mut x = rf;
        #[unroll]
        for j in 0..f0 {
            rd[j as usize] = x % b;
            x = x / b;
        }
        #[unroll]
        for j in 0..comptime!(nd - f0) {
            rd[comptime!(f0 + j) as usize] = pipd[j as usize];
        }
        // r² and r³ mod b^k, digit by digit
        let mut sq = Array::<u32>::new(comptime!(k as usize));
        let mut cu = Array::<u32>::new(comptime!(k as usize));
        let mut carry = 0u32;
        #[unroll]
        for j in 0..k {
            let mut s = carry;
            #[unroll]
            for i in 0..nd {
                if comptime!(j >= i && j - i < nd) {
                    s += rd[i as usize] * rd[comptime!(j - i) as usize];
                }
            }
            carry = s / b;
            sq[j as usize] = s - carry * b;
        }
        carry = 0u32;
        #[unroll]
        for j in 0..k {
            let mut s = carry;
            #[unroll]
            for i in 0..nd {
                if comptime!(j >= i) {
                    s += rd[i as usize] * sq[comptime!(j - i) as usize];
                }
            }
            carry = s / b;
            cu[j as usize] = s - carry * b;
        }
        let mut lo = 0u64;
        let mut hi = 0u32;
        #[unroll]
        for j in 0..nd {
            let (a, ah) = dbit(sq[j as usize]);
            let (c, ch) = dbit(cu[j as usize]);
            lo |= a | c;
            hi |= ah | ch;
        }
        let ok = lo.count_ones() + hi.count_ones() == comptime!(2 * nd);
        let r0 = rd[0usize];
        let cacc = sq[comptime!(k - 1) as usize]
            | (cu[comptime!(k - 1) as usize] << 8u32)
            | (((2u32 * r0) % b) << 16u32)
            | (((3u32 * r0 * r0) % b) << 24u32);
        if !ok {
            lo = 0u64;
            hi = 0u32;
        }
        (lo, hi, cacc)
    }

    /// Parents of every root r_f (one thread each): the compact list (record and bucket key) and the histogram of
    /// keys (class · 256 + 255 − key8).
    #[cube(launch_unchecked)]
    pub fn whist_kernel(
        rfs: &Array<u32>,
        pipd: &Array<u32>,
        rank: &Array<u32>,
        hist: &mut Array<Atomic<u32>>,
        lst: &mut Array<Vector<u32, Const<4>>>,
        lkey: &mut Array<u32>,
        lcnt: &mut Array<Atomic<u32>>,
        nroots: u32,
        pipcls: u32,
        cap: u32,
        #[comptime] w: u32,
        #[comptime] b: u32,
        #[comptime] f0: u32,
        #[comptime] k: u32,
    ) {
        let m = comptime!(b - 1);
        let i = ABSOLUTE_POS_X;
        let mut lo = 0u64;
        let mut hi = 0u32;
        let mut cacc = 0u32;
        let mut key = 0u32;
        let mut rf = 0u32;
        if i < nroots {
            rf = rfs[i as usize];
            let (a, ah, cc) = parent_w(rf, pipd, b, f0, k);
            lo = a;
            hi = ah;
            cacc = cc;
            let cls = (rf % m + pipcls) % m;
            let mut k8 = 0u32;
            #[unroll]
            for j in 0..8u32 {
                let v = rank[j as usize];
                let bit = select(
                    v < 64u32,
                    u32::cast_from((lo >> u64::cast_from(v & 63u32)) & 1u64),
                    (hi >> (v & 31u32)) & 1u32,
                );
                k8 |= bit << comptime!(7 - j);
            }
            key = cls * 256u32 + (255u32 - k8);
        }
        let flag = lo != 0u64 || hi != 0u32;
        let bl = plane_ballot(flag);
        let l = UNIT_POS_PLANE;
        let lm = select(l >= 32u32, 0xFFFF_FFFFu32, (1u32 << min(l, 31u32)) - 1u32);
        let mut r = (bl[0usize] & lm).count_ones();
        let mut n = bl[0usize].count_ones();
        if comptime!(w > 32) {
            let hm = select(l >= 32u32, (1u32 << (l & 31u32)) - 1u32, 0u32);
            r += (bl[1usize] & hm).count_ones();
            n += bl[1usize].count_ones();
        }
        let mut base0 = 0u32;
        if l == 0u32 && n > 0u32 {
            base0 = lcnt[0usize].fetch_add(n);
        }
        let base = plane_sum(base0);
        if flag {
            let slot = base + r;
            if slot < cap {
                let mut v = Vector::<u32, Const<4>>::empty();
                v[0usize] = u32::cast_from(lo & 0xFFFF_FFFFu64);
                v[1usize] = u32::cast_from(lo >> 32u64);
                v[2usize] = cacc;
                v[3usize] = rf | (hi << comptime!(RF_BITS));
                lst[slot as usize] = v;
                lkey[slot as usize] = key;
            }
            hist[key as usize].fetch_add(1u32);
        }
    }

    /// The list into its buckets (order inside a bucket arbitrary; the sort restores r order).
    #[cube(launch_unchecked)]
    pub fn wscatter_kernel(
        lst: &Array<Vector<u32, Const<4>>>,
        lkey: &Array<u32>,
        lcnt: &Array<u32>,
        cur: &mut Array<Atomic<u32>>,
        tmp: &mut Array<u32>,
        cap: u32,
    ) {
        let i = ABSOLUTE_POS_X;
        if i < min(lcnt[0usize], cap) {
            let key = lkey[i as usize];
            let slot = cur[key as usize].fetch_add(1u32);
            let v = lst[i as usize];
            tmp[(4u32 * slot) as usize] = v[0usize];
            tmp[(4u32 * slot + 1u32) as usize] = v[1usize];
            tmp[(4u32 * slot + 2u32) as usize] = v[2usize];
            tmp[(4u32 * slot + 3u32) as usize] = v[3usize];
        }
    }

    /// One cube per bucket: its records by r_f (the low RF_BITS of word 3), by rank for buckets of at most 256, by
    /// a bitonic sort up to 2,048, else by a quadratic rank (never seen).
    #[cube(launch_unchecked)]
    pub fn wsort_kernel(
        off: &Array<u32>,
        hist: &Array<u32>,
        tmp: &Array<u32>,
        rec: &mut Array<u32>,
    ) {
        let mut sk = SharedMemory::<u32>::new(2048usize);
        let mut si = SharedMemory::<u32>::new(2048usize);
        let km = comptime!((1u32 << RF_BITS) - 1);
        let kb = CUBE_POS_X;
        let t = UNIT_POS_X;
        let b0 = off[kb as usize];
        let n = hist[kb as usize];
        if n <= 256u32 {
            let n4 = (n + 3u32) & 0xFFFF_FFFCu32;
            let mut mine = 0xFFFF_FFFFu32;
            if t < n {
                mine = tmp[(4u32 * (b0 + t) + 3u32) as usize] & km;
            }
            if t < n4 {
                sk[t as usize] = mine;
            }
            sync_cube();
            if t < n {
                let mut rk = 0u32;
                let mut j = 0u32;
                while j < n4 {
                    rk += select(sk[j as usize] < mine, 1u32, 0u32);
                    rk += select(sk[(j + 1u32) as usize] < mine, 1u32, 0u32);
                    rk += select(sk[(j + 2u32) as usize] < mine, 1u32, 0u32);
                    rk += select(sk[(j + 3u32) as usize] < mine, 1u32, 0u32);
                    j += 4u32;
                }
                let dst = 4u32 * (b0 + rk);
                let src = 4u32 * (b0 + t);
                rec[dst as usize] = tmp[src as usize];
                rec[(dst + 1u32) as usize] = tmp[(src + 1u32) as usize];
                rec[(dst + 2u32) as usize] = tmp[(src + 2u32) as usize];
                rec[(dst + 3u32) as usize] = tmp[(src + 3u32) as usize];
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
                    key = tmp[(4u32 * (b0 + i) + 3u32) as usize] & km;
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
                            let bv = sk[l as usize];
                            let up = (i & kk) == 0u32;
                            if (a > bv) == up {
                                let ia = si[i as usize];
                                let ib = si[l as usize];
                                sk[i as usize] = bv;
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
                let mine = tmp[(4u32 * (b0 + i) + 3u32) as usize] & km;
                let mut rk = 0u32;
                for j in 0..n {
                    rk += select(
                        (tmp[(4u32 * (b0 + j) + 3u32) as usize] & km) < mine,
                        1u32,
                        0u32,
                    );
                }
                let dst = 4u32 * (b0 + rk);
                let src = 4u32 * (b0 + i);
                rec[dst as usize] = tmp[src as usize];
                rec[(dst + 1u32) as usize] = tmp[(src + 1u32) as usize];
                rec[(dst + 2u32) as usize] = tmp[(src + 2u32) as usize];
                rec[(dst + 3u32) as usize] = tmp[(src + 3u32) as usize];
                i += 256u32;
            }
        }
    }

    /// One cube of 1,024: an exclusive scan of `n` counts (`per` per thread): offsets, cursors; with `seg`, the
    /// starts and ends as pairs (`tseg`) and the total in `tot`; else every `every`-th offset into `marks` and the
    /// total after them.
    #[cube(launch_unchecked)]
    pub fn wscan_kernel(
        cntin: &Array<u32>,
        off: &mut Array<u32>,
        cur: &mut Array<Atomic<u32>>,
        marks: &mut Array<u32>,
        tot: &mut Array<u32>,
        #[comptime] n: u32,
        #[comptime] every: u32,
        #[comptime] seg: bool,
    ) {
        let per = comptime!((n + 1023) / 1024);
        let mut sums = SharedMemory::<u32>::new(1024usize);
        let t = UNIT_POS_X;
        let mut local = 0u32;
        #[unroll]
        for j in 0..per {
            let k = t * per + j;
            if k < n {
                local += cntin[k as usize];
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
        let mut run = sums[t as usize] - local;
        #[unroll]
        for j in 0..per {
            let k = t * per + j;
            if k < n {
                cur[k as usize].store(run);
                if comptime!(seg) {
                    off[(2u32 * k) as usize] = run;
                    run += cntin[k as usize];
                    off[(2u32 * k + 1u32) as usize] = run;
                } else {
                    off[k as usize] = run;
                    if k % every == 0u32 {
                        marks[(k / every) as usize] = run;
                    }
                    run += cntin[k as usize];
                }
            }
        }
        if t == 1023u32 {
            let total = sums[1023usize];
            tot[0usize] = total;
            if comptime!(!seg) {
                marks[comptime!(n / every) as usize] = total;
            }
        }
    }

    /// Tops: thread i = d·nlead + (h − hlo) tests the prefix p = (h·b + d)·b^(k−1−f0) + pip (if in the range's
    /// prefixes [plo, phi]; the range's ends clip the first and last); certificate of n² and n³ at positions ≥ k;
    /// a count per segment d·m + h mod m.
    #[cube(launch_unchecked)]
    pub fn wtops1_kernel(
        tm: &mut Array<u64>,
        th: &mut Array<u32>,
        tv: &mut Array<u32>,
        segc: &mut Array<Atomic<u32>>,
        tstat: &mut Array<Atomic<u32>>,
        pipd: &Array<u32>,
        ends: &Array<u32>,
        ntest: u32,
        nlead: u32,
        hlo: u32,
        plo_lo: u32,
        plo_hi: u32,
        phi_lo: u32,
        phi_hi: u32,
        #[comptime] b: u32,
        #[comptime] f0: u32,
        #[comptime] k: u32,
        #[comptime] l: u32,
        #[comptime] s2: u32,
        #[comptime] s3: u32,
        #[comptime] maxpop: u32,
    ) {
        let m = comptime!(b - 1);
        let bb = comptime!(b * b);
        let na = comptime!((l + 1) / 2);
        let i = ABSOLUTE_POS_X;
        if i < ntest {
            let d = i / nlead;
            let h = hlo + i % nlead;
            let bw = comptime!(b as u64);
            let mut p = u64::cast_from(h * b + d);
            #[unroll]
            for j in 0..comptime!(k - 1 - f0) {
                p = p * bw + u64::cast_from(pipd[comptime!(k - 2 - f0 - j) as usize]);
            }
            let plo = u64::cast_from(plo_lo) | (u64::cast_from(plo_hi) << 32u64);
            let phi = u64::cast_from(phi_lo) | (u64::cast_from(phi_hi) << 32u64);
            let mut ok = false;
            let mut lo = 0u64;
            let mut hi = 0u32;
            if p >= plo && p <= phi {
                let mut ad = Array::<u32>::new(comptime!(l as usize));
                let mut cd = Array::<u32>::new(comptime!(l as usize));
                #[unroll]
                for j in 0..f0 {
                    ad[j as usize] = select(p == plo, ends[j as usize], 0u32);
                    cd[j as usize] =
                        select(p == phi, ends[comptime!(l + j) as usize], comptime!(b - 1));
                }
                #[unroll]
                for j in 0..comptime!(k - 1 - f0) {
                    let v = pipd[j as usize];
                    ad[comptime!(f0 + j) as usize] = v;
                    cd[comptime!(f0 + j) as usize] = v;
                }
                ad[comptime!(k - 1) as usize] = d;
                cd[comptime!(k - 1) as usize] = d;
                let mut hh = h;
                #[unroll]
                for j in 0..comptime!(l - k) {
                    let q = hh / b;
                    let v = hh - q * b;
                    ad[comptime!(k + j) as usize] = v;
                    cd[comptime!(k + j) as usize] = v;
                    hh = q;
                }
                let mut an = Array::<u32>::new(comptime!(na as usize));
                let mut cn = Array::<u32>::new(comptime!(na as usize));
                limbs(&ad, &mut an, l, b);
                limbs(&cd, &mut cn, l, b);
                let mut a2 = Array::<u32>::new(comptime!((2 * na) as usize));
                let mut c2 = Array::<u32>::new(comptime!((2 * na) as usize));
                mul_l(&an, &an, &mut a2, na, na, bb);
                mul_l(&cn, &cn, &mut c2, na, na, bb);
                let mut a3 = Array::<u32>::new(comptime!((3 * na) as usize));
                let mut c3 = Array::<u32>::new(comptime!((3 * na) as usize));
                mul_l(&a2, &an, &mut a3, comptime!(2 * na), na, bb);
                mul_l(&c2, &cn, &mut c3, comptime!(2 * na), na, bb);
                let (l1, h1, bad1) = cert_w(&a2, &c2, 0u64, 0u32, b, s2, k);
                let (l2, h2, bad2) = cert_w(&a3, &c3, l1, h1, b, s3, k);
                ok = !bad1 && !bad2;
                lo = l2;
                hi = h2;
            }
            tm[i as usize] = lo;
            th[i as usize] = hi;
            tv[i as usize] = select(ok, 1u32, 0u32);
            if ok {
                segc[(d * m + h % m) as usize].fetch_add(1u32);
                if lo.count_ones() + hi.count_ones() > maxpop {
                    tstat[1usize].fetch_add(1u32);
                }
            }
        }
    }

    /// Each certified prefix into its segment: masks (lo, hi) and the thread index.
    #[cube(launch_unchecked)]
    pub fn wtops2_kernel(
        tm: &Array<u64>,
        th: &Array<u32>,
        tv: &Array<u32>,
        cur: &mut Array<Atomic<u32>>,
        tmask: &mut Array<u64>,
        tmh: &mut Array<u32>,
        thd: &mut Array<u32>,
        ntest: u32,
        nlead: u32,
        hlo: u32,
        cap: u32,
        #[comptime] b: u32,
    ) {
        let m = comptime!(b - 1);
        let i = ABSOLUTE_POS_X;
        if i < ntest {
            if tv[i as usize] == 1u32 {
                let d = i / nlead;
                let h = hlo + i % nlead;
                let slot = cur[(d * m + h % m) as usize].fetch_add(1u32);
                if slot < cap {
                    tmask[slot as usize] = tm[i as usize];
                    tmh[slot as usize] = th[i as usize];
                    thd[slot as usize] = i;
                }
            }
        }
    }

    /// The tops' digit table (7-bit fields, 4 per word, padded with the first digit), and the zeroing of the
    /// histogram and the list count for the slice's preparation.
    #[cube(launch_unchecked)]
    pub fn wtdigz_kernel(
        tmask: &Array<u64>,
        tmh: &Array<u32>,
        tdig: &mut Array<u32>,
        hist: &mut Array<u32>,
        lcnt: &mut Array<u32>,
        tstat: &Array<u32>,
        nbk: u32,
        cap: u32,
        #[comptime] b: u32,
    ) {
        // an empty top mask (no certified digit) pads with the pad digit, whose slice row is zero
        let pad = comptime!(if b > 64 { b } else { 64 });
        let i = ABSOLUTE_POS_X;
        if i < nbk {
            hist[i as usize] = 0u32;
        }
        if i == 0u32 {
            lcnt[0usize] = 0u32;
        }
        if i < min(tstat[0usize], cap) {
            let mut x = tmask[i as usize];
            let mut y = tmh[i as usize];
            let first = select(
                x != 0u64,
                x.trailing_zeros(),
                select(y != 0u32, 64u32 + y.trailing_zeros(), pad),
            );
            let mut dw = Array::<u32>::new(5usize);
            #[unroll]
            for kk in 0..5u32 {
                dw[kk as usize] = 0u32;
            }
            #[unroll]
            for kk in 0..20u32 {
                let xz = x != 0u64;
                let v = select(
                    xz,
                    x.trailing_zeros(),
                    select(y != 0u32, 64u32 + y.trailing_zeros(), first),
                );
                let ny = select(xz, y, y & (y - select(y != 0u32, 1u32, 0u32)));
                x &= x - select(xz, 1u64, 0u64);
                y = ny;
                dw[comptime!(kk / 4) as usize] |= v << comptime!(7 * (kk % 4));
            }
            #[unroll]
            for kk in 0..5u32 {
                tdig[(i * TDW + kk) as usize] = dw[kk as usize];
            }
        }
    }

    /// Records → survivor entries (top index, r mod b^f0); thread 0 copies the parent and slab counts to `stat`.
    #[cube(launch_unchecked)]
    pub fn wexpand_kernel(
        out: &Array<Vector<u32, Const<4>>>,
        slabn: &Array<u32>,
        slabcnt: &Array<u32>,
        pseg: &Array<u32>,
        tseg: &Array<u32>,
        roots: &Array<u32>,
        lst: &Array<u32>,
        lcnt: &Array<u32>,
        surv: &mut Array<u32>,
        scount: &mut Array<Atomic<u32>>,
        stat: &mut Array<u32>,
        nslab_cap: u32,
        scap: u32,
        c0: u32,
        #[comptime] b: u32,
        #[comptime] nroot: u32,
    ) {
        let m = comptime!(b - 1);
        if ABSOLUTE_POS_X == 0u32 {
            stat[0usize] = lcnt[0usize];
            stat[1usize] = slabn[0usize];
        }
        let ns = min(slabn[0usize], nslab_cap);
        let ppc = NT / PLANE_DIM;
        let pstride = CUBE_COUNT_X * ppc;
        let mut s = CUBE_POS_X * ppc + UNIT_POS_X / PLANE_DIM;
        while s < ns {
            let cnt = slabcnt[s as usize];
            let mut r0 = 0u32;
            while r0 < cnt {
                let r = r0 + UNIT_POS_PLANE;
                let i = s * SLAB + r;
                let live = r < cnt;
                let mut wlo = 0u32;
                let mut whi = 0u32;
                let mut ti = 0u32;
                let mut pos = 0u32;
                if live {
                    let rec = out[i as usize];
                    let ps = rec[0usize] & 0xFFFFu32;
                    let du = (rec[0usize] >> 16u32) & 255u32;
                    let c = rec[0usize] >> 24u32;
                    wlo = rec[2usize];
                    whi = rec[3usize];
                    let cc = (c + du) % m;
                    let mut rem = ps;
                    let mut found = false;
                    for kk in 0..nroot {
                        let ct = (roots[kk as usize] + m - cc) % m;
                        let sx = (du * m + ct) * 2u32;
                        let b0 = tseg[sx as usize];
                        let len = tseg[(sx + 1u32) as usize] - b0;
                        if !found {
                            if rem < len {
                                ti = b0 + rem;
                                found = true;
                            } else {
                                rem -= len;
                            }
                        }
                    }
                    let pb = pseg[c as usize];
                    let pe = pseg[(c + 1u32) as usize];
                    pos = (pb - pseg[c0 as usize]) * b + du * (pe - pb) + rec[1usize];
                }
                let nb = wlo.count_ones() + whi.count_ones();
                let excl = plane_exclusive_sum(nb);
                let tot = plane_sum(nb);
                let mut bs = 0u32;
                if UNIT_POS_PLANE == 0u32 && tot > 0u32 {
                    bs = scount[0usize].fetch_add(tot);
                }
                let mut slot = plane_sum(bs) + excl;
                if live {
                    let mut x = wlo;
                    while x != 0u32 {
                        let bt = x.trailing_zeros();
                        x &= x - 1u32;
                        if slot < scap {
                            surv[(2u32 * slot) as usize] = ti;
                            surv[(2u32 * slot + 1u32) as usize] = lst[(pos + bt) as usize];
                        }
                        slot += 1u32;
                    }
                    let mut y = whi;
                    while y != 0u32 {
                        let bt = y.trailing_zeros();
                        y &= y - 1u32;
                        if slot < scap {
                            surv[(2u32 * slot) as usize] = ti;
                            surv[(2u32 * slot + 1u32) as usize] = lst[(pos + 32u32 + bt) as usize];
                        }
                        slot += 1u32;
                    }
                }
                r0 += PLANE_DIM;
            }
            s += pstride;
        }
    }

    /// The full check of every survivor entry (grid-stride): n from (top, r mod b^f0) and the slice's digits, n²
    /// and n³ in base-b² limbs, the distinct digits of their s2 + s3 = b digits. Nice: all b distinct, written as
    /// (pip, top's thread index, r_f, 1). `ran[0]` and `ran[1]` count the entries and sum their indices; with
    /// `probe`, `pr[i]` = entry i's distinct digits.
    #[cube(launch_unchecked)]
    pub fn wcheck_kernel(
        surv: &Array<u32>,
        scount: &Array<u32>,
        thd: &Array<u32>,
        pipd: &Array<u32>,
        nice_out: &mut Array<u32>,
        nice_count: &mut Array<Atomic<u32>>,
        ran: &mut Array<Atomic<u32>>,
        pr: &mut Array<u32>,
        scap: u32,
        nice_cap: u32,
        nlead: u32,
        hlo: u32,
        pip: u32,
        clip: &Array<u32>, // plo (lo, hi), phi (lo, hi), start mod b^f0, (end − 1) mod b^f0
        #[comptime] b: u32,
        #[comptime] f0: u32,
        #[comptime] k: u32,
        #[comptime] l: u32,
        #[comptime] s2: u32,
        #[comptime] s3: u32,
        #[comptime] probe: bool,
    ) {
        let bb = comptime!(b * b);
        let bw = comptime!(b as u64);
        let plo = u64::cast_from(clip[0usize]) | (u64::cast_from(clip[1usize]) << 32u64);
        let phi = u64::cast_from(clip[2usize]) | (u64::cast_from(clip[3usize]) << 32u64);
        let slo = clip[4usize];
        let ehi = clip[5usize];
        let mut nclip = 0u32;
        let na = comptime!((l + 1) / 2);
        let count = min(scount[0usize], scap);
        let mut i = ABSOLUTE_POS_X;
        let stride = CUBE_COUNT_X * CUBE_DIM_X;
        let mut done = 0u32;
        let mut isum = 0u32;
        while i < count {
            let ti = surv[(2u32 * i) as usize];
            let rf = surv[(2u32 * i + 1u32) as usize];
            let ix = thd[ti as usize];
            let d = ix / nlead;
            let h = hlo + ix % nlead;
            // a top the range's ends clip holds n outside the range: only its prefix p can be plo or phi
            let mut p = u64::cast_from(h * b + d);
            #[unroll]
            for j in 0..comptime!(k - 1 - f0) {
                p = p * bw + u64::cast_from(pipd[comptime!(k - 2 - f0 - j) as usize]);
            }
            let out = (p == plo && rf < slo) || (p == phi && rf > ehi);
            let mut nd = Array::<u32>::new(comptime!(l as usize));
            let mut x = rf;
            #[unroll]
            for j in 0..f0 {
                let q = x / b;
                nd[j as usize] = x - q * b;
                x = q;
            }
            #[unroll]
            for j in 0..comptime!(k - 1 - f0) {
                nd[comptime!(f0 + j) as usize] = pipd[j as usize];
            }
            nd[comptime!(k - 1) as usize] = d;
            let mut hh = h;
            #[unroll]
            for j in 0..comptime!(l - k) {
                let q = hh / b;
                nd[comptime!(k + j) as usize] = hh - q * b;
                hh = q;
            }
            let mut nn = Array::<u32>::new(comptime!(na as usize));
            limbs(&nd, &mut nn, l, b);
            let mut sq = Array::<u32>::new(comptime!((2 * na) as usize));
            mul_l(&nn, &nn, &mut sq, na, na, bb);
            let mut cu = Array::<u32>::new(comptime!((3 * na) as usize));
            mul_l(&sq, &nn, &mut cu, comptime!(2 * na), na, bb);
            let mut lo = 0u64;
            let mut hi = 0u32;
            #[unroll]
            for j in 0..s2 {
                let (a, ah) = dbit(dig_l(&sq, j, b));
                lo |= a;
                hi |= ah;
            }
            #[unroll]
            for j in 0..s3 {
                let (a, ah) = dbit(dig_l(&cu, j, b));
                lo |= a;
                hi |= ah;
            }
            let uniq = lo.count_ones() + hi.count_ones();
            if comptime!(probe) {
                pr[i as usize] = select(out, u32::MAX, uniq);
            }
            if out {
                nclip += 1u32;
            } else if uniq == b {
                let pos = nice_count[0usize].fetch_add(1u32);
                if pos < nice_cap {
                    let o = 4u32 * pos;
                    nice_out[o as usize] = pip;
                    nice_out[(o + 1u32) as usize] = ix;
                    nice_out[(o + 2u32) as usize] = rf;
                    nice_out[(o + 3u32) as usize] = 1u32;
                }
            }
            done += 1u32;
            isum += i;
            i += stride;
        }
        if done > 0u32 {
            ran[0usize].fetch_add(done);
            ran[1usize].fetch_add(isum);
        }
        if nclip > 0u32 {
            ran[2usize].fetch_add(nclip);
        }
    }
}

// ------------------------------------------------------------------------------------------------ host

/// A base and shape as the wide device path sees them (all host-side facts).
#[derive(Clone, Debug)]
pub struct WideBase {
    pub b: u32,
    pub f0: u32,
    pub k: u32,
    /// Digits of n, n², n³ over the whole range.
    pub l: u32,
    pub s2: u32,
    pub s3: u32,
    pub roots: Vec<u32>,
    pub start: u128,
    pub end: u128,
    /// Leads h = n div b^k: [hlo, hlo + nlead).
    pub hlo: u32,
    pub nlead: u32,
    /// The range's prefixes n div b^f0: [plo, phi].
    pub plo: u64,
    pub phi: u64,
    /// The low f0 digits of start, then of end − 1 (then zeros to l each).
    pub ends: Vec<u32>,
}

impl WideBase {
    /// # Errors
    /// A base or shape outside what the layouts hold.
    pub fn new(coord: &Coord, sh: Shape) -> Result<Self> {
        let b = coord.b;
        let (f0, k) = (sh.f0, sh.k);
        ensure!(
            (3..=MAXB).contains(&b),
            "middle-out wide: base {b} outside 3-{MAXB}"
        );
        let (start, end) = (coord.start, coord.end);
        let l = ndigits(end - 1, b);
        ensure!(
            k >= 2 && f0 < k && k <= l,
            "middle-out wide: shape (f0 {f0}, k {k}) for {l}-digit n"
        );
        let bu = u128::from(b);
        ensure!(
            bu.pow(f0) < 1 << RF_BITS,
            "middle-out wide: b^f0 reaches 2^{RF_BITS}"
        );
        ensure!(
            bu.pow(k - 1 - f0) <= 1 << 32,
            "middle-out wide: a slice's digits do not fit 32 bits"
        );
        // digits of n² and n³ (U384: n³ passes 2^128 from base 41 on)
        let pd = |x: u128| -> (u32, u32) {
            let v = U384::from_u128(x);
            let sq = v.mul(&v);
            let cu = sq.mul(&v);
            (
                sq.digits(u64::from(b)).len() as u32,
                cu.digits(u64::from(b)).len() as u32,
            )
        };
        let (s2, s3) = pd(start);
        let e1 = end - 1;
        ensure!(
            pd(e1) == (s2, s3) && s2 + s3 == b,
            "middle-out wide: n², n³ change length over the range"
        );
        // limb columns: na products below b⁴ plus a carry
        let na = u128::from(l.div_ceil(2));
        ensure!(
            2 * na * bu.pow(4) < 1 << 31,
            "middle-out wide: limb columns reach 2^31"
        );
        let bk = bu.pow(k);
        let hlo = start / bk;
        let nlead = e1 / bk - hlo + 1;
        ensure!(
            u128::from(b) * nlead < 1 << 32 && hlo + nlead < 1 << 32,
            "middle-out wide: tops of a slice do not fit 32 bits"
        );
        let bf = bu.pow(f0);
        let (plo, phi) = (start / bf, e1 / bf);
        ensure!(phi < 1 << 64, "middle-out wide: prefixes reach 2^64");
        let mut ends = vec![0u32; 2 * l as usize];
        for j in 0..f0 {
            ends[j as usize] = ((start / bu.pow(j)) % bu) as u32;
            ends[(l + j) as usize] = ((e1 / bu.pow(j)) % bu) as u32;
        }
        Ok(Self {
            b,
            f0,
            k,
            l,
            s2,
            s3,
            roots: base_roots(b),
            start,
            end,
            hlo: hlo as u32,
            nlead: nlead as u32,
            plo: plo as u64,
            phi: phi as u64,
            ends,
        })
    }

    pub fn m(&self) -> u32 {
        self.b - 1
    }

    /// Prefixes a slice tests: b · nlead threads.
    pub fn ntest(&self) -> u32 {
        self.b * self.nlead
    }

    /// The digits [f0, k − 1) of a slice, least significant first.
    pub fn pip_digits(&self, pip: u64) -> Vec<u32> {
        let mut x = pip;
        (0..(self.k - 1 - self.f0))
            .map(|_| {
                let v = (x % u64::from(self.b)) as u32;
                x /= u64::from(self.b);
                v
            })
            .collect()
    }

    /// n of a survivor: its top's thread index ix (d, h), the slice and r mod b^f0.
    pub fn n_of(&self, pip: u64, ix: u32, rf: u32) -> u128 {
        let bu = u128::from(self.b);
        let d = u128::from(ix / self.nlead);
        let h = u128::from(self.hlo + ix % self.nlead);
        ((h * bu + d) * bu.pow(self.k - 1 - self.f0) + u128::from(pip)) * bu.pow(self.f0)
            + u128::from(rf)
    }

    /// Prefixes of a slice inside the range (the CPU reference's `tops_tested`).
    pub fn tested(&self, pip: u64) -> u64 {
        let bu = u128::from(self.b);
        let mut n = 0u64;
        for d in 0..bu {
            let p0 =
                (u128::from(self.hlo) * bu + d) * bu.pow(self.k - 1 - self.f0) + u128::from(pip);
            let step = bu.pow(self.k - self.f0);
            let mut cnt = u64::from(self.nlead);
            if p0 < u128::from(self.plo) {
                cnt -= 1;
            }
            let p1 = p0 + step * u128::from(self.nlead - 1);
            if p1 > u128::from(self.phi) {
                cnt -= 1;
            }
            n += cnt;
        }
        n
    }
}

/// Capacities and per-base settings of the wide path.
#[derive(Clone, Copy, Debug)]
pub struct WideCaps {
    pub parents: u32,
    pub tops: u32,
    /// Survivors of a whole slice (a batch gets its share, plus slack).
    pub survivors: u32,
    /// Classes per launch batch (b − 1: one batch per slice; lavapipe fewer).
    pub classes: u32,
    pub nice: u32,
    /// Instances of PMAX probes per job.
    pub ninst: u32,
    /// Digits of a top mask the kernel reads.
    pub maxpop: u32,
    /// Tests: per-entry distinct digits from the check.
    pub probe: bool,
}

impl WideCaps {
    /// Defaults for base `b` (classes = all).
    pub fn for_base(b: u32) -> Self {
        let (parents, tops, survivors, ninst, maxpop) = match b {
            0..=40 => (1 << 20, 1 << 20, 1 << 22, 4, 20),
            41..=64 => (2_100_000, 480_000, 24_000_000, 2, 17),
            65 => (4_000_000, 3_000_000, 40_000_000, 2, 18),
            // base 68: 89M prefixes and ~143M survivors per slice; 3.5k-6.3k probes per job (bases/RESULTS.md)
            _ => (4_000_000, 16_000_000, 200_000_000, 12, 19),
        };
        WideCaps {
            parents,
            tops,
            survivors,
            classes: b - 1,
            nice: 4096,
            ninst,
            maxpop,
            probe: false,
        }
    }
}

/// What the device did for a group of slices (sums).
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct WCounts {
    pub children: u64,
    pub chunks: u64,
    pub flat: u64,
    pub kept: u64,
    pub survivors: u64,
    pub checked: u64,
    pub slices: u64,
    pub tops: u64,
}

impl WCounts {
    fn add(&mut self, o: &WCounts) {
        self.children += o.children;
        self.chunks += o.chunks;
        self.flat += o.flat;
        self.kept += o.kept;
        self.survivors += o.survivors;
        self.checked += o.checked;
        self.slices += o.slices;
        self.tops += o.tops;
    }
}

struct WSlice {
    pip: u64,
    pipd: Handle,
    tmh: Handle,
    tmhh: Handle,
    tsegh: Handle,
    thdh: Handle,
    tstat: Handle,
}

struct WTicket {
    /// Job instances the batch launched.
    jobs: u32,
    ran: Handle,
    scount: Handle,
    stat: Handle,
    tstat: Option<Handle>,
}

/// The wide device path for one base and shape: kernels compiled for one
/// plane width, buffers allocated once.
pub struct WideJoin<R: Runtime> {
    client: ComputeClient<R>,
    pub w: u32,
    fill: u32,
    pub caps: WideCaps,
    pub wb: WideBase,
    nbk: u32,
    nseg: u32,
    nrf: u32,
    rfh: Handle,
    roots_h: Handle,
    ends_h: Handle,
    clip_h: Handle,
    /// Per batch: (c0, c1, jobs buffer, job instances).
    pub batches: Vec<(u32, u32, Handle, u32)>,
    plast: u32,
    nslab_cap: u32,
    scap: u32,
    lcap: u32,
    out: Handle,
    slabcnt: Handle,
    g_tmp: Handle,
    g_lst: Handle,
    g_lkey: Handle,
    g_rec: Handle,
    g_tdig: Handle,
    histh: Handle,
    lcnt: Handle,
    off: Handle,
    curh: Handle,
    g_pseg: Handle,
    pstot: Handle,
    clst: Handle,
    surv: Handle,
    pr: Handle,
    nice_out: Handle,
    nice_count: Handle,
    tm: Handle,
    th: Handle,
    tv: Handle,
    /// Timing (`MIDOUT_STOP`): 1 tops, 2 parents, 3 main kernel, 5 expansion, 6 all.
    stop: u32,
}

impl<R: Runtime> WideJoin<R> {
    /// # Errors
    /// A plane width or base the kernels do not take.
    pub fn new(client: ComputeClient<R>, caps: WideCaps, coord: &Coord, sh: Shape) -> Result<Self> {
        let w = client.properties().hardware.plane_size_max;
        ensure!(
            [8u32, 16, 32, 64].contains(&w),
            "middle-out wide: plane width {w} not supported"
        );
        let wb = WideBase::new(coord, sh)?;
        let m = wb.m();
        ensure!(
            caps.classes >= 1 && caps.classes <= m,
            "middle-out wide: classes per batch 1-{m}"
        );
        ensure!(
            caps.maxpop >= 1 && caps.maxpop <= 20,
            "middle-out wide: maxpop 1-20"
        );
        ensure!(caps.ninst >= 1, "middle-out wide: ninst >= 1");
        ensure!(
            caps.ninst * PMAX < 1 << 16,
            "middle-out wide: probe slots reach 2^16"
        );
        let fill = if w < 32 { 512 } else { FILL };
        let base = Base::new(coord);
        let rfs: Vec<u32> = {
            let mut v: Vec<u32> = bottoms::<u128>(&base, wb.f0, wb.f0, 0)
                .into_iter()
                .map(|x| x.r as u32)
                .collect();
            v.sort_unstable();
            v
        };
        let nrf = rfs.len() as u32;
        let mk = |v: Vec<u32>| client.create(cubecl::bytes::Bytes::from_elems(v));
        let rfh = mk(if rfs.is_empty() { vec![0] } else { rfs });
        let roots_h = mk(wb.roots.clone());
        let ends_h = mk(wb.ends.clone());
        let bf = u128::from(wb.b).pow(wb.f0);
        let clip_h = mk(vec![
            wb.plo as u32,
            (wb.plo >> 32) as u32,
            wb.phi as u32,
            (wb.phi >> 32) as u32,
            (wb.start % bf) as u32,
            ((wb.end - 1) % bf) as u32,
        ]);
        let mut batches = Vec::new();
        let mut c0 = 0;
        while c0 < m {
            let c1 = (c0 + caps.classes).min(m);
            let mut jobs: Vec<u32> = Vec::new();
            for inst in 0..caps.ninst {
                for c in c0..c1 {
                    for d in 0..wb.b {
                        jobs.push(c);
                        jobs.push(d | (inst * PMAX) << 8);
                    }
                }
            }
            let nj = (jobs.len() / 2) as u32;
            batches.push((c0, c1, mk(jobs), nj));
            c0 = c1;
        }
        let share = |x: u32| -> u32 {
            ((x as u64 * caps.classes as u64).div_ceil(m as u64) as u32).saturating_add(x / 16)
        };
        let scap = share(caps.survivors);
        let jobs_max = caps.ninst * caps.classes * wb.b;
        let nslab_cap = scap / SLAB + jobs_max * (NT / w) + 64;
        let lcap = wb.b * share(caps.parents);
        let np = caps.parents as usize;
        let nt = caps.tops as usize;
        let nbk = m * 256;
        let nseg = wb.b * m;
        let ntest = wb.ntest() as usize;
        let e = |bytes: usize| client.empty(bytes.max(4));
        Ok(Self {
            w,
            fill,
            nbk,
            nseg,
            nrf,
            rfh,
            roots_h,
            ends_h,
            clip_h,
            batches,
            plast: (caps.ninst - 1) * PMAX,
            nslab_cap,
            scap,
            lcap,
            out: e(nslab_cap as usize * SLAB as usize * 16),
            slabcnt: e(nslab_cap as usize * 4),
            g_tmp: e(np * 16),
            g_lst: e(np * 16),
            g_lkey: e(np * 4),
            g_rec: e(np * 16),
            g_tdig: e(nt * TDW as usize * 4),
            histh: mk(vec![0u32; nbk as usize]),
            lcnt: mk(vec![0u32; 1]),
            off: e(nbk as usize * 4),
            curh: e(nbk.max(nseg) as usize * 4),
            g_pseg: e((m as usize + 1) * 4),
            pstot: e(4),
            clst: e(lcap as usize * 4),
            surv: e(scap as usize * 8),
            pr: e(if caps.probe { scap as usize * 4 } else { 4 }),
            nice_out: mk(vec![0u32; caps.nice as usize * NICE_STRIDE]),
            nice_count: mk(vec![0u32; 1]),
            tm: e(ntest * 8),
            th: e(ntest * 4),
            tv: e(ntest * 4),
            stop: std::env::var("MIDOUT_STOP")
                .ok()
                .and_then(|x| x.parse().ok())
                .unwrap_or(6),
            caps,
            wb,
            client,
        })
    }

    fn upto(&self, k: u32) -> bool {
        self.stop >= k
    }

    pub fn mk(&self, v: Vec<u32>) -> Handle {
        self.client.create(cubecl::bytes::Bytes::from_elems(v))
    }

    fn rd(&self, h: &Handle) -> Result<Vec<u32>> {
        Ok(u32::from_bytes(
            &self
                .client
                .read_one(h.clone())
                .map_err(|e| anyhow!("read: {e:?}"))?,
        )
        .to_vec())
    }

    fn sync(&self) -> Result<()> {
        cubecl::future::block_on(self.client.sync()).map_err(|e| anyhow!("sync: {e:?}"))
    }

    /// Queue a slice's tops and parents.
    fn queue_prep(&self, pip: u64, rankh: &Handle) -> WSlice {
        let wb = &self.wb;
        let c = &self.client;
        let nt = self.caps.tops as usize;
        let np = self.caps.parents as usize;
        let a = |h: &Handle, n: usize| unsafe { ArrayArg::from_raw_parts(h.clone(), n.max(1)) };
        let pd = wb.pip_digits(pip);
        let npd = pd.len();
        let pipd = self.mk(if pd.is_empty() { vec![0] } else { pd });
        let nseg = self.nseg as usize;
        let segc = self.mk(vec![0u32; nseg]);
        let tstat = self.mk(vec![0u32; 2]);
        let tsegh = self.client.empty(nseg * 2 * 4);
        let tmh = self.client.empty(nt * 8);
        let tmhh = self.client.empty(nt * 4);
        let thdh = self.client.empty(nt * 4);
        let cur = self.client.empty(nseg * 4);
        let dummy = self.client.empty(4);
        let ntest = wb.ntest();
        let (b, f0, k, l) = (wb.b, wb.f0, wb.k, wb.l);
        unsafe {
            if self.upto(1) {
                wp::wtops1_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static(ntest.div_ceil(NT), 1, 1),
                    CubeDim::new_1d(NT),
                    a(&self.tm, ntest as usize),
                    a(&self.th, ntest as usize),
                    a(&self.tv, ntest as usize),
                    a(&segc, nseg),
                    a(&tstat, 2),
                    a(&pipd, npd),
                    a(&self.ends_h, 2 * l as usize),
                    ntest,
                    wb.nlead,
                    wb.hlo,
                    wb.plo as u32,
                    (wb.plo >> 32) as u32,
                    wb.phi as u32,
                    (wb.phi >> 32) as u32,
                    b,
                    f0,
                    k,
                    l,
                    wb.s2,
                    wb.s3,
                    self.caps.maxpop,
                );
                wp::wscan_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static(1, 1, 1),
                    CubeDim::new_1d(1024),
                    a(&segc, nseg),
                    a(&tsegh, 2 * nseg),
                    a(&cur, nseg),
                    a(&dummy, 1),
                    a(&tstat, 2),
                    self.nseg,
                    1u32,
                    true,
                );
                wp::wtops2_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static(ntest.div_ceil(NT), 1, 1),
                    CubeDim::new_1d(NT),
                    a(&self.tm, ntest as usize),
                    a(&self.th, ntest as usize),
                    a(&self.tv, ntest as usize),
                    a(&cur, nseg),
                    a(&tmh, nt),
                    a(&tmhh, nt),
                    a(&thdh, nt),
                    ntest,
                    wb.nlead,
                    wb.hlo,
                    nt as u32,
                    b,
                );
                wp::wtdigz_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static((nt as u32).max(self.nbk).div_ceil(NT), 1, 1),
                    CubeDim::new_1d(NT),
                    a(&tmh, nt),
                    a(&tmhh, nt),
                    a(&self.g_tdig, nt * TDW as usize),
                    a(&self.histh, self.nbk as usize),
                    a(&self.lcnt, 1),
                    a(&tstat, 2),
                    self.nbk,
                    nt as u32,
                    b,
                );
            }
            if self.upto(2) {
                let nbk = self.nbk as usize;
                wp::whist_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static(self.nrf.div_ceil(NT).max(1), 1, 1),
                    CubeDim::new_1d(NT),
                    a(&self.rfh, self.nrf as usize),
                    a(&pipd, npd),
                    a(rankh, 8),
                    a(&self.histh, nbk),
                    a(&self.g_lst, np),
                    a(&self.g_lkey, np),
                    a(&self.lcnt, 1),
                    self.nrf,
                    (pip % u64::from(wb.m())) as u32,
                    np as u32,
                    self.w,
                    b,
                    f0,
                    k,
                );
                wp::wscan_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static(1, 1, 1),
                    CubeDim::new_1d(1024),
                    a(&self.histh, nbk),
                    a(&self.off, nbk),
                    a(&self.curh, nbk),
                    a(&self.g_pseg, wb.m() as usize + 1),
                    a(&self.pstot, 1),
                    self.nbk,
                    256u32,
                    false,
                );
                wp::wscatter_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static((np as u32).div_ceil(NT), 1, 1),
                    CubeDim::new_1d(NT),
                    a(&self.g_lst, np),
                    a(&self.g_lkey, np),
                    a(&self.lcnt, 1),
                    a(&self.curh, nbk),
                    a(&self.g_tmp, np * 4),
                    np as u32,
                );
                wp::wsort_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static(self.nbk, 1, 1),
                    CubeDim::new_1d(256),
                    a(&self.off, nbk),
                    a(&self.histh, nbk),
                    a(&self.g_tmp, np * 4),
                    a(&self.g_rec, np * 4),
                );
            }
        }
        WSlice {
            pip,
            pipd,
            tmh,
            tmhh,
            tsegh,
            thdh,
            tstat,
        }
    }

    /// Queue one launch batch of a prepared slice.
    fn queue_batch(&self, ws: &WSlice, bi: usize, cnt: &Handle) -> WTicket {
        let (c0, _c1, jobs, nj) = &self.batches[bi];
        let wb = &self.wb;
        let c = &self.client;
        let np = self.caps.parents as usize;
        let nt = self.caps.tops as usize;
        let nseg = self.nseg as usize;
        let a = |h: &Handle, n: usize| unsafe { ArrayArg::from_raw_parts(h.clone(), n.max(1)) };
        let slabn = self.mk(vec![0u32]);
        let scount = self.mk(vec![0u32]);
        let ran = self.mk(vec![0u32; 3]);
        let stat = self.mk(vec![0u32; 2]);
        let ns = self.nslab_cap as usize;
        let npd = (wb.k - 1 - wb.f0) as usize;
        unsafe {
            if self.upto(3) {
                wk::wide_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static(*nj, 1, 1),
                    CubeDim::new_1d(NT),
                    a(&self.g_rec, np),
                    a(&self.g_pseg, wb.m() as usize + 1),
                    a(&self.g_tdig, nt * TDW as usize),
                    a(&ws.tsegh, 2 * nseg),
                    a(&self.roots_h, wb.roots.len()),
                    a(jobs, 2 * *nj as usize),
                    a(cnt, NCNT),
                    a(&self.out, ns * SLAB as usize),
                    a(&slabn, 1),
                    a(&self.slabcnt, ns),
                    self.nslab_cap,
                    a(&self.clst, self.lcap as usize),
                    *c0,
                    self.plast,
                    self.w,
                    self.fill,
                    wb.b,
                    wb.roots.len() as u32,
                    self.caps.maxpop,
                );
            }
            if self.upto(5) {
                wp::wexpand_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static(EXPAND_CUBES, 1, 1),
                    CubeDim::new_1d(NT),
                    a(&self.out, ns * SLAB as usize),
                    a(&slabn, 1),
                    a(&self.slabcnt, ns),
                    a(&self.g_pseg, wb.m() as usize + 1),
                    a(&ws.tsegh, 2 * nseg),
                    a(&self.roots_h, wb.roots.len()),
                    a(&self.clst, self.lcap as usize),
                    a(&self.lcnt, 1),
                    a(&self.surv, 2 * self.scap as usize),
                    a(&scount, 1),
                    a(&stat, 2),
                    self.nslab_cap,
                    self.scap,
                    *c0,
                    wb.b,
                    wb.roots.len() as u32,
                );
            }
            if self.upto(6) {
                wp::wcheck_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static(CHECK_CUBES, 1, 1),
                    CubeDim::new_1d(CHECK_WG),
                    a(&self.surv, 2 * self.scap as usize),
                    a(&scount, 1),
                    a(&ws.thdh, nt),
                    a(&ws.pipd, npd),
                    a(&self.nice_out, self.caps.nice as usize * NICE_STRIDE),
                    a(&self.nice_count, 1),
                    a(&ran, 3),
                    a(
                        &self.pr,
                        if self.caps.probe {
                            self.scap as usize
                        } else {
                            1
                        },
                    ),
                    self.scap,
                    self.caps.nice,
                    wb.nlead,
                    wb.hlo,
                    ws.pip as u32,
                    a(&self.clip_h, 6),
                    wb.b,
                    wb.f0,
                    wb.k,
                    wb.l,
                    wb.s2,
                    wb.s3,
                    self.caps.probe,
                );
            }
        }
        WTicket {
            jobs: if self.upto(3) { *nj } else { 0 },
            ran,
            scount,
            stat,
            tstat: None,
        }
    }

    /// Queue a whole slice into the group's counters.
    fn queue_slice(&self, pip: u64, rankh: &Handle, cnt: &Handle, out: &mut Vec<WTicket>) {
        let ws = self.queue_prep(pip, rankh);
        for bi in 0..self.batches.len() {
            let mut t = self.queue_batch(&ws, bi, cnt);
            if bi == 0 {
                t.tstat = Some(ws.tstat.clone());
            }
            out.push(t);
        }
    }

    /// Synchronise and check every account of a group.
    fn finish_group(&self, cnt: &Handle, tickets: &[WTicket]) -> Result<WCounts> {
        self.sync()?;
        if self.stop != 6 {
            return Ok(WCounts::default());
        }
        let v = self.rd(cnt)?;
        ensure!(
            v[C_ERR_PLANE] == 0 && v[C_ERR_PMAX] == 0 && v[C_ERR_SLAB] == 0 && v[C_ERR_CLASS] == 0,
            "middle-out wide kernel errors: plane {} pmax {} slab {} class {}",
            v[C_ERR_PLANE],
            v[C_ERR_PMAX],
            v[C_ERR_SLAB],
            v[C_ERR_CLASS]
        );
        let mut dc = WCounts::default();
        for d in 0..self.wb.b as usize {
            dc.children += v[d * 5] as u64;
            dc.chunks += v[d * 5 + 1] as u64;
            dc.flat += v[d * 5 + 2] as u64;
            dc.kept += v[d * 5 + 3] as u64;
            dc.survivors += v[d * 5 + 4] as u64;
        }
        let jobs: u64 = tickets.iter().map(|t| u64::from(t.jobs)).sum();
        ensure!(
            u64::from(v[C_JOBS]) == jobs,
            "middle-out wide: {} of {jobs} job instances ran",
            v[C_JOBS]
        );
        let mut listed = 0u64;
        let mut clipped = 0u64;
        for t in tickets {
            let n = self.rd(&t.scount)?[0];
            ensure!(
                n <= self.scap,
                "middle-out wide: survivor list overflow {n} > {}",
                self.scap
            );
            let ran = self.rd(&t.ran)?;
            let want_sum = (u64::from(n) * u64::from(n.saturating_sub(1)) / 2 % (1 << 32)) as u32;
            ensure!(
                ran[0] == n && ran[1] == want_sum,
                "middle-out wide: check incomplete: {} of {n} entries, index sum {} (want {want_sum})",
                ran[0],
                ran[1]
            );
            if let Some(ts) = &t.tstat {
                let s = self.rd(ts)?;
                ensure!(
                    s[0] <= self.caps.tops,
                    "middle-out wide: {} tops > cap {}",
                    s[0],
                    self.caps.tops
                );
                ensure!(
                    s[1] == 0,
                    "middle-out wide: {} tops of more than {} digits",
                    s[1],
                    self.caps.maxpop
                );
                dc.tops += u64::from(s[0]);
            }
            let st = self.rd(&t.stat)?;
            ensure!(
                st[0] <= self.caps.parents,
                "middle-out wide: {} parents > cap {}",
                st[0],
                self.caps.parents
            );
            ensure!(
                st[1] <= self.nslab_cap,
                "middle-out wide: {} slabs > cap {}",
                st[1],
                self.nslab_cap
            );
            listed += u64::from(n);
            clipped += u64::from(ran[2]);
            dc.checked += u64::from(ran[0] - ran[2]);
        }
        ensure!(
            listed == dc.survivors,
            "middle-out wide: {listed} survivors listed, the kernel counted {}",
            dc.survivors
        );
        // survivor bits of a clipped top outside the range are not survivors (the reference's `clipped`)
        dc.survivors -= clipped;
        Ok(dc)
    }

    /// The 8 key digits of a slice from the device's own tops and parents
    /// (every top, every parent: the CPU reference's rule exactly).
    ///
    /// # Errors
    /// Device errors.
    pub fn rank_of(&self, pip: u64) -> Result<[u32; 8]> {
        let b = self.wb.b;
        let rankh = self.mk((0..8).map(|i| i % b).collect());
        let ws = self.queue_prep(pip, &rankh);
        self.sync()?;
        let ntops = (self.rd(&ws.tstat)?[0] as usize).min(self.caps.tops as usize);
        let tm = self.rd(&ws.tmh)?;
        let tmh = self.rd(&ws.tmhh)?;
        let mut ft = vec![0u64; b as usize];
        for i in 0..ntops {
            let mut lo = u64::from(tm[2 * i]) | u64::from(tm[2 * i + 1]) << 32;
            while lo != 0 {
                ft[lo.trailing_zeros() as usize] += 1;
                lo &= lo - 1;
            }
            let mut hi = tmh[i];
            while hi != 0 {
                ft[64 + hi.trailing_zeros() as usize] += 1;
                hi &= hi - 1;
            }
        }
        let np = (self.rd(&self.lcnt)?[0] as usize).min(self.caps.parents as usize);
        let lst = self.rd(&self.g_lst)?;
        let mut fp = vec![0u64; b as usize];
        for i in 0..np {
            let mut lo = u64::from(lst[4 * i]) | u64::from(lst[4 * i + 1]) << 32;
            while lo != 0 {
                fp[lo.trailing_zeros() as usize] += 1;
                lo &= lo - 1;
            }
            let mut hi = lst[4 * i + 3] >> RF_BITS;
            while hi != 0 {
                fp[64 + hi.trailing_zeros() as usize] += 1;
                hi &= hi - 1;
            }
        }
        key_digits(b, &fp, &ft)
            .try_into()
            .map_err(|_| anyhow!("8 key digits"))
    }

    /// One slice alone (tests): counts, survivors as n (read back per
    /// batch), the check's distinct-digit counts per survivor (with
    /// `probe`), and the tops (thread index, mask lo, hi).
    ///
    /// # Errors
    /// Device errors or a failed account.
    pub fn run_slice(
        &self,
        pip: u64,
        rank: &[u32; 8],
    ) -> Result<(WCounts, Vec<(u128, u32)>, Vec<(u32, u64, u32)>)> {
        let cnt = self.mk(vec![0u32; NCNT]);
        let rankh = self.mk(rank.to_vec());
        let ws = self.queue_prep(pip, &rankh);
        self.sync()?;
        let ntops = (self.rd(&ws.tstat)?[0] as usize).min(self.caps.tops as usize);
        let thd = self.rd(&ws.thdh)?;
        let tm = self.rd(&ws.tmh)?;
        let tmh = self.rd(&ws.tmhh)?;
        let tops: Vec<(u32, u64, u32)> = (0..ntops)
            .map(|i| {
                (
                    thd[i],
                    u64::from(tm[2 * i]) | u64::from(tm[2 * i + 1]) << 32,
                    tmh[i],
                )
            })
            .collect();
        let mut tk = Vec::new();
        let mut v = Vec::new();
        for bi in 0..self.batches.len() {
            let mut t = self.queue_batch(&ws, bi, &cnt);
            if bi == 0 {
                t.tstat = Some(ws.tstat.clone());
            }
            self.sync()?;
            let n = self.rd(&t.scount)?[0] as usize;
            ensure!(
                n <= self.scap as usize,
                "run_slice: list overflow {n} > {}",
                self.scap
            );
            let list = self.rd(&self.surv)?;
            let pr = if self.caps.probe {
                self.rd(&self.pr)?
            } else {
                vec![0; n]
            };
            for i in 0..n {
                let ix = thd[list[2 * i] as usize];
                let nn = self.wb.n_of(pip, ix, list[2 * i + 1]);
                if !self.caps.probe {
                    v.push((nn, 0));
                } else if pr[i] != u32::MAX {
                    v.push((nn, pr[i]));
                } else {
                    ensure!(
                        nn < self.wb.start || nn >= self.wb.end,
                        "run_slice: {nn} in the range marked clipped"
                    );
                }
            }
            tk.push(t);
        }
        let mut dc = self.finish_group(&cnt, &tk)?;
        dc.slices = 1;
        Ok((dc, v, tops))
    }

    /// The nice numbers the check has written so far, ascending.
    pub fn nice(&self) -> Result<Vec<u128>> {
        let n = self.rd(&self.nice_count)?[0] as usize;
        ensure!(
            n <= self.caps.nice as usize,
            "middle-out wide: nice output overflow {n}"
        );
        let w = self.rd(&self.nice_out)?;
        let mut v: Vec<u128> = (0..n)
            .map(|i| {
                let o = i * NICE_STRIDE;
                self.wb.n_of(u64::from(w[o]), w[o + 1], w[o + 2])
            })
            .collect();
        v.sort_unstable();
        Ok(v)
    }
}

/// Search a field on the wide device path: the key from the field's first
/// slice (the device's tops and parents), then every slice queued, one
/// synchronisation per `group` slices.
///
/// # Errors
/// A field that is not whole quanta, a shape that cannot search it, or any
/// failed account.
pub fn search_field_wide<R: Runtime>(
    gj: &WideJoin<R>,
    coord: &Coord,
    v_start: u128,
    v_size: u128,
    group: usize,
) -> Result<(FieldOutcome, WCounts, FieldTiming)> {
    let sh = Shape {
        f0: gj.wb.f0,
        k: gj.wb.k,
    };
    ensure!(coord.b == gj.wb.b, "middle-out wide: base mismatch");
    sh.fits(coord)?;
    let ts = coord.field_digits(v_start, v_size)?;
    let pips: Vec<u64> = ts
        .flat_map(|t| sh.slices_of(coord, t).map(|p| p as u64).collect::<Vec<_>>())
        .collect();
    let nice_before = gj.nice()?;
    let t0 = Instant::now();
    let rank = gj.rank_of(pips[0])?;
    let host_wait = t0.elapsed().as_secs_f64();
    let rankh = gj.mk(rank.to_vec());
    let mut total = WCounts::default();
    let mut sync_s = 0f64;
    let mut done = 0usize;
    while done < pips.len() {
        let cnt = gj.mk(vec![0u32; NCNT]);
        let mut tk = Vec::new();
        let k0 = done;
        while done < pips.len() && done - k0 < group {
            gj.queue_slice(pips[done], &rankh, &cnt, &mut tk);
            done += 1;
        }
        let tsync = Instant::now();
        let mut g = gj.finish_group(&cnt, &tk)?;
        sync_s += tsync.elapsed().as_secs_f64();
        g.slices = (done - k0) as u64;
        total.add(&g);
    }
    let wall = t0.elapsed().as_secs_f64();
    let mut nice = gj.nice()?;
    for n in &nice_before {
        if let Some(i) = nice.iter().position(|x| x == n) {
            nice.remove(i);
        }
    }
    for &n in &nice {
        ensure!(
            super::arith::unique_digits(n, coord.b).1,
            "middle-out wide: device reported {n}, not nice"
        );
    }
    if total.slices != pips.len() as u64 {
        bail!("middle-out wide: {} of {} slices", total.slices, pips.len());
    }
    Ok((
        FieldOutcome {
            nice,
            survivors: total.survivors,
            checked: total.checked,
            slices: total.slices,
        },
        total,
        FieldTiming {
            wall,
            host_wait,
            sync: sync_s,
            field: wall,
            ..FieldTiming::default()
        },
    ))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::midout::arith::unique_digits;
    use crate::midout::cpu::{Counts, slice_join};

    #[test]
    fn wide_bases_fit_the_layouts() {
        for (b, f0, k) in [
            (30, 2, 5),
            (40, 3, 6),
            (50, 3, 7),
            (64, 4, 10),
            (65, 4, 10),
            (68, 4, 10),
            (69, 4, 10),
            (70, 4, 10),
        ] {
            let coord = Coord::with_digits(b, 0, 1, 0).unwrap();
            let wb = WideBase::new(&coord, Shape { f0, k }).unwrap();
            assert_eq!(wb.s2 + wb.s3, b);
            if b > 40 {
                continue;
            }
            // the tested count = the reference's rule (cpu::unit_tops) on two slices
            let base = Base::new(&coord);
            for pip in [0u64, (u64::from(b).pow(k - 1 - f0)) - 1] {
                let mut tested = 0u64;
                for d in 0..u128::from(b) {
                    let uval = u128::from(pip) + d * base.pw[(k - 1 - f0) as usize];
                    let _ = crate::midout::cpu::unit_tops::<u128>(
                        &base,
                        Shape { f0, k },
                        uval,
                        &mut tested,
                    );
                }
                assert_eq!(wb.tested(pip), tested, "b{b} pip {pip}");
                // n_of inverts the digits
                let n = wb.n_of(pip, wb.nlead + 1, 7);
                assert_eq!(n % base.pw[f0 as usize], 7);
            }
        }
    }

    fn device() -> Option<crate::cubecl_backend::CubeclContext> {
        #[cfg(feature = "cubecl-cuda")]
        if std::env::var("MIDOUT_CUDA").is_ok() {
            return crate::cubecl_backend::CubeclContext::new_cuda(0).ok();
        }
        crate::cubecl_backend::CubeclContext::new_default().ok()
    }

    /// One slice through the CPU reference (u128 masks) on `threads` threads
    /// (units split), survivors with their units.
    fn cpu_slice(coord: &Coord, sh: Shape, pip: u128) -> (Counts, Vec<u128>) {
        let base = Base::new(coord);
        let mut v = Vec::new();
        let cn = slice_join::<u128>(&base, sh, pip, |_, n, _| v.push(n));
        v.sort_unstable();
        (cn, v)
    }

    /// The wide device path against the CPU reference on whole slices: tops
    /// count, survivor sets n for n, children, chunks, flat, kept (the key is
    /// the reference's rule), survivors = checked, and the check's distinct
    /// digits of every survivor = the reference's. `MIDOUT_WIDE_CASES` is a
    /// comma list of `b:f0:k:pip` (default a b65 slice); `MIDOUT_CLASSES`
    /// the batch width.
    #[test]
    #[ignore = "needs a GPU (MIDOUT_CUDA=1 for the CUDA runtime) and minutes of CPU"]
    fn wide_slices_equal_cpu() {
        let ctx = device().expect("a device");
        let cases: Vec<(u32, u32, u32, u64)> = std::env::var("MIDOUT_WIDE_CASES")
            .unwrap_or_else(|_| "65:4:10:717171717".into())
            .split(',')
            .map(|s| {
                let f: Vec<u64> = s.split(':').map(|x| x.parse().unwrap()).collect();
                (f[0] as u32, f[1] as u32, f[2] as u32, f[3])
            })
            .collect();
        let classes: Option<u32> = std::env::var("MIDOUT_CLASSES")
            .ok()
            .map(|s| s.parse().unwrap());
        macro_rules! go {
            ($client:expr) => {{
                for &(b, f0, k, pip) in &cases {
                    let coord = Coord::with_digits(b, 0, 1, 0).unwrap();
                    let sh = Shape { f0, k };
                    let mut caps = WideCaps::for_base(b);
                    caps.probe = true;
                    if let Some(c) = classes {
                        caps.classes = c.min(b - 1);
                    }
                    if let Ok(x) = std::env::var("MIDOUT_NINST") {
                        caps.ninst = x.parse().unwrap();
                    }
                    if let Ok(x) = std::env::var("MIDOUT_MAXPOP") {
                        caps.maxpop = x.parse().unwrap();
                    }
                    let gj = WideJoin::new($client, caps, &coord, sh).unwrap();
                    println!(
                        "device {} W {} base {b} shape ({f0}, {k}) slice {pip}",
                        ctx.device_name(),
                        gj.w
                    );
                    let t0 = Instant::now();
                    let rank = gj.rank_of(pip).unwrap();
                    let (dc, mut got, tops) = gj.run_slice(pip, &rank).unwrap();
                    let tdev = t0.elapsed().as_secs_f64();
                    let t1 = Instant::now();
                    let (cn, want) = cpu_slice(&coord, sh, u128::from(pip));
                    println!("slice {pip}: device {dc:?} ({tdev:.1} s)");
                    println!(
                        "slice {pip}: cpu    {cn:?} ({:.1} s)",
                        t1.elapsed().as_secs_f64()
                    );
                    assert_eq!(tops.len() as u64, cn.tops, "tops");
                    assert_eq!(gj.wb.tested(pip), cn.tops_tested, "tops tested");
                    got.sort_unstable();
                    let gn: Vec<u128> = got.iter().map(|x| x.0).collect();
                    assert_eq!(gn.len(), want.len(), "survivor count");
                    assert!(gn == want, "survivor sets differ");
                    assert_eq!(
                        (
                            dc.children,
                            dc.chunks,
                            dc.flat,
                            dc.kept,
                            dc.survivors,
                            dc.checked
                        ),
                        (
                            cn.children,
                            cn.chunks,
                            cn.flat,
                            cn.kept,
                            cn.survivors,
                            cn.survivors
                        )
                    );
                    let mut bad = 0;
                    for &(n, u) in &got {
                        if unique_digits(n, b).0 != u {
                            bad += 1;
                        }
                    }
                    assert_eq!(
                        bad, 0,
                        "the check's distinct digits differ on {bad} survivors"
                    );
                    let nice: Vec<u128> = got.iter().filter(|x| x.1 == b).map(|x| x.0).collect();
                    assert_eq!(gj.nice().unwrap(), nice);
                    println!(
                        "slice {pip}: PASS ({} survivors, {} tops, {} nice)",
                        gn.len(),
                        tops.len(),
                        nice.len()
                    );
                }
            }};
        }
        match &ctx {
            crate::cubecl_backend::CubeclContext::Wgpu { client, .. } => go!(client.clone()),
            #[cfg(feature = "cubecl-cuda")]
            crate::cubecl_backend::CubeclContext::Cuda { client, .. } => go!(client.clone()),
            #[allow(unreachable_patterns)]
            _ => panic!("unsupported runtime"),
        }
    }

    /// Whole small bases through the wide device path against brute force:
    /// every slice of the base on the device; the union of the survivors is
    /// exactly the set of n passing the shape's predicate (no n twice), and
    /// the device's check reports exactly the nice numbers (69 at base 10).
    /// The CPU reference's own brute-force cases, here on the device.
    #[test]
    #[ignore = "needs a GPU (MIDOUT_CUDA=1 for the CUDA runtime)"]
    fn wide_whole_small_bases_vs_brute_force() {
        use crate::midout::cpu::q_shape;
        use std::collections::HashSet;
        let ctx = device().expect("a device");
        let classes: Option<u32> = std::env::var("MIDOUT_CLASSES")
            .ok()
            .map(|s| s.parse().unwrap());
        let max_slices: u64 = std::env::var("MIDOUT_MAX_SLICES")
            .ok()
            .map_or(u64::MAX, |s| s.parse().unwrap());
        let cases: &[(u32, &[(u32, u32)])] = &[
            (10, &[(0, 2)]),
            (12, &[(1, 3)]),
            (13, &[(1, 3), (0, 3)]),
            (14, &[(1, 3)]),
            (17, &[(1, 3), (1, 4)]),
            (18, &[(1, 3), (1, 4)]),
            (19, &[(1, 3), (0, 4)]),
            (20, &[(2, 4), (1, 4)]),
            (22, &[(2, 4)]),
            (24, &[(1, 4), (2, 4)]),
            (25, &[(2, 5)]),
        ];
        macro_rules! go {
            ($client:expr) => {{
                for &(b, shapes) in cases {
                    let coord = Coord::with_digits(b, 0, 1, 0).unwrap();
                    let base = Base::new(&coord);
                    let nice_brute: Vec<u128> =
                        (coord.start..coord.end).filter(|&n| unique_digits(n, b).1).collect();
                    for &(f0, k) in shapes {
                        let sh = Shape { f0, k };
                        let mut caps = WideCaps::for_base(b);
                        caps.probe = true;
                        if let Some(c) = classes {
                            caps.classes = c.min(b - 1);
                        }
                        let gj = WideJoin::new($client, caps, &coord, sh).unwrap();
                        let mut got = HashSet::new();
                        let mut surv = 0u64;
                        let npip = u64::from(b).pow(k - 1 - f0);
                        if npip > max_slices {
                            println!("b{b} shape ({f0}, {k}): {npip} slices > MIDOUT_MAX_SLICES, skipped");
                            continue;
                        }
                        for pip in 0..npip {
                            let rank = gj.rank_of(pip).unwrap();
                            let (dc, v, _) = gj.run_slice(pip, &rank).unwrap();
                            assert_eq!(dc.survivors, v.len() as u64);
                            surv += dc.survivors;
                            for (n, u) in v {
                                assert!(got.insert(n), "b{b} {sh:?}: n {n} twice");
                                assert_eq!(unique_digits(n, b).0, u, "b{b}: distinct digits of {n}");
                            }
                        }
                        let want: HashSet<u128> =
                            (coord.start..coord.end).filter(|&n| q_shape::<u128>(&base, sh, n)).collect();
                        assert_eq!(got, want, "b{b} shape {sh:?}: survivors differ from brute force");
                        assert_eq!(surv, want.len() as u64);
                        assert_eq!(gj.nice().unwrap(), nice_brute, "b{b} shape {sh:?}: nice");
                        println!(
                            "b{b} shape ({f0}, {k}): {npip} slices, {} survivors = brute force, nice {:?}: PASS",
                            want.len(),
                            nice_brute
                        );
                    }
                }
            }};
        }
        match &ctx {
            crate::cubecl_backend::CubeclContext::Wgpu { client, .. } => go!(client.clone()),
            #[cfg(feature = "cubecl-cuda")]
            crate::cubecl_backend::CubeclContext::Cuda { client, .. } => go!(client.clone()),
            #[allow(unreachable_patterns)]
            _ => panic!("unsupported runtime"),
        }
    }

    /// A real base-65 slice against the staged prototype (`g2proto dumpsu 65
    /// 4 10 PIP DIR`, an independent implementation): every unit's survivor
    /// set and every unit's top count. `MIDOUT_SU_DIR`.
    #[test]
    #[ignore = "needs a GPU and MIDOUT_SU_DIR (a staged slice)"]
    fn wide_slice_vs_staged() {
        let ctx = device().expect("a device");
        let dir = std::env::var("MIDOUT_SU_DIR").expect("MIDOUT_SU_DIR");
        let meta = std::fs::read_to_string(format!("{dir}/meta.txt")).unwrap();
        let first: Vec<&str> = meta.lines().next().unwrap().split_whitespace().collect();
        let b: u32 = first[1].parse().unwrap();
        let f0: u32 = first[3].parse().unwrap();
        let k: u32 = first[5].parse().unwrap();
        let pip: u64 = first[7].parse().unwrap();
        let mut counts = Vec::new();
        let mut tcounts = Vec::new();
        for line in meta.lines() {
            let f: Vec<&str> = line.split_whitespace().collect();
            if f[0] == "unit" {
                tcounts.push(f[5].parse::<usize>().unwrap());
                counts.push(f[13].parse::<usize>().unwrap());
            }
        }
        let raw = std::fs::read(format!("{dir}/surv.bin")).unwrap();
        let coord = Coord::with_digits(b, 0, 1, 0).unwrap();
        macro_rules! go {
            ($client:expr) => {{
                let mut caps = WideCaps::for_base(b);
                caps.probe = true;
                let gj = WideJoin::new($client, caps, &coord, Shape { f0, k }).unwrap();
                let rank = gj.rank_of(pip).unwrap();
                let (dc, got, tops) = gj.run_slice(pip, &rank).unwrap();
                println!("staged b{b} slice {pip}: device {dc:?}");
                let bu = u128::from(b);
                let unit = |n: u128| ((n / bu.pow(k - 1)) % bu) as usize;
                let mut by: Vec<Vec<u128>> = vec![Vec::new(); b as usize];
                for (n, _) in got {
                    by[unit(n)].push(n);
                }
                let mut tby = vec![0usize; b as usize];
                for (ix, _, _) in &tops {
                    tby[(ix / gj.wb.nlead) as usize] += 1;
                }
                let mut off = 0;
                for (d, &c) in counts.iter().enumerate() {
                    let mut want: Vec<u128> = raw[off..off + 16 * c]
                        .chunks_exact(16)
                        .map(|x| u128::from_le_bytes(x.try_into().unwrap()))
                        .collect();
                    want.sort_unstable();
                    by[d].sort_unstable();
                    assert_eq!(by[d], want, "unit {d}");
                    assert_eq!(tby[d], tcounts[d], "unit {d} tops");
                    off += 16 * c;
                }
                println!(
                    "staged b{b} slice {pip}: PASS, {} units, {} survivors",
                    counts.len(),
                    counts.iter().sum::<usize>()
                );
            }};
        }
        match &ctx {
            crate::cubecl_backend::CubeclContext::Wgpu { client, .. } => go!(client.clone()),
            #[cfg(feature = "cubecl-cuda")]
            crate::cubecl_backend::CubeclContext::Cuda { client, .. } => go!(client.clone()),
            #[allow(unreachable_patterns)]
            _ => panic!("unsupported runtime"),
        }
    }
}
