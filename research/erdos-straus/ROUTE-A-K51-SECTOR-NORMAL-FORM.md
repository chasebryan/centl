# Route-A k51 sector normal form

**Status:** exact route-local module inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Verifier:** `verify_route_a_k51_sector_normal_form.py`  
**Depends on:** landed Route-A ancestry, k51 exact signed-box closure, route-conditioned phase state, and ten-cofactor support separation  
**Claim boundary:** exact theorem on realized Route A at k51. This compresses the fixed 14-state endpoint family but does not yet eliminate all five residual correlation modes. It is not a closed decomposition method and not an Erdős–Straus proof.

## 1. Route A fixes the k51 arithmetic

On realized Route A,

`t = 199 + 391u`.

Write

`C51 = (p+51)/4 = 55 + 210t = 5K`,

with

`K = 11 + 42t = 8369 + 16422u`.

Then

`K = 5 mod51`

and therefore

`C51 = 25 mod51`.

Since `K=5 mod51`, K is coprime to both3 and17. Every rational prime factor of K is therefore a unit modulo51.

The exact k51 targets at this Route-A center are fixed:

```text
Type I target  = -4^(-1) = 38 mod51
Type II target = -25      = 26 mod51.
```

The mandatory seed factor5 has square-divisor mask

`M5={1,5,25}`

with center5.

The complete exact seed-5 residue closure contains

```text
1403 states.
```

At final center25 there are exactly

```text
14 misses.
```

The purpose of this module is to explain nine of those fourteen by two exact structural sectors and isolate the remaining five as a finite correlation residual.

## 2. Hits are absorbing and factor order is irrelevant

For a prime-factor occurrence of K with residue r modulo51, the exact transition is

`(M,c) -> (M*{1,r,r^2}, c*r)`.

These transitions commute.

A hit is also forward invariant:

- a Type-I divisor remains a divisor after adjoining another factor;
- if d is Type II for C, then after adjoining r, `dr` is Type II for `Cr`.

Therefore factor occurrences may be reordered freely for structural classification, and any finite killer pattern remains fatal after all later factors are inserted.

## 3. Six single-occurrence killer residues

Starting from the mandatory seed state, exactly six unit residues cause an immediate signed-box hit after one dynamic prime-factor occurrence:

`X51={10,26,28,38,46,50}`.

Their exact mechanisms are:

```text
r=10 -> Type II
r=26 -> Type I
r=28 -> Type I
r=38 -> Type I
r=46 -> Type II
r=50 -> Type II.
```

Hence every Route-A k51 miss obeys the range-free prime-support restriction

`q mod51 notin X51`

for every rational prime q dividing K.

Multiplicity is literal. If a prime in one of these residue classes occurs even once, k51 hits.

## 4. Character sector H51

Let

`chi3(r)=(r/3)`

and

`chi17(r)=(r/17)`

be the quadratic characters on units modulo3 and17.

Define the index-two subgroup

`H51={r in (Z/51Z)^* : chi3(r) chi17(r)=+1}`.

Explicitly,

`H51={1,4,5,11,13,14,16,19,20,23,25,29,41,43,44,49}`.

The mandatory seed5 lies in H51.

Both exact targets lie outside H51:

`38 notin H51`,

`26 notin H51`.

### Character theorem

If every rational prime factor q of K lies in H51, then every divisor residue of

`C51^2=(5K)^2`

lies in H51, while neither exact target does.

Therefore

`all q|K in H51 => k51 miss`.

Conversely, if the final divisor mask is contained in H51, then every q|K lies in H51 because each q itself is a divisor of `C51^2`.

Thus

`final mask subset H51 <=> all q|K in H51`.

At Route-A center25 the H51-only closure has exactly six endpoint masks, and all six are misses.

So six of the fourteen Route-A miss masks are explained exactly by one index-two character condition.

## 5. The independent mod-17 safe sector

Reduce the exact k51 state modulo17.

The seed is

`{1,5,8}`

with center5.

Because `K=5 mod17`, the final center is

`5*5=8 mod17`.

The two k51 targets reduce to

```text
38 -> 4 mod17
26 -> 9 mod17.
```

The complete exact modulo17 closure has

```text
88 states.
```

At final center8 there are six endpoint states, but only two omit both4 and9. Their masks are

```text
S5 = {1,5,6,8,13}
S9 = {1,2,5,6,7,8,13,14,15}.
```

Any full modulo51 state whose mod17 projection is S5 or S9 is automatically a k51 miss, regardless of its mod3 fiber structure.

## 6. Exact mod-17 factor grammar

Prime-factor occurrences are counted with multiplicity.

Modulo17, the quadratic residues are

`{1,2,4,8,9,13,15,16}`

and the nonresidues are

`{3,5,6,7,10,11,12,14}`.

Since `K=5 mod17` is a nonresidue, the number of nonresidue prime-factor occurrences in K is odd.

Starting from the seed and inserting only nonresidue occurrences, the exact target-avoiding counts are

