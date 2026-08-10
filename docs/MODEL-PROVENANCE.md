# CENTL-SCi model provenance

Status: required preservation metadata for an active CENTL-SCi model.

A model filename is not provenance. Different quantizers and repositories may
publish files with nearly identical GGUF names while the underlying bytes differ.
CENTL therefore keeps model **content identity**, **base-model lineage**, **exact
quantized-file origin**, and **redistribution approval** as separate facts.

## Content identity remains authoritative

The active GGUF is preserved under its computed SHA-256:

```text
models/<sha256>/<filename>.gguf
```

`models/ACTIVE.sha256` selects the active preserved model. The model's content
SHA-256 is never inferred from its filename or source URL.

The provenance layer binds metadata to that exact digest rather than replacing
content-addressed preservation.

## Current qualified filename

CENTL's current reference/qualification filename is:

```text
Qwen_Qwen3-4B-Instruct-2507-Q4_K_M.gguf
```

The repository catalog records the base-model lineage that can be stated without
inventing the GGUF's quantizer origin:

```text
base_model_id=Qwen/Qwen3-4B-Instruct-2507
base_model_source=https://huggingface.co/Qwen/Qwen3-4B-Instruct-2507
base_model_license=Apache-2.0
quantization=Q4_K_M
quantized_source_status=unverified
redistribution_status=not-approved
```

The exact Q4_K_M source repository/file is intentionally **not** filled in from
the filename alone. Multiple independently produced Q4_K_M files can represent
the same base model.

## Bound mirror record

During capsule finalization, if an active model exists,
`scripts/model-provenance.py bind MIRROR` creates:

```text
models/<sha256>/PROVENANCE
models/<sha256>/PROVENANCE.sha256
```

The bound record includes:

- actual model content SHA-256;
- exact preserved filename and byte count;
- base-model identity/source/license record;
- quantization label;
- exact quantized-source verification state;
- exact source repository/file/SHA only when verified;
- redistribution review state;
- the preservation mirror's `SOURCE-COMMIT`; and
- whether the metadata came from the CENTL catalog, an operator file, or an
  unrecorded fallback.

The output is deterministic for the same model, source commit, and provenance
input. It contains no timestamp that would cause the preservation tree to change
merely because the binding command was repeated.

## Exact GGUF origin confirmation

When the exact quantized source becomes known, create an operator provenance file
using:

```text
supply-chain/model-provenance/PROVENANCE.example
```

The critical fields are:

```text
quantized_source_status=verified
quantized_source_repository=<source repository URL>
quantized_source_file=<exact upstream file name>
quantized_source_sha256=<published/verified file SHA-256>
```

Then bind it:

```sh
CENTL_SCI_MODEL_PROVENANCE_FILE=/protected/path/model.provenance \
  python3 scripts/model-provenance.py bind /srv/centl-mirror
```

For a `verified` quantized source, the supplied
`quantized_source_sha256` **must exactly equal** the active preserved model's
computed SHA-256. A source page, filename, model card, or repository name is not
enough.

If the hash does not match, binding fails. The operator must determine whether the
local model came from another quantizer/revision rather than editing the expected
hash to make it pass.

## Redistribution is a separate decision

Even a content-hash-verified origin does not automatically make a model approved
for public redistribution by FCF.

The supported states are:

```text
not-approved
operator-reviewed-allowed
operator-reviewed-restricted
```

The built-in qualified-model catalog uses `not-approved`. An unverified exact
quantized origin cannot be marked `operator-reviewed-allowed` by the binder.

This is why the FCF public release exporter does not include `models/` at all.
Preservation for disaster recovery and public redistribution are separate
contracts.

## Unknown future models

If a future active model has no catalog entry and no operator provenance file,
CENTL still preserves its exact bytes. Binding creates an explicit unrecorded
record rather than guessing:

```text
base_model_id=unrecorded
base_model_license=unrecorded
quantized_source_status=unverified
redistribution_status=not-approved
```

That model remains recoverable, but its missing provenance is visible and can be
resolved later with an operator-verified sidecar.

## Verification

Run:

```sh
python3 scripts/model-provenance.py verify /srv/centl-mirror
```

Verification requires:

- `ACTIVE.sha256` to be a valid SHA-256;
- active model bytes to recompute to that digest;
- the model manifest filename to match the preserved file;
- `PROVENANCE.sha256` to verify the provenance record;
- bound content SHA-256, byte count, and filename to match the active model;
- bound preservation source commit to match `project/SOURCE-COMMIT`;
- a `verified` exact source SHA to equal the actual model digest; and
- provenance/redistribution states to satisfy the policy above.

The weekly/local `scripts/preservation-drill` runs this verification whenever an
active model is present.

## Relationship to recovery

`scripts/capsule-build` binds/verifies provenance before it regenerates the
whole-mirror receipt. The provenance record is therefore included in the same
strict preservation-copy checks as the GGUF, OCI capsule, and other recovery
material.

The no-network model recovery test still trusts only the model bytes as untrusted
semantic input. Provenance metadata documents origin; it does not elevate model
output into the trusted mathematical core.
