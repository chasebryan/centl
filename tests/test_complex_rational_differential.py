#!/usr/bin/env python3

from fractions import Fraction
import random
import subprocess
import sys


def ftext(value: Fraction) -> str:
    return f"{value.numerator}/{value.denominator}"


def pair_text(value: tuple[Fraction, Fraction]) -> str:
    return f"{ftext(value[0])}\t{ftext(value[1])}"


def add(a, b):
    return (a[0] + b[0], a[1] + b[1])


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1])


def mul(a, b):
    return (a[0] * b[0] - a[1] * b[1], a[0] * b[1] + a[1] * b[0])


def div(a, b):
    denominator = b[0] * b[0] + b[1] * b[1]
    if denominator == 0:
        raise ZeroDivisionError
    return (
        (a[0] * b[0] + a[1] * b[1]) / denominator,
        (a[1] * b[0] - a[0] * b[1]) / denominator,
    )


def pow_nonnegative(base, exponent):
    result = (Fraction(1), Fraction(0))
    while exponent:
        if exponent & 1:
            result = mul(result, base)
        exponent >>= 1
        if exponent:
            base = mul(base, base)
    return result


def power(base, exponent):
    if exponent == 0:
        if base == (Fraction(0), Fraction(0)):
            raise ZeroDivisionError("0^0")
        return (Fraction(1), Fraction(0))
    if exponent > 0:
        return pow_nonnegative(base, exponent)
    return pow_nonnegative(div((Fraction(1), Fraction(0)), base), -exponent)


def run(probe, operation, *arguments):
    completed = subprocess.run(
        [probe, operation, *arguments],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return completed.stdout.strip()


def random_fraction(rng):
    numerator = rng.randint(-40, 40)
    denominator = rng.randint(1, 23)
    return Fraction(numerator, denominator)


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: test_complex_rational_differential.py PROBE", file=sys.stderr)
        return 2
    probe = sys.argv[1]
    rng = random.Random(0xC3117)
    operations = {"add": add, "sub": sub, "mul": mul, "div": div}

    cases = 0
    for _ in range(80):
        a = (random_fraction(rng), random_fraction(rng))
        b = (random_fraction(rng), random_fraction(rng))
        if b == (Fraction(0), Fraction(0)):
            b = (Fraction(1), Fraction(0))
        arguments = [ftext(a[0]), ftext(a[1]), ftext(b[0]), ftext(b[1])]
        for name, oracle in operations.items():
            expected = pair_text(oracle(a, b))
            actual = run(probe, name, *arguments)
            if actual != expected:
                print(
                    f"{name} mismatch: a={a} b={b} expected={expected!r} actual={actual!r}",
                    file=sys.stderr,
                )
                return 1
            cases += 1

    for _ in range(40):
        base = (random_fraction(rng), random_fraction(rng))
        if base == (Fraction(0), Fraction(0)):
            base = (Fraction(1), Fraction(1))
        exponent = rng.randint(-8, 8)
        expected = pair_text(power(base, exponent))
        actual = run(
            probe,
            "pow",
            ftext(base[0]),
            ftext(base[1]),
            str(exponent),
        )
        if actual != expected:
            print(
                f"pow mismatch: base={base} exponent={exponent} expected={expected!r} actual={actual!r}",
                file=sys.stderr,
            )
            return 1
        cases += 1

    print(f"exact complex-rational differential oracle: PASS ({cases} cases)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
