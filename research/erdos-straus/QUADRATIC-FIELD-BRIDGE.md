# Quadratic-field bridge for the square-lift core

**Status:** exact theorem note plus prior-art boundary  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** norm forms, splitting of primes in quadratic fields, genus characters, class groups, and Rédei matrices are classical. This note does not claim those objects as new. Its purpose is to identify the classical arithmetic underneath the Type A/B square-lift/defect machinery and to state exactly what remains specific to the present minimal-depth/shadow program.

Read with:

- [SQUARE-LIFT-RECIPROCITY.md](SQUARE-LIFT-RECIPROCITY.md)
- [RECIPROCITY-DEFECT-QUOTIENT.md](RECIPROCITY-DEFECT-QUOTIENT.md)
- [RECIPROCITY-MATRIX.md](RECIPROCITY-MATRIX.md)
- [SQUAREFREE-LIFT-CORE.md](SQUAREFREE-LIFT-CORE.md)
- [PRIOR-ART.md](PRIOR-ART.md)

## 1. The square-lift depth is a quadratic norm

Let

\[
d=4a-1
\]

be squarefree and let `s` be positive odd. Put

\[
\boxed{
j=\frac{1+d s^2}{4}.}
\]

Because `d=3 mod 4`, the imaginary quadratic field

\[
K_d=\mathbb Q(\sqrt{-d})
\]

has ring of integers

\[
\mathcal O_d
=\mathbb Z\left[\frac{1+\sqrt{-d}}2\right].
\]

Define

\[
\boxed{
\alpha_s=\frac{1+s\sqrt{-d}}2\in\mathcal O_d.
}
\]

Then

\[
\boxed{
N_{K_d/\mathbb Q}(\alpha_s)
=\frac{1+d s^2}{4}
=j.
}
\]

Thus every square-lift depth is the norm of one distinguished algebraic integer.

The ancestor depth is the special case

\[
a=N(\alpha_1).
\]

## 2. Every rational prime dividing j splits

### Theorem

Every rational prime `ell|j` splits in `K_d`.

For odd `ell`, equivalently,

\[
\boxed{
\left(\frac{-d}{\ell}\right)=+1.
}
\]

If `2|j`, then `2` also splits in `K_d`.

### Proof for odd ell

From

\[
4j=1+d s^2
\]

and `ell|j`, we have

\[
d s^2\equiv-1\pmod\ell.
\]

Also `gcd(ell,s)=1`, because any common divisor of `j` and `s` would divide `1` in the displayed identity. Hence

\[
-d\equiv s^{-2}\pmod\ell,
\]

so `-d` is a nonzero square modulo `ell`. Therefore `ell` splits in the quadratic field.

### The prime 2

If `2|j`, then

\[
1+d s^2\equiv0\pmod8.
\]

Every odd square is `1 mod 8`, so

\[
d\equiv7\pmod8.
\]

The fundamental discriminant is `-d`, hence

\[
-d\equiv1\pmod8,
\]

which is exactly the split case for `2` in the quadratic field. QED.

This is the field-theoretic form of the reciprocity statement proved earlier for the divisor primes of a square lift.

## 3. A canonical prime above every divisor prime

Because

\[
N(\alpha_s)=j,
\]

every rational prime `ell|j` divides the principal ideal `(alpha_s)`.

Since `ell` splits, write

\[
(\ell)=\mathfrak p_{\ell,s}\,\overline{\mathfrak p}_{\ell,s}.
\]

Exactly one of the two primes above `ell` divides `(alpha_s)`.

Indeed, if both divided `(alpha_s)`, then `(ell)` would divide `(alpha_s)`, so `alpha_s in ell O_d`. Taking traces would imply

\[
\ell\mid\operatorname{Tr}(\alpha_s)=1,
\]

impossible.

Thus the element `alpha_s` canonically selects one prime ideal above every rational prime factor of `j`.

For odd `ell`, one may describe this selected prime using the square root

\[
\sqrt{-d}\equiv-s^{-1}\pmod\ell
\]

forced by `alpha_s`.

## 4. Ideal-factorization conservation law

Factor

\[
j=\prod_{\ell\mid j}\ell^{e_\ell}.
\]

The selected split primes satisfy

\[
\boxed{
(\alpha_s)
=
\prod_{\ell\mid j}
\mathfrak p_{\ell,s}^{e_\ell}.
}
\]

Both sides have norm `j`, and the preceding section shows which prime above each split rational prime can occur.

Passing to the ideal class group gives the exact conservation law

\[
\boxed{
\sum_{\ell\mid j}
e_\ell[\mathfrak p_{\ell,s}]
=0
\quad\text{in }\operatorname{Cl}(K_d).
}
\]

This is strictly stronger in principle than the binary defect-conservation law, which retains only selected quadratic-character information.

The earlier relation

