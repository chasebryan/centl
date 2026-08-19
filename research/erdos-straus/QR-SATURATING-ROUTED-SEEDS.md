# QR-saturating seeds and routed rigidity upgrades

**Status:** proved general lemma plus corrected periodic route atlas v2  
**Date:** 2026-08-16  
**Primary classifier:** `classify_qr_saturating_route_atlas.py`  
**Independent realization regression:** `verify_qr_saturating_route_atlas.py`  
**Depends on:** class-conditioned seed law, character-routing theorem, reciprocity-route barrier  
**Claim boundary:** this is a fixed-shift support theorem and route-upgrade atlas. It does not give a universal shift ceiling and does not prove Erdős-Straus.

## 1. QR-saturating seed lemma

Let k be an odd prime with

`k = 3 mod 4`.

Let

`C_k = (p+k)/4`

for a prime p congruent to 1 modulo 4, and let S be a mandatory divisor of C_k.

Write Q_k for the nonzero quadratic-residue subgroup modulo k.

Assume the divisor residues of S squared are exactly Q_k:

`{D mod k : D divides S^2} = Q_k`.

Then S is called QR-saturating at k.

### Theorem

If S divides C_k and S is QR-saturating at k, then

> fixed k misses if and only if every prime factor of C_k is a quadratic residue modulo k.

### Proof

The two Lane-I divisor-square targets are

- Type I - the residue `-1/4 mod k`;
- Type II - the residue `-C_k mod k`.

Because k is 3 modulo 4, -1 is a quadratic nonresidue. Therefore the Type-I target is a nonresidue.

Suppose some prime factor ell of C_k is a quadratic nonresidue modulo k. Since S is QR-saturating, divisors of S^2 realize every quadratic residue. Multiplying ell by those seed divisors realizes the complete nonresidue coset inside divisors of C_k^2. In particular the Type-I target is realized, so fixed k hits.

Hence a miss forces every prime factor of C_k to be a quadratic residue.

Conversely, if every prime factor of C_k is a quadratic residue, then every divisor of C_k^2 is a quadratic residue. Consequently C_k is a quadratic residue, so `-C_k` is a nonresidue. Both Type I and Type II are outside the divisor set, and fixed k misses.

This proves the equivalence.

## 2. Existing theorems explained by seed saturation

Several previously discovered finite-state theorems have an elementary seed-saturation explanation:

- k=7, seed 2 - divisors of 2^2 give all 3 quadratic residues modulo 7;
- k=11, seed 15 on h=169,289,529 - divisors of 15^2 give all 5 quadratic residues modulo 11;
- k=19, seed 35 on h=121 - divisors of 35^2 give all 9 quadratic residues modulo 19;
- k=31, seed 70 on h=529 - divisors of 70^2 give all 15 quadratic residues modulo 31.

The classifier scans prime shifts through k<=5000 and finds exactly 17 class-shift pairs whose class seed is already QR-saturating, including the trivial k=3 cases and the families above.

Not every rigid character theorem is explained by initial seed saturation. For example k=31 seed10, k=47 seed42, and k=59 seed105 require the stronger exact state-closure mechanism. This distinction is preserved.

## 3. Routing can create a saturating seed

The reciprocity-route barrier proves that a positively routed prime q automatically has positive Jacobi character at an admissible destination. That prevents a simple character-sign contradiction.

But a routed factor can still be powerful in a different way: it can enlarge the mandatory seed until the seed divisors fill the entire quadratic-residue subgroup.

This converts a destination with exceptional or non-rigid miss states into an exact QR-support node.

### Route-scope correction

The character-routing theorem produces one congruence class of destination shifts modulo `4q`. It is not restricted to the least positive representative.

The original v1 saturation classifier enumerated least-positive representatives from its source route table and also omitted the already-proved h=361 q=59 positive-character source. Its count of seven upgrades was therefore a count for that restricted source/representative atlas, not for the complete current route inventory.

Version 2 corrects this by scanning destination shifts directly. For every prime destination k=3 mod4 through the requested bound it tests the exact routing condition

`p mod q = -k mod q`

against every currently proved source theorem. This automatically includes all periodic representatives.

It also includes q=59 on h=361.

With that corrected scope, there are exactly **10** novel single-source QR-saturation upgrades through prime destination k<=5000.

## 4. Exact novel routed saturation upgrades

### 4.1 q=23 into k=19, h=289

On the rigid k=23 residue branch

`p mod23 = 4`,

factor 23 is routed into C19.

For h=289, the ordinary k=19 class seed is 7. The routed seed becomes

`S = 7*23 = 161`.

The divisors of 161^2 are exactly the 9 quadratic residues modulo 19.

Therefore on this branch

> k=19 misses if and only if every prime factor of C19 is a quadratic residue modulo 19.

### 4.2 q=31 into k=23, h=169,289,529

On the route

`p mod31 = 8`,

factor 31 enters C23.

The universal hard k=23 seed is 6, so the routed seed is

`S = 6*31 = 186`.

The divisors of 186^2 are exactly all 11 quadratic residues modulo 23.

