# Single-active Class-A local escape

**Status:** proved universal local lemma  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Coordinator:** primary research coordinator  
**Partner input:** Operator-02 active fixed-negative split and valuation criterion  
**Claim boundary:** this lemma resolves the unique active fixed-negative row locally under a Class-A hypothesis. It does **not** by itself prove the full Class-C system, universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture.

Read with:

- [CLASS-C-C1-SINGLE-ACTIVE.md](CLASS-C-C1-SINGLE-ACTIVE.md)
- [OPERATOR-COORDINATION.md](OPERATOR-COORDINATION.md)
- [operator-02/DIAMOND-FIXED-NEGATIVE-PULLBACK-SPLIT.md](operator-02/DIAMOND-FIXED-NEGATIVE-PULLBACK-SPLIT.md)
- [operator-02/DIAMOND-VALUATION-CRITERION.md](operator-02/DIAMOND-VALUATION-CRITERION.md)

## 1. Setup

Fix a directly novel admissible target candidate

\[
x=r+Ls,
\qquad
L=\operatorname{lcm}(840,4k-1),
\qquad
\gcd(r,L)=1.
\]

Let `j<k` be an earlier layer and put

\[
m_j=4j-1,
\qquad
g_j=\gcd(L,m_j),
\qquad
q_j=m_j/g_j.
\]

Its exact pulled-back Type A/B forbidden set is

\[
R_j\subseteq\mathbb Z/q_j\mathbb Z.
\]

Assume `j` lies in the active fixed-negative core and that its valuation excess is **Class A only**:

\[
\boxed{p\mid q_j\Longrightarrow p\mid L.}
\]

Equivalently, no prime absent from `L` survives into `q_j`; activity comes only from higher powers of primes already fixed by the target progression.

## 2. Local escape theorem

### Theorem

If the target candidate is not directly shadowed by layer `j` and

\[
\operatorname{rad}(q_j)\mid L,
\]

then there exists

\[
s_0\pmod{q_j}
\]

such that

\[
r+Ls_0\pmod{m_j}\notin T_j.
\]

Moreover every such choice is automatically reduced at every prime dividing `q_j`.

### Proof

Direct shadowing by `j` is exactly the statement that every parameter residue modulo `q_j` is forbidden:

\[
R_j=\mathbb Z/q_j\mathbb Z.
\]

The candidate is directly novel, so in particular it is not directly shadowed by `j`. Therefore

\[
R_j\ne\mathbb Z/q_j\mathbb Z.
\]

Choose

\[
s_0\notin R_j.
\]

By definition of the exact pullback, this gives

\[
r+Ls_0\pmod{m_j}\notin T_j.
\]

Now let `p|q_j`. By the Class-A hypothesis, `p|L`. Hence

\[
r+Ls_0\equiv r\pmod p.
\]

Since the target progression is admissible,

\[
\gcd(r,L)=1,
\]

so `p` does not divide `r`. Thus

\[
p\nmid r+Ls_0.
\]

This holds for every `p|q_j`, so every local escape residue is automatically reduced on the active layer's prime support. QED.

## 3. CRT independence corollary

### Corollary

Under the theorem's hypotheses, the local escape choice

\[
s\equiv s_0\pmod{q_j}
\]

can be combined by CRT with **arbitrary** parameter congruence conditions whose moduli are coprime to `q_j`.

### Proof

This is the ordinary Chinese remainder theorem. The point here is structural: Class-A activity lives entirely on prime-power lifts of coordinates already contained in `L`, while genuinely new parameter coordinates away from those primes are coprime to `q_j`. QED.

## 4. What the lemma removes

For a candidate with

\[
|\mathcal N^{\rm act}_{k,r}|=1,
\]

let `j0` be the unique active fixed-negative layer.

If `j0` is Class A only, then:

1. the unique active fixed-negative row itself always has an exact local escape;
2. reducedness cannot eliminate that escape;
3. any remaining obstruction must come from compatibility with other exact rows sharing the same small prime-power coordinates, or from nonfixed rows surviving the finer reductions.

So the unique active row is **not**, by itself, a local covering obstruction.

This is weaker than full C1 because the complete residual system can contain nonfixed exact constraints.

## 5. Finite k <= 1500 signal

The coordinated primary replay of the frozen `k<=1500` bundle found, before independent workflow verification is promoted:

```text
exactly one active fixed-negative layer: 2,770 candidates
Class-A-only source:                     2,770
Class-B or mixed source:                     0
observed q_j0:                           3, 5, 9
minimum reduced-safe residues mod q_j0:     2
```

Thus every single-active candidate in that finite range lies inside the theorem above.

These counts remain finite evidence until the dedicated Class-C census workflow completes and freezes its independent verifier/artifact.

## 6. A sharper finite observation to test

The same replay indicates that after exact fiber peeling the unique active fixed-negative row survives into the final nonempty residual kernel only very rarely, while most residual edges in this single-active population come from nonfixed earlier layers.

If independently verified, that means the next C1 proof target should not be phrased as merely "escape the unique active row." The theorem above already does that locally. The real task is:

> prove that the active-row escape can always be coordinated with the surviving nonfixed exact rows.

That is a much sharper statement.

## 7. Falsifier and boundary

The theorem would fail only if one of its explicit hypotheses failed:

- the candidate were directly shadowed, making `R_j` full;
- a prime dividing `q_j` were absent from `L` (Operator-02 Class B), so reducedness and free-coordinate compatibility would require additional work;
- or the target progression were not reduced/admissible.

No claim is made for Class-B activity here.

The lemma is elementary once the active-core/valuation language is isolated. Its value is as a rigorous reduction inside the coordinated DSC-P proof architecture, not as a stand-alone resolution of the Erdős-Straus problem.
