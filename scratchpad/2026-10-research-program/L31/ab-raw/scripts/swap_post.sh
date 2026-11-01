#!/bin/bash
for p in $(pgrep -f '/post\.sh|\./post\.sh'); do [ "$p" != "$$" ] && kill $p && echo killed $p; done
cd /root/l31b && nohup ./post2.sh > logs/post2.out 2>&1 < /dev/null &
sleep 1; ps -eo pid,args | grep -E 'post2?\.sh' | grep -v grep
