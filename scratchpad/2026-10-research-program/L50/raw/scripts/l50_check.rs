//! L50 scratch bench (not for a PR): the CPU join's full check on recorded
//! join survivors (the `n` that passed the prefilter), three ways.
//!
//! V0: today's `get_is_nice_with_known_lsd(n, b, 3, mask of digits 0..2)`.
//! V1: seeded with the 16 digits the join already knows (positions 0..7 of
//!     n² and n³), scanning n² and n³ from position 8 (U256, two divisions
//!     by b⁴ to drop the known digits).
//! V2: n² in base b² by schoolbook columns from the low end (carries of
//!     columns 0..3, digits from column 4 on), exit at the first repeat; n³
//!     (when n² passes) as V1.
//!
//! usage: l50_check <base> <file of u128 LE> [reps]
use nice_common::client_process::get_is_nice_with_known_lsd;
use nice_common::fixed_width::U256;
use std::time::Instant;

/// Digits of `x` (U256), low first, until it is zero.
fn digits_u256(mut x: U256, b: u32) -> Vec<u32> {
    let mut v = Vec::new();
    while !x.is_zero() {
        v.push(x.div_assign_rem_u32(b));
    }
    v
}

#[inline(never)]
fn v0<const B: u32>(n: &[u128], seed3: &[u64]) -> u64 {
    let mut hits = 0;
    for (&x, &s) in n.iter().zip(seed3) {
        hits += u64::from(get_is_nice_with_known_lsd(x, B, 3, s));
    }
    hits
}

#[inline(always)]
fn scan_from<const B: u32, const B4: u32>(x: U256, seen: u64) -> Option<u64> {
    scan_from_c::<B, B4, false>(x, seen, &mut 0)
}

#[inline(always)]
fn scan_from_c<const B: u32, const B4: u32, const C: bool>(mut x: U256, mut seen: u64, cnt: &mut u32) -> Option<u64> {
    x.div_assign_rem_u32_const::<B4>();
    x.div_assign_rem_u32_const::<B4>();
    while !x.is_zero() {
        let d = x.div_assign_rem_u32_const::<B>();
        if C {
            *cnt += 1;
        }
        let bit = 1u64 << d;
        if seen & bit != 0 {
            return None;
        }
        seen |= bit;
    }
    Some(seen)
}

#[inline(always)]
fn check_v1<const B: u32, const B4: u32>(n: u128, seed16: u64) -> bool {
    let sq = U256::mul_u128_u128(n, n);
    let Some(seen) = scan_from::<B, B4>(sq, seed16) else {
        return false;
    };
    scan_from::<B, B4>(sq.mul_u128_truncating(n), seen).is_some()
}

#[inline(always)]
fn scan5<const B: u32, const B4: u32, const B5: u32>(x: U256, seen: u64) -> Option<u64> {
    scan5_c::<B, B4, B5, false>(x, seen, &mut 0)
}

#[inline(always)]
fn scan5_c<const B: u32, const B4: u32, const B5: u32, const C: bool>(mut x: U256, mut seen: u64, cnt: &mut u32) -> Option<u64> {
    x.div_assign_rem_u32_const::<B4>();
    x.div_assign_rem_u32_const::<B4>();
    loop {
        let mut r = x.div_assign_rem_u32_const::<B5>();
        let last = x.is_zero();
        let mut i = 0;
        while if last { r != 0 } else { i < 5 } {
            let d = r % B;
            r /= B;
            if C {
                *cnt += 1;
            }
            let bit = 1u64 << d;
            if seen & bit != 0 {
                return None;
            }
            seen |= bit;
            i += 1;
        }
        if last {
            return Some(seen);
        }
    }
}

#[inline(always)]
fn check_v3<const B: u32, const B4: u32, const B5: u32>(n: u128, seed16: u64) -> bool {
    let sq = U256::mul_u128_u128(n, n);
    let Some(seen) = scan5::<B, B4, B5>(sq, seed16) else {
        return false;
    };
    scan5::<B, B4, B5>(sq.mul_u128_truncating(n), seen).is_some()
}

#[inline(never)]
fn v3<const B: u32, const B4: u32, const B5: u32>(n: &[u128], seed16: &[u64]) -> u64 {
    let mut hits = 0;
    for (&x, &s) in n.iter().zip(seed16) {
        hits += u64::from(check_v3::<B, B4, B5>(x, s));
    }
    hits
}

#[inline(never)]
fn v1<const B: u32, const B4: u32>(n: &[u128], seed16: &[u64]) -> u64 {
    let mut hits = 0;
    for (&x, &s) in n.iter().zip(seed16) {
        hits += u64::from(check_v1::<B, B4>(x, s));
    }
    hits
}

