//! `CubeCL` detailed-mode backend: the hand-written Vulkan backend's detailed
//! kernel (since removed) expressed as a `#[cube]` Rust function instead of
//! generated WGSL.
//!
//! This is a benchmark-grade port for evaluating `CubeCL` as a replacement for
//! the string-codegen approach (see PR #96 discussion). It kept the Vulkan
//! backend's structure: same per-base constants from
//! [`crate::gpu_config`], same split16 chunk scan (all divisions 32-bit with
//! comptime-constant divisors), same 4-copy workgroup histogram, same
//! `MISS_STRIDE` near-miss records, same `FieldResults` out the other end.
//! What used to be per-base source generation is `#[comptime]` parameters:
//! `CubeCL` JIT-specializes one Rust function per base at first launch.
//!
//! Niceonly drives the shared [`crate::gpu_niceonly`] pipeline like the other
//! backends: the CPU's MSD prefix filter streams range descriptors in, and
//! [`niceonly_kernel`] reconstructs the stride filter's candidates on-device
//! from the residue table — the same reconstruction, offset reduction, lane
//! tiling, and low-digit prefilter as the Vulkan shader had, as Rust.

#![cfg(feature = "cubecl")]
// The cube macro evaluates comptime! expressions host-side, where fn-level
// allows do not reach; these lints are all macro-expansion artifacts.
#![allow(
    clippy::cast_possible_truncation,
    clippy::cast_possible_wrap,
    clippy::cast_lossless,
    clippy::used_underscore_binding
)]

use crate::client_process::process_range_detailed;
use crate::cubecl_join::{JoinPipeline, limits_of, run_slices};
use crate::gpu_config::{
    VulkanPrefilterParams, chunk_constants_u16, gpu_supports_base, n_limbs, vulkan_prefilter_params,
};
use crate::gpu_niceonly::{
    BATCHES_IN_FLIGHT, DeviceResult, GPU_LSD_K, MAX_STRIDE_MODULUS, NiceonlyPipeline,
    NiceonlyStats, PendingField, RangeSink, lane_shift_for, stride_chunk_bits,
};
use crate::gpu_route::{FieldTicket, NiceonlyGpu, Route};
use crate::join_plan::{JoinCeiling, JoinField, JoinLimits, plan_join};
use crate::number_stats::get_near_miss_cutoff;
use crate::overlap_join::StrideReason;
use crate::stride_filter::StrideTable;
use crate::{FieldResults, FieldSize, NiceNumberSimple, UniquesDistributionSimple};
use anyhow::{Context as _, Result, ensure};
use cubecl::prelude::*;
use log::{debug, warn};
use std::collections::HashMap;
use std::sync::{Arc, Mutex, OnceLock};
use web_time::Instant;

/// Threads per cube (workgroup).
pub const WORKGROUP_SIZE: u32 = 256;

/// Upper bound on cubes per dispatch; threads grid-stride past it.
pub const MAX_CUBES: u32 = 4096;

/// Workgroup histogram copies, spreading atomic contention like the CUDA
/// kernel's per-warp histograms.
pub const HIST_COPIES: u32 = 4;

/// u32 slots per near-miss record: n as four u32 limbs plus its unique count.
pub const MISS_STRIDE: u32 = 5;

/// Candidates per dispatch: small enough that a u32 histogram bin cannot
/// overflow before the host drains it.
pub const CUBECL_BATCH_SIZE: u128 = 50_000_000;

/// Near-miss records held on the device per field.
const NEAR_MISS_CAPACITY: usize = 1 << 20;

/// The detailed kernel: for each candidate `n` in `[start, start+count)`,
/// count the unique base-b digits of n² and n³ together, histogram the
/// count, and record near-misses above the cutoff.
///
/// Comptime parameters make `CubeCL` specialize one kernel per base, exactly
/// as the WGSL generator bakes literals: every division below is by a
/// comptime constant, and every limb loop unrolls to straight-line code.
#[cube(launch_unchecked)]
#[allow(clippy::too_many_arguments, clippy::too_many_lines)]
fn detailed_kernel(
    hist: &mut Array<Atomic<u32>>,
    miss_count: &mut Array<Atomic<u32>>,
    miss_data: &mut Array<u32>,
    s0: u32,
    s1: u32,
    s2: u32,
    s3: u32,
    cnt_lo: u32,
    cnt_hi: u32,
    miss_cap: u32,
    #[comptime] base: u32,
    #[comptime] limbs: u32,
    #[comptime] chunk_digits: u32,
    #[comptime] chunk_div: u32,
    #[comptime] cutoff: u32,
    #[comptime] wide_chunk: bool,
) {
    let hist_bins = comptime!(base + 1);
    let sq_limbs = comptime!(2 * limbs);
    let cu_limbs = comptime!(3 * limbs);
    let two_masks = comptime!(base > 64);

    let hist_s = SharedMemory::<Atomic<u32>>::new(comptime!((HIST_COPIES * (base + 1)) as usize));

    // Zero the workgroup histogram.
    let mut zi = UNIT_POS_X;
    while zi < HIST_COPIES * hist_bins {
        hist_s[zi as usize].store(0u32);
        zi += CUBE_DIM_X;
    }
    sync_cube();

    let start_lo = (u64::cast_from(s1) << 32u64) | u64::cast_from(s0);
    let start_hi = (u64::cast_from(s3) << 32u64) | u64::cast_from(s2);
    let count = (u64::cast_from(cnt_hi) << 32u64) | u64::cast_from(cnt_lo);
    let copy = (UNIT_POS_X >> 5u32) % HIST_COPIES;
    let stride = u64::cast_from(CUBE_COUNT_X) * u64::cast_from(CUBE_DIM_X);

    // Scratch for the digit scan, in shared memory: the split loop indexes
    // it at runtime, and a register-promoted array makes every such access a
    // compare/select chain over all words (~100 extra SASS compares at b50),
    // while local memory costs a round trip. One shared word per thread per
    // limb, padded to an odd stride so a warp's accesses spread across banks.
    let sv_pad = comptime!(cu_limbs | 1);
    let mut sv_s = SharedMemory::<u32>::new(comptime!((WORKGROUP_SIZE * (cu_limbs | 1)) as usize));
    let svb = UNIT_POS_X * sv_pad;

    let mut idx = u64::cast_from(ABSOLUTE_POS_X);
    while idx < count {
        // n = start + idx over u64 halves (u128 add with carry).
        let n_lo = start_lo + idx;
        let mut n_hi = start_hi;
        if n_lo < start_lo {
            n_hi += 1u64;
        }

        // --- num_unique(n_lo, n_hi), inlined ---------------------------------
        // Unpack n into u32 limbs held in a local array; limb loops below
        // unroll over comptime bounds, so indices are constants.
        let mut nl = Array::<u32>::new(limbs as usize);
        #[unroll]
        for i in 0..limbs {
            let shift = comptime!(((i & 1) * 32) as u64);
            if comptime!(i < 2) {
                nl[i as usize] = u32::cast_from(n_lo >> shift);
            } else {
                nl[i as usize] = u32::cast_from(n_hi >> shift);
            }
        }

        // sq = n * n (schoolbook, u64 accumulation).
        let mut sq = Array::<u32>::new(sq_limbs as usize);
        #[unroll]
        for i in 0..sq_limbs {
            sq[i as usize] = 0u32;
        }
        #[unroll]
        for i in 0..limbs {
            let mut carry = 0u64;
            #[unroll]
            for j in 0..limbs {
                let k = comptime!(i + j);
                let t = u64::cast_from(nl[i as usize]) * u64::cast_from(nl[j as usize])
                    + u64::cast_from(sq[k as usize])
                    + carry;
                sq[k as usize] = u32::cast_from(t);
                carry = t >> 32u64;
            }
            sq[comptime!(i + limbs) as usize] = u32::cast_from(carry);
        }

        // cu = sq * n.
        let mut cu = Array::<u32>::new(cu_limbs as usize);
        #[unroll]
        for i in 0..cu_limbs {
            cu[i as usize] = 0u32;
        }
        #[unroll]
        for i in 0..sq_limbs {
            let mut carry = 0u64;
            #[unroll]
            for j in 0..limbs {
                let k = comptime!(i + j);
                let t = u64::cast_from(sq[i as usize]) * u64::cast_from(nl[j as usize])
                    + u64::cast_from(cu[k as usize])
                    + carry;
                cu[k as usize] = u32::cast_from(t);
                carry = t >> 32u64;
            }
            cu[comptime!(i + limbs) as usize] = u32::cast_from(carry);
        }

        // Digit masks.
        let mut m0 = 0u64;
        let mut m1 = 0u64;

        // Two scans: sq then cu. `pass` selects the source.
        let mut pass: u32 = 0u32;
        while pass < 2u32 {
            if pass == 0u32 {
                #[unroll]
                for i in 0..sq_limbs {
                    sv_s[(svb + u32::cast_from(i)) as usize] = sq[i as usize];
                }
                #[unroll]
                for i in sq_limbs..cu_limbs {
                    sv_s[(svb + u32::cast_from(i)) as usize] = 0u32;
                }
            } else {
                #[unroll]
                for i in 0..cu_limbs {
                    sv_s[(svb + u32::cast_from(i)) as usize] = cu[i as usize];
                }
            }

            // top_limb
            let mut top: i32 = comptime!(cu_limbs as i32 - 1).runtime();
            while top >= 0 {
                if sv_s[(svb + u32::cast_from(top)) as usize] != 0u32 {
                    break;
                }
                top -= 1;
            }

            // Chunked radix scan, destroying sv. Two flavors, chosen at
            // comptime per runtime: `wide_chunk` divides limb-pairs by a
            // sub-2^31 constant with one u64 division per limb (nvcc
            // strength-reduces it; 5 digits/chunk at base 40), while the
            // split16 flavor uses two u32 divisions over 16-bit halves
            // (for drivers that cannot strength-reduce u64, 3 digits/chunk).
            while top >= 0 {
                let mut rem = 0u32;
                if wide_chunk {
                    let mut rem64 = 0u64;
                    let mut i: i32 = top;
                    while i >= 0 {
                        let cur = (rem64 << 32u64)
                            | u64::cast_from(sv_s[(svb + u32::cast_from(i)) as usize]);
                        // Quotient once, remainder by mul-sub — see the
                        // niceonly scan; `%` would cost a second multiply-high
                        // sequence per word.
                        let q = cur / u64::cast_from(chunk_div);
                        sv_s[(svb + u32::cast_from(i)) as usize] = u32::cast_from(q);
                        rem64 = cur - q * u64::cast_from(chunk_div);
                        i -= 1;
                    }
                    rem = u32::cast_from(rem64); // rem < chunk_div < 2^31
                } else {
                    let mut i: i32 = top;
                    while i >= 0 {
                        let vi = sv_s[(svb + u32::cast_from(i)) as usize];
                        let c1 = (rem << 16u32) | (vi >> 16u32);
                        let q1 = c1 / chunk_div;
                        let r1 = c1 - q1 * chunk_div;
                        let c2 = (r1 << 16u32) | (vi & 0xFFFFu32);
                        let q2 = c2 / chunk_div;
                        rem = c2 - q2 * chunk_div;
                        sv_s[(svb + u32::cast_from(i)) as usize] = (q1 << 16u32) | q2;
                        i -= 1;
                    }
                }
                while top >= 0 {
                    if sv_s[(svb + u32::cast_from(top)) as usize] != 0u32 {
                        break;
                    }
                    top -= 1;
                }

                let mut chunk = rem;
                if top >= 0 {
                    // Interior chunk: all chunk_digits digits, zeros included.
                    #[unroll]
                    for _k in 0..chunk_digits {
                        let cq = chunk / base;
                        let d = chunk - cq * base;
                        chunk = cq;
                        if two_masks {
                            if d < 64u32 {
                                m0 |= 1u64 << u64::cast_from(d);
                            } else {
                                m1 |= 1u64 << u64::cast_from(d - 64u32);
                            }
                        } else {
                            m0 |= 1u64 << u64::cast_from(d);
                        }
                    }
                } else {
                    // Most significant chunk: digits until zero.
                    while chunk != 0u32 {
                        let cq = chunk / base;
                        let d = chunk - cq * base;
                        chunk = cq;
                        if two_masks {
                            if d < 64u32 {
                                m0 |= 1u64 << u64::cast_from(d);
                            } else {
                                m1 |= 1u64 << u64::cast_from(d - 64u32);
                            }
                        } else {
                            m0 |= 1u64 << u64::cast_from(d);
                        }
                    }
                }
            }
            pass += 1u32;
        }

        let mut u = u32::cast_from(m0).count_ones() + u32::cast_from(m0 >> 32u64).count_ones();
        if two_masks {
            u += u32::cast_from(m1).count_ones() + u32::cast_from(m1 >> 32u64).count_ones();
        }
        // --- end num_unique --------------------------------------------------

        hist_s[(copy * hist_bins + u) as usize].fetch_add(1u32);
        if u > cutoff {
            let pos = miss_count[0].fetch_add(1u32);
            if pos < miss_cap {
                let o = MISS_STRIDE * pos;
                miss_data[o as usize] = u32::cast_from(n_lo);
                miss_data[(o + 1u32) as usize] = u32::cast_from(n_lo >> 32u64);
                miss_data[(o + 2u32) as usize] = u32::cast_from(n_hi);
                miss_data[(o + 3u32) as usize] = u32::cast_from(n_hi >> 32u64);
                miss_data[(o + 4u32) as usize] = u;
            }
        }

        idx += stride;
    }

    sync_cube();
    // Reduce the workgroup histogram into the global one.
    let mut b = UNIT_POS_X;
    while b < hist_bins {
        let mut acc = 0u32;
        #[unroll]
        for c in 0..HIST_COPIES {
            acc += hist_s[(c * hist_bins + b) as usize].load();
        }
        if acc != 0u32 {
            hist[b as usize].fetch_add(acc);
        }
        b += CUBE_DIM_X;
    }
}

// ---------------------------------------------------------------------------
// Finite-difference detailed kernel (experiment, exp/gpu-detailed-fd).
//
// Each thread walks a run of consecutive n. The run's first n is seeded with
// exact limb arithmetic and long division (the same u64-by-constant chunk
// split the per-number kernel uses), into base-b digit arrays packed four
// digits per u32 (one byte lane each, little-endian): S = n², C = n³,
// dS = 2n+1, dC = 3n²+3n+1, ddC = 6n+6. Every later n costs five digit-array
// additions and the mask build, with no division at all.
//
// Digit-array addition is the biased-byte add from the L2 CPU prototype:
// adding `256 - b` to every addend byte makes a byte overflow into the next
// exactly when its digit sum reaches b, so one native u32 add carries all four
// lanes. For b <= 128 a lane that carried out holds a value below b (bit 7
// clear) and one that did not holds at least 256 - b (bit 7 set), so bit 7
// both selects the lanes that need the bias taken back and, for the top lane,
// is the carry out of the word. Branch-free; the only branch is the carry out
// of the word above the addend's top word (four digits of b-1 in a row).
//
// The host runs this kernel only on the part of a batch where n² has exactly
// `ls` digits and n³ exactly `lc` (the whole of a base's legal range), so the
// mask covers comptime digit positions and leading zeros never enter it.
// ---------------------------------------------------------------------------

/// Biased add `x += y` over packed digit words: `y` has `wy` words, `x` has
/// `wx >= wy`. The carry out of `x`'s top word is dropped.
#[cube]
fn fd_add(
    x: &mut Array<u32>,
    y: &Array<u32>,
    #[comptime] wy: u32,
    #[comptime] wx: u32,
    #[comptime] base: u32,
) {
    let bias = comptime!((256 - base) * 0x0101_0101u32);
    let fix = comptime!(256 - base);
    let mut cin = 0u32;
    #[unroll]
    for w in 0..wy {
        let t = x[w as usize] + y[w as usize] + bias + cin;
        cin = (t >> 31u32) ^ 1u32;
        x[w as usize] = t - ((t >> 7u32) & 0x0101_0101u32) * fix;
    }
    fd_carry(x, cin, wy, wx, base);
}

/// Biased add `x += y` like [`fd_add`], but words `wy..kd` take the carry
/// unconditionally and anything above `kd` only on a (rare) ripple, which
/// is reported: returns 1 when a word at or above `kd` changed.
#[cube]
fn fd_add_split(
    x: &mut Array<u32>,
    y: &Array<u32>,
    #[comptime] wy: u32,
    #[comptime] kd: u32,
    #[comptime] wx: u32,
    #[comptime] base: u32,
) -> u32 {
    let bias = comptime!((256 - base) * 0x0101_0101u32);
    let fix = comptime!(256 - base);
    let mut cin = 0u32;
    #[unroll]
    for w in 0..wy {
        let t = x[w as usize] + y[w as usize] + bias + cin;
        cin = (t >> 31u32) ^ 1u32;
        x[w as usize] = t - ((t >> 7u32) & 0x0101_0101u32) * fix;
    }
    #[unroll]
    for w in wy..kd {
        let t = x[w as usize] + bias + cin;
        cin = (t >> 31u32) ^ 1u32;
        x[w as usize] = t - ((t >> 7u32) & 0x0101_0101u32) * fix;
    }
    let mut rippled = 0u32;
    if comptime!(kd < wx) {
        if cin != 0u32 {
            fd_ripple(x, kd, wx, base);
            rippled = 1u32;
        }
    }
    rippled
}

/// Biased add `x += y` over words `0..wy`, then the carry into words
/// `wy..kd`; no ripple above `kd`. Returns the last word's raw sum, whose
/// bit 31 is clear exactly when it carried out (the caller ripples).
#[cube]
fn fd_add_top(
    x: &mut Array<u32>,
    y: &Array<u32>,
    #[comptime] wy: u32,
    #[comptime] kd: u32,
    #[comptime] base: u32,
) -> u32 {
    let bias = comptime!((256 - base) * 0x0101_0101u32);
    let fix = comptime!(256 - base);
    let mut cin: u32 = 0u32;
    let mut t: u32 = 0u32;
    #[unroll]
    for w in 0..wy {
        t = x[w as usize] + y[w as usize] + bias + cin;
        cin = (t >> 31u32) ^ 1u32;
        x[w as usize] = t - ((t >> 7u32) & 0x0101_0101u32) * fix;
    }
    #[unroll]
    for w in wy..kd {
        t = x[w as usize] + bias + cin;
        cin = (t >> 31u32) ^ 1u32;
        x[w as usize] = t - ((t >> 7u32) & 0x0101_0101u32) * fix;
    }
    t
}

/// Biased add of a one-digit constant into word 0; returns the raw sum as
/// [`fd_add_top`] does.
#[cube]
fn fd_add_const_top(x: &mut Array<u32>, #[comptime] c: u32, #[comptime] base: u32) -> u32 {
    let bias = comptime!((256 - base) * 0x0101_0101u32);
    let fix = comptime!(256 - base);
    let t = x[0] + comptime!(bias + c);
    x[0] = t - ((t >> 7u32) & 0x0101_0101u32) * fix;
    t
}

/// Biased add of a one-digit constant `c < base` into word 0 of `x`.
#[cube]
fn fd_add_const(x: &mut Array<u32>, #[comptime] c: u32, #[comptime] wx: u32, #[comptime] base: u32) {
    let bias = comptime!((256 - base) * 0x0101_0101u32);
    let fix = comptime!(256 - base);
    let t = x[0] + comptime!(bias + c);
    let cin = (t >> 31u32) ^ 1u32;
    x[0] = t - ((t >> 7u32) & 0x0101_0101u32) * fix;
    if comptime!(wx > 1) {
        if cin != 0u32 {
            fd_ripple(x, 1u32, wx, base);
        }
    }
}

/// Carry `cin` into word `from` of `x` unconditionally (the word above the
/// addend's top word takes a carry often), then ripple further only when that
/// word carried out too, which is rare.
#[cube]
fn fd_carry(
    x: &mut Array<u32>,
    cin: u32,
    #[comptime] from: u32,
    #[comptime] wx: u32,
    #[comptime] base: u32,
) {
    let bias = comptime!((256 - base) * 0x0101_0101u32);
    let fix = comptime!(256 - base);
    if comptime!(from < wx) {
        let t = x[from as usize] + bias + cin;
        let c2 = (t >> 31u32) ^ 1u32;
        x[from as usize] = t - ((t >> 7u32) & 0x0101_0101u32) * fix;
        if comptime!(from + 1 < wx) {
            if c2 != 0u32 {
                fd_ripple(x, comptime!(from + 1), wx, base);
            }
        }
    }
}

/// Add a carry of 1 into word `from` and ripple it up to word `wx - 1`.
#[cube]
fn fd_ripple(x: &mut Array<u32>, #[comptime] from: u32, #[comptime] wx: u32, #[comptime] base: u32) {
    let bias = comptime!((256 - base) * 0x0101_0101u32);
    let fix = comptime!(256 - base);
    let mut cin = 1u32;
    #[unroll]
    for w in from..wx {
        let t = x[w as usize] + bias + cin;
        cin = (t >> 31u32) ^ 1u32;
        x[w as usize] = t - ((t >> 7u32) & 0x0101_0101u32) * fix;
    }
}

/// Convert a little-endian u32 limb value `v` (destroyed) into packed
/// base-b digits in `out` (`ndig` digits, `out` pre-zeroed), peeling
/// `chunk_digits` digits per u64-by-constant long division.
#[cube]
fn fd_to_digits(
    v: &mut Array<u32>,
    out: &mut Array<u32>,
    #[comptime] nlimbs: u32,
    #[comptime] ndig: u32,
    #[comptime] base: u32,
    #[comptime] chunk_digits: u32,
    #[comptime] chunk_div: u32,
) {
    let nchunks = comptime!(ndig.div_ceil(chunk_digits));
    #[unroll]
    for k in 0..nchunks {
        let mut rem64 = 0u64;
        #[unroll]
        for ii in 0..nlimbs {
            let i = comptime!(nlimbs - 1 - ii);
            let cur = (rem64 << 32u64) | u64::cast_from(v[i as usize]);
            let q = cur / u64::cast_from(chunk_div);
            v[i as usize] = u32::cast_from(q);
            rem64 = cur - q * u64::cast_from(chunk_div);
        }
        let mut chunk = u32::cast_from(rem64);
        #[unroll]
        for i in 0..chunk_digits {
            let j = comptime!(k * chunk_digits + i);
            if comptime!(j < ndig) {
                let cq = chunk / base;
                let d = chunk - cq * base;
                chunk = cq;
                let w = comptime!(j / 4);
                let sh = comptime!(8 * (j % 4));
                out[w as usize] |= d << sh;
            }
        }
    }
}

/// OR `1 << d` into `m` for packed digits `from..ndig` of `x`.
#[cube]
fn fd_mask(x: &Array<u32>, m: u64, #[comptime] from: u32, #[comptime] ndig: u32) -> u64 {
    let mut mm = m;
    #[unroll]
    for j in from..ndig {
        let w = comptime!(j / 4);
        let sh = comptime!(8 * (j % 4));
        let d = if comptime!(j % 4 == 3) {
            x[w as usize] >> 24u32
        } else {
            (x[w as usize] >> sh) & 0xFFu32
        };
        mm |= 1u64 << u64::cast_from(d);
    }
    mm
}

