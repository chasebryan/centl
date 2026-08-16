# Multi-source QR saturation in the character-route graph

**Status:** exact finite route-graph theorem  
**Date:** 2026-08-16  
**Primary classifier:** `classify_multisource_qr_saturation.py`  
**Independent verifier:** `verify_multisource_qr_saturation.py`  
**Depends on:** `QR-SATURATING-ROUTED-SEEDS.md`, `CHARACTER-ROUTING-RECIPROCITY-BARRIER.md`, current fixed-shift support atlas  
**Claim boundary:** the results below prove conditional fixed-shift rigidity on named simultaneous route branches. They do not prove that every prime enters those branches and do not prove Erdős-Straus.

## 1. Why multiple routes matter

The reciprocity barrier shows that a single positively routed source prime arrives in the positive Jacobi character class at an admissible destination. A single routed factor is therefore often compatible with the receiving miss condition.

The QR-saturating seed lemma shows a different mechanism. A collection of individually compatible mandatory divisors can collectively fill the entire quadratic-residue subgroup of a prime destination.

This motivates a stricter route-graph question:

> Can two or three source theorems route distinct prime factors into the same companion so that no proper routed subset saturates the destination, but the full combined seed does?

The answer is yes.

Using only the currently proved positive-character source nodes and prime destinations through k<=5000, there are exactly

- 8 genuine two-source saturation synergies;
- 6 genuine three-source saturation synergies.

Here genuine means:

- the ordinary destination class seed is not QR-saturating;
- no one routed source factor makes it QR-saturating;
- for a triple, no routed pair makes it QR-saturating;
- the complete named routed set does make it QR-saturating.

## 2. Two-source synergies

### h=121, destination k=31

Sources:

- q=19 with required `p mod19=7`;
- q=47 with required `p mod47=16`.

Both residues are permitted positive-character source branches. They route

`19 | C31`

and

`47 | C31`.

The h=121 class seed at k=31 is 2. Neither seed 2*19 nor seed 2*47 saturates QR(31), but

`S = 2*19*47 = 1786`

does.

Thus, conditional on the two source branches, a k=31 miss is equivalent to QR-only prime support of C31.

### h=121, destination k=79

Sources q=19 and23 with required residues

`p mod19=16`

and

`p mod23=13`.

The class seed is 10. The combined seed

`S = 10*19*23 = 4370`

QR-saturates modulo79, while neither single routed augmentation does.

### h=169, destination k=19

Sources:

- q=11, `p mod11=3`;
- q=23, `p mod23=4`.

Both route into C19. The h=169 class seed is 1. Neither 11 nor23 alone fills QR(19), but

`S = 11*23 = 253`

does.

Therefore a simultaneous source survivor on this branch can miss k=19 only when every prime factor of C19 is a quadratic residue modulo19.

### h=169, destination k=83

There are three distinct pair synergies, all on class seed21:

- q=11 and23, required residues5 and9, seed5313;
- q=11 and31, required residues5 and10, seed7161;
- q=23 and31, required residues9 and10, seed14973.

Each pair saturates QR(83), while neither member of the pair does so alone.

### h=169, destination k=167

Sources q=11 and31 with required residues9 and19. The class seed is42 and the combined seed

`S = 42*11*31 = 14322`

saturates QR(167), with neither single routed source sufficient.

### h=529, destination k=19

The same q=11 and q=23 geometry as h=169 occurs:

`p mod11=3`

`p mod23=4`

and

`S = 11*23 = 253`.

This pair QR-saturates modulo19 from the otherwise trivial class seed1.

## 3. Three-source synergies

Exactly six genuine triples occur through destination k<=5000.

### Destination k=79

For h=169,289,529, the sources q=11,23,31 with required residues

`9, 13, 14`

jointly saturate QR(79) from class seed2:

`S = 2*11*23*31 = 15686`.

No single source and no source pair saturates the destination.

### Destination k=83

For h=289 and529, q=11,23,31 with required residues

`5, 9, 10`

jointly saturate QR(83) from class seed3:

`S = 3*11*23*31 = 23529`.

No proper routed subset saturates.

### Destination k=167

For h=289, sources q=11,31,47 with required residues

`9, 19, 21`

jointly saturate QR(167) from class seed6:

`S = 6*11*31*47 = 96162`.

Again no proper routed subset is sufficient.

## 4. The finite kappa-star record realizes a pair saturation exactly

The finite first-denominator record

`p = 8,803,369`

has hard class h=169 and first Lane-I hit kappa-star=107 in the existing finite census.

Before that hit it misses k=11, k=19, and k=23. Its relevant congruences are

`p mod11 = 3`

and

`p mod23 = 4`.

Therefore the q=11 and q=23 source routes both land in C19.

Indeed

`C19 = (p+19)/4 = 2,200,847`

with exact factorization

`2,200,847 = 11*23*8699`.

The pair seed

`11*23 = 253`

already fills every quadratic residue modulo19. The remaining factor satisfies

`8699 mod19 = 16`,

which is itself a quadratic residue modulo19.

So k=19 still misses exactly as the saturation theorem predicts.

This is an important adversarial witness. Multi-source saturation is a real structural strengthening, but saturation alone is not coverage. A hard prime can satisfy the resulting QR-only support condition and continue deeper.

## 5. Strategic meaning

The route graph now has three distinct levels:

1. Character routing - a positive source character routes a prime factor into another companion.
2. Single-source saturation - one routed factor enlarges the destination seed enough to fill its QR subgroup.
3. Multi-source saturation - several individually insufficient routed factors collectively fill the destination QR subgroup.

The third level is the first genuinely collective routing mechanism. It is invisible if each character theorem is studied in isolation.

The next useful question is not merely whether a destination becomes QR-rigid. The 8,803,369 anchor shows that QR-rigid residual support can persist. The next target is therefore:

> after multi-source saturation, can the remaining cofactor be forced into a proper subset of the QR subgroup by another exact state, valuation, or coprime-residual constraint?

This points directly toward intersections of the multi-source saturation atlas with

- exceptional exact miss masks;
- the six-companion residual wheel;
- class-conditioned residual coprimality;
- higher-order characters inside the QR subgroup;
- valuation constraints from the divisor-square state.

Erdős-Straus remains open.
