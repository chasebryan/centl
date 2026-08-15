# Diamond Candidate: Fixed-Negative Pullback Split

**Author:** Operator-02  
**Date:** 2026-08-14  
**Status:** structural observation derived strictly from parent definitions and theorems  
**Novelty claim level:** Operator-02 diamond candidate — a compression of the residual obstruction that follows from combining parent definitions; not previously isolated as a named object in the parent documents  
**Claim boundary:** inherits all parent claim boundaries. This note does not prove DSC-P, López coverage, or the Erdős-Straus conjecture. It does not modify any parent theorem. If the observation is already implicit in primary work, priority remains with the primary program.

---

## 1. Parent material used (nothing altered)

- Character-shield completeness (`../CHARACTER-SHIELD-COMPLETENESS.md`):  
  shield inconsistent ⇔ \(\mathcal N_{k,r} \neq \emptyset\), where

\[
\mathcal N_{k,r}
=
\bigl\{ j < k : \sigma(m_j) \in F_k,\ (r/m_j) = -1 \bigr\}.
\]

- Pullback construction (`../THEORY.md`, `../FIBER-SHADOW-KERNEL.md`, `../ODD-COVERING-BRIDGE.md`):

\[
q_j = \frac{m_j}{\gcd(L, m_j)},
\qquad
R_j = \text{forbidden residues for } s \bmod q_j.
\]

- Direct novelty: no single earlier layer covers the candidate progression; in particular the candidate is not directly shadowed by any j.

- Local signature quotient (`../QUADRATIC-SIGNATURE-QUOTIENT.md`): traps occupy the single affine coset \(\chi_m(-1)+H_k\); Jacobi −1 is necessary but not sufficient for being a trap.

---

## 2. The split

Fix a directly novel candidate with progression modulus L and residue r. Consider any layer j ∈ \(\mathcal N_{k,r}\).

### Type I — inactive fixed-negative layer

If

\[
q_j = 1,
\]

then gcd(L, m_j) = m_j, so m_j | L. The entire candidate progression is locked to the single residue r mod m_j. Whether that residue lies in T_j is a yes/no fact about r alone; it does not constrain the free parameter s.

Direct novelty already guarantees the residue is **not** in T_j.  
The layer is Jacobi-negative (that is why it sits in \(\mathcal N_{k,r}\)) but is not a trap hit.  
It contributes **no forbidden set** to the parameter covering problem on s.

### Type II — active fixed-negative layer

If

\[
q_j > 1,
\]

then some prime-power valuation in m_j strictly exceeds the corresponding valuation in L. The layer still imposes a genuine nonempty constraint

\[
s \bmod q_j \in R_j
\]

on the parameter line. These are the only layers inside \(\mathcal N_{k,r}\) that can participate in the residual fiber-kernel covering problem.

---

## 3. Refined residual obstruction

Define the **active fixed-negative core**

\[
\boxed{
\mathcal N^{\mathrm{act}}_{k,r}
=
\bigl\{ j \in \mathcal N_{k,r} : q_j > 1 \bigr\}.
}
\]

Then:

- Layers in \(\mathcal N_{k,r} \setminus \mathcal N^{\mathrm{act}}_{k,r}\) are character-shield obstacles but are already resolved for exact trap avoidance by direct novelty; they do not feed the s-system.
- The only fixed-negative layers that can contribute residual fiber-kernel constraints are those in \(\mathcal N^{\mathrm{act}}_{k,r}\).

Consequently the residual obstruction for Class C may be restated as:

> nonempty fiber shadow kernel **together with** a nonempty active fixed-negative core \(\mathcal N^{\mathrm{act}}_{k,r}\), with exact trap avoidance required only against the layers in that active core (inside their Jacobi −1 regions, and more finely inside their trap-signature cosets).

---

## 4. Why this is a compression

Parent character-shield completeness already reduced inconsistency to the existence of some fixed-only Jacobi-negative layer. The present split further discards every such layer that is valuation-absorbed by L.

Those discarded layers explain why the character shield can fail while the candidate remains exactly trap-free at those moduli: Jacobi −1 is a large half-space; T_j is a much smaller divisor-generated set. Direct novelty has already selected the non-trap point inside that half-space whenever q_j = 1.

What remains for exact residue work is only the active part of the fixed-negative core — the layers that still move when s moves.

---

## 5. Interaction with the full signature quotient

Parent `QUADRATIC-SIGNATURE-QUOTIENT.md` shows that even inside Jacobi −1, a residue is a trap only if its full local Legendre signature lies in the coset \(\chi(-1)+H_j\).

For an active fixed-negative layer, the parameter s still varies the residue x = r + L s modulo the residual part of m_j. The local signature at primes dividing q_j can therefore change with s. Exact trap avoidance on such a layer is equivalent to keeping the induced local signature outside the trap coset (or, more strongly, outside T_j itself).

The fiber kernel is precisely the set of residual primes that still participate in those varying local signatures after all peelable coordinates have been removed.

---

## 6. Falsifiable consequences for primary census

When primary output records, for each Class-C candidate:

1. the set \(\mathcal N_{k,r}\),
2. the corresponding pullback moduli q_j,
3. the residual fiber kernel,

Operator-02 predicts:

- |\(\mathcal N^{\mathrm{act}}_{k,r}\)| ≤ |\(\mathcal N_{k,r}\)|, often strictly smaller;
- residual fiber-kernel constraints arise only from layers in \(\mathcal N^{\mathrm{act}}_{k,r}\) (together with any non-fixed-negative layers that survived peeling — but those are already Jacobi-safe or free-prime layers handled by the shield when solvable);
- if |\(\mathcal N^{\mathrm{act}}_{k,r}\)| = 0 while \(\mathcal N_{k,r}\) ≠ ∅, then the character shield fails for purely inactive reasons and the residual fiber kernel, if nonempty, must be explained by other (non-fixed-negative) constraints — a configuration worth isolating.

These are diagnostic predictions, not theorems.

---

## 7. Relation to the diamond architecture

Parent `SHADOW-COVER-GEOMETRY.md` already observed that raw cover mass is typically ≫ 1 yet no union cover occurs — the overlap geometry is essential. The present split is a contribution to that overlap accounting on the character-negative side: a large part of the apparent character obstruction does not enter the parameter covering problem at all.

In project language this is offered as a **diamond inside the residual core**: a further exact reduction of what Class C must still solve, obtained by reading the parent pullback and character-completeness definitions against each other.

---

## 8. What is not claimed

- Not claimed: that \(\mathcal N^{\mathrm{act}}\) is always empty for directly novel candidates.
- Not claimed: that residual kernels vanish when \(\mathcal N^{\mathrm{act}}\) is empty.
- Not claimed: DSC-P or any universal covering prohibition.
- Not claimed: literature priority over the primary program; if the split is already used implicitly in primary analyzers, this note only names and isolates it.

---

## 9. Immediate next Operator-02 work on this diamond

1. Formalize the valuation criterion q_j > 1 in terms of v_p(m_j) > v_p(L) for some p.
2. When primary census data appear, measure |\(\mathcal N\)| vs |\(\mathcal N^{\mathrm{act}}\)| on Class C.
3. Check whether residual kernel primes are always among the primes that witness the valuation excess for layers in \(\mathcal N^{\mathrm{act}}\).
4. Integrate the trap-signature coset (parent quotient theorem) as the precise unsafe set on each active fixed-negative layer.
