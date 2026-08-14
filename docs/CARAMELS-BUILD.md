# CENTL-SCi v0.0.2-Caramels — BUILD mode

Status: development-branch reference for the Caramels downstream self-extension surface.

> Free for science.

`BUILD>` is the user-owned system-extension mode of CENTL-SCi. It is not a shell and it does not grant generated code the assurance of verified CENTL core.

The design rule is:

```text
understand the requested change
  -> reuse an existing capability when possible
  -> choose the smallest justified extension layer
  -> validate before activation
  -> preserve provenance and assurance
  -> snapshot reversible downstream state before mutation
```

## Status and discovery

```text
BUILD> status
BUILD> catalog
BUILD> products
BUILD> capabilities
BUILD> show capability gcd
BUILD> extend add a local helper for my lab protocol
BUILD> audit workspace
BUILD> revisions
```

In the live REPL, `:workbook PATH` exports the current session as a replayable
CENTL script. `:catalog` and `:products` expose the same discovery surfaces.
`centl-mirage doctor` reports structural MIRAGE cycle health; it is not Oasis
qualification.

`status` reports the Caramels version, platform family, workspace/revision, structural workspace health, enabled native extensions, package count, and deliberately gated integration work.

`capabilities` searches both built-in CENTL/CENTL Physics capabilities and downstream extensions/packages. Local packages are reported as compositions only; package membership never creates a new package-level assurance claim.

`audit workspace` is a read-only structural consistency check. Its health field is either `healthy` or `attention_required`. This is **not a trust score** and does not promote downstream code.

`revisions` / `show revisions` / `workspace history` expose a bounded view of the durable downstream revision ledger. At most the newest 100 parsed revision events are shown.

## Assurance inspection

```text
BUILD> assurance levels
BUILD> assurance my_extension
BUILD> explain assurance my_extension
```

Caramels distinguishes evidence/trust categories rather than assigning a single numeric assurance score. Current labels include:

- `verified_extension`
- `validated_native_extension`
- `locally_tested_extension`
- `external_backend`
- `experimental_local_extension`
- `unverified_generated_extension`

Every explanation states both what the category establishes and what it does **not** establish. In particular, locally tested/generated/external code does not silently become verified CENTL core.

Unknown or legacy assurance labels are preserved as provenance, but Caramels does not infer additional guarantees from an unknown label.

## Native CENTL definitions

Direct definitions:

```text
BUILD> create value tau = 2*pi
BUILD> create function square(x) = x^2
BUILD> modify function square(x) = x*x
```

English-to-CENTL construction:

```text
BUILD> create a value named tau equal to 2*pi
BUILD> create a function named kinetic_energy that takes mass and velocity and computes 1/2 * mass * velocity^2
BUILD> make a kinetic energy function
BUILD> let square(x) = x^2
BUILD> teach yourself harmonic mean
```

English, `let`, topic names, and `teach yourself` share the same parser-validated workshop. A successful native program is hot-loaded and usually receives a spoken alias, so `square of 6` works in the same session. No restart is required for native CENTL programs.

`patch your source` / compiled-host requests write a reviewable proposal under `generated/host-patches/`. Those cannot hot-load. SCi says so: rebuild with `dune build`, then restart `centl-sci`.

```text
BUILD> programs
BUILD> spoken
BUILD> dialect
BUILD> journal
BUILD> export dialect
BUILD> host patches
```

`dialect` is the replayable local language. `journal` is the inspectable growth log. `export dialect` writes those artifacts without touching verified core.

## Reviewed GitHub publish

```text
BUILD> publish status
BUILD> pack contribution
BUILD> grant contributor publish
BUILD> stage contribution
BUILD> grant owner publish I accept local git and gh without storing tokens
BUILD> commit contribution
BUILD> open draft pull request
```

`push this to github` prints the required sequence. It does not push. Other contributors can pack and open a draft PR by hand; their work still needs approval. oasis is never the automatic base. Tokens are never stored.