```text
0 occurrences : 1 skeleton
1 occurrence  : 4 skeletons
2 occurrences : 3 skeletons
3 occurrences : 2 skeletons
4 occurrences : 1 skeleton
5 occurrences : 0 skeletons.
```

The unique size-4 target-avoiding skeleton is

`(5,5,5,7)`.

It cannot occur in a Route-A factorization of K because it contains an even number of nonresidue occurrences, while `K=5 mod17` is itself a nonresidue and therefore requires odd nonresidue parity.

The arithmetically admissible odd skeletons are

```text
size 1: (5), (6), (7), (10)
size 3: (5,5,5), (5,5,7).
```

Every size-5 nonresidue multiset hits. Since hits are absorbing, every larger nonresidue skeleton hits as well.

Closing the admissible odd skeletons under all quadratic-residue occurrences leaves only five target-avoiding states. Enforcing the fixed final product `K=5 mod17` reduces the accepted factorizations to three exact patterns.

### S17 grammar

After deleting every prime-factor occurrence congruent to1 modulo17, the remaining occurrence multiset of K is exactly one of

```text
{5}
{5,5,7}
{7,8}.
```

Equivalently:

1. one occurrence5 mod17, all others1;
2. two occurrences5 and one occurrence7 mod17, all others1;
3. one occurrence7 and one occurrence8 mod17, all others1.

### Theorem

The divisor mask of `C51^2` omits both target residues modulo17 if and only if K satisfies the S17 grammar above.

This is exact and range-free.

## 7. How much of the 14-state family is now explained

Among the fourteen exact Route-A center25 miss masks:

```text
6 are H51 character-sector masks
5 are S17 projection-safe masks
2 lie in both sectors.
```

Therefore

`6 + 5 - 2 = 9`

of the fourteen masks are explained by the union

`H51 OR S17`.

Only five miss masks remain outside both structural sectors.

Call them the correlation residual

`CORR5`.

Their exact masks are:

### C18

`{1,2,4,5,7,10,11,13,16,23,25,29,31,32,35,37,43,47}`

### C19

`{1,2,4,5,7,13,16,19,20,22,23,25,31,32,35,40,44,47,49}`

### C22

`{1,2,4,5,7,8,13,14,16,19,20,22,23,25,31,32,35,40,41,44,47,49}`

### C24a

`{1,2,4,5,7,8,10,13,14,16,19,20,22,23,25,31,32,35,37,40,41,44,47,49}`

### C24b

`{1,2,4,5,7,10,11,13,16,19,20,22,23,25,29,31,32,35,37,40,43,44,47,49}`

These five are genuine CRT-correlation misses: their mod17 projections no longer exclude both targets, and their full masks are not contained in H51. They survive only because the dangerous mod17 target fibers occur with the wrong mod3 sign.

## 8. CORR5 is a real finite residual, not a ghost

Each correlation mask is reachable from the exact seed by a short dynamic factor-residue skeleton whose product is5 modulo51:

```text
C18  : (37,47)
C19  : (32,40)
C22  : (5,8,32)
C24a : (7,7,23)
C24b : (5,37,40).
```

These are canonical short reachability witnesses, not complete factor grammars.

The next theorem target is to replace CORR5 by a small exact occurrence grammar, just as the Route-B THIN state was reduced to `{9}` or `{3,3}`.

## 9. Coupling to the separated support ladder

The route equations include

`5K - 391R = 8`.

Since R and K are odd,

`gcd(R,K)=1`.

The landed ten-cofactor theorem strengthens this: the odd support of K is disjoint from every other dynamic cofactor reservoir through k55.

Thus the H51/S17/CORR5 conditions must be paid for using a genuinely independent prime-support reservoir. Route A cannot recycle odd primes already serving k19, k23, k27, k31, k35, k39, k43, k47, or k55 survivor constraints.

## 10. Route-A normal form

The fixed 14-state endpoint family has now become

```text
Route A + k51 miss
    |
    +-- H51 character sector
    |      every q|K has chi3(q)chi17(q)=+1
    |
    +-- S17 projection-safe sector
    |      non-1 occurrence multiset mod17 is
    |      {5} or {5,5,7} or {7,8}
    |
    `-- CORR5
           one of five exact CRT-correlation masks.
```

The first two sectors overlap in two endpoint masks. Their union accounts for nine of the fourteen exact misses.

This is the Route-A analogue of the Route-B symbolic compression, but it is not yet as complete because CORR5 still lacks its final occurrence grammar.

## 11. Next theorem target

Attack CORR5 directly in the CRT group

`(Z/51Z)^* ~= C2 x C16`.

The desired result is one of:

1. a finite occurrence-skeleton grammar for the five residual masks;
2. a character/fiber theorem collapsing several CORR5 masks at once;
3. an incompatibility between CORR5 and the landed k31/k35 or phase-support state.

Any of these would convert Route A from a sector normal form into a fully symbolic route-local transition state.

Erdős–Straus remains open.
