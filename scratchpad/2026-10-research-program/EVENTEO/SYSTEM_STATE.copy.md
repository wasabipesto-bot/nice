# System State

This document describes the environment you are running in. Read it at the start of every session. If you change system state (install a tool, add a config file, start a long-running service, create a directory structure, change an env var), update the relevant section before ending the session and append a dated entry to the Changelog at the bottom.

---

## Identity and access

- You are user `claude` (uid 1001) on **eventeo**, a home desktop on the owner's LAN (ASUS M5A97 LE R2.0 board, BIOS 2601). Another human account, `justin` (uid 1000), also exists; its home is not yours to touch.
- **No sudo** (`sudo` asks for a password). If a task needs root, stop and ask the owner.
- You have free rein inside `/home/claude`. Anything outside it is the owner's.
- Login is through **Tailscale SSH** (`RunSSH: true`): `ssh claude@eventeo` from the tailnet. Tailnet ACLs decide who may log in, not `authorized_keys`.
- Time zone is **America/New_York** (logs, cron and `systemctl list-timers` show EST/EDT; the nice client logs UTC).

## Hardware

| | |
|---|---|
| CPU | AMD FX-6300 (Piledriver, 2012): 6 cores in 3 modules (each module pair shares one FPU), 3.5 GHz, governor `schedutil` |
| CPU features | SSE4.2, AVX, FMA3, FMA4, XOP, BMI1, TBM, F16C, AES. **No AVX2, BMI2, ADX, SHA or AVX-512.** Never build with `-C target-cpu=x86-64-v3` or copy binaries built with it from elsewhere: they die with SIGILL here. |
| RAM | 16 GB, plus 976 MB swap on `sda3` |
| GPU 0 | **NVIDIA GeForce GTX 1060 3GB** (GP106, Pascal, cc 6.1, 3 GB, 120 W limit), PCI 01:00.0, PCIe 2.0 x16 slot. Idles at about 10–12 W (P5). |
| GPU 1 | **NVIDIA GeForce RTX 3060 12GB** (GA106 LHR, HP OEM board, cc 8.6, 12 GB, 170 W limit), PCI 05:00.0, installed 2026-11-26. The slot links at **x4** (PCIe 2.0 max on this board); benchmarks show no loss from it. Idles at about 4 W (P8). |
| PSU | EVGA 750 W G2 (PN 220-G2-0750; owner, 2026-11-26). It only matters if more cards are added, e.g. on a riser: the wall peak with both cards is about 320 W. |
| Disk | Samsung 840 PRO 256 GB SSD: `sda2` ext4 237 GB `/` (about 200 GB free on 2026-11-25), `sda1` EFI |
| `/tmp` | 7.8 GB **tmpfs** (RAM-backed). Keep cargo target dirs and big scratch on disk. |
| Sensors | `sensors`: `k10temp` temp1 reads far too low on FX chips (it showed 13 °C at idle), so trust it only for trends. `fam15h_power` reports CPU package power (about 45–65 W at idle). GPU temperature and power come from `nvidia-smi`. |

A **NanoKVM** the owner used for setup is attached by USB. It shows up as `sdb` (22 GB exFAT "USB Mass Storage", not mounted) and network interface `enx7228bd9a7d47` (10.10.91.100/24). Leave both alone.

## Wall power metering

