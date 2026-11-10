#!/bin/bash
# pull.sh: copy the box's logs back to ivory (raw/box).
D=$(cd "$(dirname "$0")/.." && pwd)/box
rsync -a -e "ssh -o StrictHostKeyChecking=no -p 39808" root@ssh7.vast.ai:/root/n1/logs/ $D/
