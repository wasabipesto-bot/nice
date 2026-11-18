import sys
p = sys.argv[1]
s = open(p).read()


def rep(old, new, cnt=1):
    global s
    n = s.count(old)
    assert n == cnt, (old[:80], n)
    s = s.replace(old, new)


# tscan also clears the parents' histogram and list count (tdigz2's side duty before)
rep("""    /// One cube of 1,024: segment starts (tseg pairs), cursors, the top count
    /// in tstat[0] and the prefixes certified (the valid parents) in tstat[2].
    #[cube(launch_unchecked)]
    pub fn tscan_kernel(
        segc: &Array<u32>,
        tseg: &mut Array<u32>,
        cur: &mut Array<Atomic<u32>>,
        tstat: &mut Array<u32>,
        l5n: &Array<u32>,
    ) {
        let mut sums = SharedMemory::<u32>::new(1024usize);
        let t = UNIT_POS_X;
        if t == 0u32 {
            tstat[2usize] = l5n[0usize];
        }""", """    /// One cube of 1,024: segment starts (tseg pairs), cursors, the top count
    /// in tstat[0] and the prefixes certified (the valid parents) in tstat[2];
    /// also clears the parents' histogram and list count for the slice's
    /// preparation.
    #[cube(launch_unchecked)]
    pub fn tscan_kernel(
        segc: &Array<u32>,
        tseg: &mut Array<u32>,
        cur: &mut Array<Atomic<u32>>,
        tstat: &mut Array<u32>,
        l5n: &Array<u32>,
        hist: &mut Array<u32>,
        lcnt: &mut Array<u32>,
    ) {
        let mut sums = SharedMemory::<u32>::new(1024usize);
        let t = UNIT_POS_X;
        if t == 0u32 {
            tstat[2usize] = l5n[0usize];
            lcnt[0usize] = 0u32;
        }
        let mut z = t;
        while z < 16128u32 {
            hist[z as usize] = 0u32;
            z += 1024u32;
        }""")
rep("""    /// Each certified prefix into its segment: tmask and thd = h | d << 16,
    /// and tmhi, the prefilter's mask (its digits at positions >= 12).
    #[cube(launch_unchecked)]
    pub fn tops2_kernel(
        tm: &Array<u64>,
        thm: &Array<u64>,
        tv: &Array<u32>,
        cur: &mut Array<Atomic<u32>>,
        tmask: &mut Array<u64>,
        thd: &mut Array<u32>,
        tmhi: &mut Array<u64>,
        l5: &Array<u32>,
        l5n: &Array<u32>,
        cap: u32,
    ) {""", """    /// Each certified prefix into its segment: tmask and thd = h | d << 16,
    /// tmhi (the prefilter's mask, its digits at positions >= 12), its digits
    /// for the main kernel (`tdig`: 20 6-bit fields in 4 words, padded with
    /// the first) and production's top record (P = n div b^5 and w6).
    #[cube(launch_unchecked)]
    pub fn tops2_kernel(
        tm: &Array<u64>,
        thm: &Array<u64>,
        tv: &Array<u32>,
        cur: &mut Array<Atomic<u32>>,
        tmask: &mut Array<u64>,
        thd: &mut Array<u32>,
        tmhi: &mut Array<u64>,
        tdig: &mut Array<u32>,
        top_rec: &mut Array<u32>,
        l5: &Array<u32>,
        l5n: &Array<u32>,
        pip_hi: u32,
        cap: u32,
    ) {""")
rep("""                    tmhi[slot as usize] = thm[i as usize];
                }""", """                    tmhi[slot as usize] = thm[i as usize];
                    let mut x = tm[i as usize];
                    let first = x.trailing_zeros();
                    let mut dw = Array::<u32>::new(4usize);
                    #[unroll]
                    for k in 0..4u32 {
                        dw[k as usize] = 0u32;
                    }
                    #[unroll]
                    for k in 0..20u32 {
                        let v = select(x != 0u64, x.trailing_zeros(), first);
                        x &= x - select(x != 0u64, 1u64, 0u64);
                        dw[comptime!(k / 5) as usize] |= v << comptime!(6 * (k % 5));
                    }
                    #[unroll]
                    for k in 0..4u32 {
                        tdig[(slot * 4u32 + k) as usize] = dw[k as usize];
                    }
                    let w6 = (d << 24u32) | pip_hi;
                    let o = 8u32 * slot;
                    top_rec[o as usize] = ((h & 3u32) << 30u32) | w6;
                    top_rec[(o + 1u32) as usize] = h >> 2u32;
                    top_rec[(o + 2u32) as usize] = 0u32;
                    top_rec[(o + 3u32) as usize] = 0u32;
                    top_rec[(o + 4u32) as usize] = 0u32;
                    top_rec[(o + 5u32) as usize] = 0u32;
                    top_rec[(o + 6u32) as usize] = w6;
                    top_rec[(o + 7u32) as usize] = 0u32;
                }""")
# drop tdigz2 and toprec2 (now in tops2)
i0 = s.index("    /// tdigz with the top count read on the device (tstat[0]).")
i1 = s.index("// ------------------------------------------------------------------------------------------------ host: tops")
tail_close = s[i0:i1]
# keep the module's closing brace
assert tail_close.rstrip().endswith("}\n}") or tail_close.rstrip().endswith("}")
s = s[:i0].rstrip() + "\n}\n\n" + s[i1:]
# launches
rep("""                    a(&cur, 4032),
                    a(&tstat, 3),
                    a(&l5n, 1),
                );""", """                    a(&cur, 4032),
                    a(&tstat, 3),
                    a(&l5n, 1),
                    a(&self.histh, 16128),
                    a(&self.lcnt, 1),
                );""")
rep("""                    a(&tmh, nt),
                    a(&thdh, nt),
                    a(&tmhih, nt),
                    a(&self.l5, full as usize),
                    a(&l5n, 1),
                    nt as u32,
                );
            }""", """                    a(&tmh, nt),
                    a(&thdh, nt),
                    a(&tmhih, nt),
                    a(&self.g_tdig, nt * 4),
                    a(&self.top_rec, nt * 8),
                    a(&self.l5, full as usize),
                    a(&l5n, 1),
                    (pip >> 6) as u32,
                    nt as u32,
                );
            }""")
i0 = s.index("            if self.stop < 10 || self.stop - 10 >= 4 {\n                dtops::tdigz2_kernel")
i1 = s.index("        if self.upto(2) {\n            self.queue_parents(pip, rankh);")
seg = s[i0:i1]
assert "toprec2_kernel" in seg
s = s[:i0] + "        }\n" + s[i1:]
rep("""this one (1 tops, 2 parents, 3 main kernel, 5 expansion, 6 all; 11–15:
    /// the first 1–5 device-top kernels alone)""", """this one (1 tops, 2 parents, 3 main kernel, 5 expansion, 6 all; 11–13:
    /// the first 1–3 device-top kernels alone)""")
open(p, 'w').write(s)
