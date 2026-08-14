# Current research frontier: from shadow completeness to quotient, tower, and dyadic cores

**Date:** 2026-08-14  
**Status:** active theorem program  
**Claim boundary:** Erdős-Straus remains open; universal López Type A/B coverage and universal Direct-Shadow Completeness remain unproved.

This is the short moving-frontier record. The full synthesis remains [DIAMOND.md](DIAMOND.md). The durable checkpoint is [RESEARCH-BACKUP-2026-08-14.md](RESEARCH-BACKUP-2026-08-14.md).

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

## 4. Exact quadratic trap signature and character-shield completeness

For every divisor `e|k`, with `m_k=4k-1`,

\[
\left(\frac{-e}{m_k}\right)
=
\left(\frac{-4e}{m_k}\right)
=-1.
\]

The Type B half of this quadratic-nonresidue property is already present in López 2024 and is not an FCF novelty claim. See [QUADRATIC-PRIOR-ART-NOTE.md](QUADRATIC-PRIOR-ART-NOTE.md).

The new reduction is [CHARACTER-SHIELD-COMPLETENESS.md](CHARACTER-SHIELD-COMPLETENESS.md). Let `W_k` be the squareclass span of earlier moduli, `F_k` the target-fixed prime-coordinate subspace, and `U_k` the span of individually fixed-only earlier rows. Then

\[
\boxed{W_k\cap F_k=U_k.}
\]

Consequently

\[
\boxed{
\text{character shield inconsistent}
\iff
\exists\text{ one fixed-only earlier layer with Jacobi sign }-1.
}
\]

There is no genuinely collective new obstruction at the scalar quadratic-character level.

## 5. Full local quadratic signatures sharpen the shield

Factor

\[
m_k=\prod_{i=1}^r p_i^{a_i}
\]

and retain the complete vector of local Legendre signs. If `H_k` is the span of local signatures of prime divisors of `k`, then

\[
\boxed{
\chi_k(T_k)=\chi_k(-1)+H_k.
}
\]

So all Type A/B traps occupy one affine class in the quotient

\[
Q_k=V_k/H_k.
\]

On the frozen `k<=1200` candidate bundle:

```text
Jacobi character shield solved:        30,414 / 41,470
full quadratic-signature shield:       30,786 / 41,470
rescued beyond Jacobi:                    372
direct quadratic-signature residual:  10,684
```

All

\[
\boxed{1,566,322/1,566,322}
\]

higher-codimension signature constraints encountered were shadowed by one codimension-one signature constraint. An independent implementation reproduced the same finite result.

See [QUADRATIC-SIGNATURE-SHIELD-K1200.md](QUADRATIC-SIGNATURE-SHIELD-K1200.md).

## 6. The multiplicative trap quotient is stronger still

Let

\[
D_k=\langle \ell:\ell\text{ prime},\ \ell\mid k\rangle
\le(\mathbb Z/(4k-1)\mathbb Z)^\times.
\]

Then

\[
\boxed{T_k\subseteq-D_k.}
\]

Hence all Type A/B traps occupy one distinguished class in

\[
\boxed{\Gamma_k=(\mathbb Z/(4k-1)\mathbb Z)^\times/D_k.}
\]

The full local quadratic quotient is only a quotient of this multiplicative object.

The normalized exact trap set inside `D_k` is the image of two exponent boxes:

\[
\boxed{
-T_k
=
\phi_k(\mathcal B_{\mathbf a})
\cup
\phi_k(\mathcal B_{\mathbf a}-\mathbf a).
}
\]

See [MULTIPLICATIVE-TRAP-QUOTIENT.md](MULTIPLICATIVE-TRAP-QUOTIENT.md).

## 7. Character residuals form coherent square-lift towers

For an earlier modulus `m_j=4j-1`, let `sf(m_j)` be its squarefree kernel.

An earlier layer is character-fixed exactly when

\[
\boxed{
\operatorname{sf}(m_j)\mid\operatorname{rad}(L).
}
\]

Thus every such modulus is

\[
\boxed{m_j=a b^2,}
\qquad
a\mid\operatorname{rad}(L),\quad a\equiv3\pmod4.
\]

For a fixed target progression,

\[
\boxed{
\left(\frac r{a b^2}\right)=\left(\frac r a\right),
}
\]

so an entire tower is character-positive or character-negative at once.

Within a tower, `b_1|b_2` gives an exact odd-square modulus ancestry relation:

\[
\boxed{
\frac{m(a,b_2)}{m(a,b_1)}
=\left(\frac{b_2}{b_1}\right)^2.
}
\]

The frozen `k<=1200` replay shows that among the `11,056` Jacobi-character residual candidates, the median number of variable negative towers is `1`, the mean is about `1.110`, and the observed maximum is `10`. These finite counts are proof-mining diagnostics only.

See [SQUARE-LIFT-TOWERS.md](SQUARE-LIFT-TOWERS.md).

## 8. New infinite theorem family: the dyadic trap lattice

For

\[
k=2^a,
\]

the modulus is

\[
m_a=2^{a+2}-1.
\]

The exact theorem is

\[
\boxed{
T_{2^a}=-\langle2\rangle,
\qquad
\operatorname{ord}_{m_a}(2)=a+2.
}
\]

More strongly,

\[
\boxed{
T_k=-D_k
\iff
k\text{ is a power of }2.
}
\]

So powers of two are exactly the Type A/B layers whose exact trap set saturates its entire multiplicative trap coset.

The Mersenne divisibility identity gives

\[
2^{a+2}-1\mid2^{b+2}-1
\iff
a+2\mid b+2.
\]

Whenever this holds with `a<b`, reduction maps the entire later dyadic trap set onto the earlier one:

\[
\boxed{
T_{2^b}\bmod(2^{a+2}-1)=T_{2^a}.
}
\]

This gives an infinite exact family of direct Type A/B shadow relations.

Within the dyadic subsystem, the nodes irredundant with respect to earlier dyadic nodes are exactly

\[
\boxed{2^{q-2}\text{ with }q\text{ prime}.}
\]

See [DYADIC-TRAP-LATTICE.md](DYADIC-TRAP-LATTICE.md). A dedicated GitHub Actions regression checks the theorem family and the finite full-saturation classification automatically.

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

No `k<=1500` numerical result is promoted until the complete workflow finishes green.

## 10. The problem we are actually trying to solve now

The original global covering question has repeatedly collapsed when viewed at the right resolution:

\[
\boxed{
\begin{array}{c}
\text{exact Type A/B pullbacks}\\
\downarrow\\
\text{direct shadow graph}\\
\downarrow\\
\text{fiber peeling}\\
\downarrow\\
\text{small-prime residual kernel}\\
\downarrow\\
\text{Jacobi character saturation}\\
\downarrow\\
\text{full local quadratic signatures}\\
\downarrow\\
\text{multiplicative quotient}\\
\downarrow\\
\text{square-lift towers / two-box core}\\
\downarrow\\
\text{local p-adic exact trap avoidance}
\end{array}
}
\]

The immediate theorem target is:

> Prove that every directly novel Type A/B candidate can escape the remaining multiplicative/tower core by local `p`-adic choices.

That would give universal DSC-P:

\[
\boxed{
\text{not directly shadowed}
\Longrightarrow
\text{reduced avoiding class}
\Longrightarrow
\text{infinitely many exact-depth primes}.
}
\]

If achieved, the direct-shadow graph becomes a complete obstruction theory for Type A/B first-hit realizability.

That is the present edge of the diamond.
