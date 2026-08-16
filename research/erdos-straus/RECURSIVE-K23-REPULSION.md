# Recursive incoming-source repulsion at k=23

**Status:** exact application of the landed k23 repulsion theorem to the recursive character graph  
**Date:** 2026-08-16  
**Classifier:** `classify_recursive_k23_repulsion.py`  
**Depends on:** `RECURSIVE-CHARACTER-PROMOTION.md`, `K23-INCOMING-SOURCE-REPULSION.md`  
**Claim boundary:** conditional branch pruning only. This does not prove that every survivor routes one of these sources into C23 and does not prove Erdős-Straus.

## 1. The landed repulsion theorem becomes recursive

The k23 incoming-source theorem says:

> if a positive-character prime q routes into C23 and q mod23 is a nonidentity quadratic residue, then the mandatory seed 6q QR-saturates modulo23 and the two ordinary negative k23 miss centers p mod23=5 and14 are impossible.

The provenance-aware recursive closure manufactures new positive-character sources. The natural question is therefore exact:

> which recursively extracted or promoted sources can, without violating their accumulated residue ancestry, be routed into C23 as a nonidentity positive source?

This is a state question, not merely a congruence question. A source that was earned under one exact p mod q value cannot later be rerouted through an incompatible value.

## 2. Exact finite result

Apply the repulsion theorem to all 70 canonical states in the configured recursive closure.

There are exactly

- 31 state/source repulsion opportunities;
- 8 distinct `(hard class, recursive source)` pairs that realize such an opportunity;
- opportunity-depth histogram `2,4,10,6,6,3` for recursive depths 0 through5.

The eight distinct repelling source classes are:

- h=121, q13, available already at root depth0, requiring `p mod13=3` to route into C23;
- h=121, q59, minimum depth2, requiring `p mod59=36`;
- h=121, q71, minimum depth2, requiring `p mod71=48`;
- h=169, q13, minimum depth2, requiring `p mod13=3`;
- h=169, q71, minimum depth1, requiring `p mod71=48`;
- h=169, q167, minimum depth2, requiring `p mod167=144`;
- h=289, q13, available already at root depth0, requiring `p mod13=3`;
- h=289, q71, minimum depth1, requiring `p mod71=48`.

Every listed source has a nonidentity QR residue modulo23 and an ancestry-compatible positive route into C23.

## 3. Why q13 is only the first instance

The merged composite extraction theorem already produced q13 on h=121 and h=289. Since

`13 mod23 = 13`,

and13 is a nonidentity quadratic residue modulo23, the route condition

`p mod13 = -23 mod13 = 3`

activates the repulsion theorem. This recovers the previously observed q13 elimination of the two negative k23 centers.

The recursive graph shows that this is not special to q13.

## 4. q71 is a recurrent repeller

The promotion closure creates q71 on both h=169 and h=289.

Since

`71 mod23 = 2`,

the source is a nonidentity QR modulo23. Routing q71 into C23 requires

`p mod71 = -23 mod71 = 48`.

On an ancestry-compatible q71 state, that single route makes seed

`6*71 = 426`

QR-saturating modulo23. Therefore neither p mod23=5 nor p mod23=14 can survive that branch.

This links the recursive q37/q43 promotion machinery directly to elimination of the exceptional k23 geometry.

## 5. q59 and q167 extend the same mechanism

On h=121 the recursive graph promotes q59. Since

`59 mod23 = 13`,

it is another nonidentity repelling source. The required route residue is

`p mod59 = 36`.

On h=169 the graph promotes q167. Since

`167 mod23 = 6`,

it also repels the negative k23 centers when

`p mod167 = 144`.

Thus recursion creates progressively larger moduli that can terminate an old low-shift exceptional branch.

## 6. What is and is not eliminated

This theorem does **not** say that every q13, q59, q71, or q167 source automatically divides C23.

It says that once the exact route residue into C23 is imposed and is compatible with the source's accumulated ancestry, the two negative k23 miss centers are impossible.

The positive k23 residue branches remain possible, as does the sharp identity incoming residue q mod23=1.

The result is therefore a branch-pruning rule for a future survivor tree, not a universal k23 closure.

## 7. Strategic consequence

CBX now has three different recursive edge effects that should remain separate in code and proofs:

1. **promotion edges** create a new positive character;
2. **repulsion edges** terminate specific exceptional miss centers without necessarily creating a new character;
3. **valuation edges** predict where a routed source must lift from q to q^2 or higher.

The next combined search should attach these edge types to the same provenance state and ask whether a branch is killed before another promotion is needed.

That is more valuable than blindly increasing the destination bound: the graph now has actual terminal edges.

Erdős-Straus remains open.
