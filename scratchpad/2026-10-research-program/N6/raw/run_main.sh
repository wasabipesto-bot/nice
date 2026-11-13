#!/bin/bash
# N6 main counting runs: 48 field locations x 25 grandparent units per base and seed.
# Two streams (seeds 1 and 2), each sequential over bases, under nice -n 19.
BIN=~/projects/nice/target/release/examples/n6_top_counts
cd "$(dirname "$0")"
for seed in 1 2; do
  ( for spec in "60 1e16" "62 1e17" "64 1e17"; do
      set -- $spec
      { time nice -n 19 $BIN $1 $2 48 25 $seed > main_b$1_s$seed.log ; } 2> main_b$1_s$seed.err
    done ) &
done
wait
