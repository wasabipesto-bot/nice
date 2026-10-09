//! Experiment harness (branch `exp/join-sizing` only; never shipped).
//!
//! `jbench gpu MODE BASE WIDTH S1 [S2 ...]` times whole nice-only fields
//! `[S, S+WIDTH)` through the GPU routes, after one untimed warm-up field
//! just below S1:
//!   - `hybrid`: the client's NVIDIA `auto` (hand-CUDA stride + CubeCL join);
//!   - `cubecl`: everything through the CubeCL CUDA context;
//!   - `cuda`: everything through hand-CUDA (no join).
//!
//! `PIPE=1` keeps `fields_in_flight()` fields open, as the client does.
//!
//! `jbench cpu BASE WIDTH THREADS SAMPLE S1 [S2 ...]` runs SAMPLE partitions,
//! spread evenly over each field's first slice, through the CPU join on
//! THREADS threads, and reports per-partition core time.
//!
//! One JSON line per field, then a summary line with the `NICE_EXP_*`
//! overrides in effect.
use anyhow::{Result, bail};
use nice_common::FieldSize;
use nice_common::client_process_cuda::{CudaContext, CudaWithJoin};
use nice_common::cpu_join::{CpuJoin, PartitionResult, Scratch, slices_for};
use nice_common::cubecl_backend::CubeclContext;
use nice_common::gpu_niceonly::fields_in_flight;
use nice_common::gpu_route::{FieldTicket, NiceonlyGpu, NiceonlyStarted, Route, begin_niceonly};
use serde_json::json;
use std::collections::VecDeque;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::time::Instant;

enum Gpu {
    Cuda(CudaContext),
    Cubecl(CubeclContext),
    Pair(CudaWithJoin),
}

impl Gpu {
    fn as_dyn(&self) -> &dyn NiceonlyGpu {
        match self {
            Gpu::Cuda(c) => c,
            Gpu::Cubecl(c) => c,
            Gpu::Pair(p) => p,
        }
    }
    fn device_name(&self) -> Option<String> {
        match self {
            Gpu::Cuda(_) => None,
            Gpu::Cubecl(c) => Some(c.device_name()),
            Gpu::Pair(p) => Some(p.join.device_name()),
        }
    }
}

fn exp_env() -> serde_json::Value {
    let mut m = serde_json::Map::new();
    for (k, v) in std::env::vars() {
        if k.starts_with("NICE_EXP_") || k == "PIPE" {
            m.insert(k, json!(v));
        }
    }
    serde_json::Value::Object(m)
}

fn fields(width: u128, starts: &[String]) -> Result<Vec<FieldSize>> {
    starts
        .iter()
        .map(|s| {
            let s: u128 = s.parse()?;
            Ok(FieldSize::new(s, s + width))
        })
        .collect()
}

