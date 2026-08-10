# Matching a preserved GGUF to known source candidates

A candidate ledger is comparison evidence, not an origin claim. Use it only after
the real model bytes have been preserved and content-addressed.

For the active model in an FCF mirror:

```sh
python3 scripts/model-provenance-candidates.py /srv/centl-mirror
```

The command recomputes the active model SHA-256 and compares it against the
filename-specific candidate ledger under `supply-chain/model-provenance/`.

If no digest matches, it reports:

```text
match=none
```

That is a normal result. Do not infer an origin from the closest filename,
repository popularity, file size, or quantization label.

If exactly one candidate digest matches, the matcher reports
`match=exact-sha256` with the recorded source repository and source filename.
It can also emit an operator-review sidecar:

```sh
python3 scripts/model-provenance-candidates.py \
  /srv/centl-mirror \
  --require-match \
  --output /tmp/centl-model.provenance
```

Review the generated record, then bind it to the mirror:

```sh
CENTL_SCI_MODEL_PROVENANCE_FILE=/tmp/centl-model.provenance \
  python3 scripts/model-provenance.py bind /srv/centl-mirror

python3 scripts/model-provenance.py verify /srv/centl-mirror
```

The emitted sidecar keeps:

```text
redistribution_status=not-approved
```

An exact source match establishes origin evidence; it does not independently
complete a redistribution-license review.

Candidate ledgers should contain only independently obtained exact SHA-256 values
and HTTPS source repositories. Duplicate hashes are rejected by the matcher. A
ledger row does not alter the active model and does not become trusted provenance
until the active model's computed digest matches it exactly.
