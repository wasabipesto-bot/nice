//! One entry point for a client route: a field of the middle-out coordinate
//! of base `b`, searched on the path for that base (base 64: [`super::gpu`],
//! 64-bit masks; base 65: [`super::gpu_wide`], two-word masks), with
//! every account checked and, where asked, the sampled CPU check. Returns the
//! outcome and the route's telemetry (the path, the join's shape, the
//! counters, the sampled slice, the timings). Nothing here knows the wire.

use super::coord::Coord;
use super::cpu::{FieldOutcome, Shape};
use super::gpu::{Caps, FieldTiming, GpuJoin, GpuOptions, search_field};
use super::gpu_wide::{WideCaps, WideJoin, WideOptions, search_field_wide};
use anyhow::{Result, bail, ensure};
use cubecl::prelude::*;
use serde_json::{Value, json};

/// The runtime types a route names (the client does not depend on `cubecl`).
pub use cubecl::prelude::{ComputeClient as Client, Runtime as DeviceRuntime};

/// Slices per synchronisation (the benches' default).
const GROUP: usize = 16;
/// Classes per batch on the base-64 path (the bench's default: all).
const CLASSES_B64: u32 = 63;

/// The join of one base on one device.
pub enum FieldJoin<R: Runtime> {
    /// Base 64.
    Narrow(Box<GpuJoin<R>>),
    /// Base 65 (the wide path, two-word masks).
    Wide(Box<WideJoin<R>>, u32),
}

impl<R: Runtime> FieldJoin<R> {
    /// The join for base `b` (64: the 64-bit path; 65: the wide path). Bases 66–70 are refused: the wide path
    /// computes them, but only base 65 has been run end to end through it (and base 68 does not fit a
    /// 10 GB card).
    ///
    /// # Errors
    /// A base other than 64 or 65, or a device error.
    pub fn new(client: ComputeClient<R>, b: u32) -> Result<Self> {
        let coord = Coord::for_base(b)?;
        match b {
            64 => Ok(Self::Narrow(Box::new(GpuJoin::new(
                client,
                Caps::b64(CLASSES_B64),
            )?))),
            65 => Ok(Self::Wide(
                Box::new(WideJoin::new(
                    client,
                    WideCaps::for_base(b),
                    &coord,
                    Shape::for_coord(&coord),
                )?),
                b,
            )),
            _ => bail!("middle-out: no device path for base {b}"),
        }
    }

    /// The base this join searches.
    #[must_use]
    pub fn base(&self) -> u32 {
        match self {
            Self::Narrow(_) => 64,
            Self::Wide(_, b) => *b,
        }
    }

    /// Whether the sampled CPU check is on by default for this base: on at
    /// both. Its CPU slice runs on up to four threads beside the device's
    /// (`gpu::sample_threads`); on a box with a 5-CPU quota and an RTX 3080
    /// it took 33 s at base 65 against a 56 s field, and 11 s at base 64
    /// against a 30 s field, so the host does not wait for it.
    #[must_use]
    pub fn cpu_check_default(&self) -> bool {
        match self {
            Self::Narrow(_) | Self::Wide(..) => true,
        }
    }

    /// Search the field `[v_start, v_start + v_size)` of `coord` (which must
    /// be one of this join's base's known coordinates, `Coord::is_known`):
    /// every account checked, the sampled CPU check if `cpu_check`, its CPU
    /// slice on `cpu_threads` threads (0: `gpu::sample_threads`' default).
    ///
    /// # Errors
    /// A field that is not whole quanta of the base, a failed account, or a
    /// sampled check that differs.
    pub fn search(
        &self,
        coord: &Coord,
        v_start: u128,
        v_size: u128,
        cpu_check: bool,
        cpu_threads: usize,
    ) -> Result<(FieldOutcome, Value)> {
        // the device paths search the base's known coordinates (`Coord::is_known`) only
        ensure!(
            coord.b() == self.base() && coord.is_known(),
            "middle-out: the base-{} join cannot search a field of coordinate (base {}, digits {}, {}, {})",
            self.base(),
            coord.b(),
            coord.k0(),
            coord.k1(),
            coord.q0()
        );
        let coord = coord.clone();
        let shape = Shape::for_coord(&coord);
        let (o, counts, tm, path, w) = match self {
            Self::Narrow(gj) => {
                let opt = GpuOptions::new(GROUP, cpu_check).with_cpu_threads(cpu_threads);
                let (o, dc, tm) = search_field(gj, &coord, v_start, v_size, opt)?;
                let c = json!({"tops": dc.tops, "children": dc.children, "chunks": dc.chunks,
                               "flat": dc.flat, "kept": dc.kept, "slices": dc.slices});
                (o, c, tm, "narrow", gj.w)
            }
            Self::Wide(gj, _) => {
                let opt = WideOptions {
                    group: GROUP,
                    cpu_check,
                    cpu_threads,
                };
                let (o, dc, tm) = search_field_wide(gj, &coord, v_start, v_size, opt)?;
                let c = json!({"tops": dc.tops, "children": dc.children, "chunks": dc.chunks,
                               "flat": dc.flat, "kept": dc.kept, "slices": dc.slices});
                (o, c, tm, "wide", gj.w)
            }
        };
        let tel = json!({
            "path": path,
            "shape": [shape.f0, shape.k],
            "plane_width": w,
            "group": GROUP,
            "survivors": o.survivors,
            "checked": o.checked,
            "slices": o.slices,
            "device_counts": counts,
            "sampled_check": sampled(&tm, cpu_check),
            "timing": {
                "wall": tm.wall, "field": tm.field, "sync": tm.sync, "host_wait": tm.host_wait,
                "cpu_check": tm.cpu_check, "cpu_wait": tm.cpu_wait, "sample_dev": tm.sample_dev,
            },
        });
        Ok((o, tel))
    }

    /// (test switch, feature `midout-fault`) Inject one of the library's
    /// fault bits: `accounts` drops the main kernel (the accounts fail),
    /// `sample` makes the prefilter drop ~1/1024 of the survivors (the
    /// accounts pass; only the sampled CPU check sees it).
    ///
    /// # Errors
    /// An unknown name.
    #[cfg(feature = "midout-fault")]
    pub fn set_test_fault(&mut self, name: &str) -> Result<()> {
        let (narrow, wide) = match name {
            "accounts" => (super::gpu::F_SKIP_MAIN, super::gpu_wide::F_SKIP_MAIN),
            "sample" => (super::gpu::F_PF_DROP, super::gpu_wide::F_PF_DROP),
            _ => bail!("middle-out: unknown device fault '{name}'"),
        };
        match self {
            Self::Narrow(gj) => gj.set_fault(narrow),
            Self::Wide(gj, _) => gj.set_fault(wide),
        }
        Ok(())
    }
}

fn sampled(tm: &FieldTiming, on: bool) -> Value {
    match (on, tm.sampled) {
        (false, _) => Value::Null,
        // the library returns an error for a slice that differs, so a slice here was equal
        (true, Some(p)) => json!({"slice": p, "equal": true, "cpu_secs": tm.cpu_check}),
        (true, None) => json!({"slice": null, "equal": null}),
    }
}
