//! Opt-in counting run (research program L1): why the join's cost per
//! top-layer prefix differs by base, and what two ways of skipping ANDs
//! that cannot pass would save. `NICE_TEST_L1=<output directory>`.
//!
//! For each base it samples partitions of two fields (1e16, 1e15 at base 58,
//! as EXPERIMENTS item 23 profiled them; `NICE_TEST_L1_SIZE` overrides) and
//! runs each one exactly as [`CpuJoin::run`] does, with
//! stage timers, then counts on the same tops and bottom lists: tops and
//! their certificates' popcount, the bottoms, ANDs (bottoms scanned) per
//! top, and what passes the AND, the range test and the prefilter. The ANDs
//! alone and the full checks alone are timed again separately.
//!
//! The simulations, on the real masks of every scanned (top, class):
//! - **Signature bucketing:** each digit-sum class split by `bottom ∩ S`
//!   for a digit set `S` of `s` digits; a top scans only the sub-buckets
//!   disjoint from `top ∩ S`. `S` is the lowest `s` digits, the `s` digits
//!   most often in the window's top masks, or the `s` with the largest
//!   (top frequency × bottom frequency), the last two chosen per window
//!   from two partitions outside the sample.
//! - **Pruning:** bottoms that meet digits every top knows are dropped
//!   before the scan: the window's own certificate, the certificate of the
//!   1e16 field from the same start (which every top of the window knows
//!   too), or the AND of the key's top masks.
//!
//! Output: `partitions.csv`, `windows.csv`, `popcount.csv`, `digits.csv`.

// Measurement code: short names as in `overlap_join`, small indices.
#![allow(
    clippy::many_single_char_names,
    clippy::cast_possible_truncation,
    clippy::needless_range_loop
)]

use super::*;
use crate::overlap_join::Base;
use crate::overlap_join::test_fields::PLAN_FIELDS;
use std::fmt::Write as _;
use std::sync::Mutex;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::time::{Duration, Instant};

/// Two fields per base, at the size EXPERIMENTS item 23 profiled them (1e15
/// at base 58, 1e16 above): item 23's own field, and a second one (item
/// 18's GPU field at base 58, the `PLAN_FIELDS` start above, run at 1e16).
fn windows() -> Vec<(u32, &'static str, u128, u128)> {
    let plan = |b: u32| {
        PLAN_FIELDS
            .iter()
            .find(|f| f.0 == b)
            .expect("a plan field")
            .1
    };
    let (e15, e16) = (1_000_000_000_000_000, 10_000_000_000_000_000);
    vec![
        (58, "item23", 183_859_216_587_923_470_200, e15),
        (58, "item18", 130_525_216_587_923_470_200, e15),
        (60, "item23", 795_599_612_114_824_200_908, e16),
        (60, "plan", plan(60), e16),
        (62, "item23", 12_255_736_762_397_899_821_056, e16),
        (62, "plan", plan(62), e16),
        (64, "item23", 72_806_461_862_957_161_709_568, e16),
        (64, "plan", plan(64), e16),
    ]
}

fn splitmix(x: &mut u64) -> u64 {
    *x = x.wrapping_add(0x9E37_79B9_7F4A_7C15);
    let mut z = *x;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58_476D_1CE4_E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D0_49BB_1331_11EB);
    z ^ (z >> 31)
}

/// `bottom ∩ S` as an `s`-bit index (bit `i` = digit `digits[i]`).
#[inline]
fn sig(m: u64, digits: &[u32]) -> usize {
    let mut x = 0u64;
    for (i, &d) in digits.iter().enumerate() {
        x |= ((m >> d) & 1) << i;
    }
    x as usize
}

/// Subset sums in place: `a[T] = Σ_{U ⊆ T} a[U]`.
fn zeta(a: &mut [u32], s: usize) {
    for bit in 0..s {
        let bb = 1usize << bit;
        for t in 0..a.len() {
            if t & bb != 0 {
                a[t] += a[t ^ bb];
            }
        }
    }
}

fn bits(mut m: u64) -> impl Iterator<Item = usize> {
    std::iter::from_fn(move || {
        if m == 0 {
            return None;
        }
        let d = m.trailing_zeros() as usize;
        m &= m - 1;
        Some(d)
    })
}

