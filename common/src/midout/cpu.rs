//! The CPU reference of the middle-out join: exact, generic over the base
//! (3–128) and the mask word, and slow. It is the definition that a faster
//! search of a field (the device paths, `gpu` and `gpu_wide`) must
//! reproduce number for number and count for count; it is not a client
//! route.
//!
//! Its tests compare it with brute force on every field of eleven small
//! bases (nine of them with survivors): the survivors, the numbers the full
//! check examines, and the nice numbers. Separate tests check the pieces
//! the reference and its brute-force predicate share: the top certificate
//! against its definition, the roots against production's residue filter,
//! and the prefilter at base 64 against full digits.
//!
//! # The join, for one slice
//!
//! The shape `(f0, k)`: a *top* is a prefix `p = n div b^f0`, certified by
//! the digits of `n²` and `n³` at positions `>= k` that are the same for
//! every `n` of its interval; a *bottom* is `r = n mod b^k`, certified by
//! the low `k` digits of `r²` and `r³`. They share the digits `[f0, k)` of
//! `n`. A slice fixes digits `[f0, k − 1)` (the value `pip`) and covers
//! every leading value, every digit `k − 1` (the slice's `b` units) and
//! every low value. Its bottoms are the depth-`(k − 1)` *parents* with
//! digits `[f0, k − 1) = pip`, each with one *child* per unit digit; its
//! tops are the certified prefixes of each unit. A pair (top, child) whose
//! classes mod `b − 1` add up to a root, whose masks are disjoint, and
//! whose `n` lies in the top's interval is a *survivor*; every nice `n` is
//! one. The pairing runs over 64-child chunks of the children sorted by a
//! key of frequent digits, with the chunk's common mask as a skip: the
//! structure a GPU kernel can use, so that its counts of chunks and kept
//! words can be compared with these.
//!
//! # What a field search returns
//!
//! [`search_field`] returns the field's nice numbers and two exact counts
//! that depend only on the shape and the field, not on the order of work or
//! the device ([`FieldOutcome`]):
//!
//! - `survivors`: the `n` of the field that pass the shape's predicate
//!   ([`q_shape`]: `n`'s class mod `b − 1` is a root, its top and bottom are
//!   certified, their masks are disjoint). The same kind of count as
//!   production's `survivors`, for this join's shape (the numbers are not
//!   comparable with the overlap join's).
//! - `checked`: the survivors that also pass the middle-digit prefilter
//!   ([`prefilter`], [`q_checked`]), i.e. the `n` the full check examines:
//!   the same kind of count as production's `checked`.
//!
//! Both are defined by brute-force predicates here, so a search that finds
//! the same nice numbers but examines a different set of `n` is caught by
//! its counts.

// The arithmetic names are single letters, as in the formulas above.
#![allow(clippy::many_single_char_names)]

use super::arith::{U384, roots, unique_digits};
use super::coord::{Coord, ndigits};
use super::mask::Mask;
use anyhow::{Result, ensure};
use std::sync::atomic::{AtomicU64, Ordering};

/// The join's shape. Internal to the join: fields do not depend on it.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Shape {
    pub f0: u32,
    pub k: u32,
}

impl Shape {
    /// The shape the join uses for a coordinate: `(4, 10)` for `(4, 8, 5)`
    /// (at base 64 tops are `n div 64^4`, bottoms `n mod 64^10`, a slice
    /// fixes digits 4–8; the rule below would give `k = 9`); otherwise tops
    /// down to the coordinate's lowest digit `k0` and bottoms of `k1 + 1`
    /// digits, which is `(4, 10)` again for the older `(4, 9, 6)` of bases
    /// 64–70, and the small bases' shapes in the tests.
    #[must_use]
    pub fn for_coord(c: &Coord) -> Self {
        match (c.k0(), c.k1(), c.q0()) {
            (4, 8, 5) => Shape { f0: 4, k: 10 },
            _ => Shape {
                f0: c.k0(),
                k: c.k1() + 1,
            },
        }
    }

    /// Whether a field of `c` is a whole number of this shape's slices: the
    /// field's fixed digits `[q0, k1)` must lie inside the slice's `[f0, k − 1)`.
    ///
    /// # Errors
    /// A shape that cannot search a field of `c` slice by slice.
    pub fn fits(&self, c: &Coord) -> Result<()> {
        let l = ndigits(c.end() - 1, c.b());
        ensure!(
            self.f0 <= c.q0() && c.k1() < self.k && self.k <= l,
            "middle-out: shape (f0 {}, k {}) cannot search fields fixing digits [{}, {}) of {l}-digit n",
            self.f0,
            self.k,
            c.q0(),
            c.k1()
        );
        Ok(())
    }

    /// The slices (`pip` = digits `[f0, k − 1)` of n) of one value `t` of a
    /// field's fixed digits `[q0, k1)`.
    pub fn slices_of(&self, c: &Coord, t: u128) -> impl Iterator<Item = u128> + use<> {
        let b = u128::from(c.b());
        let lo_n = c.q0() - self.f0; // free digits below the fixed ones
        let hi_n = self.k - 1 - c.k1(); // free digits above
        let lo_span = b.pow(lo_n);
        let mid = t * lo_span;
        let hi_mul = b.pow(c.k1() - self.f0);
        let count = lo_span * b.pow(hi_n);
        (0..count).map(move |i| (i / lo_span) * hi_mul + mid + i % lo_span)
    }

    /// A label for telemetry: the counters below are properties of
    /// (shape, field), so audits compare like with like.
    #[must_use]
    pub fn label(&self) -> String {
        format!("midout(f0 {}, k {})", self.f0, self.k)
    }
}

