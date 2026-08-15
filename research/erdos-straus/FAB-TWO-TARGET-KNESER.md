# Two-target Kneser collapse for external nonresidue shifts

**Status:** proved theorem  
**Date:** 2026-08-15  
**Depends on:** `FAB-KNESER-DIVISOR-DEFECT.md`, `FAB-TYPE-II-SIGNED-DIVISOR.md`, `FAB-UNBOUNDED-DIVISOR-RATIO-CERTIFICATE.md`, `EXTERNAL-NR-FACTOR-CYCLE.md`  
**Claim boundary:** this removes every odd-index Kneser stabilizer defect from the combined Type-I/Type-II Erdős--Straus problem at an external nonresidue prime shift. It does not eliminate the remaining even-index defects and therefore does not prove Erdős--Straus.

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
=\prod_i r_i^{e_i}
\]

and

\[
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

Two exact sufficient targets now live in this same set:

\[
\boxed{
\tau_I=-p^{-1}\pmod q
}
\]

from the strong fixed-`q` FAB/Type-I lane, and

\[
\boxed{
\tau_{II}=-1\pmod q
}
\]

from the normalized Type-II lane.

Therefore

\[
\boxed{
\tau_I\in R
\quad\text{or}\quad
\tau_{II}\in R
\Longrightarrow
p\text{ satisfies Erdős--Straus}.}
\]

The rest of this note studies what is forced if **both** targets are missed.

---

## 2. Character positions of the two targets

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

Hence

\[
\boxed{
\left(\frac{\tau_I}{q}\right)
=
\left(\frac{-p^{-1}}q\right)
=+1,
}
\]

while

\[
\boxed{
\left(\frac{\tau_{II}}q\right)
=-1.
}
\]

Thus the Type-I target is on the quadratic-residue side and the Type-II target is on the quadratic-nonresidue side.

This complementary placement is what collapses the previous odd-index defect hierarchy.

---

## 3. Stabilizer setup

Let

\[
H=\operatorname{Stab}(R)
=\{g\in G:gR=R\}
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
\]

and

\[
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

## 4. Odd stabilizer index is impossible for a combined failure

Assume

\[
\boxed{\tau_I\notin R,\qquad \tau_{II}\notin R.}
\]

Suppose first that `n` is odd.

Since `q≡3 mod4`,

\[
q-1=2m
\]

with `m` odd. If `n` is odd, then

\[
|H|=\frac{q-1}{n}
\]

is even.

The cyclic group `G` has a unique element of order two, namely `-1`. Every even-order subgroup contains that element. Therefore

\[
-1\in H.
\]

But `H⊆R`, so

\[
\tau_{II}=-1\in R,
\]

contradicting the assumed combined failure.

Thus:

### Theorem — odd-index collapse

If both fixed-`q` targets are missed, then

\[
\boxed{[G:H]\text{ is even}.}
\]

In particular **no odd stabilizer index can support a genuine combined Type-I/Type-II failure**.

---

## 5. Index two is also impossible

If

\[
[G:H]=2,
\]

then `H` is the unique quadratic-residue subgroup of `G`.

The Type-I target `tau_I` is a quadratic residue. Hence

\[
\tau_I\in H\subseteq R,
\]

again contradicting combined failure.

Therefore:

### Corollary — first possible combined defect

At an external nonresidue prime shift,

\[
\boxed{
\tau_I,\tau_{II}\notin R
\Longrightarrow
[G:H]\ge6
\text{ and }[G:H]\text{ is even}.}
\]

Since `v_2(q-1)=1`, every possible combined defect index has the form

\[
\boxed{2m,\qquad m\ge3\text{ odd}.}
\]

The first possible index is therefore `6`, not `3`.

This removes the entire odd-prime-index hierarchy (`3,5,7,11,...`) from the **combined Erdős--Straus obstruction**, even though those indices remain legitimate one-target defects for the Type-I box considered in isolation.

---

## 6. The two missed H-cosets are distinct

Continue to assume both targets are missed. Since the index `n` is even and `v_2(q-1)=1`, the subgroup `H` has odd order. Hence

\[
H\subseteq G^2,
\]

the quadratic-residue subgroup.

The quotient of the two targets is

\[
\frac{\tau_I}{\tau_{II}}
=
\frac{-p^{-1}}{-1}
=p^{-1}.
\]

If the two targets belonged to the same `H`-coset, then

\[
p^{-1}\in H,
\]

hence `p∈H`. But `H` contains only quadratic residues, while

\[
\left(\frac pq\right)=-1.
\]

Contradiction.

Therefore

\[
\boxed{\tau_IH\ne\tau_{II}H.}
\]

A combined failure misses **at least two distinct quotient cosets**.

---

## 7. Improved two-target Kneser budget

Because `R` is `H`-periodic and misses the two distinct cosets above,

\[
\boxed{|R|\le(n-2)|H|.}
\]

Combining this with the Kneser lower bound yields

\[
1+\sum_i(s_i-1)
\le n-2.
\]

Therefore:

### Theorem — two-target defect budget

If both the Type-I and Type-II targets are missed at an external nonresidue prime shift, then

\[
\boxed{
\sum_i
\left(
\min(2e_i+1,\operatorname{ord}_{G/H}(r_iH))-1
\right)
\le n-3,
\qquad n=[G:H].
}
\]

This improves the previous one-target budget

\[
\sum_i(s_i-1)\le n-2
\]

by one full unit of quotient room.

---

## 8. Cubic defects are automatically rescued

The previous one-target Kneser analysis identified index `3` as the first possible Type-I placement defect and derived a rigid cubic-residue normal form.

For the full Erdős--Straus problem, that cubic case is no obstruction at all.

Indeed, an index-three stabilizer has even order, hence contains `-1`. Because `H⊆R`,

\[
\boxed{-1\in R.}
\]

Thus the normalized Type-II target hits at the same fixed shift.

So:

\[
\boxed{
\text{Type-I cubic defect}
\Longrightarrow
\text{Type-II rescue at the same }q.
}
\]

The same statement holds for **every odd stabilizer index**, not merely index three.

---

## 9. Strategic consequence

For the direct Erdős--Straus route, the Kneser search should no longer spend its main effort classifying cubic, fifth-power, seventh-power, or other odd-index Type-I defects one by one.

Those defects matter if one insists on the Type-I/strong-FAB target alone, but the second target shows that they cannot be genuine failures of the full equation.

The new residual wall is:

\[
\boxed{
\text{external nonresidue }q
+\text{both targets missed}
+\text{even stabilizer index }n\ge6
+\text{two-target budget }\le n-3.
}
\]

The first exact case to classify is therefore

\[
\boxed{n=6.}
\]

At index six the entire expansion budget is only

\[
\boxed{\sum_i(s_i-1)\le3.}
\]

That is a much smaller obstruction than the former unrestricted cubic-first hierarchy.

---

## 10. Next theorem target

Classify all aperiodic symmetric signed boxes in the cyclic quotient `C_6` satisfying

\[
\sum_i(s_i-1)\le3
\]

while simultaneously missing

\[
\tau_{II}H=(-1)H
\]

and

\[
\tau_IH=(-p^{-1})H.
\]

Then transport the resulting finite list through the external-nonresidue factor cycle.

If index six can be eliminated, the next possible combined defect index jumps to the next even divisor `2m` of `q-1` with odd `m>3`, again under the strengthened two-target budget.
