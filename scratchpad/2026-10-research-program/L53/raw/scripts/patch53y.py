#!/usr/bin/env python3
"""L53 experiment (not for the PR): an in-process A/B. With NICE_EXP_L53_ALT set, every other field (by a process-wide
count of run_slices_with calls, the warm-up field included) runs in "old" mode, exactly as 87958fd did: no sort beside
the device work; each slice's layer sorted by #249's code (copied verbatim) at the top of run_slice, on the device
thread, inside device_secs. "new" fields run the commit's path unchanged. Same process, same kernel images (no spill
coin flip between sides), same thermal state for neighbouring fields. Per field it prints a line
  L53 FIELD n=<count> mode=old|new b=<base> slices= device= wall= sort_dev= prep_wait= setup=
(wall = run_slices_with's own duration; sort_dev = the device thread's sort time; prep_wait = time the device thread
waited for the slice-preparing thread). With NICE_EXP_L53_REPEAT the throughput harness repeats its first field n times
(so neighbouring fields are the same field). Applied to tree argv[1] (the commit tree)."""
import sys
p = sys.argv[1] + '/common/src/cubecl_join.rs'
s = open(p).read()
def rep(a, b):
    global s
    assert s.count(a) == 1, a[:80]
    s = s.replace(a, b, 1)

rep("""/// [`run_slices`], counting the partitions run on `progress`.
fn run_slices_with<R: Runtime>(""", """static L53_FIELDS: std::sync::atomic::AtomicUsize = std::sync::atomic::AtomicUsize::new(0);
static L53_SORT_NS: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);

/// #249's sort, verbatim (L53's "old" mode).
fn l53_old_sorted_layer(fs: &FieldSetup, nkeys: u32) -> Result<(Vec<u32>, Vec<u32>)> {
    let (m1, nk) = (u64::from(fs.m1), u64::from(nkeys));
    ensure!(
        usize::try_from(nk * m1) == Ok(fs.nb),
        "{} buckets for {nkeys} keys",
        fs.nb
    );
    let pdiv_m1 = u64::try_from(fs.nparts % u128::from(m1))?;
    let p0mod = u64::try_from(fs.base.powu(fs.k2 - fs.f0 - fs.jp.p))?;
    let p0s: Vec<u64> = fs
        .tlay
        .iter()
        .map(|&(p0, _)| u64::try_from(p0).map_err(|_| anyhow!("top-layer prefix exceeds u64")))
        .collect::<Result<_>>()?;
    let group = |p0: u64| -> usize {
        let key = if nkeys > 1 { p0 % nk } else { 0 };
        #[allow(clippy::cast_possible_truncation)]
        let g = (key * m1 + (p0 % m1) * pdiv_m1 % m1) as usize;
        g
    };
    let mut goff = vec![0u32; fs.nb + 1];
    for &p0 in &p0s {
        goff[group(p0) + 1] += 1;
    }
    for g in 0..fs.nb {
        goff[g + 1] += goff[g];
    }
    let mut at = goff.clone();
    let mut tl = vec![0u32; 5 * p0s.len()];
    for &p0 in &p0s {
        let g = group(p0);
        let i = at[g] as usize;
        at[g] += 1;
        let w = u32_words(u128::from(p0));
        tl[5 * i..5 * i + 5].copy_from_slice(&[
            w[0],
            w[1],
            u32::try_from(g)?,
            goff[g],
            u32::try_from(p0 % p0mod)?,
        ]);
    }
    Ok((tl, goff))
}

/// [`run_slices`], counting the partitions run on `progress`.
fn run_slices_with<R: Runtime>(""")

rep("""    let mut hits = Vec::new();
    let mut slots_hint = field.plan.slots;
    let mut next: Option<Result<(FieldSetup, SortedLayer)>> = None;
    for i in 0..count.min(field.slices.len()) {
        let owned;
        let (fs, layer) = if i == 0 {
            (&field.fs, field.layer.clone())
        } else {
            owned = next.take().expect("prepared beside the previous slice")?;
            (&owned.0, owned.1)
        };
        st.slices += 1;
        st.setup_secs += fs.secs + layer.secs;""", """    let mut hits = Vec::new();
    let mut slots_hint = field.plan.slots;
    let l53_t = Instant::now();
    let l53_n = L53_FIELDS.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
    let l53_old = std::env::var("NICE_EXP_L53_ALT").is_ok() && l53_n % 2 == 1;
    L53_SORT_NS.store(0, std::sync::atomic::Ordering::Relaxed);
    let mut l53_wait = 0.0f64;
    let mut next: Option<Result<(FieldSetup, Option<SortedLayer>)>> = None;
    for i in 0..count.min(field.slices.len()) {
        let owned;
        let (fs, layer) = if i == 0 {
            (&field.fs, (!l53_old).then(|| field.layer.clone()))
        } else {
            owned = next.take().expect("prepared beside the previous slice")?;
            (&owned.0, owned.1)
        };
        st.slices += 1;
        st.setup_secs += fs.secs + layer.as_ref().map_or(0.0, |l| l.secs);""")

