#!/usr/bin/env python3
"""Throwaway (never committed): the CPU join's prefilter digits by shifts at power-of-two bases behind
NICE_EXP_FX_SHIFT=1 (read once per Fx::new), and cpu_join_partition_timing on any field
(NICE_TEST_CPU_JOIN_FIELD=base:start:size; the stride comparison is skipped then). python3 patch_cpufx.py TREE"""
import sys
p = sys.argv[1] + '/common/src/cpu_join.rs'
s = open(p).read()
def rep(old, new):
    global s
    assert s.count(old) == 1, old
    s = s.replace(old, new)
rep("""    b2: SmallDiv,
}
""", """    b2: SmallDiv,
    sh: u32,
}
""")
rep("""            b2: SmallDiv::new(b2),
        }""", """            b2: SmallDiv::new(b2),
            sh: if b.is_power_of_two() && std::env::var("NICE_EXP_FX_SHIFT").is_ok_and(|v| v == "1") {
                b.trailing_zeros()
            } else {
                0
            },
        }""")
rep("""        let f = (a * self.c).wrapping_add(p.wrapping_mul(dh));
        let fb = u64::from(f) * self.b;""", """        let f = (a * self.c).wrapping_add(p.wrapping_mul(dh));
        if self.sh != 0 {
            let up = 32 - self.sh;
            return (u64::from(f >> up), u64::from((f << self.sh) >> up));
        }
        let fb = u64::from(f) * self.b;""")
rep("""        let (size, chunk) = (100_000_000_000_000u128, 1_000_000_000u128);
        let range = FieldSize::new(FRONTIER_57, FRONTIER_57 + size);
        let join = CpuJoin::for_field(57, &range).expect("a join field");""",
"""        let (mut size, chunk) = (100_000_000_000_000u128, 1_000_000_000u128);
        let (mut fb, mut fstart) = (57u32, FRONTIER_57);
        let mut chunks = chunks;
        if let Ok(v) = std::env::var("NICE_TEST_CPU_JOIN_FIELD") {
            let x: Vec<&str> = v.split(':').collect();
            fb = x[0].parse().unwrap();
            fstart = x[1].parse().unwrap();
            size = x[2].parse::<f64>().unwrap() as u128;
            chunks = 0;
        }
        let range = FieldSize::new(fstart, fstart + size);
        let join = CpuJoin::for_field(fb, &range).expect("a join field");
        eprintln!("FX_SHIFT={:?} base {fb}", std::env::var("NICE_EXP_FX_SHIFT"));""")
rep("""        let stride_field = t.elapsed().as_secs_f64() / f64::from(chunks) * (size / chunk) as f64;""",
"""        let stride_field = t.elapsed().as_secs_f64() / f64::from(chunks.max(1)) * (size / chunk) as f64;""")
open(p, 'w').write(s)
print('patched', p)
