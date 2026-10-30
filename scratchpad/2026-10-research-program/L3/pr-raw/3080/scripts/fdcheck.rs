//! Fingerprint `process_range_detailed_cubecl` (CUDA runtime) on three windows
//! of every base 10-64 with a range: the start, the middle and the end, up to
//! 1e8 numbers each. Same source in every tree; compare the printed lines.
use nice_common::FieldSize;
use nice_common::cubecl_backend::{CubeclContext, process_range_detailed_cubecl};

fn main() {
    let ctx = CubeclContext::new_cuda(0).expect("CubeCL CUDA init");
    for base in 10..=64u32 {
        let Ok(Some(r)) = nice_common::base_range::get_base_range_u128(base) else {
            continue;
        };
        let count = r.size().min(100_000_000);
        for (name, off) in [("start", 0), ("middle", (r.size() - count) / 2), ("end", r.size() - count)] {
            let range = FieldSize::new(r.start() + off, r.start() + off + count);
            let res = process_range_detailed_cubecl(&ctx, &range, base).unwrap();
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
            let total: u128 = res.distribution.iter().map(|d| d.count).sum();
            assert_eq!(total, count);
            println!(
                "FDCHECK b{base} {name} [{}, {}) misses {} fp {h:016x}",
                range.start(),
                range.end(),
                res.nice_numbers.len()
            );
        }
    }
}
