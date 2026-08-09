# CENTL-SCi

Status: experimental architecture, current released milestone `0.0.1-Camelus`.

**CENTL-SCi means Specific CENTL Interpreter.** It is developed as part of CENTL
under the Free Computation Foundation.

> Free for science.

CENTL-SCi is a local, domain-restricted semantic interpreter for mathematics and
physics. It is not a general-purpose chatbot and it is not a second mathematical
or physics evaluator. Its job is to interpret a scientific problem, produce a
strict validated representation, dispatch that representation to CENTL's
deterministic machinery, and present only what the resulting evidence justifies.

The model is an untrusted semantic interpreter. CENTL remains authoritative for
mathematics, exactness, approximation, bounds, units, solving, physics,
verification, resource limits, provenance, and whether a result is actually
established.

## Trust and presentation boundary

```text
ordinary-language scientific problem
        |
        v
Tier-0 deterministic interpreter --------+
        |                                 |
        | defer                           |
        v                                 |
local semantic model                      |
(untrusted interpreter)                   |
        |                                 |
        +---------------+-----------------+
                        |
                        v
               validated Problem IR
                        |
                   strict lowering
                        |
        +---------------+----------------+
        |                                |
        v                                v
CENTL protocol                    CENTL Physics protocol
(read-only compute)               (typed exact request)
        |                                |
        +---------------+----------------+
                        |
                        v
              structured CENTL evidence
                        |
                        v
             deterministic presentation
                 /        |        \
                /         |         \
           human      --details     --json
```

The presentation layer consumes structured evidence. It does not recompute
mathematics, invoke a language model to rewrite answers, or infer facts absent
from the outcome.

## Current support boundary

The current validated IR deliberately supports four classes:

| Problem class | Domain | Execution |
| --- | --- | --- |
| `exact_expression` | mathematics | read-only CENTL `compute` |
| `polynomial_equation` | mathematics | compile to CENTL `solve` |
| `unit_conversion` | physics | typed CENTL Physics conversion |
| `unsupported` | either/outside scope | no computation |

The equation path inherits CENTL's current admitted solver domain. Unsupported
or unresolved work stays visible internally and is never replaced by a model
guess.

CENTL Physics already implements more mechanics than the current natural-language
SCi contract exposes. A physics feature is promoted into SCi only after its
interpretation schema, lowering, safety boundary, and fixtures are defined.

## Answer-first human output

The default interface is intentionally small. A scientist should need knowledge
of mathematics or physics, not knowledge of CENTL-SCi's implementation terms.

```sh
centl-sci 'What is 0.1 plus 0.2?'
```

```text
3/10
```

```sh
centl-sci 'Solve x squared minus 5x plus 6 equals zero.'
```

```text
x = 2 or x = 3
```

```sh
centl-sci 'Convert 2.5 kilometers to meters.'
```

```text
2500 m
```

Default output contains the answer, conventional units when relevant, and only
scientifically necessary qualifications. It does not print interpreter route
codes, backend/model names, provenance identifiers, schema versions, Problem IR,
verification state codes, or implementation status prefixes.

Exact values remain exact. Human presentation does not turn `3/10` into a
binary-floating approximation. A finite solution set is rendered naturally
rather than exposing protocol syntax.

If CENTL provides a rigorous approximation interval, the human renderer keeps
the qualification visible instead of presenting an unjustified point value.
If CENTL cannot establish a result, the renderer does not manufacture one.

## `--details`

`--details` adds concise scientific metadata without changing the answer:

```sh
centl-sci --details 'Solve x squared minus 5x plus 6 equals zero.'
```

```text
x = 2 or x = 3

Details:
  Exact result
  Variable: x
  Method: polynomial equation solving
  Verified by CENTL
```

The details view intentionally uses scientific language rather than internal
route/status codes.

## `--json`

`--json` remains the machine interface. It preserves the complete structured
outcome used by tests, pipelines, assimilation tooling, and developers,
including interpretation, CENTL response/evidence, status, route, and provenance
where available.

```sh
centl-sci --json 'What is 0.1 plus 0.2?'
```

Human simplification is a presentation change, not an evidence deletion.
`--details` and `--json` are mutually exclusive.

## Live scientific REPL

Running `centl-sci` in an interactive terminal starts the live scientific
problem interpreter:

```text
CENTL-SCi v0.0.1-Camelus
Free for science.

> What is 0.1 plus 0.2?
3/10
> Solve x squared minus 5x plus 6 equals zero.
x = 2 or x = 3
> Convert 2.5 kilometers to meters.
2500 m
>
```

The REPL is not a conversation. Each submitted line is an independent
scientific problem. No language-model conversational memory or implicit
cross-question state is created.

Session controls are deliberately minimal:

- `:help`
- `:details on`
- `:details off`
- `:quit`
- `:exit`
- Ctrl-D / EOF

`--repl` forces the REPL when standard input is not a terminal, which is useful
for integration testing. Bare non-interactive standard input retains one-shot
stdin behavior for compatibility.

