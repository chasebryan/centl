# Physicist onboarding  

This page is deliberately narrow. It is for physicists who want to use CENTL and CENTL Physics for physical calculation and exact-first mechanics without learning the rest of the repository first.

If that is you, you can ignore CARAVAN, networking, repository infrastructure, release engineering, and contributor workflows unless you later choose to explore them.

## Take only what you need

A physicist does **not** need to install the whole CENTL product family.

| What you want | Install | What you do **not** get |
| --- | --- | --- |
| Typed exact-first physics only | `centl-physics` | separate `centl` and `centl-sci` commands |
| Physics + direct supporting mathematics | `centl-physics` + `centl` | `centl-sci` |
| Physics in ordinary language only | `centl-sci` | separate `centl` and `centl-physics` commands |
| Physics + mathematics + interpreter | all three components | nothing omitted |

**For direct physics work, `centl-physics` alone is the recommended minimum.** Add `centl` only when you want its direct mathematics CLI, and add SCi only when you want natural-language scientific interpretation.

On GNU/Linux, each choice is a **component-specific archive**. Asking for Physics does not first download the complete CENTL bundle. Required runtime libraries, license texts, provenance metadata, and the selected executable remain because they are required to run and redistribute that command correctly.

## Start here: choose your operating system   

CentL26.10 provides 100% feature-parity native physics and mechanics simulation across all major platforms:

| Platform | Recommended Path | Distribution Status |
| --- | --- | --- |
| **macOS (Apple Silicon & Intel)** | `./install.sh` or `open build/centl26/macos/CentL26.app` | Native AppKit/WebKit standalone application |
| **GNU/Linux (x86_64 / Arm64)** | `sh install.sh` or `centl26` | Standalone binary with desktop integration and icons |
| **Windows 11 (x64)** | `.\install.ps1` or `CentL26.bat` | Native standalone package with launcher & shortcut |
| **Cross-Platform Web** | `cargo run --release --bin centl26` | Local loopback web server (`http://127.0.0.1:2626`) |

###  GNU/Linux x86_64 — download only the physics command

Download the component installer and ask for CENTL Physics only:

```sh
curl -fsSLO https://raw.githubusercontent.com/chasebryan/centl/main/install-component
sh install-component --component physics
```

That installs `centl-physics` without installing separate `centl` or `centl-sci` commands.

Add direct mathematics only if you want it:

```sh
sh install-component --component centl
```

Add the scientific interpreter only if you want it:

```sh
sh install-component --component sci
```

Common physicist installation shapes are therefore:

```sh
# physics only
sh install-component --component physics

# physics + direct exact mathematics, no SCi
sh install-component --component physics
sh install-component --component centl

# physics + ordinary-language interpreter, no separate mathematics command
sh install-component --component physics
sh install-component --component sci

# all three, assembled explicitly
sh install-component --component physics
sh install-component --component centl
sh install-component --component sci
```

If you intentionally want the complete bundled distribution instead:

```sh
curl -fsSLO https://raw.githubusercontent.com/chasebryan/centl/oasis/install
sh install --channel oasis
```

###  macOS — build and install only what you want

macOS uses the `CENTL-Marsa` harbor. Homebrew is required; the Marsa bootstrap prepares GMP, MPFR, FLINT, `pkg-config`, and the OCaml/opam environment.

```sh
git clone --filter=blob:none --single-branch --branch CENTL-Marsa https://github.com/chasebryan/centl.git
cd centl
sh scripts/marsa-install --component physics
```

That installs only `centl-physics`. Add mathematics or SCi independently:

```sh
sh scripts/marsa-install --component centl
sh scripts/marsa-install --component sci
```

Or use the full port only when you deliberately want everything:

```sh
sh scripts/marsa-install --component all
```

By default commands are installed below `~/.local/bin`. If needed:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

Marsa currently builds from the shared source graph, so the source checkout contains shared build dependencies even when only one command is installed. The **installed product surface** is component-selective. macOS Marsa is the Camp harbor, not an Oasis-qualified release.

###  Windows — install only the selected command

Windows currently uses `CENTL-Marsa` from an **MSYS2 MinGW64 shell**, not ordinary Command Prompt. You need Git and `opam` available in that environment; the Marsa bootstrap prepares the MinGW numeric and build dependencies.

From the MSYS2 MinGW64 shell:

```sh
git clone --filter=blob:none --single-branch --branch CENTL-Marsa https://github.com/chasebryan/centl.git
cd centl
sh scripts/marsa-install --component physics
```

That installs only `centl-physics.exe`. Add the other surfaces independently when needed:

```sh
sh scripts/marsa-install --component centl
sh scripts/marsa-install --component sci
```

