#!/usr/bin/env python3
"""N16: host side of the switches (after patch_n16_kernel.py): NICE_EXP_JOIN_WG, NICE_EXP_JOIN_DBL (incl. the check
launched twice), NICE_EXP_BALLOT (top append), NICE_EXP_SLOTS (partitions per launch cap), NICE_EXP_HOSTACC (host-side
launch accounting) and a plane-size probe in NICE_EXP_INFO. python3 patch_n16_host.py TREE"""
import sys
p = sys.argv[1] + '/common/src/cubecl_join.rs'
s = open(p).read()


def rep(a, b, cnt=1):
    global s
    assert s.count(a) == cnt, (s.count(a), a[:80])
    s = s.replace(a, b)


# --- struct fields
rep("""    stg: u32,
    fd_wg: u32,
    limbs: u32,""", """    stg: u32,
    fd_wg: u32,
    /// N16: the join kernel's cube size (`NICE_EXP_JOIN_WG`), the doubled
    /// parts (`NICE_EXP_JOIN_DBL`, see [`DBL_HELP`]).
    wg: u32,
    dbl: u32,
    limbs: u32,""")
rep("""            fd_wg: exp_env("NICE_EXP_FD_WG", JOIN_WG),""", """            fd_wg: exp_env("NICE_EXP_FD_WG", JOIN_WG),
            wg: exp_env("NICE_EXP_JOIN_WG", JOIN_WG),
            dbl: exp_env("NICE_EXP_JOIN_DBL", 0),""")
# ballot override: 0 scans, 1 one-word ballot, 2 two-word ballot
rep("""            ballot: ballot_append(client.properties().hardware.plane_size_max),""",
    """            ballot: match exp_env("NICE_EXP_BALLOT", 9) {
                0 => 0,
                1 => 1,
                2 => 2,
                _ => u32::from(ballot_append(client.properties().hardware.plane_size_max)),
            },""")
rep("""    /// [`ballot_append`] for the device's largest plane.
    ballot: bool,""", """    /// [`ballot_append`] for the device's largest plane (1), else the scans
    /// (0); N16's `NICE_EXP_BALLOT` forces 0, 1 or 2 (a two-word ballot for
    /// planes of up to 64 lanes, see `top_slot`).
    ballot: u32,""")
# top_slot: ballot modes
rep("""        #[comptime] nb: u32,
        #[comptime] ballot: bool,
    ) -> u32 {
        let g0 = plane_broadcast(g, 0u32);
        let one = plane_all(!kept || g == g0);
        let kc = select(kept && one, 1u32, 0u32);
        let b0 = if comptime!(ballot) {
            let bal = plane_ballot(kept && one);
            bal[0usize]
        } else {
            kc
        };
        let n = if comptime!(ballot) {
            b0.count_ones()
        } else {
            plane_sum(kc)
        };
        let pre = if comptime!(ballot) {
            (b0 & ((1u32 << UNIT_POS_PLANE) - 1u32)).count_ones()
        } else {
            plane_exclusive_sum(kc)
        };""", """        #[comptime] nb: u32,
        #[comptime] ballot: u32,
    ) -> u32 {
        let g0 = plane_broadcast(g, 0u32);
        let one = plane_all(!kept || g == g0);
        let kc = select(kept && one, 1u32, 0u32);
        let mut n = 0u32;
        let mut pre = 0u32;
        if comptime!(ballot == 1) {
            let bal = plane_ballot(kept && one);
            let b0 = bal[0usize];
            n = b0.count_ones();
            pre = (b0 & ((1u32 << UNIT_POS_PLANE) - 1u32)).count_ones();
        } else if comptime!(ballot == 2) {
            // N16: a two-word ballot (planes of up to 64 lanes).
            let bal = plane_ballot(kept && one);
            let b0 = bal[0usize];
            let b1 = bal[1usize];
            n = b0.count_ones() + b1.count_ones();
            let l = UNIT_POS_PLANE;
            if l < 32u32 {
                pre = (b0 & ((1u32 << l) - 1u32)).count_ones();
            } else {
                pre = b0.count_ones() + (b1 & ((1u32 << (l - 32u32)) - 1u32)).count_ones();
            }
        } else {
            n = plane_sum(kc);
            pre = plane_exclusive_sum(kc);
        }""")
