# Five-halves sieve bound from the exact q=3, q=7, and q=11 Type-II filters

**Status:** proved application of a classical upper-bound sieve  
**Date:** 2026-08-15  
**Depends on:** `STRONG-ES-Q3-Q7-SIEVE.md`, `STRONG-ES-Q11-EXACT-FILTER.md`  
**Imported classical tools:** Selberg/Brun upper-bound sieve, prime number theorem in arithmetic progressions, Dirichlet-character prime sums  
**Claim boundary:** classical Erdős--Straus exceptional-set results are stronger when larger parametric families are used. This note records the specific quantitative consequence of the three exact fixed Type-II shifts `3,7,11`; it does not prove universal strong/Type-II coverage.

---

## 1. Consecutive corridor variables

Let

\[
A=\frac{p+3}{4}.
\]

The first three prime shifts in the Type-II corridor are

\[
\boxed{
\begin{array}{c|c}
q & C=(p+q)/4\\
\hline
3 & A\\
7 & A+1\\
11 & A+2.
\end{array}}
\]

For a simultaneous survivor:

1. `A` has only prime factors `1 mod3`;
2. `A+1` has only quadratic-residue prime factors mod `7`;
3. `A+2` lies in one of the two exact `q=11` miss branches.

We sieve each `q=11` branch separately.

---

## 2. Baseline dimension from primality, q=3, and q=7

For every large sieve prime `ell`, the first two-filter argument forbids:

- one residue making `p=4A-3` divisible by `ell`;
- residue `A=0` for the half of primes with `ell=2 mod3`;
- residue `A=-1` for the half with `(ell/7)=-1`.

These residues are distinct away from finitely many small primes.

Therefore the baseline sieve dimension is

\[
\boxed{2.}
\]

and the baseline survivor count is

\[
\ll X/(\log X)^2.
\]

---

## 3. q=11 Branch A adds half a sieve dimension

Branch A requires every prime factor of

\[
A+2
\]

to be a quadratic residue modulo `11`.

Thus for every sieve prime `ell` with

\[
\left(\frac\ell{11}\right)=-1,
\]

the residue

\[
\boxed{A\equiv-2\pmod\ell}
\]

is forbidden.

Quadratic nonresidue primes modulo `11` have relative density

\[
\boxed{1/2.}
\]

among primes away from `11`.

The residue `-2` is distinct from the three baseline forbidden residues for every sufficiently large `ell`; collisions occur only at finitely many primes and do not affect sieve dimension.

Hence Branch A has dimension

\[
\boxed{
2+\frac12=\frac52.}
\]

The upper-bound sieve gives

\[
\boxed{
N_A(X)
\ll
\frac{X}{(\log X)^{5/2}}.}
\]

---

## 4. q=11 Branch B is even thinner

The exact thin Branch B requires:

- `v_3(A+2)=1`;
- every other QR factor is `1 mod11`;
- no prime factors `7,8,10 mod11`;
- the only allowed nonresidue classes are `2,6 mod11`, with total valuation at most two.

For an upper bound we may **discard** the valuation restrictions and enlarge the set.

After ignoring the special fixed prime `3`, every prime divisor of `A+2` is then allowed only in the three classes

\[
\boxed{1,2,6\pmod{11}.}
\]

Therefore primes in the seven reduced classes

\[
\boxed{3,4,5,7,8,9,10\pmod{11}}
\]

are forbidden as divisors of `A+2`.

These classes have prime density

\[
\boxed{7/10.}
\]

by the prime number theorem in arithmetic progressions.

Thus Branch B has sieve dimension at least

\[
\boxed{
2+\frac7{10}=\frac{27}{10}.}
\]

Consequently

\[
\boxed{
N_B(X)
\ll
\frac{X}{(\log X)^{27/10}}.}
\]

The actual exact Branch-B set is smaller because the ignored primitive valuation mass is capped by two.

---

## 5. Combined three-shift theorem

Every simultaneous `q=3,7,11` miss belongs to Branch A or Branch B at `q=11`.

Therefore

\[
\begin{aligned}
N_{3,7,11}(X)
&\le N_A(X)+N_B(X)\\
&\ll
\frac{X}{(\log X)^{5/2}}
+
\frac{X}{(\log X)^{27/10}}.
\end{aligned}
\]

The first term dominates.

Hence:

### Theorem — three fixed Type-II shifts leave a five-halves-dimensional sifted set

\[
\boxed{
\#\{p\le X:\ p\text{ prime and }q=3,7,11\text{ all miss}\}
\ll
\frac{X}{(\log X)^{5/2}}.}
\]

The same bound holds after restriction to the six Mordell-hard classes.

---

## 6. Relative prime density

Since

\[
\pi(X)\sim X/\log X,
\]

the relative density of triple survivors among primes is

\[
\boxed{
O\left((\log X)^{-3/2}\right).}
\]

Thus the first three prime Type-II shifts alone capture all but a very thin relative subset of primes.

Again, this does not approach the strength of the best classical full-ES exceptional-set bounds. Its value is that it arises from three explicit exact strong/Type-II corridor positions.

---

## 7. Local-density interpretation

The dominant Branch-A sieve dimension decomposes as

\[
\boxed{
1
+\frac12
+\frac12
+\frac12
=
\frac52.}
\]

The four pieces are:

1. primality of `4A-3`;
2. inert-prime exclusion from `A` modulo `3`;
3. quadratic-NR exclusion from `A+1` modulo `7`;
4. quadratic-NR exclusion from `A+2` modulo `11`.

The three shifted factor restrictions occur at distinct residues

\[
0,-1,-2\pmod\ell
\]

for almost every sieve prime, so their local dimensions add cleanly.

---

## 8. Prior-art boundary

Vaughan, Elsholtz, and later work obtain substantially stronger exceptional-set estimates for Erdős--Straus using broader parametric solution families and deeper sieve arguments.

No novelty claim is made for:

- the upper-bound sieve;
- density-zero exceptional sets;
- the general use of several parametric families to increase sieve dimension.

The specific contribution here is the transparent translation of the exact `q=3,7,11` Type-II factorization filters into an additive sieve-dimension ledger.

---

## 9. Next target

The corridor now suggests a systematic program.

For each small prime shift

\[
q\equiv3\pmod4,
\]

classify the exact miss into:

1. a main splitting branch excluding a positive-density set of prime divisors of `(p+q)/4`;
2. finitely many low-entropy defect branches.

If the main splitting density and every defect-branch density can be quantified uniformly, each new corridor position can add positive sieve dimension.

The immediate algebraic targets are `q=19` and `q=23`.
