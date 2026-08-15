# Erdős-Straus research backup — 2026-08-14

**Project:** Free Computation Foundation / CENTL  
**Purpose:** durable checkpoint of the active Type A/B theorem program  
**Claim boundary:** this checkpoint does not claim a proof of the Erdős-Straus conjecture, universal López Type A/B coverage, or universal Direct-Shadow Completeness.

This file exists specifically so the live research state is recoverable from the repository even if chat context, local scratch files, or workflow artifacts later disappear.

## Canonical research chain

- [WS-CAND-003](../../docs/wellsprings/WS-CAND-003-erdos-straus-type-ab-shadow-structure.md)
- [DIAMOND.md](DIAMOND.md)
- [CURRENT-FRONTIER.md](CURRENT-FRONTIER.md)
- [DEPTH-SPECTRUM.md](DEPTH-SPECTRUM.md)
- [SPECTRUM-INFINITE-COINFINITE.md](SPECTRUM-INFINITE-COINFINITE.md)
- [DIRECT-SHADOW-COMPLETENESS.md](DIRECT-SHADOW-COMPLETENESS.md)
- [DIRECT-SHADOW-K1000.md](DIRECT-SHADOW-K1000.md)
- [DIRECT-SHADOW-K1200.md](DIRECT-SHADOW-K1200.md)
- [FIBER-SELECTOR-K1200.md](FIBER-SELECTOR-K1200.md)
- [SHADOW-COVER-GEOMETRY.md](SHADOW-COVER-GEOMETRY.md)
- [SHADOW-KERNEL.md](SHADOW-KERNEL.md)
- [FIBER-SHADOW-KERNEL.md](FIBER-SHADOW-KERNEL.md)
- [QUADRATIC-TRAP-SIGNATURE.md](QUADRATIC-TRAP-SIGNATURE.md)
- [CHARACTER-SHIELD-COMPLETENESS.md](CHARACTER-SHIELD-COMPLETENESS.md)
- [QUADRATIC-SIGNATURE-COSET.md](QUADRATIC-SIGNATURE-COSET.md)
- [PROPER-JACOBI-ANCESTOR.md](PROPER-JACOBI-ANCESTOR.md)
- [MULTIPLICATIVE-TRAP-COSET.md](MULTIPLICATIVE-TRAP-COSET.md)
- [TRAP-QUOTIENT-FACTORIZATION.md](TRAP-QUOTIENT-FACTORIZATION.md)
- [SQUARE-LIFT-CORE.md](SQUARE-LIFT-CORE.md)
- [MERSENNE-SHADOW-LATTICE.md](MERSENNE-SHADOW-LATTICE.md)
- [PRIME-POWER-TRAP-DICHOTOMY.md](PRIME-POWER-TRAP-DICHOTOMY.md)
- [PRIME-MODULUS-BACKBONE.md](PRIME-MODULUS-BACKBONE.md)
- [SURVIVOR-DENSITY.md](SURVIVOR-DENSITY.md)
- [COMPOSITE-CORE.md](COMPOSITE-CORE.md)
- [PRIOR-ART.md](PRIOR-ART.md)

## Latest fully frozen finite certificate frontier

The completed candidatewise Direct-Shadow attack through `k<=1200` produced:

```text
admissible candidates:             57,367
directly shadowed candidates:      15,897
directly novel candidates:         41,470
integer avoiding witnesses:        41,470
reduced avoiding witnesses:        41,470
unresolved integer candidates:          0
unresolved reduced candidates:          0
independent verifier:              VERIFIED
```

Every directly novel hard-compatible candidate through depth 1200 therefore has an explicit reduced avoiding progression and an infinite exact-depth prime family by Dirichlet.

Completed workflow provenance:

```text
run id:       31846146909
head commit:  ef88f759a68907e517430e82432c5054f463edc5
artifact id:  9236427053
artifact sha256:
a2479a4113d693af2e647ffc2e007d3d7b1cf628ce7190f72c4ad6282a98ba14
```

This is finite and does not prove universal DSC-P.

## Independent fiber-selector replay of the same frozen bundle

The later theorem-driven replay did not use the stored sequential witness to decide fiber peelability or selector success.

Exact augmented fiber peeling completely removed the residual system for

\[
\boxed{26,044/41,470}
\]

candidates.

All remaining

\[
\boxed{15,426/15,426}
\]

nonempty fiber kernels were solved by the fixed selector menu

\[
\boxed{0,\pm1,\ldots,\pm64}.
\]

Largest selector radius actually required:

\[
\boxed{54}.
\]

Unresolved residual kernels:

\[
\boxed{0}.
\]

Every nonempty residual kernel in this finite replay used primes at most `23`.

See [FIBER-SELECTOR-K1200.md](FIBER-SELECTOR-K1200.md).

## Exact theorem expansion frozen after the k<=1200 run

### Character obstruction completeness

At the scalar Jacobi/squareclass level,

\[
\boxed{W_k\cap F_k=U_k.}
\]

Thus collective quadratic-character inconsistency occurs if and only if one fixed-only earlier layer is already Jacobi-negative. There is no genuinely collective new obstruction at this scalar character level.

### Full local quadratic-signature coset

If

\[
m_k=\prod p_i^{a_i},
\]

