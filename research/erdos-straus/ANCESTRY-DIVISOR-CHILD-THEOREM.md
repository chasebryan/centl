# Divisor-child ancestry theorem for Type A/B shadowing

**Status:** proved universal theorem with coordinator-reviewed `q=13` and `q=17` classifications  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Coordinator:** Operator-01 / primary research lead  
**Operator-02 provenance:** `operator-02/ANCESTRY-Q13-CLASSIFICATION.md`, `operator-02/ANCESTRY-Q17-CLASSIFICATION.md`  
**Claim boundary:** this note concerns unrestricted Type A/B trap-set shadowing along modulus ancestry. It does not prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture. Hard-class-conditioned shadowing can be stronger than unrestricted shadowing.

Read with:

- [THEORY.md](THEORY.md)
- [PRIME-CHILD-SHADOWS.md](PRIME-CHILD-SHADOWS.md)
- [QUOTIENT-9-RIGIDITY.md](QUOTIENT-9-RIGIDITY.md)
- [OPERATOR-COORDINATION.md](OPERATOR-COORDINATION.md)

## 1. General ancestry parameter

Fix positive integers `j` and `s`, and put

\[
Q=4s+1,
\qquad
K=Qj-s.
\]

Then

\[
4K-1
=Q(4j-1).
\]

Write

\[
m=4j-1.
\]

Thus `j -> K` is a modulus-divisibility ancestry edge with quotient `Q`.

The elementary identity

\[
\boxed{K=s m+j}
\]

gives

\[
K\equiv j\pmod m
\]

and

\[
\gcd(j,K)=\gcd(j,s).
\]

Define the normalized ancestor trap set

\[
S_j=-T_j
=\{e,4e\pmod m:e\mid j\}.
\]

As in the existing ancestry theory,

\[
T_K\bmod m\subseteq T_j
\]

is equivalent to requiring every divisor of `K`, reduced modulo `m`, to lie in `S_j`.

## 2. Divisor-child theorem

### Theorem

Let

\[
a\mid\gcd(j,s)
\]

and suppose

\[
\boxed{K=a p}
\]

for a prime `p`.

Then

\[
\boxed{T_K\bmod(4j-1)\subseteq T_j.}
\]

In words:

> whenever the child depth is a prime multiplied by a divisor common to the ancestry shift `s` and the ancestor depth `j`, the entire child Type A/B trap set is shadowed by the ancestor.

### Proof

Write

\[
j=a d,
\qquad
s=a c.
\]

Then

\[
p=\frac Ka
=\frac{(4s+1)j-s}{a}.
\]

Subtract `d=j/a`:

\[
\begin{aligned}
p-d
&=4sd-c\\
&=c(4ad-1)\\
&=c(4j-1)\\
&=c m.
\end{aligned}
\]

Hence

\[
\boxed{p\equiv d=j/a\pmod m.}
\]

Every divisor `E` of `K=a p` can be written in one of the forms

\[
E=b
\quad\text{or}\quad
E=bp
\]

for some divisor `b|a`. This remains true if `p|a`: divisors with the final extra `p`-exponent use the second form.

If `E=b`, then

\[
b\mid a\mid j,
\]

so `E` is an ancestor divisor and lies in `S_j`.

If `E=bp`, then

\[
E\equiv b\frac ja\pmod m.
\]

But

\[
b\frac ja
=\frac{j}{a/b}
\]

is again a divisor of `j`. Therefore `E mod m` lies in `S_j`.

Thus every divisor of `K` maps into `S_j`, proving

\[
T_K\bmod m\subseteq T_j.
\]

QED.

## 3. Prime-child theorem as the first case

Taking

\[
a=1
\]

recovers the existing prime-child theorem immediately:

\[
K\text{ prime}
\Longrightarrow
T_K\bmod m\subseteq T_j.
\]

So prime children are the `a=1` edge of a larger divisor-child family.

## 4. Immediate ancestry ladder

For a fixed ancestry shift `s`, every divisor

\[
a\mid s
\]

that also divides `j` supplies a potential fully shadowed child shape

\[
\boxed{K=a p,\quad p\text{ prime}.}
\]

This predicts the exact composite families independently observed at the first ancestry quotients.

### Q = 5

Here `s=1`, so only `a=1` exists:

\[
K=p.
\]

This agrees with the proved `q=5` rigidity theorem: unrestricted full shadow occurs only for prime children.

### Q = 9

Here `s=2`, so

\[
a\in\{1,2\}.
\]

The theorem gives

\[
K=p\quad\text{or}\quad K=2p.
\]

The existing exact classification adds one exceptional smooth child

\[
(j,K)=(2,16).
\]

### Q = 13

Here `s=3`, so

\[
a\in\{1,3\}.
\]

The theorem gives

\[
K=p\quad\text{or}\quad K=3p.
\]

Operator-02 independently proved that these are not merely sufficient but exhaustive.

### Q = 17

Here `s=4`, so

