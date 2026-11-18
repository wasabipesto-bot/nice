//! NM scratch (never pushed): the near-miss by-product of the CPU join.
//!
//! nm_join bf  <base> <start|fFRAC> <size> <tol> <v0> <count>
//!     the join with tolerance `tol` on partitions v0..v0+count against a
//!     brute-force enumeration of the definition on the same partitions.
//! nm_join run <base> <start|fFRAC> <size> <slice> <v0> <count> <tol>
//!     contiguous partitions of one slice on one thread (the client's order),
//!     as CPU2's harness; prints time, counters, hits, near misses, histogram.
use malachite::base::num::arithmetic::traits::Pow;
use malachite::base::num::conversion::traits::Digits;
use malachite::natural::Natural;
use nice_common::FieldSize;
use nice_common::base_range::get_base_range_u128;
use nice_common::cpu_join::{CpuJoin, PartitionResult, Scratch, slices_for};
use nice_common::overlap_join::{JoinParams, ndigits};
use std::collections::BTreeMap;
use std::time::Instant;

fn start_of(base: u32, a: &str, size: u128) -> u128 {
    if let Some(f) = a.strip_prefix('f') {
        let band = get_base_range_u128(base).unwrap().unwrap();
        let f: f64 = f.parse().unwrap();
        let off = (band.size() as f64 * f) as u128;
        let s = band.start() + off / size * size;
        s.min(band.end() - size)
    } else {
        a.parse().unwrap()
    }
}

/// Digits of x^e, low first, padded to `len`.
fn pow_digits(x: u128, e: u64, b: u32, len: usize) -> Vec<u32> {
    let mut d: Vec<u32> = Natural::from(x).pow(e).to_digits_asc(&b);
    d.resize(len.max(d.len()), 0);
    d
}

/// The definition of "reaches the full check" for the join's shape (t, k,
/// p, mid = 2), and the distinct-digit count of n² ‖ n³.
struct Def {
    b: u32,
    s2: usize,
    s3: usize,
    k: usize,
    k2: usize,
    w: u128,
    s: u128,
    e: u128,
    roots: Vec<u32>,
    bk: u128,
}

impl Def {
    /// The top certificate of the block holding `p`, as the join defines
    /// it (`Base::cert_parts`): the digits of n² and n³ at positions >=
    /// c0 = max(k, digits of hi^j − lo^j) common to the block's ends
    /// (clipped to the field), distinct, closed over the domain {d, d + 1}
    /// of each power's first disagreement at or above c0
    /// (`close_certificate`); and the gate, min c0 >= k2. As (mask, clean,
    /// gate).
    fn cert(&self, p: u128) -> (u64, bool, bool) {
        let lo = (p * self.w).max(self.s);
        let hi = (p * self.w + self.w - 1).min(self.e - 1);
        let mut mask = 0u64;
        let mut ok = true;
        let mut doms = [0u64; 2];
        let mut floor = usize::MAX;
        for (j, (ex, len)) in [(2u64, self.s2), (3u64, self.s3)].into_iter().enumerate() {
            let a = pow_digits(lo, ex, self.b, len);
            let z = pow_digits(hi, ex, self.b, len);
            let diff = Natural::from(hi).pow(ex) - Natural::from(lo).pow(ex);
            let nd = diff.to_digits_asc(&self.b).len();
            let c0 = self.k.max(nd);
            floor = floor.min(c0);
            let mut pos = len;
            while pos > c0 && a[pos - 1] == z[pos - 1] {
                pos -= 1;
                let bit = 1u64 << a[pos];
                ok &= mask & bit == 0;
                mask |= bit;
            }
            if pos > c0 {
                // First disagreement at pos − 1 >= c0: z's digit is a's + 1.
                let d = a[pos - 1];
                assert_eq!(z[pos - 1], d + 1);
                doms[j] = 0b11u64 << d;
            }
        }
        if !ok {
            return (mask, false, false);
        }
        // close_certificate
        let mut forced = [false; 2];
        loop {
            let mut changed = false;
            for (dom, f) in doms.iter().zip(&mut forced) {
                if *dom == 0 || *f {
                    continue;
                }
                let free = dom & !mask;
                if free == 0 {
                    return (mask, false, false);
                }
                if free.is_power_of_two() {
                    mask |= free;
                    *f = true;
                    changed = true;
                }
            }
            if !changed {
                break;
            }
        }
        (mask, true, floor >= self.k2)
    }

