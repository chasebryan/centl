# Julia/Nemo differential laboratory

This directory is an independent numerical oracle for CENTL. It is not a
runtime dependency and must not define production semantics or formatting.

Run the deterministic differential suite from the repository root after
instantiating its pinned environment and building CENTL:

```sh
julia --project=lab/julia -e 'using Pkg; Pkg.instantiate()'
julia --project=lab/julia lab/julia/differential.jl
```

Set `CENTL_BIN` to exercise a packaged executable instead of the repository
launcher. The suite reads CENTL's structured JSON numerators and denominators,
then compares them with independently computed Nemo integers and rationals. It
covers finite sums and products, empty ranges, rational telescoping products,
exact sequences and recurrences, polynomial integrals, and exact real-quadratic
solution components. Quadratic cases independently check the normalized center
and radicand, both Vieta identities, and invariance under nonzero equation
scaling across deterministic and seeded generated cases.
