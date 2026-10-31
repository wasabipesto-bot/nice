// Browser GPU rates, two ways, interleaved by round:
//
//  kernel  process_chunk_gpu over each GPU scenario's window (the plan's
//          b40_detailed and b50_detailed: 2e8 numbers from the range start)
//          in a fresh page: --warm untimed calls, then --calls timed ones;
//          the round's value is the median timed call.
//  suite   the real page in "Benchmark suite (NiceMark)" mode on the GPU
//          backend (a dedicated worker, two slices in flight, exactly as a
//          user runs it) with --budget seconds; the page's own benchmark
//          report is captured whole. The API is stubbed: /ping answers
//          locally and every other off-box request is aborted.
//
//   node bench.mjs [--rounds 3] [--warm 2] [--calls 3] [--budget 60]
//                  [--only kernel|suite] [--chromium-arg FLAG]... [--out FILE]
import { writeFile } from "node:fs/promises";
import { adapterRecord, launch, modulePage, parseArgs, serve, timeGpu } from "./lib.mjs";

const args = parseArgs();
const ROUNDS = Number(args.rounds ?? 3);
const WARM = Number(args.warm ?? 2);
const CALLS = Number(args.calls ?? 3);
const BUDGET = String(args.budget ?? 60);
const only = args.only;

const site = await serve();
const { browser, flags, version } = await launch({ args: args["chromium-arg"] ?? [] });
console.log(`chromium ${version}; flags: ${flags.length ? flags.join(" ") : "(none)"}; ${ROUNDS} rounds`);

const probe = await modulePage(browser, site.url, "probe");
const adapter = await adapterRecord(probe);
const plan = JSON.parse(await probe.evaluate(() => window.__nice.benchmark_plan()));
await probe.close();
const gpuDefs = plan.scenarios.filter((s) => BigInt(s.window_gpu) > 0n);
console.log(`adapter ${adapter.vendor}/${adapter.architecture} fallback=${adapter.fallback}; scenarios ${gpuDefs.map((s) => s.key).join(", ")}`);

const med = (v) => [...v].sort((a, b) => a - b)[Math.floor(v.length / 2)];

async function kernel(def) {
    const page = await modulePage(browser, site.url, `kernel:${def.key}`);
    const size = BigInt(def.window_gpu);
    const r = await timeGpu(page, { base: def.base, start: BigInt(def.start), size, warm: WARM, calls: CALLS });
    await page.close();
    const timed = r.secs.filter((x) => x >= 0);
    return {
        key: def.key,
        base: def.base,
        window: size.toString(),
        untimed_secs: r.secs.filter((x) => x < 0).map((x) => -x),
        timed_secs: timed,
        median_secs: med(timed),
        rate: Number(size) / med(timed),
    };
}

async function suite() {
    const page = await browser.newPage();
    let report = null;
    page.on("console", async (m) => {
        if (m.text().startsWith("benchmark report:")) {
            try {
                report = await m.args()[1].jsonValue();
            } catch (e) {
                console.log(`[suite] could not read report: ${e}`);
            }
        }
    });
    page.on("pageerror", (e) => console.log(`[suite] pageerror: ${e.message}`));
    await page.route("**/*", async (route) => {
        const u = route.request().url();
        if (u.startsWith(site.url)) return route.continue();
        if (u.includes("api.nicenumbers.net") && u.includes("/ping")) {
            return route.fulfill({ status: 200, headers: { "Access-Control-Allow-Origin": "*" }, body: "pong" });
        }
        return route.abort();
    });
    await page.goto(site.url);
    await page.waitForSelector("#startBtn:not([disabled])", { timeout: 120000 });
    await page.waitForFunction(() => !document.getElementById("backendHelp").textContent.includes("Checking"), undefined, {
        timeout: 120000,
    });
    const backends = await page.evaluate(() => [...document.querySelectorAll("#backendSelect option")].map((o) => `${o.value}=${o.textContent.trim()}`));
    if (!backends.some((b) => b.startsWith("gpu="))) {
        const why = await page.textContent("#backendHelp");
        await page.close();
        return { error: `page offered no GPU backend: ${why}` };
    }
    await page.selectOption("#testMode", "suite");
    await page.selectOption("#backendSelect", "gpu");
    await page.selectOption("#benchBudget", BUDGET);
    const t0 = Date.now();
    await page.click("#startBtn");
    await page.waitForFunction(() => /suite complete/i.test(document.getElementById("status").textContent), undefined, {
        timeout: 30 * 60 * 1000,
    });
    for (let i = 0; i < 50 && !report; i++) await new Promise((r) => setTimeout(r, 100));
    const score = await page.textContent("#nicemarkScore");
    await page.close();
    return { wall_secs: (Date.now() - t0) / 1000, backends, score: score?.trim(), report };
}

const runs = [];
for (let r = 1; r <= ROUNDS; r++) {
    if (only !== "suite") {
        for (const def of gpuDefs) {
            const k = await kernel(def);
            runs.push({ round: r, kind: "kernel", ...k });
            console.log(
                `round ${r} kernel ${k.key}: ${k.rate.toExponential(3)} n/s (timed ${k.timed_secs.map((x) => x.toFixed(4)).join(" ")} s; untimed ${k.untimed_secs
                    .map((x) => x.toFixed(3))
                    .join(" ")} s)`,
            );
        }
    }
    if (only !== "kernel") {
        const s = await suite();
        runs.push({ round: r, kind: "suite", ...s });
        if (s.error) console.log(`round ${r} suite: ${s.error}`);
        else
            console.log(
                `round ${r} suite: NiceMark ${s.score}; ` +
                    (s.report?.scenarios ?? [])
                        .map((x) => `${x.key}=${x.rate.toExponential(3)} n/s (${x.repetitions}x${Number(x.window_size).toExponential(0)}, warmup ${x.warmup_seconds.toFixed(2)} s)`)
                        .join("  "),
            );
    }
}
if (args.out) await writeFile(args.out, JSON.stringify({ chromium: version, flags, adapter, budget_secs: Number(BUDGET), warm: WARM, calls: CALLS, runs }, null, 2) + "\n");
await browser.close();
await site.close();
