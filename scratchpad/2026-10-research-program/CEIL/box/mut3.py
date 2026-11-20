#!/usr/bin/env python3
# box: mut3.py — the review's 27 mutants on dev/mo-clean c2152084 in /w/mut (own target /w/tmut); copied from G2/build7p/box/mut2.py, paths changed only.
# The review's sed line numbers refer to 06d55495; each is remapped to the same source line in the head
# (matched by text, and by occurrence order where the text repeats), then the sed is applied there.
import subprocess, re, sys, os


os.chdir('/w/mut')
env = dict(os.environ, CARGO_TARGET_DIR='/w/tmut', PATH='/root/.cargo/bin:' + os.environ['PATH'])
OLD = '06d55495'
src = open('/w/box/mut_list.sh').read()
muts = re.findall(r"^run (\S+) \$(C|A) '(.*)'$", src, re.M)
def lines(rev, f):
    return subprocess.run(['git', 'show', f'{rev}:{f}'], capture_output=True, text=True, check=True).stdout.split('\n')
done = set(l.split()[0] for l in open('/w/raw/mut/table.txt')) if os.path.exists('/w/raw/mut/table.txt') else set()
out = open('/w/raw/mut/table.txt', 'a')
for mid, which, expr in muts:
    if mid in done:
        continue
    f = 'common/src/midout/cpu.rs' if which == 'C' else 'common/src/midout/arith.rs'
    subprocess.run(['git', 'checkout', '-q', '--', 'common/src/midout'], check=True)
    old = lines(OLD, f); new = open(f).read().split('\n')
    def remap(m):
        L = int(m.group(1)); text = old[L - 1]
        occ = [i for i, t in enumerate(old) if t == text].index(L - 1)
        hits = [i for i, t in enumerate(new) if t == text]
        if len(hits) <= occ:
            # a line of the old test that the head rewrote: find the head's counterpart by the sed's own pattern
            pat = expr.split(';')[[int(x) for x in re.findall(r'(\d+)s/', expr)].index(L)].split('/')[1]
            pat = pat.replace('\\', '')
            hits = [i for i, t in enumerate(new) if pat in t]
            nonlocal_note.append(f'line {L} remapped by pattern to {[h + 1 for h in hits]}')
            return ','.join(f'{h + 1}' for h in hits[:1]) + 's'
        return f'{hits[occ] + 1}s'
    nonlocal_note = []
    e2 = re.sub(r'(\d+)s', remap, expr)
    before = open(f).read()
    subprocess.run(['sed', '-i', e2.replace('\\&', '\\&'), f], check=True)
    if open(f).read() == before:
        out.write(f'{mid} NOAPPLY ({e2})\n'); out.flush(); continue
    diff = subprocess.run(['git', 'diff', '-U0'], capture_output=True, text=True).stdout
    r = subprocess.run('timeout 900 cargo test -q --release -p nice_common --lib midout::', shell=True,
                       capture_output=True, text=True, env=env)
    fails = sorted(set(re.findall(r'^    (midout::\S+)$', r.stdout, re.M)))
    verdict = 'SURVIVES' if r.returncode == 0 else 'killed'
    out.write(f'{mid} {verdict} rc={r.returncode} failing={",".join(x.split("::")[-1] for x in fails)} {" ".join(nonlocal_note)}\n'); out.flush()
    open(f'/w/raw/mut/{mid}.diff', 'w').write(diff)
    open(f'/w/raw/mut/{mid}.log', 'w').write(r.stdout[-6000:] + r.stderr[-3000:])
subprocess.run(['git', 'checkout', '-q', '--', 'common/src/midout'])
out.write('DONE\n')
