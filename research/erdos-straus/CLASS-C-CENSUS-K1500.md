# Class-C active-core census through k = 1500

**Status:** exact finite theorem-certificate result  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Coordinator:** Operator-01 / primary research lead  
**Partner framework:** Operator-02 active fixed-negative core and valuation-source split  
**Claim boundary:** this is an exact finite-range result. It does not prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture.

Read with:

- [CLASS-C-C1-SINGLE-ACTIVE.md](CLASS-C-C1-SINGLE-ACTIVE.md)
- [SINGLE-ACTIVE-LOCAL-ESCAPE.md](SINGLE-ACTIVE-LOCAL-ESCAPE.md)
- [OPERATOR-COORDINATION.md](OPERATOR-COORDINATION.md)
- [operator-02/DIAMOND-FIXED-NEGATIVE-PULLBACK-SPLIT.md](operator-02/DIAMOND-FIXED-NEGATIVE-PULLBACK-SPLIT.md)
- [operator-02/DIAMOND-VALUATION-CRITERION.md](operator-02/DIAMOND-VALUATION-CRITERION.md)
- [DIRECT-SHADOW-K1500.md](DIRECT-SHADOW-K1500.md)

## 1. Provenance

The census replays the already frozen candidate bundle from the completed direct-shadow workflow:

```text
source workflow run:  31849103304
source artifact id:   9238241616
source candidate set: 53,240 directly novel candidates through k<=1500
```

The census itself ran in a separate replay-only workflow:

```text
census workflow run: 31854324273
workflow head:       d330e20082297d21f3005f5a173eaebfdc40ea9b
census artifact id:  9238613961
artifact sha256:
9ba6c7425356dac272821a71b677811ed697c3dd062040cf78302b5f272031ba
```

The artifact contains:

- `class-c-census.json`
- `class-c-census-report.md`
- `class-c-census-independent-verifier.json`
- `provenance.txt`
- `SHA256SUMS`

Its internal SHA-256 manifest was checked successfully.

## 2. Independent verification

The independent verifier reconstructs the fixed-negative core, active subcore, valuation sources, exact pullbacks, residual fiber kernels, and bounded selectors with a different peeling control flow: local fiber loads are recomputed from scratch after every peel rather than maintained incrementally.

It returned:

```json
{
  "direct_novel_candidates_checked": 53240,
  "independent_control_flow": "fiber loads recomputed from scratch after each peel",
  "k_limit": 1500,
  "mismatched_sections": [],
  "single_active_candidates_checked": 2770,
  "verdict": "VERIFIED"
}
```

Therefore the counts below are independently reproduced finite statements.

## 3. Active-core census

Among all `53,240` directly novel candidates:

```text
character shield solvable, N empty:             38,658
N^act empty:                                     43,968
N nonempty but N^act empty:                       5,310
exactly one active fixed-negative layer:          2,770
```

The `5,310` inactive-only cases are especially important conceptually: scalar character shielding can fail even though every fixed-negative row is already parameter-inactive. Direct novelty then certifies exact safety at those locked rows.

## 4. Single-active population

For all

\[
\boxed{2,770}
\]

candidates with

\[
|\mathcal N^{\mathrm{act}}_{k,r}|=1,
\]

the unique active quotient was:

```text
q = 3: 1,322
q = 5:    34
q = 9: 1,414
```

No other `q` occurred.

Every one of the 2,770 cases was Operator-02 **Class A only**:

```text
Class A only: 2,770
Class B only:     0
mixed A/B:        0
```

Thus every observed active valuation excess came from a higher power of a prime already dividing the target progression modulus `L`. No even-powered free-prime source occurred in the single-active population through `k<=1500`.

This `3,5,9` / Class-A-only collapse is a finite result, not yet a universal theorem.

## 5. Exact pullback size

For the unique active row `j0`, the exact forbidden pullback `R_j0` was tiny:

