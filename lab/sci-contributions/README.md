# CENTL-SCi voluntary contribution data

CENTL-SCi does not transmit usage data by default.

The contribution system exists only to let users deliberately create local evidence that may help improve deterministic coverage, semantic routing, model qualification, and failure handling.

## User modes

`off` is the default.

- `off`: no contribution records are written.
- `diagnostics`: writes local structural/error metadata but never the submitted problem text.
- `examples`: writes the submitted problem text, interpreted SCi IR, status, and checked CENTL/CENTL Physics response to a local private JSONL file. This mode may capture sensitive text and must be chosen explicitly.

No mode performs network upload.

Use the installed `centl-sci` CLI:

```sh
centl-sci --contribution-status
centl-sci --contribution-diagnostics
centl-sci --contribution-examples
centl-sci --contribution-off
centl-sci --contribution-export ./centl-sci-review.jsonl
centl-sci --contribution-clear
```

An export is still private until the user deliberately shares it.

## Maintainer boundary

`lab/sci-contributions/private/` is gitignored. Maintainers may place received bundles there for local review, redaction, deduplication, and conversion into regression fixtures. It is not a privacy boundary outside a maintainer's own checkout and must never be force-added to Git.

`lab/sci-contributions/public/` is the opposite: everything committed there is public repository content. A case may enter that directory only after the contributor deliberately chose to publish it and the maintainer verified that the record contains no material that should remain private.

Do not represent a directory in a public GitHub repository as "developer-only". Git history is public once committed.

## Publication requirements

A future public contribution bundle must carry, at minimum:

- schema version;
- explicit `public_release: true` acknowledgement;
- contribution mode;
- the CENTL-SCi version used;
- a contributor-selected data license or other explicit permission suitable for the intended use;
- a statement that the contributor reviewed the exported material before publication.

No account identifier, device identifier, advertising identifier, IP address, hostname, home-directory path, or hidden telemetry identifier is part of the v1 capture schema.

## Development use

Contribution records are evidence, not authority. Before a contributed example can change deterministic admission or qualify a model, it should be converted into a reviewed corpus fixture with an independently established expected IR/status/result. CENTL remains the computational authority for admitted mathematics and physics.
