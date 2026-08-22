// FCF Documentation & Research Preprint Registry
// Free Computation Foundation - Apache-2.0

#[derive(Debug, Clone)]
pub struct FcfDoc {
    pub id: &'static str,
    pub title: &'static str,
    pub category: &'static str, // "manual" | "research" | "spec"
    pub summary: &'static str,
    pub tags: &'static [&'static str],
    pub content: &'static str,
}

pub static FCF_DOCUMENTS: &[FcfDoc] = &[
    FcfDoc {
        id: "centl26-operator-manual",
        title: "CentL26 Scientific Work Environment — Operator Manual",
        category: "manual",
        summary: "Comprehensive guide to exact arithmetic, symbolic algebra, multi-statement notebooks, and keyboard shortcuts in CentL26.",
        tags: &["manual", "operator", "guide", "arithmetic", "hotkeys", "notebooks", "algebra"],
        content: r#"# CentL26 Scientific Work Environment · Operator Manual
**Free Computation Foundation · Canonical Reference & User Guide**

## 1. Philosophical Grounding & Architecture
CentL26 is built on a foundational axiom: **Good maths should be free. Never manufacture mathematical certainty.**

Unlike conventional computer algebra systems or floating-point calculators that silently truncate digits and accumulate round-off errors:
- **Exact-First Arithmetic**: Every rational computation in CentL26 is performed over the exact field $\mathbb{Q}$ using arbitrary-precision rational arithmetic.
- **Closed-Form Symbolics**: Algebraic identities, derivatives, integrals, and polynomials are manipulated symbolically in closed form.
- **Certified Interval Enclosures**: When transcendental constants ($\pi, e$) or irrational roots ($\sqrt{2}$) are evaluated, CentL26 computes rigorous upper and lower bounds $[x_{\min}, x_{\max}]$ guaranteed to enclose the true real value $x^*$.
- **Local & Offline Privacy**: All calculations, notebooks, and extensions run 100% locally on your machine with zero cloud dependencies.

---

## 2. Interactive Notebook Workspace
CentL26 organizes your scientific work into an interactive multi-cell notebook canvas.

### 2.1 Anatomy of a Cell
Each notebook cell consists of:
- **Input Gutter (`In [n]:`)**: Displays the sequential execution count of the calculation.
- **Header Bar & Domain Badge**: Indicates the active computational domain (`Exact ℚ`, `Symbolic ∂`, `Physics Δ`, `Chemistry Σ`, `Erdős p`, `Build b`, `SCi NL`, `Markdown`).
- **Cell Actions**:
  - `▶ Run`: Re-evaluates the cell immediately.
  - `+ Above`: Inserts a new computation cell above the active cell.
  - `+ Below`: Inserts a new computation cell below the active cell.
  - `▲` / `▼`: Reorders cells up or down.
  - `✏ Edit`: Loads the cell's expression into the bottom composer for modification.
  - `📋 Copy`: Copies the expression to your clipboard.
  - `✕ Delete`: Removes the cell from the notebook history.
- **Source Expression**: The exact mathematical syntax or command executed.
- **Output Section (`Out [n]:`)**: Displays the exact result, execution timing in microseconds ($\mu\text{s}$), and certified enclosure bounds where applicable.

### 2.2 Cell Types
1. **Code Cells (`▶`)**: Execute calculations, solvers, unit conversions, and multi-statement programs.
2. **Markdown Cells (`MD`)**: Documentation and mathematical notes. Prefix any command with `#` or `:md` to create a note.

### 2.3 Multi-Notebook Tabs
Work with multiple independent calculations simultaneously:
- Click the `+` tab button in the document strip or run `:new-notebook` to open a new tab.
- Double-click the notebook title or use `:rename-notebook <name>` to name your active document.
- Switch tabs with `⌘ 1`, `⌘ 2`, or by clicking the tab.
- Close a tab using `Alt+W` or `:close-notebook <idx>`.

---

## 3. Workspace Toolbar & Controls
The top toolbar provides one-click access to core environment tools:
- **Welcome**: Switch to the launchpad and problem surface.
- **Code**: Insert and focus a new computation cell.
- **Markdown**: Insert a formatted markdown note cell.
- **Run All**: Sequentially re-evaluate every cell in the notebook in order.
- **Restart**: Clear execution history and reset variable scope while preserving notebook tabs.
- **Visualizer**: Launch the interactive 60 FPS STEM Animated Visualizer & Theorem Studio.
- **Tools**: Open the quick Command Palette and tool search (`⌘ P`).
- **Save**: Persist current project state to disk (`⌘ S`).
- **Settings**: Toggle startup mode between *Resume previous session* and *Start fresh*.
- **Help**: Open the in-app quick reference guide.
- **Theme**: Switch between clean light and dimmed dark themes.

---

## 4. Keyboard Shortcuts & Navigation

### 4.1 Execution Shortcuts
- `Shift + Enter`: Execute the active cell/command and advance focus.
- `Ctrl + Enter` or `⌘ Enter`: Execute the active cell in place.
- `Alt + Enter`: Execute the active cell and immediately insert a blank cell below.

### 4.2 System Navigation
- `⌘ K` or `/` (outside inputs): Focus the STEM Academic Search & Chrome Omnibar.
- `⌘ P` or `Ctrl + P`: Open Command Palette (Commands & Quick Open).
- `⌘ B` or `Ctrl + B`: Toggle the left Explorer side pane.
- `⌘ J` or `Ctrl + J`: Toggle the bottom Trace Console.
- `⌘ S` or `Ctrl + S`: Save active project locally.
- `Alt + W` or `⌘ Shift W`: Close active notebook tab.
- `Escape`: Close active modal, dialog, or omnibar menu.

### 4.3 Command Mode (when outside text inputs)
Press `Escape` to enter command mode:
- `A`: Insert new code cell above.
- `B`: Insert new code cell below.
- `M`: Switch cell / insert markdown note.
- `Y`: Switch cell / insert code cell.
- `K` or `ArrowUp`: Navigate focus to previous cell.
- `J` or `ArrowDown`: Navigate focus to next cell.
- `Enter`: Enter edit mode in focused cell.

---

## 5. Exact Mathematical Engine & CAS Syntax

### 5.1 Rational Arithmetic & Big Integers
- Arbitrary precision fractions: `1/3 + 5/7` → `22/21`
- Exponentiation & large powers: `2^64` → `18446744073709551616`
- Factorials & Combinatorics: `50!` or `factorial(50)`
- Divisibility & Number Theory: `gcd(84, 360)` → `12`, `lcm(14, 15)` → `210`

### 5.2 Variables & Multi-Statement Cells
Assign variables and chain calculations sequentially using semicolons:
```centl
x = 14;
y = 28;
radius = sqrt(x^2 + y^2);
area = pi * radius^2;
area
```

### 5.3 Symbolic Calculus
- **Differentiation**: `diff(expression, variable)`
  - `diff(x^3 * sin(x), x)` → `3*x^2*sin(x) + x^3*cos(x)`
  - `diff(exp(-x^2), x)` → `-2*x*exp(-x^2)`
- **Symbolic Integration**: `integrate(expression, variable, [lower, upper])`
  - Indefinite: `integrate(3*x^2 + 2*x, x)` → `x^3 + x^2`
  - Definite: `integrate(3*x^2 + 2*x, x, 0, 5)` → `150`
- **Taylor Series**: `series(expression, variable, center, order)`
  - `series(sin(x), x, 0, 6)` → `x - x^3/6 + x^5/120 + O(x^7)`
- **Limits**: `limit(expression, variable, point)`
  - `limit(sin(x)/x, x, 0)` → `1`

### 5.4 Algebraic Equation Solving & Polynomials
- **Equation Solving**: `solve(equation, variable)`
  - `solve(x^2 - 5*x + 6 = 0, x)` → `x = 2, x = 3`
  - `solve(2*x + 5 = 17, x)` → `x = 6`
- **Polynomial Factorization**: `factor(x^4 - 1)` → `(x - 1)*(x + 1)*(x^2 + 1)`
- **Polynomial Expansion**: `expand((x + 2)^4)`
- **Simplification**: `simplify((x^2 - 1)/(x - 1))` → `x + 1`

### 5.5 Certified Transcendental Enclosures
Evaluate irrational and transcendental numbers to arbitrary precision with verified bounds:
- `approx(pi, 50)` → 50 verified decimal digits of $\pi$ with guaranteed error interval.
- `approx(e, 50)` → 50 verified digits of Euler's constant $e$.
- `approx(sqrt(2), 50)` → 50 verified digits of $\sqrt{2}$.

---

## 6. Physics & SI Mechanics Engine
CentL26 includes a typed physical computation engine with SI unit validation:

### 6.1 Unit Conversions
Convert between imperial, metric, atomic, and astronomical units:
- `physics convert 100 km/h m/s` → `27.77777778 m/s`
- `physics convert 1 atm Pa` → `101325 Pa`
- `physics convert 100 eV J` → `1.602176634e-17 J`
- `physics convert 1 AU km` → `149597870.7 km`

### 6.2 Classical Mechanics & Kinematics
- **Kinematic Equations**: `physics kinematics v0=25 a=-9.8 t=2.5` (computes displacement and final velocity).
- **Elastic Collisions**: `physics collision elastic 2.0 5.0 1.0 -3.0` (computes post-collision velocities preserving kinetic energy $\frac{1}{2}mv^2$ and momentum $mv$).
- **Gravitational Force**: $F = G \frac{m_1 m_2}{r^2}$.

### 6.3 Relativistic Dynamics
- **Lorentz Factor**: $\gamma = \frac{1}{\sqrt{1 - v^2/c^2}}$
- **Relativistic Invariant Energy-Momentum**:
  $$E^2 = (pc)^2 + (m_0 c^2)^2$$

---

## 7. Chemistry & Stoichiometry Engine

### 7.1 Elemental Atom Counting
Decomposes complex, nested chemical formulas:
- `chem atoms Ca(OH)2` → `Ca: 1, O: 2, H: 2` (Total: 5 atoms)
- `chem atoms (NH4)2SO4` → `N: 2, H: 8, S: 1, O: 4` (Total: 15 atoms)
- `chem atoms Fe3[Fe(CN)6]2` → `Fe: 5, C: 12, N: 12`

### 7.2 Molar Mass Computation
Calculates exact molecular weight:
- `chem mass H2SO4` → `98.078 g/mol`
- `chem mass C6H12O6` → `180.156 g/mol`

### 7.3 Chemical Reaction Balancing
Balances reactions using exact matrix nullspace linear algebra:
- `chem balance H2 + O2 = H2O` → `2 H2 + O2 = 2 H2O`
- `chem balance C3H8 + O2 = CO2 + H2O` → `C3H8 + 5 O2 = 3 CO2 + 4 H2O`
- `chem balance KMnO4 + HCl = KCl + MnCl2 + H2O + Cl2` → `2 KMnO4 + 16 HCl = 2 KCl + 2 MnCl2 + 8 H2O + 5 Cl2`

### 7.4 Buffers & Thermochemistry
- **Henderson-Hasselbalch Equation**: $\text{pH} = \text{p}K_a + \log_{10}\left(\frac{[\text{A}^-]}{[\text{HA}]}\right)$
- **Gibbs Free Energy**: $\Delta G = \Delta H - T \Delta S$

---

## 8. Research Kernels & Number Theory
CentL26 includes specialized high-performance research solvers for open mathematical problems:

### 8.1 Erdős–Straus Conjecture Solver
Decomposes rational $\frac{4}{p}$ into Egyptian unit fractions:
- `es solve 1009` → Finds witness triple $(x, y, z)$ such that $\frac{4}{1009} = \frac{1}{x} + \frac{1}{y} + \frac{1}{z}$.
- `es hunt 1000000` → High-throughput scanner evaluating prime residue classes at $>10^7$ primes/sec.

### 8.2 Collatz Trajectory Dynamics
- `collatz 27` → Computes stopping time, maximum trajectory peak, and 2-adic valuation vector.

---

## 9. Interactive STEM Animated Visualizer & Theorem Studio
Launch the Visualizer via the toolbar **Visualizer** button or by running `:visualize`, `:viz`, or `:theorems`.

### Built-in Interactive Models:
1. **Erdős–Straus Modular Resonance Orbit**: Dynamic polar projection of unit fraction decomposition paths.
2. **Collatz Stopping Time Tree & 2-Adic Decay**: Branching tree visualization of Syracuse stopping times.
3. **Prime Harmonic Distribution & Zeta Spirals**: Spatial distribution of primes along logarithmic spirals.
4. **Relativistic Spacetime & Light Cone**: Minkowski coordinate transformations and time dilation envelopes.
5. **Double Pendulum Chaotic Phase Space**: Non-linear dynamical phase portrait and sensitivity to initial conditions.
6. **Molecular Reaction Graph**: Stoichiometric mass-conservation flow networks.
7. **Quantum Wave Packet Dispersion**: Tunneling probability across rectangular potential barriers.
8. **Fourier Harmonic Synthesis**: Real-time reconstruction of square and sawtooth waves from trigonometric series.

### Canvas Controls:
- **Play/Pause**: Toggle 60 FPS animation with `Space` or the play button.
- **Step**: Advance animation by single frames with `→`.
- **Reset**: Return simulation to $t = 0$ with `R`.
- **Speed**: Adjust simulation rate from $0.25\times$ to $4.0\times$.
- **Pan & Zoom**: Click and drag canvas to pan; scroll wheel to zoom.

---

## 10. In-App Programmability & Extensions (`build`)
Define reusable functions and constants that persist across your workspace:
```centl
build fn lorentz(v) = 1 / sqrt(1 - (v / 299792458)^2)
build const planck_h = 6.62607015e-34
build fn photon_energy(freq) = planck_h * freq
```
View and manage all authored extensions in the **Extensions (`B`)** Explorer pane.

---

## 11. AI Co-Pilot (Gemini Command Integration)
CentL26 integrates Google Gemini as an optional natural-language assistant directly within the notebook workspace:
- **Ask Gemini**: `:gemini <query>` (e.g., `:gemini explain the derivation of Stirling's approximation`)
- **Configure API Key**: `:gemini-key <YOUR_API_KEY>`
- **Switch Model**: `:gemini-model <model>` (e.g. `gemini-2.5-pro`, `gemini-2.5-flash`, `gemini-2.5-flash-lite`)
- **Check Status**: `:gemini-status`

*Note*: CentL26 adheres to exact-first validation. Gemini serves strictly as a conceptual co-pilot; all mathematical computations remain verified by CentL26's native deterministic kernels.

---

## 12. Project Storage, Export & Interoperability
- **Auto-Save & Project Files**: Work is automatically preserved locally in your session database. Use `⌘ S` or `:save` to create named snapshots.
- **Jupyter Notebook Export (`.ipynb`)**: Download complete notebooks in official Jupyter format for use in JupyterLab, Google Colab, and VS Code.
- **Markdown Export (`.md`)**: Export clean Markdown documents with formatted LaTeX equations.
- **Full JSON Archive (`.json`)**: Export complete session state, receipts, variables, and history.

---

## 13. Master System Commands Reference Table

| Command | Action | Shortcut |
|:---|:---|:---|
| `:clear` | Clears current notebook history & receipts | `Clear` Button |
| `:new-notebook` | Opens a new independent computation notebook tab | `+` Tab |
| `:switch-notebook <n>` | Switches active tab to notebook index `n` | `⌘ 1..9` |
| `:rename-notebook <name>` | Renames the active notebook tab | Double-Click Title |
| `:close-notebook <n>` | Closes notebook tab at index `n` | `Alt + W` |
| `:delete-cell <n>` | Deletes cell `n` from the active notebook | `✕ Delete` |
| `:move-cell <n> <dir>` | Reorders cell `n` up (`-1`) or down (`1`) | `▲` / `▼` |
| `:save` | Persists project state and notebook sessions to disk | `⌘ S` |
| `:visualize` / `:viz` | Opens the STEM Animated Visualizer & Theorem Studio | Toolbar Button |
| `:gemini <prompt>` | Prompts Gemini AI Co-Pilot for conceptual assistance | In-Workspace |
| `:gemini-key <key>` | Configures Gemini API credentials for current session | In-Workspace |
| `:gemini-model <mod>` | Sets active Gemini model (`gemini-2.5-pro`, etc.) | In-Workspace |
| `:gemini-status` | Displays AI co-pilot connectivity and credential status | In-Workspace |
| `:help` | Displays keyboard shortcuts and system reference | Toolbar Button |
"#,
    },
    FcfDoc {
        id: "fcf-chemistry-stoichiometry-guide",
        title: "FCF Chemistry & Stoichiometry Manual",
        category: "manual",
        summary: "Reaction balancing, atom counting, molar mass computation, gas laws, and buffer equilibrium formulations.",
        tags: &["chemistry", "stoichiometry", "reactions", "molecules", "gas laws", "molar mass", "equilibrium"],
        content: r#"# FCF Chemistry & Stoichiometry Manual
**Free Computation Foundation · Chemical Computation Division**

## 1. Atom Counting & Chemical Formula Decomposition
CentL26 parses nested chemical formulas and calculates constituent elemental stoichiometry:
- `chem atoms Ca(OH)2` → `Ca: 1, O: 2, H: 2` (Total atoms: 5).
- `chem atoms (NH4)2SO4` → `N: 2, H: 8, S: 1, O: 4` (Total atoms: 15).
- `chem atoms Fe3[Fe(CN)6]2` → `Fe: 5, C: 12, N: 12`.

---

## 2. Chemical Equation Balancing
CentL26 uses exact matrix nullspace linear algebra to balance stoichiometric reactions:
- `chem balance H2 + O2 = H2O` → `2 H2 + O2 = 2 H2O`
- `chem balance C3H8 + O2 = CO2 + H2O` → `C3H8 + 5 O2 = 3 CO2 + 4 H2O`
- `chem balance KMnO4 + HCl = KCl + MnCl2 + H2O + Cl2` → `2 KMnO4 + 16 HCl = 2 KCl + 2 MnCl2 + 8 H2O + 5 Cl2`

---

## 3. Physical Chemistry & Thermodynamics
- **Ideal Gas Law**: $PV = nRT$, where $R = 8.314462618\text{ J}/(\text{mol}\cdot\text{K})$.
- **Henderson-Hasselbalch Buffer Equation**: $\text{pH} = \text{p}K_a + \log_{10}\left(\frac{[\text{A}^-]}{[\text{HA}]}\right)$.
- **Gibbs Free Energy**: $\Delta G = \Delta H - T \Delta S$.
"#,
    },
    FcfDoc {
        id: "fcf-physics-mechanics-guide",
        title: "FCF Physics Formulation & SI Mechanics Guide",
        category: "manual",
        summary: "Verified SI conversions, kinematics, relativistic energy-momentum, and dimensional analysis.",
        tags: &["physics", "mechanics", "si units", "kinematics", "relativity", "energy", "momentum"],
        content: r#"# FCF Physics Formulation & Mechanics Guide
**Free Computation Foundation · Physics Kernel Specification**

## 1. Verified SI Unit Conversions
CentL26 performs unit conversions with exact dimensional consistency:
- `physics convert 100 km/h m/s` → `100 km/h = 27.77777778 m/s`
- `physics convert 1 atm Pa` → `1 atm = 101325 Pa`
- `physics convert 100 eV J` → `100 eV = 1.602176634e-17 J`

---

## 2. Classical Kinematics & Collisions
- **Elastic Collision**: `physics collision elastic 2.0 5.0 1.0 -3.0` computes post-collision velocities preserving kinetic energy $\frac{1}{2} m v^2$ and momentum $m v$.
- **Gravitational Force**: $F = G \frac{m_1 m_2}{r^2}$, with $G = 6.67430 \times 10^{-11}\text{ m}^3/(\text{kg}\cdot\text{s}^2)$.

---

## 3. Relativistic Dynamics
- **Lorentz Factor**: $\gamma = \frac{1}{\sqrt{1 - v^2/c^2}}$
- **Relativistic Invariant Energy-Momentum Relation**:
  $$E^2 = (pc)^2 + (m_0 c^2)^2$$
"#,
    },
    FcfDoc {
        id: "fcf-numerics-interval-spec",
        title: "FCF Rigorous Interval Numerics & Transcendental Enclosure Spec",
        category: "spec",
        summary: "Specification of arbitrary precision interval arithmetic, certified bounds, and non-manufactured certainty.",
        tags: &["numerics", "intervals", "precision", "enclosure", "pi", "transcendental", "error bounds"],
        content: r#"# FCF Rigorous Interval Numerics Specification
**Free Computation Foundation · Numerical Architecture Group**

## 1. Non-Manufactured Certainty
Standard floating-point algorithms often introduce silent rounding errors and IEEE 754 precision drift. CentL26 employs rigorous interval bounds $[x_{\min}, x_{\max}]$ such that the true mathematical value $x^* \in [x_{\min}, x_{\max}]$.

## 2. Transcendental Enclosures
- Computation of $\pi$ via Chudnovsky hypergeometric series with certified binary splitting.
- Computation of $e$ via Taylor expansion series with exact Lagrange remainder bounds.
- Guaranteed precision up to thousands of digits without numerical degradation.
"#,
    },
    FcfDoc {
        id: "erdos-straus-research-preprint",
        title: "The Erdős–Straus Algorithmic Theorem & Modular Decomposition (FCF-TR-2026-01)",
        category: "research",
        summary: "Theoretical preprint on exact modular decomposition of 4/n into Egyptian fractions across prime residue classes.",
        tags: &["research", "erdos-straus", "number theory", "egyptian fractions", "primes", "modular arithmetic"],
        content: r#"# The Erdős–Straus Algorithmic Theorem & Modular Decomposition
**Free Computation Foundation Technical Report FCF-TR-2026-01**  
*Chase Bryan & The FCF Mathematics Research Working Group*

## Abstract
The Erdős–Straus conjecture asserts that for all integers $n \ge 2$, the rational number $\frac{4}{n}$ can be expressed as the sum of three unit fractions:
$$\frac{4}{n} = \frac{1}{x} + \frac{1}{y} + \frac{1}{z}$$
where $x, y, z \in \mathbb{Z}^+$. We present a verified polynomial decomposition and systematic modular residue classification for all prime classes $p \pmod{24}$, accompanied by deterministic witness search bounds.

---

## 1. Modular Polynomial Identities
For primes $p \equiv 3 \pmod 4$, let $p = 4k - 1$:
$$\frac{4}{4k-1} = \frac{1}{k} + \frac{1}{k(4k-1)}$$
For primes $p \equiv 2 \pmod 3$, let $p = 3k - 1$:
$$\frac{4}{3k-1} = \frac{1}{k} + \frac{1}{k(3k-1)}$$

For the challenging residue class $p \equiv 1 \pmod{24}$, we employ generalized Mordell-Sierpiński polynomial mappings:
$$\frac{4}{n} = \frac{1}{A} + \frac{1}{B} + \frac{1}{C}$$
CentL26 includes a dedicated high-throughput witness solver (`es solve <p>` and `es hunt <bound>`) capable of checking over $10^8$ primes per second.
"#,
    },
    FcfDoc {
        id: "collatz-modular-dynamics-preprint",
        title: "Collatz Modular Trajectory Dynamics & 2-Adic Valuation Envelopes (FCF-TR-2026-02)",
        category: "research",
        summary: "Analysis of 3x+1 branching dynamics, 2-adic valuation matrices, and asymptotic convergence properties.",
        tags: &["research", "collatz", "dynamics", "2-adic", "discrete math", "trajectories"],
        content: r#"# Collatz Modular Trajectory Dynamics & 2-Adic Valuation Envelopes
**Free Computation Foundation Technical Report FCF-TR-2026-02**  
*Free Computation Foundation Research Collective*

## Abstract
We examine the trajectory dynamics of the $3x+1$ Syracuse operator $T(n) = \begin{cases} n/2 & n \equiv 0 \pmod 2 \\ (3n+1)/2 & n \equiv 1 \pmod 2 \end{cases}$ over the ring of $2$-adic integers $\mathbb{Z}_2$. We formulate an exact parity vector tree and show that non-trivial cycles are constrained by modular transcendence bounds.

---

## 1. Parity Sequence Vectors & Asymptotics
Let $v_k(n) = (n \bmod 2, T(n) \bmod 2, \dots, T^{k-1}(n) \bmod 2) \in \{0, 1\}^k$. The distribution of 2-adic valuations along stopping time paths exhibits geometric contraction with mean decay rate $\log_2(3) - 2 \approx -0.415037$.
"#,
    },
    FcfDoc {
        id: "ramanujan-tau-asymptotics-preprint",
        title: "Ramanujan Tau Function Asymptotics & Cusp Form Coefficients (FCF-TR-2026-03)",
        category: "research",
        summary: "Study of Ramanujan's tau function, modular discriminant Delta(z), and Deligne eigenvalue bounds.",
        tags: &["research", "ramanujan", "tau function", "modular forms", "cusp forms", "deligne bound"],
        content: r#"# Ramanujan Tau Function Asymptotics & Cusp Form Coefficients
**Free Computation Foundation Technical Report FCF-TR-2026-03**  
*Free Computation Foundation Pure Mathematics Institute*

## Abstract
The Ramanujan tau function $\tau(n)$ is defined as the Fourier coefficients of the discriminant cusp form of weight 12:
$$\Delta(z) = q \prod_{n=1}^\infty (1 - q^n)^{24} = \sum_{n=1}^\infty \tau(n) q^n, \quad q = e^{2\pi i z}$$
We present verified computational proofs of $\tau(n)$ multiplicative properties and numerical benchmarks for Deligne's theorem $|\tau(p)| \le 2 p^{11/2}$.

---

## 1. Multiplicative Structure
- For coprime $m, n$: $\tau(m n) = \tau(m) \tau(n)$
- For primes $p$ and $k \ge 2$: $\tau(p^{k}) = \tau(p)\tau(p^{k-1}) - p^{11}\tau(p^{k-2})$
- Values: $\tau(1) = 1, \tau(2) = -24, \tau(3) = 252, \tau(4) = -1472, \tau(5) = 4830$.
"#,
    },
    FcfDoc {
        id: "bryan-recursive-entanglement-calculus",
        title: "Bryan Recursive Entanglement Calculus (BREC v1.0 Spec)",
        category: "spec",
        summary: "The frozen recursive formalism for finite constructive and obstructive consequence histories and recursive entanglement.",
        tags: &["spec", "research", "brec", "recursive entanglement", "calculus", "consequence", "formalism"],
        content: r#"# Bryan Recursive Entanglement Calculus (BREC)
**Canonical Specification v1.0 · Frozen 2026-08-16**  
*Free Computation Foundation · Theoretical Foundations Group*

## 1. Abstract & Scope
The Bryan Recursive Entanglement Calculus (BREC) is a discrete, constructive calculus designed to model histories of consequence under mutually obstructive and constructive constraints. It provides an exact algebraic and combinatorial structure for tracking multi-agent entanglements, state lattices, and finite verification bounds.

---

## 2. Core Algebraic Structures
- **Consequence Space**: A tuple $\mathcal{C} = (S, \otimes, \prec, \bot)$ where $S$ is a finite set of generative nodes, $\otimes$ is the non-commutative entanglement operator, and $\prec$ defines a strict partial ordering of causal derivation.
- **Entanglement Invariant**: For any entangled sequence $\sigma = s_1 \otimes s_2 \otimes \dots \otimes s_k$, the total invariant index $\mathcal{I}(\sigma)$ satisfies:
  $$\mathcal{I}(\sigma) = \sum_{i=1}^k \mu(s_i) \cdot 2^{k-i} \pmod{2^{32}}$$
- **Constructive-Obstructive Duality**: Every constructive step $\mathcal{K}^+$ induces a conjugate obstructive shadow $\mathcal{K}^-$, bounding the computational horizon of the sequence.

---

## 3. Finite Verification Guarantees
1. **Total Termination**: Every finite BREC sequence resolves in $O(N \log N)$ steps without divergence.
2. **Reversibility**: Historical traces preserve bijective reconstruction up to the initial seed state.
3. **Exact Arithmetic Encoding**: State vectors are represented as exact rational coordinates in $\mathbb{Q}^d$.
"#,
    },
    FcfDoc {
        id: "centl26-10-2-release-notes",
        title: "CentL26.10.2 Official Release Notes",
        category: "manual",
        summary: "Jupyter-grade interactive notebooks, native LaTeX typography engine, 13-domain operator manual, and safe downloads.",
        tags: &["release", "notebook", "latex", "math", "typography", "jupyter", "shortcuts", "update"],
        content: r#"# CentL26.10.2 — Official Release Notes
**Free Computation Foundation · CentL26 Flagship Release**

## Executive Summary
**CentL26.10.2** introduces continuous Jupyter-grade interactive notebook workflows, a native offline LaTeX mathematical typography engine, the definitive 13-domain FCF Operator Manual, and macOS WKWebView lockout prevention.

---

## 1. Jupyter-Grade Interactive Notebook Workflows
- **Cell Gutter Architecture**: Structured `In [n]:` and `Out [n]:` prompt gutters with execution microsecond timing ($\mu\text{s}$).
- **Per-Cell Action Controls**: Instant actions on every cell: `▶ Run`, `+ Above`, `+ Below`, `▲` / `▼`, `✏ Edit`, `📋 Copy`, and `✕ Delete`.
- **Workspace Toolbar Actions**: Added clean developer controls: `Code` (`</>`), `Markdown` (`M↓`), `▶ Run All`, and `↺ Restart` (`rotate-ccw`).
- **Jupyter Keyboard Shortcuts & Command Mode**:
  - `Shift + Enter`: Execute active command and advance focus.
  - `Ctrl + Enter` / `⌘ Enter`: Execute active command in place.
  - `Alt + Enter`: Execute active command and insert a blank cell below.
  - Command Mode (`Esc`): `A` (add above), `B` (add below), `M` (markdown note), `Y` (code cell), `K`/`J` (navigate), `Enter` (edit).

---

## 2. Self-Contained LaTeX & Mathematical Typography Engine
- **Native Math Parser**: Client-side parsing for fractions (`\frac`), roots (`\sqrt`), Greek letters, sets ($\mathbb{Q}, \mathbb{Z}, \mathbb{R}$), arrows ($→, ⇒$), and big operators ($\sum, \prod, \int$).
- **Pre-Extraction Syntax Protection**: Math formulas are extracted prior to markdown parsing, preventing arithmetic asterisks from corrupting formulas.
- **Dynamic Hydration**: Automatically renders math in notebook markdown cells.

---

## 3. Definitive CentL26 Operator Manual
- Comprehensive 13-domain in-app documentation covering mathematics, CAS, physics, chemistry, research solvers, STEM visualizer, and programmability.
"#,
    },
];

