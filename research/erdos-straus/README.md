# Erdős-Straus Type A/B automated research harness

This directory operationalizes the research program recorded in `docs/wellsprings/WS-CAND-003-erdos-straus-type-ab-shadow-structure.md`.

The harness is deliberately split into three layers:

1. `esc_research.py` regenerates the finite Type A/B first-hit computation, exact trap cardinalities, direct shadow map, shadow ancestry graph, finite candidate quotient families, and first-hit witnesses that prove selected classes are not union-shadowed by all previous layers.
2. `verify_research.py` independently rechecks the finite claims with a different implementation. In particular, direct-shadow certificates are verified by explicitly constructing the residue fibre and checking set containment.
3. `centl_certify.py` feeds the algebraic output into the repository's CENTL binary. CENTL exactly verifies every frontier Egyptian-fraction decomposition, one polynomial family for every frontier witness, and the modulus-ancestry polynomial identity for every observed divisibility quotient. It also emits a dedicated receipt for the current record family.

The GitHub Actions workflow `.github/workflows/erdos-straus-research.yml` builds CENTL from the checked-out commit, runs all three stages, hashes the outputs, and uploads the complete result bundle as a workflow artifact.

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

## What the harness does not prove

It does not prove the Erdős-Straus conjecture. It does not prove López's Type A/B coverage conjecture. It does not establish literature priority. `direct_novel` means no **single** previous layer shadows the entire class; several earlier layers could still collectively cover it. The stronger cases are the classes carrying actual first-hit primes, because those primes are concrete counterexamples to such collective coverage.

Observed quotient groups in `ancestry-candidate-families.json` are finite theorem candidates. They are not promoted to infinite shadow families without a separate proof.

## Research direction

The automation is designed to move the project from numerical scouting toward theorem discovery:

`Type A/B witnesses -> C_AB -> trap layers -> direct shadow -> modulus ancestry -> witnessed irredundant core -> candidate infinite families`.

The next mathematical target is a necessary-and-sufficient condition for full shadowing along modulus-ancestry families, especially the `q=5` relation `k=5j-1`, followed by an exact treatment of collective union shadowing for classes without an explicit first-hit witness.
