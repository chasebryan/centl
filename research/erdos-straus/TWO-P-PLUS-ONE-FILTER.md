# Exact `2p+1` factor filter

**Status:** proved elementary sufficient family / necessary counterexample restriction  
**Date:** 2026-08-15  
**Depends on:** `FAB-COPRIME-DIVISOR-CRITERION.md`, `FAB-HARD-FIRST-FILTERS.md`  
**Claim boundary:** this removes an infinite family and adds one exact linear-form restriction on any prime counterexample. It does not prove Erdős--Straus.

---

## 1. The pair `(a,b)=(1,2)`

Let `p` be a Mordell-hard prime, so

\[
p\equiv1\pmod8.
\]

The coprime pair

\[
(a,b)=(1,2)
\]

has linear form

\[
a+bp=1+2p=2p+1
\]

and modulus

\[
4ab=8.
\]

The coprime divisor criterion says that this pair yields an Erdős--Straus certificate if and only if `2p+1` has a positive divisor

\[
k\equiv-p\pmod8.
\]

Because `p≡1\pmod8`,

\[
\boxed{-p\equiv7\pmod8.}
\]

---

## 2. Theorem

If `2p+1` has a divisor

\[
k\equiv7\pmod8,
\]

then `p` satisfies Erdős--Straus.

### Proof

The displayed congruence is exactly the coprime divisor criterion for `(1,2)`. Write

\[
p+k=8t,
\qquad
q=\frac{2p+1}{k}.
\]

The general reconstruction gives the explicit decomposition

\[
\boxed{
\frac4p
=
\frac1{2t}
+
\frac1{qt}
+
\frac1{2pqt}.
}
\]

QED.

In particular any prime factor of `2p+1` that is itself `7\bmod8` solves `p`.

---

## 3. Exact miss restriction

For hard `p`,

\[
2p+1\equiv3\pmod8.
\]

A divisor congruent to `7\bmod8` exists unless every prime factor of `2p+1` lies in the classes

\[
\boxed{1\text{ or }3\pmod8.}
\]

Indeed a prime factor `7\bmod8` is itself a forbidden divisor, while a factor `3\bmod8` times a factor `5\bmod8` produces a divisor `7\bmod8`. If no `7\bmod8` divisor exists, the classes `3` and `5` cannot both occur. The total residue `3\bmod8` then forces the nontrivial class to be `3`.

Thus a hard-prime counterexample must satisfy

\[
\boxed{
q\mid(2p+1),\ q\text{ prime}
\Longrightarrow
q\equiv1\text{ or }3\pmod8.
}
\]

This is the same pair of residue classes forced on `p+2` by the existing `(2,1)` filter, now imposed on the dual linear form `2p+1`.

---

## 4. Forced factor `3`

Hard primes satisfy `p≡1\pmod{24}`, hence

\[
\boxed{3\mid(2p+1).}
\]

The prime `3` is itself `3\bmod8`, so it is allowed by the miss restriction. A miss therefore means that the cofactor

\[
\frac{2p+1}{3^v}
\]

is composed entirely of primes `1\bmod8`, except possibly further primes `3\bmod8` whose total `3\bmod8` valuation keeps every partial product out of the class `7`.

---

## 5. Place in the linear-form sieve

A hypothetical hard-prime counterexample must now simultaneously place all of the following forms in restricted quadratic-residue semigroups:

1. `(p+1)/2` — primes `1\bmod4`;
2. `(p+3)/4` — primes `1\bmod3`;
3. `(3p+1)/4` — primes `1\bmod3`;
4. `p+2` — primes `1` or `3\bmod8`;
5. `4p+1` — primes `1\bmod4`;
6. `p+4` — primes `1\bmod4`;
7. `2p+1` — primes `1` or `3\bmod8`.

These are exact infinite restrictions, not range-limited computations.

---

## 6. Finite regression signal

Among Mordell-hard primes through `500{,}000`, the first four filters leave `202` survivors, `4p+1` and `p+4` then leave `78`, and the present theorem removes `37` of those `78`. The remaining `41` are all solved by some two-target shift

\[
k\in\{7,11,15,19,23,31\}.
\]

That last count is finite evidence only.
