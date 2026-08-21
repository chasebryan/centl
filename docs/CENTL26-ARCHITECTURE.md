# CentL26 product and platform architecture

**Status:** normative architecture for the new main application line  
**Product:** CentL26  
**Organization:** FCF — Free Computation Foundation  
**Scope:** standalone desktop product, project format, capability integration,
compatibility, and release qualification

> Free for science.

## 1. Product definition

**CentL26 is the product.** It is the all-encompassing, standalone scientific
work environment through which people use CENTL mathematics, physics,
chemistry, scientific interpretation, research, evidence, extension, and
preservation facilities.

CentL26 replaces **CENTL Lab** as the user-facing application name. “Lab” may
remain a descriptive noun and a migration term, but it is not a separate
product line. The application launches as a desktop program, owns its window,
opens projects directly, and does not require the user to operate it through a
general-purpose browser.

CentL26 is not a new evaluator and is not a monolith that rewrites every
existing engine. It is a coherent product shell, project system, and execution
boundary over versioned backend capabilities. Existing CENTL productry becomes
an integrated capability family behind that boundary rather than a collection
of competing top-level applications.

The product must preserve these rules:

1. The project is the durable unit of work; a page, prompt, or process is not.
2. Scientific semantics belong to authoritative engines, never to the UI.
3. Exact, proved, bounded, deterministic, experimental, untrusted, failed, and
   unsupported outcomes remain distinguishable.
4. Every admitted execution is attributable to its inputs, project revision,
   capability contract, executor build, policy, and evidence.
5. Backend availability never implies verified-core assurance.
6. The complete primary workflow works offline after installation.
7. The product presents one calm work surface; advanced facilities are reached
   progressively through commands, inspectors, and contextual tools.
8. A typical laptop window has no whole-application document scroll. Individual
   editors, notebooks, tables, consoles, and inspectors own their local scroll.

## 2. Canonical identity and naming

The following names have different responsibilities and must not be collapsed:

| Name | Meaning |
| --- | --- |
| **CentL26** | The composed 2026 desktop product and main user experience. |
| **CENTL** | The computational lineage and exact-first core engine family. |
| **FCF** | The organization abbreviation. |
| **Free Computation Foundation** | The full organization identity. |
| **Oasis** | A qualification state for an exact release snapshot, not a product version. |
| **MIRAGE, SCi, Physics, Chemistry, CARAVAN, CENTLAMP** | Capability families, services, or development programs presented through CentL26. |
| **Camp, Marsa, Wellspring** | Distribution, historical, governance, or knowledge concepts; not competing application brands. |

Normal application chrome should say **CentL26**, not `centl-web`, `centl-lab`,
an engine version, a model vendor, or a development branch. `FCF` may appear in
compact persistent identity, while **Free Computation Foundation** appears in
the welcome surface, About, release provenance, exports, and other durable
identity locations. Backend names remain visible where they are useful:
capability selection, evidence, diagnostics, receipts, licenses, and About.

The desktop bundle identifier should remain stable across annual trains so an
operating system sees one continuing application. Year-specific display names
and launch aliases may coexist, but they must not fragment project ownership or
application updates.

## 3. Stable product identity and build metadata

The human-facing product name remains **CentL26** throughout the continuing
2026 channel. Feature work, backend integration, and maintenance do not create
public `CentL26.N` editions. The native bundle and Cargo package retain the
internal compatibility value `26.0.0`; the source commit, build identifier, and
composition manifest distinguish exact builds.

Internal build metadata never enters the brand. Diagnostic and provenance
surfaces may report `26.0.0`, a source commit, and a build identifier, while
normal application chrome and release communication continue to say CentL26.
Backend engines retain their own independent versions.

### 3.1 Independent version axes

A CentL26 build is a composition, not a single source version. Its release
manifest must record every independent axis:

