# Changelog

## Unreleased

### Added

- CENTL-MIRAGE now runs a complete local development cycle: CEGIS example
  search, semantic fingerprints, fingerprint comparison, autonomy policy,
  review, and explicit accept/reject. A cycle still does not activate source or
  promote assurance by itself.
- MIRAGE evidence executors can discharge parser, capability-discovery, and
  example or fingerprint regression obligations from transaction-bound
  artifacts instead of leaving those actions permanently pending.
- Deterministic SCi code generation can locate a native definition request
  inside surrounding prose rather than only at the start of a cell.
- `centl-mirage wellspring` and `centl-mirage oasis` inspect Wellspring
  Candidates and Oasis identity without declaring either status.
- `scripts/oasis.py --inspect` reports distance from Oasis qualification and
  cannot declare a release.
- Durable Wellspring Candidate records live under `docs/wellsprings/`.
- MIRAGE now records bounded equality-saturation rewrites, metamorphic
  property checks, a claim-local evidence lattice, Pareto ranking of
  admissible candidates, and an explicit cycle progress measure.
- Generated SCi external/native scaffolds have an inspectable JSONL ABI
  contract that cannot self-enable or claim verified-core modification.
- CENTL-SCi `status` is now a real BUILD command over the previously orphaned
  status module, with honest remaining gates.
- Deterministic SCi fast paths now admit `gcd of`, `lcm of`, and
  `fibonacci of` without consulting a model.
- The capability graph now includes gcd, lcm, Fibonacci, sequence, sum,
  product, and recurrence so MIRAGE can prefer composition.
- MIRAGE fingerprints load candidate definitions and report whether the core
  observation corpus is preserved; `iterate` recomputes an active cycle from
  stored source.
- CENTL-SCi now has a deterministic capability catalog, an FCF product-family
  listing, constructive next-step guidance, and `extend <request>` to start a
  local MIRAGE cycle instead of dead-ending on unsolved work.
- Spoken `sum of`, `product of`, `sequence of`, and `factorial of` lower to
  exact CENTL without a model.
- SCi can export a replayable workbook from the live session; BUILD can
  inspect a single catalog capability; MIRAGE `doctor` reports structural
  cycle health.
- Requirements that already compose to existing CENTL operations are marked
  SATISFIED instead of asking for a new implementation.
- Spoken ordinals such as `the 10th fibonacci number` lower to `fibonacci(10)`.
- CENTL-SCi encodes the official Oasis promotion path: experimental work
  drafts to `mirage`, Oasis remains a later qualification on `oasis`, and
  verbs that would self-approve, merge to oasis, or tag a release are
  refused. Inspection never declares Oasis.
- CENTL-SCi can prepare a reviewed contribution pack and, with an explicit
  local grant, commit only that pack and open a **draft** GitHub pull
  request against `mirage`. Tokens are not stored, English is not passed
  to a shell, oasis is never the automatic base, and out-of-scope harm
  is refused. This is not a claim of perfect security.
- CENTL-SCi records a user-owned growth journal and replayable dialect.
  `let square(x) = x^2 and then square(6)` creates, hot-loads, and evaluates
  in one utterance. Composition reports `Uses:`. Missing programs stay
  symbolic and tell the user how to create them. `:dialect`, `:journal`,
  and `export dialect` expose the living local language without promoting
  assurance.
- CENTL-SCi now has a live English program workshop: `let`, topic names,
  conventional exact recipes, and `teach yourself` create local `.centl`
  programs, install spoken aliases, evaluate a first example, and say
  whether a restart is required. Native programs hot-load. Host/OCaml
  growth writes a reviewable proposal and requires `dune build` plus a
  process restart. Verified core is never rewritten by this path.

### Changed

- Goal graphs record `validated_by` edges from requirements to extracted
  examples and acceptance cells.

## 0.14.0 — 2026-08-10

### Release posture

- v0.14.0 is the consolidation and hardening release intended to succeed v0.12.0
  as the next stable CENTL baseline. The v0.13.0 development line was never
  formally published as a stable release; its validated work is incorporated
  here rather than presented as a separate public release.
- v0.14.0 is being qualified as an **Oasis candidate**. Oasis is a repeatable
  release classification, not this version's codename. The declaration
  `CENTL v0.14.0 is an Oasis release.` is withheld until the final release gate
  is complete on the reviewed release commit.
- The canonical release tag remains ordinary Semantic Versioning: `v0.14.0`.

