# Type A/B shadow ancestry: formal working lemmas

This note separates proved elementary structure from computational conjecture targets for WS-CAND-003.

## Definitions

For `k >= 1`, write

\[
m_k=4k-1,
\]

and

\[
T_k=\{-d,-4d\pmod{m_k}:d\mid k\}.
\]

Let

\[
H=\{1,121,169,289,361,529\}\pmod{840}.
\]

A hard-class-compatible candidate at layer `k` is a pair `(h,t)` with `h in H`, `t in T_k`, `gcd(t,m_k)=1`, and

\[
t\equiv h\pmod{\gcd(840,m_k)}.
\]

It defines the CRT progression

\[
x\equiv h\pmod{840},\qquad x\equiv t\pmod{m_k}.
\]

A candidate is **directly shadowed by layer `j<k`** when every integer in that CRT progression lies in `T_j` modulo `m_j`.

## Lemma 1: modulus ancestry

For integers `1 <= j < k`,

\[
m_j\mid m_k
\]

if and only if there exists an integer `s >= 1` such that

\[
\boxed{m_k=(4s+1)m_j}
\]

and equivalently

\[
\boxed{k=(4s+1)j-s.}
\]

### Proof

If `m_j | m_k`, let `q=m_k/m_j`. Since both moduli are congruent to `3 mod 4`,

\[
3q\equiv3\pmod4,
\]

so `q == 1 mod 4`. Write `q=4s+1`. Then

\[
4k-1=(4s+1)(4j-1)
\]

and expansion gives

\[
k=(4s+1)j-s.
\]

The converse follows by substituting that expression for `k`. QED.

For fixed `s`, the identity

\[
4((4s+1)j-s)-1=(4s+1)(4j-1)
\]

is a univariate polynomial identity in `j`. The automated harness asks CENTL to certify the fixed-quotient identity for every ancestry quotient actually observed in the finite shadow graph.

The first nontrivial ancestry family is `s=1`, hence

\[
\boxed{k=5j-1,\qquad m_k=5m_j.}
\]

## Lemma 2: direct shadow collapses to residue reduction along ancestry

Assume `j<k` and `m_j | m_k`. Let `(h,t)` be an admissible candidate at layer `k`. Then `(h,t)` is directly shadowed by `j` if and only if

\[
\boxed{t\bmod m_j\in T_j.}
\]

### Proof

Every integer in the current candidate progression satisfies

\[
x\equiv t\pmod{m_k}.
\]

Since `m_j | m_k`, this forces

\[
x\equiv t\pmod{m_j}
\]

for every member of the progression. Therefore every member is captured by layer `j` exactly when that one forced residue belongs to `T_j`. QED.

This removes the need for a general CRT fibre computation on modulus-ancestry edges. The general fibre criterion is still needed for shadow edges where `m_j` does not divide `m_k`.

## Corollary: exact full-shadow test on an ancestry edge

If `m_j | m_k`, then layer `k` is completely directly shadowed by `j` on the hard-prime population exactly when every admissible candidate `(h,t)` at layer `k` satisfies

\[
t\bmod m_j\in T_j.
\]

This is a finite divisor-generated residue condition. It is the natural starting point for classifying infinite shadow families.

## Lemma 3: first-hit primes certify global non-union-shadowing

Suppose a prime `p` has

\[
C_{AB}(p)=k.
\]

Set

\[
h=p\bmod840,\qquad t=p\bmod m_k.
\]

Then the current candidate class `(h,t)` is **not** covered by the union of all earlier Type A/B trap layers.

### Proof

The prime `p` itself belongs to the current CRT class. By the definition of `C_AB(p)=k`, it lies in no trap `T_j` for `j<k`. Hence the union of earlier layers cannot cover the entire current class. QED.

This is stronger than `direct_novel`: the latter excludes only one-layer containment, whereas a first-hit prime excludes collective coverage by all previous layers at once.

For the current finite record,

\[
C_{AB}(9658489)=2622,
\]

so its `(169,10449)` candidate class at modulus `10487` has an explicit globally non-union-shadowed witness.

## Theorem target A: classify `k=5j-1`

The automation observes all three possibilities along the first ancestry family:

- complete direct shadow;
- partial direct shadow;
- no direct shadow from the immediate ancestor.

The research target is a necessary-and-sufficient condition on `j` for

\[
T_{5j-1}^{\mathrm{admissible}}\bmod(4j-1)\subseteq T_j.
\]

A finite list of observed examples is not an infinite-family theorem. The automated `ancestry-candidate-families.json` exists to discover candidate conditions that can then be proved separately.

## Theorem target B: irredundant core

For candidates without an explicit first-hit prime, determine whether several earlier layers can jointly cover the current CRT progression even though no one earlier layer covers it. The exact target is collective **union shadowing**.

The checked-in automation currently makes only two rigorous union-level statements:

1. a completely directly shadowed class is certainly union-shadowed;
2. a class containing a verified first-hit prime is certainly not union-shadowed.

All classes between those two categories remain open to stronger exact covering analysis.

## Theorem target C: growth and distribution of `C_AB`

The existing unboundedness theorem rules out any universal constant ceiling. Useful next questions are therefore growth, record frequency, hard-class distribution, and whether the irredundant ancestry structure yields nontrivial upper bounds for large families of primes.
