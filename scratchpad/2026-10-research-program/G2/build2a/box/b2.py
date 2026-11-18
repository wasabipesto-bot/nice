import sys
p = sys.argv[1]
mode = sys.argv[2]  # "B" or "A": which compact kernel the file holds
s = open(p).read()


def rep(old, new, cnt=1):
    global s
    n = s.count(old)
    assert n == cnt, (old[:80], n)
    s = s.replace(old, new)


# main kernel: the entry's second word is the child's position in the job list; no loads in the kernel
rep("""                            // (midout) survivor-list entries straight from the words: (top, r0) per set bit, the
                            // child's r4 from the job's child list; a plane's entries of one step are contiguous in
                            // its slab (or in fresh consecutive slabs when they do not fit), so the step costs one
                            // scan and, per SLAB entries, one atomic""",
    """                            // (midout) one entry per set bit straight from the words: (top, the child's position in
                            // the job's child list), stores only (the compaction reads the child's r4); a plane's
                            // entries of one step are contiguous in its slab (or in fresh consecutive slabs when
                            // they do not fit), so the step costs one scan and, per SLAB entries, one atomic""")
rep("""                                            out[(2u32 * o + 1u32) as usize] =
                                                clst[(lp + b) as usize] + r0hi;""",
    """                                            out[(2u32 * o + 1u32) as usize] = lp + b;""")
rep("""                                            out[(2u32 * o + 1u32) as usize] =
                                                clst[(lp + 32u32 + b) as usize] + r0hi;""",
    """                                            out[(2u32 * o + 1u32) as usize] = lp + 32u32 + b;""")
rep("""            if comptime!(mode == 2 && !noout) {
                // (midout) phase 1's child-list stores, read by other threads of the cube in 3b
                sync_storage();
            }
""", "")
rep("""        clst: &mut Array<u32>,
        c0: u32,
        // (midout) the slice's digit 4 at bits 24-29 of r0 = n mod 2^30
        r0hi: u32,
        #[comptime] mode: u32,""", """        clst: &mut Array<u32>,
        c0: u32,
        #[comptime] mode: u32,""")
rep("""                        *c0,
                        ((pip & 63) as u32) << 24,
                        2u32,""", """                        *c0,
                        2u32,""")
if mode == "B":
    rep("""        ent: &Array<u32>,
        slabn: &Array<u32>,
        slabcnt: &Array<u32>,
        lcnt: &Array<u32>,
        surv: &mut Array<u32>,""", """        ent: &Array<u32>,
        slabn: &Array<u32>,
        slabcnt: &Array<u32>,
        lcnt: &Array<u32>,
        lst: &Array<u32>,
        surv: &mut Array<u32>,""")
    rep("""        nslab_cap: u32,
        scap: u32,
    ) {
        if ABSOLUTE_POS_X == 0u32 {""", """        nslab_cap: u32,
        scap: u32,
        r0hi: u32,
    ) {
        if ABSOLUTE_POS_X == 0u32 {""")
    rep("""                    surv[(2u32 * o + 1u32) as usize] = ent[(2u32 * i + 1u32) as usize];""",
        """                    surv[(2u32 * o + 1u32) as usize] = lst[ent[(2u32 * i + 1u32) as usize] as usize] + r0hi;""")
    rep("""                        a(&self.lcnt, 1),
                        a(&self.surv, 2 * self.scap as usize),
                        a(&scount, 1),
                        a(&stat, 2),
                        self.nslab_cap,
                        self.scap,
                    );""", """                        a(&self.lcnt, 1),
                        a(&self.clst, self.lcap as usize),
                        a(&self.surv, 2 * self.scap as usize),
                        a(&scount, 1),
                        a(&stat, 2),
                        self.nslab_cap,
                        self.scap,
                        ((pip & 63) as u32) << 24,
                    );""")
    rep("""    /// The main kernel's slabs → production's dense survivor list `(top,
    /// r0)`, `n = P·b^5 + r0`: each plane takes the used slabs in a
    /// grid-stride loop, reserves its slab's count with one atomic and copies
    /// the entries.""", """    /// The main kernel's slabs → production's dense survivor list `(top,
    /// r0)`, `n = P·b^5 + r0`: each plane takes the used slabs in a
    /// grid-stride loop, reserves its slab's count with one atomic and copies
    /// the entries, the child's r4 read from the child list (`lst`, at the
    /// entry's position; a slab's entries share a round's few chunks, so
    /// these reads stay in cache).""")
else:
    rep("""        lcnt: &Array<u32>,
        top_rec: &Array<u32>,
        surv: &mut Array<u32>,""", """        lcnt: &Array<u32>,
        lst: &Array<u32>,
        top_rec: &Array<u32>,
        surv: &mut Array<u32>,""")
    rep("""        nslab_cap: u32,
        scap: u32,
        #[comptime] w: u32,
    ) {""", """        nslab_cap: u32,
        scap: u32,
        r0hi: u32,
        #[comptime] w: u32,
    ) {""")
    rep("""            let cnt = slabcnt[s as usize];
            read += cnt;
            let mut keep = 0u32;
            for j in 0..per {
                let r = lane + j * w;
                if r < cnt {
                    let i = s * SLAB + r;
                    let rb = 8u32 * ent[(2u32 * i) as usize];
                    if pf(
                        ent[(2u32 * i + 1u32) as usize],""", """            let cnt = slabcnt[s as usize];
            read += cnt;
            let mut keep = 0u32;
            for j in 0..per {
                let r = lane + j * w;
                if r < cnt {
                    let i = s * SLAB + r;
                    let rb = 8u32 * ent[(2u32 * i) as usize];
                    if pf(
                        lst[ent[(2u32 * i + 1u32) as usize] as usize] + r0hi,""")
    rep("""                if o < scap {
                    surv[(2u32 * o) as usize] = ent[(2u32 * i) as usize];
                    surv[(2u32 * o + 1u32) as usize] = ent[(2u32 * i + 1u32) as usize];
                }""", """                if o < scap {
                    surv[(2u32 * o) as usize] = ent[(2u32 * i) as usize];
                    surv[(2u32 * o + 1u32) as usize] =
                        lst[ent[(2u32 * i + 1u32) as usize] as usize] + r0hi;
                }""")
    rep("""                        a(&self.lcnt, 1),
                        a(&self.top_rec, nt * 8),
                        a(&self.surv, 2 * self.scap as usize),
                        a(&scount, 1),
                        a(&stat, 3),
                        self.nslab_cap,
                        self.scap,
                        self.w,""", """                        a(&self.lcnt, 1),
                        a(&self.clst, self.lcap as usize),
                        a(&self.top_rec, nt * 8),
                        a(&self.surv, 2 * self.scap as usize),
                        a(&scount, 1),
                        a(&stat, 3),
                        self.nslab_cap,
                        self.scap,
                        ((pip & 63) as u32) << 24,
                        self.w,""")
open(p, 'w').write(s)
