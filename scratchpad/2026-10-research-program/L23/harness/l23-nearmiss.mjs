// Near-miss parity for the wasm CPU detailed path at bases that take the
// finite-difference loop. Scans with the NEW wasm from the start of each listed
// base's range until it has found some near misses (or hit the cap), then runs
// a 100k window around every near miss found through BOTH builds and requires
// byte-identical results; the scan's own chunks are also re-run through the old
// build up to the first few near misses (so a near miss the new build missed
// would show up as a difference there).
//
// Serves /old/ and /new/ (each a copy of web/search with its own pkg), loads the
// wasm module in a blank page from each, and calls the exported
// process_chunk_wasm(start, end, base) -- the function the page's workers call --
// on a fixed list of windows, chunked the way the worker chunks (100k) plus
// whole-window and odd-chunk variants. Every chunk's raw JSON string comes back
// to node unparsed (so a near miss above 2^53 is compared as exact digits) and
// the two builds' strings must be byte-identical.
//
//   node l23-nearmiss.mjs <out.jsonl>     (old and new sites mounted at /site-old, /site-new)
import { createServer } from "node:http";
import { readFile, writeFile } from "node:fs/promises";
import { createHash } from "node:crypto";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const OUT = process.argv[2] ?? "/out/parity.jsonl";
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


const PLAN = [
    // base, max numbers to scan with the new build, stop after this many near misses
    [40, 1_500_000_000n, 12],
    [42, 600_000_000n, 6],
    [43, 600_000_000n, 6],
    [44, 600_000_000n, 6],
    [45, 600_000_000n, 6],
    [47, 400_000_000n, 4],
    [50, 400_000_000n, 4],
];
// PLAN="40:1500000000:1,49:..." overrides the list above.
if (process.env.PLAN) {
    PLAN.length = 0;
    for (const item of process.env.PLAN.split(",")) {
        const [b, cap, want] = item.split(":");
        PLAN.push([Number(b), BigInt(cap), Number(want)]);
    }
}
const CHUNK = 1_000_000n;

const browser = await chromium.launch({ headless: true });
const version = browser.version();
console.log(`chromium ${version}`);

async function openBuild(tag) {
    const page = await browser.newPage();
    page.on("pageerror", (e) => console.log(`[${tag}] pageerror:`, e.message));
    await page.goto(`${base}/${tag}/blank.html`);
    await page.evaluate(async () => {
        const m = await import("./pkg/nice_wasm_client.js");
        await m.default();
        window.__nice = m;
    });
    return page;
}
const run = (page, start, end, chunk, b) =>
    page.evaluate(
        ({ start, end, chunk, b }) => {
            const res = [];
            let s = BigInt(start);
            const e = BigInt(end), c = BigInt(chunk);
            while (s < e) {
                const ce = s + c > e ? e : s + c;
                res.push(window.__nice.process_chunk_wasm(s.toString(), ce.toString(), b));
                s = ce;
            }
            return res;
        },
        { start: start.toString(), end: end.toString(), chunk: chunk.toString(), b },
    );
const nearOf = (jsons) =>
    jsons.flatMap((j) =>
        JSON.parse(j.replace(/("number":)(\d+)/g, '$1"$2"')).nice_numbers.map((n) => [BigInt(n.number), n.num_uniques]),
    );

const pNew = await openBuild("new");
const pOld = await openBuild("old");
const lines = [];
let bad = 0, checked = 0;
for (const [b, cap, want] of PLAN) {
    const [lo, hi] = baseRange(b);
    let s = lo;
    const found = [];
    const t0 = Date.now();
    while (s < lo + cap && s < hi && found.length < want) {
        const e = s + CHUNK * 20n < hi ? s + CHUNK * 20n : hi;
        const jsNew = await run(pNew, s, e, CHUNK, b);
        const nm = nearOf(jsNew);
        if (nm.length) {
            // The whole 20M stretch through the old build too, chunk for chunk.
            const jsOld = await run(pOld, s, e, CHUNK, b);
            const same = jsOld.length === jsNew.length && jsOld.every((j, i) => j === jsNew[i]);
            if (!same) bad++;
            checked++;
            lines.push(JSON.stringify({ kind: "stretch", base: b, start: s.toString(), end: e.toString(), near_misses: nm.map(([n, u]) => `${n}:${u}`), identical: same }));
            console.log(`b${b} stretch [${s}, ${e}) near=${nm.length} ${same ? "same" : "DIFF"}`);
        }
        found.push(...nm);
        s = e;
    }
    const scanned = s - lo;
    const secs = (Date.now() - t0) / 1000;
    console.log(`b${b}: scanned ${scanned} from range start in ${secs.toFixed(1)}s, ${found.length} near misses`);
    lines.push(JSON.stringify({ kind: "scan", base: b, scanned: scanned.toString(), secs, near_misses: found.map(([n, u]) => `${n}:${u}`) }));
    // A 100k window centred on each near miss, worker chunking, both builds.
    for (const [n, u] of found) {
        const ws = n - 50_000n < lo ? lo : n - 50_000n;
        const we = ws + 100_000n;
        const a = await run(pOld, ws, we, 100_000n, b);
        const c = await run(pNew, ws, we, 100_000n, b);
        const same = a.length === c.length && a.every((j, i) => j === c[i]);
        const nmOld = nearOf(a).map(([x, y]) => `${x}:${y}`);
        if (!same) bad++;
        checked++;
        const h = createHash("sha256");
        for (const j of a) { h.update(j); h.update("\n"); }
        lines.push(JSON.stringify({ kind: "window", base: b, near: `${n}:${u}`, start: ws.toString(), end: we.toString(), sha256_old: h.digest("hex"), near_misses_old: nmOld, identical: same }));
        console.log(`  b${b} ${n} (${u} uniques): window [${ws}, ${we}) ${same ? "same" : "DIFF"}; old build lists ${nmOld.join(" ")}`);
    }
}
await writeFile(OUT, lines.join("\n") + "\n");
console.log(`chromium ${version}: ${checked} comparisons, ${bad} differing`);
await browser.close();
server.close();
process.exit(bad ? 1 : 0);
