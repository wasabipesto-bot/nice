#!/usr/bin/env python3
"""B64 Task B: walk variants on tree E (exp/l51-profile + patch_harness), carried in the high bits of the `stg` knob
(NICE_EXP_JOIN_STAGE; bit 0 keeps L51's meaning: 0 stage once per top batch, 1 once per work item):
  stg >> 1 == 1: one walk over both entry slots' pass bits (L37's COMPACT=2 on the lean prefilter): rounds = the
                 plane's max of (pop0 + pop1) instead of max(pop0) + max(pop1), one loop entry/exit per chunk not two;
  stg >> 1 == 2: today's walk without the per-round plane barrier (ablation of `sync_plane`).
Defaults (stg 0) are today's kernel. python3 patchB.py TREE"""
import sys
p = sys.argv[1] + '/common/src/cubecl_join.rs'
s = open(p).read()
def rep(old, new, n=1):
    global s
    assert s.count(old) == n, (old[:80], s.count(old))
    s = s.replace(old, new)
rep("if comptime!(stg == 0) {", "if comptime!((stg & 1) == 0) {")
rep("if comptime!(stg == 1) {", "if comptime!((stg & 1) == 1) {")
rep("""                        if comptime!(abl == 1 || abl == 4) {
                            // no walk
                        } else {
                        #[unroll]
                        for j in 0..ept {
""", """                        if comptime!(abl == 1 || abl == 4) {
                            // no walk
                        } else if comptime!((stg >> 1) == 1 && ept == 2 && lean && abl == 0) {
                            // B64 Task B: one walk over both entry slots.
                            let mut x0 = pm[0usize] & vv[0usize];
                            let mut x1 = pm[1usize] & vv[1usize];
                            while plane_any((x0 | x1) != 0u32) {
                                if (x0 | x1) != 0u32 {
                                    let lo = x0 != 0u32;
                                    let x = select(lo, x0, x1);
                                    let jt2 = jc + x.trailing_zeros();
                                    let xn = x & (x - 1u32);
                                    x0 = select(lo, xn, x0);
                                    x1 = select(lo, x1, xn);
                                    let r0 = select(lo, rr[0usize], rr[1usize]);
                                    let pass = walk_pf_lean(
                                        select(lo, ac[0usize], ac[1usize]),
                                        select(lo, ac3[0usize], ac3[1usize]),
                                        select(lo, pc[0usize], pc[1usize]),
                                        select(lo, pc3[0usize], pc3[1usize]),
                                        t_dm[jt2 as usize],
                                        select(lo, mlo[0usize], mlo[1usize]),
                                        select(lo, mhi[0usize], mhi[1usize]),
                                        t_glo[jt2 as usize],
                                        t_ghi[jt2 as usize],
                                        base,
                                    );
                                    if pass {
                                        let at = s_cnt[0].fetch_add(1u32);
                                        if at < SURV_SH_CAP {
                                            s_t[at as usize] = t_id[jt2 as usize];
                                            s_r[at as usize] = r0;
                                        } else {
                                            let g = surv_count[0].fetch_add(1u32);
                                            if g < surv_cap {
                                                surv[(2u32 * g) as usize] = t_id[jt2 as usize];
                                                surv[(2u32 * g + 1u32) as usize] = r0;
                                            }
                                        }
                                    }
                                }
                                if walk_sync {
                                    sync_plane();
                                }
                            }
                        } else {
                        #[unroll]
                        for j in 0..ept {
""")
rep("""                                if walk_sync {
                                    sync_plane();
                                }
                            }
                        }
                        }
                        jc += 32u32;""", """                                if comptime!(walk_sync && (stg >> 1) != 2) {
                                    sync_plane();
                                }
                            }
                        }
                        }
                        jc += 32u32;""")
open(p, 'w').write(s)
print('patched B', p)
