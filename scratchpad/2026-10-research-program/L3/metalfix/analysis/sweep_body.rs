
    /// Diagnostic sweep for the M4 Metal run (not part of the PR): every
    /// base 10-64 with a range: 2e5 at the range start and mid-range, 1e5 at
    /// the range end and at two seeded random points, production shape, FD vs
    /// CPU; plus run length 1 (every n seeded) on the start window.
    #[test]
    #[ignore = "diagnostic"]
    fn zz_metal_sweep2() {
        let ctx = CubeclContext::new_default().expect("CubeCL init");
        let mut bad = Vec::new();
        let mut windows = 0;
        let mut numbers = 0u128;
        let mut state = 0x2545_F491_4F6C_DD1Du64;
        for base in 10..=64u32 {
            let Ok(Some(r)) = crate::base_range::get_base_range_u128(base) else { continue; };
            let (rs, re) = (r.range_start, r.range_end);
            let size = re - rs;
            let w2 = 200_000u128.min(size);
            let w1 = 100_000u128.min(size);
            let mid = rs + size / 2;
            let mut wins = vec![
                ("start", FieldSize::new(rs, rs + w2), FD_RUN_LEN),
                ("start-run1", FieldSize::new(rs, rs + w2), 1),
            ];
            if size > 4 * w2 {
                wins.push(("mid", FieldSize::new(mid, mid + w2), FD_RUN_LEN));
                wins.push(("end", FieldSize::new(re - w1, re), FD_RUN_LEN));
                for i in 0..2 {
                    state ^= state << 13; state ^= state >> 7; state ^= state << 17;
                    let off = (u128::from(state) * (size - w1)) >> 64;
                    wins.push((if i == 0 { "rand0" } else { "rand1" }, FieldSize::new(rs + off, rs + off + w1), FD_RUN_LEN));
                }
            }
            for (what, range, run_len) in wins {
                let cpu = cpu_detailed_parallel(&range, base);
                let fd = run(&ctx, &range, base, DetailedKernel::FiniteDifference { run_len, batch: CUBECL_BATCH_SIZE });
                let ok = fd.distribution == cpu.distribution && fd.nice_numbers == cpu.nice_numbers;
                windows += 1;
                numbers += range.size();
                println!("SWEEP b{base} {what} [{}, +{}) run {run_len}: fd {} ({} near-misses)",
                    range.start(), range.size(), if ok { "exact" } else { "MISMATCH" }, cpu.nice_numbers.len());
                if !ok { bad.push(format!("b{base} {what}")); }
            }
        }
        println!("SWEEP {windows} windows, {numbers} numbers; FD mismatches: {bad:?}");
        assert!(bad.is_empty());
    }
