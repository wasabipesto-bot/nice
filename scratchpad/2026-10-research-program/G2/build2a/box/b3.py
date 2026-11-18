import sys
p = sys.argv[1]
s = open(p).read()


def rep(old, new, cnt=1):
    global s
    n = s.count(old)
    assert n == cnt, (old[:80], n)
    s = s.replace(old, new)


# probe table: the top's index in word 3's spare bits
rep("""                            let mut pv = Vector::<u32, Const<4>>::empty();
                            #[unroll]
                            for k in 0..4u32 {
                                pv[k as usize] = tdig[((b0 + j) * 4u32 + k) as usize];
                            }
                            prob_d[(base + j - poff) as usize] = pv;""", """                            let mut pv = Vector::<u32, Const<4>>::empty();
                            #[unroll]
                            for k in 0..4u32 {
                                pv[k as usize] = tdig[((b0 + j) * 4u32 + k) as usize];
                            }
                            // (midout) the top's index in word 3's bits 12-31 (digits 15-16 are bits 0-11)
                            pv[3usize] = (pv[3usize] & 0xFFFu32) | ((b0 + j) << 12u32);
                            prob_d[(base + j - poff) as usize] = pv;""")
rep("""                            let mut pv = Vector::<u32, Const<4>>::empty();
                            #[unroll]
                            for k in 0..4u32 {
                                pv[k as usize] = dw[k as usize];
                            }
                            prob_d[(base + j - poff) as usize] = pv;""", """                            let mut pv = Vector::<u32, Const<4>>::empty();
                            #[unroll]
                            for k in 0..4u32 {
                                pv[k as usize] = dw[k as usize];
                            }
                            pv[3usize] = (pv[3usize] & 0xFFFu32) | ((b0 + j) << 12u32);
                            prob_d[(base + j - poff) as usize] = pv;""")
rep("""                            let p16 = ent & 0xFFFFu32;
                            pk[h as usize] = p16;
                            let kmask = 0u32 - ((ent >> qs) & 1u32);
                            let mut alo = 0u32;
                            let mut ahi = 0u32;
                            let dws = prob_d[(p16 >> 4u32) as usize];""", """                            let p16 = ent & 0xFFFFu32;
                            let kmask = 0u32 - ((ent >> qs) & 1u32);
                            let mut alo = 0u32;
                            let mut ahi = 0u32;
                            let dws = prob_d[(p16 >> 4u32) as usize];
                            // (midout) the record names its top, not its probe slot
                            pk[h as usize] = dws[3usize] >> 12u32;""")
rep("""                                        rv[0usize] = ((pk[0usize] >> 4u32) + poff)
                                            | (d << 16u32)
                                            | (c << 24u32);
                                        rv[1usize] = cpos;""", """                                        rv[0usize] = pk[0usize];
                                        rv[1usize] = lb + cpos;""")
rep("""                                        rv[0usize] = ((pk[1usize] >> 4u32) + poff)
                                            | (d << 16u32)
                                            | (c << 24u32);
                                        rv[1usize] = cpos;""", """                                        rv[0usize] = pk[1usize];
                                        rv[1usize] = lb + cpos;""")
