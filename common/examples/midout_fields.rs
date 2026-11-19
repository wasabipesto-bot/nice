//! A work list of middle-out fields for the local coordinator
//! (`scripts/midout_coordinator.py`), cut by the library's own coordinate:
//! one JSON object per field, `{base, range_start, range_end, range_size}`
//! (`range_*` in v; `range_size` = the n the field holds).
//!
//! usage: midout_fields --base B (--t T0,T1,.. | --spread N) [--quanta Q]
//!   --t: the fields' first quantum (the value of digits 6-8 at base 64);
//!   --spread N: N fields spread evenly over the base; --quanta: quanta per field (1)
use anyhow::{Result, bail};
use nice_common::midout::Coord;

fn main() -> Result<()> {
    let args: Vec<String> = std::env::args().collect();
    let opt = |name: &str| {
        args.iter()
            .position(|a| a == name)
            .and_then(|i| args.get(i + 1))
            .cloned()
    };
    let b: u32 = opt("--base").map_or(Ok(64), |s| s.parse())?;
    let quanta: u128 = opt("--quanta").map_or(Ok(1), |s| s.parse())?;
    let coord = Coord::for_base(b)?;
    let q = coord.quantum();
    let total = (coord.v_end() - coord.start) / q;
    let ts: Vec<u128> = if let Some(t) = opt("--t") {
        t.split(',').map(str::parse).collect::<Result<_, _>>()?
    } else if let Some(n) = opt("--spread") {
        let n: u128 = n.parse()?;
        (0..n).map(|i| (2 * i + 1) * total / (2 * n)).collect()
    } else {
        bail!("--t or --spread");
    };
    let mut out = Vec::new();
    for t in ts {
        let (s, size) = (coord.start + t * q, quanta * q);
        let n = coord.n_count(s, size)?;
        out.push(format!(
            "{{\"base\":{b},\"range_start\":{s},\"range_end\":{},\"range_size\":{n}}}",
            s + size
        ));
    }
    println!("[\n{}\n]", out.join(",\n"));
    Ok(())
}
