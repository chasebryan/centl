# Class-conditioned residual coupling on the Mordell-hard branches

**Status:** proved elementary cross-shift theorem  
**Date:** 2026-08-16  
**Depends on:** `MORDELL-HARD-CLASS-CONDITIONED-SEED-LAW.md`, `CLASS-CONDITIONED-CHARACTER-ANNIHILATION.md`, `K19-TWO-TARGET-FILTER.md`  
**Claim boundary:** this theorem couples selected class-conditioned fixed-shift companions by exact linear and gcd identities. It does not prove that one of the named shifts must hit and does not prove Erdős–Straus.

## 1. Purpose

The class-conditioned seed theorem and character atlas give exact information at individual fixed shifts. The remaining proof problem is cross-shift compatibility.

For one hard residue class

```text
p = 840r + h
```

the companion at an admissible shift `k` is

```text
C_k = (p+k)/4 = 210r + (h+k)/4.
```

After dividing by the maximal class-conditioned seed

```text
g(k,h) = gcd(210,(h+k)/4),
```

the residual is an affine linear form in `r`.

The selected character-annihilation shifts therefore do not have independent factorizations. Their residuals satisfy tiny integer linear relations, which force exact gcd restrictions.

## 2. Class h = 121: shifts 19 and 47

Let

```text
p = 840r + 121.
```

At `k=19`, the class seed is `35`:

```text
C_19 = 210r + 35 = 35A,
A = 6r + 1.
```

At `k=47`, the class seed is `42`:

```text
C_47 = 210r + 42 = 42B,
B = 5r + 1.
```

The two residuals satisfy

```text
5A - 6B = -1.
```

Therefore

```text
gcd(A,B) = 1.
```

### Consequence

No rational prime can divide both the seed-stripped `k=19` and `k=47` companions on this hard class.

This is particularly relevant because the existing exact `k=19` theorem on `h=121` says that a combined `k=19` miss forces every prime factor of `C_19` outside the mandatory seed to lie on the quadratic-residue side modulo 19, while the class-conditioned `k=47` theorem says a `k=47` survivor must have positive 47-character.

The present theorem does not make those two conditions contradictory. It proves that their residual rational-prime resources are disjoint.

## 3. Class h = 169: shifts 11 and 31

Let

```text
p = 840r + 169.
```

The class seeds at `11` and `31` are `15` and `10`:

```text
C_11 = 210r + 45 = 15A,
A = 14r + 3,

C_31 = 210r + 50 = 10B,
B = 21r + 5.
```

The residuals satisfy

```text
2B - 3A = 1.
```

Hence

```text
gcd(A,B) = 1.
```

Thus a prime in this hard class that survives both fixed shifts must realize the two exact miss structures using disjoint residual rational-prime support.

The character atlas additionally forces

```text
(p/11) = +1
(p/31) = +1
```

for such a simultaneous survivor.

## 4. Class h = 529: shifts 11 and 31

Let

```text
p = 840r + 529.
```

The class seeds are `15` and `70`:

```text
C_11 = 210r + 135 = 15A,
A = 14r + 9,

C_31 = 210r + 140 = 70B,
B = 3r + 2.
```

Now

```text
14B - 3A = 1.
```

Therefore

```text
gcd(A,B) = 1.
```

Any simultaneous `k=11` and `k=31` survivor on this class must again allocate the two residual factorization states to disjoint rational-prime supports, while satisfying

```text
(p/11) = (p/31) = +1.
```

## 5. Class h = 361: shifts 31 and 59

Let

```text
p = 840r + 361.
```

At `k=31`, the maximal class seed is `14`; at `k=59`, it is `105`:

```text
C_31 = 210r + 98 = 14A,
A = 15r + 7,

C_59 = 210r + 105 = 105B,
B = 2r + 1.
```

The residuals obey

```text
15B - 2A = 1.
```

Hence

```text
gcd(A,B) = 1.
```

The `k=31` negative-character branch is not annihilated on this class; the exact atlas retains a real negative-character miss state. The `k=59` theorem does annihilate its negative branch, so every simultaneous survivor must satisfy

```text
(p/59) = +1,
```

but no analogous `(p/31)=+1` assertion is made here.

