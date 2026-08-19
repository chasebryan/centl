# CBX Lane-I overlap graph — 10,000,000

**Status:** preserved exact finite overlap analysis  
**Date:** 2026-08-15  
**Kernel:** `cbx.kernel 0.1.0`  
**Primary platform:** Fedora-family GNU/Linux  
**Finite domain:** Mordell-hard primes `p <= 10,000,000`  
**Standalone shift ceiling:** `K_I = 400`  
**Source commit:** overlap workflow based on the CBX standalone 10M/K400 corpus  
**GitHub Actions run:** `31928793294`  
**Artifact id:** `9258669044`  
**Claim boundary:** all relations below are exact finite set relations on the stated domain. They are theorem candidates, not universal signed-box shadow theorems and not a proof of Erdős–Straus.

---

## 1. The finite layer sets

For every admissible shift

\[
k=3,7,11,\ldots,399,
\]

let

\[
T_k^{10^7}
=
\{p\le10^7:\ p\text{ Mordell-hard prime and Lane I hits at }k\}.
\]

The standalone census contains 100 such layers and the exact relation file contains

\[
\boxed{534,037}
\]

`(k,p)` hit relations.

The union of the layer sets contains all

\[
\boxed{20,513}
\]

Mordell-hard primes through 10,000,000.

Because targets may belong to many layers, 534,037 is an overlap-event count rather than a unique-prime count.

---

## 2. Ordered novelty versus standalone strength

When the layers are placed in ordinary increasing-k order, exactly 16 shifts add at least one previously uncovered hard prime:

\[
\boxed{
3,7,11,15,19,23,27,31,35,39,43,47,51,55,59,107.
}
\]

Therefore

\[
\boxed{84/100}
\]

standalone layers are fully contained in the **union** of earlier layers on this finite domain.

This is the same first-hit fact seen from the standalone sets:

\[
T_k^{10^7}
\subseteq
\bigcup_{j<k}T_j^{10^7}
\]

for all 84 non-novel layers.

In particular, every one of the 73 shifts above 107 is fully shadowed by the earlier union.

The important question is how complicated that earlier union must be.

---

## 3. No single-layer containment

The exact pairwise containment search found

\[
\boxed{0}
\]

relations of the form

\[
T_k^{10^7}\subseteq T_j^{10^7}
\qquad (j<k).
\]

So none of the 84 union-shadowed layers is merely a duplicate or subset of one earlier standalone layer on the 10M corpus.

This is already a useful negative result: first-hit shadowing is not explained by trivial one-layer absorption.

---

## 4. No two-layer union containment

The exact search also found

\[
\boxed{0}
\]

later layers for which two earlier layers suffice:

\[
T_k^{10^7}
\subseteq
T_a^{10^7}\cup T_b^{10^7},
\qquad a,b<k.
\]

A two-layer containment that appeared on the much smaller `p<=100,000` smoke corpus therefore **does not survive scale to 10,000,000**.

That failure is methodologically important. Small-corpus exact containment is evidence for a theorem search, not evidence of a theorem.

---

## 5. Strongest pairwise overlaps are still partial

Although there is no one-layer containment, some pairs overlap strongly.

Leading earlier/later relations include:

| later `k` | earlier `j` | intersection | fraction of later layer covered | Jaccard |
|---:|---:|---:|---:|---:|
| 119 | 23 | 9,366 | 75.8688% | 55.6340% |
| 95 | 47 | 8,730 | 77.2566% | 54.1411% |
| 95 | 23 | 8,594 | 76.0531% | 51.8677% |
| 55 | 11 | 8,230 | **78.2245%** | 52.3851% |
| 111 | 23 | 8,361 | 80.0939% | 52.4601% |
| 143 | 47 | 7,695 | 81.1484% | 50.1650% |

The strongest *coverage fraction* among these is not enough for containment. For example,

\[
\boxed{
|T_{55}\cap T_{11}|=8,230
}
\]

while

\[
|T_{55}|=10,521,
\]

so approximately

\[
\boxed{78.2245\%}
\]

of the finite `k=55` layer is covered by `k=11` alone, leaving more than one fifth elsewhere.

