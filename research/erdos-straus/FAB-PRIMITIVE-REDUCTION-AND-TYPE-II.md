# Primitive reduction and the p-entangled size sector

**Status:** proved exact structural theorem  
**Date:** 2026-08-15  
**Depends on:** `FAB-GCD-NORMAL-FORM.md`  
**Claim boundary:** this proves gcd-coprimality is without loss of generality for prime existence after reordering. It does not prove the remaining primitive certificate exists for every prime.

## 1. GCD-normal data

For a general fab certificate write

\[
a=shA,
\qquad b=shB,
\qquad k=s\kappa,
\qquad \gcd(A,B)=1,
\]

with

\[
\kappa Q=A+Bp.
\]

The factor `h` is inessential, and the exact normalized conditions are

\[
4sB\mid Q(p+s\kappa),
\]

\[
4sA\mid pQ(p+s\kappa).
\]

We now assume

\[
\boxed{p\nmid k.}
\]

Hence `p` divides neither `s` nor `kappa`.

## 2. Case p does not divide A

When

\[
p\nmid A,
\]

`FAB-GCD-NORMAL-FORM.md` gives

\[
AB\mid p+s\kappa.
\]

Write

\[
p+s\kappa=ABc.
\]

The remaining condition is

\[
4s\mid Qc.
\]

Since `p` does not divide `s`,

\[
\gcd(s,p+s\kappa)=1.
\]

Thus `s` is coprime to `ABc`, and

\[
s\mid Q.
\]

Write

\[
Q=sQ_0.
\]

Then

\[
A+Bp=kQ_0
\]

and

\[
4\mid Q_0c.
\]

Therefore the primitive pair `(A,B)` with the same `k` satisfies the original fab conditions.

## 3. Case p divides A

Write

\[
\boxed{A=p^eA_0,
\qquad p\nmid A_0.}
\]

Because `gcd(A,B)=1`,

\[
p\nmid B.
\]

Also

\[
A+Bp
=p\left(p^{e-1}A_0+B\right).
\]

Since `p` does not divide `kappa`,

\[
\boxed{\kappa\mid p^{e-1}A_0+B.}
\]

Put

\[
C=\frac{p^{e-1}A_0+B}{\kappa}.
\]

Then

\[
Q=pC.
\]

Both `C` and

\[
R=p+s\kappa
\]

are coprime to `p`.

The second normalized fab condition contains only `p^2` on its right-hand side:

\[
4sp^eA_0\mid p^2CR.
\]

Therefore

\[
\boxed{e\le2.}
\]

For either `e=1` or `e=2`, cancelling the available powers of `p` reduces the two normalized conditions to

\[
4sB\mid CR,
\qquad
4sA_0\mid CR.
\]

Since `gcd(A_0,B)=1`,

\[
\boxed{4sA_0B\mid CR.}
\]

Again `gcd(s,R)=1`, so

\[
\boxed{s\mid C.}
\]

Write

\[
C=sC_0.
\]

Then

\[
A+Bp
=p\kappa C
=p\kappa sC_0
=k(pC_0),
\]

so the same divisor `k` divides the primitive linear form `A+Bp`.

The primitive fab quotient is

\[
Q_0=pC_0.
\]

The condition

\[
4A_0B\mid C_0R
\]

checks the two original fab divisibilities directly for the primitive pair `(A,B)`.

Hence `(A,B,k)` is again fab-admissible.

## 4. Primitive-reduction theorem

Combining the two cases gives:

### Theorem

Let `p` be prime. Every general fab certificate with

\[
\boxed{p\nmid k}
\]

reduces, by dividing `a,b` by their common gcd, to a certificate with

\[
\boxed{\gcd(a,b)=1}
\]

and the **same admissible divisor `k`**.

So common gcd scaling contributes no essential solution power whenever the chosen fab divisor is not itself divisible by the target prime.

## 5. Gcd-coprimality is WLOG for prime existence

Suppose an Erdős–Straus solution exists for a prime `p`.

At least one of its three denominators is not divisible by `p`. Otherwise all three denominators would be `p` times positive integers and multiplying

\[
\frac4p=\frac1x+\frac1y+\frac1z
\]

by `p` would express `4` as a sum of three unit fractions, each at most `1`, which is impossible.

Pass to the corresponding decomposition of `1/p` with all denominators multiplied by `4`, and choose a non-`p` denominator as the first denominator `x` in the completeness construction of the fab parametrization.

Then

\[
k=x-p
\]

is not divisible by `p`.

The primitive-reduction theorem applies.

Therefore:

### Corollary — primitive fab completeness for prime existence

If the Erdős–Straus equation is solvable for a prime `p`, then there exists a fab certificate with

\[
\boxed{\gcd(a,b)=1.}
\]

Thus gcd-coprimality itself is without loss of generality for the prime problem.

## 6. What the current coprime divisor criterion still misses

The repository theorem `FAB-COPRIME-DIVISOR-CRITERION.md` additionally assumes the primitive parameters lie below `p`, which ensures

\[
p\nmid a.
\]

The primitive-reduction theorem does **not** imply that size condition.

For a primitive certificate with `p not| k`, if

\[
p\mid a,
\]
then the p-adic argument above shows

\[
\boxed{v_p(a)\in\{1,2\}.}
\]

Write

\[
a=p^eA_0,
\qquad e\in\{1,2\},
\qquad p\nmid A_0.
\]

Then `k` divides the much smaller factor

\[
\boxed{k\mid p^{e-1}A_0+b.}
\]

If

\[
C_0=\frac{p^{e-1}A_0+b}{k},
\]

the remaining exact condition is

\[
\boxed{4A_0b\mid C_0(p+k).}
\]

For `e=1`, the divisor relation is completely independent of `p`:

\[
\boxed{k\mid A_0+b.}
\]

This is the primitive p-entangled / classical Type-II-shaped sector.

## 7. Revised complete proof target

The prime problem can now be split without any arbitrary gcd restriction:

1. **ordinary primitive sector** `p not| a`, where the coprime divisor criterion and reciprocal signed-target machinery apply;
2. **p-entangled primitive sector** `a=p^eA_0`, `e=1 or2`, governed by the reduced criterion above.

A universal proof may close either sector pointwise. It does **not** need a genuinely non-coprime fab theorem.

This is a sharper boundary than the earlier draft of this file, which incorrectly treated the `p|A` branch as essentially non-coprime after normalization.
