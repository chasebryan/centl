# Provenance-aware recursive character promotion

**Status:** exact finite recursive route-graph closure for the configured mechanism  
**Date:** 2026-08-16  
**Primary classifier:** `classify_recursive_character_promotion.py`  
**Independent verifier:** `verify_recursive_character_promotion.py`  
**Depends on:** `JACOBI-SATURATION-CHARACTER-EXTRACTION.md`, `QR-SATURATING-ROUTED-SEEDS.md`, `MULTISOURCE-QR-SATURATION.md`, reciprocity-route barrier  
**Claim boundary:** finite conditional promotion graph only. This is not a survivor cover, not a universal shift ceiling, and not an Erdős-Straus proof.

## 1. Why the route graph must carry ancestry

The composite Jacobi-saturation theorem creates new positive characters such as

`(13/p)=+1`, `(17/p)=+1`, `(37/p)=+1`, `(43/p)=+1`.

Those statements are conditional. For example, the h=169 q37 source is earned on the branch

`p mod23 = 4`

plus a k=111 miss.

It is therefore unsound to flatten q37 into a class-wide source list and forget how it was obtained.

The recursive object is a proof state carrying

- the hard class `h mod840`;
- exact accumulated residue assignments `p mod q = r`;
- the fixed shifts whose misses were used to extract or promote characters;
- the positive-character source primes derived on that branch;
- a proof path witnessing the ancestry.

The classifier canonicalizes only states with the same hard class, exact residue assignments, and derived source set. Breadth-first traversal preserves one shortest ancestry when the same arithmetic state is reached in more than one way.

## 2. Recursive promotion rule

Let a current proof state contain a positive-character source q. A route into destination k imposes

`p mod q = -k mod q`,

so q divides

`C_k = (p+k)/4`.

If the state already fixed `p mod q`, the route is admitted only when the two residues agree. Otherwise the required route residue must lie in the positive quadratic-character class of q. This is the provenance gate that prevents a derived character from being used outside its earned branch.

The v1 recursive engine admits one or two routed source primes at a time and requires the routed set to be minimal for saturation.

### Prime destination

If k is prime, k=3 mod4, and the routed seed QR-saturates k while the class seed and every proper routed subset do not, then a k miss forces

`(k/p)=+1`.

The prime k becomes a new positive-character source in the child state.

### Composite destination

If k is composite, k=3 mod4, and the routed seed Jacobi-saturates k minimally, a k miss forces

`Jacobi(k/p)=+1`.

Version 1 promotes a new prime only when exactly one odd-exponent prime factor of k lies outside the hard modulus 840 and the hard class fixes the remaining character product positively. This is deliberately the same extraction rule already proved in the merged composite atlas.

The k=551 two-unknown-character product branch is preserved in the parent research but is not recursively split in this v1 engine.

## 3. Exact finite search scope

The pinned closure uses

- the eight merged single-prime extraction states as roots;
- prime and composite destinations `k<=5000`, `k=3 mod4`;
- routed source arity at most two;
- only route sets containing at least one recursively derived source, because base-only routes are already covered by the landed route atlases;
- minimal QR/Jacobi saturation at the destination;
- exact residue compatibility at every generation.

Within that scope the breadth-first queue exhausts completely.

The exact state graph contains

- 8 root extraction states;
- 70 reachable canonical proof states total;
- 66 promotion edges;
- maximum state depth 5;
- state-depth histogram `8,15,20,14,10,3` for depths 0 through5.

No configured transition remains after the final three depth-5 states are processed.

## 4. Thirteen new hard-class/source pairs

Beyond the base source atlas and the eight merged extraction sources, the recursion creates exactly 13 new `(hard class, positive-character prime)` pairs.

### h=121

Generation 1:

- q53;
- q79.

Generation 2:

- q11;
- q59;
- q71.

### h=169

Generation 1:

- q19;
- q71;
- q83.

Generation 2:

- q13;
- q167.

### h=289

Generation 1:

- q19;
- q71;
- q191.

All 13 first appear by generation 2. Deeper states through depth5 create alternate or more constrained promotion ancestries but no additional hard-class/source pair.

