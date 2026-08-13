"""Authenticated enrollment and withdrawal core for CARAVAN carriers.

This module is transport-agnostic on purpose.  It gives the future HTTPS
coordinator a small, testable state-transition boundary while keeping public
network enrollment disabled until the surrounding release and deployment gates
are satisfied.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any, Iterable

from .coordinator import CoordinatorError, CoordinatorState
from .enrollment import register_accepted_carrier
from .policy import PolicyAcceptanceReceipt, PolicyError
from .session import SessionAuthority


PUBLIC_ENROLLMENT_RESULT_SCHEMA = "fcf-caravan-enrollment-result-v1"


class EnrollmentProtocolError(RuntimeError):
    """Raised when an enrollment or withdrawal transition fails closed."""


class EnrollmentAuthority:
    """Apply authenticated carrier lifecycle changes with release allowlisting."""

    def __init__(
        self,
        coordinator: CoordinatorState,
        sessions: SessionAuthority,
        *,
        policy_path: str | Path,
        policy_version: str,
        allowed_agent_versions: Iterable[str],
    ) -> None:
        versions = frozenset(allowed_agent_versions)
        if not versions or any(not value for value in versions):
            raise ValueError("at least one non-empty carrier release version is required")
        if not policy_version:
            raise ValueError("policy_version is required")
        self.coordinator = coordinator
        self.sessions = sessions
        self.policy_path = Path(policy_path)
        self.policy_version = policy_version
        self.allowed_agent_versions = versions

    def enroll(self, value: object, *, now: float | None = None) -> dict[str, Any]:
        if not isinstance(value, dict):
            raise EnrollmentProtocolError("enrollment receipt must be a JSON object")
        try:
            receipt = PolicyAcceptanceReceipt.from_dict(value)
            if receipt.agent_version not in self.allowed_agent_versions:
                raise EnrollmentProtocolError("carrier release is not admitted for enrollment")
            register_accepted_carrier(
                self.coordinator,
                receipt,
                expected_policy_path=self.policy_path,
                expected_policy_version=self.policy_version,
                now=now,
            )
        except (PolicyError, CoordinatorError, ValueError, OSError) as exc:
            if isinstance(exc, EnrollmentProtocolError):
                raise
            raise EnrollmentProtocolError("carrier enrollment authentication failed") from exc
        return {
            "schema": PUBLIC_ENROLLMENT_RESULT_SCHEMA,
            "node_id": receipt.node_id,
            "state": "active",
            "public_listing": False,
        }

    def withdraw(self, node_id: str) -> dict[str, Any]:
        if not node_id:
            raise EnrollmentProtocolError("node_id is required for withdrawal")
        try:
            self.coordinator.withdraw(node_id)
            self.sessions.revoke_node(node_id)
        except CoordinatorError as exc:
            raise EnrollmentProtocolError("carrier withdrawal failed") from exc
        return {
            "schema": PUBLIC_ENROLLMENT_RESULT_SCHEMA,
            "node_id": node_id,
            "state": "withdrawn",
            "public_listing": False,
        }
