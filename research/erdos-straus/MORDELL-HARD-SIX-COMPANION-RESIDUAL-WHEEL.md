# Mordell-hard six-companion residual wheel

**Status:** proved elementary cross-shift theorem  
**Date:** 2026-08-16  
**Depends on:** `MORDELL-HARD-FORCED-SEED-LAW.md`, `MORDELL-HARD-232-COPRIME-TRIPLES.md`  
**Regression:** `verify_mordell_hard_six_companion_wheel.py`  
**Claim boundary:** this is an exact structural theorem for every complete six-shift Mordell-hard block. It does not assert that one of the six shifts must hit the Erdős–Straus targets.

## 1. A complete admissible shift wheel

Let

\[
p=24m+1
\]

be Mordell-hard. Fix an integer `t>=0` and consider the six consecutive admissible shifts in one period modulo 24:

\[
\boxed{
k_j=24t+3+4j,
\qquad j=0,1,2,3,4,5.
}
\]

Thus the block is

\[
\boxed{
24t+3,\ 24t+7,\ 24t+11,\ 24t+15,\ 24t+19,\ 24t+23.
}
\]

Put

\[
n=m+t.
\]

Then the six shifted companions are exactly the six consecutive integers

\[
\boxed{
C_0=6n+1,
C_1=6n+2,
C_2=6n+3,
C_3=6n+4,
C_4=6n+5,
C_5=6n+6.
}
\]

In particular,

\[
\boxed{C_{j+1}=C_j+1.}
\]

## 2. Universal seed pattern

The corresponding values

\[
u_j=\frac{k_j+1}{4}
\]

are

\[
6t+1,\ 6t+2,\ 6t+3,\ 6t+4,\ 6t+5,\ 6t+6.
\]

By the maximal hard forced-seed law,

\[
g_j=\gcd(6,u_j),
\]

so every complete six-shift block has the universal seed pattern

\[
\boxed{(g_0,g_1,g_2,g_3,g_4,g_5)=(1,2,3,2,1,6).}
\]

Therefore the companions factor canonically as

\[
\boxed{
(C_0,C_1,C_2,C_3,C_4,C_5)
=(R_0,\,2R_1,\,3R_2,\,2R_3,\,R_4,\,6R_5),
}
\]

where the maximal seed-stripped residuals are

\[
\boxed{
R_0=6n+1,
\quad
R_1=3n+1,
\quad
R_2=2n+1,
\quad
R_3=3n+2,
\quad
R_4=6n+5,
\quad
R_5=n+1.
}
\]

The earlier `2-3-2` theorem is precisely the middle subwheel `(R_1,R_2,R_3)`.

## 3. Full pairwise gcd graph

There are fifteen unordered pairs among the six residuals. Thirteen are always coprime. The remaining two have completely controlled gcds.

### Pairs involving `R0=6n+1`

\[
R_0-2R_1=-1,
\]

hence

\[
\boxed{\gcd(R_0,R_1)=1.}
\]

Also

\[
R_0-3R_2=-2.
\]

Both `R0` and `R2` are odd, so

\[
\boxed{\gcd(R_0,R_2)=1.}
\]

Further,

\[
R_0-2R_3=-3.
\]

But `R0=1 mod 3`, so

\[
\boxed{\gcd(R_0,R_3)=1.}
\]

Since

\[
R_4-R_0=4
\]

and both are odd,

\[
\boxed{\gcd(R_0,R_4)=1.}
\]

Finally,

\[
R_0-6R_5=-5.
\]

Therefore

\[
\boxed{
\gcd(R_0,R_5)=\gcd(R_5,5)=\gcd(n+1,5).
}
\]

This gcd is either `1` or `5`.

### Pairs involving `R1=3n+1`

\[
2R_1-3R_2=-1,
\]

so

\[
\boxed{\gcd(R_1,R_2)=1.}
\]

Also

\[
R_3-R_1=1,
\]

hence

\[
\boxed{\gcd(R_1,R_3)=1.}
\]

Next,

\[
R_4-2R_1=3.
\]

Since `R1=1 mod 3`,

\[
\boxed{\gcd(R_1,R_4)=1.}
\]

Finally,

\[
R_1-3R_5=-2,
\]

so

\[
\boxed{
\gcd(R_1,R_5)=\gcd(R_5,2)=\gcd(n+1,2).
}
\]

This gcd is either `1` or `2`.

### Pairs involving `R2=2n+1`

\[
3R_2-2R_3=-1,
\]

so

\[
\boxed{\gcd(R_2,R_3)=1.}
\]

Also

\[
R_4-3R_2=2.
\]

Both `R2` and `R4` are odd, hence

\[
\boxed{\gcd(R_2,R_4)=1.}
\]

And

\[
R_2-2R_5=-1,
\]

so

\[
\boxed{\gcd(R_2,R_5)=1.}
\]

### Remaining pairs

\[
2R_3-R_4=-1,
\]

hence

\[
\boxed{\gcd(R_3,R_4)=1.}
\]

Also

\[
R_3-3R_5=-1,
\]

so

\[
\boxed{\gcd(R_3,R_5)=1.}
\]

