from __future__ import annotations

from pathlib import Path
import tempfile
import threading
import unittest
from urllib.request import urlopen

from caravan.coordinator import CoordinatorState
from caravan.identity import CarrierIdentity
from caravan.policy import create_policy_receipt
from caravan.public_service import PublicCoordinatorService
from caravan.transport import CarrierTransportClient


ROOT = Path(__file__).resolve().parents[1]


class PublicCoordinatorServiceTests(unittest.TestCase):
    def test_enrollment_assigns_durable_live_number_and_census_is_aggregate(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            coordinator = CoordinatorState(root / "coordinator.sqlite", heartbeat_ttl=1800)
            service = PublicCoordinatorService(
                coordinator,
                policy_path=ROOT / "docs" / "CARAVAN-HOST-POLICY.md",
                policy_version="FCF-CARAVAN-HOST-v1",
                allowed_agent_versions={"test-version"},
                port=0,
            )
            thread = threading.Thread(target=service.serve_forever, daemon=True)
            thread.start()
            try:
                identity = CarrierIdentity.create(root / "identity")
                receipt = create_policy_receipt(
                    identity,
                    ROOT / "docs" / "CARAVAN-HOST-POLICY.md",
                    policy_version="FCF-CARAVAN-HOST-v1",
                    agent_version="test-version",
                    acceptance_mode="interactive",
                )
                host, port = service.address
                client = CarrierTransportClient(
                    f"http://{host}:{port}", identity, allow_loopback_http=True
                )
                result = client.enroll(receipt.to_dict())
                self.assertEqual(result["caravan_number"], 1)
                self.assertEqual(client.enroll(receipt.to_dict())["caravan_number"], 1)
                client.connect()
                client.heartbeat(load=0, capacity=1024)
                census = urlopen(f"http://{host}:{port}/census-v1.json").read().decode()
                self.assertIn('"active_camels":1', census)
                self.assertNotIn(identity.node_id, census)
                self.assertNotIn(identity.public_identity, census)
                self.assertEqual(client.withdraw()["state"], "withdrawn")
            finally:
                service.close()

    def test_public_service_has_no_unlisted_content_route(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            coordinator = CoordinatorState(root / "coordinator.sqlite")
            service = PublicCoordinatorService(
                coordinator,
                policy_path=ROOT / "docs" / "CARAVAN-HOST-POLICY.md",
                policy_version="FCF-CARAVAN-HOST-v1",
                allowed_agent_versions={"test-version"},
                port=0,
            )
            thread = threading.Thread(target=service.serve_forever, daemon=True)
            thread.start()
            try:
                host, port = service.address
                with self.assertRaises(Exception):
                    urlopen(f"http://{host}:{port}/coordinator.sqlite")
            finally:
                service.close()


if __name__ == "__main__":
    unittest.main()
