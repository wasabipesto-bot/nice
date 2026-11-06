
    /// The batch load's `ceil(D·2^32/b²)`, as [`join_kernel`] forms it.
    fn fx_top(d: u32, base: u32) -> u32 {
        let (_, q, r) = super::kernels::fx_consts(base);
        let b2 = base * base;
        d * q + (d * r + b2 - 1) / b2
    }

    /// [`walk_pf_lean`]'s two digits of `F = ah + p·dh mod 2^32`: the high
    /// words of `F·b` and of `(F·b mod 2^32)·b`.
    #[allow(clippy::cast_possible_truncation)]
    fn fx_digits(ah: u32, p: u32, dh: u32, base: u32) -> (u32, u32) {
        let f = ah.wrapping_add(p.wrapping_mul(dh));
        let fb = u64::from(f) * u64::from(base);
        ((fb >> 32) as u32, ((u64::from(fb as u32) * u64::from(base)) >> 32) as u32)
    }

    /// [`walk_pf`]'s digit test at mid = 2: four one-hot masks.
    fn pf_masks(seen: u64, g2: u32, g3: u32, h2: u32, h3: u32) -> bool {
        let at_k = (1u64 << g2) | (1u64 << g3);
        let at_k1 = (1u64 << h2) | (1u64 << h3);
        !(g2 == g3 || h2 == h3 || seen & at_k != 0 || (seen | at_k) & at_k1 != 0)
    }

    /// [`walk_pf_lean`]'s on the bit-reversed `seen`: digit g is the sign
    /// bit of `hi32(seen << g)`, and six compares.
    #[allow(clippy::cast_possible_truncation, clippy::cast_possible_wrap)]
    fn pf_lean(rseen: u64, g2: u32, g3: u32, h2: u32, h3: u32) -> bool {
        let hi = |g: u32| ((rseen << g) >> 32) as u32;
        let hit = hi(g2) | hi(g3) | hi(h2) | hi(h3);
        !(g2 == g3 || h2 == h3 || g2 == h2 || g2 == h3 || g3 == h2 || g3 == h3 || (hit as i32) < 0)
    }

    fn xorshift(x: &mut u64) -> u64 {
        *x ^= *x << 13;
        *x ^= *x >> 7;
        *x ^= *x << 17;
        *x
    }

    /// The lean prefilter's fixed-point digits at every base 10-64: `C =
    /// ceil(2^32/b²)` and the batch load's `dh` are the true ceilings (every
    /// D < b²), `A·C` fits a word, and the error `Δ = A·(C·b² − 2^32) +
    /// P·(dh·b² − D·2^32)` stays below 2^32 for every A, P, D < b². Then the
    /// digits themselves: every (P, D) at the largest A, and every (A, D) at
    /// the largest P, against `(A + P·D) mod b²` (the error grows with A and
    /// P; `fx_digits_are_exact_everywhere` runs every triple).
    #[test]
    fn fx_digits_match_the_division() {
        for base in 10u32..=64 {
            let b2 = base * base;
            let (c, q, r) = super::kernels::fx_consts(base);
            assert_eq!(u128::from(c), (1u128 << 32).div_ceil(u128::from(b2)), "b{base}");
            assert_eq!(u64::from(q) * u64::from(b2) + u64::from(r), 1u64 << 32, "b{base}");
            assert!((b2 - 1).checked_mul(c).is_some(), "b{base}: A·C overflows");
            let e1 = u64::from(c) * u64::from(b2) - (1u64 << 32);
            let mut e2max = 0u64;
            let dh: Vec<u32> = (0..b2).map(|d| fx_top(d, base)).collect();
            for d in 0..b2 {
                let want = (u128::from(d) << 32).div_ceil(u128::from(b2));
                assert_eq!(u128::from(dh[d as usize]), want, "b{base} D={d}");
                e2max = e2max.max(u64::from(dh[d as usize]) * u64::from(b2) - (u64::from(d) << 32));
            }
            let m = u64::from(b2 - 1);
            assert!(m * e1 + m * e2max < 1u64 << 32, "b{base}: Δ bound");
            let amax = b2 - 1;
            for p in 0..b2 {
                for d in 0..b2 {
                    let x = (amax + p * d) % b2;
                    assert_eq!(
                        fx_digits(amax * c, p, dh[d as usize], base),
                        (x / base, x % base),
                        "b{base} A={amax} P={p} D={d}"
                    );
                }
            }
            for a in 0..b2 {
                for d in 0..b2 {
                    let x = (a + amax * d) % b2;
                    assert_eq!(
                        fx_digits(a * c, amax, dh[d as usize], base),
                        (x / base, x % base),
                        "b{base} A={a} P={amax} D={d}"
                    );
                }
            }
        }
    }

    /// The fixed-point digits over every operand the join can give them: all
    /// (A, P, D) below b² at every base 10-64 (6.6e11 triples, minutes on all
    /// cores).
    #[test]
    #[ignore = "exhaustive, minutes on all cores"]
    #[allow(clippy::cast_possible_truncation)]
    fn fx_digits_are_exact_everywhere() {
        let threads = std::thread::available_parallelism().map_or(8, std::num::NonZero::get);
        let t0 = Instant::now();
        let mut total = 0u64;
        for base in 10u32..=64 {
            let b2 = base * base;
            let c = super::kernels::fx_consts(base).0;
            let next = std::sync::atomic::AtomicU32::new(0);
            std::thread::scope(|sc| {
                for _ in 0..threads {
                    sc.spawn(|| {
                        loop {
                            let d = next.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
                            if d >= b2 {
                                break;
                            }
                            let dh = fx_top(d, base);
                            for p in 0..b2 {
                                let u = p.wrapping_mul(dh);
                                let y = p * d % b2;
                                // (h, g): the digits of (A + P·D) mod b², stepped with A.
                                let (mut h, mut g) = (y / base, y % base);
                                let mut bad = 0u32;
                                for a in 0..b2 {
                                    let f = (a * c).wrapping_add(u);
                                    let fb = u64::from(f) * u64::from(base);
                                    let fh = (fb >> 32) as u32;
                                    let fg = ((u64::from(fb as u32) * u64::from(base)) >> 32) as u32;
                                    bad |= (fh ^ h) | (fg ^ g);
                                    g += 1;
                                    if g == base {
                                        g = 0;
                                        h += 1;
                                        if h == base {
                                            h = 0;
                                        }
                                    }
                                }
                                assert_eq!(bad, 0, "b{base} P={p} D={d}");
                            }
                        }
                    });
                }
            });
            total += u64::from(b2).pow(3);
        }
        println!(
            "fixed-point digits: {total} triples (A, P, D < b², b = 10-64) exact in {:.1}s on {threads} threads",
            t0.elapsed().as_secs_f64()
        );
    }

    /// The lean membership test (bit-reversed masks, four shifts and a sign
    /// test, six compares) is the four-mask test: every digit 4-tuple at
    /// every base 10-64 against a random set of seen digits (about a quarter
    /// of the bits, as the entry's 12 and a top's certificate give), and 10^7
    /// random tuples against sets of every density.
    #[test]
    #[allow(clippy::cast_possible_truncation)]
    fn lean_membership_matches_the_masks() {
        let mut x = 0x9E37_79B9_7F4A_7C15u64;
        let (mut fails, mut pass, mut n) = (0u64, 0u64, 0u64);
        for base in 10u32..=64 {
            for g2 in 0..base {
                for g3 in 0..base {
                    for h2 in 0..base {
                        for h3 in 0..base {
                            let seen = xorshift(&mut x) & xorshift(&mut x);
                            let want = pf_masks(seen, g2, g3, h2, h3);
                            fails += u64::from(want != pf_lean(seen.reverse_bits(), g2, g3, h2, h3));
                            pass += u64::from(want);
                            n += 1;
                        }
                    }
                }
            }
        }
        for _ in 0..10_000_000 {
            let r = xorshift(&mut x);
            let base = 10 + (r % 55) as u32;
            let dig = |s: u64| (s % u64::from(base)) as u32;
            let (g2, g3, h2, h3) = (dig(r >> 8), dig(r >> 20), dig(r >> 32), dig(r >> 44));
            let mut seen = xorshift(&mut x);
            for _ in 0..(r >> 60) % 4 {
                seen &= xorshift(&mut x);
            }
            seen &= u64::MAX >> (64 - base);
            let want = pf_masks(seen, g2, g3, h2, h3);
            fails += u64::from(want != pf_lean(seen.reverse_bits(), g2, g3, h2, h3));
            pass += u64::from(want);
            n += 1;
        }
        assert_eq!(fails, 0, "{fails} of {n} differ");
        assert!(pass > n / 50 && pass < n / 2, "{pass} of {n} pass");
    }

    /// The lean prefilter end to end against the division form ([`walk_pf`]
    /// at mid = 2, as `cpu_join`'s prefilter): random entries (A2, A3, P2,
    /// P3 < b², masks) and tops (D < b², certificate, seed flag), 10^6 per
    /// base 10-64.
    #[test]
    #[allow(clippy::cast_possible_truncation)]
    fn lean_prefilter_matches_the_division_form() {
        let mut x = 0x2545_F491_4F6C_DD1Du64;
        let mut pass = 0u64;
        for base in 10u32..=64 {
            let b2 = base * base;
            let c = super::kernels::fx_consts(base).0;
            let full = u64::MAX >> (64 - base);
            for _ in 0..1_000_000 {
                let r = xorshift(&mut x);
                let (a2, a3) = ((r % u64::from(b2)) as u32, ((r >> 16) % u64::from(b2)) as u32);
                let (p2, p3) = (((r >> 32) % u64::from(b2)) as u32, ((r >> 48) % u64::from(b2)) as u32);
                let r2 = xorshift(&mut x);
                let d = (r2 % u64::from(b2)) as u32;
                let seed = (r2 >> 20) & 1 == 1;
                let em = xorshift(&mut x) & xorshift(&mut x) & xorshift(&mut x) & full;
                let tm = xorshift(&mut x) & xorshift(&mut x) & full;
                let seen = em | if seed { tm } else { 0 };
                let (x2, x3) = ((a2 + p2 * d) % b2, (a3 + p3 * d) % b2);
                let want = pf_masks(seen, x2 % base, x3 % base, x2 / base, x3 / base);
                let dh = fx_top(d, base);
                let (h2, g2) = fx_digits(a2 * c, p2, dh, base);
                let (h3, g3) = fx_digits(a3 * c, p3, dh, base);
                let gated = if seed { tm.reverse_bits() } else { 0 };
                assert_eq!(pf_lean(em.reverse_bits() | gated, g2, g3, h2, h3), want, "b{base}");
                pass += u64::from(want);
            }
        }
        assert!(pass > 0);
    }
