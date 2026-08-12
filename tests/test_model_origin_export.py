from __future__ import annotations

import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "model-origin-export.py"


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


class SemanticOriginExportTests(unittest.TestCase):
    def make_mirror(
        self,
        root: Path,
        *,
        model_bytes: bytes = b"CENTL semantic model test artifact\n",
        redistribution: str = "operator-reviewed-allowed",
        source_status: str = "verified",
    ) -> tuple[Path, str, str]:
        mirror = root / "mirror"
        digest = sha256(model_bytes)
        name = "centl-test-model-Q4_K_M.gguf"
        model_dir = mirror / "models" / digest
        model_dir.mkdir(parents=True)
        (mirror / "models" / "ACTIVE.sha256").write_text(digest + "\n", encoding="utf-8")
        (model_dir / name).write_bytes(model_bytes)
        (model_dir / "MANIFEST").write_text(
            f"sha256={digest}\nfile={name}\nbytes={len(model_bytes)}\n",
            encoding="utf-8",
        )
        source_sha = digest if source_status == "verified" else "-"
        provenance = "\n".join(
            [
                "schema=1",
                f"content_sha256={digest}",
                f"file_name={name}",
                f"bytes={len(model_bytes)}",
                "base_model_id=Qwen/Qwen3-4B-Instruct-2507",
                "base_model_source=https://example.invalid/base",
                "base_model_license=Apache-2.0",
                "quantization=Q4_K_M",
                f"quantized_source_status={source_status}",
                "quantized_source_repository=https://example.invalid/quantized",
                f"quantized_source_file={name}",
                f"quantized_source_sha256={source_sha}",
                f"redistribution_status={redistribution}",
                "preservation_source_commit=0123456789abcdef0123456789abcdef01234567",
                "record_source=operator:test",
                "note=test record",
                "",
            ]
        )
        provenance_path = model_dir / "PROVENANCE"
        provenance_path.write_text(provenance, encoding="utf-8")
        (model_dir / "PROVENANCE.sha256").write_text(
            f"{sha256(provenance.encode())}  PROVENANCE\n", encoding="utf-8"
        )
        return mirror, digest, name

    def run_export(self, mirror: Path, output: Path) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(SCRIPT), str(mirror), str(output)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

    def test_exports_exact_model_and_caravan_catalog(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            mirror, digest, name = self.make_mirror(root)
            output = root / "origin"
            result = self.run_export(mirror, output)
            self.assertEqual(result.returncode, 0, result.stderr)

            active = json.loads((output / "models" / "ACTIVE.json").read_text())
            self.assertEqual(active["artifact_id"], f"sha256:{digest}")
            self.assertEqual(active["content_sha256"], digest)
            exported = output / "models" / "sha256" / digest / name
            self.assertEqual(sha256(exported.read_bytes()), digest)

            catalog = json.loads(
                (output / "caravan" / "catalog-v1.json").read_text()
            )
            self.assertEqual(catalog["schema"], "centl-caravan-catalog-v1")
            self.assertEqual(catalog["artifacts"][0]["artifact_id"], f"sha256:{digest}")
            self.assertEqual(catalog["artifacts"][0]["distribution"], "public-approved")
            self.assertEqual(
                sum(chunk["length"] for chunk in catalog["artifacts"][0]["chunks"]),
                len(exported.read_bytes()),
            )
            self.assertTrue((output / "ORIGIN-SHA256SUMS").is_file())

    def test_refuses_model_without_redistribution_approval(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            mirror, _digest, _name = self.make_mirror(
                root, redistribution="not-approved"
            )
            result = self.run_export(mirror, root / "origin")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("operator-reviewed-allowed", result.stderr)

    def test_refuses_unverified_quantized_origin(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            mirror, _digest, _name = self.make_mirror(
                root, source_status="unverified"
            )
            result = self.run_export(mirror, root / "origin")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("verified exact quantized source", result.stderr)

    def test_refuses_tampered_model(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            mirror, digest, name = self.make_mirror(root)
            (mirror / "models" / digest / name).write_bytes(b"tampered\n")
            result = self.run_export(mirror, root / "origin")
            self.assertNotEqual(result.returncode, 0)
            self.assertTrue(
                "byte count" in result.stderr or "checksum mismatch" in result.stderr
            )

    def test_repeated_export_is_deterministic(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            mirror, _digest, _name = self.make_mirror(root)
            output = root / "origin"
            first = self.run_export(mirror, output)
            self.assertEqual(first.returncode, 0, first.stderr)
            first_catalog = (output / "caravan" / "catalog-v1.json").read_bytes()
            first_active = (output / "models" / "ACTIVE.json").read_bytes()
            first_receipt = (output / "ORIGIN-SHA256SUMS").read_bytes()

            second = self.run_export(mirror, output)
            self.assertEqual(second.returncode, 0, second.stderr)
            self.assertEqual(
                first_catalog, (output / "caravan" / "catalog-v1.json").read_bytes()
            )
            self.assertEqual(
                first_active, (output / "models" / "ACTIVE.json").read_bytes()
            )
            self.assertEqual(
                first_receipt, (output / "ORIGIN-SHA256SUMS").read_bytes()
            )


if __name__ == "__main__":
    unittest.main()
