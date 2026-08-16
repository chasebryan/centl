# cbx.kernel

**CB X-ray Kernel.** Experimental ES+ research instrument, version **0.1.0**.

`cbis.kernel 1.2.0` remains the production ES-LETTER-v1 hunt. `cbx.kernel` is deliberately separate: it X-rays hidden W/I/N/L geometry, constructs the finite Lane-I cover in multiple exact orientations, and measures the data needed to attack adaptive-K and hybrid-search questions without changing cbis production semantics.

Primary platform: **Fedora-family GNU/Linux**. Ubuntu is a secondary Linux portability check. macOS and Windows are not CBX support targets except where compatibility falls out naturally.

Start with:

- [`../ES-plus/CBIS-K-PARAMETER-STATUS.md`](../ES-plus/CBIS-K-PARAMETER-STATUS.md) — cbis K/search-grade audit;
- [`../ES-plus/CBX-IMPLEMENTATION-STATUS.md`](../ES-plus/CBX-IMPLEMENTATION-STATUS.md) — implementation/preservation status;
- [`../ES-plus/CBX-FORMULATION-2.md`](../ES-plus/CBX-FORMULATION-2.md) — preserved constructive-I-first orchestration from retired draft PR #246; no separate `cbx2.kernel` is maintained;
- [`../ES-plus/CBX-INVERSE-I.md`](../ES-plus/CBX-INVERSE-I.md) — constructive Lane-I cover;
- [`../ES-plus/CBX-LANE-I-ORIENTATION-BENCHMARK.md`](../ES-plus/CBX-LANE-I-ORIENTATION-BENCHMARK.md) — p-major/C-major/shift-major comparison;
- [`../ES-plus/CBX-INITIAL-XRAY-CENSUS.md`](../ES-plus/CBX-INITIAL-XRAY-CENSUS.md) — first clean hidden-lane census.

## What CBX separates

CBX treats the finite search as

\[
\Gamma=(F,K_I,E_N,A_L),
\]

with default

```text
F=11, K_I=400, E_N=300, A_L=400.
```

A named X-ray run has an immutable grade. `--k-max K` remains a compatibility convenience setting `K_I=A_L=K`; it is not the complete grade.

The production-equivalent verdict remains

```text
W -> I -> N -> L
```

but the X-ray runtime evaluates all lanes independently, so a W/fab hit does not hide later signed-box, external-NR, or López structure.

## Exact arithmetic

The shared core uses:

- deterministic 64-bit Miller–Rabin primality;
- Pollard-rho factorization across the unsigned 64-bit arithmetic domain;
- Mordell-hard residue and A/B/C spectrum classification;
- exact signed-box vacancy tests;
- W/R/fab predicates;
- Lane N and Lane L predicates;
- ES-LETTER-v1 identity compatibility.

CBX follows the mathematical finite predicates rather than reproducing the eventual bounded-trial-factor limitation in cbis 1.2.0.

## Five research surfaces

### 1. X-ray runtime

`cbx` measures every lane on each hard prime, even when W already solves it.

For Lane I it records

\[
k_I^*(p)=\min\{k:\delta_k((p+k)/4)=0\}.
\]

Example:

```sh
./centl es cbx probe 2521
./centl es cbx go --run deep-I --i-max 2000
./centl es cbx analyze --run deep-I
```

The runtime is signal-atomic and crash-preserving: an entered target finishes before SIGINT/SIGTERM is honored; named runs are single-writer locked; seed writes are atomic; a hard crash may replay an uncheckpointed batch but does not skip it; a truncated final JSON append is repaired at restart; `--iterations N` provides deterministic finite censuses.

### 2. C-major inverse Lane I

`cbx-inverse` implements the constructive orientation

\[
\boxed{k\to C\to p=4C-k.}
\]

For hard residue

\[
h\in\{1,121,169,289,361,529\}\pmod{840},
\]

only

\[
C\equiv(h+k)/4\pmod{210}
\]

can generate that hard class.

Two exact modes are retained:

```sh
# default: exact cheap gates before C factorization
./centl es cbx inverse --target-gated --hi 1000000 --i-max 400

# literal constructive baseline
./centl es cbx inverse --strict-c-first --hi 1000000 --i-max 400
```

`--verify` cross-checks cover membership **and minimal first k** against p-major recognition target-by-target. `--hits`, `--residuals`, and `--layers` preserve exact finite sets and per-k telemetry.

### 3. p-major Lane-I reference

`cbx-forward-i` is the stripped reference orientation

\[
\boxed{p\to k\to C.}
\]

It exists so work counts and hit maps can be compared without the other W/N/L machinery.

```sh
./centl es cbx forward-i --hi 1000000 --i-max 400
```

### 4. shift-major survivor frontier

`cbx-shift-i` transposes the active work set:

\[
\boxed{k\to p\to C.}
\]

