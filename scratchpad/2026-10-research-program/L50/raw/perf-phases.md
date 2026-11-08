## split-b60e16-1t.data: IPC 1.87, 4.00 branch-misses per 1k instructions
| phase | % cycles | % instructions | % branch-misses | IPC | misses / 1k instr |
|---|---|---|---|---|---|
| scan (AND + extraction) | 39.0 | 34.6 | 50.0 | 1.66 | 5.8 |
| survivor (range + prefilter) | 14.6 | 12.3 | 18.0 | 1.57 | 5.8 |
| full check | 11.1 | 9.8 | 14.9 | 1.64 | 6.1 |
| top cert (FD read) | 14.8 | 18.1 | 6.6 | 2.27 | 1.5 |
| top step | 10.9 | 14.0 | 5.1 | 2.40 | 1.5 |
| top seed | 2.2 | 2.5 | 1.0 | 2.18 | 1.5 |
| tops loop + dh | 3.2 | 4.3 | 1.4 | 2.50 | 1.3 |
| sort tops | 1.3 | 1.9 | 0.0 | 2.59 | 0.1 |
| list + advance | 0.9 | 0.9 | 1.8 | 1.80 | 8.4 |
| extend | 0.2 | 0.2 | 0.1 | 1.67 | 1.6 |
| closure (tops/extend/list/sort inlined) | 0.5 | 0.4 | 0.6 | 1.43 | 5.7 |
| other | 1.1 | 1.1 | 0.4 | 1.83 | 1.4 |

## split-b62e17s0-1t.data: IPC 1.87, 3.95 branch-misses per 1k instructions
| phase | % cycles | % instructions | % branch-misses | IPC | misses / 1k instr |
|---|---|---|---|---|---|
| scan (AND + extraction) | 37.6 | 33.2 | 49.8 | 1.65 | 5.9 |
| survivor (range + prefilter) | 14.7 | 12.7 | 18.6 | 1.61 | 5.8 |
| full check | 12.1 | 10.6 | 15.4 | 1.64 | 5.7 |
| top cert (FD read) | 13.2 | 16.7 | 5.5 | 2.36 | 1.3 |
| top step | 9.3 | 12.3 | 3.9 | 2.46 | 1.3 |
| top seed | 4.2 | 5.1 | 1.7 | 2.28 | 1.3 |
| tops loop + dh | 3.4 | 3.9 | 1.3 | 2.14 | 1.3 |
| sort tops | 1.3 | 1.8 | 0.0 | 2.53 | 0.1 |
| list + advance | 1.1 | 0.9 | 2.1 | 1.59 | 9.1 |
| extend | 0.2 | 0.2 | 0.1 | 1.61 | 2.3 |
| closure (tops/extend/list/sort inlined) | 0.5 | 0.4 | 0.5 | 1.40 | 5.3 |
| other | 2.0 | 2.1 | 0.8 | 1.99 | 1.5 |

## plain-b60e16-1t.data: IPC 2.06, 4.06 branch-misses per 1k instructions
| phase | % cycles | % instructions | % branch-misses | IPC | misses / 1k instr |
|---|---|---|---|---|---|
| scan (AND + extraction) | 40.0 | 31.2 | 51.3 | 1.61 | 6.7 |
| survivor (range + prefilter) | 14.4 | 11.2 | 18.1 | 1.60 | 6.6 |
| full check | 11.2 | 8.8 | 14.5 | 1.62 | 6.7 |
| sort tops | 1.4 | 1.9 | 0.1 | 2.83 | 0.1 |
| closure (tops/extend/list/sort inlined) | 31.6 | 45.5 | 15.2 | 2.97 | 1.4 |
| other | 1.1 | 1.4 | 0.6 | 2.65 | 1.7 |

## plain-b60e16-4t.data: IPC 1.97, 4.18 branch-misses per 1k instructions
| phase | % cycles | % instructions | % branch-misses | IPC | misses / 1k instr |
|---|---|---|---|---|---|
| scan (AND + extraction) | 40.4 | 33.5 | 50.7 | 1.63 | 6.3 |
| survivor (range + prefilter) | 14.3 | 11.6 | 17.7 | 1.59 | 6.4 |
| full check | 11.5 | 9.5 | 14.5 | 1.63 | 6.4 |
| sort tops | 1.4 | 2.0 | 0.1 | 2.72 | 0.1 |
| closure (tops/extend/list/sort inlined) | 30.9 | 42.2 | 16.3 | 2.69 | 1.6 |
| other | 1.1 | 1.1 | 0.6 | 2.04 | 2.1 |

