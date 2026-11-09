#!/usr/bin/env python3
"""patch54.py REPO: the L54 experiment over d813aea: `join_kernel` takes a comptime `and_form` (env NICE_EXP_AND_FORM,
read in JoinDevice::new; default 0) choosing the transposed AND's digit loop:
  0  d813aea's loop (merged lo/hi walk, t_tr[ab + d + 64c])
  1  fold only: the index masked to the table, (ab + d) & (TR_WORDS - 1), so the +64c fold into the loads
  2  swap + mask: walk x, then y (x = y once x is empty, the base + 32 from then on), no per-digit word select;
     index (sb + bit) & (TR_WORDS - 1)
  3  swap + 4 arrays: the group's AND_GROUP chunks in 4 shared arrays (t4a..t4d), the same index for each
     (g·64 + d), no mask"""
import sys, re
p = sys.argv[1] + '/common/src/cubecl_join.rs'
s = open(p).read()
def sub(old, new, cnt=1):
    global s
    assert s.count(old) == cnt, (old[:80], s.count(old))
    s = s.replace(old, new)
# constants
sub("""const AND_GROUP: u32 = 4;
""", """const AND_GROUP: u32 = 4;
/// Words of the transposed table `t_tr` (L54: a power of two, so an index
/// masked to it is provably in range).
const TR_WORDS: u32 = TOP_CAP / 32 * 64;
const _: () = assert!(TR_WORDS.is_power_of_two() && AND_GROUP == 4);
""")
sub("""        AND_GROUP, DEAD_MASK, JOIN_WG, MAX_ROOTS, SURV_FLUSH, SURV_SH_CAP, TOP_CAP, TOP_REC_WORDS,
        TRANSPOSE_MIN,
    };""", """        AND_GROUP, DEAD_MASK, JOIN_WG, MAX_ROOTS, SURV_FLUSH, SURV_SH_CAP, TOP_CAP, TOP_REC_WORDS,
        TR_WORDS, TRANSPOSE_MIN,
    };""")
# kernel signature
sub("""        #[comptime] walk_sync: bool,
    ) {
        let m1 = comptime!(base - 1);""", """        #[comptime] walk_sync: bool,
        #[comptime] and_form: u32,
    ) {
        let m1 = comptime!(base - 1);""")