## 6. Class h = 289: the 11,31,47 residual triple

This is the strongest three-shift branch.

Let

```text
p = 840r + 289.
```

The class-conditioned seeds are

```text
k=11 -> 15
k=31 -> 10
k=47 -> 42.
```

Write

```text
C_11 = 210r + 75 = 15A,
A = 14r + 5,

C_31 = 210r + 80 = 10B,
B = 21r + 8,

C_47 = 210r + 84 = 42D,
D = 5r + 2.
```

### The 11-31 edge

```text
2B - 3A = 1,
```

so

```text
gcd(A,B) = 1.
```

### The 11-47 edge

```text
14D - 5A = 3.
```

Therefore

```text
gcd(A,D) divides 3.
```

Moreover

```text
A == D == 0 (mod 3)
```

holds exactly when

```text
r == 2 (mod 3).
```

Hence

```text
gcd(A,D) = 3   if r == 2 (mod 3),
gcd(A,D) = 1   otherwise.
```

### The 31-47 edge

```text
21D - 5B = 2.
```

Therefore

```text
gcd(B,D) divides 2.
```

Both are even exactly when `r` is even. Hence

```text
gcd(B,D) = 2   if r is even,
gcd(B,D) = 1   if r is odd.
```

### Triple-support theorem

The seed-stripped residual support graph on `(A,B,D)` has no unrestricted edge:

```text
A ---- no edge ---- B
|                    |
3 only              2 only
|                    |
D -------------------
```

More precisely:

- `A` and `B` are always coprime;
- `A` and `D` can share only the prime `3`, and only for `r==2 mod3`;
- `B` and `D` can share only the prime `2`, and only for even `r`.

Every rational prime other than `2` and `3` can therefore divide at most one of the three residuals.

A simultaneous survivor at `k=11,31,47` must additionally satisfy the exact character restrictions

```text
(p/11) = +1
(p/31) = +1
(p/47) = +1.
```

Again, those character conditions alone are CRT-compatible. The new content is that the finite-state obstructions imposing them must be realized on an almost-disjoint residual support triple tied together by the displayed linear identities.

## 7. Cross-class summary

The selected class-conditioned residual couplings are:

```text
hard class   shifts       seed-stripped residual relation       overlap
121          19,47        5A - 6B = -1                          none
169          11,31        2B - 3A = 1                           none
289          11,31        2B - 3A = 1                           none
289          11,47        14D - 5A = 3                          prime 3 only
289          31,47        21D - 5B = 2                          prime 2 only
361          31,59        15B - 2A = 1                          none
529          11,31        14B - 3A = 1                          none
```

These are identities in the free parameter `r`, not finite-census observations.

## 8. Relation to the six-companion wheel

The universal six-companion wheel already proves nearly disjoint prime support after removing the maximal seed common to all six hard classes.

The present theorem conditions further on the exact residue class `h mod840` and strips the stronger class seed. This yields smaller residuals and, on the named branches, sharper pairwise relations tailored to the exact shifts whose negative-character miss branches have been eliminated.

The two results therefore serve different levels of the proof search:

```text
six-wheel theorem
- class-independent support coupling across a complete 24-period block

class residual theorem
- stronger class-specific coupling among the exact character-critical shifts
```

## 9. What remains

This theorem does not yet close a hard class. Distinct rational primes can still populate the coprime residuals independently.

The next theorem target is narrower:

```text
Can the exact miss-state packet requirements at two or three character-critical shifts
be simultaneously realized when their rational-prime supports are forced to be disjoint
and their residual values satisfy the listed linear equations?
```

For `h=289`, this is now a three-state compatibility problem with only possible shared-prime channels `2` and `3`.

For `h=121`, the exact factor-support theorem at `k=19` gives an additional asymmetric constraint that may make the coprime `(19,47)` pair especially useful.

## 10. Reproduction

Run

```sh
python3 research/erdos-straus/verify_class_residual_coupling.py --max-r 100000 --json
```

The verifier checks the companion factorizations, class seeds, all displayed linear identities, all exact gcd formulas, and the conditional `2` and `3` overlap rules.

Erdős–Straus remains open. The theorem supplies an exact class-conditioned coupling invariant for the next simultaneous-obstruction attack.