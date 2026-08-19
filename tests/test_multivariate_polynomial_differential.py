#!/usr/bin/env python3

from fractions import Fraction
import random
import subprocess
import sys


def add(a, b):
    out = dict(a)
    for monomial, coefficient in b.items():
        out[monomial] = out.get(monomial, Fraction(0)) + coefficient
        if out[monomial] == 0:
            del out[monomial]
    return out


def mul_monomial(a, b):
    powers = dict(a)
    for variable, exponent in b:
        powers[variable] = powers.get(variable, 0) + exponent
    return tuple(sorted((variable, exponent) for variable, exponent in powers.items() if exponent))


def multiply(a, b):
    out = {}
    for ma, ca in a.items():
        for mb, cb in b.items():
            monomial = mul_monomial(ma, mb)
            out[monomial] = out.get(monomial, Fraction(0)) + ca * cb
            if out[monomial] == 0:
                del out[monomial]
    return out


def derivative(variable, polynomial):
    out = {}
    for monomial, coefficient in polynomial.items():
        powers = dict(monomial)
        exponent = powers.get(variable, 0)
        if exponent == 0:
            continue
        coefficient *= exponent
        if exponent == 1:
            del powers[variable]
        else:
            powers[variable] = exponent - 1
        new_monomial = tuple(sorted(powers.items()))
        out[new_monomial] = out.get(new_monomial, Fraction(0)) + coefficient
    return {m: c for m, c in out.items() if c}


def substitute(substitutions, polynomial):
    out = {}
    for monomial, coefficient in polynomial.items():
        remaining = []
        for variable, exponent in monomial:
            if variable in substitutions:
                coefficient *= substitutions[variable] ** exponent
            else:
                remaining.append((variable, exponent))
        remaining = tuple(remaining)
        out[remaining] = out.get(remaining, Fraction(0)) + coefficient
        if out[remaining] == 0:
            del out[remaining]
    return out


def ftext(value):
    return f"{value.numerator}/{value.denominator}"


def encode(polynomial):
    parts = []
    for monomial in sorted(polynomial):
        coefficient = polynomial[monomial]
        powers = ",".join(f"{variable}^{exponent}" for variable, exponent in monomial)
        parts.append(f"{ftext(coefficient)}|{powers}")
    return ";".join(parts)


def run(probe, *arguments):
    completed = subprocess.run(
        [probe, *arguments],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return completed.stdout.strip()


def random_polynomial(rng):
    polynomial = {}
    variables = ("x", "y", "z")
    for _ in range(rng.randint(0, 6)):
        powers = []
        for variable in variables:
            exponent = rng.randint(0, 3)
            if exponent:
                powers.append((variable, exponent))
        monomial = tuple(powers)
        coefficient = Fraction(rng.randint(-8, 8), rng.randint(1, 9))
        polynomial[monomial] = polynomial.get(monomial, Fraction(0)) + coefficient
        if polynomial[monomial] == 0:
            del polynomial[monomial]
    return polynomial


def main():
    if len(sys.argv) != 2:
        print("usage: test_multivariate_polynomial_differential.py PROBE", file=sys.stderr)
        return 2
    probe = sys.argv[1]
    rng = random.Random(0x504F4C59)
    cases = 0
    for _ in range(80):
        left = random_polynomial(rng)
        right = random_polynomial(rng)
        for operation, oracle in (("add", add), ("mul", multiply)):
            expected = encode(oracle(left, right))
            actual = run(probe, operation, encode(left), encode(right))
            if actual != expected:
                print(f"{operation} mismatch\nleft={left}\nright={right}\nexpected={expected!r}\nactual={actual!r}", file=sys.stderr)
                return 1
            cases += 1

        variable = rng.choice(("x", "y", "z"))
        expected = encode(derivative(variable, left))
        actual = run(probe, "diff", variable, encode(left))
        if actual != expected:
            print(f"diff mismatch variable={variable} polynomial={left}\nexpected={expected!r}\nactual={actual!r}", file=sys.stderr)
            return 1
        cases += 1

        substitutions = {
            "x": Fraction(rng.randint(-4, 4), rng.randint(1, 5)),
            "z": Fraction(rng.randint(-4, 4), rng.randint(1, 5)),
        }
        encoded_substitutions = ",".join(f"{name}={ftext(value)}" for name, value in substitutions.items())
        expected = encode(substitute(substitutions, left))
        actual = run(probe, "sub", encoded_substitutions, encode(left))
        if actual != expected:
            print(f"substitution mismatch polynomial={left}\nsubstitutions={substitutions}\nexpected={expected!r}\nactual={actual!r}", file=sys.stderr)
            return 1
        cases += 1

    print(f"exact multivariate polynomial differential oracle: PASS ({cases} cases)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
