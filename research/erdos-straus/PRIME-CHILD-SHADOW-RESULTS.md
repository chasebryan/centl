# Prime-child shadow automated regression results

**Date:** 2026-08-15  
**Status:** completed green finite regression of proved theorem family  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** the universal proofs are in [PRIME-CHILD-SHADOWS.md](PRIME-CHILD-SHADOWS.md). The finite enumeration below is regression/falsification evidence, not the proof itself.

## Workflow provenance

Completed GitHub Actions run:

```text
workflow:     CENTL Erdős-Straus prime-child shadows
run id:       31852969007
head commit:  76ad8a9df8890a3dd0f6048b0985076a6d1852f9
conclusion:   success
artifact id:  9238092721
artifact sha256:
21a22ccdb80e505d9cacbf9a8932e088f3721bfc62b55c249e984066bbbdb6e5
```

## General ancestry-quotient regression

The analyzer tested every configured ancestry quotient

```text
q = 5, 9, 13, ..., 101
```

with base depths

```text
j <= 2000.
```

Whenever the ancestry child

\[
K=qj-\frac{q-1}{4}
\]

was prime, the analyzer explicitly enumerated `T_K`, reduced it modulo `4j-1`, and checked complete containment in `T_j`.

Result:

\[
\boxed{6,247/6,247}
\]

prime-child shadow checks passed.

No prime-child theorem regression failure occurred.

## Quotient-5 rigidity regression

For

\[
K=5j-1
\]

the workflow checked every

\[
1\le j\le50,000.
\]

Counts:

```text
prime children K:                   5,510
full unrestricted q=5 shadows:      5,510
prime/shadow mismatches:                0
```

Thus over all 50,000 tested bases,

\[
\boxed{
T_{5j-1}\bmod(4j-1)\subseteq T_j
\iff
5j-1\text{ is prime}
}

held exactly.

This agrees with the universal quotient-5 rigidity theorem.

## Why this matters

The finite ancestry map's strong quotient-5 population is now split cleanly into two phenomena:

1. an unrestricted infinite prime-child family, proved exactly;
2. extra shadows that appear only after Mordell-hard-class / prime-compatibility conditioning removes target classes.

The unrestricted theorem no longer needs to be inferred from finite graph statistics.

## Methodological note

The run hashes its JSON and report before artifact upload. The artifact digest above freezes the exact finite regression state.
