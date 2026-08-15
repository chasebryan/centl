# Exact counterexample to the `(p-1)/2` divisor-lift conjecture

**Status:** explicit finite counterexample to a project conjecture  
**Date:** 2026-08-15  
**Target disproved:** universal existence of a successful `t|(p-1)/2` node with `d=4t-1`  
**Does not affect:** Erdős–Straus itself, the fab parametrization, the reciprocal-double-sieve theorems, or the six-form detector theorem.

## 1. Prime

Take

\[
\boxed{p=9,078,191,439,529.}
\]

Direct primality testing gives `p` prime, and

\[
\boxed{p\bmod840=289,}
\]

so it lies in a Mordell-hard residue class.

## 2. Sparse adaptive divisor lattice

Put

\[
V=\frac{p-1}{2}=4,539,095,719,764.
\]

Then

\[
\boxed{
V=2^2\cdot3\cdot378,257,976,647,
}
\]

with

\[
\boxed{r=378,257,976,647\text{ prime}.}
\]

Thus

\[
\operatorname{Div}(V)
=
\{1,2,3,4,6,12,r,2r,3r,4r,6r,12r\}.
\]

This is the smallest kind of divisor lattice on which the adaptive conjecture could plausibly fail: the universal `2,3` skeleton plus one large prime direction.

## 3. Every adaptive node fails

For each

\[
t\in\operatorname{Div}(V),
\qquad
 d_t=4t-1,
\]

both exact criteria were checked:

### Forward

\[
\exists D\mid\left(\frac{p+d_t}{4}\right)^2:
\quad4D\equiv-1\pmod{d_t},
\]

### Reciprocal

\[
\exists D\mid\left(\frac{pd_t+1}{4}\right)^2:
\quad4D\equiv-1\pmod{d_t}.
\]

Neither criterion succeeds at any of the twelve nodes.

For the six large nodes, the paired bases factor as follows.

Let `r=378257976647`.

### t = r

\[
X=7r,
\]

and

\[
Y=r\cdot41\cdot269\cdot21863\cdot37649.
\]

### t = 2r

\[
X=2^3r,
\]

and

\[
Y=2^2\cdot11\cdot31\cdot5743\cdot2317801\cdot r.
\]

### t = 3r

\[
X=3^2r,
\]

and

\[
Y=3\cdot7\cdot157\cdot619\cdot13344767\cdot r.
\]

### t = 4r

\[
X=2\cdot5\cdot r,
\]

and

\[
Y=2\cdot5\cdot743059\cdot4886929\cdot r.
\]

### t = 6r

\[
X=2^2\cdot3\cdot r,
\]

and

\[
\boxed{Y=2^4\cdot3^2\cdot r^2.}
\]

### t = 12r

\[
X=2\cdot3^2\cdot r,
\]

and

\[
Y=2\cdot3\cdot53\cdot2129\cdot11789\cdot13649\cdot r.
\]

Exact signed-divisor residue enumeration at the corresponding moduli `4t-1` finds no target hit in either lane.

## 4. The prime is nevertheless solved immediately outside the falsified lattice

The first small reciprocal-double-sieve hit is the **forward** lane at

\[
\boxed{d=31.}
\]

This corresponds to

\[
\boxed{t=8,}
\]

because `31=4*8-1`.

But

\[
8\nmid\frac{p-1}{2},
\]

while

\[
\boxed{8\mid p-1.}
\]

So the prime is not an Erdős–Straus counterexample. It is a counterexample only to the proposed restriction of the fab search to the divisor lattice of `(p-1)/2`.

## 5. Interpretation

This prime demonstrates a clean dyadic defect:

\[
\frac{p-1}{2}
\]

contains only `2^2`, while the first rescuing structural node requires `2^3` through `t=8`.

That is the exact same phenomenon seen one level lower when the smaller proposal `t|(p-1)/4` failed on primes rescued by `t=4`.

The evidence therefore suggests a hierarchy

\[
\operatorname{Div}\!\left(\frac{p-1}{4}\right)
\subset
\operatorname{Div}\!\left(\frac{p-1}{2}\right)
\subset
\operatorname{Div}(p-1)
\subset\cdots
\]

rather than a proof tied permanently to one divisor lattice.

Any next conjecture in this direction must be attacked explicitly for the possibility that another prime requires the next missing power of `2`.
