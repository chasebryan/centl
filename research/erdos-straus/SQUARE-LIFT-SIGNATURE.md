# Square-lift quadratic-signature shadow theorem

**Status:** proved theorem family plus finite proof-mining signal  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this note does not prove universal Direct-Shadow Completeness, universal López Type A/B coverage, or the Erdős-Straus conjecture. It proves an infinite shadow family at the full local quadratic-signature resolution.

Read with:

- [SQUARE-LIFT-RECIPROCITY.md](SQUARE-LIFT-RECIPROCITY.md)
- [QUADRATIC-SIGNATURE-QUOTIENT.md](QUADRATIC-SIGNATURE-QUOTIENT.md)
- [QUADRATIC-SIGNATURE-SHIELD-K1200.md](QUADRATIC-SIGNATURE-SHIELD-K1200.md)
- [CHARACTER-SHIELD-COMPLETENESS.md](CHARACTER-SHIELD-COMPLETENESS.md)

## 1. Setup

Let

\[
d=4a-1
\]

be squarefree and let `s` be positive odd. Put

\[
4j-1=d s^2.
\]

Thus `a` is the squarefree ancestor depth of `j`.

Let the distinct prime divisors of `d` be

\[
p_1,\ldots,p_r.
\]

For every unit `u mod d`, write

\[
\lambda_d(u)
=
\left(
\left(\frac{u}{p_1}\right),\ldots,
\left(\frac{u}{p_r}\right)
\right)
\in\mathbb F_2^r,
\]

with `+1` encoded by `0` and `-1` by `1`.

Let

\[
V_a
=
\operatorname{span}_{\mathbb F_2}
\{\lambda_d(\ell):\ell\mid a,\ \ell\text{ prime}\}.
\]

Then the ancestor trap-signature theorem gives

\[
\lambda_d(T_a)=\eta_d+V_a,
\]

where

\[
\eta_d=\lambda_d(-1).
\]

## 2. Projected divisor-signature space

Define

\[
\boxed{
W_{j\to a}
=
\operatorname{span}_{\mathbb F_2}
\{\lambda_d(\ell):\ell\mid j,\ \ell\text{ prime}\}.
}
\]

Because signatures are multiplicative, as `e` ranges over the divisors of `j`, the set of signatures `lambda_d(e)` is exactly `W_{j->a}`.

Since `4` is a square modulo every odd prime divisor of `d`, both Type A and Type B projected traps have the same signature shift by `eta_d`.

### Theorem

The complete projected quadratic-signature image of the lifted trap set is

\[
\boxed{
\lambda_d(T_j\bmod d)
=
\eta_d+W_{j\to a}.
}
\]

### Proof

For every divisor `e|j`,

\[
\lambda_d(-e)=\eta_d+\lambda_d(e)
\]

and

\[
\lambda_d(-4e)=\eta_d+\lambda_d(e).
\]

The divisor signatures fill exactly the span `W_{j->a}`. QED.

## 3. Exact signature-shadow criterion

The ancestor trap signatures are

\[
\eta_d+V_a.
\]

The lifted projected trap signatures are

\[
\eta_d+W_{j\to a}.
\]

Therefore:

### Theorem

The square-lift layer `j` is completely shadowed by its ancestor `a` at full local quadratic-signature resolution if and only if

\[
\boxed{
W_{j\to a}\subseteq V_a.
}
\]

Equivalently, it is enough to test the prime generators:

\[
\boxed{
\lambda_d(\ell)\in V_a
\quad\text{for every prime }\ell\mid j.
}
\]

This is an exact finite-dimensional linear-algebra criterion. Unlike exact residue containment, there is no need to enumerate every divisor of `j` once the prime generators are known.

## 4. Reciprocity places every lift inside the Jacobi kernel

[SQUARE-LIFT-RECIPROCITY.md](SQUARE-LIFT-RECIPROCITY.md) proves that for every divisor `e|j`,

\[
\left(\frac e d\right)=+1.
\]

At the vector level this says every element of `W_{j->a}` lies in the kernel of the Jacobi functional

\[
J_d:\mathbb F_2^r\to\mathbb F_2.
\]

Hence

\[
\boxed{
W_{j\to a}\subseteq\ker J_d.
}
\]