/// P(AND = 0) for a top of popcount `pc` against a bottom of `kk` distinct
/// digits drawn uniformly from `b`: C(b − pc, kk) / C(b, kk).
fn uniform_model(b: u32, kk: u32) -> Vec<f64> {
    (0..=64u32)
        .map(|pc| {
            if pc + kk > b {
                0.0
            } else {
                (0..kk)
                    .map(|i| f64::from(b - pc - i) / f64::from(b - i))
                    .product()
            }
        })
        .collect()
}

/// The ANDs of one scan alone: how many bottoms the top's mask misses, as
/// `CpuJoin::scan_avx2` tests them but counted instead of dispatched.
#[cfg(target_arch = "x86_64")]
#[target_feature(enable = "avx2")]
fn count_zero_avx2(masks: &[u64], t: u64) -> u64 {
    use std::arch::x86_64::{
        __m256i, _mm256_and_si256, _mm256_castsi256_pd, _mm256_cmpeq_epi64, _mm256_loadu_si256,
        _mm256_movemask_pd, _mm256_set1_epi64x, _mm256_setzero_si256,
    };
    let tv = _mm256_set1_epi64x(t.cast_signed());
    let zero = _mm256_setzero_si256();
    let (chunks, rest) = masks.as_chunks::<16>();
    let mut n = 0u64;
    for chunk in chunks {
        let mut bits = 0u32;
        for q in 0..4 {
            // SAFETY: four u64 at 4q of a 16-element chunk, loaded unaligned.
            #[allow(clippy::cast_ptr_alignment)]
            let v = unsafe { _mm256_loadu_si256(chunk.as_ptr().add(4 * q).cast::<__m256i>()) };
            let z = _mm256_cmpeq_epi64(_mm256_and_si256(v, tv), zero);
            bits |= (_mm256_movemask_pd(_mm256_castsi256_pd(z)).cast_unsigned()) << (4 * q);
        }
        n += u64::from(bits.count_ones());
    }
    n + rest.iter().filter(|&&m| m & t == 0).count() as u64
}

fn count_zero(join: &CpuJoin, masks: &[u64], t: u64) -> u64 {
    #[cfg(target_arch = "x86_64")]
    if join.avx2 {
        // SAFETY: `avx2` is only set where the CPU has AVX2.
        return unsafe { count_zero_avx2(masks, t) };
    }
    let _ = join;
    masks.iter().filter(|&&m| m & t == 0).count() as u64
}

/// The client's full check of a prefilter survivor, as `CpuJoin::survivor`
/// makes it (the seed is the low `f0` digits of n² and n³).
fn full_check(fs: &FieldSetup, n: u128) -> bool {
    if fs.f0 != 3 {
        return get_is_nice(n, fs.b);
    }
    let b = u128::from(fs.b);
    let m = b * b * b;
    let r = n % m;
    let sq = r * r % m;
    let cu = sq * r % m;
    let mut seed = 0u64;
    for mut y in [sq, cu] {
        for _ in 0..3 {
            seed |= 1u64 << (y % b);
            y /= b;
        }
    }
    get_is_nice_with_known_lsd(n, fs.b, 3, seed)
}

/// What one partition did.
#[derive(Clone)]
struct Meas {
    tops: u64,
    pc_hist: Vec<u64>,
    n2_known: u64,
    n3_known: u64,
    split_n: u64,
    ext_rows: u64,
    keys: u64,
    list_entries: u64,
    ands: u64,
    and_pass: u64,
    survivors: u64,
    checked: u64,
    hits: u64,
    model_pass: f64,
    t_tops: Duration,
    t_extend: Duration,
    t_list: Duration,
    t_scan: Duration,
    t_and: Duration,
    t_full: Duration,
    sig_rem: Vec<u64>,
    sig_vis: Vec<u64>,
    sig_nevis: Vec<u64>,
    prune_skip: Vec<u64>,
    /// Per popcount: tops, ANDs, AND passes.
    by_pc: Vec<[u64; 3]>,
    top_freq: Vec<u64>,
    bot_freq: Vec<u64>,
}

