//! Exact arithmetic for the CPU reference: 384-bit unsigned (6 × u64,
//! little endian), enough for `n³` at every base up to 70 (70^42 < 2^258)
//! and for any `n < 2^128` (`n³ < 2^384`). Ported from the G2 prototype
//! (`G2/bases/proto/src/arith.rs`), which is exact against brute force at
//! bases 10–28 and against an independent join at 62, 64 and 65–70.

pub const NL: usize = 6;

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct U384(pub [u64; NL]);

impl U384 {
    #[must_use]
    pub fn from_u128(x: u128) -> Self {
        let mut a = [0u64; NL];
        #[allow(clippy::cast_possible_truncation)]
        {
            a[0] = x as u64;
            a[1] = (x >> 64) as u64;
        }
        U384(a)
    }

    /// The product; panics if it does not fit 384 bits.
    #[must_use]
    pub fn mul(&self, o: &U384) -> U384 {
        let mut r = [0u64; NL];
        for i in 0..NL {
            if self.0[i] == 0 {
                continue;
            }
            let mut carry: u128 = 0;
            for j in 0..(NL - i) {
                let cur = u128::from(r[i + j]) + u128::from(self.0[i]) * u128::from(o.0[j]) + carry;
                #[allow(clippy::cast_possible_truncation)]
                {
                    r[i + j] = cur as u64;
                }
                carry = cur >> 64;
            }
            assert!(carry == 0 && (NL - i..NL).all(|j| o.0[j] == 0), "U384 overflow");
        }
        U384(r)
    }

    #[must_use]
    pub fn is_zero(&self) -> bool {
        self.0.iter().all(|&w| w == 0)
    }

    /// Divide in place by a small `d`, return the remainder.
    pub fn divrem_small(&mut self, d: u64) -> u64 {
        let mut rem: u128 = 0;
        for i in (0..NL).rev() {
            let cur = (rem << 64) | u128::from(self.0[i]);
            #[allow(clippy::cast_possible_truncation)]
            {
                self.0[i] = (cur / u128::from(d)) as u64;
                rem = cur % u128::from(d);
            }
        }
        #[allow(clippy::cast_possible_truncation)]
        let r = rem as u64;
        r
    }

    /// Base-`b` digits, least significant first (empty for 0).
    #[must_use]
    pub fn digits(&self, b: u64) -> Vec<u8> {
        let mut x = *self;
        let mut v = Vec::with_capacity(48);
        while !x.is_zero() {
            #[allow(clippy::cast_possible_truncation)]
            v.push(x.divrem_small(b) as u8);
        }
        v
    }
}

/// Distinct digits of `n²` and `n³` together, and whether `n` is nice
/// (every digit exactly once).
#[must_use]
pub fn unique_digits(n: u128, b: u32) -> (u32, bool) {
    let x = U384::from_u128(n);
    let sq = x.mul(&x);
    let cu = sq.mul(&x);
    let mut seen = [false; 256];
    let mut tot = 0u32;
    let mut u = 0u32;
    for d in sq.digits(u64::from(b)).into_iter().chain(cu.digits(u64::from(b))) {
        if !seen[d as usize] {
            seen[d as usize] = true;
            u += 1;
        }
        tot += 1;
    }
    (u, u == b && tot == b)
}

/// Residues `r mod (b − 1)` with `r² + r³ ≡ b(b − 1)/2 (mod b − 1)`: the
/// classes a nice number can be in.
#[must_use]
pub fn roots(b: u32) -> Vec<u32> {
    let m = u64::from(b - 1);
    let target = (u64::from(b) * m / 2) % m;
    (0..m)
        .filter(|&r| (r * r % m + r * r % m * r % m) % m == target)
        .map(|r| u32::try_from(r).expect("b < 2^32"))
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn known_nice_and_roots() {
        assert_eq!(unique_digits(69, 10), (10, true));
        assert!(!unique_digits(70, 10).1);
        assert_eq!(roots(64), vec![0, 6, 21, 27, 35, 42, 48, 62]);
    }
}
