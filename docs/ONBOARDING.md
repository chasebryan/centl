# CENTL contributor onboarding

This is the complete manual learning path for understanding, building, testing,
and changing CENTL. It assumes no prior F* or OCaml experience. AI tools are
optional: every source of truth, command, and readiness exercise needed to work
on the project is listed here.

The repository is the authority when this guide and an external tutorial
disagree. In particular, use the exact versions in
[`toolchain.lock`](../toolchain.lock), not the newest versions from a tutorial.

## What fully onboarded means

A contributor is ready to work independently when they can:

- build CENTL from a clean checkout and run the appropriate test suites;
- explain why `0.1` is exact and why an approximation is displayed as an
  enclosure rather than an unjustified point value;
- trace an expression from the parser, through exact evaluation, to terminal
  or structured JSON output;
- decide whether a change belongs in F*, handwritten OCaml, the C/Arb bridge,
  the Julia laboratory, or documentation;
- change and re-extract the verified F* core without editing generated OCaml;
- add unit, CLI, adversarial, metamorphic, and differential coverage in the
  right places;
- preserve CENTL's numerical and verification contracts during review.

You do not have to learn the entire stack before making a documentation or
small OCaml contribution. Follow the stages in order, and stop at the readiness
gate appropriate to the part of the repository you plan to change.

## The system in one picture

```text
calculator / script / JSON Lines / MCP
                    |
                    v
       handwritten OCaml application
 parser, sessions, limits, protocols,
 rendering, precision orchestration, CLI
                    |
                    v
          extracted F* semantic core
 exact values, algebra, calculus, boundary
 validation, proof-backed algorithms
                    |
                    v
          narrow OCaml -> C boundary
              FLINT / Arb / GMP / MPFR

Independent oracle: Julia + Nemo differential tests
```

The implemented product is currently an exact-first calculator and numerical
language. [`DESIGN_PATH.md`](DESIGN_PATH.md) describes the longer-term direction
toward checking mathematical claims; treat it as product direction, not a claim
that every described capability already exists.

## Stage 0: orient yourself

Read these project documents in order before changing behavior:

1. [`README.md`](../README.md) — product promise and user-facing examples.
2. [`DESIGN_PATH.md`](DESIGN_PATH.md) — intended product direction.
3. [`DESIGN.md`](DESIGN.md) — implemented architecture, ownership, and trust
   boundary.
4. [`NUMERICS.md`](NUMERICS.md) — exactness, approximation, precision, and
   resource contracts.
5. [`VERIFICATION.md`](VERIFICATION.md) — what is proved, assumed, extracted,
   and tested.
6. [`SYNTAX.md`](SYNTAX.md) — complete public language surface.
7. [`PROTOCOL.md`](PROTOCOL.md) and [`MCP.md`](MCP.md) — machine-facing
   interfaces.
8. [`ROADMAP.md`](ROADMAP.md) — current scope and sequencing.

For feature-level work, also use [`MATHEMATICS.md`](MATHEMATICS.md),
[`ALGEBRA.md`](ALGEBRA.md), [`CALCULUS.md`](CALCULUS.md), and
[`ITERATION.md`](ITERATION.md) as the implemented mathematical reference sheets.

If a release or local build is already available, run a few expressions from
the README and inspect their output. Otherwise, return to these after Stage 1:

```sh
./centl '0.1 + 0.2'
./centl '1 / 3'
./centl 'approx(sin(pi / 6), 20)'
./centl 'solve(x^2 - 5*x + 6 = 0, x)'
./centl 'sequence(k^2, k = 1, 5)'
```

Readiness gate: explain the difference among an exact rational, an exact
symbolic value, a real enclosure, a solution set, and an indeterminate result.

## Stage 1: install and prove the baseline

Follow [`CONTRIBUTING.md`](../CONTRIBUTING.md) for operating-system packages and
the checksum-verified F* install. The reproducible development sequence is:

```sh
scripts/bootstrap-opam
eval "$(opam env --switch=centl)"
make test
make quality
```

`make test` verifies and extracts F*, builds the native application, and runs
the normal Dune test suite. `make quality` checks formatting, warnings, the opam
manifest, and agreement among pinned versions. Neither quality target rewrites
source files.

