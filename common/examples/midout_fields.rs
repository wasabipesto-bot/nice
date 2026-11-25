//! **midout_fields**: a work list of middle-out fields for the development
//! server (`scripts/midout_coordinator.py`), cut by the library's own
//! coordinate (`midout::coord`). Prints a JSON list on stdout, one object
//! per field: `{base, coordinate, range_start, range_end, range_size}`
//! (`coordinate` the id `midout:K0,K1,Q0`; `range_*` in v; `range_size` the
//! n the field holds, `Coord::n_count`). Needs no feature and no device.
//!
//! ```text
//! cargo run --release -p nice_common --example midout_fields -- --base 64 --spread 16 > work.json
//! python3 scripts/midout_coordinator.py --worklist work.json --state STATE --port 8470
//! nice_client midout --api-base http://127.0.0.1:8470 --repeat
//! ```

#[path = "support/args.rs"]
mod args;

use anyhow::{Result, bail, ensure};
use args::Opt;
use nice_common::midout::Coord;

const ABOUT: &str =
    "Print a work list of middle-out fields (JSON) for scripts/midout_coordinator.py.";

const OPTS: &[Opt] = &[
    Opt {
        name: "--base",
        value: Some("B"),
        help: "the base (default 64)",
    },
    Opt {
        name: "--t",
        value: Some("T0,T1,.."),
        help: "the fields' first quanta: the values of their fixed digits (5-7 at base 64 by default)",
    },
    Opt {
        name: "--spread",
        value: Some("N"),
        help: "N fields spread evenly over the base (instead of --t)",
    },
    Opt {
        name: "--quanta",
        value: Some("Q"),
        help: "quanta per field (default 1)",
    },
    Opt {
        name: "--digits",
        value: Some("K0,K1,Q0"),
        help: "another coordinate than the base's (any Coord::with_digits; tests of a client's refusal, small bases)",
    },
];

fn main() -> Result<()> {
    let a = args::parse("midout_fields", ABOUT, OPTS)?;
    let b: u32 = a.get("--base", 64)?;
    let quanta: u128 = a.get("--quanta", 1)?;
    ensure!(quanta >= 1, "--quanta must be at least 1");
    let coord = match args::digits(&a)? {
        Some((k0, k1, q0)) => Coord::with_digits(b, k0, k1, q0)?,
        None => Coord::for_base(b)?,
    };
    let id = nice_common::midout::wire::coordinate_id(coord.k0(), coord.k1(), coord.q0());
    let q = coord.quantum();
    let total = (coord.v_end() - coord.start()) / q;
    let ts: Vec<u128> = match (a.list::<u128>("--t")?, a.opt::<u128>("--spread")?) {
        (Some(t), None) => t,
        (None, Some(n)) => {
            ensure!(n >= 1 && n <= total, "--spread {n}: 1 to {total} fields");
            (0..n).map(|i| (2 * i + 1) * total / (2 * n)).collect()
        }
        (Some(_), Some(_)) => bail!("--t and --spread: give one"),
        (None, None) => bail!("give --t T0,T1,.. or --spread N (see --help)"),
    };
    let mut out = Vec::new();
    for t in ts {
        ensure!(
            t.checked_add(quanta).is_some_and(|e| e <= total),
            "t {t} with {quanta} quanta runs past the base's {total} quanta"
        );
        let (s, size) = (coord.start() + t * q, quanta * q);
        let n = coord.n_count(s, size)?;
        out.push(format!(
            "{{\"base\":{b},\"coordinate\":\"{id}\",\"range_start\":{s},\"range_end\":{},\"range_size\":{n}}}",
            s + size
        ));
    }
    println!("[\n{}\n]", out.join(",\n"));
    Ok(())
}