## plain-b62e17s0-1t.data: IPC 1.93, 4.14 branch-misses per 1k instructions
| phase | % cycles | % instructions | % branch-misses | IPC | misses / 1k instr |
|---|---|---|---|---|---|
| scan (AND + extraction) | 38.9 | 32.7 | 50.0 | 1.62 | 6.3 |
| survivor (range + prefilter) | 14.8 | 12.4 | 18.7 | 1.62 | 6.2 |
| full check | 11.9 | 10.0 | 15.2 | 1.63 | 6.2 |
| sort tops | 1.3 | 1.9 | 0.1 | 2.79 | 0.1 |
| closure (tops/extend/list/sort inlined) | 31.1 | 40.8 | 15.3 | 2.53 | 1.6 |
| other | 1.7 | 2.1 | 0.7 | 2.43 | 1.3 |

## plain-b62e17s0-4t.data: IPC 1.93, 4.13 branch-misses per 1k instructions
| phase | % cycles | % instructions | % branch-misses | IPC | misses / 1k instr |
|---|---|---|---|---|---|
| scan (AND + extraction) | 38.4 | 31.9 | 49.6 | 1.60 | 6.4 |
| survivor (range + prefilter) | 15.0 | 12.1 | 18.9 | 1.55 | 6.5 |
| full check | 11.5 | 9.7 | 15.0 | 1.63 | 6.4 |
| sort tops | 1.3 | 1.8 | 0.1 | 2.65 | 0.1 |
| closure (tops/extend/list/sort inlined) | 31.5 | 42.2 | 15.2 | 2.59 | 1.5 |
| other | 1.9 | 2.2 | 0.9 | 2.21 | 1.8 |

## plain-b60e14-1t.data: IPC 1.95, 4.88 branch-misses per 1k instructions
| phase | % cycles | % instructions | % branch-misses | IPC | misses / 1k instr |
|---|---|---|---|---|---|
| scan (AND + extraction) | 19.5 | 14.8 | 20.6 | 1.49 | 6.8 |
| survivor (range + prefilter) | 12.6 | 9.5 | 13.0 | 1.47 | 6.7 |
| full check | 7.4 | 5.6 | 7.7 | 1.48 | 6.7 |
| sort tops | 1.4 | 1.6 | 1.6 | 2.26 | 4.9 |
| closure (tops/extend/list/sort inlined) | 57.8 | 67.2 | 56.5 | 2.27 | 4.1 |
| other | 0.9 | 1.2 | 0.3 | 2.65 | 1.3 |

## plain-b60e14-4t.data: IPC 1.99, 4.90 branch-misses per 1k instructions
| phase | % cycles | % instructions | % branch-misses | IPC | misses / 1k instr |
|---|---|---|---|---|---|
| scan (AND + extraction) | 19.5 | 15.2 | 20.6 | 1.55 | 6.7 |
| survivor (range + prefilter) | 12.7 | 9.5 | 13.0 | 1.49 | 6.7 |
| full check | 7.5 | 5.7 | 7.9 | 1.53 | 6.7 |
| sort tops | 1.4 | 1.6 | 1.6 | 2.14 | 5.1 |
| closure (tops/extend/list/sort inlined) | 57.6 | 66.7 | 56.3 | 2.31 | 4.1 |
| other | 1.0 | 1.2 | 0.4 | 2.52 | 1.6 |

## plain-b62e14-1t.data: IPC 1.90, 5.25 branch-misses per 1k instructions
| phase | % cycles | % instructions | % branch-misses | IPC | misses / 1k instr |
|---|---|---|---|---|---|
| scan (AND + extraction) | 16.4 | 13.1 | 15.5 | 1.51 | 6.2 |
| survivor (range + prefilter) | 13.0 | 10.2 | 11.9 | 1.48 | 6.2 |
| full check | 6.1 | 5.0 | 5.9 | 1.57 | 6.1 |
| sort tops | 0.9 | 1.1 | 1.0 | 2.16 | 5.1 |
| closure (tops/extend/list/sort inlined) | 62.3 | 69.2 | 65.2 | 2.11 | 4.9 |
| other | 0.9 | 1.3 | 0.3 | 2.70 | 1.2 |

## plain-b62e14-4t.data: IPC 1.88, 5.30 branch-misses per 1k instructions
| phase | % cycles | % instructions | % branch-misses | IPC | misses / 1k instr |
|---|---|---|---|---|---|
| scan (AND + extraction) | 16.0 | 12.8 | 15.0 | 1.50 | 6.2 |
| survivor (range + prefilter) | 13.9 | 10.8 | 12.5 | 1.45 | 6.2 |
| full check | 6.2 | 4.9 | 5.7 | 1.50 | 6.1 |
| sort tops | 0.9 | 1.1 | 1.0 | 2.14 | 5.0 |
| closure (tops/extend/list/sort inlined) | 61.5 | 69.0 | 65.2 | 2.11 | 5.0 |
| other | 1.0 | 1.3 | 0.4 | 2.39 | 1.5 |

