//! Reviewer's check (CPU2 review, 2026-11-14): `TopFdSetup::run_of` against
//! exact big-integer arithmetic on adversarial blocks, and `cert(.., true)`'s
//! `Err(n)` against `Base::cert_parts` on blocks placed next to a digit
//! boundary of a certified position.
//!
//! Included as a child module of `cpu_top_fd` (so it sees the private items)
//! by appending to common/src/cpu_top_fd.rs:
//!
//!   #[cfg(test)]
//!   #[path = "<abs path>/CPU2/review/exact_run_check.rs"]
//!   mod review_exact;
//!
//! Run: cargo test --release -p nice_common review_exact -- --nocapture
//! Env REVIEW_BASES="40-64" (default 7-64), REVIEW_TRIALS (default 40).

use super::{TopFd, TopFdSetup};
use crate::base_range::get_base_range_u128;
use crate::overlap_join::Base;
use malachite::base::num::arithmetic::traits::{FloorRoot, Pow};
use malachite::natural::Natural;

struct Rng(u64);
impl Rng {
    fn next(&mut self) -> u64 {
        // splitmix64
        self.0 = self.0.wrapping_add(0x9E37_79B9_7F4A_7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58_476D_1CE4_E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D0_49BB_1331_11EB);
        z ^ (z >> 31)
    }
    fn below(&mut self, n: u128) -> u128 {
        let x = (u128::from(self.next()) << 64) | u128::from(self.next());
        x % n
    }
}

fn nat(x: u128) -> Natural {
    Natural::from(x)
}

/// Exact facts about block `[P·w, P·w + w − 1]` at position `(j, i)`:
/// (certified at i, exact run). The run is the number of blocks P, P+1, ...
/// whose last n has n^j < (⌊a^j/b^i⌋ + 1)·b^i, i.e. those for which the
/// lemma holds; 0 if the block itself straddles.
fn exact(b: u32, w: u128, cap: u32, p: u128, j: u64, i: u32) -> (bool, u128) {
    let bi = Natural::from(b).pow(u64::from(i));
    let a = nat(p * w);
    let e = nat(p * w + w - 1);
    let aj = (&a).pow(j);
    let ej = (&e).pow(j);
    let x = &aj / &bi;
    let t = (&x + Natural::from(1u32)) * &bi;
    if ej >= t {
        return (false, 0);
    }
    // from_j = max(cap, ndig(e^j − a^j), h)
    let d = &ej - &aj;
    let bn = Natural::from(b);
    let mut ndig = 0u32;
    let mut pw = Natural::from(1u32);
    while pw <= d {
        pw *= &bn;
        ndig += 1;
    }
    let mut h = 0u32;
    let mut pw = Natural::from(1u32);
    while &aj / &pw != &ej / &pw {
        pw *= &bn;
        h += 1;
    }
    let from = cap.max(ndig).max(h);
    // largest e* with e*^j < t; last block P* has P*·w + w − 1 <= e*.
    let estar = (&t - Natural::from(1u32)).floor_root(j);
    let wn = nat(w);
    let pstar = (&estar + Natural::from(1u32) - &wn) / &wn;
    let pstar = u128::try_from(&pstar).expect("P* fits u128");
    assert!(pstar >= p);
    (i >= from, pstar - p + 1)
}

fn bases() -> Vec<u32> {
    let s = std::env::var("REVIEW_BASES").unwrap_or_else(|_| "7-64".into());
    let (lo, hi) = s.split_once('-').map_or((7, 64), |(a, b)| {
        (a.parse().unwrap(), b.parse().unwrap())
    });
    (lo..=hi).collect()
}

