
    /// Diagnostic sweep for the M4 Metal run (not part of the PR): every
    /// base 10-64 with a range, 1e5 at the range start and 1e5 mid-range,
    /// production shape, FD vs CPU and division vs CPU.
    #[test]
    #[ignore = "diagnostic"]
    fn zz_metal_sweep() {
        let ctx = CubeclContext::new_default().expect("CubeCL init");
        let mut bad = Vec::new();
        for base in 10..=64u32 {
            let Ok(Some(r)) = crate::base_range::get_base_range_u128(base) else { continue; };
            let w = 100_000u128;
            let mid = r.range_start + (r.range_end - r.range_start) / 2;
            let mut wins = vec![("start", FieldSize::new(r.range_start, (r.range_start + w).min(r.range_end)))];
            if r.range_end - r.range_start > 4 * w {
                wins.push(("mid", FieldSize::new(mid, mid + w)));
            }
            for (what, range) in wins {
                let cpu = cpu_detailed_parallel(&range, base);
                let fd = run(&ctx, &range, base, DetailedKernel::DEFAULT);
                let div = run(&ctx, &range, base, DetailedKernel::Division);
                let fd_ok = fd.distribution == cpu.distribution && fd.nice_numbers == cpu.nice_numbers;
                let div_ok = div.distribution == cpu.distribution && div.nice_numbers == cpu.nice_numbers;
                let moved: u128 = fd.distribution.iter().zip(&cpu.distribution)
                    .map(|(g, c)| g.count.abs_diff(c.count)).sum::<u128>() / 2;
                println!("SWEEP b{base} {what} [{}, +{}): fd {} (>= {moved} moved) division {}",
                    range.start(), range.size(),
                    if fd_ok { "exact" } else { "MISMATCH" }, if div_ok { "exact" } else { "MISMATCH" });
                if !fd_ok { bad.push(format!("b{base} {what}")); }
            }
        }
        println!("SWEEP FD mismatches: {bad:?}");
    }
