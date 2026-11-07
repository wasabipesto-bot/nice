#!/usr/bin/env python3
"""L48 patch 1: NICE_EXP_TOPFD levels 1-3 in top_fd_kernel (cubecl_join.rs) and level 4 in join_plan.rs."""
import sys, re
root = sys.argv[1]
fn = f'{root}/common/src/cubecl_join.rs'
s = open(fn).read()

def rep(old, new, count=1):
    global s
    n = s.count(old)
    if n != count:
        sys.exit(f'anchor found {n} times (want {count}):\n{old[:300]}')
    s = s.replace(old, new)

# --- constants -------------------------------------------------------------
rep('''/// FD at power-of-two bases too: no, `top_kernel`'s division is shifts there and FD measured slower.
const TOP_FD_AT_POW2_BASES: bool = false;
''', '''/// FD at power-of-two bases too: no, `top_kernel`'s division is shifts there and FD measured slower.
const TOP_FD_AT_POW2_BASES: bool = false;
/// Experiment (L48): `NICE_EXP_TOPFD`, cumulative levels of [`top_fd_kernel`]
/// (0 is #240's kernel): 1 carries c0 and b^c0 - 1 - d across stepped slots,
/// takes scanned words wholly above c0 by a short path, and lets stepping
/// slots skip a, e and the clip test; 2 appends with a plane ballot; 3 leaves
/// the words of x ending four or more digits below c0 out of x mod b^c0
/// unless the carry test needs them; 4 plans one expected survivor per
/// prefix and partition (`join_plan`). 103 is level 3 with the left-out
/// words always added back (tests the fallback).
pub(crate) fn exp_topfd_level() -> u32 {
    static L: std::sync::OnceLock<u32> = std::sync::OnceLock::new();
    *L.get_or_init(|| {
        std::env::var("NICE_EXP_TOPFD")
            .ok()
            .and_then(|v| v.parse::<u32>().ok())
            .filter(|&l| l <= 4 || l == 103)
            .unwrap_or(0)
    })
}
''')

