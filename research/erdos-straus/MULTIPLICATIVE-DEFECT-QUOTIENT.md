# Multiplicative reciprocity defect quotient for Type A/B square lifts

**Status:** proved universal theorem and classification  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this theorem is at multiplicative-coset resolution. It does not imply exact residue shadowing, universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture. The group theory, CRT, Dirichlet theorem, and quadratic reciprocity used in the proof are classical; the Type-A/B-specific organization is the research contribution under review.

Read with:

- [MULTIPLICATIVE-TRAP-QUOTIENT.md](MULTIPLICATIVE-TRAP-QUOTIENT.md)
- [RECIPROCITY-DEFECT-QUOTIENT.md](RECIPROCITY-DEFECT-QUOTIENT.md)
- [SQUARE-LIFT-SIGNATURE-CLASSIFICATION.md](SQUARE-LIFT-SIGNATURE-CLASSIFICATION.md)
- [SQUARE-LIFT-RECIPROCITY.md](SQUARE-LIFT-RECIPROCITY.md)
- [QUADRATIC-FIELD-BRIDGE.md](QUADRATIC-FIELD-BRIDGE.md)

## 1. Ancestor multiplicative groups

Let

\[
d=4a-1
\]

be squarefree and put

\[
G_a=(\mathbb Z/d\mathbb Z)^\times.
\]

Let

\[
D_a
=
\langle \ell\bmod d:\ell\mid a,\ \ell\text{ prime}\rangle
\le G_a.
\]

The multiplicative trap theorem gives

\[
T_a\subseteq-D_a.
\]

Every generator of `D_a` has Jacobi symbol `+1` modulo `d`, so

\[
D_a\subseteq K_a,
\]

where

\[
\boxed{
K_a
=
\ker\left(
(\mathbb Z/d\mathbb Z)^\times
\xrightarrow{(\cdot/d)}
\{\pm1\}
\right)
}
\]

is the Jacobi-positive subgroup.

Since `d=3 mod 4`, the Jacobi character is nontrivial and

\[
[G_a:K_a]=2.
\]

## 2. The multiplicative defect quotient

Define

\[
\boxed{
\mathcal M_a
=
K_a/D_a.
}
\]

This is the **multiplicative reciprocity defect quotient** of the ancestor.

Its order is

\[
|\mathcal M_a|
=[K_a:D_a]
=
\frac{[G_a:D_a]}{[G_a:K_a]}
=
\boxed{\frac{\iota(a)}2},
\]

where

\[
\iota(a)=[G_a:D_a]
\]

is the multiplicative trap index.

Using the quotient factorization

\[
\iota(a)=2^{\kappa(a)}\Theta(a),
\]

we obtain

\[
\boxed{
|\mathcal M_a|
=2^{\kappa(a)-1}\Theta(a).
}
\]

Thus `M_a` contains both:

1. the quadratic reciprocity-defect information of dimension `kappa(a)-1`;
2. all higher-order multiplicative information measured by `Theta(a)`.

## 3. Square-lift prime defects

For positive odd `s`, define

\[
j_s=\frac{1+d s^2}{4},
\qquad
4j_s-1=d s^2.
\]

Square-lift reciprocity proves that every prime

\[
q\mid j_s
\]

satisfies

\[
\left(\frac qd\right)=+1.
\]

Therefore

\[
q\bmod d\in K_a
\]

and has a well-defined multiplicative defect class

\[
\boxed{
\delta_a^{\rm mult}(q)
=[q]\in\mathcal M_a.
}
\]

The class is trivial exactly when

\[
q\bmod d\in D_a.
\]

## 4. Full multiplicative conservation law

Factor

\[
j_s=\prod_q q^{e_q}.
\]

Because

\[
4j_s=1+d s^2,
\]

we have

\[
j_s\equiv4^{-1}\pmod d.
\]

But

\[
4\in D_a
\]

because `4a=1 mod d` and `a in D_a`. Hence

\[
[4^{-1}]=1
\quad\text{in }\mathcal M_a.
\]

Therefore

\[
[j_s]=1
\quad\text{in }\mathcal M_a.
\]

By multiplicativity:

### Theorem

Every square lift satisfies the exact finite-abelian conservation law

\[
\boxed{
\prod_{q\mid j_s}
\left(\delta_a^{\rm mult}(q)\right)^{e_q}
=1
\quad\text{in }\mathcal M_a.
}
\]

Unlike the earlier `F_2` conservation law, the exponents are retained in the full finite abelian group. Odd-order information is not discarded.

## 5. Multiplicative signature defect of a lift

Define

\[
D_{j_s\to a}
=
\langle q\bmod d:q\mid j_s\rangle
\le K_a.
\]

Its image in the defect quotient is

\[
\boxed{
\Delta^{\rm mult}_{j_s\to a}
=
D_{j_s\to a}D_a/D_a
\le\mathcal M_a.
}
\]

Equivalently,

\[
\Delta^{\rm mult}_{j_s\to a}
=
\langle\delta_a^{\rm mult}(q):q\mid j_s\rangle.
\]

The projected Type A/B trap set of the lift lies in

\[
-D_{j_s\to a},
\]

while the ancestor trap lies in

\[
-D_a.
\]

Thus the lift is ancestor-shadowed at **multiplicative-coset resolution** exactly when

\[
\boxed{
\Delta^{\rm mult}_{j_s\to a}=1.
}
\]

This is stronger than quadratic-signature shadowing.

## 6. Universal multiplicative-shadow classification

### Theorem

The following are equivalent:

1. \(\iota(a)=2\);
2. \(D_a=K_a\);
3. \(\mathcal M_a=1\);
4. every positive odd square lift has
   \[
   \Delta^{\rm mult}_{j_s\to a}=1;
   \]
