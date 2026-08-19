# CBX Lane-I overlap graph — 10,000,000 at K_I=400

**Status:** preserved exact finite overlap/containment census  
**Date:** 2026-08-16  
**Kernel:** `cbx.kernel 0.1.0`  
**Primary platform:** Fedora 44 GNU/Linux  
**Finite domain:** Mordell-hard primes `p <= 10,000,000`  
**Lane-I shifts:** `k = 3,7,...,399`  
**Source commit:** `8e74569d251756c28c0e570b1ffabeb9b42ad986`  
**Checkout merge commit:** `fe38d4ed0366202f2874cc8770e3938675605723`  
**GitHub Actions run:** `31929064008`  
**Artifact id:** `9258751000`  
**Artifact name:** `cbx-standalone-fedora-X10000000-K400-8e74569d251756c28c0e570b1ffabeb9b42ad986`  
**Artifact ZIP digest:** `sha256:6165a3b22a71331394aed8febdb687122671a6196ea2a5976998a3ed8b50ba6d`  
**Claim boundary:** every containment and overlap statement below is exact only for the stated finite prime domain. It is theorem-hunting evidence, not a universal signed-box shadow theorem and not a proof of Erdős–Straus.

---

## 1. The finite layer sets

For every admissible Lane-I shift `k`, define the finite intrinsic hit set

\[
H_k(X)=\left\{p\le X:
 p\text{ is Mordell-hard prime and }
 \delta_k\!\left(\frac{p+k}{4}\right)=0
\right\}.
\]

This census takes

\[
X=10^7
\]

and constructs all 100 sets

\[
H_3,H_7,\ldots,H_{399}.
\]

The exact relation file contains

\[
\boxed{534,037}
\]

`(k,p)` hit relations over

\[
\boxed{20,513}
\]

unique Mordell-hard primes.

Every one of the 100 standalone layers is nonempty.

---

## 2. Ordered novelty reconstructs the first-hit frontier exactly

Let

\[
U_{<k}=\bigcup_{j<k}H_j.
\]

The marginal novelty of layer `k` is

\[
N_k=H_k\setminus U_{<k}.
\]

The exact overlap graph finds

\[
|N_k|>0
\]

for exactly 16 shifts:

\[
\boxed{
3,7,11,15,19,23,27,31,35,39,43,47,51,55,59,107.
}
\]

That is exactly the productive first-hit sequence from the independent K=400 survivor census.

Hence the set-level reconstruction and the search-level first-hit engine agree:

\[
\boxed{
\sum_k |N_k|=20,513.
}
\]

All hard primes are in the ordered union through 107.

---

## 3. Eighty-four layers are fully shadowed by the prior union

The remaining

\[
\boxed{84/100}
\]

layers satisfy the exact finite containment

\[
\boxed{
H_k(10^7)\subseteq\bigcup_{j<k}H_j(10^7).
}
\]

In particular all 73 configured layers with

\[
k>107
\]

are fully contained in the prior union on this finite domain.

This explains why the ordered survivor frontier is empty after 107 even though every later standalone layer is intrinsically productive.

But this union-shadowing is **not** a trivial small-layer absorption.

---

## 4. No exact one-layer shadow

For every later layer `H_k`, the analyzer tested all earlier single layers `H_j`, `j<k`.

It found

\[
\boxed{
\#\{k:\exists j<k,\ H_k\subseteq H_j\}=0.
}
\]

So no later finite layer is exactly shadowed by one earlier layer.

The strongest measured single earlier coverage is

\[
H_{55}\text{ against }H_{11}.
\]

Their intersection contains 8,230 primes and covers

\[
\boxed{78.224503\%}
\]

of `H_55`, with Jaccard similarity

\[
\boxed{0.5239368475}.
\]

That is substantial overlap, but it still leaves more than one fifth of `H_55` outside `H_11`.

---

## 5. No exact two-layer shadow

For every later target layer, the analyzer then searched all pairs of earlier layers.

It found

\[
\boxed{
\#\{k:\exists a<b<k,\ H_k\subseteq H_a\cup H_b\}=0.
}
\]

Thus no later layer in this finite census is exactly absorbed by any two earlier layers.

---

## 6. No exact three-layer shadow

The v2 overlap analyzer extends the exact bitset search through all triples of earlier layers.

It independently reproduced on Fedora:

\[
\boxed{
\#\{k:\exists a<b<c<k,\ H_k\subseteq H_a\cup H_b\cup H_c\}=0.
}
\]

Therefore the exact finite shadow-depth result through three layers is

\[
\boxed{
\text{single}=0,\qquad
\text{two}=0,\qquad
\text{three}=0.
}
\]

This includes every one of the 73 fully union-shadowed layers above 107.

The consequence is important:

> the observed absorption of late layers is genuinely multi-layer. It does not collapse to an obvious one-, two-, or three-earlier-layer cover on this finite domain.

This is a finite search result, not a theorem that four or more layers are universally necessary.

---

## 7. Large pairwise overlaps still exist

The lack of exact small covers does not mean the layer graph is weakly connected.

Representative best-earlier coverage values include approximately:

