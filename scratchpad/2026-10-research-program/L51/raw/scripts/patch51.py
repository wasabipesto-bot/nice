#!/usr/bin/env python3
"""patch51.py: L51's experiment switches on d813aea + the cherry-picked profile (0cfbc7d).
Profile split (top_fd / top_clip, null mark, spilled); join ablation modes (L45's 1-4) on #249's
kernel; env-driven comptime knobs: TMIN, EPT, AND_GROUP, TOP_CAP, SURV_FLUSH, stage cadence, FD cube size.
Every default reproduces d813aea's kernels."""
import sys
p = sys.argv[1]
s = open(p).read()

def rep(old, new, count=1):
    global s
    n = s.count(old)
    assert n == count, (n, old[:120])
    s = s.replace(old, new)

# ---------------- join_kernel ----------------
ks = s.index('    pub fn join_kernel(')
ke = s.index('    /// 16-bit limbs of `k^e`', ks)
k = s[ks:ke]

def krep(old, new, count=1):
    global k
    n = k.count(old)
    assert n == count, (n, old[:120])
    k = k.replace(old, new)

krep('''        #[comptime] walk_sync: bool,
    ) {
''', '''        #[comptime] walk_sync: bool,
        #[comptime] abl: u32,
        #[comptime] tmin: u32,
        #[comptime] spc: bool,
        #[comptime] ag_c: u32,
        #[comptime] tcap: u32,
        #[comptime] sflush: u32,
        #[comptime] stg: u32,
    ) {
        // L51 (experimental, `NICE_EXP_JOIN_*`): `abl` 0 full; 1 AND only
        // (pass masks formed, range-tested and counted, no walk); 2 walk
        // without the prefilter and the stage; 3 walk and prefilter, no
        // stage; 4 no AND (every pass mask 0). `tmin` = the transpose gate, `ag_c`
        // = AND_GROUP, `tcap` = TOP_CAP, `sflush` = SURV_FLUSH; `stg` 0 the
        // stage checked once per top batch (d813aea), 1 once per work item;
        // `spc` counts pairs written past a full stage in `and_count[1]`.
        let mut ck = 0u32;
        let mut npf: u32 = 0u32;
''')
krep('TOP_CAP', 'tcap', k.count('TOP_CAP'))
krep('let ag = comptime!(AND_GROUP);', 'let ag = comptime!(ag_c);')

# batch load: a loop when tcap > JOIN_WG
bl_start = k.index('                if UNIT_POS_X < nt {\n                    // Top q of the bucket')
bl_end = k.index('                sync_cube();\n                if nt >= TRANSPOSE_MIN {', bl_start)
body = k[bl_start:bl_end]
inner = body[len('                if UNIT_POS_X < nt {\n'):]
assert inner.endswith('                }\n')
inner = inner[:-len('                }\n')]
inner_u = inner.replace('UNIT_POS_X', 'uu')
newbl = ('                if comptime!(tcap <= JOIN_WG) {\n' + body.replace('\n                ', '\n                    ').replace('                if UNIT_POS_X < nt {', '                    if UNIT_POS_X < nt {', 1)
         + '                } else {\n'
         '                    let mut uu = UNIT_POS_X;\n'
         '                    while uu < nt {\n' + inner_u.replace('\n                    ', '\n                        ').replace('                    // Top q', '                        // Top q', 1) +
         '                        uu += JOIN_WG;\n'
         '                    }\n'
         '                }\n')
k = k[:bl_start] + newbl + k[bl_end:]

