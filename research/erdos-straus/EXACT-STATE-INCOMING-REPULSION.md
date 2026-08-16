# Exact-state incoming-source repulsion beyond QR saturation

**Status:** exact finite-state theorem and small-prime atlas  
**Date:** 2026-08-16  
**Primary classifier:** `classify_exact_state_incoming_repulsion.py`  
**Independent verifier:** `verify_exact_state_incoming_repulsion.py`  
**Depends on:** exact divisor-square fixed-shift state model, reciprocity-route barrier, source-independent QR-saturation repulsion, product-aware character closure  
**Claim boundary:** this theorem scans prime destinations `k in {7,11,19,23,31,47}`. It proves conditional character promotion on exact incoming-source routes; the route residue must still be realized on the same branch and positive-character miss states may remain. It is not a universal shift ceiling and does not prove Erdős-Straus.

## 1. Why full QR saturation is sufficient but not necessary

The source-independent repulsion theorem in `PRIME-DIVISOR-MASK-REPULSION.md` uses a strong sufficient condition.

Let S be the mandatory seed at prime destination k and let q be a positive-character source routed into C_k. If divisors of

`(S q)^2`

fill all of QR(k), then every negative-character miss center disappears.

That criterion deliberately forgets the exact relation between the divisor mask and the Type-II center.

The exact fixed-shift state is finer.

Write a state as

`(M,c)`,

where M is the set of divisor-square residues currently available modulo k and c is the multiplicative center representing C_k modulo k.

Adjoining one prime factor with residue a applies

`T_a(M,c) = ( M * {1,a,a^2}, c a )`.

A state hits if either

- the fixed Type-I target `-1/4` lies in M; or
- the moving Type-II target `-c` lies in M.

Thus a route can eliminate every negative miss center even when the augmented mask is still a proper subset of QR(k). The reason is that the mask and the moving center are correlated.

This is invisible to character-only saturation.

## 2. Exact incoming-state repeller definition

Fix prime k, hard class h, and class seed

`S = gcd(210,(h+k)/4)`.

Let C(S,k) be the complete exact state closure generated from the seed under all unit-factor transitions, and let M(S,k) be its miss states.

Now let a positive source q route into C_k and put

`r = q mod k`.

The mandatory routed seed state is obtained by one exact transition T_r applied to the ordinary seed state. Close that augmented state under all remaining unit factors.

Call r an **exact-state repeller** if

- the ordinary closure has at least one negative-character miss center; and
- the augmented closure has no negative-character miss center.

If, additionally, the augmented seed divisor mask is not all of QR(k), call r a **state-only repeller**.

On a state-only repeller route, a k miss still forces

`p mod k in QR(k)`,

hence for the Mordell-hard prime skeleton p=1 mod4,

`(k/p)=+1`,

but this conclusion was obtained without QR-saturating the augmented seed.

## 3. Exact atlas through k=47

The classifier scans

`k = 7,11,19,23,31,47`

across all six Mordell-hard classes.

The exact result is:

- 21 class/destination branches have ordinary negative-character miss centers;
- 19 of those admit at least one exact incoming repeller;
- 156 hard-class/source-residue repeller pairs occur in total;
- 92 are already explained by full QR saturation;
- 64 are genuinely state-only repeller pairs;
- those 64 occur on exactly 9 class/destination branches.

The only negative-center branches in this range with no exact positive incoming repeller are

- h=169, k19, seed1;
- h=529, k19, seed1.

## 4. k=19, seed5: two extra repellers

For h=1 and h=361 at k=19, the ordinary seed is

`S=5`.

The exact ordinary closure has

- 132 states;
- 44 miss states;
- negative centers

`{2,3,8,10,12,13}`.

Full QR saturation explains incoming source residues

`7,11`.

Exact-state analysis adds two more:

`6,16`.

For either r=6 or16, the routed seed does not QR-saturate. Nevertheless the exact augmented closure has only

- 10 miss states;
- 9 distinct centers;
- zero negative centers.

So a miss on either route forces `(19/p)=+1` by exact mask-center geometry.

## 5. k=31, seed2: repulsion with no saturation at all

For h=1 and h=121 at k=31,

