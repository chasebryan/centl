# Exact classification of multiplicative-ancestry shadows

**Status:** proved necessary-and-sufficient theorem  
**Date:** 2026-08-15  
**Depends on:** `ES-SQUARE-STABILIZER-EXTENSION-SHADOW.md`, `ES-SQUARE-TRAP-SIGNED-BOX-IDENTITY.md`, `THEORY.md`  
**Claim boundary:** completely classifies direct shadow by `j` for square-completed descendants of the form `k=jB` along a modulus-ancestry edge. It does not classify ancestry edges for which `j` does not divide `k` and does not prove universal completed coverage.

---

## 1. Setup

Fix

\[
\boxed{j\ge1}
\]

and put

\[
\boxed{m=4j-1.}
\]

Let

\[
R_j=\mathcal R_m(j)
\]

be the completed signed divisor box of `j` reduced modulo its own modulus, and let

\[
\boxed{H_j=\operatorname{Stab}(R_j).}
\]

Take an integer

\[
\boxed{B\ge1}
\]

and define

\[
\boxed{k=jB.}
\]

Assume the modulus-ancestry condition

\[
\boxed{m_j\mid m_k.}
\]

Since `j` is a unit modulo `m`, this is equivalent to

\[
\boxed{B\equiv1\pmod m.}
\]

---

## 2. Exact product factorization

Write

\[
j=\prod_p p^{E_p},
\qquad
B=\prod_p p^{F_p}.
\]

Then

\[
k=\prod_p p^{E_p+F_p}.
\]

The signed exponent interval satisfies

\[
[-E_p-F_p,E_p+F_p]
=
[-E_p,E_p]+[-F_p,F_p].
\]

Therefore reduction modulo `m` gives the exact product-set identity

\[
\boxed{
\mathcal R_m(k)
=R_j\,R_B,}
\]

where

\[
R_B=\mathcal R_m(B).
\]

Because the zero exponent is always allowed,

\[
\boxed{1\in R_B.}
\]

Hence

\[
\boxed{R_j\subseteq\mathcal R_m(k).}
\]

This one inclusion turns the direct-shadow condition into an equality condition.

---

## 3. Direct shadow forces equality

The completed trap is the negative signed box:

\[
S_t=-\mathcal R_{m_t}(t).
\]

Along the ancestry edge, layer `k` is directly shadowed by `j` exactly when

\[
S_k\bmod m\subseteq S_j.
\]

Multiplying by `-1`, this is

\[
\mathcal R_m(k)\subseteq R_j.
\]

But the previous section already gave

\[
R_j\subseteq\mathcal R_m(k).
\]

Therefore:

### Lemma — multiplicative shadow is exact reduction

For `k=jB` on an ancestry edge,

\[
\boxed{
S_k\bmod m_j\subseteq S_j
\iff
S_k\bmod m_j=S_j.}
\]

There is no proper completed containment in this multiplicative setting.

---

## 4. Necessity of stabilizer support

Assume direct shadow holds. Then

\[
R_jR_B=R_j.
\]

Let `r` be any prime divisor of `B`.

Because `v_r(B)>=1`, the signed box `R_B` contains the residue `r`: choose exponent `+1` at `r` and zero at every other prime.

Thus

\[
r\in R_B.
\]

From

\[
R_jR_B=R_j
\]

we obtain

\[
R_jr\subseteq R_j.
\]

Multiplication by the unit `r mod m` is a bijection of the ambient unit group, so

\[
|R_jr|=|R_j|.
\]

A finite subset contained in another subset of the same size must be equal. Hence

\[
R_jr=R_j.
\]

Therefore

\[
\boxed{r\in H_j.}
\]

Since `r` was arbitrary:

\[
\boxed{
\text{direct shadow}
\Longrightarrow
r\bmod m_j\in H_j
\text{ for every prime }r\mid B.}
\]

---

## 5. Sufficiency

Conversely, suppose every prime divisor of `B` lies in `H_j` modulo `m`.

Then every signed product formed from those primes also lies in the subgroup `H_j`, so

\[
R_B\subseteq H_j.
\]

Hence

\[
R_jR_B
\subseteq
R_jH_j
=R_j.
\]

Since `1 in R_B`, the reverse inclusion holds. Therefore

\[
R_jR_B=R_j.
\]

Thus

\[
S_k\bmod m_j=S_j.
\]

---

## 6. Exact iff theorem

Combining necessity and sufficiency:

### Theorem — multiplicative-ancestry shadow classification

Let

\[
\boxed{k=jB}
\]

and assume

\[
\boxed{4j-1\mid4k-1,}
\]

equivalently

\[
\boxed{B\equiv1\pmod{4j-1}.}
\]

Then the following are equivalent:

1. the completed layer `k` is directly shadowed by `j`;
2. the reduction is exactly equal:
   \[
   S_k\bmod(4j-1)=S_j;
   \]
3. every prime divisor `r` of `B` satisfies
   \[
   \boxed{r\bmod(4j-1)\in H_j.}
   \]

Symbolically,

\[
\boxed{
S_{jB}\bmod m_j\subseteq S_j
\iff
\operatorname{supp}(B)\bmod m_j\subseteq H_j.}
\]

This is a complete classification of direct shadows on multiplicative ancestry edges.

---

## 7. Irreducible multiplicative descendants

The theorem identifies the exact obstruction to shadowing.

A multiplicative ancestry descendant `k=jB` can remain directly novel relative to `j` only if

\[
\boxed{
\exists r\mid B:
 r\bmod m_j\notin H_j.}
\]

Such a prime is a genuinely new projected direction in the ancestor quotient

\[
G_j/H_j.
\]

Therefore the natural **multiplicative ancestry kernel** of the extension is obtained by deleting all prime-power factors whose prime bases lie in `H_j`.

If nothing remains, the descendant is exactly redundant.

If something remains, Kneser theory should be applied only to those quotient-visible prime directions.

---

## 8. Prime extension as an immediate corollary

If `B=r` is prime, the ancestry condition itself gives

\[
r\equiv1\pmod m.
\]

Thus `r` is automatically in `H_j`.

Hence every prime multiplicative extension on an ancestry edge is completely shadowed:

\[
\boxed{
k=jr,\quad m_j\mid m_k
\Longrightarrow
S_k\bmod m_j=S_j.}
\]

This recovers `ES-SQUARE-PRIME-EXTENSION-SHADOW.md` without a separate hypothesis beyond ancestry.

---

## 9. Relation to Kneser defect quotients

The theorem turns cross-layer novelty into a quotient statement.

For a multiplicative descendant, every extension prime outside `H_j` has a nontrivial class in

\[
G_j/H_j.
\]

Those are exactly the directions capable of enlarging the projected completed box.

Thus:

\[
\boxed{
\text{cross-layer novelty}
=
\text{nontrivial extension support in the ancestor stabilizer quotient}.}
\]

This is the exact algebraic merger of modulus ancestry and internal stabilizer theory for the divisible-index case.

---

## 10. Next target

The remaining ancestry problem splits cleanly:

1. **multiplicative ancestry** `j|k`: solved by the theorem above;
2. **nonmultiplicative ancestry** `j\nmid k`: still open and governed by the affine relation
   \[
   k=(4s+1)j-s.
   \]

The second class is now the genuinely new cross-layer frontier.

A useful next program is to determine whether those nonmultiplicative edges admit an analogous factorization after translating the layer index by the ancestry parameter `s`, or whether they require a different quotient object entirely.
