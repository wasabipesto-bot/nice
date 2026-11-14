// Reviewer's main-vs-branch comparison (CPU2 review, 2026-11-14); shared body,
// `include!`d by cmp_main.rs / cmp_branch.rs, which each define
//   struct Emu (per simulated thread state for the tops walk),
//   fn emu_new() -> Emu,
//   fn emu_tops(join: &CpuJoin, v: u32, emu: &mut Emu) -> Vec<Top>.
// Every event (field, slice, thread, partition) prints the partition's tops
// (count + hash of their Debug form, in order) and `run_partition`'s result
// with that thread's own long-lived Scratch. The two outputs must be equal.

use super::{CpuJoin, Scratch, Top, slices_for};
use crate::FieldSize;
use crate::base_range::get_base_range_u128;
use crate::overlap_join::JoinParams;
use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};
use std::io::Write;

struct Rng(u64);
impl Rng {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E37_79B9_7F4A_7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58_476D_1CE4_E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D0_49BB_1331_11EB);
        z ^ (z >> 31)
    }
    fn below(&mut self, n: u64) -> u64 {
        self.next() % n
    }
}

/// A rayon-like schedule of `vs` on `threads` threads, plus disorder:
/// chunks of 1-24 partitions dealt to random threads, sometimes out of
/// order, retries of the same partition, a step back by one, and gaps of
/// 1-30 (so RUN_GAP's edge is crossed). Events are (thread, v) in time order.
fn schedule(vs: &[u32], threads: usize, rng: &mut Rng) -> Vec<(usize, u32)> {
    let mut chunks: Vec<Vec<u32>> = Vec::new();
    let mut i = 0;
    while i < vs.len() {
        let len = 1 + rng.below(24) as usize;
        chunks.push(vs[i..(i + len).min(vs.len())].to_vec());
        i += len;
    }
    for k in 1..chunks.len() {
        if rng.below(4) == 0 {
            chunks.swap(k - 1, k);
        }
    }
    let mut per: Vec<Vec<u32>> = vec![Vec::new(); threads];
    for c in chunks {
        let t = rng.below(threads as u64) as usize;
        for &v in &c {
            per[t].push(v);
            match rng.below(40) {
                0 => per[t].push(v),                      // retry
                1 if v > 0 => per[t].push(v - 1),         // a step back
                2 => per[t].push(v + 1 + rng.below(30) as u32), // a gap ahead
                _ => {}
            }
        }
    }
    // Interleave the threads in time.
    let mut pos = vec![0usize; threads];
    let mut out = Vec::new();
    loop {
        let live: Vec<usize> = (0..threads).filter(|&t| pos[t] < per[t].len()).collect();
        if live.is_empty() {
            return out;
        }
        let t = live[rng.below(live.len() as u64) as usize];
        out.push((t, per[t][pos[t]]));
        pos[t] += 1;
    }
}

fn hash_tops(tops: &[Top]) -> u64 {
    let mut h = DefaultHasher::new();
    format!("{tops:?}").hash(&mut h);
    h.finish()
}

struct Job {
    label: String,
    join: CpuJoin,
    vs: Vec<u32>,
}

/// Run every job's schedule, all jobs interleaved on the same simulated
/// threads (so a thread's state meets several joins), then each job once
/// more in ascending order on one fresh thread.
fn run_jobs(jobs: &[Job], seed: u64, out: &mut impl Write) {
    let threads = 3;
    let mut rng = Rng(seed);
    let mut events: Vec<(usize, usize, u32)> = Vec::new();
    let scheds: Vec<Vec<(usize, u32)>> =
        jobs.iter().map(|j| schedule(&j.vs, threads, &mut rng)).collect();
    let mut pos = vec![0usize; jobs.len()];
    loop {
        let live: Vec<usize> = (0..jobs.len()).filter(|&k| pos[k] < scheds[k].len()).collect();
        if live.is_empty() {
            break;
        }
        // Mostly stay on one job for a while, as a client does per slice.
        let k = live[rng.below(live.len() as u64) as usize];
        for _ in 0..1 + rng.below(6) {
            if pos[k] < scheds[k].len() {
                let (t, v) = scheds[k][pos[k]];
                events.push((t, k, v));
                pos[k] += 1;
            }
        }
    }
    let mut emus: Vec<Emu> = (0..threads).map(|_| emu_new()).collect();
    let mut scs: Vec<Scratch> = (0..threads).map(|_| Scratch::default()).collect();
    for &(t, k, v) in &events {
        let job = &jobs[k];
        if v >= job.join.partitions() {
            continue;
        }
        let tops = emu_tops(&job.join, v, &mut emus[t]);
        let r = job.join.run_partition(v, &mut scs[t]);
        writeln!(
            out,
            "{} v={v}: tops={} hash={:016x} surv={} chk={} hits={:?}",
            job.label,
            tops.len(),
            hash_tops(&tops),
            r.survivors,
            r.checked,
            r.hits
        )
        .unwrap();
    }
    for job in jobs {
        let mut emu = emu_new();
        let mut sc = Scratch::default();
        for &v in &job.vs {
            let tops = emu_tops(&job.join, v, &mut emu);
            let r = job.join.run_partition(v, &mut sc);
            writeln!(
                out,
                "{} v={v}: tops={} hash={:016x} surv={} chk={} hits={:?}",
                job.label,
                tops.len(),
                hash_tops(&tops),
                r.survivors,
                r.checked,
                r.hits
            )
            .unwrap();
        }
    }
}

