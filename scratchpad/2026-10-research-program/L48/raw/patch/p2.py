#!/usr/bin/env python3
"""L48 patch 2 (the PR form, no knobs): applies to f3fb390's cubecl_join.rs (and join_plan.rs). Flags on the command
line: ballot (level 2), partial (level 3), spp1 (level 4), ee (level 5). The trims (level 1) are always in.
python3 p2.py ROOT [ballot] [partial] [spp1] [ee]"""
import sys
root = sys.argv[1]; flags = set(sys.argv[2:])
BALLOT, PARTIAL, SPP1, EE = 'ballot' in flags, 'partial' in flags, 'spp1' in flags, 'ee' in flags
fn = f'{root}/common/src/cubecl_join.rs'
s = open(fn).read()
def rep(old, new, count=1):
    global s
    n = s.count(old)
    if n != count:
        sys.exit(f'anchor found {n} times (want {count}):\n{old[:300]}')
    s = s.replace(old, new)

if EE:
    helpers = '''    /// `x -= y` over `nx` u32 words (`y` has `ny` <= `nx`); returns the borrow
    /// out of the top word. A borrow past `y`'s words is propagated only when
    /// there is one.
    #[cube]
    fn sub_words(x: &mut Array<u32>, y: &Array<u32>, #[comptime] ny: u32, #[comptime] nx: u32) -> u32 {
        // x + !y + 1, carried as `add_words` carries.
        let mut c = 1u64;
        #[unroll]
        for j in 0..ny {
            c += u64::cast_from(x[j as usize]) + u64::cast_from(y[j as usize] ^ 0xFFFF_FFFFu32);
            x[j as usize] = u32::cast_from(c);
            c >>= 32u64;
        }
        if comptime!(ny < nx) {
            if c == 0u64 {
                #[unroll]
                for j in ny..nx {
                    c += u64::cast_from(x[j as usize]) + 0xFFFF_FFFFu64;
                    x[j as usize] = u32::cast_from(c);
                    c >>= 32u64;
                }
            }
        }
        1u32 - u32::cast_from(c)
    }

    /// Words that bound the binary steps for blocks of width w = b^f0 (δ =
    /// w - 1): c2 = 2wδ < 2w², k3 = 6w²δ < 6w³, and Δ3 = 3wδ(2a + 2w - 1) <
    /// 3w²·2^(32·limbs + 2) for a block start a < 2^(32·limbs).
    fn fd_step_words(base: u32, f0: u32, limbs: u32) -> (u32, u32, u32) {
        let w = u128::from(base).pow(f0);
        let bits = |x: u128| 128 - x.leading_zeros();
        (
            bits(2 * w * w).div_ceil(32),
            bits(6 * w * w * w).div_ceil(32),
            (bits(3 * w * w) + 32 * limbs + 2).div_ceil(32),
        )
    }
'''
else:
    helpers = '''    /// `x -= y` over `nx` u32 words (`y` has `ny` <= `nx`); returns the borrow
    /// out of the top word.
    #[cube]
    fn sub_words(x: &mut Array<u32>, y: &Array<u32>, #[comptime] ny: u32, #[comptime] nx: u32) -> u32 {
        // x + !y + 1, carried as `add_words` carries.
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
'''
helpers += '''
    /// `out = b^c - 1 - x` over `nl` words (mod 2^(32·nl)), b^c from the
    /// power table `pw` (`nl3` words a power); it is its own inverse.
    #[cube]
    fn pw_minus1(
        pw: &Array<u32>,
        c: u32,
        x: &Array<u32>,
        out: &mut Array<u32>,
        #[comptime] nl: u32,
        #[comptime] nl3: u32,
    ) {
        let mut cy = 0u64;
        #[unroll]
        for j in 0..nl {
            cy += u64::cast_from(pw[(c * nl3 + j) as usize])
                + u64::cast_from(x[j as usize] ^ 0xFFFF_FFFFu32);
            out[j as usize] = u32::cast_from(cy);
            cy >>= 32u64;
        }
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
'''
if PARTIAL:
    helpers += '''
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
'''
rep('''    /// The binary differences' constants for blocks of width w (δ = w - 1):''', helpers + '''
    /// The binary differences' constants for blocks of width w (δ = w - 1):''')

