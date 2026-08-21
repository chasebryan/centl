<p>
  <img src="assets/branding/fcf-centl-banner.png" alt="Free Computation Foundation — CENTL">
</p>


# CENTL / CentL26

[![Version](https://img.shields.io/badge/version-26.4.0-blue.svg)](https://github.com/chasebryan/centl)
[![License](https://img.shields.io/badge/license-Apache--2.0-green.svg)](LICENSE)
[![Rust](https://img.shields.io/badge/rust-2021%20edition-orange.svg)](https://www.rust-lang.org/)
[![Offline First](https://img.shields.io/badge/offline-100%25%20local-success.svg)](https://freecomputation.org/)
[![Exact Mathematics](https://img.shields.io/badge/arithmetic-exact%20rational-purple.svg)](docs/NUMERICS.md)

**Exact-first mathematics, physics, chemistry, and offline STEM computing environment.**

*Good maths should be free.*  
*Never manufacture mathematical certainty.*

**CentL26** · [freecomputation.org](https://freecomputation.org/) · Apache-2.0

> **CentL26 is the flagship standalone scientific computing environment of CENTL.**  
> The "26" represents the 2026 flagship product line. CentL26 provides a calm, offline, deterministic scientific workbench that combines exact rational arithmetic, symbolic algebra, physics kernels, chemical stoichiometry, in-app hackability, 2D function plotting, and a comprehensive offline natural language problem solver.

---

## Key Highlights in CentL26.4

### 1. In-App Programmability & Hackability (`build`)
Users can extend CentL26 dynamically without learning complex programming languages:
- **Plain-English Synthesis**: `build a formula for kinetic energy KE(m, v) = 0.5 * m * v^2`
- **Declarative Function Syntax**: `build fn lorentz(v) = 1 / sqrt(1 - (v / 299792458)^2)`
- **Constants & Units**: `build const G_mars = 3.72`
- **Inspection & Testing**: `build list`, `build test lorentz(2.4e8)`, `build inspect lorentz`, `build export`, and `build clear`.
- Registered extensions are immediately callable across all subsequent notebook computations with exact execution receipts.

### 2. Dim Mode Theme
- Matte dark theme (`theme-dim`) designed for reduced eye strain during long lab sessions.
- Toggled via the toolbar Sun/Moon icon on the far right.
- Preserves 100% of exact typographic metrics, grid geometry, and layout alignment with `localStorage` persistence.

### 3. 2D ASCII & Unicode Function Plotter
- Native 2D coordinate grid plotting rendered directly in notebook cells or terminal CLI.
- **Syntax**: `plot <expression> from <x_min> to <x_max>`
- **Examples**: `plot sin(x) from -3.14 to 3.14`, `plot x^2 - 4 from -4 to 4`.
- Features automatic range autoscale, zero-axis indicator lines, and discrete marker points (`●`).

### 4. Comprehensive Native Offline SCi Problem Solver
Think out loud and type plain-English questions across all STEM disciplines without requiring an internet connection or cloud subscription:
- **Solution & Physical Chemistry**:
  - *pH & pOH Equilibria*: "What is the pH of a 0.05 M HCl solution?", "Calculate [H+] for pH = 3.5"
  - *Dilutions & Molarities*: "Dilute 50 mL of 2 M HCl to 200 mL, what is the final concentration?"
  - *Thermochemistry*: "Calculate Gibbs free energy when delta H is -92.4 kJ and delta S is -198 J/K at 298 K"
  - *Electrochemistry*: "Nernst equation for E0 = 1.10 V, n = 2, Q = 0.01"
  - *Reaction Balancing & Composition*: "Balance Fe + O2 -> Fe2O3", "Molar mass of Ca(OH)2"
- **Classical Mechanics & Kinematics**:
  - *Kinematics*: "A car accelerates from 0 to 25 m/s in 5 seconds, what is its acceleration?", "How far does an object travel accelerating at 3 m/s^2 for 10 s?"
  - *Free Fall*: "Free fall speed dropped from 20 meters"
  - *Energy & Power*: "Calculate kinetic energy of a 1500 kg car moving at 25 m/s", "Potential energy of 10 kg at height 15 m", "Work done by 250 N force over 12 meters"
- **Electromagnetism & Circuits**:
  - *Ohm's Law*: "What is the current with voltage 120 V and resistance 15 ohms?", "Resistance for 240 V and 30 A"
  - *Capacitance*: "Capacitance with charge 50 uC at 12 V"
- **Quantum, Photonics & Modern Physics**:
  - *Matter Waves*: "Calculate de broglie wavelength for mass 9.1e-31 kg and velocity 1e6 m/s"
  - *Photon Energy*: "Calculate energy of photon with wavelength 500 nm"
  - *Spectroscopy*: "What is the transition wavelength in hydrogen from n=3 to n=2?"
  - *Photoelectric Effect*: "Stopping potential for work function 2.3 eV and wavelength 400 nm"
  - *Special Relativity*: "Calculate Lorentz factor for velocity 2.4e8 m/s", "Time dilation at 0.8 c"
- **Thermodynamics & Radiation**:
  - *Carnot Engines*: "What is the Carnot efficiency with hot reservoir 600 K and cold reservoir 300 K?"
  - *Blackbody Radiation*: "Blackbody radiation at 5800 K", "Stefan-Boltzmann flux for 3000 K"
  - *Astrophysics*: "What is the escape velocity for mass 5.972e24 kg and radius 6.371e6 m?"
- **Geometry, Vectors & Linear Algebra**:
  - *Mensuration*: "Area of a circle with radius 7", "Volume of a sphere with radius 5", "Hypotenuse of right triangle with legs 3 and 4"
  - *Vector Calculus*: "Dot product of (1, 2, 3) and (4, 5, 6)", "Cross product of (1, 0, 0) and (0, 1, 0)"
  - *Matrices*: "Determinant of [[1, 2], [3, 4]]", "Inverse of [[4, 7], [2, 6]]"
- **Number Theory & Statistics**:
  - *Number Theory*: "totient of 36", "extended gcd of 240 and 46", "modular inverse of 3 mod 11", "Is 104729 prime?", "Prime factors of 360", "Solve Erdős-Straus for prime 2521"
  - *Statistics*: "Mean of 10, 20, 30, 40, 50", "Variance and standard deviation of 2, 4, 4, 4, 5, 5, 7, 9"
  - *Symbolic Calculus*: "Diff x^3 * cos(x)", "Integrate 3*x^2 + 2*x from 0 to 5", "Solve 3*x - 15 = 0"

### 5. Multi-Domain Auto-Detector
Eliminates the requirement to type subsystem prefixes:
```text
stoich measured 'C2H6 + O2 -> CO2 + H2O' C2H6 3 CO2
balance Fe + O2 -> Fe2O3
atoms Al2(SO4)3
convert 100 km/h to m/s
constant c
physics debroglie 9.1e-31 1e6
solve 2521
```

### 6. Optional Hybrid Gemini Verification
Set an API key via `:gemini-key <key>` or `GEMINI_API_KEY` to enable online multi-step problem decomposition (`:gemini <prompt>`). Every proposed step is executed and verified against CentL's exact rational kernel.

### 7. 50+ STEM Reference Examples Dataset
A structured, multi-domain reference dataset with exact rational guarantees is available:
- Downloadable via `/download/centl26-examples.csv` and `/download/centl26-examples.tsv`
- Viewable in-app via `:examples` or through the Data Explorer panel.

---

## Quick Start

### CLI Evaluation

```sh
# Exact rational mathematics
./target/release/centl26 "0.1 + 0.2"                    # → 3/10
./target/release/centl26 "totient(36)"                   # → 12
./target/release/centl26 "diff(x^3 * sin(x), x)"        # → 3*x^2*sin(x) + x^3*cos(x)
./target/release/centl26 "plot sin(x) from -3.14 to 3.14"

# Direct STEM problem solving
./target/release/centl26 "What is the pH of a 0.05 M HCl solution?"
./target/release/centl26 "Dilute 50 mL of 2 M HCl to 200 mL, what is the final concentration?"
./target/release/centl26 "A car accelerates from 0 to 25 m/s in 5 seconds, what is its acceleration?"
./target/release/centl26 "Hypotenuse of right triangle with legs 3 and 4"
./target/release/centl26 "Dot product of (1, 2, 3) and (4, 5, 6)"
```

### Standalone Desktop & Web Application

To launch the standalone workbench locally:

```sh
# Run standalone binary on default port 2626
cargo run --release --bin centl26

# Or build native macOS AppKit/WebKit bundle:
./scripts/build-centl26-macos
open build/centl26/macos/CentL26.app
```

---

## Architecture

| Component | Path | Description |
| :--- | :--- | :--- |
| **SCi Plain-English Solver** | [`src-web/engine/sci.rs`](src-web/engine/sci.rs) | Offline natural language parser, unit solvers, and hybrid Gemini bridge. |
| **In-App Programmability** | [`src-web/engine/extensions.rs`](src-web/engine/extensions.rs) | In-app user function builder, AST compiler, parameter validator, and macro engine. |
| **2D Function Plotter** | [`src-web/engine/plot.rs`](src-web/engine/plot.rs) | 2D discrete coordinate sampler and ASCII/Unicode grid renderer. |
| **Mathematics & Calculus** | [`src-web/engine/`](src-web/engine/) | Exact rational arithmetic, symbolic differentiation, integration, linear algebra, and statistics. |
| **Physics Kernel** | [`src-web/physics/`](src-web/physics/) | Mechanics, quantum physics, thermodynamics, radiation, relativity, and physical constants. |
| **Chemistry Engine** | [`src-web/server/`](src-web/server/) | Element catalog, reaction balancing via rational nullspace, and stoichiometric calculations. |
| **Design Contract** | [`design/centl26/`](design/centl26/) | Automated visual and layout regression assertions (57 invariants). |

---

## Research

The CENTL research program includes active exploration of **Erdős–Straus Diophantine Decomposition** ($4/p = 1/x + 1/y + 1/z$):

- **`cbis.kernel`**: Production letter hunt engine.
- **`cbx.kernel`**: Finite search grade analysis and inverse-cover x-ray instrument.
- **`cbap.kernel`**: High-performance letter targeting engine.

```sh
./target/release/centl26 "solve 2521"
```

---

## Documentation

- [CentL26 Architecture Guide](docs/CENTL26-ARCHITECTURE.md)
- [CentL26 Design Contract](docs/CENTL26-DESIGN-CONTRACT.md)
- [Numerical & Exactness Contract](docs/NUMERICS.md)
- [Mathematician Onboarding](docs/MATHEMATICIANS.md)
- [Physicist Onboarding](docs/PHYSICISTS.md)
- [Native macOS Packaging](desktop/centl26/macos/README.md)

---

## License

Software is licensed under **Apache-2.0**.  
Documentation is licensed under **CC BY 4.0** where identified.  
Branding is reserved: see [LICENSING.md](LICENSING.md).

Developed under the **Free Computation Foundation**.  
**Free for science.**

