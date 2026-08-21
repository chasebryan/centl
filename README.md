<p>
  <img src="assets/branding/fcf-centl-banner.png" alt="Free Computation Foundation — CENTL">
</p>


# CENTL / CentL26

[![Version](https://img.shields.io/badge/version-26.6.1-blue.svg)](https://github.com/chasebryan/centl)
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

## How to Run CentL26 (Web & Desktop Application)

CentL26 is distributed with full feature parity across both local web browser and native desktop application environments. Both run the exact same offline Rust core engine with zero cloud dependencies.

### Option A: Local Web Server (Cross-Platform)

```sh
# 1. Clone repository
git clone https://github.com/chasebryan/centl.git
cd centl

# 2. Build and launch
cargo run --release --bin centl26

# 3. Open in browser:
# http://127.0.0.1:2626
```

### Option B: Native macOS Desktop Application (`CentL26.app`)

```sh
# 1. Build host-native macOS bundle (AppKit + WebKit + Rust core)
./desktop/centl26/macos/build.sh

# 2. Open application
open build/centl26/macos/CentL26.app
```

---

## Key Highlights in CentL26.6.1

### 1. Expanded Exact Combinatorics & Number Theory
- Exact computation for Catalan numbers `catalan(n)`, Stirling numbers of the second kind `stirling2(n, k)`, Bell numbers `bell(n)`, and derangements `derangements(n)`.
- Deterministic number-theoretic tools: `is_prime(n)`, `next_prime(n)`, `prev_prime(n)`, `is_square(n)`, `collatz(n)`, `divisors(n)`, `sum_divisors(n)`, `is_perfect(n)`.
- Statistical routines: `mean`, `median`, `variance`, `stddev`, `zscore`, `normal_pdf`, `normal_cdf`, `binomial_pmf`, `poisson_pmf`.

### 2. Deep Native Offline SCi Problem Solver
Think out loud and type plain-English questions across 32 STEM domains without cloud connections:
- **Classical Mechanics**: Kinetic energy ($E_k = \frac{1}{2}mv^2$), gravitational potential energy ($E_p = mgh$), work ($W = Fd$), power ($P = W/t$), centripetal force ($F_c = mv^2/r$).
- **Electromagnetism & Circuits**: Ohm's law ($V = IR$), electrical power ($P = IV$), circuit resistance, capacitance, electrostatic energy ($U = \frac{1}{2}CV^2$).
- **Thermodynamics & Physical Chemistry**: Solution pH/pOH, dilutions ($M_1 V_1 = M_2 V_2$), ideal gas law ($PV = nRT$), Gibbs free energy ($\Delta G = \Delta H - T\Delta S$), Nernst cell potentials ($E = E^\circ - \frac{0.0592}{n}\log_{10} Q$), reaction balancing, and molar masses.
- **Wave Dynamics & Quantum**: Wave speed ($v = f\lambda$), photon energy ($E = hf$), hydrogen Rydberg lines, photoelectric stopping potential, de Broglie matter waves.
- **Geometry & Vectors**: Area, perimeter, volume, surface area, 3D dot products, cross products, determinants, and matrix inverses.

### 3. Rigorous Interval Numerics Active
- Native arbitrary-precision interval enclosures and transcendental approximations registered as available capability `org.fcf.centl.numerics.enclose`.

### 4. Dynamic Multi-Notebook Workspaces & In-Place Renaming
- Create independent notebook tabs with the **`+`** button.
- Click directly on the notebook title in the breadcrumb (`Workspace / [Notebook 01]`) to rename active tabs with automatic synchronization across downloads and exports.
- Export active work anytime as Markdown (`/download/notebook.md`) or structured JSON (`/download/notebook.json`).

### 5. 2D Coordinate Grid Function Plotter
- Full multi-line ASCII/Unicode coordinate grid visualization rendered directly in notebook cells, evidence panels, exports, and CLI.
- **Syntax**: `plot <expression> from <x_min> to <x_max>`
- **Examples**: `plot sin(x) from -3.14 to 3.14`, `plot x^3 - 3*x from -2.5 to 2.5`.

### 6. In-App Programmability & Extensions (`build`)
- Extend CentL26 dynamically in plain English or declarative syntax:
  - `build fn KE(m, v) = 1/2 * m * v^2`
  - `build const G_mars = 3.72`
  - `build list`, `build test KE(10, 5)`, `build export`

---

## Quick Start CLI Examples

```sh
# Exact rational mathematics
./target/release/centl26 "0.1 + 0.2"                    # → 3/10
./target/release/centl26 "catalan(6)"                   # → 132
./target/release/centl26 "totient(36)"                   # → 12
./target/release/centl26 "diff(x^3 * sin(x), x)"        # → 3*x^2*sin(x) + x^3*cos(x)
./target/release/centl26 "plot sin(x) from -3.14 to 3.14"

# Direct STEM problem solving
./target/release/centl26 "What is the pH of a 0.05 M HCl solution?"
./target/release/centl26 "Dilute 50 mL of 2 M HCl to 200 mL, what is the final concentration?"
./target/release/centl26 "Calculate kinetic energy of a 1500 kg car moving at 25 m/s"
./target/release/centl26 "Hypotenuse of right triangle with legs 3 and 4"
./target/release/centl26 "Dot product of (1, 2, 3) and (4, 5, 6)"
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

