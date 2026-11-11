#!/bin/bash
cd /root/b64
until grep -q "PR_BUILD_DONE" logs/pr_build.out; do sleep 10; done
bash scripts/pr_tests.sh > logs/pr_tests.out 2>&1
