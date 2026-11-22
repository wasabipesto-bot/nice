//! Emit the tables that the Lean model of the middle-out join
//! (`lean-midout/`) is compared against, from the real CPU reference
//! (`midout::coord`, `midout::cpu`, `midout::arith`). Deterministic (fixed
//! xorshift seeds); numbers above 2^53 are written as decimal strings.
//!
//! ```text
//! cargo run --release -p nice_common --example midout_lean_fixtures -- lean-midout/fixtures
//! (cd lean-midout/fixtures && sha256sum *.json > SHA256SUMS)
//! ```
//!
//! Files:
//! - `whole.json`: every slice of every field of the small bases the Rust
//!   tests run (`check_whole_base`): the slice's `pip`, its counters and
//!   every survivor `(d, n, pass)` in the order the reference reports them;
//!   and `search_field` on the whole base and on the first field.
//! - `bases.json`: for every base 3-128, its roots and its range (the
//!   closed form, exact).
//! - `b64.json`: base-64 (and base-65) pieces: `v` and `n_of_v` of sampled
//!   values, field digits and slice lists of sampled fields, top
//!   certificates of sampled intervals, the tops of sampled units, parent
//!   lists of small shapes, sampled parents and child masks of real
//!   slices, prefilter verdicts.

use nice_common::base_range::get_base_range_natural;
use nice_common::midout::arith::roots;
use nice_common::midout::coord::Coord;
use nice_common::midout::cpu::{
    Base, Counts, Parent, Shape, child_mask, parents, prefilter, search_field, slice_join,
    top_cert_split, unit_tops,
};
use serde_json::{Value, json};
use std::fs;
use std::path::Path;

fn s(x: u128) -> Value {
    Value::String(x.to_string())
}

fn digits_of(m: u64) -> Value {
    json!((0..64).filter(|i| m >> i & 1 == 1).collect::<Vec<u32>>())
}

fn counts(c: &Counts) -> Value {
    json!([
        c.tops_tested,
        c.tops,
        c.parents,
        c.children,
        c.chunks,
        c.pairs,
        c.flat,
        c.kept,
        c.words,
        c.survivors,
        c.checked,
        c.clipped
    ])
}

struct Rng(u64);
impl Rng {
    fn next(&mut self) -> u64 {
        self.0 ^= self.0 << 13;
        self.0 ^= self.0 >> 7;
        self.0 ^= self.0 << 17;
        self.0
    }
    fn u128(&mut self) -> u128 {
        u128::from(self.next()) << 64 | u128::from(self.next())
    }
    fn below(&mut self, m: u128) -> u128 {
        self.u128() % m
    }
}

fn parent_json(p: &Parent<u64>) -> Value {
    json!([s(p.r), digits_of(p.mask), p.c2, p.c3, p.a2, p.a3, p.cls])
}

/// The small bases of `cpu`'s `check_whole_base` tests.
const WHOLE: &[(u32, (u32, u32, u32), &[(u32, u32)])] = &[
    (10, (0, 1, 0), &[(0, 2)]),
    (12, (1, 2, 1), &[(1, 3)]),
    (13, (1, 2, 1), &[(1, 3), (0, 3)]),
    (14, (1, 2, 1), &[(1, 3)]),
    (17, (1, 2, 1), &[(1, 3), (1, 4)]),
    (18, (1, 2, 1), &[(1, 3), (1, 4)]),
    (19, (1, 2, 1), &[(1, 3), (0, 4)]),
    (20, (2, 3, 2), &[(2, 4), (1, 4)]),
    (22, (2, 3, 2), &[(2, 4)]),
    (24, (1, 3, 2), &[(1, 4), (2, 4)]),
    (25, (2, 4, 3), &[(2, 5)]),
];

fn outcome(o: &nice_common::midout::cpu::FieldOutcome) -> Value {
    json!({
        "nice": o.nice.iter().map(|&n| s(n)).collect::<Vec<_>>(),
        "survivors": o.survivors,
        "checked": o.checked,
        "slices": o.slices,
    })
}

