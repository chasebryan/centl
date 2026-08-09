# CENTL-SCi Engine Architecture

> **CENTL-SCi v0.0.1-Camelus**  
> **Free Computation Foundation**  
> **Free for science.**

Status: active architecture direction for the local and hosted CENTL-SCi runtime.

## Product identity

CENTL-SCi is not a chatbot and it is not a general-purpose language model. It is
a scientific semantic interpreter whose purpose is to convert ordinary
mathematics and physics language into a small typed problem representation that
CENTL can check and execute.

The visible product is **CENTL-SCi**. The organization identity is **FCF — Free
Computation Foundation**. The product line is **Free for science.**

Upstream runtime and temporary model branding must not leak into the normal user
experience. Runtime/model provenance remains available through build, debug,
about, and license information.

## Trust boundary

```text
problem text
    |
    v
conservative deterministic fast path
    | admitted                       | ambiguous
    v                                v
CENTL-SCi IR                    FCF-SCi Engine
    |                                |
    |                           typed SCi IR only
    |                                |
    +---------------+----------------+
                    |
                    v
             strict validation
                    |
                    v
                  CENTL
                    |
                    v
             checked evidence
```

CENTL remains the mathematical authority. The inference engine is an untrusted
semantic parser even when it is distributed by FCF.

The engine must never gain permission to emit an arbitrary executable command,
filesystem operation, network request, CENTL operation, or mathematical result.
It emits only the closed, versioned SCi Problem IR accepted by the validator.

## Runtime direction

The v0.0.1-Camelus reference implementation begins with `llama.cpp` compatibility,
but the production direction is an FCF-specific scientific inference runtime.
The runtime should retain upstream license/provenance information while exposing
only the functionality CENTL-SCi needs.

Production priorities are:

1. persistent resident inference rather than per-problem model loading;
2. deterministic fast-path admission before neural inference;
3. grammar-constrained structured output;
4. a compact semantic model specialized for mathematics/physics interpretation;
5. CPU-first portability and measured accelerator support;
6. no general chat/persona/tool/agent surface;
7. reproducible local and hosted behavior using the same SCi IR contract.

The current `llama-cli` path remains useful as a qualification/reference
backend, not the performance target.

## Performance tiers

### Tier 0: deterministic interpretation

Mechanically recognizable supported problems should bypass neural inference.
Examples include exact arithmetic, canonical unit conversion, and directly
symbolic equations when the translation is unambiguous.

Tier 0 must remain conservative. If a statement requires semantic judgment, it
must fall through rather than guessing.

### Tier 1: semantic inference

Remaining supported ordinary-language mathematics and physics problems go to a
small resident semantic model. The model's only job is translating the problem
into SCi IR.

The current 4B Qwen model is a reference/teacher candidate rather than the
intended production model. Sub-billion parameter models are an engineering
target if the deterministic corpus demonstrates adequate interpretation quality.
No size or latency target becomes a compatibility claim until it is measured.

### Tier 2: deterministic computation

All admitted operations are lowered into CENTL or CENTL Physics. Exactness,
dimensional validity, conditions, resource limits, unsupported behavior, and
verification status are established there rather than by the semantic model.

## Resident engine

A persistent service avoids reloading model weights for every problem. The
initial compatibility layer may use a loopback `llama-server`; the longer-term
FCF-SCi Engine should expose a narrower versioned protocol containing only the
operations necessary for SCi interpretation.

The service must be explicitly local when used by the local product. Hosted
CENTL-SCi is a separate deployment mode and must not silently change a local
installation into a network client.

A resident request contains conceptually:

```json
{
  "version": 1,
  "problem": "Solve x squared minus five x plus six equals zero for x.",
  "schema": "centl-sci-problem-ir-v1"
}
```

and the only successful semantic output is validated SCi Problem IR.

## Model strategy

General conversational quality is not the selection objective. Candidate models
must instead be measured for:

- semantic math/physics classification;
- exact field extraction;
- paraphrase robustness;
- schema compliance under constrained decoding;
- adversarial instruction resistance;
- unsupported-problem recognition;
- CPU interpretation latency;
- peak/model memory;
- quantization sensitivity;
- redistribution license and model-card obligations.

A smaller specialized student can be trained or distilled using independently
reviewed SCi fixtures and teacher-generated candidates, but expected IR and
mathematical results must remain independently established. Teacher output is
never ground truth merely because it came from a larger model.

## Local and hosted parity

The local and FCF-hosted products should share:

- the same SCi Problem IR version;
- the same validation rules;
- the same deterministic fast path where practical;
- the same CENTL request lowering;
- the same evidence/status semantics.

Hosting changes deployment and capacity. It does not change what counts as
mathematical evidence.

## Visual identity

The human interface is an FCF scientific console, not a chatbot and not a card
dashboard.

Terminal presentation uses a compact Commander/DOS-derived prompt grammar:

```text
 CENTL-SCi    //  FCF
Free Computation Foundation  //  Free for science.

SCI> Solve x squared minus 5x plus 6 equals zero.

OK> ESTABLISHED
=> x in {2, 3}
IR> mathematics.polynomial_equation -> solve
AS> none
RS> transformed
PV> exact via CENTL
```

ANSI-capable terminals may use a restrained deep-blue title treatment,
blue/cyan structural channels, bright result text, green established status,
amber unresolved status, and red failure status. `--json` and machine protocols
must remain presentation-free.

The same visual grammar should carry into the hosted interface: deep scientific
blue, cyan information channels, prominent mathematical results, compact
provenance, and a terminal-like problem entry surface without pretending to be
an old terminal emulator.

## Measurements

Performance reporting should separate at least:

- engine/model load time;
- interpretation latency;
- deterministic CENTL computation time;
- verification time;
- rendering time;
- model memory;
- process peak memory.

Cold `llama-cli` measurements must not be advertised as steady-state latency.
Likewise, GPU measurements must not be presented as CPU compatibility results.

## Upstream and licensing

An FCF fork of `llama.cpp` must retain the upstream copyright and MIT license
notices required by the upstream license. The FCF product may have distinct
branding and architecture while accurately preserving that provenance.

Model licensing is separate from inference-runtime licensing. Every bundled or
recommended model must be reviewed independently for redistribution and use
rights before release.