Therefore, for each h in {169,289,529}, on p mod31=8,

> k=23 misses if and only if every prime factor of C23 is a quadratic residue modulo 23.

This is strictly stronger than the ordinary seed-6 k=23 geometry. Without factor 31, k=23 has 15 miss states, including the two negative-character exceptions p mod23=5 and14. With mandatory seed186, those exceptions disappear entirely.

### 4.3 q=47 into k=11, h=121

On the rigid h=121 k=47 source branch, take

`p mod47 = 36`.

Then 47 divides C11.

The h=121 k=11 class seed is only 3. Routing 47 gives

`S = 3*47 = 141`.

The divisors of 141^2 fill the complete quadratic-residue subgroup modulo11.

Thus on this route

> k=11 misses if and only if every prime factor of C11 is a quadratic residue modulo11.

### 4.4 q=47 into k=31, h=289

On h=289 and

`p mod47 = 16`,

factor 47 enters C31.

The ordinary k=31 class seed is 10. The routed seed is

`S = 10*47 = 470`.

Its square-divisor residues fill all 15 quadratic residues modulo31.

Therefore

> k=31 misses if and only if every prime factor of C31 is a quadratic residue modulo31.

### 4.5 q=47 into k=19, h=289

On h=289 and

`p mod47 = 28`,

factor 47 enters C19.

The ordinary k=19 seed is 7. The routed seed becomes

`S = 7*47 = 329`.

The divisors of 329^2 fill the quadratic-residue subgroup modulo19.

Therefore this route upgrades h=289 k=19 to the exact condition

> k=19 misses if and only if every prime factor of C19 is a quadratic residue modulo19.

## 5. New q=59 routed upgrades on h=361

The proved h=361 k=59 theorem says a k=59 miss requires

`(59/p) = +1`.

That positive source character supplies three additional QR-saturating routes into smaller prime destinations.

### 5.1 q=59 into k=11

Required source residue:

`p mod59 = 48`.

Then 59 divides C11. The h=361 class seed at k=11 is3, so

`S = 3*59 = 177`.

The divisors of 177^2 fill QR(11). Therefore

> on h=361 and p mod59=48, k=11 misses iff every prime factor of C11 is a quadratic residue modulo11.

### 5.2 q=59 into k=23

Required source residue:

`p mod59 = 36`.

Then 59 divides C23. The universal k=23 seed6 strengthens to

`S = 6*59 = 354`.

The divisors of 354^2 fill QR(23). Therefore

> on h=361 and p mod59=36, k=23 misses iff every prime factor of C23 is a quadratic residue modulo23.

This removes the ordinary seed-6 exceptional negative-character geometry on the routed branch.

### 5.3 q=59 into k=31

Required source residue:

`p mod59 = 28`.

Then 59 divides C31. The h=361 k=31 class seed14 strengthens to

`S = 14*59 = 826`.

The divisors of 826^2 fill QR(31). Hence

> on h=361 and p mod59=28, k=31 misses iff every prime factor of C31 is a quadratic residue modulo31.

These three branches connect the established k=59 theorem back into the small-shift support network.

## 6. Corrected automated atlas result

The v2 classifier uses the currently proved source inventory

- q=7 on all hard classes;
- q=11 on h=169,289,529;
- q=19 on h=121;
- the ten rigid positive q=23 residue branches on all hard classes;
- q=31 on h=169,289,529;
- q=47 on h=121,289;
- q=59 on h=361.

It scans every prime destination k=3 mod4 through k<=5000, including periodic route representatives.

The 10 novel single-source upgrades are:

- 23 -> 19, h=289, source residue4, seed7 ->161;
- 31 -> 23, h=169, source residue8, seed6 ->186;
- 31 -> 23, h=289, source residue8, seed6 ->186;
- 31 -> 23, h=529, source residue8, seed6 ->186;
- 47 -> 11, h=121, source residue36, seed3 ->141;
- 47 -> 31, h=289, source residue16, seed10 ->470;
- 47 -> 19, h=289, source residue28, seed7 ->329;
- 59 -> 31, h=361, source residue28, seed14 ->826;
- 59 -> 23, h=361, source residue36, seed6 ->354;
- 59 -> 11, h=361, source residue48, seed3 ->177.

The independent finite regression realizes every one of these 10 route branches on actual Mordell-hard primes below two million and finds at least one destination miss on each branch, with zero violations of the QR-support equivalence.

## 7. Strategic consequence

The reciprocity barrier says a routed quadratic factor cannot win merely by having the wrong sign at the destination. The saturation theorem identifies the next mechanism that survives reciprocity:

> enough individually compatible routed factors can enlarge a mandatory divisor seed until its square-divisor geometry fills an entire character subgroup.

The corrected atlas also makes two route-mining rules explicit:

1. source inventories must include every proved positive-character theorem, even when the source theorem itself came from a larger shift such as59;
2. routing must be treated as a periodic congruence class modulo4q, not as a single least-positive destination.

The next layer is multi-source saturation, where two or three individually insufficient routed factors jointly fill a destination QR subgroup.

Erdős-Straus remains open.
