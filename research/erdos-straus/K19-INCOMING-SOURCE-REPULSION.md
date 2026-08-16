# Incoming positive-source repulsion at h=289, k=19

**Status:** proved exact fixed-shift route theorem  
**Date:** 2026-08-16  
**Depends on:** reciprocity-route barrier, Jacobi-saturation character extraction, QR-saturating routed seeds  
**Primary classifier:** `classify_k19_incoming_source_repulsion.py`  
**Independent verifier:** `verify_k19_incoming_source_repulsion.py`  
**Claim boundary:** this eliminates the three negative h=289 k=19 miss centers after a sharp class of positive incoming routes. It does not eliminate the positive k=19 centers and does not prove Erdős-Straus.

## 1. Ordinary h=289 geometry at k=19

On hard class

`p mod840 = 289`,

the class-conditioned k=19 seed is

`g_(19,289) = 7`.

Divisors of 7 squared have residues

`H = {1,7,11} mod19`.

This is the unique order-3 subgroup inside the order-9 quadratic-residue group

`QR(19) = {1,4,5,6,7,9,11,16,17}`.

The exact seed7 state closure has

- 51 total states;
- 18 miss states;
- exactly three negative-character miss centers:

`p mod19 = 2,3,14`.

The remaining miss centers are quadratic residues.

## 2. Route a positive source q into C19

Let q be a prime available as a positive character source and suppose it is routed into

`C19 = (p+19)/4`.

Thus

`q | C19`.

The reciprocity-route barrier at destination k=19 implies

`(q/19)=+1`.

Therefore

`q mod19` lies in QR(19).

The mandatory seed becomes

`7q`.

## 3. Exact quotient-group saturation law

There are two cases.

If

`q mod19` lies in H={1,7,11},

then powers q^0,q^1,q^2 remain in H and adjoining q does not enlarge the seed7 subgroup beyond H.

If instead

`q mod19` lies in

`{4,5,6,9,16,17}`,

then q lies outside H. Since QR(19)/H has order3, the three cosets

`H`, `qH`, `q^2 H`

are all distinct and exhaust QR(19).

But those are precisely the residue classes supplied by divisors

`7^a q^b`, with `0<=a<=2` and `0<=b<=2`,

of `(7q)^2`.

Therefore:

> On h=289, an incoming positive source q QR-saturates k=19 exactly when `q mod19` lies in `{4,5,6,9,16,17}`.

The non-repelling positive residues `{1,7,11}` are the sharp complement.

## 4. Elimination of the three negative centers

Once seed7q is QR-saturating, a fixed k=19 miss requires every prime factor of C19 to be a quadratic residue modulo19. Hence p mod19 must itself be a quadratic residue.

Therefore the ordinary negative miss centers

`2,3,14`

are impossible after any repelling incoming source route.

So:

> On h=289, if a positive-character prime q routes into C19 and `q mod19` is one of `4,5,6,9,16,17`, then k=19 cannot miss at p mod19=2,3,14.

## 5. Explicit Type-II divisor table

The elimination is constructive.

For the three negative centers the Type-II targets are

- p mod19=2 -> target9;
- p mod19=3 -> target4;
- p mod19=14 -> target6.

For every repelling q residue, the following divisors D of `(7q)^2` hit those targets exactly.

| q mod19 | p mod19=2, target9 | p mod19=3, target4 | p mod19=14, target6 |
|---|---|---|---|
| 4 | `7q` | `q` | `7^2 q` |
| 5 | `7^2 q^2` | `7 q^2` | `q^2` |
| 6 | `7^2 q` | `7q` | `q` |
| 9 | `q` | `7^2 q` | `7q` |
| 16 | `q^2` | `7^2 q^2` | `7 q^2` |
| 17 | `7 q^2` | `q^2` | `7^2 q^2` |

Every exponent is at most2, so each D divides `(7q)^2`, which divides `C19^2`.

## 6. Current source examples

### q=23

`23 mod19 = 4`.

This is repelling. The merged q23-to-k19 h=289 route has seed161=7*23 and exact QR-support rigidity.

### q=47

`47 mod19 = 9`.

This is repelling. The merged q47-to-k19 route has seed329=7*47 and exact QR-support rigidity.

### q=17 - newly extracted recursive source

The composite k=51 theorem on h=289 can extract

`(17/p)=+1`

from the branch

`p mod11=4`, `p mod23=18`, k51 miss.

Refining to

`p mod17=15`

routes 17 into C19. Since

`17 mod19=17`,

this is a repelling source. Thus the three negative k19 centers die.

### q=43 - newly extracted recursive source

The composite k=215 theorem on h=289 can extract

`(43/p)=+1`

from

`p mod11=5`, `p mod31=2`, k215 miss.

Refining to

`p mod43=24`

routes 43 into C19. Since

`43 mod19=5`,

this is also repelling and eliminates all three negative centers.

### q=11 - sharp non-repelling control

`11 mod19=11`,

which lies inside H. A routed q11 factor therefore remains inside the existing seed7 subgroup and does not QR-saturate the destination by itself.

This is the exact analogue of q47 as the identity-residue control in the k23 repulsion theorem, but here the non-repelling set is the full order-3 subgroup H rather than only the identity.

## 7. Six independent recursive anchors

The independent verifier pins one actual prime for every negative center on each of the two newly extracted recursive sources.

For q17:

- p mod19=2: p=123,985,129;
- p mod19=3: p=116,759,449;
- p mod19=14: p=311,852,809.

Each satisfies the q17 extraction-source residues, genuinely misses k51, routes 17 into C19, and then hits k19 with the explicit D from the table.

For q43:

- p mod19=2: p=817,957,849;
- p mod19=3: p=571,619,449;
- p mod19=14: p=1,606,240,729.

Each satisfies the q43 extraction-source residues, genuinely misses k215, routes 43 into C19, and then hits k19 with the exact Type-II divisor.

These anchors validate the branch realizations but are not the proof. The proof is the quotient-group saturation argument.

## 8. Strategic consequence

The route graph now has two proved source-repulsion destinations:

- k=23 - every nonidentity incoming QR source residue repels the two negative exceptions;
- h=289, k=19 - every incoming QR source outside the seed7 subgroup repels the three negative exceptions.

This identifies a more general pattern:

> the ordinary mandatory seed occupies a subgroup or near-subgroup of the destination QR geometry; an incoming positive source that leaves that stabilizer can expand the divisor lattice to full QR support, causing all negative-center miss branches to collapse.

The next theorem target is to characterize this stabilizer/repeller structure at the other non-rigid prime destinations rather than discovering routed saturation one source at a time.

Erdős-Straus remains open.
