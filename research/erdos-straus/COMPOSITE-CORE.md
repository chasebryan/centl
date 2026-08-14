# The composite rescue core

**Status:** reduction note
**Date:** 2026-08-14
**Claim boundary:** this note reorganizes the Type A/B congruence system around prime versus composite target moduli. It does not prove universal Type A/B coverage. The term `composite rescue core` is project terminology and no literature-priority claim is made without a separate prior-art review.

## 1. Prime-modulus capture

For each layer

\[
k\ge1,
\qquad m_k=4k-1,
\]

let

\[
T_k=\{-e,-4e\pmod{m_k}:e\mid k\}.
\]

Call a prime `p` **prime-modulus captured** if there exists a layer `k` such that

\[
m_k=4k-1\text{ is prime}
\]

and

\[
p\bmod m_k\in T_k.
\]

Every such hit is a valid Type A or Type B witness.

The exact survivor-density theorem shows more: the prime-modulus layers form independent new CRT coordinates, and their accumulated hazard forces the set of primes escaping every prime-modulus layer to have relative prime density zero.

## 2. The prime-modulus core

Define

\[
\mathcal C_{\rm pm}
=
\left\{
p\text{ prime}:
 p\bmod q\notin
 T_{(q+1)/4}
\text{ for every prime }q\equiv3\pmod4
\right\}.
\]

Then

\[
\boxed{
overline d_{\mathbb P}(\mathcal C_{\rm pm})=0.
}
\]

Thus a relative density-one set of primes is already solved inside the prime-modulus backbone before any composite modulus is used.

## 3. Composite rescue

A prime in `C_pm` can still have a Type A/B solution. If it does, every minimal Type A/B witness for that prime necessarily occurs at a composite target modulus `4k-1`.

Call such a hit a **composite rescue**.

For a prime `p in C_pm` with finite `C_AB(p)`, define its composite rescue depth by

\[
R_{\rm comp}(p)=C_{AB}(p).
\]

The universal Type A/B coverage conjecture is therefore equivalent to the following residual statement:

\[
\boxed{
\text{Every prime in }\mathcal C_{\rm pm}\text{ has a composite rescue.}
}
\]

This does not weaken the logical difficulty of the pointwise conjecture, but it isolates that difficulty inside a zero-density arithmetic core.

## 4. Why the core is not empty in the observed data

The prime `2521` is a canonical example.

Its minimal Type A/B depth in the CENTL research data is

\[
C_{AB}(2521)=22,
\qquad
m_{22}=87=3\cdot29.
\]

The López analysis identifies `2521` as lacking Type A solutions and states that its Type B solution is associated only with composite values `87` and `1275` for `4dn-1`.

Thus `2521` is not merely difficult in a numerical sense. It demonstrates that composite rescue is genuinely necessary: the prime-modulus backbone alone cannot cover every prime.

## 5. A simpler density-one spine inside the backbone

The special Type B choice

\[
n=1
\]

gives

\[
p\equiv-1\pmod{4d-1}.
\]

Therefore, whenever `p+1` has a prime divisor

\[
q\equiv3\pmod4,
\]

we may take

\[
d=\frac{q+1}{4}
\]

and obtain a Type B witness.

Equivalently, a prime escaping this one-parameter spine must have no odd prime factor `3 mod 4` in `p+1`.

This particular divisor criterion is already represented in recent Erdős-Straus work and should not be treated as a project novelty. Its importance here is organizational: it shows that even a very thin slice of the prime-modulus backbone removes most primes, while the full trap set gives an exact multi-residue hazard.

## 6. The diamond-shaped residual problem

The Type A/B conjecture can now be decomposed into two qualitatively different regimes:

### Density-one backbone

Prime moduli `q=4k-1` contribute independent exact hazards

\[
h_k=\frac{|T_k|}{q-1}.
\]

Their product forces the prime-modulus survivor density to zero.

### Zero-density composite core

The remaining primes have escaped every independent prime-modulus layer. To finish pointwise coverage one must show that the dependency-rich composite layers always rescue them.

This is precisely the regime where the shadow graph, modulus ancestry, partial shadows, and joint shadow closure matter most.

The deep problem is therefore no longer well described as "find more congruences." It is:

> Explain why every prime that escapes the independent backbone is forced into the composite shadow geometry.

## 7. Immediate theorem targets

The strongest next targets are:

1. classify composite layers whose target modulus has a prescribed factorization pattern and prove exact rescue criteria;
2. determine whether every composite rescue can be reduced to a finite list of irreducible shadow-quotient patterns;
3. test whether record-high `C_AB` primes are statistically enriched in the prime-modulus core before their eventual composite rescue;
4. prove or refute direct-shadow completeness inside the composite core;
5. characterize the first composite-rescue depth as a function of the factorization of the shifted integers `p+n` and `p+4d`.

A successful structural theorem in this residual core would attack exactly the part of López's conjecture that the density-one prime-modulus mechanism cannot touch.
