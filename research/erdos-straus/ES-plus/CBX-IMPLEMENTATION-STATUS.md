# CBX implementation status

**Status:** active experimental ES+ research kernel  
**Date:** 2026-08-15  
**Kernel:** `cbx.kernel 0.1.0`  
**Primary platform:** Fedora-family GNU/Linux  
**Secondary portability check:** Ubuntu GNU/Linux  
**Production boundary:** `cbis.kernel 1.2.0` remains the production ES-LETTER engine  
**Claim boundary:** this note records software, exact finite operation counts, and finite empirical measurements. It does not prove an adaptive K law or the Erdős–Straus conjecture.

---

## 1. Why CBX exists separately from cbis

`cbis.kernel` is the production hunt. It asks whether the configured finite cover disposes of a Mordell-hard prime and correctly stops later lanes from affecting the verdict once an earlier lane has solved the target.

`cbx.kernel` is the research instrument. It asks what structure is hidden underneath that operational verdict.

The production ordering remains

\[
W\to I\to N\to L,
\]

but CBX independently measures the later lanes even when W already hits. It also contains finite Lane-I research engines that transpose the same signed-box work into different traversal orientations.

`cbis.kernel` state and semantics are not mutated by CBX development.

---

## 2. Finite search grade

The complete finite search is not described honestly by one scalar K. CBX records

\[
\boxed{\Gamma=(F,K_I,E_N,A_L)}
\]

with default

\[
\boxed{(11,400,300,400).}
\]

Here:

- `F` is the coprime fab edge;
- `K_I` is the signed-box Lane-I ceiling;
- `E_N` is the external-NR ceiling;
- `A_L` is the López-layer ceiling.

Named X-ray runs have immutable grades. A different grade requires a different run name. `--k-max K` remains only a compatibility shortcut setting `K_I=A_L=K`.

ES-LETTER-v1 identity remains attached to the prime/event. Exact finite search strength is recorded separately as grade provenance.

---

## 3. Arithmetic and preservation core

`src/cbx.c` supplies:

- deterministic 64-bit Miller–Rabin primality;
- Pollard-rho factorization;
- Mordell-hard classification and spectra A/B/C;
- W linear/R/fab predicates;
- signed-box vacancy and Lane-I recognition;
- external-NR Lane N;
- López Lane L;
- ES-LETTER-v1 identity primitives.

CBX intentionally follows the mathematical finite cover rather than reproducing eventual cbis implementation defects. In particular, it does not inherit the bounded trial-factor fallback that can become unsafe at very large cbis inputs.

`src/cbx_runtime.c` adds preservation semantics:

- target-atomic SIGINT/SIGTERM handling;
- sweep cursor = last fully processed integer;
- home cursor = first unprocessed S;
- no uint64 cursor wrap;
- deterministic `--iterations N` runs;
- one POSIX writer lock per named run;
- crash-truncated JSONL tail repair;
- replay rather than skip after an uncheckpointed hard crash;
- unique-letter count reconciliation from durable markers;
- strict numeric parsing;
- exact `policy_scale` serialization;
- unsigned-64-safe external-NR Jacobi evaluation.

The clean initial X-ray census is permanently tied to the exact source/runtime blobs recorded in `CBX-INITIAL-XRAY-CENSUS.md`.

---

## 4. Three exact Lane-I traversals

All three finite Lane-I engines target the same predicate and preserve the same minimal first shift

\[
k_I^*(p)=\min\{k:\delta_k((p+k)/4)=0\}.
\]

### 4.1 p-major recognition

`cbx-forward-i`

\[
\boxed{p\to k\to C=(p+k)/4}
\]

This is the reference work order. Each hard prime is outermost and shifts are tested in increasing order until the first hit or exhaustion.

### 4.2 C-major construction

`cbx-inverse`

\[
\boxed{k\to C\to p=4C-k}
\]

For hard residue

\[
h\in\{1,121,169,289,361,529\}\pmod{840}
\]

and admissible `k`, only

\[
C\equiv\frac{h+k}{4}\pmod{210}
\]

can generate a hard target. Thus each k has six compatible C classes modulo 210.

Two exact C-major modes are retained:

