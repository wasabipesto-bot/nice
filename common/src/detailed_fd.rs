//! Detailed mode by finite differences (research prototype, L2).
//!
//! `process_range_detailed` recomputes n² and n³ for every number and pulls
//! each base-b digit out with a multi-limb division. Over a run of
//! consecutive n the same values follow from additions alone:
//!
//! ```text
//! S  = n²   S  += dS    dS  = 2n + 1        dS  += 2
//! C  = n³   C  += dC    dC  = 3n² + 3n + 1  dC  += ddC
//!                       ddC = 6n + 6        ddC += 6
//! ```
//!
//! Each value is kept as a little-endian array of base-b digits with its
//! length (the position past the top non-zero digit; positions at and above
//! it are always zero). An array add is add, compare with b, conditional
//! subtract, carry: no division anywhere in the loop. The digit-presence
//! mask is rebuilt from the `len` digits of S and C, so leading zeros never
//! enter it, and `count_ones()` gives `num_uniques` exactly as the division
//! path does.
//!
//! The state is seeded once per range from the existing exact fixed-width
//! arithmetic (`U256`).

// Hot-loop helpers: forced inlining is the point (each is called at a handful
// of sites inside the per-number loop).
#![allow(clippy::inline_always)]

use crate::client_process::process_range_detailed;
use crate::fixed_width::U256;
use crate::{FieldResults, FieldSize, NiceNumberSimple, UniquesDistributionSimple, number_stats};

/// Digit capacity of every array, a whole number of 64-bit words. The largest
/// value carried is n³: 38 digits at base 64 over its legal range. The slack
/// covers the out-of-range test windows and the word past the top that the
/// word-parallel add always touches; an overflow would panic on the bounds
/// check, never wrap.
const CAP: usize = 72;

/// One in every byte of a word.
const LO: u64 = 0x0101_0101_0101_0101;

/// One word (8 digits, one per byte) of base-`BASE` addition: `a + r + cin`.
///
/// Classic biased addition, as in BCD: add `256 - BASE` to every byte of the
/// addend, so a byte overflows into the next exactly when its digit sum
/// reaches `BASE`, and the native 64-bit add propagates all eight carries.
/// Bytes that did not carry out then take the bias back off. Needs every byte
/// of `a` and `r` below `BASE`.
#[inline(always)]
fn add_word<const BASE: u32>(a: u64, r: u64, cin: bool) -> (u64, bool) {
    let bias = 256 - u64::from(BASE);
    let rb = r + bias * LO; // per byte r + bias ≤ 255: no cross-byte carry
    let (t, c1) = a.overflowing_add(rb);
    let (t, c2) = t.overflowing_add(u64::from(cin));
    let cout = c1 | c2;
    // Bit 8j of t ^ a ^ rb is the carry into byte j; the carry out of byte j
    // is the carry into byte j + 1, and `cout` for the top byte.
    let carried = (((t ^ a ^ rb) >> 8) & LO) | (u64::from(cout) << 56);
    (t - (carried ^ LO) * bias, cout)
}

/// A non-negative integer as base-`BASE` digits, least significant first.
#[derive(Clone, Copy)]
struct Digits {
    d: [u8; CAP],
    /// Number of significant digits; `d[len..]` is all zero.
    len: usize,
}

impl Digits {
    #[allow(clippy::cast_possible_truncation)]
    fn from_u256<const BASE: u32>(mut x: U256) -> Self {
        let mut d = [0u8; CAP];
        let mut len = 0;
        while !x.is_zero() {
            d[len] = x.div_assign_rem_u32_const::<BASE>() as u8;
            len += 1;
        }
        Self { d, len }
    }

    fn from_u128<const BASE: u32>(x: u128) -> Self {
        Self::from_u256::<BASE>(U256::from_u128(x))
    }

