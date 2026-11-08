#!/usr/bin/env python3
import sys, pathlib
path = pathlib.Path(sys.argv[1]); s = path.read_text()
def rep(old, new):
    global s
    assert s.count(old) == 1, old
    s = s.replace(old, new)
# statics
rep("const PIECE: usize = 1024;\n",
    "const PIECE: usize = 1024;\n#[cfg(test)]\nstatic SEEN: [std::sync::atomic::AtomicU64; 256] = [const { std::sync::atomic::AtomicU64::new(0) }; 256];\n#[cfg(test)]\nstatic LONG: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);\n#[cfg(test)]\nstatic MAXLEN: std::sync::atomic::AtomicUsize = std::sync::atomic::AtomicUsize::new(0);\n#[cfg(test)]\nstatic SCANS: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);\n")
rep("    let pos = &BIT_POS[usize::from(bits)];\n",
    "    #[cfg(test)]\n    SEEN[usize::from(bits)].fetch_add(1, std::sync::atomic::Ordering::Relaxed);\n    let pos = &BIT_POS[usize::from(bits)];\n")
rep("        self.each_pass(pass.top.mask, masks, idx, |j| {",
    "        #[cfg(test)]\n        {\n            use std::sync::atomic::Ordering::Relaxed;\n            SCANS.fetch_add(1, Relaxed);\n            MAXLEN.fetch_max(masks.len(), Relaxed);\n            if masks.len() > PIECE {\n                LONG.fetch_add(1, Relaxed);\n            }\n        }\n        self.each_pass(pass.top.mask, masks, idx, |j| {")
# report in the windows test
rep("""        for (b, s, e, jp) in windows() {
            check_partitions(b, s, e, jp, 96);
        }""",
"""        use std::sync::atomic::Ordering::Relaxed;
        for (b, s, e, jp) in windows() {
            LONG.store(0, Relaxed);
            MAXLEN.store(0, Relaxed);
            SCANS.store(0, Relaxed);
            check_partitions(b, s, e, jp, 96);
            eprintln!(
                "INSTR b{b} [{s}, {e}) {jp:?}: scans {}, max class {}, classes > PIECE {}",
                SCANS.load(Relaxed),
                MAXLEN.load(Relaxed),
                LONG.load(Relaxed)
            );
        }""")
# report byte coverage in the new test after the per-length part
rep("""        let range = FieldSize::new(47, 100);
        let jp = JoinParams { t: 2, k: 1, p: 0 };
        let mut joins""",
"""        {
            use std::sync::atomic::Ordering::Relaxed;
            let counts: Vec<u64> = SEEN.iter().map(|c| c.load(Relaxed)).collect();
            let missing: Vec<usize> = (0..256).filter(|&i| counts[i] == 0).collect();
            let min = counts.iter().min().copied().unwrap_or(0);
            eprintln!("INSTR bytes seen by emit (all paths): {} distinct, min count {min}, missing {missing:?}", 256 - missing.len());
        }
        let range = FieldSize::new(47, 100);
        let jp = JoinParams { t: 2, k: 1, p: 0 };
        let mut joins""")
rep("""            let mut sc = Scratch::default();
            for v in 0..best.partitions() {
                let want = best.run_partition(v, &mut sc);""",
"""            let mut sc = Scratch::default();
            use std::sync::atomic::Ordering::Relaxed;
            LONG.store(0, Relaxed);
            MAXLEN.store(0, Relaxed);
            SCANS.store(0, Relaxed);
            for v in 0..best.partitions() {
                let want = best.run_partition(v, &mut sc);
                if v + 1 == best.partitions() {
                    eprintln!(
                        "INSTR2 b{b} [{s}, {e}) {jp:?}: best-path scans {}, max class {}, classes > PIECE {}",
                        SCANS.load(Relaxed),
                        MAXLEN.load(Relaxed),
                        LONG.load(Relaxed)
                    );
                }""")
path.write_text(s); print("instrumented")
