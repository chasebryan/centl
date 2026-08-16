# Class-conditioned character annihilation at fixed Erdős–Straus shifts

**Status:** exact finite-group theorem series  
**Date:** 2026-08-16  
**Depends on:** `MORDELL-HARD-CLASS-CONDITIONED-SEED-LAW.md`, the exact fixed-shift two-target signed-box equivalence, and the existing per-shift state classifiers  
**Claim boundary:** these are range-free implications at the named fixed shifts and hard residue classes. They do not prove that every hard prime is covered by these shifts, and they do not prove Erdős–Straus.

## 1. Setup

Let `p` be a Mordell-hard prime, so

```text
p mod 840 in {1,121,169,289,361,529}.
```

Fix a prime shift

```text
q == 3 (mod 4)
```

and put

```text
C_q = (p+q)/4.
```

The exact fixed-shift Lane-I problem is a two-target signed-divisor problem in the unit group modulo `q`.

The class-conditioned seed theorem gives the maximal divisor forced by the exact hard class `h=p mod 840`:

```text
g(q,h) = gcd(210,(h+q)/4).
```

Therefore every actual companion on that class has the form

```text
C_q = g(q,h) * R
```

for some positive integer `R`.

The state closure used here first consumes every prime factor of the mandatory seed, with multiplicity, and then permits arbitrary additional unit-factor directions. Consequently the resulting finite state space is a **superset of every actual factorization state** that can occur on the class.

This is the key logical direction: if a character branch contains no miss state even in that superset closure, then no actual prime in the class can miss on that branch.

## 2. Why state-center parity is the prime character

For prime `q`, the multiplicative group modulo `q` is cyclic of even order `q-1`. In discrete-log coordinates, even exponents are quadratic residues and odd exponents are quadratic nonresidues.

The state center is the discrete log of `C_q mod q`. Since

```text
C_q == p * 4^(-1) (mod q)
```

and `4` is a square modulo every odd prime,

```text
(C_q/q) = (p/q).
```

Thus:

```text
even center  <=> (p/q) = +1
odd center   <=> (p/q) = -1.
```

For the hard-prime domain `p==1 mod4`, quadratic reciprocity also gives `(p/q)=(q/p)`, but the theorem is stated below using `(p/q)` to match the finite-state construction directly.

## 3. Exact closure ledger

The relevant exact seeded closures are:

```text
shift q   seed   states   misses   +1 misses   -1 misses
11           3       25        9            7           2
11          15       15        5            5           0

31           2      760      118           88          30
31          10       75       18           18           0
31          14      153       23           22           1
31          70       45       15           15           0

47           6     1079      196          116          80
47          42       97       24           24           0

59           3    35740     5869         3148        2721
59         105      133       30           30           0
```

The `q=59, seed=105` line reproduces the already-proved class-conditioned `k=59` theorem and is retained here as a control. The new content is the corresponding annihilation at `q=11`, `q=31`, and `q=47`.

## 4. Range-free q=11 theorem

At `q=11`, the six hard-class seeds are

```text
h=1      ->  3
h=121    ->  3
h=169    -> 15
h=289    -> 15
h=361    ->  3
h=529    -> 15
```

The seed-15 closure contains only 15 states. Its five miss states all have positive quadratic character. There is no negative-character miss state.

### Theorem 11

For every Mordell-hard prime `p`, if

```text
p mod 840 in {169,289,529}
```

and

```text
(p/11) = -1,
```

then the fixed shift `k=11` hits the exact Lane-I two-target criterion and therefore gives an Erdős–Straus decomposition.

Equivalently, any prime in one of those three hard classes that survives `k=11` must satisfy

```text
(p/11) = +1.
```

This statement has no finite `p` cutoff.

## 5. Range-free q=31 theorem

At `q=31`, the class seeds are

```text
h=1      ->  2
h=121    ->  2
h=169    -> 10
h=289    -> 10
h=361    -> 14
h=529    -> 70
```

The seed-10 closure has 18 misses, all positive character. The seed-70 closure has 15 misses, all positive character.

### Theorem 31

For every Mordell-hard prime `p`, if

```text
p mod 840 in {169,289,529}
```

and

```text
(p/31) = -1,
```

then fixed `k=31` hits.

Hence every survivor in those three hard classes must satisfy

```text
(p/31) = +1.
```

### Exact boundary: h=361 is not included

The class `h=361` has seed 14, not 10 or 70. Its exact closure has

