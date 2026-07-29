# Toolchain

CENTL uses separate production, verification, and numerical-laboratory tools.
The canonical pins are recorded in [`toolchain.lock`](../toolchain.lock). The
first exact-calculator slice is verified and tested with these versions:

| Tool | Version |
| --- | --- |
| F* | 2026.07.05 (`2173bc4`) |
| Z3 | 4.13.3 |
| OCaml | 4.14.1 |
| Dune | 3.24.1 |
| Zarith | 1.14 |
| Yojson | 2.2.2 |
| FLINT / Arb | 3.0.1 |
| Alcotest | 1.9.1 |
| QCheck | 0.91 |

## Production and verification

- F* for executable definitions and proofs.
- The Z3 version bundled with the selected F* release.
- OCaml 4.14 and OPAM for extraction and the application host.
- Dune for OCaml builds.
- Zarith for extracted unbounded integers.
- FLINT 3, including Arb and Calcium, with GMP and MPFR.
- A C compiler and GNU Make for native bindings.

The development OPAM switch is named `centl`.

Activate it in a shell with:

```sh
eval "$(opam env --switch=centl)"
```

## Numerical laboratory

- Julia installed through Juliaup.
- Nemo for FLINT, Arb, and Calcium access.

The laboratory is an independent oracle. Production code must not depend on a
Julia environment or Julia-generated formatting.

## Smoke checks

```sh
fstar.exe --version
"$(fstar.exe --locate_z3 4.13.3)" --version
ocamlopt -version
dune --version
pkg-config --modversion flint
julia --version
julia -e 'using Nemo; println(Nemo.NEMO_VERSION); println(sqrt(ArbField(256)(2)))'
```

`make test` verifies the F* core, builds the native FLINT/Arb binding, and runs
exact, symbolic, rigorous-containment, CLI, JSON, and property tests.
