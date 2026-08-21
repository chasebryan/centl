## Unreleased

### CentL26.8.1 — Resilient Multi-Strategy Updater, Clean Bin Architecture & Zero Build Warnings (2026-08-21)

- **Resilient Multi-Strategy In-App Updater**: `execute_repo_update` now features a 3-tier compilation and download fallback pipeline:
  1. Standard fast release build (`cargo build --release --bin centl26`).
  2. Isolated target directory retry (`--target-dir target/update-build`) to gracefully bypass `Operation not permitted (os error 1)` hardlink locks in `target/release/build/`.
  3. Precompiled binary automatic download from GitHub Releases (`https://github.com/chasebryan/centl/releases/latest/download/...`) with in-place binary replacement if local cargo tools or compilation are locked.
- **Clean Library & Binary Architecture**: Refactored entry points into `src-web/lib.rs` and dedicated binary files (`centl_web.rs`, `centl_hub.rs`, `centl_lab.rs`), permanently eliminating the Cargo warning `warning: file src-web/main.rs found to be present in multiple build targets`.
- **Zero Build Warnings**: Guaranteed pristine compiler diagnostics across all 4 release targets.

### CentL26.8.0 — STEM Academic Search Engine, Gemini AI Resiliency & Intelligent Updates (2026-08-21)

- **STEM Academic Search Engine & Chrome Router**: Upgraded the Command Palette (`⌘ K`) into a unified STEM academic research hub. Routes any scientific inquiry directly to Google Scholar, arXiv, PubMed, Wolfram MathWorld, OEIS, NIST Chemistry WebBook, IEEE Xplore, and NASA ADS through Google Chrome with a bespoke FCF-stylized Chrome vector emblem.
- **FCF Knowledge Center & In-App Reader**: Built an offline indexed document viewer (`.fcf-doc-modal`) with rich Markdown parsing for all FCF operator manuals, mathematical architecture specifications, and theoretical research papers (Erdős–Straus, Collatz dynamics, Ramanujan tau asymptotics).
- **Gemini AI Co-Pilot Resiliency & Multi-Model Fallback**:
  - Auto-fallback chain across `gemini-2.5-flash` $\rightarrow$ `gemini-2.0-flash` $\rightarrow$ `gemini-1.5-flash` $\rightarrow$ `gemini-1.5-pro` $\rightarrow$ `gemini-2.5-pro` prevents 404/unsupported model errors.
  - Multi-variable key discovery (`CENTL_GEMINI_KEY`, `GEMINI_API_KEY`, `GOOGLE_API_KEY`, `GOOGLE_AI_API_KEY`, `GEMINI_KEY`) and cross-platform key persistence (`~/.centl/gemini.key` on macOS/Linux and `%USERPROFILE%\.centl\gemini.key` on Windows).
  - Resilient JSON/Markdown parsing: strips markdown code fences and automatically extracts JSON objects or graceful conversational mathematical reasoning with exact CentL verification.
- **Intelligent Dual-Channel Updates**: Rate-limit-free GitHub raw manifest polling (`https://raw.githubusercontent.com/chasebryan/CentL/main/Cargo.toml`) combined with `git ls-remote` / `git rev-parse` commit parity checks, providing 100% reliable update detection and in-place release recompilation.
- **Multi-Platform Universal Standard**: Certified builds across Windows 11, macOS (Apple Silicon / Intel), and Debian/Ubuntu/Fedora/Arch Linux.

### CentL26.7.3 — In-App Rust Toolchain & Repository Discovery (2026-08-21)

- **Universal Cargo & Git Discovery for In-App Updates**: `execute_repo_update` dynamically locates user Rust toolchains (`~/.cargo/bin/cargo`, Homebrew, system binaries) and auto-augments process `PATH` in GUI AppKit/WebKit desktop bundles to eliminate missing path / `os error 2` failures.
- **Dynamic Repository Root Resolver**: Accurately resolves repository root from current working directory or binary ancestor paths when updating local checkouts.
- **Clear Guidance for Binary Standalone Users**: If `CentL26` is run outside a git clone or without a local Rust toolchain, the update dialog provides crystal-clear links and instructions for downloading binary releases or installing Rust.

### CentL26.7.2 — Multi-Statement Cell Engine & Multi-Platform Updates (2026-08-21)

- **Large Multi-Statement Computations in Single Cells**: Write and run compound mathematical scripts, multi-step derivations, and mixed-domain calculations directly inside a single cell (split by newlines or semicolons `;`), featuring full step-by-step block transparency, inter-step variable persistence, comment support (`#` and `//`), and exact rational result enclosures.
- **Top Navigation Bar Polish**: Removed redundant top Run button; re-allocated and expanded the Command Center search bar (`⌘ K`) up to `480px` for optimal breathing room and quick access to commands.
- **Synchronized Multi-Platform Release Packages**: Packaged native portable distributions across **macOS Arm64** (`CentL26-macOS-arm64.zip`), **Linux x86_64** (`CentL26-Linux-x86_64.tar.gz`), and **Windows 11 x64** (`CentL26-Windows-x64.zip`).

### CentL26.7.1 — Natural Language Arithmetic & In-App Update Dialog (2026-08-21)

- **Universal Natural Language Arithmetic**: CentL-SCi parses and solves conversational math questions in plain English (e.g. `"what is 55 divided by 22?"` $\rightarrow$ `5/2` / `2.5`, percentages `"15% of 300"`, square roots `"square root of 144"`, fractions `"half of 150"`, number theory `"is 97 a prime number?"`, and gcd/lcm) with exact rational receipts.
- **Dedicated In-App Update Modal Dialog**: Built a Google-grade Software Update Dialog (`.fcf-update-modal`) with real-time status indication, 1-click in-place git pull & release recompilation, and smooth automated reload.

### CentL26.7.0 — Rock Standard Multi-Platform Release (2026-08-21)

