# k47 phase absorption on h169

**Status:** proved fixed-shift module inside the candidate decomposition framework  
**Date:** 2026-08-16  
**Verifier:** `verify_k47_phase_absorption.py`  
**Claim boundary:** exact h169 k47 survivor-phase implication only. This is not a universal depth bound, not a closed decomposition method, and not an Erdős–Straus proof.

## 1. Coordinate

For

`p = 169 + 840t`

at the admissible shift `k=47`,

`C47 = (p+47)/4 = 54 + 210t = 6J`,

with

`J = 9 + 35t`.

The fixed mandatory seed is therefore `6=2*3`.

Modulo47,

`C47 = 7 + 22t`.

The exact signed-box targets are

- Type I: `d = -4^(-1) = 35 mod47`;
- Type II: `d = -C47 mod47`.

If `C47 = 0 mod47`, then the factor47 case is an immediate Type-II hit. Otherwise every residual prime factor of `J` is a unit modulo47 and the complete unit residue-state closure applies.

## 2. Exact seed-6 closure

Starting from the divisor-square state supplied by the fixed factors2 and3 and adjoining every possible nonzero residue modulo47, the complete exact closure contains

```text
1079 states
 883 hits
 196 misses
```

with hit mechanisms

```text
Type I only       221
Type II only       68
Type I + Type II  594
miss              196
```

This reconstructs the same seed-6 exact state geometry already used by the incoming-repulsion program, but here the final hard-class center is imposed as the response coordinate.

## 3. Range-free phase theorem

Filter the complete miss set by the required final center

`C47 = 7 + 22t mod47`.

Exactly thirteen phases have no possible miss state:

`A47 = {1,5,6,10,13,21,23,36,37,38,40,42,44}`.

Therefore

`k47 miss => t mod47 notin A47`.

Equivalently,

`k47 absorbs every h169 integer with t mod47 in A47`.

The possible survivor phases are

`S47 = {0,2,3,4,7,8,9,11,12,14,15,16,17,18,19,20,22,24,25,26,27,28,29,30,31,32,33,34,35,39,41,43,45,46}`.

This implication is range-free. It is obtained from complete exact residue-state closure, not from a finite prime census.

The phases in `S47` are only **possible** survivor phases. Existence of an abstract miss state with the same center does not assert that every, or any particular, arithmetic integer in that phase realizes it.

## 4. Ten absorptions beyond the universal divisor shell

The universal signed-box selector shell handles three of the thirteen phases directly:

- `t=21`: `C47=-1 mod47`, so `d=1` is Type II;
- `t=36`: `C47=0 mod47`, so `d=C47` is Type II;
- `t=44`: `C47=35=-4^(-1) mod47`, so `d=C47` is Type I.

The remaining ten absorbed phases

`{1,5,6,10,13,23,37,38,40,42}`

are not explained by those universal divisors. They arise from the full exact seed-6 divisor-state geometry.

Thus k47 contributes genuine state-dependent phase absorption beyond the factorization-free selector shell.

## 5. Center structure

The thirteen absorbed phases correspond to final centers

`{0,11,22,23,29,35,38,39,41,43,44,45,46}` modulo47.

Every nonzero absorbed center is a quadratic nonresidue modulo47.

The complete closure still has miss states at the eleven other nonresidue centers

`{5,10,13,15,19,20,26,30,31,33,40}`,

and at every quadratic-residue center.

So the theorem is strictly finer than a quadratic-character test: character alone does not determine k47 survival.

## 6. p-coordinate form

Since the h169 parameter has period47 at this shift, the absorbed p residues modulo

`840*47 = 39480`

are

`{1009,4369,5209,8569,11089,17809,19489,30409,31249,32089,33769,35449,37129}`.

## 7. Place in the local machine

The post-k23 ladder now carries several different exact transition forms:

- k27: finite survivor grammar;
- k31: BARE/FULL_QR normal form;
- k35: two-branch survivor theorem;
- k39: phase absorption modulo13;
- k43: universal selector-shell phases;
- k47: thirteen-phase absorption modulo47, ten of them beyond the universal shell.

This diversity is useful. It argues against forcing every fixed shift into one preferred representation. The candidate decomposition framework should retain whichever exact coordinate is smallest and lossless for that shift.

The developing Bryan Entanglement Cross layer is intentionally not used as proof data here. If attached later, it should annotate or schedule these exact transitions without changing their arithmetic semantics or granting pruning permission.

## 8. Next theorem target

Intersect the surviving k47 phases with the already-proved k39 phase restriction and the k27/k31/k35 survivor coordinates, then test whether the residual product state forces k51 or k55.

The important target is no longer another census. It is an implication of the form

`survive k27,k31,k35,k39,k43,k47 => restricted residual state`

followed by a deterministic next selector or a strictly smaller exact survivor grammar.
