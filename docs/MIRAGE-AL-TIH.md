# CENTL MIRAGE: Al-Tih

**Arabic:** التيه (`al-Tih`)
**Status:** active development epoch
**Branch:** `mirage`
**Oasis target:** intentionally unscheduled
**Purpose:** sustained experimental development before the next Oasis qualification

> **Do not seek the Oasis yet. Enter the desert deliberately.**

## 1. Declaration

CENTL MIRAGE has entered **Al-Tih**: a deliberate period of wandering, experimentation, self-examination, failure, discovery, and hardening before CENTL seeks another Oasis.

The name refers to wilderness and wandering in the desert. It is used here with respect for its Arabic and historical resonance, not as ornamental pseudo-Arabic. The engineering metaphor is precise: MIRAGE is the place where CENTL may leave the marked road, explore difficult ideas, discover dead ends, and return carrying evidence rather than certainty.

Al-Tih is not a release. It is not a version number. It is not an Oasis candidate.

There is **no scheduled next Oasis**.

The next Oasis will be attempted only when the work produced in MIRAGE has become excellent enough to justify the cost of qualification.

Until then, stayable laboratory work occupies an [FCF Camp](FCF-CAMPS.md)
rather than inventing a release. A Camp is not an Oasis.

The governing rule is:

> **Oasis is not scheduled. Oasis is earned.**

## 2. Why Al-Tih exists

Oasis exists to represent a qualified, stable CENTL product. MIRAGE exists for the opposite phase of engineering: experimentation, research, architectural change, self-development, aggressive testing, and ideas whose value has not yet been established.

Attempting Oasis qualification too frequently would force experimental work to imitate product work before the experiments have matured. Al-Tih deliberately removes that pressure.

During this epoch:

- MIRAGE may change substantially;
- experimental interfaces may be replaced;
- unsuccessful approaches are acceptable when their failure teaches us something;
- research code need not satisfy every Oasis gate while it remains isolated from Oasis authority;
- correctness claims still require evidence;
- experiments must remain attributable and reproducible where reasonably possible;
- no experimental capability silently inherits Oasis or verified-core assurance;
- `oasis` remains protected from MIRAGE experimentation.

The goal is not instability for its own sake. The goal is to make room for difficult work whose eventual result is substantially better than a sequence of hurried releases.

## 3. Al-Tih objective

By the end of Al-Tih, CENTL should have demonstrated not merely that it can acquire more features, but that it possesses a disciplined architecture for **understanding, testing, extending, attacking, explaining, and improving itself**.

The desired transition is:

```text
CENTL that can be developed
        ->
CENTL that can participate rigorously in its own development
```

This does not mean giving an AI model authority over the repository. MIRAGE must make self-development more accountable than ordinary ad-hoc code generation, not less.

A model may propose. A verifier may establish. Evidence may justify. Policy may admit. Humans retain publication authority.

## 4. The expeditions

Al-Tih is organized as a set of major expeditions. They may overlap, and discoveries in one expedition may alter another. Completion means demonstrating the engineering property of the expedition, not merely creating files bearing its name.

### 4.1 The Caravan Trial

The Caravan Trial connects the existing MIRAGE architecture into a complete evidence-driven improvement cycle.

Given a bounded goal such as:

```text
Add support for exact matrix determinants.
```

MIRAGE should be able to:

1. preserve the original request and its provenance;
2. lower it into a structured goal;
3. inspect existing CENTL capabilities before proposing new code;
4. identify gaps, assumptions, conflicts, and unanswered questions;
5. derive explicit engineering and mathematical obligations;
6. generate one or more candidate changes;
7. materialize each candidate in an isolated transaction area;
8. build it;
9. execute relevant tests and checkers;
10. search for counterexamples;
11. compare the candidate with the baseline;
12. collect structured evidence;
13. review the candidate against policy;
14. reject it or mark it admissible;
15. preserve the entire decision lineage.

No candidate may silently edit trusted Oasis state. No generated change becomes authoritative merely because its generator considers it plausible.

The Caravan Trial is complete when CENTL can repeatedly perform this cycle on real bounded improvements and produce reproducible evidence bundles.

### 4.2 The Mirror

MIRAGE must learn to inspect CENTL as a computational object.

The Mirror builds a machine-readable model of:

