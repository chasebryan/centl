# Single-active first-shell theorem and hard-class 3/5/9 collapse

**Status:** proved theorem and hard-class corollary; pending external mathematical review  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Coordinator:** Operator-01 / primary research lead  
**Partner framework:** Operator-02 active fixed-negative core / valuation criterion  
**Claim boundary:** this theorem is a structural result inside the Type A/B minimal-depth program. It does not prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture.

Read with:

- [SINGLE-ACTIVE-EXCESS-PRIME-POWER.md](SINGLE-ACTIVE-EXCESS-PRIME-POWER.md)
- [SINGLE-ACTIVE-HARD-COLLAPSE-K100000.md](SINGLE-ACTIVE-HARD-COLLAPSE-K100000.md)
- [CLASS-C-CENSUS-K1500.md](CLASS-C-CENSUS-K1500.md)
- [operator-02/DIAMOND-FIXED-NEGATIVE-PULLBACK-SPLIT.md](operator-02/DIAMOND-FIXED-NEGATIVE-PULLBACK-SPLIT.md)
- [operator-02/DIAMOND-VALUATION-CRITERION.md](operator-02/DIAMOND-VALUATION-CRITERION.md)

## 1. Setup

Let the target Type A/B candidate have modulus

\[
M=4k-1
\]

and progression modulus

\[
L=\operatorname{lcm}(840,M).
\]

Let an earlier fixed-negative layer have modulus

\[
m=4j-1.
\]

Write its squarefree kernel as `d`. Since the layer is fixed at squareclass level,

\[
\boxed{m=d s^2}
\]

for a positive odd integer `s`, where

\[
d\equiv3\pmod4,
\qquad d\mid L.
\]

For the target residue `r`, the Jacobi sign on the whole `d`-tower is constant:

\[
\left(\frac r{d u^2}\right)=\left(\frac r d\right)
\]

whenever the symbol is defined.

A tower layer `d u^2<M` is active exactly when

\[
du^2\nmid L.
\]

Assume that the global active fixed-negative core has exactly one member. Then the negative `d`-tower containing that member has exactly one active layer.

The goal is to classify that unique active shell.

## 2. Tower normalization

Define

\[
A=\frac Ld.
\]

Because `d` is odd and `M` is odd,

\[
\boxed{v_2(A)=3.}
\]

Indeed `v_2(L)=v_2(840)=3`.

Let

\[
c=\frac LM
=\frac{840}{\gcd(840,M)}.
\]

Then

\[
\boxed{
A=c\frac Md.
}
\]

and `c` is an integer divisor of `840` with exact 2-adic valuation `3`.

Let `s` be the unique active square parameter in the negative tower, and let `N` be the largest positive odd integer satisfying

\[
dN^2<M.
\]

Thus

\[
N^2<\frac Md\le(N+2)^2
\]

and consequently

\[
\boxed{
cN^2<A\le c(N+2)^2.}
\]

Every other odd `u<=N`, `u!=s`, is an earlier fixed-negative layer. Uniqueness of the active core forces it inactive:

\[
du^2\mid L.
\]

Since `d|L`, this is equivalent to

\[
\boxed{u^2\mid A.}
\]

The active shell itself satisfies

\[
\boxed{s^2\nmid A.}
\]

We now show this can happen only at `s=3` or `s=5`.

## 3. Elimination of s >= 9

Assume

\[
s\ge9.
\]

Then the tower layers `u=3,5,7` are all earlier than the active shell and hence inactive. Therefore

\[
9d\mid L,
\qquad
25d\mid L,
\qquad
49d\mid L.
\]

For each of the primes `3,5,7`, the exponent contributed by the square is at least `2`, while `840` contains that prime only to exponent `1`. Hence the required exponent must occur in `M`.

Thus

\[
3\cdot5\cdot7=105\mid M,
\]

so

\[
\gcd(840,M)=105
\]

and therefore

\[
\boxed{c=8.}
\]

Since `N>=s>=9`, consider the two largest odd positions.

### Case 1: s is neither N nor N-2

