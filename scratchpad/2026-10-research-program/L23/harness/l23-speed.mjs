// Browser benchmark suite, old wasm against new wasm, in one headless Chromium:
// the real page (web/search) in "Benchmark suite (NiceMark)" mode on the CPU
// backend, runs interleaved old new old new ... Every request that is not to
// the local server is answered here (the suite pings the API) or aborted, so
// nothing leaves the box. The suite's own report object (logged to the
// console as "benchmark report:") is captured whole.
//
//   node l23-speed.mjs <out.json> [rounds] [budget_secs]
import { createServer } from "node:http";
import { readFile, writeFile } from "node:fs/promises";
import { createHash } from "node:crypto";
import { extname, join, normalize } from "node:path";
import { chromium } from "playwright";

const OUT = process.argv[2] ?? "/out/speed.json";
const ROUNDS = Number(process.argv[3] ?? 3);
const BUDGET = String(process.argv[4] ?? 60);
const ROOTS = { old: "/site-old", new: "/site-new" };
const MIME = { ".html": "text/html", ".js": "text/javascript", ".mjs": "text/javascript", ".wasm": "application/wasm", ".css": "text/css", ".json": "application/json" };

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
        const file = normalize(join(root, m[2] === "/" ? "/index.html" : m[2]));
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


const browser = await chromium.launch({ headless: true });
const version = browser.version();
console.log(`chromium ${version}; ${ROUNDS} rounds, budget ${BUDGET}s`);

async function suite(tag) {
    const page = await browser.newPage();
    let report = null;
    page.on("console", async (m) => {
        if (m.text().startsWith("benchmark report:")) {
            try {
                report = await m.args()[1].jsonValue();
            } catch (e) {
                console.log(`[${tag}] could not read report: ${e}`);
            }
        }
    });
    page.on("pageerror", (e) => console.log(`[${tag}] pageerror:`, e.message));
    await page.route("**/*", async (route) => {
        const u = route.request().url();
        if (u.startsWith(base)) return route.continue();
        if (u.includes("api.nicenumbers.net") && u.includes("/ping")) {
            return route.fulfill({ status: 200, headers: { "Access-Control-Allow-Origin": "*" }, body: "pong" });
        }
        return route.abort();
    });
    await page.goto(`${base}/${tag}/`);
    await page.waitForSelector("#startBtn:not([disabled])", { timeout: 120000 });
    await page.waitForFunction(
        () => !document.getElementById("backendHelp").textContent.includes("Checking"),
        undefined,
        { timeout: 120000 },
    );
    await page.selectOption("#testMode", "suite");
    await page.selectOption("#backendSelect", "cpu");
    await page.selectOption("#benchBudget", BUDGET);
    const t0 = Date.now();
    await page.click("#startBtn");
    await page.waitForFunction(
        () => /suite complete/i.test(document.getElementById("status").textContent),
        undefined,
        { timeout: 30 * 60 * 1000 },
    );
    for (let i = 0; i < 50 && !report; i++) await new Promise((r) => setTimeout(r, 100));
    const results = await page.textContent("#results");
    await page.close();
    return { tag, wall_secs: (Date.now() - t0) / 1000, report, results };
}

const runs = [];
for (let r = 0; r < ROUNDS; r++) {
    for (const tag of ["old", "new"]) {
        const out = await suite(tag);
        out.round = r + 1;
        runs.push(out);
        const sc = out.report?.scenarios ?? [];
        console.log(
            `round ${r + 1} ${tag}: ` +
                sc.map((s) => `${s.key}=${(s.rate / 1e6).toFixed(3)}M/s (${s.repetitions}x${Number(s.window_size) / 1e6}M, ${s.threads}t)`).join("  ") +
                `  score=${out.report?.score?.toFixed(1)}  build=${out.report?.build_sha}`,
        );
    }
}
await writeFile(OUT, JSON.stringify({ chromium: version, budget_secs: Number(BUDGET), runs }, null, 2));
await browser.close();
server.close();
