# Sourced by every research script on eventeo. Nothing here may reach the production API:
# the default address is replaced by a closed local port, and scripts pass --api-base explicitly as well.
export NICE_API_BASE=http://127.0.0.1:9
export CUDA_DEVICE_ORDER=PCI_BUS_ID
export R=$HOME/research            # persistent research root (scripts, binaries, runs)
export SRC=$HOME/projects/nice     # the clone; worktrees under $SRC/.worktrees
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
