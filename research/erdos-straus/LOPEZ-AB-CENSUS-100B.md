# López Type A/B complete finite census through 100 billion

**Status:** exact finite census  
**Date:** 2026-08-16  
**Domain:** Mordell-hard primes `p <= 100,000,000,000`  
**Depends on:** `LOPEZ-AB-FINITE-DECISION-BOUND.md`, `LOPEZ-AB-SQRT-COMPLETE-AUDIT.md`  
**Claim boundary:** finite evidence only. This is not a proof of López Type A/B completeness and not a proof of Erdős–Straus.

## 1. Result

The exact census contains

```text
128,671,219
```

Mordell-hard primes through

```text
100,000,000,000.
```

Every one of those primes has at least one López Type A or Type B witness.

Thus the finite result is

```text
hard primes checked      128,671,219
Type A/B captured        128,671,219
complete Type A/B misses           0
finite capture rate          100 percent
```

This does **not** imply universal Type A/B completeness. The complete square-root auditor is now available precisely so that any future bounded survivor can be decided prime-by-prime without extrapolating from this census.

## 2. New deepest observed Type A/B witness

The previous finite record was

```text
p = 9,658,489
C_AB = 2,622
Type B
```

The 100-billion census moves the record to

```text
p = 45,894,591,961
C_AB = 13,234
Type A
```

An exact first certificate is

```text
d = 26
n = 509
K = d*n = 13,234
m = 4K-1 = 52,935
quotient = 866,999
```

The defining Type A divisibility is exact:

```text
p + 4d
= 45,894,591,961 + 104
= 45,894,592,065
= 866,999 * 52,935.
```

Therefore

```text
p == -4d (mod 4dn-1)
```

at `K=13,234`.

The direct layer audit finds no Type A/B witness at any smaller `K`. The independent square-root complete auditor reconstructs the same first depth.

## 3. High-depth record chain

The important finite record progression is now:

```text
p                 first C_AB
9,658,489              2,622
362,385,409            2,850
740,856,601            3,612
1,135,844,089          7,138
10,671,101,281         7,945
37,941,547,081         9,315
45,894,591,961        13,234
```

The jump from `3,612` to `7,138` is especially important: it is the first point in this census where a `K=5,000` Type A/B research grade ceases to be complete even as a finite observational grade.

The later records show that `C_AB` continues to have a nontrivial tail. A fixed `K=5,000` or even `K=10,000` must therefore never be described as a universal Type A/B depth bound.

## 4. The first K=5,000 bounded model escapes

Between one and ten billion, four hard primes survive every Type A/B layer through `K=5,000`:

```text
1,135,844,089
2,621,555,161
2,802,389,209
2,844,772,561
```

The complete square-root auditor resolves all four:

```text
p                 exact C_AB
1,135,844,089          7,138
2,621,555,161          5,600
2,802,389,209          5,472
2,844,772,561          5,020
```

So these are genuine **bounded model escapes** from the `K=5,000` observation grade, but none is a López counterexample.

This is the cleanest demonstration so far of why the CBIS model-escape language must distinguish

```text
AB_UNSEEN_THROUGH_K
```

from

```text
NO_TYPE_A_OR_B_WITNESS.
```

The first statement occurred four times below ten billion at `K=5,000`. The second statement occurred zero times after complete audit.

## 5. Later record survivors

The same procedure was continued with the current record itself as the bounded survival threshold.

### 10 to 20 billion

Two primes survived through `K=7,138`:

```text
10,671,101,281
17,605,186,369
```

Complete audit gives

```text
10,671,101,281 -> C_AB = 7,945
17,605,186,369 -> C_AB = 7,548
```

### 30 to 40 billion

One prime survived through `K=7,945`:

```text
37,941,547,081
```

Complete audit gives

```text
C_AB = 9,315.
```

### 40 to 50 billion

One prime survived through `K=9,315`:

```text
45,894,591,961
```

Complete audit gives the present record

```text
C_AB = 13,234.
```

### 50 to 100 billion

No hard prime survives through `K=13,234`.

The largest interval maxima observed there were:

```text
50 to 60B    5,425
60 to 70B    8,890
70 to 80B    7,695
80 to 90B    4,284
90 to 100B   8,514
```

None challenges the current record.

## 6. Exact hard-prime counts by census interval

The segmented prime census produced:

```text
interval                         hard primes
<= 100,000,000                      179,468
100,000,001 to 1,000,000,000      1,408,113
1,000,000,001 to 10,000,000,000  12,628,126
10B to 20B                         13,345,271
20B to 30B                         13,056,376
30B to 40B                         12,873,998
40B to 50B                         12,739,129
50B to 60B                         12,635,546
60B to 70B                         12,552,626
70B to 80B                         12,477,405
80B to 90B                         12,415,862
90B to 100B                        12,359,299
---------------------------------------------
total                             128,671,219
```

The prime generator is an exact segmented sieve restricted after sieving to the six Mordell-hard residue classes modulo 840.

## 7. Two independent coordinates

Every high-depth candidate was checked in two mathematically equivalent but operationally independent coordinates.

### Direct layer coordinate

For each layer `K`, set

```text
m = 4K-1.
```

For every divisor `s` of `K`, test the exact residues

```text
Type B: p == -s  (mod m)
Type A: p == -4s (mod m).
```

This is the same full bounded A/B scan used by the CBIS model-risk auditor, including composite moduli.

### Complete square-root coordinate

`lopez_ab_complete_sqrt_audit.py` reconstructs every possible Type A certificate and every canonical Type B certificate from divisors of the short interval immediately above `p`.

This coordinate has no empirical `K` cutoff.

The record candidates agree in both coordinates.

## 8. Reproduction

The bounded census tool is

```text
research/erdos-straus/lopez_ab_bounded_census.py
```

For example, the original `K=5,000` escape interval can be reproduced with

```sh
python3 research/erdos-straus/lopez_ab_bounded_census.py \
  --lo 1000000001 \
  --hi 10000000000 \
  --k-max 5000 \
  --complete-survivors \
  --json
```

A direct complete audit of the present record is

```sh
python3 research/erdos-straus/lopez_ab_complete_sqrt_audit.py \
  45894591961 --all --json
```

The 100-billion census was run in exact contiguous chunks. Chunking changes only memory/runtime behavior; every integer in the stated interval belongs to exactly one chunk.

## 9. Research consequence

The current evidence says two things at once.

First, López Type A/B remains extremely strong: no complete miss was found among more than 128 million Mordell-hard primes through 100 billion.

Second, bounded Type A/B depth is less stable than the earlier 50-million census suggested. The observed record has grown from `2,622` to `13,234`, and multiple primes now provably escape `K=5,000` before being recovered deeper.

Therefore Type A/B should continue to be treated exactly as the present CBX/CBIS architecture treats it:

```text
valuable structural model
not a kernel axiom
bounded misses are not falsifications
complete square-root misses would be falsification candidates
```

The primary Erdős–Straus search remains independent in the complete first-denominator/Lane-I coordinate.

López Type A/B remains unrefuted. Erdős–Straus remains open.