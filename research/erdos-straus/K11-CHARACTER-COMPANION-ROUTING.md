# Character-to-companion routing from the rigid k=11 branch

**Status:** exact arithmetic routing theorem plus exact routed fixed-shift state closures  
**Date:** 2026-08-16  
**Depends on:** `SMALL-PRIME-CLASS-CHARACTER-ATLAS.md`; `MORDELL-HARD-CLASS-CONDITIONED-SEED-LAW.md`; `SIX-COMPANION-RESIDUAL-WHEEL.md` if present under the current research naming; fixed-shift Lane-I divisor-square equivalence  
**Primary classifier:** `classify_k11_routed_companion_states.py`  
**Independent realization regression:** `verify_k11_routed_companion_states.py`  
**Claim boundary:** the routing lemma is exact and range-free, and the routed closures are exact at their fixed shifts. This does not give a universal fixed-shift cover and does not prove Erdős-Straus.

## 1. Why character information should be routed rather than merely recorded

The small-prime class atlas proves that for

```text
p = 169, 289, or 529 mod 840,
```

a miss at fixed k=11 is possible only when

```text
(11/p) = +1.
```

The stronger atlas statement says that every prime factor of

```text
C_11 = (p+11)/4
```

must itself be a quadratic residue modulo 11.

The Legendre condition on p is not merely a passive restriction. By quadratic reciprocity it tells us the residue class of p modulo 11 lies in the quadratic-residue set. That residue determines another companion C_k which is forced to contain the factor 11.

This turns a character condition at one shift into mandatory factorization information at another shift.

## 2. General character-to-companion routing lemma

Let p be an odd prime satisfying

```text
p = 1 mod 4,
```

and let q be an odd prime different from p.

Assume

```text
(q/p) = +1.
```

Since p is 1 mod 4, quadratic reciprocity gives

```text
(p/q) = (q/p) = +1.
```

Therefore

```text
r = p mod q
```

is a nonzero quadratic residue modulo q.

Now solve the simultaneous congruences

```text
k = 3 mod 4
k = -r mod q.
```

Because 4 and q are coprime, the Chinese remainder theorem gives exactly one class k modulo 4q.

For every representative of that class,

```text
q divides p+k.
```

Since q is odd,

```text
q divides C_k = (p+k)/4.
```

### Routing theorem

A positive quadratic character `(q/p)=+1` on the p=1 mod4 prime domain routes the prime q into one uniquely determined admissible companion class k modulo 4q.

This is an elementary exact theorem. No finite census is involved.

## 3. The complete q=11 route table

The nonzero quadratic residues modulo 11 are

```text
1, 3, 4, 5, 9.
```

Choosing the least positive admissible representative k=3 mod4 gives

```text
p mod 11 = 1  ->  11 divides C_43
p mod 11 = 3  ->  11 divides C_19
p mod 11 = 4  ->  11 divides C_7
p mod 11 = 5  ->  11 divides C_39
p mod 11 = 9  ->  11 divides C_35
```

Thus every hard prime in h=169,289,529 that survives fixed k=11 routes a mandatory factor 11 into exactly one of

```text
k = 7, 19, 35, 39, 43
```

within the first q=11 routing period.

The two strongest routed branches found so far are p mod11=9 and p mod11=5.

## 4. Route p mod11 = 9: factor 11 enters C35

If

```text
p mod 11 = 9,
```

then

```text
11 divides C_35.
```

For h=169,289,529, the class-conditioned seed at k=35 is exactly 3. The routed factor therefore strengthens the mandatory seed from

```text
3
```

to

```text
3*11 = 33.
```

Using the exact k=35 state transition system, the seed-33 closure has

```text
57 total states
33 hard-admissible states
15 miss states.
```

That is already a large reduction from the earlier universal seeded problem, but the exact hard residue class gives substantially more.

Because 35 divides 840, fixing h also fixes C35 modulo 35:

```text
h=169 -> C35 mod35 = 16
h=289 -> C35 mod35 = 11
h=529 -> C35 mod35 = 1.
```

Restricting the seed-33 closure to each exact center gives

```text
h=169 -> 2 exact-center states -> 1 miss
h=289 -> 2 exact-center states -> 1 miss
h=529 -> 2 exact-center states -> 1 miss.
```

Even more strongly, the unique miss in all three classes has the same divisor-residue mask:

```text
1, 3, 4, 9, 11, 12, 13, 16, 17, 27, 29, 33 mod 35.
```

This is exactly the 12-element kernel of the Jacobi character modulo 35:

```text
(a/35) = (a/5)(a/7) = +1.
```

### Routed k=35 support theorem

For

```text
h in {169,289,529},
p mod11 = 9,
```

the following are equivalent:

```text
fixed k=35 misses
```

and

```text
every prime factor q of C35 satisfies (q/35)=+1.
```

The forward direction follows from the unique exact miss mask: every exponent-one divisor residue must lie in the Jacobi-plus subgroup.

