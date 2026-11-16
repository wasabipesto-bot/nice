//! Pairing variants for one transversal unit (no key digits; class only).
//! All variants must produce the same survivor count.

use crate::join::*;
use std::time::Instant;

pub struct Group {
    pub masks: Vec<u64>,
    pub hs: Vec<u128>,
    pub slices: Vec<[u64; 64]>,         // per 64-top chunk: tops containing digit v
    pub tables: Vec<[[u64; 256]; 8]>,   // per chunk: byte j value x -> tops meeting x<<8j
    pub common: Vec<u64>,               // per chunk: AND of member masks
    pub scommon: Vec<u64>,              // per 8 chunks
}

pub fn build_groups(base: &Base, tops: &[(u64, Top)], by_mask: bool) -> Vec<Group> {
    let m = (base.b - 1) as usize;
    let mut by: Vec<Vec<(u128, u64)>> = vec![Vec::new(); m];
    for (_, t) in tops {
        by[(t.h % m as u128) as usize].push((t.h, t.mask));
    }
    by.into_iter()
        .map(|mut v| {
            if by_mask {
                // cluster: permute digits by frequency in this group, most frequent first, sort descending
                let mut freq = [0u32; 64];
                for x in &v {
                    for d in 0..64 {
                        freq[d] += ((x.1 >> d) & 1) as u32;
                    }
                }
                let mut ord: Vec<usize> = (0..64).collect();
                ord.sort_by(|a, b| freq[*b].cmp(&freq[*a]));
                let key = |m: u64| -> u64 {
                    let mut k = 0u64;
                    for (i, &d) in ord.iter().enumerate() {
                        k |= ((m >> d) & 1) << (63 - i);
                    }
                    k
                };
                v.sort_by_key(|x| std::cmp::Reverse(key(x.1)));
            } else {
                v.sort();
            }
            let masks: Vec<u64> = v.iter().map(|x| x.1).collect();
            let hs: Vec<u128> = v.iter().map(|x| x.0).collect();
            let nch = masks.len().div_ceil(64);
            let mut slices = vec![[0u64; 64]; nch];
            let mut common = vec![!0u64; nch];
            for (i, &mk) in masks.iter().enumerate() {
                let c = i / 64;
                common[c] &= mk;
                let mut x = mk;
                while x != 0 {
                    let d = x.trailing_zeros() as usize;
                    slices[c][d] |= 1u64 << (i % 64);
                    x &= x - 1;
                }
            }
            let mut tables = vec![[[0u64; 256]; 8]; nch];
            for c in 0..nch {
                for j in 0..8 {
                    for x in 1..256usize {
                        let low = x.trailing_zeros() as usize;
                        tables[c][j][x] = tables[c][j][x & (x - 1)] | slices[c][8 * j + low];
                    }
                }
            }
            let scommon = common.chunks(8).map(|w| w.iter().fold(!0u64, |a, &b| a & b)).collect();
            Group { masks, hs, slices, tables, common, scommon }
        })
        .collect()
}

#[derive(Default, Debug)]
pub struct VarStats {
    pub pairs: u64,
    pub chunk_inc: u64,       // (bottom, chunk) incidences
    pub chunk_kept: u64,      // after chunk-common skip
    pub schunk_inc: u64,
    pub schunk_kept: u64,
    pub digit_ops: u64,       // popcount iterations of the bit-sliced variant
    pub surv: [u64; 5],
    pub secs: [f64; 5],
}

fn chunk_bits(len: usize, c: usize) -> u64 {
    let n = (len - 64 * c).min(64);
    if n == 64 { !0 } else { (1u64 << n) - 1 }
}

