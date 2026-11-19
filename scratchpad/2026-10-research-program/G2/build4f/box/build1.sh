#!/bin/bash
# build the route binaries, the examples and the unit tests for /root/mc's tree; $1 = log dir
source ~/.cargo/env; cd /root/mc; export CARGO_TARGET_DIR=/root/t/mc; L=$1; mkdir -p $L /root/mo/bin
git log --oneline -1 > $L/head.txt; git status --short >> $L/head.txt; git diff HEAD | md5sum >> $L/head.txt
cargo build --release -p nice_client --features cubecl-cuda > $L/b_client.log 2>&1; echo rc=$? >> $L/b_client.log
cp /root/t/mc/release/nice_client /root/mo/bin/nice_mo
cargo build --release -p nice_client --features cubecl-cuda,midout-fault > $L/b_fault.log 2>&1; echo rc=$? >> $L/b_fault.log
cp /root/t/mc/release/nice_client /root/mo/bin/nice_mo_fault
cargo build --release -p nice_common --features cubecl-cuda --example midout_bench --example midout_wide_bench --example midout_fields > $L/b_ex.log 2>&1; echo rc=$? >> $L/b_ex.log
cp /root/t/mc/release/examples/midout_bench /root/t/mc/release/examples/midout_wide_bench /root/t/mc/release/examples/midout_fields /root/mo/bin/
md5sum /root/mo/bin/* > $L/bins.txt
strings /root/mo/bin/nice_mo | grep -c "TEST FAULT" >> $L/bins.txt; strings /root/mo/bin/nice_mo_fault | grep -c "NICE_MIDOUT_FAULT" >> $L/bins.txt
cargo test --release -p nice_common --features rustls-tls --lib -- midout::wire client_api_async > $L/t_common.log 2>&1; echo rc=$? >> $L/t_common.log
cargo test --release -p nice_client --features cubecl-cuda -- midout_route > $L/t_client.log 2>&1; echo rc=$? >> $L/t_client.log
echo done > $L/done
