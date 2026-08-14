# CENTL-MIRAGE: Full Demonstration Guide

**A practical demonstration of local, evidence-gated self-development in CENTL**

> Good maths should be free.

CENTL-MIRAGE is the development architecture for allowing CENTL to inspect, extend, test, and reason about changes to its own downstream computational environment without pretending that generated code is automatically trustworthy.

This guide walks through a complete MIRAGE demonstration using the current `mirage` development branch. It is intended for users, developers, researchers, and reviewers who want to see what MIRAGE can actually do today.

The demonstration shows a full progression from ordinary human requirements to structured machine-readable development state:

```text
human design document
        |
        v
provenance-preserving Specification IR
        |
        v
goal and capability analysis
        |
        v
evidence obligations
        |
        v
candidate transactions
        |
        v
candidate materialization
        |
        v
readiness and execution planning
        |
        v
evidence receipts
        |
        v
candidate admission assessment
```

It then demonstrates the existing controlled CENTL-SCi downstream extension machinery, workspace revision history, assurance inspection, auditing, rollback, and contradiction handling.

The important idea is not merely that CENTL can generate code.

The important idea is that CENTL can generate a proposed change **while preserving the distinction between a proposal, a tested local extension, and verified core**.

---

## Current status

MIRAGE is an active development architecture, not the stable CENTL product branch.

The ordinary branch roles are:

- `oasis` — qualified stable product and release branch;
- `mirage` — development, research, experimentation, and self-development branch;
- `main` — comprehensive developer and research distribution.

At the time of this document, the rolling Mirage binary channel has not yet been successfully published. Selecting Mirage through the ordinary installer may therefore still return an HTTP 404 while the rolling distribution pipeline is being completed.

For this demonstration, use a local source checkout of the `mirage` branch.

This is also useful because it ensures the demonstration is running the newest MIRAGE development code rather than an older packaged build.

---

# 1. Prepare the MIRAGE development build

From an existing CENTL repository checkout:

```sh
git fetch origin
git switch mirage
git pull --ff-only origin mirage
```

Load the CENTL opam environment:

```sh
eval "$(opam env --switch=centl)"
```

Build the native development tree:

```sh
make native-build
```

The MIRAGE executable produced by the development build is:

```text
_build/default/src/mirage_main.exe
```

The normal CENTL-SCi development executable is:

```text
_build/default/src/sci_main.exe
```

MIRAGE is also defined as the public executable `centl-mirage` when installed through the normal Dune packaging path.

---

# 2. Create an isolated MIRAGE laboratory

A self-development demonstration should not modify an ordinary user workspace accidentally.

Create a new isolated CENTL workspace:

```sh
export CENTL_WORKSPACE="$HOME/.centl/workspaces/mirage-showcase-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$CENTL_WORKSPACE"
```

Create a temporary directory for the source documents used by the demonstration:

```sh
DEMO_DIR="$(mktemp -d)"
```

Display the paths for reference:

```sh
echo "MIRAGE workspace: $CENTL_WORKSPACE"
echo "Demo files:       $DEMO_DIR"
```

The CENTL workspace is deliberately user-owned downstream state. MIRAGE does not need to edit the checked-out upstream repository merely to analyze or stage a local extension.

---

# 3. Give MIRAGE a human-readable scientific design

The centerpiece of the demonstration is a design document written in ordinary language.

Create the following file:

```sh
SPEC="$DEMO_DIR/orbital-laboratory.md"

cat > "$SPEC" <<'EOF'
# Orbital Laboratory

Build a small exact-computation orbital mechanics extension for CENTL.

Create a function named kinetic_energy that takes mass and velocity and computes 1/2 * mass * velocity^2

Acceptance: kinetic_energy(2, 3) should return 9.

Acceptance: rational inputs should remain exact rather than being silently rounded to floating-point approximations.

Example: kinetic_energy(4, 5) = 50.

Create a function named specific_orbital_energy that takes mu and radius and velocity and computes 1/2 * velocity^2 - mu/radius

Acceptance: the orbital-energy calculation should preserve exact CENTL arithmetic whenever all supplied quantities are exact.

Example: specific_orbital_energy(10, 5, 2) = 0.

Non-goal: Do not modify verified CENTL core.

Non-goal: Do not require a network service or paid AI API.
EOF
```

