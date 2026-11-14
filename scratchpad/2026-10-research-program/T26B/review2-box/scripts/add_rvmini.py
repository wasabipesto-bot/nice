#!/usr/bin/env python3
"""add_rvmini.py FILE: reviewer's test-only probe kernels for cubecl-opt's MergeSameExpressions (not for any PR).
Words start with distinct values (stored in an earlier block), then mode-specific operations, then readback.
out: s[0..4], t[0..2], p[0..2], g[0..2]."""
import sys
p = sys.argv[1]; s = open(p).read()
k = r'''
#[cube(launch_unchecked)]
fn rv_mini_kernel(out: &mut Array<u32>, g: &mut Array<Atomic<u32>>, val: u32, #[comptime] mode: u32, #[comptime] n: u32) {
    let s = SharedMemory::<Atomic<u32>>::new(4usize);
    let t = SharedMemory::<Atomic<u32>>::new(2usize);
    let mut p = SharedMemory::<u32>::new(2usize);
    if UNIT_POS_X == 0u32 {
        s[0].store(1u32);
        s[1].store(2u32);
        s[2].store(3u32);
        s[3].store(4u32);
        t[0].store(5u32);
        t[1].store(6u32);
        p[0] = 11u32;
        p[1] = 12u32;
    }
    sync_cube();
    if UNIT_POS_X == 0u32 {
        if comptime!(mode == 1) {
            s[0].store(7u32);
            s[1].store(7u32);
            s[2].store(7u32);
            s[3].store(7u32);
        }
        if comptime!(mode == 2) {
            s[0].store(7u32);
            t[0].store(7u32);
        }
        if comptime!(mode == 3) {
            let v = val + UNIT_POS_X;
            s[0].store(v);
            s[1].store(v);
        }
        if comptime!(mode == 5) {
            p[0] = 7u32;
            p[1] = 7u32;
        }
        if comptime!(mode == 6) {
            let _a = s[0].fetch_add(1u32);
            let _b = s[1].fetch_add(1u32);
        }
        if comptime!(mode == 7) {
            g[0].store(7u32);
            g[1].store(7u32);
        }
        if comptime!(mode == 8) {
            let _a = s[0].swap(7u32);
            let _b = s[1].swap(7u32);
        }
        if comptime!(mode == 9) {
            let _a = s[0].fetch_add(1u32);
            let _b = s[0].fetch_add(1u32);
        }
        if comptime!(mode == 10) {
            #[unroll]
            for k in 0..n {
                s[k as usize].store(7u32);
            }
        }
        if comptime!(mode == 11) {
            s[0].store(7u32);
            g[0].store(7u32);
        }
    }
    if comptime!(mode == 4) {
        if UNIT_POS_X == 0u32 {
            s[0].store(7u32);
        }
        if UNIT_POS_X == 0u32 {
            s[1].store(7u32);
        }
    }
    sync_cube();
    if UNIT_POS_X == 0u32 {
        out[0] = s[0].load();
        out[1] = s[1].load();
        out[2] = s[2].load();
        out[3] = s[3].load();
        out[4] = t[0].load();
        out[5] = t[1].load();
        out[6] = p[0];
        out[7] = p[1];
    }
}
'''
anchor = "/// One-thread smoke kernel"
assert s.count(anchor) == 1
s = s.replace(anchor, k + "\n" + anchor)
t = r'''
    #[test]
    #[ignore = "requires a wgpu device"]
    fn rv_mini_merge_probe() {
        let ctx = CubeclContext::new_default().expect("CubeCL init");
        #[allow(irrefutable_let_patterns)]
        let CubeclContext::Wgpu { client, .. } = &ctx else { unreachable!() };
        for mode in [1u32, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] {
            let out = client.create(cubecl::bytes::Bytes::from_elems(vec![0u32; 8]));
            let g = client.create(cubecl::bytes::Bytes::from_elems(vec![21u32, 22u32]));
            unsafe {
                rv_mini_kernel::launch_unchecked::<cubecl::wgpu::WgpuRuntime>(
                    client, CubeCount::Static(1, 1, 1), CubeDim::new_1d(64),
                    ArrayArg::from_raw_parts(out.clone(), 8),
                    ArrayArg::from_raw_parts(g.clone(), 2),
                    7u32, mode, 4u32);
            }
            let v = u32::from_bytes(&client.read_one(out).unwrap()).to_vec();
            let gv = u32::from_bytes(&client.read_one(g).unwrap()).to_vec();
            println!("RVMINI mode={mode}: s={:?} t={:?} p={:?} g={gv:?}", &v[0..4], &v[4..6], &v[6..8]);
        }
    }
}
'''
assert s.endswith("}\n")
s = s[:-2] + t
open(p, 'w').write(s); print("rvmini ok")
