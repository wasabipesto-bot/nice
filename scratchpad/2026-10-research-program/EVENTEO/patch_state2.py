#!/usr/bin/env python3
import os
p = os.path.expanduser("~/SYSTEM_STATE.md"); s = open(p).read()
a = "- **Missing**: `just`, `cmake`, `clang`, `sqlite3`, `psql`, `vulkaninfo` (`vulkan-tools`). Cargo-installable ones (`just`) can go in `~/.cargo/bin` without root. The rest need the owner or a container."
if a in s:
    s = s.replace(a, "- **`just` 1.59.0** is in `~/.cargo/bin` (cargo-installed 2026-11-26; `just lint` is the project lint bar).\n- **Missing**: `cmake`, `clang`, `sqlite3`, `psql`, `strace`, `vulkaninfo` (`vulkan-tools`). They need the owner or a container.")
a = "- **Electricity**: $160 for 902 kWh"
if "Sustained base-64" not in s:
    assert s.count(a) == 1
    s = s.replace(a, "- **Sustained base-64 nice-only load draws more than the benchmark figures above** (2026-11-26, plug averaged over whole runs on the RTX 3060): the production join on 1e17 fields **250–265 W** (the card itself 151 W by nvidia-smi), the middle-out join 272–278 W (card 157 W, five host threads), the GTX 1060 alone on the middle-out join 217 W. At 265 W the whole machine costs $0.047 an hour. One hour of builds and tests used 0.21 kWh.\n" + a)
if "Installed `just` 1.59.0" not in s:
    s = s.rstrip("\n") + "\n- 2026-11-26: Installed `just` 1.59.0 with cargo (`~/.cargo/bin/just`). Recorded wall power under sustained base-64 load.\n"
open(p, "w").write(s); print("ok")
