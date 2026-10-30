#!/bin/bash
while ! grep -q PROTOCOL_DONE /root/logs/proto/trees.txt; do sleep 10; done
/root/post.sh
