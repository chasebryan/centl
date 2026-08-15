# Exact index-six normal form for the combined FAB targets

**Status:** proved theorem  
**Date:** 2026-08-15  
**Depends on:** `FAB-TWO-TARGET-KNESER.md`, `SHIFTED-NONRESIDUE-TRANSFER.md`, `EXTERNAL-NR-FACTOR-CYCLE.md`  
**Claim boundary:** classifies the first possible combined fixed-shift Kneser defect. It does not prove that index-six defects cannot occur, and therefore does not prove Erdős--Straus.

---

## 1. Setup

Let `p` be Mordell-hard and let `q<p` be an external quadratic-nonresidue prime with

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
G=(\mathbb Z/q\mathbb Z)^\times,
\]

and let

\[
R=\mathcal R_q(C)
\]

be the signed divisor box.

Assume that both exact solution targets are missed:

\[
\boxed{-p^{-1}\notin R,\qquad -1\notin R.}
\]

Let

\[
H=\operatorname{Stab}(R)
\]

and assume the first possible combined index:

\[
\boxed{[G:H]=6.}
\]

By `FAB-TWO-TARGET-KNESER.md`, the two-target defect budget is

\[
\boxed{
\sum_i(s_i-1)\le3,
}
\]

where

\[
s_i=\min(2e_i+1,\operatorname{ord}_{G/H}(r_iH)).
\]

Because `G` is cyclic, the quotient

\[
\boxed{G/H\cong C_6.}
\]

Since `H` has index six, it is the unique sixth-power subgroup

\[
\boxed{H=G^6.}
\]

---

## 2. Local contributions in C6

Write the quotient additively as `Z/6Z`.

A prime factor whose image is trivial contributes `0` to the Kneser budget.

For a nontrivial image there are only three possible orders.

### Order two

The local signed interval projects to

\[
\{0,3\},
\]

for every positive exponent. Hence

\[
\boxed{s_i-1=1.}
\]

### Order three

The local signed interval already fills

\[
\{0,2,4\},
\]

so

\[
\boxed{s_i-1=2.}
\]

### Order six

If `e_i=1`, the local image is

\[
\{0,g,-g\}
\]

for a generator `g` of `C_6`, giving

\[
\boxed{s_i-1=2.}
\]

If `e_i>=2`, then

\[
s_i\ge5,
\]

and therefore

\[
\boxed{s_i-1\ge4,}
\]

which exceeds the entire two-target budget.

Thus every order-six factor in a combined index-six defect must occur to exponent exactly one.

---

## 3. Aperiodicity forces an order-six factor

Pass to

\[
\bar R=R/H\subseteq C_6.
\]

Because `H` is the full stabilizer of `R`, the quotient set `bar R` has trivial stabilizer.

Suppose no prime factor has order six in the quotient.

Then every nontrivial local set is one of the two subgroups

\[
\{0,3\}
\quad\text{or}\quad
\{0,2,4\}.
\]

If only order-two factors occur, their sum remains the order-two subgroup and has nontrivial stabilizer.

If only order-three factors occur, their sum remains the order-three subgroup and has nontrivial stabilizer.

If both types occur, their sum is all of `C_6`, so neither target can be missed.

All three possibilities contradict the assumed combined defect.

Therefore:

\[
\boxed{\text{at least one prime factor has order six modulo }H.}
\]

---

## 4. The order-six factor is unique

One order-six factor already consumes two units of the budget.

A second order-six or order-three factor would consume at least two more units, violating

\[
\sum_i(s_i-1)\le3.
\]

The only possible additional nontrivial local factor would therefore have order two, contributing one unit.

But adding the order-two local set to an order-six `e=1` local set gives

\[
\{0,g,-g\}+\{0,3\}=C_6.
\]

Indeed, after choosing `g=1`, the two sets are

\[
\{0,1,5\}
\quad\text{and}\quad
\{0,3\},
\]

whose sum is

\[
\{0,1,2,3,4,5\}.
\]