The installed executables live below the selected prefix, normally `~/.local/bin`. MSYS2 resolves the ordinary command names once that directory is on `PATH`:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

Windows support is presently a Marsa harbor/source-build path. The repository's Windows dependency/FLINT harbor is CI-checked, but the full Windows CENTL product job remains disabled until the OCaml/MinGW runtime and library toolchains are unified. Do not interpret a successful Windows source build as an Oasis declaration.

For the detailed port status and harbor rules, see [CENTL Marsa](CENTL-MARSA.md).

## Verify your physics installation

On **GNU/Linux, macOS, or Windows/MSYS2**, check an exact unit conversion:

```sh
centl-physics convert 100 cm m
```

Expected result:

```text
1
```

Check an exact defining physical constant:

```sh
centl-physics constant c
```

Then try the documented uniform-gravity particle path:

```sh
centl-physics gravity 2 0,0,10 1,0,0 0,0,-10 1/10 10
```

The result identifies the discrete symplectic-Euler integrator and keeps rational state exact.

If you chose to install CENTL-SCi, start it with:

```sh
centl-sci
```

and select physics-first interaction:

```text
:mode physics
```

You are now on the physics path. Nothing else in CENTL is required reading before you begin.

## Which command should a physicist use?

### `centl-physics` — the authoritative typed physics engine

Use `centl-physics` for physical quantities, dimensions, units, constants, and the engine's deterministic mechanics surfaces.

The simplest human CLI entry points include:

```sh
centl-physics convert 100 cm m
centl-physics constant c
centl-physics gravity 2 0,0,10 1,0,0 0,0,-10 1/10 10
```

More advanced physics operations are available through the `Centl_physics` library, the versioned JSON Lines server, and the read-only `centl_physics` MCP tool. The full physics document identifies which operations cross each interface boundary.

### `centl` — optional direct mathematics for physics work

Use `centl` for supporting exact mathematics when the task is mathematical rather than dimensioned physical state. It is a separate installable command, not a prerequisite for using the `centl-physics` CLI.

For example:

```sh
centl 'solve(x^2 - 5*x + 6 = 0, x)'
centl 'diff(x^3 + 2*x + 1, x)'
centl 'approx(sqrt(2), 30)'
```

CENTL Physics extends the same exact-first philosophy into typed physical quantities. It does not replace the mathematical engine with an unrelated evaluator.

### `centl-sci` — optional physics interpreter

Use `centl-sci` in `PHYS` mode when you want to describe a supported physical task in ordinary language while keeping CENTL's deterministic physics machinery authoritative.

Examples include:

```text
PHYS> convert 100 centimeters to meters
PHYS> what is the speed of light in vacuum
PHYS> simulate a particle with mass 2 kg, position (0,0,10) m, velocity (1,0,0) m/s, gravity (0,0,-10) m/s^2, dt 1/10 s, steps 10
```

CENTL-SCi is not a second physics engine. It interprets the request, validates the physical problem representation, and dispatches admitted operations to CENTL's deterministic physics machinery.

For more evidence about how a request was interpreted and executed, use:

```sh
centl-sci --details 'Convert 100 centimeters to meters.'
centl-sci --explain 'What is the speed of light in vacuum?'
```

## The physical contract you should understand

CENTL Physics is **dimension-safe and exact-first**.

The engine represents all seven SI base dimensions:

- length;
- mass;
- time;
- electric current;
- thermodynamic temperature;
- amount of substance;
- luminous intensity.

Derived dimensions are composed algebraically. Addition and subtraction require identical dimensions. Multiplication and division compose dimensions. A dimension mismatch is an error, not an implicit conversion or a guessed physical interpretation.

For example:

```sh
centl-physics convert 1 m s
```

fails rather than producing a meaningless number.

When inputs and unit scales are rational, admitted physics operations preserve exact rational arithmetic. CENTL does not introduce binary floating-point rounding merely because the calculation is physical.

## What physics is useful today?

### Dimensions and exact unit conversion

The unit catalog includes SI base and useful derived units such as `m`, `cm`, `mm`, `km`, `s`, `ms`, `min`, `h`, `kg`, `g`, `A`, `K`, `mol`, `cd`, `m/s`, `m/s^2`, `N`, `J`, `Pa`, `Hz`, `C`, `W`, `V`, `N/m`, `kg/s`, `J*s`, `J/K`, and `1/mol`.

Rational scale conversions remain exact.

### Dimensioned vectors

Three-dimensional vectors carry physical dimensions. The engine supports addition, subtraction, scalar scaling, dot products, cross products, and exact squared norms, with dimension checks where required.

### Particle mechanics

A particle carries:

- a stable identifier;
- positive mass;
- three-dimensional position;
- three-dimensional velocity.

