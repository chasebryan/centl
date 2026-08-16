# Hard-prime forced-2 reduction at `k=63`

**Status:** exact computer-assisted hard-prime state reduction  
**Date:** 2026-08-16  
**Depends on:** `K63-TWO-TARGET-FILTER.md`  
**Machine certificate:** `classify_k63_forced2_states.py`  
**Independent finite regression:** `verify_k63_forced2_structure.py`  
**Claim boundary:** every Mordell-hard prime state at fixed `k=63` lies in the reduced closure proved here. The closure is a hard-prime superset, not a prime-realization theorem. Erdős–Straus remains open.

## 1. Universal factor 2

Every Mordell-hard prime has

\[
p=24m+1.
\]

At shift `k=63`,

\[
C_{63}=\frac{p+63}{4}
=\frac{24m+64}{4}
=6m+16
=2(3m+8).
\]

Therefore

\[
\boxed{2\mid C_{63}}
\]

for every Mordell-hard prime.

This is a range-free arithmetic restriction.

## 2. The forced factor lies outside the hard center subgroup

The fixed-63 unit group is

\[
(\mathbb Z/63\mathbb Z)^\times\cong C_6\times C_6,
\]

with coordinates

\[
x=29^a10^b\pmod{63}.
\]

`K63-TWO-TARGET-FILTER.md` proves that every hard-prime center lies in

\[
H=\{(a,b):a,b\text{ even}\}\cong C_3\times C_3.
\]

The forced factor `2` has coordinate

\[
\boxed{2\leftrightarrow(1,2).}
\]

Its first coordinate is odd, so

\[
\boxed{2\notin H.}
\]

This differs qualitatively from the k=59 forced factor 3, which lies inside the quadratic-residue subgroup there.

One mandatory occurrence of factor 2 therefore seeds the exact state at

\[
S_2=T_{(1,2)}(\{(0,0)\},(0,0)).
\]

Every actual hard-prime factorization is obtained from this state by applying the ordinary exact transitions for the remaining valuation occurrences.

## 3. Exact reduced closure

The generic fixed-63 closure contains

\[
6,389
\]

total states, of which 1,844 have an admissible hard center and 684 are misses.

Starting after the mandatory factor 2 gives only

\[
\boxed{1,740\text{ total states}.}
\]

Among these,

\[
\boxed{421\text{ have an admissible hard center},}
\]

split into

\[
\boxed{334\text{ hits}}
\]

and

\[
\boxed{87\text{ misses}.}
\]

Thus the hard-prime obstruction table contracts from

\[
684\longrightarrow87.
\]

### Theorem — forced-2 hard containment

For every Mordell-hard prime `p`, the exact fixed-63 state of `C63` belongs to the 1,740-state forced-2 closure, and every actual fixed-63 miss belongs to its 87-state admissible miss table.

No converse realization claim is made.

## 4. Added outside-subgroup complexity falls to three

The forced factor already contributes one direction outside `H`. Starting from that mandatory seed, minimize the number of **additional** valuation units outside `H` required to reach each admissible miss state.

The exact histogram is

```text
minimum added outside-H units   miss states
1                                   38
2                                   18
3                                   31
```

Hence

\[
\boxed{\text{every hard-prime k=63 miss state has a forced-2 representative needing at most three additional outside-H units}.}
\]

There is no zero-cost row because the seed center begins outside `H`: additional quotient support is mandatory to return the final center to the hard subgroup.

The quotient

\[
G/H\cong C_2\times C_2
\]

explains why one, two, or three added outside classes can compensate the seeded quotient class.

## 5. Exact reduced center distribution

The 87 reduced miss states occupy all nine possible hard centers in `H`, with counts

```text
center (0,0)   23
center (0,2)    5
center (0,4)    5
center (2,0)    5
center (2,2)    5
center (2,4)   23
center (4,0)    5
center (4,2)   11
center (4,4)    5
```

So the reduction does not collapse the problem to a single hard center. It compresses the factorization-state geometry inside every center class.

## 6. Independent finite regression

`verify_k63_forced2_structure.py` independently generates Mordell-hard primes, verifies `2|C63`, consumes one mandatory factor 2, reconstructs the remaining state from the actual factorization, and compares the reduced classifier with the direct divisor-square targets.

Through `100,000`:

```text
hard primes     273
k=63 hits        54
k=63 misses     219
mismatches        0
```

These finite counts check realization. The hard-state containment theorem comes from the universal identity `C63=2(3m+8)` plus exact closure from the forced seed.

## 7. Reproduction

```sh
python3 research/erdos-straus/classify_k63_forced2_states.py --json
python3 research/erdos-straus/verify_k63_forced2_structure.py --limit 100000 --json
```

The complete 87-state reduced miss table is emitted with `--table`.

Hard regression constants:

```text
forced factor                         2
forced coordinate                 (1,2)
forced seed divisor-set size          3
reduced total states               1,740
reduced admissible states            421
reduced hits                         334
reduced misses                        87
minimum added outside-H     {1:38, 2:18, 3:31}
```

Erdős–Straus remains open. The forced factor removes most of the generic fixed-63 obstruction geometry before any finite prime bound is used.
