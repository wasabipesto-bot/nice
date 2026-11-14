#!/usr/bin/env python3
"""add_harness.py FILE: append a test-only CUDA timing harness for the stride pipeline to cubecl_backend.rs's tests
(used only in the timing binaries of main and of the fix; not part of the PR)."""
import sys
p = sys.argv[1]; s = open(p).read()
h = r'''
    /// Timing harness (not in the PR): `NICE_TEST_FIELDS` fields of `NICE_TEST_STRIDE_FIELD=base:start:size` through
    /// the CUDA runtime's nice-only pipeline (set `NICE_JOIN_ROUTE=stride`), after one untimed warm-up field before
    /// `start`.
    #[test]
    #[cfg(feature = "cubecl-cuda")]
    #[ignore = "requires an NVIDIA device; prints throughput"]
    #[allow(clippy::cast_precision_loss)]
    fn cubecl_cuda_stride_throughput_fixed_fields() {
        use crate::gpu_niceonly::{FIELDS_IN_FLIGHT, msd_floor_in_use};
        use crate::gpu_route::{NiceonlyStarted, begin_niceonly};
        let Ok(n) = std::env::var("NICE_TEST_FIELDS") else {
            eprintln!("skipping: set NICE_TEST_FIELDS");
            return;
        };
        let spec = std::env::var("NICE_TEST_STRIDE_FIELD").expect("NICE_TEST_STRIDE_FIELD=base:start:size");
        let v: Vec<u128> = spec.split(':').map(|x| x.parse().unwrap()).collect();
        let (base, start, size) = (v[0] as u32, v[1], v[2]);
        let ctx = CubeclContext::new_cuda(0).expect("CubeCL CUDA init");
        let n: usize = n.parse().expect("NICE_TEST_FIELDS must be a count");
        let fields: Vec<FieldSize> = (0..n as u128)
            .map(|i| FieldSize::new(start + i * size, start + (i + 1) * size))
            .collect();
        let warm = FieldSize::new(start - size / 10, start);
        if let NiceonlyStarted::Queued(ticket) = begin_niceonly(&ctx, &warm, base).unwrap() {
            ctx.finish(ticket).unwrap();
        }
        let lookahead = FIELDS_IN_FLIGHT.saturating_sub(1);
        let t = std::time::Instant::now();
        let mut queued = std::collections::VecDeque::new();
        let mut found = Vec::new();
        for f in &fields {
            match begin_niceonly(&ctx, f, base).unwrap() {
                NiceonlyStarted::Queued(ticket) => queued.push_back(ticket),
                _ => panic!("field did not take the stride pipeline"),
            }
            while queued.len() > lookahead {
                let ticket = queued.pop_front().unwrap();
                found.extend(ctx.finish(ticket).unwrap().0.nice_numbers.iter().map(|x| x.number));
            }
        }
        for ticket in queued {
            found.extend(ctx.finish(ticket).unwrap().0.nice_numbers.iter().map(|x| x.number));
        }
        let secs = t.elapsed().as_secs_f64();
        eprintln!(
            "STRIDE THROUGHPUT base={base} fields={n} size={size} secs={secs:.3} rate={:.4e} n/s floor_now={} found={} {:?}",
            (n as f64) * (size as f64) / secs,
            msd_floor_in_use(),
            found.len(),
            found
        );
    }
}
'''
assert s.endswith("}\n")
s = s[:-2] + h
open(p, 'w').write(s); print("ok")
