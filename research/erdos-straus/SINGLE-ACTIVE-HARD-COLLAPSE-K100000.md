# Single-active hard-class quotient collapse through k = 100,000

**Status:** exact finite theorem-certificate / falsification result  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** the universal theorem currently proves only `q=p` or `p^2` for a unique active fixed-negative layer. The sharper restriction `q in {3,5,9}` for Mordell-hard target candidates remains a theorem candidate, not a proof.

Read with:

- [SINGLE-ACTIVE-EXCESS-PRIME-POWER.md](SINGLE-ACTIVE-EXCESS-PRIME-POWER.md)
- [CLASS-C-CENSUS-K1500.md](CLASS-C-CENSUS-K1500.md)
- [CLASS-C-C1-SINGLE-ACTIVE.md](CLASS-C-C1-SINGLE-ACTIVE.md)
- [OPERATOR-COORDINATION.md](OPERATOR-COORDINATION.md)

## 1. Question attacked

For the six Mordell-hard residue classes

\[
H=\{1,121,169,289,361,529\}\pmod{840},
\]

consider every hard-compatible Type A/B target candidate through a target depth `k`.

For the target progression, let

\[
\mathcal N^{\rm act}_{k,r}
\]

be the active fixed-negative core.

The conjecture under attack was:

\[
\boxed{
|\mathcal N^{\rm act}_{k,r}|=1
\Longrightarrow
q_{j_0}\in\{3,5,9\}
\text{ and the valuation excess is Class A.}
}
\]

The universal theorem in [SINGLE-ACTIVE-EXCESS-PRIME-POWER.md](SINGLE-ACTIVE-EXCESS-PRIME-POWER.md) already reduces the possible quotient to

\[
q_{j_0}=p\text{ or }p^2.
\]

This run attacks the remaining prime-direction restriction.

## 2. Two independent constructions

The primary implementation constructs every fixed-squareclass earlier layer directly as

\[
m=d s^2,
\]

where `d` is a squarefree divisor of the target fixed-prime support.

The independent verifier does **not** use that construction. It first enumerates every actual earlier modulus

\[
m_j=4j-1,
\]

computes its squarefree kernel, groups the earlier layers by that kernel, and queries those groups for each target.

Thus the finite result is checked by two different constructions of the fixed-squareclass tower system.

## 3. Workflow provenance

GitHub Actions:

```text
workflow run: 31854964168
head commit:  2a8d59aa5cd1558d38ba103de640b15106225757
artifact id:  9238743256
artifact sha256:
f390c20afe0c8fc97d9046c34117f4e0b2c8e56f255d6a31c732b337d16d2159
```

The artifact contains the primary JSON/report, independent verifier output, provenance, and an internally checked SHA-256 manifest.

## 4. Exact result

Range:

\[
\boxed{k\le100,000}.
\]

Total hard-compatible Type A/B target candidates examined:

\[
\boxed{8,021,288}.
\]

Candidates with exactly one active fixed-negative layer:

\[
\boxed{419,123}.
\]

Their excess quotient distribution was exactly:

```text
q = 3: 252,832
q = 5:   4,173
q = 9: 162,118
```

Valuation-source distribution:

```text
Class A: 419,123
Class B:       0
other:         0
```

Counterexamples to the tested collapse:

\[
\boxed{0}.
\]

## 5. Independent verifier

The second implementation returned:

```json
{
  "actual": {
    "counterexample_count": 0,
    "hard_compatible_target_candidates": 8021288,
    "q_histogram": {
      "3": 252832,
      "5": 4173,
      "9": 162118
    },
    "single_active_candidates": 419123,
    "valuation_source_histogram": {
      "A": 419123
    }
  },
  "independent_construction": "enumerated earlier m_j grouped by squarefree kernel",
  "k_limit": 100000,
  "mismatched_fields": [],
  "verdict": "VERIFIED"
}
```

No census field disagreed.

## 6. First observed examples

The first examples in each quotient family are:

### q = 3

```text
k = 36
M = 143
d = 11
h = 1
t = 131
```

### q = 5

```text
k = 484
M = 1935
d = 43
h = 1
t = 1891
```

### q = 9

```text
k = 114
M = 455
d = 39
h = 169
t = 449
```

These are regression fixtures, not privileged theoretical cases.

## 7. Distribution across hard classes

The single-active cases are broadly distributed across all six hard classes:

```text
h=1:   70,058
h=121: 70,076
h=169: 69,957
h=289: 69,478
h=361: 70,076
h=529: 69,478
```

So the observed collapse is not being driven by one exceptional hard residue class.

## 8. Interpretation

The theorem-plus-computation stack is now:

\[
\boxed{
|\mathcal N^{act}|=1
\overset{\text{proved}}{\Longrightarrow}
q=p\text{ or }p^2
\overset{k\le100000}{\Longrightarrow}
q\in\{3,5,9\}\text{ only}.
}
\]

The first implication is universal.

The second arrow is still finite evidence.

But the absence of `7`, `25`, every prime `>=11`, and every Class-B prime square over more than eight million hard-compatible target candidates sharply isolates the missing arithmetic statement.

## 9. Proof direction

Write the unique negative square-lift tower as

\[
m=d s^2.
\]

Uniqueness has a stronger consequence than merely `q=p` or `p^2`:

- removing any prime factor from `s` must destroy activity, otherwise a smaller member of the same negative tower would be a second active layer;
- any *other* square lift `d u^2` below the target modulus must be absorbed by `L`, otherwise it too would be active and negative.

Thus the unique active layer is a first valuation shell in an otherwise absorbed negative tower.

The remaining proof problem is to combine this first-shell structure with the hard-class local-square conditions at `3,5,7` and target Type A/B compatibility.

The desired theorem is:

\[
\boxed{
\text{hard-compatible first active shell}
\Longrightarrow
s=3\text{ or }5,
}
\]

with the valuation of `3` distinguishing `q=3` from `q=9`.

## 10. Falsifier

A single hard-compatible candidate with

\[
|\mathcal N^{act}|=1
\]

and one of

```text
q = 7,
q = 25,
q = p or p^2 for p >= 11,
Class-B q = p^2,
```

would immediately falsify the small-prime-collapse conjecture while leaving the proved `p/p^2` theorem intact.

No such candidate exists through `k=100,000` in the exact double-construction search.
