# Quantitative infinite-coinfinite spectrum for square-completed Type-II depth

**Status:** proved theorem  
**Date:** 2026-08-15  
**Depends on:** `ES-SQUARE-COMPLETION-BACKBONE.md`, `ES-SQUARE-SQUAREFREE-FACTOR-LIFT.md`, `ES-SQUARE-ALL-QUOTIENT-FACTOR-LIFT.md`  
**Imported classical tool:** prime number theorem in arithmetic progressions  
**Claim boundary:** proves quantitative lower bounds for both realized exact depths and structural-gap depths in the classical strong/Type-II completed system. It does not prove that every prime has a Type-II solution.

---

## 1. Completed minimal-depth spectrum

For each layer

\[
a\ge1,
\]

define

\[
m_a=4a-1
\]

and the completed strong/Type-II trap

\[
S_a=\{-4D\pmod{m_a}:D\mid a^2\}.
\]

Let

\[
\boxed{\mathcal D_{\rm sq}}
\]

denote the set of layer indices `a` that occur as exact first completed depths for infinitely many Mordell-hard primes.

Let

\[
\boxed{\mathcal G_{\rm sq}}
\]

denote the set of **structural gaps**, meaning layer indices that cannot be the first completed hit of any integer because the whole layer is already shadowed by an earlier layer.

The two sets are disjoint.

---

## 2. Realized-depth lower bound from the prime-modulus backbone

`ES-SQUARE-COMPLETION-BACKBONE.md` proves that whenever

\[
q=4a-1>7
\]

is prime, the depth `a` is realized by infinitely many Mordell-hard primes.

Therefore

\[
\boxed{
\left\{\frac{q+1}{4}:q>7\text{ prime},\ q\equiv3\pmod4\right\}
\subseteq
\mathcal D_{\rm sq}.}
\]

Hence

\[
|\mathcal D_{\rm sq}\cap[1,K]|
\ge
\pi(4K-1;4,3)+O(1).
\]

The prime number theorem in arithmetic progressions gives

\[
\pi(x;4,3)
\sim
\frac12\operatorname{Li}(x).
\]

Therefore

\[
\boxed{
|\mathcal D_{\rm sq}\cap[1,K]|
\ge
(1+o(1))\frac{2K}{\log(4K)}.}
\]

In particular the completed exact-depth spectrum is infinite.

---

## 3. Structural-gap lower bound from the quotient-nine family

`ES-SQUARE-SQUAREFREE-FACTOR-LIFT.md` proves that for every prime

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

Therefore

\[
\boxed{
\{2r:r\text{ prime},\ r\equiv8\pmod9\}
\subseteq
\mathcal G_{\rm sq}.}
\]

If

\[
k=2r\le K,
\]

then

\[
r\le K/2.
\]

Thus

\[
|\mathcal G_{\rm sq}\cap[1,K]|
\ge
\pi(K/2;9,8)+O(1).
\]

Since

\[
\varphi(9)=6,
\]

the prime number theorem in arithmetic progressions gives

\[
\pi(x;9,8)
\sim
\frac16\operatorname{Li}(x).
\]

Hence

\[
\boxed{
|\mathcal G_{\rm sq}\cap[1,K]|
\ge
(1+o(1))\frac{K}{12\log K}.}
\]

In particular the structural-gap set is infinite.

---

## 4. Infinite and coinfinite

Because

\[
\mathcal D_{\rm sq}
\]

contains infinitely many realized prime-modulus depths, while

\[
\mathcal G_{\rm sq}
\]

contains infinitely many impossible quotient-nine depths, the completed minimal-depth spectrum is neither finite nor cofinite.

### Theorem — completed spectrum is infinite and coinfinite

\[
\boxed{
\mathcal D_{\rm sq}\text{ is infinite and has infinite complement}.}
\]

More quantitatively, both sides already contain explicit arithmetic subfamilies of order

\[
\boxed{K/\log K.}
\]

---

## 5. Arithmetic backbone and anti-backbone

The two explicit families have complementary meanings.

### Backbone

Prime target moduli

\[
4a-1\text{ prime}
\]

produce independent CRT coordinates and guarantee infinitely many exact arrivals.

### Anti-backbone

The quotient-nine semiprime layers

\[
a=2r,
\qquad
r\equiv8\pmod9
\]

are exact factor-lift descendants and can never be first arrivals.

Thus the completed spectrum contains both:

\[
\boxed{
\text{an infinite arithmetic backbone of necessary depths}}
\]

and

\[
\boxed{
\text{an infinite arithmetic anti-backbone of forbidden depths}.}
\]

---

## 6. Comparison of scales

The explicit realized family has lower-bound scale

\[
\frac{2K}{\log(4K)},
\]

while the single quotient-nine gap family already has scale

\[
\frac{K}{12\log K}.
\]

The all-quotient factor-lift theorem supplies many additional structural-gap families, so the latter constant is not expected to be optimal.

No asymptotic density for the full spectrum or full gap set is claimed here.

The point is only that neither side is a sparse logarithmic curiosity: both have at least prime-counting order.

---

## 7. Consequence for first-depth modeling

Any model that treats completed depth as a nearly contiguous set with occasional exceptional gaps is false.

Any model that treats the spectrum as only the prime-modulus backbone is also false in finite data, because many composite-index depths are realized.

The correct object has three components:

1. guaranteed prime-modulus arrivals;
2. guaranteed ancestry/factor-lift structural gaps;
3. a genuinely arithmetic composite residual spectrum.

The current proof program should focus on the third component rather than trying to remove either of the first two.

---

## 8. Strong-conjecture boundary

These depth statements belong to the completed strong/Type-II system.

They do **not** say that every prime has a Type-II hit.

A hypothetical failure of the strong conjecture could still avoid every completed layer, even though the set of realizable layer depths itself is infinite and arithmetically rich.

Thus spectrum structure and universal prime coverage remain logically distinct questions.
