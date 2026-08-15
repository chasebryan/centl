# Shifted-factor descent for the post-DSC Erdős–Straus wall

**Status:** working theorem checkpoint; exact reductions proved below, universal existence step open  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Depends on:** `FAB-COPRIME-DIVISOR-CRITERION.md`, `FAB-HARD-NONRESIDUE-BRIDGE.md`, `FAB-HARD-FIRST-FILTERS.md`  
**Claim boundary:** this document does **not** prove Erdős–Straus or López-all-primes. It records exact algebraic reductions that survive the post-DSC pivot and isolates a narrower divisor-placement theorem.

---

## 1. Starting criterion

For a prime

\[
p\equiv1\pmod4,
\]

and coprime positive integers `a,b<p`, the current `fab` reduction says that a positive divisor `k|a+bp` gives a certificate exactly when

\[
\boxed{k\equiv-p\pmod{4ab}.}
\]

Write

\[
q=\frac{a+bp}{k},
\qquad
p+k=4abc.
\]

Then the Egyptian-fraction identity is

\[
\frac4p
=
\frac1{abc}
+
\frac1{aqc}
+
\frac1{bpqc}.
\]

The post-DSC goal is existence of at least one such certificate for every hard prime, not exact-depth realizability.

---

## 2. The b=1 four-cycle

Set `b=1`. Then

\[
kq=a+p,
\qquad
p+k=4ac.
\]

From

\[
kq=a+p=a+4ac-k
\]

we obtain

\[
k(q+1)=a(1+4c).
\]

The coprime criterion gives `gcd(a,k)=1`, hence

\[
\boxed{k\mid1+4c.}
\]

Write

\[
\boxed{1+4c=kd.}
\]

Since `k≡3 mod4`, necessarily

\[
\boxed{d\equiv3\pmod4.}
\]

Then

\[
\boxed{q+1=ad.}
\]

Thus every `b=1` certificate sits in the exact four-link cycle

\[
\boxed{
 p+k=4ac,
\quad
4c+1=kd,
\quad
p+a=kq,
\quad
q+1=ad.
}
\]

Eliminating `c,q` gives the single bilinear surface

\[
\boxed{p=akd-a-k.}
\]

Conversely, if positive integers `a,k,d` satisfy

\[
k\equiv d\equiv3\pmod4,
\qquad
p=akd-a-k>0,
\]

then

\[
k\mid p+a,
\qquad
4a\mid p+k,
\]

so `k` is a valid `b=1` divisor certificate.

Therefore:

### Theorem — b=1 surface

For prime `p≡1 mod4`, the `b=1` lane is equivalent to finding

\[
\boxed{
a,k,d>0,\quad k\equiv d\equiv3\pmod4,\quad p=akd-a-k.
}
\]

This is an exact equivalence, not a heuristic.

---

## 3. Shifted-factor identity

Multiplying the surface relation by `d` gives

\[
dp+1
=akd^2-ad-kd+1
=(ad-1)(kd-1).
\]

Hence every `b=1` certificate satisfies

\[
\boxed{dp+1=(ad-1)(kd-1),\qquad d\equiv3\pmod4.}
\]

This packages the remaining existence problem as a self-referential shifted-factor problem.

The already-proved `d=3` filter is the first special case. Failure at `d=3` forces

\[
\frac{3p+1}{4}
\]

to have only prime factors `1 mod3`.

The mirror `k=3` filter similarly forces

\[
\frac{p+3}{4}
\]

to have only prime factors `1 mod3` on a hypothetical counterexample.

Thus a hard counterexample must make the two neighbours

\[
A=\frac{p+3}{4},
\qquad
B=\frac{3p+1}{4}=3A-2
\]

simultaneously Eisenstein-split.

---

## 4. Fixed-k divisor-square reduction

Return to general coprime `a,b` and fix a prospective divisor `k≡3 mod4`. Put

\[
C=\frac{p+k}{4}.
\]

A certificate with this `k` has

\[
C=abc.
\]

Using

\[
p=4abc-k,
\]

we get

\[
a+bp
=a+4ab^2c-bk
=a(1+4b^2c)-bk.
\]

Because `gcd(a,k)=1`, the condition `k|a+bp` is equivalent to

\[
\boxed{4b^2c\equiv-1\pmod k.}
\]

Define

\[
u=b^2c.
\]

Then `u|C^2`.

The converse divisor realization is exact:

### Lemma — every divisor of C^2 is a b^2 c realization

For every positive divisor

\[
u\mid C^2,
\]

there exist positive integers `a,b,c` such that

\[
abc=C,
\qquad
\gcd(a,b)=1,
\qquad
b^2c=u.
\]

### Proof

Work prime by prime. If

\[
v_r(C)=E,
\qquad
v_r(u)=U,
\qquad
0\le U\le2E,
\]

then choose exponent triples `(alpha,beta,gamma)` for `(a,b,c)` as follows.

If `U<=E`, take

\[
(\alpha,\beta,\gamma)=(E-U,0,U).
\]

If `U>=E`, take

\[
(\alpha,\beta,\gamma)=(0,U-E,2E-U).
\]

In both cases