| Axis | Example form | Compatibility question |
| --- | --- | --- |
| Product build | `CentL26` + source/build identity | Which complete application composition is running? |
| Project schema | `centl.project/1` | Can this project be opened and written safely? |
| Broker protocol | `centl.broker/1` | Can the shell and broker exchange requests? |
| Capability contract | `org.fcf.centl.math.evaluate/1` | Does this request/result shape have the expected meaning? |
| Adapter | adapter SemVer + build digest | Can the broker invoke this engine correctly? |
| Backend engine | engine SemVer or native build ID | Which implementation performed the work? |
| Receipt/evidence schema | `centl.receipt/1` | Can evidence be read and verified? |
| SCi model/runtime | model, grammar, runtime, and weight digest | Which untrusted interpreter produced the IR? |
| Dataset/constant catalog | catalog ID + revision/digest | Which scientific data informed the result? |
| Extension | package version + content digest | Which user or third-party code ran? |

The About surface may summarize these values, but the complete composition must
remain exportable as a machine-readable bill of materials. Receipts record the
versions relevant to their individual run.

An engine or product update does not rename CentL26. The product manifest is the
authoritative mapping between the stable application identity and its exact
components.

## 4. Standalone application boundary

The target runtime topology is:

```text
CentL26 native window
  |
  +-- application controller
  |     +-- commands, documents, layout, accessibility, recovery
  |
  +-- project service
  |     +-- object graph, revisions, content store, migrations, search
  |
  +-- capability broker
  |     +-- registry, validation, routing, budgets, cancellation, receipts
  |
  +-- worker supervisor
  |     +-- built-in adapters -> authoritative CENTL engines
  |     +-- optional adapters  -> models, research kernels, extensions
  |
  +-- artifact and evidence service
        +-- immutable runs, artifacts, receipts, provenance graph
```

The shipped artifact is a desktop application bundle or native package. UI
assets and required engines are included in the installation. Double-clicking
the application or a project opens an application window; it must not instruct
the user to copy a loopback URL into a browser.

The first native release may retain the existing embedded HTML/CSS/JavaScript
renderer inside a private webview. That is an implementation technique, not a
web product boundary. If a loopback server remains temporarily necessary, it
must be child-process-owned, authenticated, dynamically addressed, unreachable
from non-loopback interfaces, and stopped with the application. Local IPC is
the preferred stable boundary.

The public `freecomputation.org` site is documentation, publication, and public
research infrastructure. CentL26 does not load its runtime, fonts, analytics,
scripts, or visual assets from that site. Hosted services, when explicitly
enabled, are optional capability providers and must be visibly distinct from
local execution.

### 4.1 Window and work-surface contract

The application controller exposes a stable IDE anatomy without displaying all
facilities at once:

- a compact title/command region;
- one narrow activity switcher;
- an optional project navigator;
- a central document/work area;
- one contextual inspector region;
- an optional bottom panel for trace, problems, jobs, or terminal work;
- a small status line for project, execution, assurance, and background state.

Navigator, inspector, and bottom panel are independently collapsible and
resizable. The center retains priority. At supported laptop minimum sizes, the
frame remains fixed to the window and no global vertical page is created.
Commands, keyboard navigation, document tabs, quick-open, and contextual actions
provide access to depth without permanent dashboard density.

Layout is a user preference, not project scientific state. It may be synced or
restored separately, but it must not change a project's computational revision.

### 4.2 Automatic update channel

The status-line **Update** action is a native application operation, not a link
to the source repository. On macOS it asks the host to check the repository's
published `centl26` release, offers the newest complete build for the current
architecture, downloads it after confirmation, replaces `CentL26.app`, and
relaunches the application. A browser-hosted development surface reports that
updates require the native app and does not redirect elsewhere.

The public name and bundle version remain CentL26 and `26.0.0`; the release and
build manifests compare source commits to identify an update. The channel
publishes one architecture-specific ZIP, adjacent checksum, and release
manifest. The manifest is published last so a partially uploaded update is not
offered. Local ad-hoc or unpinned builds remain development artifacts and do not
masquerade as installable channel updates.

