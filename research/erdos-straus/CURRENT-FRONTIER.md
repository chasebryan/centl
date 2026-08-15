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
| Finite candidatewise DSC through k<=1500 | parent certificates |

## Research split

### A. Erdős-Straus track: highest priority

DSC was an unnecessarily strong exact-depth bridge. A union-shadowed candidate is already solved at an earlier Type A/B layer, so the ES problem does not require every target candidate to be independently realizable.

The real remaining prime problem is:

\[
\boxed{\text{every Mordell-hard prime has at least one Type A/B hit}.}
\]

Equivalently, every prime escaping the density-one prime-modulus backbone must receive a **composite rescue**.

Priority:

1. attack the zero-density prime-modulus survivor core directly;
2. classify composite-rescue mechanisms by factorization of `4k-1` and shifted integers;
3. connect the current Type A/B language with complete divisor parametrizations of Egyptian-fraction solutions;
4. only after all-prime coverage is closed, use the standard divisor/scaling reduction for composite `n`.

### B. Depth-spectrum track

Replace the false direct-shadow graph completeness conjecture by a **covering-core / hypergraph** theory.

Priority:

1. classify minimal union-shadow cores, beginning with the three-row q=3 core in `DSC-COUNTEREXAMPLE.md`;
2. retain strong/weak/pointwise absorption as hyperedge reductions;
3. determine which candidate classes are exact-depth realizable after collective cores are included.

This remains mathematically valuable but is no longer the shortest ES route.

## One-line status

The proposed universal exact-depth bridge has been constructively falsified and independently verified. The ES attack is now cleaner: **prove pointwise Type A/B coverage of the zero-density composite-rescue core; do not spend the main proof effort trying to resurrect DSC.**
