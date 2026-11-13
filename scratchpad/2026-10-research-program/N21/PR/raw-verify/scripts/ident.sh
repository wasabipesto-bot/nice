#!/bin/bash
# ident.sh BIN...: per binary, CubeCL's full compilation log of production runs (the dense compare on one partition
# of b62 1e17 and of b64 1e17: launch_batch in hits mode, every join kernel) on CUDA, and CI's wgsl_dump_for_lint on
# lavapipe with CUBECL_DEBUG_LOG (the shaders the wgpu runtime compiled: WGSL for naga builds, the SPIR-V compiler's
# output for cubecl-spirv builds). Logs in $W/ident/BIN/.
W=/root/n21v; export NICE_BUILD_SHA=test LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}
export VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1)
for B in "$@"; do
  d=$W/ident/$B; rm -rf $d; mkdir -p $d; cd $d
  for f in "62:7520566762397899821056" "64:58557331862957161709568"; do
    b=${f%%:*}
    printf '[compilation.logger]\nlevel = "full"\nfile = "%s/cuda_b%s.log"\n' $d $b > cubecl.toml
    NICE_TEST_JOIN_DENSE=1 NICE_TEST_JOIN_DENSE_FIELD=$f:100000000000000000 \
      $W/bin/$B --ignored --exact cubecl_join::tests::cubecl_cuda_join_matches_the_cpu_join_on_a_dense_field --nocapture > run_cuda_b$b.out 2>&1
  done
  printf '[compilation.logger]\nlevel = "full"\nfile = "%s/comp_lint.log"\n' $d > cubecl.toml
  CUBECL_DEBUG_LOG=$d/wgsl.log $W/bin/$B --ignored --exact cubecl_backend::tests::wgsl_dump_for_lint --nocapture > run_lint.out 2>&1
  rm cubecl.toml
  echo "$B: $(grep -h 'test result' run_*.out | tr '\n' ' ')"
done
