//! A/B harness (not part of the PR): run sampled partitions of one slice of
//! a nice-only field through the CPU join (public API only) and print the
//! wall time and the survivor / checked counts.
//!
//! usage: l52_ab <base> <start> <size> <threads> <partitions|0=all> [slice]
use nice_common::FieldSize;
use nice_common::bench_defs::sample_order;
use nice_common::cpu_join::{CpuJoin, PartitionResult, Scratch, slices_for};
use std::sync::atomic::{AtomicUsize, Ordering};
use std::time::Instant;

fn main() {
    let a: Vec<String> = std::env::args().collect();
    let base: u32 = a[1].parse().unwrap();
    let start: u128 = a[2].parse().unwrap();
    let size: u128 = a[3]
        .parse::<f64>()
        .map(|x| x as u128)
        .unwrap_or_else(|_| a[3].parse().unwrap());
    let threads: usize = a[4].parse().unwrap();
    let want: usize = a[5].parse().unwrap();
    let si: usize = a.get(6).map_or(0, |s| s.parse().unwrap());
    let range = FieldSize::new(start, start + size);
    let (jp, slices) = slices_for(base, &range).expect("a join field");
    let t = Instant::now();
    let join = CpuJoin::new(base, &slices[si], jp).expect("setup");
    let setup = t.elapsed().as_secs_f64();
    let parts = join.partitions();
    let order = sample_order(parts);
    let n = if want == 0 { order.len() } else { want.min(order.len()) };
    println!(
        "b{base} [{start}, +{size:e}) {jp:?}: {} slices, slice {si}; setup {setup:.3}s; {parts} partitions, running {n} on {threads} thread(s)",
        slices.len()
    );
    let next = AtomicUsize::new(0);
    let wall = Instant::now();
    let out = std::thread::scope(|s| {
        let ws: Vec<_> = (0..threads)
            .map(|_| {
                s.spawn(|| {
                    let mut sc = Scratch::default();
                    let mut out = PartitionResult::default();
                    loop {
                        let i = next.fetch_add(1, Ordering::Relaxed);
                        if i >= n {
                            return out;
                        }
                        out.add(join.run_partition(order[i], &mut sc));
                    }
                })
            })
            .collect();
        let mut out = PartitionResult::default();
        for w in ws {
            out.add(w.join().unwrap());
        }
        out
    });
    let secs = wall.elapsed().as_secs_f64();
    let per = secs * threads as f64 / n as f64;
    println!(
        "wall {secs:.3}s; {:.3} ms/partition/thread; survivors {} checked {} hits {}",
        per * 1e3,
        out.survivors,
        out.checked,
        out.hits.len(),
    );
}
