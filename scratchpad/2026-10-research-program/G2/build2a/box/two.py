import sys
p = sys.argv[1]
s = open(p).read()

i0 = s.index("        // one plane per slab at a time, its lanes over the slab's rows: no idle slots past a slab's count\n        let ns = min(slabn[0usize], nslab_cap);\n        let ppc = NT / PLANE_DIM;\n        let pstride = CUBE_COUNT_X * ppc;\n        let mut s = CUBE_POS_X * ppc + UNIT_POS_X / PLANE_DIM;\n        let mut read = 0u32;")
i1 = s.index("        let rs = plane_sum(read);")
new = '''        // one plane per slab at a time, its lanes over the slab's rows: no idle slots past a slab's count; two
        // records per lane and take, their loads issued together (more loads in flight per plane)
        let ns = min(slabn[0usize], nslab_cap);
        let ppc = NT / PLANE_DIM;
        let pstride = CUBE_COUNT_X * ppc;
        let mut s = CUBE_POS_X * ppc + UNIT_POS_X / PLANE_DIM;
        let mut read = 0u32;
        while s < ns {
            let cnt = slabcnt[s as usize];
            let mut r0 = 0u32;
            while r0 < cnt {
                let ra = r0 + UNIT_POS_PLANE;
                let rb = ra + PLANE_DIM;
                let mut reca = Vector::<u32, Const<4>>::empty();
                let mut recb = Vector::<u32, Const<4>>::empty();
                #[unroll]
                for k in 0..4u32 {
                    reca[k as usize] = 0u32;
                    recb[k as usize] = 0u32;
                }
                if ra < cnt {
                    reca = out[(s * SLAB + ra) as usize];
                }
                if rb < cnt {
                    recb = out[(s * SLAB + rb) as usize];
                }
                let hda = thd[reca[0usize] as usize];
                let hdb = thd[recb[0usize] as usize];
                let topa = tmhi[reca[0usize] as usize];
                let topb = tmhi[recb[0usize] as usize];
                read += reca[2usize].count_ones()
                    + reca[3usize].count_ones()
                    + recb[2usize].count_ones()
                    + recb[3usize].count_ones();
                let (kla, kha) = keep_bits(reca, hda, topa, lst, r0hi, pip_hi);
                let (klb, khb) = keep_bits(recb, hdb, topb, lst, r0hi, pip_hi);
                let nb = kla.count_ones() + kha.count_ones() + klb.count_ones() + khb.count_ones();
                let excl = plane_exclusive_sum(nb);
                let tot = plane_sum(nb);
                let mut b0 = 0u32;
                if UNIT_POS_PLANE == 0u32 && tot > 0u32 {
                    b0 = scount[0usize].fetch_add(tot);
                }
                let slot = plane_sum(b0) + excl;
                let sb = put_bits(reca[0usize], reca[1usize], kla, kha, lst, surv, slot, scap, r0hi);
                put_bits(recb[0usize], recb[1usize], klb, khb, lst, surv, sb, scap, r0hi);
                r0 += 2u32 * PLANE_DIM;
            }
            s += pstride;
        }
'''
s = s[:i0] + new + s[i1:]
# helpers before the expansion kernel
j = s.index("    /// Records → production's survivor-list entries")
helpers = '''    /// The bits of a record (top index, chunk position, word lo, hi) whose
    /// survivor passes the prefilter; `hd` and `top` its top's h | d << 16 and
    /// prefilter mask. An all-zero record (past the slab) has none.
    #[cube]
    fn keep_bits(
        rec: Vector<u32, Const<4>>,
        hd: u32,
        top: u64,
        lst: &Array<u32>,
        r0hi: u32,
        pip_hi: u32,
    ) -> (u32, u32) {
        let pos = rec[1usize];
        // P = n div 2^30 = h·2^30 + d·2^24 + digits 5-8 (the top record's words 0-1)
        let h = hd & 0xFFFFu32;
        let plo = ((h & 3u32) << 30u32) | ((hd >> 16u32) << 24u32) | pip_hi;
        let phi = h >> 2u32;
        let mut klo = 0u32;
        let mut khi = 0u32;
        // one loop over both words: the plane runs max(bits) rounds, not that per word
        let mut x = rec[2usize];
        let mut y = rec[3usize];
        while (x | y) != 0u32 {
            let inlo = x != 0u32;
            let b = select(inlo, x.trailing_zeros(), y.trailing_zeros());
            let off = select(inlo, b, 32u32 + b);
            if inlo {
                x &= x - 1u32;
            } else {
                y &= y - 1u32;
            }
            if pf(lst[(pos + off) as usize] + r0hi, plo, phi, top) {
                if inlo {
                    klo |= 1u32 << b;
                } else {
                    khi |= 1u32 << b;
                }
            }
        }
        (klo, khi)
    }

    /// Writes the kept bits' entries `(top, r0)` from `slot` on; returns the
    /// next slot.
    #[cube]
    fn put_bits(
        ti: u32,
        pos: u32,
        klo: u32,
        khi: u32,
        lst: &Array<u32>,
        surv: &mut Array<u32>,
        slot0: u32,
        scap: u32,
        r0hi: u32,
    ) -> u32 {
        let mut slot = slot0;
        let mut x = klo;
        let mut y = khi;
        while (x | y) != 0u32 {
            let inlo = x != 0u32;
            let b = select(inlo, x.trailing_zeros(), y.trailing_zeros());
            let off = select(inlo, b, 32u32 + b);
            if inlo {
                x &= x - 1u32;
            } else {
                y &= y - 1u32;
            }
            if slot < scap {
                surv[(2u32 * slot) as usize] = ti;
                surv[(2u32 * slot + 1u32) as usize] = lst[(pos + off) as usize] + r0hi;
            }
            slot += 1u32;
        }
        slot
    }

'''
s = s[:j] + helpers + s[j:]
open(p, 'w').write(s)
