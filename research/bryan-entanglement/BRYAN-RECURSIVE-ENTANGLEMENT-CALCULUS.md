# Bryan Recursive Entanglement Calculus (BREC)

## Canonical research specification, version 1.0

**Status:** FROZEN  
**Freeze date:** 2026-08-16  
**Originator:** Chase Bryan  
**Canonical name:** Bryan Recursive Entanglement Calculus  
**Abbreviation:** BREC  
**Finite visual seed:** Bryan Entanglement Cross

> BREC treats an entanglement not as a single sign or compass direction, but as a recursively generated history of directed consequences. The Cross is a finite projection. The calculus is the closure behind it.

---

## 1. Scope and claim boundary

BREC is an abstract mathematical language for systems in which a state can generate constructive and obstructive consequences recursively.

The words **positive**, **negative**, **constructive**, **obstructive**, **propagation**, and **entanglement** are formal labels until an application supplies domain semantics.

BREC v1.0 makes one completeness claim only:

> Under a binary consequence alphabet `{+, -}`, every finite signed consequence history is represented by exactly one formal history word in the BREC history space.

That is a combinatorial completeness statement. It is not, by itself, a theorem about quantum mechanics, causality, number theory, physics, or any empirical system.

---

## 2. Primitive alphabet

Let

\[
\Sigma_2 = \{\oplus,\ominus\}
\]

or equivalently, for calculation,

\[
\Sigma_2 = \{+1,-1\}.
\]

Let

\[
\Sigma_2^* = \bigcup_{n\ge 0}\Sigma_2^n
\]

be the set of all finite signed words, including the empty word

\[
\varepsilon.
\]

A word

\[
w=(s_1,s_2,\ldots,s_n),\qquad s_i\in\{+1,-1\}
\]

is a complete finite propagation history. Temporal order is read from left to right.

---

## 3. Bryan recursion

Let `X` be a state space and let

\[
T_+,T_-:X\to X
\]

be the positive and negative propagation operators. They may be replaced by partial operators when an application permits terminal or undefined branches.

For an initial entanglement state

\[
E_\varepsilon = E,
\]

define recursively

\[
\boxed{E_{w\sigma}=T_\sigma(E_w),\qquad \sigma\in\{+,-\}.}
\]

Equivalently, for

\[
w=(s_1,\ldots,s_n),
\]

define

\[
T_w = T_{s_n}\circ T_{s_{n-1}}\circ\cdots\circ T_{s_1}
\]

and

\[
\boxed{E_w=T_w(E).}
\]

For the empty word,

\[
T_\varepsilon=\operatorname{id}_X.
\]

This recursion is the frozen core of BREC v1.0.

---

## 4. Bryan closure

The depth-`n` formal history layer is

\[
\mathcal H_n=\Sigma_2^n.
\]

The depth-`n` evaluated state family is

\[
\mathcal E_n(E)=\{T_w(E):w\in\Sigma_2^n\}.
\]

The complete finite Bryan closure is

\[
\boxed{
\mathfrak B(E)
=
\bigcup_{n=0}^{\infty}\mathcal E_n(E)
=
\{T_w(E):w\in\Sigma_2^*\}.
}
\]

A bounded closure through depth `N` is

\[
\boxed{
\mathfrak B_{\le N}(E)
=
\bigcup_{n=0}^{N}\mathcal E_n(E).
}
\]

There are exactly

\[
|\mathcal H_n|=2^n
\]

formal histories at depth `n`, and exactly

\[
\sum_{j=0}^{n}2^j=2^{n+1}-1
\]

formal histories through depth `n`.

A critical distinction is frozen into the definition:

\[
|\mathcal E_n(E)|\le 2^n.
\]

Different histories may evaluate to the same state. BREC therefore distinguishes **history identity** from **state identity**. Collisions are mathematical information, not missing branches.

---

## 5. The Bryan Entanglement Cross as a finite projection

The original Bryan Entanglement Cross displays the eight history labels

\[
\boxed{
\mathcal C_B
=
\{+,-,+-,-+,++-,+--,--+,-++\}.
}
\]

Its intended readings are:

