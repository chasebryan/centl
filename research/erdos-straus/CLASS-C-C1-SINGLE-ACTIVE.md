# C1: single-active Class-C attack

**Status:** coordinated theorem target and falsification design  
**Date:** 2026-08-14  
**Coordinator:** primary research coordinator  
**Partner input:** Operator-02 `DIAMOND-CLASS-C-NODE.md`, `DIAMOND-FIXED-NEGATIVE-PULLBACK-SPLIT.md`, `DIAMOND-VALUATION-CRITERION.md`  
**Claim boundary:** this file defines an attack. It does not prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture.

## 1. Target

Fix a directly novel Type A/B candidate

\[
x\equiv r\pmod L,
\qquad L=\operatorname{lcm}(840,4k-1).
\]

For each earlier layer `j<k`, put

\[
m_j=4j-1,
\qquad
q_j=\frac{m_j}{\gcd(L,m_j)}.
\]

Let

\[
\mathcal N_{k,r}
=\{j<k:\sigma(m_j)\in F_k,\ (r/m_j)=-1\}
\]

be the fixed-negative character core, and define Operator-02's active subcore

\[
\boxed{
\mathcal N^{\mathrm{act}}_{k,r}
=\{j\in\mathcal N_{k,r}:q_j>1\}.
}
\]

The first coordinated special case is

\[
\boxed{|\mathcal N^{\mathrm{act}}_{k,r}|=1.}
\]

Call the unique active fixed-negative layer `j0`.

## 2. Why C1 is the correct first target

Character-shield completeness says the free quadratic signs can make every earlier layer outside the fixed-negative core Jacobi-positive. Fixed-negative layers with `q_j=1` are parameter-inactive and direct novelty already guarantees that their locked residue is not an exact Type A/B trap.

Thus when the active core has one member, all remaining exact difficulty is concentrated at one moving fixed-negative layer, together with reducedness and any finer local compatibility required to realize the chosen character assignment.

The central question is therefore:

> Does direct novelty at the unique active layer always leave a residue choice that is compatible with the global character shield and reducedness?

A proof would establish a genuine infinite special case of DSC-P rather than a finite-range statistic.

## 3. Valuation source split

For the unique active layer,

\[
q_{j_0}>1
\iff
\exists p:\ v_p(m_{j_0})>v_p(L).
\]

The excess primes are classified as:

- **Class A:** `p|L` with a higher power in `m_j0` than in `L`;
- **Class B:** `p∤L` occurring to even valuation in `m_j0`, hence invisible to the squareclass/Jacobi row but still active on the parameter line.

The C1 census must separate these two mechanisms.

## 4. Exact finite census to run first

On the already verified `k<=1500` candidate bundle, the primary analyzer will compute for every directly novel candidate:

1. `|N|` and `|N_act|`;
2. the unique active layer when `|N_act|=1`;
3. `q_j0` and its prime-power factorization;
4. Class A and Class B valuation witnesses;
5. the exact pulled-back forbidden set `R_j0`;
6. whether the candidate's fiber kernel is empty;
7. if nonempty, its residual prime signature;
8. whether all residual kernel primes are explained by Class A/B valuation witnesses from `N_act`;
9. bounded-selector radius from the independently generated selector construction where available;
10. the exact number of safe residues modulo `q_j0` before and after reducedness.

The output is a census, not a theorem.

## 5. Falsifiers

The C1 theorem route is weakened or falsified in its proposed form if the census finds any of the following:

- a single-active candidate whose post-character exact constraints require an additional active fixed-negative layer not captured by `N_act`;
- a residual kernel coordinate with no valuation-source explanation from the active layer and no separately identified non-fixed-negative source;
- a unique active layer whose exact safe set is nonempty by direct novelty but every safe choice conflicts with the necessary character/reducedness conditions;
- evidence that the local compatibility problem cannot be represented on the active layer's valuation-excess coordinates.

None of these would falsify DSC-P itself. They would falsify this proof route.

## 6. Candidate proof route

For `|N_act|=1`, attempt to show:

1. all other earlier layers can be made Jacobi-positive by the proved character-shield extension;
2. inactive fixed-negative layers are exact-safe by direct novelty;
3. the unique active layer has a proper forbidden pullback set `R_j0` because direct shadow is absent;
4. the remaining character choices restrict only signs or higher-power lifts on the prime-power coordinates of `q_j0`;
5. the two-box / multiplicative trap structure prevents those compatible choices from exhausting the complement of `R_j0`;
6. choose one reduced local residue and reverse the fiber/CRT construction;
7. Dirichlet gives infinitely many exact-depth primes.

The high-value lemma is Step 5.

## 7. Relationship to Operator-02

Operator-02 is asked to attack C1 independently from the formulation side:

- classify possible Class A/B valuation patterns when `|N_act|=1`;
- search for a direct local lemma forcing at least one safe residue;
- identify any hidden source of residual constraints omitted by the primary formulation;
- adversarially test any Coordinator proof attempt.

The Coordinator owns the canonical census, proof promotion, workflow integration, and theorem claim boundary.

## 8. Promotion rule

C1 is promoted from `THEOREM-CANDIDATE` to `PROVED` only after a universal proof is written and independently checked. A clean `k<=1500` census, even with zero exceptions, remains finite evidence only.