/// A base's constants for the join.
pub struct Base {
    pub b: u32,
    pub start: u128,
    pub end: u128,
    pub l: u32,
    pub pw: Vec<u128>,
    pub roots: Vec<u32>,
}

impl Base {
    /// # Panics
    /// Never for a coordinate (its range has a last element).
    #[must_use]
    pub fn new(c: &Coord) -> Base {
        let mut pw = vec![1u128];
        while pw.len() < 40 {
            let last = *pw.last().unwrap();
            pw.push(last.saturating_mul(u128::from(c.b())));
        }
        Base {
            b: c.b(),
            start: c.start(),
            end: c.end(),
            l: ndigits(c.end() - 1, c.b()),
            pw,
            roots: roots(c.b()),
        }
    }
}

/// `(a·c) mod m` for `a, c < m < 2^96`.
#[inline]
fn mm(a: u128, c: u128, m: u128) -> u128 {
    if m < (1u128 << 63) {
        return (a * c) % m;
    }
    let mut acc: u128 = 0;
    for sh in [64u32, 32, 0] {
        let piece = (c >> sh) & 0xffff_ffff;
        acc = ((acc << 32) % m + (a * piece) % m) % m;
    }
    acc
}

/// Certificate of the top interval `[a, c]`: the digits of `n²` and `n³` at
/// positions `>= kpos` that are the same for every n of it (compared from the
/// top down; a power whose length changes over the interval gives none).
/// `None` if one of them repeats.
#[must_use]
pub fn top_cert<M: Mask>(base: &Base, a: u128, c: u128, kpos: u32) -> Option<M> {
    top_cert_split(base, a, c, kpos, kpos).map(|x| x.0)
}

/// [`top_cert`] at `kpos`, and the part of it at positions `>= kmid`
/// (`kmid >= kpos`): the top's certified digits above the prefilter's.
#[must_use]
pub fn top_cert_split<M: Mask>(
    base: &Base,
    a: u128,
    c: u128,
    kpos: u32,
    kmid: u32,
) -> Option<(M, M)> {
    let b = u64::from(base.b);
    let (xa, xc) = (U384::from_u128(a), U384::from_u128(c));
    let (sa, sc) = (xa.mul(&xa), xc.mul(&xc));
    let (ca, cc) = (sa.mul(&xa), sc.mul(&xc));
    let mut mask = M::default();
    let mut mhi = M::default();
    for (p, q) in [(sa, sc), (ca, cc)] {
        let (dp, dq) = (p.digits(b), q.digits(b));
        if dp.len() != dq.len() {
            continue;
        }
        let mut j = dp.len();
        while j > kpos as usize {
            j -= 1;
            if dp[j] != dq[j] {
                break;
            }
            let bit = M::bit(u32::from(dp[j]));
            if !(mask & bit).is_zero() {
                return None;
            }
            mask |= bit;
            if j >= kmid as usize {
                mhi |= bit;
            }
        }
    }
    Some((mask, mhi))
}

/// The middle-digit prefilter of a survivor `n` of shape `k` (the same rule
/// as production's `cpu_join::CpuJoin::prefilter`, computed independently,
/// at the two positions above the bottom):
/// the digits at positions `k` and `k + 1` of `n²` and `n³` are distinct,
/// miss the bottom's digits (positions `0..k`), and miss `mhi`, the top's
/// certified digits at positions `>= k + 2` (true for every nice n: its
/// certificate's digits are digits of n² and n³ at other positions). The
/// bottom's own `2k` digits are distinct for a survivor, so this is: the
/// `2k + 4` digits at positions `0..k + 2` are distinct and the four new
/// ones miss `mhi`.
///
/// # Panics
/// If `b^(k + 2)` is not below 2^96.
#[must_use]
pub fn prefilter<M: Mask>(base: &Base, k: u32, n: u128, mhi: M) -> bool {
    let m = base.pw[(k + 2) as usize];
    assert!(m < (1u128 << 96), "prefilter: b^(k+2) must be below 2^96");
    let b = u128::from(base.b);
    if n < base.pw[(k + 2).div_ceil(2) as usize] {
        // n² may have no digit at position k + 1: no prefilter (small bases only)
        return true;
    }
    let r = n % m;
    let r2 = mm(r, r, m);
    let r3 = mm(r2, r, m);
    let mut seen = M::default();
    for v in [r2, r3] {
        let mut x = v;
        for j in 0..k + 2 {
            #[allow(clippy::cast_possible_truncation)]
            let bit = M::bit((x % b) as u32);
            x /= b;
            if !(seen & bit).is_zero() || (j >= k && !(mhi & bit).is_zero()) {
                return false;
            }
            seen |= bit;
        }
    }
    true
}

/// Bottom certificate of `r mod b^k` straight from `r²` and `r³` (tests).
#[must_use]
pub fn bot_cert_direct<M: Mask>(base: &Base, r: u128, k: u32) -> Option<M> {
    let x = U384::from_u128(r);
    let s = x.mul(&x);
    let c = s.mul(&x);
    let mut mask = M::default();
    for v in [s, c] {
        let d = v.digits(u64::from(base.b));
        for j in 0..k as usize {
            let bit = M::bit(u32::from(d.get(j).copied().unwrap_or(0)));
            if !(mask & bit).is_zero() {
                return None;
            }
            mask |= bit;
        }
    }
    Some(mask)
}

#[derive(Clone, Copy, Debug)]
pub struct Bot<M> {
    pub r: u128,
    pub mask: M,
}