# --- helpers after add_words --------------------------------------------------
rep('''    /// The binary differences' constants for blocks of width w (δ = w - 1):''', '''    /// `x -= y` over `nx` u32 words (`y` has `ny` <= `nx`); returns the borrow
    /// out of the top word (x + !y + 1, as `add_words` adds).
    #[cube]
    fn sub_words_b(
        x: &mut Array<u32>,
        y: &Array<u32>,
        #[comptime] ny: u32,
        #[comptime] nx: u32,
    ) -> u32 {
        let mut c = 1u64;
        #[unroll]
        for j in 0..nx {
            if comptime!(j < ny) {
                c += u64::cast_from(x[j as usize]) + u64::cast_from(y[j as usize] ^ 0xFFFF_FFFFu32);
            } else {
                c += u64::cast_from(x[j as usize]) + 0xFFFF_FFFFu64;
            }
            x[j as usize] = u32::cast_from(c);
            c >>= 32u64;
        }
        1u32 - u32::cast_from(c)
    }

    /// `out = b^c0 - 1 - x` over `nl` words (mod 2^(32·nl)), b^c0 from the
    /// power table `pw` (`nl3` words a power): its own inverse.
    #[cube]
    fn pw_minus1(
        pw: &Array<u32>,
        c0: u32,
        x: &Array<u32>,
        out: &mut Array<u32>,
        #[comptime] nl: u32,
        #[comptime] nl3: u32,
    ) {
        let mut c = 0u64;
        #[unroll]
        for j in 0..nl {
            c += u64::cast_from(pw[(c0 * nl3 + j) as usize])
                + u64::cast_from(x[j as usize] ^ 0xFFFF_FFFFu32);
            out[j as usize] = u32::cast_from(c);
            c >>= 32u64;
        }
    }

    /// Whether `x` (`nl` words) is below b^p.
    #[cube]
    fn words_lt_pow(
        x: &Array<u32>,
        #[comptime] nl: u32,
        #[comptime] base: u32,
        #[comptime] p: u32,
    ) -> bool {
        let lp = comptime!((pow_words32(base, p).len() as u32).min(nl));
        let mut hi = 0u32;
        #[unroll]
        for j in lp..nl {
            hi |= x[j as usize];
        }
        let mut lt = false;
        let mut eq = true;
        #[unroll]
        for jj in 0..lp {
            let j = comptime!(lp - 1 - jj);
            let xj = x[j as usize];
            let cj = comptime!(pow_words32(base, p)[j as usize]);
            lt = lt || (eq && xj < cj);
            eq = eq && xj == cj;
        }
        hi == 0u32 && lt
    }

    /// The base-b value of a word's four packed digits.
    #[cube]
    fn word_value(word: u32, #[comptime] base: u32) -> u32 {
        (word & 0xFFu32)
            + comptime!(base)
                * (((word >> 8u32) & 0xFFu32)
                    + comptime!(base)
                        * (((word >> 16u32) & 0xFFu32) + comptime!(base) * (word >> 24u32)))
    }

    /// `acc += v · b^p0` over `nl` words, for a sum below b^(p0 + 4).
    #[cube]
    fn add_scaled_pow(
        acc: &mut Array<u32>,
        v: u32,
        #[comptime] nl: u32,
        #[comptime] base: u32,
        #[comptime] p0: u32,
    ) {
        let len = comptime!((pow_words32(base, p0).len() as u32).min(nl));
        let topk = comptime!((pow_words32(base, p0 + 4).len() as u32).min(nl));
        let mut c = 0u64;
        #[unroll]
        for k in 0..len {
            let t = u64::cast_from(v) * comptime!(u64::from(pow_words32(base, p0)[k as usize]))
                + u64::cast_from(acc[k as usize])
                + c;
            acc[k as usize] = u32::cast_from(t);
            c = t >> 32u64;
        }
        #[unroll]
        for k in len..topk {
            let t = u64::cast_from(acc[k as usize]) + c;
            acc[k as usize] = u32::cast_from(t);
            c = t >> 32u64;
        }
    }

    /// The binary differences' constants for blocks of width w (δ = w - 1):''')

# --- cert_power_fd ----------------------------------------------------------
rep('''        #[comptime] sp: u32,
        #[comptime] base: u32,
        #[comptime] z: u32,
    ) -> u64 {
        let mut rem = Array::<u32>::new(nl as usize);''', '''        #[comptime] sp: u32,
        #[comptime] base: u32,
        #[comptime] z: u32,
        #[comptime] lvl: u32,
    ) -> u64 {
        let mut rem = Array::<u32>::new(nl as usize);''')

old_loop = '''            let word = q[j as usize];
            let mut low = 0u32;
            if c0 >= wend {
                // Every digit of the word below c0 (those at sp and up are 0).
                low = (word & 0xFFu32)
                    + comptime!(base)
                        * (((word >> 8u32) & 0xFFu32)
                            + comptime!(base)
                                * (((word >> 16u32) & 0xFFu32)
                                    + comptime!(base) * (word >> 24u32)));
            } else {
                #[unroll]
                for i in 0..4u32 {
                    let pos = comptime!(p0 + i);
                    if comptime!(pos < sp) {
                        let dx = (word >> comptime!(8 * i)) & 0xFFu32;
                        let above = c0 <= pos;
                        let bit = select(above, 1u64 << u64::cast_from(dx), 0u64);
                        run |= bit;
                        runc |= select(in_run, 0u64, bit);
                        let ends = above && in_run && dx != comptime!(base - 1);
                        dlo = select(ends, dx, dlo);
                        qend = select(ends, pos.runtime(), qend);
                        in_run = in_run && !ends;
                        low += select(above, 0u32, dx * comptime!(base.pow(i)));
                    }
                }
            }
            // rem += low · b^p0 (the sum is below b^(p0 + 4)).
            if p0 < c0 {
                let len = comptime!((pow_words32(base, p0).len() as u32).min(nl));
                let topk = comptime!((pow_words32(base, p0 + 4).len() as u32).min(nl));
                let mut c = 0u64;
                #[unroll]
                for k in 0..len {
                    let t = u64::cast_from(low)
                        * comptime!(u64::from(pow_words32(base, p0)[k as usize]))
                        + u64::cast_from(rem[k as usize])
                        + c;
                    rem[k as usize] = u32::cast_from(t);
                    c = t >> 32u64;
                }
                #[unroll]
                for k in len..topk {
                    let t = u64::cast_from(rem[k as usize]) + c;
                    rem[k as usize] = u32::cast_from(t);
                    c = t >> 32u64;
                }
            }
        }'''
