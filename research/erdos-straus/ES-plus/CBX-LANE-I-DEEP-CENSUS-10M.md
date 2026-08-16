# CBX Lane-I deep census — 10,000,000

**Status:** preserved exact finite research census  
**Date:** 2026-08-15  
**Kernel:** `cbx.kernel 0.1.0`  
**Primary platform:** Fedora 44 GNU/Linux  
**Finite domain:** Mordell-hard primes `p <= 10,000,000`  
**Lane-I ceiling:** `K_I = 160`  
**Source commit:** `2ca47f56179b2364f5d5ca9b8f765df1c6b94cf3`  
**GitHub Actions run:** `31928217803`  
**Artifact id:** `9258483327`  
**Artifact name:** `cbx-fedora-X10000000-K160-2ca47f56179b2364f5d5ca9b8f765df1c6b94cf3`  
**Artifact digest:** `sha256:be4574b1662bc856265233b8a95ce53afb1e67c61f1a6716824368be4a30b678`  
**Claim boundary:** every result below is finite. This note is not an adaptive-K theorem and is not a proof of Erdős–Straus.

---

## 1. Exact finite result

The census contains

\[
\boxed{20,513}
\]

Mordell-hard primes through `10,000,000`.

All three independently implemented Lane-I traversals agree exactly on the finite cover and on the minimal first shift of every covered target:

\[
\boxed{
\text{p-major}
=
\text{target-gated C-major}
=
\text{shift-major}
}
\]

as exact `p -> k_I^*(p)` maps.

The result is

\[
\boxed{20,513/20,513\text{ covered}}
\]

with

\[
\boxed{0\text{ Lane-I residuals through }K_I=160.}
\]

Both alternative traversals ran their independent `--verify` checks against p-major recognition and recorded zero mismatches.

The three emitted hit maps and the three emitted residual sets were then compared again by a separate canonical set/map checker before publication.

---

## 2. Exact expensive-work equality

The finite p-major recognizer performs

\[
\boxed{45,553}
\]

signed-box factorizations.

The target-gated C-major engine also performs exactly

\[
\boxed{45,553}
\]

factorizations, and shift-major performs exactly

\[
\boxed{45,553}.
\]

Thus

\[
\boxed{
\rho_F^{\rm gated}=1,
\qquad
\rho_F^{\rm shift}=1.
}
\]

Shift-major also performs exactly `45,553` active `(p,k)` visits, equal to the p-major shift-candidate count.

The strict C-enumeration tax remains visible in the target-gated engine's cheap traversal count:

\[
\texttt{C\_candidates}=2,857,160,
\]

so

\[
\boxed{
\rho_C
=\frac{2,857,160}{45,553}
=62.72166487388317.
}
\]

Target gating removes that tax from the expensive factorization set, but not from the integer/residue traversal itself.

---

## 3. Fedora timing benchmark

Three-repeat finite wall-clock medians on the preserved Fedora runner were:

```text
p-major       0.101441520 s
C-major       0.129474607 s
shift-major   0.101341961 s
```

Therefore

\[
\boxed{
\rho_t^{\rm C-major}=1.2763472688505186
}
\]

and

\[
\boxed{
\rho_t^{\rm shift}=0.9990185576874488.
}
\]

The shift-major timing is interpreted as **practical parity**, not as a universal speed advantage. Exact operation-count equality is the stronger result.

---

## 4. Productive first-hit shifts

Exactly 16 admissible shifts are productive on this finite corpus:

\[
\boxed{
3,7,11,15,19,23,27,31,35,39,43,47,51,55,59,107.
}
\]

Their exact first-hit counts are:

| `k` | new hard primes first covered |
|---:|---:|
| 3 | 8,590 |
| 7 | 4,779 |
| 11 | 4,463 |
| 15 | 949 |
| 19 | 883 |
| 23 | 541 |
| 27 | 91 |
| 31 | 152 |
| 35 | 17 |
| 39 | 22 |
| 43 | 5 |
| 47 | 15 |
| 51 | 1 |
| 55 | 2 |
| 59 | 2 |
| 107 | 1 |

The finite maximum is therefore

\[
\boxed{k_I^*=107.}
\]

The unique target realizing that maximum is

\[
\boxed{p=8,803,369.}
\]

This independently reproduces the current X-ray record inside an exact finite all-hard-prime census.

---

## 5. The frontier collapses to one prime

The cumulative cover is especially informative near the end:

```text
after k=47   covered 20,507   remaining 6
after k=51   covered 20,508   remaining 5
after k=55   covered 20,510   remaining 3
after k=59   covered 20,512   remaining 1
after k=107  covered 20,513   remaining 0
```

So after `k=59`, the entire finite frontier consists of one prime:

\[
\boxed{p=8,803,369.}
\]

That prime then survives every admissible shift

\[
63,67,71,75,79,83,87,91,95,99,103
\]

before finally hitting at `107`.

This creates a finite **single-prime gauntlet**:

\[
oxed{
59
<
63,67,\ldots,103
<
107.
}
\]

The eleven intervening shifts each perform exactly one signed-box factorization and add zero new hard prime.

---

## 6. Dead-with-factorization shifts

