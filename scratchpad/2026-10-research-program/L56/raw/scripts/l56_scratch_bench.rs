
// L56 SCRATCH (not for the commit): the check on recorded survivors.
#[cfg(test)]
mod l56_scratch {
    use super::*;
    use crate::client_process::{get_is_nice, get_is_nice_with_known_lsd};
    use crate::fixed_width::U256;
    use std::time::Instant;

    fn digits(mut x: U256, b: u32) -> Vec<u32> {
        let mut v = Vec::new();
        while !x.is_zero() {
            v.push(x.div_assign_rem_u32(b));
        }
        v
    }

    #[inline(always)]
    fn scan5<const B: u32, const B4: u32, const B5: u32>(mut x: U256, mut seen: u64, end: u32) -> Option<u64> {
        x.div_assign_rem_u32_const::<B4>();
        x.div_assign_rem_u32_const::<B4>();
        let mut pos = 8;
        loop {
            let mut r = x.div_assign_rem_u32_const::<B5>();
            for _ in 0..5 {
                if pos >= end {
                    return Some(seen);
                }
                let d = r % B;
                r /= B;
                let bit = 1u64 << d;
                if seen & bit != 0 {
                    return None;
                }
                seen |= bit;
                pos += 1;
            }
        }
    }

    #[inline(never)]
    fn v3<const B: u32, const B4: u32, const B5: u32>(n: u128, seen: u64, ends: [u32; 2]) -> bool {
        let sq = U256::mul_u128_u128(n, n);
        let Some(seen) = scan5::<B, B4, B5>(sq, seen, ends[0]) else {
            return false;
        };
        scan5::<B, B4, B5>(sq.mul_u128_truncating(n), seen, ends[1]).is_some()
    }

