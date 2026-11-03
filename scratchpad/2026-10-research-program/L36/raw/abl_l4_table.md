| removed | b62 1e17: stepped s, ns | saves | % of s | b60 1e16: stepped s, ns | saves | % of s | rounds |
|---|---|---|---|---|---|---|---|
| none | **0.2182** | | | **0.2092** | | | 6 / 6 |
| LSCAN (fast path) + LC0 (carried c0, b^c0 - d) | 0.1732 | 0.0450 | 20.6 % | 0.1644 | 0.0447 | 21.4 % | 6 / 6 |
| LCLIP (no a, e on steps) | 0.2127 | 0.0055 | 2.5 % | 0.2054 | 0.0038 | 1.8 % | 6 / 6 |
| LSCAN (fast path) + LC0 (carried c0, b^c0 - d) + LCLIP (no a, e on steps) | 0.1695 | 0.0487 | 22.3 % | 0.1612 | 0.0479 | 22.9 % | 6 / 6 |