An unsupported or failed request does not terminate the REPL; the next problem
is interpreted independently.

## Tier-0 deterministic interpretation

CENTL-SCi first uses a conservative deterministic path where the language is
unambiguous. Current examples include exact arithmetic, exact unit conversion,
symbolic polynomial equations, and a bounded spoken-polynomial form.

For example, both of these are deterministic:

```text
Solve x squared minus 5 x plus 6 equals zero for x.
Solve x squared minus 5x plus 6 equals zero.
```

The second form infers the variable only when the spoken equation begins with an
unambiguous identifier. Ambiguous narrative language still defers to the semantic
layer rather than being aggressively pattern-matched.

## Problem IR v1

The semantic model produces one closed JSON object. A polynomial equation looks
like:

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
  "value": "2.5",
  "from_unit": "km",
  "to_unit": "m"
}
```

The validator rejects unknown or duplicate fields, unknown operations, invalid
class/domain/operation combinations, invalid identifiers, control characters,
oversized fields, and unsafe equation separators. Validation is independent of
the model's claim that its output is valid.

The architectural direction is to make future model generations smaller rather
than larger: predict only semantic information that genuinely requires semantic
interpretation, then let OCaml construct deterministic boilerplate and canonical
Problem IR.

## Local inference boundary

The cold reference adapter targets a local `llama.cpp` `llama-cli`, and a
resident loopback `llama-server` adapter is also supported. No model is bundled
or declared mathematically authoritative.

The local adapters:

- use explicitly configured local executables/model paths;
- constrain model output to the SCi schema;
- use bounded single-problem generation;
- cap problem and model-output bytes;
- parse a complete JSON object rather than scraping prose;
- treat generated fields and expressions as untrusted after generation;
- never let the model select arbitrary shell commands or tools.

A local model may be configured through `--model` / `CENTL_SCI_MODEL`, or a
resident loopback backend through `--server-url` / `CENTL_SCI_SERVER_URL`.

Deterministic Tier-0 problems do not require a model.

## Build and native packages

From a source checkout:

```sh
make build
_build/default/src/sci_main.exe 'What is 0.1 plus 0.2?'
```

The Dune package registers `centl-sci` as a public executable.

The native release builders now include CENTL-SCi alongside CENTL and CENTL
Physics. Unix/macOS archives contain `bin/centl-sci`; Windows archives contain
`centl-sci.exe`. The package smoke tests require exact arithmetic through the
packaged SCi executable before an archive is emitted.

Model weights remain separate artifacts and are never silently downloaded by a
CENTL release package.

## Mathematical honesty

A successful interpretation is not the same thing as a successful mathematical
operation. Internally, CENTL-SCi distinguishes established, unresolved,
unsupported, and failed outcomes. Human presentation translates those states
into useful scientific language without upgrading them.

Examples:

```text
More information is required to solve this problem.
```

or:

```text
CENTL-SCi cannot solve this problem yet.
```

A result that CENTL did not establish is never converted into a confident human
answer merely because the semantic model emitted plausible fields.

Interpreter assumptions remain separate from CENTL evidence. CENTL-SCi does not
silently invent physical constants, initial conditions, or missing quantities.

## Contribution and privacy model

Contribution capture remains opt-in and is **off by default**.

- `diagnostics` captures metadata/errors without raw problem text;
- `examples` may capture raw problem text only after explicit opt-in;
- no mode performs hidden network upload;
- exported data is intended for user review before sharing.

Starting or using the REPL does not change contribution mode and does not make
REPL input training data automatically.

## Portability

Shared SCi runtime and presentation code must remain portable across Linux,
macOS, and Windows. Terminal handling uses ordinary standard input/output and EOF
semantics; the REPL does not depend on a particular shell or ANSI terminal
control sequence.

Platform-specific file-permission operations in the contribution subsystem are
guarded so Windows does not execute unsupported `Unix.fchmod` behavior.

## Validation and assimilation

The deterministic validation layers include:

- IR/schema and execution tests;
- Tier-0 fast-path tests;
- deterministic presentation golden tests;
- one-shot CLI and `--details` tests;
- structured `--json` preservation checks;
- multi-request REPL integration tests;
- `:quit`, `:exit`, and EOF behavior;
- recovery after an unsupported/deferred request;
- contribution privacy tests;
- the existing SCi product/model assimilation harness;
- `scripts/sci-interface-check.py`, which exercises the visible product interface
  and is included in CI and `make sci-assimilate`.

Run the normal deterministic assimilation path with:

```sh
make sci-assimilate
```

A local semantic model can be qualified separately through the existing model
and resident-server assimilation paths. Model performance results must identify
the model/runtime/hardware and must not be generalized beyond what was actually
measured.

## Next interpretation surfaces

Expansion remains fixture-driven rather than chatbot-driven. Candidate next
classes include exact differentiation/integration extraction and typed basic
mechanics slots that lower into existing CENTL Physics operations.

The governing rule remains:

> The model interprets. CENTL computes. CENTL verifies. The interface gives the
> scientist the answer.