The ancestor divisor-signature space also lies in this kernel:

\[
V_a\subseteq\ker J_d.
\]

## 5. Quotient-dimension-one automatic shadow theorem

Let

\[
\kappa(a)=r-\dim V_a
\]

be the quadratic quotient dimension from [QUADRATIC-SIGNATURE-QUOTIENT.md](QUADRATIC-SIGNATURE-QUOTIENT.md).

The Jacobi functional is nonzero and annihilates `V_a`, so `kappa(a)>=1`.

If

\[
\boxed{\kappa(a)=1,}
\]

then `V_a` is a codimension-one subspace contained in the codimension-one Jacobi kernel. Therefore

\[
\boxed{V_a=\ker J_d.}
\]

Combining this with square-lift reciprocity gives:

### Theorem

If the squarefree ancestor `a` has

\[
\boxed{\kappa(a)=1,}
\]

then **every** odd square-lift

\[
4j-1=(4a-1)s^2
\]

satisfies

\[
\boxed{
\lambda_d(T_j\bmod d)
\subseteq
\lambda_d(T_a).
}
\]

Thus every such lifted layer is automatically shadowed by its squarefree ancestor at full local quadratic-signature resolution.

QED.

## 6. Relation to Jacobi saturation

[JACOBI-SATURATION.md](JACOBI-SATURATION.md) classified the much stronger exact-residue condition in which the ancestor trap set fills the entire Jacobi-negative half. That happens only for

\[
a=1,2,4.
\]

The present theorem is broader because it asks only for equality after passing to local Legendre-sign vectors.

Whenever `kappa(a)=1`, the ancestor trap **signature coset** fills the entire Jacobi-negative signature hyperplane even though the exact trap set is usually much smaller.

Thus:

\[
\boxed{
\text{exact Jacobi saturation}
\Longrightarrow
\text{signature saturation},
}
\]

but not conversely.

## 7. Finite signal through k <= 1200

An exact replay of the non-squarefree layers through `j<=1200` gives:

```text
non-squarefree layer moduli:              224
square-lifts whose projected signatures
are NOT contained in the ancestor coset:  17
signature-shadowed square-lifts:          207
```

Every one of the 17 finite exceptions has a squarefree ancestor with

\[
\kappa(a)>1.
\]

Sixteen have `kappa(a)=2`; one has `kappa(a)=3`.

The first exceptions are:

```text
j=115,  m=459,  ancestor a=13,  d=51
j=205,  m=819,  ancestor a=23,  d=91
j=259,  m=1035, ancestor a=29,  d=115
j=319,  m=1275, ancestor a=13,  d=51
j=520,  m=2079, ancestor a=58,  d=231
```

These counts are finite proof-mining data. The automatic-shadow theorem for `kappa(a)=1` is universal.

## 8. Why this matters for QDSC

The full quadratic-signature shield through `k<=1200` found that collective higher-codimension signature constraints repeatedly collapse onto lower-codimension shadows.

The theorem above supplies one infinite arithmetic mechanism for that collapse:

\[
\boxed{
\text{square lift}
+
\kappa(a)=1
\Longrightarrow
\text{ancestor signature shadow}.
}
\]

So higher-order local sign information created by square factors is often not new at all. It is inherited from the squarefree ancestor.

Only square lifts over ancestors with a genuinely higher-dimensional quotient

\[
\kappa(a)>1
\]

can create new quadratic-signature projection information.

This localizes the square-lift part of the QDSC proof problem to the higher-quotient ancestor set.

## 9. Next theorem target

For `kappa(a)>1`, classify the subspace

\[
W_{j\to a}
\]

inside the Jacobi kernel and determine exactly when it escapes `V_a`.

Because both spaces are generated by prime-factor signature vectors, this becomes a reciprocity-matrix problem rather than an exact residue enumeration problem.

That is the next natural bridge from square-lift ancestry to the quadratic-signature direct-shadow theorem.

## 10. Novelty boundary

Local Legendre symbols, quadratic reciprocity, vector spaces over `F_2`, and affine signature cosets are classical. The candidate contribution is the exact square-lift projection theorem and the automatic ancestor-shadow criterion inside the López Type A/B minimal-depth/shadow framework.

Publication priority remains subject to broader literature review and independent scrutiny.