fn gpu(a: &[String]) -> Result<()> {
    let mode = a[2].clone();
    let b: u32 = a[3].parse()?;
    let width: u128 = a[4].parse()?;
    let fields = fields(width, &a[5..])?;
    let pipe = std::env::var("PIPE").is_ok_and(|v| v == "1");
    let g = match mode.as_str() {
        "hybrid" => Gpu::Pair(CudaWithJoin {
            cuda: CudaContext::new(0)?,
            join: CubeclContext::new_cuda(0)?,
        }),
        "cubecl" => Gpu::Cubecl(CubeclContext::new_cuda(0)?),
        "cuda" => Gpu::Cuda(CudaContext::new(0)?),
        _ => bail!("mode is hybrid, cubecl or cuda"),
    };
    let mut tickets: VecDeque<FieldTicket> = VecDeque::new();
    let begin = |tickets: &mut VecDeque<FieldTicket>, f: &FieldSize| -> Result<bool> {
        let NiceonlyStarted::Queued(t) = begin_niceonly(g.as_dyn(), f, b)? else {
            bail!("field handled off-device")
        };
        let join = t.route() == Route::Join;
        tickets.push_back(t);
        Ok(join)
    };
    let tw = Instant::now();
    let s0 = fields[0].start();
    begin(&mut tickets, &FieldSize::new(s0 - width, s0))?;
    let t = tickets.pop_front().unwrap();
    g.as_dyn().finish(t)?;
    let warm = tw.elapsed().as_secs_f64();
    let lookahead = if pipe { fields_in_flight().saturating_sub(1) } else { 0 };
    let t0 = Instant::now();
    let mut queued: VecDeque<(FieldSize, bool, f64)> = VecDeque::new();
    let mut last = 0.0;
    let mut done = |tickets: &mut VecDeque<FieldTicket>, q: (FieldSize, bool, f64), last: &mut f64| -> Result<()> {
        let tk = tickets.pop_front().unwrap();
        let (res, st) = g.as_dyn().finish(tk)?;
        let now = t0.elapsed().as_secs_f64();
        println!(
            "{}",
            json!({"kind": "field", "mode": mode, "base": b, "start": q.0.start().to_string(),
                "width": width.to_string(), "join_route": q.1, "since_begin": now - q.2,
                "since_prev": now - *last, "found": res.nice_numbers.len(),
                "stats": st.telemetry_json()})
        );
        *last = now;
        Ok(())
    };
    for f in &fields {
        let r = begin(&mut tickets, f)?;
        queued.push_back((*f, r, t0.elapsed().as_secs_f64()));
        while queued.len() > lookahead {
            let q = queued.pop_front().unwrap();
            done(&mut tickets, q, &mut last)?;
        }
    }
    while let Some(q) = queued.pop_front() {
        done(&mut tickets, q, &mut last)?;
    }
    let wall = t0.elapsed().as_secs_f64();
    println!(
        "{}",
        json!({"kind": "summary", "mode": mode, "base": b, "pipe": pipe, "fields": fields.len(),
            "wall": wall, "per_field": wall / fields.len() as f64, "warm_sec": warm,
            "device": g.device_name(), "exp": exp_env()})
    );
    Ok(())
}

fn cpu(a: &[String]) -> Result<()> {
    let b: u32 = a[2].parse()?;
    let width: u128 = a[3].parse()?;
    let threads: usize = a[4].parse()?;
    let sample: usize = a[5].parse()?;
    for f in fields(width, &a[6..])? {
        let Some((jp, slices)) = slices_for(b, &f) else {
            println!("{}", json!({"kind": "field", "base": b, "start": f.start().to_string(), "join": false}));
            continue;
        };
        let ts = Instant::now();
        let join = CpuJoin::new(b, &slices[0], jp)?;
        let setup = ts.elapsed().as_secs_f64();
        let parts = join.partitions() as usize;
        let k = sample.min(parts).max(1);
        let picks: Vec<u32> = (0..k).map(|i| (i * parts / k) as u32).collect();
        let next = AtomicUsize::new(0);
        let tr = Instant::now();
        let out = std::thread::scope(|s| {
            let ws: Vec<_> = (0..threads.max(1))
                .map(|_| {
                    s.spawn(|| {
                        let mut sc = Scratch::default();
                        let mut o = PartitionResult::default();
                        loop {
                            let i = next.fetch_add(1, Ordering::Relaxed);
                            if i >= picks.len() {
                                return o;
                            }
                            o.add(join.run_partition(picks[i], &mut sc));
                        }
                    })
                })
                .collect();
            let mut o = PartitionResult::default();
            for w in ws {
                o.add(w.join().expect("worker panicked"));
            }
            o
        });
        let run = tr.elapsed().as_secs_f64();
        let per_part = run * threads.max(1) as f64 / k as f64;
        println!(
            "{}",
            json!({"kind": "field", "base": b, "start": f.start().to_string(), "width": width.to_string(),
                "join": true, "t": jp.t, "k": jp.k, "p": jp.p, "slices": slices.len(),
                "partitions": parts, "sampled": k, "threads": threads, "setup_secs": setup,
                "run_secs": run, "core_secs_per_partition": per_part,
                "field_core_secs_est": slices.len() as f64 * (setup + per_part * parts as f64),
                "survivors": out.survivors, "checked": out.checked, "hits": out.hits.len(),
                "exp": exp_env()})
        );
    }
    Ok(())
}

fn main() -> Result<()> {
    let a: Vec<String> = std::env::args().collect();
    match a.get(1).map(String::as_str) {
        Some("gpu") => gpu(&a),
        Some("cpu") => cpu(&a),
        _ => bail!("usage: jbench gpu MODE BASE WIDTH S... | jbench cpu BASE WIDTH THREADS SAMPLE S..."),
    }
}