Install the independent mathematical oracle once:

```sh
julia --startup-file=no --project=lab/julia \
  -e 'using Pkg; Pkg.instantiate()'
make differential-test
```

Run the full defensive suite before high-risk numerical, parser, native, or
protocol work:

```sh
make hardening-test
```

Useful references:

- [opam usage](https://opam.ocaml.org/doc/Usage.html) and
  [switches](https://opam.ocaml.org/doc/man/opam-switch.html)
- [Dune documentation](https://dune.readthedocs.io/en/stable/) and its
  [mental model](https://dune.readthedocs.io/en/stable/explanation/mental-model.html)
- [GNU Make manual](https://www.gnu.org/software/make/manual/)
- [Pro Git](https://git-scm.com/book/en/v2) if Git itself is new

Readiness gate: a clean `make test` and `make quality`, followed by a successful
evaluation through the locally built `./centl` launcher.

## Stage 2: learn the OCaml used by CENTL

OCaml is the host language. It owns parsing, sessions, iteration orchestration,
resource limits, the CLI, history, JSON Lines, MCP, and the bridge to extracted
semantics and native numerics.

### Required OCaml concepts

Learn these in this order:

1. expressions, immutable `let` bindings, functions, recursion, and pipelines;
2. tuples, records, variants, pattern matching, lists, arrays, and `option`;
3. modules, signatures (`.mli`), namespaces, and compilation units;
4. labelled and optional arguments;
5. exceptions, `result`, mutable references, hash tables, and queues;
6. bytes versus strings and UTF-8 boundary awareness;
7. higher-order functions and tail recursion;
8. foreign function declarations for the C boundary.

Use the free official material:

- [OCaml learning hub](https://ocaml.org/learn)
- [Tour of OCaml](https://ocaml.org/docs/tour-of-ocaml)
- [OCaml 4.14 reference manual](https://ocaml.org/manual/4.14/index.html)
- [Labelled and optional arguments](https://ocaml.org/docs/labels)
- [Interfacing C with OCaml](https://ocaml.org/manual/4.14/intfc.html)
- [Zarith 1.14 API](https://ocaml.org/p/zarith/1.14/doc/index.html) for exact
  integers and rationals
- [Yojson 2.2.2 API](https://ocaml.org/p/yojson/2.2.2/doc/index.html) for JSON

### Read CENTL's OCaml in this order

1. [`centl_syntax.ml`](../src/ocaml/centl_syntax.ml) — small catalogue of public
   syntax, examples, and completion names.
2. [`centl_request_queue.mli`](../src/ocaml/centl_request_queue.mli) and
   [`centl_request_queue.ml`](../src/ocaml/centl_request_queue.ml) — compact
   interface/implementation example with bounded state.
3. [`centl_history.ml`](../src/ocaml/centl_history.ml) — persistence, validation,
   locking, and bounded storage.
4. [`centl_parser.ml`](../src/ocaml/centl_parser.ml) — tokens, source spans,
   precedence, statements, and located errors.
5. [`centl_iteration.ml`](../src/ocaml/centl_iteration.ml) — finite iteration,
   recurrences, budgets, and stack-aware execution.
6. [`centl_protocol.ml`](../src/ocaml/centl_protocol.ml) — a small structured
   interface around the engine.
7. [`centl_engine.ml`](../src/ocaml/centl_engine.ml) — the main bridge; read one
   feature vertically rather than attempting the whole file at once.
8. [`main.ml`](../src/ocaml/main.ml) — CLI flags, input modes, REPL behavior, and
   top-level error handling.

Readiness exercise: add a harmless completion or syntax example, add/update its
test, run the focused test and `make quality`, and explain every line of the
diff. Revert the exercise if it is not a real product improvement.

## Stage 3: understand Dune and the test ecosystem

CENTL uses Dune to compile OCaml, link foreign stubs, format source, and run
several kinds of tests.

Required references:

- [Dune tests](https://dune.readthedocs.io/en/stable/tests.html)
- [Dune Cram tests](https://dune.readthedocs.io/en/stable/reference/cram.html)
- [Dune foreign stubs](https://dune.readthedocs.io/en/stable/reference/foreign-stubs.html)
- [Alcotest 1.9.1 API](https://ocaml.org/p/alcotest/1.9.1/doc/alcotest/Alcotest/index.html)
- [QCheck 0.91 API](https://ocaml.org/p/qcheck-core/0.91/doc/qcheck-core/QCheck/index.html)
- [OCamlFormat 0.29.0 getting started](https://ocaml.org/p/ocamlformat/0.29.0/doc/getting_started.html)

Study [`src/dune`](../src/dune), [`src/native/dune`](../src/native/dune), and
[`tests/dune`](../tests/dune). Then map the suites:

- [`test_centl.ml`](../tests/test_centl.ml) covers the general semantic surface.
- [`test_iteration.ml`](../tests/test_iteration.ml) and
  [`test_sequence.ml`](../tests/test_sequence.ml) cover bounded iteration.
- [`test_adversarial.ml`](../tests/test_adversarial.ml) attacks resource and
  numerical boundaries.
- [`test_history.ml`](../tests/test_history.ml) and
  [`test_request_queue.ml`](../tests/test_request_queue.ml) cover stateful host
  infrastructure.
- [`cli.t`](../tests/cli.t) and [`installer.t`](../tests/installer.t) are
  end-to-end Cram transcripts.
- [`tests/corpus/`](../tests/corpus) contains deterministic malformed and edge
  inputs.
- [`tests/hardening/`](../tests/hardening) contains fuzz-corpus, metamorphic,
  sanitizer, and performance checks.

Focused loops after the baseline has passed include:

```sh
dune exec tests/test_sequence.exe
dune runtest tests/cli.t
make adversarial-test
make fuzz-test
make metamorphic-test
make performance-test
```

Use `make format-fix` only when you intend to rewrite formatting, and inspect
its diff afterward.

Readiness exercise: find one public behavior in `tests/cli.t`, identify the unit
test beneath it, and describe what the Cram test catches that the unit test does
not.

## Stage 4: learn F* and the verified core

F* is a proof-oriented functional language. CENTL uses it for the semantic
model and mathematical operations whose invariants should be explicit and
machine checked. F* asks Z3 to discharge verification conditions, then extracts
executable OCaml.

No previous proof-assistant experience is required. Follow the official free
[Proof-Oriented Programming in F*](https://fstar-lang.org/tutorial/book/index.html)
in this order:

1. [How to use the book](https://fstar-lang.org/tutorial/book/structure.html)
2. [Getting off the ground](https://fstar-lang.org/tutorial/book/part1/part1_getting_off_the_ground.html)
3. [Total functions and refinement types](https://fstar-lang.org/tutorial/book/part1/part1.html)
4. [Inductive types](https://fstar-lang.org/tutorial/book/part1/part1_inductives.html)
5. [Lemmas and induction](https://fstar-lang.org/tutorial/book/part1/part1_lemmas.html)
6. [Execution and extraction](https://fstar-lang.org/tutorial/book/part1/part1_execution.html)
7. [How SMT-based verification works](https://fstar-lang.org/tutorial/book/under_the_hood/under_the_hood.html)

When a proof fails, use the official Z3 material to understand the solver rather
than treating solver settings as magic:

- [Z3 logic introduction](https://microsoft.github.io/z3guide/docs/logic/intro/)
- [Arithmetic theories](https://microsoft.github.io/z3guide/docs/theories/Arithmetic/)
- [Quantifiers](https://microsoft.github.io/z3guide/docs/logic/Quantifiers/)

### Read CENTL's F* in this order

1. [`Centl.Gcd.fst`](../src/fstar/Centl.Gcd.fst) — the smallest complete local
   example of definitions, specifications, verification, and extraction.
2. The type and value definitions near the beginning of
   [`Centl.Core.fst`](../src/fstar/Centl.Core.fst).
3. Rational normalization and arithmetic.
4. Dyadic bounds and outward-rounded enclosure construction.
5. symbolic expression substitution and variable handling;
6. algebra, differentiation, integration, solving, validation, and rendering.

Use tests and documentation to choose a vertical slice before reading the
large core file. For example, trace rational addition or differentiation from a
test, into OCaml engine dispatch, into the F* definition, then back through the
renderer.

### The only safe F* edit loop

```sh
make verify
make extract
git diff -- src/generated
make native-test
make quality
```

Never hand-edit [`src/generated/`](../src/generated). Those files are a checked-in
build artifact produced from F*. An F* change includes the reviewed generated
diff. CI re-extracts with the pinned verifier and rejects a stale snapshot.

The adapters in [`src/runtime/`](../src/runtime) map the F* extraction runtime
to OCaml and Zarith. They are part of the executable trust path and should stay
small.

Readiness exercise: state a simple invariant in `Centl.Gcd.fst`, verify it,
inspect its extracted OCaml, and explain which fact was proved versus merely
tested. Do not keep a tutorial-only change.

## Stage 5: learn exact and rigorous numerics

CENTL's core promise is not just “many digits.” It distinguishes exact values
from certified enclosures, rounds bounds outward, and refuses to print digits
that are not justified.

Learn these concepts:

- arbitrary-precision integers and normalized rational numbers;
- exact symbolic values versus numeric approximations;
- interval/ball arithmetic and outward rounding;
- absolute versus relative precision and cancellation;
- real versus complex enclosures;
- indeterminate values and explicit resource exhaustion;
- why converting an enclosure to a floating-point midpoint can destroy the
  public contract.

Authoritative references:

- [FLINT 3.0.1 manual](https://flintlib.org/download/flint-3.0.1.pdf)
- [Using Arb ball arithmetic](https://flintlib.org/doc/using.html)
- [Arb real-ball API](https://flintlib.org/doc/arb.html) and
  [Arb documentation index](https://flintlib.org/doc/index_arb.html)
- [Calcium introduction](https://flintlib.org/doc/introduction_calcium.html) and
  [`ca` exact-number API](https://flintlib.org/doc/ca.html)
- [GMP 6.3 manual](https://gmplib.org/manual/index)
- [MPFR 4.2.2 manual](https://www.mpfr.org/mpfr-current/)

Trace one native call through all three layers:

1. its declaration in [`centl_arb.ml`](../src/native/centl_arb.ml);
2. its OCaml use in [`centl_engine.ml`](../src/ocaml/centl_engine.ml);
3. its implementation and allocation/error cleanup in
   [`centl_arb_stubs.c`](../src/native/centl_arb_stubs.c).

The [OCaml C interface manual](https://ocaml.org/manual/4.14/intfc.html) is
required reading before editing the stubs. Pay particular attention to GC
roots, ownership, blocking sections, exception boundaries, and allocation
failure paths.

If C is new, first complete the relevant parts of the free
[GNU C Language Introduction and Reference Manual](https://www.gnu.org/software/c-intro-and-ref/manual/html_node/index.html).
Use the [SEI CERT C Coding Standard](https://wiki.sei.cmu.edu/confluence/display/c/SEI+CERT+C+Coding+Standard)
as the defensive reference for native-boundary work.

Readiness exercise: trace `approx(sin(pi / 6), 20)` and explain where precision
is requested, where outward bounds are established, how failure is classified,
and why the displayed endpoints are safe.

## Stage 6: understand parsing, scope, and resource limits

The handwritten parser is inside the trusted application boundary. A parser
bug can change the meaning of user mathematics before verified semantics sees
it, so parser work requires semantic and adversarial tests.

Read in this order:

1. the grammar and precedence contract in [`SYNTAX.md`](SYNTAX.md);
2. tokens, source locations, and precedence in
   [`centl_parser.ml`](../src/ocaml/centl_parser.ml);
3. immutable definitions, functions, lookup, substitution, and rendering in
   [`centl_engine.ml`](../src/ocaml/centl_engine.ml);
4. finite iteration budgets in
   [`centl_iteration.ml`](../src/ocaml/centl_iteration.ml);
5. parser and multiline cases in [`tests/`](../tests) and
   [`tests/corpus/`](../tests/corpus).

For every new syntax form, test at least precedence, whitespace, multiline
input, source locations, malformed input, nesting, budget limits, terminal
output, and structured output. Avoid unbounded recursion on user-controlled
input.

Readiness exercise: trace a multiline function definition and one malformed
variant from bytes to token, AST/statement, engine evaluation, and caret error.

## Stage 7: understand machine protocols and MCP

CENTL's human and machine interfaces must expose the same typed mathematical
result. JSON must not silently collapse exact values or enclosures into ordinary
floating-point numbers.

Start with [`PROTOCOL.md`](PROTOCOL.md),
[`centl_protocol.ml`](../src/ocaml/centl_protocol.ml), [`MCP.md`](MCP.md), and
[`centl_mcp.ml`](../src/ocaml/centl_mcp.ml). Then read the request queue because
long-running MCP work depends on bounded scheduling and cancellation:
[`centl_request_queue.mli`](../src/ocaml/centl_request_queue.mli).

Protocol references:

- [JSON-RPC 2.0 specification](https://www.jsonrpc.org/specification)
- [JSON Lines format](https://jsonlines.org/)
- [MCP server overview](https://modelcontextprotocol.io/specification/2025-11-25/server/index)
- [MCP tools](https://modelcontextprotocol.io/specification/2025-11-25/server/tools)
- [MCP cancellation](https://modelcontextprotocol.io/specification/2025-11-25/basic/utilities/cancellation)
- [MCP schema](https://modelcontextprotocol.io/specification/2025-11-25/schema)

Manual JSON Lines smoke test:

```sh
printf '%s\n' '{"version":1,"expression":"0.1 + 0.2"}' | ./centl --serve
```

Readiness exercise: explain how invalid JSON, an invalid expression, a limit
failure, cancellation, and a valid exact result differ on the wire. Confirm
each case is bounded and machine distinguishable.

## Stage 8: understand the independent Julia/Nemo oracle

The Julia laboratory is intentionally independent of CENTL's F*/OCaml
implementation. It catches shared-assumption bugs that ordinary example tests
may miss. It is required before merging changes to mathematical behavior.

Learn only the Julia needed for the laboratory:

- [Julia getting started](https://julialang.org/learning/getting-started/)
- [Julia 1.x manual: getting started](https://docs.julialang.org/en/v1/manual/getting-started/)
- [Julia modules](https://docs.julialang.org/en/v1/manual/modules/)
- [Pkg environments](https://pkgdocs.julialang.org/v1/environments/)
- [Nemo documentation](https://nemocas.github.io/Nemo.jl/stable/)
- [Nemo developer introduction](https://nemocas.github.io/Nemo.jl/stable/developer/introduction/)

Then read [`lab/julia/README.md`](../lab/julia/README.md),
[`Project.toml`](../lab/julia/Project.toml), and
[`differential.jl`](../lab/julia/differential.jl). The checked-in manifest pins
the oracle environment. Random cases are seeded and must remain reproducible.

Readiness exercise: add a temporary deterministic oracle case, observe both
sides' structured values, force a harmless mismatch, and understand the failure
report. Remove the forced mismatch afterward.

## Stage 9: hardening, packaging, and release work

Read [`PERFORMANCE.md`](PERFORMANCE.md), [`INSTALL.md`](INSTALL.md),
[`TOOLCHAIN.md`](TOOLCHAIN.md), the root [`Makefile`](../Makefile), and
[`scripts/`](../scripts) before changing build or release behavior.

The defensive suites have different jobs:

- adversarial tests target known dangerous boundaries;
- the deterministic fuzz corpus mutates parsers and protocols;
- metamorphic tests check relationships that should remain true across inputs;
- native sanitizers look for C memory and undefined-behavior failures;
- performance smoke tests protect explicit resource envelopes;
- differential tests compare mathematical results with an independent system.

Release artifacts use exact native dependency pins, while ordinary local
development may use compatible distribution packages. Do not change a version
in only one file: update the canonical lock and all intentionally mirrored
locations, then run `scripts/check-toolchain-pins` through `make quality`.

The project is licensed
[AGPL-3.0-or-later](https://www.gnu.org/licenses/agpl-3.0.html). Read the license
and preserve SPDX notices when adding source files or redistributing modified
network-accessible versions.

Readiness gate: explain what each CI/release job protects and successfully run
the local suite appropriate to the proposed packaging or dependency change.

## Repository map

| Path | Responsibility | Change risk |
| --- | --- | --- |
| [`src/fstar/`](../src/fstar) | Verified semantic model and mathematical operations | High: proof and semantic contract |
| [`src/generated/`](../src/generated) | Checked-in F* extraction output | Generated; never edit manually |
| [`src/runtime/`](../src/runtime) | F* extraction runtime adapters | High: execution/trust boundary |
| [`src/ocaml/`](../src/ocaml) | Parser, engine bridge, sessions, limits, protocols, CLI | Medium to high by feature |
| [`src/native/`](../src/native) | OCaml/C/Arb foreign interface | High: memory and numeric safety |
| [`tests/`](../tests) | Unit, Cram, adversarial, corpus, hardening tests | Required evidence |
| [`lab/julia/`](../lab/julia) | Independent Nemo oracle | Keep independent and deterministic |
| [`docs/`](.) | Product, syntax, numerical, protocol, and verification contracts | User-visible contract |
| [`scripts/`](../scripts) | Bootstrap, pin checks, sanitizers, packaging | High: developer/release integrity |
| [`.github/workflows/`](../.github/workflows) | CI and release enforcement | High: repository-wide safety net |

## Route a change before writing it

| Change | Primary location | Minimum validation |
| --- | --- | --- |
| Documentation only | `README.md`, `docs/` | `make quality` where toolchain is available; review links/examples |
| CLI, REPL, history, queue | `src/ocaml/`, focused tests | `make native-test`, `make quality` |
| Parser or syntax | parser, syntax catalogue, docs, unit/Cram/corpus tests | `make native-test`, `make fuzz-test`, `make quality` |
| Exact semantic or algebraic behavior | `src/fstar/`, generated snapshot, tests | `make test`, `make differential-test`, `make quality` |
| Approximation/native numerics | F* plus `src/native/` as needed | `make test`, `make hardening-test`, `make differential-test`, `make quality` |
| JSON Lines or MCP | protocol/MCP/queue, docs, corpus tests | `make native-test`, `make fuzz-test`, `make adversarial-test`, `make quality` |
| Dependency or toolchain pin | `toolchain.lock` and intentional mirrors | clean bootstrap/build, `make test`, `make quality` |
| Packaging/release | scripts, installer tests, workflows, release docs | installer/package smoke tests plus complete build |

“Minimum” is not a ceiling. Run the broader suite whenever a change crosses
layers or could affect mathematical correctness, trust boundaries, memory
safety, untrusted input, or resource use.

## A reliable vertical-slice workflow

For any behavior change:

1. Write down the user-visible input, typed result, rendering, error behavior,
   and resource limit before editing.
2. Locate an existing neighboring test and trace it through the system.
3. Choose the owning layer using the routing table above.
4. Add the smallest failing test at the lowest useful layer.
5. Implement the change without weakening the numerical or verification
   contract.
6. If F* changed, verify, extract, and review generated output.
7. Add an end-to-end test for user-visible behavior and a structured-protocol
   test where applicable.
8. Add adversarial, metamorphic, sanitizer, performance, or differential
   evidence when the risk calls for it.
9. Update every affected contract document and syntax example.
10. Run focused checks, then the required full targets from the routing table.
11. Review `git diff` for generated noise, accidental formatting, secrets,
    temporary fixtures, and unrelated user changes.

## Common failures and where to look

| Symptom | First checks |
| --- | --- |
| `dune` or an OCaml package is missing | Run `eval "$(opam env --switch=centl)"`; inspect `opam switch` and `centl.opam` |
| F* cannot find the expected Z3 | Recheck the pinned F* install in `CONTRIBUTING.md`; use `fstar.exe --locate_z3 4.13.3` |
| Generated files changed unexpectedly | Confirm the pinned F* version, run `make extract` once, and inspect only `src/generated/` |
| Native link/load error for FLINT/GMP/MPFR | Check `pkg-config`, installed development/runtime libraries, `src/native/dune`, and platform loader paths |
| F* proof times out | Reduce to the failing definition, inspect the verification condition, relevant refinements, quantifiers, and solver limits; do not simply raise limits first |
| Correct-looking numeric point disagrees with the contract | Check whether the value should be exact or an outward enclosure; never discard the radius/bounds |
| Cram output changed | Decide whether behavior or only presentation changed; inspect terminal color, source locations, ordering, and protocol stability |
| Fuzz/metamorphic failure | Preserve the input and seed, minimize the case, then add it to the deterministic corpus or focused unit tests |
| Differential disagreement | Compare typed exact structures before text rendering; check whether CENTL or the oracle is outside its supported domain |
| Slow or nonterminating input | Identify the explicit budget, recursion depth, queue bound, or native-call limit before optimizing |

## A low-risk first-contribution ladder

1. Fix an inaccurate explanation or add a missing tested example in `docs/`.
2. Improve a diagnostic or completion in handwritten OCaml with a focused test.
3. Add a deterministic regression case for an already-understood behavior.
4. Make a bounded parser, history, queue, or protocol improvement.
5. Add a proved helper or small semantic change in F* and inspect extraction.
6. Change rigorous numerical or native behavior only after completing the
   numerics and FFI readiness exercises.

## Non-negotiable review checklist

- Decimal input never enters binary floating-point implicitly.
- Exact results stay exact; approximation is visible and intentional.
- Enclosures remain enclosures and are rounded outward.
- No displayed digit claims more precision than has been established.
- Human and machine interfaces represent the same typed result.
- Invalid or oversized user input is rejected predictably and with bounded
  resource use.
- Parser, protocol, queue, and history state have explicit size/depth limits.
- F* assumptions remain reported as errors and generated OCaml is current.
- C stubs preserve OCaml GC rules and native allocation ownership on every path.
- Tests are deterministic; randomized failures include reproducible seeds.
- The Julia oracle remains implementation-independent.
- Public behavior changes update syntax, protocol, numerical, or verification
  documentation as appropriate.
- No generated artifact, formatter rewrite, pin update, or unrelated worktree
  change is included accidentally.

## Glossary

**Exact value**
: A value represented without approximation, such as an arbitrary-precision
  integer, normalized rational, or supported symbolic expression.

**Enclosure**
: A certified interval or ball known to contain the mathematical value. Its
  width records uncertainty.

**Outward rounding**
: Rounding a lower bound downward and an upper bound upward so the true value
  remains contained.

**Refinement type**
: A type restricted by a logical predicate, allowing F* to verify properties of
  values accepted or returned by a function.

**Verification condition**
: A logical obligation produced by F* and discharged by its type checker and
  SMT solver.

**Extraction**
: Translation of verified F* definitions into executable OCaml. Extraction
  preserves the program, not a runtime proof checker.

**Trusted boundary**
: Code or assumptions that verification relies on but does not itself prove,
  including parsing, runtime adapters, native libraries, and parts of the host
  application. See [`VERIFICATION.md`](VERIFICATION.md) for the exact boundary.

**Differential test**
: A test that evaluates the same mathematical case in CENTL and an independent
  implementation, then compares structured results.

**Metamorphic test**
: A test of a relation between multiple executions, such as an identity or an
  invariance, when a complete expected output is inconvenient.

## Final readiness checklist

Before claiming full-stack readiness, complete all of the following:

- [ ] Read the project contract documents in Stage 0.
- [ ] Bootstrap the pinned OCaml/F*/native toolchain from a clean checkout.
- [ ] Pass `make test` and `make quality`.
- [ ] Complete the OCaml, Dune/testing, and F* readiness exercises.
- [ ] Trace one exact and one approximate expression end to end.
- [ ] Trace one malformed parser input and one machine-protocol error.
- [ ] Explain the verification and native trust boundaries.
- [ ] Instantiate and run the Julia/Nemo differential suite.
- [ ] Run the hardening suite relevant to the target contribution.
- [ ] Make one small reviewed change using the vertical-slice workflow.
- [ ] Demonstrate that the change preserves the non-negotiable checklist.

Once these boxes are complete, a contributor can work on CENTL manually without
depending on an AI subscription or undocumented project knowledge.
