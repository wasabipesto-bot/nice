//! L50 harness (scratch, not for a PR): L49's `l49_ab` plus the setup time,
//! the `l50-prof` counters, and a recording mode for the checked `n`.
//!
//! usage: l50_prof <base> <start> <size> <threads> <partitions|0=all> [slice]
//! env: L50_RECORD=<file> (needs `l50-prof`): write every checked n (u128 LE).
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
    let t = Instant::now();
    let (jp, slices) = slices_for(base, &range).expect("a join field");
    let join = CpuJoin::new(base, &slices[si], jp).expect("setup");
    let setup = t.elapsed().as_secs_f64();
    let parts = join.partitions();
    let order = sample_order(parts);
    let n = if want == 0 { order.len() } else { want.min(order.len()) };
    println!(
        "b{base} [{start}, +{size:e}) {jp:?}: {} slices, slice {si}; setup {setup:.3}s (fs {:.3}s); {parts} partitions, running {n} on {threads} thread(s)",
        slices.len(),
        join.setup_secs()
    );
    #[cfg(feature = "l50-prof")]
    if let Ok(path) = std::env::var("L50_RECORD") {
        let mut rec = Vec::new();
        let mut sc = Scratch::default();
        let mut out = PartitionResult::default();
        for &v in &order[..n] {
            out.add(join.run_partition_recording(v, &mut sc, &mut rec));
        }
        let bytes: Vec<u8> = rec.iter().flat_map(|x| x.to_le_bytes()).collect();
        std::fs::write(&path, bytes).unwrap();
        println!("recorded {} checked n to {path}; survivors {} checked {}", rec.len(), out.survivors, out.checked);
        return;
    }
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
    #[cfg(feature = "l50-prof")]
    {
        use nice_common::cpu_join::l50::{C, NAMES};
        let v: Vec<u64> = C.iter().map(|c| c.load(Ordering::Relaxed)).collect();
        let tp = v[5] as f64;
        print!("prof bpre {}:", join.bpre_len());
        for (i, name) in NAMES.iter().enumerate() {
            print!(" {name}={}", v[i]);
        }
        println!();
        let ph = ["tops", "extend", "sort", "list", "scan+surv"];
        let mut s = String::from("split %:");
        for (i, p) in ph.iter().enumerate() {
            s += &format!(" {p} {:.2}", 100.0 * v[i] as f64 / tp);
        }
        let rest = tp - v[..5].iter().sum::<u64>() as f64;
        s += &format!(" other {:.2}", 100.0 * rest / tp);
        println!("{s}");
        let np = v[6] as f64;
        println!(
            "per partition: tsc {:.3e}; slots_fd {:.0} seeds {:.0} ({:.2} %) steps {:.0} ({:.3}/slot) clipped {:.1} kept {:.0} ({:.1} %); ext_rows {:.0}, listed {:.0}; ands {:.4e}, class scans {:.4e} (ands/scan {:.1}); survivors {:.4e} checked {:.4e}",
            tp / np,
            v[8] as f64 / np,
            v[9] as f64 / np,
            100.0 * v[9] as f64 / v[8].max(1) as f64,
            v[10] as f64 / np,
            v[10] as f64 / v[8].max(1) as f64,
            v[11] as f64 / np,
            v[12] as f64 / np,
            100.0 * v[12] as f64 / (v[8] + v[11]).max(1) as f64,
            v[13] as f64 / np,
            v[14] as f64 / np,
            v[15] as f64 / np,
            v[16] as f64 / np,
            v[15] as f64 / v[16].max(1) as f64,
            out.survivors as f64 / np,
            out.checked as f64 / np,
        );
        let gs: u64 = v[18..29].iter().sum();
        let mut g = String::from("gap histogram (% of FD slots):");
        for i in 18..29 {
            g += &format!(" {} {:.3}", NAMES[i], 100.0 * v[i] as f64 / gs.max(1) as f64);
        }
        println!("{g}");
        println!(
            "unit tsc: per slot (tops) {:.1}; per AND (scan+surv) {:.2}; per listed (list) {:.1}; per ext row (extend) {:.1}",
            v[0] as f64 / (v[8] + v[11]).max(1) as f64,
            v[4] as f64 / v[15].max(1) as f64,
            v[3] as f64 / v[14].max(1) as f64,
            v[1] as f64 / v[13].max(1) as f64,
        );
    }
}
