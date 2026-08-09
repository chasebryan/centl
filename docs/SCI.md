# CENTL-SCi

Status: experimental architecture, version `0.0.1-Camelus`.

CENTL-SCi means **Chase's Explicit Number Theory Language — Specific CENTL
Interpreter**.

CENTL-SCi is a local, domain-restricted semantic interpreter for mathematics and
physics. It is not a general chatbot and it is not a second mathematical or
physics evaluator. Its job is to translate an ordinary-language problem into a
small validated problem representation, dispatch that representation to
CENTL's deterministic machinery, and present the resulting evidence without
upgrading model guesses into mathematical facts.

The trust relationship is:

```text
ordinary-language problem
        |
        v
local model (untrusted interpreter)
        |
        v
CENTL-SCi Problem IR v1
        |
   strict validation
        |
        +-------------------+
        |                   |
        v                   v
CENTL protocol        CENTL Physics protocol
(read-only compute)   (typed exact request)
        |                   |
        +---------+---------+
                  |
                  v
        structured CENTL evidence
                  |
                  v
          mathematical result
```

CENTL remains the authority wherever it has implemented semantics.

## v0.0.1-Camelus support boundary

The first milestone deliberately supports only four IR classes:

| Problem class | Domain | Execution |
| --- | --- | --- |
| `exact_expression` | mathematics | read-only CENTL `compute` |
| `polynomial_equation` | mathematics | compile to CENTL `solve` |
| `unit_conversion` | physics | typed `centl-physics` `convert` |
| `unsupported` | either/outside scope | no computation |

The equation path inherits CENTL's current solver boundary: linear and real
quadratic equations with rational coefficients are the completed exact domain.
Unsupported equations remain explicit in CENTL's structured resolution rather
than being guessed.

The unit-conversion path inherits CENTL Physics dimensional checking and exact
rational scalar parsing. Dimensionally incompatible conversions are failures.

CENTL Physics already implements more mechanics than this table exposes. That
broader functionality is intentionally not available through natural-language
SCi planning yet. A physics feature is not promoted into the SCi support
contract until its interpretation schema and adversarial fixtures are defined
and tested.

## Problem IR v1

Every model result is one JSON object. Common fields are:

```json
{
  "schema_version": 1,
  "domain": "mathematics",
  "problem_class": "polynomial_equation",
  "operation": "solve",
  "assumptions": []
}
```

A polynomial equation adds explicit sides and a variable:

```json
{
  "schema_version": 1,
  "domain": "mathematics",
  "problem_class": "polynomial_equation",
  "operation": "solve",
  "assumptions": [],
  "left": "x^2 - 5*x + 6",
  "relation": "equal",
  "right": "0",
  "variable": "x"
}
```

An exact unit conversion is typed separately:

```json
{
  "schema_version": 1,
  "domain": "physics",
  "problem_class": "unit_conversion",
  "operation": "convert",
  "assumptions": [],
  "value": "100",
  "from_unit": "cm",
  "to_unit": "m"
}
```

The validator rejects unknown fields, duplicate fields, unknown operations,
invalid class/domain/operation combinations, invalid identifiers, control
characters, oversized model fields, and unsafe equation separators. Validation
is independent of the model's claim that its output is valid.

## Local inference boundary

The initial adapter targets `llama.cpp`'s `llama-cli`.

CENTL-SCi:

- starts the executable directly with `Unix.open_process_args_in`; it does not
  construct a shell command;
- passes `--offline` so the inference invocation does not fetch remote models;
- passes a JSON Schema constraint to `llama-cli`;
- also describes the schema in the prompt because grammar constraints alone do
  not tell the model what fields mean;
- uses one bounded single-turn generation;
- caps problem and model-output bytes;
- parses exactly one JSON object and does not extract JSON from surrounding
  prose;
- treats every generated expression and field as untrusted input after
  generation.

The configured `llama-cli` executable and model path are local operator
configuration, not values chosen by the model.

The adapter is intentionally replaceable. CENTL-SCi's IR and execution bridge
do not depend on Qwen-specific APIs or a hosted inference provider.

## Model candidates

No model is declared mathematically authoritative and no model is bundled with
CENTL-SCi v0.0.1-Camelus.

The initial evaluation candidates are:

1. `Qwen/Qwen3-4B-Instruct-2507` — Apache-2.0, approximately 4B parameters,
   instruction-tuned and non-thinking-only. It is the first candidate to test
   for structured math/physics interpretation.
2. `Qwen/Qwen3-1.7B` — Apache-2.0, approximately 1.7B parameters. It is the
   lower-resource comparison baseline.

`llama.cpp` is MIT-licensed and supports local GGUF inference, quantization,
CPU execution, Apple Silicon, and multiple optional accelerator backends.

These are **evaluation candidates, not compatibility claims**. A model should
only become a recommended default after the CENTL-SCi fixture corpus measures
interpretation accuracy, schema compliance, latency, and memory use on tested
hardware.

Upstream resources:

- <https://github.com/ggml-org/llama.cpp>
- <https://huggingface.co/Qwen/Qwen3-4B-Instruct-2507>
- <https://huggingface.co/Qwen/Qwen3-1.7B>

Users are responsible for obtaining model weights under the model's applicable
license. CENTL release archives should not silently download model weights.

## Build and run

Build CENTL from source using the normal pinned toolchain:

```sh
make build
```

Install or build `llama.cpp`, place a compatible GGUF model on the local
machine, then run one problem:

