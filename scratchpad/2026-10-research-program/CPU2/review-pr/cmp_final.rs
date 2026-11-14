// Final-tree adapter (3ba5766a, PR review): the tops a thread's run would make,
// with the carried state, through Scratch::enter itself.
type Emu = Scratch;
/// Prefix entries above the partition at entry (an upper bound on the blocks
/// skipped, out-of-range prefixes included), partitions, partitions with runs.
static SKIPPED: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
static PARTS: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
static RUNS_ON: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
fn emu_report() -> String {
    use std::sync::atomic::Ordering::Relaxed;
    format!(
        "emulated partitions {}, with runs worked out {}, prefix entries above their partition {}",
        PARTS.load(Relaxed),
        RUNS_ON.load(Relaxed),
        SKIPPED.load(Relaxed)
    )
}
fn emu_new() -> Emu {
    Scratch::default()
}
fn emu_tops(join: &CpuJoin, v: u32, emu: &mut Emu) -> Vec<Top> {
    // The final tree's own rule (Scratch::enter), not a copy.
    let runs = emu.enter(join.id, v, join.fs.tlay.len());
    let vv = u16::try_from(v).unwrap_or(u16::MAX);
    SKIPPED.fetch_add(
        emu.next.iter().filter(|&&n| vv < n).count() as u64,
        std::sync::atomic::Ordering::Relaxed,
    );
    PARTS.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
    if runs {
        RUNS_ON.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
    }
    let (mut out, mut tops) = (Vec::new(), Vec::new());
    for key in 0..join.keyspace as usize {
        let (lo, hi) = (join.key_off[key] as usize, join.key_off[key + 1] as usize);
        if lo == hi {
            continue;
        }
        join.tops(v, &join.fs.tlay[lo..hi], &mut emu.next[lo..hi], runs, &mut tops);
        out.extend_from_slice(&tops);
    }
    out
}
include!("cmp_common.rs");
