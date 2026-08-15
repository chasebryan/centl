# Two-target Kneser collapse for external nonresidue shifts

**Status:** proved theorem  
**Date:** 2026-08-15  
**Depends on:** `FAB-KNESER-DIVISOR-DEFECT.md`, `FAB-TYPE-II-SIGNED-DIVISOR.md`, `FAB-UNBOUNDED-DIVISOR-RATIO-CERTIFICATE.md`, `EXTERNAL-NR-FACTOR-CYCLE.md`  
**Claim boundary:** this removes every odd-index Kneser stabilizer defect from the combined Type-I/Type-II Erdős--Straus problem at an external nonresidue prime shift and strengthens the remaining Kneser budget by exploiting inversion symmetry. It does not eliminate the remaining even-index defects and therefore does not prove Erdős--Straus.

---

## 1. Same box, two solution targets

Let `p` be a Mordell-hard prime and let `q<p` be an external quadratic-nonresidue prime satisfying

\[
q\equiv3\pmod4,
\qquad
\left(\frac qp\right)=-1.
\]

Put

\[
C=\frac{p+q}{4}
=\prod_i r_i^{e_i},
\qquad
G=(\mathbb Z/q\mathbb Z)^\times.
\]

The fixed-`q` signed divisor box is

\[
\boxed{
R=
\left\{
\prod_i r_i^{z_i}\pmod q:
-e_i\le z_i\le e_i
\right\}.
}
\]

It is inversion-symmetric:

\[
\boxed{R^{-1}=R.}
\]

Two exact sufficient targets live in the same box:

\[
\boxed{\tau_I=-p^{-1}\pmod q}
\]

from the strong fixed-`q` FAB / normalized Type-I lane, and

\[
\boxed{\tau_{II}=-1\pmod q}
\]

from the normalized Type-II lane.

Hence

\[
\boxed{
\tau_I\in R
\quad\text{or}\quad
\tau_{II}\in R
\Longrightarrow
p\text{ satisfies Erdős--Straus}.}
\]

Because `R=R^{-1}`, a Type-I miss automatically also misses

\[
\boxed{\tau_I^{-1}=-p.}
\]

Thus a genuine combined failure excludes three natural residues:

\[
\boxed{-p^{-1},\quad -p,\quad -1.}
\]

---

## 2. Quadratic character positions

Because `p≡1 mod4`, quadratic reciprocity gives

\[
\left(\frac pq\right)
=
\left(\frac qp\right)
=-1.
\]

Also `q≡3 mod4`, so

\[
\left(\frac{-1}{q}\right)=-1.
\]

Therefore

\[
\boxed{
\left(\frac{-p^{-1}}q\right)=+1,
\qquad
\left(\frac{-p}q\right)=+1,
\qquad
\left(\frac{-1}q\right)=-1.
}
\]

The two inverse Type-I orientations lie on the quadratic-residue side, while the Type-II target lies on the quadratic-nonresidue side.

---

## 3. Stabilizer and Kneser setup

Let

\[
H=\operatorname{Stab}(R)
\]

and put

\[
\boxed{n=[G:H].}
\]

Because `1∈R` and `R` is `H`-periodic,

\[
\boxed{H\subseteq R.}
\]

For each prime factor `r_i` of `C`, define

\[
d_i=\operatorname{ord}_{G/H}(r_iH),
\qquad
s_i=\min(2e_i+1,d_i).
\]

Kneser's theorem gives

\[
\boxed{
|R|
\ge
|H|\left(1+\sum_i(s_i-1)\right).
}
\]

---

## 4. Odd stabilizer index is impossible

Assume both solution targets are missed.

If `n` were odd, then because

\[
q-1=2m
\]

with `m` odd, the subgroup `H` would have even order. The cyclic group `G` has a unique element of order two, namely `-1`, so every even-order subgroup contains `-1`.

Hence

\[
-1\in H\subseteq R,
\]

contradicting the Type-II miss.

Therefore

\[
\boxed{n\text{ is even}.}
\]

