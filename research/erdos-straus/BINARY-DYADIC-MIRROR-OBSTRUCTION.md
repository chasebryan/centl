# Pure-dyadic first denominators are universally obstructed on the hard-prime lane

**Status:** proved universal obstruction  
**Date:** 2026-08-15  
**Depends on:** `BINARY-R-DIVISOR-COLLISION.md`, `FAB-MIRROR-CHARACTER-OBSTRUCTION.md`  
**Claim boundary:** this rules out an apparently attractive smooth-denominator strategy. It does not prove Erdős-Straus.

---

## 1. Setup

Let `p` be Mordell-hard. Then

\[
\boxed{p\equiv1\pmod8.}
\]

Choose any `n>=1` such that

\[
2^{n+2}>p
\]

and put

\[
\boxed{A=2^n,\qquad r=4A-p=2^{n+2}-p.}
\]

Then `r>0`, and because `p==1 mod 8`,

\[
\boxed{r\equiv7\pmod8.}
\]

In particular `r` is odd and `r==3 mod 4`.

The one-denominator subtraction is

\[
\frac4p-\frac1A
=\frac r{pA}.
\]

Put

\[
N=pA=p2^n.
\]

By the binary divisor-collision theorem, the remainder can split into two unit fractions only if

\[
-1\in D_r(N)D_r(N)^{-1}.
\]

---

## 2. Every divisor ratio is dyadic modulo r

From

\[
r=2^{n+2}-p
\]

we have

\[
\boxed{p\equiv2^{n+2}\pmod r.}
\]

Every divisor of `N=p2^n` has the form

\[
p^\epsilon2^j,
\qquad
\epsilon\in\{0,1\},\quad0\le j\le n.
\]

Therefore every quotient of two divisors is, modulo `r`, a power of `2`:

\[
\boxed{
D_r(N)D_r(N)^{-1}
\subseteq
\langle2\rangle.
}
\]

Indeed replacing every occurrence of `p` by `2^(n+2)` makes this immediate.

---

## 3. Jacobi obstruction

For every odd positive integer

\[
r\equiv7\pmod8,
\]

the Jacobi symbols satisfy

\[
\boxed{\left(\frac2r\right)=+1}
\]

and

\[
\boxed{\left(\frac{-1}r\right)=-1.}
\]

Hence every power of `2` has Jacobi sign `+1` modulo `r`, while `-1` has sign `-1`.

Thus

\[
\boxed{-1\notin\langle2\rangle\pmod r.}
\]

Consequently

\[
\boxed{
D_r(N)\cap(-D_r(N))=\varnothing,
}
\]

and the binary remainder does not split.

### Theorem

For every Mordell-hard prime `p` and every positive dyadic first denominator `A=2^n` with `4A>p`, the associated binary numerator

\[
r=4A-p
\]

**cannot** rescue `p`.

QED.

---

## 4. Why this matters

The obstruction is not lack of divisor count. It is a **squareclass obstruction**.

The maximally smooth choice `A=2^n` collapses the entire signed divisor box into one Jacobi-positive subgroup, while the binary target `-1` is Jacobi-negative.

Therefore a successful smooth-denominator construction must import at least one factor carrying the opposite character.

On the Mordell-hard lane, the frozen small shield satisfies

\[
\left(\frac2p\right)
=\left(\frac3p\right)
=\left(\frac5p\right)
=\left(\frac7p\right)=+1.
\]

So the missing ingredient cannot be built solely from `2,3,5,7`. It must include a genuine external nonresidue prime or squareclass.

This independently matches:

- `FAB-HARD-NONRESIDUE-BRIDGE.md`;
- `FAB-MIRROR-CHARACTER-OBSTRUCTION.md`;
- `FAB-GCD-SURFACE-REFORMULATION.md`.

All three routes now point to the same reduced design principle:

\[
\boxed{
\text{large smooth/square bulk}
+\text{one unavoidable external nonresidue defect}.
}
\]