This is an exact fixed point of the configured finite promotion mechanism, not a statement that larger destinations, source arity three, product-character propagation, or other mechanisms cannot enlarge the graph.

## 5. h=121: q13 bootstraps q53 and q79

The merged h=121 k=39 branch gives a conditional q13 source from

`p mod47 = 8`.

Two recursive routes are immediately productive.

### q13 + q23 -> k159 -> q53

Take

`p mod13 = 10`,

`p mod23 = 2`.

Then 13 and23 divide C159. The h=121 class seed is70 and

`S = 70*13*23 = 20930`

Jacobi-saturates

`159 = 3*53`.

Neither routed source alone saturates. A k=159 miss therefore forces

`(53/p)=+1`.

The new q53 source immediately routes back into the small prime destination k=11 on

`p mod53 = 42`,

where the class seed3 becomes

`3*53 = 159`,

which QR-saturates modulo11. Thus the recursion can feed a large extracted source back into a very small fixed shift.

### q13 + q19 -> k79 -> q79

On

`p mod13 = 12`,

`p mod19 = 16`,

the seed

`10*13*19 = 2470`

QR-saturates k=79 minimally, promoting q79.

A second valid q79 ancestry uses q13+q23 at k79. From that branch, q79 combined with q19 promotes both q59 and q71 at the next generation.

## 6. h=169: q37 produces a source cascade

The merged h=169 k=111 extraction provides q37 on the branch

`p mod23 = 4`.

Three first-generation promotions follow.

### q37 -> k71

On

`p mod37 = 3`,

the h=169 k71 class seed30 becomes

`30*37 = 1110`,

which QR-saturates modulo71. A k71 miss promotes q71.

### q11 + q37 -> k83

On residues

`p mod11 = 5`,

`p mod37 = 28`,

the seed

`21*11*37 = 8547`

minimally QR-saturates k83, promoting q83.

### q11 + q37 -> k95 -> q19

On

`p mod11 = 4`,

`p mod37 = 16`,

the seed

`6*11*37 = 2442`

Jacobi-saturates

`95 = 5*19`.

The hard class fixes the mod5 character positively, so a k95 miss extracts q19.

That newly extracted q19 then combines with q31 at k167:

`42*19*31 = 24738`,

which minimally QR-saturates modulo167 and promotes q167.

Separately, the q71 branch combines with q11 at k39 to extract q13. The route graph therefore moves in both directions: upward to 167 and back down to 13.

## 7. h=289: q43 reaches q191

The merged h=289 k215 branch provides q43 under

`p mod11 = 5`,

`p mod31 = 2`.

Three especially useful promotions are:

- q43 -> k19, seed `7*43=301`, promoting q19;
- q43 -> k71, seed `30*43=1290`, promoting q71;
- q23+q43 -> k191 on residues16 and24, seed `30*23*43=29670`, promoting q191.

Thus a character extracted from the composite shift215 can route into a prime destination almost as large as the parent and create q191 as a new conditional source.

## 8. What the fixed point means

The finite closure demonstrates that composite character extraction is not a terminal theorem. It is a recursive source generator.

The exact chain is now

`old positive characters`

`-> routed seed growth`

`-> prime QR or composite Jacobi saturation`

`-> destination miss`

`-> new positive character`

`-> new routed seed growth`.

For the configured v1 mechanism, this recursion is large enough to create 13 new class/source pairs but small enough to exhaust exactly.

That gives CBX a finite, inspectable route grammar instead of an informal list of interesting congruences.

## 9. Research decision after this closure

The next recursive expansion should not simply raise the destination bound and hope for more nodes.

The higher-value extensions are now:

1. propagate the k551 two-character product constraint as a first-class state object;
2. admit genuine three-source recursive saturation while preserving exact ancestry;
3. intersect promoted states with `ROUTED-RESIDUAL-GCD-ATLAS.md`, so support characters and rational-prime allocation are enforced simultaneously;
4. attach `PERIODIC-ROUTE-VALUATION-LADDER.md` phase data to each routed source, so a character edge also knows when its factor must lift to q^2 or higher;
5. test whether any branch becomes internally inconsistent before widening k.

The central design rule is frozen: **no derived character may enter the route graph without its provenance.**

Erdős-Straus remains open.