rep("""        #[comptime] ballot: bool,""", """        #[comptime] ballot: u32,""")
# join launch: wg, dbl, zz
rep("""            join_kernel::launch_unchecked::<R>(
                c,
                CubeCount::Static(join_cubes, 1, 1),
                CubeDim::new_1d(JOIN_WG),""", """            join_kernel::launch_unchecked::<R>(
                c,
                CubeCount::Static(join_cubes, 1, 1),
                CubeDim::new_1d(self.wg),""")
rep("""                self.sflush,
                self.stg,
            );""", """                self.sflush,
                self.stg,
                self.wg,
                self.dbl,
                0u32,
            );""")
# check twice
rep("""            join_cubes,                       // join
            CHECK_CUBES,                      // check
        ];""", """            join_cubes,                       // join
            CHECK_CUBES * if self.dbl & DBL_CHECK != 0 { 2 } else { 1 }, // check
        ];""")
rep("""        unsafe {
            check_kernel::launch_unchecked::<R>(""", """        for _ in 0..if self.dbl & DBL_CHECK != 0 { 2 } else { 1 } {
            self.n_launch.set(self.n_launch.get() + 1);
            unsafe {
            check_kernel::launch_unchecked::<R>(""")
rep("""                0u32,
                0u32,
                0u32,
                probe,
            );
        }
        c.flush()""", """                0u32,
                0u32,
                0u32,
                probe,
            );
            }
        }
        c.flush()""")
# launch counting: top, bucket, join
rep("""        self.launch_top(vs, &vs_h, &grp_cnt, &ran, self.top_fd);""",
    """        self.launch_top(vs, &vs_h, &grp_cnt, &ran, self.top_fd);
        // N16 accounting: the top stage's launches (FD + clipped) and bucket + join.
        self.n_launch
            .set(self.n_launch.get() + 2 + if self.top_fd { 1 + self.top_fix(vs) as u64 } else { 1 });""")
rep("""    profile: bool,
    prof: std::cell::Cell<JoinProfile>,
}""", """    profile: bool,
    prof: std::cell::Cell<JoinProfile>,
    /// N16: kernel launches so far (`NICE_EXP_HOSTACC`).
    n_launch: std::cell::Cell<u64>,
}""")
open(p, 'w').write(s)
print('patched N16 host (part 1)', p)

# ---- part 2
s = open(p).read()
rep("""            prof: std::cell::Cell::new(JoinProfile::default()),""",
    """            prof: std::cell::Cell::new(JoinProfile::default()),
            n_launch: std::cell::Cell::new(0),""")