fn windows(n: u32, len: u32) -> Vec<u32> {
    if n <= 3 * len {
        return (0..n).collect();
    }
    let mut v: Vec<u32> = (0..len).collect();
    v.extend(n / 2 - len / 2..n / 2 + len / 2);
    v.extend(n - len..n);
    v
}

fn out_file(name: &str) -> std::fs::File {
    let dir = std::env::var("REVIEW_OUT").expect("REVIEW_OUT dir");
    std::fs::File::create(format!("{dir}/{name}")).unwrap()
}

/// Production-shape fields at bases 40-64 at band positions the author did
/// not use, windows of partitions at the start, middle and end of the
/// first and last slice.
#[test]
#[ignore = "review harness"]
fn review_cmp_production() {
    let mut out = out_file(&format!(
        "{}-production.txt",
        std::env::var("REVIEW_TAG").unwrap()
    ));
    let len: u32 = std::env::var("REVIEW_WINDOW")
        .ok()
        .and_then(|x| x.parse().ok())
        .unwrap_or(12);
    let bases: Vec<u32> = std::env::var("REVIEW_PBASES")
        .unwrap_or_else(|_| "40,44,48,52,56,57,58,59,60,61,62,63,64".into())
        .split(',')
        .map(|x| x.parse().unwrap())
        .collect();
    for b in bases {
        let Some(band) = get_base_range_u128(b).unwrap() else {
            continue;
        };
        let t0 = std::time::Instant::now();
        let mut jobs = Vec::new();
        // fraction of the band (per mille) and field size
        for &(pm, size) in &[
            (0u128, 100_000_000_000_000u128),
            (71, 1_000_000_000_000_000),
            (830, 100_000_000_000_000),
            (1000, 10_000_000_000_000_000),
        ] {
            let size = size.min(band.size());
            let s = if pm == 1000 {
                band.end() - size
            } else {
                band.start() + (band.size() - size) / 1000 * pm
            };
            let range = FieldSize::new(s, s + size);
            let Some((jp, slices)) = slices_for(b, &range) else {
                writeln!(out, "b{b} {s}+{size}: no join").unwrap();
                continue;
            };
            let nsl = slices.len();
            let mut picks = vec![0usize];
            if nsl > 1 {
                picks.push(nsl - 1);
            }
            for si in picks {
                let join = CpuJoin::new(b, &slices[si], jp).unwrap();
                let vs = windows(join.partitions(), len);
                jobs.push(Job {
                    label: format!("b{b} {s}+{size} {jp:?} slice {si}/{nsl}"),
                    join,
                    vs,
                });
            }
        }
        run_jobs(&jobs, 0x5EED ^ u64::from(b), &mut out);
        eprintln!("b{b}: {} jobs, {:.0}s; {}", jobs.len(), t0.elapsed().as_secs_f64(), emu_report());
    }
}