new_loop = '''            let word = q[j as usize];
            let mut low = 0u32;
            // Level 3: a word ending four or more digits below c0 is left
            // out of x mod b^c0 here; the carry test adds it back when it
            // can decide the test.
            let mut take = true;
            if comptime!(lvl >= 3) {
                take = c0 < comptime!(wend + 4);
            }
            if c0 >= wend {
                // Every digit of the word below c0 (those at sp and up are 0).
                if take {
                    low = word_value(word, base);
                }
            } else {
                // Level 1: once x's run of (b - 1)s from c0 up has ended (in
                // a lower word, or before the scan when c0 < z), every digit
                // here lies above c0: only its bit is set.
                let mut slow = true;
                if comptime!(lvl >= 1) {
                    slow = in_run;
                }
                if slow {
                    #[unroll]
                    for i in 0..4u32 {
                        let pos = comptime!(p0 + i);
                        if comptime!(pos < sp) {
                            let dx = (word >> comptime!(8 * i)) & 0xFFu32;
                            let above = c0 <= pos;
                            let bit = select(above, 1u64 << u64::cast_from(dx), 0u64);
                            run |= bit;
                            runc |= select(in_run, 0u64, bit);
                            let ends = above && in_run && dx != comptime!(base - 1);
                            dlo = select(ends, dx, dlo);
                            qend = select(ends, pos.runtime(), qend);
                            in_run = in_run && !ends;
                            low += select(above, 0u32, dx * comptime!(base.pow(i)));
                        }
                    }
                } else {
                    let mut wb = 0u64;
                    #[unroll]
                    for i in 0..4u32 {
                        let pos = comptime!(p0 + i);
                        if comptime!(pos < sp) {
                            let dx = (word >> comptime!(8 * i)) & 0xFFu32;
                            wb |= 1u64 << u64::cast_from(dx);
                        }
                    }
                    run |= wb;
                    runc |= wb;
                }
            }
            // rem += low · b^p0 (the sum is below b^(p0 + 4)).
            if p0 < c0 && take {
                add_scaled_pow(&mut rem, low, nl, base, p0);
            }
        }'''
rep(old_loop, new_loop)

old_carry = '''        let dupc = select(pruc != nc, 1u32, 0u32);
        let mut one_more = false;
        if c0 < sp {
            let mut s = Array::<u32>::new(nl as usize);'''