impl Meas {
    fn new(nsig: usize, nprune: usize) -> Self {
        Self {
            tops: 0,
            pc_hist: vec![0; 65],
            n2_known: 0,
            n3_known: 0,
            split_n: 0,
            ext_rows: 0,
            keys: 0,
            list_entries: 0,
            ands: 0,
            and_pass: 0,
            survivors: 0,
            checked: 0,
            hits: 0,
            model_pass: 0.0,
            t_tops: Duration::ZERO,
            t_extend: Duration::ZERO,
            t_list: Duration::ZERO,
            t_scan: Duration::ZERO,
            t_and: Duration::ZERO,
            t_full: Duration::ZERO,
            sig_rem: vec![0; nsig],
            sig_vis: vec![0; nsig],
            sig_nevis: vec![0; nsig],
            prune_skip: vec![0; nprune],
            by_pc: vec![[0; 3]; 65],
            top_freq: vec![0; 64],
            bot_freq: vec![0; 64],
        }
    }

    /// The `q` quantile of the tops' popcount.
    #[allow(clippy::cast_precision_loss)]
    fn pc_quantile(&self, q: f64) -> usize {
        let target = (self.tops as f64 * q).ceil().max(1.0);
        let mut acc = 0u64;
        for (pc, &n) in self.pc_hist.iter().enumerate() {
            acc += n;
            if acc as f64 >= target {
                return pc;
            }
        }
        64
    }
}

type Sigs = [(String, Vec<u32>)];
type Prunes = [(String, Option<u64>)];

