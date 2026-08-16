# k=7 universal support and rigid positive k=23 routes

**Status:** exact fixed-shift support theorem and routed affine-coupling atlas  
**Date:** 2026-08-16  
**Primary classifier:** `classify_k7_k23_rigid_support_routes.py`  
**Independent realization regression:** `verify_k7_k23_rigid_support_routes.py`  
**Claim boundary:** all support statements are range-free at their named shifts. The coupled residual equations are necessary conditions for simultaneous misses, not contradictions and not an Erdős-Straus proof.

## 1. Universal Mordell-hard k=7 support theorem

Every Mordell-hard class modulo 840 has class-conditioned seed 2 at k=7. The exact seed-2 closure modulo 7 has

- 9 states;
- 3 miss states;
- one miss center for each hard p residue 1, 2, 4 modulo 7.

All three miss states have the same divisor-residue mask

`{1,2,4} mod7`,

which is exactly the nonzero quadratic-residue subgroup modulo 7.

Therefore:

> For every Mordell-hard prime p, fixed k=7 misses if and only if every prime factor of C7=(p+7)/4 is a quadratic residue modulo 7.

This is stronger than a Legendre-sign statement. The hard mod-840 skeleton already places p in a positive 7-character class, so the actual information at k=7 is factor-support rigidity.

## 2. Exact miss decomposition at k=23

Every Mordell-hard class has seed 6 at k=23. The exact seed-6 closure has

- 49 states;
- 15 misses.

Ten positive p residues modulo 23 are completely rigid:

`2,3,4,6,8,9,12,13,16,18`.

For each of those residues there is exactly one miss state, and its divisor mask is exactly the quadratic-residue subgroup

`{1,2,3,4,6,8,9,12,13,16,18} mod23`.

Hence, on any of those ten residue branches:

> fixed k=23 misses if and only if every prime factor of C23=(p+23)/4 is a quadratic residue modulo 23.

Only three p residues support non-rigid k=23 miss geometry:

- p mod23=1 has three miss states, with mask sizes 9, 11, and 21;
- p mod23=5 has one 19-residue miss mask;
- p mod23=14 has one 19-residue miss mask.

The latter two are exactly the negative-character exits already isolated by the k=19/k=23 routed-bottleneck theorem.

## 3. Routing the rigid k=23 support into lower companions

Positive k=23 character routes factor 23 into a uniquely determined companion. Four destinations are especially useful because the receiving shift already has an exact support theorem.

### 3.1 p mod23=8 routes into k=15

Here

`23 divides C15`.

Every hard class also forces 2|C15, so write

`C15 = 46 A`.

At k=23 write

`C23 = 6 B`.

Since C23-C15=2,

`3B - 23A = 1`.

Thus gcd(A,B)=1.

If k=15 and k=23 both miss, then

- every prime factor of A lies in the Jacobi-plus subgroup `{1,2,4,8} mod15`;
- every prime factor of B is a quadratic residue modulo 23.

The k=15 support statement is exact: the routed seed is 46, the closure has 12 states, and the exact hard-class center leaves one Jacobi-plus miss state for every hard class.

This route is universal across all six Mordell-hard classes.

### 3.2 p mod23=12 routes into k=11

Here

`23 divides C11`.

For h in {169,289,529}, the class-conditioned k=11 seed is 15. Therefore

`C11 = 345 A`

and again

`C23 = 6 B`.

Because C23-C11=3,

`2B - 115A = 1`.

Hence gcd(A,B)=1.

A simultaneous k=11/k=23 miss forces

- A to have only quadratic-residue prime support modulo 11;
- B to have only quadratic-residue prime support modulo 23.

### 3.3 p mod23=4 routes into k=19

Here

`23 divides C19`.

For h=289, the k=19 class seed is 7, so

`C19 = 161 A`.

For h=121, the class seed is 35, so

`C19 = 805 A`.

In both cases C23=6B and C23-C19=1. Therefore

- h=289: `6B - 161A = 1`;
- h=121: `6B - 805A = 1`.

Both equations force gcd(A,B)=1.

The routed k=19 seed closures have 27 states and 9 misses, and every miss mask is exactly the quadratic-residue subgroup modulo 19. Thus simultaneous k=19/k=23 misses force A and B into QR-support semigroups modulo 19 and 23 respectively.

### 3.4 p mod23=16 routes into k=7

Here

`23 divides C7`.

Since every hard class also forces 2|C7,

`C7 = 46 A`.

With C23=6B and C23-C7=4,

`3B - 23A = 2`.

Therefore gcd(A,B) divides 2.

A simultaneous k=7/k=23 miss forces

- every prime factor of A to be a quadratic residue modulo 7;
- every prime factor of B to be a quadratic residue modulo 23.

This route is also universal across all six hard classes.

## 4. What the new atlas changes

The k=23 positive branch is no longer appropriately described as a single Legendre condition. Ten of its eleven positive residue classes are exact prime-support states. Several of those states route factor 23 directly into lower companions whose miss geometry is independently rigid.

The resulting residual equations have tiny right-hand sides:

`3B - 23A = 1`

`2B - 115A = 1`

`6B - 161A = 1`

`6B - 805A = 1`

`3B - 23A = 2`.

They couple coprimality or near-coprimality with two different multiplicative support semigroups.

A quadratic-reciprocity pass over the first equation was checked and does not yield an additional contradiction; the reciprocity identity is compatible with the affine relation. Finite simultaneous realizations also exist. Those negative results are important: the correct next target is a stronger support-allocation or higher-character obstruction, not a claim that these equations are already impossible.

Erdős-Straus remains open.
