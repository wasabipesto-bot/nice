#!/usr/bin/env python3
"""N16: join_kernel switches (work-group size, doubling modes, base-split removal modes) on tree E + N13 patches.
Kept as the record of how commit 2 of exp/n16-join-base was made. python3 patch_n16_kernel.py TREE"""
import sys
p = sys.argv[1] + '/common/src/cubecl_join.rs'
s = open(p).read()


def rep(a, b, cnt=1):
    global s
    assert s.count(a) == cnt, (s.count(a), a[:80])
    s = s.replace(a, b)


rep("""        #[comptime] sflush: u32,
        #[comptime] stg: u32,
    ) {
        // L51 (experimental""", """        #[comptime] sflush: u32,
        #[comptime] stg: u32,
        #[comptime] wg: u32,
        #[comptime] dbl: u32,
        zz: u32,
    ) {
        // N16 (experimental, `NICE_EXP_JOIN_WG`, `NICE_EXP_JOIN_DBL`,
        // `NICE_EXP_JOIN_ABL` 5-8): `wg` = threads per cube (JOIN_WG by
        // default); `dbl` = a bit mask of parts executed twice (see
        // `DBL_*` on the host), every repeat indexed with `rep * zz` where `zz`
        // is a runtime 0 the compiler cannot see through, so the repeat is
        // not folded away and the result is unchanged (ORs and stores of the
        // same values; the shadow walk and the second prefilter are combined
        // so that they cannot change a count). `abl` 5: dispatch only (the
        // first barrier, the final count and `cube_done`); 6: + the work-item
        // headers and their three barriers (no batch loop); 7: + the batch
        // loads into shared memory and the batch barriers (no copy, no
        // waves); 8: + the transposed copy (no waves); 4 (= L51's z): + the
        // entry waves without the AND.
        // L51 (experimental""")
rep("let wave = comptime!(ept * JOIN_WG);", "let wave = comptime!(ept * wg);")
rep("""        let bsq = comptime!(base * base);
        let mut t_lo""", """        let bsq = comptime!(base * base);
        let r_load = comptime!(if dbl & 1 != 0 { 2u32 } else { 1u32 });
        let r_copy = comptime!(if dbl & 2 != 0 { 2u32 } else { 1u32 });
        let r_and = comptime!(if dbl & 4 != 0 { 2u32 } else { 1u32 });
        let r_wave = comptime!(if dbl & 64 != 0 { 2u32 } else { 1u32 });
        let mut t_lo""")
rep("""        let nbk = comptime!(nkeys * m1);
        let mut w = CUBE_POS_X;
        while w < nwork {""", """        let nbk = comptime!(nkeys * m1);
        let mut w = CUBE_POS_X;
        if comptime!(abl == 5) {
            w = nwork;
        }
        while w < nwork {""")
rep("""                s_cum[0] = 0u32;
                #[unroll]
                for r in 0..nroots {
                    let c = s_cum[r as usize];
                    s_cum[comptime!(r + 1) as usize] += c;
                    s_db[r as usize] -= c;
                }
            }
            sync_cube();""", """                s_cum[0] = 0u32;
                #[unroll]
                for r in 0..nroots {
                    let c = s_cum[r as usize];
                    s_cum[comptime!(r + 1) as usize] += c;
                    s_db[r as usize] -= c;
                }
            }
            sync_cube();
            if comptime!(dbl & 128 != 0) {
                // DBL_BARRIERS: the work item's three barriers again.
                sync_cube();
                sync_cube();
                sync_cube();
            }""")
rep("""            let mut tc = 0u32;
            while tc < s_cum[nroots as usize] {""", """            let mut tc = 0u32;
            if comptime!(abl == 6) {
                tc = s_cum[nroots as usize];
            }
            while tc < s_cum[nroots as usize] {""")
