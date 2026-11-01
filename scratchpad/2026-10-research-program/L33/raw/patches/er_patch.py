#!/usr/bin/env python3
"""Early reject prototype (NICE_EXP_TOP_ER=1: per-lane skip of the cube when the
square's certificate is already dead; =2: plus compaction of the survivors within
the cube before the cube's conversion)."""
import re, sys
p = sys.argv[1]
s = open(p).read()

def rep(old, new, count=1):
    global s
    n = s.count(old)
    assert n == count, (n, old[:300])
    s = s.replace(old, new)

# ---------------- top_cert: er gate + top_close
rep("""        #[comptime] chunk_div: u32,
        #[comptime] hist: bool,
    ) -> u64 {
        let nl2 = comptime!(2 * limbs);""",
"""        #[comptime] chunk_div: u32,
        #[comptime] hist: bool,
        #[comptime] er: u32,
    ) -> u64 {
        let nl2 = comptime!(2 * limbs);""")

i0 = s.index("        let mcu = cert_power(\n            &mut a3,\n            &e3,\n            pw,\n            &mut c0b,")
i1 = s.index("        let mut kept = 0u32;\n        if keep {\n            kept = 1u32;\n        }\n        if comptime!(hist) {")
old_block = s[i0:i1]
# the cube call text, to reuse
call_end = old_block.index("        );\n") + len("        );\n")
cube_call = old_block[:call_end]
closure = old_block[call_end:]
assert closure.lstrip().startswith("let mut mask = msq | mcu;"), closure[:80]
new_block = """        // Early reject: a dead square certificate (`dupa`) rejects the
        // interval whatever the cube holds, so the cube is skipped.
        let mut alive = dupa[0] == 0u32;
        if comptime!(er == 0) {
            alive = true;
        }
        let mut mask = msq;
        let mut keep = false;
        let mut mcu = 0u64;
        let mut c0bv = 0xFFFF_FFFFu32;
        if alive {
""" + "\n".join(("    " + l if l else l) for l in cube_call.replace("let mcu = cert_power(", "mcu = cert_power(").split("\n")) + """
            c0bv = c0b[0];
            let mut kp = Array::<u32>::new(1usize);
            mask = top_close(
                msq, mcu, dupa[0], dupb[0], doma[0], doma[1], domb[0], domb[1], &mut kp,
            );
            keep = kp[0] != 0u32;
        }
"""
s = s[:i0] + new_block + s[i1:]
rep("""        res[0] = kept;
        res[1] = c0a[0];
        res[2] = c0b[0];
        mask
    }
""",
"""        res[0] = kept;
        res[1] = c0a[0];
        res[2] = c0bv;
        mask
    }

    /// The end of `top_cert`: the duplicate and cross tests of the two
    /// powers' certificates and `close_certificate` over their
    /// first-disagreement intervals. Returns the mask; `kp[0]` = kept.
    #[cube]
    pub(super) fn top_close(
        msq: u64,
        mcu: u64,
        dupa: u32,
        dupb: u32,
        da0: u32,
        da1: u32,
        db0: u32,
        db1: u32,
        kp: &mut Array<u32>,
    ) -> u64 {
""" + closure.replace("dupa[0] == 0u32 && dupb[0] == 0u32", "dupa == 0u32 && dupb == 0u32")
        .replace("dom_mask(doma[0], doma[1])", "dom_mask(da0, da1)")
        .replace("dom_mask(domb[0], domb[1])", "dom_mask(db0, db1)") + """        kp[0] = select(keep, 1u32, 0u32);
        mask
    }
""")

# ---------------- top_kernel
k0 = s.index("    #[cube(launch_unchecked)]\n    pub fn top_kernel(")
k1 = s.index("    /// Plane-aggregated histogram add")
kern = s[k0:k1]

