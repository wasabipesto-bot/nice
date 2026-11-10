//! N1 experiment (2026-11-10, not for merging): the join at the
//! "transversal" shape, a base's whole range as the field and one partition
//! value as the unit of work. Exactness tests, operation counts and timing.
//! Everything here is opt-in (`#[ignore]`, driven by `N1_*` variables) except
//! the small exactness tests.

use super::{CpuJoin, JoinCounts, PartitionResult, Scratch, SurvMode, Top};
use crate::FieldSize;
use crate::base_range::get_base_range_u128;
use crate::client_process::get_is_nice;
use crate::overlap_join::test_fields::mid_mirror_wide;
use crate::overlap_join::{Base, JoinParams, join_range};
use std::time::Instant;

/// splitmix64.
fn next_u64(x: &mut u64) -> u64 {
    *x = x.wrapping_add(0x9E37_79B9_7F4A_7C15);
    let mut z = *x;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58_476D_1CE4_E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D0_49BB_1331_11EB);
    z ^ (z >> 31)
}

/// `count` distinct values below `n`, in drawing order.
fn sample(seed: u64, n: u32, count: usize) -> Vec<u32> {
    let mut x = seed;
    let mut out = Vec::new();
    while out.len() < count.min(n as usize) {
        #[allow(clippy::cast_possible_truncation)]
        let v = (((next_u64(&mut x) >> 32) * u64::from(n)) >> 32) as u32;
        if !out.contains(&v) {
            out.push(v);
        }
    }
    out
}

/// The base's whole valid range.
fn whole(b: u32) -> FieldSize {
    get_base_range_u128(b)
        .expect("base range")
        .expect("a base with a range")
}

/// The shape `(t, k, p)` for `f0`, `k` and no key level at length `l`.
fn shape(l: u32, f0: u32, k: u32) -> JoinParams {
    JoinParams {
        t: l - f0,
        k,
        p: k - f0,
    }
}

/// The CPU join's tops for partition `v`, every key (as `run` makes them).
fn all_tops(join: &CpuJoin, v: u32) -> Vec<Top> {
    let (mut out, mut tops) = (Vec::new(), Vec::new());
    for key in 0..join.keyspace as usize {
        let (lo, hi) = (join.key_off[key] as usize, join.key_off[key + 1] as usize);
        join.tops(v, &join.fs.tlay[lo..hi], &mut tops);
        out.extend_from_slice(&tops);
    }
    out
}

/// What one partition gave: AND survivors, prefilter survivors, hits (all
/// sorted).
#[derive(Debug, PartialEq, Eq, Default)]
struct Unit {
    and: Vec<u128>,
    pre: Vec<u128>,
    hits: Vec<u128>,
}

/// The fast CPU join on partition `v`: twice, once stopping at the AND (its
/// survivors), once in full (prefilter survivors and hits).
fn cpu_unit(join: &mut CpuJoin, v: u32, sc: &mut Scratch) -> Unit {
    let mut u = Unit::default();
    join.mode = SurvMode::AndOnly;
    let r1 = join.run(v, sc, Some(&mut u.and));
    join.mode = SurvMode::Full;
    let r2 = join.run(v, sc, Some(&mut u.pre));
    assert_eq!(r1.survivors, r2.survivors);
    assert_eq!(r1.survivors as usize, u.and.len());
    assert_eq!(r2.checked as usize, u.pre.len());
    u.hits = r2.hits;
    u.and.sort_unstable();
    u.pre.sort_unstable();
    u.hits.sort_unstable();
    u
}

/// The reference join on partition `v` at the join's own shape.
fn ref_unit(join: &CpuJoin, v: u32) -> Unit {
    let fs = &join.fs;
    let mut u = Unit::default();
    let st = join_range(
        &fs.base,
        fs.s,
        fs.e,
        fs.jp,
        Some(&[u128::from(v)]),
        Some(&mut u.and),
    );
    u.and.sort_unstable();
    u.pre = u
        .and
        .iter()
        .copied()
        .filter(|&n| mid_mirror_wide(fs, n))
        .collect();
    u.hits = st.hits;
    u.hits.sort_unstable();
    u
}