#[test]
#[allow(clippy::many_single_char_names, clippy::too_many_lines)]
fn review_exact_run_bound_and_adversarial_runs() {
    let trials: u32 = std::env::var("REVIEW_TRIALS")
        .ok()
        .and_then(|x| x.parse().ok())
        .unwrap_or(40);
    let mut rng = Rng(0xC0FF_EE00_5EED_1234);
    let (mut evals, mut certified, mut tight, mut overclaim_uncert, mut violations) =
        (0u64, 0u64, 0u64, 0u64, 0u64);
    let (mut fails, mut covered, mut long_runs) = (0u64, 0u64, 0u64);
    let mut worst_ratio = 0.0f64;
    let mut setups = 0u64;
    for b in bases() {
        let Some(band) = get_base_range_u128(b).expect("base range") else {
            continue;
        };
        // The whole band, its two ends, and random sub-fields.
        let mut fields = vec![(band.start(), band.end())];
        for _ in 0..3 {
            let size = 1 + rng.below(band.size());
            let s = band.start() + rng.below(band.size() - size + 1);
            fields.push((s, s + size));
        }
        for (s, e) in fields {
            let Some(base) = Base::try_new(b, s, e - 1) else {
                continue;
            };
            for f0 in 1..base.l {
                let w = base.powu(f0);
                if w >= 1 << 32 {
                    break;
                }
                for o in 1..=2u32 {
                    let cap = f0 + o;
                    if cap >= base.l {
                        continue;
                    }
                    let (plo, phi) = (s.div_ceil(w), (e / w).saturating_sub(1));
                    if phi < plo + 4 {
                        continue;
                    }
                    for span in [1u32, b, b * b, 4096, 65_535, u32::MAX] {
                        let Some(fd) = TopFdSetup::try_new(&base, f0, o, cap, phi, b * b, span)
                        else {
                            continue;
                        };
                        setups += 1;
                        for _ in 0..trials {
                            // A position and a target digit boundary above a random block.
                            let (jj, i) = fd.order[(rng.next() % fd.order.len() as u64) as usize];
                            let (jj, i) = (usize::from(jj), u32::from(i));
                            let j = 2 + jj as u64;
                            let p0 = plo + rng.below(phi - plo + 1);
                            let bi = Natural::from(b).pow(u64::from(i));
                            let aj = nat(p0 * w).pow(j);
                            let t = (&aj / &bi + Natural::from(1u32)) * &bi;
                            let estar = (&t - Natural::from(1u32)).floor_root(j);
                            let wn = nat(w);
                            let Ok(pstar) =
                                u128::try_from(&((&estar + Natural::from(1u32)) / &wn))
                            else {
                                continue;
                            };
                            let pstar = pstar.saturating_sub(1);
                            let mut cands = vec![p0, pstar, pstar + 1, pstar + 2];
                            for k in 1..=4u128 {
                                cands.push(pstar.saturating_sub(k));
                            }
                            for t in 0..48 {
                                let d = 1u128 << t;
                                cands.push(pstar.saturating_sub(d));
                                cands.push(pstar.saturating_sub(d - 1));
                                cands.push(pstar.saturating_sub(d + 1));
                                // Near the span's edge of the bound.
                            }
                            for k in [1u128, 2, 3] {
                                cands.push(pstar.saturating_sub(u128::from(span).saturating_mul(k)));
                            }
                            for p in cands {
                                if p < plo || p > phi {
                                    continue;
                                }
                                let mut st = TopFd::default();
                                fd.advance(&mut st, p);
                                let n = fd.run_of(&st, jj, i);
                                evals += 1;
                                assert!(n >= 1 && n <= span.max(1), "b{b} P {p}: n {n} span {span}");
                                let (cert, run) = exact(b, w, cap, p, j, i);
                                if !cert {
                                    if u128::from(n) > run.max(1) {
                                        overclaim_uncert += 1;
                                    }
                                    continue;
                                }
                                certified += 1;
                                if u128::from(n) > run {
                                    violations += 1;
                                    eprintln!(
                                        "VIOLATION b{b} [{s},{e}) f0 {f0} o {o} span {span} P {p} j {j} i {i}: run_of {n} > exact {run}"
                                    );
                                }
                                let capped = run.min(u128::from(span));
                                if u128::from(n) == capped {
                                    tight += 1;
                                }
                                #[allow(clippy::cast_precision_loss)]
                                {
                                    worst_ratio = worst_ratio.max(f64::from(n) / capped as f64);
                                }
                                // The whole path: cert(.., true) and cert_parts on the run.
                                if let Err(m) = fd.cert(&st, true) {
                                    fails += 1;
                                    long_runs += u64::from(m > 64);
                                    let m = u128::from(m);
                                    let mut ds: Vec<u128> = (1..m.min(65)).collect();
                                    ds.extend(m.saturating_sub(64).max(1)..m);
                                    for _ in 0..16 {
                                        if m > 1 {
                                            ds.push(1 + rng.below(m - 1));
                                        }
                                    }
                                    for d in ds {
                                        let q = p + d;
                                        if q > phi {
                                            continue;
                                        }
                                        let a = q * w;
                                        assert_eq!(
                                            base.cert_parts(a, a + w - 1, cap),
                                            None,
                                            "b{b} [{s},{e}) f0 {f0} o {o} span {span}: run {m} from P {p}, block {q} passes"
                                        );
                                        covered += 1;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    eprintln!(
        "setups {setups}; run_of evaluations {evals}, at certified positions {certified} (equal to the capped exact run: {tight}; worst n/exact {worst_ratio:.6}); bound above exact at UNcertified positions (never asked): {overclaim_uncert}; VIOLATIONS {violations}"
    );
    eprintln!("failing certificates on these blocks {fails} (runs > 64: {long_runs}); later blocks re-certified by cert_parts: {covered}, all failing");
    assert_eq!(violations, 0);
    assert!(certified > 10_000);
}
