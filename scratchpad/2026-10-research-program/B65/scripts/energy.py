#!/usr/bin/env python3
"""energy.py START END (UTC, e.g. 2026-11-26T05:49:00Z): eventeo's wall energy over the window from the smart plug
in Prometheus on shalash: the integral of hassio_sensor_power_w (30 s scrape) and the energy counter's difference."""
import json, sys, urllib.request, urllib.parse
from datetime import datetime
P = 'http://shalash.neon-locrian.ts.net:9090/api/v1/query_range'
def q(expr, a, b):
    u = P + '?' + urllib.parse.urlencode({'query': expr, 'start': a, 'end': b, 'step': '30'})
    r = json.load(urllib.request.urlopen(u, timeout=20))['data']['result']
    return [(float(t), float(v)) for t, v in r[0]['values']] if r else []
a, b = sys.argv[1], sys.argv[2]
pw = q('hassio_sensor_power_w{entity="sensor.0x282c02bfffec51b1_power"}', a, b)
e = q('hassio_sensor_energy_kwh{entity="sensor.0x282c02bfffec51b1_energy"}', a, b)
kwh = sum(v * 30 for _, v in pw) / 3.6e6
print(f'samples {len(pw)}; mean {sum(v for _, v in pw)/max(len(pw),1):.1f} W; max {max((v for _, v in pw), default=0):.1f} W; integral {kwh:.3f} kWh')
if e: print(f'energy counter {e[0][1]:.2f} -> {e[-1][1]:.2f} kWh: {e[-1][1]-e[0][1]:.2f} kWh (0.01 kWh resolution)')