- mathematical capabilities;
- physics capabilities;
- parser and language constructs;
- natural-language interpretation surfaces;
- modules and packages;
- dependencies and trust boundaries;
- assurance levels;
- tests and their coverage relationships;
- known limitations;
- unresolved requirements;
- weakly evidenced behavior;
- experimental versus qualified functionality.

The result should support questions such as:

```text
What can CENTL prove or compute exactly?
What mathematical domains are unsupported?
Which capabilities have weak evidence?
Which tests protect this behavior?
What would have to change to satisfy this requirement?
```

A future `centl-mirage survey` surface should be capable of producing both a machine-readable capability map and a human-readable research queue.

The Mirror is not self-confidence. It is self-description backed by inspectable repository facts.

### 4.3 The Crucible

A candidate that survives its happy-path tests has only begun its journey.

The Crucible turns MIRAGE against its own work.

It should include increasingly aggressive use of:

- property-based testing;
- fuzzing;
- mutation testing;
- differential testing;
- metamorphic testing;
- deterministic replay;
- malformed and ambiguous natural-language input;
- pathological exact arithmetic cases;
- enormous integers and rational expressions;
- parser ambiguity;
- dimensional and unit errors;
- physics boundary conditions;
- serialization and protocol corruption;
- corrupted or incomplete evidence;
- hostile candidate patches;
- resource-budget exhaustion;
- regression corpus expansion from discovered failures.

MIRAGE should attempt to falsify its own candidate before asking anyone else to trust it.

Failure in the Crucible is useful when it produces a durable counterexample and improves the next candidate.

### 4.4 The Scribe

Plain English should become a serious local specification medium for CENTL development.

A researcher should be able to provide a design document, mathematical note, requirements document, or carefully written request and have MIRAGE transform it into attributable engineering structure.

The Scribe extends the Structure Library and Specification IR so that prose can yield:

- requirements;
- invariants;
- acceptance criteria;
- examples;
- non-goals;
- assumptions;
- open questions;
- mathematical entities;
- expected dimensions and units;
- candidate tests;
- capability gaps;
- development obligations.

The original document remains authoritative for what the user actually wrote. Inferred interpretations remain visibly inferred. Numbers, operators, units, signs, constraints, and assumptions must never be silently invented.

The ambition is not "prompt to code." It is:

```text
human specification
 -> attributable structured intent
 -> obligations
 -> candidate implementation
 -> evidence
```

### 4.5 The Djinn Boundary

MIRAGE should push local and offline machine intelligence hard while making the boundary between **suggestion** and **authority** unusually clear.

Local models may help with:

- prose interpretation;
- candidate generation;
- naming;
- search and ranking;
- test suggestions;
- documentation;
- refactoring proposals;
- hypothesis generation.

They may not, by themselves:

- declare a mathematical statement true;
- mark an obligation discharged;
- confer verified-core assurance;
- suppress contradictory evidence;
- invent provenance;
- authorize publication;
- weaken an Oasis invariant to make a candidate pass.

The central rule is:

> **A model may hypothesize. It may not confer truth.**

MIRAGE should remain useful without a paid AI service and without network access.

### 4.6 The Long Night

MIRAGE should eventually support sustained bounded research cycles rather than only one-shot generation.

A user supplies an objective, resource budget, policy, and stopping conditions. MIRAGE may then iterate locally:

```text
hypothesis
 -> candidate
 -> obligations
 -> execution
 -> counterexample/evidence
 -> reject or retain
 -> refine
 -> repeat
```

Every iteration must remain bounded, observable, interruptible, and attributable.

The Long Night must have explicit termination conditions. Endless rewriting is not progress.

Useful stopping conditions include:

- the goal is satisfied;
- no admissible candidate is found within the budget;
- further progress requires user information;
- a policy boundary is reached;
- evidence stops improving;
- the user stops the run.

### 4.7 The Return

The Return begins only after the exploratory work has matured.

At that point MIRAGE stops expanding the candidate surface. The surviving work is frozen and the question changes from:

```text
What can we discover?
```

to:

```text
What can we defend?
```

The Return is the precursor to Oasis seeking, not Oasis qualification itself.

It requires consolidation, removal of abandoned experiments, dependency review, documentation reconstruction, evidence review, reproducibility work, security review, and identification of the exact candidate state that may be carried toward Oasis.

## 5. The Book of the Desert

Al-Tih treats failed experiments as engineering knowledge rather than disposable noise.

MIRAGE should maintain a structured experimental lineage called **The Book of the Desert**.

