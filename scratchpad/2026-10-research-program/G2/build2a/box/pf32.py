import sys
p = sys.argv[1]
s = open(p).read()


def rep(old, new, cnt=1):
    global s
    n = s.count(old)
    assert n == cnt, (old[:80], n)
    s = s.replace(old, new)


i0 = s.index("    /// `(lo, hi)` of `a·b` for 64-bit words, by 32-bit halves.")
i1 = s.index("    /// Records → production's survivor-list entries")
s = s[:i0] + '''    /// Digit v (< 64) as a one-hot pair of 32-bit words (lo: digits 0-31).
    #[cube]
    fn oh(v: u32) -> (u32, u32) {
        let b = 1u32 << (v & 31u32);
        let m = 0u32 - (v >> 5u32);
        (b & !m, b & m)
    }

    /// The 12 low base-64 digits of a residue mod 2^72 in 32-bit limbs
    /// (`w0`, `w1`, `w2` < 256), ORed into the one-hot pair (lo, hi); digits
    /// 10-11 also into (mlo, mhi).
    #[cube]
    fn digits12(w0: u32, w1: u32, w2: u32) -> (u32, u32, u32, u32) {
        let mut lo = 0u32;
        let mut hi = 0u32;
        #[unroll]
        for j in 0..5u32 {
            let (a, b) = oh((w0 >> comptime!(6 * j)) & 63u32);
            lo |= a;
            hi |= b;
        }
        let (a5, b5) = oh((w0 >> 30u32) | ((w1 & 15u32) << 2u32));
        lo |= a5;
        hi |= b5;
        #[unroll]
        for j in 0..4u32 {
            let (a, b) = oh((w1 >> comptime!(4 + 6 * j)) & 63u32);
            lo |= a;
            hi |= b;
        }
        let (a10, b10) = oh((w1 >> 28u32) | ((w2 & 3u32) << 4u32));
        let (a11, b11) = oh(w2 >> 2u32);
        (lo, hi, a10 | a11, b10 | b11)
    }

    /// The middle-digit prefilter of one survivor (`cpu::prefilter` at k
    /// 10): n mod 2^72 from `r0` and its top's P (bits 30-93 of n), in 32-bit
    /// limbs; the digits at positions 0-11 of n² and n³ (mod 2^72) must be
    /// 24 distinct digits (the bottom's 20 are distinct already), and those
    /// at 10-11 must miss the top's certified digits at positions >= 12
    /// (`top`).
    #[cube]
    fn pf(r0: u32, plo: u32, phi: u32, top: u64) -> bool {
        let x0 = r0 | (plo << 30u32);
        let x1 = (plo >> 2u32) | (phi << 30u32);
        let x2 = (phi >> 2u32) & 255u32;
        // n² mod 2^72
        let s0 = x0 * x0;
        let t1 = u64::cast_from(u32::mul_hi(x0, x0)) + 2u64 * u64::cast_from(x0 * x1);
        let s1 = u32::cast_from(t1 & 0xFFFF_FFFFu64);
        let s2 = (u32::cast_from(t1 >> 32u64) + 2u32 * u32::mul_hi(x0, x1) + x1 * x1 + 2u32 * x0 * x2)
            & 255u32;
        // n³ = n²·n mod 2^72
        let c0 = s0 * x0;
        let t2 = u64::cast_from(u32::mul_hi(s0, x0))
            + u64::cast_from(s0 * x1)
            + u64::cast_from(s1 * x0);
        let c1 = u32::cast_from(t2 & 0xFFFF_FFFFu64);
        let c2 = (u32::cast_from(t2 >> 32u64)
            + u32::mul_hi(s0, x1)
            + u32::mul_hi(s1, x0)
            + s1 * x1
            + s0 * x2
            + s2 * x0)
            & 255u32;
        let (sl, sh, sml, smh) = digits12(s0, s1, s2);
        let (cl, ch, cml, cmh) = digits12(c0, c1, c2);
        let lo = sl | cl;
        let hi = sh | ch;
        let mlo = sml | cml;
        let mhi = smh | cmh;
        let tlo = u32::cast_from(top & 0xFFFF_FFFFu64);
        let thi = u32::cast_from(top >> 32u64);
        lo.count_ones() + hi.count_ones() == 24u32 && ((mlo & tlo) | (mhi & thi)) == 0u32
    }

''' + s[i1:]
# one loop over the record's 64 bits (a lane's two words in turn): the plane runs max(bits) rounds, not max per word
rep("""                    let mut x = wlo;
                    while x != 0u32 {
                        let b = x.trailing_zeros();
                        x &= x - 1u32;
                        if pf(lst[(pos + b) as usize] + r0hi, plo, phi, top) {
                            klo |= 1u32 << b;
                        }
                    }
                    let mut y = whi;
                    while y != 0u32 {
                        let b = y.trailing_zeros();
                        y &= y - 1u32;
                        if pf(lst[(pos + 32u32 + b) as usize] + r0hi, plo, phi, top) {
                            khi |= 1u32 << b;
                        }
                    }""", """                    // one loop over both words: the plane runs max(bits) rounds, not that per word
                    let mut x = wlo;
                    let mut y = whi;
                    while (x | y) != 0u32 {
                        let inlo = x != 0u32;
                        let b = select(inlo, x.trailing_zeros(), y.trailing_zeros());
                        let off = select(inlo, b, 32u32 + b);
                        if inlo {
                            x &= x - 1u32;
                        } else {
                            y &= y - 1u32;
                        }
                        if pf(lst[(pos + off) as usize] + r0hi, plo, phi, top) {
                            if inlo {
                                klo |= 1u32 << b;
                            } else {
                                khi |= 1u32 << b;
                            }
                        }
                    }""")
open(p, 'w').write(s)
