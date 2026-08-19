# CBX Lane-I standalone census — 10,000,000

**Status:** preserved exact finite standalone-layer census  
**Date:** 2026-08-15  
**Kernel:** `cbx.kernel 0.1.0`  
**Primary platform:** Fedora-family GNU/Linux  
**Finite domain:** Mordell-hard primes `p <= 10,000,000`  
**Standalone shift ceiling:** `K_I = 400`  
**Source commit:** `5aa482c8ecac92ee6511535e7e82abfd469e09bd`  
**GitHub Actions run:** `31928532641`  
**Artifact id:** `9258586932`  
**Artifact name:** `cbx-standalone-fedora-X10000000-K400-5aa482c8ecac92ee6511535e7e82abfd469e09bd`  
**Artifact digest:** `sha256:e869fd189aebc9745db6e4a77ce39f6d9441f3aa320f15c599b4cd37d503d728`  
**Claim boundary:** standalone hit counts measure finite layer strength and overlap. They are not first-hit depths, universal redundancy theorems, an adaptive-K theorem, or a proof of Erdős–Straus.

---

## 1. Why this census is different

The ordered Lane-I cover measures

\[
k_I^*(p)=\min\{k:\delta_k((p+k)/4)=0\}.
\]

Once a prime is covered at a smaller k, later shifts never get a chance to contribute a first hit for that target.

That is exactly what a first-hit search should do, but it hides the intrinsic strength of later layers.

The standalone profiler asks a different finite question:

> If shift k were tested against the entire Mordell-hard prime universe by itself, how many targets would it hit?

For every admissible

\[
k=3,7,11,\ldots,399,
\]

it independently evaluates all 20,513 Mordell-hard primes through 10,000,000, without removing targets hit by earlier shifts.

Thus the two objects must not be confused:

\[
\boxed{\text{first-hit novelty} \neq \text{standalone layer strength}.}
\]

---

## 2. Exact finite result

The target universe contains

\[
\boxed{20,513}
\]

Mordell-hard primes.

There are exactly 100 admissible shifts through 400:

\[
3,7,11,\ldots,399.
\]

The standalone result is

\[
\boxed{100/100\text{ layers productive}.}
\]

There are

\[
\boxed{0\text{ standalone zero-hit layers}.}
\]

This includes every one of the 73 admissible shifts above the ordered-cover record 107:

\[
\boxed{111,115,119,\ldots,399.}
\]

All 73 hit at least one hard prime on the finite 10M domain.

---

## 3. Above 107 is not weak territory

The ordered first-hit cover is already complete by 107, so every standalone hit above 107 is necessarily overlap with targets captured earlier in the ordered cover.

Nevertheless many of these layers are individually very strong.

Leading standalone layers above 107 include:

| `k` | standalone hits | fraction of all hard primes |
|---:|---:|---:|
| 119 | 12,345 | 60.1813% |
| 111 | 10,439 | 50.8897% |
| 191 | 10,142 | 49.4418% |
| 167 | 9,818 | 47.8623% |
| 311 | 9,811 | 47.8282% |
| 215 | 9,685 | 47.2140% |
| 143 | 9,483 | 46.2292% |
| 159 | 9,234 | 45.0154% |
| 239 | 8,785 | 42.8265% |
| 335 | 7,968 | 38.8437% |

Therefore the finite statement

\[
\text{“k>107 contributes no new first hit”}
\]

must not be misread as

\[
\text{“k>107 is a weak or empty layer.”}
\]

The data say almost the opposite: many later layers are powerful but completely shadowed by the union of earlier first-hit layers on this finite domain.

---

## 4. The record-prime gauntlet is also strong-but-shadowed

The ordered 10M census showed that after k=59 only one prime remains unresolved:

\[
p=8,803,369.
\]

It survives

\[
63,67,71,75,79,83,87,91,95,99,103
\]

and finally hits at 107.

Those eleven intermediate shifts therefore perform one active ordered-cover factorization each and add no new target.

Standalone profiling shows that they are not intrinsically dead layers at all:

| `k` | standalone hits | hit rate |
|---:|---:|---:|
| 63 | 6,677 | 32.5501% |
| 67 | 2,865 | 13.9668% |
| 71 | 12,960 | 63.1794% |
| 75 | 3,925 | 19.1342% |
| 79 | 8,579 | 41.8223% |
| 83 | 6,771 | 33.0083% |
| 87 | 9,230 | 44.9959% |
| 91 | 3,577 | 17.4377% |
| 95 | 11,300 | 55.0870% |
| 99 | 3,660 | 17.8423% |
| 103 | 7,415 | 36.1478% |

So the local gauntlet means:

> these layers are strong on the full hard-prime universe, but they all miss the one exceptional survivor left to them by smaller shifts.

That is a much sharper theorem-discovery target than calling them “dead layers.”

---

## 5. Strongest standalone layers overall

The strongest finite standalone layers through 400 are:

