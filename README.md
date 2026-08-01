# centl

> A calculator first, a language when needed.

CENTL is a calculator-first numerical language. Write mathematics directly,
interactively or in scripts, without programming ceremony. It is exact by
default, explicit about approximation, and never prints an unjustified digit.

You should not need to become a programmer to calculate or abandon mathematical
rigor to program.

The source tree is preparing `0.9.0` as an **UNRELEASED** version with exact
polynomial integration. The runtime version, Git tag, installers, and published
release remain `0.8.0` until a release is deliberately cut.

## Principles

- Typing an expression produces an answer immediately.
- A script is simply a saved sequence of calculator expressions and definitions.
- Ordinary mathematics requires no imports, boilerplate, entry points, or type
  declarations.
- Integers, decimals, and fractions are exact by default.
- Approximation and rounding are always visible and intentional.
- Advanced capabilities appear gradually without changing the basic language.
- Error messages explain the mathematics, not compiler internals.

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
./centl 'sum(k^2, k = 1, 100)'
./centl 'distance(0, 0, 3, 4)'
./centl 'approx(sin(pi / 6), 20)'
```

```text
3/10
3 * x^2 + 2
x^3 + x^2 + x
1/3
(x - 1) * (x + 1)
x in {2, 3}
338350
5
≈ [0.49999999999999999999, 0.50000000000000000001]
```

Run `./centl` for the calculator, `./centl --syntax` for every implemented form,
`./centl --file path` for a script, `./centl --serve` for persistent JSON Lines,
or `./centl --mcp` as a local AI tool. Mathematical output is colored when
written to a terminal; use
`--color=always`, `--no-color`, or `NO_COLOR` to control it.

Calculator sessions and scripts remember immutable definitions written as
`r = 3` or `f(x) = x^2 + 1`.

## Design

CENTL is in early development. See the [architecture](docs/DESIGN.md),
[complete syntax sheet](docs/SYNTAX.md),
[numerical contract](docs/NUMERICS.md),
[calculus syntax](docs/CALCULUS.md),
[algebra syntax](docs/ALGEBRA.md),
[mathematical functions](docs/MATHEMATICS.md),
[exact finite iteration](docs/ITERATION.md),
[installation and binary releases](docs/INSTALL.md),
[verification boundary](docs/VERIFICATION.md),
[machine protocol](docs/PROTOCOL.md), [MCP adapter](docs/MCP.md), and
[roadmap](docs/ROADMAP.md). Unreleased work is summarized in the
[changelog](CHANGELOG.md).

## License

`SPDX-License-Identifier: AGPL-3.0-or-later`
