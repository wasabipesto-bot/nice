
// ---- L26 (box-local, never committed): WGSL dump driver and CUDA-runtime
// copies of the wgpu-only probe tests. Appended to cubecl_backend.rs on the box.
#[cfg(test)]
mod l26_local {
    use super::*;
    use crate::gpu_route::process_niceonly;

    const TREE: &str = "L26TREE";

    fn mirror(n: u128, base: u32, pre: &VulkanPrefilterParams) -> bool {
        let modulus = u128::from(pre.chunk_div).pow(pre.limbs);
        let m = n % modulus;
        let sq = (m * m) % modulus;
        let cu = (sq * m) % modulus;
        let mut seen = 0u128;
        let mut dup = false;
        for mut v in [sq, cu] {
            for _ in 0..pre.digits {
                let d = (v % u128::from(base)) as u32;
                v /= u128::from(base);
                let bit = 1u128 << d;
                dup |= seen & bit != 0;
                seen |= bit;
            }
        }
        !dup
    }

    fn start(b: u32) -> u128 {
        crate::base_range::get_base_range_u128(b).unwrap().unwrap().range_start
    }

    /// One production (non-probe) stride nice-only field, so CUBECL_DEBUG_LOG
    /// records the kernel's WGSL.
    #[test]
    #[ignore = "L26 dump driver"]
    fn l26_stride() {
        let b: u32 = std::env::var("L26_BASE").unwrap().parse().unwrap();
        let size = std::env::var("L26_SIZE").ok().map_or(1e7, |v| v.parse::<f64>().unwrap()) as u128;
        let ctx = CubeclContext::new_default().unwrap();
        let s = start(b);
        let r = FieldSize::new(s, s + size);
        let res = process_niceonly(&ctx, &r, b).unwrap();
        println!(
            "{TREE} stride b{b} [{s}, +{size}) limbs {:?} prefilter {:?}: {} nice",
            crate::gpu_config::n_limbs(b),
            vulkan_prefilter_params(b),
            res.nice_numbers.len()
        );
    }

    /// `cubecl_prefilter_survivors_match_the_host_mirror` on the CUDA runtime.
    #[test]
    #[cfg(feature = "cubecl-cuda")]
    #[ignore = "L26 CUDA probe"]
    fn l26_cuda_prefilter_probe() {
        use crate::gpu_niceonly::MAX_LANES_PER_RANGE;
        println!("{TREE}");
        let ctx = CubeclContext::new_cuda(0).expect("CubeCL CUDA init");
        let CubeclContext::Cuda { client, .. } = &ctx else {
            unreachable!("new_cuda returns the CUDA variant");
        };
        for base in [30u32, 34, 40] {
            let pre = vulkan_prefilter_params(base).expect("base has a prefilter");
            let table = StrideTable::new(base, GPU_LSD_K);
            let start = start(base);
            let len: u32 = 5_000_000;
            let mut per_width = Vec::new();
            for shift in 0..=MAX_LANES_PER_RANGE.ilog2() {
                let mut run =
                    CubeclNiceonlyRun::new(client, base, start, false).expect("probe run");
                assert!(run.plan.prefilter.is_some());
                run.probe = true;
                run.lane_shift_override = Some(shift);
                run.launch(0, &[0], &[len], &[0]).expect("dispatch");
                per_width.push(
                    run.finish()
                        .expect("results")
                        .iter()
                        .map(|n| n.number)
                        .collect::<Vec<u128>>(),
                );
            }
            let end = start + u128::from(len);
            let (mut n, mut idx) = table.first_valid_at_or_after(start);
            let mut want = Vec::new();
            let mut candidates = 0u32;
            while n < end {
                candidates += 1;
                if mirror(n, base, &pre) {
                    want.push(n);
                }
                n += u128::from(table.gap_table[idx]);
                idx = (idx + 1) % table.gap_table.len();
            }
            for (shift, got) in per_width.iter().enumerate() {
                assert_eq!(got, &want, "base {base}: {} lanes disagree with the CPU mirror", 1 << shift);
            }
            assert!(!want.is_empty() && want.len() < candidates as usize);
            println!(
                "base {base}: limbs {:?}, {} of {candidates} candidates survive, CUDA agrees at {} lane widths",
                crate::gpu_config::n_limbs(base),
                want.len(),
                per_width.len()
            );
        }
    }

