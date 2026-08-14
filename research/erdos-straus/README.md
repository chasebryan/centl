# Erdős-Straus Type A/B automated research harness

This directory operationalizes the research program recorded in `docs/wellsprings/WS-CAND-003-erdos-straus-type-ab-shadow-structure.md`.

## Research map

**Current synthesis:** [`DIAMOND.md`](DIAMOND.md) records how the minimal Type A/B depth invariant, shadow graph, exact-depth spectrum, exact survivor hazard, prime-modulus backbone, and composite rescue core now fit into one theorem program.

Core linked records:

- [`THEORY.md`](THEORY.md) — foundational shadow and modulus-ancestry results;
- [`RESULTS-2026-08-14.md`](RESULTS-2026-08-14.md) — automated frontier, shadow map, independent verification, and CENTL certification;
- [`DEPTH-SPECTRUM.md`](DEPTH-SPECTRUM.md) — exact-depth realization and the structural-gap versus latency-gap distinction;
- [`DIRECT-SHADOW-COMPLETENESS.md`](DIRECT-SHADOW-COMPLETENESS.md) — candidatewise attack showing all 19,016 directly novel candidates through `k=600` have independently verified reduced avoiding progressions;
- [`PRIME-MODULUS-BACKBONE.md`](PRIME-MODULUS-BACKBONE.md) — infinite exact-depth prime-modulus backbone;
- [`SURVIVOR-DENSITY.md`](SURVIVOR-DENSITY.md) — exact finite-depth density, mass, and conditional hazard;
- [`COMPOSITE-CORE.md`](COMPOSITE-CORE.md) — zero-density prime-modulus survivor core and composite-rescue reduction;
- [`PRIOR-ART.md`](PRIOR-ART.md) — literature and priority boundary;
- [`CRYPTOLOGY.md`](CRYPTOLOGY.md), [`CRYPTOLOGY-THEORY.md`](CRYPTOLOGY-THEORY.md), and [`CRYPTOLOGY-RESULTS-2026-08-14.md`](CRYPTOLOGY-RESULTS-2026-08-14.md) — controlled cryptology side investigation;
- [`../../docs/wellsprings/WS-CAND-003-erdos-straus-type-ab-shadow-structure.md`](../../docs/wellsprings/WS-CAND-003-erdos-straus-type-ab-shadow-structure.md) — formal Wellspring Candidate record.

The harness is deliberately split into three layers:

1. `esc_research.py` regenerates the finite Type A/B first-hit computation, exact trap cardinalities, direct shadow map, shadow ancestry graph, finite candidate quotient families, and first-hit witnesses that prove selected classes are not union-shadowed by all previous layers.
2. `verify_research.py` independently rechecks the finite claims with a different implementation. In particular, direct-shadow certificates are verified by explicitly constructing the residue fibre and checking set containment.
3. `centl_certify.py` feeds the algebraic output into the repository's CENTL binary. CENTL exactly verifies every frontier Egyptian-fraction decomposition, one polynomial family for every frontier witness, and the modulus-ancestry polynomial identity for every observed divisibility quotient. It also emits a dedicated receipt for the current record family.

The GitHub Actions workflow `.github/workflows/erdos-straus-research.yml` builds CENTL from the checked-out commit, runs all three stages, hashes the outputs, and uploads the complete result bundle as a workflow artifact.

A separate candidatewise falsification workflow, `.github/workflows/erdos-straus-direct-shadow-completeness.yml`, now attacks the possibility that multiple earlier partial shadows can jointly cover a candidate even when no single earlier layer does. Its first completed run through `k=600` found explicit reduced avoiding progressions for all `19,016` directly novel candidates and independently reverified every certificate.

## Default research contract

The default automated run uses:

- prime limit `10,000,000`;
- hard classes modulo 840: `1, 121, 169, 289, 361, 529`;
- Type A/B depth search through `k=3000`;
- the checked-in thirteen-record frontier as a regression fixture;
- exact direct-shadow analysis through `k=3000`;
- explicit non-union-shadow witnesses wherever a first-hit prime is present.

Run locally after building CENTL:

```sh
rm -rf research-output
python3 research/erdos-straus/esc_research.py \
  --limit 10000000 \
  --k-max 3000 \
  --out research-output

python3 research/erdos-straus/verify_research.py \
  --out research-output

python3 research/erdos-straus/centl_certify.py \
  --centl _build/default/src/main.exe \
  --out research-output

(
  cd research-output
  sha256sum * > SHA256SUMS.final
)
```

## What is proved or certified by the harness

The finite computation can certify statements such as:

- a listed prime has no Type A/B hit below its claimed `C_AB` and does have a hit at that depth;
- a direct-shadow certificate really gives a complete residue fibre contained in an earlier trap set;
- every first-hit prime is an explicit witness that its current CRT class is not covered by the union of all earlier Type A/B trap layers;
- the trap-cardinality formula agrees with explicit trap enumeration through the configured `k` bound;
- observed modulus divisibility edges satisfy `4k-1 = q(4j-1)` with `q = 4s+1` and therefore `k=qj-s`;
- CENTL verifies the supplied exact Egyptian-fraction and polynomial identities without floating-point approximation.

The candidatewise completeness harness adds a stronger finite statement: through `k=600`, every directly novel hard-compatible candidate, not merely every realizable layer, has an explicit reduced avoiding progression and therefore an infinite exact-depth prime family by Dirichlet.

## What the harness does not prove

It does not prove the Erdős-Straus conjecture. It does not prove López's Type A/B coverage conjecture. It does not establish literature priority. In general, `direct_novel` means only that no **single** previous layer shadows the entire class; several earlier layers could still collectively cover it. The new `k<=600` candidatewise certificates rule that collective-coverage possibility out for every directly novel candidate in that finite range, but do not prove the universal implication for all `k`.

Observed quotient groups in `ancestry-candidate-families.json` are finite theorem candidates. They are not promoted to infinite shadow families without a separate proof.

## Research direction

The automation is designed to move the project from numerical scouting toward theorem discovery:

`Type A/B witnesses -> C_AB -> trap layers -> direct shadow -> modulus ancestry -> witnessed irredundant core -> candidate infinite families`.

The highest-value immediate theorem target is now the universal form of **Direct-Shadow Completeness**: prove or refute that every hard-compatible candidate not directly shadowed by one earlier layer admits a reduced avoiding class. In parallel, classify full shadowing along modulus-ancestry families, especially the `q=5` relation `k=5j-1`.

The broader theorem program is summarized in [`DIAMOND.md`](DIAMOND.md):

`C_AB -> shadow graph -> exact-depth spectrum -> exact survivor process -> prime-modulus backbone -> composite rescue core`.
