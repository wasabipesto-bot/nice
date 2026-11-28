//! The device path of the middle-out join with masks wider than 64 bits:
//! bases 65–70, and (for its tests) any base 3–70 and any shape `(f0, k)`
//! whose numbers fit the layouts below. CubeCL, one source for CUDA and
//! Vulkan (SPIR-V).
//!
//! A second path, not a width parameter of [`super::gpu`]: base 64 keeps its
//! 64-bit kernels byte for byte (no tax by construction); what the narrow
//! path gains must be ported here by hand. Ported so far: the
//! accounts, guards and sampled CPU check, the top hierarchy
//! (`wtops5`), the prefilter before the check (in `wexpand_kernel`,
//! mirroring `cpu::prefilter`) and the parents' root pass shared across the
//! slice's top digit (`wanc_kernel`). The main kernel here is the base-64 kernel (`gpu::kernels::g2_kernel`:
//! shuffle transpose, two entries per step,
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
//!   `maxpop > 16`); the main kernel's shared copy of a probe keeps digits
//!   16 and 17 in the four words' spare top bits when `maxpop <= 18`;
//! - **more slice rows**: 65 rows per chunk up to base 64, `(b + 1) | 1`
//!   above (67 at b65, 69 at b68, 71 at b69/b70), a zero row for the pad
//!   digit of an empty top mask; the digits 64..b are transposed by ballots
//!   (at most 6 per chunk segment) and their common masks taken from them;
//! - **the padded coordinate**: the range's ends are clipped per top
//!   (start's and end's low digits), and `h` runs over the leading values;
//! - **classes mod b − 1** and **roots** per base (`m`, `nroot` comptime);
//!   jobs run as `ninst` instances of `PMAX` probes each (the base-64 path's
//!   second instance, generalised: base 68 has 3.5k–6.3k probes per job).
//!
//! The full check is this file's own (`wcheck_kernel`): production's
//! `check_kernel` holds digits in one 64-bit mask and refuses bases above
//! 64. Survivor entries are `(top, r mod b^f0)`; the check rebuilds `n`
//! from the top's `(h, d)`, the slice's digits and the entry.
//!
//! # Data layouts (where they differ from the base-64 path's, see [`super::gpu`])
//!
//! - **Parent record** (`Vector<u32, 4>`): `[mask lo (digits 0–31), mask lo (32–63), cacc, rf | mask hi <<
//!   RF_BITS]`: `rf = r mod b^f0` in the low `RF_BITS` = 25 bits, the mask's digits 64..b above it; `cacc = c2 |
//!   c3 << 8 | a2 << 16 | a3 << 24` (8-bit fields), the child of unit `d` adding digits `(c2 + a2·d) mod b` and
//!   `(c3 + a3·d) mod b` (`child_w`).
//! - **Top digits** (`tdig`, `TDW` = 5 words per top): 7-bit digit fields, 4 per word, padded with the first
//!   digit.
//! - **Job** (two words): `[c, d | poff << 8]`, as on the base-64 path; a job runs as `ninst` instances of
//!   `PMAX` probes, `poff` the instance's first probe.
//! - **Child list**: job `(c, d)` of a batch writes its certified children's `rf` from position `(pseg[c] −
//!   pseg[c0])·b + d·(pseg[c + 1] − pseg[c])`.
//! - **Record** (`Vector<u32, 4>`): `[probe | d << 16 | c << 24, chunk position, word lo, word hi]`: the probe's
//!   index in the job's probe list (16 bits, `poff` included), the unit and the class (8 bits each), the chunk's
//!   first child relative to the job's list start (the expansion adds the start from `c` and `d`), and the
//!   64-pair word as on the base-64 path.
//! - **Survivor entry** (`surv`, two words): `[top index, rf]`; the check (`wcheck_kernel`) rebuilds `n` from
//!   the top's `(h, d)`, the slice's digits and `rf`.
//! - **Counters** (`cnt`, `NCNT` words): units × 5 as on the base-64 path (up to 70 units), then `C_*`.
//! - **Account** (`acc`, `ACC_WORDS` = 16 words per slice): the `A_*` words below; the same stages as the
//!   base-64 path's table, without the separate top-record kernel (`A_TREC`) and with the parents' scan and
//!   sort as `A_HSCAN`, `A_SORT`, so the indices differ from the base-64 path's.
//!
//! # Correspondence with the base-64 path
//!
//! What the narrow path gains must be ported here by hand; this is the map (base-64 item → wide item). The
//! host-tops path has no wide counterpart.
//!
//! | base 64 ([`super::gpu`]) | wide (this module) |
//! |---|---|
//! | `GpuJoin`, `Caps::b64` | `WideJoin`, `WideCaps::for_base` |
//! | `g2_kernel`, `child_mask` | `wide_kernel`, `child_w` |
//! | `tops5`, `tops1`, `tscan`, `tops2`, `tdigz2` | `wtops5`, `wtops1`, `wscan`, `wtops2`, `wtdigz` |
//! | `toprec2` (production's top records) | — (`wcheck_kernel` reads the tops itself) |
//! | `hist2`, `scan16`, `scatter3`, `hsort` | `whist`, `wscan`, `wscatter`, `wsort` |
//! | `anc8_kernel`, `build_anc`, `set_parent_sharing`, `F_SKIP_ANC` (digit 8 of a `(4, 8, 5)` field) | `wanc_kernel`, `build_anc`, `set_parent_sharing`, `F_SKIP_ANC` (digit k − 2) |
//! | `expand_kernel` with `keep_bits2`, `put_bits`, `pf` / `pf24` | `wexpand_kernel` with `wrec_top`, `wtop_ctx`, `put_bits_w`, `pf_w2` (`pf_w`: the earlier form) |
//! | production's `check_kernel` | `wcheck_kernel` |
//! | `done_kernel` | `wdone_kernel` |
//! | `queue_dev_prep`, `queue_batch`, `queue_done`, `queue_dev` | `queue_prep`, `queue_batch`, `queue_done`, `queue_slice` |
//! | `finish_group`, `check_slice`, `A_*`, `C_*` | `finish_group`, `check_slice`, `A_*`, `C_*` (other indices) |
//! | `run_slice_dev` | `run_slice` |
//! | `search_field`, `GpuOptions`, `sample_compare` | `search_field_wide`, `WideOptions`, `wide_sample_compare` |

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
    // kernel code (`#[cube]`) spells these out, so that the generated
    // device code stays the code whose exactness was measured
    clippy::manual_midpoint,
    clippy::manual_range_contains,
    clippy::manual_rotate,
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
/// A job's child-list range past the batch's list (the write is clamped).
const C_ERR_CLST: usize = 366;
/// Slices whose last kernel ran (`wdone_kernel`): the host counts slices from this word.
const C_SLICES: usize = 367;
const NCNT: usize = 368;
/// Per-slice account (`acc`, one buffer per slice; the base-64 path's accounts, wide form): what every stage ran,
/// compared by the host with what it queued (`WideJoin::check_slice`). Every word starts at 0, and no word may
/// stay 0 for a slice whose stage ran. `wtops1`: valid parents examined (= `wtops5`'s `l5n[0]`), tops certified
/// (= `tstat[0]`); `wscan` (tops) ran; `wtops2` tops placed, `wtdigz` rows written (= `tstat[0]`).
const A_T1_EXAM: usize = 0;
const A_T1_CERT: usize = 1;
const A_TSCAN: usize = 2;
const A_T2_PLACED: usize = 3;
const A_TDIG: usize = 4;
/// `whist`: cubes done (= its grid), parents certified counted apart from the list (= `lcnt`); `wscan` (parents)
/// ran; `wscatter`: rows moved (= `lcnt`) and the listed parents' children over all b units (= the main kernel's
/// children); `wsort`: cubes done (= the buckets).
const A_H_CUBES: usize = 5;
const A_H_CERT: usize = 6;
const A_HSCAN: usize = 7;
const A_SCAT: usize = 8;
const A_SC_CHILD: usize = 9;
const A_SORT: usize = 10;
/// Main kernel: job instances that reached their end (= queued), probes run (= nroot × tops: every top is a probe
/// of one job per root, over the job's instances), children seen (= `A_SC_CHILD`).
const A_JOBS: usize = 11;
const A_PROBES: usize = 12;
const A_CHILD: usize = 13;
/// The slice's last kernel ran (1).
const A_DONE: usize = 14;
/// `whist` ran with planes of another width than compiled for, or partly filled.
const A_ERR_PLANE: usize = 15;
const ACC_WORDS: usize = 16;
/// The expansion's own account (`est`): cubes done, slabs walked (once per plane), survivor bits read, bits of a
/// clipped top, survivors appended counted per lane (= the list's count).
const EST_WORDS: usize = 5;
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
/// The wide main kernel (`wide_kernel`) and its helpers (`dbit`: a digit's bit in the two-word mask, `child_w`:
/// a parent's child at unit `d`).
// CubeCL's comptime branches assign a variable declared before them (`let mut x = ..; if comptime!(..) { x = .. }
// else { x = .. }`): rustc sees the declaration's value as never read.
#[allow(unused_assignments)]
mod wk {
    use super::{
        A_CHILD, A_JOBS, A_PROBES, C_ERR_CLASS, C_ERR_CLST, C_ERR_PLANE, C_ERR_PMAX, C_ERR_SLAB,
        C_JOBS, C_LSLOTS, NT, PMAX, RF_BITS, SLAB, TDW,
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

    /// Digit `k` of a probe: 7-bit fields, four per word of `pv` (bits 0-27); with `maxpop` 17-18, digits 16 and
    /// 17 split over the words' bits 28-31 (low four bits in words 0 and 2, high three in words 1 and 3); above
    /// 18, digits 16.. in `pe` (four per word).
    #[cube]
    fn probe_digit(
        pv: Vector<u32, Const<4>>,
        pe: u32,
        #[comptime] k: u32,
        #[comptime] maxpop: u32,
    ) -> u32 {
        let mut dg = 0u32;
        if comptime!(k < 16) {
            dg = (pv[comptime!(k / 4) as usize] >> comptime!(7 * (k % 4))) & 127u32;
        } else if comptime!(maxpop > 18) {
            dg = (pe >> comptime!(7 * (k - 16))) & 127u32;
        } else if comptime!(k == 16) {
            dg = (pv[0usize] >> 28u32) | ((pv[1usize] >> 24u32) & 0x70u32);
        } else {
            dg = (pv[2usize] >> 28u32) | ((pv[3usize] >> 24u32) & 0x70u32);
        }
        dg
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
    pub fn child_w(pm: u64, ph: u32, cacc: u32, d: u32, #[comptime] b: u32) -> (u64, u32) {
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

    /// One cube per job instance (class c, unit d, probes [poff, poff + PMAX)): the base-64 kernel with
    /// two-word masks, `b | 1` slice rows, 7-bit probe digits and classes mod b − 1 (see the module docs).
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
        // fault-injection bits, 0 in production: F_DROP_PROBE (8) each instance's last probe not run
        fault: u32,
        // the slice's account (`A_*`) and the child list's length
        acc: &mut Array<Atomic<u32>>,
        lcap: u32,
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
        // a probe's digits 0-15 in `prob_d`; up to two more (maxpop 17-18) in the words' spare top nibbles
        // (`probe_digit`); a fifth word per probe (`prob_e`) only above 18, which keeps base 65's shared memory
        // under the 21,504 bytes a 64-lane RDNA SIMD needs for 12 waves of this kernel
        let mut prob_d = SharedMemory::<Vector<u32, Const<4>>>::new(comptime!(PMAX as usize));
        let mut prob_e =
            SharedMemory::<u32>::new(comptime!((if maxpop > 18 { PMAX } else { 32 }) as usize));
        let mut wcnt = SharedMemory::<u32>::new(comptime!(
            (if 2 * NT / w < 32 { 32 } else { 2 * NT / w }) as usize
        ));
        // 32 words each though only [0] is used: every shared array a multiple of 128 bytes keeps every offset
        // aligned in CubeCL's CUDA layout, whose order changes from process to process (one word each made the
        // kernel ~16 % slower on an RTX 3080 in some processes)
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
        // s_nl[1]: the instance's survivor bits, counted by each lane apart from the ballots that place its
        // records. Cleared in a block of its own: the SPIR-V compiler's expression merge keeps only the first of
        // two atomic stores of one value in a block (CubeCL 0.10), which left it uncleared beside s_nl[0]
        if t == 1u32 {
            s_nl[1usize].store(0u32);
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
            // the pending parent index (`idx - pb`) is 16 bits: a class of up to 65,536 parents
            if pe - pb > 65536u32 && poff == 0u32 {
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
                        if comptime!(maxpop > 16) {
                            let e = tdig[((b0 + j) * TDW + 4u32) as usize];
                            if comptime!(maxpop > 18) {
                                prob_e[(base + j - poff) as usize] = e;
                            } else {
                                // digits 16 and 17 (bits 0-13 of the fifth word) into the four words' bits 28-31
                                pv[0usize] |= (e & 15u32) << 28u32;
                                pv[1usize] |= ((e >> 4u32) & 7u32) << 28u32;
                                pv[2usize] |= ((e >> 7u32) & 15u32) << 28u32;
                                pv[3usize] |= ((e >> 11u32) & 7u32) << 28u32;
                            }
                        }
                        prob_d[(base + j - poff) as usize] = pv;
                    }
                    j += NT;
                }
                base += b1 - b0;
            }
        }
        sync_cube();
        let mut nprobe = min(s_np[0usize] - min(s_np[0usize], poff), PMAX);
        if (fault & 8u32) != 0u32 && nprobe > 0u32 {
            nprobe -= 1u32;
        }

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
        // here, not at the end, so that none of these stays live through the rounds: the
        // probes this instance runs (the host's law: nroot x tops over all instances) and the job's child list
        // [lb, lb + (pe - pb)) inside the batch's
        if t == 0u32 {
            acc[A_PROBES].fetch_add(nprobe);
            if lb + (pe - pb) > lcap {
                cnt[C_ERR_CLST].fetch_add(1u32);
            }
        }
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
                    // bounded (the job's whole range is checked once, `C_ERR_CLST`)
                    clst[min(lb + cdone + sl16, lcap - 1u32) as usize] = r4v;
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
                    if comptime!(maxpop > 18) {
                        pe5 = prob_e[pp as usize];
                    }
                    #[unroll]
                    for k in 0..maxpop {
                        let dg = probe_digit(pv, pe5, k, maxpop);
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
                // phase 3b: four chunks per lane (q = t % 4, chunks q, q + 4, q + 8, q + 12), 64 probe streams
                // (st = t / 4), one list entry per unit per step: a lane reads its probe's digits once for its four
                // chunks (their rows are constant offsets apart); 64 entries x 16 chunks per cube step
                let q = t % 4u32;
                let st = t / 4u32;
                let mut vlo = Array::<u32>::new(4usize);
                let mut vhi = Array::<u32>::new(4usize);
                #[unroll]
                for h in 0..4u32 {
                    let qh = q + comptime!(4 * h);
                    let nq = select(qh < nch, min(64u32, ntake - min(ntake, qh * 64u32)), 0u32);
                    vlo[h as usize] = select(nq >= 32u32, 0xFFFF_FFFFu32, (1u32 << (nq % 32u32)) - 1u32);
                    vhi[h as usize] = select(
                        nq == 64u32,
                        0xFFFF_FFFFu32,
                        select(nq > 32u32, (1u32 << (nq % 32u32)) - 1u32, 0u32),
                    );
                }
                let qr = q * srow;
                let qs = 16u32 + q;
                let cpos0 = cdone + q * 64u32;
                let mut e0 = 0u32;
                while e0 < nlist {
                    let mut wlo = Array::<u32>::new(4usize);
                    let mut whi = Array::<u32>::new(4usize);
                    // e < nlist + 63 <= PMAX + 63 < pq's size (PMAX + 64)
                    let e = e0 + st;
                    let ent = select(e < nlist, pq[e as usize], 0u32);
                    let p16 = ent & 0xFFFFu32;
                    let dws = prob_d[(p16 >> 4u32) as usize];
                    let mut de = 0u32;
                    if comptime!(maxpop > 18) {
                        de = prob_e[(p16 >> 4u32) as usize];
                    }
                    let mut alo = Array::<u32>::new(4usize);
                    let mut ahi = Array::<u32>::new(4usize);
                    let mut rows = Array::<u32>::new(comptime!(maxpop as usize));
                    #[unroll]
                    for k in 0..maxpop {
                        rows[k as usize] = (probe_digit(dws, de, k, maxpop) + qr) * 2u32;
                    }
                    // a chunk the entry does not keep (or past nch) gives a zero word whatever its rows hold: the
                    // reads of chunks 1-3 are skipped for it (lanes masked off; the whole branch when no lane of the
                    // plane keeps it); chunk 0 reads always, so that the row addresses are formed once, outside
                    #[unroll]
                    for h in 0..4u32 {
                        let mut xl = 0u32;
                        let mut xh = 0u32;
                        if comptime!(h == 0) || (((ent >> (qs + comptime!(4 * h))) & 1u32) != 0u32 && vlo[h as usize] != 0u32) {
                            #[unroll]
                            for k in 0..maxpop {
                                xl |= sl[(rows[k as usize] + comptime!(8 * srow * h)) as usize];
                                xh |= sl[(rows[k as usize] + comptime!(8 * srow * h + 1)) as usize];
                            }
                        }
                        alo[h as usize] = xl;
                        ahi[h as usize] = xh;
                    }
                    let mut nsl = Array::<u32>::new(4usize);
                    let mut rk = Array::<u32>::new(4usize);
                    let mut nn = 0u32;
                    #[unroll]
                    for h in 0..4u32 {
                        let kmask = 0u32 - ((ent >> (qs + comptime!(4 * h))) & 1u32);
                        wlo[h as usize] = !alo[h as usize] & vlo[h as usize] & kmask;
                        whi[h as usize] = !ahi[h as usize] & vhi[h as usize] & kmask;
                        let nz = (wlo[h as usize] | whi[h as usize]) != 0u32;
                        nsl[h as usize] = nn;
                        rk[h as usize] = plane_rank_m(nz, rlo, rhi, w);
                        nn += plane_count(nz, w);
                    }
                    if t == 0u32 {
                        my_lslots += min(64u32, nlist - e0) * nch;
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
                            slab_id = plane_sum(sid);
                            slab_used = 0u32;
                            have_slab = true;
                            if slab_id >= nslab_cap && lane == 0u32 {
                                cnt[C_ERR_SLAB].fetch_add(1u32);
                            }
                        }
                        let sbase = slab_id * SLAB + slab_used;
                        // F_SLAB_SPLIT (1048576): the records of lanes other than lane 0 are lost (written empty),
                        // as when lanes split from lane 0's after a branch append apart from it
                        let lost = (fault & 1048576u32) != 0u32 && lane != 0u32;
                        if slab_id < nslab_cap {
                            #[unroll]
                            for h in 0..4u32 {
                                if (wlo[h as usize] | whi[h as usize]) != 0u32 {
                                    let mut rv = Vector::<u32, Const<4>>::empty();
                                    rv[0usize] = ((p16 >> 4u32) + poff) | (d << 16u32) | (c << 24u32);
                                    rv[1usize] = cpos0 + comptime!(256 * h);
                                    rv[2usize] = select(lost, 0u32, wlo[h as usize]);
                                    rv[3usize] = select(lost, 0u32, whi[h as usize]);
                                    out[(sbase + nsl[h as usize] + rk[h as usize]) as usize] = rv;
                                }
                            }
                        }
                        #[unroll]
                        for h in 0..4u32 {
                            my_surv += wlo[h as usize].count_ones() + whi[h as usize].count_ones();
                        }
                        slab_used += nn;
                    }
                    e0 += 64u32;
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
        if lane == 0u32 && sk > 0u32 {
            cnt[(d * 5u32 + 3u32) as usize].fetch_add(sk);
        }
        if my_surv > 0u32 {
            s_nl[1usize].fetch_add(my_surv);
        }
        sync_cube();
        if t == 0u32 {
            let ss = s_nl[1usize].load();
            if ss > 0u32 {
                cnt[(d * 5u32 + 4u32) as usize].fetch_add(ss);
            }
        }
        if t == 0u32 && poff == 0u32 {
            cnt[(d * 5u32) as usize].fetch_add(my_children);
            cnt[(d * 5u32 + 1u32) as usize].fetch_add(my_chunks);
            acc[A_CHILD].fetch_add(my_children);
        }
        if t == 0u32 {
            cnt[(d * 5u32 + 2u32) as usize].fetch_add(my_flat);
            cnt[C_LSLOTS].fetch_add(my_lslots);
            cnt[C_JOBS].fetch_add(1u32);
            // positive evidence: this instance reached its end
            acc[A_JOBS].fetch_add(1u32);
        }
    }
}

/// Preparation, tops, expansion and check for wide masks: everything is
/// generic in (b, f0, k) and works on base-b digits and base-b² limbs.
// CubeCL's comptime branches assign a variable declared before them (`let mut x = ..; if comptime!(..) { x = .. }
// else { x = .. }`): rustc sees the declaration's value as never read.
#[allow(unused_assignments)]
mod wp {
    use super::wk::{child_w, dbit};
    use super::{
        A_DONE, A_ERR_PLANE, A_H_CERT, A_H_CUBES, A_SC_CHILD, A_SCAT, A_SORT, A_T1_CERT, A_T1_EXAM,
        A_T2_PLACED, A_TDIG, C_SLICES, NT, RF_BITS, SLAB, TDW,
    };
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
        let (lo, hi, _ml, _mh, bad) = cert_split_w(x, y, lo_in, hi_in, 0u64, 0u32, b, s, k, k);
        (lo, hi, bad)
    }