/// The finite-difference detailed kernel: thread `t` takes the run of
/// `run_len` consecutive candidates starting at `start + t * run_len`
/// (grid-stride over runs), seeds its digit arrays from the run's first n
/// and steps through the run by digit-array addition.
#[cube(launch_unchecked)]
#[allow(clippy::too_many_arguments, clippy::too_many_lines)]
fn detailed_fd_kernel(
    hist: &mut Array<Atomic<u32>>,
    miss_count: &mut Array<Atomic<u32>>,
    miss_data: &mut Array<u32>,
    low_table: &Array<u64>,
    s0: u32,
    s1: u32,
    s2: u32,
    s3: u32,
    cnt_lo: u32,
    cnt_hi: u32,
    run_len: u32,
    miss_cap: u32,
    #[comptime] base: u32,
    #[comptime] limbs: u32,
    #[comptime] chunk_digits: u32,
    #[comptime] chunk_div: u32,
    #[comptime] cutoff: u32,
    #[comptime] ls: u32,
    #[comptime] lc: u32,
    #[comptime] lds: u32,
    #[comptime] ldc: u32,
    #[comptime] lddc: u32,
    #[comptime] static_mask: bool,
    #[comptime] merged: bool,
    #[comptime] hist_local: bool,
    #[comptime] hist_lo: u32,
    #[comptime] use_table: bool,
) {
    let hist_bins = comptime!(base + 1);
    // Low-digit table: entry r is the mask of digits 0 and 1 of r² and r³
    // mod b², i.e. of n² and n³ for every n ≡ r (mod b²).
    let b2 = comptime!(base * base);
    let low_dig = comptime!(if use_table { 2u32 } else { 0u32 });
    let sq_limbs = comptime!(2 * limbs);
    let cu_limbs = comptime!(3 * limbs);
    let ws = comptime!(ls.div_ceil(4));
    let wc = comptime!(lc.div_ceil(4));
    let wds = comptime!(lds.div_ceil(4));
    let wdc = comptime!(ldc.div_ceil(4));
    let wddc = comptime!(lddc.div_ceil(4));
    // Words of S and C that change on most steps: the addend's words plus,
    // when the addend fills its top word, one more. Above them a word only
    // changes on a ripple (four digits of b-1), and their mask is cached.
    let ks = comptime!(if static_mask { (lds + 1).div_ceil(4).min(ws) } else { ws });
    let kc = comptime!(if static_mask { (ldc + 1).div_ceil(4).min(wc) } else { wc });
    let ks_dig = comptime!((4 * ks).min(ls));
    let kc_dig = comptime!((4 * kc).min(lc));

    let hist_s = SharedMemory::<Atomic<u32>>::new(comptime!((HIST_COPIES * (base + 1)) as usize));
    let mut zi = UNIT_POS_X;
    while zi < HIST_COPIES * hist_bins {
        hist_s[zi as usize].store(0u32);
        zi += CUBE_DIM_X;
    }
    sync_cube();

    let start_lo = (u64::cast_from(s1) << 32u64) | u64::cast_from(s0);
    let start_hi = (u64::cast_from(s3) << 32u64) | u64::cast_from(s2);
    let count = (u64::cast_from(cnt_hi) << 32u64) | u64::cast_from(cnt_lo);
    let copy = (UNIT_POS_X >> 5u32) % HIST_COPIES;
    let stride = u64::cast_from(CUBE_COUNT_X) * u64::cast_from(CUBE_DIM_X) * u64::cast_from(run_len);

    let mut off = u64::cast_from(ABSOLUTE_POS_X) * u64::cast_from(run_len);
    while off < count {
        let mut len = u32::cast_from(count - off);
        if count - off > u64::cast_from(run_len) {
            len = run_len;
        }
        let n_lo = start_lo + off;
        let mut n_hi = start_hi;
        if n_lo < start_lo {
            n_hi += 1u64;
        }

        // --- seed: exact limbs of n, n², n³, 2n+1, 3n²+3n+1, 6n+6 ----------
        let mut nl = Array::<u32>::new(limbs as usize);
        #[unroll]
        for i in 0..limbs {
            let shift = comptime!(((i & 1) * 32) as u64);
            if comptime!(i < 2) {
                nl[i as usize] = u32::cast_from(n_lo >> shift);
            } else {
                nl[i as usize] = u32::cast_from(n_hi >> shift);
            }
        }
        let mut sq = Array::<u32>::new(sq_limbs as usize);
        #[unroll]
        for i in 0..sq_limbs {
            sq[i as usize] = 0u32;
        }
        #[unroll]
        for i in 0..limbs {
            let mut carry = 0u64;
            #[unroll]
            for j in 0..limbs {
                let k = comptime!(i + j);
                let t = u64::cast_from(nl[i as usize]) * u64::cast_from(nl[j as usize])
                    + u64::cast_from(sq[k as usize])
                    + carry;
                sq[k as usize] = u32::cast_from(t);
                carry = t >> 32u64;
            }
            sq[comptime!(i + limbs) as usize] = u32::cast_from(carry);
        }
        let mut cu = Array::<u32>::new(cu_limbs as usize);
        #[unroll]
        for i in 0..cu_limbs {
            cu[i as usize] = 0u32;
        }
        #[unroll]
        for i in 0..sq_limbs {
            let mut carry = 0u64;
            #[unroll]
            for j in 0..limbs {
                let k = comptime!(i + j);
                let t = u64::cast_from(sq[i as usize]) * u64::cast_from(nl[j as usize])
                    + u64::cast_from(cu[k as usize])
                    + carry;
                cu[k as usize] = u32::cast_from(t);
                carry = t >> 32u64;
            }
            cu[comptime!(i + limbs) as usize] = u32::cast_from(carry);
        }
        // 2n+1 and 6n+6 (limbs + 1 words), 3n²+3n+1 (2·limbs + 1 words).
        let mut v_ds = Array::<u32>::new(comptime!(limbs + 1) as usize);
        let mut v_ddc = Array::<u32>::new(comptime!(limbs + 1) as usize);
        let mut c_ds = 1u64;
        let mut c_ddc = 6u64;
        #[unroll]
        for i in 0..comptime!(limbs + 1) {
            if comptime!(i < limbs) {
                c_ds += 2u64 * u64::cast_from(nl[i as usize]);
                c_ddc += 6u64 * u64::cast_from(nl[i as usize]);
            }
            v_ds[i as usize] = u32::cast_from(c_ds);
            v_ddc[i as usize] = u32::cast_from(c_ddc);
            c_ds >>= 32u64;
            c_ddc >>= 32u64;
        }
        let mut v_dc = Array::<u32>::new(comptime!(sq_limbs + 1) as usize);
        let mut c_dc = 1u64;
        #[unroll]
        for i in 0..comptime!(sq_limbs + 1) {
            if comptime!(i < sq_limbs) {
                c_dc += 3u64 * u64::cast_from(sq[i as usize]);
            }
            if comptime!(i < limbs) {
                c_dc += 3u64 * u64::cast_from(nl[i as usize]);
            }
            v_dc[i as usize] = u32::cast_from(c_dc);
            c_dc >>= 32u64;
        }

        let mut ds = Array::<u32>::new(wds as usize);
        let mut dc = Array::<u32>::new(wdc as usize);
        let mut ddc = Array::<u32>::new(wddc as usize);
        let mut sd = Array::<u32>::new(ws as usize);
        let mut cd = Array::<u32>::new(wc as usize);
        #[unroll]
        for i in 0..ws {
            sd[i as usize] = 0u32;
        }
        #[unroll]
        for i in 0..wc {
            cd[i as usize] = 0u32;
        }
        #[unroll]
        for i in 0..wds {
            ds[i as usize] = 0u32;
        }
        #[unroll]
        for i in 0..wdc {
            dc[i as usize] = 0u32;
        }
        #[unroll]
        for i in 0..wddc {
            ddc[i as usize] = 0u32;
        }
        fd_to_digits(&mut sq, &mut sd, sq_limbs, ls, base, chunk_digits, chunk_div);
        fd_to_digits(&mut cu, &mut cd, cu_limbs, lc, base, chunk_digits, chunk_div);
        fd_to_digits(&mut v_ds, &mut ds, comptime!(limbs + 1), lds, base, chunk_digits, chunk_div);
        fd_to_digits(&mut v_dc, &mut dc, comptime!(sq_limbs + 1), ldc, base, chunk_digits, chunk_div);
        fd_to_digits(&mut v_ddc, &mut ddc, comptime!(limbs + 1), lddc, base, chunk_digits, chunk_div);

        // --- walk the run ----------------------------------------------------
        let mut ms = 0u64;
        if static_mask {
            ms = fd_mask(&sd, ms, ks_dig, ls);
            ms = fd_mask(&cd, ms, kc_dig, lc);
        }
        // Per-thread packed histogram: 8-bit counters for bins
        // hist_lo..hist_lo+16 in four words, flushed every 255 numbers.
        let mut h0: u32 = 0u32;
        let mut h1: u32 = 0u32;
        let mut h2: u32 = 0u32;
        let mut h3: u32 = 0u32;
        let mut hfill: u32 = 0u32;
        let mut r: u32 = 0u32;
        if use_table {
            let m64 = comptime!(u64::from(base * base));
            let p64 = comptime!(((1u128 << 64) % u128::from(base * base)) as u64);
            r = u32::cast_from(((n_hi % m64) * p64 + n_lo % m64) % m64);
        }
        let mut i = 0u32;
        while i < len {
            let mut m = ms;
            if use_table {
                m |= low_table[r as usize];
                r += 1u32;
                if r == b2 {
                    r = 0u32;
                }
            }
            m = fd_mask(&sd, m, low_dig, ks_dig);
            m = fd_mask(&cd, m, low_dig, kc_dig);
            let u = u32::cast_from(m).count_ones() + u32::cast_from(m >> 32u64).count_ones();
            if hist_local {
                let k = u - hist_lo;
                if k < 16u32 {
                    let inc = 1u32 << ((k & 3u32) << 3u32);
                    let q = k >> 2u32;
                    h0 += select(q == 0u32, inc, 0u32);
                    h1 += select(q == 1u32, inc, 0u32);
                    h2 += select(q == 2u32, inc, 0u32);
                    h3 += select(q == 3u32, inc, 0u32);
                } else {
                    hist_s[(copy * hist_bins + u) as usize].fetch_add(1u32);
                }
                hfill += 1u32;
                let last = i + 1u32 == len;
                if hfill == 255u32 || last {
                    let hb = copy * hist_bins + hist_lo;
                    #[unroll]
                    for j in 0..4u32 {
                        let c = (h0 >> comptime!(8 * j)) & 0xFFu32;
                        if c != 0u32 {
                            hist_s[(hb + j) as usize].fetch_add(c);
                        }
                    }
                    #[unroll]
                    for j in 0..4u32 {
                        let c = (h1 >> comptime!(8 * j)) & 0xFFu32;
                        if c != 0u32 {
                            hist_s[(hb + comptime!(4 + j)) as usize].fetch_add(c);
                        }
                    }
                    #[unroll]
                    for j in 0..4u32 {
                        let c = (h2 >> comptime!(8 * j)) & 0xFFu32;
                        if c != 0u32 {
                            hist_s[(hb + comptime!(8 + j)) as usize].fetch_add(c);
                        }
                    }
                    #[unroll]
                    for j in 0..4u32 {
                        let c = (h3 >> comptime!(8 * j)) & 0xFFu32;
                        if c != 0u32 {
                            hist_s[(hb + comptime!(12 + j)) as usize].fetch_add(c);
                        }
                    }
                    h0 = 0u32;
                    h1 = 0u32;
                    h2 = 0u32;
                    h3 = 0u32;
                    hfill = 0u32;
                }
            } else {
                hist_s[(copy * hist_bins + u) as usize].fetch_add(1u32);
            }
            if u > cutoff {
                let pos = miss_count[0].fetch_add(1u32);
                if pos < miss_cap {
                    let x_lo = n_lo + u64::cast_from(i);
                    let mut x_hi = n_hi;
                    if x_lo < n_lo {
                        x_hi += 1u64;
                    }
                    let o = MISS_STRIDE * pos;
                    miss_data[o as usize] = u32::cast_from(x_lo);
                    miss_data[(o + 1u32) as usize] = u32::cast_from(x_lo >> 32u64);
                    miss_data[(o + 2u32) as usize] = u32::cast_from(x_hi);
                    miss_data[(o + 3u32) as usize] = u32::cast_from(x_hi >> 32u64);
                    miss_data[(o + 4u32) as usize] = u;
                }
            }
            // Step n -> n+1.
            if merged {
                // All five adds without their (rare) ripples, then one branch
                // for all of them: a word carried out iff bit 31 of its raw
                // sum is clear.
                let ts = fd_add_top(&mut sd, &ds, wds, ks, base);
                let tds = fd_add_const_top(&mut ds, 2u32, base);
                let tc = fd_add_top(&mut cd, &dc, wdc, kc, base);
                let tdc = fd_add_top(&mut dc, &ddc, wddc, wddc, base);
                let tddc = fd_add_const_top(&mut ddc, 6u32, base);
                let mut all: u32 = 0xFFFF_FFFFu32;
                if comptime!(ks < ws) {
                    all &= ts;
                }
                if comptime!(wds > 1) {
                    all &= tds;
                }
                if comptime!(kc < wc) {
                    all &= tc;
                }
                if comptime!(wddc < wdc) {
                    all &= tdc;
                }
                if comptime!(wddc > 1) {
                    all &= tddc;
                }
                if all < 0x8000_0000u32 {
                    let mut rec: u32 = 0u32;
                    if comptime!(ks < ws) {
                        if ts < 0x8000_0000u32 {
                            fd_ripple(&mut sd, ks, ws, base);
                            rec = 1u32;
                        }
                    }
                    if comptime!(wds > 1) {
                        if tds < 0x8000_0000u32 {
                            fd_ripple(&mut ds, 1u32, wds, base);
                        }
                    }
                    if comptime!(kc < wc) {
                        if tc < 0x8000_0000u32 {
                            fd_ripple(&mut cd, kc, wc, base);
                            rec = 1u32;
                        }
                    }
                    if comptime!(wddc < wdc) {
                        if tdc < 0x8000_0000u32 {
                            fd_ripple(&mut dc, wddc, wdc, base);
                        }
                    }
                    if comptime!(wddc > 1) {
                        if tddc < 0x8000_0000u32 {
                            fd_ripple(&mut ddc, 1u32, wddc, base);
                        }
                    }
                    if rec != 0u32 {
                        ms = fd_mask(&sd, 0u64, ks_dig, ls);
                        ms = fd_mask(&cd, ms, kc_dig, lc);
                    }
                }
            } else if static_mask {
                let r = fd_add_split(&mut sd, &ds, wds, ks, ws, base)
                    | fd_add_split(&mut cd, &dc, wdc, kc, wc, base);
                fd_add_const(&mut ds, 2u32, wds, base);
                fd_add_split(&mut dc, &ddc, wddc, wddc, wdc, base);
                fd_add_const(&mut ddc, 6u32, wddc, base);
                if r != 0u32 {
                    ms = fd_mask(&sd, 0u64, ks_dig, ls);
                    ms = fd_mask(&cd, ms, kc_dig, lc);
                }
            } else {
                fd_add(&mut sd, &ds, wds, ws, base);
                fd_add_const(&mut ds, 2u32, wds, base);
                fd_add(&mut cd, &dc, wdc, wc, base);
                fd_add(&mut dc, &ddc, wddc, wdc, base);
                fd_add_const(&mut ddc, 6u32, wddc, base);
            }
            i += 1u32;
        }

        off += stride;
    }

    sync_cube();
    let mut b = UNIT_POS_X;
    while b < hist_bins {
        let mut acc = 0u32;
        #[unroll]
        for c in 0..HIST_COPIES {
            acc += hist_s[(c * hist_bins + b) as usize].load();
        }
        if acc != 0u32 {
            hist[b as usize].fetch_add(acc);
        }
        b += CUBE_DIM_X;
    }
}

/// u32 slots per niceonly hit: n as four u32 limbs.
pub const NICEONLY_STRIDE: u32 = 4;

/// Capacity of the niceonly output buffer (in nice numbers) per field.
/// Genuinely nice numbers are astronomically rare; this is pure headroom.
const NICEONLY_OUT_CAPACITY: usize = 1 << 16;

