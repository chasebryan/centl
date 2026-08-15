# Dyachenko ED2 lattice repair audit

**Status:** exact proof audit and corrected lattice lemma  
**Date:** 2026-08-15  
**Primary source:** E. Dyachenko, arXiv:2511.07465v1  
**Claim boundary:** this note does not claim that no repair of the paper is possible. It proves that the stated Lemma 9.24 / Proposition 9.25 route is invalid, gives a correct replacement rectangle bound, and shows that replacing the false `d'` bound by that correct bound does not by itself establish Theorem 9.21.

---

## 1. The lattice in the claimed unconditional step

The paper considers

\[
L=\{(u,v)\in\mathbb Z^2:b'u+c'v\equiv0\pmod g\},
\]

with

\[
\gcd(b',g)=\gcd(c',g)=1,
\]

and defines

\[
\alpha=\gcd(g,b'+c'),
\qquad
\boxed{d'=g/\alpha}.
\]

The map

\[
\phi:\mathbb Z^2\to\mathbb Z/g\mathbb Z,
\qquad
(u,v)\mapsto b'u+c'v
\]

is surjective because `b'` is a unit modulo `g`. Hence

\[
\boxed{[\mathbb Z^2:L]=g.}
\]

So the geometric scale of the full kernel lattice is its index `g`, not the diagonal period `d'` alone.

---

## 2. Lemma 9.24 is false as stated

The paper states that if

\[
w=(d',d')\in L
\]

and `p0=(u0,v0) in L`, then

\[
p_0+\mathbb Zw
=
\{(u,v)\in L:u\equiv u_0,\ v\equiv v_0\pmod{d'}\}.
\]

This equality is false in general.

### Smallest counterexample

Take

\[
g=2,\qquad b'=c'=1.
\]

Then

\[
L=\{(u,v):u+v\equiv0\pmod2\},
\]

and

\[
\alpha=\gcd(2,2)=2,
\qquad d'=1.
\]

Choose `p0=(0,0)`. Since congruence modulo `1` imposes no condition, the right-hand side of the claimed equality is **all of `L`**.

The left-hand side is only

\[
\{(m,m):m\in\mathbb Z\},
\]

a single diagonal line.

For example `(2,0) in L` lies on the right but not the left.

Therefore

\[
\boxed{\text{Lemma 9.24 is false as stated.}}
\]

The correct statement is only the inclusion

\[
p_0+\mathbb Z(d',d')
\subseteq
\{(u,v)\in L:u\equiv u_0,\ v\equiv v_0\pmod{d'}\}.
\]

The reverse inclusion generally contains multiple parallel diagonal cosets.

---

## 3. Proposition 9.25 is false as stated

The proposition claims that every axis-parallel rectangle

\[
R=[x_0,x_0+H)\times[y_0,y_0+W)
\]

with

\[
H,W\ge d'
\]

meets `L`.

The earlier `g=2,b'=c'=1,d'=1` example gives

\[
R=[0,1)\times[1,2).
\]

Its only integer point is `(0,1)`, and

\[
0+1\not\equiv0\pmod2.
\]

Hence

\[
\boxed{L\cap R=\varnothing.}
\]

So Proposition 9.25 is false.

The proof error is exact: it chooses an `x`-coordinate representative and a `y`-coordinate representative independently, then uses **one** diagonal shift parameter and assumes it realizes both choices simultaneously.

---

## 4. There is no replacement bound depending only on d'

The failure is not a missing factor of `2` or another small constant.

For any integer

\[
g\ge2,
\]

take

\[
b'=1,\qquad c'=g-1.
\]

Then both are units modulo `g` and

\[
b'+c'=g,
\]

so

\[
\alpha=g,
\qquad
\boxed{d'=1}.
\]

But

\[
L=\{(u,v):u-v\equiv0\pmod g\}.
\]

Its diagonal period is `(1,1)`, yet the lattice has index `g` and consists of `g` distinct diagonal congruence layers inside `Z^2`.

Unit-size rectangles can plainly be placed on integer points outside `L`, no matter how large `g` is.

Therefore there is no universal theorem of the form

\[
H,W\ge F(d')
\Longrightarrow
L\cap R\ne\varnothing
\]

for a function `F` depending only on `d'`.

The missing geometric information is the transverse spacing / full index `g`.

---

## 5. Correct elementary rectangle-hitting theorem

### Theorem

Let

\[
L=\{(u,v)\in\mathbb Z^2:b'u+c'v\equiv0\pmod g\}
\]

with

\[
\gcd(c',g)=1.
\]

Then every axis-parallel rectangle

\[
R=[x_0,x_0+H)\times[y_0,y_0+W)
\]

with

\[
\boxed{H\ge1,\qquad W\ge g}
\]

meets `L`.

Symmetrically, if `gcd(b',g)=1`, then

\[
\boxed{H\ge g,\qquad W\ge1}
\]

also suffices.

### Proof

Assume `H>=1`. The half-open interval `[x0,x0+H)` contains an integer `u`.

For this fixed `u`, the lattice congruence is

\[
c'v\equiv-b'u\pmod g.
\]

Because `c'` is invertible modulo `g`, there is exactly one residue class

\[
v\equiv r(u)\pmod g.
\]

Every half-open interval of length at least `g` contains a representative of every residue class modulo `g`. Since `W>=g`, choose such a `v` in `[y0,y0+W)`.

Then `(u,v) in L cap R`. QED.

This is crude but universal and exact.

---

## 6. Why the corrected bound does not repair Theorem 9.21

There are two independent issues.

### A. The paper verifies only the weaker d'-scale condition

The Type-I discussion and Corollary 9.26 explicitly use

\[
H,W\ge d'=g/\alpha.
\]

The corrected elementary theorem needs the full `g` scale in one coordinate.

When `alpha>1`, these are genuinely different requirements. The family in section 4 has

\[
d'=1
\]

with arbitrarily large `g`.

Thus the stated box-size argument does not imply the corrected hitting condition.

In the special setup of Section 9.6 the paper says to **fix** `alpha,d'`, so `g=alpha d'` is fixed and a polylogarithmic coordinate range eventually exceeds `g` for sufficiently large `P`. That observation can repair only the *linear lattice hit* for such a fixed parameter family and sufficiently large `P`. It does not prove that one fixed `(alpha,d')` family produces the required nonlinear ED2 point for every prime `P`.

### B. A linear lattice hit is not the nonlinear ED2 existence theorem

The paper itself states after Proposition 9.25 that the lattice step provides a point satisfying the **linear constraints**.

To obtain an ED2 solution it invokes the normalized coordinates and the inverse test. In Appendix D, Lemma D.16 gives the necessary-and-sufficient conditions

\[
m\mid u,
\qquad
u\equiv v\pmod2,
\qquad
\boxed{u^2-v^2=4M},
\]

or equivalently requires the discriminant

\[
\boxed{u^2-4M}
\]

to be a perfect square.

That lemma is a verifier/equivalence theorem. It does **not** assert that an arbitrary lattice point furnished by a rectangle hit satisfies the square equation.

Therefore even a corrected proof that the rectangle contains a point of `L` would establish only a linear-congruence point. An additional existence theorem is still required to force the nonlinear discriminant/perfect-square condition.

---

## 7. Appendix status agrees with this boundary

The paper's own appendix summary distinguishes:

- the unconditional algebraic core;
- unconditional direct/back algorithms and their correctness;
- a **conditional finite covering scheme**;
- computational/counting criteria for windows.

This is consistent with the repair audit: the algorithms can correctly verify or construct a solution when the required arithmetic point exists, while universal existence still needs an independent covering/existence argument.

---

## 8. Conclusion for the CENTL/FCF proof hunt

The attempted shortcut

\[
\text{replace false Proposition 9.25 by a correct lattice-radius lemma}
\]

does **not** close Erdős-Straus.

What survives is useful but narrower:

1. the ED2 algebraic identities and direct/back tests are legitimate theorem-mining tools;
2. the kernel lattice has exact index `g` and a simple correct `g`-scale hitting theorem;
3. the diagonal period `d'=g/alpha` cannot control arbitrary rectangle hitting by itself;
4. after any corrected linear hit, the perfect-square/discriminant existence problem remains.

Accordingly, the highest-value CENTL route remains the internally derived exact divisor-placement / external-nonresidue program rather than attempting to resurrect Theorem 9.21 from its present lattice argument.
