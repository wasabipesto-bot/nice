//! G2/bases: one super-unit through the G2 structure, CPU reference, any base <= 128 (u128 masks).
//! Mirrors `bench/g2bench.cu`'s `cpu_block` (the kernel v10 reference): parents of the super-unit
//! (digits [f0, k-1) = pip) sorted per class by an 8-bit probe-weighted key, affine children per unit digit d,
//! 64-chunks with bit slices and a common mask, top-driven probes with the common-mask skip.
//! Tops may be sampled (a pseudo-random fraction q of the leading values of every unit): every top-side count
//! (pairs, flat and kept incidences, nonzero words, survivors) is a sum over tops, so it scales by 1/q.

use crate::join::*;
use std::time::Instant;

pub struct Parent {
    pub r: u128,
    pub mask: Mask,
    pub c2: u32,
    pub c3: u32,
    pub a2: u32,
    pub a3: u32,
    pub cls: u32,
}

/// depth-(k-1) parents of the super-unit pip (digits [f0, k-1) of r = pip), r ascending (the bench's order)
pub fn parents(base: &Base, k: u32, f0: u32, pip: u128, st: &mut BotStats) -> Vec<Parent> {
    let b = base.b as u128;
    let bk = base.pw[k as usize];
    let bj = base.pw[(k - 1) as usize];
    let m = b - 1;
    let mut v: Vec<Parent> = bottoms(base, k - 1, f0, pip, st)
        .into_iter()
        .map(|p| {
            let r2 = mm(p.r % bk, p.r % bk, bk);
            let r3 = mm(r2, p.r % bk, bk);
            let r0 = p.r % b;
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

#[inline]
pub fn child_mask(base: &Base, p: &Parent, d: u32) -> Mask {
    let b = base.b as u32;
    let e2 = (p.c2 + p.a2 * d) % b;
    let e3 = (p.c3 + p.a3 * d) % b;
    let add: Mask = (1 << e2) | (1 << e3);
    if e2 == e3 || (p.mask & add) != 0 {
        return 0;
    }
    p.mask | add
}

/// splitmix-style hash for sampling leads
#[inline]
fn hsh(x: u128, seed: u64) -> u64 {
    let mut z = (x as u64) ^ ((x >> 64) as u64).rotate_left(17) ^ seed.wrapping_mul(0x9E3779B97F4A7C15);
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

/// tops of unit uval (digits [f0, k) = uval), leading values sampled with probability q (q >= 1: all)
pub fn unit_tops(base: &Base, f0: u32, k: u32, uval: u128, q: f64, seed: u64, tested: &mut u64) -> Vec<Top> {
    let pw = &base.pw;
    let lead_lo = base.start / pw[k as usize];
    let lead_hi = (base.end - 1) / pw[k as usize];
    let thr = if q >= 1.0 { u64::MAX } else { (q * u64::MAX as f64) as u64 };
    let mut out = Vec::new();
    for lead in lead_lo..=lead_hi {
        if q < 1.0 && hsh(lead, seed) > thr {
            continue;
        }
        let p = lead * pw[(k - f0) as usize] + uval;
        let a = (p * pw[f0 as usize]).max(base.start);
        let c = (p * pw[f0 as usize] + pw[f0 as usize] - 1).min(base.end - 1);
        if a > c {
            continue;
        }
        *tested += 1;
        if let Some(mask) = top_cert(base, a, c, k) {
            let h = p / pw[(k - f0) as usize];
            out.push(Top { h, mask, lo: a, hi: c });
        }
    }
    out
}

#[derive(Default, Debug, Clone)]
pub struct SuCounts {
    pub roots_f0: u64,   // depth-f0 roots with a valid certificate (the prep's scan, per super-unit)
    pub parents: u64,
    pub tops_tested: u64,
    pub tops: u64,
    pub probes: u64,     // (top, root class) probes
    pub children: u64,
    pub chunks: u64,
    pub pairs: u64,
    pub flat: u64,
    pub kept: u64,
    pub words_nz: u64,   // nonzero 64-pair words = survivor records
    pub surv: u64,       // survivors in range (raw bits minus clipped)
    pub clipped: u64,
    pub pop_kept: u64,   // sum of top popcounts over kept words (slice loads per word)
    pub pop_max: u32,
    pub key_digits: Vec<u32>,
}

/// Run one super-unit. Returns counts and (optionally) the survivor sets per unit digit d.
pub fn run_su(base: &Base, f0: u32, k: u32, pip: u128, q: f64, seed: u64, want_sets: bool,
              timing: bool) -> (SuCounts, Vec<Vec<u128>>, Vec<Vec<Top>>) {
    let b = base.b as usize;
    let m = b - 1;
    let mut cn = SuCounts::default();
    let t0 = Instant::now();
    // roots: depth-f0 residues with a valid certificate (prep cost driver)
    {
        let mut st = BotStats::default();
        cn.roots_f0 = bottoms(base, f0, f0, 0, &mut st).len() as u64;
    }
    let mut bst = BotStats::default();
    let ps = parents(base, k, f0, pip, &mut bst);
    cn.parents = ps.len() as u64;
    // tops of all b units
    let step = base.pw[(k - 1 - f0) as usize];
    let mut tops_by_d: Vec<Vec<Top>> = Vec::with_capacity(b);
    for d in 0..b as u128 {
        let uval = pip + d * step;
        let t = unit_tops(base, f0, k, uval, q, seed ^ (d as u64) << 32, &mut cn.tops_tested);
        cn.tops += t.len() as u64;
        tops_by_d.push(t);
    }
    let t_tops = t0.elapsed().as_secs_f64();
    // digit ranking: parent frequency x pooled top frequency, top 8
    let mut fp = vec![0f64; b];
    let mut ft = vec![0f64; b];
    for p in &ps { for v in 0..b { fp[v] += ((p.mask >> v) & 1) as f64; } }
    for tv in &tops_by_d { for t in tv { for v in 0..b { ft[v] += ((t.mask >> v) & 1) as f64; } } }
    let mut dg: Vec<usize> = (0..b).collect();
    // stable tie-break by digit index ascending (std::sort in the bench is not stable; ties are rare)
    dg.sort_by(|&x, &y| (fp[y] * ft[y]).partial_cmp(&(fp[x] * ft[x])).unwrap().then(x.cmp(&y)));
    let rank: Vec<usize> = dg[..8].to_vec();
    cn.key_digits = rank.iter().map(|&x| x as u32).collect();
    let key8 = |mk: Mask| -> u32 {
        let mut kk = 0u32;
        for (i, &v) in rank.iter().enumerate() { kk |= (((mk >> v) & 1) as u32) << (7 - i); }
        kk
    };
    let mut ps = ps;
    ps.sort_by_key(|p| p.cls * 256 + (255 - key8(p.mask))); // stable
    let mut pseg = vec![0usize; m + 1];
    {
        let mut i = 0;
        for c in 0..m { pseg[c] = i; while i < ps.len() && ps[i].cls as usize == c { i += 1; } }
        pseg[m] = ps.len();
    }
    // tops per (d, ct)
    let mut tseg: Vec<Vec<Vec<usize>>> = vec![vec![Vec::new(); m]; b];
    for (d, tv) in tops_by_d.iter().enumerate() {
        for (i, t) in tv.iter().enumerate() { tseg[d][(t.h % m as u128) as usize].push(i); }
    }
    let bk1 = base.pw[(k - 1) as usize];
    let bkk = base.pw[k as usize];
    let mut sets: Vec<Vec<u128>> = vec![Vec::new(); if want_sets { b } else { 0 }];
    let t1 = Instant::now();
    let mut cm: Vec<Mask> = Vec::new();
    let mut cp: Vec<usize> = Vec::new();
    let mut probes: Vec<usize> = Vec::new();
    for c in 0..m {
        for d in 0..b {
            let cc = (c + d) % m;
            probes.clear();
            for &rt in &base.roots {
                let ct = (rt as usize + m - cc) % m;
                probes.extend_from_slice(&tseg[d][ct]);
            }
            cn.probes += probes.len() as u64;
            cm.clear();
            cp.clear();
            for p in pseg[c]..pseg[c + 1] {
                let x = child_mask(base, &ps[p], d as u32);
                if x != 0 { cm.push(x); cp.push(p); }
            }
            cn.children += cm.len() as u64;
            cn.pairs += cm.len() as u64 * probes.len() as u64;
            let nch = cm.len().div_ceil(64);
            cn.chunks += nch as u64;
            let tv = &tops_by_d[d];
            let mut sl = vec![0u64; b];
            for qi in 0..nch {
                let n0 = qi * 64;
                let n = (cm.len() - n0).min(64);
                for x in sl.iter_mut() { *x = 0; }
                let mut common: Mask = !0;
                let valid: u64 = if n == 64 { !0 } else { (1u64 << n) - 1 };
                for i in 0..n {
                    let mk = cm[n0 + i];
                    common &= mk;
                    let mut y = mk;
                    while y != 0 { sl[y.trailing_zeros() as usize] |= 1u64 << i; y &= y - 1; }
                }
                cn.flat += probes.len() as u64;
                for &ti in &probes {
                    let tp = &tv[ti];
                    let tm = tp.mask;
                    if common & tm != 0 { continue; }
                    cn.kept += 1;
                    let pc = tm.count_ones();
                    cn.pop_kept += pc as u64;
                    cn.pop_max = cn.pop_max.max(pc);
                    let mut acc = 0u64;
                    let mut y = tm;
                    while y != 0 { acc |= sl[y.trailing_zeros() as usize]; y &= y - 1; }
                    let mut w = !acc & valid;
                    if w != 0 { cn.words_nz += 1; }
                    while w != 0 {
                        let i = w.trailing_zeros() as usize;
                        let r = ps[cp[n0 + i]].r + d as u128 * bk1;
                        let nn = tp.h * bkk + r;
                        if nn >= tp.lo && nn <= tp.hi {
                            cn.surv += 1;
                            if want_sets { sets[d].push(nn); }
                        } else {
                            cn.clipped += 1;
                        }
                        w &= w - 1;
                    }
                }
            }
        }
    }
    let t_pair = t1.elapsed().as_secs_f64();
    if timing {
        eprintln!("  su timing: lists {:.1}s pairing {:.1}s", t_tops, t_pair);
    }
    for s in sets.iter_mut() { s.sort(); }
    (cn, sets, tops_by_d)
}
