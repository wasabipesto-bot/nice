//! Minimal exact arithmetic: 256-bit unsigned (4 x u64, little endian), enough for n^3 at b <= 64.

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct U256(pub [u64; 4]);

impl U256 {
    pub fn from_u128(x: u128) -> Self {
        U256([x as u64, (x >> 64) as u64, 0, 0])
    }
    pub fn mul(&self, o: &U256) -> U256 {
        let mut r = [0u64; 4];
        for i in 0..4 {
            let mut carry: u128 = 0;
            if self.0[i] == 0 {
                continue;
            }
            for j in 0..(4 - i) {
                let cur = r[i + j] as u128 + (self.0[i] as u128) * (o.0[j] as u128) + carry;
                r[i + j] = cur as u64;
                carry = cur >> 64;
            }
        }
        U256(r)
    }
    pub fn mul_u128(&self, x: u128) -> U256 {
        self.mul(&U256::from_u128(x))
    }
    pub fn is_zero(&self) -> bool {
        self.0.iter().all(|&w| w == 0)
    }
    /// divide in place by small d, return remainder
    pub fn divrem_small(&mut self, d: u64) -> u64 {
        let mut rem: u128 = 0;
        for i in (0..4).rev() {
            let cur = (rem << 64) | self.0[i] as u128;
            self.0[i] = (cur / d as u128) as u64;
            rem = cur % d as u128;
        }
        rem as u64
    }
    pub fn cmp(&self, o: &U256) -> std::cmp::Ordering {
        for i in (0..4).rev() {
            if self.0[i] != o.0[i] {
                return self.0[i].cmp(&o.0[i]);
            }
        }
        std::cmp::Ordering::Equal
    }
    /// base-b digits, least significant first (no leading zeros; empty for 0)
    pub fn digits(&self, b: u64) -> Vec<u8> {
        let mut x = *self;
        let mut v = Vec::with_capacity(48);
        while !x.is_zero() {
            v.push(x.divrem_small(b) as u8);
        }
        v
    }
}

pub fn pow256(b: u64, e: u32) -> U256 {
    let mut r = U256::from_u128(1);
    for _ in 0..e {
        r = r.mul_u128(b as u128);
    }
    r
}

/// Base range [start, end) exactly as common/src/base_range.rs.
pub fn base_range(b: u64) -> Option<(u128, u128)> {
    let k = (b / 5) as u32;
    // ceiling root: smallest x with x^r >= v
    let ceil_root = |v: U256, r: u32| -> u128 {
        let (mut lo, mut hi) = (0u128, if r == 2 { 1u128 << 120 } else { 1u128 << 84 });
        while lo < hi {
            let mid = lo + (hi - lo) / 2;
            let m = U256::from_u128(mid);
            let mut p = m;
            for _ in 1..r {
                p = p.mul(&m);
            }
            if p.cmp(&v) != std::cmp::Ordering::Less {
                hi = mid;
            } else {
                lo = mid + 1;
            }
        }
        lo
    };
    let p = |e: u32| pow256(b, e);
    let as128 = |x: U256| -> u128 { (x.0[0] as u128) | ((x.0[1] as u128) << 64) };
    match b % 5 {
        0 => Some((ceil_root(p(3 * k - 1), 3), as128(p(k)))),
        2 => Some((as128(p(k)), ceil_root(p(3 * k + 1), 3))),
        3 => Some((ceil_root(p(3 * k + 1), 3), ceil_root(p(2 * k + 1), 2))),
        4 => Some((ceil_root(p(2 * k + 1), 2), ceil_root(p(3 * k + 2), 3))),
        _ => None,
    }
}

/// residue classes r mod (b-1) with r^2 + r^3 == b(b-1)/2 mod (b-1)
pub fn roots(b: u64) -> Vec<u64> {
    let m = b - 1;
    let target = (b * (b - 1) / 2) % m;
    (0..m).filter(|&r| (r * r % m + r * r % m * r % m) % m == target).collect()
}

/// number of distinct digits of n^2 and n^3 together, and whether n is nice
pub fn unique_digits(n: u128, b: u64) -> (u32, bool) {
    let x = U256::from_u128(n);
    let sq = x.mul(&x);
    let cu = sq.mul(&x);
    let mut seen = 0u64;
    let mut tot = 0;
    for d in sq.digits(b).into_iter().chain(cu.digits(b)) {
        seen |= 1u64 << d;
        tot += 1;
    }
    let u = seen.count_ones();
    (u, u as u64 == b && tot == b)
}
