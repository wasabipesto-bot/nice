//! Finite-difference detailed kernel for `CubeCL`: the unique-digit histogram
//! without a division per number.
//!
//! [`crate::cubecl_backend`]'s per-number kernel squares and cubes every n and
//! divides both results down to digits. Over a run of consecutive n the
//! division is unnecessary: with dS = 2n+1, dC = 3n²+3n+1 and ddC = 6n+6,
//! stepping n to n+1 is S += dS, dS += 2, C += dC, dC += ddC, ddC += 6. Here
//! each thread takes a run of [`FD_RUN_LEN`] consecutive n, seeds the five
//! values once from the run's first n (the same limb products and
//! division-by-constant chunk split as the per-number kernel), and keeps them
//! as base-b digit arrays in registers, four digits to a u32 (one byte lane
//! each, little-endian). Each step is five digit-array additions, each four
//! digits per native add: adding 256 - b to every byte of the addend makes a
//! lane overflow into the next exactly when its digit sum reaches b, and the
//! lanes that did not overflow give the bias back (`fd_add_top`). Words of
//! S and C above the addend's width change only when a carry ripples through
//! four digits of b-1, so their part of the digit mask is cached per run and
//! one rare branch per step does every such ripple and the cache refresh. The
//! mask build, histogram and near-miss records are the per-number kernel's.
//!
//! Exactness: the seed is exact integer arithmetic, and every step is an exact
//! base-b addition, so after k steps the arrays hold exactly (n+k)², (n+k)³ and
//! the three differences. The biased add needs every lane below b (b ≤ 128),
//! which its own output keeps true. The kernel is specialised to digit
//! lengths: n² has exactly `ls` digits and n³ exactly `lc` for every n in a
//! base's legal range (their digit counts sum to the base and neither can
//! fall, so neither can rise), so the mask covers comptime positions and
//! leading zeros never enter it; [`fd_plan`] computes that interval exactly,
//! and the host sends any part of a batch outside it to the per-number kernel.
//! The addends' widths are taken at the interval's top, where they are
//! largest, so no addend can outgrow its array.
//!
//! Portability: the kernel needs what the per-number kernel needs (u64 add,
//! multiply and shift; a u64 division only in the CUDA and HIP seed, the
//! split16 division on wgpu). It is exact on CUDA and on Vulkan (lavapipe,
//! through naga's WGSL and through `CubeCL`'s SPIR-V compiler), but not on
//! Metal: on an Apple M4 it returned wrong unique counts for most numbers at
//! bases 23, 27-30, 49, 50 and 52-55, even at one number per run, so the
//! fault lies in the seed, the digit packing or the mask build. The root
//! cause is open, so production keeps the per-number kernel on Metal
//! adapters (`DetailedKernel::for_device` in [`crate::cubecl_backend`]), and
//! `cubecl_fd_matches_cpu_detailed` below, which runs this kernel on any
//! wgpu device, is the test that shows it.

#![cfg(feature = "cubecl")]
// The cube macro evaluates comptime! expressions host-side, where fn-level
// allows do not reach; these lints are all macro-expansion artifacts.
#![allow(
    clippy::cast_possible_truncation,
    clippy::cast_possible_wrap,
    clippy::cast_lossless,
    clippy::used_underscore_binding
)]

use crate::cubecl_backend::{HIST_COPIES, MISS_STRIDE};
use crate::gpu_config::gpu_supports_base;
use cubecl::prelude::*;
use malachite::base::num::arithmetic::traits::{CeilingRoot, DivAssignRem, Pow};
use malachite::natural::Natural;

/// Consecutive candidates per thread. The seed costs about 5 % of a run's
/// work at 128; measured on an RTX 3080, throughput is flat (within 3 %) from
/// 64 to 512 and drops below 64 (the seed) and at 2048 (too few threads to
/// fill the device at one batch per dispatch).
pub const FD_RUN_LEN: u32 = 128;

/// Highest base the kernel serves: the digit mask is one u64. (The biased add
/// itself holds to base 128.)
pub const FD_MAX_BASE: u32 = 64;

