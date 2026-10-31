// Shared pieces of the hardware browser harness (adapter check, parity,
// benchmark): the static server, the Chromium launch, the adapter record and
// its assertion, base ranges in BigInt, and the parity window lists.
//
// The harness ships to a GPU machine as this directory plus a built copy of
// web/search (with pkg/ and vendor/), so nothing here reaches outside it.
// Staging on a Mac with no Node (what worked on mayalaran, 2026-10-31), all
// inside one directory $D:
//   curl nodejs.org/dist/v24.14.1/node-v24.14.1-darwin-arm64.tar.gz, unpack to $D/node
//   export PATH=$D/node/bin:$PATH npm_config_cache=$D/npm-cache \
//          PLAYWRIGHT_BROWSERS_PATH=$D/pw-browsers TMPDIR=$D/tmp/
//   (in $D/harness) npm i --no-save playwright@1.62.0   # CI's version
//   npx playwright install --no-shell chromium          # 179 MiB, ~40 s
//   copy this directory to $D/harness/hw and the built site to $D/site
//   NICE_E2E_ROOT=$D/site node $D/harness/hw/adapter.mjs --expect-vendor apple
// TMPDIR keeps Chromium's throwaway profile inside $D too.
//
//   adapter.mjs  adapter record + hardware (or --software) assertion
//   parity.mjs   process_chunk_gpu vs process_chunk_wasm, raw JSON, per window
//   bench.mjs    kernel-only and real-page GPU suite rates
//   serve.mjs    the static server alone, for opening the page by hand
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

// ---------------------------------------------------------------------------
// Arguments
// ---------------------------------------------------------------------------

/** `--name value` / `--name=value` / bare `--flag`; repeated names collect. */
export function parseArgs(argv = process.argv.slice(2)) {
    const out = { _: [] };
    for (let i = 0; i < argv.length; i++) {
        const a = argv[i];
        if (!a.startsWith("--")) {
            out._.push(a);
            continue;
        }
        let [k, v] = a.slice(2).split(/=(.*)/s, 2);
        if (v === undefined) {
            // A value follows unless the next token is another flag. Chromium
            // flags start with "--" too, so --chromium-arg always takes the
            // `=` form or the next token verbatim.
            const next = argv[i + 1];
            if (k === "chromium-arg" || (next !== undefined && !next.startsWith("--"))) {
                v = next;
                i++;
            } else {
                v = true;
            }
        }
        if (k === "chromium-arg") (out[k] ??= []).push(v);
        else out[k] = v;
    }
    return out;
}

// ---------------------------------------------------------------------------
// Static server: the site root plus a blank page for module-level calls
// ---------------------------------------------------------------------------

const MIME = {
    ".html": "text/html",
    ".js": "text/javascript",
    ".mjs": "text/javascript",
    ".wasm": "application/wasm",
    ".css": "text/css",
    ".json": "application/json",
};

/** The site served: NICE_E2E_ROOT, else the repo's web/search. */
export function siteRoot() {
    return process.env.NICE_E2E_ROOT
        ? normalize(process.env.NICE_E2E_ROOT)
        : normalize(join(fileURLToPath(import.meta.url), "../../../../web/search"));
}

/**
 * Serve `root` on 127.0.0.1 (a secure context, so WebGPU is exposed).
 * `/blank.html` is an empty page at the site's origin, from which the
 * harness imports `./pkg/nice_wasm_client.js` and calls its exports
 * directly. Resolves to `{ url, close }`.
 */
export async function serve(root = siteRoot(), port = 0) {
    const server = createServer(async (req, res) => {
        try {
            const path = req.url === "/" ? "/index.html" : req.url.split("?")[0];
            if (path === "/blank.html") {
                res.writeHead(200, { "Content-Type": "text/html" });
                return res.end("<!doctype html><meta charset=utf-8><title>nice hw harness</title>");
            }
            const file = normalize(join(root, path));
            if (!file.startsWith(root)) throw new Error("traversal");
            const body = await readFile(file);
            res.writeHead(200, { "Content-Type": MIME[extname(file)] ?? "application/octet-stream" });
            res.end(body);
        } catch {
            res.writeHead(404);
            res.end("not found");
        }
    });
    await new Promise((r) => server.listen(port, "127.0.0.1", r));
    return {
        url: `http://127.0.0.1:${server.address().port}/`,
        close: () => new Promise((r) => server.close(r)),
    };
}