rep("""/// Experimental per-phase profile of the join (`NICE_EXP_GPU_PROFILE=1`):""",
    """/// N16 `NICE_EXP_JOIN_DBL` bits: parts of the join executed twice, each
/// exact (same counts and hits), so cost(part) = T(doubled) - T(full) with
/// the card at least as loaded as in production.
pub(crate) const DBL_LOAD: u32 = 1; // the batch loads of the top records into shared memory
pub(crate) const DBL_COPY: u32 = 2; // the transposed copy (t_tr)
pub(crate) const DBL_AND: u32 = 4; // the AND (transposed ORs, or the per-top tests)
pub(crate) const DBL_WALK: u32 = 8; // a shadow walk: the rounds' vote and pop, no prefilter
pub(crate) const DBL_PREFILTER: u32 = 16; // the lean prefilter twice per walked pair
pub(crate) const DBL_CHECK: u32 = 32; // the check kernel launched twice (hits deduplicated)
pub(crate) const DBL_WAVE: u32 = 64; // the entry waves' loads (lists, ext_m, ext_q, bp_r) and terms
pub(crate) const DBL_BARRIERS: u32 = 128; // every work-item and batch barrier twice
#[allow(dead_code)]
pub(crate) const DBL_HELP: [u32; 8] = [
    DBL_LOAD,
    DBL_COPY,
    DBL_AND,
    DBL_WALK,
    DBL_PREFILTER,
    DBL_CHECK,
    DBL_WAVE,
    DBL_BARRIERS,
];

/// N16 host-side launch accounting (`NICE_EXP_HOSTACC=1`), summed over the
/// process: batches, kernel launches, fences that were pending, count reads,
/// and nanoseconds in `launch_batch` (buffers created, kernels encoded and
/// submitted, flush), in `launch_fence`, waiting on fences, and reading.
pub(crate) mod hostacc {
    use std::sync::atomic::{AtomicU64, Ordering::Relaxed};
    pub static BATCHES: AtomicU64 = AtomicU64::new(0);
    pub static LAUNCHES: AtomicU64 = AtomicU64::new(0);
    pub static FENCES: AtomicU64 = AtomicU64::new(0);
    pub static READS: AtomicU64 = AtomicU64::new(0);
    pub static ENC_NS: AtomicU64 = AtomicU64::new(0);
    pub static FENCE_NS: AtomicU64 = AtomicU64::new(0);
    pub static WAIT_NS: AtomicU64 = AtomicU64::new(0);
    pub static READ_NS: AtomicU64 = AtomicU64::new(0);
    pub fn on() -> bool {
        static ON: std::sync::OnceLock<bool> = std::sync::OnceLock::new();
        *ON.get_or_init(|| super::exp_env("NICE_EXP_HOSTACC", 0) == 1)
    }
    pub fn add(c: &AtomicU64, v: u64) {
        c.fetch_add(v, Relaxed);
    }
    pub fn reset() {
        for c in [&BATCHES, &LAUNCHES, &FENCES, &READS, &ENC_NS, &FENCE_NS, &WAIT_NS, &READ_NS] {
            c.store(0, Relaxed);
        }
    }
    #[allow(clippy::cast_precision_loss)]
    pub fn line() -> String {
        let g = |c: &AtomicU64| c.load(Relaxed);
        let s = |c: &AtomicU64| c.load(Relaxed) as f64 * 1e-9;
        format!(
            "HOSTACC batches={} launches={} fences_pending={} reads={} encode_s={:.3} fence_s={:.3} \\
             wait_s={:.3} read_s={:.3}",
            g(&BATCHES),
            g(&LAUNCHES),
            g(&FENCES),
            g(&READS),
            s(&ENC_NS),
            s(&FENCE_NS),
            s(&WAIT_NS),
            s(&READ_NS)
        )
    }
}

/// Experimental per-phase profile of the join (`NICE_EXP_GPU_PROFILE=1`):""")
# run_pass instrumentation
rep("""        while inflight.len() >= BATCHES_IN_FLIGHT {
            let tw = Instant::now();
            if let Some((f, upto)) = inflight.pop_front() {
                cubecl::future::block_on(f).map_err(|e| anyhow!("launch fence failed: {e:?}"))?;
                count_to(upto);
            }
            st.device_wait_secs += tw.elapsed().as_secs_f64();
        }
        let rec = dev.launch_batch(batch, false)?;
        launched += batch.len();
        match launch_fence(client)? {
            Some(f) => inflight.push_back((f, launched)),
            // Nothing was pending: the batch has already run.
            None => count_to(launched),
        }""", """        while inflight.len() >= BATCHES_IN_FLIGHT {
            let tw = Instant::now();
            if let Some((f, upto)) = inflight.pop_front() {
                cubecl::future::block_on(f).map_err(|e| anyhow!("launch fence failed: {e:?}"))?;
                count_to(upto);
            }
            st.device_wait_secs += tw.elapsed().as_secs_f64();
            if hostacc::on() {
                hostacc::add(&hostacc::WAIT_NS, tw.elapsed().as_nanos() as u64);
            }
        }
        let te = Instant::now();
        let rec = dev.launch_batch(batch, false)?;
        launched += batch.len();
        let tf = Instant::now();
        let fence = launch_fence(client)?;
        if hostacc::on() {
            hostacc::add(&hostacc::ENC_NS, (tf - te).as_nanos() as u64);
            hostacc::add(&hostacc::FENCE_NS, tf.elapsed().as_nanos() as u64);
            hostacc::add(&hostacc::BATCHES, 1);
            hostacc::add(&hostacc::LAUNCHES, dev.n_launch.replace(0));
            hostacc::add(&hostacc::FENCES, u64::from(fence.is_some()));
        }
        match fence {
            Some(f) => inflight.push_back((f, launched)),
            // Nothing was pending: the batch has already run.
            None => count_to(launched),
        }""")
