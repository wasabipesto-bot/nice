// Day-2 pairing-gap harness on real G2 super-units (dump2 output of day2/proto).
// usage: pair DIR SCHEME [sample_every]
// Blocks = (parent class c, unit digit d). Children of a block are ordered/chunked by SCHEME,
// probes are the unit's tops of the class-compatible top classes. Counts:
//   pairs, pass (disjoint pairs), flat chunk tests, kept 64-words, touch (kept words holding a passing
//   pair), pack (sum over probes of ceil(pass_t/64)), lookups (sum over kept words of digits to OR),
//   visits (bucket enumerations).
use std::io::Read;

struct Par { r: u128, mask: u64, c2: u8, c3: u8, a2: u8, a3: u8, cls: u32 }
struct Top { d: u32, h: u64, mask: u64 }

fn load(dir: &str) -> (u64, Vec<u64>, f64, Vec<Par>, Vec<Top>) {
    let meta = std::fs::read_to_string(format!("{dir}/meta2.txt")).unwrap();
    let w: Vec<&str> = meta.split_whitespace().collect();
    let b: u64 = w[1].parse().unwrap();
    let ri = meta.find('[').unwrap();
    let rj = meta.find(']').unwrap();
    let roots: Vec<u64> = meta[ri + 1..rj].split(',').map(|x| x.trim().parse().unwrap()).collect();
    let adm: f64 = w[w.iter().position(|&x| x == "adm").unwrap() + 1].parse().unwrap();
    let mut buf = Vec::new();
    std::fs::File::open(format!("{dir}/parents.bin")).unwrap().read_to_end(&mut buf).unwrap();
    let mut ps = Vec::new();
    for c in buf.chunks(32) {
        ps.push(Par {
            r: u128::from_le_bytes(c[0..16].try_into().unwrap()),
            mask: u64::from_le_bytes(c[16..24].try_into().unwrap()),
            c2: c[24], c3: c[25], a2: c[26], a3: c[27],
            cls: u32::from_le_bytes(c[28..32].try_into().unwrap()),
        });
    }
    ps.sort_by_key(|p| p.r);
    let mut buf = Vec::new();
    std::fs::File::open(format!("{dir}/tops.bin")).unwrap().read_to_end(&mut buf).unwrap();
    let mut ts = Vec::new();
    for c in buf.chunks(52) {
        ts.push(Top {
            d: u32::from_le_bytes(c[0..4].try_into().unwrap()),
            h: u64::from_le_bytes(c[4..12].try_into().unwrap()),
            mask: u64::from_le_bytes(c[12..20].try_into().unwrap()),
        });
    }
    (b, roots, adm, ps, ts)
}

#[derive(Clone, Copy)]
struct St { pairs: u64, pass: u64, flat: u64, kept: u64, touch: u64, pack: u64, lookups: u64, visits: u64, chunks: u64, children: u64, probes: u64, ej: [u64; 66], warp_eff: u64, warp_n: u64 }
impl St {
    fn add(&mut self, o: &St) {
        self.pairs += o.pairs; self.pass += o.pass; self.flat += o.flat; self.kept += o.kept; self.touch += o.touch;
        self.pack += o.pack; self.lookups += o.lookups; self.visits += o.visits; self.chunks += o.chunks;
        self.children += o.children; self.probes += o.probes;
        for i in 0..66 { self.ej[i] += o.ej[i]; } self.warp_eff += o.warp_eff; self.warp_n += o.warp_n;
    }
}

impl Default for St { fn default() -> Self { St { pairs: 0, pass: 0, flat: 0, kept: 0, touch: 0, pack: 0, lookups: 0, visits: 0, chunks: 0, children: 0, probes: 0, ej: [0; 66], warp_eff: 0, warp_n: 0 } } }
struct Chunk { common: u64, valid: u64, sl: [u64; 64], tag: u64 /* bucket pattern */, known: u64 }
fn cw() -> usize { std::env::var("CW").ok().map(|x| x.parse().unwrap()).unwrap_or(64) }
fn mk_chunks(members: &[u64], tag: u64, known: u64, out: &mut Vec<Chunk>) {
    for g in members.chunks(cw()) {
        let mut c = Chunk { common: !0, valid: 0, sl: [0; 64], tag, known };
        for (i, &m) in g.iter().enumerate() {
            c.common &= m;
            c.valid |= 1u64 << i;
            let mut y = m;
            while y != 0 { c.sl[y.trailing_zeros() as usize] |= 1u64 << i; y &= y - 1; }
        }
        out.push(c);
    }
}

