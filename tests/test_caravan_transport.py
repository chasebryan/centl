from __future__ import annotations

import hashlib
from pathlib import Path
import socket
import tempfile
import threading
import time
import unittest
from unittest import mock

from caravan.coordinator import CoordinatorState
from caravan.identity import CarrierIdentity
from caravan.session import SessionAuthority, SessionError, session_proof_payload
from caravan.transport import (
    CarrierTransportClient,
    CoordinatorLabService,
    TransportError,
)


def _artifact(data: bytes) -> str:
    return "sha256:" + hashlib.sha256(data).hexdigest()


def _register(coordinator: CoordinatorState, identity: CarrierIdentity) -> None:
    coordinator.register_carrier(
        identity.node_id,
        public_identity=identity.public_identity,
        policy_version="FCF-CARAVAN-HOST-lab-v1",
        agent_version="0.0.1-lab",
    )


class SessionTests(unittest.TestCase):
    def test_wrong_identity_fails_and_challenge_replay_is_burned(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            coordinator = CoordinatorState(root / "coordinator.sqlite")
            identity = CarrierIdentity.create(root / "identity-a")
            attacker = CarrierIdentity.create(root / "identity-b")
            _register(coordinator, identity)
            _register(coordinator, attacker)
            sessions = SessionAuthority(coordinator)

            challenge = sessions.issue_challenge(identity.node_id)
            payload = session_proof_payload(
                identity.node_id,
                challenge.challenge_id,
                challenge.challenge,
            )
            with self.assertRaises(SessionError):
                sessions.complete_challenge(
                    node_id=identity.node_id,
                    challenge_id=challenge.challenge_id,
                    challenge=challenge.challenge,
                    signature=attacker.sign(payload),
                )

            with self.assertRaises(SessionError):
                sessions.complete_challenge(
                    node_id=identity.node_id,
                    challenge_id=challenge.challenge_id,
                    challenge=challenge.challenge,
                    signature=identity.sign(payload),
                )

    def test_expired_session_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            coordinator = CoordinatorState(root / "coordinator.sqlite")
            identity = CarrierIdentity.create(root / "identity")
            _register(coordinator, identity)
            sessions = SessionAuthority(coordinator, challenge_ttl=2, session_ttl=3)
            challenge = sessions.issue_challenge(identity.node_id, now=10)
            payload = session_proof_payload(
                identity.node_id,
                challenge.challenge_id,
                challenge.challenge,
            )
            session = sessions.complete_challenge(
                node_id=identity.node_id,
                challenge_id=challenge.challenge_id,
                challenge=challenge.challenge,
                signature=identity.sign(payload),
                now=11,
            )
            self.assertEqual(sessions.authenticate(session.token, now=13), identity.node_id)
            with self.assertRaises(SessionError):
                sessions.authenticate(session.token, now=15)

    def test_pending_challenges_are_globally_and_per_carrier_bounded(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            coordinator = CoordinatorState(root / "coordinator.sqlite")
            identity_a = CarrierIdentity.create(root / "identity-a")
            identity_b = CarrierIdentity.create(root / "identity-b")
            _register(coordinator, identity_a)
            _register(coordinator, identity_b)
            sessions = SessionAuthority(
                coordinator,
                max_pending_challenges=2,
                max_challenges_per_node=1,
            )

            sessions.issue_challenge(identity_a.node_id, now=10)
            with self.assertRaisesRegex(SessionError, "for carrier"):
                sessions.issue_challenge(identity_a.node_id, now=10)
            sessions.issue_challenge(identity_b.node_id, now=10)

            identity_c = CarrierIdentity.create(root / "identity-c")
            _register(coordinator, identity_c)
            with self.assertRaisesRegex(SessionError, "too many pending carrier"):
                sessions.issue_challenge(identity_c.node_id, now=10)

    def test_active_session_count_is_bounded(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            coordinator = CoordinatorState(root / "coordinator.sqlite")
            identity = CarrierIdentity.create(root / "identity")
            _register(coordinator, identity)
            sessions = SessionAuthority(
                coordinator,
                max_pending_challenges=2,
                max_challenges_per_node=2,
                max_active_sessions=1,
                max_sessions_per_node=1,
            )

            first = sessions.issue_challenge(identity.node_id, now=10)
            first_payload = session_proof_payload(
                identity.node_id,
                first.challenge_id,
                first.challenge,
            )
            sessions.complete_challenge(
                node_id=identity.node_id,
                challenge_id=first.challenge_id,
                challenge=first.challenge,
                signature=identity.sign(first_payload),
                now=10,
            )

            second = sessions.issue_challenge(identity.node_id, now=10)
            second_payload = session_proof_payload(
                identity.node_id,
                second.challenge_id,
                second.challenge,
            )
            with self.assertRaisesRegex(SessionError, "too many active sessions for carrier"):
                sessions.complete_challenge(
                    node_id=identity.node_id,
                    challenge_id=second.challenge_id,
                    challenge=second.challenge,
                    signature=identity.sign(second_payload),
                    now=10,
                )

    def test_one_carrier_cannot_monopolize_global_session_pool(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            coordinator = CoordinatorState(root / "coordinator.sqlite")
            identity_a = CarrierIdentity.create(root / "identity-a")
            identity_b = CarrierIdentity.create(root / "identity-b")
            _register(coordinator, identity_a)
            _register(coordinator, identity_b)
            sessions = SessionAuthority(
                coordinator,
                max_pending_challenges=4,
                max_challenges_per_node=2,
                max_active_sessions=2,
                max_sessions_per_node=1,
            )

            def complete(identity: CarrierIdentity):
                challenge = sessions.issue_challenge(identity.node_id, now=10)
                payload = session_proof_payload(
                    identity.node_id,
                    challenge.challenge_id,
                    challenge.challenge,
                )
                return sessions.complete_challenge(
                    node_id=identity.node_id,
                    challenge_id=challenge.challenge_id,
                    challenge=challenge.challenge,
                    signature=identity.sign(payload),
                    now=10,
                )

            complete(identity_a)
            with self.assertRaisesRegex(SessionError, "too many active sessions for carrier"):
                complete(identity_a)

            session_b = complete(identity_b)
            self.assertEqual(sessions.authenticate(session_b.token, now=10), identity_b.node_id)


class OutboundTransportTests(unittest.TestCase):
    def test_carrier_connects_outbound_heartbeats_advertises_and_polls(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            coordinator = CoordinatorState(root / "coordinator.sqlite", heartbeat_ttl=30)
            identity = CarrierIdentity.create(root / "identity")
            _register(coordinator, identity)
            artifact_id = _artifact(b"approved artifact")
            coordinator.apply_authenticated_catalog(
                [(artifact_id, len(b"approved artifact"), "public-approved")],
                catalog_version=1,
            )

            with CoordinatorLabService(coordinator) as service:
                client = CarrierTransportClient(
                    service.base_url,
                    identity,
                    allow_loopback_http=True,
                )
                # The coordinator is already listening. If carrier code tries to
                # bind a listening socket, fail the test: normal carrier behavior
                # is outbound-only.
                with mock.patch.object(
                    socket.socket,
                    "bind",
                    side_effect=AssertionError("carrier attempted inbound bind"),
                ):
                    client.connect()
                    client.heartbeat(load=0.25, capacity=1024 * 1024)
                    client.advertise(artifact_id)
                    self.assertEqual(client.poll(wait_seconds=0.01), [])

                stats = coordinator.network_stats()
                self.assertEqual(stats.available_caravans, 1)
                self.assertEqual(stats.protected_artifacts, 1)
                self.assertEqual(stats.verified_replicas, 1)

    def test_request_thread_population_is_bounded(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            coordinator = CoordinatorState(root / "coordinator.sqlite")
            identity = CarrierIdentity.create(root / "identity")
            _register(coordinator, identity)

            with CoordinatorLabService(coordinator, max_concurrent_requests=1) as service:
                client = CarrierTransportClient(
                    service.base_url,
                    identity,
                    allow_loopback_http=True,
                )
                client.connect()

                # connect() has received its response, but the server-side request
                # thread may still be completing its finally block. Require a
                # genuinely idle server before starting the saturation probe.
                idle_deadline = time.monotonic() + 2.0
                while service.active_requests != 0 and time.monotonic() < idle_deadline:
                    time.sleep(0.01)
                self.assertEqual(service.active_requests, 0)

                poll_errors: list[BaseException] = []

                def slow_poll() -> None:
                    try:
                        self.assertEqual(client.poll(wait_seconds=2.0), [])
                    except BaseException as exc:  # preserve assertion/thread failures
                        poll_errors.append(exc)

                worker = threading.Thread(target=slow_poll, daemon=True)
                worker.start()
                deadline = time.monotonic() + 2.0
                while service.active_requests != 1 and time.monotonic() < deadline:
                    time.sleep(0.01)
                self.assertEqual(service.active_requests, 1)

                with self.assertRaises(TransportError):
                    client.heartbeat(load=0, capacity=1)

                worker.join(timeout=3)
                self.assertFalse(worker.is_alive())
                self.assertEqual(poll_errors, [])
                idle_deadline = time.monotonic() + 2.0
                while service.active_requests != 0 and time.monotonic() < idle_deadline:
                    time.sleep(0.01)
                self.assertEqual(service.active_requests, 0)
                client.heartbeat(load=0, capacity=1)

    def test_quarantine_invalidates_existing_session_on_next_request(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            coordinator = CoordinatorState(root / "coordinator.sqlite")
            identity = CarrierIdentity.create(root / "identity")
            _register(coordinator, identity)

            with CoordinatorLabService(coordinator) as service:
                client = CarrierTransportClient(
                    service.base_url,
                    identity,
                    allow_loopback_http=True,
                )
                client.connect()
                coordinator.quarantine(identity.node_id)
                with self.assertRaises(TransportError):
                    client.heartbeat(load=0, capacity=1)

    def test_carrier_cannot_advertise_unapproved_content_over_transport(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            coordinator = CoordinatorState(root / "coordinator.sqlite")
            identity = CarrierIdentity.create(root / "identity")
            _register(coordinator, identity)
            unknown = _artifact(b"carrier invented bytes")

            with CoordinatorLabService(coordinator) as service:
                client = CarrierTransportClient(
                    service.base_url,
                    identity,
                    allow_loopback_http=True,
                )
                client.connect()
                client.heartbeat(load=0, capacity=100)
                with self.assertRaises(TransportError):
                    client.advertise(unknown)

    def test_plain_http_is_rejected_for_non_loopback_coordinator(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            identity = CarrierIdentity.create(Path(tmp) / "identity")
            with self.assertRaises(TransportError):
                CarrierTransportClient(
                    "http://example.invalid:8080",
                    identity,
                    allow_loopback_http=True,
                )

    def test_poll_duration_is_bounded_by_coordinator(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            coordinator = CoordinatorState(root / "coordinator.sqlite")
            identity = CarrierIdentity.create(root / "identity")
            _register(coordinator, identity)
            with CoordinatorLabService(coordinator) as service:
                client = CarrierTransportClient(
                    service.base_url,
                    identity,
                    allow_loopback_http=True,
                )
                client.connect()
                with self.assertRaises(TransportError):
                    client.poll(wait_seconds=999)


if __name__ == "__main__":
    unittest.main()