rep("""                if comptime!(tcap <= JOIN_WG) {
                    if UNIT_POS_X < nt {
                        // Top q of the bucket: in the last segment that starts
                        // at or before it (the ones between are empty).
                        let q = tc + UNIT_POS_X;""", """                for rep in 0..r_load {
                if comptime!(tcap <= wg) {
                    if UNIT_POS_X < nt {
                        // Top q of the bucket: in the last segment that starts
                        // at or before it (the ones between are empty).
                        let q = tc + UNIT_POS_X + rep * zz;""")
rep("""                    let mut uu = UNIT_POS_X;
                    while uu < nt {
                        // Top q of the bucket: in the last segment that starts
                        // at or before it (the ones between are empty).
                        let q = tc + uu;""", """                    let mut uu = UNIT_POS_X;
                    while uu < nt {
                        // Top q of the bucket: in the last segment that starts
                        // at or before it (the ones between are empty).
                        let q = tc + uu + rep * zz;""")
rep("""                        uu += JOIN_WG;
                    }
                }
                sync_cube();
                if nt >= tmin {""", """                        uu += wg;
                    }
                }
                }
                sync_cube();
                if comptime!(dbl & 128 != 0) {
                    sync_cube();
                }
                if nt >= tmin && comptime!(abl != 7) {
                    for rep in 0..r_copy {""")
rep("""                    if comptime!(tcap == JOIN_WG) {
                        let cc = UNIT_POS_X / 32u32;""", """                    if comptime!(tcap == wg) {
                        let cc = UNIT_POS_X / 32u32;""")
rep("t_lo[(t0 + i) as usize]", "t_lo[(t0 + i + rep * zz) as usize]", 2)
rep("t_hi[(t0 + i) as usize]", "t_hi[(t0 + i + rep * zz) as usize]", 2)
rep("""                            cc += comptime!(JOIN_WG / 32);
                        }
                    }
                }
                sync_cube();
""", """                            cc += comptime!(wg / 32);
                        }
                    }
                    }
                }
                sync_cube();
                if comptime!(dbl & 128 != 0) {
                    sync_cube();
                }
""")
rep("""                let mut ws = 0u32;
                while ws < s_hd[2] {""", """                let mut ws = 0u32;
                if comptime!(abl == 7 || abl == 8) {
                    ws = s_hd[2];
                }
                while ws < s_hd[2] {""")
rep("""                    #[unroll]
                    for j in 0..ept {
                        let sl = ws + UNIT_POS_X + comptime!(j * JOIN_WG);""", """                    for rep in 0..r_wave {
                    #[unroll]
                    for j in 0..ept {
                        let sl = ws + UNIT_POS_X + comptime!(j * wg) + rep * zz;""")
rep("""                            rr[j as usize] = r0;
                        }
                    }
                    if comptime!(abl == 1 || abl == 2 || abl == 4) {""", """                            rr[j as usize] = r0;
                        }
                    }
                    }
                    if comptime!(abl == 1 || abl == 2 || abl == 4) {""")
rep("""                                let ab = cb * 64u32;
                                #[unroll]
                                for j in 0..ept {""", """                                let ab = cb * 64u32;
                                for rep in 0..r_and {
                                #[unroll]
                                for j in 0..ept {""")
rep("""                                        let a = ab + d;
                                        #[unroll]
                                        for c in 0..ag {
                                            acc[comptime!(c * ept + j) as usize] |=
                                                t_tr[(a + comptime!(c * 64)) as usize];
                                        }
                                    }
                                }
                            }""", """                                        let a = ab + d + rep * zz;
                                        #[unroll]
                                        for c in 0..ag {
                                            acc[comptime!(c * ept + j) as usize] |=
                                                t_tr[(a + comptime!(c * 64)) as usize];
                                        }
                                    }
                                }
                                }
                            }""")