// evaluate probes against chunks; bucket chunks share a tag; a probe visits a tag only if tag & t == 0
fn eval(chunks: &[Chunk], probes: &[u64], st: &mut St, dorder: &[u8; 64]) {
    // dorder: digits in decreasing child frequency (early-exit order)
    st.chunks += chunks.len() as u64;
    for &t in probes {
        let td: Vec<usize> = dorder.iter().map(|&x| x as usize).filter(|&x| (t >> x) & 1 == 1).collect();
        let mut pt = 0u64;
        let mut last_tag = u64::MAX;
        let mut tag_ok = true;
        let mut grp: Vec<u64> = Vec::new();
        for c in chunks {
            if c.tag != last_tag {
                last_tag = c.tag;
                tag_ok = c.tag & t == 0;
                if tag_ok { st.visits += 1; }
            }
            if !tag_ok { continue; }
            st.flat += 1;
            let mut acc = 0u64; let mut jneed = 0usize;
            for (j, &x) in td.iter().enumerate() {
                acc |= c.sl[x];
                if jneed == 0 && acc & c.valid == c.valid { jneed = j + 1; }
            }
            let p = (!acc & c.valid).count_ones() as u64;
            pt += p;
            if c.common & t != 0 { continue; }
            st.kept += 1;
            st.lookups += (t & !c.known).count_ones() as u64;
            if p > 0 { st.touch += 1; jneed = td.len(); st.ej[65] += 1; } else { st.ej[jneed] += 1; }
            grp.push(jneed as u64);
            if grp.len() == 32 { st.warp_eff += 32 * *grp.iter().max().unwrap(); st.warp_n += 32; grp.clear(); }
        }
        if !grp.is_empty() { st.warp_eff += grp.len() as u64 * *grp.iter().max().unwrap(); st.warp_n += grp.len() as u64; }
        st.pass += pt;
        st.pack += pt.div_ceil(64);
    }
}


// Probe trie x chunk: probes sorted by their digit sequences (order = probe-frequency desc);
// one DFS per chunk shares prefix ORs among probes and prunes a subtree as soon as acc covers all
// members (no disjoint member can exist below). Counts computed nodes (lookups), leaf tests, and the
// warp-union (32 consecutive chunks of the block traverse together; a node is paid if any lane needs it).
fn warp_w() -> usize { std::env::var("WARP").ok().map(|x| x.parse().unwrap()).unwrap_or(32) }
fn trie_eval(chunks: &[Chunk], probes: &[u64], tr: &mut [u64; 6]) {
    let mut wt = [0u32; 64];
    for &t in probes { let mut y = t; while y != 0 { wt[y.trailing_zeros() as usize] += 1; y &= y - 1; } }
    let mut ord: Vec<usize> = (0..64).collect();
    ord.sort_by(|&a, &c| wt[c].cmp(&wt[a]).then(a.cmp(&c)));
    let mut seqs: Vec<Vec<u8>> = probes.iter().map(|&t| ord.iter().filter(|&&x| (t >> x) & 1 == 1).map(|&x| x as u8).collect()).collect();
    seqs.sort();
    let n = seqs.len();
    let mut lcp = vec![0usize; n];
    for i in 1..n { let (a, c) = (&seqs[i - 1], &seqs[i]); let mut l = 0; while l < a.len() && l < c.len() && a[l] == c[l] { l += 1; } lcp[i] = l; }
    // node ids: (i, depth) where i = first probe index owning the node (depth >= lcp[i])
    let nodes_total: usize = (0..n).map(|i| seqs[i].len() - lcp[i]).sum();
    tr[0] += nodes_total as u64 * chunks.len() as u64; // unpruned node visits
    let mut nid = vec![0usize; n + 1];
    for i in 0..n { nid[i + 1] = nid[i] + seqs[i].len() - lcp[i]; }
    let mut warp_seen = vec![0u32; nodes_total];
    for (qi, c) in chunks.iter().enumerate() {
        let lane = (qi % warp_w()) as u32;
        if lane == 0 { for x in warp_seen.iter_mut() { *x = 0; } }
        let mut acc = [0u64; 66];
        let mut full_at = usize::MAX; // smallest depth whose acc is full on the current path
        for i in 0..n {
            let l = lcp[i];
            if full_at != usize::MAX && full_at < l { continue; } // still inside a pruned subtree
            full_at = usize::MAX;
            let sq = &seqs[i];
            let base = if l == 0 { 0 } else { acc[l - 1] };
            let mut a = base;
            let mut pruned = false;
            for dpt in l..sq.len() {
                a |= c.sl[sq[dpt] as usize];
                acc[dpt] = a;
                tr[1] += 1;
                let id = nid[i] + dpt - l;
                if warp_seen[id] & (1 << lane) == 0 { if warp_seen[id] == 0 { tr[2] += 1; } warp_seen[id] |= 1 << lane; }
                if a & c.valid == c.valid { full_at = dpt; pruned = true; break; }
            }
            if !pruned { tr[3] += 1; if (!a & c.valid) != 0 { tr[4] += 1; } }
        }
        tr[5] += 1;
    }
    // tr[2] counts warp-union nodes; scale: each union node costs one warp step for 32 lanes
}