// ---------------------------------------------------------------------------
// Browser
// ---------------------------------------------------------------------------

/**
 * Hardware mode: full Chromium in new-headless mode (`channel: "chromium"`;
 * the default chrome-headless-shell has no GPU), with no flags unless the
 * caller passes dev-only ones. Software mode pins SwiftShader as CI does.
 */
export async function launch({ software = false, args = [] } = {}) {
    const flags = software
        ? ["--enable-unsafe-webgpu", "--use-webgpu-adapter=swiftshader", "--enable-features=Vulkan", ...args]
        : args;
    const browser = await chromium.launch({ headless: true, channel: "chromium", args: flags });
    return { browser, flags, version: browser.version() };
}

/** A blank page at the site origin with the wasm module loaded as `window.__nice`. */
export async function modulePage(browser, url, tag = "page") {
    const page = await browser.newPage();
    page.on("pageerror", (e) => console.log(`[${tag}] pageerror: ${e.message}`));
    page.on("console", (m) => {
        if (m.type() === "error") console.log(`[${tag}] console error: ${m.text()}`);
    });
    await page.goto(`${url}blank.html`);
    await page.evaluate(async () => {
        const m = await import("./pkg/nice_wasm_client.js");
        await m.default();
        window.__nice = m;
    });
    return page;
}

/**
 * The adapter as the page sees it (main thread), the name the wasm reports
 * from `gpu_init()`, and the build's GPU sizes. Never throws: a missing
 * adapter is a record with `adapter: false`.
 */
export async function adapterRecord(page) {
    return page.evaluate(async () => {
        const rec = { navigator_gpu: !!navigator.gpu };
        try {
            const a = await navigator.gpu?.requestAdapter();
            rec.adapter = !!a;
            if (a) {
                const i = a.info ?? (await a.requestAdapterInfo?.());
                rec.vendor = i?.vendor;
                rec.architecture = i?.architecture;
                rec.device = i?.device;
                rec.description = i?.description;
                rec.subgroupMinSize = i?.subgroupMinSize;
                rec.subgroupMaxSize = i?.subgroupMaxSize;
                rec.fallback = i?.isFallbackAdapter ?? a.isFallbackAdapter;
                rec.features = [...a.features].sort();
                rec.limits = {
                    maxComputeWorkgroupSizeX: a.limits.maxComputeWorkgroupSizeX,
                    maxComputeInvocationsPerWorkgroup: a.limits.maxComputeInvocationsPerWorkgroup,
                    maxComputeWorkgroupsPerDimension: a.limits.maxComputeWorkgroupsPerDimension,
                    maxStorageBufferBindingSize: a.limits.maxStorageBufferBindingSize,
                    maxBufferSize: a.limits.maxBufferSize,
                };
            }
        } catch (e) {
            rec.error = String(e);
        }
        try {
            rec.gpu_build_info = window.__nice.gpu_build_info();
            rec.build_sha = window.__nice.build_sha();
            rec.client_version = window.__nice.client_version();
        } catch (e) {
            rec.build_error = String(e);
        }
        if (rec.adapter) {
            try {
                rec.gpu_init_name = await window.__nice.gpu_init();
            } catch (e) {
                rec.gpu_init_error = String(e);
            }
        }
        rec.user_agent = navigator.userAgent;
        return rec;
    });
}

const SOFTWARE = /swiftshader|llvmpipe|lavapipe|software|basic render/i;

/**
 * The hardware assertion: problems as strings (empty = pass). `rate` is the
 * warm 2e8-number b40 call's numbers/s; `minRate` 1e8 (SwiftShader ~1e6).
 */
