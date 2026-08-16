# Finite decision bound for López Type A/B on the hard-prime domain

**Status:** proved elementary theorem  
**Date:** 2026-08-16  
**Depends on:** López Type A/B congruence characterizations; Mordell-hard residue skeleton  
**Claim boundary:** this proves that Type A/B existence is finitely decidable for each fixed prime. It does not prove that every prime has Type A or B, and it does not produce a counterexample to López or Erdős–Straus.

## 1. Why this matters

The López Type A/B conjecture is often phrased with unbounded positive parameters `d,n`. For a fixed prime `p`, however, those parameters cannot wander to arbitrary depth.

Write the Type A/B layer index as

```text
K = d n
```

and the associated modulus as

```text
m = 4 d n - 1 = 4K - 1.
```

López's exact prime characterizations are:

```text
Type A:  p == -4d  (mod 4dn-1)
Type B:  p == -n   (mod 4dn-1)
```

The divisibility itself forces an explicit upper bound on `K`.

The main result is:

### Theorem — complete hard-prime A/B decision ceiling

Let `p` be a Mordell-hard prime, so

```text
p mod 840 in {1,121,169,289,361,529}.
```

Then every Type A witness satisfies

```text
K = dn <= (p+3)/11,
```

and every Type B witness satisfies

```text
K = dn <= 3(p+1)/11.
```

Consequently

```text
K_complete(p) = floor(3(p+1)/11)
```

is a complete Type A/B decision bound on the Mordell-hard prime domain.

If a full Type A/B audit finds no witness through `K_complete(p)`, then there is no Type A or Type B witness at any larger layer either.

This converts the statement

```text
C_AB(p) = infinity
```

from an apparently infinite search assertion into a finite certificate for each fixed hard prime.

## 2. Hard-prime arithmetic used

Every Mordell-hard residue satisfies

```text
p == 1 (mod 24).
```

In particular

```text
p == 1 (mod 3)
p == 1 (mod 8)
```

and the six classes have

```text
p mod 5 in {1,4}
p mod 7 in {1,2,4}.
```

Only these elementary congruence facts are used below.

## 3. Type A bound

Suppose `p` has a Type A witness. Then

```text
4dn-1 divides p+4d.
```

Define the positive quotient

```text
s = (p+4d)/(4dn-1).
```

Since `p == 1 (mod 4)` and `4dn-1 == 3 (mod 4)`, one has

```text
s == 3 (mod 4).
```

Thus `s` is one of

```text
3,7,11,15,...
```

and the defining equation is

```text
p = s(4dn-1) - 4d.
```

Equivalently,

```text
p+s = 4d(ns-1).
```

### Case A1 — s >= 7

We claim directly that

```text
11dn <= p+3.
```

Indeed

```text
p+3-11dn
= dn(4s-11) - s - 4d + 3.
```

For `s>=7` and `d,n>=1`, the right side is nonnegative. Its smallest possible value occurs at the smallest parameters and is already positive at `s=7,d=n=1`.

Hence

```text
K = dn <= (p+3)/11.
```

### Case A2 — s = 3

Now

```text
p+3 = 4d(3n-1).
```

The hard-prime congruences exclude `n=1,2,3`:

- `n=1` would make `p+3` divisible by 8, but `p==1 (mod 8)` gives `p+3==4 (mod 8)`;
- `n=2` would make `p+3` divisible by 5, but hard primes are `1` or `4 mod 5`, so `p+3` is `4` or `2 mod 5`;
- `n=3` again makes `p+3` divisible by 8.

Therefore

```text
n >= 4.
```

Using `p+3=4d(3n-1)`,

```text
K = dn
  = n(p+3) / (4(3n-1)).
```

For `n>=4`,

```text
n / (4(3n-1)) <= 1/11,
```

because this is equivalent to `11n <= 12n-4`.

Thus again

```text
K <= (p+3)/11.
```

### Sharpness of the Type A coefficient

The bound is attained by a hard prime parameter family. For example

```text
p = 1009
d = 23
n = 4
s = 3
K = 92
m = 367
```

and

```text
p+4d = 1101 = 3*367.
```

Hence this is a Type A certificate with

```text
K = 92 = (1009+3)/11.
```

The coefficient `1/11` therefore cannot be improved using only a universal hard-prime parameter ceiling of this form.

## 4. Type B bound

Suppose `p` has a Type B witness. Then

```text
4dn-1 divides p+n.
```

Define

```text
s = (p+n)/(4dn-1) >= 1.
```

