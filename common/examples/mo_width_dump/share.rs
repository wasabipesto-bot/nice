//! Sharing shared-memory loads between neighbouring probes of phase 3b (scratch branch `exp/mo-word-width`, a
//! measurement only). `MO_SHARE=1 mo_width_dump <pip> <dir> [threads]` counts, at width 64, the digit loads per
//! listed (probe, round) under probe orders × stream assignments × sharing schemes, and with
//! `MO_SHARE_WRITE=<order>,<assignment>,<cap>` also writes `<dir>/s<pip>_w64_ps.bin`: the W64 dump with each
//! instance's probes in that order (digits re-encoded in it), the round lists in that order, and per list entry
//! the one-register scheme's plan `n | s0 << 5 | sv << 10` (an array of `nlist` u32 after `expected`; header
//! word 7 = 1). The kernel then loads digits `s0..n` of an entry (starting from the saved OR if `s0 > 0`) and
//! saves the OR after digit `sv − 1` when `sv > s0`.
//!
//! Orders: `today` (digits ascending, probes as listed today); sorted orders sort an instance's probes
//! lexicographically by their digit sequence: `asc` (digit value ascending), `freq` (descending frequency over
//! the instance's probes), `pos` (certificate position: n² from the most significant digit down, then n³),
//! `posi` (n² and n³ interleaved by significance); `_u` = that digit sequence with today's probe order.
//! Assignments of a round's list to the 16 probe streams (2 entries per lane per step, as `g2_kernel`): `il`
//! today's (entry e → stream e % 16), `c32` 32 contiguous segments (two chains per stream), `c16x2` 16
//! contiguous segments of 2·⌈nlist/32⌉ entries (one chain, two per step), `c16` 16 segments, one entry per step.
//! Schemes: `pad17` (today: 17 loads), `own` (the probe's own digit count), `trieC` (unbounded stack, levels
//! ≤ C), `d1C` (one saved OR, optimal plan by dynamic programming, levels ≤ C), `gD` (a stack of D saved ORs,
//! a greedy plan with lookahead 32, levels ≤ 17).
//! Lockstep: a plane of 2 streams (CUDA warp 32) or 4 (wave 64) pays, per step and entry slot, its largest
//! per-stream load count.

use super::{Job, PMAX, SLW, par_jobs};
use std::io::Write;

#[derive(Clone, Copy, PartialEq, Eq)]
enum Ord {
    Asc,
    Freq,
    Pos,
    PosI,
}
const ORDS: [(&str, Ord, bool); 7] = [
    ("today", Ord::Asc, false),
    ("asc", Ord::Asc, true),
    ("freq", Ord::Freq, true),
    ("pos", Ord::Pos, true),
    ("posi", Ord::PosI, true),
    ("pos_u", Ord::Pos, false),
    ("freq_u", Ord::Freq, false),
];

#[derive(Clone, Copy, PartialEq, Eq)]
enum Asg {
    Il,
    C32,
    C16x2,
    C16,
}
const ASGS: [(&str, Asg); 4] = [("il", Asg::Il), ("c32", Asg::C32), ("c16x2", Asg::C16x2), ("c16", Asg::C16)];

#[derive(Clone, Copy)]
enum Sch {
    Pad17,
    Own,
    Trie(u8),
    D1(u8),
    G(u8),
    /// one saved OR, levels multiples of q (≤ 16): block-structured code
    Q(u8),
}
const SCHS: [(&str, Sch); 16] = [
    ("pad17", Sch::Pad17),
    ("own", Sch::Own),
    ("trie4", Sch::Trie(4)),
    ("trie8", Sch::Trie(8)),
    ("trie12", Sch::Trie(12)),
    ("trie17", Sch::Trie(17)),
    ("d1_4", Sch::D1(4)),
    ("d1_8", Sch::D1(8)),
    ("d1_12", Sch::D1(12)),
    ("d1_17", Sch::D1(17)),
    ("g1", Sch::G(1)),
    ("g2", Sch::G(2)),
    ("g3", Sch::G(3)),
    ("q2", Sch::Q(2)),
    ("q3", Sch::Q(3)),
    ("q4", Sch::Q(4)),
];
const NA: usize = 7; // accumulators per combination