eventeo is plugged into a ThirdReality Zigbee smart plug (`0x282c02bfffec51b1`, "Smart Plug A"). The chain is zigbee2mqtt → Home Assistant, both on celebrimbor.
- **Power (W)**: Prometheus (shalash) `hassio_sensor_power_w{entity="sensor.0x282c02bfffec51b1_power"}`, plus `hassio_sensor_voltage_v` and `hassio_sensor_current_a`. Exported since 2026-11-26 00:2x UTC, after the owner added the `*_power`, `*_voltage` and `*_current` globs to HA's prometheus filter. Scraped every 30 s. The plug reports on change, every 2–5 s under load, with a heartbeat about every 5 min at idle. For finer resolution, HA's recorder holds about 10 days of every report (read-only via `ssh justin@celebrimbor`, `file:/opt/homeassistant/home-assistant_v2.db?mode=ro`, states ⨝ states_meta).
- **Energy (kWh)**: exported to Prometheus on shalash as `hassio_sensor_energy_kwh{entity="sensor.0x282c02bfffec51b1_energy"}`, scraped every 30 s. It's correct but has only **0.01 kWh resolution** (it ticks about every 10 min at idle), so `rate()` over less than about 1 h is a staircase. The plug has a "Reset total energy" button, so the counter can reset.
- **Measured at the wall** (time-weighted from the recorder, nice v3.4.8 `--benchmark-secs 150`). With the 1060 only: idle **51 W**, 1060 niceonly **161 W**, 1060 detailed **171 W**, CPU niceonly (4 threads) **114 W**. With both cards installed (2026-11-26): idle **64.5 W**, 3060 niceonly **187 W**, 3060 detailed **198 W**, both cards niceonly **258 W** (peaks of about 320 W). Soft-off standby is about 2 W. A 6-job cargo build draws about 95–130 W. Voltage is about 122 V at 60 Hz.
- **Sustained base-64 nice-only load draws more than the benchmark figures above** (2026-11-26, plug averaged over whole runs on the RTX 3060): the production join on 1e17 fields **250–265 W** (the card itself 151 W by nvidia-smi), the middle-out join 272–278 W (card 157 W, five host threads), the GTX 1060 alone on the middle-out join 217 W. At 265 W the whole machine costs $0.047 an hour. One hour of builds and tests used 0.21 kWh.
- **Electricity**: $160 for 902 kWh on a recent bill, so **$0.177/kWh** all-in (marginal is a bit lower). Idle 24/7 costs about $6.60/month.
- **Throughput vs the RTX 3060 median** (public benchmarks, v3.4.8): GPU niceonly ×0.17 at b60–b62 (×0.23–0.27 at b58), GPU detailed ×0.43, CPU niceonly ×0.007–0.009. NiceMark isn't proportional across CPU and GPU, so compare per-scenario rates instead.
- **Cost per RTX-3060-hour equivalent** (hurdle in the GPU buy model: $0.040). Because eventeo now stays off when unused, the right figure is the **whole-machine** cost:
  - **3060 niceonly: $0.033 (0.83× the hurdle)**, about $24/month at 24/7.
  - 3060 detailed: $0.035 (0.89×).
  - Both cards niceonly: $0.039 (0.98×). Adding the 1060 to a running 3060 costs about 70 W for another ×0.17, which is $0.073 per 3060-hour (1.8×), so it isn't worth it.
  - 1060 alone (old figures): $0.168 whole machine, $0.115 above idle.
  - CPU niceonly: never.

## Power cycling (keep it off when unused)

The owner's policy (2026-11-26): eventeo stays **off when unused** and gets woken for tests and development. Power it off when you're done, unless the owner asked for it to stay up or something long-running needs it.
- **Off**: `systemctl poweroff`. A polkit rule (`/etc/polkit-1/rules.d/50-claude-power.rules`, owner-installed) lets `claude` power off and reboot without a password, including while the owner's `justin` session is logged in. Shutdown takes about 10 s. Standby draw is **2 W** with WoL armed.
- **On**: Wake-on-LAN. Run `~/.local/bin/wake-eventeo` **on ivory**. It ssh's to `justin@celebrimbor` (the default sender; mayalaran, 192.168.1.247, also works and was tested 2026-11-26: up in 44 s), which is on the same LAN (192.168.1.248), and broadcasts a magic packet for MAC `2c:56:dc:d4:4e:33` to 192.168.1.255 and 255.255.255.255 on port 9. Then it waits for ssh. The broadcast can't cross Tailscale, so it has to be sent from a LAN host. Measured 2026-11-26: power rises about 2 s after the packet, and **ssh is usable after about 50 s**. A plain reboot takes about 60 s.
- WoL is armed by `ethernet-wol g` under `iface enp2s0` in `/etc/network/interfaces` (owner-added, needs `ethtool`). It applies at ifup, so it took a reboot to take effect the first time. Check with `cat /sys/class/net/enp2s0/device/power/wakeup` (should read `enabled`). `ethtool enp2s0` can't show Wake-on without root.
- Before powering off, check that nothing is running (`pgrep -a nice_client`, `podman ps`, `who`). It kills the owner's desktop session too.
- **After a power cut** (the plug unplugged or switched off, then restored), WoL does **not** work: tested 2026-11-26, with packets from mayalaran and celebrimbor ignored at 1.8 W standby. The NIC is armed only by a clean shutdown, so the owner has to boot it by hand. After that, WoL works again.
- If WoL ever fails: the owner checks the BIOS (APM: ErP Ready Disabled, Power On By PCIE/PCI Enabled). Fallback: BIOS "Restore AC Power Loss = Power On" plus the smart plug (`switch.0x282c02bfffec51b1` in HA). Only cut the plug after a clean shutdown.
- Uptime is no longer continuous. Don't assume user services, timers or containers ran while it was off.