# transposed copy: guarded / looped when tcap != JOIN_WG
tr_start = k.index('                if nt >= TRANSPOSE_MIN {\n                    // Thread u writes chunk')
tr_end = k.index('                sync_cube();\n\n                let mut ws = 0u32;', tr_start)
tr = k[tr_start:tr_end]
a = tr.index('                    let cc = UNIT_POS_X / 32u32;')
b = tr.rindex('                }\n')
tr_body = tr[a:b]
loop_body = tr_body.replace('                    let cc = UNIT_POS_X / 32u32;\n', '')
loop_body = loop_body.replace('\n                    ', '\n                        ')
loop_body = '    ' + loop_body.lstrip(' ').join(['', '']) if False else loop_body
new_tr = ('                if nt >= tmin {\n'
          + tr[len('                if nt >= TRANSPOSE_MIN {\n'):a]
          + '                    if comptime!(tcap == JOIN_WG) {\n'
          + tr_body.replace('\n                    ', '\n                        ').replace('                    let cc', '                        let cc', 1)
          + '                    } else {\n'
          '                        let mut cc = UNIT_POS_X / 32u32;\n'
          '                        while cc < comptime!(tcap / 32) {\n'
          + '                            ' + loop_body.replace('\n                        ', '\n                            ').lstrip(' ')
          + '                            cc += comptime!(JOIN_WG / 32);\n'
          '                        }\n'
          '                    }\n'
          '                }\n')
k = k[:tr_start] + new_tr + k[tr_end:]

# ablation: checksum of the entry loads (modes 1, 2, 4)
krep('''                    // Branch-free AND over a chunk of up to 32 tops into a pass
''', '''                    if comptime!(abl == 1 || abl == 2 || abl == 4) {
                        #[unroll]
                        for j in 0..ept {
                            ck ^= ac[j as usize]
                                ^ ac3[j as usize]
                                ^ pc[j as usize]
                                ^ pc3[j as usize]
                                ^ rr[j as usize]
                                ^ mlo[j as usize]
                                ^ mhi[j as usize];
                        }
                    }
                    // Branch-free AND over a chunk of up to 32 tops into a pass
''')
krep('''                        let mut pm = Array::<u32>::new(ept as usize);
                        if nt >= TRANSPOSE_MIN {''', '''                        let mut pm = Array::<u32>::new(ept as usize);
                        if comptime!(abl == 4) {
                            #[unroll]
                            for j in 0..ept {
                                pm[j as usize] = 0u32;
                            }
                        } else if nt >= tmin {''')
# walk
w0 = k.index('                        #[unroll]\n                        for j in 0..ept {\n                            let mut x = pm[j as usize] & vv[j as usize];')
w1 = k.index('                        jc += 32u32;', w0)
walk = k[w0:w1]
walk = walk.replace('''                                    let pass = if comptime!(lean) {''', '''                                    if comptime!(abl == 2) {
                                        npf ^= jt2;
                                    } else {
                                    let pass = if comptime!(lean) {''', 1)
walk = walk.replace('''                                    if pass {
                                        let at = s_cnt[0].fetch_add(1u32);''', '''                                    if comptime!(abl == 3) {
                                        if pass {
                                            npf += 1u32;
                                        }
                                    } else if pass {
                                        let at = s_cnt[0].fetch_add(1u32);''', 1)
walk = walk.replace('''                                        } else {
                                            let g = surv_count[0].fetch_add(1u32);''', '''                                        } else {
                                            if comptime!(spc) {
                                                and_count[1].fetch_add(1u32);
                                            }
                                            let g = surv_count[0].fetch_add(1u32);''', 1)
walk = walk.replace('''                                }
                                if walk_sync {''', '''                                    }
                                }
                                if walk_sync {''', 1)
assert walk.count('npf') == 2 and walk.count('spc') == 1
walk = ('                        if comptime!(abl == 1 || abl == 4) {\n'
        '                            // no walk\n'
        '                        } else {\n' + walk + '                        }\n')
k = k[:w0] + walk + k[w1:]

