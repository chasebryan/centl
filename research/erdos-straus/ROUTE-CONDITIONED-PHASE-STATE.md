# Route-conditioned phase state through k55

**Status:** exact framework-state refinement  
**Date:** 2026-08-16  
**Verifier:** `verify_route_conditioned_phase_state.py`  
**Depends on:** landed h169 phase contraction through k55, ten-cofactor odd-support separation, and Route-B k47 survivor normal form  
**Claim boundary:** exact necessary phase/state restrictions on the two realized h169 routes. This is not a termination theorem, not a closed decomposition method, and not an Erdős–Straus proof.

## 1. Why global phase volume must be conditioned on ancestry

The landed h169 phase-volume theorem uses five exact filters:

```text
k39 :  9 / 13 phases survive
k43 : 40 / 43
k47 : 34 / 47
k51 : 13 / 17
k55 :  7 / 11.
```

Their moduli are pairwise coprime, so for unrestricted h169 the product is exact.

The realized k19 routes are not unrestricted h169 progressions, however. Each route already fixes one of those phase moduli:

- Route A contains the prime17 in its route modulus;
- Route B contains the prime47 in its route modulus.

Therefore the candidate framework should use **route-conditioned phase state**, not blindly multiply every global filter again after the route has been selected.

## 2. Route A fixes the k51 phase

Route A is

`t = 199 + 391u`,

with `391=17*23`.

Hence

`t = 12 mod17`

for every Route-A state.

Phase12 is a surviving k51 phase. Its exact h169 k51 center is

`C51 = 25 mod51`,

and the landed k51 closure contains14 miss states at that center.

Thus k51 supplies **no additional phase-volume contraction** after conditioning on Route A. It instead leaves a fixed 14-state local target for future compression.

For the remaining phase moduli

`13,43,47,11`,

we have

`gcd(391,m)=1`.

Therefore `u -> 199+391u` is a bijection modulo each m, and the survivor counts are unchanged.

The exact Route-A phase modulus is

`M_A = 13*43*47*11 = 289003`.

The exact number of surviving u classes is

`N_A = 9*40*34*7 = 85680`.

So, relative to Route A,

`V_A = 85680 / 289003`

which is approximately

`0.2964675107178818`.

The named phase filters exclude

`203323 / 289003`

of Route-A u-space, approximately70.3532489%.

## 3. Route B fixes the k47 phase

Route B is

`t = 705 + 1081u`,

with `1081=23*47`.

Hence

`t = 0 mod47`

for every Route-B state.

Phase0 is a surviving k47 phase. The landed Route-B theorem sharpens that fixed phase much further:

```text
k47 miss
  <=> every q|J is QR mod47,

J=B+1,

k47_mode = THIN | FULL_QR.
```

Thus k47 supplies **no additional phase-volume contraction** after conditioning on Route B. It supplies an exact two-mode survivor state instead.

For the remaining phase moduli

`13,43,17,11`,

we have

`gcd(1081,m)=1`.

The exact Route-B phase modulus is

`M_B = 13*43*17*11 = 104533`.

The exact number of surviving u classes is

`N_B = 9*40*13*7 = 32760`.

So, relative to Route B,

`V_B = 32760 / 104533 = 2520 / 8041`

approximately

`0.31339385648551177`.

The named phase filters exclude approximately68.6606143% of Route-B u-space.

## 4. THIN couples mode to parity

The Route-B THIN grammar allows, after deleting residue-1 prime-factor occurrences of J, only

`{9}`

or

`{3,3}`

modulo47.

The rational prime2 has residue2 modulo47. Although2 is a quadratic residue modulo47, it is not permitted by the THIN grammar.

Therefore

`THIN => 2 does not divide J`.

But

`J = 9 + 35t`,

so

`J is odd <=> t is even`.

Hence

`Route-B THIN => t even`.

Since

`t = 705 + 1081u`

and both705 and1081 are odd,

`t even <=> u odd`.

Therefore

`Route-B THIN => u odd`.

Parity is independent of the four odd residual phase moduli, so the THIN branch occupies at most

`32760`

classes modulo

`2*M_B = 209066`.

Its necessary phase fraction is

`32760 / 209066 = 1260 / 8041`

approximately

`0.15669692824275588`.

This is only the phase/parity envelope. The full THIN factor grammar is substantially stronger.

## 5. Mode couples to the exact 2-adic support seam

The ten-cofactor theorem gives

`gcd(D,J)=gcd(2,t+1)`.

Therefore Route B splits exactly:

### t odd

```text
J even
D even
gcd(D,J)=2
THIN impossible
k47 survivor mode = FULL_QR.
```

### t even

```text
J odd
D odd
gcd(D,J)=1
k47 survivor mode = THIN or FULL_QR.
```

This is the first direct coupling between an exact survivor mode and the global support-overlap graph.

The mode is not decorative metadata. It changes which exact 2-adic edge exists in the companion state.

## 6. Correct route-conditioned framework state

The local machine should therefore carry different coordinates on the two routes.

### Route A

```text
route = A
phase_u mod 289003 in 85680 necessary classes
k51 center = 25 mod51
k51 local miss state in a 14-state endpoint family
odd support separated through k55
```

### Route B

```text
route = B
phase_u mod 104533 in 32760 necessary classes
k47_mode = THIN | FULL_QR
J = B+1
B support = QR23
J support = QR47
odd support separated through k55

if THIN:
    u odd
    gcd(D,J)=1

if u even / t odd:
    k47_mode = FULL_QR
    gcd(D,J)=2
```

This is strictly more faithful than a single global phase-volume scalar after route selection.

## 7. Next theorem target

The asymmetry now points to a precise next attack.

Route B has been compressed from a fixed k47 phase to two exact modes.

Route A still has a fixed k51 phase with14 exact miss states.

The highest-value next target is therefore:

> compress the Route-A center-25 k51 endpoint family into an exact support grammar or a small behavioral normal form, then couple that mode to the ten-cofactor overlap graph exactly as Route B was coupled at k47.

If successful, both realized routes will carry route-local symbolic modes rather than coarse fixed-shift state sets.

Erdős–Straus remains open.