/// The niceonly kernel: the `#[cube]` port of the removed Vulkan backend's
/// `niceonly_wgsl`, checking the stride-valid candidates of MSD-surviving
/// ranges reconstructed on-device from the residue table.
///
/// Shared per-candidate check: the low-digit modular prefilter, then the
/// full square/cube distinct-digit scan, appending hits (or, in probe
/// builds, prefilter survivors) to the output buffer. Factored out of
/// `niceonly_kernel` so the plain and plane-compacted enumeration paths run
/// the identical body.
// `collapsible_if`: `has_prefilter` is comptime and `ok` is runtime; the
// cube macro wants them in separate `if`s so the outer one folds away.
#[cube]
#[allow(
    clippy::too_many_arguments,
    clippy::too_many_lines,
    clippy::similar_names,
    clippy::many_single_char_names,
    clippy::collapsible_if,
    clippy::fn_params_excessive_bools
)]
pub(crate) fn candidate_check(
    n_lo: u64,
    n_hi: u64,
    sv_s: &mut SharedMemory<u32>,
    svb: u32,
    nice_out: &mut Array<u32>,
    nice_count: &mut Array<Atomic<u32>>,
    nice_cap: u32,
    #[comptime] base: u32,
    #[comptime] limbs: u32,
    #[comptime] chunk_digits: u32,
    #[comptime] chunk_div: u32,
    #[comptime] wide_chunk: bool,
    #[comptime] pre_limbs: u32,
    #[comptime] pre_chunk_digits: u32,
    #[comptime] pre_chunk_div: u32,
    #[comptime] probe: bool,
) {
    let sq_limbs = comptime!(2 * limbs);
    let cu_limbs = comptime!(3 * limbs);
    let two_masks = comptime!(base > 64);
    let has_prefilter = comptime!(pre_limbs > 0);

    let mut ok = true;
    // Low-digit modular prefilter: are the lowest
    // `pre_limbs * pre_chunk_digits` digits of n² and n³ all distinct?
    // Fixed-length and branch-free — lanes only save work when their
    // whole group is killed, and this kills ~98% of candidates. Held
    // as digit-chunks of base `pre_chunk_div < 2^16` so the truncated
    // multiplies stay in u32 (`x^k mod b^p == (x mod b^p)^k mod b^p`).
    if has_prefilter {
        if ok {
            // v = n's u32 limbs; a[r] = successive `mod pre_chunk_div`
            // chunks peeled off by the same split16 step the digit scan
            // uses.
            let mut v = Array::<u32>::new(limbs as usize);
            #[unroll]
            for i in 0..limbs {
                let shift = comptime!(((i & 1) * 32) as u64);
                if comptime!(i < 2) {
                    v[i as usize] = u32::cast_from(n_lo >> shift);
                } else {
                    v[i as usize] = u32::cast_from(n_hi >> shift);
                }
            }
            let mut a = Array::<u32>::new(pre_limbs as usize);
            #[unroll]
            for rr in 0..pre_limbs {
                let mut rem = 0u32;
                #[unroll]
                for i in 0..limbs {
                    let idx = comptime!(limbs - 1 - i);
                    let vi = v[idx as usize];
                    // Plain paired `%` here, unlike the digit scan: the
                    // mul-sub form of these four prefilter sites
                    // miscompiles under naga's MSL backend (survivors
                    // diverge from the host mirror on Apple GPUs, caught
                    // by the probe test), and the prefilter runs once per
                    // candidate so the pairing costs nothing measurable.
                    let c1 = (rem << 16u32) | (vi >> 16u32);
                    let q1 = c1 / pre_chunk_div;
                    let c2 = ((c1 % pre_chunk_div) << 16u32) | (vi & 0xFFFFu32);
                    rem = c2 % pre_chunk_div;
                    v[idx as usize] = (q1 << 16u32) | (c2 / pre_chunk_div);
                }
                a[rr as usize] = rem;
            }

            // sq = a², cu = sq·a, truncated schoolbook over digit-chunks —
            // dropping products at or above chunk `pre_limbs` is exactly
            // reduction mod pre_chunk_div^pre_limbs.
            let mut psq = Array::<u32>::new(pre_limbs as usize);
            #[unroll]
            for i in 0..pre_limbs {
                psq[i as usize] = 0u32;
            }
            #[unroll]
            for i in 0..pre_limbs {
                let mut carry = 0u32;
                #[unroll]
                for j in 0..comptime!(pre_limbs - i) {
                    let k = comptime!(i + j);
                    let t = a[i as usize] * a[j as usize] + psq[k as usize] + carry;
                    psq[k as usize] = t % pre_chunk_div;
                    carry = t / pre_chunk_div;
                }
            }
            let mut pcu = Array::<u32>::new(pre_limbs as usize);
            #[unroll]
            for i in 0..pre_limbs {
                pcu[i as usize] = 0u32;
            }
            #[unroll]
            for i in 0..pre_limbs {
                let mut carry = 0u32;
                #[unroll]
                for j in 0..comptime!(pre_limbs - i) {
                    let k = comptime!(i + j);
                    let t = psq[i as usize] * a[j as usize] + pcu[k as usize] + carry;
                    pcu[k as usize] = t % pre_chunk_div;
                    carry = t / pre_chunk_div;
                }
            }

            // Duplicate scan over both values' chunks; every chunk holds
            // exactly pre_chunk_digits real digits, leading zeros included
            // (that is what the host's digit-count guarantee buys).
            let mut p0 = 0u64;
            let mut p1 = 0u64;
            let mut dup = 0u64;
            let mut src: u32 = 0u32;
            while src < 2u32 {
                #[unroll]
                for i in 0..pre_limbs {
                    let mut c = if src == 0u32 {
                        psq[i as usize]
                    } else {
                        pcu[i as usize]
                    };
                    #[unroll]
                    for _k in 0..pre_chunk_digits {
                        let d = c % base;
                        c /= base;
                        if two_masks {
                            if d < 64u32 {
                                let bit = 1u64 << u64::cast_from(d);
                                dup |= p0 & bit;
                                p0 |= bit;
                            } else {
                                let bit = 1u64 << u64::cast_from(d - 64u32);
                                dup |= p1 & bit;
                                p1 |= bit;
                            }
                        } else {
                            let bit = 1u64 << u64::cast_from(d);
                            dup |= p0 & bit;
                            p0 |= bit;
                        }
                    }
                }
                src += 1u32;
            }
            if dup != 0u64 {
                ok = false;
            }
        }
    }

    // Full check: unique digits of n² and n³ together must number
    // exactly `base`. Same limb multiply and chunked scan as the
    // detailed kernel, but the scan bails at the first duplicate —
    // almost no candidate survives its n² scan. A probe build skips
    // it and reports the prefilter's survivors instead, which is the
    // only way a device test can see the filter itself (an
    // over-rejecting prefilter agrees with the CPU on any range
    // without a nice number in it — the v3.2.14 bug class).
    let mut m0 = 0u64;
    let mut m1 = 0u64;
    if ok && !probe {
        let mut nl = Array::<u32>::new(limbs as usize);
        #[unroll]
        for i in 0..limbs {
            let shift = comptime!(((i & 1) * 32) as u64);
            if comptime!(i < 2) {
                nl[i as usize] = u32::cast_from(n_lo >> shift);
            } else {
                nl[i as usize] = u32::cast_from(n_hi >> shift);
            }
        }
        let mut sq = Array::<u32>::new(sq_limbs as usize);
        #[unroll]
        for i in 0..sq_limbs {
            sq[i as usize] = 0u32;
        }
        #[unroll]
        for i in 0..limbs {
            let mut carry = 0u64;
            #[unroll]
            for jj in 0..limbs {
                let k = comptime!(i + jj);
                let t = u64::cast_from(nl[i as usize]) * u64::cast_from(nl[jj as usize])
                    + u64::cast_from(sq[k as usize])
                    + carry;
                sq[k as usize] = u32::cast_from(t);
                carry = t >> 32u64;
            }
            sq[comptime!(i + limbs) as usize] = u32::cast_from(carry);
        }

        // Scan n² first; n³ is only multiplied out if n² had no
        // duplicate (the same ordering worth 20-27% in the CUDA
        // kernel — the cube multiply is usually dead work). Straight-line
        // like the hand kernels: the sq scan reads a sq_limbs window, and
        // the cube is built directly in the scratch and destroyed by its
        // scan — no cu array, no extra copies, no runtime pass branch.
        // (The pass-loop version cost ~30% whole-kernel at bases without a
        // prefilter, where every candidate takes this path.)
        #[unroll]
        for i in 0..sq_limbs {
            sv_s[(svb + u32::cast_from(i)) as usize] = sq[i as usize];
        }
        let mut top: i32 = comptime!(sq_limbs as i32 - 1).runtime();
        while top >= 0 {
            if sv_s[(svb + u32::cast_from(top)) as usize] != 0u32 {
                break;
            }
            top -= 1;
        }
        while top >= 0 && ok {
            let mut rem = 0u32;
            if wide_chunk {
                let mut rem64 = 0u64;
                let mut i: i32 = top;
                while i >= 0 {
                    let cur =
                        (rem64 << 32u64) | u64::cast_from(sv_s[(svb + u32::cast_from(i)) as usize]);
                    // Quotient once, remainder by mul-sub: `%` would
                    // lower as a second independent multiply-high
                    // correction sequence (the hand kernels avoid it
                    // the same way).
                    let q = cur / u64::cast_from(chunk_div);
                    sv_s[(svb + u32::cast_from(i)) as usize] = u32::cast_from(q);
                    rem64 = cur - q * u64::cast_from(chunk_div);
                    i -= 1;
                }
                rem = u32::cast_from(rem64); // rem < chunk_div < 2^31
            } else {
                let mut i: i32 = top;
                while i >= 0 {
                    let vi = sv_s[(svb + u32::cast_from(i)) as usize];
                    let c1 = (rem << 16u32) | (vi >> 16u32);
                    let q1 = c1 / chunk_div;
                    let r1 = c1 - q1 * chunk_div;
                    let c2 = (r1 << 16u32) | (vi & 0xFFFFu32);
                    let q2 = c2 / chunk_div;
                    rem = c2 - q2 * chunk_div;
                    sv_s[(svb + u32::cast_from(i)) as usize] = (q1 << 16u32) | q2;
                    i -= 1;
                }
            }
            while top >= 0 {
                if sv_s[(svb + u32::cast_from(top)) as usize] != 0u32 {
                    break;
                }
                top -= 1;
            }

            let mut chunk = rem;
            let mut dup = 0u64;
            if top >= 0 {
                // Interior chunk: all chunk_digits digits, zeros included.
                #[unroll]
                for _k in 0..chunk_digits {
                    let cq = chunk / base;
                    let d = chunk - cq * base;
                    chunk = cq;
                    if two_masks {
                        if d < 64u32 {
                            let bit = 1u64 << u64::cast_from(d);
                            dup |= m0 & bit;
                            m0 |= bit;
                        } else {
                            let bit = 1u64 << u64::cast_from(d - 64u32);
                            dup |= m1 & bit;
                            m1 |= bit;
                        }
                    } else {
                        let bit = 1u64 << u64::cast_from(d);
                        dup |= m0 & bit;
                        m0 |= bit;
                    }
                }
            } else {
                // Most significant chunk: digits until zero.
                while chunk != 0u32 {
                    let cq = chunk / base;
                    let d = chunk - cq * base;
                    chunk = cq;
                    if two_masks {
                        if d < 64u32 {
                            let bit = 1u64 << u64::cast_from(d);
                            dup |= m0 & bit;
                            m0 |= bit;
                        } else {
                            let bit = 1u64 << u64::cast_from(d - 64u32);
                            dup |= m1 & bit;
                            m1 |= bit;
                        }
                    } else {
                        let bit = 1u64 << u64::cast_from(d);
                        dup |= m0 & bit;
                        m0 |= bit;
                    }
                }
            }
            if dup != 0u64 {
                ok = false;
            }
        }

        if ok {
            // cu = sq * n, built directly in the scratch and consumed there.
            #[unroll]
            for i in 0..cu_limbs {
                sv_s[(svb + u32::cast_from(i)) as usize] = 0u32;
            }
            #[unroll]
            for i in 0..sq_limbs {
                let mut carry = 0u64;
                #[unroll]
                for jj in 0..limbs {
                    let k = comptime!(i + jj);
                    let t = u64::cast_from(sq[i as usize]) * u64::cast_from(nl[jj as usize])
                        + u64::cast_from(sv_s[(svb + k) as usize])
                        + carry;
                    sv_s[(svb + k) as usize] = u32::cast_from(t);
                    carry = t >> 32u64;
                }
                sv_s[(svb + comptime!(i + limbs)) as usize] = u32::cast_from(carry);
            }
            let mut topc: i32 = comptime!(cu_limbs as i32 - 1).runtime();
            while topc >= 0 {
                if sv_s[(svb + u32::cast_from(topc)) as usize] != 0u32 {
                    break;
                }
                topc -= 1;
            }
            while topc >= 0 && ok {
                let mut rem = 0u32;
                if wide_chunk {
                    let mut rem64 = 0u64;
                    let mut i: i32 = topc;
                    while i >= 0 {
                        let cur = (rem64 << 32u64)
                            | u64::cast_from(sv_s[(svb + u32::cast_from(i)) as usize]);
                        // Quotient once, remainder by mul-sub: `%` would
                        // lower as a second independent multiply-high
                        // correction sequence (the hand kernels avoid it
                        // the same way).
                        let q = cur / u64::cast_from(chunk_div);
                        sv_s[(svb + u32::cast_from(i)) as usize] = u32::cast_from(q);
                        rem64 = cur - q * u64::cast_from(chunk_div);
                        i -= 1;
                    }
                    rem = u32::cast_from(rem64); // rem < chunk_div < 2^31
                } else {
                    let mut i: i32 = topc;
                    while i >= 0 {
                        let vi = sv_s[(svb + u32::cast_from(i)) as usize];
                        let c1 = (rem << 16u32) | (vi >> 16u32);
                        let q1 = c1 / chunk_div;
                        let r1 = c1 - q1 * chunk_div;
                        let c2 = (r1 << 16u32) | (vi & 0xFFFFu32);
                        let q2 = c2 / chunk_div;
                        rem = c2 - q2 * chunk_div;
                        sv_s[(svb + u32::cast_from(i)) as usize] = (q1 << 16u32) | q2;
                        i -= 1;
                    }
                }
                while topc >= 0 {
                    if sv_s[(svb + u32::cast_from(topc)) as usize] != 0u32 {
                        break;
                    }
                    topc -= 1;
                }

                let mut chunk = rem;
                let mut dup = 0u64;
                if topc >= 0 {
                    // Interior chunk: all chunk_digits digits, zeros included.
                    #[unroll]
                    for _k in 0..chunk_digits {
                        let cq = chunk / base;
                        let d = chunk - cq * base;
                        chunk = cq;
                        if two_masks {
                            if d < 64u32 {
                                let bit = 1u64 << u64::cast_from(d);
                                dup |= m0 & bit;
                                m0 |= bit;
                            } else {
                                let bit = 1u64 << u64::cast_from(d - 64u32);
                                dup |= m1 & bit;
                                m1 |= bit;
                            }
                        } else {
                            let bit = 1u64 << u64::cast_from(d);
                            dup |= m0 & bit;
                            m0 |= bit;
                        }
                    }
                } else {
                    // Most significant chunk: digits until zero.
                    while chunk != 0u32 {
                        let cq = chunk / base;
                        let d = chunk - cq * base;
                        chunk = cq;
                        if two_masks {
                            if d < 64u32 {
                                let bit = 1u64 << u64::cast_from(d);
                                dup |= m0 & bit;
                                m0 |= bit;
                            } else {
                                let bit = 1u64 << u64::cast_from(d - 64u32);
                                dup |= m1 & bit;
                                m1 |= bit;
                            }
                        } else {
                            let bit = 1u64 << u64::cast_from(d);
                            dup |= m0 & bit;
                            m0 |= bit;
                        }
                    }
                }
                if dup != 0u64 {
                    ok = false;
                }
            }
        }
    }

    if ok {
        let mut u = u32::cast_from(m0).count_ones() + u32::cast_from(m0 >> 32u64).count_ones();
        if two_masks {
            u += u32::cast_from(m1).count_ones() + u32::cast_from(m1 >> 32u64).count_ones();
        }
        if probe || u == base {
            let pos = nice_count[0].fetch_add(1u32);
            if pos < nice_cap {
                let o = NICEONLY_STRIDE * pos;
                nice_out[o as usize] = u32::cast_from(n_lo);
                nice_out[(o + 1u32) as usize] = u32::cast_from(n_lo >> 32u64);
                nice_out[(o + 2u32) as usize] = u32::cast_from(n_hi);
                nice_out[(o + 3u32) as usize] = u32::cast_from(n_hi >> 32u64);
            }
        }
    }
}

/// `lanes = 1 << lane_shift` threads cooperate on each range, striding
/// through its candidates by index — pure index arithmetic, no subgroup ops.
/// The g-th valid candidate at or after a range start is
/// `B0 + (g / R) * M + residues[g % R]`.
///
/// The stride modulus `M` and residue count `R` depend only on the base, so
/// they ride along as comptime parameters: every division below is by a
/// comptime constant, including the range offset's chunked Horner reduction
/// (`offset_chunk_bits` wide, u32 throughout — the construct RADV cannot
/// strength-reduce at 64 bits, avoided the same way the WGSL avoids it).
#[cube(launch_unchecked)]
// The single-character and lookalike names (m, g, j, rs/re, ...) deliberately
// match the generated WGSL, so the two kernels review side by side.
// `manual_midpoint`: `u32::midpoint` has no cube-dialect translation.
// manual_midpoint: `u32::midpoint` has no cube translation, so the kernel
// keeps the shift form.
// `collapsible_if`: `has_prefilter` is comptime and `ok` is runtime; the
// cube macro wants them in separate `if`s so the outer one folds away.
#[allow(
    clippy::too_many_arguments,
    clippy::too_many_lines,
    clippy::similar_names,
    clippy::many_single_char_names,
    clippy::manual_midpoint,
    clippy::collapsible_if,
    clippy::fn_params_excessive_bools
)]
fn niceonly_kernel(
    residues: &Array<u32>,
    range_offsets: &Array<u32>, // lo, hi pairs
    range_lens: &Array<u32>,
    nice_out: &mut Array<u32>,
    nice_count: &mut Array<Atomic<u32>>,
    low_masks: &Array<u32>, // per residue: lo,hi words of its exact low-digit mask
    range_masks: &Array<u32>, // per range: lo,hi words of its certificate
    fs0: u32,
    fs1: u32,
    fs2: u32,
    fs3: u32,
    fs_mod_m: u32,
    num_ranges: u32,
    nice_cap: u32,
    lane_shift: u32,
    #[comptime] base: u32,
    #[comptime] limbs: u32,
    #[comptime] chunk_digits: u32,
    #[comptime] chunk_div: u32,
    #[comptime] wide_chunk: bool,
    #[comptime] stride_m: u32,
    #[comptime] stride_r: u32,
    #[comptime] offset_chunk_bits: u32,
    #[comptime] pre_limbs: u32, // 0 disables the low-digit prefilter
    #[comptime] pre_chunk_digits: u32,
    #[comptime] pre_chunk_div: u32,
    #[comptime] probe: bool, // report prefilter survivors instead of nice numbers
    #[comptime] cross: bool, // cross-end residue filter (certificate x low mask)
    #[comptime] compact: bool, // plane-compact mask survivors before checking
    #[comptime] plane_scoped: bool, // compaction queue per plane (needs Plane::Sync)
) {
    let cu_limbs = comptime!(3 * limbs);
    let offset_chunks = comptime!(64 / offset_chunk_bits);
    let per_word = comptime!(32 / offset_chunk_bits);
    let offset_chunk_mask = comptime!((1u32 << offset_chunk_bits) - 1);

    let lanes = 1u32 << lane_shift;
    let lane = ABSOLUTE_POS_X & (lanes - 1u32);
    let nwarps = (CUBE_COUNT_X * CUBE_DIM_X) >> lane_shift;
    let fs_lo = (u64::cast_from(fs1) << 32u64) | u64::cast_from(fs0);
    let fs_hi = (u64::cast_from(fs3) << 32u64) | u64::cast_from(fs2);

    // Scratch for the digit scan, in shared memory: the split loop indexes
    // it at runtime, and a register-promoted array makes every such access a
    // compare/select chain over all words (~100 extra SASS compares at b50),
    // while local memory costs a round trip. One shared word per thread per
    // limb, padded to an odd stride so a warp's accesses spread across banks.
    let sv_pad = comptime!(cu_limbs | 1);
    let mut sv_s = SharedMemory::<u32>::new(comptime!((WORKGROUP_SIZE * (cu_limbs | 1)) as usize));
    let svb = UNIT_POS_X * sv_pad;

    if comptime!(compact && plane_scoped) {
        // Plane-scoped compaction: the same cursors and survivor production
        // as the cube-scoped path below, but each plane owns a private
        // queue (2*PLANE_DIM slots) in shared memory, takes positions
        // straight from plane_exclusive_sum, fences the write->drain handoff
        // with sync_plane, and drains in PLANE_DIM-wide waves. No cube
        // barrier, no serial walk over plane totals, and a plane whose
        // ranges are exhausted leaves as soon as its queue is dry instead
        // of idling through the other planes' iterations. Control flow is
        // plane-uniform: `qn` comes from plane_sum and `done` from
        // plane_all. Requires Plane::Sync (spirv/msl/cuda; not wgsl).
        let mut q_lo = SharedMemory::<u64>::new(comptime!((2 * WORKGROUP_SIZE) as usize));
        let mut q_hi = SharedMemory::<u64>::new(comptime!((2 * WORKGROUP_SIZE) as usize));
        let qbase = PLANE_POS * (2u32 * PLANE_DIM);
        let lane_in_plane = UNIT_POS_X % PLANE_DIM;

        let mut r = ABSOLUTE_POS_X >> lane_shift;
        let mut have_range = r < num_ranges;
        let mut need_setup = have_range;
        let mut rmask = 0u64;
        let mut re_lo = 0u64;
        let mut re_hi = 0u64;
        let mut b0_lo = 0u64;
        let mut b0_hi = 0u64;
        let mut g = 0u32;
        let mut qn = 0u32;
        loop {
            if need_setup {
                need_setup = false;
                let off_lo = range_offsets[(2u32 * r) as usize];
                let off_hi = range_offsets[(2u32 * r + 1u32) as usize];
                let offset = (u64::cast_from(off_hi) << 32u64) | u64::cast_from(off_lo);
                rmask = 0u64;
                if cross {
                    rmask = (u64::cast_from(range_masks[(2u32 * r + 1u32) as usize]) << 32u64)
                        | u64::cast_from(range_masks[(2u32 * r) as usize]);
                }
                let rs_lo = fs_lo + offset;
                let mut rs_hi = fs_hi;
                if rs_lo < fs_lo {
                    rs_hi += 1u64;
                }
                re_lo = rs_lo + u64::cast_from(range_lens[r as usize]);
                re_hi = rs_hi;
                if re_lo < rs_lo {
                    re_hi += 1u64;
                }
                let mut acc = 0u32;
                #[unroll]
                for k in 0..offset_chunks {
                    let word = if comptime!(k < per_word) {
                        off_hi
                    } else {
                        off_lo
                    };
                    let shift =
                        comptime!(32 - offset_chunk_bits - (k % per_word) * offset_chunk_bits);
                    acc = ((acc << offset_chunk_bits) | ((word >> shift) & offset_chunk_mask))
                        % stride_m;
                }
                let m = (fs_mod_m + acc) % stride_m;
                b0_lo = rs_lo - u64::cast_from(m);
                b0_hi = rs_hi;
                if rs_lo < u64::cast_from(m) {
                    b0_hi -= 1u64;
                }
                let mut lb_lo = 0u32;
                let mut lb_hi = stride_r.runtime();
                while lb_lo < lb_hi {
                    let mid = (lb_lo + lb_hi) >> 1u32;
                    if residues[mid as usize] < m {
                        lb_lo = mid + 1u32;
                    } else {
                        lb_hi = mid;
                    }
                }
                g = lb_lo + lane;
            }

            // One candidate ordinal per lane per iteration. A lane whose
            // range just ended spends the iteration advancing its cursor
            // and produces nothing.
            let mut pf = 0u32;
            let mut cand_lo = 0u64;
            let mut cand_hi = 0u64;
            if have_range {
                let cycle = g / stride_r;
                let j = g - cycle * stride_r;
                let add = u64::cast_from(cycle) * u64::cast_from(stride_m)
                    + u64::cast_from(residues[j as usize]);
                let n_lo = b0_lo + add;
                let mut n_hi = b0_hi;
                if n_lo < b0_lo {
                    n_hi += 1u64;
                }
                if n_hi > re_hi || (n_hi == re_hi && n_lo >= re_lo) {
                    r += nwarps;
                    if r < num_ranges {
                        need_setup = true;
                    } else {
                        have_range = false;
                    }
                } else {
                    let mut masked = false;
                    if cross {
                        let lm = (u64::cast_from(low_masks[(2u32 * j + 1u32) as usize]) << 32u64)
                            | u64::cast_from(low_masks[(2u32 * j) as usize]);
                        if (lm & rmask) != 0u64 {
                            masked = true;
                        }
                    }
                    if !masked {
                        pf = 1u32;
                        cand_lo = n_lo;
                        cand_hi = n_hi;
                    }
                    g += lanes;
                }
            }

            let idx_in_plane = plane_exclusive_sum(pf);
            let tot = plane_sum(pf);
            let done = plane_all(!have_range);
            if pf != 0u32 {
                let dst = (qbase + qn + idx_in_plane) as usize;
                q_lo[dst] = cand_lo;
                q_hi[dst] = cand_hi;
            }
            qn += tot;
            // Queue writes become visible to the drain below.
            sync_plane();

            let mut take = 0u32;
            if qn >= PLANE_DIM {
                take = PLANE_DIM;
            } else if done {
                take = qn;
            }
            if lane_in_plane < take {
                let s = (qbase + qn - take + lane_in_plane) as usize;
                candidate_check(
                    q_lo[s],
                    q_hi[s],
                    &mut sv_s,
                    svb,
                    nice_out,
                    nice_count,
                    nice_cap,
                    base,
                    limbs,
                    chunk_digits,
                    chunk_div,
                    wide_chunk,
                    pre_limbs,
                    pre_chunk_digits,
                    pre_chunk_div,
                    probe,
                );
            }
            qn -= take;
            // Drain reads are ordered before the next iteration reuses slots.
            sync_plane();
            if done && qn == 0u32 {
                break;
            }
        }
    } else if compact {
        // Cube-compacted enumeration (cross filter survivors only).
        //
        // Each lane keeps its own (range, ordinal) cursor - identical
        // candidate coverage to the plain path - but instead of checking a
        // survivor in place (where SIMT would idle every filtered lane
        // through its neighbors' checks), survivors queue in cube-scoped
        // shared memory and are checked in dense CUBE_DIM_X-wide waves.
        //
        // The queue is cube-scoped rather than plane-scoped because WGSL
        // has no plane barrier (cubecl's sync_plane panics in the wgsl
        // compiler), so the write->read handoff is fenced with sync_cube.
        // Queue positions come from a two-level scan: plane_exclusive_sum
        // within a plane, plane totals through shared memory. Control flow
        // is cube-uniform: every thread runs every iteration with exactly
        // two barriers, planes whose ranges are exhausted just stop
        // producing, and everyone leaves together once the queue is dry.
        // Wave-size agnostic: nothing assumes a plane width, only that it
        // divides CUBE_DIM_X.
        let mut q_lo = SharedMemory::<u64>::new(comptime!((2 * WORKGROUP_SIZE) as usize));
        let mut q_hi = SharedMemory::<u64>::new(comptime!((2 * WORKGROUP_SIZE) as usize));
        // Indexed by plane id; sized for the narrowest plane wgpu allows.
        let mut plane_tot = SharedMemory::<u32>::new(comptime!(WORKGROUP_SIZE as usize));
        let mut plane_done = SharedMemory::<u32>::new(comptime!(WORKGROUP_SIZE as usize));
        let my_plane = UNIT_POS_X / PLANE_DIM;
        let num_planes = CUBE_DIM_X / PLANE_DIM;

        let mut r = ABSOLUTE_POS_X >> lane_shift;
        let mut have_range = r < num_ranges;
        let mut need_setup = have_range;
        let mut rmask = 0u64;
        let mut re_lo = 0u64;
        let mut re_hi = 0u64;
        let mut b0_lo = 0u64;
        let mut b0_hi = 0u64;
        let mut g = 0u32;
        let mut qn = 0u32;
        loop {
            if need_setup {
                need_setup = false;
                let off_lo = range_offsets[(2u32 * r) as usize];
                let off_hi = range_offsets[(2u32 * r + 1u32) as usize];
                let offset = (u64::cast_from(off_hi) << 32u64) | u64::cast_from(off_lo);
                rmask = 0u64;
                if cross {
                    rmask = (u64::cast_from(range_masks[(2u32 * r + 1u32) as usize]) << 32u64)
                        | u64::cast_from(range_masks[(2u32 * r) as usize]);
                }
                let rs_lo = fs_lo + offset;
                let mut rs_hi = fs_hi;
                if rs_lo < fs_lo {
                    rs_hi += 1u64;
                }
                re_lo = rs_lo + u64::cast_from(range_lens[r as usize]);
                re_hi = rs_hi;
                if re_lo < rs_lo {
                    re_hi += 1u64;
                }
                let mut acc = 0u32;
                #[unroll]
                for k in 0..offset_chunks {
                    let word = if comptime!(k < per_word) {
                        off_hi
                    } else {
                        off_lo
                    };
                    let shift =
                        comptime!(32 - offset_chunk_bits - (k % per_word) * offset_chunk_bits);
                    acc = ((acc << offset_chunk_bits) | ((word >> shift) & offset_chunk_mask))
                        % stride_m;
                }
                let m = (fs_mod_m + acc) % stride_m;
                b0_lo = rs_lo - u64::cast_from(m);
                b0_hi = rs_hi;
                if rs_lo < u64::cast_from(m) {
                    b0_hi -= 1u64;
                }
                let mut lb_lo = 0u32;
                let mut lb_hi = stride_r.runtime();
                while lb_lo < lb_hi {
                    let mid = (lb_lo + lb_hi) >> 1u32;
                    if residues[mid as usize] < m {
                        lb_lo = mid + 1u32;
                    } else {
                        lb_hi = mid;
                    }
                }
                g = lb_lo + lane;
            }

            // One candidate ordinal per lane per iteration. A lane whose
            // range just ended spends the iteration advancing its cursor
            // and produces nothing.
            let mut pf = 0u32;
            let mut cand_lo = 0u64;
            let mut cand_hi = 0u64;
            if have_range {
                let cycle = g / stride_r;
                let j = g - cycle * stride_r;
                let add = u64::cast_from(cycle) * u64::cast_from(stride_m)
                    + u64::cast_from(residues[j as usize]);
                let n_lo = b0_lo + add;
                let mut n_hi = b0_hi;
                if n_lo < b0_lo {
                    n_hi += 1u64;
                }
                if n_hi > re_hi || (n_hi == re_hi && n_lo >= re_lo) {
                    r += nwarps;
                    if r < num_ranges {
                        need_setup = true;
                    } else {
                        have_range = false;
                    }
                } else {
                    let mut masked = false;
                    if cross {
                        let lm = (u64::cast_from(low_masks[(2u32 * j + 1u32) as usize]) << 32u64)
                            | u64::cast_from(low_masks[(2u32 * j) as usize]);
                        if (lm & rmask) != 0u64 {
                            masked = true;
                        }
                    }
                    if !masked {
                        pf = 1u32;
                        cand_lo = n_lo;
                        cand_hi = n_hi;
                    }
                    g += lanes;
                }
            }

            let idx_in_plane = plane_exclusive_sum(pf);
            let tot = plane_sum(pf);
            let pd = plane_all(!have_range);
            if UNIT_POS_PLANE == 0u32 {
                plane_tot[my_plane as usize] = tot;
                let mut d = 0u32;
                if pd {
                    d = 1u32;
                }
                plane_done[my_plane as usize] = d;
            }
            // Barrier 1: plane totals/done flags become visible, and the
            // previous iteration's drain reads are ordered before this
            // iteration's queue writes reuse those slots.
            sync_cube();

            let mut base_off = qn;
            let mut incoming = 0u32;
            let mut all_done = true;
            let mut p = 0u32;
            while p < num_planes {
                let t = plane_tot[p as usize];
                if p < my_plane {
                    base_off += t;
                }
                incoming += t;
                if plane_done[p as usize] == 0u32 {
                    all_done = false;
                }
                p += 1u32;
            }
            if pf != 0u32 {
                let dst = (base_off + idx_in_plane) as usize;
                q_lo[dst] = cand_lo;
                q_hi[dst] = cand_hi;
            }
            qn += incoming;
            // Barrier 2: queue writes become visible to the drain below.
            sync_cube();

            // qn and all_done are cube-uniform (derived from the shared
            // totals alone), so drain sizing and loop exit stay uniform.
            let mut take = 0u32;
            if qn >= CUBE_DIM_X {
                take = CUBE_DIM_X;
            } else if all_done {
                take = qn;
            }
            if UNIT_POS_X < take {
                let s = (qn - take + UNIT_POS_X) as usize;
                candidate_check(
                    q_lo[s],
                    q_hi[s],
                    &mut sv_s,
                    svb,
                    nice_out,
                    nice_count,
                    nice_cap,
                    base,
                    limbs,
                    chunk_digits,
                    chunk_div,
                    wide_chunk,
                    pre_limbs,
                    pre_chunk_digits,
                    pre_chunk_div,
                    probe,
                );
            }
            qn -= take;
            if all_done && qn == 0u32 {
                break;
            }
        }
    } else {
        let mut r = ABSOLUTE_POS_X >> lane_shift;
        while r < num_ranges {
            let off_lo = range_offsets[(2u32 * r) as usize];
            let off_hi = range_offsets[(2u32 * r + 1u32) as usize];
            let offset = (u64::cast_from(off_hi) << 32u64) | u64::cast_from(off_lo);

            // Cross-end certificate for this range (0 = no filtering; the
            // no-MSD bypass and mask-less analyses ship exactly that).
            let mut rmask = 0u64;
            if cross {
                rmask = (u64::cast_from(range_masks[(2u32 * r + 1u32) as usize]) << 32u64)
                    | u64::cast_from(range_masks[(2u32 * r) as usize]);
            }

            // range_start = field_start + offset, range_end = + len.
            let rs_lo = fs_lo + offset;
            let mut rs_hi = fs_hi;
            if rs_lo < fs_lo {
                rs_hi += 1u64;
            }
            let re_lo = rs_lo + u64::cast_from(range_lens[r as usize]);
            let mut re_hi = rs_hi;
            if re_lo < rs_lo {
                re_hi += 1u64;
            }

            // m = range_start mod M. The host pushes `field_start mod M`; only the
            // 64-bit offset is reduced here, MSB-first Horner over u32 chunks with
            // every divisor a comptime constant. Exact because acc < M <= 2^(32-c).
            let mut acc = 0u32;
            #[unroll]
            for k in 0..offset_chunks {
                let word = if comptime!(k < per_word) {
                    off_hi
                } else {
                    off_lo
                };
                let shift = comptime!(32 - offset_chunk_bits - (k % per_word) * offset_chunk_bits);
                acc =
                    ((acc << offset_chunk_bits) | ((word >> shift) & offset_chunk_mask)) % stride_m;
            }
            let m = (fs_mod_m + acc) % stride_m;

            // B0 = range_start - m.
            let b0_lo = rs_lo - u64::cast_from(m);
            let mut b0_hi = rs_hi;
            if rs_lo < u64::cast_from(m) {
                b0_hi -= 1u64;
            }

            // First residue index at or after m: lower_bound over the sorted table.
            let mut lb_lo = 0u32;
            let mut lb_hi = stride_r.runtime();
            while lb_lo < lb_hi {
                let mid = (lb_lo + lb_hi) >> 1u32;
                if residues[mid as usize] < m {
                    lb_lo = mid + 1u32;
                } else {
                    lb_hi = mid;
                }
            }

            let mut g = lb_lo + lane;
            loop {
                let cycle = g / stride_r;
                let j = g - cycle * stride_r;
                let add = u64::cast_from(cycle) * u64::cast_from(stride_m)
                    + u64::cast_from(residues[j as usize]);
                let n_lo = b0_lo + add;
                let mut n_hi = b0_hi;
                if n_lo < b0_lo {
                    n_hi += 1u64;
                }
                if n_hi > re_hi || (n_hi == re_hi && n_lo >= re_lo) {
                    break;
                }

                // Cross-end residue filter: residue j's exact low output digits
                // against the range's certain high digits. An intersection is a
                // duplicated digit across two distinct positions - skip the
                // candidate without checking anything.
                let mut masked = false;
                if cross {
                    let lm = (u64::cast_from(low_masks[(2u32 * j + 1u32) as usize]) << 32u64)
                        | u64::cast_from(low_masks[(2u32 * j) as usize]);
                    if (lm & rmask) != 0u64 {
                        masked = true;
                    }
                }
                if !masked {
                    candidate_check(
                        n_lo,
                        n_hi,
                        &mut sv_s,
                        svb,
                        nice_out,
                        nice_count,
                        nice_cap,
                        base,
                        limbs,
                        chunk_digits,
                        chunk_div,
                        wide_chunk,
                        pre_limbs,
                        pre_chunk_digits,
                        pre_chunk_div,
                        probe,
                    );
                }

                g += lanes;
            }
            r += nwarps;
        }
    }
}

