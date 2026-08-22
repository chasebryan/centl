# CENTL documentation

This directory is the manual set. The public site hosts the same front-facing
manuals as HTML at [freecomputation.org/docs.html](https://freecomputation.org/docs.html)
and every public research record at
[freecomputation.org/research.html](https://freecomputation.org/research.html).
The repository remains canonical.

## Start here

### CentL26 — Flagship Universal Release

[CentL26](CENTL26-ARCHITECTURE.md) is the single cohesive product direction of
CENTL: the standalone, offline scientific IDE where all computation,
research, and capability work is assembled for users. The 26 identifies the
product year; maintenance updates retain the same CentL26 name while publishing
new immutable build snapshots.
The current **CentL26.10** release combines the
approved visual system, continuous Jupyter-grade notebooks, in-app paper reading,
exact polynomial algebra, higher-order calculus, interactive STEM dynamic visualizer,
academic search omnibar, and universal native support across macOS, Linux, and Windows 11.

Public release documentation: [CentL26.10 Universal Release Notes](releases/26.10.0.md) · [CentL26 release architecture](CENTL26-ARCHITECTURE.md) ·
[design contract](CENTL26-DESIGN-CONTRACT.md) · [native packaging guide](../desktop/centl26/macos/README.md).

| Document | When to open it |
| --- | --- |
| [INSTALL.md](INSTALL.md) · [hosted](https://freecomputation.org/manuals/install.html) | Universal installation across macOS, Linux, Windows 11 |
| [NUMERICS.md](NUMERICS.md) · [hosted](https://freecomputation.org/manuals/numerics.html) | what a printed digit means |
| [ALGEBRA.md](ALGEBRA.md) · [hosted](https://freecomputation.org/manuals/algebra.html) | exact polynomial algebra, rational root solver, equations |
| [CALCULUS.md](CALCULUS.md) · [hosted](https://freecomputation.org/manuals/calculus.html) | derivatives, integration, limits, Taylor series |
| [SCI.md](SCI.md) · [hosted](https://freecomputation.org/manuals/sci.html) | CentL-SCi natural language problem solver & AI co-pilot |
| [CHEMISTRY.md](CHEMISTRY.md) · [hosted](https://freecomputation.org/manuals/chemistry.html) | stoichiometry, reaction balancing, sample spread |
| [SYNTAX.md](SYNTAX.md) · [hosted](https://freecomputation.org/manuals/syntax.html) | CAS syntax & functions reference |
| [MATHEMATICIANS.md](MATHEMATICIANS.md) · [hosted](https://freecomputation.org/manuals/mathematicians.html) | mathematics onboarding |
| [PHYSICISTS.md](PHYSICISTS.md) · [hosted](https://freecomputation.org/manuals/physicists.html) | typed physics onboarding |
| [SCIENCE-DOMAINS-PLAN.md](SCIENCE-DOMAINS-PLAN.md) | full multi-domain science scheme |
| [CENTL26-ARCHITECTURE.md](CENTL26-ARCHITECTURE.md) | standalone CentL26 product and backend architecture |
| [CENTL26-DESIGN-CONTRACT.md](CENTL26-DESIGN-CONTRACT.md) | approved interface freeze and review gate |
| [releases/26.10.0.md](releases/26.10.0.md) | CentL26.10 flagship universal release notes |
| [releases/26.0.0.md](releases/26.0.0.md) | CentL26 initial release notes |

## Use

- [MATHEMATICS.md](MATHEMATICS.md)
- [PHYSICS.md](PHYSICS.md)
- [VERIFICATION.md](VERIFICATION.md)
- [PROTOCOL.md](PROTOCOL.md)
- [MCP.md](MCP.md)

## CENTLAMP information retrieval

CENTLAMP is the **CENTL Authority & Metric Protocol**, an exact-first research
track for inspectable, replayable information retrieval and ranking.

- [CENTLAMP.md](CENTLAMP.md) — purpose, architecture, ranking principles, trust
  boundary, evaluation discipline, and first vertical slice.
- [CENTLAMP-RANK-CERTIFICATE.md](CENTLAMP-RANK-CERTIFICATE.md) — version-zero
  contract for explaining and replaying a result ordering.
- [CENTLAMP-TODO.md](CENTLAMP-TODO.md) — staged research and implementation
  checklist from bounded lexical search through authority, evidence topology,
  semantic retrieval, manipulation resistance, scale, and external comparison.

## Mathematics breadth program

- [MATHEMATICS-CAPABILITY-TODO.md](MATHEMATICS-CAPABILITY-TODO.md) — long-horizon
  capability checklist across algebra, analysis, linear algebra, number theory,
  discrete mathematics, geometry, probability/statistics, optimization, special
  functions, and certified scientific mathematics.
- [MATHEMATICS-IMPLEMENTATION-STANDARD.md](MATHEMATICS-IMPLEMENTATION-STANDARD.md)
  — mandatory admission gate for exactness, assumptions, evidence, schemas,
  resource limits, testing, security, and documentation before a capability is
  marked complete.

## Product identity

- [OASIS.md](OASIS.md) — steadily advanced snapshot of current main and mirage
- [FCF-CAMPS.md](FCF-CAMPS.md) — current stay; newest software lives here
- [CENTL-MARSA.md](CENTL-MARSA.md) — Windows and macOS harbor of that stay
- [RELEASE-POLICY.md](RELEASE-POLICY.md)
- [releases/0.15.0.md](releases/0.15.0.md)
- [releases/0.14.0.md](releases/0.14.0.md)
- [releases/camp-001.md](releases/camp-001.md)
- [REPOSITORY-MAP.md](REPOSITORY-MAP.md)

## Research

Public research is hosted, searchable, and readable without JavaScript:

- [Research library](https://freecomputation.org/research.html)
- [Bryan Recursive Entanglement Calculus v1.0](../research/bryan-entanglement/BRYAN-RECURSIVE-ENTANGLEMENT-CALCULUS.md) · [hosted](https://freecomputation.org/bryan-recursive-entanglement-calculus.html)
- [Erdős–Straus program](https://freecomputation.org/research-erdos-straus.html)
- [Wellspring records](wellsprings/README.md)
- [WS-CAND-003](wellsprings/WS-CAND-003-erdos-straus-type-ab-shadow-structure.md)

Regenerate the hosted HTML after editing papers or manuals:

```sh
python3 scripts/publish-site-library.py
```

## Open only when you need it

Laboratory, preservation, and contribution manuals stay here on purpose:

- MIRAGE: [CENTL-MIRAGE.md](CENTL-MIRAGE.md)
- CARAVAN: [CARAVAN.md](CARAVAN.md)
- Camps: [FCF-CAMPS.md](FCF-CAMPS.md)
- Wellsprings: [FCF-WELLSPRING.md](FCF-WELLSPRING.md)
- Company and AI proposal: [FCF-PROPOSAL.md](FCF-PROPOSAL.md)
- Security and integrity: [../SECURITY.md](../SECURITY.md), [INTEGRITY.md](INTEGRITY.md)

The site index is [freecomputation.org/docs.html](https://freecomputation.org/docs.html).
