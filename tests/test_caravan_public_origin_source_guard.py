from __future__ import annotations

import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import tarfile
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
GUARD = ROOT / "scripts" / "caravan-public-origin-source-guard.py"
BRANCHES = ("main", "oasis", "mirage")


def load_guard():
    spec = importlib.util.spec_from_file_location("caravan_source_guard", GUARD)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def write_archive(path: Path, branch: str) -> str:
    with tarfile.open(path, mode="w:gz") as archive:
        for name, data in (
            (f"centl-{branch}/README.md", b"CENTL test source\n"),
            (f"centl-{branch}/LICENSE", b"test license\n"),
        ):
            info = tarfile.TarInfo(name)
            info.size = len(data)
            info.mode = 0o644
            archive.addfile(info, io.BytesIO(data))
    return hashlib.sha256(path.read_bytes()).hexdigest()


class CaravanSourceGuardV2Tests(unittest.TestCase):
    def setUp(self) -> None:
        self.module = load_guard()

    def make_candidate(self, root: Path) -> tuple[Path, dict[str, object]]:
        build_id = "20260812T120000Z-123"
        candidates = root / "candidates"
        source = candidates / build_id / "source"
        source.mkdir(parents=True)
        (candidates / "READY").write_text(build_id + "\n", encoding="ascii")

        branches: dict[str, object] = {}
        for index, branch in enumerate(BRANCHES):
            archive_name = f"centl-{branch}.tar.gz"
            digest = write_archive(source / archive_name, branch)
            branches[branch] = {
                "commit": f"{index + 1}" * 40,
                "archive": archive_name,
                "sha256": digest,
            }
        source_index: dict[str, object] = {
            "schema": "centl-fcf-source-index-v2",
            "repository": "chasebryan/centl",
            "mirror_receipt_sha256": "a" * 64,
            "authorization_sha256": "b" * 64,
            "branches": branches,
        }
        (source / "INDEX.json").write_text(
            json.dumps(source_index, sort_keys=True) + "\n", encoding="utf-8"
        )
        return candidates, source_index

    def run_guard(self, candidates: Path) -> int:
        with mock.patch.object(self.module.os, "geteuid", return_value=0), mock.patch.dict(
            os.environ, {"FCF_CARAVAN_CANDIDATE_ROOT": str(candidates)}, clear=False
        ):
            return self.module.main()

    def test_v2_candidate_is_accepted(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            candidates, _ = self.make_candidate(Path(td))
            self.assertEqual(self.run_guard(candidates), 0)

    def test_v1_index_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            candidates, source_index = self.make_candidate(Path(td))
            source_index["schema"] = "centl-fcf-source-index-v1"
            index_path = next(candidates.glob("*/source/INDEX.json"))
            index_path.write_text(json.dumps(source_index) + "\n", encoding="utf-8")
            with self.assertRaisesRegex(SystemExit, "unsupported source index schema"):
                self.run_guard(candidates)

    def test_v2_archive_digest_mismatch_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            candidates, source_index = self.make_candidate(Path(td))
            branches = source_index["branches"]
            assert isinstance(branches, dict)
            main = branches["main"]
            assert isinstance(main, dict)
            main["sha256"] = "0" * 64
            index_path = next(candidates.glob("*/source/INDEX.json"))
            index_path.write_text(json.dumps(source_index) + "\n", encoding="utf-8")
            with self.assertRaisesRegex(SystemExit, "source archive digest mismatch: main"):
                self.run_guard(candidates)

    def test_v2_authority_binding_is_required(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            candidates, source_index = self.make_candidate(Path(td))
            source_index["authorization_sha256"] = "not-a-digest"
            index_path = next(candidates.glob("*/source/INDEX.json"))
            index_path.write_text(json.dumps(source_index) + "\n", encoding="utf-8")
            with self.assertRaisesRegex(SystemExit, "authorization_sha256 is invalid"):
                self.run_guard(candidates)


if __name__ == "__main__":
    unittest.main()
