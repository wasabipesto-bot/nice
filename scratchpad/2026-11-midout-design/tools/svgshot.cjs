// SVG → PNG at 2x: node /page/tools/svgshot.cjs /page/static/midout-overview.svg /page/static/midout-overview.png
const { chromium } = require('playwright');
const [, , src, out] = process.argv;
(async () => { const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 1500, height: 1060 }, deviceScaleFactor: 2 });
  const errs = []; p.on('pageerror', e => errs.push(e.message));
  await p.goto('file://' + src); await p.screenshot({ path: out }); console.log('svg errors', JSON.stringify(errs)); await b.close(); })();