kern = kern.replace("""        #[comptime] nb: u32,
        #[comptime] hist: bool,
    ) {""", """        #[comptime] nb: u32,
        #[comptime] hist: bool,
        #[comptime] er: u32,
    ) {""")

# a/e/clip -> helper call; capture the original a/e text
a0 = kern.index("        if i < ntlay {\n")
a1 = kern.index("                let mut res = Array::<u32>::new(3usize);")
ae_text = kern[a0:a1]
b0 = kern.index("                if res[0] != 0u32 {\n")
b1 = kern.index("        if comptime!(hist) {\n            let o = comptime!(6u32);")
emit_text = kern[b0:b1]

new_head = """        let mut a = Array::<u32>::new(limbs as usize);
        let mut e = Array::<u32>::new(limbs as usize);
        let mut st = Array::<u32>::new(6usize);
        let mut kept = false;
        let mut mask = 0u64;
        let mut r1 = 0u32;
        let mut r2 = 0u32;
        let mut ie = i;
        let mut s_n = SharedMemory::<Atomic<u32>>::new(1usize);
        let mut s_q = SharedMemory::<u32>::new(comptime!(6 * JOIN_WG as usize));
        if comptime!(er == 2) {
            if UNIT_POS_X == 0u32 {
                s_n[0].store(0u32);
            }
            sync_cube();
        }
        if i < ntlay {
            let inr = top_ae(i, slot, tlay, vs, fb, w, pdiv, &mut a, &mut e, &mut st, limbs);
            if inr {
                if comptime!(er == 2) {
                    // Phase 1: the square's certificate only; the intervals
                    // it does not reject queue for phase 2.
                    let nl2 = comptime!(2 * limbs);
                    let nl3 = comptime!(3 * limbs);
                    let mut a2 = Array::<u32>::new(comptime!(4 * limbs) as usize);
                    let mut e2 = Array::<u32>::new(comptime!(4 * limbs) as usize);
                    let mut a3 = Array::<u32>::new(comptime!(6 * limbs) as usize);
                    let mut e3 = Array::<u32>::new(comptime!(6 * limbs) as usize);
                    powers16(&a, &e, &mut a2, &mut e2, &mut a3, &mut e3, limbs);
                    let mut c0a = Array::<u32>::new(1usize);
                    let mut dupa = Array::<u32>::new(1usize);
                    let mut doma = Array::<u32>::new(2usize);
                    let mut isq = Array::<u32>::new(1usize);
                    let msq = cert_power(
                        &mut a2,
                        &e2,
                        pw,
                        &mut c0a,
                        &mut dupa,
                        &mut doma,
                        0u64,
                        &mut isq,
                        nl2,
                        nl3,
                        s2,
                        cap,
                        base,
                        chunk_digits,
                        chunk_div,
                        false,
                    );
                    if dupa[0] == 0u32 {
                        let at = s_n[0].fetch_add(1u32);
                        let q = 6u32 * at;
                        s_q[q as usize] = i;
                        s_q[(q + 1u32) as usize] = u32::cast_from(msq);
                        s_q[(q + 2u32) as usize] = u32::cast_from(msq >> 32u64);
                        s_q[(q + 3u32) as usize] = c0a[0];
                        s_q[(q + 4u32) as usize] = doma[0];
                        s_q[(q + 5u32) as usize] = doma[1];
                    }
                } else {
"""
# body of the old in-range block between `let mut res` and `if res[0] != 0u32 {`
mid = kern[a1:b0]
mid = mid.replace("""                    chunk_div,
                    hist,
                );""", """                    chunk_div,
                    hist,
                    er,
                );""")