## Who uses this box (owner, 2026-11-26)

The owner gave the nice research program's director **primary lease**: "you have primary lease on that box as well
and can boot or shutdown whenever you need it, and you can persist whatever you need inside your claude home
directory." Both GPUs are for development and tests. No 24/7 client for now; if that changes it will likely be a
user service under `claude` that the director may stop and resume. The owner may log in between runs.
- Research jobs live under `~/research` and never contact the production API (`scripts/env.sh`).
- **End every job with `bash -l ~/research/scripts/off_if_idle.sh`**: it powers the box off unless someone other
  than `claude` is logged in, a client/build/test is running, a container is up, or `~/research/keep-up` exists.
- Build times, cold (FX-6300, 6 jobs): `nice_common` test binary with the card tier 3 min 45 s, the three midout
  examples 5 min 20 s, `nice_client --features gpu` 6 min 20 s.

## OS and system services

- Debian 13 (trixie), kernel **6.12.118+deb13-amd64** (first booted 2026-11-26; the NVIDIA DKMS module works on it).
- `unattended-upgrades` is active, so Debian security updates (kernel, the DKMS NVIDIA module) can land without anyone acting. After an unexpected GPU failure, compare `nvidia-smi` and `uname -r` against this doc.
- Running system services of note: `tailscaled`, `ssh` (OpenSSH on `0.0.0.0:22`/`[::]:22`), `nvidia-persistenced`, `exim4` (loopback :25 only), `avahi-daemon`, `NetworkManager`, `cron`.
- No firewall is active (`nftables`, `ufw` and `firewalld` are all inactive).
- Desktop leftovers (`accounts-daemon`, `upower`, `switcheroo-control`, `ModemManager`) are present. Ignore them.

## Network

- LAN: `enp2s0` 192.168.1.251/24, gateway 192.168.1.254 (AT&T residential). Public IPv4 egress is 107.198.152.46 (NAT). The host also has a **global IPv6 address** (2600:1702:696a:f860:…:4e33), which outbound traffic prefers.
- **Inbound from the internet**: on 2026-11-25, port 22 on the public IPv6 address timed out from a Hetzner host, so the router blocks unsolicited inbound IPv6. sshd still allows passwords (the Debian default) on the LAN, and no host firewall exists. Treat the router as the only perimeter, and bind new services to the tailnet IP or loopback, never `0.0.0.0`.
- Tailscale: `tailscale0` 100.106.103.100 / fd7a:115c:a1e0::2033:6765, MagicDNS `eventeo.neon-locrian.ts.net`. It is a tagged device. Unlike on ivory, **`tailscale status` works for `claude`**. Whether `tailscale serve` or `set` work for you is untested.
- From ivory, eventeo is reached directly over IPv6 (not through DERP).
- One `podman pull` from Docker Hub's CloudFront got a connection reset over IPv6 and succeeded on retry. If pulls keep failing, suspect the IPv6 path.

## Home directory layout

