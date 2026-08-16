# External `q ≡ 3 mod 4` eligibility depth is unbounded

**Status:** proved universal theorem  
**Date:** 2026-08-16  
**Depends on:** `EXTERNAL-Q3-BINARY-CENSUS-10M.md`  
**Imported classical tools:** Chinese remainder theorem; Dirichlet's theorem on primes in reduced arithmetic progressions  
**Claim boundary:** this proves that no fixed ceiling can contain an eligible external prime `q==3 mod4` for every Mordell-hard prime. It does not prove that an eligible external prime always rescues, and does not prove Erdős–Straus.

---

## 1. Statement

Fix an arbitrary finite bound

\[
\boxed{Q\ge3.}
\]

Then there exist infinitely many Mordell-hard primes `p` such that

\[
\boxed{
\left(\frac qp\right)=+1
}
\]

for **every** prime

\[
q\le Q,
\qquad
q\equiv3\pmod4.
\]

Consequently none of those primes `q` is eligible for the restricted external-prime lane

\[
q\equiv3\pmod4,
\qquad
\left(\frac qp\right)=-1.
\]

Therefore the least eligible external prime `q==3 mod4` is unbounded over the Mordell-hard prime population.

---

## 2. Construction

Let

\[
\mathcal Q_Q
=
\{q\le Q:q\text{ prime},\ q\equiv3\pmod4\}.
\]

Put

\[
\boxed{
M
=840\prod_{q\in\mathcal Q_Q}q.
}
\]

Consider primes in the reduced arithmetic progression

\[
\boxed{p\equiv1\pmod M.}
\]

Since

\[
\gcd(1,M)=1,
\]

Dirichlet's theorem gives infinitely many such primes.

Every one satisfies

\[
\boxed{p\equiv1\pmod{840},}
\]

so it lies in one of the six Mordell-hard residue classes, specifically the class `1 mod 840`.

---

## 3. Every small `q==3 mod4` is forced onto the residue side

Take any

\[
q\in\mathcal Q_Q.
\]

Because `q|M`,

\[
\boxed{p\equiv1\pmod q.}
\]

Hence

\[
\left(\frac pq\right)=+1.
\]

Also

\[
p\equiv1\pmod4.
\]

Quadratic reciprocity therefore contributes no sign, giving

\[
\boxed{
\left(\frac qp\right)
=
\left(\frac pq\right)
=+1.
}
\]

This holds simultaneously for every `q in Q_Q`.

Thus no prime

\[
q\le Q,
\qquad q\equiv3\pmod4
\]

is external to any prime `p` in the constructed progression.

---

## 4. Theorem

### External-q3 eligibility-depth theorem

For every finite `Q`, infinitely many Mordell-hard primes have no external prime

\[
q\equiv3\pmod4
\]

with

\[
q\le Q.
\]

Equivalently,

\[
\boxed{
\sup_p\min\left\{
q:q\text{ prime},\ q\equiv3\pmod4,\ \left(\frac qp\right)=-1
\right\}
=\infty,
}
\]

where `p` ranges over Mordell-hard primes.

---

## 5. Eligible external primes still exist for each fixed p

The theorem above is a lower-bound construction, not a claim that the external-q3 set can be empty.

Fix a Mordell-hard prime `p`. Choose any quadratic-nonresidue residue class

\[
a\pmod p.
\]

CRT combines

\[
q\equiv3\pmod4,
\qquad
q\equiv a\pmod p
\]

into a reduced class modulo `4p`. Dirichlet therefore supplies infinitely many primes `q` in that class.

For each such prime,

\[
\left(\frac qp\right)=-1.
\]

Hence every fixed hard prime has infinitely many eligible external primes `q==3 mod4`; their least member is simply not uniformly bounded across `p`.

---

## 6. Consequence for the finite `419` signal

`EXTERNAL-Q3-BINARY-CENSUS-10M.md` records the striking finite fact that every hard prime through `10^7` is rescued by an eligible external prime

\[
q\le419.
\]

A larger direct stress replay through `10^8` retains the same deepest observed pair

\[
(p,q)=(8,925,841,419).
\]

The theorem above proves that this finite stability **cannot** become a universal statement of the form

\[
q\le419
\]

or, more generally,

\[
q\le Q_0
\]

for any fixed constant `Q_0`, because some hard primes have no eligible external q3 prime below that ceiling at all.

Therefore the correct universal target must be adaptive:

\[
\boxed{
\forall p\text{ hard},\ \exists q=q(p)\text{ external},\ q\equiv3\pmod4,
\text{ such that the binary/two-target test hits}.}
\]

The auxiliary prime must be allowed to grow with `p`.

---

## 7. Proof-search consequence

This theorem separates two tasks that finite experiments can otherwise blur.

### Finite-engineering question

How small is a successful external prime on accessible ranges?

The current answer is spectacularly small: `q<=419` through at least `10^8` in direct replay.

### Universal mathematics question

Why must **some** eligible external prime succeed, even when the first eligible prime itself is arbitrarily large?

That question cannot be settled by extending a fixed table of shifts. It requires a structural statement uniform in `q`, such as:

- a uniform signed-box expansion theorem;
- an incompatibility among the Kneser defects across all external primes;
- or an adaptive construction of `q` from the arithmetic of `p` that forces target membership.

The exact failure constraints in `BINARY-R-KNESER-DEFECT.md` are designed for this adaptive regime.

---

Erdős–Straus remains open. The theorem proves unbounded eligibility depth, not universal rescue.