rep("""            let prep = later.map(|sl| {
                scope.spawn(|| -> Result<(FieldSetup, SortedLayer)> {
                    let fs = field.fs.sub_range(sl.start(), sl.end())?;
                    let layer = sorted_layer(&fs)?;
                    Ok((fs, layer))
                })
            });""", """            let prep = later.map(|sl| {
                scope.spawn(move || -> Result<(FieldSetup, Option<SortedLayer>)> {
                    let fs = field.fs.sub_range(sl.start(), sl.end())?;
                    if l53_old {
                        return Ok((fs, None));
                    }
                    let layer = sorted_layer(&fs)?;
                    Ok((fs, Some(layer)))
                })
            });""")

rep("""            next = prep.map(|h| h.join().expect("slice setup panicked"));
            Ok(())
        })?;
    }
    hits.sort_unstable();
    hits.dedup();""", """            let l53_w = Instant::now();
            next = prep.map(|h| h.join().expect("slice setup panicked"));
            l53_wait += l53_w.elapsed().as_secs_f64();
            Ok(())
        })?;
    }
    #[allow(clippy::cast_precision_loss)]
    let l53_sort = L53_SORT_NS.load(std::sync::atomic::Ordering::Relaxed) as f64 * 1e-9;
    eprintln!(
        "L53 FIELD n={l53_n} mode={} b={} slices={} device={:.4} wall={:.4} sort_dev={:.4} prep_wait={:.4} setup={:.4}",
        if l53_old { "old" } else { "new" },
        field.fs.b,
        st.slices,
        st.device_secs,
        l53_t.elapsed().as_secs_f64(),
        l53_sort,
        l53_wait,
        st.setup_secs
    );
    hits.sort_unstable();
    hits.dedup();""")

rep("""fn run_slice<R: Runtime>(
    client: &ComputeClient<R>,
    fs: &FieldSetup,
    layer: SortedLayer,""", """fn run_slice<R: Runtime>(
    client: &ComputeClient<R>,
    fs: &FieldSetup,
    layer: Option<SortedLayer>,""")

rep("""    let t0 = Instant::now();
    let (plan, mut retry) = layouts;
    let mut dev = JoinDevice::new(client, fs, layer, &plan)?;""", """    let t0 = Instant::now();
    let (plan, mut retry) = layouts;
    let layer = match layer {
        Some(l) => l,
        None => {
            // 87958fd: the sort on the device thread, inside device_secs.
            let ts = Instant::now();
            let nkeys = if fs.key_level { fs.b } else { 1 };
            let (words, goff) = l53_old_sorted_layer(fs, nkeys)?;
            #[allow(clippy::cast_possible_truncation)]
            L53_SORT_NS.fetch_add(ts.elapsed().as_nanos() as u64, std::sync::atomic::Ordering::Relaxed);
            SortedLayer {
                words,
                goff,
                secs: 0.0,
            }
        }
    };
    let mut dev = JoinDevice::new(client, fs, layer, &plan)?;""")
# The harness: with NICE_EXP_L53_REPEAT set, all n fields are the first one (the same field, repeated).
rep("""            let fields: Vec<FieldSize> = (0..n)
                .map(|i| FieldSize::new(start + i * size, start + (i + 1) * size))
                .collect();""", """            let l53_rep = std::env::var("NICE_EXP_L53_REPEAT").is_ok();
            let fields: Vec<FieldSize> = (0..n)
                .map(|i| if l53_rep { 0 } else { i })
                .map(|i| FieldSize::new(start + i * size, start + (i + 1) * size))
                .collect();""")
open(p, 'w').write(s)
print('patched', p)
