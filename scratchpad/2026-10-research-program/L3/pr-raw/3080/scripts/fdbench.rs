//! Time `process_range_detailed_cubecl` (the client's detailed GPU path) on a
//! fixed window through CubeCL's CUDA runtime. Dropped into common/examples/
//! of each tree on the box, untracked; same source for every tree.
//!
//! usage: fdbench <base> <count> <reps> [offset from range start]
use nice_common::FieldSize;
use nice_common::cubecl_backend::{CubeclContext, process_range_detailed_cubecl};
use std::time::Instant;

fn main() {
    let a: Vec<String> = std::env::args().collect();
    let base: u32 = a[1].parse().unwrap();
    let count: u128 = a[2].parse::<f64>().unwrap() as u128;
    let reps: usize = a[3].parse().unwrap();
    let offset: u128 = a.get(4).map_or(0, |x| x.parse::<f64>().unwrap() as u128);
    let ctx = CubeclContext::new_cuda(0).expect("CubeCL CUDA init");
    let rs = nice_common::base_range::get_base_range_u128(base)
        .unwrap()
        .unwrap()
        .start();
    let range = FieldSize::new(rs + offset, rs + offset + count);
    // JIT warm-up on a small window of the same base.
    process_range_detailed_cubecl(&ctx, &FieldSize::new(rs, rs + 1_000_000), base).unwrap();
    for r in 0..reps {
        let t = Instant::now();
        let res = process_range_detailed_cubecl(&ctx, &range, base).unwrap();
        let secs = t.elapsed().as_secs_f64();
        // FNV-1a over the distribution and near-miss list, to compare trees.
        let mut h: u64 = 0xcbf2_9ce4_8422_2325;
        let mut eat = |bytes: &[u8]| {
            for &b in bytes {
                h = (h ^ u64::from(b)).wrapping_mul(0x0100_0000_01b3);
            }
        };
        for d in &res.distribution {
            eat(&d.num_uniques.to_le_bytes());
            eat(&d.count.to_le_bytes());
        }
        for n in &res.nice_numbers {
            eat(&n.number.to_le_bytes());
            eat(&n.num_uniques.to_le_bytes());
        }
        println!(
            "FDBENCH b{base} start {} count {count} rep {r} secs {secs:.4} rate {:.4e} misses {} fp {h:016x}",
            range.start(),
            count as f64 / secs,
            res.nice_numbers.len()
        );
    }
}
