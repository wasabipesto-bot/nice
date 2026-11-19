//! The work unit of the middle-out join: a field is a range of a per-base
//! coordinate `v`, and this module is the whole of what a field means.
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
//! with `h0 = start div b^k1` and `H = (end − 1) div b^k1 − h0 + 1`, the
//! number of values `h` takes. `v` moves the digits `[k0, k1)` of `n` above
//! all the others and keeps the rest in their order. It is one to one from
//! the range into `[start, start + H·b^k1)`; the `v` that no `n` of the
//! range maps to (`h` of the first or last value whose `n` falls outside the
//! range) are the *padding*, and [`Coord::n_of_v`] returns `None` for them.
//!
//! - **Base 64** (`k0 = 4`, `k1 = 9`): the range is exactly `[2^75, 2^76)`,
//!   `H = 2^21`, there is no padding, and `v` is `n` with bits 24–53 moved up
//!   to bits 45–74: the renumbering of `G2/PROPOSAL.md` §2,
//!   `v = 2^75 + π′·2^45 + (h − 2^15)·2^30 + d9·2^24 + low` (there `h` is
//!   `n div b^10` and `d9` digit 9; here they are one number `n div b^9`).
//! - **Other bases** (`G2/bases/RESULTS.md` §5): the same formula with
//!   padding. It pads at `b^k1` granularity, a little less than §5's
//!   `b^(k1+1)`, and `v` never needs more bits than `start + H·b^k1`.
//!
//! # What a field fixes
//!
//! A field is `(base, v_start, v_size)`. It must be a whole number of
//! *quanta*: `v_start − start` and `v_size` multiples of [`Coord::quantum`]
//! `= H·b^q0`. One quantum is exactly the set of `n` of the range whose
//! digits `[q0, k1)` take one value `t`, every other digit free; a field is
//! the set of `n` whose digits `[q0, k1)` lie in a range of values
//! `[t0, t1)` ([`Coord::field_digits`]). That set is all a search of the
//! field may rely on: the order of `v` inside a quantum, and the digits
//! `[k0, q0)`, are not part of the contract, so a search may split a field
//! however it likes. At base 64 a field fixes digits 6–8 (quantum `2^57`,
//! 262,144 fields per base).
//!
//! `range_size` of a field (what the server sums) is [`Coord::n_count`],
//! the `n` it holds, not `v_size`; they differ only by padding.
//!
//! Nothing here knows the join's shape: the join checks for itself that its
//! shape can search a field of this coordinate (`join` module).

use crate::base_range::get_base_range_u128;
use anyhow::{Result, bail, ensure};
use std::ops::Range;

/// A base's coordinate (see the module documentation).
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Coord {
    pub b: u32,
    /// The base's range of `n`, `[start, end)`.
    pub start: u128,
    pub end: u128,
    /// The digits `[k0, k1)` that go on top of `v`.
    pub k0: u32,
    pub k1: u32,
    /// A field fixes the digits `[q0, k1)`.
    pub q0: u32,
    /// `h0 = start div b^k1` and the number of values of `h`.
    pub h0: u128,
    pub hn: u128,
}

/// The coordinates fields may be cut in. Only base 64 is defined today;
/// bases 65 and 68–70 are here for the wide device path's measurements
/// (the padded form; no field of them exists or is planned).
#[must_use]
pub fn coord_digits(b: u32) -> Option<(u32, u32, u32)> {
    match b {
        64 | 65 | 68 | 69 | 70 => Some((4, 9, 6)),
        _ => None,
    }
}

impl Coord {
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

    /// A coordinate with explicit digit positions (tests and tools; fields
    /// of a base use [`Coord::for_base`]).
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

    /// How many `n` of the range a field holds (its `range_size`).
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

/// `b^e` (panics on overflow: every caller's exponent is a digit position
/// of an `n` below 2^128).
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

    /// Base 64's v is PROPOSAL §2's bit renumbering, on random n and the ends.
    #[test]
    fn b64_is_the_bit_renumbering() {
        let c = Coord::for_base(64).unwrap();
        assert_eq!((c.start, c.end, c.hn), (1 << 75, 1 << 76, 1 << 21));
        assert_eq!(c.v_end(), 1 << 76);
        assert_eq!(c.quantum(), 1 << 57);
        let mut x = 0x9E37_79B9_7F4A_7C15_u64;
        let mut ns = vec![1u128 << 75, (1u128 << 76) - 1];
        for _ in 0..10_000 {
            x ^= x << 13;
            x ^= x >> 7;
            x ^= x << 17;
            let y = u128::from(x) << 64 | u128::from(x.rotate_left(29));
            ns.push((1 << 75) | (y & ((1 << 75) - 1)));
        }
        for n in ns {
            let h = n >> 60;
            let d9 = (n >> 54) & 63;
            let pi = (n >> 24) & ((1 << 30) - 1);
            let low = n & ((1 << 24) - 1);
            let want = (1u128 << 75) + (pi << 45) + ((h - (1 << 15)) << 30) + (d9 << 24) + low;
            assert_eq!(c.v_of_n(n), want);
            assert_eq!(c.n_of_v(want), Some(n));
        }
    }

    /// A b64 field of one quantum is exactly the n with digits 6–8 fixed.
    #[test]
    fn b64_quantum_fixes_digits_6_to_8() {
        let c = Coord::for_base(64).unwrap();
        let q = c.quantum();
        for t in [0u128, 1, 4095, 77_777, (1 << 18) - 1] {
            let vs = c.start + t * q;
            assert_eq!(c.field_digits(vs, q).unwrap(), t..t + 1);
            assert_eq!(c.n_count(vs, q).unwrap(), q);
            // first, last and a middle v of the quantum all have digits 6-8 = t
            for v in [vs, vs + q - 1, vs + q / 3] {
                let n = c.n_of_v(v).unwrap();
                assert_eq!((n >> 36) & ((1 << 18) - 1), t);
            }
        }
        assert!(c.field_digits(c.start + 1, q).is_err());
        assert!(c.field_digits(c.start, q / 2).is_err());
        assert!(c.field_digits(c.v_end() - q, 2 * q).is_err());
        assert_eq!(
            c.field_digits(c.start, c.v_end() - c.start).unwrap(),
            0..1 << 18
        );
    }

    /// Exhaustive bijection and field counts on small padded bases, every b
    /// mod 5 class with a range.
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

    /// Base 65's padded coordinate: v fits, padding is tiny, counts add up.
    #[test]
    fn b65_padded() {
        let c = Coord::for_base(65).unwrap();
        let w = c.end - c.start;
        let pad = c.v_end() - c.start - w;
        assert!(pad * 1_000_000 < w * 3, "padding {pad} of {w}");
        let q = c.quantum();
        let nq = (c.v_end() - c.start) / q;
        assert_eq!(nq, 65u128.pow(3));
        let mut tot = 0;
        for t in 0..nq {
            tot += c.n_count(c.start + t * q, q).unwrap();
        }
        assert_eq!(tot, w);
        for n in [c.start, c.end - 1, c.start + w / 3] {
            assert_eq!(c.n_of_v(c.v_of_n(n)), Some(n));
        }
    }
}
