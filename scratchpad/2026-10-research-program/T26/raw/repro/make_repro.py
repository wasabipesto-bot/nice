#!/usr/bin/env python3
"""make_repro.py IN OUT: main 41b4b405's cubecl_join.rs -> a test-only reproduction tree. The top kernels and
`top_slot` are unchanged; added: a cube size for the top stage (`top_wg`, tests), a comptime test bit on
top_fd_kernel (TOP_LANE0_OUT: every plane's lane 0 appends its top with its own atomic and sits out the plane's
append, so the rest of the plane runs `top_slot` without lane 0), and `repro_*` tests that run the FD kernel against
top_kernel on partly filled planes / planes without lane 0 and COUNT what goes wrong instead of stopping at the first
difference."""
import sys
src, dst = sys.argv[1], sys.argv[2]
s = open(src).read()
def rep(old, new, cnt=1):
    global s
    assert s.count(old) == cnt, (old[:80], s.count(old))
    s = s.replace(old, new)
rep("const STAGES: usize = 4;\n", "const STAGES: usize = 4;\n/// Repro test bit: lane 0 of every plane appends alone.\npub(crate) const TOP_LANE0_OUT: u32 = 1;\n")
rep("""        AND_GROUP, DEAD_MASK, JOIN_WG, MAX_ROOTS, SURV_FLUSH, SURV_SH_CAP, TOP_CAP, TOP_REC_WORDS,
        TRANSPOSE_MIN,
    };""", """        AND_GROUP, DEAD_MASK, JOIN_WG, MAX_ROOTS, SURV_FLUSH, SURV_SH_CAP, TOP_CAP, TOP_LANE0_OUT,
        TOP_REC_WORDS, TRANSPOSE_MIN,
    };""")
rep("""        #[comptime] tq: u32,
        #[comptime] ballot: bool,
    ) {
        let nl2 = comptime!(2 * limbs);""", """        #[comptime] tq: u32,
        #[comptime] ballot: bool,
        #[comptime] test: u32,
    ) {
        let nl2 = comptime!(2 * limbs);""")
rep("""                let rec = top_slot(kept, tl_g, tl_off, slot, ntlay, grp_cnt, nb, ballot);
""", """                let rec = if comptime!(test & TOP_LANE0_OUT != 0) {
                    let mut r = 0u32;
                    if UNIT_POS_PLANE == 0u32 {
                        if kept {
                            r = slot * ntlay
                                + tl_off
                                + grp_cnt[(slot * nb + tl_g) as usize].fetch_add(1u32);
                        }
                    } else {
                        r = top_slot(kept, tl_g, tl_off, slot, ntlay, grp_cnt, nb, ballot);
                    }
                    r
                } else {
                    top_slot(kept, tl_g, tl_off, slot, ntlay, grp_cnt, nb, ballot)
                };
""")
rep("""    top_fd_min: u32,
""", """    top_fd_min: u32,
    top_wg: u32,
""")
rep("""            top_fd_min: TOP_FD_MIN_UNITS,
""", """            top_fd_min: TOP_FD_MIN_UNITS,
            top_wg: JOIN_WG,
""")
rep("""        let nslots_u32 = u32::try_from(nslots).expect("a batch fits u32");
        let top_cubes = self.ntlay.div_ceil(JOIN_WG).max(1);""", """        let nslots_u32 = u32::try_from(nslots).expect("a batch fits u32");
        let top_cubes = self.ntlay.div_ceil(self.top_wg).max(1);""")
rep("""        let ran = ran.clone();
        unsafe {
            if fd {""", """        let ran = ran.clone();
        #[cfg(not(test))]
        let test = 0;
        #[cfg(test)]
        let test = tests::TOP_TEST_BITS.with(std::cell::Cell::get);
        unsafe {
            if fd {""")
rep("""                    CubeCount::Static(top_cubes, groups, 1),
                    CubeDim::new_1d(JOIN_WG),""", """                    CubeCount::Static(top_cubes, groups, 1),
                    CubeDim::new_1d(self.top_wg),""")
rep("""                    self.tq,
                    self.ballot,
                );""", """                    self.tq,
                    self.ballot,
                    test,
                );""")
rep("""                    CubeCount::Static(top_cubes, nslots_u32, 1),
                    CubeDim::new_1d(JOIN_WG),""", """                    CubeCount::Static(top_cubes, nslots_u32, 1),
                    CubeDim::new_1d(self.top_wg),""")
rep("""        let top_cubes = self.ntlay.div_ceil(JOIN_WG).max(1);
        let nslots = u32::try_from(vs.len()).expect("a batch fits u32");""", """        let top_cubes = self.ntlay.div_ceil(self.top_wg).max(1);
        let nslots = u32::try_from(vs.len()).expect("a batch fits u32");""")
rep("""        pub(super) static REFUSE_ABOVE: std::cell::Cell<usize> =
            const { std::cell::Cell::new(usize::MAX) };
    }
""", """        pub(super) static REFUSE_ABOVE: std::cell::Cell<usize> =
            const { std::cell::Cell::new(usize::MAX) };
        pub(super) static TOP_TEST_BITS: std::cell::Cell<u32> =
            const { std::cell::Cell::new(0) };
    }
""")
anchor = """    /// The FD kernel keeps each power's c0 = max(k, ndig(e^k - a^k)) from
    /// slot to slot"""
rep(anchor, open(__file__.replace('make_repro.py', 'repro_tests.rs')).read() + anchor)
open(dst, 'w').write(s)
print('ok', dst)
