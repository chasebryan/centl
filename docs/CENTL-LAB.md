# CENTL Lab graphical work environment (superseded)

> **This document is a historical design record.** The application has been
> promoted and redesigned as **CentL26**. The normative current product,
> interface, versioning, project, capability-broker, and backend-integration
> specification is [CENTL26-ARCHITECTURE.md](CENTL26-ARCHITECTURE.md). Where this
> record conflicts with that specification—especially the old editorial color
> system, default panel density, or `centl-lab` product name—the CentL26
> specification governs.

**Status:** legacy migration record  
**Product boundary:** standalone private host, not part of freecomputation.org  
**Identity:** CENTL, by the Free Computation Foundation  

> Free for science.

## Product definition

CENTL Lab is the graphical scientific work environment for CENTL. It is not a
website with a calculator attached and it is not a skin over the existing Hub.
It is a project-based environment in which a scientist can formulate a problem,
assemble inputs and models, execute deterministic kernels, inspect a visual
result, and retain the evidence that justifies the result.

The public FCF website remains a publishing, documentation, and research-library
surface. CENTL Lab is a private application surface. Its host binds to loopback,
ships its interface inside the executable, and has no CDN or public-site runtime
dependency.

## Non-negotiable design rules

1. A project, not a command line, is the top-level unit of work.
2. The notebook is one instrument among several, not the whole product.
3. Exact, bounded, deterministic, local, experimental, and unresolved results
   must remain visually distinguishable.
4. Every admitted execution creates a receipt linked to its input, executor,
   output, assurance class, and relevant workspace revision.
5. Unsupported work remains an inspectable object. The interface must never
   manufacture a plot, value, proof, or physical conclusion to fill an empty UI.
6. Files, datasets, models, visualizations, and receipts must be usable without
   an internet connection.
7. Natural-language interpretation may help formulate work but may not become a
   second evaluator or confer assurance.
8. The visual system belongs to FCF: Oasis blue structure, paper and sand work
   surfaces, rust and palm evidence accents, editorial serif headings, and
   restrained instrument typography.

## Durable work objects

```text
Project
├── Experiments
│   ├── Notebooks
│   │   ├── Note cells
│   │   ├── Computation cells
│   │   ├── Protocol cells
│   │   ├── Dataset cells
│   │   └── Visualization cells
│   ├── Runs
│   └── Artifacts
├── Datasets
├── Models
├── Receipts
├── Local extensions
└── Project policy
```

- **Project:** the portable local workspace and assurance boundary.
- **Experiment:** a named scientific question with methods, assumptions, and
  related runs.
- **Notebook:** the narrative and executable record of an experiment.
- **Dataset:** typed tabular, vector, time-series, or structured protocol input.
- **Model:** a reusable mathematical, physical, chemical, or domain-specific
  representation.
- **Run:** one immutable execution attempt, including unsuccessful attempts.
- **Artifact:** a plot, table, certificate, report, snapshot, or exported result.
- **Receipt:** the machine-readable evidence record for an admitted execution.
- **Extension:** downstream user code whose assurance remains separate from the
  verified core.

## Window anatomy

The main window is an IDE-scale instrument surface:

1. **Title bar** — FCF/CENTL identity, application menus, global command search,
   and local-kernel state.
2. **Activity bar** — project, search, datasets, models, extensions, inspector,
   and settings.
3. **Project explorer** — experiments and durable scientific objects rather than
   navigation links.
4. **Document tabs** — notebooks, datasets, model editors, receipts, and reports
   can be open together.
5. **Notebook toolbar** — run controls, cell insertion, mode selection, kernel
   selection, and experiment actions.
6. **Central work canvas** — typed notebook cells and domain instruments.
7. **Inspector** — visual analysis, symbols, dimensions, assumptions, evidence,
   and receipts beside the work they describe.
8. **Execution trace** — kernel, protocol, validation, and failure events.
9. **Status line** — FCF mission, assurance mode, product line, session, and
   editor state.

The explorer, inspector, and trace are independently collapsible. Layout state
is local to the workstation.

## Domain environments

### Exact mathematics and symbolic analysis

- structured expression editor with canonical CENTL source view;
- exact arithmetic, algebra, geometry, combinatorics, and sequences;
- symbolic differentiation, integration, solving, substitution, factoring,
  expansion, and simplification;