This eliminates every odd-index Type-I Kneser defect from the combined Erdős--Straus obstruction.

---

## 5. Index two is impossible

If `n=2`, then `H` is the quadratic-residue subgroup. The Type-I target `-p^{-1}` is a quadratic residue, so

\[
-p^{-1}\in H\subseteq R,
\]

contradicting failure.

Thus

\[
\boxed{
\text{combined failure}
\Longrightarrow
n\ge6\text{ and }n\text{ is even}.}
\]

Since `v_2(q-1)=1`, every possible combined defect index has the form

\[
\boxed{n=2m,\qquad m\ge3\text{ odd}.}
\]

The first possible index is `6`, not `3`.

---

## 6. Three distinct missed H-cosets

For an even combined defect index, `H` has odd order. Hence

\[
H\subseteq G^2,
\]

the quadratic-residue subgroup.

The Type-II target `-1` is a quadratic nonresidue, while `-p^{-1}` and `-p` are quadratic residues. Therefore

\[
(-1)H
\]

is distinct from both Type-I target cosets.

It remains to compare the inverse Type-I cosets.

Because `H` has odd order, the quotient

\[
G^2/H
\]

also has odd order. The class of `-p^{-1}` lies in this quotient. If

\[
(-p^{-1})H=(-p)H,
\]

then the class of `-p^{-1}` would equal its inverse and therefore have order at most two. An odd-order group has no nontrivial element of order two, so this would force

\[
-p^{-1}\in H\subseteq R,
\]

contradicting the assumed Type-I miss.

Hence

\[
\boxed{
(-p^{-1})H,
\quad
(-p)H,
\quad
(-1)H
\text{ are three distinct }H\text{-cosets}.}
\]

---

## 7. Symmetric three-coset Kneser budget

A combined failure therefore misses at least three distinct `H`-cosets. Since `R` is `H`-periodic,

\[
\boxed{|R|\le(n-3)|H|.}
\]

Combining with the Kneser lower bound gives

\[
1+\sum_i(s_i-1)
\le n-3.
\]

Thus:

### Theorem — symmetric combined defect budget

If both Type I and Type II miss at an external nonresidue prime shift, then

\[
\boxed{
\sum_i
\left(
\min(2e_i+1,\operatorname{ord}_{G/H}(r_iH))-1
\right)
\le n-4,
\qquad n=[G:H].
}
\]

This improves the original one-target budget `n-2` by **two full units of quotient room**.

---

## 8. Odd-index defects are automatically Type-II rescued

The one-target analysis previously identified cubic index `3` as the first possible Type-I defect, followed by prime indices `5,7,11,...`.

For the full equation, none of those odd-index defects can survive. At any odd index, `-1∈H⊆R`, so the Type-II target is already hit at the same fixed shift.

In particular,

\[
\boxed{
\text{Type-I cubic defect}
\Longrightarrow
\text{Type-II rescue at the same }q.}
\]

The same implication holds for every odd stabilizer index.

---

## 9. First combined case: index six

At

\[
n=6,
\]

the symmetric combined budget becomes

\[
\boxed{
\sum_i(s_i-1)\le2.}
\]

Moreover the quotient has six classes. Because a combined failure misses exactly the three distinguished target-side classes at minimum,

\[
(-p^{-1})H,
\quad
(-p)H,
\quad
(-1)H,
\]

only three quotient classes can remain occupied by the signed box.

`FAB-INDEX6-COMBINED-DEFECT.md` proves that this forces a single primitive sextic factor.

---

## 10. Strategic consequence

The direct ES search should no longer classify odd-prime Kneser defects one by one.

The residual wall is now

\[
\boxed{
\text{external nonresidue }q
+\text{three target cosets missed}
+\text{even stabilizer index }n\ge6
+\text{symmetric budget }\le n-4.}
\]

The first case is index six with budget only `2`. If index six is eliminated, the search jumps directly to the next even quotient `2m` under the same stronger symmetric budget.
