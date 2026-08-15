# Prior-art calibration for the square-completed Type-II route

**Status:** source/provenance note  
**Date:** 2026-08-15  
**Claim boundary:** this note deliberately narrows FCF novelty language. The divisor-of-a-square Type-II mechanism is prior art. Any FCF novelty claim must concern later structural synthesis only after a publication-grade review.

---

## 1. The square-divisor mechanism is old prior art

The current FCF route uses positive integers `a,d` with

\[
d\mid a^2
\]

and a congruence equivalent to

\[
4a-1\mid ap+d.
\]

This mechanism must **not** be advertised as an FCF discovery.

A source trail reaches at least to Léon Thépault's 1979 work, recorded in later historical analysis of the Erdős--Straus problem.

The theorem is stated in the form:

> for a prime `n≡1 mod4`, if there exist positive `a,b` such that `b|a^2` and `4a-1` divides `bn+a`, then an Erdős--Straus decomposition exists.

The explicit decomposition recorded with that theorem is

\[
\boxed{
\frac4n
=
\frac1{an}
+
\frac{4a-1}{n(a+bn)}
+
\frac{b(4a-1)}{a(a+bn)}.}
\]

Thus divisor-square Type-II constructions were already present decades before the current work.

---

## 2. Exact equivalence with the current congruence coordinate

The FCF square-completed congruence is written as

\[
\boxed{
4a-1\mid p+4d,
\qquad
d\mid a^2.}
\]

Since

\[
4a\equiv1\pmod{4a-1},
\]

this is equivalent to

\[
\boxed{4a-1\mid ap+d.}
\]

Let

\[
d^*=\frac{a^2}{d}.
\]

Because `d` is a unit modulo `4a-1`, multiplying

\[
ap+d\equiv0
\]

by `a/d` gives

\[
\boxed{d^*p+a\equiv0\pmod{4a-1}.}
\]

This is exactly the Thépault shape with

\[
\boxed{b=d^*.}
\]

Therefore the present square-completed coordinate and the historical Thépault condition are related by the divisor-complement involution.

The underlying existence mechanism is prior art.

---

## 3. 2017/2023 public discussion

A 2017 Mathematics Stack Exchange question studied the integrality condition

\[
\boxed{
\frac{d+an}{4a-1}\in\mathbb Z}
\]

with square-divisor conditions.

A 2023 answer explicitly relates the resulting condition `D|A^2` to the classical Type-II form and derives the square-divisor parameter from Mordell-style Type-II variables.

This is non-peer-reviewed discussion, but it is additional evidence that the square-divisor coordinate itself was already recognized before the current project.

---

## 4. Bradford 2024

Kyle Bradford's 2024 preprint

*Elemental Patterns from the Erdős Straus Conjecture*, arXiv:2403.16047,

proves necessary and sufficient divisor-of-a-square modular descriptions in terms of the smallest denominator `x`.

For prime `p`, Bradford uses divisors

\[
d\mid x^2
\]

and gives separate modular conditions corresponding to standard Type I and Type II, with a one-to-one correspondence to Erdős--Straus solutions.

This is a different coordinate system from the `4a-1` square-completed López layer, but it confirms that **complete square-divisor descriptions of prime ES solutions are established prior art**.

---

## 5. Bello-Hernández--Benito--Fernández 2026

The 2026 divisor-parametrization paper

*A Divisor Parametrization for the Erdős--Straus Conjecture*, arXiv:2606.10922,

provides another complete divisor-based coordinate system and compares it with standard Type I/II descriptions.

The FCF two-target signed-box theorem and divisor-square forms should be presented as reformulations/syntheses against this complete modern background, not as the first divisor parametrization of ES.

---

## 6. What remains potentially distinctive in the current work

The targeted prior-art pass above changes the responsible novelty boundary.

Do **not** claim novelty for:

- the condition `d|a^2`;
- a Type-II solution generated from a divisor of a square;
- divisor complement by itself;
- a complete divisor-of-a-square description of Type I/II solutions;
- the general use of modular divisor criteria for Erdős--Straus.

The current potentially distinctive synthesis is narrower:

1. place Thépault's complete square divisor lattice on the **same layer `a`** as López's 2024 Type-A/B congruence system;
2. prove that López Type A and Type B are exactly the two monotone boundary orthants of that centered divisor box;
3. identify the omitted Type-II certificates as mixed-sign/cross-orthant parameters;
4. derive the exact mixed-parameter count
   \[
   \tau(a^2)-2\tau(a)+1;
   \]
5. identify López A/B mutual inversion as the restriction of the global divisor-complement involution;
6. prove the exact finite-group identity
   \[
   S_a=-\mathcal R_{4a-1}(a),
   \]
   merging the completed López layer with the repository's Kneser signed-box machinery;
7. combine that internal Kneser geometry with the pre-existing cross-layer shadow/ancestry framework.

These items are **potentially novel structural synthesis**, not established priority claims.

---

## 7. Terminology correction

Future research notes should prefer language such as:

- **Thépault square-completed layer**;
- **square-completed López layer**;
- **FCF orthant/Kneser synthesis**;

rather than wording that implies FCF originated the square-divisor criterion.

The theorem files already carry claim-boundary disclaimers; this note supplies the explicit provenance correction.

---

## 8. Publication-grade follow-up

A proper priority review should trace:

1. the original Thépault publication in *Pour la Science* / Gardner's reporting and any surviving primary text;
2. Gardes' historical thesis transcription and analysis;
3. Mordell's Type-II parametrization;
4. Elsholtz--Tao's solution parametrizations;
5. the 2017 public square-divisor discussion;
6. Bradford 2024;
7. López 2022/2024;
8. Bello-Hernández--Benito--Fernández 2026;
9. Schuh 2025 and related Pythagorean-prime square-divisor parametrizations.

Until that review is complete, the orthant/signed-box merger should be described as **potentially novel** rather than first or unique.
