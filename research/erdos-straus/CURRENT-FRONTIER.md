# Current research frontier

**Date:** 2026-08-15  
**Claim boundary:** Erdős-Straus open; López Type A/B coverage for every prime open. Universal DSC-0 and DSC-P are **false**, by explicit hosted-verified counterexample.

## Major correction

The exact Dirichlet parameter condition is

\[
\gcd(r+Ls,LQ)=1,
\]

not `gcd(s,Q)=1`. See `REDUCED-PARAMETER-DOMAIN.md`.

For primes already dividing `L`, including `3,5,7`, reducedness imposes no restriction on the parameter coordinate. Thus the exact q=3 domain is all of `Z/3Z`.

## Major falsification

`DSC-COUNTEREXAMPLE.md` gives two explicit Mordell-hard admissible target candidates at

\[
k=4,217,870,554,934,815,548
\]

that are:

- directly novel: no earlier layer directly shadows them;
- union-shadowed: rows `6820`, `8602`, `9790` have q=3 singleton pullbacks covering `0,1,2`.

The standalone verifier checks every possible direct-shadow modulus using `DIRECT-SHADOW-SMOOTHNESS.md` and was replayed successfully in GitHub Actions:

```text
run:      31862644146
artifact: 9241048158
```

Therefore

\[
\boxed{\text{DSC-0 is false}}
\qquad\text{and}\qquad
\boxed{\text{DSC-P is false}.}
\]

All finite DSC certificates through `k<=1500` remain valid finite statements.

## Closed and retained

| Theorem/result | File |
|---|---|
| Exact reduced-parameter domain | `REDUCED-PARAMETER-DOMAIN.md` |
| Direct-shadow smoothness | `DIRECT-SHADOW-SMOOTHNESS.md` |
| Strong q=3 absorption | `Q3-ABSORPTION.md` |
| Weak q=3 redundancy | `Q3-WEAK-REDUNDANCY.md` |
| Pointwise q=3 absorption | `Q3-POINTWISE-ABSORPTION.md` |
| q=3 pullbacks are singleton | `Q3-SINGLETON-PULLBACK.md` |
| Explicit DSC counterexample | `DSC-COUNTEREXAMPLE.md` |
| Prime-modulus backbone / density-one prime capture | `PRIME-MODULUS-BACKBONE.md`, `COMPOSITE-CORE.md` |
| Coprime FAB divisor criterion | `FAB-COPRIME-DIVISOR-CRITERION.md` |
| Fixed-k signed divisor box / Kneser defect | `FAB-UNBOUNDED-DIVISOR-RATIO-CERTIFICATE.md`, `FAB-KNESER-DIVISOR-DEFECT.md` |
| Normalized Type-II target in the same signed box | `FAB-TYPE-II-SIGNED-DIVISOR.md` |
| Two-target Kneser collapse | `FAB-TWO-TARGET-KNESER.md` |
| Exact first combined defect | `FAB-INDEX6-COMBINED-DEFECT.md` |
| Finite candidatewise DSC through k<=1500 | parent certificates |

## New direct-ES correction: López-all-primes is not required

Universal López Type A/B coverage remains an important and experimentally strong conjecture, but it is **stronger than what is logically required to prove Erdős-Straus**.

The 2026 Bello-Hernández--Benito--Fernández divisor parametrization is complete for Erdős--Straus decompositions after the standard factor-4 scaling. The post-DSC direct route should therefore use the complete FAB/Type-I/Type-II geometry rather than require every prime to pass through the López Type A/B subfamily.

López-all-primes remains a parallel theorem target, not a prerequisite for the shortest direct ES route.

## Same fixed-k box, two exact solution targets

Fix a prime `p≡1 mod4` and a coprime shift

\[
k\equiv3\pmod4.
\]

Put

\[
C=\frac{p+k}{4}
=\prod_i r_i^{e_i}
\]

and define the signed divisor box

\[
\mathcal R_k(C)
=
\left\{
\prod_i r_i^{z_i}\pmod k:
-e_i\le z_i\le e_i
\right\}.
\]

The existing strong FAB / normalized Type-I lane uses the target

\[
\boxed{\tau_I=-p^{-1}\pmod k.}
\]

`FAB-TYPE-II-SIGNED-DIVISOR.md` proves that the standard normalized Type-II lane uses the **same** box with target

\[
\boxed{\tau_{II}=-1\pmod k.}
\]

