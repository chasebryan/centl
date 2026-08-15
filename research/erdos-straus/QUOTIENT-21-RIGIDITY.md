# Quotient-21 shadow rigidity

**Status:** proved theorem inside the Type A/B minimal-depth/shadow program  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Provenance:** Operator-02 first isolated/proved the `5p` pattern; the canonical proof below is the Coordinator's independent proof via the general ancestry skeleton.  
**Claim boundary:** unrestricted Type A/B trap-set shadowing only. Does not prove universal DSC-P, López coverage, or Erdős-Straus.

Read with:

- [ANCESTRY-DIVISOR-CHILD-THEOREM.md](ANCESTRY-DIVISOR-CHILD-THEOREM.md)
- [ANCESTRY-ASYMPTOTIC-SKELETON.md](ANCESTRY-ASYMPTOTIC-SKELETON.md)
- [QUOTIENT-21-29-RIGIDITY.md](QUOTIENT-21-29-RIGIDITY.md)

## Theorem

Let

\[
K=21j-5,
\qquad
m=4j-1.
\]

Then

\[
\boxed{
T_K\bmod m\subseteq T_j
\iff
K\text{ is prime or }K=5p\text{ with }p\text{ prime}.
}
\]

In the second alternative necessarily `5|j`.

## Direct implication

This is the divisor-child theorem with shift `s=5`.

The only divisors of `5` are `1` and `5`, giving respectively:

- prime children;
- `K=5p` when `5|j`.

Both are fully shadowed.

## Converse for j >= 6

Since the shift `s=5` is odd and

\[
j\ge s+1=6,
\]

the odd-shift asymptotic skeleton applies.

Thus every fully shadowed child is either:

1. `5`-smooth, so `K=5^u`; or
2. a divisor-child `K=ap` with `a|gcd(j,5)`, hence `a=1` or `5`.

The second case is exactly prime or `5p`.

For the smooth case, `K>5` forces `25|K`. If `25<m`, then `25` is an odd divisor of `K` below `m`. But

\[
\gcd(j,K)=\gcd(j,5)
\]

shows `25∤j`, and an odd integer cannot be of the form `4e`. Therefore `25∉S_j`, contradicting full shadowing.

Hence a smooth full shadow would require

\[
m\le25.
\]

With `j>=6`, only `j=6` remains. Then

\[
K=121,
\qquad
m=23,
\]

and divisor `11` satisfies `1<11<m` and `11∤j`, so `11∉S_j`.

Therefore no smooth exception occurs.

## Exact small cases j = 1,...,5

```text
j=1: K=16,  m=3;  divisor 2 escapes S_1.
j=2: K=37;         prime, shadowed.
j=3: K=58,  m=11; divisor 2 escapes S_3.
j=4: K=79;         prime, shadowed.
j=5: K=100, m=19; divisor 2 escapes S_5.
```

This completes the exact classification. QED.

## Correction note

An earlier promoted draft inherited the sentence

> `N=21d-1` is always odd.

That sentence is false when `d` is odd. The theorem itself is unaffected because the canonical proof above does not use that parity assertion.

The repository preserves the earlier version in Git history for provenance.
