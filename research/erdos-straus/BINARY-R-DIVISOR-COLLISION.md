# Binary-r rescue as a signed divisor collision

**Status:** proved exact reformulation  
**Date:** 2026-08-15  
**Depends on:** `BINARY-R-RESCUE.md`  
**Claim boundary:** this converts the exact binary rescue condition into a finite multiplicative collision problem. It does not prove that such a collision always occurs.

## 1. Setup

Let `p == 1 (mod 4)` be prime and let `r == 3 (mod 4)` be an odd positive integer such that

\[
\gcd(r,p)=1,
\qquad
A_r=\frac{p+r}{4}\in\mathbb Z,
\qquad
\gcd(r,A_r)=1.
\]

Put

\[
N=N_r=pA_r.
\]

Then

\[
\frac4p
=
\frac1{A_r}
+
\frac rN.
\]

By `BINARY-R-RESCUE.md`, the binary remainder splits if and only if there is a divisor

\[
d\mid N^2
\]

with

\[
\boxed{d\equiv-N\pmod r.}
\]

The argument below does not require `r` prime, only `gcd(N,r)=1`.

---

## 2. Every divisor of N^2 is a signed divisor ratio around N

Write

\[
N=\prod_i q_i^{e_i}.
\]

A divisor

\[
d=\prod_i q_i^{f_i},
\qquad 0\le f_i\le2e_i,
\]

can be written

\[
\boxed{d=N\frac{x}{y}}
\]

where `x,y|N`.

Indeed, for each prime put

\[
z_i=f_i-e_i\in[-e_i,e_i].
\]

The positive `z_i` exponents form `x` and the negative exponents form `y`.

Conversely, for any `x,y|N`,

\[
N\frac{x}{y}
\]

is an integer divisor of `N^2`: primewise its exponent lies between `0` and `2e_i`.

Because `gcd(N,r)=1`, every divisor of `N` is invertible modulo `r`.

Therefore

\[
d\equiv-N\pmod r
\]

is equivalent to

\[
Nxy^{-1}\equiv-N\pmod r,
\]

hence to

\[
\boxed{x\equiv-y\pmod r.}
\]

---

## 3. Divisor-collision theorem

Let

\[
D_r(N)=\{x\bmod r:x\mid N\}
\subseteq(\mathbb Z/r\mathbb Z)^\times.
\]

Then the following are equivalent:

1. the binary-r remainder `r/N` splits into two unit fractions;
2. there is `d|N^2` with `d == -N (mod r)`;
3. there are divisors `x,y|N` with
   \[
   x\equiv-y\pmod r;
   \]
4. the divisor residue set meets its negative:
   \[
   \boxed{D_r(N)\cap(-D_r(N))\ne\varnothing;}
   \]
5. `-1` lies in the ratio set
   \[
   \boxed{-1\in D_r(N)D_r(N)^{-1}.}
   \]

Thus the fixed-r ES problem is a **signed divisor collision**, not an arbitrary search through all divisors of `N^2`.

---

## 4. Signed exponent-box formulation

With

\[
N=\prod_i q_i^{e_i},
\]

the collision exists if and only if there are integers

\[
-e_i\le z_i\le e_i
\]

such that

\[
\boxed{
\prod_i q_i^{z_i}\equiv-1\pmod r.
}
\]

This is the exact multiplicative analogue of a bounded symmetric exponent box hitting one distinguished group element.

It is structurally close to the two-box and defect-quotient machinery already developed in the Type A/B shadow program, but here the target is the actual Erdős–Straus decomposition rather than exact-depth realizability.

---

## 5. Pigeonhole escape

Since negation is a bijection of the unit group modulo `r`,

\[
|D_r(N)|=|-D_r(N)|.
\]

Therefore, if

\[
\boxed{2|D_r(N)|>\varphi(r),}
\]

then the two sets must intersect and the binary-r rescue is automatic.

For prime `r`, this is simply

\[
\boxed{|D_r(N)|>\frac{r-1}{2}.}
\]

Failure forces the divisor residues into at most half of the available unit classes.

This gives a clean theorem-mining target: prove divisor-residue expansion past the half-group threshold, or classify every multiplicatively compressed exception.

---

## 6. Exact reciprocity bridge for prime r

Now assume `r` is prime and `r == 3 (mod 4)`.

Let `q` be any odd prime divisor of

\[
A_r=\frac{p+r}{4}.
\]

Then

\[
p\equiv-r\pmod q.
\]

Because `p == 1 (mod 4)`, quadratic reciprocity gives

\[
\left(\frac qp\right)
=
\left(\frac pq\right)
=
\left(\frac{-r}{q}\right).
\]

Since `r == 3 (mod 4)`, reciprocity between `r` and `q` gives

\[
\left(\frac rq\right)
=
\left(\frac{-1}{q}\right)
\left(\frac qr\right).
\]

Hence

\[
\left(\frac{-r}{q}\right)
=
\left(\frac{-1}{q}\right)
\left(\frac rq\right)
=
\boxed{\left(\frac qr\right)}.
\]

Therefore

\[
\boxed{
q\mid A_r
\Longrightarrow
\left(\frac qp\right)=\left(\frac qr\right).
}
\]

So a prime factor of the shifted integer `A_r` is a quadratic nonresidue modulo `r` **if and only if** it is an external quadratic nonresidue modulo the hard prime `p`.

This is an exact bridge from `FAB-HARD-NONRESIDUE-BRIDGE.md` into the direct binary-r rescue.

---

## 7. Consecutive-translate interpretation

Put

\[
A=\frac{p+3}{4}.
\]

For

\[
r=4t+3,
\]

we have

\[
\boxed{A_r=A+t.}
\]

Thus the prime-r program probes the divisor geometry of consecutive translates of the original Eisenstein-split neighbor:

\[
A,\ A+1,\ A+2,\ A+4,\ A+5,\ A+7,\ldots
\]

for `r=3,7,11,19,23,31,...`.

The finite first-hit histogram in `BINARY-R-RESCUE.md` is therefore evidence about a sequence of exact multiplicative collision problems on nearby translates, not a collection of unrelated congruence tricks.

---

## 8. New all-prime target

A sufficient universal theorem now has the sharply stated form:

> For every Mordell-hard prime `p`, there exists an odd `r == 3 (mod 4)` with `gcd(r,pA_r)=1` such that the signed divisor exponent box of
> \[
> N_r=pA_r
> \]
> contains `-1` modulo `r`.

For prime `r`, failure means a multiplicatively compressed divisor set of size at most `(r-1)/2`; every nonresidue prime entering `A_r` is simultaneously an external nonresidue of `p` by the reciprocity bridge.

This is the current direct ES proof target.
