<p>
  <img src="assets/branding/fcf-centl-banner.png" alt="Free Computation Foundation — CENTL">
</p>


# CENTL / CentL26

[![Version](https://img.shields.io/badge/version-26.9.0-blue.svg)](https://github.com/chasebryan/centl)
[![License](https://img.shields.io/badge/license-Apache--2.0-green.svg)](LICENSE)
[![Rust](https://img.shields.io/badge/rust-2021%20edition-orange.svg)](https://www.rust-lang.org/)
[![Offline First](https://img.shields.io/badge/offline-100%25%20local-success.svg)](https://freecomputation.org/)
[![Exact Mathematics](https://img.shields.io/badge/arithmetic-exact%20rational-purple.svg)](docs/NUMERICS.md)

**Exact-first mathematics, physics, chemistry, and offline STEM computing environment.**

*Good maths should be free.*  
*Never manufacture mathematical certainty.*

**CentL26** · [freecomputation.org](https://freecomputation.org/) · Apache-2.0

> **CentL26 is the flagship standalone scientific computing environment of CENTL.**  
> The "26" represents the 2026 flagship product line. CentL26 provides a calm, offline, deterministic scientific workbench that combines exact rational arithmetic, canonical polynomial algebra, physics kernels, chemical stoichiometry, in-app hackability, 2D function plotting, interactive STEM animated visualizer & theorem studio, academic search engine, and a comprehensive offline natural language problem solver.
> 
> **CentL26.9.0 is the official universal release across all supported desktop and web environments.**

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

## Key Highlights in CentL26.9

### 1. Robust Algebraic Engine & Canonical Polynomial Solver
- **High-Precision Rational Root Theorem Solver**: Exact root extraction for linear, quadratic, cubic, quartic, and higher-degree polynomials with synthetic division (`synthetic_divide_root`) and exact radical isolation.
- **Direct Algebraic Equation Auto-Solving**: Free variable analysis automatically differentiates variable assignment (`x = 5`) from equations (`2x + 3 = 7` $\rightarrow x = 2$, `x^2 - 5x + 6 = 0` $\rightarrow x = 2, x = 3$).
- **Constant Mathematical Equality Verification**: Immediate truth-value validation (`2 + 3 = 5` $\rightarrow true$, `2 + 3 = 6` $\rightarrow false$, `2^10 = 1024` $\rightarrow true$).
- **Polynomial Expansion & Factorization**:
  - `factor(x^2 - 9)` $\rightarrow (x + 3)(x - 3)$
  - `factor(x^2 - 5x + 6)` $\rightarrow (x - 2)(x - 3)$
  - `factor(x^3 - 6x^2 + 11x - 6)` $\rightarrow (x - 1)(x - 2)(x - 3)$
  - `expand((x - 1)*(x + 1))` $\rightarrow x^2 - 1$
- **Smart Implicit Multiplication**: Natural parsing of mathematical notation (`2x`, `5x^2`, `3(x+1)`, `(x-1)(x+1)`, `4pi`, `2sin(x)`) while preserving English natural language sentences.

### 2. Calculus, Discrete Mathematics & Series
- **Higher-Order Differentiation**: `diff(f, x, n)` (e.g. `diff(x^4, x, 3)` $\rightarrow 24x$).
- **Definite & Indefinite Integration**: `integrate(3x^2 + 2x, x, 0, 3)` $\rightarrow 36$.
- **Symbolic Limits & L'Hôpital's Rule**: `limit((x^2 - 1)/(x - 1), x, 1)` $\rightarrow 2$.
- **Taylor Series Expansion**: `taylor(exp(x), x, 0, 3)` $\rightarrow 1 + x + \frac{1}{2}x^2 + \frac{1}{6}x^3$.
- **Discrete Summations & Products**: `sum(k^2, k, 1, 5)` $\rightarrow 55$, `product(k, k, 1, 5)` $\rightarrow 120$.

### 3. Interactive STEM Animated Visualizer & Theorem Studio
- Engage directly with dynamic mathematical theorems, Fourier harmonics, ODE wave animations, Lorenz chaotic attractors, particle physics simulations, and Bravais crystal lattice geometry.

### 4. Calm Welcome Experience & Preferences
- Clean Welcome surface with customizable boot behavior (`"Resume Previous Session"` or `"Start Fresh Computation"`).
- Keyboard-safe tab closing accelerators (`⌥ W` / `⌘ ⇧ W`) and native Settings cogwheel interface.

### 5. Exhaustive 100-Test Automated Non-Regression Suite
- Dedicated offline test verification across arithmetic, linear/quadratic/polynomial algebra, calculus, stoichiometry, and modern physics.

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

