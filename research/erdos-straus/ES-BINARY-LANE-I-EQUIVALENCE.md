# Binary rescue and Lane-I are the same fixed-shift test

**Status:** proved exact equivalence  
**Date:** 2026-08-16  
**Depends on:** `BINARY-R-DIVISOR-COLLISION.md`, `ES-TWO-TARGET-DIVISOR-SQUARE.md`, `ES-plus/LETTER-EQUATION.md`  
**Claim boundary:** this identifies two exact formulations of the same fixed-shift Erdős–Straus condition. It does not prove that some shift always succeeds and therefore does not prove Erdős–Straus.

---

## 1. Setup

Let

\[
p\equiv1\pmod4
\]

be prime and let

\[
k\equiv3\pmod4,
\qquad
\gcd(k,p)=1.
\]

Put

\[
\boxed{C=\frac{p+k}{4}},
\qquad
\boxed{N=pC}.
\]

Then `gcd(C,k)=1`. Also `gcd(p,C)=1`, because any common divisor of `p` and `C` divides

\[
4C-p=k.
\]

Thus every divisor of `N^2=p^2C^2` has a unique form

\[
\boxed{D=p^a e,
\qquad a\in\{0,1,2\},
\qquad e\mid C^2.}
\]

Modulo `k`,

\[
\boxed{p\equiv4C},
\qquad
\boxed{N=pC\equiv4C^2.}
\]

---

## 2. The binary criterion

`BINARY-R-DIVISOR-COLLISION.md` applies to any odd positive `k==3 mod4` with `gcd(N,k)=1`; primality of `k` is not required.

The binary remainder

\[
\frac{k}{N}
\]

splits into two unit fractions if and only if there exists

\[
D\mid N^2
\]

such that

\[
\boxed{D\equiv-N\pmod k.}
\]

Using `D=p^a e` and `N==4C^2 mod k`, this is

\[
p^a e\equiv-4C^2\pmod k.
\]

The three possible exponents `a=0,1,2` are exactly the two Lane-I targets.

---

## 3. The middle p-exponent is exactly Type II

If

\[
a=1,
\]

then

\[
pe\equiv-4C^2\pmod k.
\]

Since `p==4C mod k` and `4C` is a unit,

\[
4Ce\equiv-4C^2
\]

is equivalent to

\[
\boxed{e\equiv-C\pmod k.}
\]

By `ES-TWO-TARGET-DIVISOR-SQUARE.md`, this is exactly the Type-II divisor-square criterion.

Therefore

\[
\boxed{
a=1
\quad\Longleftrightarrow\quad
\text{Lane-I Type II}.}
\]

An explicit Lane-I Type-II witness `e|C^2` maps to the binary witness

\[
\boxed{D=pe.}
\]

---

## 4. The outer p-exponents are the two Type-I orientations

### Case a=2

If

\[
a=2,
\]

then

\[
p^2e\equiv-4C^2\pmod k.
\]

Using `p^2==16C^2 mod k` and cancelling `C^2`,

\[
16e\equiv-4
\]

so

\[
\boxed{e\equiv-4^{-1}\pmod k.}
\]

Equivalently,

\[
\boxed{4e\equiv-1\pmod k,}
\]

which is exactly the Type-I divisor-square criterion.

Thus a Type-I witness `e|C^2` maps directly to

\[
\boxed{D=p^2e.}
\]

### Case a=0

If

\[
a=0,
\]

then

\[
e\equiv-4C^2\pmod k.
\]

Let

\[
e^*=\frac{C^2}{e}.
\]

Because `e` is a unit modulo `k`,

\[
e^*
\equiv
\frac{C^2}{-4C^2}
\equiv
-4^{-1}
\pmod k.
\]

Hence `e*` is again a Type-I divisor-square witness. This is precisely divisor-complement symmetry between the two Type-I orientations.

Therefore

\[
\boxed{
a\in\{0,2\}
\quad\Longleftrightarrow\quad
\text{Lane-I Type I}.}
\]

---

## 5. Exact equivalence theorem

### Theorem

For prime `p==1 mod4` and any admissible shift

\[
k\equiv3\pmod4,
\qquad
\gcd(k,p)=1,
\]

with

\[
C=\frac{p+k}{4},
\qquad
N=pC,
\]

the following are equivalent:

1. the fixed-`k` binary remainder
   \[
   \frac{k}{N}
   \]
   splits into two unit fractions;
2. there exists `D|N^2` with
   \[
   D\equiv-N\pmod k;
   \]
3. the Lane-I two-target signed box hits at shift `k`;
4. there exists `e|C^2` satisfying at least one of
   \[
   \boxed{4e\equiv-1\pmod k}
   \]
   or
   \[
   \boxed{e\equiv-C\pmod k.}
   \]

In particular,

\[
\boxed{
\text{binary rescue at }r=k
\iff
\delta_k\!\left(\frac{p+k}{4}\right)=0.
}
\]

This is an equality of the fixed-shift hit sets, not merely an implication.

---

## 6. Consecutive-selector identification

For a Mordell-hard prime write

\[
P=\frac{p-1}{4}.
\]

The consecutive binary selector uses

\[
r_u=4u-1.
\]

Taking

\[
k=r_u
\]

gives

\[
C
=\frac{p+k}{4}
=\frac{p-1}{4}+u
=\boxed{P+u}.
\]

Therefore CBX Lane-I shifts

\[
3,7,11,15,\ldots
\]

are exactly the consecutive binary selectors

\[
u=1,2,3,4,\ldots.
\]

Their first-hit depths satisfy

\[
\boxed{k_I^*(p)=4u^*(p)-1.}
\]

For example, the finite record

\[
p=8,803,369,
\qquad
k_I^*=107
\]

is exactly the previously recorded consecutive-selector first hit

\[
u^*=27,
\qquad
r_{27}=107.
\]

---

## 7. Consequence for theorem mining

This equivalence removes a duplicated frontier.

Every exact fixed-`r` binary theorem is automatically an exact classification of the corresponding CBX Lane-I layer `k=r`, including the existing results at `3`, `7`, and `11`.

Conversely, every CBX finite layer census is finite evidence about the same binary-rescue hit set and can be used to prioritize new fixed-`r` classifications.

In particular, the 10M overlap graph should not rediscover already-proved binary residue classes as if they were new Lane-I phenomena. Its highest-value role is to identify unexplained overlap or failure structure **after** importing the binary classifications.

The computational orientation remains distinct:

- the binary program was developed primarily as a theorem-mining formulation;
- CBX supplies p-major, C-major, shift-major, standalone, overlap, and hybrid scheduling instruments.

The mathematical predicate is the same.

---

## 8. Research direction

The next exact target is therefore not to maintain separate “binary” and “Lane-I” fixed-shift theories. It is to build one shared fixed-shift classification table:

\[
\boxed{
k=3,7,11,15,19,23,\ldots}
\]

recording, for each shift,

- exact automatic residue families;
- exact factor-support failure laws;
- Type-I versus Type-II witness mechanism;
- finite intrinsic hit rate;
- overlap with earlier classified layers;
- the remaining unclassified failure set.

That table can feed both proof search and CBX scheduling without changing mathematical semantics.

---

Erdős–Straus remains open. This theorem identifies two exact formulations; it does not supply the missing universal existence argument.
