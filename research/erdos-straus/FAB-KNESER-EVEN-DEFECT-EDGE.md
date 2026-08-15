# Even-index FAB defects expose every quadratic-nonresidue factor

**Status:** proved universal theorem in the external-nonresidue prime-shift lane  
**Date:** 2026-08-15  
**Depends on:** `FAB-KNESER-FULL-STABILIZER-DEFECT.md`, `EXTERNAL-NR-FACTOR-CYCLE.md`, `SHIFTED-NONRESIDUE-TRANSFER.md`  
**Claim boundary:** gives a sharp lower bound on every even-index placement defect in terms of the quadratic-nonresidue valuation mass of the shifted factorization. It does not eliminate all odd-index defects and therefore does not prove Erdős-Straus.

---

## 1. Setup

Let `p` be a Mordell-hard prime and let

\[
q\equiv3\pmod4
\]

be a prime satisfying

\[
\left(\frac qp\right)=-1.
\]

Put

\[
\boxed{C=\frac{p+q}{4}}
\]

and let

\[
R\subseteq G=(\mathbb Z/q\mathbb Z)^\times
\]

be the fixed-`q` signed divisor box.

Assume the exact FAB target is missed. Let

\[
\boxed{H=\operatorname{Stab}(R)}
\]

be the full stabilizer and set

\[
\boxed{n=[G:H].}
\]

This note treats the case

\[
\boxed{2\mid n.}
\]

Because `q≡3 mod4`,

\[
q-1=2m
\]

with `m` odd. Hence every even divisor `n` of `q-1` satisfies

\[
\boxed{n\equiv2\pmod4.}
\]

---

## 2. The stabilizer lies inside the quadratic residues

The group `G` is cyclic. Choose a generator `g`.

The unique subgroup of index `n` is

\[
H=\langle g^n\rangle.
\]

Since `n` is even,

\[
g^n=(g^2)^{n/2}
\]

is a square. Therefore every element of `H` is a square:

\[
\boxed{H\subseteq G^2.}
\]

So every quadratic nonresidue modulo `q` lies outside the full defect stabilizer.

### Corollary — the factor-cycle edge is always visible

`EXTERNAL-NR-FACTOR-CYCLE.md` supplies, from this `3 mod4` source vertex `q`, a prime factor

\[
r\mid C
\]

with

\[
\left(\frac rp\right)=-1.
\]

The factorwise transfer theorem gives

\[
\left(\frac rq\right)=-1.
\]

Hence in every even-index failure,

\[
\boxed{r\notin H.}
\]

Thus the external-nonresidue descent edge cannot be hidden inside an even-index stabilizer.

---

## 3. Quadratic-nonresidue valuation mass

Write

\[
C=\prod_s s^{e_s}.
\]

Define the total valuation mass carried by quadratic nonresidue prime factors modulo `q`:

\[
\boxed{
E_q(C)
:=
\sum_{
 s^{e_s}\parallel C,
 (s/q)=-1
} e_s.
}
\]

Every such prime factor lies outside `H`. Therefore

\[
E_q(C)
\le
\sum_{s^{e_s}\parallel C,\ s\notin H} e_s.
\]

The full-stabilizer defect theorem gives

\[
2\sum_{s^{e_s}\parallel C,\ s\notin H} e_s
\le n-2.
\]

Hence

\[
\boxed{2E_q(C)\le n-2.}
\]

or equivalently

\[
\boxed{n\ge2E_q(C)+2.}
\]

---

## 4. Parity sharpens the bound by two more units

Because `(q/p)=-1` and both `p≡1 mod4`, `q≡3 mod4`, quadratic reciprocity gives

\[
\left(\frac pq\right)=-1.
\]

Since `4` is a square modulo `q`,

\[
\boxed{\left(\frac Cq\right)=-1.}
\]

Thus the total nonresidue valuation mass has odd parity:

\[
\boxed{E_q(C)\equiv1\pmod2.}
\]

Consequently

\[
2E_q(C)+2\equiv0\pmod4.
\]

