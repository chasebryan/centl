"""Ordered construction menu for B-BervigES.kernel.

Layers marked `classical` or `theorem` are proved sufficient families.
Layers marked `search` are constructive and not a universal proof.
"""

from __future__ import annotations

import math
from collections.abc import Callable, Iterator

from .arithmetic import HARD, Factorizer, jacobi
from .witness import (
    Witness,
    make_witness,
    reconstruct_fab,
    reconstruct_type_i,
    reconstruct_type_ii,
    signed_box_map,
)


LayerFn = Callable[[int, Factorizer], Witness | None]


def identity_even(n: int, _fx: Factorizer) -> Witness | None:
    if n % 2:
        return None
    m = n // 2
    return make_witness(
        n,
        m,
        m + 1,
        m * (m + 1),
        layer="classical",
        method="even",
        kind="identity",
    )


def identity_3mod4(n: int, _fx: Factorizer) -> Witness | None:
    if n % 4 != 3:
        return None
    m = (n - 3) // 4
    return make_witness(
        n,
        m + 2,
        (m + 1) * (m + 2),
        n * (m + 1),
        layer="classical",
        method="3mod4",
        kind="identity",
    )


def identity_2mod3(n: int, _fx: Factorizer) -> Witness | None:
    if n % 3 != 2:
        return None
    a = (n + 1) // 3
    return make_witness(
        n,
        n,
        a,
        n * a,
        layer="classical",
        method="2mod3",
        kind="identity",
    )


def identity_5mod8(n: int, _fx: Factorizer) -> Witness | None:
    if n % 8 != 5:
        return None
    # n = 8k+5.  Use 4/n - 1/((n+3)/2) and split the remainder.
    # (n+3)/2 = 4k+4 = 4(k+1). That is smaller than 4/n? skip if messy.
    # Standard: 4/(8k+5) = 1/(2k+2) + 1/((8k+5)(2k+2)/2) wait.
    k = (n - 5) // 8
    # 4/n = 1/(2(k+1)) + 1/(n(k+1)) + 1/(n(k+1))
    # 1/(2k+2) + 2/(n(k+1)) = (n + 4) / (2(k+1)n) = (8k+9)/(2(k+1)n) ≠ 4/n.
    # Use two-target later. Keep a known working identity:
    # 4/n = 1/((n+3)/4 * 2) ... n≡5 mod 8 ⇒ n+3 ≡ 0 mod 8, (n+3)/8 integer.
    t = (n + 3) // 8
    # Try 4/n = 1/(2t) + 1/(2t n) + 1/(n t)
    # 1/(2t)+1/(2tn)+1/(nt) = (n + 1 + 2)/(2 t n) = (n+3)/(2 t n)
    # n+3 = 8t, so (8t)/(2 t n) = 4/n. Yes.
    return make_witness(
        n,
        2 * t,
        2 * t * n,
        n * t,
        layer="classical",
        method="5mod8",
        kind="identity",
    )


def _divisor_in_class(n: int, fac: dict[int, int], mod: int, residue: int) -> int | None:
    reach: dict[int, int] = {1 % mod: 1}
    target = residue % mod
    for q, e in fac.items():
        nxt = dict(reach)
        for r, val in reach.items():
            v = val
            rr = r
            for _ in range(e):
                v *= q
                rr = (rr * (q % mod)) % mod
                if rr not in nxt:
                    nxt[rr] = v
        reach = nxt
        if target in reach:
            return reach[target]
    return reach.get(target)


def _has_divisor_class(n: int, mod: int, residue: int, fx: Factorizer) -> int | None:
    return _divisor_in_class(n, fx.factor(n), mod, residue)


def fab_pair(p: int, a: int, b: int, fx: Factorizer) -> Witness | None:
    if a <= 0 or b <= 0 or math.gcd(a, b) != 1:
        return None
    if a >= p or b >= p:
        return None
    nlin = a + b * p
    mod = 4 * a * b
    target = (-p) % mod
    k = _has_divisor_class(nlin, mod, target, fx)
    if k is None:
        return None
    x, y, z = reconstruct_fab(p, a, b, k)
    return make_witness(
        p,
        x,
        y,
        z,
        layer="window",
        method=f"fab({a},{b})",
        kind="fab",
        detail={"a": a, "b": b, "k": k},
    )


def theorem_p_plus_four(p: int, fx: Factorizer) -> Witness | None:
    if p % 2 == 0:
        return None
    fac = fx.factor(p + 4)
    k = _divisor_in_class(p + 4, fac, 4, 3)
    if k is None:
        return None
    m = (k + 1) // 4
    if (m * p + 1) % k:
        return None
    v = (m * p + 1) // k
    return make_witness(
        p,
        v,
        m * p,
        m * p * v,
        layer="theorem",
        method="p+4",
        kind="linear",
        detail={"q": k, "m": m},
    )


def theorem_4p_plus_one(p: int, fx: Factorizer) -> Witness | None:
    if p % 2 == 0:
        return None
    nlin = 4 * p + 1
    fac = fx.factor(nlin)
    f = _divisor_in_class(nlin, fac, 4, 3)
    if f is None:
        return None
    g = nlin // f
    if g % 4 != 3:
        return None
    u = (f + 1) // 4
    v = (g + 1) // 4
    return make_witness(
        p,
        u * v,
        p * v,
        p * u,
        layer="theorem",
        method="4p+1",
        kind="linear",
        detail={"F": f, "G": g},
    )


