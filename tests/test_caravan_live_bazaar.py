from __future__ import annotations

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import importlib.machinery
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import threading
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "caravan-live-bazaar"


def _load_script_module():
    loader = importlib.machinery.SourceFileLoader("caravan_live_bazaar", str(SCRIPT))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    if spec is None:
        raise RuntimeError("could not load caravan-live-bazaar")
    module = importlib.util.module_from_spec(spec)
    sys.modules[loader.name] = module
    loader.exec_module(module)
    return module


class _CensusHandler(BaseHTTPRequestHandler):
    document: dict[str, object] = {}

    def log_message(self, format: str, *args: object) -> None:
        return

    def do_GET(self) -> None:  # noqa: N802
        if self.path != "/census-v1.json":
            self.send_response(404)
            self.end_headers()
            return
        payload = (json.dumps(self.document, sort_keys=True) + "\n").encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)


class CaravanLiveBazaarTests(unittest.TestCase):
    def test_refreshes_static_page_from_coordinator_truth(self) -> None:
        module = _load_script_module()
        _CensusHandler.document = {
            "schema": "fcf-caravan-census-v1",
            "status": "live",
            "generated_at": "2026-08-19T03:00:00Z",
            "active_camels": 7,
            "hungry_camels": 2,
            "lost_camels": 3,
            "cargo_loads": 11,
            "active_window_seconds": 1800,
            "lost_after_seconds": 259200,
            "individual_nodes_public": False,
            "ip_addresses_public": False,
        }
        server = ThreadingHTTPServer(("127.0.0.1", 0), _CensusHandler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            with tempfile.TemporaryDirectory() as temp_dir:
                site_build = Path(temp_dir) / "site"
                site_build.mkdir()
                host, port = server.server_address[:2]
                document = module.refresh_once(
                    repo_root=ROOT,
                    site_build=site_build,
                    coordinator=f"http://{host}:{port}",
                )

                self.assertEqual(document["active_camels"], 7)
                published = json.loads(
                    (
                        site_build
                        / "pub"
                        / "centl"
                        / "caravan"
                        / "census-v1.json"
                    ).read_text(encoding="utf-8")
                )
                self.assertEqual(published["active_camels"], 7)
                html = (site_build / "mirrors.html").read_text(encoding="utf-8")
                self.assertNotIn("__FCF_ACTIVE_CAMELS__", html)
                self.assertNotIn("__FCF_HUNGRY_CAMELS__", html)
                self.assertNotIn("__FCF_LOST_CAMELS__", html)
                self.assertNotIn("__FCF_CARGO_LOADS__", html)
                self.assertIn("authenticated coordinator census", html)
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=5)


if __name__ == "__main__":
    unittest.main()
