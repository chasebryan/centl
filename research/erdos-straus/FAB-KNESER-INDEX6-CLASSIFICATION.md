# Exact index-6 FAB Kneser defect classification

**Status:** proved universal classification in the external-nonresidue prime-shift lane  
**Date:** 2026-08-15  
**Depends on:** `FAB-KNESER-DIVISOR-DEFECT.md`, `FAB-KNESER-PRIME-INDEX-DEFECT.md`, `SHIFTED-NONRESIDUE-TRANSFER.md`  
**Claim boundary:** classifies every failed fixed-q FAB box whose exact stabilizer quotient has order six. It does not prove that all possible stabilizer indices are impossible and therefore does not prove Erdős-Straus.

---

## 1. Setup

Let `p` be a Mordell-hard prime and let

\[
q\equiv3\pmod4
\]

be a prime with

\[
\left(\frac qp\right)=-1.
\]

Put

\[
C=\frac{p+q}{4}=\prod_i r_i^{e_i}
\]

and let

\[
R=\left\{\prod_i r_i^{z_i}\pmod q:-e_i\le z_i\le e_i\right\}
\]

be the signed divisor box in

\[
G=(\mathbb Z/q\mathbb Z)^\times.
\]

Assume the exact FAB target

\[
\tau=-p^{-1}\pmod q
\]

is missed.

Let

\[
H=\operatorname{Stab}(R)
\]

and assume

\[
\boxed{[G:H]=6.}
\]

Because `G` is cyclic, the quotient

\[
\bar G=G/H
\]

is cyclic of order six.

By definition of `H` as the **full** stabilizer of `R`, the image

\[
\bar R=R/H
\]

has trivial stabilizer in `\bar G`.

---

## 2. Order-two projections are impossible

Suppose a prime factor `r_i|C` has image

\[
\bar r_i\in\bar G
\]

of order two.

For every exponent `e_i>=1`, its local signed set in the quotient is

\[
\{\bar r_i^{-e_i},\ldots,1,\ldots,\bar r_i^{e_i}\}
=\{1,\bar r_i\},
\]

which is exactly the order-two subgroup of `\bar G`.

Multiplying any set by this local set makes the resulting product set invariant under that order-two subgroup.

Hence `\bar R` would have a nontrivial stabilizer, contradicting the fact that `H` was the full stabilizer of `R`.

Therefore:

\[
\boxed{\operatorname{ord}(\bar r_i)\ne2\quad\text{for every }r_i|C.}
\]

---

## 3. Order-three projections are impossible

The same argument applies to an image of order three.

If

\[
\operatorname{ord}(\bar r_i)=3,
\]

then already for `e_i>=1` the exponent interval `[-e_i,e_i]` covers all three powers, so the local set is the complete order-three subgroup

\[
\{1,\bar r_i,\bar r_i^2\}.
\]

Its presence would force `\bar R` to be invariant under that subgroup, again contradicting trivial stabilizer.

Thus:

\[
\boxed{\operatorname{ord}(\bar r_i)\ne3\quad\text{for every }r_i|C.}
\]

Consequently every prime factor of `C` either lies in `H` or projects to an element of exact order six.

---

## 4. Kneser room for order-six factors

For an order-six image, the local Kneser contribution is

\[
\min(2e_i+1,6)-1.
\]

The index-six defect budget from `FAB-KNESER-DIVISOR-DEFECT.md` is

\[
\sum_i(s_i-1)\le4.
\]

Hence:

- `e_i=1` contributes `2`;
- `e_i=2` contributes `4`;
- `e_i>=3` contributes `5`, impossible.

Therefore the only Kneser-allowed nontrivial patterns are:

1. one order-six factor of exponent one;
2. one order-six factor of exponent two;
3. two order-six factors, both of exponent one.

All remaining prime factors must lie in `H`.

---

## 5. Quadratic character kills the even patterns

Because

\[
q\equiv3\pmod4
\]

