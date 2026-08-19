# Source-independent prime divisor-mask repulsion

**Status:** exact finite-group theorem plus hard-class and recursive atlases  
**Date:** 2026-08-16  
**Primary classifier:** `classify_prime_divisor_mask_repulsion.py`  
**Independent verifier:** `verify_prime_divisor_mask_repulsion.py`  
**Depends on:** QR-saturating seed lemma, reciprocity-route barrier, `RECURSIVE-CHARACTER-PROMOTION.md`  
**Claim boundary:** conditional fixed-shift branch pruning only. A positive source must still enter the exact route residue that makes it divide the destination companion. This does not give a universal shift ceiling and does not prove Erdős-Straus.

## 1. One theorem behind the k=23 and h=289,k=19 repulsion laws

Let k be a prime with

`k = 3 mod4`,

and let S be a mandatory divisor of

`C_k = (p+k)/4`.

Write

`A(S,k) = {D mod k : D divides S^2}`.

Assume

`A(S,k) subset QR(k)`.

Now let q be any prime available as a proved positive-character source and route it into C_k. Thus

`q | C_k`.

The reciprocity-route barrier forces

`q mod k in QR(k)`.

Put

`r = q mod k`.

The new mandatory seed is Sq. Its square divisors have residue set

`A(S,k) * {1,r,r^2}`.

Therefore:

> **Prime divisor-mask repulsion theorem.** If
>
> `A(S,k) * {1,r,r^2} = QR(k)`,
>
> then the routed seed Sq is QR-saturating modulo k. Any fixed-k miss after that route requires every prime factor of C_k to be a quadratic residue modulo k. In particular, every ordinary miss center with negative quadratic character is eliminated.

This is source-independent. The source prime matters only through its residue r modulo the destination and through the separate proof that it is a positive source on the branch.

Define the repeller set

`R(S,k) = {r in QR(k) : A(S,k)*{1,r,r^2}=QR(k)}`.

The previously proved k=23 and h=289,k=19 incoming-source theorems are exact special cases of this rule.

## 2. Finite hard-class atlas through k<=5000

Scanning every prime destination

`k<=5000`, `k=3 mod4`,

with the exact hard-class seed

`g_(k,h) = gcd(210,(h+k)/4)`

finds exactly 21 class-seed branches with a nonempty source-independent repeller set.

Of those:

- 16 branches have one or more negative ordinary miss centers, so an incoming repeller source creates genuine branch termination;
- 5 branches already have only positive-character ordinary miss centers, so incoming saturation strengthens support but does not eliminate a negative center.

The negative-center destinations are only

`k = 11,19,23,31,71`.

## 3. k=11: a new universal-looking local repeller geometry

For hard classes

`h in {1,121,361}`,

the k=11 class seed is

`S=3`.

Its divisor-square mask has three residues inside the five-element QR subgroup. The exact repeller set is

`R(3,11) = {3,4,5,9}`.

The ordinary negative miss centers are

`p mod11 in {2,6}`.

Therefore any positive source q routed into C11 with

`q mod11 in {3,4,5,9}`

eliminates both negative k=11 centers on those hard classes.

The only positive residue that does not repel is the identity residue1.

This is the same quotient geometry seen at k=23, but on the order-5 QR group.

## 4. k=19 has two distinct stabilizers

### h=289

The landed h=289 theorem is recovered exactly:

`S=7`,

`A={1,7,11}`,

and

`R(7,19)={4,5,6,9,16,17}`.

These routes eliminate the negative centers

`{2,3,14}`.

### h=1 and h=361

Here the class seed is

`S=5`.

The exact repeller set is much smaller:

`R(5,19)={7,11}`.

Yet either residue QR-saturates the destination and eliminates all six ordinary negative centers

`{2,3,8,10,12,13}`.

Thus the same destination can have different source stabilizers on different hard classes because the mandatory seed occupies a different divisor mask.

## 5. k=23 recovers the landed source-independent theorem

Every hard class has

`S=6`.

The exact repeller set is

`QR(23) - {1}`

or explicitly

`{2,3,4,6,8,9,12,13,16,18}`.

Every such incoming positive route eliminates

`p mod23 in {5,14}`.

The identity source residue1 remains the sharp non-repelling control.

## 6. h=361,k=31 exposes a new terminal center

On h=361,

`S=14`

at k=31. The exact repeller residues are

`{2,4,5,8,10,14,16,20,25,28}`.

