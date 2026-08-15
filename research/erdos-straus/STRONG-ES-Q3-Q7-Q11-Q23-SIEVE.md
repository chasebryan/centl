# Cubic-log sieve bound from q=3,7,11,23 Type-II filters

**Status:** proved application of a classical upper-bound sieve  
**Date:** 2026-08-15  
**Depends on:** `STRONG-ES-Q3-Q7-Q11-SIEVE.md`, `STRONG-ES-Q23-EXACT-FILTER.md`  
**Imported classical tools:** Selberg/Brun upper-bound sieve, prime number theorem in arithmetic progressions  
**Claim boundary:** this is a specific quantitative consequence of four exact fixed Type-II filters. Classical full Erdős--Straus exceptional-set estimates are stronger. This does not prove universal strong/Type-II coverage.

---

## 1. Existing three-shift branches

Let

\[
A=\frac{p+3}{4}.
\]

The exact `q=3,7,11` analysis splits the survivor set into two `q=11` branches.

### q=11 Branch A

The sieve dimension is

\[
\boxed{5/2.}
\]

### q=11 Branch B

After harmlessly enlarging the exact thin defect branch, the sieve dimension is at least

\[
\boxed{27/10.}
\]

Therefore every three-shift survivor belongs to a branch of dimension at least

\[
\boxed{5/2.}
\]

---

## 2. q=23 acts at a new shifted residue

The `q=23` shifted integer is

\[
\boxed{A+5.}
\]

Thus every prime-factor exclusion at this position forbids the residue

\[
\boxed{A\equiv-5\pmod\ell}
\]

for the relevant sieve primes `ell`.

For all sufficiently large `ell`, this residue is distinct from:

- the primality residue for `4A-3`;
- `0`, used by the `q=3` filter;
- `-1`, used by `q=7`;
- `-2`, used by `q=11`.

Hence the local sieve dimensions add directly. The finitely many collision primes do not affect the logarithmic exponent.

---

## 3. q=23 Branch A adds one-half

The main `q=23` miss branch requires every prime factor of `A+5` to be a quadratic residue modulo `23`.

Quadratic nonresidue primes modulo `23` have density

\[
\boxed{1/2.}
\]

among primes.

Therefore Branch A adds exactly one-half unit of sieve dimension.

Applied to the weaker existing `q=11` Branch A:

\[
\boxed{
\frac52+\frac12=3.}
\]

This will be the dominant combined branch.

---

## 4. q=23 Branch B is substantially thinner

The thin `q=23` branch allows ordinary prime divisors of `A+5` only in the three residue classes

\[
\boxed{1,5,14\pmod{23},}
\]

apart from the fixed forced primes `2,3`.

Thus it forbids

\[
\boxed{19/22}
\]

of the reduced prime residue classes modulo `23`.

So any branch using the thin `q=23` geometry gains at least

\[
\boxed{19/22>1/2}
\]

of sieve dimension.

The exact valuation cap on the two allowed nonresidue classes makes the true branch even smaller.

---

## 5. Four branch combinations

Combine the two `q=11` branches with the two `q=23` branches.

The resulting lower bounds for sieve dimension are:

\[
\boxed{
\begin{array}{c|c|c}
q=11 & q=23 & \text{dimension lower bound}\\
\hline
A & A & 5/2+1/2=3\\
A & B & 5/2+19/22>3\\
B & A & 27/10+1/2=16/5>3\\
B & B & 27/10+19/22>3.
\end{array}}
\]

Thus every simultaneous four-shift survivor belongs to a sieve problem of dimension at least three.

---

## 6. Main theorem

Applying the classical upper-bound sieve branchwise and summing the four bounds gives:

### Theorem — four fixed Type-II shifts leave a dimension-three prime set

\[
\boxed{
\#\{p\le X:\ p\text{ prime and }q=3,7,11,23\text{ all miss}\}
\ll
\frac{X}{(\log X)^3}.}
\]

The same estimate holds after restricting to Mordell-hard primes.

---

## 7. Relative prime density

Since

\[
\pi(X)\sim X/\log X,
\]

the relative density of four-shift survivors among primes satisfies

\[
\boxed{
O\left((\log X)^{-2}\right).}
\]

Thus four explicit small Type-II shifts already remove all but a doubly-logarithmically thin relative subset of primes.

---

## 8. Interpretation

The logarithmic exponent has increased as follows:

\[
\boxed{
\begin{array}{c|c}
\text{fixed shifts used} & \text{upper-bound sieve dimension}\\
\hline
3,7 & 2\\
3,7,11 & 5/2\\
3,7,11,23 & 3.
\end{array}}
\]

Each useful corridor position contributes an explicit positive-density prime-factor exclusion on a new shifted integer `A+h`.

The exceptional finite-group defect branches do not reduce the current dominant exponent because they are more restrictive than the main splitting branches.

---

## 9. Prior-art boundary

The method remains classical sieve theory, and the best known full-ES exceptional-set estimates are much stronger.

The point of the present calculation is structural:

- the exact fixed-shift Type-II classifications produce a transparent local density ledger;
- the shifted residues `0,-1,-2,-5` are distinct;
- the sieve dimensions add visibly.

This creates a bridge between the finite-group signed-box analysis and analytic exceptional-set estimates.

---

## 10. Next target

Search for additional corridor primes `q` for which hard congruences force enough quadratic-residue generators into `(p+q)/4` that every miss branch excludes a uniformly positive density of prime residue classes.

If an infinite sequence of such shifts can be controlled uniformly, the fixed-shift sieve dimension would grow without bound. Turning that growth into a universal theorem would require constants and uniformity far beyond the present fixed-family argument, but it is now a precise analytic direction.