/// Partition `v` of `join` as [`CpuJoin::run`] runs it, timed by stage and
/// counted, with the simulations `sigs` and `prunes` on its masks.
#[allow(clippy::too_many_lines, clippy::cast_precision_loss)]
fn measure(join: &CpuJoin, v: u32, sigs: &Sigs, prunes: &Prunes, sc: &mut Scratch) -> Meas {
    let fs = &join.fs;
    let m1 = fs.m1;
    let roots = &fs.base.roots;
    let model = uniform_model(fs.b, 2 * join.k);
    let mut m = Meas::new(sigs.len(), prunes.len());
    let mut out = PartitionResult::default();
    let mut rec: Vec<u128> = Vec::new();
    let mut hist: Vec<Vec<u32>> = sigs
        .iter()
        .map(|(_, d)| vec![0u32; (m1 as usize) << d.len()])
        .collect();
    let mut nonempty = hist.clone();
    let mut pcount = vec![0u32; m1 as usize];
    let mut top_pass: Vec<u64> = Vec::new();
    let class = |root: u32, pc: u32| ((root + m1 - pc) % m1) as usize;
    let mut extended = false;
    for key in 0..join.keyspace {
        let (lo, hi) = (
            join.key_off[key as usize] as usize,
            join.key_off[key as usize + 1] as usize,
        );
        if lo == hi {
            continue;
        }
        let t0 = Instant::now();
        join.tops(v, &fs.tlay[lo..hi], &mut sc.tops);
        if sc.tops.is_empty() {
            m.t_tops += t0.elapsed();
            continue;
        }
        sc.tops.sort_unstable_by_key(|t| t.pc);
        m.t_tops += t0.elapsed();
        if !extended {
            let t0 = Instant::now();
            join.extend(v, &mut sc.ext);
            m.t_extend += t0.elapsed();
            m.ext_rows = sc.ext.idx.len() as u64;
            extended = true;
        }
        let d = if fs.key_level {
            key
        } else {
            join.partition_digit(v, fs.jp.p - 1)
        };
        let t0 = Instant::now();
        join.list(d, &mut sc.ext, &mut sc.masks, &mut sc.info, &mut sc.offs);
        m.t_list += t0.elapsed();
        m.keys += 1;
        m.list_entries += sc.masks.len() as u64;

        // The production scan: AND, range test, prefilter, full check.
        let t0 = Instant::now();
        {
            let mut record = Some(&mut rec);
            for top in &sc.tops {
                for &root in roots {
                    let c = class(root, top.pc);
                    let (lo, hi) = (sc.offs[c] as usize, sc.offs[c + 1] as usize);
                    let pass = Pass {
                        top,
                        d,
                        ext: &sc.ext,
                        info: &sc.info[lo..hi],
                    };
                    join.scan(&pass, &sc.masks[lo..hi], &mut out, &mut record);
                }
            }
        }
        m.t_scan += t0.elapsed();

        // The ANDs alone.
        top_pass.clear();
        let t0 = Instant::now();
        for top in &sc.tops {
            let mut n = 0u64;
            for &root in roots {
                let c = class(root, top.pc);
                let (lo, hi) = (sc.offs[c] as usize, sc.offs[c + 1] as usize);
                n += count_zero(join, &sc.masks[lo..hi], top.mask);
            }
            top_pass.push(n);
        }
        m.t_and += t0.elapsed();

        // Counts.
        let class_len = |c: usize| u64::from(sc.offs[c + 1] - sc.offs[c]);
        for (i, top) in sc.tops.iter().enumerate() {
            let pc = top.mask.count_ones() as usize;
            let ands: u64 = roots.iter().map(|&r| class_len(class(r, top.pc))).sum();
            m.tops += 1;
            m.pc_hist[pc] += 1;
            m.ands += ands;
            m.and_pass += top_pass[i];
            m.model_pass += ands as f64 * model[pc];
            m.by_pc[pc][0] += 1;
            m.by_pc[pc][1] += ands;
            m.by_pc[pc][2] += top_pass[i];
            for dg in bits(top.mask) {
                m.top_freq[dg] += 1;
            }
            if i % 8 == 0 {
                let lo = top.p * fs.w;
                let (a, e) = (lo.max(fs.s), (lo + fs.w - 1).min(fs.e - 1));
                let (mask, k2, k3) = fs
                    .base
                    .cert_split(a, e, join.k)
                    .expect("a top is certified");
                assert_eq!(mask, top.mask, "cert_split agrees with cert");
                m.n2_known += u64::from(k2);
                m.n3_known += u64::from(k3);
                m.split_n += 1;
            }
        }
        for &bm in &sc.masks {
            for dg in bits(bm) {
                m.bot_freq[dg] += 1;
            }
        }

        // Signature bucketing: what each top would still AND.
        for (vi, (_, digits)) in sigs.iter().enumerate() {
            let s = digits.len();
            let w = 1usize << s;
            let full = w - 1;
            let (h, ne) = (&mut hist[vi], &mut nonempty[vi]);
            h.fill(0);
            for c in 0..m1 as usize {
                let (lo, hi) = (sc.offs[c] as usize, sc.offs[c + 1] as usize);
                for &bm in &sc.masks[lo..hi] {
                    h[c * w + sig(bm, digits)] += 1;
                }
                let hc = &mut h[c * w..(c + 1) * w];
                let nc = &mut ne[c * w..(c + 1) * w];
                for u in 0..w {
                    nc[u] = u32::from(hc[u] > 0);
                }
                zeta(hc, s);
                zeta(nc, s);
            }
            for top in &sc.tops {
                let comp = full & !sig(top.mask, digits);
                for &root in roots {
                    let c = class(root, top.pc);
                    m.sig_rem[vi] += u64::from(h[c * w + comp]);
                    m.sig_vis[vi] += 1u64 << comp.count_ones();
                    m.sig_nevis[vi] += u64::from(ne[c * w + comp]);
                }
            }
        }

        // Pruning: bottoms meeting digits every top of the key knows.
        let key_common = sc.tops.iter().fold(u64::MAX, |acc, t| acc & t.mask);
        for (pi, (_, mask)) in prunes.iter().enumerate() {
            let pm = mask.unwrap_or(key_common);
            assert!(
                sc.tops.iter().all(|t| t.mask & pm == pm),
                "every top knows the pruned digits"
            );
            for (c, n) in pcount.iter_mut().enumerate() {
                let (lo, hi) = (sc.offs[c] as usize, sc.offs[c + 1] as usize);
                *n = u32::try_from(sc.masks[lo..hi].iter().filter(|&&bm| bm & pm != 0).count())
                    .expect("a class fits u32");
            }
            for top in &sc.tops {
                for &root in roots {
                    m.prune_skip[pi] += u64::from(pcount[class(root, top.pc)]);
                }
            }
        }
    }

    // Every simulation keeps every pair that passes the AND.
    for (i, (name, _)) in sigs.iter().enumerate() {
        assert!(m.sig_rem[i] >= m.and_pass, "{name} drops a passing pair");
    }
    for (i, (name, _)) in prunes.iter().enumerate() {
        assert!(
            m.ands - m.prune_skip[i] >= m.and_pass,
            "{name} drops a passing pair"
        );
    }

    // The full checks alone.
    let t0 = Instant::now();
    let nice = rec.iter().filter(|&&n| full_check(fs, n)).count();
    m.t_full = t0.elapsed();
    assert_eq!(rec.len() as u64, out.checked);
    assert_eq!(nice, out.hits.len());
    m.survivors = out.survivors;
    m.checked = out.checked;
    m.hits = out.hits.len() as u64;
    m
}

