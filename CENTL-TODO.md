# CENTL short-term work

This is a working checklist. Product sequencing and release themes live in
[`docs/ROADMAP.md`](docs/ROADMAP.md); canonical dependency pins live in
[`toolchain.lock`](toolchain.lock).

Long-horizon mathematical breadth lives in
[`docs/MATHEMATICS-CAPABILITY-TODO.md`](docs/MATHEMATICS-CAPABILITY-TODO.md), and
every new mathematical capability is admitted under
[`docs/MATHEMATICS-IMPLEMENTATION-STANDARD.md`](docs/MATHEMATICS-IMPLEMENTATION-STANDARD.md).
Keep this file focused on immediate implementation work rather than duplicating
that strategic inventory.

## Infrastructure completed for the next development cycle

- [x] Add a reproducible contributor bootstrap and exact opam dependency
  manifest.
- [x] Make formatting, compiler checks, package linting, and pin consistency
  part of `make quality`.
- [x] Keep pull-request validation to one Linux verify/test/differential job;
  reserve native Linux packaging for `main`, tags, and manual runs.
- [x] Run the seeded Julia/Nemo differential suite in pull-request CI.
- [x] Cancel superseded branch workflow runs while preserving tagged releases.
- [x] Exercise GMP with a large exact integer in the Core 2 compatibility smoke
  test.

## Calculator experience

- [x] Add interactive completion and bounded in-session history.
- [x] Support multiline input without weakening script semantics.
- [x] Give parse diagnostics precise file or input line, column, and caret
  context.
- [x] Add bounded exact sequences and recurrence evaluation.
- [x] Persist interactive history across calculator processes.
- [x] Carry source spans through evaluation so runtime mathematical failures can
  point back to their originating subexpression.

## Math contracts (0.12.0 path)

- [x] Structured verify / check / assert surfaces.
- [x] Discharge every F* zero-difference soundness obligation before enabling
  `verified_core` polynomial equality.
- [x] Finish bounded, replayable receipts with resolved session dependencies.
- [x] Add release `BUILD_MANIFEST.json` identity validation for the supported
  Linux native package.
- [x] Validate the reusable `centl-check` GitHub Action and passing
  example contracts.
- [x] Publish stable 0.12.0 with stamped release identity and the conformance CI
  gate.
- [ ] Pilot three external contract repositories.

## CENTL-SCi Caramels

- [x] Establish GNU/Linux as the supported reference platform and sole
  release-blocking operating system.
- [x] Implement deterministic scientific interpretation, explanation, and
  representative human-variation assimilation gates.
- [x] Implement user-owned BUILD workspaces, extension/package lifecycle,
  dependency validation, assurance inspection, bounded undo, and portability.
- [x] Implement validated workspace import with same-operation active-session
  reload and rollback on post-validation copy failure.
- [x] Stabilize an executable ABI/activation boundary for generated external and
  native scaffolds when a concrete backend integration requires it.
- [x] Live English-to-program workshop with spoken aliases, self-extend,
  host-growth proposals, and honest restart/rebuild advice.
- [x] User dialect / growth journal: chain `and then`, composition uses,
  missing-program hints, `:dialect`, `:journal`, `export dialect`.
- [x] Reviewed publish path: scope gate, contributor/owner grants, local
  pack, draft PR to mirage only, no stored tokens.

## CENTL Chemistry

CENTL Chemistry is the planned exact-first chemistry domain described in
[`docs/CHEMISTRY-PLAN.md`](docs/CHEMISTRY-PLAN.md). The first slice should stay
small enough to verify completely before stoichiometry, measured data, or broader
chemical models are admitted.

Immediate vertical-slice work:

- [ ] Define the chemistry value/AST types for elements, formulas, species, and
  reactions without duplicating CENTL's rational arithmetic.
- [ ] Implement a bounded formula parser with elemental symbols, integer
  subscripts, and nested parenthesized groups.
- [ ] Implement deterministic exact atom counting and canonical species
  rendering.
- [ ] Implement reaction parsing and construct the per-element stoichiometric
  matrix exactly.
- [ ] Solve the supported balancing domain through exact rational/integer linear
  algebra and normalize to the least positive integer coefficient vector.
- [ ] Independently verify every returned balance by recounting each element on
  both sides of the reaction.
- [ ] Add explicit refusal for malformed formulas, unknown elements, impossible
  balances, and underdetermined cases without a supported canonical result.
- [ ] Expose the first `centl-chem` human CLI plus deterministic machine result
  representation from the same authoritative implementation.
- [ ] Add golden, adversarial, malformed-input, determinism, and conservation
  tests for `Ca(OH)2`, `Fe + O2 -> Fe2O3`, ethane combustion, and the
  `KMnO4 + HCl` reaction.
- [ ] Keep atomic-weight/molar-mass work blocked until measured/interval
  provenance semantics are specified; do not label chemical data exact merely
  because it is decimal.

## CENTLAMP

CENTLAMP is the **CENTL Authority & Metric Protocol**, the open search-ranking
research track defined in [`docs/CENTLAMP.md`](docs/CENTLAMP.md). The complete
staged program lives in [`docs/CENTLAMP-TODO.md`](docs/CENTLAMP-TODO.md).

Immediate vertical-slice work:

- [ ] Freeze the `centlamp/0` query, corpus, candidate, metric, penalty, profile,
  and rank-certificate vocabulary.
- [ ] Build deterministic ingestion and lexical retrieval over a bounded local
  corpus.
- [ ] Define the first exact metric vector and deterministic dominance relation.
- [ ] Implement the first public resolver and emit machine-readable rank
  certificates under [`docs/CENTLAMP-RANK-CERTIFICATE.md`](docs/CENTLAMP-RANK-CERTIFICATE.md).
- [ ] Implement certificate replay so CENTL can mechanically reject an ordering
  that does not follow from its recorded ranking evidence.
- [ ] Establish a fixed judged-query benchmark before adding semantic or neural
  retrieval, and require measured improvement for added ranking complexity.

Keep this file limited to actionable near-term work; remove or check items when
the implementation lands instead of duplicating completed CI or setup tasks.
