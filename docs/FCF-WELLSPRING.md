# FCF Wellspring

**Status:** active FCF research designation
**Scope:** foundational discoveries arising from CENTL and Free Computation Foundation research
**SemVer effect:** none
**Oasis assurance effect:** none by itself
**Publication authority:** separate from the designation

> A Wellspring is not merely a successful experiment. It is a finding from which multiple new possibilities begin to flow.

## Definition

An **FCF Wellspring** is a foundational, evidence-bearing discovery that opens multiple independently useful avenues of computation, mathematics, engineering, architecture, or research.

The term names a kind of **finding**, not a branch, release, feature, product, benchmark result, or marketing milestone.

A Wellspring matters because the value of the discovery survives any one implementation built from it. A prototype may be discarded, a release may change, or a particular research path may fail while the underlying finding remains capable of generating useful work elsewhere.

The canonical short definition is:

> **FCF Wellspring:** a foundational discovery from which multiple new avenues of computation, mathematics, architecture, engineering, or research begin to flow.

The designation is intentionally rare. It should mean more than "promising," "interesting," "working," or "better than before."

## Why the designation exists

FCF research deliberately permits uncertain exploration. CENTL-MIRAGE can contain hypotheses, prototypes, speculative architectures, partially supported mathematics, local-model proposals, and other work that has not yet earned stable-product assurance.

Most successful experiments should remain successful experiments. Some findings, however, change the shape of the search itself. They expose a reusable principle, a new abstraction, a new proof route, a new numerical or systems technique, a new trust-boundary design, or another result with consequences larger than the experiment that revealed it.

FCF Wellspring exists to identify that second category without confusing discovery with product maturity.

The governing rule is:

> **Wellspring classifies generative research significance. Oasis classifies stable-release qualification. They are independent claims.**

## Relationship to MIRAGE, Secret Oasis, and Oasis

The FCF desert vocabulary describes different things and must not collapse into one maturity ladder.

### MIRAGE

**MIRAGE** is the development and research environment in which uncertain work can be attempted, challenged, revised, or rejected. A MIRAGE result may be promising without being correct, complete, stable, or foundational.

A Wellspring can be discovered through MIRAGE work, but MIRAGE does not automatically produce Wellsprings and a MIRAGE candidate never inherits the designation merely because it passes its local acceptance criteria.

See [`CENTL-MIRAGE.md`](CENTL-MIRAGE.md).

### Secret Oasis

**Secret Oasis** is a bounded exploratory search posture: a deliberate expedition into uncertain research space where the goal is to locate unusually valuable directions without prematurely turning every idea into a public product commitment.

The existence and meaning of the Wellspring designation may be public while the working materials, candidate list, search strategy, or unvalidated results of a Secret Oasis expedition remain private until publication is appropriate.

Secret Oasis is therefore a **search activity**. Wellspring is a **finding designation**.

A Secret Oasis expedition can end with:

- no useful discovery;
- ordinary research improvements;
- one or more promising MIRAGE candidates;
- an FCF Wellspring;
- evidence that changes the direction of future exploration;
- or a justified decision to abandon the searched path.

Failure to find a Wellspring is not failure of the research process. Negative results can still eliminate bad directions and improve the next search.

### Oasis

**Oasis** is CENTL's evidence-backed stable-release qualification state. It concerns exact source identity, supported product boundaries, verification, security, documentation, packaging, reproducibility, and publication.

A Wellspring does **not** satisfy Oasis requirements. A Wellspring may be too new, too risky, too incomplete, or entirely outside a release boundary. Conversely, an Oasis release does not need to contain a Wellspring. Stable releases can be excellent because they consolidate and harden existing work.

See [`OASIS.md`](OASIS.md).

The relationship is best summarized as:

```text
MIRAGE        = where uncertain work can develop
Secret Oasis  = a deliberate search for unusually valuable directions
Wellspring    = a foundational, generative finding
Camp          = a durable stay when Oasis cannot be declared
Oasis         = a qualified stable-product release state
```

