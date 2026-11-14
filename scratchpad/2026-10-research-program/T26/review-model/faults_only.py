"""Run only the fault suites of top_slot_review.py (seeds from argv)."""
import sys
import top_slot_review as m
out = sys.stdout
for seed in [int(s) for s in sys.argv[1:]] or [11]:
    out.write(f"== faults, seed {seed} ==\n")
    m.random_suite(seed, 20000, out, noreconv=True)
    m.random_suite(seed, 20000, out, fault="misreport64")
    m.random_suite(seed, 20000, out, fault="scan_garbage", forms=["scan"], pkinds=["prefix", "nolane0", "holes"])
    m.random_suite(seed, 20000, out, fault="bad_shuffle", forms=["ballot"], widths=[8, 16, 32])
    m.random_suite(seed, 20000, out, fault="rotlane", forms=["ballot"], widths=[32], pkinds=["full", "prefix"])
    m.random_suite(seed, 20000, out, fault="ballot_ghost", forms=["ballot"], widths=[8, 16, 32], pkinds=["prefix", "nolane0", "holes"])
    out.flush()
