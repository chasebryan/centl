# Hard-prime forced-2 reduction at `k=55`

**Status:** exact computer-assisted hard-prime state reduction  
**Date:** 2026-08-16  
**Depends on:** `K55-TWO-TARGET-FILTER.md`  
**Machine certificate:** `classify_k55_forced2_states.py`  
**Independent finite regression:** `verify_k55_forced2_structure.py`  
**Claim boundary:** every Mordell-hard prime state at fixed `k=55` lies in the reduced closure proved here. The closure is a hard-prime superset, not a prime-realization theorem. Erdős–Straus remains open.

## 1. Universal factor 2

Write every Mordell-hard prime as

\[
p=24m+1.
\]

Then

\[
C_{55}=\frac{p+55}{4}
=\frac{24m+56}{4}
=6m+14
=2(3m+7).
\]

Therefore

\[
\boxed{2\mid C_{55}}
\]

for every Mordell-hard prime.

## 2. The forced factor starts outside the hard subgroup

The fixed-55 coordinates are

\[
(\mathbb Z/55\mathbb Z)^\times\cong C_{20}\times C_2,
\qquad
x=21^\varepsilon2^a.
\]

The hard-prime center subgroup from `K55-TWO-TARGET-FILTER.md` is

\[
H=\{(\varepsilon,a):a\text{ even}\},
\]

the quadratic-residue subgroup modulo 5.

The forced factor `2` has coordinate

\[
\boxed{(0,1),}
\]

so it lies outside `H`. One mandatory occurrence therefore seeds the state with a nontrivial quotient character before any remaining factors are allowed.

Every actual hard-prime factorization is obtained from this seed by applying the ordinary exact valuation transitions for the remaining factor occurrences.

## 3. Exact reduced closure

The generic fixed-55 closure contains

```text
total states        20,082
admissible states    9,558
miss states          2,319
```

After consuming the universal factor 2, the exact closure contains only

\[
\boxed{4,051\text{ total states}.}
\]

Among these,

\[
\boxed{1,990\text{ have an admissible hard center},}
\]

with

\[
\boxed{1,676\text{ hits}}
\]

and

\[
\boxed{314\text{ misses}.}
\]

Thus the admissible obstruction table contracts from

\[
2,319\longrightarrow314.
\]

### Theorem — forced-2 hard containment

For every Mordell-hard prime `p`, the exact fixed-55 state of `C55` lies in the 4,051-state forced-2 closure, and every actual fixed-55 miss lies in the 314-state admissible miss table.

The reverse realization statement is not asserted.

## 4. Only one or three additional outside units are needed

Because the mandatory factor 2 starts outside the index-two hard subgroup, the remaining factorization must contain an odd amount of outside-subgroup parity in order for the final center to return to `H`.

Minimizing the number of **additional** outside-H valuation units gives exactly

```text
minimum added outside-H units   miss states
1                                  283
3                                   31
```

Hence

\[
\boxed{\text{every hard-prime k=55 miss state has a forced-2 representative requiring at most three additional outside-H units}.}
\]

The absence of costs 0 and 2 is forced by the quotient parity.

## 5. Remaining `(11/p)` split

The fixed-55 hard subgroup condition consumes the mod-5 quadratic character, while the second coordinate still records the mod-11 character. The reduced 314 miss states split as

\[
\boxed{198\text{ with }(11/p)=+1}
\]

and

\[
\boxed{116\text{ with }(11/p)=-1.}
\]

Both branches remain possible in the exact hard-prime superset.

## 6. Independent finite regression

`verify_k55_forced2_structure.py` independently generates Mordell-hard primes, verifies `2|C55`, consumes one mandatory factor 2, reconstructs the reduced state from the actual remaining factorization, and compares it with direct divisor-square target membership.

Through `100,000` the fixed-55 outcomes are

```text
hard primes     273
k=55 hits       108
k=55 misses     165
mismatches        0
```

The finite regression checks realization inside the range-free reduced closure.

## 7. Reproduction

```sh
python3 research/erdos-straus/classify_k55_forced2_states.py --json
python3 research/erdos-straus/verify_k55_forced2_structure.py --limit 100000 --json
```

The complete 314-state reduced miss table is emitted with `--table`.

Hard regression constants:

```text
forced factor                         2
forced coordinate                 (0,1)
forced seed divisor-set size          3
reduced total states               4,051
reduced admissible states          1,990
reduced hits                       1,676
reduced misses                       314
Legendre(11/p) split       {+1:198, -1:116}
minimum added outside-H       {1:283, 3:31}
```

Erdős–Straus remains open. The hard-prime seed removes most of the generic fixed-55 obstruction geometry before any prime range is considered.
