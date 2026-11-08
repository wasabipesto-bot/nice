## aftersplit-b60e16-1t.data: IPC 2.49, 1.75 branch-misses per 1k instructions
| phase | % cycles | % instructions | % branch-misses | IPC | misses / 1k instr |
|---|---|---|---|---|---|
| scan (AND + extraction) | 43.8 | 43.3 | 54.6 | 2.46 | 2.2 |
| full check | 6.8 | 6.6 | 8.3 | 2.41 | 2.2 |
| top cert (FD read) | 21.4 | 22.1 | 14.9 | 2.58 | 1.2 |
| top step | 14.9 | 16.0 | 10.8 | 2.66 | 1.2 |
| top seed | 2.9 | 3.0 | 2.2 | 2.59 | 1.3 |
| tops loop + dh | 5.2 | 4.8 | 3.5 | 2.30 | 1.3 |
| sort tops | 1.9 | 2.0 | 0.1 | 2.61 | 0.1 |
| list + advance | 1.1 | 0.8 | 3.9 | 1.75 | 8.5 |
| extend | 0.2 | 0.2 | 0.2 | 1.66 | 1.9 |
| closure (tops/extend/list/sort inlined) | 0.7 | 0.6 | 0.7 | 2.11 | 2.1 |
| other | 0.8 | 0.7 | 0.8 | 1.95 | 2.0 |

## aftersplit-b62e17s0-1t.data: IPC 2.56, 1.70 branch-misses per 1k instructions
| phase | % cycles | % instructions | % branch-misses | IPC | misses / 1k instr |
|---|---|---|---|---|---|
| scan (AND + extraction) | 43.5 | 42.3 | 54.2 | 2.48 | 2.2 |
| full check | 6.9 | 6.9 | 9.3 | 2.56 | 2.3 |
| top cert (FD read) | 18.6 | 19.8 | 12.8 | 2.73 | 1.1 |
| top step | 13.7 | 14.7 | 9.2 | 2.75 | 1.1 |
| top seed | 6.3 | 6.6 | 4.0 | 2.69 | 1.0 |
| tops loop + dh | 4.8 | 4.7 | 3.3 | 2.52 | 1.2 |
| sort tops | 1.8 | 1.8 | 0.1 | 2.52 | 0.1 |
| list + advance | 1.3 | 0.8 | 4.5 | 1.62 | 9.2 |
| extend | 0.3 | 0.2 | 0.2 | 1.62 | 2.0 |
| closure (tops/extend/list/sort inlined) | 0.6 | 0.5 | 0.8 | 2.29 | 2.6 |
| other | 1.8 | 1.6 | 1.2 | 2.27 | 1.3 |

## scan2checkinl-b60e16-1t.data: IPC 2.48, 1.84 branch-misses per 1k instructions
| phase | % cycles | % instructions | % branch-misses | IPC | misses / 1k instr |
|---|---|---|---|---|---|
| scan (AND + extraction) | 47.2 | 45.0 | 54.9 | 2.36 | 2.2 |
| full check | 7.2 | 7.0 | 8.2 | 2.42 | 2.1 |
| top seed | 2.7 | 2.7 | 2.0 | 2.49 | 1.4 |
| sort tops | 1.9 | 2.0 | 0.1 | 2.59 | 0.1 |
| other | 40.6 | 43.3 | 34.5 | 2.64 | 1.5 |

