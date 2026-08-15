# Primitive reduction and the p-entangled Type-II sector

**Status:** proved exact structural theorem  
**Date:** 2026-08-15  
**Depends on:** `FAB-GCD-NORMAL-FORM.md`  
**Claim boundary:** this classifies where genuinely new non-coprime fab behavior can occur. It does not prove that either sector exists for every prime.

## 1. GCD-normal data

Use the normalization

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

Assume first

\[
\boxed{p\nmid A.}
\]

Then `FAB-GCD-NORMAL-FORM.md` gives

\[
AB\mid p+s\kappa.
\]

Write

\[
\boxed{p+s\kappa=ABc.}
\]

The remaining admissibility condition is exactly

\[
\boxed{4s\mid Qc.}
\]

## 2. Primitive reduction when p does not divide k

Assume in addition

\[
\boxed{p\nmid k.}
\]

Then `p` does not divide `s`.

Since

\[
p+s\kappa\equiv p\pmod s,
\]

we have

\[
\gcd(s,p+s\kappa)=1.
\]

But

\[
p+s\kappa=ABc,
\]

so

\[
\boxed{\gcd(s,ABc)=1.}
\]

In particular

\[
\gcd(s,c)=1.
\]

The condition

\[
4s\mid Qc
\]

therefore forces

\[
\boxed{s\mid Q.}
\]

Write

\[
Q=sQ_0.
\]

Then

\[
A+Bp
=\kappa Q
=s\kappa Q_0
=kQ_0,
\]

so

\[
\boxed{k\mid A+Bp.}
\]

Also

\[
4s\mid sQ_0c
\]

gives

\[
\boxed{4\mid Q_0c.}
\]

Now test the original fab conditions directly on the **primitive coprime pair** `(A,B)` with the same divisor `k` and quotient `Q_0`.

Because

\[
p+k=ABc,
\]

we have

\[
Q_0(p+k)=Q_0ABc.
\]

The factor `4|Q_0c` gives

\[
4B\mid Q_0(p+k)
\]

and

\[
4A\mid pQ_0(p+k).
\]

Therefore `(A,B,k)` is itself fab-admissible.

### Theorem — primitive reduction

Every general fab certificate satisfying

\[
\boxed{p\nmid A,
\qquad p\nmid k}
\]

reduces to a coprime fab certificate on the primitive pair

\[
\boxed{\gcd(A,B)=1}
\]

with the **same admissible divisor `k`**.

Thus non-coprime scaling creates no new solution in this sector.

## 3. Where genuinely new non-coprime behavior can live

The contrapositive is immediate:

### Corollary

A general fab certificate that cannot be reduced to a coprime certificate by primitive gcd removal must satisfy at least one of

\[
\boxed{p\mid A}
\]

or

\[
\boxed{p\mid k.}
\]

So the entire genuinely non-coprime remainder is **p-entangled**.

This is far narrower than arbitrary `gcd(a,b)>1`.

## 4. The sector p | A and p does not divide k

Assume

\[
\boxed{A=pA_0,
\qquad p\nmid k.}
\]

Since `gcd(A,B)=1`,

\[
p\nmid B.
\]

Also `p` does not divide `s` or `kappa`.

The primitive linear form is

\[
A+Bp
=p(A_0+B).
\]

Because

\[
\kappa\mid p(A_0+B)
\]

and `p` is coprime to `kappa`,

\[
\boxed{\kappa\mid A_0+B.}
\]

Put

\[
\boxed{C=\frac{A_0+B}{\kappa}.}
\]

Then

\[
Q=pC,
\qquad
q=hpC.
\]

The normalized divisibility conditions become

\[
4sB\mid pC(p+s\kappa),
\]

and

\[
4spA_0\mid p^2C(p+s\kappa).
\]

Since `p` is coprime to `4sA_0B`, these reduce exactly to

\[
4sB\mid C(p+s\kappa)
\]

and

\[
4sA_0\mid C(p+s\kappa).
\]

Because `gcd(A_0,B)=1`, their least common multiple is

\[
4sA_0B.
\]

Hence:

### Theorem — p-entangled reduced criterion

When `A=pA_0` and `p` does not divide `k`, general fab admissibility is equivalent to

\[
\boxed{
\begin{aligned}
&s\kappa\equiv3\pmod4,\\
&\kappa\mid A_0+B,\\
&4sA_0B\mid C(p+s\kappa),
\qquad C=(A_0+B)/\kappa.
\end{aligned}}
\]

The divisor condition has lost the large linear form `A+Bp`: its primitive factorization is now controlled by the **small p-independent integer `A_0+B`**.

## 5. Type-II denominator pattern

The fab decomposition of `1/p` has denominators

\[
p+k,
\]

\[
\frac{q(p+k)}{b},
\]

and

\[
\frac{pq(p+k)}{a}.
\]

In the present sector,

\[
q=hpC,
\qquad
b=shB,
\qquad
a=shpA_0.
\]

Therefore the second denominator contains a factor `p`, and after cancelling the single `p` in `a`, the third denominator still contains a factor `p` as well.

Meanwhile

\[
p\nmid p+k
\]

because `p` does not divide `k`.

Thus the pattern is exactly

\[
\boxed{
\text{one denominator not divisible by }p,
\qquad
\text{two denominators divisible by }p.
}
\]

This is the classical Type-II divisibility pattern.

So the non-coprime sector not already reduced to coprime fab is not amorphous: its `p|A, p not| k` branch is the p-entangled/Type-II side of the standard dichotomy.

## 6. The sector p | k is not needed as the only representation

Any Erdős–Straus solution for prime `p` has at least one denominator not divisible by `p`; if all three denominators were multiples of `p`, multiplying the equation by `p` would make the sum of three positive unit fractions equal `4`, impossible because each is at most `1`.

When the complete fab construction is applied with such a non-`p` denominator chosen as the first denominator, its

\[
k=x-p
\]

is not divisible by `p`.

Therefore, for an existence proof, one never needs to rely exclusively on fab representations with

\[
p\mid k.
\]

After reordering an actual solution, the relevant genuinely non-coprime alternative to the coprime program is the `p|A, p not|k` Type-II sector above.

## 7. Revised all-prime wall

The complete prime problem can therefore be attacked as a two-sector existence problem:

1. **primitive/coprime sector:** find a coprime fab certificate, where the reciprocal signed-target and nonresidue machinery applies;
2. **p-entangled Type-II sector:** find parameters satisfying the reduced p-entangled criterion.

A proof need not establish universal coprime coverage if every coprime survivor can instead be forced into the Type-II sector.

That is a strictly weaker and potentially more realistic target than the current all-coprime conjectural wall.
