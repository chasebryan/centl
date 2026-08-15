# Type I cannot rescue a hard-prime `q=7` Type-II miss

**Status:** proved exact companion to the `q=7` Type-II filter  
**Date:** 2026-08-15  
**Depends on:** `STRONG-ES-Q7-EXACT-FILTER.md`, `ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md`  
**Claim boundary:** identifies the first corridor position at which the two exact targets coincide in obstruction. It does not prove Erdős--Straus.

---

## 1. The two targets at shift `7`

Let `p` be Mordell-hard and put

\[
C=\frac{p+7}{4}.
\]

The unit group modulo `7` is cyclic of order six. Its quadratic-residue subgroup is

\[
Q=\{1,2,4\}.
\]

The Type-II target is

\[
-1\equiv6\pmod7,
\]

a nonresidue. The Type-I target is

\[
-p^{-1}\pmod7.
\]

---

## 2. Forced generator of `Q`

Hard primes satisfy `p≡1\pmod8`, so `2\mid C`. The residue

\[
2\pmod7
\]

generates `Q`:

\[
2,\qquad 2^2\equiv4,\qquad 2^3\equiv1.
\]

Already the local signed set of a single factor `2` is

\[
\{2^{-1},1,2\}=\{4,1,2\}=Q.
\]

Thus for every Mordell-hard prime the signed box contains the full quadratic-residue subgroup.

---

## 3. Every hard class is a residue modulo `7`

The six Mordell-hard classes satisfy

\[
p\bmod7\in\{1,2,4\}=Q.
\]

Hence

\[
\boxed{\Bigl(\frac p7\Bigr)=+1.}
\]

Because `7≡3\pmod4`, the Type-I target is then a nonresidue:

\[
\Bigl(\frac{-p^{-1}}{7}\Bigr)
=
\Bigl(\frac{-1}{7}\Bigr)
\Bigl(\frac p7\Bigr)^{-1}
=
(-1)\cdot(+1)
=
-1.
\]

Concretely:

\[
\begin{array}{c|c}
p\bmod7 & -p^{-1}\bmod7\\
\hline
1 & 6\\
2 & 3\\
4 & 5
\end{array}
\]

In the first row the two targets coincide. In the other two rows the Type-I target is a primitive order-six class.

---

## 4. Theorem

For a Mordell-hard prime, the following are equivalent:

1. `-1\notin\mathcal R_7(C)`;
2. `-p^{-1}\notin\mathcal R_7(C)`;
3. every prime factor of `C` is a quadratic residue modulo `7`.

### Proof

The existing `q=7` theorem gives `(1)\Leftrightarrow(3)`. Under `(3)` the signed box lies in `Q`, while both targets are nonresidues, so `(3)\Rightarrow(2)`. Conversely, if some prime factor is a nonresidue then the Type-II theorem already produces `-1` in the box, and inversion symmetry is not needed. If one prefers a direct Type-I check: a nonresidue factor together with the already-full subgroup `Q` fills the whole group, which contains both targets. QED.

---

## 5. Consequence

At the second corridor position, Type I contributes **no additional hard-prime coverage** beyond Type II. Combined Erdős--Straus failure at `q=7` is exactly the already-classified Type-II miss.

The first corridor position `q=3` is the same phenomenon: for hard `p` one has `p≡1\pmod3`, so `-p^{-1}\equiv-1\pmod3` and the two targets coincide.

The next prime shift `q=11` is different. There Type I can rescue a Type-II miss; see `Q11-TYPE-I-COMPANION.md`.
