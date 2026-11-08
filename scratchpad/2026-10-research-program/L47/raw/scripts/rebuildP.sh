#!/bin/bash
# rebuild P (test binary and client) at the PR head given as $1; then let the exactness queue go
for p in $(pgrep -f "buildclient.sh P client_P"); do kill $p; done
for p in $(pgrep -f "cargo build --release -j 8 -p nice_client"); do kill $p; done
sleep 2
cd /root/nice && git fetch -q origin exp/check-d-pr && cd /root/l47/src/P && git checkout -q --detach $1 && git log --oneline -1
mv /root/l47/logs/build_P.out /root/l47/logs/build_P_k4.out
(setsid nohup bash -c "NICEN=5 J=10 /root/l47/scripts/build.sh P P gpu /root/tgt && touch /root/l47/logs/x_go && NICEN=10 J=8 /root/l47/scripts/buildclient.sh P client_P" > /root/l47/logs/build_P.out 2>&1 < /dev/null &)
sleep 2; pgrep -af "cargo" | cut -c1-120
