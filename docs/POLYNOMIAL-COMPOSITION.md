# Exact Polynomial Composition

Status: P0 admission candidate.

This document freezes the mathematical and machine contract for exact simultaneous
polynomial substitution in CENTL.

## Domain

The admitted source and replacement values are canonical sparse multivariate
polynomials over `Q` as represented by `Centl_multivariate_polynomial`.

For a source polynomial

`p in Q[x1,...,xn]`

and a finite substitution map

`S = {x_i -> q_i}`

where every `q_i` is itself a canonical sparse polynomial over `Q`, CENTL returns
exactly the polynomial obtained by replacing each selected source variable with
its replacement polynomial and expanding in the resulting polynomial ring.

## Simultaneous semantics

Substitutions are simultaneous, not sequential.

For example, applying

`x -> y`

and

`y -> x`

to `x - y` returns `y - x`. CENTL does not take the result of the first
substitution and feed it through the second substitution.

Replacement polynomials are therefore treated as values of the substitution
map. Variables occurring inside a replacement are not recursively substituted
by other entries in the same request.

## Canonical result

The result uses the existing canonical multivariate-polynomial representation:

- rational coefficients are exact and normalized;
- zero coefficients are removed;
- powers of the same variable are combined;
- variables inside a monomial have deterministic lexical order;
- equal monomials are combined;
- no floating-point approximation is introduced.

## Algorithm

CENTL expands each source monomial independently.

For a source term

`a * product(x_i ^ e_i)`,

CENTL does the following:

1. For an unsubstituted variable, retain `x_i ^ e_i` directly. No artificial
   repeated exponentiation is performed.
2. For a substituted variable, compute `q_i ^ e_i` by exact exponentiation by
   squaring.
3. Multiply the resulting exact polynomial factors.
4. Traverse the expanded factor polynomial one term at a time.
5. Before retaining each term, checkpoint cancellation and charge its linear
   accumulation work, multiply its coefficient by the exact source coefficient
   `a`, add that term to the canonical result, and immediately re-check the
   term-count and exact-bit ceilings.

Sparse multiplication is performed pair by pair. Exact-bit and term-count
guards run after every pairwise monomial accumulation, during exponentiation by
squaring, and after every final scaled-term insertion. An explosive product or
final accumulation is therefore refused while it is growing rather than after
a full oversized intermediate has already been constructed.

## Refusal and resource semantics

Composition has no approximate fallback. A request is explicitly refused when
one of the following boundaries is crossed:

- duplicate substitution variables;
- an empty substitution variable name;
- too many substitution entries;
- a substituted source exponent exceeds the composition power ceiling;
- an intermediate or final polynomial exceeds the admitted term ceiling;
- an intermediate or final polynomial exceeds the admitted exact-bit ceiling;
- the deterministic multiplication/addition work budget is exhausted;
- the final machine response exceeds the result-byte ceiling;
- the request is cancelled.

The power ceiling applies to actual substitution expansion. An unsubstituted
source variable may retain a larger exponent when that exponent is already
admitted by the underlying polynomial parser.

## Work accounting

Polynomial multiplication charges the exact number of source term pairs that
the canonical sparse multiplier will examine. Final coefficient scaling and
canonical insertion charge one unit per expanded term before that work is
performed. Work accounting saturates by refusal rather than overflowing an
integer counter.

This is an admission boundary, not a complexity claim. The purpose is to make
resource use deterministic and enforceable at the public request boundary.

## Cancellation

Composition is cooperatively cancellable:

- before expansion begins;
- between source terms;
- between source monomial factors;
- during exponentiation by squaring;
- inside canonical sparse polynomial multiplication;
- before each final scaled-term insertion.

A cancelled request returns an explicit `cancelled` failure and no partial
polynomial is presented as a result.

## Public machine surfaces

The canonical mathematics gateway exposes the domain
`polynomial_composition`.

Its version-1 request actions are:

- `capabilities`
- `compose`

A `compose` request contains:

- `polynomial`: the canonical sparse source polynomial;
- `substitutions`: an array of objects containing `variable` and `polynomial`.

JSONL `op: "math"` and the closed-schema MCP `centl_math` tool route through
the same implementation. Their server ceilings clamp the composition limits,
so a more permissive nested request cannot escape the outer request boundary.

## Provenance

Successful results are classified as `exact` and identify the backend as
`centl-exact-polynomial-composition`. Gateway transport preserves the domain
name and nested provenance.

## Admission evidence

The implementation is not admitted merely because one symbolic example
expands correctly. The test ladder includes:

- direct canonical equality tests;
- explicit simultaneous-versus-sequential substitution tests;
- unchanged large-exponent tests;
- substituted power-ceiling tests;
- intermediate term-growth refusal;
- duplicate-substitution refusal;
- final-accumulation cancellation;
- mid-operation cooperative cancellation;
- a separately coded rational evaluation oracle over a deterministic grid;
- a 4096-bit exact-coefficient oracle case;
- strict protocol tests;
- JSONL public-route tests;
- closed-schema MCP public-route tests;
- public result-size and cancellation tests.

The broader polynomial capability checklist is promoted only after these tests
and the repository CI gates pass.
