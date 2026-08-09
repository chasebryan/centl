![Free Computation Foundation — FCF and camel banner](assets/branding/fcf-centl-banner.png)

# centl

> change the world.

CENTL is a deterministic, exact-first mathematical evaluation kernel with a
calculator, a small expression language, and script, JSON, and MCP interfaces.
It keeps exact values exact, produces rigorous enclosures when approximation is
requested, and leaves unsupported or indeterminate work visible instead of
manufacturing certainty.

CENTL 0.12.0-rc.1 is the release candidate for the
[accepted product direction](docs/DESIGN_PATH.md): a mathematical contract
checker for code and automated workflows—a type checker for mathematical
claims. It adds structured claim verification (`centl verify`, `centl check`,
MCP `centl_verify`), F*-backed universal equality for the admitted univariate
rational-polynomial fragment, exact counterexamples, and bounded replayable
receipts tied to the binary's extracted-core identity.

The 0.11.0 foundation reports whether every requested transformation completed, proved
an input unchanged, remained residual, or was unsupported. It separates
read-only computation from explicit session mutation, publishes closed MCP
schemas and supported domains, exposes definition dependencies and focused
syntax help, and returns structured retry and source-range error metadata.

## Principles

- Exactness describes a value; it does not imply that every requested operation
  completed.
- Integers, decimals, and fractions are exact values rather than binary
  floating-point approximations.
- Explicit approximation returns a rigorous enclosure, not an unqualified
  floating-point guess.
- Unsupported transformations remain visible or return a structured failure;
  they do not masquerade as completed work.
- Conditions and domain obligations are retained instead of silently discarded.
- The calculator, scripts, JSON, and MCP expose the same typed semantics.
- Automated callers can use a read-only compute operation that rejects all
  session mutation; definitions use a separate explicit operation.
- Every unqualified printed digit is justified by an exact value or the full
  returned enclosure.

## Try it

Install a native Linux or macOS release without a compiler toolchain:

```sh
curl -fsSLO https://raw.githubusercontent.com/chasebryan/centl/main/install
less install
sh install
centl 'solve(x^2 - 5*x + 6 = 0, x)'
```

On Windows PowerShell:

```powershell
Invoke-WebRequest https://raw.githubusercontent.com/chasebryan/centl/main/install.ps1 -OutFile install.ps1
Get-Content .\install.ps1
Unblock-File .\install.ps1
.\install.ps1
centl 'solve(x^2 - 5*x + 6 = 0, x)'
```

From a source checkout with the development toolchain installed:

```sh
make test
./centl '0.1 + 0.2'
./centl 'diff(x^3 + 2*x + 1, x)'
./centl 'integrate(3*x^2 + 2*x + 1, x)'
./centl 'integrate(x^2, x = 0, 1)'
./centl 'factor(x^2 - 1)'
./centl 'solve(x^2 - 5*x + 6 = 0, x)'
./centl 'solve(x^2 = 2, x)'
./centl 'sum(k^2, k = 1, 100)'
./centl 'sequence(k^2, k = 1, 5)'
./centl 'recurrence(1, a = a*n, n = 0, 5)'
./centl 'distance(0, 0, 3, 4)'
./centl 'approx(sin(pi / 6), 20)'
./centl verify --left '0.1 + 0.2' --relation equal --right '3/10'
./centl verify --left 'sqrt(2)' --relation less_than --right '2'
./centl verify --left '(x+1)^2' --relation equal --right 'x^2+2*x+1' \
  --variable x:rational --receipt identity.json
./centl check examples/contracts/math-contracts.centl --receipt contracts.json
```

```text
3/10
3 * x^2 + 2
x^3 + x^2 + x
1/3
(x - 1) * (x + 1)
x in {2, 3}
x in {-sqrt(2), sqrt(2)}
338350
[1, 4, 9, 16, 25]
[1, 1, 2, 6, 24, 120]
5
≈ [0.49999999999999999999, 0.50000000000000000001]
```