```
/home/claude/
├── .bashrc / .profile    # source ~/.cargo/env, ~/.local/bin/env and nvm (installed by the owner 2026-11-25)
├── .ssh/id_ed25519       # GitHub key "GitHub CLI" on wasabipesto-bot (added 2026-11-25); git over ssh works
├── .config/gh/           # gh auth for wasabipesto-bot (scopes: repo, read:org, gist, admin:public_key)
├── .cargo/ .rustup/      # Rust (rustup)
├── .local/bin/           # claude, uv, uvx
├── .nvm/                 # Node via nvm
├── .claude/ .claude.json # Claude Code state
├── nice-bin/v3.4.8/      # nice release binaries: gpu/nice_client, cpu/nice_client (sha256-verified)
├── projects/nice/        # clone of wasabipesto/nice (origin https, main)
│                         # remote `fork` = wasabipesto-bot/nice (https); worktrees under projects/nice/.worktrees/
├── research/             # the nice research program's root on this box (2026-11-26)
│   ├── scripts/          # env.sh (sourced by every script: closed-port NICE_API_BASE, CUDA_DEVICE_ORDER=PCI_BUS_ID),
│   │                     # build_mo.sh BRANCH TAG, run_mo.sh TAG GPU RUN PHASES, off_if_idle.sh, env_vulkan.sh, vkprobe.py
│   ├── vk/               # unpacked libegl-nvidia0 + 10_nvidia.json: the Vulkan workaround (see the GPU table)
│   ├── bin/TAG/          # built binaries by tag      ├── t/     cargo target dirs (safe to delete)
│   ├── logs/TAG/         # build logs                 └── runs/  run outputs by name
├── nice-build.log        # first source build log (2026-11-25)
│                         # projects/nice/target/ ≈ 1.3 GB release build
└── SYSTEM_STATE.md       # this file
```

Store project work under `~/projects/`.

## Installed tools

### Owner-installed for you (2026-11-25)
- **Rust** via rustup: stable 1.100.0 (`cargo`, `clippy`, `rustfmt`, `rust-analyzer`). This matches nice's pinned `rust-toolchain.toml` (1.100.0).
- **uv** 0.13.10. Only Python 3.13.5 is available (system). Use `uv run` or `uv venv`, never global pip.
- **nvm**: Node 24.22.3 (default) and 20.20.2; npm 11.19.1.
- **gh** 2.106.0, logged in as `wasabipesto-bot`, git protocol ssh.
- **Claude Code** 2.1.332 at `~/.local/bin/claude`.
- **Podman** 5.4.2 (rootless) with the `podman-docker` shim and Debian `docker-compose` 2.26.1. See "Containers".
- **Tailscale** 1.104.7.

### System packages already present
- CUDA: **`nvidia-cuda-toolkit` 12.4.131** from Debian (`nvcc` at `/usr/bin/nvcc`, toolkit tree at `/usr/lib/cuda`, `libnvrtc.so.12` 12.4, Nsight Compute and Systems, cuda-gdb). There is no `/usr/local/cuda`.
- NVIDIA driver **550.163.01** (DKMS). Its CUDA ceiling is **12.4**. OpenCL ICD: `nvidia.icd`.
- `git`, `gcc`/`make`/`pkg-config`, `tmux`, `screen`, `htop`, `btop`, `rsync`, `sshfs`, `curl`, `wget`, `python3`, `sensors`.
- Added by the owner 2026-11-25: `jq`, `perf` (6.12.118), `nvtop`, `nvidia-vulkan-icd`.
- **`just` 1.59.0** is in `~/.cargo/bin` (cargo-installed 2026-11-26; `just lint` is the project lint bar).
- `strace` and `vulkan-tools` (`vulkaninfo`): installed by the owner 2026-11-26.
- **Missing**: `cmake`, `clang`, `sqlite3`, `psql`. They need the owner or a container.

### PATH gotcha
Non-interactive `ssh eventeo 'cmd'` gets only `/usr/local/bin:/usr/bin:/bin`: cargo, uv, node and claude are **not** on PATH. Use `ssh eventeo 'bash -lc "…"'`, or run a script with `bash -l script.sh`. For nvm, also `source ~/.nvm/nvm.sh`. When you pipe a script over ssh's stdin, any inner command that reads stdin eats the rest of it, so copy the script over with `scp` and run it with `</dev/null`.

## GPU: what works (tested 2026-11-25)

The GPUs' job here is the **nice** client. Run it **natively, not in a container**.