new_carry = '''        let dupc = select(pruc != nc, 1u32, 0u32);
        let mut one_more = false;
        if comptime!(lvl >= 1) {
            if c0 < sp {
                // `d` holds b^c0 - 1 - (y - x): one more iff x mod b^c0 > it.
                // dd = d - rem, with a borrow iff rem > d.
                let mut dd = Array::<u32>::new(nl as usize);
                let mut c = 1u64;
                #[unroll]
                for j in 0..nl {
                    c += u64::cast_from(d[j as usize]) + u64::cast_from(rem[j as usize] ^ 0xFFFF_FFFFu32);
                    dd[j as usize] = u32::cast_from(c);
                    c >>= 32u64;
                }
                one_more = c == 0u64;
                if comptime!(lvl >= 3) {
                    // Level 3: the left-out words (those ending at or below
                    // c0 - 4) add L < b^p, p the first kept word's position;
                    // one more iff L > dd. Only if dd < b^p can they matter:
                    // then add them and test again.
                    if !one_more && c0 >= comptime!(z + 8) {
                        let mut amb = false;
                        if comptime!(lvl >= 100) {
                            amb = true;
                        }
                        #[unroll]
                        for jj in 1..nw {
                            let p = comptime!(z + 4 * jj);
                            if comptime!(p + 4 < sp) {
                                if c0 >= comptime!(p + 4) && c0 < comptime!(p + 8) {
                                    amb = amb || words_lt_pow(&dd, nl, base, p);
                                }
                            }
                        }
                        if amb {
                            let mut lo = Array::<u32>::new(nl as usize);
                            #[unroll]
                            for j in 0..nl {
                                lo[j as usize] = 0u32;
                            }
                            #[unroll]
                            for j in 0..nw {
                                let p0 = comptime!(z + 4 * j);
                                let wend = comptime!(if p0 + 4 < sp { p0 + 4 } else { sp });
                                if c0 >= comptime!(wend + 4) {
                                    add_scaled_pow(&mut lo, word_value(q[j as usize], base), nl, base, p0);
                                }
                            }
                            let mut ca = 0u64;
                            let mut cb = 1u64;
                            #[unroll]
                            for j in 0..nl {
                                ca += u64::cast_from(rem[j as usize]) + u64::cast_from(lo[j as usize]);
                                let rj = u32::cast_from(ca);
                                ca >>= 32u64;
                                cb += u64::cast_from(d[j as usize]) + u64::cast_from(rj ^ 0xFFFF_FFFFu32);
                                cb >>= 32u64;
                            }
                            one_more = cb == 0u64;
                        }
                    }
                }
            }
        } else if c0 < sp {
            let mut s = Array::<u32>::new(nl as usize);'''
rep(old_carry, new_carry)

# --- top_cert_fd: pass lvl -----------------------------------------------------
rep('''        #[comptime] s3: u32,
        #[comptime] f0: u32,
    ) -> u64 {
        let nl2 = comptime!(2 * limbs);
        let nl3 = comptime!(3 * limbs);
        let mut dupa = Array::<u32>::new(1usize);''', '''        #[comptime] s3: u32,
        #[comptime] f0: u32,
        #[comptime] lvl: u32,
    ) -> u64 {
        let nl2 = comptime!(2 * limbs);
        let nl3 = comptime!(3 * limbs);
        let mut dupa = Array::<u32>::new(1usize);''')
rep('''            s2,
            base,
            comptime!(2 * f0),
        );''', '''            s2,
            base,
            comptime!(2 * f0),
            lvl,
        );''')
rep('''            s3,
            base,
            comptime!(3 * f0),
        );''', '''            s3,
            base,
            comptime!(3 * f0),
            lvl,
        );''')

# --- top_fd_kernel -------------------------------------------------------------
rep('''        #[comptime] nb: u32,
        #[comptime] f0: u32,
        #[comptime] tq: u32,
    ) {
        let m1 = comptime!(base - 1);''', '''        #[comptime] nb: u32,
        #[comptime] f0: u32,
        #[comptime] tq: u32,
        #[comptime] lvl: u32,
    ) {
        let m1 = comptime!(base - 1);''')