    /// Ripple a carry of one into position `i` and up.
    #[inline(always)]
    #[allow(clippy::cast_possible_truncation)]
    fn ripple<const BASE: u32>(&mut self, mut i: usize) {
        loop {
            let t = self.d[i] + 1;
            if t == BASE as u8 {
                self.d[i] = 0;
                i += 1;
            } else {
                self.d[i] = t;
                if i >= self.len {
                    self.len = i + 1;
                }
                return;
            }
        }
    }

    /// `self += rhs`, where `rhs` is a little-endian digit slice.
    ///
    /// The digit carries are data-dependent coin flips, so the select is
    /// marked unpredictable: without that, LLVM's cmov converter turns it
    /// into a branch that mispredicts about half the time (measured: about
    /// 17 misses per number, 3x slower). The carry out of the top addend
    /// digit is applied unconditionally for the same reason; only the rare
    /// ripple past it (or a new top digit) branches.
    #[inline(always)]
    #[allow(clippy::cast_possible_truncation)]
    fn add_digits<const BASE: u32>(&mut self, rhs: &[u8]) {
        let b = BASE as u8;
        let n = rhs.len();
        let mut carry = 0u8;
        // Positions at and above `self.len` are zero, so an addend longer
        // than `self` needs no special case beyond the length update.
        for (a, &r) in self.d[..n].iter_mut().zip(rhs) {
            let t = *a + r + carry;
            let ge = t >= b;
            *a = std::hint::select_unpredictable(ge, t.wrapping_sub(b), t);
            carry = u8::from(ge);
        }
        if n < self.len {
            let t = self.d[n] + carry;
            if t == b {
                self.d[n] = 0;
                self.ripple::<BASE>(n + 1);
            } else {
                self.d[n] = t;
            }
        } else {
            // The sum is at least as long as the addend; a carry out of the
            // top adds one more digit.
            self.len = n;
            if carry != 0 {
                self.d[n] = 1;
                self.len = n + 1;
            }
        }
    }

    /// `self += rhs`.
    #[inline(always)]
    fn add_assign<const BASE: u32>(&mut self, rhs: &Self) {
        self.add_digits::<BASE>(&rhs.d[..rhs.len]);
    }

    /// `self += k` for a single digit `0 < k < BASE`.
    #[inline(always)]
    fn add_small<const BASE: u32>(&mut self, k: u8) {
        self.add_digits::<BASE>(&[k]);
    }

    #[inline(always)]
    fn word(&self, i: usize) -> u64 {
        u64::from_le_bytes(self.d[8 * i..8 * i + 8].try_into().unwrap())
    }

    #[inline(always)]
    fn set_word(&mut self, i: usize, w: u64) {
        self.d[8 * i..8 * i + 8].copy_from_slice(&w.to_le_bytes());
    }

    /// Carry one into word `i` and up (rare: needs eight digits of b - 1).
    #[inline(never)]
    fn ripple_words<const BASE: u32>(&mut self, mut i: usize) {
        loop {
            let (t, c) = add_word::<BASE>(self.word(i), 0, true);
            self.set_word(i, t);
            if !c {
                return;
            }
            i += 1;
        }
    }

    /// The sum has at most one digit more than the longer operand.
    #[inline(always)]
    fn fix_len(&mut self, operand_len: usize) {
        let len = self.len.max(operand_len);
        self.len = len + usize::from(self.d[len] != 0);
    }

    /// `self += rhs`, eight digits per 64-bit add.
    ///
    /// The word above the addend's top word always takes the carry (it is
    /// often set); only a carry out of that one branches.
    #[inline(always)]
    fn add_assign_swar<const BASE: u32>(&mut self, rhs: &Self) {
        let nw = rhs.len.div_ceil(8);
        let mut c = false;
        for i in 0..nw {
            let (t, co) = add_word::<BASE>(self.word(i), rhs.word(i), c);
            self.set_word(i, t);
            c = co;
        }
        let (t, co) = add_word::<BASE>(self.word(nw), 0, c);
        self.set_word(nw, t);
        if co {
            self.ripple_words::<BASE>(nw + 1);
        }
        self.fix_len(rhs.len);
    }

