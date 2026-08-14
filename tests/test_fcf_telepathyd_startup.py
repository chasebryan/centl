from __future__ import annotations

import argparse
from pathlib import Path
import runpy
from types import SimpleNamespace
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "fcf-telepathyd"


class ImmediateEvent:
    def __init__(self, calls: list[str]) -> None:
        self.calls = calls

    def set(self) -> None:
        self.calls.append("stop-set")

    def wait(self) -> None:
        self.calls.append("stop-wait")


class ServeStartupRegressionTests(unittest.TestCase):
    def test_gateway_is_serving_before_tor_publish_probe(self) -> None:
        namespace = runpy.run_path(
            str(SCRIPT),
            run_name="fcf_telepathyd_startup_regression",
        )
        serve_globals = namespace["_serve"].__globals__
        calls: list[str] = []

        class FakeGateway:
            def __init__(self, _config: object) -> None:
                self.address = ("127.0.0.1", 8790)

            def start_background(self) -> "FakeGateway":
                calls.append("gateway-start-background")
                return self

            def close(self) -> None:
                calls.append("gateway-close")

        class FakeCarrier:
            def __init__(self, _config: object) -> None:
                calls.append("carrier-create")

            def publish(self) -> SimpleNamespace:
                calls.append("carrier-publish")
                return SimpleNamespace(endpoint="a" * 56 + ".onion")

            def withdraw(self) -> None:
                calls.append("carrier-withdraw")

        fake_event = ImmediateEvent(calls)

        with tempfile.TemporaryDirectory() as td:
            args = argparse.Namespace(
                publish=True,
                carrier="tor-onion",
                listen_host="127.0.0.1",
                listen_port=8790,
                caravan_live_root=Path("/srv/fcf-caravan-live/current"),
                virtual_port=80,
                tor_binary="tor",
                state_dir=Path(td),
            )
            with (
                mock.patch.dict(
                    serve_globals,
                    {
                        "TelepathyGateway": FakeGateway,
                        "TorOnionCarrier": FakeCarrier,
                    },
                ),
                mock.patch.object(
                    serve_globals["threading"],
                    "Event",
                    return_value=fake_event,
                ),
                mock.patch.object(serve_globals["signal"], "signal") as signal_mock,
            ):
                result = namespace["_serve"](args)

        self.assertEqual(result, 0)
        signal_mock.assert_called_once()
        self.assertEqual(
            calls,
            [
                "gateway-start-background",
                "carrier-create",
                "carrier-publish",
                "stop-wait",
                "carrier-withdraw",
                "gateway-close",
            ],
        )


if __name__ == "__main__":
    unittest.main()
