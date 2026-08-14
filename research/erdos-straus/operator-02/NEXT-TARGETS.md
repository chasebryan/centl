# Operator-02 Next Targets

**Status:** proposed analysis queue  
**Date:** 2026-08-14  
**Constraint:** all work remains inside `operator-02/`; no modification of parent documents or scripts

---

## Priority 1 — Fiber-kernel residual structure (highest leverage)

**Goal.** Produce a clean description of the possible residual prime sets that survive exact fiber peeling on the already-verified k ≤ 1200 (and later k ≤ 1500) corpus.

**Method.**
- Work exclusively from the published fiber-peeling theorem and the diagnostic observations already recorded in the parent frontier note.
- Catalog the observed residual signatures (e.g., {3,11,13}, {3,5,11,13,17,19,23}, empty kernels).
- Attempt to identify arithmetic invariants that force a residual kernel of a given signature to possess a reduced avoiding assignment.
- Document any candidate invariants or counter-example searches inside this container only.

**Deliverable form.** A new markdown note under this directory (e.g., `FIBER-KERNEL-RESIDUALS.md`) that cites the parent theorem by path and states clearly what is proved versus what is still diagnostic.

---

## Priority 2 — Character-shield + fiber interaction

**Goal.** Examine whether the uniform Jacobi −1 property of traps can be used to constrain or eliminate entire classes of residual fiber kernels without additional search.

**Method.**
- Read `QUADRATIC-TRAP-SIGNATURE.md` and `FIBER-SHADOW-KERNEL.md` together.
- Ask whether forcing all earlier moduli to Jacobi +1 (the shield construction) interacts cleanly with the surviving small-prime coordinates.
- Record any positive or negative structural observations here.

---

## Priority 3 — Ancestry family q = 5

**Goal.** Begin extraction of a necessary-and-sufficient condition for full shadowing in the family k = 5j − 1.

**Method.**
- Use only the arithmetic relation already stated in the parent documents (4k − 1 = 5(4j − 1)).
- Examine the observed full / partial / absent cases as diagnostic data.
- Attempt to isolate the precise arithmetic condition on j that forces the fiber inclusion.

**Caution.** Do not extrapolate the 130 observed full-shadow points into a universal claim. The parent documents already note the existence of partial and absent cases.

---

## Priority 4 — Support for the pending k ≤ 1500 run

**Goal.** Prepare analysis scaffolding so that, once the primary automation finishes the k ≤ 1500 certificate, Operator-02 can rapidly produce a residual-kernel report without touching the primary evidence bundle.

**Method.**
- Pre-define the fields and summary statistics that will be extracted from any future fiber-kernel output.
- Keep the scaffolding inside this container.

---

## Explicit non-goals

- Do not re-implement or alter the primary probes (`direct_shadow_completeness_probe.py`, `shadow_fiber_kernel_analyzer.py`, etc.).
- Do not modify any `.md` or `.py` file outside `operator-02/`.
- Do not publish claims that exceed the finite ranges already certified by the primary program.
- Do not treat failed bounded selectors as counterexamples.

---

## Workflow discipline

Every new document created under `operator-02/` will:

1. State its date and Operator-02 authorship.
2. Cite parent documents by relative path only.
3. Separate proved statements from diagnostic observations.
4. Explicitly restate the inherited claim boundaries when discussing open targets.
