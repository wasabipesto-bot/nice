#!/usr/bin/env python3
"""make_repro.py MAIN_FILE FIX_FILE OUT: main's cubecl_backend.rs plus, in tests only, a cube-size override
and the fix's partly-filled-plane test (without the rank-form switch and the account, which main lacks)."""
import sys, re
main = open(sys.argv[1]).read(); fix = open(sys.argv[2]).read()
def rep(s, old, new):
    assert s.count(old) == 1, old
    return s.replace(old, new)
s = main
s = rep(s, """    /// Force the plane-scoped queue on or off (device tests).
    #[cfg(test)]
    plane_override: Option<bool>,
}""", """    /// Force the plane-scoped queue on or off (device tests).
    #[cfg(test)]
    plane_override: Option<bool>,
    /// Units per cube (device tests, repro only).
    #[cfg(test)]
    cube_dim_override: Option<u32>,
}""")
s = rep(s, """            #[cfg(test)]
            plane_override: None,
        })""", """            #[cfg(test)]
            plane_override: None,
            #[cfg(test)]
            cube_dim_override: None,
        })""")
s = rep(s, """        let cubes = threads
            .div_ceil(u64::from(WORKGROUP_SIZE))""", """        #[cfg(test)]
        let cube_dim = self.cube_dim_override.unwrap_or(WORKGROUP_SIZE).min(WORKGROUP_SIZE);
        #[cfg(not(test))]
        let cube_dim = WORKGROUP_SIZE;
        let cubes = threads
            .div_ceil(u64::from(cube_dim))""")
s = rep(s, """                CubeCount::Static(cubes, 1, 1),
                CubeDim::new_1d(WORKGROUP_SIZE),
                ArrayArg::from_raw_parts(self.plan.residues.clone(), self.plan.stride_r as usize),""",
"""                CubeCount::Static(cubes, 1, 1),
                CubeDim::new_1d(cube_dim),
                ArrayArg::from_raw_parts(self.plan.residues.clone(), self.plan.stride_r as usize),""")
# tests: queue_cases + queue_partial_planes + the two device tests, rank-form line removed
a = fix.index("    /// The window, certificate and host-mirror survivors of the queue tests:")
b = fix.index("    /// A queue that skips a survivor, or checks one twice in place of")
t = fix[a:b]
t = t.replace("                            run.ballot_override = Some(ballot);\n", "                            let _ = ballot;\n")
t = t.replace("&[true, false], &[256, 100, 48, 36]", "&[true], &[256, 100, 48, 36]")
t = t.replace("""        let forms: &[bool] = if std::env::var_os("NICE_TEST_QUEUE_SCAN").is_some() {
            &[true, false]
        } else {
            &[true]
        };""", "        let forms: &[bool] = &[true];")
t = t.replace("fn cubecl_queues_check", "fn repro_queues_check").replace("fn cubecl_cuda_queues_check", "fn repro_cuda_queues_check")
assert s.endswith("    }\n}\n")
s = s[:-2] + "\n" + t + "}\n"
open(sys.argv[3], 'w').write(s)
print("ok")
