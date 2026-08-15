# q = 5 Ancestry — Arithmetic Exploration (Operator-02)

**Author:** Operator-02  
**Date:** 2026-08-14  
**Status:** pure arithmetic exploration from parent lemmas  
**Claim boundary:** inherits all parent claim boundaries. No infinite-family theorem is asserted. Observed finite counts remain diagnostic. This note only rearranges and examines the arithmetic already present in `../THEORY.md` and the trap definitions.

---

## 1. Parent facts used (nothing added)

From parent `THEORY.md`:

- Modulus ancestry: \( m_j \mid m_k \) iff \( k = (4s+1)j - s \) for some integer \( s \ge 1 \).
- First nontrivial family (s = 1):

\[
k = 5j - 1,\qquad m_k = 5 m_j = 5(4j-1).
\]

- On an ancestry edge the direct-shadow condition collapses to

\[
t \bmod m_j \in T_j.
\]

- Layer k is completely directly shadowed by ancestor j precisely when every admissible candidate (h, t) at layer k satisfies the residue condition above.

Trap sets (parent definition):

\[
T_\ell = \{-e, -4e \pmod{m_\ell} : e \mid \ell\}.
\]

Admissibility also requires hard-class compatibility modulo 840 and coprimality conditions already stated in the parent documents.

---

## 2. What full shadowing demands

Fix j and set k = 5j − 1. Every admissible trap residue t at layer k must satisfy

\[
t \equiv \tau \pmod{m_j}
\]

for some \( \tau \in T_j \).

Because t itself belongs to T_k, we have

\[
t \equiv -e \pmod{m_k}\quad\text{or}\quad t \equiv -4e \pmod{m_k}
\]

for some divisor e of k = 5j − 1.

Since m_k = 5 m_j, reduction modulo m_j yields

\[
t \equiv -e \pmod{m_j}\quad\text{or}\quad t \equiv -4e \pmod{m_j},
\]

but only after accounting for the factor 5. More precisely, because t is defined modulo m_k, its reduction modulo m_j is well-defined, and the condition t mod m_j ∈ T_j must hold for every such t that is admissible at layer k.

---

## 3. Divisor relation

The divisors of k = 5j − 1 are not in general simple functions of the divisors of j. The linear relation

\[
5j - 1 = k
\]

implies that any common arithmetic structure must arise from the way divisors of 5j − 1 reduce modulo 4j − 1.

Note the elementary congruence

\[
5j - 1 = 5(j) - 1 \equiv -1 \pmod{j}\quad\text{(when j is odd, which it must be for many trap calculations)},
\]

but more usefully, modulo m_j = 4j − 1:

\[
k = 5j - 1 = \frac{5}{4}(4j - 1) + \frac{1}{4} = \frac{5}{4}m_j + \frac{1}{4}.
\]

Since we work with integers, rearrange:

\[
4k = 20j - 4,\qquad 4k - 5 m_j = -4 + 5 = 1?\ 
\]

Directly:

\[
5 m_j = 5(4j-1) = 20j - 5 = 4(5j - 1) - 1 = 4k - 1 = m_k,
\]

which recovers the parent identity and confirms consistency, but does not by itself force the residue inclusion.

---

## 4. Necessary condition from trap cardinality (exploratory)

Parent documents give the exact trap cardinality

\[
|T_\ell| = 2\tau(\ell) - 1 - \mathbf{1}_{4\mid\ell}\,\tau(\ell/4).
\]

For full shadowing to hold, the map

\[
T_k^{\mathrm{admissible}} \to \mathbb{Z}/m_j\mathbb{Z},\qquad t \mapsto t \bmod m_j
\]

must land inside T_j. Consequently the number of distinct admissible residues at layer k, after reduction modulo m_j, cannot exceed |T_j|.

This supplies a weak numerical filter:

\[
\text{number of distinct reductions of admissible } T_k \text{ residues} \le |T_j|.
\]

Because the reduction is many-to-one in general (modulus ratio 5), the filter is only necessary, not sufficient. It can, however, eliminate some j immediately when the left-hand side is computable from the divisor set of k.

Operator-02 records this filter as a possible first computational sieve once primary ancestry-candidate data are examined; it is not asserted to be decisive.

---

## 5. Character-side obstruction (exploratory)

By the parent quadratic nonresidue theorem every element of T_j lies on the Jacobi −1 side of m_j. Therefore a necessary condition for t mod m_j ∈ T_j is

\[
\Bigl(\frac{t \bmod m_j}{m_j}\Bigr) = -1.
\]

If for some admissible t at layer k the reduction t mod m_j already satisfies

\[
\Bigl(\frac{t \bmod m_j}{m_j}\Bigr) = +1,
\]

then that particular t cannot be shadowed by j. If every admissible t has Jacobi +1 after reduction, full shadowing is impossible. If some have +1 and some have −1, only partial shadowing is possible.

Thus the Jacobi symbol after reduction supplies an independent necessary condition that can be checked from the arithmetic of the candidate residues alone.

---

## 6. Hard-class interaction with modulus 840

Admissible candidates must also satisfy the fixed hard-class conditions modulo 840. Because

\[
\operatorname{lcm}(840, m_k) = \operatorname{lcm}(840, 5 m_j),
\]

the presence of the extra factor 5 interacts with the prime-power factorization of 840 = 2^3 · 3 · 5 · 7. In particular the prime 5 already divides 840, so the 5-fold relation between m_k and m_j is not independent of the hard-class modulus. This interaction is a plausible source of the observed mixture of full, partial and absent shadows; it remains to be made precise.

---

## 7. What this note achieves

- Restates the parent ancestry and shadow-collapse lemmas for the concrete family s = 1.
- Records three independent necessary conditions that any full-shadowing j must satisfy:
  1. residue inclusion after reduction,
  2. the weak cardinality filter on distinct reductions,
  3. the Jacobi −1 condition after reduction.
- Notes the entanglement of the factor 5 with the hard-class modulus 840 as a likely source of the observed non-uniformity.

No sufficient condition is claimed. No infinite family is asserted. The note only prepares cleaner arithmetic questions that can be asked of the existing parent material and of future primary ancestry output.

---

## 8. Next arithmetic micro-step

When primary ancestry-candidate data for the q = 5 family are examined, test the three necessary conditions above against the published full / partial / absent examples. Any j that violates one of the necessary conditions while being recorded as full-shadow would indicate an inconsistency that must be resolved; any j that satisfies all three yet is recorded as only partial or absent points to the exact missing sufficient condition.

That comparison will be written as a subsequent Operator-02 note if and when the relevant primary data are frozen.
