    // ---------------------------------------------------------------------
    // REPRO (test-only, not for a PR): main's top_slot on partly filled
    // planes and planes without lane 0, counted.
    // ---------------------------------------------------------------------

    fn repro_window(fs: &FieldSetup, off: usize, len: usize) -> FieldSetup {
        let (b, m1) = (u128::from(fs.b), u128::from(fs.m1));
        let pdiv = fs.nparts % m1;
        let group = |p0: u128| {
            let key = if fs.key_level { p0 % b } else { 0 };
            key * m1 + (p0 % m1) * pdiv % m1
        };
        let mut order: Vec<usize> = (0..fs.tlay.len()).collect();
        order.sort_by_key(|&i| group(fs.tlay[i].0));
        let off = off.min(order.len().saturating_sub(len));
        let mut keep = order[off..(off + len).min(order.len())].to_vec();
        keep.sort_unstable();
        with_tops(fs, keep.into_iter().map(|i| fs.tlay[i]).collect())
    }

    impl<R: Runtime> JoinDevice<R> {
        /// `run_tops` without its assertions: (tops counted, the counted
        /// records' entries per slot sorted, records left at the sentinel).
        fn repro_tops(&self, vs: &[u32], fd: bool) -> (u64, Vec<Vec<[u32; 9]>>, usize) {
            let c = &self.client;
            let nslots = vs.len();
            let nb = self.nb as usize;
            let rec_len = TOP_REC_WORDS as usize * self.max_slots * self.ntlay as usize;
            unsafe {
                fill_sentinel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static(CHECK_CUBES, 1, 1),
                    CubeDim::new_1d(JOIN_WG),
                    ArrayArg::from_raw_parts(self.top_rec.clone(), rec_len),
                    u32::try_from(rec_len).expect("records fit u32"),
                );
            }
            let vs_h = c.create(cubecl::bytes::Bytes::from_elems(vs.to_vec()));
            let grp_cnt = c.create(cubecl::bytes::Bytes::from_elems(vec![0u32; nslots * nb]));
            let ran = c.create(cubecl::bytes::Bytes::from_elems(vec![0u32; STAGES]));
            self.launch_top(vs, &vs_h, &grp_cnt, &ran, fd);
            let counts = self.read_u32(&grp_cnt).expect("group counts");
            assert_eq!(self.read_u32(&ran).expect("ran")[0], self.top_expect(vs, fd));
            let rec = self.read_u32(&self.top_rec).unwrap();
            let goff = self.read_u32(&self.goff).unwrap();
            let ntl = self.ntlay as usize;
            let mut unwritten = 0;
            let mut total = 0u64;
            let entries = (0..nslots)
                .map(|s| {
                    let mut ents: Vec<[u32; 9]> = Vec::new();
                    for (grp, w) in goff.windows(2).enumerate() {
                        let n = (counts[s * nb + grp] as usize).min((w[1] - w[0]) as usize);
                        total += u64::from(counts[s * nb + grp]);
                        for i in 0..n {
                            let at = s * ntl + w[0] as usize + i;
                            let rw = &rec[TOP_REC_WORDS as usize * at..][..8];
                            if rw[7] > 1 {
                                unwritten += 1;
                                continue;
                            }
                            let gw = u32::try_from(grp).unwrap();
                            ents.push([gw, rw[0], rw[1], rw[2], rw[3], rw[4], rw[5], rw[6], rw[7]]);
                        }
                    }
                    ents.sort_unstable();
                    ents
                })
                .collect();
            (total, entries, unwritten)
        }
    }

    /// Counts per (field, cube size, form, bits): tops `top_kernel` keeps,
    /// tops the FD kernel counted, of its entries how many are top_kernel's
    /// (multiset), lost = top_kernel's not found, records unwritten.
    fn repro_top_partial_planes<R: Runtime>(client: &ComputeClient<R>, name: &str, forms: &[bool], bits_list: &[u32], wgs: &[u32]) {
        let lim = device_limits(client, name);
        let cpp = ["cuda", "hip"].iter().any(|r| R::name(client).contains(r));
        let mut fields: Vec<(String, FieldSetup, JoinPlan)> = Vec::new();
        for &(b, s, e, t, k, p) in WINDOWS {
            let jp = JoinParams { t, k, p };
            let fs = FieldSetup::new(b, s, e, jp).expect("field setup");
            let plan = test_plan(&fs, limits_of(client), 4);
            fields.push((format!("b{b} [{s}, {e}) ({t},{k},{p})"), fs, plan));
        }
        for &(b, start, size) in PLAN_FIELDS {
            let range = FieldSize::new(start, start + size);
            let field = crate::join_plan::plan_join(b, &range, lim).expect("a join field");
            fields.push((format!("b{b} {size:e}, first slice"), field.fs, field.plan));
        }
        let mut bad_runs = 0usize;
        let mut runs = 0usize;
        let mut tot_lost = 0u64;
        for (label, fs, plan) in fields {
            if !top_fd_fits(&fs) {
                continue;
            }
            for &wg in wgs {
                let one_cube = cpp && !wg.is_multiple_of(32);
                let subs: Vec<(String, FieldSetup)> = if one_cube {
                    let mid = fs.tlay.len() / 2;
                    let w = wg as usize;
                    vec![
                        (format!("{label}, prefixes 0..{w}"), repro_window(&fs, 0, w)),
                        (format!("{label}, {} from {mid}", w - 3), repro_window(&fs, mid, w - 3)),
                    ]
                } else {
                    vec![(label.clone(), fs.clone())]
                };
                for (what, sub) in subs {
                    let layer = sorted_layer(&sub).expect("sorted layer");
                    let mut dev = JoinDevice::new(client, &sub, layer, &plan).expect("device");
                    let n = u32::try_from(sub.nparts).expect("b^p < 2^32");
                    let ms = dev.max_slots;
                    let mut batches: Vec<Vec<u32>> = vec![(0..n.min(u32::try_from(ms).unwrap())).collect()];
                    let live = live_partitions(&sub);
                    let step = live.len().div_ceil(96).max(1);
                    batches.push(live.into_iter().step_by(step).take(ms).collect());
                    for (bi, vs) in batches.iter().enumerate() {
                        let (wt, we, _) = dev.repro_tops(vs, false);
                        dev.top_wg = wg;
                        dev.top_fd_min = 0;
                        for &ballot in forms {
                            dev.ballot = ballot;
                            for &bits in bits_list {
                                TOP_TEST_BITS.with(|c| c.set(bits));
                                let (gt, ge, unw) = dev.repro_tops(vs, true);
                                TOP_TEST_BITS.with(|c| c.set(0));
                                let (mut found, mut lost) = (0u64, 0u64);
                                for (w, g) in we.iter().zip(&ge) {
                                    let mut gm: std::collections::HashMap<[u32; 9], i64> = std::collections::HashMap::new();
                                    for e in g {
                                        *gm.entry(*e).or_default() += 1;
                                    }
                                    for e in w {
                                        match gm.get_mut(e) {
                                            Some(c) if *c > 0 => {
                                                *c -= 1;
                                                found += 1;
                                            }
                                            _ => lost += 1,
                                        }
                                    }
                                }
                                let bad = lost > 0 || gt != wt || unw > 0;
                                runs += 1;
                                if bad {
                                    bad_runs += 1;
                                    tot_lost += lost;
                                }
                                println!(
                                    "REPRO {name}: {what} batch {bi} ({} slots, {} prefixes): cubes of {wg}, ballot {ballot}, bits {bits}: kept {wt}, counted {gt}, found {found}, lost {lost}, unwritten {unw}{}",
                                    vs.len(),
                                    dev.ntlay,
                                    if bad { "  <-- WRONG" } else { "" }
                                );
                            }
                        }
                        dev.top_wg = JOIN_WG;
                        dev.top_fd_min = TOP_FD_MIN_UNITS;
                    }
                }
            }
        }
        println!("REPRO {name}: {bad_runs} of {runs} runs wrong, {tot_lost} tops lost in all");
        assert_eq!(bad_runs, 0, "{name}: runs that lost or miscounted tops");
    }

    fn repro_env_forms(default: &[bool]) -> Vec<bool> {
        match std::env::var("REPRO_FORMS").as_deref() {
            Ok("b") => vec![true],
            Ok("s") => vec![false],
            Ok("bs") => vec![true, false],
            _ => default.to_vec(),
        }
    }
    fn repro_env_bits() -> Vec<u32> {
        match std::env::var("REPRO_LANE0").as_deref() {
            Ok("1") => vec![0, TOP_LANE0_OUT],
            Ok("only") => vec![TOP_LANE0_OUT],
            _ => vec![0],
        }
    }
    fn repro_env_wgs() -> Vec<u32> {
        std::env::var("REPRO_WGS").map_or(vec![100, 48, JOIN_WG], |s| s.split(',').map(|x| x.parse().unwrap()).collect())
    }

    #[test]
    #[ignore = "repro"]
    fn repro_top_partial_planes_wgpu() {
        let (client, name) = client();
        let ballot = ballot_append(client.properties().hardware.plane_size_max);
        let forms = repro_env_forms(if ballot { &[true, false] } else { &[false] });
        println!("REPRO {name}: plane_size_max {} min {}", client.properties().hardware.plane_size_max, client.properties().hardware.plane_size_min);
        repro_top_partial_planes(&client, &name, &forms, &repro_env_bits(), &repro_env_wgs());
    }

    #[test]
    #[cfg(feature = "cubecl-cuda")]
    #[ignore = "repro"]
    fn repro_cuda_top_partial_warps() {
        let ctx = CubeclContext::new_cuda(0).expect("CubeCL CUDA init");
        let name = ctx.device_name();
        let CubeclContext::Cuda { client, .. } = ctx else {
            unreachable!("new_cuda is CUDA")
        };
        let forms = repro_env_forms(&[true]);
        repro_top_partial_planes(&client, &name, &forms, &repro_env_bits(), &repro_env_wgs());
    }