/// `count` partitions of `[0, n)`, one from each of `count` equal strata.
fn stratified(n: u32, count: usize, seed: u64) -> Vec<u32> {
    let mut x = seed;
    let count = u32::try_from(count).expect("a small count").min(n);
    (0..count)
        .map(|i| {
            let (lo, hi) = (i * n / count, (i + 1) * n / count);
            lo + u32::try_from(splitmix(&mut x) % u64::from(hi - lo)).expect("below n")
        })
        .collect()
}

/// The `s` digits with the largest `score`, in decreasing order.
fn top_digits(score: &[f64], s: usize) -> Vec<u32> {
    let mut idx: Vec<u32> = (0..u32::try_from(score.len()).expect("64")).collect();
    idx.sort_by(|&a, &b| {
        score[b as usize]
            .total_cmp(&score[a as usize])
            .then(a.cmp(&b))
    });
    idx.truncate(s);
    idx
}

fn secs(d: Duration) -> f64 {
    d.as_secs_f64()
}

fn env_or<T: std::str::FromStr>(name: &str, default: T) -> T {
    std::env::var(name).map_or(default, |s| {
        s.parse()
            .unwrap_or_else(|_| panic!("{name}: cannot parse {s}"))
    })
}

#[test]
#[ignore = "opt-in counting run (research program L1)"]
#[allow(clippy::too_many_lines, clippy::cast_precision_loss)]
fn l1_selectivity() {
    let Ok(out_dir) = std::env::var("NICE_TEST_L1") else {
        eprintln!("skipping: set NICE_TEST_L1 to an output directory");
        return;
    };
    let out_dir = std::path::PathBuf::from(out_dir);
    std::fs::create_dir_all(&out_dir).expect("output directory");
    let parts: usize = env_or("NICE_TEST_L1_PARTS", 6);
    let size_override: Option<u128> = std::env::var("NICE_TEST_L1_SIZE")
        .ok()
        .map(|s| s.parse().expect("NICE_TEST_L1_SIZE: a size"));
    let threads: usize = env_or("NICE_TEST_L1_THREADS", 3);
    let bases: Vec<u32> = std::env::var("NICE_TEST_L1_BASES")
        .unwrap_or_else(|_| "58,60,62,64".into())
        .split(',')
        .map(|b| b.trim().parse().expect("NICE_TEST_L1_BASES: bases"))
        .collect();
    let field16 = 10_000_000_000_000_000u128;

    let mut part_csv = String::from(
        "base,window,start,size,partition,tlay,tops,pc_mean,pc_p10,pc_p90,n2_known_mean,\
         n3_known_mean,ext_rows,keys,list_mean,roots,ands_per_top,and_pass_per_top,\
         survivors_per_top,checked_per_top,hits,model_pass_per_top,tops_s,extend_s,list_s,\
         scan_s,and_only_s,fullcheck_s",
    );
    let mut win_csv = String::from(
        "base,window,start,size,L,s2,s3,t,k,p,f0,m1,roots,nparts,tlay,cert_window_pc,\
         cert_1e16_pc,S_top8,S_coll8,prepass_partitions,sampled_partitions,elapsed_s",
    );
    let mut pc_csv = String::from("base,window,popcount,tops,ands,and_pass,pass_rate,model_rate");
    let mut dig_csv = String::from("base,window,digit,top_frac,bottom_frac,in_cert_window");
    let mut header_done = false;

    for &base in &bases {
        for (wi, &(_, wname, start, size)) in windows().iter().enumerate().filter(|w| w.1.0 == base)
        {
            let size = size_override.unwrap_or(size);
            let t_win = Instant::now();
            let range = FieldSize::new(start, start + size);
            let jp = join_params_for(base, &range).expect("a join window");
            let join = CpuJoin::new(base, &range, jp).expect("window setup");
            let fs = &join.fs;
            let k = join.k;
            let cert_win = fs.base.cert(start, start + size - 1, k).unwrap_or(0);
            let cert16 = Base::try_new(base, start, start + field16 - 1)
                .and_then(|b16| b16.cert(start, start + field16 - 1, k))
                .unwrap_or(0);
            assert_eq!(
                cert_win & cert16,
                cert16,
                "the window knows the field's digits"
            );

            // Pre-pass: digit frequencies from partitions outside the sample.
            let seed = 0x4C31_0000 + (u64::from(base) << 8) + wi as u64;
            let sample = stratified(join.partitions(), parts, seed);
            let mut x = seed ^ 0xABCD;
            let mut pre = Vec::new();
            while pre.len() < 2 {
                let v = u32::try_from(splitmix(&mut x) % u64::from(join.partitions()))
                    .expect("below b^p");
                if !sample.contains(&v) && !pre.contains(&v) {
                    pre.push(v);
                }
            }
            let mut sc = Scratch::default();
            let (mut tf, mut bf, mut nt, mut nb) = (vec![0u64; 64], vec![0u64; 64], 0u64, 0u64);
            for &v in &pre {
                let mm = measure(&join, v, &[], &[], &mut sc);
                for d in 0..64 {
                    tf[d] += mm.top_freq[d];
                    bf[d] += mm.bot_freq[d];
                }
                nt += mm.tops;
                nb += mm.list_entries;
            }
            let tfrac: Vec<f64> = tf.iter().map(|&c| c as f64 / nt.max(1) as f64).collect();
            let bfrac: Vec<f64> = bf.iter().map(|&c| c as f64 / nb.max(1) as f64).collect();
            let coll: Vec<f64> = tfrac.iter().zip(&bfrac).map(|(a, b)| a * b).collect();
            for d in 0..base as usize {
                let _ = write!(
                    dig_csv,
                    "\n{base},{wname},{d},{:.5},{:.5},{}",
                    tfrac[d],
                    bfrac[d],
                    (cert_win >> d) & 1
                );
            }
            let mut sigs: Vec<(String, Vec<u32>)> = Vec::new();
            for s in [4u32, 6, 8] {
                sigs.push((format!("low{s}"), (0..s).collect()));
            }
            for s in [4usize, 6, 8] {
                sigs.push((format!("top{s}"), top_digits(&tfrac, s)));
            }
            for s in [4usize, 6, 8] {
                sigs.push((format!("coll{s}"), top_digits(&coll, s)));
            }
            let prunes: Vec<(String, Option<u64>)> = vec![
                ("prune_window".into(), Some(cert_win)),
                ("prune_1e16".into(), Some(cert16)),
                ("prune_key".into(), None),
            ];
            if !header_done {
                for (name, _) in &sigs {
                    let _ = write!(part_csv, ",skip_{name},visits_{name},nevisits_{name}");
                }
                for (name, _) in &prunes {
                    let _ = write!(part_csv, ",skip_{name}");
                }
                header_done = true;
            }

            // The sample, on `threads` threads.
            let next = AtomicUsize::new(0);
            let results = Mutex::new(Vec::new());
            std::thread::scope(|s| {
                for _ in 0..threads.max(1) {
                    s.spawn(|| {
                        let mut sc = Scratch::default();
                        loop {
                            let i = next.fetch_add(1, Ordering::Relaxed);
                            let Some(&v) = sample.get(i) else { return };
                            let mm = measure(&join, v, &sigs, &prunes, &mut sc);
                            results.lock().expect("results").push((v, mm));
                        }
                    });
                }
            });
            let mut results = results.into_inner().expect("results");
            results.sort_by_key(|r| r.0);

            let tlay = fs.tlay.len();
            let mut by_pc = vec![[0u64; 3]; 65];
            let (mut k2s, mut k3s, mut kn) = (0u64, 0u64, 0u64);
            for (v, mm) in &results {
                let tops = mm.tops.max(1) as f64;
                let per = |x: u64| x as f64 / tops;
                let _ = write!(
                    part_csv,
                    "\n{base},{wname},{start},{size},{v},{tlay},{},{:.3},{},{},{:.3},{:.3},{},{},\
                     {:.1},{},{:.1},{:.3},{:.3},{:.4},{},{:.3},{:.4},{:.4},{:.4},{:.4},{:.4},{:.4}",
                    mm.tops,
                    mm.pc_hist
                        .iter()
                        .enumerate()
                        .map(|(pc, &n)| pc as f64 * n as f64)
                        .sum::<f64>()
                        / tops,
                    mm.pc_quantile(0.1),
                    mm.pc_quantile(0.9),
                    mm.n2_known as f64 / mm.split_n.max(1) as f64,
                    mm.n3_known as f64 / mm.split_n.max(1) as f64,
                    mm.ext_rows,
                    mm.keys,
                    mm.list_entries as f64 / mm.keys.max(1) as f64,
                    fs.base.roots.len(),
                    per(mm.ands),
                    per(mm.and_pass),
                    per(mm.survivors),
                    per(mm.checked),
                    mm.hits,
                    mm.model_pass / tops,
                    secs(mm.t_tops),
                    secs(mm.t_extend),
                    secs(mm.t_list),
                    secs(mm.t_scan),
                    secs(mm.t_and),
                    secs(mm.t_full),
                );
                let ands = mm.ands.max(1) as f64;
                for i in 0..sigs.len() {
                    let pairs = mm.tops as f64 * fs.base.roots.len() as f64;
                    let _ = write!(
                        part_csv,
                        ",{:.4},{:.2},{:.2}",
                        1.0 - mm.sig_rem[i] as f64 / ands,
                        mm.sig_vis[i] as f64 / pairs.max(1.0),
                        mm.sig_nevis[i] as f64 / pairs.max(1.0)
                    );
                }
                for i in 0..prunes.len() {
                    let _ = write!(part_csv, ",{:.4}", mm.prune_skip[i] as f64 / ands);
                }
                for pc in 0..65 {
                    for j in 0..3 {
                        by_pc[pc][j] += mm.by_pc[pc][j];
                    }
                }
                k2s += mm.n2_known;
                k3s += mm.n3_known;
                kn += mm.split_n;
            }
            let model = uniform_model(base, 2 * k);
            for (pc, r) in by_pc.iter().enumerate() {
                if r[0] > 0 {
                    let _ = write!(
                        pc_csv,
                        "\n{base},{wname},{pc},{},{},{},{:.6},{:.6}",
                        r[0],
                        r[1],
                        r[2],
                        r[2] as f64 / r[1].max(1) as f64,
                        model[pc]
                    );
                }
            }
            let digits = |d: &[u32]| d.iter().map(u32::to_string).collect::<Vec<_>>().join(" ");
            let _ = write!(
                win_csv,
                "\n{base},{wname},{start},{size},{},{},{},{},{},{},{},{},{},{},{tlay},{},{},{},{},\
                 {},{},{:.1}",
                fs.base.l,
                fs.base.s2,
                fs.base.s3,
                jp.t,
                jp.k,
                jp.p,
                fs.f0,
                fs.m1,
                fs.base.roots.len(),
                fs.nparts,
                cert_win.count_ones(),
                cert16.count_ones(),
                digits(&sigs[5].1),
                digits(&sigs[8].1),
                pre.len(),
                results.len(),
                t_win.elapsed().as_secs_f64()
            );
            eprintln!(
                "L1 b{base} {wname}: {} partitions in {:.1}s; n² known {:.2}, n³ known {:.2}; \
                 cert window {} digits, 1e16 {}",
                results.len(),
                t_win.elapsed().as_secs_f64(),
                k2s as f64 / kn.max(1) as f64,
                k3s as f64 / kn.max(1) as f64,
                cert_win.count_ones(),
                cert16.count_ones()
            );
            // Written after every window, so a partial run keeps its rows.
            for (name, body) in [
                ("partitions.csv", &part_csv),
                ("windows.csv", &win_csv),
                ("popcount.csv", &pc_csv),
                ("digits.csv", &dig_csv),
            ] {
                std::fs::write(out_dir.join(name), format!("{body}\n")).expect("write a CSV");
            }
        }
    }
}

/// Opt-in (`NICE_TEST_L1_PROBE=1`): the top-layer size of each 1e15 tenth
/// of the 1e16 field at every window's start, to place the windows where
/// the field has tops.
#[test]
#[ignore = "opt-in probe (research program L1)"]
fn l1_probe_windows() {
    if std::env::var("NICE_TEST_L1_PROBE").is_err() {
        eprintln!("skipping: set NICE_TEST_L1_PROBE=1");
        return;
    }
    let tenth = 1_000_000_000_000_000u128;
    for (base, name, start, _) in windows() {
        let sizes: Vec<usize> = (0..10u128)
            .map(|i| {
                let range = FieldSize::new(start + i * tenth, start + (i + 1) * tenth);
                let jp = join_params_for(base, &range).expect("a join window");
                FieldSetup::new(base, range.start(), range.end(), jp)
                    .expect("setup")
                    .tlay
                    .len()
            })
            .collect();
        eprintln!(
            "L1 PROBE b{base} {name} {start}: tenths {sizes:?}, total {}",
            sizes.iter().sum::<usize>()
        );
    }
}