rep("""                            let mut jt = jc;
                            let mut bit = 1u32;
                            while jt < cend {
                                let tlo = t_lo[jt as usize];
                                let thi = t_hi[jt as usize];
                                #[unroll]
                                for j in 0..ept {
                                    let z = (mlo[j as usize] & tlo) | (mhi[j as usize] & thi);
                                    pm[j as usize] |= select(z == 0u32, bit, 0u32);
                                }
                                bit <<= 1u32;
                                jt += 1u32;
                            }""", """                            for rep in 0..r_and {
                            let mut jt = jc;
                            let mut bit = 1u32;
                            while jt < cend {
                                let tlo = t_lo[(jt + rep * zz) as usize];
                                let thi = t_hi[(jt + rep * zz) as usize];
                                #[unroll]
                                for j in 0..ept {
                                    let z = (mlo[j as usize] & tlo) | (mhi[j as usize] & thi);
                                    pm[j as usize] |= select(z == 0u32, bit, 0u32);
                                }
                                bit <<= 1u32;
                                jt += 1u32;
                            }
                            }""")
rep("""                        #[unroll]
                        for j in 0..ept {
                            let mut x = pm[j as usize] & vv[j as usize];
                            let r0 = rr[j as usize];
                            while plane_any(x != 0u32) {""", """                        if comptime!(dbl & 8 != 0) {
                            // DBL_WALK: a shadow walk over the same bits (the
                            // rounds' vote, pop and lane bookkeeping), its
                            // checksum folded in through `zz` (0).
                            #[unroll]
                            for j in 0..ept {
                                let mut x = pm[j as usize] & vv[j as usize];
                                while plane_any(x != 0u32) {
                                    if x != 0u32 {
                                        npf ^= jc + x.trailing_zeros();
                                        x &= x - 1u32;
                                    }
                                    if walk_sync {
                                        sync_plane();
                                    }
                                }
                            }
                        }
                        #[unroll]
                        for j in 0..ept {
                            let mut x = pm[j as usize] & vv[j as usize];
                            let r0 = rr[j as usize];
                            while plane_any(x != 0u32) {""")
rep("""                                    let pass = if comptime!(lean) {""",
    """                                    let mut pass = if comptime!(lean) {""")
rep("""                                            k,
                                            k2,
                                        )
                                    };
                                    if comptime!(abl == 3) {""", """                                            k,
                                            k2,
                                        )
                                    };
                                    if comptime!(dbl & 16 != 0 && lean) {
                                        // DBL_PREFILTER: the same test again on
                                        // the same pair (jt2 + zz = jt2, ac ^ zz
                                        // = ac), ANDed in.
                                        let jz = jt2 + zz;
                                        let p2 = walk_pf_lean(
                                            ac[j as usize] ^ zz,
                                            ac3[j as usize],
                                            pc[j as usize],
                                            pc3[j as usize],
                                            t_dm[jz as usize],
                                            mlo[j as usize],
                                            mhi[j as usize],
                                            t_glo[jz as usize],
                                            t_ghi[jz as usize],
                                            base,
                                        );
                                        pass = pass && p2;
                                    }
                                    if comptime!(abl == 3) {""")
rep("""                if UNIT_POS_X < comptime!(tcap / 32) {
                    s_cw[UNIT_POS_X as usize].store(0u32);
                }
                tc += tcap;
                sync_cube();""", """                if UNIT_POS_X < comptime!(tcap / 32) {
                    s_cw[UNIT_POS_X as usize].store(0u32);
                }
                tc += tcap;
                sync_cube();
                if comptime!(dbl & 128 != 0) {
                    sync_cube();
                }""")
rep("""        if comptime!(abl == 3) {
            if npf == 0x9E37_79B9u32 {
                nand += 1u32;
            }
        }""", """        if comptime!(abl == 3) {
            if npf == 0x9E37_79B9u32 {
                nand += 1u32;
            }
        }
        if comptime!(dbl & 8 != 0 && abl == 0) {
            // The shadow walk's checksum, times zz = 0.
            nand += npf * zz;
        }""")
open(p, 'w').write(s)
print('patched N16 kernel', p)
