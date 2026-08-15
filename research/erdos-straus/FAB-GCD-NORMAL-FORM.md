# GCD-normal form for general fab certificates

**Status:** proved exact normalization theorem  
**Date:** 2026-08-15  
**External framework:** Bello-Hernández, Benito, Fernández, arXiv:2606.10922v1  
**Relation to repo:** extends `FAB-COPRIME-DIVISOR-CRITERION.md` beyond `gcd(a,b)=1`  
**Claim boundary:** this is an exact reformulation of the general fab admissibility conditions. It does not prove universal existence.

## 1. Why this normalization matters

The complete fab definition allows arbitrary positive integers `a,b`; coprimality is not part of the definition.

The current project criterion

\[
k\mid(a+bp),
\qquad
k\equiv-p\pmod{4ab}
\]

is an exact collapse only in the coprime range. A universal proof does not have to solve that stronger subproblem if the non-coprime sector supplies additional certificates.

The common gcd can be normalized exactly.

## 2. Canonical factorization of a,b,k

Let `p` be prime and suppose `a,b,k` are positive with

\[
k\mid a+bp.
\]

Write

\[
\boxed{g=\gcd(a,b),
\qquad a=gA,
\qquad b=gB,
\qquad \gcd(A,B)=1.}
\]

Now separate the part of `k` that lies in the common gcd:

\[
\boxed{s=\gcd(k,g),
\qquad k=s\kappa,
\qquad g=sh.}
\]

Prime by prime, after removing the common minimum valuation, `kappa` and `h` have disjoint support. Hence

\[
\boxed{\gcd(\kappa,h)=1.}
\]

Since

\[
s\kappa\mid sh(A+Bp),
\]

we get

\[
\kappa\mid h(A+Bp).
\]

Coprimality with `h` therefore forces

\[
\boxed{\kappa\mid A+Bp.}
\]

Put

\[
\boxed{Q=\frac{A+Bp}{\kappa}.}
\]

Then the fab quotient is simply

\[
\boxed{q=\frac{a+bp}{k}=hQ.}
\]

## 3. Exact cancellation of the inessential common scale

The general fab admissibility conditions are

\[
k\equiv3\pmod4,
\]

\[
4b\mid q(p+k),
\]

and

\[
4a\mid p q(p+k).
\]

Substitute

\[
a=shA,
\quad b=shB,
\quad k=s\kappa,
\quad q=hQ.
\]

The two divisibility conditions become

\[
4shB\mid hQ(p+s\kappa),
\]

and

\[
4shA\mid p hQ(p+s\kappa).
\]

The factor `h` cancels completely:

\[
\boxed{
4sB\mid Q(p+s\kappa),
}
\]

\[
\boxed{
4sA\mid pQ(p+s\kappa).
}
\]

Thus the residual common scaling `h` contains **no mathematical information** for admissibility.

## 4. General GCD-normal theorem

### Theorem

Let `p` be prime, let `A,B` be coprime positive integers, and let `s,kappa` be positive integers. Put

\[
k=s\kappa.
\]

Assume

\[
\boxed{k\equiv3\pmod4,}
\]

\[
\boxed{\kappa\mid A+Bp,}
\]

and define

\[
Q=\frac{A+Bp}{\kappa}.
\]

Then, for **any** positive integer `h`, the parameters

\[
\boxed{a=shA,
\qquad b=shB}
\]

make `k` fab-admissible if and only if

\[
\boxed{4sB\mid Q(p+s\kappa)}
\]

and

\[
\boxed{4sA\mid pQ(p+s\kappa).}
\]

Conversely, every general fab certificate admits exactly this normalization with

\[
s=\gcd(k,\gcd(a,b)).
\]

Therefore the non-coprime fab sector adds one essential arithmetic parameter `s`; arbitrary further common scaling is redundant.

## 5. Stronger collapse when p does not divide A

Assume additionally

\[
\boxed{p\nmid A.}
\]

Because

\[
\gcd(A,B)=1
\]

and

\[
\kappa Q=A+Bp,
\]

we have

\[
\gcd(A,\kappa Q)=1,
\qquad
\gcd(B,\kappa Q)=1.
\]

The normalized divisibilities therefore force

\[
B\mid p+s\kappa
\]

and

\[
A\mid p+s\kappa.
\]

Hence

\[
\boxed{AB\mid p+s\kappa.}
\]

Put

\[
\boxed{c=\frac{p+s\kappa}{AB}.}
\]

After cancelling `A` and `B`, the remaining two divisibility conditions are

\[
4s\mid QAc,
\qquad
4s\mid pQBc.
\]

Since

\[
\gcd(A,pB)=1,
\]

Bézout gives the exact collapse

\[
\boxed{4s\mid Qc.}
\]

Thus:

### Corollary — reduced GCD-normal criterion

For coprime `A,B` with `p not| A`, a general fab certificate exists from `(A,B,s,kappa)` exactly when

\[
\boxed{
\begin{aligned}
&s\kappa\equiv3\pmod4,\\
&\kappa\mid A+Bp,\\
&AB\mid p+s\kappa,\\
&4s\mid
\frac{A+Bp}{\kappa}
\frac{p+s\kappa}{AB}.
\end{aligned}}
\]

This is a four-condition integer system with no hidden gcd scale.

## 6. Recovery of the coprime criterion

The coprime fab sector is exactly

\[
s=1,
\qquad h=1.
\]

Then

\[
k=\kappa\equiv3\pmod4.
\]

The congruence `p+k=0 mod4` supplies the factor `4`, and the reduced criterion collapses to the already-deposited coprime divisor condition.

So the present theorem genuinely extends the current project language rather than replacing it.

## 7. New proof opportunity

The extra parameter `s` allows the admissible fab divisor

\[
k=s\kappa
\]

to contain a component drawn from the common gcd of `a,b`, rather than requiring the entire `k` to divide the primitive linear form `A+Bp`.

The primitive divisor is only

\[
\kappa\mid A+Bp.
\]

The remaining factor `s` is controlled instead by the coupled divisibility

\[
4s\mid Qc.
\]

This opens a proof route that the coprime divisor-in-one-ray-class formulation cannot see.

The next computational and theoretical question is therefore:

> Do hypothetical survivors of the coprime reciprocal program admit a small or structurally forced `s>1` GCD-normal certificate?

If yes, universal coprime coverage is stronger than necessary and should be abandoned as the endgame target.
