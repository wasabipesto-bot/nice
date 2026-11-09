#!/usr/bin/env python3
"""Scratch variants of the committed tree for in-place comparisons (never
committed): `notop` = the column form without the top's digits (every
check scans each power to its last digit); `v3` = the check of the L50
prototype's form (U256 n² and n³, two quotients by b^4 to drop the 8 known
digits, then five digits per quotient by b^5) seeded with the same digits
(low and top) and stopping at the same ends, for bases 58/60/62/64 at k2 = 8.
usage: variants.py notop|v3|restore  (run in the worktree)"""
import sys, subprocess
p = 'common/src/cpu_join.rs'
v = sys.argv[1]
if v == 'restore':
    subprocess.run(['git', 'checkout', p], check=True)
    sys.exit()
s = open(p).read()
old = '''        if self.check.nice(top.p, r0, low, top.seed, ends) {'''
assert s.count(old) == 1
if v == 'notop':
    new = '''        let _ = (top.seed, ends);
        if self.check.nice(top.p, r0, low, 0, [self.fs.base.s2, self.fs.base.s3]) {'''
elif v == 'v3':
    new = '''        let nice = if self.fs.k2 == 8 {
            match self.fs.b {
                58 => v3::<58, { 58 * 58 * 58 * 58 }, { 58 * 58 * 58 * 58 * 58 }>(n(), low | top.seed, ends),
                60 => v3::<60, { 60 * 60 * 60 * 60 }, { 60 * 60 * 60 * 60 * 60 }>(n(), low | top.seed, ends),
                62 => v3::<62, { 62 * 62 * 62 * 62 }, { 62 * 62 * 62 * 62 * 62 }>(n(), low | top.seed, ends),
                64 => v3::<64, { 64 * 64 * 64 * 64 }, { 64 * 64 * 64 * 64 * 64 }>(n(), low | top.seed, ends),
                _ => self.check.nice(top.p, r0, low, top.seed, ends),
            }
        } else {
            self.check.nice(top.p, r0, low, top.seed, ends)
        };
        if nice {'''
    s = s.replace('/// The first pass\'s compaction:', '''#[inline(always)]
fn scan5<const B: u32, const B4: u32, const B5: u32>(mut x: crate::fixed_width::U256, mut seen: u64, end: u32) -> Option<u64> {
    x.div_assign_rem_u32_const::<B4>();
    x.div_assign_rem_u32_const::<B4>();
    let mut pos = 8;
    loop {
        let mut r = x.div_assign_rem_u32_const::<B5>();
        for _ in 0..5 {
            if pos >= end {
                return Some(seen);
            }
            let d = r % B;
            r /= B;
            let bit = 1u64 << d;
            if seen & bit != 0 {
                return None;
            }
            seen |= bit;
            pos += 1;
        }
    }
}

#[inline(always)]
fn v3<const B: u32, const B4: u32, const B5: u32>(n: u128, seen: u64, ends: [u32; 2]) -> bool {
    let sq = crate::fixed_width::U256::mul_u128_u128(n, n);
    let Some(seen) = scan5::<B, B4, B5>(sq, seen, ends[0]) else {
        return false;
    };
    scan5::<B, B4, B5>(sq.mul_u128_truncating(n), seen, ends[1]).is_some()
}

/// The first pass's compaction:''', 1)
s = s.replace(old, new)
open(p, 'w').write(s)