\[
a\in\{1,2,4\}.
\]

The theorem gives

\[
K=p,\quad2p,\quad4p.
\]

Operator-02 independently proved the full converse, with one exceptional smooth child

\[
(j,K)=(4,64).
\]

## 5. Coordinator review: q = 13 classification

Operator-02 source:

`operator-02/ANCESTRY-Q13-CLASSIFICATION.md`

### Accepted theorem

Let

\[
K=13j-3.
\]

Then

\[
\boxed{
T_K\bmod(4j-1)\subseteq T_j
\iff
K\text{ is prime or }K=3p\text{ with }p\text{ prime}.
}
\]

The direct implication is now subsumed by the divisor-child theorem with `s=3`.

The Operator-02 converse was reviewed by the Coordinator. Its case split is sound:

1. if `j` is odd and `K` composite, divisor `2` escapes `S_j`;
2. if `j` is even and `3∤j`, a least prime factor of composite `K` is `<m`, does not divide `j`, and escapes `S_j`;
3. if `j=3d`, write `K=3(13d-1)`; when the cofactor is composite, a least non-3 prime factor escapes, while the remaining `3`-divisible subcase gives divisor `9`, and `9∉S_j` because `9∤j`.

No coarse signature/exact-trap equivalence is used.

Coordinator classification: **PROVED / promoted**.

## 6. Coordinator review: q = 17 classification

Operator-02 source:

`operator-02/ANCESTRY-Q17-CLASSIFICATION.md`

### Accepted theorem

Let

\[
K=17j-4.
\]

Then

\[
\boxed{
T_K\bmod(4j-1)\subseteq T_j
\iff
\begin{cases}
K\text{ prime},\text{ or}\\
K=2p,\text{ or}\\
K=4p,\text{ or}\\
(j,K)=(4,64),
\end{cases}
}
\]

where `p` is an odd prime in the composite prime-times-divisor cases.

The direct prime/`2p`/`4p` implications follow from the divisor-child theorem with `s=4`.

The Coordinator reviewed the converse by 2-adic cases:

- odd `j`: a least prime factor of composite `K` escapes;
- `v2(K)=1`: after `j=2d`, a least prime factor of the odd composite cofactor escapes;
- `v2(K)=2`: same after `j=4d`;
- `v2(K)=3` or `4`: the odd cofactor lies strictly between `j` and `m` and hence cannot be in `S_j`;
- `v2(K)>=5`: `j≡4 mod8`, so `v2(j)=2`; divisor `32` escapes except at `j=4`, where `K=64` and the power-of-two residues are explicitly contained in `S_4`.

Coordinator classification: **PROVED / promoted**.

## 7. New structural conjecture: prime-times-common-divisor plus smooth exceptions

The first four exact ancestry quotients now have a common form:

\[
\boxed{
\text{full shadow child}
=
\text{prime}\times a,\quad a\mid\gcd(j,s),
}
\]

plus rare children whose entire factorization is supported on the small primes of the shift `s`.

This motivates the following theorem candidate.

### Ancestry converse candidate

For fixed `s` and sufficiently large `j`, if

\[
T_{(4s+1)j-s}\bmod(4j-1)\subseteq T_j,
\]

then

\[
\boxed{K=a p}
\]

for some

\[
a\mid\gcd(j,s)
\]

and prime `p`, except possibly for a finite set of `s`-smooth children.

This is **not proved** in general.

## 8. Why a general converse is plausible

Let `ell|K` be a prime not dividing `j`.

If

\[
1<\ell<m=4j-1,
\]

then `ell` cannot lie in `S_j`:

- it is not a plain divisor of `j`;
- as a prime it cannot equal `4e` for a proper divisor `e|j`;
- the endpoint `4j` reduces to `1`, not `ell`.

Thus under full shadowing, every prime factor of `K` below `m` must divide `j`, and hence must divide

\[
\gcd(j,K)=\gcd(j,s).
\]

Any prime factor not supported by the shift must therefore be at least `m`.

Since

\[
K=(4s+1)j-s
\]

grows linearly in `j` while `m^2` grows quadratically, for fixed `s` and large `j` one has

\[
K<m^2.
\]

Consequently there can be at most one prime factor outside the shift support.

This is the mechanism behind the observed prime-times-common-divisor families. The remaining work is to control excessive powers of the shift primes and classify the finite smooth exceptions.

## 9. Proof target

The next ancestry theorem should formalize Section 8 into:

1. an explicit threshold `J(s)` above which `K<m^2`;
2. a bound on the exponents of primes dividing `gcd(j,s)` under full shadowing;
3. a finite classification of `s`-smooth exceptions below that threshold or with exceptional exponent cycles;
4. a general converse yielding the divisor-child family as the complete asymptotic ancestry skeleton.

If successful, the separate `q=5,9,13,17,...` rigidity calculations collapse into one theorem.

That would turn the ancestry portion of the shadow graph from a collection of observed quotient families into a single structural law.
