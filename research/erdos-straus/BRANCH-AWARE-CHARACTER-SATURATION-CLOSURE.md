# Branch-aware quadratic/Jacobi saturation closure

**Status:** exact finite negative-frontier theorem  
**Date:** 2026-08-16  
**Primary classifier:** `classify_branch_aware_character_closure.py`  
**Independent anchor verifier:** `verify_branch_aware_character_closure.py`  
**Depends on:** Jacobi-saturation character extraction, QR-saturating routed seeds, multi-source saturation, reciprocity-route barrier, incoming-source repulsion theorems  
**Claim boundary:** this is a complete closure statement for the stated character-saturation model through destination k<=5000. It is not a proof of Erdős-Straus and does not include finer exact miss masks, valuations, Type-II center geometry, or unrestricted companion-factor allocation.

## 1. Question

The preceding route program showed that a fixed-shift miss can produce a positive quadratic or Jacobi character, route a new prime factor into another companion, enlarge the mandatory divisor seed, saturate a new character kernel, and extract another positive character.

The natural question is whether this recursion eventually contradicts itself.

A valid test must be branch-aware. It is not enough to collect character statements in a global set. Every residue used to route a source must remain attached to the same hypothetical prime p throughout the cascade.

This note closes that exact finite question for the present saturation model.

## 2. Root branches

The closure begins from the eight merged composite character-extraction branches.

1. h=121 - k39 extraction of q13, with p mod47=8.
2. h=169 - k51 extraction of q17, with p mod11=4 and p mod23=18.
3. h=169 - k111 extraction of q37, with p mod23=4.
4. h=289 - k39 extraction of q13, with p mod11=5 and p mod47=8.
5. h=289 - k51 extraction of q17, with p mod11=4 and p mod23=18.
6. h=289 - k215 extraction of q43, with p mod11=5 and p mod31=2.
7. h=529 - k51 extraction of q17, with p mod11=4 and p mod23=18.
8. h=529 - k171 extraction of q19, with p mod11=5 and p mod23=13.

Each root also carries the already-proved positive source characters for its hard class under the simultaneous-survivor hypothesis.

- h=121 - q19 and q47.
- h=169 - q11 and q31.
- h=289 - q11, q31, and q47.
- h=529 - q11 and q31.

The fixed source residues that define a root are retained exactly.

## 3. State and transition rule

A branch state consists of

- the hard class h modulo840;
- every source residue p mod q already fixed by routing;
- every prime character `(q/p)` already known;
- recursion depth.

For every odd destination

`k = 3 mod4`

through k<=5000, the classifier first forms the mandatory class-conditioned seed

`g_(k,h) = gcd(210,(h+k)/4)`.

Every already-fixed source q satisfying

`p mod q = -k mod q`

is automatically adjoined to the seed because q divides C_k.

For a known but not yet fixed source character, routing is permitted exactly when the required residue `-k mod q` has that known Legendre sign.

The resulting mandatory seed S is then tested directly in the divisor-square geometry modulo k.

A transition qualifies in one of four ways.

### Type-I hit

If the divisor residues of S squared already contain the Type-I target `-1/4 mod k`, the branch closes at k.

### Saturated known-positive destination

If the divisor residues of S squared equal the complete Jacobi-plus unit kernel modulo k and every odd-exponent prime character in k is already known, then the saturated miss requires their product to be +1.

If the known product is +1, the transition is compatible and produces no new source.

If it is -1, the branch would close by character contradiction.

### Single-character extraction

If the seed Jacobi-saturates and exactly one odd-exponent prime factor q of k has unknown character, a miss forces that character exactly.

The extracted character is added to the branch and may be routed in later generations.

### Product constraint

If two or more odd-exponent prime factors of k remain unknown, saturation produces only their character product. That constraint is recorded but is not promoted to separate source characters.

## 4. Multi-source completeness guard

At a destination, the classifier enumerates minimal qualifying routed subsets through size three.

A larger hidden subset must also be ruled out.

All source characters that occur in this closure are positive. By the reciprocity-route barrier, a positively routed source lies in the Jacobi-plus character class at the destination.

Adding additional positive routed factors can only enlarge the seed divisor set within that plus kernel.

Therefore two relevant properties are monotone under adding compatible positive sources:

- once the fixed Type-I target is present, it remains present;
- once the complete Jacobi-plus kernel is saturated, it remains saturated.

Consequently, whenever no subset of size at most three qualifies, it is sufficient to adjoin every compatible positive source simultaneously and test the maximal seed.

If that maximal seed neither hits Type I nor Jacobi-saturates, no hidden subset of four or more compatible positive sources can qualify.

The complete k<=5000 closure contains

`0`

hidden large-subset qualifiers under this maximal-seed test.

## 5. Exact closure result

Starting from the eight roots, the branch-aware saturation recursion reaches a fixed point after depth seven.

