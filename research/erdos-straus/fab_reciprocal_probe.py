#!/usr/bin/env python3
"""Exact finite probe for FAB-RECIPROCAL-DUALITY.md.

This is a discovery instrument, not a proof of Erdős-Straus.
It scans Mordell-hard primes and tests two exact sufficient lanes at each
m == 3 (mod 4):

  forward:    D | ((p+m)/4)^2,  4D == -1 (mod m)
  reciprocal: D | ((pm+1)/4)^2, 4D == -1 (mod m)

When a lane succeeds, the script reconstructs a complete integer fab
certificate and verifies the resulting Egyptian-fraction identity exactly by
cross multiplication.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
from collections import Counter
from pathlib import Path

HARD = (1, 121, 169, 289, 361, 529)


def prime_sieve(limit: int) -> list[int]:
    flags = bytearray(b"\x01") * (limit + 1)
    if limit >= 0:
        flags[0] = 0
    if limit >= 1:
        flags[1] = 0
    for p in range(2, math.isqrt(limit) + 1):
        if flags[p]:
            start = p * p
            flags[start : limit + 1 : p] = b"\x00" * (((limit - start) // p) + 1)
    return [p for p in range(2, limit + 1) if flags[p] and p % 840 in HARD]


def ordinary_primes(limit: int) -> list[int]:
    flags = bytearray(b"\x01") * (limit + 1)
    if limit >= 0:
        flags[0] = 0
    if limit >= 1:
        flags[1] = 0
    for p in range(2, math.isqrt(limit) + 1):
        if flags[p]:
            start = p * p
            flags[start : limit + 1 : p] = b"\x00" * (((limit - start) // p) + 1)
    return [p for p in range(2, limit + 1) if flags[p]]


def factorint(n: int, primes: list[int]) -> dict[int, int]:
    if n <= 0:
        raise ValueError("factorint expects a positive integer")
    out: dict[int, int] = {}
    x = n
    for r in primes:
        if r * r > x:
            break
        if x % r == 0:
            e = 0
            while x % r == 0:
                x //= r
                e += 1
            out[r] = e
        if x == 1:
            break
    if x > 1:
        out[x] = out.get(x, 0) + 1
    return out


def target_divisor_of_square(n: int, m: int, primes: list[int]) -> tuple[int, dict[int, int]] | None:
    """Return D|n^2 with 4D == -1 mod m, plus factorization of n.

    Dynamic programming is over residue classes modulo m and stores one exact
    divisor representative for every reached residue. This is finite and exact.
    """
    if m <= 1 or math.gcd(4, m) != 1:
        raise ValueError("m must be odd and >1")

    fac = factorint(n, primes)
    target = (-pow(4, -1, m)) % m
    reached: dict[int, int] = {1 % m: 1}

    if target in reached:
        return reached[target], fac

    for r, e in fac.items():
        powers: list[tuple[int, int]] = []
        exact = 1
        residue = 1 % m
        for _ in range(2 * e + 1):
            powers.append((residue, exact))
            exact *= r
            residue = (residue * r) % m

        nxt = dict(reached)
        for old_residue, old_value in reached.items():
            for power_residue, power_value in powers:
                new_residue = (old_residue * power_residue) % m
                if new_residue not in nxt:
                    nxt[new_residue] = old_value * power_value
        reached = nxt

        if target in reached:
            return reached[target], fac

    return None


def reconstruct_n_square(n: int, D: int, fac: dict[int, int]) -> tuple[int, int, int]:
    """Reconstruct (left, right, shared) from n and D|n^2.

    For forward use these as (a,b,c); for reciprocal use them as (q,b,c).
    """
    left = 1
    right = 1
    shared = 1
    x = D

    for r, E in fac.items():
        U = 0
        while x % r == 0:
            x //= r
            U += 1
        if U > 2 * E:
            raise AssertionError("D is not a divisor of n^2")

        alpha = max(E - U, 0)
        beta = max(U - E, 0)
        gamma = E - abs(E - U)

        left *= r**alpha
        right *= r**beta
        shared *= r**gamma

    if x != 1:
        raise AssertionError("D contains a prime not present in n")
    if left * right * shared != n:
        raise AssertionError("n reconstruction failed")
    if right * right * shared != D:
        raise AssertionError("D reconstruction failed")
    if math.gcd(left, right) != 1:
        raise AssertionError("coprime reconstruction failed")

    return left, right, shared


def verify_certificate(p: int, a: int, b: int, c: int, k: int, d: int, q: int) -> dict:
    if min(a, b, c, k, d, q) <= 0:
        raise AssertionError("non-positive certificate parameter")
    if k % 4 != 3 or d % 4 != 3:
        raise AssertionError("k,d must both be 3 mod 4")
    if p + k != 4 * a * b * c:
        raise AssertionError("p+k identity failed")
    if p * d + 1 != 4 * b * c * q:
        raise AssertionError("pd+1 identity failed")
    if k * d != 1 + 4 * b * b * c:
        raise AssertionError("kd identity failed")
    if q != a * d - b:
        raise AssertionError("q=ad-b failed")
    if k * q != a + b * p:
        raise AssertionError("kq=a+bp failed")

    xden = a * b * c
    yden = a * c * q
    zden = b * c * p * q

    lhs = 4 * xden * yden * zden
    rhs = p * (yden * zden + xden * zden + xden * yden)
    if lhs != rhs:
        raise AssertionError("Egyptian-fraction identity failed")

    return {
        "a": a,
        "b": b,
        "c": c,
        "k": k,
        "d": d,
        "q": q,
        "x": xden,
        "y": yden,
        "z": zden,
    }


def forward_hit(p: int, m: int, primes: list[int]) -> dict | None:
    n = (p + m) // 4
    got = target_divisor_of_square(n, m, primes)
    if got is None:
        return None
    D, fac = got
    a, b, c = reconstruct_n_square(n, D, fac)
    k = m
    if (a + b * p) % k:
        raise AssertionError("forward reconstructed k does not divide a+bp")
    q = (a + b * p) // k
    d_num = 1 + 4 * b * b * c
    if d_num % k:
        raise AssertionError("forward complementary factor is not integral")
    d = d_num // k
    cert = verify_certificate(p, a, b, c, k, d, q)
    cert.update({"lane": "forward", "m": m, "square_base": n, "D": D})
    return cert


def reciprocal_hit(p: int, m: int, primes: list[int]) -> dict | None:
    n = (p * m + 1) // 4
    got = target_divisor_of_square(n, m, primes)
    if got is None:
        return None
    D, fac = got
    q, b, c = reconstruct_n_square(n, D, fac)
    d = m
    kd = 4 * D + 1
    if kd % d:
        raise AssertionError("reciprocal reconstructed k is not integral")
    k = kd // d
    if (q + b) % d:
        raise AssertionError("reciprocal reconstructed a is not integral")
    a = (q + b) // d
    cert = verify_certificate(p, a, b, c, k, d, q)
    cert.update({"lane": "reciprocal", "m": m, "square_base": n, "D": D})
    return cert


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=50_000_000)
    ap.add_argument("--max-m", type=int, default=59)
    ap.add_argument("--out", type=Path)
    args = ap.parse_args()

    if args.limit < 2:
        raise SystemExit("--limit must be >=2")
    if args.max_m < 3:
        raise SystemExit("--max-m must be >=3")

    params = [m for m in range(3, args.max_m + 1, 4)]
    if not params:
        raise SystemExit("no m == 3 mod 4 parameters selected")

    max_factor_target = (args.limit * params[-1] + 1) // 4
    trial_primes = ordinary_primes(math.isqrt(max_factor_target) + 1)
    hard_primes = prime_sieve(args.limit)

    counts: Counter[tuple[str, int]] = Counter()
    unresolved: list[int] = []
    records: list[dict] = []
    max_first_m = None

    for p in hard_primes:
        hit = None
        for m in params:
            hit = forward_hit(p, m, trial_primes)
            if hit is not None:
                break
            hit = reciprocal_hit(p, m, trial_primes)
            if hit is not None:
                break

        if hit is None:
            unresolved.append(p)
            continue

        counts[(hit["lane"], hit["m"])] += 1
        max_first_m = hit["m"] if max_first_m is None else max(max_first_m, hit["m"])
        hit["p"] = p
        records.append(hit)

    distribution = [
        {"lane": lane, "m": m, "captures": counts[(lane, m)]}
        for m in params
        for lane in ("forward", "reciprocal")
        if counts[(lane, m)]
    ]

    summary = {
        "schema": 1,
        "problem": "Erdos-Straus reciprocal fab double sieve",
        "limit": args.limit,
        "max_m": args.max_m,
        "hard_residues_mod_840": list(HARD),
        "hard_prime_count": len(hard_primes),
        "captured_count": len(records),
        "unresolved_count": len(unresolved),
        "unresolved": unresolved,
        "max_first_success_m": max_first_m,
        "first_success_distribution": distribution,
        "scientific_status": "finite exact computation; not an Erdos-Straus proof",
    }

    print("CENTL / reciprocal fab double sieve")
    print(f"prime bound            {args.limit:,}")
    print(f"largest m              {args.max_m}")
    print(f"Mordell-hard primes    {len(hard_primes):,}")
    print(f"captured               {len(records):,}")
    print(f"unresolved             {len(unresolved):,}")
    print(f"max first-success m    {max_first_m}")
    print()
    print("first-success distribution")
    for row in distribution:
        print(f"{row['lane']:10s}  m={row['m']:>3d}  {row['captures']:>7,d}")

    if unresolved:
        print()
        print("first unresolved")
        print(" ".join(str(p) for p in unresolved[:20]))

    if args.out is not None:
        args.out.mkdir(parents=True, exist_ok=True)
        (args.out / "summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True) + "\n")
        (args.out / "first-success-certificates.jsonl").write_text(
            "".join(json.dumps(row, sort_keys=True) + "\n" for row in records)
        )
        files = sorted(p for p in args.out.iterdir() if p.is_file() and p.name != "SHA256SUMS")
        (args.out / "SHA256SUMS").write_text("".join(f"{sha256(p)}  {p.name}\n" for p in files))
        print()
        print(f"results                {args.out}")


if __name__ == "__main__":
    main()
