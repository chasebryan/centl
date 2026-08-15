# Exact ancestry rigidity for quotients 21 and 29

**Status:** proved exact unrestricted-shadow classifications  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** unrestricted Type A/B trap-set shadowing only. Hard-class-conditioned shadowing can be stronger. This does not prove Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture.

Read with:

- [ANCESTRY-DIVISOR-CHILD-THEOREM.md](ANCESTRY-DIVISOR-CHILD-THEOREM.md)
- [ANCESTRY-ASYMPTOTIC-SKELETON.md](ANCESTRY-ASYMPTOTIC-SKELETON.md)
- [QUOTIENT-9-RIGIDITY.md](QUOTIENT-9-RIGIDITY.md)

## 1. Quotient 21

Set

\[
K=21j-5,
\qquad
m=4j-1.
\]

This is the ancestry shift `s=5`.

### Theorem 1

\[
\boxed{
T_K\bmod m\subseteq T_j
\iff
\left(
K\text{ is prime}
\quad\text{or}\quad
K=5p\text{ with }p\text{ prime}
\right).
}
\]

In the `5p` case, necessarily `5|j`.

### Proof: direct implication

The divisor-child theorem with `s=5` has

\[
a\mid5.
\]

Thus `a=1` gives prime children and `a=5` gives `5p` whenever `5|j`. Both are fully shadowed.

### Proof: converse for j >= 6

The odd-shift asymptotic skeleton applies because

\[
j\ge s+1=6.
\]

Therefore full shadowing implies either:

1. `K` is `5`-smooth, hence `K=5^u`; or
2. `K=a p` with
   \[
   a\mid\gcd(j,5),
   \]
   so `a=1` or `5`.

The second case is exactly the claimed prime/`5p` family.

It remains to remove the smooth branch.

For an odd shift, any smooth child larger than `s` has some prime exponent exceeding its exponent in `s`. Here that means divisor

\[
25\mid K.
\]

If

\[
25<m,
\]

then the odd integer `25` is a divisor of `K` smaller than `m`. It cannot lie in `S_j` unless `25|j`. But

\[
\gcd(j,K)=\gcd(j,5)
\]

has `5`-valuation at most one, so `25∤j`. Thus smooth shadowing would require

\[
m\le25.
\]

For `j>=6`, this leaves only

\[
j=6,\qquad m=23,\qquad K=121.
\]

But divisor `11` satisfies

\[
1<11<m,
\qquad11\nmid j,
\]

so `11∉S_j` and shadowing fails.

Therefore no smooth exception occurs for `j>=6`.

### Small j = 1,...,5

The remaining cases are exact and tiny:

```text
j=1: K=16, m=3;  divisor 2 escapes S_1.
j=2: K=37;        prime, hence shadowed.
j=3: K=58, m=11; divisor 2 escapes S_3.
j=4: K=79;        prime, hence shadowed.
j=5: K=100,m=19; divisor 2 escapes S_5.
```

This completes the quotient-21 classification. QED.

## 2. Quotient 29

Set

\[
K=29j-7,
\qquad
m=4j-1.
\]

This is the ancestry shift `s=7`.

### Theorem 2

\[
\boxed{
T_K\bmod m\subseteq T_j
\iff
\left(
K\text{ is prime}
\quad\text{or}\quad
K=7p\text{ with }p\text{ prime}
\right).
}
\]

In the `7p` case, necessarily `7|j`.

### Proof: direct implication

The divisor-child theorem with `s=7` has only

\[
a=1\quad\text{or}\quad a=7.
\]

Thus prime children and `7p` children with `7|j` are fully shadowed.

### Proof: converse for j >= 8

The odd-shift skeleton applies for

\[
j\ge s+1=8.
\]

Hence a full shadow is either prime/`7p`, or `7`-smooth:

\[
K=7^u.
\]

A smooth child larger than `7` contains divisor

\[
49.
\]

If

\[
49<m,
\]

then `49<m` is an odd divisor of `K`. It cannot be in `S_j` unless `49|j`, but

\[
\gcd(j,K)=\gcd(j,7)
\]

has `7`-valuation at most one. Therefore a smooth full shadow requires

\[
m\le49.
\]

For `j>=8`, this leaves only

\[
8\le j\le12.
\]

These five cases are checked explicitly below.

### Exact small window j = 1,...,12

```text
j=1:  K=22,  m=3;  divisor 2 escapes.
j=2:  K=51,  m=7;  divisor 3 escapes.
j=3:  K=80,  m=11; divisor 2 escapes.
j=4:  K=109;        prime, hence shadowed.
j=5:  K=138, m=19; divisor 2 escapes.
j=6:  K=167;        prime, hence shadowed.
j=7:  K=196, m=27; divisor 2 escapes.
j=8:  K=225, m=31; divisor 3 escapes.
j=9:  K=254, m=35; divisor 2 escapes.
j=10: K=283;        prime, hence shadowed.
j=11: K=312, m=43; divisor 2 escapes.
j=12: K=341, m=47; divisor 11 escapes.
```

Every non-prime case in the smooth-exception window has an explicit divisor outside `S_j`.

For `j>=13`, the smooth branch is impossible by the `49<m` argument, so the asymptotic skeleton leaves only prime or `7p`.

This completes the quotient-29 classification. QED.

## 3. Ancestry ladder after these theorems

The exact unrestricted classifications now begin:

| Quotient `Q` | Shift `s` | Full-shadow child shapes |
|---:|---:|---|
| 5  | 1 | prime only |
| 9  | 2 | prime, `2p`, plus `(j,K)=(2,16)` |
| 13 | 3 | prime, `3p` |
| 17 | 4 | prime, `2p`, `4p`, plus `(j,K)=(4,64)` |
| 21 | 5 | prime, `5p` |
| 29 | 7 | prime, `7p` |

The quotient-21 and quotient-29 proofs are no longer separate ad hoc divisor searches. They are short corollaries of the universal odd-shift skeleton plus finite smooth-window elimination.

## 4. General prime-shift corollary template

Let `r` be an odd prime and set

\[
Q=4r+1,
\qquad
K=Qj-r.
\]

For

\[
j\ge r+1,
\]

the odd-shift skeleton gives

\[
\boxed{
\text{full shadow}
\Longrightarrow
K=r^u
\text{ or }
K=p
\text{ or }
K=rp\ (r|j).
}
\]

Any smooth case `K=r^u` with `u>=2` contains divisor `r^2`. Once

\[
r^2<m=4j-1,
\]

that divisor cannot lie in `S_j`, because `r^2∤j` follows from

\[
\gcd(j,K)=\gcd(j,r).
\]

Thus every odd-prime shift has only a finite explicit smooth window

\[
4j-1\le r^2
\]

to check.

This turns exact classification for all prime shifts into a finite arithmetic problem after the universal theorem.

## 5. Next target

Automate the finite smooth-window check for odd prime shifts `r` and determine whether any prime shift admits a genuine smooth exception.

If none do, then for every odd prime `r` we obtain the uniform exact theorem

\[
\boxed{
T_{(4r+1)j-r}\bmod(4j-1)\subseteq T_j
\iff
K\text{ prime or }K=rp\text{ with }r|j.
}
\]

That is now a sharply bounded theorem program rather than an open-ended search.