| later k | best earlier k | fraction of later layer covered |
|---:|---:|---:|
| 55 | 11 | 0.782245 |
| 67 | 23 | 0.723560 |
| 91 | 47 | 0.713727 |
| 399 | 23 | 0.703429 |
| 111 | 23 | 0.692595 |
| 95 | 23 | 0.691327 |
| 119 | 23 | 0.689510 |
| 63 | 11 | 0.685038 |
| 191 | 11 | 0.680931 |
| 311 | 11 | 0.679951 |

Other high-similarity pairs include `23 <- 11`, `47 <- 11`, `47 <- 23`, `31 <- 23`, `71 <- 23`, and `119 <- 23`.

So the graph contains strong recurring overlap hubs, especially early layers such as 11 and 23, without exact single-layer containment.

---

## 8. Greedy multi-layer covers are heuristic theorem targets

The analyzer also computes a greedy earlier-layer cover for each later `H_k`.

Examples from the finite graph include greedy covers of roughly:

- 10 earlier layers for `k=63`;
- 9 for `k=67`;
- 13 for `k=71`;
- 6 for `k=91`;
- 8 for `k=99`;
- 9 for `k=103`;
- 9 for `k=111`.

For `k=107`, the greedy earlier union leaves exactly one hit uncovered, consistent with the unique first-hit record prime at 107.

These greedy counts are **not minimum set-cover proofs**. They are prioritization signals only.

---

## 9. The structural picture

The paired marginal, standalone, and overlap censuses now say:

1. every one of the 100 configured shifts has genuine finite arithmetic content;
2. only 16 contribute novel first hits in ascending order;
3. 84 are fully shadowed by the union of prior layers;
4. none is fully shadowed by one prior layer;
5. none is fully shadowed by two prior layers;
6. none is fully shadowed by three prior layers.

Schematically,

\[
\boxed{
\text{large intrinsic layers}
+\text{heavy overlap}
+\text{no small exact absorber}
\Longrightarrow
\text{collective cover geometry}.
}
\]

This is a much sharper theorem target than simply observing that late layers add no new primes.

---

## 10. Research direction

The next symbolic work should attack the overlap graph structurally rather than searching for another raw finite speedup.

Promising questions include:

### Spectrum-conditioned containment

Replace `H_k` by

\[
H_{k,A},\quad H_{k,B},\quad H_{k,C}
\]

and ask whether exact small-layer containments appear inside one spectrum even when they fail globally.

### Congruence-conditioned shadowing

Search for residue refinements under which a large fraction of a later layer is forced into an earlier layer or small union.

### Proven multi-layer absorption

Try to identify an arithmetic condition that proves

\[
H_k\subseteq H_{a_1}\cup\cdots\cup H_{a_m}
\]

for a structured family of `k`, rather than inferring it from the finite graph.

### Explain the recurring hubs

Layers 11 and 23 repeatedly appear as strong earlier-overlap partners. Their role should be compared with the existing signed-box, defect, reciprocity, and shadowing machinery.

### The 107 survivor

Because the greedy prior union leaves one first-hit survivor at 107, the exact membership pattern of `p=8,803,369` across earlier `H_k` is a natural microscopic test case for any proposed absorption theorem.

---

## 11. Preserved provenance and checksums

The canonical v2 overlap artifact is GitHub Actions artifact `9258751000` from run `31929064008`.

Environment metadata records:

```text
source_commit=8e74569d251756c28c0e570b1ffabeb9b42ad986
checkout_commit=fe38d4ed0366202f2874cc8770e3938675605723
Fedora Linux 44 (Container Image)
GCC 16.1.1
Python 3.14.6
```

Selected artifact checksums:

```text
overlap-analysis.json
  9082d81bd690de07f71b85f3dcfd7e79a14a6b2b3b3a3fe490e6b53d045b88ef

standalone-hit-relations.tsv
  dbe0d89232e71a0616d3317dc85dd59eda61b031697d9aedc35f72b355e10df3

standalone-profile.json
  2ed5c09193ef01a487c9ed6a2629b65850acc2411a1ea94b0bb219736f45e187

standalone-analysis.json
  7b6f13ff9e7910fd2e470dc30623d1f1c6520c387ff630abf65ef90c2465cf87

RESEARCH-SUMMARY.json
  d7abb088209529629fc0795068d70601b5683043962244ece2cfcc17c9132a64

ENVIRONMENT.txt
  4b38a38b58445bda09ab8ba0bbe2daf3b6778b433a662b160536933a339e79e5
```

Artifact ZIP digest:

```text
sha256:6165a3b22a71331394aed8febdb687122671a6196ea2a5976998a3ed8b50ba6d
```

---

## 12. Reproduction

```sh
./centl es cbx standalone-i \
  --hi 10000000 \
  --i-max 400 \
  --segment 1000000 \
  --sets standalone-hit-relations.tsv \
  > standalone-profile.json

./centl es cbx analyze-overlap \
  standalone-hit-relations.tsv \
  --json > overlap-analysis.json
```

The v2 analyzer performs the exact single-, two-, and three-earlier-layer containment searches with integer bitsets.

---

Erdős–Straus remains open. This graph is exact finite theorem-hunting evidence, not a proof.