The ordinary fixed-shift closure has exactly one negative miss center:

`p mod31 = 26`.

Any positive source routed into C31 through one of those ten residues destroys that center.

The h=169 and h=289 seed10 branches also possess source-independent repeller sets at k31, but their ordinary misses have no negative center. They are support-strengthening branches rather than negative-center terminal branches.

## 7. k=71: the largest current terminal destination

For hard classes

`h in {169,289,529}`,

the k=71 class seed is

`S=30`.

The base divisor mask occupies 25 of the 35 QR residues. Exactly 26 incoming QR source residues enlarge it to all of QR(71):

`{4,5,8,9,10,16,18,20,25,27,29,30,32,37,38,40,43,45,48,49,50,54,57,58,60,64}`.

The ordinary negative miss centers are exactly

`p mod71 in {17,53}`.

So k=71 is a genuine source-independent repulsion destination, not merely a promotion node discovered accidentally by the recursive search.

## 8. Five support-only saturation branches

The class-seed scan also finds five branches whose incoming repeller set is nonempty but whose ordinary miss centers are already entirely positive-character:

- h=169, k31, seed10;
- h=289, k31, seed10;
- h=121, k47, seed42;
- h=289, k47, seed42;
- h=361, k59, seed105.

These are still exact divisor-mask saturation laws. They simply do not terminate a negative-character child, so they are separated from the 16 terminal-capable branches in the classifier output.

## 9. Intersection with the landed recursive character graph

The provenance-aware recursive graph currently has 70 canonical states.

Intersecting every derived positive source in those states with the 16 negative-center repulsion branches gives exactly

- 106 ancestry-compatible state/source/destination repulsion opportunities;
- 17 distinct `(hard class, destination, source prime)` repeller triples.

Ten of those 17 are already represented by the landed k23 and h=289,k19 theorem families.

Seven are new terminal mechanisms.

## 10. Seven new recursive terminal triples

### h=121, destination k=11

The recursive graph creates three sources that can repel both negative k11 centers:

- q53, first available at recursive depth1; route condition `p mod53=42`; seed `3*53=159`;
- q59, first available at depth2; route condition `p mod59=48`; seed `3*59=177`;
- q71, first available at depth2; route condition `p mod71=60`; seed `3*71=213`.

Each source residue modulo11 lies in R(3,11), so the route eliminates

`p mod11 in {2,6}`.

The q53 case is especially clean: q53 itself was extracted from the h=121 recursive k159 Jacobi branch, then feeds back into the small prime destination k11.

### h=169, destination k=71

Two recursively available sources repel the negative k71 centers:

- q37, already present at root depth0 from the merged k111 extraction; route condition `p mod37=3`; seed `30*37=1110`;
- q167, first available at depth2; route condition `p mod167=96`; seed `30*167=5010`.

Each eliminates

`p mod71 in {17,53}`.

Thus the same q37 source that promotes q71 on one route can terminate negative k71 children on another exact route.

### h=289, destination k=71

Two sources provide the analogous terminal mechanism:

- q43, root depth0 from the merged k215 extraction; route condition `p mod43=15`; seed `30*43=1290`;
- q191, first available at depth1; route condition `p mod191=120`; seed `30*191=5730`.

Again both negative k71 centers 17 and53 are eliminated.

## 11. Exact relation to the existing repulsion theorems

This atlas does not retract the specialized k23 or h=289,k19 results.

Those papers remain useful because they give particularly transparent group decompositions, explicit Type-II monomial tables, and realized prime anchors.

The present theorem identifies the common algebraic engine:

`ordinary seed mask A`

`+ incoming positive source residue r`

`-> A{1,r,r^2}`

`-> full QR subgroup`

`-> negative miss centers impossible`.

The specialized results are now named instances of a general repulsion operator.

## 12. Strategic consequence for CBX

The recursive graph should no longer classify every useful positive-source route as a promotion attempt.

A source route can now have at least four exact effects:

1. **promotion** - a saturated miss creates a new positive character;
2. **repulsion** - a saturated route destroys negative miss centers;
3. **residual allocation** - routed residuals become coprime or nearly coprime across shifts;
4. **valuation phase** - repeated routes force q-adic lifts.

The highest-value next engine is therefore a provenance-preserving survivor graph whose edges carry these effects independently and whose nodes are removed immediately when any repulsion rule contradicts their fixed center.

That is a substantially sharper goal than merely increasing the search bound.

Erdős-Straus remains open.
