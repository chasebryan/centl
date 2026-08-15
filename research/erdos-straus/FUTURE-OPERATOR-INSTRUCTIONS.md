# Future Operator Instructions

**Date written:** 2026-08-15  
**Scope:** Erdős-Straus / Type A/B / DSC-P program in `research/erdos-straus/`  
**Authority:** continue theorem work; repository is the ledger

---

## Mission

Advance Type A/B shadow structure toward universal Direct-Shadow Completeness. Do not claim Erdős-Straus, full López coverage, or universal DSC-P without a complete proof on `main` with explicit claim boundaries.

---

## Hard rules

1. Repository first — no result only in chat.
2. Claim boundaries on every theorem file.
3. Finite ≠ universal.
4. No fake solutions.
5. Prefer exact arithmetic (CENTL when available; exact rationals otherwise under the same contract as `docs/NUMERICS.md`).

---

## Priority order

### P0 — Close the residual C1 gap

Files: `C1-ESCAPE-CORE.md`, `C1-PULLBACK-CARDINALITY.md`

**Proved:**
- `|R| ≤ |T_j|`
- `0 ∉ T_j`
- `ψ` injective, image = progression `≡ r (mod g)`
- pigeonhole when `|T_j| < φ(q)`
- zero-slot penalty for prime `q`
- finite non-cover certificate `j ≤ 2500`

**Open:**
- `φ(q) ≤ |T_j|` and `0 ∉ R` ⇒ still `U \ R ≠ ∅` via two-box / `-D_j` geometry

**Suggested attack:**
1. Use `T ⊆ -D` so pullbacks lie in a low-rank box image, not an arbitrary set.
2. Exhaust all `q` with `φ(q) ≤ 200` against the two-box constraints (finite list of `q`).
3. Promote C1 when gap closes.

### P1 — C1 theorem document

`C1-THEOREM.md` with full proof chain once gap is closed.

### P2 — Bounded `|N^{act}| ≥ 2`

### P3 — Ancestry rigidity family continuation

### P4 — Mixed-box support-2

### P5 — Atom-to-shadow

---

## Edge files

`CURRENT-FRONTIER.md`, `DIAMOND.md`, `CLASS-C-RESIDUAL-CORE.md`, `CLASS-C-C1-SINGLE-ACTIVE.md`, `C1-ESCAPE-CORE.md`, `ERDOS-STRAUS-WALL.md`, `QUOTIENT-*-RIGIDITY.md`, `MULTIPLICATIVE-TRAP-QUOTIENT.md`

---

## Success criterion

A file on `main` that proves the residual gap, or reduces it to an explicit finite list of moduli with machine-checked escape, or produces a sharp counterexample forcing a stronger hypothesis.

## Standing order

**Prove that a Type A/B two-box pullback never covers all reduced residues; then promote C1. Keep the wall honest.**