# record expansion: no walk
i0 = s.index("    /// Records → production's survivor-list entries")
i1 = s.index("    /// Production's top-record layout per top")
s = s[:i0] + '''    /// Records → production's survivor-list entries `(top, r0)`, `r0 = n mod
    /// 2^30` (the child's r4 and the slice's digit 4): each plane takes the
    /// used slabs in a grid-stride loop and its lanes the slab's records,
    /// appended in plane-sized takes. A record names its top and its chunk's
    /// first position in the child lists (`lst`, written by the main
    /// kernel's phase 1), so a set bit b is the child at that position + b.
    /// Thread 0 also copies the slice's parent and slab counts to `stat`.
    #[cube(launch_unchecked)]
    pub fn expand_kernel(
        out: &Array<Vector<u32, Const<4>>>,
        slabn: &Array<u32>,
        slabcnt: &Array<u32>,
        lst: &Array<u32>,
        lcnt: &Array<u32>,
        surv: &mut Array<u32>,
        scount: &mut Array<Atomic<u32>>,
        stat: &mut Array<u32>,
        nslab_cap: u32,
        scap: u32,
        r0hi: u32,
    ) {
        if ABSOLUTE_POS_X == 0u32 {
            stat[0usize] = lcnt[0usize];
            stat[1usize] = slabn[0usize];
        }
        // one plane per slab at a time, its lanes over the slab's rows: no idle slots past a slab's count
        let ns = min(slabn[0usize], nslab_cap);
        let ppc = NT / PLANE_DIM;
        let pstride = CUBE_COUNT_X * ppc;
        let mut s = CUBE_POS_X * ppc + UNIT_POS_X / PLANE_DIM;
        while s < ns {
            let cnt = slabcnt[s as usize];
            let mut r0 = 0u32;
            while r0 < cnt {
                let r = r0 + UNIT_POS_PLANE;
                let i = s * SLAB + r;
                let live = r < cnt;
                let mut wlo = 0u32;
                let mut whi = 0u32;
                let mut ti = 0u32;
                let mut pos = 0u32;
                if live {
                    let rec = out[i as usize];
                    ti = rec[0usize];
                    pos = rec[1usize];
                    wlo = rec[2usize];
                    whi = rec[3usize];
                }
                let nb = wlo.count_ones() + whi.count_ones();
                let excl = plane_exclusive_sum(nb);
                let tot = plane_sum(nb);
                let mut b0 = 0u32;
                if UNIT_POS_PLANE == 0u32 && tot > 0u32 {
                    b0 = scount[0usize].fetch_add(tot);
                }
                let mut slot = plane_sum(b0) + excl;
                if live {
                    let mut x = wlo;
                    while x != 0u32 {
                        let b = x.trailing_zeros();
                        x &= x - 1u32;
                        if slot < scap {
                            surv[(2u32 * slot) as usize] = ti;
                            surv[(2u32 * slot + 1u32) as usize] = lst[(pos + b) as usize] + r0hi;
                        }
                        slot += 1u32;
                    }
                    let mut y = whi;
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
                }
                r0 += PLANE_DIM;
            }
            s += pstride;
        }
    }

''' + s[i1:]
rep("""mod post {
    use super::{M, NT, SLAB};""", """mod post {
    use super::{NT, SLAB};""")
rep("""                        a(&self.out, ns * SLAB as usize),
                        a(&slabn, 1),
                        a(&self.slabcnt, ns),
                        a(&self.g_pseg, 64),
                        a(tsegh, 64 * 63 * 2),
                        a(&self.roots_h, NROOT),
                        a(&self.clst, self.lcap as usize),
                        a(&self.lcnt, 1),
                        a(&self.surv, 2 * self.scap as usize),
                        a(&scount, 1),
                        a(&stat, 2),
                        self.nslab_cap,
                        self.scap,
                        *c0,
                        ((pip & 63) as u32) << 24,""", """                        a(&self.out, ns * SLAB as usize),
                        a(&slabn, 1),
                        a(&self.slabcnt, ns),
                        a(&self.clst, self.lcap as usize),
                        a(&self.lcnt, 1),
                        a(&self.surv, 2 * self.scap as usize),
                        a(&scount, 1),
                        a(&stat, 2),
                        self.nslab_cap,
                        self.scap,
                        ((pip & 63) as u32) << 24,""")
rep("""//! 4. new here: the main kernel also writes each job's certified children
//!    (their r4, in order) as phase 1 appends them, and its records name
//!    their job and chunk position; `expand_kernel` turns records into
//!    production's survivor-list entries `(top, r0)`, `n = P·b^5 + r0`;""", """//! 4. new here: the main kernel also writes each job's certified children
//!    (their r4, in order) as phase 1 appends them, and its records name
//!    their top and their chunk's position in the child lists;
//!    `expand_kernel` turns records into production's survivor-list entries
//!    `(top, r0)`, `n = P·b^5 + r0`;""")
open(p, 'w').write(s)