export function hardwareProblems(rec, { expectVendor, rate, minRate = 1e8 }) {
    const p = [];
    if (!rec.adapter) p.push("no adapter returned");
    if (rec.fallback === true) p.push("adapter is a fallback adapter");
    for (const k of ["vendor", "architecture", "device", "description", "gpu_init_name"]) {
        if (typeof rec[k] === "string" && SOFTWARE.test(rec[k])) p.push(`${k} "${rec[k]}" names a software adapter`);
    }
    if (expectVendor && rec.vendor !== expectVendor) p.push(`vendor "${rec.vendor}", expected "${expectVendor}"`);
    if (!(rate > minRate)) p.push(`warm b40 rate ${rate?.toExponential(3)} n/s is not above ${minRate.toExponential(0)}`);
    return p;
}

/** The CI inverse: the pinned adapter must be the software one. */
export function softwareProblems(rec) {
    const p = [];
    if (!rec.adapter) p.push("no adapter returned");
    const named = ["vendor", "architecture", "description"].some((k) => SOFTWARE.test(rec[k] ?? ""));
    if (!named && rec.fallback !== true) p.push("adapter is neither named software nor a fallback");
    return p;
}

/**
 * Time `process_chunk_gpu` over [start, start+size) at `base`: `warm`
 * untimed calls, then `calls` timed ones, in-page with performance.now().
 * Returns per-call seconds and the last JSON.
 */
export async function timeGpu(page, { base, start, size, warm = 1, calls = 1 }) {
    return page.evaluate(
        async ({ base, s, e, warm, calls }) => {
            const t = [];
            let j = null;
            for (let i = 0; i < warm + calls; i++) {
                const t0 = performance.now();
                j = await window.__nice.process_chunk_gpu(s, e, base);
                const dt = (performance.now() - t0) / 1000;
                if (i >= warm) t.push(dt);
                else t.push(-dt); // negative = untimed warm-up, kept for the compile cost
            }
            return { secs: t, json: j };
        },
        { base, s: start.toString(), e: (start + size).toString(), warm, calls },
    );
}

// ---------------------------------------------------------------------------
// Base ranges (common/src/base_range.rs), BigInt
// ---------------------------------------------------------------------------