# stage cadence + flush level
krep('''                sync_cube();
                let sc = s_cnt[0].load();
                sync_cube();
                if sc >= SURV_FLUSH {
                    flush_survivors(
                        &s_t,
                        &s_r,
                        &mut s_cnt,
                        &mut s_base,
                        surv,
                        surv_count,
                        surv_cap,
                        sc,
                    );
                    sync_cube();
                }
                if UNIT_POS_X < comptime!(tcap / 32) {''', '''                sync_cube();
                if comptime!(stg == 0) {
                    let sc = s_cnt[0].load();
                    sync_cube();
                    if sc >= sflush {
                        flush_survivors(
                            &s_t,
                            &s_r,
                            &mut s_cnt,
                            &mut s_base,
                            surv,
                            surv_count,
                            surv_cap,
                            sc,
                        );
                        sync_cube();
                    }
                }
                if UNIT_POS_X < comptime!(tcap / 32) {''')
krep('''                tc += tcap;
                sync_cube();
            }
            w += CUBE_COUNT_X;''', '''                tc += tcap;
                sync_cube();
            }
            if comptime!(stg == 1) {
                // Once per work item: every thread is past the last batch's
                // final barrier, so the count is complete and uniform.
                let sc = s_cnt[0].load();
                sync_cube();
                if sc >= sflush {
                    flush_survivors(
                        &s_t,
                        &s_r,
                        &mut s_cnt,
                        &mut s_base,
                        surv,
                        surv_count,
                        surv_cap,
                        sc,
                    );
                    sync_cube();
                }
            }
            w += CUBE_COUNT_X;''')
krep('''        // One atomic per plane for the join survivors.
        let planes_and = plane_sum(nand);''', '''        if comptime!(abl == 1 || abl == 2 || abl == 4) {
            if (ck ^ npf) == 0x9E37_79B9u32 {
                nand += 1u32;
            }
        }
        if comptime!(abl == 3) {
            if npf == 0x9E37_79B9u32 {
                nand += 1u32;
            }
        }
        // One atomic per plane for the join survivors.
        let planes_and = plane_sum(nand);''')
assert 'TRANSPOSE_MIN' not in k.replace('[`TRANSPOSE_MIN`]', '').replace('`TRANSPOSE_MIN`', ''), 'TMIN left'
k = k.replace('[`TRANSPOSE_MIN`]', '[`super::TRANSPOSE_MIN`]')
s = s[:ks] + k + s[ke:]

# kernels' imports: drop what the kernels no longer use
rep('''        AND_GROUP, DEAD_MASK, JOIN_WG, MAX_ROOTS, SURV_FLUSH, SURV_SH_CAP, TOP_CAP, TOP_REC_WORDS,
        TRANSPOSE_MIN,
    };''', '''        DEAD_MASK, JOIN_WG, MAX_ROOTS, SURV_SH_CAP, TOP_REC_WORDS,
    };''')
# the compile-time assert still references the consts (host side); keep them used
rep('''const _: () = assert!(
    JOIN_WG == TOP_CAP''', '''#[allow(dead_code)]
const _: () = assert!(
    JOIN_WG == TOP_CAP''')

# ---------------- host side ----------------
rep('''    walk_sync: bool,
    limbs: u32,''', '''    walk_sync: bool,
    /// L51 experiment knobs (see `join_kernel`): `NICE_EXP_JOIN_ABL`,
    /// `_TMIN`, `_SPILLCNT`, `_EPT`, `_AG`, `_TCAP`, `_FLUSH`, `_STAGE`, and
    /// `NICE_EXP_FD_WG` (the FD top kernel's cube size).
    abl: u32,
    tmin: u32,
    spc: bool,
    ept: u32,
    ag: u32,
    tcap: u32,
    sflush: u32,
    stg: u32,
    fd_wg: u32,
    limbs: u32,''')
