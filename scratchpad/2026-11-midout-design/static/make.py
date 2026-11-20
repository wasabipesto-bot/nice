"""Static overview of the middle-out join (dev/mo-clean 10ddbf17): python3 make.py, run inside static/."""
from html import escape
W, H = 1500, 1060
INK, INK2, MUTED = "#0b0b0b", "#52514e", "#8a8983"
PAGE, SURF, GRID = "#f6f5f2", "#ffffff", "#dcdad4"
HOST, HOST_BG = "#2a78d6", "#e6f0fc"
DEV, DEV_BG = "#4a3aa7", "#ebe8f8"
CPU, CPU_BG = "#138a60", "#e3f6ee"
PINK, PINK_BG = "#c2457a", "#fcebf2"
OLD, OLD_BG = "#7a7974", "#efeeea"
ACC = "#d4561f"
o = []
a = o.append
def text(x, y, s, size=13, weight=400, fill=INK, anchor="middle"):
    a(f'<text x="{x}" y="{y}" font-size="{size}" font-weight="{weight}" fill="{fill}" text-anchor="{anchor}">{escape(s)}</text>')
def card(cx, y, w, h, title, sub, stroke, fill, tsize=14.5):
    a(f'<rect x="{cx-w/2}" y="{y}" width="{w}" height="{h}" rx="10" fill="{fill}" stroke="{stroke}" stroke-width="1.6"/>')
    top = y + h/2 - (18 + len(sub)*16)/2 + 14
    text(cx, top, title, tsize, 650)
    for i, s in enumerate(sub):
        text(cx, top + 19 + i*16, s, 12, 400, INK2)
