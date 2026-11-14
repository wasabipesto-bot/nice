import random, top_slot_model as T
# re-run the misreport variant and print the first undetected trial's planes
rng = random.Random(7); v = dict(name='fix', form='ballot', width=64, misreport=True)
M = T.M
for trial in range(20000):
    ngroups = rng.choice([1, 2, 4]); width = 64
    planes = [T.make_plane(rng, width, ngroups) for _ in range(rng.randint(1, 6))]
    cnt = [0]*ngroups; seg = width*len(planes); base_of = lambda g: g*seg
    written = []; dn = ds = 0; rng.shuffle(planes); want = [0]*ngroups
    for kind, lanes in planes:
        for l, x in lanes.items():
            if x['kept'] and x['active']: want[x['g']] += 1
        out, acc = T.new_slot(lanes, cnt, 'ballot', True, False, base_of)
        written += list(out.values()); dn = (dn+acc[0]) % M; ds = (ds+acc[1]) % M
    ok = cnt == want and sorted(written) == sorted((g, i) for g in range(ngroups) for i in range(cnt[g]))
    if not ok and dn == 0 and ds == 0:
        print('trial', trial, 'ngroups', ngroups, 'cnt', cnt, 'want', want)
        for kind, lanes in planes:
            kl = [(l, x['g']) for l, x in lanes.items() if x['kept'] and x['active']]
            print(' plane', kind, 'kept active (lane, g):', kl)
        print(' written', sorted(written))
