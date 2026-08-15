# Squarefree-lift localization of the Type A/B character residual

**Status:** proved theorem family plus finite replay target  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this note does not prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture. It refines the residual left by the character-shield theorems.

Read with:

- [CHARACTER-SHIELD-COMPLETENESS.md](CHARACTER-SHIELD-COMPLETENESS.md)
- [QUADRATIC-TRAP-SIGNATURE.md](QUADRATIC-TRAP-SIGNATURE.md)
- [QUADRATIC-SIGNATURE-SHIELD-K1200.md](QUADRATIC-SIGNATURE-SHIELD-K1200.md)
- [DIRECT-SHADOW-COMPLETENESS.md](DIRECT-SHADOW-COMPLETENESS.md)
- [THEORY.md](THEORY.md)

## 1. Squarefree ancestor

For an earlier layer `j`, write

\[
m_j=4j-1.
\]

Let

\[
d_j=\operatorname{sf}(m_j)
=\prod_{v_p(m_j)\text{ odd}}p
\]

be the squarefree kernel of `m_j`. Then there is a unique odd integer `s_j>=1` with

\[
\boxed{m_j=d_j s_j^2.}
\]

Because every odd square is `1 mod 4` and `m_j=3 mod 4`,

\[
d_j\equiv3\pmod4.
\]

Hence

\[
\boxed{a_j=\frac{d_j+1}{4}}
\]

is a positive integer and

\[
\boxed{d_j=4a_j-1=m_{a_j}.}
\]

We call `a_j` the **squarefree ancestor depth** of `j`.

Moreover `a_j<=j`, with equality exactly when `m_j` is squarefree.

## 2. Squarefree character reduction

### Theorem

For every integer `x` coprime to `m_j`,

\[
\boxed{
\left(\frac{x}{m_j}\right)
=
\left(\frac{x}{d_j}\right).
}
\]

### Proof

Write

\[
m_j=\prod_p p^{e_p}.
\]

The Jacobi symbol is

\[
\left(\frac{x}{m_j}\right)
=
\prod_p\left(\frac{x}{p}\right)^{e_p}.
\]

Every even exponent contributes `1`; the odd exponents are exactly the primes occurring in `d_j`. QED.

Thus the scalar quadratic character of a layer depends only on its squarefree ancestor modulus.

## 3. Fixed-negative layers are square-lifts

Fix a target candidate `(k,h,t)` and write

\[
x\equiv r\pmod L,
\qquad
L=\operatorname{lcm}(840,m_k).
\]

An earlier layer `j<k` is **character-fixed** when every prime occurring to odd exponent in `m_j` divides `L`. Equivalently,

\[
\boxed{d_j\mid L.}
\]

For such a layer, the candidate progression fixes `x mod d_j`, and the previous theorem gives

\[
\boxed{
\left(\frac{x}{m_j}\right)
=
\left(\frac{r}{d_j}\right)
}
\]

for every reduced member of the progression.

Therefore every immutable Jacobi-negative layer in the character residual is literally a square-lift over a smaller fixed modulus `d_j=m_{a_j}`.

## 4. Direct novelty at the ancestor

Suppose the target candidate is directly novel.

If `d_j|L`, then the earlier ancestor modulus `m_{a_j}=d_j` divides the target progression modulus. Therefore the residue modulo `d_j` is fixed to `r mod d_j`.

Direct novelty implies

\[
\boxed{
r\bmod d_j\notin T_{a_j}.}
\]

Otherwise the ancestor layer `a_j` itself would directly shadow the target candidate.

Hence every fixed-negative layer of a directly novel candidate sits over a residue satisfying

\[
\boxed{
\left(\frac r{d_j}\right)=-1,
\qquad
r\bmod d_j\notin T_{a_j}.
}
\]

In words: the character residual is built from **nontrap quadratic nonresidues at squarefree ancestor layers**.

## 5. Projection excess

The exact trap set at the lifted layer can be projected to the ancestor modulus:

\[
\pi_j(T_j)=T_j\bmod d_j.
\]

Define the **squarefree projection excess**

