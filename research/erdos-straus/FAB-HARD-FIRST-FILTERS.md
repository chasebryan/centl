# First exact shifted-factor filters for Mordell-hard primes

**Status:** proved sufficient families and necessary restrictions on any prime counterexample  
**Date:** 2026-08-15  
**Depends on:** `FAB-COPRIME-DIVISOR-CRITERION.md`  
**Claim boundary:** these filters remove infinite families and sharply constrain a hypothetical counterexample. They do not prove that the remaining intersection is empty.

## 1. Hard-prime facts

Let `p` be a Mordell-hard prime:

\[
p\bmod840\in\{1,121,169,289,361,529\}.
\]

Then

\[
\boxed{p\equiv1\pmod{24}.}
\]

In particular `p≡1 mod8` and `p≡1 mod3`.

---

## 2. The p+1 / mod-4 filter

Take `a=b=1` in the coprime divisor criterion. A certificate exists whenever

\[
\exists k\mid p+1,\qquad k\equiv-p\equiv3\pmod4.
\]

Thus a counterexample must satisfy:

\[
\boxed{
\text{every odd prime factor of }(p+1)/2\text{ is }1\pmod4.
}
\]

This is the familiar simplest Type-B spine, included here to align the hierarchy.

---

## 3. Exact k=3 filter

Set

\[
N_3^-:=\frac{p+3}{4}.
\]

Because `p≡1 mod24`, this is an odd integer congruent to `1 mod3`.

### Theorem

If `N_3^-` has a divisor

\[
a\equiv2\pmod3,
\]

then `fab(p,a,1)>0` with admissible divisor

\[
\boxed{k=3.}
\]

### Proof

Since `a|N_3^-`,

\[
4a\mid p+3.
\]

Also `p≡1 mod3` and `a≡2 mod3`, hence

\[
3\mid p+a.
\]

Thus `k=3` divides `a+p` and

\[
3\equiv-p\pmod{4a}
\]

because `4a|p+3`. The coprime divisor criterion with `b=1` applies. QED.

Since `N_3^-≡1 mod3`, it has a divisor `2 mod3` if and only if it has a prime factor `2 mod3`.

Therefore any prime counterexample must satisfy

\[
\boxed{
\text{every prime factor of }\frac{p+3}{4}\text{ is }1\pmod3.
}
\]

An explicit decomposition is obtained by putting

\[
t=\frac{p+3}{4a},
\qquad
q=\frac{p+a}{3},
\]

which gives

\[
\frac4p
=
\frac1{at}
+
\frac1{aqt}
+
\frac1{pqt}.
\]

---

## 4. Dual d=3 filter

Set

\[
N_3^+:=\frac{3p+1}{4}.
\]

Again `N_3^+≡1 mod3`.

### Theorem

If `N_3^+` has a divisor

\[
c\equiv2\pmod3,
\]

then `p` has a coprime fab certificate.

### Construction

Put

\[
q=\frac{N_3^+}{c}.
\]

Because `N_3^+≡1 mod3` and `c≡2 mod3`,

\[
q\equiv2\pmod3.
\]

Define

\[
a=\frac{q+1}{3},
\qquad
k=\frac{4c+1}{3}.
\]

Both are positive integers, and since

\[
3k=4c+1\equiv1\pmod4,
\]

we have

\[
\boxed{k\equiv3\pmod4.}
\]

Now

\[
3(a+p)=q+1+3p=q+(4cq-1)=q(4c+1)=3kq,
\]

so

\[
k\mid a+p.
\]

Also

\[
3(p+k)=3p+4c+1=4c(q+1)=12ac,
\]

hence

\[
4a\mid p+k.
\]

Thus `k` satisfies the coprime divisor criterion for `(a,b)=(a,1)`. QED.

Consequently any prime counterexample must also satisfy

\[
\boxed{
\text{every prime factor of }\frac{3p+1}{4}\text{ is }1\pmod3.
}
\]

---

## 5. The two Eisenstein-split neighbours

A hypothetical Mordell-hard prime counterexample must therefore have

\[
A:=\frac{p+3}{4},
\qquad
B:=\frac{3p+1}{4}
\]

with every prime factor of both `A` and `B` equal to `1 mod3`.

These numbers satisfy the exact relation

\[
\boxed{B=3A-2.}
\]

Hence the all-prime remainder is contained in the simultaneous splitting problem

\[
\boxed{
A\text{ and }3A-2
\text{ are composed entirely of primes }1\pmod3.
}
\]

Equivalently, both lie in the multiplicative semigroup of rational primes that split in the Eisenstein quadratic field, with no ramified factor `3` and no inert factor `2 mod3`.

This is a structural restriction, not a contradiction: examples exist. Its value is that every subsequent rescue theorem may assume this simultaneous split structure.

---

## 6. The p+2 / mod-8 filter

Take `(a,b)=(2,1)`. Since hard `p≡1 mod8`, the target divisor class is

\[
-p\equiv7\pmod8.
\]

Thus

\[
\boxed{
\exists k\mid p+2,\quad k\equiv7\pmod8
\Longrightarrow
p\text{ is solved.}
}
\]

The absence of such a divisor has an exact factorization description.

Because

\[
p+2\equiv3\pmod8,
\]

a divisor `7 mod8` exists unless all prime factors of `p+2` are in the classes

\[
\boxed{1\text{ or }3\pmod8.}
\]

Indeed a prime factor `7 mod8` is itself a forbidden divisor, while a factor `3 mod8` times a factor `5 mod8` gives `7 mod8`. If no `7` divisor exists, classes `3` and `5` cannot both occur; the total residue `3 mod8` then forces the nontrivial class to be `3`, with odd total valuation parity.

So a counterexample must satisfy

\[
\boxed{
\text{every prime factor of }p+2\text{ is }1\text{ or }3\pmod8.
}
\]

---

## 7. Counterexample sieve produced by theorem, not by range

Every prime counterexample in the six Mordell-hard classes must simultaneously satisfy:

1. `(p+1)/2` has only odd prime factors `1 mod4`;
2. `(p+3)/4` has only prime factors `1 mod3`;
3. `(3p+1)/4` has only prime factors `1 mod3`;
4. `p+2` has only prime factors `1 or 3 mod8`.

These are exact infinite restrictions. They should be used as assumptions in the next descent rather than merely as computational filters.
