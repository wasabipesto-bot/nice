//! Experiment harness for the wide join (branch `exp/join-wide` only; never
//! shipped). CPU only, so it builds with or without `wide-join`; every line
//! it prints carries `mask_bits` (64, or 128 with `wide-join`).
//!
//! `jwide list THREADS < lines`: for each `base start size` line, the
//! field's top-layer density, as `scenario_probe list` prints it:
//! `base start size prefixes max_prefixes`.
//!
//! `jwide join BASE WIDTH THREADS SAMPLE S1 [S2 ...]`: the CPU join on each
//! field `[S, S + WIDTH)`. Every slice is set up, and SAMPLE of its
//! partitions, spread evenly as `jbench cpu` spreads them, run on THREADS
//! threads; each partition is timed on its thread. The field's estimate is
//! the sum over its slices of setup + mean partition time × partitions.
//!
//! `jwide stride BASE WIDTH THREADS CHUNKS SEED S1 [S2 ...]`: the client's
//! CPU stride path (`process_range_niceonly`, LSD k = 3) on CHUNKS chunks of
//! 1e9 at random positions of each field's production chunk grid (the
//! client cuts fields of 1e14 and up into 1e9 chunks from their start),
//! each timed on its thread. Chunk costs are heavy-tailed, so the mean is
//! reported with its standard error and the distribution.
//!
//! One JSON line per field.
use anyhow::{Result, bail};
use nice_common::FieldSize;
use nice_common::base_range::get_base_range_u128;
use nice_common::client_process::{get_is_nice, process_range_niceonly};
use nice_common::cpu_join::{CpuJoin, PartitionResult, Scratch, slices_for};
use nice_common::overlap_join::{Base, JoinParams, Mask, join_verdict, ndigits};
use nice_common::stride_filter::StrideTable;
use serde_json::json;
use std::sync::Mutex;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::time::Instant;

/// The client's chunk for nice-only fields of 1e14 and up.
const CHUNK: u128 = 1_000_000_000;

fn fields(width: u128, starts: &[String]) -> Result<Vec<FieldSize>> {
    starts
        .iter()
        .map(|s| {
            let s: u128 = s.parse()?;
            Ok(FieldSize::new(s, s + width))
        })
        .collect()
}

/// Run `f` on items `0..n` on `threads` threads; each item's result and its
/// own time on its thread, in item order.
fn timed_items<T: Send>(
    n: usize,
    threads: usize,
    f: impl Fn(usize) -> T + Sync,
) -> (Vec<(T, f64)>, f64) {
    let next = AtomicUsize::new(0);
    let out: Mutex<Vec<Option<(T, f64)>>> = Mutex::new((0..n).map(|_| None).collect());
    let t0 = Instant::now();
    std::thread::scope(|s| {
        for _ in 0..threads.max(1) {
            s.spawn(|| {
                loop {
                    let i = next.fetch_add(1, Ordering::Relaxed);
                    if i >= n {
                        return;
                    }
                    let t = Instant::now();
                    let r = f(i);
                    let secs = t.elapsed().as_secs_f64();
                    out.lock().unwrap()[i] = Some((r, secs));
                }
            });
        }
    });
    let wall = t0.elapsed().as_secs_f64();
    let items = out
        .into_inner()
        .unwrap()
        .into_iter()
        .map(|x| x.expect("every item ran"))
        .collect();
    (items, wall)
}

fn list(a: &[String]) -> Result<()> {
    use std::io::BufRead;
    let threads: usize = a[2].parse()?;
    let lines: Vec<(u32, u128, u128)> = std::io::stdin()
        .lock()
        .lines()
        .map(|l| {
            let l = l?;
            let v: Vec<&str> = l.split_whitespace().collect();
            Ok((v[0].parse()?, v[1].parse()?, v[2].parse()?))
        })
        .collect::<Result<_>>()?;
    let (rows, _) = timed_items(lines.len(), threads, |i| {
        let (b, s, size) = lines[i];
        let e = s + size;
        let l = ndigits(e - 1, b);
        let jp = JoinParams::for_length(b, l).expect("join parameters");
        let depth = jp.t - jp.p;
        let block = u128::from(b).pow(l - depth);
        let base = Base::try_new(b, s, e - 1).expect("one digit length");
        let p = base.top_layer(s, e - 1, depth, jp.k).len();
        format!("{b} {s} {size} {p} {}", (e - s).div_ceil(block))
    });
    for (r, _) in rows {
        println!("{r}");
    }
    Ok(())
}

