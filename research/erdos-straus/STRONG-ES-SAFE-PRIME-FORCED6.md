# Safe-prime shifts q = 23 mod 24 carry a forced nine-class Type-II obstruction

**Status:** proved uniform finite-group theorem  
**Date:** 2026-08-15  
**Depends on:** `STRONG-ES-PRIME-SHIFT-KNESER-DICHOTOMY.md`, `STRONG-ES-Q23-EXACT-FILTER.md`  
**Claim boundary:** applies to any safe prime `q=2ell+1` in the residue class `23 mod24`. Infinitude of such safe primes is not known and is not assumed. The theorem gives a uniform local obstruction for every one that exists.

---

## 1. Safe-prime setup

Let

\[
\boxed{q=2\ell+1}
\]

with both `q` and `ell` prime, and assume

\[
\boxed{q\equiv23\pmod{24}.}
\]

Let `p` be Mordell-hard and put

\[
\boxed{C=\frac{p+q}{4}.}
\]

Hard primes satisfy

\[
p\equiv1\pmod{24}.
\]

Hence

\[
p+q\equiv24\equiv0\pmod{24}
\]

and therefore

\[
\boxed{6\mid C.}
\]

So `2` and `3` are forced prime factors of the shifted integer.

---

## 2. Both forced factors generate the QR subgroup

The quadratic-residue subgroup

\[
Q=(\mathbb Z/q\mathbb Z)^{\times 2}
\]

has prime order

\[
\boxed{|Q|=\ell.}
\]

Because

\[
q\equiv7\pmod8,
\]

quadratic reciprocity gives

\[
\left(\frac2q\right)=+1.
\]

Because

\[
q\equiv-1\pmod{12},
\]

one has

\[
\left(\frac3q\right)=+1.
\]

Neither `2` nor `3` is `1 mod q`.

Since `Q` has prime order, every nonidentity element generates it. Therefore

\[
\boxed{
\operatorname{ord}_q(2)
=
\operatorname{ord}_q(3)
=\ell.}
\]

Use `2` as a generator of `Q` and write

\[
\boxed{3\equiv2^c\pmod q}
\]

for a unique nonzero

\[
c\in\mathbb Z/\ell\mathbb Z.
\]

---

## 3. The forced two-factor QR box

Using only one copy of each forced factor, their signed exponent choices give the subset

\[
\boxed{
F_q
=
\{x+cy\pmod\ell:
 x,y\in\{-1,0,1\}\}.}
\]

There are at most nine elements.

We prove there are exactly nine.

---

## 4. Any collision forces one of six tiny ratios

Suppose

\[
x_1+cy_1
\equiv
x_2+cy_2
\pmod\ell
\]

for two distinct pairs in `{-1,0,1}^2`.

Then

\[
\Delta x+c\Delta y\equiv0
\]

with

\[
\Delta x,\Delta y\in\{-2,-1,0,1,2\}.
\]

If `Delta y=0`, then `Delta x=0` because `ell>=11`, contradicting distinctness.

Therefore

\[
\boxed{
c=-\Delta x/\Delta y.}
\]

The only nonzero ratios obtainable from the difference set are

\[
\boxed{
\pm1,
\quad
\pm2,
\quad
\pm\frac12.}
\]

Thus a collision forces `c` into this six-element set.

---

## 5. Every exceptional ratio would force a small excluded prime q

Recall

\[
3\equiv2^c\pmod q.
\]

### c = 1

Would give

\[
3\equiv2\pmod q,
\]

impossible.

### c = -1

Would give

\[
3\equiv2^{-1},
\]

so

\[
6\equiv1\pmod q,
\]

forcing `q=5`.

### c = 2

Would give

\[
3\equiv4\pmod q,
\]

impossible.

### c = -2

Would give

\[
3\equiv4^{-1},
\]

so

\[
12\equiv1\pmod q,
\]

forcing `q=11`.

### c = 1/2

Squaring gives

\[
9\equiv2\pmod q,
\]

forcing `q=7`.

### c = -1/2

Squaring gives

\[
9\equiv2^{-1}\pmod q,
\]

so

\[
18\equiv1\pmod q,
\]

forcing `q=17`.

None is compatible with

\[
q\equiv23\pmod{24},
\qquad
q\ge23.
\]

Therefore no collision occurs.

### Theorem — forced QR nine-set

\[
\boxed{|F_q|=9.}
\]

---

## 6. Translate the nine QR classes into forbidden NR factors

The Type-II target is

\[
-1.
\]

Every quadratic nonresidue can be written uniquely as

\[
\boxed{x=-h}
\]

with

\[
h\in Q.
\]

If the shifted integer `C` has a prime factor in the NR class `x=-h`, then the signed local set of that factor contains both `x` and `x^{-1}`.

The target `-1` is obtained from `x` exactly when the existing QR box contains

\[
h^{-1},
\]

and from `x^{-1}` exactly when it contains `h`.

The forced set `F_q` is symmetric under inversion in additive coordinates.

Therefore every NR class

\[
\boxed{-h,
\qquad h\in F_q}
\]

forces an immediate Type-II hit using only the forced factors `2,3` and that one NR factor.

Since `|F_q|=9`, there are nine such forbidden NR prime residue classes.

---

## 7. Safe-prime miss dichotomy with a uniform exceptional obstruction

The safe-prime Kneser theorem says every miss is either:

1. pure quadratic splitting; or
2. a full-stabilizer-trivial aperiodic defect.

In the second branch, the nine NR classes above are still impossible as prime factors of `C`.

Thus:

### Theorem — forced-nine-class safe-prime obstruction

For every safe prime

\[
q\equiv23\pmod{24},
\]

a Mordell-hard Type-II miss satisfies one of:

### Branch A

Every prime factor of `(p+q)/4` is a quadratic residue modulo `q`.

### Branch B

The signed box is aperiodic, and at minimum the nine quadratic-nonresidue residue classes

\[
\boxed{-F_q}
\]

are forbidden as prime divisors of `(p+q)/4`.

The branch may have additional restrictions; nine is a uniform guaranteed minimum.

---

## 8. Sieve contribution

Among the

\[
q-1=2\ell
\]

reduced prime residue classes modulo `q`:

- Branch A forbids all `ell` NR classes, density `1/2`;
- Branch B forbids at least `9` classes, density
  \[
  \boxed{9/(q-1).}
  \]

Therefore every miss branch contributes at least

\[
\boxed{
\delta_q
=
\min\left(\frac12,\frac9{q-1}\right)
=
\frac9{q-1}
}
\]

for `q>=23`, before using any additional exact branch structure.

For `q=23`, the dedicated exact theorem is much stronger than this generic bound.

For `q=47`, the generic bound already contributes

\[
\boxed{9/46}
\]

of a sieve dimension.

---

## 9. Important logical boundary

No claim is made that infinitely many safe primes

\[
q\equiv23\pmod{24}
\]

exist.

That is a Sophie-Germain/safe-prime type problem and is open.

The theorem is conditional only in the harmless sense:

> every safe prime in this progression that exists carries the stated nine-class obstruction.

Finite known shifts such as `23` and `47` can be used unconditionally in fixed-shift sieve arguments.
