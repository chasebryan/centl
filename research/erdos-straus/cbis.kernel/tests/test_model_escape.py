#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODULE = ROOT / "cbis_escape.py"
spec = importlib.util.spec_from_file_location("cbis_escape", MODULE)
assert spec is not None and spec.loader is not None
cbis_escape = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = cbis_escape
spec.loader.exec_module(cbis_escape)


class ModelEscapeTests(unittest.TestCase):
    def test_record_prime_ab_depth_boundary(self) -> None:
        p = 9_658_489
        shallow = cbis_escape.full_ab_through(p, 400)
        self.assertFalse(shallow.found)

        deep = cbis_escape.full_ab_through(p, 3000)
        self.assertTrue(deep.found)
        self.assertEqual(deep.type, "B")
        self.assertEqual(deep.k, 2622)
        self.assertEqual(deep.m, 10487)
        self.assertEqual(deep.d, 69)
        self.assertEqual(deep.n, 38)

    def test_general_search_is_independent_of_ab_depth(self) -> None:
        p = 9_658_489
        result = cbis_escape.search_general(p, x_count=8)
        self.assertTrue(result["found"])
        self.assertTrue(result["verified"])
        w = result["witness"]
        # x is stable: the first canonical x with a general witness.  The
        # valid divisor pair within that x need not be unique, so y/z are
        # verified mathematically rather than frozen to one enumeration order.
        self.assertEqual(w["x"], 2_414_624)
        witness = cbis_escape.GeneralWitness(
            x=w["x"],
            y=w["y"],
            z=w["z"],
            remainder_a=w["remainder_a"],
            remainder_b=w["remainder_b"],
            divisor_d=w["divisor_d"],
        )
        self.assertTrue(cbis_escape.verify_general_witness(p, witness))
        self.assertLessEqual(w["x"], w["y"])
        self.assertLessEqual(w["y"], w["z"])

    def test_exact_verifier_rejects_perturbation(self) -> None:
        p = 2521
        result = cbis_escape.search_general(p, x_count=16)
        self.assertTrue(result["found"])
        w = result["witness"]
        bad = cbis_escape.GeneralWitness(
            x=w["x"],
            y=w["y"],
            z=w["z"] + 1,
            remainder_a=w["remainder_a"],
            remainder_b=w["remainder_b"],
            divisor_d=w["divisor_d"],
        )
        self.assertFalse(cbis_escape.verify_general_witness(p, bad))

    def test_small_prime_complete_domain_logic(self) -> None:
        p = 1009
        result = cbis_escape.search_general(p, x_count=10_000)
        self.assertTrue(result["found"])
        self.assertTrue(result["verified"])
        self.assertGreaterEqual(result["witness"]["x"], p // 4 + 1)
        self.assertLessEqual(result["witness"]["x"], 3 * p // 4)

    def test_prime_classifier(self) -> None:
        self.assertTrue(cbis_escape.is_prime64(9_658_489))
        self.assertFalse(cbis_escape.is_prime64(9_658_489 * 3))
        self.assertTrue(cbis_escape.is_prime64(2))


if __name__ == "__main__":
    unittest.main()
