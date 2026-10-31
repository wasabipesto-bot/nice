// Kernel-only rate by run shape in one build: process_chunk_gpu_shape over
// the plan's GPU windows (2e8 from the b40 and b50 starts), fresh page per
// (round, shape, scenario), --warm untimed + --calls timed, median.
// Shapes interleave within each round. R 0 = per-number kernel.
//   node kshape.mjs [--shapes 0,64,128] [--rounds 3] [--warm 2] [--calls 3] [--out FILE]
import { writeFile } from "node:fs/promises";
import { adapterRecord, launch, modulePage, parseArgs, serve } from "./hw/lib.mjs";

const args = parseArgs();
const shapes = String(args.shapes ?? "0,64,128").split(",").map(Number);
const ROUNDS = Number(args.rounds ?? 3), WARM = Number(args.warm ?? 2), CALLS = Number(args.calls ?? 3);
const site = await serve();
const { browser, flags, version } = await launch({ args: args["chromium-arg"] ?? [] });
const probe = await modulePage(browser, site.url, "probe");
const adapter = await adapterRecord(probe);
const plan = JSON.parse(await probe.evaluate(() => window.__nice.benchmark_plan()));
await probe.close();
const defs = plan.scenarios.filter((s) => BigInt(s.window_gpu) > 0n);
console.log(`chromium ${version}; adapter ${adapter.vendor}/${adapter.architecture}; shapes ${shapes.join(",")}; ${defs.map((d) => d.key).join(", ")}`);
const med = (v) => [...v].sort((a, b) => a - b)[Math.floor(v.length / 2)];
const runs = [];
for (let r = 1; r <= ROUNDS; r++) {
    for (const def of defs) {
        for (const R of shapes) {
            const page = await modulePage(browser, site.url, `k${R}`);
            const s = BigInt(def.start), size = BigInt(def.window_gpu);
            const secs = await page.evaluate(async ({ s, e, b, R, n }) => {
                const t = [];
                for (let i = 0; i < n; i++) {
                    const t0 = performance.now();
                    await window.__nice.process_chunk_gpu_shape(s, e, b, R, 0);
                    t.push((performance.now() - t0) / 1000);
                }
                return t;
            }, { s: s.toString(), e: (s + size).toString(), b: def.base, R, n: WARM + CALLS });
            await page.close();
            const timed = secs.slice(WARM);
            const rate = Number(size) / med(timed);
            runs.push({ round: r, key: def.key, run_len: R, untimed: secs.slice(0, WARM), timed, rate });
            console.log(`round ${r} ${def.key} R=${R}: ${rate.toExponential(3)} n/s (timed ${timed.map((x) => x.toFixed(4)).join(" ")}; untimed ${secs.slice(0, WARM).map((x) => x.toFixed(3)).join(" ")})`);
        }
    }
}
if (args.out) await writeFile(args.out, JSON.stringify({ chromium: version, flags, adapter, runs }, null, 1) + "\n");
await browser.close();
await site.close();
