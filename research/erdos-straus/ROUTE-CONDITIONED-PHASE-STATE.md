# Route-conditioned phase and mode state through k55

**Status:** exact framework-state refinement  
**Date:** 2026-08-16  
**Verifier:** `verify_route_conditioned_phase_state.py`  
**Depends on:** landed route-conditioned k19/k31 phase contraction, ten-cofactor odd-support separation, and Route-B k47 survivor normal form  
**Claim boundary:** exact necessary route-conditioned phase/mode restrictions. This is not a termination theorem, not a closed decomposition method, and not an Erdős–Straus proof.

## 1. Start from the stronger landed phase envelope

The landed route-conditioned phase theorem already incorporates:

- pair-route k19 QR19 center support;
- k31 QR31 support;
- k39, k43, k47, k51, and k55 exact phase filters.

It gives the exact necessary envelopes

```text
Route A:
11,566,800 / 170,222,767
≈ 0.06795095746504931

Route B:
4,422,600 / 61,569,937
= 340,200 / 4,736,149
≈ 0.07183051039990507.
```

This module does not replace those contractions. It adds the **route-local endpoint state** that a scalar phase fraction cannot represent.

## 2. Route A fixes a live k51 endpoint family

Route A is

`t = 199 + 391u`,

so

`t = 12 mod17`.

That phase is not absorbed by k51. It fixes

`C51 = 25 mod51`.

Rebuilding the exact seed-5 k51 closure gives

```text
1403 total states
14 miss states at center 25.
```

Thus Route A does not carry a free k51 phase coordinate after route selection. It carries a **fixed 14-state endpoint family**.

That family is now the unresolved Route-A local-mode target.

## 3. Route B fixes a two-mode k47 endpoint

Route B is

`t = 705 + 1081u`,

so

`t = 0 mod47`.

That phase is not absorbed by k47. It fixes

`C47 = 7 mod47`.

The landed Route-B normal form reduces the fixed endpoint to exactly

`k47_mode = THIN | FULL_QR`,

with

`J=B+1`

and

`k47 miss <=> every prime factor of J is QR mod47`.

Thus Route B has already been compressed from a phase to a symbolic two-mode state.

## 4. THIN forces parity

The exact THIN grammar permits, after deleting residue-1 factor occurrences of J, only

`{9}`

or

`{3,3}`

modulo47.

Rational prime2 has residue2 modulo47, which is not allowed in THIN.

Therefore

`THIN => 2 does not divide J`.

Since

`J = 9 + 35t`,

we have

`J odd <=> t even`.

Hence

`Route-B THIN => t even`.

Because

`t = 705 + 1081u`

with both coefficients odd,

`t even <=> u odd`.

Therefore

`Route-B THIN => u odd`.

## 5. Strong THIN phase/parity envelope

The landed Route-B phase theorem leaves

`4,422,600`

classes modulo

`61,569,937`.

All independent phase moduli there are odd. Parity is therefore an independent coordinate.

The THIN parity condition leaves at most

`4,422,600`

classes modulo

`123,139,874 = 2*61,569,937`.

Hence the necessary THIN phase/parity envelope is

`4,422,600 / 123,139,874`

which reduces to

`170,100 / 4,736,149`

and is approximately

`0.035915255199952534`.

So before using the rest of the THIN factor grammar, the proved phase-plus-parity conditions alone remove about96.41% of Route-B parameter space.

This remains a necessary modular envelope, not a density theorem and not a termination measure.

## 6. Survivor mode switches an exact support edge

The ten-cofactor support theorem gives

`gcd(D,J)=gcd(2,t+1)`.

Therefore Route B splits exactly.

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

Thus the k47 survivor mode is coupled to the exact 2-adic support graph.

This is more than annotation: selecting THIN switches the D-J overlap edge off.

## 7. Correct route-local machine state

### Route A

```text
route = A
CRT phase in the landed 11,566,800 / 170,222,767 envelope
k51 center = 25 mod51
k51 local state in a 14-miss endpoint family
odd support separated through k55
```

### Route B

```text
route = B
CRT phase in the landed 4,422,600 / 61,569,937 envelope
k47_mode = THIN | FULL_QR
J = B+1
B support = QR23
J support = QR47
odd support separated through k55

THIN => u odd => gcd(D,J)=1
u even / t odd => FULL_QR and gcd(D,J)=2.
```

## 8. Next theorem target

The route asymmetry is now explicit.

Route B has a two-mode k47 normal form with parity/support coupling.

Route A still has14 exact k51 endpoint misses.

The next high-value theorem target is therefore:

> compress the Route-A center-25 k51 endpoint family into a small exact support grammar or behavioral normal form, then couple it to the ten-cofactor support graph.

If that closes cleanly, both realized routes will carry symbolic route-local modes rather than raw endpoint-state families.

Erdős–Straus remains open.
