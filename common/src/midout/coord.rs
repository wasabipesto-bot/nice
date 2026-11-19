//! The work unit of the middle-out join: a *field*, a range of a per-base
//! coordinate `v`. This module is the whole of what a field means; it knows
//! nothing of how a field is searched.
//!
//! # The coordinate
//!
//! For a base `b` with range `[start, end)` and three digit positions
//! `k0 <= q0 < k1`, write every `n` of the range as
//!
//! ```text
//! n = h·b^k1 + key·b^k0 + low,   key = digits [k0, k1) of n, low = n mod b^k0
//! v = start + key·(H·b^k0) + (h − h0)·b^k0 + low
//! ```
//!
//! with `h0 = start div b^k1` and `H = (end − 1) div b^k1 − h0 + 1`
//! ([`Coord::hn`]), the number of values `h` takes. `v` moves the digits `[k0, k1)` of `n` above
//! all the others and keeps the rest in their order. It is one to one from
//! the range into `[start, start + H·b^k1)`.
//!
//! **Base 64** is the only base with a coordinate ([`Coord::for_base`]):
//! `(k0, k1, q0) = (4, 8, 5)`. Its range is exactly `[2^75, 2^76)`, so
//! `H = 2^27`, `h0 = 2^27`, and `v` is a permutation of the bits of `n`:
//! digits 4–7 (bits 24–47) move up to bits 51–74, the rest keep their
//! order:
//!
//! ```text
//! v = 2^75 + key·2^51 + (h − 2^27)·2^24 + low,
//!     h = n >> 48, key = (n >> 24) mod 2^24, low = n mod 2^24
//! ```
//!
//! **Other bases** (here only in tests): the same formula. When the range
//! does not start and end on multiples of `b^k1`, some `v` of the first and
//! last values of `h` have no `n` in the range; they are *padding*, and
//! [`Coord::n_of_v`] returns `None` for them. The tests use small bases,
//! where every `n` can be visited, to check the formula in that general
//! form, and base 65 as a large base that pads.
//!
//! # What a field fixes
//!
//! A field is `(base, v_start, v_size)`. It must be a whole number of
//! *quanta*: `v_start − start` and `v_size` multiples of
//! [`Coord::quantum`] `= H·b^q0`. One quantum is exactly the set of `n` of
//! the range whose digits `[q0, k1)` take one value `t`, every other digit
//! free; a field is the set of `n` whose digits `[q0, k1)` lie in a range of
//! values `[t0, t1)` ([`Coord::field_digits`]). That set is all a search of
//! the field may rely on: the order of `v` inside a quantum, and the digits
//! `[k0, q0)`, are not part of the contract.
//!
//! At base 64 a field of one quantum is all `n` with one value of digits
//! 5–7: `2^57` numbers, and the base has `64^3 = 262,144` such fields.
//!
//! The number of `n` in a field is [`Coord::n_count`], not `v_size`; they
//! differ only by padding (never at base 64).
//!
//! # Slices
//!
//! The search works on *slices*: at base 64, the `2^45` numbers that share
//! one value of digits 4–8. A field fixes digits 5–7 only, so every slice
//! lies in exactly one field and a field of one quantum is exactly 4,096
//! whole slices (every value of digit 4 times every value of digit 8). Any
//! search that splits `n` into a top part and a bottom part sees every
//! digit of `n` on one side or the other, so it can restrict itself to a
//! field by its fixed digits alone; and a search by slices is free in its
//! shape, its order and its grouping of slices inside a field. Leaving
//! digits 4 and 8 free lets neighbouring slices of a field share
//! preparation: slices that differ only in digit 4 have the same digits
//! above it (the tops' side), and slices that differ only in digit 8 the
//! same digits below it (the bottoms' side).
//!
//! No server stores this coordinate or its fields; nothing here proposes a
//! field row, a claim format or an API.

use crate::base_range::get_base_range_u128;
use anyhow::{Result, bail, ensure};
use std::ops::Range;

/// A base's coordinate (see the module documentation). Built only by
/// [`Coord::for_base`] or [`Coord::with_digits`], which check the digit
/// positions and that `v` fits; its values are read by the methods below.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Coord {
    b: u32,
    start: u128,
    end: u128,
    k0: u32,
    k1: u32,
    q0: u32,
    h0: u128,
    hn: u128,
}

