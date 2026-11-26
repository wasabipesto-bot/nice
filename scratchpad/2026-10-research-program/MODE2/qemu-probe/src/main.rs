// Spawn-and-join churn as par_map does it: ROUNDS scopes of K threads each, trivial work.
// Prints the process's VmRSS / VmHWM (from /proc/self/status) every STEP threads.
use std::time::Instant;
fn status(k: &str) -> String {
    std::fs::read_to_string("/proc/self/status").ok()
        .and_then(|s| s.lines().find(|l| l.starts_with(k)).map(|l| l.split_whitespace().nth(1).unwrap_or("?").to_string()))
        .unwrap_or_else(|| "?".into())
}
fn main() {
    let a: Vec<usize> = std::env::args().skip(1).map(|x| x.parse().unwrap()).collect();
    let (total, k, step) = (a[0], a[1], a[2]);
    let t0 = Instant::now();
    let mut spawned = 0usize;
    let mut acc = 0u64;
    println!("threads_spawned rss_kib hwm_kib secs");
    while spawned < total {
        let r: u64 = std::thread::scope(|s| {
            let hs: Vec<_> = (0..k).map(|i| s.spawn(move || (i as u64).wrapping_mul(2654435761))).collect();
            hs.into_iter().map(|h| h.join().unwrap()).sum()
        });
        acc = acc.wrapping_add(r);
        let before = spawned;
        spawned += k;
        if spawned / step != before / step {
            println!("{spawned} {} {} {:.2}", status("VmRSS:"), status("VmHWM:"), t0.elapsed().as_secs_f64());
        }
    }
    println!("done {acc}");
}
