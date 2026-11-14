//! CPU2 scratch profiling (not for the PR): the top phase of one partition
//! in isolation, in several ablation modes.
use super::*;
use std::time::Instant;

#[derive(Default, Debug, Clone)]
pub struct TopProf {
    pub prefixes: u64,
    pub unclipped: u64,
    pub seeds: u64,
    pub steps: u64,
    pub tops: u64,
    pub tests: u64,
    pub ns: u64,
}

impl CpuJoin {
    /// Mode 0: `tops()` as the join runs it; 1: advance only; 2: advance +
    /// cert, no push; 3: seed every unclipped prefix.
    #[allow(clippy::cast_possible_truncation)]
    pub fn prof_tops(&self, v: u32, mode: u32, sc: &mut Scratch) -> TopProf {
        let mut pr = TopProf::default();
        let fs = &self.fs;
        let t = Instant::now();
        let mut sink = 0u64;
        for key in 0..self.keyspace as usize {
            let (lo, hi) = (self.key_off[key] as usize, self.key_off[key + 1] as usize);
            if lo == hi {
                continue;
            }
            let layer = &fs.tlay[lo..hi];
            if mode == 0 {
                self.tops(v, layer, &mut vec![0; hi - lo], &mut sc.tops);
                pr.tops += sc.tops.len() as u64;
                continue;
            }
            let fd = self.fd.as_ref().expect("fd");
            let mut st = TopFd::default();
            for &(p0, _) in layer {
                let p = p0 * fs.nparts + u128::from(v);
                if p < fs.plo || p > fs.phi {
                    continue;
                }
                pr.prefixes += 1;
                let lo = p * fs.w;
                if !(lo >= fs.s && lo + fs.w - 1 <= fs.e - 1) {
                    continue;
                }
                pr.unclipped += 1;
                if mode == 3 {
                    fd.seed_pub(&mut st, p);
                    sink ^= st.pc as u64;
                    continue;
                }
                let (s, n) = fd.advance_counted(&mut st, p);
                pr.seeds += s;
                pr.steps += n;
                if mode == 2 {
                    if let Ok(c) = fd.cert(&st) {
                        pr.tops += 1;
                        sink ^= c.mask;
                    }
                } else {
                    sink ^= u64::from(st.pc);
                }
            }
        }
        pr.ns = t.elapsed().as_nanos() as u64;
        std::hint::black_box(sink);
        pr
    }
}

impl CpuJoin {
    /// The skip walk's counts for partition `v` (call in ascending order
    /// with one scratch): prefixes, tests (certs), seeds, steps, tops.
    #[allow(clippy::cast_possible_truncation)]
    pub fn prof_skip(&self, v: u32, sc: &mut Scratch) -> TopProf {
        let mut pr = TopProf::default();
        let fs = &self.fs;
        if !sc.last.is_some_and(|(id, last)| id == self.id && last < v) {
            sc.next.clear();
            sc.next.resize(fs.tlay.len(), 0);
        }
        sc.last = Some((self.id, v));
        let fd = self.fd.as_ref().expect("fd");
        let t = Instant::now();
        for key in 0..self.keyspace as usize {
            let (lo, hi) = (self.key_off[key] as usize, self.key_off[key + 1] as usize);
            let mut st = TopFd::default();
            for i in lo..hi {
                let p = fs.tlay[i].0 * fs.nparts + u128::from(v);
                if p < fs.plo || p > fs.phi {
                    continue;
                }
                pr.prefixes += 1;
                let l = p * fs.w;
                if !(l >= fs.s && l + fs.w - 1 <= fs.e - 1) {
                    continue;
                }
                pr.unclipped += 1;
                if v < u32::from(sc.next[i]) {
                    continue;
                }
                let (s, n) = fd.advance_counted(&mut st, p);
                pr.seeds += s;
                pr.steps += n;
                pr.tests += 1;
                match fd.cert(&st) {
                    Ok(_) => pr.tops += 1,
                    Err(n) => sc.next[i] = u16::try_from(v + n).unwrap_or(u16::MAX),
                }
                pr.unclipped += 0;
                pr.prefixes += 0;
                // tests counted as seeds+... below
                pr.ns += 0;
            }
        }
        pr.ns = t.elapsed().as_nanos() as u64;
        pr
    }
}

impl CpuJoin {
    /// The real `tops()` with the failing runs carried over (ascending
    /// partitions, one scratch): ns and tops.
    #[allow(clippy::cast_possible_truncation)]
    pub fn prof_tops_carried(&self, v: u32, sc: &mut Scratch) -> TopProf {
        let mut pr = TopProf::default();
        if !sc.last.is_some_and(|(id, last)| id == self.id && last < v) {
            sc.next.clear();
            sc.next.resize(self.fs.tlay.len(), 0);
        }
        sc.last = Some((self.id, v));
        let t = Instant::now();
        for key in 0..self.keyspace as usize {
            let (lo, hi) = (self.key_off[key] as usize, self.key_off[key + 1] as usize);
            if lo == hi {
                continue;
            }
            self.tops(v, &self.fs.tlay[lo..hi], &mut sc.next[lo..hi], &mut sc.tops);
            pr.tops += sc.tops.len() as u64;
        }
        pr.ns = t.elapsed().as_nanos() as u64;
        pr
    }
}