\[
\alpha+\beta+\gamma=E,
\qquad
2\beta+\gamma=U,
\]

and never both `alpha,beta` are positive, so `gcd(a,b)=1`. Combining the local choices proves the lemma. QED.

Therefore, whenever `k<3p` (so `C<p` and the reconstructed `a,b` automatically satisfy `a,b<p`), we have:

### Theorem — fixed-k divisor box

\[
\boxed{
\text{a coprime fab certificate with divisor }k
\iff
\exists u\mid C^2:
4u\equiv-1\pmod k,
\quad C=\frac{p+k}{4}.
}
\]

For larger `k`, the same arithmetic equivalence holds provided the reconstructed `a,b` satisfy the framework's size hypotheses.

This removes the apparent three-parameter search. At fixed `k`, the wall is one divisor-box hit in `Div(C^2)`.

---

## 5. Character alignment for an external nonresidue prime

Let `k` now be an odd prime with

\[
k\equiv3\pmod4
\]

and suppose

\[
\left(\frac{k}{p}\right)=-1.
\]

Because `p≡1 mod4`, quadratic reciprocity gives

\[
\left(\frac{p}{k}\right)=-1.
\]

Hence

\[
\boxed{
\left(\frac{-p}{k}\right)=+1.
}
\]

Also

\[
C=\frac{p+k}{4}
\equiv\frac p4\pmod k,
\]

so

\[
\boxed{
\left(\frac{C}{k}\right)=-1.
}
\]

The target residue

\[
-4^{-1}\pmod k
\]

is also a quadratic nonresidue because `(-1/k)=-1` and `4` is a square.

Thus the fixed-k divisor-box problem has **no quadratic-character obstruction**: both `C` and the target class lie on the same nonresidue side.

What remains is exact divisor placement inside that coset.

This is a useful narrowing, not an existence proof.

---

## 6. Prescribing the leftover nonresidue c = ell

Let `ell` be an odd prime with

\[
\left(\frac{\ell}{p}\right)=-1.
\]

Suppose `k` is an odd prime satisfying

\[
k\equiv3\pmod4,
\qquad
k\equiv-p\pmod\ell.
\]

Then

\[
\boxed{
\left(\frac{-\ell}{k}\right)=+1.
}
\]

### Proof

Since `p≡1 mod4`, reciprocity gives `(p/ell)=(ell/p)=-1`. From `k≡-p mod ell`,

\[
\left(\frac{k}{\ell}\right)
=
\left(\frac{-p}{\ell}\right).
\]

Applying reciprocity between `k` and `ell` and using `k≡3 mod4` yields `(ell/k)=-1`; multiplying by `(-1/k)=-1` gives `(-ell/k)=+1`. QED.

Therefore the quadratic congruence

\[
\boxed{4\ell b^2\equiv-1\pmod k}
\]

is automatically solvable.

Again, the remaining issue is not character theory. It is choosing a square-root representative `b` compatible with the exact factorization

\[
\frac{p+k}{4}=ab\ell.
\]

This isolates the missing theorem as a divisor-placement problem.

---

## 7. Bezout and norm form when c = ell

Assume a certificate has `c=ell`. From

\[
1+4b^2\ell=kd,
\qquad
q+b=ad,
\]

put

\[
t=q=ad-b.
\]

Then

\[
\boxed{4\ell bt-pd=1.}
\]

Indeed,

\[
p=4ab\ell-k
\]

and multiplication by `d` gives

\[
pd=4ab\ell d-(1+4b^2\ell)
=4b\ell(ad-b)-1.
\]

There is also the exact factorization

\[
\boxed{
(4a\ell b-p)(4a\ell t-p)
=p^2+4a^2\ell.
}
\]

The first factor is exactly

\[
4a\ell b-p=k.
\]

Thus any certificate with prescribed external nonresidue `ell` gives a factorization of the norm-like integer

\[
\boxed{p^2+4a^2\ell.}
\]

This is the cleanest present bridge to the repository's quadratic-field / norm machinery.

---

## 8. Immediate universal target

The current reductions point to one narrow statement.

For a hypothetical Mordell-hard counterexample `p`:

1. the first exact shifted-factor filters force simultaneous splitting restrictions on `(p+1)/2`, `(p+3)/4`, `(3p+1)/4`, `p+2`, and related small shifts;
2. any coprime certificate must import an external quadratic nonresidue prime `ell>=11`;
3. after fixing a prospective divisor `k`, the entire `fab` search becomes
   \[
   \exists u\mid ((p+k)/4)^2:\quad4u\equiv-1\pmod k;
   \]
4. when `k` is a `3 mod4` quadratic nonresidue of `p`, the character obstruction to this congruence vanishes automatically;
5. prescribing the external nonresidue `c=ell` converts the problem into the Bezout/norm equations above.

The next theorem should therefore **not** be another finite `k` census. It should prove a divisor-placement result of one of the following forms:

\[
\boxed{
\text{character alignment}
+\text{hard-prime split restrictions}
\Longrightarrow
\text{target divisor in }\operatorname{Div}(C^2),
}
\]

or, equivalently, a norm-factor selection theorem for

\[
p^2+4a^2\ell.
\]

That is the present shortest route toward the all-prime wall.
