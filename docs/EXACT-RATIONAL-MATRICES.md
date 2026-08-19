# Exact rational matrices

Status: implementation in progress.

Capability family: P0 exact linear-algebra substrate.

This contract is intentionally narrower than a general numerical linear-algebra
package. The first CENTL matrix domain is finite dense matrices over `Q`. Every
successful arithmetic result is exact.

## Mathematical object

A matrix is an `m x n` rectangular array of rational numbers with `m >= 1` and
`n >= 1`. Rows have equal length. Rational entries are normalized by Zarith.

The first admitted operations are:

- dense construction and exact indexing;
- matrix equality;
- addition and subtraction for equal shapes;
- rational scalar multiplication;
- matrix multiplication for compatible shapes;
- transpose;
- trace for square matrices;
- determinant for square matrices;
- deterministic reduced row echelon form;
- rank;
- exact inverse for nonsingular square matrices;
- exact solution classification for `A x = b`;
- exact null-space basis derived from the same RREF semantics.

## Index convention

The internal OCaml API is zero-based. Any future human mathematical syntax must
state its convention explicitly rather than silently inheriting the host-language
indexing convention.

## Linear-system result model

For an `m x n` rational matrix `A` and rational vector `b` of length `m`, CENTL
classifies the system exactly as one of:

- `no_solution`;
- `unique`, with one exact rational vector of length `n`;
- `infinite`, with one exact particular solution and an exact basis for the
  homogeneous null space.

The infinite-solution representation denotes

`x = particular + c1*basis1 + ... + ck*basisk`

for arbitrary rational parameters `c1 ... ck`.

No floating-point rank tolerance is used.

## RREF convention

RREF uses deterministic left-to-right pivot search and top-to-bottom row search.
Each pivot is normalized to one and eliminated from every other row. Pivot
columns are therefore deterministic for an identical exact input.

## Determinant and inverse

Determinants and inverses are computed with exact rational elimination. Row swaps
change determinant sign. Division is only by a pivot proven nonzero by exact
rational comparison.

An inverse request for a singular matrix returns an explicit singular-matrix
error. It does not return a pseudoinverse and does not fall back to floating
point.

## Invalid inputs and refusal boundary

The first slice rejects:

- empty matrices;
- ragged rows;
- incompatible matrix dimensions;
- trace/determinant/inverse requests for nonsquare matrices;
- a right-hand-side vector whose length differs from the matrix row count.

The first slice does not claim:

- sparse storage;
- complex or algebraic matrix entries;
- approximate matrices or numerical conditioning estimates;
- least squares or pseudoinverses;
- eigenvalue/eigenvector algorithms;
- LU/QR/Cholesky/SVD/Schur decomposition;
- matrix exponentials;
- certified floating-point acceleration.

Those remain separate capability contracts.

## Exactness and result classification

Construction and every admitted operation are `exact`. A singular inverse,
incompatible shape, or inconsistent system is not a numerical failure. It is a
mathematically classified outcome or a structured domain error as appropriate.

No binary floating-point arithmetic is permitted in this module.

## Resource model

The core library is allocation-bounded by input dimensions but does not define the
public admission ceiling. The public adapter must bound at least:

- row count;
- column count;
- total matrix entries;
- exact input/result bit size;
- elimination work proportional to the relevant cubic dimension;
- output bytes.

Large but mathematically valid work must fail as `resource_limit`, not be silently
approximated.

## Cancellation

The eventual public evaluator must provide deterministic cancellation checkpoints
between pivot iterations and other bounded outer-loop steps. The pure core does
not own request cancellation state.

## Machine representation

A dense exact rational matrix is represented structurally, never as a formatted
string:

```json
{
  "kind": "rational_matrix",
  "exact": true,
  "rows": 2,
  "columns": 2,
  "entries": [
    [
      {"numerator":"1","denominator":"1"},
      {"numerator":"2","denominator":"1"}
    ],
    [
      {"numerator":"3","denominator":"1"},
      {"numerator":"4","denominator":"1"}
    ]
  ]
}
```

Linear-system results must carry an explicit decision field and structured exact
vectors. Text is presentation only.

## Verification obligations before promotion

Before any D1/B4 capability checkbox is marked complete, the implementation must
have:

1. exact examples and failure-boundary tests;
2. matrix-addition/multiplication algebraic identity tests where dimensions
   permit;
3. determinant checks including row-swap sign and multiplicativity samples;
4. `A * inverse(A) = I` reconstruction tests for invertible samples;
5. RREF idempotence and pivot invariants;
6. rank/null-space dimension checks;
7. solution reconstruction for unique and infinite systems;
8. inconsistency checks for no-solution systems;
9. an independently implemented differential oracle on generated rational
   samples;
10. adversarial dimension/bit/output resource tests at the public boundary;
11. strict machine-schema and malformed-input tests;
12. documentation and CI green under the mathematics implementation standard.

Until those gates land, the strategic capability entries remain unchecked.
