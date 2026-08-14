# Cryptology control lemmas for WS-CAND-003

**Status:** proved elementary controls and experimental interpretation
**Date:** 2026-08-14

This note records arithmetic controls that must be applied before interpreting any Type A/B fingerprint as a nontrivial cryptologic signal.

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

## 5. Experimental decision rule

For both factor-level prime fingerprints and public toy-RSA product fingerprints:

- **signal survives masking:** investigate aggressively, first for sampling bias, finite-range effects, classifier leakage, and hidden algebraic dependence; only after these are rejected should the result be considered a candidate cryptologic distinguisher;
- **signal collapses to chance after masking:** record a negative result. This means the pilot separation was explained by explicitly planted congruence information rather than a deeper fingerprint effect;
- **public-modulus signal survives masking while prime sampling controls remain clean:** this is the most interesting near-term outcome, because it would show source information visible from `N=pq` alone, but still would not constitute factor recovery or an RSA break.

## 6. Claim boundary

The proved content of this note is elementary modular arithmetic. It establishes how deliberately planted `1 mod (4k-1)` constraints interact with the Type A/B fingerprint.

It does not establish a cryptographic distinguisher, weakness, factorization method, or attack on any deployed system.
