# FCF Semantic Origin

Status: implemented publication contract; public origin provisioning pending.

CENTL must not require a hosted language-model API, a model hub, or another
semantic middleman in order to use its reference semantic layer. The Foundation
therefore treats semantic-model distribution as part of the same preservation
and availability problem as source, releases, toolchains, and recovery material.

The **FCF Semantic Origin** is the canonical publication boundary for a
redistribution-approved CENTL-SCi model. CARAVAN may replicate those exact bytes,
but carriers do not decide which model is trusted.

## Design goals

1. **Local-first runtime.** CENTL-SCi, MIRAGE, and other semantic consumers run
   against user-controlled local model bytes.
2. **Foundation-supplied artifacts.** Once a model is approved for public
   redistribution, FCF can publish the exact qualified bytes directly from its
   preservation store.
3. **No runtime model-hub dependency.** A user who has the FCF artifact does not
   need Hugging Face, an inference API, or another model distributor to run it.
4. **Content identity before location.** The SHA-256 identity is authoritative.
   An HTTPS URL, FCF origin, or CARAVAN carrier is only a way to obtain those
   bytes.
5. **Availability never becomes authority.** CARAVAN carriers may supply bytes;
   authenticated FCF metadata determines which content identity is approved.
6. **Fail closed on redistribution.** Preservation is not publication. A model
   cannot enter the public semantic origin until provenance is verified and its
   bound record explicitly says `operator-reviewed-allowed`.

## Current reference lineage

The current reference lineage remains:

```text
Qwen/Qwen3-4B-Instruct-2507
```

The repository records the base-model license as Apache-2.0. The current
qualified Q4_K_M filename still has an unverified exact third-party quantized
origin and is therefore **not currently public-origin eligible**.

This distinction is intentional. FCF should not turn a provenance gap into a
distribution claim merely because the model works locally.

The preferred long-term path is for FCF to preserve an immutable official base
revision, produce or fully verify its own canonical quantization, record the
exact resulting SHA-256, complete redistribution review, and then export those
bytes through this contract.

## Publication gate

A preserved model is eligible for public export only when all of the following
are true:

- `models/ACTIVE.sha256` is a valid lowercase SHA-256;
- the active model bytes recompute to that digest;
- `MANIFEST` names the same file, digest, and byte count;
- `PROVENANCE` and `PROVENANCE.sha256` verify;
- `content_sha256`, `file_name`, and `bytes` match the active model;
- `quantized_source_status=verified`;
- `quantized_source_sha256` equals the active model digest;
- base-model identity and license are recorded; and
- `redistribution_status=operator-reviewed-allowed`.

`scripts/model-origin-export.py` enforces this gate and does not contain a flag
that bypasses it.

Check an existing preservation mirror without writing publication output:

```sh
python3 scripts/model-origin-export.py /srv/centl-mirror --check
```

Export an eligible model into a static HTTPS origin tree:

```sh
python3 scripts/model-origin-export.py \
  /srv/centl-mirror \
  /srv/www/pub/centl
```

## Exported layout

The exporter creates:

```text
/pub/centl/
  ORIGIN-SHA256SUMS
  models/
    ACTIVE.json
    sha256/
      <model-sha256>/
        <model>.gguf
        PROVENANCE
        PROVENANCE.sha256
  caravan/
    catalog-v1.json
```

The model remains content-addressed. `models/ACTIVE.json` is a small discovery
record, not a replacement for the SHA-256 identity.

`ORIGIN-SHA256SUMS` covers the exported model and metadata so an origin copy can
be audited independently.

## CARAVAN relationship

The exporter emits `caravan/catalog-v1.json` using the existing
`centl-caravan-catalog-v1` schema. The model entry is:

- identified as `sha256:<digest>`;
- split into the same authenticated 4 MiB chunk records used by CARAVAN;
- marked `public-approved`; and
- given a stable logical path under `models/sha256/`.

That catalog is application metadata. Before a networked CARAVAN client trusts
it, the catalog must be published through the existing authenticated TUF
metadata path. A carrier cannot replace the trust root, change the approved
digest, or promote a preservation-only model into public distribution.

The resulting retrieval order can therefore be:

```text
local content-addressed cache
        |
        v
FCF Semantic Origin
        |
        v
authenticated CARAVAN carriers
```

All three routes converge on the same SHA-256 identity. Location can change;
authority does not.

## OASIS relationship

OASIS is the strict stable-product branch and release declaration. An Oasis
release may name a semantic model only by an immutable qualified identity and
must not silently fall back to an unrelated online model or hosted API.

The semantic layer remains optional to mathematical correctness. Semantic output
does not become mathematical evidence merely because its model is preserved or
FCF-hosted.

For an Oasis publication that includes a reference semantic model, the model
origin gate, provenance verification, and no-network runtime checks should all be
green before the model is advertised as part of the release.

## MIRAGE relationship

MIRAGE is intentionally more permissive because it is the development and
experimental branch. It may evaluate alternate local models and quantizations,
but experimental artifacts remain explicitly unqualified.

Promotion from MIRAGE toward OASIS requires a deliberate identity transition:

```text
experimental model
    -> preserved exact bytes
    -> bound provenance
    -> evaluation
    -> redistribution review
    -> public-approved immutable identity
```

MIRAGE must never teach CENTL to depend on a third-party hosted inference API as
a hidden prerequisite.

## Hosting boundary

The GitHub Pages site remains the human-readable directory. Large model weights
do not belong in the Pages Git repository.

The semantic origin tree is deliberately static so FCF can serve it from any
ordinary HTTPS file server, object store, or future Foundation-controlled
infrastructure without changing the artifact format. GitHub can remain a
bootstrap development and source-distribution surface while the byte origin is
moved under direct FCF operational control.

## Operator checklist

Before making a semantic model publicly reachable:

1. Preserve the exact base-model revision.
2. Preserve or produce the exact GGUF.
3. Bind and verify model provenance.
4. Complete license and redistribution review.
5. Set `redistribution_status=operator-reviewed-allowed` only after that review.
6. Run `model-origin-export.py --check`.
7. Export the origin tree.
8. Authenticate the CARAVAN catalog through TUF.
9. Copy the origin to at least one independent FCF-controlled preservation
   location and verify receipts.
10. Publish the origin endpoint in **The Bazaar** only after the bytes are
    actually reachable and audited.

The Bazaar is a directory of provisioners. It is not itself the trust anchor.
