# Exact two-target filter at the composite shift `k=55`

**Status:** exact computer-assisted finite-group classification  
**Date:** 2026-08-16  
**Depends on:** `FIXED-SHIFT-JACOBI-PARITY.md`, `ES-TWO-TARGET-DIVISOR-SQUARE.md`, `ES-BINARY-LANE-I-EQUIVALENCE.md`  
**Machine certificate:** `classify_k55_states.py`  
**Independent finite regression:** `verify_k55_structure.py`  
**Claim boundary:** this closes the fixed Lane-I shift `k=55`. It does not prove a universal finite shift ceiling and does not prove Erdős–Straus.

## 1. Group and hard-prime center

Let `p` be Mordell-hard and put

\[
C=\frac{p+55}{4}.
\]

The unit group is

\[
(\mathbb Z/55\mathbb Z)^\times\cong C_{20}\times C_2.
\]

Use coordinates

\[
x=21^\varepsilon 2^a\pmod{55},
\qquad \varepsilon\in C_2,\ a\in C_{20}.
\]

The six Mordell-hard residue classes modulo 840 are all `1` or `4 mod 5`, so

\[
\left(\frac5p\right)=+1.
\]

Because `4` is a square and `55=0 mod 5`, the shifted center `C` is also a quadratic residue modulo 5. In the chosen coordinate this is exactly

\[
\boxed{a\equiv0\pmod2.}
\]

Thus the hard-prime center lies in the index-two subgroup

\[
H=\{(\varepsilon,a):a\text{ even}\}.
\]

## 2. Exact targets

The Type-I divisor-square target is

\[
-4^{-1}\equiv41\pmod{55},
\]

with coordinate

\[
\boxed{(1,8).}
\]

Also

\[
-1=(1,10).
\]

For an admissible center `(epsilon,c)`, the Type-II target `-C` is obtained by adding `(1,10)`.

A prime-valuation occurrence in coordinate `g` gives the exact transition

\[
T_g(D,c)=\left(D+\{0,g,2g\},c+g\right).
\]

Closing the empty state under all 40 unit directions exhausts arbitrary factorization residue states.

## 3. Exact finite closure

The least closed state space contains

\[
\boxed{20,082}
\]

states. Exactly

\[
\boxed{9,558}
\]

have hard-prime-admissible center in `H`.

Applying the two targets gives

\[
\boxed{7,239\text{ hit states}}
\]

and

\[
\boxed{2,319\text{ combined-miss states}.}
\]

Therefore the emitted 2,319-state table is the complete fixed-`k=55` obstruction geometry. This is a range-free finite-group closure theorem.

## 4. The hard subgroup does not trivially decide the shift

Closing only directions inside `H` produces

\[
\boxed{710}
\]

states. Unlike `k=51`, both fixed-55 targets can lie inside `H`, so pure-H support does not force failure.

Among the 710 pure-H states,

\[
\boxed{211\text{ miss}.}
\]

The other

\[
\boxed{2,108}
\]

miss states require support outside `H`.

## 5. Four-unit outside-H cutoff

For each exact state, minimize

\[
(\text{valuation units outside }H,\ \text{total valuation units}).
\]

Among the 2,319 misses the exact distribution is

\[
\begin{array}{c|r}
\text{minimum outside-H units}&\text{miss states}\\
\hline
0&211\\
2&1962\\
4&146
\end{array}
\]

Hence

\[
\boxed{\text{every fixed-55 miss state has a state-equivalent representative with at most four outside-H valuation units}.}
\]

Only even costs occur because an admissible center must finish back inside the index-two subgroup `H`.

## 6. The remaining character is `(11/p)`

Modulo 11, the coordinate `2` has order 10 and `21=-1`. For an admissible center the `a` coordinate is even, so the quadratic character modulo 11 is determined exactly by `epsilon`.

Since every Mordell-hard prime has `p=1 mod 4`, quadratic reciprocity gives

\[
\boxed{(-1)^\varepsilon=\left(\frac{11}{p}\right).}
\]

The 2,319 exact miss states split as

\[
\boxed{1,381\text{ with }(11/p)=+1}
\]

and

\[
\boxed{938\text{ with }(11/p)=-1.}
\]

Both character branches therefore contain genuine fixed-shift failure geometry.

## 7. Target-preserving symmetry

The involution

\[
(\varepsilon,a)\mapsto(\varepsilon,11a)
\]

fixes the Type-I coordinate `(1,8)` and the `-1` translation `(1,10)`, so it preserves the complete miss set.

The 2,319 misses collapse to

\[
\boxed{1,436\text{ symmetry orbits},}
\]

consisting of

\[
\boxed{553\text{ fixed states}}
\]

and

\[
\boxed{883\text{ two-state orbits}.}
\]

## 8. Independent regression

`verify_k55_structure.py` independently builds the divisor residue box of `C^2` directly modulo 55 and compares it with the closed state classifier.

Through `100,000`:

```text
hard primes     273
k=55 hits       108
k=55 misses     165
mismatches        0
```

During derivation an independent direct signed-box census through `100,000,000` gave

```text
hard primes     179,468
k=55 hits        98,721
k=55 misses      80,747
mismatches            0
```

The finite 100M character outcomes were

```text
(11/p)=+1 : 29,836 hits, 59,504 misses
(11/p)=-1 : 68,885 hits, 21,243 misses
```

These population counts are finite evidence. The theorem is the exact finite-group closure above.

## 9. Corrected 100M corridor

Exactly 22 hard primes through 100M survive all classified shifts through `k=51`.

Every one of those 22 satisfies

\[
\boxed{(11/p)=+1.}
\]

At `k=55`:

```text
hits      10
misses    12
```

and all 12 remaining misses still lie in the `(11/p)=+1` branch.

This is a strong cross-shift selection signal, but it is a finite observation only. It does not imply a universal prior-corridor exclusion of the negative character branch without a separate proof.

## 10. Reproduction

```sh
python3 research/erdos-straus/classify_k55_states.py --json
python3 research/erdos-straus/verify_k55_structure.py --limit 100000 --json
```

The complete miss table is emitted by

```sh
python3 research/erdos-straus/classify_k55_states.py --json --table
```

Hard regression constants are

```text
total states                 20,082
admissible states             9,558
hit states                    7,239
miss states                   2,319
pure-H states                   710
pure-H misses                   211
nonpure misses                2,108
symmetry orbits               1,436
Legendre(11/p) split    {+1:1381, -1:938}
minimum outside-H      {0:211, 2:1962, 4:146}
```

Erdős–Straus remains open. Fixed `k=55` is now completely classified; the corrected corridor moves next to `k=59`.