/// One-thread smoke kernel for [`CubeclContext::new_cuda`]: proves the
/// runtime can actually compile and run something before init reports
/// success.
#[cube(launch_unchecked)]
fn smoke_kernel(out: &mut Array<u32>) {
    if ABSOLUTE_POS_X == 0 {
        out[0] = 42u32;
    }
}

// ============================================================================
// Host side
// ============================================================================

/// The process-wide wgpu client: `init_setup` registers the device server
/// and is not idempotent, so setup runs exactly once per process and later
/// contexts clone the client — shared by the sync and async constructors.
static WGPU_DEFAULT: OnceLock<(
    cubecl::prelude::ComputeClient<cubecl::wgpu::WgpuRuntime>,
    String,
)> = OnceLock::new();

/// What a timed sample of the overlap join on one field did
/// ([`CubeclContext::join_sample`]).
#[derive(Clone, Debug)]
pub struct JoinSample {
    /// The field's slices, and partitions per slice (`b^p`).
    pub slices: usize,
    pub partitions: u128,
    /// The field's size in first slices
    /// ([`crate::overlap_join::slice_weight`]).
    pub slice_weight: f64,
    /// Partitions per launch planned for the first slice.
    pub slots: usize,
    /// Partitions sampled, all from the first slice.
    pub sampled: usize,
    /// Host setup of the first slice on the calling thread (bottom list and
    /// top layer), and the device's wall time for the sampled partitions.
    pub setup_secs: f64,
    pub run_secs: f64,
    /// Pairs that passed the AND, the prefilter's survivors, partitions
    /// re-run after a list overflowed, and the hits, over the sample.
    pub survivors: u64,
    pub checked: u64,
    pub retried_partitions: usize,
    pub hits: Vec<u128>,
    /// Layouts the device did not run during the sample, each re-run in a
    /// smaller one (see [`crate::join_plan::JoinCeiling`]).
    pub refused: u32,
}

/// One initialized `CubeCL` device: wgpu everywhere, or the native CUDA
/// runtime when built with `cubecl-cuda` (the meaningful NVIDIA comparison,
/// since it exercises `CubeCL`'s CUDA codegen against the hand kernels).
pub enum CubeclContext {
    Wgpu {
        client: cubecl::prelude::ComputeClient<cubecl::wgpu::WgpuRuntime>,
        device_name: String,
        /// Per-base niceonly plans, cached across fields — see [`NiceonlyPlan`].
        /// Shared with the niceonly pipeline's dispatch thread.
        niceonly_plans: Arc<Mutex<HashMap<u32, Arc<NiceonlyPlan>>>>,
        /// The continuous niceonly pipeline, started on the first niceonly field.
        niceonly_pipeline:
            Mutex<Option<NiceonlyPipeline<CubeclPendingField<cubecl::wgpu::WgpuRuntime>>>>,
        /// The overlap join's pipeline, started on the first field it takes
        /// (see [`crate::join_plan::plan_join`]).
        join_pipeline: Mutex<Option<JoinPipeline>>,
        /// The largest join layout this device runs, as far as it has shown.
        join_ceiling: Arc<JoinCeiling>,
    },
    #[cfg(feature = "cubecl-cuda")]
    Cuda {
        client: cubecl::prelude::ComputeClient<cubecl::cuda::CudaRuntime>,
        device_name: String,
        /// Per-base niceonly plans, cached across fields — see [`NiceonlyPlan`].
        /// Shared with the niceonly pipeline's dispatch thread.
        niceonly_plans: Arc<Mutex<HashMap<u32, Arc<NiceonlyPlan>>>>,
        /// The continuous niceonly pipeline, started on the first niceonly field.
        niceonly_pipeline:
            Mutex<Option<NiceonlyPipeline<CubeclPendingField<cubecl::cuda::CudaRuntime>>>>,
        /// The overlap join's pipeline, started on the first field it takes
        /// (see [`crate::join_plan::plan_join`]).
        join_pipeline: Mutex<Option<JoinPipeline>>,
        /// The largest join layout this device runs, as far as it has shown.
        join_ceiling: Arc<JoinCeiling>,
    },
    #[cfg(feature = "cubecl-hip")]
    Hip {
        client: cubecl::prelude::ComputeClient<cubecl::hip::HipRuntime>,
        device_name: String,
        /// Per-base niceonly plans, cached across fields — see [`NiceonlyPlan`].
        /// Shared with the niceonly pipeline's dispatch thread.
        niceonly_plans: Arc<Mutex<HashMap<u32, Arc<NiceonlyPlan>>>>,
        /// The continuous niceonly pipeline, started on the first niceonly field.
        niceonly_pipeline:
            Mutex<Option<NiceonlyPipeline<CubeclPendingField<cubecl::hip::HipRuntime>>>>,
        /// The overlap join's pipeline, started on the first field it takes
        /// (see [`crate::join_plan::plan_join`]).
        join_pipeline: Mutex<Option<JoinPipeline>>,
        /// The largest join layout this device runs, as far as it has shown.
        join_ceiling: Arc<JoinCeiling>,
    },
}

/// The device's real name from the CUDA driver, e.g. `NVIDIA A100-SXM4-40GB`.
///
/// `CubeCL`'s CUDA runtime does not expose one — its `Runtime::name` is the
/// static string `"cuda"` — so this asks the driver directly. That matters
/// well beyond cosmetics: this string is `hardware.gpu_model` in every
/// benchmark report and every `--telemetry` submission, and both the API's
/// `/estimate` and the fleet controller match offers against it. A
/// `gpu_models_match` against a placeholder fails for every real GPU, which
/// drops the estimate to the `floor` stage and makes the sample unusable. And
/// since #133 fixed the runtime headers, `cubecl-cuda` is the backend
/// `--gpu-backend auto` picks for detailed mode on NVIDIA, so a placeholder
/// here would silently blank the GPU identity of the entire detailed corpus.
///
/// Asked at *device* level (`cuDeviceGet` + `cuDeviceGetName`), which touches
/// no context and so cannot disturb the one `CubeCL` has just built. `cuInit`
/// is idempotent and has already run inside `CudaRuntime::client`; it is
/// repeated here only so the helper does not depend on call order.
///
/// The backend itself is *not* folded into this string — the hand-CUDA arm
/// reports the bare driver name too, and `hardware.gpu_backend` already
/// distinguishes the two. Keeping them identical is what lets a `cuda` and a
/// `cubecl-cuda` report of the same card land in the same estimator bucket.
///
/// Falls back to the old placeholder if the driver refuses, which is the only
/// case a caller can still see. cudarc *panics* rather than erroring when
/// `libcuda` cannot be loaded (the same trap the NVRTC probe in
/// `client_process_cuda` documents), so the driver calls run under
/// `catch_unwind` — a name for a report is never worth taking the process down.
#[cfg(feature = "cubecl-cuda")]
fn cuda_device_name(device_index: usize) -> String {
    let name = std::panic::catch_unwind(|| {
        use cudarc::driver::result::{device, init};
        // Idempotent, and `CudaRuntime::client` has already run it; repeated
        // here only so this helper does not depend on call order.
        init().ok()?;
        let ordinal = i32::try_from(device_index).ok()?;
        let dev = device::get(ordinal).ok()?;
        device::get_name(dev).ok()
    });
    match name {
        Ok(Some(name)) if !name.trim().is_empty() => name,
        _ => {
            warn!(
                "CUDA driver did not name device {device_index}; \
                 benchmark and telemetry reports will carry a placeholder"
            );
            format!("cubecl-cuda device {device_index}")
        }
    }
}

impl CubeclContext {
    /// Runtime options for the wgpu backend.
    ///
    /// In a browser this pins `ExclusivePages`, so every buffer is allocated
    /// at exactly its own size. The default `SubSlices` pool instead builds a
    /// ladder of page sizes down from `max_storage_buffer_binding_size` — the
    /// *adapter's* maximum, since cubecl requests adapter limits — so on a
    /// discrete card it will try to allocate pages of hundreds of megabytes
    /// to satisfy a 21 MB request. A browser gives a tab far less GPU memory
    /// than the card has, and refuses: observed on an RX 9070 XT under
    /// `LibreWolf` 149 as "Not enough memory left", then an invalid buffer,
    /// then a panic in `CubeCL`'s buffer mapping. Native builds keep the
    /// default pooling, which is measurably fine on the same card.
    ///
    /// This backend allocates a handful of long-lived buffers per field, so
    /// exclusive pages cost nothing here.
    fn runtime_options() -> cubecl::wgpu::RuntimeOptions {
        #[allow(unused_mut)]
        let mut options = cubecl::wgpu::RuntimeOptions::default();
        #[cfg(target_family = "wasm")]
        {
            options.memory_config = cubecl::wgpu::MemoryConfiguration::ExclusivePages;
        }
        options
    }

    /// Initialize on the runtime's default device (discrete first, then
    /// integrated, then software rasterizers), recording the adapter's
    /// marketing name for benchmark reports and the estimator.
    ///
    /// `init_setup` registers the device server and is not idempotent, so the
    /// setup runs exactly once per process; later contexts clone the client.
    ///
    /// # Errors
    /// Returns an error if no wgpu device is available.
    pub fn new_default() -> Result<Self> {
        let (client, device_name) = WGPU_DEFAULT.get_or_init(|| {
            let device = cubecl::wgpu::WgpuDevice::default();
            let setup = cubecl::wgpu::init_setup::<cubecl::wgpu::AutoGraphicsApi>(
                &device,
                Self::runtime_options(),
            );
            // Include the resolved graphics API: AutoGraphicsApi may pick
            // DX12 on Windows, and reports need to know which API actually
            // ran.
            let info = setup.adapter.get_info();
            let client = cubecl::wgpu::WgpuRuntime::client(&device);
            let device_name = format!(
                "{} ({:?}, {})",
                info.name,
                info.backend,
                <cubecl::wgpu::WgpuRuntime as cubecl::prelude::Runtime>::name(&client)
            );
            (client, device_name)
        });
        Ok(Self::Wgpu {
            client: client.clone(),
            device_name: device_name.clone(),
            niceonly_plans: Arc::new(Mutex::new(HashMap::new())),
            niceonly_pipeline: Mutex::new(None),
            join_pipeline: Mutex::new(None),
            join_ceiling: Arc::new(JoinCeiling::for_device(device_name)),
        })
    }

    /// As [`Self::new_default`], but awaiting adapter acquisition — the only
    /// form a browser permits (`init_setup` panics on wasm by design). Native
    /// callers can use either; both share one process-wide client.
    ///
    /// # Errors
    /// Returns an error if no wgpu device is available.
    ///
    /// # Panics
    /// Cannot in practice: the read of the just-initialized process-wide
    /// client is infallible once the set above has happened.
    pub async fn new_default_async() -> Result<Self> {
        if WGPU_DEFAULT.get().is_none() {
            let device = cubecl::wgpu::WgpuDevice::default();
            let setup = cubecl::wgpu::init_setup_async::<cubecl::wgpu::AutoGraphicsApi>(
                &device,
                Self::runtime_options(),
            )
            .await;
            let info = setup.adapter.get_info();
            let client = cubecl::wgpu::WgpuRuntime::client(&device);
            let device_name = format!(
                "{} ({:?}, {})",
                info.name,
                info.backend,
                <cubecl::wgpu::WgpuRuntime as cubecl::prelude::Runtime>::name(&client)
            );
            // A racing initializer winning this set is fine: both describe
            // the same process-wide runtime registration.
            let _ = WGPU_DEFAULT.set((client, device_name));
        }
        let (client, device_name) = WGPU_DEFAULT
            .get()
            .expect("just initialized the wgpu default client");
        Ok(Self::Wgpu {
            client: client.clone(),
            device_name: device_name.clone(),
            niceonly_plans: Arc::new(Mutex::new(HashMap::new())),
            niceonly_pipeline: Mutex::new(None),
            join_pipeline: Mutex::new(None),
            join_ceiling: Arc::new(JoinCeiling::for_device(device_name)),
        })
    }

    /// Initialize `CubeCL`'s native CUDA runtime on `device_index`.
    ///
    /// # Errors
    /// Returns an error if CUDA is unavailable.
    /// A working NVIDIA *driver* is not enough: kernel compilation needs
    /// NVRTC from the CUDA toolkit, `CubeCL` compiles lazily at first
    /// launch, and a missing NVRTC panics `CubeCL`'s server thread while
    /// launches keep reporting success — a completed run whose results are
    /// silently zero. So init proves the runtime end-to-end with a smoke
    /// kernel before reporting success, the same contract as the hand
    /// backends' init-time compile checks.
    #[cfg(feature = "cubecl-cuda")]
    pub fn new_cuda(device_index: usize) -> Result<Self> {
        let device = cubecl::cuda::CudaDevice::new(device_index);
        let client = cubecl::cuda::CudaRuntime::client(&device);

        let out = client.create(cubecl::bytes::Bytes::from_elems(vec![0u32; 1]));
        unsafe {
            smoke_kernel::launch_unchecked::<cubecl::cuda::CudaRuntime>(
                &client,
                CubeCount::Static(1, 1, 1),
                CubeDim::new_1d(1),
                ArrayArg::from_raw_parts(out.clone(), 1),
            );
        }
        let bytes = client.read_one(out).map_err(|e| {
            anyhow::anyhow!(
                "CubeCL CUDA smoke test failed to read back: {e:?} \
                 (is the CUDA toolkit, including NVRTC, installed?)"
            )
        })?;
        ensure!(
            u32::from_bytes(&bytes)[0] == 42,
            "CubeCL CUDA smoke kernel did not run \
             (is the CUDA toolkit, including NVRTC, installed?)"
        );

        Ok(Self::Cuda {
            client,
            device_name: cuda_device_name(device_index),
            niceonly_plans: Arc::new(Mutex::new(HashMap::new())),
            niceonly_pipeline: Mutex::new(None),
            join_pipeline: Mutex::new(None),
            join_ceiling: Arc::default(),
        })
    }

    /// Initialize on the native HIP (`ROCm`) runtime, device `device_index`.
    ///
    /// Same smoke-kernel contract as [`Self::new_cuda`]: hiprtc must compile
    /// and run something before init reports success.
    ///
    /// # Errors
    /// Returns an error if the HIP runtime cannot compile or run a kernel.
    #[cfg(feature = "cubecl-hip")]
    pub fn new_hip(device_index: usize) -> Result<Self> {
        let device = cubecl::hip::AmdDevice::new(device_index);
        let client = cubecl::hip::HipRuntime::client(&device);

        let out = client.create(cubecl::bytes::Bytes::from_elems(vec![0u32; 1]));
        unsafe {
            smoke_kernel::launch_unchecked::<cubecl::hip::HipRuntime>(
                &client,
                CubeCount::Static(1, 1, 1),
                CubeDim::new_1d(1),
                ArrayArg::from_raw_parts(out.clone(), 1),
            );
        }
        let bytes = client.read_one(out).map_err(|e| {
            anyhow::anyhow!("CubeCL HIP smoke test failed to read back: {e:?} (is ROCm installed?)")
        })?;
        ensure!(
            u32::from_bytes(&bytes)[0] == 42,
            "CubeCL HIP smoke kernel did not run (is ROCm installed?)"
        );

        Ok(Self::Hip {
            client,
            device_name: format!("cubecl-hip device {device_index}"),
            niceonly_plans: Arc::new(Mutex::new(HashMap::new())),
            niceonly_pipeline: Mutex::new(None),
            join_pipeline: Mutex::new(None),
            join_ceiling: Arc::default(),
        })
    }

