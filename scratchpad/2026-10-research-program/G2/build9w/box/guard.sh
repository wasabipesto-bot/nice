#!/bin/bash
# sourced by every run script: abort unless the production hosts are mapped to loopback and unreachable; save the proof
P=$1/hosts_proof.txt; date -u > $P
grep -q "127.0.0.1 api.nicenumbers.net" /etc/hosts && grep -q "::1 api.nicenumbers.net" /etc/hosts || { echo "ABORT: hosts block missing" | tee -a $P; exit 1; }
for h in api.nicenumbers.net data.nicenumbers.net nicenumbers.net www.nicenumbers.net; do
  echo "$(getent hosts $h | tr '\n' ' ') curl=$(curl -s -m 5 -o /dev/null -w '%{http_code}' https://$h/)" >> $P
  if curl -s -m 5 -o /dev/null https://$h/; then echo "ABORT: $h reachable" | tee -a $P; exit 1; fi
done
