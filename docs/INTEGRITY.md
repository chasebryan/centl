# CENTL SHA-256 integrity process

Status: required development and release infrastructure.

CENTL uses a project-owned verification **process** built from the standard
SHA-256 cryptographic hash function. CENTL does not define or modify the hash
algorithm.

## Standard

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

This is the ordinary `SHA256SUMS` / GNU `sha256sum -c` representation for normal
file names. We are not creating a CENTL-specific digest algorithm.

## What a SHA-256 check proves

If a file's computed SHA-256 equals a trusted expected SHA-256, the verifier has
strong evidence that the checked bytes are the same bytes represented by that
expected digest.

SHA-256 **does not by itself authenticate the publisher**. If an attacker can
replace both a file and its expected checksum, an unsigned checksum alone does
not establish origin.

CENTL therefore treats these as separate properties:

- **integrity:** SHA-256 digest comparison;
- **provenance/authentication:** Git commit identity today, and a standard
  signature mechanism for published FCF checksum manifests as the hosting layer
  is established.

A future signature layer must sign the standard checksum/receipt material. It
must not replace SHA-256 with a home-grown cryptographic construction.

## Development gate

`make quality` now includes `integrity-source`.

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
build process. CI associates that receipt with the commit SHA that was checked
out.

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

## Release integrity

CENTL native release packaging already emits an adjacent SHA-256 checksum for
each release archive:

```text
centl-linux-x86_64.tar.gz
centl-linux-x86_64.tar.gz.sha256
```

The installer refuses to extract or execute a downloaded/local archive until the
archive SHA-256 matches the expected value. Offline installs use the same check.

Therefore the verification chain is intentionally layered:

```text
source SHA256SUMS receipt
        |
        v
pinned dependency SHA-256 / Git commits
        |
        v
verified + tested build
        |
        v
release archive
        |
        v
archive SHA-256
        |
        v
installer recomputes SHA-256 before execution
```

## Preservation gate

`make supply-chain-preserve MIRROR=... MODEL=...` now starts by generating the
source integrity receipt before synchronizing the external preservation mirror.
The preservation run therefore records the source state and the preserved
external inputs as one development operation.

The mirror itself is then checked with:

```sh
make supply-chain-audit MIRROR=/srv/centl-mirror
```

## Operational policy

The required policy for new external binary/source inputs is:

1. identify an authoritative upstream release or immutable source commit;
2. obtain the expected SHA-256 from a trusted channel when upstream publishes
   one, or calculate and record it only after maintainers have deliberately
   accepted the exact bytes being preserved;
3. pin the version/commit and SHA-256 in CENTL's preservation metadata;
4. preserve the exact bytes under FCF control;
5. recompute SHA-256 whenever the bytes cross a trust/storage boundary;
6. reject any mismatch; never "update the checksum" merely to make a mismatch
   pass;
7. require the normal verification/test gates before promoting a changed pin.

A checksum mismatch is treated as an integrity failure until independently
explained. The expected digest is not rewritten during incident handling.

## Next authentication layer

The next step after FCF-controlled hosting exists is to publish and preserve a
standard cryptographic signature over release `SHA256SUMS`/integrity receipts so
a user can verify both:

1. the bytes match the SHA-256 digest; and
2. the expected digest was authenticated by an FCF release key/identity.

That should use an established signature system and documented key-rotation and
offline-key procedures. It is intentionally separate from this SHA-256 integrity
layer.