The engine validates dimensions when particle state is constructed.

### Forces

Built-in force models include:

- constant force;
- uniform gravity;
- Hooke-law spring force about a fixed anchor;
- linear velocity drag.

Net force is accumulated exactly before acceleration is derived from `F / m`.

### Deterministic time evolution

The first time integrator is fixed-step symplectic Euler.

With rational mass, state, force parameters, and timestep, intermediate state remains rational. The output is the exact result of the **chosen discrete integrator**.

That distinction matters: CENTL does not present a discrete numerical trajectory as though it were the analytic continuous-time solution.

### Diagnostics

The library exposes exact momentum and kinetic-energy calculations, uniform-gravity potential energy, spring potential energy, and exact invariant comparison.

### Sphere contact and collision reasoning

CENTL Physics can classify exact sphere-pair geometry as:

- `separated`;
- `touching`;
- `overlapping`.

It also provides deliberately bounded exact contact and elastic-response primitives, including exact 1D elastic collision, exact 3D frictionless contact response, isolated touching-contact composition, and bounded continuous constant-velocity sphere-contact certification.

A `deferred` result is meaningful physics evidence. It means CENTL has identified a valid state outside the current operation's justified response domain, such as overlap or ambiguous simultaneous contacts. It is not permission to pretend a unique response exists.

Advanced contact operations are primarily library or machine-interface surfaces. Read the full physics contract before building a simulation around them.

### Exact physical constants

The current constant catalog deliberately contains exact SI defining or conventional values, including:

- speed of light in vacuum, `c`;
- Planck constant, `h`;
- elementary charge, `e`;
- Boltzmann constant, `k_B`;
- Avogadro constant, `N_A`;
- standard acceleration of gravity, `g0`.

Measured constants such as the Newtonian gravitational constant are intentionally not promoted into this exact catalog until CENTL has first-class uncertainty and provenance semantics appropriate for them.

## CENTL-SCi physics mode: supply the physics, not guesses

For the current uniform-gravity particle class, SCi requires the user to supply all required physical data:

- mass;
- initial position;
- initial velocity;
- gravity vector;
- timestep;
- number of steps.

CENTL-SCi does not invent missing initial conditions and does not silently choose a gravity vector for you.

That is a feature. A scientific interpreter should not smuggle unstated physical assumptions into a supposedly deterministic result.

## What should you *not* assume?

CENTL Physics is intentionally a bounded exact-rational mechanics foundation, not a universal physics simulator.

Do not assume that it currently provides:

- a general rigid-body solver;
- automatic collision handling inside every time step;
- penetration correction or arbitrary contact manifolds;
- friction, spin, torque, or general constraints and joints;
- general force-driven continuous collision detection;
- adaptive or higher-order ODE integration;
- rigorous truncation-error enclosure propagation for general trajectories;
- measured-constant uncertainty propagation;
- relativistic, quantum, continuum, fluid, or field solvers.

If an operation lies outside the admitted physical model, CENTL should leave the boundary visible rather than manufacture a result.

## Recommended physicist workflow

1. **Install only the surfaces you need.** For direct physics, start with `centl-physics` alone.
2. **Choose the correct platform path:** Oasis component archive on GNU/Linux x86_64, Marsa component build on macOS or Windows.
3. **Add `centl` only when you want the direct mathematics command.**
4. **Add `centl-sci` only when ordinary-language scientific interaction is useful.**
5. **Keep units and dimensions explicit.** Treat dimension mismatch as useful evidence, not an inconvenience to bypass.
6. **Distinguish discrete integration from analytic evolution.** The integrator name is part of the result's meaning.
7. **Treat `deferred`, unsupported, and unresolved outcomes as information.** They mark the current assurance boundary.
8. **Use `--details` or `--explain`** when you need to inspect SCi's interpretation and execution path.

## Read next, and only when you need it

- [CENTL Physics](PHYSICS.md) — complete implemented physics capabilities, numerical contract, machine interfaces, and current boundary.
- [Linear sphere contact contract](PHYSICS_LINEAR_CONTACT.md) — exact bounded continuous contact and event-step boundaries.
- [CENTL-SCi](SCI.md) — optional physics-first natural-language interaction and evidence surfaces.
- [Numerical contract](NUMERICS.md) — the exactness and approximation philosophy inherited from CENTL.
- [Installation](INSTALL.md) — GNU/Linux Oasis/Mirage channels, offline installation, and source builds.
- [CENTL Marsa](CENTL-MARSA.md) — macOS and Windows Camp harbor, dependencies, and assurance boundary.

That is the complete starting map for a physicist. The rest of the repository can stay outside your working set until your physical work actually requires it.
