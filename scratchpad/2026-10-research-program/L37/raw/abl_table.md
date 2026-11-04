| part | b62 1e17 s/field | % join | % field | % join in cycles | b60 1e16 s/field | % join | % field | % join in cycles |
|---|---|---|---|---|---|---|---|---|
| base: no AND (mode z): work items, top batch + transposed copy, entry loads + prefilter terms, per-chunk stage check (2 barriers) | 29.69 | 41.0 % | 22.9 % | 39.9 % | 5.73 | 37.9 % | 22.4 % | 39.1 % |
| AND: the transposed digit ORs (a − z) | 3.67 | 5.1 % | 2.8 % | 1.7 % | 0.67 | 4.4 % | 2.6 % | -0.5 % |
| walk: rounds, set-bit pops, residue test (b − a) | 11.29 | 15.6 % | 8.7 % | 16.8 % | 2.34 | 15.5 % | 9.1 % | 13.9 % |
| prefilter `walk_pf` (p − b) | 24.18 | 33.4 % | 18.6 % | 36.1 % | 5.69 | 37.6 % | 22.2 % | 44.0 % |
| stage + flush (c − p) | 3.57 | 4.9 % | 2.7 % | 5.5 % | 0.70 | 4.7 % | 2.7 % | 3.6 % |
| **join (mode c = main)** | **72.39** | 100 % | 55.8 % | 94.8 G-cycles | **15.15** | 100 % | 59.1 % | 20.1 G-cycles |
| field (profiled device, probe excluded) | 129.74 | | 100 % | | 25.64 | | 100 % | |

| mode | NICE_EXP_JOIN_ABL | b62 1e17 join s/field (rounds) | field | SM MHz | b60 1e16 join s/field (rounds) | field | SM MHz |
|---|---|---|---|---|---|---|---|
| c: full (= main) | 0 | 72.39 (71.44, 72.39, 75.27) | 129.74 | 1297 | 15.15 (15.13, 15.15, 15.65) | 25.64 | 1305 |
| a: AND only | 1 | 33.36 (33.36, 33.55, 32.98) | 83.23 | 1189 | 6.41 (6.52, 6.38, 6.41) | 14.82 | 1179 |
| b: walk, no prefilter, no stage | 2 | 44.64 (44.35, 44.64, 45.09) | 92.69 | 1246 | 8.75 (8.72, 8.75, 8.78) | 17.00 | 1204 |
| p: walk + prefilter, no stage | 3 | 68.83 (68.12, 68.83, 69.26) | 115.61 | 1309 | 14.44 (14.44, 14.51, 14.38) | 22.33 | 1334 |
| z: no AND | 4 | 29.69 (29.69, 29.80, 29.63) | 77.03 | 1273 | 5.73 (5.73, 5.73, 5.73) | 13.84 | 1349 |
| d: full, per-top AND (TMIN = 2^30) | 0 + TMIN | 84.85 (85.52, 84.85, 84.80) | 142.11 | 1297 | 17.21 (16.82, 17.32, 17.21) | 27.49 | 1295 |
