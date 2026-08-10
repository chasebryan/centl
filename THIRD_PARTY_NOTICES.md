# Third-party notices

CENTL depends on and interoperates with software and model artifacts that are **not relicensed by CENTL's Apache-2.0 migration**. Their upstream licenses remain authoritative.

## Native and build dependencies

Current source and release tooling uses components including:

| Component | Role | License handling |
| --- | --- | --- |
| F* | verification and checked extraction | upstream license is preserved with release/build provenance |
| OCaml | compiler/runtime | upstream license and applicable linking terms are preserved |
| Zarith | arbitrary-precision OCaml arithmetic support | upstream license is preserved |
| Yojson | JSON support | upstream license is preserved |
| FLINT | exact and rigorous native mathematics | upstream LGPL notices/source references are preserved in native release packages |
| GMP | arbitrary-precision integer/rational native arithmetic | upstream GPL/LGPL notices/source references are preserved in native release packages |
| MPFR | correctly rounded floating-point arithmetic | upstream GPL/LGPL notices/source references are preserved in native release packages |
| Julia / Nemo | independent differential-testing laboratory | upstream licenses apply; these are not relicensed as CENTL code |
| llama.cpp | optional local CENTL-SCi inference runtime | upstream license/copyright notices must remain with any redistributed runtime |

The release packagers copy the exact dependency license texts used for a given packaged build into the release `licenses/` directory and record source/relinking references where required. Those packaged texts, the pinned toolchain records, and upstream source are the controlling evidence for the exact dependency version distributed in a release.

## Models and model repositories

CENTL-SCi model weights, GGUF files, tokenizer/configuration files, and preserved model repositories are separate artifacts. A model is not covered by Apache-2.0 merely because CENTL can load it, validate its output, preserve its bytes, or record its provenance.

Public redistribution of model material requires its own verified provenance and license review. CENTL's preservation tooling deliberately distinguishes recoverability from redistribution approval.

## Imported assets and data

Any imported image, dataset, fixture, standard text, or other material carrying its own copyright/license notice retains that notice and license. Project-wide SPDX defaults in `.reuse/dep5` apply only where CENTL/FCF has authority to make the stated grant.

## Relicensing rule

Nothing in `LICENSE`, `LICENSING.md`, `.reuse/dep5`, or repository metadata is intended to replace a valid third-party license. If a conflict is discovered, the narrower third-party notice governs that material until the provenance is corrected.
