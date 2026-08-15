# Current research frontier

**Date:** 2026-08-15  
**Claim boundary:** Erdős-Straus open; all-prime Type A/B coverage open. **Universal DSC-0 and DSC-P are false.**

## Major correction and falsification

The exact Dirichlet condition is

\[
\gcd(r+Ls,LQ)=1,
\]

not `gcd(s,Q)=1`.

After correcting that domain, the research program found and independently verified an explicit counterexample to Direct-Shadow Completeness.

See:

- `REDUCED-PARAMETER-DOMAIN.md`
- `DSC-COUNTEREXAMPLE.md`

The counterexample is

```text
k = 4,478,950
m = 17,915,799
h = 1
t = 17,892,349
r = 1,236,166,681
L = 5,016,423,720
```

It has **zero** direct-shadow sources among all `4,478,949` earlier layers, but the three ancestry-minimal q=3 rows

```text
j=70  -> s=0 mod 3
j=25  -> s=1 mod 3
j=187 -> s=2 mod 3
```

cover every integer parameter.

Therefore

\[
\boxed{\text{DSC-0 is false}}
\]

and

\[
\boxed{\text{DSC-P is false}.}
\]

Do not rebuild either conjecture under a renamed form.

---

## Hosted counterexample provenance

```text
workflow run: 31863463072
workflow sha: 566520c0649b30151c1120c902030c8a758844f2
artifact id:  9241281418
artifact digest:
sha256:021bb1142fdd5b069ee8492b92405d0e3dcad2ada9647f8e22c8af951b175b91
```

Two independent exhaustive verifiers agree:

```text
primary:
  earlier layers: 4,478,949
  q>2*tau pruned: 4,478,643
  exact candidates tested: 306
  direct shadows: 0

independent:
  sqrt-bound survivors: 24,795
  exact |T| survivors: 277
  direct shadows: 0

q=3 union mask: 7 = {0,1,2}
verdict: DIRECTLY_NOVEL_UNION_SHADOW
```

---

## Structural results retained

The counterexample kills the universal **collapse** from collective coverage to direct coverage. It does not invalidate the underlying local theorems.

| Result | Status |
|---|---|
| Exact reduced parameter domain | proved |
| Strong q=3 absorption | proved |
| Weak q=3 redundancy | proved |
| Pointwise frozen absorption | proved |
| Pointwise divisor descent | proved |
| One global q=3 next digit | proved |
| q=3 factor-pair species | proved |
| Ancestry / quotient rigidity theorems | retained in stated scopes |
| Character / signature / multiplicative tools | retained |
| Fiber peeling | retained |
| CN-coprime CRT statement | retained in pairwise-coprime hypothesis |
| Finite DSC certificates through `k<=1500` | still true finite statements |
| Universal DSC-0 | **false** |
| Universal DSC-P | **false** |

The `k<=100000` primitive/minimal q=3 zero-cover certificates also remain true finite results; the first constructed full minimal cover lies later at `k=4,478,950`.

---

## New first-class object: the collective core

The correct obstruction object is a minimal family of proper pullbacks whose union covers the candidate parameter domain even though no single member covers it.

Call such a family a **collective core**.

The counterexample supplies the first explicit irreducible core of this program:

\[
\boxed{\mathcal C=\{25,70,187\}.}
\]

All three have `q=3`, and their factor-pair species are

\[
(2,5),\qquad(5,2),\qquad(8,8)\pmod9.
\]

They realize the complete three-symbol next-digit alphabet.

This is not a failure of Type A/B coverage. It is a **successful earlier-layer rescue** of an otherwise directly novel target candidate.

---

## New research architecture

For each admissible target candidate:

1. reconstruct exact pullbacks on the exact affine Dirichlet domain;
2. remove direct/frozen absorption;
3. descend pointwise along divisor ancestry;
4. merge duplicate/residue-redundant constraints;
5. apply exact fiber peeling / character / multiplicative quotients;
6. identify the irreducible residual hypergraph;
7. determine whether it:
   - has an avoiding parameter, or
   - contains a collective core covering the domain.

The global theorem target is no longer `direct novelty -> realization`.

It is to classify the terminal alternatives and use them to control the all-prime survivor process.

---

## Prime endgame

`PRIME-REDUCTION.md` proves the elementary divisor-scaling reduction:

\[
\boxed{
\text{Erdős-Straus for all primes}
\Longrightarrow
\text{Erdős-Straus for all integers }n\ge2.
}
\]

Thus there is no separate composite-`n` endgame.

The main unresolved wall is **all-prime coverage**.

López Type A/B is a powerful primary route, but it need not be an exclusive route: any rigorously proved auxiliary parametrization may cover residual primes.

---

## Active edge

1. **Formalize collective cores**: minimality, projection, ancestry reduction, core rank, and exact covering certificates.
2. Build a collective-core census/falsifier beyond the constructed example; determine whether every union shadow admits a small prime-power core.
3. Replace the old DSC survivor process with a **realizable-or-collectively-covered** recursion.
4. Correct shared-core lift-room/fiber theorems to use full residue rings at primes dividing `L`.
5. Return to the all-prime remainder. Density-one is not enough.
6. Use independent divisor parametrizations as a secondary sieve against any hypothetical Type A/B survivor.

---

## One-line status

Direct-shadow completeness is dead by explicit verified counterexample. The research has moved to **collective-core theory**: directly novel target candidates can be rescued by irreducible unions of earlier Type A/B layers. Erdős-Straus remains open, and all-prime coverage is now the true endgame.
