// Render the interactive map in Chromium (Playwright), click every node and check its panel, try each spotlight,
// and take screenshots. Run inside the Playwright container (see README): node /page/tools/shot_map.cjs
const { chromium } = require('playwright');
const PAGE = 'file:///page/interactive/midout-map.html', OUT = '/page/screenshots/';
(async () => {
  const b = await chromium.launch();
  const errs = [];
  const mk = async (theme, dsf, vp) => {
    const p = await b.newPage({ viewport: vp || { width: 1800, height: 1200 }, colorScheme: theme, deviceScaleFactor: dsf });
    p.on('pageerror', e => errs.push(theme + ' pageerror ' + e.message));
    p.on('console', m => { if (m.type() === 'error' || m.type() === 'warning') errs.push(theme + ' console ' + m.text()); });
    await p.goto(PAGE); return p;
  };
  // 1. every node: click, check the panel
  const p = await mk('light', 1);
  const ids = await p.$$eval('g.node', gs => gs.map(g => g.dataset.id));
  const bad = [];
  for (const id of ids) {
    await p.click(`g.node[data-id="${id}"]`);
    const r = await p.evaluate(() => {
      const pn = document.getElementById('panel');
      return { title: pn.querySelector('.title')?.textContent || '', why: !!pn.textContent.match(/Why it exists/),
               refs: pn.querySelectorAll('.refs code').length, len: pn.textContent.length };
    });
    if (!r.title || !r.why || r.len < 120) bad.push([id, r]);
    if (!r.refs && !['o_claim'].includes(id)) bad.push([id, 'no refs']);
  }
  console.log('nodes', ids.length, 'bad panels', JSON.stringify(bad));
  // 2. full page, light, one node selected
  await p.click('g.node[data-id="main"]');
  await p.screenshot({ path: OUT + 'map-full-light.png', fullPage: true });
  // 3. spotlights (viewport shots at 1x of the diagram area)
  for (const v of ['acc', 'wide', 'fld', 'S', '6']) {
    await p.selectOption('#optSpot', v);
    const dims = await p.$$eval('g.node.dim', g => g.length);
    const accShown = await p.$$eval('path.edge.acc', es => es.filter(e => getComputedStyle(e).display !== 'none').length);
    console.log('spotlight', v, 'dimmed', dims, 'account edges shown', accShown);
    await p.screenshot({ path: OUT + `map-spot-${v}.png`, fullPage: true });
  }
  await p.selectOption('#optSpot', '');
  // toggles
  await p.click('#optBars'); const bars = await p.$$eval('g.bar', g => g.filter(x => getComputedStyle(x).display !== 'none').length);
  await p.click('#optCorr'); const corr = await p.$$eval('path.edge.corr', g => g.filter(x => getComputedStyle(x).display !== 'none').length);
  console.log('bars shown after toggle off', bars, '| corr shown after toggle off', corr);
  await p.click('#optBars'); await p.click('#optCorr');
  // 4. 2x shots a person looks at: panel views
  const q = await mk('light', 2, { width: 1800, height: 1150 });
  await q.click('g.node[data-id="main"]');
  await q.evaluate(() => document.querySelector('g.node[data-id="main"]').scrollIntoView({ block: 'center' }));
  await q.screenshot({ path: OUT + 'map-main-panel-light@2x.png' });
  await q.click('g.node[data-id="expand"]');
  await q.selectOption('#optSpot', 'acc');
  await q.screenshot({ path: OUT + 'map-checks-spotlight-light@2x.png' });
  const d = await mk('dark', 2, { width: 1800, height: 1150 });
  await d.click('g.node[data-id="anc8"]');
  await d.screenshot({ path: OUT + 'map-top-dark@2x.png' });
  await d.selectOption('#optSpot', 'wide');
  await d.evaluate(() => document.querySelector('g.node[data-id="main"]').scrollIntoView({ block: 'center' }));
  await d.click('g.node[data-id="main"]');
  await d.screenshot({ path: OUT + 'map-wide-dark@2x.png' });
  // 5. narrow viewport: no horizontal page scroll of the body
  const m = await mk('light', 1, { width: 390, height: 900 });
  const sw = await m.evaluate(() => [document.documentElement.scrollWidth, window.innerWidth]);
  console.log('phone width scrollWidth/innerWidth', sw);
  console.log('errors', JSON.stringify(errs));
  await b.close();
})().catch(e => { console.error('FAILED', e); process.exit(1); });
