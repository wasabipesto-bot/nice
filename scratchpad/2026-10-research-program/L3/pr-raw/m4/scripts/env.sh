D="$HOME/claude-exp-2026-10-30-fd"
export PATH="$HOME/.cargo/bin:$PATH"
export CARGO_HOME="$D/cargo"
export CARGO_TARGET_DIR="$D/target"
export CARGO_NET_OFFLINE=true
[ -f "$D/toolchain.env" ] && . "$D/toolchain.env"
