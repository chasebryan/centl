# Proper Jacobi ancestor theorem for higher Type A/B signature codimension

**Status:** proved universal structural theorem  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this theorem concerns the quadratic-signature envelope of Type A/B traps. It does not prove exact Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture. Literature priority for this formulation remains under review.

Read with:

- [QUADRATIC-SIGNATURE-COSET.md](QUADRATIC-SIGNATURE-COSET.md)
- [QUADRATIC-TRAP-SIGNATURE.md](QUADRATIC-TRAP-SIGNATURE.md)
- [CHARACTER-SHIELD-COMPLETENESS.md](CHARACTER-SHIELD-COMPLETENESS.md)
- [MULTIPLICATIVE-TRAP-COSET.md](MULTIPLICATIVE-TRAP-COSET.md)

## 1. Setup

Fix a layer `k` and write

\[
m=4k-1=\prod_{i=1}^r p_i^{a_i}.
\]

Let

\[
\lambda_m:(\mathbb Z/m\mathbb Z)^\times\to\mathbb F_2^r
\]

be the vector of local Legendre signs, let

\[
\eta=\lambda_m(-1),
\]

and let

\[
V_k=\operatorname{span}\{\lambda_m(\ell):\ell\mid k,\ \ell\text{ prime}\}.
\]

The exact quadratic-signature trap theorem gives

\[
\lambda_m(T_k)=\eta+V_k.
\]

Define

\[
\kappa(k)=r-\dim V_k=\dim V_k^\perp.
\]

Let

\[
\alpha=(a_i\bmod2)_{i=1}^r.
\]

This is the exponent-parity vector defining the Jacobi character modulo `m`.

## 2. The Jacobi vector lies in the annihilator

For every prime divisor `ell|k`, the divisor-Jacobi theorem gives

\[
\left(\frac{\ell}{m}\right)=+1.
\]

Therefore

\[
\alpha\cdot\lambda_m(\ell)=0
\pmod2
\]

for every generator of `V_k`, hence

\[
\boxed{\alpha\in V_k^\perp.}
\]

Since `m=3 mod 4`,

\[
\left(\frac{-1}{m}\right)=-1,
\]

so

\[
\boxed{\alpha\cdot\eta=1.}
\]

Thus the usual Jacobi character is one nonzero affine annihilator of the trap-signature space.

## 3. Proper Jacobi ancestor theorem

### Theorem

If

\[
\boxed{\kappa(k)\ge2,}
\]

then there exists a squarefree divisor

\[
\boxed{d\mid\operatorname{rad}(m)}
\]

such that

\[
\boxed{1<d<m,\qquad d\equiv3\pmod4,}
\]

and every Type A/B trap at layer `k` is Jacobi-negative modulo `d`:

\[
\boxed{
\left(\frac{t}{d}\right)=-1
\qquad(t\in T_k).
}
\]

Consequently

\[
\boxed{d=4s-1}
\]

for an earlier depth

\[
\boxed{s=(d+1)/4<k.}
\]

We call `s` a **proper Jacobi ancestor** of the higher-codimension signature layer `k`.

### Proof

Because `kappa(k)>=2`, the annihilator `V_k^perp` has dimension at least two. Choose

\[
u\in V_k^\perp
\]

independent of `alpha`.

If

\[
u\cdot\eta=1,
\]

set `w=u`. Otherwise set

\[
w=u+\alpha.
\]

Then in either case

\[
\boxed{w\in V_k^\perp,\qquad w\cdot\eta=1.}
\]

Also `w` is nonzero and

\[
\boxed{w\ne\alpha.}
\]

Define the squarefree divisor

\[
d=\prod_{i:w_i=1}p_i.
\]

Because `w dot eta = 1`, an odd number of the selected primes are `3 mod 4`, so

\[
\boxed{d\equiv3\pmod4.}
\]

Clearly

\[
d\mid\operatorname{rad}(m).
\]