    /// Whether `n` reaches the check (given its block's certificate), and
    /// its distinct digits.
    fn reach(&self, n: u128, cert: (u64, bool, bool)) -> Option<u32> {
        if !cert.1 || !self.roots.contains(&((n % u128::from(self.b - 1)) as u32)) {
            return None;
        }
        // Bottom: the low k digits of n² and n³, from n mod b^k (cheap).
        let r = n % self.bk;
        let (r2, r3) = (r * r % self.bk, (r * r % self.bk) * r % self.bk);
        let mut bot = 0u64;
        for mut x in [r2, r3] {
            for _ in 0..self.k {
                let bit = 1u64 << (x % u128::from(self.b));
                if bot & bit != 0 {
                    return None;
                }
                bot |= bit;
                x /= u128::from(self.b);
            }
        }
        if bot & cert.0 != 0 {
            return None;
        }
        let d2 = pow_digits(n, 2, self.b, self.s2);
        let d3 = pow_digits(n, 3, self.b, self.s3);
        // Prefilter: positions k..k2 of both, distinct, new against the
        // bottom, and against the certificate if every certified position
        // is >= k2 (the gate).
        let gate = cert.2;
        let mut pre = bot | if gate { cert.0 } else { 0 };
        for d in [&d2, &d3] {
            for &x in &d[self.k..self.k2] {
                let bit = 1u64 << x;
                if pre & bit != 0 {
                    return None;
                }
                pre |= bit;
            }
        }
        let mut all = 0u64;
        for &x in d2.iter().chain(d3.iter()) {
            all |= 1u64 << x;
        }
        Some(all.count_ones())
    }
}

/// Distinct digits of n² ‖ n³ (n³ below 2^128, else malachite).
fn distinct_small(n: u128, b: u32) -> u32 {
    let bb = u128::from(b);
    let mut m = 0u64;
    match n.checked_mul(n).and_then(|q| q.checked_mul(n)) {
        Some(c) => {
            for mut x in [n * n, c] {
                while x > 0 {
                    m |= 1u64 << (x % bb);
                    x /= bb;
                }
            }
        }
        None => {
            for e in [2u64, 3] {
                for d in Natural::from(n).pow(e).to_digits_asc(&b) {
                    m |= 1u64 << d;
                }
            }
        }
    }
    m.count_ones()
}

fn bf(a: &[String]) {
    let base: u32 = a[2].parse().unwrap();
    let (start, size) = if a[3] == "W" {
        let band = get_base_range_u128(base).unwrap().unwrap();
        (band.start(), band.size())
    } else {
        let size: u128 = a[4].parse::<f64>().unwrap() as u128;
        (start_of(base, &a[3], size), size)
    };
    let tol: u32 = a[5].parse().unwrap();
    let v0: u32 = a[6].parse().unwrap();
    let count: u32 = a[7].parse().unwrap();
    let range = FieldSize::new(start, start + size);
    let l = ndigits(range.last(), base);
    assert_eq!(l, ndigits(start, base));
    let jp = match std::env::var("NM_JP") {
        Ok(x) => {
            let v: Vec<u32> = x.split(',').map(|t| t.parse().unwrap()).collect();
            JoinParams { t: v[0], k: v[1], p: v[2] }
        }
        Err(_) => JoinParams::for_length(base, l).expect("join params"),
    };
    let mut join = CpuJoin::new(base, &range, jp).expect("setup");
    join.set_tolerance(tol);
    let v1 = (v0 + count).min(join.partitions());
    let mut sc = Scratch::default();
    let mut out = PartitionResult::default();
    let t = Instant::now();
    let fresh = std::env::var("NM_FRESH").is_ok();
    for v in v0..v1 {
        if fresh {
            sc = Scratch::default();
        }
        out.add(join.run_partition(v, &mut sc));
    }
    let jsecs = t.elapsed().as_secs_f64();
    let b = base;
    let bb = u128::from(b);
    let f0 = l - jp.t;
    let def = Def {
        b,
        s2: Natural::from(start).pow(2).to_digits_asc(&b).len(),
        s3: Natural::from(start).pow(3).to_digits_asc(&b).len(),
        k: jp.k as usize,
        k2: {
            let s2 = Natural::from(start).pow(2).to_digits_asc(&b).len() as u32;
            let mut mid = 2;
            while mid > 0
                && (jp.k + mid > s2 || u64::from(b).pow(jp.k + mid - f0) >= 1 << 32 || jp.k + mid > 12)
            {
                mid -= 1;
            }
            (jp.k + mid) as usize
        },
        w: bb.pow(f0),
        s: start,
        e: start + size,
        roots: (0..b - 1)
            .filter(|&c| {
                let c = u64::from(c);
                (c * c + c * c * c) % u64::from(b - 1) == u64::from(b * (b - 1) / 2 % (b - 1))
            })
            .collect(),
        bk: bb.pow(jp.k),
    };
    assert_eq!(Natural::from(start + size - 1).pow(3).to_digits_asc(&b).len(), def.s3);
    assert_eq!(Natural::from(start + size - 1).pow(2).to_digits_asc(&b).len(), def.s2);
    if let Ok(x) = std::env::var("NM_DEBUG_N") {
        let n: u128 = x.parse().unwrap();
        let c = def.cert(n / def.w);
        println!("debug n {n}: cert mask {:#b} clean {} gate {} reach {:?}", c.0, c.1, c.2, def.reach(n, c));
        return;
    }
    let nparts = bb.pow(jp.p);
    let t = Instant::now();
    // Brute force: every n of the field in the partitions run.
    let mut want: BTreeMap<u128, u32> = BTreeMap::new();
    let mut reached = 0u64;
    let all_n = std::env::var("NM_ALL").is_ok();
    let mut allhist = [0u64; 5];
    let mut rhist = vec![0u64; 65];
    let (pfirst, plast) = (start / def.w, (start + size - 1) / def.w);
    for p in pfirst..=plast {
        let v = (p % nparts) as u32;
        if v < v0 || v >= v1 {
            continue;
        }
        let cert = def.cert(p);
        if !cert.1 && !all_n {
            continue;
        }
        let lo = (p * def.w).max(start);
        let hi = (p * def.w + def.w).min(start + size);
        for n in lo..hi {
            if all_n {
                let d = distinct_small(n, b);
                if d + 4 >= b {
                    allhist[(b - d) as usize] += 1;
                }
            }
            if !cert.1 {
                continue;
            }
            if let Some(d) = def.reach(n, cert) {
                reached += 1;
                rhist[(b - d) as usize] += 1;
                if d >= b.saturating_sub(tol.min(3)) {
                    want.insert(n, d);
                }
            }
        }
    }
    let bsecs = t.elapsed().as_secs_f64();
    let mut got: BTreeMap<u128, u32> = out.near.iter().copied().collect();
    for &h in &out.hits {
        got.insert(h, b);
    }
    let mut hist: BTreeMap<u32, u64> = BTreeMap::new();
    for &d in want.values() {
        *hist.entry(b - d).or_default() += 1;
    }
    let mut jr = out.reps.clone();
    jr.resize(65, 0);
    let hist_ok = tol != 64 || jr == rhist;
    let equal = got == want && out.checked == reached && hist_ok;
    if all_n {
        println!("ALL b{b}: all n in the partitions run, by b - distinct (0..4): {allhist:?}; reaching the check: {:?}", &rhist[..5]);
    }
    println!(
        "BF b{b} start {start} size {size:e} tol {tol} v {v0}..{v1} join {jsecs:.2}s brute {bsecs:.2}s \
         checked {} reached {reached} reported {} want {} reps-hist(want) {:?} join-reps {:?} {}",
        out.checked,
        got.len(),
        want.len(),
        hist,
        out.reps,
        if equal { "EQUAL" } else { "MISMATCH" }
    );
    if !equal {
        let only_got: Vec<_> = got.iter().filter(|(n, _)| !want.contains_key(n)).take(5).collect();
        let only_want: Vec<_> = want.iter().filter(|(n, _)| !got.contains_key(n)).take(5).collect();
        println!("only join {only_got:?} only brute {only_want:?}");
        std::process::exit(1);
    }
}

