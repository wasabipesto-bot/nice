//! G2 pipeline on one unit, CPU-timed: shared depth-(k-1) parents -> affine children for the unit's
//! top shared digit -> class groups of bottoms in clustered chunks (bit slices + common masks) ->
//! top-driven probes. Must reproduce join_scalar's survivor count exactly.

use crate::join::*;
use std::time::Instant;

pub struct Parent { pub r: u128, pub mask: u64, pub c2: u8, pub c3: u8, pub a2: u8, pub a3: u8 }

pub fn parents(base: &Base, k: u32, f0: u32, pi_low: u128, st: &mut BotStats) -> Vec<Parent> {
    let b = base.b as u128;
    let bk = base.pw[k as usize];
    let bj = base.pw[(k - 1) as usize];
    bottoms(base, k - 1, f0, pi_low, st)
        .into_iter()
        .map(|p| {
            let r2 = (p.r * p.r) % bk;
            let r3 = (r2 * p.r) % bk;
            let r0 = p.r % b;
            Parent {
                r: p.r,
                mask: p.mask,
                c2: ((r2 / bj) % b) as u8,
                c3: ((r3 / bj) % b) as u8,
                a2: ((2 * r0) % b) as u8,
                a3: ((3 * r0 * r0) % b) as u8,
            }
        })
        .collect()
}

pub struct Chunked {
    pub slices: Vec<[u64; 64]>,
    pub common: Vec<u64>,
    pub valid: Vec<u64>,
    pub rs: Vec<Vec<u128>>,
}