For the reverse direction, if every prime factor lies in that subgroup then every divisor of C35 squared also lies in that subgroup. Both fixed-shift targets lie in the opposite coset, so neither target can occur.

This is a complete factor-support characterization of the routed k=35 miss branch.

## 5. Direct link to the six-companion residual wheel

The relevant six-shift block is

```text
27, 31, 35, 39, 43, 47.
```

After stripping the universal seeds, the six-companion theorem places k=35 at residual position R2, with

```text
C35 = 3*R2.
```

On the p mod11=9 route,

```text
11 divides C35.
```

Since 11 does not divide 3,

```text
11 divides R2.
```

The residual-wheel theorem says every rational prime other than 2 and 5 can divide at most one residual layer in a complete six-shift wheel. Hence the routed factor 11 is pinned uniquely to R2 in this wheel.

So a simultaneous survivor on this branch must satisfy both:

```text
11 divides R2 and no other residual in the wheel,
```

and

```text
every prime factor of C35, hence every prime factor of R2, lies in the Jacobi-plus subgroup modulo 35.
```

This is the first direct coupling between the character atlas and the cross-shift residual-support theorem.

It is not yet a contradiction. It converts the remaining problem into a support-allocation question across nearly coprime residuals.

## 6. Route p mod11 = 5: factor 11 enters C39

If

```text
p mod 11 = 5,
```

then

```text
11 divides C39.
```

For h=169,289,529, the k=39 class seed is 2, so the routed seed becomes

```text
2*11 = 22.
```

The exact seed-22 closure has

```text
83 total states
45 hard-admissible states
9 miss states.
```

All nine miss states lie on the positive Legendre-13 center branch:

```text
(13/p) = +1.
```

There are no negative-character miss states.

### Routed k=39 character theorem

For

```text
h in {169,289,529},
p mod11 = 5,
(13/p) = -1,
```

fixed k=39 must hit.

Equivalently, a prime surviving k=11 and then missing on this routed k=39 branch acquires the additional necessary condition

```text
(13/p) = +1.
```

Unlike the k=35 branch, the complete k=39 miss masks are not confined to the quadratic-residue subgroup modulo 13. The exact conclusion here is therefore a center-character condition, not a full prime-factor support theorem.

## 7. The second routing step: q=13

Once the routed k=39 miss forces

```text
(13/p) = +1,
```

the same routing lemma applies again.

The nonzero quadratic residues modulo 13 are

```text
1, 3, 4, 9, 10, 12.
```

The least positive admissible routes are

```text
p mod13 = 1  ->  13 divides C51
p mod13 = 3  ->  13 divides C23
p mod13 = 4  ->  13 divides C35
p mod13 = 9  ->  13 divides C43
p mod13 = 10 ->  13 divides C3
p mod13 = 12 ->  13 divides C27.
```

Thus the route

```text
k11 miss
-> p mod11=5
-> 11 divides C39
-> k39 miss
-> (13/p)=+1
```

necessarily pushes a second external prime factor, 13, into one of six explicit companion layers.

Three of those destinations,

```text
k=27, 35, 43,
```

lie in the same six-companion wheel as k=39. This is a natural next location for a two-factor support-allocation theorem.

## 8. Independent finite realization regression

The independent verifier factors the companions directly and tests the exact divisor-square targets without using the abstract state masks to decide the result.

Through p<=100,000, on the p mod11=9 route:

```text
h=169 -> 5 primes -> 0 k35 hits -> 5 misses
h=289 -> 5 primes -> 0 k35 hits -> 5 misses
h=529 -> 5 primes -> 1 k35 hit  -> 4 misses
```

Every realized k35 miss has only Jacobi-plus prime factors modulo35.

On the p mod11=5 route:

```text
h=169 -> 6 primes -> 4 k39 hits -> 2 misses -> 4 negative-13 primes -> 0 negative-13 misses
h=289 -> 3 primes -> 1 k39 hit  -> 2 misses -> 1 negative-13 prime  -> 0 negative-13 misses
h=529 -> 4 primes -> 4 k39 hits -> 0 misses -> 3 negative-13 primes -> 0 negative-13 misses
```

These finite counts are regression anchors only. The routing and fixed-shift conclusions come from exact arithmetic and complete finite-group closures.

## 9. Present theorem frontier

The earlier strategy asked whether isolated fixed shifts could each be made sufficiently strong.

The current structure is richer:

```text
fixed-shift miss
-> character restriction
-> CRT routes a mandatory prime factor into another companion
-> routed factor shrinks the next exact state space
-> next miss can impose a new character or support restriction
-> the residual wheel limits where those routed primes can coexist.
```

The k35 branch is currently the sharpest example because it reaches a unique exact-class miss state and an exact Jacobi-plus support characterization.

The next proof target is to force a second routed factor or support condition into the same six-companion wheel and determine whether the nearly disjoint residual supports can satisfy all miss constraints simultaneously.

Erdős-Straus remains open.
