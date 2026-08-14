# Shadow-cover geometry behind Direct-Shadow Completeness

**Status:** exact finite diagnostic from the verified `k <= 600` candidate bundle  
**Date:** 2026-08-14  
**Claim boundary:** this note identifies a proof obstruction and a stronger theorem target. It does not prove universal Direct-Shadow Completeness.

This note follows [DIRECT-SHADOW-COMPLETENESS.md](DIRECT-SHADOW-COMPLETENESS.md). The candidatewise run established that all `19,016` directly novel hard-compatible candidates through `k=600` have reduced avoiding progressions. The question here is **why** that happens.

For a candidate progression

\[
x=r+Ls,
\]

each earlier Type A/B layer `j<k` forbids a finite set

\[
R_j\subseteq\mathbb Z/q_j\mathbb Z,
\qquad
q_j=\frac{4j-1}{\gcd(L,4j-1)}.
\]

The candidate is union-shadowed exactly when these pulled-back forbidden residue systems cover every integer parameter `s`.

---

## 1. A cheap density proof does not explain the result

A first possible explanation would be a union bound. Define the raw **cover mass**

\[
W(k,h,t)=\sum_{j<k}\frac{|R_j|}{q_j},
\]

summing only nonempty forbidden systems.

If `W<1`, the union bound immediately proves that the forbidden systems cannot cover all integers. If most directly novel candidates had `W<1`, Direct-Shadow Completeness would have a simple density explanation.

That is emphatically not what the verified `k<=600` bundle shows.

Across all `19,016` directly novel candidates:

```text
minimum W:        0
median W:         8.500010768048488
mean W:           7.906791184249354
maximum W:        10.789829231455588
W < 1:            132 candidates
W > 1:         18,884 candidates
```

Thus

\[
\boxed{18,884/19,016\approx99.306\%}
\]

of directly novel candidates have raw cover mass **greater than one**, often much greater than one, yet every one of them still has an explicit avoiding parameter and a reduced Dirichlet progression.

Therefore the observed noncoverage is not explained by low total forbidden density.

The overlap and dependency geometry among the forbidden congruences is doing essential arithmetic work.

---

## 2. The constraint systems are genuinely dense

The same exact recomputation gives, among the directly novel candidates through `k=600`:

```text
median number of active earlier constraints: 251
mean number of active earlier constraints:   245.6381994110223
maximum active earlier constraints:          477
```

So a typical candidate is not escaping because only a handful of earlier layers interact with it. Hundreds of earlier Type A/B layers can impose nonempty forbidden parameter classes.

Nevertheless the complete collection still fails to cover the parameter line in every tested directly novel candidate.

---

## 3. Nor is there a simple new-coordinate explanation

Another tempting explanation is that each successive constraint might introduce a fresh CRT prime-power coordinate, leaving enough freedom to escape.

That is also false in its simplest form.

Process the active constraints in increasing layer order and maintain the accumulated parameter modulus

\[
Q_i=\operatorname{lcm}(q_1,\ldots,q_i).
\]

Call a constraint **new-coordinate** if adjoining its `q_j` enlarges the accumulated lcm, and **old-coordinate** otherwise.

Across the verified candidate bundle, both kinds occur heavily. The median counts are approximately

```text
new-coordinate constraints: 145
old-coordinate constraints:  108
```

and some candidates have more than `200` active old-coordinate constraints.

For the hardest first-run reduced witness

\[
(k,h,t)=(500,529,1979),
\]

there are `392` active earlier constraints:

```text
207 new-coordinate constraints
185 old-coordinate constraints
```

So the finite theorem cannot be explained by saying that every forbidden layer acts on a fresh independent coordinate.

---

## 4. The stronger structural clue

We now know three things simultaneously in the tested range:

1. no single earlier layer covers a directly novel candidate;
2. the total nominal forbidden density is usually far above `1`;
3. hundreds of dependent constraints nevertheless leave a reduced avoiding progression.

This points toward a special **overlap theorem** for Type A/B pullback constraints.

The important object is no longer merely the list of forbidden densities

\[
|R_j|/q_j.
\]

It is their structured intersection geometry.

A future proof of Direct-Shadow Completeness must explain why Type A/B forbidden residue systems overlap so strongly that collective coverage cannot arise without one layer already becoming a direct shadow.

That property would be special. General covering systems absolutely can cover the integers without any single constituent covering them, so no generic union-bound or generic CRT argument can establish the desired theorem.

---

## 5. Refined theorem target

For a directly novel candidate `(k,h,t)`, define the finite pullback family

\[
\mathscr R_{k,h,t}
=
\{(q_j,R_j):1\le j<k,\ R_j\ne\varnothing\}.
\]

The experimental phenomenon can be stated as:

\[
\boxed{
R_j\ne\mathbb Z/q_j\mathbb Z\ \forall j
\quad\Longrightarrow\quad
\bigcup_j\{s:s\bmod q_j\in R_j\}\ne\mathbb Z.
}
\]

for every tested Type A/B pullback family.

The prime-realization version adds that the complement contains a residue class `s0` for which

\[
\gcd(r+Ls_0,LQ)=1.
\]

The candidate proof mechanism should therefore search for an invariant of the **family of pullbacks**, not merely of individual `q_j` or cardinalities `|R_j|`.

---

## 6. High-value proof directions

The next proof search should test the following mechanisms.

### A. Shadow-of-shadow redundancy

Many old-coordinate constraints may themselves be redundant after pullback. Determine whether every apparently new forbidden class is contained in the union of a small ancestral basis while the basis itself necessarily leaves a residue uncovered.

### B. Prime-power coordinate signatures

Factor every `q_j` into prime powers and study which local coordinates each `R_j` can occupy. Search for a prime-power coordinate on which all active Type A/B forbidden sets omit a common compatible value.

### C. Multiplicative character obstruction

The residues in `T_j` are generated from divisors of `j` by the two maps `e -> -e` and `e -> -4e`. Their affine pullbacks may preserve a quadratic, multiplicative, or divisor-theoretic signature that prevents arbitrary covering-system behavior.

### D. Minimal-cover contradiction

Assume a smallest union-shadowed but not directly shadowed candidate exists. Extract a minimal subcover of parameter residue systems. Classical covering-system constraints on repeated maximal moduli or prime-power divisibility may then collide with the special form `q_j=(4j-1)/gcd(L,4j-1)` and the trap-cardinality bounds.

### E. Reduced-survivor strengthening

The finite data show more than an uncovered integer: every candidate has an uncovered parameter whose resulting arithmetic progression is reduced modulo `LQ`. A proof may be easier if constructed prime-power coordinate by prime-power coordinate while preserving reducedness from the outset.

---

## 7. Why this is a better clue than simply extending the search

The `k<=600` experiment already rules out the obvious failure mode for `19,016` individual candidates. The cover-mass diagnostic now rules out the obvious easy proof.

That is progress in both directions:

- the conjecture survived a much stronger falsification attempt;
- the explanation cannot be a trivial density estimate.

The remaining mechanism must account for substantial, highly overlapping modular mass.

In project terms, this is the **diamond inside the diamond**: the shadow graph appears to carry a nontrivial overlap geometry that is invisible if one records only which layers are connected.

The next mathematical goal is to identify and prove that overlap invariant.
