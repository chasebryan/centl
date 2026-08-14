# WS-CAND-002 — Justified outward decimal rendering

**Status:** candidate
**Date identified:** 2026-08-14
**Investigators / contributors:** CENTL/FCF research expedition
**Originating expedition:** secret-oasis-2026-08-14
**Source / commit / artifact identity:** `src/fstar/Centl.Core.fst`

## Core finding

After the verified core accepts dyadic enclosure endpoints and an exponent
budget, outward conversion onto a shared decimal scale is a proved containment.
Printed digits are therefore justified by the enclosure rather than by host
floating-point formatting.

## Assumptions and scope

- The trusted base still includes F*, extraction, OCaml, and the numerical
  backend that produced the dyadic endpoints.
- The theorem does not by itself make an enclosure narrow enough for a requested
  digit count.

## Evidence

- `Centl.Core` defines enclosure validation and outward decimal containment over
  exact integer inequalities.
- Host rendering consumes the validated representation rather than formatting
  machine floats.
- Deterministic and differential tests cover justified-digit cases.

Independent review: not performed. Formal proof of the local theorem is not the
same as independent designation review.

## Known counterexamples / failure modes

- If a printed digit can be shown to escape the validated enclosure, the claim
  is false.
- If rendering is found to pass through host floating-point before
  justification, the claim is false.

## Downstream avenues opened

- machine protocol decimal endpoints with explicit justification
- SCi presentation that cannot invent digits
- later verified interval operations that shrink the numerical trust boundary

## Oasis impact

Already present in the Oasis numerical contract. Designation would not change
the v0.14.0 release identity.

## Falsifiers / demotion conditions

- A counterexample enclosure whose rendered decimal is not an outward rounding.
- Prior art showing the exact theorem and interface are already standard and
  FCF's claim overstates novelty.

## References

- [`src/fstar/Centl.Core.fst`](../../src/fstar/Centl.Core.fst)
- [`docs/NUMERICS.md`](../NUMERICS.md)