But every even defect index satisfies

\[
n\equiv2\pmod4.
\]

Therefore the first allowable even index at or above `2E_q(C)+2` is two units larger.

### Theorem — even-defect edge bound

Every even-index failed fixed-`q` FAB box in the external-nonresidue lane satisfies

\[
\boxed{
n\ge2E_q(C)+4.}
\]

Equivalently,

\[
\boxed{
E_q(C)\le\frac{n-4}{2}.
}
\]

This is sharper than the generic full-stabilizer bound because the external shift forces odd quadratic-nonresidue parity while `q≡3 mod4` forces the quotient index to have exactly one factor of two.

---

## 5. Individual projected-order bound for every nonresidue factor

Let

\[
s^e\parallel C
\]

with

\[
\left(\frac sq\right)=-1.
\]

Then `s notin H`. `FAB-KNESER-FULL-STABILIZER-DEFECT.md` gives

\[
\operatorname{ord}_{G/H}(sH)>2e+1.
\]

Because `H⊆G^2` and `s` is a nonresidue, the quotient class `sH` remains outside the quotient's square subgroup. Its order is therefore even.

Hence

\[
\boxed{
\operatorname{ord}_{G/H}(sH)
\ge2e+2.
}
\]

In particular the full quotient index obeys

\[
\boxed{n\ge2e+2}
\]

for every nonresidue prime-power factor separately.

Thus high valuation of even one quadratic-nonresidue factor forces a large defect quotient.

---

## 6. Small-index consequences

### Index 6

The theorem gives

\[
E_q(C)\le1.
\]

Since `E_q(C)` is positive and odd,

\[
\boxed{E_q(C)=1.}
\]

So an index-six failure contains exactly one unit of quadratic-nonresidue valuation mass. This is consistent with, and is strengthened by, the exact unique order-six atom classification in `FAB-KNESER-INDEX6-CLASSIFICATION.md`.

### Index 10

\[
E_q(C)\le3.
\]

Hence

\[
\boxed{E_q(C)\in\{1,3\}.}
\]

So every index-ten failure has either one or three total nonresidue valuation units, never two or four.

### Index 14

\[
E_q(C)\le5,
\]

and therefore

\[
E_q(C)\in\{1,3,5\}.
\]

### Index 18

\[
E_q(C)\le7,
\]

so

\[
E_q(C)\in\{1,3,5,7\}.
\]

The same parity ladder holds for every even defect index.

---

## 7. Contrapositive elimination rule

The theorem gives an exact test for excluding a candidate even defect index.

If the shifted integer `C=(p+q)/4` has quadratic-nonresidue valuation mass `E`, then every even failed stabilizer quotient must satisfy

\[
\boxed{n\ge2E+4.}
\]

Therefore all even quotient indices

\[
2,6,10,\ldots,2E+2
\]

are automatically impossible.

As the factorization accumulates more nonresidue valuation mass, the entire low-index even defect spectrum is pushed upward.

This is the precise `entropy` side of the external factor-cycle program: every additional visible quadratic-nonresidue factor consumes stabilizer room that cannot be recovered by hiding it inside `H`.

---

## 8. Updated entropy-or-descent picture

At every `3 mod4` vertex of the external-nonresidue factor cycle:

1. if the FAB target is hit, the prime is solved;
2. if the target is missed with **even** defect index, the outgoing nonresidue edge is necessarily visible and the quotient index satisfies the sharp mass bound
   \[
   n\ge2E_q(C)+4;
   \]
3. if the target is missed with **odd** defect index, the nonresidue edge may be hidden inside the stabilizer, and the prime-index/cubic defect theorems control the first cases.

Thus the remaining all-prime problem splits naturally into:

\[
\boxed{
\text{odd high-power-residue defects}
\quad\text{versus}\quad
\text{even visible-edge defects with growing index}.}
\]

A universal closure theorem can now attack these two branches separately rather than treating all fixed-`q` placement failures as one undifferentiated phenomenon.
