# ~/claude on mayalaran

Persistent folder of the research agent for the "nice" project (created 2026-11-26 with the owner's permission:
"You may create a new folder within the home directory for persistence"). Everything the agent keeps on this
machine is here; nothing outside it is written (cargo's registry is redirected to `cargo-home/`; the Rust
toolchains are the ones rustup already has).

- `scripts/`  env.sh (sourced by every script; replaces the production API address by a closed local port), build and run scripts
- `src/`      clone of the project (remote `fork` = wasabipesto-bot/nice), worktrees per branch
- `t/`        cargo target directories (safe to delete)
- `bin/`      built binaries by tag
- `runs/`     logs of runs by date
- `cargo-home/` cargo registry cache (safe to delete)

To remove everything: `rm -rf ~/claude`. No services, launch agents or cron entries are installed.