rep('''                    .contains(cubecl::ir::features::Plane::Sync),
            limbs,''', '''                    .contains(cubecl::ir::features::Plane::Sync),
            abl: exp_env("NICE_EXP_JOIN_ABL", 0),
            tmin: exp_env("NICE_EXP_JOIN_TMIN", TRANSPOSE_MIN),
            spc: exp_env("NICE_EXP_JOIN_SPILLCNT", 0) == 1,
            ept: exp_env("NICE_EXP_JOIN_EPT", ENTRIES_PER_THREAD),
            ag: exp_env("NICE_EXP_JOIN_AG", AND_GROUP),
            tcap: exp_env("NICE_EXP_JOIN_TCAP", TOP_CAP),
            sflush: exp_env("NICE_EXP_JOIN_FLUSH", SURV_FLUSH),
            stg: exp_env("NICE_EXP_JOIN_STAGE", 0),
            fd_wg: exp_env("NICE_EXP_FD_WG", JOIN_WG),
            limbs,''')
rep('''pub(crate) fn gpu_profile_enabled() -> bool {''', '''pub(crate) fn exp_env(name: &str, default: u32) -> u32 {
    std::env::var(name)
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(default)
}

pub(crate) fn gpu_profile_enabled() -> bool {''')
# join launch
rep('''                ArrayArg::from_raw_parts(survivors.clone(), 1),
                ArrayArg::from_raw_parts(ran.clone(), nran),
                nwork_u32,''', '''                ArrayArg::from_raw_parts(survivors.clone(), 2),
                ArrayArg::from_raw_parts(ran.clone(), nran),
                nwork_u32,''')
rep('''                ENTRIES_PER_THREAD,
                self.f0,
                self.k,
                self.k2,
                self.walk_sync,
            );''', '''                self.ept,
                self.f0,
                self.k,
                self.k2,
                self.walk_sync,
                self.abl,
                self.tmin,
                self.spc,
                self.ag,
                self.tcap,
                self.sflush,
                self.stg,
            );''')
rep('''        let survivors = c.create(cubecl::bytes::Bytes::from_elems(vec![0u32; 1]));
        let checked = c.create(cubecl::bytes::Bytes::from_elems(vec![0u32; 1]));
        // Every kernel counts''', '''        let survivors = c.create(cubecl::bytes::Bytes::from_elems(vec![0u32; 2]));
        let checked = c.create(cubecl::bytes::Bytes::from_elems(vec![0u32; 1]));
        // Every kernel counts''')
rep('let wave = u64::from(ENTRIES_PER_THREAD * JOIN_WG);', 'let wave = u64::from(self.ept * JOIN_WG);')
# FD cube size
rep('''    fn top_expect(&self, vs: &[u32], fd: bool) -> u32 {
        let top_cubes = self.ntlay.div_ceil(JOIN_WG).max(1);
        let nslots = u32::try_from(vs.len()).expect("a batch fits u32");
        let per_slot = top_cubes * nslots;
        let fd_cubes = top_cubes * self.top_fd_groups(nslots).1;''', '''    fn top_expect(&self, vs: &[u32], fd: bool) -> u32 {
        let top_cubes = self.ntlay.div_ceil(JOIN_WG).max(1);
        let nslots = u32::try_from(vs.len()).expect("a batch fits u32");
        let per_slot = top_cubes * nslots;
        let fd_cubes = self.ntlay.div_ceil(self.fd_wg).max(1) * self.top_fd_groups(nslots).1;''')
rep('''                let (slot_k, groups) = self.top_fd_groups(nslots_u32);
                top_fd_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static(top_cubes, groups, 1),
                    CubeDim::new_1d(JOIN_WG),''', '''                let (slot_k, groups) = self.top_fd_groups(nslots_u32);
                top_fd_kernel::launch_unchecked::<R>(
                    c,
                    CubeCount::Static(self.ntlay.div_ceil(self.fd_wg).max(1), groups, 1),
                    CubeDim::new_1d(self.fd_wg),''')
# profile split inside launch_top (the caller synchronised at the inputs mark)
rep('''        let grp_cnt = grp_cnt.clone();
        let ran = ran.clone();
        unsafe {
            if fd {''', '''        let grp_cnt = grp_cnt.clone();
        let ran = ran.clone();
        let mut t0 = Instant::now();
        unsafe {
            if fd {''')