    /// `self += k` for a single digit `0 < k < BASE`, eight digits per add.
    #[inline(always)]
    fn add_small_swar<const BASE: u32>(&mut self, k: u8) {
        let (t, co) = add_word::<BASE>(self.word(0), u64::from(k), false);
        self.set_word(0, t);
        if co {
            self.ripple_words::<BASE>(1);
        }
        self.fix_len(1);
    }

    /// Bit `d` set for every significant digit `d`.
    #[inline(always)]
    fn mask(&self) -> u64 {
        // Two accumulators halve the OR dependency chain.
        let (pairs, rest) = self.d[..self.len].as_chunks::<2>();
        let (mut m0, mut m1) = (0u64, 0u64);
        for &[a, b] in pairs {
            m0 |= 1u64 << a;
            m1 |= 1u64 << b;
        }
        for &d in rest {
            m0 |= 1u64 << d;
        }
        m0 | m1
    }
}

/// The finite-difference state for n: digits of n², n³ and the three
/// differences that step them to n + 1.
struct State {
    s: Digits,
    ds: Digits,
    c: Digits,
    dc: Digits,
    ddc: Digits,
}

impl State {
    /// Seed the state at `n` with exact fixed-width arithmetic.
    fn new<const BASE: u32>(n: u128) -> Self {
        let square = U256::mul_u128_u128(n, n);
        let cube = square.mul_u128_truncating(n);
        // 3n² + 3n + 1 = 3·n(n+1) + 1, and 3·n(n+1) is even.
        let mut dc = U256::mul_u128_u128(n, n + 1).mul_u128_truncating(3);
        dc.limbs[0] |= 1;
        Self {
            s: Digits::from_u256::<BASE>(square),
            ds: Digits::from_u128::<BASE>(2 * n + 1),
            c: Digits::from_u256::<BASE>(cube),
            dc: Digits::from_u256::<BASE>(dc),
            ddc: Digits::from_u128::<BASE>(6 * (n + 1)),
        }
    }

    /// `num_uniques` for the current n.
    #[inline(always)]
    fn num_uniques(&self) -> u32 {
        (self.s.mask() | self.c.mask()).count_ones()
    }

    /// Advance from n to n + 1, by digit-serial adds or (`SWAR`) eight
    /// digits per 64-bit add.
    #[inline(always)]
    fn step<const BASE: u32, const SWAR: bool>(&mut self) {
        if SWAR {
            self.s.add_assign_swar::<BASE>(&self.ds);
            self.ds.add_small_swar::<BASE>(2);
            self.c.add_assign_swar::<BASE>(&self.dc);
            self.dc.add_assign_swar::<BASE>(&self.ddc);
            self.ddc.add_small_swar::<BASE>(6);
        } else {
            self.s.add_assign::<BASE>(&self.ds);
            self.ds.add_small::<BASE>(2);
            self.c.add_assign::<BASE>(&self.dc);
            self.dc.add_assign::<BASE>(&self.ddc);
            self.ddc.add_small::<BASE>(6);
        }
    }
}

/// Per-number `num_uniques` over `[start, end)` by finite differences,
/// passed to `f` in order. Exposed for the exactness tests.
#[inline(always)]
fn for_each_uniques<const BASE: u32, const SWAR: bool>(
    start: u128,
    end: u128,
    mut f: impl FnMut(u128, u32),
) {
    const { assert!(BASE >= 7 && BASE <= 64, "u64 mask, and 6 must be one digit") };
    if start >= end {
        return;
    }
    let mut st = State::new::<BASE>(start);
    for num in start..end {
        f(num, st.num_uniques());
        st.step::<BASE, SWAR>();
    }
}