/// Bit 31 of a word's raw biased sum is clear exactly when its top lane
/// carried out of the word.
const NO_CARRY: u32 = 0x8000_0000;

/// Biased add `x += y` over words `0..wy`, then the carry alone into words
/// `wy..kd`. Nothing is added above `kd`: returns the last word's raw sum,
/// whose bit 31 is clear exactly when it carried out, for the caller's rare
/// ripple.
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
        // A lane that carried out holds its digit sum minus b, below b, so
        // bit 7 is clear; one that did not holds at least 256 - b, bit 7 set.
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

/// Add a carry of 1 into word `from` and ripple it up to word `wx - 1`.
#[cube]
fn fd_ripple(
    x: &mut Array<u32>,
    #[comptime] from: u32,
    #[comptime] wx: u32,
    #[comptime] base: u32,
) {
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

/// Convert the little-endian u32 limbs `v` (destroyed) into `ndig` packed
/// base-b digits in `out` (pre-zeroed), `chunk_digits` digits per long
/// division by `chunk_div` = b^`chunk_digits`. The two flavors are the
/// per-number kernel's: `wide_chunk` divides limb pairs in u64 (a
/// multiply-high under nvcc and hipcc); split16 divides 16-bit halves in u32,
/// with `chunk_div` below 2^16, for targets without a fast u64 division.
#[cube]
#[allow(clippy::too_many_arguments)]
fn fd_to_digits(
    v: &mut Array<u32>,
    out: &mut Array<u32>,
    #[comptime] nlimbs: u32,
    #[comptime] ndig: u32,
    #[comptime] base: u32,
    #[comptime] chunk_digits: u32,
    #[comptime] chunk_div: u32,
    #[comptime] wide_chunk: bool,
) {
    let nchunks = comptime!(ndig.div_ceil(chunk_digits));
    #[unroll]
    for k in 0..nchunks {
        let mut chunk = if wide_chunk {
            let mut rem64 = 0u64;
            #[unroll]
            for ii in 0..nlimbs {
                let i = comptime!(nlimbs - 1 - ii);
                let cur = (rem64 << 32u64) | u64::cast_from(v[i as usize]);
                let q = cur / u64::cast_from(chunk_div);
                v[i as usize] = u32::cast_from(q);
                rem64 = cur - q * u64::cast_from(chunk_div);
            }
            u32::cast_from(rem64)
        } else {
            let mut rem = 0u32;
            #[unroll]
            for ii in 0..nlimbs {
                let i = comptime!(nlimbs - 1 - ii);
                let vi = v[i as usize];
                let c1 = (rem << 16u32) | (vi >> 16u32);
                let q1 = c1 / chunk_div;
                let r1 = c1 - q1 * chunk_div;
                let c2 = (r1 << 16u32) | (vi & 0xFFFFu32);
                let q2 = c2 / chunk_div;
                rem = c2 - q2 * chunk_div;
                v[i as usize] = (q1 << 16u32) | q2;
            }
            rem
        };
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
/// `run_len` consecutive candidates from `start + t * run_len` (grid-stride
/// over runs), seeds its digit arrays from the run's first n and steps
/// through the run by digit-array addition. Every candidate must lie where n²
/// has `ls` digits and n³ `lc` (see [`fd_plan`]).
#[cube(launch_unchecked)]
#[allow(
    clippy::too_many_arguments,
    clippy::too_many_lines,
    clippy::similar_names,
    clippy::collapsible_if
)]
pub(crate) fn detailed_fd_kernel(
    hist: &mut Array<Atomic<u32>>,
    miss_count: &mut Array<Atomic<u32>>,
    miss_data: &mut Array<u32>,
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
    #[comptime] wide_chunk: bool,
    #[comptime] cutoff: u32,
    #[comptime] ls: u32,
    #[comptime] lc: u32,
    #[comptime] lds: u32,
    #[comptime] ldc: u32,
    #[comptime] lddc: u32,
) {
    let hist_bins = comptime!(base + 1);
    let sq_limbs = comptime!(2 * limbs);
    let cu_limbs = comptime!(3 * limbs);
    // Words of S, C, dS, dC, ddC.
    let ws = comptime!(ls.div_ceil(4));
    let wc = comptime!(lc.div_ceil(4));
    let wds = comptime!(lds.div_ceil(4));
    let wdc = comptime!(ldc.div_ceil(4));
    let wddc = comptime!(lddc.div_ceil(4));
    // Words of S and C that change on most steps: the addend's words and the
    // word holding the digit just above the addend's top, which takes its
    // carry. A word above them changes only when a carry ripples through
    // every digit between, all b-1: at most once per b^4 steps or so.
    let ks = comptime!((lds + 1).div_ceil(4).min(ws));
    let kc = comptime!((ldc + 1).div_ceil(4).min(wc));
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
    let stride =
        u64::cast_from(CUBE_COUNT_X) * u64::cast_from(CUBE_DIM_X) * u64::cast_from(run_len);

    let mut off = u64::cast_from(ABSOLUTE_POS_X) * u64::cast_from(run_len);
    while off < count {
        let mut len = run_len;
        if count - off < u64::cast_from(run_len) {
            len = u32::cast_from(count - off);
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

        let mut sd = Array::<u32>::new(ws as usize);
        let mut cd = Array::<u32>::new(wc as usize);
        let mut ds = Array::<u32>::new(wds as usize);
        let mut dc = Array::<u32>::new(wdc as usize);
        let mut ddc = Array::<u32>::new(wddc as usize);
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
        fd_to_digits(
            &mut sq,
            &mut sd,
            sq_limbs,
            ls,
            base,
            chunk_digits,
            chunk_div,
            wide_chunk,
        );
        fd_to_digits(
            &mut cu,
            &mut cd,
            cu_limbs,
            lc,
            base,
            chunk_digits,
            chunk_div,
            wide_chunk,
        );
        fd_to_digits(
            &mut v_ds,
            &mut ds,
            comptime!(limbs + 1),
            lds,
            base,
            chunk_digits,
            chunk_div,
            wide_chunk,
        );
        fd_to_digits(
            &mut v_dc,
            &mut dc,
            comptime!(sq_limbs + 1),
            ldc,
            base,
            chunk_digits,
            chunk_div,
            wide_chunk,
        );
        fd_to_digits(
            &mut v_ddc,
            &mut ddc,
            comptime!(limbs + 1),
            lddc,
            base,
            chunk_digits,
            chunk_div,
            wide_chunk,
        );

        // --- walk the run ----------------------------------------------------
        // The cached mask of the slow words of S and C (digits from ks_dig and
        // kc_dig up). It must be refreshed whenever a ripple reaches them,
        // which the rare branch below does; everything else reads only the
        // fast words.
        let mut ms = fd_mask(&sd, 0u64, ks_dig, ls);
        ms = fd_mask(&cd, ms, kc_dig, lc);
        let mut i = 0u32;
        while i < len {
            let mut m = fd_mask(&sd, ms, 0u32, ks_dig);
            m = fd_mask(&cd, m, 0u32, kc_dig);
            let u = u32::cast_from(m).count_ones() + u32::cast_from(m >> 32u64).count_ones();
            hist_s[(copy * hist_bins + u) as usize].fetch_add(1u32);
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

            // Step n -> n+1: the five adds without their ripples into the
            // slow words, then one branch for all five. Each add returns the
            // raw sum of the last word it touched, and a word carried out iff
            // bit 31 of that sum is clear, so the AND of the sums that can
            // carry into a further word is below NO_CARRY iff any did. An add
            // whose last word is its array's top word has nowhere to carry
            // (the array is wide enough for the interval), so it is left out.
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
            if all < NO_CARRY {
                let mut refresh: u32 = 0u32;
                if comptime!(ks < ws) {
                    if ts < NO_CARRY {
                        fd_ripple(&mut sd, ks, ws, base);
                        refresh = 1u32;
                    }
                }
                if comptime!(wds > 1) {
                    if tds < NO_CARRY {
                        fd_ripple(&mut ds, 1u32, wds, base);
                    }
                }
                if comptime!(kc < wc) {
                    if tc < NO_CARRY {
                        fd_ripple(&mut cd, kc, wc, base);
                        refresh = 1u32;
                    }
                }
                if comptime!(wddc < wdc) {
                    if tdc < NO_CARRY {
                        fd_ripple(&mut dc, wddc, wdc, base);
                    }
                }
                if comptime!(wddc > 1) {
                    if tddc < NO_CARRY {
                        fd_ripple(&mut ddc, 1u32, wddc, base);
                    }
                }
                // A ripple changed a slow word of S or C: its cached mask is
                // stale.
                if refresh != 0u32 {
                    ms = fd_mask(&sd, 0u64, ks_dig, ls);
                    ms = fd_mask(&cd, ms, kc_dig, lc);
                }
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

/// The digit lengths the kernel is specialised to at one base: n² has `ls`
/// digits and n³ `lc` for every n in `[reg_lo, reg_hi)`, and the addends
/// 2n+1, 3n²+3n+1 and 6n+6 fit in `lds`, `ldc` and `lddc` digits up to
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
fn natural_digits(x: &Natural, base: u32) -> u32 {
    let mut y = x.clone();
    let mut c = 0;
    while y != 0u32 {
        y.div_assign_rem(Natural::from(base));
        c += 1;
    }
    c
}

/// The finite-difference plan for `base`, or `None` where the kernel does not
/// apply: no u128 range, or above [`FD_MAX_BASE`].
#[must_use]
#[allow(clippy::similar_names)]
pub fn fd_plan(base: u32) -> Option<FdPlan> {
    if base > FD_MAX_BASE || !gpu_supports_base(base) {
        return None;
    }
    let range = crate::base_range::get_base_range_u128(base).ok()??;
    let b = Natural::from(base);
    let n0 = Natural::from(range.range_start);
    let ls = natural_digits(&(&n0 * &n0), base);
    let lc = natural_digits(&(&n0 * &n0 * &n0), base);
    // n² has ls digits for ceil(sqrt(b^(ls-1))) <= n < ceil(sqrt(b^ls)), and
    // likewise n³.
    let lo_s = b.clone().pow(u64::from(ls - 1)).ceiling_root(2);
    let lo_c = b.clone().pow(u64::from(lc - 1)).ceiling_root(3);
    let hi_s = b.clone().pow(u64::from(ls)).ceiling_root(2);
    let hi_c = b.pow(u64::from(lc)).ceiling_root(3);
    let reg_lo = u128::try_from(&lo_s.max(lo_c)).ok()?;
    let hi = hi_s.min(hi_c);
    let reg_hi = u128::try_from(&hi).ok()?;
    // The addends after the interval's last step, the largest they get.
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::client_process::process_range_detailed;
    use crate::cubecl_backend::{
        CUBECL_BATCH_SIZE, CubeclContext, DetailedKernel, process_range_detailed_cubecl_kernel,
    };
    use crate::{FieldResults, FieldSize};

    /// The kernel's interval is exactly the legal range at every base it
    /// serves, so production fields never leave it, and nothing above
    /// [`FD_MAX_BASE`] gets a plan.
    #[test]
    fn plan_covers_exactly_the_legal_range() {
        let mut served = 0;
        for base in 10..=FD_MAX_BASE {
            let Ok(Some(range)) = crate::base_range::get_base_range_u128(base) else {
                assert!(fd_plan(base).is_none(), "b{base}: plan without a range");
                continue;
            };
            let plan = fd_plan(base).unwrap_or_else(|| panic!("b{base}: no plan"));
            assert_eq!(
                (plan.reg_lo, plan.reg_hi),
                (range.range_start, range.range_end),
                "b{base}: regular interval"
            );
            assert_eq!(plan.ls + plan.lc, base, "b{base}: digit lengths");
            served += 1;
        }
        assert_eq!(served, 44, "bases 10-64 with a range");
        for base in FD_MAX_BASE + 1..=128 {
            assert!(fd_plan(base).is_none(), "b{base}");
        }
    }

    /// `process_range_detailed` over scoped threads, merged.
    fn cpu_detailed_parallel(range: &FieldSize, base: u32) -> FieldResults {
        let threads =
            std::thread::available_parallelism().map_or(8, std::num::NonZero::get) as u128;
        let step = range.size().div_ceil(threads).max(1);
        let parts: Vec<FieldResults> = std::thread::scope(|sc| {
            let hs: Vec<_> = (0..threads)
                .filter_map(|t| {
                    let a = range.start() + t * step;
                    let z = (a + step).min(range.end());
                    (a < z).then(|| {
                        sc.spawn(move || process_range_detailed(&FieldSize::new(a, z), base))
                    })
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

    /// Run shapes the exactness tests cover: the default; a run length that
    /// leaves a partial run in every window; one number per run, so every n
    /// is seeded by division; and many short batches, each ending in a
    /// partial run.
    const SHAPES: [(u32, u128); 4] = [
        (FD_RUN_LEN, CUBECL_BATCH_SIZE),
        (61, CUBECL_BATCH_SIZE),
        (1, CUBECL_BATCH_SIZE),
        (1000, 333_333),
    ];

    fn run(
        ctx: &CubeclContext,
        range: &FieldSize,
        base: u32,
        kernel: DetailedKernel,
    ) -> FieldResults {
        cubecl::future::block_on(process_range_detailed_cubecl_kernel(
            ctx, range, base, kernel,
        ))
        .expect("cubecl detailed run")
    }

    fn assert_shapes_match(
        ctx: &CubeclContext,
        range: &FieldSize,
        base: u32,
        cpu: &FieldResults,
        what: &str,
    ) {
        for (run_len, batch) in SHAPES {
            let gpu = run(
                ctx,
                range,
                base,
                DetailedKernel::FiniteDifference { run_len, batch },
            );
            assert_eq!(
                gpu.distribution, cpu.distribution,
                "b{base} {what}, run {run_len}, batch {batch}: distribution"
            );
            assert_eq!(
                gpu.nice_numbers, cpu.nice_numbers,
                "b{base} {what}, run {run_len}, batch {batch}: near-misses"
            );
        }
    }

    /// Windows of `w` numbers at b40 and b50: the range start and end, one
    /// straddling the range start (n³ gains a digit there, so each batch
    /// splits between the two kernels), eight seeded random ones, and one
    /// centred on every point inside the range where an addend gains a
    /// digit.
    fn windows(base: u32, width: u128) -> Vec<(FieldSize, String)> {
        let legal = crate::base_range::get_base_range_u128(base)
            .unwrap()
            .unwrap();
        let (rs, re) = (legal.range_start, legal.range_end);
        let mut out = vec![
            (
                FieldSize::new(rs, rs + 2 * width),
                "range start".to_string(),
            ),
            (FieldSize::new(re - 2 * width, re), "range end".into()),
            (
                FieldSize::new(rs - width, rs + width),
                "straddling the range start".into(),
            ),
        ];
        let mut state = 0x9E37_79B9_7F4A_7C15u64 ^ u64::from(base);
        for i in 0..8 {
            state = state.wrapping_add(0x9E37_79B9_7F4A_7C15);
            let mut z = state;
            z = (z ^ (z >> 30)).wrapping_mul(0xBF58_476D_1CE4_E5B9);
            z = (z ^ (z >> 27)).wrapping_mul(0x94D0_49BB_1331_11EB);
            z ^= z >> 31;
            let off = (u128::from(z) * (re - rs - width)) >> 64;
            out.push((
                FieldSize::new(rs + off, rs + off + width),
                format!("random {i}"),
            ));
        }
        let b128 = u128::from(base);
        for k in 1..=30u32 {
            let Some(bk) = b128.checked_pow(k) else { break };
            let g_ds = bk.saturating_sub(1).div_ceil(2);
            let g_ddc = bk.saturating_sub(6).div_ceil(6);
            // The smallest n with 3n² + 3n + 1 >= b^k.
            let (mut lo, mut hi) = (0u128, 1u128 << 64);
            while lo < hi {
                let mid = lo.midpoint(hi);
                let value = mid
                    .checked_mul(mid)
                    .and_then(|q| q.checked_mul(3))
                    .and_then(|q| q.checked_add(3 * mid + 1));
                if value.is_none_or(|v| v >= bk) {
                    hi = mid;
                } else {
                    lo = mid + 1;
                }
            }
            for (name, g) in [("dS", g_ds), ("ddC", g_ddc), ("dC", lo)] {
                if g > rs + width && g + width < re {
                    out.push((
                        FieldSize::new(g - width / 2, g + width / 2),
                        format!("{name} gains digit {k} at {g}"),
                    ));
                }
            }
        }
        out
    }

    /// The whole range of every base from 10 to `max_base` that has one,
    /// every run shape: the windows with near-misses. Returns how many.
    fn small_bases(ctx: &CubeclContext, max_base: u32) -> usize {
        let mut misses = 0;
        for base in 10..=max_base {
            let Ok(Some(range)) = crate::base_range::get_base_range_u128(base) else {
                continue;
            };
            let cpu = cpu_detailed_parallel(&range, base);
            assert_shapes_match(ctx, &range, base, &cpu, "full range");
            misses += cpu.nice_numbers.len();
            println!(
                "b{base} full range ({} numbers): exact, {} near-misses",
                range.size(),
                cpu.nice_numbers.len()
            );
        }
        misses
    }

    /// The finite-difference kernel against the CPU through the native CUDA
    /// runtime: at b40 and b50 every window of [`windows`] at 1e6 numbers
    /// under every run shape, the 2e8-number benchmark window whole against
    /// both the CPU and the per-number kernel, and the full range of every
    /// base 10-28 (76 million numbers).
    #[test]
    #[cfg(feature = "cubecl-cuda")]
    #[ignore = "requires an NVIDIA device"]
    fn cubecl_cuda_fd_matches_cpu_detailed() {
        let ctx = CubeclContext::new_cuda(0).expect("CubeCL CUDA init");
        for base in [40u32, 50] {
            for (range, what) in windows(base, 1_000_000) {
                let cpu = cpu_detailed_parallel(&range, base);
                assert_shapes_match(&ctx, &range, base, &cpu, &what);
                println!("b{base} {what}: [{}, {}) exact", range.start(), range.end());
            }
            let rs = crate::base_range::get_base_range_u128(base)
                .unwrap()
                .unwrap()
                .range_start;
            let range = FieldSize::new(rs, rs + 200_000_000);
            let cpu = cpu_detailed_parallel(&range, base);
            let fd = run(&ctx, &range, base, DetailedKernel::DEFAULT);
            let div = run(&ctx, &range, base, DetailedKernel::Division);
            assert_eq!(
                fd.distribution, cpu.distribution,
                "b{base} benchmark window"
            );
            assert_eq!(
                fd.nice_numbers, cpu.nice_numbers,
                "b{base} benchmark window"
            );
            assert_eq!(
                div.distribution, cpu.distribution,
                "b{base} benchmark window"
            );
            assert_eq!(
                div.nice_numbers, cpu.nice_numbers,
                "b{base} benchmark window"
            );
            println!("b{base} benchmark window [{rs}, +2e8): finite differences = division = CPU");
        }
        let misses = small_bases(&ctx, 28);
        assert!(misses > 0, "no near-misses compared");
        println!("bases 10-28: {misses} near-misses");
    }

    /// As [`cubecl_cuda_fd_matches_cpu_detailed`] on the default wgpu
    /// device, sized for a software rasterizer: windows of 1e5 numbers and
    /// bases 10-24 in full. It runs the kernel even on Metal, where
    /// production does not: on an Apple M4 it fails at the b50 range start.
    #[test]
    #[ignore = "requires a wgpu device"]
    fn cubecl_fd_matches_cpu_detailed() {
        let ctx = CubeclContext::new_default().expect("CubeCL init");
        for base in [40u32, 50] {
            for (range, what) in windows(base, 100_000) {
                let cpu = cpu_detailed_parallel(&range, base);
                assert_shapes_match(&ctx, &range, base, &cpu, &what);
                println!("b{base} {what}: [{}, {}) exact", range.start(), range.end());
            }
        }
        let misses = small_bases(&ctx, 24);
        assert!(misses > 0, "no near-misses compared");
        println!("bases 10-24: {misses} near-misses");
    }
}