    /// Time the overlap join on the partitions `parts` of the first slice of
    /// `range`, planned, batched and launched exactly as a production field
    /// is, without running the whole field. This is how the benchmark
    /// measures the join at production field sizes: the field's time is
    /// about `setup + (partitions / sampled) · run` per slice, times the
    /// slices. Kernels compile on first use, so time a throwaway sample
    /// first. `Ok(Err(reason))` if the field takes the stride pipeline on
    /// this device.
    ///
    /// # Errors
    /// Device failures.
    pub fn join_sample(
        &self,
        base: u32,
        range: &FieldSize,
        parts: &[u32],
    ) -> Result<std::result::Result<JoinSample, StrideReason>> {
        let lim = match NiceonlyGpu::join_limits(self) {
            Ok(lim) => lim,
            Err(reason) => return Ok(Err(reason)),
        };
        let field = match plan_join(base, range, lim) {
            Ok(field) => field,
            Err(reason) => return Ok(Err(reason)),
        };
        let (hits, st) = match self {
            Self::Wgpu {
                client,
                join_ceiling,
                ..
            } => run_slices(client, &field, 1, parts, join_ceiling)?,
            #[cfg(feature = "cubecl-cuda")]
            Self::Cuda {
                client,
                join_ceiling,
                ..
            } => run_slices(client, &field, 1, parts, join_ceiling)?,
            #[cfg(feature = "cubecl-hip")]
            Self::Hip {
                client,
                join_ceiling,
                ..
            } => run_slices(client, &field, 1, parts, join_ceiling)?,
        };
        Ok(Ok(JoinSample {
            slices: field.slice_count(),
            partitions: field.partitions(),
            slice_weight: crate::overlap_join::slice_weight(&field.slices),
            slots: field.plan.slots,
            sampled: parts.len(),
            setup_secs: st.setup_secs,
            run_secs: st.device_secs,
            survivors: st.survivors,
            checked: st.checked,
            retried_partitions: st.retried_partitions,
            hits: hits.iter().map(|h| h.number).collect(),
            refused: st.refused,
        }))
    }

    /// The adapter/device name, for reports.
    #[must_use]
    pub fn device_name(&self) -> String {
        match self {
            Self::Wgpu { device_name, .. } => device_name.clone(),
            #[cfg(feature = "cubecl-cuda")]
            Self::Cuda { device_name, .. } => device_name.clone(),
            #[cfg(feature = "cubecl-hip")]
            Self::Hip { device_name, .. } => device_name.clone(),
        }
    }

    /// Which runtime this context drives, matching the `--gpu-backend` value
    /// that selects it — for benchmark reports and submission telemetry.
    #[must_use]
    pub fn backend_name(&self) -> &'static str {
        match self {
            Self::Wgpu { .. } => "cubecl",
            #[cfg(feature = "cubecl-cuda")]
            Self::Cuda { .. } => "cubecl-cuda",
            #[cfg(feature = "cubecl-hip")]
            Self::Hip { .. } => "cubecl-hip",
        }
    }
}

/// `CubeCL` implementation of `process_range_detailed`.
///
/// **Range semantics**: half-open [`range_start`, `range_end`).
///
/// # Errors
/// Returns an error on any device failure or if the near-miss buffer
/// overflows.
pub fn process_range_detailed_cubecl(
    ctx: &CubeclContext,
    range: &FieldSize,
    base: u32,
) -> Result<FieldResults> {
    cubecl::future::block_on(process_range_detailed_cubecl_async(ctx, range, base))
}

/// As [`process_range_detailed_cubecl`], awaiting device reads instead of
/// blocking on them — the only form a browser permits. The sync wrapper is
/// this future under `block_on`, so both paths run the same body (and the
/// native device tests cover it).
///
/// # Errors
/// Returns an error on any device failure or if the near-miss buffer
/// overflows.
pub async fn process_range_detailed_cubecl_async(
    ctx: &CubeclContext,
    range: &FieldSize,
    base: u32,
) -> Result<FieldResults> {
    process_range_detailed_cubecl_with(ctx, range, base, FdOptions::from_env()).await
}

/// Knobs for the finite-difference detailed kernel (experiment).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct FdOptions {
    /// Use the finite-difference kernel where it applies (wide chunk flavor,
    /// base <= 64, inside the base's regular digit-count interval).
    pub enabled: bool,
    /// Consecutive candidates per thread.
    pub run_len: u32,
    /// Candidates per dispatch (the histogram drain interval follows).
    pub batch: u128,
    /// Cache the mask of the slow-changing high words of n² and n³.
    pub static_mask: bool,
    /// One branch per step for all rare carries (needs `static_mask`).
    pub merged: bool,
    /// Per-thread packed histogram instead of one shared atomic per number.
    pub hist_local: bool,
    /// Masks of the two lowest digits of n² and n³ from a b²-entry table
    /// (v4; measured within 2 % of v3, so off by default).
    pub table: bool,
}

impl FdOptions {
    /// Enabled, run length `run_len`, default batch and variant.
    #[must_use]
    pub fn with_run(run_len: u32) -> Self {
        Self {
            enabled: true,
            run_len,
            batch: CUBECL_BATCH_SIZE,
            static_mask: true,
            merged: true,
            hist_local: false,
            table: false,
        }
    }
}

impl FdOptions {
    /// `NICE_DETAILED_FD=0` disables it; `NICE_FD_RUN` and `NICE_FD_BATCH`
    /// set the run length and batch size.
    #[must_use]
    pub fn from_env() -> Self {
        let enabled = std::env::var("NICE_DETAILED_FD").map_or(true, |v| v != "0");
        let run_len = std::env::var("NICE_FD_RUN")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(128u32)
            .max(1);
        let batch = std::env::var("NICE_FD_BATCH")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(CUBECL_BATCH_SIZE)
            .clamp(1, 1_000_000_000);
        let static_mask = std::env::var("NICE_FD_STATIC").map_or(true, |v| v != "0");
        let hist_local = std::env::var("NICE_FD_HIST").is_ok_and(|v| v == "1");
        let merged = static_mask && std::env::var("NICE_FD_MERGED").map_or(true, |v| v != "0");
        let table = std::env::var("NICE_FD_TABLE").is_ok_and(|v| v == "1");
        Self {
            enabled,
            run_len,
            batch,
            static_mask,
            merged,
            hist_local,
            table,
        }
    }
}

/// Digit counts the finite-difference kernel is specialised for at one base:
/// n² has `ls` digits and n³ `lc` for every n in `[reg_lo, reg_hi)`, and the
/// addends 2n+1, 3n²+3n+1, 6n+6 fit in `lds`, `ldc`, `lddc` digits up to
/// `reg_hi`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct FdPlan {
    pub ls: u32,
    pub lc: u32,
    pub lds: u32,
    pub ldc: u32,
    pub lddc: u32,
    pub reg_lo: u128,
    pub reg_hi: u128,
}

/// Number of base-`base` digits of `x` (0 for 0).
fn natural_digits(x: &malachite::natural::Natural, base: u32) -> u32 {
    use malachite::base::num::arithmetic::traits::DivAssignRem;
    let mut y = x.clone();
    let mut c = 0;
    while y != 0u32 {
        y.div_assign_rem(malachite::natural::Natural::from(base));
        c += 1;
    }
    c
}

/// The finite-difference plan for `base`, or `None` where the kernel does not
/// apply (no u128 range, or a base above 64, which needs two masks).
#[must_use]
pub fn fd_plan(base: u32) -> Option<FdPlan> {
    use malachite::base::num::arithmetic::traits::{CeilingRoot, Pow};
    use malachite::natural::Natural;
    if base > 64 || !gpu_supports_base(base) {
        return None;
    }
    let range = crate::base_range::get_base_range_u128(base).ok()??;
    let b = Natural::from(base);
    let n0 = Natural::from(range.range_start);
    let ls = natural_digits(&(&n0 * &n0), base);
    let lc = natural_digits(&(&n0 * &n0 * &n0), base);
    let lo_s = b.clone().pow(u64::from(ls - 1)).ceiling_root(2);
    let lo_c = b.clone().pow(u64::from(lc - 1)).ceiling_root(3);
    let hi_s = b.clone().pow(u64::from(ls)).ceiling_root(2);
    let hi_c = b.pow(u64::from(lc)).ceiling_root(3);
    let reg_lo = u128::try_from(&lo_s.max(lo_c)).ok()?;
    let hi = hi_s.min(hi_c);
    let reg_hi = u128::try_from(&hi).ok()?;
    let lds = natural_digits(&(&hi * Natural::from(2u32) + Natural::from(1u32)), base);
    let ldc = natural_digits(
        &(&hi * &hi * Natural::from(3u32) + &hi * Natural::from(3u32) + Natural::from(1u32)),
        base,
    );
    let lddc = natural_digits(&(&hi * Natural::from(6u32) + Natural::from(6u32)), base);
    Some(FdPlan {
        ls,
        lc,
        lds,
        ldc,
        lddc,
        reg_lo,
        reg_hi,
    })
}

/// As [`process_range_detailed_cubecl_async`] with explicit
/// finite-difference knobs (tests and A/B runs).
///
/// # Errors
/// Returns an error on any device failure or if the near-miss buffer
/// overflows.
pub async fn process_range_detailed_cubecl_with(
    ctx: &CubeclContext,
    range: &FieldSize,
    base: u32,
    fd: FdOptions,
) -> Result<FieldResults> {
    if !gpu_supports_base(base) {
        warn!("base {base} not supported on GPU, falling back to CPU for this field");
        return Ok(process_range_detailed(range, base));
    }

    match ctx {
        CubeclContext::Wgpu { client, .. } => {
            detailed_impl(client, range, base, wide_chunk_for(client), fd).await
        }
        #[cfg(feature = "cubecl-cuda")]
        CubeclContext::Cuda { client, .. } => {
            detailed_impl(client, range, base, wide_chunk_for(client), fd).await
        }
        #[cfg(feature = "cubecl-hip")]
        CubeclContext::Hip { client, .. } => {
            detailed_impl(client, range, base, wide_chunk_for(client), fd).await
        }
    }
}

/// Which chunk-scan flavor a client should run.
///
/// The wide flavor divides limb pairs with 64-bit arithmetic and is the
/// CUDA-native form. On wgpu it is *legal* wherever the device exposes
/// `u64` and the shader goes through one of `CubeCL`'s direct compilers
/// (`wgpu<spirv>` / `wgpu<msl>`; naga's MSL backend miscompiles its checked
/// u64 division), but legal is not fast: on an Apple M4 under `wgpu<msl>`
/// the wide flavor measured 4.6x *slower* than split16 (64-bit integer
/// division is emulated on Apple GPUs). So wgpu defaults to split16 and
/// `NICE_CUBECL_WIDE=1` opts in for A/B runs on devices where it is legal;
/// `NICE_CUBECL_WIDE=0` forces split16 anywhere. A forced wide flavor on a
/// device without u64 fails at shader compile time, loudly.
pub(crate) fn wide_chunk_for<R: cubecl::prelude::Runtime>(
    client: &cubecl::prelude::ComputeClient<R>,
) -> bool {
    let name = R::name(client);
    let cuda = name.contains("cuda");
    let direct = name.contains("spirv") || name.contains("msl") || name == "hip";
    let u64_ok = client
        .properties()
        .features
        .supports_type(cubecl::ir::Type::scalar(cubecl::ir::ElemType::UInt(
            cubecl::ir::UIntKind::U64,
        )));
    // HIP joins CUDA on the wide side: hipcc lowers the u64 constant
    // divisions to multiply-high like nvcc does, and the wide flavor measured
    // 1.04x (b40) / 1.24x (b50) over split16 in detailed mode on an
    // RX 9070 XT — the opposite of the same card under SPIR-V.
    let wide = match std::env::var("NICE_CUBECL_WIDE").ok().as_deref() {
        Some("0") => false,
        Some(_) => true,
        None => cuda || name == "hip",
    };
    if wide && !cuda && !(direct && u64_ok) {
        warn!(
            "NICE_CUBECL_WIDE=1 on {name} (direct compiler {direct}, u64 {u64_ok}): \
             the wide chunk scan is not expected to compile here"
        );
    }
    debug!("CubeCL chunk flavor on {name}: wide {wide} (direct compiler {direct}, u64 {u64_ok})");
    wide
}

/// Read one histogram buffer and fold its bins into the accumulator.
///
/// An async fn rather than a closure (async closures aren't stable), and
/// `read_async` rather than `read_one` so [`detailed_impl`] stays runnable
/// on wasm, where a future cannot block.
pub(crate) async fn drain<R: cubecl::prelude::Runtime>(
    client: &cubecl::prelude::ComputeClient<R>,
    handle: cubecl::server::Handle,
    histogram: &mut [u128],
) -> Result<()> {
    let bytes = client
        .read_async(vec![handle])
        .await
        .map_err(|e| anyhow::anyhow!("histogram read failed: {e:?}"))?
        .remove(0);
    let bins = u32::from_bytes(&bytes);
    for (acc, &bin) in histogram.iter_mut().zip(bins.iter()) {
        *acc += u128::from(bin);
    }
    Ok(())
}

/// Runtime-generic body of [`process_range_detailed_cubecl`].
#[allow(clippy::too_many_lines)]
async fn detailed_impl<R: cubecl::prelude::Runtime>(
    client: &cubecl::prelude::ComputeClient<R>,
    range: &FieldSize,
    base: u32,
    wide_chunk: bool,
    fd: FdOptions,
) -> Result<FieldResults> {
    /// Batches launched between blocking histogram drains; the overflow
    /// bound is checked below.
    const DRAIN_INTERVAL: usize = 64;
    const _: () = assert!((DRAIN_INTERVAL as u128) * CUBECL_BATCH_SIZE < u32::MAX as u128);
    // Packed-histogram window: 16 bins around the typical unique count
    // (about 0.59 b at the live bases); only speed depends on it.
    #[allow(clippy::cast_possible_truncation, clippy::cast_sign_loss)]
    let hist_lo = ((f64::from(base) * 0.59).round() as u32).saturating_sub(8).min(base.saturating_sub(15));
    let plan = if fd.enabled && wide_chunk {
        fd_plan(base)
    } else {
        None
    };
    let use_table = fd.table && plan.is_some_and(|p| p.ls >= 2 && p.lc >= 2);
    let low_table: Vec<u64> = if use_table {
        let b = u64::from(base);
        (0..b * b)
            .map(|r| {
                let sq = (r * r) % (b * b);
                let cu = (sq * r) % (b * b);
                (1u64 << (sq % b)) | (1u64 << (sq / b)) | (1u64 << (cu % b)) | (1u64 << (cu / b))
            })
            .collect()
    } else {
        vec![0u64; 1]
    };
    let low_table_len = low_table.len();
    let low_table_handle = client.create(cubecl::bytes::Bytes::from_elems(low_table));
    let batch_size = if plan.is_some() {
        fd.batch
    } else {
        CUBECL_BATCH_SIZE
    };
    #[allow(clippy::cast_possible_truncation)]
    let drain_interval = ((u128::from(u32::MAX) / batch_size) as usize).clamp(1, DRAIN_INTERVAL);

    let start_time = Instant::now();
    let limbs = n_limbs(base).with_context(|| format!("base {base} has no u128 range"))?;
    let (chunk_digits, chunk_div) = if wide_chunk {
        crate::gpu_config::chunk_constants(base)
    } else {
        chunk_constants_u16(base)
    };
    let cutoff = get_near_miss_cutoff(base);
    let hist_bins = (base + 1) as usize;

    let miss_count_handle = client.create(cubecl::bytes::Bytes::from_elems(vec![0u32; 1]));
    let miss_data_handle =
        client.empty(NEAR_MISS_CAPACITY * MISS_STRIDE as usize * core::mem::size_of::<u32>());

    let mut histogram = vec![0u128; hist_bins];

    // Batches launch back-to-back asynchronously — the blocking histogram
    // read is the only stream sync, so doing it per batch put a GPU-idle
    // bubble after every ~12ms of work (~25% whole-field on an RTX 4060,
    // the hand-CUDA backend's entire lead). Each candidate increments
    // exactly one u32 bin, so a bin grows by at most CUBECL_BATCH_SIZE per
    // batch and one drain per DRAIN_INTERVAL batches stays overflow-safe:
    // 64 * 50e6 < u32::MAX. (The hand-CUDA kernel sidesteps this with u64
    // bins; WGSL has no u64 atomics, and this host loop serves both.)
    let mut hist_handle = client.create(cubecl::bytes::Bytes::from_elems(vec![0u32; hist_bins]));
    let mut undrained = 0usize;
    // Ticks on submission: without a per-batch sync there is nothing cheap
    // to wait on here, so the bar runs ahead of the device by however many
    // batches the runtime queues. It still shows the field is moving.
    let progress = crate::progress::FieldProgress::begin(range, batch_size);

    for batch in range.chunks(batch_size) {
      // Split the batch at the finite-difference kernel's regular interval:
      // the inside goes to it, anything outside to the per-number kernel.
      let mut pieces: Vec<(u128, u128, bool)> = Vec::with_capacity(3);
      match plan {
          Some(p) => {
              let (a, z) = (batch.start(), batch.end());
              let lo = a.max(p.reg_lo).min(z);
              let hi = z.min(p.reg_hi).max(lo);
              if lo > a {
                  pieces.push((a, lo - a, false));
              }
              if hi > lo {
                  pieces.push((lo, hi - lo, true));
              }
              if z > hi {
                  pieces.push((hi, z - hi, false));
              }
          }
          None => pieces.push((batch.start(), batch.size(), false)),
      }
      for (start, count, use_fd) in pieces {
        let count = count as u64;
        if let (true, Some(p)) = (use_fd, plan) {
            let runs = count.div_ceil(u64::from(fd.run_len));
            let cubes = u32::try_from(runs.div_ceil(u64::from(WORKGROUP_SIZE)))
                .unwrap_or(65_535)
                .clamp(1, 65_535);
            unsafe {
                detailed_fd_kernel::launch_unchecked::<R>(
                    client,
                    CubeCount::Static(cubes, 1, 1),
                    CubeDim::new_1d(WORKGROUP_SIZE),
                    ArrayArg::from_raw_parts(hist_handle.clone(), hist_bins),
                    ArrayArg::from_raw_parts(miss_count_handle.clone(), 1),
                    ArrayArg::from_raw_parts(
                        miss_data_handle.clone(),
                        NEAR_MISS_CAPACITY * MISS_STRIDE as usize,
                    ),
                    ArrayArg::from_raw_parts(low_table_handle.clone(), low_table_len),
                    start as u32,
                    (start >> 32) as u32,
                    (start >> 64) as u32,
                    (start >> 96) as u32,
                    count as u32,
                    (count >> 32) as u32,
                    fd.run_len,
                    NEAR_MISS_CAPACITY as u32,
                    base,
                    limbs,
                    chunk_digits,
                    chunk_div,
                    cutoff,
                    p.ls,
                    p.lc,
                    p.lds,
                    p.ldc,
                    p.lddc,
                    fd.static_mask,
                    fd.static_mask && fd.merged,
                    fd.hist_local,
                    hist_lo,
                    use_table,
                );
            }
            continue;
        }
        let cubes = u32::try_from(count.div_ceil(u64::from(WORKGROUP_SIZE)))
            .unwrap_or(MAX_CUBES)
            .clamp(1, MAX_CUBES);

        unsafe {
            detailed_kernel::launch_unchecked::<R>(
                client,
                CubeCount::Static(cubes, 1, 1),
                CubeDim::new_1d(WORKGROUP_SIZE),
                ArrayArg::from_raw_parts(hist_handle.clone(), hist_bins),
                ArrayArg::from_raw_parts(miss_count_handle.clone(), 1),
                ArrayArg::from_raw_parts(
                    miss_data_handle.clone(),
                    NEAR_MISS_CAPACITY * MISS_STRIDE as usize,
                ),
                start as u32,
                (start >> 32) as u32,
                (start >> 64) as u32,
                (start >> 96) as u32,
                count as u32,
                (count >> 32) as u32,
                NEAR_MISS_CAPACITY as u32,
                base,
                limbs,
                chunk_digits,
                chunk_div,
                cutoff,
                wide_chunk,
            );
        }
      }

        // Submit this batch on its own, because a GPU driver kills a
        // submission that runs too long. CubeCL aggregates dispatches into one
        // command buffer and submits only at `CUBECL_WGPU_MAX_TASKS` tasks (32
        // by default) or at the next read — a bound tuned for ML kernels that
        // run in microseconds. This one is a persistent grid-stride kernel over
        // a whole `CUBECL_BATCH_SIZE`, ~0.12 s per dispatch at base 50 on an
        // AMD 860M, so without this flush a single submission holds the *whole
        // field*: `DETAILED_SEARCH_MAX_FIELD_SIZE` is 20 batches, which is
        // 2.4 s at base 50 and 6.3 s at base 80. Measured on Linux/RADV,
        // amdgpu resets a gfx job at ~2 s ("ring gfx_0.0.0 timeout ... device
        // wedged") and the device is lost for the rest of the process; Windows
        // has the same 2 s TDR, and only survives because the GPUs it was
        // tested on run a field inside it. So the task cap is not the bound
        // that matters — the field is — and raising or lowering it does not
        // help.
        //
        // Flushing per batch is free: `flush` submits without waiting, and one
        // batch already saturates the device (measured interleaved, 80 batches
        // at base 50: 9.76 s median against 10.00 s for the aggregated form).
        client
            .flush()
            .map_err(|e| anyhow::anyhow!("stream flush failed: {e:?}"))?;

        undrained += 1;
        if undrained == drain_interval {
            drain(client, hist_handle, &mut histogram).await?;
            hist_handle = client.create(cubecl::bytes::Bytes::from_elems(vec![0u32; hist_bins]));
            undrained = 0;
        }
        progress.tick();
    }
    drain(client, hist_handle, &mut histogram).await?;

    // Every candidate lands in exactly one bin, so a mismatch means the
    // device silently did nothing for some batch — refuse to report
    // fabricated zeros. Observed failure modes differ per runtime, so the
    // hint does too: a CUDA runtime without NVRTC, or a wgpu device the
    // driver's watchdog reset.
    let counted: u128 = histogram.iter().sum();
    let hint = if R::name(client).contains("cuda") {
        "is the CUDA toolkit, including NVRTC, installed?"
    } else {
        "was the device reset by the driver's watchdog? check the kernel log"
    };
    ensure!(
        counted == range.size(),
        "GPU histogram counted {counted} of {} candidates; \
         the device dropped work ({hint})",
        range.size()
    );

    // Near misses.
    let bytes = client
        .read_async(vec![miss_count_handle.clone()])
        .await
        .map_err(|e| anyhow::anyhow!("miss count read failed: {e:?}"))?
        .remove(0);
    let miss_total = u32::from_bytes(&bytes)[0] as usize;
    ensure!(
        miss_total <= NEAR_MISS_CAPACITY,
        "near-miss buffer overflow: {miss_total} > {NEAR_MISS_CAPACITY}"
    );
    // Read back only the records written (none when there are none): the
    // whole buffer is 20 MB, a ~1-2 ms PCIe copy per field that is a fifth
    // of a benchmark window at finite-difference speed.
    // NICE_MISS_READ_ALL=1 restores the full read for A/B runs.
    let read_all = std::env::var("NICE_MISS_READ_ALL").is_ok_and(|v| v == "1");
    let miss_bytes = if miss_total == 0 && !read_all {
        None
    } else {
        let handle = if read_all {
            miss_data_handle
        } else {
            miss_data_handle.offset_end(
                ((NEAR_MISS_CAPACITY - miss_total) * MISS_STRIDE as usize * core::mem::size_of::<u32>())
                    as u64,
            )
        };
        Some(
            client
                .read_async(vec![handle])
                .await
                .map_err(|e| anyhow::anyhow!("miss data read failed: {e:?}"))?
                .remove(0),
        )
    };
    let words: &[u32] = miss_bytes.as_ref().map_or(&[], |b| u32::from_bytes(b));
    let mut nice_numbers: Vec<NiceNumberSimple> = (0..miss_total)
        .map(|i| {
            let o = i * MISS_STRIDE as usize;
            let number = u128::from(words[o])
                | (u128::from(words[o + 1]) << 32)
                | (u128::from(words[o + 2]) << 64)
                | (u128::from(words[o + 3]) << 96);
            NiceNumberSimple {
                number,
                num_uniques: words[o + 4],
            }
        })
        .collect();
    nice_numbers.sort_by_key(|n| n.number);

    let distribution: Vec<UniquesDistributionSimple> = (1..=base)
        .map(|i| UniquesDistributionSimple {
            num_uniques: i,
            count: histogram[i as usize],
        })
        .collect();

    #[allow(clippy::cast_precision_loss)]
    {
        let secs = start_time.elapsed().as_secs_f64();
        debug!(
            "CubeCL detailed b{base}: {:.2e} numbers in {secs:.2}s ({:.2e} n/s), {} near-misses",
            range.size() as f64,
            range.size() as f64 / secs,
            nice_numbers.len(),
        );
    }

    Ok(FieldResults {
        distribution,
        nice_numbers,
    })
}

