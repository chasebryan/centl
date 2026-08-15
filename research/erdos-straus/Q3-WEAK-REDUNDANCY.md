# q=3 Weak-Ancestor Redundancy

**Status:** proved universal theorem  
**Date:** 2026-08-15  
**Depends on:** `Q3-ABSORPTION.md`  
**Claim boundary:** reduces the corrected q=3 shared-factor obstruction to base layers. Does not prove that base layers cannot cover the corrected parameter domain, universal DSC-P, López-all-primes, or Erdős-Straus.

---

## Setup

Let

\[
m_j=4j-1,
\qquad
q_j=\frac{m_j}{\gcd(L,m_j)}.
\]

Call a layer `j` **weak** when there is an earlier layer `i<j` such that

\[
\boxed{m_i\mid m_j}
\]

and

\[
\boxed{T_j\bmod m_i\subseteq T_i,}
\]

but

\[
\boxed{m_i\nmid m_j/3.}
\]

Thus `j` has a trap-reducing ancestor, but not a strong-absorption ancestor in the sense of `Q3-ABSORPTION.md`.

---

## Theorem (weak q=3 redundancy)

Assume

\[
\boxed{q_j=3.}
\]

If `i` is a weak trap-reducing ancestor of `j`, then

\[
\boxed{q_i=3}
\]

and, for the same candidate progression,

\[
\boxed{R_j\subseteq R_i\subseteq\mathbb Z/3\mathbb Z.}
\]

Therefore a weak `q=3` layer contributes **no forbidden parameter residue not already contributed by an earlier layer**.

### Proof

Put

\[
g=\gcd(L,m_j).
\]

Since `q_j=3`,

\[
\boxed{m_j=3g}
\]

and `g|L`.

Because `m_i|m_j`, every common divisor of `L` and `m_i` is also a common divisor of `L` and `m_j`; hence

\[
\gcd(L,m_i)=\gcd(g,m_i).
\]

Now `m_i|3g`. Therefore

\[
\frac{m_i}{\gcd(g,m_i)}\mid3.
\]

The weak hypothesis says `m_i` does **not** divide `g=m_j/3`, so this quotient is greater than `1`. Since `3` is prime,

\[
\boxed{
\frac{m_i}{\gcd(L,m_i)}
=
\frac{m_i}{\gcd(g,m_i)}
=3.
}
\]

Thus `q_i=3`.

Now take any residue class

\[
a\in R_j.
\]

By definition there is a parameter `s` with

\[
s\equiv a\pmod3
\]

such that

\[
x(s)=r+Ls\pmod{m_j}\in T_j.
\]

Reducing modulo `m_i` and using

\[
T_j\bmod m_i\subseteq T_i
\]

gives

\[
x(s)\pmod{m_i}\in T_i.
\]

Since `q_i=3`, this means exactly

\[
s\bmod3\in R_i.
\]

Hence `a in R_i`, proving

\[
\boxed{R_j\subseteq R_i.}
\]

QED.

---

## Corollary 1 — weak layers can be deleted from q=3 covers

For any candidate progression, repeatedly delete every weak `q=3` layer and retain one of its earlier weak ancestors. The union of forbidden classes modulo `3` does not shrink:

\[
\boxed{
\bigcup_{j\in\mathcal W}R_j
\subseteq
\bigcup_{i\in\mathcal A}R_i,
}
\]

where `A` contains earlier ancestors reached by the reductions.

Thus weak descendants are redundant for every q=3 covering question.

---

## Corollary 2 — directly novel corrected q=3 obstruction = base-only obstruction

Combine this theorem with Strong q=3 absorption:

- **strong** layer: if `R_j != empty`, the candidate is directly shadowed and therefore cannot occur on a directly novel candidate;
- **weak** layer: `R_j` is contained in an earlier q=3 ancestor pullback and adds no new forbidden class;
- **base** layer: no trap-reducing ancestor is available from this hierarchy.

Therefore on directly novel candidates, every genuinely new forbidden residue in the q=3 coordinate can be represented by a **base q=3 layer**.

In the exact Dirichlet parameter domain, `3|840|L`, so the local domain is all of

\[
\mathbb Z/3\mathbb Z.
\]

A genuine q=3 local obstruction must therefore reduce to base layers whose pullbacks cover all three classes

\[
\boxed{\{0,1,2\}.}
\]

The residual theorem target is no longer strong+weak+base, and no longer a complementary pair. It is:

\[
\boxed{
\text{Can base q=3 layers cover }\mathbb Z/3\mathbb Z
\text{ on a directly novel admissible candidate?}
}
\]

---

## Consequence for the j<=1500 ancestry census

`Q3-ABSORPTION.md` records:

```text
strong absorb: 153
weak only:      114
base:           233
```

The first two populations are now structurally removed from the novel q=3 obstruction:

- 153 strong layers are novel-impossible when active;
- 114 weak layers are residue-redundant;
- only the 233 base layers can contribute genuinely new q=3 forbidden classes in that finite census.

The counts are finite census data; the strong/weak reductions themselves are universal.
