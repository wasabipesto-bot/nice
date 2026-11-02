#!/bin/bash
/root/l35/build.sh P0 P0 gpu
/root/l35/buildclient.sh P0 client_P0
echo P0_DONE $(date -u +%T) > /root/l35/logs/p0.done
