#!/usr/bin/env python3
"""L48 patch 3 (on p1): level 5 = level 4 + the step's carries and borrows past each addend's words propagated only
when there is one, and the binary addends cut to their comptime word bounds."""
import sys
root = sys.argv[1]
fn = f'{root}/common/src/cubecl_join.rs'
s = open(fn).read()
def rep(old, new, count=1):
    global s
    n = s.count(old)
    if n != count:
        sys.exit(f'anchor found {n} times (want {count}):\n{old[:300]}')
    s = s.replace(old, new)

rep('''/// unless the carry test needs them; 4 plans one expected survivor per
/// prefix and partition (`join_plan`). 103 is level 3 with the left-out
/// words always added back (tests the fallback).''', '''/// unless the carry test needs them; 4 plans one expected survivor per
/// prefix and partition (`join_plan`); 5 propagates the step's carries past
/// each addend's words only when there is one. 103 is level 3 with the
/// left-out words always added back (tests the fallback).''')
rep('''            .filter(|&l| l <= 4 || l == 103)''', '''            .filter(|&l| l <= 5 || l == 103)''')
rep('''            top_fd_lvl: match exp_topfd_level() {
                103 => 103,
                l => l.min(3),
            },''', '''            top_fd_lvl: match exp_topfd_level() {
                4 => 3,
                l => l,
            },''')

helpers = '''    /// Level 5: [`fd_add_top`] with the carry past `y`'s `wy` words
    /// propagated only when there is one (a word plus the bias and no carry
    /// comes back unchanged).
    #[cube]
    fn fd_add_ee(
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
    }

    /// Level 5: `fd_add_small` with the carry past word 0 propagated only
    /// when there is one.
    #[cube]
    fn fd_add_small_ee(
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

    /// Level 5: [`top_fd_step`] with early-exit carries.
    #[cube]
    fn top_fd_step_ee(
        sq: &mut Array<u32>,
        cu: &mut Array<u32>,
        ds: &mut Array<u32>,
        dc: &mut Array<u32>,
        ddc: &mut Array<u32>,
        #[comptime] base: u32,
        #[comptime] tq: u32,
        #[comptime] q2: u32,
        #[comptime] q3: u32,
    ) {
        let wq1 = comptime!((tq + 1).div_ceil(4));
        let wq2 = comptime!(q2.div_ceil(4));
        let wdc = comptime!((q2 + 1).div_ceil(4));
        let wq3 = comptime!(q3.div_ceil(4));
        fd_add_ee(sq, ds, wq1, wq2, base);
        fd_add_small_ee(ds, 2u32, wq1, base);
        fd_add_ee(cu, dc, wdc, wq3, base);
        fd_add_ee(dc, ddc, wq1, wdc, base);
        fd_add_small_ee(ddc, 6u32, wq1, base);
    }

    /// Level 5: [`sub_words_b`] with the borrow past `y`'s `ny` words
    /// propagated only when there is one.
    #[cube]
    fn sub_words_ee(
        x: &mut Array<u32>,
        y: &Array<u32>,
        #[comptime] ny: u32,
        #[comptime] nx: u32,
    ) -> u32 {
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

    /// Level 5: [`add_words`] with the carry past `y`'s `ny` words
    /// propagated only when there is one.
    #[cube]
    fn add_words_ee(x: &mut Array<u32>, y: &Array<u32>, #[comptime] ny: u32, #[comptime] nx: u32) {
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
    }

    /// Level 5: words that bound the binary steps for blocks of width w =
    /// b^f0 (δ = w - 1): c2 = 2wδ < 2w², k3 = 6w²δ < 6w³, and Δ3 = 3wδ(2a +
    /// 2w - 1) < 3w²·2^(32·limbs + 2) for a block start a < 2^(32·limbs).
    fn fd_step_words(base: u32, f0: u32, limbs: u32) -> (u32, u32, u32) {
        let w = u128::from(base).pow(f0);
        let bits = |x: u128| 128 - x.leading_zeros();
        (
            bits(2 * w * w).div_ceil(32),
            bits(6 * w * w * w).div_ceil(32),
            (bits(3 * w * w) + 32 * limbs + 2).div_ceil(32),
        )
    }

    /// The binary differences' constants for blocks of width w (δ = w - 1):'''
rep('''    /// The binary differences' constants for blocks of width w (δ = w - 1):''', helpers)

old = '''                        if step {
                            top_fd_step(
                                &mut sq, &mut cu, &mut ds, &mut dc, &mut ddc, base, tq, q2, q3,
                            );
                            if comptime!(lc0) {'''
new = '''                        if step && comptime!(lvl == 5) {
                            top_fd_step_ee(
                                &mut sq, &mut cu, &mut ds, &mut dc, &mut ddc, base, tq, q2, q3,
                            );
                            let nc2 = comptime!(fd_step_words(base, f0, limbs).0.min(3).min(nl2));
                            let nk3 = comptime!(fd_step_words(base, f0, limbs).1.min(4).min(nl3));
                            let nd3 = comptime!(fd_step_words(base, f0, limbs).2.min(nl3));
                            let br2 = sub_words_ee(&mut dp2, &c2, nc2, nl2);
                            let br3 = sub_words_ee(&mut dp3, &del3, nd3, nl3);
                            add_words_ee(&mut del3, &k3, nk3, nl3);
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
                        } else if step {
                            top_fd_step(
                                &mut sq, &mut cu, &mut ds, &mut dc, &mut ddc, base, tq, q2, q3,
                            );
                            if comptime!(lc0) {'''
rep(old, new)
open(fn, 'w').write(s)

fn2 = f'{root}/common/src/join_plan.rs'
t = open(fn2).read()
old2 = '''/// Experiment (L48): [`SURV_PER_PREFIX`], or 1 at `NICE_EXP_TOPFD=4`.
fn surv_per_prefix() -> usize {
    if crate::cubecl_join::exp_topfd_level() == 4 {'''
assert t.count(old2) == 1
t = t.replace(old2, '''/// Experiment (L48): [`SURV_PER_PREFIX`], or 1 at `NICE_EXP_TOPFD` 4 and 5.
fn surv_per_prefix() -> usize {
    if matches!(crate::cubecl_join::exp_topfd_level(), 4 | 5) {''')
open(fn2, 'w').write(t)
print('p3 applied')