- `--strict-c-first`: factor every compatible C before consulting the target set;
- default `--target-gated`: generate p from `(k,C)`, then cheaply reject non-target, already-covered, or non-coprime candidates before factoring C.

The gates do not change membership or the first k because k is processed monotonically upward.

### 4.3 shift-major survivor traversal

`cbx-shift-i`

\[
\boxed{k\to p\to C=(p+k)/4}
\]

The shift is outermost. Each finite segment starts from the exact Mordell-hard prime target set. At a given k, only still-uncovered targets are active. When a target hits, it is removed from the frontier immediately.

This exposes all unresolved targets at one shift simultaneously without paying the C-major compatible-residue traversal tax.

---

## 5. Executable equivalence invariant

Both C-major and shift-major support `--verify` against p-major recognition.

For every hard prime in the finite corpus CBX requires:

\[
\text{cover membership agreement}
\]

and, when covered,

\[
\text{minimal first-k agreement}.
\]

The mandatory Fedora/Ubuntu smoke corpus is

\[
2\le p\le100{,}000,
\qquad K_I=80.
\]

It contains 273 Mordell-hard primes. Current regression checks require zero mismatches for both alternative traversals.

For shift-major the finite work-set equalities are also required:

\[
\boxed{\rho_F^{\rm shift}=1}
\]

and

\[
\boxed{\rho_V^{\rm shift}=1},
\]

where `rho_F` compares factorizations with p-major recognition and `rho_V` compares active shift-major visits with p-major shift candidates.

---

## 6. Three-way Fedora benchmark

The canonical benchmark note is `CBX-LANE-I-ORIENTATION-BENCHMARK.md`.

At

\[
X=100{,}000,
\qquad K_I=80,
\]

exact operation counts give:

### Strict C-major

\[
\boxed{\rho_F^{\rm strict}=20.198020.}
\]

The literal constructive algorithm spends about 20.2 times as many expensive signed-box factorizations as p-major recognition on this corpus.

### Target-gated C-major

\[
\boxed{\rho_F^{\rm gated}=1.000000}
\]

while raw compatible-C enumeration remains

\[
\boxed{\rho_C^{\rm gated}=20.198020.}
\]

Target gating therefore removes the expensive-arithmetic waste completely, leaving cheap traversal overhead.

### Shift-major

\[
\boxed{\rho_F^{\rm shift}=1.000000,
\qquad
\rho_V^{\rm shift}=1.000000.}
\]

A canonical Fedora three-repeat microbenchmark measured median wall ratio

\[
\rho_t^{\rm shift}=0.992221,
\]

while a later CI repetition measured approximately `1.011994`. The correct interpretation is **practical timing parity**, not a universal speed advantage.

This shifts the optimization question from “forward or inverse?” to:

> which orientation should each portion of Lane I use, and what structure becomes exploitable when k is outermost?

---

## 7. Per-shift telemetry

`cbx-inverse --layers FILE` now emits aggregate telemetry for every admissible k:

```text
k
C_candidates
hard_targets
skipped_non_target
skipped_covered
skipped_non_coprime
factorizations
delta_hits
new_covered
```

`analyze_layers.py` reports:

- productive shifts;
- shifts that factor work but add zero new coverage;
- shifts that perform zero factorization because the frontier is already empty;
- marginal new-cover/factorization efficiency;
- cumulative cover and factorization counts;
- highest-yield and highest-dead-work layers.

On the Fedora smoke corpus through `K_I=80`:

- 20 admissible shifts are represented;
- 8 are productive: `3,7,11,15,19,23,27,31`;
- dead-with-factorization layers: `0`;
- all later tested layers do zero expensive work because the finite frontier has already emptied.

Leading marginal cover counts include:

```text
k=3   new=87   factorizations=273
k=11  new=83   factorizations=131
k=7   new=55   factorizations=186
k=19  new=16   factorizations=37
k=23  new=15   factorizations=21
```

This small corpus therefore provides **no evidence for an active dead shift that can simply be deleted**. Finite zero marginal coverage is never promoted to a redundancy theorem.

---

## 8. X-ray adaptive-K program

