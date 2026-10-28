#!/bin/bash
until grep -q AB_DONE /root/ab/ab.log; do sleep 5; done
/root/nicemark.sh > /root/ab/nm.log 2>&1
/root/ept.sh > /root/ab/ept.log 2>&1
echo CHAIN_DONE $(date -u +%T) >> /root/ab/ept.log