The exact finite dead-with-work set is

\[
\boxed{
D_{10^7,160}
=
\{63,67,71,75,79,83,87,91,95,99,103\}.
}
\]

Every one of these layers has the same finite interpretation:

- `20,512` targets are already covered;
- exactly one hard target remains active;
- one factorization is performed;
- `delta_k=0` is not achieved for that target;
- zero new coverage is added.

This is **not evidence that these shifts are universally redundant layers**.

It is evidence that the record prime `8,803,369` follows an unusually long local vacancy sequence immediately below its first hit at 107.

That distinction is now part of the research contract: finite zero marginal cover must not be promoted to a shadowing theorem without an independent proof.

---

## 7. Leading marginal coverage

The dominant early layers are:

| `k` | factorizations | new first hits | new/factorization |
|---:|---:|---:|---:|
| 3 | 20,513 | 8,590 | 0.418759 |
| 7 | 11,923 | 4,779 | 0.400822 |
| 11 | 7,144 | 4,463 | 0.624720 |
| 15 | 2,681 | 949 | 0.353972 |
| 19 | 1,732 | 883 | 0.509815 |
| 23 | 849 | 541 | 0.637220 |
| 27 | 308 | 91 | 0.295455 |
| 31 | 217 | 152 | 0.700461 |
| 35 | 65 | 17 | 0.261538 |
| 39 | 48 | 22 | 0.458333 |
| 43 | 26 | 5 | 0.192308 |
| 47 | 21 | 15 | 0.714286 |
| 51 | 6 | 1 | 0.166667 |
| 55 | 5 | 2 | 0.400000 |
| 59 | 3 | 2 | 0.666667 |
| 107 | 1 | 1 | 1.000000 |

These efficiencies are finite conditional statistics on the surviving frontier. They do not define a safe heuristic ordering by themselves.

---

## 8. What the deep census changes

The `100,000` smoke corpus could not distinguish “later layer is unnecessary” from “the frontier already ended.” The 10M corpus can.

It establishes three different finite phenomena:

1. **productive layers** that first cover one or more surviving targets;
2. **zero-work layers** reached only after a segment/frontier is already empty;
3. **dead-with-factorization layers** that evaluate a genuinely surviving target and fail to cover it.

Only the third category is potentially informative for future local obstruction/shadow theory, and here all eleven examples belong to the same record prime.

So the next mathematical target is not yet a theorem of universal layer absorption. It is the structure of the record-prime gauntlet:

\[
\boxed{
\delta_k\!\left(\frac{8,803,369+k}{4}\right)>0
\quad
\text{for }k=63,67,\ldots,103,
}
\]

followed by

\[
\boxed{
\delta_{107}\!\left(\frac{8,803,369+107}{4}\right)=0.
}
\]

That is a concrete finite object for the defect/spectrum machinery to explain.

---

## 9. Preserved artifact contents

The Actions artifact contains:

```text
ENVIRONMENT.txt
RESEARCH-SUMMARY.json
SHA256SUMS
canonical-hits.tsv
canonical-residuals.txt
forward-hits.tsv
forward-residuals.txt
forward-summary.json
inverse-hits.tsv
inverse-layers.tsv
inverse-residuals.txt
inverse-summary.json
layer-analysis.json
orientation-benchmark.json
shift-hits.tsv
shift-residuals.txt
shift-summary.json
```

Key SHA-256 values recorded inside the artifact manifest include:

```text
canonical-hits.tsv       0355a90d4956a6023514f7d1fad2d4767ac32cb41c29ac5075e7484061863b15
inverse-layers.tsv       2498a17bef0814753216368967ba4fbe5cf6fff55260297138335206a392d135
layer-analysis.json      27db4a17f8b0f2cb3b80a21b84dcde92cf04b2eab841e0b5f6f6b6ef5c2938f
orientation-benchmark    3c2724ae6a2f045156678eb8896f51148389000a053cd42eaf6b9495ff24ad21
RESEARCH-SUMMARY.json    f3cc6a687ef5902beb793903ddfcb30dd2a3e78493438048ea7c7368fff9b849
```

The GitHub artifact archive itself is additionally identified by

```text
sha256:be4574b1662bc856265233b8a95ce53afb1e67c61f1a6716824368be4a30b678
```

and expires from GitHub Actions storage on 2026-11-14 unless separately archived.

---

## 10. Next experiment

The deep census pipeline has already been extended for the next run to include full per-shift profiling and a larger default `K_I=400` ceiling.

The next exact questions are:

1. Does the productive set remain unchanged when the ceiling extends from 160 to 400 on the same 10M corpus?
2. Do any shifts above 107 perform active work, or is the frontier provably empty there for this corpus?
3. How do first-hit depth quantiles split by spectrum A/B/C?
4. Which shifts maximize conditional generation density and shift-major first-hit efficiency?
5. Can the `63..103` gauntlet for `8,803,369` be explained by a defect/factor-pattern statement rather than brute vacancy evaluation?
6. Does the next larger X frontier create more high-depth gauntlets, or is `107` unusually isolated?

---

Erdős–Straus remains open. This is an exact finite census and a theorem-discovery object, not a proof.