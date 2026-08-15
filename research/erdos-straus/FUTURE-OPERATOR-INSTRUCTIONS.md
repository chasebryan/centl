# Future Operator Instructions

**Date:** 2026-08-15  
**Scope:** `research/erdos-straus/`

## Standing order

Use the exact Dirichlet reduced parameter domain from `REDUCED-PARAMETER-DOMAIN.md`. Do **not** equate reducedness with `gcd(s,Q)=1`. Rebuild the shared-factor C1/C2/CN program on that domain, then attack corrected DSC-P. Keep Erdős-Straus claim boundaries exact.

## Priority

1. Replay `reduced_domain_tight_probe.py` and `verify_reduced_domain_tight.py` at the same limit and freeze the first corrected-domain certificate.
2. Replace the old complementary-pair target. For `q=3`, `3|L`, so the exact domain is all `Z/3Z`; a two-singleton `{1},{2}` pair leaves `0` and is not a reduced obstruction.
3. Attack the first genuine 3-adic cover shape: three rows whose forbidden sets cover `{0,1,2}`. The first observed corrected-domain example occurs at `k=8378` and is already directly shadowed by `j=6,12`; prove the admissible/direct-shadow mechanism or falsify it.
4. Generalise lift-room to the exact affine domain. Primes already in `L` use full residue-ring fibers; free primes exclude one global affine class modulo `p`.
5. Re-run arbitrary shared-core peeling. The `3/5/7` coordinates are all `L`-supported because `3*5*7 | 840 | L`, so they must not be artificially restricted to units.
6. Bound the corrected tight active core on Class-C residuals, then reassemble DSC-P.
7. Keep the López pointwise remainder separate from density-one results.

## Proved assets to use

- Exact reduced-domain theorem: `REDUCED-PARAMETER-DOMAIN.md`
- Original exact Dirichlet criterion: `gcd(r+Ls,LQ)=1`
- Trap pullback and direct-shadow definitions
- Totient-ratio / lift-room results as unit-domain proof-mining assets
- Full-ring lift-room for `rad(q) | L`: a reduction fiber `Z/qZ -> Z/dZ` has size `q/d`
- Thinness bounds on `|R|`
- Divisor-child ancestry and hard-conditioned union-shadow theorems
- Finite candidatewise DSC certificates through `k<=1500`, whose verifiers already use the correct gcd condition

## Required claim corrections

- Complementary `q=3` unit covers are **not** failures of actual Dirichlet reducedness.
- `U_Q=(Z/QZ)^*` may be used only as an auxiliary sufficient subset unless equivalence to the exact affine domain has been proved in the stated case.
- The old `205` absorption result remains correct but no longer defines the universal shared-factor bottleneck.
- A bounded witness-search failure is not a union-shadow proof.

## Forbidden

Announcing Erdős-Straus solved without a complete deposited proof.
Calling `gcd(s,Q)=1` the exact reduced condition.
Restoring the old complementary-`q=3` pair as the main theorem target after this correction.
