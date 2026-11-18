//! Exact certificates and a keyed overlap join restricted to one "transversal unit":
//! the set of n in the base range whose digits [lo_fix, hi_fix) equal a fixed value.
//! Both the G2 shape and the reference shape (today's f0 3, k 6) are run on the same set.

use crate::arith::*;

/// Digit mask: one bit per digit. u128 since G2/bases (was u64, b <= 64); b <= 128.
pub type Mask = u128;

pub struct Base {
    pub b: u64,
    pub start: u128,
    pub end: u128, // exclusive
    pub l: u32,    // digits of n
    pub pw: Vec<u128>,
    pub roots: Vec<u64>,
}

impl Base {
    pub fn new(b: u64) -> Base {
        let (start, end) = base_range(b).expect("no range");
        let mut pw = vec![1u128];
        while pw.len() < 25 {
            let last = *pw.last().unwrap();
            pw.push(last.saturating_mul(b as u128));
        }
        let mut l = 0;
        while pw[l as usize] <= end - 1 {
            l += 1;
        }
        Base { b, start, end, l, pw, roots: roots(b) }
    }
    pub fn digit(&self, n: u128, j: u32) -> u64 {
        ((n / self.pw[j as usize]) % self.b as u128) as u64
    }
}

/// Certificate of the top interval [a, c] (inclusive): digits of n^2 and n^3 constant over it,
/// at positions >= kpos. None if a digit repeats.
pub fn top_cert(base: &Base, a: u128, c: u128, kpos: u32) -> Option<Mask> {
    let b = base.b;
    let xa = U256::from_u128(a);
    let xc = U256::from_u128(c);
    let (sa, sc) = (xa.mul(&xa), xc.mul(&xc));
    let (ca, cc) = (sa.mul(&xa), sc.mul(&xc));
    let mut mask: Mask = 0;
    for (p, q) in [(sa, sc), (ca, cc)] {
        let dp = p.digits(b);
        let dq = q.digits(b);
        if dp.len() != dq.len() {
            continue;
        }
        let mut j = dp.len();
        while j > kpos as usize {
            j -= 1;
            if dp[j] != dq[j] {
                break;
            }
            let bit: Mask = 1 << dp[j];
            if mask & bit != 0 {
                return None;
            }
            mask |= bit;
        }
    }
    Some(mask)
}

/// Bottom certificate of residue r mod b^k computed directly (for checks).
pub fn bot_cert_direct(base: &Base, r: u128, k: u32) -> Option<Mask> {
    let x = U256::from_u128(r);
    let s = x.mul(&x);
    let c = s.mul(&x);
    let mut mask: Mask = 0;
    for v in [s, c] {
        let d = v.digits(base.b);
        for j in 0..k as usize {
            let dig = if j < d.len() { d[j] } else { 0 };
            let bit: Mask = 1 << dig;
            if mask & bit != 0 {
                return None;
            }
            mask |= bit;
        }
    }
    Some(mask)
}

#[derive(Clone, Copy, Debug)]
pub struct Bot {
    pub r: u128,
    pub mask: Mask,
}

#[derive(Default, Debug, Clone)]
pub struct BotStats {
    pub visits: u64,
    pub nodes: u64,
}

/// (a * c) mod m for a, c < m < 2^96 (G2/bases: b^k may exceed 2^62 at k 11 above b 64).
#[inline]
pub fn mm(a: u128, c: u128, m: u128) -> u128 {
    if m < (1u128 << 63) {
        return (a * c) % m;
    }
    debug_assert!(a < m && c < m && m < (1u128 << 96));
    // c in 32-bit pieces from the top: acc = (acc * 2^32 + a * piece) mod m; acc, a < 2^96 -> fits
    let mut acc: u128 = 0;
    for sh in [64u32, 32, 0] {
        let piece = (c >> sh) & 0xffff_ffff;
        acc = ((acc << 32) % m + (a * piece) % m) % m;
    }
    acc
}

/// All certified residues r mod b^k whose digits [f, k) equal `forced` (value of k-f digits),
/// digits [0, f) free. DFS with incremental r^2, r^3 mod b^k (b^k < 2^96 since G2/bases).
pub fn bottoms(base: &Base, k: u32, f: u32, forced: u128, st: &mut BotStats) -> Vec<Bot> {
    let bk = base.pw[k as usize];
    assert!(bk < (1u128 << 96));
    let b = base.b as u128;
    let mut out = Vec::new();
    // stack: (depth j, r, r2, r3, mask)
    let mut stack: Vec<(u32, u128, u128, u128, Mask)> = vec![(0, 0, 0, 0, 0)];
    while let Some((j, r, r2, r3, mask)) = stack.pop() {
        if j == k {
            out.push(Bot { r, mask });
            continue;
        }
        let bj = base.pw[j as usize];
        let b2j = if 2 * j < k { base.pw[(2 * j) as usize] } else { 0 };
        let b3j = if 3 * j < k { base.pw[(3 * j) as usize] } else { 0 };
        let (dlo, dhi) = if j < f {
            (0u128, b - 1)
        } else {
            let d = (forced / base.pw[(j - f) as usize]) % b;
            (d, d)
        };
        // terms independent of d
        let two_r = (2 * r) % bk; // r < b^j
        let three_r2 = (3 * r2) % bk;
        let three_r = (3 * r) % bk;
        for d in dlo..=dhi {
            st.visits += 1;
            let nr = r + d * bj;
            // (r + d b^j)^2 = r2 + 2 d r b^j + d^2 b^2j
            let t1 = mm((two_r * d) % bk, bj, bk);
            let t2 = mm(d * d % bk, b2j, bk);
            let nr2 = (r2 + t1 + t2) % bk;
            // (r + d b^j)^3 = r3 + 3 d r^2 b^j + 3 d^2 r b^2j + d^3 b^3j
            let u1 = mm((three_r2 * d) % bk, bj, bk);
            let u2 = mm((three_r * (d * d)) % bk, b2j, bk);
            let u3 = mm((d * d * d) % bk, b3j, bk);
            let nr3 = (r3 + u1 + u2 + u3) % bk;
            let e2 = ((nr2 / bj) % b) as u64;
            let e3 = ((nr3 / bj) % b) as u64;
            if e2 == e3 {
                continue;
            }
            let add: Mask = (1 << e2) | (1 << e3);
            if mask & add != 0 {
                continue;
            }
            st.nodes += 1;
            stack.push((j + 1, nr, nr2, nr3, mask | add));
        }
    }
    out
}

