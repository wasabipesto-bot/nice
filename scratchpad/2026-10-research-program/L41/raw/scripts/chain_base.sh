#!/bin/bash
# chain_base.sh: setup, the base test binary B and client_B.
L=/root/l41/logs
/root/l41/setup.sh > /root/l41/setup.out 2>&1
J=10 /root/l41/build.sh B B > $L/build_B.out 2>&1
/root/l41/buildclient.sh B client_B > $L/buildclient_B.out 2>&1
touch $L/base.done
