from __future__ import annotations

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
RENDER = ROOT / "scripts" / "caravan-render-bazaar"


class CaravanRenderBazaarStrictTests(unittest.TestCase):
    def test_renderer_rejects_any_unresolved_fcf_placeholder(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            template = root / "mirrors.html"
            census = root / "census.json"
            output = root / "rendered.html"
            template.write_text(
                "\n".join(
                    (
                        "__FCF_ACTIVE_CAMELS__",
                        "__FCF_HUNGRY_CAMELS__",
                        "__FCF_LOST_CAMELS__",
                        "__FCF_CARGO_LOADS__",
                        "__FCF_CENSUS_STATUS__",
                        "__FCF_UNEXPECTED_PLACEHOLDER__",
                    )
                ),
                encoding="utf-8",
            )
            census.write_text(
                json.dumps(
                    {
                        "schema": "fcf-caravan-lead-census-v1",
                        "status": "live",
                        "generated_at": "2026-08-18T00:00:00+00:00",
                        "probe": "healthy",
                        "active_camels": 1,
                        "hungry_camels": 0,
                        "lost_camels": 0,
                        "cargo_loads": 0,
                    }
                ),
                encoding="utf-8",
            )

            result = subprocess.run(
                [
                    sys.executable,
                    str(RENDER),
                    "--template",
                    str(template),
                    "--census",
                    str(census),
                    "--output",
                    str(output),
                ],
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )

            self.assertEqual(result.returncode, 2)
            self.assertIn("unresolved FCF placeholder", result.stderr)
            self.assertFalse(output.exists())


if __name__ == "__main__":
    unittest.main()
