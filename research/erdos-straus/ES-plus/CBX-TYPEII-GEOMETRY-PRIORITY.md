# CBX Type-II geometry priority

**Status:** active research policy / exact interpretation  
**Date:** 2026-08-16  
**Stack base:** `agent/cbx-kernel` / draft PR #230  
**Depends on:** `ES-TYPEII-ROOT-GEOMETRY.md`, `ES-TYPEII-SQUARE-COMPLETION-LOPEZ-A.md`, `ES-SQUARE-COMPLETION-BACKBONE.md`, `ES-BINARY-LANE-I-EQUIVALENCE.md`  
**Claim boundary:** this changes the research hierarchy, not the Erdős–Straus claim boundary. It does not disprove the López-all-primes conjecture and does not prove Erdős–Straus.

---

## 1. Decision

López Type A/B is no longer the privileged model of the Erdős–Straus search space.

The exact Type-II root parametrization proves that the López A/B families are precisely the divisibility-comparable boundary cases

\[
\boxed{b\mid c\quad\text{or}\quad c\mid b,}
\]

while valid square-completed Type-II certificates also occupy the genuinely mixed region

\[
\boxed{b\nmid c\quad\text{and}\quad c\nmid b.}
\]

Accordingly, López is retained as a mathematically useful boundary family, finite-depth coordinate system, and diagnostic. It is not to be treated as the governing ontology of the full Type-II geometry.

The software consequence is equally direct:

> failure to find a López A/B certificate must never be interpreted as failure of Type II, and no CBX theorem-mining or scheduling rule may silently prune the incomparable-root region.

---

## 2. Why this already fits CBX

This decision does **not** require replacing the CBX kernel.

CBX Lane I already evaluates the exact fixed-shift signed-box condition. `ES-BINARY-LANE-I-EQUIVALENCE.md` proves that the Lane-I two-target signed box is exactly the fixed-shift Type-I/II condition. In particular, the Type-II target is the full divisor-square criterion

\[
\boxed{d\mid C^2,\qquad d\equiv-C\pmod k,}
\]

not the narrower López boundary condition.

By contrast, Lane L remains the López prime-modulus trap observer. That is useful X-ray information, but it is subordinate to the full signed-box geometry already carried by Lane I.

Therefore the existing production-equivalent order

```text
W -> I -> N -> L
```

is preserved. No fifth cover lane is introduced, and no ES-LETTER-v1 semantics change.

The hierarchy is now explicit:

```text
full fixed-shift Type-I/II geometry  -> Lane I
external-NR structure               -> Lane N
López boundary-family diagnostics   -> Lane L
```

Lane L may explain a hit. It may not define what counts as a possible Type-II hit.

---

## 3. Exact completion relation

For prime `p == 1 mod 4`, square-completed standard Type II is equivalent to the existence of positive `a,d` with

\[
\boxed{d\mid a^2,\qquad p\nmid d,\qquad 4a-1\mid p+4d.}
\]

López Type A is the subfamily

\[
\boxed{d\mid a.}
\]

Under the canonical squarefree-root decomposition

\[
\boxed{d=sb^2,\qquad a=sbc,\qquad s\text{ squarefree},}
\]

this becomes

\[
\boxed{\text{Type A}\iff b\mid c.}
\]

The complementary López Type-B boundary is

\[
\boxed{\text{Type B}\iff c\mid b.}
\]

Thus

\[
\boxed{\text{López A/B}\iff b,c\text{ are comparable by divisibility}.}
\]

The square-only interior is exactly

\[
\boxed{b\nmid c\ \land\ c\nmid b.}
\]

This is the geometry CBX should now preserve explicitly in analysis and theorem mining.

---

## 4. Instrumentation rule for future CBX work

Future CBX telemetry may annotate an exact Lane-I witness with additional geometry, but those annotations are observational and must not alter the cover verdict.

The preferred eventual fields are conceptually:

```text
i_mechanism       type-I | type-II
root_relation     b-divides-c | c-divides-b | incomparable | n/a
lopez_boundary    true | false | n/a
```

For Type-II witnesses, an implementation may additionally preserve the exact square-completion data needed to reconstruct

```text
(a, d, s, b, c)
```

or an equivalent canonical certificate.

The critical invariant is:

```text
geometry annotation != new lane
geometry annotation != pruning permission
```

A mixed-root hit is a first-class Type-II hit, not a model escape that needs to be translated back into López coordinates before it is accepted.

---

## 5. Relationship to draft PR #231

Draft PR #231 (`cbis: implement Type A/B model-escape subsystem`) remains complementary rather than redundant.

Its job is epistemic separation inside CBIS:

1. current W/I/N/L cover status;
2. bounded Type A/B audit status;
3. exact general Erdős–Straus witness status independent of A/B coordinates.

That is valuable because it prevents finite A/B depth from becoming an implicit completeness assumption.

CBX has a different role. Because Lane I already carries the full fixed-shift signed-box Type-I/II predicate, CBX should use the exact Type-II geometry itself as the primary theorem-discovery object and keep López depth as a side measurement.

So the two active lines fit together as follows:

```text
CBIS model-escape (#231):  protect production search from an A/B completeness assumption
CBX geometry policy:       make full Type-II geometry the primary research object
```

Neither line should convert a finite A/B miss into a statement that López-all-primes is false.

---

## 6. Consequence for current CBX analyses

Existing Lane-I censuses, overlap graphs, first-hit records, shadow-depth studies, and adaptive-K experiments remain valid because they were computed from the full signed-box predicate rather than from Lane L.

Their interpretation changes in one important way: they should no longer be discussed as though later success must eventually be accounted for by López A/B.

Instead, future analysis should ask which part of the exact Type-II geometry produced the hit.

High-value next measurements are:

1. classify Lane-I Type-II first hits into comparable-root versus incomparable-root certificates;
2. measure first-hit depth distributions separately for the López boundary and square-only interior;
3. condition the existing Lane-I overlap graph on root relation;
4. determine whether the `63..103 -> 107` record-prime gauntlet is a failure of boundary comparability, a failure of Type II entirely at those shifts, or a Type-I/Type-II mechanism change;
5. identify recurring mixed-root factor patterns that admit symbolic classification;
6. prefer the square-completed layer system when formulating universal Type-II coverage targets.

The existing theorem that square-completed Type-II first-hit depth is unbounded also remains decisive: the desired proof cannot be a universal bounded-depth statement, whether the layers are viewed through López or through their completion.

---

## 7. Pull-request stacking policy

This research direction is intentionally suitable for stacked PRs.

Recommended stack:

```text
main
  └─ #230  agent/cbx-kernel
       ├─ this policy / geometry-priority PR
       │    └─ optional witness-geometry telemetry implementation
       └─ #263  exact-state character promotion closure
```

A child PR should be used when a change depends on CBX but is not required to stabilize the core kernel itself. This keeps #230 from becoming the only review surface for every theorem-mining experiment.

PR #231 may remain based on `main` because it modifies the CBIS sidecar/observer surface rather than the CBX research kernel.

---

## 8. Non-negotiable research rule

From this point forward:

- Type A/B may be searched, audited, censused, and proved about;
- Type A/B may be used as a boundary coordinate system;
- Type A/B may not be assumed complete;
- a mixed-root Type-II certificate is not second-class evidence;
- a theorem that only controls the comparable-root sector must say so;
- a CBX optimization may not discard incomparable-root states unless an independent theorem proves that pruning sound.

The governing object is the full exact Type-II geometry.

López keeps its seat at the boundary. It no longer owns the room.
