# Exact rational polynomial factorization

CENTL admits exact irreducible factorization of nonzero univariate polynomials over `Q[x]` with one explicit variable.

This capability is distinct from the older expression-level `Factor(...)` rewrites, which intentionally cover only a few elementary identities. It is also distinct from square-free multiplicity decomposition: every successful factor returned here is irreducible over `Q`, not merely square-free.

## Mathematical contract

For a nonzero admitted polynomial `p in Q[x]`, a successful result returns

`p = unit * product_i (factor_i ^ multiplicity_i)`

with these canonical conventions:

- `unit` is exactly the leading coefficient of the original input;
- every `factor_i` is monic, nonconstant, and irreducible in `Q[x]`;
- every `multiplicity_i` is a positive integer;
- factors are deterministic and sorted canonically;
- identical irreducible factors are combined into one multiplicity entry;
- multiplying the returned factors and unit reconstructs the original input exactly.

A successful result is classified `exact` only after CENTL has independently exact-divided and reconstructed the factorization.

## Boundary cases

- The zero polynomial is refused with the public code `zero_polynomial`; it has no finite irreducible factorization.
- A nonzero constant `c` returns `unit = c` and no factors.
- A nonconstant irreducible polynomial returns one multiplicity-1 factor equal to its monic normalization.
- Inputs containing any variable other than the explicitly admitted variable are refused.
- Resource exhaustion returns `resource_limit`, never a partial factorization mislabeled complete.

## Exact algorithm

The production algorithm is a deterministic bounded form of Kronecker factorization.

### 1. Primitive integer normalization

CENTL converts the rational input to a primitive integer polynomial using exact denominator LCM and coefficient GCD operations. The primitive polynomial is normalized to positive leading coefficient. This step uses Gauss's lemma: reducibility over `Q[x]` is equivalent to reducibility of the primitive integer polynomial over `Z[x]`.

The public result is normalized independently to monic rational factors, so the original leading coefficient becomes the canonical scalar `unit`.

### 2. Complete divisor/interpolation search

For a primitive integer polynomial `F` of degree `n`, CENTL searches possible factor degrees `d = 1 .. floor(n/2)`.

For each degree `d`:

1. choose `d+1` distinct integer evaluation points where `F(x) != 0`;
2. enumerate every signed integer divisor of each exact value `F(x)`;
3. enumerate the Cartesian product of those divisor choices;
4. interpolate the unique degree-at-most-`d` rational polynomial through each value tuple;
5. retain only primitive integer polynomials of degree exactly `d` with positive leading coefficient;
6. exact-divide `F` by each retained candidate.

If `G in Z[x]` of degree `d` divides `F`, then `G(x)` divides `F(x)` at every selected integer point. Its `d+1` values therefore appear in the enumerated divisor tuples, and interpolation reconstructs `G` exactly. Consequently, exhausting the search through degree `floor(n/2)` proves that the remaining polynomial is irreducible over `Z`, and therefore over `Q` by Gauss's lemma.

When a nontrivial exact divisor is found, CENTL recursively factors both divisor and quotient. Repeated irreducible factors are combined deterministically at the end.

### 3. Independent reconstruction

Before a successful result crosses a public boundary, CENTL:

- verifies every retained candidate by exact polynomial division;
- verifies that every recursive terminal factor reached a fully exhausted Kronecker search or has degree one;
- normalizes each terminal factor to monic form;
- reconstructs `unit * product(factor_i ^ multiplicity_i)` exactly and compares it with the original input.

Any invariant violation is `internal_error`, never a successful factorization.

## Resource and cancellation contract

Kronecker factorization is deliberately allowed to be expensive, but never unbounded.

One request-wide state accounts for validation, primitive normalization, evaluation, divisor trials, divisor-list retention, Cartesian-product search, interpolation, exact division, recursion, factor normalization, reconstruction, and cancellation checks.

The admitted request is bounded by explicit limits including:

- maximum input terms;
- maximum polynomial degree;
- maximum aggregate exact-bit size;
- maximum evaluation-point search;
- maximum trial divisors per integer value;
- maximum retained divisors per evaluation value;
- maximum interpolation candidates;
- maximum recursion/factor count;
- maximum polynomial-division steps;
- maximum aggregate work;
- maximum serialized result bytes;
- cooperative cancellation.

If an exact divisor enumeration cannot be completed inside its limit, the whole request returns `resource_limit`. CENTL must never infer irreducibility from an incomplete divisor search.

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

Unknown fields are refused. There is no approximate, heuristic, probabilistic, monomial-order, backend-selection, or partial-factorization control in version 1.

The exact result contains:

- `kind = "polynomial_rational_factorization"`
- exact rational `unit`
- `factor_count`
- canonically ordered exact factors with positive multiplicities
- an explicit `complete = true`
- exact provenance

Public refusal codes include `invalid_request`, `invalid_polynomial`, `zero_polynomial`, `resource_limit`, `cancelled`, and `internal_error` where appropriate.

## Public surfaces

Admission requires both canonical routes:

- JSONL mathematics gateway domain `polynomial_factorization`;
- MCP `centl_math` domain `polynomial_factorization` with a closed nested schema.

Both routes inherit the surrounding polynomial/server result ceiling and cancellation plumbing.

## Evidence required before promotion

The admission ladder must include:

- exact reconstruction for every successful test vector;
- reducible and irreducible polynomials across degrees greater than two;
- repeated irreducible factors and non-monic rational inputs;
- rational factors whose primitive integer representatives are non-monic;
- constant and zero boundary cases;
- deterministic factor ordering;
- explicit divisor-search, candidate-search, degree, exact-bit, output, and cancellation refusals;
- independently constructed generated products with known irreducible factors;
- differential comparison against an independent open exact implementation such as FLINT for representative cases;
- permanent regressions for every discovered false-factor or false-irreducibility bug;
- JSONL and MCP capability, exact-result, strict-schema, refusal, result-limit-parity, and deep-cancellation tests.

## Explicit non-claims

This admission does not claim:

- multivariate factorization;
- finite-field factorization as a public domain;
- algebraic-extension factorization;
- approximate or floating-point factorization;
- heuristic partial factorization;
- fast asymptotic performance competitive with modular/Hensel/van-Hoeij algorithms.

A future implementation may replace the internal Kronecker search with a faster exact algorithm only if the same public contract, refusal semantics, deterministic ordering, independent reconstruction, and admission evidence remain intact.
