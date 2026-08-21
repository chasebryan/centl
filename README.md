<p>
  <img src="assets/branding/fcf-centl-banner.png" alt="Free Computation Foundation — CENTL">
</p>


# CENTL / CentL26

[![Version](https://img.shields.io/badge/version-26.7.3-blue.svg)](https://github.com/chasebryan/centl)
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
> 
> **CentL26.7 is frozen as the rock standard foundation across all supported desktop and web environments.**

---

## Simple & Easy Setup Across All Ecosystems

CentL26 runs natively on Windows 11, macOS Arm64, and Debian/Fedora Linux distros with 100% feature parity. All modes run the exact same offline Rust core engine with zero cloud dependencies.

### 1. macOS (Apple Silicon Arm64 & Intel)

```sh
# 1-Command Universal Setup:
./install.sh

# Or build native AppKit/WebKit application:
./desktop/centl26/macos/build.sh
open build/centl26/macos/CentL26.app
```

### 2. Linux (Debian, Ubuntu, Fedora, RHEL, Arch)

```sh
# 1-Command Universal Setup (Installs binary, desktop launcher, and hicolor icons):
./install.sh

# Or build standalone package:
./desktop/centl26/linux/build.sh
./build/centl26/linux/CentL26
```

### 3. Windows 11 (PowerShell & Terminal)

```powershell
# 1-Command PowerShell Setup (Installs binary, Start Menu & Desktop shortcuts):
.\install.ps1

# Or 1-click batch launcher:
.\desktop\centl26\windows\CentL26.bat
```

### 4. Cross-Platform Local Web Browser

```sh
cargo run --release --bin centl26
# Open http://127.0.0.1:2626
```

---

## Key Highlights in CentL26.7

### 1. Multi-Platform Rock Standard Freeze
- Unified 1-command installer and packaging pipelines across **Windows 11**, **macOS Arm64**, and **Debian/Fedora Linux**.
- Full standalone native bundles, system application launchers (`.desktop`, `CentL26.app`, `.lnk`), and offline web servers.

### 2. Google-Grade App Icon
- Handcrafted vector icon featuring harmonious layered geometry, fluid mathematical continuous ribbons, vibrant scientific blues (`#1A73E8`, `#4285F4`, `#24C1E0`), and ambient elevation lighting.
- Multi-resolution assets bundled in `.icns`, `.ico`, `.svg`, and multi-res PNGs.

### 3. Verified Multi-Channel Update Mechanic
- **macOS Desktop App**: Direct WebKit message bridge integration (`CentL26Updater.swift`) with signature and atomic replace verification.
- **Git Clone Workspaces**: In-app **Update** button fetches remote commits, offers rebuild confirmation, pulls `origin/main`, rebuilds release binaries, and reloads seamlessly.
- **Release Binary Archives**: Automatically queries latest releases from GitHub.

### 4. Expanded Exact Combinatorics & Number Theory
- Exact computation for `catalan(n)`, `stirling2(n, k)`, `bell(n)`, `derangements(n)`, `is_prime(n)`, `next_prime(n)`, `prev_prime(n)`, `is_square(n)`, `collatz(n)`, `divisors(n)`, `sum_divisors(n)`, `is_perfect(n)`.
- Statistical routines: `mean`, `median`, `variance`, `stddev`, `zscore`, `normal_pdf`, `normal_cdf`, `binomial_pmf`, `poisson_pmf`.

### 5. Native Offline SCi Problem Solver
Think out loud and type plain-English questions across 32 STEM domains without internet:
- **Classical Mechanics**: Kinetic energy ($E_k = \frac{1}{2}mv^2$), potential energy ($E_p = mgh$), work ($W = Fd$), power ($P = W/t$), centripetal force ($F_c = mv^2/r$).
- **Electromagnetism & Circuits**: Ohm's law ($V = IR$), electrical power ($P = IV$), resistance, capacitance, electrostatic energy ($U = \frac{1}{2}CV^2$).
- **Thermodynamics & Chemistry**: Solution pH/pOH, dilutions ($M_1 V_1 = M_2 V_2$), ideal gas law ($PV = nRT$), Gibbs free energy, Nernst potentials, reaction balancing.
- **Waves & Quantum**: Wave dynamics ($v = f\lambda$), photon energy ($E = hf$), Rydberg spectral lines, photoelectric effect, matter waves.

### 6. Dynamic Multi-Notebook Workspaces & In-Place Renaming
- Create independent notebook tabs with the **`+`** button.
- Click directly on the notebook title in the breadcrumb (`Workspace / [Notebook 01]`) to rename active tabs.
- Export active work anytime as Markdown (`/download/notebook.md`) or structured JSON (`/download/notebook.json`).

### 7. 2D Coordinate Grid Function Plotter
- Full multi-line ASCII/Unicode coordinate grid visualization rendered directly in notebook cells, evidence panels, exports, and CLI (`plot sin(x) from -3.14 to 3.14`).

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

