# q23 blocked-phase full-geometry atlas

**Status:** exact finite earliest-hit atlas on the two realized h169 route families  
**Date:** 2026-08-16  
**Primary analyzer:** `analyze_q23_blocked_phase_geometry.py`  
**Depends on:** `Q23-SQUARE-LIFT-PHASE-SIEVE.md`, `CANONICAL-Q2-TYPEII-BOUNDARY.md`, full Type-II root geometry  
**Claim boundary:** this exhausts each stated arithmetic progression only through its pinned first replacement hit. It is a finite exact result, not a density theorem, a universal phase theorem, or an Erdős–Straus proof.

---

## 1. The controlled experiment

The q23 phase sieve proves that on h169 the canonical square-lift divisor

\[
d=23^2=529
\]

is Type-II-compatible on 13 valuation phases and blocked on the ten phases

```text
n = 1,2,4,7,9,10,13,16,19,22.
```

`CANONICAL-Q2-TYPEII-BOUNDARY.md` sharpens the interpretation: whenever `d=23^2` succeeds at a genuine q23 square lift, that Type-II certificate is necessarily López Type A (`b|c`).

So a blocked phase gives a clean experiment:

> remove the deterministic canonical boundary certificate, preserve the complete signed box, and ask what mechanism replaces it first.

The answer is not uniform.

---

## 2. Exact phase progressions

For

\[
k_n=19+92n,
\]

the q23 square-lift condition is

\[
23^2\mid C_{k_n}
\iff
p\equiv-k_n\pmod{4\cdot23^2}
\iff
p\equiv-k_n\pmod{2116}.
\]

The analyzer intersects this exactly with

\[
p\equiv169\pmod{840}
\]

and one of the two realized route residues:

```text
Route A: p mod17 = 15
Route B: p mod47 = 28
```

Every phase therefore becomes one exact arithmetic progression. The progression modulus is

```text
Route A:  7,554,120
Route B: 20,884,920
```

For every candidate through the pinned first replacement hit, the analyzer then checks:

1. deterministic 64-bit primality;
2. exact Lane-I miss at k=19;
3. exact Lane-I miss at k=23;
4. full signed-box status at the square-lift destination `k_n`;
5. canonical `d=529` is indeed blocked;
6. every Type-II divisor witness, classified by root comparability.

Thus “first” below means first inside the exact stated route-phase progression after simultaneous k19/k23 survival, not first in an ad hoc sample.

---

## 3. Route A: q17 + q23

| n | k | first replacement p | mechanism | Type-II geometry |
|---:|---:|---:|---|---|
| 1 | 111 | 288,537,649 | I+II | mixed |
| 2 | 203 | 382,143,049 | Type II only | interior-only |
| 4 | 387 | 2,246,368,489 | Type I only | n/a |
| 7 | 663 | 457,355,809 | Type II only | interior-only |
| 9 | 847 | 2,019,416,449 | Type II only | boundary-only |
| 10 | 939 | 1,108,323,889 | Type I only | n/a |
| 13 | 1215 | 1,842,387,289 | Type I only | n/a |
| 16 | 1491 | 8,049,889 | Type II only | boundary-only |
| 19 | 1767 | 341,744,929 | Type II only | interior-only |
| 22 | 2043 | 3,840,616,249 | Type II only | interior-only |

Route A therefore gives, among the ten blocked phases:

```text
Type I only   3
Type II only  6
I+II          1
```

Among the seven first replacements containing Type II:

```text
interior-only  4
boundary-only  2
mixed          1
```

So on this realized route, removing the canonical q23 boundary certificate does **not** merely reveal another López layer. Four blocked phases first terminate through exclusively incomparable-root Type-II witnesses.

---

## 4. Route B: q23 + q47

| n | k | first replacement p | mechanism | Type-II geometry |
|---:|---:|---:|---|---|
| 1 | 111 | 209,441,569 | I+II | mixed |
| 2 | 203 | 118,637,569 | I+II | boundary-only |
| 4 | 387 | 3,362,156,449 | Type II only | boundary-only |
| 7 | 663 | 5,763,014,209 | Type I only | n/a |
| 9 | 847 | 9,090,072,769 | Type I only | n/a |
| 10 | 939 | 3,590,074,489 | Type I only | n/a |
| 13 | 1215 | 6,366,860,809 | Type II only | interior-only |
| 16 | 1491 | 580,829,929 | Type I only | n/a |
| 19 | 1767 | 8,328,227,209 | Type I only | n/a |
| 22 | 2043 | 2,124,497,929 | Type I only | n/a |

