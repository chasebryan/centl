![Free Computation Foundation — FCF and camel banner](assets/branding/fcf-centl-banner.png)

# CENTL

**Exact-first mathematics, physics, and scientific computation for GNU/Linux.**

> Good maths should be free.

CENTL is built around a simple rule: **never manufacture mathematical certainty**.
Exact values remain exact, approximations carry explicit justification, invalid or
unsupported work stays visible, and semantic tooling is never allowed to overrule
the mathematical evidence produced by CENTL itself.

**Current consolidation line: CENTL v0.14.0 — Oasis.** Oasis integrates the
validated post-v0.12 work, CENTL-MIRAGE, and the CARAVAN Phase 1 local laboratory
into one deliberately organized and hardened baseline. The intermediate v0.13.0
development line was not formally published as a stable release.

CENTL combines five closely related pieces:

| Surface | Purpose |
| --- | --- |
| `centl` | Exact calculator, numerical language, verification engine, JSON protocol, and MCP interface |
| `centl-sci` | Answer-first mathematics and physics interpreter with user-owned extension workflows |
| `centl-physics` | Exact-first typed physics operations, units, vectors, mechanics, and diagnostics |
| **CENTL-MIRAGE** | Local introspective self-development bootstrap for specification ingestion, capability analysis, evidence obligations, and staged candidate transactions |
| **CENTL CARAVAN** | Content-addressed authenticated preservation and availability system, shipped in Oasis as a bounded Phase 1 local laboratory |

## Quick start

CENTL is developed, validated, packaged, and released for **GNU/Linux**.

```sh
curl -fsSLO https://raw.githubusercontent.com/chasebryan/centl/main/install
sh install
```

If the installer adds `~/.local/bin` to your shell configuration, open a new
terminal once. Then launch the scientific interface:

```sh
centl-sci
```

Or use the exact command surfaces directly:

```sh
centl '0.1 + 0.2'
centl 'solve(x^2 - 5*x + 6 = 0, x)'
centl verify --left '0.1 + 0.2' --relation equal --right '3/10'
centl-physics convert 100 cm m
```

```text
3/10
x in {2, 3}
verdict: verified (closed_exact_rational via closed_rational_comparison); comparison=equal
1
```

The native installer verifies its release checksum, stages and smoke-tests the
package before activation, validates exact arithmetic and physics conversion, and
activates the command launchers atomically.

For full installation details and offline archives, see
[docs/INSTALL.md](docs/INSTALL.md).

## CENTL-SCi — v0.0.2-Caramels

**Caramels** is the current CENTL-SCi interaction generation: a local scientific
interface for expressing mathematics and physics in ordinary language while
keeping CENTL's exact and verified machinery in control of the answer.

A typical session is intentionally small:

```text
CENTL-SCi v0.0.2-Caramels
Free for science.

> What is 0.1 plus 0.2?
3/10
> Solve x squared minus 5x plus 6 equals zero.
x = 2 or x = 3
> Solve -4.9*t^2 + 20*t = 0 for t.
t = 0 or t = 200/49
>
```

The final result remains `200/49` rather than being silently collapsed into an
arbitrary floating-point decimal.

Caramels provides:

- deterministic fast paths for exact arithmetic, equations, algebraic transforms,
  certified approximation, units, constants, and supported mechanics;
- `MATH>`, `PHYS>`, `HYBRID>`, and `BUILD>` interaction modes;
- evidence-backed interpretation and explanation rather than opaque answer text;
- clarification when a problem is underspecified instead of invented values;
- persistent user workspaces, revisions, snapshots, extension packages, and
  dependency-aware activation;
- a user-owned BUILD surface for extending CENTL without silently redefining the
  verified core;
- optional local semantic-model interpretation behind a closed validation boundary.

A local language model, when configured, is an **interpreter of intent — not a
mathematical authority**. Model output must pass CENTL-SCi's typed problem boundary
and is lowered into CENTL or CENTL Physics before a result can inherit mathematical
meaning. Model weights remain separate artifacts and are never silently downloaded.

See [docs/SCI.md](docs/SCI.md) for the interaction architecture and
[docs/CARAMELS-BUILD.md](docs/CARAMELS-BUILD.md) for the self-extension model.

![CENTL-MIRAGE — a camel appearing through desert heat haze](assets/branding/centl-mirage.png)

## CENTL-MIRAGE

**Mathematical Introspective Recursive Autonomous Growth Engine**

