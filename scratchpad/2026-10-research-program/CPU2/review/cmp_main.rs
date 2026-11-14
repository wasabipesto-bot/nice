// Main adapter (41b4b405): every block certified.
struct Emu;
fn emu_report() -> String {
    String::new()
}
fn emu_new() -> Emu {
    Emu
}
fn emu_tops(join: &CpuJoin, v: u32, _emu: &mut Emu) -> Vec<Top> {
    let (mut out, mut tops) = (Vec::new(), Vec::new());
    for key in 0..join.keyspace as usize {
        let (lo, hi) = (join.key_off[key] as usize, join.key_off[key + 1] as usize);
        if lo == hi {
            continue;
        }
        join.tops(v, &join.fs.tlay[lo..hi], &mut tops);
        out.extend_from_slice(&tops);
    }
    out
}
include!("cmp_common.rs");
