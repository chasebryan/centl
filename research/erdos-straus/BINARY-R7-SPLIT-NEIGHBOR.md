# Exact r=7 binary rescue for Mordell-hard primes

**Status:** proved iff classification  
**Date:** 2026-08-15  
**Depends on:** `BINARY-R-RESCUE.md`, `BINARY-R-DIVISOR-COLLISION.md`  
**Claim boundary:** this closes the `r=7` stage exactly. It does not prove that every hard prime is rescued at `r=7`, and therefore does not prove Erdős–Straus.

## 1. Setup

Let `p` be a Mordell-hard prime. Then

\[
p\bmod840\in\{1,121,169,289,361,529\},
\]

so in particular

\[
\boxed{p\bmod7\in\{1,2,4\}.}
\]

These are exactly the nonzero quadratic residues modulo `7`.

Put

\[
\boxed{A_7=\frac{p+7}{4}},
\qquad
N_7=pA_7.
\]

Since hard `p == 1 (mod 8)`,

\[
p+7\equiv0\pmod8,
\]

hence

\[
\boxed{2\mid A_7.}
\]

By the binary-r collision theorem, `p` is rescued at `r=7` iff the divisor residues of `N_7` meet their negatives modulo `7`.

## 2. Fixed quadratic-residue divisors already fill the QR half

The quadratic-residue subgroup modulo `7` is

\[
Q_7=\{1,2,4\}.
\]

We always have divisor residue `1`.

We also have the divisor `p`, whose residue lies in `Q_7`, and because `2|A_7`, the literal divisor `2` belongs to `N_7`.

Casewise:

- if `p == 1 (mod 7)`, divisors `1` and `2` are present, and `A_7 == 2 (mod 7)`; products available inside the divisor lattice give the needed QR support;
- if `p == 2 (mod 7)`, the fixed divisors `1,p,A_7` have residues
  \[
  1,2,4;
  \]
- if `p == 4 (mod 7)`, the fixed divisors `1,p,2` have residues
  \[
  1,4,2.
  \]

More directly in the first case, if a nonresidue factor `q` occurs, multiplication by the divisor `2` supplies the missing negative whenever `q == 3 (mod 7)`, while `q == 5,6` collide with already present `2,1` respectively. Thus no separate assumption that all three QR residues are present is needed.

## 3. Any nonresidue prime factor forces rescue

The nonresidues modulo `7` are

\[
\{3,5,6\}.
\]

Let `q|A_7` be prime and assume `(q/7)=-1`.

### q == 5 mod 7

Then

\[
-q\equiv2\pmod7.
\]

The divisor `2|A_7` is present, so the divisor residue set contains both `q` and `-q`. Rescue follows.

### q == 6 mod 7

Then

\[
-q\equiv1\pmod7.
\]

The divisor `1` is present, so rescue follows.

### q == 3 mod 7

Then

\[
2q\equiv6\equiv-1\pmod7.
\]

Because `q` is odd and `2q|A_7`, both `1` and the divisor `2q` are present, so the collision follows.

Thus

\[
\boxed{
\exists q\mid A_7\text{ prime with }(q/7)=-1
\Longrightarrow
r=7\text{ rescues }p.
}
\]

## 4. Converse

If every prime factor of `A_7` is a quadratic residue modulo `7`, then every divisor of `A_7` is a quadratic residue modulo `7`.

The hard prime `p` is itself a quadratic residue modulo `7`. Therefore every divisor of

\[
N_7=pA_7
\]

lies in `Q_7`.

But

\[
-1\equiv6\pmod7
\]

is a quadratic nonresidue, so negation maps the QR half to the NQR half. Hence

\[
D_7(N_7)\cap(-D_7(N_7))=\varnothing.
\]

No binary-r rescue exists at `r=7`.

Combining the two directions gives the exact classification:

\[
\boxed{
\text{r=7 rescues }p
\iff
\frac{p+7}{4}
\text{ has a prime factor that is a quadratic nonresidue mod }7.
}
\]

Equivalently, failure at `r=7` is exactly

\[
\boxed{
q\mid\frac{p+7}{4},\ q\text{ prime}
\Longrightarrow
\left(\frac q7\right)=+1.
}
\]

## 5. Simultaneous residue interpretation modulo p

By the reciprocity bridge in `BINARY-R-DIVISOR-COLLISION.md`, for every odd prime `q|A_7`,

\[
\left(\frac qp\right)=\left(\frac q7\right).
\]

Therefore failure of the `r=7` rescue says that every prime factor of the neighboring integer

\[
\boxed{A_7=A_3+1}
\]

is simultaneously a quadratic residue modulo `7` and modulo `p`.

The preceding `r=3` failure says every prime factor of

\[
A_3=\frac{p+3}{4}
\]

is `1 mod 3`, equivalently quadratic-residue-side modulo `3`.

Thus a hypothetical counterexample surviving both binary stages has two consecutive integers

\[
A_3,\quad A_3+1
\]

with exact split-prime restrictions in two different quadratic characters.
