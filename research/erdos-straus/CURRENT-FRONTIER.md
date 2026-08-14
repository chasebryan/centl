# Current research frontier: from shadow completeness to quotient and square-lift cores

**Date:** 2026-08-14  
**Status:** active theorem program  
**Claim boundary:** Erdős-Straus remains open; universal López Type A/B coverage and universal Direct-Shadow Completeness remain unproved.

This is the short moving-frontier record. The full synthesis remains [DIAMOND.md](DIAMOND.md).

## 1. Exact candidatewise frontier

The completed candidatewise Direct-Shadow attack through `k<=1200` remains the latest fully frozen all-stage certificate result:

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

Every one of the `41,470` directly novel hard-compatible candidates therefore has an explicit reduced avoiding progression and hence an infinite exact-depth prime family by Dirichlet.

See [DIRECT-SHADOW-K1200.md](DIRECT-SHADOW-K1200.md).

This is an exact finite theorem-certificate statement, not universal DSC-P.

## 2. Stronger independent construction on the same k<=1200 bundle

A full replay of the frozen candidate bundle through the newer exact fiber-peeling theorem gives:

\[
\boxed{26,044/41,470}
\]

candidates whose entire residual coordinate system peels away constructively.

The remaining

\[
\boxed{15,426}
\]

nonempty residual kernels are all solved by the fixed selector menu

\[
\boxed{\{0,\pm1,\ldots,\pm64\}}.
\]

Thus

\[
\boxed{41,470/41,470}
\]

are independently resolved by

\[
\boxed{
\text{fiber peeling}
+
\text{bounded residual selector}
}
\]

without using the stored sequential witness to decide either step.

The largest selector radius actually needed was

\[
\boxed{54}.
\]

Every nonempty residual fiber kernel in this finite replay used primes at most `23`.

See [FIBER-SELECTOR-K1200.md](FIBER-SELECTOR-K1200.md).

## 3. Exact fiber-peeling theorem

For a pulled-back earlier constraint with

\[
q_j=p^{a_{j,p}}c,
\qquad (p,c)=1,
\]

let `f_{j,p}` be the maximum width of a forbidden `p^{a_{j,p}}` fiber after the other coordinates are fixed.

Define

\[
\Lambda_p
=
\sum_{p\mid q_j}
\frac{f_{j,p}}{p^{a_{j,p}}}.
\]

If the augmented reducedness load satisfies

\[
\boxed{\Lambda_p^{*}<1,}
\]

then the entire `p` coordinate is peelable while preserving a reduced solution.

See [FIBER-SHADOW-KERNEL.md](FIBER-SHADOW-KERNEL.md).

This turns a global covering problem into an iterated local elimination problem.

## 4. Exact quadratic trap signature

For every divisor `e|k`, with `m_k=4k-1`,

\[
\boxed{
\left(\frac{-e}{m_k}\right)
=
\left(\frac{-4e}{m_k}\right)
=-1.
}
\]

Thus every Type A/B trap lies on the Jacobi-negative side.

The resulting character shield converts simultaneous trap avoidance into an `F_2` sign problem. See [QUADRATIC-TRAP-SIGNATURE.md](QUADRATIC-TRAP-SIGNATURE.md).

## 5. Proved character-shield obstruction completeness

The global `F_2` character system has now been reduced exactly.

Let `W_k` be the squareclass span of all earlier moduli and `F_k` the coordinate subspace supported on primes fixed by the target progression. Let `U_k` be the span of earlier rows that are individually fixed-only.

Then

\[
\boxed{W_k\cap F_k=U_k.}
\]

Consequently the simultaneous Jacobi `+1` shield is inconsistent **if and only if** one earlier fixed-only layer is already Jacobi-negative by itself.

There is no genuinely collective new obstruction at the scalar quadratic-character level.

See [CHARACTER-SHIELD-COMPLETENESS.md](CHARACTER-SHIELD-COMPLETENESS.md).

## 6. New multiplicative trap-coset theorem

For

\[
m_k=4k-1,
\qquad
G_k=(\mathbb Z/m_k\mathbb Z)^\times,
\]

define

\[
H_k=\langle\ell\bmod m_k:\ell\text{ prime},\ \ell\mid k\rangle.
\]

Then

\[
\boxed{T_k\subseteq-H_k}
\]

and

