
// ---- L28 box-local tests (never committed) ----
#[cfg(test)]
mod l28_local {
    use super::*;
    use crate::FieldSize;
    use crate::cubecl_backend::{CubeclContext, process_range_detailed_cubecl};

    /// Start, middle and end windows of every base 10-64 with a plan,
    /// against the CPU (distribution and near-misses).
    fn sweep(ctx: &CubeclContext, width: u128) {
        println!("L28TREE sweep on {} width {width}", ctx.device_name());
        let (mut windows, mut numbers, mut misses) = (0usize, 0u128, 0usize);
        for base in 10..=64u32 {
            let Some(p) = fd_plan(base) else { continue };
            let Ok(Some(r)) = crate::base_range::get_base_range_u128(base) else {
                continue;
            };
            let (lo, hi) = (r.range_start.max(p.reg_lo), r.range_end.min(p.reg_hi));
            if hi <= lo {
                continue;
            }
            let w = width.min(hi - lo);
            let mid = lo + (hi - lo) / 2 - w / 2;
            for (what, a) in [("start", lo), ("mid", mid), ("end", hi - w)] {
                let range = FieldSize::new(a, a + w);
                let gpu = process_range_detailed_cubecl(ctx, &range, base).expect("gpu run");
                let cpu = super::tests::cpu_detailed_parallel(&range, base);
                assert_eq!(gpu.distribution, cpu.distribution, "b{base} {what} distribution");
                assert_eq!(gpu.nice_numbers, cpu.nice_numbers, "b{base} {what} near-misses");
                windows += 1;
                numbers += w;
                misses += cpu.nice_numbers.len();
                println!(
                    "b{base} {what} [{a}, +{w}) exact, {} near-misses",
                    cpu.nice_numbers.len()
                );
            }
        }
        println!("L28 sweep: {windows} windows, {numbers} numbers, {misses} near-misses, all exact");
    }

    fn width(default: u128) -> u128 {
        std::env::var("L28_WIDTH").ok().and_then(|s| s.parse().ok()).unwrap_or(default)
    }

    #[test]
    #[ignore = "box-local"]
    fn l28_wgpu_fd_sweep() {
        let ctx = CubeclContext::new_default().expect("CubeCL init");
        sweep(&ctx, width(100_000));
    }

    #[test]
    #[cfg(feature = "cubecl-cuda")]
    #[ignore = "box-local"]
    fn l28_cuda_fd_sweep() {
        let ctx = CubeclContext::new_cuda(0).expect("CubeCL CUDA init");
        sweep(&ctx, width(10_000_000));
    }

    /// One FD launch at L28_BASE (default 40), for shader dumps.
    #[test]
    #[ignore = "box-local"]
    fn l28_dump() {
        let base: u32 = std::env::var("L28_BASE").ok().and_then(|s| s.parse().ok()).unwrap_or(40);
        let ctx = if std::env::var("L28_CUDA").is_ok() {
            CubeclContext::new_cuda(0).expect("CubeCL CUDA init")
        } else {
            CubeclContext::new_default().expect("CubeCL init")
        };
        let s = crate::base_range::get_base_range_u128(base).unwrap().unwrap().range_start;
        let range = FieldSize::new(s, s + 10_000);
        let gpu = process_range_detailed_cubecl(&ctx, &range, base).expect("gpu run");
        let cpu = super::tests::cpu_detailed_parallel(&range, base);
        assert_eq!(gpu.distribution, cpu.distribution);
        println!("L28TREE dump b{base} on {}", ctx.device_name());
    }
}
