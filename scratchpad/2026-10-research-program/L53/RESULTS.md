# L53 RESULTS: #249's layer sort off the device thread (RTX 3080 at 150 W, 2026-11-09)

Brief: `BRIEF.md` (L51.1's lever). New commit **`39a495a`** "Overlap join: sort the top layer off the device thread"
on `pr/join-static-buckets` (third commit on `87958fd`). Box: Vast **59842980** (`nice-research-l53-sort`), RTX 3080
10 GB, driver 580.159.03, CUDA 12.8 toolkit, **power limit 150 W** (default 320 W; every timed run sat at 147–150 W),
Xeon **E5-2630 v4 @ 2.2 GHz** (20 threads visible, cgroup quota 19.2 CPUs), **7.7 GB RAM**, rustc 1.99.1. Host load
during the timed chains: load1 median 1.1–1.2 (max 1.5 / 2.0), i.e. the harness's own threads and nothing else.
Raw logs `raw/box/logs/`, scripts `raw/scripts/`, tables `raw/analysis_ab.txt` (`analyze53.py`) and
`raw/analysis_alt.txt` (`analyze_alt.py`).

## Summary

(filled in below)

## 1. Where the sort sat, and why the GPU idled (87958fd)

1. `run_slices_with` runs each slice's `run_slice` on the thread that drives the device; beside it a scoped thread
   prepares only the *next* slice's `FieldSetup` (`field.fs.sub_range`: its top layer unsorted, its bottoms pruned),
   and the loop joins that thread after `run_slice` returns.
2. The sort was not in that thread: `run_slice` begins with `JoinDevice::new`, whose first host step was
   `sorted_layer(fs, nkeys)` (a counting sort of the slice's top layer by group, two passes of 3 u64 divisions per
   prefix plus one more for `P0 mod b^(k2−f0−p)`, ~2.8 M prefixes per b62 1e17 slice), before any buffer or launch.
3. By then the previous `run_slice` had read every batch back (`run_pass` drains its fences, then `read_hits`), so
   the device queue was empty: the GPU idled for the whole sort, 11 times per b62 1e17 field (2 per b60 1e16).
4. Slice 0 was the same: `run_field` → first `run_slice` → `JoinDevice::new` → sort, on the pipeline thread that had
   just finished the previous field; `plan_join` (which the client does overlap with the previous field) built the
   first slice's `FieldSetup` but not its sorted layer.
5. So the overlap that existed covered `sub_range` only; the sort sat on the critical path between one slice's last
   read and the next slice's first launch, and `device_secs` (timed from the top of `run_slice`) counted it.