The finite shadow is therefore genuinely distributed.

---

## 6. Greedy earlier-layer cover complexity above 107

A greedy set-cover summary was computed for each later layer using only earlier layers. The greedy procedure is **heuristic**, not an exact minimum-set-cover solver, but it gives a useful scale for the distributed overlap.

For the 73 shifts above 107, every layer is covered by the earlier union. Greedy cover sizes are:

| earlier layers used | number of later layers |
|---:|---:|
| 5 | 2 |
| 6 | 18 |
| 7 | 35 |
| 8 | 15 |
| 9 | 2 |
| 10 | 1 |

Thus the finite distribution has

\[
\boxed{\text{median greedy cover size}=7}
\]

with range

\[
\boxed{5\le g(k)\le10.}
\]

Examples of the smallest greedy covers are

```text
T_147 covered greedily by {23,11,31,7,15}
T_171 covered greedily by {23,11,31,7,3}
T_151 covered greedily by {23,11,47,7,31,15}
T_187 covered greedily by {23,11,47,7,31,15}
```

The largest observed greedy cover is

```text
T_371 covered greedily using 10 earlier layers:
{23,11,31,7,47,3,15,19,39,59}
```

These are finite descriptive covers only. Greedy cardinality is an upper bound on the true finite minimum cover size, not an exact minimum.

---

## 7. Best single-predecessor coverage above 107

Even above the ordered first-hit ceiling, later layers typically share a large but incomplete fraction with one earlier layer.

Examples:

```text
k=119  best earlier k=23   coverage 75.8688%
k=143  best earlier k=47   coverage 81.1484%
k=147  best earlier k=23   coverage 79.0458%
k=167  best earlier k=23   coverage 79.6191%
k=171  best earlier k=23   coverage 79.4743%
k=191  best earlier k=47   coverage 80.5068%
k=263  best earlier k=23   coverage 81.8464%
```

The remaining 18–25% is what forces the shadow to draw from additional earlier layers.

This is precisely the structure that a complementary-cover theorem would need to explain.

---

## 8. What has been falsified

The 10M exact graph rules out several attractive simplifications:

### Falsified finite model A — duplicate layers

\[
T_k\subseteq T_j.
\]

No examples.

### Falsified finite model B — simple complementary pair

\[
T_k\subseteq T_a\cup T_b.
\]

No examples at 10M/K400.

### Falsified inference from the smoke corpus

The exact two-layer relation seen below 100,000 does not persist through 10,000,000.

Therefore the current evidence favors **distributed many-layer shadowing**, not trivial layer absorption.

---

## 9. Exact-triple follow-up

CBX now includes a separate exact finite shadow-depth analyzer that tests one-, two-, and three-earlier-layer unions against the preserved standalone hit sets.

This is intentionally separated from the broad overlap analyzer so the finite negative result can have independent CI/artifact provenance.

Until that artifact is preserved, this note treats the exact one- and two-layer results above as the publication-grade bound. No claim about exact four-layer or minimum set-cover size is made here.

---

## 10. Artifact provenance

The exact overlap artifact was produced by GitHub Actions run

```text
31928793294
```

with artifact id

```text
9258669044
```

and contains the standalone relation file plus overlap analysis and research summary.

The graph analysis is computed from exact finite sets, not from sampled counts.

---

## 11. Research frontier

The next theorem-search object is no longer “which layers are weak?” The standalone census already showed that many shadowed layers are very strong.

The sharper questions are:

1. What is the exact minimum number of earlier layers required to cover each fully-shadowed `T_k`?
2. Does any exact three- or four-layer containment survive the 10M corpus?
3. Are the same earlier layers repeatedly selected across many later covers?
4. Can those repeated combinations be derived from modulus/factor/defect structure?
5. Can a proven finite-looking pattern be upgraded to a universal signed-box containment theorem?
6. Can proven containment relations safely prune the hybrid scheduler while preserving exact first-hit semantics?

The current finite evidence says the shadow graph is a many-body object.

---

Erdős–Straus remains open. This is an exact finite overlap graph and theorem-discovery object, not a proof.