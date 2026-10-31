// Browser parity: the GPU path (process_chunk_gpu: WGSL through the
// browser's compiler onto the real device) against the wasm CPU path
// (process_chunk_wasm), one window at a time, raw JSON compared byte for
// byte. Nothing is parsed before the comparison, so near misses above 2^53
// are compared as exact digits.
//
//   node parity.mjs [--subset hw|ci] [--extra] [--random N [--random-width W]]
//                   [--set NAME[,NAME]]
//                   [--chromium-arg FLAG]... [--software] [--expect-vendor V]
//                   [--timeout-secs 600] [--out parity.jsonl]
//
// --subset hw (default) is the L24 proposal's §3.3 list; ci is its CI
// subset. --extra adds the two 2e8 benchmark windows whole; --random N adds N
// seeded W-number windows (default 1e6) at every base 10–64. --set keeps only
// the named sets (full, sme, m4fail, gain, boundary, partial, nearmiss,
// fallback, bench, random, ci). Each window's record (both SHA-256s, timings, near
// misses, and on a difference both raw strings and a readable diff) is one
// JSONL line; the adapter record is the first. Exit 1 on any difference or
// error.
import { createHash } from "node:crypto";
import { writeFile } from "node:fs/promises";
import { adapterRecord, baseRange, ciWindows, describeDiff, hwWindows, launch, modulePage, parseArgs, parseExact, serve } from "./lib.mjs";

const args = parseArgs();
const software = !!args.software;
const timeoutMs = Number(args["timeout-secs"] ?? 600) * 1000;
let windows =
    args.subset === "ci"
        ? ciWindows()
        : hwWindows({
              extra: !!args.extra,
              randomPerBase: Number(args.random ?? 0),
              randomWidth: BigInt(args["random-width"] ?? 1_000_000),
          });
if (args.set) {
    const keep = new Set(String(args.set).split(","));
    windows = windows.filter((w) => keep.has(w.set));
}

const site = await serve();
const { browser, flags, version } = await launch({ software, args: args["chromium-arg"] ?? [] });
console.log(`chromium ${version}; flags: ${flags.length ? flags.join(" ") : "(none)"}; ${windows.length} windows`);

let page = await modulePage(browser, site.url, "parity");
const adapter = await adapterRecord(page);
console.log(
    `adapter: vendor=${JSON.stringify(adapter.vendor)} architecture=${JSON.stringify(adapter.architecture)} ` +
        `fallback=${adapter.fallback} gpu_init=${JSON.stringify(adapter.gpu_init_name ?? adapter.gpu_init_error)} build=${adapter.build_sha}`,
);
if (!adapter.adapter || adapter.gpu_init_error) {
    console.log("no usable adapter; nothing to compare");
    process.exit(2);
}
if (args["expect-vendor"] && adapter.vendor !== args["expect-vendor"]) {
    console.log(`adapter vendor ${adapter.vendor}, expected ${args["expect-vendor"]}`);
    process.exit(1);
}

// The plan's starts must agree with the BigInt ranges the windows use.
const plan = JSON.parse(await page.evaluate(() => window.__nice.benchmark_plan()));
for (const s of plan.scenarios) {
    if (BigInt(s.start) !== baseRange(s.base)[0]) {
        throw new Error(`plan ${s.key} starts at ${s.start}; baseRange(${s.base}) says ${baseRange(s.base)[0]}`);
    }
}

function withTimeout(p, ms, what) {
    let t;
    return Promise.race([
        p.finally(() => clearTimeout(t)),
        new Promise((_, rej) => {
            t = setTimeout(() => rej(new Error(`${what}: timed out after ${ms / 1000}s`)), ms);
        }),
    ]);
}