## 5. Capability broker

The capability broker is the only supported application-level route from the
CentL26 work surface to computation. It is a semantic firewall, dispatcher, and
evidence coordinator; it is not another mathematics or physics engine.

### 5.1 Responsibilities

The broker must:

1. discover built-in, optional, and project-local capability manifests;
2. select by stable capability ID and compatible contract version;
3. validate request structure before execution;
4. enforce project policy, trust, resource, filesystem, network, and concurrency
   boundaries;
5. route deterministically to one declared adapter, never by undocumented
   fallback;
6. supervise start, progress, cancellation, timeout, crash, and retry behavior;
7. validate the returned envelope without reinterpreting scientific meaning;
8. commit immutable run, artifact, diagnostic, and receipt objects atomically;
9. report unavailable or incompatible work as such instead of manufacturing a
   substitute;
10. expose capability status separately from result assurance.

### 5.2 Capability manifest

Every provider supplies a signed or installation-trusted manifest containing at
least:

```text
capability_id
contract_versions
provider_id
adapter_version
backend_identity_and_build
domain_and_operations
maturity: stable | preview | experimental | disabled
assurance_classes_the_provider_may_report
determinism_and_replay_properties
required_permissions
resource_limits
input_and_output_schema_digests
receipt_and_evidence_schema_versions
platform_constraints
license_and_provenance
```

Capability maturity describes product support. Assurance describes a specific
result. A stable capability can return `unsupported`; an experimental provider
can produce a deterministically replayable result without thereby becoming
verified core.

Stable IDs describe meaning, not a binary name. Representative families are:

```text
org.fcf.centl.math.evaluate
org.fcf.centl.math.verify
org.fcf.centl.numerics.enclose
org.fcf.centl.physics.convert
org.fcf.centl.physics.simulate
org.fcf.centl.chemistry.compute
org.fcf.centl.sci.interpret
org.fcf.centl.research.erdos_straus
org.fcf.centl.mirage.develop
org.fcf.centl.caravan.retrieve
org.fcf.centl.search.rank
```

The examples establish a namespace, not a declaration that every listed
contract is currently implemented or stable.

### 5.3 Request and result envelopes

A broker request contains:

- request and run IDs;
- project ID and exact input revision;
- capability ID and accepted contract range;
- typed operation and references to input objects;
- explicit parameters, assumptions, units, and requested assurance where
  applicable;
- time, memory, output, filesystem, and network budgets;
- user cancellation token and project policy identity.

A broker result contains:

- terminal state: completed, partial, unsupported, rejected, cancelled, timed
  out, or failed;
- typed values and/or artifact references;
- executor-returned evidence and assurance classification;
- residuals, assumptions, bounds, warnings, and diagnostics;
- provider, adapter, backend, contract, schema, and build identity;
- input/output digests, timing, resource use, and replay information;
- the immutable receipt reference.

The renderer may format this envelope but may not promote its assurance, erase
its residuals, infer absent values, or replace it with model-generated output.

### 5.4 Provider isolation

Built-in verified engines may run in-process only when their memory-safety,
failure, and cancellation properties justify it. Native kernels, model runtimes,
research programs, user extensions, and third-party tools normally run in
supervised workers with narrowly granted filesystem and network access.

A worker crash fails its run, not the project or application. Restart and retry
are explicit events. A retry receives a new run ID and links to the failed
attempt; history is never rewritten to make the failure disappear.

## 6. Backend unification map

The existing system is integrated by adapter and contract, not by renaming all
source modules or merging all numerical implementations immediately.