None of these terms substitutes for the evidence required by another.

## What qualifies as a Wellspring

A candidate should satisfy all of the following dimensions before FCF uses the Wellspring designation publicly.

### 1. Foundational significance

The finding changes or materially clarifies a foundation rather than merely improving one local implementation.

Examples include a reusable computational principle, a new exactness or verification technique, a broadly applicable representation, a new architectural trust separation, or another result capable of influencing multiple components.

A faster function, cleaner refactor, isolated bug fix, or one-off feature is normally not foundational by itself.

### 2. Generative value

The finding opens **multiple distinct downstream avenues**.

At least two downstream directions should be articulable without pretending that closely related implementation tasks are independent discoveries.

For example, a new representation might independently enable:

- a stronger proof strategy;
- a simpler evaluator;
- and a new machine-interface capability.

The important property is branching value. A Wellspring is a source, not merely a destination.

### 3. Evidence

The core claim must have evidence appropriate to its domain.

Evidence may include:

- formal proof or proof obligations;
- deterministic tests;
- independent differential evaluation;
- counterexamples survived;
- reproducible experiments;
- benchmarks with controlled methodology;
- architecture or threat-model analysis;
- source/provenance records;
- or other domain-appropriate validation.

The designation must identify what is established and what remains hypothetical. Model confidence, aesthetic appeal, novelty language, or excitement are not evidence.

### 4. Reproducibility or inspectability

Another competent investigator should be able to inspect the reasoning and, where the claim is experimental, reproduce the relevant result from recorded inputs, source identity, assumptions, and procedures.

Some theoretical or architectural findings are not meaningfully rerun like a benchmark. In those cases the argument, model, proof, assumptions, and counterexamples must still be inspectable.

### 5. Durability

The finding should retain value if the original prototype is removed.

This is a useful test against accidental overclassification. If deleting one implementation destroys the entire value of the "discovery," the result is probably an implementation success rather than a Wellspring.

### 6. Relevance to FCF's mission or research systems

The finding must connect to FCF's computational, mathematical, scientific, preservation, trust, or systems work. Interesting discoveries outside that scope can remain valuable without receiving an FCF-specific designation.

### 7. Falsifiability and limits

A Wellspring record must state what could invalidate, narrow, or demote the claim.

A designation that cannot survive explicit counterexamples, changing assumptions, or independent review is not a scientific designation.

## What does not qualify

The following are not Wellsprings merely by being successful:

- a feature shipping on time;
- a passing CI run;
- an Oasis-qualified release;
- a performance improvement with only one narrow use;
- a popular announcement or adoption spike;
- a local-model suggestion that has not been independently validated;
- a speculative architecture with no evidence;
- a renamed existing technique;
- a large amount of engineering work;
- or a result whose only downstream consequence is "continue implementing the same feature."

A Wellspring can eventually produce any of these outcomes, but those outcomes do not establish the Wellspring in reverse.

## Wellspring Candidate

Before designation, a potentially foundational discovery should be called a **Wellspring Candidate**.

This language matters because early research is unusually vulnerable to narrative momentum. Naming a candidate as a completed Wellspring before independent scrutiny would turn the designation into self-congratulation rather than a useful research signal.

Candidate status means:

1. a potentially foundational claim has been identified;
2. at least two plausible downstream directions have been described;
3. the evidence package is incomplete, under review, or awaiting reproduction;
4. the candidate may still be rejected without implying that the wider research effort failed.

No automated score, model output, MIRAGE acceptance result, or project founder declaration should bypass the evidence review implied by candidate status.

## Wellspring Record

Durable records live under [`docs/wellsprings/`](wellsprings/README.md). The
local `centl-mirage wellspring` command can render the current expedition and
records, but it cannot designate a Wellspring: designation requires the
evidence review described below.

A designated Wellspring should receive a durable **Wellspring Record** in the repository or another FCF-controlled research archive.

A record should contain at least:

```text
Title
Status: candidate | designated | narrowed | retired
Date identified
Investigators / contributors
Originating expedition or research context
Source / commit / artifact identity
Core finding
Assumptions and scope
Evidence
Independent reproduction or review
Known counterexamples / failure modes
Downstream avenues opened
Oasis impact, if any
Security or publication constraints
Falsifiers / demotion conditions
References
```

The record is the technical object. The name is only a compact label for it.

Where a Wellspring generates later projects, those projects should link back to the record and identify exactly which part of the original finding they rely upon.

## Downstream streams

The independent lines of work opened by a Wellspring may be described informally as its **streams**.

A stream is not automatically a project or branch. It is a traceable downstream research direction whose existence helps demonstrate the generative value of the source finding.

A useful Wellspring record therefore answers:

> If this finding is real, what can we now investigate or build that was not previously available, justified, or obvious?

The answer should contain multiple materially distinct directions.

## Designation process

The preferred process is:

```text
observation or experiment
        |
        v
possible foundational finding
        |
        v
Wellspring Candidate
        |
        | evidence + reproduction + adversarial review
        v
FCF Wellspring
        |
        +--> downstream stream A
        +--> downstream stream B
        +--> downstream stream C ...
```

A candidate is designated only when the core claim is sufficiently supported for the strength of language used in its record.

The review should actively search for simpler explanations, prior art, hidden assumptions, counterexamples, measurement artifacts, circular evidence, and cases in which several supposed downstream avenues are really the same implementation task under different names.

## Designation is revocable

Wellspring is an evidence-backed status, not an honorific.

A record may be changed to `narrowed` or `retired` when later evidence shows that:

- the core claim was false;
- the result depended on an unstated assumption;
- the supposed novelty was already established elsewhere and FCF's claim materially overstated it;
- the generative consequences did not survive scrutiny;
- reproduction failed for reasons that undermine the finding;
- or a later model explains the evidence more accurately.

The historical record should not be erased. It should explain what changed and why.

Revocability strengthens the designation because FCF is committing to the evidence rather than to the prestige of having announced a discovery.

## Publication and security

Wellspring designation does not grant authority to publish sensitive material.

A finding may implicate security vulnerabilities, unreleased infrastructure, private research notes, model or dataset licensing, third-party confidentiality, embargoed collaboration, or other constraints. Those boundaries must be resolved independently.

Likewise, describing the Wellspring concept publicly does not require publishing the operational details of a Secret Oasis expedition or exposing unvalidated candidates.

Publication should separate:

- the existence of a research concept;
- the claim that a particular Wellspring Candidate exists;
- the evidence required to designate it;
- and the decision to release technical details.

## Relationship to releases

A Wellspring can influence a later Oasis release, but the path is ordinary engineering:

```text
Wellspring
   |
   v
research streams / implementations
   |
   v
MIRAGE development and validation
   |
   v
selected stable product boundary
   |
   v
Oasis qualification
```

The Wellspring designation contributes no release assurance by itself. The resulting implementation must pass the same applicable verification, security, packaging, documentation, and publication gates as any other code.

Similarly, failure to integrate a Wellspring into CENTL does not automatically invalidate the discovery. Its value may belong to another FCF project, a later generation of CENTL, a mathematical result, or a preserved research direction.

## Scarcity rule

FCF should prefer **under-designation** to inflation.

There is no quota, cadence, leaderboard, release requirement, or expectation that every research cycle should discover a Wellspring. Months or years may pass without one. Multiple Wellsprings may also emerge close together if the evidence genuinely warrants it.

The term remains useful only while an FCF Wellspring means that the search uncovered a source of several durable new possibilities, not simply that the team had a good day.

## Canonical statement

When the evidence supports designation, the preferred public form is:

> **The Free Computation Foundation has designated this finding an FCF Wellspring.**

That sentence should be followed by the Wellspring Record, the evidence supporting the core claim, and the downstream research avenues the finding opens.