Then

```text
p+n = s(4dn-1)
```

or equivalently

```text
p+s = n(4ds-1).
```

### Case B1 — s = 1

We have

```text
p+1 = n(4d-1).
```

The hard-prime skeleton excludes the first two values of `d`:

- `d=1` gives `p == -1 (mod 3)`, contradicting `p==1 (mod 3)`;
- `d=2` gives `p == -1 (mod 7)`, but hard primes are only `1,2,4 mod 7`.

Therefore

```text
d >= 3.
```

Since

```text
K = dn = d(p+1)/(4d-1)
```

and `d/(4d-1)` decreases with `d`, its maximum for `d>=3` occurs at `d=3`. Hence

```text
K <= 3(p+1)/11.
```

### Case B2 — s >= 2

From

```text
p+n = s(4dn-1)
```

we obtain

```text
p+n >= 2(4dn-1),
```

so

```text
p+2 >= n(8d-1).
```

Therefore

```text
K = dn <= d(p+2)/(8d-1) <= (p+2)/7.
```

For every positive `p`,

```text
(p+2)/7 <= 3(p+1)/11.
```

Thus the same hard-prime Type B ceiling holds in both cases:

```text
K <= 3(p+1)/11.
```

### Sharpness of the Type B coefficient

The coefficient `3/11` is attained by hard-prime parameter data. For example

```text
p = 4201
d = 3
n = 382
s = 1
K = 1146
m = 4583
```

and

```text
p+n = 4583 = m.
```

Hence

```text
K = 1146 = 3(4201+1)/11.
```

Again, this shows that the universal parameter ceiling is sharp on the hard-prime skeleton.

## 5. Complete finite decision theorem

Combining the two bounds gives:

### Corollary — finite falsification certificate for a fixed hard prime

For a Mordell-hard prime `p`, define

```text
K_complete(p) = floor(3(p+1)/11).
```

Run a full Type A/B audit over every layer

```text
1 <= K <= K_complete(p),
```

including composite moduli `4K-1`.

If no Type A or Type B witness occurs in that finite interval, then no Type A or Type B witness exists for `p` at all.

Therefore such a prime would be a genuine counterexample to López's Type A/B all-primes conjecture, not merely a bounded model escape.

This does **not** imply that the same prime would be an Erdős–Straus counterexample. The complete Lane-I/general-first-denominator coordinate remains independent of Type A/B and may still produce an exact Erdős–Straus decomposition.

That distinction is precisely what the model-escape architecture is intended to test.

## 6. Broader p == 1 mod 24 bound

The same argument gives a slightly weaker bound before imposing the full six-class Mordell-hard skeleton.

For any prime

```text
p == 1 (mod 24),
```

one obtains

```text
Type A: K <= (p+3)/10
Type B: K <= 2(p+1)/7.
```

Therefore

```text
K_complete,24(p) = floor(2(p+1)/7)
```

is sufficient for a complete Type A/B decision on the entire `1 mod 24` prime domain.

The improvement from `2/7` to `3/11` on the Mordell-hard skeleton comes from excluding the Type-B extremal case `d=2,s=1` using the exact hard residue classes modulo 7.

## 7. Consequence for the current CBIS model-escape subsystem

The present bounded auditor is epistemically conservative: `AB_UNSEEN_THROUGH_K` means exactly what it says.

This theorem permits a second, stronger classification when the requested depth reaches the complete ceiling:

```text
K >= floor(3(p+1)/11)
```

for a Mordell-hard prime.

At that point, if no witness is found, the result is no longer merely

```text
AB_UNSEEN_THROUGH_K.
```

It can be certified as

```text
NO_TYPE_A_OR_B_WITNESS.
```

That stronger status should remain separate from ES letters and from the W/I/N/L production verdict.

## 8. Reproduction and regression

The accompanying verifier checks:

- the exact six hard residue classes and their mod-3, mod-5, mod-7, and mod-8 consequences;
- the excluded extremal Type-A cases;
- the excluded extremal Type-B cases;
- generated Type-A and Type-B parameter families against the proved ceilings;
- the sharp equality examples `p=1009` and `p=4201`;
- direct congruence verification of both examples.

Run:

```sh
python3 research/erdos-straus/verify_lopez_ab_finite_decision_bound.py --json
```

The theorem is elementary and range-free. The regression is not the proof; it protects the implementation and the stated constants.

Erdős–Straus remains open, and López Type A/B remains unrefuted unless an actual prime completes this finite audit with no Type A/B witness.