// 2-cover certificates: pairs {x, y} (outside the common mask) such that every member has x or y.
// Upper bound on extra skips if a chunk could test all of its 2-covers (and 3-covers among the
// chunk's 12 most frequent digits) against t.
thread_local! { static GC: std::cell::RefCell<[u64; 21]> = std::cell::RefCell::new([0; 21]); }
fn cover_eval(chunks: &[Chunk], probes: &[u64], cv: &mut [u64; 6]) {
    for c in chunks {
        let mut pairs: Vec<u64> = Vec::new();
        let mut cnt = [0u32; 64];
        for v in 0..64 { cnt[v] = (c.sl[v] & c.valid).count_ones(); }
        for x in 0..64 { if (c.common >> x) & 1 == 1 || cnt[x] == 0 { continue; }
            for y in (x + 1)..64 { if (c.common >> y) & 1 == 1 || cnt[y] == 0 { continue; }
                if (c.sl[x] | c.sl[y]) & c.valid == c.valid { pairs.push((1u64 << x) | (1u64 << y)); } } }
        let mut top: Vec<usize> = (0..64).filter(|&v| (c.common >> v) & 1 == 0).collect();
        top.sort_by(|&a, &b| cnt[b].cmp(&cnt[a]));
        top.truncate(12);
        let mut trip: Vec<u64> = Vec::new();
        for i in 0..top.len() { for j in i + 1..top.len() { for k in j + 1..top.len() {
            let (x, y, z) = (top[i], top[j], top[k]);
            if (c.sl[x] | c.sl[y] | c.sl[z]) & c.valid == c.valid {
                let m = (1u64 << x) | (1u64 << y) | (1u64 << z);
                if !pairs.iter().any(|&p| p & m == p) { trip.push(m); } } } } }
        cv[0] += pairs.len() as u64; cv[1] += trip.len() as u64; cv[2] += 1;
        for &t in probes {
            if c.common & t != 0 { continue; }
            let mut acc = 0u64; let mut y = t;
            while y != 0 { acc |= c.sl[y.trailing_zeros() as usize]; y &= y - 1; }
            if !acc & c.valid != 0 { continue; } // passing word: must be kept
            cv[3] += 1;
            // greedy cover of the 64 members by t's digits
            { let mut unc = c.valid; let mut k = 0u64;
              while unc != 0 { let mut best = 0u64; let mut y = t;
                while y != 0 { let x = y.trailing_zeros() as usize; let g = c.sl[x] & unc; if g.count_ones() > best.count_ones() { best = g; } y &= y - 1; }
                unc &= !best; k += 1; }
              GC.with(|h| h.borrow_mut()[k.min(20) as usize] += 1); }
            if pairs.iter().any(|&p| p & t == p) { cv[4] += 1; }
            else if trip.iter().any(|&p| p & t == p) { cv[5] += 1; }
        }
    }
}


