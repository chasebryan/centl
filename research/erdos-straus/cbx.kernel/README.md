# cbx.kernel

**CB X-ray Kernel.** Experimental ES+ research instrument. Version **0.1.0**.

`cbis.kernel` remains the production letter engine. `cbx.kernel` is deliberately separate: it looks *through* the production cover, measures hidden lane geometry, and now also implements the constructive finite Lane-I inverse cover.

Primary platform: **Fedora-family GNU/Linux**. Ubuntu is retained as a secondary Linux portability check. macOS and Windows are not CBX support targets.

Start with:

- [`../ES-plus/CBIS-K-PARAMETER-STATUS.md`](../ES-plus/CBIS-K-PARAMETER-STATUS.md) — K/search-grade audit;
- [`../ES-plus/CBX-IMPLEMENTATION-STATUS.md`](../ES-plus/CBX-IMPLEMENTATION-STATUS.md) — current software/research status;
- [`../ES-plus/CBX-INITIAL-XRAY-CENSUS.md`](../ES-plus/CBX-INITIAL-XRAY-CENSUS.md) — first clean finite X-ray census.

## Two research orientations

CBX intentionally supports two different finite experiments.

### X-ray orientation

For each Mordell-hard prime, CBX records:

- W linear hit status;
- membership in the residual `R`;
- first deterministic coprime `fab(a,b)` hit through the configured fab edge;
- Lane-I first signed-box hit
  \[
  k_I^*(p)=\min\{k:\delta_k((p+k)/4)=0\};
  \]
- Lane-N first external nonresidue prime and realized shift;
- Lane-L first López layer and modulus;
- the ordinary stacked production verdict `W -> I -> N -> L`.

The later lanes are evaluated **even when W hits**. Their results are X-ray diagnostics; they do not weaken or reorder the production verdict.

### Constructive inverse-I orientation

`cbx-inverse` implements the finite signed-box construction

\[
k\to C\to p=4C-k.
\]

For a fixed admissible `k` and one of the six Mordell-hard classes

\[
h\in\{1,121,169,289,361,529\}\pmod{840},
\]

only the corresponding `C` class

\[
C\equiv\frac{h+k}{4}\pmod{210}
\]

can generate a hard target. Therefore the inverse engine enumerates exactly six `C mod 210` classes per admissible shift.

The order is deliberate:

1. choose `k`;
2. enumerate compatible `C`;
3. evaluate `delta_k(C)`;
4. form `p=4C-k` only for a generated hit;
5. mark it if it belongs to the finite hard-prime universe.

This is genuinely `k -> C -> p`; it is not the p-first recognition loop with variables renamed.

`--verify` intentionally performs the redundant p-first Lane-I recognition afterward and requires both cover membership and the **minimal first k** to agree for every hard prime in the interval. A mismatch returns nonzero.

The first CI equivalence census through `100,000` at `K_I=80` passed on GNU/Linux with zero mismatches. That validates the implementation on that finite corpus; it is not a proof of the underlying theorem.

## Search grade

CBX does not pretend that one scalar `K` describes the complete finite search. A perpetual X-ray run stores

\[
\Gamma=(F,K_I,E_N,A_L),
\]

with defaults

```text
F    = 11
K_I  = 400
E_N  = 300
A_L  = 400
```

A named run has an immutable grade. If you want another grade, start another run name. This prevents one corpus from silently mixing different finite strengths.

`--k-max K` is a compatibility convenience that sets both `K_I` and `A_L`; the independent flags are preferred for research.

The inverse-I census uses only `K_I`, because it is specifically constructing the signed-box Lane-I cover rather than the complete W/I/N/L verdict.

## Signal-atomic and crash-safe X-ray runtime

The arithmetic/search core is `src/cbx.c`. The perpetual executable is built through `src/cbx_runtime.c`, which gives the X-ray hunt stricter preservation semantics:

- once a prime enters the X-ray probe, all of its lane verdicts finish before SIGINT/SIGTERM is honored;
- an interrupted sweep stores the last fully processed integer rather than jumping to the end of the requested window;
- an interrupted home walk stores the first unprocessed `S`;
- the home cursor is a strict next-`S` cursor and uses a non-wrapping end-of-domain sentinel;
- `--iterations N` gives a deterministic finite number of complete sweep/home cycles, so formal censuses do not require timeout termination;
- only one writer may own a named run at a time; the POSIX advisory lock is automatically released if the process crashes;
- on restart, a crash-truncated final JSON append is trimmed before new observations are written;
- complete observations from a crashed, uncheckpointed batch may be replayed rather than skipped; `analyze.py` deduplicates them by target and grade;
- unique-letter counts are reconciled from per-run letter markers at startup;
- exact `policy_scale` values are serialized with 17 significant digits;
- numeric CLI values are parsed strictly;
- Lane-N Jacobi evaluation is unsigned-64-safe.

A hard crash therefore prefers harmless replay over skipped search space.

The finite inverse-I census does not share perpetual-run state. Its interval and optional outputs are explicit arguments, so a large census can be partitioned into deterministic segments without contaminating X-ray state.

## Adaptive-I policies

The default X-ray policy is fixed:

```text
--k-policy fixed
```

Experimental policies are available for data collection only:

```text
--k-policy log
--k-policy log2
--k-policy spectrum-log
--policy-scale C
```

They choose a realized Lane-I bound below the configured `--i-max`. They are **not theorem-backed universal bounds**.

## Exact arithmetic

CBX uses deterministic 64-bit Miller-Rabin primality and Pollard-rho factorization rather than the bounded trial-factor fallback used by the current cbis implementation. The goal is to keep factor decomposition exact across the unsigned 64-bit arithmetic domain used by the kernel.

“Production-equivalent” means the same mathematical W/I/N/L predicates and ordering at the same finite grade. CBX does not intentionally reproduce a cbis implementation defect at ranges where cbis’s bounded trial-factor fallback can misfactor a remaining composite.

## Build

```sh
make
make check
```

This builds both:

```text
cbx          # perpetual X-ray runtime
cbx-inverse  # finite constructive Lane-I cover
```

## X-ray commands

```sh
./cbx self-test
./cbx probe 2521
./cbx solve 9658489

./cbx go
./cbx go --run deep-I --i-max 2000
./cbx go --run adaptive-a --i-max 5000 --k-policy log2 --policy-scale 2.0
./cbx go --home-only
./cbx go --sweep-only

# exact finite census: 46,908 complete sweep batches
./cbx go --run formal --step 5000 --iterations 46908 --sweep-only

./cbx status
./cbx status --run deep-I
```

From the CENTL root:

```sh
./centl es cbx self-test
./centl es cbx probe 2521
./centl es cbx go --run deep-I --i-max 2000
```

Full X-ray grade controls:

```text
--fab-max F
--i-max K
--n-ell-max E
--l-max A
--k-max K
--k-policy fixed|log|log2|spectrum-log
--policy-scale C
```

Run controls:

```text
--run NAME
--step N
--iterations N
--random
--sweep-only
--home-only
```

The `probe` and `solve` commands inherit a named run's saved grade unless explicit grade flags are supplied. `--random` only chooses the initial sweep cursor for a new named run; it is ignored on an existing run.

## Inverse-I commands

```sh
# Exact inverse cover on a finite interval
./cbx-inverse --hi 1000000 --i-max 400

# Same operation from the CENTL root
./centl es cbx inverse --hi 1000000 --i-max 400

# Verify inverse membership + minimal first k against recognition
./centl es cbx inverse \
  --hi 100000 \
  --i-max 80 \
  --segment 25000 \
  --verify

# Preserve exact generated first-hit and residual sets
./centl es cbx inverse \
  --hi 10000000 \
  --i-max 400 \
  --hits inverse-hits.tsv \
  --residuals inverse-residuals.txt
```

Inverse controls:

```text
--lo L
--hi X              required upper endpoint
--i-max K
--segment N         memory-bounded p interval, default 1,000,000
--verify
--hits FILE         p<TAB>minimal-first-k
--residuals FILE    one hard prime not hit by Lane I per line
```