rep('''            let mut valid = false;
            let mut prev_v = 0u32;
            // This cube's group of slots''', '''            let mut valid = false;
            let mut prev_v = 0u32;
            // Level 1: c0 of each power and e = b^c0 - 1 - d, carried from
            // slot to slot (d itself is then only formed by a seed).
            let lc0 = comptime!(lvl >= 1);
            let nd2 = comptime!(if lvl >= 1 { nl2 } else { 1 });
            let nd3 = comptime!(if lvl >= 1 { nl3 } else { 1 });
            let mut lc0a = 0u32;
            let mut lc0b = 0u32;
            let mut dp2 = Array::<u32>::new(nd2 as usize);
            let mut dp3 = Array::<u32>::new(nd3 as usize);
            #[unroll]
            for j in 0..nd2 {
                dp2[j as usize] = 0u32;
            }
            #[unroll]
            for j in 0..nd3 {
                dp3[j as usize] = 0u32;
            }
            // This cube's group of slots''')

old_ae = '''                if live && p >= plo && p <= phi {
                    // a = p*w (< 2^96, 3 limbs), e = a + w - 1, clipped to [s, e-1].
                    let t0 = (p & 0xFFFF_FFFFu64) * u64::cast_from(w);
                    let t1 = (p >> 32u64) * u64::cast_from(w) + (t0 >> 32u64);
                    let pw0 = u32::cast_from(t0);
                    let mut a = Array::<u32>::new(limbs as usize);
                    let mut e = Array::<u32>::new(limbs as usize);
                    #[unroll]'''
new_ae = '''                if live && p >= plo && p <= phi {
                    let mut a = Array::<u32>::new(limbs as usize);
                    let mut e = Array::<u32>::new(limbs as usize);
                    let mut a_lt_s = false;
                    let mut e_gt_e = false;
                    // Level 1: only P = plo and P = phi can be clipped, and a
                    // stepping slot needs neither a nor e (they feed a seed).
                    let mut easy = false;
                    if comptime!(lvl >= 1) {
                        easy = valid && v == prev_v + 1u32 && p != plo && p != phi;
                    }
                    if !easy {
                    // a = p*w (< 2^96, 3 limbs), e = a + w - 1, clipped to [s, e-1].
                    let t0 = (p & 0xFFFF_FFFFu64) * u64::cast_from(w);
                    let t1 = (p >> 32u64) * u64::cast_from(w) + (t0 >> 32u64);
                    let pw0 = u32::cast_from(t0);
                    #[unroll]'''
rep(old_ae, new_ae)

rep('''                        e[j as usize] = t;
                        carry = c;
                    }
                    let mut a_lt_s = false;
                    let mut e_gt_e = false;
                    let mut eq_a = true;''', '''                        e[j as usize] = t;
                        carry = c;
                    }
                    let mut eq_a = true;''')

rep('''                            e[j as usize] = fb[comptime!(3 + j) as usize];
                        }
                    }
                    // Clipped blocks (P = plo, P = phi) are `top_kernel`'s''', '''                            e[j as usize] = fb[comptime!(3 + j) as usize];
                        }
                    }
                    }
                    // Clipped blocks (P = plo, P = phi) are `top_kernel`'s''')

old_step = '''                        if step {
                            top_fd_step(
                                &mut sq, &mut cu, &mut ds, &mut dc, &mut ddc, base, tq, q2, q3,
                            );
                            add_words(&mut d2, &c2, comptime!(if nl2 < 3 { nl2 } else { 3 }), nl2);
                            add_words(&mut d3, &del3, nl3, nl3);
                            add_words(
                                &mut del3,
                                &k3,
                                comptime!(if nl3 < 4 { nl3 } else { 4 }),
                                nl3,
                            );
                        } else {'''
