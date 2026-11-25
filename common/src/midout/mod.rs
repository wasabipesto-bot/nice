//! The middle-out join (development; a working name): a nice-only search
//! whose work unit is a range of a per-base coordinate instead of a range of
//! n. The client's `midout` mode (`nice_client midout`) is its only user;
//! nothing outside this module depends on it, and no server stores its
//! fields yet.
//!
//! - [`coord`]: the work unit. A field is `(base, v_start, v_size)` of a
//!   coordinate named in the claim; base 64's default fixes a few central
//!   digits of n (5–7) and nothing else. This is the only part that would
//!   ever touch the server, and it knows nothing of the join.
//! - [`cpu`]: the join's exact CPU reference (any base 3–128, generic masks),
//!   the oracle for the device path and for audits.
//! - `gpu` (feature `cubecl`): the device path at base 64.
//! - `gpu_wide` (feature `cubecl`): the device path with two-word masks,
//!   bases 65–70 (and any base up to 70 in its tests).
//! - `route` (feature `cubecl`): one entry point for the client's mode (the
//!   path per base, telemetry).
//! - [`wire`]: the mode's endpoints (`GET /claim/midout`, `POST
//!   /submit/midout`) with their types and statuses, and the guard every
//!   other mode applies to a claim.
//!
//! The examples of `nice_common` that go with it: `midout_bench` (whole
//! base-64 fields on one device, in fs per admissible n) and
//! `midout_wide_bench` (the wide path, bases 64–70), both with the feature
//! `midout-bench`; `midout_fields` (a work list for the development server
//! `scripts/midout_coordinator.py`, which serves the mode's two endpoints on
//! one machine). Each prints its options with `--help`.
//!
//! A search of a field returns its nice numbers and two exact counters,
//! `survivors` and `checked` ([`cpu::FieldOutcome`]); both are properties of
//! (shape, field), so the route reports them with the shape (`"shape": [f0,
//! k]` in its telemetry).
//!
//! # Tests: three tiers
//!
//! - **(a) ordinary** (not ignored, CPU only, seconds): the coordinate, the
//!   CPU reference against brute force on small bases, the top certificate,
//!   the wire and route logic, a sampled coordinate partition. They run in
//!   every `cargo test` (the device modules' ones with `--features cubecl`).
//!   The client's `midout_route` tests belong here too: the mode's options,
//!   and its loop driven with the CPU reference on bases 10 and 20 against
//!   the development server on 127.0.0.1 (they need `python3`, and say so
//!   when they skip for want of it).
//! - **(b) device, CI-sized** (`#[ignore]`, named `cubecl_midout_*`): one
//!   base-64 slice's first batch against the CPU reference (with and without
//!   shared parents), the check's rebuild of one class, every fault loud on
//!   one slice, and a base-40 slice and its faults on the wide path. No
//!   staged data, 4 classes per batch (lavapipe's bindings are at most
//!   128 MiB). CI's lavapipe job runs them with both compilers: `cargo test
//!   --release --features cubecl -p nice_common -- --ignored` (WGSL) and
//!   `--features cubecl-spirv ... -- --ignored cubecl_` (SPIR-V). On a CUDA
//!   card: `--features cubecl-cuda` and `MIDOUT_CUDA=1`.
//! - **(c) card-only or long** (feature `midout-box-tests`, in no default
//!   or umbrella set, so CI never builds them): whole slices and fields,
//!   both coordinates against each other, the CUDA audits (sweep, key and
//!   group independence, out-of-memory), the full coordinate partition, the
//!   staged-reference tests and the profiles. Their sizes come from
//!   `MIDOUT_*` and `AUDIT_*` variables, each documented on its test; for
//!   example `MIDOUT_CUDA=1 cargo test --release -p nice_common --features
//!   cubecl-cuda,midout-box-tests --lib -- --ignored gpu_slices_equal_cpu`.

pub mod arith;
pub mod coord;
pub mod cpu;
#[cfg(feature = "cubecl")]
pub mod gpu;
#[cfg(feature = "cubecl")]
pub mod gpu_wide;
pub mod mask;
#[cfg(feature = "cubecl")]
pub mod route;
pub mod wire;

pub use coord::Coord;
pub use cpu::{FieldOutcome, Shape};
