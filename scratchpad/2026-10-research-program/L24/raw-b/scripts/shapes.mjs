// Browser parity by run shape: process_chunk_gpu_shape(s, e, b, R, batch)
// against process_chunk_wasm, raw JSON, for each window of the chosen
// subset and each shape. R 0 is the per-number kernel alone.
//   node shapes.mjs [--subset ci|hw] [--set a,b] [--shapes 0,1,61,128,1000:333333]
//                   [--software] [--chromium-arg F]... [--out FILE]
import { writeFile } from "node:fs/promises";
import { adapterRecord, ciWindows, describeDiff, hwWindows, launch, modulePage, parseArgs, serve } from "./hw/lib.mjs";

const args = parseArgs();
let windows = args.subset === "hw" ? hwWindows() : ciWindows();
if (args.set) {
    const keep = new Set(String(args.set).split(","));
    windows = windows.filter((w) => keep.has(w.set));
}
const shapes = String(args.shapes ?? "0,1,61,128,1000:333333").split(",").map((x) => {
    const [r, b] = x.split(":");
    return { run: Number(r), batch: Number(b ?? 0) };
});
const site = await serve();
const { browser, flags, version } = await launch({ software: !!args.software, args: args["chromium-arg"] ?? [] });
const page = await modulePage(browser, site.url, "shapes");
const adapter = await adapterRecord(page);
console.log(`chromium ${version}; adapter ${adapter.vendor}/${adapter.architecture} fallback=${adapter.fallback}; ${windows.length} windows x ${shapes.length} shapes`);
const lines = [];
let bad = 0, runs = 0;
const t0 = Date.now();
for (const w of windows) {
    const cpu = await page.evaluate(({ s, e, b }) => window.__nice.process_chunk_wasm(s, e, b), { s: w.start.toString(), e: w.end.toString(), b: w.base });
    for (const sh of shapes) {
        let gpu, err;
        try {
            gpu = await page.evaluate(({ s, e, b, r, z }) => window.__nice.process_chunk_gpu_shape(s, e, b, r, z), { s: w.start.toString(), e: w.end.toString(), b: w.base, r: sh.run, z: sh.batch });
        } catch (x) {
            err = String(x);
        }
        const same = !err && gpu === cpu;
        runs++;
        if (!same) bad++;
        lines.push(JSON.stringify({ key: w.key, base: w.base, start: w.start.toString(), end: w.end.toString(), run: sh.run, batch: sh.batch, identical: same, error: err, diff: !same && gpu ? describeDiff(gpu, cpu) : undefined }));
        if (!same) console.log(`DIFF ${w.key} run ${sh.run} batch ${sh.batch}: ${err ?? describeDiff(gpu, cpu).slice(0, 3).join(" | ")}`);
    }
    console.log(`${w.key}: ${shapes.length} shapes done`);
}
console.log(`shapes: ${windows.length} windows x ${shapes.length} shapes = ${runs} runs, ${bad} differing, ${((Date.now() - t0) / 1000).toFixed(1)} s`);
if (args.out) await writeFile(args.out, lines.join("\n") + "\n");
await browser.close();
await site.close();
process.exit(bad ? 1 : 0);