    /// [`cert_w`], and the part of the certificate at positions >= `kmid` (the prefilter's `mhi`, added to
    /// `mlo_in`, `mhi_in`): (lo, hi, mhi lo, mhi hi, repeated).
    #[cube]
    fn cert_split_w(
        x: &Array<u32>,
        y: &Array<u32>,
        lo_in: u64,
        hi_in: u32,
        mlo_in: u64,
        mhi_in: u32,
        #[comptime] b: u32,
        #[comptime] s: u32,
        #[comptime] k: u32,
        #[comptime] kmid: u32,
    ) -> (u64, u32, u64, u32, bool) {
        let mut lo = lo_in;
        let mut hi = hi_in;
        let mut mlo = mlo_in;
        let mut mhi = mhi_in;
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
                    if comptime!(s - 1 - tt >= kmid) {
                        mlo |= bl;
                        mhi |= bh;
                    }
                }
            }
        }
        (lo, hi, mlo, mhi, bad)
    }

    /// The middle-digit prefilter (`cpu::prefilter` in wide form) of n whose digits
    /// `[0, k + 2)` are `rd`: the digits at positions k and k + 1 of n² and n³ are distinct, miss the digits
    /// `[0, k)` of n² and n³, and miss the top's certified digits at positions >= k + 2 (`mlo`, `mhi`). Every
    /// digit of r², r³ mod b^(k+2) is computed and tested (the bottom's 2k are distinct for a survivor). `small`:
    /// n < b^ceil((k+2)/2) (n² may have no digit at k + 1: no prefilter, small bases only).
    #[cube]
    pub fn pf_w(
        rd: &Array<u32>,
        mlo: u64,
        mhi: u32,
        small: bool,
        #[comptime] b: u32,
        #[comptime] k: u32,
    ) -> bool {
        let kk = comptime!(k + 2);
        let mut sq = Array::<u32>::new(comptime!(kk as usize));
        let mut cu = Array::<u32>::new(comptime!(kk as usize));
        let mut carry = 0u32;
        #[unroll]
        for j in 0..kk {
            let mut s = carry;
            #[unroll]
            for i in 0..kk {
                if comptime!(i <= j) {
                    s += rd[i as usize] * rd[comptime!(j - i) as usize];
                }
            }
            carry = s / b;
            sq[j as usize] = s - carry * b;
        }
        carry = 0u32;
        #[unroll]
        for j in 0..kk {
            let mut s = carry;
            #[unroll]
            for i in 0..kk {
                if comptime!(i <= j) {
                    s += rd[i as usize] * sq[comptime!(j - i) as usize];
                }
            }
            carry = s / b;
            cu[j as usize] = s - carry * b;
        }
        let mut lo = 0u64;
        let mut hi = 0u32;
        let mut ok = true;
        #[unroll]
        for j in 0..kk {
            let (a, ah) = dbit(sq[j as usize]);
            let (c, ch) = dbit(cu[j as usize]);
            if (lo & a) != 0u64 || (hi & ah) != 0u32 {
                ok = false;
            }
            lo |= a;
            hi |= ah;
            if (lo & c) != 0u64 || (hi & ch) != 0u32 {
                ok = false;
            }
            lo |= c;
            hi |= ch;
            if comptime!(j >= k) {
                if ((a | c) & mlo) != 0u64 || ((ah | ch) & mhi) != 0u32 {
                    ok = false;
                }
            }
        }
        ok || small
    }

    /// `pf_w` in base b² ("super-digits": two digits each, so a column sum of products of super-digits
    /// stays below 2^32 for b <= 70 and k + 2 <= 2 * 178): r = r_f + F·b^f0 with F's super-digits fixed per record
    /// (`sf`, from `pf_w2_fixed`) and r_f's from one division by b² per pair of its digits; r² and r³ mod b^(2·ns)
    /// in ns = ceil((k + 2) / 2) super-digit columns (ns(ns+1)/2 products each, against (k+2)(k+3)/2 per digit in
    /// `pf_w`), then each super-digit split once into its two digits. The test on the digits 0..k+1 is `pf_w`'s
    /// (all distinct, those >= k outside the top's mask, `small` passes): the same predicate, so `checked` is
    /// unchanged. `small` here is the record's part (h < hsmall, slice digits); r_f's part (its digits >= ceil((k +
    /// 2) / 2) zero) is r_f < b^ceil((k + 2) / 2), tested here.
    #[cube]
    pub fn pf_w2(
        sf: &Array<u32>,
        rf: u32,
        mlo: u64,
        mhi: u32,
        small_rec: bool,
        #[comptime] b: u32,
        #[comptime] f0: u32,
        #[comptime] k: u32,
    ) -> bool {
        let kk = comptime!(k + 2);
        let ns = comptime!((k + 3) / 2);
        let bb = comptime!(b * b);
        let tsm = comptime!((k + 3) / 2);
        let mut rz = true;
        if comptime!(tsm < f0) {
            rz = rf < comptime!(b.pow(tsm));
        }
        let mut sd = Array::<u32>::new(comptime!(ns as usize));
        let mut y = rf;
        #[unroll]
        for i in 0..ns {
            if comptime!(2 * i + 1 < f0) {
                let q = y / bb;
                sd[i as usize] = y - q * bb;
                y = q;
            } else if comptime!(2 * i + 1 == f0) {
                // the super-digit across f0: r_f's top digit and the record's digit f0
                sd[i as usize] = y + b * sf[i as usize];
            } else {
                sd[i as usize] = sf[i as usize];
            }
        }
        let mut sq = Array::<u32>::new(comptime!(ns as usize));
        let mut cu = Array::<u32>::new(comptime!(ns as usize));
        let mut carry = 0u32;
        #[unroll]
        for j in 0..ns {
            let mut t = carry;
            #[unroll]
            for i in 0..ns {
                if comptime!(i <= j) {
                    t += sd[i as usize] * sd[comptime!(j - i) as usize];
                }
            }
            carry = t / bb;
            sq[j as usize] = t - carry * bb;
        }
        carry = 0u32;
        #[unroll]
        for j in 0..ns {
            let mut t = carry;
            #[unroll]
            for i in 0..ns {
                if comptime!(i <= j) {
                    t += sd[i as usize] * sq[comptime!(j - i) as usize];
                }
            }
            carry = t / bb;
            cu[j as usize] = t - carry * bb;
        }
        // every digit's bit into one mask (all 2(k + 2) digits distinct iff it has that many bits), the four at
        // positions k and k + 1 also into a second, which must miss the top's
        let mut lo = 0u64;
        let mut hi = 0u32;
        let mut tlo = 0u64;
        let mut thi = 0u32;
        #[unroll]
        for j in 0..ns {
            let s1 = sq[j as usize] / b;
            let c1 = cu[j as usize] / b;
            let (a0, ah0) = dbit(sq[j as usize] - s1 * b);
            let (c0, ch0) = dbit(cu[j as usize] - c1 * b);
            // digit 2j of r², r³
            lo |= a0 | c0;
            hi |= ah0 | ch0;
            if comptime!(2 * j >= k) {
                tlo |= a0 | c0;
                thi |= ah0 | ch0;
            }
            // digit 2j + 1, if below k + 2
            if comptime!(2 * j + 1 < kk) {
                let (a1, ah1) = dbit(s1);
                let (c1b, ch1) = dbit(c1);
                lo |= a1 | c1b;
                hi |= ah1 | ch1;
                if comptime!(2 * j + 1 >= k) {
                    tlo |= a1 | c1b;
                    thi |= ah1 | ch1;
                }
            }
        }
        let ok = lo.count_ones() + hi.count_ones() == comptime!(2 * kk)
            && (tlo & mlo) == 0u64
            && (thi & mhi) == 0u32;
        ok || (small_rec && rz)
    }

    /// A record's fixed super-digits for `pf_w2` from its digits `rd[f0..k+2)` (`rd` of k + 2 digits):
    /// sf[i] = rd[2i] + b·rd[2i + 1] for 2i >= f0 (rd[k + 2] = 0), rd[f0] for the super-digit across f0 (f0 odd).
    #[cube]
    pub fn pf_w2_fixed(
        rd: &Array<u32>,
        sf: &mut Array<u32>,
        #[comptime] b: u32,
        #[comptime] f0: u32,
        #[comptime] k: u32,
    ) {
        let kk = comptime!(k + 2);
        let ns = comptime!((k + 3) / 2);
        #[unroll]
        for i in 0..ns {
            if comptime!(2 * i + 1 == f0) {
                sf[i as usize] = rd[f0 as usize];
            } else if comptime!(2 * i >= f0) {
                if comptime!(2 * i + 1 < kk) {
                    sf[i as usize] =
                        rd[comptime!(2 * i) as usize] + b * rd[comptime!(2 * i + 1) as usize];
                } else {
                    sf[i as usize] = rd[comptime!(2 * i) as usize];
                }
            } else {
                sf[i as usize] = 0u32;
            }
        }
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
        // F_DROP_PARENT (8192): parents of r_f = 0 mod 997 left out of the list after `parent_w`;
        // F_BAD_PARENT (16384): `parent_w` returns 0 for them (a wrong parent, which only the sampled check sees)
        fault: u32,
        acc: &mut Array<Atomic<u32>>,
        #[comptime] w: u32,
        #[comptime] b: u32,
        #[comptime] f0: u32,
        #[comptime] k: u32,
    ) {
        // the cube's certified parents, counted by each lane apart from the ballot and the list (account
        // `A_H_CERT`): a lane left out of the plane's ballot (a plane split after a branch) still counts
        let shc = SharedMemory::<Atomic<u32>>::new(1usize);
        if UNIT_POS_X == 0u32 {
            shc[0usize].store(0u32);
        }
        if PLANE_DIM != w || UNIT_POS_X % w != UNIT_POS_PLANE {
            acc[A_ERR_PLANE].fetch_add(1u32);
        }
        sync_cube();
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
            let bad = (fault & 16384u32) != 0u32 && rf % 997u32 == 0u32;
            lo = select(bad, 0u64, a);
            hi = select(bad, 0u32, ah);
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
        let cert = lo != 0u64 || hi != 0u32;
        let flag = cert && !((fault & 8192u32) != 0u32 && rf % 997u32 == 0u32);
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
        if cert {
            shc[0usize].fetch_add(1u32);
        }
        sync_cube();
        if UNIT_POS_X == 0u32 {
            acc[A_H_CERT].fetch_add(shc[0usize].load());
            acc[A_H_CUBES].fetch_add(1u32);
        }
    }

    /// The parents' shared pass across the slice's top digit (the base-64 path's `anc8_kernel`, wide form): the
    /// roots r_f whose depth-(k − 2) ancestor r = r_f + key·b^f0 (key = the slice's digits [f0, k − 2), `pipd8`,
    /// the same for the b slices that differ only in digit k − 2) has 2(k − 2) distinct digits 0..k − 3 of r² and
    /// r³ (`parent_w` one digit shallower), appended to `out` (one atomic per plane; order arbitrary). Those
    /// digits depend only on r mod b^(k−2), so every root whose parent passes `parent_w` for some top digit is
    /// listed: `whist` over this list instead of every root is exact, for each slice of the key. Account `acc8`:
    /// [cubes done, roots examined, roots certified (counted by each lane, apart from the ballot that gives the
    /// list's own count `cnt[0]`), plane errors].
    #[cube(launch_unchecked)]
    pub fn wanc_kernel(
        rfs: &Array<u32>,
        pipd8: &Array<u32>,
        out: &mut Array<u32>,
        cnt: &mut Array<Atomic<u32>>,
        nroots: u32,
        cap: u32,
        // F_ANC_DROP (65536): roots r_f = 0 mod 997 taken as uncertified (a wrong list, its counts consistent:
        // only the sampled check sees it); F_ANC_SPLIT (131072): certified roots outside lane 0 leave the plane's
        // ballot (as lanes split from lane 0's after a branch would): their entries are lost
        fault: u32,
        acc8: &mut Array<Atomic<u32>>,
        #[comptime] w: u32,
        #[comptime] b: u32,
        #[comptime] f0: u32,
        #[comptime] k: u32,
    ) {
        let sh = SharedMemory::<Atomic<u32>>::new(2usize);
        if UNIT_POS_X < 2u32 {
            sh[UNIT_POS_X as usize].store(0u32);
        }
        if PLANE_DIM != w || UNIT_POS_X % w != UNIT_POS_PLANE {
            acc8[3usize].fetch_add(1u32);
        }
        sync_cube();
        let i = ABSOLUTE_POS_X;
        let live = i < nroots;
        let mut ok = false;
        let mut rf = 0u32;
        if live {
            rf = rfs[i as usize];
            let (lo, hi, _cacc) = parent_w(rf, pipd8, b, f0, comptime!(k - 1));
            ok = (lo != 0u64 || hi != 0u32) && !((fault & 65536u32) != 0u32 && rf % 997u32 == 0u32);
        }
        let split = (fault & 131072u32) != 0u32 && ok && UNIT_POS_PLANE != 0u32;
        let bl = plane_ballot(ok && !split);
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
            base0 = cnt[0usize].fetch_add(n);
        }
        let base = plane_sum(base0);
        if ok && !split {
            let slot = base + r;
            if slot < cap {
                out[slot as usize] = rf;
            }
        }
        if ok {
            sh[1usize].fetch_add(1u32);
        }
        let ex = plane_sum(select(live, 1u32, 0u32));
        if UNIT_POS_PLANE == 0u32 {
            sh[0usize].fetch_add(ex);
        }
        sync_cube();
        if UNIT_POS_X == 0u32 {
            acc8[0usize].fetch_add(1u32);
            acc8[1usize].fetch_add(sh[0usize].load());
            acc8[2usize].fetch_add(sh[1usize].load());
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
        acc: &mut Array<Atomic<u32>>,
        #[comptime] b: u32,
    ) {
        // rows moved and the listed parents' children (b unit digits each), per cube
        let sh = SharedMemory::<Atomic<u32>>::new(2usize);
        if UNIT_POS_X < 2u32 {
            sh[UNIT_POS_X as usize].store(0u32);
        }
        sync_cube();
        let i = ABSOLUTE_POS_X;
        let live = i < min(lcnt[0usize], cap);
        let mut nch = 0u32;
        if live {
            let key = lkey[i as usize];
            let slot = cur[key as usize].fetch_add(1u32);
            let v = lst[i as usize];
            tmp[(4u32 * slot) as usize] = v[0usize];
            tmp[(4u32 * slot + 1u32) as usize] = v[1usize];
            tmp[(4u32 * slot + 2u32) as usize] = v[2usize];
            tmp[(4u32 * slot + 3u32) as usize] = v[3usize];
            let pm = u64::cast_from(v[0usize]) | (u64::cast_from(v[1usize]) << 32u64);
            let ph = v[3usize] >> comptime!(RF_BITS);
            for dd in 0..b {
                let (cl, chh) = child_w(pm, ph, v[2usize], dd, b);
                nch += select(cl != 0u64 || chh != 0u32, 1u32, 0u32);
            }
        }
        let prows = plane_sum(select(live, 1u32, 0u32));
        let pch = plane_sum(nch);
        if UNIT_POS_PLANE == 0u32 {
            sh[0usize].fetch_add(prows);
            sh[1usize].fetch_add(pch);
        }
        sync_cube();
        if UNIT_POS_X == 0u32 {
            acc[A_SCAT].fetch_add(sh[0usize].load());
            acc[A_SC_CHILD].fetch_add(sh[1usize].load());
        }
    }

    /// The slice's last kernel: its done word and the group's slice count.
    #[cube(launch_unchecked)]
    pub fn wdone_kernel(acc: &mut Array<Atomic<u32>>, cnt: &mut Array<Atomic<u32>>) {
        if ABSOLUTE_POS_X == 0u32 {
            acc[A_DONE].fetch_add(1u32);
            cnt[C_SLICES].fetch_add(1u32);
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
        acc: &mut Array<Atomic<u32>>,
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
        if t == 0u32 {
            acc[A_SORT].fetch_add(1u32);
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
        // the slice's account and the word this scan adds 1 to (`A_TSCAN` or `A_HSCAN`)
        acc: &mut Array<Atomic<u32>>,
        aw: u32,
        #[comptime] n: u32,
        #[comptime] every: u32,
        #[comptime] seg: bool,
    ) {
        let per = comptime!((n + 1023) / 1024);
        let mut sums = SharedMemory::<u32>::new(1024usize);
        let t = UNIT_POS_X;
        if t == 0u32 {
            acc[aw as usize].fetch_add(1u32);
        }
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

    /// The top hierarchy (the base-64 path's `tops5`, wide form): once per b consecutive slices (one value of the slice's
    /// digits [f0 + 1, k − 1)), thread i = d·nlead + (h − hlo) certifies the parent prefix p5 = (h·b + d)·b^(k−2−f0)
    /// + pip div b over its b^(f0+1) n (clipped to the range) and lists i if valid. A slice's prefix i is tested
    /// only under a valid parent i: a sub-interval's certificate holds its parent's digits, so a parent with a
    /// repeated digit has no valid child (exact by containment). `l5n`: [0] parents listed (the ballot's count),
    /// [1] cubes done, [2] valid parents counted by each lane apart from the ballot (= [0]).
    #[cube(launch_unchecked)]
    pub fn wtops5_kernel(
        list: &mut Array<u32>,
        l5n: &mut Array<Atomic<u32>>,
        pipd: &Array<u32>,
        ends: &Array<u32>,
        ntest: u32,
        nlead: u32,
        hlo: u32,
        plo_lo: u32,
        plo_hi: u32,
        phi_lo: u32,
        phi_hi: u32,
        // F_T5_SPLIT (262144): valid parents outside lane 0 leave the plane's ballot (as lanes split from lane 0's
        // after a branch would): their entries are lost
        fault: u32,
        #[comptime] w: u32,
        #[comptime] b: u32,
        #[comptime] f0: u32,
        #[comptime] k: u32,
        #[comptime] l: u32,
        #[comptime] s2: u32,
        #[comptime] s3: u32,
    ) {
        let bb = comptime!(b * b);
        let na = comptime!((l + 1) / 2);
        let sh = SharedMemory::<Atomic<u32>>::new(1usize);
        if UNIT_POS_X == 0u32 {
            sh[0usize].store(0u32);
        }
        sync_cube();
        let i = ABSOLUTE_POS_X;
        let mut ok = false;
        if i < ntest {
            let d = i / nlead;
            let h = hlo + i % nlead;
            let bw = comptime!(b as u64);
            let mut p = u64::cast_from(h * b + d);
            #[unroll]
            for j in 0..comptime!(k - 2 - f0) {
                p = p * bw + u64::cast_from(pipd[comptime!(k - 2 - f0 - j) as usize]);
            }
            // the range's parent prefixes: start div b^(f0+1) .. (end - 1) div b^(f0+1)
            let plo = u64::cast_from(plo_lo) | (u64::cast_from(plo_hi) << 32u64);
            let phi = u64::cast_from(phi_lo) | (u64::cast_from(phi_hi) << 32u64);
            if p >= plo && p <= phi {
                let mut ad = Array::<u32>::new(comptime!(l as usize));
                let mut cd = Array::<u32>::new(comptime!(l as usize));
                #[unroll]
                for j in 0..comptime!(f0 + 1) {
                    ad[j as usize] = select(p == plo, ends[j as usize], 0u32);
                    cd[j as usize] =
                        select(p == phi, ends[comptime!(l + j) as usize], comptime!(b - 1));
                }
                #[unroll]
                for j in 0..comptime!(k - 2 - f0) {
                    let v = pipd[comptime!(j + 1) as usize];
                    ad[comptime!(f0 + 1 + j) as usize] = v;
                    cd[comptime!(f0 + 1 + j) as usize] = v;
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
                let (_l2, _h2, bad2) = cert_w(&a3, &c3, l1, h1, b, s3, k);
                ok = !bad1 && !bad2;
            }
        }
        let split = (fault & 262144u32) != 0u32 && ok && UNIT_POS_PLANE != 0u32;
        let bl = plane_ballot(ok && !split);
        let lane = UNIT_POS_PLANE;
        let lm = select(
            lane >= 32u32,
            0xFFFF_FFFFu32,
            (1u32 << min(lane, 31u32)) - 1u32,
        );
        let mut r = (bl[0usize] & lm).count_ones();
        let mut n = bl[0usize].count_ones();
        if comptime!(w > 32) {
            let hm = select(lane >= 32u32, (1u32 << (lane & 31u32)) - 1u32, 0u32);
            r += (bl[1usize] & hm).count_ones();
            n += bl[1usize].count_ones();
        }
        let mut base0 = 0u32;
        if lane == 0u32 && n > 0u32 {
            base0 = l5n[0usize].fetch_add(n);
        }
        let base = plane_sum(base0);
        if ok && !split {
            list[(base + r) as usize] = i;
        }
        if ok {
            sh[0usize].fetch_add(1u32);
        }
        sync_cube();
        if UNIT_POS_X == 0u32 {
            l5n[1usize].fetch_add(1u32);
            l5n[2usize].fetch_add(sh[0usize].load());
        }
    }

    /// Tops: entry i = d·nlead + (h − hlo) of the valid parents' list (`wtops5`) tests the prefix p = (h·b +
    /// d)·b^(k−1−f0) + pip (if in the range's prefixes [plo, phi]; the range's ends clip the first and last);
    /// certificate of n² and n³ at positions ≥ k; a count per segment d·m + h mod m; each certified top appended to
    /// the compact list `tc` (two words per top: [i, mask lo (2 words), mask hi], [mhi lo (2 words), mhi hi,
    /// segment]; one atomic per plane on `tstat[2]`, order arbitrary; past `cap` not written, the scan's total then
    /// exceeds the cap and the host fails the slice). Grid-stride over the list, one round for a whole cube at a
    /// time (the ballot's lanes all active).
    #[cube(launch_unchecked)]
    pub fn wtops1_kernel(
        tc: &mut Array<Vector<u32, Const<4>>>,
        segc: &mut Array<Atomic<u32>>,
        tstat: &mut Array<Atomic<u32>>,
        pipd: &Array<u32>,
        ends: &Array<u32>,
        acc: &mut Array<Atomic<u32>>,
        // the valid parents' prefix indices (`wtops5`) and their count (`l5n[0]`): grid-stride over them
        list: &Array<u32>,
        l5n: &Array<u32>,
        ntest: u32,
        nlead: u32,
        hlo: u32,
        plo_lo: u32,
        plo_hi: u32,
        phi_lo: u32,
        phi_hi: u32,
        cap: u32,
        #[comptime] w: u32,
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
        let nl = min(l5n[0usize], ntest);
        let stride = CUBE_COUNT_X * NT;
        // the cube's first entry of the round (uniform in the cube)
        let mut j0 = CUBE_POS_X * NT;
        let mut exam = 0u32;
        let mut cert = 0u32;
        let lane = UNIT_POS_PLANE;
        let lm = select(
            lane >= 32u32,
            0xFFFF_FFFFu32,
            (1u32 << min(lane, 31u32)) - 1u32,
        );
        while j0 < nl {
            let jj = j0 + UNIT_POS_X;
            j0 += stride;
            let mut ok = false;
            let mut i = 0u32;
            let mut lo = 0u64;
            let mut hi = 0u32;
            let mut mq = 0u64;
            let mut mqh = 0u32;
            let mut seg = 0u32;
            if jj < nl {
                i = list[jj as usize];
                exam += 1u32;
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
                    let (l1, h1, q1, qh1, bad1) =
                        cert_split_w(&a2, &c2, 0u64, 0u32, 0u64, 0u32, b, s2, k, comptime!(k + 2));
                    let (l2, h2, q2, qh2, bad2) =
                        cert_split_w(&a3, &c3, l1, h1, q1, qh1, b, s3, k, comptime!(k + 2));
                    ok = !bad1 && !bad2;
                    lo = l2;
                    hi = h2;
                    mq = q2;
                    mqh = qh2;
                }
                seg = d * m + h % m;
                if ok {
                    cert += 1u32;
                    segc[seg as usize].fetch_add(1u32);
                    if lo.count_ones() + hi.count_ones() > maxpop {
                        tstat[1usize].fetch_add(1u32);
                    }
                }
            }
            let bl = plane_ballot(ok);
            let mut r = (bl[0usize] & lm).count_ones();
            let mut n = bl[0usize].count_ones();
            if comptime!(w > 32) {
                let hm = select(lane >= 32u32, (1u32 << (lane & 31u32)) - 1u32, 0u32);
                r += (bl[1usize] & hm).count_ones();
                n += bl[1usize].count_ones();
            }
            let mut base0 = 0u32;
            if lane == 0u32 && n > 0u32 {
                base0 = tstat[2usize].fetch_add(n);
            }
            let base = plane_sum(base0);
            if ok {
                let slot = base + r;
                if slot < cap {
                    let mut v0 = Vector::<u32, Const<4>>::empty();
                    v0[0usize] = i;
                    v0[1usize] = u32::cast_from(lo & 0xFFFF_FFFFu64);
                    v0[2usize] = u32::cast_from(lo >> 32u64);
                    v0[3usize] = hi;
                    let mut v1 = Vector::<u32, Const<4>>::empty();
                    v1[0usize] = u32::cast_from(mq & 0xFFFF_FFFFu64);
                    v1[1usize] = u32::cast_from(mq >> 32u64);
                    v1[2usize] = mqh;
                    v1[3usize] = seg;
                    tc[(2u32 * slot) as usize] = v0;
                    tc[(2u32 * slot + 1u32) as usize] = v1;
                }
            }
        }
        // valid parents examined, tops certified (plane sums, lane 0 adds)
        let ex = plane_sum(exam);
        let ce = plane_sum(cert);
        if UNIT_POS_PLANE == 0u32 {
            acc[A_T1_EXAM].fetch_add(ex);
            acc[A_T1_CERT].fetch_add(ce);
        }
    }

    /// Each listed top (`wtops1`'s compact list, `min(tstat[2], cap)` of them) into its segment: its record as
    /// listed (two words) to the segment's next slot of `tps` (one 32-byte write per top; `wtdigz` unpacks it).
    #[cube(launch_unchecked)]
    pub fn wtops2_kernel(
        tc: &Array<Vector<u32, Const<4>>>,
        tstat: &Array<u32>,
        cur: &mut Array<Atomic<u32>>,
        tps: &mut Array<Vector<u32, Const<4>>>,
        acc: &mut Array<Atomic<u32>>,
        cap: u32,
    ) {
        let nl = min(tstat[2usize], cap);
        let mut jj = ABSOLUTE_POS_X;
        let mut placed = 0u32;
        while jj < nl {
            let v0 = tc[(2u32 * jj) as usize];
            let v1 = tc[(2u32 * jj + 1u32) as usize];
            jj += CUBE_COUNT_X * NT;
            placed += 1u32;
            let slot = cur[v1[3usize] as usize].fetch_add(1u32);
            if slot < cap {
                tps[(2u32 * slot) as usize] = v0;
                tps[(2u32 * slot + 1u32) as usize] = v1;
            }
        }
        let pp = plane_sum(placed);
        if UNIT_POS_PLANE == 0u32 {
            acc[A_T2_PLACED].fetch_add(pp);
        }
    }

    /// The placed tops (`tps`, in slot order) into their arrays: masks (lo, hi), the prefix index, the
    /// prefilter's digits, and the digit table (7-bit fields, 4 per word, padded with the first digit); and the
    /// zeroing of the histogram and the list count for the slice's preparation.
    #[cube(launch_unchecked)]
    pub fn wtdigz_kernel(
        tps: &Array<Vector<u32, Const<4>>>,
        tmask: &mut Array<u64>,
        tmh: &mut Array<u32>,
        thd: &mut Array<u32>,
        ttq: &mut Array<u64>,
        ttqh: &mut Array<u32>,
        tdig: &mut Array<u32>,
        hist: &mut Array<u32>,
        lcnt: &mut Array<u32>,
        tstat: &Array<u32>,
        acc: &mut Array<Atomic<u32>>,
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
        let row = i < min(tstat[0usize], cap);
        let rows = plane_sum(select(row, 1u32, 0u32));
        if UNIT_POS_PLANE == 0u32 {
            acc[A_TDIG].fetch_add(rows);
        }
        if row {
            let v0 = tps[(2u32 * i) as usize];
            let v1 = tps[(2u32 * i + 1u32) as usize];
            let mut x = u64::cast_from(v0[1usize]) | (u64::cast_from(v0[2usize]) << 32u64);
            let mut y = v0[3usize];
            tmask[i as usize] = x;
            tmh[i as usize] = y;
            thd[i as usize] = v0[0usize];
            ttq[i as usize] = u64::cast_from(v1[0usize]) | (u64::cast_from(v1[1usize]) << 32u64);
            ttqh[i as usize] = v1[2usize];
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

    /// A record's top index and its chunk's first position in the batch's child list (an all-zero record past a
    /// slab's count: any in-range index; its words are zero, so nothing is read through them). The probe slot is
    /// counted through the job's compatible top classes (ct with ct + c + unit a root), in root order.
    #[cube]
    fn wrec_top(
        rec: Vector<u32, Const<4>>,
        pseg: &Array<u32>,
        tseg: &Array<u32>,
        roots: &Array<u32>,
        c0: u32,
        #[comptime] b: u32,
        #[comptime] nroot: u32,
    ) -> (u32, u32) {
        let m = comptime!(b - 1);
        let ps = rec[0usize] & 0xFFFFu32;
        let du = (rec[0usize] >> 16u32) & 255u32;
        let c = rec[0usize] >> 24u32;
        let cc = (c + du) % m;
        let mut rem = ps;
        let mut found = false;
        let mut ti = 0u32;
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
        (
            ti,
            (pb - pseg[c0 as usize]) * b + du * (pe - pb) + rec[1usize],
        )
    }

    /// A top's (h, unit), the bounds of r_f inside the range (`[lo, hi]`: all of it unless the range's first or
    /// last prefix, which `clip` names, cuts the top) and the small-n flag (1: n < b^ceil((k+2)/2) is possible).
    #[cube]
    fn wtop_ctx(
        ti: u32,
        thd: &Array<u32>,
        nlead: u32,
        hlo: u32,
        hsmall: u32,
        clip: &Array<u32>,
        pipv: u64,
        hzs: u32,
        #[comptime] b: u32,
        #[comptime] f0: u32,
        #[comptime] k: u32,
    ) -> (u32, u32, u32, u32, u32) {
        let ix = thd[ti as usize];
        let du = ix / nlead;
        let h = hlo + ix % nlead;
        let bp = comptime!((b as u64).pow(k - 1 - f0));
        let pp = u64::cast_from(h * b + du) * bp + pipv;
        let plo = u64::cast_from(clip[0usize]) | (u64::cast_from(clip[1usize]) << 32u64);
        let phi = u64::cast_from(clip[2usize]) | (u64::cast_from(clip[3usize]) << 32u64);
        let lo = select(pp == plo, clip[4usize], 0u32);
        let hi = select(pp == phi, clip[5usize], u32::MAX);
        let tsm = comptime!((k + 3) / 2);
        let hz = select(
            h < hsmall && hzs != 0u32 && du * select(comptime!(k > tsm), 1u32, 0u32) == 0u32,
            1u32,
            0u32,
        );
        (h, du, lo, hi, hz)
    }

    /// Writes the kept bits' entries `(ti, r_f)` from `slot` on; returns the next slot.
    #[cube]
    fn put_bits_w(
        ti: u32,
        pos: u32,
        klo: u32,
        khi: u32,
        lst: &Array<u32>,
        surv: &mut Array<u32>,
        slot0: u32,
        scap: u32,
    ) -> u32 {
        let mut slot = slot0;
        let mut x = klo;
        let mut y = khi;
        while (x | y) != 0u32 {
            let inlo = x != 0u32;
            let bt = select(inlo, x.trailing_zeros(), y.trailing_zeros());
            let off = select(inlo, bt, 32u32 + bt);
            if inlo {
                x &= x - 1u32;
            } else {
                y &= y - 1u32;
            }
            if slot < scap {
                surv[(2u32 * slot) as usize] = ti;
                surv[(2u32 * slot + 1u32) as usize] = lst[(pos + off) as usize];
            }
            slot += 1u32;
        }
        slot
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
        // the expansion's account: cubes done, slabs walked, survivor bits read, bits of a clipped top outside the
        // range (not survivors; never listed), survivors appended counted by each lane apart from the plane scan
        // that gives the list's own count `scount` (= it)
        est: &mut Array<Atomic<u32>>,
        // the prefilter: the tops' thread indices and certified digits >= k + 2, the slice's digits, the range's
        // clip (as the check's), the small-n bound (n < b^ceil((k+2)/2) iff h < hsmall and the slice's digits
        // >= ceil((k+2)/2) are zero), the fault bits (F_NOPF 1: no prefilter; F_PF_DROP 1024: the prefilter
        // wrongly drops n whose r_f has bits 10-19 zero, as on the base-64 path; F_EXP_SPLIT 524288: lanes other
        // than lane 0 with survivors in slabs s = 0 mod 7 leave the plane's scan, as lanes split from lane 0's
        // after a branch would: their entries are lost)
        thd: &Array<u32>,
        ttq: &Array<u64>,
        ttqh: &Array<u32>,
        pipd: &Array<u32>,
        clip: &Array<u32>,
        nlead: u32,
        hlo: u32,
        hsmall: u32,
        fault: u32,
        nslab_cap: u32,
        scap: u32,
        c0: u32,
        #[comptime] b: u32,
        #[comptime] nroot: u32,
        #[comptime] f0: u32,
        #[comptime] k: u32,
        // the prefilter in base b² (`pf_w2`); false: digit by digit (`pf_w`)
        #[comptime] pf2: bool,
    ) {
        let nopf = (fault & 1u32) != 0u32;
        let pfdrop = (fault & 1024u32) != 0u32;
        let fsplit = (fault & 524288u32) != 0u32;
        let shp = SharedMemory::<Atomic<u32>>::new(1usize);
        if UNIT_POS_X == 0u32 {
            shp[0usize].store(0u32);
        }
        sync_cube();
        let mut nput = 0u32;
        let bw = comptime!(b as u64);
        // n < b^ceil((k+2)/2) needs every slice digit at positions >= ceil((k+2)/2) zero
        let tsm = comptime!((k + 3) / 2);
        let mut pipz = true;
        #[unroll]
        for j in 0..comptime!(k - 1 - f0) {
            if comptime!(f0 + j >= tsm) {
                if pipd[j as usize] != 0u32 {
                    pipz = false;
                }
            }
        }
        let mut nread = 0u32;
        let mut nclip = 0u32;
        if ABSOLUTE_POS_X == 0u32 {
            stat[0usize] = lcnt[0usize];
            stat[1usize] = slabn[0usize];
        }
        // the slice's digits f0..k-1, once per thread
        let mut pd = Array::<u32>::new(comptime!((k - 1 - f0) as usize));
        let mut pipv = 0u64;
        #[unroll]
        for j in 0..comptime!(k - 1 - f0) {
            pd[j as usize] = pipd[j as usize];
            pipv = pipv * bw + u64::cast_from(pipd[comptime!(k - 2 - f0 - j) as usize]);
        }
        let hzs = select(pipz, 1u32, 0u32);
        // one plane per slab at a time, its lanes over the slab's rows; two records per lane and take, their loads
        // issued together, and one loop over both records' bits (a plane runs as many rounds as its lane with the
        // most bits: max(a + b), not max(a lo) + max(a hi) + ...)
        let ns = min(slabn[0usize], nslab_cap);
        let ppc = NT / PLANE_DIM;
        let pstride = CUBE_COUNT_X * ppc;
        let mut s = CUBE_POS_X * ppc + UNIT_POS_X / PLANE_DIM;
        let mut walked = 0u32;
        while s < ns {
            walked += 1u32;
            let cnt = slabcnt[s as usize];
            let mut r0 = 0u32;
            while r0 < cnt {
                let ra = r0 + UNIT_POS_PLANE;
                let rb = ra + PLANE_DIM;
                let mut reca = Vector::<u32, Const<4>>::empty();
                let mut recb = Vector::<u32, Const<4>>::empty();
                #[unroll]
                for kk in 0..4u32 {
                    reca[kk as usize] = 0u32;
                    recb[kk as usize] = 0u32;
                }
                if ra < cnt {
                    reca = out[(s * SLAB + ra) as usize];
                }
                if rb < cnt {
                    recb = out[(s * SLAB + rb) as usize];
                }
                nread += reca[2usize].count_ones()
                    + reca[3usize].count_ones()
                    + recb[2usize].count_ones()
                    + recb[3usize].count_ones();
                // each record's top (its probe slot among the job's compatible classes) and child-list position
                let (tia, posa) = wrec_top(reca, pseg, tseg, roots, c0, b, nroot);
                let (tib, posb) = wrec_top(recb, pseg, tseg, roots, c0, b, nroot);
                // each top's (h, unit), certified digits >= k + 2, range clip bounds and small-n flag
                let (ha, dua, lla, hla, hza) =
                    wtop_ctx(tia, thd, nlead, hlo, hsmall, clip, pipv, hzs, b, f0, k);
                let (hb, dub, llb, hlb, hzb) =
                    wtop_ctx(tib, thd, nlead, hlo, hsmall, clip, pipv, hzs, b, f0, k);
                let mqa = ttq[tia as usize];
                let mqb = ttq[tib as usize];
                let mha = ttqh[tia as usize];
                let mhb = ttqh[tib as usize];
                let mut w0 = reca[2usize];
                let mut w1 = reca[3usize];
                let mut w2 = recb[2usize];
                let mut w3 = recb[3usize];
                let mut k0 = 0u32;
                let mut k1 = 0u32;
                let mut k2 = 0u32;
                let mut k3 = 0u32;
                let mut rd = Array::<u32>::new(comptime!((k + 2) as usize));
                let mut sf = Array::<u32>::new(comptime!(((k + 3) / 2) as usize));
                #[unroll]
                for j in 0..comptime!(k - 1 - f0) {
                    rd[comptime!(f0 + j) as usize] = pd[j as usize];
                }
                while (w0 | w1 | w2 | w3) != 0u32 {
                    // the lowest set bit of the first nonzero word, in the order a lo, a hi, b lo, b hi
                    let ina = (w0 | w1) != 0u32;
                    let x = select(ina, w0, w2);
                    let y = select(ina, w1, w3);
                    let inlo = x != 0u32;
                    let wd = select(inlo, x, y);
                    let bt = wd.trailing_zeros();
                    let off = select(inlo, bt, 32u32 + bt);
                    let cl = wd & (wd - 1u32);
                    w0 = select(ina && inlo, cl, w0);
                    w1 = select(ina && !inlo, cl, w1);
                    w2 = select(!ina && inlo, cl, w2);
                    w3 = select(!ina && !inlo, cl, w3);
                    let rf = lst[(select(ina, posa, posb) + off) as usize];
                    if rf < select(ina, lla, llb) || rf > select(ina, hla, hlb) {
                        // outside a clipped top's part of the range: not a survivor, never listed
                        nclip += 1u32;
                    } else {
                        let h = select(ina, ha, hb);
                        let du = select(ina, dua, dub);
                        let mq = select(ina, mqa, mqb);
                        let mqh = select(ina, mha, mhb);
                        let hz = select(ina, hza, hzb) != 0u32;
                        rd[comptime!(k - 1) as usize] = du;
                        let h0 = h % b;
                        rd[comptime!(k) as usize] = h0;
                        rd[comptime!(k + 1) as usize] = ((h - h0) / b) % b;
                        let mut pfok = false;
                        if comptime!(pf2) {
                            pf_w2_fixed(&rd, &mut sf, b, f0, k);
                            pfok = pf_w2(&sf, rf, mq, mqh, hz, b, f0, k);
                        } else {
                            let mut yy = rf;
                            let mut rz = true;
                            #[unroll]
                            for j in 0..f0 {
                                let q = yy / b;
                                rd[j as usize] = yy - q * b;
                                if comptime!(j >= tsm) {
                                    if yy - q * b != 0u32 {
                                        rz = false;
                                    }
                                }
                                yy = q;
                            }
                            pfok = pf_w(&rd, mq, mqh, hz && rz, b, k);
                        }
                        if nopf || (pfok && !(pfdrop && (rf >> 10u32).trailing_zeros() >= 10u32)) {
                            let bit = 1u32 << bt;
                            k0 |= select(ina && inlo, bit, 0u32);
                            k1 |= select(ina && !inlo, bit, 0u32);
                            k2 |= select(!ina && inlo, bit, 0u32);
                            k3 |= select(!ina && !inlo, bit, 0u32);
                        }
                    }
                }
                let nb = k0.count_ones() + k1.count_ones() + k2.count_ones() + k3.count_ones();
                nput += nb;
                let split = fsplit && nb > 0u32 && UNIT_POS_PLANE != 0u32 && s % 7u32 == 0u32;
                let nbs = select(split, 0u32, nb);
                let excl = plane_exclusive_sum(nbs);
                let tot = plane_sum(nbs);
                let mut bs = 0u32;
                if UNIT_POS_PLANE == 0u32 && tot > 0u32 {
                    bs = scount[0usize].fetch_add(tot);
                }
                let slot = plane_sum(bs) + excl;
                if !split {
                    let sb = put_bits_w(tia, posa, k0, k1, lst, surv, slot, scap);
                    put_bits_w(tib, posb, k2, k3, lst, surv, sb, scap);
                }
                r0 += 2u32 * PLANE_DIM;
            }
            s += pstride;
        }
        if UNIT_POS_PLANE == 0u32 && walked > 0u32 {
            est[1usize].fetch_add(walked);
        }
        let pr = plane_sum(nread);
        let pc = plane_sum(nclip);
        if UNIT_POS_PLANE == 0u32 {
            est[2usize].fetch_add(pr);
            est[3usize].fetch_add(pc);
        }
        if nput > 0u32 {
            shp[0usize].fetch_add(nput);
        }
        sync_cube();
        if UNIT_POS_X == 0u32 {
            est[0usize].fetch_add(1u32);
            est[4usize].fetch_add(shp[0usize].load());
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
    /// The top hierarchy's parent prefixes n div b^(f0+1): [plo5, phi5].
    pub plo5: u64,
    pub phi5: u64,
    /// The low f0 + 1 digits of start, then of end − 1 (then zeros to l each).
    pub ends: Vec<u32>,
}

impl WideBase {
    /// # Errors
    /// A base or shape outside what the layouts hold.
    pub fn new(coord: &Coord, sh: Shape) -> Result<Self> {
        let b = coord.b();
        let (f0, k) = (sh.f0, sh.k);
        ensure!(
            (3..=MAXB).contains(&b),
            "middle-out wide: base {b} outside 3-{MAXB}"
        );
        let (start, end) = (coord.start(), coord.end());
        let l = ndigits(end - 1, b);
        ensure!(
            k >= 2 && f0 + 1 < k && k <= l,
            "middle-out wide: shape (f0 {f0}, k {k}) for {l}-digit n (the top hierarchy needs a slice digit)"
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
        for j in 0..=f0 {
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
            plo5: (start / (bf * bu)) as u64,
            phi5: (e1 / (bf * bu)) as u64,
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
            // base 68: 89M prefixes and ~143M survivors per slice; 3.5k-6.3k probes per job
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
    /// Per top: the prefilter's `mhi` (lo, hi).
    ttq: Handle,
    ttqh: Handle,
    tstat: Handle,
    /// The slice's account (`A_*`).
    acc: Handle,
    /// Its top-hierarchy group's `l5n` (parents listed, cubes done).
    l5n: Option<Handle>,
    /// The roots `whist` examined: every root, or a shared list's length.
    hn: u32,
}

/// What the host knows of a slice when its first launch batch is finished (the base-64 path's `SliceHead`).
struct WHead {
    pip: u64,
    acc: Handle,
    l5n: Option<Handle>,
    /// The roots `whist` examined (its grid's cubes are the account's).
    hn: u32,
    /// Every launch batch of the slice was queued (the probe and children laws apply).
    full: bool,
}

struct WTicket {
    /// Job instances the batch launched.
    jobs: u32,
    ran: Handle,
    scount: Handle,
    stat: Handle,
    /// The expansion's account (cubes done, slabs walked).
    est: Handle,
    tstat: Option<Handle>,
    /// On a slice's first ticket: its account.
    head: Option<WHead>,
}

/// Fault-injection bits, 0 in production; the base-64 path's numbers where the fault is the same.
/// The main kernel not launched.
#[allow(dead_code)] // the tests only
pub(crate) const F_SKIP_MAIN: u32 = 2;
/// No prefilter: every survivor listed and checked (the tests' whole survivor sets).
#[allow(dead_code)] // the tests only
pub(crate) const F_NOPF: u32 = 1;
/// The prefilter wrongly drops survivors whose r_f has bits 10-19 zero (only the sampled check sees it).
#[allow(dead_code)] // the tests only
pub(crate) const F_PF_DROP: u32 = 1024;
/// Each main-kernel instance's last probe not run.
#[allow(dead_code)] // the tests only
pub(crate) const F_DROP_PROBE: u32 = 8;
/// `wtops1` not launched.
#[allow(dead_code)] // the tests only
pub(crate) const F_SKIP_TOPS: u32 = 4096;
/// 1 parent in 997 left out of the list after it was certified.
#[allow(dead_code)] // the tests only
pub(crate) const F_DROP_PARENT: u32 = 8192;
/// 1 parent in 997 computed wrongly (no mask): conservation holds, only the sampled CPU check sees it.
#[allow(dead_code)] // the tests only
pub(crate) const F_BAD_PARENT: u32 = 16384;
/// The shared pass across the slice's top digit (`wanc_kernel`) not launched.
#[allow(dead_code)] // the tests only
pub(crate) const F_SKIP_ANC: u32 = 32768;
/// `wanc` lists a wrong set: roots r_f = 0 mod 997 left out as if uncertified, every count of the list consistent
/// (only the sampled check's field-run comparison sees it).
#[allow(dead_code)] // the tests only
pub(crate) const F_ANC_DROP: u32 = 65536;
/// `wanc`: certified roots outside lane 0 leave the plane's ballot, as lanes split from lane 0's after a branch
/// would (their entries lost, the ballot's counts consistent).
#[allow(dead_code)] // the tests only
pub(crate) const F_ANC_SPLIT: u32 = 131_072;
/// `wtops5`: the same for valid parents.
#[allow(dead_code)] // the tests only
pub(crate) const F_T5_SPLIT: u32 = 262_144;
/// `wexpand`: the same for lanes other than lane 0 with survivors in slabs s = 0 mod 7 (left out of the plane's
/// scan).
#[allow(dead_code)] // the tests only
pub(crate) const F_EXP_SPLIT: u32 = 524_288;
/// The main kernel: the records of lanes other than lane 0 lost (written empty), as when lanes split from lane
/// 0's after a branch append apart from it (the slab's count consistent).
#[allow(dead_code)] // the tests only
pub(crate) const F_SLAB_SPLIT: u32 = 1_048_576;

/// The parents' shared lists of a field: one per value of the slices' digits [f0, k − 2) (`keys`), the roots
/// whose depth-(k − 2) ancestor is valid (`wanc_kernel`), with their lengths (read once per field).
#[derive(Default)]
struct WAnc {
    keys: Vec<u64>,
    lens: Vec<u32>,
    lists: Vec<Handle>,
    /// The last build: lists and roots listed (tests, benches).
    last: (usize, u64),
    /// Slices that took a shared list, and of them those whose list is shorter than the roots (tests).
    used: (u64, u64),
}

/// Most shared lists held at once (one per value of digit f0 of a `(4, 8, 5)` field: b of them).
const ANC_LISTS: usize = MAXB as usize;

/// The wide device path for one base and shape: kernels compiled for one
/// plane width, buffers allocated once. One field at a time: the tops lists,
/// the top hierarchy's list and the shared parent lists are the join's own.
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
    /// The certified tops of a slice, compact (`wtops1`; two `Vector<u32, 4>` per top, `caps.tops` of them).
    tc: Handle,
    /// The same records placed in segment order (`wtops2`), unpacked by `wtdigz`.
    tps: Handle,
    /// The top hierarchy's list of valid parent prefixes (shared by b consecutive slices), and which slice group
    /// (pip div b) it holds with that group's `l5n` (count, cubes done).
    t5list: Handle,
    t5state: std::sync::Mutex<Option<(u64, Handle)>>,
    /// Timing only ([`WideJoin::set_timing_stop`]): 1 tops, 2 parents, 3 main kernel, 5 expansion, 6 all.
    /// The library never reads `MIDOUT_STOP`; [`search_field_wide`] refuses a stop.
    pub(crate) stop: u32,
    /// fault-injection bits; 0 in production (only the tests set them).
    pub(crate) fault: u32,
    /// The expansion's prefilter in base b² (`pf_w2`; on unless [`WideJoin::set_prefilter_b2`]).
    pf2: bool,
    /// Share the parents' root pass across the slice's top digit inside a field ([`WideJoin::set_parent_sharing`],
    /// on).
    share: bool,
    anc: std::sync::Mutex<WAnc>,
    /// A shared list's capacity in roots (a longer list is an error of the field).
    anc_cap: u32,
}

impl<R: Runtime> WideJoin<R> {
    /// # Errors
    /// A plane width or base the kernels do not take.
    pub fn new(client: ComputeClient<R>, caps: WideCaps, coord: &Coord, sh: Shape) -> Result<Self> {
        Self::with_width(client, caps, coord, sh, None)
    }

    /// [`WideJoin::new`] with the kernels compiled for plane width `force_w` instead of the device's (tests only:
    /// to dump another width's SPIR-V; the results are then invalid).
    pub(crate) fn with_width(
        client: ComputeClient<R>,
        caps: WideCaps,
        coord: &Coord,
        sh: Shape,
        force_w: Option<u32>,
    ) -> Result<Self> {
        let w = force_w.unwrap_or(client.properties().hardware.plane_size_max);
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
            tc: e(nt * 32),
            tps: e(nt * 32),
            t5list: e(ntest * 4),
            t5state: std::sync::Mutex::new(None),
            stop: 6,
            fault: 0,
            pf2: true,
            share: true,
            anc: std::sync::Mutex::new(WAnc::default()),
            // ~21 % of the roots at base 65 (24 % at 70); small bases' tests hold every root
            anc_cap: if nrf <= 1 << 20 {
                nrf.max(1)
            } else {
                nrf / 8 * 3 + 4096
            },
            caps,
            wb,
            client,
        })
    }

    fn upto(&self, k: u32) -> bool {
        self.stop >= k
    }

    /// The expansion's prefilter in base b² (`pf_w2`, the default) or digit by digit (`pf_w`, the earlier form,
    /// kept for A/B timing). The same predicate either way.
    pub fn set_prefilter_b2(&mut self, on: bool) {
        self.pf2 = on;
    }

    /// Share the parents' root pass across the slice's top digit (k − 2) inside a field: when a field's slices take
    /// at most [`ANC_LISTS`] values of their digits [f0, k − 2), each of them several times (a `(4, 8, 5)` field: b
    /// values of digit 4, b slices each), the roots whose depth-(k − 2) ancestor is valid are listed once per value
    /// (`wanc_kernel`, at the field's start, one synchronisation) and each slice's `whist` runs over its list
    /// instead of every root. Exact by containment (see `wanc_kernel`). On by default.
    pub fn set_parent_sharing(&mut self, on: bool) {
        self.share = on;
    }

    /// The last build of shared lists: (lists, roots listed in all).
    pub fn parent_sharing_last(&self) -> (usize, u64) {
        self.anc.lock().expect("anc").last
    }

    /// The key of a slice's shared list: its digits [f0, k − 2) (pip mod b^(k−2−f0)).
    fn anc_key(&self, pip: u64) -> u64 {
        pip % u64::from(self.wb.b).pow(self.wb.k - 2 - self.wb.f0)
    }

    /// Build the shared lists for `keys`, synchronise, and check their accounts.
    fn build_anc(&self, keys: &[u64]) -> Result<()> {
        ensure!(
            keys.len() <= ANC_LISTS,
            "middle-out wide: {} shared parent lists",
            keys.len()
        );
        let wb = &self.wb;
        let nd8 = (wb.k - 2 - wb.f0) as usize;
        let mut st = self.anc.lock().expect("anc");
        st.keys.clear();
        st.lens.clear();
        while st.lists.len() < keys.len() {
            let h = self.client.empty(self.anc_cap as usize * 4);
            st.lists.push(h);
        }
        let nroots = self.nrf;
        let grid = nroots.div_ceil(NT).max(1);
        let mut hs = Vec::new();
        for (j, &key) in keys.iter().enumerate() {
            let cnt = self.mk(vec![0u32]);
            let acc8 = self.mk(vec![0u32; 4]);
            let mut x = key;
            let mut d8: Vec<u32> = (0..nd8)
                .map(|_| {
                    let v = (x % u64::from(wb.b)) as u32;
                    x /= u64::from(wb.b);
                    v
                })
                .collect();
            if d8.is_empty() {
                d8.push(0);
            }
            let pd8 = self.mk(d8);
            if self.fault & F_SKIP_ANC == 0 {
                unsafe {
                    wp::wanc_kernel::launch_unchecked::<R>(
                        &self.client,
                        CubeCount::Static(grid, 1, 1),
                        CubeDim::new_1d(NT),
                        ArrayArg::from_raw_parts(self.rfh.clone(), nroots.max(1) as usize),
                        ArrayArg::from_raw_parts(pd8.clone(), nd8.max(1)),
                        ArrayArg::from_raw_parts(st.lists[j].clone(), self.anc_cap as usize),
                        ArrayArg::from_raw_parts(cnt.clone(), 1),
                        nroots,
                        self.anc_cap,
                        self.fault,
                        ArrayArg::from_raw_parts(acc8.clone(), 4),
                        self.w,
                        wb.b,
                        wb.f0,
                        wb.k,
                    );
                }
            }
            hs.push(cnt);
            hs.push(acc8);
        }
        self.sync()?;
        let nh = hs.len();
        let mut rv = cubecl::future::block_on(self.client.read_async(hs))
            .map_err(|e| anyhow!("read: {e:?}"))?
            .into_iter()
            .map(|b| u32::from_bytes(&b).to_vec());
        let mut lens = Vec::new();
        for &key in keys {
            let (Some(c), Some(a)) = (rv.next(), rv.next()) else {
                bail!("middle-out wide: {nh} buffers read, fewer returned");
            };
            let n = c[0];
            ensure!(
                a[3] == 0,
                "middle-out wide: wanc (key {key}): plane errors {}",
                a[3]
            );
            ensure!(
                a[0] == grid,
                "middle-out wide: wanc (key {key}): cubes done: {}, want {grid} (account {a:?})",
                a[0]
            );
            ensure!(
                a[1] == nroots,
                "middle-out wide: wanc (key {key}): roots examined: {}, want {nroots}",
                a[1]
            );
            ensure!(
                a[2] == n,
                "middle-out wide: wanc (key {key}): roots certified {} = listed {n}",
                a[2]
            );
            ensure!(
                n <= self.anc_cap,
                "middle-out wide: wanc (key {key}): {n} roots listed (capacity {})",
                self.anc_cap
            );
            lens.push(n);
        }
        st.last = (keys.len(), lens.iter().map(|&x| u64::from(x)).sum());
        st.keys = keys.to_vec();
        st.lens = lens;
        Ok(())
    }

    /// The shared list for a slice, if one is built: (handle, length).
    fn anc_for(&self, pip: u64) -> Option<(Handle, u32)> {
        let k = self.anc_key(pip);
        let mut st = self.anc.lock().expect("anc");
        let r = st
            .keys
            .iter()
            .position(|&x| x == k)
            .map(|j| (st.lists[j].clone(), st.lens[j]));
        if let Some((_, n)) = &r {
            st.used.0 += 1;
            st.used.1 += u64::from(*n < self.nrf);
        }
        r
    }

    /// Timing and bisection only (benches, feature `midout-bench`): run the stages up to `stop` (1 tops, 2
    /// parents, 3 main kernel, 5 expansion, 6 all). A join with a stop below 6 only times stages:
    /// [`search_field_wide`] refuses it, `time_field_wide` takes it.
    #[cfg(any(test, feature = "midout-bench"))]
    pub fn set_timing_stop(&mut self, stop: u32) {
        self.stop = stop;
    }

    /// A timing stop is set (benches, feature `midout-bench`).
    #[cfg(feature = "midout-bench")]
    pub fn stop_set(&self) -> bool {
        self.stop != 6
    }

    /// Set the fault bits (and forget the top hierarchy's list, so that the next slice makes it under them).
    #[allow(dead_code)] // the tests only
    pub(crate) fn set_fault(&mut self, f: u32) {
        self.fault = f;
        *self.t5state.lock().expect("t5state") = None;
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

    /// Queue a slice's tops and parents; with `shared`, `whist` over the slice's shared list when one is built.
    fn queue_prep(&self, pip: u64, rankh: &Handle, shared: bool) -> WSlice {
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
        let tstat = self.mk(vec![0u32; 3]);
        let acc = self.mk(vec![0u32; ACC_WORDS]);
        let tsegh = self.client.empty(nseg * 2 * 4);
        let tmh = self.client.empty(nt * 8);
        let tmhh = self.client.empty(nt * 4);
        let thdh = self.client.empty(nt * 4);
        let ttq = self.client.empty(nt * 8);
        let ttqh = self.client.empty(nt * 4);
        let cur = self.client.empty(nseg * 4);
        let dummy = self.client.empty(4);
        let ntest = wb.ntest();
        let (b, f0, k, l) = (wb.b, wb.f0, wb.k, wb.l);
        let grp = pip / u64::from(b);
        let mut l5n = None;
        let src = if shared { self.anc_for(pip) } else { None };
        let hn = src.as_ref().map_or(self.nrf, |x| x.1);
        unsafe {
            if self.upto(1) {
                let mut st = self.t5state.lock().expect("t5state");
                if st.as_ref().map(|x| x.0) != Some(grp) {
                    let h = self.mk(vec![0u32; 3]);
                    wp::wtops5_kernel::launch_unchecked::<R>(
                        c,
                        CubeCount::Static(ntest.div_ceil(NT), 1, 1),
                        CubeDim::new_1d(NT),
                        a(&self.t5list, ntest as usize),
                        a(&h, 3),
                        a(&pipd, npd),
                        a(&self.ends_h, 2 * l as usize),
                        ntest,
                        wb.nlead,
                        wb.hlo,
                        wb.plo5 as u32,
                        (wb.plo5 >> 32) as u32,
                        wb.phi5 as u32,
                        (wb.phi5 >> 32) as u32,
                        self.fault,
                        self.w,
                        b,
                        f0,
                        k,
                        l,
                        wb.s2,
                        wb.s3,
                    );
                    *st = Some((grp, h));
                }
                l5n = st.as_ref().map(|x| x.1.clone());
                let l5h = l5n.clone().expect("l5n");
                drop(st);
                let tgrid = ntest.div_ceil(NT * 4).max(1);
                if self.fault & F_SKIP_TOPS == 0 {
                    wp::wtops1_kernel::launch_unchecked::<R>(
                        c,
                        CubeCount::Static(tgrid, 1, 1),
                        CubeDim::new_1d(NT),
                        a(&self.tc, 2 * nt),
                        a(&segc, nseg),
                        a(&tstat, 3),
                        a(&pipd, npd),
                        a(&self.ends_h, 2 * l as usize),
                        a(&acc, ACC_WORDS),
                        a(&self.t5list, ntest as usize),
                        a(&l5h, 3),
                        ntest,
                        wb.nlead,
                        wb.hlo,
                        wb.plo as u32,
                        (wb.plo >> 32) as u32,
                        wb.phi as u32,
                        (wb.phi >> 32) as u32,
                        nt as u32,
                        self.w,
                        b,
                        f0,
                        k,
                        l,
                        wb.s2,
                        wb.s3,
                        self.caps.maxpop,
                    );
                }
                wp::wscan_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static(1, 1, 1),
                    CubeDim::new_1d(1024),
                    a(&segc, nseg),
                    a(&tsegh, 2 * nseg),
                    a(&cur, nseg),
                    a(&dummy, 1),
                    a(&tstat, 3),
                    a(&acc, ACC_WORDS),
                    A_TSCAN as u32,
                    self.nseg,
                    1u32,
                    true,
                );
                wp::wtops2_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static(tgrid, 1, 1),
                    CubeDim::new_1d(NT),
                    a(&self.tc, 2 * nt),
                    a(&tstat, 3),
                    a(&cur, nseg),
                    a(&self.tps, 2 * nt),
                    a(&acc, ACC_WORDS),
                    nt as u32,
                );
                wp::wtdigz_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static((nt as u32).max(self.nbk).div_ceil(NT), 1, 1),
                    CubeDim::new_1d(NT),
                    a(&self.tps, 2 * nt),
                    a(&tmh, nt),
                    a(&tmhh, nt),
                    a(&thdh, nt),
                    a(&ttq, nt),
                    a(&ttqh, nt),
                    a(&self.g_tdig, nt * TDW as usize),
                    a(&self.histh, self.nbk as usize),
                    a(&self.lcnt, 1),
                    a(&tstat, 3),
                    a(&acc, ACC_WORDS),
                    self.nbk,
                    nt as u32,
                    b,
                );
            }
            if self.upto(2) {
                let nbk = self.nbk as usize;
                let (rh, nr) = src.clone().unwrap_or_else(|| (self.rfh.clone(), self.nrf));
                wp::whist_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static(nr.div_ceil(NT).max(1), 1, 1),
                    CubeDim::new_1d(NT),
                    a(&rh, nr as usize),
                    a(&pipd, npd),
                    a(rankh, 8),
                    a(&self.histh, nbk),
                    a(&self.g_lst, np),
                    a(&self.g_lkey, np),
                    a(&self.lcnt, 1),
                    nr,
                    (pip % u64::from(wb.m())) as u32,
                    np as u32,
                    self.fault,
                    a(&acc, ACC_WORDS),
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
                    a(&acc, ACC_WORDS),
                    A_HSCAN as u32,
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
                    a(&acc, ACC_WORDS),
                    b,
                );
                wp::wsort_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static(self.nbk, 1, 1),
                    CubeDim::new_1d(256),
                    a(&self.off, nbk),
                    a(&self.histh, nbk),
                    a(&self.g_tmp, np * 4),
                    a(&self.g_rec, np * 4),
                    a(&acc, ACC_WORDS),
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
            ttq,
            ttqh,
            tstat,
            acc,
            l5n,
            hn,
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
        let est = self.mk(vec![0u32; EST_WORDS]);
        let ns = self.nslab_cap as usize;
        let npd = (wb.k - 1 - wb.f0) as usize;
        unsafe {
            if self.upto(3) && self.fault & F_SKIP_MAIN == 0 {
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
                    self.fault,
                    a(&ws.acc, ACC_WORDS),
                    self.lcap,
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
                    a(&est, EST_WORDS),
                    a(&ws.thdh, nt),
                    a(&ws.ttq, nt),
                    a(&ws.ttqh, nt),
                    a(&ws.pipd, npd),
                    a(&self.clip_h, 6),
                    wb.nlead,
                    wb.hlo,
                    1u32,
                    self.fault,
                    self.nslab_cap,
                    self.scap,
                    *c0,
                    wb.b,
                    wb.roots.len() as u32,
                    wb.f0,
                    wb.k,
                    self.pf2,
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
            est,
            tstat: None,
            head: None,
        }
    }

    /// Queue the slice's last kernel (its done word, the group's slice count).
    fn queue_done(&self, acc: &Handle, cnt: &Handle) {
        let a = |h: &Handle, n: usize| unsafe { ArrayArg::from_raw_parts(h.clone(), n.max(1)) };
        unsafe {
            wp::wdone_kernel::launch_unchecked::<R>(
                &self.client,
                CubeCount::Static(1, 1, 1),
                CubeDim::new_1d(32),
                a(acc, ACC_WORDS),
                a(cnt, NCNT),
            );
        }
    }

    /// Queue a whole slice into the group's counters.
    fn queue_slice(&self, pip: u64, rankh: &Handle, cnt: &Handle, out: &mut Vec<WTicket>) {
        let ws = self.queue_prep(pip, rankh, true);
        for bi in 0..self.batches.len() {
            let mut t = self.queue_batch(&ws, bi, cnt);
            if bi == 0 {
                t.tstat = Some(ws.tstat.clone());
                t.head = Some(WHead {
                    pip,
                    acc: ws.acc.clone(),
                    l5n: ws.l5n.clone(),
                    hn: ws.hn,
                    full: true,
                });
            }
            out.push(t);
        }
        self.queue_done(&ws.acc, cnt);
    }

    /// Synchronise and check every account of a group; with `per_slice`, each slice's own (pip, survivors) of
    /// this run is pushed (the sampled check's first half).
    fn finish_group(
        &self,
        cnt: &Handle,
        tickets: &[WTicket],
        mut per_slice: Option<&mut Vec<(u64, u64)>>,
    ) -> Result<WCounts> {
        self.sync()?;
        if self.stop != 6 {
            return Ok(WCounts::default());
        }
        // every small buffer of the group in one read (in this order: cnt; per ticket scount, ran, its tstat, stat,
        // est, its slice's acc and l5n)
        let mut hs = vec![cnt.clone()];
        for t in tickets {
            hs.extend([t.scount.clone(), t.ran.clone()]);
            if let Some(ts) = &t.tstat {
                hs.push(ts.clone());
            }
            hs.extend([t.stat.clone(), t.est.clone()]);
            if let Some(h) = &t.head {
                hs.push(h.acc.clone());
                if let Some(l) = &h.l5n {
                    hs.push(l.clone());
                }
            }
        }
        let nh = hs.len();
        let mut rv = cubecl::future::block_on(self.client.read_async(hs))
            .map_err(|e| anyhow!("read: {e:?}"))?
            .into_iter()
            .map(|b| u32::from_bytes(&b).to_vec());
        let mut next = || {
            rv.next()
                .ok_or_else(|| anyhow!("middle-out wide: {nh} buffers read, fewer returned"))
        };
        let v = next()?;
        ensure!(
            v[C_ERR_PLANE] == 0
                && v[C_ERR_PMAX] == 0
                && v[C_ERR_SLAB] == 0
                && v[C_ERR_CLASS] == 0
                && v[C_ERR_CLST] == 0,
            "middle-out wide kernel errors: plane {} pmax {} slab {} class {} child list {}",
            v[C_ERR_PLANE],
            v[C_ERR_PMAX],
            v[C_ERR_SLAB],
            v[C_ERR_CLASS],
            v[C_ERR_CLST]
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
        // per ticket: (parents listed, its slice's tops (certified, listed) if first, survivors in range)
        let mut per: Vec<(u32, Option<(u32, u32)>, u64)> = Vec::with_capacity(tickets.len());
        let mut accs = Vec::new();
        for t in tickets {
            let n = next()?[0];
            ensure!(
                n <= self.scap,
                "middle-out wide: survivor list overflow {n} > {}",
                self.scap
            );
            let ran = next()?;
            let want_sum = (u64::from(n) * u64::from(n.saturating_sub(1)) / 2 % (1 << 32)) as u32;
            ensure!(
                ran[0] == n && ran[1] == want_sum,
                "middle-out wide: check incomplete: {} of {n} entries, index sum {} (want {want_sum})",
                ran[0],
                ran[1]
            );
            let mut ntops = None;
            if t.tstat.is_some() {
                let s = next()?;
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
                ntops = Some((s[0], s[2]));
            }
            let st = next()?;
            let es = next()?;
            if let Some(h) = &t.head {
                let a = next()?;
                let l = if h.l5n.is_some() { Some(next()?) } else { None };
                accs.push((a, l));
            }
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
            // the expansion ran: every cube to its end, every used slab walked
            ensure!(
                es[0] == EXPAND_CUBES && es[1] == st[1].min(self.nslab_cap),
                "middle-out wide: expansion ran {} of {EXPAND_CUBES} cubes, walked {} of {} slabs",
                es[0],
                es[1],
                st[1]
            );
            ensure!(
                es[4] == n,
                "middle-out wide: expansion appended {n} survivors, its lanes counted {}",
                es[4]
            );
            // survivor bits the expansion read (before the prefilter), and those of a clipped top outside the range
            listed += u64::from(es[2]);
            clipped += u64::from(es[3]) + u64::from(ran[2]);
            dc.checked += u64::from(ran[0] - ran[2]);
            per.push((st[0], ntops, u64::from(es[2] - es[3] - ran[2])));
        }
        ensure!(
            listed == dc.survivors,
            "middle-out wide: {listed} survivor bits read by the expansion, the kernel counted {}",
            dc.survivors
        );
        // survivor bits of a clipped top outside the range are not survivors (the reference's `clipped`)
        dc.survivors -= clipped;
        // per slice: its tickets are consecutive, the first carries its head
        let mut heads = 0u64;
        let mut accs = accs.into_iter();
        let mut i = 0;
        while i < tickets.len() {
            let head = tickets[i]
                .head
                .as_ref()
                .ok_or_else(|| anyhow!("middle-out wide: a launch batch without its slice"))?;
            let mut j = i + 1;
            while j < tickets.len() && tickets[j].head.is_none() {
                j += 1;
            }
            let jobs: u64 = tickets[i..j].iter().map(|t| u64::from(t.jobs)).sum();
            let ntops = per[i].1.ok_or_else(|| {
                anyhow!("middle-out wide: slice {} without a top count", head.pip)
            })?;
            let (a, l5) = accs
                .next()
                .ok_or_else(|| anyhow!("middle-out wide: {nh} buffers read, fewer returned"))?;
            let Some(l5) = l5 else {
                bail!(
                    "middle-out wide: slice {} without its top-hierarchy count",
                    head.pip
                )
            };
            self.check_slice(head, &a, &l5, jobs, ntops, per[i].0)?;
            if let Some(ps) = per_slice.as_deref_mut() {
                ps.push((head.pip, per[i..j].iter().map(|x| x.2).sum()));
            }
            heads += 1;
            i = j;
        }
        // the slices the device ran to their last kernel, not the host's loop
        dc.slices = u64::from(v[C_SLICES]);
        ensure!(
            dc.slices == heads,
            "middle-out wide: {} slices done on the device, {heads} queued",
            dc.slices
        );
        Ok(dc)
    }

    /// One slice's account `a` (`A_*`) against what the host queued: `jobs` main-kernel instances, `ntops` tops
    /// (`tstat[0]`, the scan's sum of the segment counts, and `tstat[2]`, the compact list's own count), `lcnt`
    /// parents (the expansion's copy of the list length).
    fn check_slice(
        &self,
        h: &WHead,
        a: &[u32],
        l5n: &[u32],
        jobs: u64,
        ntops: (u32, u32),
        lcnt: u32,
    ) -> Result<()> {
        let pip = h.pip;
        let fail = |what: &str, got: u64, want: u64| -> Result<()> {
            ensure!(
                got == want,
                "middle-out wide: slice {pip}: {what}: {got}, want {want} (account {a:?})"
            );
            Ok(())
        };
        let (ntops, tlisted, lcnt) = (u64::from(ntops.0), u64::from(ntops.1), u64::from(lcnt));
        fail("plane errors", u64::from(a[A_ERR_PLANE]), 0)?;
        fail("slice done", u64::from(a[A_DONE]), 1)?;
        fail(
            "wtops5 cubes done",
            u64::from(l5n[1]),
            u64::from(self.wb.ntest().div_ceil(NT)),
        )?;
        fail(
            "wtops5 valid parents listed = counted by its lanes",
            u64::from(l5n[0]),
            u64::from(l5n[2]),
        )?;
        fail(
            "wtops1 valid parents examined",
            u64::from(a[A_T1_EXAM]),
            u64::from(l5n[0]),
        )?;
        fail("wtops1 tops certified", u64::from(a[A_T1_CERT]), ntops)?;
        fail("wscan (tops) ran", u64::from(a[A_TSCAN]), 1)?;
        fail("wtops2 tops placed", u64::from(a[A_T2_PLACED]), ntops)?;
        fail("wtops1 tops listed", tlisted, ntops)?;
        fail("wtdigz rows", u64::from(a[A_TDIG]), ntops)?;
        fail(
            "whist cubes done",
            u64::from(a[A_H_CUBES]),
            u64::from(h.hn.div_ceil(NT).max(1)),
        )?;
        fail(
            "parents certified (whist) = listed",
            u64::from(a[A_H_CERT]),
            lcnt,
        )?;
        fail("wscan (parents) ran", u64::from(a[A_HSCAN]), 1)?;
        fail("wscatter rows", u64::from(a[A_SCAT]), lcnt)?;
        fail(
            "wsort cubes done",
            u64::from(a[A_SORT]),
            u64::from(self.nbk),
        )?;
        fail("main-kernel job instances done", u64::from(a[A_JOBS]), jobs)?;
        if h.full {
            fail(
                "probes run = nroot x tops",
                u64::from(a[A_PROBES]),
                self.wb.roots.len() as u64 * ntops,
            )?;
            fail(
                "children seen by the main kernel = counted in the preparation",
                u64::from(a[A_CHILD]),
                u64::from(a[A_SC_CHILD]),
            )?;
        }
        Ok(())
    }

    /// The 8 key digits of a slice from the device's own tops and parents
    /// (every top, every parent: the CPU reference's rule exactly).
    ///
    /// # Errors
    /// Device errors.
    pub fn rank_of(&self, pip: u64) -> Result<[u32; 8]> {
        let b = self.wb.b;
        let rankh = self.mk((0..8).map(|i| i % b).collect());
        let ws = self.queue_prep(pip, &rankh, false);
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
        self.run_slice_with(pip, rank, false)
    }

    /// [`WideJoin::run_slice`], with `shared` the parents from the slice's shared list when one is built (tests).
    ///
    /// # Errors
    /// Device errors or a failed account.
    fn run_slice_with(
        &self,
        pip: u64,
        rank: &[u32; 8],
        shared: bool,
    ) -> Result<(WCounts, Vec<(u128, u32)>, Vec<(u32, u64, u32)>)> {
        let cnt = self.mk(vec![0u32; NCNT]);
        let rankh = self.mk(rank.to_vec());
        let ws = self.queue_prep(pip, &rankh, shared);
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
                t.head = Some(WHead {
                    pip,
                    acc: ws.acc.clone(),
                    l5n: ws.l5n.clone(),
                    hn: ws.hn,
                    full: true,
                });
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
        self.queue_done(&ws.acc, &cnt);
        let dc = self.finish_group(&cnt, &tk, None)?;
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

/// The sampled check's CPU half: slice `pip` through the CPU reference (`u128` masks) on `threads` threads: its
/// survivors, and those that pass the prefilter, sorted.
pub(crate) fn wide_cpu_slice(
    coord: &Coord,
    sh: Shape,
    pip: u64,
    threads: usize,
) -> (u64, Vec<u128>) {
    let base = Base::new(coord);
    let mut v = Vec::new();
    let cn = super::cpu::slice_join_threads::<u128>(
        &base,
        sh,
        u128::from(pip),
        threads,
        |_, n, pass| {
            if pass {
                v.push(n);
            }
        },
    );
    v.sort_unstable();
    (cn.survivors, v)
}

/// The sampled check's device half: the field run's own survivors of slice `pip` (`in_field`, if recorded), then
/// the slice again alone on the device (key `rank`), its survivors n for n, against the CPU's.
///
/// # Errors
/// Any difference, or a failed account of the device run.
pub(crate) fn wide_sample_compare<R: Runtime>(
    gj: &WideJoin<R>,
    pip: u64,
    rank: &[u32; 8],
    in_field: Option<u64>,
    cpu: &(u64, Vec<u128>),
) -> Result<()> {
    if let Some(s) = in_field {
        ensure!(
            s == cpu.0,
            "middle-out wide: sampled CPU check of slice {pip}: the field run counted survivors {s}, CPU {}",
            cpu.0
        );
    }
    let (dc, got, _) = gj.run_slice(pip, rank)?;
    let mut gn: Vec<u128> = got.into_iter().map(|x| x.0).collect();
    gn.sort_unstable();
    ensure!(
        dc.survivors == cpu.0 && dc.checked == cpu.1.len() as u64 && gn == cpu.1,
        "middle-out wide: sampled CPU check of slice {pip} differs: device survivors {} checked {} list {}, CPU \
         survivors {} checked {}",
        dc.survivors,
        dc.checked,
        gn.len(),
        cpu.0,
        cpu.1.len()
    );
    Ok(())
}

/// How a field is run on the wide path.
#[derive(Clone, Copy, Debug)]
pub struct WideOptions {
    /// Slices per synchronisation (1-256).
    pub group: usize,
    /// The sampled CPU check (as on the base-64 path): one random slice of the field recomputed by the CPU reference on a
    /// host thread while the card works; the field run's own survivors for that slice must equal the CPU's, and
    /// the slice run again alone on the device must give the same survivors, n for n. The CPU slice runs on
    /// `cpu_threads` threads (0: [`super::gpu::sample_threads`]); at base 65 it took 106 s on one thread and 33 s
    /// on four (a 5-CPU box), against a field of 56 s on an RTX 3080.
    pub cpu_check: bool,
    /// Threads for the sampled check's CPU slice; 0 for [`super::gpu::sample_threads`]' default.
    pub cpu_threads: usize,
}

/// Search a field on the wide device path: the key from the field's first slice (the device's tops and parents),
/// then every slice queued, one synchronisation per `group` slices, every account checked; with `cpu_check`, one
/// random slice also recomputed on the CPU.
///
/// # Errors
/// A field that is not whole quanta, a shape that cannot search it, a join with a timing stop set, any failed
/// account, or a sampled check that differs.
pub fn search_field_wide<R: Runtime>(
    gj: &WideJoin<R>,
    coord: &Coord,
    v_start: u128,
    v_size: u128,
    opt: WideOptions,
) -> Result<(FieldOutcome, WCounts, FieldTiming)> {
    ensure!(
        gj.stop == 6,
        "middle-out wide: a timing stop ({}) is set: this join only times stages",
        gj.stop
    );
    run_field_wide(gj, coord, v_start, v_size, opt, None, None)
}

/// (tests) [`search_field_wide`] on the slices `sel` of the field's slice list, returning each group's slices
/// and the device's counts for it (one slice per group with `opt.group` 1): the field path, slice by slice.
///
/// # Errors
/// As [`search_field_wide`].
#[cfg(all(test, feature = "midout-box-tests"))]
pub(crate) fn search_field_wide_groups<R: Runtime>(
    gj: &WideJoin<R>,
    coord: &Coord,
    v_start: u128,
    v_size: u128,
    opt: WideOptions,
    sel: std::ops::Range<usize>,
) -> Result<(FieldOutcome, Vec<(Vec<u64>, WCounts)>)> {
    ensure!(gj.stop == 6, "middle-out wide: a timing stop is set");
    let mut rec = Vec::new();
    let (o, _, _) = run_field_wide(gj, coord, v_start, v_size, opt, Some(sel), Some(&mut rec))?;
    Ok((o, rec))
}

/// **Timing only** (benches, feature `midout-bench`): time a field with the join's timing stop
/// (`WideJoin::set_timing_stop`): the stages up to it, nothing checked or returned but the time.
///
/// # Errors
/// A field that is not whole quanta, or device errors.
#[cfg(feature = "midout-bench")]
pub fn time_field_wide<R: Runtime>(
    gj: &WideJoin<R>,
    coord: &Coord,
    v_start: u128,
    v_size: u128,
    group: usize,
) -> Result<FieldTiming> {
    let opt = WideOptions {
        group,
        cpu_check: false,
        cpu_threads: 0,
    };
    Ok(run_field_wide(gj, coord, v_start, v_size, opt, None, None)?.2)
}

fn run_field_wide<R: Runtime>(
    gj: &WideJoin<R>,
    coord: &Coord,
    v_start: u128,
    v_size: u128,
    opt: WideOptions,
    sel: Option<std::ops::Range<usize>>,
    mut rec: Option<&mut Vec<(Vec<u64>, WCounts)>>,
) -> Result<(FieldOutcome, WCounts, FieldTiming)> {
    let sh = Shape {
        f0: gj.wb.f0,
        k: gj.wb.k,
    };
    ensure!(coord.b() == gj.wb.b, "middle-out wide: base mismatch");
    ensure!(
        (1..=256).contains(&opt.group),
        "middle-out wide: group of {} slices (1-256)",
        opt.group
    );
    sh.fits(coord)?;
    let ts = coord.field_digits(v_start, v_size)?;
    let mut pips: Vec<u64> = ts
        .flat_map(|t| sh.slices_of(coord, t).map(|p| p as u64).collect::<Vec<_>>())
        .collect();
    if let Some(r) = sel {
        let end = r.end.min(pips.len());
        ensure!(
            r.start < end,
            "middle-out wide: slices {r:?} of a field of {}",
            pips.len()
        );
        pips = pips[r.start..end].to_vec();
    }
    let nice_before = gj.nice()?;
    let t0 = Instant::now();
    let sample = if opt.cpu_check && gj.stop == 6 {
        use std::hash::{BuildHasher, Hasher};
        let mut hs = std::collections::hash_map::RandomState::new().build_hasher();
        hs.write_u128(v_start);
        let pip = pips[(hs.finish() % pips.len() as u64) as usize];
        let c = coord.clone();
        let threads = super::gpu::sample_threads(opt.cpu_threads);
        Some((
            pip,
            std::thread::spawn(move || {
                let t = Instant::now();
                let r = wide_cpu_slice(&c, sh, pip, threads);
                (r, t.elapsed().as_secs_f64())
            }),
        ))
    } else {
        None
    };
    let rank = gj.rank_of(pips[0])?;
    // the parents' shared lists, when the field's slices repeat their digits [f0, k - 2)
    gj.anc.lock().expect("anc").keys.clear();
    if gj.share && gj.upto(2) && gj.wb.k - 2 > gj.wb.f0 {
        let mut keys: Vec<u64> = Vec::new();
        for &p in &pips {
            let k = gj.anc_key(p);
            if !keys.contains(&k) {
                keys.push(k);
                if keys.len() > ANC_LISTS {
                    break;
                }
            }
        }
        if keys.len() <= ANC_LISTS && keys.len() < pips.len() {
            gj.build_anc(&keys)?;
        }
    }
    let host_wait = t0.elapsed().as_secs_f64();
    let rankh = gj.mk(rank.to_vec());
    let mut total = WCounts::default();
    let mut sync_s = 0f64;
    let mut done = 0usize;
    let mut per_slice = Vec::new();
    while done < pips.len() {
        let cnt = gj.mk(vec![0u32; NCNT]);
        let mut tk = Vec::new();
        let k0 = done;
        while done < pips.len() && done - k0 < opt.group {
            gj.queue_slice(pips[done], &rankh, &cnt, &mut tk);
            done += 1;
        }
        let tsync = Instant::now();
        let g = gj.finish_group(&cnt, &tk, sample.as_ref().map(|_| &mut per_slice))?;
        sync_s += tsync.elapsed().as_secs_f64();
        total.add(&g);
        if let Some(r) = rec.as_mut() {
            r.push((pips[k0..done].to_vec(), g));
        }
    }
    gj.anc.lock().expect("anc").keys.clear();
    let field = t0.elapsed().as_secs_f64();
    let mut tm = FieldTiming {
        wall: field,
        host_wait,
        sync: sync_s,
        field,
        ..FieldTiming::default()
    };
    if gj.stop != 6 {
        return Ok((FieldOutcome::default(), total, tm));
    }
    if let Some((pip, h)) = sample {
        let tw = Instant::now();
        let (cpu, tcpu) = h
            .join()
            .map_err(|_| anyhow!("middle-out wide: the sampled CPU check panicked"))?;
        tm.cpu_wait = tw.elapsed().as_secs_f64();
        tm.cpu_check = tcpu;
        let in_field = per_slice.iter().find(|x| x.0 == pip).map(|x| x.1);
        ensure!(
            in_field.is_some(),
            "middle-out wide: the sampled slice {pip} has no count from the field run"
        );
        let td = Instant::now();
        wide_sample_compare(gj, pip, &rank, in_field, &cpu)?;
        tm.sample_dev = td.elapsed().as_secs_f64();
        tm.sampled = Some(pip);
    }
    tm.wall = t0.elapsed().as_secs_f64();
    let mut nice = gj.nice()?;
    for n in &nice_before {
        if let Some(i) = nice.iter().position(|x| x == n) {
            nice.remove(i);
        }
    }
    for &n in &nice {
        ensure!(
            super::arith::unique_digits(n, coord.b()).1,
            "middle-out wide: device reported {n}, not nice"
        );
        ensure!(
            n >= coord.start() && n < coord.end(),
            "middle-out wide: device reported {n}, outside the range"
        );
        let v = coord.v_of_n(n);
        ensure!(
            v >= v_start && v < v_start + v_size,
            "middle-out wide: device reported {n} (v {v}), outside the field"
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
        tm,
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

    /// Base 65 under the coordinate `(4, 8, 5)` (padded; digits 5–7 fixed): a field's slices for the
    /// listed digit-8 values, through the field path one slice per group, each equal (children, chunks, flat,
    /// survivors, checked, tops) to the same slice run as a part of the `(4, 9, 6)` field that holds it; the
    /// per-slice counts sum to the field runs'. With `MIDOUT_485_WHOLE=1` also the whole new field through the
    /// production path (group 16; the sampled CPU check with `MIDOUT_485_CHECK=1`: ~90 s of CPU).
    /// `MIDOUT_485_T` (default 13731), `MIDOUT_485_D8` (default `0,1,64`).
    #[cfg(feature = "midout-box-tests")]
    #[test]
    #[ignore = "needs a GPU (MIDOUT_CUDA=1 for the CUDA runtime) and minutes"]
    fn wide_field_485_equals_496_slice_by_slice() {
        use std::collections::HashMap;
        let ctx = device().expect("a device");
        let b = 65u32;
        let bb = u128::from(b);
        let tn: u128 = std::env::var("MIDOUT_485_T")
            .ok()
            .map_or(13_731, |s| s.parse().unwrap());
        let d8s: Vec<u128> = std::env::var("MIDOUT_485_D8")
            .unwrap_or_else(|_| "0,1,64".into())
            .split(',')
            .map(|x| x.parse().unwrap())
            .collect();
        let cn = Coord::with_digits(b, 4, 8, 5).unwrap();
        let co = Coord::with_digits(b, 4, 9, 6).unwrap();
        let sh = Shape::for_coord(&cn);
        assert_eq!(sh, Shape::for_coord(&co));
        let (qn, qo) = (cn.quantum(), co.quantum());
        let key = |c: &WCounts| {
            (
                c.children,
                c.chunks,
                c.flat,
                c.survivors,
                c.checked,
                c.tops,
                c.slices,
            )
        };
        macro_rules! go {
            ($client:expr) => {{
                let gj = WideJoin::new($client, WideCaps::for_base(b), &cn, sh).unwrap();
                let opt1 = WideOptions { group: 1, cpu_check: false, cpu_threads: 0 };
                let bu = b as usize;
                let (mut newc, mut oldc): (HashMap<u64, WCounts>, HashMap<u64, WCounts>) = (HashMap::new(), HashMap::new());
                let (d5, hi) = (tn % bb, tn / bb);
                for &d8 in &d8s {
                    let sel = (d8 as usize) * bu..(d8 as usize) * bu + bu;
                    let (o, rec) = search_field_wide_groups(&gj, &cn, cn.start() + tn * qn, qn, opt1, sel).unwrap();
                    let (mut s1, mut c1) = (0, 0);
                    for (p, c) in rec {
                        assert_eq!((u128::from(p[0]) / bb) % bb.pow(3), tn, "slice {} outside the field", p[0]);
                        assert_eq!(u128::from(p[0]) / bb.pow(4), d8);
                        s1 += c.survivors;
                        c1 += c.checked;
                        assert!(newc.insert(p[0], c).is_none());
                    }
                    assert_eq!((s1, c1), (o.survivors, o.checked));
                    let to = hi + bb * bb * d8;
                    let sel = (d5 as usize) * bu..(d5 as usize) * bu + bu;
                    let (_, rec) = search_field_wide_groups(&gj, &co, co.start() + to * qo, qo, opt1, sel).unwrap();
                    for (p, c) in rec {
                        assert!(oldc.insert(p[0], c).is_none());
                    }
                }
                assert_eq!(newc.len(), bu * d8s.len());
                assert_eq!(oldc.len(), newc.len());
                for (p, c) in &newc {
                    let o = oldc.get(p).unwrap_or_else(|| panic!("slice {p} not in the (4, 9, 6) runs"));
                    assert_eq!(key(c), key(o), "slice {p}: (4, 8, 5) {c:?} vs (4, 9, 6) {o:?}");
                }
                let ns: u64 = newc.values().map(|c| c.survivors).sum();
                let nc: u64 = newc.values().map(|c| c.checked).sum();
                println!("b65 (4, 8, 5) field t {tn}, digit 8 in {d8s:?}: {} slices equal to (4, 9, 6)'s, survivors {ns}, checked {nc}", newc.len());
                if std::env::var("MIDOUT_485_WHOLE").is_ok_and(|x| x == "1") {
                    let cpu_check = std::env::var("MIDOUT_485_CHECK").is_ok_and(|x| x == "1");
                    let (o, _, tm) = search_field_wide(&gj, &cn, cn.start() + tn * qn, qn, WideOptions { group: 16, cpu_check, cpu_threads: 0 }).unwrap();
                    println!(
                        "b65 (4, 8, 5) whole field t {tn}: survivors {}, checked {}, slices {}, nice {:?}, sampled {:?} ({:.1} s), n {}",
                        o.survivors, o.checked, o.slices, o.nice, tm.sampled, tm.wall, cn.n_count(cn.start() + tn * qn, qn).unwrap()
                    );
                    assert_eq!(o.slices, 4225);
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

    fn device() -> Option<crate::cubecl_backend::CubeclContext> {
        #[cfg(feature = "cubecl-cuda")]
        if std::env::var("MIDOUT_CUDA").is_ok() {
            return crate::cubecl_backend::CubeclContext::new_cuda(0).ok();
        }
        crate::cubecl_backend::CubeclContext::new_default().ok()
    }

    /// One slice through the CPU reference (u128 masks) on `threads` threads
    /// (units split), survivors with their units.
    fn cpu_slice(coord: &Coord, sh: Shape, pip: u128) -> (Counts, Vec<u128>, Vec<u128>) {
        let base = Base::new(coord);
        let mut v = Vec::new();
        let mut pv = Vec::new();
        let cn = slice_join::<u128>(&base, sh, pip, |_, n, pass| {
            v.push(n);
            if pass {
                pv.push(n);
            }
        });
        v.sort_unstable();
        pv.sort_unstable();
        (cn, v, pv)
    }

    /// The wide device path against the CPU reference on whole slices `cases` (`(b, f0, k, pip)`): tops count and
    /// the tops themselves (unit, lead, mask), survivor sets n for n, children, chunks, flat, kept (the key is the reference's rule), survivors = checked,
    /// and the check's distinct digits of every survivor = the reference's. `classes` the batch width.
    /// `MIDOUT_NINST`, `MIDOUT_MAXPOP`, `MIDOUT_NOPF=1` and `MIDOUT_FORCE_W` (the compile-only path) change the
    /// run when set.
    fn wide_slices_equal(cases: &[(u32, u32, u32, u64)], classes: Option<u32>) {
        let ctx = device().expect("a device");
        macro_rules! go {
            ($client:expr) => {{
                for &(b, f0, k, pip) in cases {
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
                    // MIDOUT_FORCE_W=64: compile for that plane width on any device (lavapipe), run, report and stop:
                    // only the SPIR-V is wanted (`CUBECL_DEBUG_SPIRV`); the results are invalid
                    let force_w: Option<u32> = std::env::var("MIDOUT_FORCE_W").ok().map(|x| x.parse().unwrap());
                    let mut gj = WideJoin::with_width($client, caps, &coord, sh, force_w).unwrap();
                    if force_w.is_some() {
                        // also the shared lists' kernel (`wanc`); its plane check fails under a forced width
                        if k - 2 > f0 {
                            let ra = gj.build_anc(&[gj.anc_key(pip)]);
                            println!("COMPILE-ONLY W {} base {b} slice {pip}: wanc {ra:?}", gj.w);
                        }
                        let rank = gj.rank_of(pip).unwrap();
                        let r = gj.run_slice(pip, &rank).map(|x| x.0);
                        println!("COMPILE-ONLY W {} base {b} slice {pip}: {r:?}", gj.w);
                        continue;
                    }
                    // MIDOUT_WIDE_SHARE=1: the slice's parents from its shared list (`wanc`, digits [f0, k - 2))
                    let share = k - 2 > f0 && std::env::var("MIDOUT_WIDE_SHARE").is_ok_and(|x| x == "1");
                    if share {
                        gj.build_anc(&[gj.anc_key(pip)]).unwrap();
                    }
                    // MIDOUT_NOPF=1: no prefilter, whole survivor sets
                    let nopf = std::env::var("MIDOUT_NOPF").is_ok_and(|x| x == "1");
                    if nopf {
                        gj.set_fault(F_NOPF);
                    }
                    println!(
                        "device {} W {} base {b} shape ({f0}, {k}) slice {pip} prefilter {}",
                        ctx.device_name(),
                        gj.w,
                        !nopf
                    );
                    let t0 = Instant::now();
                    let rank = gj.rank_of(pip).unwrap();
                    let (dc, mut got, tops) = gj.run_slice_with(pip, &rank, share).unwrap();
                    if share {
                        let used = gj.anc.lock().expect("anc").used;
                        println!("slice {pip}: parents from the shared list ({} of {} roots)", gj.anc_for(pip).unwrap().1, gj.nrf);
                        assert_eq!(used, (1, 1), "slice {pip}: the shared list was not used");
                    }
                    let tdev = t0.elapsed().as_secs_f64();
                    let t1 = Instant::now();
                    let (cn, all, pass) = cpu_slice(&coord, sh, u128::from(pip));
                    let want = if nopf { all } else { pass };
                    println!("slice {pip}: device {dc:?} ({tdev:.1} s)");
                    println!(
                        "slice {pip}: cpu    {cn:?} ({:.1} s)",
                        t1.elapsed().as_secs_f64()
                    );
                    assert_eq!(tops.len() as u64, cn.tops, "tops");
                    assert_eq!(gj.wb.tested(pip), cn.tops_tested, "tops tested");
                    // the tops themselves: (unit, lead, mask) of the device's against the reference's
                    let mut dt: Vec<(u32, u128, u128)> = tops
                        .iter()
                        .map(|&(ix, lo, hi)| {
                            (
                                ix / gj.wb.nlead,
                                u128::from(gj.wb.hlo + ix % gj.wb.nlead),
                                u128::from(lo) | u128::from(hi) << 64,
                            )
                        })
                        .collect();
                    let cb = Base::new(&coord);
                    let step = cb.pw[(k - 1 - f0) as usize];
                    let nth = std::thread::available_parallelism().map_or(4, |x| x.get()) as u32;
                    let mut ct: Vec<(u32, u128, u128)> = std::thread::scope(|s| {
                        let hs: Vec<_> = (0..nth)
                            .map(|j| {
                                let cb = &cb;
                                s.spawn(move || {
                                    let mut v = Vec::new();
                                    for d in (j..b).step_by(nth as usize) {
                                        let mut tested = 0u64;
                                        let u = u128::from(pip) + u128::from(d) * step;
                                        for t in crate::midout::cpu::unit_tops::<u128>(cb, sh, u, &mut tested) {
                                            v.push((d, t.h, t.mask));
                                        }
                                    }
                                    v
                                })
                            })
                            .collect();
                        hs.into_iter().flat_map(|h| h.join().unwrap()).collect()
                    });
                    dt.sort_unstable();
                    ct.sort_unstable();
                    assert!(dt == ct, "tops differ from the reference's");
                    got.sort_unstable();
                    let gn: Vec<u128> = got.iter().map(|x| x.0).collect();
                    assert_eq!(gn.len(), want.len(), "listed count");
                    assert!(gn == want, "listed sets differ");
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
                            if nopf { cn.survivors } else { cn.checked }
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

    /// Tier (b): one base-40 slice, shape (3, 6), 4 classes per batch.
    #[test]
    #[ignore = "needs a GPU (lavapipe will do; MIDOUT_CUDA=1 for CUDA)"]
    fn cubecl_midout_wide_b40_slice_equals_cpu() {
        wide_slices_equal(&[(40, 3, 6, 1234)], Some(4));
    }

    /// Tier (c): [`wide_slices_equal`] from the environment: `MIDOUT_WIDE_CASES`, a comma list of `b:f0:k:pip`
    /// (default a base-65 slice), and `MIDOUT_CLASSES`.
    #[cfg(feature = "midout-box-tests")]
    #[test]
    #[ignore = "needs a GPU (MIDOUT_CUDA=1 for the CUDA runtime) and minutes of CPU"]
    fn wide_slices_equal_cpu() {
        let cases: Vec<(u32, u32, u32, u64)> = std::env::var("MIDOUT_WIDE_CASES")
            .unwrap_or_else(|_| "65:4:10:717171717".into())
            .split(',')
            .map(|s| {
                let f: Vec<u64> = s.split(':').map(|x| x.parse().unwrap()).collect();
                (f[0] as u32, f[1] as u32, f[2] as u32, f[3])
            })
            .collect();
        let classes = std::env::var("MIDOUT_CLASSES")
            .ok()
            .map(|s| s.parse().unwrap());
        wide_slices_equal(&cases, classes);
    }

    /// Whole small bases through the wide device path against brute force:
    /// every slice of the base on the device; the union of the survivors is
    /// exactly the set of n passing the shape's predicate (no n twice), and
    /// the device's check reports exactly the nice numbers (69 at base 10).
    /// The CPU reference's own brute-force cases, here on the device.
    #[cfg(feature = "midout-box-tests")]
    #[test]
    #[ignore = "needs a GPU (MIDOUT_CUDA=1 for the CUDA runtime)"]
    fn wide_whole_small_bases_vs_brute_force() {
        use crate::midout::cpu::{q_checked, q_shape};
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
                        (coord.start()..coord.end()).filter(|&n| unique_digits(n, b).1).collect();
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
                            assert_eq!(dc.checked, v.len() as u64);
                            surv += dc.survivors;
                            for (n, u) in v {
                                assert!(got.insert(n), "b{b} {sh:?}: n {n} twice");
                                assert_eq!(unique_digits(n, b).0, u, "b{b}: distinct digits of {n}");
                            }
                        }
                        let want: HashSet<u128> =
                            (coord.start()..coord.end()).filter(|&n| q_checked::<u128>(&base, sh, n)).collect();
                        let nsurv =
                            (coord.start()..coord.end()).filter(|&n| q_shape::<u128>(&base, sh, n)).count() as u64;
                        assert_eq!(got, want, "b{b} shape {sh:?}: checked n differ from brute force");
                        assert_eq!(surv, nsurv, "b{b} shape {sh:?}: survivors");
                        assert_eq!(gj.nice().unwrap(), nice_brute, "b{b} shape {sh:?}: nice");
                        println!(
                            "b{b} shape ({f0}, {k}): {npip} slices, {nsurv} survivors, {} checked = brute force, nice {:?}: PASS",
                            want.len(),
                            nice_brute
                        );
                        if k - 2 > f0 {
                            shared_vs_brute(&gj, b, sh, npip, &want, nsurv, &nice_brute);
                        }
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

    /// [`wide_whole_small_bases_vs_brute_force`] with the parents shared across the slice's top digit (`wanc`):
    /// (1) every slice through its key's shared list, survivors n for n against brute force (`want`, `nsurv`),
    /// every slice's list used; (2) the field path with sharing on (production's driver, its sampled check on), one
    /// field per value of digit f0, b slices per key: survivors, checked and nice numbers against brute force.
    #[cfg(feature = "midout-box-tests")]
    fn shared_vs_brute<R: Runtime>(
        gj: &WideJoin<R>,
        b: u32,
        sh: Shape,
        npip: u64,
        want: &std::collections::HashSet<u128>,
        nsurv: u64,
        nice_brute: &[u128],
    ) {
        use std::collections::HashSet;
        let (f0, k) = (sh.f0, sh.k);
        let mut keys: Vec<u64> = (0..npip).map(|p| gj.anc_key(p)).collect();
        keys.sort_unstable();
        keys.dedup();
        let u0 = gj.anc.lock().expect("anc").used;
        let mut got = HashSet::new();
        let mut surv = 0u64;
        let mut empty = 0usize;
        for ch in keys.chunks(ANC_LISTS) {
            gj.build_anc(ch).unwrap();
            empty += gj
                .anc
                .lock()
                .expect("anc")
                .lens
                .iter()
                .filter(|&&n| n == 0)
                .count();
            for pip in (0..npip).filter(|&p| ch.contains(&gj.anc_key(p))) {
                let rank = gj.rank_of(pip).unwrap();
                let (dc, v, _) = gj.run_slice_with(pip, &rank, true).unwrap();
                assert_eq!(dc.checked, v.len() as u64);
                surv += dc.survivors;
                for (n, u) in v {
                    assert!(got.insert(n), "b{b} {sh:?} shared: n {n} twice");
                    assert_eq!(
                        unique_digits(n, b).0,
                        u,
                        "b{b} shared: distinct digits of {n}"
                    );
                }
            }
        }
        let u1 = gj.anc.lock().expect("anc").used;
        assert_eq!(
            u1.0 - u0.0,
            npip,
            "b{b} {sh:?}: slices through a shared list"
        );
        assert!(
            &got == want,
            "b{b} shape {sh:?}: shared: checked n differ from brute force"
        );
        assert_eq!(surv, nsurv, "b{b} shape {sh:?}: shared: survivors");
        println!(
            "b{b} shape ({f0}, {k}) shared: {} lists ({empty} empty), {npip} slices through them ({} with a list shorter than the {} roots), n for n = brute force: PASS",
            keys.len(),
            u1.1 - u0.1,
            gj.nrf
        );
        let cf = Coord::with_digits(b, f0, f0 + 1, f0).unwrap();
        let q = cf.quantum();
        let opt = WideOptions {
            group: 16,
            cpu_check: true,
            cpu_threads: 2,
        };
        let (mut fs, mut fc, mut nice) = (0u64, 0u64, Vec::new());
        let u0 = gj.anc.lock().expect("anc").used;
        let mut lists = 0usize;
        for t in 0..u128::from(b) {
            let (o, _, tm) = search_field_wide(gj, &cf, cf.start() + t * q, q, opt).unwrap();
            assert!(tm.sampled.is_some(), "b{b} field {t}: no sampled check");
            lists += gj.parent_sharing_last().0;
            fs += o.survivors;
            fc += o.checked;
            nice.extend(o.nice);
        }
        nice.sort_unstable();
        let u1 = gj.anc.lock().expect("anc").used;
        assert_eq!(
            u1.0 - u0.0,
            npip,
            "b{b} {sh:?}: field slices through a shared list"
        );
        assert_eq!(
            (fs, fc),
            (nsurv, want.len() as u64),
            "b{b} {sh:?}: field path, shared"
        );
        assert_eq!(nice, nice_brute, "b{b} {sh:?}: field path, shared: nice");
        println!(
            "b{b} shape ({f0}, {k}) field path shared: {b} fields, {lists} lists, {npip} slices, survivors {fs}, checked {fc}, nice = brute force, sampled checks equal: PASS"
        );
    }

    #[cfg(feature = "cubecl-cuda")]
    fn wcuda_client() -> ComputeClient<cubecl::cuda::CudaRuntime> {
        match crate::cubecl_backend::CubeclContext::new_cuda(0).expect("a CUDA device") {
            crate::cubecl_backend::CubeclContext::Cuda { client, .. } => client,
            #[allow(unreachable_patterns)]
            crate::cubecl_backend::CubeclContext::Wgpu { .. } => panic!("not CUDA"),
        }
    }

    /// The production group path (`queue_slice` + `finish_group`, exactly `search_field_wide`'s) on `pips`.
    fn wgroup<R: Runtime>(gj: &WideJoin<R>, rank: &[u32; 8], pips: &[u64]) -> Result<WCounts> {
        let rankh = gj.mk(rank.to_vec());
        let cnt = gj.mk(vec![0u32; NCNT]);
        let mut tk = Vec::new();
        for &p in pips {
            gj.queue_slice(p, &rankh, &cnt, &mut tk);
        }
        gj.finish_group(&cnt, &tk, None)
    }

    /// `MIDOUT_WIDE_FAULT_CASE`: `b:pip,pip,...` (default base 65, slices 717171717 and 0).
    #[cfg(feature = "midout-box-tests")]
    fn fault_case() -> (u32, Vec<u64>) {
        let c = std::env::var("MIDOUT_WIDE_FAULT_CASE").unwrap_or_else(|_| "65:717171717,0".into());
        let (b, p) = c.split_once(':').expect("b:pips");
        (
            b.parse().unwrap(),
            p.split(',').map(|x| x.trim().parse().unwrap()).collect(),
        )
    }

    /// The base-64 path's fault acceptance on the wide path, base `b` shape `sh` on `pips`: the faults that apply
    /// are loud through the accounts of the production group path (`F_SKIP_MAIN`, `F_SKIP_TOPS`, `F_DROP_PROBE`,
    /// `F_DROP_PARENT`; `F_T5_SPLIT`, `F_EXP_SPLIT`, `F_SLAB_SPLIT`: entries lost from a ballot or plane scan,
    /// loud through the counts the lanes keep apart from it), a clean run passes before each (and after it, with `again`) with the unfaulted counts, and
    /// `F_BAD_PARENT` (a parent computed wrongly: every conservation law still holds) is loud through the sampled
    /// CPU check.
    #[allow(clippy::match_wildcard_for_single_variants)]
    fn wide_faults<R: Runtime>(
        client: ComputeClient<R>,
        b: u32,
        pips: &[u64],
        sh: Shape,
        classes: Option<u32>,
        again: bool,
    ) {
        let coord = Coord::with_digits(b, 0, 1, 0).unwrap();
        let sp = pips[0];
        let cpu = std::thread::spawn({
            let c = coord.clone();
            move || wide_cpu_slice(&c, sh, sp, crate::midout::gpu::sample_threads(0))
        });
        let mut caps = WideCaps::for_base(b);
        if let Some(c) = classes {
            caps.classes = c.min(b - 1);
        }
        let mut gj = WideJoin::new(client, caps, &coord, sh).unwrap();
        let rank = gj.rank_of(pips[0]).unwrap();
        println!(
            "base {b} W {} classes {} slices {pips:?}",
            gj.w, caps.classes
        );
        let base = wgroup(&gj, &rank, pips).expect("the run without a fault passes its accounts");
        println!("fault 0: accounts pass: {base:?}");
        let mut silent = Vec::new();
        for (name, f) in [
            ("F_SKIP_MAIN", F_SKIP_MAIN),
            ("F_SKIP_TOPS", F_SKIP_TOPS),
            ("F_DROP_PROBE", F_DROP_PROBE),
            ("F_DROP_PARENT", F_DROP_PARENT),
            ("F_T5_SPLIT", F_T5_SPLIT),
            ("F_EXP_SPLIT", F_EXP_SPLIT),
            ("F_SLAB_SPLIT", F_SLAB_SPLIT),
            ("F_BAD_PARENT", F_BAD_PARENT),
            ("F_PF_DROP", F_PF_DROP),
        ] {
            gj.set_fault(f);
            let r = wgroup(&gj, &rank, pips);
            gj.set_fault(0);
            match r {
                Err(e) => println!("{name} ({f}): accounts LOUD: {e}"),
                Ok(dc) => {
                    println!(
                        "{name} ({f}): accounts pass: survivors {} vs {}",
                        dc.survivors, base.survivors
                    );
                    if f != F_BAD_PARENT && f != F_PF_DROP {
                        silent.push(name);
                    }
                }
            }
            if again {
                let a = wgroup(&gj, &rank, pips).expect("a clean run after the fault");
                assert_eq!(a, base, "clean run after {name}");
            }
        }
        let t = Instant::now();
        let cpu = cpu.join().unwrap();
        println!(
            "CPU reference of slice {sp}: survivors {} (waited {:.1} s)",
            cpu.0,
            t.elapsed().as_secs_f64()
        );
        wide_sample_compare(&gj, sp, &rank, None, &cpu)
            .expect("the sampled check of a clean run is equal");
        println!(
            "sampled check, no fault: slice {sp} equal (survivors {})",
            cpu.0
        );
        for (name, f) in [("F_BAD_PARENT", F_BAD_PARENT), ("F_PF_DROP", F_PF_DROP)] {
            gj.set_fault(f);
            let r = wide_sample_compare(&gj, sp, &rank, None, &cpu);
            gj.set_fault(0);
            match r {
                Err(e) => println!("{name}: sampled check LOUD: {e}"),
                Ok(()) => silent.push(name),
            }
        }
        assert!(silent.is_empty(), "silent faults: {silent:?}");
    }

    /// The device the wide tests run on: CUDA with `MIDOUT_CUDA`, else the default wgpu device.
    macro_rules! on_wide_device {
        ($go:expr) => {{
            #[cfg(feature = "cubecl-cuda")]
            if std::env::var("MIDOUT_CUDA").is_ok() {
                return $go(wcuda_client());
            }
            match crate::cubecl_backend::CubeclContext::new_default().expect("a device") {
                crate::cubecl_backend::CubeclContext::Wgpu { client, .. } => $go(client),
                #[allow(unreachable_patterns)]
                _ => panic!("unsupported runtime"),
            }
        }};
    }

    /// Tier (b): [`wide_faults`] at base 40, shape (3, 6), one slice, 4 classes per batch, no rerun.
    #[test]
    #[ignore = "needs a GPU (lavapipe will do; MIDOUT_CUDA=1 for CUDA)"]
    fn cubecl_midout_wide_b40_faults_are_loud() {
        on_wide_device!(|c| wide_faults(c, 40, &[1234], Shape { f0: 3, k: 6 }, Some(4), false));
    }

    /// Tier (c): [`wide_faults`] from the environment: `MIDOUT_WIDE_FAULT_CASE` `b:pip,pip,...` (default base 65,
    /// slices 717171717 and 0; `64:712012851` forces the wide path at base 64), `MIDOUT_WIDE_FAULT_SHAPE` `f0:k`
    /// (4:10), `MIDOUT_CLASSES` the batch width, `AUDIT_AGAIN=0` skips the clean rerun after each fault.
    #[cfg(feature = "midout-box-tests")]
    #[test]
    #[ignore = "needs a GPU (MIDOUT_CUDA=1 for CUDA) and a minute or two of CPU"]
    fn wide_faults_are_loud() {
        let (b, pips) = fault_case();
        let sh = std::env::var("MIDOUT_WIDE_FAULT_SHAPE").map_or(Shape { f0: 4, k: 10 }, |x| {
            let (f, k) = x.split_once(':').expect("f0:k");
            Shape {
                f0: f.parse().unwrap(),
                k: k.parse().unwrap(),
            }
        });
        let classes = std::env::var("MIDOUT_CLASSES")
            .ok()
            .map(|c| c.parse().unwrap());
        let again = std::env::var("AUDIT_AGAIN").map_or(true, |x| x != "0");
        on_wide_device!(|c| wide_faults(c, b, &pips, sh, classes, again));
    }

    /// The parents' root pass shared across the slice's top digit (`set_parent_sharing`): the first
    /// `MIDOUT_SHARE_SLICES` (130) slices of a base-65 `(4, 8, 5)` field (65 values of digit 4 × 2 of digit 8:
    /// every shared list serves two slices), one slice per group, give every slice's counts (kept included: same
    /// key) equal with and without sharing; with sharing on, each fault is loud (`F_SKIP_ANC` new; `F_SKIP_MAIN`,
    /// `F_SKIP_TOPS`, `F_DROP_PROBE`, `F_DROP_PARENT` as without sharing), and a clean run after each gives the
    /// clean counts. `MIDOUT_485_T` the field (77777), `MIDOUT_CLASSES` the batch width.
    #[cfg(feature = "midout-box-tests")]
    #[test]
    #[ignore = "needs a GPU (MIDOUT_CUDA=1 for the CUDA runtime)"]
    fn wide_field_parent_sharing_is_exact_and_loud() {
        let b = 65u32;
        let tn: u128 = std::env::var("MIDOUT_485_T")
            .ok()
            .map_or(77_777, |s| s.parse().unwrap());
        let nsl: usize = std::env::var("MIDOUT_SHARE_SLICES")
            .ok()
            .map_or(130, |s| s.parse().unwrap());
        let classes: Option<u32> = std::env::var("MIDOUT_CLASSES")
            .ok()
            .map(|s| s.parse().unwrap());
        fn go<R: Runtime>(
            client: ComputeClient<R>,
            b: u32,
            tn: u128,
            nsl: usize,
            classes: Option<u32>,
        ) {
            let cn = Coord::with_digits(b, 4, 8, 5).unwrap();
            let sh = Shape::for_coord(&cn);
            let (q, vs) = (cn.quantum(), cn.start() + tn * cn.quantum());
            let mut caps = WideCaps::for_base(b);
            if let Some(c) = classes {
                caps.classes = c.min(b - 1);
            }
            let mut gj = WideJoin::new(client, caps, &cn, sh).unwrap();
            let opt1 = WideOptions {
                group: 1,
                cpu_check: false,
                cpu_threads: 0,
            };
            let opt16 = WideOptions { group: 16, ..opt1 };
            gj.set_parent_sharing(false);
            let (o0, r0) = search_field_wide_groups(&gj, &cn, vs, q, opt1, 0..nsl).unwrap();
            gj.set_parent_sharing(true);
            let u0 = gj.anc.lock().expect("anc").used;
            let (o1, r1) = search_field_wide_groups(&gj, &cn, vs, q, opt1, 0..nsl).unwrap();
            let u1 = gj.anc.lock().expect("anc").used;
            // used, not only built: every slice's whist ran over its key's list, shorter than the roots
            assert_eq!(
                (u1.0 - u0.0, u1.1 - u0.1),
                (nsl as u64, nsl as u64),
                "slices through a shared list shorter than the roots"
            );
            let (nl, listed) = gj.parent_sharing_last();
            let lmax = gj
                .anc
                .lock()
                .expect("anc")
                .lens
                .iter()
                .copied()
                .max()
                .unwrap_or(0);
            println!(
                "{nsl} slices of base-{b} (4, 8, 5) field {tn}: {nl} shared lists, {listed} roots listed ({:.1} % of {} per list, longest {lmax}, capacity {})",
                100.0 * listed as f64 / (nl as f64 * f64::from(gj.nrf)),
                gj.nrf,
                gj.anc_cap
            );
            assert!(nl >= 1 && nl < nsl);
            assert_eq!(r0.len(), r1.len());
            for ((p0, c0), (p1, c1)) in r0.iter().zip(&r1) {
                assert_eq!(p0, p1);
                assert_eq!(
                    c0, c1,
                    "slice {p0:?}: shared parents differ: {c0:?} vs {c1:?}"
                );
            }
            assert_eq!(
                (o0.survivors, o0.checked, o0.slices, &o0.nice),
                (o1.survivors, o1.checked, o1.slices, &o1.nice)
            );
            println!(
                "equal slice by slice with and without sharing: survivors {}, checked {}",
                o1.survivors, o1.checked
            );
            for (name, f) in [
                ("F_SKIP_ANC", F_SKIP_ANC),
                ("F_ANC_SPLIT", F_ANC_SPLIT),
                ("F_SKIP_MAIN", F_SKIP_MAIN),
                ("F_SKIP_TOPS", F_SKIP_TOPS),
                ("F_DROP_PROBE", F_DROP_PROBE),
                ("F_DROP_PARENT", F_DROP_PARENT),
            ] {
                gj.set_fault(f);
                let r = search_field_wide_groups(&gj, &cn, vs, q, opt16, 0..nsl);
                gj.set_fault(0);
                match r {
                    Ok((o, _)) => panic!(
                        "{name}: silent (survivors {}, checked {})",
                        o.survivors, o.checked
                    ),
                    Err(e) => println!("{name}: loud: {e:#}"),
                }
                let (oc, _) = search_field_wide_groups(&gj, &cn, vs, q, opt16, 0..nsl).unwrap();
                assert_eq!(
                    (oc.survivors, oc.checked),
                    (o1.survivors, o1.checked),
                    "{name}: clean rerun"
                );
            }
            // a wrong shared list whose own counts are consistent (F_ANC_DROP) passes every account; the sampled
            // check's comparison of the field run's survivors with the CPU's must catch it (its device rerun is
            // unshared, so it would not)
            let optc = WideOptions {
                cpu_check: true,
                ..opt16
            };
            gj.set_fault(F_ANC_DROP);
            let r = search_field_wide_groups(&gj, &cn, vs, q, optc, 0..nsl);
            gj.set_fault(0);
            match r {
                Ok((o, _)) => panic!(
                    "F_ANC_DROP: silent (survivors {}, checked {})",
                    o.survivors, o.checked
                ),
                Err(e) => {
                    let m = format!("{e:#}");
                    println!("F_ANC_DROP: loud: {m}");
                    assert!(
                        m.contains("the field run counted survivors"),
                        "F_ANC_DROP: loud, but not by the sampled check's field-run comparison"
                    );
                }
            }
            let (oc, _) = search_field_wide_groups(&gj, &cn, vs, q, optc, 0..nsl).unwrap();
            assert_eq!(
                (oc.survivors, oc.checked),
                (o1.survivors, o1.checked),
                "F_ANC_DROP: clean rerun with the sampled check"
            );
            println!("clean rerun with the sampled check: equal");
        }
        on_wide_device!(|c| go(c, b, tn, nsl, classes));
    }

    /// On the wide path: a failed device allocation (`AUDIT_FILL_MB` filled first, in
    /// process) must not return a slice as searched. Base 65 slice 717171717 (16,482,926 survivors).
    #[cfg(feature = "midout-box-tests")]
    #[test]
    #[ignore = "needs CUDA; fills the card's memory"]
    #[cfg(feature = "cubecl-cuda")]
    fn wide_oom_is_loud() {
        let client = wcuda_client();
        let fill_mb: u64 = std::env::var("AUDIT_FILL_MB").map_or(0, |x| x.parse().unwrap());
        let mut hold = Vec::new();
        for _ in 0..fill_mb / 64 {
            hold.push(client.empty(64 << 20));
        }
        let _ = cubecl::future::block_on(client.sync());
        println!("filled {} MiB", 64 * hold.len());
        let coord = Coord::with_digits(65, 0, 1, 0).unwrap();
        let gj = match WideJoin::new(
            client,
            WideCaps::for_base(65),
            &coord,
            Shape { f0: 4, k: 10 },
        ) {
            Ok(g) => g,
            Err(e) => {
                println!("WideJoin::new failed (loud): {e}");
                return;
            }
        };
        println!("WideJoin::new returned Ok");
        let pip = 717_171_717u64;
        let r = gj.rank_of(pip).and_then(|rank| wgroup(&gj, &rank, &[pip]));
        drop(hold);
        match r {
            Ok(dc) => {
                println!("group path returned Ok: {dc:?}");
                assert_eq!(
                    dc.survivors, 16_482_926,
                    "an allocation failure returned a slice as searched"
                );
            }
            Err(e) => println!("group path LOUD: {e}"),
        }
    }

    /// On the wide path's field driver with the shared parent lists: a failed device allocation (`AUDIT_FILL_MB`
    /// filled first, in process, after the join's own buffers) must not return the field's slices as searched.
    /// The first `MIDOUT_SHARE_SLICES` (130) slices of base-65 field 77777 (`MIDOUT_485_T`) with the card filled,
    /// then again after the fill is freed: an `Ok` under the fill must equal the clean run.
    #[cfg(feature = "midout-box-tests")]
    #[test]
    #[ignore = "needs CUDA; fills the card's memory"]
    #[cfg(feature = "cubecl-cuda")]
    fn wide_field_oom_is_loud() {
        let client = wcuda_client();
        let fill_mb: u64 = std::env::var("AUDIT_FILL_MB").map_or(0, |x| x.parse().unwrap());
        let tn: u128 = std::env::var("MIDOUT_485_T")
            .ok()
            .map_or(77_777, |s| s.parse().unwrap());
        let nsl: usize = std::env::var("MIDOUT_SHARE_SLICES")
            .ok()
            .map_or(130, |s| s.parse().unwrap());
        let cn = Coord::with_digits(65, 4, 8, 5).unwrap();
        let sh = Shape::for_coord(&cn);
        let (q, vs) = (cn.quantum(), cn.start() + tn * cn.quantum());
        let gj = match WideJoin::new(client.clone(), WideCaps::for_base(65), &cn, sh) {
            Ok(g) => g,
            Err(e) => {
                println!("WideJoin::new failed (loud): {e}");
                return;
            }
        };
        let mut hold = Vec::new();
        for _ in 0..fill_mb / 64 {
            hold.push(client.empty(64 << 20));
        }
        let _ = cubecl::future::block_on(client.sync());
        println!(
            "WideJoin::new returned Ok; then filled {} MiB",
            64 * hold.len()
        );
        let opt = WideOptions {
            group: 16,
            cpu_check: false,
            cpu_threads: 0,
        };
        let r = search_field_wide_groups(&gj, &cn, vs, q, opt, 0..nsl);
        let built = gj.parent_sharing_last();
        drop(hold);
        let _ = cubecl::future::block_on(client.sync());
        match r {
            Ok((o, _)) => {
                println!(
                    "field path returned Ok under the fill ({} lists built): {o:?}",
                    built.0
                );
                let (oc, _) = search_field_wide_groups(&gj, &cn, vs, q, opt, 0..nsl).unwrap();
                assert_eq!(
                    (o.survivors, o.checked, o.slices),
                    (oc.survivors, oc.checked, oc.slices),
                    "an allocation failure returned slices as searched"
                );
                println!("equal to the clean run after the fill was freed");
            }
            Err(e) => println!("field path LOUD: {e:#}"),
        }
    }

    /// On the wide path: a join with a timing stop is refused by `search_field_wide` before any work (base 40,
    /// shape (3, 6), 4 classes per batch: small enough for any device).
    #[test]
    #[ignore = "needs a GPU (lavapipe will do; MIDOUT_CUDA=1 for CUDA)"]
    fn cubecl_midout_wide_timing_stop_is_refused() {
        fn go<R: Runtime>(client: ComputeClient<R>) {
            let coord = Coord::with_digits(40, 0, 1, 0).unwrap();
            let mut caps = WideCaps::for_base(40);
            caps.classes = 4;
            let mut gj = WideJoin::new(client, caps, &coord, Shape { f0: 3, k: 6 }).unwrap();
            assert_eq!(gj.stop, 6, "a new join has no timing stop");
            gj.set_timing_stop(2);
            let opt = WideOptions {
                group: 16,
                cpu_check: false,
                cpu_threads: 0,
            };
            match search_field_wide(&gj, &coord, coord.start(), coord.quantum(), opt) {
                Ok((o, _, _)) => panic!("timing stop 2: search_field_wide returned Ok: {o:?}"),
                Err(e) => println!("timing stop 2: search_field_wide refused: {e}"),
            }
        }
        on_wide_device!(go);
    }

    /// A real base-65 slice against a staged reference from an independent
    /// implementation of the join (outside this repository): every unit's
    /// survivor set and every unit's top count, from the files in `MIDOUT_SU_DIR`.
    #[cfg(feature = "midout-box-tests")]
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
                let mut gj = WideJoin::new($client, caps, &coord, Shape { f0, k }).unwrap();
                gj.set_fault(F_NOPF);
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

    /// The WGSL of every base-65 kernel for CI's Apple-division lint (`scripts/wgsl-lint.py`, beside
    /// `cubecl_backend::tests::wgsl_dump_for_lint`); does nothing unless `CUBECL_DEBUG_LOG` is set. The client
    /// route's join (`WideCaps::for_base(65)`, the base's coordinate and shape), 4 classes per batch, one slice's
    /// first batch, compiled for the device's plane width and for widths 32 and 64 (the compile-only path where
    /// the device's differs). Nothing is checked: only the batch runs, so the slice's accounts fail (and under a
    /// forced width the plane checks too), which the output shows.
    #[test]
    #[ignore = "requires a wgpu device"]
    fn wgsl_dump_for_lint() {
        if std::env::var_os("CUBECL_DEBUG_LOG").is_none() {
            println!("CUBECL_DEBUG_LOG is not set; no shaders to dump");
            return;
        }
        // irrefutable without the CUDA or HIP runtime
        #[allow(irrefutable_let_patterns)]
        let crate::cubecl_backend::CubeclContext::Wgpu { client, .. } =
            crate::cubecl_backend::CubeclContext::new_default().expect("CubeCL init")
        else {
            panic!("not a wgpu device");
        };
        let coord = Coord::for_base(65).unwrap();
        let sh = Shape::for_coord(&coord);
        let pip = 717_171_717u64;
        let dev_w = client.properties().hardware.plane_size_max;
        let mut widths = vec![None];
        widths.extend([32u32, 64].into_iter().filter(|&w| w != dev_w).map(Some));
        for force_w in widths {
            let mut caps = WideCaps::for_base(65);
            // runtime sizes only (no comptime value), cut so that every binding fits lavapipe's 128 MiB at W 8
            (caps.classes, caps.survivors, caps.parents) = (4, 20_000_000, 2_000_000);
            let mut gj = WideJoin::with_width(client.clone(), caps, &coord, sh, force_w).unwrap();
            gj.batches.truncate(1);
            // the shared parent lists' kernel (`wanc`; one key)
            let ra = gj.build_anc(&[gj.anc_key(pip)]);
            println!("W {} base 65 slice {pip}: wanc {:?}", gj.w, ra.err());
            let r = gj
                .rank_of(pip)
                .and_then(|rank| gj.run_slice(pip, &rank))
                .map(|x| x.0);
            println!("W {} base 65 slice {pip}: {:?}", gj.w, r.err());
        }
    }
}