- **Multi-Platform Standard Freeze**: Official native build and packaging automation for **Windows 11** (`install.ps1`, `desktop/centl26/windows/build.ps1`, `CentL26.bat`, `CentL26.ico`), **macOS Arm64** (`install.sh`, `./desktop/centl26/macos/build.sh`, `CentL26.app`), and **Debian / Ubuntu / Fedora / RHEL / Arch Linux** (`scripts/install-linux.sh`, `desktop/centl26/linux/build.sh`, `CentL26.desktop`, hicolor icon set).
- **Google-Grade Modern App Icon**: Designed and rendered a layered geometric mathematical icon with Google-grade visual harmony, radiant scientific blues (`#1A73E8`, `#4285F4`, `#24C1E0`), ambient elevation shadow, and multi-resolution packaging (`.icns`, `.ico`, `.svg`, and multi-res PNGs).
- **Verified Multi-Channel Update Mechanic**: Prioritizes native AppKit/WebKit updater message bridge (`CentL26Updater.swift`) in standalone desktop mode, automatic `origin/main` git synchronization with in-place rebuild and auto-reload for local clones, and informative release status for binary archives.
- **Stable Foundation Freeze**: Frozen CentL26.7 as the baseline rock standard for all subsequent development.

### CentL26.6.1 — Full Backend Sweep & Capabilities Release (2026-08-21)

