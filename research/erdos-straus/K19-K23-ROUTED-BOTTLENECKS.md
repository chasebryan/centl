# Routed bottlenecks at k=19 and k=23

**Status:** exact fixed-shift theorem series  
**Date:** 2026-08-16  
**Depends on:** `SMALL-PRIME-CLASS-CHARACTER-ATLAS.md`, `K11-CHARACTER-COMPANION-ROUTING.md`, class-conditioned seed law, Lane-I divisor-square equivalence  
**Primary classifier:** `classify_k19_k23_routed_bottlenecks.py`  
**Independent realization regression:** `verify_k19_k23_routed_bottlenecks.py`  
**Claim boundary:** every theorem below is range-free at its named fixed shifts. None proves a universal shift ceiling or Erdős-Straus.

## 1. k=23 has only two negative-character miss exits

For every Mordell-hard prime, the class-conditioned seed at fixed shift k=23 is exactly 6. The exact seed-6 unit-state closure modulo 23 has

- 49 total states;
- 15 miss states;
- 13 positive-character miss states;
- exactly 2 negative-character miss states.

The two negative states have

- p mod 23 = 5;
- p mod 23 = 14.

There are no other negative-character k=23 misses.

Therefore, range-free,

> If a Mordell-hard prime misses fixed k=23 and `(23/p)=-1`, then `p mod23` is 5 or 14.

The character obstruction therefore has only two exits. The general companion-routing identity sends them to

- p mod23 = 5 -> 23 divides C87;
- p mod23 = 14 -> 23 divides C55.

So the negative k=23 branch is not an unstructured half of the prime classes. It is a two-route factor-allocation problem.

## 2. The p mod23 = 14 exit becomes rigid at k=55 for h=1,169

On the p mod23=14 route, factor 23 is forced into

`C55 = (p+55)/4`.

For hard classes h=1 and h=169 modulo 840, the class-conditioned seed at k=55 is 14. Hence the routed seed is

`14 * 23 = 322`.

The exact seed-322 closure modulo 55 has

- 85 total states;
- 5 miss states before the exact hard-class center is imposed.

After imposing the hard class, each of h=1 and h=169 leaves exactly one miss state.

Those two possible miss centers correspond to

- h=1 -> p mod55 = 1;
- h=169 -> p mod55 = 34.

Both satisfy

`p mod11 = 1`.

Therefore:

> For h in {1,169} and p mod23=14, a fixed k=55 miss forces p mod11=1.

Equivalently, on this routed branch, every p mod11 value other than 1 is killed at k=55.

If k=55 still misses, p mod11=1 routes factor 11 into

`C43 = (p+43)/4`.

This gives the exact chain

`k23 negative miss -> p mod23=14 -> 23|C55 -> either k55 hits or p mod11=1 -> 11|C43`.

For h=169 this sharpens the earlier k=11 positive-character restriction from five possible quadratic-residue classes modulo 11 to the single residue 1 on this routed branch.

## 3. The h=121 k=19 branch routes into a one-state k=15 obstruction

The existing small-prime atlas proves that on hard class h=121, a fixed k=19 miss has QR-only prime support modulo 19. In particular, `(19/p)=+1`.

One positive-character branch is

`p mod19 = 4`.

The routing identity sends this residue to k=15:

`19 divides C15`.

For h=121, the class seed at k=15 is 2, so the routed seed is

`2 * 19 = 38`.

Because 15 divides the hard-class modulus 840, h=121 also fixes

`p mod15 = 1`

and hence the exact k=15 center.

The seed-38 closure modulo 15 has 12 states and 4 misses over all centers. After imposing p mod15=1, exactly one miss state remains. Its complete divisor-residue mask is

`{1,2,4,8} mod15`.

This set is exactly the kernel of the Jacobi character modulo 15:

`(a/15) = (a/3)(a/5) = +1`.

Therefore the routed branch admits a complete support characterization:

> For h=121 and p mod19=4, fixed k=15 misses if and only if every prime factor of C15 lies in {1,2,4,8} modulo 15.

The forward direction follows because every prime factor of C15 occurs as an exponent-one divisor residue and the unique miss mask contains only the Jacobi-plus subgroup. The reverse direction follows because products of Jacobi-plus residues remain Jacobi-plus, while the k=15 target lies in the opposite character coset.

Thus an h=121 simultaneous survivor on this route must satisfy two adjacent support restrictions:

- C19 has only quadratic-residue prime support modulo 19;
- C15 has only Jacobi-plus prime support modulo 15.

The companions are adjacent integers:

`C19 = C15 + 1`.

In h=121 coordinates,

`C19 = 35(6r+1)`

and

`C15 = 2(105r+17)`,

so the seed-stripped residuals obey

`35(6r+1) - 2(105r+17) = 1`.

This is a genuine cross-shift support bottleneck, but not a contradiction. Small arithmetic realizations satisfying both support semigroups exist, so no universal coverage claim is made from the relation alone.

## 4. Why this narrows the proof search

The previous character atlas left positive and negative character branches as abstract residue conditions. The routed analysis converts several of those branches into compulsory prime factors in later companions, where the existing class seeds make the next state space much smaller.

The new exact structure is:

- k=23 negative miss has only two residue exits;
- one exit feeds k=55 and, on h=1,169, either dies there or forces a single p mod11 residue and another routed factor;
- the rigid h=121 k=19 branch has a p mod19=4 exit whose next obstruction at k=15 is a unique Jacobi-support state.

The remaining task is no longer to search blindly for stronger isolated characters. It is to couple these routed support semigroups to neighboring companion gcd identities and determine whether an infinite simultaneous allocation remains possible.

Erdős-Straus remains open.