### Added

- CENTL-MIRAGE — Mathematical Introspective Recursive Autonomous Growth Engine —
  adds bounded local design-document ingestion, SHA-256 source identity,
  provenance-preserving Specification IR, typed goal/capability graphs,
  deterministic conflict detection, capability-gap analysis, evidence
  obligations, and non-mutating candidate transactions.
- MIRAGE can deterministically materialize supported candidate definitions,
  bind the exact staged source to its transaction identity, execute the
  authoritative parser against that source, record readiness evidence, and
  construct execution plans for still-undischarged obligations without
  promoting the candidate or mutating the active workspace.
- MIRAGE exposes local `start`, `ingest`, `analyze`, and `status` workflows while
  keeping generated/downstream work below verified-core assurance until the
  appropriate engineering and validation obligations are discharged.
- CENTL CARAVAN Phase 1 adds the reproducible local laboratory for authenticated,
  content-addressed artifact preservation and availability: immutable storage,
  deterministic chunk identities, Ed25519 carrier identity, signed policy
  acceptance, TUF-authenticated catalogs, outbound-only laboratory transport,
  bounded verified retrieval, bad-carrier quarantine/fallback, hostile-transfer
  coverage, and explicit join/status/leave lifecycle.
- `docs/OASIS.md` defines the reusable CENTL Oasis release standard and the
  evidence required before any release receives the declaration.
- `docs/REPOSITORY-MAP.md` defines the supported v0.14.0 source-tree organization
  and the boundary between runtime, laboratory, documentation, assets, scripts,
  tests, automation, and historical branch state.
- `docs/releases/0.14.0.md` records the v0.14.0 feature, trust, security, rollout,
  and Oasis-qualification boundaries.

### Changed

- The authoritative CENTL version is 0.14.0.
- CARAVAN is now an included **local laboratory** component rather than a future
  placeholder. Arbitrary public volunteer enrollment remains outside v0.14.0.
- CARAVAN retrieval now validates authenticated chunk shape and maximum chunk
  size independently, checks storage/free-space capacity before transfer, and
  bounds pending challenge and active-session populations.
- MIRAGE gap analysis no longer mistakes an available generation mechanism for
  an already-existing requested binding: explicitly materializable definitions
  are staged as extensions and must produce parser evidence before readiness.
- Repository hygiene and security are treated as release gates rather than
  post-release chores. Historical branches are preserved until unique work is
  reconciled; ambiguous active pull-request state is removed.

### Security and repository hygiene

- Removed the obsolete one-shot v0.13.0 auto-tag workflow and v0.13.0 native-gate
  observer, preventing abandoned release automation from mutating refs or
  creating failure branches during v0.14.0 work.
- Removed the obsolete fixed v0.10.0 publication workflow from the active
  automation surface.
- Corrected the immutable `ocaml/setup-ocaml` action annotation in MIRAGE CI to
  match the pinned 3.7.0 commit; the associated GitHub Advanced Security review
  thread resolved after the source fix.
- CARAVAN continues to pin the remediated `cryptography` release selected after
  dependency review rejected the earlier vulnerable laboratory pin.
- The GNU/Linux installer now rejects symlink, hard-link, device, FIFO, and other
  unsupported archive member types before extraction, in addition to its
  existing checksum, path/layout, staging, smoke-test, and atomic-activation
  controls. A hostile linked-archive regression test covers this boundary.
- The stale #65 physics draft was reconciled against the modern mainline and
  closed without deleting its historical branch; its supported product behavior
  is already present in the current physics implementation and regression suite.
- Oasis qualification retains least-privilege workflow permissions, immutable
  action pins, dependency review, GitHub Actions security analysis, CARAVAN,
  MIRAGE, installer, and final integrated release validation as release gates.

### Preserved from the unreleased 0.13.0 line

- CENTL-SCi v0.0.2-Caramels, GNU/Linux-only active platform policy, FCF release
  preservation/recovery work, model-provenance boundaries, and host-neutral
  preserved release-tree support are incorporated into v0.14.0.

## 0.13.0 — UNRELEASED DEVELOPMENT LINE — 2026-08-10

### Added

- CENTL-SCi v0.0.2-Caramels becomes the current scientific interaction generation,
  with answer-first natural-language mathematics and physics, deterministic fast
  paths, evidence-backed presentation, clarification for underspecified requests,
  structured result recall, and `MATH>`, `PHYS>`, `HYBRID>`, and `BUILD>` modes.