CENTL-MIRAGE is the local self-development architecture for CENTL-SCi. Its purpose
is to let a user describe a system, capability, mathematical workflow, or design in
ordinary language and let CENTL turn that intent into an explicit, inspectable,
reversible development process without requiring a paid or remote AI service.

MIRAGE is not a chatbot that is trusted to rewrite source code. It is a recursive
engineering architecture built around CENTL's existing rule that claims require
evidence. The long-term cycle is:

```text
INGEST
  -> NORMALIZE
  -> BUILD GOAL GRAPH
  -> INTROSPECT CAPABILITIES
  -> COMPUTE GAPS
  -> SYNTHESIZE CANDIDATES
  -> CONSTRUCT OBLIGATIONS
  -> VERIFY / SEARCH FOR COUNTEREXAMPLES
  -> COMPARE WITH BASELINE
  -> ACCEPT OR REJECT
  -> RECORD REVISION + EVIDENCE
  -> RECOMPUTE GAPS
```

The Oasis bootstrap implements the controlled front half of that architecture. A
user document remains attributable source material. MIRAGE preserves provenance,
lowers the document into a Specification IR, constructs a typed goal/capability
graph, detects conflicts, and first asks whether an existing CENTL capability can
satisfy the request through composition before creating anything new.

MIRAGE then constructs explicit evidence obligations and stages a non-mutating
candidate transaction describing the smallest currently justified strategy. The
transaction records matched capability inputs and mandatory obligations while
explicitly retaining `workspace_mutated=false` and `assurance_promoted=false`.
Ambiguous, conflicting, or policy-blocked goals do not become guessed source edits.

Candidate changes are admitted only after explicit engineering and assurance gates.
The architecture separates hard admissibility from preference: parsing, type and
dimension safety, invariants, regressions, provenance, trust boundaries, and
rollback requirements come before any candidate is scored or preferred. Among
admissible candidates, MIRAGE favors the smallest semantic delta, stronger evidence,
native CENTL mechanisms, lower dependency surface, and preserved behavior.

The local command surface includes `centl-mirage start PATH`, `ingest`, `analyze`,
and `status`. Actual autonomous source mutation, CEGIS/equality-saturation execution,
semantic behavioral fingerprints, obligation execution, and monotone autonomous
acceptance/rejection remain later MIRAGE layers.

A local semantic model may propose interpretations, programs, tests, names, or
refactorings, but it never confers mathematical or engineering authority. Its output
must cross the same CENTL parsing, validation, testing, regression, and verification
boundaries as every other candidate.

MIRAGE autonomy is local. It does not imply automatic network publication, and a
user-provided document is always treated as data rather than executable authority.

See [docs/CENTL-MIRAGE.md](docs/CENTL-MIRAGE.md) for the full architecture and
implemented Oasis boundary.

## CENTL CARAVAN

**Content-Addressed Resilient Artifact Verification and Availability Network**

Oasis ships the completed **CARAVAN Phase 1 local laboratory**. It is a bounded,
reproducible environment for protecting and retrieving approved CENTL/FCF artifacts;
it is **not** authorization for arbitrary public volunteer enrollment.

CARAVAN is designed as the preservation and availability layer for approved CENTL
and FCF artifacts, so ordinary Linux machines can contribute bounded storage and
bandwidth without becoming authorities over the content they carry.

> A carrier may provide bytes, but a carrier may never define which bytes are trusted.

CARAVAN separates **availability** from **authority**. Artifact identity is bound
to authenticated metadata, exact byte lengths, cryptographic whole-file identity,
and deterministic chunk identities. A carrier can replicate an artifact, but it
cannot redefine the artifact that CENTL expects.

The Phase 1 laboratory includes:

- content-addressed immutable storage with integrity-checked promotion;
- exact whole-file SHA-256 plus deterministic 4 MiB chunk records;
- Ed25519 pseudonymous carrier identity and live proof of possession;
- signed policy-acceptance receipts without host/user identity fields;
- TUF-authenticated artifact catalogs with an independently supplied trust root;
- outbound-only laboratory carrier/coordinator sessions with bounded bodies,
  polling, concurrency, reconnect behavior, and resource use;
- short-lived, artifact/carrier-bound, single-use retrieval capabilities;
- verified multi-carrier retrieval with automatic quarantine and fallback when a
  carrier supplies incorrect bytes;