/// Every certified residue `r mod b^k` whose digits `[f, k)` are `forced`
/// (digits `[0, f)` free): a depth-first walk with `r²`, `r³` mod `b^k`
/// carried incrementally.
///
/// # Panics
/// If `b^k` is not below 2^96.
#[must_use]
pub fn bottoms<M: Mask>(base: &Base, k: u32, f: u32, forced: u128) -> Vec<Bot<M>> {
    let bk = base.pw[k as usize];
    assert!(bk < (1u128 << 96), "bottoms: b^k must be below 2^96");
    let b = u128::from(base.b);
    let mut out = Vec::new();
    let mut stack: Vec<(u32, u128, u128, u128, M)> = vec![(0, 0, 0, 0, M::default())];
    while let Some((j, r, r2, r3, mask)) = stack.pop() {
        if j == k {
            out.push(Bot { r, mask });
            continue;
        }
        let bj = base.pw[j as usize];
        let b2j = if 2 * j < k {
            base.pw[(2 * j) as usize]
        } else {
            0
        };
        let b3j = if 3 * j < k {
            base.pw[(3 * j) as usize]
        } else {
            0
        };
        let (dlo, dhi) = if j < f {
            (0u128, b - 1)
        } else {
            let d = (forced / base.pw[(j - f) as usize]) % b;
            (d, d)
        };
        let two_r = (2 * r) % bk;
        let three_r2 = (3 * r2) % bk;
        let three_r = (3 * r) % bk;
        for d in dlo..=dhi {
            let nr = r + d * bj;
            let nr2 = (r2 + mm((two_r * d) % bk, bj, bk) + mm(d * d % bk, b2j, bk)) % bk;
            let nr3 = (r3
                + mm((three_r2 * d) % bk, bj, bk)
                + mm((three_r * (d * d)) % bk, b2j, bk)
                + mm((d * d * d) % bk, b3j, bk))
                % bk;
            #[allow(clippy::cast_possible_truncation)]
            let (e2, e3) = (((nr2 / bj) % b) as u32, ((nr3 / bj) % b) as u32);
            if e2 == e3 {
                continue;
            }
            let add = M::bit(e2) | M::bit(e3);
            if !(mask & add).is_zero() {
                continue;
            }
            stack.push((j + 1, nr, nr2, nr3, mask | add));
        }
    }
    out
}

/// A certified top of one unit.
#[derive(Clone, Copy, Debug)]
pub struct Top<M> {
    /// `n div b^k`.
    pub h: u128,
    pub mask: M,
    /// The certificate's digits at positions `>= k + 2` (the prefilter's).
    pub mhi: M,
    /// Its interval of n, clipped to the range.
    pub lo: u128,
    pub hi: u128,
}

/// The certified tops of unit `uval` (digits `[f0, k)` of n), leads ascending.
pub fn unit_tops<M: Mask>(base: &Base, sh: Shape, uval: u128, tested: &mut u64) -> Vec<Top<M>> {
    let pw = &base.pw;
    let (f0, k) = (sh.f0, sh.k);
    let lead_lo = base.start / pw[k as usize];
    let lead_hi = (base.end - 1) / pw[k as usize];
    let mut out = Vec::new();
    for lead in lead_lo..=lead_hi {
        let p = lead * pw[(k - f0) as usize] + uval;
        let a = (p * pw[f0 as usize]).max(base.start);
        let c = (p * pw[f0 as usize] + pw[f0 as usize] - 1).min(base.end - 1);
        if a > c {
            continue;
        }
        *tested += 1;
        if let Some((mask, mhi)) = top_cert_split::<M>(base, a, c, k, k + 2) {
            out.push(Top {
                h: lead,
                mask,
                mhi,
                lo: a,
                hi: c,
            });
        }
    }
    out
}

/// A parent of the slice: a depth-`(k − 1)` bottom with its child
/// arithmetic (the next digit of `r²` and `r³` is affine in the child's
/// digit `d`: `(c2 + a2·d, c3 + a3·d) mod b`) and its class `r mod (b − 1)`.
#[derive(Clone, Copy, Debug)]
pub struct Parent<M> {
    pub r: u128,
    pub mask: M,
    pub c2: u32,
    pub c3: u32,
    pub a2: u32,
    pub a3: u32,
    pub cls: u32,
}

/// The slice's parents, `r` ascending.
#[must_use]
pub fn parents<M: Mask>(base: &Base, sh: Shape, pip: u128) -> Vec<Parent<M>> {
    let b = u128::from(base.b);
    let bk = base.pw[sh.k as usize];
    let bj = base.pw[(sh.k - 1) as usize];
    let m = b - 1;
    let mut v: Vec<Parent<M>> = bottoms::<M>(base, sh.k - 1, sh.f0, pip)
        .into_iter()
        .map(|p| {
            let r2 = mm(p.r % bk, p.r % bk, bk);
            let r3 = mm(r2, p.r % bk, bk);
            let r0 = p.r % b;
            #[allow(clippy::cast_possible_truncation)]
            Parent {
                r: p.r,
                mask: p.mask,
                c2: ((r2 / bj) % b) as u32,
                c3: ((r3 / bj) % b) as u32,
                a2: ((2 * r0) % b) as u32,
                a3: ((3 * r0 * r0) % b) as u32,
                cls: (p.r % m) as u32,
            }
        })
        .collect();
    v.sort_by_key(|p| p.r);
    v
}

/// The child of `p` at unit digit `d`, or zero if it is not certified.
#[inline]
#[must_use]
pub fn child_mask<M: Mask>(b: u32, p: &Parent<M>, d: u32) -> M {
    let e2 = (p.c2 + p.a2 * d) % b;
    let e3 = (p.c3 + p.a3 * d) % b;
    let add = M::bit(e2) | M::bit(e3);
    if e2 == e3 || !(p.mask & add).is_zero() {
        return M::default();
    }
    p.mask | add
}

