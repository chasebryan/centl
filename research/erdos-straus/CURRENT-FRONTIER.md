# Current research frontier

**Date:** 2026-08-15  
**Claim boundary:** Erdős-Straus open; universal DSC-P open; all-prime coverage open.

## Governing correction

The exact Dirichlet condition is

\[
\gcd(r+Ls,LQ)=1,
\]

not `gcd(s,Q)=1`.

`REDUCED-PARAMETER-DOMAIN.md` proves:

- if `p|Q` and `p|L`, the prime `p` imposes **no** restriction on the parameter class;
- if `p|Q` and `p∤L`, exactly one affine class `s=-rL^{-1} (mod p)` is excluded.

Hence for `q=3`, because `3|840|L`, the exact local domain is all of

\[
\boxed{\mathbb Z/3\mathbb Z.}
\]

The former complementary pair `{1},{2}` is not a true reduced obstruction.

---

## Closed / retained structural reductions

| Result | File |
|---|---|
| Exact reduced parameter domain | `REDUCED-PARAMETER-DOMAIN.md` |
| Strong q=3 absorption | `Q3-ABSORPTION.md` |
| Weak q=3 redundancy (`R_j subseteq R_i`) | `Q3-WEAK-REDUNDANCY.md` |
| Pointwise frozen absorption | `Q3-POINTWISE-ABSORPTION.md` |
| Pointwise divisor descent (`q_i in {1,3}`) | `Q3-POINTWISE-DIVISOR-REDUCTION.md` |
| One global next 3-adic digit | `Q3-NEXT-DIGIT-THEOREM.md` |
| Three factor-pair species / target congruence | `Q3-FACTOR-PAIR-TYPES.md` |
| Prime reduction for full ES | `PRIME-REDUCTION.md` |
| Original finite DSC through `k<=1500` | `DIRECT-SHADOW-K1500.md` |

The original finite DSC verifier remains valid because it checks `gcd(r+Ls,LQ)=1` directly.

---

## Frozen corrected-domain finite frontiers

### Corrected tight cluster through k <= 8500

Hosted replay proved:

- first full corrected-domain tight covers at `k=8378`;
- q=3 rows `52,70,106` occupy `0,1,2`;
- all 12 such candidate failures are already directly shadowed by frozen rows `6,12`;
- directly novel corrected-domain tight failures: **0**.

### Pointwise-primitive q=3 through k <= 100000

`Q3-PRIMITIVE-COVER-K100000.md` freezes:

```text
admissible candidates evaluated: 3,567,030
full primitive q=3 covers:                0
```

Complete union masks:

```text
0: 3320884
1:   77008
2:   82372
3:     146
4:   86322
5:     145
6:     153
7:       0
```

### Ancestry-minimal alignment through k <= 100000

`Q3-MINIMAL-ALIGNMENT-K100000.md` freezes the sharper descent:

```text
minimal rows on candidate:
0: 3320884
1:  239568
2:    6566
3:      12

maximum minimal rows: 3
three-or-more-row candidates: 12
three-or-more rows occupying >=2 digits: 0
full minimal q=3 covers: 0
```

All twelve three-row candidates put all three rows on one common next digit.

---

## Exact q=3 formulation now

Every q=3 trap has an ordered factor pair

\[
wa=m+1.
\]

In the common `v3(L)=1` regime, hard compatibility forces exactly three modulo-9 species:

\[
\boxed{(w,a)\equiv(2,5),(5,2),(8,8)\pmod9.}
\]

These are exactly the three global next 3-adic digits.

For a target trap factor pair

\[
WA=M+1,
\]

and any shared target divisor `b`, an aligned local pair satisfies

\[
\boxed{(W,A)\equiv(w,a)\pmod b}
\]

and therefore

\[
\boxed{b\mid(Wa-wA).}
\]

On a directly novel candidate every q=3 forbidden digit descends to an **ancestry-minimal** factor pair without changing the digit.

Thus the active universal q=3 target is:

\[
\boxed{
\text{one admissible target factor pair cannot align ancestry-minimal local pairs of all three modulo-9 species.}
}
\]

A proof closes the corrected q=3 local covering obstruction.

---

## Active edge

1. **Prove the ancestry-minimal factor-pair species theorem.** Use simultaneous target congruences and determinant divisibility `b|(Wa-wA)`; do not expand k merely for comfort.
2. Generalize corrected full-ring lift-room to arbitrary shared clusters. In particular `3,5,7|840|L`, so those coordinates use full residue rings rather than unit groups.
3. Re-run the Class-C active-core reduction on the exact affine domain and assemble corrected DSC-P.
4. Attack the all-prime remainder with more than one parametrization. López Type A/B is the primary structure, not a logically mandatory exclusive route.
5. Use `PRIME-REDUCTION.md`: once every prime is solved, Erdős-Straus is solved for every integer automatically. There is no separate composite-n endgame.

---

## One-line status

The artificial unit-parameter q=3 bottleneck is gone. The actual q=3 obstruction has been reduced to an ancestry-minimal three-species factor-pair alignment problem, with **zero full covers in two independent hosted constructions through k<=100000**. Universal DSC-P and all-prime Erdős-Straus coverage remain open.