- Caramels adds user-owned extension workflows with persistent workspaces,
  revisions, snapshots, package composition, dependency-aware extension
  lifecycle operations, validation/audit surfaces, workspace import/export, and
  controlled downstream core-change planning without redefining verified CENTL.
- Deterministic Caramels interpretation covers exact arithmetic, equations,
  algebraic transforms, approximation, unit conversion, physical constants,
  closed verification claims, and supported uniform-gravity mechanics before
  any optional local semantic model is consulted.
- FCF preservation tooling can preserve published release bytes, run recurring
  local integrity/recovery drills, reconstruct the qualified CENTL-SCi runtime
  offline, preserve exact model provenance and immutable base-model repository
  revisions, and export only explicitly approved public release material.
- Installers can consume a host-neutral immutable release tree through an
  explicit HTTPS or local `file://` release base, allowing preserved FCF release
  storage to serve packages without changing CENTL's release format.

### Changed

- GNU/Linux is now the sole active development, CI, packaging, validation,
  installation, and release target. Historical macOS and Windows code may remain
  available, but active development for those platforms is halted.
- CENTL-SCi model output remains untrusted semantic input: model provenance is
  bound to exact bytes, and generated/external semantics cannot promote
  themselves to verified CENTL core.
- Release preservation and publication are separated: private recovery material
  such as models, caches, Git mirrors, OCI capsules, and reconstruction state is
  not automatically redistributable or included in public exports.

### Deferred

- CENTL CARAVAN is not part of v0.13.0. Its architecture and Phase 1 laboratory
  implementation remain a separate future release line.
- The experimental external JSONL execution boundary remains under development
  and is not part of the v0.13.0 stable release boundary.

## 0.12.0 — 2026-08-09

### Changed

- Promoted validated release candidate series to stable 0.12.0.
- Authoritative CLI/golden outputs updated to 0.12.0 where appropriate.
- Historical rc.2/rc.3 records preserved.


## 0.12.0-rc.3 — 2026-08-09

### Added

- CENTL-SCi is packaged and activated as a first-class native command alongside
  `centl` and `centl-physics`.
- A bare `centl-sci` starts the answer-first live scientific REPL.
- Native installers smoke-test CENTL-SCi exact arithmetic and REPL startup
  before activating the installed command.
- Unix installation can configure the user's PATH automatically, with an
  explicit opt-out and a POSIX profile fallback when the shell cannot be
  identified.
- Dedicated release notes document the first-run scientific interface and
  platform policy.

### Fixed

- The Unix installer no longer fails under `set -u` when `SHELL` is absent in a
  headless CI, container, or service environment.
- Windows installer validation no longer depends on PowerShell preserving
  native REPL line boundaries; it still requires both CENTL-SCi identity
  markers before activation.
- Regression coverage now exercises installation with `SHELL` explicitly
  removed and verifies `~/.profile` PATH fallback plus `centl-sci` activation.

### Release-candidate notes

- Linux remains the CENTL-SCi reference platform. Windows support is
  experimental and best-effort during the early development series.
- This is a candidate build for validation, not the final 0.12.0 publication.

## 0.12.0-rc.1 — 2026-08-08

### Added

- Math-contract release candidate:
  - Protocol `op: "verify"` and MCP `centl_verify` check structured claims.
  - CLI `centl verify --left/--relation/--right [--variable name:rational]
    [--json] [--receipt FILE]` and `centl check FILE [--json]
    [--receipt FILE]`.
  - Calculator grammar `assert(left rel right)` and quantified
    `assert(left rel right, for_all = x, domain = rational)`, host-checked
    outside the engine (assert exits follow verify: 0/1/2).
  - Decisive scopes: closed exact rational comparison, certified enclosure
    order/inequality, and universal equality in the F*-admitted univariate
    rational-polynomial fragment. The latter reports `verified_core` and names
    `Centl.PolynomialSoundness.surface_rational_polynomial_identity_sound`.
  - False polynomial equalities are `refuted` only with an exactly rechecked
    rational counterexample (`witness_checked`).
  - Enclosure evidence includes exact dyadic endpoints plus decimal bounds;
    polynomial evidence may include `normalized_difference` and
    `counterexample`.
  - Verdicts: `verified`, `refuted`, `unknown`, `invalid`. Operational failures
    (cancellation, resource/precision limits, backend failures) remain errors.
  - Free-form assumptions, multi-variable claims, quantified order, and
    unproved polynomial identities return `unknown`.
  - Session definitions may be read; verification never mutates session state.
  - Bounded receipts include the resolved claim, active limits, exact
    transitive session dependencies, session revision, verdict evidence, and
    the binary's semantic version, optional commit, and generated-core hash.
  - `--build-info` exposes the stamped build identity, receipt schema, and
    protocol version. Native archives carry a validated `BUILD_MANIFEST.json`.
  - A reusable local `centl-check` GitHub Action runs passing contracts and can
    retain their receipt collection as an artifact.
  - Passing and deliberately pending example contracts live under
    `examples/contracts/`.
  - `describe` advertises verification scopes, verdicts, and assurance classes.

