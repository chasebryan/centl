# Squarefree factor-lift shadows and an infinite quotient-nine family

**Status:** proved exact sufficient theorem and infinite nonmultiplicative shadow family  
**Date:** 2026-08-15  
**Depends on:** `ES-SQUARE-TRAP-SIGNED-BOX-IDENTITY.md`, `ES-SQUARE-MULTIPLICATIVE-SHADOW-IFF.md`, `THEORY.md`  
**Imported classical tool:** Dirichlet's theorem on primes in reduced arithmetic progressions  
**Claim boundary:** gives a broad sufficient mechanism for completed shadows when the later layer index is squarefree, including an infinite family not covered by multiplicative ancestry. It does not classify all nonmultiplicative ancestry edges or prove universal completed coverage.

---

## 1. Setup

Fix an ancestry edge

\[
\boxed{1\le j<k,
\qquad
m_j=4j-1\mid m_k=4k-1.}
\]

Let

\[
R_t=\mathcal R_{m_j}(t)
\]

denote the centered signed divisor box of an integer `t`, reduced modulo the **ancestor modulus** `m_j`.

The completed trap reduction is

\[
S_k\bmod m_j=-R_k,
\qquad
S_j=-R_j.
\]

Assume the later index is squarefree:

\[
\boxed{k=r_1r_2\cdots r_t}
\]

with distinct primes `r_i`.

Then

\[
\boxed{
R_k
=
\prod_{i=1}^t
\{r_i^{-1},1,r_i\}.}
\]

---

## 2. Factor-lift hypothesis

Suppose the earlier index admits a factorization

\[
\boxed{j=A_1A_2\cdots A_t}
\]

into positive integers, not necessarily coprime, such that after a permutation of the factors,

\[
\boxed{r_i\equiv A_i\pmod{m_j}}
\]

for every `i`.

Then

\[
\{r_i^{-1},1,r_i\}
=
\{A_i^{-1},1,A_i\}
\pmod{m_j}.
\]

But the signed divisor box of `A_i` always contains its two extreme points and the center:

\[
\boxed{
\{A_i^{-1},1,A_i\}
\subseteq
\mathcal R_{m_j}(A_i).}
\]

Therefore

\[
R_k
\subseteq
\prod_i\mathcal R_{m_j}(A_i).
\]

Signed exponent intervals add under multiplication of integers, so

\[
\prod_i\mathcal R_{m_j}(A_i)
=
\mathcal R_{m_j}\left(\prod_iA_i\right)
=
R_j.
\]

Hence:

### Theorem — squarefree factor-lift shadow

If

\[
\boxed{
k=\prod_i r_i\text{ is squarefree},
\qquad
j=\prod_i A_i,
\qquad
r_i\equiv A_i\pmod{4j-1},}
\]

and `m_j|m_k`, then

\[
\boxed{
S_k\bmod(4j-1)
\subseteq
S_j.}
\]

Thus the entire later completed layer is directly shadowed by `j`.

---

## 3. Prime-index theorem as the one-factor case

If `k` is prime, take

\[
t=1,
\qquad
A_1=j.
\]

Ancestry gives

\[
k\equiv j\pmod{m_j}.
\]

Therefore the factor-lift theorem gives

\[
S_k\bmod m_j\subseteq S_j.
\]

This recovers the direct-shadow half of `ES-SQUARE-PRIME-INDEX-SPECTRUM.md`.

So prime-index absorption is the rank-one case of a more general factor-lifting principle.

---

## 4. Quotient-nine ancestry

Now specialize to ancestry quotient

\[
\boxed{\frac{m_k}{m_j}=9.}
\]

The standard ancestry formula is

\[
\boxed{k=9j-2.}
\]

Suppose `j` is even and write

\[
\boxed{j=2h.}
\]

Then

\[
k=18h-2=2(9h-1).
\]

Put

\[
\boxed{r=9h-1.}
\]

If `r` is prime, then

\[
\boxed{k=2r}
\]

is squarefree except for the impossible case `r=2`, which does not occur here.

Modulo

\[
m_j=8h-1,
\]

we have

\[
\boxed{2\equiv2}
\]

and

\[
r=9h-1
\equiv h
=\frac j2
\pmod{m_j}.
\]

