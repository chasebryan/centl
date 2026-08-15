# Ancestry-Minimal q=3 Alignment through k = 100,000

**Status:** exact finite theorem-certificate; independently verified  
**Date:** 2026-08-15  
**Depends on:** `Q3-POINTWISE-DIVISOR-REDUCTION.md`, `Q3-NEXT-DIGIT-THEOREM.md`, `Q3-FACTOR-PAIR-TYPES.md`  
**Claim boundary:** finite alignment certificate only. It does not prove the universal alignment theorem, universal DSC-P, López-all-primes, or Erdős-Straus.

---

## 1. Object tested

`Q3-POINTWISE-DIVISOR-REDUCTION.md` proves that a q=3 trap witness caught by an earlier divisor layer either:

- descends to a frozen `q=1` direct shadow; or
- descends to an earlier `q=3` layer while preserving the same forbidden parameter class.

Thus every q=3 digit on a directly novel candidate has an **ancestry-minimal** representative.

The finite probe removes every nonminimal trap witness first and then measures:

1. how many ancestry-minimal q=3 rows can align on one admissible candidate;
2. how many distinct next 3-adic digits they occupy;
3. whether they can cover all three digits.

---

## 2. Hosted provenance

```text
workflow run: 31862992676
workflow sha: cac29c8daee8ebb2aebc18196c20b3b626839a31
artifact id:  9241154417
artifact digest:
sha256:eb957db5cbaf853bba9c0264f9cd8d961ecb6a29bc40a7e06d6c507a71a688cd
```

Range:

\[
\boxed{k\le100000.}
\]

Primary and independent verifier completed successfully.

---

## 3. Exact result

Admissible candidates checked:

\[
\boxed{3,567,030.}
\]

Maximum number of ancestry-minimal q=3 rows simultaneously hitting one candidate:

\[
\boxed{3.}
\]

Candidates with at least three ancestry-minimal q=3 rows:

\[
\boxed{12.}
\]

Among those 12, candidates occupying two or more next digits:

\[
\boxed{0.}
\]

Full ancestry-minimal q=3 covers:

\[
\boxed{0.}
\]

---

## 4. Minimal-row count histogram

| simultaneous minimal rows | candidates |
|---:|---:|
| 0 | 3,320,884 |
| 1 | 239,568 |
| 2 | 6,566 |
| 3 | **12** |

No candidate in the tested range has four or more ancestry-minimal q=3 rows.

---

## 5. The twelve three-row cases are perfectly aligned

Their union masks are:

| one-digit mask | number of candidates |
|---:|---:|
| `1 = {0}` | 3 |
| `2 = {1}` | 6 |
| `4 = {2}` | 3 |

There are **no** masks `3`, `5`, `6`, or `7` among the three-row population.

Thus every three-row case is maximally non-covering: three distinct ancestry-minimal rows all forbid the **same** global next 3-adic digit.

The first is

```text
k = 23400
h = 1
t = 92699
mask = 4
rows = 25, 286, 754
```

---

## 6. Independent verifier

The independent affine verifier returned:

```text
verdict:            VERIFIED
primary comparison: MATCH
mismatches:         []
```

and reproduced exactly:

```text
minimal-row histogram:
0: 3320884
1: 239568
2: 6566
3: 12

three-plus masks:
1: 3
2: 6
4: 3
```

---

## 7. Frozen SHA-256 manifest

```text
a6f335121d11f2eb15752f70b108dbd8f1bd87a3b9909163d422f9e3d3e85dd6  q3-minimal-alignment.json
c5b619f91187afb67d6d424dfae03fbeffef7ed8e63b587f9c5d31e7e6a7365f  q3-minimal-alignment-report.md
858acdf925eb58104feaf31e6067de646b6503b87c9d37fa5bd817b2e00b35cd  q3-minimal-alignment-independent-verifier.json
bdc883a7a491cc923bf7a41851c6e51b3c604f8a9ac271b3336d470fab0b5ffa  provenance.txt
```

---

## 8. Stronger theorem suggested by the certificate

The data no longer merely suggests

\[
\text{no full q=3 cover}.
\]

It suggests a much more rigid statement:

> **Ancestry-minimal alignment candidate.** Whenever at least three ancestry-minimal q=3 rows align on one admissible hard Type A/B target, their factor-pair species coincide, hence they forbid one common next 3-adic digit.

By `Q3-FACTOR-PAIR-TYPES.md`, the three digits correspond to

\[
(w,a)\pmod9
\in
\{(2,5),(5,2),(8,8)\}.
\]

So the analytic target is now to prove that one admissible target factor pair cannot simultaneously align ancestry-minimal local pairs of all three species.