### Release-candidate notes

- Claims outside the admitted proof fragment—including symbolic division and
  multiple free variables—remain `unknown`; this is intentional.
- This is a candidate build for validation, not the final 0.12.0 publication.

## 0.11.0 — 2026-08-08

### Added

- Every successful evaluation now carries an orthogonal transformation
  resolution: `computed`, `transformed`, `unchanged_proved`, `residual`,
  `unsupported`, or `indeterminate`. Transformation metadata identifies the
  operation, stable reason, and supported mathematical domain where relevant.
- Persistent JSON Lines adds read-only `compute` and explicit `define`
  operations. MCP adds `centl_compute` and `centl_define` with accurate
  read-only/idempotence annotations and exact discriminated output schemas.
- `describe` and `centl_capabilities` publish resolution statuses, supported
  mathematical domains, examples, limits, and cancellation behavior.
- `session` and `centl_session` return immutable definitions in creation order
  with canonical expressions and direct dependencies.
- `help` and `centl_help` provide focused structured help generated from the
  canonical syntax catalog.
- Machine errors include retryability, structured source ranges, named limit
  details, and recovery suggestions when known.
- An executable agent-tool corpus covers correct calls, supported-domain
  selection, residual recognition, read-only rejection, cancellation, limit
  failures, exact sequences, substitution, define-only validation, and
  unresolved equations.
- MCP tool text content now mirrors human residual annotations and includes
  recovery suggestions on mathematical tool errors, while structured content
  remains the canonical machine result.
- End-to-end CLI coverage exercises `compute`/`define`/`session`/`help` and
  residual classification on human, JSON Lines, and MCP surfaces.

### Changed

- Residual or unsupported differentiation, integration, simplification,
  expansion, factoring, and solving can no longer look like a completed
  transformation in human, JSON, JSON Lines, or MCP output.
- `centl_calculate` and JSON `evaluate` retain their combined compute/define
  behavior as a documented compatibility route. New automated integrations
  should use the split operations.

Machine protocol version 1 remains unchanged. Successful evaluation responses
now require top-level `resolution`; machine error objects now require
`retryable`. Strict clients should update their response schemas. MCP tool
discovery exposes seven tools instead of two.

## 0.10.0 — 2026-08-04

### Added

- `sequence(expression, variable = lower, upper)` produces an exact finite
  sequence over inclusive integer bounds, with lexical index scope and a
  defined empty result.
- `recurrence(initial, previous = step, index = lower, upper)` produces an
  exact first-order bounded recurrence. The initial value occupies the lower
  index and every later term receives the previous exact value and its current
  index.
- Exact sequences have a structured protocol value, provenance, and identical
  behavior through one-shot JSON, persistent JSON Lines, and MCP.
- Real quadratic equations with positive nonsquare discriminants now return
  verified exact conjugate roots as canonical `center ± sqrt(radicand)` pairs,
  including structured branch, center, and radicand fields.
- Human input supports syntax-aware multiline statements in the calculator,
  standard-input scripts, and `--file` scripts. Syntax and runtime mathematical
  diagnostics now retain source locations; human output includes a caret
  excerpt and machine errors expose a stable zero-based byte position.
- Interactive terminals provide built-in and session-name completion plus
  private, versioned, bounded history shared safely across calculator
  processes. `:history`, `:clear-history`, `--no-history`, and environment
  opt-outs make persistence explicit and controllable.
- Deterministic parser/protocol/native mutation corpora, exact-rational
  metamorphic checks, ASan/UBSan coverage of the production Arb shim, and
  conservative startup/evaluation performance budgets provide reproducible
  hardening gates.
