from __future__ import annotations

import json
from pathlib import Path
import sys
import tempfile
import threading
import unittest
from urllib.error import HTTPError
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from caravan.coordinator import CoordinatorState
from caravan.identity import CarrierIdentity
from caravan.observability import ObservabilityStore
from caravan.policy import create_policy_receipt
from caravan.public_service import PublicCoordinatorService
from caravan.transport import CarrierTransportClient


class CaravanObservabilityTests(unittest.TestCase):
    def test_enrollment_funnel_is_durable_aggregate_and_not_public(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            database = root / "coordinator.sqlite"
            coordinator = CoordinatorState(database, heartbeat_ttl=1800)
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
                endpoint = f"http://{host}:{port}"

                bad = Request(
                    f"{endpoint}/v1/enroll",
                    data=b"{}",
                    method="POST",
                    headers={"Content-Type": "application/json"},
                )
                with self.assertRaises(HTTPError) as rejected:
                    urlopen(bad)
                self.assertEqual(rejected.exception.code, 400)

                identity = CarrierIdentity.create(root / "identity")
                receipt = create_policy_receipt(
                    identity,
                    ROOT / "docs" / "CARAVAN-HOST-POLICY.md",
                    policy_version="FCF-CARAVAN-HOST-v1",
                    agent_version="test-version",
                    acceptance_mode="interactive",
                )
                client = CarrierTransportClient(endpoint, identity, allow_loopback_http=True)
                self.assertEqual(client.enroll(receipt.to_dict())["caravan_number"], 1)
                client.connect()
                client.heartbeat(load=0, capacity=1024)
                client.heartbeat(load=0, capacity=1024)

                snapshot = ObservabilityStore(database).snapshot()
                self.assertEqual(snapshot.enrollment_requests, 2)
                self.assertEqual(snapshot.enrollment_accepted, 1)
                self.assertEqual(snapshot.enrollment_rejected, 1)
                self.assertEqual(snapshot.enrollment_incomplete, 0)
                self.assertEqual(snapshot.session_challenges_issued, 1)
                self.assertEqual(snapshot.session_completions_succeeded, 1)
                self.assertEqual(snapshot.registered_carriers, 1)
                self.assertEqual(snapshot.highest_caravan_number, 1)
                self.assertEqual(snapshot.first_heartbeat_carriers, 1)
                self.assertEqual(snapshot.active_camels, 1)

                with self.assertRaises(HTTPError) as hidden:
                    urlopen(f"{endpoint}/observability-v1.json")
                self.assertEqual(hidden.exception.code, 404)

                census = urlopen(f"{endpoint}/census-v1.json").read().decode("utf-8")
                self.assertNotIn("enrollment_requests", census)
                self.assertNotIn(identity.node_id, census)
                self.assertNotIn(identity.public_identity, census)

                serialized = json.dumps(snapshot.to_dict(), sort_keys=True)
                self.assertNotIn(identity.node_id, serialized)
                self.assertNotIn(identity.public_identity, serialized)
            finally:
                service.close()


if __name__ == "__main__":
    unittest.main()