- hostile-transfer rejection for corruption, ordering errors, truncation, and
  appended bytes;
- explicit `join`, `status`, and `leave` lifecycle plus a reproducible local lab.

Production relay deployment, public enrollment, final privacy/telemetry policy,
abuse operations, and the other public-network rollout gates remain separate work.
CARAVAN does not claim global anonymity or protection against every traffic-analysis
adversary.

Architecture and policy are documented in
[docs/CARAVAN.md](docs/CARAVAN.md),
[docs/CARAVAN-THREAT-MODEL.md](docs/CARAVAN-THREAT-MODEL.md),
[docs/CARAVAN-HOST-POLICY.md](docs/CARAVAN-HOST-POLICY.md), and
[docs/CARAVAN-ROLLOUT.md](docs/CARAVAN-ROLLOUT.md).

## The numerical contract

CENTL's behavior is intentionally conservative:

- integers, fractions, and decimal literals are exact values;
- exact results remain exact for as long as the admitted mathematics permits;
- requested approximations return justified enclosures rather than unqualified
  floating-point guesses;
- mathematical and physical dimension errors fail explicitly;
- unsupported or unresolved operations remain unsupported or unresolved;
- generated, external, or model-produced semantics cannot promote themselves to
  verified CENTL core;
- every unqualified printed digit must be justified.

## CENTL Physics

CENTL Physics provides exact rational unit conversion, SI dimensional analysis,
3D vector and particle operations, force and gravity evaluation, energy and
momentum diagnostics, bounded collision/contact reasoning, and narrow exact
event-aware mechanics contracts.

It does not pretend to be a universal physics simulator. Supported domains and
known boundaries are documented explicitly in [docs/PHYSICS.md](docs/PHYSICS.md).

## Linux-first platform policy

GNU/Linux is the sole reference platform for current development, CI, packaging,
validation, installation, and release work. macOS and Windows are not active
support targets.

Historical portability code may remain in the repository where retaining it is
less disruptive than deleting it, but current CENTL engineering is intentionally
focused on one environment that can be tested, reproduced, and improved quickly.
See [docs/SCI_PLATFORM_SUPPORT.md](docs/SCI_PLATFORM_SUPPORT.md) for the platform
policy.

## Development

Native releases are recommended for ordinary use. Development from source uses
the pinned toolchain and verified F* extraction path on Linux:

```sh
scripts/bootstrap-opam
eval "$(opam env --switch=centl)"
make test
```

Contributor setup is documented in [docs/ONBOARDING.md](docs/ONBOARDING.md) and
[CONTRIBUTING.md](CONTRIBUTING.md).

The supported source-tree organization is documented in
[docs/REPOSITORY-MAP.md](docs/REPOSITORY-MAP.md).

## Documentation

- [CENTL-SCi](docs/SCI.md)
- [Caramels BUILD and self-extension](docs/CARAMELS-BUILD.md)
- [CENTL-MIRAGE](docs/CENTL-MIRAGE.md)
- [CENTL CARAVAN](docs/CARAVAN.md)
- [CARAVAN threat model](docs/CARAVAN-THREAT-MODEL.md)
- [CARAVAN host policy](docs/CARAVAN-HOST-POLICY.md)
- [CARAVAN rollout](docs/CARAVAN-ROLLOUT.md)
- [Installation](docs/INSTALL.md)
- [Syntax](docs/SYNTAX.md)
- [Mathematics](docs/MATHEMATICS.md)
- [Numerical contract](docs/NUMERICS.md)
- [Physics](docs/PHYSICS.md)
- [Verification](docs/VERIFICATION.md)
- [Machine protocol](docs/PROTOCOL.md)
- [MCP adapter](docs/MCP.md)
- [Architecture](docs/DESIGN.md)
- [Repository map](docs/REPOSITORY-MAP.md)
- [Oasis release notes](docs/releases/0.14.0.md)
- [Roadmap](docs/ROADMAP.md)
- [Changelog](CHANGELOG.md)

## License

FCF-owned CENTL software is licensed under the **Apache License 2.0** (`Apache-2.0`).
Project documentation is licensed under **CC BY 4.0** where identified, while
official FCF/CENTL branding is governed separately so forks remain free without
being mistaken for official releases.

See [LICENSING.md](LICENSING.md), [TRADEMARKS.md](TRADEMARKS.md), and
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for the complete license map.

Developed under the **Free Computation Foundation**.

> **Free for science.**
