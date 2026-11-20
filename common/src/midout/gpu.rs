//! The device path of the middle-out join (CubeCL: CUDA, and Vulkan through
//! SPIR-V or WGSL), base 64, shape (4, 10), `u64` masks.
//!
//! # Stages of a slice, and what each one proves
//!
//! A slice is one value `pip` of digits 4–8 of n (30 bits). Its stages are
//! queued on one stream without a synchronisation; the host reads the
//! device's counters once per group of slices (`finish_group`) and compares
//! every account word (`A_*`, below) with what it queued (`check_slice`).
//!
//! | stage | kernels | hands the next stage | account (compared with) |
//! |---|---|---|---|
//! | tops | `tops5` (once per 64 slices), `tops1`, `tscan`, `tops2`, `tdigz2`, `toprec2` | tops by segment (`tmask`, `thd`, `tmhi`, `tseg`), probe digits (`tdig`), production's top records | `A_T1_EXAM` (= the 64-slice level's count), `A_T1_CERT`, `A_T2_PLACED`, `A_TDIG`, `A_TREC` (each = the tops certified), `A_TSCAN` (= 1) |
//! | parents | `anc8` (when shared, once per value of digits 4–7), `hist2`, `scan16`, `scatter3`, `hsort` | parent records sorted by (class, key), `pseg` | `A_H2_CUBES` (= its grid), `A_H2_CERT` and `A_SCAT` (= the list length), `A_SCAN16` (= 1), `A_HSORT` (= 16,128), `A_SC_CHILD` (= the main kernel's children) |
//! | main kernel, per batch of classes | `g2_kernel` | records (slabs), child lists | `A_JOBS` (= instances queued), `A_PROBES` (= 8 × tops), `A_CHILD` (= `A_SC_CHILD`) |
//! | expansion, per batch | `expand_kernel` | survivor entries `(top, r0)` that pass the middle-digit prefilter | its `stat` words: cubes done (= its grid), slabs walked (= slabs used), bits read (= the main kernel's survivors) |
//! | full check, per batch | production's `cubecl_join::check_kernel`, unchanged | nice numbers | its `ran` words (production's own: entries checked = the list) |
//! | done | `done_kernel` | the slice's done word | `A_DONE` (= 1) and the group's `C_SLICES` (= slices queued) |
//!
//! Every account word starts at 0 and none may stay 0 for a stage that ran,
//! so a launch that did not run, a dropped stage or a failed allocation is an
//! error, not an empty slice. The two conservation laws tie the stages
//! together: the children the main kernel saw equal the children `scatter3`
//! listed, and the survivor bits the expansion read equal the bits the main
//! kernel wrote. What no account can see (a wrong certificate, a wrong child
//! mask, a false common-mask skip, a too-strict prefilter: work that ran and
//! computed wrongly) is what the sampled CPU check exists for
//! ([`GpuOptions::cpu_check`]).
//!
//! # Data layouts
//!
//! - **Parent record** (`par`, one `Vector<u32, 4>`): `[mask lo, mask hi,
//!   cacc, r4]`. `mask` is the 64-bit digit mask of the parent's r² and r³
//!   digits; `r4` its residue mod 64^4 (24 bits); `cacc = c2 | c3 << 8 | a2 <<
//!   16 | a3 << 24` (6-bit fields): the child of unit `d` adds digits `(c2 +
//!   a2·d) mod 64` and `(c3 + a3·d) mod 64` (`child_mask`). Records are sorted
//!   by class `c` and key; `pseg[c] .. pseg[c + 1]` is class `c`.
//! - **Top**: `thd = h | d << 16` (lead `h` in `[2^15, 2^16)`, unit `d`),
//!   `tmask` its certified digits, `tmhi` the certificate's digits at
//!   positions ≥ 12 (the prefilter's); sorted into segments `tseg[(d·63 +
//!   ct)·2] .. [+1]` by (unit, `h mod 63`). `tdig` holds each top's digits as
//!   20 6-bit fields, 5 per word in 4 words, padded with its first digit (OR
//!   is idempotent); at most `MAXPOP` = 17 are read.
//! - **Production's top record** (`TOP_REC_WORDS` = 8 words per top):
//!   `P = n div 64^5` in words 0–1 and `w6 = P mod 64^5` in word 6
//!   (`toprec_kernel`), as `check_kernel` reads them.
//! - **Job** (`jobs`, two words): `[c, d | poff << 8]`: class `c`, unit `d`
//!   (8 bits), `poff` the job's first probe (0, or `PMAX` for the second
//!   instance of a job with more than `PMAX` probes).
//! - **Probe** (the main kernel's shared `prob_d`, one `Vector<u32, 4>`): the
//!   top's `tdig` words, with bits 12–31 of word 3 replaced by the top's index
//!   (digits 15–16 stay in bits 0–11; a top index must fit 20 bits, checked by
//!   the host).
//! - **Child list** (`clst`, one word per child: its `r4`): per batch, job
//!   `(c, d)` writes its certified children in order from position
//!   `64·(pseg[c] − pseg[c0]) + d·(pseg[c + 1] − pseg[c])`, `c0` the batch's
//!   first class; a position past the list is an error (`C_ERR_CLST`).
//! - **Record** (`out`, one `Vector<u32, 4>`): `[top index, child-list
//!   position of the chunk's first child, word lo, word hi]`: bit `b` of the
//!   64-bit word is the pair (this top, the chunk's child `b`), a survivor of
//!   the join. Records go to plane-private slabs of `SLAB` = 256
//!   (`slabcnt[s]` records in slab `s`, `slabn[0]` slabs used).
//! - **Survivor entry** (`surv`, two words, production's survivor-list
//!   layout): `[top index, r0]`, `r0 = n mod 2^30` = the child's `r4` plus
//!   digit 4 of the slice (`r0hi`), so `n = P·64^5 + r0`.
//! - **Counters** (`cnt`, `NCNT` words, per group): 64 units × 5 words
//!   (children, chunks, flat pairs, kept chunks, survivors), then the error
//!   words `C_ERR_*` and the slice count `C_SLICES`.
//! - **Account** (`acc`, `ACC_WORDS` words, one buffer per slice): the `A_*`
//!   words of the table above, `A_ERR_PLANE` (a kernel ran on planes of
//!   another width) last.

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

use super::coord::Coord;
use super::cpu::{FieldOutcome, Shape, key_digits};
// production's full check, its grid and its `ran` words (4 stage counters, the work counter, entries checked, their
// index sum, the top account), shared rather than copied so that a change there cannot desynchronise this path
use crate::cubecl_join::{
    CHECK_CUBES, JOIN_WG as CHECK_WG, RAN_WORDS, TOP_REC_WORDS, ballot_append, check_kernel,
};
use crate::join_check::{CheckShape, GATE_DIGITS};
use anyhow::{Result, anyhow, bail, ensure};
use cubecl::prelude::*;
use cubecl::server::Handle;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::{Mutex, mpsc};
use std::time::Instant;

const M: u32 = 63;
const NROOT: usize = 8;
const ROOTS: [u32; NROOT] = [0, 6, 21, 27, 35, 42, 48, 62];
const MASK60: u64 = (1u64 << 60) - 1;
/// Threads per cube.
const NT: u32 = 256;
/// Children per round: 16 full chunks.
const FILL: u32 = 1024;
/// Probe table rows (the kernel's shared memory): a job's probes must fit.
pub const PMAX: u32 = 576;
/// Digits of a top mask the kernel reads: a top's popcount must fit.
///
/// 17 is the most a top can certify at base 64:
/// a top's interval is 2^24 n wide with n >= 2^75, so over it n² moves by
/// at least 2^100 > 64^16 and n³ by at least 3·2^174 > 64^29; only digits
/// 17–25 of n² (9) and 30–37 of n³ (8) can agree at both ends. Every slice
/// seen has a 17-digit top, so the margin is 0 and none is needed. This
/// does not hold for other bases (the wide path must redo it).
pub const MAXPOP: u32 = 17;
/// Records per plane-private output slab.
const SLAB: u32 = 256;
/// Slice words in shared memory.
const SLW: u32 = 2080;
/// Counter layout: 64 units × 5 (children, chunks, flat, kept, surv), then extras.
const C_LSLOTS: usize = 320;
const C_ERR_PLANE: usize = 321;
const C_ERR_PMAX: usize = 322;
const C_ERR_SLAB: usize = 323;
/// A class of more than 65,536 parents (the pending parent index is 16 bits).
const C_ERR_IDX: usize = 324;
/// A child-list position past the batch's list (the write is skipped).
const C_ERR_CLST: usize = 325;
/// Slices whose last kernel ran (`done_kernel`): the host counts slices from this word.
const C_SLICES: usize = 326;
const NCNT: usize = 328;
/// Per-slice account (`acc`, one buffer per slice): what every stage ran, compared by the host with what it queued
/// (`GpuJoin::check_slice`). Every word starts at 0, and no word may stay 0 for a slice whose stage ran.
/// `tops1`: valid parents examined (= the 64-slice level's `l5n[0]`) and tops certified (= `tstat[0]`).
const A_T1_EXAM: usize = 0;
const A_T1_CERT: usize = 1;
/// `tscan` ran (1).
const A_TSCAN: usize = 2;
/// `tops2`: tops placed (= `tstat[0]`); `tdigz2`, `toprec2`: rows written (= `tstat[0]`).
const A_T2_PLACED: usize = 3;
const A_TDIG: usize = 4;
const A_TREC: usize = 5;
/// `hist2`: cubes done (= its grid) and parents certified, counted apart from the list (= `lcnt`).
const A_H2_CUBES: usize = 6;
const A_H2_CERT: usize = 7;
/// `scan16` ran (1); `scatter3`: rows moved (= `lcnt`) and the listed parents' certified children (= the main
/// kernel's children); `hsort`: cubes done (= 16,128).
const A_SCAN16: usize = 8;
const A_SCAT: usize = 9;
const A_SC_CHILD: usize = 10;
const A_HSORT: usize = 11;
/// Main kernel: job instances that reached their end (= the instances queued), probes run (= 8 × tops: every top
/// is a probe of one job per root) and children seen (= `A_SC_CHILD`).
const A_JOBS: usize = 12;
const A_PROBES: usize = 13;
const A_CHILD: usize = 14;
/// The slice's last kernel ran (1).
const A_DONE: usize = 15;
/// A kernel ran with planes of another width than it was compiled for, or partly filled.
const A_ERR_PLANE: usize = 16;
const ACC_WORDS: usize = 20;
/// The expansion's `stat` words: list length (parents), slabs, survivor bits read, cubes done, slabs walked.
const STAT_WORDS: usize = 5;
/// Grid of the record expansion (a grid-stride loop over the used slabs).
const EXPAND_CUBES: u32 = 4096;
/// Grid of the per-slice top kernels (a grid-stride loop over the valid parents).
const TOPS_CUBES: u32 = 1024;
/// Nice numbers a group may report.
const NICE_CAP: u32 = 4096;
/// Production's nice-output stride (four words per n).
const NICE_STRIDE: usize = 4;

// ------------------------------------------------------------------------------------------------ device
/// The main kernel (`g2_kernel`) and its plane helpers: per job (class, unit) of a batch, the children of the
/// class's parents in 64-child chunks against the unit's probes; writes records, child lists and the main kernel's
/// account words (see the module's data layouts).
// CubeCL's comptime branches assign a variable declared before them (`let mut x = ..; if comptime!(..) { x = .. }
// else { x = .. }`): rustc sees the declaration's value as never read.
#[allow(unused_assignments)]
mod kernels {
    use super::{
        A_CHILD, A_JOBS, A_PROBES, C_ERR_CLST, C_ERR_IDX, C_ERR_PLANE, C_ERR_PMAX, C_ERR_SLAB,
        C_LSLOTS, M, MAXPOP, NT, PMAX, SLAB, SLW,
    };
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

    /// Exclusive rank of this lane's flag in its plane, by a ballot and population counts. `lo` and `hi` are the
    /// lane's ballot masks below it (bits `[0, lane)` of the ballot's two words), made once by the caller outside
    /// its loops (ACO recomputed them in every step otherwise). The ballot's second word only when W = 64.
    #[cube]
    fn plane_rank_m(flag: bool, lo: u32, hi: u32, #[comptime] w: u32) -> u32 {
        let b = plane_ballot(flag);
        let mut r = (b[0usize] & lo).count_ones();
        if comptime!(w > 32) {
            r += (b[1usize] & hi).count_ones();
        }
        r
    }

    /// Lanes of the plane whose flag is set, by a ballot (its second word only when W = 64).
    #[cube]
    fn plane_count(flag: bool, #[comptime] w: u32) -> u32 {
        let b = plane_ballot(flag);
        let mut n = b[0usize].count_ones();
        if comptime!(w > 32) {
            n += b[1usize].count_ones();
        }
        n
    }

