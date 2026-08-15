# Quotient-9 shadow rigidity

**Status:** proved theorem inside the Type A/B minimal-depth/shadow program  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this does not prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture. It completely classifies unrestricted full direct shadows along the ancestry quotient `q=9`.

Read with:

- [PRIME-CHILD-SHADOWS.md](PRIME-CHILD-SHADOWS.md)
- [SQUARE-LIFT-TOWERS.md](SQUARE-LIFT-TOWERS.md)
- [RECIPROCITY-TOWER-SHADOWS.md](RECIPROCITY-TOWER-SHADOWS.md)
- [DYADIC-TRAP-LATTICE.md](DYADIC-TRAP-LATTICE.md)

## 1. Quotient-9 ancestry

Fix a source depth `j>=1`, put

\[
m=4j-1,
\]

and define its quotient-9 ancestry child

\[
\boxed{K=9j-2.}
\]

Then

\[
4K-1=9(4j-1)=9m.
\]

Thus this is exactly the odd-square lift with square multiplier

\[
9=3^2.
\]

Also

\[
\boxed{K\equiv j\pmod m}
\]

and

\[
\boxed{4K\equiv1\pmod m.}
\]

## 2. Normalized trap sets

It is convenient to negate the trap sets. Define

\[
S_n=-T_n
=
\{e,4e\pmod{4n-1}:e\mid n\}.
\]

The set `S_n` is inverse-closed. Indeed, if `e|n` and `f=n/e`, then

\[
(4e)f=4n\equiv1\pmod{4n-1},
\]

so

\[
(4e)^{-1}\equiv f,
\]

and conversely.

For the ancestry pair `(j,K)`, if `e f=K`, then modulo `m`

\[
(4e)f=4K\equiv1.
\]

Therefore, once every divisor residue `e mod m` belongs to `S_j`, all companion residues `4e mod m` belong as well by inverse closure.

Hence:

### Lemma

For `K=9j-2`,

\[
\boxed{
T_K\bmod m\subseteq T_j
\iff
 e\bmod m\in S_j\quad\text{for every divisor }e\mid K.
}
\]

This reduces quotient-9 full shadowing to the image of the target divisor lattice.

## 3. Classification theorem

### Theorem

Let

\[
K=9j-2.
\]

Then the complete unrestricted target layer is shadowed by `j` if and only if exactly one of the following occurs:

1. `K` is prime;
2. `K=2p` with `p` prime;
3. `(j,K)=(2,16)`.

Equivalently,

\[
\boxed{
T_{9j-2}\bmod(4j-1)\subseteq T_j
\iff
\begin{cases}
9j-2\text{ is prime},\quad\text{or}\\
(9j-2)/2\text{ is prime},\quad\text{or}\\
j=2.
\end{cases}
}
\]

In the second alternative `j` is automatically even because `9j-2` is even.

## 4. Prime child direction

If `K` is prime, the general prime-child ancestry theorem applies immediately:

\[
\boxed{T_K\bmod m\subseteq T_j.}
\]

## 5. Twice-prime child direction

Suppose

\[
K=2p
\]

with `p` prime.

Then `K` is even, so `j` is even. Put

\[
d=j/2.
\]

Since

\[
K=9j-2,
\]

we have

\[
p=\frac K2=\frac{9j-2}{2}.
\]

Subtract `d=j/2`:

\[
p-d
=
\frac{8j-2}{2}
=4j-1
=m.
\]

Therefore

\[
\boxed{p\equiv d=j/2\pmod m.}
\]

The divisors of `K=2p` are

\[
1,2,p,K.
\]

Modulo `m` these become

\[
1,\quad2,\quad j/2,\quad j,
\]

and every one is a divisor of `j`.

Thus every target divisor residue lies in `S_j`, so by the normalized-divisor lemma

\[
\boxed{T_K\bmod m\subseteq T_j.}
\]

## 6. Exceptional child K = 16

For

\[
j=2,
\]

we get

\[
K=16,
\qquad
m=7.
\]

The normalized base trap set is

\[
S_2=\{1,2,4\}\pmod7.
\]

Every divisor of `16` is a power of two, and its residue modulo `7` lies in

\[
\{1,2,4\}.
\]

Therefore

\[
\boxed{T_{16}\bmod7\subseteq T_2.}
\]

This is the unique composite child in the quotient-9 classification that is neither prime nor twice a prime.

## 7. Converse when j is odd

Assume `j` is odd. Then `K=9j-2` is odd.

Suppose `K` is composite. Let `ell` be its smallest prime factor. Then

\[
\ell\le\sqrt K.
\]

For every composite odd child beyond the tiny initial range,

\[
\sqrt K<4j-1=m,
\]

and the few initial values are checked directly. In fact the inequality already holds for every relevant odd `j>=1` with composite `K`.

Also

\[
\gcd(j,K)
=
\gcd(j,9j-2)
=
\gcd(j,2)
=1,
\]

so

\[
\ell\nmid j.
\]

Because `ell` is an odd integer with

\[
1<\ell<m,
\]

it cannot be a member of the normalized base set `S_j`:

- it is not a divisor of `j`;
- every unwrapped value `4d` with `d<j` is divisible by `4`, hence cannot equal odd `ell`;
- the only wrapped endpoint `4j` reduces to `1`.

Thus

\[
\ell\notin S_j.
\]

But `ell|K`, so the normalized-divisor lemma says full shadowing fails.

Therefore, when `j` is odd,

\[
\boxed{
T_K\bmod m\subseteq T_j
\iff
K\text{ is prime}.
}
\]