# --- cert_power_fd ---
doc_old = '''    /// [`cert_power`] with the power's digits read from the finite-difference
    /// state instead of divided out: x = Q·b^z (Q's packed digits in `q`,
    /// four to a word; the `z` digits below are zero) and d = y - x (`nl`
    /// u32 words); `c0` = max(cap, ndig(d) clamped to sp), computed by the
    /// caller. The same results from the same digits as `cert_power`, by a
    /// scan over Q's words from the bottom: a word wholly below c0 only adds
    /// its value times b^pos to x mod b^c0 (u32 words here; nothing divides
    /// it), and the digits of the others go through `cert_power`'s scan step
    /// in order. The repeat flags come from the masks' popcounts at the end
    /// (a digit repeats among the n positions a mask covers iff it has fewer
    /// than n bits), and the end of x's run of (b - 1)s from c0 up is kept as
    /// a position. The zero digits at c0..z, if c0 < z (never for an
    /// unclipped block with P >= 1, where d2 >= w² and d3 >= w³), are put in
    /// before the scan: the first ends the run, the rest lie above it.
    #[cube]
    pub(super) fn cert_power_fd(
        q: &Array<u32>,
        d: &Array<u32>,
        pw: &Array<u32>,
        c0: u32,
        out_dup: &mut Array<u32>,
        out_dom: &mut Array<u32>,
        #[comptime] nl: u32,
        #[comptime] nl3: u32,
        #[comptime] sp: u32,'''
partial_doc = ''' Words that end four or more digits
    /// below c0 are left out of x mod b^c0 at first: they add less than b^p
    /// (p the first kept word's position), so the carry test needs them only
    /// when it is decided within b^p, and then adds them.''' if PARTIAL else ''
doc_new = f'''    /// [`cert_power`] with the power's digits read from the finite-difference
    /// state instead of divided out: x = Q·b^z (Q's packed digits in `q`,
    /// four to a word; the `z` digits below are zero), `c0` = max(cap,
    /// ndig(y - x) clamped to sp) and `dm` = b^c0 - 1 - (y - x) (`nl` u32
    /// words), both kept by the caller. The same results from the same digits
    /// as `cert_power`, by a scan over Q's words from the bottom: a word
    /// wholly below c0 only adds its value times b^pos to x mod b^c0 (u32
    /// words here; nothing divides it), and the digits of the others go
    /// through `cert_power`'s scan step in order, those of a word above the
    /// end of x's run of (b - 1)s from c0 up without the run's bookkeeping.
    /// The carry is x mod b^c0 > dm.{partial_doc} The repeat flags come from
    /// the masks' popcounts at the end (a digit repeats among the n positions
    /// a mask covers iff it has fewer than n bits), and the end of x's run of
    /// (b - 1)s from c0 up is kept as a position. The zero digits at c0..z, if
    /// c0 < z (never for an unclipped block with P >= 1, where d2 >= w² and d3
    /// >= w³), are put in before the scan: the first ends the run, the rest
    /// lie above it.
    #[cube]
    pub(super) fn cert_power_fd(
        q: &Array<u32>,
        dm: &Array<u32>,
        c0: u32,
        out_dup: &mut Array<u32>,
        out_dom: &mut Array<u32>,
        #[comptime] nl: u32,
        #[comptime] sp: u32,'''
rep(doc_old, doc_new)

old_loop_head = '''            let word = q[j as usize];
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
                for i in 0..4u32 {'''
if PARTIAL:
    new_loop_head = '''            let word = q[j as usize];
            let mut low = 0u32;
            // A word ending four or more digits below c0 is left out for now.
            let take = c0 < comptime!(wend + 4);
            if c0 >= wend {
                // Every digit of the word below c0 (those at sp and up are 0).
                if take {
                    low = word_value(word, base);
                }
            } else if in_run {
                #[unroll]
                for i in 0..4u32 {'''
