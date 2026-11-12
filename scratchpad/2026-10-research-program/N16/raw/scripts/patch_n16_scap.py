#!/usr/bin/env python3
"""N16: NICE_EXP_JOIN_SCAP, the join's shared survivor stage in entries (SURV_SH_CAP, 1024 = 8 KiB of the cube's
18.5 KiB of shared memory), a comptime parameter; exact (a full stage sends pairs to the list directly).
python3 patch_n16_scap.py TREE"""
import sys
p = sys.argv[1] + '/common/src/cubecl_join.rs'
s = open(p).read()
def rep(a, b, cnt=1):
    global s
    assert s.count(a) == cnt, (s.count(a), a[:80])
    s = s.replace(a, b)
rep("""        #[comptime] wg: u32,
        #[comptime] dbl: u32,
        zz: u32,""", """        #[comptime] wg: u32,
        #[comptime] dbl: u32,
        #[comptime] scap: u32,
        zz: u32,""")
rep("""        let mut s_t = SharedMemory::<u32>::new(comptime!(SURV_SH_CAP as usize));
        let mut s_r = SharedMemory::<u32>::new(comptime!(SURV_SH_CAP as usize));""",
    """        let mut s_t = SharedMemory::<u32>::new(comptime!(scap as usize));
        let mut s_r = SharedMemory::<u32>::new(comptime!(scap as usize));""")
rep("                                        if at < SURV_SH_CAP {", "                                        if at < scap {")
rep("""        out_cap: u32,
        sc: u32,
    ) {
        let mut n = sc;
        if n > SURV_SH_CAP {
            n = SURV_SH_CAP; // the rest went to `out` from the walk""", """        out_cap: u32,
        sc: u32,
        #[comptime] scap: u32,
    ) {
        let mut n = sc;
        if n > scap {
            n = scap; // the rest went to `out` from the walk""")
# every call passes scap after sc
import re
n0 = s.count("flush_survivors(")
s = re.sub(r"(flush_survivors\(\n(?:\s+[^\n]+\n){7}(\s+)sc,\n)", lambda m: m.group(1) + m.group(2) + "scap,\n", s)
assert s.count("                            scap,\n") + s.count("                        scap,\n") + s.count("                    scap,\n") >= 3, 'calls'
rep("        DEAD_MASK, JOIN_WG, MAX_ROOTS, SURV_SH_CAP, TOP_REC_WORDS,", "        DEAD_MASK, JOIN_WG, MAX_ROOTS, TOP_REC_WORDS,")
# host
rep("""    wg: u32,
    dbl: u32,
    limbs: u32,""", """    wg: u32,
    dbl: u32,
    /// N16: the shared survivor stage's entries (`NICE_EXP_JOIN_SCAP`).
    scap: u32,
    limbs: u32,""")
rep("""            dbl: exp_env("NICE_EXP_JOIN_DBL", 0),""", """            dbl: exp_env("NICE_EXP_JOIN_DBL", 0),
            scap: exp_env("NICE_EXP_JOIN_SCAP", SURV_SH_CAP),""")
rep("""                self.wg,
                self.dbl,
                0u32,""", """                self.wg,
                self.dbl,
                self.scap,
                0u32,""")
open(p, 'w').write(s)
print('patched scap', p)