Thus

\[
\boxed{
\tau_I\in\mathcal R_k(C)
\quad\text{or}\quad
\tau_{II}\in\mathcal R_k(C)
\Longrightarrow
p\text{ is solved}.}
\]

This is the present direct-ES collision point.

## External-nonresidue Kneser collapse

Let `q<p` be an external quadratic-nonresidue prime with

\[
q\equiv3\pmod4,
\qquad
\left(\frac qp\right)=-1,
\]

and use the fixed shift `k=q`.

Let

\[
H=\operatorname{Stab}(\mathcal R_q((p+q)/4)),
\qquad
n=[(\mathbb Z/q\mathbb Z)^\times:H].
\]

If both exact targets are missed, then `FAB-TWO-TARGET-KNESER.md` proves:

1. `n` cannot be odd, because every odd-index stabilizer contains `-1`, which is the Type-II target;
2. `n` cannot be `2`, because the Type-I target is a quadratic residue and lies in the index-two stabilizer;
3. therefore
   \[
   \boxed{n\ge6\text{ and }n\text{ is even};}
   \]
4. the two missed targets occupy distinct `H`-cosets;
5. the Kneser budget strengthens from the one-target bound `n-2` to
   \[
   \boxed{
   \sum_i
   \left(
   \min(2e_i+1,\operatorname{ord}_{G/H}(r_iH))-1
   \right)
   \le n-3.
   }
   \]

Consequently the former cubic-first hierarchy is no longer the direct ES wall:

\[
\boxed{
\text{every odd-index Type-I Kneser defect is automatically rescued by Type II}.}
\]

## First surviving combined defect: index six

`FAB-INDEX6-COMBINED-DEFECT.md` classifies the first possible case exactly.

If both targets miss and the stabilizer index is `6`, then

\[
H=G^6
\]

and

\[
\boxed{
\frac{p+q}{4}=rS
}
\]

with the following rigid structure:

1. there is exactly one prime factor `r` outside the sixth-power subgroup `G^6`;
2. `v_r((p+q)/4)=1`;
3. `rG^6` generates `G/G^6≅C_6`;
4. every prime factor of `S` is a sixth-power residue modulo `q`;
5. `r` is simultaneously a quadratic and cubic nonresidue modulo `q`;
6. shifted-nonresidue transfer makes `r` the **unique** external quadratic-nonresidue prime factor relative to `p`;
7. therefore the external-nonresidue factor graph has a forced edge
   \[
   \boxed{q\to r.}
   \]

The first combined obstruction is therefore a **single primitive sextic defect**, not a general index-six cloud.

## Research split

### A. Direct Erdős-Straus track: highest priority

The current shortest route is now:

1. work in the complete FAB / standard Type-I/II framework;
2. use the two targets in the same fixed-shift signed divisor box;
3. choose external nonresidue prime shifts to kill the quadratic obstruction;
4. exploit the fact that every genuine combined failure has even stabilizer index at least `6`;
5. attack the exact index-six primitive sextic defect and its forced external-nonresidue successor;
6. only if index six survives, move to the next even quotient under the stronger `n-3` budget;
7. once every prime is covered, apply the standard divisor/scaling reduction for composite `n`.

The next theorem target is:

\[
\boxed{
\text{primitive sextic defect at }q
\Longrightarrow
\text{forced successor }r\text{ cannot sustain a compatible combined defect cycle}.}
\]

### B. López Type A/B track

Continue studying

\[
\boxed{\text{every Mordell-hard prime has at least one Type A/B hit}}
\]

and the zero-density composite-rescue core. This remains mathematically valuable and may still produce the final proof, but it is no longer imposed as a prerequisite for the direct ES route.

### C. Depth-spectrum track

Replace the false direct-shadow graph completeness conjecture by a **covering-core / hypergraph** theory.

Priority:

1. classify minimal union-shadow cores, beginning with the three-row q=3 core in `DSC-COUNTEREXAMPLE.md`;
2. retain strong/weak/pointwise absorption as hyperedge reductions;
3. determine which candidate classes are exact-depth realizable after collective cores are included.

This remains mathematically valuable but is no longer the shortest ES route.

## One-line status

The direct proof search has moved past DSC and past the one-target cubic Kneser wall: **Type I and Type II are now coupled in one signed divisor box, every odd-index defect collapses, and the first surviving all-prime obstruction is a forced single-prime index-six sextic defect.**