/// The `CubeCL` nice-only path. The MSD prefix filter runs on the CPU (all
/// cores) and the GPU checks the surviving ranges' stride-valid candidates,
/// which it reconstructs from the residue table on-device; production-size
/// fields go to the overlap join instead. Either way the nice numbers found
/// are exactly the CPU path's: the coarser MSD floor makes the GPU's
/// candidate set a superset, and the final check is the same. Fields start
/// through [`crate::gpu_route::begin_niceonly`].
impl NiceonlyGpu for CubeclContext {
    fn join_limits(&self) -> std::result::Result<JoinLimits, StrideReason> {
        match self {
            Self::Wgpu {
                client,
                device_name,
                join_ceiling,
                ..
            } => join_limits_on(client, device_name, join_ceiling),
            #[cfg(feature = "cubecl-cuda")]
            Self::Cuda {
                client,
                device_name,
                join_ceiling,
                ..
            } => join_limits_on(client, device_name, join_ceiling),
            #[cfg(feature = "cubecl-hip")]
            Self::Hip {
                client,
                device_name,
                join_ceiling,
                ..
            } => join_limits_on(client, device_name, join_ceiling),
        }
    }

    fn begin_stride(&self, range: &FieldSize, base: u32) -> Result<FieldTicket> {
        let software = is_software_rasterizer(&self.device_name());
        match self {
            Self::Wgpu {
                client,
                niceonly_plans,
                niceonly_pipeline,
                ..
            } => begin_stride_on(
                client,
                niceonly_plans,
                niceonly_pipeline,
                software,
                range,
                base,
            ),
            #[cfg(feature = "cubecl-cuda")]
            Self::Cuda {
                client,
                niceonly_plans,
                niceonly_pipeline,
                ..
            } => begin_stride_on(
                client,
                niceonly_plans,
                niceonly_pipeline,
                software,
                range,
                base,
            ),
            #[cfg(feature = "cubecl-hip")]
            Self::Hip {
                client,
                niceonly_plans,
                niceonly_pipeline,
                ..
            } => begin_stride_on(
                client,
                niceonly_plans,
                niceonly_pipeline,
                software,
                range,
                base,
            ),
        }
    }

    fn begin_join(&self, field: JoinField) -> Result<FieldTicket> {
        match self {
            Self::Wgpu {
                client,
                join_pipeline,
                join_ceiling,
                ..
            } => begin_join_on(client, join_pipeline, join_ceiling, field),
            #[cfg(feature = "cubecl-cuda")]
            Self::Cuda {
                client,
                join_pipeline,
                join_ceiling,
                ..
            } => begin_join_on(client, join_pipeline, join_ceiling, field),
            #[cfg(feature = "cubecl-hip")]
            Self::Hip {
                client,
                join_pipeline,
                join_ceiling,
                ..
            } => begin_join_on(client, join_pipeline, join_ceiling, field),
        }
    }

    fn finish(&self, ticket: FieldTicket) -> Result<(FieldResults, NiceonlyStats)> {
        match self {
            Self::Wgpu {
                niceonly_pipeline,
                join_pipeline,
                ..
            } => finish_on(niceonly_pipeline, join_pipeline, ticket),
            #[cfg(feature = "cubecl-cuda")]
            Self::Cuda {
                niceonly_pipeline,
                join_pipeline,
                ..
            } => finish_on(niceonly_pipeline, join_pipeline, ticket),
            #[cfg(feature = "cubecl-hip")]
            Self::Hip {
                niceonly_pipeline,
                join_pipeline,
                ..
            } => finish_on(niceonly_pipeline, join_pipeline, ticket),
        }
    }
}

/// Runtime-generic body of [`CubeclContext::begin_stride`]: the stride
/// pipeline, started on the first field.
fn begin_stride_on<R: cubecl::prelude::Runtime>(
    client: &cubecl::prelude::ComputeClient<R>,
    plans: &Arc<Mutex<HashMap<u32, Arc<NiceonlyPlan>>>>,
    pipeline: &Mutex<Option<NiceonlyPipeline<CubeclPendingField<R>>>>,
    software: bool,
    range: &FieldSize,
    base: u32,
) -> Result<FieldTicket> {
    let mut guard = pipeline.lock().unwrap();
    let pipeline = guard.get_or_insert_with(|| {
        NiceonlyPipeline::start(
            "CubeCL",
            CubeclNiceonlySink {
                client: client.clone(),
                plans: plans.clone(),
                wide_chunk: wide_chunk_for(client),
                software,
                open: HashMap::new(),
                inflight: std::collections::VecDeque::new(),
            },
        )
    });
    pipeline.push(base, range)
}

/// Runtime-generic body of [`CubeclContext::begin_join`]: the join's
/// pipeline, started on the first field it takes.
fn begin_join_on<R: cubecl::prelude::Runtime>(
    client: &cubecl::prelude::ComputeClient<R>,
    join_pipeline: &Mutex<Option<JoinPipeline>>,
    join_ceiling: &Arc<JoinCeiling>,
    field: JoinField,
) -> Result<FieldTicket> {
    join_pipeline
        .lock()
        .unwrap()
        .get_or_insert_with(|| JoinPipeline::start(client.clone(), join_ceiling.clone()))
        .push(field)
}

/// Runtime-generic body of [`CubeclContext::finish`]: the ticket says which
/// pipeline holds the field.
fn finish_on<R: cubecl::prelude::Runtime>(
    pipeline: &Mutex<Option<NiceonlyPipeline<CubeclPendingField<R>>>>,
    join_pipeline: &Mutex<Option<JoinPipeline>>,
    ticket: FieldTicket,
) -> Result<(FieldResults, NiceonlyStats)> {
    let (stats, nice_numbers) = match ticket.route() {
        Route::Join => join_pipeline
            .lock()
            .unwrap()
            .as_mut()
            .ok_or_else(|| anyhow::anyhow!("no overlap join field has been begun"))?
            .next_result(ticket)?,
        Route::Stride => {
            let mut guard = pipeline.lock().unwrap();
            let pipeline = guard
                .as_mut()
                .ok_or_else(|| anyhow::anyhow!("no niceonly field has been begun"))?;
            let (stats, nice_numbers) = pipeline.next_result(ticket)?;
            debug!(
                "CubeCL niceonly pipeline: {} ranges in {} dispatches, found {}",
                stats.num_ranges,
                stats.launches,
                nice_numbers.len()
            );
            (stats, nice_numbers)
        }
    };
    Ok((
        FieldResults {
            distribution: Vec::new(),
            nice_numbers,
        },
        stats,
    ))
}

/// The join's own account (re-runs, layout, survivor counts) of the last
/// field `finish` returned from the join.
#[cfg(test)]
pub(crate) fn last_join_stats(ctx: &CubeclContext) -> Option<crate::cubecl_join::JoinFieldStats> {
    let pipeline = match ctx {
        CubeclContext::Wgpu { join_pipeline, .. } => join_pipeline,
        #[cfg(feature = "cubecl-cuda")]
        CubeclContext::Cuda { join_pipeline, .. } => join_pipeline,
        #[cfg(feature = "cubecl-hip")]
        CubeclContext::Hip { join_pipeline, .. } => join_pipeline,
    };
    pipeline
        .lock()
        .unwrap()
        .as_ref()
        .and_then(JoinPipeline::last_field_stats)
}

/// Device memory the context's client has in use and has reserved, bytes.
#[cfg(test)]
pub(crate) fn memory_usage(ctx: &CubeclContext) -> Option<(u64, u64)> {
    let usage = match ctx {
        CubeclContext::Wgpu { client, .. } => client.memory_usage(),
        #[cfg(feature = "cubecl-cuda")]
        CubeclContext::Cuda { client, .. } => client.memory_usage(),
        #[cfg(feature = "cubecl-hip")]
        CubeclContext::Hip { client, .. } => client.memory_usage(),
    }
    .ok()?;
    Some((usage.bytes_in_use, usage.bytes_reserved))
}

/// A fence on one launched batch: the client's `sync` future taken right
/// after the launch and polled once on the spot. The flush is eager, but on
/// wgpu the submitted-work-done callback is registered inside the future's
/// first poll, and such a callback covers everything submitted *at
/// registration*; polling immediately pins it to the work queued up to this
/// launch, so awaiting it later does not also wait for whatever was launched
/// since.
pub(crate) type LaunchFence = cubecl::future::DynFut<Result<(), cubecl::server::ServerError>>;

/// Take a fence on everything the client has queued so far. `None` if it
/// resolved on the spot (nothing pending).
pub(crate) fn launch_fence<R: cubecl::prelude::Runtime>(
    client: &cubecl::prelude::ComputeClient<R>,
) -> Result<Option<LaunchFence>> {
    use std::task::{Context, Poll, Waker};
    let mut fence = client.sync();
    let mut cx = Context::from_waker(Waker::noop());
    match fence.as_mut().poll(&mut cx) {
        Poll::Ready(r) => {
            r.map_err(|e| anyhow::anyhow!("launch fence failed: {e:?}"))?;
            Ok(None)
        }
        Poll::Pending => Ok(Some(fence)),
    }
}

/// The device end of the niceonly pipeline for a `CubeCL` runtime: one
/// [`CubeclNiceonlyRun`] per open field, plus the launch count that bounds
/// the work in flight.
struct CubeclNiceonlySink<R: cubecl::prelude::Runtime> {
    client: cubecl::prelude::ComputeClient<R>,
    plans: Arc<Mutex<HashMap<u32, Arc<NiceonlyPlan>>>>,
    wide_chunk: bool,
    /// The adapter is a software rasterizer (plans then keep the plane-scoped
    /// queue off — see [`is_software_rasterizer`]).
    software: bool,
    open: HashMap<u64, CubeclNiceonlyRun<R>>,
    /// One fence per launched batch, oldest first: the `CubeCL` analogue of
    /// the CUDA sink's event ring. Before the ring exceeds
    /// [`BATCHES_IN_FLIGHT`] the oldest fence is awaited, so the dispatch
    /// thread blocks for exactly one batch at a time and the descriptor
    /// channel keeps draining. A full `client.sync()` every N launches was
    /// tried first and is the wrong shape: it parks the dispatch thread for N
    /// batches while the channel fills and the MSD workers park unseen, so
    /// "device behind" reads as saturated and the floor controller drove
    /// the floor to its minimum on a 9070 XT and an M4 (a third of the
    /// pinned throughput).
    inflight: std::collections::VecDeque<LaunchFence>,
}

impl<R: cubecl::prelude::Runtime> RangeSink for CubeclNiceonlySink<R> {
    type Pending = CubeclPendingField<R>;

    fn begin_field(&mut self, seq: u64, base: u32, range: &FieldSize) -> Result<()> {
        let plan = cached_plan(&self.plans, &self.client, base, self.software)?;
        let run =
            CubeclNiceonlyRun::from_plan(&self.client, plan, base, range.start(), self.wide_chunk)?;
        self.open.insert(seq, run);
        Ok(())
    }

    fn launch(&mut self, field: u64, offsets: &[u64], lens: &[u32], masks: &[u64]) -> Result<()> {
        let run = self
            .open
            .get_mut(&field)
            .ok_or_else(|| anyhow::anyhow!("launch for a field that is not open ({field})"))?;
        // Backpressure: wait for the oldest batch before adding another,
        // once `BATCHES_IN_FLIGHT` are outstanding.
        while self.inflight.len() >= BATCHES_IN_FLIGHT {
            if let Some(oldest) = self.inflight.pop_front() {
                cubecl::future::block_on(oldest)
                    .map_err(|e| anyhow::anyhow!("launch fence failed: {e:?}"))?;
            }
        }
        run.launch(field, offsets, lens, masks)?;
        if let Some(fence) = launch_fence(&self.client)? {
            self.inflight.push_back(fence);
        }
        Ok(())
    }

    fn end_field(&mut self, seq: u64) -> Result<Self::Pending> {
        let mut run = self
            .open
            .remove(&seq)
            .ok_or_else(|| anyhow::anyhow!("end of a field that is not open ({seq})"))?;
        run.end_field(seq)
    }
}

/// Whether a wgpu adapter name denotes a software rasterizer. CI runs the
/// device tests on lavapipe, and llvmpipe mishandles a subgroup-scope
/// control barrier inside plane-divergent control flow (the plane-scoped
/// compaction queue returned 2 of 283 survivors there, and was exact with
/// the barriers removed), so that path stays off on such adapters.
/// Whether a device can run the overlap join's kernels, which use plane
/// (subgroup) operations with no fallback. `CubeCL` reports them on every
/// CUDA, HIP and Metal device and on wgpu adapters with subgroups, but never
/// on CPU-type adapters, where the software rasterizers (lavapipe,
/// `SwiftShader`) run them anyway. The stride pipeline has a path without
/// them, so a device that fails this keeps every field there.
fn joins_on(plane_ops: bool, device: &str) -> bool {
    plane_ops || is_software_rasterizer(device)
}

/// [`NiceonlyGpu::join_limits`] for one `CubeCL` device: its limits within
/// the layouts it has shown it runs (`ceiling`), unless it cannot run the
/// join's kernels at all ([`joins_on`]).
fn join_limits_on<R: cubecl::prelude::Runtime>(
    client: &cubecl::prelude::ComputeClient<R>,
    device: &str,
    ceiling: &JoinCeiling,
) -> std::result::Result<JoinLimits, StrideReason> {
    let plane_ops = client
        .properties()
        .features
        .plane
        .contains(cubecl::ir::features::Plane::Ops);
    if !joins_on(plane_ops, device) {
        static WARNED: std::sync::Once = std::sync::Once::new();
        WARNED.call_once(|| {
            warn!(
                "overlap join: {device} has no subgroup operations, which the join's \
                 kernels need; nice-only fields use the stride pipeline"
            );
        });
        return Err(StrideReason::NoPlaneOps);
    }
    Ok(ceiling.cap(limits_of(client)))
}

pub(crate) fn is_software_rasterizer(device: &str) -> bool {
    let squashed = device.to_lowercase().replace(' ', "");
    ["llvmpipe", "lavapipe", "swiftshader", "softwarerasterizer"]
        .iter()
        .any(|s| squashed.contains(s))
}

/// Fetch the base's plan from the context cache, building it on first use.
///
/// # Panics
/// Panics if the cache mutex was poisoned by an earlier panic.
fn cached_plan<R: cubecl::prelude::Runtime>(
    plans: &Mutex<HashMap<u32, Arc<NiceonlyPlan>>>,
    client: &cubecl::prelude::ComputeClient<R>,
    base: u32,
    software: bool,
) -> Result<Arc<NiceonlyPlan>> {
    if let Some(plan) = plans.lock().unwrap().get(&base) {
        return Ok(plan.clone());
    }
    // Built outside the lock: seconds of CPU work for a large modulus, and
    // another thread asking for a *different* base should not wait on it.
    // A racing build of the same base wastes one table walk, harmlessly.
    let plan = Arc::new(NiceonlyPlan::build(client, base, software)?);
    Ok(plans.lock().unwrap().entry(base).or_insert(plan).clone())
}

/// Per-base niceonly state that survives across fields: the stride-table
/// constants and the residue table already on the device. The analog of the
/// CUDA backend's cached `NiceonlyPlan`.
///
/// Building this is *expensive*: `StrideTable::new` walks the whole modulus
/// on one CPU thread (8.6e6 steps at base 52). Rebuilt per field, that walk
/// dominated the pipeline at benchmark-window field sizes — measured on an
/// RTX 4060, half of every b50 scenario's wall time was table rebuilds the
/// hand backends never do.
// Public because it names a field type of the public context enum; its own
// fields stay private, so nothing outside this module can touch it.
pub struct NiceonlyPlan {
    stride_m: u32,
    stride_r: u32,
    residues: cubecl::server::Handle,
    prefilter: Option<VulkanPrefilterParams>,
    /// Per-residue exact low-digit masks on device as (lo, hi) u32 words,
    /// for the cross-end residue filter; a 2-word dummy when `cross` is off.
    low_masks: cubecl::server::Handle,
    cross: bool,
    /// Plane-compact the filter's survivors before checking them (requires
    /// `cross` and a device with plane ops).
    compact: bool,
    /// Use the plane-scoped compaction queue instead of the cube-scoped one
    /// (default on under `wgpu<spirv>` and `cuda`; `NICE_CUBECL_PLANE_COMPACT=0|1`
    /// overrides; requires `compact` and a device with plane barriers).
    plane_compact: bool,
}

impl NiceonlyPlan {
    /// # Errors
    /// Returns an error for an unconfigurable base. Residue-empty bases must
    /// be short-circuited by the caller before any stride table is built.
    fn build<R: cubecl::prelude::Runtime>(
        client: &cubecl::prelude::ComputeClient<R>,
        base: u32,
        software: bool,
    ) -> Result<Self> {
        let table = StrideTable::new(base, GPU_LSD_K);
        ensure!(
            !table.valid_residues.is_empty(),
            "no valid stride residues for base {base} (residue-empty base?)"
        );
        ensure!(
            table.modulus <= MAX_STRIDE_MODULUS,
            "stride modulus {} exceeds the kernel's {MAX_STRIDE_MODULUS} bound for base {base}",
            table.modulus
        );
        #[allow(clippy::cast_possible_truncation)]
        let stride_m = table.modulus as u32;
        let stride_r = u32::try_from(table.valid_residues.len())
            .with_context(|| format!("residue count overflows u32 for base {base}"))?;
        // Cross-end residue filter: wherever the low-mask table exists
        // (base <= 64).
        let cross = !table.low_digit_masks.is_empty();
        // Compaction needs plane scan/reduce ops; adapters without them
        // (some older wgpu targets) fall back to the naive skip.
        let plane_ok = client
            .properties()
            .features
            .plane
            .contains(cubecl::ir::features::Plane::Ops);
        let compact = cross && plane_ok;
        let plane_sync = client
            .properties()
            .features
            .plane
            .contains(cubecl::ir::features::Plane::Sync);
        // Plane-scoped queue: on by default where it is measured to win —
        // CubeCL's direct SPIR-V compiler on a real Vulkan device (+18-22%
        // on every niceonly scenario on an RX 9070 XT) and the native CUDA
        // runtime (+9-18% on an RTX 3090 once the device is the bottleneck,
        // neutral while the CPU MSD filter is). Off on Metal (b50+ loses),
        // off on software rasterizers (see `is_software_rasterizer`), and
        // opt-in on anything else. `NICE_CUBECL_PLANE_COMPACT=0|1`
        // overrides, except on software rasterizers where the variant
        // cannot run correctly.
        let name = R::name(client);
        let plane_default = name.contains("spirv") || name.contains("cuda");
        let plane_compact = compact
            && plane_sync
            && !software
            && match std::env::var("NICE_CUBECL_PLANE_COMPACT").ok().as_deref() {
                Some("0") => false,
                Some(_) => true,
                None => plane_default,
            };
        debug!(
            "CubeCL niceonly plan base {base}: cross {cross}, compact {compact} \
             (plane ops {plane_ok}), plane-scoped {plane_compact} (plane sync {plane_sync})"
        );
        #[allow(clippy::cast_possible_truncation)]
        let mask_words: Vec<u32> = if cross {
            table
                .low_digit_masks
                .iter()
                .flat_map(|&m| [m as u32, (m >> 32) as u32])
                .collect()
        } else {
            vec![0u32; 2]
        };
        let low_masks = client.create(cubecl::bytes::Bytes::from_elems(mask_words));
        let residues = client.create(cubecl::bytes::Bytes::from_elems(table.valid_residues));
        Ok(Self {
            stride_m,
            stride_r,
            residues,
            prefilter: vulkan_prefilter_params(base),
            low_masks,
            cross,
            compact,
            plane_compact,
        })
    }
}

/// The `CubeCL` end of the niceonly range pipeline: the base's cached plan
/// plus this field's output buffers, kept across every dispatch of a field.
struct CubeclNiceonlyRun<R: cubecl::prelude::Runtime> {
    client: cubecl::prelude::ComputeClient<R>,
    plan: Arc<NiceonlyPlan>,
    nice_out: cubecl::server::Handle,
    nice_count: cubecl::server::Handle,
    field_start: u128,
    /// `field_start mod M`, so the kernel only reduces the 64-bit offset.
    fs_mod_m: u32,
    base: u32,
    limbs: u32,
    chunk_digits: u32,
    chunk_div: u32,
    wide_chunk: bool,
    /// Report prefilter survivors instead of nice numbers (device tests only).
    probe: bool,
    /// Pin the lane tiling instead of sizing it per dispatch (device tests).
    lane_shift_override: Option<u32>,
    /// Force the compact specialization on or off (device tests).
    #[cfg(test)]
    compact_override: Option<bool>,
    /// Force the plane-scoped queue on or off (device tests).
    #[cfg(test)]
    plane_override: Option<bool>,
}

impl<R: cubecl::prelude::Runtime> CubeclNiceonlyRun<R> {
    /// Build a fresh, uncached plan and wrap a run around it (device tests).
    #[cfg(test)]
    fn new(
        client: &cubecl::prelude::ComputeClient<R>,
        base: u32,
        field_start: u128,
        wide_chunk: bool,
    ) -> Result<Self> {
        let plan = Arc::new(NiceonlyPlan::build(client, base, false)?);
        Self::from_plan(client, plan, base, field_start, wide_chunk)
    }