/// n's base-b² limbs from P = ⌊n/b³⌋ (< 2^64) and r0 = n mod b³: lo = r0 +
/// (P mod b⁷)·b³ < b^10, hi = ⌊P/b⁷⌋.
#[inline(always)]
fn limbs<const B: u64, const NL: usize>(p: u64, r0: u64) -> [u64; NL] {
    let b2 = B * B;
    let b3 = b2 * B;
    let b7 = b3 * b3 * B;
    let mut lo = r0 + (p % b7) * b3;
    let mut hi = p / b7;
    let mut x = [0u64; NL];
    for (i, l) in x.iter_mut().enumerate() {
        if i < 5 {
            *l = lo % b2;
            lo /= b2;
        } else {
            *l = hi % b2;
            hi /= b2;
        }
    }
    x
}

/// n² digits from position 8 up to position `top` (n² has `top + 1`
/// digits) by base-b² columns; `None` at the first repeat.
#[inline(always)]
fn sq_cols<const B: u64, const NL: usize>(x: &[u64; NL], seen: u64, top: u32) -> Option<u64> {
    sq_cols_c::<B, NL, false>(x, seen, top, &mut 0)
}

#[inline(always)]
fn sq_cols_c<const B: u64, const NL: usize, const C: bool>(x: &[u64; NL], mut seen: u64, top: u32, cnt: &mut u32) -> Option<u64> {
    let b2 = B * B;
    let mut carry = 0u64;
    let mut pos = 0u32;
    for j in 0..2 * NL - 1 {
        let lo = j.saturating_sub(NL - 1);
        let hi = j.min(NL - 1);
        let mut c = carry;
        for i in lo..=hi {
            c += x[i] * x[j - i];
        }
        carry = c / b2;
        let limb = c % b2;
        if j >= 4 {
            let (d0, d1) = (limb % B, limb / B);
            if C {
                *cnt += 1;
            }
            let bit0 = 1u64 << d0;
            if seen & bit0 != 0 {
                return None;
            }
            seen |= bit0;
            if pos + 1 > top {
                return Some(seen);
            }
            if C {
                *cnt += 1;
            }
            let bit1 = 1u64 << d1;
            if seen & bit1 != 0 {
                return None;
            }
            seen |= bit1;
            if pos + 1 == top {
                return Some(seen);
            }
        }
        pos += 2;
    }
    // The last carry's digits (positions 2(2NL − 1) and up).
    while pos <= top {
        let d = carry % B;
        carry /= B;
        if C {
            *cnt += 1;
        }
        let bit = 1u64 << d;
        if seen & bit != 0 {
            return None;
        }
        seen |= bit;
        pos += 1;
    }
    Some(seen)
}

#[inline(never)]
fn v2<const B: u32, const B4: u32, const BU: u64, const NL: usize>(
    n: &[u128],
    pr: &[(u64, u64)],
    seed16: &[u64],
    thr2: u128,
    s2lo: u32,
) -> u64 {
    let mut hits = 0;
    for ((&x, &(p, r0)), &s) in n.iter().zip(pr).zip(seed16) {
        // n² has s2lo digits below thr2, one more from it.
        let top = s2lo - 1 + u32::from(x >= thr2);
        let xl = limbs::<BU, NL>(p, r0);
        let Some(seen) = sq_cols::<BU, NL>(&xl, s, top) else {
            continue;
        };
        let cu = U256::mul_u128_u128(x, x).mul_u128_truncating(x);
        hits += u64::from(scan_from::<B, B4>(cu, seen).is_some());
    }
    hits
}

fn isqrt_ceil_pow(b: u128, e: u32) -> u128 {
    // smallest n with n² >= b^e (b^e < 2^256: use f64 then fix in U256).
    let target = digits_pow(b, e);
    let mut n = (b as f64).powf(e as f64 / 2.0) as u128;
    n = n.saturating_sub(4);
    while cmp_u256(&U256::mul_u128_u128(n, n), &target) == std::cmp::Ordering::Less {
        n += 1;
    }
    n
}
fn digits_pow(b: u128, e: u32) -> U256 {
    let mut x = U256::from_u128(1);
    for _ in 0..e {
        x = x.mul_u128_truncating(b);
    }
    x
}
fn cmp_u256(a: &U256, b: &U256) -> std::cmp::Ordering {
    for i in (0..4).rev() {
        match a.limbs[i].cmp(&b.limbs[i]) {
            std::cmp::Ordering::Equal => {}
            o => return o,
        }
    }
    std::cmp::Ordering::Equal
}

