"""Egyptian-fraction witnesses and two-target / fab reconstruction."""

from __future__ import annotations

from dataclasses import asdict, dataclass, field


@dataclass(frozen=True)
class Witness:
    n: int
    x: int
    y: int
    z: int
    layer: str
    method: str
    kind: str
    detail: dict = field(default_factory=dict)

    def sorted_denoms(self) -> tuple[int, int, int]:
        return tuple(sorted((self.x, self.y, self.z)))

    def as_dict(self) -> dict:
        d = asdict(self)
        d["denominators"] = list(self.sorted_denoms())
        return d

    def equation(self) -> str:
        x, y, z = self.sorted_denoms()
        return f"4/{self.n} = 1/{x} + 1/{y} + 1/{z}"


def verify_witness(w: Witness) -> bool:
    if min(w.n, w.x, w.y, w.z) <= 0:
        return False
    return 4 * w.x * w.y * w.z == w.n * (w.y * w.z + w.x * w.z + w.x * w.y)


def make_witness(
    n: int,
    x: int,
    y: int,
    z: int,
    *,
    layer: str,
    method: str,
    kind: str,
    detail: dict | None = None,
) -> Witness:
    a, b, c = sorted((int(x), int(y), int(z)))
    w = Witness(
        n=int(n),
        x=a,
        y=b,
        z=c,
        layer=layer,
        method=method,
        kind=kind,
        detail=dict(detail or {}),
    )
    if not verify_witness(w):
        raise ValueError(f"invalid witness for n={n}: {w.equation()}")
    return w


def scale_witness(w: Witness, m: int, *, method: str) -> Witness:
    if m <= 0:
        raise ValueError("scale must be positive")
    return make_witness(
        w.n * m,
        w.x * m,
        w.y * m,
        w.z * m,
        layer=w.layer,
        method=method,
        kind="scaled",
        detail={"from_n": w.n, "scale": m, "base_method": w.method},
    )


def exponents_to_bdt(
    factors: dict[int, int], exponents: dict[int, int]
) -> tuple[int, int, int]:
    b = 1
    d = 1
    t = 1
    for r, e in factors.items():
        z = exponents.get(r, 0)
        if abs(z) > e:
            raise ValueError("exponent exceeds valuation")
        if z > 0:
            b *= r**z
            t *= r ** (e - z)
        elif z < 0:
            d *= r ** (-z)
            t *= r ** (e + z)
        else:
            t *= r**e
    return b, d, t


def signed_box_map(factors: dict[int, int], mod: int) -> dict[int, dict[int, int]]:
    if mod <= 1:
        return {}
    reach: dict[int, dict[int, int]] = {1 % mod: {}}
    for r, e in factors.items():
        if pow(r, 1, mod) == 0 or _gcd(r, mod) != 1:
            return {}
        nxt: dict[int, dict[int, int]] = {}
        powers = [(z, pow(r, z, mod)) for z in range(-e, e + 1)]
        for val, exp in reach.items():
            for z, pz in powers:
                nv = (val * pz) % mod
                if nv not in nxt:
                    ne = dict(exp)
                    if z:
                        ne[r] = z
                    nxt[nv] = ne
        reach = nxt
    return reach


def reconstruct_type_ii(
    p: int, k: int, factors: dict[int, int], exponents: dict[int, int]
) -> tuple[int, int, int]:
    b, d, t = exponents_to_bdt(factors, exponents)
    if (b + d) % k:
        raise ValueError("Type II ratio does not meet k | B+D")
    a = (b + d) // k
    x = a * b * t * p
    y = b * t * d
    z = a * t * d * p
    return x, y, z


def reconstruct_type_i(
    p: int, k: int, factors: dict[int, int], exponents: dict[int, int]
) -> tuple[int, int, int]:
    b, d, t = exponents_to_bdt(factors, exponents)
    if (d + p * b) % k:
        raise ValueError("Type I ratio does not meet k | D+pB")
    a = (d + p * b) // k
    x = a * b * t * p
    y = b * t * d
    z = a * t * d
    return x, y, z


def reconstruct_fab(p: int, a: int, b: int, k: int) -> tuple[int, int, int]:
    if (p + k) % (4 * a * b):
        raise ValueError("fab modulus does not divide p+k")
    t = (p + k) // (4 * a * b)
    if (a + b * p) % k:
        raise ValueError("fab k does not divide a+bp")
    q = (a + b * p) // k
    return a * b * t, a * q * t, b * p * q * t


def _gcd(a: int, b: int) -> int:
    while b:
        a, b = b, a % b
    return abs(a)