```sh
dune exec centl-sci -- \
  --model /path/to/model.gguf \
  'Solve x squared minus 5 x plus 6 equals zero for x.'
```

The model may also be configured with `CENTL_SCI_MODEL`, and an alternate
`llama-cli` path may be configured with `CENTL_SCI_LLAMA_CLI`.

For a reproducible envelope containing the original problem, validated IR,
compiled CENTL request, structured CENTL response, resolution, and provenance:

```sh
dune exec centl-sci -- \
  --model /path/to/model.gguf \
  --json \
  'Convert 100 centimeters to meters.'
```

Ordinary execution requires no network connection after the selected inference
runtime and model artifacts are installed.

## Local model qualification

A model should be evaluated against the checked-in SCi corpus before it is
recommended. The normal local path is:

```sh
make sci-model-test MODEL=/path/to/model.gguf
```

This builds the current CENTL tree and writes `sci-model-report.json`. Useful
configuration variables are:

```sh
make sci-model-test \
  MODEL=/path/to/model.gguf \
  SCI_LLAMA_CLI=/path/to/llama-cli \
  SCI_TIMEOUT=300 \
  SCI_REPORT=reports/qwen3-4b-q4.json
```

The report records the model path and file size, operating-system and machine
identity, every fixture result, validated interpretation, compiled/executed
CENTL result, mismatch reasons, process exit status, and per-case elapsed time.
It is intended to make local developer feedback reproducible rather than
subjective.

The corpus currently includes exact arithmetic, equation paraphrases, irrelevant
wording, exact unit conversion, dimensional mismatch, missing physics data,
out-of-domain questions, contradictions, and prompt-injection-like text embedded
inside a mathematics problem.

For targeted investigation without running the whole corpus:

```sh
python3 scripts/sci-model-eval.py \
  --model /path/to/model.gguf \
  --model-label 'Qwen3-4B-Instruct-2507 Q4' \
  --case embedded_instruction_is_data \
  --case unit_dimension_mismatch \
  --output sci-targeted-report.json
```

The current adapter starts `llama-cli` separately for each submitted problem.
Therefore `elapsed_seconds` in this report includes process startup and model
loading and must **not** be published as interpretation-only latency. Separating
model load time from steady-state interpretation latency requires a persistent
inference adapter or an independently measured runtime and remains follow-up
performance work.

## Mathematical honesty

A successful model parse does not imply a successful mathematical operation.
The final SCi status is derived from CENTL's structured result:

- `established`: CENTL reports a completed computation/transformation, or CENTL
  Physics reports a successful typed result;
- `unresolved`: CENTL returned a residual, unsupported, indeterminate, or other
  non-complete mathematical resolution;
- `unsupported`: the validated SCi IR explicitly declines the problem and no
  CENTL operation is executed;
- `failed`: the CENTL machine interface rejected or failed the request.

CENTL-SCi never converts an `unsupported` CENTL result into a model-generated
numerical answer.

Interpreter assumptions remain separate from CENTL evidence. v0.0.1-Camelus does
not silently invent physical constants, initial conditions, or missing
quantities.

## Security boundary

Treat all three of these as untrusted:

1. the user's problem text;
2. the local model's output;
3. model-generated mathematical expressions.

The first milestone adds no network listener, filesystem tool, arbitrary shell
execution, or model-selected process invocation. The only generated operation
names are admitted by the closed SCi IR. Mathematical requests are then
processed by the existing bounded CENTL/CENTL Physics interfaces.

`exact_expression` is intentionally routed through the existing read-only
`compute` intent, so a generated definition cannot mutate a CENTL session.

## Testing

`tests/test_sci.ml` covers the deterministic boundary without requiring a model
weight download:

- valid IR for each implemented class;
- schema parseability;
- hallucinated operation rejection;
- unknown-field rejection;
- equation separator/injection rejection;
- arbitrary prose rejection;
- exact decimal computation through CENTL;
- exact polynomial equation solving through CENTL;
- exact unit conversion through CENTL Physics;
- no execution for `unsupported`;
- a deterministic local-process end-to-end path from problem text through the
  inference adapter, validated IR, and the actual CENTL kernel;
- offline, single-turn, schema-constrained `llama-cli` argv construction.

Model-quality evaluation is a separate test layer because it is model- and
hardware-dependent. It must record at least:

- model and quantization identity;
- fixture accuracy and schema-valid rate;
- model loading time;
- interpretation latency;
- CENTL execution time;
- verification time where applicable;
- explanation/rendering time;
- peak process memory and model memory;
- CPU/GPU/backend and operating system.

The initial `sci-model-eval.py` report provides fixture accuracy and an honest
whole-process elapsed measurement. It does not yet claim to separate all of the
performance categories above.

Do not publish hardware support or performance numbers until they have actually
been measured.

## Packaging status

The Dune package registers `centl-sci` as a public executable and adds no new
OCaml package dependency; it reuses `unix` and `yojson`, which CENTL already
uses.

The current native release archive scripts still explicitly package only
`centl` and `centl-physics`. Therefore v0.0.1-Camelus should be treated as
source/opam experimental functionality until those archive scripts are
deliberately extended and tested for `centl-sci`. Model weights remain a
separate artifact even after native packaging is added.

## Next interpretation surfaces

Expansion should be fixture-driven rather than breadth-driven. Candidate next
classes are exact differentiation/integration plans and a typed basic-mechanics
IR that maps to the existing `simulate_particle` physics request. Mechanics
must explicitly represent quantities, units, initial state, force model,
integration semantics, assumptions, and requested result before it is admitted.