/// Survivors by definition, n by n (as `overlap_join`'s test `brute`): the
/// residue class, the k low digits of n² and n³ distinct, the top
/// certificate of n's block, and the AND.
fn brute(base: &Base, s: u128, e: u128, jp: JoinParams) -> Vec<u128> {
    let bb = u128::from(base.b);
    let w_t = bb.pow(base.l - jp.t);
    let bk = bb.pow(jp.k);
    let roots: Vec<u128> = base.roots.iter().map(|&r| u128::from(r)).collect();
    let mut surv = Vec::new();
    for n in s..e {
        if !roots.contains(&(n % (bb - 1))) {
            continue;
        }
        let r = n % bk;
        let (mut x2, mut x3) = ((r * r) % bk, ((r * r) % bk * r) % bk);
        let mut bm = 0u64;
        let mut ok = true;
        for _ in 0..jp.k {
            for d in [x2 % bb, x3 % bb] {
                let bit = 1u64 << d;
                ok &= bm & bit == 0;
                bm |= bit;
            }
            x2 /= bb;
            x3 /= bb;
        }
        if !ok {
            continue;
        }
        let p = n / w_t;
        let lo = (p * w_t).max(s);
        let hi = (p * w_t + w_t - 1).min(e - 1);
        let Some(tm) = base.cert(lo, hi, jp.k) else {
            continue;
        };
        if tm & bm == 0 {
            surv.push(n);
        }
    }
    surv
}

/// Whole-base units at `jp` for every partition value: the fast join
/// against the reference unit by unit (AND survivors, prefilter survivors,
/// hits), and the union against brute force (if `brute_force`) and against
/// the reference at `today` (a contiguous-style shape) over the whole base.
#[allow(clippy::cast_possible_truncation)]
fn whole_base_exact(b: u32, jp: JoinParams, today: JoinParams, brute_force: bool) -> String {
    let t0 = Instant::now();
    let range = whole(b);
    let (s, e) = (range.start(), range.end());
    let mut join = CpuJoin::new_experiment(b, &range, jp).expect("setup");
    let plain_fd = join.fd.is_some();
    let mut plain = CpuJoin::new_experiment(b, &range, jp).expect("setup");
    plain.fd = None;
    let mut sc = Scratch::default();
    let (mut and_all, mut pre_all, mut hits_all) = (Vec::new(), Vec::new(), Vec::new());
    for v in 0..join.partitions() {
        assert_eq!(all_tops(&join, v), all_tops(&plain, v), "b{b} {jp:?} v {v}: tops");
        let got = cpu_unit(&mut join, v, &mut sc);
        let want = ref_unit(&join, v);
        assert_eq!(got.and, want.and, "b{b} {jp:?} v {v}: AND survivors");
        assert_eq!(got.pre, want.pre, "b{b} {jp:?} v {v}: prefilter survivors");
        assert_eq!(got.hits, want.hits, "b{b} {jp:?} v {v}: hits");
        and_all.extend(got.and);
        pre_all.extend(got.pre);
        hits_all.extend(got.hits);
    }
    and_all.sort_unstable();
    pre_all.sort_unstable();
    hits_all.sort_unstable();
    // The same n through the reference at a contiguous-style shape.
    let base_t = Base::try_new(b, s, e - 1).expect("base");
    let mut rec_t = Vec::new();
    let st_t = join_range(&base_t, s, e, today, None, Some(&mut rec_t));
    let mut hits_t = st_t.hits.clone();
    hits_t.sort_unstable();
    assert_eq!(hits_all, hits_t, "b{b}: hits at {jp:?} vs {today:?}");
    let mut line = format!(
        "b{b} [{s}, {e}) {jp:?} ({} units, stepped tops {plain_fd}): AND survivors {}, prefilter \
         survivors {}, hits {hits_all:?} == reference unit by unit; reference at {today:?}: \
         {} survivors, same hits",
        join.partitions(),
        and_all.len(),
        pre_all.len(),
        rec_t.len()
    );
    if brute_force {
        assert_eq!(and_all, brute(&base_t, s, e, jp), "b{b} {jp:?}: brute survivors");
        rec_t.sort_unstable();
        assert_eq!(rec_t, brute(&base_t, s, e, today), "b{b} {today:?}: brute");
        let nice: Vec<u128> = (s..e).filter(|&n| get_is_nice(n, b)).collect();
        assert_eq!(hits_all, nice, "b{b}: brute nice numbers");
        line += "; == brute force (both shapes' survivors, the nice numbers)";
    }
    line += &format!(" [{:.1}s]", t0.elapsed().as_secs_f64());
    eprintln!("N1 EXACT {line}");
    line
}

