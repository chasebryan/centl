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

CENTL Chemistry is the exact-first chemistry domain described in
[`docs/CHEMISTRY-PLAN.md`](docs/CHEMISTRY-PLAN.md). Development implementation
is currently isolated on `feature/centl-chem-phase1`; checked items below mean
source/tests have been authored on that branch, not that the slice has passed
admission or been merged.

Deterministic chemistry foundation:

- [x] Define chemistry value types for formulas, species, reactions,
  conservation evidence, and balanced reactions without duplicating CENTL's
  rational arithmetic.
- [x] Implement a bounded formula parser with all 118 current element symbols,
  positive integer subscripts, and nested parenthesized groups.
- [x] Implement deterministic arbitrary-precision atom counting.
- [x] Implement reaction parsing and exact per-element stoichiometric matrix
  construction.
- [x] Reuse `Centl_matrix.nullspace` to solve the supported balancing domain
  over exact rationals and normalize to the primitive all-positive integer
  coefficient vector.
- [x] Independently verify every returned balance by recounting each element on
  both sides of the reaction.
- [x] Add explicit refusal for malformed formulas, unknown elements, impossible
  balances, zero-coefficient solutions, mixed-sign solutions, and
  underdetermined reactions without a supported canonical result.
- [x] Expose `centl-chem atoms`, `centl-chem balance`, and deterministic JSON
  evidence from the same authoritative implementation.
- [x] Include exact stoichiometric matrices, stable machine error codes, original
  supplied coefficients, and per-element conservation evidence in machine
  results.
- [x] Add golden, malformed-input, resource-bound, deterministic-replay, and
  conservation tests for `Ca(OH)2`, `Fe + O2 -> Fe2O3`, ethane combustion,
  and the `KMnO4 + HCl` reaction.

Sample-spread / CPS evidence foundation:

- [x] Add bounded replicate ingestion with a single explicit CENTL Physics unit
  per spread request.
- [x] Compute exact-over-reported-values mean, median, min/max, range, MAD,
  population/sample variance, population/sample standard deviation, standard
  error, and relative standard deviation.
- [x] Preserve irrational standard deviations as exact radicals rather than
  silently decimalizing them.
- [x] Preserve raw replicate values in the machine result.
- [x] Separate `source_class=measured` from
  `arithmetic_class=exact_over_reported_values`; provide an explicit
  `spread exact` declaration without making it the default.
- [x] Keep confidence intervals uncomputed until a confidence model, level, and
  method are declared.
- [x] Keep measurement uncertainty explicitly separate from sample spread and
  report it as not provided until an uncertainty budget exists.
- [x] Add human and JSON spread surfaces plus measured/exact provenance tests.

Immediate next chemistry work:

- [ ] Run formatting, compilation, chemistry unit/protocol/Cram tests, and the
  relevant repository quality gates; fix every failure before calling the slice
  green.
- [ ] Add exact amount-of-substance and specified-particle conversion using the
  existing exact SI Avogadro constant rather than duplicating it.
- [ ] Add reaction stoichiometric amount conversion using the verified canonical
  coefficient vector.
- [ ] Add limiting-reagent and theoretical-yield amount semantics while keeping
  measured mass/molar-mass work blocked behind provenance-aware atomic-weight
  data.
- [ ] Define the measurement-uncertainty representation: uncertainty components,
  standard/combined/expanded uncertainty, coverage factor/probability,
  traceability, corrections, and provenance.
- [ ] Define explicit confidence-interval and quantile methods before enabling
  either output.
- [ ] Keep atomic-weight/molar-mass work blocked until measured/interval
  provenance semantics and source-versioning are implemented; do not label
  chemical data exact merely because it is decimal.
- [ ] Keep CPS thermodynamic, kinetic, phase/pressure, toxicology, volatility,
  and broader predictive/hazard models blocked until their data sources,
  assumptions, uncertainty contracts, and refusal boundaries are independently
  specified and tested.

No chemistry capability becomes an Oasis/public claim merely because source
exists on the development branch.

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