fn seqs(j: &Job, poff: usize, npi: usize, ord: Ord) -> Vec<Vec<u8>> {
    let mut rank = [0u8; 64];
    if ord == Ord::Freq {
        let mut f = [0u32; 64];
        for p in 0..npi {
            let mut y = j.probes[poff + p].0;
            while y != 0 {
                f[y.trailing_zeros() as usize] += 1;
                y &= y - 1;
            }
        }
        let mut v: Vec<usize> = (0..64).collect();
        v.sort_by_key(|&d| (std::cmp::Reverse(f[d]), d));
        for (r, &d) in v.iter().enumerate() {
            rank[d] = r as u8;
        }
    }
    (0..npi)
        .map(|p| {
            let mk = j.probes[poff + p].0;
            let (c2, c3) = &j.certs[poff + p];
            match ord {
                Ord::Asc | Ord::Freq => {
                    let mut dg = Vec::new();
                    let mut y = mk;
                    while y != 0 {
                        dg.push(y.trailing_zeros() as u8);
                        y &= y - 1;
                    }
                    if ord == Ord::Freq {
                        dg.sort_by_key(|&d| rank[d as usize]);
                    }
                    dg
                }
                Ord::Pos => c2.iter().chain(c3.iter()).copied().collect(),
                Ord::PosI => {
                    let mut dg = Vec::new();
                    for i in 0..c2.len().max(c3.len()) {
                        if i < c2.len() {
                            dg.push(c2[i]);
                        }
                        if i < c3.len() {
                            dg.push(c3[i]);
                        }
                    }
                    dg
                }
            }
        })
        .collect()
}

fn qmask(q: u8) -> u32 {
    (1..=16u32).filter(|p| p % u32::from(q) == 0).fold(0, |m, p| m | 1 << p)
}

fn lcp(a: &[u8], b: &[u8]) -> u8 {
    a.iter().zip(b).take_while(|(x, y)| x == y).count() as u8
}

/// Placement of entry e of a list of n: (stream, step, slot h).
fn place(asg: Asg, n: usize, e: usize) -> (usize, usize, usize, usize) {
    // returns (stream, step, h, chain id)
    match asg {
        Asg::Il => (e % 16, e / 32, (e / 16) % 2, e % 16),
        Asg::C32 => {
            let l = n.div_ceil(32);
            let g = e / l;
            (g % 16, e % l, g / 16, g)
        }
        Asg::C16x2 => {
            let l = 2 * n.div_ceil(32);
            let g = e / l;
            let i = e % l;
            (g, i / 2, i % 2, g)
        }
        Asg::C16 => {
            let l = n.div_ceil(16);
            let g = e / l;
            (g, e % l, 0, g)
        }
    }
}

/// One saved OR, levels ≤ cap: the plan minimising the chain's loads. Returns per entry (loads, s0, sv).
fn d1_plan(ns: &[u8], l: &[u8], nx: &[u8], cap: u8, allow: u32) -> Vec<(u8, u8, u8)> {
    const INF: u32 = u32::MAX / 2;
    let m = ns.len();
    let mut f = [INF; 18];
    f[0] = 0;
    // back[i][p] = (prev v, start)
    let mut back: Vec<[(u8, u8); 18]> = vec![[(0, 0); 18]; m];
    for i in 0..m {
        let n = u32::from(ns[i]);
        let hi = cap.min(nx[i]) as usize;
        let mut g = [INF; 18];
        // option B: start 0 from the best state
        let (mut bv, mut bc) = (0usize, INF);
        for (v, &fv) in f.iter().enumerate() {
            if fv < bc {
                bc = fv;
                bv = v;
            }
        }
        for p in 0..=hi {
            if p > 0 && allow >> p & 1 == 0 {
                continue;
            }
            g[p] = bc + n;
            back[i][p] = (bv as u8, 0);
        }
        // option A: start ve = v (v ≤ l_i), states p ∈ {0} ∪ [ve, hi]
        for v in 1..18usize {
            if f[v] >= INF || v > l[i] as usize {
                continue;
            }
            let c = f[v] + n - v as u32;
            if c < g[0] {
                g[0] = c;
                back[i][0] = (v as u8, v as u8);
            }
            for p in v..=hi {
                if allow >> p & 1 == 0 {
                    continue;
                }
                if c < g[p] {
                    g[p] = c;
                    back[i][p] = (v as u8, v as u8);
                }
            }
        }
        f = g;
    }
    let mut p = (0..18).min_by_key(|&v| f[v]).unwrap();
    let mut out = vec![(0u8, 0u8, 0u8); m];
    for i in (0..m).rev() {
        let (v, s0) = back[i][p];
        out[i] = (ns[i] - s0, s0, p as u8);
        p = v as usize;
    }
    out
}

