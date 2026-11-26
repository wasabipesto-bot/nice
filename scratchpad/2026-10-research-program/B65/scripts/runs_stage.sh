#!/bin/bash
# runs_stage.sh (replaced 06:2x UTC for the coordinator's added measurement): the load runs first, then the stage
# profile (runs_stage_only.sh).
. "$HOME/research/scripts/env.sh"
bash $R/b65/scripts/runs_load.sh
bash $R/b65/scripts/runs_stage_only.sh