new_step = '''                        if step {
                            top_fd_step(
                                &mut sq, &mut cu, &mut ds, &mut dc, &mut ddc, base, tq, q2, q3,
                            );
                            if comptime!(lc0) {
                                // e -= the step of d. A borrow means d reached
                                // b^c0 (rare): d = b^c0 - 1 - e, and c0 and e
                                // are formed again.
                                let br2 = sub_words_b(
                                    &mut dp2,
                                    &c2,
                                    comptime!(if nl2 < 3 { nl2 } else { 3 }),
                                    nl2,
                                );
                                let br3 = sub_words_b(&mut dp3, &del3, nl3, nl3);
                                add_words(
                                    &mut del3,
                                    &k3,
                                    comptime!(if nl3 < 4 { nl3 } else { 4 }),
                                    nl3,
                                );
                                if lc0a < s2 && br2 != 0u32 {
                                    let mut dd = Array::<u32>::new(nl2 as usize);
                                    pw_minus1(pw, lc0a, &dp2, &mut dd, nl2, nl3);
                                    let mut nc = ndig_fast(&dd, pw, nl2, nl3, s2, base);
                                    if nc < cap {
                                        nc = cap.runtime();
                                    }
                                    lc0a = nc;
                                    pw_minus1(pw, lc0a, &dd, &mut dp2, nl2, nl3);
                                }
                                if lc0b < s3 && br3 != 0u32 {
                                    let mut dd = Array::<u32>::new(nl3 as usize);
                                    pw_minus1(pw, lc0b, &dp3, &mut dd, nl3, nl3);
                                    let mut nc = ndig_fast(&dd, pw, nl3, nl3, s3, base);
                                    if nc < cap {
                                        nc = cap.runtime();
                                    }
                                    lc0b = nc;
                                    pw_minus1(pw, lc0b, &dd, &mut dp3, nl3, nl3);
                                }
                            } else {
                                add_words(
                                    &mut d2,
                                    &c2,
                                    comptime!(if nl2 < 3 { nl2 } else { 3 }),
                                    nl2,
                                );
                                add_words(&mut d3, &del3, nl3, nl3);
                                add_words(
                                    &mut del3,
                                    &k3,
                                    comptime!(if nl3 < 4 { nl3 } else { 4 }),
                                    nl3,
                                );
                            }
                        } else {'''
rep(old_step, new_step)

old_c0 = '''                                chunk_digits,
                                chunk_div,
                            );
                        }
                        let mut c0a = ndig_fast(&d2, pw, nl2, nl3, s2, base);
                        if c0a < cap {
                            c0a = cap.runtime();
                        }
                        let mut c0b = ndig_fast(&d3, pw, nl3, nl3, s3, base);
                        if c0b < cap {
                            c0b = cap.runtime();
                        }
                        mask = top_cert_fd(
                            &sq, &cu, &d2, &d3, c0a, c0b, pw, &mut res, base, limbs, s2, s3, f0,
                        );
                    }'''
new_c0 = '''                                chunk_digits,
                                chunk_div,
                            );
                            if comptime!(lc0) {
                                let mut n2 = ndig_fast(&d2, pw, nl2, nl3, s2, base);
                                if n2 < cap {
                                    n2 = cap.runtime();
                                }
                                lc0a = n2;
                                let mut n3 = ndig_fast(&d3, pw, nl3, nl3, s3, base);
                                if n3 < cap {
                                    n3 = cap.runtime();
                                }
                                lc0b = n3;
                                pw_minus1(pw, lc0a, &d2, &mut dp2, nl2, nl3);
                                pw_minus1(pw, lc0b, &d3, &mut dp3, nl3, nl3);
                            }
                        }
                        if comptime!(lc0) {
                            mask = top_cert_fd(
                                &sq, &cu, &dp2, &dp3, lc0a, lc0b, pw, &mut res, base, limbs, s2,
                                s3, f0, lvl,
                            );
                        } else {
                            let mut c0a = ndig_fast(&d2, pw, nl2, nl3, s2, base);
                            if c0a < cap {
                                c0a = cap.runtime();
                            }
                            let mut c0b = ndig_fast(&d3, pw, nl3, nl3, s3, base);
                            if c0b < cap {
                                c0b = cap.runtime();
                            }
                            mask = top_cert_fd(
                                &sq, &cu, &d2, &d3, c0a, c0b, pw, &mut res, base, limbs, s2, s3,
                                f0, lvl,
                            );
                        }
                    }'''