# arrays
sub("""        let mut t_tr = SharedMemory::<u32>::new(comptime!((TOP_CAP / 32 * 64) as usize));
""", """        let mut t_tr = SharedMemory::<u32>::new(comptime!((TOP_CAP / 32 * 64) as usize));
        // L54 form 3: chunk 4g + k of the batch at t4k[g·64 + d].
        let mut t4a = SharedMemory::<u32>::new(comptime!(if and_form == 3 {
            (TOP_CAP / 32 / AND_GROUP * 64) as usize
        } else {
            1
        }));
        let mut t4b = SharedMemory::<u32>::new(comptime!(if and_form == 3 {
            (TOP_CAP / 32 / AND_GROUP * 64) as usize
        } else {
            1
        }));
        let mut t4c = SharedMemory::<u32>::new(comptime!(if and_form == 3 {
            (TOP_CAP / 32 / AND_GROUP * 64) as usize
        } else {
            1
        }));
        let mut t4d = SharedMemory::<u32>::new(comptime!(if and_form == 3 {
            (TOP_CAP / 32 / AND_GROUP * 64) as usize
        } else {
            1
        }));
""")
# copy
sub("""                    t_tr[(cc * 64u32 + dl) as usize] = w0;
                    t_tr[(cc * 64u32 + 32u32 + dl) as usize] = w1;
                }
                sync_cube();
""", """                    if comptime!(and_form == 3) {
                        let k4 = cc % 4u32;
                        let r4 = (cc / 4u32) * 64u32 + dl;
                        if k4 == 0u32 {
                            t4a[r4 as usize] = w0;
                            t4a[(r4 + 32u32) as usize] = w1;
                        } else if k4 == 1u32 {
                            t4b[r4 as usize] = w0;
                            t4b[(r4 + 32u32) as usize] = w1;
                        } else if k4 == 2u32 {
                            t4c[r4 as usize] = w0;
                            t4c[(r4 + 32u32) as usize] = w1;
                        } else {
                            t4d[r4 as usize] = w0;
                            t4d[(r4 + 32u32) as usize] = w1;
                        }
                    } else {
                        t_tr[(cc * 64u32 + dl) as usize] = w0;
                        t_tr[(cc * 64u32 + 32u32 + dl) as usize] = w1;
                    }
                }
                sync_cube();
""")
# AND loop
old = """                                let ab = cb * 64u32;
                                #[unroll]
                                for j in 0..ept {
                                    // The entry's digits, low word first; an
                                    // empty slot (vv = 0) has none.
                                    let mut x = mlo[j as usize] & vv[j as usize];
                                    let mut y = mhi[j as usize] & vv[j as usize];
                                    while (x | y) != 0u32 {
                                        let lo = x != 0u32;
                                        let v = select(lo, x, y);
                                        // v != 0: its lowest set bit.
                                        let d =
                                            (v.find_first_set() - 1u32) + select(lo, 0u32, 32u32);
                                        let v1 = v & (v - 1u32);
                                        x = select(lo, v1, x);
                                        y = select(lo, y, v1);
                                        let a = ab + d;
                                        #[unroll]
                                        for c in 0..ag {
                                            acc[comptime!(c * ept + j) as usize] |=
                                                t_tr[(a + comptime!(c * 64)) as usize];
                                        }
                                    }
                                }
"""
new = """                                let ab = if comptime!(and_form == 3) {
                                    cb * 16u32
                                } else {
                                    cb * 64u32
                                };
                                #[unroll]
                                for j in 0..ept {
                                    // The entry's digits, low word first; an
                                    // empty slot (vv = 0) has none.
                                    let mut x = mlo[j as usize] & vv[j as usize];
                                    let mut y = mhi[j as usize] & vv[j as usize];
                                    if comptime!(and_form < 2) {
                                        while (x | y) != 0u32 {
                                            let lo = x != 0u32;
                                            let v = select(lo, x, y);
                                            // v != 0: its lowest set bit.
                                            let d = (v.find_first_set() - 1u32)
                                                + select(lo, 0u32, 32u32);
                                            let v1 = v & (v - 1u32);
                                            x = select(lo, v1, x);
                                            y = select(lo, y, v1);
                                            let a = if comptime!(and_form == 1) {
                                                (ab + d) & comptime!(TR_WORDS - 1)
                                            } else {
                                                ab + d
                                            };
                                            #[unroll]
                                            for c in 0..ag {
                                                acc[comptime!(c * ept + j) as usize] |=
                                                    t_tr[(a + comptime!(c * 64)) as usize];
                                            }
                                        }
                                    } else {
                                        // Walk x's bits, then y's: once x is
                                        // empty it takes y (and y 0), and the
                                        // row base moves to the high half.
                                        let ab_hi = ab + 32u32;
                                        let e0 = x == 0u32;
                                        x = select(e0, y, x);
                                        y = select(e0, 0u32, y);
                                        let mut sb = select(e0, ab_hi, ab);
                                        while x != 0u32 {
                                            let bit = x.find_first_set() - 1u32;
                                            let x1 = x & (x - 1u32);
                                            let e = x1 == 0u32;
                                            let a = if comptime!(and_form == 2) {
                                                (sb + bit) & comptime!(TR_WORDS - 1)
                                            } else {
                                                sb + bit
                                            };
                                            x = select(e, y, x1);
                                            y = select(e, 0u32, y);
                                            sb = select(e, ab_hi, sb);
                                            if comptime!(and_form == 2) {
                                                #[unroll]
                                                for c in 0..ag {
                                                    acc[comptime!(c * ept + j) as usize] |=
                                                        t_tr[(a + comptime!(c * 64)) as usize];
                                                }
                                            } else {
                                                acc[j as usize] |= t4a[a as usize];
                                                acc[comptime!(ept + j) as usize] |= t4b[a as usize];
                                                acc[comptime!(2 * ept + j) as usize] |=
                                                    t4c[a as usize];
                                                acc[comptime!(3 * ept + j) as usize] |=
                                                    t4d[a as usize];
                                            }
                                        }
                                    }
                                }
"""
sub(old, new)
# struct field, init, launch
sub("""    walk_sync: bool,
    limbs: u32,""", """    walk_sync: bool,
    /// L54: the transposed AND's digit-loop form (`NICE_EXP_AND_FORM`).
    and_form: u32,
    limbs: u32,""")
sub("""                    .contains(cubecl::ir::features::Plane::Sync),
            limbs,""", """                    .contains(cubecl::ir::features::Plane::Sync),
            and_form: std::env::var("NICE_EXP_AND_FORM")
                .ok()
                .and_then(|v| v.parse().ok())
                .unwrap_or(0),
            limbs,""")
sub("""                self.k2,
                self.walk_sync,
            );""", """                self.k2,
                self.walk_sync,
                self.and_form,
            );""")
open(p, 'w').write(s)
print('patched', p)
