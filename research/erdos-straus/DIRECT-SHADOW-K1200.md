# Direct-Shadow Completeness attack through k = 1200

**Status:** exact finite theorem-certificate result; universal theorem remains open  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Research lineage:** [DIAMOND.md](DIAMOND.md) -> [DIRECT-SHADOW-COMPLETENESS.md](DIRECT-SHADOW-COMPLETENESS.md) -> [DIRECT-SHADOW-K1000.md](DIRECT-SHADOW-K1000.md) -> this record

This record extends the candidatewise falsification attack through `k=1200` and freezes the first full automated prime-power coordinate-core diagnostic.

It does **not** prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture.

## 1. Exact candidatewise result

The completed GitHub Actions run used:

- all six Mordell-hard classes modulo `840`;
- every Type A/B layer through `k=1200`;
- every prime-compatible admissible target residue;
- witness search through `s=2,000,000`;
- an independent modular verifier;
- the prime-power coordinate proof-mining analyzer;
- CENTL exact certification of selected hardest CRT progression identities;
- SHA-256 freezing and artifact publication.

The exact result was:

```text
admissible candidates:             57,367
directly shadowed candidates:      15,897
directly novel candidates:         41,470
integer avoiding witnesses:        41,470
reduced avoiding witnesses:        41,470
unresolved integer candidates:          0
unresolved reduced candidates:          0
```

Therefore

\[
\boxed{
41,470/41,470
\text{ directly novel candidates through }k=1200
\text{ are explicitly not union-shadowed.}
}
\]

And more strongly,

\[
\boxed{
41,470/41,470
\text{ have reduced avoiding progressions.}
}
\]

Every one therefore has an explicit Dirichlet progression containing infinitely many primes whose first Type A/B hit occurs at that candidate's depth.

This is an exact finite-range certificate statement, not an asymptotic or universal theorem.

## 2. Independent verification

The independent verifier returned:

```json
{
  "direct_novel_candidates_checked": 41470,
  "integer_witnesses_verified": 41470,
  "k_limit": 1200,
  "reduced_witnesses_verified": 41470,
  "unresolved_integer_candidates": 0,
  "unresolved_reduced_candidates": 0,
  "verdict": "VERIFIED"
}
```

Thus the growth from `33,644` directly novel candidates at `k<=1000` to `41,470` at `k<=1200` introduced no collective-shadow counterexample and no failure of reduced prime realization.

## 3. Hardest first reduced witnesses

The largest first reduced parameters in this run included:

| k | h | t | first reduced s | x = r + Ls |
|---:|---:|---:|---:|---:|
| 1146 | 169 | 4579 | 1,232,114 | 4,743,294,875,089 |
| 1170 | 529 | 3899 | 1,200,079 | 4,716,744,233,569 |
| 1160 | 289 | 4607 | 1,066,259 | 4,154,955,601,729 |
| 1116 | 169 | 4427 | 1,065,106 | 3,992,999,483,929 |
| 1148 | 529 | 4550 | 1,060,095 | 4,088,194,001,329 |
| 1200 | 529 | 3199 | 1,059,772 | 4,272,114,097,969 |
| 1176 | 361 | 4691 | 1,019,129 | 4,026,090,113,161 |
| 1165 | 529 | 4426 | 1,012,370 | 1,320,658,207,369 |
| 1200 | 529 | 4784 | 1,009,638 | 4,070,014,316,449 |
| 1148 | 529 | 4583 | 991,301 | 3,822,896,533,369 |

The appearance of first avoiding parameters above one million reinforces that the positive certificates are not arising merely from trivial tiny parameter choices.

## 4. Prime-power coordinate locality

The run also froze the first complete coordinate-core diagnostic for all `41,470` directly novel candidates.

The analyzer begins from a canonical assignment satisfying all single-prime-support constraints, preferring local residue `1` wherever possible. It then uses the already-certified reduced witness only to guide which prime-power coordinates to change. The repair count is therefore an explicit upper bound on local Hamming distance to a satisfying assignment; it is not asserted to be minimal and is not an independent proof of witness existence.

Results:

```text
canonical unary-safe assignment solves: 15,715 / 41,470 = 37.895%
maximum guided repair count:             9 prime-power coordinates
```

Repair distribution:

| changed prime-power coordinates | candidates | cumulative |
|---:|---:|---:|
| 0 | 15,715 | 37.895% |
| 1 | 13,838 | 71.264% |
| 2 | 7,292 | 88.847% |
| 3 | 3,017 | 96.122% |
| 4 | 1,080 | 98.727% |
| 5 | 367 | 99.612% |
| 6 | 123 | 99.908% |
| 7 | 34 | 99.990% |
| 8 | 3 | 99.998% |
| 9 | 1 | 100.000% |

Thus every one of the `41,470` certified candidates lies within at most nine prime-power coordinate changes of this simple unary-safe basepoint under the guided construction.

That is a proof-mining observation, not a universal bounded-repair theorem. Its importance is structural: a huge global congruence system is exhibiting very low local repair complexity.

## 5. CENTL certification and artifact

CENTL verified all generated symbolic progression identities for the selected hardest cases. The independent number-theoretic verifier remained responsible for earlier-layer avoidance and reducedness.

The completed artifact bundle was uploaded by workflow run `31846146909` with artifact ID `9236427053`.

Artifact ZIP SHA-256 digest:

```text
a2479a4113d693af2e647ffc2e007d3d7b1cf628ce7190f72c4ad6282a98ba14
```

The bundle contains the complete candidate certificate JSON, independent verifier result, coordinate-core result, CENTL receipt, build information, generated contracts, reports, and per-file hashes.

## 6. What changed conceptually

The candidatewise pattern has now survived three increasingly strong exact ranges:

```text
k <= 600:   19,016 / 19,016 directly novel candidates reduced-realizable
k <= 1000:  33,644 / 33,644 directly novel candidates reduced-realizable
k <= 1200:  41,470 / 41,470 directly novel candidates reduced-realizable
```

No union-shadow counterexample has appeared.

At the same time, the coordinate-core result says the certified solution space is not merely nonempty. It appears close, in prime-power-coordinate distance, to a very simple local basepoint.

This is exactly the behavior motivating the stronger local elimination theory in [SHADOW-KERNEL.md](SHADOW-KERNEL.md) and [FIBER-SHADOW-KERNEL.md](FIBER-SHADOW-KERNEL.md).

## 7. New target

The research frontier is no longer just to push the number `1200` upward.

The main target is to prove that the Type A/B pullback system admits a local-to-global construction:

\[
\boxed{
\text{directly novel}
\Longrightarrow
\text{small-prime fiber kernel}
\Longrightarrow
\text{reduced local solution}
\Longrightarrow
\text{infinite exact-depth prime family}.
}
\]

The first implication is now partially supported by exact peeling theorems rather than computation alone. The second is where the deepest remaining structure appears to live.
