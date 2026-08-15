# Exhaustion of forced-kernel detectors from the hard shield

**Status:** exact finite classification theorem  
**Date:** 2026-08-15  
**Verifier:** `fab_forced_kernel_catalog.py`  
**Depends on:** `FAB-FORCED-KERNEL-DETECTORS.md`  
**Claim boundary:** this exhausts detectors whose positive kernel is saturated using only universally forced occurrences of `2,3,5,7`. It does not exhaust detectors that use additional moving factors.

## 1. Why the classification is finite

A Mordell-hard residue class modulo `840` can universally force at most one occurrence of each of

\[
2,3,5,7
\]

into a forward or reciprocal lane base.

Each forced prime occurrence contributes signed exponent choices

\[
-1,0,+1.
\]

Therefore the signed reach of the entire hard shield has size at most

\[
\boxed{3^4=81.}
\]

If that reach fills the complete Jacobi-positive kernel

\[
H_d
\]

for an odd squarefree `d=3 mod4`, then

\[
|H_d|=\frac{\varphi(d)}2\le81.
\]

Hence

\[
\boxed{\varphi(d)\le162.}
\]

For squarefree `d`, every prime factor `q|d` contributes a factor `q-1` to `phi(d)`, so necessarily

\[
q\le163.
\]

Thus there are only finitely many candidates: enumerate all subsets of odd primes at most `163` whose product of `(q-1)` is at most `162`, retain products `d=3 mod4`, then test the exact hard-class divisibility and signed-reach condition.

No arbitrary numerical cap on `d` enters the classification.

## 2. Exact enumeration

The finite enumeration contains

\[
\boxed{41}
\]

candidate squarefree moduli satisfying the character-size bound.

For every candidate, every one of the six hard classes modulo `840`, and both forward and reciprocal lanes, `fab_forced_kernel_catalog.py` computes:

1. which occurrences among `2,3,5,7` are forced into the base;
2. the exact bounded signed reach of those occurrences modulo `d`;
3. the complete Jacobi-positive kernel `H_d`;
4. whether the forced reach contains the full kernel.

## 3. Classification theorem

Apart from the already-understood tiny endpoints, the only squarefree moduli

\[
d>7,
\qquad d\equiv3\pmod4,
\]

for which the Mordell hard shield alone can saturate the full positive kernel are

\[
\boxed{d\in\{11,19,31\}.}
\]

More precisely:

### d = 11

The forced factors are

\[
\boxed{3,5}
\]

and

\[
\Sigma_{11}(15)=H_{11}.
\]

They occur in both lanes for hard classes

\[
\boxed{169,289,529\pmod{840}.}
\]

### d = 19

The forced factors are

\[
\boxed{5,7}
\]

and

\[
\Sigma_{19}(35)=H_{19}.
\]

They occur in the forward lane for hard class

\[
\boxed{121\pmod{840}}
\]

and the reciprocal lane for hard class

\[
\boxed{361\pmod{840}.}
\]

### d = 31

The forced factors are

\[
\boxed{2,5,7}
\]

and

\[
\Sigma_{31}(70)=H_{31}.
\]

They occur in the reciprocal lane for hard class

\[
\boxed{289\pmod{840}}
\]

and the forward lane for hard class

\[
\boxed{529\pmod{840}.}
\]

There are no further `d>31` examples in the complete finite candidate set.

## 4. Interpretation

This is an exhaustion result for a **mechanism**, not merely a small-`d` census.

The factors `2,3,5,7` encoded by the classical Mordell-hard modulus `840` have now been squeezed as far as possible inside the forced-kernel architecture. They produce the universal low detectors and the class-specific extensions at `11,19,31`, but they cannot saturate a larger Jacobi-positive kernel by themselves.

Therefore any detector beyond this point must acquire genuinely new moving arithmetic information, such as:

- an external prime factor of a paired linear form;
- an adaptive factor derived from `p-1`;
- a dyadic/Mersenne escape coordinate;
- or a norm/ray-class factor selected from a larger structure.

This sharply separates the completed small-prime shield from the still-open external-nonresidue step.
