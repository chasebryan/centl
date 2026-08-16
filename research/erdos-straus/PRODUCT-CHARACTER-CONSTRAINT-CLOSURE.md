# Product-character constraint closure

**Status:** exact follow-on to the class-global-positive character fixed point  
**Date:** 2026-08-16  
**Primary classifier:** `classify_product_character_constraint_closure.py`  
**Independent verifier:** `verify_product_character_constraint_closure.py`  
**Depends on:** `BRANCH-AWARE-CHARACTER-SATURATION-CLOSURE.md`, Jacobi-saturation character extraction  
**Claim boundary:** this propagates multi-character sign equations only inside the landed class-global-positive character-saturation model. It does not subsume branch-local source refinements, exact miss masks, valuation geometry, residual allocation, or prove Erdős-Straus.

## 1. Why the parent closure left one loose equation

The class-global-positive character closure reaches a 259-state fixed point but records one saturated transition with two unknown odd-exponent prime characters:

`k = 551 = 19*29`.

On the h=289 branch with

`p mod23 = 1`,

`p mod31 = 7`,

the mandatory seed is

`S = 210*23*31 = 149730`.

Divisors of S squared fill the complete Jacobi-plus kernel modulo551. Therefore a k=551 miss forces

`(19/p)(29/p) = +1`.

The parent theorem deliberately logs this relation without splitting it into two individual source characters.

The present follow-on asks the exact next question:

> if that product equation is carried as state information and used in every later saturated transition, does it create a new individual character or a contradiction?

The answer is no within the same model and destination range.

## 2. Character equations as GF(2) state

Encode a prime character by

`x_q = 0` when `(q/p)=+1`,

`x_q = 1` when `(q/p)=-1`.

Then a product equation

`(q1/p)...(qm/p) = sigma`

becomes a linear equation over GF(2):

`x_q1 xor ... xor x_qm = b`,

where b=0 for sigma=+1 and b=1 for sigma=-1.

The k=551 relation is therefore

`x_19 xor x_29 = 0`.

The product-aware state extends the parent state by a canonical Gaussian-eliminated basis of such equations.

Whenever an individual character is known, it is substituted into the basis. A one-variable row derives a new individual character. An empty row with right side1 is a contradiction.

Whenever a later saturated destination asks for the product of several unknown characters, the existing basis is first queried. If that product is already implied, the transition is classified as known-compatible or contradictory rather than inserting the same unresolved relation again.

## 3. The k=551 equation is exact

The independent verifier directly enumerates every positive divisor of

`149730^2`.

Their residues modulo551 equal the complete Jacobi-plus unit kernel, of size252.

The Type-I target is absent.

Since

`551 = 19*29`

and neither q19 nor q29 is fixed by the h=289 hard modulus or by the routed residues at this branch, the only extracted statement is

`chi_19 * chi_29 = +1`.

Its truth table contains exactly two permitted assignments:

`(-1,-1)`

and

`(+1,+1)`.

Thus the equation alone determines neither sign. If either sign is learned later, the other must equal it. Opposite learned signs would be an immediate contradiction.

## 4. Exact product-aware closure

Re-running the same class-global-positive model through destination

`k<=5000`

with the canonical GF(2) constraint basis carried in every state gives:

- roots - 8;
- canonical states - 260;
- qualifying transitions - 2,826;
- saturated known-compatible transitions - 2,541;
- single-character extractions - 284;
- newly inserted unresolved product equations - 1;
- Type-I hits - 0;
- known-sign contradictions - 0;
- individual characters derived from product equations - 0;
- product-equation contradictions - 0;
- states carrying an unresolved product equation - 1;
- maximum depth - 7.

The source alphabet is unchanged from the parent theorem.

The exact qualifying destination set is also unchanged.

The six-transition increase relative to the parent 2,820-transition closure comes from the additional constraint-bearing state. The existing equation allows repeated appearances of the same character product to be classified as known-compatible rather than creating a second unresolved product relation.

## 5. The unique constraint-bearing state

Exactly one canonical state carries a nonempty product-equation basis.

It lies on h=289 at depth2 and has fixed residues

`p mod11 = 5`,

`p mod13 = 3`,

`p mod23 = 1`,

`p mod31 = 7`,

`p mod47 = 8`.

Its individually known positive characters are

`q11, q13, q23, q31, q47`.

Its unresolved basis is exactly

`x_19 xor x_29 = 0`.

No later transition on this state determines x19 or x29 separately.

No later transition contradicts the relation.

## 6. The state fixed point is still below k=1000

The product-aware classifier computes the complete canonical state-key set twice:

- once with destinations through k<=1000;
- once with destinations through k<=5000.

The two state-key sets are exactly equal.

Thus the product equation does not unlock a late source or contradiction above1000 within the model.

This is a finite statement about the pinned model, not an asymptotic claim.

## 7. Strategic meaning

The lone unresolved quadratic-character equation is not the hidden escape hatch of the character program.

Once propagated exactly, it produces one extra state but:

- no new individual source character;
- no negative character;
- no character contradiction;
- no new source alphabet;
- no new state above k=1000.

That pushes the method boundary one notch farther.

The remaining structure is not merely an unpropagated Legendre/Jacobi relation. The next useful state engine must preserve information finer than character sign, especially:

1. exact fixed-shift miss centers and masks;
2. source-independent repulsion of those centers;
3. seed-stripped residual gcd allocation across companions;
4. periodic q-adic valuation phases;
5. exact Type-II target collisions.

The finite record p=8,803,369 remains the clean prototype: its k=107 opening is controlled by the exact square divisor 11^2 and the quotient congruence modulo107, not by one more unresolved quadratic sign.

Erdős-Straus remains open.
