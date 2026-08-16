# Universal forced-seed law for Mordell-hard fixed shifts

**Status:** proved elementary theorem  
**Date:** 2026-08-16  
**Applies to:** exact two-target fixed-shift state analysis  
**Regression:** `verify_mordell_hard_forced_seed_law.py`  
**Claim boundary:** this identifies the maximal common divisor forced by the Mordell-hard congruence skeleton at each admissible shift. It does not assert that the remaining factorization hits either Erdős–Straus target.

## 1. Setup

Every Mordell-hard prime satisfies

\[
\boxed{p\equiv1\pmod{24}.}
\]

Write

\[
p=24m+1.
\]

Every admissible fixed shift has

\[
k\equiv3\pmod4,
\]

so write

\[
\boxed{k=4u-1},
\qquad
u_k:=u=\frac{k+1}{4}.
\]

Then the shifted companion is

\[
C_k=\frac{p+k}{4}
=\frac{24m+1+4u-1}{4}
=6m+u.
\]

## 2. Universal forced divisor

Define

\[
\boxed{
g_k=\gcd(6,u)
=\gcd\!\left(6,\frac{k+1}{4}\right).
}
\]

Since `g_k` divides both `6m` and `u`,

\[
\boxed{g_k\mid C_k}
\]

for every Mordell-hard prime.

Because `g_k|6`, only four seed values are possible:

\[
\boxed{g_k\in\{1,2,3,6\}.}
\]

Thus every admissible shift belongs to exactly one of four hard-seed classes.

## 3. Exact periodic classification

The forced seed is determined by `u=(k+1)/4` modulo 6:

\[
\boxed{
\begin{array}{c|c}
u_k\pmod 6 & g_k\\
\hline
0&6\\
1&1\\
2&2\\
3&3\\
4&2\\
5&1
\end{array}}
\]

Equivalently, in terms of the shift:

- `g_k=6` when `k=23 mod 24`;
- `g_k=3` when `k=11 mod 24`;
- `g_k=2` when `k=7 or 15 mod 24`;
- `g_k=1` when `k=3 or 19 mod 24`.

The seed pattern is periodic with period 24 in `k`.

## 4. The seed is automatically a unit modulo the shift

The exact fixed-shift state model requires every factor of `C_k` used by the group classifier to be a unit modulo `k`.

For the universal seed:

- `k` is odd, so `2` never divides `k`;
- if `3|g_k`, then `3|u`, hence
  \[
  k=4u-1\equiv-1\pmod3,
  \]
  so `3` does not divide `k`.

Therefore

\[
\boxed{\gcd(g_k,k)=1.}
\]

The prime-valuation content of `g_k` can always be consumed as ordinary exact transitions before closing over the remaining factorization directions.

## 5. Maximality on the full Mordell-hard congruence skeleton

The six Mordell-hard residue classes modulo 840 are

\[
1,121,169,289,361,529.
\]

Writing `p=24m+1`, these correspond to

\[
m\equiv0,5,7,12,15,22\pmod{35}.
\]

For fixed `k=4u-1`, the companion values over the six complete arithmetic classes are

\[
210n+u,
\quad
210n+u+30,
\quad
210n+u+42,
\quad
210n+u+72,
\quad
210n+u+90,
\quad
210n+u+132.
\]

Any integer dividing every companion throughout the full Mordell-hard congruence skeleton must divide

\[
210,\ 30,\ 42,\ 72,\ 90,\ 132,\ u.
\]

But

\[
\gcd(210,30,42,72,90,132)=6.
\]

Hence the common divisor of the entire skeleton is exactly

\[
\boxed{\gcd(6,u)=g_k.}
\]

### Theorem — maximal hard-skeleton forced seed

For every admissible shift `k=4u-1`, the greatest integer dividing

\[
C_k=\frac{p+k}{4}
\]

for every integer `p` in the six complete Mordell-hard congruence classes is

\[
\boxed{g_k=\gcd(6,u).}
\]

Therefore no larger universal fixed divisor can be extracted from the Mordell-hard congruence skeleton alone.

This maximality is an arithmetic-class statement. It does not require assumptions about which individual values in those classes are prime.

## 6. Classified-shift ledger

For the current fixed-shift corridor:

```text
k     u=(k+1)/4     forced seed
3          1             1
7          2             2
11         3             3
15         4             2
19         5             1
23         6             6
27         7             1
31         8             2
35         9             3
39        10             2
43        11             1
47        12             6
51        13             1
55        14             2
59        15             3
63        16             2
```

Later examples include

```text
71 -> 6
79 -> 2
83 -> 3
87 -> 2
95 -> 6
103 -> 2
107 -> 3
```

The existing `k=47` forced-6 theorem and the new `k=55`, `k=59`, and `k=63` reductions are instances of this single law.

## 7. Quantitative consequence for the standard depth horizon

Through `k<=5000` there are exactly 1,250 admissible shifts. The forced-seed classes are

```text
seed 1 : 417 shifts
seed 2 : 417 shifts
seed 3 : 208 shifts
seed 6 : 208 shifts
```

Therefore

\[
\boxed{833/1250}
\]

of the admissible shifts in that horizon carry a nontrivial universal factor before any factorization-specific analysis begins.

This is a shift-count fact, not a statement that those shifts hit a corresponding fraction of primes.

## 8. Research consequence

A generic fixed-shift closure begins from the empty factorization state. For Mordell-hard research this is unnecessarily large whenever `g_k>1`.

The natural hard-prime workflow is:

1. compute `g_k=gcd(6,(k+1)/4)`;
2. factor `g_k` and consume its mandatory prime valuations as exact transitions;
3. close only over the remaining arbitrary factor directions;
4. intersect with any additional hard-center character restrictions already known for the modulus.

At the currently reduced shifts:

```text
k=47  forced 6   miss states   196   from 14,474 generic
k=55  forced 2   miss states   314   from  2,319 generic admissible
k=59  forced 3   miss states 5,869   from 61,215 generic
k=63  forced 2   miss states    87   from    684 generic admissible
```

These are the natural hard-prime state spaces for subsequent cross-shift theorem mining.

The law also exposes previously unused seeds at already-classified shifts such as `k=35` (`g=3`) and `k=39` (`g=2`).

## 9. Reproduction

```sh
python3 research/erdos-straus/verify_mordell_hard_forced_seed_law.py --max-k 5000 --json
```

The verifier checks the closed formula against the gcd of the complete six-class Mordell-hard skeleton for every admissible shift through the requested bound.

Erdős–Straus remains open. The theorem removes avoidable generic state geometry before the proof search begins.
