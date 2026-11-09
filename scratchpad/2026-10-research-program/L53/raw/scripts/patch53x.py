#!/usr/bin/env python3
"""L53 experiment (not for the PR): adds the ignored test `l53_sort_timing` to common/src/cubecl_join.rs of the tree
given as argv[1]. For every field "b:start:size" in NICE_L53_FIELDS it plans the field for this CUDA device (the
same slices as the throughput harness), and for every slice times #249's sort (copied verbatim as `old_sorted_layer`,
on the slice's own setup) and the new `sorted_layer`, asserts both give the same words and offsets, counts the
prefixes the new form takes by division, and times the slice-0 layer clone the device thread does."""
import sys
p = sys.argv[1] + '/common/src/cubecl_join.rs'
s = open(p).read()
anchor = "    /// The host side of the static bucket order, without a device: the\n"
assert anchor in s and 'l53_sort_timing' not in s
test = r'''    /// #249's sort, verbatim (L53's reference and its "before" timing).
    fn old_sorted_layer(fs: &FieldSetup, nkeys: u32) -> Result<(Vec<u32>, Vec<u32>)> {
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

    #[test]
    #[cfg(feature = "cubecl-cuda")]
    #[ignore = "L53: host timing of the layer sort"]
    #[allow(clippy::cast_precision_loss)]
    fn l53_sort_timing() {
        let ctx = CubeclContext::new_cuda(0).expect("CubeCL CUDA init");
        let name = ctx.device_name();
        let CubeclContext::Cuda { client, .. } = ctx else {
            unreachable!("new_cuda is CUDA")
        };
        let lim = device_limits(&client, &name);
        let specs = std::env::var("NICE_L53_FIELDS").expect("NICE_L53_FIELDS");
        for spec in specs.split(',') {
            let f: Vec<&str> = spec.split(':').collect();
            let b: u32 = f[0].parse().expect("base");
            let start: u128 = f[1].parse().expect("start");
            let size = f[2].parse::<f64>().expect("size") as u128;
            let range = FieldSize::new(start, start + size);
            let tp = Instant::now();
            let field = crate::join_plan::plan_join(b, &range, lim).expect("a join field");
            let plan_secs = tp.elapsed().as_secs_f64();
            let (mut t_old, mut t_new, mut t_sub, mut t_p1, mut npre, mut nslow) = (0.0, 0.0, 0.0, 0.0, 0usize, 0usize);
            let tc = Instant::now();
            let cl = field.layer.clone();
            let clone_secs = tc.elapsed().as_secs_f64();
            drop(cl);
            for (i, sl) in field.slices.iter().enumerate() {
                let ts = Instant::now();
                let fs = if i == 0 {
                    field.fs.clone()
                } else {
                    field.fs.sub_range(sl.start(), sl.end()).expect("slice")
                };
                let sub = ts.elapsed().as_secs_f64();
                let nkeys = if fs.key_level { fs.b } else { 1 };
                let t0 = Instant::now();
                let (tl, goff) = old_sorted_layer(&fs, nkeys).expect("old");
                let old = t0.elapsed().as_secs_f64();
                let t1 = Instant::now();
                let layer = sorted_layer(&fs).expect("new");
                let new = t1.elapsed().as_secs_f64();
                // Pass 1 alone (a replica of the new form's first loop): residues, groups, counts.
                let t2 = Instant::now();
                let (bb, mm1) = (u64::from(fs.b), u64::from(fs.m1));
                let pdm = u64::try_from(fs.nparts % u128::from(mm1)).expect("u64");
                let class: Vec<u64> = (0..mm1).map(|r| r * pdm % mm1).collect();
                let pm = u64::try_from(fs.base.powu(fs.k2 - fs.f0 - fs.jp.p)).expect("u64");
                let stp = bb.min(pm);
                let wrap = |r: u64, m: u64| if r >= m { r - m } else { r };
                let mut gr1: Vec<(u64, u32, u32)> = Vec::with_capacity(fs.tlay.len());
                let mut cnt = vec![0u32; fs.nb + 1];
                let mut pv: Option<(u64, u64, u64, u64)> = None;
                for &(p0, _) in &fs.tlay {
                    let p0 = u64::try_from(p0).expect("u64");
                    let (_, rb, rm, rp) = match pv {
                        Some((q, rb, rm, rp)) if p0 >= q && p0 - q < stp => {
                            let d = p0 - q;
                            (p0, wrap(rb + d, bb), wrap(rm + d, mm1), wrap(rp + d, pm))
                        }
                        _ => (p0, p0 % bb, p0 % mm1, p0 % pm),
                    };
                    pv = Some((p0, rb, rm, rp));
                    let key = if fs.key_level { rb } else { 0 };
                    #[allow(clippy::cast_possible_truncation)]
                    let (g, r) = ((key * mm1 + class[rm as usize]) as u32, rp as u32);
                    cnt[g as usize + 1] += 1;
                    gr1.push((p0, g, r));
                }
                let pass1 = t2.elapsed().as_secs_f64();
                assert_eq!(gr1.len(), fs.tlay.len());
                drop(gr1);
                assert!(layer.words == tl && layer.goff == goff, "b{b} slice {i}: the layers differ");
                if i == 0 {
                    assert!(field.layer.words == tl && field.layer.goff == goff, "b{b} slice 0: the field's layer differs");
                }
                let p0mod = u64::try_from(fs.base.powu(fs.k2 - fs.f0 - fs.jp.p)).expect("u64");
                let step = u64::from(fs.b).min(p0mod);
                let mut prev: Option<u64> = None;
                let mut slow = 0usize;
                for &(p0, _) in &fs.tlay {
                    let p0 = u64::try_from(p0).expect("u64");
                    match prev {
                        Some(q) if p0 >= q && p0 - q < step => {}
                        _ => slow += 1,
                    }
                    prev = Some(p0);
                }
                println!(
                    "L53 SLICE b{b} slice={i} prefixes={} old={old:.4}s new={new:.4}s pass1={pass1:.4}s (layer.secs={:.4}) sub_range={sub:.4}s slow={slow} words_equal=1",
                    fs.tlay.len(),
                    layer.secs
                );
                t_old += old;
                t_new += new;
                t_sub += sub;
                t_p1 += pass1;
                npre += fs.tlay.len();
                nslow += slow;
            }
            println!(
                "L53 FIELD b{b} size={size:e} slices={} prefixes={npre} old={t_old:.3}s new={t_new:.3}s pass1={t_p1:.3}s ratio={:.1} slow={nslow} ({:.2}%) sub_range_total={t_sub:.3}s plan_join={plan_secs:.3}s (first layer {:.4}s) slice0_clone={clone_secs:.4}s all_equal=1",
                field.slices.len(),
                t_old / t_new,
                100.0 * nslow as f64 / npre as f64,
                field.layer.secs
            );
        }
    }

'''
s = s.replace(anchor, test + anchor, 1)
open(p, 'w').write(s)
print('patched', p)
