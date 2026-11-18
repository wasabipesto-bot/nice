//! The middle-out join (development; working name, `G2` in the research
//! notes): a nice-only search whose work unit is a range of a per-base
//! coordinate instead of a range of n. Additive: no production route reaches
//! it, and nothing outside this module depends on it.
//!
//! - [`coord`]: the work unit. A field is `(base, v_start, v_size)`; it fixes
//!   a few central digits of n (6–8 at base 64) and nothing else. This is the
//!   only part that would ever touch the server, and it knows nothing of the
//!   join.
//! - [`cpu`]: the join's exact CPU reference (any base 3–128, generic masks),
//!   the oracle for the device path and for audits.
//! - `gpu` (feature `cubecl`): the device path at base 64.
//!
//! A search of a field returns its nice numbers and two exact counters,
//! `survivors` and `checked` ([`cpu::FieldOutcome`]); both are properties of
//! (shape, field), so they are reported with the shape's label.

// Development code (the port's kernels keep their own style; arithmetic
// names follow the papers' single letters).
#![allow(
    clippy::chunks_exact_to_as_chunks,
    clippy::manual_midpoint,
    clippy::manual_range_contains,
    clippy::manual_rotate,
    clippy::many_single_char_names,
    clippy::missing_panics_doc,
    clippy::must_use_candidate,
    clippy::needless_for_each,
    clippy::too_many_lines,
    clippy::type_complexity
)]

pub mod arith;
pub mod coord;
pub mod cpu;
#[cfg(feature = "cubecl")]
pub mod gpu;
pub mod mask;

pub use coord::Coord;
pub use cpu::{FieldOutcome, Shape};
