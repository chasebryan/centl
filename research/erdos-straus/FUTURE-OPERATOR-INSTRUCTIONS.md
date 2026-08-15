# Future Operator Instructions

**Date:** 2026-08-15  
**Scope:** `research/erdos-straus/`

## Standing order

Do **not** try to prove universal DSC-0 or DSC-P. They are false; see `DSC-COUNTEREXAMPLE.md` and hosted verifier run `31862644146`.

The primary Erdős-Straus track is now:

\[
\boxed{
\text{every prime escaping the prime-modulus backbone}
\Longrightarrow
\text{some composite Type A/B / divisor-parametrization rescue}.
}
\]

Keep the exact-depth / covering-core program separate from the all-prime ES program.

## Highest-priority proof targets

0. **Corridor after `k=19`.** Combined two-target filters are now exact at `3,7,11,15,19` and the linear form `2p+1`. The next exact target is the Type-I companion to the existing `q=23` Type-II theorem. Do not spend the main budget restoring DSC. Do not try to finish ES by a `{2,3,5,7}`-smooth aligned Type-II cover; that covering is false.

1. **All-prime divisor criterion.** Build on `FAB-COPRIME-DIVISOR-CRITERION.md`:
   \[
   \fab(p,a,b)>0
   \iff
   \exists k\mid(a+bp),\quad k\equiv-p\pmod{4ab}
   \]
   for the coprime range. Find a cap-free existence theorem or a descent from failure.
2. **Hard external-nonresidue bridge.** Use `FAB-HARD-NONRESIDUE-BRIDGE.md`: any coprime fab certificate for a Mordell-hard prime imports an external quadratic nonresidue `ell>=11`. Coordinate this with the existing 11/13 residual structure.
3. **Composite-rescue core.** A prime that escapes every prime-modulus Type A/B layer has density zero but still must be solved pointwise. Classify the factorization patterns of the small linear forms `a+bp` that force a divisor in the target class.
4. **Mine recent algebra, not claimed conclusions.** `PRIOR-ART-AUDIT-2026-08-15.md` records why recent claimed universal proofs do not currently close the covering burden. Reuse valid identities only.
5. After every prime is proved, close arbitrary composite `n` by an explicit divisor/scaling lemma and write the final proof chain self-containedly.

## Exact assets now canonical

### q=3 / covering-core tools

- `Q3-ABSORPTION.md`: strong q=3 absorption.
- `Q3-WEAK-REDUNDANCY.md`: weak q=3 descendants add no new class.
- `Q3-POINTWISE-ABSORPTION.md`: candidate-specific trap absorption.
- `Q3-SINGLETON-PULLBACK.md`: every q=3 pullback has size at most one.
- `DIRECT-SHADOW-SMOOTHNESS.md`: direct shadows are supported on primes already in `L`.
- `DSC-COUNTEREXAMPLE.md`: explicit three-row q=3 union shadow with no direct shadow.

These are useful for the **depth-spectrum hypergraph** but are no longer the main ES wall.

### Exact reducedness

Use

\[
\boxed{\gcd(r+Ls,LQ)=1}
\]

and `REDUCED-PARAMETER-DOMAIN.md`.

Never replace this by `gcd(s,Q)=1` without a proved special-case equivalence. Primes already dividing `L` impose no parameter restriction.

### All-prime / fab / two-target corridor

- `FAB-COPRIME-DIVISOR-CRITERION.md`
- `FAB-HARD-NONRESIDUE-BRIDGE.md`
- `PRIME-MODULUS-BACKBONE.md`
- `COMPOSITE-CORE.md`
- `ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md`
- `TWO-P-PLUS-ONE-FILTER.md`
- `HARD-Q7-TYPE-I-NO-RESCUE.md`
- `Q11-TYPE-I-COMPANION.md`
- `K15-TWO-TARGET-FILTER.md`

## Recent-proof audit

Read `PRIOR-ART-AUDIT-2026-08-15.md` before importing a claimed solution.

In particular:

- Bradford arXiv:2602.11774v1 derives families but leaves the covering-system step to be shown.
- Dyachenko arXiv:2511.07465v1 uses Proposition 9.25 for its unconditional ED2 existence claim; the proposition is false as stated. A two-line lattice rectangle counterexample is deposited in the audit.
- Bello-Hernández–Benito–Fernández arXiv:2606.10922v1 provides a useful divisor parametrization and strong finite evidence, but does not claim that the `a,b<=11` window is universally sufficient.

## Depth-spectrum track, secondary

Universal direct-shadow completeness is replaced by a covering-core/hypergraph problem:

1. classify minimal union-shadow cores;
2. reduce hyperedges using strong/weak/pointwise ancestry;
3. determine exact-depth realizability after collective covers are included.

Do not let this secondary track consume the main ES proof budget.

## Forbidden

- Announcing Erdős-Straus solved without a complete deposited proof whose every universal existence step is proved.
- Claiming DSC-0 or DSC-P universally; both are falsified.
- Calling parameter-unit coverage equivalent to exact Dirichlet reducedness.
- Treating a finite bounded-parameter computation, a density-one result, or a conditional covering scheme as pointwise all-prime coverage.
- Reusing Proposition 9.25 of arXiv:2511.07465v1 as stated; it has an explicit counterexample.

## Computational hunt

The operator-facing hunt is `./centl es go` (menu: `./centl es`). It is an infinite window recurrence from a seed. Letters are collected; the engine stops when the operator stops it. Letter numbers are content-addressed (`ES-LETTER-v1`) and must stay independent of start factor, clock, and host. Do not replace them with a discovery-order serial.
