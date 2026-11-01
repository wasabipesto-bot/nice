#!/bin/bash
/root/stack.sh pr segv &
/root/stack.sh pr cert &
/root/stack.sh pr parity &
/root/stack.sh main parity &
/root/stack.sh fix parity &
/root/stack.sh fix cert &
wait
touch /root/logs/stack_all.done
