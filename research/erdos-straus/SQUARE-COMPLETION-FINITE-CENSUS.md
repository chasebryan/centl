# Finite square-completion census through 50,000,000

**Status:** exact finite computation; standalone reproducer checked in  
**Date:** 2026-08-15  
**Reproducer:** `square_completion_probe.py`  
**Claim boundary:** this is a finite statement only. `ES-SQUARE-COMPLETION-BACKBONE.md` proves that completed first-hit depth is unbounded, so no finite observed ceiling is promoted to a universal theorem.

---

## Run domain

Prime domain:

\[
\boxed{p\le50,000,000}
\]

restricted to Mordell-hard residue classes

\[
\boxed{p\bmod840\in\{1,121,169,289,361,529\}.}
\]

Number of hard primes:

\[
\boxed{93,457.}
\]

Completed layers searched:

\[
\boxed{a\le1500.}
\]

For each layer

\[
m_a=4a-1
\]

the exact square-completed trap is

\[
S_a=\{-4D\pmod{m_a}:D\mid a^2\},
\]

with the validity check

\[
p\nmid D.
\]

---

## Result

Every one of the `93,457` hard primes was captured.

\[
\boxed{\text{unresolved}=0.}
\]

The deepest observed square-completed first hit was

\[
\boxed{624.}
\]

It occurred for exactly one prime:

\[
\boxed{p=2,031,121.}
\]

The witness is

\[
\boxed{
a=624,
\qquad
D=576,
\qquad
m_a=2495,
\qquad
q=815.}
\]

Exact checks:

\[
576\mid624^2,
\]

\[
2,031,121+4\cdot576
=2,033,425
=2495\cdot815,
\]

and, with

\[
C=\frac{2,031,121+815}{4}=507,984,
\]

\[
576\mid C^2,
\qquad
576+C=624\cdot815.
\]

Thus this is simultaneously a valid square-completed congruence witness and an exact standard Type-II divisor-square witness.

---

## The deepest witness is genuinely mixed

Factor

\[
624=2^4\cdot3\cdot13
\]

and

\[
576=2^6\cdot3^2.
\]

Relative to the midpoint exponents of `624`, the square divisor `576` is

- above the midpoint at `2`;
- above the midpoint at `3`;
- below the midpoint at `13`.

Therefore it lies in neither López boundary orthant.

The completed depth is

\[
\boxed{624,}
\]

whereas a direct López Type-A/B scan gives first depth

\[
\boxed{1403}
\]

for the same prime.

So the finite record is a genuine mixed-sign rescue rather than an old boundary hit written in new notation.

---

## Record frontier observed in this run

As primes are ordered increasingly, the completed-depth records are:

| prime `p` | first completed depth `a` | modulus `4a-1` |
|---:|---:|---:|
| 1009 | 3 | 11 |
| 1201 | 8 | 31 |
| 2521 | 12 | 47 |
| 3361 | 25 | 99 |
| 33289 | 39 | 155 |
| 90841 | 42 | 167 |
| 144169 | 48 | 191 |
| 167521 | 65 | 259 |
| 225289 | 70 | 279 |
| 361321 | 72 | 287 |
| 915961 | 76 | 303 |
| 954409 | 84 | 335 |
| 1853329 | 96 | 383 |
| 2031121 | 624 | 2495 |

No later hard prime through `50,000,000` exceeds depth `624` in this finite domain.

Again, the unboundedness theorem proves that this plateau must eventually break.

---

## Reproduction

From the repository root:

```bash
python3 research/erdos-straus/square_completion_probe.py \
  --prime-limit 50000000 \
  --a-max 1500 \
  --compare-ab-max 5000
```

Expected headline values:

```text
hard_prime_count      93457
captured              93457
unresolved            0
max_completed_depth   624
deepest.p             2031121
deepest.a             624
deepest.D             576
deepest.m             2495
deepest.quotient      815
lopez_ab_first_depth  1403
```

The script emits JSON including the exact witness checks and record frontier.

---

## Interpretation

The finite data say two things at once:

1. square completion is not a small cosmetic enlargement of López A/B; it can sharply reduce difficult first-hit depths;
2. the compression does not imply bounded latency, because the completed prime-modulus backbone proves arbitrarily large exact finite depths.

The useful proof question is therefore not

> “Is completed depth bounded?”

but

> “Why can no prime avoid every symmetric completed layer, even though the first successful layer can occur arbitrarily late?”