#[allow(clippy::cast_precision_loss)]
fn join(a: &[String]) -> Result<()> {
    let b: u32 = a[2].parse()?;
    let width: u128 = a[3].parse()?;
    let threads: usize = a[4].parse()?;
    let sample: usize = a[5].parse()?;
    for f in fields(width, &a[6..])? {
        let Some((jp, slices)) = slices_for(b, &f) else {
            let reason = join_verdict(b, &f).err().map(|r| r.label());
            println!(
                "{}",
                json!({"kind": "join", "base": b, "start": f.start().to_string(), "join": false,
                    "reason": reason, "mask_bits": Mask::BITS})
            );
            continue;
        };
        let (mut setup, mut est, mut sampled_secs, mut wall_secs) = (0.0, 0.0, 0.0, 0.0);
        let (mut sampled, mut partitions) = (0usize, 0usize);
        let mut out = PartitionResult::default();
        let mut per_slice = Vec::new();
        // Every sampled partition's time over its slice's mean, for the
        // spread (and so the sampling error) of the estimate.
        let mut rel = Vec::new();
        // Seconds in each phase of the CPU join (feature `join-prof`).
        let mut phases = [0.0f64; 4];
        for slice in &slices {
            let ts = Instant::now();
            let join = CpuJoin::new(b, slice, jp)?;
            let su = ts.elapsed().as_secs_f64();
            let parts = join.partitions() as usize;
            let k = sample.min(parts).max(1);
            let picks: Vec<u32> = (0..k)
                .map(|i| u32::try_from(i * parts / k).expect("b^p fits u32"))
                .collect();
            let (items, wall) = timed_items(k, threads, |i| {
                thread_local! {
                    static SCRATCH: std::cell::RefCell<Scratch> =
                        std::cell::RefCell::new(Scratch::default());
                }
                let r = SCRATCH.with(|sc| join.run_partition(picks[i], &mut sc.borrow_mut()));
                (r, phases_taken())
            });
            let secs: f64 = items.iter().map(|(_, s)| s).sum();
            let per_part = secs / k as f64;
            for ((r, ph), s) in items {
                out.add(r);
                rel.push(s / per_part);
                for (t, x) in phases.iter_mut().zip(ph) {
                    *t += x;
                }
            }
            let slice_est = su + per_part * parts as f64;
            per_slice.push(
                json!({"start": slice.start().to_string(), "size": slice.size().to_string(),
                "setup_secs": su, "core_secs_per_partition": per_part, "est_core_secs": slice_est}),
            );
            setup += su;
            est += slice_est;
            sampled_secs += secs;
            wall_secs += wall * threads.max(1) as f64;
            sampled += k;
            partitions = parts;
        }
        println!(
            "{}",
            json!({"kind": "join", "base": b, "start": f.start().to_string(), "width": width.to_string(),
                "join": true, "t": jp.t, "k": jp.k, "p": jp.p, "mask_bits": Mask::BITS,
                "slices": slices.len(), "partitions": partitions, "sampled": sampled,
                "threads": threads, "setup_secs": setup,
                "core_secs_per_partition": sampled_secs / sampled as f64,
                "wall_core_secs_per_partition": wall_secs / sampled as f64,
                "field_core_secs_est": est, "core_secs_per_number": est / width as f64,
                "partition_cv": cv(&rel), "phase_secs": phases.map(|x| x / sampled as f64),
                "survivors": out.survivors, "checked": out.checked,
                "hits": out.hits.len(), "per_slice": per_slice})
        );
    }
    Ok(())
}

/// The CPU join's phase times on this thread since the last call (tops,
/// extend, list, scan), with the `join-prof` feature; zeros without it.
fn phases_taken() -> [f64; 4] {
    #[cfg(feature = "join-prof")]
    return nice_common::cpu_join::prof::take();
    #[cfg(not(feature = "join-prof"))]
    [0.0; 4]
}

/// The coefficient of variation of `x`.
#[allow(clippy::cast_precision_loss)]
fn cv(x: &[f64]) -> f64 {
    let n = x.len() as f64;
    let mean = x.iter().sum::<f64>() / n;
    let var = x.iter().map(|v| (v - mean).powi(2)).sum::<f64>() / (n - 1.0).max(1.0);
    var.sqrt() / mean
}

/// A splitmix64 stream.
struct Rng(u64);

impl Rng {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E37_79B9_7F4A_7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58_476D_1CE4_E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D0_49BB_1331_11EB);
        z ^ (z >> 31)
    }

    fn below(&mut self, n: u128) -> u128 {
        ((u128::from(self.next()) << 64) | u128::from(self.next())) % n
    }
}

