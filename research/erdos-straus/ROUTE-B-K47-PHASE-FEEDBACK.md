# Route-B later-phase feedback into k47

**Status:** exact cross-shift dependency module inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Verifier:** `verify_route_b_k47_phase_feedback.py`  
**Depends on:** `ROUTE-B-K47-SURVIVOR-NORMAL-FORM.md`, route-conditioned phase state, and the landed k55 phase theorem.  
**Claim boundary:** exact necessary restrictions on Route-B k47 survival. Not a termination theorem, not a closed decomposition method, and not an Erdős–Straus proof.

## 1. Route-B k47 coordinate

On realized Route B,

`C47 = 6J`,

with

`J = 9 + 35t`.

The landed exact theorem says

`k47 misses iff every rational prime factor of J is a nonzero quadratic residue modulo47`.

Conditional on a miss, the exact modes are

`THIN | FULL_QR`.

THIN has the exact factor-occurrence grammar: after deleting every prime-factor occurrence congruent to1 modulo47, the remaining occurrence tuple is exactly

`(9,)`

or

`(3,3)`.

## 2. tau11=1 is an exact k47 killer

Modulo11,

`J = 9 + 2t`.

Therefore

`11 | J <=> t = 1 mod11`.

Quadratic reciprocity gives

`(11/47) = -1`.

So rational prime11 is a quadratic nonresidue modulo47. If `tau11=1`, then J contains prime11, contradicting the exact QR47 support condition required by a k47 miss.

Hence

`Route B + tau11=1 -> k47 hits`.

The standalone k55 theorem permits tau11=1, so this strictly refines the later phase envelope.

## 3. Route-B k55 phase refinement

The landed k55 survivor set is

`S11 = {0,1,2,3,4,8,9}`.

Simultaneous Route-B k47/k55 survival therefore requires

`S11^B = {0,2,3,4,8,9}`.

The Route-B conditional phase count contracts from

`4,422,600 / 61,569,937`

to

`3,790,800 / 61,569,937`.

The latter reduces by gcd13 to

`291,600 / 4,736,149`.

This is exact modular contraction, not a prime-density estimate.

## 4. tau17=8 forces FULL_QR at k47

Modulo17,

`J = 9 + t`.

Therefore

`17 | J <=> t = 8 mod17`.

The rational prime17 is a quadratic residue modulo47:

`(17/47)=+1`.

So factor17 is compatible with a k47 miss. But residue17 modulo47 is not one of the THIN non-1 residues `{3,9}`.

Therefore

`Route B + tau17=8 + k47 miss -> k47 mode FULL_QR`.

The standalone k51 phase theorem permits tau17=8, so this is a genuine mode refinement rather than a redundant excluded phase.

## 5. Route-B ancestry form

Route B has

`t = 705 + 1081u`.

Modulo11,

`t = 1 + 3u`,

so

`tau11=1 <=> u=0 mod11`.

Thus

`Route-B k47 survival -> u != 0 mod11`.

Modulo17,

`t = 8 + 10u`,

so

`tau17=8 <=> u=0 mod17`.

Thus

`u=0 mod17 + k47 miss -> FULL_QR47`.

## 6. 3-adic THIN refinement

Since

`J = 9 + 35t`,

we have

`3 | J <=> t = 0 mod3`

and

`9 | J <=> t = 0 mod9`.

Rational prime3 contributes residue3 modulo47.

If `tau9=0` and k47 is THIN, prime3 occurs at least twice. The exact THIN occurrence grammar therefore forces the non-1 occurrence tuple to be exactly

`(3,3)`.

Consequently:

- `v3(J)=2`;
- every prime factor of `J/9` is1 modulo47;
- `27 | J` is impossible in THIN.

Solving `27 | J` gives

`t = 9 mod27`.

Hence

`Route B + k47 THIN + t=9 mod27 -> contradiction`.

This tau27 refinement is recorded for theorem mining but is not yet promoted into the main phase state, which currently retains tau9.

## 7. Machine consequence

The dependency engine can add

```text
if route == B and tau11 == 1:
    contradiction with k47 miss

if route == B and tau17 == 8:
    k47_mode = FULL_QR
```

and, if tau27 is later introduced,

```text
if route == B and k47_mode == THIN and tau27 == 9:
    contradiction.
```

These rules should run before factor enumeration of J.

## 8. Bryan Entanglement Cross / BREC boundary

A later phase deleting a k47 survivor phase is a natural backward/downward directional annotation, while the forced FULL_QR mode is a constructive state refinement.

Those labels remain optional telemetry. The factor divisibility and exact k47 survivor theorem are the sole sources of mathematical pruning permission.

## 9. Next target

Compile tau11 and tau17 feedback into the exact propagator, then intersect them with the existing k27 phase selectors. The most valuable cases are assignments that simultaneously force a strict k27 mode and FULL_QR47 or produce an exact contradiction across the two shifts.