/// The 8 key digits of a slice: parent frequency × top frequency, largest
/// first, ties by digit (the order of the chunk key; a GPU path must use
/// the same rule for its chunk counts to match).
///
/// # Panics
/// Never (digit counts are finite).
#[must_use]
#[allow(clippy::cast_precision_loss)]
pub fn key_digits(b: u32, fp: &[u64], ft: &[u64]) -> Vec<u32> {
    let mut dg: Vec<u32> = (0..b).collect();
    dg.sort_by(|&x, &y| {
        let (x, y) = (x as usize, y as usize);
        (fp[y] as f64 * ft[y] as f64)
            .partial_cmp(&(fp[x] as f64 * ft[x] as f64))
            .unwrap()
            .then(x.cmp(&y))
    });
    dg.truncate(8);
    dg
}

/// Exact, device-independent counts of one slice (or a sum of slices).
/// `survivors` and `checked` are the join's result, and the tests check
/// them against brute force. The rest describe its work and depend on the
/// chunk order (the key) as well as the shape; they are here so that a GPU
/// kernel's counts can be compared with them. **No ordinary test checks
/// them**: only the card-only audits (`gpu::audit`) compare a device's
/// `children`, `chunks` and `flat` with these.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct Counts {
    /// Top prefixes whose certificate was computed (every lead of every unit).
    pub tops_tested: u64,
    /// Of those, the certified ones.
    pub tops: u64,
    /// The slice's parents.
    pub parents: u64,
    /// Certified children, summed over every (class, unit) pair.
    pub children: u64,
    /// 64-child chunks of those children.
    pub chunks: u64,
    /// Children × the tops probed against them: the pair work of a join
    /// without chunks.
    pub pairs: u64,
    /// (chunk, top) probes: each probed top against each chunk.
    pub flat: u64,
    /// Probes that pass the chunk's common-mask skip.
    pub kept: u64,
    /// Kept probes whose word of mask-disjoint children is not zero.
    pub words: u64,
    /// Survivors inside their top's interval: the n of the slice that pass
    /// the shape's predicate ([`q_shape`]).
    pub survivors: u64,
    /// Survivors that pass the middle-digit prefilter ([`prefilter`]): the n
    /// the full check examines.
    pub checked: u64,
    /// Survivor bits outside a clipped top (range ends only).
    pub clipped: u64,
}

impl Counts {
    pub fn add(&mut self, o: &Counts) {
        self.tops_tested += o.tops_tested;
        self.tops += o.tops;
        self.parents += o.parents;
        self.children += o.children;
        self.chunks += o.chunks;
        self.pairs += o.pairs;
        self.flat += o.flat;
        self.kept += o.kept;
        self.words += o.words;
        self.survivors += o.survivors;
        self.checked += o.checked;
        self.clipped += o.clipped;
    }
}

/// One slice through the join; calls `sink(d, n, pass)` for every survivor
/// (unit digit `d`; `pass`: it passes the prefilter). Single-threaded.
#[allow(clippy::too_many_lines)] // one loop nest, kept whole to mirror a kernel
pub fn slice_join<M: Mask>(
    base: &Base,
    sh: Shape,
    pip: u128,
    mut sink: impl FnMut(u32, u128, bool),
) -> Counts {
    let b = base.b as usize;
    let m = b - 1;
    let mut cn = Counts::default();
    let ps = parents::<M>(base, sh, pip);
    cn.parents = ps.len() as u64;
    let step = base.pw[(sh.k - 1 - sh.f0) as usize];
    let mut tops_by_d: Vec<Vec<Top<M>>> = Vec::with_capacity(b);
    for d in 0..b as u128 {
        let t = unit_tops::<M>(base, sh, pip + d * step, &mut cn.tops_tested);
        cn.tops += t.len() as u64;
        tops_by_d.push(t);
    }
    let digit_count = |it: &mut dyn Iterator<Item = M>| -> Vec<u64> {
        let mut f = vec![0u64; b];
        for mut x in it {
            while !x.is_zero() {
                f[x.trailing_zeros() as usize] += 1;
                x = x.clear_lowest();
            }
        }
        f
    };
    let fp = digit_count(&mut ps.iter().map(|p| p.mask));
    let ft = digit_count(&mut tops_by_d.iter().flatten().map(|t| t.mask));
    let rank = key_digits(base.b, &fp, &ft);
    let key = |mk: M| -> u64 {
        let mut kk = 0u64;
        for (i, &v) in rank.iter().enumerate() {
            kk |= u64::from(!(mk & M::bit(v)).is_zero()) << (7 - i);
        }
        kk
    };
    let mut ps = ps;
    ps.sort_by_key(|p| (u64::from(p.cls) << 8) + (255 - key(p.mask)));
    let mut pseg = vec![0usize; m + 1];
    {
        let mut i = 0;
        for (c, seg) in pseg.iter_mut().enumerate().take(m) {
            *seg = i;
            while i < ps.len() && ps[i].cls as usize == c {
                i += 1;
            }
        }
        pseg[m] = ps.len();
    }
    let mut tseg: Vec<Vec<Vec<usize>>> = vec![vec![Vec::new(); m]; b];
    for (d, tv) in tops_by_d.iter().enumerate() {
        for (i, t) in tv.iter().enumerate() {
            tseg[d][(t.h % m as u128) as usize].push(i);
        }
    }
    let bk1 = base.pw[(sh.k - 1) as usize];
    let bkk = base.pw[sh.k as usize];
    let (mut cm, mut cp, mut probes): (Vec<M>, Vec<usize>, Vec<usize>) =
        (Vec::new(), Vec::new(), Vec::new());
    let mut sl = vec![0u64; b];
    for c in 0..m {
        for d in 0..b {
            // a top of class ct pairs with a child of class c + d when ct + c + d is a root
            let cc = (c + d) % m;
            probes.clear();
            for &rt in &base.roots {
                let ct = (rt as usize + m - cc) % m;
                probes.extend_from_slice(&tseg[d][ct]);
            }
            cm.clear();
            cp.clear();
            #[allow(clippy::cast_possible_truncation)]
            for (p, par) in ps.iter().enumerate().take(pseg[c + 1]).skip(pseg[c]) {
                let x = child_mask(base.b, par, d as u32);
                if !x.is_zero() {
                    cm.push(x);
                    cp.push(p);
                }
            }
            cn.children += cm.len() as u64;
            cn.pairs += cm.len() as u64 * probes.len() as u64;
            let nch = cm.len().div_ceil(64);
            cn.chunks += nch as u64;
            let tv = &tops_by_d[d];
            for qi in 0..nch {
                let n0 = qi * 64;
                let n = (cm.len() - n0).min(64);
                sl.fill(0);
                let mut common = !M::default();
                let valid: u64 = if n == 64 { !0 } else { (1u64 << n) - 1 };
                for i in 0..n {
                    let mk = cm[n0 + i];
                    common &= mk;
                    let mut y = mk;
                    while !y.is_zero() {
                        sl[y.trailing_zeros() as usize] |= 1u64 << i;
                        y = y.clear_lowest();
                    }
                }
                cn.flat += probes.len() as u64;
                for &ti in &probes {
                    let tp = &tv[ti];
                    if !(common & tp.mask).is_zero() {
                        continue;
                    }
                    cn.kept += 1;
                    let mut acc = 0u64;
                    let mut y = tp.mask;
                    while !y.is_zero() {
                        acc |= sl[y.trailing_zeros() as usize];
                        y = y.clear_lowest();
                    }
                    let mut w = !acc & valid;
                    if w != 0 {
                        cn.words += 1;
                    }
                    while w != 0 {
                        let i = w.trailing_zeros() as usize;
                        let nn = tp.h * bkk + d as u128 * bk1 + ps[cp[n0 + i]].r;
                        if nn >= tp.lo && nn <= tp.hi {
                            cn.survivors += 1;
                            let pass = prefilter(base, sh.k, nn, tp.mhi);
                            cn.checked += u64::from(pass);
                            #[allow(clippy::cast_possible_truncation)]
                            sink(d as u32, nn, pass);
                        } else {
                            cn.clipped += 1;
                        }
                        w &= w - 1;
                    }
                }
            }
        }
    }
    cn
}

