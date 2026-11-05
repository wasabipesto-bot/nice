#!/usr/bin/env python3
"""add_rounds.py IN OUT {M|G|Q}: add the test-only walk counter NICE_EXP_JOIN_ROUNDS to a join kernel source.
0 off (the kernel as is); 1: and_count = plane-rounds of the walk (lane 0 of each plane adds 1 per round);
2: plane-chunks (32-top chunks of a batch the plane visits); 3: plane-groups (AND groups of 4 chunks)."""
import sys
src, dst, kind = sys.argv[1:4]
s = open(src).read()
def rep(old, new, n=1):
    global s
    assert s.count(old) == n, (old, s.count(old))
    s = s.replace(old, new)
# host side
rep("""        #[comptime] walk_sync: bool,
    ) {
        let m1 = comptime!(base - 1);
        let nkeys = comptime!(if key_level { base } else { 1 });
        let wave = comptime!(ept * JOIN_WG);""",
"""        #[comptime] walk_sync: bool,
        #[comptime] rounds: u32,
    ) {
        let m1 = comptime!(base - 1);
        let nkeys = comptime!(if key_level { base } else { 1 });
        let wave = comptime!(ept * JOIN_WG);""")
rep("""    walk_sync: bool,
    limbs: u32,""", """    walk_sync: bool,
    /// Test only (`NICE_EXP_JOIN_ROUNDS`): the walk counter in `and_count`.
    rounds: u32,
    limbs: u32,""")
rep("""                    .contains(cubecl::ir::features::Plane::Sync),
            limbs,""", """                    .contains(cubecl::ir::features::Plane::Sync),
            rounds: std::env::var("NICE_EXP_JOIN_ROUNDS")
                .ok()
                .and_then(|v| v.parse().ok())
                .unwrap_or(0),
            limbs,""")
rep("""                self.walk_sync,
            );""", """                self.walk_sync,
                self.rounds,
            );""")
lane0 = "UNIT_POS_PLANE == 0u32"
if kind == 'M':
    # per chunk: count chunks / groups at the chunk loop's top
    rep("""                        let mut pm = Array::<u32>::new(ept as usize);
                        if nt >= TRANSPOSE_MIN {
                            let cb = jc / 32u32;""",
"""                        let mut pm = Array::<u32>::new(ept as usize);
                        if comptime!(rounds == 2) {
                            if %s {
                                nand += 1u32;
                            }
                        }
                        if comptime!(rounds == 3) {
                            if %s && (jc / 32u32) %% comptime!(AND_GROUP) == 0u32 {
                                nand += 1u32;
                            }
                        }
                        if nt >= TRANSPOSE_MIN {
                            let cb = jc / 32u32;""" % (lane0, lane0))
    rep("""                            while plane_any(x != 0u32) {
                                if x != 0u32 {""", """                            while plane_any(x != 0u32) {
                                if comptime!(rounds == 1) {
                                    if %s {
                                        nand += 1u32;
                                    }
                                }
                                if x != 0u32 {""" % lane0)
    rep("""                                    if r0 >= t_rlo[jt2 as usize] && r0 < t_rhi[jt2 as usize] {
                                        nand += 1u32;""", """                                    if r0 >= t_rlo[jt2 as usize] && r0 < t_rhi[jt2 as usize] {
                                        if comptime!(rounds == 0) {
                                            nand += 1u32;
                                        }""")
elif kind == 'Q':
    # the final form (the group walk for every batch, words formed per branch): modes 2/3 at the walk's comment
    rep("""                        // Each lane walks the group's set bits as one set,
""", """                        if comptime!(rounds == 2) {
                            if %s {
                                let nc = (nt - jc + 31u32) / 32u32;
                                let gc = select(nt >= TRANSPOSE_MIN, comptime!(AND_GROUP), 1u32);
                                nand += select(nc > gc, gc, nc);
                            }
                        }
                        if comptime!(rounds == 3) {
                            if %s && (jc / 32u32) %% comptime!(AND_GROUP) == 0u32 {
                                nand += 1u32;
                            }
                        }
                        // Each lane walks the group's set bits as one set,
""" % (lane0, lane0))
    rep("""                        while plane_any((x | nm) != 0u32) {
                            if (x | nm) != 0u32 {""", """                        while plane_any((x | nm) != 0u32) {
                            if comptime!(rounds == 1) {
                                if %s {
                                    nand += 1u32;
                                }
                            }
                            if (x | nm) != 0u32 {""" % lane0)
    rep("""                                if r0 >= t_rlo[jt2 as usize] && r0 < t_rhi[jt2 as usize] {
                                    nand += 1u32;""", """                                if r0 >= t_rlo[jt2 as usize] && r0 < t_rhi[jt2 as usize] {
                                    if comptime!(rounds == 0) {
                                        nand += 1u32;
                                    }""")
else:
    rep("""                        let mut nm = 0u32;
                        #[unroll]
                        for i in 0..nw {""", """                        if comptime!(rounds == 2) {
                            if %s {
                                let nc = (nt - jc + 31u32) / 32u32;
                                nand += select(nc > comptime!(AND_GROUP), comptime!(AND_GROUP), nc);
                            }
                        }
                        if comptime!(rounds == 3) {
                            if %s {
                                nand += 1u32;
                            }
                        }
                        let mut nm = 0u32;
                        #[unroll]
                        for i in 0..nw {""" % (lane0, lane0))
    rep("""                        while plane_any((x | nm) != 0u32) {
                            if (x | nm) != 0u32 {""", """                        while plane_any((x | nm) != 0u32) {
                            if comptime!(rounds == 1) {
                                if %s {
                                    nand += 1u32;
                                }
                            }
                            if (x | nm) != 0u32 {""" % lane0)
    rep("""                                if r0 >= t_rlo[jt2 as usize] && r0 < t_rhi[jt2 as usize] {
                                    nand += 1u32;""", """                                if r0 >= t_rlo[jt2 as usize] && r0 < t_rhi[jt2 as usize] {
                                    if comptime!(rounds == 0) {
                                        nand += 1u32;
                                    }""")
open(dst, 'w').write(s)
