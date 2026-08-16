# Realized k=19 pair survivor normal form

**Status:** exact fixed-shift state theorem on the two pair routes realized by the recursive closure  
**Date:** 2026-08-16  
**Primary classifier:** `classify_k19_realized_pair_survivor_normal_form.py`  
**Independent verifier:** `verify_k19_realized_pair_survivor_normal_form.py`  
**Depends on:** `MULTISOURCE-EXACT-STATE-PROMOTION-CLOSURE.md`, exact divisor-square state model  
**Claim boundary:** this theorem concerns only the two h=169 pair routes that the landed 380-state class-global recursion actually realizes at k19. It does not prove that every survivor enters either route and does not prove Erdős-Straus.

## 1. Why retain the exact state

The 380-state recursive closure promotes the k19 character on two genuine state-only pair routes:

- q17 + q23 -> k19;
- q23 + q47 -> k19.

At the character level both transitions end with the same statement:

`(19/p)=+1`.

That projection discards the exact reason the branch survives.

Keeping the `(mask,center)` state reveals that the 41-state closures on these two routes are almost completely rigid. The ten miss states collapse to only two modes.

## 2. Route A: q17+q23 -> k19

On h=169, the recursive route requires

`p mod17 = 15`,

`p mod23 = 4`.

Thus 17 and23 both divide

`C19=(p+19)/4`.

Modulo19 their incoming residues are

`17`, `4`.

Starting from class seed1, the routed divisor-square mask is

`M_A = {1,4,6,7,11,16,17}`.

Its exact p-center is

`p mod19 = 6`.

This state is itself a k19 miss.

The complete exact closure from this routed state contains

- 41 states;
- 10 misses.

Nine of the misses have divisor mask exactly

`QR(19) = {1,4,5,6,7,9,11,16,17}`,

one at each quadratic-residue center.

The tenth miss is exactly the original routed state

`(M_A, 6)`.

There is no third mask type.

## 3. Route B: q23+q47 -> k19

The recursive route requires

`p mod23 = 4`,

`p mod47 = 28`.

Thus 23 and47 divide C19.

Modulo19 their residues are

`4`, `9`.

The routed starting mask is

`M_B = {1,4,5,9,11,16,17}`

with exact p-center

`p mod19 = 11`.

Again the closure contains

- 41 states;
- 10 misses.

Again nine miss states have the complete QR(19) mask, one at every positive center, and the only partial-mask miss is the original routed state

`(M_B, 11)`.

No intermediate miss mask occurs.

## 4. Two-mode survivor theorem

For either realized pair route, every k19 miss is exactly one of:

### Mode Q - saturated

The divisor-square mask is the full quadratic-residue subgroup QR(19).

The center may be any of the nine quadratic residues modulo19.

### Mode B - bare routed state

The divisor-square mask is exactly the seven-element routed source mask.

The center is fixed:

- 6 for q17+q23;
- 11 for q23+q47.

There are no other miss modes.

This is substantially stronger than the character statement `(19/p)=+1`.

## 5. Trivial stabilizer of the bare mode

For each bare routed state, test one additional companion prime-factor residue

`a in (Z/19Z)^*`.

The exact transition multiplies the mask by

`{1,a,a^2}`

and multiplies the center by a.

The only residue preserving either the entire bare state or even just its seven-element mask is

`a=1 mod19`.

Every non-1 residue strictly enlarges the mask.

Because divisor masks only grow as further prime factors are adjoined, once the bare mask is left it can never be recovered later.

## 6. Exact cofactor support corollary

Write the routed companion as

### Route A

`C19 = 17*23*R_A`.

### Route B

`C19 = 23*47*R_B`.

Then the bare unsaturated miss mode occurs if and only if every prime factor of the remaining cofactor R is

`1 mod19`.

Proof:

- if every residual prime factor is1 mod19, every exact transition is the identity, so the routed bare state persists and is a miss;
- if any residual prime factor has non-1 residue, the mask strictly grows and can never return to the bare state;
- by the two-mode theorem, if the final state still misses after leaving the bare state, it must be the full QR(19) mode.

Therefore any k19 miss on either route satisfies the exact dichotomy

> **all residual prime support is 1 mod19, or the final divisor mask is fully QR-saturated.**

This is the first lossless compressed survivor signature extracted from the pair-enabled recursive graph.

## 7. Finite realization regression through 10 million

The independent verifier scans actual h=169 primes through

`p <= 10,000,000`.

For q17+q23 -> k19 it finds

- 14 route primes;
- 3 k19 misses;
- all 3 in full-QR mode;
- 0 bare-mode misses;
- first full-QR miss p=3,780,169.

For q23+q47 -> k19 it finds

- 4 route primes;
- 3 k19 misses;
- all 3 in full-QR mode;
- 0 bare-mode misses;
- first full-QR miss p=592,369.

No forbidden intermediate miss is observed.

These finite counts are regression anchors only. The two-mode theorem itself comes from the complete exact state closure and is range-free on the named routes.

## 8. Why this matters for the next engine

A naive persistent-state engine would carry all 41 reachable exact states at each realized k19 pair route.

That is unnecessary for miss propagation.

The miss-relevant state can be compressed losslessly to

- `FULL_QR`, or
- `BARE(seed-mask, defect-center, residual-support=1 mod19)`.

This is a concrete design pattern for CBX survivor signatures: retain only the exact distinctions that affect future arithmetic.

The next useful intersection is with the already-landed cross-shift and valuation theorems:

- in FULL_QR mode, all remaining k19 support information is subgroup-level but the routed residual still participates in exact gcd relations;
- in BARE mode, the residual cofactor is forced into the much smaller prime-support class `1 mod19`;
- repeated routed factors have deterministic q-adic valuation phases, which can be tested against these two survivor modes and later Type-II target formation.

The k107 record shows what the destination looks like: a deterministic valuation lift plus an exact quotient congruence can open a Type-II target. The present theorem gives a compact exact state that can now be carried toward such later destinations instead of collapsing immediately to a character sign.

Erdős-Straus remains open.
