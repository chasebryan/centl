"""Exact integer arithmetic used by the kernel."""

from __future__ import annotations

import math


HARD = (1, 121, 169, 289, 361, 529)


def sieve_primes(n: int) -> list[int]:
    if n < 2:
        return []
    bs = bytearray(b"\x01") * (n + 1)
    bs[:2] = b"\x00\x00"
    lim = math.isqrt(n)
    for p in range(2, lim + 1):
        if bs[p]:
            start = p * p
            bs[start : n + 1 : p] = b"\x00" * (((n - start) // p) + 1)
    return [i for i, v in enumerate(bs) if v]


def is_prime(n: int) -> bool:
    if n < 2:
        return False
    if n % 2 == 0:
        return n == 2
    d = 3
    while d * d <= n:
        if n % d == 0:
            return False
        d += 2
    return True


def jacobi(a: int, n: int) -> int:
    if n <= 0 or n % 2 == 0:
        raise ValueError("jacobi modulus must be odd and positive")
    a %= n
    result = 1
    while a:
        while a % 2 == 0:
            a //= 2
            if n % 8 in (3, 5):
                result = -result
        a, n = n, a
        if a % 4 == 3 and n % 4 == 3:
            result = -result
        a %= n
    return result if n == 1 else 0


def divisors_of_factored(fac: dict[int, int]) -> list[int]:
    divs = [1]
    for p, e in fac.items():
        more = []
        pe = 1
        for _ in range(e):
            pe *= p
            more.extend(d * pe for d in divs)
        divs.extend(more)
    return divs


class Factorizer:
    def __init__(self, sieve_limit: int = 200_000) -> None:
        if sieve_limit < 16:
            sieve_limit = 16
        self.primes = sieve_primes(sieve_limit)

    def factor(self, n: int) -> dict[int, int]:
        if n <= 1:
            return {}
        out: dict[int, int] = {}
        x = n
        for p in self.primes:
            if p * p > x:
                break
            if x % p == 0:
                e = 0
                while x % p == 0:
                    x //= p
                    e += 1
                out[p] = e
            if x == 1:
                return out
        if x > 1:
            if x <= self.primes[-1] * self.primes[-1] or is_prime(x):
                out[x] = out.get(x, 0) + 1
            else:
                d = self.primes[-1] | 1
                while d * d <= x:
                    if x % d == 0:
                        e = 0
                        while x % d == 0:
                            x //= d
                            e += 1
                        out[d] = e
                    d += 2
                if x > 1:
                    out[x] = out.get(x, 0) + 1
        return out

    def first_prime_factor(self, n: int) -> int:
        if n < 2:
            raise ValueError("n must be >= 2")
        fac = self.factor(n)
        return min(fac)

    def is_prime(self, n: int) -> bool:
        if n < 2:
            return False
        fac = self.factor(n)
        return len(fac) == 1 and next(iter(fac.values())) == 1