def arrow(d, color=MUTED, dash=None):
    da = f' stroke-dasharray="{dash}"' if dash else ""
    a(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="2"{da} marker-end="url(#ah)"/>')
def label(x, y, s, fill=INK2, anchor="middle", size=11.5, weight=600):
    a(f'<text x="{x}" y="{y}" font-size="{size}" font-weight="{weight}" fill="{fill}" text-anchor="{anchor}" paint-order="stroke" stroke="{PAGE}" stroke-width="5" stroke-linejoin="round">{escape(s)}</text>')
def bar(x, y, frac, color, txt):
    a(f'<rect x="{x}" y="{y}" width="120" height="8" rx="4" fill="{GRID}"/>')
    a(f'<rect x="{x}" y="{y}" width="{max(2,120*frac):.1f}" height="8" rx="4" fill="{color}"/>')
    text(x + 128, y + 8, txt, 11.5, 600, INK2, "start")

a(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" font-family="system-ui,-apple-system,Segoe UI,sans-serif">')
a(f'<defs><marker id="ah" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{MUTED}"/></marker></defs>')
a(f'<rect width="{W}" height="{H}" fill="{PAGE}"/>')
text(40, 44, "The middle-out join: one base-64 field, end to end", 22, 700, INK, "start")
text(40, 68, "A nice-only GPU join whose unit of work is every n sharing five middle digits. Branch dev/mo-clean (10ddbf17); not merged, no server change.", 13.5, 400, INK2, "start")

# --- digits strip
x0, y0, cw = 60, 104, 62
text(40, y0 - 8, "THE DIGITS OF n (BASE 64, 13 DIGITS)", 11.5, 700, MUTED, "start")
for i, p in enumerate(range(12, -1, -1)):
    fixed, sl, unit = 5 <= p <= 7, 4 <= p <= 8, p == 9
    st, fl = (PINK, PINK_BG) if fixed else (DEV, DEV_BG) if sl else (HOST, HOST_BG) if unit else (GRID, SURF)
    a(f'<rect x="{x0+i*cw}" y="{y0}" width="{cw-6}" height="30" rx="5" fill="{fl}" stroke="{st}" stroke-width="1.5"/>')
    text(x0 + i*cw + (cw-6)/2, y0 + 20, str(p), 13, 600)
def span(i0, i1, y, c, s):
    xa, xb = x0 + i0*cw, x0 + (i1+1)*cw - 6
    a(f'<line x1="{xa}" y1="{y}" x2="{xb}" y2="{y}" stroke="{c}" stroke-width="3"/>')
    text((xa+xb)/2, y + 16, s, 12, 600, c)
span(0, 8, y0 + 44, DEV, "top: n div 64^4 — a lead value h and a unit d under the slice")
span(3, 12, y0 + 82, HOST, "bottom: n mod 64^10 — a parent (digits 0–8) and one of its 64 children (digit 9)")
lx = x0 + 13*cw + 20
for i, (c, s) in enumerate([(PINK, "pink: a field fixes digits 5–7 (2^57 n, 4,096 slices)"),
                            (DEV, "purple + pink: a slice, digits 4–8 (2^45 n)"),
                            (HOST, "blue: the unit, digit 9, paired on")]):
    a(f'<rect x="{lx}" y="{y0 + i*24 - 2}" width="14" height="14" rx="3" fill="{c}"/>')
    text(lx + 22, y0 + i*24 + 10, s, 12.5, 500, INK, "start")
text(lx, y0 + 84, "Today's overlap join: tops = digits 3–12, bottoms = digits 0–5,", 12, 400, INK2, "start")
text(lx, y0 + 100, "field = a 1e17 range of n; bottoms rebuilt per partition.", 12, 400, INK2, "start")

# --- pipeline (middle column)
cx, w = 470, 400
y = 250
text(40, y - 12, "ONE FIELD", 11.5, 700, MUTED, "start")
stages = [
    ("claim from a local coordinator", ["names its coordinate · whole quanta · not the production API"], PINK, PINK_BG, 52, None),
    ("field setup (host, once)", ["4,096 slices · key from the first slice", "parent lists shared across digit 8 · one slice sampled"], HOST, HOST_BG, 62, None),
    ("tops", ["coarse level once per 64 slices · ~238k tops per slice"], DEV, DEV_BG, 52, (0.759, "tops")),
    ("parents", ["~1.04M per slice from a shared list (20 % of roots)"], DEV, DEV_BG, 52, (0.476, "parents")),
    ("main kernel: bit-sliced pairing", ["children in 64-chunks, one word per digit value", "a top tests 64 children with ~17 ORs · common-mask skip"], DEV, DEV_BG, 62, (2.607, "main")),
    ("expansion + prefilter", ["10.9M records → n · 2.87 % pass"], DEV, DEV_BG, 52, (0.356, "expansion")),
    ("production's full check (unchanged)", ["~338k entries per slice"], DEV, DEV_BG, 52, (0.112, "check")),
]
ys = []
for t, sub, st, fl, h, sh in stages:
    card(cx, y, w, h, t, sub, st, fl)
    if sh:
        bar(cx + w/2 + 18, y + h/2 - 4, sh[0]/4.312, DEV, f"{sh[0]:.3f} ms ({100*sh[0]/4.312:.0f} %)")
    ys.append((y, h)); y += h + 22
for (ya, ha), (yb, _) in zip(ys, ys[1:]):
    arrow(f"M{cx},{ya+ha} L{cx},{yb-2}")
# per-slice bracket
yt, yb = ys[2][0] - 6, ys[6][0] + ys[6][1] + 6
a(f'<path d="M{cx-w/2-14},{yt} h-8 V{yb} h8" fill="none" stroke="{DEV}" stroke-width="1.6"/>')
label(cx - w/2 - 26, (yt+yb)/2 - 8, "every slice,", DEV, "end")
label(cx - w/2 - 26, (yt+yb)/2 + 8, "no sync", DEV, "end")
label(cx + w/2 + 18, ys[2][0] - 8, "RX 9070 XT, ms per slice (share of 4.31)", MUTED, "start", 11)
label(cx + w/2 + 18, ys[6][0] + ys[6][1] + 18, "tops, parents: measured off the operating point (too high)", MUTED, "start", 11)
# checks
y += 4
card(cx, y, w, 62, "accounts compared, every 16 slices", ["each stage's own count = what was queued or counted elsewhere", "any difference: the field fails, nothing is submitted"], ACC, "#fdeee6")
arrow(f"M{cx},{ys[-1][0]+ys[-1][1]} L{cx},{y-2}")
yc = y; y += 62 + 22
card(cx, y, w, 52, "sampled CPU check, once per field", ["one random slice recomputed by the CPU, n for n"], CPU, CPU_BG)
arrow(f"M{cx},{yc+62} L{cx},{y-2}")
ys2 = y; y += 52 + 22
card(cx, y, w, 44, "submit to the coordinator → next claim", [], PINK, PINK_BG)
arrow(f"M{cx},{ys2+52} L{cx},{y-2}")
arrow(f"M{cx-w/2},{y+22} H60 V{ys[0][0]+26} H{cx-w/2-2}", MUTED, "6 5")
label(66, (ys[0][0]+y)/2, "next field", MUTED, "start")

# --- right column: overlap join and numbers
rx = 1215
text(rx - 150, 250 - 12, "TODAY'S OVERLAP JOIN, FOR COMPARISON", 11.5, 700, MUTED, "start")
oy = 250
for t, sub in [("a 1e17 range of n per field", ["tops certified per field (f0 3)"]),
               ("bottoms rebuilt per partition", ["12 certified digits (k 6)"]),
               ("AND walk + prefilter at each flush", ["one 64-bit AND per pair · 6 % pass"]),
               ("the same check", [])]:
    card(rx, oy, 300, 50, t, sub, OLD, OLD_BG, 13.5); oy += 64
text(rx - 150, oy + 14, "Same pairs tested per n at base 64; each costs", 12.5, 400, INK2, "start")
text(rx - 150, oy + 31, "about ×6–8 less here, and the work around them is", 12.5, 400, INK2, "start")
text(rx - 150, oy + 48, "shared by 2^45 n instead of one 1e17 range (judged).", 12.5, 400, INK2, "start")
ny = oy + 90
text(rx - 150, ny, "MEASURED, 2026-11-19, AGAINST v3.4.8's JOIN", 11.5, 700, MUTED, "start")
rows = [("RX 9070 XT, base 64", "0.99 vs 4.76 fs", "×4.79"),
        ("RTX 3080 240 W, base 64", "1.62 vs 6.62 fs", "×4.09"),
        ("RTX 3080, base 65", "3.29 fs", "no join today"),
        ("RX 9070 XT, base 65", "3.1 fs", "before its fit")]
for i, (c, v, r) in enumerate(rows):
    yy = ny + 26 + i*26
    text(rx - 150, yy, c, 13, 500, INK, "start")
    text(rx + 70, yy, v, 13, 400, INK2, "start")
    text(rx + 170, yy, r, 13, 700, INK, "start")
text(rx - 150, ny + 140, "fs per admissible n · exact on every slice and field tried ·", 11.5, 400, MUTED, "start")
text(rx - 150, ny + 156, "the 9070 XT number is the branch just before its cleanup", 11.5, 400, MUTED, "start")
a('</svg>')
open("midout-overview.svg", "w").write("\n".join(o))
