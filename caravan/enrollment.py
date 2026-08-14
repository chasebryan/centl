"""Policy-gated carrier enrollment for the CARAVAN laboratory."""

from __future__ import annotations

import os

from .coordinator import CoordinatorState
from .policy import PolicyAcceptanceReceipt, verify_policy_receipt


def register_accepted_carrier(
    coordinator: CoordinatorState,
    receipt: PolicyAcceptanceReceipt,
    *,
    expected_policy_path: os.PathLike[str] | str,
    expected_policy_version: str,
    carrier_class: str = "volunteer",
    now: float | None = None,
) -> int:
    """Register a carrier only after its signed policy receipt verifies.

    This is the laboratory enrollment boundary. The coordinator receives a
    pseudonymous node/public identity plus versioned acceptance metadata; it does
    not need an operator username, hostname, or legal name.
    """

    verified = verify_policy_receipt(
        receipt,
        expected_policy_path=expected_policy_path,
        expected_policy_version=expected_policy_version,
    )
    return coordinator.register_carrier(
        verified.node_id,
        public_identity=verified.public_identity,
        policy_version=verified.policy_version,
        agent_version=verified.agent_version,
        carrier_class=carrier_class,
        now=now,
    )
