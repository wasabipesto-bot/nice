**Problem.** On any host that is not x86-64 (Apple Silicon, for example) `cargo clippy -p "*" --all-targets -- -D warnings`, the second command of `just lint`, fails on main:

- `unused_self` at `common/src/cpu_join.rs:986` (`pass1`),
- `unused_mut` at `common/src/cpu_join.rs:2093` (the `joins` of the pass-1 test).

Both bindings are used only on the x86-64 AVX paths. CI's lint job runs on Linux x86-64, so it never sees this.

**Change.** The two sites get an `allow` that applies on other targets only (`cfg_attr(not(target_arch = "x86_64"), …)`), the form `stride_filter.rs` already uses. Nothing changes on x86-64 and no code is compiled differently anywhere.

**Checked** on an Apple M4, each with a fresh target directory: main fails with exactly these two errors; with the change the command passes. (The third command of `just lint`, with `nice_client/cubecl-spirv`, does not build on macOS for an unrelated reason: `cubecl-wgpu`'s build script wants the Vulkan SDK. Not touched here.)

No changelog line: nothing a user of the client sees.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
