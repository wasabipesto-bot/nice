//! CPU2 scratch: in the client's pattern, `(0..n).into_par_iter()
//! .map_init(Scratch::default, ..)`, how many items start a fresh run (a new
//! scratch, or not the scratch's last item + 1)? And with one scratch per
//! worker thread instead (thread-local): how many items come after a lower
//! one on the same thread (the runs carry over), and how many directly
//! after their predecessor? Items sleep 1 ms (no CPU). usage: <n>
use rayon::prelude::*;
use std::cell::Cell;
use std::sync::atomic::{AtomicU32, Ordering};
thread_local! { static LAST: Cell<u32> = const { Cell::new(u32::MAX) }; }
fn main() {
    let n: u32 = std::env::args().nth(1).unwrap().parse().unwrap();
    for threads in [2usize, 4, 8, 16, 32, 64] {
        let pool = rayon::ThreadPoolBuilder::new().num_threads(threads).build().unwrap();
        let (fresh, tl_asc, tl_next) = (AtomicU32::new(0), AtomicU32::new(0), AtomicU32::new(0));
        pool.install(|| {
            (0..n)
                .into_par_iter()
                .map_init(
                    || u32::MAX,
                    |last, v| {
                        if *last == u32::MAX || v != *last + 1 {
                            fresh.fetch_add(1, Ordering::Relaxed);
                        }
                        *last = v;
                        LAST.with(|l| {
                            let p = l.get();
                            if p != u32::MAX && p < v {
                                tl_asc.fetch_add(1, Ordering::Relaxed);
                            }
                            if p != u32::MAX && p + 1 == v {
                                tl_next.fetch_add(1, Ordering::Relaxed);
                            }
                            l.set(v);
                        });
                        std::thread::sleep(std::time::Duration::from_millis(1));
                    },
                )
                .count();
        });
        let f = fresh.load(Ordering::Relaxed);
        println!(
            "threads {threads}: map_init scratch: {f} of {n} items start a run (mean run {:.1}); per-thread scratch: {} items follow a lower one, {} follow their predecessor",
            f64::from(n) / f64::from(f),
            tl_asc.load(Ordering::Relaxed),
            tl_next.load(Ordering::Relaxed)
        );
        // reset thread-locals: a new pool has new threads.
    }
}
