#!/usr/bin/env python3

from fractions import Fraction
import random
import subprocess
import sys


def ftext(value: Fraction) -> str:
    return f"{value.numerator}/{value.denominator}"


def mtext(matrix) -> str:
    return ";".join(",".join(ftext(value) for value in row) for row in matrix)


def det2(matrix):
    return matrix[0][0] * matrix[1][1] - matrix[0][1] * matrix[1][0]


def inverse2(matrix):
    determinant = det2(matrix)
    if determinant == 0:
        raise ZeroDivisionError
    return [
        [matrix[1][1] / determinant, -matrix[0][1] / determinant],
        [-matrix[1][0] / determinant, matrix[0][0] / determinant],
    ]


def multiply(a, b):
    return [
        [sum((a[row][k] * b[k][column] for k in range(2)), Fraction(0)) for column in range(2)]
        for row in range(2)
    ]


def random_fraction(rng):
    return Fraction(rng.randint(-20, 20), rng.randint(1, 13))


def random_matrix(rng):
    return [[random_fraction(rng), random_fraction(rng)], [random_fraction(rng), random_fraction(rng)]]


def run(probe, *arguments):
    completed = subprocess.run(
        [probe, *arguments],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return completed.stdout.strip()


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: test_matrix_differential.py PROBE", file=sys.stderr)
        return 2
    probe = sys.argv[1]
    rng = random.Random(0x4D4154524958)
    cases = 0

    for _ in range(80):
        a = random_matrix(rng)
        b = random_matrix(rng)

        expected_product = mtext(multiply(a, b))
        actual_product = run(probe, "mul", mtext(a), mtext(b))
        if actual_product != expected_product:
            print(
                f"matrix multiplication mismatch: a={a} b={b} expected={expected_product!r} actual={actual_product!r}",
                file=sys.stderr,
            )
            return 1
        cases += 1

        expected_det = ftext(det2(a))
        actual_det = run(probe, "det", mtext(a))
        if actual_det != expected_det:
            print(
                f"determinant mismatch: a={a} expected={expected_det!r} actual={actual_det!r}",
                file=sys.stderr,
            )
            return 1
        cases += 1

        if det2(a) != 0:
            expected_inverse = mtext(inverse2(a))
            actual_inverse = run(probe, "inverse", mtext(a))
            if actual_inverse != expected_inverse:
                print(
                    f"inverse mismatch: a={a} expected={expected_inverse!r} actual={actual_inverse!r}",
                    file=sys.stderr,
                )
                return 1
            cases += 1

    print(f"exact rational matrix differential oracle: PASS ({cases} cases)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