```text
153 states
23 misses
22 positive-character misses
1 negative-character miss.
```

That lone abstract negative state is genuinely realizable. The smallest prime realization is

```text
p = 54,121
p mod 840 = 361
(p/31) = -1
C_31 = (p+31)/4 = 13,538 = 2 * 7 * 967
```

and fixed `k=31` misses both exact targets.

Therefore **no q=31 negative-character annihilation is claimed for h=361**. The counterexample is pinned in the independent regression to prevent accidental future overstatement.

## 6. Range-free q=47 theorem

At `q=47`, the class seeds are

```text
h=1      ->  6
h=121    -> 42
h=169    ->  6
h=289    -> 42
h=361    ->  6
h=529    ->  6
```

The universal forced-6 closure has 1,079 states and 196 misses, including 80 negative-character misses.

Conditioning on `h=121` or `h=289` forces the stronger seed 42. The closure collapses to

```text
97 states
24 misses
24 positive-character misses
0 negative-character misses.
```

### Theorem 47

For every Mordell-hard prime `p`, if

```text
p mod 840 in {121,289}
```

and

```text
(p/47) = -1,
```

then fixed `k=47` hits.

Thus a survivor in either class must satisfy

```text
(p/47) = +1.
```

This is stronger than the earlier finite negative-character corridor evidence because it follows from an exact seeded finite-group closure and has no range parameter.

## 7. q=59 control theorem

The already-proved class-conditioned `k=59` atlas gives

```text
h=361 -> seed 105.
```

Its closure has

```text
133 states
30 misses
30 positive-character misses
0 negative-character misses.
```

Therefore

```text
p mod 840 = 361
and
(p/59) = -1
```

implies a fixed `k=59` hit.

The present cross-modulus implementation reproduces those constants independently of the older specialized `k=59` atlas, which serves as a control on the common state construction.

## 8. Combined survivor character tree

The new exact implications can be summarized by hard class:

```text
h=1      no new character condition from this atlas
h=121    survivor past k=47  -> (p/47)=+1
h=169    survivor past k=11,31 -> (p/11)=(p/31)=+1
h=289    survivor past k=11,31,47 -> (p/11)=(p/31)=(p/47)=+1
h=361    survivor past k=59 -> (p/59)=+1
h=529    survivor past k=11,31 -> (p/11)=(p/31)=+1
```

These restrictions alone do not contradict the Chinese remainder theorem. They are not a coverage proof.

Their value is that each surviving class now enters the six-companion residual-support problem with prescribed quadratic-character signs at several exact fixed shifts.

## 9. Independent finite realization regression

The theorem itself is finite-group and range-free. A separate direct arithmetic regression factors actual companions and checks the signed divisor box without importing the atlas classifier.

Through `p <= 2,000,000`:

```text
q=11 affected classes   2,247 primes   1,147 negative character   0 negative misses
q=31 affected classes   2,247 primes   1,171 negative character   0 negative misses
q=47 affected classes   1,511 primes     760 negative character   0 negative misses
q=59 affected class       745 primes     376 negative character   0 negative misses
```

The q=31 h=361 negative control contains

```text
745 class primes
383 negative-character primes
3 negative-character misses
```

with first misses

```text
54,121
1,408,201
1,824,841.
```

The finite counts are only regressions. The range-free implications come from closure of the complete seeded finite state spaces.

## 10. Strategic consequence

The natural next object is no longer an independent Legendre-symbol sieve.

The six-companion residual theorem proves that, after universal seeds are removed, every rational prime other than the named tiny exceptions can support at most one residual layer in a six-shift wheel. The present theorem says that, on several hard classes, simultaneous survival also forces definite quadratic-character sides at specific shift primes.

The next proof target is therefore a **class-conditioned cross-shift compatibility theorem**:

```text
forced seed
+
forced character side
+
almost-disjoint residual prime support
+
linear relations among neighboring residuals.
```

A contradiction must come from that coupled arithmetic. Independent character congruences by themselves remain CRT-compatible.

## 11. Reproduction

Run the exact atlas with

```sh
python3 research/erdos-straus/classify_class_conditioned_character_atlas.py --json
```

Run the independent finite realization regression with

```sh
python3 research/erdos-straus/verify_class_conditioned_character_atlas.py --limit 2000000 --json
```

Erdős–Straus remains open. The theorem series removes exact negative-character branches from several hard-class fixed-shift state spaces and preserves the known q=31 h=361 obstruction explicitly.