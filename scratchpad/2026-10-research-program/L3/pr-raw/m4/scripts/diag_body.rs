
    fn uniq_of(r: &FieldResults) -> Vec<(u32, u128)> {
        r.distribution.iter().filter(|d| d.count > 0).map(|d| (d.num_uniques, d.count)).collect()
    }

    /// Diagnostic for the M4 Metal run (not part of the PR): per shape,
    /// exact or not; for a mismatch, bisect prefixes for the first wrong n.
    #[test]
    #[ignore = "diagnostic"]
    fn zz_metal_diag() {
        let ctx = CubeclContext::new_default().expect("CubeCL init");
        let mut cases: Vec<(u32, FieldSize)> = Vec::new();
        for (base, w) in [(23u32, 0u128), (24, 0), (50, 200_000), (40, 200_000)] {
            let r = crate::base_range::get_base_range_u128(base).unwrap().unwrap();
            let end = if w == 0 { r.range_end } else { r.range_start + w };
            cases.push((base, FieldSize::new(r.range_start, end)));
        }
        for (base, range) in cases {
            let cpu = cpu_detailed_parallel(&range, base);
            let div = run(&ctx, &range, base, DetailedKernel::Division);
            println!(
                "b{base} [{}, {}) size {}: division kernel distribution {} near-misses {}",
                range.start(), range.end(), range.size(),
                if div.distribution == cpu.distribution { "exact" } else { "MISMATCH" },
                if div.nice_numbers == cpu.nice_numbers { "exact" } else { "MISMATCH" },
            );
            for (run_len, batch) in SHAPES {
                let k = DetailedKernel::FiniteDifference { run_len, batch };
                let gpu = run(&ctx, &range, base, k);
                let ok = gpu.distribution == cpu.distribution && gpu.nice_numbers == cpu.nice_numbers;
                let wrong: u128 = gpu.distribution.iter().zip(&cpu.distribution)
                    .map(|(g, c)| g.count.abs_diff(c.count)).sum::<u128>() / 2;
                println!("b{base} FD run {run_len} batch {batch}: {} (at least {wrong} numbers moved bins)",
                    if ok { "exact" } else { "MISMATCH" });
                if ok { continue; }
                let same = |a: u128, b: u128| {
                    let r = FieldSize::new(a, b);
                    let c = process_range_detailed(&r, base);
                    let g = run(&ctx, &r, base, k);
                    g.distribution == c.distribution && g.nice_numbers == c.nice_numbers
                };
                let (mut lo, mut hi) = (range.start(), range.end());
                while hi - lo > 1 {
                    let mid = lo + (hi - lo) / 2;
                    if same(range.start(), mid) { lo = mid; } else { hi = mid; }
                }
                let n = hi - 1;
                let one = FieldSize::new(n, n + 1);
                let c1 = process_range_detailed(&one, base);
                let g1 = run(&ctx, &one, base, DetailedKernel::FiniteDifference { run_len: 1, batch });
                let d1 = run(&ctx, &one, base, DetailedKernel::Division);
                println!(
                    "  first wrong n = {n} (offset {} from start, position {} in its run): cpu {:?} fd-alone {:?} division-alone {:?}",
                    n - range.start(), (n - range.start()) % u128::from(run_len),
                    uniq_of(&c1), uniq_of(&g1), uniq_of(&d1)
                );
            }
        }
    }
