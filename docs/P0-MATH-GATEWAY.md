# Canonical P0 Mathematics Gateway

Status: implementation contract for the canonical routing layer that joins the
first P0 mathematics substrates.

This gateway exists so exact complex rationals, exact rational matrices and
linear systems, canonical multivariate rational polynomials, and exact real
algebraic root certificates do not grow into four unrelated public evaluators.
The domain implementations remain independently testable, but one strict
CENTL-native request envelope selects the mathematical domain and preserves the
domain result and provenance.

## Request envelope

A gateway request is a strict JSON object:

```json
{
  "version": 1,
  "id": "optional-request-id",
  "domain": "matrix",
  "request": {
    "action": "determinant",
    "matrix": [["1", "2"], ["3", "4"]]
  }
}
```

The gateway owns `version` and `id`. Nested requests must not supply either
field. They are injected into the selected domain adapter so the existing domain
contracts remain authoritative.

Admitted domain names are:

- `complex_rational`
- `matrix`
- `multivariate_polynomial`
- `real_algebraic`
- `capabilities`

`capabilities` takes no request or an empty request object.

## Semantic contract

The gateway does not reinterpret mathematics. It routes to the admitted exact
implementation and preserves that implementation's result classification,
provenance, exactness, refusal semantics, and resource failures.

It therefore MUST NOT:

- convert an unsupported exact request into floating-point output;
- erase an algebraic isolation certificate;
- convert a singular/inconsistent matrix decision into an approximate answer;
- canonicalize a polynomial differently from the polynomial core;
- accept nested protocol-version or request-id overrides;
- hide resource-limit or cancellation outcomes.

The outer gateway adds the selected `domain` to the machine response and applies
a final response-byte ceiling after that wrapping step.

## Domain value models

### Exact complex rationals

Values are exact pairs `(a, b)` with `a,b in Q`, denoting `a + b i`. The gateway
routes the CENTL expression string to the exact complex-rational evaluator.

### Exact rational matrices and linear systems

Matrices contain exact rational entries. Elimination-based operations are
cooperatively cancellable at elimination checkpoints. Final matrix, scalar,
RREF, null-space, and linear-solution outputs are independently checked against
the exact-bit ceiling after computation.

### Canonical multivariate rational polynomials

Polynomials use the canonical sparse `Q[x1,...,xn]` representation and retain the
polynomial core's exact operation and resource semantics. Multiplication,
integer powers, differentiation, and rational substitution have cooperative
cancellation checkpoints inside their iterative work. Add/sub work admission is
linear in term counts; multiplication admission accounts for the term-pair
product. Total-degree and exact-bit accumulation are overflow-safe.

### Real algebraic root certificates

A real algebraic value in this initial admitted slice is identified by a
primitive square-free integer polynomial and an open rational interval proven by
exact Sturm counting to contain exactly one distinct real root. The result class
is `algebraic_exact`. Refinement is cooperatively cancellable between exact
bisection steps, and refined rational endpoints are rechecked against the
endpoint-bit ceiling before a result is emitted.

## Cancellation

The gateway checks cancellation before dispatch. The matrix adapter propagates
the callback into elimination checkpoints. The multivariate-polynomial adapter
propagates it through multiplication, power, differentiation, and rational
substitution loops. The real-algebraic adapter checks before bounded Sturm work
and between repeated refinement steps. A cancelled operation returns an explicit
`cancelled` failure and never substitutes a partial or approximate result.

## Admission boundary

The gateway is infrastructure, not evidence that every surrounding strategic
checkbox is complete. A broad checklist item is marked complete only when its
value model is integrated through the canonical public protocol and MCP surface,
resource/adversarial/cross-surface tests pass, and all applicable requirements in
`MATHEMATICS-IMPLEMENTATION-STANDARD.md` are satisfied.
