#!/usr/bin/env python3
"""Exact model-escape observer for cbis.kernel.

This is intentionally outside the W/I/N/L cover.  It asks a different
question: can the full Erdős–Straus equation be solved without assuming a
Type A/B parametrization, while Type A/B is still unseen through a finite
bound K?

For a prime p and ordered denominators x <= y <= z,

    4/p = 1/x + 1/y + 1/z

forces

    floor(p/4)+1 <= x <= floor(3p/4).

For each x, reduce

    a/b = 4/p - 1/x.

Then the two-unit-fraction equation is equivalent to

    (a y - b)(a z - b) = b^2.

Enumerating the divisors of b^2 therefore gives a complete exact search for
that x.  Python integers are used deliberately so witness verification does
not inherit a machine-word overflow boundary.

A finite Type A/B miss is never promoted to a proof that no Type A/B witness
exists.  Evidence records are bounded model-escape observations only.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
import re
import subprocess
import sys
import tempfile
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterator

HARD = (1, 121, 169, 289, 361, 529)
U64_MAX = (1 << 64) - 1
DEFAULT_AB_K = 400
DEFAULT_X_COUNT = 10_000
ROOT = Path(__file__).resolve().parent
AUDIT_BINARY = ROOT / "cbis-audit"
LETTERS = ROOT / "letters"
EVIDENCE = ROOT / "evidence"


@dataclass(frozen=True)
class ABHit:
    found: bool = False
    type: str | None = None
    k: int | None = None
    m: int | None = None
    d: int | None = None
    n: int | None = None


@dataclass(frozen=True)
class GeneralWitness:
    x: int
    y: int
    z: int
    remainder_a: int
    remainder_b: int
    divisor_d: int

    def equation(self, p: int) -> str:
        return f"4/{p} = 1/{self.x} + 1/{self.y} + 1/{self.z}"


# Deterministic Miller-Rabin bases for unsigned 64-bit integers.
_MR_BASES = (2, 325, 9375, 28178, 450775, 9780504, 1795265022)
_SMALL_TRIAL = (2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37)


def is_prime64(n: int) -> bool:
    if n < 2 or n > U64_MAX:
        return False
    for p in _SMALL_TRIAL:
        if n % p == 0:
            return n == p
    d = n - 1
    s = 0
    while d % 2 == 0:
        d //= 2
        s += 1
    for a in _MR_BASES:
        if a % n == 0:
            continue
        x = pow(a, d, n)
        if x in (1, n - 1):
            continue
        for _ in range(s - 1):
            x = (x * x) % n
            if x == n - 1:
                break
        else:
            return False
    return True


def _sieve_primes(limit: int = 10_000) -> tuple[int, ...]:
    bs = bytearray(b"\x01") * (limit + 1)
    bs[:2] = b"\x00\x00"
    for p in range(2, math.isqrt(limit) + 1):
        if bs[p]:
            start = p * p
            bs[start : limit + 1 : p] = b"\x00" * (((limit - start) // p) + 1)
    return tuple(i for i, v in enumerate(bs) if v)


_SMALL_PRIMES = _sieve_primes()


def _pollard_rho(n: int) -> int:
    """Return a non-trivial factor of an odd composite 64-bit integer."""
    if n % 2 == 0:
        return 2
    if n % 3 == 0:
        return 3
    c = 1
    while True:
        x = 2
        y = 2
        d = 1
        while d == 1:
            x = (x * x + c) % n
            y = (y * y + c) % n
            y = (y * y + c) % n
            d = math.gcd(abs(x - y), n)
        if d != n:
            return d
        c += 1


def factor64(n: int) -> dict[int, int]:
    """Exact factorization for 1 <= n <= 2^64-1."""
    if n < 1 or n > U64_MAX:
        raise ValueError("factor64 domain is 1..2^64-1")
    out: dict[int, int] = {}
    x = n
    for p in _SMALL_PRIMES:
        if p * p > x:
            break
        if x % p:
            continue
        e = 0
        while x % p == 0:
            x //= p
            e += 1
        out[p] = e

    def split(v: int) -> None:
        if v == 1:
            return
        if is_prime64(v):
            out[v] = out.get(v, 0) + 1
            return
        d = _pollard_rho(v)
        split(d)
        split(v // d)

    split(x)
    return dict(sorted(out.items()))


def full_ab_through(p: int, K: int) -> ABHit:
    """Return the minimal Type A/B hit with k <= K, if one exists."""
    if K < 1:
        return ABHit()
    for k in range(1, K + 1):
        m = 4 * k - 1
        r = p % m
        for e in range(1, math.isqrt(k) + 1):
            if k % e:
                continue
            divisors = (e,) if e * e == k else (e, k // e)
            for s in divisors:
                # Type B: n=s, d=k/s, p == -n (mod 4dn-1).
                if r == (-s) % m:
                    return ABHit(True, "B", k, m, k // s, s)
                # Type A: d=s, n=k/s, p == -4d (mod 4dn-1).
                if r == (-4 * s) % m:
                    return ABHit(True, "A", k, m, s, k // s)
    return ABHit()


def verify_general_witness(p: int, w: GeneralWitness) -> bool:
    if min(w.x, w.y, w.z) <= 0:
        return False
    if not (w.x <= w.y <= w.z):
        return False
    return 4 * w.x * w.y * w.z == p * (
        w.x * w.y + w.x * w.z + w.y * w.z
    )


def _divisors_lte(
    items: tuple[tuple[int, int], ...], limit: int, i: int = 0, d: int = 1
) -> Iterator[int]:
    if i == len(items):
        yield d
        return
    q, exp = items[i]
    qpow = 1
    for _ in range(exp + 1):
        nd = d * qpow
        if nd > limit:
            break
        yield from _divisors_lte(items, limit, i + 1, nd)
        qpow *= q


def _witness_for_x(p: int, x: int) -> GeneralWitness | None:
    """Complete exact y,z search for one canonical first denominator x."""
    a0 = 4 * x - p
    if a0 <= 0:
        return None
    b0 = p * x
    g = math.gcd(a0, b0)
    a = a0 // g
    b = b0 // g

    # The model-escape program is prime-domain.  Because x < p for the
    # canonical range, gcd(4x-p, px)=1 and b=p*x.  Keep the assertion loud:
    # if it ever stops being true, the factor construction below must change.
    if g != 1 or x >= p:
        raise AssertionError("prime-domain remainder invariant failed")

    fac = factor64(x)
    b2_fac = {q: 2 * e for q, e in fac.items()}
    b2_fac[p] = b2_fac.get(p, 0) + 2
    # Larger bases first prune d > b earlier.
    items = tuple(sorted(b2_fac.items(), reverse=True))

    for d in _divisors_lte(items, b):
        if (b + d) % a:
            continue
        y = (b + d) // a
        if y < x:
            continue
        e = (b * b) // d
        if (b + e) % a:
            # With gcd(a,b)=1 and d | b^2, the paired divisor should satisfy
            # the same congruence once d does.  Keep this check rather than
            # relying on that implication silently.
            continue
        z = (b + e) // a
        if y > z:
            continue
        w = GeneralWitness(x, y, z, a, b, d)
        if verify_general_witness(p, w):
            return w
    return None


def search_general(
    p: int,
    *,
    x_count: int = DEFAULT_X_COUNT,
    x_from: int | None = None,
    complete: bool = False,
) -> dict:
    """Search the full ES equation without a Type A/B parametrization.

    `complete=True` requests the complete canonical x-domain.  Otherwise the
    search examines at most `x_count` consecutive x values starting at
    max(floor(p/4)+1, x_from).
    """
    if not is_prime64(p):
        raise ValueError("general model-escape search currently requires a 64-bit prime")
    if x_count < 1:
        raise ValueError("x_count must be >= 1")

    x_min = p // 4 + 1
    x_max = (3 * p) // 4
    start = max(x_min, x_from if x_from is not None else x_min)
    if start > x_max:
        return {
            "found": False,
            "requested_complete": complete,
            "domain_exhausted": complete and start == x_min,
            "canonical_x_min": x_min,
            "canonical_x_max": x_max,
            "x_start": start,
            "x_stop": x_max,
            "x_tested": 0,
        }
    stop = x_max if complete else min(x_max, start + x_count - 1)

    tested = 0
    for x in range(start, stop + 1):
        tested += 1
        w = _witness_for_x(p, x)
        if w is None:
            continue
        return {
            "found": True,
            "requested_complete": complete,
            "domain_exhausted": False,
            "canonical_x_min": x_min,
            "canonical_x_max": x_max,
            "x_start": start,
            "x_stop": stop,
            "x_tested": tested,
            "witness": asdict(w),
            "equation": w.equation(p),
            "verified": verify_general_witness(p, w),
        }

    return {
        "found": False,
        "requested_complete": complete,
        "domain_exhausted": complete and start == x_min and stop == x_max,
        "canonical_x_min": x_min,
        "canonical_x_max": x_max,
        "x_start": start,
        "x_stop": stop,
        "x_tested": tested,
    }


def _run_c_audit(p: int, K: int) -> tuple[dict | None, str | None]:
    if not AUDIT_BINARY.is_file():
        return None, "cbis-audit binary missing"
    proc = subprocess.run(
        [str(AUDIT_BINARY), str(p), "--k-max", str(K)],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if proc.returncode != 0:
        return None, (proc.stderr.strip() or f"cbis-audit exited {proc.returncode}")
    try:
        return json.loads(proc.stdout), None
    except json.JSONDecodeError as exc:
        return None, f"cbis-audit returned invalid JSON: {exc}"


def _audit_consistent(py_ab: ABHit, c_audit: dict | None) -> bool | None:
    if c_audit is None:
        return None
    cab = c_audit.get("full_type_ab") or {}
    if bool(cab.get("found")) != py_ab.found:
        return False
    if not py_ab.found:
        return True
    return (
        cab.get("type") == py_ab.type
        and int(cab.get("k")) == py_ab.k
        and int(cab.get("m")) == py_ab.m
        and int(cab.get("d")) == py_ab.d
        and int(cab.get("n_parameter")) == py_ab.n
    )


def observe_prime(
    p: int,
    *,
    ab_k: int,
    x_count: int,
    x_from: int | None,
    complete: bool,
) -> dict:
    if p < 2 or p > U64_MAX:
        raise ValueError("p must be in 2..2^64-1")
    prime = is_prime64(p)
    hard = prime and p % 840 in HARD
    if not prime:
        return {
            "kernel": "cbis-model-escape",
            "n": p,
            "prime": False,
            "hard_prime": False,
            "classification": "NOT_PRIME",
        }

    py_ab = full_ab_through(p, ab_k)
    c_audit, audit_error = _run_c_audit(p, ab_k)
    consistent = _audit_consistent(py_ab, c_audit)
    general = search_general(p, x_count=x_count, x_from=x_from, complete=complete)
    model_escape = bool(general.get("found")) and not py_ab.found

    if consistent is False:
        classification = "AUDIT_DISAGREEMENT"
    elif py_ab.found:
        classification = "AB_EXPLAINED_THROUGH_K"
    elif general.get("found"):
        classification = "GENERAL_ES_WITNESS_AB_UNSEEN_THROUGH_K"
    elif general.get("domain_exhausted"):
        classification = "COMPLETE_GENERAL_SEARCH_NO_WITNESS_REQUIRES_INDEPENDENT_VERIFICATION"
    else:
        classification = "AB_UNSEEN_THROUGH_K_GENERAL_SEARCH_INCOMPLETE"

    cover = c_audit.get("cover") if c_audit else None
    cover_escape = False
    if cover and not py_ab.found:
        cover_escape = any(bool(cover.get(k)) for k in ("W", "I", "N"))

    out = {
        "kernel": "cbis-model-escape",
        "n": p,
        "prime": True,
        "hard_prime": hard,
        "ab_bound_K": ab_k,
        "type_ab": asdict(py_ab),
        "ab_unseen_through_K": not py_ab.found,
        "general": general,
        "general_model_escape_candidate": model_escape,
        "cover_escape_candidate": cover_escape,
        "classification": classification,
        "c_audit": c_audit,
        "c_audit_error": audit_error,
        "c_python_ab_consistent": consistent,
        "claim_boundary": (
            "A/B unseen through finite K is not proof that Type A/B is false. "
            "A general exact witness only shows that Erdős–Straus can already "
            "be witnessed while the bounded A/B search remains unresolved."
        ),
    }
    if general.get("domain_exhausted") and not general.get("found"):
        out["counterexample_boundary"] = (
            "A complete exact no-witness result would be extraordinary. Do not "
            "publish it as an Erdős–Straus counterexample without an independent "
            "implementation and certificate review."
        )
    return out


def _evidence_id(result: dict) -> str:
    w = result["general"]["witness"]
    text = (
        "ES-MODEL-ESCAPE-v1\n"
        f"p={result['n']}\n"
        f"K={result['ab_bound_K']}\n"
        f"x={w['x']}\n"
        f"y={w['y']}\n"
        f"z={w['z']}\n"
    )
    return "ME-" + hashlib.sha256(text.encode("utf-8")).hexdigest()[:32]


def record_evidence(result: dict) -> Path | None:
    if not result.get("general_model_escape_candidate"):
        return None
    if result.get("c_python_ab_consistent") is False:
        raise RuntimeError("refusing to record evidence while C/Python A/B audits disagree")
    if not result.get("general", {}).get("verified"):
        raise RuntimeError("refusing to record an unverified general witness")

    EVIDENCE.mkdir(parents=True, exist_ok=True)
    ident = _evidence_id(result)
    path = EVIDENCE / f"{ident}.json"
    payload = dict(result)
    payload["evidence_id"] = ident
    payload["evidence_schema"] = "ES-MODEL-ESCAPE-v1"
    payload["record_kind"] = "bounded-model-escape-candidate"

    if not path.exists():
        fd, tmp_name = tempfile.mkstemp(prefix=f".{ident}.", suffix=".tmp", dir=EVIDENCE)
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as f:
                json.dump(payload, f, indent=2, sort_keys=True)
                f.write("\n")
                f.flush()
                os.fsync(f.fileno())
            os.replace(tmp_name, path)
        finally:
            if os.path.exists(tmp_name):
                os.unlink(tmp_name)

        journal = EVIDENCE / "JOURNAL.md"
        with journal.open("a", encoding="utf-8") as f:
            f.write(
                f"- `{ident}` p={result['n']} K={result['ab_bound_K']} "
                f"x={result['general']['witness']['x']} "
                "general witness / A-B unseen through K\n"
            )
    return path


def _letter_primes() -> list[int]:
    found: set[int] = set()
    if not LETTERS.exists():
        return []
    patterns = (
        re.compile(r"\*\*n:\*\*\s*(\d+)"),
        re.compile(r"\bn=(\d+)\b"),
    )
    for path in LETTERS.glob("*.md"):
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for pat in patterns:
            m = pat.search(text)
            if m:
                found.add(int(m.group(1)))
                break
    return sorted(found)


def _emit(obj: object) -> None:
    json.dump(obj, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        prog="cbis-escape",
        description="Exact general Erdős–Straus observer outside the Type A/B model",
    )
    ap.add_argument("target", help="prime to inspect, or 'letters'")
    ap.add_argument("--ab-k", type=int, default=DEFAULT_AB_K, dest="ab_k")
    ap.add_argument(
        "--x-count",
        type=int,
        default=DEFAULT_X_COUNT,
        help=f"bounded canonical x values to inspect (default {DEFAULT_X_COUNT})",
    )
    ap.add_argument("--x-from", type=int, default=None)
    ap.add_argument(
        "--complete",
        action="store_true",
        help="search the complete canonical x-domain; can be very expensive",
    )
    ap.add_argument(
        "--record",
        action="store_true",
        help="persist exact bounded model-escape witnesses under evidence/",
    )
    ap.add_argument(
        "--limit",
        type=int,
        default=20,
        help="with target=letters, inspect at most this many letters",
    )
    args = ap.parse_args(argv)

    if args.ab_k < 1:
        ap.error("--ab-k must be >= 1")
    if args.x_count < 1:
        ap.error("--x-count must be >= 1")
    if args.limit < 1:
        ap.error("--limit must be >= 1")

    if args.target == "letters":
        rows = []
        for p in _letter_primes()[: args.limit]:
            row = observe_prime(
                p,
                ab_k=args.ab_k,
                x_count=args.x_count,
                x_from=args.x_from,
                complete=args.complete,
            )
            if args.record:
                path = record_evidence(row)
                row["evidence_file"] = str(path.relative_to(ROOT)) if path else None
            rows.append(row)
        _emit(
            {
                "kernel": "cbis-model-escape",
                "mode": "letters",
                "count": len(rows),
                "results": rows,
            }
        )
        return 0

    try:
        p = int(args.target, 0)
    except ValueError:
        ap.error("target must be an integer prime or 'letters'")
        return 2

    result = observe_prime(
        p,
        ab_k=args.ab_k,
        x_count=args.x_count,
        x_from=args.x_from,
        complete=args.complete,
    )
    if args.record:
        path = record_evidence(result)
        result["evidence_file"] = str(path.relative_to(ROOT)) if path else None
    _emit(result)
    return 0 if result.get("prime") else 2


if __name__ == "__main__":
    raise SystemExit(main())
