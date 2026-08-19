# CBX Lane-I global shadow depth through four — 10,000,000 at K_I=400

**Status:** preserved exact finite lower-bound census  
**Date:** 2026-08-16  
**Kernel:** `cbx.kernel 0.1.0`  
**Primary platform:** Fedora 44 GNU/Linux  
**Finite domain:** Mordell-hard primes `p <= 10,000,000`  
**Lane-I shifts:** `k = 3,7,...,399`  
**GitHub Actions run:** `31929718324`  
**Artifact id:** `9258920514`  
**Claim boundary:** every statement below is exact only on the stated finite hit-set graph. A finite lower bound on shadow depth is not a universal theorem and does not prove Erdős–Straus.

---

## 1. Question

For the intrinsic finite Lane-I hit sets

\[
H_k(X)=\{p\le X:p\text{ is Mordell-hard and hit at shift }k\},
\]

84 of the 100 configured layers satisfy

\[
H_k(10^7)\subseteq\bigcup_{j<k}H_j(10^7).
\]

The global overlap census had already shown that none of those later layers is contained in one, two, or three earlier layers.

This census asks whether depth four is enough:

\[
H_k(10^7)
\stackrel{?}{\subseteq}
H_a\cup H_b\cup H_c\cup H_d,
\qquad a<b<c<d<k.
\]

---

## 2. Exact finite result

The exhaustive finite search finds

\[
\boxed{0}
\]

union-shadowed layers with an exact cover by four or fewer earlier global layers.

Equivalently, for **all 84** layers that are fully contained in the complete prior union,

\[
\boxed{\text{finite global shadow depth}\ge 5.}
\]

This includes all

\[
\boxed{73}
\]

configured layers above the observed first-hit frontier `k=107`.

Together with the earlier graph result, the exact finite small-cover counts are therefore

\[
\boxed{
\text{depth 1}=0,
\quad
\text{depth 2}=0,
\quad
\text{depth 3}=0,
\quad
\text{depth 4}=0.
}
\]

The late-layer absorption seen in the ordered cover is genuinely collective on this finite domain.

---

## 3. Two targeted hard layers

The research workflow additionally tracked two representative union-shadowed targets.

### Target `k=147`

The standalone layer has

\[
\boxed{|H_{147}(10^7)|=1,683.}
\]

It is contained in the full earlier union but has no exact earlier cover of size at most four.

Thus its finite shadow-depth lower bound is

\[
\boxed{d_{147}\ge5.}
\]

### Target `k=171`

The standalone layer has

\[
\boxed{|H_{171}(10^7)|=3,592.}
\]

Again the full earlier union covers it, but no one-, two-, three-, or four-layer earlier subcover does.

Hence

\[
\boxed{d_{171}\ge5.}
\]

These are finite lower bounds, not claims that depth five is sufficient.

---

## 4. Why `k=107` is different

The first-hit census records `k=107` as a **novel** layer: one finite record prime survives every smaller configured shift and first hits at 107.

Therefore

\[
H_{107}(10^7)
\not\subseteq
\bigcup_{j<107}H_j(10^7).
\]

It is not a candidate for an earlier-layer shadow-depth certificate at all.

This matters operationally: a workflow that required the complete `H_107` to be covered by earlier layers would contradict the exact first-hit map. No successful canonical artifact makes such a claim.

---

## 5. Contrast with the Spectrum-C shadow

The global graph has no exact earlier cover through depth four, but spectrum conditioning reveals the exact finite relation

\[
H_{363,C}(10^7)
\subseteq
H_{23,C}(10^7)
\cup
H_{39,C}(10^7)
\cup
H_{59,C}(10^7).
\]

So conditioning changes the combinatorics dramatically:

\[
\boxed{
\text{global depth}\ge5
\quad\text{can coexist with}\quad
\text{spectrum-conditioned depth}=3.
}
\]

That contrast strongly suggests that the correct symbolic shadow theorem, if one exists, may need spectrum/residue information rather than a bare global set containment.

---

## 6. Research consequence

The easy absorption ladder is now exhausted through depth four on the finite global graph.

The next useful directions are not blind larger set-cover searches alone. They are:

1. **conditioned shadows** — spectra, residue subclasses, factor-pattern classes;
2. **targeted depth searches** on especially informative late layers;
3. **structural explanations** for why hubs such as `k=11` and `k=23` cover large fractions without becoming complete global absorbers;
4. **symbolic attack** on the verified Spectrum-C triple `363 <- {23,39,59}`;
5. use deeper finite cover searches only as topology reconnaissance, not as substitutes for a theorem.

A successful global depth-five or deeper finite cover would still be a theorem target, not a proof of universal absorption.

---

## 7. Reproduction

The preserved research workflow builds exact standalone hit sets and searches all globally prior-union-shadowed layers through depth four using the CBX bitset shadow engine.

The canonical run is GitHub Actions run `31929718324`, artifact `9258920514`.

---

Erdős–Straus remains open. This is an exact finite lower bound on global shadow depth, not a proof.