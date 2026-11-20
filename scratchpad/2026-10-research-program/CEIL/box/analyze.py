#!/usr/bin/env python3
"""analyze.py: tables from CEIL/raw/s_<base>_<pip>.txt (mo_ceiling output). Usage: analyze.py <base> [files...]"""
import re, sys, glob, os

RAW = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'raw')
MAXPOP = 17


def parse(path):
    vs, q0, setup = {}, None, None
    for line in open(path):
        if line.startswith('VAR '):
            name = line.split()[1]
            d = {}
            for k, v in re.findall(r'(\w+)=(\[[^\]]*\]|\S+)', line):
                if v.startswith('['):
                    d[k] = [int(x) for x in v.strip('[]').split(',') if x.strip()]
                else:
                    try:
                        d[k] = int(v)
                    except ValueError:
                        d[k] = v
            vs[name] = d
        elif line.startswith('Q0REF'):
            q0 = line
        elif line.startswith('SETUP'):
            setup = line
    return vs, q0, setup


def tot(runs, name):
    out = {}
    for vs in runs:
        if name not in vs:
            return None
        for k, v in vs[name].items():
            if k == 'csz':
                out[k] = v
            elif isinstance(v, int):
                out[k] = out.get(k, 0) + v
            elif isinstance(v, list):
                o = out.setdefault(k, [])
                o.extend([0] * (len(v) - len(o)))
                for i, x in enumerate(v):
                    o[i] += x
    return out


def work(d, g=16, model='issue'):
    # today's kernel: every listed (probe, round) costs nch lane slots × MAXPOP ORs; ext digits add the max over
    # lanes. 'issue': a slot costs the same whatever the chunk width (load-instruction bound); 'bytes': a slot
    # costs csz/64 of a 64-bit slot (LDS-bandwidth bound).
    w = d[f'lane{g}'] * MAXPOP + d[f'wext{g}']
    return w * d['csz'] / 64 if model == 'bytes' else w


WIDE = False


