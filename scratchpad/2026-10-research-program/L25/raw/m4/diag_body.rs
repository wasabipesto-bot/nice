
    /// L25 M4 confirmation (ad hoc, never for upstream): every window that
    /// `cubecl_join_matches_the_cpu_reference` checks (the b10 band, then
    /// `WINDOWS`), the device against the CPU reference exactly as
    /// `check_window` compares them, but totalled per window instead of
    /// stopping at the first difference.
    #[test]
    #[ignore = "requires a wgpu device"]
    fn zz_l25_windows_each() {
        const TREE: &str = "L25TREE-@@TREE@@";
        let (client, name) = client();
        println!("{TREE} device {name}");
        let mut all = vec![(10u32, 47u128, 100u128, 2u32, 1u32, 0u32)];
        all.extend_from_slice(WINDOWS);
        let mut bad = 0usize;
        for (b, s, e, t, k, p) in all {
            let t0 = std::time::Instant::now();
            let jp = JoinParams { t, k, p };
            let fs = FieldSetup::new(b, s, e, jp).expect("field setup");
            let live = live_partitions(&fs);
            let step = live.len().div_ceil(96).max(1);
            let parts: Vec<u32> = live.into_iter().step_by(step).collect();
            let plan = test_plan(&fs, limits_of(&client), 4);
            let mut dev = JoinDevice::new(&client, &fs, &plan).expect("device");
            let (mut gs, mut cs, mut gp, mut cp) = (0u64, 0u64, 0usize, 0usize);
            let (mut missing, mut extra, mut batches, mut bad_batches) = (0usize, 0usize, 0usize, 0usize);
            let mut first_bad: Option<String> = None;
            let mut cpu_hits = Vec::new();
            let mut err: Option<String> = None;
            for batch in parts.chunks(dev.max_slots) {
                batches += 1;
                let vs: Vec<u128> = batch.iter().map(|&v| u128::from(v)).collect();
                let mut cpu = Vec::new();
                let st = join_range(&fs.base, s, e, jp, Some(&vs), Some(&mut cpu));
                cpu.retain(|&n| mid_mirror(&fs, n));
                cpu.sort_unstable();
                cpu_hits.extend(st.hits);
                let rec = match dev.launch_batch(batch, false) {
                    Ok(r) => r,
                    Err(x) => {
                        err = Some(format!("launch {batch:?}: {x:#}"));
                        break;
                    }
                };
                let survivors = match dev.read_counts(&rec) {
                    Ok((sv, _)) => sv,
                    Err(x) => {
                        err = Some(format!("read_counts {batch:?}: {x:#}"));
                        break;
                    }
                };
                let got = match dev.read_checked(&rec) {
                    Ok(g) => g,
                    Err(x) => {
                        err = Some(format!("read_checked {batch:?}: {x:#}"));
                        break;
                    }
                };
                gs += u64::from(survivors);
                cs += st.survivors;
                gp += got.len();
                cp += cpu.len();
                let gset: std::collections::BTreeSet<u128> = got.iter().copied().collect();
                let cset: std::collections::BTreeSet<u128> = cpu.iter().copied().collect();
                let mi = cset.difference(&gset).count();
                let ex = gset.difference(&cset).count();
                missing += mi;
                extra += ex;
                if u64::from(survivors) != st.survivors || got != cpu {
                    bad_batches += 1;
                    if first_bad.is_none() {
                        first_bad = Some(format!(
                            "partitions {batch:?}: join survivors gpu {survivors} cpu {}, \
                             prefilter survivors gpu {} cpu {} (missing {mi}, extra {ex})",
                            st.survivors,
                            got.len(),
                            cpu.len()
                        ));
                    }
                }
            }
            cpu_hits.sort_unstable();
            let hits = dev.read_hits().unwrap_or_default();
            let ok = err.is_none()
                && gs == cs
                && gp == cp
                && missing == 0
                && extra == 0
                && hits == cpu_hits;
            if !ok {
                bad += 1;
            }
            println!(
                "L25DIAG {TREE} b{b} [{s}, {e}) ({t},{k},{p}) partitions {} in {batches} batches, \
                 {bad_batches} differing; join survivors gpu {gs} cpu {cs}; prefilter survivors \
                 gpu {gp} cpu {cp} (missing {missing}, extra {extra}); hits gpu {} cpu {}; \
                 err {err:?}; {:.2}s -> {}",
                parts.len(),
                hits.len(),
                cpu_hits.len(),
                t0.elapsed().as_secs_f64(),
                if ok { "AGREES" } else { "DIFFERS" }
            );
            if let Some(f) = first_bad {
                println!("L25DIAG {TREE}   first differing batch: {f}");
            }
        }
        println!("L25DIAG {TREE} windows differing: {bad}");
    }
}