**Device numbering:** CUDA numbers devices fastest-first by default, but nvidia-smi uses PCI order (0 = 1060, 1 = 3060). Always export `CUDA_DEVICE_ORDER=PCI_BUS_ID` so that `--gpu-device N` matches nvidia-smi index N. Confirm the card with `nvidia-smi --query-gpu=index,utilization.gpu --format=csv` during a run. The results in the table below are from the 1060 unless stated. The RTX 3060 behaves the same way: cubecl-cuda is fastest, hand CUDA works, and Vulkan falls back to llvmpipe.

| path | result |
|---|---|
| CUDA driver API + NVRTC 12.4 | Works. The nice release binary dlopens the system `libnvrtc.so.12`. PTX from NVRTC 12.4 loads on driver 550. |
| `--gpu-backend cubecl-cuda` (`auto` picks it) | Works natively and is the **fastest** backend. |
| `--gpu-backend cuda` (hand CUDA) | Works, about 7.7× slower than cubecl-cuda in detailed mode on this card. |
| `--gpu-backend cubecl` (wgpu/Vulkan) | **Works with a per-user workaround (2026-11-26); without it wgpu falls back to llvmpipe.** Cause: with no display attached, NVIDIA's Vulkan driver (`libGLX_nvidia.so.0`) initialises through EGL, and Debian's `libegl-nvidia0` (libEGL_nvidia.so.0) and its glvnd vendor file are not installed, so glvnd finds only Mesa's EGL and the driver returns NULL for `vkCreateInstance` (strace: it reads `/usr/share/glvnd/egl_vendor.d`, loads Mesa, never opens `/dev/nvidia*`). Workaround, no root: the package is unpacked under `~/research/vk` (`apt download libegl-nvidia0 && dpkg-deb -x`) with a hand-written vendor file; `. ~/research/scripts/env_vulkan.sh` sets `__EGL_VENDOR_LIBRARY_FILENAMES` to it (and refuses if the unpacked library's version differs from the loaded driver's: then download and unpack again). With it `vulkaninfo --summary` lists both cards (Vulkan 1.3.277) and wgpu adapters are `DiscreteGpu(0)` = GTX 1060, `DiscreteGpu(1)` = RTX 3060 (`CUBECL_WGPU_DEFAULT_DEVICE` or the client's `--gpu-wgpu-device`). System-wide fix, if the owner prefers it: `apt install libegl-nvidia0 nvidia-egl-common` (not done: it could change which EGL the GNOME session uses). |
| nice `-gpu` container image | **Won't run**: it's built on CUDA 12.8, which needs driver ≥ 570. The fleet's `min_cuda_version` rule exists for the same reason. |
| Rootless podman + GPU | Partly works without nvidia-container-toolkit or CDI (neither is installed). `--device /dev/nvidia0 --device /dev/nvidiactl --device /dev/nvidia-uvm`, plus bind-mounting `libcuda.so.1`, `libnvidia-ptxjitcompiler.so.1` (without it: `CUDA_ERROR_JIT_COMPILER_NOT_FOUND`), `libnvrtc.so.12`, `libnvrtc-builtins.so.12.4`, `/etc/ssl/certs`, `/usr/lib/cuda` and `/usr/include` (with `CUDA_PATH=/usr/lib/cuda`), runs nvidia-smi and the hand-CUDA backend. CubeCL CUDA's kernel compile still failed inside the container, so it dropped to hand CUDA. |

### Driver version: stay on Debian's 550 (checked 2026-11-25)
- **Nothing pins the driver in apt** (no `preferences.d` entries, no `apt-mark` holds). 550.163.01 is simply the newest NVIDIA driver in every Debian suite: trixie, trixie-backports and sid (555 is only in experimental). The owner installed it 2026-09-18 with `apt install nvidia-kernel-dkms nvidia-smi libcuda1 nvidia-cuda-toolkit`.
- **Going to ≥ 570 means leaving Debian's packages** for NVIDIA's CUDA apt repo or the `.run` installer. That would replace the whole stack: the kernel module, libcuda, the GLX/EGL/Vulkan libraries that the GNOME/gdm3 desktop on this box also uses, and in practice Debian's CUDA 12.4 toolkit too. `unattended-upgrades` only follows Debian origins, so those packages would stop getting automatic updates, while kernel updates (6.12.118 is already staged) keep arriving and rely on DKMS rebuilding a third-party module.
- **Pascal hazard:** the **580 branch is NVIDIA's last for Pascal (GTX 10xx)**. 590+ doesn't drive this card at all, and NVIDIA's repo metapackages pull the newest branch unless pinned. CUDA 13 also dropped offline compilation for anything below sm_75, so stay on a 12.x toolkit/NVRTC (12.9 is the last for sm_61).
- **Upside is small:** a newer driver would only let the nice `-gpu` container image (CUDA 12.8) run. Native nice already uses the fastest backend on 550.
- The DKMS module is already built for the staged kernel 6.12.118 (`/lib/modules/6.12.118+deb13-amd64/updates/dkms/nvidia-current*.ko.xz`), so the next reboot should keep the GPU.

