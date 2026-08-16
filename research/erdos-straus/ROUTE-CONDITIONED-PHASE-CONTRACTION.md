# Route-conditioned phase contraction

**Status:** exact necessary survivor-phase refinement inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Verifier:** `verify_route_conditioned_phase_contraction.py`  
**Depends on:** realized k19 pair survivor normal form, k31 survivor normal form, and landed phase-volume contraction through k55.  
**Claim boundary:** exact modular necessary conditions only. These contractions are candidate progress coordinates, not termination measures, not a closed decomposition method, and not an Erdős–Straus proof.

## 1. Why ancestry must enter the phase coordinate

The landed phase-volume theorem through k55 uses the range-free filters at k39, k43, k47, k51, and k55.

Two earlier exact modules contribute additional phase information:

- k31 gives a general h169 phase restriction through the QR31 support theorem;
- on the two realized k19 pair routes, the exact survivor normal form forces the k19 center into QR19.

The realized route residue conditions also fix one of the later phase coordinates:

- Route A fixes `t mod17`, so the k51 phase is no longer free;
- Route B fixes `t mod47`, so the k47 phase is no longer free.

Therefore the correct phase-volume coordinate is ancestry-sensitive.

## 2. General h169 k31 phase filter

Write

`C31 = 10D`,

with

`D = 5 + 21t`.

The exact k31 theorem states

`k31 misses iff every rational prime factor q of D is a nonzero quadratic residue modulo31`.

Hence a k31 miss necessarily has

`D mod31 in QR31`,

where

`QR31 = {1,2,4,5,7,8,9,10,14,16,18,19,20,25,28}`.

Since `21` is invertible modulo31, this is equivalent to exactly fifteen allowed t-phases:

`S31 = {0,2,6,7,8,9,11,12,14,15,19,22,27,28,29} mod31`.

Thus k31 alone absorbs the complementary sixteen phases.

This is only a necessary phase shadow of the stronger factorwise QR31 support theorem. A phase in S31 need not realize a k31 miss.

## 3. General phase-volume refinement through k55

Combine k31 with the already-landed necessary survivor filters:

```text
shift   modulus   survivor phases
k31       31            15
k39       13             9
k43       43            40
k47       47            34
k51       17            13
k55       11             7
```

The six moduli are pairwise coprime.

The complete phase modulus is therefore

`M31..55 = 31*13*43*47*17*11 = 152,304,581`.

Simultaneous survival at all six shifts requires t to lie in

`15*9*40*34*13*7 = 16,707,600`

CRT classes modulo M31..55.

So the raw class ratio is

`16,707,600 / 152,304,581`,

which reduces by gcd221 to

`75,600 / 689,161`.

Numerically,

`V31..55 ~= 0.10969860453507961`.

Thus these phase conditions alone exclude approximately

`89.03013954649204%`

of periodic h169 t-space.

Again, this is exact modular contraction, not a density estimate and not termination.

## 4. Realized pair-route k19 phase filter

The two realized pair routes into k19 are

```text
Route A: q17+q23 -> k19
Route B: q23+q47 -> k19.
```

For either route, the complete exact k19 survivor closure has misses only at the nine quadratic-residue centers modulo19:

`QR19 = {1,4,5,6,7,9,11,16,17}`.

Since

`p = 169 + 840t = 17 + 4t mod19`,

an actual pair-route k19 miss requires

`S19 = {0,2,7,8,11,14,15,16,17} mod19`.

This contains the two BARE defect phases:

- Route A BARE center6 corresponds to `t=2 mod19`;
- Route B BARE center11 corresponds to `t=8 mod19`.

The phase condition does not distinguish BARE from FULL_QR. It records only the necessary center coordinate.

## 5. Route A conditional contraction

Route A has

`C19 = 391R`,

so

`t = 199 mod391`.

In particular

```text
t = 12 mod17
t = 15 mod23.
```

The landed k51 survivor set modulo17 contains12, so Route A is not killed automatically at k51. Instead the k51 phase coordinate is already fixed by ancestry and contributes no additional conditional fraction.

The remaining independent phase restrictions on a Route-A branch surviving through k55 are

```text
k19 mod19 :  9/19
k31 mod31 : 15/31
k39 mod13 :  9/13
k43 mod43 : 40/43
k47 mod47 : 34/47
k55 mod11 :  7/11
```

All six moduli are coprime to391 and to one another.

Therefore, conditional on the exact Route-A ancestry, simultaneous phase survival occupies

`11,566,800`

classes out of

`170,222,767`

classes over the independent phase modulus.

The exact conditional fraction is

`V_A = 11,566,800 / 170,222,767`

or approximately

`0.06795095746504931`.

So the proved phase restrictions remove approximately

`93.20490425349507%`

of Route-A conditional phase space before the full k27/k31/k35 support grammars are intersected.

## 6. Route B conditional contraction

Route B has

`C19 = 1081R`,

so

`t = 705 mod1081`.

In particular

```text
t = 15 mod23
t = 0 mod47.
```

The landed k47 survivor set contains phase0, so Route B is not killed automatically at k47. The k47 phase coordinate is instead fixed by ancestry and contributes no extra conditional fraction.

The remaining independent phase filters are

```text
k19 mod19 :  9/19
k31 mod31 : 15/31
k39 mod13 :  9/13
k43 mod43 : 40/43
k51 mod17 : 13/17
k55 mod11 :  7/11
```

All six moduli are coprime to1081 and to one another.

Hence conditional Route-B survival occupies

`340,200`

classes out of

`4,736,149`

classes over the independent phase modulus.

The fraction is

`V_B = 340,200 / 4,736,149`

or approximately

`0.07183051039990507`.

Thus the exact phase filters remove approximately

`92.81694896000949%`

of Route-B conditional phase space.

## 7. What this changes in the candidate machine

The phase coordinate is no longer adequately represented by one global scalar.

The exact state should distinguish at least

```text
phase_volume_global
phase_volume_route_A
phase_volume_route_B
```

or, more fundamentally, retain the underlying allowed CRT phase class rather than only the volume.

The volume is telemetry and a candidate progress coordinate. The actual CRT class is proof-bearing arithmetic state.

This distinction aligns with the in-draft Bryan Entanglement Cross principle:

- exact phase class tells what arithmetic states remain possible;
- a future directional annotation may describe the contraction as excavation;
- the BEC layer does not create the contraction and does not grant pruning beyond the theorem.

## 8. Interaction with support separation

A separate active theorem proves that the odd support reservoirs across the k19..k55 companion ladder are non-recyclable.

The two results are orthogonal:

`phase restriction` controls the allowed parameter class of t;

`support separation` controls how prime factors may be allocated among companion cofactors.

The next proof object should therefore retain both:

`state = (route, CRT_phase, k27_mode, k31_mode, k35_branch, separated_support, affine_data)`.

The immediate theorem target is to eliminate formal product-state combinations that are not arithmetically realizable.
