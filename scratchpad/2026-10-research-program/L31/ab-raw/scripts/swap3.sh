#!/bin/bash
kill 20689 2>/dev/null && echo killed post2 20689
kill 20687 2>/dev/null && echo killed stale swap 20687
cd /root/l31b && nohup ./post3.sh > logs/post3.out 2>&1 < /dev/null &
sleep 1
ps -eo pid,args | grep -E 'post[23]\.sh' | grep -v grep
