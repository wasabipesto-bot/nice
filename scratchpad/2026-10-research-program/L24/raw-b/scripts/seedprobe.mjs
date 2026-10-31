// Browser seed probe: fd_seed_probe_gpu (the finite-difference seed's five
// digit arrays, one n per thread, on the browser's GPU) against BigInt digits,
// word for word, at every base 10-64 with a range: 1024 n at the start,
// middle and end. Run from a harness copy beside hw/ (imports ./hw/lib.mjs).
//   node seedprobe.mjs [--software] [--chromium-arg F]... [--out FILE]
import { writeFile } from "node:fs/promises";
import { adapterRecord, baseRange, launch, modulePage, parseArgs, serve } from "./hw/lib.mjs";

const args = parseArgs();
const site = await serve();
const { browser, flags, version } = await launch({ software: !!args.software, args: args["chromium-arg"] ?? [] });
const page = await modulePage(browser, site.url, "seed");
const adapter = await adapterRecord(page);
console.log(`chromium ${version}; adapter ${adapter.vendor}/${adapter.architecture} fallback=${adapter.fallback}; build ${adapter.build_sha} ${adapter.gpu_build_info}`);

function expected(n, b, offsets, stride) {
    const B = BigInt(b);
    const vals = [n * n, n * n * n, 2n * n + 1n, 3n * n * n + 3n * n + 1n, 6n * n + 6n];
    const rec = new Array(stride).fill(0);
    vals.forEach((v0, k) => {
        let v = v0;
        const top = k + 1 < offsets.length ? offsets[k + 1] : stride;
        for (let j = 0; v > 0n; j++) {
            const w = offsets[k] + (j >> 2);
            if (w >= top) { rec[offsets[k]] = -1; break; } // value outgrew its array: never expected
            rec[w] = (rec[w] + Number(v % B) * 2 ** (8 * (j & 3))) >>> 0;
            v /= B;
        }
    });
    return rec;
}

const out = [];
let bad = 0, windows = 0, numbers = 0;
const t0 = Date.now();
for (let b = 10; b <= 64; b++) {
    const r = baseRange(b);
    if (!r) continue;
    const [rs, re] = r;
    const span = re - rs < 1024n ? re - rs : 1024n;
    const mid = rs + (re - rs) / 2n;
    const starts = [rs, mid < re - span ? mid : re - span, re - span];
    for (const s of starts) {
        const j = JSON.parse(await page.evaluate(({ s, c, b }) => window.__nice.fd_seed_probe_gpu(s, c, b), { s: s.toString(), c: Number(span), b }));
        let wrong = 0, first = null;
        for (let t = 0; t < Number(span); t++) {
            const want = expected(s + BigInt(t), b, j.offsets, j.stride);
            const got = j.words.slice(t * j.stride, (t + 1) * j.stride);
            if (want.some((x, i) => x !== got[i])) {
                wrong++;
                first ??= { n: (s + BigInt(t)).toString(), got, want };
            }
        }
        windows++;
        numbers += Number(span);
        if (wrong) bad++;
        out.push({ base: b, start: s.toString(), count: Number(span), wrong, first });
        console.log(`b${b} [${s}, +${span}): ${wrong ? `${wrong} n WRONG, first ${first.n}` : "exact"}`);
    }
}
const summary = { chromium: version, flags, adapter, windows, numbers, windows_wrong: bad, wall_secs: (Date.now() - t0) / 1000 };
console.log(`seed probe: ${windows} windows, ${numbers} n, ${bad} windows wrong, ${summary.wall_secs.toFixed(1)} s`);
if (args.out) await writeFile(args.out, JSON.stringify({ summary, windows: out }, null, 1) + "\n");
await browser.close();
await site.close();
process.exit(bad ? 1 : 0);
