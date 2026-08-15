# Infinite squarefree factor-lift families at every ancestry quotient

**Status:** proved infinite exact construction  
**Date:** 2026-08-15  
**Depends on:** `ES-SQUARE-SQUAREFREE-FACTOR-LIFT.md`, `THEORY.md`  
**Imported classical tool:** Dirichlet's theorem on primes in reduced arithmetic progressions  
**Claim boundary:** constructs infinite exact completed-shadow families for every allowed modulus-ancestry quotient. It does not classify all shadows at a fixed quotient or prove universal completed coverage.

---

## 1. Allowed ancestry quotients

Every modulus-ancestry quotient between layers has the form

\[
\boxed{Q=4s+1}
\]

with

\[
\boxed{s\ge1.}
\]

The corresponding ancestry relation is

\[
\boxed{k=Qj-s}
\]

or equivalently

\[
\boxed{k=j+s(4j-1).}
\]

We now construct infinitely many exact squarefree factor-lift shadows for **every** such `Q`.

---

## 2. Choose a squarefree divisor of the ancestry parameter

Fix

\[
\boxed{Q=4s+1.}
\]

Choose any squarefree positive divisor

\[
\boxed{A\mid s.}
\]

Put

\[
\boxed{t=s/A.}
\]

Because

\[
Q=4s+1,
\]

we have

\[
\boxed{\gcd(t,Q)=1.}
\]

Indeed every common divisor of `t|s` and `4s+1` divides `1`.

---

## 3. Choose the lifted prime

Let `r` be a prime satisfying

\[
\boxed{r\equiv-t\pmod Q.}
\]

Then

\[
\boxed{B=\frac{r+t}{Q}}
\]

is a positive integer.

Define

\[
\boxed{j=AB}
\]

and

\[
\boxed{k=Ar.}
\]

For all sufficiently large choices of `r`, one may also assume

\[
\gcd(r,A)=1,
\]

so `k` is squarefree because `A` was chosen squarefree.

---

## 4. Exact ancestry identity

Using

\[
r=QB-t,
\]

we obtain

\[
\begin{aligned}
k
&=Ar\\
&=A(QB-t)\\
&=QAB-At\\
&=Qj-s.
\end{aligned}
\]

Thus `j,k` satisfy the exact ancestry relation.

Hence

\[
\boxed{4k-1=Q(4j-1).}
\]

So the modulus quotient is exactly the prescribed value `Q`.

---

## 5. The new prime lifts the missing ancestor factor

Let

\[
m=4j-1.
\]

Since

\[
j=AB,
\]

we have

\[
m=4AB-1.
\]

Now

\[
\begin{aligned}
r-B
&=QB-t-B\\
&=(Q-1)B-t\\
&=4sB-t\\
&=4AtB-t\\
&=t(4AB-1)\\
&=tm.
\end{aligned}
\]

Therefore

\[
\boxed{r\equiv B\pmod m.}
\]

This is the exact factor-lift congruence.

---

## 6. Factorization match

Write the squarefree divisor `A` as

\[
\boxed{A=p_1p_2\cdots p_h}
\]

with distinct primes `p_i`.

Then the later squarefree index is

\[
\boxed{k=p_1p_2\cdots p_h r.}
\]

The earlier index has the factorization

\[
\boxed{j=p_1p_2\cdots p_h B.}
\]

Modulo `m`:

- each shared prime factor `p_i` maps to itself;
- the new prime `r` maps to the remaining ancestor factor `B`.

Thus the prime factors of `k` lift a complete factorization of `j`.

`ES-SQUARE-SQUAREFREE-FACTOR-LIFT.md` applies and gives

\[
\boxed{
S_k\bmod m
\subseteq
S_j.}
\]

Therefore `k` is structurally impossible as a completed minimal depth.

---

## 7. Infinite family by Dirichlet

The target prime residue class is

\[
\boxed{-t\pmod Q.}
\]

Because

\[
\gcd(t,Q)=1,
\]

this is a reduced class.

Dirichlet's theorem therefore supplies infinitely many primes

