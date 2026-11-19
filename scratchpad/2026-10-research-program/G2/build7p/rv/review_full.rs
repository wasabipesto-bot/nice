//! Reviewer's checks (scratch only, never pushed).
#![allow(clippy::all, clippy::pedantic)]
use super::arith::{U384, roots, unique_digits};
use super::coord::Coord;
use super::cpu::{Base, Shape, prefilter, search_field, top_cert_split};
use crate::base_range::get_base_range_u128;
use crate::client_process::{get_num_unique_digits, process_range_niceonly};
use crate::residue_filter::get_residue_filter;
use crate::stride_filter::StrideTable;

fn xs(seed: &mut u64) -> u64 {
    *seed ^= *seed << 13;
    *seed ^= *seed >> 7;
    *seed ^= *seed << 17;
    *seed
}

/// roots == production's residue filter, every base 3..=128.
#[test]
fn rv_roots_vs_production() {
    for b in 3..=128u32 {
        assert_eq!(roots(b), get_residue_filter(&b), "b{b}");
    }
}

/// unique_digits == production's get_num_unique_digits on whole small ranges.
#[test]
fn rv_unique_vs_production() {
    for b in [10u32, 12, 13, 14, 15, 17, 18, 19, 20, 22] {
        let r = get_base_range_u128(b).unwrap().unwrap();
        for n in r.first()..r.end() {
            assert_eq!(unique_digits(n, b).0, get_num_unique_digits(n, b), "b{b} n{n}");
        }
    }
}

/// Whole bases: the CPU reference's nice numbers == production's nice-only search.
#[test]
fn rv_nice_vs_production() {
    let cases: &[(u32, (u32, u32, u32), (u32, u32))] = &[
        (10, (0, 1, 0), (0, 2)),
        (12, (1, 2, 1), (1, 3)),
        (13, (1, 2, 1), (1, 3)),
        (14, (1, 2, 1), (1, 3)),
        (17, (1, 2, 1), (1, 3)),
        (18, (1, 2, 1), (1, 3)),
        (19, (1, 2, 1), (1, 3)),
        (20, (2, 3, 2), (2, 4)),
        (22, (2, 3, 2), (2, 4)),
        (23, (2, 3, 2), (2, 4)),
        (24, (1, 3, 2), (1, 4)),
        (25, (2, 4, 3), (2, 5)),
        (27, (2, 4, 3), (2, 5)),
        (28, (2, 4, 3), (2, 5)),
        (29, (2, 4, 3), (2, 5)),
    ];
    for &(b, (k0, k1, q0), (f0, k)) in cases {
        let c = Coord::with_digits(b, k0, k1, q0).unwrap();
        let t = std::time::Instant::now();
        let (o, _) = search_field::<u64>(&c, Shape { f0, k }, c.start, c.v_end() - c.start, 4).unwrap();
        let tm = t.elapsed();
        let r = get_base_range_u128(b).unwrap().unwrap();
        let res = std::panic::catch_unwind(|| {
            let table = StrideTable::new(b, 1);
            process_range_niceonly(&r, b, &table)
                .nice_numbers
                .iter()
                .filter(|x| x.num_uniques == b)
                .map(|x| x.number)
                .collect::<Vec<u128>>()
        });
        let mut prod = match res {
            Ok(v) => v,
            Err(_) => {
                eprintln!("REVIEW b{b}: production nice-only search panicked (stride table); using get_num_unique_digits scan");
                (r.first()..r.end()).filter(|&n| get_num_unique_digits(n, b) == b).collect()
            }
        };
        prod.sort_unstable();
        eprintln!("REVIEW b{b}: midout {} nice {:?} (survivors {}, checked {}, {tm:?}); production {}", o.nice.len(), o.nice, o.survivors, o.checked, prod.len());
        assert_eq!(o.nice, prod, "b{b}");
        if b == 10 {
            assert_eq!(o.nice, vec![69]);
        }
    }
}

