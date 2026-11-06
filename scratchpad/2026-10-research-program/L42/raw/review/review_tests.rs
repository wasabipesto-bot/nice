
#[cfg(test)]
#[allow(clippy::all, clippy::pedantic)]
mod review_tests {
    use super::*;
    use crate::base_range::get_base_range_u128;
    use crate::overlap_join::JoinParams;

    struct Lcg(u64);
    impl Lcg {
        fn next(&mut self) -> u64 {
            self.0 = self
                .0
                .wrapping_mul(6_364_136_223_846_793_005)
                .wrapping_add(1_442_695_040_888_963_407);
            self.0 >> 16
        }
        fn below(&mut self, n: u128) -> u128 {
            ((u128::from(self.next()) << 48) ^ u128::from(self.next())) % n
        }
    }

    /// Every base 40-64, fields of 1e13..1e17 across the band (and the
    /// band's very end): the stepped path is taken, and the word adds.
    #[test]
    fn review_production_fits() {
        for b in 40..=64u32 {
            let Some(band) = get_base_range_u128(b).unwrap() else { eprintln!("b{b}: no band"); continue };
            let (mut n, mut minw, mut maxw, mut maxdig) = (0, usize::MAX, 0, 0u32);
            let mut pts: Vec<u128> = (0..=200u128).map(|i| band.start() + band.size() / 200 * i).collect();
            pts.push(band.end());
            for &pt in &pts {
                for size in [10_000_000_000_000u128, 100_000_000_000_000, 10_000_000_000_000_000, 100_000_000_000_000_000] {
                    for (s, e) in [(pt, pt + size), (pt.saturating_sub(size), pt)] {
                        let (s, e) = (s.max(band.start()), e.min(band.end()));
                        if s >= e { continue; }
                        let Some(base) = Base::try_new(b, s, e - 1) else { continue };
                        let Some(jp) = JoinParams::for_length(b, base.l) else { continue };
                        let f0 = base.l - jp.t;
                        let o = jp.t + jp.k - base.l;
                        let k = jp.k;
                        let mut mid = 2;
                        while mid > 0 && (k + mid > base.s2 || u64::from(b).pow(k + mid - f0) >= 1 << 32 || k + mid > 12) { mid -= 1; }
                        let bmid = b.pow(mid);
                        let w = base.powu(f0);
                        let phi = (e - 1) / w;
                        let fd = TopFdSetup::try_new(&base, f0, o, k, phi, bmid);
                        assert!(fd.is_some(), "b{b} [{s}, {e}) {jp:?}: no FD");
                        let fd = fd.unwrap();
                        let adds = fd.addend_words.iter().sum::<usize>() + 7;
                        minw = minw.min(adds); maxw = maxw.max(adds);
                        maxdig = maxdig.max(base.s3 - 3 * f0);
                        n += 1;
                    }
                }
            }
            eprintln!("b{b}: {n} fields, word adds/step {minw}..={maxw}, P^3 digits <= {maxdig}");
            assert!(n > 0);
        }
    }

    /// x as a W4 from its digits (independent of low_value).
    fn value(x: &Digits, b: u32, ndig: u32) -> W4 {
        let mut acc = W4::default();
        for i in (0..ndig).rev() {
            acc = acc.mul_u128(u128::from(b)).add(&W4([u64::from(digit(x, i)), 0, 0, 0]));
        }
        acc
    }

