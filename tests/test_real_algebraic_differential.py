#!/usr/bin/env python3

from fractions import Fraction
import random
import subprocess
import sys


def multiply(left, right):
    result = [0] * (len(left) + len(right) - 1)
    for i, a in enumerate(left):
        for j, b in enumerate(right):
            result[i + j] += a * b
    return result


def polynomial_from_roots(roots):
    polynomial = [1]
    for root in roots:
        polynomial = multiply(polynomial, [-root, 1])
    return polynomial


def qtext(value):
    return f"{value.numerator}/{value.denominator}"


def run(probe, coefficients, lower, upper):
    completed = subprocess.run(
        [probe, "count", ",".join(str(c) for c in coefficients), qtext(lower), qtext(upper)],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return int(completed.stdout.strip())


def main():
    if len(sys.argv) != 2:
        print("usage: test_real_algebraic_differential.py PROBE", file=sys.stderr)
        return 2
    probe = sys.argv[1]
    rng = random.Random(0x535455524D)
    cases = 0
    root_pool = list(range(-8, 9))

    for _ in range(140):
        degree = rng.randint(1, 6)
        roots = sorted(rng.sample(root_pool, degree))
        coefficients = polynomial_from_roots(roots)
        left_half = rng.randint(-19, 17)
        right_half = rng.randint(left_half + 1, 19)
        lower = Fraction(left_half, 2)
        upper = Fraction(right_half, 2)
        if lower.denominator == 1 and lower.numerator in roots:
            lower -= Fraction(1, 2)
        if upper.denominator == 1 and upper.numerator in roots:
            upper += Fraction(1, 2)
        expected = sum(1 for root in roots if lower < root < upper)
        actual = run(probe, coefficients, lower, upper)
        if actual != expected:
            print(
                f"root-count mismatch roots={roots} polynomial={coefficients} interval=({lower},{upper}) expected={expected} actual={actual}",
                file=sys.stderr,
            )
            return 1
        cases += 1

    print(f"real algebraic root-count oracle: PASS ({cases} constructed-root cases)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