The perpetual X-ray runtime supports experimental Lane-I schedules:

```text
fixed
log
log2
spectrum-log
```

with explicit `policy_scale` and hard `K_I` cap.

`analyze.py`:

- deduplicates overlapping/replayed observations by target and grade;
- reports all/R/fab-only/linear/A/B/C strata;
- reports I/N/L hit rates and first-depth distributions;
- computes the running observed frontier `K_obs(X)`;
- computes a separate R-only record sequence;
- mechanically falsifies candidate K laws;
- computes conservative finite observed scales for the built-in policy families;
- tolerates only a crash-truncated final JSON record, while malformed complete records remain hard errors.

The first clean default-grade X-ray census reached

```text
sweep cursor:       234,540,000
hard-prime X-rays:  401,752
production letters: 0
```

with finite observed record

\[
\boxed{k_I^*=107\text{ at }p=8{,}803{,}369.}
\]

Inside R, Lane-I p99 was 27 and the finite maximum was again 107.

The candidate

\[
K(p)=\lceil2\log p\rceil
\]

fails 244 of 102,502 measured R targets in that corpus.

---

## 9. Fedora-first CI architecture

CBX intentionally does not spend research effort on macOS or Windows support unless compatibility falls out naturally.

### Mandatory regression workflow

`.github/workflows/cbx-kernel.yml`

Primary lane: Fedora-family GNU/Linux.  
Secondary lane: Ubuntu GNU/Linux.

It checks:

- build and runtime self-test;
- known X-ray semantics;
- deterministic finite X-ray runs;
- immutable grade rejection;
- C-major equivalence;
- shift-major equivalence;
- three-orientation operation-count invariants;
- per-k telemetry parsing;
- adaptive-policy analyzer output.

### Deep research census workflow

`.github/workflows/cbx-research-census.yml`

This is a manually parameterized Fedora research workflow with inputs for:

```text
X
K_I
segment size
benchmark repetitions
```

Its default research expedition is

\[
X=10{,}000{,}000,
\qquad K_I=160,
\]

chosen specifically to include the current `k_I*=107` record.

It preserves as a GitHub Actions artifact:

- environment/commit metadata;
- target-gated inverse summary;
- exact per-k telemetry TSV + analyzed JSON;
- exact inverse hit/residual sets;
- exact shift-major hit/residual sets;
- exact p-major hit/residual sets;
- three-way benchmark JSON;
- concise research summary JSON;
- SHA-256 manifest.

The workflow requires byte-for-byte hit and residual set identity among all three traversals before publishing the artifact.

---

## 10. Root operator surface

From the repository root:

```sh
# perpetual X-ray engine
./centl es cbx go
./centl es cbx probe 2521
./centl es cbx status

# exact finite Lane-I traversals
./centl es cbx forward-i --hi X --i-max K
./centl es cbx inverse --hi X --i-max K
./centl es cbx shift-i --hi X --i-max K

# benchmarking / analysis
./centl es cbx bench --hi X --i-max K --repeat 3
./centl es cbx analyze --run NAME
./centl es cbx analyze-layers layers.tsv
```

CBX state remains separate from cbis state.

---

## 11. Current research frontier

The implementation question is no longer whether the inverse cover can be built. It can, and two different k-major traversals now agree exactly with p-major recognition on the regression corpus.

The immediate research questions are:

1. What does the per-k first-hit/marginal-cost distribution look like on a corpus large enough to reach k=107 and beyond?
2. Do any shifts remain active, pay factorization cost, and add zero new coverage on larger corpora?
3. Can such finite patterns be upgraded to actual signed-box shadow/absorption theorems?
4. Can defect, spectrum, factor-pattern, or residue structure reject candidates before Pollard-rho work?
5. Does some subset of shifts favor C-major generation while others favor shift-major traversal?
6. Can a measured per-shift scheduler beat both p-major and shift-major without changing the exact finite cover?
7. Can the eventual K rule be derived from defect/spectrum theory rather than fitted from finite data?

The current engineering hypothesis is therefore a **hybrid Lane-I scheduler**, not one globally privileged loop order.

---

Erdős–Straus remains open. CBX is an exact finite research instrument, not a proof engine.