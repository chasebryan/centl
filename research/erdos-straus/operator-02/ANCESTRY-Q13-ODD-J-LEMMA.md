# q = 13 Odd-j Blocking Lemma

**Author:** Operator-02  
**Date:** 2026-08-15  
**Status:** proved elementary lemma  
**Type:** THEOREM CANDIDATE component (lemma proved; full classification still open)  
**Parent style:** same normalized-set arguments as `../PRIME-CHILD-SHADOWS.md` §6 Case 1 and `../QUOTIENT-9-RIGIDITY.md`

---

## Lemma

Let j be a positive odd integer, and set

\[
K = 13j - 3,\qquad m = 4j - 1.
\]

If K is composite, then

\[
T_K \bmod m \not\subseteq T_j.
\]

In particular, there is no unrestricted full direct shadow along q = 13 when the source depth j is odd and the child is composite.

---

## Proof

Since j is odd, 13j is odd and 3 is odd, so K is even. As K is composite and K ≥ 4 (the smallest odd j with composite K in range already exceeds 4), we have 2 | K, hence

\[
-2 \in T_K.
\]

It suffices to show −2 ∉ T_j, i.e. 2 ∉ S_j where

\[
S_j = \{e,\, 4e \bmod m : e \mid j\}.
\]

Because j is odd, 2 does not divide j, so 2 is not among the plain divisor residues e|j.

For e | j with e < j,

\[
4e \le 4(j-1) = 4j - 4 = m - 3,
\]

so 4e mod m is an even integer in {4, 8, …, m−3}, never equal to 2.

For e = j,

\[
4j \equiv 1 \pmod m,
\]

so the wrapped residue is 1 ≠ 2.

Therefore 2 ∉ S_j, so −2 ∉ T_j. Full shadowing fails. QED.

---

## Finite check

For every odd j ≤ 1999, direct computation confirms 2 ∉ S_j (consistent with the lemma, not a substitute for the proof).

---

## Role in the q = 13 classification candidate

Combined with the prime-child theorem and the 3p divisor argument:

- odd j + composite K ⇒ no unrestricted full shadow (**this lemma**);
- K = 3p with p prime and 3|j ⇒ unrestricted full shadow (**elementary divisor residues**);
- K prime ⇒ unrestricted full shadow (**parent prime-child theorem**).

Remaining open for the full classification: when j is even, show that the only composite full shadows are those with K = 3p.

---

## Claim boundary

Lemma is elementary and restricted to odd source depth. Full q = 13 classification remains open. Primary priority absolute if promoted.
