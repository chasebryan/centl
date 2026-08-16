# q23 blocked-phase full-ancestry audit

**Status:** exact finite ancestry theorem over the parent blocked-phase atlas prefixes  
**Date:** 2026-08-16  
**Primary verifier:** `audit_q23_blocked_phase_ancestry.py`  
**Depends on:** `Q23-BLOCKED-PHASE-GEOMETRY-ATLAS.md`, `Q23-SQUARE-LIFT-PHASE-SIEVE.md`, exact signed-box Lane-I semantics  
**Claim boundary:** this is an exact finite theorem on the same twenty route-phase prefixes exhausted by the parent atlas. It is not a universal shift ceiling and not an Erdős–Straus proof.

---

## 1. Why the ancestry audit is necessary

The blocked-phase geometry atlas asks a useful controlled question at the distant q23 valuation destination

`k_n = 19 + 92n`.

It requires exact signed-box misses at k19 and k23, then classifies the complete signed box at k_n.

That is a valid destination-geometry cross-section.

It is **not yet a transition of the candidate decomposition framework**, because a framework survivor must also miss every admissible signed-box shift between k23 and k_n. If a prime decomposes at k27 or k31, the later k_n geometry is no longer on its live ancestry.

This verifier adds exactly that missing condition.

---

## 2. Exact finite result

Across the same twenty blocked route-phase prefixes used by the parent atlas:

```text
prime candidates in exact progressions        814
simultaneous k19/k23 signed-box survivors      148
survivors reaching their blocked destination     0
```

Every one of the 148 simultaneous survivors terminates earlier.

Their first post-k23 signed-box hits are exactly:

```text
k=27   64
k=31   64
k=35    7
k=39    4
k=43    5
k=47    3
k=55    1
```

Therefore, on these exact finite prefixes,

`first post-k23 hit <= 55`.

No candidate in the audited survivor set reaches any blocked q23 destination as a live framework state.

This does **not** prove a universal k55 ceiling. It proves the statement exactly for the stated 148 survivors.

---

## 3. Mechanism at the actual first hit

At the ancestry-correct first post-k23 hit, the 148 survivors split as:

```text
Type I + Type II   122
Type I only         20
Type II only         6
```

Thus 128 of 148 actual first exits contain Type II.

For those complete Type-II witness sets, the exact root geometry is:

```text
mixed          63
interior-only  49
boundary-only  16
```

The remaining 20 are Type-I-only and therefore have no Type-II geometry.

So among the 128 ancestry-correct first hits containing Type II:

- 112 expose incomparable-root geometry (`mixed` or `interior-only`);
- 49 are **interior-only**, with no López-comparable Type-II witness at that first live exit;
- 16 are boundary-only.

This is stronger for the candidate framework than inspecting a later blocked destination: incomparable-root Type II is already present at the **actual earliest live decomposition step** for most Type-II-containing exits in this finite specimen.

---

## 4. Exact first-hit support

The first post-k23 hit support is only

`{27,31,35,39,43,47,55}`.

The mass is concentrated at k27 and k31:

`128 / 148`

of the simultaneous k19/k23 survivors terminate at one of those two shifts.

The deepest audited survivor reaches only k55.

This changes the immediate research target. The q23 valuation destination remains useful as a controlled arithmetic cross-section, but the live decomposition machine should first explain the compact early-exit gauntlet.

---

## 5. Per-cell exact audit

### Route A: q17 + q23

| n | destination k | prime candidates | k19/k23 survivors | first post-k23 hits |
|---:|---:|---:|---:|---|
| 1 | 111 | 10 | 2 | 31:2 |
| 2 | 203 | 13 | 4 | 31:4 |
| 4 | 387 | 61 | 12 | 27:6, 31:3, 39:1, 43:1, 47:1 |
| 7 | 663 | 13 | 2 | 31:2 |
| 9 | 847 | 62 | 12 | 27:3, 31:7, 35:1, 39:1 |
| 10 | 939 | 37 | 9 | 27:5, 31:3, 43:1 |
| 13 | 1215 | 59 | 7 | 27:4, 31:3 |
| 16 | 1491 | 2 | 1 | 31:1 |
| 19 | 1767 | 14 | 4 | 27:1, 31:2, 43:1 |
| 22 | 2043 | 115 | 19 | 27:12, 31:7 |

### Route B: q23 + q47

| n | destination k | prime candidates | k19/k23 survivors | first post-k23 hits |
|---:|---:|---:|---:|---|
| 1 | 111 | 5 | 2 | 27:1, 31:1 |
| 2 | 203 | 3 | 1 | 27:1 |
| 4 | 387 | 39 | 7 | 27:2, 31:2, 35:2, 39:1 |
| 7 | 663 | 56 | 8 | 27:2, 31:5, 47:1 |
| 9 | 847 | 99 | 17 | 27:7, 31:7, 35:1, 39:1, 55:1 |
| 10 | 939 | 38 | 8 | 27:3, 31:4, 47:1 |
| 13 | 1215 | 66 | 6 | 27:3, 31:2, 35:1 |
| 16 | 1491 | 6 | 2 | 27:1, 31:1 |
| 19 | 1767 | 87 | 16 | 27:8, 31:6, 35:1, 43:1 |
| 22 | 2043 | 29 | 9 | 27:5, 31:2, 35:1, 43:1 |

The verifier pins these per-cell counts, not only the aggregate totals.

---

## 6. Correct interpretation of the parent blocked-phase atlas

The parent atlas remains useful and exact in its stated arithmetic role:

> if one inspects the complete signed box specifically at the blocked q23 valuation destination, what geometry is present there?

But those destination events are **counterfactual with respect to the live first-hit ancestry** for every simultaneous survivor in the audited prefixes, because each candidate already terminated earlier.

Therefore the parent term “replacement hit” should be read as **destination replacement geometry**, not as “the next transition of the decomposition framework.”

The decomposition framework must use the ancestry-correct first hit.

---

## 7. New framework state transition target

The live finite transition observed here is

```text
simultaneous k19/k23 survivor
        |
        v
first exact post-k23 hit
        |
        +-- k27
        +-- k31
        +-- k35
        +-- k39
        +-- k43
        +-- k47
        `-- k55
```

with terminal geometry

```text
Type I only
Type I + Type II
Type II only

and, when Type II is present,

boundary-only
mixed
interior-only
```

This is much closer to the object required by `TYPEII-CANDIDATE-DECOMPOSITION-FRAMEWORK.md`: it respects earlier termination and associates each live survivor with its actual next certificate geometry.

---

## 8. Next theorem target

The immediate theorem-mining problem is now:

> derive exact state conditions that force a simultaneous k19/k23 survivor into one of the seven first-hit shifts `{27,31,35,39,43,47,55}`, preferably with a well-founded rule selecting the shift before factor enumeration.

The first attack should isolate k27 and k31, which already absorb 128 of the 148 audited survivors, and condition them on:

- k19 mode `FULL_QR | BARE`;
- Route A/B ancestry;
- residual support and the affine `B,R` coupling;
- q23 valuation phase;
- complete Type-II root geometry at the actual first hit.

A proved implication from survivor state to one of these early exits would be a genuine transition theorem for the developing decomposition framework rather than another destination census.

Erdős–Straus remains open.
