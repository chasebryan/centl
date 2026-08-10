# CENTL-SCi base-model repository preservation

Status: recommended development/reconstruction preservation for the reference
local-model stack.

The active GGUF is sufficient to **run** the current CENTL-SCi reference path,
but it is not sufficient to reconstruct the model pipeline if the upstream model
hub disappears. Re-quantization, alternate quantization experiments, tokenizer
recovery, and model-format migration may require the original base-model
repository files.

FCF therefore supports a private immutable snapshot of the official base-model
repository in addition to the active GGUF.

## Current base lineage

The current qualified GGUF is based on:

```text
Qwen/Qwen3-4B-Instruct-2507
```

The project provenance catalog records the base-model license as Apache-2.0. The
exact third-party quantized GGUF origin remains a separate content-hash-bound
provenance question; see `MODEL-PROVENANCE.md`.

Preserving the official base repository does **not** claim that the current local
Q4_K_M file was produced by the official repository or by any particular
quantizer.

## Plan before downloading

A full base-model snapshot can be several gigabytes. Resolve the exact revision
and inspect the repository file plan first:

```sh
python3 scripts/model-repository-preserve.py \
  /srv/centl-mirror \
  --repository Qwen/Qwen3-4B-Instruct-2507 \
  --plan
```

`main` is resolved to the model hub's full immutable Git commit before the plan is
printed. When the hub publishes file sizes, the command also prints the known
total byte count. Planning does not mutate the FCF mirror.

## Preserve the full immutable revision

```sh
python3 scripts/model-repository-preserve.py \
  /srv/centl-mirror \
  --repository Qwen/Qwen3-4B-Instruct-2507
```

For a previously resolved exact revision:

```sh
python3 scripts/model-repository-preserve.py \
  /srv/centl-mirror \
  --repository Qwen/Qwen3-4B-Instruct-2507 \
  --revision <40-character-hub-commit>
```

An optional `HF_TOKEN` may be supplied for model-hub API metadata/rate limits.
The token is never written to the snapshot. For the public reference repository,
large file downloads are intentionally performed without forwarding that token
through model-hub/CDN redirects.

Large model files are streamed to temporary files in bounded chunks. They are not
buffered in memory as a single response. A downloaded file is moved into its
staged repository location only after the transfer completes.

The preservation command is an **online capture-time operation**. Once the model
repository revision is stored and the FCF mirror is copied, model-hub
availability is not required to read or use the preserved files.

## Verification of downloaded source bytes

The model hub exposes two relevant source identities:

- large LFS-backed files may have an LFS SHA-256 identity (`lfs.sha256`; an
  OID-style SHA-256 representation is also accepted);
- normal Git-managed files may have a Git blob SHA-1 identity.

FCF uses those source identities to check that the downloaded bytes correspond
to the selected hub revision when they are available.

Git blob SHA-1 is used only as the upstream Git object identity. It is **not**
CENTL's integrity primitive and is not treated as a modern collision-resistant
security boundary.

Every preserved file, regardless of upstream metadata, receives an FCF-computed
SHA-256 in the repository snapshot's deterministic receipt.

The verification layers are therefore:

```text
exact hub revision
      |
      +--> LFS SHA-256 when published
      |        or
      +--> Git blob object identity when published
      |
      v
preserved file bytes
      |
      v
FCF SHA-256 repository receipt
      |
      v
whole FCF mirror receipt
```

A mismatch aborts preservation. Do not rewrite an expected source identity merely
to make a changed download pass.

A mutating capture also verifies an existing finalized FCF mirror **before**
contacting the model hub. A corrupted preservation store is not silently repaired
by downloading fresh upstream bytes.

## Layout

The default Qwen snapshot is stored as:

```text
centl-mirror/
  model-repositories/
    Qwen_Qwen3-4B-Instruct-2507/
      ACTIVE
      <immutable-hub-commit>/
        files/
          ... complete model repository files ...
        SOURCE.json
        UPSTREAM-IDENTITIES.json
        REPOSITORY-SHA256SUMS
        REPOSITORY-SHA256SUMS.sha256
```

`SOURCE.json` records repository identity/source URL, requested and resolved
revisions, capture time, model-card license field when published, file count,
total preserved byte count, and whether API authentication was used. It never
stores the token itself.

`UPSTREAM-IDENTITIES.json` records each path, hub Git blob identity when
published, hub LFS SHA-256 when published, published size when available, actual
preserved byte count, and FCF-computed SHA-256.

The revision directory is immutable. Re-running preservation for an already
stored revision verifies the existing revision receipt rather than replacing the
files.

## Public/private boundary

Base-model repository snapshots are **not** release artifacts. They are stored in
the private FCF preservation mirror for development/reconstruction continuity.

`scripts/publication-export` allowlists only `releases/vVERSION/` and therefore
does not publish `model-repositories/`.

Any future public model distribution must have a separate explicit contract that
covers model licensing, exact provenance, attribution, file size/hosting, and the
intended relationship to the CENTL-SCi runtime.

## Relationship to the active GGUF

The two preservation objects solve different failure modes:

- `models/<sha256>/<file>.gguf` preserves the exact currently qualified runtime
  model bytes;
- `model-repositories/.../<revision>/` preserves the original base repository
  needed for future reconstruction/re-quantization work.

Neither substitutes for the other.

The active GGUF retains its own content-bound provenance record. The base
repository snapshot retains the official repository revision and its complete
files. A future reproducible quantization pipeline could explicitly connect these
objects once the exact quantizer/source process is known.

## Storage copies

After adding a base-model revision, the command regenerates the whole FCF mirror
receipt. Update the independent second mirror and strictly compare it:

```sh
sh scripts/mirror-receipt compare \
  /srv/centl-mirror \
  /mnt/fcf-backup/centl-mirror
```

Because model repositories are large and operationally important, a successful
copy command alone is not accepted as proof that the second copy is complete.
