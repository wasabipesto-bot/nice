#!/bin/bash
source ~/.cargo/env
eval "$(sed -n "/^build() {/,/^}/p" /root/setup.sh)"
build pr b 10 && build xpr b 10
echo SETUP_B_DONE $(date -u +%T)
