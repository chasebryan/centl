# Square-lift reciprocity and infinite ancestor-shadow families

**Status:** proved theorem family  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this note does not prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture. It gives an exact infinite family of shadow reductions inside the squarefree-lift core.

Read with:

- [SQUAREFREE-LIFT-CORE.md](SQUAREFREE-LIFT-CORE.md)
- [QUADRATIC-TRAP-SIGNATURE.md](QUADRATIC-TRAP-SIGNATURE.md)
- [DYADIC-TRAP-LATTICE.md](DYADIC-TRAP-LATTICE.md)
- [THEORY.md](THEORY.md)

## 1. Square-lift setup

Let

\[
d=4a-1
\]

be squarefree, and let `s` be any positive odd integer. Define

\[
\boxed{
4j-1=d s^2,
\qquad
j=\frac{d s^2+1}{4}.
}
\]

Then the squarefree ancestor of the layer `j` is exactly `a`.

The exact Type A/B traps are

\[
T_j=\{-e,-4e\pmod{4j-1}:e\mid j\}.
\]

We study their projection modulo the ancestor modulus `d`.

## 2. Reciprocity theorem for divisors of j

### Theorem

For every divisor `e|j`,

\[
\boxed{
\left(\frac e d\right)=+1.
}
\]

Consequently,

\[
\boxed{
\left(\frac{-e}{d}\right)
=
\left(\frac{-4e}{d}\right)
=-1.
}
\]

Thus

\[
\boxed{
T_j\bmod d
\subseteq
\{u\in(\mathbb Z/d\mathbb Z)^\times:(u/d)=-1\}.
}
\]

### Proof

It is enough to prove the first claim for every prime divisor `ell|j`.

Because `gcd(j,4j-1)=1`, the prime `ell` is coprime to `d s`.

From

\[
d s^2=4j-1
\]

and `ell|j`, we obtain

\[
d s^2\equiv-1\pmod\ell.
\]

Hence

\[
-d\equiv s^{-2}\pmod\ell,
\]

so `-d` is a quadratic residue modulo `ell`.

### Odd ell

Because `d` is squarefree and `d=3 mod 4`, quadratic reciprocity for the Jacobi symbol gives

\[
\left(\frac\ell d\right)
=
\left(\frac{-d}{\ell}\right).
\]

The right side is `+1` by the congruence above. Therefore

\[
(\ell/d)=+1.
\]

### ell = 2

If `2|j`, then

\[
4j-1\equiv7\pmod8.
\]

Since every odd square is `1 mod 8`, the identity `4j-1=d s^2` gives

\[
d\equiv7\pmod8.
\]

Therefore

\[
(2/d)=+1.
\]

By multiplicativity, every divisor `e|j` satisfies `(e/d)=+1`.

Finally `d=3 mod 4`, so `(-1/d)=-1`, while `4` is a square modulo `d`. Hence

\[
(-e/d)=(-4e/d)=-1.
\]

QED.

## 3. Interpretation

The square-lift operation cannot project Type A/B traps arbitrarily into the ancestor unit group.

It is confined to the ancestor's Jacobi-negative half.

So the projection excess from [SQUAREFREE-LIFT-CORE.md](SQUAREFREE-LIFT-CORE.md),

\[
E_j=(T_j\bmod d)\setminus T_a,
\]

always satisfies

\[
\boxed{
E_j
\subseteq
\{u:(u/d)=-1\}\setminus T_a.
}
\]

The only possible new projected residues are therefore **nontrap quadratic nonresidues of the squarefree ancestor**.

This identifies the exact location where a square-lift can create genuinely new residue information.

## 4. Saturated-ancestor shadow theorem

Call the ancestor `a` **Jacobi-saturated** when

\[
\boxed{
T_a
=
\{u\in(\mathbb Z/d\mathbb Z)^\times:(u/d)=-1\}.
}
\]

### Theorem

If `a` is Jacobi-saturated, then every odd square-lift

\[
4j-1=(4a-1)s^2
\]

satisfies

\[
\boxed{
T_j\bmod(4a-1)
\subseteq T_a.
}
\]

Hence

\[
\boxed{E_j=\varnothing.}
\]

### Proof

The reciprocity theorem places the projected trap set inside the complete Jacobi-negative half of the ancestor. Saturation identifies that half with `T_a`. QED.

Thus every Jacobi-saturated ancestor generates an **infinite square-lift direct-shadow family**.

## 5. Three explicit infinite families

The first three ancestors are Jacobi-saturated.

### a = 1

\[
d=3,
\qquad
T_1=\{2\},
\]

which is the complete Jacobi-negative unit set modulo `3`.

Therefore for every odd `s`,

\[
\boxed{
j=\frac{3s^2+1}{4}}
\]

has

\[
T_j\bmod3\subseteq T_1.
\]

### a = 2

\[
d=7,
\qquad
T_2=\{3,5,6\},
\]

which is the complete quadratic-nonresidue set modulo `7`.

Therefore for every odd `s`,

\[
\boxed{
j=\frac{7s^2+1}{4}}
\]

has

\[
T_j\bmod7\subseteq T_2.
\]

### a = 4

\[
d=15,
\qquad
T_4=\{7,11,13,14\},
\]

which is the complete Jacobi-negative unit set modulo `15`.

Therefore for every odd `s`,

\[
\boxed{
j=\frac{15s^2+1}{4}}
\]

has

\[
T_j\bmod15\subseteq T_4.
\]

These are infinite exact shadow families, not finite empirical patterns.

## 6. Relation to the finite k <= 1200 core

The `k<=1200` squarefree-lift replay found many non-squarefree moduli whose projection excess is empty. The theorem above explains an infinite subcollection immediately: every lift with squarefree ancestor modulus `3`, `7`, or `15` is forced to have zero excess.

It also explains why the exceptional projection layers cannot be arbitrary. They can only arise when the ancestor's Jacobi-negative half is strictly larger than its exact Type A/B trap set.

For example, the ancestor

\[
a=3,
\qquad d=11,
\]

has only three Type A/B trap residues while the Jacobi-negative half has five. Square-lifts over `11` can therefore create projection excess, and the first such example occurs at

\[
j=25,
\qquad
4j-1=99=11\cdot3^2.
\]

## 7. New classification problem

The projection-excess question now splits cleanly into two pieces.

First, classify the Jacobi-saturated ancestors:

\[
\boxed{
T_a
=
\{u:(u/(4a-1))=-1\}.
}
\]

Second, for a nonsaturated ancestor, determine which square multipliers `s^2` still satisfy

\[
T_j\bmod(4a-1)\subseteq T_a.
\]

The finite data shows that both outcomes occur for the same ancestor, so saturation is sufficient but not necessary for an individual lift to be shadowed.

## 8. Why this sharpens the proof search

The residual hierarchy is now

\[
\boxed{
\text{fixed-negative character layer}
\to
\text{squarefree ancestor}
\to
\text{Jacobi-negative projection}
\to
\text{ancestor trap vs. nontrap split}
\to
\text{projection excess only}.
}
\]

A large half-space obstruction has collapsed to a small exact residue difference set.

That difference set, rather than the whole lifted trap layer, is the object that must be controlled in the next Direct-Shadow Completeness proof stage.

## 9. Novelty boundary

Quadratic reciprocity and Jacobi symbols are classical. The candidate contribution is the square-lift specialization to the López Type A/B trap system and the resulting infinite ancestor-shadow families inside the minimal-depth/shadow framework.

Publication priority remains subject to external review and a broader literature search.