// CPU timing: G2 probe loop (lanes over chunks semantics, scalar) vs probe-trie DFS with full-cover pruning
fn time_block(chunks: &[Chunk], probes: &[u64], tm: &mut [f64; 4], cnt: &mut [u64; 2]) {
    use std::time::Instant;
    // G2: per probe, per chunk
    let t0 = Instant::now();
    let mut s1 = 0u64;
    for &t in probes {
        let td: Vec<usize> = { let mut v = Vec::new(); let mut y = t; while y != 0 { v.push(y.trailing_zeros() as usize); y &= y - 1; } v };
        for c in chunks {
            if c.common & t != 0 { continue; }
            let mut acc = 0u64;
            for &x in &td { acc |= c.sl[x]; }
            s1 += (!acc & c.valid).count_ones() as u64;
        }
    }
    tm[0] += t0.elapsed().as_secs_f64();
    // trie
    let t1 = Instant::now();
    let mut wt = [0u32; 64];
    for &t in probes { let mut y = t; while y != 0 { wt[y.trailing_zeros() as usize] += 1; y &= y - 1; } }
    let mut ord: Vec<usize> = (0..64).collect();
    ord.sort_by(|&a, &c| wt[c].cmp(&wt[a]).then(a.cmp(&c)));
    let mut seqs: Vec<Vec<u8>> = probes.iter().map(|&t| ord.iter().filter(|&&x| (t >> x) & 1 == 1).map(|&x| x as u8).collect()).collect();
    seqs.sort();
    let n = seqs.len();
    let mut lcp = vec![0usize; n];
    for i in 1..n { let (a, c) = (&seqs[i - 1], &seqs[i]); let mut l = 0; while l < a.len() && l < c.len() && a[l] == c[l] { l += 1; } lcp[i] = l; }
    // skip pointers: next probe index whose lcp < depth (precompute per (i, depth) lazily via scan)
    tm[2] += t1.elapsed().as_secs_f64();
    let t2 = Instant::now();
    let mut s2 = 0u64;
    for c in chunks {
        let mut acc = [0u64; 66];
        let mut i = 0;
        while i < n {
            let l = lcp[i];
            let sq = &seqs[i];
            let mut a = if l == 0 { 0 } else { acc[l - 1] };
            let mut full = usize::MAX;
            for dpt in l..sq.len() {
                a |= c.sl[sq[dpt] as usize];
                acc[dpt] = a;
                if a & c.valid == c.valid { full = dpt; break; }
            }
            if full == usize::MAX { s2 += (!a & c.valid).count_ones() as u64; i += 1; }
            else { i += 1; while i < n && lcp[i] > full { i += 1; } }
        }
    }
    tm[1] += t2.elapsed().as_secs_f64();
    cnt[0] += s1; cnt[1] += s2;
    assert_eq!(s1, s2);
}


// two-sided blocking: probes sorted (probe-frequency key), grouped by g; a (group, chunk) is skipped
// whole when the group's common mask meets the chunk's common mask. Returns skip tests replaced.
fn twoside_eval(chunks: &[Chunk], probes: &[u64], g: usize, ts: &mut [u64; 4]) {
    let mut wt = [0f64; 64];
    for &t in probes { let mut y = t; while y != 0 { wt[y.trailing_zeros() as usize] += 1.0; y &= y - 1; } }
    let (pos, _) = rank_from(&wt);
    let mut pr = probes.to_vec();
    pr.sort_by_key(|&x| std::cmp::Reverse(key_by_rank(x, &pos)));
    for grp in pr.chunks(g) {
        let gc = grp.iter().fold(!0u64, |a, &x| a & x);
        ts[3] += gc.count_ones() as u64;
        for c in chunks {
            ts[0] += 1; // group tests
            if gc & c.common != 0 { ts[1] += grp.len() as u64; } // probe tests avoided (all would skip)
            else { ts[2] += grp.len() as u64; }
        }
    }
}

fn key_by_rank(m: u64, rankpos: &[u8; 64]) -> u64 {
    let mut k = 0u64; let mut y = m;
    while y != 0 { k |= 1u64 << rankpos[y.trailing_zeros() as usize]; y &= y - 1; }
    k
}
fn rank_from(w: &[f64; 64]) -> ([u8; 64], Vec<usize>) {
    let mut dg: Vec<usize> = (0..64).collect();
    dg.sort_by(|&a, &c| w[c].partial_cmp(&w[a]).unwrap().then(a.cmp(&c)));
    let mut pos = [0u8; 64];
    for (i, &d) in dg.iter().enumerate() { pos[d] = 63 - i as u8; }
    (pos, dg)
}

fn param_early(a: &[String]) -> usize { a.get(4).map(|x| x.parse().unwrap()).unwrap_or(8) }

