# q=3 Pullbacks Are Singleton

**Status:** proved universal theorem  
**Date:** 2026-08-15  
**Depends on:** Type A/B trap definition  
**Claim boundary:** proves a single `q=3` row forbids at most one parameter class in the full parameter ring. It does not prove that three distinct rows cannot cover all three classes, universal DSC-P, López-all-primes, or Erdős-Straus.

---

## Theorem

Let

\[
m=4j-1,
\qquad
g=\gcd(L,m),
\qquad
q=m/g=3.
\]

For

\[
T_j=\{-e,-4e\pmod m:e\mid j\},
\]

define the pullback

\[
R_j=\{s\bmod3:r+Ls\bmod m\in T_j\}.
\]

Then

\[
\boxed{|R_j|\le1.}
\]

Equivalently, no two distinct points in the attained three-point fibre differ by a nonzero element of that fibre and both lie in `T_j`.

---

## Step 1 — what two hits would imply

Since `q=3`,

\[
m=3g.
\]

The map `s -> r+Ls mod m` is injective on `Z/3Z`; its three attained values form one coset modulo `g`. Any two distinct attained values differ modulo `m` by

\[
\boxed{g\quad\text{or}\quad2g=-g\pmod m.}
\]

Thus two pullback classes would produce two distinct trap residues whose difference is congruent to `±g` modulo `m`.

We prove that this cannot occur.

Because `m=4j-1=3g`, for `j>1`

\[
j<g<2j,
\qquad
g\equiv1\pmod4.
\]

The case `j=1` has only one distinct trap and is immediate.

---

## Step 2 — same-box differences

Take divisors `e,f|j`.

### A/A

A difference of two `-e` traps has representative

\[
e-f.
\]

But

\[
|e-f|<j<g,
\]

so it cannot represent `±g mod 3g`.

### B/B

A difference of two `-4e` traps has representative

\[
4(e-f).
\]

A residue congruent to `±g mod 3g` can be represented in the range of such a difference only by one of `±g,±2g`.

But

\[
g\equiv1\pmod4,
\qquad
2g\equiv2\pmod4,
\]

whereas `4(e-f)` is divisible by `4`. Hence none of those values is possible.

---

## Step 3 — mixed differences

It remains to consider

\[
D=4e-f
\]

(the other mixed orientation is its negative after swapping the two traps).

Since `e,f<=j`,

\[
4-j\le D\le4j-1=3g.
\]

Therefore `D≡±g (mod 3g)` can only occur through

\[
D\in\{g,-g,2g,-2g\}.
\]

### The ±2g cases are impossible by size

If `e=j`, then

\[
D=4j-f.
\]

The equation `D=2g` would require

\[
f=4j-2g=g+1>j,
\]

impossible. If `e<j`, then `e<=j/2`, so

\[
D<2j<2g.
\]

Thus `D=2g` is impossible.

Also

\[
D\ge4-j>-2g
\]

for `j>1`, so `D=-2g` is impossible.

### The +g case

Suppose

\[
4e-f=g=\frac{4j-1}{3}.
\]

Then

\[
12e-3f=4j-1.
\]

Reducing modulo `e` gives

\[
3f\equiv1\pmod e.
\]

Hence

\[
\gcd(e,f)=1.
\]

Since `e|j` and `f|j`, coprimality implies

\[
ef\mid j.
\]

Write

\[
j=efh,
\qquad h\ge1.
\]

Substitution gives

\[
4efh-12e+3f=1,
\]

or

\[
\boxed{e(4fh-12)+3f=1.}
\]

If `fh>=3`, the left side is at least `3`, impossible. If `fh=1`, then `f=h=1` and the equation becomes `-8e+3=1`, impossible. If `fh=2`, the possibilities `(f,h)=(1,2)` or `(2,1)` give respectively `-4e+3=1` or `-4e+6=1`, again impossible.

Therefore `D=g` cannot occur.

### The -g case

Suppose

\[
4e-f=-g.
\]

Then

\[
12e-3f=-4j+1,
\]

so

\[
4j+12e-3f=1.
\]

Reducing modulo `e` again forces `gcd(e,f)=1`, hence `j=efh`. Therefore

\[
4efh+12e-3f=1,
\]

i.e.

\[
\boxed{f(4eh-3)+12e=1.}
\]

But `e,h>=1` gives `4eh-3>=1`, so the left side is at least `f+12e>=13`, contradiction.

Thus `D=-g` is impossible.

All mixed cases are excluded.

---

## Conclusion

No two distinct Type A/B traps differ by the nonzero displacement of a `q=3` fibre. Hence the fibre contains at most one trap:

\[
\boxed{|R_j|\le1.}
\]

QED.

---

## Corrected-domain consequence

For the Mordell-hard program,

\[
3\mid840\mid L,
\]

so the exact Dirichlet parameter domain on a `q=3` coordinate is the full ring

\[
\mathbb Z/3\mathbb Z.
\]

Therefore:

1. one q=3 row forbids at most one of the three classes;
2. two q=3 rows can never cover the exact local domain;
3. any genuine q=3 local obstruction requires at least **three distinct rows**, with singleton pullbacks covering exactly
   \[
   \boxed{\{0,1,2\}.}
   \]
4. after `Q3-ABSORPTION.md`, `Q3-WEAK-REDUNDANCY.md`, and `Q3-POINTWISE-ABSORPTION.md`, a directly novel obstruction would require three pointwise-primitive base contributions carrying three distinct classes.

This is now the precise q=3 theorem target.
