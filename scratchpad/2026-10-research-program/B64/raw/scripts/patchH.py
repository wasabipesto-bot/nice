#!/usr/bin/env python3
"""B64 lever test (on top of patchB): stg >> 1 == 3 prepares a bucket's entry wave once per work item instead of once
per top batch when the bucket has at most one wave of entries (ne <= ept * JOIN_WG); the wave's registers stay live
across the bucket's top batches. Other stg values: today's order (the wave arrays are only declared earlier, which
does not change what is live where). python3 patchH.py TREE"""
import sys
p = sys.argv[1] + '/common/src/cubecl_join.rs'
s = open(p).read()
def rep(old, new):
    global s
    assert s.count(old) == 1, (old[:90], s.count(old))
    s = s.replace(old, new)
decl = """                    let mut mlo = Array::<u32>::new(ept as usize);
                    let mut mhi = Array::<u32>::new(ept as usize);
                    let mut rr = Array::<u32>::new(ept as usize);
                    // Per-slot validity: an empty slot must never pass, whatever
                    // the top's mask (a top may certify nothing at small t).
                    let mut vv = Array::<u32>::new(ept as usize);
                    // The entry's part of the prefilter (see above).
                    let mut ac = Array::<u32>::new(ept as usize);
                    let mut pc = Array::<u32>::new(ept as usize);
                    // Lean: `ac`/`pc` the n² terms (A·C, P), `ac3`/`pc3` n³'s.
                    let mut ac3 = Array::<u32>::new(ept as usize);
                    let mut pc3 = Array::<u32>::new(ept as usize);
"""
rep(decl, "")
rep("""            let mut tc = 0u32;
            while tc < s_cum[nroots as usize] {""", decl.replace("                    ", "            ", ) + """            let mut tc = 0u32;
            while tc < s_cum[nroots as usize] {""")
rep("""                    #[unroll]
                    for j in 0..ept {
                        let sl = ws + UNIT_POS_X + comptime!(j * JOIN_WG);""", """                    let mut prep = true;
                    if comptime!((stg >> 1) == 3) {
                        prep = tc == 0u32 || ne > wave;
                    }
                    if prep {
                    #[unroll]
                    for j in 0..ept {
                        let sl = ws + UNIT_POS_X + comptime!(j * JOIN_WG);""")
rep("""                            rr[j as usize] = r0;
                        }
                    }
                    if comptime!(abl == 1 || abl == 2 || abl == 4) {""", """                            rr[j as usize] = r0;
                        }
                    }
                    }
                    if comptime!(abl == 1 || abl == 2 || abl == 4) {""")
open(p, 'w').write(s)
print('patched H', p)
