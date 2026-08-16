# Periodic route valuation ladder

**Status:** exact arithmetic theorem  
**Date:** 2026-08-16  
**Verifier:** `verify_periodic_route_valuation_ladder.py`  
**Depends on:** companion identity `C_k=(p+k)/4`, character-to-companion routing, periodic route-scope correction  
**Claim boundary:** this theorem guarantees routed-factor valuation events, not Lane-I hits. It does not give a universal shift ceiling and does not prove Erdős-Straus.

## 1. A routed factor does not appear once

Suppose an odd prime `q` divides one admissible companion

`C_k0 = (p+k0)/4`,

with

`k0 = 3 mod4`.

Write

`C_k0 = q M`.

Every shift

`k_n = k0 + 4 q n`

lies in the same route class modulo `4q`. Its companion is

`C_{k_n}`

`= (p+k0+4qn)/4`

`= C_k0 + qn`

`= q(M+n)`.

Therefore

> a routed prime factor generates an exact arithmetic ladder of companions whose q-stripped residual increases by one at each repeated route representative.

This identity is range-free.

## 2. Exact q-adic lift theorem

For every integer `e>=1`,

`q^e | C_{k_n}`

if and only if

`q^(e-1) | M+n`.

Equivalently,

`n = -M mod q^(e-1)`.

Hence among every complete block of `q^(e-1)` consecutive representatives in the route class, exactly one has q-adic valuation at least `e`.

In particular:

- every routed q has exactly one `q^2` lift among the next `q` route representatives;
- exactly one `q^3` lift occurs among the next `q^2` representatives;
- more generally the valuation ladder is deterministic once `M=C_k0/q` is known.

For the first square lift, one may choose

`0 <= n <= q-1`,

so a `q^2` companion is guaranteed by

`k <= k0 + 4q(q-1)`.

This is a valuation-event bound only. It is not a bound for a Lane-I hit.

## 3. Multi-source lift corollary

Suppose a product of distinct routed source primes

`Q = q1*q2*...*qs`

divides one companion

`C_k0 = Q R`.

Repeat the destination by the common route period

`k_t = k0 + 4 Q t`.

Then

`C_{k_t} = Q(R+t)`.

Consequently, for every `e>=1`,

`Q^e | C_{k_t}`

if and only if

`t = -R mod Q^(e-1)`.

In particular there is exactly one simultaneous `Q^2` lift among every `Q` common-route representatives.

Thus multi-source routing does more than preserve several factors. It gives a deterministic schedule on which all of those routed factors can be lifted simultaneously in valuation.

Again, this does not force a hit. It manufactures a stronger divisor lattice at a predictable later destination.

## 4. Canonical Type-II test at a square lift

Suppose a square lift produces

`C_k = q^2 B`,

with `gcd(q,k)=1`.

The divisor-square form of the Type-II target asks whether a divisor `d` of `C_k^2` satisfies

`d = -C_k mod k`.

The valuation lift supplies the canonical divisor

`d=q^2`.

For this divisor,

`q^2 = -q^2 B mod k`.

Because q is invertible modulo k, this is equivalent to

`B = -1 mod k`.

Therefore:

> at any routed `q^2` lift, the canonical divisor `d=q^2` gives a Type-II hit exactly when the remaining quotient `B=C_k/q^2` is congruent to `-1 mod k`.

The valuation theorem supplies the square divisor. The remaining quotient congruence is the separate target-formation condition.

This separation is useful. It distinguishes what routing guarantees from what a later hit still needs.

## 5. The 8,803,369 record explains itself

For the finite Lane-I record

`p = 8,803,369`,

one has

`p mod11 = 3`.

The route class for q=11 begins at

`k0=19`,

and repeats as

`19, 63, 107, 151, ..., 459`.

At k=19,

`C19 = 2,200,847 = 11 * 200,077`.

Thus

`M=200,077`,

and

`-M mod11 = 2`.

The unique square lift in the first q=11 route period is therefore

`n=2`,

which gives

`k = 19 + 4*11*2 = 107`.

Exactly as predicted,

`C107 = 2,200,869`

`= 11^2 * 18,189`.

The known Type-II certificate uses

`d=11^2=121`.

The quotient is

`B=18,189`,

and

`18,189 = 170*107 - 1`.

So

`B = -1 mod107`,

which is precisely the canonical Type-II trigger from the square-lift theorem.

The k=107 opening therefore decomposes into two distinct facts:

1. **route valuation:** periodic q=11 routing forces the unique first-period `11^2` lift at k=107 for this prime;
2. **target formation:** the remaining quotient happens to satisfy `B=-1 mod107`.

The first fact is now a theorem. The second remains the deeper coverage question.

## 6. The same record has a simultaneous q11*q23 lift

At k=19 the same prime lies on the multi-source branch

`C19 = 11*23*8699`.

Put

`Q=11*23=253`,

`R=8699`.

The common route ladder is

`k_t = 19 + 4*253*t`,

with

`C_{k_t}=253(8699+t)`.

The unique first simultaneous square lift satisfies

`t = -8699 mod253 = 156`.

Hence

`k=157,891`,

and

`C_k = 2,240,315 = 253^2 * 35`.

This occurs long after the prime has already hit at k=107, so it is not a new finite record. Its value is structural: multi-source route accumulation carries an exact simultaneous valuation-amplification schedule.

## 7. Strategic consequence for CBX

The corrected route graph should now track three distinct edge properties:

1. **support routing** - which source prime is forced into which destination class;
2. **divisor-lattice saturation** - whether one or more routed factors fill a destination QR subgroup;
3. **valuation phase** - where repeated route representatives lift a routed factor from `q` to `q^2`, `q^3`, or a routed product from `Q` to `Q^2`.

The third coordinate was missing from the route graph.

For theorem search, the highest-value experiment is now to intersect these deterministic valuation phases with exact destination miss masks and Type-II quotient conditions. The finite k=107 anchor gives the prototype:

`routed q -> predictable q^2 lift -> test B=-1 mod k`.

A square lift alone is not coverage, and the existence of a bounded square-lift representative must not be reported as a bounded Lane-I theorem.

Erdős-Straus remains open.
