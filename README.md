![Free Computation Foundation — FCF and camel banner](assets/branding/fcf-centl-banner.png)

# CENTL

**Exact-first mathematics, physics, and scientific computation for GNU/Linux.**

> Good maths should be free.

CENTL is built around one rule: **never manufacture mathematical certainty**.

Exact values remain exact when the admitted mathematics permits it. Approximations carry explicit evidence. Unsupported or indeterminate work stays visible. Semantic models may help interpret intent, but they cannot overrule the mathematical evidence produced by CENTL itself.

> **Every unqualified printed digit must be justified.**

## Current stable release

**CENTL v0.14.0 is an Oasis release.**

v0.14.0 is the current stable CENTL baseline for **GNU/Linux x86_64**. It consolidates the validated post-v0.12 development line, CENTL-SCi v0.0.2-Caramels, bounded MIRAGE work, and the CARAVAN Phase 1 laboratory into one reviewed and hardened release boundary. The intermediate v0.13.0 line was never published as a stable release.

**Oasis** is a repeatable quality declaration, not a version suffix or codename. A release earns the declaration only when its exact source identity has been reconciled, hardened, validated, qualified, and published through the Oasis gate.

Stable product authority lives on [`oasis`](https://github.com/chasebryan/centl/tree/oasis). The `main` branch is the complete developer and research distribution and may contain work that is newer or more experimental than the stable product.

See [The CENTL Oasis Release Standard](docs/OASIS.md) and [Release and Branch Policy](docs/RELEASE-POLICY.md).

## What CENTL contains

| Surface | Purpose |
| --- | --- |
| `centl` | Exact calculator, numerical language, verification engine, JSON protocol, and MCP interface |
| `centl-sci` | Local answer-first mathematics and physics interpreter with evidence-backed natural-language interaction |
| `centl-physics` | Exact-first typed physics operations, units, vectors, mechanics, and diagnostics |
| **CENTL-MIRAGE** | Local introspective self-development architecture for specification ingestion, capability analysis, staged candidates, and evidence planning |
| **CENTL CARAVAN** | Content-addressed authenticated preservation and availability architecture for approved FCF artifacts |

The standard v0.14.0 native archive installs `centl`, `centl-sci`, and `centl-physics`. MIRAGE and CARAVAN work included in the source baseline does not silently become a supported public command merely because it exists in the repository.

## Install

For the standard product, install from the authoritative Oasis branch:

```sh
curl -fsSLO https://raw.githubusercontent.com/chasebryan/centl/oasis/install
sh install
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

The installer validates release identity and integrity, stages the package, smoke-tests the installed command surfaces, and activates them only after those checks succeed.

See [Installation](docs/INSTALL.md) for the complete installation and offline-recovery paths.

## The numerical contract

CENTL is intentionally conservative:

- integers, fractions, and decimal literals are exact values;
- exact results remain exact for as long as the admitted mathematics permits;
- requested approximations return justified enclosures rather than unqualified floating-point guesses;
- mathematical and physical dimension errors fail explicitly;
- unsupported or unresolved operations remain unsupported or unresolved;
- generated, external, or model-produced semantics cannot promote themselves to verified CENTL core;
- mathematical claims are separated from presentation and interpretation;
- every unqualified printed digit must be justified.

This is the center of the project. Speed, convenience, and semantic assistance are useful only when they do not counterfeit certainty.

## CENTL-SCi: Caramels

**CENTL-SCi v0.0.2-Caramels** is the current scientific interaction generation. It lets a user express mathematics and physics in ordinary language while CENTL's deterministic machinery remains responsible for the result.

```text
CENTL-SCi v0.0.2-Caramels
Free for science.

> What is 0.1 plus 0.2?
3/10

> Solve x squared minus 5x plus 6 equals zero.
x = 2 or x = 3
```

Caramels provides deterministic fast paths, mathematics/physics/hybrid interaction modes, evidence-backed explanations, clarification instead of invented assumptions, persistent user workspaces, and controlled BUILD/self-extension workflows.

A configured local language model is an **interpreter of intent, not a mathematical authority**. Model-produced semantics must cross CENTL's typed and deterministic boundaries before a result can inherit mathematical meaning.

See [CENTL-SCi](docs/SCI.md) and [Caramels BUILD](docs/CARAMELS-BUILD.md).

## CENTL-MIRAGE

**Mathematical Introspective Recursive Autonomous Growth Engine**

MIRAGE is CENTL's local self-development architecture. It is designed to turn user-supplied specifications and ordinary-language engineering intent into explicit, inspectable, reversible development artifacts rather than granting a model permission to rewrite trusted source code unchecked.

The architecture preserves provenance, builds typed goals and capability graphs, computes gaps, prefers reuse and composition before new implementation, constructs evidence obligations, and stages candidate work behind explicit admission boundaries.

MIRAGE does not grant generated material verified-core authority. Candidate source, model proposals, and user documents must cross the same parsing, testing, regression, provenance, trust, and verification boundaries required of other CENTL work.

See [CENTL-MIRAGE](docs/CENTL-MIRAGE.md).

## CENTL CARAVAN

**Content-Addressed Resilient Artifact Verification and Availability Network**

CARAVAN is the preservation and availability architecture for approved CENTL and Free Computation Foundation artifacts. Its governing invariant is simple:

> **A carrier may provide bytes, but a carrier may never define which bytes are trusted.**

Artifact authority comes from authenticated FCF metadata and exact content identity. Carriers contribute availability, not truth.

The v0.14.0 Oasis boundary includes the bounded Phase 1 local laboratory. Main-line development also contains later enrollment, census, public-origin, and rollout work, but **public volunteer network enrollment remains gated until the corresponding release and operational requirements are satisfied**.

### Joining the CARAVAN is a contribution

Supporting CENTL does not require writing code or sending money. **Running a CARAVAN carrier is itself a form of support.** A participating machine can donate bounded storage, bandwidth, and availability to help preserve approved FCF material and reduce dependence on any single host or provider.

Participation is designed to remain voluntary, resource-capped, rootless for ordinary carriers, reversible, and unable to redefine trusted artifact identity. Until public enrollment is opened for the relevant release channel, users can still help by testing the join path, reviewing the protocol and policy, and preparing compatible carrier systems.

See [CENTL CARAVAN](docs/CARAVAN.md), [Joining the CARAVAN manually](docs/CARAVAN-JOIN-MANUAL.md), [CARAVAN Host Policy](docs/CARAVAN-HOST-POLICY.md), and [CARAVAN Threat Model](docs/CARAVAN-THREAT-MODEL.md).

## Support CENTL

CENTL is developed under the **Free Computation Foundation**. There are several meaningful ways to help:

- contribute code, tests, mathematics, documentation, review, or reproducible bug reports;
- test CENTL on GNU/Linux and report exact failures with enough evidence to reproduce them;
- challenge mathematical or verification claims with counterexamples and independent validation;
- help preserve the software and its dependencies;
- participate in CARAVAN as enrollment becomes available;
- sponsor continued development through [GitHub Sponsors](https://github.com/sponsors/chasebryan).

Infrastructure is a contribution. Verification is a contribution. Preservation is a contribution. Careful criticism is a contribution.

## Branches and contribution flow

CENTL uses three long-lived branches with deliberately different responsibilities:

- **`oasis`** is the authoritative stable-product branch and must satisfy the complete Oasis qualification standard;
- **`mirage`** is the development and research laboratory for features, prototypes, experiments, and incomplete work;
- **`main`** is the comprehensive developer/research distribution and integration view.

Experimental work normally matures on `mirage`. Stable promotions are deliberately qualified into `oasis`. Repository-wide integration and documentation may target `main` according to the branch policy.

Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## Development

CENTL development is intentionally **GNU/Linux-first**. macOS and Windows are not active support targets for current development, CI, packaging, validation, installation, or release work.

From a development checkout:

```sh
scripts/bootstrap-opam
eval "$(opam env --switch=centl)"
make test
make quality
```

The pinned F*, Z3, OCaml, Dune, numerical libraries, formatter, and laboratory versions are recorded in [`toolchain.lock`](toolchain.lock).

Contributor setup and the manual learning path are documented in [CONTRIBUTING.md](CONTRIBUTING.md) and [Contributor Onboarding](docs/ONBOARDING.md).

## Documentation

- [Installation](docs/INSTALL.md)
- [Syntax](docs/SYNTAX.md)
- [Mathematics](docs/MATHEMATICS.md)
- [Numerical contract](docs/NUMERICS.md)
- [Physics](docs/PHYSICS.md)
- [Verification](docs/VERIFICATION.md)
- [Machine protocol](docs/PROTOCOL.md)
- [MCP adapter](docs/MCP.md)
- [CENTL-SCi](docs/SCI.md)
- [Caramels BUILD](docs/CARAMELS-BUILD.md)
- [CENTL-MIRAGE](docs/CENTL-MIRAGE.md)
- [CENTL CARAVAN](docs/CARAVAN.md)
- [CARAVAN join manual](docs/CARAVAN-JOIN-MANUAL.md)
- [Oasis release standard](docs/OASIS.md)
- [Release and branch policy](docs/RELEASE-POLICY.md)
- [Repository map](docs/REPOSITORY-MAP.md)
- [v0.14.0 release notes](docs/releases/0.14.0.md)
- [Roadmap](docs/ROADMAP.md)
- [Changelog](CHANGELOG.md)

## License

FCF-owned CENTL software is licensed under the **Apache License 2.0** (`Apache-2.0`). Project documentation is licensed under **CC BY 4.0** where identified. Official FCF/CENTL names and branding are governed separately so forks remain free without being mistaken for official releases.

See [LICENSING.md](LICENSING.md), [TRADEMARKS.md](TRADEMARKS.md), and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

Developed under the **Free Computation Foundation**.

> **Free for science.**
