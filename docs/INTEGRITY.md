# CENTL integrity and release authentication

Status: required development and release infrastructure.

CENTL uses a project-owned verification **process** built from established
cryptographic primitives and formats. CENTL does not define or modify a hash or
signature algorithm.

## Integrity primitive: SHA-256

The integrity primitive is SHA-256 as standardized by FIPS 180-4 and widely
implemented by operating systems, language runtimes, package managers, and
release tooling.

`scripts/integrity.py` uses Python's standard `hashlib.sha256`. Before performing
CENTL integrity work, it checks that implementation against published SHA-256
known-answer values, including the empty message and `abc` vectors.

The checksum manifest format is deliberately conventional:

```text
<64 lowercase hex SHA-256 characters><two spaces><relative path>
```

This is ordinary `SHA256SUMS` / `sha256sum -c` style data for normal file names.
CENTL adds conservative path validation, duplicate rejection, regular-file
requirements, and root containment around that format.

## Authentication primitive: signify

Release checksum manifests are authenticated with OpenBSD `signify`. `signify`
is an established utility for signing/verifying files and signed checksum lists.
FCF uses it as defined rather than introducing a custom signature scheme.

The two properties remain separate:

- **integrity:** the bytes match a trusted SHA-256 value;
- **authentication:** the trusted checksum manifest was signed by the selected
  FCF release key.

A checksum is not treated as proof of publisher identity by itself.

## Development source gate

`make quality` includes `integrity-source`.

That target:

1. runs the SHA-256 known-answer tests;
2. obtains the complete Git-tracked file list for the checkout;
3. hashes every tracked regular file;
4. writes `_build/integrity/SHA256SUMS` in deterministic path order;
5. immediately verifies every entry against the working tree;
6. writes `_build/integrity/SHA256SUMS.sha256`, the SHA-256 of the manifest
   itself.

Run it directly with:

```sh
make integrity-source
```

The resulting pair is an integrity receipt for the exact source tree seen by the
build process. CI associates that receipt with the Git commit being tested.

## Dependency and toolchain gate

External build inputs are verified independently from the source-tree receipt.

`supply-chain/sources.lock` records trusted SHA-256 values for downloaded
artifacts such as F*, GMP, MPFR, FLINT, and Julia. `scripts/supply-chain` refuses
to accept a mirrored artifact whose computed SHA-256 differs from the lock.

Git dependencies are pinned by full commit IDs and checked for the required
commit in the local bare mirror. `scripts/supply-chain-check.py` also rejects
silent disagreement between preservation pins and CENTL's canonical toolchain
metadata.

This means "it came from our mirror" is never treated as sufficient integrity
evidence. FCF-hosted bytes still have to match the expected cryptographic
identity.

## CENTL-SCi model integrity

A CENTL-SCi GGUF model is preserved by its computed SHA-256:

```text
models/<sha256>/<filename>.gguf
```

`models/ACTIVE.sha256` identifies the selected preserved model. Mirror audit
recomputes the model digest before accepting it.

The model filename, model-host URL, or upstream repository name is not used as a
substitute for content integrity.

## Preservation receipt

`make supply-chain-preserve MIRROR=... MODEL=...` requires a clean tracked
worktree and records:

```text
project/SOURCE-COMMIT
project/SOURCE-SHA256SUMS
project/SOURCE-SHA256SUMS.sha256
project/centl.bundle
```

alongside the mirrored dependency artifacts, Git repositories, opam material,
Julia/Nemo depot, and optional model bytes.

The mirror itself is checked with:

```sh
make supply-chain-audit MIRROR=/srv/centl-mirror
```

## No-network rebuild gate

The preserved mirror is tested as an actual recovery source with:

```sh
make offline-rebuild MIRROR=/srv/centl-mirror
```

`scripts/offline-rebuild` creates a Linux network namespace with no upstream
network route, audits the mirror, verifies the recorded source receipt, recovers
the exact source commit from the Git bundle, obtains F* from the SHA-256-pinned
mirror, uses the preserved Julia/Nemo depot, and runs CENTL's quality, verified
build, test, and differential gates.

A missing dependency is a preservation/build-capsule failure. The gate is not
allowed to solve the problem by downloading from upstream.

See `infra/offline-build/README.md`.

## Release integrity and authentication

Native packaging produces per-archive `.sha256` files for the existing installer
contract. Final multi-platform release promotion additionally creates:

```text
SHA256SUMS
SHA256SUMS.sig
```

using:

```sh
make release-sign \
  RELEASE_DIR=/path/to/release \
  FCF_SIGNIFY_SECRET_KEY=/protected/keys/fcf-centl-release-2026.sec \
  FCF_SIGNIFY_PUBLIC_KEY=/protected/keys/fcf-centl-release-2026.pub
```

`release-sign` creates and verifies the deterministic SHA-256 manifest, signs it,
verifies the new signature against the selected public key, and recomputes all
listed checksums before reporting success.

Independent verification is:

```sh
make release-verify \
  RELEASE_DIR=/path/to/release \
  FCF_SIGNIFY_PUBLIC_KEY=keys/fcf-centl-release-2026.pub
```

The verifier authenticates `SHA256SUMS` first and then recomputes every listed
SHA-256 value.

## Release key continuity

FCF production secret keys are passphrase-protected and are treated as
recoverable organizational assets. The policy deliberately avoids making one
person or one device the only path to future releases.

The normal model is:

- one protected working copy;
- at least two additional encrypted backups in independent locations/services;
- separately recoverable passphrase information;
- additional trusted custodians when maintainership grows;
- explicit key rotation with old public keys retained for historical releases.

If every copy of a secret key is lost, releases already signed by it remain
verifiable with the old public key. Future releases continue under a replacement
key after its public identity and transition are published.

See `keys/README.md` and `docs/RELEASE-SIGNING.md`.

## Verification chain

```text
Git-tracked source files
        |
        v
source SHA256SUMS + manifest digest + exact commit
        |
        v
pinned dependency SHA-256 / full Git commits
        |
        v
mirror audit + no-network rebuild/test
        |
        v
final release archives
        |
        v
SHA256SUMS
        |
        v
FCF signify signature over SHA256SUMS
        |
        v
signature verification + archive SHA-256 recomputation
        |
        v
installation/execution
```

## Operational policy

For a new external binary/source input:

1. identify an authoritative upstream release or immutable source commit;
2. obtain the expected SHA-256 from a trusted channel when upstream publishes
   one, or calculate and record it only after maintainers deliberately accept
   the exact bytes being preserved;
3. pin the version/commit and SHA-256 in CENTL's preservation metadata;
4. preserve the exact bytes under FCF control;
5. recompute SHA-256 whenever the bytes cross a trust/storage boundary;
6. reject any mismatch; never update a checksum merely to make a mismatch pass;
7. require normal verification/test gates before promoting a changed pin.

A checksum mismatch is an integrity failure until independently explained. A
signature failure is an authentication failure until independently explained.
Neither expected identity is rewritten during incident handling simply to make a
failed artifact pass.
