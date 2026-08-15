# Kneser defect theorem for external binary-r rescue

**Status:** proved universal theorem in the external-nonresidue binary-rescue lane  
**Date:** 2026-08-15  
**Depends on:** `BINARY-R-DIVISOR-COLLISION.md`, `FAB-KNESER-FULL-STABILIZER-DEFECT.md`, `SHIFTED-NONRESIDUE-TRANSFER.md`  
**Claim boundary:** proves that every failed external binary-r collision has an even stabilizer quotient and sharply bounds its visible nonresidue valuation mass. It does not prove that some r must succeed for every hard prime and therefore does not prove Erdős-Straus.

---

## 1. Setup

Let `p` be a Mordell-hard prime and let

\[
r\equiv3\pmod4
\]

be a prime satisfying

\[
\boxed{\left(\frac rp\right)=-1.}
\]

Put

\[
A=\frac{p+r}{4},
\qquad
N=pA.
\]

`BINARY-R-DIVISOR-COLLISION.md` proves that the exact binary rescue exists if and only if the signed divisor exponent box

\[
\boxed{
R=
\left\{
\prod_{s^e\parallel N}s^z\pmod r:
-e\le z\le e
\right\}
\subseteq G=(\mathbb Z/r\mathbb Z)^\times
}
\]

contains

\[
\boxed{-1.}
\]

Assume the binary rescue fails:

\[
\boxed{-1\notin R.}
\]

Let

\[
H=\operatorname{Stab}(R),
\qquad
n=[G:H].
\]

Because `r` is prime, `G` is cyclic of order `r-1`.

---

## 2. Odd defect index is impossible

Suppose

\[
2\nmid n.
\]

Write `G=<g>`. The unique subgroup of index `n` is

\[
H=\langle g^n\rangle.
\]

Since `n|(r-1)` and `n` is odd,

\[
n\mid\frac{r-1}{2}.
\]

Therefore

\[
-1
=g^{(r-1)/2}
\in H.
\]

But `1 in R`, and `R` is `H`-periodic. Hence

\[
H\subseteq R.
\]

Thus

\[
-1\in R,
\]

contradicting binary-rescue failure.

### Theorem — no odd binary defect

Every failed external binary-r divisor collision has

\[
\boxed{2\mid n.}
\]

Since

\[
r\equiv3\pmod4,
\]

we have

\[
v_2(r-1)=1.
\]

Therefore every even defect index satisfies

\[
\boxed{n\equiv2\pmod4.}
\]

So the complete defect spectrum is

\[
\boxed{n=2,6,10,14,18,\ldots}
\]

before the additional Kneser constraints are imposed.

---

## 3. Index two is also impossible

If

\[
n=2,
\]

then `H` is the quadratic-residue subgroup of `G`.

Quadratic reciprocity gives

\[
\left(\frac pr\right)
=
\left(\frac rp\right)
=-1
\]

because `p≡1 mod4`.

Thus the distinguished prime factor `p||N` lies outside `H`.

Its local signed set is

\[
\{p^{-1},1,p\}.
\]

Modulo `H`, the element `pH` has order two, so this local set already fills the whole quotient

\[
G/H.
\]

That would make the full signed box project onto the whole quotient, including the class of `-1`, contradicting failure.

Equivalently, this is the projected-order gap from the full-stabilizer theorem: an exponent-one factor outside `H` would require quotient order strictly greater than `3`, not `2`.

Hence

\[
\boxed{n\ne2.}
\]

Combining with the previous section:

\[
\boxed{n\ge6,\qquad n\equiv2\pmod4.}
\]

---

## 4. Both p and A are quadratic nonresidues modulo r

We already have

\[
\left(\frac pr\right)=-1.
\]

Also

\[
A=\frac{p+r}{4}
\equiv\frac p4\pmod r,
\]

so

\[
\boxed{\left(\frac Ar\right)=-1.}
\]

Therefore the total quadratic-nonresidue valuation mass inside the factorization of `A` is odd.

Define

\[
\boxed{
E_r(A)
=
\sum_{
 s^e\parallel A,
 (s/r)=-1
}e.
}
\]

Then

\[
\boxed{E_r(A)\equiv1\pmod2.}
\]

Because `p` does not divide `A`, the corresponding nonresidue valuation mass in

\[
N=pA
\]

is exactly

\[
\boxed{E_r(N)=1+E_r(A).}
\]

Thus `E_r(N)` is positive and even.

---

## 5. Every quadratic-nonresidue factor is visible

Every failed defect index is even. As in `FAB-KNESER-EVEN-DEFECT-EDGE.md`, this implies

\[
H\subseteq G^2.
\]

Therefore every prime factor of `N` that is a quadratic nonresidue modulo `r` lies outside `H`.

