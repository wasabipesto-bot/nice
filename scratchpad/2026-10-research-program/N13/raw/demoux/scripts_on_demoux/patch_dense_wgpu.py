#!/usr/bin/env python3
"""N13: a wgpu twin of `cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field` (the same body on `client()`, the wgpu
client): NICE_TEST_JOIN_DENSE partitions of slice 0 of NICE_TEST_JOIN_DENSE_FIELD=base:start:size, device hits and
both survivor counts asserted equal to the CPU join's. python3 patch_dense_wgpu.py TREE"""
import sys, re
p = sys.argv[1] + '/common/src/cubecl_join.rs'
s = open(p).read()
head = """    #[test]
    #[cfg(feature = "cubecl-cuda")]
    #[ignore = "requires an NVIDIA device; opt-in, NICE_TEST_JOIN_DENSE=partitions"]
    #[allow(clippy::cast_possible_truncation, clippy::cast_sign_loss)]
    fn cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field() {"""
assert s.count(head) == 1
i = s.index(head)
# the function ends at the first "\n    }\n" after its start
j = s.index("\n    }\n", i) + len("\n    }\n")
body = s[i:j]
w = body.replace('#[cfg(feature = "cubecl-cuda")]\n', '')
w = w.replace('requires an NVIDIA device', 'requires a wgpu device')
w = w.replace('fn cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field', 'fn wgpu_join_matches_the_cpu_join_on_a_dense_field')
old = """        let ctx = CubeclContext::new_cuda(0).expect("CubeCL CUDA init");
        let CubeclContext::Cuda { client, .. } = ctx else {
            unreachable!("new_cuda is CUDA")
        };
"""
assert w.count(old) == 1
w = w.replace(old, "        let (client, _) = client();\n")
s = s[:j] + "\n" + w + s[j:]
open(p, 'w').write(s)
print('patched dense wgpu', p)
