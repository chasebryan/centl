# FCF CARAVAN join-signing key ceremony

Status: **operator procedure prepared; no production key is stored in this repository**.

The CARAVAN join signing identity is the release-authority boundary for the public volunteer installer. It is separate from carrier identities, GitHub credentials, Tor identities, TLS keys, and ordinary service credentials.

Public enrollment remains disabled until issue #167 is complete. Creating this key does not open the CARAVAN.

## Where to run the ceremony

Use a trusted FCF administrator system with OpenBSD `signify` available. Prefer a machine that is not serving the public CARAVAN origin and is not an ordinary volunteer carrier. The secret key should remain outside:

- the CENTL Git checkout;
- GitHub Actions or other hosted CI;
- web roots;
- normal cloud-synchronization folders;
- volunteer carrier state; and
- public CARAVAN cargo.

The repository provides a guardrailed operator command:

```sh
scripts/caravan-join-key-ceremony \
  --output-dir /protected/fcf-keys \
  --key-name fcf-caravan-join-2026
```

The command deliberately invokes `signify -G` **without** `-n`, so the production secret key is passphrase-protected. It then signs and verifies a local challenge before reporting success and prints the SHA-256 of the public key.

## Record the authority

After generation, record all three values in an offline FCF operations record:

```text
key name
public-key SHA-256
creation date and responsible operator
```

Do not copy the secret-key bytes into an issue, pull request, chat, screenshot, CI secret, or repository file.

## Cross-publication gate

Only the **public** key should be broadly distributed. Before `join-caravan 1.0.0` can be called an FCF release, the same public-key bytes and SHA-256 must be available through at least two independently reachable FCF-controlled trust channels.

Recommended channels are:

1. the versioned CARAVAN release area on `freecomputation.org`; and
2. the CENTL repository/release documentation on GitHub.

Additional FCF-controlled archival or Semantic Origin publication is encouraged. A human-friendly pointer may move; the trusted key bytes and fingerprint must not silently change under the same identity.

## Release ceremony

Once the public key is cross-published and all other #167 production gates are green, use the secret/public pair only for an explicit immutable release:

```sh
export FCF_CARAVAN_JOIN_SECRET_KEY=/protected/fcf-keys/fcf-caravan-join-2026.sec
export FCF_CARAVAN_JOIN_PUBLIC_KEY=/protected/fcf-keys/fcf-caravan-join-2026.pub

scripts/caravan-join-release \
  --version 1.0.0 \
  --output /srv/fcf-release-candidates/caravan
```

The release command requires a clean Git checkout, refuses a signing key inside the repository, creates a deterministic versioned archive, signs both the inner exact-membership manifest and outer release checksums, and does not overwrite an existing version.

## Independent verification

Before publication, verify the candidate from a separate location using a separately obtained copy of the public key:

```sh
scripts/caravan-join-verify \
  /srv/fcf-release-candidates/caravan/fcf-caravan-join-1.0.0 \
  /trusted-independent-copy/fcf-caravan-join-2026.pub
```

A successful local build is not enough. The separately trusted key must match the bundled public key byte-for-byte, and both outer and inner signatures/checksums must pass.

## Recovery and rotation

Keep an offline recovery copy using an FCF-approved method. Losing the only secret key prevents further releases under that identity. Suspected compromise requires a new signing identity and an explicit public transition notice; never silently replace the public key while retaining the same key name or release identity.

Carrier identity rotation is separate from release-signing-key rotation. A volunteer carrier key can never sign or authorize FCF release bytes.