| Existing family | CentL26 role | Integration rule |
| --- | --- | --- |
| CENTL OCaml/F*/native core | Exact mathematics, symbolic work, verification, and protocols | Remains authoritative for the contracts it owns; no UI reimplementation. |
| Rust web engine | Current exact/symbolic and numerical implementation used by the private host | Reconcile contract-by-contract with the authoritative core; duplicates require parity tests and an explicit owner. |
| CENTL Physics | Typed quantities, constants, particles, worlds, collision/contact, and physics protocols | Exposed through typed physics contracts and evidence-preserving adapters. |
| CENTL Chemistry | Exact-first amount, constants, data, thermo, limiting-reagent, and model work | Enabled only for operations whose public contracts and assurance are qualified. |
| CENTL-SCi / Caramels | Conservative scientific intent compilation and presentation metadata | Produces validated IR; never supplies scientific truth or bypasses an engine. |
| BUILD / MIRAGE | Capability discovery, project-local development, review, materialization, and extension lifecycle | Runs in an assurance-separated development workspace with explicit promotion. |
| Research kernels | Bounded searches, expeditions, certificates, and analysis | Each kernel declares finite scope, grade, determinism, and artifact contracts. |
| CARAVAN | Verified retrieval, preservation, catalog, and optional collaboration transport | Optional network capability; retrieved bytes do not gain scientific authority from transport. |
| CENTLAMP | Search/rank protocol and evidence | Added only through versioned ranking contracts and replayable profiles. |
| Wellsprings, Camps, release records | Knowledge, provenance, and governance objects | Imported and linked as records; not treated as executors. |
| Public site and Hub | Publication and transitional access surfaces | They do not become the desktop runtime or its design authority. |

Where two engines currently answer the same operation, CentL26 must not route
between them opportunistically. The capability manifest identifies the owner;
parity work runs as conformance testing or an explicitly requested comparison.

### 6.1 Current CentL26 implementation boundary

The shipping implementation is intentionally narrower than the target broker
described above. Its current, testable boundary is:

- one durable local `centl.project/1` project with one notebook, revisioned
  execution history, typed provider evidence, and atomic restart persistence;
- a runtime-overlay capability registry at `GET /api/capabilities` and a
  project/notebook read model at `GET /api/workspace`;
- built-in exact/symbolic mathematics, typed physics, and bounded
  Erdős–Straus execution, plus explicitly resolved `centl` rigorous-numerics
  and `centl-chem` chemistry providers;
- one authenticated compatibility mutation route, `POST /api/run`, whose
  admitted results are persisted before the refreshed workbench is returned;
- distinct Work, Projects, Tools, Data, Models, Research, and Build surfaces.
  Data objects, model/SCi execution, multi-project switching, and the
  BUILD/MIRAGE extension workbench report unavailable or planned status rather
  than presenting decorative controls as working product features.

`POST /api/run` is not yet the complete typed broker envelope from Section 5.
New capability families must not add more UI-only prefix routing; they should
enter through a versioned request/response adapter and then migrate this
compatibility route behind the same dispatcher.

## 7. Project object model

The CentL26 project format is year-neutral so projects survive annual product
names. Its root schema begins at `centl.project/1`; it is not called
`centl26.project`.

```text
Project
├── Manifest and project policy
├── Sources and documents
├── Experiments
│   ├── Notebooks
│   │   └── typed cells
│   ├── Workflows
│   └── run collections
├── Datasets and data views
├── Mathematical, physical, and chemical models
├── Programs, packages, and local extensions
├── Runs (immutable attempts)
├── Artifacts
├── Receipts and evidence graph
├── Environment lock and capability requirements
├── Publications and exports
└── Project history and migration journal
```

### 7.1 Common object header

Every durable object has:

- a stable project-scoped object ID;
- a type ID and schema version;
- a monotonic revision identity;
- content and attachment digests;
- created/modified provenance;
- parent, dependency, and derived-from edges where applicable;
- assurance and trust metadata where applicable;
- deletion/tombstone state rather than ambiguous disappearance;
- extension fields that preserve unknown compatible data.

Mutable authoring objects create revisions. Runs, receipts, and published
artifacts are immutable; corrections create linked successors.

### 7.2 Principal types

