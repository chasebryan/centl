# ES+

New research built on the Type A/B and two-target work. One object: the
letter spectrum as the complement of the inverse signed-box cover.

The foundational note is [`LETTER-EQUATION.md`](LETTER-EQUATION.md).
The homing equation is [`HOMING.md`](HOMING.md).

The production letter engine is [`../cbis.kernel`](../cbis.kernel/README.md)
(CB Inverse Sieve). A letter it collects is the same ES-LETTER-v1 object
as a forward-menu letter at the same finite search grade.

The K/search-grade audit and successor plan is
[`CBIS-K-PARAMETER-STATUS.md`](CBIS-K-PARAMETER-STATUS.md). It records why
one scalar K is not the complete finite grade, the current cbis 1.2.0
reproducibility issues, and the empirical reason W/fab is presently the
operational frontier.

The separate research instrument is
[`../cbx.kernel`](../cbx.kernel/README.md) — **CB X-ray Kernel**. CBX keeps
the production W -> I -> N -> L verdict but evaluates every lane
independently, including I/N/L on primes that W already solved, so the
hidden first-hit depth distribution can be measured without weakening W.

The first clean X-ray validation census is
[`CBX-INITIAL-XRAY-CENSUS.md`](CBX-INITIAL-XRAY-CENSUS.md). It records
401,752 hard-prime observations through a sweep cursor of 234,540,000 at
the default grade. Lane I hit every observed target through K=400, with
finite observed maximum `k_I*=107`; this is a finite record, not a bound.
The formal run used the signal-atomic CBX runtime and an exact finite
iteration count rather than timeout termination.

W-clause census: [`w-census/W-CENSUS.md`](w-census/W-CENSUS.md).
Letters at the window layer have to sit in the residual `R` where both
`4p+1` and `p+4` are supported on primes `≡ 1 (mod 4)`.

None of these notes, finite censuses, or kernels proves Erdős–Straus.
