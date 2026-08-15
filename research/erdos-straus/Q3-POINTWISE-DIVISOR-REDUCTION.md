# q=3 Pointwise Divisor Reduction

**Status:** proved universal theorem  
**Date:** 2026-08-15  
**Depends on:** `Q3-ABSORPTION.md`, `Q3-WEAK-REDUNDANCY.md`, `Q3-POINTWISE-ABSORPTION.md`, `Q3-NEXT-DIGIT-THEOREM.md`  
**Claim boundary:** canonically reduces individual q=3 trap witnesses to earliest divisor-ancestry representatives. It does not by itself prove that the surviving ancestry-minimal representatives cannot occupy all three next 3-adic digits, universal DSC-P, López-all-primes, or Erdős-Straus.

---

## 1. Setup

Fix a candidate progression

\[
x(s)=r+Ls.
\]

Let `j` be an earlier layer with

\[
m_j=4j-1,
\qquad
q_j=\frac{m_j}{\gcd(L,m_j)}=3.
\]

Write

\[
g_j=\gcd(L,m_j)=m_j/3.
\]

Thus

\[
\boxed{m_j=3g_j,\qquad g_j\mid L.}
\]

Suppose a parameter class

\[
a\in R_j\subseteq\mathbb Z/3\mathbb Z
\]

is witnessed by an actual trap

\[
u\in T_j,
\qquad
r+La\equiv u\pmod{m_j}.
\]

Let `i<j` be any earlier layer satisfying

\[
\boxed{m_i\mid m_j}
\]

and suppose this **specific** trap reduces into the ancestor trap set:

\[
\boxed{u\bmod m_i\in T_i.}
\]

No whole-set inclusion `T_j mod m_i subseteq T_i` is assumed.

---

## 2. Lemma — the ancestor quotient is only 1 or 3

Because

\[
\gcd(L,m_j)=g_j,
\]

for every divisor `m_i|m_j` one has

\[
\boxed{
\gcd(L,m_i)=\gcd(g_j,m_i).
}
\]

Indeed the prime-power intersection of `L` with `m_j` is exactly `g_j`, and restricting that intersection to the divisor `m_i` gives the displayed identity.

Since

\[
m_i\mid 3g_j,
\]

it follows that

\[
\boxed{
q_i
=\frac{m_i}{\gcd(L,m_i)}
=\frac{m_i}{\gcd(g_j,m_i)}
\in\{1,3\}.
}
\]

More precisely:

- if `m_i|g_j`, then `q_i=1`;
- if `m_i∤g_j`, then `q_i=3`.

---

## 3. Theorem — pointwise divisor reduction

Under the setup above, exactly one of the following occurs.

### Case A — frozen ancestor

If

\[
m_i\mid g_j=m_j/3,
\]

then

\[
\boxed{q_i=1}
\]

and the candidate is directly shadowed by layer `i`.

#### Proof

Since `m_i|g_j|L`, the progression is frozen modulo `m_i`. The witnessing parameter satisfies

\[
x(a)\equiv u\pmod{m_i}\in T_i.
\]

Therefore every point of the progression has that same residue in `T_i`. QED.

### Case B — moving q=3 ancestor

If

\[
m_i\nmid g_j,
\]

then

\[
\boxed{q_i=3}
\]

and the **same parameter class** is forbidden by the ancestor:

\[
\boxed{a\in R_i.}
\]

#### Proof

The lemma gives `q_i=3`. Reducing

\[
r+La\equiv u\pmod{m_j}
\]

modulo `m_i` gives

\[
r+La\equiv u\pmod{m_i}\in T_i.
\]

Hence `a mod 3` belongs to the ancestor pullback `R_i`. QED.

---

## 4. Definition — ancestry-minimal q=3 trap witness

Call a hard-compatible trap witness

\[
u\in T_j
\]

**ancestry-minimal** if there is no earlier `i<j` with

\[
m_i\mid m_j
\]

and

\[
u\bmod m_i\in T_i.
\]

This is strictly sharper than whole-layer base/weak/strong classification. A layer can be whole-layer `base` while a particular trap point is still reducible to an earlier q=3 layer or frozen ancestor.

---

## 5. Corollary — canonical descent of every q=3 forbidden digit

Take any q=3 forbidden class `a in R_j` and one of its trap witnesses `u in T_j`.

If `u` is not ancestry-minimal, choose an earlier divisor ancestor catching it.

- If that ancestor has `q=1`, the candidate is directly shadowed and cannot be directly novel.
- Otherwise it has `q=3` and forbids the **same** class `a`.

Repeat.

The layer index strictly decreases, so the process terminates.

Therefore on every **directly novel** candidate:

\[
\boxed{
\text{every q=3 forbidden parameter class has an ancestry-minimal representative.}
}
\]

The common digit is preserved throughout the descent.

---

## 6. Relation to the earlier hierarchy

This theorem contains the earlier q=3 reductions as special cases.

- **Strong absorption:** one ancestor catches every trap and is frozen (`q_i=1`).
- **Weak redundancy:** one ancestor catches every trap and remains moving (`q_i=3`).
- **Pointwise absorption:** one particular trap is caught by a frozen divisor parent.
- **Pointwise moving reduction:** new here as the exact trap-level analogue of weak redundancy.

Thus the true local obstruction is smaller than “base layers with primitive traps.” It is the set of **ancestry-minimal trap witnesses actually aligned on one admissible candidate**.

---

## 7. Sharpened q=3 target

By `Q3-NEXT-DIGIT-THEOREM.md`, a q=3 obstruction must occupy all three values of one global next 3-adic digit.

By the descent theorem above, on a directly novel candidate every occupied value can be represented by an ancestry-minimal trap witness.

Hence the exact residual target is

\[
\boxed{
\text{Can ancestry-minimal admissible q=3 trap witnesses occupy all three next 3-adic digits?}
}
\]

A proof that they cannot would close the corrected q=3 local covering obstruction universally.