def theorem_fab_small(p: int, fx: Factorizer, ab_max: int = 11) -> Witness | None:
    if not fx.is_prime(p) or p % 4 != 1:
        return None
    pairs = [
        (a, b)
        for a in range(1, ab_max + 1)
        for b in range(1, ab_max + 1)
        if math.gcd(a, b) == 1
    ]
    # Prefer the pairs that historically clear the most hard survivors.
    pairs.sort(key=lambda ab: ((ab[0], ab[1]) != (1, 5), ab[0] + ab[1], ab))
    for a, b in pairs:
        w = fab_pair(p, a, b, fx)
        if w is not None:
            return w
    return None


def try_two_target(p: int, k: int, fx: Factorizer, *, layer: str, method: str) -> Witness | None:
    if k <= 1 or k % 4 != 3 or math.gcd(k, p) != 1:
        return None
    if (p + k) % 4:
        return None
    c = (p + k) // 4
    if c <= 0:
        return None
    fac = fx.factor(c)
    box = signed_box_map(fac, k)
    if not box:
        return None
    t_ii = (-1) % k
    t_i = (-pow(p, -1, k)) % k
    if t_ii in box:
        x, y, z = reconstruct_type_ii(p, k, fac, box[t_ii])
        return make_witness(
            p,
            x,
            y,
            z,
            layer=layer,
            method=method,
            kind="II",
            detail={"k": k, "C": c, "target": t_ii},
        )
    if t_i in box:
        x, y, z = reconstruct_type_i(p, k, fac, box[t_i])
        return make_witness(
            p,
            x,
            y,
            z,
            layer=layer,
            method=method,
            kind="I",
            detail={"k": k, "C": c, "target": t_i},
        )
    return None


def theorem_corridor_small(p: int, fx: Factorizer) -> Witness | None:
    if not fx.is_prime(p) or p % 4 != 1:
        return None
    for k in (3, 7, 11, 15):
        w = try_two_target(p, k, fx, layer="theorem", method=f"corridor[{k}]")
        if w is not None:
            return w
    return None


def search_corridor(p: int, fx: Factorizer, k_max: int) -> Witness | None:
    if not fx.is_prime(p) or p % 4 != 1:
        return None
    cap = min(k_max, (p + 4) // 3)
    for h in range(0, max(0, (cap - 3) // 4) + 1):
        k = 4 * h + 3
        if k in (3, 7, 11, 15):
            continue
        w = try_two_target(p, k, fx, layer="search", method=f"corridor[{k}]")
        if w is not None:
            return w
    return None


def search_external_nr(p: int, fx: Factorizer, ell_max: int = 200) -> Witness | None:
    if not fx.is_prime(p) or p % 4 != 1:
        return None
    for ell in fx.primes:
        if ell < 11 or ell > ell_max or ell == p:
            continue
        if jacobi(ell, p) != -1:
            continue
        if ell % 4 == 3:
            w = try_two_target(p, ell, fx, layer="search", method=f"nr-shift[{ell}]")
            if w is not None:
                return w
        k = (-p) % (4 * ell)
        if k == 0:
            k = 4 * ell
        w = try_two_target(p, k, fx, layer="search", method=f"nr-aligned[{ell}]")
        if w is not None:
            return w
    return None


def lopez_ab(p: int, fx: Factorizer, k_max: int) -> Witness | None:
    if not fx.is_prime(p):
        return None
    for k in range(1, k_max + 1):
        fac_k = fx.factor(k)
        divs = [1]
        for r, e in fac_k.items():
            more = []
            pe = 1
            for _ in range(e):
                pe *= r
                more.extend(d * pe for d in divs)
            divs.extend(more)
        m = 4 * k - 1
        for d in divs:
            nn = k // d
            if (p + 4 * d) % m == 0:
                q = (p + 4 * d) // m
                if q > 0:
                    u = nn * q - 1
                    if u > 0:
                        return make_witness(
                            p,
                            d * u,
                            k * p,
                            k * p * u,
                            layer="search",
                            method="lopez-A",
                            kind="A",
                            detail={"d": d, "n": nn, "k": k, "m": m, "q": q},
                        )
            if (p + nn) % m == 0:
                q = (p + nn) // m
                if q > 0:
                    return make_witness(
                        p,
                        k * q,
                        d * q * p,
                        k * p,
                        layer="search",
                        method="lopez-B",
                        kind="B",
                        detail={"d": d, "n": nn, "k": k, "m": m, "q": q},
                    )
    return None


KERNEL_MENU: list[tuple[str, str, LayerFn]] = [
    ("classical", "even", identity_even),
    ("classical", "3mod4", identity_3mod4),
    ("classical", "2mod3", identity_2mod3),
    ("classical", "5mod8", identity_5mod8),
    ("theorem", "4p+1", theorem_4p_plus_one),
    ("theorem", "p+4", theorem_p_plus_four),
    ("theorem", "corridor-3-7-11-15", theorem_corridor_small),
    ("window", "fab<=11", theorem_fab_small),
    ("search", "external-nr", search_external_nr),
    ("search", "corridor-scan", search_corridor),
    ("search", "lopez-AB", lopez_ab),
]


def iter_menu(through_layer: str | None = None) -> Iterator[tuple[str, str, LayerFn]]:
    order = ("classical", "theorem", "window", "search")
    stop = None if through_layer is None else order.index(through_layer)
    for layer, name, fn in KERNEL_MENU:
        if stop is not None and order.index(layer) > stop:
            break
        yield layer, name, fn


def is_hard_prime(p: int) -> bool:
    return p > 5 and p % 840 in HARD