fn main() {
    let a: Vec<String> = std::env::args().collect();
    let dir = &a[1];
    let scheme = a[2].as_str();
    let every: usize = a.get(3).map(|x| x.parse().unwrap()).unwrap_or(1);
    let (b, roots, adm, ps, ts) = load(dir);
    let m = (b - 1) as usize;
    // pooled frequencies
    let mut fp = [0f64; 64]; let mut ft = [0f64; 64];
    for p in &ps { for v in 0..64 { fp[v] += ((p.mask >> v) & 1) as f64; } }
    for t in &ts { for v in 0..64 { ft[v] += ((t.mask >> v) & 1) as f64; } }
    let mut w = [0f64; 64];
    for v in 0..64 { w[v] = fp[v] * ft[v]; }
    let (pos_pool, dg_pool) = rank_from(&w);
    let rank8: Vec<usize> = dg_pool[..8].to_vec();
    let key8 = |mk: u64| -> u32 { let mut k = 0; for (i, &d) in rank8.iter().enumerate() { k |= (((mk >> d) & 1) as u32) << (7 - i); } k };
    if scheme == "stats" {
        // asymmetry: per-digit presence, pooled
        let np = ps.len() as f64; let nt = ts.len() as f64;
        println!("b {} parents {} tops {} key8 {:?}", b, ps.len(), ts.len(), rank8);
        let mut v: Vec<(usize, f64, f64)> = (0..b as usize).map(|i| (i, ft[i] / nt, fp[i] / np)).collect();
        v.sort_by(|x, y| (y.1 * y.2).partial_cmp(&(x.1 * x.2)).unwrap());
        println!("digit  P(top has)  P(parent has)  product   (sorted by product; first 20, last 5)");
        for x in v.iter().take(20).chain(v.iter().rev().take(5).collect::<Vec<_>>().into_iter().rev()) { println!("{:5} {:10.4} {:12.4} {:9.4}", x.0, x.1, x.2, x.1 * x.2); }
        let sum_t: f64 = (0..64).map(|i| ft[i] / nt).sum(); let sum_p: f64 = (0..64).map(|i| fp[i] / np).sum();
        println!("mean digits per top {:.2}, per parent {:.2}", sum_t, sum_p);
        // co-occurrence lift: top side and parent side, distribution of P(i,j)/(P(i)P(j)) over pairs with P(i),P(j) > 0.05
        for (name, masks) in [("tops", ts.iter().map(|t| t.mask).collect::<Vec<_>>()), ("parents", ps.iter().map(|p| p.mask).collect::<Vec<_>>())] {
            let n = masks.len() as f64;
            let mut f1 = [0f64; 64]; let mut f2 = vec![[0f64; 64]; 64];
            for &mk in &masks {
                let mut y = mk;
                let mut ds = [0usize; 64]; let mut nd = 0;
                while y != 0 { ds[nd] = y.trailing_zeros() as usize; nd += 1; y &= y - 1; }
                for i in 0..nd { f1[ds[i]] += 1.0; for j in 0..nd { f2[ds[i]][ds[j]] += 1.0; } }
            }
            let mut lifts = Vec::new();
            for i in 0..64 { for j in (i + 1)..64 {
                let pi = f1[i] / n; let pj = f1[j] / n;
                if pi > 0.05 && pj > 0.05 { lifts.push((f2[i][j] / n / (pi * pj), i, j)); }
            } }
            lifts.sort_by(|x, y| x.0.partial_cmp(&y.0).unwrap());
            let l = lifts.len();
            let ln: Vec<f64> = lifts.iter().map(|x| x.0.ln()).collect();
            let sd = (ln.iter().map(|x| x * x).sum::<f64>() / l as f64).sqrt();
            println!("{name}: digit pairs {} lift min {:.3} ({},{}) p10 {:.3} median {:.3} p90 {:.3} max {:.3} ({},{}); rms ln-lift {:.3}",
                l, lifts[0].0, lifts[0].1, lifts[0].2, lifts[l / 10].0, lifts[l / 2].0, lifts[9 * l / 10].0, lifts[l - 1].0, lifts[l - 1].1, lifts[l - 1].2, sd);
        }
        return;
    }
    // parent order: stable sort by (cls, 255-key8)
    let mut order: Vec<usize> = (0..ps.len()).collect();
    let dpool: u64 = dg_pool[..param_early(&a)].iter().fold(0u64, |acc, &x| acc | (1u64 << x));
    match scheme {
        "parfull" => order.sort_by_key(|&i| (ps[i].cls, std::cmp::Reverse(key_by_rank(ps[i].mask, &pos_pool)))),
        "parbucket" => order.sort_by_key(|&i| (ps[i].cls, std::cmp::Reverse(key_by_rank(ps[i].mask & dpool, &pos_pool)), 255 - key8(ps[i].mask))),
        _ => order.sort_by_key(|&i| (ps[i].cls, 255 - key8(ps[i].mask))),
    }
    let mut seg = vec![0usize; m + 1];
    { let mut i = 0; for c in 0..m { seg[c] = i; while i < order.len() && ps[order[i]].cls as usize == c { i += 1; } } seg[m] = order.len(); }
    // tops per (d, class)
    let mut tseg: Vec<Vec<u64>> = vec![Vec::new(); b as usize * m];
    for t in &ts { tseg[t.d as usize * m + (t.h % m as u64) as usize].push(t.mask); }
    let param: usize = a.get(4).map(|x| x.parse().unwrap()).unwrap_or(8);
    let mut tot = St::default();
    let mut tr = [0u64; 6];
    let do_trie = std::env::var("TRIE").is_ok();
    let do_cov = std::env::var("COVER").is_ok(); let mut cv = [0u64; 6];
    let two_g: usize = std::env::var("TWO").ok().map(|x| x.parse().unwrap()).unwrap_or(0); let mut tsd = [0u64; 4];
    let do_time = std::env::var("TIME").is_ok(); let mut tm = [0f64; 4]; let mut tcnt = [0u64; 2];
    let mut nblk = 0usize; let mut used = 0usize;
    let mut chunks: Vec<Chunk> = Vec::new();
    for c in 0..m {
        for d in 0..b as u32 {
            nblk += 1;
            if (nblk - 1) % every != 0 { continue; }
            used += 1;
            let cc = (c + d as usize) % m;
            let mut probes: Vec<u64> = Vec::new();
            for &r in &roots { let ct = (r as usize + m - cc) % m; probes.extend_from_slice(&tseg[d as usize * m + ct]); }
            let mut kids: Vec<u64> = Vec::new(); let mut ptag: Vec<u64> = Vec::new();
            for &pi in &order[seg[c]..seg[c + 1]] {
                let p = &ps[pi];
                let e2 = ((p.c2 as u64 + p.a2 as u64 * d as u64) % b) as u32;
                let e3 = ((p.c3 as u64 + p.a3 as u64 * d as u64) % b) as u32;
                if e2 == e3 { continue; }
                let add = (1u64 << e2) | (1u64 << e3);
                if p.mask & add != 0 { continue; }
                kids.push(p.mask | add);
                ptag.push(p.mask & dpool);
            }
            let mut st = St { pairs: (probes.len() * kids.len()) as u64, children: kids.len() as u64, probes: probes.len() as u64, ..Default::default() };
            chunks.clear();
            // block-local weights: probe frequency x child frequency
            let block_rank = || {
                let mut wt = [0f64; 64]; let mut wc = [0f64; 64];
                for &t in &probes { let mut y = t; while y != 0 { wt[y.trailing_zeros() as usize] += 1.0; y &= y - 1; } }
                for &k in &kids { let mut y = k; while y != 0 { wc[y.trailing_zeros() as usize] += 1.0; y &= y - 1; } }
                let mut w = [0f64; 64]; for v in 0..64 { w[v] = wt[v] * wc[v]; }
                rank_from(&w)
            };
            match scheme {
                "g2" | "parfull" => mk_chunks(&kids, 0, 0, &mut chunks),
                "parbucket" => {
                    let mut i = 0;
                    while i < kids.len() {
                        let tag = ptag[i]; let mut j = i;
                        while j < kids.len() && ptag[j] == tag { j += 1; }
                        mk_chunks(&kids[i..j], tag, 0, &mut chunks);
                        i = j;
                    }
                    for &t in &probes { st.visits += 1u64 << (param as u32 - (t & dpool).count_ones()); }
                }
                "random" => {
                    let mut k2 = kids.clone(); let mut s = 0x9E3779B97F4A7C15u64 ^ (c as u64 * 977 + d as u64);
                    for i in (1..k2.len()).rev() { s ^= s << 13; s ^= s >> 7; s ^= s << 17; let j = (s % (i as u64 + 1)) as usize; k2.swap(i, j); }
                    mk_chunks(&k2, 0, 0, &mut chunks)
                }
                "fullpool" => { let mut k2 = kids.clone(); k2.sort_by_key(|&x| std::cmp::Reverse(key_by_rank(x, &pos_pool))); mk_chunks(&k2, 0, 0, &mut chunks) }
                "fullblock" => { let (pos, _) = block_rank(); let mut k2 = kids.clone(); k2.sort_by_key(|&x| std::cmp::Reverse(key_by_rank(x, &pos))); mk_chunks(&k2, 0, 0, &mut chunks) }
                "bucket" => {
                    // presence buckets on the `param` digits of highest probe x child frequency in this block
                    let (pos, dg) = block_rank();
                    let dmask: u64 = dg[..param].iter().fold(0u64, |acc, &x| acc | (1u64 << x));
                    let mut k2 = kids.clone();
                    k2.sort_by_key(|&x| (std::cmp::Reverse(key_by_rank(x & dmask, &pos)), std::cmp::Reverse(key_by_rank(x, &pos))));
                    let mut i = 0;
                    while i < k2.len() {
                        let tag = k2[i] & dmask; let mut j = i;
                        while j < k2.len() && k2[j] & dmask == tag { j += 1; }
                        mk_chunks(&k2[i..j], tag, dmask, &mut chunks);
                        i = j;
                    }
                    // enumeration overhead: each probe enumerates 2^(param - |t & D|) patterns
                    for &t in &probes { st.visits += 1u64 << (param as u32 - (t & dmask).count_ones()); }
                }
                "greedy" => {
                    // greedy chunk formation in the block-ranked order: seed = first unassigned; add the 63
                    // unassigned members (within a window of W) that keep the largest probe-weighted common
                    let (pos, _) = block_rank();
                    let mut wt = [0f64; 64];
                    for &t in &probes { let mut y = t; while y != 0 { wt[y.trailing_zeros() as usize] += 1.0; y &= y - 1; } }
                    let mut k2 = kids.clone(); k2.sort_by_key(|&x| std::cmp::Reverse(key_by_rank(x, &pos)));
                    let win = param.max(64);
                    let mut used_f = vec![false; k2.len()];
                    let mut start = 0;
                    let score = |m: u64| -> f64 { let mut s = 0.0; let mut y = m; while y != 0 { s += wt[y.trailing_zeros() as usize]; y &= y - 1; } s };
                    let mut groups: Vec<u64> = Vec::new();
                    loop {
                        while start < k2.len() && used_f[start] { start += 1; }
                        if start >= k2.len() { break; }
                        used_f[start] = true;
                        let mut com = k2[start]; let mut mem = vec![k2[start]];
                        while mem.len() < 64 {
                            let mut best = usize::MAX; let mut bs = -1.0;
                            for j in start + 1..(start + win).min(k2.len()) {
                                if used_f[j] { continue; }
                                let sc = score(com & k2[j]);
                                if sc > bs { bs = sc; best = j; }
                            }
                            if best == usize::MAX { break; }
                            used_f[best] = true; com &= k2[best]; mem.push(k2[best]);
                        }
                        groups.extend_from_slice(&mem);
                        // pad to a multiple of 64 boundary semantics: mk_chunks on this group alone
                        mk_chunks(&mem, 0, 0, &mut chunks);
                        groups.clear();
                    }
                }
                _ => panic!("scheme"),
            }
            let dorder: [u8; 64] = {
                let mut wc = [0f64; 64];
                for &k in &kids { let mut y = k; while y != 0 { wc[y.trailing_zeros() as usize] += 1.0; y &= y - 1; } }
                let (_, dg) = rank_from(&wc); let mut o = [0u8; 64]; for i in 0..64 { o[i] = dg[i] as u8; } o
            };
            eval(&chunks, &probes, &mut st, &dorder);
            if do_trie { trie_eval(&chunks, &probes, &mut tr); }
            if do_cov { cover_eval(&chunks, &probes, &mut cv); }
            if two_g > 0 { twoside_eval(&chunks, &probes, two_g, &mut tsd); }
            if do_time { time_block(&chunks, &probes, &mut tm, &mut tcnt); }
            tot.add(&st);
        }
    }
    let f = every as f64; // scale sampled blocks to the super-unit
    let per = |x: u64| x as f64 * f / adm;
    println!("{} {} blocks {}/{}: pairs/adm {:.3e} pass/adm {:.3e} (rate {:.2e}) children/adm {:.3e} flat {:.3e} kept {:.3e} (kept frac {:.3}) touch {:.3e} pack {:.3e} | kept/touch {:.2} kept/pack {:.1} | lookups/kept {:.2} visits/adm {:.3e} chunks/adm {:.3e}",
        dir, if scheme == "bucket" || scheme == "greedy" || scheme == "parbucket" { format!("{scheme}:{param}") } else { scheme.to_string() }, used, nblk,
        per(tot.pairs), per(tot.pass), tot.pass as f64 / tot.pairs as f64, per(tot.children), per(tot.flat), per(tot.kept), tot.kept as f64 / (tot.probes as f64 * 0.0 + 1.0).max(1.0) / 1.0 * 0.0 + tot.kept as f64 / tot.flat.max(1) as f64,
        per(tot.touch), per(tot.pack), tot.kept as f64 / tot.touch as f64, tot.kept as f64 / tot.pack as f64,
        tot.lookups as f64 / tot.kept as f64, per(tot.visits), per(tot.chunks));
    if two_g > 0 {
        println!("  TWO-SIDED g={}: group tests/adm {:.3e}; probe-level skip tests avoided {:.3} of flat ({:.3e}/adm); mean group common digits {:.2}",
            two_g, per(tsd[0]), tsd[1] as f64 / (tsd[1] + tsd[2]) as f64, per(tsd[1]), tsd[3] as f64 * two_g as f64 / tot.probes.max(1) as f64 / 1.0);
    }
    if do_time {
        println!("  TIME (CPU, 1 thread): G2 probe loop {:.3}s = {:.2} ns per kept word; trie DFS {:.3}s (+ trie build {:.3}s) = {:.2}x faster; pass pairs {} == {}",
            tm[0], tm[0] * 1e9 / tot.kept as f64, tm[1], tm[2], tm[0] / (tm[1] + tm[2]), tcnt[0], tcnt[1]);
    }
    if do_cov {
        GC.with(|h| { let h = h.borrow(); let tot: u64 = h.iter().sum(); let mut l = String::new(); for k in 1..21 { if h[k] > 0 { l += &format!(" {}:{:.3}", k, h[k] as f64 / tot as f64); } } println!("  greedy cover size (t's digits) of kept non-passing words:{l}"); });
        println!("  COVER: 2-covers per chunk {:.2}, new 3-covers (top-12 digits) per chunk {:.2}; kept non-passing words {:.3e}/adm, of which skippable by a 2-cover {:.3} and additionally by a 3-cover {:.3}",
            cv[0] as f64 / cv[2] as f64, cv[1] as f64 / cv[2] as f64, per(cv[3]), cv[4] as f64 / cv[3] as f64, cv[5] as f64 / cv[3] as f64);
    }
    if do_trie {
        println!("  TRIE: unpruned nodes/adm {:.3e}; computed nodes (lookups)/adm {:.3e} = {:.2} per flat incidence; warp-union nodes x32 /adm {:.3e}; leaf tests/adm {:.3e}; leaves with a pass {:.3e}; chunk passes {:.3e}  [G2: kept x lookups/adm {:.3e}]",
            per(tr[0]), per(tr[1]), tr[1] as f64 / tot.flat as f64, per(tr[2]) * warp_w() as f64, per(tr[3]), per(tr[4]), per(tr[5]), per(tot.lookups));
    }
    // early exit: fraction of kept words certified after j lookups (digits in decreasing child frequency)
    let mut cum = 0u64; let mut line = String::new();
    for j in 1..=20 { cum += tot.ej[j]; line += &format!(" {}:{:.3}", j, cum as f64 / tot.kept as f64); }
    let mean_need: f64 = (0..65).map(|j| j as f64 * tot.ej[j] as f64).sum::<f64>() / (tot.kept - tot.ej[65]) as f64;
    println!("  early-exit cum frac certified by j lookups:{line}; passing words {:.4}; mean j (non-passing) {:.2}; warp-uniform (32 lanes) eff lookups/word {:.2}",
        tot.ej[65] as f64 / tot.kept as f64, mean_need, tot.warp_eff as f64 / tot.warp_n as f64);
}
