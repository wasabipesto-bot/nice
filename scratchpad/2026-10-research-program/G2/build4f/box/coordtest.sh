#!/bin/bash
# the coordinator's own rules over curl: never twice across a restart, route check, one submission per field; $1 = run tag
set -u
B=/root/mo/bin; R=/root/mo/runs/$1/coord; mkdir -p $R; P=8480; O=$R/out.txt; : > $O
$B/midout_fields --base 64 --t 10,20,30 > $R/w.json
st() { python3 /root/mc/scripts/midout_coordinator.py --worklist $R/w.json --state $R/state --port $P "$@" 2>> $R/coord.log & echo $! > $R/pid; sleep 1; }
st
echo "GET /claim/niceonly (plain): $(curl -s -w ' %{http_code}' http://127.0.0.1:$P/claim/niceonly)" >> $O
echo "claim 1: $(curl -s http://127.0.0.1:$P/claim/niceonly?coordinate=midout)" >> $O
echo "claim 2: $(curl -s http://127.0.0.1:$P/claim/niceonly?coordinate=midout)" >> $O
kill $(cat $R/pid); sleep 1; st
echo "after restart, claim 3: $(curl -s http://127.0.0.1:$P/claim/niceonly?coordinate=midout)" >> $O
echo "claim 4 (none left): $(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:$P/claim/niceonly?coordinate=midout)" >> $O
sub() { curl -s -w ' %{http_code}' -X POST -H 'Content-Type: application/json' -d "$1" http://127.0.0.1:$P/submit; }
echo "submit claim 1000 route overlap: $(sub '{"claim_id":1000,"username":"t","client_version":"x","unique_distribution":null,"nice_numbers":[],"telemetry":{"pipeline":{"route":"overlap"}}}')" >> $O
echo "submit claim 1000 no telemetry: $(sub '{"claim_id":1000,"username":"t","client_version":"x","unique_distribution":null,"nice_numbers":[]}')" >> $O
echo "submit claim 1000 route midout: $(sub '{"claim_id":1000,"username":"t","client_version":"x","unique_distribution":null,"nice_numbers":[],"telemetry":{"pipeline":{"route":"midout"}}}')" >> $O
echo "submit claim 1000 again: $(sub '{"claim_id":1000,"username":"t","client_version":"x","unique_distribution":null,"nice_numbers":[],"telemetry":{"pipeline":{"route":"midout"}}}')" >> $O
echo "submit unknown claim 5: $(sub '{"claim_id":5,"username":"t","client_version":"x","unique_distribution":null,"nice_numbers":[],"telemetry":{"pipeline":{"route":"midout"}}}')" >> $O
kill $(cat $R/pid); sleep 1; st --reissue-after 0
echo "restart with --reissue-after 0: claim: $(curl -s http://127.0.0.1:$P/claim/niceonly?coordinate=midout)" >> $O
echo "status: $(curl -s http://127.0.0.1:$P/status)" >> $O
kill $(cat $R/pid); cat $O