Run `./centl` for the calculator, `./centl --syntax` for every implemented form,
`./centl --file path` for a script, `./centl --serve` for persistent JSON Lines,
or `./centl --mcp` as a local AI tool. Mathematical output is colored when
written to a terminal; use
`--color=always`, `--no-color`, or `NO_COLOR` to control it.

## Physics engine

The development path now includes an experimental exact-first particle physics
engine. It is implemented as the `Centl_physics` library module and the
`centl-physics` executable. Rational inputs remain arbitrary-precision
rationals through unit conversion, force evaluation, collision formulas, and
fixed-step state evolution; incompatible physical dimensions fail explicitly.

After a source build:

```sh
dune exec centl-physics -- convert 100 cm m
dune exec centl-physics -- constant c
dune exec centl-physics -- gravity 2 0,0,10 1,0,0 0,0,-10 1/10 10
```

Native packages built from this development path install `centl-physics`
alongside `centl`. The engine implements seven-base SI dimensional analysis,
exact unit conversion, dimension-safe 3D vectors, particle state, constant
force, uniform gravity, Hooke springs, linear drag, symplectic-Euler time
evolution, energy and momentum diagnostics, exact ideal 1D elastic collision
response, and an exact frictionless 3D response primitive for a caller-supplied
contact with distinct particle centers. The 3D primitive deliberately does not
perform collision detection, infer radii, correct penetration, or model spin,
torque, or friction. It does not yet claim a general rigid-body contact solver,
adaptive integration, continuum/fluid solvers, or rigorous truncation-error
enclosures. See [docs/PHYSICS.md](docs/PHYSICS.md) for the exact contract and
current boundary.

Calculator sessions and scripts remember immutable definitions written as
`r = 3` or `f(x) = x^2 + 1`.

In an interactive terminal, incomplete statements continue at a `....>`
prompt. Tab completes built-in and session-defined names, Up/Down browse the
bounded history saved across calculator processes, and `:history` or
`:clear-history` inspect or durably clear it. Standard-input and `--file`
scripts use the same multiline statement rules. Human syntax errors identify
the source line and column and show a caret at the failing byte.

History is stored as private, versioned state at
`$XDG_STATE_HOME/centl/history.json` on Unix, falling back to
`$HOME/.local/state/centl/history.json`, and at
`%LOCALAPPDATA%\centl\history.json` on Windows. It is capped at 1,000 entries
and 1 MiB, and concurrent calculator processes merge additions under a lock
before an atomic replacement. Use
`--no-history`, set `CENTL_NO_HISTORY`, or set `CENTL_HISTORY=off` to retain
Up/Down history only for the current process. The
[syntax guide](docs/SYNTAX.md#interactive-history) documents paths, privacy,
concurrency, limits, and the disk-format policy.

## Developer quickstart

New to OCaml, F*, or rigorous numerics? Follow the complete
[manual contributor onboarding](docs/ONBOARDING.md). See
[CONTRIBUTING.md](CONTRIBUTING.md) for system prerequisites, the pinned F* setup,
and the reproducible opam bootstrap. Once those are installed:

```sh
scripts/bootstrap-opam
eval "$(opam env --switch=centl)"
make test
```

## Design

CENTL is in early development. See the [architecture](docs/DESIGN.md),
[near-term product design path](docs/DESIGN_PATH.md),
[complete syntax sheet](docs/SYNTAX.md),
[numerical contract](docs/NUMERICS.md),
[calculus syntax](docs/CALCULUS.md),
[algebra syntax](docs/ALGEBRA.md),
[mathematical functions](docs/MATHEMATICS.md),
[exact finite iteration and sequences](docs/ITERATION.md),
[physics engine contract](docs/PHYSICS.md),
[installation and binary releases](docs/INSTALL.md),
[verification boundary](docs/VERIFICATION.md),
[performance contract](docs/PERFORMANCE.md),
[machine protocol](docs/PROTOCOL.md), [MCP adapter](docs/MCP.md), and
[roadmap](docs/ROADMAP.md). Release history is summarized in the
[changelog](CHANGELOG.md).

## License

`SPDX-License-Identifier: AGPL-3.0-or-later`
