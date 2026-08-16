# Branch-aware quadratic/Jacobi saturation closure

**Status:** exact finite fixed point for the class-global-positive character-saturation model  
**Date:** 2026-08-16  
**Primary classifier:** `classify_branch_aware_character_closure.py`  
**Independent anchor verifier:** `verify_branch_aware_character_closure.py`  
**Depends on:** Jacobi-saturation character extraction, QR-saturating routed seeds, multi-source saturation, reciprocity-route barrier, incoming-source repulsion theorems  
**Claim boundary:** this is a complete closure statement for the model stated below through destination `k<=5000`: the eight extraction roots, the class-global positive source characters attached to those hard classes, exact retained route residues, and characters recursively extracted inside this model. It is **not** a superset of every previously landed CBX route model. In particular, `RECURSIVE-CHARACTER-PROMOTION.md` also explores branch-local positive source routes such as an unfixed q23 route; those are not admitted here unless q23 is already fixed on the root/state. The landed h=121 q59 source is a concrete witness to that distinction. This theorem does not include finer exact miss masks, valuations, Type-II center geometry, unrestricted companion-factor allocation, or prove Erdős-Straus.

## 1. Question

The preceding route program showed that a fixed-shift miss can produce a positive quadratic or Jacobi character, route a new prime factor into another companion, enlarge the mandatory divisor seed, saturate a new character kernel, and extract another positive character.

The question addressed here is narrower and exact:

> Starting from the eight merged extraction roots, and allowing the positive source characters that are already class-global on those simultaneous-survivor branches plus characters recursively extracted from them, does the resulting branch-aware QR/Jacobi saturation recursion reach a fixed point or contradict itself?

A valid test must remain branch-aware. It is not enough to collect character statements in a global set. Every residue used to route a source must remain attached to the same hypothetical prime p throughout the cascade.

This note closes that stated finite model. It does not claim to close the union of every CBX routing model.

## 2. Root branches and source scope

The closure begins from the eight merged composite character-extraction branches.

1. h=121 - k39 extraction of q13, with p mod47=8.
2. h=169 - k51 extraction of q17, with p mod11=4 and p mod23=18.
3. h=169 - k111 extraction of q37, with p mod23=4.
4. h=289 - k39 extraction of q13, with p mod11=5 and p mod47=8.
5. h=289 - k51 extraction of q17, with p mod11=4 and p mod23=18.
6. h=289 - k215 extraction of q43, with p mod11=5 and p mod31=2.
7. h=529 - k51 extraction of q17, with p mod11=4 and p mod23=18.
8. h=529 - k171 extraction of q19, with p mod11=5 and p mod23=13.

Each root also carries the already-proved **class-global** positive source characters for its hard class under the simultaneous-survivor hypothesis.

- h=121 - q19 and q47.
- h=169 - q11 and q31.
- h=289 - q11, q31, and q47.
- h=529 - q11 and q31.

The fixed source residues that define a root are retained exactly.

A source whose positivity is only available after refining to a branch-local residue is not automatically added to this source inventory. The important example is q23. When a root already fixes p mod23 to a positive residue, q23 is available there. When p mod23 is unfixed, this model does not create a q23 source merely by choosing a positive route residue. That branch-local refinement belongs to the complementary model in `RECURSIVE-CHARACTER-PROMOTION.md`.

This distinction explains why the present fixed point can contain q53, q71, q79 and many later sources while not containing the separately landed h=121 q59 source.

## 3. State and transition rule

A branch state consists of

- the hard class h modulo840;
- every source residue p mod q already fixed by routing;
- every prime character `(q/p)` already known in this model;
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

If two or more odd-exponent prime factors of k remain unknown, saturation produces only their character product. That constraint is recorded but is not promoted to separate source characters in this theorem.

## 4. Multi-source completeness guard

At a destination, the classifier enumerates minimal qualifying routed subsets through size three.

A larger hidden subset must also be ruled out.

All source characters that actually occur in this pinned closure are positive. By the reciprocity-route barrier, a positively routed source lies in the Jacobi-plus character class at the destination.

Adding additional positive routed factors can only enlarge the seed divisor set within that plus kernel.

Therefore two relevant properties are monotone under adding compatible positive sources:

- once the fixed Type-I target is present, it remains present;
- once the complete Jacobi-plus kernel is saturated, it remains saturated.

Consequently, whenever no subset of size at most three qualifies, it is sufficient to adjoin every compatible positive source simultaneously and test the maximal seed.

If that maximal seed neither hits Type I nor Jacobi-saturates, no hidden subset of four or more compatible positive sources can qualify.

The complete k<=5000 closure contains

`0`

hidden large-subset qualifiers under this maximal-seed test.

