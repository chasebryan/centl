# Square-root-width complete López Type A/B audit

**Status:** proved exact reparameterization  
**Date:** 2026-08-16  
**Depends on:** `LOPEZ-AB-FINITE-DECISION-BOUND.md`; López Type A/B congruence characterizations  
**Claim boundary:** this is a complete decision algorithm for Type A/B existence for a fixed odd prime. It does not prove López, disprove López, or prove Erdős–Straus.

## 1. Motivation

`LOPEZ-AB-FINITE-DECISION-BOUND.md` proves that the Type A/B question is finite for every fixed prime. A literal scan of all layers `K=dn` up to a linear ceiling is exact but computationally wasteful.

Both López families contain a hidden symmetry that collapses the complete search to a factor search over only a square-root-width interval of offsets `p+a`.

The result is useful for two distinct jobs:

1. deciding whether a fixed prime has any Type A/B witness at all;
2. recovering the true first Type A/B depth `C_AB(p)` without assuming a finite empirical cutoff.

## 2. Type A as a symmetric product equation

López Type A is

```text
p == -4d  (mod 4dn-1).
```

Let the positive quotient be `s`:

```text
p+4d = s(4dn-1).
```

Put

```text
u = 4d.
```

Then

```text
p = n u s - u - s.
```

For an odd prime `p`, reduction modulo 4 gives

```text
s == -p (mod 4).
```

Thus one of the two positive integers `(u,s)` is divisible by 4 and the other is congruent to `-p mod 4`.

Now define

```text
a = min(u,s)
b = max(u,s).
```

The equation is symmetric in `u,s`, so

```text
p+a = b(na-1).
```

Therefore

```text
r = na-1
```

is a divisor of `p+a`, with

```text
r == -1 (mod a),
n = (r+1)/a,
b = (p+a)/r.
```

Conversely, every divisor `r` of `p+a` satisfying these relations, together with the residue-pair condition

```text
{a,b} contains one value == 0 (mod 4)
and the other == -p (mod 4),
```

reconstructs an exact Type A witness.

### Finite offset bound

Because `a<=b` and `n>=1`,

```text
p = nab-a-b >= a^2-2a.
```

Hence

```text
(a-1)^2 <= p+1
```

and therefore

```text
A_A(p) = 1 + floor(sqrt(p+1))
```

is a complete Type A offset ceiling.

So Type A requires factoring only

```text
p+1, p+2, ..., p+A_A(p).
```

## 3. Type B as a symmetric product equation

López Type B is

```text
p == -n  (mod 4dn-1).
```

Let the positive quotient be `s`:

```text
p+n = s(4dn-1).
```

Then

```text
p = 4dns - n - s.
```

This equation is exactly symmetric in `n` and `s`.

Choose the canonical orientation

```text
a = min(n,s)
b = max(n,s).
```

Then

```text
p+a = b(4da-1).
```

Therefore

```text
r = 4da-1
```

is a divisor of `p+a` satisfying

```text
r == -1 (mod 4a),
d = (r+1)/(4a),
b = (p+a)/r.
```

Conversely every such divisor reconstructs a Type B witness.

The `n <-> s` symmetry means that choosing the smaller member as `n=a` loses no existence information. It also cannot increase the Type B layer `K=dn`, so this canonical orientation is sufficient when computing the first Type B depth.

### Finite offset bound

Since `a<=b` and `d>=1`,

```text
p = 4dab-a-b >= 4a^2-2a.
```

Thus

```text
4a^2-2a <= p.
```

The complete Type B offset ceiling is

```text
A_B(p) = floor((1 + sqrt(1+4p))/4).
```

So the Type B search is even narrower than Type A.

## 4. Complete algorithm

For a fixed odd prime `p`:

1. compute `A_A = 1 + floor(sqrt(p+1))`;
2. factor every integer in the contiguous interval `p+1` through `p+A_A`;
3. for each offset `a`, enumerate divisors of `p+a`;
4. apply the exact Type A divisor condition `r == -1 mod a` and residue-pair orientation;
5. for `a<=A_B`, apply the exact Type B divisor condition `r == -1 mod 4a`;
6. reconstruct every certificate with exact integer arithmetic;
7. choose the smallest reconstructed `K=dn` across Type A and canonical Type B certificates.

If neither search produces a certificate, then the fixed prime has no Type A or Type B solution.

No empirical `K` cutoff is involved.

## 5. Why the interval can be factored efficiently

The numbers requiring factorization are consecutive:

```text
p+1, p+2, ..., p+A_A.
```

The accompanying implementation uses segmented interval factorization:

- sieve ordinary primes only through `sqrt(p+A_A)`;
- for each small prime, visit the offsets divisible by that prime;
- divide out complete valuations in place;
- any residual value greater than one is the final prime factor.

This avoids separately trial-dividing every offset from scratch.

The search width is `O(sqrt(p))`; the factorization work is performed over that single interval rather than over a linear number of Type A/B layers.

## 6. Canonical regression: p = 9,658,489

For

```text
p = 9,658,489
```

we have

```text
A_A = 3108
A_B = 1554.
```

The complete square-root auditor recovers the known first Type B witness

```text
d = 69
n = 38
quotient = 921
K = dn = 2622
m = 4K-1 = 10487.
```

Indeed

```text
p+n = 9,658,527 = 921 * 10,487.
```

Thus the exact first Type A/B depth is recovered while factoring only the first 3,108 offsets above `p`.

The same complete audit also finds Type A certificates for this prime, but the earliest Type A layer lies deeper than the Type B record.

## 7. López's classical exceptional Type A examples

The square-root audit also reproduces the structural distinction in López's paper:

### p = 193

```text
Type A certificates: none
first Type B K: 4
```

### p = 2521

```text
Type A certificates: none
first Type B K: 22
```

Thus the complete algorithm does not silently force Type A where López records its absence; it recovers Type B as the complementary family.

## 8. Relation to the finite linear ceiling

The linear theorem and the square-root theorem answer different questions.

`LOPEZ-AB-FINITE-DECISION-BOUND.md` proves an explicit upper ceiling on every possible parameter layer in the hard domain. It is a useful mathematical certificate that the search cannot continue forever.

The present theorem gives a much better computational coordinate. It does not scan those layers. It reconstructs every possible certificate from divisors of a square-root-width offset interval.

Therefore the preferred complete audit is now:

```text
finite-decision theorem for epistemic completeness
+
square-root factor search for execution.
```

## 9. Consequence for model-escape research

A bounded result such as

```text
AB_UNSEEN_THROUGH_K
```

remains useful for comparing model depth against the general Erdős–Straus coordinate.

But when the research target is specifically the López conjecture, the complete square-root auditor should be used instead.

A prime for which this complete audit returns no Type A and no Type B certificate would be a genuine López counterexample candidate immediately, subject to independent reproduction and certificate review.

The general Lane-I/first-denominator observer remains independent. Such a prime could still satisfy Erdős–Straus outside Type A/B.

## 10. Reproduction

Run a complete audit with

```sh
python3 research/erdos-straus/lopez_ab_complete_sqrt_audit.py 9658489 --json
```

The verifier cross-checks the square-root reconstruction against the older direct layer scan on a finite prime corpus and pins the known examples above.

Erdős–Straus remains open. López Type A/B remains unrefuted until an actual prime completes this exact audit with an empty certificate set.