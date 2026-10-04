#!/usr/bin/env python3

import json
import subprocess
import sys
from fractions import Fraction


def trim(coefficients):
    values = list(coefficients)
    while values and values[-1] == 0:
        values.pop()
    return values


def multiply(left, right):
    result = [0] * (len(left) + len(right) - 1)
    for i, a in enumerate(left):
        for j, b in enumerate(right):
            result[i + j] += a * b
    return trim(result)


def power(polynomial, exponent):
    result = [1]
    for _ in range(exponent):
        result = multiply(result, polynomial)
    return result


def product(*polynomials):
    result = [1]
    for polynomial in polynomials:
        result = multiply(result, polynomial)
    return result


def run_json(command, coefficients):
    encoded = ",".join(str(value) for value in coefficients)
    completed = subprocess.run(
        [command, encoded],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=30,
    )
    try:
        return json.loads(completed.stdout)
    except json.JSONDecodeError as exc:
        raise AssertionError(
            f"{command} returned invalid JSON for {encoded}: {completed.stdout!r}"
        ) from exc


def fraction(text):
    return Fraction(text)


def normalize_factor(coefficients, multiplicity):
    coefficients = trim([fraction(value) for value in coefficients])
    if not coefficients:
        raise AssertionError("oracle returned a zero factor")
    leading = coefficients[-1]
    monic = tuple(value / leading for value in coefficients)
    return (len(monic) - 1, tuple(reversed(monic)), multiplicity)


def centl_factorization(payload):
    factors = [
        normalize_factor(item["coefficients"], int(item["multiplicity"]))
        for item in payload["factors"]
    ]
    return sorted(factors)


def flint_factorization(payload):
    factors = [
        normalize_factor(item["coefficients"], int(item["multiplicity"]))
        for item in payload["factors"]
    ]
    return sorted(factors)


def describe(factors):
    return [
        {
            "degree": degree,
            "coefficients_high_to_low": [str(value) for value in coefficients],
            "multiplicity": multiplicity,
        }
        for degree, coefficients, multiplicity in factors
    ]


def main():
    if len(sys.argv) != 3:
        raise SystemExit(
            "usage: test_polynomial_factorization_differential.py CENTL_PROBE FLINT_ORACLE"
        )

    centl_probe, flint_oracle = sys.argv[1:]

    q2a = [2, 1, 1]                  # x^2 + x + 2
    q2b = [2, -1, 1]                 # x^2 - x + 2
    c3a = [2, 2, 0, 1]               # x^3 + 2x + 2
    c3b = [3, 3, 0, 1]               # x^3 + 3x + 3
    nonmonic_linear = [1, 2]          # 2x + 1
    nonmonic_quadratic = [1, 1, 3]    # 3x^2 + x + 1
    x_minus_two = [-2, 1]
    x_plus_one = [1, 1]

    cases = [
        ("x4-minus-one", [-1, 0, 0, 0, 1]),
        ("quadratic-times-cubic", product(q2a, c3a)),
        ("repeated-quadratics", product(power(q2a, 2), q2b)),
        ("two-eisenstein-cubics", product(c3a, c3b)),
        ("nonmonic-factors", product(nonmonic_linear, nonmonic_quadratic)),
        ("repeated-linears", product(power(x_minus_two, 3), power(x_plus_one, 2))),
        ("x6-minus-one", [-1, 0, 0, 0, 0, 0, 1]),
        ("eisenstein-quartic", [2, 2, 0, 0, 1]),
        ("eisenstein-cubic", c3a),
        ("mixed-seven-degree", product(q2a, q2b, c3a)),
    ]

    for name, coefficients in cases:
        centl = run_json(centl_probe, coefficients)
        flint = run_json(flint_oracle, coefficients)

        expected_unit = Fraction(coefficients[-1], 1)
        actual_unit = fraction(centl["unit"])
        if actual_unit != expected_unit:
            raise AssertionError(
                f"{name}: CENTL unit {actual_unit} != leading coefficient {expected_unit}"
            )

        centl_factors = centl_factorization(centl)
        flint_factors = flint_factorization(flint)
        if centl_factors != flint_factors:
            raise AssertionError(
                f"{name}: factorization mismatch\n"
                f"CENTL={describe(centl_factors)}\n"
                f"FLINT={describe(flint_factors)}"
            )

    print(f"polynomial-factorization-flint-differential: PASS ({len(cases)} cases)")


if __name__ == "__main__":
    main()
