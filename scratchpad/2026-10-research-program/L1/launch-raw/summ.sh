#!/bin/bash
# summ.sh LOG...: one line per base from the harness's JOIN THROUGHPUT lines
grep -h "JOIN THROUGHPUT\|EXP_FLUSH\|EXP_OVERRAN" "$@" | perl -ne 'if (/JOIN THROUGHPUT.*base=(\d+).*per_field=([\d.]+).*device=([\d.]+)s.*batches=(\d+) slots=(\d+) plan_mib=(\d+).*retried=(\d+).*survivors=(\d+) checked=(\d+) found=(\d+).*peak_in_use_mib=(\d+) peak_reserved_mib=(\d+)/) { print "b$1 pf=$2 dev=$3 batches=$4 slots=$5 mib=$6 retried=$7 surv=$8 chk=$9 found=$10 inuse=$11 resv=$12\n" } elsif (/EXP_(FLUSH|OVERRAN)/) { s/^\s+//; print }'