Then both `N` and `N-2` are inactive. They are coprime because they are odd and differ by `2`. Hence

\[
N^2(N-2)^2\mid A.
\]

But for every odd `N>=9`,

\[
N^2(N-2)^2>8(N+2)^2,
\]

contradicting

\[
A\le8(N+2)^2.
\]

### Case 2: s=N

Then `N-2` and `N-4` are inactive and coprime. Hence

\[
(N-2)^2(N-4)^2\mid A.
\]

For `N>=9`,

\[
(N-2)^2(N-4)^2>8(N+2)^2,
\]

again impossible.

### Case 3: s=N-2

Then `N` and `N-4` are inactive. Since `N` is odd,

\[
\gcd(N,N-4)=\gcd(N,4)=1.
\]

Therefore

\[
N^2(N-4)^2\mid A,
\]

while for `N>=9`,

\[
N^2(N-4)^2>8(N+2)^2.
\]

Contradiction.

Thus

\[
\boxed{s<9.}
\]

## 4. Elimination of s = 7

Assume

\[
s=7.
\]

The `u=3` and `u=5` layers are earlier and inactive, so

\[
9d\mid L,
\qquad25d\mid L.
\]

As above, the necessary exponents of `3` and `5` cannot come from `840` alone, hence

\[
15\mid M.
\]

Therefore

\[
\gcd(840,M)\in\{15,105\}
\]

and

\[
\boxed{c\in\{56,8\}.}
\]

### If N >= 11

Then `N` and `N-2` are both different from the active value `7`, so both are inactive and coprime. Hence

\[
N^2(N-2)^2\mid A.
\]

For every odd `N>=11`,

\[
N^2(N-2)^2>56(N+2)^2.
\]

Since `c<=56`, this contradicts

\[
A\le c(N+2)^2.
\]

So only `N=7` or `N=9` remain.

### If N = 9

The inactive values `3,5,9` give

\[
\operatorname{lcm}(3^2,5^2,9^2)
=2025
\mid A.
\]

If `c=8`, then

\[
648<A\le968,
\]

which contains no positive multiple of `2025`.

If `c=56`, then

\[
4536<A\le6776.
\]

The only multiple of `2025` in this interval is

\[
A=6075,
\]

but

\[
v_2(6075)=0\ne3=v_2(A),
\]

contradiction.

### If N = 7

The inactive values `3,5` imply

\[
225\mid A.
\]

If `c=8`, then

\[
392<A\le648.
\]

The only multiple of `225` is `450`, with

\[
v_2(450)=1\ne3.
\]

If `c=56`, then

\[
2744<A\le4536.
\]

Write

\[
A=225m.
\]

The interval forces

\[
13\le m\le20.
\]

Since `225` is odd, the condition `v_2(A)=3` would require

\[
v_2(m)=3.
\]

But among the integers `13,...,20`, the only multiple of `8` is `16`, whose 2-adic valuation is `4`, not `3`.

Contradiction.

Hence

\[
\boxed{s\ne7.}
\]

Combining with the previous section and the fact that `s=1` is inactive because `d|L`, we obtain the main theorem.

## 5. Universal first-shell theorem

### Theorem

If a negative fixed-squareclass tower contains exactly one active layer below the target modulus, then its unique active square parameter is

\[
\boxed{s\in\{3,5\}.}
\]

Consequently, if the global active fixed-negative core has size one, its unique excess quotient satisfies

\[
\boxed{q\in\{3,5,9,25\}.}
\]

### Quotient classification

If `s=3`, then

\[
v_3(d3^2)=v_3(d)+2\le3,
\]

while `v_3(L)>=1`. Activity therefore leaves quotient exponent at most `2`:

\[
\boxed{q\in\{3,9\}.}
\]

If `s=5`, the same argument gives

\[
\boxed{q\in\{5,25\}.}
\]

This strengthens the earlier general `q=p` or `p^2` theorem by identifying the only possible prime directions in a unique active tower.

## 6. Hard-class elimination of q = 25

Now impose the Mordell-hard target classes

