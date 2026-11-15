#!/bin/sh
cd /root/nice
git fetch -q upstream --tags
M=$(git rev-parse upstream/main); R=$(git rev-parse 'v3.4.7^{commit}')
echo "main $M release $R" > /root/logs/shas.txt
/root/box_build.sh $M; /root/box_build.sh $R
