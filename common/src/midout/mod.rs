//! The middle-out join (a working name): a nice-only search whose unit of
//! work is a *field* of a new kind, a range of a per-base coordinate `v`
//! rather than a range of `n`.
//!
//! The search pairs certified prefixes of `n` (tops) with certified
//! suffixes (bottoms) inside *slices*, sets of `n` that share a few middle
//! digits. At base 64 a slice is all `n` with one value of digits 4–8. A
//! field fixes fewer of those digits (5–7 at base 64), so every field is a
//! whole number of slices and the search may cut it any way it likes.
//!
//! This module holds, so far, only [`coord`]: what a field is, the maps
//! between `n` and `v`, and how fields cover a base's range. Nothing uses
//! it yet: no client route, no server, no stored data.

pub mod coord;

pub use coord::Coord;