and `lambda` records the vector of local Legendre signs, then

\[
\boxed{\lambda(T_k)=\eta_k+V_k.}
\]

The trap signatures form one exact affine subspace. The scalar Jacobi `-1` theorem is only one projection.

A finite replay through `k<=1200` found:

```text
full local quadratic-signature shield solved: 30,786
direct signature residual:                    10,684
collective linear inconsistency:                   0
unresolved non-direct signature systems:           0
```

This finite absence of collective signature obstruction is not yet a universal theorem.

### Proper Jacobi ancestor theorem

If the local signature codimension satisfies

\[
\kappa(k)\ge2,
\]

then there is a proper squarefree divisor

\[
d\mid\operatorname{rad}(4k-1),
\qquad d<4k-1,
\qquad d\equiv3\pmod4,
\]

such that every Type A/B trap at depth `k` is Jacobi-negative modulo `d`.

Thus every higher-codimension quadratic trap envelope has a strictly earlier Jacobi ancestor.

### Multiplicative trap coset

Let

\[
H_k=\langle\ell\bmod(4k-1):\ell\mid k,\ \ell\text{ prime}\rangle.
\]

Then

\[
\boxed{T_k\subseteq-H_k}
\]

and

\[
\boxed{-1\notin H_k.}
\]

### Exact quotient factorization

Let

\[
\iota(k)=[(\mathbb Z/(4k-1)\mathbb Z)^\times:H_k]
\]

and let `kappa(k)` be the quadratic-signature codimension. Then

\[
\boxed{\iota(k)=2^{\kappa(k)}\Theta(k)}
\]

with

\[
\Theta(k)=[\ker\lambda:H_k\cap\ker\lambda].
\]

Therefore the exact unit trap density factors as

\[
\boxed{
\frac{|T_k|}{\varphi(4k-1)}
=2^{-\kappa(k)}\Theta(k)^{-1}\frac{|T_k|}{|H_k|}.
}
\]

This separates quadratic-signature filtering, higher-order multiplicative filtering, and exact divisor sparsity.

### Square-lift core

If an earlier layer is fixed at squareclass level, every prime outside the target progression modulus occurs to even exponent. The post-character residual therefore has the form

\[
q_j=c_js_j^2
\]

with the new-prime part carried by squares. The remaining character residual is a higher `p`-adic lifting problem rather than another free quadratic-sign problem.

## Infinite exact structural-gap theorem

For power-of-two depths

\[
k=2^a,
\qquad m=2^{a+2}-1,
\]

we proved

\[
\boxed{T_{2^a}=-\langle2\rangle.}
\]

If

\[
a+2\mid b+2,
\qquad a<b,
\]

then

\[
\boxed{T_{2^b}\text{ is completely directly shadowed by }T_{2^a}.}
\]

Hence infinitely many depths can never be minimal `C_AB` values for any integer.

For every `b>=3` with `b+2` composite,

\[
\boxed{2^b\text{ is structurally impossible as a minimal Type A/B depth}.}
\]

Within the exponent-indexed power-of-two subsequence, a density-one set of exponents is therefore killed by this exact Mersenne ancestry.

The companion prime-power theorem proves this full coset saturation is binary exceptionalism: for every odd prime `p`,

\[
\boxed{T_{p^a}\subsetneq-\langle p\rangle.}
\]

## Spectrum synthesis

The prime-modulus backbone gives infinitely many exact depths realized by infinitely many hard-class primes.

The Mersenne shadow lattice gives infinitely many depths impossible for every integer.

Therefore the prime Type A/B minimal-depth spectrum and the hard-class infinite-realization spectrum are both

\[
\boxed{\text{infinite and co-infinite}.}
\]

See [SPECTRUM-INFINITE-COINFINITE.md](SPECTRUM-INFINITE-COINFINITE.md).

## Current k<=1500 assault

Workflow run:

```text
run id: 31849103304
k_limit: 1500
search_limit: 3,000,000
```

At this checkpoint:

```text
candidate attack:            SUCCESS
independent verifier:        SUCCESS
coordinate-core mining:      SUCCESS
coarse shadow-kernel stage:  IN PROGRESS
remaining stages:            pending
```

The successful attack and independent verifier already mean the candidatewise search itself did not find a counterexample before depth 1500. **No final numerical counts are promoted here until the complete workflow, CENTL certification, hashes, and artifact upload finish green.**

## Active proof architecture

\[
\boxed{
\begin{array}{c}
C_{AB}\text{ and exact-depth spectrum}\\
\downarrow\\
\text{direct shadow graph / infinite shadow lattices}\\
\downarrow\\
\text{fiber peeling and bounded local selectors}\\
\downarrow\\
\text{scalar character saturation}\\
\downarrow\\
\text{full local quadratic signature}\\
\downarrow\\
\text{deep multiplicative quotient}\\
\downarrow\\
\text{square-lift / higher p-adic core}\\
\downarrow\\
\text{exact divisor-generated residue avoidance}\\
\downarrow\\
\text{universal DSC-P target}
\end{array}
}
\]

## Research rule

Every material theorem, conjecture, computational frontier, counterexample search, workflow result, artifact digest, and change in claim boundary is to be committed to this repository. Chat discussion is exploratory; **the repository is canonical**.
