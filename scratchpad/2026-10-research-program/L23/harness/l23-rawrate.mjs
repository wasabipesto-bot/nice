// Single-thread wasm rate, old build against new, no page machinery:
// process_chunk_wasm calls over the 1,000,000 numbers at the start of each
// base's range (the window the native fd_timing test times), timed with
// performance.now() inside the page, old and new interleaved by round. Results
// must be equal on every timed call.
//
//   node l23-rawrate.mjs <out.json> [rounds=3] [warmup calls=1] [bases=40,50,60]
import { createServer } from "node:http";
import { readFile, writeFile } from "node:fs/promises";
import { createHash } from "node:crypto";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const OUT = process.argv[2] ?? "/out/rawrate.json";
const ROUNDS = Number(process.argv[3] ?? 3);
const WARM = Number(process.argv[4] ?? 1);
const ROOTS = { old: "/site-old", new: "/site-new" };
const MIME = { ".html": "text/html", ".js": "text/javascript", ".wasm": "application/wasm" };

const server = createServer(async (req, res) => {
    try {
        const path = req.url.split("?")[0];
        const m = /^\/(old|new)(\/.*)$/.exec(path);
        if (!m) throw new Error("no root");
        if (m[2] === "/blank.html") {
            res.writeHead(200, { "Content-Type": "text/html" });
            return res.end("<!doctype html><title>parity</title>");
        }
        const root = ROOTS[m[1]];
        const file = normalize(join(root, m[2]));
        if (!file.startsWith(root)) throw new Error("traversal");
        const body = await readFile(file);
        res.writeHead(200, { "Content-Type": MIME[extname(file)] ?? "application/octet-stream" });
        res.end(body);
    } catch {
        res.writeHead(404);
        res.end("not found");
    }
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const base = `http://127.0.0.1:${server.address().port}`;

// ---- base ranges, as common/src/base_range.rs computes them ----
function iroot(x, r) {
    // floor of the r-th root of x (BigInt), by binary search
    if (x < 2n) return x;
    let lo = 0n, hi = 1n;
    while (hi ** r <= x) hi <<= 1n;
    while (hi - lo > 1n) {
        const mid = (lo + hi) >> 1n;
        if (mid ** r <= x) lo = mid; else hi = mid;
    }
    return lo;
}
function ceilRoot(x, r) {
    const f = iroot(x, BigInt(r));
    return f ** BigInt(r) === x ? f : f + 1n;
}
function baseRange(b) {
    const B = BigInt(b);
    const k = BigInt(Math.floor(b / 5));
    switch (b % 5) {
        case 0: return [ceilRoot(B ** (3n * k - 1n), 3), B ** k];
        case 2: return [B ** k, ceilRoot(B ** (3n * k + 1n), 3)];
        case 3: return [ceilRoot(B ** (3n * k + 1n), 3), ceilRoot(B ** (2n * k + 1n), 2)];
        case 4: return [ceilRoot(B ** (2n * k + 1n), 2), ceilRoot(B ** (3n * k + 2n), 3)];
        default: return null;
    }
}


const browser = await chromium.launch({ headless: true });
const version = browser.version();
// A fresh page per measurement: V8 compiles a wasm function with its baseline
// compiler first and swaps in the optimised code between calls, so the first
// call of a fresh instance runs well behind (measured: 98 then ~58 ns/number
// at base 40 on the new build). WARM untimed full calls, then CALLS timed ones.
const CALLS = 3;
async function measure(tag, lo, hi, b) {
    const page = await browser.newPage();
    await page.goto(`${base}/${tag}/blank.html`);
    const out = await page.evaluate(async ({ s, e, b, warm, calls }) => {
        const m = await import("./pkg/nice_wasm_client.js");
        await m.default();
        for (let i = 0; i < warm; i++) m.process_chunk_wasm(s, e, b);
        const t = [];
        let j = null;
        for (let i = 0; i < calls; i++) {
            const t0 = performance.now();
            j = m.process_chunk_wasm(s, e, b);
            t.push(performance.now() - t0);
        }
        return { t, j };
    }, { s: lo.toString(), e: hi.toString(), b, warm: WARM, calls: CALLS });
    await page.close();
    return out;
}
const med = (v) => [...v].sort((a, b) => a - b)[Math.floor(v.length / 2)];
const rows = [];
for (const b of (process.argv[5] ?? "40,50,60").split(",").map(Number)) {
    const [lo] = baseRange(b);
    const hi = lo + 1_000_000n;
    const ns = { old: [], new: [] };
    for (let r = 0; r < ROUNDS; r++) {
        const a = await measure("old", lo, hi, b);
        const c = await measure("new", lo, hi, b);
        if (a.j !== c.j) throw new Error(`b${b}: results differ`);
        // ms per 1,000,000 numbers == ns per number; the round's value is the
        // median of its timed calls
        ns.old.push(med(a.t));
        ns.new.push(med(c.t));
    }
    const row = { base: b, start: lo.toString(), numbers: 1_000_000, ns_per_number_old: ns.old, ns_per_number_new: ns.new,
        median_old: med(ns.old), median_new: med(ns.new), ratio: med(ns.old) / med(ns.new) };
    rows.push(row);
    const sp = (v) => { const m = med(v); return `${((Math.min(...v) / m - 1) * 100).toFixed(1)}/+${((Math.max(...v) / m - 1) * 100).toFixed(1)} %`; };
    console.log(`b${b}: old [${ns.old.map((x) => x.toFixed(1)).join(" ")}] med ${row.median_old.toFixed(1)} ns (${sp(ns.old)}) | new [${ns.new.map((x) => x.toFixed(1)).join(" ")}] med ${row.median_new.toFixed(1)} ns (${sp(ns.new)}) | ${row.ratio.toFixed(2)}x`);
}
await writeFile(OUT, JSON.stringify({ chromium: version, warm_calls: WARM, timed_calls_per_round: CALLS, rows }, null, 2));
console.log(`chromium ${version}`);
await browser.close();
server.close();