Finally,

\[
R_4-6R_5=-1,
\]

so

\[
\boxed{\gcd(R_4,R_5)=1.}
\]

## 4. Six-wheel residual-support theorem

Combining all fifteen pairs gives the complete graph.

### Theorem — residual support is disjoint outside `2` and `5`

For every Mordell-hard prime and every complete six-shift block, the maximal seed-stripped residuals

\[
R_0,\ldots,R_5
\]

have pairwise coprime prime supports except for exactly two possible shared-prime edges:

\[
\boxed{
5\text{ may be shared only by }R_0\text{ and }R_5,
}
\]

and this occurs exactly when

\[
5\mid n+1;
\]

while

\[
\boxed{
2\text{ may be shared only by }R_1\text{ and }R_5,
}
\]

and this occurs exactly when

\[
2\mid n+1.
\]

Every rational prime

\[
\boxed{q\ne2,5}
\]

can divide **at most one** residual in the entire six-shift wheel.

No other residual-support overlap is possible.

## 5. Exact overlap graph

Writing an edge only when a nontrivial gcd can occur, the residual overlap graph has six vertices and only two edges:

```text
R0 --------(5)-------- R5 --------(2)-------- R1

R2     R3     R4
```

All omitted pairs have gcd exactly `1`.

Even these two exceptional edges are conditional:

```text
R0--R5 exists only if 5 | n+1
R1--R5 exists only if 2 | n+1
```

Thus the generic wheel has completely disjoint residual support, and the exceptional wheel has overlap through known tiny primes only.

## 6. Relation to the unstripped companions

The six original companions are consecutive integers, so adjacent companions are automatically coprime.

The residual theorem is stronger because it controls nonadjacent layers after removing exactly the maximal universal seeds `1,2,3,2,1,6`.

For example, a large rational prime appearing in the residual factorization of `C_{24t+7}` cannot reappear in any residual factorization attached to the other five shifts in the same block.

This converts six nominally separate factorization problems into one nearly disjoint prime-support allocation problem.

## 7. Current classified wheels

### Wheel `t=0`

\[
(3,7,11,15,19,23).
\]

The terminal shift `23` is already seed-aware with forced factor 6.

### Wheel `t=1`

\[
(27,31,35,39,43,47).
\]

Known seed-aware or seed-reduced layers include:

- `k=31`, where the existing theorem is organized by the forced factor 2 and its 2-adic valuation;
- `k=35`, reduced to 64 hard miss states after forced factor 3;
- `k=39`, reduced to 36 hard miss states after forced factor 2;
- `k=47`, reduced to 196 hard miss states after forced factor 6.

The wheel theorem shows that their seed-stripped rational-prime supports are almost completely disjoint across the whole six-layer block.

### Wheel `t=2`

\[
(51,55,59,63,67,71).
\]

Current exact hard-state reductions include:

```text
k=55    314 misses
k=59  5,869 misses
k=63     87 misses
```

The middle three are the already-proved `2-3-2` coprime subwheel. The full theorem adds the neighboring residuals at 51, 67, and 71 and proves that, apart from the named 2/5 edges involving the final residual, large-prime packet resources are disjoint across all six layers.

### Wheel `t=4`

\[
(99,103,107,111,115,119).
\]

The corrected finite 100M survivor `p=8,803,369` misses at 103 and first hits at 107. Its k=107 companion is in the seed-3 position of this wheel.

## 8. State-theoretic consequence

A fixed-shift miss state records which residue directions are supplied by the prime factors of its companion. Before this theorem, cross-shift mining could accidentally treat the same rational prime as if it were independently available in multiple neighboring layers.

The six-wheel theorem forbids that almost completely.

After consuming the maximal seeds:

- a rational prime `q != 2,5` can contribute packet directions to at most one of the six residual states;
- prime `5` can contribute to two residual states only on the exact edge `(R0,R5)` and only when `5|n+1`;
- prime `2` can contribute to two residual states only on `(R1,R5)` and only when `2|n+1`.

Therefore a simultaneous six-layer obstruction must allocate its nontrivial rational-prime packet resources across an almost-disjoint support partition constrained by the linear companion identities.

This is a substantially smaller cross-shift compatibility problem than the Cartesian product of six generic miss tables.

## 9. What this theorem does not say

Residual support disjointness does **not** imply that the six shifts cover every hard prime. Different rational primes can independently realize the packet requirements of different layers.

A coverage theorem would still need to prove that the required six-state packet configuration cannot coexist under the linear residual relations.

The wheel theorem supplies the missing coupling invariant for that next step.

## 10. Reproduction

```sh
python3 research/erdos-straus/verify_mordell_hard_six_companion_wheel.py \
  --max-t 1000 --json
```

The verifier checks:

1. the six consecutive companion identities;
2. the universal seed pattern `1,2,3,2,1,6`;
3. the exact residual normal form;
4. all fifteen pairwise residual gcd formulas;
5. the two and only two possible overlap edges.

Erdős–Straus remains open. The theorem turns each complete 24-period shift block into an almost-disjoint residual prime-support wheel.