The classifier now enforces the positive-source precondition before using the maximal-seed guard. The result contains zero negative extracted characters, so that invariant is preserved throughout the pinned run.

## 5. Exact closure result

Starting from the eight roots under the source scope above, the branch-aware saturation recursion reaches a fixed point after depth seven.

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

Thus this recursion closes rather than growing indefinitely.

## 6. Closed source alphabet inside this model

Within this exact source model and destination range, the recursion closes on the following 24 source primes:

`11, 13, 17, 19, 23, 29, 31, 37, 43, 47, 53, 71, 79, 83, 107, 109, 127, 131, 151, 167, 191, 271, 383, 971`.

No negative source character is generated.

This is **not** the full union of all source primes already proved elsewhere in CBX. In particular q59 is absent here even though `RECURSIVE-CHARACTER-PROMOTION.md` proves an h=121 q59 source using a branch-local q23 route. That is expected from the model boundary in Section 2 and is not a contradiction between the two theorems.

Representative newly generated sources inside this model include q29, q53, q79, q83, q107, q109, q127, q131, q151, q167, q191, q271, q383, and q971.

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

## 7. Qualifying destination certificate

All qualifying saturation destinations in this model through k<=5000 lie in the exact finite set

`3, 7, 11, 15, 19, 23, 27, 31, 35, 39, 47, 51, 55, 63, 71, 75, 79, 83, 91, 95, 107, 111, 127, 131, 135, 143, 151, 167, 171, 191, 203, 215, 231, 271, 327, 371, 383, 391, 551, 971`.

This set includes compatible destinations that may produce a qualifying saturated transition without creating a new source state.

The initial certificate accidentally listed only destinations emphasized by source creation. A first correction then substituted a different over-inclusive list. Neither error changed the state machine, transition count, source alphabet, maximum depth, or maximum qualifying destination. The list above is the exact set emitted by the canonical classifier and independently reproduced during review.

No qualifying destination occurs above971 through5000.

The classifier also computes the complete state closure at k<=1000 and requires its canonical state-key set to equal the k<=5000 state-key set. Thus extending the destination range from1000 to5000 adds no new source or branch state inside this model.

This is a finite observation within the pinned model, not a claim about all k or all CBX source semantics.

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

Neither sign is individually determined by that transition, so this theorem records the relation without promoting q19 or q29 from it.

A separate product-aware follow-on can carry this relation as a first-class state constraint; preliminary exact evaluation shows that doing so does not create an additional individual character, but that stronger claim is intentionally kept separate from the present closure.

The independent verifier replays the product branch directly.

## 9. Class-global-positive frontier theorem

Within the stated roots, class-global source theorems, routing rule, exact retained congruences, Jacobi/QR seed-saturation mechanism, and destination range k<=5000:

> recursive positive character routing reaches a finite compatible fixed point. It produces no negative character, no Type-I seed collision, and no character-sign contradiction.

This is useful precisely because it is negative.

It says that continuing to iterate this **specific** class-global-positive saturation grammar does not finish the conjecture. It does not say that every branch-local positive route, exact miss-mask refinement, or other CBX route semantics have been exhausted.

## 10. What this theorem does not erase

The closure intentionally forgets information finer than Jacobi sign once a destination has been reduced to its complete plus kernel.

It also intentionally omits branch-local source refinements that are not already represented by a known character in the state.

Those discarded or complementary information channels are now the main research frontier.

In particular, the next proof search should use at least one of:

- exact miss masks that are proper subsets of the Jacobi-plus kernel;
- exact Type-II center collisions;
- prime-power valuation information inside C_k;
- exponent-sensitive divisor-square geometry;
- simultaneous allocation of routed factors among coprime or nearly coprime companions;
- the six-companion residual wheel and its support-overlap restrictions;
- higher-order characters inside the positive quadratic/Jacobi subgroup;
- explicit reconciliation of class-global and branch-local source semantics in one survivor-state engine.

The finite record p=8,803,369 already demonstrates why this matters. Its first Lane-I hit at k=107 is not explained merely by a character sign. The exact hit uses the square divisor

`D = 11^2 = 121`,

which collides with the Type-II target modulo107.

That is precisely the sort of exponent- and center-sensitive information the character closure discards.

## 11. Strategic conclusion

This class-global-positive character model has now done two jobs.

First, it produces a much larger exact branch-aware fixed point than the earlier shallow recursive atlas, including late sources such as q271, q383, and q971.

Second, it identifies a method boundary without pretending to subsume the complementary branch-local route model.

The next route toward a universal argument should therefore not be another unstructured search for positive Legendre symbols. The sharper target is a unified survivor-state engine that preserves exact miss centers and provenance while combining class-global characters, branch-local routes, source-independent repulsion, residual allocation, and valuation phases.

Erdős-Straus remains open.
