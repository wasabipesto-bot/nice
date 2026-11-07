#!/usr/bin/env python3
"""L48 round 2, measurement only (not in the PR): add an ignored CUDA test `l48_plan_report` to ROOT's cubecl_join.rs
that prints, for the A/B's fields, the slices and the first slice's plan under the device's limits (this tree's,
vram_budget on CUDA) and with vram_budget off (= the base's SURV_PER_PREFIX 2 everywhere)."""
import sys
fn = sys.argv[1] + '/common/src/cubecl_join.rs'
s = open(fn).read()
anchor = '''    /// The FD kernel's append ranks kept tops with a ballot only on planes'''
assert s.count(anchor) == 1
test = '''    #[test]
    #[cfg(feature = "cubecl-cuda")]
    #[ignore = "L48 measurement"]
    fn l48_plan_report() {
        let ctx = CubeclContext::new_cuda(0).expect("CubeCL CUDA init");
        let name = ctx.device_name();
        let CubeclContext::Cuda { client, .. } = ctx else {
            unreachable!("new_cuda is CUDA")
        };
        let lim = device_limits(&client, &name);
        let off = crate::join_plan::JoinLimits {
            vram_budget: false,
            ..lim
        };
        eprintln!(
            "L48 PLAN device={name} max_binding={} budget={} vram={}",
            lim.max_binding, lim.budget, lim.vram_budget
        );
        for (b, start, size, n) in [
            (62u32, 7_997_740_455_941_656_911_841u128, 100_000_000_000_000_000u128, 1u128),
            (62, 7_997_740_455_941_656_911_841, 10_000_000_000_000_000, 2),
            (60, 1_366_406_074_057_412_100_454, 10_000_000_000_000_000, 2),
            (64, 41_242_006_262_957_161_709_568, 10_000_000_000_000_000, 2),
        ] {
            for i in 0..n {
                let range = FieldSize::new(start + i * size, start + (i + 1) * size);
                for (tag, l) in [("base_rule", off), ("this_pr", lim)] {
                    let f = crate::join_plan::plan_join(b, &range, l).expect("a join field");
                    let cuts: Vec<String> =
                        f.slices.iter().map(|s| (s.end() - s.start()).to_string()).collect();
                    eprintln!(
                        "L48 PLAN b{b} {size:e} field{i} {tag}: slices={} first_slots={} first_mib={} \\
                         first_prefixes={} slice_sizes={}",
                        f.slices.len(),
                        f.plan.slots,
                        f.plan.bytes >> 20,
                        f.fs.tlay.len(),
                        cuts.join(",")
                    );
                }
            }
        }
    }

'''
s = s.replace(anchor, test + anchor)
open(fn, 'w').write(s)
print('plan report added')