    fn bench<const B: u32, const B4: u32, const B5: u32>(b: u32, start: u128, size: u128, parts: usize) {
        let range = FieldSize::new(start, start + size);
        let (jp, slices) = slices_for(b, &range).expect("join");
        let join = CpuJoin::new(b, &slices[0], jp).expect("setup");
        let order = crate::bench_defs::sample_order(join.partitions());
        let mut rec = Vec::new();
        let mut sc = Scratch::default();
        for &v in order.iter().take(parts) {
            join.run(v, &mut sc, Some(&mut rec));
        }
        let (s2, s3) = (join.fs.base.s2, join.fs.base.s3);
        let seed3: Vec<u64> = rec
            .iter()
            .map(|c| {
                let sq = U256::mul_u128_u128(c.n, c.n);
                let d2 = digits(sq, b);
                let d3 = digits(sq.mul_u128_truncating(c.n), b);
                d2[..3].iter().chain(&d3[..3]).fold(0u64, |a, &g| a | 1 << g)
            })
            .collect();
        // Digits a check converts before its verdict: the old check (from
        // position 3, seeded with the 6 low digits), and this one (the
        // middle, from k2 = 8, seeded with the low and top digits).
        let (mut old_d, mut new_d, mut first4, mut sq_pass) = (0u64, 0u64, 0u64, 0u64);
        for c in &rec {
            let sq = U256::mul_u128_u128(c.n, c.n);
            let d2 = digits(sq, b);
            let d3 = digits(sq.mul_u128_truncating(c.n), b);
            let mut seen = d2[..3].iter().chain(&d3[..3]).fold(0u64, |a, &g| a | 1 << g);
            'o: for d in [&d2[3..], &d3[3..]] {
                for &g in d {
                    old_d += 1;
                    if seen & 1 << g != 0 {
                        break 'o;
                    }
                    seen |= 1 << g;
                }
            }
            let mut seen = c.low | c.top;
            let mut k = 0u64;
            let mut rep = false;
            for (j, d) in [&d2[8..c.ends[0] as usize], &d3[8..c.ends[1] as usize]].into_iter().enumerate() {
                for &g in d {
                    k += 1;
                    if seen & 1 << g != 0 {
                        rep = true;
                        break;
                    }
                    seen |= 1 << g;
                }
                if rep {
                    break;
                }
                if j == 0 {
                    sq_pass += 1;
                }
            }
            new_d += k;
            first4 += u64::from(rep && k <= 4);
        }
        let nn = rec.len() as f64;
        eprintln!(
            "digits before the verdict: old {:.2}, seeded {:.2}; decided within the first 4 middle digits {:.2} %; n² middle passes {:.3} %",
            old_d as f64 / nn, new_d as f64 / nn, 100.0 * first4 as f64 / nn, 100.0 * sq_pass as f64 / nn
        );
        let gated = rec.iter().filter(|c| c.top != 0).count();
        let avg_top: f64 = rec.iter().map(|c| f64::from(c.top.count_ones())).sum::<f64>() / rec.len() as f64;
        eprintln!("b{b}: {} checked, {gated} gated, top digits avg {avg_top:.2}", rec.len());
        let mut diff = 0;
        for (c, &s3m) in rec.iter().zip(&seed3) {
            let want = get_is_nice(c.n, b);
            diff += u32::from(get_is_nice_with_known_lsd(c.n, b, 3, s3m) != want);
            diff += u32::from(join.check.nice(c.p, c.r0, c.low, c.top, c.ends) != want);
            diff += u32::from(join.check.nice(c.p, c.r0, c.low, 0, [s2, s3]) != want);
            diff += u32::from(v3::<B, B4, B5>(c.n, c.low | c.top, c.ends) != want);
        }
        eprintln!("verdict differences: {diff}");
        if let Ok(v) = std::env::var("L56_ONLY") {
            let mut h = 0u32;
            let t = Instant::now();
            for _ in 0..10 {
                for c in &rec {
                    h += u32::from(match v.as_str() {
                        "old" => get_is_nice_with_known_lsd(c.n, b, 3, c.low),
                        "cols" => join.check.nice(c.p, c.r0, c.low, c.top, c.ends),
                        _ => v3::<B, B4, B5>(c.n, c.low | c.top, c.ends),
                    });
                }
            }
            eprintln!("only {v}: {:.1} ns h {h}", t.elapsed().as_secs_f64() * 1e9 / rec.len() as f64 / 10.0);
            return;
        }
        for rep in 0..3 {
            let t = Instant::now();
            let mut h = 0u32;
            for (c, &s3m) in rec.iter().zip(&seed3) {
                h += u32::from(get_is_nice_with_known_lsd(c.n, b, 3, s3m));
            }
            let t0 = t.elapsed().as_secs_f64();
            let t = Instant::now();
            for c in &rec {
                h += u32::from(join.check.nice(c.p, c.r0, c.low, c.top, c.ends));
            }
            let t1 = t.elapsed().as_secs_f64();
            let t = Instant::now();
            for c in &rec {
                h += u32::from(join.check.nice(c.p, c.r0, c.low, 0, [s2, s3]));
            }
            let t2 = t.elapsed().as_secs_f64();
            let t = Instant::now();
            for c in &rec {
                h += u32::from(v3::<B, B4, B5>(c.n, c.low | c.top, c.ends));
            }
            let t3 = t.elapsed().as_secs_f64();
            let t = Instant::now();
            for c in &rec {
                h += u32::from(v3::<B, B4, B5>(c.n, c.low, [s2, s3]));
            }
            let t4 = t.elapsed().as_secs_f64();
            let ns = |t: f64| t * 1e9 / rec.len() as f64;
            eprintln!(
                "rep {rep}: old {:.1} ns; cols+top {:.1} (x{:.2}); cols {:.1} (x{:.2}); v3+top {:.1} (x{:.2}); v3 {:.1} (x{:.2}); h {h}",
                ns(t0), ns(t1), t0 / t1, ns(t2), t0 / t2, ns(t3), t0 / t3, ns(t4), t0 / t4
            );
        }
    }

    #[test]
    #[ignore = "L56 scratch bench"]
    fn l56_check_bench() {
        bench::<60, { 60 * 60 * 60 * 60 }, { 60 * 60 * 60 * 60 * 60 }>(60, 1_157_209_632_114_824_200_908, 10_000_000_000_000_000, 2);
        bench::<62, { 62 * 62 * 62 * 62 }, { 62 * 62 * 62 * 62 * 62 }>(62, 4_473_066_762_334_864_396_992, 100_000_000_000_000_000, 2);
    }
}
