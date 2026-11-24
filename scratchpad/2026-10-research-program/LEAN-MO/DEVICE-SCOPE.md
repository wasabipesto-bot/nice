# Scope: a Lean model of the GPU path and a proof that it returns the reference's outcome (2026-11-24)

*Read-only scope, written on ivory 05:45–08:30 UTC from `dev/mo-clean` at `eb9ef776` (worktree `.worktrees/midout-clean`)
and `lean/midout` at `05747baa` (worktree `.worktrees/lean-midout`). Nothing was built, run or changed. Line numbers
are `common/src/midout/gpu.rs` unless another file is named; Lean names are in `lean-midout/NiceMidOut/`.*

## 0. Bottom line

- Base 64 differs from the reference in **14 algorithmic ways** (G1–G14); the wide path adds 7 (W1–W7). Most are
  short against the existing model: the device computes the same sets in other orders, and the reference's run
  form is already proved order-free (`sliceRun_surv_perm`, `RunProofs.lean:123–152`, 30 lines).
- **Silent if wrong:** G1 tops, G3 digit table, G4 shared parent lists, G7/G8 child positions and records, G11
  prefilter, G12 production's check. G12 is invisible even to the sampled slice; G4 is seen by it only through
  two counts, because the sampled slice's device rerun is unshared.
- A proof covers a **Lean description of what each stage is meant to compute**, not the kernels; without a card
  they are tied to it only by tables dumped from lavapipe (8 lanes) and by existing host mirrors. Limbs, ballots,
  shuffles, atomics, plane widths 32/64 and the check's arithmetic stay outside.
- About **1,500–2,500 Lean lines** for base 64 (40–65 % of the existing 3,754), plus a Rust dumper.
- **Prove first:** G1, then G4 with G5(b), then G7+G8. Leave G11's limbs and G12 to tests (§6).

## 1. What "the same" has to mean

Device orders are free: tops by atomic slots (`:1946`, `:2105`), records by slab arrival (`:758–790`), entries by
atomic takes (`:1742–1748`); parent records after `hsort` and each job's child list (`:462–490`) are deterministic.
So: **sets** (`∈ ↔`) for tops and parents, **lists** for parent order and child lists, **permutations** (not `Finset`:
counts are compared) for probes, records, survivors. The field outcome is still an **equality of `FieldOutcome`**
(`Join.lean:170–175`): `nice` is sorted on both sides (`:3769`, `Join.lean:189`), the counts are order-free.
Labels: **[implied]** by an existing theorem; **[short]** new, ≲150 lines; **[subst]** new, 200+ lines; **[impl]** needs
implementation detail (limbs, bits, lanes, memory). Signatures are uncompiled proposals; `sh = ⟨4, 10⟩`; base 64's
range is `[2^75, 2^76)` (`coord.rs:21`).

## 2. The differences, base-64 path (`gpu.rs`)

