# Finite shift corridor for the classical strong/Type-II conjecture

**Status:** proved elementary reduction  
**Date:** 2026-08-15  
**Depends on:** `ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md`, `ES-TYPEII-ROOT-GEOMETRY.md`, `STRONG-ES-MIZONY-THEPAULT-PROVENANCE.md`  
**Claim boundary:** this is an elementary consequence of the standard Type-II factor form. It does not prove the strong conjecture or Erdős--Straus, and no novelty claim is made for the size bound itself.

---

## 1. Fixed-shift Type-II data

Let

\[
p\equiv1\pmod4
\]

be prime and let

\[
q\equiv3\pmod4,
\qquad
\gcd(q,p)=1.
\]

Put

\[
\boxed{C=\frac{p+q}{4}.}
\]

A standard Type-II hit at shift `q` is equivalent to a factorization

\[
\boxed{C=BDT}
\]

with positive integers `B,D,T` such that

\[
\boxed{q\mid B+D.}
\]

This is the normalized `-1` target in the signed divisor box.

---

## 2. Universal upper bound on a successful Type-II shift

Because

\[
q\mid B+D
\]

and `B+D>0`,

\[
q\le B+D.
\]

For positive `B,D`,

\[
B+D\le BD+1
\]

because

\[
(B-1)(D-1)\ge0.
\]

Also

\[
BD\le BDT=C.
\]

Therefore

\[
q\le C+1.
\]

Substituting

\[
C=\frac{p+q}{4}
\]

gives

\[
4q\le p+q+4,
\]

hence

\[
\boxed{3q\le p+4.}
\]

Thus:

### Theorem — finite Type-II shift bound

Every standard Type-II solution for prime `p≡1 mod4` has an associated shift satisfying

\[
\boxed{
q\le\frac{p+4}{3}.}
\]

So the strong/Type-II existence problem for a fixed prime has a finite admissible shift corridor.

---

## 3. Consecutive-integer parameterization

Define

\[
\boxed{A=\frac{p+3}{4}.}
\]

Every positive shift congruent to `3 mod 4` has the form

\[
\boxed{q_h=4h+3,
\qquad h\ge0.}
\]

The corresponding shifted integer is

\[
\begin{aligned}
C_h
&=\frac{p+q_h}{4}\\
&=\frac{p+3}{4}+h\\
&=A+h.
\end{aligned}
\]

Thus the fixed-shift Type-II problem runs through consecutive integers:

\[
\boxed{C_h=A+h.}
\]

The shift bound becomes

\[
4h+3\le\frac{p+4}{3}.
\]

Equivalently,

\[
12h+9\le p+4,
\]

so

\[
\boxed{h\le\frac{p-5}{12}.}
\]

Hence only the initial corridor

\[
\boxed{
A,\ A+1,\ \ldots,\ A+\left\lfloor\frac{p-5}{12}\right\rfloor
}
\]

can support a standard Type-II shift.

---

## 4. Exact defect corridor for a hypothetical strong counterexample

Let

\[
R_{q_h}(C_h)
\]

be the signed divisor box of `C_h` modulo `q_h`.

A Type-II hit is exactly

\[
-1\in R_{q_h}(C_h).
\]

Therefore a hypothetical prime counterexample to the strong/Type-II conjecture must satisfy simultaneously

\[
\boxed{
-1\notin
\mathcal R_{4h+3}(A+h)
}
\]

for every integer

\[
\boxed{
0\le h\le\left\lfloor\frac{p-5}{12}\right\rfloor
}
\]

except the irrelevant case `q_h=p`, where the shift is not coprime to `p`.

This is a long finite sequence of coupled factorization defects on consecutive integers.

---

## 5. Root form across the corridor

The root geometry says a Type-II hit at `h` is equivalent to a factorization

\[
\boxed{A+h=sbt}
\]

with `s` squarefree and

\[
\boxed{b+t\equiv0\pmod{4h+3}.}
\]

Thus a strong counterexample must make every consecutive integer in the corridor avoid this complementary-root congruence.

The modulus changes linearly with the position:

\[
\boxed{q_h=4h+3.}
\]

So the obstruction is not a collection of independent arbitrary moduli. It is a synchronized pair

\[
\boxed{(A+h,\,4h+3)}.
\]

---

## 6. First two corridor positions

### h = 0

\[
q_0=3,
\qquad
C_0=A=\frac{p+3}{4}.
\]

For Mordell-hard `p`, the exact `q=3` theorem already gives:

\[
\boxed{
q=3\text{ misses}
\iff
\text{every prime factor of }A\text{ is }1\pmod3.}
\]

### h = 1

\[
q_1=7,
\qquad
C_1=A+1=\frac{p+7}{4}.
\]

The next exact factorization defect can be classified completely in the cyclic group of order six; see the companion `q=7` filter note.

Thus the corridor begins with two consecutive integers carrying sharply constrained but different local splitting laws.

---

## 7. Strategic consequence

The strong/Type-II route can be attacked as a **consecutive defect corridor** rather than as an unbounded auxiliary search.

A hypothetical counterexample requires approximately

\[
\frac p{12}
\]

simultaneous signed-box misses on consecutive integers, each with a linearly changing modulus.

Potential proof tools now include:

1. exact small-shift factor restrictions (`q=3,7,11,...`);
2. sieve arguments across the consecutive integers `A+h`;
3. incompatibility of splitting conditions imposed by several small moduli;
4. average signed-divisor expansion as `h` ranges through the corridor;
5. identifying a short initial segment whose combined local conditions already force a hit.

The shift bound does not solve the strong conjecture, but it turns its fixed-prime search space into a highly structured finite interval.
