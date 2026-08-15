# Exact two-target divisor-square criterion

**Status:** proved exact reformulation  
**Date:** 2026-08-15  
**Depends on:** `ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md`, `FAB-UNBOUNDED-DIVISOR-RATIO-CERTIFICATE.md`  
**Claim boundary:** this is an equivalent coordinate form of the exact prime Type-I/Type-II signed-box theorem. It does not prove universal target existence.

---

## 1. From signed exponents to divisors of C^2

Let

\[
p\equiv1\pmod4
\]

be prime and let

\[
k\equiv3\pmod4,
\qquad
\gcd(k,p)=1.
\]

Put

\[
C=\frac{p+k}{4}
=\prod_i r_i^{e_i}.
\]

The signed divisor box is

\[
\mathcal R_k(C)
=
\left\{
\prod_i r_i^{z_i}\pmod k:
-e_i\le z_i\le e_i
\right\}.
\]

For each signed exponent vector define

\[
u_i=e_i-z_i.
\]

Then

\[
0\le u_i\le2e_i
\]

and

\[
d=\prod_i r_i^{u_i}
\]

runs through **every positive divisor of `C^2` exactly once** as the exponent vector varies.

Moreover

\[
\prod_i r_i^{z_i}
=C\,d^{-1}\pmod k.
\]

Therefore

\[
\boxed{
\mathcal R_k(C)
=
\{C d^{-1}\pmod k:d\mid C^2\}.}
\]

This is a bijective reparametrization of the signed box.

---

## 2. Type-I target

By inversion symmetry, the Type-I target may be written as

\[
-p
\]

instead of `-p^{-1}`.

Since

\[
p\equiv4C\pmod k,
\]

the equation

\[
C d^{-1}\equiv-p\pmod k
\]

is equivalent to

\[
C d^{-1}\equiv-4C\pmod k.
\]

Because `C` is a unit modulo `k`, this becomes

\[
d^{-1}\equiv-4\pmod k,
\]

or

\[
\boxed{4d\equiv-1\pmod k.}
\]

Thus:

### Exact Type-I divisor-square criterion

\[
\boxed{
\text{Type I at shift }k
\iff
\exists d\mid C^2:
4d\equiv-1\pmod k.}
\]

This recovers the fixed-`k` divisor-square target from the earlier strong FAB lane, now as the exact standard Type-I coordinate.

---

## 3. Type-II target

The Type-II target is

\[
-1.
\]

Hence

\[
C d^{-1}\equiv-1\pmod k
\]

is equivalent to

\[
\boxed{d\equiv-C\pmod k.}
\]

Therefore:

### Exact Type-II divisor-square criterion

\[
\boxed{
\text{Type II at shift }k
\iff
\exists d\mid C^2:
d\equiv-C\pmod k.}
\]

This is the divisor-square counterpart that was missing from the one-target fixed-`k` formulation.

---

## 4. Exact two-target theorem

Combining the two cases with `ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md` gives:

### Theorem — prime ES as two divisor classes inside Div(C^2)

For prime `p≡1 mod4`, Erdős--Straus holds for `p` if and only if there exists

\[
k\equiv3\pmod4,
\qquad
\gcd(k,p)=1,
\]

such that, with

\[
C=\frac{p+k}{4},
\]

there is a divisor `d|C^2` satisfying at least one of

\[
\boxed{4d\equiv-1\pmod k}
\]

or

\[
\boxed{d\equiv-C\pmod k.}
\]

Equivalently,

\[
\boxed{
\operatorname{Div}(C^2)
\cap
\left(
\{-4^{-1}\}
\cup
\{-C\}
\right)
\ne\varnothing
\pmod k.}
\]

The first class is Type I; the second is Type II.

---

## 5. Complement involution

The divisor set has the natural involution

\[
\boxed{d\longmapsto d^*=\frac{C^2}{d}.}
\]

Under the signed-box map

\[
C/d,
\]

this is exactly inversion:

\[
\frac C{d^*}
=
\left(\frac Cd\right)^{-1}.
\]

### Type I

The two orientations `-p` and `-p^{-1}` correspond to a complementary divisor pair.

If

\[
d\equiv-4^{-1}\pmod k,
\]

then

\[
d^*=C^2d^{-1}
\equiv-4C^2\pmod k,
\]

which is the divisor coordinate of the inverse Type-I orientation.

### Type II

The Type-II residue is self-inverse. If

\[
d\equiv-C\pmod k,
\]

then

\[
d^*
=C^2d^{-1}
\equiv-C\pmod k.
\]

Thus the Type-II target class is fixed by divisor complement.

This self-reciprocity is a useful structural distinction between the two solution types.

---

## 6. Type-II square-pair form

Suppose

\[
d\mid C^2,
\qquad
 d\equiv-C\pmod k.
\]

Put

\[
e=\frac{C^2}{d}.
\]

Then also

\[
e\equiv-C\pmod k.
\]

Since `de=C^2` is a square, `d` and `e` have the same squarefree kernel. Write

\[
\boxed{d=s a^2,\qquad e=s b^2}
\]

with `s` squarefree. Then

\[
\boxed{C=sab.}
\]

Now

\[
d+C
=s a^2+sab
=s a(a+b).
\]

Because every prime factor of `sa` divides `C` and `gcd(C,k)=1`, one has

\[
\gcd(sa,k)=1.
\]

Therefore

\[
k\mid d+C
\iff
\boxed{k\mid a+b.}
\]

So Type II may equivalently be viewed as a complementary divisor-square pair whose square roots add to a multiple of the shift.

This recovers the familiar normalized factor-pair geometry from a different direction.

---

## 7. Strategic consequence

The exact prime problem can be stated without signed exponents:

> Choose an admissible shift `k`. The square divisor lattice of `C=(p+k)/4` must hit one of two residue classes modulo `k`: the fixed Type-I class `-4^{-1}` or the moving Type-II class `-C`.

The two classes have different involution behavior:

- Type I is a complementary pair under `d -> C^2/d`;
- Type II is self-complementary.

This form may be better suited to divisor-distribution, reciprocity, and lattice arguments than the original signed-box notation while remaining exactly equivalent to it.