/// Small bases, whole joins: random fields (offsets and sizes the author's
/// test did not use), every supported shape with p 0-2 and bounded work,
/// every partition.
#[test]
#[ignore = "review harness"]
fn review_cmp_small() {
    let mut out = out_file(&format!("{}-small.txt", std::env::var("REVIEW_TAG").unwrap()));
    let mut rng = Rng(0xABCD_0123);
    let mut njobs = 0;
    // 10-34: at b35 one of the enumerated shapes needs more memory than ivory has.
    for b in 10..=34u32 {
        let Some(band) = get_base_range_u128(b).unwrap() else {
            continue;
        };
        for fi in 0..3u64 {
            // One field's shapes at a time (memory: ivory has 7 GB).
            let mut jobs = Vec::new();
            let size = (u128::from(rng.next()) % 3_000_000 + 50_000).min(band.size());
            let s = band.start() + u128::from(rng.next()) % (band.size() - size + 1);
            let range = FieldSize::new(s, s + size);
            let Some(base) = crate::overlap_join::Base::try_new(b, s, s + size - 1) else {
                continue;
            };
            let l = base.l;
            for t in 1..l {
                for k in 1..l {
                    for p in 0..=2 {
                        let jp = JoinParams { t, k, p };
                        if !jp.supported(b, l) {
                            continue;
                        }
                        let Ok(join) = CpuJoin::new(b, &range, jp) else {
                            continue;
                        };
                        let work = join.fs.tlay.len() as u64 * u64::from(join.partitions());
                        if work > 2_000_000 || join.fs.tlay.is_empty() {
                            continue;
                        }
                        let vs: Vec<u32> = (0..join.partitions()).collect();
                        jobs.push(Job {
                            label: format!("b{b} {s}+{size} {jp:?}"),
                            join,
                            vs,
                        });
                    }
                }
            }
            njobs += jobs.len();
            run_jobs(&jobs, 0x77 ^ u64::from(b) ^ (fi << 8), &mut out);
        }
    }
    eprintln!("{njobs} small-base joins; {}", emu_report());
}

/// Fields with tops at bases 58-64 (most fixed positions above have none):
/// scan band positions in steps of 3.7 % for 1e15 fields (and 1e17 at b62,
/// b64) whose first slice has a non-empty top layer, take the first three
/// (one for 1e17), windows of partitions at the start, middle and end of the
/// first and last slice.
#[test]
#[ignore = "review harness"]
fn review_cmp_production_hunt() {
    let mut out = out_file(&format!("{}-hunt.txt", std::env::var("REVIEW_TAG").unwrap()));
    let len: u32 = std::env::var("REVIEW_WINDOW")
        .ok()
        .and_then(|x| x.parse().ok())
        .unwrap_or(12);
    for (b, size, want) in [
        (62u32, 1_000_000_000_000_000u128, 3usize),
        (64, 1_000_000_000_000_000, 3),
        (63, 1_000_000_000_000_000, 2),
        (60, 1_000_000_000_000_000, 2),
        (58, 1_000_000_000_000_000, 1),
        (62, 100_000_000_000_000_000, 1),
        (64, 100_000_000_000_000_000, 1),
    ] {
        let band = get_base_range_u128(b).unwrap().unwrap();
        let t0 = std::time::Instant::now();
        let mut jobs = Vec::new();
        let mut found = 0;
        let mut pm = 13u128;
        while pm < 1000 && found < want {
            let s = band.start() + (band.size() - size) / 1000 * pm;
            pm += 37;
            let range = FieldSize::new(s, s + size);
            let Some((jp, slices)) = slices_for(b, &range) else {
                continue;
            };
            let first = CpuJoin::new(b, &slices[0], jp).unwrap();
            if first.fs.tlay.is_empty() {
                continue;
            }
            found += 1;
            let nsl = slices.len();
            let w = if size > 1_000_000_000_000_000 { len.min(8) } else { len };
            let vs = windows(first.partitions(), w);
            jobs.push(Job {
                label: format!("b{b} {s}+{size} {jp:?} slice 0/{nsl}"),
                join: first,
                vs,
            });
            if nsl > 1 {
                let join = CpuJoin::new(b, &slices[nsl - 1], jp).unwrap();
                let vs = windows(join.partitions(), w);
                jobs.push(Job {
                    label: format!("b{b} {s}+{size} {jp:?} slice {}/{nsl}", nsl - 1),
                    join,
                    vs,
                });
            }
        }
        run_jobs(&jobs, 0x4A17 ^ u64::from(b) ^ (size as u64), &mut out);
        eprintln!(
            "b{b} {size:e}: {} jobs, {:.0}s; {}",
            jobs.len(),
            t0.elapsed().as_secs_f64(),
            emu_report()
        );
    }
}