The earlier index factorization is

\[
\boxed{j=2\cdot\frac j2.}
\]

Thus the two prime factors of `k` lift exactly to the two factors of `j`.

The factor-lift theorem applies and gives

\[
\boxed{
S_{2r}\bmod(4j-1)
\subseteq
S_j.}
\]

---

## 5. Parameterization by primes r = 8 mod 9

The relation

\[
r=9h-1
\]

is equivalent to

\[
\boxed{r\equiv8\pmod9.}
\]

Conversely, let `r` be any prime in that residue class and define

\[
\boxed{
h=\frac{r+1}{9},
\qquad
j=2h=\frac{2(r+1)}9,
\qquad
k=2r.}
\]

Then

\[
4j-1
=
\frac{8(r+1)}9-1
=
\frac{8r-1}{9},
\]

while

\[
4k-1=8r-1.
\]

Therefore

\[
\boxed{
4k-1=9(4j-1).}
\]

So this is an exact quotient-nine ancestry edge.

And the factor congruences are precisely

\[
2\equiv2,
\qquad
r\equiv\frac j2
\pmod{4j-1}.
\]

Hence:

### Theorem — quotient-nine semiprime shadow family

For every prime

\[
\boxed{r\equiv8\pmod9,}
\]

the layer

\[
\boxed{k=2r}
\]

is completely directly shadowed by

\[
\boxed{j=\frac{2(r+1)}9.}
\]

The moduli satisfy

\[
\boxed{m_k=9m_j.}
\]

Thus `2r` is impossible as a square-completed minimal depth.

---

## 6. Infinite family

Because

\[
\gcd(8,9)=1,
\]

Dirichlet's theorem gives infinitely many primes

\[
\boxed{r\equiv8\pmod9.}
\]

Therefore the quotient-nine theorem supplies infinitely many squarefree semiprime structural gaps

\[
\boxed{k=2r.}
\]

This family is genuinely nonmultiplicative:

\[
j\nmid k
\]

for all but trivial impossible coincidences.

So it lies outside the exact multiplicative-extension classification of `ES-SQUARE-MULTIPLICATIVE-SHADOW-IFF.md`.

---

## 7. Examples

### r = 17

\[
r\equiv8\pmod9,
\qquad
j=4,
\qquad
k=34.
\]

Then

\[
m_j=15,
\qquad
m_k=135=9\cdot15,
\]

and

\[
S_{34}\bmod15\subseteq S_4.
\]

### r = 53

\[
j=12,
\qquad
k=106,
\]

with

\[
423=9\cdot47.
\]

Thus

\[
S_{106}\bmod47\subseteq S_{12}.
\]

### r = 71

\[
j=16,
\qquad
k=142,
\]

and

\[
567=9\cdot63.
\]

Again the later completed layer is directly redundant.

---

## 8. Why factor lifting is different from stabilizer extension

The multiplicative-extension theorem treats

\[
k=jB
\]

and explains shadowing through the stabilizer of the ancestor box.

The present theorem treats a different mechanism:

- `j` need not divide `k`;
- the **prime factors of the later index** project to whole multiplicative factors of the earlier index;
- each three-point prime direction of the later box embeds into the larger signed box of its lifted ancestor factor.

Thus there are now two exact cross-layer mechanisms:

\[
\boxed{
\begin{array}{ll}
\text{stabilizer extension}:&
\text{new directions are invisible},\\[1mm]
\text{factor lift}:&
\text{new prime directions become existing ancestor factors}.
\end{array}}
\]

The quotient-nine family proves that nonmultiplicative completed ancestry has infinite exact structure rather than being only sporadic finite overlap.

---

## 9. Next target

The natural generalization is to ancestry quotient

\[
Q=4s+1
\]

with

\[
k=Qj-s.
\]

Search for factorizations of `k` into few prime factors whose residues modulo `m_j` lift a factorization of `j`.

The first targets are:

1. other fixed quotients `Q=13,17,21,...`;
2. two-prime later indices `k=uv`;
3. systematic CRT/Dirichlet constructions producing infinite factor-lift families.

A successful classification would turn the remaining nonmultiplicative ancestry graph into a finite collection of factor-lift templates rather than a raw residue-containment problem.
