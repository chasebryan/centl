# Negative-Legendre `k=47` corridor census

**Status:** exact fixed-`k` state analysis plus finite theorem-mining census  
**Date:** 2026-08-16  
**Analyzer:** `analyze_k47_negative_corridor.py`  
**Claim boundary:** fixed-`k=47` state statements below are exact. Cross-shift statements are finite censuses only. Erdős–Straus remains open.

---

## 1. Exact forced-6 fixed-47 classification

For every Mordell-hard prime `p ≡ 1 (mod 24)`,

\[
C_{47}=\frac{p+47}{4}
\]

is divisible by `6=2·3`. The forced-6 state closure contains 1,079 hard-prime states, of which 196 miss the two fixed-47 targets. Their character split is

\[
116\text{ with }(47/p)=+1,
\qquad
80\text{ with }(47/p)=-1.
\]

The 80 negative-character misses are exactly the one-additional-nonresidue-packet branch.

Using base-5 logarithms modulo 47, those 80 states partition exactly into eleven representative classes:

| log direction `r` | residue mod 47 | exact miss states |
|---:|---:|---:|
| 1 | 5 | 7 |
| 7 | 11 | 2 |
| 9 | 40 | 13 |
| 11 | 13 | 13 |
| 17 | 38 | 9 |
| 19 | 10 | 9 |
| 27 | 26 | 9 |
| 29 | 19 | 9 |
| 35 | 20 | 4 |
| 37 | 33 | 4 |
| 45 | 29 | 1 |

The classes are disjoint and their union is exactly the 80-state negative-character forced-6 miss family.

A representative direction is a state-equivalence label. It is not a claim that an actual factorization contains one uniquely distinguished prime in that residue class.

---

## 2. The original 10M observation

On the **complete** Mordell-hard prime universe through `10,000,000` there are

\[
\boxed{20,513}
\]

hard primes. Exactly

\[
\boxed{822}
\]

have `(47/p)=-1` and miss `k=47`.

Applying earlier shifts gives

```text
start  822
k=3    558
k=7    302
k=11   118
k=15    81
k=19    48
k=23    13
k=27     7
k=31     2
k=35     1
k=39     0
k=43     0
```

On that finite domain, the unique minimum seven-layer cover is

\[
\{3,7,15,23,27,31,39\}.
\]

The 822 targets occupy 62 of the 80 exact negative-character fixed-47 miss states. Their finite minimum-cover histogram was

```text
1 earlier shift   35 states
2 earlier shifts   9 states
3 earlier shifts  11 states
4 earlier shifts   7 states
```

This was useful theorem-mining evidence, but not a theorem.

---

## 3. Census-universe bug discovered and fixed

The first version of the analyzer inferred its population from the **union of hit rows** in the standalone TSV.

That is logically unsafe. A hard prime which misses every stored shift produces no hit row and therefore disappears from the inferred universe.

At 10M there are six such omitted hard primes:

```text
118801
496609
532249
806521
2458369
8803369
```

All six happen to have `(47/p)=+1`, so the 822 negative-character count and its zero residual were numerically unchanged. That was luck, not a valid census construction.

The analyzer now builds the complete Mordell-hard universe independently by exact segmented prime sieve over the six hard residue classes modulo 840:

\[
\{1,121,169,289,361,529\}\pmod{840}.
\]

It can also recompute every fixed-shift signed-box hit directly with `--direct` rather than trusting a hit-only relation as the domain definition.

At 10M, direct recomputation gives:

- hard universe: `20,513`,
- hit-union population: `20,507`,
- silent all-miss omissions: `6`,
- negative-character k47 misses: `822`,
- residual after shift 39: `0`,
- zero mismatches against every stored hit row for shifts `3,7,11,15,19,23,27,31,35,39,43,47`.

Thus the old relation data were correct; the inferred-universe logic was not.

---

## 4. The 10M cross-shift candidate is refuted at 50M

Running the corrected analyzer directly through `50,000,000` gives

\[
\boxed{93,457}
\]

Mordell-hard primes and

\[
\boxed{3,524}
\]

negative-character `k=47` misses.

The earlier-corridor residual is

```text
start  3524
k=3    2251
k=7    1173
k=11    403
k=15    236
k=19    129
k=23     47
k=27     27
k=31      7
k=35      3
k=39      1
k=43      1
```

The surviving prime is

\[
\boxed{p=25,569,769}.
\]

It is prime, satisfies

\[
p\equiv169\pmod{840},
\qquad
\left(\frac{47}{p}\right)=-1,
\]

and misses every tested fixed shift

\[
3,7,11,15,19,23,27,31,35,39,43,47,51.
\]

It then **hits at `k=55`**. Therefore it is not an Erdős–Straus counterexample. It is a counterexample to the proposed cross-shift claim that failure through 39 forces a negative-character hit at 47.

For this prime,

\[
C_{47}=6,392,454=2\cdot3\cdot1,065,409.
\]

Its exact fixed-47 state is

```text
mask       0x755e0f55c6b
center_log 3
direction  11
residue    13 mod 47
```

This state was already one of the seven hardest 10M exact-state classes. The 50M extension shows that its apparent four-layer finite cover was not universal.

---

## 5. 50M exact-state picture

The 3,524 negative-character k47 misses realize

\[
\boxed{78/80}
\]

of the exact forced-6 negative-character miss states.

Their finite earlier-shift cover histogram is now

```text
1 shift      31 states
2 shifts     20 states
3 shifts      4 states
4 shifts     14 states
5 shifts      7 states
6 shifts      1 state
uncovered     1 state
```

The uncovered exact state is precisely

```text
mask       0x755e0f55c6b
center_log 3
direction  11
```

with 164 finite targets in that state class through 50M. The prime `25,569,769` survives every earlier configured shift in that class.

So neither the eleven-direction quotient nor the full k47 state alone determines an earlier hit universally.

---

## 6. Revised theorem target

The failed candidate has done useful work: it tells us exactly what information is still missing.

A universal cross-shift theorem cannot depend only on

- `(47/p)`,
- the one-packet representative direction, or
- the complete fixed-47 divisor-set state.

The next object must include **companion information**, because two primes can occupy the same exact k47 state while their neighboring integers

\[
C_k=P+\frac{k+1}{4},\qquad p=4P+1,
\]

factor differently enough to change earlier-shift coverage.

The new hard kernel is therefore the companion signature of state

\[
\boxed{(0x755e0f55c6b,3)}
\]

and especially the transition from the all-miss pattern through `k=51` to the first observed hit at `k=55` for `p=25,569,769`.

That is a stronger and safer next theorem-mining target than trying to resurrect the refuted 10M containment.

---

## 7. Reproduction

Complete direct census, with no hit-union universe assumption:

```sh
python3 research/erdos-straus/analyze_k47_negative_corridor.py \
  --direct --hi 10000000 --json

python3 research/erdos-straus/analyze_k47_negative_corridor.py \
  --direct --hi 50000000 --json
```

Cross-check an existing relation while independently rebuilding the full universe and hit relation:

```sh
python3 research/erdos-straus/analyze_k47_negative_corridor.py \
  standalone-hit-relations.tsv \
  --direct --hi 10000000 --json
```

The critical methodological rule is now explicit:

> **A hit-only relation may describe hits, but it may never define the census universe.**

Erdős–Straus remains open.
