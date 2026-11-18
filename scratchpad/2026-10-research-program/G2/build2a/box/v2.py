import sys
p = sys.argv[1]
s = open(p).read()


def rep(old, new, cnt=1):
    global s
    n = s.count(old)
    assert n == cnt, (old[:80], n)
    s = s.replace(old, new)


# kernel side: as v.py (one-bit words carry the child's r4, bit 31 of word 0)
rep("""            sync_cube();
            if dhave {
                pq[dsl as usize] = pq[dsl as usize] | (dv << 16u32);
                dhave = false;
            }
            sync_cube();
            let done = cur >= pe;""", """            sync_cube();
            if dhave {
                pq[dsl as usize] = pq[dsl as usize] | (dv << 16u32);
                dhave = false;
            }
            sync_cube();
            if comptime!(mode == 2 && !noout) {
                // (midout) phase 1's child-list stores, read by other threads of the cube in 3b (SPIR-V needs a
                // device-memory barrier for that; on CUDA it is the same __syncthreads)
                sync_storage();
            }
            let done = cur >= pe;""")
for h in ("0", "1"):
    old = """                                        rv[0usize] = pk[%susize];
                                        rv[1usize] = lb + cpos;
                                        rv[2usize] = wlo[%susize];
                                        rv[3usize] = whi[%susize];""" % (h, h, h)
    new = """                                        // (midout) a word with one bit (most of them) carries its child's r4,
                                        // flagged by bit 31 of word 0, in place of the chunk's position
                                        let one = (wlo[%susize] & (wlo[%susize] - 1u32)) == 0u32
                                            && (whi[%susize] & (whi[%susize] - 1u32)) == 0u32
                                            && (wlo[%susize] == 0u32 || whi[%susize] == 0u32);
                                        let mut w0 = pk[%susize];
                                        let mut w1 = lb + cpos;
                                        if one {
                                            let b = select(
                                                wlo[%susize] != 0u32,
                                                wlo[%susize].trailing_zeros(),
                                                32u32 + whi[%susize].trailing_zeros(),
                                            );
                                            w1 = clst[(lb + cpos + b) as usize];
                                            w0 |= 0x8000_0000u32;
                                        }
                                        rv[0usize] = w0;
                                        rv[1usize] = w1;
                                        rv[2usize] = wlo[%susize];
                                        rv[3usize] = whi[%susize];""" % ((h,) * 12)
    rep(old, new)
# expansion: one prefilter call per bit, its r4 from the record or the child list
rep("""                if r < cnt {
                    let rec = out[i as usize];
                    ti = rec[0usize];
                    pos = rec[1usize];""", """                let mut one = false;
                if r < cnt {
                    let rec = out[i as usize];
                    // bit 31: a one-bit word whose child's r4 is word 1
                    one = (rec[0usize] >> 31u32) != 0u32;
                    ti = rec[0usize] & 0x7FFF_FFFFu32;
                    pos = rec[1usize];""")
rep("""                        if pf(lst[(pos + off) as usize] + r0hi, plo, phi, top) {""", """                        let mut r4 = pos;
                        if !one {
                            r4 = lst[(pos + off) as usize];
                        }
                        if pf(r4 + r0hi, plo, phi, top) {""")
rep("""                let mut x = klo;
                while x != 0u32 {
                    let b = x.trailing_zeros();
                    x &= x - 1u32;
                    if slot < scap {
                        surv[(2u32 * slot) as usize] = ti;
                        surv[(2u32 * slot + 1u32) as usize] = lst[(pos + b) as usize] + r0hi;
                    }
                    slot += 1u32;
                }
                let mut y = khi;
                while y != 0u32 {
                    let b = y.trailing_zeros();
                    y &= y - 1u32;
                    if slot < scap {
                        surv[(2u32 * slot) as usize] = ti;
                        surv[(2u32 * slot + 1u32) as usize] =
                            lst[(pos + 32u32 + b) as usize] + r0hi;
                    }
                    slot += 1u32;
                }""", """                let mut x = klo;
                let mut y = khi;
                while (x | y) != 0u32 {
                    let inlo = x != 0u32;
                    let b = select(inlo, x.trailing_zeros(), y.trailing_zeros());
                    let off = select(inlo, b, 32u32 + b);
                    if inlo {
                        x &= x - 1u32;
                    } else {
                        y &= y - 1u32;
                    }
                    let mut r4 = pos;
                    if !one {
                        r4 = lst[(pos + off) as usize];
                    }
                    if slot < scap {
                        surv[(2u32 * slot) as usize] = ti;
                        surv[(2u32 * slot + 1u32) as usize] = r4 + r0hi;
                    }
                    slot += 1u32;
                }""")
open(p, 'w').write(s)
