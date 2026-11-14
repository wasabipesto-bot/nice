#!/bin/bash
# q.sh CMD...: run CMD holding /root/t26/lock (serialises builds and device runs on the box)
exec flock /root/t26/lock "$@"
