"""Rootless outbound CARAVAN heartbeat agent."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import time

from .identity import CarrierIdentity
from .transport import CarrierTransportClient, TransportError


def _capacity_bytes(value: int) -> int:
    if value < 1 or value > 4096:
        raise ValueError("storage ceiling must be between 1 and 4096 GiB")
    return value * 1024 * 1024 * 1024


def run(args: argparse.Namespace) -> int:
    identity = CarrierIdentity.load(args.identity)
    capacity = _capacity_bytes(args.storage_gib)
    interval = max(30.0, min(float(args.interval), 1800.0))
    client = CarrierTransportClient(args.coordinator, identity)
    while True:
        try:
            client.connect()
            client.heartbeat(load=0.0, capacity=capacity)
            print("FCF CARAVAN camel heartbeat accepted", flush=True)
            while True:
                time.sleep(interval)
                client.heartbeat(load=0.0, capacity=capacity)
        except (TransportError, OSError, ValueError) as exc:
            client.disconnect()
            print(f"FCF CARAVAN camel is seeking the coordinator: {exc}", flush=True)
            time.sleep(min(interval, 60.0))


def main() -> int:
    parser = argparse.ArgumentParser(description="Keep a rootless FCF CARAVAN camel authenticated")
    parser.add_argument("--coordinator", required=True)
    parser.add_argument("--identity", type=Path, required=True)
    parser.add_argument("--storage-gib", type=int, required=True)
    parser.add_argument("--interval", type=float, default=60.0)
    args = parser.parse_args()
    return run(args)


if __name__ == "__main__":
    raise SystemExit(main())
