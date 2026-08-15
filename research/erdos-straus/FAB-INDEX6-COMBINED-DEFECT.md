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

By inversion symmetry this also forces

\[
\boxed{-p\notin R.}
\]

Let

\[
H=\operatorname{Stab}(R)
\]

and assume the first possible combined index:

\[
\boxed{[G:H]=6.}
\]

By `FAB-TWO-TARGET-KNESER.md`, the symmetric combined defect budget is

\[
\boxed{
\sum_i(s_i-1)\le2,
}
\]

where

\[
s_i=\min(2e_i+1,\operatorname{ord}_{G/H}(r_iH)).
\]

Because `G` is cyclic,

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

for every positive exponent, so

\[
\boxed{s_i-1=1.}
\]

### Order three

The local signed interval fills

\[
\{0,2,4\},
\]

and

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

so

\[
\boxed{s_i-1\ge4,}
\]

which is impossible under the budget `2`.

Thus every order-six factor must occur to exponent exactly one.

---

## 3. Aperiodicity forces an order-six factor

Pass to

\[
\bar R=R/H\subseteq C_6.
\]

Because `H` is the full stabilizer of `R`, the quotient set `bar R` has trivial stabilizer.

Suppose no prime factor has order six in the quotient.

Then every nontrivial local set is one of the two proper subgroups

\[
\{0,3\}
\quad\text{or}\quad
\{0,2,4\}.
\]

If only order-two factors occur, their sum remains the order-two subgroup and has nontrivial stabilizer.

If only order-three factors occur, their sum remains the order-three subgroup and has nontrivial stabilizer.

If both types occur, their sum is all of `C_6`, contradicting the target misses.

Therefore

\[
\boxed{\text{at least one prime factor has order six modulo }H.}
\]

---

## 4. The order-six factor consumes the full budget

An order-six factor already contributes exactly `2`, the entire available budget.

Hence **every other prime factor must have trivial image modulo `H`**.

There can be no second order-six factor, no order-three factor, and not even an order-two factor.

Therefore:

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

After orienting the generator `rH` as class `1`,

\[
\boxed{\bar R=\{0,1,5\}\subset C_6.}
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

Thus

\[
\boxed{
C=rS,
\qquad
v_r(C)=1,
}
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

the shifted-nonresidue transfer theorem gives

\[
\boxed{
\left(\frac sp\right)
=
\left(\frac sq\right).}
\]

Every prime factor of `S` is a sixth power modulo `q`, hence a quadratic residue modulo `q` and therefore modulo `p`.

The exceptional factor `r` is a quadratic nonresidue modulo `q`, hence

\[
\boxed{
\left(\frac rp\right)=-1.}
\]

Therefore `r` is the **unique external-nonresidue prime factor** of `C`.

The external factor graph has the forced edge

\[
\boxed{q\longrightarrow r,}
\]

with

\[
\boxed{r\ne q,\qquad r<p.}
\]

At the first surviving combined defect, the formerly nondeterministic factor descent becomes deterministic.

---

## 7. The three missing quotient classes are exact

The quotient box occupies

\[
\boxed{\{0,1,5\}.}
\]

The Type-II target

\[
-1H
\]

is the unique order-two class, namely

\[
\boxed{3.}
\]

The Type-I target `-p^{-1}` is a quadratic residue, so its quotient class is even. It is missed and nontrivial, therefore it is class `2` or `4`.

Its inverse `-p` occupies the other one of those two classes.

Consequently the six quotient classes split **exactly** as

\[
\boxed{
\begin{array}{c|c}
\text{hit by }R & 0,1,5\\
\hline
-p^{-1}H & 2\text{ or }4\\
-1H & 3\\
-pH & 4\text{ or }2
\end{array}}
\]

Thus the three excluded natural targets are precisely the three missing quotient classes.

---

## 8. A small-prime consequence

The unique exceptional factor `r` is a quadratic nonresidue modulo `p`. Mordell-hard primes satisfy

\[
\left(\frac2p\right)
=
\left(\frac3p\right)
=
\left(\frac5p\right)
=
\left(\frac7p\right)=+1.
\]

Therefore none of `2,3,5,7` can be the exceptional factor.

If any of these primes divides

\[
C=\frac{p+q}{4},
\]

it must lie in the sixth-power subgroup modulo `q`.

For example, if

\[
q\equiv7\pmod8,
\]

then `C` is even, so a combined index-six defect forces

\[
\boxed{2\in G^6.}
\]

Since `(2/q)=+1` in this congruence class, this adds the nontrivial requirement that `2` also be a cubic residue modulo `q`.

This supplies an immediate local filter on index-six candidates.

---

## 9. Strategic consequence

The first possible combined Kneser obstruction is a one-prime defect:

\[
\boxed{
\frac{p+q}{4}=rS,
}
\]

where

1. `r` occurs exactly once;
2. `r` is simultaneously a quadratic and cubic nonresidue modulo `q`;
3. every prime factor of `S` is a sixth power modulo `q`;
4. `r` is the unique external quadratic-nonresidue factor relative to `p`;
5. the external factor cycle is forced to take `q -> r`;
6. the quotient box occupies exactly the three classes `0,±1`, while the three natural solution targets occupy exactly the complementary classes.

The next descent problem is therefore sharply defined: transport this primitive sextic defect through the forced successor `r`, including the `r≡1 mod4` case where the natural next admissible shift is composite (`3r`, or another `3 mod4` hard-residue multiplier times `r`).
