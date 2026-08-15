# Standard Type II as the square-divisor completion of López Type A

**Status:** proved exact equivalence  
**Date:** 2026-08-15  
**Depends on:** `ES-TWO-TARGET-DIVISOR-SQUARE.md`, `ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md`  
**External background:** Miguel Angel López, *A Complete Congruence System for the Erdos-Straus Conjecture*, arXiv:2404.01508, especially Theorem 7  
**Claim boundary:** this identifies an exact structural relation between standard prime Type II and the López Type-A congruence family. It does not prove universal existence and no literature-priority claim is made without a separate prior-art review.

---

## 1. Exact Type-II divisor-square starting point

Let

\[
p\equiv1\pmod4
\]

be prime.

`ES-TWO-TARGET-DIVISOR-SQUARE.md` proves that a standard Type-II solution at an admissible shift

\[
k\equiv3\pmod4,
\qquad
\gcd(k,p)=1
\]

is equivalent to the existence of

\[
C=\frac{p+k}{4}
\]

and a divisor

\[
\boxed{d\mid C^2}
\]

such that

\[
\boxed{d\equiv-C\pmod k.}
\]

Write

\[
\boxed{d+C=ak}
\]

for a positive integer `a`.

---

## 2. Eliminate the shift

Using

\[
4C=p+k,
\]

multiply `d+C=ak` by four:

\[
4d+p+k=4ak.
\]

Hence

\[
\boxed{p+4d=(4a-1)k.}
\]

Therefore every Type-II certificate gives the López-shaped congruence

\[
\boxed{4a-1\mid p+4d,}
\]

or equivalently

\[
\boxed{p\equiv-4d\pmod{4a-1}.}
\]

This is exactly the residue shape occurring in López Type A.

---

## 3. The square-divisor condition collapses to d | a^2

Because

\[
d\mid C^2
\]

and

\[
\gcd(C,k)=1,
\]

we have

\[
\gcd(d,k)=1.
\]

Modulo `d`, the equation

\[
d+C=ak
\]

gives

\[
C\equiv ak\pmod d.
\]

Squaring,

\[
C^2\equiv a^2k^2\pmod d.
\]

Since `d|C^2` and `k` is invertible modulo `d`,

\[
\boxed{d\mid a^2.}
\]

Thus every standard Type-II solution yields positive integers `a,d` satisfying

\[
\boxed{
d\mid a^2,
\qquad
4a-1\mid p+4d.}
\]

Also `p` does not divide `d`, because `d|C^2` and `p` does not divide `C`.

---

## 4. Converse construction

Now suppose positive integers `a,d` satisfy

\[
\boxed{
d\mid a^2,
\qquad
p\nmid d,
\qquad
4a-1\mid p+4d.}
\]

Define

\[
\boxed{k=\frac{p+4d}{4a-1}.}
\]

Because

\[
p+4d\equiv1\pmod4
\]

and

\[
4a-1\equiv3\pmod4,
\]

we obtain

\[
\boxed{k\equiv3\pmod4.}
\]

If `p|k`, then from

\[
(4a-1)k=p+4d
\]

we would get `p|d`, contradiction. Hence

\[
\boxed{\gcd(k,p)=1.}
\]

Put

\[
\boxed{C=\frac{p+k}{4}.}
\]

The defining equations give

\[
\boxed{(4a-1)C=ap+d.}
\]

Since any common divisor of `d` and `4a-1` divides `a` and then divides `1`,

\[
\boxed{\gcd(d,4a-1)=1.}
\]

Modulo `d`,

\[
(4a-1)C\equiv ap\pmod d.
\]

Squaring and using `d|a^2`, together with `p` and `4a-1` invertible modulo `d`, gives

\[
\boxed{d\mid C^2.}
\]

Finally,

\[
\begin{aligned}
(4a-1)(d+C)
&=(4a-1)d+ap+d\\
&=a(p+4d)\\
&=a(4a-1)k,
\end{aligned}
\]

