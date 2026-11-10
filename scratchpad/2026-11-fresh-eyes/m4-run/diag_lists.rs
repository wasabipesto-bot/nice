    /// Diagnostic, local only: the list the device hands to the full check
    /// against the CPU reference's prefilter survivors, for partitions of one
    /// slice of a production field. `missing` are candidates never checked.
    #[test]
    #[ignore = "diagnostic: NICE_DIAG_FIELD=base:start:size NICE_DIAG_PARTS=from:count:step NICE_DIAG_SLICE=i"]
    fn zz_m4_lists() {
        let spec = std::env::var("NICE_DIAG_FIELD").expect("NICE_DIAG_FIELD");
        let f: Vec<&str> = spec.split(':').collect();
        let base: u32 = f[0].parse().unwrap();
        let start: u128 = f[1].parse().unwrap();
        let size: u128 = f[2].parse().unwrap();
        let pspec = std::env::var("NICE_DIAG_PARTS").unwrap_or_else(|_| "0:4:1".into());
        let p: Vec<u32> = pspec.split(':').map(|x| x.parse().unwrap()).collect();
        let si: usize = std::env::var("NICE_DIAG_SLICE").map_or(0, |x| x.parse().unwrap());
        let slots: usize = std::env::var("NICE_DIAG_SLOTS").map_or(4, |x| x.parse().unwrap());
        let (client, name) = client();
        let range = FieldSize::new(start, start + size);
        let field =
            crate::join_plan::plan_join(base, &range, limits_of(&client)).expect("a join field");
        let jp = field.fs.jp;
        let sl = &field.slices[si];
        let (s, e) = (sl.start(), sl.end());
        let fs = FieldSetup::new(base, s, e, jp).expect("field setup");
        let total = u32::try_from(fs.nparts).unwrap();
        let parts: Vec<u32> = (0..p[1]).map(|i| p[0] + i * p[2]).filter(|&v| v < total).collect();
        let plan = test_plan(&fs, limits_of(&client), slots);
        let mut dev = JoinDevice::new(&client, &fs, &plan).expect("device");
        println!(
            "DIAGL tree=DIAGTREE device={name} b{base} slice {si} of {} [{s}, {e}) {jp:?} parts={parts:?} max_slots={}",
            field.slices.len(),
            dev.max_slots
        );
        let (mut tm, mut te, mut tc, mut tg) = (0u64, 0u64, 0u64, 0u64);
        for batch in parts.chunks(dev.max_slots) {
            let vs: Vec<u128> = batch.iter().map(|&v| u128::from(v)).collect();
            let mut cpu = Vec::new();
            let t0 = Instant::now();
            let st = join_range(&fs.base, s, e, jp, Some(&vs), Some(&mut cpu));
            cpu.retain(|&n| mid_mirror(&fs, n));
            cpu.sort_unstable();
            let cpu_secs = t0.elapsed().as_secs_f64();
            let rec = dev.launch_batch(batch, false).expect("launch");
            let (survivors, _) = dev.read_counts(&rec).expect("counts");
            let got = dev.read_checked(&rec).expect("prefilter survivors");
            let (mut i, mut j, mut missing, mut extra) = (0usize, 0usize, 0u64, 0u64);
            let mut first_missing = Vec::new();
            while i < cpu.len() || j < got.len() {
                if j == got.len() || (i < cpu.len() && cpu[i] < got[j]) {
                    missing += 1;
                    if first_missing.len() < 3 {
                        first_missing.push(cpu[i]);
                    }
                    i += 1;
                } else if i == cpu.len() || got[j] < cpu[i] {
                    extra += 1;
                    j += 1;
                } else {
                    i += 1;
                    j += 1;
                }
            }
            println!(
                "DIAGL batch {batch:?}: cpu join survivors={} gpu counted={survivors} | cpu prefilter survivors={} gpu listed={} missing={missing} extra={extra} first_missing={first_missing:?} cpu_secs={cpu_secs:.1}",
                st.survivors,
                cpu.len(),
                got.len()
            );
            tm += missing;
            te += extra;
            tc += cpu.len() as u64;
            tg += got.len() as u64;
        }
        #[allow(clippy::cast_precision_loss)]
        let rel = tm as f64 / tc.max(1) as f64;
        println!("DIAGL total: cpu prefilter survivors={tc} gpu listed={tg} missing={tm} extra={te} missing/cpu={rel:.3e}");
    }

