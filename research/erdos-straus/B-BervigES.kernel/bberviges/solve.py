"""B-BervigES.kernel driver: solve one n, a range, or a residual."""

from __future__ import annotations

from collections import Counter
from dataclasses import dataclass, field

from .arithmetic import HARD, Factorizer
from .menu import (
    KERNEL_MENU,
    is_hard_prime,
    lopez_ab,
    search_corridor,
    search_external_nr,
    theorem_fab_small,
)
from .witness import Witness, scale_witness, verify_witness


@dataclass
class SolveResult:
    n: int
    witness: Witness | None
    failed: bool = False

    @property
    def solved(self) -> bool:
        return self.witness is not None and not self.failed


class Solver:
    def __init__(
        self,
        *,
        sieve_limit: int = 200_000,
        k_max: int = 400,
        ell_max: int = 200,
        ab_max: int = 11,
        through_layer: str = "search",
        prefer_cc: bool = True,
    ) -> None:
        self.fx = Factorizer(sieve_limit)
        self.k_max = k_max
        self.ell_max = ell_max
        self.ab_max = ab_max
        self.through_layer = through_layer
        self.prefer_cc = prefer_cc
        self._cache: dict[int, Witness] = {}

    def _apply_named(self, name: str, n: int) -> Witness | None:
        if name == "corridor-scan":
            return search_corridor(n, self.fx, self.k_max)
        if name == "lopez-AB":
            return lopez_ab(n, self.fx, self.k_max)
        if name == "external-nr":
            return search_external_nr(n, self.fx, self.ell_max)
        if name == "fab<=11":
            return theorem_fab_small(n, self.fx, self.ab_max)
        for layer, nm, fn in KERNEL_MENU:
            if nm == name:
                return fn(n, self.fx)
        raise KeyError(name)

    def _allowed(self, layer: str) -> bool:
        order = ("classical", "theorem", "window", "search")
        return order.index(layer) <= order.index(self.through_layer)

    def solve_prime(self, p: int) -> Witness | None:
        if p in self._cache:
            return self._cache[p]
        for layer, name, _fn in KERNEL_MENU:
            if not self._allowed(layer):
                continue
            w = self._apply_named(name, p)
            if w is not None:
                self._cache[p] = w
                return w
        return None

    def solve(self, n: int) -> SolveResult:
        if n < 2:
            return SolveResult(n, None, failed=True)
        if n in self._cache:
            return SolveResult(n, self._cache[n])

        if self.prefer_cc:
            from .cc_bridge import solve_via_cc

            w = solve_via_cc(n, k_max=self.k_max, through=self.through_layer)
            if w is not None:
                self._cache[n] = w
                return SolveResult(n, w)

        # Direct classical identities apply to every n, not only primes.
        for layer, name, _fn in KERNEL_MENU:
            if layer != "classical" or not self._allowed(layer):
                continue
            w = self._apply_named(name, n)
            if w is not None:
                self._cache[n] = w
                return SolveResult(n, w)

        if self.fx.is_prime(n):
            w = self.solve_prime(n)
            return SolveResult(n, w, failed=w is None)

        # Composite: scale a solution of the least prime factor.
        q = self.fx.first_prime_factor(n)
        base = self.solve(q)
        if base.witness is None:
            return SolveResult(n, None, failed=True)
        w = scale_witness(base.witness, n // q, method=f"scale-from-{q}")
        self._cache[n] = w
        return SolveResult(n, w)

    def solve_range(self, limit: int) -> dict:
        hist: Counter[str] = Counter()
        kind: Counter[str] = Counter()
        unsolved: list[int] = []
        examples: list[dict] = []
        for n in range(2, limit + 1):
            r = self.solve(n)
            if r.witness is None:
                unsolved.append(n)
                hist["unsolved"] += 1
                continue
            hist[r.witness.method] += 1
            kind[r.witness.kind] += 1
            if len(examples) < 12:
                examples.append(
                    {
                        "n": n,
                        "equation": r.witness.equation(),
                        "method": r.witness.method,
                        "layer": r.witness.layer,
                    }
                )
        return {
            "kernel": "B-BervigES.kernel",
            "limit": limit,
            "through_layer": self.through_layer,
            "solved": limit - 1 - len(unsolved),
            "unsolved": unsolved,
            "methods": dict(hist),
            "kinds": dict(kind),
            "examples": examples,
            "claim_boundary": (
                "a solved finite range is a certificate for those n only; "
                "it is not a proof of the Erdős–Straus conjecture"
            ),
        }

    def residual(self, limit: int) -> dict:
        """Hard primes that escape the theorem layers."""
        saved = self.through_layer
        self.through_layer = "theorem"
        escaped: list[dict] = []
        caught: Counter[str] = Counter()
        if limit <= self.fx.primes[-1]:
            hard = [p for p in self.fx.primes if is_hard_prime(p) and p <= limit]
        else:
            hard = [
                p
                for p in range(7, limit + 1, 2)
                if is_hard_prime(p) and self.fx.is_prime(p)
            ]
        for p in hard:
            w = self.solve_prime(p)
            if w is None:
                escaped.append({"p": p, "mod840": p % 840})
            else:
                caught[w.method] += 1
        self.through_layer = saved
        search_hits: list[dict] = []
        still = []
        if escaped and saved == "search":
            self.through_layer = "search"
            for row in escaped:
                w = self.solve_prime(row["p"])
                if w is None:
                    still.append(row)
                else:
                    search_hits.append(
                        {
                            "p": row["p"],
                            "method": w.method,
                            "kind": w.kind,
                            "equation": w.equation(),
                        }
                    )
            self.through_layer = saved
        return {
            "kernel": "B-BervigES.kernel",
            "limit": limit,
            "hard_primes": len(hard),
            "theorem_caught": dict(caught),
            "theorem_escaped": escaped,
            "search_rescued": search_hits,
            "still_open_after_search": still,
            "claim_boundary": (
                "theorem_escaped is the finite residual after proved layers only. "
                "Empty search residual is not a proof of Erdős–Straus."
            ),
        }


def check_result(result: SolveResult) -> bool:
    return result.witness is not None and verify_witness(result.witness)