- symbol table and definition dependencies;
- exact result view alongside optional bounded decimal views;
- comparison and claim-verification instruments.

### Rigorous numerics

- precision and enclosure controls;
- interval/enclosure plot layers distinct from point estimates;
- convergence and precision diagnostics;
- copy/export operations that preserve qualification metadata;
- refusal states when the requested digits are not justified.

### Physics

- typed quantity and unit editor;
- vector, particle, force, world, contact, and collision inspectors;
- 2D/3D scene and timeline views backed by explicit model state;
- integrator and timestep controls that identify the discrete method;
- momentum, energy, contact, and invariant diagnostics;
- exact state tables beside graphical views.

### Research expeditions

- bounded-run configuration and search grades;
- progress, findings, certificates, and reproducibility metadata;
- comparison of runs without implying that a finite search proves a universal
  statement;
- first-class support for the Erdős–Straus public research kernels.

### CENTL-SCi

- MATH, PHYS, HYBRID, and BUILD input modes;
- deterministic interpretation record before execution;
- clarification and missing-information states;
- normalized input, typed Problem IR, executor request, and evidence explanation;
- natural language never replaces canonical source or authoritative output.

### BUILD and MIRAGE

- local definitions and downstream extensions;
- source, test, capability, and assurance views;
- MIRAGE proposal/review/materialization lifecycle;
- explicit separation among verified core, generated work, external code, and
  user-local code.

### Chemistry

Chemistry instruments must appear only as implementation reaches the public
exact-first chemistry contract. Planned editors include formula structure,
reaction balancing with per-element conservation evidence, stoichiometry,
provenance-aware chemical data, and explicitly modeled thermochemical work.
The Lab must not present the chemistry roadmap as an implemented capability.

## Execution topology

```text
CENTL Lab window
      │
      ├── project/object service
      ├── notebook and visualization service
      └── local execution broker
                 │
                 ├── CENTL exact core
                 ├── CENTL Physics
                 ├── CENTL Chemistry (when admitted)
                 ├── research kernels
                 ├── CENTL-SCi interpreter
                 └── BUILD / MIRAGE workspace operations
                          │
                          └── receipt + artifact store
```

The graphical layer never implements parallel scientific semantics. It submits a
typed request to the authoritative kernel, then renders the result and evidence.

## Offline and security boundary

- `centl-lab` binds to `127.0.0.1` only.
- HTML, CSS, and application JavaScript are embedded in the Rust binary.
- The initial host defines a restrictive same-origin Content Security Policy.
- No CDN, analytics, remote font, or public-site asset is required.
- The current session store is process-local and bounded.
- Layout and unfinished-cell draft state are stored locally in the application
  renderer; they contain no remote synchronization path.
- Future project persistence must use explicit project roots, bounded file sizes,
  atomic writes, and portable versioned schemas.

## Implemented first slice

The current Rust implementation provides:

- the dedicated `centl-lab` binary and `centl-web --lab` entry point;
- an embedded, loopback-only application host;
- project explorer, document tabs, notebook cells, command palette, collapsible
  IDE panes, trace console, visualization and evidence inspectors;
- asynchronous cell execution without full-window navigation;
- exact mathematics and symbolic execution through the Rust CENTL engine;
- current typed physics conversion/collision operations;
- current Erdős–Straus solver and bounded hunt operations;
- bounded session history and visible execution receipts;
- keyboard execution (`Ctrl+Enter`) and command search (`Ctrl/Cmd+K`);
- progressive form operation if application JavaScript is unavailable.

The datasets, project files, model editor, multiple cell types, plot binding, and
extension lifecycle visible in the shell are the intended object model and work
surface. They are not yet a claim that persistence or every domain editor is
implemented. The interface must continue to label implementation boundaries
honestly as those services are added.

## Next implementation sequence

1. Versioned `.centllab` project manifest and atomic local project persistence.
2. Notebook cell CRUD, immutable run records, and artifact/receipt addressing.
3. Dataset table, import, schema, unit, and provenance services.
4. Plot specification and exact/enclosure-aware 2D visualization.
5. Physics world editor, timeline, state table, and diagnostic plots.
6. CENTL-SCi typed request and explanation integration.
7. Verification, protocol, and evidence-graph document types.
8. BUILD/MIRAGE extension workbench with assurance-separated execution.
9. Native desktop window packaging over the same private embedded host.
10. Accessibility, keyboard, large-project, recovery, and offline qualification.
