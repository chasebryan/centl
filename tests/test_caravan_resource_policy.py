from __future__ import annotations

import unittest

from caravan.resource_policy import CarrierResourcePolicy


class CarrierResourcePolicyTests(unittest.TestCase):
    def test_defaults(self) -> None:
        policy = CarrierResourcePolicy()
        self.assertGreater(policy.storage_limit_bytes, 0)
        self.assertGreater(policy.min_free_bytes, 0)


if __name__ == "__main__":
    unittest.main()
