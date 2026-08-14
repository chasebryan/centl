from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol


class CarrierError(RuntimeError):
    """A Telepathy carrier could not satisfy its narrow contract."""


@dataclass(frozen=True)
class CarrierStatus:
    carrier: str
    available: bool
    published: bool
    endpoint: str | None = None
    pid: int | None = None
    detail: str | None = None


class Carrier(Protocol):
    """Minimal replaceable road beneath FCF Telepathy."""

    def probe(self) -> CarrierStatus:
        ...

    def publish(self) -> CarrierStatus:
        ...

    def status(self) -> CarrierStatus:
        ...

    def withdraw(self) -> CarrierStatus:
        ...
