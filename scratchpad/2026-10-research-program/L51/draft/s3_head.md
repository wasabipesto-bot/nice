## 3. Part B: retune screens (unprofiled, one binary, every value its own comptime kernel, 2 interleaved rounds)

`chain_screen2.sh`: per round b62 1e17 then b60 1e16, every variant once, the base (d813aea's constants) at the start and
in the middle of each block; round 2 runs the list reversed. **Ratio = local base ÷ variant**, the local base being the
base runs of the same round nearest in time before and after (the card's speed drifted by up to 2.6 % over a
20-minute block; the round-mean ratio is in `raw/analysis.txt`). After every run its join kernel was replayed through
the driver's JIT; a run that had compiled the 40-register spill variant (§3.3) was kept as `*_spill<k>` and re-run, up
to twice, so the ratios compare spill-free kernels (TOP_CAP 512 compiles 40 registers + 8 B in every process: its
third try stands). Every run gave the exact counts.

The first form of the chain (`chain_screen.sh`, 06:46–07:04) had a name bug (`${v%2}` turned `tm512`, `ag2`, `tc512`,
`fd512` into unknown names, which ran the defaults); its valid runs (round 1 b62: base, EPT 1/3, TMIN 128/256, AG 8,
base2) were kept, the two mislabelled ones count as base runs (`base3`, `base4`), and `chain_screen2.sh` (07:17–)
finished round 1 with two more base runs (`base5`, `base6`) and ran round 2.
