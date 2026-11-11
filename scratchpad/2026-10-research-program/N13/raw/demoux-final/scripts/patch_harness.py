#!/usr/bin/env python3
"""B64: the throughput harness takes a list of field starts (NICE_TEST_JOIN_LIST=s1,s2,...; size NICE_TEST_JOIN_SIZE)
instead of consecutive fields, and prints one FIELD line per finished field (time since the first begin, its stats).
Applies to upstream main c0c357a, fork pr/check-d a97e3d7 and fork exp/l51-profile 14f87cd (identical harness text).
python3 patch_harness.py TREE"""
import sys
p = sys.argv[1] + '/common/src/cubecl_join.rs'
s = open(p).read()
old = """            let fields: Vec<FieldSize> = (0..n)
                .map(|i| FieldSize::new(start + i * size, start + (i + 1) * size))
                .collect();
"""
new = """            let fields: Vec<FieldSize> = match std::env::var("NICE_TEST_JOIN_LIST") {
                Ok(l) => l
                    .split(',')
                    .filter(|x| !x.trim().is_empty())
                    .map(|x| {
                        let s0: u128 = x.trim().replace('_', "").parse().expect("a start");
                        FieldSize::new(s0, s0 + size)
                    })
                    .collect(),
                Err(_) => (0..n)
                    .map(|i| FieldSize::new(start + i * size, start + (i + 1) * size))
                    .collect(),
            };
            let n = fields.len() as u128;
"""
assert s.count(old) == 1, 'fields'
s = s.replace(old, new)
old2 = """                per_field.push((stats, last_join_stats(ctx).expect("join stats")));
            };
"""
new2 = """                per_field.push((stats, last_join_stats(ctx).expect("join stats")));
                {
                    let (ns, js) = per_field.last().expect("pushed");
                    eprintln!(
                        "FIELD i={} at={:.3} msd={:.3} device={:.3} total={:.3} launches={} | jsetup={:.3} \\
                         jdevice={:.3} jwait={:.3} slices={} partitions={} batches={} slots={} min_slots={} \\
                         survivors={} checked={} retried={} splits={} refused={}",
                        per_field.len() - 1,
                        t.elapsed().as_secs_f64(),
                        ns.msd_secs,
                        ns.device_secs,
                        ns.total_secs,
                        ns.launches,
                        js.setup_secs,
                        js.device_secs,
                        js.device_wait_secs,
                        js.slices,
                        js.partitions,
                        js.batches,
                        js.slots,
                        js.min_slots,
                        js.survivors,
                        js.checked,
                        js.retried_partitions,
                        js.splits,
                        js.refused,
                    );
                }
            };
"""
assert s.count(old2) == 1, 'finish'
s = s.replace(old2, new2)
open(p, 'w').write(s)
print('patched', p)
