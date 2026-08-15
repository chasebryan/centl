# Mixed-box obstruction in exact square-lift shadowing

**Status:** exact reformulation plus falsified simplification and finite proof-mining data  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this note does not prove universal Direct-Shadow Completeness or exact square-lift shadowing. It identifies the exact combinatorial object left after multiplicative/genus reductions and records a counterexample to a tempting but false generator-wise simplification.

Read with:

- [MULTIPLICATIVE-TRAP-QUOTIENT.md](MULTIPLICATIVE-TRAP-QUOTIENT.md)
- [SQUAREFREE-LIFT-CORE.md](SQUAREFREE-LIFT-CORE.md)
- [SQUARE-LIFT-SIGNATURE-CLASSIFICATION.md](SQUARE-LIFT-SIGNATURE-CLASSIFICATION.md)
- [GENUS-DEFECT-IDENTIFICATION.md](GENUS-DEFECT-IDENTIFICATION.md)

## 1. Normalize the trap set

For a depth `k`, write

\[
m_k=4k-1
\]

and define the normalized positive trap set

\[
\boxed{
U_k=-T_k
=
\{e,4e\pmod{m_k}:e\mid k\}.
}
\]

Let

\[
D_k=\{e\pmod{m_k}:e\mid k\}
\]

be the divisor-residue set.

Because

\[
4k\equiv1\pmod{m_k},
\]

for `e|k` and `f=k/e` we have

\[
4e\equiv f^{-1}\pmod{m_k}.
\]

As `e` ranges over divisors, so does `f`. Therefore:

### Theorem

\[
\boxed{
U_k=D_k\cup D_k^{-1}.
}
\]

This is the exact two-box/inverse formulation of a Type A/B trap layer.

The inversion relationship itself is consistent with López's prior observation that the two Type A/B divisor families are mutual inverses; the present use is to organize exact square-lift projection shadowing.

## 2. Square-lift projection criterion

Let

\[
d=4a-1
\]

be squarefree and let

\[
4j-1=d s^2.
\]

Project the lifted traps modulo the ancestor modulus `d`.

Define

\[
D_{j\to d}
=\{e\bmod d:e\mid j\}.
\]

Since also

\[
4j\equiv1\pmod d,
\]

the same divisor/inverse argument gives

\[
\boxed{
-T_j\bmod d
=
D_{j\to d}\cup D_{j\to d}^{-1}.
}
\]

The ancestor normalized trap is

\[
U_a=D_a\cup D_a^{-1}.
\]

Since `U_a` is inversion-stable, we obtain:

### Exact projection-shadow criterion

\[
\boxed{
T_j\bmod d\subseteq T_a
\iff
D_{j\to d}\subseteq U_a.
}
\]

Thus exact square-lift projection shadowing is a problem about where **all divisor residues of `j`** land relative to one ancestor two-box set.

## 3. Exponent-box formulation

Factor

\[
a=\prod_{i=1}^r p_i^{A_i}.
\]

Let

\[
H_a=\langle p_1,\ldots,p_r\rangle
\le(\mathbb Z/d\mathbb Z)^\times
\]

and define

\[
\phi_a:\mathbb Z^r\to H_a,
\qquad
(x_1,\ldots,x_r)
\mapsto
\prod_i p_i^{x_i}\pmod d.
\]

Let

\[
B_A=\{x\in\mathbb Z^r:0\le x_i\le A_i\}.
\]

Then

\[
D_a=\phi_a(B_A)
\]

and

\[
D_a^{-1}=\phi_a(-B_A).
\]

Hence

\[
\boxed{
U_a=\phi_a(B_A\cup-B_A).
}
\]

This is the ancestor's exact **signed exponent box**.

Now factor

\[
j=\prod_{q\mid j}q^{E_q}.
\]

If a prime `q|j` lies outside `H_a`, exact projection shadowing fails immediately, because the divisor `q` itself lies outside `U_a subset H_a`.

If every prime factor lies in `H_a`, choose exponent vectors `v_q` satisfying

\[
\phi_a(v_q)=q\pmod d.
\]

Then every divisor of `j` has the form

\[
\phi_a\left(\sum_q t_qv_q\right),
\qquad
0\le t_q\le E_q.
\]

Therefore exact projection shadowing becomes the signed-box containment problem

\[
\boxed{
\phi_a
\left(
\left\{
\sum_qt_qv_q:0\le t_q\le E_q
\right\}
\right)
\subseteq
\phi_a(B_A\cup-B_A).
}
\]

The relation lattice `ker(phi_a)` allows wraparound, so the problem lives in a finite abelian exponent lattice rather than ordinary Euclidean boxes.