/// The digit positions `(k0, k1, q0)` of base `b`'s coordinate: `(4, 8, 5)`
/// at base 64 (a field fixes digits 5–7), none at any other base.
#[must_use]
pub fn coord_digits(b: u32) -> Option<(u32, u32, u32)> {
    match b {
        64 => Some((4, 8, 5)),
        _ => None,
    }
}

impl Coord {
    /// The base.
    #[must_use]
    pub fn b(&self) -> u32 {
        self.b
    }

    /// The first `n` of the base's range `[start, end)` (and the first `v`).
    #[must_use]
    pub fn start(&self) -> u128 {
        self.start
    }

    /// One past the last `n` of the base's range.
    #[must_use]
    pub fn end(&self) -> u128 {
        self.end
    }

    /// The lowest of the digits `[k0, k1)` that go on top of `v`.
    #[must_use]
    pub fn k0(&self) -> u32 {
        self.k0
    }

    /// One past the highest of the digits `[k0, k1)` that go on top of `v`.
    #[must_use]
    pub fn k1(&self) -> u32 {
        self.k1
    }

    /// A field fixes the digits `[q0, k1)`.
    #[must_use]
    pub fn q0(&self) -> u32 {
        self.q0
    }

    /// `h0 = start div b^k1`.
    #[must_use]
    pub fn h0(&self) -> u128 {
        self.h0
    }

    /// `H`, the number of values `h = n div b^k1` takes.
    #[must_use]
    pub fn hn(&self) -> u128 {
        self.hn
    }

    /// The coordinate of base `b` ([`coord_digits`]).
    ///
    /// # Errors
    /// A base without a coordinate.
    pub fn for_base(b: u32) -> Result<Self> {
        let Some((k0, k1, q0)) = coord_digits(b) else {
            bail!("middle-out: base {b} has no field coordinate");
        };
        Self::with_digits(b, k0, k1, q0)
    }

    /// Whether this is its base's coordinate ([`coord_digits`]), the one
    /// fields are cut in.
    #[must_use]
    pub fn is_known(&self) -> bool {
        coord_digits(self.b) == Some((self.k0, self.k1, self.q0))
    }

    /// A coordinate with explicit digit positions, for any base with a
    /// `u128` range (the tests check the formula on small bases with it;
    /// [`Coord::is_known`] says whether it is its base's coordinate).
    ///
    /// # Errors
    /// A base without a `u128` range, or positions that are not
    /// `k0 <= q0 < k1 <= digits of n`.
    pub fn with_digits(b: u32, k0: u32, k1: u32, q0: u32) -> Result<Self> {
        ensure!((3..=128).contains(&b), "middle-out: base {b} outside 3-128");
        let Some(r) = get_base_range_u128(b)? else {
            bail!("middle-out: base {b} has no range");
        };
        let (start, end) = (r.first(), r.end());
        let l = ndigits(end - 1, b);
        ensure!(
            k0 <= q0 && q0 < k1 && k1 <= l,
            "middle-out: digit positions k0 {k0} <= q0 {q0} < k1 {k1} <= {l} fail at base {b}"
        );
        let bk1 = pow(b, k1);
        let h0 = start / bk1;
        let hn = (end - 1) / bk1 - h0 + 1;
        // v must fit: start + H·b^k1 (checked_mul guards the extreme bases).
        let span = hn.checked_mul(bk1).and_then(|s| s.checked_add(start));
        ensure!(span.is_some(), "middle-out: v overflows u128 at base {b}");
        Ok(Self {
            b,
            start,
            end,
            k0,
            k1,
            q0,
            h0,
            hn,
        })
    }

    /// `b^e`.
    #[must_use]
    pub fn pw(&self, e: u32) -> u128 {
        pow(self.b, e)
    }

    /// One past the last `v`.
    #[must_use]
    pub fn v_end(&self) -> u128 {
        self.start + self.hn * self.pw(self.k1)
    }

    /// The `v` of `n`.
    ///
    /// # Panics
    /// `n` outside the range.
    #[must_use]
    pub fn v_of_n(&self, n: u128) -> u128 {
        assert!(
            n >= self.start && n < self.end,
            "v_of_n: {n} outside the range"
        );
        let (bk0, bk1) = (self.pw(self.k0), self.pw(self.k1));
        let h = n / bk1;
        let key = (n % bk1) / bk0;
        let low = n % bk0;
        self.start + key * (self.hn * bk0) + (h - self.h0) * bk0 + low
    }

