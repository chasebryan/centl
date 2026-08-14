![Free Computation Foundation — FCF and camel banner](assets/branding/fcf-centl-banner.png)

# CENTL OASIS

**The authoritative standard-product line for CENTL.**

> Good maths should be free.

CENTL is exact-first mathematics, physics, and scientific computation for GNU/Linux. Its governing numerical rule is simple: **never manufacture mathematical certainty**. Exact values remain exact, approximations carry explicit justification, unsupported work remains visible, and untrusted semantic tooling cannot promote its own claims into verified CENTL mathematics.

## Current release status

> **CENTL v0.14.0 is an Oasis release.**

This is the first CENTL release prepared under the complete repeatable Oasis standard: repository reconciliation, stable-boundary review, mathematical verification, deterministic and adversarial testing, security convergence, package and installer validation, exact hosted proof, and publication of the already-qualified release bytes.

The declaration belongs to the exact source commit that passes the final Oasis gate. This release branch is intentionally tested **before** it becomes authoritative; it may be promoted to `oasis` only without changing that green SHA. The `v0.14.0` tag and published archive must then bind to that same commit.

Oasis is not a codename or a SemVer suffix. It is a repeatable quality classification. Stable tags remain ordinary versions such as `v0.14.0`.

See [The CENTL Oasis Release Standard](docs/OASIS.md), [Oasis promotion](docs/OASIS-PROMOTION.md), and [CENTL release and branch policy](docs/RELEASE-POLICY.md).

## What `oasis` means

The lowercase `oasis` branch is CENTL's authoritative standard-product branch. Stable release identity, recommended installation, supported product claims, and public release declarations come from this branch.

The other long-lived branches deliberately have different jobs:

- [`mirage`](https://github.com/chasebryan/centl/tree/mirage) is the development and research laboratory for new features, experiments, speculative mathematics, architecture work, and self-development research.
- [`main`](https://github.com/chasebryan/centl/tree/main) is the comprehensive developer and research distribution and may contain integrated experimental material that has not earned Oasis assurance.

> **Oasis is a promotion state, not a property of every commit.**

## Standard native product

The v0.14.0 standard GNU/Linux release archive installs three supported command surfaces:

- `centl` — exact calculator, numerical language, verification engine, JSON protocol, and MCP interface;
- `centl-physics` — exact-first typed physics operations, units, vectors, mechanics, and diagnostics;
- `centl-sci` — answer-first mathematics and physics interaction with user-owned extension workflows.

The native release target is **GNU/Linux x86_64**. Historical macOS and Windows implementation material may remain in repository history, but it is not part of the active Oasis release promise.

Install the standard product from the authoritative line:

```sh
curl -fsSLO https://raw.githubusercontent.com/chasebryan/centl/oasis/install
sh install
```

Then start the scientific interface:

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

Expected exact-first results include:

```text
3/10
x in {2, 3}
verdict: verified (closed_exact_rational via closed_rational_comparison); comparison=equal
1
```

The installer verifies the release checksum, rejects unsafe archive structure, stages the package away from the active installation, smoke-tests the installed commands, and only then activates the new version.

See [Installation](docs/INSTALL.md) for the complete supported path.

## CENTL-SCi v0.0.2-Caramels

Caramels is the current scientific interaction generation. It lets users express supported mathematics and physics in ordinary language while CENTL's deterministic and verified machinery remains the authority for the result.

It includes deterministic exact fast paths, evidence-backed presentation, clarification for underspecified requests, persistent user workspaces and revisions, controlled BUILD/self-extension workflows, and an optional local semantic model behind a closed validation boundary.

A local model is an interpreter of intent, **not a mathematical authority**. Generated or external semantics cannot promote themselves into verified CENTL core.

See [CENTL-SCi](docs/SCI.md) and [Caramels BUILD](docs/CARAMELS-BUILD.md).

## CENTL-MIRAGE boundary

CENTL-MIRAGE, the **Mathematical Introspective Recursive Autonomous Growth Engine**, is present in the v0.14.0 source baseline as a bounded local self-development bootstrap.

The admitted v0.14.0 boundary includes specification ingestion, SHA-256 provenance, typed goal/capability analysis, conflict and gap detection, deterministic candidate materialization where supported, parser evidence, evidence obligations and plans, readiness/admission/review artifacts, and non-mutating candidate transactions.

MIRAGE does **not** gain verified-core authority merely because its source is present on Oasis. Generated candidates remain untrusted until they cross the applicable parser, type/dimension, regression, rollback, trust, and verification boundaries. v0.14.0 does not claim autonomous promotion of generated source into the verified core.

The standard v0.14.0 native archive does not install `centl-mirage` as one of the three public release commands listed above. MIRAGE remains an explicitly bounded source/laboratory capability for this release unless a later independently qualified release promotes that command surface.

See [CENTL-MIRAGE](docs/CENTL-MIRAGE.md).

## CENTL CARAVAN Phase 1 boundary

CENTL CARAVAN is included in the v0.14.0 source baseline as a **Phase 1 local laboratory** for authenticated, content-addressed artifact preservation and availability.

Its governing invariant is:

> **A carrier may provide bytes, but a carrier may never define which bytes are trusted.**

The laboratory includes bounded content-addressed storage, deterministic chunk identities, Ed25519 carrier identity, signed policy acceptance, TUF-authenticated catalogs, outbound-only laboratory transport, capacity and resource ceilings, verified multi-carrier retrieval, and bad-carrier quarantine/fallback behavior.

This is **not** authorization for arbitrary public volunteer enrollment or a production public carrier network. Public deployment, abuse operations, privacy/telemetry policy, and production rollout remain outside the v0.14.0 Oasis product boundary.

CARAVAN is not installed as a command in the standard v0.14.0 native archive.

See [CARAVAN](docs/CARAVAN.md), [CARAVAN threat model](docs/CARAVAN-THREAT-MODEL.md), and [CARAVAN rollout](docs/CARAVAN-ROLLOUT.md).

## Numerical contract

CENTL's stable behavior is intentionally conservative:

- integers, fractions, and decimal literals are exact values;
- exact results remain exact for as long as the admitted mathematics permits;
- requested approximations return justified enclosures rather than unqualified floating-point guesses;
- mathematical and physical dimension errors fail explicitly;
- unsupported or unresolved operations remain unsupported or unresolved;
- generated, external, or model-produced semantics cannot promote themselves to verified CENTL core;
- every unqualified printed digit must be justified.

## Oasis qualification

The public qualification command is:

```sh
./scripts/oasis
```

The engine is fail-closed. It checks the executing pinned toolchain, release-metadata coherence, F* verification and fresh extraction identity, formatting and repository quality, source integrity and supply-chain pins, native and Python suites, mandatory sanitizer-backed hardening, fuzz/metamorphic/performance coverage, Julia/Nemo differential validation, CENTL-SCi interface behavior, release packaging, hostile archive structure, isolated installation, and durable evidence generation.

The final v0.14.0 release path additionally requires authentic successful hosted jobs named `Adversarial engine self-test`, `Full stable-product convergence`, and `Release security state` on the **exact final SHA**. The same successful run preserves the archive that is eligible for publication. The release latch refuses to rebuild substitute bytes.

A green badge alone is not an Oasis declaration if known release-blocking work remains.

## Development flow

The ordinary maturity path is:

```text
feature / research work
         |
         v
      mirage
         |
         | stabilize + satisfy the complete Oasis gate
         v
       oasis
         |
         v
 stable release / tag
```

`main` remains the integrated developer/research distribution rather than another maturity rung.

Contribution targeting is defined in [CONTRIBUTING.md](CONTRIBUTING.md) and [docs/RELEASE-POLICY.md](docs/RELEASE-POLICY.md).

`mirage` is not a full release. You may still check it out and build it if you want experimental surfaces. Recommended stable installation remains the published Oasis identity on `oasis` (`v0.14.0`). A later candidate must contain the current oasis tip; Oasis does not regress.

## Documentation

- [Oasis release standard](docs/OASIS.md)
- [Oasis convergence engine](docs/OASIS-ENGINE.md)
- [Oasis promotion and publication](docs/OASIS-PROMOTION.md)
- [Branch and release policy](docs/RELEASE-POLICY.md)
- [v0.14.0 release notes](docs/releases/0.14.0.md)
- [Repository map](docs/REPOSITORY-MAP.md)
- [Security policy and threat boundaries](SECURITY.md)
- [Installation](docs/INSTALL.md)
- [CENTL-SCi](docs/SCI.md)
- [Syntax](docs/SYNTAX.md)
- [Mathematics](docs/MATHEMATICS.md)
- [Numerical contract](docs/NUMERICS.md)
- [Physics](docs/PHYSICS.md)
- [Verification](docs/VERIFICATION.md)
- [Machine protocol](docs/PROTOCOL.md)
- [MCP adapter](docs/MCP.md)
- [Architecture](docs/DESIGN.md)
- [Roadmap](docs/ROADMAP.md)
- [Changelog](CHANGELOG.md)

## License

FCF-owned CENTL software is licensed under the **Apache License 2.0** (`Apache-2.0`). Project documentation is licensed under **CC BY 4.0** where identified, while official FCF/CENTL branding is governed separately so forks remain free without being mistaken for official releases.

See [LICENSING.md](LICENSING.md), [TRADEMARKS.md](TRADEMARKS.md), and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

Developed under the **Free Computation Foundation**.

> **Free for science.**