/// Task 2(b): whole-base units at small bases, every partition value.
/// Brute force up to b30; b33/b34/b40 through the reference only. At b10
/// the unit is n's last digit (and finds 69).
#[test]
#[ignore = "N1 experiment; minutes"]
fn n1_whole_base_units_are_exact_at_small_bases() {
    let mut out = Vec::new();
    // (base, f0, k, today's-kind shape (t, k, p), brute force)
    let cases: &[(u32, u32, u32, (u32, u32, u32), bool)] = &[
        (10, 0, 1, (2, 1, 0), true),
        (12, 1, 2, (2, 2, 0), true),
        (14, 1, 2, (2, 2, 1), true),
        (17, 2, 3, (3, 2, 1), true),
        (18, 2, 3, (3, 2, 1), true),
        (20, 2, 3, (3, 2, 1), true),
        (22, 2, 4, (3, 3, 1), true),
        (24, 2, 4, (3, 3, 1), true),
        (25, 2, 4, (3, 3, 1), true),
        (28, 2, 5, (4, 3, 1), true),
        (29, 2, 5, (4, 3, 1), true),
        (30, 2, 5, (4, 3, 1), true),
        (33, 3, 6, (5, 4, 2), false),
        (34, 3, 6, (5, 4, 2), false),
    ];
    let only: Option<u32> = std::env::var("N1_BASE").ok().and_then(|v| v.parse().ok());
    for &(b, f0, k, (t, tk, tp), bf) in cases {
        if only.is_some_and(|o| o != b) {
            continue;
        }
        let l = Base::try_new(b, whole(b).start(), whole(b).end() - 1)
            .expect("base")
            .l;
        let jp = shape(l, f0, k);
        out.push(whole_base_exact(b, jp, JoinParams { t, k: tk, p: tp }, bf));
    }
    for l in out {
        println!("N1 EXACT {l}");
    }
}

/// Task 2(b) at base 40 (L = 8): shape (f0 3, k 7, p 4); `N1_B40` random
/// units of the 40^4 (every one would take hours) against the reference
/// unit by unit (AND survivors, prefilter survivors, hits, stepped tops).
#[test]
#[ignore = "N1 experiment; long"]
fn n1_whole_base_units_are_exact_at_base_40() {
    let Ok(n) = std::env::var("N1_B40") else {
        return;
    };
    let n: usize = n.parse().expect("N1_B40: a unit count");
    let t = Instant::now();
    let range = whole(40);
    let jp = shape(8, 3, 7);
    let mut join = CpuJoin::new_experiment(40, &range, jp).expect("setup");
    let mut plain = CpuJoin::new_experiment(40, &range, jp).expect("setup");
    plain.fd = None;
    let mut sc = Scratch::default();
    let (mut and, mut pre, mut hits) = (0, 0, 0);
    for v in sample(0x40, join.partitions(), n) {
        assert_eq!(all_tops(&join, v), all_tops(&plain, v), "b40 v {v}: tops");
        let got = cpu_unit(&mut join, v, &mut sc);
        let want = ref_unit(&join, v);
        assert_eq!(got, want, "b40 {jp:?} v {v}");
        and += got.and.len();
        pre += got.pre.len();
        hits += got.hits.len();
    }
    println!(
        "N1 EXACT b40 {jp:?}: {n} random units of {}: {and} AND survivors, {pre} prefilter \
         survivors, {hits} hits: fast join == reference on every unit [{:.0}s]",
        join.partitions(),
        t.elapsed().as_secs_f64()
    );
}

