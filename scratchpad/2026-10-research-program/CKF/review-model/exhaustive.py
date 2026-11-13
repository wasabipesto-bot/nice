# Every population of a 16-lane plane, and 200k random populations of a 32-lane one:
# ballot ranks are 0..n-1 distinct, exactly one leader, lead index = the leader's lane.
import random
M=0xFFFFFFFF
def check(lanes_set, W):
    lanes=0
    for l in lanes_set: lanes|=1<<l
    ranks={l: bin(lanes & (((1<<l)-1)&M)).count('1') for l in lanes_set}
    assert sorted(ranks.values())==list(range(len(lanes_set)))
    lead=bin(lanes ^ ((lanes-1)&M)).count('1')-1
    assert ranks[lead]==0 and lead in lanes_set
for m in range(1,1<<16):
    check([l for l in range(16) if m>>l&1],16)
rng=random.Random(5)
for _ in range(200000):
    m=rng.getrandbits(32) or 1
    check([l for l in range(32) if m>>l&1],32)
check(list(range(32)),32); check([31],32); check([0],32)
print("ballot single-take: all populations ok")