pub fn run(base: &Base, f0: u32, k: u32, uval: u128, tops: &[(u64, Top)], ref_surv: u64, adm: f64, cluster: bool) {
    let b = base.b;
    let m = (b - 1) as usize;
    let o = k - f0;
    let d = (uval / base.pw[(o - 1) as usize]) as u64; // top shared digit (position k-1)
    let pi_low = uval % base.pw[(o - 1) as usize];
    let mut st = BotStats::default();
    let t0 = Instant::now();
    let ps = parents(base, k, f0, pi_low, &mut st);
    let t_par = t0.elapsed().as_secs_f64();
    // children (one per parent for this unit's digit d)
    let t1 = Instant::now();
    let bj = base.pw[(k - 1) as usize];
    let mut groups: Vec<Vec<(u64, u128)>> = vec![Vec::new(); m];
    let mut nchild = 0u64;
    for p in &ps {
        let e2 = ((p.c2 as u64 + p.a2 as u64 * d) % b) as u32;
        let e3 = ((p.c3 as u64 + p.a3 as u64 * d) % b) as u32;
        if e2 == e3 {
            continue;
        }
        let add = (1u64 << e2) | (1u64 << e3);
        if p.mask & add != 0 {
            continue;
        }
        let r = p.r + d as u128 * bj;
        groups[(r % m as u128) as usize].push((p.mask | add, r));
        nchild += 1;
    }
    let t_child = t1.elapsed().as_secs_f64();
    // cluster + chunk + slice
    let t2 = Instant::now();
    let mut ch: Vec<Chunked> = Vec::with_capacity(m);
    for g in groups.iter_mut() {
        if cluster {
            let mut freq = [0u32; 64];
            for x in g.iter() {
                let mut y = x.0;
                while y != 0 { freq[y.trailing_zeros() as usize] += 1; y &= y - 1; }
            }
            let mut ord: Vec<u8> = (0..64).collect();
            ord.sort_by(|a, c| freq[*c as usize].cmp(&freq[*a as usize]));
            let mut perm = [0u8; 64];
            for (i, &dd) in ord.iter().enumerate() { perm[dd as usize] = 63 - i as u8; }
            g.sort_unstable_by_key(|x| {
                let mut kk = 0u64; let mut y = x.0;
                while y != 0 { let dd = y.trailing_zeros() as usize; kk |= 1u64 << perm[dd]; y &= y - 1; }
                std::cmp::Reverse(kk)
            });
        }
        let nch = g.len().div_ceil(64);
        let mut c = Chunked { slices: vec![[0u64; 64]; nch], common: vec![!0u64; nch], valid: vec![0; nch], rs: vec![Vec::new(); nch] };
        for (i, &(mk, r)) in g.iter().enumerate() {
            let q = i / 64;
            c.common[q] &= mk;
            c.valid[q] |= 1u64 << (i % 64);
            c.rs[q].push(r);
            let mut y = mk;
            while y != 0 { c.slices[q][y.trailing_zeros() as usize] |= 1u64 << (i % 64); y &= y - 1; }
        }
        ch.push(c);
    }
    let t_chunk = t2.elapsed().as_secs_f64();
    // probes
    let t3 = Instant::now();
    let (mut inc, mut kept, mut surv) = (0u64, 0u64, 0u64);
    let mut out: Vec<u128> = Vec::new();
    for (_, tp) in tops {
        let ct = (tp.h % m as u128) as u64;
        for &rt in &base.roots {
            let cb = ((rt + m as u64 - ct) % m as u64) as usize;
            let c = &ch[cb];
            for q in 0..c.common.len() {
                inc += 1;
                if c.common[q] & tp.mask != 0 { continue; }
                kept += 1;
                let mut acc = 0u64;
                let mut y = tp.mask;
                while y != 0 { acc |= c.slices[q][y.trailing_zeros() as usize]; y &= y - 1; }
                let mut s = !acc & c.valid[q];
                while s != 0 {
                    let i = s.trailing_zeros() as usize;
                    let n = tp.h * base.pw[k as usize] + c.rs[q][i];
                    if n >= tp.lo && n <= tp.hi { surv += 1; out.push(n); }
                    s &= s - 1;
                }
            }
        }
    }
    let t_probe = t3.elapsed().as_secs_f64();
    if let Ok(p) = std::env::var("G2_PIPEDUMP") {
        let mut v = out.clone(); v.sort();
        std::fs::write(format!("{p}.{uval}.{cluster}"), v.iter().map(|n| format!("{n}\n")).collect::<String>()).unwrap();
    }
    // four-Russians variant: tables built per chunk (timed), then 8 lookups per kept incidence
    let t5 = Instant::now();
    let mut tabs: Vec<Vec<[[u64; 256]; 8]>> = Vec::with_capacity(m);
    for c in &ch {
        let mut tv = vec![[[0u64; 256]; 8]; c.slices.len()];
        for (q, sl) in c.slices.iter().enumerate() {
            for j in 0..8 {
                for x in 1..256usize {
                    tv[q][j][x] = tv[q][j][x & (x - 1)] | sl[8 * j + x.trailing_zeros() as usize];
                }
            }
        }
        tabs.push(tv);
    }
    let t_tab = t5.elapsed().as_secs_f64();
    // tile order: per class group, per chunk (table hot in L1), all tops probing that group
    let mut probing: Vec<Vec<(u64, [u8; 8], u128, u128, u128)>> = vec![Vec::new(); m];
    for (_, tp) in tops {
        let ct = (tp.h % m as u128) as u64;
        for &rt in &base.roots {
            let cb = ((rt + m as u64 - ct) % m as u64) as usize;
            probing[cb].push((tp.mask, tp.mask.to_le_bytes(), tp.h, tp.lo, tp.hi));
        }
    }
    let t6 = Instant::now();
    let mut surv4 = 0u64;
    for cb in 0..m {
        let c = &ch[cb];
        for q in 0..c.common.len() {
            let tb = &tabs[cb][q];
            let cm = c.common[q];
            for &(tm, bytes, h, lo, hi) in &probing[cb] {
                if cm & tm != 0 { continue; }
                let mut acc = 0u64;
                for j in 0..8 { acc |= tb[j][bytes[j] as usize]; }
                let mut s = !acc & c.valid[q];
                while s != 0 {
                    let i = s.trailing_zeros() as usize;
                    let n = h * base.pw[k as usize] + c.rs[q][i];
                    if n >= lo && n <= hi { surv4 += 1; }
                    s &= s - 1;
                }
            }
        }
    }
    let t_probe4 = t6.elapsed().as_secs_f64();
    assert_eq!(surv4, ref_surv);
    // full check of survivors
    let t4 = Instant::now();
    let mut maxu = 0;
    for &n in &out { maxu = maxu.max(crate::arith::unique_digits(n, b).0); }
    let t_check = t4.elapsed().as_secs_f64();
    assert_eq!(surv, ref_surv, "pipeline survivors differ from the scalar join");
    let share = base.b as f64; // parents shared by the b units that differ in the top shared digit
    let per = |t: f64| t / adm;
    println!(
        "  PIPE (cluster={}) parents {} (visits {}, {:.3}s, shared by {} units) children {} ({:.4}s, {:.1} ns/parent) chunk {:.4}s probes inc {} kept {} ({:.3}) {:.4}s surv {} (== scalar) check {:.4}s maxuniq {}",
        cluster, ps.len(), st.visits, t_par, b, nchild, t_child, t_child * 1e9 / ps.len() as f64, t_chunk, inc, kept, kept as f64 / inc as f64, t_probe, surv, t_check, maxu
    );
    println!("  PIPE 4R-TD: tables {:.4}s ({:.1} ns per chunk, {} chunks) probes {:.4}s ({:.2} ns/kept inc, {:.2} incl. tables) vs sliced {:.2} ns/kept inc; surv {} (== scalar)",
        t_tab, t_tab * 1e9 / ch.iter().map(|c| c.slices.len()).sum::<usize>() as f64, ch.iter().map(|c| c.slices.len()).sum::<usize>(),
        t_probe4, t_probe4 * 1e9 / kept.max(1) as f64, (t_probe4 + t_tab) * 1e9 / kept.max(1) as f64, t_probe * 1e9 / kept.max(1) as f64, surv4);
    let tot = t_par / share + t_child + t_chunk + t_probe + t_check;
    println!(
        "  PIPE s/adm: parents/{} {:.2e} children {:.2e} chunking {:.2e} probes {:.2e} check {:.2e} | total (excl. tops) {:.3e} s/adm; probe {:.2} ns/kept incidence",
        b, per(t_par / share), per(t_child), per(t_chunk), per(t_probe), per(t_check), per(tot), t_probe * 1e9 / kept.max(1) as f64
    );
}