fn whole() -> Value {
    let mut out = Vec::new();
    for &(b, (k0, k1, q0), shapes) in WHOLE {
        let coord = Coord::with_digits(b, k0, k1, q0).unwrap();
        let base = Base::new(&coord);
        let q = coord.quantum();
        let nq = (coord.v_end() - coord.start()) / q;
        let mut shs = Vec::new();
        for &(f0, k) in shapes {
            let sh = Shape { f0, k };
            let mut slices = Vec::new();
            for t in 0..nq {
                for pip in sh.slices_of(&coord, t) {
                    let mut surv = Vec::new();
                    let c = slice_join::<u64>(&base, sh, pip, |d, n, pass| {
                        surv.push(json!([d, s(n), u8::from(pass)]));
                    });
                    slices.push(json!({"t": s(t), "pip": s(pip), "counts": counts(&c), "surv": surv}));
                }
            }
            let (all, _) =
                search_field::<u64>(&coord, sh, coord.start(), coord.v_end() - coord.start(), 1)
                    .unwrap();
            let (first, _) = search_field::<u64>(&coord, sh, coord.start(), q, 1).unwrap();
            shs.push(json!({
                "f0": f0, "k": k, "slices": slices,
                "field_all": outcome(&all), "field_first": outcome(&first),
            }));
        }
        out.push(json!({
            "base": b, "k0": k0, "k1": k1, "q0": q0,
            "start": s(coord.start()), "end": s(coord.end()),
            "h0": s(coord.h0()), "hn": s(coord.hn()),
            "quantum": s(q), "v_end": s(coord.v_end()),
            "shapes": shs,
        }));
    }
    json!(out)
}

fn bases() -> Value {
    let mut out = Vec::new();
    for b in 3u32..=128 {
        // the closed form as exact naturals (empty at bases 3 and 4)
        let range = get_base_range_natural(b)
            .map_or(Value::Null, |(lo, hi)| json!([lo.to_string(), hi.to_string()]));
        out.push(json!({"base": b, "roots": roots(b), "range": range}));
    }
    json!(out)
}