For each increasing shift it walks only unresolved hard primes. Hits are removed from the active frontier before the next shift. This preserves exact minimal first-k semantics while exposing all unresolved targets for one k together.

```sh
./centl es cbx shift-i --hi 1000000 --i-max 400 --verify
```

On the finite Fedora benchmark at `X=100000, K_I=80`, shift-major had exactly the same factorization and active `(p,k)` work set as p-major, with wall time at practical parity.

### 5. per-shift profiler

`cbx-profile-i` measures each admissible shift as its own finite research object. For every k it records:

- unresolved active targets;
- exact signed-box factorizations;
- first hits;
- A/B/C first-hit counts;
- coprimality skips;
- compatible C values that a C-major traversal would enumerate.

```sh
./centl es cbx profile-i --hi 10000000 --i-max 400 > profile.json
./centl es cbx analyze-profile profile.json
```

`analyze_profile.py` reports first-hit depth p50/p90/p99, productive/dead shifts, first-hits-per-factorization, first-hits-per-C-candidate, spectrum mix, and ranked empirical targets for generator/theorem work.

These rankings are **not** an automatic optimal scheduler. They are finite evidence from which a scheduler or theorem can be proposed and then attacked.

## Build and regression

```sh
make -C research/erdos-straus/cbx.kernel
make -C research/erdos-straus/cbx.kernel check
```

The build produces:

```text
cbx             perpetual X-ray runtime
cbx-inverse     C-major finite Lane-I construction
cbx-forward-i   p-major finite Lane-I reference
cbx-shift-i     shift-major survivor traversal
cbx-profile-i   per-shift Lane-I profiler
```

The primary GitHub Actions gate is Fedora-family GNU/Linux, with Ubuntu secondary. It verifies exact first-k equivalence across the finite engines, profile accounting, known X-rays, deterministic runs, analyzer parsing, grade immutability, and three-way orientation benchmarks.

A separate Fedora research-census workflow preserves larger finite studies as hashed artifacts with exact hit/residual maps, environment metadata, profile data, benchmarks, and concise summaries.

## Orientation benchmark

Use:

```sh
./centl es cbx bench --hi 100000 --i-max 80 --repeat 3
```

or

```sh
python3 research/erdos-straus/cbx.kernel/bench_i.py \
  --hi 100000 --i-max 80 --repeat 3
```

The Fedora 44 three-repeat microbenchmark at `X=100000, K_I=80` found:

```text
strict C-major:
  factorization ratio vs p-major = 20.198020
  wall ratio                     = 12.190308

target-gated C-major:
  factorization ratio            = 1.000000
  C-enumeration ratio            = 20.198020
  wall ratio                     = 1.325060

shift-major:
  factorization ratio            = 1.000000
  active-visit ratio             = 1.000000
  wall ratio                     = 0.992221
```

The `0.992221` timing is interpreted as **practical parity within timing noise**, not a speed theorem. The structural result is more important: target gating removes the expensive C-major arithmetic waste; shift-major removes the remaining C-enumeration overhead.

## Per-k inverse telemetry

C-major can emit tab-separated layer telemetry:

```sh
./centl es cbx inverse \
  --hi 1000000 --i-max 400 \
  --layers layers.tsv

./centl es cbx analyze-layers layers.tsv
```

This records compatible C count, hard-target encounters, skip reasons, factorizations, signed-box hits, and **new** cover contributed by each k. Finite zero marginal cover is a theorem-hunting signal, not a redundancy theorem.

## Adaptive-K experiments

The X-ray runtime supports measurement policies:

```text
fixed
log
log2
spectrum-log
```

with explicit `--policy-scale` and hard `--i-max` cap. `analyze.py` can falsify candidate policies against stronger fixed-K streams and compute conservative observed envelope scales.

The first clean default-grade census reached sweep cursor `234,540,000`, recorded `401,752` hard-prime X-rays and zero production letters, with finite Lane-I record

\[
\boxed{k_I^*=107\text{ at }p=8,803,369.}
\]

Inside R the Lane-I p99 was `27`. The deliberately aggressive empirical rule `K(p)=ceil(2 log p)` fails 244 of 102,502 measured R targets. These are finite observations only.

## Research direction

The current algorithmic question is no longer simply “forward or inverse?”. CBX now measures three exact orientations. The next hypothesis is a **per-shift hybrid**:

\[
\text{hybrid Lane I}
=
\text{generated shifts}
+
\text{shift-major shifts}
+
\text{recognition fallback}.
\]

Per-shift profile evidence should decide what to test. Candidate structural gates include spectrum, residue, factor pattern, defect/stabilizer information, and any future direct generation of `delta_k(C)=0`.

A good finite scheduler remains an engineering hypothesis until separately proved.

## Claim boundary

Erdős–Straus remains open. A finite miss is not a counterexample. A finite empty letter spectrum is not a proof. `107` is an observed finite record, not a universal K bound. Exact agreement between traversal orientations validates software on finite corpora; it does not establish asymptotic superiority of any orientation.