The exact finite closure is:

- roots - 8;
- unique branch states - 259;
- minimal qualifying transitions - 2,820;
- saturated known-positive transitions - 2,535;
- positive single-character extractions - 284;
- multi-character product constraints - 1;
- Type-I branch closures inside this saturation scan - 0;
- known-sign contradictions - 0;
- negative character extractions - 0;
- hidden four-or-more-source qualifiers - 0;
- maximum recursion depth - 7;
- largest qualifying destination - k=971.

The generation profile is

- depth0 - 8 states processed, 25 new states;
- depth1 - 25 processed, 55 new;
- depth2 - 55 processed, 62 new;
- depth3 - 62 processed, 47 new;
- depth4 - 47 processed, 29 new;
- depth5 - 29 processed, 23 new;
- depth6 - 23 processed, 10 new;
- depth7 - 10 processed, 0 new.

Thus the recursion closes rather than growing indefinitely.

## 6. Closed source alphabet

Within this model and destination range, the recursion closes on exactly the following 24 source primes:

`11, 13, 17, 19, 23, 29, 31, 37, 43, 47, 53, 71, 79, 83, 107, 109, 127, 131, 151, 167, 191, 271, 383, 971`.

No negative source character is generated.

Representative newly generated sources include q29, q53, q79, q83, q107, q109, q127, q131, q151, q167, q191, q271, q383, and q971.

The independent verifier directly replays representative root, composite, middle-generation, and late-generation extraction edges by enumerating every positive divisor of the mandatory seed squared. It does not use the classifier's state-transition implementation.

Among the pinned anchors are:

- q79 at prime destination k79;
- q83 at k83;
- q109 extracted from composite k327=3*109;
- q151 at k151;
- q271 at k271;
- q383 at k383;
- q971 at k971.

For each anchor the direct divisor set equals the full Jacobi-plus kernel and the remaining odd-exponent character is forced positive.

## 7. Qualifying destination set

All qualifying saturation destinations through k<=5000 lie in the finite set

`3, 7, 11, 15, 19, 23, 31, 35, 39, 47, 51, 55, 71, 79, 83, 107, 109, 111, 127, 131, 151, 167, 171, 191, 215, 271, 383, 551, 971`.

No new qualifying destination occurs above971 through5000.

A separate run truncated at k<=1000 reaches the same final state closure. Extending the destination range from1000 to5000 therefore adds no new source, branch state, or qualifying transition class.

This is a finite observation within the pinned model, not a claim about all k.

## 8. The lone unresolved product constraint

Exactly one saturated transition produces two unknown prime characters rather than one.

It is the already-known h=289 branch at

`k=551 = 19*29`.

The routed conditions

`p mod23 = 1`

and

`p mod31 = 7`

make

`S = 210*23*31 = 149730`

Jacobi-saturating modulo551.

A miss therefore forces

`(19/p)(29/p)=+1`.

Neither sign is individually determined by that transition, so the closure does not promote q19 or q29 from this product statement alone.

The independent verifier replays this product branch directly.

## 9. Negative frontier theorem

Within the stated roots, source theorems, routing rule, exact retained congruences, Jacobi/QR seed-saturation mechanism, and destination range k<=5000:

> recursive positive character routing reaches a finite compatible fixed point. It produces no negative character, no Type-I seed collision, and no character-sign contradiction.

This is useful precisely because it is negative.

The repeated survival of the route graph is no longer evidence that one more Legendre symbol is likely to finish the conjecture. At this scope, the entire quadratic/Jacobi saturation recursion has been enumerated and it does not finish it.

## 10. What this theorem does not erase

The closure intentionally forgets information finer than Jacobi sign once a destination has been reduced to its complete plus kernel.

That discarded information is now the main research frontier.

In particular, the next proof search should use at least one of:

- exact miss masks that are proper subsets of the Jacobi-plus kernel;
- exact Type-II center collisions;
- prime-power valuation information inside C_k;
- exponent-sensitive divisor-square geometry;
- simultaneous allocation of routed factors among coprime or nearly coprime companions;
- the six-companion residual wheel and its support-overlap restrictions;
- higher-order characters inside the positive quadratic/Jacobi subgroup.

The finite record p=8,803,369 already demonstrates why this matters. Its first Lane-I hit at k=107 is not explained merely by a character sign. The exact hit uses the square divisor

`D = 11^2 = 121`,

which collides with the Type-II target modulo107.

That is precisely the sort of exponent- and center-sensitive information the character closure discards.

## 11. Strategic conclusion

The character route program has now done two jobs.

First, it produced real range-free theorems, new source characters, routed saturation upgrades, and recursive branch eliminations.

Second, it has now identified its own boundary.

The next route toward a universal argument should not be another unstructured search for positive Legendre symbols. The sharper target is the exact divisor geometry that remains after all compatible character information has been exhausted.

Erdős-Straus remains open.