/// A stack of `d` saved ORs, greedy plan with lookahead 32. Returns loads per entry.
fn g_plan(ns: &[u8], l: &[u8], d: usize) -> Vec<u8> {
    let m = ns.len();
    let mut st: Vec<u8> = Vec::new();
    let mut out = vec![0u8; m];
    for i in 0..m {
        st.retain(|&s| s <= l[i]);
        let start = st.iter().copied().max().unwrap_or(0);
        out[i] = ns[i] - start;
        let top = ns[i].min(17);
        let mut t: Vec<u8> = Vec::new();
        let mut mm = u8::MAX;
        for j in i + 1..m.min(i + 33) {
            mm = mm.min(l[j]);
            if mm == 0 {
                break;
            }
            // largest candidate ≤ mm: a saved level ≤ start, or a new level in (start, top]
            let c = if mm > start { mm.min(top) } else { st.iter().copied().filter(|&s| s <= mm).max().unwrap_or(0) };
            if c > 0 && !t.contains(&c) {
                t.push(c);
                if t.len() == d {
                    break;
                }
            }
        }
        st = t;
    }
    out
}

/// Counts for one instance: per (order, assignment, scheme) [entries, loads, lockstep2, lockstep4, occupied
/// plane slots 2, occupied 4, own digits].
fn inst_counts(j: &Job, poff: usize, npi: usize) -> Vec<[u64; NA]> {
    let nch_r = j.kids.len().div_ceil(1024);
    // common masks per round (as job_width)
    let mut commons: Vec<Vec<u64>> = Vec::new();
    for r in 0..nch_r {
        let r0 = r * 1024;
        let ntake = (j.kids.len() - r0).min(1024);
        let nch = ntake.div_ceil(64);
        commons.push(
            (0..nch)
                .map(|q| {
                    let c0 = r0 + q * 64;
                    let nq = (j.kids.len() - c0).min(64);
                    j.kids[c0..c0 + nq].iter().fold(!0u64, |a, &x| a & x)
                })
                .collect(),
        );
    }
    let mut acc = vec![[0u64; NA]; ORDS.len() * ASGS.len() * SCHS.len()];
    for (oi, &(_, ord, sorted)) in ORDS.iter().enumerate() {
        let sq = seqs(j, poff, npi, ord);
        let mut perm: Vec<usize> = (0..npi).collect();
        if sorted {
            perm.sort_by(|&a, &b| sq[a].cmp(&sq[b]));
        }
        for cm in &commons {
            let list: Vec<usize> = perm
                .iter()
                .copied()
                .filter(|&p| cm.iter().any(|&c| c & j.probes[poff + p].0 == 0))
                .collect();
            let n = list.len();
            if n == 0 {
                continue;
            }
            for (ai, &(_, asg)) in ASGS.iter().enumerate() {
                let pl: Vec<_> = (0..n).map(|e| place(asg, n, e)).collect();
                let nchain = 32;
                let mut chains: Vec<Vec<usize>> = vec![Vec::new(); nchain];
                for e in 0..n {
                    chains[pl[e].3].push(e); // e ascending = processing order in every assignment
                }
                let nsteps = pl.iter().map(|x| x.1).max().unwrap() + 1;
                for (si, &(_, sch)) in SCHS.iter().enumerate() {
                    let mut loads = vec![0u8; n];
                    for ch in &chains {
                        if ch.is_empty() {
                            continue;
                        }
                        let s: Vec<&[u8]> = ch.iter().map(|&e| sq[list[e]].as_slice()).collect();
                        let ns: Vec<u8> = s.iter().map(|x| x.len() as u8).collect();
                        let l: Vec<u8> =
                            (0..s.len()).map(|i| if i == 0 { 0 } else { lcp(s[i - 1], s[i]) }).collect();
                        let nx: Vec<u8> = (0..s.len()).map(|i| if i + 1 < s.len() { l[i + 1] } else { 0 }).collect();
                        let ld: Vec<u8> = match sch {
                            Sch::Pad17 => vec![17; s.len()],
                            Sch::Own => ns.clone(),
                            Sch::Trie(c) => (0..s.len()).map(|i| ns[i] - l[i].min(c)).collect(),
                            Sch::D1(c) => d1_plan(&ns, &l, &nx, c, !0).iter().map(|x| x.0).collect(),
                            Sch::Q(q) => d1_plan(&ns, &l, &nx, 16, qmask(q)).iter().map(|x| x.0).collect(),
                            Sch::G(d) => g_plan(&ns, &l, d as usize),
                        };
                        for (k, &e) in ch.iter().enumerate() {
                            loads[e] = ld[k];
                        }
                    }
                    let a = &mut acc[(oi * ASGS.len() + ai) * SCHS.len() + si];
                    a[0] += n as u64;
                    for (k, ps) in [(2usize, 2usize), (3, 4)] {
                        let np = 16 / ps;
                        let mut mx = vec![0u8; nsteps * 2 * np];
                        let mut occ = vec![false; nsteps * 2 * np];
                        for e in 0..n {
                            let (st, step, h, _) = pl[e];
                            let ix = (step * 2 + h) * np + st / ps;
                            mx[ix] = mx[ix].max(loads[e]);
                            occ[ix] = true;
                        }
                        a[k] += mx.iter().map(|&x| u64::from(x)).sum::<u64>();
                        a[k + 2] += occ.iter().filter(|&&o| o).count() as u64;
                    }
                    a[1] += loads.iter().map(|&x| u64::from(x)).sum::<u64>();
                    a[6] += list.iter().map(|&p| sq[p].len() as u64).sum::<u64>();
                }
            }
        }
    }
    acc
}

