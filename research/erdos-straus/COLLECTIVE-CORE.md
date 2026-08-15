# Collective-Core Theory for Type A/B Pullbacks

**Status:** foundational definitions and elementary theorems proved  
**Date:** 2026-08-15  
**Motivation:** `DSC-COUNTEREXAMPLE.md` proves that collective coverage need not collapse to a single direct shadow.  
**Claim boundary:** this framework organizes collective shadows. It does not yet classify all cores or prove all-prime Erdős-Straus coverage.

---

## 1. Candidate pullback system

Fix an admissible Type A/B target candidate

\[
x(s)=r+Ls.
\]

For each earlier layer `j`, write

\[
m_j=4j-1,
\qquad
g_j=\gcd(L,m_j),
\qquad
q_j=m_j/g_j,
\]

and let

\[
R_j\subseteq\mathbb Z/q_j\mathbb Z
\]

be the exact pullback defined by

\[
s\bmod q_j\in R_j
\iff
r+Ls\bmod m_j\in T_j.
\]

Discard rows with `R_j=empty`.

For a finite family `F` of remaining rows put

\[
\boxed{Q_F=\operatorname{lcm}_{j\in F}q_j.}
\]

Lift each pullback to the common period:

\[
\widetilde R_j^{(F)}
=
\{s\bmod Q_F:s\bmod q_j\in R_j\}.
\]

Its exact cardinality is

\[
\boxed{
|\widetilde R_j^{(F)}|
=|R_j|\frac{Q_F}{q_j}.
}
\]

---

## 2. Exact Dirichlet parameter domain

For a common period `Q`, define

\[
\mathcal D(r,L;Q)
=
\{s\bmod Q:\gcd(r+Ls,LQ)=1\}.
\]

Candidate admissibility already gives

\[
\gcd(r,L)=1.
\]

Hence:

- if `p|Q` and `p|L`, no parameter class is removed at `p`;
- if `p|Q` and `p∤L`, exactly the affine class
  \[
  s\equiv-rL^{-1}\pmod p
  \]
  is removed.

This is the exact reduced domain from `REDUCED-PARAMETER-DOMAIN.md`.

Two covering notions are useful.

### Integer cover

A family `F` is an **integer cover** when

\[
\boxed{
\bigcup_{j\in F}\widetilde R_j^{(F)}
=
\mathbb Z/Q_F\mathbb Z.
}
\]

Then every integer parameter hits an earlier layer.

### Reduced-domain cover

A family `F` is a **reduced-domain cover** when

\[
\boxed{
\mathcal D(r,L;Q_F)
\subseteq
\bigcup_{j\in F}\widetilde R_j^{(F)}.
}
\]

Then no Dirichlet-reduced avoiding class survives, even if some non-reduced integer parameters do.

Every integer cover is a reduced-domain cover. The converse need not hold.

---

## 3. Definition — collective core

A finite family

\[
\mathcal C
\]

of earlier rows is an **integer collective core** when:

1. `C` is an integer cover;
2. no proper subfamily of `C` is an integer cover.

Likewise, `C` is a **reduced collective core** when it minimally covers the exact reduced domain.

The **rank** of a core is

\[
\boxed{\rho(\mathcal C)=|\mathcal C|.}
\]

Its **core modulus** is

\[
\boxed{Q_\mathcal C=\operatorname{lcm}_{j\in\mathcal C}q_j.}
\]

Its **prime support** is

\[
\boxed{
\operatorname{supp}(\mathcal C)
=\{p:p\mid Q_\mathcal C\}.
}
\]

A rank-one integer core is exactly a direct shadow. Rank at least two is genuinely collective.

---

## 4. Private-witness theorem

### Theorem

If `C` is an inclusion-minimal cover of a finite domain `D`, then every row `j in C` has a **private witness**

\[
s_j\in D
\]

such that

\[
s_j\in\widetilde R_j
\]

but

\[
s_j\notin\widetilde R_i
\qquad
\text{for every }i\in C\setminus\{j\}.
\]

### Proof

If no such private witness existed for row `j`, then every point covered by `j` would also be covered by the other rows. Removing `j` would leave the union unchanged on `D`, contradicting minimality. QED.

### Corollary

The private witnesses of distinct rows are distinct. Therefore

\[
\boxed{\rho(C)\le |D|.}
\]

For an integer core, `D=Z/Q_C Z`, so

\[
\boxed{\rho(C)\le Q_C.}
\]

---

## 5. Integer-load lower bound

Define the normalized integer load

\[
\boxed{
\lambda(C)
=\sum_{j\in C}\frac{|R_j|}{q_j}.
}
\]

### Theorem

Every integer cover satisfies

\[
\boxed{\lambda(C)\ge1.}
\]

### Proof

Lift to `Q=Q_C`. By the union bound,

\[
Q
=
\left|\bigcup_{j\in C}\widetilde R_j\right|
\le
\sum_{j\in C}|\widetilde R_j|.
\]

Using

\[
|\widetilde R_j|=|R_j|Q/q_j
\]

gives