| Cross ray | History meaning |
| --- | --- |
| `+` | forward constructive propagation |
| `-` | backward obstructive propagation |
| `+-` | constructive rise followed by possible obstruction |
| `-+` | obstructive descent followed by possible construction |
| `++-` | two constructive stages followed by obstruction |
| `+--` | construction followed by two obstructive stages |
| `--+` | two obstructive stages followed by construction |
| `-++` | obstruction followed by two constructive stages |

The Cross is therefore not the whole depth-3 layer. It is a mixed-depth, eight-ray selection from `Σ₂*`.

For example, the full third layer also contains

\[
+++,\quad +-+,\quad -+-,\quad ---.
\]

The two alternating words

\[
+-+\qquad\text{and}\qquad -+-
\]

are **re-entrant histories**. They express a consequence that reverses and then reverses again. Their automatic appearance is one reason the recursive calculus is strictly larger than the eight-ray diagram.

---

## 6. Frozen history invariants

For

\[
w=(s_1,\ldots,s_n),\qquad s_i\in\{-1,+1\},
\]

BREC v1.0 defines the following canonical invariants.

### 6.1 Depth

\[
\boxed{d(w)=|w|=n.}
\]

### 6.2 Initial polarity

For nonempty `w`,

\[
\boxed{\iota(w)=s_1.}
\]

### 6.3 Terminal polarity

\[
\boxed{\tau(w)=s_n.}
\]

### 6.4 Polarity parity

\[
\boxed{P(w)=\prod_{i=1}^{n}s_i.}
\]

This records the parity of negative stages.

### 6.5 Net constructive bias

\[
\boxed{B(w)=\sum_{i=1}^{n}s_i.}
\]

### 6.6 Reversal count

\[
\boxed{
R(w)=\sum_{i=1}^{n-1}\frac{1-s_i s_{i+1}}{2}.
}
\]

Each term is `1` exactly when two adjacent stages have opposite polarity. Thus

\[
R(+++-)=1,
\qquad
R(+-+-)=3.
\]

`R(w)` measures directional oscillation rather than net sign.

---

## 7. Weighted consequence amplitude

Signs encode direction but not strength. Let

\[
a_i\ge 0
\]

be application-defined stage weights. Define

\[
\boxed{A(w)=\sum_{i=1}^{n}a_i s_i.}
\]

A recency-discounted form is

\[
\boxed{
A_\lambda(w)
=
\sum_{i=1}^{n}\lambda^{n-i}s_i,
\qquad 0<\lambda\le 1.
}
\]

The weights are not intrinsic to the binary history. They are part of the application semantics.

---

## 8. Bryan state signature

A canonical descriptive signature for a nonempty history is

\[
\boxed{
\Gamma_B(w)
=
\bigl(
 w,
 |w|,
 \iota(w),
 \tau(w),
 P(w),
 B(w),
 R(w),
 A_\lambda(w)
\bigr).
}
\]

An implementation may append domain-specific observables, but the frozen fields above retain their meanings.

The signature separates questions that are often incorrectly collapsed into one sign:

- where the branch began,
- where it currently ends,
- how deep it is,
- how many negative stages occurred modulo two,
- its net signed bias,
- how many times it reversed,
- and its optional weighted magnitude.

---

## 9. Binary finite-history completeness

### Proposition BREC-1

For every finite sequence of binary consequences

\[
(s_1,\ldots,s_n),\qquad s_i\in\{+,-\},
\]

there exists exactly one history word

\[
w\in\Sigma_2^n
\]

with those symbols in that order.

### Consequence

The BREC history tree contains every finite binary positive/negative contingency exactly once as a formal history, including persistence, reversal, repeated reversal, and arbitrarily long alternation.

### Important qualification

The proposition does **not** imply that all evaluated states are distinct. If

\[
T_u(E)=T_v(E)
\]

for distinct histories `u` and `v`, then the application has a state collision. BREC preserves both histories and records the collision at the evaluated-state layer.

---

## 10. Recursive evaluation algorithm

For a depth limit `N`, BREC evaluation is breadth-first or depth-first traversal of the same formal tree.

Canonical breadth-first form:

```text
frontier := {(ε, E)}
emit (ε, E)

for depth := 0 .. N-1:
    next := ∅
    for each (w, x) in frontier:
        for σ in {+, -}:
            y := Tσ(x)
            emit (wσ, y, ΓB(wσ))
            add (wσ, y) to next
    frontier := next
```