The English path produces a structured change request before native source generation. Generated native source is parsed by the existing CENTL parser before it can be written into the local workspace.

An enabled native extension participates in the downstream persistent CENTL session. Re-enabling a native extension now performs a source preflight: the source must exist, parse, and be a value/function definition before the manifest can become enabled.

A failed enable preflight does not advance the workspace revision. Disabling remains possible even when the local source is invalid so the user can recover from a broken extension.

## Extension lifecycle

```text
BUILD> show extensions
BUILD> inspect my_extension
BUILD> validate my_extension
BUILD> disable my_extension
BUILD> enable my_extension
BUILD> remove my_extension
BUILD> undo
```

Mutating operations snapshot downstream state first. Removal archives local state instead of pretending it never existed.

Generated non-native scaffolds cannot be routed through the native CENTL definition loader. Attempting to enable a Python/native scaffold through that loader is explicitly rejected until its declared runtime boundary is implemented and validated.

## Packages

```text
BUILD> create package science
BUILD> list packages
BUILD> show package science
BUILD> add extension tau to package science
BUILD> validate package science
```

Packages group downstream extensions. Validation reports each member's:

- presence/missing state
- enabled/disabled state
- kind
- individual assurance

Package composition does not promote or replace member assurance.

## External/native scaffolds

```text
BUILD> scaffold python adapter telescope_reader astropy
BUILD> scaffold native extension sparse_backend sparse-matrix-solver
```

Generated scaffolds are intentionally inactive. Their contracts preserve an explicit external/native boundary and do not claim verified-core status.

## Deeper core changes

A request classified as a CENTL core modification creates a persistent downstream plan instead of silently editing trusted core source.

The plan records:

- the requested change
- reusable capabilities found first
- proposed implementation steps
- trust/assurance notes
- unresolved engineering work

The generated plan artifact is local. It is not a commit, push, pull request, or upstream publication.

## Upstream preparation

```text
BUILD> prepare upstream contribution
```

This prepares a local review artifact for selected downstream work. Publication remains an explicit user decision.

## Portability

Safe export is live:

```text
BUILD> export workspace
BUILD> export workspace /path/to/bundle
```

Validated reversible import is also live:

```text
BUILD> import workspace /path/to/bundle
```

A Caramels bundle contains downstream manifests, native modules, packages, tests, data, and generated scaffolds. It excludes verified core, history, snapshots, prior exports, and local workspace identity/configuration.

Bundle validation rejects malformed metadata, symlinks, unsupported filesystem objects, absolute or traversal-style manifest sources, invalid extensions, enabled non-native kinds, invalid dependency graphs, disabled required local dependencies, and packages that reference missing extensions.

Import/export scanning is bounded to 10,000 files, 16 MiB per file, 256 MiB aggregate payload, and 64 directory levels. Export preflights the included workspace surfaces before creating the target. Export target ancestry is normalized so traversal and symlink-parent aliases cannot redirect an export into active workspace state.

`BUILD> import workspace PATH` validates the bundle before mutation, snapshots the current downstream state, replaces only downstream surfaces, advances the workspace revision, and reloads enabled native definitions into the active core session in the same REPL operation. A post-validation copy failure triggers automatic snapshot rollback; a rollback failure is reported explicitly rather than hidden.

Read-only bundle inspection and import planning expose inventory and add/remove/replace/unchanged changes without mutating the workspace or promoting assurance.

## Current Caramels boundary

The following remain deliberately separate from the completed Caramels BUILD surface:

- stable executable ABI/activation for generated external/native scaffolds
- automatic trusted-core patch application
- automatic upstream publication
- support, packaging, installer, CI, and release validation for operating systems other than GNU/Linux

Caramels is Linux-first and Linux-supported. Local ownership and extension freedom do not change the core assurance rule: **user code may grow CENTL without silently redefining what verified core means.**