\[
Q\le Q\sum_{j\in C}\frac{|R_j|}{q_j}.
\]

Divide by `Q`. QED.

---

## 6. Tight collective cores

Call an integer core **load-tight** when

\[
\boxed{\lambda(C)=1.}
\]

### Theorem

If an integer cover is load-tight, then its lifted pullback sets are pairwise disjoint.

### Proof

The union bound in the previous theorem is an equality. For finite sets, equality

\[
\left|\bigcup A_i\right|=\sum|A_i|
\]

holds exactly when the sets are pairwise disjoint. QED.

Therefore a load-tight core partitions the common parameter period exactly.

This is the cleanest possible collective shadow geometry.

---

## 7. Common-modulus rank bound

Suppose every row in `C` has the same pullback modulus

\[
q_j=q.
\]

If

\[
|R_j|\le r
\]

for every row, then an integer cover requires

\[
\boxed{
\rho(C)\ge\left\lceil\frac qr\right\rceil.
}
\]

This follows from the load bound:

\[
1\le\sum\frac{|R_j|}{q}
\le\frac{\rho(C)r}{q}.
\]

### Singleton corollary

If all pullbacks are singletons, then

\[
\boxed{\rho(C)\ge q.}
\]

For `q=p` prime this lower bound is sharp when one row occupies each residue class.

---

## 8. Reduced-domain exact load

For a reduced collective core, the simple fraction `|R_j|/q_j` may overcount classes excluded by Dirichlet reducedness.

At common period `Q=Q_C`, define

\[
D=\mathcal D(r,L;Q)
\]

and the exact reduced load

\[
\boxed{
\lambda_D(C)
=
\sum_{j\in C}
\frac{|\widetilde R_j\cap D|}{|D|}.
}
\]

The same union-bound proof gives

\[
\boxed{\lambda_D(C)\ge1}
\]

for every reduced-domain cover.

Equality again forces the sets

\[
\widetilde R_j\cap D
\]

to partition the exact Dirichlet domain.

This is the correct load notion when free primes occur in `Q`.

---

## 9. Reduction operations before core extraction

A canonical core search should simplify the full pullback family first.

Safe reductions include:

1. **empty-row deletion:** remove `R_j=empty`;
2. **direct/frozen decision:** a singleton rank-one cover terminates immediately;
3. **pointwise divisor descent:** replace a trap witness by an earlier divisor ancestor when `Q3-POINTWISE-DIVISOR-REDUCTION.md` or its future analog applies;
4. **set containment:** if, after lifting to a common period,
   \[
   \widetilde R_j\subseteq\widetilde R_i,
   \]
   then `j` is redundant for covering;
5. **duplicate merging:** identical lifted constraints need only one representative;
6. **fiber peeling / coordinate elimination:** use exact local room to eliminate coordinates that cannot participate in a terminal cover.

After these reductions, any remaining cover should be reduced to an inclusion-minimal core.

---

## 10. The verified DSC counterexample as a tight core

`DSC-COUNTEREXAMPLE.md` gives

\[
\mathcal C=\{25,70,187\}
\]

with

\[
q_{25}=q_{70}=q_{187}=3
\]

and singleton pullbacks

\[
R_{70}=\{0\},
\qquad
R_{25}=\{1\},
\qquad
R_{187}=\{2\}
\]

on the target progression.

Therefore

\[
Q_C=3,
\qquad
\rho(C)=3,
\qquad
\operatorname{supp}(C)=\{3\}.
\]

Its load is

\[
\lambda(C)
=\frac13+\frac13+\frac13
=\boxed1.
\]

So the first verified non-direct collective shadow is a **load-tight rank-three one-prime core**.

Each row has the other two classes as witnesses that it is not individually covering, while its occupied class is private relative to the other two. Hence the core is inclusion-minimal.

---

## 11. Hypergraph formulation

Fix common period `Q` and exact domain `D`.

Construct a hypergraph with:

- vertices = parameter classes in `D`;
- one hyperedge for each earlier row `j`, equal to
  \[
  \widetilde R_j\cap D.
  \]

Then:

- an avoiding class is an uncovered vertex;
- a collective cover is an edge cover of all vertices;
- a collective core is an inclusion-minimal full edge cover;
- a direct shadow is a one-edge full cover;
- private witnesses are vertices unique to their core edge.

This finite hypergraph is the correct terminal object after arithmetic reduction.

---

## 12. New theorem program

The replacement for DSC is not another collapse conjecture. It is a classification program:

1. Which prime supports can occur in irreducible cores?
2. Is core rank uniformly bounded on Type A/B candidate systems?
3. Are all terminal cores load-tight or near-tight after pointwise/fiber reduction?
4. Can every core be synthesized from local factor-pair data?
5. Are there infinite families of q=3 rank-three cores?
6. Can collective cores be used positively to prove that putative all-prime survivors are repeatedly absorbed by earlier Type A/B layers?

The all-prime Erdős-Straus problem does not require exact-depth realization of every directly novel candidate. It requires that no prime survives all valid solution mechanisms. Collective cores are therefore potential **coverage certificates**, not pathologies to eliminate.
