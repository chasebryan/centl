# Multi-source exact-state repulsion

**Status:** exact finite small-prime atlas plus range-free fixed-state implications  
**Date:** 2026-08-16  
**Primary classifier:** `classify_multisource_exact_state_repulsion.py`  
**Independent verifier:** `verify_multisource_exact_state_repulsion.py`  
**Depends on:** `EXACT-STATE-INCOMING-REPULSION.md`  
**Claim boundary:** this is a residue-pair repulsion atlas. Two distinct proved positive source primes still have to realize the named route residues on the same ancestry-compatible branch. It does not prove every survivor enters such a branch, does not give a universal shift ceiling, and does not prove Erdős-Straus.

## 1. The single-source boundary was not the exact-state boundary

The landed single-source exact-state theorem found two exceptional branches with negative fixed-shift miss centers but no incoming positive source residue that repels them:

- `h=169`, `k=19`, class seed1;
- `h=529`, `k=19`, class seed1.

That statement is exact for **one** incoming routed source.

It is not stable under two routed sources.

Two individually insufficient positive routed factors can jointly alter both the divisor mask and the moving Type-II center enough to eliminate every negative-character miss center while the combined starting mask still remains a proper subset of QR(k).

That is a genuinely multi-source exact-state effect.

## 2. Definition

Fix a prime destination `k=3 mod4` and a class seed `S`.

Let `r1,r2` be quadratic-residue source residues modulo k. They represent two proved positive source primes routed into the same companion.

Starting from the exact seed state `(M,c)`, adjoin each routed factor by

`(M,c) -> (M*{1,r,r^2}, c*r)`.

The residue multiset `{r1,r2}` is a **genuine two-source state-only repeller** when

1. the ordinary seed closure has at least one negative-character miss center;
2. neither r1 nor r2 alone eliminates all negative miss centers;
3. adjoining both residues leaves no negative-character miss center in the complete exact closure;
4. the combined starting divisor mask is still not QR(k).

Condition 4 excludes ordinary two-source QR saturation. The mechanism therefore depends on the exact mask-center correlation.

Residue pairs are multisets. A pair `(r,r)` does not mean the same rational prime is inserted twice. It means two distinct routed source primes may share residue r modulo the destination.

## 3. Exact small-prime atlas

Scanning the same prime destinations as the landed single-source exact-state theorem,

`k in {7,11,19,23,31,47}`,

finds exactly

- **10 class/destination branches** with a genuine two-source state-only repeller;
- **96 residue multisets** in total;
- both of the two former single-source no-repeller branches are resolved.

The 10 branches are

- h1, k19, seed5;
- h169, k19, seed1;
- h361, k19, seed5;
- h529, k19, seed1;
- h1, k31, seed2;
- h121, k31, seed2;
- h1, k47, seed6;
- h169, k47, seed6;
- h361, k47, seed6;
- h529, k47, seed6.

No claim is made here about larger prime destinations.

## 4. The flagship closure at h169/h529, k19

For both h169 and h529,

`C19`

has class seed1.

The ordinary exact closure has

- 439 states;
- 136 misses;
- negative miss centers

`{2,3,8,10,12,13,14}`.

The landed theorem proves that **no single positive incoming source residue** eliminates all seven negative centers.

Nevertheless, exactly ten source-residue multisets do:

```text
(4,9)
(4,16)
(4,17)
(5,6)
(5,16)
(6,9)
(6,16)
(6,17)
(16,17)
(17,17)
```

For every one of these pairs:

- neither residue is a single-source exact repeller;
- the two-source exact closure has no negative miss center;
- the starting divisor mask has size 5 or7, strictly smaller than `|QR(19)|=9`;
- the surviving miss centers are exactly the nine positive-character centers;
- the exact closure has either 41 or70 states and 10 or12 misses.

Therefore, on an ancestry-compatible route carrying any one of these two-source residue multisets,

> a k19 miss forces `(19/p)=+1`, even though neither incoming source does so alone and the combined seed is not QR-saturating.

This closes the two single-source exceptions from `EXACT-STATE-INCOMING-REPULSION.md` at arity two.

## 5. Why this is not disguised QR saturation

Take the flagship pair `(4,9)` at k19.

Starting from seed1, the two routed factors generate only

`{1,4,5,9,11,16,17}`

inside the divisor-square mask.

QR(19) has nine elements, so two residues are still absent.

Yet the complete exact closure has no negative-character miss center.

The reason is the moving Type-II target. The center is multiplied by each routed residue at the same time that the divisor mask grows. The surviving mask-center combinations avoid every negative center even though the static mask alone does not fill the positive subgroup.

Character-only saturation cannot see this.

## 6. Additional pair-only geometries

### k31, seed2

On h1 and h121, twelve genuine pair-only state repellers occur:

```text
(7,7)   (7,18)  (7,19)
(10,10) (10,20) (10,28)
(18,18) (18,19) (19,19)
(20,20) (20,28) (28,28)
```

For example `(7,18)` leaves

- 65 exact states;
- 16 misses;
- all 15 surviving centers positive-character;
- a proper, non-saturating starting mask.

Neither 7 nor18 is a single-source exact repeller on this branch.

### k47, seed6

On h1, h169, h361 and h529, twelve genuine pair-only state repellers occur:

```text
(2,3)   (2,16)
(3,3)   (3,16)  (3,24)
(4,6)   (4,8)
(6,12)  (6,24)
(12,12)
(16,16) (16,24)
```

The representative pair `(2,3)` leaves 97 exact states and24 misses, with all23 surviving centers positive-character and without filling QR(47).

## 7. Strategic consequence

The hierarchy of exact routing mechanisms is now

1. single-source QR/Jacobi saturation;
2. multi-source QR/Jacobi saturation;
3. single-source state-only repulsion;
4. **multi-source state-only repulsion**.

The fourth mechanism is strictly necessary. It resolves the only two small-prime negative-center branches that survived every single positive incoming source.

The next recursive graph should therefore admit state-only promotion edges of arity two, but it must preserve ancestry. A residue pair is not a free class-global source law. Both source characters and both exact route residues have to be established in the same state.

The most valuable immediate intersection is with the 346-state exact-state-augmented character closure. That will determine whether any of the 96 residue multisets are actually realized by two known positive sources on the same recursive branch and whether the resulting k19/k31/k47 character promotions create a new feedback cascade or contradiction.

Erdős-Straus remains open.