```text
|R_j0| = 0: 2,644 candidates
|R_j0| = 1:   126 candidates
```

The number of locally reduced and exact-safe residues modulo `q_j0` was never zero. The minimum was

\[
\boxed{2}.
\]

Distribution:

```text
2 reduced-safe residues:   12 candidates
3 reduced-safe residues: 1310
5 reduced-safe residues:   34
8 reduced-safe residues:  114
9 reduced-safe residues: 1300
```

This finite behavior is consistent with the universal local lemma in [SINGLE-ACTIVE-LOCAL-ESCAPE.md](SINGLE-ACTIVE-LOCAL-ESCAPE.md).

## 6. Fiber-kernel interaction

The 2,770 single-active candidates split as:

```text
fiber kernel empty:      1,290
fiber kernel nonempty:   1,480
```

Among the 1,480 nonempty residual systems, the unique active fixed-negative row itself survived fiber peeling only

\[
\boxed{18}
\]

times.

It was removed before the final residual kernel in

\[
\boxed{1,462}
\]

cases.

Residual edge-source census:

```text
nonfixed earlier rows:                 69,672
unique active fixed-negative row:          18
other fixed-negative rows:                   0
fixed-positive rows:                         0
```

This is a decisive organizational result:

\[
\boxed{
\mathcal N^{\mathrm{act}}
\text{ and the final fiber residual are different resolutions.}
}
\]

The active fixed-negative core identifies where scalar character shielding fails while the parameter still moves. It does **not** identify the complete exact residual row set after fiber peeling.

## 7. Residual kernel signatures in C1

Among the 1,480 nonempty single-active systems, the observed residual signatures were:

```text
{3,5,11,13,17,19,23}:           680
{3,11,13}:                       336
{3,11,13,19,23}:                 210
{3,5,11,17,19,23}:               160
{3,11,13,17,19,23}:               54
{3,5,11,13,17,19,23,29,31}:      16
{3,5,13,17,19,23}:                12
{3,5,11,13,19,23}:                 6
{3,11,13,19}:                       4
{11,13}:                             2
```

The two `{11,13}` cases are the smallest nontrivial residual systems in this C1 range and are priority exact laboratories.

## 8. Independent bounded-selector result

Every nonempty C1 residual kernel was solved by the fixed bounded selector menu

\[
\{0,\pm1,\ldots,\pm64\}.
\]

Result:

\[
\boxed{1,480/1,480}
\]

with maximum required absolute selector

\[
\boxed{48}.
\]

This is finite evidence only. It does not prove a universal bounded-selector theorem.

## 9. What the census changed

The original Class-C intuition risked treating `N^act` as the exact residual obstruction.

The census rejects that simplification.

The correct coordinated picture is:

\[
\boxed{
\begin{array}{c}
\text{fixed-negative character core }\mathcal N\\
\downarrow\\
\text{parameter-active subcore }\mathcal N^{act}\\
\downarrow\\
\text{exact fiber peeling}\\
\downarrow\\
\text{mostly nonfixed residual rows}
\end{array}}
\]

So the next theorem must coordinate two structures:

1. the valuation/character mechanism controlling `N^act`;
2. the nonfixed exact rows that survive into the small-prime fiber kernel.

## 10. New theorem targets

The verified census gives four immediate targets:

1. **single-active excess theorem:** prove as much as possible about why a unique active fixed-negative row has a prime-power excess quotient of very low complexity;
2. **hard-class `3,5,9` collapse:** prove or falsify the observed restriction `q in {3,5,9}` and absence of Class B in the hard-class single-active regime;
3. **two-prime residual theorem:** solve the two `{11,13}` C1 systems structurally rather than by selector lookup;
4. **active-to-nonfixed coordination:** identify why the unique active row usually peels away while the remaining nonfixed rows still admit a common local escape.

The first of these already admits a universal prime-power reduction, recorded separately in the next theorem note.