#[allow(clippy::cast_precision_loss)]
fn stride(a: &[String]) -> Result<()> {
    let b: u32 = a[2].parse()?;
    let width: u128 = a[3].parse()?;
    let threads: usize = a[4].parse()?;
    let chunks: usize = a[5].parse()?;
    let seed: u64 = a[6].parse()?;
    // The client's CPU table (`DEFAULT_LSD_K_VALUE`).
    let table = StrideTable::new(b, 3);
    let mut rng = Rng(seed);
    for f in fields(width, &a[7..])? {
        let grid = width.div_ceil(CHUNK);
        let picks: Vec<FieldSize> = (0..chunks)
            .map(|_| {
                let s = f.start() + rng.below(grid) * CHUNK;
                FieldSize::new(s, (s + CHUNK).min(f.end()))
            })
            .collect();
        let (items, wall) = timed_items(picks.len(), threads, |i| {
            process_range_niceonly(&picks[i], b, &table)
                .nice_numbers
                .len()
        });
        let mut secs: Vec<f64> = items.iter().map(|(_, s)| *s).collect();
        let hits: usize = items.iter().map(|(h, _)| h).sum();
        let n = secs.len() as f64;
        let mean = secs.iter().sum::<f64>() / n;
        let var = secs.iter().map(|s| (s - mean).powi(2)).sum::<f64>() / (n - 1.0).max(1.0);
        secs.sort_by(f64::total_cmp);
        let q = |p: f64| secs[((n - 1.0) * p).round() as usize];
        println!(
            "{}",
            json!({"kind": "stride", "base": b, "start": f.start().to_string(), "width": width.to_string(),
                "mask_bits": Mask::BITS, "chunk": CHUNK.to_string(), "chunks": picks.len(),
                "seed": seed, "threads": threads,
                "core_secs_per_chunk": mean, "se_core_secs_per_chunk": (var / n).sqrt(),
                "wall_core_secs_per_chunk": wall * threads.max(1) as f64 / n,
                "min": q(0.0), "p50": q(0.5), "p90": q(0.9), "p99": q(0.99), "max": q(1.0),
                "live_share": secs.iter().filter(|&&s| s > 1e-3).count() as f64 / n,
                "core_secs_per_number": mean / CHUNK as f64,
                "field_core_secs_est": mean * (width as f64 / CHUNK as f64),
                "hits": hits})
        );
    }
    Ok(())
}

/// `jwide grid BASE SIZE N SEED`: N distinct random fields of SIZE on the
/// grid `range_start + i·SIZE` of BASE, as `base start size` lines (for
/// `list`), in order.
fn grid(a: &[String]) -> Result<()> {
    let b: u32 = a[2].parse()?;
    let size: u128 = a[3].parse::<f64>()? as u128;
    let n: usize = a[4].parse()?;
    let mut rng = Rng(a[5].parse()?);
    let Some(r) = get_base_range_u128(b)? else {
        bail!("base {b} has no range");
    };
    let cells = r.size() / size;
    let mut picks = std::collections::BTreeSet::new();
    while picks.len() < n.min(usize::try_from(cells).unwrap_or(usize::MAX)) {
        picks.insert(rng.below(cells));
    }
    for i in picks {
        println!("{b} {} {size}", r.start() + i * size);
    }
    Ok(())
}

/// `jwide check BASE N SEED`: the client's full nice check (`get_is_nice`)
/// on N random numbers of BASE's range, one thread: nanoseconds per call.
#[allow(clippy::cast_precision_loss)]
fn check(a: &[String]) -> Result<()> {
    let b: u32 = a[2].parse()?;
    let n: usize = a[3].parse()?;
    let mut rng = Rng(a[4].parse()?);
    let Some(r) = get_base_range_u128(b)? else {
        bail!("base {b} has no range");
    };
    let xs: Vec<u128> = (0..n).map(|_| r.start() + rng.below(r.size())).collect();
    let t = Instant::now();
    let nice = xs.iter().filter(|&&x| get_is_nice(x, b)).count();
    let secs = t.elapsed().as_secs_f64();
    println!(
        "{}",
        json!({"kind": "check", "base": b, "calls": n, "ns_per_call": secs * 1e9 / n as f64,
            "nice": nice})
    );
    Ok(())
}

fn main() -> Result<()> {
    let a: Vec<String> = std::env::args().collect();
    match a.get(1).map(String::as_str) {
        Some("list") => list(&a),
        Some("join") => join(&a),
        Some("stride") => stride(&a),
        Some("grid") => grid(&a),
        Some("check") => check(&a),
        _ => bail!(
            "usage: jwide list THREADS < lines | jwide join BASE WIDTH THREADS SAMPLE S... | \
             jwide stride BASE WIDTH THREADS CHUNKS SEED S... | jwide grid BASE SIZE N SEED | \
             jwide check BASE N SEED"
        ),
    }
}
