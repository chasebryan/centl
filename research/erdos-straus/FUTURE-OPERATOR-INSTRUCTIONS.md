# Future Operator Instructions

**Date written:** 2026-08-15  
**Scope:** Erdős-Straus / Type A/B / DSC-P program in `research/erdos-straus/`  
**Authority:** continue non-destructive theorem work; repository is the ledger

---

## Mission

Advance the Type A/B shadow program toward universal Direct-Shadow Completeness (DSC-P). Do not claim Erdős-Straus, full López coverage, or universal DSC-P unless a complete proof is written, checked, and deposited on `main` with explicit claim boundaries.

---

## Hard rules

1. **Repository first.** No result exists only in chat. Every lemma, census, and correction lands as a file under `research/erdos-straus/` (or `operator-02/` for parallel analysis notes).
2. **Claim boundaries on every theorem file.** State what is proved and what remains open.
3. **Do not silently rewrite history.** Corrections get new notes that supersede; keep provenance links.
4. **Finite ≠ universal.** A clean census through `k ≤ N` is a certificate for that range only.
5. **No fake solutions.** If the two-box gap is unsolved, say so. If ES is open, say so.

---

## Priority order (descending)

### P0 — Close the C1 gap

File: `C1-PULLBACK-CARDINALITY.md`

**Proved already:**
- `|R| ≤ |T_j|` for the active-layer pullback;
- `φ(q) > |T_j| ⇒` reduced safe residue exists.

**Open:**
- When `φ(q) ≤ |T_j|`, prove the two-box image cannot cover all of `(Z/qZ)^×`.

**Suggested attack:**
1. Classify residual `q` with `φ(q) ≤ 2τ(j)` — these are products of tiny primes only.
2. For each fixed small prime set, expand the two-box equations explicitly mod `q`.
3. Use that traps lie in a single coset of the divisor subgroup (multiplicative trap quotient) so their pullbacks lie in a low-complexity Boolean combination of cosets, not an arbitrary set of size `|T|`.
4. If needed, exhaust `q | ∏_{p≤31} p` by machine and promote the finite classification to a lemma with explicit bound.

### P1 — Promote C1 to a theorem

Once the gap is closed, write `C1-THEOREM.md` with full proof:
character shield → inactive layers safe → active pullback escape → fiber reverse → Dirichlet.

### P2 — Bounded `|N^{act}|`

Extend C1 to `|N^{act}| ≤ B` for small fixed `B` (start with 2).

### P3 — Ancestry rigidity family

Continue odd-prime `s` classifications (`q = 4s+1`). Method is uniform; each new prime is a write-up, not a new idea. Parent files already exist for `s ∈ {3,5,7}` and for `q = 17`.

### P4 — Mixed-box support-2

Finite evidence through `j ≤ 50,000` with zero support-3 counterexamples (`operator-02/MIXED-BOX-SUPPORT-RESULTS.md`). Either prove support ≤ 2 or find the smallest support-3 example and freeze it.

### P5 — Atom-to-shadow census

Bridge multiplicative defect atoms back to earlier-layer shadowing (Coordinator task O2-E).

---

## Files that define the edge

| File | Role |
|------|------|
| `CURRENT-FRONTIER.md` | moving edge |
| `DIAMOND.md` | full synthesis |
| `CLASS-C-RESIDUAL-CORE.md` | residual node |
| `CLASS-C-C1-SINGLE-ACTIVE.md` | C1 attack design |
| `C1-PULLBACK-CARDINALITY.md` | cardinality bound + gap |
| `C1-PARTIAL-THEOREMS.md` | partial lemmas |
| `ERDOS-STRAUS-WALL.md` | honest wall |
| `QUOTIENT-*-RIGIDITY.md` | proved ancestry classifications |
| `MULTIPLICATIVE-TRAP-QUOTIENT.md` | two-box geometry |
| `OPERATOR-COORDINATION.md` | role split |

---

## Coordination protocol

- Parallel analysis notes: `operator-02/` only, unless explicitly authorized to write parent theorems.
- Parent theorem promotion requires: exact statement, proof or certificate, claim boundary, prior-art note, falsifier, link to source notes.
- If the primary coordinator is offline, continue depositing theorems and handoff notes; do not invent a second canonical synthesis track that diverges from `CURRENT-FRONTIER.md` without labeling it provisional.

---

## Success criterion for the next session

A new file on `main` that either:

1. proves the two-box gap and promotes C1, or
2. produces a sharp counterexample showing the gap lemma needs a stronger hypothesis, or
3. reduces the gap to a finite explicit list of residual moduli with machine-checked escape.

Anything else is secondary.

---

## Forbidden outcomes

- Announcing Erdős-Straus solved without a complete deposited proof.
- Equating signature-coset membership with exact trap membership.
- Treating finite selector success as universal DSC-P.
- Editing claim boundaries to hide open problems.

---

## One-sentence standing order

**Prove that a Type A/B two-box pullback never covers all reduced residues, then promote C1; until then, keep the wall honest.**
