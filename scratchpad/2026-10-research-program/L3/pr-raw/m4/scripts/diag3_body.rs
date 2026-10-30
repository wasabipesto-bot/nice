
    /// Diagnostic for the M4 Metal run (not part of the PR): which single n
    /// the FD kernel gets wrong, one launch per n, run length 1.
    #[test]
    #[ignore = "diagnostic"]
    fn zz_metal_wrong_n() {
        let ctx = CubeclContext::new_default().expect("CubeCL init");
        for (base, count) in [(23u32, 3000u128), (50, 400)] {
            let r = crate::base_range::get_base_range_u128(base).unwrap().unwrap();
            let mut wrong = 0;
            for n in r.range_start..r.range_start + count {
                let one = FieldSize::new(n, n + 1);
                let c = uniq_of(&process_range_detailed(&one, base));
                let g = uniq_of(&run(&ctx, &one, base, DetailedKernel::FiniteDifference { run_len: 1, batch: CUBECL_BATCH_SIZE }));
                if c != g {
                    wrong += 1;
                    println!("WRONG b{base} n={n} cpu={c:?} fd={g:?}");
                }
            }
            println!("WRONGSUM b{base}: {wrong} of {count} from {}", r.range_start);
        }
    }