`S=2`.

The ordinary closure has

- 760 states;
- 118 misses;
- ten negative centers

`{3,6,11,12,13,17,21,22,24,26}`.

No incoming residue in the new four-element set below QR-saturates the seed:

`{5,9,14,25}`.

Yet every one eliminates all ten negative centers.

- r=5 or25 leaves 18 miss states;
- r=9 or14 leaves 21 miss states;
- every surviving miss center is one of the 15 quadratic residues modulo31.

This is a pure exact-state promotion mechanism with no full-QR saturation explanation.

## 6. h=361, k=31: four more residues beyond saturation

On h=361 the k31 seed is

`S=14`.

The ordinary closure has 23 misses and one negative center:

`p mod31 = 26`.

Ten source residues were already known to repel that center by QR saturation.

Exact-state analysis adds

`7,9,18,19`.

None QR-saturates the augmented seed.

- r=7 or9 leaves 18 positive-center misses;
- r=18 or19 leaves 16 positive-center misses.

So the exact repeller set is strictly larger than the saturation repeller set even on a destination where a saturation theorem already exists.

## 7. k=47, seed6: the large collapse

The strongest new geometry occurs at k=47 on hard classes

`h in {1,169,361,529}`.

The ordinary class seed is

`S=6`.

Its exact closure has

- 1,079 states;
- 196 miss states;
- eleven negative centers

`{5,10,13,19,20,26,29,30,33,38,40}`.

No incoming source residue listed below QR-saturates the augmented seed.

Nevertheless all twelve residues

`{7,9,14,17,18,21,25,27,28,34,37,42}`

eliminate every negative center.

For residues

`7,14,17,18,25,27,34,37`,

the augmented closure has only 24 miss states.

For

`9,21,28,42`,

it has 26 miss states.

In every case there are exactly 23 surviving centers, all quadratic residues modulo47.

Thus an incoming positive source can collapse 196 ordinary misses to roughly two dozen positive-center states without filling QR(47).

That is the cleanest current example of information carried by the exact mask-center pair and lost by character saturation.

## 8. Intersection with the landed product-aware character graph

The landed class-global product-aware character closure has 260 canonical states.

Intersecting those states with the 64 state-only repeller cases gives exactly

- 27 ancestry-compatible state/source/destination opportunities;
- 3 distinct repeller triples;
- 0 character contradictions.

The three promotion triples are

- h=169, q17 -> k47;
- h=169, q37 -> k47;
- h=529, q17 -> k47.

The h=169 q37 -> k47 triple also occurs on later states where q47 has already become positive through other character-saturation ancestry; those occurrences are compatible rather than new promotions.

The exact route residues are:

- q17 -> k47 requires `p mod17=4`, with `17 mod47=17`;
- q37 -> k47 requires `p mod37=27`, with `37 mod47=37`.

Both 17 and37 are state-only repeller residues at the k47 seed6 geometry.

Therefore, on the named branches, if k47 still misses, the exact state theorem forces

`(47/p)=+1`.

This creates q47 as a conditional positive source on h=169 and h=529 without invoking QR saturation at k47.

## 9. Why this changes the recursive program

The previous character grammar could create a new source only after a seed filled a complete quadratic/Jacobi plus kernel.

That is no longer the complete promotion rule.

CBX now has a second source generator:

`positive routed source`

`-> exact mandatory mask-center state`

`-> all negative centers eliminated`

`-> destination miss implies positive destination character`

`-> new source`

without requiring full kernel saturation.

The immediate next experiment is therefore to feed the newly available h=169/h=529 q47 source back into the recursive route graph and ask whether exact-state promotion creates additional sources or terminal branches that the 260-state character closure could not reach.

That follow-on must preserve the distinction between class-global and branch-local source provenance.

## 10. Method boundary

This theorem does not yet use the entire exact miss-state identity as recursive state data. It uses one exact consequence: whether negative centers remain after a mandatory incoming source.

The next stronger survivor engine should preserve the surviving exact mask-center state itself, not only the promoted character sign.

That is where residual gcd allocation, periodic valuations, and exact Type-II target formation can finally operate on the same branch state.

Erdős-Straus remains open.
