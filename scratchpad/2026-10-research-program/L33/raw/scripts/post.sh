#!/bin/bash
# After master2: the host cost of the parent digits (ER=8: the host builds them, the kernel is A's), then lavapipe.
L=/root/l33/logs; R=/root/l33/scripts/runv.sh
while ! grep -q "MASTER done" $L/master.log 2>/dev/null; do sleep 10; done
echo "POST start $(date -u +%T)" >> $L/master.log
for r in 1 2 3; do
  $R ab3_A_e16_b62_r$r A "" 62 2 1e16
  $R ab3_p_e16_b62_r$r B2 8 62 2 1e16
done
$R ab3_A_e17_b62_r1 A "" 62 1 1e17
$R ab3_p_e17_b62_r1 B2 8 62 1 1e17
echo "POST done $(date -u +%T)" >> $L/master.log
sed -i 's/MASTER done/MASTER_done_seen/' /dev/null
/root/l33/scripts/chain_lvp2.sh
