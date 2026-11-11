#!/bin/bash
cd /root/b64
until [ -e logs/pr/prt.done ]; do sleep 10; done
bash scripts/pr_ab.sh > logs/pr_ab.out 2>&1
