# Constructive nonuniversal square-lift certificate results

**Date:** 2026-08-15  
**Status:** completed green finite regression of the universal square-lift classification  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** the universal classification proof is in [UNIVERSAL-SQUARE-LIFT-SHADOW-CLASSIFICATION.md](UNIVERSAL-SQUARE-LIFT-SHADOW-CLASSIFICATION.md). The finite certificates below are regression/falsification evidence.

## Workflow provenance

Completed GitHub Actions run:

```text
workflow:     CENTL Erdős-Straus square-lift counterexamples
run id:       31852781397
head commit:  45adfb05f8f454b2564fe52338dc7255e425c05a
conclusion:   success
artifact id:  9238029825
artifact sha256:
9f221d7cf82f8a27ccd02beb35da98513852120837047fadf8ef11cff7666d87
```

## Result

Every base

\[
1\le j\le5000
\]

except the three proved universal bases

\[
\boxed{1,2,4}
\]

received an explicit constructive certificate showing that some odd square lift escapes the base shadow.

Thus:

```text
bases checked:                         5,000
universal bases skipped:               1,2,4
nonuniversal bases certified:          4,997
unresolved bases:                          0
```

For every certified base the artifact records:

1. a Jacobi-negative residue `v` outside the base trap set;
2. the positive class `u=-v mod (4j-1)`;
3. a prime `ell == u mod (4j-1)`;
4. an odd square-lift parameter `c` satisfying
   `c^2 == -(4j-1)^(-1) mod ell`;
5. the lifted depth
   \[
   K=((4j-1)c^2+1)/4;
   \]
6. the check `ell|K`;
7. the explicit lifted trap residue
   \[
   -\ell\equiv v\pmod{4j-1},
   \]
   which lies outside the base trap set.

Each tuple therefore directly witnesses failure of universal square-lift shadowing for that base.

## Search scale

Across all `4,997` nonuniversal bases:

```text
maximum progression prime used:         1,270,909
maximum progression search steps:              68
maximum constructed lift depth: 19,833,438,467,899,419
```

The enormous maximum lifted depth is not evidence that the theorem needs huge numbers. It reflects the deliberately direct constructive Dirichlet/reciprocity certificate mechanism.

## Interpretation

The finite certification agrees perfectly with the universal theorem:

\[
\boxed{
\text{base shadows every odd square lift}
\iff
j\in\{1,2,4\}.
}
\]

The key methodological point is that every nonuniversal base receives a **positive counterexample certificate**, rather than merely failing to pass a finite shadow scan.

This is a particularly strong regression design because any future change to the theorem machinery can be checked against thousands of explicit escape constructions.
