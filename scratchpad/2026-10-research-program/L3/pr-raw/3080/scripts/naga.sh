#!/bin/bash
# naga (the wgpu shader translator, version matching the lockfile) WGSL -> MSL
# on the dumped kernels: what the Metal path of the default cubecl feature does.
source /root/.cargo/env
while ! grep -q SPIRV_DONE /root/logs/post/status; do sleep 10; done
L=/root/logs/post
{ date -u; cargo install naga-cli --version 29.0.4 --locked --root /root/nagacli 2>&1 | tail -n 3
  /root/nagacli/bin/naga --help 2>&1 | head -n 40
  cd /root/wgsl
  for f in wgsl_*.wgsl; do
    echo "== $f"
    /root/nagacli/bin/naga "$f" "${f%.wgsl}.metal" 2>&1 | tail -n 5; echo "rc=$?"
    ls -la "${f%.wgsl}.metal" 2>&1
  done
  date -u; echo NAGA_DONE; } > $L/naga.txt 2>&1
