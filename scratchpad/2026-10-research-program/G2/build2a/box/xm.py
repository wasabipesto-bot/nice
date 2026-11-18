import sys
p = sys.argv[1]
s = open(p).read()


def rep(old, new, cnt=1):
    global s
    n = s.count(old)
    assert n == cnt, (old[:80], n)
    s = s.replace(old, new)


rep("""        r0hi: u32,
        pip_hi: u32,
    ) {
        if ABSOLUTE_POS_X == 0u32 {
            stat[0usize].store(lcnt[0usize]);""", """        r0hi: u32,
        pip_hi: u32,
        xm: u32,
    ) {
        let mut sink = 0u32;
        if ABSOLUTE_POS_X == 0u32 {
            stat[0usize].store(lcnt[0usize]);""")
rep("""                    read += wlo.count_ones() + whi.count_ones();
                    // P = n div 2^30""", """                    read += wlo.count_ones() + whi.count_ones();
                    if xm == 1u32 {
                        sink ^= ti ^ pos;
                    } else if xm == 2u32 {
                        let mut x = wlo;
                        let mut y = whi;
                        sink ^= thd[ti as usize] ^ u32::cast_from(tmhi[ti as usize]);
                        while (x | y) != 0u32 {
                            let inlo = x != 0u32;
                            let b = select(inlo, x.trailing_zeros(), y.trailing_zeros());
                            let off = select(inlo, b, 32u32 + b);
                            if inlo {
                                x &= x - 1u32;
                            } else {
                                y &= y - 1u32;
                            }
                            sink ^= lst[(pos + off) as usize];
                        }
                    } else {
                    // P = n div 2^30""")
rep("""                            if inlo {
                                klo |= 1u32 << b;
                            } else {
                                khi |= 1u32 << b;
                            }
                        }
                    }
                }
                let nb = klo.count_ones() + khi.count_ones();""", """                            if inlo {
                                klo |= 1u32 << b;
                            } else {
                                khi |= 1u32 << b;
                            }
                        }
                    }
                    }
                }
                let nb = klo.count_ones() + khi.count_ones();""")
rep("""        let rs = plane_sum(read);
        if UNIT_POS_PLANE == 0u32 && rs > 0u32 {
            stat[2usize].fetch_add(rs);
        }""", """        let rs = plane_sum(read);
        if UNIT_POS_PLANE == 0u32 && rs > 0u32 {
            stat[2usize].fetch_add(rs);
        }
        if sink == 0x1234_5678u32 {
            stat[1usize].fetch_add(1u32);
        }""")
rep("""                        ((pip & 63) as u32) << 24,
                        (pip >> 6) as u32,
                    );""", """                        ((pip & 63) as u32) << 24,
                        (pip >> 6) as u32,
                        std::env::var("XM").ok().and_then(|x| x.parse().ok()).unwrap_or(0u32),
                    );""")
open(p, 'w').write(s)