    /// The `n` of `v`, or `None` for padding.
    ///
    /// # Panics
    /// `v` outside `[start, v_end)`.
    #[must_use]
    pub fn n_of_v(&self, v: u128) -> Option<u128> {
        assert!(
            v >= self.start && v < self.v_end(),
            "n_of_v: {v} outside the coordinate"
        );
        let (bk0, bk1) = (self.pw(self.k0), self.pw(self.k1));
        let x = v - self.start;
        let key = x / (self.hn * bk0);
        let rest = x % (self.hn * bk0);
        let h = self.h0 + rest / bk0;
        let low = rest % bk0;
        let n = h * bk1 + key * bk0 + low;
        (n >= self.start && n < self.end).then_some(n)
    }

    /// The `v` of one field quantum: every `n` with one value of digits
    /// `[q0, k1)`.
    #[must_use]
    pub fn quantum(&self) -> u128 {
        self.hn * self.pw(self.q0)
    }

    /// The fixed digits of a field: the values `[t0, t1)` its digits
    /// `[q0, k1)` take (as the number `n div b^q0 mod b^(k1 − q0)`).
    ///
    /// # Errors
    /// A field that is empty, outside the coordinate, or not whole quanta.
    pub fn field_digits(&self, v_start: u128, v_size: u128) -> Result<Range<u128>> {
        let q = self.quantum();
        ensure!(v_size > 0, "middle-out field: empty");
        ensure!(
            v_start >= self.start
                && v_start
                    .checked_add(v_size)
                    .is_some_and(|e| e <= self.v_end()),
            "middle-out field [{v_start}, +{v_size}) outside base {}'s coordinate",
            self.b
        );
        ensure!(
            (v_start - self.start).is_multiple_of(q) && v_size.is_multiple_of(q),
            "middle-out field [{v_start}, +{v_size}) at base {} is not whole quanta of {q}",
            self.b
        );
        let t0 = (v_start - self.start) / q;
        Ok(t0..t0 + v_size / q)
    }

    /// How many `n` of the range a field holds (`v_size` less the padding).
    ///
    /// # Errors
    /// As [`Coord::field_digits`].
    pub fn n_count(&self, v_start: u128, v_size: u128) -> Result<u128> {
        let ts = self.field_digits(v_start, v_size)?;
        // For one value t and one h, the n are the block
        // [h·b^k1 + t·b^q0, + b^q0): full for every h but the first and the
        // last, which are clipped to the range.
        let per_t = self.pw(self.q0);
        let mut ends = vec![self.h0];
        if self.hn > 1 {
            ends.push(self.h0 + self.hn - 1);
        }
        let mut total = 0u128;
        for t in ts {
            total += self.hn.saturating_sub(2) * per_t;
            for &h in &ends {
                let lo = h * self.pw(self.k1) + t * per_t;
                let (a, c) = (lo.max(self.start), (lo + per_t).min(self.end));
                if a < c {
                    total += c - a;
                }
            }
        }
        Ok(total)
    }
}

/// `b^e`.
///
/// # Panics
/// On overflow (every caller's exponent is a digit position of an `n` below
/// 2^128, so `b^e` fits).
#[must_use]
pub fn pow(b: u32, e: u32) -> u128 {
    u128::from(b).checked_pow(e).expect("b^e overflows u128")
}

/// Digits of `x` in base `b` (0 for 0).
#[must_use]
pub fn ndigits(mut x: u128, b: u32) -> u32 {
    let mut d = 0;
    while x > 0 {
        x /= u128::from(b);
        d += 1;
    }
    d
}

#[cfg(test)]
mod tests {
    use super::*;

    /// `count` pseudo-random n in `[lo, hi)` (xorshift, fixed seed).
    fn rand_n(lo: u128, hi: u128, count: usize) -> Vec<u128> {
        let mut x = 0x2545_F491_4F6C_DD1D_u64;
        let mut next = || {
            x ^= x << 13;
            x ^= x >> 7;
            x ^= x << 17;
            x
        };
        (0..count)
            .map(|_| {
                let y = u128::from(next()) << 64 | u128::from(next());
                lo + y % (hi - lo)
            })
            .collect()
    }