**G1. Tops certified in a hierarchy.** `tops5` (`:1913–1954`, once per value `q = pip >> 6` of digits 5–8, cached
by `l5cur`, `:3043–3068`) certifies the 2^21 coarse prefixes `n div 2^30` over 2^30 n; `tops1` (`:1956–2028`)
certifies a slice's prefix `n div 2^24` only under a valid coarse one. Three facts make it the reference's
`unitTops` (`Join.lean:78–80`, `cpu.rs:457`):
(a) *containment*: a valid fine top implies a valid coarse parent (the coarse interval's agreeing top positions
are a prefix of the fine one's, same digits) — via `mem_certPositions_iff` (`TopsProofs.lean:258`);
(b) *fixed positions*: the device scans positions 25..10 of n² and 37..10 of n³ (`cert_pow` `:1876–1911`, called
`:2002–2003`), the reference skips a power whose two ends differ in length (`cpu.rs:196–198`); equal because n² has
26 and n³ 38 digits on all of `[2^75, 2^76)` (`:1824–1825`); the scan itself is `topCertScan` (`TopsScan.lean:237`);
(c) *no clipping*: the reference clips each interval to the range (`unitLeads`, `Join.lean:67–74`); at base 64 no
interval crosses `2^75` or `2^76`. `theorem devTops_mem_iff (hp : pip < 2^30) : (d, t) ∈ devTops pip ↔ d < 64 ∧`
`t ∈ unitTops 64 (2^75) (2^76) 4 10 (pip + d * 64^5)` — [short] for each of (a)–(c), 250–400 lines in all.

**G2. Segments and probes.** Tops by (unit d, h mod 63) (`:2010`, `tscan` `:2033–2079`, `tops2` `:2084–2120`); job
(c, d) loads segments `ct = (root + 63 − (c+d) mod 63) mod 63` (`:353`, `:359–402`, roots `:131`): `probesOf`
(`Join.lean:147–148`) up to order. `devProbes segs c d ~ probesOf 64 (unitTops …) c d`, `roots 64 = [0,6,…,62]` by
`decide`, and the law "probes = 8 × tops" (`:3739–3744`) as a corollary — [short].

**G3. The probe digit table.** A mask as 20 six-bit fields padded with its first digit (`tdigz2` `:2124–2165`), 17 read
(`:683–687`, `:737–743`; `MAXPOP` `:139–147`, checked `:3587–3591`): `decode17 (encode m) = m` for 1 ≤ |m| ≤ 17 —
[short], bit-level. **Unguarded precondition:** for an empty mask the pad is `trailing_zeros(0)`, not a digit; the
wide path keeps a zero row for this (`gpu_wide.rs:25–27`), the narrow path has none. At base 64 an empty certified
mask needs n²'s digit 25 and n³'s digit 37 both to change in one 2^24-wide interval, `|2√m − ∛j| < 2^−50` for m ∈ {2, 3},
j ∈ [9, 63]; the nearest pairs (2√2/∛23, 2√3/∛41, ∛42) differ by ≈ 0.01. Make it a lemma (`devTops_mask_nonempty`, [short]).

**G4. Parents from depth-4 roots and from lists shared by the 64 slices differing in digit 8.** Roots: `r4 < 2^24`,
digits 0–3 of r², r³ distinct (`:2339–2343`); `anc8` (`:934–1014`; built `:4134–4151`, `:2861–2935`; looked up by digits
4–7, `:2943–2950`) keeps roots with 16 distinct digits 0–7 of `r4 + k8·2^24 mod 2^48`; `hist2` (`:1020–1100`) runs
`parent()` (`:891–932`: digits 0–8 from r mod 2^60, class `(r4 mod 63 + pip mod 63) mod 63` as 2^24 ≡ 1 mod 63, `cacc`
= `mkParent`'s c2, c3, a2, a3) over the list (`:3337`). Reference `parents` (`Join.lean:115–116`), `mem_parents_iff`
(`BottomsExact.lean:256`), containment by `lowDistinct_congr` (`:90`). `theorem devParents_mem_iff (hp : pip < 2^30)`
`(hs : src = depth4Roots ∨ src = anc8 (pip % 2^24)) : p ∈ devParents rank pip src ↔ p ∈ parents 64 sh pip` — [short].

**G5. Bucket order and the key.** Key `cls·256 + (255 − k8)` (`:920–926`), 16,128 buckets (`:1090`), scan, scatter
(`:1129–1168`, `:1296–1342`), per-bucket sort by r4 in three branches (≤256, ≤2048, larger: `:1187`, `:1218`, `:1271`).
The rank is the field's first slice's, from a 1/16 root sample (`:4133`, `:2416–2427`), not the slice's own
(`cpu.rs:737–739`, `Join.lean:253–262`). (a) `devOrder rank ps = ps.mergeSort (key rank)` for `ps` sorted by distinct r
— [short], optional (counters `kept`, `chunks` only); (b) **any rank is exact**: `(sliceRunR … rank).surv ~
sliceSurvivors …` — [short], the existing permutation proof with the rank made a parameter.

**G6. Jobs and two instances.** All (c, d) in batches of classes, each queued with probe windows [0, 576) and [576,
1152) (`:2767–2783`; kernel `:347–354`, `:388`, `:404`), children counted once (`:851–856`), >1,152 an error (`:368–370`).
`P.take 576 ++ (P.drop 576).take 576 = P` for `P.length ≤ 1152`, and the instances' survivors `~` the job's — [short].

**G7. Children per parent, chunks per job.** Phase 1 (`:447–494`) appends each certified child's r4, in parent order,
at `64·(pseg[c] − pseg[c0]) + d·|class c|` (`:54–57`, `:427`, `:482`); chunks are 64 consecutive children, the rest
carried (`:501–509`, `:810–828`). `devChildList … c d = (kidsOf 64 (class c of devOrder …) d).map (·.1 % 2^24)`,
chunks `= chunksOf 64` (`Join.lean:152–153`, `231–232`), job regions disjoint — [short] (the compaction is [impl]); and
`child_count` (`:1106–1124`, the law's second count) = #{d : `childMask … d ≠ none`} — [short].

**G8. Pairing as records, expanded afterwards.** Phases 2–3b (`:518–800`) write `[top index, chunk's first child-list
position, word]` per non-zero word (`:58–62`, `:777–790`), skip from register ballots (`:564–613`, `:663–696`); the
expansion (`:1665–1787`, `:1565–1628`) maps bit b to the child at position + b. Skip exactness is [implied]
(`probeSurv_eq`, `RunProofs.lean:84`); the word's meaning is how `sliceRun` already models it (`Join.lean:310–314`).
New: `expand (kids.map (·.1)) (records P kids) ~ (chunksOf 64 kids).flatMap fun ch => P.flatMap fun t =>`
`(ch.filter (Disjoint t.mask ·.2)).map (t, ·.1)` — [subst], 200–300 lines (transpose, ballots stay [impl]).

**G9. No interval test.** The kernel keeps every disjoint pair (`:744–745`); the reference also tests `t.lo ≤ n ≤ t.hi`
(`cpu.rs:856`, `Join.lean:166, 273`), always true at base 64 (G1(c)) — [short].

**G10. n from the entry.** `r0 = r4 + digit 4·2^24` (`:63–65`, `:1609`, `:3459`), top record `P = h·2^30 + d·2^24 +`
digits 5–8 (`:44–46`, `:2169–2197`), `n = P·64^5 + r0 = h·64^10 + d·64^9 + (r4 + pip·2^24)` — [short], `omega`.

**G11. Prefilter in the expansion, with the top's certificate above position 11.** `keep_bits2` `:1611–1619`;
`pf` (32-bit limbs, `:1503–1542`) or `pf24` (24-bit limbs, `:1462–1501`) by runtime (`:2467–2487`). (a) The rule is
`midPrefilter 64 10 n t.mhi` (`Join.lean:132–140`) without the exemption, which never applies since n ≥ 2^75 >
64^6 (`cpu.rs:236–239`) — [short]; (b) it depends on n mod 2^72 only — [short]; its soundness for nice n is
[implied] (`midPrefilter_of_isNice`, `Prefilter.lean:46`; `midPrefilter_of_mem_unitTops`, `:112`); (c) that `pf`
and `pf24` compute it — [impl].

**G12. Production's full check.** `check_kernel` (`cubecl_join.rs:3475`, launched `:3465–3486`, shape `:2762`): n
rebuilt in base-b² limbs from (P, w6, r0), a gate on n² and n³'s low digits, quotients by multiply-high
(`join_check.rs:1–30`). The gate being necessary and `magic`'s exactness (`join_check.rs:23–30`) are [short];
columns, carries and limbs are [impl].

**G13. A field as groups of 16 slices.** `field_run` (`:4072–4288`), groups `:4154–4170`, accounts `finish_group`
(`:3506–3673`), `check_slice` (`:3680–3752`). Outcome: `survivors` = the main kernel's bits (`:3549–3558`, = bits read,
`:3627–3631`); `checked` = entries checked (`:3624`); `slices` = done words (`:3666–3671`); `nice` = sorted cumulative
buffer minus its content before the field, as a multiset (`:3755–3771`, `:4107`, `:4224–4230`). With G1–G11:
`deviceSearchField_eq` (§4), [short given the rest], 150–250 lines (cf. `EndToEnd`, 188). Accounts and the two laws
are evidence that kernels ran, not functions; only "the laws hold for the model" is provable — [short], low value.

**G14. One slice per field recomputed on the CPU.** Random slice (`:4110–4128`), CPU `cpu_slice` (`:3888–3904`);
in-field counts must equal the CPU's (`:3917–3927`); an **unshared** rerun (`:3181`, `:3928`) must match its list n for
n (`:3930–3941`). Probabilistic; not a proof object.

Correction to the brief: the **parents** are scattered into (class, key) buckets and sorted (G5); children are
appended per parent in the main kernel (G7).

**Wide path (`gpu_wide.rs`, bases 65–70), in addition:** W1 clipping per top at the range's first and last
prefixes (`wtop_ctx` `:2054–2086`) and a clipped coarse level (`:1657–1661`); W2 the prefilter's exemption flag
(`:2079–2084`); W3 records name the probe slot, mapped back to a top by recounting the segments (`wrec_top`
`:2011–2052`) — silent if wrong; W4 `ninst` instances instead of two (`:32–33`); W5 per-base `maxpop`, 7-bit
fields and a zero row for empty masks (`:21–27`); W6 its own check, `wcheck_kernel` (`:2338`), not independently
audited (DESIGN §6.9); W7 no parent sharing (`:65–66`). Everything below is for base 64; the wide path is a second
instance of the same model with W1–W6 added, roughly +40 % (W1 and W3 are the new proofs).

## 3. Which errors would lose a nice number silently

Accounts see work dropped or duplicated by count, not work that ran and computed wrongly. The sampled slice sees
any defect that changes its counts or list. One slice of 4,096 is drawn per field (`:4114`): a defect touching a
fraction f of slices is seen with probability f per field, 1 − (1 − f)^k after k fields (DESIGN §4); one confined to
the nice number's own slice, 1/4,096 ≈ 0.024 % per field.

| | caught by accounts? | sampled slice | rare trigger the sample misses | rank |
|---|---|---|---|---|
| G12 check | no (entries counted, verdict not) | **never** (it compares the list before the check) | every nice n (none known at b64) | 1 |
| G4 shared lists | no (`anc8` counts its own list, `:2900–2928`) | only the in-field counts; the rerun is unshared | a root missing for some digit-4–7 values only | 2 |
| G11 prefilter | no (`F_PF_DROP` passes them all, DESIGN §4) | yes for a fraction ≳ 1e-7 of survivors (11.8M per slice) | limb carry cases (`pf`, `pf24`) | 3 |
| G1 tops | no (`A_T1_*` agree with each other, `:3699–3723`) | yes (the CPU certifies from scratch) | prefixes at a 2^30 or 2^24 boundary | 4 |
| G7/G8 positions, records | no (bits are conserved even when they name the wrong child) | yes if systematic | partial last chunk, carried rest, second instance | 5 |
| G3 digit table | no | yes if systematic | 17-digit tops; an empty mask (none at b64) | 6 |
| G6 windows | yes by count (`:368–370`, `:3739–3744`) | content only | a job above 576 probes: ~1 slice in 1,024 (DESIGN §6.12), 63 % after 1,000 fields | 7 |
| G5 order, key | sort losses mostly yes (`A_CHILD` = `A_SC_CHILD`, `:3745–3749`) | — | order cannot lose a survivor (G5b) | 8 |
| G2, G9, G10 | partly (probe count) | yes: systematic | none (static facts) | 9 |

So the ranking for proof value is G4, G1, G7/G8 (silent, cheap, exercised on every slice); G11 and G12 are as
silent but their risk lives in the arithmetic, which a proof at reasonable price cannot reach.

## 4. The device model

**Definitions** (`NiceMidOut/Device.lean`, one function per stage, on the existing `Join.lean` types):
`devCoarse q`, `devTops pip` (G1, with `topCertScan` at fixed positions), `devSegs`, `devProbes` (G2), `encode`,
`decode17` (G3), `anc8 k8`, `devParents rank pip src` (G4), `devOrder rank` (G5), `devJobs`, `windows` (G6),
`devChildList`, `devChunks` (G7), `records`, `expand` (G8), `devEntryN` (G10), `devPf` (G11), `devSlice rank pip`,
and `deviceSearchField c vs vz rank : Option FieldOutcome` (G13; the device passes the first slice's rank), refusing
what `field_run` refuses (`:4081–4094`). The check stays `finalCheck` (G12 is not modelled).

**Theorem**, an equality of outcomes, the host's runtime guards as hypotheses:
```
structure Guards (c : Coord) (vs vz : ℕ) : Prop where   -- each discharged at run time by a host check
  probes  : ∀ pip c' d, (devProbes … c' d).length ≤ 1152                -- :368–370, :3739–3744
  classes : ∀ pip c', ((devOrder …).filter (·.cls = c')).length ≤ 65536  -- :433–435
  pop     : ∀ pip d t, (d, t) ∈ devTops pip → t.mask.card ≤ 17         -- :3587–3591
  caps    : …                                                -- :2756–2760, :3564–3568, :3601–3612
theorem deviceSearchField_eq (hc : Coord.withDigits 64 4 8 5 = some c) (hg : Guards c vs vz) (rank : List ℕ) :
    deviceSearchField c vs vz rank = searchField c ⟨4, 10⟩ vs vz
```
Free device orders enter as "for any `l' ~ l`" in the stage lemmas. With `no_nice_of_searched_withDigits`: empty
device outcomes on fields covering base 64 mean no nice number in base 64 — **under the model**.

**Tying it to the Rust without a card.**
- *Host mirrors that exist:* `slice_tops` (`:2372–2443`, tops in the device's layout and the rank), `top_cert_b64`
  (`:2291–2308`, tested on 20,000 prefixes, `:4319`), `parent_mask`, `root_mask`, `depth4_roots` (`:2311–2343`), the
  job table (`:2767–2783`). Dumpable like the reference's fixtures (`common/examples/midout_lean_fixtures.rs` on
  `lean/midout`), but they are mirrors, not the kernels.
- *The kernels themselves* run on lavapipe (DESIGN §2 stage 3, §4; "lavapipe will do", `:4614`); `run_slice_dev`
  already reads back tops (`:3206–3216`) and entries (`:3233–3241`). A dumper would add `l5`/`l5n` (G1), `g_rec`,
  `g_pseg` (G4, G5: lists), `clst` (G7: list), `out`, `slabcnt` (G8: multiset), `surv` (G10, G11). Not written;
  Rust on `dev/mo-clean`, its owners' decision.
- *Untested without a card:* plane widths 32 and 64 (lavapipe runs 8; `:546–563`, `:589–611`), NVRTC and ACO, CUDA's
  `pf` (lavapipe can be forced to run `pf`, `:4733–4736`), buffer reuse on the stream (`:3043–3068`), real
  allocation failures, the check on any nice input. No workflow on `dev/mo-clean` mentions `midout`; the device
  tests sit behind the feature `midout-box-tests`.

## 5. Size, order, risks

**Basis** (existing `lean-midout/NiceMidOut/`): `TopsProofs` 265 + `TopsScan` 261 lines for the reference's tops;
`BottomsExact` 301, `BottomsNodup` 116, `BottomsKids` 56 for parents and children; `RunProofs` 218 (run form),
`Pairing` 106, `Prefilter` 131, `EndToEnd` 188; definitions `Join.lean` 324; `Conformance.lean` 372; 3,754 in all.

| step | items | Lean lines (est.) |
|---|---|---|
| 1 definitions | `Device.lean` | 250–350 |
| 2 tops | G1 (a–c), G3's non-empty mask, G9 | 250–400 |
| 3 parents | G4, G5(b) | 180–300 |
| 4 jobs and probes | G2, G6 | 100–200 |
| 5 children, records, expansion | G7, G8 | 250–400 |
| 6 entries, prefilter rule | G10, G11(a, b) | 80–150 |
| 7 field | G13, `deviceSearchField_eq`, base corollary | 150–250 |
| 8 conformance | device stages against dumped tables | 200–350 (+ Rust dumper 200–400) |
| optional | G3 encode/decode, G5(a), G12 gate and `magic` | 250–450 |

Total for steps 1–8: **about 1,500–2,500 lines**; the wide path roughly +40 %.

**The audit's lessons, built in.**
- *Whole-object statements:* `∈ ↔` and `~` per stage, not positional lemmas (REVIEW B4).
- *No conditional vacuity:* prove `deviceSearchField_isSome_iff` (accepts exactly what `field_run` accepts, REVIEW
  B1) and instantiate the theorem at base 64's coordinate by `decide` as `b64_instance` does; show in the conformance that the
  guards hold on the dumped slices.
- *A mutant per lemma*, each to break a lemma in the closure and be caught by the conformance: coarse interval
  2^29; coarse key `pip >> 5`; positions 24/36; shared-list key over digits 4–8; class without the pip term; second
  window at 575/577; chunk of 63; record position + 1; `r0hi` dropped; prefilter mod 2^66; `nice` as a set
  difference. REVIEW M9 (a check accepting one more number passed every fixture): plant inputs, not only real slices.
- *Tested = proved:* the conformance imports `Device.lean`; no second copy of a definition.
- *Price:* one whole base-64 reference slice did not finish in 45 minutes (README); compare per stage on samples.

**Risks.** (1) Overselling: the theorem is about a model of intent; the kernels meet it only on dumped samples. (2) A
model written from comments, not code: each definition cites the lines it mirrors. (3) `Finset` statements would hide a
duplicated survivor. (4) Steps 2, 3, 5 hold most proof risk; step 8 needs a Rust dumper that does not exist.

## 6. Recommendation

**Prove first, if only a few sessions are spent:**
1. **G1, the tops hierarchy at base 64** (containment, fixed digit lengths, no clipping, non-empty masks). Silent to
   every account, exercised on every slice, and its exactness ("a finer interval keeps every digit its parent
   certified", `:1916–1918`) is marked [proven] in DESIGN §2 on an informal argument only. Cheap: the scan
   (`topCertScan_eq`) and the position characterisation (`mem_certPositions_iff`) exist. It also settles G3's
   unguarded empty-mask case at base 64.
2. **G4 with G5(b), the shared parent lists and key independence.** The structurally weakest point of the sampled
   check (the rerun is unshared, so only two counts of one slice per field see a list error), on by default for
   every field of the default coordinate, and short: `lowDistinct_congr` and `mem_parents_iff` do the work, and
   G5(b) is the existing 30-line permutation proof with the rank made a parameter.
3. **G7 + G8, child lists, records and expansion**, if a third session is available: it is where a wrong position
   silently replaces a survivor by another number while every count still agrees.

**Leave to tests:** G11(c), `pf` and `pf24` against `cpu::prefilter` on random and carry-edge n, both forms forced on
lavapipe and on a card; G12, production's check, by its existing `CHECK_COUNT` mode (four words per entry: distinct
digits, gate, mask, `cubecl_join.rs:3464–3468`) compared with `unique_digits`' distinct count on the sampled slice's
entries, which would test the verdict's arithmetic on every survivor rather than on nice numbers that do not occur;
G3's encoding, the transposes and ballots, and the accounts (already fault-injected, `audit.rs`). The wide path:
after base 64, starting with W3 (`wrec_top`), which is silent and has no base-64 counterpart.

## 7. Limits of this scope

Narrow path read in full (kernels, host driver); wide path: header and W1–W7's functions only. Lines at `eb9ef776` / `05747baa`
(`lean-midout` had an uncommitted `README.md` change, not mine). Nothing compiled; G3's arithmetic is by hand. No tool refused.
