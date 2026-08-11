![Free Computation Foundation - FCF and camel banner](assets/branding/fcf-centl-banner.png)

# CENTL OASIS

**The authoritative standard-product branch for CENTL.**

> Good maths should be free.

CENTL is exact-first mathematics, physics, and scientific computation for
GNU/Linux. Its governing numerical rule is simple: **never manufacture
mathematical certainty**.

Exact values remain exact, approximations carry explicit justification, invalid or
unsupported work stays visible, and semantic tooling is never allowed to overrule
the mathematical evidence produced by CENTL itself.

## What this branch means

`oasis` is the branch on which CENTL makes its stable-product promises.

A change may be useful, innovative, or fully functional on another branch without
being Oasis-qualified. Work becomes eligible for the stable product only after it
is promoted here and passes the complete Oasis gate.

> **Oasis is a promotion state, not a property of every commit.**

The authoritative policies are:

- [CENTL release and branch policy](docs/RELEASE-POLICY.md)
- [The CENTL Oasis Release Standard](docs/OASIS.md)

The other long-lived branches have deliberately different roles:

- [`mirage`](https://github.com/chasebryan/centl/tree/mirage) is the development,
  research, prototype, and experimentation laboratory. It intentionally uses a
  lighter development gate.
- [`main`](https://github.com/chasebryan/centl/tree/main) is the comprehensive
  developer and research distribution containing the broad CENTL codebase.

Neither branch inherits Oasis assurance merely by containing code that also exists
here.

## Current release status

**CENTL v0.14.0 is being qualified as the first Oasis release.**

Until every applicable Oasis gate has completed successfully, its status remains:

> **Oasis candidate**

A release is declared Oasis only after the exact reviewed `oasis` commit has passed
the required formatting, build, deterministic testing, mathematical verification,
integrity, security, documentation, packaging, reproducibility, installation, and
release-identity gates.

The final stable tag remains ordinary Semantic Versioning, for example `v0.14.0`.
Oasis is a quality declaration, not a version suffix.

## Standard-product installation

CENTL is developed, validated, packaged, and released for **GNU/Linux**.

Install the standard-product line directly from this branch:

```sh
curl -fsSLO https://raw.githubusercontent.com/chasebryan/centl/oasis/install
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

Expected exact-first behavior includes results such as:

```text
3/10
x in {2, 3}
verdict: verified (closed_exact_rational via closed_rational_comparison); comparison=equal
1
```

For installation details and offline archives, see
[docs/INSTALL.md](docs/INSTALL.md).

## Stable-product boundary

The Oasis line may include only capabilities that have crossed the applicable
qualification boundary. Presence elsewhere in CENTL does not automatically make a
feature part of the stable product.

The standard product is built around:

- `centl`, the exact calculator, numerical language, verification engine, JSON
  protocol, and MCP interface;
- `centl-sci`, the answer-first mathematics and physics interaction surface;
- `centl-physics`, exact-first typed physics operations, units, vectors, mechanics,
  and diagnostics;
- additional subsystems only when their specific release gates have been satisfied
  and the release documentation explicitly includes them.

MIRAGE experiments, CARAVAN laboratory work, local extensions, generated material,
and model-produced proposals must not inherit stable or verified-core assurance by
proximity.

## Numerical contract

CENTL's stable behavior is intentionally conservative:

- integers, fractions, and decimal literals are exact values;
- exact results remain exact for as long as the admitted mathematics permits;
- requested approximations return justified enclosures rather than unqualified
  floating-point guesses;
- mathematical and physical dimension errors fail explicitly;
- unsupported or unresolved operations remain unsupported or unresolved;
- generated, external, or model-produced semantics cannot promote themselves to
  verified CENTL core;
- every unqualified printed digit must be justified.

## Qualification model

The ordinary path into the standard product is:

```text
feature / research work
         |
         v
      mirage
         |
         | stabilize + complete Oasis qualification
         v
       oasis
         |
         v
 stable release / tag
```

Oasis CI is intentionally stricter than Mirage CI. This branch is where formatting,
verification, integrity, security, release reproducibility, and other product gates
become mandatory rather than aspirational.

## Development and research

Ordinary users should use qualified Oasis releases. Developers and researchers who
want the entire active CENTL tree should use `main`. New experimental work should
normally be developed through `mirage` or a short-lived branch targeting it.

Contribution targeting rules are defined in
[docs/RELEASE-POLICY.md](docs/RELEASE-POLICY.md).

## Documentation

- [Oasis release standard](docs/OASIS.md)
- [Branch and release policy](docs/RELEASE-POLICY.md)
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

FCF-owned CENTL software is licensed under the **Apache License 2.0**
(`Apache-2.0`). Project documentation is licensed under **CC BY 4.0** where
identified, while official FCF/CENTL branding is governed separately so forks
remain free without being mistaken for official releases.

See [LICENSING.md](LICENSING.md), [TRADEMARKS.md](TRADEMARKS.md), and
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for the complete license map.

Developed under the **Free Computation Foundation**.

> **Free for science.**