Conceptually, every significant experiment records:

```text
goal
 -> source/provenance
 -> hypothesis
 -> baseline
 -> candidate
 -> obligations
 -> execution plan
 -> environment
 -> evidence
 -> attacks/counterexamples
 -> result
 -> rejection/admission reason
 -> ancestry
```

An experiment should have a durable identity and, where applicable:

- source commit;
- parent experiment;
- generated diff;
- dependency identity;
- build identity;
- test corpus identity;
- benchmark deltas;
- discovered counterexamples;
- assurance claims;
- known limitations;
- final disposition.

Possible dispositions include:

```text
REJECTED
INCONCLUSIVE
RETAINED_EXPERIMENTAL
SUPERSEDED
ADMISSIBLE
PROMOTION_CANDIDATE
```

The long-term goal is that CENTL can answer:

```text
Why does this implementation exist?
```

with an inspectable intellectual and experimental lineage rather than merely pointing to the commit in which the code appeared.

## 6. Failure is data

Al-Tih explicitly permits high experimental failure rates.

If MIRAGE evaluates hundreds of candidate improvements and only a small number survive, that is not inherently failure of the project. What matters is whether rejected candidates are rejected for intelligible reasons, whether useful counterexamples are retained, whether trusted code remains protected, and whether the surviving candidates become stronger because of the process.

The dangerous outcome is not a rejected experiment.

The dangerous outcome is an experiment that fails silently, cannot explain itself, corrupts trusted state, or produces confidence unsupported by evidence.

Therefore:

> **A failed candidate with preserved evidence may be more valuable than a passing candidate with unexplained confidence.**

## 7. Independent evidence and differential truth

MIRAGE should avoid validating CENTL solely by asking CENTL whether CENTL is correct.

Where practical, candidates should be checked through independent or structurally different evidence sources.

Examples include:

- comparison with established mathematical implementations for overlapping domains;
- algebraic identities and exact invariants;
- independent reference implementations;
- dimensional invariants;
- conservation laws in physics;
- deterministic replay;
- parser round trips;
- metamorphic relationships;
- property-based generators;
- proof or theorem checkers where available;
- reproducible builds and artifact hashes.

Agreement with an external implementation is evidence, not automatic authority. Disagreement is a research event that must be investigated rather than resolved by majority vote.

For CENTL-SCi, natural-language interpretation must lower into explicit internal mathematical structure before the result receives mathematical authority.

## 8. Mirage Laboratory

Al-Tih requires an isolated laboratory in which candidates can be dangerous without making the product dangerous.

Each serious experiment should execute in an isolated candidate workspace, branch, worktree, sandbox, or equivalent transaction area with a known baseline.

The laboratory should support:

- candidate generation;
- compilation;
- test execution;
- fuzzing;
- mutation;
- benchmarking;
- evidence collection;
- comparison;
- rejection and cleanup;
- retention of selected artifacts.

Experiments must not mutate Oasis directly.

Promotion should move evidence-backed artifacts across an explicit boundary rather than turning experimental state into stable state by accident.

## 9. Promotion protocol: MIRAGE to Oasis Candidate

MIRAGE does not become Oasis merely because a branch is merged.

When Al-Tih eventually produces work worth qualifying, MIRAGE should construct a **sealed Oasis-candidate bundle** containing at least:

- exact source commit;
- source tree identity;
- generated-core identities;
- dependency identities;
- toolchain identity;
- build instructions;
- test results;
- adversarial/fuzz/property evidence;
- differential and metamorphic evidence where applicable;
- security findings and dispositions;
- reproducibility evidence;
- performance changes;
- known limitations;
- assurance map;
- Book of the Desert lineage for promoted experiments;
- human approval state.

Oasis qualification consumes the frozen candidate. It does not qualify a moving MIRAGE branch.

The metaphor is deliberate:

> **MIRAGE discovers. The Caravan carries. Oasis qualifies.**

Availability may be distributed. Authority remains explicit.

## 10. The Caravan Trial completion criterion

The central Al-Tih milestone is reached when the following statement is demonstrably true:

> **CENTL can receive a bounded improvement goal, generate a candidate change, test and attack it, produce reproducible evidence, and deliver a sealed Oasis-candidate bundle without modifying Oasis itself.**

This should be demonstrated repeatedly, not once as a staged example.

The goal is a development mechanism whose failures are observable and whose successes are defensible.

## 11. Conditions for ending Al-Tih

