# Incoming positive-source repulsion at k=23

**Status:** proved exact fixed-shift route theorem  
**Date:** 2026-08-16  
**Depends on:** reciprocity-route barrier, QR-saturating seed lemma, q13 recursive elimination  
**Primary classifier:** `classify_k23_incoming_source_repulsion.py`  
**Independent verifier:** `verify_k23_incoming_source_repulsion.py`  
**Claim boundary:** this eliminates the two negative k=23 miss centers after a broad class of incoming positive-character routes. It does not force every positive source to route into C23 and does not prove Erdős-Straus.

## 1. Setup

For every Mordell-hard prime p,

`C23 = (p+23)/4`

has the universal mandatory seed

`6 | C23`.

Let q be another odd prime with

`q | C23`

and suppose q is available as a positive character source:

`(q/p)=+1`.

The reciprocity-route barrier applies at destination k=23. Therefore

`(q/23)=+1`.

Thus q modulo23 lies in

`QR(23) = {1,2,3,4,6,8,9,12,13,16,18}`.

## 2. Nonidentity incoming residues saturate the destination

The base seed6 is not QR-saturating modulo23.

However, if

`q mod23` is any nonidentity element of QR(23),

then the routed seed

`6q`

is QR-saturating modulo23:

`{D mod23 : D divides (6q)^2} = QR(23)`.

This is an exact finite-group statement. In discrete-log coordinates, QR(23) is cyclic of order11 with generator2. Divisors of `(6q)^2` contribute exponents 0,1,2 from each of 2,3,q. For every nonzero QR exponent supplied by q, the resulting three-coordinate sumset is all of Z/11Z.

The identity residue is the sharp exception. If

`q mod23 = 1`,

then adjoining q contributes no new divisor residue and the seed remains non-saturating.

## 3. Consequence for the two exceptional k=23 miss centers

The ordinary seed-6 k=23 state geometry has exactly two negative-character miss centers:

`p mod23 = 5`

and

`p mod23 = 14`.

If a nonidentity positive source q is routed into C23, seed6q is QR-saturating. A saturated k=23 miss requires every prime factor of C23 to be a quadratic residue modulo23, and therefore requires p mod23 itself to be a quadratic residue.

Hence:

> Any positively routed source prime q with `q mod23 != 1` eliminates both ordinary negative k=23 miss centers 5 and14.

This is source-independent. The merged q13 theorem is one recursive instance, not an isolated coincidence.

## 4. Explicit Type-II divisor certificates

The elimination can be witnessed directly by divisors of `(6q)^2`.

For p mod23=5, the Type-II target is16.

For p mod23=14, the Type-II target is8.

For each nonidentity QR residue r=q mod23, the following exponent triples `(a,b,c)` produce

`D = 2^a 3^b q^c`,

with every exponent at most2, so `D | (6q)^2 | C23^2`.

| q mod23 | p mod23=5, target16 | p mod23=14, target8 |
|---|---|---|
| 2 | `2^2 q^2` | `2 q^2` |
| 3 | `2^2 3 q^2` | `2 3 q^2` |
| 4 | `q^2` | `2q` |
| 6 | `3 q^2` | `3^2 q` |
| 8 | `2q` | `q` |
| 9 | `3^2 q^2` | `2 3 q` |
| 12 | `3^2 q` | `3^2 q^2` |
| 13 | `3q` | `q^2` |
| 16 | `q` | `2^2 3 q` |
| 18 | `2 3 q` | `3q` |

Each listed D is exactly the Type-II target modulo23.

Therefore the branch elimination is constructive for every possible repelling source residue.

## 5. Current source examples

Several sources already present in the merged CBX theorem graph illustrate the rule.

### q=13

`13 mod23 = 13`.

This is a nonidentity QR residue. The merged recursive q13 theorem therefore kills both negative k=23 centers. Its explicit choices are D=39 and D=169.

### q=31

`31 mod23 = 8`.

Thus any positive q31 route into C23 makes seed186 QR-saturating and eliminates both negative centers. This is the previously observed q31 to k23 upgrade on h=169,289,529.

### q=59

`59 mod23 = 13`.

Thus the h=361 q59 route into C23 makes seed354 QR-saturating and eliminates the negative centers.

### q=47 - sharp identity control

`47 mod23 = 1`.

Although q47 can be a positive character source, adjoining it to the k=23 seed does not enlarge the divisor residue set:

`Div((6*47)^2) mod23 = Div(6^2) mod23`.

So q47 is the exact identity-residue control showing why the hypothesis `q mod23 != 1` is necessary.

## 6. Strategic meaning

The exceptional negative k=23 geometry is fragile under incoming positive routes.

A branch can preserve p mod23=5 or14 only if every positive source routed into C23 is congruent to1 modulo23. Any nonidentity positive incoming factor immediately supplies enough divisor-square geometry to hit k=23.

This changes the recursive search target. Instead of treating the k=23 negative exceptions as permanent escape states, the branch-aware route graph should ask:

> does any extracted or promoted positive source q with q mod23 !=1 become mandatory in C23?

If yes, that negative branch terminates at k=23.

The remaining work is to propagate this rule through extracted q17, q37, q43 and later promoted sources, while preserving the exact residue constraints that created those sources.

Erdős-Straus remains open.