Inspect the document:

```sh
cat "$SPEC"
```

Notice what has **not** been supplied.

The user did not write OCaml.

The user did not write a CENTL module.

The user did not write JSON development metadata.

The user supplied requirements, examples, acceptance criteria, and non-goals.

That distinction matters.

---

# 4. Start the MIRAGE development cycle

Run the complete MIRAGE pipeline:

```sh
_build/default/src/mirage_main.exe start "$SPEC" | tee "$DEMO_DIR/mirage-full-run.txt"
```

This is the central demonstration command.

`centl-mirage start` performs the current MIRAGE development pipeline in sequence.

The output should contain sections similar to:

```text
CENTL-MIRAGE cycle initiated.
Goal graph:
Evidence obligations:
Candidate transactions:
Candidate materialization:
Candidate evidence readiness:
Candidate evidence execution plan:
Candidate evidence receipts:
Candidate admission assessment:
```

The exact counts and paths may vary with the current development tree and workspace contents.

## What MIRAGE does during this command

### 4.1 Ingest the source document

MIRAGE copies the original source into the local structure library and computes a SHA-256 content identifier.

The original user document remains authoritative.

MIRAGE does not silently replace it with an inferred summary.

### 4.2 Build Specification IR

The document is decomposed into attributable specification cells.

Current cell categories include:

```text
DIRECTIVE
INVARIANT
ACCEPTANCE
EXAMPLE
NON_GOAL
QUESTION
CONTEXT
```

Each cell retains information such as:

```text
cell ID
cell kind
source document
start line
end line
verbatim source text
```

This creates a provenance-preserving intermediate representation rather than flattening the user's document into one opaque prompt.

### 4.3 Build a goal and capability graph

MIRAGE then maps the source document into explicit development concepts such as:

- requirements;
- hard invariants;
- acceptance criteria;
- examples;
- non-goals;
- open questions;
- known CENTL capabilities;
- capability gaps.

A requirement can currently be classified with states such as:

```text
SATISFIED
COMPOSABLE
ALIAS_OR_WRAPPER
EXTENSION_REQUIRED
CORE_CHANGE_REQUIRED
AMBIGUOUS
CONFLICTING
UNSUPPORTED_BY_POLICY
```

Before generating anything new, MIRAGE attempts to determine whether existing CENTL functionality can be reused or composed.

### 4.4 Construct evidence obligations

A candidate change is not treated as acceptable merely because it was generated successfully.

MIRAGE constructs evidence obligations associated with the originating requirement and candidate transaction.

These obligations form part of the evidence-gating model required before a future autonomous activation system can safely accept changes.

### 4.5 Construct candidate transactions

MIRAGE creates candidate transactions representing the smallest development strategies it believes are appropriate for the requirement.

Current candidate strategies include concepts such as:

```text
compose_existing
alias_or_wrapper
downstream_extension
isolated_core_patch
```

Candidate transactions are given deterministic SHA-256 fingerprints derived from their structural identity and source requirement.

A transaction fingerprint is **not** mathematical proof and is not presented as one.

It is an identity binding between a proposed transaction and the requirement that caused it.

### 4.6 Materialize deterministic candidate source where possible

For requirements that the current deterministic CENTL-SCi generator understands, MIRAGE can create native CENTL source.

For example, this sentence:

```text
Create a function named kinetic_energy that takes mass and velocity and computes 1/2 * mass * velocity^2
```

can be lowered into a structured native CENTL definition request.

The generated source is passed through the authoritative CENTL parser.

Parser acceptance proves that the generated source is syntactically valid CENTL.

Parser acceptance does **not** prove:

- mathematical correctness;
- behavioral equivalence;
- regression safety;
- verified-core status;
- production readiness.

MIRAGE records that distinction explicitly.