rep("""    let counts = cubecl::future::block_on(client.read_async(handles))
        .map_err(|e| anyhow!("read failed: {e:?}"))?;
    if dev.profile {
        st.prof.read_secs += tr.elapsed().as_secs_f64();
    }""", """    let counts = cubecl::future::block_on(client.read_async(handles))
        .map_err(|e| anyhow!("read failed: {e:?}"))?;
    if dev.profile {
        st.prof.read_secs += tr.elapsed().as_secs_f64();
    }
    if hostacc::on() {
        hostacc::add(&hostacc::READS, 1);
        hostacc::add(&hostacc::READ_NS, tr.elapsed().as_nanos() as u64);
    }""")
# slots cap
rep("""    let mut dev = JoinDevice::new(client, fs, &plan)?;
    let mut slots = slots_hint.clamp(1, dev.max_slots);""", """    let mut dev = JoinDevice::new(client, fs, &plan)?;
    // N16: `NICE_EXP_SLOTS` caps the partitions per launch (1, 2, 4, ...).
    let mut slots = slots_hint
        .clamp(1, dev.max_slots)
        .min(exp_env("NICE_EXP_SLOTS", u32::MAX) as usize);""")
# harness: reset after warm-up, print after JOIN THROUGHPUT
rep("""            let warm = FieldSize::new(start - warm_size, start);
            run_routed(ctx, base, &warm);""", """            let warm = FieldSize::new(start - warm_size, start);
            run_routed(ctx, base, &warm);
            super::hostacc::reset();""")
rep("""                mib(in_use),
                mib(reserved),
            );
            if compare {""", """                mib(in_use),
                mib(reserved),
            );
            if super::hostacc::on() {
                eprintln!("{} fields={n}", super::hostacc::line());
            }
            if compare {""")
# plane probe kernel and its use
rep("""    /// Count the cube in `ran[stage]` once every unit of it is done (see""",
    """    /// N16: what a kernel sees of its plane (`NICE_EXP_INFO`): PLANE_DIM,
    /// CUBE_DIM and the units of plane 0 that vote (plane_sum of 1).
    #[cube(launch_unchecked)]
    pub fn plane_probe(out: &mut Array<u32>) {
        let n = plane_sum(1u32);
        if UNIT_POS_X == 0u32 {
            out[0] = PLANE_DIM;
            out[1] = CUBE_DIM_X;
            out[2] = n;
        }
    }

    /// Count the cube in `ran[stage]` once every unit of it is done (see""")
rep("""            pr.features.plane,
            lim
        );
    }""", """            pr.features.plane,
            lim
        );
        for wg in [256u32, 128, 64] {
            let h = client.create(cubecl::bytes::Bytes::from_elems(vec![0u32; 3]));
            unsafe {
                kernels::plane_probe::launch_unchecked::<R>(
                    client,
                    CubeCount::Static(1, 1, 1),
                    CubeDim::new_1d(wg),
                    ArrayArg::from_raw_parts(h.clone(), 3),
                );
            }
            match client.read_one(h) {
                Ok(b) => {
                    let v = u32::from_bytes(&b);
                    eprintln!(
                        "EXP_PLANE wg={wg} plane_dim={} cube_dim={} plane_sum1={}",
                        v[0], v[1], v[2]
                    );
                }
                Err(e) => eprintln!("EXP_PLANE wg={wg} read failed: {e:?}"),
            }
        }
    }""")
open(p, 'w').write(s)
print('patched N16 host (part 2)', p)