export function iroot(x, r) {
    if (x < 2n) return x;
    let lo = 0n,
        hi = 1n;
    while (hi ** r <= x) hi <<= 1n;
    while (hi - lo > 1n) {
        const mid = (lo + hi) >> 1n;
        if (mid ** r <= x) lo = mid;
        else hi = mid;
    }
    return lo;
}
function ceilRoot(x, r) {
    const f = iroot(x, BigInt(r));
    return f ** BigInt(r) === x ? f : f + 1n;
}
/** `[start, end)` of the base's range, or null (b ≡ 1 mod 5). */
export function baseRange(b) {
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

const U128_MAX = (1n << 128n) - 1n;

/**
 * Points inside the range where an FD addend gains a digit, as the native
 * `windows()` test computes them: 2n+1 ≥ b^k (dS), 6n+6 ≥ b^k (ddC) and
 * 3n²+3n+1 ≥ b^k (dC), kept where `g > rs + width && g + width < re`.
 */
export function gainPoints(b, width) {
    const [rs, re] = baseRange(b);
    const B = BigInt(b);
    const out = [];
    for (let k = 1n; k <= 30n; k++) {
        const bk = B ** k;
        if (bk > U128_MAX) break;
        const sat = (x, y) => (x > y ? x - y : 0n);
        const ceilDiv = (x, y) => (x + y - 1n) / y;
        const gds = ceilDiv(sat(bk, 1n), 2n);
        const gddc = ceilDiv(sat(bk, 6n), 6n);
        let lo = 0n,
            hi = 1n << 64n;
        while (lo < hi) {
            const mid = (lo + hi) >> 1n;
            const v = 3n * mid * mid + 3n * mid + 1n;
            if (v > U128_MAX || v >= bk) hi = mid;
            else lo = mid + 1n;
        }
        for (const [name, g] of [["dS", gds], ["ddC", gddc], ["dC", lo]]) {
            if (g > rs + width && g + width < re) out.push({ name, k: Number(k), g });
        }
    }
    return out;
}

// ---------------------------------------------------------------------------
// Parity windows (L24 proposal §3.3)
// ---------------------------------------------------------------------------

// splitmix64, fixed seed, for the extra windows on the M4 failure bases.
function rng(seed) {
    let s = seed;
    const next64 = () => {
        s = (s + 0x9e3779b97f4a7c15n) & 0xffffffffffffffffn;
        let z = s;
        z = ((z ^ (z >> 30n)) * 0xbf58476d1ce4e5b9n) & 0xffffffffffffffffn;
        z = ((z ^ (z >> 27n)) * 0x94d049bb133111ebn) & 0xffffffffffffffffn;
        return z ^ (z >> 31n);
    };
    return (n) => ((next64() << 64n) | next64()) % n;
}

export const M4_FAILURE_BASES = [23, 25, 27, 28, 29, 30, 49, 50, 52, 53, 54, 55];
export const PARTIAL_LENGTHS = [1n, 2n, 61n, 127n, 128n, 129n, 255n, 257n, 100001n];

/**
 * The `--hw` parity set. Each window: { set, key, base, start, end }.
 * `extra` adds the two 2e8 benchmark windows whole (b40/b50 starts);
 * `randomPerBase` adds that many seeded `randomWidth` windows per base 10–64.
 */
export function hwWindows({ extra = false, randomPerBase = 0, randomWidth = 1_000_000n } = {}) {
    const w = [];
    const add = (set, key, base, start, end) => w.push({ set, key, base, start: BigInt(start), end: BigInt(end) });
    const W = 100_000n;
    // Bases 10–25 in full.
    for (let b = 10; b <= 25; b++) {
        const r = baseRange(b);
        if (r) add("full", `b${b}/full`, b, r[0], r[1]);
    }
    // Bases 27–64: start, middle, end.
    for (let b = 27; b <= 64; b++) {
        const r = baseRange(b);
        if (!r) continue;
        const [rs, re] = r;
        const mid = rs + (re - rs) / 2n;
        add("sme", `b${b}/start`, b, rs, rs + W);
        add("sme", `b${b}/middle`, b, mid - W / 2n, mid + W / 2n);
        add("sme", `b${b}/end`, b, re - W, re);
    }
    // M4 failure bases above 25: four seeded windows each.
    const below = rng(0x4c32345f6d346677n);
    for (const b of M4_FAILURE_BASES.filter((b) => b > 25)) {
        const [rs, re] = baseRange(b);
        for (let i = 0; i < 4; i++) {
            const s = rs + below(re - rs - W);
            add("m4fail", `b${b}/seeded${i}`, b, s, s + W);
        }
    }
    // Digit-gain points, 1e5 centred, bases 27–64 (10–25 are covered whole).
    for (let b = 27; b <= 64; b++) {
        if (!baseRange(b)) continue;
        for (const { name, k, g } of gainPoints(b, W)) {
            add("gain", `b${b}/${name}-k${k}@${g}`, b, g - W / 2n, g + W / 2n);
        }
    }
    // Kernel boundary: straddling the range start (b40, b50) and end (b40); b10 past its end.
    for (const b of [40, 50]) {
        const [rs] = baseRange(b);
        add("boundary", `b${b}/straddle-start`, b, rs - 50_000n, rs + 50_000n);
    }
    {
        const [, re] = baseRange(40);
        add("boundary", "b40/straddle-end", 40, re - 50_000n, re + 50_000n);
        add("boundary", "b10/[47,200)", 10, 47n, 200n);
    }
    // Partial runs at the b40 and b57 starts.
    for (const b of [40, 57]) {
        const [rs] = baseRange(b);
        for (const len of PARTIAL_LENGTHS) add("partial", `b${b}/len${len}`, b, rs, rs + len);
    }
    // Near-miss windows.
    add("nearmiss", "b49/nearmiss", 49, 20363742218551559n, 20363742218651559n);
    add("nearmiss", "b40/nearmiss", 40, 1917398732423n - 50_000n, 1917398732423n + 50_000n);
    // Above the FD bases: today's kernel everywhere, (b)'s division fallback.
    for (const b of [80, 97]) {
        const [rs] = baseRange(b);
        add("fallback", `b${b}/start`, b, rs, rs + 50_000n);
    }
    // Optional sweep: seeded windows at every base 10–64 with a range.
    if (randomPerBase > 0) {
        const pick = rng(0x4c32345f72616e64n);
        for (let b = 10; b <= 64; b++) {
            const r = baseRange(b);
            if (!r) continue;
            const [rs, re] = r;
            const width = re - rs > randomWidth ? randomWidth : re - rs;
            for (let i = 0; i < randomPerBase; i++) {
                const s = rs + (re - rs > width ? pick(re - rs - width) : 0n);
                add("random", `b${b}/random${i}`, b, s, s + width);
            }
        }
    }
    if (extra) {
        for (const b of [40, 50]) {
            const [rs] = baseRange(b);
            add("bench", `b${b}/bench-2e8`, b, rs, rs + 200_000_000n);
        }
    }
    return w;
}

/** The CI subset (§3.3), for the SwiftShader run. */
export function ciWindows() {
    const all = hwWindows();
    const keep = (k) => all.find((w) => w.key === k);
    const out = [keep("b10/[47,200)"), keep("b23/full")];
    const [rs40] = baseRange(40);
    out.push({ set: "ci", key: "b40/start", base: 40, start: rs40, end: rs40 + 100_000n });
    out.push(keep("b40/straddle-start"));
    out.push(all.find((w) => w.set === "gain" && w.base === 40 && w.key.includes("/dS-")));
    for (const len of [1n, 61n, 129n]) out.push(keep(`b40/len${len}`));
    out.push(keep("b49/nearmiss"));
    out.push(all.find((w) => w.set === "gain" && w.base === 50 && w.key.includes("/dC-")));
    for (const b of [57, 64, 80]) {
        const [rs] = baseRange(b);
        out.push({ set: "ci", key: `b${b}/start-2e4`, base: b, start: rs, end: rs + 20_000n });
    }
    return out.filter(Boolean);
}

/** JSON with every integer quoted, so values above 2^53 parse exactly. */
export function parseExact(json) {
    return JSON.parse(json.replace(/([:\[,]\s*)(\d+)(?=\s*[,}\]])/g, '$1"$2"'));
}

/** What differs between two raw results, as readable lines. */
export function describeDiff(gpuJson, cpuJson) {
    const lines = [];
    let g, c;
    try {
        g = parseExact(gpuJson);
        c = parseExact(cpuJson);
    } catch (e) {
        return [`unparseable: ${e}`];
    }
    const gd = new Map((g.distribution ?? []).map((d) => [d.num_uniques, d.count]));
    const cd = new Map((c.distribution ?? []).map((d) => [d.num_uniques, d.count]));
    for (const k of new Set([...gd.keys(), ...cd.keys()])) {
        if (gd.get(k) !== cd.get(k)) lines.push(`bin ${k}: gpu ${gd.get(k)} cpu ${cd.get(k)}`);
    }
    const key = (n) => `${n.number}:${n.num_uniques}`;
    const gn = new Set((g.nice_numbers ?? []).map(key));
    const cn = new Set((c.nice_numbers ?? []).map(key));
    for (const x of gn) if (!cn.has(x)) lines.push(`near-miss only on gpu: ${x}`);
    for (const x of cn) if (!gn.has(x)) lines.push(`near-miss only on cpu: ${x}`);
    if (!lines.length) lines.push("same content, different serialisation (order or formatting)");
    return lines;
}