Without pruning, the algorithm visits

\[
2^{N+1}-1
\]

formal history nodes through depth `N`.

A domain may deduplicate evaluated states for efficiency, but it must not confuse deduplication with deletion of formal history. If provenance matters, all predecessor histories must remain recoverable.

---

## 11. Geometric embeddings

The compass drawing is a visualization, not the definition. BREC can be embedded into multiple geometries without changing the formal histories.

### 11.1 Circular depth projection

Encode

\[
+\mapsto 0,
\qquad
-\mapsto 1.
\]

For

\[
w=b_1b_2\cdots b_n,
\]

define its binary address

\[
k(w)=\sum_{j=1}^{n}b_j2^{n-j}.
\]

A canonical angular projection is

\[
\boxed{
\theta_n(w)=2\pi\frac{k(w)}{2^n}.
}
\]

and its unit ray is

\[
\boxed{
D_n(w)=\bigl(\cos\theta_n(w),\sin\theta_n(w)\bigr).
}
\]

This yields `2^n` equally addressable rays at depth `n`.

### 11.2 Hypercube representation

The more natural finite geometry is

\[
\boxed{\mathcal H_n=\{-1,+1\}^n.}
\]

Each word is one vertex of the `n`-dimensional signed hypercube. The recursive embedding is

\[
(s_1,\ldots,s_n)
\mapsto
(s_1,\ldots,s_n,+1)
\]

or

\[
(s_1,\ldots,s_n)
\mapsto
(s_1,\ldots,s_n,-1).
\]

Thus the Cross can be treated as a two-dimensional visual shadow of a recursively increasing signed geometry.

---

## 12. Symmetries and transformations

BREC distinguishes histories while allowing useful transformations.

### 12.1 Global sign inversion

\[
\boxed{\nu(s_1\cdots s_n)=(-s_1)\cdots(-s_n).}
\]

### 12.2 Temporal reversal

\[
\boxed{\rho(s_1\cdots s_n)=s_n\cdots s_1.}
\]

### 12.3 Prefix and suffix operations

For words `u,v`, concatenation

\[
uv
\]

represents the history obtained by appending `v` after `u`.

Because concatenation is associative and `ε` is its identity, the formal history space `Σ₂*` is the free monoid on two generators. This gives BREC an algebraic foundation independent of any drawing.

An application may study equivalence classes under `ν`, `ρ`, operator identities, or evaluated-state collisions, but those equivalences are additional structure and do not alter the frozen raw history space.

---

## 13. Terminal, partial, and absorbing contingencies

Some applications do not permit both consequences from every state. In that case use partial operators

\[
T_\sigma:X\rightharpoonup X.
\]

A branch `wσ` exists formally but may be marked **undefined** under that application.

An absorbing state `x*` may satisfy

\[
T_+(x^*)=x^*,
\qquad
T_-(x^*)=x^*,
\]

or only one of these identities.

BREC therefore separates:

1. the exhaustive formal contingency space, and
2. the application-admissible evaluated subspace.

This distinction prevents a domain restriction from being mistaken for a missing logical possibility.

---

## 14. Stochastic BREC

When consequences have conditional probabilities, attach a transition kernel

\[
p(\sigma\mid E_w),
\qquad
\sum_{\sigma\in\{+,-\}}p(\sigma\mid E_w)=1.
\]

Then the probability of a finite history is

\[
\boxed{
\Pr(w)
=
\prod_{i=1}^{n}
 p\bigl(s_i\mid E_{s_1\cdots s_{i-1}}\bigr).
}
\]

This extension changes branch weights, not the underlying history set.

---

## 15. Generalized Bryan recursion

Binary BREC is the frozen base calculus. A larger property alphabet may be introduced as

\[
\Sigma_m=\{p_1,p_2,\ldots,p_m\}.
\]

Then

\[
\boxed{
E_{wp_j}=T_{p_j}(E_w),
\qquad p_j\in\Sigma_m.
}
\]

At depth `n` there are

\[
\boxed{m^n}
\]

formal histories, and the complete finite closure is

\[
\boxed{
\mathfrak B_{\Sigma_m}(E)
=
\{T_w(E):w\in\Sigma_m^*\}.
}
\]

This accommodates neutral, unknown, multi-valued, typed, or domain-specific consequences without changing the recursive architecture.

