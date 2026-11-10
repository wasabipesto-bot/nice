    /// Diagnostic, local only: the GPU join against the CPU join on
    /// partitions of a production field, in total and per partition.
    #[test]
    #[ignore = "diagnostic: NICE_DIAG_FIELD=base:start:size NICE_DIAG_PARTS=from:count:step"]
    fn zz_m4_deficit() {
        let spec = std::env::var("NICE_DIAG_FIELD").expect("NICE_DIAG_FIELD");
        let f: Vec<&str> = spec.split(':').collect();
        let base: u32 = f[0].parse().unwrap();
        let start: u128 = f[1].parse().unwrap();
        let size: u128 = f[2].parse().unwrap();
        let pspec = std::env::var("NICE_DIAG_PARTS").unwrap_or_else(|_| "0:32:1".into());
        let p: Vec<u32> = pspec.split(':').map(|x| x.parse().unwrap()).collect();
        let single = std::env::var("NICE_DIAG_SINGLE").is_ok();
        let reps: u32 = std::env::var("NICE_DIAG_REPS").map_or(1, |x| x.parse().unwrap());
        let (client, name) = client();
        let range = FieldSize::new(start, start + size);
        let field =
            crate::join_plan::plan_join(base, &range, limits_of(&client)).expect("a join field");
        let total = u32::try_from(field.fs.nparts).unwrap();
        let parts: Vec<u32> = (0..p[1]).map(|i| p[0] + i * p[2]).filter(|&v| v < total).collect();
        println!(
            "DIAG tree=DIAGTREE device={name} b{base} [{start}, +{size}) {:?} slices={} nparts={total} parts={}+{}x{}",
            field.fs.jp,
            field.slices.len(),
            p[0],
            parts.len(),
            p[2]
        );
        let cpus: Vec<crate::cpu_join::CpuJoin> = field
            .slices
            .iter()
            .map(|sl| crate::cpu_join::CpuJoin::new(base, sl, field.fs.jp).expect("cpu setup"))
            .collect();
        let per = parts.len().div_ceil(8).max(1);
        let mut want: Vec<(u64, u64, u64)> = vec![(0, 0, 0); parts.len()];
        let t0 = Instant::now();
        std::thread::scope(|s| {
            for (cp, cw) in parts.chunks(per).zip(want.chunks_mut(per)) {
                let cpus = &cpus;
                s.spawn(move || {
                    let mut sc = crate::cpu_join::Scratch::default();
                    for (v, w) in cp.iter().zip(cw.iter_mut()) {
                        for cpu in cpus {
                            let r = cpu.run_partition(*v, &mut sc);
                            w.0 += r.survivors;
                            w.1 += r.checked;
                            w.2 += r.hits.len() as u64;
                        }
                    }
                });
            }
        });
        let cs: u64 = want.iter().map(|w| w.0).sum();
        let cc: u64 = want.iter().map(|w| w.1).sum();
        let ch: u64 = want.iter().map(|w| w.2).sum();
        println!("DIAG cpu survivors={cs} checked={cc} hits={ch} secs={:.1}", t0.elapsed().as_secs_f64());
        #[allow(clippy::cast_precision_loss)]
        let pass = cc as f64 / cs.max(1) as f64;
        for rep in 0..reps {
            let t1 = Instant::now();
            let (hits, st) =
                run_slices(&client, &field, field.slices.len(), &parts, &JoinCeiling::default())
                    .expect("device run");
            #[allow(clippy::cast_precision_loss)]
            let (ds, dc) = (cs as f64 - st.survivors as f64, st.checked as f64 - cc as f64);
            let lost = ds - dc / (1.0 - pass);
            println!(
                "DIAG gpu rep={rep} survivors={} checked={} hits={} slots={} retried={} secs={:.1} | cpu-gpu survivors={ds:.0} gpu-cpu checked={dc:.0} unaccounted={lost:.0} rel={:.3e}",
                st.survivors,
                st.checked,
                hits.len(),
                st.slots,
                st.retried_partitions,
                t1.elapsed().as_secs_f64(),
                lost / cs.max(1) as f64
            );
        }
        if single {
            let mut bad = 0u32;
            for (v, w) in parts.iter().zip(want.iter()) {
                let (hits, st) =
                    run_slices(&client, &field, field.slices.len(), &[*v], &JoinCeiling::default())
                        .expect("device run");
                if st.survivors != w.0 || st.checked != w.1 {
                    bad += 1;
                    println!(
                        "DIAG part {v}: gpu survivors={} checked={} hits={} | cpu survivors={} checked={}",
                        st.survivors,
                        st.checked,
                        hits.len(),
                        w.0,
                        w.1
                    );
                }
            }
            println!("DIAG single: {bad} of {} partitions differ", parts.len());
        }
    }

