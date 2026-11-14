#!/usr/bin/env python3
"""add_knobs.py FILE: investigation knobs for the fix's queue test (timing/investigation binaries only, not the PR):
NICE_TEST_QUEUE_PLANE_ANYWAY=1 tests the plane-scoped queue on software rasterizers too;
NICE_TEST_QUEUE_DIMS=a,b,.. replaces the cube sizes of the wgpu partial-plane test."""
import sys
p = sys.argv[1]; s = open(p).read()
old = "        plane_sync && !is_software_rasterizer(device)\n    }"
assert s.count(old) == 1
s = s.replace(old, "        plane_sync && (!is_software_rasterizer(device) || std::env::var_os(\"NICE_TEST_QUEUE_PLANE_ANYWAY\").is_some())\n    }")
old = "        let bad = queue_partial_planes(client, planes, &[true, false], &[256, 100, 48, 36]);"
assert s.count(old) == 1
s = s.replace(old, """        let dims: Vec<u32> = std::env::var("NICE_TEST_QUEUE_DIMS").map_or(vec![256, 100, 48, 36], |v| v.split(',').map(|x| x.parse().unwrap()).collect());
        let bad = queue_partial_planes(client, planes, &[true, false], &dims);""")
open(p, 'w').write(s); print("ok")
# NICE_TEST_QUEUE_FORM=scan|ballot overrides the production plan's rank form (timing of the scan form on CUDA).
s = open(p).read()
old = "            ballot: ballot_append(client.properties().hardware.plane_size_max),"
assert s.count(old) == 1
s = s.replace(old, """            ballot: match std::env::var("NICE_TEST_QUEUE_FORM").ok().as_deref() {
                Some("scan") => false,
                Some("ballot") => true,
                _ => ballot_append(client.properties().hardware.plane_size_max),
            },""")
open(p, 'w').write(s); print("form knob ok")