We claim `d<m`. Since `d<=rad(m)<=m`, equality could occur only if `m` were squarefree and `w` selected every prime factor of `m`. But for squarefree `m`, the all-prime vector is exactly `alpha`, contradicting `w!=alpha`. Hence

\[
\boxed{d<m.}
\]

Now let `t in T_k`. Its local signature has the form

\[
\lambda_m(t)=\eta+v,
\qquad v\in V_k.
\]

Since `w in V_k^perp`,

\[
w\cdot\lambda_m(t)
=w\cdot\eta+w\cdot v
=1.
\]

But `d` is squarefree and supported exactly on the coordinates selected by `w`, so

\[
\left(\frac{t}{d}\right)
=(-1)^{w\cdot\lambda_m(t)}
=-1.
\]

Finally `d=3 mod 4` gives

\[
d=4s-1
\]

for an integer `s`, and `d<m=4k-1` gives `s<k`. QED.

## 4. Meaning

Every signature layer with more than one independent quadratic restriction is already contained in the Jacobi-negative half-space of a **strictly earlier** modulus of the same `4s-1` form.

Thus higher quadratic codimension is not primitive.

At quadratic-signature resolution, the only layers that can be primitive are

\[
\boxed{\kappa(k)=1.}
\]

For those layers the unique nonzero annihilator is the Jacobi character itself, so their trap-signature envelope is exactly the full Jacobi-negative hyperplane.

This creates a sharp dichotomy:

\[
\boxed{
\begin{array}{ll}
\kappa(k)=1 &: \text{primitive quadratic layer;}\\[1mm]
\kappa(k)\ge2 &: \text{has a strict earlier Jacobi ancestor.}
\end{array}
}
\]

## 5. Relation to signature shadowing

The theorem is a genuine ancestor/shadow statement at the **character-envelope** level:

\[
\boxed{
\lambda_m(T_k)
\subseteq
\left\{x:\left(\frac{x}{d}\right)=-1\right\}
}
\]

for some earlier modulus `d=4s-1`.

It does **not** claim

\[
T_k\subseteq T_s
\]

as exact residue sets. The earlier exact trap `T_s` is generally much smaller than the entire Jacobi-negative half modulo `d`.

So this theorem explains redundancy in the quadratic envelope without overclaiming exact Direct-Shadow Completeness.

## 6. Why this is important for the proof program

The full local signature problem seemed to introduce increasingly complicated affine restrictions as the number of prime factors of `4k-1` grew.

The theorem reverses that intuition:

> every genuinely higher-dimensional quadratic trap envelope descends to a simpler, strictly earlier scalar Jacobi obstruction.

Therefore the primitive quadratic skeleton is made only of `kappa=1` layers.

The remaining proof problem is to understand how target-fixed signs interact with this strict descent. In particular:

1. if the proper Jacobi ancestor is target-positive, the higher layer is automatically defeated;
2. if the ancestor is target-negative but still has higher signature codimension, descent can continue;
3. a descent chain can terminate at a primitive `kappa=1` layer;
4. if that terminal layer is fully fixed and negative, it is a direct signature obstruction;
5. otherwise its Jacobi sign supplies a free linear safety equation.

This is precisely the shape suggested by the zero-collective-obstruction finite replay through `k<=1200`.

## 7. Next theorem target

The immediate target is now stronger and more concrete:

> Prove that proper-Jacobi-ancestor descent, together with character-shield saturation, implies **quadratic-signature Direct-Shadow Completeness**: if no single earlier layer is a direct signature obstruction, then all earlier quadratic-signature trap envelopes can be avoided simultaneously.

If proved, the entire elementary quadratic quotient would disappear from the unresolved exact DSC-P problem.

What would remain would be the genuinely higher-order arithmetic already isolated in [SQUARE-LIFT-CORE.md](SQUARE-LIFT-CORE.md): prime-power lifts and exact divisor-generated residues inside a fixed signature class.
