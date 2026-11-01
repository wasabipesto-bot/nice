import re
old=open('/tmp/topcert_old_cert_power.rs').read().split('\n')
# old: doc lines then #[cube] then fn cert_power(
i_fn=[i for i,l in enumerate(old) if l.strip()=='fn cert_power(' ][0]
body=old[i_fn:]
body[0]=body[0].replace('fn cert_power(','fn cert_power_lockstep(')
lock='\n'.join(['    /// `kernels::cert_power` as it was before it divided out only x\'s',
 '    /// digits: both endpoints\' powers turned into digits in lockstep, least',
 '    /// significant first, where a position whose digits differ resets the',
 '    /// run. The reference the remainder form must reproduce exactly.',
 '    #[cube]']+body)
test_code = r'''
    // ---------------------------------------------------------------------
    // The top certificate: the remainder form against the lockstep scan it
    // replaced and against the CPU's `Base::cert`.
    // ---------------------------------------------------------------------

''' + lock + r'''

    /// Words per interval in [`cert_test_kernel`]'s output: for the square
    /// and then the cube, `cert_power`'s (run lo, run hi, dup, dom lo, dom
    /// hi, c0) at 0 and 6 and `cert_power_lockstep`'s at 12 and 18; then
    /// `top_cert`'s (kept, mask lo, mask hi, c0 of the square, of the cube)
    /// at 24.
    const CERT_OUT: u32 = 32;

    /// Writes one power's certificate state at `o` (see [`CERT_OUT`]).
    #[cube]
    fn put_power(
        out: &mut Array<u32>,
        o: u32,
        run: u64,
        c0: &Array<u32>,
        dup: &Array<u32>,
        dom: &Array<u32>,
    ) {
        out[o as usize] = u32::cast_from(run);
        out[(o + 1u32) as usize] = u32::cast_from(run >> 32u64);
        out[(o + 2u32) as usize] = dup[0];
        out[(o + 3u32) as usize] = dom[0];
        out[(o + 4u32) as usize] = dom[1];
        out[(o + 5u32) as usize] = c0[0];
    }

    /// Per interval `[a, e]` (`limbs` u32 words each, a then e, in `iv`):
    /// both powers' certificates by `cert_power` and by
    /// `cert_power_lockstep`, and `top_cert`'s, written as [`CERT_OUT`]
    /// says.
    #[cube(launch_unchecked)]
    fn cert_test_kernel(
        iv: &Array<u32>,
        pw: &Array<u32>,
        out: &mut Array<u32>,
        n: u32,
        #[comptime] base: u32,
        #[comptime] limbs: u32,
        #[comptime] cap: u32,
        #[comptime] s2: u32,
        #[comptime] s3: u32,
        #[comptime] chunk_digits: u32,
        #[comptime] chunk_div: u32,
    ) {
        let i = ABSOLUTE_POS_X;
        if i < n {
            let nl2 = comptime!(2 * limbs);
            let nl3 = comptime!(3 * limbs);
            let nh2 = comptime!(4 * limbs);
            let nh3 = comptime!(6 * limbs);
            let mut a = Array::<u32>::new(limbs as usize);
            let mut e = Array::<u32>::new(limbs as usize);
            #[unroll]
            for j in 0..limbs {
                a[j as usize] = iv[(2u32 * limbs * i + j) as usize];
                e[j as usize] = iv[(2u32 * limbs * i + limbs + j) as usize];
            }
            let mut a2 = Array::<u32>::new(nh2 as usize);
            let mut e2 = Array::<u32>::new(nh2 as usize);
            let mut a3 = Array::<u32>::new(nh3 as usize);
            let mut e3 = Array::<u32>::new(nh3 as usize);
            powers16(&a, &e, &mut a2, &mut e2, &mut a3, &mut e3, limbs);
            let mut x2 = Array::<u32>::new(nh2 as usize);
            let mut y2 = Array::<u32>::new(nh2 as usize);
            let mut x3 = Array::<u32>::new(nh3 as usize);
            let mut y3 = Array::<u32>::new(nh3 as usize);
            #[unroll]
            for j in 0..nh2 {
                x2[j as usize] = a2[j as usize];
                y2[j as usize] = e2[j as usize];
            }
            #[unroll]
            for j in 0..nh3 {
                x3[j as usize] = a3[j as usize];
                y3[j as usize] = e3[j as usize];
            }
            let o = i * CERT_OUT;
            let mut c0 = Array::<u32>::new(1usize);
            let mut dup = Array::<u32>::new(1usize);
            let mut dom = Array::<u32>::new(2usize);
            let m = cert_power(
                &mut a2, &e2, pw, &mut c0, &mut dup, &mut dom, nl2, nl3, s2, cap, base,
                chunk_digits, chunk_div,
            );
            put_power(out, o, m, &c0, &dup, &dom);
            let m = cert_power(
                &mut a3, &e3, pw, &mut c0, &mut dup, &mut dom, nl3, nl3, s3, cap, base,
                chunk_digits, chunk_div,
            );
            put_power(out, o + 6u32, m, &c0, &dup, &dom);
            let m = cert_power_lockstep(
                &mut x2, &mut y2, pw, &mut c0, &mut dup, &mut dom, nl2, nl3, s2, cap, base,
                chunk_digits, chunk_div,
            );
            put_power(out, o + 12u32, m, &c0, &dup, &dom);
            let m = cert_power_lockstep(
                &mut x3, &mut y3, pw, &mut c0, &mut dup, &mut dom, nl3, nl3, s3, cap, base,
                chunk_digits, chunk_div,
            );
            put_power(out, o + 18u32, m, &c0, &dup, &dom);
            let mut res = Array::<u32>::new(3usize);
            let mask = top_cert(
                &a, &e, pw, &mut res, base, limbs, cap, s2, s3, chunk_digits, chunk_div,
            );
            out[(o + 24u32) as usize] = res[0];
            out[(o + 25u32) as usize] = u32::cast_from(mask);
            out[(o + 26u32) as usize] = u32::cast_from(mask >> 32u64);
            out[(o + 27u32) as usize] = res[1];
            out[(o + 28u32) as usize] = res[2];
        }
    }

    /// A splitmix64 stream for the interval generators.
    struct SplitMix(u64);

    impl SplitMix {
        fn next(&mut self) -> u64 {
            self.0 = self.0.wrapping_add(0x9E37_79B9_7F4A_7C15);
            let mut z = self.0;
            z = (z ^ (z >> 30)).wrapping_mul(0xBF58_476D_1CE4_E5B9);
            z = (z ^ (z >> 27)).wrapping_mul(0x94D0_49BB_1331_11EB);
            z ^ (z >> 31)
        }

        /// Below `n` (> 0), near enough uniform for a test.
        fn below(&mut self, n: u128) -> u128 {
            ((u128::from(self.next()) << 64) | u128::from(self.next())) % n
        }
    }

    /// What one group of intervals exercised.
    #[derive(Default)]
    struct CertTally {
        intervals: u64,
        kept: u64,
        /// Powers whose shifted endpoints differ by one (the carry case).
        carried: u64,
        /// Powers with a digit at or above c0 (c0 below the digit count).
        scanned: u64,
    }

    /// Runs `iv` (one comptime shape: base, `limbs`, `cap` and the digit
    /// counts of `base`) through [`cert_test_kernel`] with the production
    /// chunk constants, and asserts per interval that `cert_power` equals
    /// `cert_power_lockstep` on both powers, word for word, and that
    /// `top_cert` equals `Base::cert` and its c0 terms `Base::cert_floor`.
    #[allow(clippy::cast_possible_truncation)]
    fn check_cert_group<R: Runtime>(
        client: &ComputeClient<R>,
        base: &crate::overlap_join::Base,
        limbs: u32,
        cap: u32,
        iv: &[(u128, u128)],
        tally: &mut CertTally,
    ) {
        if iv.is_empty() {
            return;
        }
        let b = base.b;
        let nl3 = 3 * limbs as usize;
        let mut pw = Vec::with_capacity((base.s3 as usize + 1) * nl3);
        for i in 0..=base.s3 {
            let words: Vec<u32> = base
                .poww_words(i)
                .iter()
                .flat_map(|&w| [w as u32, (w >> 32) as u32])
                .collect();
            assert!(
                words[nl3..].iter().all(|&x| x == 0),
                "b{b}: b^{i} does not fit {nl3} words"
            );
            pw.extend_from_slice(&words[..nl3]);
        }
        let mut words = Vec::with_capacity(iv.len() * 2 * limbs as usize);
        for &(a, e) in iv {
            assert!(e >> (32 * limbs) == 0, "b{b}: [{a}, {e}] exceeds {limbs} words");
            for x in [a, e] {
                words.extend((0..limbs).map(|j| (x >> (32 * j)) as u32));
            }
        }
        let n = u32::try_from(iv.len()).expect("a test-sized group");
        let (cd, cdiv) = chunk_constants_u16(b);
        let out = client.empty(iv.len() * CERT_OUT as usize * 4);
        let iv_h = client.create(cubecl::bytes::Bytes::from_elems(words.clone()));
        let pw_h = client.create(cubecl::bytes::Bytes::from_elems(pw.clone()));
        unsafe {
            cert_test_kernel::launch_unchecked::<R>(
                client,
                CubeCount::Static(n.div_ceil(JOIN_WG), 1, 1),
                CubeDim::new_1d(JOIN_WG),
                ArrayArg::from_raw_parts(iv_h, words.len()),
                ArrayArg::from_raw_parts(pw_h, pw.len()),
                ArrayArg::from_raw_parts(out.clone(), iv.len() * CERT_OUT as usize),
                n,
                b,
                limbs,
                cap,
                base.s2,
                base.s3,
                cd,
                cdiv,
            );
        }
        let bytes = client.read_one(out).expect("read the certificates");
        let got = u32::from_bytes(&bytes);
        for (i, &(a, e)) in iv.iter().enumerate() {
            let o = &got[i * CERT_OUT as usize..(i + 1) * CERT_OUT as usize];
            let at = format!("b{b} [{a}, {e}] cap {cap}");
            assert_eq!(o[0..6], o[12..18], "{at}: the square's certificate differs");
            assert_eq!(o[6..12], o[18..24], "{at}: the cube's certificate differs");
            let mask = u64::from(o[25]) | (u64::from(o[26]) << 32);
            let want = base.cert(a, e, cap);
            assert_eq!((o[24] == 1).then_some(mask), want, "{at}: against Base::cert");
            assert_eq!(
                o[27].min(o[28]),
                base.cert_floor(a, e, cap),
                "{at}: against Base::cert_floor"
            );
            tally.intervals += 1;
            tally.kept += u64::from(want.is_some());
            for p in [&o[0..6], &o[6..12]] {
                tally.carried += u64::from(p[3] <= p[4]);
                tally.scanned += u64::from(p[5] < if p == &o[0..6] { base.s2 } else { base.s3 });
            }
        }
    }

    /// The top certificate from the low endpoint's digits and a remainder
    /// (`kernels::cert_power`) equals the lockstep scan of both endpoints'
    /// digits it replaced, power by power and word for word (the mask, the
    /// repeat flag, the digit interval at the first disagreement, c0), and
    /// `top_cert` equals the CPU's `Base::cert` and `cert_floor`: on
    /// partition-extended tops of production-shaped fields at bases 58-64,
    /// and on arbitrary intervals and caps at smaller bases, in groups that
    /// share a kernel shape (where c0 is often the cap). More with
    /// `NICE_TEST_CERT_SAMPLES` per field and base (default 20,000).
    fn check_certificates<R: Runtime>(client: &ComputeClient<R>, name: &str) {
        use crate::overlap_join::{Base, join_params_for};
        let per: u64 = std::env::var("NICE_TEST_CERT_SAMPLES")
            .ok()
            .and_then(|v| v.parse().ok())
            .unwrap_or(20_000);
        let mut tally = CertTally::default();
        for (b, s0, size) in [
            (58, 183_859_216_587_923_470_200, 1_000_000_000_000_000),
            (60, 795_599_612_114_824_200_908, 10_000_000_000_000_000),
            (62, 12_255_736_762_397_899_821_056, 10_000_000_000_000_000),
            (62, 7_997_740_455_941_656_911_841, 100_000_000_000_000_000),
            (64, 72_806_461_862_957_161_709_568, 10_000_000_000_000_000),
        ] {
            let range = FieldSize::new(s0, s0 + size);
            let jp = join_params_for(b, &range).expect("a join field");
            let fs = FieldSetup::new(b, s0, s0 + size, jp).expect("field setup");
            let limbs = crate::gpu_config::n_limbs(b).expect("a base range");
            let mut rng = SplitMix(u64::from(b) * 0x51ED_2701 + (size >> 40) as u64);
            let mut iv = Vec::new();
            for _ in 0..per {
                let (p0, _) = fs.tlay[rng.below(fs.tlay.len() as u128) as usize];
                let p = p0 * fs.nparts + rng.below(fs.nparts);
                if p < fs.plo || p > fs.phi {
                    continue;
                }
                let lo = p * fs.w;
                iv.push((lo.max(fs.s), (lo + fs.w - 1).min(fs.e - 1)));
            }
            check_cert_group(client, &fs.base, limbs, jp.k, &iv, &mut tally);
        }
        for b in [10u32, 12, 20, 30, 40, 47, 50, 57] {
            let mut rng = SplitMix(u64::from(b) * 0x2545_F491);
            for _ in 0..4 {
                // n of about `half` + 1 digits, any cap below 6, widths up
                // to 2^40 or n's own: the intervals whose powers keep their
                // digit counts and share the first one's.
                let half = 2 + u32::try_from(rng.below(14)).unwrap();
                let cap = u32::try_from(rng.below(6)).unwrap();
                let start = u128::from(b).pow(half);
                let bits = 128 - start.leading_zeros();
                let mut iv = Vec::new();
                let mut shape: Option<(Base, u32)> = None;
                for _ in 0..per / 16 {
                    let a = start + rng.below(start * 3);
                    let shift = rng.below(u128::from(bits.min(40)));
                    let e = a + rng.below(1 << shift);
                    let Some(base) = Base::try_new(b, a, e) else {
                        continue;
                    };
                    let words = (128 - e.leading_zeros()).div_ceil(32).max(1);
                    let limbs = (words..=3).find(|&l| {
                        base.poww_words(base.s3)[..]
                            .iter()
                            .skip(3 * l as usize / 2)
                            .all(|&w| w == 0)
                            && (3 * l) % 2 == 0
                            || base.poww_words(base.s3)[(3 * l as usize).div_ceil(2)..]
                                .iter()
                                .all(|&w| w == 0)
                                && u64::from(base.poww_words(base.s3)[3 * l as usize / 2])
                                    >> 32
                                    == 0
                    });
                    let Some(limbs) = limbs else { continue };
                    match &shape {
                        None => shape = Some((base, limbs)),
                        Some((s, l)) if (s.s2, s.s3, *l) != (base.s2, base.s3, limbs) => continue,
                        Some(_) => {}
                    }
                    iv.push((a, e));
                }
                if let Some((base, limbs)) = shape {
                    check_cert_group(client, &base, limbs, cap, &iv, &mut tally);
                }
            }
        }
        println!(
            "{name}: {} intervals, {} kept; {} of the powers scanned above c0, {} of them \
             with the carry",
            tally.intervals, tally.kept, tally.scanned, tally.carried
        );
        assert!(
            tally.kept > per && tally.carried > per,
            "the kept case or the carry is barely tested"
        );
    }

    #[test]
    #[ignore = "requires a wgpu device"]
    fn top_certificates_match_the_lockstep_scan_and_the_cpu() {
        let (client, name) = client();
        check_certificates(&client, &name);
    }

    /// The same on `CubeCL`'s CUDA runtime.
    #[test]
    #[cfg(feature = "cubecl-cuda")]
    #[ignore = "requires an NVIDIA device"]
    fn cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu() {
        let ctx = CubeclContext::new_cuda(0).expect("CubeCL CUDA init");
        let name = ctx.device_name();
        let CubeclContext::Cuda { client, .. } = ctx else {
            unreachable!("new_cuda is CUDA")
        };
        check_certificates(&client, &name);
    }
'''
open('/tmp/topcert/test_code.rs','w').write(test_code)
print("ok")
