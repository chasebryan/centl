# Full quadratic-signature coset for Type A/B traps

**Status:** proved structural theorem with finite proof-mining evidence  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this note does not prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture. López 2024 records the Type B Jacobi-nonresidue property. The vector-valued local-signature packaging below is being treated as a novelty candidate within the minimal-depth/shadow program pending broader literature review.

Read with:

- [QUADRATIC-TRAP-SIGNATURE.md](QUADRATIC-TRAP-SIGNATURE.md)
- [CHARACTER-SHIELD-COMPLETENESS.md](CHARACTER-SHIELD-COMPLETENESS.md)
- [MULTIPLICATIVE-TRAP-COSET.md](MULTIPLICATIVE-TRAP-COSET.md)
- [DIRECT-SHADOW-COMPLETENESS.md](DIRECT-SHADOW-COMPLETENESS.md)
- [DIAMOND.md](DIAMOND.md)

## 1. Local signature map

Fix `k>=1` and write

\[
m=4k-1=\prod_{i=1}^r p_i^{a_i}.
\]

For every unit `x mod m`, define its local quadratic signature

\[
\boxed{
\lambda_m(x)=
\left(
\ell_{p_1}(x),\ldots,\ell_{p_r}(x)
\right)
\in\mathbb F_2^r,
}
\]

where

\[
\left(\frac{x}{p_i}\right)=(-1)^{\ell_{p_i}(x)}.
\]

Thus each coordinate records the Legendre sign at one distinct prime divisor of `m`.

Let

\[
\eta_m=\lambda_m(-1).
\]

Its `p_i` coordinate is `1` exactly when `p_i=3 mod 4`.

## 2. Divisor-signature space

Let `P(k)` denote the distinct prime divisors of `k`, including `2` when appropriate. Define

\[
\boxed{
V_k=\operatorname{span}_{\mathbb F_2}
\{\lambda_m(\ell):\ell\in P(k)\}.
}
\]

Every divisor `e|k` is obtained by choosing exponents of these primes. Since quadratic signatures only remember exponent parity, and a divisor may independently include or omit one copy of each prime divisor, the set of signatures attained by divisors of `k` is exactly

\[
\boxed{
\{\lambda_m(e):e\mid k\}=V_k.
}
\]

## 3. Quadratic-signature trap theorem

Recall

\[
T_k=\{-e,-4e\pmod m:e\mid k\}.
\]

### Theorem

The set of local quadratic signatures attained by the complete Type A/B trap set is the affine subspace

\[
\boxed{
\lambda_m(T_k)=\eta_m+V_k.
}
\]

### Proof

For `e|k`, multiplicativity of Legendre symbols gives

\[
\lambda_m(-e)=\eta_m+\lambda_m(e).
\]

Because `4` is a square modulo every odd prime,

\[
\lambda_m(4)=0,
\]

and therefore

\[
\lambda_m(-4e)=\eta_m+\lambda_m(e).
\]

As `e` ranges over divisors of `k`, `lambda_m(e)` ranges over exactly `V_k`. Hence

\[
\lambda_m(T_k)=\eta_m+V_k.
\]

QED.

## 4. Quadratic quotient dimension

Define

\[
\boxed{
\kappa(k)
=r-\dim V_k.
}
\]

Then the trap signatures occupy exactly a fraction

\[
\boxed{2^{-\kappa(k)}}
\]

of all possible local Legendre-sign vectors.

The Jacobi theorem is the weakest universal projection of this statement. The product of the local Legendre signs is the Jacobi symbol, so the previous `Jacobi=-1` trap signature is one nonzero linear functional vanishing on `V_k`.

Therefore

\[
\boxed{\kappa(k)\ge1}
\]

for every `k`.

When `kappa(k)>1`, the vector-valued signature shield excludes strictly more unit classes than the single Jacobi bit can see.

## 5. Candidate restriction

For a target candidate at depth `K`, write

\[
x\equiv r\pmod L,
\qquad
L=\operatorname{lcm}(840,4K-1).
\]

At an earlier layer `j<K`, some prime-sign coordinates of `lambda_{m_j}(x)` are fixed by `x=r mod L`; the remaining coordinates are free choices obtainable by CRT.

Intersect the affine trap-signature space

\[
\eta_{m_j}+V_j
\]

with the fixed signs.

The resulting forbidden set on the free sign coordinates is again an affine subspace. It therefore falls into four exact cases:

1. **empty:** the earlier layer is automatically safe at quadratic-signature resolution;
2. **full:** every free signature lands in the trap-signature envelope, giving one direct signature obstruction;
3. **codimension one:** safety is equivalent to one linear XOR equation;
4. **higher codimension:** only a smaller affine subset of free signatures is forbidden.

This converts the earlier residue system into a finite affine-subspace avoidance problem over `F_2`.

## 6. Signature shield theorem

If one can choose the free local Legendre signs so that, for every earlier `j<K`, the resulting signature lies outside

\[
\eta_{m_j}+V_j,
\]

then the target candidate has a reduced avoiding arithmetic progression and therefore infinitely many primes of exact Type A/B depth `K`.

The proof is the same CRT/Dirichlet construction used for the scalar character shield, but with prescribed local Legendre signs at the relevant primes. A Type A/B trap would force its full local signature into the forbidden affine coset, contradicting the construction.

This criterion is sufficient, not necessary: an integer can share a trap's quadratic signature while still avoiding the much smaller exact residue set `T_j`.

## 7. Relation to the multiplicative trap coset

Let

\[
H_k=\langle\ell\bmod m_k:\ell\mid k,\ \ell\text{ prime}\rangle.
\]

The multiplicative theorem gives

\[
T_k\subseteq-H_k.
\]

Applying the local Legendre-sign map gives

\[
\lambda_m(-H_k)=\eta_m+V_k.
\]

Thus the quadratic-signature theorem is exactly the maximal elementary-2 quotient visible through the individual Legendre characters of the full multiplicative trap coset.

The hierarchy is

\[
\boxed{
T_k
\subseteq
-H_k
\longrightarrow
\eta_m+V_k
\longrightarrow
\text{Jacobi }-1.
}
\]

Each arrow discards information.

## 8. Finite replay through k <= 1200

A proof-mining replay of the frozen `41,470` directly novel candidates through `k<=1200` used this full local quadratic-signature system without consulting the stored exact avoiding witness.

It found:

```text
full quadratic-signature shield solved: 30,786
direct signature residual:              10,684
collective linear inconsistency found:       0
unresolved non-direct signature systems:     0
```

Every one of the `30,786` non-direct-signature candidates was solved by the deterministic base solution of the codimension-one XOR system; no randomized repair trial was needed in that replay.

This is a finite diagnostic, not a universal theorem that collective quadratic-signature obstruction never occurs.

The key conceptual observation is that the richer local signature geometry independently resolves candidates that the scalar Jacobi shield leaves in its negative core.

## 9. Next theorem target

The strongest finite pattern now asks for a signature-level analogue of Direct-Shadow Completeness:

> If no single earlier layer is a full quadratic-signature obstruction, can the collection of earlier affine signature traps ever cover all globally compatible sign assignments?

The `k<=1200` replay found no such collective obstruction.

A proof would remove the entire elementary-2 quotient from the exact DSC-P problem and leave only:

- direct signature residual layers;
- higher-order multiplicative quotient information;
- prime-power lifting inside a fixed signature;
- the final exact divisor-generated residue sets.

That is a substantially smaller target than the original global covering system.