\[
\boxed{r\equiv-t\pmod Q.}
\]

Discarding finitely many primes that divide `A`, infinitely many remain with

\[
\gcd(r,A)=1.
\]

Hence:

### Theorem — all-quotient factor-lift family

For every ancestry quotient

\[
\boxed{Q=4s+1}
\]

and every squarefree divisor

\[
\boxed{A\mid s,}
\]

there exist infinitely many ancestry pairs `j<k` satisfying

\[
\boxed{4k-1=Q(4j-1)}
\]

for which the later index `k` is squarefree and

\[
\boxed{S_k\bmod(4j-1)\subseteq S_j.}
\]

Thus **every allowed ancestry quotient supports infinitely many exact completed structural gaps**.

---

## 8. Quotient nine recovered

Take

\[
Q=9,
\qquad
s=2.
\]

Choose

\[
A=2,
\qquad
 t=1.
\]

Then

\[
r\equiv-1\equiv8\pmod9,
\]

\[
B=\frac{r+1}{9},
\]

\[
j=2B=\frac{2(r+1)}9,
\]

and

\[
k=2r.
\]

This is exactly the quotient-nine semiprime family already isolated.

---

## 9. Quotient thirteen

Take

\[
Q=13,
\qquad
s=3,
\qquad
A=3,
\qquad
 t=1.
\]

Every prime

\[
\boxed{r\equiv12\pmod{13}}
\]

gives

\[
B=\frac{r+1}{13},
\qquad
j=3B,
\qquad
k=3r,
\]

with

\[
\boxed{4k-1=13(4j-1)}
\]

and complete direct shadow by `j`.

For example

\[
r=103
\]

gives

\[
\boxed{j=24,
\qquad
k=309.}
\]

---

## 10. Multiple families at one quotient

When `s` has several squarefree divisors, one quotient supports several distinct factor-lift templates.

For

\[
Q=25,
\qquad
s=6,
\]

one may choose

\[
A=2,\ 3,\ 6
\]

with corresponding

\[
t=3,\ 2,\ 1.
\]

This yields prime progressions

\[
\boxed{
\begin{array}{c|c}
A & r\pmod{25}\\
\hline
2 & 22\\
3 & 23\\
6 & 24
\end{array}}
\]

and three infinite shadow families at the same ancestry quotient.

So the factorization of the ancestry parameter `s` controls the multiplicity of explicit shadow templates.

---

## 11. The rank-one case A = 1

The divisor

\[
A=1
\]

is squarefree and always allowed.

Then

\[
t=s,
\qquad
j=B,
\qquad
k=r
\]

is prime.

The construction reduces to the prime-index ancestry absorption theorem.

Thus the all-quotient theorem continuously interpolates from:

- rank-one prime target shadows (`A=1`);
- semiprime target shadows (`A` prime);
- higher squarefree target shadows (`omega(A)>1`).

---

## 12. Structural interpretation

For fixed quotient

\[
Q=4s+1,
\]

the ancestry parameter `s` is not just an additive offset.

Its squarefree divisors specify how much of the earlier layer factorization can be **carried unchanged** into the later index.

The remaining ancestor factor `B` is then replaced by one new prime `r` in a Dirichlet progression chosen so that

\[
r\equiv B\pmod{m_j}.
\]

Therefore the fixed-quotient shadow geometry has an explicit arithmetic template:

\[
\boxed{
\text{shared squarefree factor}
+\text{one lifted prime}
\Longrightarrow
\text{complete shadow}.}
\]

---

## 13. Consequence for the nonmultiplicative frontier

The nonmultiplicative ancestry graph is not a collection of isolated coincidences.

It contains infinite exact shadow families at **every** allowed quotient and often several independent families at the same quotient.

The remaining classification problem is therefore:

1. determine which shadows are generated by these one-prime factor lifts;
2. allow several new primes lifting several factors of `j`;
3. characterize the residual ancestry edges not decomposable into stabilizer extensions or factor lifts.

A successful theorem would turn nonmultiplicative shadowing into a finite factorization-matching problem attached to `s=(Q-1)/4`.
