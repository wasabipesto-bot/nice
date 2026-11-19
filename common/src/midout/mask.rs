//! Digit masks: one bit per digit of the base. The CPU reference is generic
//! over the word: `u64` up to base 64, `u128` above it, through the same
//! code (its tests run both words on the same bases). The base-64 device
//! path takes the low word ([`Mask::low64`]); the wide device path
//! (`gpu_wide`) has its own kernels with two-word masks.

use std::ops::{BitAnd, BitAndAssign, BitOr, BitOrAssign, Not};

pub trait Mask:
    Copy
    + Eq
    + Default
    + Send
    + Sync
    + std::fmt::Debug
    + BitAnd<Output = Self>
    + BitOr<Output = Self>
    + BitAndAssign
    + BitOrAssign
    + Not<Output = Self>
    + 'static
{
    /// Digits a mask can hold (the largest base it serves).
    const BITS: u32;
    #[must_use]
    fn bit(i: u32) -> Self;
    #[must_use]
    fn is_zero(self) -> bool;
    #[must_use]
    fn count_ones(self) -> u32;
    /// Lowest set digit (`BITS` for 0).
    #[must_use]
    fn trailing_zeros(self) -> u32;
    /// `self` without its lowest set digit.
    #[must_use]
    fn clear_lowest(self) -> Self;
    /// The low 64 digits (the device's word).
    #[must_use]
    fn low64(self) -> u64;
}

macro_rules! mask_impl {
    ($t:ty) => {
        impl Mask for $t {
            const BITS: u32 = <$t>::BITS;
            #[inline]
            fn bit(i: u32) -> Self {
                1 << i
            }
            #[inline]
            fn is_zero(self) -> bool {
                self == 0
            }
            #[inline]
            fn count_ones(self) -> u32 {
                <$t>::count_ones(self)
            }
            #[inline]
            fn trailing_zeros(self) -> u32 {
                <$t>::trailing_zeros(self)
            }
            #[inline]
            fn clear_lowest(self) -> Self {
                self & self.wrapping_sub(1)
            }
            #[inline]
            #[allow(clippy::cast_possible_truncation)]
            fn low64(self) -> u64 {
                self as u64
            }
        }
    };
}
mask_impl!(u64);
mask_impl!(u128);