/// The shape's predicate at one n, straight from the definitions (brute
/// force): n's class is a root, its top and bottom are certified, their
/// masks are disjoint.
#[must_use]
pub fn q_shape<M: Mask>(base: &Base, sh: Shape, n: u128) -> bool {
    let m = u128::from(base.b - 1);
    #[allow(clippy::cast_possible_truncation)]
    if !base.roots.contains(&((n % m) as u32)) {
        return false;
    }
    let p = n / base.pw[sh.f0 as usize];
    let a = (p * base.pw[sh.f0 as usize]).max(base.start);
    let c = (p * base.pw[sh.f0 as usize] + base.pw[sh.f0 as usize] - 1).min(base.end - 1);
    let Some(tm) = top_cert::<M>(base, a, c, sh.k) else {
        return false;
    };
    let Some(bm) = bot_cert_direct::<M>(base, n % base.pw[sh.k as usize], sh.k) else {
        return false;
    };
    (tm & bm).is_zero()
}

/// [`q_shape`] and the prefilter, straight from the definitions (brute
/// force): the n the full check examines.
///
/// # Panics
/// Never: a survivor's top is certified.
#[must_use]
pub fn q_checked<M: Mask>(base: &Base, sh: Shape, n: u128) -> bool {
    if !q_shape::<M>(base, sh, n) {
        return false;
    }
    let p = n / base.pw[sh.f0 as usize];
    let a = (p * base.pw[sh.f0 as usize]).max(base.start);
    let c = (p * base.pw[sh.f0 as usize] + base.pw[sh.f0 as usize] - 1).min(base.end - 1);
    let (_, mhi) = top_cert_split::<M>(base, a, c, sh.k, sh.k + 2).expect("a certified top");
    prefilter(base, sh.k, n, mhi)
}

/// What a search of a field returns (see the module documentation).
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct FieldOutcome {
    /// The nice numbers of the field, ascending.
    pub nice: Vec<u128>,
    /// n of the field that pass the join's predicate (the same kind of count
    /// as production's `survivors`, for this shape).
    pub survivors: u64,
    /// n the full check examined: survivors that pass the middle-digit
    /// prefilter, [`prefilter`] (the same kind of count as production's
    /// `checked`).
    pub checked: u64,
    /// Slices searched.
    pub slices: u64,
}