fn tdig_seq(seq: &[u8], idx: u32) -> [u32; 4] {
    let mut dg: Vec<u32> = seq.iter().map(|&x| u32::from(x)).collect();
    let first = dg[0];
    while dg.len() < 20 {
        dg.push(first);
    }
    let mut w = [0u32; 4];
    for (k, &v) in dg.iter().enumerate() {
        w[k / 5] |= v << (6 * (k % 5));
    }
    w[3] = (w[3] & 0xFFF) | (idx << 12);
    w
}

pub fn run(jobs: &[Job], pip: u128, dir: &str, threads: usize) {
    let t0 = std::time::Instant::now();
    let mut insts: Vec<(usize, usize, usize)> = Vec::new();
    for (jx, j) in jobs.iter().enumerate() {
        let np = j.probes.len();
        for ins in 0..(if np > PMAX { 2 } else { 1 }) {
            insts.push((jx, ins * PMAX, (np - ins * PMAX).min(PMAX)));
        }
    }
    if std::env::var("MO_SHARE_ONLYWRITE").is_ok() {
        if let Ok(spec) = std::env::var("MO_SHARE_WRITE") {
            write_bench(jobs, &insts, pip, dir, threads, &spec);
        }
        return;
    }
    let parts = par_jobs(threads, insts.len(), |i| {
        let (jx, poff, npi) = insts[i];
        inst_counts(&jobs[jx], poff, npi)
    });
    let mut tot = vec![[0u64; NA]; ORDS.len() * ASGS.len() * SCHS.len()];
    for p in &parts {
        for (t, a) in tot.iter_mut().zip(p) {
            for k in 0..NA {
                t[k] += a[k];
            }
        }
    }
    let base = tot[0]; // today, il, pad17
    let (b2, b4) = (base[2] as f64, base[3] as f64);
    println!(
        "SHARE {pip} instances {} entries {} | today's kernel: plane digit-iterations warp32 {} wave64 {} ({:.1} s)",
        insts.len(),
        base[0],
        base[2],
        base[3],
        t0.elapsed().as_secs_f64()
    );
    for (oi, &(on, _, _)) in ORDS.iter().enumerate() {
        for (ai, &(an, _)) in ASGS.iter().enumerate() {
            for (si, &(sn, _)) in SCHS.iter().enumerate() {
                let a = tot[(oi * ASGS.len() + ai) * SCHS.len() + si];
                let e = a[0] as f64;
                println!(
                    "C {pip} {on:7} {an:6} {sn:7} loads/visit {:6.3} own {:6.3} | lockstep loads per visit w32 {:6.3} w64 {:6.3} | vs today w32 {:.4} w64 {:.4} | idle stream slots w32 {:.4} w64 {:.4}",
                    a[1] as f64 / e,
                    a[6] as f64 / e,
                    a[2] as f64 * 2.0 / e,
                    a[3] as f64 * 4.0 / e,
                    a[2] as f64 / b2,
                    a[3] as f64 / b4,
                    1.0 - e / (a[4] as f64 * 2.0),
                    1.0 - e / (a[5] as f64 * 4.0),
                );
            }
        }
    }
    if let Ok(spec) = std::env::var("MO_SHARE_WRITE") {
        write_bench(jobs, &insts, pip, dir, threads, &spec);
    }
}

