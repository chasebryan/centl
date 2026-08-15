# Squarefree semiprime layers always contain genuinely new mixed Type-II residues

**Status:** proved exact layer theorem  
**Date:** 2026-08-15  
**Depends on:** `ES-SQUARE-COMPLETION-TRAP-GEOMETRY.md`, `ES-SQUARE-TRAP-SIGNED-BOX-IDENTITY.md`  
**Claim boundary:** proves strict layerwise enlargement beyond López A/B for every squarefree semiprime layer. It does not prove that every prime is captured by one of these new residues.

---

## 1. Setup

Let

\[
\boxed{a=uv}
\]

with distinct primes

\[
\boxed{u<v.}
\]

Put

\[
\boxed{m=4uv-1.}
\]

The complete square-divisor parameter set is

\[
D=u^i v^j,
\qquad
0\le i,j\le2.
\]

The midpoint is `(1,1)`.

The López lower and upper orthants contain every point except

\[
\boxed{(2,0)\quad\text{and}\quad(0,2).}
\]

Thus the only mixed square divisors are

\[
\boxed{D=u^2,\qquad D=v^2.}
\]

---

## 2. Signed-box form

The centered exponent box is

\[
(z_u,z_v)\in\{-1,0,1\}^2.
\]

By

\[
S_a=-\mathcal R_m(a),
\]

the two mixed signed values are

\[
\boxed{x=u\,v^{-1}\pmod m}
\]

and

\[
\boxed{x^{-1}=v\,u^{-1}\pmod m.}
\]

The López boundary signed values are

\[
\boxed{
B=
\{1,u,v,uv,u^{-1},v^{-1},(uv)^{-1}\}
\subseteq(\mathbb Z/m\mathbb Z)^\times.}
\]

Therefore the mixed trap residue `-x` would collide with the López trap exactly if

\[
\boxed{x\in B.}
\]

We prove this is impossible.

---

## 3. The easy boundary collisions

### x = 1

This would give

\[
u\equiv v\pmod m.
\]

But

\[
0<v-u<m,
\]

so it would force `u=v`, contradiction.

### x = u

Cancelling the unit `u` gives

\[
v^{-1}\equiv1\pmod m,
\]

hence

\[
v\equiv1\pmod m.
\]

But

\[
0<v-1<m.
\]

Impossible.

### x = v^{-1}

Multiplying by `v` gives

\[
u\equiv1\pmod m,
\]

again impossible because

\[
0<u-1<m.
\]

### x = u^{-1}

This gives

\[
u^2\equiv v\pmod m.
\]

Both `u^2` and `v` are strictly smaller than `m` because

\[
u^2<uv<m
\]

and

\[
v<m.
\]

Thus the congruence would force

\[
u^2=v,
\]

impossible for distinct primes.

### x = (uv)^{-1}

Multiplying by `uv` gives

\[
u^2\equiv1\pmod m.
\]

But

\[
0<u^2-1<m,
\]

so this is impossible.

---

## 4. The collision x = v

Assume

\[
u v^{-1}\equiv v\pmod m.
\]

Then

\[
\boxed{v^2-u=t(4uv-1)}
\]

for some positive integer `t`.

Because

\[
4uv-1>uv,
\]

we have

\[
t<\frac{v^2}{uv}=\frac vu<v.
\]

Reduce the displayed equation modulo `v`:

\[
-u\equiv-t\pmod v.
\]

Hence

\[
t\equiv u\pmod v.
\]

Since

\[
0<t<v
\]

and

\[
0<u<v,
\]

we obtain

\[
\boxed{t=u.}
\]

Substitution gives

\[
v^2-u=u(4uv-1),
\]

so

\[
v^2=4u^2v.
\]

Cancelling `v` yields

\[
\boxed{v=4u^2,}
\]

which is composite. Contradiction.

Therefore

\[
\boxed{x\ne v.}
\]

---

## 5. The collision x = uv

Assume

\[
u v^{-1}\equiv uv\pmod m.
\]

Cancelling `u` gives

\[
v^{-1}\equiv v\pmod m,
\]

so

\[
\boxed{v^2-1=t(4uv-1)}
\]

for some positive integer `t`.

Again

\[
t<\frac vu<v.
\]

Modulo `v`,

\[
-1\equiv-t\pmod v,
\]

so

\[
t\equiv1\pmod v.
\]

The size bound forces

\[
\boxed{t=1.}
\]

Thus

\[
v^2-1=4uv-1,
\]

and therefore

\[
\boxed{v=4u,}
\]

again impossible for the prime `v`.

Hence

\[
\boxed{x\ne uv.}
\]

---

## 6. Exact strict-enlargement theorem

All seven López boundary possibilities have been excluded. Therefore

\[
\boxed{x=u/v\notin B.}
\]

Since `B` is inversion-stable, its inverse also lies outside:

\[
\boxed{x^{-1}=v/u\notin B.}
\]

Returning to trap residues, both mixed square-divisor parameters represent residues outside the old López layer unless the two mixed residues collide with each other. In all cases the completed residue set is strictly larger than the López set.

Thus:

### Theorem — squarefree semiprime strict completion

For every pair of distinct primes `u<v`,

\[
\boxed{
T_{uv}\subsetneq S_{uv}.}
\]

The strict enlargement is supplied by the mixed square divisors

\[
\boxed{u^2\quad\text{and}\quad v^2,}
\]

whose signed ratios

\[
\boxed{u/v\quad\text{and}\quad v/u}
\]

lie outside both López boundary orthants modulo `4uv-1`.

---

## 7. Dimension-two dichotomy

This yields a clean first classification by support dimension:

### One prime in the layer index

If

\[
\omega(a)=1,
\]

then

\[
\boxed{S_a=T_a.}
\]

There is no mixed geometry.

### Two distinct simple primes

If

\[
a=uv,
\qquad u\ne v\text{ prime},
\]

then

\[
\boxed{T_a\subsetneq S_a.}
\]

The completion necessarily creates a genuine mixed inverse pair outside the López boundary.

Thus the very first multidimensional layer family already exhibits unavoidable new Type-II residue geometry.

---

## 8. Next target

The next problem is no longer whether squarefree semiprime layers add new residues. They always do.

The useful questions are:

1. when are the two mixed residues distinct from each other;
2. when does either mixed residue survive hard-class admissibility;
3. when is a mixed semiprime residue directly shadowed by an earlier completed layer;
4. whether semiprime mixed residues account for a positive proportion of the finite completed-depth improvements over López A/B.

Because the entire new region has only two parameters, this is the lowest-dimensional nontrivial testbed for the unified Kneser-plus-ancestry program.
