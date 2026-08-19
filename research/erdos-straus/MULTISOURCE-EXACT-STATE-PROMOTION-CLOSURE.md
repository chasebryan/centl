# Multi-source exact-state promotion closure

**Status:** exact finite closure of the stated hybrid grammar  
**Date:** 2026-08-16  
**Primary classifier:** `classify_multisource_exact_state_promotion_closure.py`  
**Independent verification:** `verify_multisource_exact_state_promotion_closure.py`  
**Depends on:** `EXACT-STATE-PROMOTION-CLOSURE.md`, `MULTISOURCE-EXACT-STATE-REPULSION.md`  
**Claim boundary:** this is the class-global/product-aware character projection augmented by single-source and genuine two-source state-only exact promotion. It still does not retain full surviving mask-center states, branch-local q23 source semantics, residual-gcd constraints, or periodic valuation phases as active state. No universal shift ceiling and no Erdős-Straus proof.

## 1. Why re-close again

The landed 346-state closure admits single-source state-only exact repulsion as a character-promotion rule.

`MULTISOURCE-EXACT-STATE-REPULSION.md` proves that this is not the end of the exact-state hierarchy. Two individually insufficient positive incoming sources can jointly eliminate every negative exact miss center while their combined divisor mask still fails to fill QR(k).

The recursive question is therefore:

> do any of those genuine pair repellers actually occur inside one ancestry-compatible character state, and if so, what do they add?

This branch answers that question for the same class-global/product-aware grammar.

## 2. Pair transition semantics

A two-source state-only promotion edge requires

1. two **distinct** source primes already known positive in the same state;
2. both source routes are compatible with every fixed residue already carried by the state;
3. the multiset of source residues modulo the destination is one of the proved genuine pair-repeller multisets;
4. the destination is not already known negative.

Both route residues are inserted into the child state's fixed ancestry before the destination character is promoted.

A repeated residue type such as `(17,17)` therefore requires two distinct source primes whose residues modulo the destination are both17. One source is never counted twice.

## 3. Exact fixed point

Re-closing through `k<=5000` gives

- **8 roots**;
- **380 canonical states**;
- **maximum depth 8**;
- **4,142 ordinary saturation transitions**;
- **149 single-source exact-state transition opportunities**;
- **76 two-source exact-state transition opportunities**;
- **18 two-source extraction events**;
- **58 two-source routes whose destination character was already positive**;
- **0 two-source sign contradictions**;
- **0 product-constraint contradictions**;
- **0 characters derived from the product equation**;
- **0 hidden saturation qualifiers of source arity four or larger under the parent completeness guard**.

The depth frontier is

```text
depth  states processed  new states
0      8                 28
1      28                65
2      65                90
3      90                90
4      90                59
5      59                27
6      27                12
7      12                1
8      1                 0
```

The queue again exhausts at depth8.

## 4. What changed relative to the 346-state parent

The parent has346 canonical states. Pair feedback adds34 more.

But the positive source alphabet is unchanged:

```text
11,13,17,19,23,29,31,37,43,47,53,71,79,83,107,109,127,131,151,167,191,251,271,383,971
```

More strongly, the set of positive `(hard class, source prime)` pairs is also unchanged.

Thus the new 34 states are not new character facts. They are new **ancestry facts**: additional compatible combinations of exact route residues and already-known characters.

This is the central interpretation of the closure.

## 5. Only two distinct pair promotions are realized

Although18 pair extraction events occur across different ancestry states, they reduce to exactly two distinct source-pair/destination geometries:

- `h=169`, `q17 + q23 -> k19`;
- `h=169`, `q23 + q47 -> k19`.

No h529 pair promotion, k31 pair promotion, or k47 pair promotion from the 96-pair theorem is realized as an unknown-character extraction inside this class-global closure.

The same two h169 pair routes also occur later in states where q19 is already known positive, accounting for the distinct known-plus pair geometries.

No pair route finds a destination character already known negative.

## 6. h169 q17+q23 -> k19

The source route requirements are

`p mod17 = -19 mod17 = 15`,

`p mod23 = -19 mod23 = 4`.

Both are positive-character source residues.

Modulo the destination k19, the routed primes are

`17 mod19 = 17`,

`23 mod19 = 4`.

Thus the incoming exact-state residue multiset is

`(4,17)`,

one of the ten genuine h169/h529 k19 pair repellers.

Starting from class seed1, the two-source divisor mask is

`{1,4,6,7,11,16,17}`.

It has size7, not the full QR(19) size9.

Yet the complete exact closure has

- 41 states;
- 10 misses;
- nine surviving centers

`{1,4,5,6,7,9,11,16,17}`;

- zero negative-character centers.

Therefore, on this exact ancestry branch,

> if k19 still misses, `(19/p)=+1`.

The promotion is state-only, not QR saturation.

## 7. h169 q23+q47 -> k19

The source route requirements are

`p mod23 = 4`,

`p mod47 = -19 mod47 = 28`.

Both are positive-character residues.

Modulo19,

`23 mod19 = 4`,

`47 mod19 = 9`.

The pair is therefore

`(4,9)`.

Its starting mask is

`{1,4,5,9,11,16,17}`,

again size7 rather than9.

The exact closure is again

- 41 states;
- 10 misses;
- the same nine positive surviving centers;
- no negative center.

So a k19 miss on this branch again promotes `(19/p)=+1` without QR saturation.

## 8. Why this does not create a new source prime

q19 is already present elsewhere in the landed class-global character graph on h169.

The pair edges therefore do not enlarge the source alphabet. Their contribution is to prove q19 positive on **additional, more constrained ancestry states** where the ordinary character-saturation grammar did not establish it by the same path.

This distinction matters for the next research engine. A character-only state canonicalizes these branches together once their sign assignments match, but the exact masks and route ancestry are not equivalent.

## 9. The character projection has reached another boundary

The progression is now

- 260 states: product-aware character saturation;
- 346 states: add single-source state-only promotion;
- 380 states: add genuine two-source state-only promotion.

Each richer exact-state rule increases the number of arithmetic ancestry states, but the last step adds **zero** new class/source character pairs and **zero** contradictions.

This is strong evidence that further projection onto character signs alone is throwing away the object that is now doing the work.

The next state should preserve the surviving exact fixed-shift object itself.

## 10. Next target: persistent survivor signatures

For a routed destination, instead of storing only

`(k/p)=+1`,

store a canonical survivor signature containing at least

- the exact surviving `(mask,center)` states or a lossless compressed equivalent;
- the routed source ancestry that generated the signature;
- residual-support/gcd relations from `ROUTED-RESIDUAL-GCD-ATLAS.md`;
- periodic valuation phases from `PERIODIC-ROUTE-VALUATION-LADDER.md`;
- individual characters and GF(2) product constraints.

The two realized k19 pair routes are an ideal first prototype: each reduces the huge ordinary state space to only41 exact states and10 misses, with the same nine centers but different seven-element masks.

The immediate theorem question is no longer merely whether k19 has positive character. It is:

> can the surviving mask-center signatures from these two ancestry geometries be intersected with residual coprimality or a deterministic valuation lift so that the later Type-II target becomes forced?

That is the bridge from character routing back to the k107 phenomenon.

Erdős-Straus remains open.
