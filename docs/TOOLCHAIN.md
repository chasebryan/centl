# Toolchain

CENTL uses separate production, verification, and numerical-laboratory tools.
Exact version pins belong in build configuration as implementation begins.

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

The exact F* verification and FLINT enclosure smoke tests will live in the
repository once their source directories are created.
