# Direct-Shadow Completeness attack through k = 1500

**Status:** exact finite theorem-certificate result; universal theorem remains open  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this record does not prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture.

This record supersedes `DIRECT-SHADOW-K1200.md` as the latest fully frozen all-stage candidatewise certificate frontier.

## 1. Completed workflow provenance

GitHub Actions run:

```text
run id:       31849103304
head commit:  c508994fb48e6f701f15577352f275df5646cd78
artifact id:  9238241616
```

Artifact ZIP digest:

```text
sha256:e181a66bec9a8e0d68b4b6b46892b6c71c50ebe8ab64c45944c8c17408c983dd
```

Configured range:

```text
k_limit:      1500
search_limit: 3000000
```

Every workflow stage completed successfully: candidate attack, independent verifier, coordinate-core mining, coarse peeling, fiber peeling, bounded residual selector, quadratic-character analysis, CENTL certification, SHA-256 freezing, and artifact upload.

## 2. Exact candidatewise result

```text
admissible candidates:             73,814
directly shadowed candidates:      20,574
directly novel candidates:         53,240
integer avoiding witnesses:        53,240
reduced avoiding witnesses:        53,240
unresolved integer candidates:          0
unresolved reduced candidates:          0
```

Therefore

\[
\boxed{53,240/53,240}
\]

directly novel hard-compatible candidates through `k<=1500` are explicitly not covered by the union of all earlier Type A/B layers.

More strongly, every one has a reduced avoiding progression, and hence an infinite exact-depth prime progression by Dirichlet.

This is an exact finite-range certificate statement only.

## 3. Independent verification

The independent verifier returned:

```json
{
  "direct_novel_candidates_checked": 53240,
  "integer_witnesses_verified": 53240,
  "k_limit": 1500,
  "reduced_witnesses_verified": 53240,
  "unresolved_integer_candidates": 0,
  "unresolved_reduced_candidates": 0,
  "verdict": "VERIFIED"
}
```

No candidatewise union-shadow counterexample appeared through depth 1500.

## 4. Hardest first reduced witnesses

The largest first reduced parameters include:

| k | h | t | first reduced s | x = r + Ls |
|---:|---:|---:|---:|---:|
| 1488 | 121 | 5858 | 2,664,772 | 13,320,769,304,761 |
| 1443 | 121 | 5768 | 2,548,375 | 12,353,606,223,961 |
| 1338 | 289 | 5349 | 2,277,454 | 10,236,795,302,449 |
| 1488 | 169 | 5920 | 2,275,978 | 11,377,254,388,249 |
| 1285 | 121 | 4111 | 2,208,004 | 3,177,141,479,521 |
| 1380 | 529 | 5507 | 2,158,986 | 10,008,973,062,169 |

The finite survival is therefore not an artifact of tiny parameter choices.

## 5. Prime-power coordinate locality

For the `53,240` directly novel candidates:

```text
canonical unary-safe assignment solves: 17,776 / 53,240 = 33.388%
maximum guided repair count:             10 prime-power coordinates
```

Cumulative guided upper bounds:

```text
0 changes: 33.388%
<=1:       66.405%
<=2:       85.804%
<=3:       94.701%
<=4:       98.131%
<=5:       99.435%
<=6:       99.853%
<=7:       99.964%
<=8:       99.992%
<=9:       99.996%
<=10:     100.000%
```

These guided counts are proof-mining upper bounds, not proven minima.

## 6. Exact coarse and fiber peeling

The exact prime-power load criterion alone fully resolves

\[
754/53,240=1.416\%
\]

of candidates. Its largest residual kernel has 28 prime coordinates, largest residual prime 109, and the conservative universal first-bound leaves only primes at most 139 potentially non-peelable before the true candidate geometry is used.

The sharper exact augmented fiber peeling resolves

\[
\boxed{26,532/53,240=49.835\%}
\]

with an empty residual kernel.

Across all candidates, the largest residual fiber kernel has 9 prime coordinates and the largest residual prime observed is

\[
\boxed{31}.
\]

The kernel-size distribution is:

```text
size 0: 26,532
size 2:     28
size 3:  3,996
size 4:      6
size 5:    384
size 6:  1,582
size 7: 20,274
size 9:    438
```

Thus the theorem-driven reduction continues to collapse a global system with hundreds of earlier layers to a tiny small-prime interior.

## 7. Bounded-selector result

The workflow then tests the fixed residual selector menu

\[
\mathcal S_{64}=\{0,\pm1,\ldots,\pm64\}.
\]

All nonempty fiber kernels were solved:

\[
\boxed{26,708/26,708}.
\]

Therefore the independent two-stage construction

\[
\boxed{
\text{exact fiber peeling}
+
\text{bounded residual selector}
}
\]

resolves

\[
\boxed{53,240/53,240}
\]

directly novel candidates through `k<=1500`, without consulting the stored sequential witness to decide either stage.

Unresolved bounded-selector kernels:

\[
\boxed{0}.
\]

The largest selector radius actually required remains

\[
\boxed{54},
\]

the same maximum observed in the earlier `k<=1200` replay.

## 8. Quadratic-character layer

The exact trap-signature checker performed

\[
\boxed{22,428}
\]

explicit Jacobi trap checks and all passed.

The scalar character shield independently certifies

\[
\boxed{38,658/53,240=72.611\%}
\]

of the directly novel candidates.

The remaining character residual is

\[
\boxed{14,582}.
\]

The stronger theorem in `CHARACTER-SHIELD-COMPLETENESS.md` explains why collective scalar-character inconsistency cannot arise except from a fixed-negative earlier layer. These residuals therefore mark where exact trap geometry, higher local signatures, multiplicative quotients, square-lift structure, and p-adic refinement are actually needed.

## 9. Relation to the theorem program

The exact finite frontier now reads:

```text
k <= 600:   19,016 / 19,016 directly novel candidates reduced-realizable
k <= 1000:  33,644 / 33,644
k <= 1200:  41,470 / 41,470
k <= 1500:  53,240 / 53,240
```

No candidatewise collective-shadow counterexample has appeared.

More importantly, the latest range is not supported only by sequential witness search. Every directly novel candidate is also independently resolved by the theorem-driven fiber-peeling plus bounded-selector construction.

The immediate universal target remains

\[
\boxed{
\text{directly novel}
\Longrightarrow
\text{reduced avoiding progression}
}
\]

for all admissible Type A/B candidates.

The active proof route is now to explain why the residual fiber kernels remain confined to small prime coordinates and why the selector radius remains bounded, using the quadratic-signature, multiplicative-quotient, reciprocity, square-lift, and exact two-box trap structure already recorded elsewhere in this directory.