/// Task 2(c): `N1_EXACT_PARTS` (default 20) random partition values of the
/// production-sized whole-base shape `(L − 4, 9, 5)` at `N1_BASE` (default
/// 54): fast join = reference (AND survivors, prefilter survivors, hits),
/// and stepped tops = divided tops.
#[test]
#[ignore = "N1 experiment; minutes"]
fn n1_transversal_units_match_the_reference() {
    let b: u32 = std::env::var("N1_BASE").map_or(54, |v| v.parse().expect("N1_BASE"));
    let count: usize = std::env::var("N1_EXACT_PARTS").map_or(20, |v| v.parse().expect("count"));
    let range = whole(b);
    let base = Base::try_new(b, range.start(), range.end() - 1).expect("base");
    let jp = shape(base.l, 4, 9);
    let t = Instant::now();
    let mut join = CpuJoin::new_experiment(b, &range, jp).expect("setup");
    eprintln!(
        "b{b} {jp:?}: setup {:.1}s, tlay {}, bpre {}, k2 {}, lean {}, wide {}, fd {}",
        t.elapsed().as_secs_f64(),
        join.fs.tlay.len(),
        join.fs.bp_r.len(),
        join.fs.k2,
        join.lean,
        join.wide,
        join.fd.is_some()
    );
    let mut plain = CpuJoin::new_experiment(b, &range, jp).expect("setup");
    plain.fd = None;
    let mut sc = Scratch::default();
    let (mut and, mut pre, mut hits, mut tops) = (0, 0, 0, 0);
    for v in sample(0xB54 + u64::from(b), join.partitions(), count) {
        let tt = all_tops(&join, v);
        assert_eq!(tt, all_tops(&plain, v), "b{b} v {v}: tops");
        let got = cpu_unit(&mut join, v, &mut sc);
        let want = ref_unit(&join, v);
        assert_eq!(got.and, want.and, "b{b} v {v}: AND survivors");
        assert_eq!(got.pre, want.pre, "b{b} v {v}: prefilter survivors");
        assert_eq!(got.hits, want.hits, "b{b} v {v}: hits");
        and += got.and.len();
        pre += got.pre.len();
        hits += got.hits.len();
        tops += tt.len();
        eprintln!(
            "b{b} v {v}: {} tops, {} AND survivors, {} prefilter survivors: equal",
            tt.len(),
            got.and.len(),
            got.pre.len()
        );
    }
    println!(
        "N1 EXACT-C b{b} {jp:?}: {count} random units, {tops} tops, {and} AND survivors, {pre} \
         prefilter survivors, {hits} hits: fast join == reference on every unit"
    );
}

/// One measured unit: the counts (full mode), and the scan's seconds in the
/// three survivor modes.
struct Measured {
    counts: JoinCounts,
    res: PartitionResult,
    scan: [f64; 3],
    total: [f64; 3],
}

fn measure(join: &mut CpuJoin, v: u32, sc: &mut Scratch) -> Measured {
    let mut scan = [0.0; 3];
    let mut total = [0.0; 3];
    let mut counts = JoinCounts::default();
    let mut res = PartitionResult::default();
    // `N1_FULL_ONLY`: the full mode only (no split of the survivor path).
    let modes: &[SurvMode] = if std::env::var("N1_FULL_ONLY").is_ok() {
        &[SurvMode::Full]
    } else {
        &[SurvMode::Full, SurvMode::NoCheck, SurvMode::AndOnly]
    };
    for (i, &mode) in modes.iter().enumerate() {
        join.mode = mode;
        let mut c = JoinCounts::default();
        let t = Instant::now();
        let r = join.run_partition_counted(v, sc, None, &mut c);
        total[i] = t.elapsed().as_secs_f64();
        scan[i] = c.t_scan;
        if i == 0 {
            counts = c;
            res = r;
        }
    }
    join.mode = SurvMode::Full;
    Measured {
        counts,
        res,
        scan,
        total,
    }
}

/// A shape under test at one base: the join, its admissible n per unit,
/// and its units.
struct Subject {
    name: String,
    join: CpuJoin,
    admissible: f64,
    units: Vec<u32>,
    setup: f64,
}

