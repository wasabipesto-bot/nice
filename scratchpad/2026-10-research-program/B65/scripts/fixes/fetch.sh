#!/bin/bash
# fetch.sh: fetch dev/mo-wide-b65b from the fork into eventeo's clone.
. "$HOME/research/scripts/env.sh"
cd "$SRC" && git fetch -q fork dev/mo-wide-b65b && git rev-parse --short=8 FETCH_HEAD
