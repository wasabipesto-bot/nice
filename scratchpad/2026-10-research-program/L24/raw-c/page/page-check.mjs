// Open parity.html as a person would (?run=1 presses Run), wait for the
// verdict, save a screenshot and the verdict text. Scratch tool, not in the PR.
//   node page-check.mjs SITE_ROOT OUT_PREFIX [subset] [hw]
import { chromium } from "playwright";
import { createServer } from "node:http";
import { readFile, writeFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
const [root, out, subset = "ci", mode = ""] = process.argv.slice(2);
const MIME = { ".html": "text/html", ".js": "text/javascript", ".wasm": "application/wasm" };
const server = createServer(async (req, res) => {
    try {
        const file = normalize(join(root, req.url.split("?")[0]));
        res.writeHead(200, { "Content-Type": MIME[extname(file)] ?? "application/octet-stream" });
        res.end(await readFile(file));
    } catch { res.writeHead(404); res.end(); }
});
await new Promise((r) => server.listen(0, "127.0.0.1", r));
const url = `http://127.0.0.1:${server.address().port}/parity.html?subset=${subset}&run=1`;
const browser = await chromium.launch(
    mode === "hw"
        ? { headless: true, channel: "chromium" }
        : { headless: true, args: ["--enable-unsafe-webgpu", "--use-webgpu-adapter=swiftshader", "--enable-features=Vulkan"] },
);
const page = await browser.newPage({ viewport: { width: 1100, height: 900 } });
page.on("pageerror", (e) => console.log("pageerror", e.message));
const t0 = Date.now();
await page.goto(url);
await page.waitForFunction(() => /PASS|FAIL|ERROR|Nothing/.test(document.getElementById("verdict").textContent), undefined, { timeout: 600000 });
const verdict = await page.textContent("#verdict");
const adapter = await page.textContent("#adapter");
console.log(`verdict: ${verdict}\nadapter panel: ${adapter.replace(/\s+/g, " ")}\nwall ${(Date.now() - t0) / 1000} s`);
await page.screenshot({ path: `${out}.png` });
await page.click("#copy");
await writeFile(`${out}.verdict.txt`, `${verdict}\n${adapter}\n`);
await browser.close();
server.close();