### 4.7 Assess readiness

MIRAGE records which evidence is available, which evidence can currently be executed, and which required checks remain pending or blocked.

This prevents the engine from collapsing every development state into a misleading binary `passed` value.

### 4.8 Build an execution plan

MIRAGE constructs an evidence execution plan from the candidate and readiness state.

The plan binds evidence actions to specific candidate transactions and obligations.

### 4.9 Execute supported evidence actions

The current evidence machinery can execute supported local actions such as creation of reversible pre-activation workspace snapshots.

Unimplemented validators remain explicitly `pending`.

Unsupported actions remain explicitly `blocked`.

MIRAGE does not fabricate a successful receipt for an action it did not actually perform.

### 4.10 Assess candidate admission

Finally, MIRAGE assesses whether the exact candidate/evidence combination is admissible under the currently implemented rules.

The current engine deliberately stops before arbitrary candidate activation.

The demonstration should make this boundary visible:

```text
candidate source activated: no
assurance promoted: no
```

This is a safety property, not a cosmetic limitation.

MIRAGE currently knows how to analyze and stage substantially more than it is willing to activate automatically.

---

# 5. Inspect the generated MIRAGE state

MIRAGE creates durable local development artifacts rather than keeping the entire process inside transient conversational state.

Show the active cycle:

```sh
_build/default/src/mirage_main.exe status
```

Then list the files in the isolated workspace:

```sh
find "$CENTL_WORKSPACE" -type f -printf '%P\n' | sort
```

You should see a combination of workspace metadata, structure-library material, revision data, and generated MIRAGE development artifacts.

The exact generated filenames are content-addressed and may differ between source documents.

## Inspect the human-readable development plan

```sh
echo
echo "===== MIRAGE DEVELOPMENT PLAN ====="
cat "$CENTL_WORKSPACE"/generated/mirage/*.plan.md
```

The plan retains the originating source cell IDs and explains the proposed implementation layer, reusable capabilities, development steps, trust notes, and unresolved work.

## Inspect the machine-readable artifacts

```sh
for f in "$CENTL_WORKSPACE"/generated/mirage/*.json; do
    echo
    echo "================================================================"
    echo "$(basename "$f")"
    echo "================================================================"
    python3 -m json.tool "$f"
done
```

Depending on the current MIRAGE version, the generated state can include information such as:

```text
source SHA-256
source spans
specification cells
goal graph nodes
goal graph edges
capability matches
capability gaps
conflicts
evidence obligations
candidate transactions
transaction fingerprints
materialized source
source SHA-256 fingerprints
parser-validation state
readiness state
execution plans
evidence receipts
admission assessments
workspace revision
```

This is one of the most important parts of the demonstration.

The output is not merely "AI conversation history."

It is structured development state that can be inspected independently.

---

# 6. Inspect candidate materialization

To focus specifically on generated source:

```sh
python3 -m json.tool "$CENTL_WORKSPACE"/generated/mirage/*.materialization.json
```

For supported deterministic requests, inspect fields such as:

```text
candidate_id
transaction_fingerprint
strategy
state
source
source_sha256
parser_validated
rationale
materialization_fingerprint
```

A successful materialization may show:

```text
state: materialized_source
parser_validated: true
```

This means MIRAGE successfully generated a syntactically valid CENTL candidate.

It still does not mean the candidate is verified core.

That separation is intentional.

---

# 7. Demonstrate controlled downstream growth with CENTL-SCi BUILD

MIRAGE currently performs conservative candidate staging and analysis.

The existing CENTL-SCi Caramels BUILD surface provides the controlled downstream extension mechanism used to actually add local user-owned definitions.

Create the kinetic-energy function:

```sh
_build/default/src/sci_main.exe --mode build \
'create a function named kinetic_energy that takes mass and velocity and computes 1/2 * mass * velocity^2'
```

Create the specific-orbital-energy function:

```sh
_build/default/src/sci_main.exe --mode build \
'create a function named specific_orbital_energy that takes mu and radius and velocity and computes 1/2 * velocity^2 - mu/radius'
```