The JSON summary reports:

```text
hard_primes
C_candidates
delta_hits
covered_hard_primes
residual_hard_primes
verification_targets
verification_mismatches
```

This is also the beginning of the performance audit. Exact constructive inversion is now implemented, but **it is not assumed to be faster**. `C_candidates` and the corresponding p-first workload must be benchmarked across increasing `X` and `K_I`.

## X-ray output

Each named X-ray run writes append-only JSONL observations under

```text
observations/<run>.jsonl
```

and its cursor/grade under

```text
state/<run>.seed
```

If a target survives the complete production-equivalent grade, CBX preserves the existing `ES-LETTER-v1` content-addressed identity. Exact finite grades are recorded separately in

```text
letters/GRADES.jsonl
```

so the identity of the prime/event is not confused with the strength of the finite experiment that observed it.

The state counter distinguishes observations from unique letters. `analyze.py` additionally deduplicates overlapping sweep/home observations and crash-replayed observations by target and grade.

## Analyze the X-ray stream

`analyze.py` reports first-depth distributions for:

- all targets;
- `R`;
- fab-only targets;
- linear W hits;
- spectra A, B and C.

For I, N and L it reports hit rate plus minimum, median, p90, p99 and maximum observed first depth.

It computes the running observed Lane-I frontier

\[
K_{\mathrm{obs}}(X)=\max\{k_I^*(p):p\le X\text{ observed}\},
\]

including a separate `R` record sequence.

If a hard crash leaves a partial final JSON append, the analyzer ignores only that incomplete EOF record and reports that it did so. An invalid complete record remains a hard error.

```sh
python3 analyze.py --run default
python3 analyze.py --run formal --json
```

### Falsify candidate K laws

Candidate policies can be tested offline against a stronger fixed-K observation stream:

```sh
python3 analyze.py --run formal \
  --candidate-policy log \
  --candidate-scale 2.0 \
  --candidate-R-only

python3 analyze.py --run formal \
  --candidate-policy log2 \
  --candidate-scale 0.5
```

The analyzer reports how many observed I depths violate the proposed policy, plus the first and worst finite failure. A policy that survives remains an empirical envelope, not a theorem.

It also computes a conservative finite observed scale for each built-in policy family:

\[
c_{\mathrm{obs}}
=\max_{p\ \mathrm{observed}}
\frac{k_I^*(p)}{B(p)},
\]

where `B(p)` is `log p`, `(log p)^2`, or the spectrum-weighted logarithmic basis. It reports both the all-target and `R`-only scale and the exact prime that forces each maximum. These are calibration statistics only, not asymptotic statements.

## CI regression gate

`.github/workflows/cbx-kernel.yml` uses **Fedora-family GNU/Linux as the primary regression platform** and Ubuntu as a secondary Linux check.

The gate checks:

- clean build and runtime self-test;
- the root `./centl es cbx` launcher;
- the known `2521` X-ray semantics;
- deterministic finite X-ray censuses;
- analyzer output and immutable grades;
- exact finite inverse-I generation;
- inverse-vs-recognition equality of cover membership and minimal first `k`.

macOS and Windows compatibility are natural byproducts only and do not drive CBX design or release decisions.

## First clean X-ray census

At the default grade, a deterministic sweep through cursor `234,540,000` produced `401,752` hard-prime X-rays and zero production letters. Lane I and the current N lane each hit every observed target. The finite observed Lane-I record was

\[
k_I^*=107
\quad\text{at}\quad
p=8,803,369.
\]

Inside `R`, the Lane-I p99 was `27` and the finite maximum was again `107`.

These are finite records only. See `CBX-INITIAL-XRAY-CENSUS.md` for the exact counts, source blobs and raw-stream checksum.

## Claim boundary

CBX is an instrument for discovering structure in hidden I/N/L depth distributions and for constructing finite signed-box covers. A finite miss is not an Erdős–Straus counterexample. A finite empty letter spectrum is not a proof. An inverse implementation that matches recognition is not, by itself, evidence that the inverse orientation is asymptotically faster.