and `(q/p)=-1`, quadratic reciprocity gives

\[
\left(\frac pq\right)=-1.
\]

Since `4` is a square,

\[
\boxed{\left(\frac Cq\right)=-1.}
\]

Thus `C` is a quadratic nonresidue modulo `q`.

Now `H` has index six in a cyclic group. Every element of `H` is a square because

\[
H=G^6\subseteq G^2.
\]

An order-six quotient element is represented by an odd exponent in the quotient and therefore carries the nontrivial quadratic parity.

### One exponent-two exception

If the only nontrivial projected factor has exponent two, its quotient contribution to `C` is a square. Every other factor lies in `H` and is also a square.

Therefore `C` would be a quadratic residue, contradiction.

### Two simple order-six exceptions

Let their quotient classes be generators `x` and `y` of `C_6`.

Every generator is either `g` or `g^{-1}` for a fixed quotient generator `g`. Thus

\[
xy\in\{g^2,1,g^{-2}\},
\]

which always has even quotient exponent and is quadratic-residue-side.

Again all remaining factors lie in `H`, so `C` would be a quadratic residue, contradiction.

Hence both even patterns are impossible.

---

## 6. Exact classification theorem

### Theorem

Under the setup above, if the fixed-q FAB divisor box fails and its full stabilizer has quotient index six, then there is exactly one prime factor

\[
\boxed{r\parallel C}
\]

such that

\[
\boxed{\operatorname{ord}_{G/H}(rH)=6.}
\]

Every other prime factor of `C` lies in `H`:

\[
\boxed{s|C,\ s\ne r\Longrightarrow s\in H.}
\]

Equivalently, in the sixth-power quotient, the entire shifted factorization has exactly one simple primitive order-six defect.

Since `G` is cyclic and `H=G^6`, this can be stated as:

\[
\boxed{
C=r\cdot U,
\qquad
v_r(C)=1,
\qquad
U\text{ is supported entirely on sixth-power residues mod }q,
}
\]

where `r mod q` has exact order six in `G/G^6`.

---

## 7. Quotient shape of the failed box

Let `x=rH`, a generator of the order-six quotient.

All other local sets collapse to the identity coset, while the exceptional simple factor contributes

\[
\{x^{-1},1,x\}.
\]

Therefore

\[
\boxed{
R/H=\{x^{-1},1,x\}.
}
\]

The FAB target is quadratic-residue-side. In `C_6`, the quadratic-residue subgroup is

\[
\{1,x^2,x^4\}.
\]

Because the target is missed, it cannot be the identity coset already present in `R/H`. Hence its quotient class is exactly one of

\[
\boxed{x^2\text{ or }x^4.}
\]

Thus the index-six failure is a rigid three-coset picture:

\[
\boxed{
\text{available}=\{x^{-1},1,x\},
\qquad
\text{target}\in\{x^2,x^4\}.
}
\]

There is no other index-six geometry.

---

## 8. Why this matters for descent

At an external nonresidue vertex `q`, `EXTERNAL-NR-FACTOR-CYCLE.md` guarantees a prime factor of `C` that is also a quadratic nonresidue modulo `p`.

In an index-six failure, the theorem above says the quotient has exactly one simple factor carrying the nontrivial sixth-power class. All remaining factor mass is invisible in the quotient.

Therefore the descent has a canonical candidate:

- if the unique order-six factor is the external-nonresidue factor, the factor edge is forced through the unique quotient defect;
- if it is not, the external-nonresidue descent factor lies inside `H=G^6`, so it is simultaneously a sixth-power residue modulo `q` and a quadratic nonresidue modulo `p`.

Either way, index six no longer represents an arbitrary mixed character failure. It reduces to one distinguished simple factor and a sixth-power-residue background.

The next useful classification targets are indices `10` and `18`, which are the other recurrent mixed defects seen in proof-mining and should admit analogous exact-stabilizer reductions.