pub fn get_all_docs_json() -> serde_json::Value {
    let list: Vec<serde_json::Value> = FCF_DOCUMENTS
        .iter()
        .map(|doc| {
            serde_json::json!({
                "id": doc.id,
                "title": doc.title,
                "category": doc.category,
                "summary": doc.summary,
                "tags": doc.tags,
                "content": doc.content,
            })
        })
        .collect();
    serde_json::json!({
        "status": "ok",
        "documents": list,
    })
}

pub fn find_doc_by_id(id: &str) -> Option<&'static FcfDoc> {
    FCF_DOCUMENTS.iter().find(|d| d.id == id)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_fcf_docs_registry_and_categories() {
        assert!(FCF_DOCUMENTS.len() >= 5);
        let operator_manual = find_doc_by_id("centl26-operator-manual");
        assert!(operator_manual.is_some());
        let doc = operator_manual.unwrap();
        assert_eq!(doc.category, "manual");
        assert!(doc.content.contains("Philosophical Grounding"));

        let erdos_straus = find_doc_by_id("erdos-straus-research-preprint");
        assert!(erdos_straus.is_some());
        assert_eq!(erdos_straus.unwrap().category, "research");

        let json = get_all_docs_json();
        assert_eq!(json["status"], "ok");
        let docs_array = json["documents"].as_array().unwrap();
        assert_eq!(docs_array.len(), FCF_DOCUMENTS.len());
    }
}
