# Direct-Shadow Completeness attack through k = 1000

**Status:** exact finite theorem-certificate result; universal theorem remains open  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Research lineage:** [DIAMOND.md](DIAMOND.md) -> [DIRECT-SHADOW-COMPLETENESS.md](DIRECT-SHADOW-COMPLETENESS.md) -> this record

This record extends the candidatewise falsification attack from `k <= 600` to `k <= 1000`.

It does **not** prove universal Direct-Shadow Completeness, Lopez Type A/B coverage, or the Erdos-Straus conjecture. Every positive statement below is either an exact finite certificate statement or a standard consequence of such a certificate together with Dirichlet's theorem.

## 1. Candidatewise question

For a hard-class-compatible Type A/B candidate `(k,h,t)`, write

\[
x=r+Ls,
\qquad L=\operatorname{lcm}(840,4k-1).
\]

Each earlier layer `j<k` pulls back to a forbidden residue set

\[
R_j\subseteq \mathbb Z/q_j\mathbb Z,
\qquad q_j=\frac{4j-1}{\gcd(L,4j-1)}.
\]

A direct shadow means one `R_j` is already the complete parameter space. The stronger failure mode under attack is **union shadowing**: no single `R_j` is complete, but the union of several proper forbidden systems covers every integer `s`.

The prime-realization form, DSC-P, asks whether every directly novel candidate contains an avoiding `s_0` satisfying

\[
\gcd(r+Ls_0,LQ)=1,
\qquad Q=\operatorname{lcm}\{q_j:R_j\neq\varnothing\}.
\]

Such a reduced class contains infinitely many primes whose first Type A/B hit occurs at depth `k`.

## 2. Exact k <= 1000 run

The automated workflow used:

- all six Mordell-hard classes modulo `840`;
- every layer through `k=1000`;
- every prime-compatible Type A/B target candidate;
- witness search through `s=1,000,000`;
- a discovery implementation;
- a separate independent verifier;
- CENTL exact certification of selected hardest CRT progression identities;
- SHA-256 freezing and artifact publication.

Result:

```text
admissible candidates:             46,254
directly shadowed candidates:      12,610
directly novel candidates:         33,644
integer avoiding witnesses:        33,644
reduced avoiding witnesses:        33,644
unresolved integer candidates:          0
unresolved reduced candidates:          0
```

Therefore, throughout this finite domain,

\[
\boxed{
33,644/33,644
\text{ directly novel candidates are not union-shadowed.}
}
\]

More strongly,

\[
\boxed{
33,644/33,644
\text{ directly novel candidates have reduced avoiding progressions.}
}
\]

Thus every directly novel candidate through `k=1000` has an explicit infinite-prime exact-depth family.

## 3. Independent verification

The independent verifier returned

```json
{
  "direct_novel_candidates_checked": 33644,
  "integer_witnesses_verified": 33644,
  "k_limit": 1000,
  "reduced_witnesses_verified": 33644,
  "unresolved_integer_candidates": 0,
  "unresolved_reduced_candidates": 0,
  "verdict": "VERIFIED"
}
```

The verifier independently reconstructs trap sets, CRT candidates, direct-shadow status, earlier-layer avoidance, the full parameter period, and the reduced gcd condition.

## 4. CENTL certification

CENTL separately verified the generated polynomial identities showing that selected hardest progressions remain simultaneously in the intended hard class and target Type A/B residue class for symbolic parameter `s`.

The modular avoidance claim is not delegated to CENTL: it is checked independently by the number-theoretic verifier. This separation is intentional.

## 5. Hardest reduced witnesses

The largest first reduced parameters in this run include:

| k | h | t | first reduced s | x = r + Ls |
|---:|---:|---:|---:|---:|
| 987 | 169 | 3935 | 730101 | 2420638196089 |
| 992 | 289 | 3963 | 709237 | 2363376980449 |
| 950 | 169 | 3779 | 689094 | 2199011682169 |
| 1000 | 529 | 3979 | 685853 | 767963845009 |
| 915 | 289 | 3658 | 679831 | 2089502502649 |
| 902 | 289 | 3563 | 643752 | 1950492099649 |
| 804 | 529 | 3199 | 623459 | 336742774729 |
| 983 | 529 | 2948 | 605762 | 2000252995129 |
| 945 | 529 | 3671 | 593896 | 1885242060769 |
| 928 | 169 | 3583 | 574425 | 596873851729 |

The hardest examples are important because the finite success is not an artifact of every candidate escaping at a tiny parameter.

## 6. What changed from k <= 600

The first candidatewise attack certified `19,016` directly novel candidates through `k=600`.

The present run adds `14,628` additional directly novel candidates and again finds **zero** union-shadow counterexamples and **zero** failures of reduced prime realization.

The implication

\[
\text{directly novel}\Longrightarrow\text{reduced avoiding progression}
\]

has therefore survived candidatewise exact certification through one thousand layers, but remains a conjecture beyond the certified finite range.

## 7. Relation to covering systems

The pullback family

\[
\mathscr R_{k,h,t}=\{(q_j,R_j):j<k,\ R_j\neq\varnothing\}
\]

is a highly structured odd-modulus covering problem. General families of proper congruence classes can certainly cover the integers, so the finite result requires explanation from the special Type A/B arithmetic.

The companion note [SHADOW-COVER-GEOMETRY.md](SHADOW-COVER-GEOMETRY.md) already shows that a simple density argument cannot explain the phenomenon: in the `k<=600` bundle, roughly 99.3% of directly novel candidates had nominal forbidden cover mass greater than one, often much greater than one.

The next proof target is therefore an invariant of the **intersection geometry** of the `R_j`, not merely their cardinalities.

## 8. New proof-search direction

The most promising constructive clue is to factor the parameter period into odd prime-power coordinates.

For each candidate, first impose only the constraints supported on a single prime-power coordinate. Select a canonical allowed local value, preferring `1` whenever possible. Then inspect how many genuinely multi-prime constraints remain violated.

Preliminary exact diagnostics on the certified bundle show that this simple coordinate construction already satisfies most tested candidates outright, while many failures appear repairable by changing only one or a few prime-power coordinates. This is not yet a theorem and is being promoted to a dedicated automated analyzer.

If a bounded local-repair principle can be proved, DSC-P may reduce from a global covering-system problem to a finite local compatibility theorem on prime-power coordinates.

## 9. Current conclusion

The strongest finite statement is now

\[
\boxed{
33,644/33,644
\text{ directly novel hard-compatible candidates through }k=1000
\text{ possess independently verified reduced exact-depth progressions.}
}
\]

No collective-shadow counterexample has appeared.

The universal theorem remains open. The research priority is now to explain why the Type A/B pullback systems fail to cover despite large nominal cover mass and heavy congruence dependence.