# One-Dimensional Type I Divisor Layers

**Status:** proved equivalence for the `b=1` Type I axis; proposed first-hit research system  
**Date:** 2026-08-15  
**Depends on:** `FAB-ONE-PARAMETER-AXES.md`, `FAB-TYPE-I-EQUIVALENCE.md`  
**Prior-art calibration:** Elsholtz–Tao record that the computations available to them represented every prime `p≡1 mod4`, `p<=10^14`, in their Type I parametrization with their parameter `a=1`. Under the exact variable crosswalk, that is the `fab` axis `b=1`.  
**Claim boundary:** the `10^14` statement is prior finite computation, not a universal theorem. This note gives an exact layer reformulation of that axis.

---

## 1. Start from the exact b=1 Type I axis

For prime

\[
p\equiv1\pmod4,
\]

the `b=1` coprime Type I criterion is:

there exist positive integers `a,k` such that

\[
\boxed{k\mid p+a}
\]

and

\[
\boxed{k\equiv-p\pmod{4a}.}
\]

Equivalently,

\[
\boxed{4a\mid p+k.}
\]

Because `p` is prime and this is a Type I certificate, `p∤a,k`.

---

## 2. Introduce the layer coordinate c

Define

\[
\boxed{c=\frac{p+k}{4a}.}
\]

Then

\[
p+k=4ac
\]

and hence

\[
\boxed{a=\frac{p+k}{4c}.}
\]

Now impose the divisor condition `k|p+a`.

Multiply by `4c`:

\[
4c(p+a)=4cp+p+k.
\]

Modulo `k`, this is

\[
p(4c+1).
\]

Since `p∤k`,

\[
k\mid p+a
\iff
\boxed{k\mid4c+1.}
\]

Thus the two-parameter axis collapses to a one-dimensional layer indexed by `c`.

---

## 3. Exact layer theorem

### Theorem

A prime

\[
p\equiv1\pmod4
\]

has a `b=1` Type I solution if and only if there exist positive integers `c,k` such that

\[
\boxed{k\mid4c+1}
\]

and

\[
\boxed{p\equiv-k\pmod{4c}.}
\]

Because

\[
4c+1\equiv1\pmod4
\]

while

\[
p\equiv1\pmod4,
\]

the congruence forces

\[
\boxed{k\equiv3\pmod4.}
\]

Conversely any divisor `k|4c+1`, `k≡3 mod4`, satisfying the displayed target congruence gives

\[
a=\frac{p+k}{4c}\in\mathbb N
\]

and reconstructs the exact Type I certificate.

---

## 4. Layer trap set

Define the one-dimensional Type I layer modulus

\[
\boxed{N_c=4c}
\]

and trap set

\[
\boxed{
U_c
=
\{-k\pmod{4c}:
 k\mid4c+1,
 k\equiv3\pmod4\}.
}
\]

Then

\[
\boxed{
p\text{ is solved on the b=1 Type I axis}
\iff
\exists c\ge1:\ p\bmod N_c\in U_c.
}
\]

This is directly analogous to the Type A/B layer system, but with a different arithmetic source:

- modulus: `4c`;
- trap numerators: selected divisors of `4c+1`;
- target residue: the negative divisor.

---

## 5. Divisor-pair symmetry inside a layer

Since

\[
4c+1\equiv1\pmod4,
\]

if

\[
k\mid4c+1
\]

and

\[
k\equiv3\pmod4,
\]

then the complementary divisor

\[
\ell=\frac{4c+1}{k}
\]

also satisfies

\[
\boxed{\ell\equiv3\pmod4.}
\]

Thus useful trap numerators occur in divisor pairs

\[
\boxed{k\ell=4c+1,\qquad k\equiv\ell\equiv3\pmod4.}
\]

The layer is empty exactly when `4c+1` has no divisor `3 mod4`, equivalently when every prime factor `3 mod4` occurs to even exponent.

---

## 6. Polynomial form

Write

\[
4c+1=k\ell
\]

with

\[
k,\ell\equiv3\pmod4.
\]

The target congruence gives

\[
p+k=4ca
\]

for some positive integer `a`.

Since

\[
4c=k\ell-1,
\]

we obtain the exact polynomial representation

\[
\boxed{
p=a(k\ell-1)-k.}
\]

Equivalently,

\[
\boxed{p+a+k=ak\ell.}
\]

So universal `b=1` Type I would be equivalent to representing every prime `p≡1 mod4` by this ternary divisor polynomial with both `k,ell≡3 mod4`.

---

## 7. First-hit invariant

Define

\[
\boxed{
C_{I,1}(p)
=
\min\{c\ge1:\ p\bmod4c\in U_c\},
}
\]

when the set is nonempty.

This is a Type I analogue of `C_AB`, but it tracks the one-dimensional `b=1` divisor layers rather than López A/B depth.

The classical finite computation cited by Elsholtz–Tao implies

\[
\boxed{
C_{I,1}(p)<\infty
}
\]

for every tested prime

\[
p\equiv1\pmod4,
\qquad
p\le10^{14}.
\]

This is finite evidence only.

---

## 8. Why this subsystem is strategically important

The `b=1` axis is much smaller than the complete coprime Type I plane, yet it already survived the enormous historical finite test.

It also has a clean layer geometry suitable for the existing FCF/CENTL machinery:

- exact trap cardinality from the factorization of `4c+1`;
- direct/collective shadow questions between moduli `4c`;
- exact first-hit depth;
- character signatures of divisor-pair traps;
- survivor densities and hazards;
- possible ancestry when one `4c_i` divides another.

The active theorem question is therefore worth isolating:

\[
\boxed{
\text{Does every prime }p\equiv1\pmod4
\text{ hit some one-dimensional Type I divisor layer?}
}
\]

A proof would establish universal Type I and hence Erdős-Straus for all primes. A counterexample would be a mathematically meaningful Type I-axis survivor and should immediately be tested in the larger coprime Type I plane and Type II system.