- **Project** — portable assurance, policy, naming, and storage boundary.
- **Source/document** — canonical code, structured text, report, protocol, or
  domain document.
- **Experiment** — a scientific question, method, assumptions, inputs, and
  related executions.
- **Notebook** — ordered narrative and executable cells; it is one project tool,
  not the product itself.
- **Cell** — typed source, note, protocol, dataset, visualization, or control
  unit with stable identity across edits.
- **Dataset** — typed data plus schema, units, provenance, import digest, and
  transformation lineage.
- **Model** — reusable mathematical, physical, chemical, search, or other domain
  representation.
- **Workflow** — explicit dependency graph of capability requests.
- **Run** — one immutable execution attempt against exact input revisions.
- **Artifact** — content-addressed plot, table, certificate, snapshot, report,
  binary, or exported result.
- **Receipt** — machine-readable claim about one execution and its evidence.
- **Evidence edge** — relation among input, executor, run, result, proof,
  enclosure, validation, or review records.
- **Extension/package** — user or third-party capability code with origin,
  permissions, tests, and assurance separated from the core.
- **Environment lock** — required capability contract ranges and the exact
  provider composition used for reproducibility.

### 7.3 Storage requirements

The canonical form is a directory project suitable for version control and
recovery. A portable archive may use `.centlproj`, but the internal schema and
content digests—not the filename extension—define identity. Large immutable
attachments live in a content-addressed store referenced by project objects.

Writes are atomic. Before schema migration, CentL26 creates a recoverable
snapshot and a migration journal. Cache, index, layout, hover, selection,
transient console, and task-progress state are replaceable application state and
must not be mistaken for authoritative project content.

## 8. Migration and compatibility

### 8.1 Legacy application surfaces

Existing commands such as `centl`, `centl-physics`, and `centl-sci` remain
supported automation and compatibility interfaces while their contracts are in
use. CentL26 invokes engines through libraries or machine protocols; it never
screen-scrapes their human terminal output.

`centl-lab` may become a transitional launcher alias for CentL26. `centl-web`
and `centl-hub` remain separate publication/compatibility surfaces until their
unique functions are either integrated or explicitly retired. None of these
legacy executable names is the CentL26 product version.

The current process-local Lab session format is not a durable project contract.
If a historical build has no persistent source, CentL26 cannot claim to recover
it. Any files or `.centllab` formats introduced during transition receive an
explicit importer and are converted into the year-neutral project schema.

### 8.2 Project opening rules

When opening a project, CentL26 must choose exactly one of these states:

1. **read/write compatible** — no migration required;
2. **migratable** — backup, preview, migration, validation, and journal succeed;
3. **read-only preserved** — content can be displayed/exported but safe writing
   is not possible;
4. **unsupported but intact** — the application explains what is missing and
   does not modify the project;
5. **damaged** — recovery tools operate on a copy and never conceal data loss.

Unknown object types and fields are preserved when safe. They are not discarded
merely because the installed product cannot render them. Downgrade never
silently rewrites a newer project.

### 8.3 Capability compatibility

Compatibility is negotiated from declared contract ranges, not inferred from
binary filenames or product versions. An adapter may bridge an older backend
only when conformance tests establish equivalent semantics. Incompatible
providers are disabled with an actionable diagnostic; the broker does not guess
at request translation.

A newer provider may replay an old run only if the user requests replay. The
original receipt continues to name the original executor and remains immutable.
Recomputed results are linked comparisons, not replacements.

### 8.4 Release composition

Every product artifact contains a signed release manifest that pins:

- product and source snapshot;
- project/broker/receipt schema ranges;
- built-in capability contracts and maturity;
- adapters, backends, models, catalogs, and their digests;
- optional components and platform constraints;
- licenses, SBOM, signing identity, and reproducible-build evidence.