/// Search a field `[v_start, v_start + v_size)` of `coord` with the CPU
/// reference, on `threads` threads (slices in parallel); every survivor
/// that passes the prefilter gets the full check.
///
/// # Errors
/// A field that is not whole quanta, or a shape that cannot search it.
///
/// # Panics
/// If a search thread panics.
pub fn search_field<M: Mask>(
    coord: &Coord,
    sh: Shape,
    v_start: u128,
    v_size: u128,
    threads: usize,
) -> Result<(FieldOutcome, Counts)> {
    ensure!(
        coord.b() <= M::BITS,
        "middle-out CPU: base {} needs wider masks",
        coord.b()
    );
    sh.fits(coord)?;
    let ts = coord.field_digits(v_start, v_size)?;
    let base = Base::new(coord);
    let pips: Vec<u128> = ts
        .flat_map(|t| sh.slices_of(coord, t).collect::<Vec<_>>())
        .collect();
    let next = AtomicU64::new(0);
    let threads = threads.max(1);
    let parts: Vec<(Vec<u128>, u64, Counts)> = std::thread::scope(|s| {
        let hs: Vec<_> = (0..threads)
            .map(|_| {
                s.spawn(|| {
                    let mut nice = Vec::new();
                    let mut checked = 0u64;
                    let mut cn = Counts::default();
                    loop {
                        let i = usize::try_from(next.fetch_add(1, Ordering::Relaxed)).unwrap();
                        if i >= pips.len() {
                            break;
                        }
                        let c = slice_join::<M>(&base, sh, pips[i], |_, n, pass| {
                            if pass {
                                checked += 1;
                                if unique_digits(n, base.b).1 {
                                    nice.push(n);
                                }
                            }
                        });
                        cn.add(&c);
                    }
                    (nice, checked, cn)
                })
            })
            .collect();
        hs.into_iter().map(|h| h.join().unwrap()).collect()
    });
    let mut out = FieldOutcome {
        slices: pips.len() as u64,
        ..Default::default()
    };
    let mut cn = Counts::default();
    for (n, ch, c) in parts {
        out.nice.extend(n);
        out.checked += ch;
        cn.add(&c);
    }
    out.nice.sort_unstable();
    out.survivors = cn.survivors;
    Ok((out, cn))
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashSet;

    /// The prefilter from its definition, on the full digits of `n²` and
    /// `n³` rather than the reference's residues mod `b^(k + 2)`: the digits
    /// at positions `0..k + 2` of both are distinct, and the four at
    /// positions `k` and `k + 1` miss `mhi`. The same exemption for an `n²`
    /// that may be too short ([`prefilter`]).
    fn prefilter_digits(base: &Base, k: u32, n: u128, mhi: u64) -> bool {
        let k = k as usize;
        if n < base.pw[(k + 2).div_ceil(2)] {
            return true;
        }
        let x = U384::from_u128(n);
        let sq = x.mul(&x);
        let cu = sq.mul(&x);
        let mut seen = 0u64;
        for d in [sq.digits(u64::from(base.b)), cu.digits(u64::from(base.b))] {
            for (pos, &dig) in d.iter().take(k + 2).enumerate() {
                let bit = 1u64 << dig;
                if seen & bit != 0 || (pos >= k && mhi & bit != 0) {
                    return false;
                }
                seen |= bit;
            }
        }
        true
    }

    /// [`prefilter_digits`] of a survivor, with its top's `mhi`.
    fn prefilter_direct(base: &Base, sh: Shape, n: u128) -> bool {
        let w = base.pw[sh.f0 as usize];
        let p = n / w;
        let (a, c) = ((p * w).max(base.start), (p * w + w - 1).min(base.end - 1));
        let (_, mhi) = top_cert_split::<u64>(base, a, c, sh.k, sh.k + 2).expect("a certified top");
        prefilter_digits(base, sh.k, n, mhi)
    }

    /// One small base, every field of its coordinate, against brute force:
    /// the survivors are exactly the n passing the shape's predicate, each
    /// once and in its own field; `checked` is the number of them passing
    /// the prefilter (also recomputed from full digits); every nice number
    /// is found. Then the field search itself: the whole base as one field
    /// with `u128` masks, and the first field with `u64` masks, give the
    /// same counts and nice numbers.
    fn check_whole_base(b: u32, (k0, k1, q0): (u32, u32, u32), shapes: &[(u32, u32)]) {
        let coord = Coord::with_digits(b, k0, k1, q0).unwrap();
        let base = Base::new(&coord);
        let (start, end) = (coord.start(), coord.end());
        let q = coord.quantum();
        let nq = (coord.v_end() - start) / q;
        let field_of = |n: u128| (n / coord.pw(q0)) % coord.pw(k1 - q0);
        let nice_brute: Vec<u128> = (start..end).filter(|&n| unique_digits(n, b).1).collect();
        if b == 10 {
            assert_eq!(nice_brute, vec![69]);
        }
        for &(f0, k) in shapes {
            let sh = Shape { f0, k };
            let mut got = HashSet::new();
            let mut nice = Vec::new();
            let (mut checked, mut surv0, mut checked0) = (0u64, 0u64, 0u64);
            for t in 0..nq {
                for pip in sh.slices_of(&coord, t) {
                    slice_join::<u64>(&base, sh, pip, |_, n, pass| {
                        assert_eq!(field_of(n), t, "b{b}: n {n} outside its field");
                        assert!(got.insert(n), "b{b}: n {n} twice");
                        checked += u64::from(pass);
                        if t == 0 {
                            surv0 += 1;
                            checked0 += u64::from(pass);
                        }
                        if pass && unique_digits(n, b).1 {
                            nice.push(n);
                        }
                    });
                }
            }
            let want: HashSet<u128> = (start..end)
                .filter(|&n| q_shape::<u64>(&base, sh, n))
                .collect();
            assert_eq!(got, want, "b{b} {sh:?}: survivors differ from brute force");
            let want_checked = want
                .iter()
                .filter(|&&n| {
                    let qc = q_checked::<u64>(&base, sh, n);
                    assert_eq!(qc, prefilter_direct(&base, sh, n), "b{b} n {n}");
                    qc
                })
                .count() as u64;
            assert_eq!(checked, want_checked, "b{b} {sh:?}: checked");
            nice.sort_unstable();
            assert_eq!(nice, nice_brute, "b{b} {sh:?}: nice numbers");
            let (all, _) =
                search_field::<u128>(&coord, sh, start, coord.v_end() - start, 3).unwrap();
            assert_eq!(
                (all.survivors, all.checked, &all.nice),
                (want.len() as u64, checked, &nice_brute),
                "b{b} {sh:?}: the whole base as one field, u128 masks"
            );
            let (first, _) = search_field::<u64>(&coord, sh, start, q, 2).unwrap();
            let nice0: Vec<u128> = nice_brute
                .iter()
                .copied()
                .filter(|&n| field_of(n) == 0)
                .collect();
            assert_eq!(
                (first.survivors, first.checked, first.nice),
                (surv0, checked0, nice0),
                "b{b} {sh:?}: the first field, u64 masks"
            );
        }
    }

    // Whole small bases: every b mod 5 class with a range (0, 2, 3, 4), odd
    // and even bases, and two shapes on the same fields where it is cheap.
    // (b, coordinate (k0, k1, q0), shapes (f0, k)). Bases 12 and 19 have no
    // survivors in their shapes (nor base 13 in (0, 3)), so they test only
    // that nothing is found; the prefilter is exempt over the whole of bases
    // 10–14.
    #[test]
    fn whole_base_10_vs_brute_force() {
        check_whole_base(10, (0, 1, 0), &[(0, 2)]);
    }
    #[test]
    fn whole_base_12_vs_brute_force() {
        check_whole_base(12, (1, 2, 1), &[(1, 3)]);
    }
    #[test]
    fn whole_base_13_vs_brute_force() {
        check_whole_base(13, (1, 2, 1), &[(1, 3), (0, 3)]);
    }
    #[test]
    fn whole_base_14_vs_brute_force() {
        check_whole_base(14, (1, 2, 1), &[(1, 3)]);
    }
    #[test]
    fn whole_base_17_vs_brute_force() {
        check_whole_base(17, (1, 2, 1), &[(1, 3), (1, 4)]);
    }
    #[test]
    fn whole_base_18_vs_brute_force() {
        check_whole_base(18, (1, 2, 1), &[(1, 3), (1, 4)]);
    }
    #[test]
    fn whole_base_19_vs_brute_force() {
        check_whole_base(19, (1, 2, 1), &[(1, 3), (0, 4)]);
    }
    #[test]
    fn whole_base_20_vs_brute_force() {
        check_whole_base(20, (2, 3, 2), &[(2, 4), (1, 4)]);
    }
    #[test]
    fn whole_base_22_vs_brute_force() {
        check_whole_base(22, (2, 3, 2), &[(2, 4)]);
    }
    #[test]
    fn whole_base_24_vs_brute_force() {
        check_whole_base(24, (1, 3, 2), &[(1, 4), (2, 4)]);
    }
    /// The only 5-digit bottom shape here, and the largest range (6.4 million n).
    #[test]
    fn whole_base_25_vs_brute_force() {
        check_whole_base(25, (2, 4, 3), &[(2, 5)]);
    }

    /// The top certificate against its definition: the digits of `n²` and
    /// `n³`, from the top down to position `k`, that are the same for every
    /// `n` of the interval (each power on its own; one whose length changes
    /// gives none), and the part at positions `>= k + 2`. Shapes with
    /// `f0 = 0` are the ones where, at these bases, the certificate reaches
    /// positions `k` to `k + 2`.
    #[test]
    fn top_certificate_equals_its_definition() {
        let cert_of_every_n = |b: u32, a: u128, c: u128, k: u32| -> Option<(u64, u64)> {
            let (mut mask, mut mhi) = (0u64, 0u64);
            for power in [2, 3] {
                let ds: Vec<Vec<u8>> = (a..=c)
                    .map(|n| {
                        let x = U384::from_u128(n);
                        let sq = x.mul(&x);
                        let pw = if power == 2 { sq } else { sq.mul(&x) };
                        pw.digits(u64::from(b))
                    })
                    .collect();
                let len = ds[0].len();
                if ds.iter().any(|d| d.len() != len) {
                    continue;
                }
                for pos in (k as usize..len).rev() {
                    if ds.iter().any(|d| d[pos] != ds[0][pos]) {
                        break;
                    }
                    let bit = 1u64 << ds[0][pos];
                    if mask & bit != 0 {
                        return None;
                    }
                    mask |= bit;
                    if pos >= k as usize + 2 {
                        mhi |= bit;
                    }
                }
            }
            Some((mask, mhi))
        };
        for (b, f0, k) in [
            (10u32, 0u32, 2u32),
            (13, 0, 3),
            (19, 0, 4),
            (17, 1, 3),
            (20, 2, 4),
            (24, 1, 4),
            (25, 2, 5),
        ] {
            let base = Base::new(&Coord::with_digits(b, 1, 2, 1).unwrap());
            let w = base.pw[f0 as usize];
            let (mut p, mut tested) = (base.start / w, 0);
            while p * w < base.end && tested < 20_000 {
                let (a, c) = ((p * w).max(base.start), (p * w + w - 1).min(base.end - 1));
                assert_eq!(
                    top_cert_split::<u64>(&base, a, c, k, k + 2),
                    cert_of_every_n(b, a, c, k),
                    "b{b} f0 {f0} k {k} prefix {p}"
                );
                p += 1 + p % 7;
                tested += 1;
            }
        }
    }

    /// The residue classes a nice number can be in are production's
    /// (`residue_filter`), for every base the reference serves.
    #[test]
    fn roots_equal_production_residue_filter() {
        for b in 3..=128u32 {
            assert_eq!(
                roots(b),
                crate::residue_filter::get_residue_filter(&b),
                "b{b}"
            );
        }
    }

    /// The prefilter at base 64 and its shape `(4, 10)`, where `b^12 = 2^72`
    /// takes `mm`'s large-modulus branch (no small base reaches it), against
    /// the full digits of `n²` and `n³` on random `n` and random `mhi`.
    #[test]
    fn prefilter_at_base_64_equals_full_digits() {
        let base = Base::new(&Coord::for_base(64).unwrap());
        let mut x = 0x1234_5678_9ABC_DEF1_u64;
        let mut next = || {
            x ^= x << 13;
            x ^= x >> 7;
            x ^= x << 17;
            x
        };
        let mut passed = 0;
        for _ in 0..100_000 {
            let r = (u128::from(next()) << 64 | u128::from(next())) & ((1 << 75) - 1);
            let n = (1u128 << 75) | r;
            let mhi = next() & next() & next();
            let got = prefilter::<u64>(&base, 10, n, mhi);
            assert_eq!(got, prefilter_digits(&base, 10, n, mhi), "n {n}");
            passed += u32::from(got);
        }
        assert!(passed > 100, "{passed} of 100,000 passed: too few to test");
    }

    /// Digit positions `(4, 8, 5)` and the (4, 10) shape: a field of one
    /// quantum is 4,096 (base 64) or 4,225 (base 65, padded) distinct
    /// slices, exactly those whose digits 5–7 are the field's, every n of the
    /// field in one of them; digit 4 varies fastest, so 64 consecutive slices
    /// share digits 5–8.
    #[test]
    fn fields_are_whole_slices_of_the_shape() {
        for (b, per) in [(64u32, 4096usize), (65, 4225)] {
            let c = Coord::with_digits(b, 4, 8, 5).unwrap();
            let sh = Shape::for_coord(&c);
            assert_eq!(sh, Shape { f0: 4, k: 10 });
            assert!(sh.fits(&c).is_ok());
            let bb = u128::from(b);
            let q = c.quantum();
            for t in [0u128, 1, 77_777, bb.pow(3) - 1] {
                let pips: Vec<u128> = sh.slices_of(&c, t).collect();
                assert_eq!(pips.len(), per);
                let set: std::collections::HashSet<u128> = pips.iter().copied().collect();
                assert_eq!(set.len(), per);
                for (i, &p) in pips.iter().enumerate() {
                    assert!(p < bb.pow(5));
                    assert_eq!((p / bb) % bb.pow(3), t, "b{b} t {t} pip {p}");
                    assert_eq!(p % bb, (i % b as usize) as u128, "digit 4 innermost");
                    assert_eq!(p / bb, pips[i - i % b as usize] / bb);
                }
                // every n of the quantum lies in one of its slices (sampled along v)
                let vs = c.start() + t * q;
                for j in 0..5_000u128 {
                    let v = vs + (q / 5_000) * j + j * 7_919 % (q / 5_000);
                    if let Some(n) = c.n_of_v(v) {
                        assert!(set.contains(&((n / bb.pow(4)) % bb.pow(5))), "b{b} n {n}");
                    }
                }
            }
        }
    }

    /// A shape searches a field slice by slice only if the field's fixed
    /// digits lie inside the slice's: at base 64, slices must fix digits 5–7
    /// and stop below the bottoms' top digit.
    #[test]
    fn shapes_that_do_not_fit_are_refused() {
        let c = Coord::for_base(64).unwrap();
        assert!(Shape::for_coord(&c).fits(&c).is_ok());
        assert!(Shape { f0: 3, k: 11 }.fits(&c).is_ok());
        assert!(Shape { f0: 6, k: 10 }.fits(&c).is_err());
        assert!(Shape { f0: 4, k: 8 }.fits(&c).is_err());
        assert!(Shape { f0: 4, k: 14 }.fits(&c).is_err());
    }

    /// A real base-64 slice against a staged reference from an independent
    /// implementation (outside this repository; `tops.bin`, `surv.bin`,
    /// `meta.txt` in `MIDOUT_SU_DIR`): every unit's
    /// survivor set, the tops, and the totals. Set `MIDOUT_SU_DIR`; minutes of
    /// CPU on one thread per unit.
    #[cfg(feature = "midout-box-tests")]
    #[test]
    #[ignore = "needs MIDOUT_SU_DIR (a staged base-64 slice) and minutes of CPU"]
    fn b64_slice_vs_staged() {
        let dir = std::env::var("MIDOUT_SU_DIR").expect("MIDOUT_SU_DIR");
        let meta = std::fs::read_to_string(format!("{dir}/meta.txt")).unwrap();
        let first: Vec<&str> = meta.lines().next().unwrap().split_whitespace().collect();
        let pip: u128 = first[7].parse().unwrap();
        let mut counts = Vec::new();
        for line in meta.lines() {
            let f: Vec<&str> = line.split_whitespace().collect();
            if f[0] == "unit" {
                counts.push(f[13].parse::<usize>().unwrap());
            }
        }
        let raw = std::fs::read(format!("{dir}/surv.bin")).unwrap();
        let coord = Coord::for_base(64).unwrap();
        let base = Base::new(&coord);
        let sh = Shape::for_coord(&coord);
        let mut got: Vec<Vec<u128>> = vec![Vec::new(); 64];
        let cn = slice_join::<u64>(&base, sh, pip, |d, n, _| got[d as usize].push(n));
        let mut off = 0;
        for (d, &c) in counts.iter().enumerate() {
            let mut want: Vec<u128> = raw[off..off + 16 * c]
                .as_chunks::<16>()
                .0
                .iter()
                .map(|x| u128::from_le_bytes(*x))
                .collect();
            want.sort_unstable();
            got[d].sort_unstable();
            assert_eq!(got[d], want, "unit {d}");
            off += 16 * c;
        }
        let tops_bin = std::fs::metadata(format!("{dir}/tops.bin")).unwrap().len();
        assert_eq!(cn.tops * 52, tops_bin);
        println!("b64 slice {pip}: {cn:?}");
    }
}
