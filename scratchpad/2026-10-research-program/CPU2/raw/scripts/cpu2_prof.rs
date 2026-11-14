//! CPU2 scratch (not for the PR): the CPU join's top phase at production
//! shapes. usage: cpu2_prof <base> <start|fFRAC> <size> <partitions> [slices: all|i]
use nice_common::FieldSize;
use nice_common::base_range::get_base_range_u128;
use nice_common::bench_defs::sample_order;
use nice_common::cpu_join::{CpuJoin, Scratch, slices_for};
use std::time::Instant;

fn main() {
    let a: Vec<String> = std::env::args().collect();
    let base: u32 = a[1].parse().unwrap();
    let size: u128 = a[3].parse::<f64>().unwrap() as u128;
    let start: u128 = if let Some(f) = a[2].strip_prefix('f') {
        let band = get_base_range_u128(base).unwrap().unwrap();
        let f: f64 = f.parse().unwrap();
        let off = (band.size() as f64 * f) as u128;
        let s = band.start() + off / size * size;
        s.min(band.end() - size)
    } else {
        a[2].parse().unwrap()
    };
    let want: usize = a[4].parse().unwrap();
    let range = FieldSize::new(start, start + size);
    let (jp, slices) = slices_for(base, &range).expect("a join field");
    let which: Vec<usize> = match a.get(5).map(String::as_str) {
        None | Some("all") => (0..slices.len()).collect(),
        Some("spread") => {
            let mut v = vec![0, slices.len() / 2, slices.len() - 1];
            v.dedup();
            v
        }
        Some(i) => vec![i.parse().unwrap()],
    };
    println!(
        "FIELD b{base} start {start} size {size:e} {jp:?} slices {}",
        slices.len()
    );
    for si in which {
        let t = Instant::now();
        let join = CpuJoin::new(base, &slices[si], jp).expect("setup");
        let setup = t.elapsed().as_secs_f64();
        let parts = join.partitions();
        let order = sample_order(parts);
        let n = want.min(order.len());
        println!("SLICE {si} setup {setup:.3}s partitions {parts} sampled {n}");
        let mut sc = Scratch::default();
        for &v in &order[..n] {
            let t = Instant::now();
            let out = join.run_partition(v, &mut sc);
            let total = t.elapsed().as_nanos();
            let m: Vec<_> = (0..4).map(|m| join.prof_tops(v, m, &mut sc)).collect();
            println!(
                "PART b{base} s{si} v{v} total_ns {total} survivors {} checked {} | full_ns {} tops {} | adv_ns {} prefixes {} unclipped {} seeds {} steps {} | cert_ns {} tops {} | seedall_ns {}",
                out.survivors,
                out.checked,
                m[0].ns,
                m[0].tops,
                m[1].ns,
                m[1].prefixes,
                m[1].unclipped,
                m[1].seeds,
                m[1].steps,
                m[2].ns,
                m[2].tops,
                m[3].ns
            );
        }
    }
}
