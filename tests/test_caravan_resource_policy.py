from __future__ import annotations

import unittest

from caravan.resource_policy import (
    CarrierResourcePolicy,
    GIB,
    MIB,
    MonthlyTransferBudget,
    ResourcePolicyError,
)


class CarrierResourcePolicyTests(unittest.TestCase):
    def test_defaults_are_bounded_and_round_trip_exactly(self) -> None:
        policy = CarrierResourcePolicy()
        self.assertEqual(policy.storage_limit_bytes, 10 * GIB)
        self.assertEqual(policy.min_free_bytes, 512 * MIB)
        self.assertEqual(policy.outbound_bytes_per_second, 4 * MIB)
        self.assertEqual(policy.max_concurrent_transfers, 4)
        self.assertEqual(policy.max_queue_depth, 32)
        self.assertEqual(policy.request_deadline_seconds, 120.0)
        self.assertEqual(policy.monthly_transfer_limit_bytes, 250 * GIB)
        self.assertEqual(CarrierResourcePolicy.from_dict(policy.to_dict()), policy)

    def test_policy_schema_must_match_exactly(self) -> None:
        value = CarrierResourcePolicy().to_dict()
        missing = dict(value)
        missing.pop("max_queue_depth")
        with self.assertRaises(ResourcePolicyError):
            CarrierResourcePolicy.from_dict(missing)

        extra = dict(value)
        extra["unexpected_field"] = 1
        with self.assertRaises(ResourcePolicyError):
            CarrierResourcePolicy.from_dict(extra)

    def test_values_above_safety_ceilings_are_rejected(self) -> None:
        defaults = CarrierResourcePolicy().to_dict()
        cases = (
            ("storage_limit_bytes", 5000 * GIB),
            ("min_free_bytes", 10 * GIB),
            ("outbound_bytes_per_second", 2048 * MIB),
            ("max_concurrent_transfers", 65),
            ("max_queue_depth", 4097),
            ("request_deadline_seconds", 4000),
            ("monthly_transfer_limit_bytes", 101 * 1024 * GIB),
        )
        for name, setting in cases:
            with self.subTest(name=name):
                value = dict(defaults)
                value[name] = setting
                with self.assertRaises(ResourcePolicyError):
                    CarrierResourcePolicy.from_dict(value)


class MonthlyTransferBudgetTests(unittest.TestCase):
    def test_budget_tracks_usage_and_stops_at_ceiling(self) -> None:
        budget = MonthlyTransferBudget(limit_bytes=100, window_started_at=10)
        budget.reserve(40, now=11)
        self.assertEqual(budget.remaining(now=12), 60)
        budget.reserve(60, now=13)
        self.assertEqual(budget.remaining(now=14), 0)
        with self.assertRaises(ResourcePolicyError):
            budget.reserve(1, now=15)

    def test_new_window_resets_usage(self) -> None:
        budget = MonthlyTransferBudget(
            limit_bytes=100,
            window_started_at=10,
            used_bytes=90,
            window_seconds=30,
        )
        self.assertEqual(budget.remaining(now=40), 100)
        budget.reserve(25, now=40)
        self.assertEqual(budget.remaining(now=41), 75)

    def test_clock_rollback_is_rejected(self) -> None:
        budget = MonthlyTransferBudget(limit_bytes=100, window_started_at=10)
        with self.assertRaises(ResourcePolicyError):
            budget.reserve(1, now=9)


if __name__ == "__main__":
    unittest.main()