    /// Per-field setup over a cached plan: cheap — two buffer creations.
    ///
    /// # Errors
    /// Returns an error for a base with no u128 range.
    fn from_plan(
        client: &cubecl::prelude::ComputeClient<R>,
        plan: Arc<NiceonlyPlan>,
        base: u32,
        field_start: u128,
        wide_chunk: bool,
    ) -> Result<Self> {
        let limbs = n_limbs(base).with_context(|| format!("base {base} has no u128 range"))?;
        let (chunk_digits, chunk_div) = if wide_chunk {
            crate::gpu_config::chunk_constants(base)
        } else {
            chunk_constants_u16(base)
        };
        let nice_out = client.create(cubecl::bytes::Bytes::from_elems(vec![
            0u32;
            NICEONLY_OUT_CAPACITY
                * NICEONLY_STRIDE
                    as usize
        ]));
        let nice_count = client.create(cubecl::bytes::Bytes::from_elems(vec![0u32; 1]));

        #[allow(clippy::cast_possible_truncation)]
        let fs_mod_m = (field_start % u128::from(plan.stride_m)) as u32;
        Ok(Self {
            client: client.clone(),
            plan,
            nice_out,
            nice_count,
            field_start,
            fs_mod_m,
            base,
            limbs,
            chunk_digits,
            chunk_div,
            wide_chunk,
            probe: false,
            lane_shift_override: None,
            #[cfg(test)]
            compact_override: None,
            #[cfg(test)]
            plane_override: None,
        })
    }

    /// Collect the nice numbers found across the whole field (device tests).
    #[cfg(test)]
    fn finish(&self) -> Result<Vec<NiceNumberSimple>> {
        read_niceonly_hits(&self.client, &self.nice_count, &self.nice_out, self.base)
    }
}

/// Read a field's hits back. The blocking reads double as the device wait: a
/// dispatch still in flight has simply not written its hits yet, and the
/// failure mode is *silently missing solutions* — so the read path orders
/// after every launch on the client's queue.
///
/// # Errors
/// Returns an error if the kernel tried to write more hits than the buffer
/// holds — which, given how rare nice numbers are, means a kernel bug rather
/// than a genuine flood.
fn read_niceonly_hits<R: cubecl::prelude::Runtime>(
    client: &cubecl::prelude::ComputeClient<R>,
    nice_count: &cubecl::server::Handle,
    nice_out: &cubecl::server::Handle,
    base: u32,
) -> Result<Vec<NiceNumberSimple>> {
    let bytes = client
        .read_one(nice_count.clone())
        .map_err(|e| anyhow::anyhow!("nice count read failed: {e:?}"))?;
    let written = u32::from_bytes(&bytes)[0] as usize;
    ensure!(
        written <= NICEONLY_OUT_CAPACITY,
        "niceonly output buffer overflow: {written} > {NICEONLY_OUT_CAPACITY} \
         (this strongly suggests a kernel bug)"
    );
    let bytes = client
        .read_one(nice_out.clone())
        .map_err(|e| anyhow::anyhow!("nice out read failed: {e:?}"))?;
    let words = u32::from_bytes(&bytes);
    let mut hits: Vec<NiceNumberSimple> = (0..written)
        .map(|i| {
            let o = i * NICEONLY_STRIDE as usize;
            let lo = u128::from(words[o]) | (u128::from(words[o + 1]) << 32);
            let hi = u128::from(words[o + 2]) | (u128::from(words[o + 3]) << 32);
            NiceNumberSimple {
                number: (hi << 64) | lo,
                num_uniques: base,
            }
        })
        .collect();
    hits.sort_by_key(|n| n.number);
    Ok(hits)
}

/// Certificates as (lo, hi) u32 words, matching the offset encoding; a
/// 2-word dummy when the cross filter is off.
#[allow(clippy::cast_possible_truncation)]
fn certificate_words(masks: &[u64], cross: bool) -> Vec<u32> {
    if cross {
        masks
            .iter()
            .flat_map(|&m| [m as u32, (m >> 32) as u32])
            .collect()
    } else {
        vec![0u32; 2]
    }
}

impl<R: cubecl::prelude::Runtime> CubeclNiceonlyRun<R> {
    /// Whether this dispatch should use the compacted specialization. The
    /// no-MSD bypass ships all-zero certificates; the compacted kernel can
    /// only cost there (queue traffic and two barriers per iteration for a
    /// filter that never fires), so such dispatches take the plain path.
    /// Mixed batches keep compaction.
    fn dispatch_compact(&self, masks: &[u64]) -> bool {
        #[cfg(test)]
        if let Some(forced) = self.compact_override {
            return forced;
        }
        self.plan.compact && masks.iter().any(|&m| m != 0)
    }

    /// Whether a compacted dispatch uses the plane-scoped queue.
    fn dispatch_plane_scoped(&self, compact: bool) -> bool {
        #[cfg(test)]
        if let Some(forced) = self.plane_override {
            return compact && forced;
        }
        compact && self.plan.plane_compact
    }
}

/// A closed field's device work on a `CubeCL` runtime: the handles its hits
/// land in. Waited for on the client's thread; the blocking reads order after
/// every launch on the client's queue.
pub struct CubeclPendingField<R: cubecl::prelude::Runtime> {
    client: cubecl::prelude::ComputeClient<R>,
    nice_out: cubecl::server::Handle,
    nice_count: cubecl::server::Handle,
    base: u32,
}

impl<R: cubecl::prelude::Runtime> PendingField for CubeclPendingField<R> {
    fn wait(self: Box<Self>) -> Result<DeviceResult> {
        Ok(DeviceResult {
            nice_numbers: read_niceonly_hits(
                &self.client,
                &self.nice_count,
                &self.nice_out,
                self.base,
            )?,
            // No per-submission timing on this runtime without device
            // timestamp queries.
            device_busy_secs: None,
        })
    }
}

impl<R: cubecl::prelude::Runtime> RangeSink for CubeclNiceonlyRun<R> {
    type Pending = CubeclPendingField<R>;

    /// A run is one field; opening is what constructing it did.
    fn begin_field(&mut self, _seq: u64, _base: u32, _range: &FieldSize) -> Result<()> {
        Ok(())
    }

    fn end_field(&mut self, _seq: u64) -> Result<Self::Pending> {
        Ok(CubeclPendingField {
            client: self.client.clone(),
            nice_out: self.nice_out.clone(),
            nice_count: self.nice_count.clone(),
            base: self.base,
        })
    }

