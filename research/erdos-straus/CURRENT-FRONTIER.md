# Current research frontier: from shadow completeness to the small-prime kernel

**Date:** 2026-08-14  
**Status:** active theorem program  
**Claim boundary:** Erdos-Straus remains open; universal Lopez Type A/B coverage and universal Direct-Shadow Completeness remain unproved.

This is the short moving-frontier record. The full synthesis remains [DIAMOND.md](DIAMOND.md).

## What is now exact

The candidatewise Direct-Shadow attack has reached `k<=1000`:

- `46,254` admissible hard-compatible Type A/B candidates;
- `12,610` directly shadowed candidates;
- `33,644` directly novel candidates;
- `33,644/33,644` explicit integer avoiding witnesses;
- `33,644/33,644` reduced avoiding progressions;
- `0` unresolved integer candidates;
- `0` unresolved reduced candidates;
- independent verifier verdict: `VERIFIED`;
- CENTL exact certification of selected hardest progression identities.

See [DIRECT-SHADOW-K1000.md](DIRECT-SHADOW-K1000.md).

The universal conjecture remains open, but no candidatewise union-shadow counterexample has appeared through one thousand layers.

## The covering-system bridge

For a candidate `x=r+Ls`, every earlier Type A/B layer induces a forbidden system

\[
s\bmod q_j\in R_j,
\qquad q_j=(4j-1)/\gcd(L,4j-1).
\]

Every nontrivial `q_j` is odd. Union shadowing is therefore a special structured odd covering problem.

The general Erdos-Selfridge odd covering problem is classical and open; our system is a much more restricted divisor-generated subclass with repeated moduli and multi-residue layers. See [ODD-COVERING-BRIDGE.md](ODD-COVERING-BRIDGE.md).

## New theorem: prime-power peeling

Write

\[
Q=\prod_p p^{A_p}
\]

for the total parameter period. For coordinate `p`, define

\[
\lambda_p
=
\sum_{p\mid q_j}\frac{|R_j|}{p^{v_p(q_j)}}.
\]

If

\[
\lambda_p<1,
\]

then `p` can be removed from the satisfiability problem: any solution of the constraints not involving `p` can be extended to a value of the `p^{A_p}` coordinate satisfying every incident constraint.

Adding the one local residue forbidden by the reducedness condition gives the augmented version used for prime realization.

See [SHADOW-KERNEL.md](SHADOW-KERNEL.md).

## Universal finite kernel through k=1000

Using only the trap sizes and the fact that `p|q_j` implies `p|4j-1`, define the conservative candidate-independent bound

\[
B_p(k)
=
\frac{1+\sum_{j<k,\ p\mid4j-1}|T_j|}{p}.
\]

Exact evaluation at `k=1000` gives

\[
B_p(1000)<1
\]

for every prime `p>=113`.

Therefore every admissible candidate through `k=1000` can shed every parameter prime coordinate at least `113` before the genuine obstruction is even considered.

Only 28 primes survive the universal first bound:

```text
3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47,
53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109
```

Candidate-specific peeling is stronger still.

This is the current theoretical pivot:

\[
\boxed{
\text{global union-cover problem}
\longrightarrow
\text{provably peelable large-prime exterior}
\longrightarrow
\text{small-prime shadow kernel}.
}
\]

## Coordinate-core proof mining

A new analyzer, [`shadow_coordinate_core.py`](shadow_coordinate_core.py), decomposes certified candidates into prime-power coordinates, satisfies all unary constraints first, prefers local residue `1` where possible, and measures how many coordinate changes are required to reach a globally satisfying assignment.

Exploratory analysis of the `k<=1000` certified bundle found a strikingly local pattern: most candidates are already satisfied by the unary-safe basepoint or require only a few prime-coordinate changes. The analyzer is now part of the automated research pipeline so future numbers will be regenerated and frozen with the certificate bundle rather than treated as an informal notebook observation.

## Attack currently running

The automated candidatewise falsification range has been raised to

\[
\boxed{k\le1200}
\]

with witness search through

\[
\boxed{s\le2,000,000}.
\]

The same run now also mines the prime-power coordinate core after independent witness verification and before CENTL certification/hashing.

For reference, the candidate-independent bound at `k=1200` already predicts that every prime coordinate `p>=127` is universally peelable; only primes through `113` can survive the first universal kernel bound.

No result from the in-progress run should be treated as established until the workflow finishes and the independent verifier, coordinate analyzer, CENTL checks, hashes, and artifact upload are green.

## The problem we are actually trying to solve now

The immediate theorem target is no longer "find more examples."

It is:

> Prove that the small-prime Type A/B shadow kernel always has a reduced satisfying assignment whenever no direct shadow exists.

A successful proof would convert the candidatewise finite phenomenon into universal DSC-P:

\[
\text{not directly shadowed}
\Longrightarrow
\text{reduced avoiding class}
\Longrightarrow
\text{infinitely many exact-depth primes}.
\]

If that succeeds, the shadow graph becomes a complete obstruction theory for Type A/B first-hit realizability.

That is the present edge of the diamond.