rep(old_c0, new_c0)

old_app = '''                let kc = select(kept, 1u32, 0u32);
                let n = plane_sum(kc);
                let pre = plane_exclusive_sum(kc);
                let mut at = 0u32;'''
new_app = '''                let mut n = 0u32;
                let mut pre = 0u32;
                if comptime!(lvl >= 2) {
                    // Level 2: one ballot; the plane's count and this lane's
                    // rank are popcounts (up to 128 lanes a plane).
                    let bal = plane_ballot(kept);
                    let lane = UNIT_POS_PLANE;
                    let wi = lane >> 5u32;
                    let lt = (1u32 << (lane & 31u32)) - 1u32;
                    #[unroll]
                    for k in 0..4u32 {
                        let bk = bal[k as usize];
                        n += bk.count_ones();
                        let mk = select(k < wi, 0xFFFF_FFFFu32, select(k == wi, lt, 0u32));
                        pre += (bk & mk).count_ones();
                    }
                } else {
                    let kc = select(kept, 1u32, 0u32);
                    n = plane_sum(kc);
                    pre = plane_exclusive_sum(kc);
                }
                let mut at = 0u32;'''
rep(old_app, new_app)

# --- host: field, launch arg ----------------------------------------------------
rep('''    /// [`TOP_FD_MIN_UNITS`] (the tests lower it to force slot groups).
    top_fd_min: u32,
''', '''    /// [`TOP_FD_MIN_UNITS`] (the tests lower it to force slot groups).
    top_fd_min: u32,
    /// `NICE_EXP_TOPFD` (experiment; see [`exp_topfd_level`]), as the kernel takes it.
    top_fd_lvl: u32,
''')
rep('''            top_fd_min: TOP_FD_MIN_UNITS,
''', '''            top_fd_min: TOP_FD_MIN_UNITS,
            top_fd_lvl: match exp_topfd_level() {
                103 => 103,
                l => l.min(3),
            },
''')
rep('''                    self.nb,
                    self.f0,
                    self.tq,
                );''', '''                    self.nb,
                    self.f0,
                    self.tq,
                    self.top_fd_lvl,
                );''')
open(fn, 'w').write(s)

# --- join_plan.rs: level 4 ----------------------------------------------------
fn2 = f'{root}/common/src/join_plan.rs'
t = open(fn2).read()
def rep2(old, new, count=1):
    global t
    n = t.count(old)
    if n != count:
        sys.exit(f'join_plan anchor found {n} times (want {count}):\n{old[:300]}')
    t = t.replace(old, new)
rep2('''const SURV_PER_PREFIX: usize = 2;
''', '''const SURV_PER_PREFIX: usize = 2;
/// Experiment (L48): [`SURV_PER_PREFIX`], or 1 at `NICE_EXP_TOPFD=4`.
fn surv_per_prefix() -> usize {
    if crate::cubecl_join::exp_topfd_level() == 4 {
        1
    } else {
        SURV_PER_PREFIX
    }
}
''')
rep2('''(list_cap as usize / 2 / (SURV_PER_PREFIX * fs.tlay.len().max(1))).max(1);''', '''(list_cap as usize / 2 / (surv_per_prefix() * fs.tlay.len().max(1))).max(1);''')
rep2('''    let by_survivors = list_cap / 2 / (s * SURV_PER_PREFIX);''', '''    let by_survivors = list_cap / 2 / (s * surv_per_prefix());''')
rep2('''                plan.slots * ntl * SURV_PER_PREFIX
                    <= plan.list_cap as usize / 2 + ntl * SURV_PER_PREFIX''', '''                plan.slots * ntl * surv_per_prefix()
                    <= plan.list_cap as usize / 2 + ntl * surv_per_prefix()''')
open(fn2, 'w').write(t)
print('patched')