The full-stabilizer Kneser theorem gives

\[
2\sum_{s^e\parallel N,\ s\notin H}e
\le n-2.
\]

Hence

\[
2E_r(N)\le n-2.
\]

Substituting `E_r(N)=1+E_r(A)` yields:

### Theorem — external binary defect mass bound

Every failed external binary-r collision satisfies

\[
\boxed{
n\ge2E_r(A)+4.}
\]

Equivalently,

\[
\boxed{
E_r(A)\le\frac{n-4}{2}.
}
\]

Because `E_r(A)` is odd and `n≡2 mod4`, this parity is exact, not merely an inequality artifact.

Every additional nonresidue valuation unit in the shifted integer `(p+r)/4` eliminates another low even defect index.

---

## 6. Projected-order bound

Let

\[
s^e\parallel N
\]

with

\[
\left(\frac sr\right)=-1.
\]

Then `s notin H`. The full-stabilizer theorem gives

\[
\operatorname{ord}_{G/H}(sH)>2e+1.
\]

Because `sH` remains quadratic-nonresidue-side in the even quotient, its order is even. Therefore

\[
\boxed{
\operatorname{ord}_{G/H}(sH)
\ge2e+2.
}
\]

In particular, the distinguished factor `p` has exponent one, so

\[
\boxed{
\operatorname{ord}_{G/H}(pH)\ge4.
}
\]

But the quotient order is `2 mod4`, so the first possible order is actually

\[
\boxed{6.}
\]

This is another direct proof that no index-two defect can survive.

---

## 7. Exact index-six classification

Assume

\[
\boxed{n=6.}
\]

The mass bound gives

\[
E_r(A)\le1.
\]

Since `E_r(A)` is positive and odd,

\[
\boxed{E_r(A)=1.}
\]

Thus `A` contains exactly one unit of quadratic-nonresidue valuation mass: there is a unique prime

\[
s\parallel A
\]

with `(s/r)=-1`, and every other prime factor of `A` is a quadratic residue modulo `r`.

The two nonresidue prime factors of `N=pA` are therefore precisely the simple factors

\[
p
\quad\text{and}\quad
s.
\]

They already consume the full outside-stabilizer valuation budget:

\[
2(1+1)=4=n-2.
\]

Hence every other prime factor of `N` lies in `H`.

The projected-order gap excludes orders `2` and `3`; in the cyclic quotient of order six, both `pH` and `sH` therefore have exact order six.

Let `x` generate `G/H`. Every generator is `x` or `x^{-1}`, so each of the two simple nontrivial local sets is

\[
\{x^{-1},1,x\}.
\]

Their product is

\[
\boxed{
R/H
=
\{x^{-2},x^{-1},1,x,x^2\},
}
\]

which is every quotient class except the unique order-two class

\[
x^3.
\]

Because `r≡3 mod4` and `H⊂G^2`, the image of `-1` in `G/H` is exactly that order-two class.

Therefore:

### Theorem — exact binary index-six defect

A binary-r failure has stabilizer index six if and only if, in the quotient geometry forced above, the shifted factorization has exactly two simple primitive order-six atoms `p` and `s`, all other factor mass lies in `H`, and

\[
\boxed{
R/H=(G/H)\setminus\{-1H\}.
}
\]

So index six is the extremal one-hole failure: the signed divisor box covers five of the six quotient classes and misses **only the required ES target**.

---

## 8. Why the binary route is cleaner than the FAB target route

For the strong fixed-q FAB target, odd-index defects can survive and must be treated separately.

For the binary-r target, the distinguished class is exactly `-1`. Since `-1` belongs to every odd-index subgroup of a cyclic group of order `2 mod4`, **all odd-index defects vanish immediately**.

Thus every external binary-r failure has the same architecture:

\[
\boxed{
\text{even quotient}
\Longrightarrow
H\subseteq\text{quadratic residues}
\Longrightarrow
\text{every nonresidue factor is visible}
\Longrightarrow
\text{Kneser mass forces the quotient upward}.
}
\]

This removes the odd high-power-residue branch from the entropy-or-descent program entirely.

---

## 9. New direct ES target

For every Mordell-hard prime `p`, choose an external nonresidue prime

\[
r\equiv3\pmod4,
\qquad
(r/p)=-1.
\]

If the binary collision at `r` fails, its full stabilizer index obeys

\[
\boxed{
n\ge2E_r((p+r)/4)+4,
\qquad n\mid r-1,
\qquad n\equiv2\pmod4.
}
\]

Therefore a universal proof can aim to force

\[
2E_r((p+r)/4)+4>r-1
\]

for some external `r`, or more generally show that the finite external-nonresidue factor cycle cannot support the required sequence of increasingly structured even defects.

Unlike the FAB route, there is no odd-defect escape hatch.