else:
    new_loop_head = '''            let word = q[j as usize];
            let mut low = 0u32;
            if c0 >= wend {
                // Every digit of the word below c0 (those at sp and up are 0).
                low = word_value(word, base);
            } else if in_run {
                #[unroll]
                for i in 0..4u32 {'''
rep(old_loop_head, new_loop_head)

old_loop_tail = '''                        low += select(above, 0u32, dx * comptime!(base.pow(i)));
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
new_loop_tail = '''                        low += select(above, 0u32, dx * comptime!(base.pow(i)));
                    }
                }
            } else {
                // x's run has ended (in a lower word, or before the scan when
                // c0 < z): every digit here lies above c0.
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
            // rem += low · b^p0 (the sum is below b^(p0 + 4)).
            if p0 < c0''' + (' && take' if PARTIAL else '') + ''' {
                add_scaled_pow(&mut rem, low, nl, base, p0);
            }
        }'''
rep(old_loop_tail, new_loop_tail)

old_carry_start = '''        let dupc = select(pruc != nc, 1u32, 0u32);
        let mut one_more = false;
        if c0 < sp {
            let mut s = Array::<u32>::new(nl as usize);'''
i0 = s.index(old_carry_start)
end_marker = '''            one_more = carry != 0u32 || ge;
        }
