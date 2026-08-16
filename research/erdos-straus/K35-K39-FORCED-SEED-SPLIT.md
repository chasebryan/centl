# Forced-seed split of the conjugate `k=35` and `k=39` problems

**Status:** exact computer-assisted hard-prime reductions  
**Date:** 2026-08-16  
**Depends on:** `K35-TWO-TARGET-FILTER.md`, `K39-TWO-TARGET-FILTER.md`, `MORDELL-HARD-FORCED-SEED-LAW.md`  
**Machine certificate:** `classify_k35_k39_forced_seeds.py`  
**Independent finite regression:** `verify_k35_k39_forced_seeds.py`  
**Claim boundary:** these are range-free hard-prime state containments at the two fixed shifts. They do not prove Erdős–Straus.

## 1. Generic conjugacy is not hard-seed conjugacy

The generic fixed-shift problems at `k=35` and `k=39` share the abstract unit-group geometry

\[
C_{12}\times C_2
\]

and are related by the exact target-preserving conjugacy already proved in `K39-TWO-TARGET-FILTER.md`.

However, the hard-prime forced-seed law gives different mandatory factors:

\[
\boxed{3\mid C_{35}},
\qquad
\boxed{2\mid C_{39}}.
\]

These seeds occupy different quotient positions in the common coordinate model. Therefore the two **hard-prime** state problems are no longer identified by the generic target conjugacy.

## 2. `k=35`: forced factor 3 lies inside the hard subgroup

For `p=24m+1`,

\[
C_{35}=\frac{p+35}{4}=6m+9=3(2m+3).
\]

In the k=35 coordinate

\[
x=6^\varepsilon3^a\pmod{35},
\]

the forced factor is

\[
\boxed{3\leftrightarrow(0,1).}
\]

The hard center subgroup is `epsilon=0`, so the forced factor begins **inside** the hard subgroup.

Starting from this mandatory valuation occurrence and closing over all remaining unit directions gives

```text
total states          394
admissible states     194
hit states            130
miss states            64
```

The generic admissible miss table had 232 states. Thus

\[
\boxed{232\to64.}
\]

Minimizing additional outside-subgroup valuation units gives

```text
0 outside units   38 misses
2 outside units   26 misses
```

so every hard-prime k=35 miss has a forced-3 representative with at most two additional outside-H units.

The forced-3 pure-H closure has exactly 38 states, and all 38 miss.

## 3. `k=39`: forced factor 2 begins outside the hard subgroup

For `p=24m+1`,

\[
C_{39}=\frac{p+39}{4}=6m+10=2(3m+5).
\]

Using the k=39 coordinate

\[
x=14^\varepsilon28^a\pmod{39},
\]

the forced factor has coordinate

\[
\boxed{2\leftrightarrow(1,1).}
\]

The hard center subgroup is again `epsilon=0`, so this mandatory factor starts **outside** it.

The forced-2 closure contains

```text
total states          394
admissible states     196
hit states            160
miss states            36
```

Therefore

\[
\boxed{232\to36}
\]

for the admissible miss table.

The minimum number of additional outside-H units is

```text
1 outside unit   34 misses
3 outside units    2 misses
```

so every hard-prime k=39 miss has a forced-2 representative with at most three additional outside-H units.

## 4. Why the seeded problems split

The generic k35-to-k39 conjugacy acts on coordinates by

\[
(\varepsilon,a)\mapsto(\varepsilon,5a).
\]

It sends the k35 forced direction `(0,1)` to `(0,5)`, not to the actual k39 forced direction `(1,1)`.

Thus the conjugacy preserves the target geometry but **does not preserve the mandatory hard-prime seed**.

This explains why the generic closures share the same 1,298-state / 232-miss geometry while their natural hard-prime reductions differ sharply:

```text
                generic miss   forced-seed miss
k=35                 232              64
k=39                 232              36
```

The lesson is structural: target conjugacy alone is insufficient for comparing hard-prime fixed-shift problems. The mandatory factor seed is part of the mathematical data.

## 5. Independent finite regression

`verify_k35_k39_forced_seeds.py` independently generates Mordell-hard primes, checks the mandatory factors, consumes one forced valuation occurrence, rebuilds the remaining exact state from factorization, and compares against direct divisor-square target membership.

Through `100,000`:

```text
hard primes   273

k=35
  hits         47
  misses      226

k=39
  hits        147
  misses      126

mismatches      0
```

These are finite realization checks. The reduced closures themselves are range-free finite-group exhaustions from universally forced seeds.

## 6. Reproduction

```sh
python3 research/erdos-straus/classify_k35_k39_forced_seeds.py --json
python3 research/erdos-straus/verify_k35_k39_forced_seeds.py --limit 100000 --json
```

Erdős–Straus remains open. The result shows that hard-prime seed data can break an otherwise exact fixed-shift conjugacy and should be included in the canonical CBX state specification.
