# No finite rotated-factor progression cover can prove the all-prime case

**Status:** proved structural impossibility theorem  
**Date:** 2026-08-15  
**Depends on:** `FAB-RECIPROCAL-DUALITY.md`  
**Claim boundary:** this rules out one proof architecture. It does not rule out a finite set of adaptive divisor tests whose factor data varies with `p`.

## 1. Rotated progression families

Fix positive integers `b,c` and put

\[
M=4bc,
\qquad
N=1+4b^2c=1+Mb.
\]

If

\[
N=kd,
\qquad
k\equiv d\equiv3\pmod4,
\]

then every sufficiently positive integer

\[
\boxed{p=Ma-k}
\]

with integer `a>0` lies in the progression

\[
\boxed{p\equiv-k\pmod M}
\]

and has the exact reciprocal-fab certificate from `FAB-RECIPROCAL-DUALITY.md`.

Thus one fixed factorization of `1+4b^2c` generates one arithmetic-progression solution family.

## 2. A valid rotated family never covers p = 1 mod M

### Lemma

For every valid rotated factorization above,

\[
\boxed{-k\not\equiv1\pmod M.}
\]

### Proof

Suppose instead

\[
k\equiv-1\pmod M.
\]

Since

\[
kd=N\equiv1\pmod M,
\]

the complementary factor also satisfies

\[
d\equiv-1\pmod M.
\]

Write

\[
k=Mt-1,
\qquad
d=Ms-1
\]

with positive integers `s,t`.

Then

\[
1+Mb
=kd
=(Mt-1)(Ms-1)
=M^2st-M(t+s)+1.
\]

Cancelling `1` and dividing by `M` gives

\[
\boxed{b=Mst-t-s.}
\]

For `s,t>=1`,

\[
b\ge M-2.
\]

But `M=4bc` with `c>=1`, so

\[
b\le M/4.
\]

For every `M>=4`,

\[
M-2>M/4,
\]

contradiction. QED.

Therefore every fixed rotated progression misses the entire residue class

\[
\boxed{p\equiv1\pmod M.}
\]

## 3. No finite cover

Take any finite collection of valid rotated progression families with moduli

\[
M_1,\ldots,M_r.
\]

Put

\[
\boxed{Q=\operatorname{lcm}(M_1,\ldots,M_r).}
\]

Every integer

\[
p\equiv1\pmod Q
\]

satisfies

\[
p\equiv1\pmod{M_i}
\]

for every family `i`. By the lemma, none of the rotated families covers such a `p`.

Since each `M_i` is divisible by `4`, so is `Q`. Hence

\[
\gcd(1,Q)=1,
\]

and Dirichlet's theorem gives infinitely many primes

\[
\boxed{p\equiv1\pmod Q.}
\]

Consequently:

### Theorem — no finite rotated progression cover

\[
\boxed{
\text{No finite set of fixed }(b,c,k,d)
\text{ rotated families covers all primes }p\equiv1\pmod4.
}
\]

In particular, no proof of the hard-prime case can consist only of discovering a finite static list of factorizations

\[
1+4b^2c=kd
\]

and taking the union of their arithmetic progressions.

## 4. What this does and does not rule out

This theorem does **not** rule out:

1. an infinite family with a proved descent or covering mechanism;
2. choosing `(b,c)` adaptively from `p`;
3. a finite list of reciprocal-double-sieve parameters `m` whose **divisors vary with p**;
4. a factor-selection theorem on `((p+m)/4)^2` or `((pm+1)/4)^2`;
5. the bounded `(a,b)` phenomenon reported computationally in the 2026 divisor-parametrization paper, because its admissible divisor and remaining factor data vary with the input.

It rules out only the seductive but weaker architecture of a finite static congruence cover by fixed rotated factor pairs.

## 5. Research consequence

The universal step must contain genuinely moving arithmetic information.

The most promising remaining forms are therefore:

\[
\boxed{
\text{adaptive factor selection}
\quad\text{or}\quad
\text{an infinite family with monotone descent}.
}
\]

This aligns with the current reciprocal signed-target program: at fixed `m`, the target group element is simple (`-1` in the reciprocal lane), while the factorization of the moving linear form carries the input-dependent information needed to evade the finite-cover obstruction.