    /// Base 64's coordinate is the base's, and `v` is the bit permutation of
    /// the module documentation (n's bits 24–47 moved up to bits 51–74), on
    /// random n and both ends of the range.
    #[test]
    fn b64_is_a_bit_permutation() {
        let c = Coord::for_base(64).unwrap();
        assert_eq!((c.k0, c.k1, c.q0), (4, 8, 5));
        assert!(c.is_known());
        assert_eq!(
            (c.start, c.end, c.hn, c.h0),
            (1 << 75, 1 << 76, 1 << 27, 1 << 27)
        );
        assert_eq!(c.v_end(), 1 << 76);
        let mut ns = vec![1u128 << 75, (1u128 << 76) - 1];
        ns.extend(rand_n(1 << 75, 1 << 76, 20_000));
        let mut vs = std::collections::HashSet::new();
        for n in ns {
            let h = n >> 48;
            let key = (n >> 24) & ((1 << 24) - 1);
            let low = n & ((1 << 24) - 1);
            let want = (1u128 << 75) + (key << 51) + ((h - (1 << 27)) << 24) + low;
            assert_eq!(c.v_of_n(n), want);
            assert_eq!(c.n_of_v(want), Some(n));
            vs.insert(want);
        }
        assert!(vs.len() > 19_000);
    }

    /// A base-64 field of one quantum is exactly the n with one value of
    /// digits 5–7; every n lands in the field of its digits 5–7; fields that
    /// are not whole quanta are refused; 262,144 fields of 2^57.
    #[test]
    fn b64_quantum_fixes_digits_5_to_7() {
        let c = Coord::for_base(64).unwrap();
        let q = c.quantum();
        assert_eq!(q, 1 << 57);
        assert_eq!((c.v_end() - c.start) / q, 1 << 18);
        for t in [0u128, 1, 4095, 77_777, (1 << 18) - 1] {
            let vs = c.start + t * q;
            assert_eq!(c.field_digits(vs, q).unwrap(), t..t + 1);
            assert_eq!(c.n_count(vs, q).unwrap(), q);
            for v in [vs, vs + q - 1, vs + q / 3, vs + q / 7 * 5] {
                let n = c.n_of_v(v).unwrap();
                assert_eq!((n >> 30) & ((1 << 18) - 1), t);
            }
        }
        for n in rand_n(1 << 75, 1 << 76, 20_000) {
            let t = (n >> 30) & ((1 << 18) - 1);
            assert_eq!((c.v_of_n(n) - c.start) / q, t);
        }
        assert!(c.field_digits(c.start + 1, q).is_err());
        assert!(c.field_digits(c.start, q / 2).is_err());
        assert!(c.field_digits(c.start, 0).is_err());
        assert!(c.field_digits(c.v_end() - q, 2 * q).is_err());
        let all = c.v_end() - c.start;
        assert_eq!(c.field_digits(c.start, all).unwrap(), 0..1 << 18);
        assert_eq!(c.n_count(c.start, all).unwrap(), c.end - c.start);
        assert_eq!(c.n_count(c.start + 5 * q, 3 * q).unwrap(), 3 * q);
    }

    /// A base-64 field of one quantum is exactly 4,096 whole slices (one
    /// value of digits 4–8 each): every n of a slice, whatever its other
    /// digits, lands in the same field, the one of the slice's digits 5–7.
    #[test]
    fn b64_field_is_4096_whole_slices() {
        let c = Coord::for_base(64).unwrap();
        let q = c.quantum();
        let free = rand_n(0, 1 << 76, 64);
        for t in [0u128, 1, 4095, 77_777, (1 << 18) - 1] {
            let mut slices = std::collections::HashSet::new();
            for d8 in 0..64u128 {
                for d4 in 0..64u128 {
                    let pip = d8 << 24 | t << 6 | d4; // digits 4-8 of n
                    assert!(slices.insert(pip));
                    // n = (digits 9-12) | pip | (digits 0-3), the free parts
                    // random; bit 75 set keeps n in the range
                    let x = free[usize::try_from((d4 + d8) % 64).unwrap()];
                    let hi = (1 << 21) | ((x >> 54) & ((1 << 21) - 1));
                    let n = hi << 54 | pip << 24 | (x & ((1 << 24) - 1));
                    assert_eq!((c.v_of_n(n) - c.start) / q, t, "slice {pip}");
                }
            }
            assert_eq!(slices.len(), 4096);
        }
    }

