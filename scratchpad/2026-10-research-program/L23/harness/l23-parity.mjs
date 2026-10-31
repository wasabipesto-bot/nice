// Browser parity for the wasm CPU detailed path: old wasm (process_range_detailed)
// against new wasm (process_range_detailed_fd), same headless Chromium.
//
// Serves /old/ and /new/ (each a copy of web/search with its own pkg), loads the
// wasm module in a blank page from each, and calls the exported
// process_chunk_wasm(start, end, base) -- the function the page's workers call --
// on a fixed list of windows, chunked the way the worker chunks (100k) plus
// whole-window and odd-chunk variants. Every chunk's raw JSON string comes back
// to node unparsed (so a near miss above 2^53 is compared as exact digits) and
// the two builds' strings must be byte-identical.
//
//   node l23-parity.mjs <out.jsonl>     (old and new sites mounted at /site-old, /site-new)
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

// ---- seeded PRNG (splitmix64) for the random windows ----
let seed = 0x4c32335f70617269n; // fixed
function next64() {
    seed = (seed + 0x9e3779b97f4a7c15n) & 0xffffffffffffffffn;
    let z = seed;
    z = ((z ^ (z >> 30n)) * 0xbf58476d1ce4e5b9n) & 0xffffffffffffffffn;
    z = ((z ^ (z >> 27n)) * 0x94d049bb133111ebn) & 0xffffffffffffffffn;
    return z ^ (z >> 31n);
}
function below(n) {
    return ((next64() << 64n) | next64()) % n;
}

// ---- the window list ----
const windows = [];
const add = (key, b, start, end, chunk) =>
    windows.push({ key, base: b, start: BigInt(start), end: BigInt(end), chunk: BigInt(chunk) });

// The browser benchmark windows (benchmark_plan(); b50_detailed_1t is the first
// half of b50_detailed's window). Worker chunking, whole-window, odd chunk.
const [s40] = baseRange(40);
const [s50] = baseRange(50);
for (const [k, b, s] of [["b40_detailed", 40, s40], ["b50_detailed", 50, s50]]) {
    add(`${k}/chunk100k`, b, s, s + 2_000_000n, 100_000);
    add(`${k}/whole`, b, s, s + 2_000_000n, 2_000_000);
    add(`${k}/chunk7919`, b, s, s + 2_000_000n, 7_919);
}
// The offline-benchmark field the page's "test mode" runs (worker.js).
add("offline_b40_field/chunk100k", 40, 1916284264916n, 1916294264916n, 100_000);
// The e2e's base-49 claim stub: a window holding the near miss
// 20363742218601559 (45 uniques, above 2^53). Base 49 takes the new loop.
add("b49_nearmiss/whole", 49, 20363742218551559n, 20363742218651559n, 100_000);
add("b49_nearmiss/chunk997", 49, 20363742218551559n, 20363742218651559n, 997);
// Every base 40..64 with a range: first and last 100k of the range and four
// seeded random 100k windows (63 is included: it stays on the division loop).
for (let b = 40; b <= 64; b++) {
    const r = baseRange(b);
    if (!r) continue;
    const [lo, hi] = r;
    add(`b${b}/first`, b, lo, lo + 100_000n, 100_000);
    add(`b${b}/last`, b, hi - 100_000n, hi, 100_000);
    for (let i = 0; i < 4; i++) {
        const s = lo + below(hi - lo - 100_000n);
        add(`b${b}/rand${i}`, b, s, s + 100_000n, 100_000);
    }
}
// Small bases, whole range: the division fallback, and near misses.
for (let b = 10; b <= 24; b++) {
    const r = baseRange(b);
    if (!r) continue;
    add(`b${b}/full`, b, r[0], r[1], 100_000);
}

const browser = await chromium.launch({ headless: true });
const version = browser.version();
console.log(`chromium ${version}; ${windows.length} windows`);

async function runAll(tag) {
    const page = await browser.newPage();
    page.on("pageerror", (e) => console.log(`[${tag}] pageerror:`, e.message));
    await page.goto(`${base}/${tag}/blank.html`);
    await page.evaluate(async () => {
        const m = await import("./pkg/nice_wasm_client.js");
        await m.default();
        window.__nice = m;
    });
    const plan = JSON.parse(await page.evaluate(() => window.__nice.benchmark_plan()));
    for (const sc of plan.scenarios) {
        const mine = sc.base === 40 ? s40 : s50;
        if (BigInt(sc.start) !== mine) throw new Error(`plan ${sc.key} starts at ${sc.start}, harness computed ${mine}`);
    }
    console.log(`[${tag}] plan starts match: ${plan.scenarios.map((s) => `${s.key}@${s.start}`).join(", ")}`);
    const out = [];
    for (const w of windows) {
        const t0 = Date.now();
        const chunks = await page.evaluate(
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
            { start: w.start.toString(), end: w.end.toString(), chunk: w.chunk.toString(), b: w.base },
        );
        const secs = (Date.now() - t0) / 1000;
        const h = createHash("sha256");
        let total = 0n;
        const near = [];
        for (const j of chunks) {
            h.update(j);
            h.update("\n");
            const parsed = JSON.parse(j.replace(/("number":)(\d+)/g, '$1"$2"'));
            for (const d of parsed.distribution) total += BigInt(d.count);
            for (const n of parsed.nice_numbers) near.push(`${n.number}:${n.num_uniques}`);
        }
        out.push({
            key: w.key, base: w.base, start: w.start.toString(), end: w.end.toString(),
            chunk: w.chunk.toString(), chunks: chunks.length, sha256: h.digest("hex"),
            counted: total.toString(), near_misses: near, secs,
        });
        if (total !== w.end - w.start) {
            console.log(`[${tag}] ${w.key}: distribution sums to ${total}, window is ${w.end - w.start}`);
        }
    }
    await page.close();
    return out;
}

const old = await runAll("old");
const neu = await runAll("new");
let bad = 0, numbers = 0n, nm = 0;
const lines = [];
for (let i = 0; i < windows.length; i++) {
    const a = old[i], b = neu[i];
    const same = a.sha256 === b.sha256;
    if (!same) bad++;
    numbers += BigInt(a.end) - BigInt(a.start);
    nm += a.near_misses.length;
    lines.push(JSON.stringify({ ...a, secs_old: a.secs, secs_new: b.secs, sha256_new: b.sha256, near_misses_new: b.near_misses, identical: same, secs: undefined }));
    console.log(
        `${same ? "same" : "DIFF"} ${a.key.padEnd(28)} b${a.base} n=${(BigInt(a.end) - BigInt(a.start)).toString().padStart(9)} ` +
            `chunks=${String(a.chunks).padStart(5)} near=${a.near_misses.length} old=${a.secs.toFixed(2)}s new=${b.secs.toFixed(2)}s ${a.sha256.slice(0, 16)}`,
    );
}
await writeFile(OUT, lines.join("\n") + "\n");
console.log(
    `chromium ${version}: ${windows.length} windows, ${numbers} numbers (counting overlaps), ` +
        `${nm} near misses, ${bad} differing`,
);
await browser.close();
server.close();
process.exit(bad ? 1 : 0);