`/dev/nvidia*` are mode 666, so no group membership is needed. `claude` is not in `video` or `render`, which only matters for `/dev/dri` (unused).

### nice v3.4.8 benchmark: RTX 3060 (device 1, 2026-11-26)

| mode | backend | NiceMark | headline numbers/sec | vs public RTX 3060 median |
|---|---|---|---|---|
| detailed | cubecl-cuda | **1459–1472** | b40 1.48e10, b50 1.31–1.33e10 | ×0.99–1.00 |
| detailed | hand CUDA | 415 | b40 4.7e9, b50 3.4e9 | — |
| niceonly | cubecl-cuda (join) | **1417–1421** | b58 weak 2.2e14, b60 weak 4.4–4.5e14, b62 weak 5.7e14 | ×1.01–1.03 |

Both cards running niceonly at the same time slowed neither card: the 3060 gave NiceMark 1417 and the 1060 gave 295. The 3060 peaked at 62 °C.

### nice v3.4.8 benchmark: GTX 1060 (release binaries, `--benchmark`, offline with `NICE_API_BASE=http://127.0.0.1:9`)

| mode | device | NiceMark | headline numbers/sec |
|---|---|---|---|
| detailed | GPU cubecl-cuda | **637–638** | b40 6.4e9, b50 5.8e9 |
| detailed | GPU hand CUDA | 83 | b40 9.6e8, b50 6.5e8 |
| detailed | GPU wgpu → llvmpipe | 5 | (CPU fallback; ignore) |
| detailed | CPU (4 threads) | 222 | b50 3.8e7, 1 thread 1.1e7 |
| niceonly | GPU cubecl-cuda (join) | **293** | b58 weak 5.1e13, b60 weak 7.6e13, b62 weak 9.5e13 |
| niceonly | CPU (4 threads) | 192 | b60 weak 3.0e12, b62 weak 3.1e12 |

Under load the GPU ran at 98–100 % utilisation, 1885–1898 MHz, 85–92 W, and at most 64 °C. Niceonly used about 1.9 GB of the 3 GB VRAM by b62, so watch VRAM at b64 and above, and before raising batch size.

