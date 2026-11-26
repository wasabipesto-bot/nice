#!/bin/bash
# chain1.sh: after builds1.sh, the A/B (runs_ab.sh), then the stage profile (runs_stage.sh).
. "$HOME/research/scripts/env.sh"
until [ -f $R/logs/b65/builds1.done ]; do sleep 10; done
grep -q "rc=[1-9]" $R/logs/b65/rc.txt && echo "a build failed: A/B runs only for what exists" >> $R/logs/b65/rc.txt
bash $R/b65/scripts/runs_ab.sh
bash $R/b65/scripts/runs_stage.sh
echo done > $R/b65/chain1.done
