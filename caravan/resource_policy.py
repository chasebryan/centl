"""Fail-closed resource policy for normal CARAVAN volunteer carriers.

The public volunteer role is deliberately bounded.  This module contains the
resource contract independently from any service manager or network transport so
all Linux environments can enforce the same limits.
"""

from __future__ import annotations

from dataclasses import dataclass
import math
import time
from typing import Any


class ResourcePolicyError(RuntimeError):
    """Raised when carrier resource policy or accounting violates its bounds."""


MIB = 1024 * 1024
GIB = 1024 * MIB


@dataclass(frozen=True, slots=True)
class CarrierResourcePolicy:
    storage_limit_bytes: int = 10 * GIB
    min_free_bytes: int = 512 * MIB
    outbound_bytes_per_second: int = 4 * MIB
    max_concurrent_transfers: int = 4
    max_queue_depth: int = 32
    request_deadline_seconds: float = 120.0
    monthly_transfer_limit_bytes: int = 250 * GIB

    def __post_init__(self) -> None:
        integer_fields = {
            "storage_limit_bytes": self.storage_limit_bytes,
            "min_free_bytes": self.min_free_bytes,
            "outbound_bytes_per_second": self.outbound_bytes_per_second,
            "max_concurrent_transfers": self.max_concurrent_transfers,
            "max_queue_depth": self.max_queue_depth,
            "monthly_transfer_limit_bytes": self.monthly_transfer_limit_bytes,
        }
        for name, value in integer_fields.items():
            if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
                raise ResourcePolicyError(f"{name} must be a positive integer")
        if self.storage_limit_bytes > 4096 * GIB:
            raise ResourcePolicyError("storage limit exceeds the CARAVAN safety maximum")
        if self.min_free_bytes >= self.storage_limit_bytes:
            raise ResourcePolicyError("minimum free-space reserve must be below storage limit")
        if self.outbound_bytes_per_second > 1024 * MIB:
            raise ResourcePolicyError("outbound rate exceeds the CARAVAN safety maximum")
        if self.max_concurrent_transfers > 64:
            raise ResourcePolicyError("concurrent transfer limit exceeds the CARAVAN safety maximum")
        if self.max_queue_depth > 4096:
            raise ResourcePolicyError("queue depth exceeds the CARAVAN safety maximum")
        if (
            isinstance(self.request_deadline_seconds, bool)
            or not isinstance(self.request_deadline_seconds, (int, float))
            or not math.isfinite(float(self.request_deadline_seconds))
            or not 1 <= float(self.request_deadline_seconds) <= 3600
        ):
            raise ResourcePolicyError("request deadline must be between 1 and 3600 seconds")
        if self.monthly_transfer_limit_bytes > 100 * 1024 * GIB:
            raise ResourcePolicyError("monthly transfer limit exceeds the CARAVAN safety maximum")

    def to_dict(self) -> dict[str, int | float]:
        return {
            "storage_limit_bytes": self.storage_limit_bytes,
            "min_free_bytes": self.min_free_bytes,
            "outbound_bytes_per_second": self.outbound_bytes_per_second,
            "max_concurrent_transfers": self.max_concurrent_transfers,
            "max_queue_depth": self.max_queue_depth,
            "request_deadline_seconds": float(self.request_deadline_seconds),
            "monthly_transfer_limit_bytes": self.monthly_transfer_limit_bytes,
        }

    @classmethod
    def from_dict(cls, value: object) -> "CarrierResourcePolicy":
        if not isinstance(value, dict):
            raise ResourcePolicyError("resource policy must be a JSON object")
        expected = {
            "storage_limit_bytes",
            "min_free_bytes",
            "outbound_bytes_per_second",
            "max_concurrent_transfers",
            "max_queue_depth",
            "request_deadline_seconds",
            "monthly_transfer_limit_bytes",
        }
        if set(value) != expected:
            raise ResourcePolicyError("resource policy fields do not match the contract")
        return cls(**{name: value[name] for name in expected})  # type: ignore[arg-type]


@dataclass(slots=True)
class MonthlyTransferBudget:
    """Simple fail-closed transfer accounting with fixed 30-day windows.

    Persistence is intentionally the caller's responsibility.  The accounting
    object accepts a restored window start and byte count so a process restart
    does not have to reset the volunteer's transfer ceiling.
    """

    limit_bytes: int
    window_started_at: float
    used_bytes: int = 0
    window_seconds: float = 30 * 24 * 60 * 60

    def __post_init__(self) -> None:
        if isinstance(self.limit_bytes, bool) or not isinstance(self.limit_bytes, int) or self.limit_bytes <= 0:
            raise ResourcePolicyError("monthly transfer budget must be positive")
        if isinstance(self.used_bytes, bool) or not isinstance(self.used_bytes, int) or self.used_bytes < 0:
            raise ResourcePolicyError("used transfer bytes must be a non-negative integer")
        if self.used_bytes > self.limit_bytes:
            raise ResourcePolicyError("restored transfer usage exceeds configured budget")
        if not math.isfinite(float(self.window_started_at)):
            raise ResourcePolicyError("transfer window start must be finite")
        if not math.isfinite(float(self.window_seconds)) or self.window_seconds <= 0:
            raise ResourcePolicyError("transfer window duration must be positive")

    def _roll_window(self, now: float) -> None:
        if now < self.window_started_at:
            raise ResourcePolicyError("transfer accounting clock moved before the active window")
        if now - self.window_started_at >= self.window_seconds:
            self.window_started_at = now
            self.used_bytes = 0

    def reserve(self, byte_count: int, *, now: float | None = None) -> None:
        if isinstance(byte_count, bool) or not isinstance(byte_count, int) or byte_count < 0:
            raise ResourcePolicyError("transfer reservation must be a non-negative integer")
        timestamp = time.time() if now is None else float(now)
        if not math.isfinite(timestamp):
            raise ResourcePolicyError("transfer accounting timestamp must be finite")
        self._roll_window(timestamp)
        if byte_count > self.limit_bytes - self.used_bytes:
            raise ResourcePolicyError("monthly transfer budget exhausted")
        self.used_bytes += byte_count

    def remaining(self, *, now: float | None = None) -> int:
        timestamp = time.time() if now is None else float(now)
        if not math.isfinite(timestamp):
            raise ResourcePolicyError("transfer accounting timestamp must be finite")
        self._roll_window(timestamp)
        return self.limit_bytes - self.used_bytes

    def to_dict(self) -> dict[str, int | float]:
        return {
            "limit_bytes": self.limit_bytes,
            "window_started_at": self.window_started_at,
            "used_bytes": self.used_bytes,
            "window_seconds": self.window_seconds,
        }
