from __future__ import annotations

from dataclasses import replace
import json
import os
from pathlib import Path
import stat
import tempfile
import unittest

from caravan.identity import (
    CarrierIdentity,
    IdentityError,
    derive_node_id,
    verify_signature,
)
from caravan.policy import (
    PolicyError,
    create_policy_receipt,
    read_policy_receipt,
    verify_policy_receipt,
    write_policy_receipt,
)


class CarrierIdentityTests(unittest.TestCase):
    def test_identity_is_stable_owner_only_and_pseudonymous(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "identity"
            identity = CarrierIdentity.create(root)
            self.assertTrue(identity.node_id.startswith("caravan-node-v1:"))
            self.assertTrue(identity.public_identity.startswith("ed25519:"))
            self.assertEqual(identity.node_id, derive_node_id(identity.public_identity))

            mode = stat.S_IMODE(os.lstat(root / "identity.pem").st_mode)
            self.assertEqual(mode & 0o077, 0)
            loaded = CarrierIdentity.load(root)
            self.assertEqual(loaded.node_id, identity.node_id)
            self.assertEqual(loaded.public_identity, identity.public_identity)

            payload = b"CENTL CARAVAN carrier proof"
            signature = loaded.sign(payload)
            verify_signature(loaded.public_identity, payload, signature)
            with self.assertRaises(IdentityError):
                verify_signature(loaded.public_identity, payload + b"!", signature)

    def test_identity_key_and_directory_symlink_or_permissions_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            identity_root = root / "identity"
            CarrierIdentity.create(identity_root)

            os.chmod(identity_root / "identity.pem", 0o644)
            with self.assertRaises(IdentityError):
                CarrierIdentity.load(identity_root)

            os.chmod(identity_root / "identity.pem", 0o600)
            real = root / "real"
            real.mkdir(mode=0o700)
            link = root / "identity-link"
            link.symlink_to(real, target_is_directory=True)
            with self.assertRaises(IdentityError):
                CarrierIdentity.create(link)


class PolicyReceiptTests(unittest.TestCase):
    def test_policy_receipt_binds_exact_policy_and_identity(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            identity = CarrierIdentity.create(root / "identity")
            policy = root / "policy.md"
            policy.write_text("CARAVAN policy bytes\n", encoding="utf-8")

            receipt = create_policy_receipt(
                identity,
                policy,
                policy_version="FCF-CARAVAN-HOST-lab-v1",
                agent_version="0.0.1-lab",
                acceptance_mode="interactive",
                accepted_at=1_786_000_000,
            )
            verified = verify_policy_receipt(
                receipt,
                expected_policy_path=policy,
                expected_policy_version="FCF-CARAVAN-HOST-lab-v1",
            )
            self.assertEqual(verified.node_id, identity.node_id)
            self.assertNotIn("username", receipt.to_dict())
            self.assertNotIn("hostname", receipt.to_dict())

            receipt_path = root / "state" / "policy-receipt.json"
            write_policy_receipt(receipt_path, receipt)
            loaded = read_policy_receipt(receipt_path)
            self.assertEqual(loaded, receipt)
            parsed = json.loads(receipt_path.read_text(encoding="utf-8"))
            self.assertEqual(parsed["policy_sha256"], receipt.policy_sha256)

            policy.write_text("changed policy bytes\n", encoding="utf-8")
            with self.assertRaises(PolicyError):
                verify_policy_receipt(receipt, expected_policy_path=policy)

    def test_receipt_field_tampering_and_wrong_identity_fail(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            identity = CarrierIdentity.create(root / "identity-a")
            other = CarrierIdentity.create(root / "identity-b")
            policy = root / "policy.md"
            policy.write_text("policy\n", encoding="utf-8")
            receipt = create_policy_receipt(
                identity,
                policy,
                policy_version="v1",
                agent_version="lab",
                acceptance_mode="non-interactive",
                accepted_at=1_786_000_000,
            )

            with self.assertRaises(PolicyError):
                verify_policy_receipt(replace(receipt, policy_version="v2"))
            with self.assertRaises(PolicyError):
                verify_policy_receipt(
                    replace(
                        receipt,
                        node_id=other.node_id,
                        public_identity=other.public_identity,
                    )
                )


if __name__ == "__main__":
    unittest.main()
