// Independent check: new count form vs the old form exactly as the kernel computes it.
// Old (main): seen = (mhi|thi)<<32 | (mlo|tlo); hit = OR of u32((seen << g) >> 32) over the four digits;
//   fail if any of six equalities or i32(hit) < 0.
// New: a = OR of (2^63 >> d); new = popcnt(u32(a) & !(mlo|tlo)) + popcnt(u32(a>>32) & !(mhi|thi)); pass iff new == 4.
// Both read seen only at bits 63-d for d in D, so for each digit 4-tuple in 0..64 we enumerate every assignment
// of those bits, with the other 60+ bits all-zero, all-one and random (and a random split between m and t words).

fn old(mlo: u32, mhi: u32, tlo: u32, thi: u32, g2: u32, g3: u32, h2: u32, h3: u32) -> bool {
    let seen = (u64::from(mhi | thi) << 32) | u64::from(mlo | tlo);
    let hit = ((seen << u64::from(g2)) >> 32) as u32
        | ((seen << u64::from(g3)) >> 32) as u32
        | ((seen << u64::from(h2)) >> 32) as u32
        | ((seen << u64::from(h3)) >> 32) as u32;
    let mut ok = true;
    if g2 == g3 || h2 == h3 || g2 == h2 || g2 == h3 || g3 == h2 || g3 == h3 || (hit as i32) < 0 {
        ok = false;
    }
    ok
}

fn new(mlo: u32, mhi: u32, tlo: u32, thi: u32, g2: u32, g3: u32, h2: u32, h3: u32) -> bool {
    let top = 0x8000_0000_0000_0000u64;
    let a = (top >> u64::from(g2)) | (top >> u64::from(g3)) | (top >> u64::from(h2)) | (top >> u64::from(h3));
    let n = ((a as u32) & !(mlo | tlo)).count_ones() + (((a >> 32) as u32) & !(mhi | thi)).count_ones();
    let mut ok = true;
    if n != 4u32 {
        ok = false;
    }
    ok
}

// Mathematical statement, natural (non-reversed) order: digit d in seen_nat bit d.
fn spec(seen_nat: u64, d: [u32; 4]) -> bool {
    let distinct = d[0] != d[1] && d[0] != d[2] && d[0] != d[3] && d[1] != d[2] && d[1] != d[3] && d[2] != d[3];
    distinct && d.iter().all(|&x| seen_nat >> x & 1 == 0)
}

fn xs(x: &mut u64) -> u64 {
    *x ^= *x << 13;
    *x ^= *x >> 7;
    *x ^= *x << 17;
    *x
}

fn main() {
    let mut x = 0x9E37_79B9_7F4A_7C15u64;
    let (mut n, mut fails, mut pass, mut spec_fails) = (0u64, 0u64, 0u64, 0u64);
    for g2 in 0..64u32 {
        for g3 in 0..64u32 {
            for h2 in 0..64u32 {
                for h3 in 0..64u32 {
                    let d = [g2, g3, h2, h3];
                    let mut dmask = 0u64; // reversed positions
                    for &v in &d {
                        dmask |= 1u64 << (63 - v);
                    }
                    let pos: Vec<u32> = (0..64).filter(|&b| dmask >> b & 1 == 1).collect();
                    for sub in 0..(1u32 << pos.len()) {
                        let mut on = 0u64;
                        for (i, &p) in pos.iter().enumerate() {
                            if sub >> i & 1 == 1 {
                                on |= 1u64 << p;
                            }
                        }
                        for bg in 0..3 {
                            let other = match bg {
                                0 => 0,
                                1 => !0u64,
                                _ => xs(&mut x),
                            } & !dmask;
                            let seen = on | other;
                            // split seen across m and t words at random (OR must equal seen)
                            let r = xs(&mut x);
                            let m = seen & r;
                            let t = (seen & !r) | (seen & xs(&mut x));
                            let (mlo, mhi, tlo, thi) = (m as u32, (m >> 32) as u32, t as u32, (t >> 32) as u32);
                            let o = old(mlo, mhi, tlo, thi, g2, g3, h2, h3);
                            let w = new(mlo, mhi, tlo, thi, g2, g3, h2, h3);
                            let s = spec(seen.reverse_bits(), d);
                            fails += u64::from(o != w);
                            spec_fails += u64::from(o != s);
                            pass += u64::from(o);
                            n += 1;
                        }
                    }
                }
            }
        }
    }
    println!("cases {n}  old!=new {fails}  old!=spec {spec_fails}  passes {pass}");
    // Digit bound: h = mul_hi(f, b), g = mul_hi(f*b mod 2^32, b) are < b for every f, b <= 64 (spot over all b and
    // the f extremes plus random f).
    let mut bad = 0u64;
    for b in 2..=64u64 {
        for f in [0u64, 1, 0xFFFF_FFFF, 0xFFFF_FFFE, 0x8000_0000].into_iter().chain((0..1_000_000).map(|_| xs(&mut x) & 0xFFFF_FFFF)) {
            let h = (f * b) >> 32;
            let g = (((f * b) & 0xFFFF_FFFF) * b) >> 32;
            bad += u64::from(h >= b || g >= b);
        }
    }
    println!("digit-bound violations {bad}");
}