- **Backend Mathematical & Number-Theoretic Sweep**: Native exact implementations added for `catalan(n)`, `stirling2(n, k)`, `bell(n)`, `derangements(n)`, `is_square(n)`, `next_prime(n)`, `prev_prime(n)`, `collatz(n)`, `divisors(n)`, `sum_divisors(n)`, `is_perfect(n)`, `median`, and `zscore`.
- **Expanded Plain-English SCi Problem Solver**: Enhanced natural language parsing for classical mechanics ($E_k, E_p, W, P, F_c$), electromagnetism (Ohm's law, electric power, capacitance), thermodynamics ($PV = nRT, Q = mc\Delta T$), wave dynamics ($v = f\lambda$), density, and gravitational laws.
- **Capabilities Registry Activation**: Upgraded `org.fcf.centl.numerics.enclose` from adapter-dependent to native `available` with arbitrary-precision interval enclosures.
- **Unified Web & macOS App Distribution**: Crystal-clear dual setup documentation for running CentL26 via local web server (`cargo run --release --bin centl26`) or native macOS application bundle (`./desktop/centl26/macos/build.sh`), both backed by the exact same offline Rust core engine.
- **Decluttered UI & Direct In-Place Naming**: Interactive click-to-type notebook renaming, unclipped typography, single `+` tab creation workflow, and removal of duplicate status badges.

### CentL26.5.0 — Product Maturity & Full Capability Release (2026-08-21)

- **Top-Left Version Branding**: Visual `v26.5` label directly embedded in the top-left branding lockup, kernel badge, and status bar.
- **Multi-Notebook Tabs & Workspaces**: Direct in-app tab bar supporting `+` tab creation, tab switching, and notebook renaming.
- **Save & Download Work**: Download active notebook sessions in clean Markdown (`/download/notebook.md`) or structured JSON (`/download/notebook.json`).
- **2D Coordinate Grid Function Plotter**: Full multi-line ASCII/Unicode coordinate grid visualization rendered directly in notebook cells, evidence panels, exports, and CLI.
- **In-App Repository Updater**: Bottom-right Update button checks `origin/main`, pulls latest commits, and rebuilds binaries in-place without Developer ID signature blocks on local builds.
- **Fresh-Clone Reliability**: macOS build scripts hardened to support shallow git checkouts and source archives automatically.
- **FCF About Modal**: Activity rail FCF icon opens modal dialog with links to `freecomputation.org` and GitHub sponsorship.
- **Native SCi & In-App Programmability**: Multi-domain STEM problem solver (32 domains) and `build` extension system registered as native available capabilities.
- **UI Redundancy Cleanup**: Consolidated status labels and explorer footers for a focused, clean scientific workbench.

### CentL26.4.1 (2026-08-21)

- 2D Function Plotter: Fixed notebook cell history rendering to preserve and display the full multi-line ASCII/Unicode coordinate grid graph and axis metrics in result cells and export receipts.

### CentL26.4.0 — Product Maturity Release (2026-08-21)

- Version display: Running version now visible in top-left branding lockup and status bar
- Notebook tabs: "New Computation" creates independent notebook tabs with separate sessions
- Save & download: Name, save, and download notebooks as Markdown or JSON
- Working updater: Update button pulls latest from main and rebuilds for repo-clone users
- FCF about panel: Activity rail FCF button opens about modal with sponsorship and website links
- SCi interpreter: Registered as native available capability (no longer integration-planned)
- Build system: In-app programmability registered as native capability; mirage references removed
- Redundancy cleanup: Consolidated duplicate CentL26 Core / Local / Exact-first status labels
- Fresh-clone reliability: Improved install pipeline for first-time users

### CentL26.2.3 release (Offline Multi-Domain SCi Solver & Plain English Reasoning)

- **Comprehensive Native Offline SCi Solver**: Substantially upgraded offline natural language problem understanding without external API dependencies. Users can think out loud and type plain-English questions across:
  - **Aqueous & Solution Chemistry**: Solution pH/pOH equilibrium ($[H^+] = 10^{-\text{pH}}$, $[OH^-] = 10^{-\text{pOH}}$, strong monoprotic/monobasic), volumetric dilutions ($M_1 V_1 = M_2 V_2$), thermochemical Gibbs free energy ($\Delta G = \Delta H - T\Delta S$) and spontaneity classification, electrochemical Nernst cell potentials ($E = E^\circ - \frac{0.0592}{n}\log_{10} Q$), reaction balancing, and composition.
  - **Classical Mechanics & Kinematics**: Multivariable linear kinematics ($v = v_0 + at$, $d = v_0 t + \frac{1}{2}at^2$), gravitational free fall impact speed ($v = \sqrt{2gh}$) and drop duration, kinetic energy ($KE = \frac{1}{2}mv^2$), gravitational potential energy ($PE = mgh$), mechanical work ($W = Fd$), power dissipation ($P = W/t$).
  - **Electromagnetism & Circuit Laws**: Ohmic current ($I = V/R$), circuit resistance ($R = V/I$), electric power ($P = VI$), capacitance and electrostatic stored energy ($C = Q/V$, $U = \frac{1}{2}CV^2$).
  - **Quantum, Photonics & Spectroscopy**: Hydrogenic Rydberg spectral lines ($1/\lambda = R_\infty Z^2 (1/n_1^2 - 1/n_2^2)$), photoelectric work function and stopping voltage ($K_{max} = hf - \Phi$), photon energy/momentum ($E = hc/\lambda$), matter waves ($\lambda = h/p$).
  - **Thermodynamics & Radiation**: Carnot cycle maximum thermodynamic limits ($\eta = 1 - T_c/T_h$), Stefan-Boltzmann radiant flux ($P/A = \sigma T^4$), Wien displacement peak wavelength ($\lambda_{max} = b/T$).
  - **Astrophysics & Relativity**: Planetary escape velocities ($v_{esc} = \sqrt{2GM/R}$), circular orbital velocities ($v_{orb} = \sqrt{GM/R}$), relativistic Lorentz factors ($\gamma = 1/\sqrt{1-v^2/c^2}$).
  - **Geometry & Mensuration**: Circle area and circumference ($A = \pi r^2, C = 2\pi r$), sphere volume and surface area ($V = \frac{4}{3}\pi r^3, A = 4\pi r^2$), cylinder volume ($V = \pi r^2 h$), Pythagorean right triangle geometry ($c = \sqrt{a^2 + b^2}$).
  - **Linear Algebra & Vector Calculus**: 3D vector dot products, cross products, and 2x2 matrix determinants.
  - **Number Theory & Statistics**: Euler's totient ($\phi(n)$), extended Euclidean algorithm ($ax + by = \gcd(a, b)$), modular multiplicative inverse ($a^{-1} \pmod m$), primality verification, prime factorization, sample mean, sample variance, and sample standard deviation.
  - **Symbolic Calculus & Plotting**: Derivatives with arbitrary variables, definite and indefinite integrals, algebraic root finding, polynomial factoring, polynomial expansion, and 2D ASCII coordinate graphing.
- **Unrestricted Evaluator Routing**: Removed restrictive symbol filters so that mathematical questions containing units (e.g. `m/s`, `km/h`, `kJ/mol`), operators (`*`, `+`, `-`, `/`, `^`), or parenthesized quantities seamlessly route to the offline SCi solver with verified step-by-step rational deductions.

### CentL26.2 release (Multi-Domain Auto-Detector, SCi Natural Language Solver, Gemini Hybrid, & Examples Catalog)

- **In-App Programmability & Extension Engine (`build`)**: Allows non-programmers to define, brainstorm, test, and execute custom STEM functions, units, constants, and pipelines in plain English or explicit builder syntax (e.g. `build fn KE(m, v) = 1/2 * m * v^2`, `build a formula for kinetic energy KE(m, v) = 0.5 * m * v^2`, `build const G_earth = 9.80665`, `build list`, `build inspect KE`, `build test KE 10 5`, `build export`). Registered user extensions are dynamically wired directly into notebook evaluations (e.g., `KE(10, 5)` computes `125` with exact receipts).
- **Dim Mode Theme Toggle**: Replaced redundant toolbar icon with a theme toggle (Sun/Moon icons) that engages a matte dimmed color palette (`theme-dim`), preserving 100% of the exact geometry, typography, and calm clarity, persisted across sessions in `localStorage`.
- **Smart Multi-Domain Auto-Detector**: Eliminates the requirement to manually prefix commands with subsystem tags. Users can run chemistry commands directly (e.g. `stoich measured 'C2H6 + O2 -> CO2 + H2O' C2H6 3 CO2`, `balance Fe + O2 -> Fe2O3`, `atoms Ca(OH)2`, `limiting ...`, `molar-mass ...`, `particles ...`, `moles ...`, `spread ...`, or raw chemical reactions like `Fe + O2 -> Fe2O3`), physics commands directly (e.g. `convert 100 cm m`, `convert 100 cm to m`, `constant c`, `cherenkov ...`, `gravity ...`, `collision ...`, `units`), Erdős–Straus commands directly (`solve 2521`, `probe 2521`, `hunt 20000`), and CPS commands (`preflight ...`).
- **CentL-SCi Natural Language STEM Problem Solver**: Allows users to write problem sets in plain English (e.g., "What is the molar mass of Ca(OH)2?", "Find the derivative of x^4 * cos(x) with respect to x", "Convert 100 kilometers per hour to meters per second", "Is 1009 a prime number?") and receive structured, step-by-step verified solutions offline across chemistry, physics, calculus, algebra, and number theory.
- **Extensible Hybrid Gemini Support**: Integrates optional Gemini API language model support (`:gemini-key <key>`, `GEMINI_API_KEY`/`CENTL_GEMINI_KEY`, or `:gemini <query>`) that decomposes complex STEM word problems into atomic CentL computational commands, executing and verifying each step against CentL's exact mathematical engine with offline SCi fallback.
- **Complete 50+ STEM Examples Catalog**: Added full downloadable spreadsheet (`/download/centl26-examples.csv`, `/download/centl26-examples.tsv`, and `/api/examples`) and explorer reference sheet links covering Chemistry, Chemical Process Systems, Mechanics, Thermodynamics, Quantum Physics, Calculus, Linear Algebra, Statistics, and Number Theory.
- **New Computation Flow Enhancement**: Fixed "New computation" button and keyboard shortcuts (`Alt+N`, `Cmd+Shift+N`, Palette `New computation`) to reliably activate the Work area, clear draft state without deleting notebook history, and smoothly focus the composer editor.
- **In-App Updater Flow**: Updated update checker to provide seamless in-app status notifications via WebKit messaging and `/api/update` without navigating out of the application.

### CentL26 product line

- Introduces **CentL26**, the standalone, offline scientific work environment
  and new annual desktop product line from the Free Computation Foundation.
- Replaces the former CENTL Lab product name with a calm, white, progressively
  disclosed IDE surface designed to keep the active work visible on a laptop.
- Adds the `centl26` executable, embedded workbench assets, loopback-only local
  host, asynchronous notebook execution, command palette, collapsible IDE
  panes, exact mathematics, current physics and research kernels, and visible
  result-assurance states.
- Keeps the public product identity at **CentL26** while source commits and
  internal build metadata identify changes independently from historical CENTL
  core-engine versions and Oasis qualification.
- Establishes the `centl.broker/1` capability-registry boundary so existing
  CENTL product families can be integrated without confusing planned adapters
  with currently available executors.
- Wires Work, Projects, Tools, Data, Models, Research, and Build to distinct
  explorer areas with correct active state, durable mode/layout selection, and
  honest unavailable or planned states where an adapter does not yet exist.
- Adds runtime-backed `/api/capabilities` and `/api/workspace` read models so
  provider availability, project revision, notebook runs, and area counts come
  from the running application rather than decorative UI constants.
- Turns notebook receipts into inspectable evidence records instead of rerun
  shortcuts, and makes unmatched command-palette input executable.
- Makes New computation start a blank draft without deleting notebook history,
  makes Clear persist a pristine notebook after one confirmation, disables
  empty Run/Clear actions, and keeps starters and reruns mode-compatible.
- Replaces the status-bar repository redirect with the native CentL26 updater:
  it discovers the newest immutable CentL26 build snapshot, accepts only a
  complete qualified macOS artifact set, installs it atomically, and relaunches
  the app without rewriting a previously published release. Each snapshot uses a
  unique `centl26-build-<sequence>-<commit>` tag titled CentL26 and is frozen on
  publish.
- Adds the native macOS application-bundle path; the application owns and
  terminates its private backend rather than asking the user to operate a
  browser-hosted website.
- Freezes the user-approved CentL26 visual system behind a deterministic design
  contract covering the workbench sources, native icon, 57 semantic invariants,
  CI enforcement, and an explicit reviewed-update workflow.
- Adds the first durable `centl.project/1` notebook store. The default project
  now survives application restarts through bounded, schema-validated,
  owner-private, atomically replaced `project.centllab` records.
- Integrates the qualified exact CENTL Chemistry slice through its versioned
  JSON machine protocol. `chem atoms <formula>` and
  `chem balance <reaction>` retain their complete provider evidence, and
  reaction results are admitted only after conservation verification.
- Bundles both canonical CENTL numerics and CENTL Chemistry by default, aligns
  the native launcher and backend provider environment, and verifies rigorous
  `approx(pi, 50)` plus chemistry atom/balance requests through the packaged
  HTTP application path.

- **cbis.kernel** now homes on
  `R = {hard p : p+4 and 4p+1 ∈ Sigma_1}` while the 0-to-infinity
  sweep still runs. `--home-only` / `--sweep-only`. W is split into
  linear / R / fab and is not weakened. A TTY `go` is a fixed color
  panel (sweep, home, matrix, last events) instead of a scrolling
  dump. `--scroll` or a pipe keeps the line log. `NO_COLOR` is
  honored. A 2:35 live-panel demo sits on the research README and
  on the public site (`site/assets/cbis-kernel-esp-demo.mp4`).
  Release tag: `cbis-1.2.0`.
- ES+ records the letter equation: \(\Lambda_K\) is the complement of
  the inverse signed-box cover. The note is
  `research/erdos-straus/ES-plus/LETTER-EQUATION.md`. Mathematics only.
- **cbap.kernel** (CB-Advanced-Processing) is a C letter-targeting
  engine: channels A/B/C acquire, lock, and track Mordell-hard primes
  on three CRT spectra; channel D sets LETTER true or drops the prime.
  `./centl es cbap` starts at 0 and resumes; `--random` sets the first
  start. GREAT is not stored. Letters go to `cbap.kernel/letters/`.
- The hunt lets the operator file all three stamps or LETTER only.
  Menu `[a]` / `[t]`, or `./centl es go --all` / `--letters-only`.
  The choice is stored on that hunt. GREAT/GOOD are compact JSONL, not
  a pair of files per hit. `./centl es compact` deletes an old file pile.
- The Erdős–Straus program now has a public infinite hunt (`./centl es go`),
  coupled bb.kernel / CC.kernel engines, resume seeds, and content-addressed
  letter numbers. The record is `research/erdos-straus/ES-HUNT.md`. A finished
  hunt is not a proof of the conjecture.
- Public site, manuals, and inspect now name CENTL v0.15.0 **Al-Nur** as
  the published Oasis. `main` and `mirage` continue from that floor.
  The `v0.15.0` tag stays.
- The public site hosts the research library and front-facing manuals as
  HTML. Search suggestions use a native `datalist`. The site serves no
  JavaScript. `join.html` is a consent-gated static launcher download.

## 0.15.0 — 2026-08-14

Official snapshot of the current stable main and mirage trees, placed on
the oasis tip so Oasis does not regress. This Oasis is named **Al-Nur**.
The canonical tag remains `v0.15.0`. After promotion, development
continues on those lines. The public commands remain `centl`,
`centl-physics`, and `centl-sci` on GNU/Linux x86_64. Laboratory
surfaces stay laboratory. This identity is the published Oasis Al-Nur.

### Security

- Workflow checkouts no longer persist GitHub credentials in `.git/config`.
  Distribution jobs use job-scoped `contents: write` and an explicit push
  token header instead of a workflow-wide write token.
- Oasis qualification and publication workflows no longer hold
  `statuses: write` or `checks: write`. Exact-SHA attestation is the Actions
  job conclusion, which cannot be forged with a stolen status token.
- The Oasis security gate still fails closed on high GitHub Security-tab
  alerts, except Scorecard's job-level `contents: write` warning on jobs that
  must publish releases or the `distribution` branch.
- Publish grants clamp contributor privileges regardless of hand-edited JSON.
  Pack identities, basenames, origin URLs, and staged paths are allowlisted;
  possible secret material is refused; `git` is invoked with `-C` instead of
  trusting a process-wide directory change.

### Added

- Official Oasis logic: `oasis` is the steadily advanced stable snapshot
  of current `main` and `mirage`. `./scripts/oasis --snapshot` reports
  that procedure without declaring Oasis.
- CARAVAN enrollment now assigns a durable live caravan number and
  returns it on re-enrollment of the same carrier.
- `CENTL-Marsa` is the undeletable harbor that ports the Camp stay to
  macOS and Windows. It is not Oasis. `install` now sends those kernels
  to the harbor instead of a dead end.
- FCF Camp #1 publishes a named stay artifact `fcf-camp-001`. It is not a
  SemVer identity and not an Oasis declaration. CENTL v0.14.0 remains Oasis.
- FCF now publishes an open proposal for companies and other AI software to
  use CENTL, contribute to `mirage`, and sponsor the foundation. Sponsorship
  does not buy Oasis or endorsement.
- The public site now carries search metadata, a sitemap that includes
  machine entry points, `llms.txt`, and an `ai.html` welcome for programs.
  Layout and `style.css` are unchanged. Ranking is not claimed.
- FCF Camps are the named stay when a new Oasis cannot honestly be declared.
  `centl-mirage camps` inspects occupation and never declares Oasis. CENTL
  v0.14.0 remains the published Oasis.
- CARAVAN reports catalog coverage, mission filters, store inventory, and
  verified cargo loads. `centl caravan inspect` is inspect-only. The signed
  join installer, invite schema, and `join.html` are unchanged.
- CENTL-MIRAGE now runs a complete local development cycle: CEGIS example
  search, semantic fingerprints, fingerprint comparison, autonomy policy,
  review, and explicit accept/reject. A cycle still does not activate source or
  promote assurance by itself.
- MIRAGE evidence executors can discharge parser, capability-discovery, and
  example or fingerprint regression obligations from transaction-bound
  artifacts instead of leaving those actions permanently pending.
- Deterministic SCi code generation can locate a native definition request
  inside surrounding prose rather than only at the start of a cell.
- `centl-mirage wellspring` and `centl-mirage oasis` inspect Wellspring
  Candidates and Oasis identity without declaring either status.
- `scripts/oasis.py --inspect` reports distance from Oasis qualification and
  cannot declare a release.
- Durable Wellspring Candidate records live under `docs/wellsprings/`.
- MIRAGE now records bounded equality-saturation rewrites, metamorphic
  property checks, a claim-local evidence lattice, Pareto ranking of
  admissible candidates, and an explicit cycle progress measure.
- Generated SCi external/native scaffolds have an inspectable JSONL ABI
  contract that cannot self-enable or claim verified-core modification.
- CENTL-SCi `status` is now a real BUILD command over the previously orphaned
  status module, with honest remaining gates.
- Deterministic SCi fast paths now admit `gcd of`, `lcm of`, and
  `fibonacci of` without consulting a model.
- The capability graph now includes gcd, lcm, Fibonacci, sequence, sum,
  product, and recurrence so MIRAGE can prefer composition.
- MIRAGE fingerprints load candidate definitions and report whether the core
  observation corpus is preserved; `iterate` recomputes an active cycle from
  stored source.
- CENTL-SCi now has a deterministic capability catalog, an FCF product-family
  listing, constructive next-step guidance, and `extend <request>` to start a
  local MIRAGE cycle instead of dead-ending on unsolved work.
- Spoken `sum of`, `product of`, `sequence of`, and `factorial of` lower to
  exact CENTL without a model.
- SCi can export a replayable workbook from the live session; BUILD can
  inspect a single catalog capability; MIRAGE `doctor` reports structural
  cycle health.
- Requirements that already compose to existing CENTL operations are marked
  SATISFIED instead of asking for a new implementation.
- Spoken ordinals such as `the 10th fibonacci number` lower to `fibonacci(10)`.
- Oasis inspection now blocks promotion when HEAD does not contain the
  current oasis tip, so a laboratory branch cannot regress Oasis-only
  installer, CI, or qualification work.
- CENTL-SCi encodes the official Oasis promotion path: experimental work
  drafts to `mirage`, Oasis remains a later qualification on `oasis`, and
  verbs that would self-approve, merge to oasis, or tag a release are
  refused. Inspection never declares Oasis.
- CENTL-SCi can prepare a reviewed contribution pack and, with an explicit
  local grant, commit only that pack and open a **draft** GitHub pull
  request against `mirage`. Tokens are not stored, English is not passed
  to a shell, oasis is never the automatic base, and out-of-scope harm
  is refused. This is not a claim of perfect security.
- CENTL-SCi records a user-owned growth journal and replayable dialect.
  `let square(x) = x^2 and then square(6)` creates, hot-loads, and evaluates
  in one utterance. Composition reports `Uses:`. Missing programs stay
  symbolic and tell the user how to create them. `:dialect`, `:journal`,
  and `export dialect` expose the living local language without promoting
  assurance.
- CENTL-SCi now has a live English program workshop: `let`, topic names,
  conventional exact recipes, and `teach yourself` create local `.centl`
  programs, install spoken aliases, evaluate a first example, and say
  whether a restart is required. Native programs hot-load. Host/OCaml
  growth writes a reviewable proposal and requires `dune build` plus a
  process restart. Verified core is never rewritten by this path.

### Changed

- Goal graphs record `validated_by` edges from requirements to extracted
  examples and acceptance cells.
- Public site copy and the repository README now lead with install and the
  three Oasis commands. FCF Camp #1 is named as the current stay where
  newest software is used; it does not replace Oasis. Laboratory internals
  stay in the documentation index. `style.css` and `join.html` are unchanged.

## 0.14.0 — 2026-08-10

### Release posture

- v0.14.0 is the consolidation and hardening release intended to succeed v0.12.0
  as the next stable CENTL baseline. The v0.13.0 development line was never
  formally published as a stable release; its validated work is incorporated
  here rather than presented as a separate public release.
- v0.14.0 is an **Oasis release**. Oasis is a repeatable release
  classification, not this version's codename. The declaration belongs to
  the exact reviewed commit that passed the Oasis gate.
- The canonical release tag remains ordinary Semantic Versioning: `v0.14.0`.

### Added

- CENTL-MIRAGE — Mathematical Introspective Recursive Autonomous Growth Engine —
  adds bounded local design-document ingestion, SHA-256 source identity,
  provenance-preserving Specification IR, typed goal/capability graphs,
  deterministic conflict detection, capability-gap analysis, evidence
  obligations, and non-mutating candidate transactions.
- MIRAGE can deterministically materialize supported candidate definitions,
  bind the exact staged source to its transaction identity, execute the
  authoritative parser against that source, record readiness evidence, and
  construct execution plans for still-undischarged obligations without
  promoting the candidate or mutating the active workspace.
- MIRAGE exposes local `start`, `ingest`, `analyze`, and `status` workflows while
  keeping generated/downstream work below verified-core assurance until the
  appropriate engineering and validation obligations are discharged.
- CENTL CARAVAN Phase 1 adds the reproducible local laboratory for authenticated,
  content-addressed artifact preservation and availability: immutable storage,
  deterministic chunk identities, Ed25519 carrier identity, signed policy
  acceptance, TUF-authenticated catalogs, outbound-only laboratory transport,
  bounded verified retrieval, bad-carrier quarantine/fallback, hostile-transfer
  coverage, and explicit join/status/leave lifecycle.
- `docs/OASIS.md` defines the reusable CENTL Oasis release standard and the
  evidence required before any release receives the declaration.
- `docs/REPOSITORY-MAP.md` defines the supported v0.14.0 source-tree organization
  and the boundary between runtime, laboratory, documentation, assets, scripts,
  tests, automation, and historical branch state.
- `docs/releases/0.14.0.md` records the v0.14.0 feature, trust, security, rollout,
  and Oasis-qualification boundaries.

### Changed

- The authoritative CENTL version is 0.14.0.
- CARAVAN is now an included **local laboratory** component rather than a future
  placeholder. Arbitrary public volunteer enrollment remains outside v0.14.0.
- CARAVAN retrieval now validates authenticated chunk shape and maximum chunk
  size independently, checks storage/free-space capacity before transfer, and
  bounds pending challenge and active-session populations.
- MIRAGE gap analysis no longer mistakes an available generation mechanism for
  an already-existing requested binding: explicitly materializable definitions
  are staged as extensions and must produce parser evidence before readiness.
- Repository hygiene and security are treated as release gates rather than
  post-release chores. Historical branches are preserved until unique work is
  reconciled; ambiguous active pull-request state is removed.

### Security and repository hygiene

- Removed the obsolete one-shot v0.13.0 auto-tag workflow and v0.13.0 native-gate
  observer, preventing abandoned release automation from mutating refs or
  creating failure branches during v0.14.0 work.
- Removed the obsolete fixed v0.10.0 publication workflow from the active
  automation surface.
- Corrected the immutable `ocaml/setup-ocaml` action annotation in MIRAGE CI to
  match the pinned 3.7.0 commit; the associated GitHub Advanced Security review
  thread resolved after the source fix.
- CARAVAN continues to pin the remediated `cryptography` release selected after
  dependency review rejected the earlier vulnerable laboratory pin.
- The GNU/Linux installer now rejects symlink, hard-link, device, FIFO, and other
  unsupported archive member types before extraction, in addition to its
  existing checksum, path/layout, staging, smoke-test, and atomic-activation
  controls. A hostile linked-archive regression test covers this boundary.
- The stale #65 physics draft was reconciled against the modern mainline and
  closed without deleting its historical branch; its supported product behavior
  is already present in the current physics implementation and regression suite.
- Oasis qualification retains least-privilege workflow permissions, immutable
  action pins, dependency review, GitHub Actions security analysis, CARAVAN,
  MIRAGE, installer, and final integrated release validation as release gates.

### Preserved from the unreleased 0.13.0 line

- CENTL-SCi v0.0.2-Caramels, GNU/Linux-only active platform policy, FCF release
  preservation/recovery work, model-provenance boundaries, and host-neutral
  preserved release-tree support are incorporated into v0.14.0.

## 0.13.0 — UNRELEASED DEVELOPMENT LINE — 2026-08-10

### Added

- CENTL-SCi v0.0.2-Caramels becomes the current scientific interaction generation,
  with answer-first natural-language mathematics and physics, deterministic fast
  paths, evidence-backed presentation, clarification for underspecified requests,
  structured result recall, and `MATH>`, `PHYS>`, `HYBRID>`, and `BUILD>` modes.
- Caramels adds user-owned extension workflows with persistent workspaces,
  revisions, snapshots, package composition, dependency-aware extension
  lifecycle operations, validation/audit surfaces, workspace import/export, and
  controlled downstream core-change planning without redefining verified CENTL.
- Deterministic Caramels interpretation covers exact arithmetic, equations,
  algebraic transforms, approximation, unit conversion, physical constants,
  closed verification claims, and supported uniform-gravity mechanics before
  any optional local semantic model is consulted.
- FCF preservation tooling can preserve published release bytes, run recurring
  local integrity/recovery drills, reconstruct the qualified CENTL-SCi runtime
  offline, preserve exact model provenance and immutable base-model repository
  revisions, and export only explicitly approved public release material.
- Installers can consume a host-neutral immutable release tree through an
  explicit HTTPS or local `file://` release base, allowing preserved FCF release
  storage to serve packages without changing CENTL's release format.

### Changed

- GNU/Linux is now the sole active development, CI, packaging, validation,
  installation, and release target. Historical macOS and Windows code may remain
  available, but active development for those platforms is halted.
- CENTL-SCi model output remains untrusted semantic input: model provenance is
  bound to exact bytes, and generated/external semantics cannot promote
  themselves to verified CENTL core.
- Release preservation and publication are separated: private recovery material
  such as models, caches, Git mirrors, OCI capsules, and reconstruction state is
  not automatically redistributable or included in public exports.

### Deferred

- CENTL CARAVAN is not part of v0.13.0. Its architecture and Phase 1 laboratory
  implementation remain a separate future release line.
- The experimental external JSONL execution boundary remains under development
  and is not part of the v0.13.0 stable release boundary.

## 0.12.0 — 2026-08-09

### Changed

- Promoted validated release candidate series to stable 0.12.0.
- Authoritative CLI/golden outputs updated to 0.12.0 where appropriate.
- Historical rc.2/rc.3 records preserved.


## 0.12.0-rc.3 — 2026-08-09

### Added

- CENTL-SCi is packaged and activated as a first-class native command alongside
  `centl` and `centl-physics`.
- A bare `centl-sci` starts the answer-first live scientific REPL.
- Native installers smoke-test CENTL-SCi exact arithmetic and REPL startup
  before activating the installed command.
- Unix installation can configure the user's PATH automatically, with an
  explicit opt-out and a POSIX profile fallback when the shell cannot be
  identified.
- Dedicated release notes document the first-run scientific interface and
  platform policy.

### Fixed

- The Unix installer no longer fails under `set -u` when `SHELL` is absent in a
  headless CI, container, or service environment.
- Windows installer validation no longer depends on PowerShell preserving
  native REPL line boundaries; it still requires both CENTL-SCi identity
  markers before activation.
- Regression coverage now exercises installation with `SHELL` explicitly
  removed and verifies `~/.profile` PATH fallback plus `centl-sci` activation.

### Release-candidate notes

- Linux remains the CENTL-SCi reference platform. Windows support is
  experimental and best-effort during the early development series.
- This is a candidate build for validation, not the final 0.12.0 publication.

## 0.12.0-rc.1 — 2026-08-08

### Added

- Math-contract release candidate:
  - Protocol `op: "verify"` and MCP `centl_verify` check structured claims.
  - CLI `centl verify --left/--relation/--right [--variable name:rational]
    [--json] [--receipt FILE]` and `centl check FILE [--json]
    [--receipt FILE]`.
  - Calculator grammar `assert(left rel right)` and quantified
    `assert(left rel right, for_all = x, domain = rational)`, host-checked
    outside the engine (assert exits follow verify: 0/1/2).
  - Decisive scopes: closed exact rational comparison, certified enclosure
    order/inequality, and universal equality in the F*-admitted univariate
    rational-polynomial fragment. The latter reports `verified_core` and names
    `Centl.PolynomialSoundness.surface_rational_polynomial_identity_sound`.
  - False polynomial equalities are `refuted` only with an exactly rechecked
    rational counterexample (`witness_checked`).
  - Enclosure evidence includes exact dyadic endpoints plus decimal bounds;
    polynomial evidence may include `normalized_difference` and
    `counterexample`.
  - Verdicts: `verified`, `refuted`, `unknown`, `invalid`. Operational failures
    (cancellation, resource/precision limits, backend failures) remain errors.
  - Free-form assumptions, multi-variable claims, quantified order, and
    unproved polynomial identities return `unknown`.
  - Session definitions may be read; verification never mutates session state.
  - Bounded receipts include the resolved claim, active limits, exact
    transitive session dependencies, session revision, verdict evidence, and
    the binary's semantic version, optional commit, and generated-core hash.
  - `--build-info` exposes the stamped build identity, receipt schema, and
    protocol version. Native archives carry a validated `BUILD_MANIFEST.json`.
  - A reusable local `centl-check` GitHub Action runs passing contracts and can
    retain their receipt collection as an artifact.
  - Passing and deliberately pending example contracts live under
    `examples/contracts/`.
  - `describe` advertises verification scopes, verdicts, and assurance classes.

### Release-candidate notes

- Claims outside the admitted proof fragment—including symbolic division and
  multiple free variables—remain `unknown`; this is intentional.
- This is a candidate build for validation, not the final 0.12.0 publication.

## 0.11.0 — 2026-08-08

### Added

- Every successful evaluation now carries an orthogonal transformation
  resolution: `computed`, `transformed`, `unchanged_proved`, `residual`,
  `unsupported`, or `indeterminate`. Transformation metadata identifies the
  operation, stable reason, and supported mathematical domain where relevant.
- Persistent JSON Lines adds read-only `compute` and explicit `define`
  operations. MCP adds `centl_compute` and `centl_define` with accurate
  read-only/idempotence annotations and exact discriminated output schemas.
- `describe` and `centl_capabilities` publish resolution statuses, supported
  mathematical domains, examples, limits, and cancellation behavior.
- `session` and `centl_session` return immutable definitions in creation order
  with canonical expressions and direct dependencies.
- `help` and `centl_help` provide focused structured help generated from the
  canonical syntax catalog.
- Machine errors include retryability, structured source ranges, named limit
  details, and recovery suggestions when known.
- An executable agent-tool corpus covers correct calls, supported-domain
  selection, residual recognition, read-only rejection, cancellation, limit
  failures, exact sequences, substitution, define-only validation, and
  unresolved equations.
- MCP tool text content now mirrors human residual annotations and includes
  recovery suggestions on mathematical tool errors, while structured content
  remains the canonical machine result.
- End-to-end CLI coverage exercises `compute`/`define`/`session`/`help` and
  residual classification on human, JSON Lines, and MCP surfaces.

### Changed

- Residual or unsupported differentiation, integration, simplification,
  expansion, factoring, and solving can no longer look like a completed
  transformation in human, JSON, JSON Lines, or MCP output.
- `centl_calculate` and JSON `evaluate` retain their combined compute/define
  behavior as a documented compatibility route. New automated integrations
  should use the split operations.

Machine protocol version 1 remains unchanged. Successful evaluation responses
now require top-level `resolution`; machine error objects now require
`retryable`. Strict clients should update their response schemas. MCP tool
discovery exposes seven tools instead of two.

## 0.10.0 — 2026-08-04

### Added

- `sequence(expression, variable = lower, upper)` produces an exact finite
  sequence over inclusive integer bounds, with lexical index scope and a
  defined empty result.
- `recurrence(initial, previous = step, index = lower, upper)` produces an
  exact first-order bounded recurrence. The initial value occupies the lower
  index and every later term receives the previous exact value and its current
  index.
- Exact sequences have a structured protocol value, provenance, and identical
  behavior through one-shot JSON, persistent JSON Lines, and MCP.
- Real quadratic equations with positive nonsquare discriminants now return
  verified exact conjugate roots as canonical `center ± sqrt(radicand)` pairs,
  including structured branch, center, and radicand fields.
- Human input supports syntax-aware multiline statements in the calculator,
  standard-input scripts, and `--file` scripts. Syntax and runtime mathematical
  diagnostics now retain source locations; human output includes a caret
  excerpt and machine errors expose a stable zero-based byte position.
- Interactive terminals provide built-in and session-name completion plus
  private, versioned, bounded history shared safely across calculator
  processes. `:history`, `:clear-history`, `--no-history`, and environment
  opt-outs make persistence explicit and controllable.
- Deterministic parser/protocol/native mutation corpora, exact-rational
  metamorphic checks, ASan/UBSan coverage of the production Arb shim, and
  conservative startup/evaluation performance budgets provide reproducible
  hardening gates.
- A pinned opam manifest, contributor bootstrap, honest formatting and lint
  gates, and a focused pull-request verification workflow make the development
  path reproducible.

### Changed

- Exact rendering now uses an explicit traversal stack and bounded buffer
  construction, including cancellation-aware size preflight, so deeply nested
  symbolic results do not depend on the OCaml call stack.
- Sequences and recurrences share the existing request-wide iteration, exact
  bit, symbolic node, serialized-value byte, work, and cancellation limits.
  Aggregate retained sequence elements are checked before a result is returned
  or a definition is committed.
- Empty finite ranges defer session-function expansion as well as evaluation.
  Exact-bit budgets use rational numerator/denominator profiles and validate
  the actual exact payload before output; sequence and enclosure results cannot
  cross scalar-only iteration or symbolic-transformation boundaries.
- Pull requests run the pinned Linux verification, native, quality, and seeded
  Julia/Nemo differential path. Full native packaging remains on `main`, tags,
  and manual runs, and superseded branch runs are cancelled.
- Quadratic completion validates host-supplied integer square-root floor
  witnesses in F*, preserves the existing rational-root representation, and
  applies exact-bit, result-byte, and cooperative-cancellation boundaries.
- MCP calculation and reset responses now advertise separate closed output
  schemas; calculation schemas discriminate every value, definition, error,
  rational solution, and exact real-quadratic solution shape and are allocated
  only during tool discovery.
- Persistent JSON Lines and MCP input use an extracted, directly tested FIFO
  queue with exact count/byte accounting and one separately bounded emergency
  cancellation slot, so ordinary saturation cannot prevent a valid
  cancellation from reaching its target.
- Native release verification installs Git and its runtime prerequisites before
  checkout and asserts that verification runs inside the expected worktree.

Machine protocol version 1 remains unchanged. Consumers that exhaustively
match value kinds must accept the new exact `sequence` kind. Consumers that
inspect `solution_set.solutions` must also accept tagged `real_quadratic`
members alongside the unchanged rational member shape. `sequence` and
`recurrence` are reserved built-in names.

## 0.9.1 — 2026-08-02

### Fixed

- Linux and macOS x86_64 release libraries now target baseline x86-64 and use
  GMP runtime CPU dispatch instead of inheriting the hosted runner's ISA.
- Native release CI executes the packaged Linux binary under an emulated Core 2
  CPU for both exact GMP arithmetic and rigorous MPFR approximation.

The x86_64 native libraries attached to `0.9.0` were tuned for their CI runner
CPU and can exit with an illegal-instruction fault on older x86_64 processors.
Source builds, Windows, and macOS arm64 artifacts are unaffected; use `0.9.1`
for portable Linux and macOS x86_64 packages.

## 0.9.0 — 2026-08-02

### Added

- Exact inclusive `sum(expression, variable = lower, upper)` and
  `product(expression, variable = lower, upper)`, including nested iteration,
  exact rational or symbolic results, and defined empty ranges.
- `integrate(p, x)` for the canonical zero-constant antiderivative of an exact
  rational-coefficient univariate polynomial.
- `integrate(p, x = a, b)` for exact definite integration over exact rational
  bounds.
- Explicit residual `integrate(...)` expressions for unsupported integrands or
  bounds; CENTL does not guess or silently approximate them.
- Structured provenance for every machine result and request-scoped cooperative
  cancellation across JSON Lines and MCP.
- Pinned Julia/Nemo differential tests, formatting and lint gates, and expanded
  adversarial coverage.

### Changed

- Substitution is simultaneous and capture-avoiding across iteration,
  integration, differentiation, solving, and substitution binders.
- Bounded FIFO input queues, aggregate session and result limits, atomic
  definition commits, and symbolic-work preflight harden persistent operation.
- The verified core now covers semantic differentiation, polynomial
  antiderivative coefficient round trips, outward decimal rounding, and
  logarithmic exact-power properties.

The accepted polynomial syntax uses positive powers no larger than 64.
Explicit zero powers remain residual so the evaluator does not erase a possible
`0^0` error.

Machine protocol version 1 and existing value kinds remain unchanged. Machine
responses now include top-level provenance; strict response-schema consumers
may need to accept that required field. `sum`, `product`, and `integrate` are
reserved built-in names.

## 0.8.0

Added persistent JSON Lines and MCP operation. See the repository history and
release notes for the complete change record.