const sha = (s) => createHash("sha256").update(s ?? "").digest("hex");
const lines = [JSON.stringify({ kind: "header", chromium: version, flags, software, adapter, windows: windows.length, when: new Date().toISOString() })];
let bad = 0;
let numbers = 0n;
let misses = 0;
const t0all = Date.now();
for (const w of windows) {
    const n = w.end - w.start;
    let r;
    try {
        r = await withTimeout(
            page.evaluate(
                async ({ s, e, b }) => {
                    const out = {};
                    let t = performance.now();
                    try {
                        out.gpu = await window.__nice.process_chunk_gpu(s, e, b);
                    } catch (err) {
                        out.gpu_error = String(err);
                    }
                    out.gpu_secs = (performance.now() - t) / 1000;
                    t = performance.now();
                    try {
                        out.cpu = window.__nice.process_chunk_wasm(s, e, b);
                    } catch (err) {
                        out.cpu_error = String(err);
                    }
                    out.cpu_secs = (performance.now() - t) / 1000;
                    return out;
                },
                { s: w.start.toString(), e: w.end.toString(), b: w.base },
            ),
            timeoutMs,
            w.key,
        );
    } catch (err) {
        // A hung or lost device: record it and carry on in a fresh page.
        r = { gpu_error: String(err) };
        await page.close().catch(() => {});
        page = await modulePage(browser, site.url, "parity");
    }
    const identical = !r.gpu_error && !r.cpu_error && r.gpu === r.cpu;
    let near = [];
    let counted = null;
    if (r.cpu) {
        const p = parseExact(r.cpu);
        near = p.nice_numbers.map((x) => `${x.number}:${x.num_uniques}`);
        counted = p.distribution.reduce((a, d) => a + BigInt(d.count), 0n);
    }
    const rec = {
        kind: "window",
        set: w.set,
        key: w.key,
        base: w.base,
        start: w.start.toString(),
        end: w.end.toString(),
        numbers: n.toString(),
        identical,
        sha256_gpu: r.gpu ? sha(r.gpu) : null,
        sha256_cpu: r.cpu ? sha(r.cpu) : null,
        bytes: r.cpu?.length ?? null,
        near_misses: near,
        cpu_counted: counted?.toString() ?? null,
        gpu_secs: r.gpu_secs ?? null,
        cpu_secs: r.cpu_secs ?? null,
    };
    if (r.gpu_error) rec.gpu_error = r.gpu_error;
    if (r.cpu_error) rec.cpu_error = r.cpu_error;
    if (!identical) {
        bad++;
        rec.gpu_json = r.gpu ?? null;
        rec.cpu_json = r.cpu ?? null;
        if (r.gpu && r.cpu) rec.diff = describeDiff(r.gpu, r.cpu);
    }
    if (counted !== null && counted !== n) {
        rec.conservation = `cpu distribution sums to ${counted}, window is ${n}`;
    }
    lines.push(JSON.stringify(rec));
    numbers += n;
    misses += near.length;
    console.log(
        `${identical ? "same" : "DIFF"} ${w.set.padEnd(8)} ${w.key.padEnd(34)} n=${n.toString().padStart(10)} ` +
            `near=${String(near.length).padStart(2)} gpu=${(r.gpu_secs ?? NaN).toFixed(3)}s cpu=${(r.cpu_secs ?? NaN).toFixed(3)}s` +
            (identical ? "" : `  ${rec.gpu_error ?? rec.cpu_error ?? rec.diff?.slice(0, 3).join(" | ")}`),
    );
}
const summary = {
    kind: "summary",
    chromium: version,
    flags,
    windows: windows.length,
    numbers: numbers.toString(),
    near_misses: misses,
    differing: bad,
    wall_secs: (Date.now() - t0all) / 1000,
};
lines.push(JSON.stringify(summary));
if (args.out) await writeFile(args.out, lines.join("\n") + "\n");
console.log(
    `chromium ${version} on ${adapter.vendor}/${adapter.architecture}: ${windows.length} windows, ${numbers} numbers, ` +
        `${misses} near misses, ${bad} differing, ${summary.wall_secs.toFixed(1)} s`,
);
await browser.close();
await site.close();
process.exit(bad ? 1 : 0);
