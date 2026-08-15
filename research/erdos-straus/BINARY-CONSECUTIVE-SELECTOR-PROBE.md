# Consecutive binary-selector probe

**Status:** exact finite theorem-mining record; proposed fixed bound `u<=15` falsified  
**Date:** 2026-08-15  
**Depends on:** `BINARY-R-RESCUE.md`, `BINARY-R-DIVISOR-COLLISION.md`  
**Claim boundary:** finite exact evidence only. No fixed universal selector bound is claimed.

## 1. Consecutive parametrization

Write a Mordell-hard prime as

\[
p=24n+1
\]

and put

\[
P=\frac{p-1}{4}=6n.
\]

For every positive integer `u`, choose

\[
\boxed{r_u=4u-1.}
\]

Then `r_u==3 mod 4` and the first denominator is exactly

\[
\boxed{A_u=\frac{p+r_u}{4}=P+u.}
\]

Thus the binary program probes the multiplicative divisor geometry of the consecutive integers

\[
P+1,P+2,P+3,\ldots
\]

without requiring `r_u` to be prime.

## 2. Important correction

Earlier prime-`r` probes skipped composite values such as

\[
r=15,\ 39,\ 51,\ldots
\]

but the exact signed-divisor collision theorem only requires `r==3 mod4` and the relevant coprimality, not primality.

Therefore composite numerators are legitimate and must be included in theorem mining.

## 3. Finite signal through two million

On the exact Mordell-hard prime population below approximately `2*10^6`, every tested prime had a binary rescue for some

\[
1\le u\le15.
\]

This initially suggested a possible fixed-selector theorem.

## 4. Falsification through ten million

The full hard-prime census through

\[
p\le10^7
\]

contains the explicit counterexample to the proposed bound

\[
\boxed{p=8,803,369.}
\]

For this prime, the exact binary collision test fails for every

\[
\boxed{1\le u\le15.}
\]

Its first hit in the consecutive selector is

\[
\boxed{u=27,\qquad r=107.}
\]

Here

\[
A_{27}=\frac{p+107}{4}=2,200,869
=3^2\cdot11^2\cdot43\cdot47.
\]

An explicit signed-divisor collision is

\[
\boxed{1\equiv-18,189\pmod{107},}
\]

with

\[
18,189=3^2\cdot43\cdot47\mid A_{27}.
\]

Indeed

\[
18,189+1=18,190=107\cdot170.
\]

So the `u=27` rescue is exact, not a heuristic hit.

## 5. Research consequence

The attractive statement

\[
\text{“the first 15 consecutive selectors always suffice”}
\]

is false and must not be used.

The surviving signal is weaker but still useful:

- allowing composite `r_u=4u-1` materially improves the selector program;
- late hits correlate with a shifted integer `P+u` acquiring enough multiplicative residue diversity to create the signed collision;
- the hard case is therefore about **how long consecutive multiplicative compression can persist**, not about primality of the binary numerator.

Any universal selector theorem must allow an adaptive or unbounded `u`, or prove a larger bound from genuine structure rather than finite data.
