# QR-saturating seeds and routed rigidity upgrades

**Status:** proved general lemma plus exact routed atlas  
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

The current route graph contains seven such upgrades.

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

This branch was already visible in the k=7/k=23 rigid-support atlas; the saturation lemma now supplies its elementary explanation.

### 4.2 q=31 into k=23, h=169,289,529

A rigid k=31 miss on these classes has positive 31-character. On the route

`p mod31 = 8`,

factor 31 enters C23.

The universal hard k=23 seed is 6, so the routed seed is

`S = 6*31 = 186`.

The divisors of 186^2 are exactly all 11 quadratic residues modulo 23.

Therefore, for each h in {169,289,529}, on p mod31=8,

> k=23 misses if and only if every prime factor of C23 is a quadratic residue modulo 23.

This is strictly stronger than the ordinary seed-6 k=23 geometry. Without factor 31, k=23 has 15 miss states, including the two negative-character exceptions p mod23=5 and14. With mandatory seed186, those exceptions disappear entirely.

The routed seed-186 closure has 33 states and exactly 11 misses, one for each quadratic-residue p class modulo23, all with the same exact QR divisor mask.

### 4.3 q=47 into k=11, h=121

On the rigid h=121 k=47 source branch, take

`p mod47 = 36`.

Then 47 divides C11.

The h=121 k=11 class seed is only 3, which is not QR-saturating. Routing 47 gives

`S = 3*47 = 141`.

The divisors of 141^2 fill the complete quadratic-residue subgroup modulo11.

Thus on this route

> k=11 misses if and only if every prime factor of C11 is a quadratic residue modulo11.

This extends exact k=11 QR-support rigidity to an h=121 branch where the ordinary class seed does not provide it.

### 4.4 q=47 into k=31, h=289

On h=289 and

`p mod47 = 16`,

factor 47 enters C31.

The ordinary k=31 class seed is 10. The routed seed is

`S = 10*47 = 470`.

Its square-divisor residues fill all 15 quadratic residues modulo31.

Therefore

> k=31 misses if and only if every prime factor of C31 is a quadratic residue modulo31.

The destination already has a QR-support theorem from the exact seed-10 state closure; this route supplies a simpler seed-saturation proof on the named subbranch.

### 4.5 q=47 into k=19, h=289

On h=289 and

`p mod47 = 28`,

factor 47 enters C19.

The ordinary k=19 seed is 7. The routed seed becomes

`S = 7*47 = 329`.

The divisors of 329^2 fill the quadratic-residue subgroup modulo19.

Therefore this route upgrades the otherwise non-rigid h=289 k=19 problem to the exact condition

> k=19 misses if and only if every prime factor of C19 is a quadratic residue modulo19.

## 5. Automated atlas result

Using only the currently proved source nodes

- q=7;
- q=11 on h=169,289,529;
- q=19 on h=121;
- the ten rigid q=23 residue branches;
- q=31 on h=169,289,529;
- q=47 on h=121,289;

the classifier enumerates every positive-character route to a prime destination and tests whether the receiving class seed becomes QR-saturating after adjoining the routed source prime.

Exactly seven class-residue route entries are novel upgrades over their baseline class seed:

- 23 -> 19, h=289, source residue4, seed7 ->161;
- 31 -> 23, h=169, source residue8, seed6 ->186;
- 31 -> 23, h=289, source residue8, seed6 ->186;
- 31 -> 23, h=529, source residue8, seed6 ->186;
- 47 -> 11, h=121, source residue36, seed3 ->141;
- 47 -> 31, h=289, source residue16, seed10 ->470;
- 47 -> 19, h=289, source residue28, seed7 ->329.

## 6. Strategic consequence

The reciprocity barrier says a routed quadratic factor cannot win merely by having the wrong sign at the destination. The saturation theorem identifies the next mechanism that does survive reciprocity:

> enough individually compatible routed factors can enlarge a mandatory divisor seed until its square-divisor geometry fills an entire character subgroup.

This suggests that route-graph search should score edges by **divisor-lattice growth**, not merely by character sign.

The next high-value search is therefore to identify two-factor or multi-factor routed seeds that saturate a destination even when no single routed factor does, especially at the remaining exceptional k=23 branches and at composite residual-wheel destinations.

Erdős-Straus remains open.