mid = "\n".join(("    " + l if l else l) for l in mid.rstrip("\n").split("\n")) + "\n"
mid = mid.replace("let mask = top_cert(", "mask = top_cert(")
mid += """                    kept = res[0] != 0u32;
                    r1 = res[1];
                    r2 = res[2];
                }
            }
        }
        if comptime!(er == 2) {
            // Phase 2: the queued intervals, one per unit from unit 0, so
            // the planes past the queue's end have nothing to do.
            sync_cube();
            let n = s_n[0].load();
            if UNIT_POS_X < n {
                let q = 6u32 * UNIT_POS_X;
                ie = s_q[q as usize];
                let _ = top_ae(ie, slot, tlay, vs, fb, w, pdiv, &mut a, &mut e, &mut st, limbs);
                let msq = (u64::cast_from(s_q[(q + 2u32) as usize]) << 32u64)
                    | u64::cast_from(s_q[(q + 1u32) as usize]);
                let nl3 = comptime!(3 * limbs);
                let mut a2 = Array::<u32>::new(comptime!(4 * limbs) as usize);
                let mut e2 = Array::<u32>::new(comptime!(4 * limbs) as usize);
                let mut a3 = Array::<u32>::new(comptime!(6 * limbs) as usize);
                let mut e3 = Array::<u32>::new(comptime!(6 * limbs) as usize);
                powers16(&a, &e, &mut a2, &mut e2, &mut a3, &mut e3, limbs);
                let mut c0b = Array::<u32>::new(1usize);
                let mut dupb = Array::<u32>::new(1usize);
                let mut domb = Array::<u32>::new(2usize);
                let mut icu = Array::<u32>::new(1usize);
                let mcu = cert_power(
                    &mut a3,
                    &e3,
                    pw,
                    &mut c0b,
                    &mut dupb,
                    &mut domb,
                    msq,
                    &mut icu,
                    nl3,
                    nl3,
                    s3,
                    cap,
                    base,
                    chunk_digits,
                    chunk_div,
                    false,
                );
                let mut kp = Array::<u32>::new(1usize);
                mask = top_close(
                    msq,
                    mcu,
                    0u32,
                    dupb[0],
                    s_q[(q + 4u32) as usize],
                    s_q[(q + 5u32) as usize],
                    domb[0],
                    domb[1],
                    &mut kp,
                );
                kept = kp[0] != 0u32;
                r1 = s_q[(q + 3u32) as usize];
                r2 = c0b[0];
            }
        }
"""
# emit block: dedent by 8 (was inside two ifs), uses ie, kept, mask, r1, r2, st
emit = emit_text
emit = emit.replace("                if res[0] != 0u32 {\n", "        if kept {\n", 1)
lines = emit.rstrip("\n").split("\n")
# lines[0] is the new `if kept {`; dedent the rest by 8 spaces; drop the 2 closing braces of the old ifs
body = lines[1:]
# old text ends with "                }\n            }\n        }\n" -> body ends with those three closers
assert body[-1].strip() == "}" and body[-2].strip() == "}" and body[-3].strip() == "}", body[-4:]
body = body[:-2]
body = [l[8:] if l.startswith("        ") else l for l in body]
emit = lines[0] + "\n" + "\n".join(body) + "\n"
emit = (emit.replace("let mut floor = res[1];", "let mut floor = r1;")
            .replace("if res[2] < floor {\n                floor = res[2];", "if r2 < floor {\n                floor = r2;")
            .replace("if !a_lt_s && !e_gt_e {", "if st[0] == 0u32 && st[1] == 0u32 {")
            .replace("top_p[(2u32 * g) as usize] = u32::cast_from(p);", "top_p[(2u32 * g) as usize] = st[3];")
            .replace("top_p[(2u32 * g + 1u32) as usize] = u32::cast_from(p >> 32u64);", "top_p[(2u32 * g + 1u32) as usize] = st[4];")
            .replace("a[0] - pw0", "a[0] - st[2]").replace("e[0] - pw0", "e[0] - st[2]")
            .replace("tlay[(5u32 * i + 4u32) as usize] * pdiv + v", "tlay[(5u32 * ie + 4u32) as usize] * pdiv + st[5]")
            .replace("(tlay[(5u32 * i + 2u32) as usize] * pdiv_m1 + v) % m1", "(tlay[(5u32 * ie + 2u32) as usize] * pdiv_m1 + st[5]) % m1")
            .replace("key = tlay[(5u32 * i + 3u32) as usize];", "key = tlay[(5u32 * ie + 3u32) as usize];"))