#[allow(clippy::cast_possible_truncation)]
fn run<const BASE: u32, const SWAR: bool>(range: &FieldSize) -> FieldResults {
    let cutoff = number_stats::get_near_miss_cutoff(BASE);
    let mut nice_numbers: Vec<NiceNumberSimple> = Vec::new();
    let mut histogram = [0u128; 65];
    for_each_uniques::<BASE, SWAR>(range.start(), range.end(), |number, num_uniques| {
        histogram[num_uniques as usize] += 1;
        if num_uniques > cutoff {
            nice_numbers.push(NiceNumberSimple {
                number,
                num_uniques,
            });
        }
    });
    let distribution = (1..=BASE)
        .map(|i| UniquesDistributionSimple {
            num_uniques: i,
            count: histogram[i as usize],
        })
        .collect();
    FieldResults {
        distribution,
        nice_numbers,
    }
}

/// Drop-in replacement for `process_range_detailed` (same signature, same
/// output) using finite differences for the bases the const-generic division
/// path covers; every other base falls through to `process_range_detailed`.
#[must_use]
pub fn process_range_detailed_fd(range: &FieldSize, base: u32) -> FieldResults {
    dispatch::<true>(range, base)
}

fn dispatch<const SWAR: bool>(range: &FieldSize, base: u32) -> FieldResults {
    match base {
        40 => run::<40, SWAR>(range),
        42 => run::<42, SWAR>(range),
        43 => run::<43, SWAR>(range),
        44 => run::<44, SWAR>(range),
        45 => run::<45, SWAR>(range),
        47 => run::<47, SWAR>(range),
        48 => run::<48, SWAR>(range),
        49 => run::<49, SWAR>(range),
        50 => run::<50, SWAR>(range),
        52 => run::<52, SWAR>(range),
        53 => run::<53, SWAR>(range),
        54 => run::<54, SWAR>(range),
        55 => run::<55, SWAR>(range),
        57 => run::<57, SWAR>(range),
        58 => run::<58, SWAR>(range),
        59 => run::<59, SWAR>(range),
        60 => run::<60, SWAR>(range),
        62 => run::<62, SWAR>(range),
        64 => run::<64, SWAR>(range),
        _ => process_range_detailed(range, base),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::base_range::{get_base_range_natural, get_base_range_u128};
    use crate::bench_defs::DETAILED_SCENARIOS;
    use crate::client_process::get_num_unique_digits;
    use malachite::base::num::arithmetic::traits::{CeilingRoot, Pow};
    use malachite::natural::Natural;

    /// splitmix64: a seeded, dependency-free PRNG for window starts.
    struct Rng(u64);
    impl Rng {
        fn next(&mut self) -> u64 {
            self.0 = self.0.wrapping_add(0x9E37_79B9_7F4A_7C15);
            let mut z = self.0;
            z = (z ^ (z >> 30)).wrapping_mul(0xBF58_476D_1CE4_E5B9);
            z = (z ^ (z >> 27)).wrapping_mul(0x94D0_49BB_1331_11EB);
            z ^ (z >> 31)
        }
        fn below(&mut self, n: u128) -> u128 {
            ((u128::from(self.next()) << 64) | u128::from(self.next())) % n
        }
    }

    /// Compare finite differences with `get_num_unique_digits` number by
    /// number over `[start, start + len)`.
    fn check_window<const BASE: u32>(start: u128, len: u128) {
        check_window_variant::<BASE, false>(start, len);
        check_window_variant::<BASE, true>(start, len);
    }

    fn check_window_variant<const BASE: u32, const SWAR: bool>(start: u128, len: u128) {
        let mut expect = start;
        for_each_uniques::<BASE, SWAR>(start, start + len, |n, u| {
            assert_eq!(n, expect);
            assert_eq!(
                u,
                get_num_unique_digits(n, BASE),
                "base {BASE}, swar {SWAR}, n = {n} (window start {start})"
            );
            expect += 1;
        });
        assert_eq!(expect, start + len);
    }

    fn random_windows<const BASE: u32>(seed: u64) {
        let range = get_base_range_u128(BASE).unwrap().unwrap();
        let len = 10_000;
        let mut rng = Rng(seed);
        for _ in 0..20 {
            let start = range.start() + rng.below(range.size() - len);
            check_window::<BASE>(start, len);
        }
        // Both ends of the legal range.
        check_window::<BASE>(range.start(), len);
        check_window::<BASE>(range.end() - len, len);
    }

    /// Windows of 10,000 centred on every point from a factor `BASE` below
    /// the legal range up to its end where n² or n³ gains a digit: the
    /// smallest n with `n^root ≥ BASE^m`. (Past the end, n³ outgrows the
    /// reference's u128 path at base 40.)
    fn digit_gain_windows<const BASE: u32>() {
        let (lo, hi) = get_base_range_natural(BASE).unwrap();
        let lo = lo / Natural::from(BASE);
        let half = 5_000;
        let mut checked = 0;
        for (root, ms) in [(2u64, 0..140u64), (3, 0..200)] {
            for m in ms {
                let x = Natural::from(BASE).pow(m).ceiling_root(root);
                if x < lo || x > hi {
                    continue;
                }
                let x = u128::try_from(&x).unwrap();
                assert!(x > half);
                check_window::<BASE>(x - half, 2 * half);
                checked += 1;
            }
        }
        assert!(
            checked >= 3,
            "base {BASE}: only {checked} digit-gain windows"
        );
    }

    #[test]
    fn fd_matches_division_small_base_from_zero() {
        // Base 10 from n = 0: hundreds of digit gains in S, C and the
        // differences, and the empty (zero) start.
        check_window::<10>(0, 200_000);
        check_window::<7>(0, 50_000);
    }

    #[test]
    fn fd_matches_division_b40_random_windows() {
        random_windows::<40>(0x4040_4040);
    }

    #[test]
    fn fd_matches_division_b50_random_windows() {
        random_windows::<50>(0x5050_5050);
    }

    #[test]
    fn fd_matches_division_b60_random_windows() {
        random_windows::<60>(0x6060_6060);
    }

    #[test]
    fn fd_matches_division_other_bases_random_windows() {
        random_windows::<42>(42);
        random_windows::<47>(47);
        random_windows::<53>(53);
        random_windows::<59>(59);
        random_windows::<64>(64);
    }

    #[test]
    fn fd_matches_division_b40_digit_gains() {
        digit_gain_windows::<40>();
    }

    #[test]
    fn fd_matches_division_b50_digit_gains() {
        digit_gain_windows::<50>();
    }

    #[test]
    fn fd_matches_division_b60_digit_gains() {
        digit_gain_windows::<60>();
    }

    #[test]
    fn fd_field_results_match_detailed_benchmark_windows() {
        for def in DETAILED_SCENARIOS.iter().filter(|d| !d.single_thread) {
            let start = def.resolved_start();
            let range = FieldSize::new(start, start + def.window_cpu);
            let old = process_range_detailed(&range, def.base);
            let new = process_range_detailed_fd(&range, def.base);
            assert_eq!(old, new, "{}", def.key);
            assert_eq!(old, dispatch::<false>(&range, def.base), "{}", def.key);
            let total: u128 = new.distribution.iter().map(|d| d.count).sum();
            assert_eq!(total, def.window_cpu, "{}", def.key);
            eprintln!(
                "{}: {} numbers, {} near-misses, identical",
                def.key,
                total,
                new.nice_numbers.len()
            );
        }
    }

    #[test]
    fn fd_field_results_match_small_bases_full_range() {
        // The benchmark windows hold no near-misses, so the list itself is
        // checked here: every small base's whole range, run through the
        // generic finite-difference loop.
        fn check<const B: u32>() -> usize {
            let range = get_base_range_u128(B).unwrap().unwrap();
            if range.size() > 5_000_000 {
                return 0;
            }
            let new = run::<B, true>(&range);
            assert_eq!(new, process_range_detailed(&range, B), "base {B}");
            assert_eq!(new, run::<B, false>(&range), "base {B}");
            new.nice_numbers.len()
        }
        let near_misses = check::<10>()
            + check::<12>()
            + check::<13>()
            + check::<14>()
            + check::<15>()
            + check::<17>()
            + check::<18>()
            + check::<19>()
            + check::<20>()
            + check::<22>()
            + check::<23>()
            + check::<24>()
            + check::<25>()
            + check::<27>()
            + check::<28>()
            + check::<29>();
        eprintln!("small bases: {near_misses} near-misses, identical");
        assert!(near_misses > 0);
    }

    #[test]
    fn fd_falls_through_for_other_bases() {
        let range = get_base_range_u128(10).unwrap().unwrap();
        assert_eq!(
            process_range_detailed_fd(&range, 10),
            process_range_detailed(&range, 10)
        );
    }

    /// Single-thread timing of the division loop against the two
    /// finite-difference loops (digit-serial adds, then word-parallel adds) on
    /// the same 1,000,000-number window at the start of each base's range,
    /// interleaved old / bytes / words over three rounds.
    ///
    /// `taskset -c 3 cargo test --release -p nice_common --lib fd_timing -- --ignored --nocapture --test-threads 1`
    ///
    /// For per-variant hardware counters, `FD_TIMING_BASE=50` and
    /// `FD_TIMING_ONLY=old|bytes|words` restrict the run (under `perf stat`).
    #[test]
    #[ignore = "timing, run by hand"]
    #[allow(clippy::cast_precision_loss)]
    fn fd_timing() {
        use std::hint::black_box;
        use std::time::Instant;
        let window: u128 = 1_000_000;
        let rounds = 3;
        let fmt = |v: &[f64]| {
            v.iter()
                .map(|x| format!("{x:.2}"))
                .collect::<Vec<_>>()
                .join(" ")
        };
        let med = |v: &[f64]| {
            let mut s = v.to_vec();
            s.sort_by(f64::total_cmp);
            s[s.len() / 2]
        };
        let only_base: Option<u32> = std::env::var("FD_TIMING_BASE")
            .ok()
            .map(|b| b.parse().unwrap());
        let only = std::env::var("FD_TIMING_ONLY").ok();
        let names = ["old", "bytes", "words"];
        for base in [40u32, 50, 60] {
            if only_base.is_some_and(|b| b != base) {
                continue;
            }
            let start = get_base_range_u128(base).unwrap().unwrap().start();
            let range = FieldSize::new(start, start + window);
            let mut ns = [Vec::new(), Vec::new(), Vec::new()];
            for _ in 0..rounds {
                let mut results = Vec::new();
                for (k, f) in [
                    process_range_detailed as fn(&FieldSize, u32) -> FieldResults,
                    dispatch::<false>,
                    dispatch::<true>,
                ]
                .into_iter()
                .enumerate()
                {
                    if only.as_ref().is_some_and(|o| o != names[k]) {
                        ns[k].push(f64::NAN);
                        continue;
                    }
                    let t = Instant::now();
                    results.push(black_box(f(black_box(&range), base)));
                    ns[k].push(t.elapsed().as_nanos() as f64 / window as f64);
                }
                assert!(results.iter().all(|r| *r == results[0]));
            }
            let [old, bytes, words] = &ns;
            eprintln!(
                "TIMING b{base}: old [{}] med {:.2} | fd-bytes [{}] med {:.2} ({:.2}x) | fd-words [{}] med {:.2} ({:.2}x)",
                fmt(old),
                med(old),
                fmt(bytes),
                med(bytes),
                med(old) / med(bytes),
                fmt(words),
                med(words),
                med(old) / med(words),
            );
        }
    }
}