Route B gives

```text
Type I only   6
Type II only  2
I+II          2
```

Among its four Type-II-containing first replacements:

```text
interior-only  1
boundary-only  2
mixed          1
```

The route is visibly more Type-I-heavy than Route A in this finite atlas, but it still produces both mixed and purely incomparable replacement geometry.

---

## 5. Combined finite picture

Across all twenty route-phase cells:

```text
Type I only    9
Type II only   8
I+II           3
```

Eleven first replacements contain Type II. Their exact root geometry is

```text
interior-only  5
boundary-only  4
mixed          2
```

Therefore seven of the eleven Type-II-containing replacement hits include an incomparable-root witness, and five of them have **no comparable-root Type-II witness at all at that destination**.

This is the cleanest finite evidence yet for why López A/B cannot be allowed to govern the full Type-II search: after a specifically identified López-A mechanism is removed, exact signed-box survival frequently terminates in geometry that cannot be expressed as either comparable-root boundary family at the same shift.

This is evidence about these twenty exact cells only. It is not a population-frequency claim.

---

## 6. Representative interior replacements

### Route A, n=2

\[
p=382,143,049,
\qquad
k=203,
\qquad
C=95,535,813.
\]

Factorization:

\[
C=3\cdot23^2\cdot37\cdot1627.
\]

The destination is Type-II-only and interior-only. One canonical incomparable root witness is

\[
\boxed{(s,b,c)=(3,37,860683)}.
\]

Neither root divides the other.

### Route A, n=7

\[
p=457,355,809,
\qquad
k=663,
\qquad
C=114,339,118.
\]

The destination is Type-II-only and interior-only. A canonical incomparable witness is

\[
\boxed{(s,b,c)=(1613,134,529)}.
\]

Again neither root divides the other.

### Route B, n=13

\[
p=6,366,860,809,
\qquad
k=1215,
\qquad
C=1,591,715,506.
\]

The destination is Type-II-only and interior-only, with canonical incomparable witness

\[
\boxed{(s,b,c)=(1679,46,20609)}.
\]

These are not “failed López certificates.” They are successful exact Type-II certificates in the interior of the larger root geometry.

---

## 7. Mixed replacements are also informative

The blocked n=1 phase is mixed on both realized routes:

```text
Route A: p=288,537,649, k=111, I+II, mixed Type II
Route B: p=209,441,569, k=111, I+II, mixed Type II
```

So even at the same destination shift, the correct state is not a binary label “López versus non-López.” A single signed box can contain both comparable and incomparable Type-II certificates simultaneously, alongside Type I.

This is why the CBX geometry telemetry classifies the **entire witness set** at a shift rather than reporting whichever divisor happened to be enumerated first.

---

## 8. What the blocked phases now mean

Before this atlas, the ten blocked phases meant only:

> `d=529` cannot be the canonical Type-II target.

They can now be separated into three experimentally realized replacement regimes:

```text
canonical boundary blocked -> Type I replacement
canonical boundary blocked -> noncanonical boundary Type II replacement
canonical boundary blocked -> incomparable Type II replacement
```

and mixtures of those mechanisms.

This converts the q23 phase sieve from a one-divisor obstruction into a controlled full-geometry experiment.

---

## 9. Next theorem target

The obvious next question is no longer whether blocked phases can still succeed. They do.

The sharper question is:

> Which exact survivor-state coordinates predict the replacement geometry?

The candidate decomposition framework already carries:

```text
k19 mode
residual support
k23 support
affine coupling
q23 valuation phase
canonical phase allowed/blocked
full signed-box status
```

The new response variable is

```text
replacement geometry
    Type I
    comparable-root Type II
    incomparable-root Type II
    mixed
```

The next attack should condition the twenty cells on `FULL_QR/BARE`, residual-support class, factor pattern, and affine-coupling data. A successful implication there would be a genuine state-transition theorem rather than another census observation.

Erdős–Straus remains open.
