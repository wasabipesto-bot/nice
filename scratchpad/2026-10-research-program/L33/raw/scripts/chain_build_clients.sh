#!/bin/bash
# client_A and client_B (nice_client --features gpu), one after the other.
/root/l33/scripts/buildclient.sh A client_A > /root/l33/logs/buildclient_A.out 2>&1
/root/l33/scripts/buildclient.sh B client_B > /root/l33/logs/buildclient_B.out 2>&1
echo CLIENTS_DONE $(date -u +%T) > /root/l33/logs/clients.done
