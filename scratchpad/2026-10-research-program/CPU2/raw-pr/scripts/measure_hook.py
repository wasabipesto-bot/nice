#!/usr/bin/env python3
"""Measurement-only hook, applied identically to the main and branch trees
(never committed): choose slices / a partition prefix of a field by env vars,
and print the process's memory and the join telemetry after the field's join.
  NICE_MEASURE_SLICES=0,3   run only these slices of the field (indexes)
  NICE_MEASURE_PARTS=N      run only partitions 0..N of each slice
Usage: measure_hook.py <tree>"""
import sys
p = sys.argv[1] + '/client/src/main.rs'
s = open(p).read()
a1 = ') -> Option<(FieldResults, JoinTelemetry)> {\n'
assert s.count(a1) == 1
s = s.replace(a1, a1 + '''    // MEASUREMENT HOOK (not for merging)
    let picked: Vec<FieldSize> = match std::env::var("NICE_MEASURE_SLICES") {
        Ok(s) => s.split(',').map(|i| slices[i.trim().parse::<usize>().unwrap()].clone()).collect(),
        Err(_) => slices.to_vec(),
    };
    let slices = &picked[..];
    let measure_parts: Option<u32> =
        std::env::var("NICE_MEASURE_PARTS").ok().map(|s| s.parse().unwrap());
''')
a2 = '        let out = (0..join.partitions())\n'
assert s.count(a2) == 1
s = s.replace(a2, '        let out = (0..measure_parts.map_or(join.partitions(), |n| n.min(join.partitions())))\n')
a3 = '                if let Some((results, join)) = process_field_join(base, &range, jp, &slices) {\n'
assert s.count(a3) == 1
s = s.replace(a3, a3 + '''                    {
                        // MEASUREMENT HOOK (not for merging)
                        let st = std::fs::read_to_string("/proc/self/status").unwrap_or_default();
                        let mem: Vec<&str> = st.lines().filter(|l| l.starts_with("VmRSS") || l.starts_with("VmHWM")).collect();
                        eprintln!("MEASURE after-join {} threads={} join={}", mem.join(" ").split_whitespace().collect::<Vec<_>>().join(" "), rayon::current_num_threads(), join.json());
                    }
''')
open(p, 'w').write(s)
print("hooked", p)