Al-Tih has no predetermined date and no predetermined version number.

The epoch may end when there is strong evidence that:

1. the Caravan Trial works end to end on real changes;
2. The Mirror can accurately describe meaningful portions of CENTL's capability and assurance surface;
3. The Crucible routinely discovers and preserves useful counterexamples;
4. The Scribe can turn substantial human specifications into attributable structured development goals;
5. The Djinn Boundary is technically enforced rather than merely documented;
6. The Long Night can perform bounded iterative research without uncontrolled mutation;
7. The Book of the Desert preserves useful experimental lineage;
8. MIRAGE candidates can be reproduced from recorded inputs and identities;
9. abandoned experimental machinery has been removed or clearly isolated;
10. the surviving system represents a substantial improvement over the current Oasis;
11. the project can freeze a specific candidate and stop feature development long enough to qualify it rigorously.

These are not automatic release gates. They are evidence that it may finally be worth asking whether an Oasis exists inside the Mirage.

## 12. Oasis seeking

When Al-Tih ends, CENTL does **not** immediately declare another Oasis.

The sequence should be:

```text
AL-TIH
  -> THE RETURN
  -> FREEZE MIRAGE CANDIDATE
  -> CARAVAN EVIDENCE BUNDLE
  -> SECURITY + REPRODUCIBILITY + DOCUMENTATION CONVERGENCE
  -> OASIS QUALIFICATION
  -> OASIS DECLARATION, only if every required gate survives
```

During qualification, claims are challenged rather than polished. Security becomes stricter. Reproducibility is independently checked. Documentation must match observed behavior. Experimental assurance labels are audited. Every exception must be visible.

If qualification fails, the candidate returns to MIRAGE.

There is no obligation to declare an Oasis merely because an Oasis attempt began.

## 13. Relationship to the existing MIRAGE architecture

This charter extends, rather than replaces, `docs/CENTL-MIRAGE.md`.

The existing MIRAGE state model, Structure Library, Specification IR, goal graph, capability graph, candidate synthesis hierarchy, semantic fingerprints, evidence lattice, autonomy policy, and admissibility rules remain foundational.

Al-Tih supplies the larger research epoch in which those mechanisms are pushed into an integrated, adversarial, evidence-preserving system.

Existing concepts map naturally into the expeditions:

```text
Structure Library + Specification IR   -> The Scribe
Capability graph + gap analysis        -> The Mirror
Candidate/obligation/execution stages  -> The Caravan Trial
Evidence + admission + review          -> The Caravan Trial / The Crucible
Semantic fingerprints                  -> The Crucible
Local model proposer                    -> The Djinn Boundary
Recursive development cycle            -> The Long Night
Revision/evidence history               -> The Book of the Desert
Promotion and qualification             -> The Return
```

## 14. Non-negotiable Al-Tih rules

1. Oasis remains stable authority while MIRAGE experiments.
2. There is no scheduled next Oasis.
3. MIRAGE is permitted to fail; it is not permitted to hide failure.
4. Every important self-change must be attributable to a goal.
5. Every important experiment should leave reproducible evidence proportional to its claim.
6. Generated code does not inherit verified assurance.
7. Local or remote language models do not confer mathematical truth.
8. Original user specifications retain provenance.
9. Contradictions become explicit conflicts, not silent choices.
10. Trusted invariants may not be weakened merely to admit a candidate.
11. Experiments remain isolated from Oasis until explicit promotion.
12. Autonomous cycles are bounded, observable, interruptible, and reversible.
13. Security boundaries remain explicit even during experimentation.
14. Publication remains a distinct authority boundary.
15. The project records why candidates were rejected as seriously as why candidates were accepted.
16. Oasis qualification operates on a frozen candidate, never a moving experimental branch.
17. An Oasis declaration occurs only after qualification, never because of schedule or version pressure.

## 15. Closing principle

Al-Tih is the decision to spend longer in the desert so that the next Oasis means more.

CENTL should emerge from this epoch not merely larger, but more capable of explaining its own structure, discovering its own limitations, proposing its own improvements, attacking those proposals, preserving what it learns, and distinguishing speculation from justified computation.

The destination of that wandering is now named **Al-Nur**.
That name is Oasis CENTL v0.15.0. It is not a SemVer component and not
a second tag. The canonical tag remains `v0.15.0`.

For now, the work after Al-Nur continues on `mirage` and `main`.

**Free for science.**