\[
\boxed{
E_j
=
\pi_j(T_j)\setminus T_{a_j}.
}
\]

### Projection-excess theorem

Let a directly novel target candidate have `d_j|L`. If

\[
r\bmod d_j\notin E_j,
\]

then the candidate progression is automatically safe from the entire exact layer `j`.

### Proof

Because the candidate is directly novel,

\[
r\bmod d_j\notin T_{a_j}.
\]

If also `r mod d_j` is not in `E_j`, then

\[
r\bmod d_j\notin T_j\bmod d_j.
\]

Every member of the candidate progression has the same residue `r mod d_j`. Therefore no member can lie in `T_j mod m_j`, since any such hit would project into `T_j mod d_j`. QED.

### Corollary

If

\[
\boxed{E_j=\varnothing,}
\]

then every directly novel candidate for which `d_j|L` automatically avoids layer `j` exactly.

Equivalently,

\[
T_j\bmod d_j\subseteq T_{a_j}
\]

makes the lifted layer redundant over every directly novel progression that fixes its ancestor modulus.

This is an exact shadow theorem along the squarefree-lift ancestry

\[
\boxed{m_j=s_j^2m_{a_j}.}
\]

## 6. Why this matters

[CHARACTER-SHIELD-COMPLETENESS.md](CHARACTER-SHIELD-COMPLETENESS.md) proves that scalar-character inconsistency comes only from immutable negative earlier layers.

The present theorem shows that most of those immutable negative layers may still be removed **exactly**, without solving any global covering problem, by checking only whether their fixed ancestor residue lies in the projection excess `E_j`.

The hierarchy is now

\[
\boxed{
\text{character shield}
\to
\text{fixed-negative square-lifts}
\to
\text{projection excess }E_j
\to
\text{genuinely active exact lift core}.
}
\]

The object `E_j` is therefore a sharper target than the entire Jacobi-negative half of the unit group.

## 7. Finite k <= 1200 replay signal

A replay against the frozen `41,470` directly novel candidates through `k<=1200` gives the following proof-mining statistics:

```text
layers through 1200:                         1,200
non-squarefree moduli m_j:                    224
layers with nonempty projection excess E_j:   115
layers with empty projection excess:         1,085
```

Among the `41,470` directly novel candidates:

```text
character-shield inconsistent candidates:    11,056
of those, no fixed-negative layer remains
active after the exact projection-excess test: 7,608
candidates with >=1 active excess layer:       3,448
maximum active excess layers in one candidate:    10
```

Across all candidates, `38,022/41,470` have zero active squarefree projection-excess layers.

These numbers do **not** mean all `38,022` candidates are independently solved by this theorem alone. Collective character equations among non-fixed layers can still require additional choices. The result is a localization statement: the immutable exact-residue part of the character residual collapses to a much smaller family of projection-excess lifts.

The largest observed excess size through `k<=1200` is `22`, at

```text
j = 700
m_j = 2799
squarefree ancestor modulus d_j = 311
ancestor depth a_j = 78
```

## 8. Immediate theorem target

The next target is to classify exactly when

\[
\boxed{E_j=\varnothing.}
\]

Because

\[
m_j=s_j^2m_{a_j},
\]

this asks for a divisor-theoretic criterion under which

\[
T_j\bmod m_{a_j}\subseteq T_{a_j}.
\]

A successful classification would produce an infinite family of exact square-lift shadow relations and isolate the exceptional lifts where new residue information is genuinely created.

A second target is to combine the projection-excess core with the full local quadratic-signature quotient. The likely proof architecture is

\[
\boxed{
\text{direct novelty}
\to
\text{signature shield}
\to
\text{squarefree projection excess}
\to
\text{fiber kernel}
\to
\text{tiny exact residual}.
}
\]

## 9. Novelty boundary

Squarefree kernels and the identity of Jacobi symbols under deletion of even prime exponents are classical. The candidate contribution is their use as an exact **squarefree-lift localization and projection-excess reduction inside the Type A/B minimal-depth/shadow framework**.

Publication priority remains subject to broader literature review and independent mathematical scrutiny.