    /// Exhaustive bijection and field counts on small bases, padded and
    /// not, every b mod 5 class with a range.
    #[test]
    fn small_bases_bijection_and_counts() {
        for (b, k0, k1, q0) in [
            (10u32, 0u32, 1u32, 0u32),
            (12, 0, 2, 1),
            (13, 1, 2, 1),
            (14, 0, 2, 1),
            (17, 1, 3, 2),
            (18, 0, 3, 1),
            (19, 1, 3, 1),
            (20, 1, 3, 2),
            (24, 1, 4, 2),
        ] {
            let c = Coord::with_digits(b, k0, k1, q0).unwrap();
            assert!(!c.is_known());
            let mut seen = vec![false; usize::try_from(c.v_end() - c.start).unwrap()];
            for n in c.start..c.end {
                let v = c.v_of_n(n);
                assert_eq!(c.n_of_v(v), Some(n), "b{b} n {n}");
                let i = usize::try_from(v - c.start).unwrap();
                assert!(!seen[i]);
                seen[i] = true;
            }
            let pad = seen.iter().filter(|&&s| !s).count() as u128;
            assert_eq!(pad + (c.end - c.start), c.v_end() - c.start);
            // per-quantum counts sum to the range; each quantum's n have digits [q0, k1) = t
            let q = c.quantum();
            let nq = (c.v_end() - c.start) / q;
            let mut tot = 0;
            for t in 0..nq {
                let vs = c.start + t * q;
                let cnt = c.n_count(vs, q).unwrap();
                let mut direct = 0;
                for v in vs..vs + q {
                    if let Some(n) = c.n_of_v(v) {
                        assert_eq!((n / c.pw(q0)) % c.pw(k1 - q0), t);
                        direct += 1;
                    }
                }
                assert_eq!(cnt, direct, "b{b} t {t}");
                tot += cnt;
            }
            assert_eq!(tot, c.end - c.start);
        }
    }

    /// A large base that pads (65, the same digit positions as base 64): `v`
    /// fits, the padding is tiny, the counts add up to the range, and each
    /// quantum's n have its fixed digits.
    #[test]
    fn b65_padded() {
        let c = Coord::with_digits(65, 4, 8, 5).unwrap();
        assert!(!c.is_known());
        let span = c.end - c.start;
        let pad = c.v_end() - c.start - span;
        assert!(
            pad > 0 && pad * 1_000_000_000 < span * 2,
            "padding {pad} of {span}"
        );
        let q = c.quantum();
        assert_eq!(q, c.hn * 65u128.pow(5));
        let nq = (c.v_end() - c.start) / q;
        assert_eq!(nq, 65u128.pow(3));
        let mut tot = 0;
        for t in 0..nq {
            tot += c.n_count(c.start + t * q, q).unwrap();
        }
        assert_eq!(tot, span);
        let mut ns = vec![c.start, c.end - 1, c.start + span / 3];
        ns.extend(rand_n(c.start, c.end, 20_000));
        for n in ns {
            let v = c.v_of_n(n);
            assert_eq!(c.n_of_v(v), Some(n));
            let t = (v - c.start) / q;
            assert_eq!((n / c.pw(5)) % c.pw(3), t, "n {n}");
        }
        // the first and last quantum, where the padding is: their v that are n
        for t in [0, nq - 1] {
            let vs = c.start + t * q;
            let n_in = (vs..vs + q)
                .step_by(usize::try_from(q / 4099).unwrap())
                .filter_map(|v| c.n_of_v(v));
            for n in n_in {
                assert_eq!((n / c.pw(5)) % c.pw(3), t);
            }
        }
    }

    /// Only base 64 has a coordinate; digit positions that do not satisfy
    /// `k0 <= q0 < k1 <= digits of n` are refused.
    #[test]
    fn only_base_64_has_a_coordinate() {
        assert_eq!(coord_digits(64), Some((4, 8, 5)));
        for b in [10, 40, 62, 63, 65, 70] {
            assert!(coord_digits(b).is_none());
            assert!(Coord::for_base(b).is_err());
        }
        assert!(!Coord::with_digits(64, 4, 9, 6).unwrap().is_known());
        assert!(Coord::with_digits(64, 5, 8, 4).is_err());
        assert!(Coord::with_digits(64, 4, 8, 8).is_err());
        assert!(Coord::with_digits(64, 4, 14, 5).is_err());
        assert!(Coord::with_digits(2, 0, 1, 0).is_err());
    }
}