The historical Oasis SemVer line remains valid as backend and source history.
A stable CentL26 release is still promoted from an exact Oasis-qualified
snapshot; **Oasis remains the quality declaration and CentL26 becomes the
product identity**. Release policy and automation must be updated together
before the first final CentL26 tag so neither tag family is ambiguously called
the main product version.

## 9. Release gates

Presence in the repository or capability registry is not release qualification.
Each CentL26 release must pass the following gates on its exact signed
composition.

### 9.1 Product and experience

- installs, launches, updates, opens files, and uninstalls as a desktop
  application without a general-purpose browser;
- completes first-run and primary project workflows with networking disabled;
- has no whole-application scroll at the declared laptop minimum viewport;
- preserves central workspace priority when side and bottom panes are open;
- supports keyboard-only command discovery, focus traversal, execution,
  cancellation, document switching, and panel control;
- satisfies declared accessibility targets for contrast, scaling, semantics,
  motion, screen readers, and reduced-motion operation;
- restores a useful window after restart or renderer/worker failure;
- meets explicit cold-start, warm-start, interaction, memory, and large-project
  budgets for every supported platform.

### 9.2 Scientific correctness and assurance

- authoritative engines pass their existing deterministic, protocol,
  verification, and domain suites;
- adapters pass contract conformance and negative/refusal tests;
- duplicate implementations pass parity tests for their shared declared domain;
- unsupported, ambiguous, unbounded, and unjustified work remains visible;
- assurance labels, assumptions, units, bounds, residuals, and provenance
  survive execution, rendering, copy, export, save, reopen, and replay;
- semantic-model output cannot bypass IR validation or become scientific
  authority;
- advertised capability status matches the signed manifest.

### 9.3 Project integrity and compatibility

- atomic-write, crash-interruption, recovery, and content-digest tests pass;
- migration fixtures cover every supported historical project schema;
- migrations create and validate backups and do not lose unknown preserved data;
- a supported previous release can open unchanged compatible projects;
- immutable runs and receipts cannot be mutated through normal APIs;
- export/import and archive round trips preserve authoritative content.

### 9.4 Security and privacy

- native shell, broker, project parser, protocol adapters, worker supervisor,
  extension runtime, updater, and optional network services are threat-modeled;
- project paths, archives, HTML/rendered output, IPC, loopback transport, and
  capability inputs pass adversarial tests;
- workers receive least privilege and explicit resource limits;
- local-only operation performs no analytics, remote font, CDN, update, model,
  or telemetry request without an explicit policy and user action;
- dependencies, models, catalogs, and update artifacts are digest-checked and
  provenance-recorded;
- security response, signing, rollback, and compromised-update procedures are
  documented and exercised.

### 9.5 Packaging, reproducibility, and governance

- platform-native packages are signed/notarized where applicable and verified
  on clean supported systems;
- the release artifact is reproducible or any remaining variance is documented
  and independently attributable;
- SBOM, third-party notices, source obligations, model/data licenses, checksums,
  and release manifest ship with the product;
- FCF identity and trademark use are correct without obscuring upstream
  provenance;
- release notes distinguish stable, preview, experimental, unavailable, and
  removed capabilities;
- the exact snapshot passes the complete Oasis qualification gate.

Release gates use platform-specific, measurable budgets fixed before release
candidate testing. Targets are not weakened after results are observed merely
to admit the candidate.

## 10. Phased backend unification

The product can become comprehensive without attempting a hazardous single-step
rewrite.

### Phase 0 — inventory and contract freeze

- enumerate every shipped executable, protocol, engine, schema, research kernel,
  data catalog, and assurance class;
- identify duplicated semantics and name the current authority for each
  operation;
- assign stable capability IDs and initial contract versions;
- publish the first release-composition and compatibility matrices.

**Exit:** every product-visible operation has an owner, contract, maturity, and
evidence story, or is explicitly excluded.

### Phase 1 — CentL26 shell and broker boundary

- package the existing private Lab renderer in an owned desktop window;
- replace CENTL Lab branding with CentL26 and establish the restrained,
  viewport-bound work surface;
