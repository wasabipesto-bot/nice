from explore import digits, obs, to_limbs, chunk16
b, s, ls, lc = 23, 795831, 9, 14
e, K = chunk16(b)
print("K", K, "e", e)
rows = []
for n in range(s, s + 40):
    sq = to_limbs(n*n, 2); cu = to_limbs(n**3, 3)
    t = len(set(digits(sq, ls, b, 'xxx') + digits(cu, lc, b, 'xxx')))
    m = len(set(digits(sq, ls, b, 'yxx') + digits(cu, lc, b, 'xxx')))
    g = obs.get((b, n), (t, t))[1]
    hi, lo = sq[1], sq[0]
    print(n, "true", t, "model", m, "gpu", g, "hi", hi, "hi>>16", hi >> 16, "lo>>16", lo >> 16, "(lo>>16)//K", (lo >> 16)//K,
          "Sdig", digits(sq, ls, b, 'xxx'), "Sdig_m", digits(sq, ls, b, 'yxx'))
