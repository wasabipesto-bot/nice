//! N6 counting study (experiment only). Usage:
//!   n6_top_counts <base> <field_size> <fields> <units_per_field> <seed> [warp]
//! Samples `fields` production-shaped fields stratified over the base's range
//! and `units_per_field` random grandparent blocks (depth L − 6, b^6 numbers)
//! inside each; for every top-layer parent (depth L − 5) of a unit it
//! certifies all b² children (depth L − 3 = t, the GPU's (prefix, partition)
//! pairs) and counts schemes. Prints FIELD and UNIT lines of key=value.

use nice_common::base_range::get_base_range_u128;
use nice_common::overlap_join::n6::{below, next_u64};
use nice_common::overlap_join::{Base, W4};
use std::collections::BTreeMap;

#[derive(Default)]
struct C(BTreeMap<String, u64>);
impl C {
    fn add(&mut self, k: &str, n: u64) {
        *self.0.entry(k.to_string()).or_default() += n;
    }
    fn merge(&mut self, o: &C) {
        for (k, v) in &o.0 {
            self.add(k, *v);
        }
    }
    fn line(&self) -> String {
        self.0
            .iter()
            .map(|(k, v)| format!("{k}={v}"))
            .collect::<Vec<_>>()
            .join(" ")
    }
}

const CAP: u32 = 6;
const F0: u32 = 3;

/// Group configurations: nested chunk sizes over the b² children.
fn configs(b: u32) -> Vec<Vec<usize>> {
    let b = b as usize;
    vec![
        vec![4],
        vec![8],
        vec![16],
        vec![32],
        vec![b / 2],
        vec![b],
        vec![2 * b],
        vec![4 * b],
        vec![8 * b],
        vec![b, 8],
        vec![b, 16],
        vec![4 * b, b],
        vec![4 * b, 16],
        vec![4 * b, b, 8],
        vec![8 * b, b, 16, 4],
        vec![16, 4],
        vec![64],
        vec![32, 8],
    ]
}

struct Par {
    p0: u128,
    pass: Vec<bool>,
    /// Skip end per child (best pair): the next child not proven to fail.
    skb: Vec<u16>,
}

/// One lane's walk over children `lo..hi` from `start`: per test,
/// (jumped here from a non-adjacent child or from the walk's start,
/// failed). Returns the events and the reach after the window.
fn walk(par: &Par, lo: usize, hi: usize, start: usize) -> (Vec<(bool, bool)>, usize) {
    let mut ev = Vec::new();
    let mut v = start.max(lo);
    let mut reach = start;
    let mut prev: Option<usize> = None;
    while v < hi {
        let jumped = prev.is_some_and(|p| p + 1 != v);
        let fail = !par.pass[v];
        ev.push((jumped, fail));
        let nxt = if fail { par.skb[v] as usize } else { v + 1 };
        reach = reach.max(nxt);
        prev = Some(v);
        v = nxt.max(v + 1);
    }
    (ev, reach.max(hi.min(reach)))
}

/// Lockstep warp over lanes' event lists: (iterations, iterations where a
/// lane reseeds after a jump, iterations where a lane fails).
fn lockstep(lanes: &[Vec<(bool, bool)>]) -> (u64, u64, u64) {
    let iters = lanes.iter().map(Vec::len).max().unwrap_or(0);
    let (mut rs, mut fl) = (0u64, 0u64);
    for t in 0..iters {
        if lanes.iter().any(|l| l.get(t).is_some_and(|e| e.0)) {
            rs += 1;
        }
        if lanes.iter().any(|l| l.get(t).is_some_and(|e| e.1)) {
            fl += 1;
        }
    }
    (iters as u64, rs, fl)
}

#[allow(clippy::too_many_arguments)]
fn groups(
    base: &Base,
    p0: u128,
    nv: usize,
    w: u128,
    lo: usize,
    hi: usize,
    levels: &[usize],
    pass: &[bool],
    c: &mut C,
    name: &str,
    depth: usize,
) {
    if levels.is_empty() {
        c.add(&format!("{name}_tests"), (hi - lo) as u64);
        c.add(&format!("{name}_L{depth}"), (hi - lo) as u64);
        return;
    }
    let g = levels[0];
    let mut prev_pass = false;
    let mut x = lo;
    while x < hi {
        let y = (x + g).min(hi);
        c.add(&format!("{name}_tests"), 1);
        c.add(&format!("{name}_L{depth}"), 1);
        let pa = (p0 * nv as u128 + x as u128) * w;
        let pe = (p0 * nv as u128 + (y - 1) as u128) * w + w - 1;
        let ok = base.cert(pa, pe, CAP).is_some();
        if ok {
            c.add(&format!("{name}_seeds"), 1);
            if !prev_pass {
                c.add(&format!("{name}_runseeds"), 1);
            }
            groups(base, p0, nv, w, x, y, &levels[1..], pass, c, name, depth + 1);
        } else {
            let v = pass[x..y].iter().filter(|&&p| p).count() as u64;
            c.add(&format!("{name}_viol"), v);
        }
        prev_pass = ok;
        x = y;
    }
}