These are downstream workspace extensions.

They are not silent edits to verified CENTL core.

---

# 8. Inspect the newly extended system

Show the active extensions:

```sh
_build/default/src/sci_main.exe --mode build 'show extensions'
```

Validate the first extension:

```sh
_build/default/src/sci_main.exe --mode build 'validate kinetic_energy'
```

Validate the second extension:

```sh
_build/default/src/sci_main.exe --mode build 'validate specific_orbital_energy'
```

Now inspect assurance explicitly:

```sh
_build/default/src/sci_main.exe --mode build \
'explain assurance kinetic_energy'
```

And:

```sh
_build/default/src/sci_main.exe --mode build \
'explain assurance specific_orbital_energy'
```

CENTL-SCi deliberately distinguishes assurance categories instead of assigning every extension one vague trust score.

Current categories include:

```text
verified_extension
validated_native_extension
locally_tested_extension
external_backend
experimental_local_extension
unverified_generated_extension
```

The assurance report should explain both what a category establishes and what it does **not** establish.

Generated or locally tested code does not silently become verified CENTL core.

---

# 9. Audit the downstream system

After extending CENTL, ask it to inspect its own local workspace.

```sh
_build/default/src/sci_main.exe --mode build 'audit workspace'
```

Inspect revision history:

```sh
_build/default/src/sci_main.exe --mode build 'revisions'
```

Inspect available capabilities:

```sh
_build/default/src/sci_main.exe --mode build 'capabilities'
```

This portion of the demonstration shows that local extension is not merely source generation.

The system also maintains:

- workspace metadata;
- extension manifests;
- revision state;
- capability discovery;
- assurance metadata;
- structural audit information.

The intended model is a computational workspace that can grow while retaining an inspectable account of how it grew.

---

# 10. Demonstrate reversibility

A self-changing system must have a credible way to recover from its own changes.

Use BUILD's reversible downstream history:

```sh
_build/default/src/sci_main.exe --mode build 'undo'
```

Then inspect the state again:

```sh
_build/default/src/sci_main.exe --mode build 'show extensions'
```

```sh
_build/default/src/sci_main.exe --mode build 'revisions'
```

```sh
_build/default/src/sci_main.exe --mode build 'audit workspace'
```

MIRAGE's evidence subsystem also treats rollback availability as an explicit evidence concept and can create pre-activation workspace snapshots for supported candidate cycles.

The principle is simple:

> Growth must be reversible before it can safely become autonomous.

---

# 11. Demonstrate refusal instead of blind compliance

A convincing self-development system should not only succeed when given easy, consistent instructions.

It should also recognize when the specification itself is unsafe or contradictory.

Create a deliberately contradictory specification:

```sh
BAD_SPEC="$DEMO_DIR/contradictory-design.md"

cat > "$BAD_SPEC" <<'EOF'
# Contradictory Design

CENTL must use remote model execution for this capability.

CENTL must not use remote model execution for this capability.

Acceptance: implementation must satisfy every hard requirement.
EOF
```

Use a fresh isolated workspace:

```sh
export CENTL_WORKSPACE="$HOME/.centl/workspaces/mirage-refusal-$(date +%Y%m%d-%H%M%S)"
```

Run MIRAGE:

```sh
_build/default/src/mirage_main.exe start "$BAD_SPEC"
```

MIRAGE performs conservative conflict detection over hard requirements.

Requirements with opposite polarity and sufficiently overlapping semantic content can be marked:

```text
CONFLICTING
```

Blocked source cells are not silently overridden later by candidate generation, evidence execution, or admission assessment.

This is a critical part of the architecture.

A system that can modify itself must be able to say:

```text
I cannot safely satisfy this specification as written.
```

rather than inventing a convenient interpretation and proceeding.

---

# 12. What this demonstration proves

The current MIRAGE implementation demonstrates several important architectural properties.

## Provenance

The original source document remains preserved and attributable.

Generated requirements and development artifacts retain references to their originating specification cells.

## Local operation