---

## 16. Infinite branches

BREC v1.0 defines finite histories canonically. Infinite histories belong to the natural boundary

\[
\Sigma_2^\omega.
\]

An infinite branch

\[
w_\infty=(s_1,s_2,\ldots)
\]

is not assigned a limiting evaluated state unless the application supplies a topology, metric, convergence rule, or other limiting semantics.

Possible questions include whether

\[
T_{s_n}\circ\cdots\circ T_{s_1}(E)
\]

converges, cycles, diverges, enters an attractor, or remains nonconvergent as `n→∞`.

These are research questions, not assumptions of the calculus.

---

## 17. Contingency taxonomy

Within binary BREC, finite histories automatically include:

- **persistence:** `+++...` or `---...`,
- **single reversal:** examples such as `+++-` or `---+`,
- **re-entry:** examples such as `+-+` or `-+-`,
- **multiple reversal:** arbitrary words with `R(w)>1`,
- **alternation:** `+-+-...` and `-+-+...`,
- **biased mixed histories:** both signs occur but `B(w)≠0`,
- **balanced histories:** `B(w)=0`,
- **history collisions:** `u≠v` but `T_u(E)=T_v(E)`,
- **terminal branches:** a domain operator becomes undefined,
- **absorbing branches:** evaluation enters a fixed state,
- **weighted histories:** identical signs with different application amplitudes,
- **stochastic histories:** identical formal branches with different probabilities.

Thus BREC is not limited to eight directions. The eight-ray Cross is a human-readable coordinate chart over a small subset of an unbounded recursive history space.

---

## 18. Research agenda

The following problems are intentionally left open for BREC research.

1. **Collision theory.** Characterize conditions on `T+` and `T-` under which distinct histories evaluate identically.
2. **Normal forms.** Determine when operator identities permit a canonical representative of an evaluated-state equivalence class.
3. **Metrics.** Study prefix, Hamming, weighted, and state-induced distances on histories.
4. **Topology of the boundary.** Investigate `Σ₂^ω` and application-specific convergence.
5. **Dynamical systems.** Classify fixed points, cycles, attractors, and chaotic operator compositions.
6. **Probability.** Study stochastic kernels and measures over finite and infinite histories.
7. **Information.** Quantify branch entropy, reversal entropy, and compression under state collisions.
8. **Causal embeddings.** Determine when BREC histories can be faithfully represented in directed acyclic graphs or causal models.
9. **Algebra.** Study quotients of the free monoid induced by domain operator identities.
10. **Higher alphabets.** Determine which applications require `m>2` primitive consequence types.
11. **Computational pruning.** Develop provably history-preserving reductions for very deep closures.
12. **Application certificates.** Define domain-specific evidence sufficient to assign a BREC sign, weight, or operator without ambiguity.

---

## 19. Frozen core of BREC v1.0

The following statements are normative and frozen for version 1.0:

\[
\boxed{
\begin{aligned}
&E_\varepsilon=E,\\
&E_{w\sigma}=T_\sigma(E_w),
\qquad \sigma\in\{\oplus,\ominus\},\\
&\mathcal E_n(E)
=
\{T_{\sigma_n}\circ\cdots\circ T_{\sigma_1}(E):
(\sigma_1,\ldots,\sigma_n)\in\{\oplus,\ominus\}^n\},\\
&\mathfrak B(E)
=
\bigcup_{n=0}^{\infty}\mathcal E_n(E).
\end{aligned}
}
\]

Together with the distinction between formal histories and evaluated-state collisions, these equations define the canonical BREC v1.0 recursion.

The canonical interpretive sentence is:

> **An entanglement is not assigned one of eight directions. An entanglement generates a recursively closed space of directed consequences, and every finite sequence of constructive and obstructive propagation is itself a legitimate formal entanglement history.**

---

## 20. Versioning and preservation rule

This document is the canonical BREC v1.0 specification.

- Corrections that do not change mathematical meaning may be recorded as errata.
- Compatible definitions and derived results require an explicit minor-version research record.
- Any change to the primitive binary history space, Bryan recursion, or history/state distinction requires a new major version.
- Historical frozen specifications must remain available for citation and comparison.

The purpose of the freeze is reproducibility: future BREC research must be able to say exactly which calculus it uses.