To run against the real server, drop the `NICE_API_BASE` override. For a long-running client, start it with `nohup` or in `tmux`, or as a user systemd service (it won't survive a reboot without linger; see below).

### Building nice from source
`cargo build --release -p nice_client --features gpu` in `~/projects/nice` works with no extra setup. A cold build took **6 min wall** (16 min CPU, 6 jobs) and leaves a 1.3 GB `target/`. The result found the system CUDA by itself and ran cubecl-cuda at NiceMark 634 (v3.4.9-dev, main fdbe07d). Use a target dir on disk (the default `target/`), not `/tmp`. `/usr/bin/time` is not installed, so use bash's `time`.

## Containers (rootless podman)

- Podman 5.4.2, rootless, cgroup v2, netavark, overlay storage in `~/.local/share/containers`. Subordinate IDs 165536–231071.
- `docker` is the `podman-docker` shim. `docker compose` → Debian `docker-compose` 2.26.1 over the user socket `/run/user/1001/podman/podman.sock` (`podman.socket`, enabled 2026-11-25).
- **Linger is on** (the owner enabled it 2026-11-25), so the user manager runs at boot without a login. `podman-restart.service` (user) is enabled, but the stock unit only restarts `restart: always` containers. Add an `unless-stopped` drop-in like ivory's if you need one. Side effect: PipeWire and WirePlumber now run in your user manager. They're harmless.
- No `~/.config/containers/registries.conf`, so use **fully qualified image names** (`docker.io/library/debian:trixie-slim`).
- Volume contents are owned by subordinate UIDs. Inspect or delete them with `podman unshare`, never plain `rm`. `run --rm` removes anonymous volumes. `rm -f` without `-v` leaks them. Never run a bare `volume prune`.
- Images on disk: `docker.io/library/debian:trixie-slim` (81 MB, pulled 2026-11-25 for the GPU-passthrough test).

## What root has that you don't

- apt packages (nvidia-container-toolkit, a newer driver, `vulkan-tools`, …)
- NVIDIA driver and kernel changes, the WoL config, persistence mode, power limits (`nvidia-smi -pl`), clocks
- Firewall rules, sshd config, `/etc/containers`, users and groups

If you need one of these, stop and say so rather than working around it.

---

## Changelog

*Append an entry whenever you change system state. Format: `YYYY-MM-DD: description`*

- 2026-11-25: Owner set up the `claude` account: Tailscale, Podman, gh, Rust, uv, nvm, Claude Code.
- 2026-11-25: Initial document created from a capability survey. Added the GitHub known-hosts entry, downloaded nice v3.4.8 release binaries to `~/nice-bin/v3.4.8` (checksums verified), ran offline benchmarks (results above), pulled `debian:trixie-slim` for a GPU-passthrough test, cloned `wasabipesto/nice` to `~/projects/nice`, and built `nice_client --features gpu` from main fdbe07d (6 min cold, log `~/nice-build.log`, 1.3 GB `target/`).
- 2026-11-25: Owner enabled linger and installed `jq`, `perf`, `nvtop` and `nvidia-vulkan-icd`. The Vulkan ICD still fails to create an instance (see GPU table). Enabled user `podman.socket` and `podman-restart.service`. Recorded the driver-version findings (stay on 550). Identified the USB devices as the setup NanoKVM.
- 2026-11-26: Documented wall-power metering (smart plug via z2m/HA on celebrimbor; only the energy counter reaches Prometheus). No change on eventeo.
- 2026-11-26: Power (W), voltage and current now exported to Prometheus (owner changed the HA filter). Measured wall power per nice workload and recorded the electricity rate and cost figures (see "Wall power metering").
- 2026-11-26: The owner set `ethernet-wol g` on enp2s0, installed ethtool, and added the polkit power rule. Rebooted into 6.12.118 (GPU OK, WoL armed), then ran a full poweroff → 2 W → WoL-from-celebrimbor → up in 50 s cycle. Added `wake-eventeo` on ivory. New policy: keep eventeo off when unused.
- 2026-11-26: The owner installed an RTX 3060 12GB (05:00.0, x4 link) next to the 1060. Detection, driver and benchmarks are OK (it matches the public 3060 median) and wall power was measured. WoL fails after AC loss (manual boot needed), and was verified working from mayalaran after a clean shutdown.
- 2026-11-26: Research director's first session under the primary lease: WoL from ivory (ssh up in 42 s), created `~/research` (scripts, binaries, runs), added the git remote `fork` and the worktree `projects/nice/.worktrees/mo-mode`, built and ran the middle-out branch on both cards, added the PSU to the hardware table, wrote `off_if_idle.sh`, powered off at the end. Vulkan on the NVIDIA cards still fails before the driver touches `/dev/nvidia*` (traced with cuda-gdb; `strace` and `vulkan-tools` would help).
- 2026-11-26: Installed `just` 1.59.0 with cargo (`~/.cargo/bin/just`). Recorded wall power under sustained base-64 load.
- 2026-11-26: The owner installed `strace` and `vulkan-tools`. Vulkan on the NVIDIA cards diagnosed (missing `libegl-nvidia0`; see the GPU table) and made to work per user from `~/research/vk`; the middle-out join's device tests pass through Vulkan on the RTX 3060 (`NVIDIA GeForce RTX 3060 (Vulkan, wgpu<wgsl>)`), whole base-64 fields at 3.30 fs per admissible n against 3.23 through CUDA.
