# cbx.kernel

**CB X-ray Kernel.** Experimental ES+ research instrument. Version **0.1.0**.

`cbis.kernel` remains the production letter engine. `cbx.kernel` is deliberately separate: it looks *through* the production cover and records what every lane would have done even when W already solved the prime.

The design note is [`../ES-plus/CBIS-K-PARAMETER-STATUS.md`](../ES-plus/CBIS-K-PARAMETER-STATUS.md). The first clean census is [`../ES-plus/CBX-INITIAL-XRAY-CENSUS.md`](../ES-plus/CBX-INITIAL-XRAY-CENSUS.md).

## What it measures

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

“Production-equivalent” here means the same mathematical W/I/N/L predicates and ordering at the same finite grade. CBX intentionally uses exact 64-bit factorization, so at ranges where the older cbis bounded trial-factor fallback can misfactor a residual composite, CBX follows the mathematics rather than reproducing that implementation defect.

## Search grade

CBX does not pretend that one scalar `K` describes the complete finite search. A run stores

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

## Signal-atomic and crash-safe runtime

The arithmetic/search core is `src/cbx.c`. The executable is built through `src/cbx_runtime.c`, which gives the hunt stricter preservation semantics:

- once a prime enters the X-ray probe, all of its lane verdicts finish before SIGINT/SIGTERM is honored;
- an interrupted sweep stores the last fully processed integer rather than jumping to the end of the requested window;
- an interrupted home walk stores the first unprocessed `S`;
- the home cursor is a strict next-`S` cursor and uses a non-wrapping end-of-domain sentinel;
- `--iterations N` gives a deterministic finite number of complete sweep/home cycles, so formal censuses do not require timeout termination;
- only one writer may own a named run at a time; the POSIX advisory lock is automatically released if the process crashes;
- on restart, a crash-truncated final JSON append is trimmed before new observations are written;
- complete observations from a crashed, uncheckpointed batch may be replayed rather than skipped; `analyze.py` deduplicates them by target and grade;
- unique-letter counts are reconciled from per-run letter markers at startup, so a crash between letter storage and the next seed checkpoint cannot permanently undercount the run;
- exact `policy_scale` values are serialized with 17 significant digits rather than a display-rounded grade;
- numeric CLI values are parsed strictly instead of silently turning malformed input into zero;
- Lane-N Jacobi evaluation is unsigned-64-safe rather than casting a large prime through `int64_t`.

This boundary matters because a partially evaluated target must never be serialized as a mathematical miss, and a hard crash must prefer harmless replay over skipped search space.

The runtime resolves the binary directory through `/proc/self/exe` on Linux and falls back to the invoked executable path on other POSIX systems such as macOS.

## Adaptive-I policies

The default is fixed:

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

They choose a realized Lane-I bound below the configured `--i-max`. They are **not theorem-backed universal bounds** and do not change that claim boundary.

## Exact arithmetic

CBX uses deterministic 64-bit Miller-Rabin primality and Pollard-rho factorization rather than the bounded trial-factor fallback used by the current cbis implementation. The goal is to keep factor decomposition exact across the unsigned 64-bit arithmetic domain used by the kernel.

## Commands

```sh
make
make check
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

Full grade controls:

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

## Output

Each named run writes append-only JSONL observations under

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

`analyze.py` converts the append-only observation stream into the empirical objects needed for the adaptive-K research program. It reports first-depth distributions for:

- all targets;
- `R`;
- fab-only targets;
- linear W hits;
- spectra A, B and C.

For I, N and L it reports hit rate plus minimum, median, p90, p99 and maximum observed first depth.

It also computes the running observed Lane-I frontier

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

It also computes, automatically, a **conservative finite observed scale** for each built-in policy family:

\[
c_{\mathrm{obs}}
=\max_{p\ \mathrm{observed}}
\frac{k_I^*(p)}{B(p)},
\]

where `B(p)` is `log p`, `(log p)^2`, or the spectrum-weighted logarithmic basis. It reports both the all-target and `R`-only scale and the exact prime that forces each maximum. These are calibration statistics only, not asymptotic statements.

This is the empirical-to-theorem bridge: measure the hidden depth distribution, track new records, fit candidate envelopes, then try to destroy them before attempting a proof with the defect/spectrum machinery.

## CI regression gate

`.github/workflows/cbx-kernel.yml` builds and exercises CBX on both Linux and macOS. The gate checks:

- clean build and self-test;
- analyzer syntax;
- the root `./centl es cbx` launcher;
- the known 2521 X-ray semantics;
- a deterministic finite census;
- analyzer output;
- immutable named grades.

Runtime state, observations, letter markers and the built binary remain ignored artifacts rather than source changes.

## First clean census

At the default grade, a deterministic sweep through cursor `234,540,000` produced `401,752` hard-prime X-rays and zero production letters. Lane I and the current N lane each hit every observed target. The finite observed Lane-I record was

\[
k_I^*=107
\quad\text{at}\quad
p=8,803,369.
\]

Inside `R`, the Lane-I p99 was `27` and the finite maximum was again `107`.

These are finite records only. See `CBX-INITIAL-XRAY-CENSUS.md` for the exact counts, source blobs and raw-stream checksum.

## Claim boundary

CBX is an instrument for discovering structure in the hidden I/N/L depth distribution. A finite miss is not an Erdős–Straus counterexample. A finite empty letter spectrum is not a proof.