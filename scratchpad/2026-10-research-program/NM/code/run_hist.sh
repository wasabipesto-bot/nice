#!/bin/bash
# NM: full repeat counting (tol 64) on sampled partitions of production-size fields.
B=/home/claude/projects/nice/.worktrees/nm-near-miss/target-nm/release/examples/nm_join
O=${OUT:-/home/claude/projects/nice/scratchpad/2026-10-research-program/NM/raw/hist2.txt}
export NM_SAMPLE_OUT=${NM_SAMPLE_OUT:-/home/claude/projects/nice/scratchpad/2026-10-research-program/NM/raw/sample.txt}
python3 - "$@" <<'PY' > /tmp/claude-1000/-home-claude/324735b8-5439-5545-8cc9-5971228cc742/scratchpad/hist_cases.txt
import random, sys
r = random.Random(20261118)
out = []
for base, size, slices, parts, fr in [(62, '1e17', 7, 3844, [0.15, 0.35, 0.55, 0.75, 0.95]),
                                      (64, '1e17', None, 4096, [0.05, 0.25, 0.45, 0.65, 0.85])]:
    for f in fr:
        for _ in range(3):
            out.append((base, f, size, parts))
r.shuffle(out)
for base, f, size, parts in out:
    print(base, f, size, parts, r.random(), r.randrange(parts - 32))
PY
while read -r base f size parts sr v0; do
  # slice count from a dry run is not available; pick slice by fraction inside the harness range
  ns=$($B run $base f$f $size 0 0 0 0 2>/dev/null | sed -E 's/.*slice 0\/([0-9]+).*/\1/')
  si=$(python3 -c "print(int($sr*$ns))")
  echo "### b$base f$f slice $si/$ns v0 $v0 $(date -u +%H:%M:%S)" >> $O
  nice -n 19 $B run $base f$f $size $si $v0 32 64 >> $O 2>&1
done < /tmp/claude-1000/-home-claude/324735b8-5439-5545-8cc9-5971228cc742/scratchpad/hist_cases.txt
echo "#### done $(date -u +%H:%M:%S)" >> $O