#[derive(Clone, Copy, Debug)]
pub struct Top {
    pub h: u128, // digits of n at positions >= kpos (the value n div b^k)
    pub mask: Mask,
    pub lo: u128, // interval of n (clipped)
    pub hi: u128,
}

pub struct Shape {
    pub fr: u32, // f0: lowest top digit
    pub kr: u32, // k: bottom depth
}

#[derive(Default, Debug, Clone)]
pub struct JoinStats {
    pub top_tested: u64,
    pub top_cert: u64,
    pub bot: BotStats,
    pub bot_cert: u64,
    pub pairs: u64,
    pub survivors: u64,
    pub max_unique: u32,
    pub nice: Vec<u128>,
}

pub struct UnitLists {
    pub tops: Vec<(u64 /*key*/, Top)>,
    pub bots: Vec<Bot>,
}

/// Build the lists for shape s on the unit {n : digits [u0, u1) == uval}; fr <= u0 <= kr <= u1.
pub fn unit_lists(base: &Base, s: &Shape, u0: u32, u1: u32, uval: u128, st: &mut JoinStats) -> UnitLists {
    assert!(s.fr <= u0 && u0 <= s.kr && s.kr <= u1 && u1 <= base.l);
    let pw = &base.pw;
    let g = u0 - s.fr;
    let lead_lo = base.start / pw[u1 as usize];
    let lead_hi = (base.end - 1) / pw[u1 as usize];
    let mut tops = Vec::new();
    for lead in lead_lo..=lead_hi {
        for kv in 0..pw[g as usize] {
            let p = lead * pw[(u1 - s.fr) as usize] + uval * pw[(u0 - s.fr) as usize] + kv;
            let a = (p * pw[s.fr as usize]).max(base.start);
            let c = (p * pw[s.fr as usize] + pw[s.fr as usize] - 1).min(base.end - 1);
            if a > c {
                continue;
            }
            st.top_tested += 1;
            if let Some(mask) = top_cert(base, a, c, s.kr) {
                st.top_cert += 1;
                let h = p / pw[(s.kr - s.fr) as usize];
                tops.push((kv as u64, Top { h, mask, lo: a, hi: c }));
            }
        }
    }
    let forced = uval % pw[(s.kr - u0) as usize];
    let bots = bottoms(base, s.kr, u0, forced, &mut st.bot);
    st.bot_cert += bots.len() as u64;
    UnitLists { tops, bots }
}

/// Plain keyed join (scalar AND); returns survivors (n).
pub fn join_scalar(base: &Base, s: &Shape, u0: u32, lists: &UnitLists, st: &mut JoinStats) -> Vec<u128> {
    let mut out = Vec::new();
    join_cb(base, s, u0, lists, st, |n| out.push(n));
    st.survivors += out.len() as u64;
    for &n in &out {
        let (u, nice) = unique_digits(n, base.b);
        st.max_unique = st.max_unique.max(u);
        if nice {
            st.nice.push(n);
        }
    }
    out
}

pub fn join_cb(base: &Base, s: &Shape, u0: u32, lists: &UnitLists, st: &mut JoinStats, mut f: impl FnMut(u128)) {
    let m = base.b - 1;
    let g = u0 - s.fr;
    let nkeys = base.pw[g as usize] as usize;
    let mut buckets: Vec<Vec<Bot>> = vec![Vec::new(); nkeys * m as usize];
    for bt in &lists.bots {
        let key = ((bt.r / base.pw[s.fr as usize]) % base.pw[g as usize]) as usize;
        let cls = (bt.r % m as u128) as usize;
        buckets[key * m as usize + cls].push(*bt);
    }
    for (kv, tp) in &lists.tops {
        let ct = (tp.h % m as u128) as u64;
        for &rt in &base.roots {
            let cb = ((rt + m - ct) % m) as usize;
            let bucket = &buckets[*kv as usize * m as usize + cb];
            st.pairs += bucket.len() as u64;
            for bt in bucket {
                if tp.mask & bt.mask == 0 {
                    let n = tp.h * base.pw[s.kr as usize] + bt.r;
                    if n >= tp.lo && n <= tp.hi {
                        f(n);
                    }
                }
            }
        }
    }
}

/// Direct predicate for shape s at a single n (used by brute force and cross-checks).
pub fn q_shape(base: &Base, s: &Shape, n: u128) -> bool {
    let m = base.b - 1;
    if !base.roots.contains(&((n % m as u128) as u64)) {
        return false;
    }
    let p = n / base.pw[s.fr as usize];
    let a = (p * base.pw[s.fr as usize]).max(base.start);
    let c = (p * base.pw[s.fr as usize] + base.pw[s.fr as usize] - 1).min(base.end - 1);
    let Some(tm) = top_cert(base, a, c, s.kr) else { return false };
    let Some(bm) = bot_cert_direct(base, n % base.pw[s.kr as usize], s.kr) else { return false };
    tm & bm == 0
}
