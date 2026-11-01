#!/bin/bash
# final.sh: rebuild the pr test binary from the final source, rerun the certificate tests.
while ! grep -q AFTER2_DONE /root/logs/after2.log; do sleep 10; done
cd /root
echo "== $(date -u +%T) rebuild"
./quick.sh
md5sum /root/bin/pr/nice_common_test
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
cd /root/src/pr
echo "== $(date -u +%T) cert cuda (final)"
/root/bin/pr/nice_common_test --ignored --exact cubecl_join::tests::cubecl_cuda_top_certificates_match_the_lockstep_scan_and_the_cpu --nocapture --test-threads 1 > /root/logs/x_final_cert_cuda.log 2>&1
echo "exit $? $(date -u +%T)"
echo "== $(date -u +%T) cert lavapipe (final)"
VK_ICD_FILENAMES=$(ls /usr/share/vulkan/icd.d/lvp_icd*.json | head -n1) /root/bin/pr/nice_common_test --ignored --exact cubecl_join::tests::top_certificates_match_the_lockstep_scan_and_the_cpu --nocapture --test-threads 1 > /root/logs/x_final_cert_lvp.log 2>&1
echo "exit $? $(date -u +%T)"
echo FINAL_DONE $(date -u +%T)