fn main() {
    let a: Vec<String> = std::env::args().collect();
    let b: u32 = a[1].parse().unwrap();
    let size: u128 = a[2].parse::<f64>().unwrap() as u128;
    let nfields: usize = a[3].parse().unwrap();
    let units: usize = a[4].parse().unwrap();
    let seed: u64 = a[5].parse().unwrap();
    let warp: usize = a.get(6).map_or(32, |x| x.parse().unwrap());
    let range = get_base_range_u128(b).unwrap().unwrap();
    let mut rng = seed ^ (u64::from(b) << 40);
    let cfgs = configs(b);
    let bb = u128::from(b);
    let nv = (bb * bb) as usize;
    let mut total = C::default();
    for f in 0..nfields {
        let r = (next_u64(&mut rng) >> 11) as f64 / (1u64 << 53) as f64;
        let frac = (f as f64 + r) / nfields as f64;
        let at = ((range.size() - size) as f64 * frac) as u128;
        let s = range.start() + at / size * size;
        let e = s + size;
        let mut fc = C::default();
        let Some(base) = Base::try_new(b, s, e - 1) else {
            println!("FIELD b={b} f={f} frac={frac:.4} s={s} lengthchange=1");
            continue;
        };
        let l = base.l;
        let w = base.powu(F0);
        let w5 = base.powu(5);
        let w6 = base.powu(6);
        let fcert = base.cert(s, e - 1, CAP);
        let mut fpars: Vec<Par> = Vec::new();
        let glo = s.div_ceil(w6);
        let ghi = e / w6; // exclusive
        for _u in 0..units {
            let g = glo + below(&mut rng, ghi - glo);
            fc.add("units", 1);
            // Ancestors (depth 1..L-6) and the grandparent itself, clipped.
            let mut anc_ok = true;
            for j in 1..=(l - 6) {
                let ww = base.powu(l - j);
                let pa = g / base.powu(l - 6 - j);
                let lo = (pa * ww).max(s);
                let hi = (pa * ww + ww - 1).min(e - 1);
                if base.cert(lo, hi, CAP).is_none() {
                    anc_ok = false;
                    break;
                }
            }
            if !anc_ok {
                continue;
            }
            fc.add("gp_pass", 1);
            let mut uc = C::default();
            let mut pars: Vec<Par> = Vec::new();
            for u in 0..bb {
                let p0 = g * bb + u;
                uc.add("par_tests", 1);
                let Some(_) = base.cert(p0 * w5, p0 * w5 + w5 - 1, CAP) else {
                    continue;
                };
                uc.add("par_pass", 1);
                let pdet = base.n6_detail(p0 * w5, p0 * w5 + w5 - 1, CAP);
                assert!(pdet.pass);
                let mut pass = vec![false; nv];
                // Segment prefilter: per power, slow positions are those
                // >= X_j = parent.from_j - r_j; combos (r2, r3), r in 0..=3.
                let combos: Vec<(u32, u32)> =
                    (0..=3).flat_map(|r2| (0..=3).map(move |r3| (r2, r3))).collect();
                let mut rej = vec![0u32; nv];
                // Skip ends per child (first pair, best pair), nv if none.
                let mut sk_first = vec![0usize; nv];
                let mut sk_best = vec![0usize; nv];
                let pw = |v: usize, j: usize| -> W4 {
                    let p = p0 * nv as u128 + v as u128;
                    Base::n6_pow(p * w + w - 1, j)
                };
                for v in 0..nv {
                    let p = p0 * nv as u128 + v as u128;
                    let (ca, ce) = (p * w, p * w + w - 1);
                    let det = base.n6_detail(ca, ce, CAP);
                    if v % 7 == 0 {
                        let cc = base.cert(ca, ce, CAP);
                        uc.add("chk_n", 1);
                        if cc.is_some() != det.pass || (det.pass && cc != Some(det.mask)) {
                            uc.add("chk_bad", 1);
                        }
                    }
                    pass[v] = det.pass;
                    uc.add("tests", 1);
                    // New digits relative to the parent.
                    for pi in 0..2 {
                        let nnew = pdet.from[pi].saturating_sub(det.from[pi]);
                        uc.add(&format!("newdig_{pi}_{nnew}"), 1);
                    }
                    if det.pass {
                        uc.add("pass", 1);
                        sk_first[v] = v + 1;
                        sk_best[v] = v + 1;
                        continue;
                    }
                    if det.closure_fail {
                        uc.add("f_closure", 1);
                        sk_first[v] = v + 1;
                        sk_best[v] = v + 1;
                        continue;
                    }
                    uc.add("f_dup", 1);
                    let ((pa_, qa), (pb_, qb)) = det.first_pair.unwrap();
                    let kind = match (pa_, pb_) {
                        (0, 0) => "sqsq",
                        (1, 1) => "cucu",
                        _ => "sqcu",
                    };
                    uc.add(&format!("f_{kind}"), 1);
                    let par_a = qa >= pdet.from[pa_];
                    let par_b = qb >= pdet.from[pb_];
                    let rel = match (par_a, par_b) {
                        (true, true) => "parpar",
                        (false, false) => "newnew",
                        _ => "newpar",
                    };
                    uc.add(&format!("f_{rel}"), 1);
                    // Offsets of the new occurrences below the parent's from.
                    for (pi, q, par) in [(pa_, qa, par_a), (pb_, qb, par_b)] {
                        if !par {
                            let off = pdet.from[pi] - q;
                            uc.add(&format!("f_newoff_{pi}_{off}"), 1);
                        }
                    }
                    // All occurrences of repeated digits.
                    let mut occ: Vec<Vec<(usize, u32)>> = vec![Vec::new(); 64];
                    for pi in 0..2 {
                        for &(pos, d) in &det.common[pi] {
                            occ[d as usize].push((pi, pos));
                        }
                    }
                    let sp = [base.s2, base.s3];
                    // Smallest top depth m catching some repeat.
                    let mut best_m = u32::MAX;
                    let ax = [Base::n6_pow(ca, 0), Base::n6_pow(ca, 1)];
                    let run_end = |pi: usize, pos: u32| -> usize {
                        let bound = base.n6_next_boundary(ax[pi], pos);
                        // first v' > v with pw(v', pi) >= bound
                        if pw(nv - 1, pi).lt(&bound) {
                            return nv;
                        }
                        let (mut lo, mut hi) = (v + 1, nv - 1);
                        while lo < hi {
                            let mid = (lo + hi) / 2;
                            if pw(mid, pi).lt(&bound) {
                                lo = mid + 1;
                            } else {
                                hi = mid;
                            }
                        }
                        lo
                    };
                    for (ci, &(r2, r3)) in combos.iter().enumerate() {
                        let xs = [pdet.from[0].saturating_sub(r2), pdet.from[1].saturating_sub(r3)];
                        let slow = |pi: usize, q: u32| q >= xs[pi] && det.from[pi] <= xs[pi];
                        let hit = occ.iter().any(|o| o.iter().filter(|&&(pi, q)| slow(pi, q)).count() >= 2);
                        if hit {
                            rej[v] |= 1 << ci;
                        }
                    }
                    let mut best_skip = v + 1;
                    for o in &occ {
                        if o.len() < 2 {
                            continue;
                        }
                        let mut depths: Vec<u32> = o.iter().map(|&(pi, q)| sp[pi] - q).collect();
                        depths.sort_unstable();
                        best_m = best_m.min(depths[1]);
                        let mut ends: Vec<usize> = o.iter().map(|&(pi, q)| run_end(pi, q)).collect();
                        ends.sort_unstable_by(|x, y| y.cmp(x));
                        best_skip = best_skip.max(ends[1]);
                    }
                    uc.add(&format!("f_depth_{best_m}"), 1);
                    let first_skip = run_end(pa_, qa).min(run_end(pb_, qb)).max(v + 1);
                    sk_first[v] = first_skip;
                    sk_best[v] = best_skip;
                    uc.add("f_skipF_sum", (first_skip - v - 1) as u64);
                    uc.add("f_skipB_sum", (best_skip - v - 1) as u64);
                }
                for (ci, &(r2, r3)) in combos.iter().enumerate() {
                    let nm = format!("seg{r2}{r3}");
                    let xs = [pdet.from[0].saturating_sub(r2), pdet.from[1].saturating_sub(r3)];
                    // Boundaries: changes of floor(n^j / b^X_j) over the parent
                    // (only for powers with r > 0).
                    let mut bnd = 0u64;
                    for (pi, r) in [(0usize, r2), (1, r3)] {
                        if r == 0 {
                            continue;
                        }
                        let lo = Base::n6_pow(p0 * w5, pi);
                        let hi = Base::n6_pow(p0 * w5 + w5 - 1, pi);
                        let fl = |x: W4| base.n6_next_boundary(x, xs[pi]);
                        // count boundaries by stepping boundary to boundary
                        let mut x = lo;
                        loop {
                            let nb = fl(x);
                            if hi.lt(&nb) {
                                break;
                            }
                            bnd += 1;
                            x = nb;
                        }
                    }
                    uc.add(&format!("{nm}_bnd"), bnd);
                    let mut runs = 0u64;
                    let mut kept = 0u64;
                    let mut prev = false;
                    for v in 0..nv {
                        let k = rej[v] & (1 << ci) == 0;
                        if k {
                            kept += 1;
                            if !prev {
                                runs += 1;
                            }
                        } else if pass[v] {
                            uc.add(&format!("{nm}_viol"), 1);
                        }
                        prev = k;
                    }
                    uc.add(&format!("{nm}_kept"), kept);
                    uc.add(&format!("{nm}_runs"), runs);
                }
                // Fail runs along v, conditional on the previous child.
                let mut runlen = 0usize;
                for v in 0..nv {
                    if v > 0 {
                        let k = match (pass[v - 1], pass[v]) {
                            (false, false) => "ff",
                            (false, true) => "fp",
                            (true, false) => "pf",
                            (true, true) => "pp",
                        };
                        uc.add(&format!("adj_{k}"), 1);
                    }
                    if pass[v] {
                        if runlen > 0 {
                            uc.add(&format!("frun_{}", usize::BITS - runlen.leading_zeros()), 1);
                            uc.add(&format!("frunw_{}", usize::BITS - runlen.leading_zeros()), runlen as u64);
                        }
                        runlen = 0;
                    } else {
                        runlen += 1;
                    }
                }
                if runlen > 0 {
                    uc.add(&format!("frun_{}", usize::BITS - runlen.leading_zeros()), 1);
                    uc.add(&format!("frunw_{}", usize::BITS - runlen.leading_zeros()), runlen as u64);
                }
                let np = pass.iter().filter(|&&x| x).count();
                let bin = if np == 0 { 0 } else { 1 + (np * 10 - 1) / nv };
                uc.add(&format!("parfrac_{bin}"), 1);
                // Group schemes.
                for cfg in &cfgs {
                    let name = format!(
                        "g{}",
                        cfg.iter().map(ToString::to_string).collect::<Vec<_>>().join("-")
                    );
                    groups(&base, p0, nv, w, 0, nv, cfg, &pass, &mut uc, &name, 0);
                }
                // Skip-ahead walks (whole b² span, one lane per parent).
                for (nm, sk) in [("skipF", &sk_first), ("skipB", &sk_best)] {
                    let (mut v, mut tests, mut skips) = (0usize, 0u64, 0u64);
                    while v < nv {
                        tests += 1;
                        if sk[v] > v + 1 {
                            skips += 1;
                            // Exactness: every child jumped over fails.
                            let bad = pass[v + 1..sk[v]].iter().filter(|&&x| x).count();
                            uc.add(&format!("{nm}_viol"), bad as u64);
                        }
                        v = sk[v];
                    }
                    uc.add(&format!("{nm}_tests"), tests);
                    uc.add(&format!("{nm}_skips"), skips);
                }
                pars.push(Par {
                    p0,
                    pass,
                    skb: sk_best.iter().map(|&x| x as u16).collect(),
                });
            }
            // Sibling parents (consecutive p0, both in the layer), same v.
            for pr in pars.windows(2) {
                if pr[1].p0 != pr[0].p0 + 1 {
                    continue;
                }
                for v in 0..nv {
                    let k = match (pr[0].pass[v], pr[1].pass[v]) {
                        (false, false) => "ff",
                        (false, true) => "fp",
                        (true, false) => "pf",
                        (true, true) => "pp",
                    };
                    uc.add(&format!("sib_{k}"), 1);
                }
            }
            println!("UNIT b={b} f={f} g={g} {}", uc.line());
            fc.merge(&uc);
            fpars.extend(pars);
        }
        // Warps of random layer parents (the layer is sorted by group, so a
        // warp's lanes are unrelated parents), in lockstep.
        for i in (1..fpars.len()).rev() {
            let j = (next_u64(&mut rng) % (i as u64 + 1)) as usize;
            fpars.swap(i, j);
        }
        // A warp per parent, lanes over W consecutive partitions (lane l
        // steps its own FD chain by W); after a span every lane's skip end
        // is known, and the warp jumps to their reach (all lanes reseed).
        for par in &fpars {
            for &wd in &[16usize, 32] {
                let (mut v, mut spans, mut jumps, mut tests, mut failsp) = (0usize, 0u64, 0u64, 0u64, 0u64);
                while v < nv {
                    let hi = (v + wd).min(nv);
                    spans += 1;
                    tests += (hi - v) as u64;
                    let mut reach = hi;
                    let mut anyfail = false;
                    for u in v..hi {
                        if !par.pass[u] {
                            anyfail = true;
                            reach = reach.max(par.skb[u] as usize);
                        }
                    }
                    if anyfail {
                        failsp += 1;
                    }
                    if reach > hi {
                        jumps += 1;
                        for u in hi..reach.min(nv) {
                            if par.pass[u] {
                                fc.add(&format!("span{wd}_viol"), 1);
                            }
                        }
                    }
                    v = reach;
                }
                fc.add(&format!("span{wd}_spans"), spans);
                fc.add(&format!("span{wd}_jumps"), jumps);
                fc.add(&format!("span{wd}_tests"), tests);
                fc.add(&format!("span{wd}_failspans"), failsp);
            }
            fc.add("span_pairs", nv as u64);
        }
        for wchunk in fpars.chunks(warp) {
            if wchunk.len() < warp {
                break;
            }
            fc.add("w_warps", 1);
            fc.add("w_today_iters", nv as u64);
            // Whole span per lane.
            let lanes: Vec<Vec<(bool, bool)>> = wchunk.iter().map(|p| walk(p, 0, nv, 0).0).collect();
            let (it, rs, fl) = lockstep(&lanes);
            fc.add("w_full_iters", it);
            fc.add("w_full_reseed", rs);
            fc.add("w_full_failit", fl);
            fc.add("w_full_lanetests", lanes.iter().map(|l| l.len() as u64).sum());
            // Batches of `slots` consecutive partitions; a lane's reach
            // (skip-until) persists across batches.
            for &slots in &[16usize, 64, 256] {
                let mut reach = vec![0usize; wchunk.len()];
                let (mut it, mut rs, mut fl, mut act, mut wins, mut lt) = (0, 0, 0, 0u64, 0u64, 0u64);
                let mut lo = 0;
                while lo < nv {
                    let hi = (lo + slots).min(nv);
                    let lanes: Vec<Vec<(bool, bool)>> = wchunk
                        .iter()
                        .zip(reach.iter_mut())
                        .map(|(p, r)| {
                            let (ev, nr) = walk(p, lo, hi, *r);
                            *r = nr.max(*r);
                            ev
                        })
                        .collect();
                    let (a, bq, cq) = lockstep(&lanes);
                    it += a;
                    rs += bq;
                    fl += cq;
                    wins += 1;
                    lt += lanes.iter().map(|l| l.len() as u64).sum::<u64>();
                    if a > 0 {
                        act += 1;
                    }
                    lo = hi;
                }
                fc.add(&format!("w_b{slots}_iters"), it);
                fc.add(&format!("w_b{slots}_reseed"), rs);
                fc.add(&format!("w_b{slots}_failit"), fl);
                fc.add(&format!("w_b{slots}_active"), act);
                fc.add(&format!("w_b{slots}_windows"), wins);
                fc.add(&format!("w_b{slots}_lanetests"), lt);
            }
        }
        println!(
            "FIELD b={b} f={f} frac={frac:.4} s={s} L={l} fc_ok={} {}",
            u8::from(fcert.is_some()),
            fc.line()
        );
        total.merge(&fc);
    }
    println!("TOTAL b={b} {}", total.line());
}
