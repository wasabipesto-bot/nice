//! N6 experiment (2026-11-13, not for merging): a counting study of the
//! join's top certificates. For sampled production-shaped fields it
//! certifies every (top-layer prefix, partition value) pair the GPU top
//! stage would certify, classifies why the failing ones fail, and counts
//! exactly what candidate grouping / skipping schemes would test instead.
//! Driven by `examples/n6_top_counts.rs`.

use super::{Base, DIGIT_BUF, W4, close_certificate, digit_range_mask};

/// Everything `Base::cert_parts` looks at, without its early exit.
#[derive(Clone, Debug, Default)]
pub struct Detail {
    /// `cert(a, e, cap).is_some()`.
    pub pass: bool,
    /// The closed mask when it passes.
    pub mask: u64,
    /// Common digits per power: (position, digit), lowest position first,
    /// the order `cert_parts` scans them in (n² first, then n³).
    pub common: [Vec<(u32, u8)>; 2],
    /// Lowest common position per power (`sp` if none).
    pub from: [u32; 2],
    /// The d / d + 1 interval below `from`, 0 if none.
    pub dom: [u64; 2],
    /// A digit repeats among the common digits.
    pub dup: bool,
    /// No repeat, but the closure over the doms empties an interval.
    pub closure_fail: bool,
    /// The first repeat in `cert_parts`' scan order: the two occurrences as
    /// (power index 0/1, position).
    pub first_pair: Option<((usize, u32), (usize, u32))>,
}

impl Base {
    /// [`Self::cert_parts`] in full (see [`Detail`]).
    #[allow(clippy::cast_possible_truncation)]
    pub fn n6_detail(&self, a: u128, e: u128, cap: u32) -> Detail {
        let a2 = W4::mul_u128_u128(a, a);
        let e2 = W4::mul_u128_u128(e, e);
        let a3 = a2.mul_u128(a);
        let e3 = e2.mul_u128(e);
        let top = (self.b - 1) as u8;
        let mut det = Detail {
            from: [self.s2, self.s3],
            ..Detail::default()
        };
        let mut dx = [0u8; DIGIT_BUF];
        let mut seen: [Option<(usize, u32)>; 64] = [None; 64];
        let mut mask = 0u64;
        for (pi, (x, y, sp)) in [(a2, e2, self.s2), (a3, e3, self.s3)].into_iter().enumerate() {
            let d = y.sub(&x);
            let c0 = cap.max(self.ndig_w(&d));
            if c0 >= sp {
                continue;
            }
            let (qx, rem) = self.shift_down_rem(x, c0);
            let one_more = !rem.add(&d).lt(&self.poww[c0 as usize]);
            self.digits_w(qx, sp - c0, &mut dx);
            let mut run = 0usize;
            if one_more {
                while dx[run] == top {
                    run += 1;
                }
                det.dom[pi] = digit_range_mask(dx[run], dx[run] + 1);
                run += 1;
            }
            det.from[pi] = c0 + run as u32;
            for (idx, &digit) in dx[run..(sp - c0) as usize].iter().enumerate() {
                let pos = c0 + (run + idx) as u32;
                det.common[pi].push((pos, digit));
                let bit = 1u64 << digit;
                if mask & bit != 0 {
                    if !det.dup {
                        det.first_pair = Some((seen[digit as usize].expect("seen"), (pi, pos)));
                    }
                    det.dup = true;
                } else {
                    seen[digit as usize] = Some((pi, pos));
                }
                mask |= bit;
            }
        }
        if det.dup {
            return det;
        }
        match close_certificate(mask, det.dom) {
            Some(m) => {
                det.pass = true;
                det.mask = m;
            }
            None => det.closure_fail = true,
        }
        det
    }

    /// `x^j` (j = 2 or 3) as words.
    pub fn n6_pow(x: u128, j: usize) -> W4 {
        let x2 = W4::mul_u128_u128(x, x);
        if j == 0 { x2 } else { x2.mul_u128(x) }
    }

    /// floor(x / b^i) + 1, times b^i: the first value of the power at which
    /// digit `i` (and everything above it) changes from `x`'s.
    pub fn n6_next_boundary(&self, x: W4, i: u32) -> W4 {
        let (q, _) = self.shift_down_rem(x, i);
        let one = W4([1, 0, 0, 0]);
        let q1 = q.add(&one);
        // q1 · b^i: multiply the 256-bit power by q1 (q1 < 2^128 here).
        self.poww[i as usize].mul_u128(q1.to_u128())
    }
}

/// splitmix64.
pub fn next_u64(x: &mut u64) -> u64 {
    *x = x.wrapping_add(0x9E37_79B9_7F4A_7C15);
    let mut z = *x;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58_476D_1CE4_E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D0_49BB_1331_11EB);
    z ^ (z >> 31)
}

/// A uniform value below `n` (n < 2^64 is enough here; u128 by two draws).
pub fn below(x: &mut u64, n: u128) -> u128 {
    let r = (u128::from(next_u64(x)) << 64) | u128::from(next_u64(x));
    r % n
}
