# Exact-state promotion closure

**Status:** exact finite closure of the stated hybrid grammar  
**Date:** 2026-08-16  
**Primary classifier:** `classify_exact_state_promotion_closure.py`  
**Frontier diff:** `analyze_exact_state_promotion_frontier.py`  
**Independent verification:** `verify_exact_state_promotion_closure.py`  
**Depends on:** product-aware class-global character closure, exact-state incoming repulsion atlas  
**Claim boundary:** this closes only the stated class-global/product-aware plus single-source state-only promotion grammar. It does not include branch-local q23 semantics, multi-source state-only repulsion, or persistent surviving mask-center states. No universal shift ceiling and no Erdős-Straus proof.

## 1. Why the 260-state closure was not the end

The landed product-aware class-global closure reaches a fixed point when character promotion is allowed only through complete QR/Jacobi saturation.

`EXACT-STATE-INCOMING-REPULSION.md` proves a strictly finer mechanism. At a prime destination, an incoming positive source can eliminate every negative-character miss center even when the augmented divisor seed does not fill the complete QR subgroup.

On such a route, if the destination still misses, the destination character is forced positive.

That positive character is a new conditional source and must be fed back into the recursive graph.

This branch performs exactly that feedback step.

## 2. Model scope

The state is the landed product-aware state

`(hard class, fixed p mod q residues, individual characters, GF(2) product constraints)`.

Two transition families are enabled:

1. ordinary QR/Jacobi saturation transitions from the landed product-aware closure;
2. single-source state-only exact-repeller transitions from the landed small-prime exact-state atlas.

A state-only transition is admitted only when

- the source character is already known positive in that state;
- the route residue is ancestry-compatible with all existing fixed residues;
- the source residue modulo the destination belongs to the proved state-only repeller set;
- the destination character is not already known negative.

If the destination character is unknown, a destination miss promotes it to `+1` and the route residue is retained in the child state.

The model intentionally excludes

- branch-local source refinements from `RECURSIVE-CHARACTER-PROMOTION.md` unless they are already present in the class-global state;
- multi-source state-only exact repulsion;
- carrying the exact surviving `(mask,center)` state into descendants;
- residual-gcd and periodic-valuation constraints as active transition rules.

## 3. Exact fixed point

The re-closed graph through `k<=5000` has

- **8 roots**;
- **346 canonical states**;
- **maximum depth 8**;
- **3,775 ordinary saturation transitions**;
- **119 exact-state transition opportunities**;
- **23 exact-state extraction events**;
- **96 exact-state transitions whose destination character was already positive**;
- **0 exact-state sign contradictions**;
- **0 product-constraint contradictions**;
- **0 characters derived from the lone product equation**;
- **0 hidden source subsets of arity four or larger under the parent completeness guard**.

The depth frontier is

```text
depth  states processed  new states
0      8                 28
1      28                64
2      64                84
3      84                76
4      76                47
5      47                26
6      26                12
7      12                1
8      1                 0
```

The queue therefore exhausts exactly at depth 8.

## 4. Exact state-only promotion geometries used by the closure

Although 23 extraction events occur across different ancestry states, there are only three distinct state-only source/destination promotion triples:

- `h=169`, `q17 -> k47`;
- `h=169`, `q37 -> k47`;
- `h=529`, `q17 -> k47`.

The two source residues at k47 are

`17 mod47 = 17`,

`37 mod47 = 37`.

Both lie in the proved state-only k47 repeller set.

The route residues of p at the source moduli are

`p mod17 = -47 mod17 = 4`,

`p mod37 = -47 mod37 = 27`.

Both are positive-character residues, as required by the source theorems.

## 5. Independent local k47 check

The verifier rebuilds the k47 state space with explicit frozensets of divisor residues rather than the classifier's bitmask representation.

For class seed 6 at k47:

- ordinary closure: `1079` states;
- ordinary misses: `196`;
- ordinary negative miss centers:

`5,10,13,19,20,26,29,30,33,38,40`.

Adjoining either source residue 17 or 37 gives

- `97` exact states;
- `24` misses;
- `23` surviving miss centers;
- **zero negative-character miss centers**;
- seed mask size `21`, strictly smaller than `|QR(47)|=23`.

Thus these are genuinely state-only promotions. They do not secretly reduce to QR saturation.

## 6. What the feedback adds beyond the 260-state parent

The parent product-aware closure has 260 states. Exact-state feedback raises this to 346.

The source alphabet grows by one prime, q251, but alphabet size alone hides the more important class-specific changes.

Exactly three new hard-class/source pairs appear:

- `h=169 -> q79`;
- `h=169 -> q251`;
- `h=529 -> q47`.

The q47 pair is the direct h529 q17 -> k47 state-only promotion.

The q79 and q251 pairs are downstream ordinary saturation consequences unlocked by the new exact-state ancestry.

## 7. New h169 q79 promotion

At prime destination k79 the h169 class seed is

`S0=2`.

The newly ancestry-compatible routed sources are

- q11 with `p mod11=9`;
- q31 with `p mod31=14`;
- q167 with `p mod167=88`.

All are exactly the route residues `p=-79 mod q`.

The combined seed is

`S = 2*11*31*167 = 113894`.

Its square-divisor residues fill QR(79).

No proper routed subset of `{11,31,167}` QR-saturates k79.

Therefore this is a genuine three-source promotion:

> on the exact ancestry branch where all three routes are present, a k79 miss forces `(79/p)=+1`.

This is the first new h169/q79 source state exposed by the exact-state feedback grammar.

## 8. New h169 q251 promotion

At prime destination k251 the h169 class seed is

`S0=105`.

The new compatible route pair is

- q13 with `p mod13=9`;
- q17 with `p mod17=4`.

Again these are exactly `-251 mod13` and `-251 mod17`.

The combined seed

`S = 105*13*17 = 23205`

fills QR(251).

Neither `105*13` nor `105*17` saturates.

Hence

> on this exact ancestry branch, a k251 miss forces `(251/p)=+1`.

q251 is therefore the only new prime added to the class-global source alphabet by this closure.

## 9. No contradiction appears

The state-only promotions enlarge the exact branch graph, but they do not create a sign conflict.

The complete run contains

- no destination already known negative on an admitted state-only route;
- no GF(2) product-equation contradiction;
- no negative extracted character;
- no Type-I contradiction generated by the parent saturation engine.

Thus the state-only feedback mechanism is real and productive, but it does not close Erdős-Straus at the character level.

This is another method boundary.

## 10. What must become stateful next

The next useful object is no longer just a character assignment.

`EXACT-STATE-INCOMING-REPULSION.md` succeeded precisely because the full `(mask,center)` state contains information that the character projection erases. This closure then throws that finer state away after promoting the destination sign.

The natural next engine should therefore preserve, per active destination,

- the surviving divisor mask;
- the exact center class;
- source provenance;
- residual-gcd allocation constraints;
- periodic valuation phase data;
- product-character equations.

The immediate theorem question is whether two individually non-saturating routed sources can jointly eliminate every negative exact miss center even when their combined seed still does not fill QR/Jacobi support.

That is **multi-source state-only repulsion**. It should be attacked before pretending the 346-state character projection is the final recursive frontier.

Erdős-Straus remains open.