rep('''                    self.tq,
                    self.ballot,
                );
            }
            if !fd || fix {''', '''                    self.tq,
                    self.ballot,
                );
                if self.profile {
                    t0 = self
                        .prof_mark(t0, |p, s| {
                            p.top_fd_secs += s;
                            p.top_secs += s;
                        })
                        .expect("profile sync");
                }
            }
            if !fd || fix {''')
rep('''                    self.nb,
                    fix,
                );
            }
        }
    }''', '''                    self.nb,
                    fix,
                );
                if self.profile {
                    self.prof_mark(t0, |p, s| {
                        p.top_clip_secs += s;
                        p.top_secs += s;
                        p.clip_launches += 1;
                    })
                    .expect("profile sync");
                }
            }
        }
    }''')
# null mark per batch
rep('''        if let Some(t) = pt {
            pt = Some(self.prof_mark(t, |p, s| p.inputs_secs += s)?);
        }
        self.launch_top(''', '''        if let Some(t) = pt {
            let t = self.prof_mark(t, |p, s| p.inputs_secs += s)?;
            pt = Some(self.prof_mark(t, |p, s| p.null_secs += s)?);
        }
        self.launch_top(''')
# JoinProfile fields
rep('''    /// `top_kernel` + `top_scan_kernel` + `top_fill_kernel`.
    pub top_secs: f64,
    pub bucket_secs: f64,''', '''    /// `top_fd_kernel` + the clipped-block `top_kernel` (#249: no scan, fill).
    pub top_secs: f64,
    /// L51: `top_secs` split into the FD kernel and the clipped launches.
    pub top_fd_secs: f64,
    pub top_clip_secs: f64,
    pub clip_launches: u64,
    /// One empty mark per batch (the floor of a mark).
    pub null_secs: f64,
    /// Pairs the walk wrote past a full stage (`NICE_EXP_JOIN_SPILLCNT=1`).
    pub spilled: u64,
    pub bucket_secs: f64,''')
rep('''        self.top_secs += o.top_secs;
        self.bucket_secs += o.bucket_secs;''', '''        self.top_secs += o.top_secs;
        self.top_fd_secs += o.top_fd_secs;
        self.top_clip_secs += o.top_clip_secs;
        self.clip_launches += o.clip_launches;
        self.null_secs += o.null_secs;
        self.spilled += o.spilled;
        self.bucket_secs += o.bucket_secs;''')
rep('''        let surv = u32::from_bytes(&counts[3 * i])[0];''', '''        let surv = u32::from_bytes(&counts[3 * i])[0];
        st.prof.spilled += u64::from(u32::from_bytes(&counts[3 * i]).get(1).copied().unwrap_or(0));''')
rep('''        + p.check_secs
        + p.read_secs;''', '''        + p.check_secs
        + p.read_secs
        + p.null_secs;''')
rep('''         probe={:.4} unattributed={:.4} | ntlay={} nbp={} tops={} listed={} pairs={} \\
         padded_pairs={} live_buckets={} buckets={} survivors={} checked={} hits={hits}",''', '''         probe={:.4} unattributed={:.4} | top_fd={:.4} top_clip={:.4} clip_launches={} null={:.4} \\
         | ntlay={} nbp={} tops={} listed={} pairs={} \\
         padded_pairs={} live_buckets={} buckets={} survivors={} checked={} spilled={} hits={hits}",''')
rep('''        js.device_secs - phases - p.probe_secs,
        p.ntlay,''', '''        js.device_secs - phases - p.probe_secs,
        p.top_fd_secs,
        p.top_clip_secs,
        p.clip_launches,
        p.null_secs,
        p.ntlay,''')
rep('''        js.survivors,
        js.checked,
    );
}''', '''        js.survivors,
        js.checked,
        p.spilled,
    );
}''')
open(p, 'w').write(s)
print('patched')
