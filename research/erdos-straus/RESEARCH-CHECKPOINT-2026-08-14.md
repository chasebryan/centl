# FCF/CENTL Erdős-Straus research checkpoint

**Frozen:** 2026-08-14  
**Purpose:** repository checkpoint for the active Type A/B depth-spectrum / shadow-completeness program.  
**Claim boundary:** this is an archival index, not an additional mathematical claim.

This checkpoint exists so that theorem notes, automation, analyzers, finite certificates, and the current proof direction remain recoverable from Git history while the research continues.

## Primary synthesis

- [`DIAMOND.md`](DIAMOND.md)
- [`CURRENT-FRONTIER.md`](CURRENT-FRONTIER.md)
- [`../../docs/wellsprings/WS-CAND-003-erdos-straus-type-ab-shadow-structure.md`](../../docs/wellsprings/WS-CAND-003-erdos-straus-type-ab-shadow-structure.md)

## Exact-depth and shadow records

- [`THEORY.md`](THEORY.md)
- [`RESULTS-2026-08-14.md`](RESULTS-2026-08-14.md)
- [`DEPTH-SPECTRUM.md`](DEPTH-SPECTRUM.md)
- [`DIRECT-SHADOW-COMPLETENESS.md`](DIRECT-SHADOW-COMPLETENESS.md)
- [`DIRECT-SHADOW-K1000.md`](DIRECT-SHADOW-K1000.md)
- [`DIRECT-SHADOW-K1200.md`](DIRECT-SHADOW-K1200.md)
- [`SHADOW-COVER-GEOMETRY.md`](SHADOW-COVER-GEOMETRY.md)
- [`ODD-COVERING-BRIDGE.md`](ODD-COVERING-BRIDGE.md)

## Current proof-mining stack

- [`SHADOW-KERNEL.md`](SHADOW-KERNEL.md) — prime-power local-load peeling theorem;
- [`FIBER-SHADOW-KERNEL.md`](FIBER-SHADOW-KERNEL.md) — sharper fiber-load peeling theorem;
- [`QUADRATIC-TRAP-SIGNATURE.md`](QUADRATIC-TRAP-SIGNATURE.md) — Jacobi `-1` trap theorem and quadratic character shield;
- [`shadow_coordinate_core.py`](shadow_coordinate_core.py);
- [`shadow_kernel_analyzer.py`](shadow_kernel_analyzer.py);
- [`shadow_fiber_kernel_analyzer.py`](shadow_fiber_kernel_analyzer.py);
- [`quadratic_trap_signature_analyzer.py`](quadratic_trap_signature_analyzer.py).

## Larger theorem architecture

- [`PRIME-MODULUS-BACKBONE.md`](PRIME-MODULUS-BACKBONE.md)
- [`SURVIVOR-DENSITY.md`](SURVIVOR-DENSITY.md)
- [`COMPOSITE-CORE.md`](COMPOSITE-CORE.md)
- [`PRIOR-ART.md`](PRIOR-ART.md)

## Cryptology side investigation

- [`CRYPTOLOGY.md`](CRYPTOLOGY.md)
- [`CRYPTOLOGY-THEORY.md`](CRYPTOLOGY-THEORY.md)
- [`CRYPTOLOGY-RESULTS-2026-08-14.md`](CRYPTOLOGY-RESULTS-2026-08-14.md)

## Automation

The candidatewise workflow is

- [`.github/workflows/erdos-straus-direct-shadow-completeness.yml`](../../.github/workflows/erdos-straus-direct-shadow-completeness.yml)

and now executes discovery, independent verification, coordinate-core analysis, coarse prime-power peeling, fiber peeling, quadratic-character shielding, CENTL exact certification, SHA-256 freezing, and artifact upload.

The main research workflow remains

- [`.github/workflows/erdos-straus-research.yml`](../../.github/workflows/erdos-straus-research.yml).

## Recent repository commits in this proof direction

- `bc06f4c8fee9d3b243c73b3f99df3b9eb326c5c6` — add quadratic trap signature theorem;
- `1214e2fd6c4c0b11f05ca0b2d238c0c789177700` — automate quadratic character-shield analysis;
- `4e0a54f0b69cd230011ccca7acb34d54b85b885f` — integrate the quadratic analyzer into the candidatewise workflow and artifact bundle;
- `3d04ec32e03af13bfc807d907daf118ce3884d56` — refresh the research map to include the current proof stack.

Earlier finite certificate bundles are additionally preserved as GitHub Actions artifacts with their own SHA-256 manifests.

## Research continuity rule

For this active program, substantive new theorem notes, algorithms, proof-mining scripts, or frozen numerical conclusions should be committed to the repository before they are treated as part of the durable research record. Workflow-generated evidence should continue to be hashed and uploaded as artifacts.

The current immediate theorem target remains a proof or refutation of universal DSC-P:

\[
\boxed{
\text{directly novel}
\Longrightarrow
\text{reduced avoiding progression}.
}

The current proof strategy is to combine exact shadow redundancy, prime-power/fiber elimination, and quadratic-character structure until any hypothetical obstruction is forced into a small residual core that can be classified exactly.
