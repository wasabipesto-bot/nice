D="$HOME/claude-exp-2026-10-31-top"
echo "FIRST_SSH $(date -u +%Y-%m-%dT%H:%M:%SZ) $(date +%s)"
if test -e "$D"; then echo "DIR_ALREADY_EXISTS"; exit 3; fi
mkdir -p "$D/logs" "$D/bin" && touch "$D/pids"
cat > "$D/watchdog.sh" <<'WEOF'
#!/bin/sh
D="$HOME/claude-exp-2026-10-31-top"
sleep "$1"
desc() { for c in $(pgrep -P "$1"); do echo "$c"; desc "$c"; done; }
if [ -f "$D/pids" ]; then
  for p in $(cat "$D/pids"); do
    kids=$(desc "$p")
    kill -9 "$p" 2>/dev/null
    for k in $kids; do kill -9 "$k" 2>/dev/null; done
  done
fi
cd "$HOME" && rm -rf "$D"
WEOF
nohup sh "$D/watchdog.sh" 3460 > /dev/null 2>&1 &
wd=$!
echo "WATCHDOG_PID $wd started $(date +%s) sleep 3460"
sleep 1
echo "WATCHDOG_CHILD $(pgrep -P $wd)"
echo "--- facts"
uname -a; sw_vers; sysctl -n machdep.cpu.brand_string hw.ncpu hw.memsize
uptime; pmset -g batt 2>/dev/null | head -2
system_profiler SPDisplaysDataType 2>/dev/null | sed -n '1,12p'
df -h "$HOME" | tail -1
for c in git rsync strings shasum rustup; do printf '%s: ' $c; command -v $c || echo missing; done
rsync --version 2>&1 | head -1
"$HOME/.cargo/bin/rustup" toolchain list
ls "$HOME/.cargo/registry/cache" "$HOME/.cargo/registry/index"
du -sh "$HOME/.cargo/registry" 2>/dev/null
echo "--- ps"
ps -axo pid,ppid,%cpu,etime,command | awk '$3 > 5.0 || /claude-exp/' | cut -c1-200