5. every positive odd square lift is ancestor-shadowed at multiplicative-coset resolution.

### Proof

The equivalence of `1`, `2`, and `3` follows from

\[
[G_a:K_a]=2
\]

and

\[
D_a\subseteq K_a.
\]

If `D_a=K_a`, square-lift reciprocity puts every prime divisor of every lift in `K_a=D_a`, proving `4` and `5`.

Conversely, if every lift is multiplicatively shadowed then no nontrivial class in `K_a/D_a` can ever be represented by a lift prime. Section 7 proves that every class of `K_a/D_a` is represented by infinitely many such primes, so the quotient must be trivial. QED.

Therefore

\[
\boxed{
\iota(a)=2
\iff
\text{universal square-lift multiplicative shadowing}.
}
\]

## 7. Every multiplicative defect class is realized infinitely often

Assume

\[
\mathcal M_a\ne1.
\]

Let

\[
C\in\mathcal M_a
\]

be any class, nontrivial or trivial. Choose a unit residue

\[
r\in K_a
\]

representing `C`.

Use CRT to choose a reduced residue class `R mod 4d` satisfying

\[
R\equiv1\pmod4,
\qquad
R\equiv r\pmod d.
\]

Dirichlet's theorem gives infinitely many primes

\[
q\equiv R\pmod{4d}.
\]

For each such prime,

\[
[q]=C\in\mathcal M_a.
\]

Because `q=1 mod 4`, quadratic reciprocity gives

\[
\left(\frac{-d}{q}\right)
=
\left(\frac qd\right)
=+1,
\]

since `r in K_a`.

Therefore the congruence

\[
d s^2\equiv-1\pmod q
\]

has a solution. Choose one odd solution `s_0`, and then every

\[
\boxed{
s=s_0+2q n,
\qquad n\ge0,
}
\]

is positive odd and satisfies the same congruence.

Hence

\[
q\mid j_s
\]

for infinitely many distinct square lifts, and all such lifts contain the prescribed multiplicative defect class `C`.

Thus:

### Realization theorem

\[
\boxed{
\text{Every class of }\mathcal M_a
\text{ is represented by infinitely many split primes}\
\text{and occurs in infinitely many square-lift depths.}
}
\]

In particular, if

\[
\iota(a)>2,
\]

then infinitely many square lifts fail ancestor shadowing at multiplicative-coset resolution.

## 8. Relation to the quadratic defect quotient

The local quadratic-sign map induces a natural surjection

\[
\boxed{
\mathcal M_a
\twoheadrightarrow
\mathcal R_a,
}
\]

where

\[
\mathcal R_a
=
\ker J_d/V_a
\]

is the earlier `F_2` reciprocity defect quotient.

Its kernel contains precisely the defect information invisible to all local Legendre symbols.

Numerically,

\[
|\mathcal R_a|=2^{\kappa(a)-1},
\]

while

\[
|\mathcal M_a|
=2^{\kappa(a)-1}\Theta(a).
\]

Therefore the kernel has order

\[
\boxed{\Theta(a).}
\]

So the previously defined deep multiplicative factor `Theta(a)` is exactly the amount of square-lift defect information discarded by the complete local quadratic-signature system.

## 9. Ray-class interpretation

Let

\[
K=\mathbb Q(\sqrt{-d})
\]

and use the finite modulus

\[
d\mathcal O_K.
\]

For an ideal `A` coprime to `d`, its absolute ideal norm gives a unit modulo `d`:

\[
N(A)\bmod d\in(\mathbb Z/d\mathbb Z)^\times.
\]

If a principal ideal is generated by

\[
\beta\equiv1\pmod{d\mathcal O_K},
\]

then

\[
N(\beta)\equiv1\pmod d.
\]

Hence the norm-residue map factors through the ray class group modulo `d\mathcal O_K`.

For the canonical selected prime ideals

\[
\mathfrak p_{q,s}\mid(\alpha_s),
\qquad
N\mathfrak p_{q,s}=q,
\]

the ray norm-residue is exactly

\[
q\bmod d.
\]

Composing the ray norm-residue map with

\[
G_a\to\Gamma_a=G_a/D_a
\]

produces precisely the multiplicative defect classes above.

Thus `M_a` is the concrete residue quotient seen by the norm map from the square-lift ray-class configuration. This does **not** identify `M_a` with the full ray class group; it identifies it as a canonical quotient of ray norm-residue data.

## 10. Why this sharpens the proof search

The hierarchy is now exact:

\[
\boxed{
\begin{array}{c}
\text{principal norm identity}\\
\downarrow\\
\text{ray norm-residue classes}\\
\downarrow\\
\mathcal M_a=K_a/D_a\\
\downarrow\\
\mathcal R_a\text{ (quadratic quotient)}\\
\downarrow\\
\text{Jacobi bit}
\end{array}
}
\]

Every square-lift prime-factor configuration obeys a conservation law already in the full finite abelian group `M_a`, before any reduction to quadratic characters.

This is a stronger constraint than the binary reciprocity-defect law and is a natural candidate mechanism for the strong overlap observed in the exact Type A/B covering systems.

## 11. Next theorem target

For an ancestor with

\[
\iota(a)>2,
\]

classify the finite zero-product configurations

\[
\prod C_i^{e_i}=1
\quad(C_i\in\mathcal M_a)
\]

that can arise from square-lift prime factors, and determine how those configurations constrain the exact two-box trap image.

The especially important case is when `M_a` is cyclic or has small Davenport constant. Zero-sum/zero-product theory in finite abelian groups may then force short cancelling subconfigurations that correspond to intermediate divisor depths or exact shadow ancestors.

That is now a concrete bridge from the multiplicative defect quotient back to Direct-Shadow Completeness.
