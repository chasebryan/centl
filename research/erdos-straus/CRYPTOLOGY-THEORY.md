# Cryptology control lemmas for WS-CAND-003

**Status:** proved elementary controls and experimental interpretation
**Date:** 2026-08-14

This note records arithmetic controls that must be applied before interpreting any Type A/B fingerprint as a nontrivial cryptologic signal. It also formalizes the threshold-shadow mechanism exposed by the high-versus-low `C_AB` experiment.

## 1. The residue 1 is never a Type A/B trap

Recall

\[
m_k=4k-1,
\]

and

\[
T_k=\{-d,-4d\pmod{m_k}:d\mid k\}.
\]

### Lemma

For every integer `k >= 1`,

\[
\boxed{1\notin T_k.}
\]

### Proof

Suppose first that for a divisor `d | k`,

\[
1\equiv-d\pmod{4k-1}.
\]

Then `4k-1` divides `d+1`. But

\[
0<d+1\le k+1<4k-1
\]

for `k >= 2`, which is impossible. The case `k=1` is immediate by direct enumeration.

Suppose instead

\[
1\equiv-4d\pmod{4k-1}.
\]

Then `4k-1` divides `4d+1`. Since

\[
0<4d+1\le4k+1=(4k-1)+2,
\]

the only possible positive multiple is `4k-1`, which would force

\[
4d+1=4k-1,
\]

hence `d=k-1/2`, impossible for integral `d`. QED.

## 2. Forced-escape corollary

If

\[
p\equiv1\pmod{4k-1},
\]

then `p` cannot have a Type A/B hit at layer `k`.

Thus a prime generator deliberately constrained by

\[
p\equiv1\pmod{\operatorname{lcm}(4k_1-1,\ldots,4k_r-1)}
\]

forces escape from every listed layer `k_i`.

This observation is closely related to the existing proof that `C_AB` is unbounded: imposing residue 1 simultaneously modulo all early Type A/B moduli forces a prime to survive those layers.

## 3. Interpretation of the first cryptology pilot

The first controlled toy source used

\[
p\equiv1\pmod{\operatorname{lcm}(840,11,19,23)}.
\]

Since

\[
11=4(3)-1,\qquad19=4(5)-1,\qquad23=4(6)-1,
\]

the structured source was deliberately forced to avoid Type A/B hits at

\[
\boxed{k=3,5,6.}
\]

Therefore the large pilot separation between the `p == 1 mod 840` control and the structured source is not by itself surprising cryptologic evidence. Part of the signal is an exact arithmetic consequence of how the structured source was constructed.

The pilot is still useful because it demonstrates that the Type A/B fingerprint responds strongly to planted modular structure. But the correct next question is harder:

> Does any statistically useful signal remain after every feature that directly exposes the planted congruences is removed?

## 4. Required negative-control mask

For the planted extra modulus

\[
M_{extra}=11\cdot19\cdot23,
\]

a conservative masked fingerprint should discard every layer `k` for which

\[
\gcd(4k-1,M_{extra})>1.
\]

This removes not only the exact layers `3,5,6`, but every fingerprint modulus sharing an arithmetic factor with the planted constraints.

A still stronger control also removes the very early layers and all layers fully directly shadowed, leaving a shadow-compressed deep fingerprint.

The repeated held-out probe `crypto_probe_v2.py` implements both controls.

## 5. Threshold shadowing

The high-versus-low `C_AB` experiment introduces a different source of structure. No extra congruences are explicitly planted. Instead, primes are selected by whether they survive the Type A/B sieve through a threshold.

Fix a hard residue class `h mod 840` and a threshold `D >= 2`. For `k >= D`, let `A_{k,h}` be the admissible Type A/B candidate classes `(h,t)` at layer `k`.

Define

\[
S_{D,k,h}=\left\{(h,t)\in A_{k,h}:\exists j<D\text{ such that }(h,t)\text{ is directly shadowed by }j\right\}.
\]

The **pre-shadow load** is

\[
\boxed{
\sigma_{D,h}(k)=\frac{|S_{D,k,h}|}{|A_{k,h}|}
}
\]

when `A_{k,h}` is nonempty.

### Theorem: survival excludes pre-shadowed later candidates

Let `p` be a prime with

\[
p\equiv h\pmod{840}
\]

and

\[
C_{AB}(p)\ge D.
\]

For any `k >= D`, if `p` has a Type A/B hit at layer `k`, then its candidate class at `k` lies in

\[
A_{k,h}\setminus S_{D,k,h}.
\]

Equivalently, no prime surviving every layer below `D` can occupy a later candidate class directly shadowed by any `j<D`.

### Proof

Assume toward a contradiction that the layer-`k` candidate containing `p` lies in `S_{D,k,h}`. Then by definition there exists `j<D` such that every integer in that layer-`k` CRT progression is captured by the Type A/B trap at layer `j`.

Since `p` belongs to that CRT progression, `p` is captured at layer `j`. Therefore

\[
C_{AB}(p)\le j<D,
\]

contradicting `C_AB(p) >= D`. QED.

### Corollary: complete pre-shadow forbids a later first hit

If

\[
\sigma_{D,h}(k)=1,
\]

then no prime in hard class `h` with `C_AB(p) >= D` can hit at layer `k`.

Thus a later layer may become deterministically unavailable after conditioning on survival through an earlier threshold, even when `k` is numerically well beyond that threshold.

### Corollary: partial pre-shadow induces support depletion

If

\[
0<\sigma_{D,h}(k)<1,
\]

then deep survivors can hit layer `k` only through the unshadowed fraction

\[
1-\sigma_{D,h}(k)
\]

of admissible candidate classes.

This does not by itself determine the conditional probability of a hit, because prime density and interactions among the remaining congruence constraints still matter. But it proves an exact support restriction.

## 6. Why this explains the v3 ablation

In the v3 experiment, the high-depth source satisfies

\[
p\equiv1\pmod{840},\qquad C_{AB}(p)\ge25.
\]

A classifier using all later layers `k >= 25` achieved substantial held-out factor-level accuracy. When completely directly shadowed layers were removed, that accuracy collapsed close to chance.

The threshold-shadow theorem supplies the mechanism: later classes shadowed by earlier `j<25` are prohibited for the high-depth source by construction. They therefore encode early survival history even though their own layer indices lie at or above 25.

The current shadow-compression experiment removes only layers whose entire admissible candidate set is directly shadowed. A more precise analysis should use the fractional quantity `sigma_{25,1}(k)` and ask whether empirical high-depth depletion varies with pre-shadow load.

That is now the primary theorem-and-experiment target.

## 7. Experimental decision rule

For both factor-level prime fingerprints and public toy-RSA product fingerprints:

- **signal survives masking:** investigate first for sampling bias, finite-range effects, classifier leakage, direct shadow, partial pre-shadow, and hidden algebraic dependence;
- **signal collapses after masking or shadow compression:** record the negative cryptologic result and the corresponding arithmetic explanation;
- **public-modulus signal survives all source-definition and shadow controls:** treat it as a candidate source-distribution distinguisher, not as key recovery, and subject it to independent reproduction before escalating the claim.

## 8. Claim boundary

The proved content of this note is elementary modular arithmetic. It establishes how deliberately planted `1 mod (4k-1)` constraints and threshold-conditioned Type A/B survival affect later fingerprint support.

It does not establish a cryptographic weakness, factorization method, key-recovery algorithm, or attack on any deployed system.
