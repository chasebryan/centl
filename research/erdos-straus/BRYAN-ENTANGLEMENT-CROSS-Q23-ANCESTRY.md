# Bryan Entanglement Cross — q23 ancestry pilot

**Status:** exact finite BEC telemetry over the live post-k23 ancestry audited in `Q23-BLOCKED-PHASE-ANCESTRY-AUDIT.md`  
**Date:** 2026-08-16  
**Primary verifier:** `audit_q23_blocked_phase_ancestry.py`  
**Depends on:** `BRYAN-ENTANGLEMENT-CROSS.md`, `Q23-BLOCKED-PHASE-ANCESTRY-AUDIT.md`, exact signed-box Lane-I semantics  
**Claim boundary:** the arithmetic first-hit statements are exact on the stated finite prefixes. The BEC labels are observational annotations over those exact statements. They are not a proof rule, a pruning rule, a density theorem, or a universal shift bound.

---

## 1. Why ancestry changes the BEC path

The q23 blocked-phase destination atlas is a controlled **destination cross-section**.

At that research level the experiment can be described as

```text
D  remove the canonical d=23^2 López-A mechanism by the phase obstruction
U  reopen the complete signed-box geometry at the blocked destination
R  observe an exact certificate at that destination
```

so the experimental analysis path is `DUR`.

However, `Q23-BLOCKED-PHASE-ANCESTRY-AUDIT.md` proves that none of the 148 simultaneous k19/k23 survivors in the audited prefixes actually reaches its distant blocked q23 destination as a live decomposition state. Every one terminates earlier, at its first post-k23 hit.

Therefore `DUR` must **not** be stored as the live state-machine history of those primes.

The ancestry-correct BEC path begins at the simultaneous k19/k23 survivor and follows the actual admissible shifts

```text
27, 31, 35, 39, 43, 47, 51, 55, ...
```

Each exact miss is

`L = ←⊖`,

and the first exact Type-I/II certificate is

`R = →⊕`.

Thus every live path in this audit is of the form

\[
\boxed{L^jR}.
\]

This is the first ancestry-correct BEC path family pinned by the research machine.

---

## 2. Exact finite path distribution

The ancestry audit contains 148 simultaneous k19/k23 survivors.

Their first post-k23 hits are exactly

```text
k=27   64
k=31   64
k=35    7
k=39    4
k=43    5
k=47    3
k=55    1
```

The corresponding BEC paths are therefore exactly

```text
R           64
LR          64
LLR          7
LLLR         4
LLLLR        5
LLLLLR       3
LLLLLLLR     1
```

No live path in this finite audit requires more than seven leftward obstruction events before the rightward certificate.

The total directional counts over all 148 live paths are

```text
left obstruction observations   132
right constructions              148
```

These counts are exact consequences of the pinned first-hit histogram.

They are not a probabilistic law and do not imply a universal tendency toward the right direction.

---

## 3. Terminal rightward payload

Every terminal `R` stores the exact arithmetic mechanism rather than only the direction.

Across the 148 survivors:

```text
Type I + Type II   122
Type I only         20
Type II only         6
```

When Type II is present, the complete root geometry at the actual first live exit is

```text
mixed          63
interior-only  49
boundary-only  16
```

with the remaining 20 Type-I-only exits carrying `n/a` Type-II geometry.

Therefore 112 of the 128 Type-II-containing terminal `R` events expose incomparable-root geometry, and 49 are interior-only.

The BEC direction does not replace those distinctions. The correct machine record is conceptually

```text
R(
  k = first exact hit,
  mechanism = Type-I | Type-II | I+II,
  root_geometry = boundary-only | interior-only | mixed | n/a
)
```

The direction says **construction occurred**. The payload says **what exact construction occurred**.

---

## 4. Two different BEC scopes

The q23 program now demonstrates why BEC records require an explicit scope.

### Research-operation scope

This describes how a theorem or experiment manipulates the research space.

Example:

```text
D U R
```

for the blocked-destination experiment:

- restrict one canonical boundary mechanism;
- expand back to the full signed box;
- observe the destination geometry.

### Live-ancestry scope

This describes the exact sequence experienced by one active survivor state.

Example:

```text
L L R
```

means the survivor misses at k27 and k31, then obtains its first exact certificate at k35.

These scopes must never be conflated.

The machine schema should therefore retain

```text
bec_scope = research-operation | live-ancestry
bec_path  = directional word
```

alongside exact theorem provenance.

---

## 5. Immediate theorem consequence for research direction

The distant blocked q23 destination is not the next live transition on these finite ancestry prefixes.

The live target is the compact first-exit support

\[
\boxed{\{27,31,35,39,43,47,55\}}.
\]

In BEC language the question becomes:

> Which exact survivor-state coordinates determine the length and terminal payload of the live word `L^jR`?

This is more precise than asking whether a branch is generally positive or negative.

The exact theorem-mining variables already include

```text
route ancestry
k19_mode = FULL_QR | BARE
R support
k23 rigid support
affine relation 6B-SR=1
q23 valuation phase
factor pattern
```

The desired result is an arithmetic implication such as

```text
exact survivor predicate
    => first hit k=31
    => exact terminal mechanism / root geometry
```

which the BEC layer would summarize as

```text
LR -> R(payload at k31)
```

but the proof itself must remain entirely arithmetic.

---

## 6. Best next split

Because 128 of the 148 audited survivors terminate at k27 or k31, the first BEC-conditioned theorem attack should split the live paths into

```text
R      first hit at k27
LR     first hit at k31
L^jR   later residual, j>=2
```

and ask for exact state predicates distinguishing those three classes.

That is the smallest useful decomposition of the current live machine:

- `R`: immediate construction;
- `LR`: one exact obstruction followed by construction;
- `L^jR`, `j>=2`: the residual gauntlet that still requires explanation.

If an exact theorem can separate `R` and `LR` directly from survivor state, only 20 of the 148 finite specimens remain in the deeper BEC residual.

This is a scheduler observation and theorem-search target, not a universal coverage claim.

---

## 7. Machine invariant

The q23 ancestry pilot fixes the following implementation rule:

```text
never assign BEC history from a later counterfactual destination
when an earlier exact transition has already terminated the branch.
```

BEC history must respect exact ancestry just as the decomposition framework does.

The authoritative order is

\[
\boxed{
\text{exact ancestry}
\to
\text{exact transition sequence}
\to
\text{BEC path}
\to
\text{telemetry / scheduler hypothesis}.
}
\]

That makes the Bryan Entanglement Cross compatible with the machine rather than merely descriptive of isolated endpoint geometry.

Erdős–Straus remains open.
