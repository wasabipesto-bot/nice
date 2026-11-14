#!/usr/bin/env python3
"""add_mini.py FILE: a minimal test-only kernel (not for the PR) showing CubeCL's direct SPIR-V compiler dropping
constant-index atomic stores to a shared array: unit 0 stores 7, 7, 7, 7 into words 0-3 (and, in a second kernel,
7, 8, 9, 10), barrier, unit 0 copies the four words out. Its SPIR-V shows how many OpAtomicStore survive."""
import sys
p = sys.argv[1]; s = open(p).read()
k = r'''
#[cube(launch_unchecked)]
fn mini_store_kernel(out: &mut Array<u32>, #[comptime] distinct: bool) {
    let s = SharedMemory::<Atomic<u32>>::new(4usize);
    if UNIT_POS_X == 0u32 {
        if comptime!(distinct) {
            s[0].store(7u32);
            s[1].store(8u32);
            s[2].store(9u32);
            s[3].store(10u32);
        } else {
            s[0].store(7u32);
            s[1].store(7u32);
            s[2].store(7u32);
            s[3].store(7u32);
        }
    }
    sync_cube();
    if UNIT_POS_X == 0u32 {
        out[0] = s[0].load();
        out[1] = s[1].load();
        out[2] = s[2].load();
        out[3] = s[3].load();
    }
}
'''
anchor = "/// One-thread smoke kernel"
assert s.count(anchor) == 1
s = s.replace(anchor, k + "\n" + anchor)
t = r'''
    #[test]
    #[ignore = "requires a wgpu device"]
    fn mini_constant_index_atomic_stores() {
        let ctx = CubeclContext::new_default().expect("CubeCL init");
        #[allow(irrefutable_let_patterns)]
        let CubeclContext::Wgpu { client, .. } = &ctx else { unreachable!() };
        for distinct in [false, true] {
            let out = client.create(cubecl::bytes::Bytes::from_elems(vec![0u32; 4]));
            unsafe {
                mini_store_kernel::launch_unchecked::<cubecl::wgpu::WgpuRuntime>(
                    client, CubeCount::Static(1, 1, 1), CubeDim::new_1d(64),
                    ArrayArg::from_raw_parts(out.clone(), 4), distinct);
            }
            let v = u32::from_bytes(&client.read_one(out).unwrap()).to_vec();
            println!("MINI distinct={distinct}: words {v:?}");
        }
    }
}
'''
assert s.endswith("}\n")
s = s[:-2] + t
open(p, 'w').write(s); print("mini ok")