| `k` | standalone hits | hit rate |
|---:|---:|---:|
| 23 | 13,860 | 67.5669% |
| 47 | 13,553 | 66.0703% |
| 11 | 13,417 | 65.4073% |
| 31 | 13,152 | 64.1154% |
| 71 | 12,960 | 63.1794% |
| 39 | 12,769 | 62.2483% |
| 119 | 12,345 | 60.1813% |
| 95 | 11,300 | 55.0870% |
| 59 | 10,680 | 52.0645% |
| 55 | 10,521 | 51.2894% |
| 111 | 10,439 | 50.8897% |
| 19 | 10,186 | 49.6563% |

The strongest layer in this finite standalone census is therefore

\[
\boxed{k=23}
\]

with

\[
\boxed{13,860/20,513=67.5669\%}
\]

of all hard primes hit independently.

---

## 6. Weakest layers are still nonempty

Even the weakest measured standalone layers hit hundreds of hard primes.

Examples include:

| `k` | standalone hits | hit rate |
|---:|---:|---:|
| 387 | 519 | 2.5301% |
| 363 | 679 | 3.3101% |
| 315 | 807 | 3.9341% |
| 267 | 869 | 4.2363% |
| 307 | 981 | 4.7823% |
| 379 | 981 | 4.7823% |
| 283 | 1,005 | 4.8993% |
| 331 | 1,207 | 5.8841% |

Thus the finite 10M data contain no empty signed-box layer through 399.

Again, this is not a theorem that every admissible layer is nonempty for all primes or all domains. It is an exact finite observation.

---

## 7. Spectrum balance

Across all 100 standalone layers, counting overlapping hit events, the finite spectrum totals are:

```text
Spectrum A hit events: 173,607
Spectrum B hit events: 181,895
Spectrum C hit events: 178,535
```

Total standalone hit events:

\[
\boxed{534,037}.
\]

Total target visits and factorizations are both

\[
\boxed{2,051,300}
\]

because each of 100 shifts is tested independently against all 20,513 hard primes and no tested hard prime shares a factor with these shifts in the finite domain implementation.

The aggregate event hit rate is

\[
\frac{534,037}{2,051,300}\approx26.0346\%.
\]

This aggregate counts the same prime multiple times when it is hit by multiple shifts. It is therefore an overlap statistic, not a coverage probability.

---

## 8. What this says about shadowing

For the finite 10M domain, every layer above 107 has zero first-hit novelty but positive standalone strength.

Therefore every such standalone hit set lies inside the union of the earlier ordered cover:

\[
T_k^{10^7}
\subseteq
\bigcup_{j<k}T_j^{10^7}
\qquad (k>107),
\]

where `T_k^{10^7}` denotes the finite hard-prime hit set of standalone layer k.

This union containment is automatic once the earlier ordered cover is complete. It is not yet a useful theorem by itself.

The meaningful next questions are finer:

1. Is `T_k` contained in one earlier layer?
2. If not, what is the smallest earlier collection whose union contains it?
3. Which pairs have unusually high Jaccard/intersection ratios?
4. Are those finite containments forced by modulus/factor structure?
5. Can a finite containment candidate be upgraded to an exact signed-box shadow theorem?

That is why the next CBX instrument should preserve exact per-layer hit sets and build an overlap/containment graph rather than merely counting hits.

---

## 9. Preserved artifact

The standalone artifact contains:

```text
ENVIRONMENT.txt
RESEARCH-SUMMARY.json
SHA256SUMS
standalone-analysis.json
standalone-profile.json
```

Artifact digest:

```text
sha256:e869fd189aebc9745db6e4a77ce39f6d9441f3aa320f15c599b4cd37d503d728
```

Internal SHA-256 manifest entries include:

```text
ENVIRONMENT.txt          1ad74c5aa657e39c3363e814e25bb9a3d6836fff5cc93c9d84ecb2ab4080780b
RESEARCH-SUMMARY.json    22212ba292d4488436d99dadfb4622ca08cb5d1c1dcc37e8788f47dfa20b1ac8
standalone-analysis.json d1624083ace344b33e994e2ae08b5de268a8aceb745a8a67bf1a6a8dd163b812
standalone-profile.json  b7926616d4887a5a67735df5bb34c41dce5804b60da5ec13a2a3ac7f55f47612
```

GitHub Actions retention currently expires this artifact on 2026-11-14 unless it is separately archived.

---

## 10. New research frontier

The standalone census changes the immediate optimization/theorem program.

The next object is not “which k are weak?”

It is the finite overlap graph

\[
\boxed{G_K=(\{T_k\},\text{containment/intersection relations}).}
\]

The practical sequence is:

1. emit exact standalone hit sets for each k;
2. compute pairwise and union containment candidates;
3. distinguish exact containment from high overlap;
4. cross-reference candidates with shift modulus, factor pattern, spectrum and defect data;
5. attempt proofs only for the strongest structurally explainable containment relations;
6. feed proven relations back into the hybrid scheduler as mathematical pruning, not heuristic pruning.

The first-hit and standalone views should remain separate throughout this program.

---

Erdős–Straus remains open. This is an exact finite overlap census and theorem-discovery object, not a proof.