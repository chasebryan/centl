# Performance contract

CENTL keeps its default path local and native: the command-line program starts
without a VM or network service, exact arithmetic uses Zarith and the extracted
core, and explicit real approximation crosses one narrow FLINT/Arb boundary.
The persistent JSONL and MCP modes amortize process startup when a caller has a
stream of requests. Resource ceilings bound source size, expression size,
integer iteration, exact-result growth, rendering, and Arb working precision.

`make performance-test` runs a single-threaded, deterministic smoke benchmark
against the built native development binary. It is a regression gate, not a
release-profile microbenchmark. It measures:

| Workload | Operations | Default wall-clock budget |
| --- | ---: | ---: |
| Median native process startup and `1 + 1` | 5 samples | 750 ms |
| Mixed exact evaluation | 280 | 5,000 ms |
| Rigorous 30-digit Arb evaluation | 60 | 5,000 ms |
| Persistent JSONL evaluation | 500 | 5,000 ms |

These deliberately loose budgets catch catastrophic regressions, accidental
quadratic behavior, and broken low-end usability without pretending that CI is
a laboratory benchmark. Builds, F* verification, filesystem cache warmup, and
network activity are excluded. The first process invocation is a warmup; the
reported startup value is the median of the next five. Each in-process batch
compacts the OCaml heap before timing and consumes every result.

The default gate is calibrated on native x86-64 Linux CI and uses only portable
OCaml/Unix clocks and process APIs. Other native architectures run the same
workload; emulators, heavily power-limited systems, and unusually slow machines
should use the documented budget scale rather than weakening the cases. The
smoke test intentionally does not gate peak RSS: portable, repeatable
process-memory accounting is not available across Linux, macOS, and Windows.
Memory is instead bounded structurally by the engine's source, node, exact-bit,
iteration, result-byte, binding, and Arb-precision ceilings; platform-specific
profilers can measure RSS when investigating a particular deployment.

Run the smoke benchmark with the pinned toolchain:

```sh
make build
make performance-test
```

Slower architectures or emulators can multiply all budgets while preserving
the workload and report format:

```sh
CENTL_PERF_BUDGET_SCALE=3 make performance-test
```

Individual millisecond budgets can be set with
`CENTL_PERF_STARTUP_MS`, `CENTL_PERF_EXACT_MS`, `CENTL_PERF_ARB_MS`, and
`CENTL_PERF_PROTOCOL_MS`. Fast-validation CI uses the defaults. Benchmark
numbers are guardrails, not a promise that unrelated machine load cannot affect
wall-clock time; performance investigations should record the CPU, OS, OCaml,
FLINT, compiler, power mode, and several repeated runs.

For applications, keep a JSONL or MCP process alive, send explicit per-request
limits, and request only the decimal precision actually needed. This avoids
repeated process startup and prevents one calculation from consuming work
intended for the rest of the machine.
