# Exact two-target filter at the prime shift `k=59`

**Status:** exact computer-assisted finite-group classification  
**Date:** 2026-08-16  
**Depends on:** `FIXED-SHIFT-JACOBI-PARITY.md`, `ES-TWO-TARGET-DIVISOR-SQUARE.md`, `ES-BINARY-LANE-I-EQUIVALENCE.md`  
**Machine certificate:** `classify_k59_states.py`  
**Independent finite regression:** `verify_k59_structure.py`  
**Claim boundary:** this closes the fixed Lane-I shift `k=59`. It does not prove a universal finite shift ceiling and does not prove Erdős–Straus.

## 1. Exact cyclic model

Let

\[
C=\frac{p+59}{4}.
\]

Since 59 is prime,

\[
(\mathbb Z/59\mathbb Z)^\times\cong C_{58}.
\]

Use primitive root `2` and write `lambda(x)=log_2(x) mod 58`.

The Type-I divisor-square target is

\[
-4^{-1}\equiv44\pmod{59},
\]

with log

\[
\boxed{27}.
\]

Also `lambda(-1)=29`, so for center log `c`, Type II has log `c+29 mod 58`.

A valuation occurrence of log `a` gives the exact transition

\[
T_a(D,c)=\left(D+\{0,a,2a\},c+a\right).
\]

## 2. Exact finite closure

Closing the empty state under all 58 transition directions gives exactly

\[
\boxed{291,907}
\]

states.

The two exact target tests split them into

\[
\boxed{230,692\text{ hit states}}
\]

and

\[
\boxed{61,215\text{ combined-miss states}.}
\]

This is a range-free finite-group exhaustion theorem for fixed `k=59`.

## 3. Pure quadratic support

Even logs are quadratic residues. Closing only even directions gives

\[
\boxed{4,671}
\]

states, and every one misses because the Type-I target log `27` is odd while `c+29` is odd whenever the center is even.

Thus

\[
\boxed{4,671/4,671}
\]

pure-QR states are exact misses.

## 4. The four-packet ceiling breaks here

For each miss state, minimize the number of odd-log valuation units in a state-equivalent representative. The exact histogram is

```text
minimum NR units   miss states
0                   4,671
1                  19,014
2                  24,783
3                   9,808
4                   2,656
5                     283
```

Hence

\[
\boxed{\text{every fixed-59 miss state has a representative with at most five NR units}.}
\]

This is the first classified shift in the current 35,39,43,47,51,55,59 run where the minimum-core ceiling exceeds four. Therefore the earlier `<=4` phenomenon must not be promoted to a universal fixed-shift principle.

## 5. Character split

Center parity is the quadratic character modulo 59. Since Mordell-hard primes satisfy `p=1 mod 4`, reciprocity introduces no sign change, giving

\[
(-1)^c=\left(\frac{59}{p}\right).
\]

The exact miss table splits as

```text
(59/p)=+1   32,110
(59/p)=-1   29,105
```

Both character branches contain genuine fixed-shift misses.

## 6. No nontrivial scalar target symmetry

A scalar log automorphism `a -> ma mod 58` must fix both target log 27 and the `-1` translation 29. Because `gcd(27,58)=1`, fixing 27 forces

\[
m\equiv1\pmod{58}.
\]

Thus the scalar target-preserving automorphism group is trivial at `k=59`. The symmetry compression available at 43, 51, and 55 does not recur here in this form.

## 7. Independent regression

Through `100,000`, the independent divisor-box verifier gives

```text
hard primes     273
k=59 hits       117
k=59 misses     156
mismatches        0
```

During derivation, a separate direct signed-box census through `100,000,000` gave

```text
hard primes     179,468
k=59 hits       100,760
k=59 misses      78,708
mismatches            0
```

These are finite population checks. The theorem is the exact 291,907-state closure.

## 8. Corrected 100M corridor

Exactly 12 hard primes through 100M survive every classified shift through `k=55`.

At `k=59`:

```text
hits      10
misses     2
```

The two finite survivors are

\[
\boxed{8,803,369}
\]

and

\[
\boxed{90,108,841}.
\]

The first is captured at `k=63`; the second persists until `k=107` in the current finite corridor. These are theorem-mining facts only, not a universal shift bound.

## 9. Reproduction

```sh
python3 research/erdos-straus/classify_k59_states.py --json
python3 research/erdos-straus/verify_k59_structure.py --limit 100000 --json
```

The full miss table is emitted with `--table`.

Hard regression constants:

```text
total states             291,907
hit states               230,692
miss states               61,215
pure-QR states             4,671
pure-QR misses             4,671
Legendre split       {+1:32110, -1:29105}
minimum NR units     {0:4671, 1:19014, 2:24783, 3:9808, 4:2656, 5:283}
```

Erdős–Straus remains open. Fixed `k=59` is now completely classified; the corrected finite corridor has only two survivors beyond it through 100M.
