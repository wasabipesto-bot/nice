#!/bin/bash
# off_if_idle.sh [--dry-run]: power eventeo off if nothing needs it (the owner's policy: off when unused).
# Stays up, and says why, when: the owner (or anyone but claude) is logged in; a nice client, a build, a test
# binary or a container is running; or a file ~/research/keep-up or ~/research/keep-up.<job> exists (touch one per
# job to hold the machine up; each job removes its own).
. "$(dirname "$(readlink -f "$0")")/env.sh"
why=""
for f in "$R"/keep-up*; do [ -e "$f" ] && why="$why keep-up file $(basename "$f");"; done   # one file per holder: keep-up, keep-up.<job>
others=$(who | awk '$1 != "claude" {print $1}' | sort -u | tr '\n' ' ')
[ -n "$others" ] && why="$why logged in: $others;"
for p in nice_client t_box midout_bench midout_wide_ben midout_fields cargo rustc; do  # names as the kernel keeps them (15 characters)
  pgrep -x "$p" > /dev/null && why="$why $p running;"
done
[ -n "$(podman ps -q 2>/dev/null)" ] && why="$why containers running;"
if [ -n "$why" ]; then echo "eventeo stays up:$why"; exit 1; fi
if [ "$1" = "--dry-run" ]; then echo "eventeo would power off now"; exit 0; fi
echo "eventeo powering off $(date -u +%FT%T)"; sync; systemctl poweroff