fn run(a: &[String]) {
    let base: u32 = a[2].parse().unwrap();
    let size: u128 = a[4].parse::<f64>().unwrap() as u128;
    let start = start_of(base, &a[3], size);
    let si: usize = a[5].parse().unwrap();
    let v0: u32 = a[6].parse().unwrap();
    let count: u32 = a[7].parse().unwrap();
    let tol: u32 = a[8].parse().unwrap();
    let range = FieldSize::new(start, start + size);
    let (jp, slices) = slices_for(base, &range).expect("a join field");
    let t = Instant::now();
    let mut join = CpuJoin::new(base, &slices[si], jp).expect("setup");
    join.set_tolerance(tol);
    let setup = t.elapsed().as_secs_f64();
    let v1 = (v0 + count).min(join.partitions());
    let mut sc = Scratch::default();
    let mut out = PartitionResult::default();
    let wall = Instant::now();
    for v in v0..v1 {
        out.add(join.run_partition(v, &mut sc));
    }
    let secs = wall.elapsed().as_secs_f64();
    out.hits.sort_unstable();
    out.near.sort_unstable();
    if tol == 64 {
        if let Ok(path) = std::env::var("NM_SAMPLE_OUT") {
            use std::io::Write;
            let mut f = std::fs::OpenOptions::new().create(true).append(true).open(path).unwrap();
            for x in &out.sample {
                writeln!(f, "{base} {x}").unwrap();
            }
        }
    }
    let kreps: Vec<String> = out
        .kreps
        .iter()
        .enumerate()
        .filter(|&(_, &c)| c > 0)
        .map(|(i, c)| format!("{}:{}:{c}", i / 65, i % 65))
        .collect();
    println!(
        "RUN b{base} start {start} size {size:e} slice {si}/{} v {v0}..{v1} tol {tol} setup {setup:.3} secs {secs:.4} \
         survivors {} checked {} hits {:?} near {:?} reps {:?} pre {:?} kreps {}",
        slices.len(),
        out.survivors,
        out.checked,
        out.hits,
        out.near,
        out.reps,
        out.pre,
        kreps.join(",")
    );
}

fn main() {
    let a: Vec<String> = std::env::args().collect();
    match a[1].as_str() {
        "bf" => bf(&a),
        "run" => run(&a),
        m => panic!("mode {m}"),
    }
}