for bad in ["res[", "a_lt_s", "e_gt_e", "pw0", " v)", "(p)", "p >> 32", "5u32 * i "]:
    assert bad not in emit, (bad, emit)

kern_new = kern[:a0] + new_head + mid + emit + kern[b1:]
s = s[:k0] + kern_new + s[k1:]

# ---------------- top_ae helper, from the original a/e text
ae = ae_text
# ae_text: "if i < ntlay {\n let p0..; let v..; let p..; plo; phi; if p >= plo && p <= phi {\n a/e/clip...\n"
j0 = ae.index("            if p >= plo && p <= phi {\n")
pre = ae[len("        if i < ntlay {\n"):j0]
inner = ae[j0 + len("            if p >= plo && p <= phi {\n"):]
pre = "\n".join(l[4:] if l.startswith("    ") else l for l in pre.rstrip("\n").split("\n")) + "\n"
inner = "\n".join(l[4:] if l.startswith("    ") else l for l in inner.rstrip("\n").split("\n")) + "\n"
inner = inner.replace("let mut a = Array::<u32>::new(limbs as usize);\n", "").replace("let mut e = Array::<u32>::new(limbs as usize);\n", "")
helper = """    /// The interval of top pair (`i`, `slot`): a = p·w and e = a + w − 1,
    /// clipped to [s, e − 1], into `a` and `e`; `st` = [a was below s, e was
    /// above e − 1, the low word of p·w, p (2 words), v]. Returns whether the
    /// prefix block meets the field (`a`, `e` and `st` are set only then).
    #[cube]
    #[allow(clippy::too_many_arguments)]
    fn top_ae(
        i: u32,
        slot: u32,
        tlay: &Array<u32>,
        vs: &Array<u32>,
        fb: &Array<u32>,
        w: u32,
        pdiv: u32,
        a: &mut Array<u32>,
        e: &mut Array<u32>,
        st: &mut Array<u32>,
        #[comptime] limbs: u32,
    ) -> bool {
""" + pre + """        let mut inr = false;
        if p >= plo && p <= phi {
            inr = true;
""" + inner + """            st[0] = select(a_lt_s, 1u32, 0u32);
            st[1] = select(e_gt_e, 1u32, 0u32);
            st[2] = pw0;
            st[3] = u32::cast_from(p);
            st[4] = u32::cast_from(p >> 32u64);
            st[5] = v;
        }
        inr
    }

"""
s = s[:k0] + helper + s[k0:]

# ---------------- launch: er comptime
rep("""                self.key_level,
                self.nb,
                self.hist,
            );""",
"""                self.key_level,
                self.nb,
                self.hist,
                top_er(),
            );""")
rep("""/// Takes (and clears) the summed histograms.""",
"""/// The early-reject mode of the top kernel (`NICE_EXP_TOP_ER`: 0 off, 1
/// skip the cube of a dead square, 2 that and compaction).
pub fn top_er() -> u32 {
    std::env::var("NICE_EXP_TOP_ER")
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(0)
}
/// Takes (and clears) the summed histograms.""")

# ---------------- test kernel: er
rep("""            #[comptime] chunk_div: u32,
            #[comptime] part: u32,
        ) {""",
"""            #[comptime] chunk_div: u32,
            #[comptime] part: u32,
            #[comptime] er: u32,
        ) {""")
rep("""                        chunk_div,
                        false,
                    );
                    out[(o + 24u32) as usize] = res[0];""",
"""                        chunk_div,
                        false,
                        er,
                    );
                    out[(o + 24u32) as usize] = res[0];""")
open(p, "w").write(s)
print("patched")