'''
i1 = s.index(end_marker, i0) + len(end_marker)
if PARTIAL:
    partial_code = '''            if !one_more && c0 >= comptime!(z + 8) {
                // Left out: the words ending at or below c0 - 4, adding L <
                // b^p for the first kept word's position p; one more iff L >
                // dd, so only dd < b^p needs them.
                let mut amb = false;
                #[unroll]
                for jj in 1..nw {
                    let p = comptime!(z + 4 * jj);
                    if comptime!(p + 4 < sp) {
                        if c0 >= comptime!(p + 4) && c0 < comptime!(p + 8) {
                            amb = words_lt_pow(&dd, nl, base, p);
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
                        cb += u64::cast_from(dm[j as usize]) + u64::cast_from(rj ^ 0xFFFF_FFFFu32);
                        cb >>= 32u64;
                    }
                    one_more = cb == 0u64;
                }
            }
'''
else:
    partial_code = ''
new_carry = '''        let dupc = select(pruc != nc, 1u32, 0u32);
        // floor(y / b^c0) is one more than floor(x / b^c0) iff (x mod b^c0) +
        // (y - x) >= b^c0, i.e. x mod b^c0 > dm: dd = dm - rem borrows.
        let mut one_more = false;
        if c0 < sp {
            let mut dd = Array::<u32>::new(nl as usize);
            let mut c = 1u64;
            #[unroll]
            for j in 0..nl {
                c += u64::cast_from(dm[j as usize]) + u64::cast_from(rem[j as usize] ^ 0xFFFF_FFFFu32);
                dd[j as usize] = u32::cast_from(c);
                c >>= 32u64;
            }
            one_more = c == 0u64;
''' + partial_code + '''        }
'''
s = s[:i0] + new_carry + s[i1:]

# --- top_cert_fd ---
rep('''    /// [`top_cert`] for an unclipped block a = P·b^f0, e = a + b^f0 - 1 from
    /// the state's P² and P³ digits and the binary differences `d2`, `d3`,
    /// with the c0s computed (both at least their power's zero digits).
    #[cube]
    pub(super) fn top_cert_fd(
        sq: &Array<u32>,
        cu: &Array<u32>,
        d2: &Array<u32>,
        d3: &Array<u32>,
        c0a: u32,
        c0b: u32,
        pw: &Array<u32>,
        res: &mut Array<u32>,''', '''    /// [`top_cert`] for an unclipped block a = P·b^f0, e = a + b^f0 - 1 from
    /// the state's P² and P³ digits, the c0s (both at least their power's
    /// zero digits) and b^c0 - 1 - (e^k - a^k) of each power (`dm2`, `dm3`).
    #[cube]
    pub(super) fn top_cert_fd(
        sq: &Array<u32>,
        cu: &Array<u32>,
        dm2: &Array<u32>,
        dm3: &Array<u32>,
        c0a: u32,
        c0b: u32,
        res: &mut Array<u32>,''')
rep('''        let msq = cert_power_fd(
            sq,
            d2,
            pw,
            c0a,
            &mut dupa,
            &mut doma,
            nl2,
            nl3,
            s2,''', '''        let msq = cert_power_fd(
            sq,
            dm2,
            c0a,
            &mut dupa,
            &mut doma,
            nl2,
            s2,''')
rep('''        let mcu = cert_power_fd(
            cu,
            d3,
            pw,
            c0b,
            &mut dupb,
            &mut domb,
            nl3,
            nl3,
            s3,''', '''        let mcu = cert_power_fd(
            cu,
            dm3,
            c0b,
            &mut dupb,
            &mut domb,
            nl3,
            s3,''')

# --- top_fd_kernel ---
rep('''    /// P, so the digits of P² and P³ step from slot to slot by additions
    /// ([`top_fd_step`]), as do e² - a² and e³ - a³ in binary; they are
    /// divided out ([`top_fd_seed`], [`powers_diff`]) only for a group's
    /// first unclipped slot, after a gap in `vs` and after a clipped or
    /// out-of-range slot.''', '''    /// P, so the digits of P² and P³ step from slot to slot by additions
    /// ([`top_fd_step`]), as do each power's c0 and b^c0 - 1 - (e^k - a^k) in
    /// binary; they are divided out ([`top_fd_seed`], [`powers_diff`]) only
    /// for a group's first unclipped slot, after a gap in `vs` and after a
    /// clipped or out-of-range slot.''')
rep('''            // d2 = e² - a², d3 = e³ - a³ and Δ3 = d3(P + 1) - d3(P), stepped
            // in binary: d2 += 2wδ, d3 += Δ3, Δ3 += 6w²δ.''', '''            // d2 = e² - a², d3 = e³ - a³ and Δ3 = d3(P + 1) - d3(P): d2 grows
            // by 2wδ a step, d3 by Δ3, and Δ3 by 6w²δ. What is stepped is
            // each power's c0 = max(cap, ndig(d)) (it rarely moves) and dm
            // = b^c0 - 1 - d, the bound of the carry test.''')
rep('''            let mut valid = false;
            let mut prev_v = 0u32;
            // This cube's group of slots''', '''            let mut c0a = 0u32;
            let mut c0b = 0u32;
            let mut dm2 = Array::<u32>::new(nl2 as usize);
            let mut dm3 = Array::<u32>::new(nl3 as usize);
            #[unroll]
            for j in 0..nl2 {
                dm2[j as usize] = 0u32;
            }
            #[unroll]
            for j in 0..nl3 {
                dm3[j as usize] = 0u32;
            }
            let mut valid = false;
            let mut prev_v = 0u32;
            // This cube's group of slots''')
rep('''                if live && p >= plo && p <= phi {
                    // a = p*w (< 2^96, 3 limbs), e = a + w - 1, clipped to [s, e-1].
                    let t0 = (p & 0xFFFF_FFFFu64) * u64::cast_from(w);
                    let t1 = (p >> 32u64) * u64::cast_from(w) + (t0 >> 32u64);
                    let pw0 = u32::cast_from(t0);
                    let mut a = Array::<u32>::new(limbs as usize);
                    let mut e = Array::<u32>::new(limbs as usize);
                    #[unroll]''', '''                if live && p >= plo && p <= phi {
                    let mut a = Array::<u32>::new(limbs as usize);
                    let mut e = Array::<u32>::new(limbs as usize);
                    let mut a_lt_s = false;
                    let mut e_gt_e = false;
                    // Only P = plo and P = phi can be clipped, and a slot that
                    // steps needs neither a nor e (they feed a seed).
                    let steps = valid && v == prev_v + 1u32 && p != plo && p != phi;
                    if !steps {
                    // a = p*w (< 2^96, 3 limbs), e = a + w - 1, clipped to [s, e-1].
                    let t0 = (p & 0xFFFF_FFFFu64) * u64::cast_from(w);
                    let t1 = (p >> 32u64) * u64::cast_from(w) + (t0 >> 32u64);
                    let pw0 = u32::cast_from(t0);
                    #[unroll]''')
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
old_step_to_cert_start = '''                        let step = valid && v == prev_v + 1u32;
                        if step {'''
i0 = s.index(old_step_to_cert_start)
end2 = '''                        mask = top_cert_fd(
                            &sq, &cu, &d2, &d3, c0a, c0b, pw, &mut res, base, limbs, s2, s3, f0,
                        );
                    }'''
i1 = s.index(end2, i0) + len(end2)
new_block = '''                        let step = valid && v == prev_v + 1u32;
                        if step {
                            top_fd_step(
                                &mut sq, &mut cu, &mut ds, &mut dc, &mut ddc, base, tq, q2, q3,
                            );
                            // dm -= the step of d. A borrow means d reached
                            // b^c0 (rare): d = b^c0 - 1 - dm, c0 and dm anew.
                            let br2 = sub_words(
                                &mut dm2,
                                &c2,
                                comptime!(if nl2 < 3 { nl2 } else { 3 }),
                                nl2,
                            );
                            let br3 = sub_words(&mut dm3, &del3, nl3, nl3);
                            add_words(
                                &mut del3,
                                &k3,
                                comptime!(if nl3 < 4 { nl3 } else { 4 }),
                                nl3,
                            );
                            if c0a < s2 && br2 != 0u32 {
                                pw_minus1(pw, c0a, &dm2, &mut d2, nl2, nl3);
                                c0a = ndig_fast(&d2, pw, nl2, nl3, s2, base);
                                if c0a < cap {
                                    c0a = cap.runtime();
                                }
                                pw_minus1(pw, c0a, &d2, &mut dm2, nl2, nl3);
                            }
                            if c0b < s3 && br3 != 0u32 {
                                pw_minus1(pw, c0b, &dm3, &mut d3, nl3, nl3);
                                c0b = ndig_fast(&d3, pw, nl3, nl3, s3, base);
                                if c0b < cap {
                                    c0b = cap.runtime();
                                }
                                pw_minus1(pw, c0b, &d3, &mut dm3, nl3, nl3);
                            }
                        } else {
                            let mut a2 = Array::<u32>::new(nh2 as usize);
                            let mut a3 = Array::<u32>::new(nh3 as usize);
                            powers_diff(
                                &a, &e, &mut a2, &mut a3, &mut d2, &mut d3, limbs, 1u32, false,
                            );
                            top_fd_del3(&a, w, &mut del3, limbs, nl3);
                            top_fd_seed(
                                p,
                                &mut sq,
                                &mut cu,
                                &mut ds,
                                &mut dc,
                                &mut ddc,
                                base,
                                tq,
                                q2,
                                q3,
                                chunk_digits,
                                chunk_div,
                            );
                            c0a = ndig_fast(&d2, pw, nl2, nl3, s2, base);
                            if c0a < cap {
                                c0a = cap.runtime();
                            }
                            c0b = ndig_fast(&d3, pw, nl3, nl3, s3, base);
                            if c0b < cap {
                                c0b = cap.runtime();
                            }
                            pw_minus1(pw, c0a, &d2, &mut dm2, nl2, nl3);
                            pw_minus1(pw, c0b, &d3, &mut dm3, nl3, nl3);
                        }
                        mask = top_cert_fd(
                            &sq, &cu, &dm2, &dm3, c0a, c0b, &mut res, base, limbs, s2, s3, f0,
                        );
                    }'''
s = s[:i0] + new_block + s[i1:]

if BALLOT:
    rep('''                // Append the plane's kept tops with one atomic: `slot` is a
                // loop counter, so the compiler does not aggregate it as it
                // does `top_kernel`'s (whose slot is the cube's y).
                let kc = select(kept, 1u32, 0u32);
                let n = plane_sum(kc);
                let pre = plane_exclusive_sum(kc);
                let mut at = 0u32;''', '''                // Append the plane's kept tops with one atomic: `slot` is a
                // loop counter, so the compiler does not aggregate it as it
                // does `top_kernel`'s (whose slot is the cube's y). The
                // plane's count and this lane's rank are popcounts of one
                // ballot (of up to 128 lanes).
                let bal = plane_ballot(kept);
                let lane = UNIT_POS_PLANE;
                let wi = lane >> 5u32;
                let lt = (1u32 << (lane & 31u32)) - 1u32;
                let mut n = 0u32;
                let mut pre = 0u32;
                #[unroll]
                for k in 0..4u32 {
                    let bk = bal[k as usize];
                    n += bk.count_ones();
                    let mk = select(wi > k, 0xFFFF_FFFFu32, select(wi == k, lt, 0u32));
                    pre += (bk & mk).count_ones();
                }
                let mut at = 0u32;''')
if EE:
    rep('''    fn fd_add_small(
        x: &mut Array<u32>,
        #[comptime] c: u32,
        #[comptime] kd: u32,
        #[comptime] base: u32,
    ) {
        let bias = comptime!((256 - base) * 0x0101_0101u32);
        let fix = comptime!(256 - base);
        let mut cin = 0u32;
        #[unroll]
        for w in 0..kd {
            let t = x[w as usize] + comptime!(bias + if w == 0 { c } else { 0 }) + cin;
            cin = (t >> 31u32) ^ 1u32;
            x[w as usize] = t - ((t >> 7u32) & 0x0101_0101u32) * fix;
        }
    }''', '''    fn fd_add_small(
        x: &mut Array<u32>,
        #[comptime] c: u32,
        #[comptime] kd: u32,
        #[comptime] base: u32,
    ) {
        let bias = comptime!((256 - base) * 0x0101_0101u32);
        let fix = comptime!(256 - base);
        let t0 = x[0] + comptime!(bias + c);
        let mut cin = (t0 >> 31u32) ^ 1u32;
        x[0] = t0 - ((t0 >> 7u32) & 0x0101_0101u32) * fix;
        // A word plus the bias and no carry comes back unchanged.
        if comptime!(kd > 1) {
            if cin != 0u32 {
                #[unroll]
                for w in 1..kd {
                    let t = x[w as usize] + bias + cin;
                    cin = (t >> 31u32) ^ 1u32;
                    x[w as usize] = t - ((t >> 7u32) & 0x0101_0101u32) * fix;
                }
            }
        }
    }

    /// `fd_add_top`'s biased add of `y`'s `wy` packed-digit words into `x`
    /// (`kd` words), with the carry past `y`'s words propagated only when
    /// there is one.
    #[cube]
    fn fd_add_carry(
        x: &mut Array<u32>,
        y: &Array<u32>,
        #[comptime] wy: u32,
        #[comptime] kd: u32,
        #[comptime] base: u32,
    ) {
        let bias = comptime!((256 - base) * 0x0101_0101u32);
        let fix = comptime!(256 - base);
        let mut cin = 0u32;
        #[unroll]
        for w in 0..wy {
            let t = x[w as usize] + y[w as usize] + bias + cin;
            cin = (t >> 31u32) ^ 1u32;
            x[w as usize] = t - ((t >> 7u32) & 0x0101_0101u32) * fix;
        }
        if comptime!(wy < kd) {
            if cin != 0u32 {
                #[unroll]
                for w in wy..kd {
                    let t = x[w as usize] + bias + cin;
                    cin = (t >> 31u32) ^ 1u32;
                    x[w as usize] = t - ((t >> 7u32) & 0x0101_0101u32) * fix;
                }
            }
        }
    }''')
    rep('''        fd_add_top(sq, ds, wq1, wq2, base);
        fd_add_small(ds, 2u32, wq1, base);
        fd_add_top(cu, dc, wdc, wq3, base);
        fd_add_top(dc, ddc, wq1, wdc, base);
        fd_add_small(ddc, 6u32, wq1, base);''', '''        fd_add_carry(sq, ds, wq1, wq2, base);
        fd_add_small(ds, 2u32, wq1, base);
        fd_add_carry(cu, dc, wdc, wq3, base);
        fd_add_carry(dc, ddc, wq1, wdc, base);
        fd_add_small(ddc, 6u32, wq1, base);''')
    rep('''    /// `x += y` over `nx` u32 words (`y` has `ny` <= `nx`), the carry out of
    /// the top word dropped (the caller's values fit).
    #[cube]
    fn add_words(x: &mut Array<u32>, y: &Array<u32>, #[comptime] ny: u32, #[comptime] nx: u32) {
        let mut c = 0u64;
        #[unroll]
        for j in 0..nx {
            if comptime!(j < ny) {
                c += u64::cast_from(x[j as usize]) + u64::cast_from(y[j as usize]);
            } else {
                c += u64::cast_from(x[j as usize]);
            }
            x[j as usize] = u32::cast_from(c);
            c >>= 32u64;
        }
    }''', '''    /// `x += y` over `nx` u32 words (`y` has `ny` <= `nx`), the carry out of
    /// the top word dropped (the caller's values fit); a carry past `y`'s
    /// words is propagated only when there is one.
    #[cube]
    fn add_words(x: &mut Array<u32>, y: &Array<u32>, #[comptime] ny: u32, #[comptime] nx: u32) {
        let mut c = 0u64;
        #[unroll]
        for j in 0..ny {
            c += u64::cast_from(x[j as usize]) + u64::cast_from(y[j as usize]);
            x[j as usize] = u32::cast_from(c);
            c >>= 32u64;
        }
        if comptime!(ny < nx) {
            if c != 0u64 {
                #[unroll]
                for j in ny..nx {
                    c += u64::cast_from(x[j as usize]);
                    x[j as usize] = u32::cast_from(c);
                    c >>= 32u64;
                }
            }
        }
    }''')
    rep('''                            let br2 = sub_words(
                                &mut dm2,
                                &c2,
                                comptime!(if nl2 < 3 { nl2 } else { 3 }),
                                nl2,
                            );
                            let br3 = sub_words(&mut dm3, &del3, nl3, nl3);
                            add_words(
                                &mut del3,
                                &k3,
                                comptime!(if nl3 < 4 { nl3 } else { 4 }),
                                nl3,
                            );''', '''                            let nc2 = comptime!(fd_step_words(base, f0, limbs).0.min(3).min(nl2));
                            let nk3 = comptime!(fd_step_words(base, f0, limbs).1.min(4).min(nl3));
                            let nd3 = comptime!(fd_step_words(base, f0, limbs).2.min(nl3));
                            let br2 = sub_words(&mut dm2, &c2, nc2, nl2);
                            let br3 = sub_words(&mut dm3, &del3, nd3, nl3);
                            add_words(&mut del3, &k3, nk3, nl3);''')

open(fn, 'w').write(s)

if SPP1:
    fn2 = f'{root}/common/src/join_plan.rs'
    t = open(fn2).read()
    old = '''/// An upper bound on the prefilter survivors one partition yields per
/// top-layer prefix of the field: measured 0.8-1.6 at bases 57-64 on fields
/// of 1e14-1e15 (b57 frontier 1.08, b58 1.09-1.11, b60 0.79, Dan's dense
/// b57 fields up to about 1.6). A batch is planned to fill at most half its
/// survivor list on this bound; one that still overflows is re-run in
/// smaller batches (`cubecl_join::run_field`).
const SURV_PER_PREFIX: usize = 2;'''
    assert t.count(old) == 1, 'SPP anchor'
    t = t.replace(old, '''/// The prefilter survivors one partition is expected to yield per top-layer
/// prefix of the field: measured 0.8-1.6 at bases 57-64 on fields of
/// 1e14-1e15 (b57 frontier 1.08, b58 1.09-1.11, b60 0.79, Dan's dense b57
/// fields up to about 1.6) and 0.53 on a b62 1e17 field. A batch is planned
/// to fill at most half its survivor list at this rate; one that still
/// overflows is re-run in smaller batches (`cubecl_join::run_field`). More
/// partitions per launch mean fewer of the FD top kernel's seeds.
const SURV_PER_PREFIX: usize = 1;''')
    open(fn2, 'w').write(t)
print('p2 applied', sorted(flags))