fn run<const B: u32, const B4: u32, const B5: u32, const BU: u64, const NL: usize>(n: &[u128], reps: usize) {
    let b = B;
    let b3 = u128::from(b).pow(3);
    // Untimed: the masks the join knows, P and r0, the digit-count threshold.
    let mut seed3 = Vec::with_capacity(n.len());
    let mut seed16 = Vec::with_capacity(n.len());
    let mut pr = Vec::with_capacity(n.len());
    let mut sq_digits = 0u64;
    let mut v0_digits = 0u64;
    let mut bad16 = 0u64;
    let l = {
        let mut l = 0;
        let mut x = n[0];
        while x > 0 {
            x /= u128::from(b);
            l += 1;
        }
        l
    };
    let s2lo = 2 * l - 1;
    let thr2 = isqrt_ceil_pow(u128::from(b), 2 * l - 1);
    let mut n2_pass = 0u64;
    let mut full_runs = 0u64;
    let (mut v0_conv, mut v1_conv) = (0u64, 0u64);
    for &x in n {
        let sq = U256::mul_u128_u128(x, x);
        let cu = sq.mul_u128_truncating(x);
        let d2 = digits_u256(sq, b);
        let d3 = digits_u256(cu, b);
        let m = |d: &[u32], k: usize| d[..k].iter().fold(0u64, |a, &g| a | (1 << g));
        seed3.push(m(&d2, 3) | m(&d3, 3));
        let s16 = m(&d2, 8) | m(&d3, 8);
        bad16 += u64::from(s16.count_ones() != 16);
        seed16.push(s16);
        pr.push(((x / b3) as u64, (x % b3) as u64));
        sq_digits += d2.len() as u64;
        assert_eq!(d2.len() as u32, s2lo + u32::from(x >= thr2), "digit count");
        // Conversions today (positions 3.. of n² until a repeat, then n³ from 3)
        let mut seen = seed3[seed3.len() - 1];
        let mut ok = true;
        for &g in &d2[3..] {
            v0_conv += 1;
            if seen & (1 << g) != 0 {
                ok = false;
                break;
            }
            seen |= 1 << g;
        }
        if ok {
            for &g in &d3[3..] {
                v0_conv += 1;
                if seen & (1 << g) != 0 {
                    break;
                }
                seen |= 1 << g;
            }
        }
        let before = v1_conv;
        let mut seen = s16;
        let mut ok = true;
        for &g in &d2[8..] {
            v1_conv += 1;
            if seen & (1 << g) != 0 {
                ok = false;
                break;
            }
            seen |= 1 << g;
        }
        if ok {
            n2_pass += 1;
            for &g in &d3[8..] {
                v1_conv += 1;
                if seen & (1 << g) != 0 {
                    break;
                }
                seen |= 1 << g;
            }
        }
        let want = (v1_conv - before) as u32;
        let xl0 = limbs::<BU, NL>((x / b3) as u64, (x % b3) as u64);
        let top0 = s2lo - 1 + u32::from(x >= thr2);
        let (mut c1, mut c2, mut c3) = (0u32, 0u32, 0u32);
        let sq0 = U256::mul_u128_u128(x, x);
        let cu0 = sq0.mul_u128_truncating(x);
        let r1 = scan_from_c::<B, B4, true>(sq0, s16, &mut c1).and_then(|m| scan_from_c::<B, B4, true>(cu0, m, &mut c1));
        let r2 = sq_cols_c::<BU, NL, true>(&xl0, s16, top0, &mut c2).and_then(|m| scan_from_c::<B, B4, true>(cu0, m, &mut c2));
        let r3 = scan5_c::<B, B4, B5, true>(sq0, s16, &mut c3).and_then(|m| scan5_c::<B, B4, B5, true>(cu0, m, &mut c3));
        assert_eq!((c1, c2, c3), (want, want, want), "digits tested before the verdict, n = {x}");
        assert!(r1.is_none() == r2.is_none() && r1.is_none() == r3.is_none());
        // The same with nothing seeded (long runs: the tops of n² and n³).
        let mut want0 = 0u32;
        let mut seen0 = 0u64;
        'outer: for d in [&d2[8..], &d3[8..]] {
            for &g in d {
                want0 += 1;
                if seen0 & (1 << g) != 0 {
                    break 'outer;
                }
                seen0 |= 1 << g;
            }
        }
        let (mut e1, mut e2, mut e3) = (0u32, 0u32, 0u32);
        let q1 = scan_from_c::<B, B4, true>(sq0, 0, &mut e1).and_then(|m| scan_from_c::<B, B4, true>(cu0, m, &mut e1));
        let q2 = sq_cols_c::<BU, NL, true>(&xl0, 0, top0, &mut e2).and_then(|m| scan_from_c::<B, B4, true>(cu0, m, &mut e2));
        let q3 = scan5_c::<B, B4, B5, true>(sq0, 0, &mut e3).and_then(|m| scan5_c::<B, B4, B5, true>(cu0, m, &mut e3));
        assert_eq!((e1, e2, e3), (want0, want0, want0), "unseeded digits tested, n = {x}");
        assert!(q1 == q2 && q1 == q3);
        if q1.is_some() {
            full_runs += 1;
        }
        // Exactness of V2's n² digits: every digit from position 8 against
        // the division's, on this n (seen empty, no exit: compare digits).
        let xl = limbs::<BU, NL>((x / b3) as u64, (x % b3) as u64);
        let mut c = 0u64;
        let mut got = Vec::new();
        for j in 0..2 * NL - 1 {
            let lo = j.saturating_sub(NL - 1);
            let hi = j.min(NL - 1);
            for i in lo..=hi {
                c += xl[i] * xl[j - i];
            }
            let limb = c % (BU * BU);
            c /= BU * BU;
            got.push((limb % BU) as u32);
            got.push((limb / BU) as u32);
        }
        while c > 0 {
            got.push((c % BU) as u32);
            c /= BU;
        }
        while got.last() == Some(&0) {
            got.pop();
        }
        assert_eq!(got, d2, "V2 digits of n² for n = {x}");
    }
    let _ = v0_digits;
    println!("unseeded scans from position 8 reaching the top of n³: {full_runs}");
    println!(
        "b{b} L {l}: {} checks; n² digits avg {:.2}; 16 known digits distinct in all but {bad16}; n² passes (16-seeded) {n2_pass} ({:.3} %); digit conversions per check: today {:.2}, from position 8 {:.2}; V2 digits = division digits on every n; V1/V2/V3 test exactly the reference's digits before their verdict on every n",
        n.len(),
        sq_digits as f64 / n.len() as f64,
        100.0 * n2_pass as f64 / n.len() as f64,
        v0_conv as f64 / n.len() as f64,
        v1_conv as f64 / n.len() as f64,
    );
    for r in 0..reps {
        let t = Instant::now();
        let h0 = v0::<B>(n, &seed3);
        let t0 = t.elapsed().as_secs_f64();
        let t = Instant::now();
        let h1 = v1::<B, B4>(n, &seed16);
        let t1 = t.elapsed().as_secs_f64();
        let t = Instant::now();
        let h2 = v2::<B, B4, BU, NL>(n, &pr, &seed16, thr2, s2lo);
        let t2 = t.elapsed().as_secs_f64();
        let t = Instant::now();
        let h3 = v3::<B, B4, B5>(n, &seed16);
        let t3 = t.elapsed().as_secs_f64();
        let ns = |t: f64| t * 1e9 / n.len() as f64;
        println!(
            "rep {r}: V0 {:.1} ns/check, V1 {:.1} (×{:.2}), V2 {:.1} (×{:.2}), V3 {:.1} (×{:.2}); hits {h0} {h1} {h2} {h3}",
            ns(t0),
            ns(t1),
            t0 / t1,
            ns(t2),
            t0 / t2,
            ns(t3),
            t0 / t3
        );
        assert_eq!((h0, h1, h3), (h2, h2, h2));
    }
    // Verdict agreement per n.
    let mut diff = 0;
    for (i, &x) in n.iter().enumerate() {
        let a = get_is_nice_with_known_lsd(x, B, 3, seed3[i]);
        let c = check_v1::<B, B4>(x, seed16[i]);
        let c3 = check_v3::<B, B4, B5>(x, seed16[i]);
        diff += u64::from(a != c) + u64::from(a != c3);
    }
    println!("verdicts V0 vs V1 / V3 differ on {diff}");
}

fn main() {
    let a: Vec<String> = std::env::args().collect();
    let base: u32 = a[1].parse().unwrap();
    let bytes = std::fs::read(&a[2]).unwrap();
    let reps: usize = a.get(3).map_or(3, |s| s.parse().unwrap());
    let n: Vec<u128> = bytes
        .chunks_exact(16)
        .map(|c| u128::from_le_bytes(c.try_into().unwrap()))
        .collect();
    match base {
        60 => run::<60, { 60 * 60 * 60 * 60 }, { 60 * 60 * 60 * 60 * 60 }, 60, 6>(&n, reps),
        62 => run::<62, { 62 * 62 * 62 * 62 }, { 62 * 62 * 62 * 62 * 62 }, 62, 7>(&n, reps),
        _ => panic!("base"),
    }
}