## 4. A tempting simplification is false

A natural guess is:

> If every prime-power divisor `q^t` of `j` lands in `U_a`, then every divisor of `j` lands in `U_a`.

This would reduce exact projection shadowing to independent one-prime tests.

It is false.

## 5. First mixed-box counterexample

Take

\[
\boxed{j=696.}
\]

Then

\[
4j-1=2783=23\cdot11^2,
\]

so the squarefree ancestor modulus is

\[
d=23,
\qquad
a=6.
\]

The ancestor divisor set is

\[
D_6=\{1,2,3,6\}\pmod{23}.
\]

Its inverse set is

\[
D_6^{-1}=\{1,12,8,4\}.
\]

Thus

\[
\boxed{
U_6=\{1,2,3,4,6,8,12\}\pmod{23}.
}
\]

Now

\[
696=2^3\cdot3\cdot29.
\]

Every prime-power direction individually stays inside the ancestor envelope:

\[
2,4,8\in U_6,
\]

\[
3\in U_6,
\]

and

\[
29\equiv6\pmod{23}\in U_6.
\]

Nevertheless the mixed divisor

\[
87=3\cdot29
\]

satisfies

\[
87\equiv18\pmod{23},
\]

and

\[
\boxed{18\notin U_6.}
\]

Likewise

\[
174\equiv13\pmod{23}
\]

is outside `U_6`.

Therefore

\[
\boxed{
T_{696}\bmod23
\not\subseteq T_6
}
\]

although every individual prime-power divisor direction passes the ancestor test.

This is a genuine **mixed-box obstruction**.

## 6. Finite search through j <= 20000

An exhaustive square-lift replay through `j<=20000` found `3,788` non-squarefree moduli `4j-1`.

They split as:

```text
exact ancestor projection contained:       1,198
prime-power / axis failure visible:        2,575
all prime-power axes safe but mixed fail:     15
```

The first mixed-only failure is `j=696` above.

The 15 mixed-only failures through this finite range are:

```text
696, 1180, 2076, 2324, 6408,
7044, 8319, 9592, 10024, 10632,
10740, 12702, 16152, 19752, 19869
```

This finite list is proof-mining data, not a universal classification.

Its importance is negative: it falsifies the simplest generator-wise exact theorem and proves that the final residue core contains real interactions among divisor directions.

## 7. Two kinds of exact square-lift defect

The exact projection failure now has a clean dichotomy.

### Axis defect

Some prime-power divisor already escapes:

\[
\boxed{
q^t\bmod d\notin U_a.
}
\]

This is visible one generator at a time.

### Mixed-box defect

Every prime-power divisor lies in `U_a`, but a product of different prime-power directions escapes:

\[
\boxed{
\prod_q q^{t_q}\bmod d\notin U_a.
}
\]

This is a genuine interaction effect.

The first type dominates the finite data, but the second type is exactly where a purely local prime-by-prime classification fails.

## 8. Relation to the earlier quotient hierarchy

The hierarchy can now be written more sharply:

\[
\boxed{
\begin{array}{c}
\text{genus / quadratic signature defect}\\
\downarrow\\
\text{multiplicative subgroup defect }(q\notin H_a)\\
\downarrow\\
\text{single-axis signed-box defect}\\
\downarrow\\
\text{mixed signed-box defect}\\
\downarrow\\
\text{exact projection excess}
\end{array}}
\]

Each level is strictly finer than the one above it.

The mixed-box counterexample proves that the last step cannot be removed without an additional theorem.

## 9. New theorem target

The highest-value exact square-lift question is now:

> Classify the maps from the divisor exponent box of `j` into the ancestor signed box `B_A union -B_A` modulo the relation lattice of `H_a`.

Useful subtargets are:

1. classify when a single prime-power axis stays inside the signed box;
2. classify when two individually safe axes have an unsafe sum;
3. find a Helly-type or bounded-support theorem: if full containment fails, is there always a failing divisor involving at most `C` distinct prime factors for an absolute small `C`?
4. determine whether every mixed-box defect is already detected by a pair of prime directions;
5. compare the minimal failing support with the fiber-kernel residual size.

If target 4 were true, the final square-lift residue obstruction would reduce from an arbitrary divisor box to pairwise interactions.

That is now directly falsifiable.

## 10. Novelty boundary

Exponent lattices, finite abelian groups, inverse sets, and box-containment problems are standard mathematical objects. López already records the mutual-inverse relation of the Type A/B divisor families.

The candidate contribution is the **signed-box formulation and its role as the exact residual layer of the Type A/B minimal-depth shadow hierarchy**, pending prior-art and external review.