def main():
    global WIDE, MAXPOP
    b = sys.argv[1]
    MAXPOP = 18 if b == '65' else 17  # gpu_wide.rs WideCaps::for_base: maxpop 18 at base 65
    WIDE = any(os.path.basename(f).startswith(('w_', 'q6b_')) for f in sys.argv[2:])
    files = sys.argv[2:] or sorted(glob.glob(f'{RAW}/s_{b}_*.txt'))
    runs = []
    used = []
    for f in files:
        vs, q0, setup = parse(f)
        if 'code' not in vs:
            print(f'(skip {f}: incomplete)')
            continue
        runs.append(vs)
        used.append(f)
        c = vs['code']
        m = re.search(r'children: (\d+), chunks: (\d+), pairs: (\d+), flat: (\d+), kept: (\d+), words: (\d+), survivors: (\d+), checked: (\d+)', q0 or '')
        ref = tuple(int(x) for x in m.groups()) if m else None
        mine = (c['children'], c['chunks'], None, c['flat'], c['kept'], c['records'], c['surv'], c['checked'])
        ok = ref is not None and all(x is None or x == y for x, y in zip(mine, ref))
        print(f'{os.path.basename(f)}: Q0 slice_join match={ok} ref={ref} mine={mine}')
    n = len(runs)
    print(f'\n{n} slices of base {b}\n')
    names = list(runs[0].keys())
    c = tot(runs, 'code')
    wc16, wc64 = work(c, 16), work(c, 64)
    print('| variant | kept/flat | dead a | dead b | ORs/kept | records | survivors | checked | lane slots (round) | busy (round) | busy (64-chunk wave) | work rel, issue | work rel, bytes | work64 rel | ORs rel | oracle lane slots rel |')
    print('|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|')
    for nm in names:
        d = tot(runs, nm)
        if d is None:
            continue
        fl = d['flat']
        rec = d['records'] if d['csz'] <= 64 or WIDE else None
        print(f"| {nm} | {d['kept']/fl:.4f} | {d['dead_a']/fl:.4f} | {d['dead_b']/fl:.4f} | {d['ors']/max(d['kept'],1):.2f} | "
              f"{rec if rec is not None else '-'} | {d['surv'] if rec is not None else '-'} | {d['checked'] if rec is not None else '-'} | "
              f"{d['lane16']} | {d['kept']/max(d['lane16'],1):.4f} | {d['kept']/max(d['lane64'],1):.4f} | "
              f"{work(d,16)/wc16:.4f} | {work(d,16,'bytes')/wc16:.4f} | {work(d,64)/wc64:.4f} | {d['ors']/c['ors']:.4f} | "
              f"{(d['lane16_or']/c['lane16']) if rec is not None else float('nan'):.4f} |")
    print('\nExactness (discarded survivors relative to today\'s word under the same order):\n')
    print('| variant | discarded survivors | of which pass prefilter | nice among them | claim verified | claim failed | dead_clip |')
    print('|---|---|---|---|---|---|---|')
    for nm in names:
        d = tot(runs, nm)
        if d is None or d['disc_surv'] == 0 and d['dead_a'] == 0:
            continue
        print(f"| {nm} | {d['disc_surv']} | {d['disc_checked']} | {d['disc_nice']} | {d['disc_claim_ok']} | {d['disc_claim_bad']} | {d['dead_clip']} |")
    print('\nExtended-digit count per visit (all visits; kept visits), summed:\n')
    for nm in names:
        d = tot(runs, nm)
        if d is None or len(d.get('hist', [])) <= 1:
            continue
        h, hk = d['hist'], d.get('hist_kept', [])
        sh = sum(h)
        print(f"- {nm}: " + ', '.join(f'{i}: {x/sh:.3f}' for i, x in enumerate(h)) + f"  | kept: {hk}")
    print('\nQ3 (code order):')
    print(f"  (child, a0) dead {c['q3_dead_pairs']}/{c['q3_pairs']} = {c['q3_dead_pairs']/c['q3_pairs']:.4f}; records {c['records']} -> {c['q3_records']} "
          f"({c['q3_records']/c['records']:.4f}); survivors {c['surv']} -> {c['q3_surv']} ({c['q3_surv']/c['surv']:.4f}); "
          f"kept visits whose dead word covers the chunk {c['q3_skip']} ({c['q3_skip']/c['kept']:.4f}); violations {c['q3_viol']}")
    for nm in ['code', 'lex', 'code_c128', 'lex_c128', 'lex_c256', 'lorder_ext', 'hyb3_cell', 'hyb5_cell']:
        d = tot(runs, nm)
        if d and d.get('q4l_plain'):
            print(f"Q4 under the lane model ({nm}): slot ORs by digits {d['q4l_plain']}, shared in mask order {d['q4l_trie']} "
                  f"({d['q4l_trie']/d['q4l_plain']:.4f}); against today's MAXPOP per slot: {d['q4l_trie']/(MAXPOP*c['lane16']):.4f} "
                  f"(code's lane16×MAXPOP = {MAXPOP*c['lane16']}); oracle: listed only where a word is nonzero, lane slots {d['lane16_or']} ({d['lane16_or']/d['lane16']:.4f} of {nm}'s)")
    for nm in ['code', 'lex', 'code_c128', 'lex_c128', 'lex_c256', 'lorder_ext', 'hyb3_cell', 'hyb5_cell']:
        d = tot(runs, nm)
        if d and d.get('q4w4_17'):
            print(f"Q4 lockstep ({nm}, csz {d['csz']}): wave of 4 streams: 17/slot {d['q4w4_17']}, digits {d['q4w4_len']} ({d['q4w4_len']/d['q4w4_17']:.4f}), "
                  f"trie {d['q4w4_trie']} ({d['q4w4_trie']/d['q4w4_17']:.4f}); wave of 2: digits {d['q4w2_len']/d['q4w2_17']:.4f}, trie {d['q4w2_trie']/d['q4w2_17']:.4f}; "
                  f"trie (wave 4) against code's 17 x lane slots x csz/64: {d['q4w4_trie']*d['csz']/64/(17*c['lane16']):.4f}, against code's lockstep 17: {d['q4w4_trie']*d['csz']/64/c['q4w4_17']:.4f}")
    print('Q4 (code order, kept probes per chunk):')
    print(f"  ORs plain {c['q4_plain']}; shared, probes by top value {c['q4_trie_h']} ({c['q4_trie_h']/c['q4_plain']:.4f}); "
          f"by mask (trie over kept) {c['q4_trie_mask_kept']} ({c['q4_trie_mask_kept']/c['q4_plain']:.4f}); "
          f"trie over all probes x chunks {c['q4_trie_mask']} ({c['q4_trie_mask']/c['q4_plain']:.4f})")
    print('\nPer-slice kept fraction and work16 relative to code, for selected variants:\n')
    sel = [x for x in ['code', 'key0', 'key8', 'key12', 'key16', 'lex', 'greedy', 'lorder_plain', 'lorder_ext', 'lorder_ext_c32', 'hyb1_cell', 'hyb2_cell', 'hyb3_cell', 'hyb4_cell', 'hyb6_cell', 'hyb3_tight'] if x in names]
    print('| slice | ' + ' | '.join(sel) + ' |')
    print('|---' * (len(sel) + 1) + '|')
    for f, vs in zip(used, runs):
        w0 = work(vs['code']) or float('nan')
        print(f'| {os.path.basename(f)} | ' + ' | '.join(f"{vs[s]['kept']/vs[s]['flat']:.3f} / {work(vs[s])/w0:.3f}" if s in vs else '-' for s in sel) + ' |')


main()
