// Diagnostic: the same 1M-number process_chunk_wasm call repeated N times in
// one page, each timed with performance.now(), to see whether the per-call
// time drifts (V8 tiering) or scatters (noise). node l23-series.mjs <tag> <base> <n> [fresh]
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";
const [tag, b, n] = [process.argv[2], Number(process.argv[3]), Number(process.argv[4])];
const STARTS = { 40: 1916284264916n, 50: 26507984537059635n, 60: 0n };
const MIME = { ".html": "text/html", ".js": "text/javascript", ".wasm": "application/wasm" };
const server = createServer(async (req, res) => {
    try {
        const p = req.url.split("?")[0];
        if (p === "/blank.html") { res.writeHead(200, { "Content-Type": "text/html" }); return res.end("<!doctype html>"); }
        const f = normalize(join(`/site-${tag}`, p));
        res.writeHead(200, { "Content-Type": MIME[extname(f)] ?? "application/octet-stream" });
        res.end(await readFile(f));
    } catch { res.writeHead(404); res.end(); }
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();
await page.goto(`http://127.0.0.1:${server.address().port}/blank.html`);
const out = await page.evaluate(async ({ s, b, n }) => {
    const m = await import("./pkg/nice_wasm_client.js");
    await m.default();
    const lo = BigInt(s), hi = lo + 1000000n;
    const t = [];
    for (let i = 0; i < n; i++) {
        const t0 = performance.now();
        m.process_chunk_wasm(lo.toString(), hi.toString(), b);
        t.push(+(performance.now() - t0).toFixed(1));
    }
    return t;
}, { s: STARTS[b].toString(), b, n });
console.log(`${tag} b${b} ns/number per call: ${out.join(" ")}`);
await browser.close();
server.close();