#[allow(clippy::cast_precision_loss)]
fn subjects(b: u32, shapes: &[String], parts: usize) -> Vec<Subject> {
    let range = whole(b);
    let base = Base::try_new(b, range.start(), range.end() - 1).expect("base");
    let roots = base.roots.len() as f64 / f64::from(b - 1);
    let mut out = Vec::new();
    for name in shapes {
        let t = Instant::now();
        let (join, field) = if name.starts_with("today") {
            // A production field (1e17 at b62, else 1e16; mid-base, or at
            // the fraction after `@`), and its CPU slice 0 as the client
            // runs it.
            let frac: f64 = name.split('@').nth(1).map_or(0.5, |f| f.parse().expect("today@f"));
            let size: u128 = if b == 62 { 100_000_000_000_000_000 } else { 10_000_000_000_000_000 };
            #[allow(clippy::cast_possible_truncation, clippy::cast_sign_loss)]
            let at = ((range.size() - size) as f64 * frac) as u128;
            let s = range.start() + at / size * size;
            let (jp, slices) =
                super::slices_for(b, &FieldSize::new(s, s + size)).expect("a join field");
            let sl = slices[0];
            (CpuJoin::new(b, &sl, jp).expect("setup"), sl)
        } else {
            // `f0-k[-p][a]`: `a` takes the affine bottom extension.
            let affine = name.ends_with('a');
            let f: Vec<u32> = name
                .trim_end_matches('a')
                .split('-')
                .map(|x| x.parse().expect("f0-k[-p][a]"))
                .collect();
            let mut jp = shape(base.l, f[0], f[1]);
            if let Some(&p) = f.get(2) {
                // A key level (p = o − 1) or a shorter partition.
                jp.p = p;
            }
            let mut join = CpuJoin::new_experiment(b, &range, jp).expect("setup");
            if affine {
                join.enable_affine_extend();
            }
            (join, range)
        };
        let setup = t.elapsed().as_secs_f64();
        let nparts = join.partitions();
        let admissible = field.size() as f64 * roots / f64::from(nparts);
        let units = if name.starts_with("today") {
            let live = crate::overlap_join::test_fields::live_partitions(&join.fs);
            sample(0x7E57 + u64::from(b), u32::try_from(live.len()).expect("len"), parts)
                .into_iter()
                .map(|i| live[i as usize])
                .collect()
        } else {
            sample(0x9E1 + u64::from(b), nparts, parts)
        };
        eprintln!(
            "N1 SETUP b{b} {name} {:?} field [{}, {}) setup {setup:.2}s: units {nparts}, \
             admissible/unit {admissible:.4e}, tlay {}, bpre {}, k2 {}, lean {}, wide {}, fd {}, fc {} digits",
            join.fs.jp,
            field.start(),
            field.end(),
            join.fs.tlay.len(),
            join.fs.bp_r.len(),
            join.fs.k2,
            join.lean,
            join.wide,
            join.fd.is_some(),
            join.fs.fc.count_ones()
        );
        out.push(Subject {
            name: name.clone(),
            join,
            admissible,
            units,
            setup,
        });
    }
    out
}

