# CENTL-SCi Engine Architecture

> **CENTL-SCi**  
> **Free Computation Foundation**  
> **Free for science.**

Status: architecture direction for the local and hosted CENTL-SCi runtime.

## Product identity

CENTL-SCi is not a chatbot and it is not a general-purpose language model. It is
a scientific semantic interpreter whose only purpose is to convert ordinary
mathematics and physics language into a small typed problem representation that
CENTL can check and execute.

The visible product is **CENTL-SCi**. The organization identity is **FCF — Free
Computation Foundation**. The product line is **Free for science.**

The inference implementation must not leak upstream runtime or temporary model
branding into the normal user experience. Runtime and model provenance remain
available in build/debug/about information and license notices.

## Trust boundary

```text
problem text
    |
    v
fast deterministic admission/parser
    | exact match                    | ambiguous
    |                                v
    |                         FCF semantic model
    |                         (untrusted parser)
    |                                |
    +---------------+----------------+
                    v
             CENTL-SCi IR
                    |
              strict validation
                    |
         +----------+----------+
         |                     |
         v                     v
       CENTL              CENTL Physics
         |                     |
         +----------+----------+
                    v
         checked scientific evidence
                    |
                    v
             branded rendering
```

The model never becomes mathematical authority. Exactness, proof status,
resolution, unit consistency, resource bounds, and provenance come from CENTL
and CENTL Physics.

## FCF inference engine

The initial prototype uses `llama.cpp` because it provides a strong portable
local inference substrate. The production direction is an FCF-maintained fork
with a deliberately reduced scientific surface.

Working internal name: **FCF-SCi Engine**.

The fork should:

- preserve required upstream license and copyright notices;
- remove or disable generic chat UI, personas, agent/tool calling, multimodal
  features, arbitrary model downloads, and unrelated user-facing surfaces;
- expose only the inference primitives CENTL-SCi needs;
- keep the model resident rather than starting a new process per problem;
- provide a small versioned local IPC/HTTP interface returning one structured
  interpretation object;
- support CPU first, with explicit optional GPU acceleration;
- keep network access out of local inference mode;
- make grammar/structured-output constraints part of the server request;
- measure model-load time separately from steady-state interpretation latency;
- retain upstream provenance in `--build-info` / license documentation while
  presenting FCF/CENTL-SCi branding to normal users.

This is a fork of an inference runtime, not a dependency on Meta Llama model
weights. CENTL-SCi's model layer remains replaceable.

## Model direction

Qwen3-4B-Instruct-2507 Q4 is a qualification/reference model for v0.0.1. It is
not the intended final performance architecture.

The production model should be a **small specialized semantic compiler**, not a
general assistant. Its output vocabulary and training objective should be
centered on CENTL-SCi IR.

Development path:

1. use the larger reference model plus human-reviewed fixtures to generate and
   validate interpretation examples;
2. expand adversarial and paraphrase corpora around each admitted typed IR;
3. train/distill a substantially smaller model for classification + slot
   extraction into the closed IR;
4. quantize and benchmark candidate models on CPU;
5. accept a model only when corpus accuracy and reject/unsupported behavior meet
   the release threshold;
6. never use model confidence as a substitute for CENTL verification.

The desired steady-state model is sub-billion-parameter if evaluation supports
it. This is a target, not a current compatibility claim.

## Performance architecture

Starting a 4B model process for every query is a prototype-only path. Production
performance is layered:

### Tier 0 — deterministic fast path

Recognize high-confidence surface forms without invoking a model, including
plain exact expressions, directly stated equations, and canonical unit
conversions. The resulting IR still passes the same validator and CENTL
execution boundary.

Target: effectively immediate relative to model inference.

### Tier 1 — resident specialized semantic model

Ambiguous natural-language problems use the small FCF semantic model. The model
stays loaded. The request carries only the compact semantic contract needed for
its model version; the full long instructional prompt used during prototyping is
not repeated for every request.

### Tier 2 — CENTL execution

CENTL performs exact/symbolic computation and verification. This is the source
of mathematical authority and should normally be much cheaper than loading a
large language model.

### Tier 3 — rendering

Human output is deterministic. No second language-model pass is required merely
to explain the result. Structured CENTL evidence is rendered directly into a
clear scientific response.

## Hosted architecture

FCF may host CENTL-SCi while retaining the same semantics as the local product.

```text
web/desktop/CLI client
        |
        v
FCF CENTL-SCi gateway
        |
        +--> deterministic fast path
        |
        +--> resident FCF-SCi inference workers
                    |
                    v
                SCi IR
                    |
                    v
            CENTL execution pool
                    |
                    v
           structured response
```

Hosted requirements:

- no requirement that a user run proprietary software locally;
- model workers stay warm/resident;
- bounded request sizes and execution budgets;
- per-request IR and CENTL evidence remain separable for auditing;
- no hidden model-generated numerical answer may bypass CENTL;
- local and hosted modes use the same versioned SCi IR contract;
- deterministic operations should be cacheable by normalized request where
  appropriate;
- privacy and retention policy must be explicit before public hosting;
- public service should expose health/version information without exposing
  filesystem model paths or internal infrastructure details.

## Visual identity

Human-facing CENTL-SCi should be recognizably different from a generic terminal
LLM.

Baseline terminal composition:

```text
╭──────────────────────────────────────────────────────────────╮
│  CENTL-SCi                                                   │
│  Free Computation Foundation · Free for science.             │
╰──────────────────────────────────────────────────────────────╯

  ESTABLISHED   exact mathematics

  0.1 + 0.2
  ─────────
     3/10

  interpretation   mathematics.exact_expression → compute
  assumptions      none
  resolution       computed
  provenance       exact · CENTL
```

Color semantics should be stable rather than decorative:

- cyan/blue: CENTL-SCi identity and structural labels;
- green: established/exact;
- amber: unresolved or assumption-bearing;
- red: failed/rejected;
- muted gray: provenance, engine/runtime metadata.

`--json`, machine protocols, and hosted API responses remain free of ANSI or
presentation markup.

A later web interface should use the same hierarchy: prominent problem/result,
visible exactness/status, collapsible interpretation/evidence, and FCF identity.
It should not resemble a conversational chat transcript.

## Performance metrics required before release claims

Record at minimum:

- cold model load time;
- warm interpretation p50/p95/p99;
- time to first generated token/structured field;
- total interpretation time;
- CENTL execution time;
- peak resident memory;
- CPU model and thread count;
- accelerator/backend if present;
- fixture pass rate;
- unsupported/rejection precision;
- semantic false-accept rate;
- exact CENTL outcome rate for admitted fixtures.

Do not publish 'fast', hardware support, or accuracy percentages without
measured data.

## Immediate implementation order

1. finish the current `llama-cli` v0.0.1 qualification boundary and preserve it
   as a reference backend;
2. add deterministic fast-path interpretation for the already admitted IR;
3. replace per-request `llama-cli` process launch with a persistent server
   adapter;
4. benchmark smaller Apache-licensed semantic-model candidates;
5. build a reviewed SCi interpretation training/distillation corpus;
6. add the FCF-branded terminal renderer;
7. define the hosted FCF-SCi service protocol and deployment hardening;
8. only then broaden the mathematics/physics IR surface.