- introduce application controller, capability registry, broker envelopes, and
  worker supervision;
- route the already implemented mathematics, symbolic, physics, and
  Erdős–Straus slices through adapters.

**Exit:** the app runs without a user browser, direct UI-to-engine paths are
removed, and every execution has a broker receipt.

### Phase 2 — durable project foundation

- implement `centl.project/1`, atomic persistence, revisions, recovery, artifact
  storage, environment locks, and migration tooling;
- make notebooks, datasets, models, runs, receipts, and artifacts real project
  objects rather than illustrative UI;
- add project search, command routing, and local layout persistence.

**Exit:** complete projects survive crashes, upgrades, export/import, and
offline reopening without evidence loss.

### Phase 3 — authoritative scientific convergence

- reconcile Rust and OCaml/F*/native mathematical ownership contract by
  contract;
- integrate full exact mathematics, rigorous numerics, verification, and typed
  physics protocols;
- bind visualizations to artifact specifications that retain exactness,
  enclosures, units, and source revisions;
- qualify chemistry operations individually as their contracts mature.

**Exit:** primary mathematics and physics work no longer depends on duplicated
UI semantics, and qualified chemistry appears only where honest.

### Phase 4 — scientific interaction and research

- expose SCi as a conservative intent-to-IR capability with resident optional
  model workers;
- make clarification, assumptions, interpreter path, and authoritative executor
  inspectable;
- integrate bounded research kernels as expedition/run objects with grades,
  checkpoints, certificates, and comparison tools;
- add domain-specific editors only when their object and capability contracts
  are durable.

**Exit:** natural language and research workflows create reproducible project
objects without weakening scientific authority.

### Phase 5 — BUILD, MIRAGE, and extension workbench

- integrate discovery, planning, code, tests, review, evidence, snapshots, and
  materialization as project workflows;
- isolate generated, external, and user-local code in supervised workers;
- make permissions, provenance, test evidence, and assurance transitions
  explicit;
- provide a documented capability SDK using the same broker contracts.

**Exit:** users can extend CentL26 from inside the application while the verified
core boundary remains intact.

### Phase 6 — preservation, retrieval, and optional collaboration

- expose CARAVAN retrieval/preservation through explicit local and network
  policies;
- add signed catalog, content-addressed exchange, publication, and recovery
  workflows;
- integrate ranking/search protocols only after their policies and replay
  evidence are versioned;
- keep remote execution, synchronization, and telemetry off by default unless a
  separately approved product policy changes that boundary.

**Exit:** movement and preservation of projects are verifiable and do not confer
scientific authority on transported content.

### Phase 7 — compatibility retirement

- measure real use and parity before deprecating any legacy frontend;
- retain CLI and machine protocols needed for automation;
- ship importers before removing old project/file writers;
- archive historical branding and release mappings;
- remove a duplicate engine path only after contract ownership, replay, and
  migration evidence are complete.

**Exit:** CentL26 is the clear main product without destroying useful automation,
reproducibility, or access to historical work.

## 11. Architectural decisions that do not drift

The following are release-line invariants:

- The application is **CentL26**; backend versions are not product versions.
- The desktop application is not the public website in a browser.
- The broker routes scientific meaning but does not invent it.
- Projects and capability contracts are year-neutral and versioned
  independently.
- A result's assurance is component-local and evidence-backed.
- Models interpret; authoritative engines compute and verify.
- Unsupported work remains unsupported.
- Runs and receipts are immutable.
- Experimental capability can be present without being promoted.
- FCF identity is visible, while upstream and backend provenance remains
  inspectable.
- Comprehensiveness is achieved through coherent capabilities and progressive
  disclosure, not by placing every control on the first screen.

This architecture makes the annual product line simple for people while keeping
the underlying scientific system precise: **one CentL26 application, one project
model, one capability boundary, and many independently versioned engines whose
claims remain auditable.**