\[
\sum_\ell(e_\ell\bmod2)\delta_a(\ell)=0
\]

should therefore be viewed as a coarse quadratic-character shadow of the principal-ideal identity above.

## 5. Why genus theory is relevant

For a quadratic field, genus characters are the order-two characters of the ideal class group. Their values on split prime ideals are described by quadratic residue symbols associated with the prime discriminants dividing the field discriminant.

Our local vectors

\[
\lambda_d(\ell)
=
\left(\left(\frac\ell p\right)\right)_{p\mid d}
\]

therefore live in the same classical quadratic-character ecosystem as genus theory.

This is a warning and an opportunity:

- the use of Legendre-symbol vectors and `F_2` linear algebra is not by itself a novelty claim;
- the extra null directions beyond Jacobi may have a genus-theoretic interpretation;
- classical Rédei matrices also package quadratic residue symbols into binary matrices and use their rank to study higher `2`-primary class-group structure;
- our rectangular `A_k`, however, has different row and column sets: rows come from primes dividing `4k-1`, while columns come from primes dividing `k`.

Therefore the Type A/B reciprocity matrix must **not** be called a Rédei matrix without a proved equivalence. The responsible current statement is that there is a strong structural analogy and a likely genus-theoretic bridge that requires formal identification.

## 6. Classical Rédei warning

Classical Rédei matrices are built from quadratic symbols between prime discriminant factors of a quadratic-field discriminant. Their rank controls the `4`-rank of quadratic ideal class groups.

The Type A/B reciprocity matrix

\[
A_k=
\left(
\left(\frac{\ell_j}{p_i}\right)
\right)
\]

is generally rectangular and mixes two arithmetically linked factorizations:

\[
k=\prod\ell_j^{\beta_j},
\qquad
4k-1=\prod p_i^{\alpha_i}.
\]

Its canonical null vectors arise from

\[
4k\equiv1
\]

and the López divisor-Jacobi relation.

The correct research question is therefore:

> Can `A_k`, or the square-lift defect quotient derived from it, be identified with a natural restriction, presentation, or evaluation map in the genus/class-group theory of `Q(sqrt(-(4a-1)))`?

Until that is proved, the connection remains a bridge, not an identification.

## 7. The next level beyond genus characters

The exact Type A/B trap sets depend on actual residues

\[
-e,
\qquad
-4e
\pmod d,
\]

not merely on their quadratic characters.

So even complete genus-character information cannot recover the exact projection excess

\[
E_j=(T_j\bmod d)\setminus T_a.
\]

A likely hierarchy is

\[
\boxed{
\text{principal norm identity}
\to
\text{ideal-class conservation}
\to
\text{genus / quadratic characters}
\to
\text{reciprocity defect quotient}
\to
\text{multiplicative residue quotient}
\to
\text{exact Type A/B divisor residues}.
}
\]

The exact-residue end may naturally involve ray class information rather than only the ordinary ideal class group, because congruence modulo the ancestor modulus is finer than ideal-class equivalence.

This is now a serious theory target.

## 8. Why this may be the hidden mechanism

The computational phenomenon we are trying to explain is that hundreds of earlier modular constraints overlap so strongly that directly novel candidates repeatedly retain reduced escape progressions.

The norm-form viewpoint says the square-lift part of the system is not a generic collection of congruences. The factor primes of each lifted depth are forced to:

1. split in one fixed imaginary quadratic field;
2. choose prime ideals whose weighted product is principal;
3. satisfy every genus-character conservation law induced by that principal identity;
4. satisfy the finer Type A/B residue relations inherited from the same norm equation.

That is a much more rigid arithmetic source than a random covering system.

## 9. Immediate theorem targets

1. identify the precise genus-theoretic meaning of `V_a` and `R_a`;
2. determine whether `dim R_a` is expressible through a classical class-group invariant plus the subgroup generated by the prime ideals selected by `alpha_1`;
3. compare `A_a` rigorously with the classical Rédei matrix of discriminant `-d`;
4. lift the binary defect conservation law from genus characters to the full ideal class group using the principal factorization of `(alpha_s)`;
5. determine what ray-class quotient encodes the exact residue projection `T_j mod d`;
6. test whether direct shadowing corresponds to triviality in that ray-class quotient.

The fifth and sixth questions could connect the exact shadow graph to standard algebraic number theory rather than leaving it as a bespoke congruence phenomenon.

## 10. Prior-art boundary

The following are classical and are not FCF novelty claims:

- representation by quadratic norm forms;
- splitting criteria using Kronecker/Legendre symbols;
- ideal class groups and principal ideal relations;
- genus characters;
- Rédei matrices and their use in quadratic class-group `4`-rank questions.

The candidate contribution remains the Type-A/B-specific **minimal-depth, shadow, survivor, square-lift, projection-excess and exact-residue architecture**, together with any new theorem proved about how those objects interact.
