#!/usr/bin/env python3
"""N13 (tree E = fork exp/b64-profile 44eee52): wgpu-path switches. NICE_EXP_VRAM=1 gives a non-CUDA device CUDA's
denser plan (`with_vram_budget`); NICE_EXP_WALK_SYNC=1 ends each walk round with a plane barrier on a non-CUDA device
(if the device reports Plane::Sync); NICE_EXP_INFO=1 prints the device's limits, plane sizes and plane features once
per JoinDevice. Defaults reproduce the tree. python3 patchC.py TREE"""
import sys
p = sys.argv[1] + '/common/src/cubecl_join.rs'
s = open(p).read()
def rep(a, b):
    global s
    assert s.count(a) == 1, a[:70]
    s = s.replace(a, b)
rep("""    let lim = JoinLimits::for_buffer(client.properties().memory.max_page_size);
    if R::name(client).contains("cuda") {""", """    let lim = JoinLimits::for_buffer(client.properties().memory.max_page_size);
    if exp_env("NICE_EXP_INFO", 0) == 1 {
        let pr = client.properties();
        eprintln!(
            "EXP_INFO runtime={} max_page_size={} plane_size_min={} plane_size_max={} plane={:?} limits={:?}",
            R::name(client),
            pr.memory.max_page_size,
            pr.hardware.plane_size_min,
            pr.hardware.plane_size_max,
            pr.features.plane,
            lim
        );
    }
    if R::name(client).contains("cuda") || exp_env("NICE_EXP_VRAM", 0) == 1 {""")
rep("""            walk_sync: R::name(client).contains("cuda")
                && client""", """            walk_sync: (R::name(client).contains("cuda") || exp_env("NICE_EXP_WALK_SYNC", 0) == 1)
                && client""")
open(p, 'w').write(s)
print('patched C', p)