    /// The carry test against the exact one at and around the two screen
    /// thresholds and the exact boundary rem + d = b^c0.
    #[test]
    fn review_carry_boundary() {
        let mut rng = Lcg(0x1234_5678_9ABC_DEF1);
        let (mut calls, mut screened_true, mut screened_false, mut exact_true) = (0u64, 0u64, 0u64, 0u64);
        let div20 = Div64::new(1 << 20);
        for b in 7..=64u32 {
            let lo = u128::from(b).pow(10);
            let Some(base) = Base::try_new(b, lo, lo) else { continue };
            for f0 in 1..=3u32 {
                for o in 1..=3u32 {
                    let Some(fd) = TopFdSetup::try_new(&base, f0, o, f0 + o, 2, b * b) else { continue };
                    for z in [2 * f0, 3 * f0] {
                        let bz = u128::from(b).pow(z);
                        for c0 in z..(z + 14).min(46) {
                            if (c0 as usize) >= fd.pw.len() { continue; }
                            let big = fd.pw[c0 as usize];
                            for _ in 0..60 {
                                // Random X with 40 digits; R = X mod b^(c0 - z).
                                let mut x = [0u64; NW];
                                for i in 0..40u32 {
                                    let mut g = (rng.next() % u64::from(b)) as u64;
                                    // Bias toward runs of b-1 and zeros.
                                    match rng.next() % 8 { 0 => g = u64::from(b - 1), 1 => g = 0, _ => {} }
                                    x[(i / 8) as usize] |= g << (8 * (i % 8));
                                }
                                let kk = c0 - z;
                                let rem = value(&x, b, kk).mul_u128(bz);
                                let gap = big.sub(&rem); // b^c0 - rem > 0
                                let unit = if c0 >= 2 { fd.pw[c0 as usize - 2] } else { W4([1, 0, 0, 0]) };
                                let mut m = unit; div20.divrem_w4(&mut m);
                                let r = if kk >= 2 { u64::from(digit(&x, kk - 1)) * u64::from(b) + u64::from(digit(&x, kk - 2)) } else { 0 };
                                let bb = u128::from(b * b);
                                let mut cands: Vec<W4> = Vec::new();
                                // around the exact boundary
                                cands.push(gap);
                                // around the screen thresholds
                                if bb > u128::from(r) {
                                    cands.push(unit.mul_u128(bb - u128::from(r)).add(&m));
                                }
                                if bb > u128::from(r) + 1 {
                                    cands.push(unit.mul_u128(bb - u128::from(r) - 1).sub(&m));
                                }
                                for c in cands {
                                    for dlt in -3i64..=3 {
                                        let d = if dlt >= 0 { c.add(&W4([dlt as u64, 0, 0, 0])) } else { c.sub(&W4([(-dlt) as u64, 0, 0, 0])) };
                                        // d must be in [0, b^c0)
                                        if d.0[3] >> 63 == 1 || !d.lt(&big) { continue; }
                                        let want = !rem.add(&d).lt(&big);
                                        let got = fd.carry(&x, &d, c0, z, bz);
                                        assert_eq!(got, want, "b{b} f0 {f0} o {o} z {z} c0 {c0} d {d:?}");
                                        calls += 1;
                                        exact_true += u64::from(want);
                                        // Would the screen have decided?
                                        if c0 >= z + 2 {
                                            let rf = r as f64;
                                            let df = w4_f64(&d) * fd.inv[c0 as usize];
                                            if rf + df >= fd.b2f + SCREEN_MARGIN { screened_true += 1; }
                                            else if rf + 1.0 + df <= fd.b2f - SCREEN_MARGIN { screened_false += 1; }
                                        }
                                    }
                                }
                                // random d too
                                for _ in 0..4 {
                                    let mut d = W4([rng.next() ^ (rng.next() << 32), rng.next() ^ (rng.next() << 32), rng.next() ^ (rng.next() << 32), 0]);
                                    // reduce below b^c0
                                    let mut tries = 0;
                                    while !d.lt(&big) && tries < 200 { d = W4([d.0[0] >> 1 | d.0[1] << 63, d.0[1] >> 1 | d.0[2] << 63, d.0[2] >> 1, 0]); tries += 1; }
                                    let want = !rem.add(&d).lt(&big);
                                    assert_eq!(fd.carry(&x, &d, c0, z, bz), want);
                                    calls += 1;
                                }
                            }
                        }
                    }
                }
            }
        }
        eprintln!("carry: {calls} calls, {exact_true} true; screen decided {screened_true} true / {screened_false} false at the boundary candidates");
        assert!(calls > 100_000 && screened_true > 1000 && screened_false > 1000);
    }

    /// add_digits with a forced ripple past the carry word.
    #[test]
    fn review_ripple() {
        for b in [7u32, 10, 40, 60, 64] {
            let bias = 256 - u64::from(b);
            let top = u64::from(b - 1);
            for hi in 1..NW - 1 {
                // x: words 0..=hi all b-1, word hi+1 has a b-1 then 0s.
                let mut x = [0u64; NW];
                for i in 0..=hi { x[i] = top * LO; }
                x[hi + 1] = top | (top << 8);
                let mut y = [0u64; NW];
                y[0] = 1;
                add_digits(&mut x, &y, 0, hi, bias);
                // Expect: words 0..=hi zero, word hi+1: digits 0,0,1.
                for i in 0..=hi { assert_eq!(x[i], 0, "b{b} hi {hi} word {i}"); }
                assert_eq!(x[hi + 1], 1 << 16, "b{b} hi {hi}");
            }
        }
    }
}
