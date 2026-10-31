// Capture the WGSL the browser kernel hands to createShaderModule, per base,
// on SwiftShader (scratch tool for the WGSL lint; not part of the PR).
import { chromium } from "playwright";
import { createServer } from "node:http";
import { readFile, writeFile, mkdir } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
const root = normalize(process.argv[2]);
const outDir = process.argv[3];
const bases = (process.argv[4] ?? "10,23,40,50,57,64,80,97").split(",").map(Number);
const MIME = { ".html": "text/html", ".js": "text/javascript", ".wasm": "application/wasm" };
const server = createServer(async (req, res) => {
    try {
        const path = req.url.split("?")[0];
        const file = normalize(join(root, path));
        const body = await readFile(file);
        res.writeHead(200, { "Content-Type": MIME[extname(file)] ?? "application/octet-stream" });
        res.end(body);
    } catch { res.writeHead(404); res.end(); }
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const url = `http://127.0.0.1:${server.address().port}/`;
const browser = await chromium.launch({ headless: true, args: ["--enable-unsafe-webgpu", "--use-webgpu-adapter=swiftshader", "--enable-features=Vulkan"] });
const page = await browser.newPage();
await page.addInitScript(() => {
    window.__wgsl = [];
    const orig = GPUDevice.prototype.createShaderModule;
    GPUDevice.prototype.createShaderModule = function (desc) {
        window.__wgsl.push({ label: desc.label ?? null, code: desc.code });
        return orig.call(this, desc);
    };
});
await page.goto(`${url}parity.html`);
await page.waitForFunction(() => window.parityReady || window.parityError, undefined, { timeout: 120000 });
await mkdir(outDir, { recursive: true });
for (const b of bases) {
    const before = await page.evaluate(() => window.__wgsl.length);
    await page.evaluate(async (b) => {
        const P = window.parity;
        const [s] = P.baseRange(b);
        await P.wasm.process_chunk_gpu(s.toString(), (s + 1000n).toString(), b);
    }, b);
    const mods = await page.evaluate((n) => window.__wgsl.slice(n), before);
    for (const [i, m] of mods.entries()) {
        await writeFile(join(outDir, `browser_b${b}_${i}.wgsl`), m.code);
        console.log(`b${b}: module ${i} label=${m.label} ${m.code.length} bytes`);
    }
}
await browser.close();
server.close();
