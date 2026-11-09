#!/usr/bin/env python3
"""patch54pr.py REPO: the PR form of L54's form 2 over d813aea (no knob): the transposed AND walks the entry's low
word's bits, then its high word's, and masks the table index so the per-chunk offsets fold into the loads."""
import sys
p = sys.argv[1] + '/common/src/cubecl_join.rs'
s = open(p).read()
def sub(old, new, cnt=1):
    global s
    assert s.count(old) == cnt, (old[:80], s.count(old))
    s = s.replace(old, new)
sub("""const AND_GROUP: u32 = 4;
// The transposed copy maps thread u to chunk u / 32 of the batch, and the
// groups tile the batch's chunks.
const _: () = assert!(
    JOIN_WG == TOP_CAP && TOP_CAP.is_multiple_of(32 * AND_GROUP) && TRANSPOSE_MIN <= TOP_CAP
);
""", """const AND_GROUP: u32 = 4;
/// Words of [`join_kernel`]'s transposed masks, `t_tr`: 64 digits for each
/// chunk of 32 tops.
const TR_WORDS: u32 = TOP_CAP / 32 * 64;
// The transposed copy maps thread u to chunk u / 32 of the batch, and the
// groups tile the batch's chunks. The AND masks its `t_tr` index to the
// table, so the table's size is a power of two.
const _: () = assert!(
    JOIN_WG == TOP_CAP
        && TOP_CAP.is_multiple_of(32 * AND_GROUP)
        && TRANSPOSE_MIN <= TOP_CAP
        && TR_WORDS.is_power_of_two()
);
""")
sub("""        AND_GROUP, DEAD_MASK, JOIN_WG, MAX_ROOTS, SURV_FLUSH, SURV_SH_CAP, TOP_CAP, TOP_REC_WORDS,
        TRANSPOSE_MIN,
    };""", """        AND_GROUP, DEAD_MASK, JOIN_WG, MAX_ROOTS, SURV_FLUSH, SURV_SH_CAP, TOP_CAP, TOP_REC_WORDS,
        TR_WORDS, TRANSPOSE_MIN,
    };""")
sub("""        let mut t_tr = SharedMemory::<u32>::new(comptime!((TOP_CAP / 32 * 64) as usize));
""", """        let mut t_tr = SharedMemory::<u32>::new(comptime!(TR_WORDS as usize));
""")
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
new = """                                let ab = cb * 64u32;
                                #[unroll]
                                for j in 0..ept {
                                    // The entry's digits: the low word's set
                                    // bits, then the high word's (x takes y
                                    // once it is empty, and the rows move to
                                    // the upper 32); an empty slot (vv = 0)
                                    // has none. One word to walk at a time
                                    // keeps the per-digit choice of word out
                                    // of the loop.
                                    let mut x = mlo[j as usize] & vv[j as usize];
                                    let mut y = mhi[j as usize] & vv[j as usize];
                                    let ab_hi = ab + 32u32;
                                    let e0 = x == 0u32;
                                    x = select(e0, y, x);
                                    y = select(e0, 0u32, y);
                                    let mut row = select(e0, ab_hi, ab);
                                    while x != 0u32 {
                                        // x != 0: its lowest set bit.
                                        let d = x.find_first_set() - 1u32;
                                        let x1 = x & (x - 1u32);
                                        let e = x1 == 0u32;
                                        // Masking the index to the table
                                        // changes nothing (row + d + 64c is
                                        // below TR_WORDS), but it lets the
                                        // compiler prove that adding 64c
                                        // cannot wrap: the group's four loads
                                        // then share one address and take
                                        // 64c as their offset, instead of
                                        // each forming its own.
                                        let a = (row + d) & comptime!(TR_WORDS - 1);
                                        x = select(e, y, x1);
                                        y = select(e, 0u32, y);
                                        row = select(e, ab_hi, row);
                                        #[unroll]
                                        for c in 0..ag {
                                            acc[comptime!(c * ept + j) as usize] |=
                                                t_tr[(a + comptime!(c * 64)) as usize];
                                        }
                                    }
                                }
"""
sub(old, new)
open(p, 'w').write(s)
print('patched', p)
