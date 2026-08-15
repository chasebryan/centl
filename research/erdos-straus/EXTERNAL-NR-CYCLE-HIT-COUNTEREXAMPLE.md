# Counterexample to naive hit-on-cycle / least-entry conjectures

**Status:** exact finite counterexample  
**Date:** 2026-08-15  
**Depends on:** `EXTERNAL-NR-FACTOR-CYCLE.md`, fixed-k signed-divisor criterion  
**Claim boundary:** this does not weaken the universal factor-cycle theorem. It falsifies stronger conjectures that a cycle itself, or the component entered from the least external nonresidue, must contain a successful fixed-k FAB placement.

## 1. Prime

Take the Mordell-hard prime

\[
\boxed{p=5569.}
\]

Its least external quadratic-nonresidue prime is

\[
\boxed{q_1=13.}
\]

Using the canonical shift multiplier

\[
\sigma(q)=\begin{cases}1,&q\equiv3\pmod4,\\3,&q\equiv1\pmod4,\end{cases}
\]

the natural least-external-factor map gives the exact cycle

\[
\boxed{13\to701\to137\to13.}
\]

Every vertex is `1 mod 4`, so the fixed-k auxiliary is `k=3q` at each stage.

## 2. Vertex 13

\[
k=39,
\qquad
C=\frac{5569+39}{4}=1402=2\cdot701.
\]

The signed divisor box modulo `39` is

\[
\{1,2,19,20,37,38\}.
\]

The exact target is

\[
-p^{-1}\equiv5\pmod{39},
\]

which is absent. Thus the vertex fails.

The external factor `701|C` supplies the edge

\[
13\to701.
\]

## 3. Vertex 701

\[
k=2103,
\qquad
C=\frac{5569+2103}{4}=1918=2\cdot7\cdot137.
\]

The signed divisor box has `27` residues modulo `2103`; its exact target is

\[
-p^{-1}\equiv719\pmod{2103},
\]

which is absent.

The external factor `137|C` gives

\[
701\to137.
\]

## 4. Vertex 137

\[
k=411,
\qquad
C=\frac{5569+411}{4}=1495=5\cdot13\cdot23.
\]

The signed divisor box has `23` residues modulo `411`; its exact target is

\[
-p^{-1}\equiv20\pmod{411},
\]

which is absent.

The external factor `13|C` closes the cycle:

\[
137\to13.
\]

## 5. Consequence

Therefore both statements are false:

1. every external-nonresidue factor cycle contains a fixed-k FAB hit;
2. the component entered from the least external nonresidue must contain a hit before returning to a cycle.

The factor-cycle theorem remains valuable as a **defect transport mechanism**, but the universal ES argument must use additional information, such as the Kneser full-stabilizer defect attached to failed vertices, or a global argument over multiple components / external primes.

In particular, a proof cannot rest on a purely graph-theoretic no-cycle or extremal-entry claim.
