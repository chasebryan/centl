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
             deterministic rendering
```

The model never becomes mathematical authority. Exactness, proof status,
resolution, unit consistency, resource bounds, and provenance come from CENTL
and CENTL Physics.

## Current qualification evidence

The reference local backend has now completed a real end-to-end qualification
case on developer hardware.

Observed reference configuration:

- model: `Qwen_Qwen3-4B-Instruct-2507-Q4_K_M.gguf`;
- runtime: `llama.cpp` `llama-cli` build `b10330-687e77892`;
- case: `exact_decimal_addition`;
- result: **PASS**;
- observed whole-process elapsed time: **67.064 seconds**;
- mathematical result: CENTL establishes exact `3/10` for `0.1 + 0.2`.

The 67.064-second measurement includes a fresh process and model load. It is a
cold reference-path measurement, not a steady-state inference claim and not an
acceptable production latency target.

Model qualification now explicitly uses `--force-model`, so deterministic
fast-path routing cannot accidentally inflate model-quality results.

## Tier 0 — deterministic fast path

CENTL-SCi now has a conservative deterministic interpreter ahead of the model.
It admits only surfaces that can be translated without semantic guessing and
then sends the resulting IR through the same independent validator and CENTL
execution boundary.

Initial admitted forms include:

- exact arithmetic such as `What is 0.1 plus 0.2?`;
- canonical unit conversions such as `Convert 100 centimeters to meters.`;
- directly symbolic equations such as
  `Solve x^2 - 5*x + 6 = 0 for x.`.

Natural-language equations such as `x squared minus five x ...` deliberately
fall through to the semantic model until their deterministic translation is
proven safe. General-knowledge prompts also fall through rather than being
misclassified as mathematics.

Normal JSON responses expose `interpreter_path` as `fast` or `model` so routing
is auditable. Model-quality evaluation requires `model`.

## FCF inference engine

The initial reference adapter uses `llama.cpp` because it provides a strong
portable inference substrate. The production direction is an FCF-maintained
fork with a deliberately reduced scientific surface.

Working internal name: **FCF-SCi Engine**.

The fork should:

- preserve required upstream license and copyright notices;
- remove or disable generic chat UI, personas, agent/tool calling, multimodal
  features, arbitrary model downloads, and unrelated user-facing surfaces;
- expose only the inference primitives CENTL-SCi needs;
- keep the model resident instead of starting a new process per problem;
- provide a small versioned local IPC/HTTP interface returning one structured
  interpretation object;
- support CPU first, with explicit optional GPU acceleration;
- keep network access out of local inference mode;
- make grammar/structured-output constraints part of the server request;
- measure model-load time separately from warm interpretation latency;
- retain upstream provenance in build/license information while presenting
  FCF/CENTL-SCi branding to normal users.

This is a fork of an inference runtime, not a dependency on Meta Llama model
weights. CENTL-SCi's model layer remains replaceable.

## Model direction

Qwen3-4B-Instruct-2507 Q4 is the current qualification/reference model. It is
not the intended final performance architecture.

The production model should be a **small specialized semantic compiler**, not a
general assistant. Its training objective and output vocabulary should be
centered on CENTL-SCi IR.

Development path:

1. use the reference model plus human-reviewed fixtures to generate and validate
   interpretation examples;
2. expand adversarial and paraphrase corpora around each admitted typed IR;
3. train/distill a substantially smaller model for classification and slot
   extraction into the closed IR;
4. quantize and benchmark candidates on CPU;
5. accept a model only when corpus accuracy and reject/unsupported behavior meet
   the release threshold;
6. never use model confidence as a substitute for CENTL verification.

The desired steady-state model is sub-billion-parameter if evaluation supports
it. This remains an engineering target, not a compatibility claim.

## Performance architecture

Starting a 4B process for every query is a reference-only path. Production
performance is layered:

### Tier 0 — deterministic fast path

Already in implementation. High-confidence arithmetic, unit conversion, and
direct symbolic equation surfaces can skip neural inference entirely.

Target: effectively immediate relative to model inference.

### Tier 1 — resident specialized semantic model

Ambiguous natural-language problems use the FCF semantic model. The model stays
loaded. Requests carry a compact versioned semantic contract rather than the
long prototype instruction prompt on every call.

### Tier 2 — CENTL execution

CENTL performs exact/symbolic computation and verification. This remains the
source of mathematical authority.

### Tier 3 — rendering

Human output is deterministic. No second model pass is required merely to
explain the result.

## Hosted architecture

FCF may host CENTL-SCi while retaining the same semantics as the local product.

```text
web / desktop / CLI
        |
        v
FCF CENTL-SCi gateway
        |
        +--> deterministic fast path
        |
        +--> resident FCF-SCi workers
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
- deterministic operations may be cached by normalized request where safe;
- privacy and retention policy must be explicit before public hosting;
- health/version endpoints must not expose filesystem model paths or internal
  infrastructure details.

## Visual identity

CENTL-SCi should feel like a modern scientific command console with restrained
DOS/Commander ancestry, not a chat transcript and not a boxed dashboard.

Baseline terminal composition:

```text
 CENTL-SCi    //  FCF
Free Computation Foundation  //  Free for science.

SCI> What is 0.1 plus 0.2?
RT> FAST

OK> ESTABLISHED
=> 3/10
IR> mathematics.exact_expression -> compute
AS> none
RS> computed
PV> exact via CENTL
```

Prompt channels are part of the interface grammar:

- `SCI>` submitted scientific problem;
- `RT>` interpretation route (`FAST` or `MODEL`);
- `OK>` established result;
- `WAIT>` unresolved or unsupported;
- `ERR>` failed;
- `=>` result;
- `IR>` semantic interpretation;
- `AS>` assumptions;
- `RS>` CENTL resolution;
- `PV>` provenance;
- `WHY>` reason for rejection or unsupported state.

Color semantics remain stable rather than decorative:

- deep blue / cyan: CENTL-SCi identity and structural channels;
- green: established/exact;
- amber: unresolved or assumption-bearing;
- red: failed/rejected;
- muted gray: provenance/runtime metadata.

`--json`, machine protocols, and hosted API responses remain free of ANSI or
presentation markup.

## Performance metrics required before release claims

Record at minimum:

- cold model load time;
- warm interpretation p50/p95/p99;
- time to first generated token/structured field;
- total interpretation time;
- deterministic-fast-path time;
- CENTL execution time;
- peak resident memory;
- CPU model and thread count;
- accelerator/backend if present;
- fixture pass rate;
- unsupported/rejection precision;
- semantic false-accept rate;
- exact CENTL outcome rate for admitted fixtures.

Do not publish broad `fast`, hardware-support, or accuracy claims without
measured data.

## Immediate implementation order

1. keep the working `llama-cli` path as a forced reference/qualification backend;
2. finish and benchmark the deterministic fast path;
3. replace per-request model startup with a persistent resident server adapter;
4. measure warm latency separately from cold load time;
5. benchmark smaller permissively licensed semantic-model candidates;
6. build a reviewed interpretation/distillation corpus;
7. define the hosted FCF-SCi service protocol and deployment hardening;
8. broaden mathematics/physics IR only after the performance/trust boundary is
   stable.
