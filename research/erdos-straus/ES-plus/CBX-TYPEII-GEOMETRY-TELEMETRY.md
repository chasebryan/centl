# CBX Type-II geometry telemetry

**Status:** active exact post-hoc instrumentation  
**Date:** 2026-08-16  
**Stack:** child of `agent/cbx-kernel` / PR #230  
**Depends on:** `CBX-TYPEII-GEOMETRY-PRIORITY.md`, `../ES-TWO-TARGET-DIVISOR-SQUARE.md`, `../ES-TYPEII-ROOT-GEOMETRY.md`  
**Implementation:** `../cbx.kernel/analyze_geometry.py`  
**Claim boundary:** finite exact classification of observed Lane-I hits only. This does not prove Erdős–Straus, disprove López-all-primes, or change ES-LETTER-v1 semantics.

---

## 1. Purpose

The geometry-priority decision removes López Type A/B from the privileged role of defining Type II. The next requirement is observational rather than rhetorical:

> for each actual Lane-I first hit, determine which exact fixed-shift mechanism is present and, when Type II is present, determine whether its root geometry is López-comparable, genuinely incomparable, or both.

This telemetry is deliberately post-hoc. It does not add a fifth lane, does not change `W -> I -> N -> L`, and does not alter the finite cover verdict. It reopens only a Lane-I hit that CBX has already observed.

---

## 2. Exact fixed-shift classification

For an observed Lane-I first hit at prime `p` and admissible shift `k`, put

\[
C=\frac{p+k}{4}.
\]

The analyzer factors `C` exactly and enumerates every divisor

\[
d\mid C^2.
\]

The two exact Lane-I targets are then tested independently.

### Type I

\[
\boxed{4d\equiv-1\pmod k.}
\]

### Type II

\[
\boxed{d\equiv-C\pmod k.}
\]

A first shift can therefore be classified as

- `type-I-only`;
- `type-II-only`;
- `both`.

The analyzer never infers one mechanism from the absence or presence of the other. Both divisor classes are enumerated exactly at the observed first shift.

---

## 3. Full Type-II root relation

For every Type-II divisor witness, write the canonical squarefree-root decomposition

\[
d=sb^2,
\qquad
\frac{C^2}{d}=sc^2,
\qquad
C=sbc,
\]

with `s` squarefree.

Every Type-II witness is classified by the exact divisibility relation between `b` and `c`:

\[
\boxed{b\mid c},
\qquad
\boxed{c\mid b},
\qquad
\boxed{b\nmid c\ \land\ c\nmid b}.
\]

The first two are the López A/B boundary sector. The third is the genuinely square-only interior.

Crucially, the analyzer classifies **all Type-II witnesses at the observed first shift**, not an arbitrary first witness. The resulting shift-level region is therefore:

- `boundary-only`: Type-II witnesses exist, but all are divisibility-comparable;
- `interior-only`: Type-II witnesses exist, but all are incomparable;
- `mixed`: both comparable and incomparable Type-II witnesses occur at the same first shift.

This prevents traversal order from deciding the mathematical interpretation.

---

## 4. Canonical regression facts

The analyzer carries exact self-tests that pin three qualitatively different geometries.

### `p=1009`, `k=3`

The first shift contains both Type I and Type II. Its Type-II geometry is boundary-only. A canonical boundary witness is

\[
\boxed{(s,b,c)=(11,1,23)}.
\]

### `p=2521`, `k=23`

The first shift again contains both Type I and Type II, but the Type-II sector is interior-only. A canonical incomparable witness is

\[
\boxed{(s,b,c)=(2,2,159)}.
\]

Here neither root divides the other.

### `p=8,803,369`, `k=107`

This is the current finite Lane-I depth record from the clean CBX census. At its record shift, the exact classification is

```text
mechanism       type-II-only
Type-II region  boundary-only
```

with canonical boundary witness

\[
\boxed{(s,b,c)=(1,11,200079)}.
\]

Thus the current `k_I^*=107` record is **not** an incomparable-root escape from López geometry. It lies on the comparable-root boundary even though the governing search space is strictly larger.

That distinction matters. Removing López from a privileged ontological role does not justify assuming that the hard tail must live outside López. The data are now allowed to answer that question instead of the model deciding it in advance.

---

## 5. Usage

Classify one exact hit:

```sh
./centl es cbx analyze-geometry --p 8803369 --k 107
```

Classify every Lane-I hit in one or more existing CBX observation streams:

```sh
./centl es cbx analyze-geometry \
  research/erdos-straus/cbx.kernel/observations/formal.jsonl \
  --json \
  --rows /tmp/cbx-typeii-geometry.jsonl
```

The analyzer deduplicates exact `(p,k)` observations, preserves conflicting first-k evidence instead of hiding it, and reports if one prime appears with more than one observed first shift.

---

## 6. Summary surface

The summary separates:

- Type-I-only / Type-II-only / both at the observed first shift;
- Type-II boundary-only / interior-only / mixed;
- p50 / p90 / p99 / maximum first-k depth for each mechanism and Type-II region;
- maximum-depth record primes with canonical boundary/interior witnesses;
- spectrum counts where the source JSONL preserves the CBX spectrum label.

The optional enriched JSONL records exact factorization of `C`, witness multiplicities, root-relation flags, and canonical representative witnesses.

---

## 7. Research consequence

This is the measurement layer required by the Type-II hierarchy change.

The immediate finite questions are now precise:

1. What fraction of Lane-I first hits are Type-I-only, Type-II-only, or simultaneous?
2. Among Type-II first hits, how often is the shift boundary-only, interior-only, or mixed?
3. Does first-hit depth have a different tail in the comparable and incomparable sectors?
4. Which primes are the deepest interior-only records?
5. Does the existing `63..103 -> 107` gauntlet represent loss of Type I, loss of incomparable Type II, or a more general signed-box scarcity?
6. Which root-factor patterns recur among deep boundary-only and deep interior-only hits?

Only after those distributions are measured should CBX promote a geometry-dependent scheduling or pruning hypothesis.

A theorem controlling only the López-comparable sector must remain labeled as such. A theorem controlling the incomparable sector is equally first-class. Neither sector is allowed to impersonate the full Type-II space.

---

## 8. Non-negotiable invariant

```text
geometry telemetry != new cover lane
geometry telemetry != proof
geometry telemetry != pruning permission
```

It is an exact X-ray of why an already observed Lane-I shift works.

That is enough to turn the López hierarchy decision into measurable mathematics rather than a change of vocabulary.