so

\[
\boxed{d+C=ak.}
\]

Therefore

\[
d\equiv-C\pmod k,
\]

and the exact Type-II divisor-square criterion applies.

---

## 5. Exact theorem

### Theorem — square-completed Type A equals standard prime Type II

For a prime

\[
p\equiv1\pmod4,
\]

the following are equivalent:

1. `p` has a standard Type-II Erdős--Straus solution;
2. there exist positive integers `a,d` such that
   \[
   \boxed{
   d\mid a^2,
   \qquad
   p\nmid d,
   \qquad
   4a-1\mid p+4d.}
   \]

Equivalently,

\[
\boxed{
\text{Type II}
\iff
\exists a,d>0:
 d\mid a^2,
\quad
p\equiv-4d\pmod{4a-1},
\quad p\nmid d.}
\]

---

## 6. Relation to López Type A

López Theorem 7 states that a prime has a Type-A solution exactly when there exist positive `d,n` such that

\[
\boxed{p\equiv-4d\pmod{4dn-1}.}
\]

Put

\[
\boxed{a=dn.}
\]

Then López Type A is precisely the subfamily

\[
\boxed{
d\mid a,
\qquad
p\equiv-4d\pmod{4a-1}.}
\]

The standard Type-II theorem above enlarges only the divisor condition:

\[
\boxed{
\begin{array}{ccl}
\text{López Type A} &:& d\mid a,\\[1mm]
\text{standard Type II} &:& d\mid a^2,
\end{array}}
\]

with the **same modulus** `4a-1` and the **same target residue** `-4d`.

Therefore:

\[
\boxed{
\text{standard prime Type II is the square-divisor completion of López Type A}.}
\]

Every López Type-A solution is automatically contained in the square-completed family, because

\[
d\mid a\Longrightarrow d\mid a^2.
\]

The converse need not hold.

---

## 7. Genuine square-only witness: p = 2521

López records `2521` among the exceptional primes lacking Type-A solutions in the finite analysis of that paper.

Take

\[
\boxed{p=2521,
\qquad a=12,
\qquad d=16.}
\]

Then

\[
16\mid12^2=144,
\]

but

\[
\boxed{16\nmid12.}
\]

Thus this is genuinely outside the ordinary López Type-A divisor condition.

Nevertheless

\[
4a-1=47
\]

and

\[
p+4d=2521+64=2585=47\cdot55.
\]

Hence

\[
\boxed{47\mid p+4d.}
\]

The corresponding exact signed-box shift is

\[
\boxed{k=55,}
\]

with

\[
C=\frac{2521+55}{4}=644.
\]

Indeed

\[
16\mid644^2
\]

and

\[
16+644=660=12\cdot55.
\]

So the square-completed congruence supplies a standard Type-II solution for `2521` even though this certificate is not a López Type-A certificate.

The complementary divisor is

\[
\frac{644^2}{16}=25921=161^2,
\]

so the normalized factor pair is especially transparent:

\[
16=4^2,
\qquad
25921=161^2,
\qquad
55\mid4+161.
\]

---

## 8. Strategic consequence

The old Type-A/B program and the complete Type-I/II program are not separate languages.

At least on the Type-A side there is an exact completion map:

\[
\boxed{
 d\mid a
\quad\leadsto\quad
 d\mid a^2.}
\]

The congruence itself does not change.

This suggests a new direct proof strategy:

1. retain all López Type-A congruence and shadow machinery;
2. replace the divisor lattice `Div(a)` by the square divisor lattice `Div(a^2)`;
3. study whether the additional square-only residues close the zero-density composite-rescue core;
4. compare the resulting square-completed trap system with the exact Type-II signed-divisor box and its Kneser quotient defects.

The square completion may therefore provide the missing bridge by which the mature Type-A/B machinery can be reused inside the exact prime Erdős--Straus formulation rather than abandoned.
