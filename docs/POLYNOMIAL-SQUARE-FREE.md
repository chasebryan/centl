# Exact polynomial square-free decomposition

CENTL admits exact characteristic-zero square-free multiplicity decomposition over the deliberately narrow domain `Q[x]` with one explicit variable.

This capability does **not** claim irreducible factorization over `Q`.

## Mathematical contract

For a nonzero admitted polynomial `p in Q[x]`, the operation returns

`p = unit * product_i (factor_i ^ multiplicity_i)`

with the following canonical conventions:

- `unit` is exactly the leading coefficient of the original input `p`;
- every returned `factor_i` is monic and nonconstant;
- every `multiplicity_i` is a positive integer;
- each `factor_i` is square-free;
- different returned factors are pairwise coprime;
- a returned factor represents the product of all irreducible factors of `p` occurring with that exact multiplicity;
- multiplicity groups are returned in increasing multiplicity order.

A multiplicity group can therefore remain reducible. For example, if two distinct irreducible factors both occur with multiplicity two, their product may appear as one square-free multiplicity-2 group.

## Boundary cases

- The zero polynomial is refused. Square-free factorization of zero is not admitted and returns the public error code `zero_polynomial`.
- A nonzero constant `c` returns `unit = c` and an empty factor list.
- An already square-free nonconstant polynomial returns one multiplicity-1 group after canonical monic normalization, with the original leading coefficient retained as `unit`.
- Inputs containing any variable other than the explicitly admitted variable are refused.

## Exact algorithm

The implementation uses the characteristic-zero derivative/GCD decomposition.

For `f = p / lc(p)`:

1. construct the exact derivative `f'` with a charged, cooperative-cancellation-aware pass;
2. compute `c = gcd(f, f')`;
3. compute `w = f / c` by exact polynomial division;
4. for multiplicity `i = 1, 2, ...`, compute `y = gcd(w, c)` and `z = w / y`;
5. retain nonunit `z` as the monic multiplicity-`i` group;
6. update `c = c / y` and `w = y`;
7. terminate only when both residual chains have been exhausted exactly.

Every quotient used by the algorithm is asserted exact. A nonzero remainder in an algebraically required exact quotient is treated as an internal invariant failure rather than silently accepted.

## Resource and cancellation contract

One request-wide division state is shared across the composite operation. The work meter is not reset between derivative construction, repeated GCDs, exact quotient steps, normalization, factor retention, or cancellation checks.

The admitted request is bounded by:

- maximum polynomial terms;
- maximum aggregate exact-bit size;
- maximum polynomial-division steps;
- maximum GCD Euclidean steps;
- maximum square-free factor steps;
- maximum aggregate work;
- maximum serialized result bytes;
- cooperative cancellation.

The canonical mathematics gateway clamps these limits to the existing polynomial and server envelopes. The square-free domain cannot negotiate a larger computational budget than the surrounding mathematics service already permits.

## Version-1 machine protocol

The strict protocol exposes only:

- `capabilities`
- `factorize`

A `factorize` request requires exactly:

- `version = 1`
- optional request `id`
- `action = "factorize"`
- explicit `variable`
- one canonical sparse exact-rational `polynomial`

Unknown fields are refused. There is deliberately no `irreducible`, monomial-order, approximate, numeric, or heuristic control.

The exact result contains:

- `kind = "polynomial_square_free_factorization"`
- exact rational `unit`
- `factor_count`
- an ordered factor list containing exact canonical polynomials and positive multiplicities
- exact provenance

Public refusal codes include `invalid_request`, `invalid_polynomial`, `zero_polynomial`, `resource_limit`, `cancelled`, and `internal_error` where appropriate.

## Public surfaces

The capability is admitted through the same canonical routes as the surrounding exact polynomial stack:

- JSONL mathematics gateway domain `polynomial_square_free`;
- MCP `centl_math` domain `polynomial_square_free` with a closed nested schema.

Both routes inherit the same outer result ceiling and cancellation plumbing.

## Evidence

Admission evidence includes:

- direct reconstruction and multiplicity tests;
- sign and rational-unit normalization tests;
- already-square-free and constant cases;
- zero and mixed-variable refusals;
- work, exact-bit, factor-step, and cancellation boundaries;
- an independently constructed 25-case known-multiplicity oracle that does not reuse CENTL's derivative/GCD decomposition as its oracle;
- an independent 4096-bit exact-root case;
- strict protocol regressions;
- JSONL and MCP capability, result, refusal, nested-schema, result-limit-parity, and deep-cancellation regressions.

## Explicit non-claims

This admission does not claim:

- irreducible factorization over `Q`;
- multivariate square-free factorization;
- positive-characteristic or finite-field square-free factorization;
- factorization of the zero polynomial;
- algebraic root solving;
- approximate or floating-point factorization.

Those are separate mathematical capabilities and require separate admission evidence.
