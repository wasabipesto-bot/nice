import sys
p = sys.argv[1]
s = open(p).read()


def rep(old, new, cnt=1):
    global s
    n = s.count(old)
    assert n == cnt, (old[:80], n)
    s = s.replace(old, new)


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
                // device-memory barrier for that; CUDA's is the same __syncthreads)
                sync_storage();
            }
            let done = cur >= pe;""")
rep("""                                    if nza {
                                        let mut rv = Vector::<u32, Const<4>>::empty();
                                        rv[0usize] = pk[0usize];
                                        rv[1usize] = lb + cpos;
                                        rv[2usize] = wlo[0usize];
                                        rv[3usize] = whi[0usize];
                                        out[(sbase + ra) as usize] = rv;
                                    }
                                    if nzb {
                                        let mut rv = Vector::<u32, Const<4>>::empty();
                                        rv[0usize] = pk[1usize];
                                        rv[1usize] = lb + cpos;
                                        rv[2usize] = wlo[1usize];
                                        rv[3usize] = whi[1usize];
                                        out[(sbase + na + rb) as usize] = rv;
                                    }""", """                                    // (midout) a word with one bit (most of them) carries its child's r4 (bit 31 of
                                    // word 0 set) in place of the chunk's position: the expansion needs no gather
                                    if nza {
                                        let mut rv = Vector::<u32, Const<4>>::empty();
                                        let one = (wlo[0usize] & (wlo[0usize] - 1u32)) == 0u32
                                            && (whi[0usize] & (whi[0usize] - 1u32)) == 0u32
                                            && (wlo[0usize] == 0u32 || whi[0usize] == 0u32);
                                        let mut w0 = pk[0usize];
                                        let mut w1 = lb + cpos;
                                        if one {
                                            let b = select(
                                                wlo[0usize] != 0u32,
                                                wlo[0usize].trailing_zeros(),
                                                32u32 + whi[0usize].trailing_zeros(),
                                            );
                                            w1 = clst[(lb + cpos + b) as usize];
                                            w0 |= 0x8000_0000u32;
                                        }
                                        rv[0usize] = w0;
                                        rv[1usize] = w1;
                                        rv[2usize] = wlo[0usize];
                                        rv[3usize] = whi[0usize];
                                        out[(sbase + ra) as usize] = rv;
                                    }
                                    if nzb {
                                        let mut rv = Vector::<u32, Const<4>>::empty();
                                        let one = (wlo[1usize] & (wlo[1usize] - 1u32)) == 0u32
                                            && (whi[1usize] & (whi[1usize] - 1u32)) == 0u32
                                            && (wlo[1usize] == 0u32 || whi[1usize] == 0u32);
                                        let mut w0 = pk[1usize];
                                        let mut w1 = lb + cpos;
                                        if one {
                                            let b = select(
                                                wlo[1usize] != 0u32,
                                                wlo[1usize].trailing_zeros(),
                                                32u32 + whi[1usize].trailing_zeros(),
                                            );
                                            w1 = clst[(lb + cpos + b) as usize];
                                            w0 |= 0x8000_0000u32;
                                        }
                                        rv[0usize] = w0;
                                        rv[1usize] = w1;
                                        rv[2usize] = wlo[1usize];
                                        rv[3usize] = whi[1usize];
                                        out[(sbase + na + rb) as usize] = rv;
                                    }""")
# expansion
rep("""                if r < cnt {
                    let rec = out[i as usize];
                    ti = rec[0usize];
                    pos = rec[1usize];
                    let wlo = rec[2usize];
                    let whi = rec[3usize];""", """                let mut one = false;
                if r < cnt {
                    let rec = out[i as usize];
                    // bit 31: a one-bit word whose child's r4 is word 1
                    one = (rec[0usize] >> 31u32) != 0u32;
                    ti = rec[0usize] & 0x7FFF_FFFFu32;
                    pos = rec[1usize];
                    let wlo = rec[2usize];
                    let whi = rec[3usize];""")
rep("""                    // one loop over both words: the plane runs max(bits) rounds, not that per word
                    let mut x = wlo;
                    let mut y = whi;
                    while (x | y) != 0u32 {""", """                    // one loop over both words: the plane runs max(bits) rounds, not that per word
                    let mut x = wlo;
                    let mut y = whi;
                    if one {
                        if pf(pos + r0hi, plo, phi, top) {
                            klo = wlo;
                            khi = whi;
                        }
                        x = 0u32;
                        y = 0u32;
                    }
                    while (x | y) != 0u32 {""")
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
                }""", """                if one {
                    if (klo | khi) != 0u32 && slot < scap {
                        surv[(2u32 * slot) as usize] = ti;
                        surv[(2u32 * slot + 1u32) as usize] = pos + r0hi;
                    }
                } else {
                    let mut x = klo;
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
                    }
                }""")
open(p, 'w').write(s)