    fn launch(&mut self, _field: u64, offsets: &[u64], lens: &[u32], masks: &[u64]) -> Result<()> {
        ensure!(
            offsets.len() == lens.len() && offsets.len() == masks.len(),
            "range descriptor slices have mismatched lengths ({}/{}/{})",
            offsets.len(),
            lens.len(),
            masks.len()
        );
        // Pack offsets as lo/hi u32 pairs; buffers are created per dispatch
        // and sized to the batch (CubeCL pools the allocations). These
        // per-dispatch writes also flush the stream, so each dispatch is
        // submitted on its own — the same watchdog protection detailed mode
        // gets from its explicit `flush`. If these buffers are ever hoisted
        // or pooled to save the allocation, add that flush here.
        #[allow(clippy::cast_possible_truncation)]
        let pairs: Vec<u32> = offsets
            .iter()
            .flat_map(|&o| [o as u32, (o >> 32) as u32])
            .collect();
        let offsets_handle = self.client.create(cubecl::bytes::Bytes::from_elems(pairs));
        let lens_handle = self
            .client
            .create(cubecl::bytes::Bytes::from_elems(lens.to_vec()));
        let mask_words = certificate_words(masks, self.plan.cross);
        let masks_len = mask_words.len();
        let compact = self.dispatch_compact(masks);
        let masks_handle = self
            .client
            .create(cubecl::bytes::Bytes::from_elems(mask_words));

        // Tile the dispatch to this batch's ranges; batches are homogeneous
        // enough for the mean to be a good summary, because the MSD recursion
        // bounds range length by the floor.
        let mean_len = lens.iter().map(|&l| u64::from(l)).sum::<u64>() / lens.len().max(1) as u64;
        // NICE_CUBECL_LANES pins the tiling for A/B measurement.
        let lane_shift = self
            .lane_shift_override
            .or_else(|| {
                std::env::var("NICE_CUBECL_LANES")
                    .ok()?
                    .parse::<u32>()
                    .ok()
                    .filter(|n| n.is_power_of_two() && *n <= 32)
                    .map(u32::trailing_zeros)
            })
            .unwrap_or_else(|| {
                lane_shift_for(
                    offsets.len() as u64,
                    mean_len,
                    self.plan.stride_m,
                    self.plan.stride_r,
                )
            });
        let num_ranges = u32::try_from(offsets.len()).unwrap_or(u32::MAX);
        let threads = u64::from(num_ranges) << lane_shift;
        #[allow(clippy::cast_possible_truncation)]
        let cubes = threads
            .div_ceil(u64::from(WORKGROUP_SIZE))
            .clamp(1, u64::from(MAX_CUBES)) as u32;

        let (pre_limbs, pre_chunk_digits, pre_chunk_div) = self
            .plan
            .prefilter
            .map_or((0, 0, 0), |p| (p.limbs, p.chunk_digits, p.chunk_div));

        #[allow(clippy::cast_possible_truncation)]
        unsafe {
            niceonly_kernel::launch_unchecked::<R>(
                &self.client,
                CubeCount::Static(cubes, 1, 1),
                CubeDim::new_1d(WORKGROUP_SIZE),
                ArrayArg::from_raw_parts(self.plan.residues.clone(), self.plan.stride_r as usize),
                ArrayArg::from_raw_parts(offsets_handle, offsets.len() * 2),
                ArrayArg::from_raw_parts(lens_handle, lens.len()),
                ArrayArg::from_raw_parts(
                    self.nice_out.clone(),
                    NICEONLY_OUT_CAPACITY * NICEONLY_STRIDE as usize,
                ),
                ArrayArg::from_raw_parts(self.nice_count.clone(), 1),
                ArrayArg::from_raw_parts(
                    self.plan.low_masks.clone(),
                    if self.plan.cross {
                        2 * self.plan.stride_r as usize
                    } else {
                        2
                    },
                ),
                ArrayArg::from_raw_parts(masks_handle, masks_len),
                self.field_start as u32,
                (self.field_start >> 32) as u32,
                (self.field_start >> 64) as u32,
                (self.field_start >> 96) as u32,
                self.fs_mod_m,
                num_ranges,
                NICEONLY_OUT_CAPACITY as u32,
                lane_shift,
                self.base,
                self.limbs,
                self.chunk_digits,
                self.chunk_div,
                self.wide_chunk,
                self.plan.stride_m,
                self.plan.stride_r,
                stride_chunk_bits(self.plan.stride_m),
                pre_limbs,
                pre_chunk_digits,
                pre_chunk_div,
                self.probe,
                self.plan.cross,
                compact,
                self.dispatch_plane_scoped(compact),
            );
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::client_process::process_range_niceonly;
    use crate::gpu_route::process_niceonly;

    /// The GPU histogram bins are u32; a batch must not be able to overflow one.
    #[test]
    fn batch_size_cannot_overflow_a_u32_bin() {
        assert!(CUBECL_BATCH_SIZE < u128::from(u32::MAX));
    }

    /// The join runs where `CubeCL` reports plane operations, and on the
    /// software rasterizers that run them without saying so; anywhere else
    /// its fields keep the stride pipeline.
    #[test]
    fn the_join_needs_plane_operations() {
        assert!(joins_on(
            true,
            "NVIDIA GeForce RTX 3080 (Vulkan, wgpu<wgsl>)"
        ));
        assert!(joins_on(
            false,
            "llvmpipe (LLVM 19.1.7, 256 bits) (Vulkan, wgpu<spirv>)"
        ));
        assert!(!joins_on(
            false,
            "Microsoft Basic Render Driver (Dx12, wgpu<wgsl>)"
        ));
        assert!(!joins_on(
            false,
            "Intel(R) UHD Graphics 620 (Dx12, wgpu<wgsl>)"
        ));
    }

    /// CPU/CubeCL parity on the detailed path. Runs on lavapipe:
    ///
    /// ```text
    /// VK_ICD_FILENAMES=.../lvp_icd.json \
    ///   cargo test -p nice_common --features cubecl -- --ignored --nocapture
    /// ```
    #[test]
    #[ignore = "requires a wgpu device"]
    fn cubecl_matches_cpu_detailed() {
        let ctx = CubeclContext::new_default().expect("CubeCL init");
        for (base, count) in [
            (10u32, 1_000_000u128),
            (40, 2_000_000),
            (62, 200_000),
            (80, 100_000),
        ] {
            let start = crate::base_range::get_base_range_u128(base)
                .unwrap()
                .unwrap()
                .range_start;
            let range = FieldSize::new(start, start + count);
            let gpu = process_range_detailed_cubecl(&ctx, &range, base).expect("cubecl run");
            let cpu = process_range_detailed(&range, base);
            assert_eq!(
                gpu.distribution, cpu.distribution,
                "base {base}: distribution mismatch"
            );
            assert_eq!(
                gpu.nice_numbers, cpu.nice_numbers,
                "base {base}: near-miss mismatch"
            );
            println!("base {base}: {count} candidates match the CPU exactly");
        }
    }

    /// CPU/CubeCL parity through the native HIP runtime, on real AMD silicon.
    #[test]
    #[cfg(feature = "cubecl-hip")]
    #[ignore = "requires an AMD device with ROCm"]
    fn cubecl_hip_matches_cpu_detailed() {
        let ctx = CubeclContext::new_hip(0).expect("CubeCL HIP init");
        for (base, count) in [
            (10u32, 1_000_000u128),
            (40, 2_000_000),
            (62, 200_000),
            (80, 100_000),
        ] {
            let start = crate::base_range::get_base_range_u128(base)
                .unwrap()
                .unwrap()
                .range_start;
            let range = FieldSize::new(start, start + count);
            let gpu = process_range_detailed_cubecl(&ctx, &range, base).expect("cubecl-hip run");
            let cpu = process_range_detailed(&range, base);
            assert_eq!(
                gpu.distribution, cpu.distribution,
                "base {base}: distribution mismatch"
            );
            assert_eq!(
                gpu.nice_numbers, cpu.nice_numbers,
                "base {base}: near-miss mismatch"
            );
            println!("base {base}: {count} candidates match the CPU exactly (HIP runtime)");
        }
    }

    /// Niceonly parity through the native HIP runtime.
    #[test]
    #[cfg(feature = "cubecl-hip")]
    #[ignore = "requires an AMD device with ROCm"]
    fn cubecl_hip_matches_cpu_niceonly() {
        let ctx = CubeclContext::new_hip(0).expect("CubeCL HIP init");
        for base in [10u32, 12, 25, 40, 45, 62, 80] {
            let Ok(Some(base_range)) = crate::base_range::get_base_range_u128(base) else {
                continue;
            };
            let start = base_range.range_start;
            let end = (start + 5_000_000).min(base_range.range_end);
            let range = FieldSize::new(start, end);

            let table = StrideTable::new(base, GPU_LSD_K);
            let mut cpu = process_range_niceonly(&range, base, &table).nice_numbers;
            cpu.sort_by_key(|n| n.number);
            let gpu = process_niceonly(&ctx, &range, base).expect("cubecl-hip run");

            assert_eq!(cpu, gpu.nice_numbers, "base {base}: niceonly mismatch");
            println!(
                "base {base}: [{start}, {end}) agrees, {} nice (HIP runtime)",
                gpu.nice_numbers.len()
            );
        }
    }

    /// CPU/CubeCL parity through the native CUDA runtime, on real silicon.
    #[test]
    #[cfg(feature = "cubecl-cuda")]
    #[ignore = "requires an NVIDIA device"]
    fn cubecl_cuda_matches_cpu_detailed() {
        let ctx = CubeclContext::new_cuda(0).expect("CubeCL CUDA init");
        for (base, count) in [
            (10u32, 1_000_000u128),
            (40, 2_000_000),
            (62, 200_000),
            (80, 100_000),
        ] {
            let start = crate::base_range::get_base_range_u128(base)
                .unwrap()
                .unwrap()
                .range_start;
            let range = FieldSize::new(start, start + count);
            let gpu = process_range_detailed_cubecl(&ctx, &range, base).expect("cubecl-cuda run");
            let cpu = process_range_detailed(&range, base);
            assert_eq!(
                gpu.distribution, cpu.distribution,
                "base {base}: distribution mismatch"
            );
            assert_eq!(
                gpu.nice_numbers, cpu.nice_numbers,
                "base {base}: near-miss mismatch"
            );
            println!("base {base}: {count} candidates match the CPU exactly (CUDA runtime)");
        }
    }

    /// `process_range_detailed` over `threads` scoped threads, merged.
    #[cfg(feature = "cubecl-cuda")]
    fn cpu_detailed_parallel(range: &FieldSize, base: u32) -> FieldResults {
        let threads = std::thread::available_parallelism().map_or(8, |n| n.get()) as u128;
        let size = range.size();
        let step = size.div_ceil(threads).max(1);
        let parts: Vec<FieldResults> = std::thread::scope(|sc| {
            let hs: Vec<_> = (0..threads)
                .filter_map(|t| {
                    let a = range.start() + t * step;
                    let z = (a + step).min(range.end());
                    (a < z).then(|| sc.spawn(move || process_range_detailed(&FieldSize::new(a, z), base)))
                })
                .collect();
            hs.into_iter().map(|h| h.join().unwrap()).collect()
        });
        let mut distribution = parts[0].distribution.clone();
        let mut nice_numbers = Vec::new();
        for (k, p) in parts.iter().enumerate() {
            if k > 0 {
                for (acc, d) in distribution.iter_mut().zip(&p.distribution) {
                    acc.count += d.count;
                }
            }
            nice_numbers.extend(p.nice_numbers.iter().cloned());
        }
        nice_numbers.sort_by_key(|n| n.number);
        FieldResults {
            distribution,
            nice_numbers,
        }
    }

    /// The finite-difference kernel against the CPU at b40 and b50: the range
    /// start and end, seeded random windows, windows centred on every point
    /// inside the range where an addend (2n+1, 3n²+3n+1, 6n+6) gains a
    /// digit, and a window straddling the range start (n³ gains a digit
    /// there, so the batch splits between the two kernels). Several run
    /// lengths and batch sizes, so partial runs and batch edges are hit.
    /// Then the full range of every small base (the only windows with
    /// near-misses) and the benchmark GPU windows, whole.
    #[test]
    #[cfg(feature = "cubecl-cuda")]
    #[ignore = "requires an NVIDIA device"]
    #[allow(clippy::too_many_lines)]
    fn cubecl_cuda_fd_matches_cpu_detailed() {
        let ctx = CubeclContext::new_cuda(0).expect("CubeCL CUDA init");
        let v = |run_len: u32, batch: u128, static_mask: bool, merged: bool, hist_local: bool, table: bool| FdOptions {
            enabled: true,
            run_len,
            batch,
            static_mask,
            merged,
            hist_local,
            table,
        };
        let opts = [
            v(128, CUBECL_BATCH_SIZE, true, true, false, true),
            v(128, CUBECL_BATCH_SIZE, true, true, false, false),
            v(256, CUBECL_BATCH_SIZE, true, false, false, false),
            v(256, CUBECL_BATCH_SIZE, false, false, false, false),
            v(61, CUBECL_BATCH_SIZE, true, true, true, true),
            v(1000, 333_333, true, false, true, false),
            v(1000, 333_333, true, true, false, true),
        ];
        let check = |range: &FieldSize, base: u32, cpu: &FieldResults, what: &str| {
            for o in &opts {
                let gpu = cubecl::future::block_on(process_range_detailed_cubecl_with(
                    &ctx, range, base, *o,
                ))
                .expect("cubecl-cuda fd run");
                assert_eq!(gpu.distribution, cpu.distribution, "b{base} {what} {o:?}: distribution");
                assert_eq!(gpu.nice_numbers, cpu.nice_numbers, "b{base} {what} {o:?}: near-misses");
            }
        };
        for base in [40u32, 50] {
            let plan = fd_plan(base).expect("fd plan");
            let r = crate::base_range::get_base_range_u128(base).unwrap().unwrap();
            let (rs, re) = (r.range_start, r.range_end);
            assert_eq!((plan.reg_lo, plan.reg_hi), (rs, re), "b{base}: regular interval");
            println!("b{base}: {plan:?}");
            let w = 1_000_000u128;
            let mut windows: Vec<(u128, u128, String)> = vec![
                (rs, rs + 2 * w, "range start".into()),
                (re - 2 * w, re, "range end".into()),
                (rs - w, rs + w, "straddles range start".into()),
            ];
            let mut x = 0x9E37_79B9_7F4A_7C15u64 ^ u64::from(base);
            for i in 0..8 {
                x = x.wrapping_add(0x9E37_79B9_7F4A_7C15);
                let mut z = x;
                z = (z ^ (z >> 30)).wrapping_mul(0xBF58_476D_1CE4_E5B9);
                z = (z ^ (z >> 27)).wrapping_mul(0x94D0_49BB_1331_11EB);
                z ^= z >> 31;
                let off = (u128::from(z) * (re - rs - w)) >> 64;
                windows.push((rs + off, rs + off + w, format!("random {i}")));
            }
            let b = u128::from(base);
            for k in 1..=30u32 {
                let Some(bk) = b.checked_pow(k) else { break };
                let g_ds = bk.saturating_sub(1).div_ceil(2);
                let g_ddc = bk.saturating_sub(6).div_ceil(6);
                // smallest n with 3n²+3n+1 >= b^k
                let (mut lo, mut hi) = (0u128, 1u128 << 64);
                while lo < hi {
                    let m = (lo + hi) / 2;
                    let v = m.checked_mul(m).and_then(|q| q.checked_mul(3)).and_then(|q| q.checked_add(3 * m + 1));
                    if v.is_none_or(|v| v >= bk) { hi = m } else { lo = m + 1 }
                }
                for (name, g) in [("dS", g_ds), ("ddC", g_ddc), ("dC", lo)] {
                    if g > rs + w && g + w < re {
                        windows.push((g - w / 2, g + w / 2, format!("{name} gains digit {k} at {g}")));
                    }
                }
            }
            for (a, z, what) in &windows {
                let range = FieldSize::new(*a, *z);
                let cpu = cpu_detailed_parallel(&range, base);
                check(&range, base, &cpu, what);
                println!("b{base} {what}: [{a}, {z}) exact for {} option sets", opts.len());
            }
            // The benchmark GPU window, whole, at the default options.
            let range = FieldSize::new(rs, rs + 200_000_000);
            let cpu = cpu_detailed_parallel(&range, base);
            let gpu = cubecl::future::block_on(process_range_detailed_cubecl_with(
                &ctx, &range, base, FdOptions::with_run(256),
            ))
            .expect("fd run");
            assert_eq!(gpu.distribution, cpu.distribution, "b{base} benchmark window");
            assert_eq!(gpu.nice_numbers, cpu.nice_numbers, "b{base} benchmark window");
            let old = cubecl::future::block_on(process_range_detailed_cubecl_with(
                &ctx, &range, base, FdOptions { enabled: false, ..FdOptions::with_run(256) },
            ))
            .expect("old run");
            assert_eq!(old.distribution, cpu.distribution, "b{base} benchmark window (old kernel)");
            println!(
                "b{base} benchmark window [{rs}, +2e8): fd = old = cpu, {} near-misses",
                cpu.nice_numbers.len()
            );
        }
        // Small bases, full range: the near-miss list is non-empty here.
        let mut misses = 0;
        for base in 10u32..=30 {
            let Some(plan) = fd_plan(base) else { continue };
            let r = crate::base_range::get_base_range_u128(base).unwrap().unwrap();
            if r.size() > 50_000_000 {
                continue;
            }
            let cpu = cpu_detailed_parallel(&r, base);
            check(&r, base, &cpu, "full range");
            misses += cpu.nice_numbers.len();
            println!("b{base} full range ({} numbers, {plan:?}): exact, {} near-misses", r.size(), cpu.nice_numbers.len());
        }
        assert!(misses > 0, "no near-misses exercised");
    }

    /// Interleaved timing of the per-number kernel against the
    /// finite-difference kernel over a sweep of run lengths, on the
    /// benchmark GPU window (each base's range start, 2e8 numbers).
    /// Knobs: `FD_TIMING_BASES` (default "40,50"), `FD_TIMING_RUNS`
    /// (default "64,128,256,512,1024"), `FD_TIMING_REPS` windows per cell
    /// (default 10), `FD_TIMING_ROUNDS` (default 3), `FD_TIMING_BATCH`
    /// (default `CUBECL_BATCH_SIZE`), `FD_TIMING_WINDOW` (default 2e8).
    #[test]
    #[cfg(feature = "cubecl-cuda")]
    #[ignore = "timing; requires an NVIDIA device"]
    fn fd_timing() {
        let env_list = |k: &str, d: &str| -> Vec<u128> {
            std::env::var(k)
                .unwrap_or_else(|_| d.to_string())
                .split(',')
                .filter(|x| !x.is_empty())
                .map(|x| x.trim().parse().unwrap())
                .collect()
        };
        let bases = env_list("FD_TIMING_BASES", "40,50");
        let runs = env_list("FD_TIMING_RUNS", "64,128,256,512,1024");
        let reps = env_list("FD_TIMING_REPS", "10")[0];
        let rounds = env_list("FD_TIMING_ROUNDS", "3")[0];
        let batch = env_list("FD_TIMING_BATCH", &CUBECL_BATCH_SIZE.to_string())[0];
        let window = env_list("FD_TIMING_WINDOW", "200000000")[0];
        let ctx = CubeclContext::new_cuda(0).expect("CubeCL CUDA init");
        for &base in &bases {
            let base = base as u32;
            let rs = crate::base_range::get_base_range_u128(base).unwrap().unwrap().range_start;
            let range = FieldSize::new(rs, rs + window);
            let variants = std::env::var("FD_TIMING_VARIANTS").unwrap_or_else(|_| "s".into());
            let mut arms: Vec<(String, FdOptions)> = vec![(
                "old".into(),
                FdOptions { enabled: false, ..FdOptions::with_run(1) },
            )];
            for var in variants.split(',') {
                // p = plain (v1), s = static mask (v2), m = static + merged
                // rare branch (v3), t = v3 + low-digit table (v4),
                // h = v3 + local histogram, q = v2 + local histogram
                let (sm, mg, hl, tb) = match var {
                    "p" => (false, false, false, false),
                    "s" => (true, false, false, false),
                    "h" => (true, true, true, false),
                    "q" => (true, false, true, false),
                    "t" => (true, true, false, true),
                    _ => (true, true, false, false),
                };
                for &r in &runs {
                    arms.push((
                        format!("fd{var} R={r}"),
                        FdOptions { run_len: r as u32, batch, static_mask: sm, merged: mg, hist_local: hl, table: tb, ..FdOptions::with_run(1) },
                    ));
                }
            }
            // Warm up (JIT) and cross-check every arm once.
            let reference = cubecl::future::block_on(process_range_detailed_cubecl_with(&ctx, &range, base, arms[0].1)).unwrap();
            for (name, o) in &arms {
                let r = cubecl::future::block_on(process_range_detailed_cubecl_with(&ctx, &range, base, *o)).unwrap();
                assert_eq!(r.distribution, reference.distribution, "b{base} {name}");
                assert_eq!(r.nice_numbers, reference.nice_numbers, "b{base} {name}");
            }
            let mut rates: Vec<Vec<f64>> = vec![Vec::new(); arms.len()];
            for _ in 0..rounds {
                for (k, (_, o)) in arms.iter().enumerate() {
                    let t = Instant::now();
                    for _ in 0..reps {
                        let r = cubecl::future::block_on(process_range_detailed_cubecl_with(&ctx, &range, base, *o)).unwrap();
                        assert_eq!(r.distribution, reference.distribution);
                    }
                    #[allow(clippy::cast_precision_loss)]
                    rates[k].push((window * reps) as f64 / t.elapsed().as_secs_f64());
                }
            }
            let med = |v: &Vec<f64>| {
                let mut v = v.clone();
                v.sort_by(f64::total_cmp);
                v[v.len() / 2]
            };
            let old = med(&rates[0]);
            for (k, (name, _)) in arms.iter().enumerate() {
                let rs: Vec<String> = rates[k].iter().map(|r| format!("{r:.3e}")).collect();
                println!(
                    "FDTIME b{base} batch {batch} {name:>10}: rounds [{}] median {:.3e} n/s  x{:.2}",
                    rs.join(" "),
                    med(&rates[k]),
                    med(&rates[k]) / old
                );
            }
        }
    }

    /// The placeholder is only ever reached when the driver cannot answer.
    /// Runs everywhere: an out-of-range ordinal fails before any driver call,
    /// so this pins the fallback contract without needing NVIDIA silicon.
    #[test]
    #[cfg(feature = "cubecl-cuda")]
    fn cuda_device_name_falls_back_when_the_driver_cannot_answer() {
        assert_eq!(
            cuda_device_name(usize::MAX),
            format!("cubecl-cuda device {}", usize::MAX),
        );
    }

    /// On real silicon the reported model must be the driver's name, not the
    /// placeholder — a placeholder is what made every v3.4.3 detailed report
    /// unmatchable for the estimator. Asserting "not the placeholder" rather
    /// than a specific string keeps this runnable on any NVIDIA card.
    #[test]
    #[cfg(feature = "cubecl-cuda")]
    #[ignore = "requires an NVIDIA device"]
    fn cubecl_cuda_reports_the_real_device_name() {
        let name = cuda_device_name(0);
        assert_ne!(
            name, "cubecl-cuda device 0",
            "driver did not name the device; reports would be unattributable"
        );
        assert!(!name.trim().is_empty(), "empty device name");
        // The context must carry the same string the helper resolved, since
        // that is what reaches `hardware.gpu_model`.
        let ctx = CubeclContext::new_cuda(0).expect("CubeCL CUDA init");
        assert_eq!(ctx.device_name(), name);
        assert_eq!(ctx.backend_name(), "cubecl-cuda");
        println!("cubecl-cuda device 0 reports as {name:?}");
    }

    /// The known solution: 69 is nice in base 10.
    #[test]
    #[ignore = "requires a wgpu device"]
    fn cubecl_finds_69_in_base_10() {
        let ctx = CubeclContext::new_default().expect("CubeCL init");
        let range = FieldSize::new(47, 100);
        let results = process_range_detailed_cubecl(&ctx, &range, 10).expect("cubecl run");
        let hit = results
            .nice_numbers
            .iter()
            .find(|n| n.number == 69)
            .expect("69 not found in base 10");
        assert_eq!(hit.num_uniques, 10);
    }

    /// CPU/CubeCL parity on the niceonly path, over the same range with the
    /// same stride table. The GPU checks a *superset* of the CPU's
    /// candidates (its MSD floor is coarser), so the nice-number sets must
    /// still be identical.
    /// Throughput of the continuous pipeline on a fixed run of fields on
    /// the default wgpu device, so two configurations can be compared on
    /// identical work. Fields are queued `FIELDS_IN_FLIGHT` deep as in
    /// production, and `NICE_GPU_MSD_FLOOR` applies as there;
    /// `NICE_TEST_FIELDS` (required: it is also the opt-in, since the parity
    /// workflow runs this module's ignored tests on lavapipe) fields of 1e13
    /// in base 54 from the Anvil region.
    #[test]
    #[ignore = "requires a wgpu device; prints throughput"]
    #[allow(clippy::cast_precision_loss)]
    fn pipeline_throughput_fixed_fields() {
        use crate::gpu_niceonly::{FIELDS_IN_FLIGHT, msd_floor_in_use};
        use crate::gpu_route::{NiceonlyStarted, begin_niceonly};
        // The parity workflow runs every ignored test in this module on a
        // software rasterizer; a throughput run there is hours of nothing.
        // Only run when asked for by name.
        let Ok(n) = std::env::var("NICE_TEST_FIELDS") else {
            eprintln!("skipping: set NICE_TEST_FIELDS to run the throughput harness");
            return;
        };
        let ctx = CubeclContext::new_default().expect("CubeCL init");
        let base = 54;
        let n: usize = n.parse().expect("NICE_TEST_FIELDS must be a count");
        let start: u128 = 2_778_136_280_153_679_229;
        let size: u128 = 10_000_000_000_000;
        let fields: Vec<FieldSize> = (0..n as u128)
            .map(|i| FieldSize::new(start + i * size, start + (i + 1) * size))
            .collect();
        let warm = FieldSize::new(start - size, start);
        if let NiceonlyStarted::Queued(ticket) = begin_niceonly(&ctx, &warm, base).unwrap() {
            ctx.finish(ticket).unwrap();
        }
        let lookahead = FIELDS_IN_FLIGHT.saturating_sub(1);
        let t = std::time::Instant::now();
        let mut queued = std::collections::VecDeque::new();
        let mut found = 0usize;
        for f in &fields {
            if let NiceonlyStarted::Queued(ticket) = begin_niceonly(&ctx, f, base).unwrap() {
                queued.push_back(ticket);
            }
            while queued.len() > lookahead {
                let ticket = queued.pop_front().unwrap();
                found += ctx.finish(ticket).unwrap().0.nice_numbers.len();
            }
        }
        for ticket in queued {
            found += ctx.finish(ticket).unwrap().0.nice_numbers.len();
        }
        let secs = t.elapsed().as_secs_f64();
        eprintln!(
            "THROUGHPUT fields_in_flight={} floor_now={} fields={n} secs={secs:.2} rate={:.3e} n/s found={found}",
            FIELDS_IN_FLIGHT,
            msd_floor_in_use(),
            (n as f64) * (size as f64) / secs
        );
    }

    #[test]
    #[ignore = "requires a wgpu device"]
    fn cubecl_matches_cpu_niceonly() {
        let ctx = CubeclContext::new_default().expect("CubeCL init");
        for base in [10u32, 12, 25, 40, 45, 62, 80] {
            let Ok(Some(base_range)) = crate::base_range::get_base_range_u128(base) else {
                continue;
            };
            let start = base_range.range_start;
            let end = (start + 5_000_000).min(base_range.range_end);
            let range = FieldSize::new(start, end);

            let table = StrideTable::new(base, GPU_LSD_K);
            let mut cpu = process_range_niceonly(&range, base, &table).nice_numbers;
            cpu.sort_by_key(|n| n.number);
            let gpu = process_niceonly(&ctx, &range, base).expect("cubecl run");

            assert_eq!(cpu, gpu.nice_numbers, "base {base}: niceonly mismatch");
            assert!(
                gpu.distribution.is_empty(),
                "base {base}: niceonly must report no distribution"
            );
            println!(
                "base {base}: [{start}, {end}) agrees, {} nice",
                gpu.nice_numbers.len()
            );
        }
    }

    /// The known solution, through the niceonly path: the whole pipeline (MSD
    /// filter, descriptors, on-device residue reconstruction, prefilter) has
    /// to line up for 69 to come back.
    #[test]
    #[ignore = "requires a wgpu device"]
    fn cubecl_niceonly_finds_69_in_base_10() {
        let ctx = CubeclContext::new_default().expect("CubeCL init");
        let base_range = crate::base_range::get_base_range_u128(10).unwrap().unwrap();
        let range = FieldSize::new(base_range.range_start, base_range.range_end);
        let results = process_niceonly(&ctx, &range, 10).expect("cubecl run");
        assert_eq!(
            results
                .nice_numbers
                .iter()
                .map(|n| n.number)
                .collect::<Vec<_>>(),
            vec![69]
        );
    }

    /// The prefilter's own output, checked against an independent host mirror.
    ///
    /// Nice numbers are astronomically rare, so an over-rejecting prefilter
    /// would agree with the CPU on every range the parity test can afford —
    /// rejecting everything is not a hypothetical, it is the bug the CUDA
    /// path shipped in v3.2.14. The probe build reports every candidate the
    /// prefilter *passes*, at every lane width, and the mirror here computes
    /// the expected survivors by the definition (`x^k mod d^p` in u128) rather
    /// than by the kernel's chunk arithmetic, so the two cannot share a bug.
    /// Do the lowest `digits` base-`base` digits of n² and n³, computed
    /// mod `chunk_div^limbs`, contain no duplicate? Host mirror of the
    /// kernel's low-digit prefilter, shared by the probe tests.
    fn prefilter_mirror(n: u128, base: u32, pre: &VulkanPrefilterParams) -> bool {
        let modulus = u128::from(pre.chunk_div).pow(pre.limbs);
        let m = n % modulus;
        let sq = (m * m) % modulus;
        let cu = (sq * m) % modulus;
        let mut seen = 0u128;
        let mut dup = false;
        for mut v in [sq, cu] {
            for _ in 0..pre.digits {
                let d = (v % u128::from(base)) as u32;
                v /= u128::from(base);
                let bit = 1u128 << d;
                dup |= seen & bit != 0;
                seen |= bit;
            }
        }
        !dup
    }

    /// The cross-end filter's device semantics against a host mirror, with
    /// certificates that actually fire: word packing of both the low-mask
    /// table and the range certificates, residue-to-mask indexing, and the
    /// nonzero-intersection skip — in both the compacted and plain
    /// specializations. Probe mode reports the exact survivor set, so an
    /// over-rejection (the failure ordinary parity misses when a range holds
    /// no nice number) shows up as a missing survivor here.
    #[test]
    #[ignore = "requires a wgpu device"]
    fn cubecl_cross_filter_survivors_match_the_host_mirror() {
        let ctx = CubeclContext::new_default().expect("CubeCL init");
        #[allow(irrefutable_let_patterns)]
        let CubeclContext::Wgpu { client, .. } = &ctx else {
            unreachable!("new_default returns the wgpu variant");
        };
        // b40: prefilter base, digits reach 39 (bits in both mask words).
        // b50: no prefilter, so probe reports pure cross-filter survivors;
        // digits reach 49.
        for (base, mask) in [
            (40u32, (1u64 << 5) | (1u64 << 39)),
            (50, (1u64 << 3) | (1u64 << 45)),
        ] {
            let pre = vulkan_prefilter_params(base);
            let table = StrideTable::new(base, GPU_LSD_K);
            let start = crate::base_range::get_base_range_u128(base)
                .unwrap()
                .unwrap()
                .range_start;
            // Small enough that even the no-prefilter base's probe survivors
            // fit the output buffer with wide margin (probe reports every
            // survivor, not just nice numbers).
            let len: u32 = 400_000;

            // Host mirror: every stride candidate whose residue's exact low
            // digits miss the certificate and (where present) whose low
            // digits pass the prefilter.
            let end = start + u128::from(len);
            let (mut n, mut idx) = table.first_valid_at_or_after(start);
            let mut want = Vec::new();
            let mut cross_rejected = 0u32;
            while n < end {
                if table.low_digit_masks[idx] & mask != 0 {
                    cross_rejected += 1;
                } else if pre.is_none_or(|p| prefilter_mirror(n, base, &p)) {
                    want.push(n);
                }
                n += u128::from(table.gap_table[idx]);
                idx = (idx + 1) % table.gap_table.len();
            }
            assert!(
                cross_rejected > 1000,
                "base {base}: certificate {mask:#x} rejected too little to test"
            );
            assert!(
                want.len() < NICEONLY_OUT_CAPACITY / 2,
                "base {base}: {} probe survivors would risk the output buffer; shrink the window",
                want.len()
            );

            // The plane-scoped queue needs a real subgroup barrier: llvmpipe
            // mishandles OpControlBarrier at subgroup scope inside
            // plane-divergent control flow (2 of 283 survivors; exact with
            // the barriers removed), so it is only covered on hardware.
            let plane_sync = client
                .properties()
                .features
                .plane
                .contains(cubecl::ir::features::Plane::Sync)
                && !is_software_rasterizer(&ctx.device_name());
            let variants: &[(bool, bool)] = if plane_sync {
                &[(true, false), (true, true), (false, false)]
            } else {
                &[(true, false), (false, false)]
            };
            for &(forced_compact, forced_plane) in variants {
                let mut run =
                    CubeclNiceonlyRun::new(client, base, start, false).expect("probe run");
                run.probe = true;
                run.compact_override = Some(forced_compact);
                run.plane_override = Some(forced_plane);
                run.launch(0, &[0], &[len], &[mask]).expect("dispatch");
                let mut got: Vec<u128> = run
                    .finish()
                    .expect("results")
                    .iter()
                    .map(|n| n.number)
                    .collect();
                got.sort_unstable();
                assert_eq!(
                    got, want,
                    "base {base} compact={forced_compact} plane={forced_plane}: \
                     cross-filtered survivor set mismatch"
                );
            }
        }
    }

    #[test]
    #[ignore = "requires a wgpu device"]
    fn cubecl_prefilter_survivors_match_the_host_mirror() {
        use crate::gpu_niceonly::MAX_LANES_PER_RANGE;

        let ctx = CubeclContext::new_default().expect("CubeCL init");
        #[allow(irrefutable_let_patterns)]
        let CubeclContext::Wgpu { client, .. } = &ctx else {
            unreachable!("new_default returns the wgpu variant");
        };
        // Base 40 is the live prefilter base; 30 and 34 exercise the same
        // kernel at other chunk/limb constants.
        for base in [30u32, 34, 40] {
            let pre = vulkan_prefilter_params(base).expect("base has a prefilter");
            let table = StrideTable::new(base, GPU_LSD_K);
            let start = crate::base_range::get_base_range_u128(base)
                .unwrap()
                .unwrap()
                .range_start;
            let len: u32 = 5_000_000;

            // Every lane width, over the identical range: the tiling is pure
            // index arithmetic, so a width the host never happens to choose is
            // exactly where an off-by-one would hide.
            let mut per_width = Vec::new();
            for shift in 0..=MAX_LANES_PER_RANGE.ilog2() {
                let mut run =
                    CubeclNiceonlyRun::new(client, base, start, false).expect("probe run");
                assert!(
                    run.plan.prefilter.is_some(),
                    "base {base}: no prefilter params"
                );
                run.probe = true;
                run.lane_shift_override = Some(shift);
                run.launch(0, &[0], &[len], &[0]).expect("dispatch");
                per_width.push(
                    run.finish()
                        .expect("results")
                        .iter()
                        .map(|n| n.number)
                        .collect::<Vec<u128>>(),
                );
            }
            // Every stride candidate in the range, filtered by the mirror.
            let end = start + u128::from(len);
            let (mut n, mut idx) = table.first_valid_at_or_after(start);
            let mut want = Vec::new();
            let mut candidates = 0u32;
            while n < end {
                candidates += 1;
                if prefilter_mirror(n, base, &pre) {
                    want.push(n);
                }
                n += u128::from(table.gap_table[idx]);
                idx = (idx + 1) % table.gap_table.len();
            }

            // Each lane width against the CPU mirror, not merely against
            // each other: if the tiling drops or duplicates candidates at one
            // width, comparing widths only says they disagree, while this says
            // which one is wrong.
            for (shift, got) in per_width.iter().enumerate() {
                assert_eq!(
                    got,
                    &want,
                    "base {base}: {} lanes disagree with the CPU mirror \
                     ({} survivors vs {})",
                    1 << shift,
                    got.len(),
                    want.len()
                );
            }
            assert!(!want.is_empty(), "base {base}: the mirror passed nothing");
            assert!(
                want.len() < candidates as usize,
                "base {base}: the prefilter rejected nothing"
            );
            #[allow(clippy::cast_precision_loss)]
            {
                println!(
                    "base {base}: {} of {candidates} candidates survive ({:.2}%), device agrees",
                    want.len(),
                    100.0 * want.len() as f64 / f64::from(candidates)
                );
            }
        }
    }

    /// Many batches in one field must not lose the device. Without the
    /// per-batch flush in `detailed_impl`, `CubeCL` packs persistent
    /// grid-stride dispatches into one submission until it reaches
    /// `CUBECL_WGPU_MAX_TASKS` (32), and the driver's watchdog resets the GPU
    /// long before that — ~2 s on Linux/RADV, the same 2 s TDR on Windows.
    ///
    /// 40 batches is deliberately over that cap so the test also covers the
    /// aggregated path, but it is not the interesting size: a real field is
    /// `DETAILED_SEARCH_MAX_FIELD_SIZE` = 20 batches, under the cap and still
    /// over the watchdog at every base past ~46.
    ///
    /// Skipped on software rasterizers: CI runs the ignored tests on lavapipe,
    /// where 2e9 candidates would take hours and no watchdog is involved.
    #[test]
    #[ignore = "requires a wgpu device"]
    fn cubecl_detailed_survives_more_batches_than_the_task_cap() {
        let ctx = CubeclContext::new_default().expect("CubeCL init");
        let device = ctx.device_name();
        if is_software_rasterizer(&device) {
            println!("skipping on software rasterizer: {device}");
            return;
        }

        let base = 40u32;
        let batches = 40u128;
        let count = batches * CUBECL_BATCH_SIZE;
        let start = crate::base_range::get_base_range_u128(base)
            .unwrap()
            .unwrap()
            .range_start;
        let range = FieldSize::new(start, start + count);
        let results = process_range_detailed_cubecl(&ctx, &range, base).expect("cubecl run");

        // Non-vacuous: every candidate lands in exactly one bin, so the
        // histogram must account for the whole field. A submission the driver
        // killed would take its batch's counts with it.
        let counted: u128 = results.distribution.iter().map(|d| d.count).sum();
        assert_eq!(
            counted, count,
            "{batches} batches on {device}: histogram covers {counted} of {count} candidates"
        );
        println!("{batches} batches ({count} candidates) survived on {device}");
    }

    /// CPU/CubeCL niceonly parity through the native CUDA runtime, on real
    /// silicon — the wide-chunk digit scan's only niceonly exercise.
    #[test]
    #[cfg(feature = "cubecl-cuda")]
    #[ignore = "requires an NVIDIA device"]
    fn cubecl_cuda_matches_cpu_niceonly() {
        let ctx = CubeclContext::new_cuda(0).expect("CubeCL CUDA init");
        for base in [10u32, 12, 25, 40, 45, 62, 80] {
            let Ok(Some(base_range)) = crate::base_range::get_base_range_u128(base) else {
                continue;
            };
            let start = base_range.range_start;
            let end = (start + 5_000_000).min(base_range.range_end);
            let range = FieldSize::new(start, end);

            let table = StrideTable::new(base, GPU_LSD_K);
            let mut cpu = process_range_niceonly(&range, base, &table).nice_numbers;
            cpu.sort_by_key(|n| n.number);
            let gpu = process_niceonly(&ctx, &range, base).expect("cubecl-cuda run");

            assert_eq!(cpu, gpu.nice_numbers, "base {base}: niceonly mismatch");
            println!(
                "base {base}: [{start}, {end}) agrees, {} nice (CUDA runtime)",
                gpu.nice_numbers.len()
            );
        }
    }
}