/// The W64 dump with the chosen order and the one-register plan per list entry.
fn write_bench(jobs: &[Job], insts: &[(usize, usize, usize)], pip: u128, dir: &str, threads: usize, spec: &str) {
    let f: Vec<&str> = spec.split(',').collect();
    let (_, ord, sorted) = *ORDS.iter().find(|o| o.0 == f[0]).expect("order");
    let (_, asg) = *ASGS.iter().find(|a| a.0 == f[1]).expect("assignment");
    // cap: a number (levels ≤ cap) or qN (levels multiples of N, ≤ 16)
    // tN: no plan, the stack of the entry's own prefixes at levels 1..N: s0 = min(LCP with the previous, N)
    let tlev: Option<u8> = f[2].strip_prefix('t').map(|x| x.parse().unwrap());
    let (cap, allow) = match (tlev, f[2].strip_prefix('q')) {
        (Some(_), _) => (0u8, 0u32),
        (None, Some(q)) => (16u8, qmask(q.parse().unwrap())),
        (None, None) => (f[2].parse::<u8>().unwrap(), !0u32),
    };
    // the original W64 rows per job (words, rounds, expected), then permute probes and lists per instance
    // the kernel's blocks of qb digits: per plane size (2, 4 streams) and entry slot h, how many plane-iterations
    // execute block b (some lane of the plane has s0 ≤ lo < n), of how many plane-iterations
    let qb: usize = match f[2].strip_prefix('q') {
        Some(q) => q.parse().unwrap(),
        None => 1,
    };
    // [plane size][0: plane-iterations with a valid entry, 1: digits run with the plane-uniform start (17 − min s0)]
    let uni_acc = std::sync::Mutex::new([[0u64; 2]; 2]);
    let nb = 17usize.div_ceil(qb);
    let parts: Vec<(super::WidthOut, Vec<u32>, u64, Vec<u64>)> = par_jobs(threads, jobs.len(), |jx| {
        let j = &jobs[jx];
        let mut o = super::job_width(j, 64);
        let mut meta = vec![0u32; o.lists.len()];
        let mut planned = 0u64;
        // [plane size index][h][b] then [plane size index] total plane-iterations
        let mut bx = vec![0u64; 2 * 2 * nb + 2];
        let my: Vec<_> = insts.iter().filter(|x| x.0 == jx).collect();
        for (ii, &&(_, poff, npi)) in my.iter().enumerate() {
            let sq = seqs(j, poff, npi, ord);
            let mut perm: Vec<usize> = (0..npi).collect();
            if sorted {
                perm.sort_by(|&a, &b| sq[a].cmp(&sq[b]));
            }
            let mut pos = vec![0usize; npi];
            for (k, &p) in perm.iter().enumerate() {
                pos[p] = k;
            }
            let po = o.inst[ii][5] as usize;
            for (k, &p) in perm.iter().enumerate() {
                let (_, ti) = j.probes[poff + p];
                o.probes[po + k] = tdig_seq(&sq[p], ti);
            }
            let (ro, nr) = (o.inst[ii][6] as usize, o.inst[ii][7] as usize);
            for r in ro..ro + nr {
                let (lo, nl) = (o.rounds[r][3] as usize, o.rounds[r][4] as usize);
                let mut ents: Vec<(usize, u32)> =
                    o.lists[lo..lo + nl].iter().map(|&x| (pos[(x & 0xFFFF) as usize / 16], x >> 16)).collect();
                ents.sort_by_key(|x| x.0);
                for (k, &(sp, km)) in ents.iter().enumerate() {
                    o.lists[lo + k] = (sp as u32 * 16) | (km << 16);
                }
                // chains and the plan
                let n = nl;
                let mut chains: Vec<Vec<usize>> = vec![Vec::new(); 32];
                for e in 0..n {
                    chains[place(asg, n, e).3].push(e);
                }
                for ch in &chains {
                    if ch.is_empty() {
                        continue;
                    }
                    let s: Vec<&[u8]> = ch.iter().map(|&e| sq[perm[ents[e].0]].as_slice()).collect();
                    let ns: Vec<u8> = s.iter().map(|x| x.len() as u8).collect();
                    let l: Vec<u8> = (0..s.len()).map(|i| if i == 0 { 0 } else { lcp(s[i - 1], s[i]) }).collect();
                    let nx: Vec<u8> = (0..s.len()).map(|i| if i + 1 < s.len() { l[i + 1] } else { 0 }).collect();
                    let pl: Vec<(u8, u8, u8)> = match tlev {
                        Some(t) => (0..ns.len()).map(|i| (ns[i] - l[i].min(t), l[i].min(t), 0)).collect(),
                        None => d1_plan(&ns, &l, &nx, cap, allow),
                    };
                    for (k, &e) in ch.iter().enumerate() {
                        let (ld, s0, sv) = pl[k];
                        planned += u64::from(ld);
                        meta[lo + e] = u32::from(ns[k]) | (u32::from(s0) << 5) | (u32::from(sv) << 10);
                    }
                }
                let steps = n.div_ceil(32);
                for (pi, ps) in [2usize, 4].into_iter().enumerate() {
                    let np = 16 / ps;
                    let mut mn = vec![u32::MAX; steps * np * 2];
                    for e in 0..n {
                        let (st, step, h, _) = place(asg, n, e);
                        let ix = (step * np + st / ps) * 2 + h;
                        mn[ix] = mn[ix].min(meta[lo + e] >> 5 & 31);
                    }
                    let mut u = uni_acc.lock().unwrap();
                    for &m in &mn {
                        if m != u32::MAX {
                            u[pi][0] += 1;
                            u[pi][1] += u64::from(17 - m);
                        }
                    }
                }
                for (pi, ps) in [2usize, 4].into_iter().enumerate() {
                    let np = 16 / ps;
                    bx[2 * 2 * nb + pi] += (steps * np) as u64;
                    let mut ex = vec![false; steps * np * 2 * nb];
                    for e in 0..n {
                        let (st, step, h, _) = place(asg, n, e);
                        let mt = meta[lo + e];
                        let (nd, s0) = ((mt & 31) as usize, (mt >> 5 & 31) as usize);
                        for b in 0..nb {
                            if s0 <= b * qb && nd > b * qb {
                                ex[((step * np + st / ps) * 2 + h) * nb + b] = true;
                            }
                        }
                    }
                    for (i, &x) in ex.iter().enumerate() {
                        if x {
                            bx[(pi * 2 + (i / nb) % 2) * nb + i % nb] += 1;
                        }
                    }
                }
            }
        }
        (o, meta, planned, bx)
    });
    let mut all = super::WidthOut::default();
    let mut meta_all: Vec<u32> = Vec::new();
    let mut planned = 0u64;
    let mut bxt = vec![0u64; 2 * 2 * nb + 2];
    for (jx, (mut p, meta, pl, bx)) in parts.into_iter().enumerate() {
        for (t, x) in bxt.iter_mut().zip(&bx) {
            *t += x;
        }
        let (po, ro, lo, so) =
            (all.probes.len() as u32, all.rounds.len() as u32, all.lists.len() as u32, (all.words.len() / SLW) as u32);
        for r in &mut p.rounds {
            r[0] += so;
            r[3] += lo;
        }
        for i in &mut p.inst {
            i[0] = jx as u32;
            i[5] += po;
            i[6] += ro;
        }
        all.inst.extend(p.inst);
        all.rounds.extend(p.rounds);
        all.probes.extend(p.probes);
        all.lists.extend(p.lists);
        all.words.extend(p.words);
        all.expect.extend(p.expect);
        meta_all.extend(meta);
        planned += pl;
    }
    let sum = |k: usize| all.expect.iter().map(|e| u64::from(e[k])).sum::<u64>();
    println!(
        "PSWRITE {pip} spec {spec}: inst {} rounds {} list {} | nonzero {} bits {} kept {} lslots {} | planned loads {planned} = {:.3} per entry",
        all.inst.len(),
        all.rounds.len(),
        all.lists.len(),
        sum(0),
        sum(1),
        sum(2),
        sum(3),
        planned as f64 / all.lists.len() as f64
    );
    let path = format!("{dir}/s{pip}_w64_ps.bin");
    let mut fo = std::io::BufWriter::new(std::fs::File::create(&path).unwrap());
    let mut put = |v: &[u32]| {
        for x in v {
            fo.write_all(&x.to_le_bytes()).unwrap();
        }
    };
    put(&[
        0x5744_5448,
        64,
        all.inst.len() as u32,
        all.rounds.len() as u32,
        all.probes.len() as u32,
        all.lists.len() as u32,
        (all.words.len() / SLW) as u32,
        1,
    ]);
    for r in &all.inst {
        put(r);
    }
    for r in &all.rounds {
        put(r);
    }
    for r in &all.probes {
        put(r);
    }
    put(&all.lists);
    put(&all.words);
    for r in &all.expect {
        put(r);
    }
    put(&meta_all);
    drop(put);
    fo.flush().unwrap();
    println!("WROTE {path}");
    let u = uni_acc.into_inner().unwrap();
    for (pi, nm) in ["warp32", "wave64"].iter().enumerate() {
        println!(
            "UNIFORM {pip} spec {spec} {nm}: plane entry-slots with a valid entry {} | digits run from the plane's minimum s0 to 17: {:.3} per slot (vs 17: {:.4})",
            u[pi][0],
            u[pi][1] as f64 / u[pi][0] as f64,
            u[pi][1] as f64 / u[pi][0] as f64 / 17.0
        );
    }
    for (pi, nm) in ["warp32", "wave64"].iter().enumerate() {
        let tot = bxt[2 * 2 * nb + pi];
        let mut v = Vec::new();
        let mut dl = 0f64;
        for h in 0..2 {
            for b in 0..nb {
                let x = bxt[(pi * 2 + h) * nb + b];
                let sz = (17 - b * qb).min(qb);
                dl += x as f64 * sz as f64;
                v.push(format!("{:.4}", x as f64 / tot as f64));
            }
        }
        println!(
            "BLOCKS {pip} spec {spec} {nm}: plane-iterations {tot} | digit loads issued per plane-iteration {:.3} (today 34) | fraction executing [h][block of {qb}] {}",
            dl / tot as f64,
            v.join(" ")
        );
    }
}
