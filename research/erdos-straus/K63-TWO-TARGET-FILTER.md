# Exact two-target filter at the composite shift `k=63`

**Status:** exact computer-assisted finite-group classification  
**Date:** 2026-08-16  
**Machine certificate:** `classify_k63_states.py`  
**Independent finite regression:** `verify_k63_structure.py`  
**Claim boundary:** this closes the fixed Lane-I shift `k=63`. It does not prove a universal finite shift ceiling and does not prove Erdős–Straus.

## 1. Hard-center compression

Let

\[
C=\frac{p+63}{4}.
\]

By CRT,

\[
(\mathbb Z/63\mathbb Z)^\times\cong C_6\times C_6.
\]

Use generators `29` and `10`, so

\[
x=29^a10^b\pmod{63},\qquad a,b\in C_6.
\]

Every Mordell-hard prime satisfies `p = 1 mod 3`. Also its residue modulo 7 is one of `1,2,4`, hence a quadratic residue modulo 7. Since 4 is a square, the shifted center `C` is constrained to even exponent in both cyclic coordinates:

\[
\boxed{a\equiv b\equiv0\pmod2.}
\]

Thus the hard-prime center lies in

\[
\boxed{H\cong C_3\times C_3,}
\]

a nine-element subgroup of the 36-element unit group.

## 2. Exact targets

The Type-I target is

\[
-4^{-1}\equiv47\pmod{63}
\]

with coordinate

\[
\boxed{(1,5).}
\]

Also

\[
-1=(3,3).
\]

For a hard center `(a,b)` with both entries even, the Type-II target `-C` is obtained by adding `(3,3)` and therefore lies in the odd/odd quotient class.

A valuation occurrence in coordinate `g` again gives the exact transition

\[
T_g(D,c)=\left(D+\{0,g,2g\},c+g\right).
\]

## 3. Exact finite closure

Closing the empty state under all 36 unit directions gives

\[
\boxed{6,389}
\]

states. Of these,

\[
\boxed{1,844}
\]

have admissible hard center in `H`.

The two-target test yields

\[
\boxed{1,160\text{ hit states}}
\]

and

\[
\boxed{684\text{ combined-miss states}.}
\]

This is a range-free exact fixed-shift classification.

## 4. Pure-H support is universally dead at 63

Closing only directions inside the nine-element hard subgroup gives exactly

\[
\boxed{22}
\]

states. Both targets live outside `H`, so all 22 pure-H states miss:

\[
\boxed{22/22.}
\]

The remaining 662 miss states use outside-H support.

## 5. Outside-H core size

For each miss state, minimize the number of valuation units whose direction lies outside `H`. The exact histogram is

```text
minimum outside-H units   miss states
0                           22
2                          222
3                          206
4                          234
```

Thus

\[
\boxed{\text{every fixed-63 miss state has a state-equivalent representative using at most four outside-H units}.}
\]

The appearance of cost 3 is natural because the quotient `G/H` is `C2 x C2`: three distinct nonzero quotient classes can sum to zero.

## 6. Independent regression

Through `100,000`, the independent divisor-box verifier gives

```text
hard primes     273
k=63 hits        54
k=63 misses     219
mismatches        0
```

A separate direct signed-box census through `100,000,000` gave

```text
hard primes     179,468
k=63 hits        66,506
k=63 misses     112,962
mismatches             0
```

These population counts are finite checks. The theorem is the 6,389-state exact closure.

## 7. Corrected two-prime 100M tail

After all classified shifts through `k=59`, exactly two hard primes remain in the corrected 100M corridor:

\[
8,803,369,\qquad90,108,841.
\]

At `k=63`:

- `90,108,841` hits;
- `8,803,369` misses.

The latter is the unique corrected 100M corridor survivor after `k=63` and first hits at `k=107` among the currently scanned admissible shifts.

This finite first-hit fact is not a universal shift bound.

## 8. Reproduction

```sh
python3 research/erdos-straus/classify_k63_states.py --json
python3 research/erdos-straus/verify_k63_structure.py --limit 100000 --json
```

Hard regression constants:

```text
total states                 6,389
admissible states            1,844
hit states                   1,160
miss states                    684
pure-H states                   22
pure-H misses                   22
nonpure misses                 662
minimum outside-H       {0:22, 2:222, 3:206, 4:234}
```

Erdős–Straus remains open. Fixed `k=63` is completely classified; the corrected 100M corridor now has one survivor beyond it.
