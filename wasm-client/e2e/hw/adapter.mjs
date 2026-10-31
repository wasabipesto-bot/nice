// Adapter check: which WebGPU adapter headless Chromium hands the page, and
// whether the GPU path really runs on it.
//
//   node adapter.mjs [--chromium-arg FLAG]... [--expect-vendor apple|amd]
//                    [--min-rate 1e8] [--software] [--chrome-gpu]
//                    [--rate-window N] [--out FILE]
//
// Records the adapter (vendor, architecture, device, description,
// isFallbackAdapter, features, limits), the wasm's gpu_init() name and build,
// then times process_chunk_gpu over the b40_detailed GPU window (2e8 numbers
// from the plan's start; 2e6 with --software): one untimed call (shader
// compile), one timed.
// Hardware mode (default) fails unless the adapter is real (see
// lib.mjs:hardwareProblems); --software asserts the inverse (CI's pinned
// SwiftShader). --chrome-gpu also saves chrome://gpu's text. Exit 1 on a
// failed assertion, 2 on no adapter at all.
import { writeFile } from "node:fs/promises";
import { adapterRecord, hardwareProblems, launch, modulePage, parseArgs, serve, softwareProblems, timeGpu } from "./lib.mjs";

const args = parseArgs();
const software = !!args.software;
const site = await serve();
const { browser, flags, version } = await launch({ software, args: args["chromium-arg"] ?? [] });
console.log(`chromium ${version}; flags: ${flags.length ? flags.join(" ") : "(none)"}`);

const out = { chromium: version, flags, software, when: new Date().toISOString() };

if (args["chrome-gpu"]) {
    // Best effort: the page is a web component; its text lives in a shadow root.
    try {
        const p = await browser.newPage();
        await p.goto("chrome://gpu");
        await p.waitForTimeout(3000);
        out.chrome_gpu = await p.evaluate(() => {
            // A ShadowRoot has no innerText; read its element children.
            const root = document.querySelector("info-view")?.shadowRoot;
            return root ? [...root.children].map((c) => c.innerText ?? "").join("\n") : document.body.innerText;
        });
        await p.close();
    } catch (e) {
        out.chrome_gpu_error = String(e);
    }
}

const page = await modulePage(browser, site.url, "adapter");
const rec = await adapterRecord(page);
out.adapter = rec;
console.log(
    `adapter: ${rec.adapter ? "yes" : "NO"}; vendor=${JSON.stringify(rec.vendor)} architecture=${JSON.stringify(
        rec.architecture,
    )} device=${JSON.stringify(rec.device)} description=${JSON.stringify(rec.description)} fallback=${rec.fallback}`,
);
console.log(`gpu_init name: ${JSON.stringify(rec.gpu_init_name ?? rec.gpu_init_error)}; build ${rec.build_sha} ${rec.client_version}; ${rec.gpu_build_info}`);

let code = 0;
if (rec.adapter && !rec.gpu_init_error) {
    const plan = JSON.parse(await page.evaluate(() => window.__nice.benchmark_plan()));
    const def = plan.scenarios.find((s) => s.key === "b40_detailed");
    // The full 2e8 window in hardware mode; software adapters run ~1e6 n/s,
    // so they get a 2e6 window unless --rate-window says otherwise.
    const size = BigInt(args["rate-window"] ?? (software ? 2_000_000 : def.window_gpu));
    const r = await timeGpu(page, { base: def.base, start: BigInt(def.start), size, warm: 1, calls: 1 });
    const warmSecs = r.secs[1];
    out.rate_check = {
        scenario: def.key,
        base: def.base,
        start: def.start,
        size: size.toString(),
        first_call_secs: -r.secs[0],
        warm_call_secs: warmSecs,
        warm_rate: Number(size) / warmSecs,
        result_sha_prefix: r.json.slice(0, 120),
    };
    console.log(
        `b40 ${size} numbers: first call ${(-r.secs[0]).toFixed(3)} s, warm call ${warmSecs.toFixed(3)} s = ${(
            Number(size) / warmSecs
        ).toExponential(3)} n/s`,
    );
    const problems = software
        ? softwareProblems(rec)
        : hardwareProblems(rec, {
              expectVendor: args["expect-vendor"],
              rate: out.rate_check.warm_rate,
              minRate: Number(args["min-rate"] ?? 1e8),
          });
    out.problems = problems;
    if (problems.length) {
        console.log(`ADAPTER CHECK FAILED: ${problems.join("; ")}`);
        code = 1;
    } else {
        console.log(`adapter check passed (${software ? "software, as pinned" : "hardware"})`);
    }
} else {
    out.problems = [rec.adapter ? `gpu_init failed: ${rec.gpu_init_error}` : "no adapter returned"];
    console.log(`ADAPTER CHECK FAILED: ${out.problems.join("; ")}`);
    code = 2;
}

if (args.out) await writeFile(args.out, JSON.stringify(out, null, 2) + "\n");
await browser.close();
await site.close();
process.exit(code);
