#!/usr/bin/env python3
"""reflect.py SHADER.spvasm -> LAYOUT lines for pipec (descriptor bindings and push-constant bytes) and the entry name."""
import sys, re
t = open(sys.argv[1]).read()
dset, bind, sc = {}, {}, {}
for m in re.finditer(r'OpDecorate (%\S+) DescriptorSet (\d+)', t): dset[m.group(1)] = int(m.group(2))
for m in re.finditer(r'OpDecorate (%\S+) Binding (\d+)', t): bind[m.group(1)] = int(m.group(2))
for m in re.finditer(r'(%\S+) = OpVariable %\S+ (\w+)', t): sc[m.group(1)] = m.group(2)
for v in sorted(bind, key=lambda v: bind[v]):
    print(f"binding {dset.get(v, 0)} {bind[v]} {'uniform' if sc.get(v) == 'Uniform' else 'storage'}")
if 'PushConstant' in sc.values(): print('push 256')
m = re.search(r'OpEntryPoint GLCompute %\S+ "([^"]+)"', t)
print(f"# entry {m.group(1) if m else 'main'}")
