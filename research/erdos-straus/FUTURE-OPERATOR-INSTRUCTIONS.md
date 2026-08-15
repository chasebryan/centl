# Future Operator Instructions

**Date:** 2026-08-15  
**Scope:** `research/erdos-straus/`

## Standing order

Use the exact affine Dirichlet domain from `REDUCED-PARAMETER-DOMAIN.md`. Do **not** equate reducedness with `gcd(s,Q)=1`.

The q=3 problem has already passed through strong absorption, weak redundancy, pointwise absorption, and full divisor descent. Do not reopen obsolete complementary-pair work. The next proof target is the ancestry-minimal factor-pair species obstruction.

Keep every ES claim boundary exact.

---

## Priority 1 — close q=3 analytically

Use these proved assets in order:

1. `Q3-ABSORPTION.md`: strong descendants with nonempty pullback are directly shadowed.
2. `Q3-WEAK-REDUNDANCY.md`: weak descendants add no new q=3 class.
3. `Q3-POINTWISE-ABSORPTION.md`: an individual trap caught by a frozen divisor parent directly shadows the candidate.
4. `Q3-POINTWISE-DIVISOR-REDUCTION.md`: every individual q=3 trap caught by any divisor ancestor either direct-shadows (`q=1`) or descends to the same digit (`q=3`).
5. `Q3-NEXT-DIGIT-THEOREM.md`: all q=3 rows read one common next 3-adic digit.
6. `Q3-FACTOR-PAIR-TYPES.md`: in the `v3(L)=1` regime the three digits are the three factor-pair species
   \[
   (2,5),(5,2),(8,8)\pmod9,
   \]
   and aligned local/target pairs satisfy
   \[
   (W,A)\equiv(w,a)\pmod b,
   \qquad b\mid(Wa-wA).
   \]

**Target theorem:** one admissible target factor pair cannot align ancestry-minimal q=3 local pairs of all three species.

Do not substitute another finite k-extension for this proof unless it is an adversarial counterexample hunt motivated by a concrete failed lemma.

---

## Frozen falsification evidence

### k <= 100000 primitive cover

`Q3-PRIMITIVE-COVER-K100000.md`:

```text
admissible candidates: 3,567,030
full primitive q=3 covers: 0
```

### k <= 100000 ancestry-minimal alignment

`Q3-MINIMAL-ALIGNMENT-K100000.md`:

```text
maximum minimal rows on one candidate: 3
candidates with >=3 minimal rows: 12
>=3 rows occupying >=2 digits: 0
full minimal covers: 0
```

The 12 exceptional three-row cases are proof-mining laboratories, not evidence of a theorem by themselves.

---

## Priority 2 — rebuild shared-core escape on the exact domain

After q=3 is analytically closed:

1. generalize lift-room from unit fibers to the exact affine domain;
2. remember that `3,5,7 | 840 | L`, so these local coordinates use full residue rings;
3. for a free prime `p∤L`, exclude only the single global affine non-reduced class `-rL^{-1} mod p`;
4. rerun arbitrary shared-core peeling with those exact domains;
5. reassemble corrected DSC-P only after exact avoidance and exact Dirichlet reducedness are both preserved.

---

## Priority 3 — all-prime wall

DSC-P is not the same statement as all-prime solvability.

After the exact-depth machinery is corrected, attack the pointwise all-prime remainder. López Type A/B remains the primary structural route, but do not artificially require that every prime be solved **only** by López if another rigorous parametrization covers the residual set.

`PRIME-REDUCTION.md` proves that solving every prime immediately solves every integer by denominator scaling. There is no independent composite-`n` theorem after the prime case.

The 2026 divisor-parametrization literature is therefore a legitimate secondary route for the prime remainder, subject to explicit attribution and independent checking.

---

## Required claim discipline

- A finite certificate is not a universal proof.
- `gcd(s,Q)=1` is an auxiliary sufficient subset, not the exact reduced domain.
- A two-class q=3 union is not an obstruction because `3|L`.
- A bounded witness failure is not union coverage.
- `C1-THEOREM.md` must not be cited as an unconditional infinite-strip proof until its certificate-supported boundary strip is analytically hardened.
- Do not announce Erdős-Straus solved without a complete deposited proof for all primes (prime reduction then supplies all integers).

---

## Forbidden regressions

Do not restore:

- complementary `{1},{2}` q=3 pairs as the main obstruction;
- `205` as the universal q=3 family;
- weak/base whole-layer labels as the final granularity after pointwise divisor descent;
- a separate composite-`n` wall after all primes are solved.