- A pinned opam manifest, contributor bootstrap, honest formatting and lint
  gates, and a focused pull-request verification workflow make the development
  path reproducible.

### Changed

- Exact rendering now uses an explicit traversal stack and bounded buffer
  construction, including cancellation-aware size preflight, so deeply nested
  symbolic results do not depend on the OCaml call stack.
- Sequences and recurrences share the existing request-wide iteration, exact
  bit, symbolic node, serialized-value byte, work, and cancellation limits.
  Aggregate retained sequence elements are checked before a result is returned
  or a definition is committed.
- Empty finite ranges defer session-function expansion as well as evaluation.
  Exact-bit budgets use rational numerator/denominator profiles and validate
  the actual exact payload before output; sequence and enclosure results cannot
  cross scalar-only iteration or symbolic-transformation boundaries.
- Pull requests run the pinned Linux verification, native, quality, and seeded
  Julia/Nemo differential path. Full native packaging remains on `main`, tags,
  and manual runs, and superseded branch runs are cancelled.
- Quadratic completion validates host-supplied integer square-root floor
  witnesses in F*, preserves the existing rational-root representation, and
  applies exact-bit, result-byte, and cooperative-cancellation boundaries.
- MCP calculation and reset responses now advertise separate closed output
  schemas; calculation schemas discriminate every value, definition, error,
  rational solution, and exact real-quadratic solution shape and are allocated
  only during tool discovery.
- Persistent JSON Lines and MCP input use an extracted, directly tested FIFO
  queue with exact count/byte accounting and one separately bounded emergency
  cancellation slot, so ordinary saturation cannot prevent a valid
  cancellation from reaching its target.
- Native release verification installs Git and its runtime prerequisites before
  checkout and asserts that verification runs inside the expected worktree.

Machine protocol version 1 remains unchanged. Consumers that exhaustively
match value kinds must accept the new exact `sequence` kind. Consumers that
inspect `solution_set.solutions` must also accept tagged `real_quadratic`
members alongside the unchanged rational member shape. `sequence` and
`recurrence` are reserved built-in names.

## 0.9.1 — 2026-08-02

### Fixed

- Linux and macOS x86_64 release libraries now target baseline x86-64 and use
  GMP runtime CPU dispatch instead of inheriting the hosted runner's ISA.
- Native release CI executes the packaged Linux binary under an emulated Core 2
  CPU for both exact GMP arithmetic and rigorous MPFR approximation.

The x86_64 native libraries attached to `0.9.0` were tuned for their CI runner
CPU and can exit with an illegal-instruction fault on older x86_64 processors.
Source builds, Windows, and macOS arm64 artifacts are unaffected; use `0.9.1`
for portable Linux and macOS x86_64 packages.

## 0.9.0 — 2026-08-02

### Added

- Exact inclusive `sum(expression, variable = lower, upper)` and
  `product(expression, variable = lower, upper)`, including nested iteration,
  exact rational or symbolic results, and defined empty ranges.
- `integrate(p, x)` for the canonical zero-constant antiderivative of an exact
  rational-coefficient univariate polynomial.
- `integrate(p, x = a, b)` for exact definite integration over exact rational
  bounds.
- Explicit residual `integrate(...)` expressions for unsupported integrands or
  bounds; CENTL does not guess or silently approximate them.
- Structured provenance for every machine result and request-scoped cooperative
  cancellation across JSON Lines and MCP.
- Pinned Julia/Nemo differential tests, formatting and lint gates, and expanded
  adversarial coverage.

### Changed

- Substitution is simultaneous and capture-avoiding across iteration,
  integration, differentiation, solving, and substitution binders.
- Bounded FIFO input queues, aggregate session and result limits, atomic
  definition commits, and symbolic-work preflight harden persistent operation.
- The verified core now covers semantic differentiation, polynomial
  antiderivative coefficient round trips, outward decimal rounding, and
  logarithmic exact-power properties.

The accepted polynomial syntax uses positive powers no larger than 64.
Explicit zero powers remain residual so the evaluator does not erase a possible
`0^0` error.

Machine protocol version 1 and existing value kinds remain unchanged. Machine
responses now include top-level provenance; strict response-schema consumers
may need to accept that required field. `sum`, `product`, and `integrate` are
reserved built-in names.

## 0.8.0

Added persistent JSON Lines and MCP operation. See the repository history and
release notes for the complete change record.