The initial MIRAGE development cycle does not require a paid AI API or remote model service.

The deterministic ingestion, classification, planning, candidate, and evidence machinery can operate locally.

## Capability introspection

MIRAGE checks existing CENTL and downstream capabilities before assuming that new code must be written.

## Conservative synthesis

Where a requirement can be deterministically lowered into native CENTL source, MIRAGE can stage that source and require parser acceptance.

Where the requirement cannot be lowered without guessing, the engine can leave it blocked or pending instead of fabricating an implementation.

## Evidence separation

MIRAGE distinguishes:

- parser acceptance;
- evidence readiness;
- executed evidence;
- pending evidence;
- blocked evidence;
- candidate admission;
- activation;
- assurance promotion.

These are not treated as synonyms.

## Reversibility

Downstream workspace mutation is revisioned and reversible.

MIRAGE evidence execution can also produce explicit pre-activation snapshots where supported.

## Honest assurance

Generated code does not inherit verified-core assurance merely because CENTL generated it.

## Conflict detection

Contradictory source requirements can block development rather than being silently resolved by arbitrary preference.

## No automatic publication authority

Local self-development does not imply permission to push source upstream, publish releases, or alter the official Oasis product.

Publication remains a separate user-authorized action.

---

# 13. What MIRAGE does not yet claim

The current demonstration should be presented accurately.

MIRAGE is not yet a finished unrestricted autonomous recursive programmer.

The current pipeline reaches deep into the self-development lifecycle, including:

```text
ingestion
specification IR
goal/capability analysis
evidence obligations
candidate transactions
candidate materialization
readiness
execution planning
some evidence execution
admission assessment
```

However, arbitrary candidate source is **not automatically activated** by the current `centl-mirage start` pipeline.

The engine deliberately records:

```text
candidate_source_activated: false
assurance_promoted: false
```

Future MIRAGE work is intended to continue the recursive cycle toward controlled candidate activation, evidence-driven acceptance, semantic regression checking, stronger synthesis mechanisms, and repeated goal-gap reduction.

Until those stages are implemented and tested, they should not be presented as completed functionality.

---

# 14. The MIRAGE design principle

The larger idea behind MIRAGE can be summarized in a few lines:

```text
It can propose.

It can construct.

It can inspect itself.

It can stage change.

It can gather evidence.

It can preserve provenance.

It can create rollback state.

It can reject contradiction.

But it cannot simply declare itself correct.
```

That final rule is central to CENTL.

CENTL already follows the principle that a numerical system should not print an unjustified digit.

MIRAGE extends the same philosophy to software development:

> A self-developing computational system should not claim an unjustified implementation confidence.

The goal is not uncontrolled self-modification.

The goal is **locally owned, inspectable, reversible, evidence-gated computational growth**.

---

# 15. Suggested demonstration sequence

For a live presentation or screen recording, the strongest sequence is:

1. show the human-readable orbital design document;
2. run `centl-mirage start`;
3. point out Specification IR and source SHA-256;
4. show the goal/capability graph;
5. show the candidate transaction;
6. show generated CENTL source and parser validation;
7. show evidence receipts and admission state;
8. emphasize that the candidate remains inactive and unpromoted;
9. use CENTL-SCi BUILD to add the downstream extension explicitly;
10. validate the extension and inspect its assurance;
11. show workspace audit and revision history;
12. undo the change;
13. run the contradictory specification and show MIRAGE refusing to proceed blindly.

That sequence demonstrates both **capability** and **restraint**.

Both are necessary for credible self-development.

---

# Related documentation

- [CENTL-MIRAGE architecture](CENTL-MIRAGE.md)
- [CENTL-SCi Caramels BUILD mode](CARAMELS-BUILD.md)
- [CENTL-SCi](SCI.md)
- [CENTL architecture](DESIGN.md)
- [CENTL verification](VERIFICATION.md)
- [CENTL release policy](RELEASE-POLICY.md)
- [CENTL installation](INSTALL.md)

---

Developed under the **Free Computation Foundation**.

> Free for science.