\[
H=\{1,121,169,289,361,529\}\pmod{840}.
\]

Every class in `H` is a nonzero quadratic residue modulo `5`:

\[
H\pmod5\subseteq\{1,4\}.
\]

Therefore the target residue satisfies

\[
\boxed{\left(\frac r5\right)=+1.}
\]

Assume for contradiction that the unique active fixed-negative layer has

\[
q=25.
\]

By the universal theorem it must have `s=5`, so

\[
m=d5^2.
\]

For the quotient to contain `5^2`, the squarefree kernel must contain `5` and `L` must contain only one power of `5`:

\[
5\mid d,
\qquad
v_5(L)=1.
\]

Indeed, if `5` did not divide `d`, then `m` would contain only `5^2` while `L` already contains one factor of `5`, leaving at most a single factor `5` in the quotient.

Put

\[
d'=d/5.
\]

Because `5=1 mod 4` and `d=3 mod 4`,

\[
d'\equiv3\pmod4.
\]

Also `d'` is squarefree and supported on primes dividing `L`.

The hard-class quadratic residue condition gives

\[
\left(\frac r{d'}\right)
=
\left(\frac r d\right)
\left(\frac r5\right)^{-1}
=-1.
\]

So `d'` defines another fixed-negative tower.

Now consider its `s=5` layer:

\[
m'=d'5^2=m/5<m<M.
\]

Its `5`-valuation is `2`, while `v_5(L)=1`, hence

\[
q'=rac{m'}{\gcd(L,m')}=5>1.
\]

Thus `m'` is a **second active fixed-negative earlier layer**, contradicting

\[
|\mathcal N^{\rm act}|=1.
\]

Therefore

\[
\boxed{q\ne25}
\]

for hard-compatible single-active candidates.

## 7. Hard-class 3/5/9 collapse theorem

### Corollary

For every Mordell-hard compatible Type A/B target candidate,

\[
\boxed{
|\mathcal N^{\rm act}_{k,r}|=1
\Longrightarrow
q_{j_0}\in\{3,5,9\}.
}
\]

Moreover the excess is necessarily Operator-02 **Class A**, because both primes `3` and `5` already divide

\[
L=\operatorname{lcm}(840,M).
\]

Thus

\[
\boxed{
\text{hard-compatible single-active}
\Longrightarrow
\text{Class A only, with }q=3,5,\text{ or }9.
}
\]

QED.

## 8. Independent finite regression

This theorem exactly explains the independently verified computation through

\[
k\le100,000,
\]

which examined

\[
8,021,288
\]

hard-compatible Type A/B target candidates and found

\[
419,123
\]

single-active cases:

```text
q=3: 252,832
q=5:   4,173
q=9: 162,118
other:      0
Class B:    0
```

See [SINGLE-ACTIVE-HARD-COLLAPSE-K100000.md](SINGLE-ACTIVE-HARD-COLLAPSE-K100000.md).

The finite run is now best viewed as a large regression/falsification check of the theorem rather than the basis for the theorem.

## 9. What this removes from C1

The single-active branch no longer contains arbitrary valuation geometry.

It has exactly three hard-compatible quotient shapes:

\[
\boxed{3,5,9.}
\]

Combined with [SINGLE-ACTIVE-LOCAL-ESCAPE.md](SINGLE-ACTIVE-LOCAL-ESCAPE.md), the unique active fixed-negative row itself always admits a reduced exact local escape.

Therefore the remaining C1 problem is not to understand an arbitrary active row. It is to coordinate one of three tiny Class-A local shells with the nonfixed exact rows that survive fiber peeling.

That is a substantially smaller theorem target.

## 10. Review and novelty boundary

The proof uses only elementary valuation arithmetic, Jacobi-symbol invariance under square factors, lcm divisibility, and the fixed modulus `840`. Those ingredients are classical.

The research contribution under review is the Type-A/B-specific active-core formulation and the first-shell classification inside the minimal-depth/shadow program.

This note should receive independent mathematical review, including Operator-02 adversarial review, before being treated as publication-ready.