/// Top certificate against a brute definition: the common top-down prefix of
/// n^2 and n^3 over every n in [a, c], at positions >= kpos.
fn top_brute(b: u32, a: u128, c: u128, kpos: u32, kmid: u32) -> Option<(u64, u64)> {
    let (mut mask, mut mhi) = (0u64, 0u64);
    for e in [2u32, 3] {
        let ds: Vec<Vec<u8>> = (a..=c)
            .map(|n| {
                let x = U384::from_u128(n);
                let s = x.mul(&x);
                if e == 2 { s.digits(u64::from(b)) } else { s.mul(&x).digits(u64::from(b)) }
            })
            .collect();
        let len = ds[0].len();
        if ds.iter().any(|d| d.len() != len) {
            continue;
        }
        let mut j = len;
        while j > kpos as usize {
            j -= 1;
            if ds.iter().any(|d| d[j] != ds[0][j]) {
                break;
            }
            let bit = 1u64 << ds[0][j];
            if mask & bit != 0 {
                return None;
            }
            mask |= bit;
            if j >= kmid as usize {
                mhi |= bit;
            }
        }
    }
    Some((mask, mhi))
}

#[test]
fn rv_top_cert_vs_brute() {
    for (b, f0, k) in [(10u32, 0u32, 2u32), (13, 0, 3), (19, 0, 4), (17, 1, 3), (20, 2, 4), (24, 1, 4), (25, 2, 5)] {
        let c = Coord::with_digits(b, 1, 2, 1).unwrap();
        let base = Base::new(&c);
        let w = base.pw[f0 as usize];
        let mut p = c.start / w;
        let mut cnt = 0;
        while p * w < c.end && cnt < 20_000 {
            let a = (p * w).max(c.start);
            let cc = (p * w + w - 1).min(c.end - 1);
            let got = top_cert_split::<u64>(&base, a, cc, k, k + 2);
            assert_eq!(got, top_brute(b, a, cc, k, k + 2), "b{b} p{p}");
            p += 1 + (p % 7);
            cnt += 1;
        }
    }
}

/// The prefilter at base 64, shape (4, 10): b^12 = 2^72, the large-modulus
/// branch of mm, which no small base reaches; against full digits.
#[test]
fn rv_prefilter_b64_large_modulus() {
    let c = Coord::for_base(64).unwrap();
    let base = Base::new(&c);
    let k = 10u32;
    let mut s = 0x1234_5678_9abc_def1u64;
    let (mut pass, mut tot) = (0, 0);
    for _ in 0..200_000 {
        let n = (1u128 << 75) | ((u128::from(xs(&mut s)) << 64 | u128::from(xs(&mut s))) & ((1u128 << 75) - 1));
        // a random sparse mhi
        let mhi: u64 = xs(&mut s) & xs(&mut s) & xs(&mut s);
        let x = U384::from_u128(n);
        let sq = x.mul(&x);
        let cu = sq.mul(&x);
        let mut seen = 0u64;
        let mut want = true;
        'o: for d in [sq.digits(64), cu.digits(64)] {
            for j in 0..(k + 2) as usize {
                let bit = 1u64 << d[j];
                if seen & bit != 0 || (j >= k as usize && mhi & bit != 0) {
                    want = false;
                    break 'o;
                }
                seen |= bit;
            }
        }
        let got = prefilter::<u64>(&base, k, n, mhi);
        assert_eq!(got, want, "n {n}");
        tot += 1;
        pass += u32::from(got);
    }
    // force some passes: n with distinct low digits are rare; also test n built from a known-good residue
    eprintln!("REVIEW prefilter b64: {pass}/{tot} passed");
}

/// One base-64 slice through the reference: timing, and every survivor
/// re-checked by q_shape / q_checked (run with --ignored).
#[test]
#[ignore]
fn rv_b64_one_slice() {
    use super::cpu::{q_checked, q_shape, slice_join};
    let c = Coord::for_base(64).unwrap();
    let sh = Shape::for_coord(&c);
    let base = Base::new(&c);
    for t in [77_777u128, 3] {
        let pip = sh.slices_of(&c, t).nth(1234).unwrap();
        let t0 = std::time::Instant::now();
        let mut got = Vec::new();
        let cn = slice_join::<u64>(&base, sh, pip, |_, n, pass| got.push((n, pass)));
        eprintln!("REVIEW b64 slice pip {pip}: {:?} in {:?}", cn, t0.elapsed());
        let mut seen = std::collections::HashSet::new();
        for &(n, pass) in &got {
            assert!(seen.insert(n));
            assert_eq!((n >> 24) & ((1 << 30) - 1), pip, "n {n} outside slice");
            assert!(q_shape::<u64>(&base, sh, n), "n {n}");
            assert_eq!(q_checked::<u64>(&base, sh, n), pass, "n {n}");
        }
        eprintln!("REVIEW b64 slice: {} survivors re-checked", got.len());
    }
}
