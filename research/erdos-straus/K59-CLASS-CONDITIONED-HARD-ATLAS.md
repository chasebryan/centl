# Class-conditioned hard-state atlas at `k=59`

**Status:** exact computer-assisted fixed-shift theorem  
**Date:** 2026-08-16  
**Depends on:** `K59-TWO-TARGET-FILTER.md`, `K59-FORCED3-HARD-REDUCTION.md`, `MORDELL-HARD-CLASS-CONDITIONED-SEED-LAW.md`  
**Machine certificate:** `classify_k59_class_conditioned_states.py`  
**Independent finite regression:** `verify_k59_class_conditioned_states.py`  
**Claim boundary:** this refines the fixed k=59 hard-prime obstruction by the exact residue class `p mod 840`. It does not provide a universal shift ceiling and does not prove Erdős–Straus.

## 1. The universal forced-3 closure is still too large

Every Mordell-hard prime satisfies

\[
3\mid C_{59}.
\]

The universal forced-3 theorem reduces the generic k=59 miss table from

\[
61,215
\]

to

\[
5,869
\]

hard-prime miss states.

But a Mordell-hard prime is not merely `1 mod 24`: it belongs to one of six exact classes modulo 840. The class-conditioned seed law therefore gives stronger mandatory factors.

## 2. Six hard classes, four distinct seeds

At k=59, the maximal class-conditioned seed is

\[
g_{59,h}=\gcd\!\left(210,\frac{h+59}{4}\right).
\]

For the six hard residue classes:

```text
p mod 840     maximal seed at k=59
1                     15
121                   15
169                    3
289                    3
361                  105
529                   21
```

Thus only four distinct exact seed closures are needed:

\[
\boxed{3,\ 15,\ 21,\ 105.}
\]

Their prime contents are

```text
3     = 3
15    = 3*5
21    = 3*7
105   = 3*5*7
```

All three seed primes have even base-2 logarithm modulo 59:

\[
\log_2 3=50,
\qquad
\log_2 5=6,
\qquad
\log_2 7=18.
\]

Hence every class seed is quadratic-residue support modulo 59 and does not itself flip the `(59/p)` character branch.

## 3. Exact class-seed closures

Starting from each mandatory seed and closing under all remaining factor directions gives:

```text
seed   total states   hit states   miss states
3          35,740        29,871        5,869
15          4,525         3,597          928
21          3,553         3,274          279
105           133           103           30
```

Every refined closure is an exact subset of the universal forced-3 closure, as it must be: the extra mandatory factors 5 and 7 merely specialize the already-valid hard-prime state system.

The compression is especially strong in the class

\[
p\equiv361\pmod{840},
\]

where the natural obstruction table has only

\[
\boxed{30}
\]

states.

This is a range-free class-conditioned containment, not a finite-prime extrapolation.

## 4. Minimum additional nonresidue complexity

For each seed closure, minimize the number of additional odd-log valuation units required after the mandatory seed has already been consumed.

The exact miss histograms are:

### Seed 3

```text
added NR units   miss states
0                    900
1                  2,263
2                  2,185
3                    458
4                     63
```

### Seed 15

```text
added NR units   miss states
0                    177
1                    420
2                    303
3                     28
```

### Seed 21

```text
added NR units   miss states
0                    148
1                     71
2                     55
3                      5
```

### Seed 105

```text
added NR units   miss states
0                     30
```

Thus the maximum minimum additional-NR cost contracts as

\[
4\to3\to3\to0
\]

when the seed is strengthened from `3` to `15`, `21`, and `105`.

For seed 105 every exact miss state has a pure-QR representative. This is a state-equivalence statement; it does not assert that every actual miss factorization itself contains no nonresidue prime factors.

## 5. Exact Legendre-branch split

The miss-state character branches are:

```text
seed       (59/p)=+1     (59/p)=-1
3              3,148          2,721
15               480            448
21               203             76
105               30              0
```

The last row gives a genuine fixed-shift theorem.

### Theorem — class-361 negative-character forced hit

Let `p` be a Mordell-hard prime with

\[
\boxed{p\equiv361\pmod{840}.}
\]

Then the maximal k=59 seed is

\[
\boxed{105=3\cdot5\cdot7.}
\]

The complete exact seed-105 miss closure contains no state with negative center parity. Therefore

\[
\boxed{
\left(\frac{59}{p}\right)=-1
\quad\Longrightarrow\quad
\text{the exact two-target shift }k=59\text{ hits}.}
\]

Equivalently, every fixed-k=59 miss in this hard residue class must satisfy

\[
\boxed{\left(\frac{59}{p}\right)=+1.}
\]

This implication is range-free. It is proved by exact finite-group closure after the class-conditioned arithmetic seed, not by observing primes below a numerical bound.

## 6. Pure quadratic-residue subclosures

Restricting all additional factor directions to even logs gives:

```text
seed   pure-QR states   pure-QR misses
3             900              900
15            177              177
21            148              148
105            30               30
```

Every pure-QR seed state misses both exact targets, consistent with the odd Type-I target at k=59.

The seed-105 result is particularly rigid: its entire miss table is already contained in the pure-QR subclosure.

## 7. Independent finite realization regression

`verify_k59_class_conditioned_states.py` independently:

1. generates Mordell-hard primes;
2. identifies `h=p mod 840`;
3. verifies divisibility by the exact maximal seed for that class;
4. factors `C59`;
5. consumes the full mandatory seed, not merely factor 3;
6. reconstructs the exact residual state;
7. compares the predicted hit/miss with direct divisor-square target membership.

Through `100,000` there are 273 hard primes, split as:

```text
p mod 840     hits     misses
1               19        26
121             22        28
169             12        31
289             13        32
361             23        17
529             28        22
```

Total:

```text
hits       117
misses     156
mismatches   0
```

The number of distinct realized states in that small finite regression is:

```text
h=1       44
h=121     49
h=169     43
h=289     45
h=361     35
h=529     50
```

These population counts are finite validation only. The class-conditioned closure and the class-361 character implication are range-free fixed-shift theorems.

## 8. Research consequence

The correct k=59 theorem-mining object is no longer one 5,869-state hard table. It is the six-class atlas

```text
h=1,121       -> seed-15 closure,   928 miss states
h=169,289     -> seed-3 closure,  5,869 miss states
h=361         -> seed-105 closure,   30 miss states
h=529         -> seed-21 closure,   279 miss states
```

Cross-shift work should preserve these class labels. In particular, the `h=361` branch has already lost one entire Legendre branch at k=59 before any neighboring-shift theorem is applied.

This suggests a systematic strategy: search other classified shifts for class-conditioned seeds that annihilate a character branch or collapse the miss geometry to a tiny finite family.

## 9. Reproduction

```sh
python3 research/erdos-straus/classify_k59_class_conditioned_states.py --json
python3 research/erdos-straus/verify_k59_class_conditioned_states.py \
  --limit 100000 --json
```

The full miss rows for every distinct seed closure are emitted with `--table`.

Erdős–Straus remains open. The result proves that exact Mordell-hard residue information can turn a thousands-state fixed-shift obstruction into a 30-state branch and, in one character sector, into a guaranteed hit.