\[
\boxed{-1\notin H_k.}
\]

So the entire Type A/B trap set lies inside one proper multiplicative coset.

Define the index

\[
\iota(k)=[G_k:H_k].
\]

The Jacobi `-1` theorem is only one order-two quotient of this richer structure. Finite exact enumeration through `k<=1200` found indices as large as `210`.

See [MULTIPLICATIVE-TRAP-COSET.md](MULTIPLICATIVE-TRAP-COSET.md) and [`trap_coset_analyzer.py`](trap_coset_analyzer.py).

## 7. New full local quadratic-signature theorem

Factor

\[
m_k=\prod_{i=1}^r p_i^{a_i}
\]

and record the complete vector of Legendre signs at the distinct primes `p_i`.

If `V_k` is the `F_2` span of the local signatures of the prime divisors of `k`, and `eta_k` is the signature of `-1`, then the **exact set of trap signatures** is

\[
\boxed{
\lambda_{m_k}(T_k)=\eta_k+V_k.
}
\]

Thus Type A/B traps occupy one affine subspace of the full local quadratic-signature space. The scalar Jacobi theorem is only one projection of this vector statement.

A proof-mining replay of the frozen `k<=1200` bundle found:

```text
full local quadratic-signature shield solved: 30,786
direct signature residual:                    10,684
collective linear inconsistency:                   0
unresolved non-direct signature systems:           0
```

This finite pattern is not yet promoted to a universal signature-level completeness theorem.

See [QUADRATIC-SIGNATURE-COSET.md](QUADRATIC-SIGNATURE-COSET.md) and [`quadratic_signature_shield_analyzer.py`](quadratic_signature_shield_analyzer.py).

## 8. New square-lift core

If an earlier row is fixed at the squareclass level, then every prime outside the target modulus occurs in that earlier modulus with even exponent.

Equivalently, for a character-fixed earlier row,

\[
\boxed{
p\nmid L\Longrightarrow v_p(m_j)\equiv0\pmod2.}
\]

The same holds in the pulled-back modulus `q_j`.

Therefore after the quadratic signs have been exhausted, any genuinely new prime coordinate enters the remaining obstruction only through a square power:

\[
\boxed{
q_j=c_j s_j^2,
}
\]

where the prime support of `c_j` lies inside the fixed target modulus and `(s_j,L)=1`.

The unresolved problem is therefore becoming a **higher p-adic lifting problem**, not another free quadratic-sign problem.

See [SQUARE-LIFT-CORE.md](SQUARE-LIFT-CORE.md) and [`square_lift_core_analyzer.py`](square_lift_core_analyzer.py).

## 9. Current automated assault

GitHub Actions run `31849103304` is currently attacking

\[
\boxed{k\le1500}
\]

with sequential witness search through

\[
\boxed{s\le3,000,000}.
\]

It includes independent verification, coordinate proof mining, coarse and fiber peeling, bounded residual selectors, the quadratic shield, CENTL certification, hashes, and artifact publication.

At the latest check the main candidatewise attack stage was still running. **No `k<=1500` numerical result is being promoted until the complete workflow finishes green.**

## 10. The problem we are actually trying to solve now

The original global question

> can hundreds of earlier Type A/B congruence restrictions collectively cover a directly novel candidate?

has been compressed into a hierarchy:

\[
\boxed{
\begin{array}{c}
\text{exact Type A/B pullbacks}\\
\downarrow\\
\text{fiber peeling}\\
\downarrow\\
\text{small-prime residual kernel}\\
\downarrow\\
\text{Jacobi character saturation}\\
\downarrow\\
\text{full local quadratic signatures}\\
\downarrow\\
\text{multiplicative coset quotient}\\
\downarrow\\
\text{square-lift / higher p-adic core}\\
\downarrow\\
\text{exact divisor-generated residue avoidance}
\end{array}
}
\]

The immediate theorem targets are now:

1. prove or refute signature-level Direct-Shadow Completeness;
2. prove a bounded small-prime fiber-kernel theorem;
3. classify the fixed-negative square-lift cores;
4. prove a local `p`-adic escape theorem for those cores;
5. combine the local mechanisms into universal DSC-P.

A successful universal DSC-P theorem would make the direct-shadow graph a complete obstruction theory for exact Type A/B first-hit realizability.

That is the present edge of the diamond.
