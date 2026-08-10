![Free Computation Foundation — FCF and camel banner](assets/branding/fcf-centl-banner.png)

# CENTL

> Good maths should be free.

CENTL is an exact-first mathematics and physics system built to avoid
manufacturing numerical certainty. Exact values stay exact, approximations carry
explicit bounds, and unsupported work remains visible instead of being replaced
by a plausible-looking answer.

**CENTL-SCi** is the simplest way to use it: enter one mathematics or physics
problem at a time and let CENTL perform the admitted computation and verification.
It is a scientific interpreter, not a general chatbot.

## Install

CENTL currently supports **GNU/Linux only**. Linux is the reference development,
validation, packaging, and release platform. Native releases bundle the runtime
components needed to run CENTL; a compiler, OCaml, Dune, OPAM, F*, GMP, MPFR,
and FLINT do not need to be installed separately.

```sh
curl -fsSLO https://raw.githubusercontent.com/chasebryan/centl/main/install
sh install
```

If the installer adds `~/.local/bin` to your shell configuration, open a new
terminal once. Then start the live scientific interface with:

```sh
centl-sci
```

The intended Caramels first-run experience is simply:

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

The last equation can represent idealized vertical motion for an object launched
upward at 20 m/s under `g = 9.8 m/s^2`, neglecting drag. CENTL keeps the nonzero
flight time exact as `200/49` seconds instead of turning it into an arbitrary
floating-point decimal.

For complete Linux installation details and offline archives, see
[docs/INSTALL.md](docs/INSTALL.md). macOS and Windows are currently unsupported;
see [docs/SCI_PLATFORM_SUPPORT.md](docs/SCI_PLATFORM_SUPPORT.md) for the platform
policy.

## What gets installed

Current native packages expose three commands:

- `centl-sci` — live answer-first scientific interpreter;
- `centl` — exact calculator, language, verification, JSON, and MCP interfaces;
- `centl-physics` — exact-first typed physics operations and services.

The installer verifies the release checksum, stages and smoke-tests the package
before activation, validates CENTL exact arithmetic, validates a physics unit
conversion, validates CENTL-SCi exact arithmetic, and then activates the command
launchers atomically.

## Why CENTL

CENTL follows a small set of rules:

- integers, fractions, and decimal literals are exact values;
- exact results remain exact for as long as the admitted mathematics permits;
- requested approximations return justified enclosures rather than unqualified
  floating-point guesses;
- mathematical and physical dimension errors fail explicitly;
- unsupported or unresolved operations remain unsupported or unresolved;
- semantic model output is untrusted and cannot overrule CENTL's mathematical
  evidence;
- every unqualified printed digit must be justified.

For example:

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

## CENTL-SCi

![CENTL-SCi v0.0.2-Caramels — Free Computation Foundation](assets/branding/centl-sci-v0.0.2-caramels-banner.svg)

CENTL-SCi uses a conservative deterministic interpreter first. Current admitted
fast paths include exact arithmetic, single-variable polynomial equations,
spoken polynomial forms, and exact unit conversion. These paths are local and do
not require a language model.

A separately configured local semantic model can interpret problems that require
more language understanding, but it is never the mathematical authority. Model
output must pass the closed Problem IR validator and is then lowered into CENTL
or CENTL Physics. A model cannot manufacture a result that CENTL did not
establish.

Model weights remain separate artifacts and are not silently downloaded by the
installer. This keeps the deterministic scientific runtime immediately usable
while preserving explicit provenance and consent for optional semantic models.

See [docs/SCI.md](docs/SCI.md) for the architecture and evidence boundary and
[docs/SCI_PLATFORM_SUPPORT.md](docs/SCI_PLATFORM_SUPPORT.md) for platform policy.

## CENTL CARAVAN

![CENTL CARAVAN — Content-Addressed Resilient Artifact Verification and Availability Network](assets/branding/fcf-centl-caravan.png)

**Content-Addressed Resilient Artifact Verification and Availability Network**

CENTL CARAVAN is the FCF's developing volunteer preservation and distribution
layer for `public-approved` CENTL artifacts. Ordinary Linux machines can
contribute bounded storage, bandwidth, and availability without becoming content
authorities.

> A carrier may provide bytes, but a carrier may never define which bytes are trusted.

CARAVAN treats volunteer carriers as untrusted storage and transport. Artifact
identity comes from FCF-authenticated metadata, exact byte lengths, and standard
SHA-256 content identities; bad bytes are rejected rather than made trustworthy
by mirror reputation or peer majority.

The normal carrier design is unprivileged and outbound-only: no root or sudo,
public listening port, or router configuration should be required. The default
download path uses FCF relay infrastructure so volunteer carriers do not receive
a downloader's direct network address. The public FCF site is intended to expose
aggregate network health — available caravans, protected artifacts, and verified
replicas — without publishing volunteer endpoints or identities.

CARAVAN is now in its documented local-laboratory implementation phase. The
public volunteer network is **not yet operational**. See
[docs/CARAVAN.md](docs/CARAVAN.md),
[docs/CARAVAN-THREAT-MODEL.md](docs/CARAVAN-THREAT-MODEL.md),
[docs/CARAVAN-HOST-POLICY.md](docs/CARAVAN-HOST-POLICY.md), and
[docs/CARAVAN-ROLLOUT.md](docs/CARAVAN-ROLLOUT.md).

## Physics

CENTL Physics provides exact rational unit conversion, SI dimensional analysis,
3D vector and particle operations, force and gravity evaluation, energy and
momentum diagnostics, bounded collision/contact reasoning, and narrow exact
event-aware mechanics contracts.

It deliberately does not claim a general-purpose physics simulator. Exact
supported domains and known boundaries are documented in
[docs/PHYSICS.md](docs/PHYSICS.md).

## Developers

A native release is recommended for ordinary use. Development from source uses
the pinned toolchain and verified F* extraction path on Linux:

```sh
scripts/bootstrap-opam
eval "$(opam env --switch=centl)"
make test
```

Contributor setup is documented in [docs/ONBOARDING.md](docs/ONBOARDING.md) and
[CONTRIBUTING.md](CONTRIBUTING.md).

## Documentation

- [CENTL-SCi](docs/SCI.md)
- [CENTL CARAVAN](docs/CARAVAN.md)
- [CARAVAN threat model](docs/CARAVAN-THREAT-MODEL.md)
- [CARAVAN volunteer host policy](docs/CARAVAN-HOST-POLICY.md)
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
- [Roadmap](docs/ROADMAP.md)
- [Changelog](CHANGELOG.md)

## License

`SPDX-License-Identifier: AGPL-3.0-or-later`

Developed under the **Free Computation Foundation**.

> Free for science.