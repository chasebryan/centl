# Dyadic trap lattice automated regression results

**Date:** 2026-08-14  
**Status:** completed green finite regression of proved theorem family  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** the universal proofs are in [DYADIC-TRAP-LATTICE.md](DYADIC-TRAP-LATTICE.md). The finite enumeration below is a regression/falsification run, not the proof itself.

## Workflow provenance

GitHub Actions workflow:

```text
CENTL Erdős-Straus dyadic trap lattice
```

Completed run:

```text
run id:      31852068758
head commit: 6c9fce67e20f80bdb81194c697584401443398f6
conclusion:  success
```

Artifact:

```text
artifact id: 9237819599
name:        dyadic-trap-lattice-6c9fce67e20f80bdb81194c697584401443398f6
sha256:      5c1b2f4e70eaa724f39e7f449b2e0cf964b157c0bb40c89f4b658657828e226d
```

The artifact contains the JSON theorem-regression record, a human-readable report, and per-file SHA-256 hashes.

## Finite full-saturation classification

The regression checked every Type A/B depth

\[
1\le k\le50,000.
\]

The only layers satisfying

\[
T_k=-D_k
\]

were:

```text
1,
2,
4,
8,
16,
32,
64,
128,
256,
512,
1024,
2048,
4096,
8192,
16384,
32768
```

These are exactly the powers of two in the tested interval.

This agrees with the universal theorem proved in [DYADIC-TRAP-LATTICE.md](DYADIC-TRAP-LATTICE.md):

\[
\boxed{T_k=-D_k\iff k\text{ is a power of }2.}
\]

## Cyclic dyadic regression

The run checked dyadic exponents through

\[
0\le a\le18.
\]

The exceptional endpoint `a=0`, `k=1`, was verified separately:

```text
m = 3
D_1 = {1}
T_1 = {2} = -D_1
```

For every

\[
1\le a\le18,
\]

the run verified

\[
\boxed{
T_{2^a}=-\langle2\rangle
}
\]

and

\[
\boxed{
\operatorname{ord}_{2^{a+2}-1}(2)=a+2.
}
\]

Examples from the artifact:

| a | k | 4k-1 | trap/subgroup size |
|---:|---:|---:|---:|
| 1 | 2 | 7 | 3 |
| 3 | 8 | 31 | 5 |
| 5 | 32 | 127 | 7 |
| 11 | 2048 | 8191 | 13 |
| 15 | 32768 | 131071 | 17 |
| 18 | 262144 | 1048575 | 20 |

## Exact dyadic shadow edges

Through `a<=18`, the analyzer checked `18` cyclic dyadic divisibility edges and verified that every one maps the later trap set **onto** the earlier trap set.

Examples include:

```text
k=2    -> k=16       7 | 63
k=4    -> k=64      15 | 255
k=8    -> k=256     31 | 1023
k=16   -> k=1024    63 | 4095
k=32   -> k=4096   127 | 16383
```

The largest checked edge in the configured exponent range was

```text
k=256 -> k=262144
1023 | 1048575
```

with quotient `1025`.

The exact theorem is

\[
\boxed{
1\le a<b,\quad a+2\mid b+2
\Longrightarrow
T_{2^b}\bmod(2^{a+2}-1)=T_{2^a}.
}
\]

## Regression caught and corrected a theorem-boundary bug

The first automated run failed immediately at `a=0` because the initial draft incorrectly identified the divisor-generated subgroup at `k=1` with `<2>`.

That was false:

```text
D_1 is trivial because k=1 has no prime divisors.
```

The theorem and analyzer were corrected to treat `k=1` as an exceptional saturated endpoint and to begin the cyclic dyadic shadow lattice at `a=1`.

The corrected run completed green.

This is exactly the behavior desired from the research automation: the workflow is allowed to attack our theorem statement and force corrections before a result is frozen.

## Current interpretation

The dyadic family is now a fully proved and independently automated model of the broader shadow program:

\[
\boxed{
\text{dyadic depth}
\to
\text{Mersenne-type modulus}
\to
\text{exact multiplicative trap coset}
\to
\text{Mersenne divisibility}
\to
\text{infinite direct-shadow lattice}.
}
\]

It supplies a clean regression family for attempts to prove more general algebraic shadow theorems.
