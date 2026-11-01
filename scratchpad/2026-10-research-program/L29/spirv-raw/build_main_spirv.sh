#!/bin/bash
. /root/.cargo/env
export NICE_BUILD_SHA=test
cd /root/src/main
find common/src -name '*.rs' -exec touch {} +
{ date -u; cargo test --release --features cubecl-spirv -p nice_common --no-run 2>&1 | grep -v "^ *Downloaded" | tail -30; date -u; } > /root/logs/build_main_spirv2.log 2>&1
cp target/release/deps/nice_common-6773f06445c05522 /root/bin_main_spirv
md5sum /root/bin_main_spirv >> /root/logs/build_main_spirv2.log
touch /root/logs/build_main_spirv2.done
