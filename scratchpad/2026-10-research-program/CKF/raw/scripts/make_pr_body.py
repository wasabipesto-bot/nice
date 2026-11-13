#!/usr/bin/env python3
"""make_pr_body.py: CKF/PR-BODY.md = the PR's body before (raw/pr251-body-before.md, title line dropped) with
CKF/PR-BODY-DELTA.md applied: the Work distribution bullet, the Soundness section, the Measurements preface, the
Exactness additions, and the two register paragraphs marked as the previous head's."""
import re, os
D = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
before = open(f'{D}/raw/pr251-body-before.md').read().split('\n', 2)[2]   # drop title + blank
delta = open(f'{D}/PR-BODY-DELTA.md').read()
def part(head):
    i = delta.index(head); j = delta.index('\n', i) + 1
    k = delta.find('\n## ', j)
    return delta[j:k if k >= 0 else None].strip('\n')
work = part('## What → replace').strip()
sound = part('## Soundness → replace').strip()
meas = part('## Measurements → insert').strip()
exact = part('## Exactness → add').strip()
work = re.sub(r'\n\s+', ' ', work)          # one line, like the body's bullets
b = before
b = re.sub(r'^- \*\*Work distribution\.\*\*.*$', work, b, count=1, flags=re.M)
i = b.index('## Soundness\n'); j = b.index('\n## Measurements\n')
b = b[:i] + '## Soundness\n\n' + sound + '\n' + b[j:]
i = b.index('## Measurements\n\n') + len('## Measurements\n\n')
b = b[:i] + meas + '\n\n' + b[i:]
i = b.index('## Exactness\n\n') + len('## Exactness\n\n')
j = b.index('\n- ', i) + 1                  # after the preamble paragraph
b = b[:j] + exact + '\n' + b[j:]
b = b.replace('**Code** (the runtime\'s path:', '**Code** (the previous head\'s kernel; the runtime\'s path:', 1)
b = b.replace('From the driver\'s JIT of the PTX each process compiled at run time (NVRTC, as CubeCL runs it), over all 24 processes of the A/B: the check kernel has',
              'From the driver\'s JIT of the PTX each process compiled at run time (NVRTC, as CubeCL runs it). This head\'s check kernel has 47 registers at b62 and b64 and 39 at b60, with no spills (all 12 processes of this head above). The previous head\'s, over all 24 processes of the first A/B, has', 1)
for w in ('research', 'scratchpad', 'program', 'agent', 'Claude', 'Opus', 'Sonnet', 'CKF', 'ivory', 'Vast'):
    assert w not in b.replace('Generated with [Claude Code]', ''), w
open(f'{D}/PR-BODY.md', 'w').write(b)
print(len(b), 'chars')