    /// `cubecl_cross_filter_survivors_match_the_host_mirror` on the CUDA runtime.
    #[test]
    #[cfg(feature = "cubecl-cuda")]
    #[ignore = "L26 CUDA probe"]
    fn l26_cuda_cross_filter() {
        println!("{TREE}");
        let ctx = CubeclContext::new_cuda(0).expect("CubeCL CUDA init");
        let CubeclContext::Cuda { client, .. } = &ctx else {
            unreachable!("new_cuda returns the CUDA variant");
        };
        for (base, mask) in [
            (40u32, (1u64 << 5) | (1u64 << 39)),
            (50, (1u64 << 3) | (1u64 << 45)),
        ] {
            let pre = vulkan_prefilter_params(base);
            let table = StrideTable::new(base, GPU_LSD_K);
            let start = start(base);
            let len: u32 = 400_000;
            let end = start + u128::from(len);
            let (mut n, mut idx) = table.first_valid_at_or_after(start);
            let mut want = Vec::new();
            let mut cross_rejected = 0u32;
            while n < end {
                if table.low_digit_masks[idx] & mask != 0 {
                    cross_rejected += 1;
                } else if pre.is_none_or(|p| mirror(n, base, &p)) {
                    want.push(n);
                }
                n += u128::from(table.gap_table[idx]);
                idx = (idx + 1) % table.gap_table.len();
            }
            assert!(cross_rejected > 1000);
            let plane_sync = client
                .properties()
                .features
                .plane
                .contains(cubecl::ir::features::Plane::Sync);
            let variants: &[(bool, bool)] = if plane_sync {
                &[(true, false), (true, true), (false, false)]
            } else {
                &[(true, false), (false, false)]
            };
            for &(forced_compact, forced_plane) in variants {
                let mut run =
                    CubeclNiceonlyRun::new(client, base, start, false).expect("probe run");
                run.probe = true;
                run.compact_override = Some(forced_compact);
                run.plane_override = Some(forced_plane);
                run.launch(0, &[0], &[len], &[mask]).expect("dispatch");
                let mut got: Vec<u128> = run
                    .finish()
                    .expect("results")
                    .iter()
                    .map(|n| n.number)
                    .collect();
                got.sort_unstable();
                assert_eq!(got, want, "base {base} compact={forced_compact} plane={forced_plane}");
                println!(
                    "base {base} compact={forced_compact} plane={forced_plane}: {} survivors agree (CUDA)",
                    want.len()
                );
            }
        }
    }

    /// Prefilter survivors against the mirror over windows at the start,
    /// middle and end of every base with a prefilter, on whatever client.
    fn sweep<R: cubecl::prelude::Runtime>(client: &cubecl::prelude::ComputeClient<R>, label: &str) {
        println!("{TREE} {label}");
        let len: u32 = 1_000_000;
        let mut total = (0usize, 0usize);
        for base in 10u32..=40 {
            let Some(pre) = vulkan_prefilter_params(base) else { continue };
            let r = crate::base_range::get_base_range_u128(base).unwrap().unwrap();
            let mid = r.range_start + (r.range_end - r.range_start) / 2;
            for (tag, s) in [("start", r.range_start), ("mid", mid), ("end", r.range_end - u128::from(len))] {
                let table = StrideTable::new(base, GPU_LSD_K);
                let mut run = match CubeclNiceonlyRun::new(client, base, s, false) {
                    Ok(run) => run,
                    Err(e) => {
                        println!("{label} base {base}: skipped ({e})");
                        break;
                    }
                };
                assert!(run.plan.prefilter.is_some());
                run.probe = true;
                run.launch(0, &[0], &[len], &[0]).expect("dispatch");
                let mut got: Vec<u128> = run.finish().expect("results").iter().map(|n| n.number).collect();
                got.sort_unstable();
                let end = s + u128::from(len);
                let (mut n, mut idx) = table.first_valid_at_or_after(s);
                let mut want = Vec::new();
                let mut cands = 0usize;
                while n < end {
                    cands += 1;
                    if mirror(n, base, &pre) {
                        want.push(n);
                    }
                    n += u128::from(table.gap_table[idx]);
                    idx = (idx + 1) % table.gap_table.len();
                }
                assert_eq!(got, want, "{label} base {base} {tag} [{s}, +{len})");
                assert!(!want.is_empty() && want.len() < cands);
                total.0 += want.len();
                total.1 += cands;
                println!(
                    "{label} base {base} limbs {:?} K {} {tag} [{s}, +{len}): {} of {cands} survive, device agrees",
                    crate::gpu_config::n_limbs(base),
                    pre.chunk_div,
                    want.len()
                );
            }
        }
        println!("{label} total: {} of {} candidates survive, all windows agree", total.0, total.1);
    }

    #[test]
    #[ignore = "L26 sweep"]
    fn l26_wgpu_prefilter_sweep() {
        let ctx = CubeclContext::new_default().expect("CubeCL init");
        println!("device: {}", ctx.device_name());
        #[allow(irrefutable_let_patterns)]
        let CubeclContext::Wgpu { client, .. } = &ctx else { unreachable!() };
        sweep(client, "wgpu");
    }

    #[test]
    #[cfg(feature = "cubecl-cuda")]
    #[ignore = "L26 sweep"]
    fn l26_cuda_prefilter_sweep() {
        let ctx = CubeclContext::new_cuda(0).expect("CubeCL CUDA init");
        println!("device: {}", ctx.device_name());
        let CubeclContext::Cuda { client, .. } = &ctx else { unreachable!() };
        sweep(client, "cuda");
    }
}
