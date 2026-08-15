# C1 pullback cardinality and reduced-parameter count — corrected

**Status:** proved exact pullback lemma; former local C1 gap superseded  
**Date:** 2026-08-15  
**Claim boundary:** the exact cardinality statements below are universal. The unique-active local reduced-escape problem is solved in `SINGLE-ACTIVE-REDUCED-ESCAPE-THEOREM.md`. Full C1, universal DSC-P, López universal coverage, and Erdős-Straus remain open.

Read with:

- [SINGLE-ACTIVE-REDUCED-ESCAPE-THEOREM.md](SINGLE-ACTIVE-REDUCED-ESCAPE-THEOREM.md)
- [SINGLE-ACTIVE-EXCESS-PRIME-POWER.md](SINGLE-ACTIVE-EXCESS-PRIME-POWER.md)
- [C1-PARTIAL-THEOREMS.md](C1-PARTIAL-THEOREMS.md)

## 1. Setup

Let

\[
x=r+Ls
\]

be a target progression with

\[
\gcd(r,L)=1.
\]

For an earlier layer `j`, put

\[
m=4j-1,
\qquad
g=\gcd(L,m),
\qquad
q=m/g.
\]

Let

\[
T_j=\{-e,-4e\pmod m:e\mid j\}.
\]

The compatible trap fiber is

\[
\boxed{
U_{j,r}=\{t\in T_j:t\equiv r\pmod g\}.
}
\]

The exact forbidden parameter set is

\[
\boxed{
R_{j,r}=\{s\pmod q:r+Ls\pmod m\in T_j\}.
}
\]

## 2. Exact pullback cardinality

### Theorem

The affine pullback map

\[
\Psi:U_{j,r}\to\mathbb Z/q\mathbb Z,
\qquad
\Psi(t)
=
\frac{t-r}{g}
\left(\frac Lg\right)^{-1}
\pmod q
\]

is a bijection from `U_{j,r}` onto `R_{j,r}`.

Consequently

\[
\boxed{|R_{j,r}|=|U_{j,r}|\le|T_j|.}
\]

### Proof

For `t∈U_{j,r}`, write

\[
t-r=gc,
\qquad
L=gL',
\qquad
m=gq.
\]

Because `g=gcd(L,m)`,

\[
\gcd(L',q)=1.
\]

The congruence

\[
r+Ls\equiv t\pmod m
\]

is equivalent to

\[
L's\equiv c\pmod q,
\]

which has the unique solution

\[
s\equiv c(L')^{-1}\pmod q.
\]

Thus every compatible trap gives exactly one forbidden parameter class, so `Psi` is surjective onto `R_{j,r}`.

If `Psi(t_1)=Psi(t_2)`, then

\[
(t_1-t_2)/g\equiv0\pmod q,
\]

hence

\[
t_1\equiv t_2\pmod{gq}=\pmod m.
\]

Therefore the two trap residues are identical in `Z/mZ`. So `Psi` is injective. QED.

### Correction to the former draft

The earlier version said distinct compatible traps could collide on the same parameter class. They cannot. The pullback is an exact affine relabeling of the compatible trap fiber.

## 3. Actual reducedness is a condition on x, not on s

The earlier draft called

\[
\gcd(s,q)=1
\]

"reducedness." That is not the relevant arithmetic condition.

What matters for eventual prime realization is that

\[
x=r+Ls
\]

be coprime to the modulus used for the final arithmetic progression.

For the prime divisors of `q`, define

\[
P_{\rm free}=\{p:p\mid q,\ p\nmid L\}.
\]

If `p|q` and `p|L`, then

\[
x\equiv r\pmod p,
\]

and `gcd(r,L)=1` makes `x` automatically nonzero modulo `p` for every parameter `s`.

If `p|q` and `p∤L`, then `L` is invertible modulo `p` and

\[
r+Ls\equiv0\pmod p
\]

excludes exactly one parameter residue class modulo `p`.

By CRT, the number of parameter classes modulo `q` that are reduced at every prime dividing `q` is therefore

\[
\boxed{
A(q,L)
=
q\prod_{\substack{p\mid q\\p\nmid L}}
\left(1-\frac1p\right).
}
\]

This is the correct local reduced-parameter count.

It equals `phi(q)` only in the special case that **every** prime divisor of `q` is absent from `L`.

## 4. Correct pigeonhole corollary

### Corollary

If

\[
\boxed{|R_{j,r}|<A(q,L),}
\]

then at least one exact trap-avoiding parameter class is reduced at every prime dividing `q`.

In particular, the sufficient bound

\[
\boxed{|T_j|<A(q,L)}
\]

also forces a reduced local escape.

This is elementary pigeonhole using the correct reduced set.

## 5. Why the unique-active case is now completely solved locally

For

\[
|\mathcal N^{\rm act}_{k,r}|=1,
\]

the unique-active valuation theorem gives

\[
q=p\quad\text{or}\quad p^2.
\]

### Class A

If `p|L`, then

\[
A(q,L)=q.
\]

Direct novelty says

\[
R\ne\mathbb Z/q\mathbb Z,
\]

so

\[
|R|<q=A(q,L).
\]

A reduced exact local escape follows immediately.

### Class B

If `p∤L`, then necessarily

\[
q=p^2,
\qquad p\ge11.
\]

The stronger compatible-fiber estimate proved in
[SINGLE-ACTIVE-REDUCED-ESCAPE-THEOREM.md](SINGLE-ACTIVE-REDUCED-ESCAPE-THEOREM.md) gives

\[
|R|\le\frac{p^2+3}{2}.
\]

Here

\[
A(p^2,L)=p^2-p,
\]

and

\[
\frac{p^2+3}{2}<p^2-p.
\]

Therefore a reduced exact local escape also exists in Class B.

Hence the old boundary problem

> can the unique active Type A/B pullback cover every reduced parameter class?

is closed:

\[
\boxed{\text{No, not when }|N^{act}|=1.}
\]

## 6. What remains open in C1

The local active row is no longer the obstruction.

The `k<=1500` census shows that nonfixed exact rows dominate the surviving residual system after fiber peeling. Full C1 therefore asks whether the guaranteed active-row escape can be coordinated with **all surviving nonfixed rows simultaneously**.

That global coordination question remains open.

The former instruction to prove a standalone "two-box pullback never covers all units" lemma is therefore no longer the primary C1 wall. It was also phrased using the wrong notion of reduced parameter.

## 7. General usefulness beyond C1

The exact identity

\[
|R_{j,r}|=|U_{j,r}|
\]

and the reduced-parameter count

\[
A(q,L)
=
q\prod_{p\mid q,\ p\nmid L}(1-1/p)
\]

remain useful for multi-row residual systems.

They separate two independent questions:

1. **trap-fiber size:** how many parameter classes a row forbids;
2. **reducedness geometry:** which prime coordinates actually move with the parameter.

That distinction should be preserved in all later Class-C proofs.