That would hit both targets.

Hence no additional nontrivial quotient factor can occur.

### Theorem — single primitive sextic defect

A combined index-six failure has exactly one prime factor

\[
\boxed{r\mid C}
\]

outside `H=G^6`. It satisfies

\[
\boxed{v_r(C)=1}
\]

and

\[
\boxed{\operatorname{ord}_{G/H}(rH)=6.}
\]

Every other prime factor of `C` lies in `G^6`.

Equivalently,

\[
\boxed{
\bar R=\{H,rH,r^{-1}H\}.
}
\]

---

## 5. Residue interpretation

Because `rH` has order six, `r` is neither a square nor a cube modulo `q`:

\[
\boxed{
\left(\frac rq\right)=-1,
\qquad
r\notin G^3.
}
\]

Every other prime factor `s|C` lies in `G^6`, hence is simultaneously a square and a cube modulo `q`.

Thus the shifted integer has the exact factor pattern

\[
\boxed{
C=r\,S,
}
\]

with

\[
\boxed{
v_r(C)=1,}
\]

where every prime factor of `S` is a sixth-power residue modulo `q`.

Since an index-six subgroup exists only when

\[
6\mid q-1,
\]

and `q≡3 mod4`, necessarily

\[
\boxed{q\equiv7\pmod{12}.}
\]

---

## 6. The exceptional prime is the unique external nonresidue factor

For every prime factor `s` of

\[
C=\frac{p+q}{4},
\]

the shifted-nonresidue transfer theorem gives, because `q≡3 mod4`,

\[
\boxed{
\left(\frac sp\right)
=
\left(\frac sq\right).
}
\]

All prime factors of `S` are sixth powers modulo `q`, so they are quadratic residues modulo `q` and therefore quadratic residues modulo `p`.

The exceptional factor `r` is a quadratic nonresidue modulo `q`, hence

\[
\boxed{
\left(\frac rp\right)=-1.
}
\]

Therefore `r` is not merely one possible outgoing edge in the external-nonresidue factor graph. It is the **unique external-nonresidue prime factor** of `C`.

Thus an index-six combined failure forces the edge

\[
\boxed{q\longrightarrow r}
\]

uniquely, with

\[
\boxed{r\ne q,\qquad r<p.}
\]

The former nondeterministic factor descent becomes deterministic at the first surviving combined defect.

---

## 7. Positions of the two missed targets

In the quotient `C_6`, the Type-II target

\[
-1H
\]

is the unique element of order two, i.e. class `3`.

The box occupies only

\[
\{0,1,5\}
\]

after choosing the exceptional generator orientation.

The Type-I target is a quadratic residue, so its quotient class is even. Because it is missed, it cannot be class `0`. Therefore

\[
\boxed{
(-p^{-1})H
\text{ has quotient class }2\text{ or }4,
}
\]

and hence exact quotient order three.

So the complete six quotient classes separate as

\[
\boxed{
\begin{array}{c|c}
\text{classes hit by }R & 0,1,5\\
\hline
\text{Type-II miss} & 3\\
\text{Type-I miss} & 2\text{ or }4
\end{array}}
\]

with the remaining class `4` or `2` also absent.

---

## 8. Strategic consequence

The first possible combined Kneser obstruction is therefore not a general index-six factorization pattern. It is a one-prime defect:

\[
\boxed{
\frac{p+q}{4}
=
 r\cdot S,
}
\]

where

1. `r` occurs exactly once;
2. `r` is simultaneously a quadratic and cubic nonresidue modulo `q`;
3. every prime factor of `S` is a sixth power modulo `q`;
4. `r` is the unique external quadratic-nonresidue factor relative to `p`;
5. the external factor cycle is forced to take the edge `q -> r`.

This is the next descent object.

The next theorem target is to show that this primitive sextic defect cannot persist around the external-nonresidue factor cycle, or that its forced successor `r` produces a fixed shift whose combined defect index is strictly larger and has correspondingly less Kneser room.
