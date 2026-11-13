#!/usr/bin/env python3
"""Test-only patch of bc9d87c7's cubecl_join.rs: launch_check takes the cube's unit count, and two ignored tests
(wgpu, CUDA) run the unchanged check kernel on cubes of 100 and 48 units (a partly filled last plane) over a synthetic
list of each distinct shape of the b10 band and the production fields, in count mode, and report the entries never
checked (their output words stay zero) and the work counter. The kernel and the host are unchanged.
make_repro.py IN OUT"""
import sys
s = open(sys.argv[1]).read()
def rep(a, b):
    global s
    assert s.count(a) == 1, a
    s = s.replace(a, b)
rep("""    fn launch_check(
        &self,
        cubes: u32,
        list: &Handle,""", """    fn launch_check(
        &self,
        cubes: u32,
        wg: u32,
        list: &Handle,""")
rep("""                CubeCount::Static(cubes, 1, 1),
                CubeDim::new_1d(JOIN_WG),
                ArrayArg::from_raw_parts(list.clone(), list_words),""", """                CubeCount::Static(cubes, 1, 1),
                CubeDim::new_1d(wg),
                ArrayArg::from_raw_parts(list.clone(), list_words),""")
rep("""        self.launch_check(
            CHECK_CUBES,
            &self.list,""", """        self.launch_check(
            CHECK_CUBES,
            JOIN_WG,
            &self.list,""")
rep("""        dev.launch_check(
            cubes,
            list,""", """        dev.launch_check(
            cubes,
            JOIN_WG,
            list,""")
rep("""    #[test]
    #[ignore = "requires a wgpu device"]
    fn cubecl_check_counts_match_the_cpu() {""", r'''    /// REPRO (test only): the unchanged check kernel on cubes of `wg` units.
    /// Returns the entries never checked in count mode and the work counter.
    fn repro_run<R: Runtime>(
        dev: &JoinDevice<R>,
        cubes: u32,
        wg: u32,
        lh: &Handle,
        lw: usize,
        rh: &Handle,
        rw: usize,
        n: usize,
    ) -> (Vec<usize>, u32) {
        let c = &dev.client;
        let words = 4 * n.max(1);
        let out = c.create(cubecl::bytes::Bytes::from_elems(vec![0u32; words]));
        let oc = c.create(cubecl::bytes::Bytes::from_elems(vec![0u32; 1]));
        let cap = u32::try_from(n).unwrap();
        let cnt = c.create(cubecl::bytes::Bytes::from_elems(vec![cap]));
        let ran = c.create(cubecl::bytes::Bytes::from_elems(vec![0u32; STAGES + 1]));
        dev.launch_check(
            cubes, wg, lh, lw, &cnt, rh, rw, (&out, words), &oc, &ran, cap, cap, CHECK_COUNT,
        );
        let ran = dev.read_u32(&ran).expect("ran");
        assert_eq!(ran[3], cubes, "check cubes run");
        let out = dev.read_u32(&out).expect("out");
        let skipped = (0..n).filter(|&i| out[4 * i..4 * i + 4] == [0; 4]).collect();
        (skipped, ran[STAGES])
    }

    fn repro_partial_planes<R: Runtime>(client: &ComputeClient<R>, name: &str) {
        let mut fields = vec![(10, 47, 100, JoinParams { t: 2, k: 1, p: 0 })];
        for &(b, s, size) in PLAN_FIELDS {
            let range = FieldSize::new(s, s + size);
            let jp = crate::overlap_join::join_params_for(b, &range).expect("a join field");
            fields.push((b, s, s + size, jp));
        }
        let lim = device_limits(client, name);
        let mut shapes = std::collections::HashSet::new();
        let (mut total_skipped, mut total) = (0usize, 0usize);
        for (b, s, e, jp) in fields {
            let fs = FieldSetup::new(b, s, e, jp).expect("field setup");
            let plan = JoinPlan::new(&fs, lim, 1, 1 << 16, 1, lim.budget).expect("a layout fits");
            let layer = sorted_layer(&fs).expect("sorted layer");
            let dev = JoinDevice::new(client, &fs, layer, &plan).expect("device");
            let sh = dev.check;
            if !shapes.insert(sh) {
                continue;
            }
            let ns = synthetic(&sh, (u64::from(b) << 32) | u64::from(sh.f0 * 16 + sh.k2));
            let (w, m) = (fs.base.powu(sh.f0), fs.base.powu(sh.k2 - sh.f0));
            let mut recs = vec![0u32; 8 * ns.len().max(1)];
            let mut list = vec![0u32; 2 * ns.len().max(1)];
            for (i, &n) in ns.iter().enumerate() {
                let p = n / w;
                recs[8 * i] = u32::try_from(p & 0xFFFF_FFFF).unwrap();
                recs[8 * i + 1] = u32::try_from(p >> 32).unwrap();
                recs[8 * i + 6] = u32::try_from(p % m).unwrap();
                list[2 * i] = u32::try_from(i).unwrap();
                list[2 * i + 1] = u32::try_from(n % w).unwrap();
            }
            let (lw, rw) = (list.len(), recs.len());
            let lh = client.create(cubecl::bytes::Bytes::from_elems(list));
            let rh = client.create(cubecl::bytes::Bytes::from_elems(recs));
            for wg in [JOIN_WG, 100, 48] {
                for cubes in [1, 3, CHECK_CUBES] {
                    let (skipped, counter) = repro_run(&dev, cubes, wg, &lh, lw, &rh, rw, ns.len());
                    println!(
                        "REPRO {name} b{b} {sh:?} cubes={cubes} wg={wg} entries={} skipped={} \
                         counter={counter} first_skipped={:?}",
                        ns.len(),
                        skipped.len(),
                        &skipped[..skipped.len().min(12)]
                    );
                    total_skipped += skipped.len();
                    total += ns.len();
                }
            }
        }
        println!("REPRO {name}: {total_skipped} of {total} entries never checked");
        assert_eq!(total_skipped, 0, "{name}: entries never checked on partly filled planes");
    }

    #[test]
    #[ignore = "requires a wgpu device"]
    fn repro_check_partial_planes() {
        let (client, name) = client();
        repro_partial_planes(&client, &name);
    }

    #[test]
    #[cfg(feature = "cubecl-cuda")]
    #[ignore = "requires an NVIDIA device"]
    fn repro_cuda_check_partial_planes() {
        let ctx = CubeclContext::new_cuda(0).expect("CubeCL CUDA init");
        let name = ctx.device_name();
        let CubeclContext::Cuda { client, .. } = ctx else {
            unreachable!("new_cuda is CUDA")
        };
        repro_partial_planes(&client, &name);
    }

    #[test]
    #[ignore = "requires a wgpu device"]
    fn cubecl_check_counts_match_the_cpu() {''')
open(sys.argv[2], 'w').write(s)