fn b64() -> Value {
    let mut rng = Rng(0x2545_F491_4F6C_DD1D);
    // coordinates: values, v of sampled n, n of sampled v
    let mut coords = Vec::new();
    for &(b, (k0, k1, q0)) in &[(64u32, (4u32, 8u32, 5u32)), (64, (4, 9, 6)), (65, (4, 8, 5))] {
        let c = Coord::with_digits(b, k0, k1, q0).unwrap();
        let mut vs = Vec::new();
        for i in 0..500 {
            let n = match i {
                0 => c.start(),
                1 => c.end() - 1,
                _ => c.start() + rng.below(c.end() - c.start()),
            };
            vs.push(json!([s(n), s(c.v_of_n(n))]));
        }
        let mut ns = Vec::new();
        for i in 0..500 {
            let v = match i {
                0 => c.start(),
                1 => c.v_end() - 1,
                _ => c.start() + rng.below(c.v_end() - c.start()),
            };
            ns.push(json!([s(v), c.n_of_v(v).map_or(Value::Null, s)]));
        }
        // fields: sampled whole-quanta fields, and refused ones
        let q = c.quantum();
        let nq = (c.v_end() - c.start()) / q;
        let mut fields = Vec::new();
        for (t, len) in [(0u128, 1u128), (1, 1), (nq - 1, 1), (12_345 % nq, 7), (0, nq)] {
            let (vs0, vz) = (c.start() + t * q, len * q);
            let r = c.field_digits(vs0, vz).unwrap();
            fields.push(json!([s(vs0), s(vz), [s(r.start), s(r.end)]]));
        }
        for (vs0, vz) in [
            (c.start(), 0),
            (c.start() + 1, q),
            (c.start(), q + 1),
            (c.start() + (nq - 1) * q, 2 * q),
        ] {
            assert!(c.field_digits(vs0, vz).is_err());
            fields.push(json!([s(vs0), s(vz), Value::Null]));
        }
        let sh = Shape::for_coord(&c);
        let mut slice_lists = Vec::new();
        for t in [1u128, nq - 1] {
            let l: Vec<Value> = sh.slices_of(&c, t).map(s).collect();
            slice_lists.push(json!([s(t), l]));
        }
        coords.push(json!({
            "base": b, "k0": k0, "k1": k1, "q0": q0,
            "start": s(c.start()), "end": s(c.end()), "h0": s(c.h0()), "hn": s(c.hn()),
            "quantum": s(q), "v_end": s(c.v_end()),
            "shape": [sh.f0, sh.k],
            "v_of_n": vs, "n_of_v": ns, "fields": fields, "slices": slice_lists,
        }));
    }

    let c = Coord::for_base(64).unwrap();
    let base = Base::new(&c);
    let sh = Shape::for_coord(&c);
    let span = c.end() - c.start();
    // top certificates of sampled intervals [a, a + w]
    let mut certs = Vec::new();
    for i in 0..3000u32 {
        let a = c.start() + rng.below(span);
        let w = match i % 6 {
            0 => 0,
            1 => rng.below(64),
            2 => rng.below(1 << 24),
            3 => (1u128 << 24) - 1,
            4 => rng.below(1 << 40),
            _ => rng.below(1 << 60),
        };
        let cc = (a + w).min(c.end() - 1);
        let kpos = [6u32, 8, 10, 12, 14][(i % 5) as usize];
        let kmid = kpos + [0u32, 2, 5][(i % 3) as usize];
        let got = top_cert_split::<u64>(&base, a, cc, kpos, kmid)
            .map_or(Value::Null, |(m, h)| json!([digits_of(m), digits_of(h)]));
        certs.push(json!([s(a), s(cc), kpos, kmid, got]));
    }
    // the tops of sampled units of the (4, 10) shape
    let mut units = Vec::new();
    for _ in 0..1 {
        let uval = rng.below(1 << 36);
        let mut tested = 0u64;
        let tops = unit_tops::<u64>(&base, sh, uval, &mut tested);
        let tl: Vec<Value> = tops
            .iter()
            .map(|t| json!([s(t.h), digits_of(t.mask), digits_of(t.mhi), s(t.lo), s(t.hi)]))
            .collect();
        units.push(json!({"f0": sh.f0, "k": sh.k, "u": s(uval), "tested": tested, "tops": tl}));
    }
    // whole parent lists of small shapes at base 64, with sampled child masks
    let mut plists = Vec::new();
    for &(f0, k, pip) in &[(2u32, 5u32, 0u128), (2, 5, 1234), (2, 5, 4095), (1, 4, 77)] {
        let shp = Shape { f0, k };
        let ps = parents::<u64>(&base, shp, pip);
        let mut kids = Vec::new();
        for _ in 0..400 {
            if ps.is_empty() {
                break;
            }
            let i = usize::try_from(rng.below(ps.len() as u128)).unwrap();
            let d = u32::try_from(rng.below(64)).unwrap();
            kids.push(json!([i, d, digits_of(child_mask(64, &ps[i], d))]));
        }
        plists.push(json!({
            "f0": f0, "k": k, "pip": s(pip),
            "parents": ps.iter().map(parent_json).collect::<Vec<_>>(),
            "children": kids,
        }));
    }
    // sampled parents of real (4, 10) slices: members with their records,
    // and random residues of the slice with their membership
    let mut psamples = Vec::new();
    for _ in 0..2 {
        let pip = rng.below(1 << 30);
        let ps = parents::<u64>(&base, sh, pip);
        let mut mem = Vec::new();
        for _ in 0..300 {
            let i = usize::try_from(rng.below(ps.len() as u128)).unwrap();
            let d = u32::try_from(rng.below(64)).unwrap();
            mem.push(json!([parent_json(&ps[i]), d, digits_of(child_mask(64, &ps[i], d))]));
        }
        let mut probe = Vec::new();
        for _ in 0..300 {
            let r = pip * (1 << 24) + rng.below(1 << 24);
            let is = ps.binary_search_by_key(&r, |p| p.r).is_ok();
            probe.push(json!([s(r), is]));
        }
        psamples.push(json!({
            "f0": sh.f0, "k": sh.k, "pip": s(pip), "count": ps.len(),
            "first": parent_json(&ps[0]), "last": parent_json(ps.last().unwrap()),
            "members": mem, "probes": probe,
        }));
    }
    // prefilter verdicts: random n with random mhi (as the Rust test), and
    // n built from a certified bottom with their top's mhi
    let mut pf = Vec::new();
    for _ in 0..2000 {
        let n = c.start() + rng.below(span);
        let mhi = rng.next() & rng.next() & rng.next();
        pf.push(json!([s(n), digits_of(mhi), prefilter::<u64>(&base, sh.k, n, mhi)]));
    }
    let pip = rng.below(1 << 30);
    let ps = parents::<u64>(&base, sh, pip);
    let mut built = 0;
    let mut tries = 0;
    while built < 2000 && tries < 200_000 {
        tries += 1;
        let p = &ps[usize::try_from(rng.below(ps.len() as u128)).unwrap()];
        let d = u32::try_from(rng.below(64)).unwrap();
        if child_mask(64, p, d) == 0 {
            continue;
        }
        let n = (c.start() + rng.below(span)) / (1 << 60) * (1 << 60)
            + u128::from(d) * (1 << 54)
            + p.r;
        let w = 1u128 << 24;
        let (a, e) = (n / w * w, n / w * w + w - 1);
        let Some((_, mhi)) = top_cert_split::<u64>(&base, a, e, sh.k, sh.k + 2) else {
            continue;
        };
        built += 1;
        pf.push(json!([s(n), digits_of(mhi), prefilter::<u64>(&base, sh.k, n, mhi)]));
    }
    json!({"coords": coords, "certs": certs, "units": units, "parent_lists": plists,
           "parent_samples": psamples, "prefilter": pf})
}

fn main() {
    let dir = std::env::args().nth(1).unwrap_or_else(|| "lean-midout/fixtures".into());
    let dir = Path::new(&dir);
    fs::create_dir_all(dir).unwrap();
    for (name, v) in [("bases.json", bases()), ("b64.json", b64()), ("whole.json", whole())] {
        let text = serde_json::to_string(&v).unwrap();
        fs::write(dir.join(name), text + "\n").unwrap();
        eprintln!("wrote {name}");
    }
}
