# cbx.kernel

**CB X-ray Kernel.** Experimental ES+ research instrument. Version **0.1.0**.

`cbis.kernel` remains the production letter engine. `cbx.kernel` is deliberately separate: it looks *through* the production cover and records what every lane would have done even when W already solved the prime.

The design note is [`../ES-plus/CBIS-K-PARAMETER-STATUS.md`](../ES-plus/CBIS-K-PARAMETER-STATUS.md).

## What it measures

For each Mordell-hard prime, CBX records:

- W linear hit status;
- membership in the residual `R`;
- first deterministic coprime `fab(a,b)` hit through the configured fab edge;
- Lane-I first signed-box hit
  \[
  k_I^*(p)=\min\{k:\delta_k((p+k)/4)=0\};
  \]
- Lane-N first external nonresidue prime and realized shift;
- Lane-L first López layer and modulus;
- the ordinary stacked production verdict `W -> I -> N -> L`.

The later lanes are evaluated **even when W hits**. Their results are X-ray diagnostics; they do not weaken or reorder the production verdict.

## Search grade

CBX does not pretend that one scalar `K` describes the complete finite search. A run stores

\[
\Gamma=(F,K_I,E_N,A_L),
\]

with defaults

```text
F    = 11
K_I  = 400
E_N  = 300
A_L  = 400
```

A named run has an immutable grade. If you want another grade, start another run name. This prevents one corpus from silently mixing different finite strengths.

`--k-max K` is a compatibility convenience that sets both `K_I` and `A_L`; the independent flags are preferred for research.

## Adaptive-I policies

The default is fixed:

```text
--k-policy fixed
```

Experimental policies are available for data collection only:

```text
--k-policy log
--k-policy log2
--k-policy spectrum-log
--policy-scale C
```

They choose a realized Lane-I bound below the configured `--i-max`. They are **not theorem-backed universal bounds** and do not change that claim boundary.

## Exact arithmetic

CBX uses deterministic 64-bit Miller-Rabin primality and Pollard-rho factorization rather than the bounded trial-factor fallback used by the current cbis implementation. The goal is to keep factor decomposition exact across the unsigned 64-bit arithmetic domain used by the kernel.

## Commands

```sh
make
./cbx self-test

./cbx probe 2521
./cbx solve 9658489

./cbx go
./cbx go --run deep-I --i-max 2000
./cbx go --run adaptive-a --i-max 5000 --k-policy log2 --policy-scale 2.0
./cbx go --home-only
./cbx go --sweep-only

./cbx status
./cbx status --run deep-I
```

Full grade controls:

```text
--fab-max F
--i-max K
--n-ell-max E
--l-max A
--k-max K
--k-policy fixed|log|log2|spectrum-log
--policy-scale C
```

The `probe` and `solve` commands inherit a named run's saved grade unless explicit grade flags are supplied.

## Output

Each named run writes append-only JSONL observations under

```text
observations/<run>.jsonl
```

and its cursor/grade under

```text
state/<run>.seed
```

If a target survives the complete production-equivalent grade, CBX preserves the existing `ES-LETTER-v1` content-addressed identity. Exact finite grades are recorded separately in

```text
letters/GRADES.jsonl
```

so the identity of the prime/event is not confused with the strength of the finite experiment that observed it.

Sweep and home maintain separate cursors. The home cursor is a strict **next-S** cursor, so batch endpoints are not intentionally revisited.

## Claim boundary

CBX is an instrument for discovering structure in the hidden I/N/L depth distribution. A finite miss is not an Erdős-Straus counterexample. A finite empty letter spectrum is not a proof.
