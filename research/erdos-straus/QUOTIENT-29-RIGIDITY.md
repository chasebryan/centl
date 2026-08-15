# Quotient-29 shadow rigidity

**Status:** proved theorem inside the Type A/B minimal-depth/shadow program  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** unrestricted Type A/B trap-set shadowing only. Does not prove universal DSC-P, López coverage, or Erdős-Straus.

Read with:

- [ANCESTRY-DIVISOR-CHILD-THEOREM.md](ANCESTRY-DIVISOR-CHILD-THEOREM.md)
- [ANCESTRY-ASYMPTOTIC-SKELETON.md](ANCESTRY-ASYMPTOTIC-SKELETON.md)
- [QUOTIENT-21-29-RIGIDITY.md](QUOTIENT-21-29-RIGIDITY.md)

## Theorem

Let

\[
K=29j-7,
\qquad
m=4j-1.
\]

Then

\[
\boxed{
T_K\bmod m\subseteq T_j
\iff
K\text{ is prime or }K=7p\text{ with }p\text{ prime}.
}
\]

In the second alternative necessarily `7|j`.

## Direct implication

This is the divisor-child theorem with shift `s=7`.

The only divisors of `7` are `1` and `7`, giving prime children and `7p` children when `7|j`.

## Converse for j >= 8

Because `s=7` is odd and `j>=s+1`, the odd-shift asymptotic skeleton applies.

Hence every full shadow is either:

1. `7`-smooth, so `K=7^u`; or
2. prime or `7p`.

If `K=7^u>7`, then `49|K`. Whenever `49<m`, the odd divisor `49` lies below `m`, while

\[
\gcd(j,K)=\gcd(j,7)
\]

shows `49∤j`. Thus `49∉S_j`, impossible.

Therefore a smooth exception requires

\[
m\le49.
\]

With `j>=8`, this leaves only

\[
8\le j\le12.
\]

## Exact finite window j = 1,...,12

```text
j=1:  K=22,  m=3;  divisor 2 escapes.
j=2:  K=51,  m=7;  divisor 3 escapes.
j=3:  K=80,  m=11; divisor 2 escapes.
j=4:  K=109;        prime, shadowed.
j=5:  K=138, m=19; divisor 2 escapes.
j=6:  K=167;        prime, shadowed.
j=7:  K=196, m=27; divisor 2 escapes.
j=8:  K=225, m=31; divisor 3 escapes.
j=9:  K=254, m=35; divisor 2 escapes.
j=10: K=283;        prime, shadowed.
j=11: K=312, m=43; divisor 2 escapes.
j=12: K=341, m=47; divisor 11 escapes.
```

Thus no smooth or other exceptional child survives the finite window. For `j>=13`, the skeleton leaves only prime or `7p`.

This completes the classification. QED.

## Regression note

Earlier drafts referred to a bounded computational gate in the small range. The canonical proof no longer needs that gate: all twelve small values are displayed with explicit escaping divisors or primality.
