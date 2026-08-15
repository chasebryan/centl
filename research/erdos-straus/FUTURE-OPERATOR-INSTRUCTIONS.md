# Future Operator Instructions

**Date:** 2026-08-15  
**Scope:** `research/erdos-straus/`

## Standing order

Use the exact affine Dirichlet domain from `REDUCED-PARAMETER-DOMAIN.md`. Do **not** equate reducedness with `gcd(s,Q)=1`.

**Direct-Shadow Completeness is refuted.** `DSC-COUNTEREXAMPLE.md` is authoritative:

```text
k = 4,478,950
q=3 collective core = {25,70,187}
direct-shadow sources = 0
union mask = {0,1,2}
```

Therefore universal DSC-0 and DSC-P are false. Do not resurrect them under new notation, do not seek a proof of the former q=3 alignment impossibility, and do not interpret directly novel candidates as automatically realizable.

The new first-class object is the **collective core**.

---

## Priority 1 — formalize collective-core theory

For an admissible candidate progression `x=r+Ls`, reconstruct every earlier pullback `(q_j,R_j)` on the exact parameter domain.

Define and study an inclusion-minimal residual family whose union covers that domain while no proper subfamily does.

At minimum record:

1. core modulus `Q_C=lcm(q_j)`;
2. core rank `|C|`;
3. prime-power support of the q's;
4. exact local-domain sizes;
5. normalized load `sum |R_j|/q_j` or the corresponding exact-domain density;
6. private witness classes certifying inclusion-minimality;
7. ancestry / pointwise descent relations;
8. whether the core is integer-covering or only reduced-domain-covering.

The verified counterexample is the prototype:

\[
\boxed{\mathcal C=\{25,70,187\},\quad Q_C=3,\quad |\mathcal C|=3.}
\]

Each member supplies one private q=3 class, so the core has exact normalized load `1` and is irreducible.

---

## Priority 2 — turn q=3 factor pairs into a synthesis theorem

The algebra in `Q3-FACTOR-PAIR-TYPES.md` remains proved and is now constructive.

Local q=3 traps have factor pairs

\[
wa=m+1
\]

of the three modulo-9 species

\[
(2,5),\ (5,2),\ (8,8).
\]

For shared target support `b`, aligned target and local pairs satisfy

\[
(W,A)\equiv(w,a)\pmod b.
\]

Use CRT to synthesize target factor pairs from proposed local cores. Determine:

- when the resulting target is admissible;
- when local rows remain exact q=3 rows;
- when the resulting target is directly novel;
- whether infinitely many collective cores can be generated;
- whether there is a smaller counterexample than `k=4,478,950`.

The goal is classification/construction, not impossibility.

---

## Priority 3 — rebuild the global survivor process without DSC

The old implication

\[
\text{direct novelty}\Rightarrow\text{exact-depth realization}
\]

is false.

Replace it with a terminal-alternative analysis. After all exact reductions, a candidate may be:

1. **realizable**: an avoiding exact/reduced parameter survives; or
2. **collectively covered**: a minimal collective core catches every parameter.

Both outcomes are useful for the original all-prime coverage problem. A collective core means the target progression is already solved by earlier Type A/B layers.

Build a recursion/survivor theory that tracks these alternatives rather than forcing every directly novel candidate to realize its own depth.

---

## Priority 4 — correct the shared-core machinery

Reuse, but reread through the exact affine domain:

- character/signature/multiplicative quotients;
- fiber peeling;
- ancestry and pointwise descent;
- lift-room ideas;
- CN-coprime CRT results in their stated pairwise-coprime hypotheses.

Remember:

\[
3,5,7\mid840\mid L,
\]

so these coordinates use full residue rings, not unit groups.

For a free prime `p∤L`, exact reducedness excludes only the one affine class

\[
-rL^{-1}\pmod p.
\]

Do not rebuild a unit-parameter surrogate and call it exact.

---

## Priority 5 — all-prime wall

The true Erdős-Straus endgame is all-prime coverage.

`PRIME-REDUCTION.md` proves:

\[
\boxed{\text{all primes solved}\Longrightarrow\text{all integers solved}.}
\]

There is no independent composite-`n` theorem after the prime case.

López Type A/B remains the primary structural route, but it need not be logically exclusive. A rigorously proved auxiliary divisor parametrization may cover residual primes that are awkward in the Type A/B language.

Collective coverage is **not** an ES failure. It is earlier-layer success. Use that fact.

---

## Retained finite certificates

The following remain exact finite statements and should not be deleted merely because their universal extrapolations failed:

- candidatewise DSC through `k<=1500`;
- corrected tight-domain zero-novel-failure through `k<=8500`;
- primitive q=3 no-full-cover through `k<=100000`;
- ancestry-minimal q=3 alignment through `k<=100000`.

They describe the low-depth regime. `DSC-COUNTEREXAMPLE.md` proves that its eventual geometry changes.

---

## Required claim discipline

- Universal DSC-0: **false**.
- Universal DSC-P: **false**.
- Universal q=3 three-species impossibility: **false**.
- A finite zero-counterexample range remains a finite theorem-certificate, not a universal theorem.
- `gcd(s,Q)=1` is not the exact reduced condition.
- A bounded witness-search failure is not a cover proof.
- `C1-THEOREM.md` still requires analytic hardening of its certificate-supported infinite boundary strip before being treated as a conventional fully closed proof.
- Do not announce Erdős-Straus solved without a complete all-prime proof.

---

## Forbidden regressions

Do not restore:

- DSC or DSC-P as theorem targets;
- the universal ancestry-minimal alignment conjecture;
- complementary `{1},{2}` q=3 pairs as the exact reduced obstruction;
- `205` as the universal q=3 family;
- whole-layer strong/weak/base labels as final granularity when pointwise descent is available;
- a separate composite-`n` wall after all primes are solved.