## 8. Converse when j is even

Now let

\[
j=2d.
\]

Then

\[
K=18d-2
=2N,
\]

where

\[
\boxed{N=9d-1.}
\]

Also

\[
N-m
=
(9d-1)-(8d-1)
=d,
\]

because

\[
m=4j-1=8d-1.
\]

Hence

\[
\boxed{N\equiv d=j/2\pmod m.}
\]

Suppose `N` has an odd prime factor `ell`.

Choose the smallest such factor. Since `ell|N` and

\[
\gcd(N,d)=\gcd(9d-1,d)=1,
\]

we have

\[
\ell\nmid j.
\]

Also `ell<m` except for the prime case `N=ell` itself. If `N` is composite with an odd prime factor, choosing a proper prime factor gives `ell<=sqrt N<m`.

As above, an odd `ell` with `1<ell<m` and `ell not|j` cannot lie in `S_j`.

Therefore full shadowing forces either:

1. `N` is prime, giving the twice-prime family `K=2N`; or
2. `N` has no odd prime factor, so
   \[
   N=2^r.
   \]

We must classify the second possibility.

## 9. The power-of-two residual is unique

Suppose

\[
N=9d-1=2^r.
\]

Then

\[
2^r\equiv-1\pmod9.
\]

The powers of `2 mod 9` have period `6`, and `-1 mod 9` occurs exactly when

\[
\boxed{r\equiv3\pmod6.}
\]

For `r=3`,

\[
N=8,
\qquad
d=1,
\qquad\j=2,
\qquad K=16,
\]

which is the exceptional shadow already found.

Now suppose `r>=9`. Then `d=(2^r+1)/9` is odd, so

\[
j=2d
\]

has exact 2-adic valuation `1`.

The target depth is

\[
K=2N=2^{r+1},
\]

so `16|K` and therefore `16` is a target divisor.

For `r>=9`,

\[
16<m=8d-1.
\]

But `16` cannot lie in `S_j`:

- `16` is not a divisor of `j`, because `v_2(j)=1`;
- if `16=4e` in the unwrapped second family, then `e=4`, but `4 not|j`;
- the wrapped endpoint is only `1`.

Hence the target divisor `16` escapes the base normalized trap set.

Therefore no `r>=9` works.

So the unique power-of-two residual is

\[
\boxed{j=2,\ K=16.}
\]

Combining all cases proves the classification theorem. QED.

## 10. Structural interpretation

The quotient-5 theorem said:

\[
\boxed{q=5:\quad\text{full unrestricted shadow}\iff\text{child prime}.}
\]

The new quotient-9 theorem says:

\[
\boxed{
q=9:\quad
\text{full unrestricted shadow}
\iff
\text{child has divisor lattice of prime / twice-prime type, plus }16.
}
\]

This is the first exact evidence that **composite-child shadowing is controlled by the factorization shape of the child depth itself**.

The square multiplier `9=3^2` permits one extra divisor coordinate, but only in an extremely rigid way.

## 11. Infinite shadow subfamilies

The theorem gives several infinite families.

### Prime children

Prime children satisfy

\[
K\equiv-2\equiv7\pmod9.
\]

Dirichlet gives infinitely many primes in this class, hence infinitely many quotient-9 prime-child shadows.

### Twice-prime children

Write

\[
K=2p=9j-2.
\]

Then

\[
p\equiv-1\equiv8\pmod9.
\]

Every prime

\[
p\equiv8\pmod9
\]

gives

\[
j=\frac{2p+2}{9}
=\frac{2(p+1)}9
\]

and hence a quotient-9 full shadow.

Dirichlet gives infinitely many such primes.

Therefore the quotient-9 graph has at least two infinite arithmetic components:

\[
\boxed{
K\text{ prime},\ K\equiv7\pmod9,
}
\]

and

\[
\boxed{
K=2p,\quad p\text{ prime},\ p\equiv8\pmod9.
}
\]

## 12. Counting

For child depths `K<=X`, the prime component has asymptotic count

\[
\pi(X;9,7)
\sim
\frac{1}{6}\frac{X}{\log X}.
\]

The twice-prime component corresponds to primes

\[
p\le X/2,
\qquad
p\equiv8\pmod9,
\]

and therefore has asymptotic count

\[
\pi(X/2;9,8)
\sim
\frac{1}{12}\frac{X}{\log X}.
\]

Ignoring their disjoint tiny exception, quotient `9` therefore contributes

\[
\boxed{
\left(\frac14+o(1)\right)
\frac{X}{\log X}
}

unrestricted full-shadow child depths up to `X`.

## 13. Next theorem target

The next ancestry quotient is

\[
q=13,
\qquad
K=13j-3.
\]

Unlike `9`, the quotient is prime rather than a square. The prime-child family is automatic, but composite children may obey a different rigidity law.

The broader target is now clear:

> For each fixed ancestry quotient `q=4s+1`, classify the factorization types of the child depth `K=qj-s` for which every target divisor residue is absorbed by the base divisor/inverse set.

Quotients `5` and `9` are now completely solved in the unrestricted system.

## 14. Novelty boundary

Divisor arguments, Dirichlet's theorem, and elementary congruences are classical. López Type A/B congruences are prior art.

The candidate contribution is the **exact quotient-9 ancestry shadow classification in the `C_AB` minimal-depth/shadow framework**, extending the prime-child theorem into a genuinely composite-child rigidity theorem.

Publication priority remains subject to external review and broader prior-art search.