pub fn run_variants(base: &Base, groups: &[Group], bots: &[Bot], reps: u32) -> VarStats {
    let m = base.b - 1;
    let mut by: Vec<Vec<u64>> = vec![Vec::new(); m as usize];
    for bt in bots {
        by[(bt.r % m as u128) as usize].push(bt.mask);
    }
    let mut vs = VarStats::default();
    // incidence list: (bottom class, group index)
    let mut inc: Vec<(usize, usize)> = Vec::new();
    for cb in 0..m as usize {
        for &rt in &base.roots {
            let ct = ((rt + m - cb as u64) % m) as usize;
            inc.push((cb, ct));
        }
    }
    for &(cb, ct) in &inc {
        let g = &groups[ct];
        let nb = by[cb].len() as u64;
        vs.pairs += nb * g.masks.len() as u64;
        vs.chunk_inc += nb * g.common.len() as u64;
        vs.schunk_inc += nb * g.scommon.len() as u64;
        for &bm in &by[cb] {
            vs.digit_ops += bm.count_ones() as u64 * g.common.len() as u64;
            for (c, &cm) in g.common.iter().enumerate() {
                if cm & bm == 0 {
                    vs.chunk_kept += 1;
                }
                let _ = c;
            }
            for &sm in &g.scommon {
                if sm & bm == 0 {
                    vs.schunk_kept += 1;
                }
            }
        }
    }
    for v in 0..5 {
        let t0 = Instant::now();
        let mut surv = 0u64;
        for _ in 0..reps {
            surv = 0;
            for &(cb, ct) in &inc {
                let g = &groups[ct];
                let ntops = g.masks.len();
                if ntops == 0 {
                    continue;
                }
                for &bm in &by[cb] {
                    match v {
                        0 => {
                            // scalar AND per pair
                            for &tm in &g.masks {
                                surv += (tm & bm == 0) as u64;
                            }
                        }
                        1 => {
                            // bit-sliced: OR the slices of the bottom's digits
                            for (c, sl) in g.slices.iter().enumerate() {
                                let mut acc = 0u64;
                                let mut x = bm;
                                while x != 0 {
                                    acc |= sl[x.trailing_zeros() as usize];
                                    x &= x - 1;
                                }
                                surv += (!acc & chunk_bits(ntops, c)).count_ones() as u64;
                            }
                        }
                        2 => {
                            // four Russians: 8 byte lookups per chunk
                            let bytes = bm.to_le_bytes();
                            for (c, tb) in g.tables.iter().enumerate() {
                                let mut acc = 0u64;
                                for j in 0..8 {
                                    acc |= tb[j][bytes[j] as usize];
                                }
                                surv += (!acc & chunk_bits(ntops, c)).count_ones() as u64;
                            }
                        }
                        3 => {
                            // four Russians with chunk-common skip
                            let bytes = bm.to_le_bytes();
                            for (c, tb) in g.tables.iter().enumerate() {
                                if g.common[c] & bm != 0 {
                                    continue;
                                }
                                let mut acc = 0u64;
                                for j in 0..8 {
                                    acc |= tb[j][bytes[j] as usize];
                                }
                                surv += (!acc & chunk_bits(ntops, c)).count_ones() as u64;
                            }
                        }
                        _ => {
                            // two-level skip (super-chunk of 8, then chunk) + four Russians
                            let bytes = bm.to_le_bytes();
                            for (s, &sm) in g.scommon.iter().enumerate() {
                                if sm & bm != 0 {
                                    continue;
                                }
                                let hi = (8 * s + 8).min(g.tables.len());
                                for c in 8 * s..hi {
                                    if g.common[c] & bm != 0 {
                                        continue;
                                    }
                                    let tb = &g.tables[c];
                                    let mut acc = 0u64;
                                    for j in 0..8 {
                                        acc |= tb[j][bytes[j] as usize];
                                    }
                                    surv += (!acc & chunk_bits(ntops, c)).count_ones() as u64;
                                }
                            }
                        }
                    }
                }
            }
        }
        vs.secs[v] = t0.elapsed().as_secs_f64() / reps as f64;
        vs.surv[v] = surv;
    }
    vs
}

/// Clustering evaluation (counts only). `items[g]`: masks on the chunked side for group g;
/// `probes`: (mask, group) pairs on the iterated side. Returns
/// (pairs, flat chunks ⌈n/64⌉ incidences, trie-leaf incidences, trie leaves kept after the common-mask
/// test, trie nodes visited by a descent that skips subtrees whose common mask meets the probe).
pub fn cluster_eval(items: &[Vec<u64>], probes: &[(u64, usize)]) -> [u64; 5] {
    cluster_eval_w(items, probes, false)
}

