## What

Pin the two amd64 image jobs of the Docker workflow to `runs-on: ubuntu-24.04`, and update the
comment in `client/gpu.Dockerfile` that named `ubuntu-latest` as the build host. No source
change.

## Why

GitHub's `ubuntu-latest` label has started to resolve to Ubuntu 26.04 (glibc 2.43). The job
"Build (amd64, GPU) + Push arch image" builds `nice_client` on the runner and copies the binary
into the image of `client/gpu.Dockerfile`, whose base is
`nvidia/cuda:12.8.1-runtime-ubuntu24.04` (glibc 2.39). Built on a 26.04 runner, the binary no
longer starts in that image, and the job's smoke test fails:

```
/usr/local/bin/nice_client: /lib/x86_64-linux-gnu/libm.so.6: version `GLIBC_2.43' not found (required by /usr/local/bin/nice_client)
```

- Seen on both pushes of #260 (2026-11-14), on runner image `ubuntu-26.04` 20261111.82.6. The
  same job passed on #259 and on main the day before, on `ubuntu-24.04` runners: the label gave
  24.04 on 2026-11-13 and 26.04 in #260's runs on 2026-11-14 (the amd64 image jobs, the Rust
  build and test jobs, the lavapipe job).
- It is unrelated to any PR's diff. Expect the next run on main or on any PR to fail the same
  way; on a release tag the job fails before the GPU image is pushed.
- The smoke test did what it was added for: nothing was pushed.

## The change

| job | before | after | why |
|---|---|---|---|
| Build (amd64, GPU) + Push arch image | `ubuntu-latest` | `ubuntu-24.04` | the failing job: the runner must not have a newer glibc than the image's Ubuntu 24.04 base |
| Build (amd64) + Push arch image | `ubuntu-latest` | `ubuntu-24.04` | same construction into Debian trixie (glibc 2.41); see below |
| Build (arm64) + Push arch image | `ubuntu-24.04-arm` | unchanged | already pinned |

The CPU amd64 job is not failing: in #260's run it was built on `ubuntu-26.04` and its smoke
test passed, which means today's CPU binary references no symbol newer than glibc 2.41. That
holds only until a dependency picks one up, and the multi-arch CPU image was being built on two
different Ubuntu releases. Pinning it is the same fix for the same reason; drop that hunk if
you would rather wait for it to fail.

## Not in this PR

- The other workflows keep `ubuntu-latest`. In #260's runs they already ran on `ubuntu-26.04`
  and passed: format and clippy, the workspace tests, the CUDA host tests, the Linux release
  builds with their glibc-floor assertions (the glibc binaries are built in the `cross`
  containers and the musl ones are static, so the runner's glibc does not reach them), and the
  lavapipe job. No other job copies a runner-built binary into an older image.
- The two image jobs cache `target/` under a key made of `runner.os` and the lockfile, not the
  runner release. Main's last runs (2026-11-13) were on 24.04, so the pin needs no cache
  change; putting the image into the key would be a separate hardening.
- Building the image binaries inside their base images (a multi-stage Dockerfile) would remove
  the dependency on the runner altogether. It is a larger change to the image builds.
- No changelog entry: no released artifact changes.

## Verification

This PR's own run of the two pinned jobs is the test: each builds the binary and runs it inside
the built image.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