/// Tasks 3 and 4: counts and timing. `N1_BASES` (default 60,62,64),
/// `N1_SHAPES` (default `today,4-9`; `f0-k` is the whole-base shape with
/// p = k − f0), `N1_PARTS` units per shape (default 24), `N1_ROUNDS`
/// (default 3). One thread; the shapes' units are interleaved; each unit
/// runs in the three survivor modes. One JSON line per unit and round on
/// stdout (`N1 UNIT {...}`).
#[test]
#[ignore = "N1 experiment; timing"]
#[allow(clippy::cast_precision_loss)]
fn n1_counts_and_timing() {
    let bases: Vec<u32> = std::env::var("N1_BASES")
        .unwrap_or_else(|_| "60,62,64".into())
        .split(',')
        .map(|x| x.trim().parse().expect("N1_BASES"))
        .collect();
    let shapes: Vec<String> = std::env::var("N1_SHAPES")
        .unwrap_or_else(|_| "today,4-9".into())
        .split(',')
        .map(|x| x.trim().to_string())
        .collect();
    let parts: usize = std::env::var("N1_PARTS").map_or(24, |v| v.parse().expect("N1_PARTS"));
    let rounds: usize = std::env::var("N1_ROUNDS").map_or(3, |v| v.parse().expect("N1_ROUNDS"));
    for &b in &bases {
        let mut subs = subjects(b, &shapes, parts);
        let mut sc: Vec<Scratch> = subs.iter().map(|_| Scratch::default()).collect();
        for round in 0..rounds {
            for i in 0..parts {
                for (s, scratch) in subs.iter_mut().zip(sc.iter_mut()) {
                    let Some(&v) = s.units.get(i) else { continue };
                    let m = measure(&mut s.join, v, scratch);
                    let c = &m.counts;
                    println!(
                        "N1 UNIT {}",
                        serde_json::json!({
                            "base": b, "shape": s.name, "jp": format!("{:?}", s.join.fs.jp),
                            "round": round, "v": v, "admissible": s.admissible,
                            "setup_s": s.setup,
                            "top_tests": c.top_tests, "tops": c.tops,
                            "bottom_cands": c.bottom_cands, "bottoms_ext": c.bottoms_ext,
                            "bottoms": c.bottoms, "ands": c.ands,
                            "survivors": m.res.survivors, "checked": m.res.checked,
                            "hits": m.res.hits.len(),
                            "t_tops": c.t_tops, "t_extend": c.t_extend, "t_list": c.t_list,
                            "t_scan_full": m.scan[0], "t_scan_nocheck": m.scan[1],
                            "t_scan_andonly": m.scan[2],
                            "t_total_full": m.total[0], "t_total_nocheck": m.total[1],
                            "t_total_andonly": m.total[2],
                        })
                    );
                }
            }
            eprintln!("N1 b{b} round {round} done");
        }
    }
}

/// Task 5: the affine extension gives the exact extension's rows, on
/// `N1_EXACT_PARTS` (default 40) random units at bases 54, 60, 62, 64 of the
/// shape `(L − 4, 9, 5)`, and on the test windows' and production fields'
/// partitions where it applies.
#[test]
#[ignore = "N1 experiment; a minute"]
fn n1_affine_extension_equals_the_exact_one() {
    let count: usize = std::env::var("N1_EXACT_PARTS").map_or(40, |v| v.parse().expect("count"));
    for b in [54u32, 60, 62, 64] {
        let range = whole(b);
        let base = Base::try_new(b, range.start(), range.end() - 1).expect("base");
        let jp = shape(base.l, 4, 9);
        let exact = CpuJoin::new_experiment(b, &range, jp).expect("setup");
        let mut affine = CpuJoin::new_experiment(b, &range, jp).expect("setup");
        let secs = affine.enable_affine_extend();
        let (mut e1, mut e2) = (super::Ext::default(), super::Ext::default());
        let mut rows = 0;
        for v in sample(0xAFF + u64::from(b), exact.partitions(), count) {
            exact.extend(v, &mut e1);
            affine.extend_affine(v, &mut e2);
            for (x, y, what) in [
                (&e1.idx, &e2.idx, "idx"),
                (&e1.q2, &e2.q2, "q2"),
                (&e1.q3, &e2.q3, "q3"),
                (&e1.c2, &e2.c2, "c2"),
                (&e1.c3, &e2.c3, "c3"),
                (&e1.c3b, &e2.c3b, "c3b"),
                (&e1.rho, &e2.rho, "rho"),
                (&e1.p2, &e2.p2, "p2"),
                (&e1.p3, &e2.p3, "p3"),
                (&e1.seg, &e2.seg, "seg"),
            ] {
                assert_eq!(x, y, "b{b} v {v}: {what}");
            }
            assert_eq!(e1.mask, e2.mask, "b{b} v {v}: mask");
            rows += e1.idx.len();
        }
        println!("N1 AFFINE b{b} {jp:?}: {count} units, {rows} extended rows equal (prep {secs:.2}s)");
    }
}