pub fn cluster_eval_w(items: &[Vec<u64>], probes: &[(u64, usize)], weighted: bool) -> [u64; 5] {
    // build a presence trie per group: split on the most frequent digit not yet used, until <= 64
    struct Node { common: u64, kids: Vec<usize>, leaf: bool }
    fn build(v: &mut Vec<u64>, used: u64, common: u64, nodes: &mut Vec<Node>, pf: &[f64; 64]) -> usize {
        let id = nodes.len();
        nodes.push(Node { common, kids: vec![], leaf: false });
        if v.len() <= 64 || used == !0u64 {
            nodes[id].leaf = true;
            return id;
        }
        let mut freq = [0u32; 64];
        for &m in v.iter() {
            let mut x = m & !used;
            while x != 0 { freq[x.trailing_zeros() as usize] += 1; x &= x - 1; }
        }
        let (d, _) = freq.iter().enumerate().map(|(i, &f)| (i, f as f64 * pf[i])).max_by(|a, b| a.1.partial_cmp(&b.1).unwrap()).unwrap();
        let f = freq[d];
        if f == 0 || f as usize == v.len() && false {
            nodes[id].leaf = true;
            return id;
        }
        let (mut has, mut lacks): (Vec<u64>, Vec<u64>) = v.iter().partition(|&&m| (m >> d) & 1 == 1);
        let u = used | (1u64 << d);
        let a = if !has.is_empty() { Some(build(&mut has, u, common | (1u64 << d), nodes, pf)) } else { None };
        let b = if !lacks.is_empty() { Some(build(&mut lacks, u, common, nodes, pf)) } else { None };
        nodes[id].kids = a.into_iter().chain(b).collect();
        id
    }
    let mut out = [0u64; 5];
    // probe digit frequencies per target group
    let mut pfs = vec![[0f64; 64]; items.len()];
    for &(pm, g) in probes {
        let mut x = pm;
        while x != 0 { pfs[g][x.trailing_zeros() as usize] += 1.0; x &= x - 1; }
    }
    let tries: Vec<(Vec<Node>, usize)> = items.iter().enumerate().map(|(gi, g)| {
        let mut nodes = Vec::new();
        let mut v = g.clone();
        let pf = if weighted { let mut p = pfs[gi]; for x in p.iter_mut() { *x += 1e-9; } p } else { [1.0f64; 64] };
        if !v.is_empty() { build(&mut v, 0, 0, &mut nodes, &pf); }
        let nl = nodes.iter().filter(|n| n.leaf).count();
        (nodes, nl)
    }).collect();
    for &(pm, g) in probes {
        let n = items[g].len() as u64;
        if n == 0 { continue; }
        out[0] += n;
        out[1] += n.div_ceil(64);
        let (nodes, nl) = &tries[g];
        out[2] += *nl as u64;
        for nd in nodes.iter() {
            if nd.leaf && nd.common & pm == 0 { out[3] += 1; }
        }
        // descent
        let mut st = vec![0usize];
        while let Some(i) = st.pop() {
            out[4] += 1;
            if nodes[i].common & pm != 0 { continue; }
            st.extend(nodes[i].kids.iter().copied());
        }
    }
    out
}

/// Flat 64-chunks in a sorted order. `items[g]` = (child mask, order mask); the order is the
/// probe-weighted frequency permutation of `order mask`, descending. Returns (flat chunks, kept).
pub fn sorted_chunks_eval(items: &[Vec<(u64, u64)>], probes: &[(u64, usize)]) -> (u64, u64) {
    sorted_chunks_eval_w(items, probes, probes)
}
pub fn sorted_chunks_eval_w(items: &[Vec<(u64, u64)>], probes: &[(u64, usize)], wprobes: &[(u64, usize)]) -> (u64, u64) {
    let mut pfs = vec![[0f64; 64]; items.len()];
    let pooled = std::env::var("G2_POOLED").is_ok();
    for &(pm, g) in wprobes {
        let mut x = pm;
        while x != 0 {
            let d = x.trailing_zeros() as usize;
            if pooled { for q in pfs.iter_mut() { q[d] += 1.0; } } else { pfs[g][d] += 1.0; }
            x &= x - 1;
        }
    }
    let mut commons: Vec<Vec<u64>> = Vec::with_capacity(items.len());
    for (gi, g) in items.iter().enumerate() {
        let mut freq = [0f64; 64];
        for x in g {
            let mut y = x.1;
            while y != 0 { freq[y.trailing_zeros() as usize] += 1.0; y &= y - 1; }
        }
        let mut ord: Vec<usize> = (0..64).collect();
        ord.sort_by(|a, b| (freq[*b] * (pfs[gi][*b] + 1e-9)).partial_cmp(&(freq[*a] * (pfs[gi][*a] + 1e-9))).unwrap());
        let mut perm = [0u32; 64];
        for (i, &d) in ord.iter().enumerate() { perm[d] = 63 - i as u32; }
        let mut v: Vec<(u64, u64)> = g.iter().map(|x| {
            let mut kk = 0u64; let mut y = x.1;
            while y != 0 { kk |= 1u64 << perm[y.trailing_zeros() as usize]; y &= y - 1; }
            (kk, x.0)
        }).collect();
        let cw: usize = std::env::var("G2_CW").ok().and_then(|x| x.parse().ok()).unwrap_or(64);
        // review: optional coarse key (top q bits of the permuted key) and sorting only within tiles of S items
        let q: u32 = std::env::var("G2_KEYBITS").ok().and_then(|x| x.parse().ok()).unwrap_or(64);
        if q < 64 { for e in v.iter_mut() { e.0 = if q == 0 { 0 } else { e.0 >> (64 - q) }; } }
        let tile: usize = std::env::var("G2_TILE").ok().and_then(|x| x.parse().ok()).unwrap_or(usize::MAX);
        let nosort = std::env::var("G2_NOSORT").is_ok();
        let mut cm = Vec::new();
        for t in v.chunks_mut(tile.min(usize::MAX)) {
            if !nosort { t.sort_by(|a, b| b.0.cmp(&a.0)); }
            for c in t.chunks(cw) { cm.push(c.iter().fold(!0u64, |a, x| a & x.1)); }
        }
        commons.push(cm);
    }
    let (mut flat, mut kept) = (0u64, 0u64);
    for &(pm, g) in probes {
        for &c in &commons[g] { flat += 1; if c & pm == 0 { kept += 1; } }
    }
    (flat, kept)
}
