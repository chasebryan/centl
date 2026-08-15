# Odd-prime-shift ancestry rigidity above the small-ancestor window

**Status:** proved universal theorem  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** unrestricted Type A/B trap-set shadowing only. The theorem applies for `j>=s+1`. Small `j` can contain additional full-shadow children and is a separate exception problem. This does not prove Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture.

Read with:

- [ANCESTRY-ASYMPTOTIC-SKELETON.md](ANCESTRY-ASYMPTOTIC-SKELETON.md)
- [ANCESTRY-DIVISOR-CHILD-THEOREM.md](ANCESTRY-DIVISOR-CHILD-THEOREM.md)
- [QUOTIENT-ODD-PRIME-S-RIGIDITY.md](QUOTIENT-ODD-PRIME-S-RIGIDITY.md) — corrected/retracted all-`j` claim

## 1. Setup

Let `r>=3` be an odd prime and put

\[
Q=4r+1,
\qquad
K=Qj-r,
\qquad
m=4j-1.
\]

No primality assumption on `Q` is required.

Assume

\[
\boxed{j\ge r+1.}
\]

## 2. The theorem

### Theorem

For every odd prime `r` and every `j>=r+1`,

\[
\boxed{
T_K\bmod m\subseteq T_j
\iff
\left(
K\text{ is prime}
\quad\text{or}\quad
K=r p\text{ with }p\text{ prime}
\right).
}
\]

In the second alternative necessarily

\[
r\mid j.
\]

Thus above the explicit small-ancestor window, the entire unrestricted full-shadow structure of an odd-prime shift is exactly the divisor-child family.

## 3. Direct implication

The divisor-child theorem applies with shift `s=r`.

Since `r` is prime, the only divisors of `r` are

\[
a=1,r.
\]

- `a=1` gives prime children;
- `a=r` gives `K=rp` when `r|j`.

Hence both stated shapes are fully shadowed.

## 4. Converse from the asymptotic skeleton

Because `r` is odd and `j>=r+1`, the odd-shift asymptotic skeleton applies.

Therefore a fully shadowed child satisfies exactly one of:

1. `K` is `r`-smooth;
2. `K=a p` with
   \[
   a\mid\gcd(j,r),
   \]
   and `p` prime.

Since `r` is prime, the second case is already

\[
K=p\quad\text{or}\quad K=rp.
\]

It remains only to eliminate the smooth branch.

## 5. Elimination of smooth children

If `K` is `r`-smooth, then

\[
K=r^u
\]

for some integer `u>=1`.

The ancestry equation gives

\[
r^u=(4r+1)j-r,
\]

hence

\[
\boxed{
j=\frac{r^u+r}{4r+1}.}
\]

### u = 1

Then

\[
j=\frac{2r}{4r+1}<1,
\]

impossible.

### u = 2

Integrality would require

\[
4r+1\mid r+1,
\]

because `gcd(r,4r+1)=1`.

But

\[
0<r+1<4r+1,
\]

impossible.

### u = 3

Integrality requires

\[
4r+1\mid r^2+1.
\]

Use the exact identity

\[
16(r^2+1)-(4r+1)(4r-1)=17.
\]

Therefore

\[
4r+1\mid17.
\]

For odd prime `r>=3`,

\[
4r+1\ge13.
\]

The only positive divisors of `17` at least `13` are `17` itself, which would give

\[
r=4,
\]

not an odd prime.

Thus `u=3` is impossible.

### u >= 4

The child modulus relation gives

\[
m=\frac{4r^u-1}{4r+1}.
\]

For every `r>=3` and `u>=4`,

\[
\boxed{m>r^2.}
\]

Indeed it is enough to check `u=4`:

\[
4r^4-1>r^2(4r+1),
\]

which is equivalent to

\[
4r^4-4r^3-r^2-1>0,
\]

true for `r>=3`.

But `r^2` is a divisor of `K=r^u` and satisfies

\[
1<r^2<m.
\]

Also

\[
\gcd(j,K)=\gcd(j,r),
\]

so

\[
r^2\nmid j.
\]

Because `r^2` is odd, it cannot be of the form `4e` for a divisor `e|j`. Hence

\[
r^2\notin S_j.
\]

This contradicts full shadowing.

Therefore no `r`-smooth full-shadow child exists.

The converse is complete. QED.

## 6. Why Q need not be prime

The proof uses only

\[
Q=4r+1\equiv1\pmod4
\]

for modulus ancestry and the arithmetic identity defining `K`.

It does not require `Q` itself to be prime.

Thus the theorem simultaneously contains:

- `r=3`, `Q=13`;
- `r=5`, `Q=21`;
- `r=7`, `Q=29`;
- `r=11`, `Q=45`;
- and every later odd-prime shift.

For the first few shifts, existing exact quotient-specific theorems additionally handle the finite small range `j<=r`.

## 7. Small-j exceptions really exist

The threshold `j>=r+1` cannot simply be deleted.

For example,

\[
r=17,
\qquad
j=2,
\qquad
K=121,
\qquad
m=7.
\]

Then

\[
S_2=\{1,2,4\}\pmod7
\]

and the divisors `1,11,121` reduce to `1,4,2`, so full shadowing holds even though `K` is neither prime nor `17p`.

Other small-window examples include:

```text
r=19, j=4:  K=289=17^2
r=53, j=4:  K=799=17*47
r=71, j=8:  K=2209=47^2
r=83, j=2:  K=583=11*53
```

These are governed by the exact multiplicative structure of the small ancestor `S_j`, not by the large-`j` factor-size mechanism.

## 8. Structural interpretation

The theorem separates odd-prime-shift ancestry into two regimes:

\[
\boxed{
\begin{array}{c}
1\le j\le r\\
\text{small-ancestor multiplicative exceptions possible}
\end{array}
}
\]

versus

\[
\boxed{
\begin{array}{c}
j\ge r+1\\
\text{full shadow}\iff\text{prime or }rp
\end{array}
}
\]

So the apparent infinite quotient-by-quotient complexity is actually concentrated into a finite-width diagonal strip `j<=r`.

Outside that strip, every odd-prime shift has exactly the same rigidity law.

## 9. Next target

Classify the small-ancestor exception strip

\[
\boxed{1\le j\le r}
\]

as `r` varies over odd primes.

For fixed `j`, the normalized ancestor trap set `S_j` is fixed, while

\[
K=r(4j-1)+j
\]

varies linearly with `r`.

Thus the exception problem becomes:

> classify prime parameters `r` for which every divisor of `r(4j-1)+j` lies inside the fixed finite residue set `S_j` modulo `4j-1`.

At dyadic ancestors `j=2^a`, the earlier Mersenne theorem gives

\[
S_j=\langle2\rangle,
\]

turning the condition into a concrete multiplicative-subgroup factorization problem.

That is the correct next layer of the ancestry diamond.