    #[cube]
    pub fn child_mask(pm: u64, cacc: u32, d: u32) -> u64 {
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

    /// One cube per job (class c, unit d). `w` is the plane width the kernel is compiled for (8, 32 or 64; a plane
    /// of another width is an error, `C_ERR_PLANE`), `fill` the children appended per round (`FILL`, or 512 below
    /// 32 lanes).
    ///
    /// Its phases (the comments `phase 1` … `phase 4` in the body): the probes (the 8 top classes compatible with
    /// unit `d`, their digit words into shared memory, once); then rounds until the class's parents are used up:
    /// **1** append the certified children of 256 parents at a time, in order, to the pending slots and the job's
    /// child list, until `fill` children (16 chunks of 64 at 32 lanes and above) are pending; **2** transpose the round's chunks into per-digit slices (a
    /// shuffle transpose per plane) and take each chunk's common digits from the registers; **3a** per probe, the
    /// chunks the common-mask skip keeps, into a list; **3b** per (probe, chunk) of the list, the 64-pair word
    /// (pairs whose masks are disjoint), one record per nonzero word into the plane's slab; **4** carry the
    /// pending rest to the front. At the end, the counters and the account words.
    #[cube(launch_unchecked)]
    pub fn g2_kernel(
        par: &Array<Vector<u32, Const<4>>>, // parent records (mask lo, mask hi, cacc, r4), one 16-byte vector each (one LDG.128 on CUDA)
        pseg: &Array<u32>,
        tdig: &Array<u32>, // each top's digits, 20 6-bit fields in 4 words (`tdigz2_kernel`; `tdigz_kernel` on the host-tops path), once per slice
        tseg: &Array<u32>,
        roots: &Array<u32>,
        jobs: &Array<u32>,
        cnt: &mut Array<Atomic<u32>>,
        out: &mut Array<Vector<u32, Const<4>>>, // survivor records, one 16-byte vector each (one STG.128 on CUDA)
        slabn: &mut Array<Atomic<u32>>,
        slabcnt: &mut Array<u32>,
        nslab_cap: u32,
        // each job's certified children's r4 in order, at
        // 64·(pseg[c] − pseg[c0]) + d·(class size) + position (written by phase 1)
        clst: &mut Array<u32>,
        c0: u32,
        // fault-injection bits, 0 in production: F_PMAX (4) probe window 300 instead of PMAX,
        // F_DROP_PROBE (8) each job's last probe not run, F_IDX13 (16) the pending parent index read as 13 bits,
        // F_DROP_REC (32) cube 0 never stores its second record of a step
        fault: u32,
        // the slice's account (`A_*`) and the child list's length
        acc: &mut Array<Atomic<u32>>,
        lcap: u32,
        #[comptime] w: u32,
        #[comptime] fill: u32,
    ) {
        let npl = comptime!(NT / w);
        let segs = comptime!(64 / w); // ballot segments per chunk (W <= 64)
        // pending children as u16 (parent index - class start) two per word, and the round's probe list (u32
        // entries) in the same words: the list is live only in 3a/3b, when the pending slots still needed (each
        // chunk's first, the carried rest) are already in registers. 12 waves per SIMD on RDNA4 need <= 21 KB.
        let mut pq = SharedMemory::<u32>::new(comptime!(
            (if (fill + NT) / 2 > PMAX + 32 {
                (fill + NT) / 2
            } else {
                PMAX + 64
            }) as usize
        ));
        // slices [(v + 65 q)*2 + half] (SROW = 65: the 3b address is one add and one shift of the digit, and a 16-lane group's
        // reads still fall on 16 distinct 8-byte bank pairs, (v + q) mod 16)
        let mut sl = SharedMemory::<u32>::new(comptime!((SLW) as usize));
        // every shared array a multiple of 128 bytes, so that every array starts 128-byte aligned whatever order
        // CubeCL places them in (its placement changed per build, and the full kernel's time with it)
        let slt =
            SharedMemory::<Atomic<u32>>::new(comptime!((if w < 32 { SLW } else { 32 }) as usize));
        let comm = SharedMemory::<Atomic<u32>>::new(32usize); // [2q + half]
        // each probe's 4 digit words as one 16-byte vector (one LDS.128 / ds_read_b128 per list entry)
        let mut prob_d = SharedMemory::<Vector<u32, Const<4>>>::new(comptime!(PMAX as usize));
        let mut wcnt = SharedMemory::<u32>::new(comptime!(
            (if 2 * NT / w < 32 { 32 } else { 2 * NT / w }) as usize
        ));
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
        // the job word is d | poff << 8, poff the job's first probe (0, or PMAX for the
        // job's second instance, which runs only if the job has more than PMAX probes)
        let dj = jobs[(2u32 * CUBE_POS_X + 1u32) as usize];
        let d = dj & 255u32;
        let poff = dj >> 8u32;
        let cc = (c + d) % M;
        let pmx = select((fault & 4u32) != 0u32, 300u32, PMAX);

        if PLANE_DIM != w || t % w != lane {
            cnt[C_ERR_PLANE].fetch_add(1u32);
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
            if poff > 0u32 && n > poff + pmx {
                cnt[C_ERR_PMAX].fetch_add(1u32);
            }
        }
        // the common masks start all-ones: phase 2 ANDs each plane's ballot into them
        if t < 32u32 {
            comm[t as usize].store(u32::MAX);
        }
        sync_cube();
        // probes: the 8 compatible top classes of unit d, each probe's digits as 20 6-bit fields (5 per word),
        // padded with its first digit (OR is idempotent)
        {
            let mut base = 0u32;
            for i in 0..8u32 {
                let ct = (roots[i as usize] + M - cc) % M;
                let s = (d * M + ct) * 2u32;
                let b0 = tseg[s as usize];
                let b1 = tseg[(s + 1u32) as usize];
                let mut j = t;
                while j < b1 - b0 {
                    if base + j >= poff && base + j < poff + pmx {
                        let mut pv = Vector::<u32, Const<4>>::empty();
                        #[unroll]
                        for k in 0..4u32 {
                            pv[k as usize] = tdig[((b0 + j) * 4u32 + k) as usize];
                        }
                        // the top's index in word 3's bits 12-31 (digits 15-16 are bits 0-11)
                        pv[3usize] = (pv[3usize] & 0xFFFu32) | ((b0 + j) << 12u32);
                        prob_d[(base + j - poff) as usize] = pv;
                    }
                    j += NT;
                }
                base += b1 - b0;
            }
        }
        sync_cube();
        let mut nprobe = min(s_np[0usize] - min(s_np[0usize], poff), pmx);
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
        let mut slab_used = 256u32; // = SLAB (a literal: a const would be a comptime value); full: the first record allocates
        let mut have_slab = false;

        let pb = pseg[c as usize];
        let pe = pseg[(c + 1u32) as usize];
        let mut cur = pb;
        let mut npend = 0u32;
        let mut parity = 0u32;
        // no `loop`/`break`: cubecl-spirv 0.10 emitted a conditional branch without OpSelectionMerge for them
        let mut going = nprobe > 0u32 || poff == 0u32;
        // the job's child list and the position of the round's first pending child in it
        let lb = 64u32 * (pb - pseg[c0 as usize]) + d * (pe - pb);
        // here, not at the end, so that none of these values stays live through the rounds (registers):
        // the probes this instance runs (the host's law: 8 x tops over all instances), the pending parent index
        // (`pq`, `idx - pb`) within 16 bits, the job's child list [lb, lb + (pe - pb)) inside the batch's
        if t == 0u32 {
            acc[A_PROBES].fetch_add(nprobe);
            if pe - pb > 65536u32 {
                cnt[C_ERR_IDX].fetch_add(1u32);
            }
            if lb + (pe - pb) > lcap {
                cnt[C_ERR_CLST].fetch_add(1u32);
            }
        }
        let mut cdone = 0u32;
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
                let mut r4v = 0u32;
                if idx < pe {
                    let pv = par[idx as usize];
                    r4v = pv[3usize];
                    m = child_mask(
                        u64::cast_from(pv[0usize]) | (u64::cast_from(pv[1usize]) << 32u64),
                        pv[2usize],
                        d,
                    );
                }
                let r = plane_rank_m(m != 0u64, rlo, rhi, w);
                let tot = plane_count(m != 0u64, w);
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
                    while z < 2080u32 {
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
                        let pi = pb
                            + ((pq[(mi >> 1u32) as usize] >> ((mi & 1u32) << 4u32))
                                & select((fault & 16u32) != 0u32, 0x1FFFu32, 0xFFFFu32));
                        let pv = par[pi as usize];
                        m = child_mask(
                            u64::cast_from(pv[0usize]) | (u64::cast_from(pv[1usize]) << 32u64),
                            pv[2usize],
                            d,
                        );
                    }
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
                    if q < nch {
                        // common masks from the registers (no pass over the slices): digit v is common to the
                        // chunk iff, in every plane of it, the column holds all of that plane's valid rows
                        let nv = min(w, ntake - min(ntake, q * 64u32 + sg * w));
                        // valid rows as a u64, built from u32 shifts (a variable 64-bit shift crashed lavapipe's
                        // 512-bit JIT)
                        let vlo =
                            select(nv >= 32u32, 0xFFFF_FFFFu32, (1u32 << min(nv, 31u32)) - 1u32);
                        let vhi = select(
                            nv >= 64u32,
                            0xFFFF_FFFFu32,
                            select(
                                nv > 32u32,
                                (1u32 << ((nv - min(nv, 32u32)) & 31u32)) - 1u32,
                                0u32,
                            ),
                        );
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
                                let piece =
                                    (hv >> comptime!((sb * w) % 32)) & comptime!((1u32 << w) - 1);
                                slt[(row + bit / 32u32) as usize].fetch_or(piece << (bit % 32u32));
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
                // the record's chunk q = t % 16 starts at child cdone + 64·q of the job's list
                let cpos = cdone + (t % 16u32) * 64u32;
                sync_cube();
                if comptime!(w < 32) {
                    let mut z = t;
                    while z < 2080u32 {
                        sl[z as usize] = slt[z as usize].load();
                        z += NT;
                    }
                    sync_cube();
                }
                // (this barrier guarded a pass over the slices that the shuffle transpose made unnecessary; kept so
                // that the generated code stays byte-identical to the audited kernel's)
                sync_cube();
                {
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
                {
                    // phase 3a: per probe, its 16-bit mask of chunks kept by the common-mask skip -> list
                    let allq = (1u32 << nch) - 1u32; // nch <= 16
                    let mut pp = t;
                    while pp < nprobe {
                        let mut km = allq;
                        {
                            let mut hitm = 0u32;
                            let pv = prob_d[pp as usize];
                            #[unroll]
                            for k in 0..MAXPOP {
                                let dg = (pv[comptime!(k / 5) as usize] >> comptime!(6 * (k % 5)))
                                    & 63u32;
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
                    let vhi = select(
                        nq == 64u32,
                        0xFFFF_FFFFu32,
                        select(nq > 32u32, (1u32 << (nq % 32u32)) - 1u32, 0u32),
                    );
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
                        for h in 0..2u32 {
                            // branch-free: an entry past the list reads as 0 (probe 0, no chunk kept), and a lane whose
                            // chunk is not kept computes its word and masks it (a wave skipped only when all 64 lanes
                            // were idle, which is rare; the branches cost more than they saved). e < nlist + 31 <= pq's size.
                            let e = e0 + st + comptime!(16 * h);
                            let ent = select(e < nlist, pq[e as usize], 0u32);
                            let p16 = ent & 0xFFFFu32;
                            let kmask = 0u32 - ((ent >> qs) & 1u32);
                            let mut alo = 0u32;
                            let mut ahi = 0u32;
                            let dws = prob_d[(p16 >> 4u32) as usize];
                            // the record names its top, not its probe slot
                            pk[h as usize] = dws[3usize] >> 12u32;
                            #[unroll]
                            for k in 0..MAXPOP {
                                let dg = (dws[comptime!(k / 5) as usize] >> comptime!(6 * (k % 5)))
                                    & 63u32;
                                let row = (dg + q65) * 2u32;
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
                        {
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
                                        rv[0usize] = pk[0usize];
                                        rv[1usize] = lb + cpos;
                                        rv[2usize] = wlo[0usize];
                                        rv[3usize] = whi[0usize];
                                        out[(sbase + ra) as usize] = rv;
                                    }
                                    if nzb && !((fault & 32u32) != 0u32 && CUBE_POS_X == 0u32) {
                                        let mut rv = Vector::<u32, Const<4>>::empty();
                                        rv[0usize] = pk[1usize];
                                        rv[1usize] = lb + cpos;
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
                        }
                        e0 += 32u32;
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
                    comm[(t - 32u32) as usize].store(u32::MAX);
                }
                npend = left;
                cdone += ntake;
                sync_cube();
                if done && left == 0u32 {
                    going = false;
                }
            }
        }
        {
            // F_SLABCNT (2048): cube 0 never writes its last slab's count
            if lane == 0u32
                && have_slab
                && slab_id < nslab_cap
                && !((fault & 2048u32) != 0u32 && CUBE_POS_X == 0u32)
            {
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
        if t == 0u32 && poff == 0u32 {
            // a job's second instance repeats its children and chunks: count them once
            cnt[(d * 5u32) as usize].fetch_add(my_children);
            cnt[(d * 5u32 + 1u32) as usize].fetch_add(my_chunks);
            acc[A_CHILD].fetch_add(my_children);
        }
        if t == 0u32 {
            cnt[(d * 5u32 + 2u32) as usize].fetch_add(my_flat);
            cnt[C_LSLOTS].fetch_add(my_lslots);
            // positive evidence: this instance reached its end
            acc[A_JOBS].fetch_add(1u32);
        }
    }
}

/// The parents of a slice: `anc8_kernel` (the roots valid to depth 8, shared across digit 8 of a field), `hist2`
/// (each root's parent, certified or not, counted by (class, key bucket) and appended to a compact list), `scan16`
/// (the bucket offsets), `scatter3` (the list into bucket order, with each parent's certified-children count) and
/// `hsort` (each bucket sorted by r4, the CPU reference's order): `pseg` and the sorted parent records. Also
/// `tdigz` (the host-tops path only: the top digits, and the zeroing of the slice's counters).
// CubeCL's comptime branches assign a variable declared before them (`let mut x = ..; if comptime!(..) { x = .. }
// else { x = .. }`): rustc sees the declaration's value as never read.
#[allow(unused_assignments)]
mod prep {
    use super::{A_ERR_PLANE, A_H2_CERT, A_H2_CUBES, A_HSORT, A_SC_CHILD, A_SCAN16, A_SCAT};
    use cubecl::prelude::*;

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
    /// (Digits from 32-bit halves; the 18 digits are distinct iff the mask has 18 bits, so no per-digit
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
            m |= (1u64 << u64::cast_from(dig2(slo, shi, j)))
                | (1u64 << u64::cast_from(dig2(clo, chi, j)));
        }
        let ok = m.count_ones() == 18u32;
        let r0 = r4 & 63u32;
        let cacc = dig2(slo, shi, 9u32)
            | (dig2(clo, chi, 9u32) << 8u32)
            | (((2u32 * r0) & 63u32) << 16u32)
            | (((3u32 * r0 * r0) & 63u32) << 24u32);
        // pip mod 63; uniform. pip is a slice key (digits 4–8 of n: 30 bits), so its low word is all of it. (Not
        // `u32(pip >> 32) % 63`: Apple's GPU compiler miscompiles a constant division of a u64's high word.)
        let pm63 = u32::cast_from(pip & 0xFFFF_FFFFu64) % 63u32;
        let cls = (r4 % 63u32 + pm63) % 63u32;
        let mut k8 = 0u32;
        #[unroll]
        for i in 0..8u32 {
            k8 |=
                u32::cast_from((m >> u64::cast_from(rank[i as usize])) & 1u64) << comptime!(7 - i);
        }
        let key = cls * 256u32 + (255u32 - k8);
        let mut mm = m;
        if !ok {
            mm = 0u64;
        }
        (mm, cacc, key)
    }

    /// The parents' shared pass across digit 8: the depth-4 roots whose depth-8 ancestor
    /// r = r4 + pip8·2^24 (pip8 = digits 4–7 of the slices it serves) has 16 distinct digits 0–7 of r² and r³
    /// (mod 2^48), appended as r4 to `out` (one atomic per plane; order arbitrary). Digits 0–7 of r² and r³
    /// depend only on r mod 2^48, so every root whose depth-9 parent passes `parent` for some digit 8 is listed:
    /// `hist2` over this list instead of every root is exact, for each of the 64 slices that share digits 4–7.
    /// Account `acc8`: [cubes done, roots examined, roots certified (by a ballot, apart from the list's own count
    /// `cnt[0]`), plane errors].
    #[cube(launch_unchecked)]
    pub fn anc8_kernel(
        r4s: &Array<u32>,
        out: &mut Array<u32>,
        cnt: &mut Array<Atomic<u32>>,
        nroots: u32,
        pip8: u32,
        cap: u32,
        acc8: &mut Array<Atomic<u32>>,
        #[comptime] w: u32,
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
        let mut r4 = 0u32;
        if live {
            r4 = r4s[i as usize];
            let mask48 = (1u64 << 48u64) - 1u64;
            let r = (u64::cast_from(r4) + (u64::cast_from(pip8) << 24u64)) & mask48;
            let sq = (r * r) & mask48;
            let cu = (sq * r) & mask48;
            let slo = u32::cast_from(sq & 0xFFFF_FFFFu64);
            let shi = u32::cast_from(sq >> 32u64);
            let clo = u32::cast_from(cu & 0xFFFF_FFFFu64);
            let chi = u32::cast_from(cu >> 32u64);
            let mut m = 0u64;
            #[unroll]
            for j in 0..8u32 {
                m |= (1u64 << u64::cast_from(dig2(slo, shi, j)))
                    | (1u64 << u64::cast_from(dig2(clo, chi, j)));
            }
            ok = m.count_ones() == 16u32;
        }
        let b = plane_ballot(ok);
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
            base0 = cnt[0usize].fetch_add(n);
        }
        let base = plane_sum(base0); // only lane 0 holds it
        if ok {
            let slot = base + r;
            if slot < cap {
                out[slot as usize] = r4;
            }
        }
        let ex = plane_sum(select(live, 1u32, 0u32));
        if UNIT_POS_PLANE == 0u32 {
            sh[0usize].fetch_add(ex);
            sh[1usize].fetch_add(n);
        }
        sync_cube();
        if UNIT_POS_X == 0u32 {
            acc8[0usize].fetch_add(1u32);
            acc8[1usize].fetch_add(sh[0usize].load());
            acc8[2usize].fetch_add(sh[1usize].load());
        }
    }

    /// The histogram pass also appends each parent's record and key to a compact list (one
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
        // F_DROP_PARENT (8192): parents of r4 = 0 mod 997 taken as uncertified
        fault: u32,
        acc: &mut Array<Atomic<u32>>,
        #[comptime] w: u32,
    ) {
        // the cube's certified parents, counted apart from the list (account `A_H2_CERT`)
        let sh = SharedMemory::<Atomic<u32>>::new(1usize);
        if UNIT_POS_X == 0u32 {
            sh[0usize].store(0u32);
        }
        if PLANE_DIM != w || UNIT_POS_X % w != UNIT_POS_PLANE {
            acc[A_ERR_PLANE].fetch_add(1u32);
        }
        sync_cube();
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
        let flag = m != 0u64 && !((fault & 8192u32) != 0u32 && r4 % 997u32 == 0u32);
        let bm = plane_ballot(m != 0u64);
        let mut nm = bm[0usize].count_ones();
        if comptime!(w > 32) {
            nm += bm[1usize].count_ones();
        }
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
        if UNIT_POS_PLANE == 0u32 && nm > 0u32 {
            sh[0usize].fetch_add(nm);
        }
        sync_cube();
        if UNIT_POS_X == 0u32 {
            acc[A_H2_CERT].fetch_add(sh[0usize].load());
            acc[A_H2_CUBES].fetch_add(1u32);
        }
    }

    /// The number of units d (of 64) for which `child_mask(pm, cacc, d) != 0`, pm = lo | hi << 32, in 32-bit
    /// operations (AMD's compiler, ACO, emitted the 64 `child_mask` calls with 64-bit shifts and ORs). A child of unit d is
    /// valid iff its two new digits e2 = (a2 + b2·d) mod 64 and e3 = (a3 + b3·d) mod 64 differ and both miss pm;
    /// e2 and e3 advance by b2 and b3 per unit.
    #[cube]
    pub fn child_count(lo: u32, hi: u32, cacc: u32) -> u32 {
        let nlo = !lo;
        let nhi = !hi;
        let b2 = (cacc >> 16u32) & 63u32;
        let b3 = (cacc >> 24u32) & 63u32;
        let mut e2 = cacc & 63u32;
        let mut e3 = (cacc >> 8u32) & 63u32;
        let mut n = 0u32;
        for _ in 0..64u32 {
            // bit e of !pm: the free digit test, from the half that holds it
            let f2 = (select(e2 >= 32u32, nhi, nlo) >> (e2 & 31u32)) & 1u32;
            let f3 = (select(e3 >= 32u32, nhi, nlo) >> (e3 & 31u32)) & 1u32;
            n += f2 & f3 & select(e2 != e3, 1u32, 0u32);
            e2 = (e2 + b2) & 63u32;
            e3 = (e3 + b3) & 63u32;
        }
        n
    }

    /// The scatter of the compact list into bucket order, with the list's length read on the device (`lcnt`,
    /// written by `hist2`) and launched for the list's capacity: the host never needs a slice's parent count.
    #[cube(launch_unchecked)]
    pub fn scatter3_kernel(
        lst: &Array<Vector<u32, Const<4>>>,
        lkey: &Array<u32>,
        lcnt: &Array<u32>,
        cur: &mut Array<Atomic<u32>>,
        tmp: &mut Array<u32>,
        cap: u32,
        acc: &mut Array<Atomic<u32>>,
    ) {
        // rows moved and the listed parents' certified children (64 digit tests each), per cube
        let sh = SharedMemory::<Atomic<u32>>::new(2usize);
        if UNIT_POS_X < 2u32 {
            sh[UNIT_POS_X as usize].store(0u32);
        }
        sync_cube();
        let i = ABSOLUTE_POS_X;
        let mut nch = 0u32;
        let live = i < min(lcnt[0usize], cap);
        if live {
            let key = lkey[i as usize];
            let slot = cur[key as usize].fetch_add(1u32);
            let v = lst[i as usize];
            tmp[(4u32 * slot) as usize] = v[0usize];
            tmp[(4u32 * slot + 1u32) as usize] = v[1usize];
            tmp[(4u32 * slot + 2u32) as usize] = v[2usize];
            tmp[(4u32 * slot + 3u32) as usize] = v[3usize];
            nch = child_count(v[0usize], v[1usize], v[2usize]);
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

    /// --rsort 2: one cube of 256 per bucket; buckets of at most RS2 (comptime 256) parents by rank (each thread one
    /// record, the bucket's r4s read from shared memory four at a time, padded with keys above every r4), larger
    /// ones by the bitonic sort of `bsort_kernel`'s form.
    #[cube(launch_unchecked)]
    pub fn hsort_kernel(
        off: &Array<u32>,
        hist: &Array<u32>,
        tmp: &Array<u32>,
        rec: &mut Array<u32>,
        acc: &mut Array<Atomic<u32>>,
    ) {
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
        if UNIT_POS_X == 0u32 {
            acc[A_HSORT].fetch_add(1u32);
        }
    }

    /// The buckets' exclusive scan with 1,008 threads of 16 buckets each (63 x 16 = 1,008 x 16 = 16,128 buckets)
    /// rather than 256 threads of 63: the single cube's serial chain is 4x shorter.
    #[cube(launch_unchecked)]
    pub fn scan16_kernel(
        hist: &Array<u32>,
        off: &mut Array<u32>,
        cur: &mut Array<Atomic<u32>>,
        pseg: &mut Array<u32>,
        acc: &mut Array<Atomic<u32>>,
    ) {
        let mut sums = SharedMemory::<u32>::new(1024usize);
        let t = UNIT_POS_X;
        if t == 0u32 {
            acc[A_SCAN16].fetch_add(1u32);
        }
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

    /// The top digits (host-tops path) plus the zeroing of the slice's counters on the device (the 16,128 bucket
    /// counts, the list count, the slab counter), so that the host writes nothing between slices. Launched over
    /// max(ntops, 16128) threads.
    #[cube(launch_unchecked)]
    pub fn tdigz_kernel(
        tmask: &Array<u64>,
        tdig: &mut Array<u32>,
        hist: &mut Array<u32>,
        lcnt: &mut Array<u32>,
        slabn: &mut Array<u32>,
        ntops: u32,
    ) {
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
}

/// New for the library path: what turns the main kernel's records into
/// production's survivor list.
/// After the main kernel: `expand_kernel` (records to production's survivor entries through the middle-digit
/// prefilter, `pf` or `pf24`), `done_kernel` (the slice's done word) and `toprec_kernel` (production's top records
/// from the host's tops, the host-tops path).
// CubeCL's comptime branches assign a variable declared before them (`let mut x = ..; if comptime!(..) { x = .. }
// else { x = .. }`): rustc sees the declaration's value as never read.
#[allow(unused_assignments)]
mod post {
    use super::{A_DONE, C_SLICES, NT, SLAB};
    use cubecl::prelude::*;

    /// Digit v (< 64) as a one-hot pair of 32-bit words (lo: digits 0-31).
    #[cube]
    fn oh(v: u32) -> (u32, u32) {
        let b = 1u32 << (v & 31u32);
        let m = 0u32 - (v >> 5u32);
        (b & !m, b & m)
    }

    /// The 12 low base-64 digits of a residue mod 2^72 in 32-bit limbs
    /// (`w0`, `w1`, `w2` < 256) as a one-hot pair (lo, hi), and digits 10-11
    /// alone as another.
    #[cube]
    fn digits12(w0: u32, w1: u32, w2: u32) -> (u32, u32, u32, u32) {
        let mut lo = 0u32;
        let mut hi = 0u32;
        #[unroll]
        for j in 0..5u32 {
            let (a, b) = oh((w0 >> comptime!(6 * j)) & 63u32);
            lo |= a;
            hi |= b;
        }
        let (a5, b5) = oh((w0 >> 30u32) | ((w1 & 15u32) << 2u32));
        lo |= a5;
        hi |= b5;
        #[unroll]
        for j in 0..4u32 {
            let (a, b) = oh((w1 >> comptime!(4 + 6 * j)) & 63u32);
            lo |= a;
            hi |= b;
        }
        let (a10, b10) = oh((w1 >> 28u32) | ((w2 & 3u32) << 4u32));
        let (a11, b11) = oh(w2 >> 2u32);
        (lo | a10 | a11, hi | b10 | b11, a10 | a11, b10 | b11)
    }

    /// Bits 24-47 of a product of two 24-bit values (`x·y < 2^48`): its low and high 32-bit words recombined.
    #[cube]
    fn hi24(x: u32, y: u32) -> u32 {
        ((x * y) >> 24u32) | (u32::mul_hi(x, y) << 8u32)
    }

    /// The 12 low base-64 digits of a residue mod 2^72 in 24-bit limbs (four digits per limb, none straddles) as a
    /// one-hot pair (lo, hi) by 64-bit shifts, and digits 10-11 alone as another.
    #[cube]
    fn digits12_24(l0: u32, l1: u32, l2: u32) -> (u32, u32, u32, u32) {
        let mut m = 0u64;
        #[unroll]
        for j in 0..4u32 {
            m |= 1u64 << u64::cast_from((l0 >> comptime!(6 * j)) & 63u32);
            m |= 1u64 << u64::cast_from((l1 >> comptime!(6 * j)) & 63u32);
        }
        m |= 1u64 << u64::cast_from(l2 & 63u32);
        m |= 1u64 << u64::cast_from((l2 >> 6u32) & 63u32);
        let mm = (1u64 << u64::cast_from((l2 >> 12u32) & 63u32))
            | (1u64 << u64::cast_from((l2 >> 18u32) & 63u32));
        let a = m | mm;
        (
            u32::cast_from(a & 0xFFFF_FFFFu64),
            u32::cast_from(a >> 32u64),
            u32::cast_from(mm & 0xFFFF_FFFFu64),
            u32::cast_from(mm >> 32u64),
        )
    }

    /// [`pf`] in 24-bit limbs: every product is of two values below 2^24, which ACO
    /// for GFX1201 can issue as full-rate 24-bit multiplies instead of the quarter-rate `v_mul_lo/hi_u32` of the
    /// 32-bit limbs; no 64-bit adds, no digit straddling two limbs, and each digit's one-hot as one 64-bit shift
    /// (ACO spent about six 32-bit operations per digit on `oh`'s pair; on CUDA a 64-bit variable shift is two
    /// funnel shifts and a select, so CUDA keeps `pf`).
    #[cube]
    fn pf24(r0: u32, plo: u32, phi: u32, top: u64) -> bool {
        let mk = 0xFF_FFFFu32;
        // n mod 2^72 = x0 + x1·2^24 + x2·2^48: r0 is bits 0-29, plo bits 30-61, phi bits 62-93
        let x0 = r0 & mk;
        let x1 = (r0 >> 24u32) | ((plo & 0x3_FFFFu32) << 6u32);
        let x2 = (plo >> 18u32) | ((phi & 0x3FFu32) << 14u32);
        // n² mod 2^72: column sums stay below 2^32 (at most five 24-bit terms and a carry)
        let p00 = x0 * x0;
        let s0 = p00 & mk;
        let v1 = hi24(x0, x0) + 2u32 * ((x0 * x1) & mk);
        let s1 = v1 & mk;
        let v2 = (v1 >> 24u32) + 2u32 * hi24(x0, x1) + ((x1 * x1) & mk) + 2u32 * ((x0 * x2) & mk);
        let s2 = v2 & mk;
        // n³ = n²·n mod 2^72
        let c0 = (s0 * x0) & mk;
        let u1 = hi24(s0, x0) + ((s0 * x1) & mk) + ((s1 * x0) & mk);
        let c1 = u1 & mk;
        let u2 = (u1 >> 24u32)
            + hi24(s0, x1)
            + hi24(s1, x0)
            + ((s0 * x2) & mk)
            + ((s1 * x1) & mk)
            + ((s2 * x0) & mk);
        let c2 = u2 & mk;
        let (sl, sh, sml, smh) = digits12_24(s0, s1, s2);
        let (cl, ch, cml, cmh) = digits12_24(c0, c1, c2);
        let lo = sl | cl;
        let hi = sh | ch;
        let mlo = sml | cml;
        let mhi = smh | cmh;
        let tlo = u32::cast_from(top & 0xFFFF_FFFFu64);
        let thi = u32::cast_from(top >> 32u64);
        lo.count_ones() + hi.count_ones() == 24u32 && ((mlo & tlo) | (mhi & thi)) == 0u32
    }

    /// The middle-digit prefilter of one survivor (`cpu::prefilter` at k
    /// 10): n mod 2^72 from `r0` and its top's P (bits 30-93 of n), in 32-bit
    /// limbs; the digits at positions 0-11 of n² and n³ (mod 2^72) must be
    /// 24 distinct digits (the bottom's 20 are distinct already), and those
    /// at 10-11 must miss the top's certified digits at positions >= 12
    /// (`top`).
    #[cube]
    fn pf(r0: u32, plo: u32, phi: u32, top: u64) -> bool {
        let x0 = r0 | (plo << 30u32);
        let x1 = (plo >> 2u32) | (phi << 30u32);
        let x2 = (phi >> 2u32) & 255u32;
        // n² mod 2^72
        let s0 = x0 * x0;
        let t1 = u64::cast_from(u32::mul_hi(x0, x0)) + 2u64 * u64::cast_from(x0 * x1);
        let s1 = u32::cast_from(t1 & 0xFFFF_FFFFu64);
        let s2 =
            (u32::cast_from(t1 >> 32u64) + 2u32 * u32::mul_hi(x0, x1) + x1 * x1 + 2u32 * x0 * x2)
                & 255u32;
        // n³ = n²·n mod 2^72
        let c0 = s0 * x0;
        let t2 =
            u64::cast_from(u32::mul_hi(s0, x0)) + u64::cast_from(s0 * x1) + u64::cast_from(s1 * x0);
        let c1 = u32::cast_from(t2 & 0xFFFF_FFFFu64);
        let c2 = (u32::cast_from(t2 >> 32u64)
            + u32::mul_hi(s0, x1)
            + u32::mul_hi(s1, x0)
            + s1 * x1
            + s0 * x2
            + s2 * x0)
            & 255u32;
        let (sl, sh, sml, smh) = digits12(s0, s1, s2);
        let (cl, ch, cml, cmh) = digits12(c0, c1, c2);
        let lo = sl | cl;
        let hi = sh | ch;
        let mlo = sml | cml;
        let mhi = smh | cmh;
        let tlo = u32::cast_from(top & 0xFFFF_FFFFu64);
        let thi = u32::cast_from(top >> 32u64);
        lo.count_ones() + hi.count_ones() == 24u32 && ((mlo & tlo) | (mhi & thi)) == 0u32
    }

    /// The prefilter in the runtime's form: 24-bit limbs and 64-bit one-hot shifts on the SPIR-V path (`pf24`),
    /// 32-bit limbs and one-hot pairs on CUDA (`pf`, as measured there).
    #[cube]
    fn pfx(r0: u32, plo: u32, phi: u32, top: u64, #[comptime] oh64: bool) -> bool {
        let mut ok = false;
        if comptime!(oh64) {
            ok = pf24(r0, plo, phi, top);
        } else {
            ok = pf(r0, plo, phi, top);
        }
        ok
    }

    /// The bits of two records (top index, chunk position, word lo, hi) whose
    /// survivors pass the prefilter, in one loop over the four words (a
    /// plane runs as many rounds as its lane with the most bits, so one
    /// loop over both records costs the plane max(a + b), not max(a) + max(b),
    /// and the prefilter is most of a round); `hda`, `hdb` and `topa`, `topb`
    /// their tops' h | d << 16 and prefilter masks. An all-zero record (past
    /// the slab) has none. Returns the kept bits (a lo, a hi, b lo, b hi).
    #[cube]
    fn keep_bits2(
        reca: Vector<u32, Const<4>>,
        recb: Vector<u32, Const<4>>,
        hda: u32,
        hdb: u32,
        topa: u64,
        topb: u64,
        lst: &Array<u32>,
        r0hi: u32,
        pip_hi: u32,
        nopf: bool,
        pfdrop: bool,
        #[comptime] oh64: bool,
    ) -> (u32, u32, u32, u32) {
        // P = n div 2^30 = h·2^30 + d·2^24 + digits 5-8 (the top record's words 0-1), per record
        let ha = hda & 0xFFFFu32;
        let hb = hdb & 0xFFFFu32;
        let ploa = ((ha & 3u32) << 30u32) | ((hda >> 16u32) << 24u32) | pip_hi;
        let plob = ((hb & 3u32) << 30u32) | ((hdb >> 16u32) << 24u32) | pip_hi;
        let phia = ha >> 2u32;
        let phib = hb >> 2u32;
        let mut k0 = 0u32;
        let mut k1 = 0u32;
        let mut k2 = 0u32;
        let mut k3 = 0u32;
        let mut w0 = reca[2usize];
        let mut w1 = reca[3usize];
        let mut w2 = recb[2usize];
        let mut w3 = recb[3usize];
        while (w0 | w1 | w2 | w3) != 0u32 {
            // the lowest set bit of the first nonzero word, in the order a lo, a hi, b lo, b hi
            let ina = (w0 | w1) != 0u32;
            let x = select(ina, w0, w2);
            let y = select(ina, w1, w3);
            let inlo = x != 0u32;
            let wd = select(inlo, x, y);
            let b = wd.trailing_zeros();
            let off = select(inlo, b, 32u32 + b);
            let cl = wd & (wd - 1u32);
            w0 = select(ina && inlo, cl, w0);
            w1 = select(ina && !inlo, cl, w1);
            w2 = select(!ina && inlo, cl, w2);
            w3 = select(!ina && !inlo, cl, w3);
            let pos = select(ina, reca[1usize], recb[1usize]);
            let r0 = lst[(pos + off) as usize] + r0hi;
            let top = select(ina, topa, topb);
            if nopf
                || (pfx(
                    r0,
                    select(ina, ploa, plob),
                    select(ina, phia, phib),
                    top,
                    oh64,
                ) && !(pfdrop && (r0 >> 10u32).trailing_zeros() >= 10u32))
            {
                let bit = 1u32 << b;
                k0 |= select(ina && inlo, bit, 0u32);
                k1 |= select(ina && !inlo, bit, 0u32);
                k2 |= select(!ina && inlo, bit, 0u32);
                k3 |= select(!ina && !inlo, bit, 0u32);
            }
        }
        (k0, k1, k2, k3)
    }

    /// Writes the kept bits' entries `(top, r0)` from `slot` on; returns the
    /// next slot.
    #[cube]
    fn put_bits(
        ti: u32,
        pos: u32,
        klo: u32,
        khi: u32,
        lst: &Array<u32>,
        surv: &mut Array<u32>,
        slot0: u32,
        scap: u32,
        r0hi: u32,
    ) -> u32 {
        let mut slot = slot0;
        let mut x = klo;
        let mut y = khi;
        while (x | y) != 0u32 {
            let inlo = x != 0u32;
            let b = select(inlo, x.trailing_zeros(), y.trailing_zeros());
            let off = select(inlo, b, 32u32 + b);
            if inlo {
                x &= x - 1u32;
            } else {
                y &= y - 1u32;
            }
            if slot < scap {
                surv[(2u32 * slot) as usize] = ti;
                surv[(2u32 * slot + 1u32) as usize] = lst[(pos + off) as usize] + r0hi;
            }
            slot += 1u32;
        }
        slot
    }

    /// Records → production's survivor-list entries `(top, r0)`, `r0 = n mod
    /// 2^30` (the child's r4 and the slice's digit 4), through the
    /// middle-digit prefilter ([`pf`]): each plane takes the used slabs in a
    /// grid-stride loop and its lanes the slab's records; a record names its
    /// top and its chunk's first position in the child lists (`lst`, written
    /// by the main kernel's phase 1), so a set bit b is the child at that
    /// position + b. The bits that pass are appended in plane-sized takes.
    /// `stat`: the slice's parents and slabs (thread 0) and the bits read
    /// (the survivors, for the account).
    #[cube(launch_unchecked)]
    pub fn expand_kernel(
        out: &Array<Vector<u32, Const<4>>>,
        slabn: &Array<u32>,
        slabcnt: &Array<u32>,
        lst: &Array<u32>,
        lcnt: &Array<u32>,
        thd: &Array<u32>,
        tmhi: &Array<u64>,
        surv: &mut Array<u32>,
        scount: &mut Array<Atomic<u32>>,
        stat: &mut Array<Atomic<u32>>,
        nslab_cap: u32,
        scap: u32,
        r0hi: u32,
        pip_hi: u32,
        // F_NOPF (1): every survivor listed, no prefilter
        fault: u32,
        // the prefilter in 24-bit limbs with 64-bit one-hot shifts (`pf24`: the SPIR-V path) or as measured on CUDA (`pf`)
        #[comptime] oh64: bool,
    ) {
        let nopf = (fault & 1u32) != 0u32;
        // F_PF_DROP (1024): the prefilter wrongly drops survivors whose r0 has bits 10-19 zero
        let pfdrop = (fault & 1024u32) != 0u32;
        if ABSOLUTE_POS_X == 0u32 {
            stat[0usize].store(lcnt[0usize]);
            stat[1usize].store(slabn[0usize]);
        }
        // one plane per slab at a time, its lanes over the slab's rows: no idle slots past a slab's count; two
        // records per lane and take, their loads issued together (more loads in flight per plane)
        let ns = min(slabn[0usize], nslab_cap);
        let ppc = NT / PLANE_DIM;
        let pstride = CUBE_COUNT_X * ppc;
        let mut s = CUBE_POS_X * ppc + UNIT_POS_X / PLANE_DIM;
        let mut read = 0u32;
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
                for k in 0..4u32 {
                    reca[k as usize] = 0u32;
                    recb[k as usize] = 0u32;
                }
                if ra < cnt {
                    reca = out[(s * SLAB + ra) as usize];
                }
                if rb < cnt {
                    recb = out[(s * SLAB + rb) as usize];
                }
                let hda = thd[reca[0usize] as usize];
                let hdb = thd[recb[0usize] as usize];
                let topa = tmhi[reca[0usize] as usize];
                let topb = tmhi[recb[0usize] as usize];
                read += reca[2usize].count_ones()
                    + reca[3usize].count_ones()
                    + recb[2usize].count_ones()
                    + recb[3usize].count_ones();
                let (kla, kha, klb, khb) = keep_bits2(
                    reca, recb, hda, hdb, topa, topb, lst, r0hi, pip_hi, nopf, pfdrop, oh64,
                );
                let nb = kla.count_ones() + kha.count_ones() + klb.count_ones() + khb.count_ones();
                let excl = plane_exclusive_sum(nb);
                let tot = plane_sum(nb);
                let mut b0 = 0u32;
                if UNIT_POS_PLANE == 0u32 && tot > 0u32 {
                    b0 = scount[0usize].fetch_add(tot);
                }
                let slot = plane_sum(b0) + excl;
                let sb = put_bits(
                    reca[0usize],
                    reca[1usize],
                    kla,
                    kha,
                    lst,
                    surv,
                    slot,
                    scap,
                    r0hi,
                );
                put_bits(
                    recb[0usize],
                    recb[1usize],
                    klb,
                    khb,
                    lst,
                    surv,
                    sb,
                    scap,
                    r0hi,
                );
                r0 += 2u32 * PLANE_DIM;
            }
            s += pstride;
        }
        let rs = plane_sum(read);
        if UNIT_POS_PLANE == 0u32 && rs > 0u32 {
            stat[2usize].fetch_add(rs);
        }
        // positive evidence: cubes done (= the grid) and slabs walked, once per plane (= the slabs used); a plane
        // partly filled or without lane 0 under-counts, which the host sees
        if UNIT_POS_PLANE == 0u32 && walked > 0u32 {
            stat[4usize].fetch_add(walked);
        }
        if UNIT_POS_X == 0u32 {
            stat[3usize].fetch_add(1u32);
        }
    }

    /// The slice's last kernel (after its last batch's check): the slice's
    /// done word and the group's slice count, from which the host counts
    /// the slices that ran.
    #[cube(launch_unchecked)]
    pub fn done_kernel(acc: &mut Array<Atomic<u32>>, cnt: &mut Array<Atomic<u32>>) {
        if ABSOLUTE_POS_X == 0u32 {
            acc[A_DONE].fetch_add(1u32);
            cnt[C_SLICES].fetch_add(1u32);
        }
    }

    /// Production's top-record layout per top: P = n div b^5 (lo, hi) and
    /// w6 = P mod b^5, from the top's (h, d) and the slice's digits 5–8.
    #[cube(launch_unchecked)]
    pub fn toprec_kernel(thd: &Array<u32>, top_rec: &mut Array<u32>, pip_hi: u32, ntops: u32) {
        let i = ABSOLUTE_POS_X;
        if i < ntops {
            let h = thd[i as usize] & 0xFFFFu32;
            let d = thd[i as usize] >> 16u32;
            let w6 = (d << 24u32) | pip_hi;
            let o = 8u32 * i;
            top_rec[o as usize] = ((h & 3u32) << 30u32) | w6;
            top_rec[(o + 1u32) as usize] = h >> 2u32;
            top_rec[(o + 2u32) as usize] = 0u32;
            top_rec[(o + 3u32) as usize] = 0u32;
            top_rec[(o + 4u32) as usize] = 0u32;
            top_rec[(o + 5u32) as usize] = 0u32;
            top_rec[(o + 6u32) as usize] = w6;
            top_rec[(o + 7u32) as usize] = 0u32;
        }
    }
}

/// The tops of a slice on the device (base 64, f0 4, k 10): one thread per
/// prefix (unit d, lead h), the certificate by 32-bit limbs and shifts (the
/// function of `cpu::top_cert`; n² has 26 digits and n³ 38 over the whole
/// base, so the lengths always agree), then a count per segment (d, h mod
/// 63), a scan, and a scatter into the segments. The order inside a
/// segment is the device's; nothing downstream depends on it.
mod dtops {
    use super::{A_T1_CERT, A_T1_EXAM, A_T2_PLACED, A_TDIG, A_TREC, A_TSCAN, MAXPOP};
    use cubecl::prelude::*;

    /// `r = x·y` for little-endian 32-bit limbs (comptime sizes).
    #[cube]
    fn mul(
        x: &Array<u32>,
        y: &Array<u32>,
        r: &mut Array<u32>,
        #[comptime] nx: u32,
        #[comptime] ny: u32,
    ) {
        let mut acc = Array::<u64>::new(comptime!((nx + ny) as usize));
        #[unroll]
        for k in 0..comptime!(nx + ny) {
            acc[k as usize] = 0u64;
        }
        #[unroll]
        for i in 0..nx {
            #[unroll]
            for j in 0..ny {
                let p = u64::cast_from(x[i as usize]) * u64::cast_from(y[j as usize]);
                acc[comptime!(i + j) as usize] += p & 0xFFFF_FFFFu64;
                acc[comptime!(i + j + 1) as usize] += p >> 32u64;
            }
        }
        let mut carry = 0u64;
        #[unroll]
        for k in 0..comptime!(nx + ny) {
            let v = acc[k as usize] + carry;
            r[k as usize] = u32::cast_from(v & 0xFFFF_FFFFu64);
            carry = v >> 32u64;
        }
    }

    /// Base-64 digit j (comptime) of a limb array.
    #[cube]
    fn dg(x: &Array<u32>, #[comptime] j: u32) -> u32 {
        let w = comptime!((6 * j) / 32);
        let o = comptime!((6 * j) % 32);
        let mut v = x[w as usize] >> o;
        if comptime!(o > 26) {
            v |= x[comptime!(w + 1) as usize] << comptime!(32 - o);
        }
        v & 63u32
    }

    /// One power's part of the certificate: digits top..=10 while x and y
    /// agree; (mask, its digits at positions >= 12, repeated).
    #[cube]
    fn cert_pow(
        x: &Array<u32>,
        y: &Array<u32>,
        mask_in: u64,
        mhi_in: u64,
        #[comptime] top: u32,
    ) -> (u64, u64, bool) {
        let mut mask = mask_in;
        let mut mhi = mhi_in;
        let mut live = true;
        let mut bad = false;
        #[unroll]
        for s in 0..comptime!(top - 9) {
            let dx = dg(x, comptime!(top - s));
            let dy = dg(y, comptime!(top - s));
            if live {
                if dx != dy {
                    live = false;
                } else {
                    let bit = 1u64 << u64::cast_from(dx);
                    if (mask & bit) != 0u64 {
                        bad = true;
                        live = false;
                    }
                    mask |= bit;
                    if comptime!(top - s >= 12) {
                        mhi |= bit;
                    }
                }
            }
        }
        (mask, mhi, bad)
    }

    /// The top hierarchy's coarser level, once per 64 slices (digits 5-8 =
    /// `q`): thread i = d·2^15 + (h − 2^15) certifies the prefix n div 2^30
    /// = h·2^30 + d·2^24 + q over its 2^30 n; the valid ones are appended to
    /// `l5` (h | d << 16), their count in `l5n[0]`. A slice's top (digit 4
    /// added) can only be valid under a valid parent: its interval is inside
    /// the parent's, so its certificate holds the parent's digits.
    #[cube(launch_unchecked)]
    pub fn tops5_kernel(l5: &mut Array<u32>, l5n: &mut Array<Atomic<u32>>, q: u32) {
        let i = ABSOLUTE_POS_X;
        if i < 2_097_152u32 {
            let d = i >> 15u32;
            let h = 32768u32 + (i & 32767u32);
            // p = h·2^30 + d·2^24 + q, a = p·2^30, c = a + 2^30 − 1, in 32-bit limbs
            let p = (u64::cast_from(h) << 30u64) | (u64::cast_from(d) << 24u64) | u64::cast_from(q);
            let mut a = Array::<u32>::new(3usize);
            let mut c = Array::<u32>::new(3usize);
            a[0] = u32::cast_from((p & 3u64) << 30u64);
            a[1] = u32::cast_from((p >> 2u64) & 0xFFFF_FFFFu64);
            a[2] = u32::cast_from(p >> 34u64);
            c[0] = a[0] | 0x3FFF_FFFFu32;
            c[1] = a[1];
            c[2] = a[2];
            let mut a2 = Array::<u32>::new(6usize);
            let mut c2 = Array::<u32>::new(6usize);
            mul(&a, &a, &mut a2, 3u32, 3u32);
            mul(&c, &c, &mut c2, 3u32, 3u32);
            let mut a3 = Array::<u32>::new(9usize);
            let mut c3 = Array::<u32>::new(9usize);
            mul(&a2, &a, &mut a3, 6u32, 3u32);
            mul(&c2, &c, &mut c3, 6u32, 3u32);
            let (m1, h1, bad1) = cert_pow(&a2, &c2, 0u64, 0u64, 25u32);
            let (_m2, _h2, bad2) = cert_pow(&a3, &c3, m1, h1, 37u32);
            if !bad1 && !bad2 {
                let slot = l5n[0usize].fetch_add(1u32);
                l5[slot as usize] = h | (d << 16u32);
            }
        }
        // positive evidence: cubes done (= the grid)
        if UNIT_POS_X == 0u32 {
            l5n[1usize].fetch_add(1u32);
        }
    }

    /// Thread i < l5n: the slice's top under the i-th valid parent of `l5`
    /// (the parent's lead h and unit d, the slice's digit 4): certificate,
    /// then a count in segc[d·63 + h mod 63].
    #[cube(launch_unchecked)]
    pub fn tops1_kernel(
        tm: &mut Array<u64>,
        thm: &mut Array<u64>,
        tv: &mut Array<u32>,
        segc: &mut Array<Atomic<u32>>,
        tstat: &mut Array<Atomic<u32>>,
        l5: &Array<u32>,
        l5n: &Array<u32>,
        pip: u32,
        // F_POP12 (64): the popcount limit checked as 12 instead of MAXPOP
        fault: u32,
        acc: &mut Array<Atomic<u32>>,
    ) {
        let n5 = l5n[0usize];
        let plim = select((fault & 64u32) != 0u32, 12u32, MAXPOP);
        let mut i = ABSOLUTE_POS_X;
        let mut exam = 0u32;
        let mut cert = 0u32;
        while i < n5 {
            exam += 1u32;
            let hd = l5[i as usize];
            let d = hd >> 16u32;
            let h = hd & 0xFFFFu32;
            // p = h·2^36 + d·2^30 + pip, a = p·2^24, c = a + 2^24 − 1, in 32-bit limbs
            let p =
                (u64::cast_from(h) << 36u64) | (u64::cast_from(d) << 30u64) | u64::cast_from(pip);
            let mut a = Array::<u32>::new(3usize);
            let mut c = Array::<u32>::new(3usize);
            a[0] = u32::cast_from((p & 0xFFu64) << 24u64);
            a[1] = u32::cast_from((p >> 8u64) & 0xFFFF_FFFFu64);
            a[2] = u32::cast_from(p >> 40u64);
            c[0] = a[0] | 0x00FF_FFFFu32;
            c[1] = a[1];
            c[2] = a[2];
            let mut a2 = Array::<u32>::new(6usize);
            let mut c2 = Array::<u32>::new(6usize);
            mul(&a, &a, &mut a2, 3u32, 3u32);
            mul(&c, &c, &mut c2, 3u32, 3u32);
            let mut a3 = Array::<u32>::new(9usize);
            let mut c3 = Array::<u32>::new(9usize);
            mul(&a2, &a, &mut a3, 6u32, 3u32);
            mul(&c2, &c, &mut c3, 6u32, 3u32);
            let (m1, h1, bad1) = cert_pow(&a2, &c2, 0u64, 0u64, 25u32);
            let (m2, h2, bad2) = cert_pow(&a3, &c3, m1, h1, 37u32);
            let ok = !bad1 && !bad2;
            tv[i as usize] = select(ok, 1u32, 0u32);
            if ok {
                cert += 1u32;
                tm[i as usize] = m2;
                thm[i as usize] = h2;
                segc[(d * 63u32 + h % 63u32) as usize].fetch_add(1u32);
                if m2.count_ones() > plim {
                    tstat[1usize].fetch_add(1u32);
                }
            }
            i += CUBE_COUNT_X * CUBE_DIM_X;
        }
        // positive evidence: valid parents examined (= l5n[0]) and tops certified (= tscan's sum)
        let pe = plane_sum(exam);
        let pc = plane_sum(cert);
        if UNIT_POS_PLANE == 0u32 {
            if pe > 0u32 {
                acc[A_T1_EXAM].fetch_add(pe);
            }
            if pc > 0u32 {
                acc[A_T1_CERT].fetch_add(pc);
            }
        }
    }

    /// One cube of 1,024: segment starts (tseg pairs), cursors, the top count
    /// in tstat[0] and the prefixes certified (the valid parents) in tstat[2].
    #[cube(launch_unchecked)]
    pub fn tscan_kernel(
        segc: &Array<u32>,
        tseg: &mut Array<u32>,
        cur: &mut Array<Atomic<u32>>,
        tstat: &mut Array<u32>,
        l5n: &Array<u32>,
        acc: &mut Array<Atomic<u32>>,
    ) {
        let mut sums = SharedMemory::<u32>::new(1024usize);
        let t = UNIT_POS_X;
        if t == 0u32 {
            tstat[2usize] = l5n[0usize];
            acc[A_TSCAN].fetch_add(1u32);
        }
        let mut local = 0u32;
        if t < 1008u32 {
            for j in 0..4u32 {
                local += segc[(t * 4u32 + j) as usize];
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
            for j in 0..4u32 {
                let k = t * 4u32 + j;
                tseg[(2u32 * k) as usize] = run;
                cur[k as usize].store(run);
                run += segc[k as usize];
                tseg[(2u32 * k + 1u32) as usize] = run;
            }
            if t == 1007u32 {
                tstat[0usize] = run;
            }
        }
    }

    /// Each certified prefix into its segment: tmask and thd = h | d << 16,
    /// and tmhi, the prefilter's mask (its digits at positions >= 12).
    #[cube(launch_unchecked)]
    pub fn tops2_kernel(
        tm: &Array<u64>,
        thm: &Array<u64>,
        tv: &Array<u32>,
        cur: &mut Array<Atomic<u32>>,
        tmask: &mut Array<u64>,
        thd: &mut Array<u32>,
        tmhi: &mut Array<u64>,
        l5: &Array<u32>,
        l5n: &Array<u32>,
        cap: u32,
        acc: &mut Array<Atomic<u32>>,
    ) {
        let n5 = l5n[0usize];
        let mut i = ABSOLUTE_POS_X;
        let mut placed = 0u32;
        while i < n5 {
            if tv[i as usize] == 1u32 {
                let hd = l5[i as usize];
                let d = hd >> 16u32;
                let h = hd & 0xFFFFu32;
                let slot = cur[(d * 63u32 + h % 63u32) as usize].fetch_add(1u32);
                if slot < cap {
                    tmask[slot as usize] = tm[i as usize];
                    thd[slot as usize] = h | (d << 16u32);
                    tmhi[slot as usize] = thm[i as usize];
                    placed += 1u32;
                }
            }
            i += CUBE_COUNT_X * CUBE_DIM_X;
        }
        // positive evidence: tops placed (= tstat[0])
        let pp = plane_sum(placed);
        if UNIT_POS_PLANE == 0u32 && pp > 0u32 {
            acc[A_T2_PLACED].fetch_add(pp);
        }
    }

    /// tdigz with the top count read on the device (tstat[0]).
    #[cube(launch_unchecked)]
    pub fn tdigz2_kernel(
        tmask: &Array<u64>,
        tdig: &mut Array<u32>,
        hist: &mut Array<u32>,
        lcnt: &mut Array<u32>,
        tstat: &Array<u32>,
        cap: u32,
        acc: &mut Array<Atomic<u32>>,
    ) {
        let i = ABSOLUTE_POS_X;
        if i < 16128u32 {
            hist[i as usize] = 0u32;
        }
        if i == 0u32 {
            lcnt[0usize] = 0u32;
        }
        let live = i < min(tstat[0usize], cap);
        // positive evidence: rows written (= tstat[0])
        let rows = plane_sum(select(live, 1u32, 0u32));
        if UNIT_POS_PLANE == 0u32 && rows > 0u32 {
            acc[A_TDIG].fetch_add(rows);
        }
        if live {
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

    /// toprec with the top count read on the device.
    #[cube(launch_unchecked)]
    pub fn toprec2_kernel(
        thd: &Array<u32>,
        top_rec: &mut Array<u32>,
        tstat: &Array<u32>,
        pip_hi: u32,
        cap: u32,
        acc: &mut Array<Atomic<u32>>,
    ) {
        let i = ABSOLUTE_POS_X;
        let live = i < min(tstat[0usize], cap);
        // positive evidence: rows written (= tstat[0])
        let rows = plane_sum(select(live, 1u32, 0u32));
        if UNIT_POS_PLANE == 0u32 && rows > 0u32 {
            acc[A_TREC].fetch_add(rows);
        }
        if live {
            let h = thd[i as usize] & 0xFFFFu32;
            let d = thd[i as usize] >> 16u32;
            let w6 = (d << 24u32) | pip_hi;
            let o = 8u32 * i;
            top_rec[o as usize] = ((h & 3u32) << 30u32) | w6;
            top_rec[(o + 1u32) as usize] = h >> 2u32;
            top_rec[(o + 2u32) as usize] = 0u32;
            top_rec[(o + 3u32) as usize] = 0u32;
            top_rec[(o + 4u32) as usize] = 0u32;
            top_rec[(o + 5u32) as usize] = 0u32;
            top_rec[(o + 6u32) as usize] = w6;
            top_rec[(o + 7u32) as usize] = 0u32;
        }
    }
}

// ------------------------------------------------------------------------------------------------ host: tops

/// `a·b` for `a, b < 2^128`, as 4 little-endian words.
fn mul_wide(a: u128, b: u128) -> [u64; 4] {
    let (a0, a1) = (a as u64 as u128, a >> 64);
    let (b0, b1) = (b as u64 as u128, b >> 64);
    let p00 = a0 * b0;
    let p01 = a0 * b1;
    let p10 = a1 * b0;
    let p11 = a1 * b1;
    let mid = (p00 >> 64) + (p01 as u64 as u128) + (p10 as u64 as u128);
    let hi = p11 + (p01 >> 64) + (p10 >> 64) + (mid >> 64);
    [p00 as u64, mid as u64, hi as u64, (hi >> 64) as u64]
}

/// `x·b` for a 256-bit `x` and `b < 2^128` (the product must fit 256 bits).
fn mul_4x2(x: [u64; 4], b: u128) -> [u64; 4] {
    let mut r = [0u64; 4];
    let bw = [b as u64, (b >> 64) as u64];
    for i in 0..4 {
        let mut carry = 0u128;
        for (j, &bj) in bw.iter().enumerate() {
            if i + j >= 4 {
                debug_assert!(x[i] == 0 || bj == 0 || carry == 0);
                break;
            }
            let cur = r[i + j] as u128 + x[i] as u128 * bj as u128 + carry;
            r[i + j] = cur as u64;
            carry = cur >> 64;
        }
        if i + 2 < 4 {
            let cur = r[i + 2] as u128 + carry;
            r[i + 2] = cur as u64;
            debug_assert!(cur >> 64 == 0 || i + 3 < 4);
            if i + 3 < 4 {
                r[i + 3] += (cur >> 64) as u64;
            }
        }
    }
    r
}

fn bitlen(x: &[u64; 4]) -> u32 {
    for i in (0..4).rev() {
        if x[i] != 0 {
            return 64 * i as u32 + 64 - x[i].leading_zeros();
        }
    }
    0
}

/// Base-64 digit `j` of a 256-bit number.
fn digit64(x: &[u64; 4], j: u32) -> u32 {
    let bit = 6 * j;
    let (w, o) = ((bit / 64) as usize, bit % 64);
    let mut v = x[w] >> o;
    if o > 58 && w + 1 < 4 {
        v |= x[w + 1] << (64 - o);
    }
    (v & 63) as u32
}

/// One power's part of a top certificate (digits at positions >= 10 equal
/// from the top down); false if a digit repeats.
fn cert_part(x: &[u64; 4], y: &[u64; 4], mask: &mut u64, mhi: &mut u64) -> bool {
    let lx = bitlen(x).div_ceil(6);
    if lx != bitlen(y).div_ceil(6) {
        return true;
    }
    let mut j = lx;
    while j > 10 {
        j -= 1;
        let dx = digit64(x, j);
        if dx != digit64(y, j) {
            break;
        }
        let bit = 1u64 << dx;
        if *mask & bit != 0 {
            return false;
        }
        *mask |= bit;
        if j >= 12 {
            *mhi |= bit;
        }
    }
    true
}

/// The certificate of the base-64 top interval `[a, c]` at kpos 10 (the same
/// function as `cpu::top_cert`, by shifts; tested against it).
pub fn top_cert_b64(a: u128, c: u128) -> Option<u64> {
    top_cert_b64_split(a, c).map(|x| x.0)
}

/// [`top_cert_b64`] and its digits at positions `>= 12` (the prefilter's
/// `mhi`, `cpu::top_cert_split` at 10, 12).
pub fn top_cert_b64_split(a: u128, c: u128) -> Option<(u64, u64)> {
    let (mut mask, mut mhi) = (0u64, 0u64);
    let (a2, c2) = (mul_wide(a, a), mul_wide(c, c));
    if !cert_part(&a2, &c2, &mut mask, &mut mhi) {
        return None;
    }
    let (a3, c3) = (mul_4x2(a2, a), mul_4x2(c2, c));
    if !cert_part(&a3, &c3, &mut mask, &mut mhi) {
        return None;
    }
    Some((mask, mhi))
}

/// The depth-4 roots (r4 with distinct digits 0–3 of r4² and r4³ mod 2^60), ascending.
fn root_mask(r4: u64) -> u64 {
    let s = r4.wrapping_mul(r4) & MASK60;
    let c = s.wrapping_mul(r4) & MASK60;
    let mut m = 0u64;
    for j in 0..4 {
        let a = 1u64 << ((s >> (6 * j)) & 63);
        let b = 1u64 << ((c >> (6 * j)) & 63);
        if (m & a) != 0 || (m & b) != 0 || a == b {
            return 0;
        }
        m |= a | b;
    }
    m
}

/// The mask of the parent of root r4 in slice pip (0 if a digit 0–8 repeats).
fn parent_mask(r4: u64, pip: u64) -> u64 {
    let r = r4 + (pip << 24);
    let s = r.wrapping_mul(r) & MASK60;
    let c = s.wrapping_mul(r) & MASK60;
    let mut m = 0u64;
    for j in 0..9 {
        m |= (1u64 << ((s >> (6 * j)) & 63)) | (1u64 << ((c >> (6 * j)) & 63));
    }
    if m.count_ones() == 18 { m } else { 0 }
}

/// Every depth-4 root, ascending (9,298,544 of them).
pub fn depth4_roots() -> Vec<u32> {
    (0..(1u32 << 24))
        .filter(|&r| root_mask(r as u64) != 0)
        .collect()
}

/// A slice's tops, as the device reads them.
pub struct SliceTops {
    pub pip: u64,
    /// Masks, sorted by (unit d, h mod 63), leads ascending inside.
    pub tmask: Vec<u64>,
    /// h | d << 16 per top, same order.
    pub thd: Vec<u32>,
    /// The certificate's digits at positions >= 12 (the prefilter's), same order.
    pub tmhi: Vec<u64>,
    /// Segments [(d·63 + ct)·2], [+1] of the sorted tops.
    pub tseg: Vec<u32>,
    /// The 8 key digits of the parents' sort.
    pub rank: [u32; 8],
    pub tested: u64,
    /// The largest top popcount, and the largest probe count of a job.
    pub maxpop: u32,
    pub maxprobe: u32,
}

/// Leads of a base-64 unit: h in [2^15, 2^16).
const H_LO: u64 = 1 << 15;
const H_HI: u64 = 1 << 16;
/// One root in this many feeds the key's parent digit counts.
const KEY_SAMPLE: usize = 16;

/// The tops of slice `pip` (digits 4–8), every unit; the key from the
/// tops' digit counts and a 1/16 sample of the parents'.
pub fn slice_tops(pip: u64, roots: &[u32]) -> SliceTops {
    let mut by: Vec<Vec<(u64, u32, u64)>> = vec![Vec::new(); 64 * 63];
    let mut tested = 0u64;
    let mut ft = vec![0u64; 64];
    let mut maxpop = 0;
    for d in 0..64u64 {
        for h in H_LO..H_HI {
            let p = (h << 36) | (d << 30) | pip;
            let a = (p as u128) << 24;
            tested += 1;
            if let Some((m, mh)) = top_cert_b64_split(a, a + (1 << 24) - 1) {
                by[(d * 63 + h % 63) as usize].push((m, (h as u32) | ((d as u32) << 16), mh));
                maxpop = maxpop.max(m.count_ones());
                let mut x = m;
                while x != 0 {
                    ft[x.trailing_zeros() as usize] += 1;
                    x &= x - 1;
                }
            }
        }
    }
    let mut tmask = Vec::new();
    let mut thd = Vec::new();
    let mut tmhi = Vec::new();
    let mut tseg = vec![0u32; 64 * 63 * 2];
    for (s, v) in by.iter().enumerate() {
        tseg[2 * s] = tmask.len() as u32;
        for &(m, x, mh) in v {
            tmask.push(m);
            thd.push(x);
            tmhi.push(mh);
        }
        tseg[2 * s + 1] = tmask.len() as u32;
    }
    let mut maxprobe = 0;
    for c in 0..63u32 {
        for d in 0..64u32 {
            let cc = (c + d) % M;
            let mut n = 0;
            for &r in &ROOTS {
                let ct = (r + M - cc) % M;
                let s = ((d * M + ct) * 2) as usize;
                n += tseg[s + 1] - tseg[s];
            }
            maxprobe = maxprobe.max(n);
        }
    }
    let mut fp = vec![0u64; 64];
    for &r4 in roots.iter().step_by(KEY_SAMPLE) {
        let mut x = parent_mask(r4 as u64, pip);
        while x != 0 {
            fp[x.trailing_zeros() as usize] += 1;
            x &= x - 1;
        }
    }
    let rank: [u32; 8] = key_digits(64, &fp, &ft).try_into().expect("8 key digits");
    SliceTops {
        pip,
        tmask,
        thd,
        tmhi,
        tseg,
        rank,
        tested,
        maxpop,
        maxprobe,
    }
}

// ------------------------------------------------------------------------------------------------ host: device

/// Capacities of the device buffers (per launch batch unless noted).
#[derive(Clone, Copy, Debug)]
pub struct Caps {
    /// Parents of a slice.
    pub parents: u32,
    /// Tops of a slice.
    pub tops: u32,
    /// Survivors of a whole slice (a batch gets its share, plus slack).
    pub survivors: u32,
    /// Classes per launch batch (63: one launch per slice; lavapipe: 4).
    pub classes: u32,
    /// Nice numbers the device may report before a read (or, with
    /// `probe`, every survivor the check rebuilds).
    pub nice: u32,
    /// Tests: run the check in production's probe mode (it writes every n
    /// it rebuilds from the list entry and the top record).
    pub probe: bool,
    /// The prefilter's arithmetic; `None`: [`PrefilterForm::for_runtime`].
    pub prefilter: Option<PrefilterForm>,
}

/// The arithmetic of the expansion's middle-digit prefilter. Both forms compute the same predicate (the device
/// tests compare each with the CPU reference); they differ only in speed, by compiler.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum PrefilterForm {
    /// 32-bit limbs and the digits' one-hot bits in pairs of 32-bit words (`pf`): the faster form on CUDA (an
    /// RTX 3080), where a 64-bit variable shift costs two funnel shifts and a select.
    Limbs32,
    /// 24-bit limbs and each digit's one-hot bit by one 64-bit shift (`pf24`): every product fits AMD's full-rate
    /// 24-bit multiplies (measured with RADV's compiler for the RX 9070 XT, through SPIR-V).
    Limbs24,
}

impl PrefilterForm {
    /// The form for runtime `R`: [`Self::Limbs32`] on CUDA, where it was measured faster; [`Self::Limbs24`] on
    /// every other runtime (wgpu through SPIR-V, WGSL or Metal, and HIP).
    #[must_use]
    pub fn for_runtime<R: Runtime>() -> Self {
        #[cfg(feature = "cubecl-cuda")]
        if std::any::TypeId::of::<R>() == std::any::TypeId::of::<cubecl::cuda::CudaRuntime>() {
            return Self::Limbs32;
        }
        Self::Limbs24
    }
}

impl Caps {
    /// Measured b64 slices hold 1.04M parents, 239k tops and 11.8M
    /// survivors: about twice that.
    #[must_use]
    pub fn b64(classes: u32) -> Self {
        Caps {
            parents: 2_100_000,
            tops: 480_000,
            survivors: 24_000_000,
            classes,
            nice: NICE_CAP,
            probe: false,
            prefilter: None,
        }
    }
}

/// What the device did for a group of slices (sums), with its own checks.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct DevCounts {
    pub children: u64,
    pub chunks: u64,
    pub flat: u64,
    pub kept: u64,
    pub survivors: u64,
    pub checked: u64,
    pub slices: u64,
    pub tops: u64,
    pub tested: u64,
    /// Largest slab count, list length, per-unit flat and survivor counter of a batch or group.
    pub slabs_max: u64,
    pub list_max: u64,
    pub flat_d_max: u64,
    pub surv_d_max: u64,
}

impl DevCounts {
    fn add(&mut self, o: &DevCounts) {
        self.slabs_max = self.slabs_max.max(o.slabs_max);
        self.list_max = self.list_max.max(o.list_max);
        self.flat_d_max = self.flat_d_max.max(o.flat_d_max);
        self.surv_d_max = self.surv_d_max.max(o.surv_d_max);
        self.children += o.children;
        self.chunks += o.chunks;
        self.flat += o.flat;
        self.kept += o.kept;
        self.survivors += o.survivors;
        self.checked += o.checked;
        self.slices += o.slices;
        self.tops += o.tops;
        self.tested += o.tested;
    }
}

/// A slice's uploaded inputs (kept alive until its batches are queued).
struct SliceBufs {
    tmh: Handle,
    tsegh: Handle,
    thdh: Handle,
    /// The tops' prefilter masks.
    tmhih: Handle,
}

/// One queued launch batch's small buffers, read when its group ends.
struct Ticket {
    ran: Handle,
    scount: Handle,
    stat: Handle,
    /// Device tops: the slice's top count and tops over MAXPOP digits (first batch only).
    tstat: Option<Handle>,
    /// Main-kernel job instances the batch queued.
    jobs: u32,
    /// The first batch of a slice: what the slice queued, for its account.
    head: Option<SliceHead>,
}

/// What the host queued for one slice, compared with the slice's account (`acc`) when its group ends.
struct SliceHead {
    pip: u64,
    acc: Handle,
    /// Device tops: the 64-slice level's (valid parents, cubes done).
    l5n: Option<Handle>,
    /// Host tops: their number.
    host_tops: Option<u32>,
    /// Every launch batch of the slice was queued (the probe and children laws hold only then).
    full: bool,
    /// The roots `hist2` examined: every depth-4 root, or a shared depth-8 list's length.
    h2n: u32,
}

/// A slice's device tops and parents, queued: its buffers, top status, account and 64-slice level.
struct DevPrep {
    sb: SliceBufs,
    tstat: Handle,
    acc: Handle,
    l5n: Handle,
    h2n: u32,
}

/// The parents' shared depth-8 lists of a field: one per value of digits 4–7 (`keys`), the roots whose
/// depth-8 ancestor is valid (`anc8_kernel`), with their lengths (read once per field).
#[derive(Default)]
struct AncLists {
    keys: Vec<u32>,
    lens: Vec<u32>,
    lists: Vec<Handle>,
    /// The last build: lists and roots listed (tests, benches).
    last: (usize, u64),
}

/// Most shared depth-8 lists held at once (one per value of digit 4 of a `(4, 8, 5)` field), and each
/// one's capacity in roots (a longer list is an error of the field; ~22 % of the 9.3M roots are listed).
const ANC_LISTS: usize = 64;
const ANC_CAP: u32 = 3_400_000;

/// The device side: kernels compiled for one plane width, buffers allocated
/// once and reused by every slice.
pub struct GpuJoin<R: Runtime> {
    client: ComputeClient<R>,
    pub w: u32,
    fill: u32,
    ballot: bool,
    /// The expansion's prefilter in 24-bit limbs (`pf24`, [`PrefilterForm::Limbs24`]); else `pf`.
    oh64: bool,
    caps: Caps,
    check: CheckShape,
    roots: Vec<u32>,
    r4h: Handle,
    roots_h: Handle,
    /// Per batch: (c0, c1, jobs buffer, jobs).
    pub(crate) batches: Vec<(u32, u32, Handle, u32)>,
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
    slabz: Handle,
    clst: Handle,
    surv: Handle,
    top_rec: Handle,
    nice_out: Handle,
    nice_count: Handle,
    /// Device tops: every prefix's mask, prefilter mask and validity.
    tm: Handle,
    thm: Handle,
    tv: Handle,
    /// The top hierarchy: the valid parents (digits 5-12 fixed) of the
    /// current 64 slices, and (digits 5-8, their count) once queued.
    l5: Handle,
    l5cur: Mutex<Option<(u32, Handle)>>,
    /// The sampled CPU check's slice in a field run, and its (survivors,
    /// checked) as that run counted them (`finish_group`).
    watch: Mutex<(Option<u64>, Option<(u64, u64)>)>,
    /// Timing and bisection only ([`GpuJoin::set_timing_stop`], the bench's
    /// `MIDOUT_STOP`): queue the stages up to this one (1 tops, 2 parents, 3
    /// main kernel, 5 expansion, 6 all; 11–15: the first 1–5 device-top
    /// kernels alone) and skip the accounts. 6 (everything) unless set;
    /// [`search_field`] refuses to run with anything else.
    stop: u32,
    /// fault-injection bits; 0 in production (only the audit tests set it).
    pub(crate) fault: u32,
    /// Share the parents' root pass across digit 8 inside a field ([`GpuJoin::set_parent_sharing`], on).
    share8: bool,
    anc: Mutex<AncLists>,
}

/// Host-side fault bits (the kernel bits are documented at `g2_kernel`'s `fault`).
#[allow(dead_code)] // set by the audit's tests only (some by number, `AUDIT_FAULTS`)
pub(crate) const F_NOPF: u32 = 1;
pub(crate) const F_SKIP_MAIN: u32 = 2;
#[allow(dead_code)] // set by the audit's tests only (some by number, `AUDIT_FAULTS`)
pub(crate) const F_PMAX300: u32 = 4;
#[allow(dead_code)] // set by the audit's tests only (some by number, `AUDIT_FAULTS`)
pub(crate) const F_DROP_PROBE: u32 = 8;
#[allow(dead_code)] // set by the audit's tests only (some by number, `AUDIT_FAULTS`)
pub(crate) const F_IDX13: u32 = 16;
#[allow(dead_code)] // set by the audit's tests only (some by number, `AUDIT_FAULTS`)
pub(crate) const F_DROP_REC: u32 = 32;
#[allow(dead_code)] // set by the audit's tests only (some by number, `AUDIT_FAULTS`)
pub(crate) const F_POP12: u32 = 64;
pub(crate) const F_SLAB_CAP: u32 = 128;
pub(crate) const F_SCAP: u32 = 256;
pub(crate) const F_SKIP_CHECK: u32 = 512;
#[allow(dead_code)] // set by the audit's tests only (some by number, `AUDIT_FAULTS`)
pub(crate) const F_PF_DROP: u32 = 1024;
#[allow(dead_code)] // set by the audit's tests only (some by number, `AUDIT_FAULTS`)
pub(crate) const F_SLABCNT: u32 = 2048;
pub(crate) const F_SKIP_TOPS: u32 = 4096;
#[allow(dead_code)] // set by the audit's tests only (some by number, `AUDIT_FAULTS`)
pub(crate) const F_DROP_PARENT: u32 = 8192;
/// The shared depth-8 pass (`anc8_kernel`) not launched.
#[allow(dead_code)] // set by the audit's tests only
pub(crate) const F_SKIP_ANC: u32 = 16384;

impl<R: Runtime> GpuJoin<R> {
    /// The slab capacity the kernels are told (shrunk by `F_SLAB_CAP`).
    fn ns_cap(&self) -> u32 {
        if self.fault & F_SLAB_CAP != 0 {
            2000
        } else {
            self.nslab_cap
        }
    }

    /// The list capacity the kernels are told (shrunk by `F_SCAP`).
    fn s_cap(&self) -> u32 {
        if self.fault & F_SCAP != 0 {
            100_000
        } else {
            self.scap
        }
    }

    /// Set the fault bits; `F_PMAX300` also rebuilds the job table with the second instance at 300.
    #[allow(dead_code)] // the audit's tests only
    pub(crate) fn set_fault(&mut self, f: u32) {
        self.fault = f;
        let pm = if f & F_PMAX300 != 0 { 300 } else { PMAX };
        let mut nb = Vec::new();
        for (c0, c1, _, _) in &self.batches {
            let mut jobs: Vec<u32> = (*c0..*c1)
                .flat_map(|c| (0..64u32).flat_map(move |d| [c, d]))
                .collect();
            let second: Vec<u32> = jobs
                .chunks(2)
                .flat_map(|x| [x[0], x[1] | pm << 8])
                .collect();
            jobs.extend(second);
            let nj = (jobs.len() / 2) as u32;
            nb.push((*c0, *c1, self.mk(jobs), nj));
        }
        self.batches = nb;
    }
    /// # Errors
    /// A device whose plane width the kernel does not take.
    pub fn new(client: ComputeClient<R>, caps: Caps) -> Result<Self> {
        Self::with_width(client, caps, None)
    }

    /// [`GpuJoin::new`] with the kernels compiled for plane width `force_w` instead of the device's (tests only: to
    /// dump the SPIR-V of another width for an offline compiler; the kernels' plane checks then fail and the results
    /// are invalid).
    pub(crate) fn with_width(
        client: ComputeClient<R>,
        caps: Caps,
        force_w: Option<u32>,
    ) -> Result<Self> {
        let w = force_w.unwrap_or(client.properties().hardware.plane_size_max);
        ensure!(
            [8u32, 16, 32, 64].contains(&w),
            "middle-out: plane width {w} not supported"
        );
        ensure!(
            caps.classes >= 1 && caps.classes <= 63,
            "middle-out: classes per batch 1-63"
        );
        // a top's index rides in bits 12-31 of the probe word (`g2_kernel`, phase 3)
        ensure!(
            caps.tops <= 1 << 20,
            "middle-out: a tops cap of {} does not fit the probe word's 20 bits",
            caps.tops
        );
        let fill = if w < 32 { 512 } else { FILL };
        let check = CheckShape::new(64, 13, 26, 38, 5, 10, GATE_DIGITS)?;
        let roots = depth4_roots();
        let mk = |v: Vec<u32>| client.create(cubecl::bytes::Bytes::from_elems(v));
        let r4h = mk(roots.clone());
        let roots_h = mk(ROOTS.to_vec());
        let mut batches = Vec::new();
        let mut c0 = 0;
        while c0 < 63 {
            let c1 = (c0 + caps.classes).min(63);
            // every job twice: probes [0, PMAX), then [PMAX, 2·PMAX) (a cube with none exits at once)
            let mut jobs: Vec<u32> = (c0..c1)
                .flat_map(|c| (0..64u32).flat_map(move |d| [c, d]))
                .collect();
            let second: Vec<u32> = jobs
                .chunks(2)
                .flat_map(|x| [x[0], x[1] | PMAX << 8])
                .collect();
            jobs.extend(second);
            let nj = (jobs.len() / 2) as u32;
            batches.push((c0, c1, mk(jobs), nj));
            c0 = c1;
        }
        let share = |x: u32| -> u32 {
            ((x as u64 * caps.classes as u64).div_ceil(63) as u32).saturating_add(x / 16)
        };
        let scap = share(caps.survivors);
        let jobs_max = 2 * caps.classes * 64;
        let nslab_cap = scap / SLAB + jobs_max * (NT / w) + 64;
        let lcap = 64 * share(caps.parents);
        let np = caps.parents as usize;
        let nt = caps.tops as usize;
        let e = |bytes: usize| client.empty(bytes);
        Ok(Self {
            w,
            fill,
            ballot: ballot_append(w),
            oh64: caps
                .prefilter
                .unwrap_or_else(PrefilterForm::for_runtime::<R>)
                == PrefilterForm::Limbs24,
            caps,
            check,
            roots,
            r4h,
            roots_h,
            batches,
            nslab_cap,
            scap,
            lcap,
            out: e(nslab_cap as usize * SLAB as usize * 16),
            slabcnt: e(nslab_cap as usize * 4),
            g_tmp: e(np * 16),
            g_lst: e(np * 16),
            g_lkey: e(np * 4),
            g_rec: e(np * 16),
            g_tdig: e(nt * 16),
            histh: mk(vec![0u32; 16128]),
            lcnt: mk(vec![0u32; 1]),
            off: e(16128 * 4),
            curh: e(16128 * 4),
            g_pseg: e(64 * 4),
            slabz: mk(vec![0u32; 1]),
            clst: e(lcap as usize * 4),
            surv: e(scap as usize * 8),
            top_rec: e(nt * TOP_REC_WORDS as usize * 4),
            nice_out: mk(vec![0u32; caps.nice as usize * NICE_STRIDE]),
            nice_count: mk(vec![0u32; 1]),
            tm: e(8 << 21),
            thm: e(8 << 21),
            tv: e(4 << 21),
            l5: e(4 << 21),
            l5cur: Mutex::new(None),
            watch: Mutex::new((None, None)),
            share8: true,
            anc: Mutex::new(AncLists::default()),
            stop: 6,
            fault: 0,
            client,
        })
    }

    /// Timing and bisection only (benches, feature `midout-bench`): queue the stages up to `stop` (see the
    /// field) and skip every account. A join with a stop set can only be timed (`time_field`); [`search_field`]
    /// refuses it.
    #[cfg(any(test, feature = "midout-bench"))]
    pub fn set_timing_stop(&mut self, stop: u32) {
        self.stop = stop;
    }

    /// Share the parents' root pass across digit 8 inside a field: when a field's slices take at most
    /// 64 values of digits 4–7, each of them several times (a `(4, 8, 5)` field: 64 values, 64 slices each), the
    /// roots valid to depth 8 are listed once per value (`anc8_kernel`, at the field's start, one
    /// synchronisation) and each slice's `hist2` runs over its list instead of every root. Exact by containment
    /// (see `anc8_kernel`). On by default (−3.1 % per (4, 8, 5) field on an RTX 3080).
    pub fn set_parent_sharing(&mut self, on: bool) {
        self.share8 = on;
    }

    /// Build the shared depth-8 lists for `keys` (digits 4–7), synchronise, and check their accounts.
    fn build_anc(&self, keys: &[u32]) -> Result<()> {
        ensure!(
            keys.len() <= ANC_LISTS,
            "middle-out: {} depth-8 lists",
            keys.len()
        );
        let mut st = self.anc.lock().expect("anc");
        st.keys.clear();
        st.lens.clear();
        while st.lists.len() < keys.len() {
            let h = self.client.empty(ANC_CAP as usize * 4);
            st.lists.push(h);
        }
        let nroots = self.roots.len() as u32;
        let mut hs = Vec::new();
        for (j, &k) in keys.iter().enumerate() {
            let cnt = self.mk(vec![0u32]);
            let acc8 = self.mk(vec![0u32; 4]);
            if self.fault & F_SKIP_ANC == 0 {
                unsafe {
                    prep::anc8_kernel::launch_unchecked::<R>(
                        &self.client,
                        CubeCount::Static(nroots.div_ceil(NT), 1, 1),
                        CubeDim::new_1d(NT),
                        ArrayArg::from_raw_parts(self.r4h.clone(), nroots as usize),
                        ArrayArg::from_raw_parts(st.lists[j].clone(), ANC_CAP as usize),
                        ArrayArg::from_raw_parts(cnt.clone(), 1),
                        nroots,
                        k,
                        ANC_CAP,
                        ArrayArg::from_raw_parts(acc8.clone(), 4),
                        self.w,
                    );
                }
            }
            hs.push((cnt, acc8));
        }
        cubecl::future::block_on(self.client.sync()).map_err(|e| anyhow!("sync: {e:?}"))?;
        let mut lens = Vec::new();
        for (j, (cnt, acc8)) in hs.iter().enumerate() {
            let n = self.rd(cnt)?[0];
            let a = self.rd(acc8)?;
            let k = keys[j];
            ensure!(
                a[3] == 0,
                "middle-out: anc8 (digits 4-7 {k}): plane errors {}",
                a[3]
            );
            ensure!(
                a[0] == nroots.div_ceil(NT),
                "middle-out: anc8 (digits 4-7 {k}): cubes done: {}, want {} (account {a:?})",
                a[0],
                nroots.div_ceil(NT)
            );
            ensure!(
                a[1] == nroots,
                "middle-out: anc8 (digits 4-7 {k}): roots examined: {}, want {nroots}",
                a[1]
            );
            ensure!(
                a[2] == n,
                "middle-out: anc8 (digits 4-7 {k}): roots certified {} = listed {n}",
                a[2]
            );
            ensure!(
                n > 0 && n <= ANC_CAP,
                "middle-out: anc8 (digits 4-7 {k}): {n} roots listed (capacity {ANC_CAP})"
            );
            lens.push(n);
        }
        st.last = (keys.len(), lens.iter().map(|&x| u64::from(x)).sum());
        st.keys = keys.to_vec();
        st.lens = lens;
        Ok(())
    }

    /// The last build of shared lists: (lists, roots listed in all).
    pub fn parent_sharing_last(&self) -> (usize, u64) {
        self.anc.lock().expect("anc").last
    }

    /// The shared list for a slice (digits 4–7 of `pip`), if one is built: (handle, length).
    fn anc_for(&self, pip: u64) -> Option<(Handle, u32)> {
        let st = self.anc.lock().expect("anc");
        let k = (pip & 0xFF_FFFF) as u32;
        st.keys
            .iter()
            .position(|&x| x == k)
            .map(|j| (st.lists[j].clone(), st.lens[j]))
    }

    /// The depth-4 roots the device holds (for the host's tops and key).
    pub fn roots(&self) -> &[u32] {
        &self.roots
    }

    /// Whether stage `k` is queued (`stop`).
    fn upto(&self, k: u32) -> bool {
        self.stop < 10 && self.stop >= k
    }

    fn mk(&self, v: Vec<u32>) -> Handle {
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

    /// Queue one slice (every batch) into the group's counters `cnt`;
    /// returns its batches' tickets. Nothing waits for the device.
    fn queue(&self, st: &SliceTops, cnt: &Handle, out: &mut Vec<Ticket>) -> Result<()> {
        let (sb, acc) = self.queue_prep(st)?;
        for bi in 0..self.batches.len() {
            let mut t = self.queue_batch(st.pip, st.tmask.len(), &sb, bi, cnt, &acc);
            if bi == 0 {
                t.head = Some(SliceHead {
                    pip: st.pip,
                    acc: acc.clone(),
                    l5n: None,
                    host_tops: Some(st.tmask.len() as u32),
                    full: true,
                    h2n: self.roots.len() as u32,
                });
            }
            out.push(t);
        }
        self.queue_done(&acc, cnt);
        Ok(())
    }

    /// The slice's last kernel: its done word and the group's slice count.
    fn queue_done(&self, acc: &Handle, cnt: &Handle) {
        unsafe {
            post::done_kernel::launch_unchecked::<R>(
                &self.client,
                CubeCount::Static(1, 1, 1),
                CubeDim::new_1d(32),
                ArrayArg::from_raw_parts(acc.clone(), ACC_WORDS),
                ArrayArg::from_raw_parts(cnt.clone(), NCNT),
            );
        }
    }

    /// Queue a slice with its tops made on the device; `rankh` its 8 key
    /// digits (uploaded once per field).
    fn queue_dev(&self, pip: u64, rankh: &Handle, cnt: &Handle, out: &mut Vec<Ticket>) {
        let dp = self.queue_dev_prep(pip, rankh, true);
        let nt = self.caps.tops as usize;
        for bi in 0..self.batches.len() {
            let mut t = self.queue_batch(pip, nt, &dp.sb, bi, cnt, &dp.acc);
            if bi == 0 {
                t.tstat = Some(dp.tstat.clone());
                t.head = Some(SliceHead {
                    pip,
                    acc: dp.acc.clone(),
                    l5n: Some(dp.l5n.clone()),
                    host_tops: None,
                    full: true,
                    h2n: dp.h2n,
                });
            }
            out.push(t);
        }
        self.queue_done(&dp.acc, cnt);
    }

    /// Device tops and parents of a slice; its buffers and top status.
    fn queue_dev_prep(&self, pip: u64, rankh: &Handle, shared: bool) -> DevPrep {
        let nt = self.caps.tops as usize;
        let c = &self.client;
        let a = |h: &Handle, n: usize| unsafe { ArrayArg::from_raw_parts(h.clone(), n) };
        let segc = self.mk(vec![0u32; 4032]);
        let tstat = self.mk(vec![0u32; 3]);
        let acc = self.mk(vec![0u32; ACC_WORDS]);
        let full = 1u32 << 21;
        // the slice's 64-slice group's valid parents, made once per group (the stream orders their reuse)
        let q = (pip >> 6) as u32;
        let l5n = {
            let mut cur = self.l5cur.lock().expect("l5cur");
            match &*cur {
                Some((cq, h)) if *cq == q => h.clone(),
                _ => {
                    // (valid parents, cubes done)
                    let h = self.mk(vec![0u32; 2]);
                    if self.stop < 10 || self.stop - 10 >= 1 {
                        unsafe {
                            dtops::tops5_kernel::launch_unchecked::<R>(
                                &self.client,
                                CubeCount::Static(full / NT, 1, 1),
                                CubeDim::new_1d(NT),
                                ArrayArg::from_raw_parts(self.l5.clone(), full as usize),
                                ArrayArg::from_raw_parts(h.clone(), 2),
                                q,
                            );
                        }
                    }
                    *cur = Some((q, h.clone()));
                    h
                }
            }
        };
        let tsegh = self.client.empty(4032 * 2 * 4);
        let tmh = self.client.empty(nt * 8);
        let thdh = self.client.empty(nt * 4);
        let tmhih = self.client.empty(nt * 8);
        let cur = self.client.empty(4032 * 4);
        unsafe {
            if (self.stop < 10 || self.stop - 10 >= 1) && self.fault & F_SKIP_TOPS == 0 {
                dtops::tops1_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static(TOPS_CUBES, 1, 1),
                    CubeDim::new_1d(NT),
                    a(&self.tm, full as usize),
                    a(&self.thm, full as usize),
                    a(&self.tv, full as usize),
                    a(&segc, 4032),
                    a(&tstat, 3),
                    a(&self.l5, full as usize),
                    a(&l5n, 1),
                    pip as u32,
                    self.fault,
                    a(&acc, ACC_WORDS),
                );
            }
            if self.stop < 10 || self.stop - 10 >= 2 {
                dtops::tscan_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static(1, 1, 1),
                    CubeDim::new_1d(1024),
                    a(&segc, 4032),
                    a(&tsegh, 4032 * 2),
                    a(&cur, 4032),
                    a(&tstat, 3),
                    a(&l5n, 1),
                    a(&acc, ACC_WORDS),
                );
            }
            if self.stop < 10 || self.stop - 10 >= 3 {
                dtops::tops2_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static(TOPS_CUBES, 1, 1),
                    CubeDim::new_1d(NT),
                    a(&self.tm, full as usize),
                    a(&self.thm, full as usize),
                    a(&self.tv, full as usize),
                    a(&cur, 4032),
                    a(&tmh, nt),
                    a(&thdh, nt),
                    a(&tmhih, nt),
                    a(&self.l5, full as usize),
                    a(&l5n, 1),
                    nt as u32,
                    a(&acc, ACC_WORDS),
                );
            }
            if self.stop < 10 || self.stop - 10 >= 4 {
                dtops::tdigz2_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static((nt as u32).max(16128).div_ceil(NT), 1, 1),
                    CubeDim::new_1d(NT),
                    a(&tmh, nt),
                    a(&self.g_tdig, nt * 4),
                    a(&self.histh, 16128),
                    a(&self.lcnt, 1),
                    a(&tstat, 3),
                    nt as u32,
                    a(&acc, ACC_WORDS),
                );
            }
            if self.stop < 10 || self.stop - 10 >= 5 {
                dtops::toprec2_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static((nt as u32).div_ceil(NT), 1, 1),
                    CubeDim::new_1d(NT),
                    a(&thdh, nt),
                    a(&self.top_rec, nt * 8),
                    a(&tstat, 3),
                    (pip >> 6) as u32,
                    nt as u32,
                    a(&acc, ACC_WORDS),
                );
            }
        }
        let mut h2n = self.roots.len() as u32;
        if self.upto(2) {
            let src = if shared { self.anc_for(pip) } else { None };
            h2n = self.queue_parents(pip, rankh, &acc, src);
        }
        DevPrep {
            sb: SliceBufs {
                tmh,
                tsegh,
                thdh,
                tmhih,
            },
            tstat,
            acc,
            l5n,
            h2n,
        }
    }

    /// One slice alone with device tops (tests): counts, survivors as n,
    /// and the tops (h | d << 16, mask) the device made, read back per batch.
    ///
    /// # Errors
    /// Device errors or a failed account.
    pub fn run_slice_dev(
        &self,
        pip: u64,
        rank: &[u32; 8],
        max_batches: usize,
    ) -> Result<(DevCounts, Vec<u128>, Vec<(u32, u64)>)> {
        self.run_slice_dev_with(pip, rank, max_batches, false)
    }

    /// [`GpuJoin::run_slice_dev`]; with `shared`, the parents from the shared depth-8 list of the slice's digits
    /// 4–7 when one is built (tests: `build_anc` first).
    pub(crate) fn run_slice_dev_with(
        &self,
        pip: u64,
        rank: &[u32; 8],
        max_batches: usize,
        shared: bool,
    ) -> Result<(DevCounts, Vec<u128>, Vec<(u32, u64)>)> {
        let cnt = self.mk(vec![0u32; NCNT]);
        let rankh = self.mk(rank.to_vec());
        let DevPrep {
            sb,
            tstat,
            acc,
            l5n,
            h2n,
        } = self.queue_dev_prep(pip, &rankh, shared);
        let nt = self.caps.tops as usize;
        let mut tk = Vec::new();
        let mut v = Vec::new();
        cubecl::future::block_on(self.client.sync()).map_err(|e| anyhow!("sync: {e:?}"))?;
        let ntops = (self.rd(&tstat)?[0] as usize).min(nt);
        let thd = self.rd(&sb.thdh)?;
        let tmw = self.rd(&sb.tmh)?;
        let tops: Vec<(u32, u64)> = (0..ntops)
            .map(|i| {
                (
                    thd[i],
                    u64::from(tmw[2 * i]) | u64::from(tmw[2 * i + 1]) << 32,
                )
            })
            .collect();
        let pip_hi = pip >> 6;
        let nb = self.batches.len().min(max_batches);
        for bi in 0..nb {
            let mut t = self.queue_batch(pip, nt, &sb, bi, &cnt, &acc);
            if bi == 0 {
                t.tstat = Some(tstat.clone());
                t.head = Some(SliceHead {
                    pip,
                    acc: acc.clone(),
                    l5n: Some(l5n.clone()),
                    host_tops: None,
                    full: nb == self.batches.len(),
                    h2n,
                });
            }
            cubecl::future::block_on(self.client.sync()).map_err(|e| anyhow!("sync: {e:?}"))?;
            let n = self.rd(&t.scount)?[0] as usize;
            ensure!(n <= self.scap as usize, "run_slice_dev: list overflow");
            let list = self.rd(&self.surv)?;
            for i in 0..n {
                let x = thd[list[2 * i] as usize];
                let (h, d) = (u128::from(x & 0xFFFF), u128::from(x >> 16));
                let p = (h << 30) | (d << 24) | u128::from(pip_hi);
                v.push((p << 30) + u128::from(list[2 * i + 1]));
            }
            tk.push(t);
        }
        self.queue_done(&acc, &cnt);
        let dc = self.finish_group(&cnt, &tk)?;
        Ok((dc, v, tops))
    }

    /// Upload a slice's tops and queue its preparation.
    fn queue_prep(&self, st: &SliceTops) -> Result<(SliceBufs, Handle)> {
        let ntops = st.tmask.len();
        ensure!(
            ntops <= self.caps.tops as usize,
            "middle-out: slice {} has {ntops} tops > cap",
            st.pip
        );
        ensure!(
            st.maxpop <= MAXPOP,
            "middle-out: slice {} has a top of {} digits > {MAXPOP}",
            st.pip,
            st.maxpop
        );
        ensure!(
            st.maxprobe <= 2 * PMAX,
            "middle-out: slice {} has a job of {} probes > 2·{PMAX}",
            st.pip,
            st.maxprobe
        );
        let nt = ntops.max(1);
        let tm = unsafe {
            std::slice::from_raw_parts(st.tmask.as_ptr().cast::<u8>(), st.tmask.len() * 8)
        };
        let tmh = self
            .client
            .create_from_slice(if tm.is_empty() { &[0u8; 8] } else { tm });
        let tsegh = self.mk(st.tseg.clone());
        let rankh = self.mk(st.rank.to_vec());
        let thdh = self.mk(if st.thd.is_empty() {
            vec![0]
        } else {
            st.thd.clone()
        });
        let mh: &[u64] = if st.tmhi.is_empty() { &[0] } else { &st.tmhi };
        let tmhih = self.client.create_from_slice(unsafe {
            std::slice::from_raw_parts(mh.as_ptr().cast::<u8>(), mh.len() * 8)
        });
        let c = &self.client;
        let a = |h: &Handle, n: usize| unsafe { ArrayArg::from_raw_parts(h.clone(), n) };
        unsafe {
            prep::tdigz_kernel::launch_unchecked::<R>(
                c,
                CubeCount::Static((nt as u32).max(16128).div_ceil(NT), 1, 1),
                CubeDim::new_1d(NT),
                a(&tmh, nt),
                a(&self.g_tdig, nt * 4),
                a(&self.histh, 16128),
                a(&self.lcnt, 1),
                a(&self.slabz, 1),
                ntops as u32,
            );
            post::toprec_kernel::launch_unchecked::<R>(
                c,
                CubeCount::Static((nt as u32).div_ceil(NT), 1, 1),
                CubeDim::new_1d(NT),
                a(&thdh, nt),
                a(&self.top_rec, nt * 8),
                (st.pip >> 6) as u32,
                ntops as u32,
            );
        }
        let acc = self.mk(vec![0u32; ACC_WORDS]);
        self.queue_parents(st.pip, &rankh, &acc, None);
        Ok((
            SliceBufs {
                tmh,
                tsegh,
                thdh: thdh.clone(),
                tmhih,
            },
            acc,
        ))
    }

    /// Queue the slice's parents (histogram, scan, scatter, per-bucket sort;
    /// the `prep` kernels); `hist2` over every depth-4
    /// root, or over a shared depth-8 list `src`. Returns the roots
    /// `hist2` examines.
    fn queue_parents(
        &self,
        pip: u64,
        rankh: &Handle,
        acc: &Handle,
        src: Option<(Handle, u32)>,
    ) -> u32 {
        let c = &self.client;
        let np = self.caps.parents as usize;
        let (r4h, nroots) = src.unwrap_or_else(|| (self.r4h.clone(), self.roots.len() as u32));
        let a = |h: &Handle, n: usize| unsafe { ArrayArg::from_raw_parts(h.clone(), n) };
        unsafe {
            prep::hist2_kernel::launch_unchecked::<R>(
                c,
                CubeCount::Static(nroots.div_ceil(NT), 1, 1),
                CubeDim::new_1d(NT),
                a(&r4h, nroots as usize),
                a(rankh, 8),
                a(&self.histh, 16128),
                a(&self.g_lst, np),
                a(&self.g_lkey, np),
                a(&self.lcnt, 1),
                nroots,
                pip as u32,
                (pip >> 32) as u32,
                np as u32,
                self.fault,
                a(acc, ACC_WORDS),
                self.w,
            );
            prep::scan16_kernel::launch_unchecked::<R>(
                c,
                CubeCount::Static(1, 1, 1),
                CubeDim::new_1d(1024),
                a(&self.histh, 16128),
                a(&self.off, 16128),
                a(&self.curh, 16128),
                a(&self.g_pseg, 64),
                a(acc, ACC_WORDS),
            );
            prep::scatter3_kernel::launch_unchecked::<R>(
                c,
                CubeCount::Static((np as u32).div_ceil(NT), 1, 1),
                CubeDim::new_1d(NT),
                a(&self.g_lst, np),
                a(&self.g_lkey, np),
                a(&self.lcnt, 1),
                a(&self.curh, 16128),
                a(&self.g_tmp, np * 4),
                np as u32,
                a(acc, ACC_WORDS),
            );
            prep::hsort_kernel::launch_unchecked::<R>(
                c,
                CubeCount::Static(16128, 1, 1),
                CubeDim::new_1d(256),
                a(&self.off, 16128),
                a(&self.histh, 16128),
                a(&self.g_tmp, np * 4),
                a(&self.g_rec, np * 4),
                a(acc, ACC_WORDS),
            );
        }
        nroots
    }

    /// Queue one launch batch of a prepared slice.
    fn queue_batch(
        &self,
        pip: u64,
        nt: usize,
        sb: &SliceBufs,
        bi: usize,
        cnt: &Handle,
        acc: &Handle,
    ) -> Ticket {
        let (c0, _c1, jobs, nj) = &self.batches[bi];
        let c = &self.client;
        let np = self.caps.parents as usize;
        let nt = nt.max(1);
        let tsegh = &sb.tsegh;
        let a = |h: &Handle, n: usize| unsafe { ArrayArg::from_raw_parts(h.clone(), n) };
        {
            let slabn = self.mk(vec![0u32]);
            let scount = self.mk(vec![0u32]);
            let ran = self.mk(vec![0u32; RAN_WORDS]);
            let stat = self.mk(vec![0u32; STAT_WORDS]);
            let ns = self.nslab_cap as usize;
            unsafe {
                if self.upto(3) && self.fault & F_SKIP_MAIN == 0 {
                    kernels::g2_kernel::launch_unchecked::<R>(
                        c,
                        CubeCount::Static(*nj, 1, 1),
                        CubeDim::new_1d(NT),
                        a(&self.g_rec, np),
                        a(&self.g_pseg, 64),
                        a(&self.g_tdig, nt * 4),
                        a(tsegh, 64 * 63 * 2),
                        a(&self.roots_h, NROOT),
                        a(jobs, 2 * *nj as usize),
                        a(cnt, NCNT),
                        a(&self.out, ns * SLAB as usize),
                        a(&slabn, 1),
                        a(&self.slabcnt, ns),
                        self.ns_cap(),
                        a(&self.clst, self.lcap as usize),
                        *c0,
                        self.fault,
                        a(acc, ACC_WORDS),
                        self.lcap,
                        self.w,
                        self.fill,
                    );
                }
                if self.upto(5) {
                    post::expand_kernel::launch_unchecked::<R>(
                        c,
                        CubeCount::Static(EXPAND_CUBES, 1, 1),
                        CubeDim::new_1d(NT),
                        a(&self.out, ns * SLAB as usize),
                        a(&slabn, 1),
                        a(&self.slabcnt, ns),
                        a(&self.clst, self.lcap as usize),
                        a(&self.lcnt, 1),
                        a(&sb.thdh, nt),
                        a(&sb.tmhih, nt),
                        a(&self.surv, 2 * self.scap as usize),
                        a(&scount, 1),
                        a(&stat, STAT_WORDS),
                        self.ns_cap(),
                        self.s_cap(),
                        ((pip & 63) as u32) << 24,
                        (pip >> 6) as u32,
                        self.fault,
                        self.oh64,
                    );
                }
                if self.upto(6) && self.fault & F_SKIP_CHECK == 0 {
                    check_kernel::launch_unchecked::<R>(
                        c,
                        CubeCount::Static(CHECK_CUBES, 1, 1),
                        CubeDim::new_1d(CHECK_WG),
                        a(&self.surv, 2 * self.scap as usize),
                        a(&scount, 1),
                        a(&self.top_rec, nt * 8),
                        a(&self.nice_out, self.caps.nice as usize * NICE_STRIDE),
                        a(&self.nice_count, 1),
                        a(&ran, RAN_WORDS),
                        self.s_cap(),
                        self.caps.nice,
                        self.check,
                        if self.caps.probe {
                            crate::cubecl_join::CHECK_PROBE
                        } else {
                            crate::cubecl_join::CHECK_HITS
                        },
                        self.ballot,
                    );
                }
            }
            Ticket {
                ran,
                scount,
                stat,
                tstat: None,
                jobs: *nj,
                head: None,
            }
        }
    }

    /// Synchronise, read a group's counters and tickets, check every
    /// account: kernel error counters zero, every batch's list within its
    /// cap and checked exactly once per entry, parents and slabs within caps,
    /// the survivors the kernel counted = the bits the prefilter read, and
    /// per slice the positive evidence of its account (`check_slice`). The
    /// slices returned are those the device reports done, and they must be
    /// the slices queued.
    fn finish_group(&self, cnt: &Handle, tickets: &[Ticket]) -> Result<DevCounts> {
        cubecl::future::block_on(self.client.sync()).map_err(|e| anyhow!("sync: {e:?}"))?;
        if self.stop != 6 {
            return Ok(DevCounts::default());
        }
        // every small buffer of the group in one read (in this order: cnt; per ticket scount, ran, stat, its
        // tstat, its slice's acc and l5n)
        let mut hs = vec![cnt.clone()];
        for t in tickets {
            hs.extend([t.scount.clone(), t.ran.clone(), t.stat.clone()]);
            if let Some(ts) = &t.tstat {
                hs.push(ts.clone());
            }
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
                .ok_or_else(|| anyhow!("middle-out: {nh} buffers read, fewer returned"))
        };
        let v = next()?;
        ensure!(
            v[C_ERR_PLANE] == 0
                && v[C_ERR_PMAX] == 0
                && v[C_ERR_SLAB] == 0
                && v[C_ERR_IDX] == 0
                && v[C_ERR_CLST] == 0,
            "middle-out kernel errors: plane {} pmax {} slab {} class index {} child list {}",
            v[C_ERR_PLANE],
            v[C_ERR_PMAX],
            v[C_ERR_SLAB],
            v[C_ERR_IDX],
            v[C_ERR_CLST]
        );
        let mut dc = DevCounts::default();
        for d in 0..64 {
            dc.children += v[d * 5] as u64;
            dc.chunks += v[d * 5 + 1] as u64;
            dc.flat += v[d * 5 + 2] as u64;
            dc.kept += v[d * 5 + 3] as u64;
            dc.survivors += v[d * 5 + 4] as u64;
            dc.flat_d_max = dc.flat_d_max.max(v[d * 5 + 2] as u64);
            dc.surv_d_max = dc.surv_d_max.max(v[d * 5 + 4] as u64);
        }
        let mut listed = 0u64;
        let mut stats = Vec::with_capacity(tickets.len());
        let mut accs = Vec::new();
        for t in tickets {
            let n = next()?[0];
            ensure!(
                n <= self.s_cap(),
                "middle-out: survivor list overflow {n} > {}",
                self.s_cap()
            );
            let ran = next()?;
            let st = next()?;
            let want_sum = (u64::from(n) * u64::from(n.saturating_sub(1)) / 2 % (1 << 32)) as u32;
            ensure!(
                ran[5] == n && ran[6] == want_sum,
                "middle-out: check incomplete: {} of {n} entries, index sum {} (want {want_sum})",
                ran[5],
                ran[6]
            );
            let mut ntops = None;
            if t.tstat.is_some() {
                let v = next()?;
                ensure!(
                    v[0] <= self.caps.tops,
                    "middle-out: {} tops > cap {}",
                    v[0],
                    self.caps.tops
                );
                ensure!(
                    v[1] == 0,
                    "middle-out: {} tops of more than {MAXPOP} digits",
                    v[1]
                );
                dc.tops += u64::from(v[0]);
                dc.tested += u64::from(v[2]);
                ntops = Some(v[0]);
            }
            if let Some(h) = &t.head {
                let a = next()?;
                let l = if h.l5n.is_some() { Some(next()?) } else { None };
                accs.push((a, l));
            }
            ensure!(
                st[0] <= self.caps.parents,
                "middle-out: {} parents > cap {}",
                st[0],
                self.caps.parents
            );
            ensure!(
                st[1] <= self.ns_cap(),
                "middle-out: {} slabs > cap {}",
                st[1],
                self.ns_cap()
            );
            // the expansion ran: every cube to its end, every used slab walked
            ensure!(
                st[3] == EXPAND_CUBES && st[4] == st[1].min(self.ns_cap()),
                "middle-out: expansion ran {} of {EXPAND_CUBES} cubes, walked {} of {} slabs",
                st[3],
                st[4],
                st[1]
            );
            listed += u64::from(st[2]);
            dc.slabs_max = dc.slabs_max.max(u64::from(st[1]));
            dc.list_max = dc.list_max.max(u64::from(n));
            dc.checked += u64::from(ran[5]);
            stats.push((st, ntops, ran[5]));
        }
        ensure!(
            listed == dc.survivors,
            "middle-out: {listed} survivors read by the prefilter, the kernel counted {}",
            dc.survivors
        );
        // per slice: its tickets are consecutive, the first carries its head
        let mut heads = 0u64;
        let mut accs = accs.into_iter();
        let mut i = 0;
        while i < tickets.len() {
            let head = tickets[i]
                .head
                .as_ref()
                .ok_or_else(|| anyhow!("middle-out: a launch batch without its slice"))?;
            let mut j = i + 1;
            while j < tickets.len() && tickets[j].head.is_none() {
                j += 1;
            }
            let jobs: u64 = tickets[i..j].iter().map(|t| u64::from(t.jobs)).sum();
            let ((Some(ntops), _) | (None, Some(ntops))) = (stats[i].1, head.host_tops) else {
                bail!("middle-out: slice {} without a top count", head.pip)
            };
            let (a, l) = accs
                .next()
                .ok_or_else(|| anyhow!("middle-out: a slice without its account"))?;
            self.check_slice(head, &a, l.as_deref(), jobs, ntops, stats[i].0[0])?;
            {
                let mut w = self.watch.lock().expect("watch");
                if w.0 == Some(head.pip) {
                    // the slice's own counts in this run: bits the expansion read, entries the check took
                    let surv = stats[i..j].iter().map(|x| u64::from(x.0[2])).sum();
                    let chk = stats[i..j].iter().map(|x| u64::from(x.2)).sum();
                    w.1 = Some((surv, chk));
                }
            }
            heads += 1;
            i = j;
        }
        // the slices the device ran to their last kernel, not the host's loop
        dc.slices = u64::from(v[C_SLICES]);
        ensure!(
            dc.slices == heads,
            "middle-out: {} slices done on the device, {heads} queued",
            dc.slices
        );
        Ok(dc)
    }

    /// One slice's account `a` (`A_*`; `l5n`, its 64-slice level's) against what the host queued: `jobs`
    /// main-kernel instances, `ntops` tops (the device's own count or the
    /// host's), `lcnt` parents (the expansion's copy of the list length).
    // reads nothing of the join now (the hist2 grid comes with the head)
    #[allow(clippy::unused_self)]
    fn check_slice(
        &self,
        h: &SliceHead,
        a: &[u32],
        l5n: Option<&[u32]>,
        jobs: u64,
        ntops: u32,
        lcnt: u32,
    ) -> Result<()> {
        let pip = h.pip;
        let fail = |what: &str, got: u64, want: u64| -> Result<()> {
            ensure!(
                got == want,
                "middle-out: slice {pip}: {what}: {got}, want {want} (account {a:?})"
            );
            Ok(())
        };
        fail("plane errors", u64::from(a[A_ERR_PLANE]), 0)?;
        fail("slice done", u64::from(a[A_DONE]), 1)?;
        if let Some(l) = l5n {
            fail(
                "tops5 cubes done",
                u64::from(l[1]),
                u64::from((1u32 << 21) / NT),
            )?;
            fail(
                "tops1 valid parents examined",
                u64::from(a[A_T1_EXAM]),
                u64::from(l[0]),
            )?;
            fail(
                "tops1 tops certified",
                u64::from(a[A_T1_CERT]),
                u64::from(ntops),
            )?;
            fail("tscan ran", u64::from(a[A_TSCAN]), 1)?;
            fail(
                "tops2 tops placed",
                u64::from(a[A_T2_PLACED]),
                u64::from(ntops),
            )?;
            fail("tdigz2 rows", u64::from(a[A_TDIG]), u64::from(ntops))?;
            fail("toprec2 rows", u64::from(a[A_TREC]), u64::from(ntops))?;
        }
        fail(
            "hist2 cubes done",
            u64::from(a[A_H2_CUBES]),
            u64::from(h.h2n.div_ceil(NT)),
        )?;
        fail(
            "parents certified (hist2) = listed",
            u64::from(a[A_H2_CERT]),
            u64::from(lcnt),
        )?;
        fail("scan16 ran", u64::from(a[A_SCAN16]), 1)?;
        fail("scatter3 rows", u64::from(a[A_SCAT]), u64::from(lcnt))?;
        fail("hsort cubes done", u64::from(a[A_HSORT]), 16128)?;
        fail("main-kernel job instances done", u64::from(a[A_JOBS]), jobs)?;
        if h.full {
            // every top is a probe of exactly one job per root (8), over the job's two instances
            fail(
                "probes run = 8 x tops",
                u64::from(a[A_PROBES]),
                8 * u64::from(ntops),
            )?;
            fail(
                "children seen by the main kernel = counted in the preparation",
                u64::from(a[A_CHILD]),
                u64::from(a[A_SC_CHILD]),
            )?;
        }
        Ok(())
    }

    /// The nice numbers the check has written so far, ascending.
    pub(crate) fn nice(&self) -> Result<Vec<u128>> {
        let n = self.rd(&self.nice_count)?[0] as usize;
        ensure!(
            n <= self.caps.nice as usize,
            "middle-out: nice output overflow {n}"
        );
        let w = self.rd(&self.nice_out)?;
        let mut v: Vec<u128> = (0..n)
            .map(|i| {
                let o = i * NICE_STRIDE;
                (u128::from(w[o]) | u128::from(w[o + 1]) << 32)
                    | (u128::from(w[o + 2]) | u128::from(w[o + 3]) << 32) << 64
            })
            .collect();
        v.sort_unstable();
        Ok(v)
    }

    /// One slice alone (tests): its counts and its survivor list as n,
    /// read back after each launch batch.
    ///
    /// # Errors
    /// Device errors or a failed account.
    pub fn run_slice(&self, st: &SliceTops) -> Result<(DevCounts, Vec<u128>)> {
        let cnt = self.mk(vec![0u32; NCNT]);
        let (sb, acc) = self.queue_prep(st)?;
        let mut tk = Vec::new();
        let mut v = Vec::new();
        let pip_hi = st.pip >> 6;
        for bi in 0..self.batches.len() {
            let mut t = self.queue_batch(st.pip, st.tmask.len(), &sb, bi, &cnt, &acc);
            if bi == 0 {
                t.head = Some(SliceHead {
                    pip: st.pip,
                    acc: acc.clone(),
                    l5n: None,
                    host_tops: Some(st.tmask.len() as u32),
                    full: true,
                    h2n: self.roots.len() as u32,
                });
            }
            cubecl::future::block_on(self.client.sync()).map_err(|e| anyhow!("sync: {e:?}"))?;
            let n = self.rd(&t.scount)?[0] as usize;
            ensure!(n <= self.scap as usize, "run_slice: list overflow");
            let list = self.rd(&self.surv)?;
            for i in 0..n {
                let x = st.thd[list[2 * i] as usize];
                let (h, d) = (u128::from(x & 0xFFFF), u128::from(x >> 16));
                let p = (h << 30) | (d << 24) | u128::from(pip_hi);
                v.push((p << 30) + u128::from(list[2 * i + 1]));
            }
            tk.push(t);
        }
        self.queue_done(&acc, &cnt);
        let dc = self.finish_group(&cnt, &tk)?;
        Ok((dc, v))
    }
}

/// How a field is run on the device ([`GpuOptions::new`]).
#[derive(Clone, Copy, Debug)]
pub struct GpuOptions {
    /// Slices per synchronisation.
    pub group: usize,
    /// Host threads making tops (in parallel with the device), when the
    /// tops are made on the host.
    pub(crate) host_threads: usize,
    /// Tops on the device (the only form outside the benches: the host-tops path has no tops accounts, and a
    /// host of a few cores cannot keep up with a card).
    pub(crate) device_tops: bool,
    /// The sampled CPU check: one random slice of the field recomputed by
    /// the CPU reference on a host thread while the card works; the field
    /// run's own survivors and checked for that slice must equal the CPU's,
    /// and the slice run again alone on the device at the end must give the
    /// same prefiltered list, n for n. The only check that sees a kernel
    /// computing wrongly (the accounts see only work that did not run).
    pub cpu_check: bool,
    /// Threads for the sampled check's CPU slice; 0 for [`sample_threads`]' default.
    pub(crate) cpu_threads: usize,
}

impl GpuOptions {
    /// Device tops, `group` slices per synchronisation, the sampled CPU check on or off.
    pub fn new(group: usize, cpu_check: bool) -> Self {
        Self {
            group,
            host_threads: 1,
            device_tops: true,
            cpu_check,
            cpu_threads: 0,
        }
    }

    /// The sampled check's CPU slice on `threads` threads (0: [`sample_threads`]' default).
    #[must_use]
    pub fn with_cpu_threads(self, threads: usize) -> Self {
        Self {
            cpu_threads: threads,
            ..self
        }
    }

    /// **Benches only** (feature `midout-bench`): the slices' tops made on `threads` host threads instead of on
    /// the device. This path has no tops accounts (a dropped top is not seen by any count); it is kept to time
    /// the device's tops against.
    #[cfg(feature = "midout-bench")]
    #[must_use]
    pub fn with_host_tops(self, threads: usize) -> Self {
        Self {
            host_threads: threads,
            device_tops: false,
            ..self
        }
    }
}

/// Threads for the sampled check's CPU slice: `requested`, or if it is 0,
/// the CPUs this process may use less one (left to the thread that queues
/// the device's work), at most [`SAMPLE_THREADS_MAX`], at least 1.
#[must_use]
pub fn sample_threads(requested: usize) -> usize {
    if requested > 0 {
        return requested;
    }
    let cpus = std::thread::available_parallelism().map_or(1, std::num::NonZero::get);
    cpus.saturating_sub(1).clamp(1, SAMPLE_THREADS_MAX)
}

/// The most threads the sampled check's CPU slice takes by default.
pub const SAMPLE_THREADS_MAX: usize = 4;

/// The sampled check of one slice: the CPU reference on `threads` threads
/// (survivors, checked, the prefiltered list, sorted).
fn cpu_slice(coord: &Coord, pip: u64, threads: usize) -> (u64, u64, Vec<u128>) {
    let base = super::cpu::Base::new(coord);
    let mut pass = Vec::new();
    let cn = super::cpu::slice_join_threads::<u64>(
        &base,
        Shape::for_coord(coord),
        u128::from(pip),
        threads,
        |_, n, p| {
            if p {
                pass.push(n);
            }
        },
    );
    pass.sort_unstable();
    (cn.survivors, cn.checked, pass)
}

/// The device half of the sampled check: slice `pip` alone (key `rank`)
/// against the CPU reference's `(survivors, checked, list)`.
///
/// # Errors
/// Any difference, or a failed account of the device run.
pub(crate) fn sample_compare<R: Runtime>(
    gj: &GpuJoin<R>,
    pip: u64,
    rank: &[u32; 8],
    cpu: &(u64, u64, Vec<u128>),
) -> Result<()> {
    // the slice's counts as the field run made them (if it was watched), then the slice again alone
    let in_field = std::mem::take(&mut *gj.watch.lock().expect("watch")).1;
    if let Some((s, c)) = in_field {
        ensure!(
            s == cpu.0 && c == cpu.1,
            "middle-out: sampled CPU check of slice {pip}: the field run counted survivors {s} checked {c}, \
             CPU survivors {} checked {}",
            cpu.0,
            cpu.1
        );
    }
    let (dc, mut got, _) = gj.run_slice_dev(pip, rank, usize::MAX)?;
    got.sort_unstable();
    ensure!(
        dc.survivors == cpu.0 && dc.checked == cpu.1 && got == cpu.2,
        "middle-out: sampled CPU check of slice {pip} differs: device survivors {} checked {} list {}, \
         CPU survivors {} checked {} list {}",
        dc.survivors,
        dc.checked,
        got.len(),
        cpu.0,
        cpu.1,
        cpu.2.len()
    );
    Ok(())
}

/// Search a base-64 field on the device: the field's slices queued, one
/// synchronisation per `group` slices, every account checked; with
/// `cpu_check`, one random slice also recomputed on the CPU. Returns the
/// outcome (nice numbers, survivors, checked) and the device's counts,
/// with timings.
///
/// # Errors
/// A field that is not whole quanta of base 64, a join with a timing stop
/// set, any failed account, or a sampled check that differs.
pub fn search_field<R: Runtime>(
    gj: &GpuJoin<R>,
    coord: &Coord,
    v_start: u128,
    v_size: u128,
    opt: GpuOptions,
) -> Result<(FieldOutcome, DevCounts, FieldTiming)> {
    ensure!(
        gj.stop == 6,
        "middle-out: a timing stop ({}) is set: this join only times stages",
        gj.stop
    );
    field_run(gj, coord, v_start, v_size, opt, None, None)
}

/// (tests) [`search_field`] on the slices `sel` of the field's slice list,
/// returning each group's slices and the device's counts for it (one slice
/// per group with `opt.group` 1): the field path, slice by slice.
pub(crate) type GroupCounts = Vec<(Vec<u64>, DevCounts)>;

/// See [`GroupCounts`].
///
/// # Errors
/// As [`search_field`].
#[cfg(all(test, feature = "midout-box-tests"))]
pub(crate) fn search_field_groups<R: Runtime>(
    gj: &GpuJoin<R>,
    coord: &Coord,
    v_start: u128,
    v_size: u128,
    opt: GpuOptions,
    sel: std::ops::Range<usize>,
) -> Result<(FieldOutcome, GroupCounts)> {
    ensure!(gj.stop == 6, "middle-out: a timing stop is set");
    let mut rec = Vec::new();
    let (o, _, _) = field_run(gj, coord, v_start, v_size, opt, Some(sel), Some(&mut rec))?;
    Ok((o, rec))
}

/// **Part of a field** (benches, feature `midout-bench`): [`search_field`] on the field's first `max_slices` slices
/// only (dry runs on a software device: a field is 4,096 slices). The outcome and the counts cover those slices
/// only, so the result is not a field's and must never be submitted; the sampled check draws among them.
///
/// # Errors
/// As [`search_field`].
#[cfg(feature = "midout-bench")]
pub fn search_field_part<R: Runtime>(
    gj: &GpuJoin<R>,
    coord: &Coord,
    v_start: u128,
    v_size: u128,
    opt: GpuOptions,
    max_slices: usize,
) -> Result<(FieldOutcome, DevCounts, FieldTiming)> {
    ensure!(
        gj.stop == 6,
        "middle-out: a timing stop ({}) is set: this join only times stages",
        gj.stop
    );
    field_run(
        gj,
        coord,
        v_start,
        v_size,
        opt,
        Some(0..max_slices.max(1)),
        None,
    )
}

/// **Timing only** (benches, feature `midout-bench`): [`time_field`] on the field's first `max_slices` slices only.
///
/// # Errors
/// As [`time_field`].
#[cfg(feature = "midout-bench")]
pub fn time_field_part<R: Runtime>(
    gj: &GpuJoin<R>,
    coord: &Coord,
    v_start: u128,
    v_size: u128,
    opt: GpuOptions,
    max_slices: usize,
) -> Result<FieldTiming> {
    let opt = GpuOptions {
        cpu_check: false,
        ..opt
    };
    Ok(field_run(
        gj,
        coord,
        v_start,
        v_size,
        opt,
        Some(0..max_slices.max(1)),
        None,
    )?
    .2)
}

/// **Timing only** (benches, feature `midout-bench`): time a field with the join's timing stop: the stages up to
/// the stop are queued, no account is checked and no result is returned.
///
/// # Errors
/// A field that is not whole quanta of base 64, or a device error.
#[cfg(feature = "midout-bench")]
pub fn time_field<R: Runtime>(
    gj: &GpuJoin<R>,
    coord: &Coord,
    v_start: u128,
    v_size: u128,
    opt: GpuOptions,
) -> Result<FieldTiming> {
    let opt = GpuOptions {
        cpu_check: false,
        ..opt
    };
    Ok(field_run(gj, coord, v_start, v_size, opt, None, None)?.2)
}

fn field_run<R: Runtime>(
    gj: &GpuJoin<R>,
    coord: &Coord,
    v_start: u128,
    v_size: u128,
    opt: GpuOptions,
    sel: Option<std::ops::Range<usize>>,
    mut rec: Option<&mut GroupCounts>,
) -> Result<(FieldOutcome, DevCounts, FieldTiming)> {
    ensure!(coord.b() == 64, "middle-out device path: base 64 only");
    let sh = Shape::for_coord(coord);
    ensure!(
        sh == (Shape { f0: 4, k: 10 }),
        "middle-out device path: shape (4, 10) only"
    );
    sh.fits(coord)?;
    // the per-unit counters are u32 per group: about 900 slices of the largest observed flat count wrap them
    ensure!(
        (1..=256).contains(&opt.group),
        "middle-out: group of {} slices (1-256)",
        opt.group
    );
    let ts = coord.field_digits(v_start, v_size)?;
    let mut pips: Vec<u64> = ts
        .flat_map(|t| sh.slices_of(coord, t).map(|p| p as u64).collect::<Vec<_>>())
        .collect();
    if let Some(r) = sel {
        let end = r.end.min(pips.len());
        ensure!(
            r.start < end,
            "middle-out: slices {r:?} of a field of {}",
            pips.len()
        );
        pips = pips[r.start..end].to_vec();
    }
    let nice_before = gj.nice()?;
    let t0 = Instant::now();
    // the sampled CPU check: a random slice of the field, on a host thread while the card works
    let sample = if opt.cpu_check {
        use std::hash::{BuildHasher, Hasher};
        let mut hs = std::collections::hash_map::RandomState::new().build_hasher();
        hs.write_u128(v_start);
        let pip = pips[(hs.finish() % pips.len() as u64) as usize];
        *gj.watch.lock().expect("watch") = (Some(pip), None);
        let c = coord.clone();
        let threads = sample_threads(opt.cpu_threads);
        Some((
            pip,
            std::thread::spawn(move || {
                let t = Instant::now();
                let r = cpu_slice(&c, pip, threads);
                (r, t.elapsed().as_secs_f64())
            }),
        ))
    } else {
        None
    };
    let mut total = DevCounts::default();
    let mut host_wait = 0f64;
    let mut sync_s = 0f64;
    // the key from the field's first slice on the host (it only orders the parents: any key is exact)
    let rank = slice_tops(pips[0], gj.roots()).rank;
    if opt.device_tops {
        // the parents' shared depth-8 lists, when the field's slices repeat their digits 4-7
        gj.anc.lock().expect("anc").keys.clear();
        if gj.share8 && gj.upto(2) {
            let mut keys: Vec<u32> = Vec::new();
            for &p in &pips {
                let k = (p & 0xFF_FFFF) as u32;
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
        host_wait = t0.elapsed().as_secs_f64();
        let rankh = gj.mk(rank.to_vec());
        let mut done = 0usize;
        while done < pips.len() {
            let cnt = gj.mk(vec![0u32; NCNT]);
            let mut tk = Vec::new();
            let k0 = done;
            while done < pips.len() && done - k0 < opt.group {
                gj.queue_dev(pips[done], &rankh, &cnt, &mut tk);
                done += 1;
            }
            let tsync = Instant::now();
            let g = gj.finish_group(&cnt, &tk)?;
            sync_s += tsync.elapsed().as_secs_f64();
            total.add(&g);
            if let Some(r) = rec.as_mut() {
                r.push((pips[k0..done].to_vec(), g));
            }
        }
    } else {
        let next = AtomicUsize::new(0);
        let (tx, rx) = mpsc::sync_channel::<SliceTops>(2 * opt.host_threads.max(1) + opt.group);
        let roots = gj.roots();
        let res: Result<()> = std::thread::scope(|s| {
            let rx = rx;
            for _ in 0..opt.host_threads.max(1) {
                let tx = tx.clone();
                let (next, pips) = (&next, &pips);
                s.spawn(move || {
                    loop {
                        let i = next.fetch_add(1, Ordering::Relaxed);
                        if i >= pips.len() {
                            break;
                        }
                        if tx.send(slice_tops(pips[i], roots)).is_err() {
                            break;
                        }
                    }
                });
            }
            drop(tx);
            let mut done = 0usize;
            while done < pips.len() {
                let cnt = gj.mk(vec![0u32; NCNT]);
                let mut tk = Vec::new();
                let mut g = DevCounts::default();
                let mut k = 0;
                while k < opt.group && done < pips.len() {
                    let tw = Instant::now();
                    let st = rx
                        .recv()
                        .map_err(|_| anyhow!("middle-out: top workers ended early"))?;
                    host_wait += tw.elapsed().as_secs_f64();
                    g.tops += st.tmask.len() as u64;
                    g.tested += st.tested;
                    gj.queue(&st, &cnt, &mut tk)?;
                    k += 1;
                    done += 1;
                }
                let tsync = Instant::now();
                let dc = gj.finish_group(&cnt, &tk)?;
                sync_s += tsync.elapsed().as_secs_f64();
                g.add(&dc);
                total.add(&g);
            }
            Ok(())
        });
        res?;
    }
    let field_s = t0.elapsed().as_secs_f64();
    gj.anc.lock().expect("anc").keys.clear();
    // the field's nice numbers, before the sampled slice runs again
    let nice_all = gj.nice()?;
    let mut nice = nice_all;
    for n in &nice_before {
        if let Some(i) = nice.iter().position(|x| x == n) {
            nice.remove(i);
        }
    }
    // every nice number the device reports must be nice and in the field
    for &n in &nice {
        ensure!(
            super::arith::unique_digits(n, 64).1,
            "middle-out: device reported {n}, not nice"
        );
        ensure!(
            n >= coord.start()
                && n < coord.end()
                && (v_start..v_start + v_size).contains(&coord.v_of_n(n)),
            "middle-out: device reported {n}, not in the field"
        );
    }
    // the slices the device reports done (each slice's last kernel), against the field's
    if gj.stop == 6 && total.slices != pips.len() as u64 {
        bail!("middle-out: {} of {} slices", total.slices, pips.len());
    }
    let (mut cpu_s, mut cpu_wait, mut sample_s, mut sampled) = (0f64, 0f64, 0f64, None);
    if let Some((pip, h)) = sample {
        let tw = Instant::now();
        let (r, s) = h
            .join()
            .map_err(|_| anyhow!("middle-out: the sampled CPU check panicked"))?;
        cpu_wait = tw.elapsed().as_secs_f64();
        cpu_s = s;
        ensure!(
            gj.watch.lock().expect("watch").1.is_some(),
            "middle-out: the sampled slice {pip} was not seen in the field run"
        );
        let td = Instant::now();
        sample_compare(gj, pip, &rank, &r)?;
        sample_s = td.elapsed().as_secs_f64();
        sampled = Some(pip);
        // the sampled slice's nice numbers were reported twice into the device's buffer; the next field's
        // `nice_before` removes them again
    }
    let wall = t0.elapsed().as_secs_f64();
    let out = FieldOutcome {
        nice,
        survivors: total.survivors,
        checked: total.checked,
        slices: total.slices,
    };
    Ok((
        out,
        total,
        FieldTiming {
            wall,
            host_wait,
            sync: sync_s,
            field: field_s,
            cpu_check: cpu_s,
            cpu_wait,
            sample_dev: sample_s,
            sampled,
        },
    ))
}

/// Where a field's time went (host side).
#[derive(Clone, Copy, Debug, Default)]
pub struct FieldTiming {
    pub wall: f64,
    /// The device thread waiting for tops.
    pub host_wait: f64,
    /// Synchronisations and reads at group ends.
    pub sync: f64,
    /// The field's slices alone (wall less the sampled check's tail).
    pub field: f64,
    /// The sampled CPU check: the CPU thread's time, the host's wait for
    /// it after the field, the device's rerun of the slice, and the slice.
    pub cpu_check: f64,
    pub cpu_wait: f64,
    pub sample_dev: f64,
    pub sampled: Option<u64>,
}

#[cfg(test)]
#[cfg(test)]
#[path = "audit.rs"]
mod audit;

#[cfg(test)]
mod tests {
    use super::*;
    use crate::midout::cpu::{Base, slice_join, top_cert, top_cert_split, unit_tops};

    #[test]
    fn top_cert_b64_equals_the_reference() {
        let coord = Coord::for_base(64).unwrap();
        let base = Base::new(&coord);
        let mut x = 0x1234_5678_9abc_def1u64;
        let mut n_some = 0;
        for i in 0..20_000u64 {
            x ^= x << 13;
            x ^= x >> 7;
            x ^= x << 17;
            let h = H_LO + x % (H_HI - H_LO);
            let low = (x >> 20) & ((1 << 36) - 1);
            let p = (h << 36) | if i % 2 == 0 { low } else { low & !0xFFF };
            let a = (p as u128) << 24;
            let c = a + (1 << 24) - 1;
            let want = top_cert::<u64>(&base, a, c, 10);
            assert_eq!(top_cert_b64(a, c), want, "p {p}");
            assert_eq!(
                top_cert_b64_split(a, c),
                top_cert_split::<u64>(&base, a, c, 10, 12),
                "p {p}: prefilter mask"
            );
            n_some += usize::from(want.is_some());
        }
        assert!(n_some > 1000);
    }

    #[test]
    fn slice_tops_equal_the_reference_units() {
        let coord = Coord::for_base(64).unwrap();
        let base = Base::new(&coord);
        let pip = 712_012_851u64;
        let st = slice_tops(pip, &[]);
        for d in [0u64, 17, 63] {
            let mut tested = 0;
            let want = unit_tops::<u64>(
                &base,
                Shape { f0: 4, k: 10 },
                u128::from(pip + (d << 30)),
                &mut tested,
            );
            let mut got: Vec<(u128, u64, u64)> = (0..st.tmask.len())
                .filter(|&i| u64::from(st.thd[i] >> 16) == d)
                .map(|i| (u128::from(st.thd[i] & 0xFFFF), st.tmask[i], st.tmhi[i]))
                .collect();
            got.sort_unstable();
            let w: Vec<(u128, u64, u64)> = want.iter().map(|t| (t.h, t.mask, t.mhi)).collect();
            assert_eq!(got, w, "unit {d}");
        }
        assert_eq!(st.tmask.len(), 238_813);
        assert_eq!(st.tested, 1 << 21);
    }

    /// Production's check, in its probe mode, rebuilds from our list entries
    /// and top records exactly the n of the survivors (one class of a slice).
    #[test]
    #[ignore = "needs a GPU (lavapipe will do; MIDOUT_CUDA=1 for CUDA)"]
    fn cubecl_midout_check_rebuilds_the_survivors() {
        let ctx = device().expect("a device");
        let pip = 712_012_851u64;
        macro_rules! go {
            ($client:expr) => {{
                let caps = Caps {
                    classes: 1,
                    nice: 1 << 19,
                    probe: true,
                    ..Caps::b64(1)
                };
                let gj = GpuJoin::new($client, caps).unwrap();
                let st = slice_tops(pip, gj.roots());
                let (dc, mut got, _) = gj.run_slice_dev(pip, &st.rank, 1).unwrap();
                got.sort_unstable();
                let rebuilt = gj.nice().unwrap();
                println!(
                    "class 0 of slice {pip}: {} survivors, the check rebuilt {}",
                    got.len(),
                    rebuilt.len()
                );
                assert_eq!(dc.checked, got.len() as u64);
                assert!(rebuilt == got, "the check's n differ from the survivors");
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

    /// The parents' root pass shared across digit 8 (`set_parent_sharing`): the first `MIDOUT_SHARE_SLICES`
    /// (128) slices of a `(4, 8, 5)` field (64 values of digit 4 × 2 of digit 8: every depth-8 list serves two
    /// slices), one slice per group, give every slice's counts (kept included: same key) equal with and without
    /// sharing; with sharing on, each fault is loud (`F_SKIP_ANC` new; `F_SKIP_MAIN`, `F_SKIP_TOPS`,
    /// `F_DROP_PROBE`, `F_DROP_PARENT` as without sharing), and a clean run after each gives the clean counts.
    #[cfg(feature = "midout-box-tests")]
    #[test]
    #[ignore = "needs a GPU (MIDOUT_CUDA=1 for the CUDA runtime)"]
    fn field_parent_sharing_is_exact_and_loud() {
        let ctx = device().expect("a device");
        let tn: u128 = std::env::var("MIDOUT_485_T")
            .ok()
            .map_or(77_777, |s| s.parse().unwrap());
        let nsl: usize = std::env::var("MIDOUT_SHARE_SLICES")
            .ok()
            .map_or(128, |s| s.parse().unwrap());
        let classes: u32 = std::env::var("MIDOUT_CLASSES")
            .ok()
            .map_or(63, |s| s.parse().unwrap());
        let cn = Coord::with_digits(64, 4, 8, 5).unwrap();
        let (q, vs) = (cn.quantum(), cn.start() + tn * cn.quantum());
        macro_rules! go {
            ($client:expr) => {{
                let mut gj = GpuJoin::new($client, Caps::b64(classes)).unwrap();
                gj.set_parent_sharing(false);
                let opt1 = GpuOptions { group: 1, host_threads: 1, device_tops: true, cpu_check: false, cpu_threads: 0 };
                let opt16 = GpuOptions { group: 16, ..opt1 };
                let (o0, r0) = search_field_groups(&gj, &cn, vs, q, opt1, 0..nsl).unwrap();
                gj.set_parent_sharing(true);
                let (o1, r1) = search_field_groups(&gj, &cn, vs, q, opt1, 0..nsl).unwrap();
                let (nl, listed) = gj.parent_sharing_last();
                println!(
                    "{nsl} slices of (4, 8, 5) field {tn}: {nl} depth-8 lists, {listed} roots listed ({:.1} % of {} per list)",
                    100.0 * listed as f64 / (nl as f64 * gj.roots().len() as f64),
                    gj.roots().len()
                );
                assert!(nl >= 1 && nl < nsl);
                assert_eq!(r0.len(), r1.len());
                for ((p0, c0), (p1, c1)) in r0.iter().zip(&r1) {
                    assert_eq!(p0, p1);
                    // every count (the audit's maxima, e.g. slabs, depend on the order of atomics: not compared)
                    let k = |c: &DevCounts| {
                        (c.children, c.chunks, c.flat, c.kept, c.survivors, c.checked, c.slices, c.tops, c.tested)
                    };
                    assert_eq!(k(c0), k(c1), "slice {p0:?}: shared parents differ: {c0:?} vs {c1:?}");
                }
                assert_eq!((o0.survivors, o0.checked, o0.slices), (o1.survivors, o1.checked, o1.slices));
                println!("equal slice by slice with and without sharing: survivors {}, checked {}", o1.survivors, o1.checked);
                for (name, f) in [
                    ("F_SKIP_ANC", F_SKIP_ANC),
                    ("F_SKIP_MAIN", F_SKIP_MAIN),
                    ("F_SKIP_TOPS", F_SKIP_TOPS),
                    ("F_DROP_PROBE", F_DROP_PROBE),
                    ("F_DROP_PARENT", F_DROP_PARENT),
                ] {
                    gj.set_fault(f);
                    let r = search_field_groups(&gj, &cn, vs, q, opt16, 0..nsl);
                    gj.set_fault(0);
                    match r {
                        Ok((o, _)) => panic!("{name}: silent (survivors {}, checked {})", o.survivors, o.checked),
                        Err(e) => println!("{name}: loud: {e:#}"),
                    }
                    let (oc, _) = search_field_groups(&gj, &cn, vs, q, opt16, 0..nsl).unwrap();
                    assert_eq!((oc.survivors, oc.checked), (o1.survivors, o1.checked), "{name}: clean rerun");
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

    /// A field of the coordinate `(4, 8, 5)` (digits 5–7 fixed) is searched exactly: run through the
    /// field path one slice per group, every slice's counts (children, chunks, flat, survivors, checked, tops)
    /// equal those of the same slice run through the `(4, 9, 6)` fields that hold it (each such field's 64
    /// slices of the new field's digit 5, as a part of that field); the per-slice counts sum to the field run's
    /// outcome; with the whole field (`MIDOUT_485_D8=all`, the default), the production path (group 16, the
    /// sampled CPU check on) gives the same totals. `MIDOUT_485_T` (the new field's digits 5–7, default
    /// 77777), `MIDOUT_485_D8` (`all` or a list of digit-8 values), `MIDOUT_CLASSES` (63).
    #[cfg(feature = "midout-box-tests")]
    #[test]
    #[ignore = "needs a GPU (MIDOUT_CUDA=1 for the CUDA runtime) and minutes"]
    fn field_485_equals_496_slice_by_slice() {
        use std::collections::HashMap;
        let ctx = device().expect("a device");
        let tn: u128 = std::env::var("MIDOUT_485_T")
            .ok()
            .map_or(77_777, |s| s.parse().unwrap());
        let d8s: Vec<u128> = match std::env::var("MIDOUT_485_D8").as_deref() {
            Ok("all") | Err(_) => (0..64).collect(),
            Ok(l) => l.split(',').map(|x| x.parse().unwrap()).collect(),
        };
        let whole = d8s.len() == 64;
        let classes: u32 = std::env::var("MIDOUT_CLASSES")
            .ok()
            .map_or(63, |s| s.parse().unwrap());
        let cn = Coord::with_digits(64, 4, 8, 5).unwrap();
        let co = Coord::with_digits(64, 4, 9, 6).unwrap();
        let q = cn.quantum();
        assert_eq!(q, co.quantum());
        let key = |c: &DevCounts| {
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
                let gj = GpuJoin::new($client, Caps::b64(classes)).unwrap();
                let opt1 = GpuOptions { group: 1, host_threads: 1, device_tops: true, cpu_check: false, cpu_threads: 0 };
                // the new field, slice by slice (all of it, or the slices of the listed digit-8 values)
                let mut newc: HashMap<u64, DevCounts> = HashMap::new();
                let (mut ns, mut nc) = (0u64, 0u64);
                let sels: Vec<std::ops::Range<usize>> = if whole {
                    vec![0..4096]
                } else {
                    d8s.iter().map(|&d| (d as usize) * 64..(d as usize) * 64 + 64).collect()
                };
                let tw = std::time::Instant::now();
                for sel in sels {
                    let (o, rec) = search_field_groups(&gj, &cn, cn.start() + tn * q, q, opt1, sel).unwrap();
                    let (mut s1, mut c1) = (0, 0);
                    for (p, c) in rec {
                        assert_eq!(p.len(), 1);
                        assert_eq!((u128::from(p[0]) >> 6) & ((1 << 18) - 1), tn, "slice {} outside the field", p[0]);
                        s1 += c.survivors;
                        c1 += c.checked;
                        assert!(newc.insert(p[0], c).is_none(), "slice {} twice", p[0]);
                    }
                    assert_eq!((s1, c1), (o.survivors, o.checked), "per-slice counts sum to the field run's");
                    ns += o.survivors;
                    nc += o.checked;
                }
                println!("(4, 8, 5) field t {tn}: {} slices, survivors {ns}, checked {nc} ({:.1} s)", newc.len(), tw.elapsed().as_secs_f64());
                assert_eq!(newc.len(), 64 * d8s.len());
                // the same slices through the (4, 9, 6) fields that hold them
                let (d5, hi) = (tn % 64, tn / 64);
                let mut oldc: HashMap<u64, DevCounts> = HashMap::new();
                let tw = std::time::Instant::now();
                for &d8 in &d8s {
                    let to = hi + 4096 * d8;
                    let sel = (d5 as usize) * 64..(d5 as usize) * 64 + 64;
                    let (_, rec) = search_field_groups(&gj, &co, co.start() + to * q, q, opt1, sel).unwrap();
                    for (p, c) in rec {
                        assert!(oldc.insert(p[0], c).is_none());
                    }
                }
                println!("the same slices in {} (4, 9, 6) fields ({:.1} s)", d8s.len(), tw.elapsed().as_secs_f64());
                assert_eq!(oldc.len(), newc.len());
                let mut kept_eq = 0;
                for (p, c) in &newc {
                    let o = oldc.get(p).unwrap_or_else(|| panic!("slice {p} not in the (4, 9, 6) runs"));
                    assert_eq!(key(c), key(o), "slice {p}: (4, 8, 5) {c:?} vs (4, 9, 6) {o:?}");
                    kept_eq += usize::from(c.kept == o.kept);
                }
                let os: u64 = oldc.values().map(|c| c.survivors).sum();
                let oc: u64 = oldc.values().map(|c| c.checked).sum();
                assert_eq!((os, oc), (ns, nc));
                println!("slice by slice: {} slices equal (kept equal on {kept_eq}: kept depends on the field's key)", newc.len());
                if whole {
                    let opt = GpuOptions { group: 16, host_threads: 1, device_tops: true, cpu_check: true, cpu_threads: 0 };
                    let (o, dc, tm) = search_field(&gj, &cn, cn.start() + tn * q, q, opt).unwrap();
                    println!(
                        "the production path: survivors {}, checked {}, slices {}, nice {:?}, sampled slice {:?} equal ({:.1} s)",
                        o.survivors, o.checked, o.slices, o.nice, tm.sampled, tm.wall
                    );
                    assert_eq!((o.survivors, o.checked, o.slices), (ns, nc, 4096));
                    assert_eq!(dc.tops, newc.values().map(|c| c.tops).sum::<u64>());
                    assert_eq!(dc.children, newc.values().map(|c| c.children).sum::<u64>());
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

    /// What a plane pays in the expansion: one slice's records as the device wrote them (each batch read
    /// back after it ran), the histogram of survivor bits per record, and, per take of 2·W records of a slab (lane
    /// l: records l and l + W, as `expand_kernel`), the prefilter rounds of the two-loop form (max a + max b), of the
    /// one-loop form (max (a + b)) and of four records per lane (max of 4, per 4·W records), for W 8, 32 and 64 over
    /// the slabs in the device's order. `MIDOUT_GPU_SLICES` (the first), `MIDOUT_CLASSES` (4).
    #[cfg(feature = "midout-box-tests")]
    #[test]
    #[ignore = "needs a GPU (lavapipe will do) and a minute"]
    fn expansion_bits_profile() {
        let ctx = device().expect("a device");
        let pip: u64 = std::env::var("MIDOUT_GPU_SLICES")
            .ok()
            .and_then(|s| s.split(',').next().map(|x| x.parse().unwrap()))
            .unwrap_or(712_012_851);
        let classes: u32 = std::env::var("MIDOUT_CLASSES")
            .ok()
            .map_or(4, |s| s.parse().unwrap());
        macro_rules! go {
            ($client:expr) => {{
                let gj = GpuJoin::new($client, Caps::b64(classes)).unwrap();
                let st = slice_tops(pip, gj.roots());
                let rankh = gj.mk(st.rank.to_vec());
                let cnt = gj.mk(vec![0u32; NCNT]);
                let dp = gj.queue_dev_prep(pip, &rankh, false);
                let nt = gj.caps.tops as usize;
                let mut hist = [0u64; 65];
                let mut slabs: Vec<Vec<u32>> = Vec::new();
                for bi in 0..gj.batches.len() {
                    let t = gj.queue_batch(pip, nt, &dp.sb, bi, &cnt, &dp.acc);
                    cubecl::future::block_on(gj.client.sync()).unwrap();
                    let stat = gj.rd(&t.stat).unwrap();
                    let ns = (stat[1] as usize).min(gj.nslab_cap as usize);
                    let sc = gj.rd(&gj.slabcnt).unwrap();
                    let out = gj.rd(&gj.out).unwrap();
                    for s in 0..ns {
                        let v: Vec<u32> = (0..sc[s] as usize)
                            .map(|r| {
                                let o = (s * SLAB as usize + r) * 4;
                                out[o + 2].count_ones() + out[o + 3].count_ones()
                            })
                            .collect();
                        for &x in &v {
                            hist[x as usize] += 1;
                        }
                        slabs.push(v);
                    }
                }
                let recs: u64 = hist.iter().sum();
                let bits: u64 = hist.iter().enumerate().map(|(k, &n)| k as u64 * n).sum();
                println!("slice {pip}: device W {} slabs {} records {recs} bits {bits}", gj.w, slabs.len());
                println!("PROFILE hist {:?}", hist.iter().enumerate().filter(|x| *x.1 > 0).collect::<Vec<_>>());
                for w in [8usize, 32, 64] {
                    let (mut takes, mut two, mut one, mut four) = (0u64, 0u64, 0u64, 0u64);
                    for v in &slabs {
                        let at = |i: usize| v.get(i).copied().unwrap_or(0);
                        let mut r0 = 0;
                        while r0 < v.len() {
                            takes += 1;
                            let (mut ma, mut mb, mut mab) = (0, 0, 0);
                            for l in 0..w {
                                let (a, b) = (at(r0 + l), at(r0 + l + w));
                                ma = ma.max(a);
                                mb = mb.max(b);
                                mab = mab.max(a + b);
                            }
                            two += u64::from(ma + mb);
                            one += u64::from(mab);
                            r0 += 2 * w;
                        }
                        let mut r0 = 0;
                        while r0 < v.len() {
                            let mut m4 = 0;
                            for l in 0..w {
                                m4 = m4.max((0..4).map(|k| at(r0 + l + k * w)).sum::<u32>());
                            }
                            four += u64::from(m4);
                            r0 += 4 * w;
                        }
                    }
                    println!(
                        "PROFILE W {w}: takes of 2W {takes}, rounds per take: two loops {:.3}, one loop {:.3}, four records per lane {:.3} (per 2W records)",
                        two as f64 / takes as f64,
                        one as f64 / takes as f64,
                        four as f64 / takes as f64
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

    /// A run of [`slices_equal_cpu`].
    struct SliceCase {
        /// The slices (digits 4–8).
        pips: Vec<u64>,
        /// Classes per batch (63: one batch; 4 on lavapipe, whose bindings are at most 128 MiB).
        classes: u32,
        /// Batches run per slice (`usize::MAX`: the whole slice; fewer: the classes of those batches only).
        batches: usize,
        /// The parents from the shared depth-8 list of the slice's digits 4–7 (`anc8_kernel`).
        share: bool,
        /// The tops made on the host (the host-tops path) instead of on the device.
        host_tops: bool,
        /// Compile for this plane width on any device, run, report and stop: only the generated code is wanted
        /// (`CUBECL_DEBUG_SPIRV`, `CUBECL_DEBUG_LOG`); the results are invalid.
        force_w: Option<u32>,
        /// The prefilter's form (`None`: the runtime's).
        prefilter: Option<PrefilterForm>,
    }

    /// The device's prefilter survivors of base-64 slices (the n its check takes) equal the CPU reference's, n
    /// for n, with the order-independent counts (survivors and checked among them) when the slice is whole, and
    /// the device's tops equal the host's.
    fn slices_equal_cpu(case: &SliceCase) {
        let ctx = device().expect("a device");
        let (pips, classes) = (&case.pips, case.classes);
        let coord = Coord::for_base(64).unwrap();
        let base = Base::new(&coord);
        macro_rules! go {
            ($client:expr) => {{
                let force_w = case.force_w;
                let caps = Caps {
                    prefilter: case.prefilter,
                    ..Caps::b64(classes)
                };
                let gj = GpuJoin::with_width($client, caps, force_w).unwrap();
                println!("device {} W {} prefilter {}", ctx.device_name(), gj.w, if gj.oh64 { "24-bit" } else { "32-bit" });
                for &pip in pips {
                    if force_w.is_some() {
                        let st = slice_tops(pip, gj.roots());
                        let nb: usize = case.batches;
                        // with MIDOUT_SHARE8=1 also the shared depth-8 pass (`anc8_kernel`); its plane check fails
                        // under a forced width, so the slice then runs unshared (hist2 is the same kernel either way)
                        if case.share {
                            let ra = gj.build_anc(&[(pip & 0xFF_FFFF) as u32]);
                            println!("COMPILE-ONLY W {} slice {pip}: anc8 {ra:?}", gj.w);
                        }
                        let r = if case.host_tops {
                            gj.run_slice(&st).map(|x| x.0)
                        } else {
                            gj.run_slice_dev(pip, &st.rank, nb).map(|x| x.0)
                        };
                        println!("COMPILE-ONLY W {} slice {pip}: {r:?}", gj.w);
                        continue;
                    }
                    let st = slice_tops(pip, gj.roots());
                    // the n the device's check takes: survivors that pass the prefilter
                    let mut want = Vec::new();
                    let mut want_surv = 0u64;
                    let cn = slice_join::<u64>(&base, Shape { f0: 4, k: 10 }, u128::from(pip), |_, n, pass| {
                        if pass {
                            want.push(n);
                        }
                    });
                    // a part of the slice (MIDOUT_BATCHES): survivors whose bottom's class is in the batches run
                    let nb: usize = case.batches;
                    let part = nb < gj.batches.len();
                    let c_end = if part { gj.batches[nb - 1].1 } else { 63 };
                    want.retain(|&n| (((n & ((1u128 << 54) - 1)) % 63) as u32) < c_end);
                    want.sort_unstable();
                    if !part {
                        want_surv = cn.survivors;
                    }
                    let (dc, mut got) = if case.host_tops {
                        gj.run_slice(&st).unwrap()
                    } else {
                        // MIDOUT_SHARE8=1: the parents from the shared depth-8 list of the slice's digits 4-7
                        let share = case.share;
                        if share {
                            gj.build_anc(&[(pip & 0xFF_FFFF) as u32]).unwrap();
                            let (_, n) = gj.anc_for(pip).unwrap();
                            println!("slice {pip}: shared depth-8 list of {n} roots (of {})", gj.roots().len());
                        }
                        let (dc, got, mut tops) = gj.run_slice_dev_with(pip, &st.rank, nb, share).unwrap();
                        let mut htops: Vec<(u32, u64)> = st.thd.iter().copied().zip(st.tmask.iter().copied()).collect();
                        htops.sort_unstable();
                        tops.sort_unstable();
                        assert!(tops == htops, "slice {pip}: device tops differ from the host's");
                        println!("slice {pip}: device tops = host tops ({})", tops.len());
                        (dc, got)
                    };
                    got.sort_unstable();
                    println!("slice {pip}: device {dc:?}");
                    println!("slice {pip}: cpu    {cn:?}");
                    assert_eq!(got.len(), want.len());
                    assert!(got == want, "slice {pip}: prefilter survivor sets differ");
                    assert_eq!(dc.checked, want.len() as u64);
                    if !part {
                        assert_eq!(dc.survivors, want_surv);
                        assert_eq!(
                            (dc.children, dc.chunks, dc.flat, dc.survivors, dc.checked),
                            (cn.children, cn.chunks, cn.flat, cn.survivors, cn.checked)
                        );
                    } else {
                        println!("slice {pip}: part of the slice, classes [0, {c_end}): {} survivors", want.len());
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

    /// Tier (b): one slice, its first batch of 4 classes, against the CPU reference, with the prefilter in 32-bit
    /// limbs and in 24-bit limbs (whichever the runtime would choose).
    #[test]
    #[ignore = "needs a GPU (lavapipe will do; MIDOUT_CUDA=1 for CUDA) and a minute"]
    fn cubecl_midout_slice_part_equals_cpu() {
        for form in [PrefilterForm::Limbs32, PrefilterForm::Limbs24] {
            slices_equal_cpu(&SliceCase {
                pips: vec![712_012_851],
                classes: 4,
                batches: 1,
                share: false,
                host_tops: false,
                force_w: None,
                prefilter: Some(form),
            });
        }
    }

    /// Tier (b): one slice's first batch with the parents from the shared depth-8 list (`anc8_kernel`), the
    /// runtime's prefilter.
    #[test]
    #[ignore = "needs a GPU (lavapipe will do; MIDOUT_CUDA=1 for CUDA) and a minute"]
    fn cubecl_midout_shared_parents_slice_part_equals_cpu() {
        slices_equal_cpu(&SliceCase {
            pips: vec![712_012_851],
            classes: 4,
            batches: 1,
            share: true,
            host_tops: false,
            force_w: None,
            prefilter: None,
        });
    }

    /// Tier (c): [`slices_equal_cpu`] from the environment: `MIDOUT_GPU_SLICES` (comma list of digit-4..8 values,
    /// default 712012851), `MIDOUT_CLASSES` (63), `MIDOUT_BATCHES` (all), `MIDOUT_SHARE8=1`, `MIDOUT_HOST_TOPS`,
    /// `MIDOUT_FORCE_W` (the compile-only path), `MIDOUT_PREFILTER` (`32` or `24`; default the runtime's).
    #[cfg(feature = "midout-box-tests")]
    #[test]
    #[ignore = "needs a GPU (MIDOUT_CUDA=1 for the CUDA runtime) and minutes of CPU"]
    fn gpu_slices_equal_cpu() {
        let env = |k: &str| std::env::var(k).ok();
        slices_equal_cpu(&SliceCase {
            pips: env("MIDOUT_GPU_SLICES")
                .unwrap_or_else(|| "712012851".into())
                .split(',')
                .map(|s| s.parse().unwrap())
                .collect(),
            classes: env("MIDOUT_CLASSES").map_or(63, |s| s.parse().unwrap()),
            batches: env("MIDOUT_BATCHES").map_or(usize::MAX, |s| s.parse().unwrap()),
            share: env("MIDOUT_SHARE8").is_some_and(|x| x == "1"),
            host_tops: env("MIDOUT_HOST_TOPS").is_some(),
            force_w: env("MIDOUT_FORCE_W").map(|x| x.parse().unwrap()),
            prefilter: match env("MIDOUT_PREFILTER").as_deref() {
                Some("32") => Some(PrefilterForm::Limbs32),
                Some("24") => Some(PrefilterForm::Limbs24),
                _ => None,
            },
        });
    }
}
