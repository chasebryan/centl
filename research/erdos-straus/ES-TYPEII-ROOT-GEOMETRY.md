# Type-II root geometry: López A/B are the comparable-root cases

**Status:** proved exact parametrization and structural corollary  
**Date:** 2026-08-15  
**Depends on:** `ES-TYPEII-SQUARE-COMPLETION-LOPEZ-A.md`, `ES-SQUARE-COMPLETION-TRAP-GEOMETRY.md`  
**Claim boundary:** this is an exact reparametrization of the square-completed standard Type-II theorem. It does not prove universal Type-II existence.

---

## 1. Squarefree-root decomposition

Let `p≡1 mod4` be prime and suppose a square-completed Type-II certificate is given by positive integers `a,d` with

\[
\boxed{
d\mid a^2,
\qquad
p\nmid d,
\qquad
4a-1\mid p+4d.}
\]

Because

\[
d\cdot\frac{a^2}{d}=a^2
\]

is a square, the two integers

\[
d
\qquad\text{and}\qquad
\frac{a^2}{d}
\]

have the same squarefree kernel.

Therefore there are unique positive integers `s,b,c` with `s` squarefree such that

\[
\boxed{
d=sb^2,
\qquad
\frac{a^2}{d}=sc^2.}
\]

Multiplying gives

\[
a^2=s^2b^2c^2,
\]

so

\[
\boxed{a=sbc.}
\]

Thus every square-completed Type-II certificate has canonical root data

\[
\boxed{(s,b,c),\qquad s\text{ squarefree}.}
\]

---

## 2. The exact congruence in root coordinates

Let

\[
q=rac{p+4d}{4a-1}.
\]

Substituting

\[
d=sb^2,
\qquad
a=sbc
\]

gives

\[
\boxed{
p+4sb^2=(4sbc-1)q.}
\]

Define

\[
\boxed{t=cq-b.}
\]

Then

\[
\begin{aligned}
p+q
&=4sbcq-4sb^2\\
&=4sb(cq-b)\\
&=4sbt,
\end{aligned}
\]

so

\[
\boxed{p+q=4sbt.}
\]

Since the left side is positive,

\[
\boxed{t>0.}
\]

Also by definition

\[
\boxed{b+t=cq.}
\]

Thus the square-completed congruence is equivalent to the four positive parameters

\[
\boxed{
p+q=4sbt,
\qquad
b+t=cq.}
\]

---

## 3. Explicit Type-II decomposition

The two equations immediately give

\[
\begin{aligned}
\frac1{sctp}
+\frac1{sbt}
+\frac1{sbcp}
&=
\frac{b+p c+t}{sbc tp}\\
&=
\frac{cq+pc}{sbc tp}\\
&=
\frac{c(p+q)}{sbc tp}\\
&=
\frac4p.
\end{aligned}
\]

Therefore:

### Theorem — explicit root decomposition

Every square-completed certificate

\[
p+4sb^2=(4sbc-1)q
\]

with

\[
t=cq-b>0
\]

gives the exact standard Type-II identity

\[
\boxed{
\frac4p
=
\frac1{sctp}
+
\frac1{sbt}
+
\frac1{sbcp}.}
\]

Two of the three denominators carry the factor `p`, as expected for Type II.

---

## 4. López Type A is b | c

Recall

\[
d=sb^2,
\qquad
a=sbc.
\]

The ordinary López Type-A boundary condition is

\[
d\mid a.
\]

This is equivalent to

\[
sb^2\mid sbc,
\]

hence

\[
\boxed{b\mid c.}
\]

Therefore the lower López orthant is exactly the region where the first root divides the second.

---

## 5. López Type B is c | b

The upper square-divisor boundary corresponding to López Type B is

\[
a\mid d.
\]

In root variables this is

\[
sbc\mid sb^2,
\]

so

\[
\boxed{c\mid b.}
\]

Thus the upper López orthant is exactly the opposite divisibility order.

---

## 6. Exact comparability theorem

Combining the two cases:

### Theorem — López A/B are the comparable-root Type-II certificates

A square-completed standard Type-II certificate belongs to one of the two López boundary families at the same layer if and only if

\[
\boxed{b\mid c\quad\text{or}\quad c\mid b.}
\]

The genuinely square-only Type-II certificates are exactly those with

\[
\boxed{b\nmid c
\qquad\text{and}\qquad
c\nmid b.}
\]

So the cross-orthant geometry has an elementary interpretation:

> the two square roots are incomparable in the divisibility poset.

---

## 7. Complement simply swaps the roots

The divisor complement is

\[
d^*=\frac{a^2}{d}=sc^2.
\]

Thus

\[
\boxed{d\longleftrightarrow d^*}
\]

is exactly

\[
\boxed{b\longleftrightarrow c.}
\]

This makes all previous symmetry transparent:

- Type A (`b|c`) is sent to Type B (`c|b`);
- mixed certificates (`b,c` incomparable) remain mixed;
- inverse residue pairing is just root exchange.

The entire square-divisor complement theory therefore becomes a two-root symmetry.

---

## 8. Example p = 2521

The mixed certificate

\[
a=12,
\qquad d=16
\]

has

\[
d=1\cdot4^2,
\qquad
\frac{a^2}{d}=9=1\cdot3^2.
\]

Thus

\[
\boxed{s=1,
\qquad b=4,
\qquad c=3.}
\]

The roots are incomparable:

\[
4\nmid3,
\qquad
3\nmid4.
\]

The congruence quotient is

\[
q=55
\]

and

\[
t=cq-b=3\cdot55-4=161.
\]

Hence

\[
p+q=2521+55=2576=4\cdot1\cdot4\cdot161
\]

and

\[
b+t=4+161=165=3\cdot55.
\]

The explicit decomposition is

\[
\boxed{
\frac4{2521}
=
\frac1{3\cdot161\cdot2521}
+
\frac1{4\cdot161}
+
\frac1{4\cdot3\cdot2521}.}
\]

This is a standard Type-II solution represented by incomparable roots.

---

## 9. Strategic consequence

The López all-prime conjecture can now be interpreted inside standard Type II as a **divisibility-comparability conjecture**:

> for every prime, find a Type-II certificate whose canonical roots can be chosen comparable by divisibility.

The complete Type-II problem drops that comparability requirement.

This suggests two distinct proof directions:

1. **completion route:** use all incomparable-root certificates directly, which is enough for standard Type II;
2. **descent route:** try to transform any incomparable-root certificate into another certificate with a smaller incomparability measure until one root divides the other.

A natural descent statistic is obtained after writing

\[
g=\gcd(b,c),
\qquad
b=gB,
\qquad
c=gC,
\qquad
\gcd(B,C)=1.
\]

The mixed case is precisely

\[
B>1,
\qquad
C>1.
\]

Whether the exact equations

\[
p+q=4sbt,
\qquad
b+t=cq
\]

admit a transformation that reduces `BC` while preserving `p` is now a concrete theorem target.
