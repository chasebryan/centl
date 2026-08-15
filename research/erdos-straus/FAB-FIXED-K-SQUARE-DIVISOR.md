# Fixed-k fab criterion collapses to one divisor of N²

**Status:** proved exact theorem  
**Date:** 2026-08-15  
**Depends on:** `FAB-FIXED-K-SIGNED-DIVISOR.md`  
**Claim boundary:** this is an exact fixed-k reformulation. It does not prove that some k always succeeds and therefore does not prove Erdős-Straus.

## 1. Setup

Let

\[
p\equiv1\pmod4
\]

be prime, and let

\[
k\equiv3\pmod4,
\qquad \gcd(k,p)=1.
\]

Put

\[
\boxed{N=N_k=\frac{p+k}{4}.}
\]

Then

\[
\gcd(N,k)=1.
\]

Assume `N<p`, for example `k<3p`, so every divisor of `N` automatically satisfies the size hypotheses in the coprime fab criterion.

## 2. The theorem

### Fixed-k square-divisor criterion

There exists a coprime fab certificate using the fixed admissible divisor `k` if and only if

\[
\boxed{
\exists D\mid N^2
\quad\text{such that}\quad
4D\equiv-1\pmod k.
}
\]

Equivalently,

\[
\boxed{
D\equiv-4^{-1}\pmod k.
}
\]

For

\[
k=4s+3,
\]

one has

\[
4^{-1}\equiv s+1\pmod k,
\]

so the fixed target class is

\[
\boxed{D\equiv3s+2\pmod{4s+3}.}
\]

Crucially, this target residue depends only on `k`, not on `p`.

## 3. Proof from signed exponents

Factor

\[
N=\prod r^{e_r}.
\]

By `FAB-FIXED-K-SIGNED-DIVISOR.md`, fixed-k solvability is equivalent to choosing integers

\[
-e_r\le z_r\le e_r
\]

such that

\[
\prod r^{z_r}\equiv-p\pmod k.
\]

But

\[
4N=p+k\equiv p\pmod k,
\]

hence

\[
-p\equiv-4N\pmod k.
\]

Write

\[
d_r=e_r-z_r.
\]

Then

\[
0\le d_r\le2e_r.
\]

Therefore

\[
D:=\prod r^{d_r}
\]

runs through **exactly all positive divisors of `N^2`**.

Also

\[
\prod r^{z_r}
=N D^{-1}\pmod k.
\]

Thus the target equation becomes

\[
N D^{-1}\equiv-4N\pmod k.
\]

Since `N` is invertible modulo `k`, cancel it:

\[
D^{-1}\equiv-4\pmod k,
\]

or equivalently

\[
\boxed{4D\equiv-1\pmod k.}
\]

This proves the equivalence. QED.

## 4. Direct factor reconstruction

The divisor `D|N^2` contains the complete fab data.

For each prime `r^e||N`, let

\[
d=v_r(D),
\qquad0\le d\le2e.
\]

Define the exponents

\[
v_r(a)=\max(e-d,0),
\]

\[
v_r(b)=\max(d-e,0),
\]

\[
v_r(t)=e-|e-d|.
\]

Then

\[
\boxed{N=abt,}
\]

\[
\boxed{D=b^2t,}
\]

and

\[
\gcd(a,b)=1.
\]

The congruence

\[
4D\equiv-1\pmod k
\]

is

\[
4b^2t\equiv-1\pmod k.
\]

Since

\[
p+k=4N=4abt,
\]

the fixed-k fab equations follow exactly.

Let

\[
q=\frac{a+bp}{k}.
\]

Then the decomposition is

\[
\boxed{
\frac4p
=
\frac1{abt}
+
\frac1{aqt}
+
\frac1{bpqt}.
}
\]

## 5. Immediate examples

### k=3

Here

\[
-4^{-1}\equiv2\pmod3.
\]

Thus fixed `k=3` succeeds iff

\[
\boxed{
N_3^2
\text{ has a divisor }2\pmod3.
}
\]

That occurs exactly when `N_3=(p+3)/4` has a prime factor `2 mod3`, recovering the first Eisenstein filter.

### k=7

Here

\[
-4^{-1}\equiv5\pmod7.
\]

Thus fixed `k=7` succeeds iff

\[
\boxed{
N_7^2
\text{ has a divisor }5\pmod7.
}
\]

This is exactly the residue-product problem classified in `FAB-K7-EXACT-FILTER.md`.

### k=11

Here

\[
-4^{-1}\equiv8\pmod{11}.
\]

So the entire fixed-11 problem is simply:

\[
\boxed{
\exists D\mid((p+11)/4)^2,
\quad D\equiv8\pmod{11}.
}
\]

No separate search over `a,b` is needed.

## 6. Shift formulation

Let

\[
A=\frac{p+3}{4}.
\]

For `k=4s+3`,

\[
N_k=A+s.
\]

Therefore the all-prime problem contains the following exact subproblem:

> Given `A=(p+3)/4`, prove that for some `s>=0`, the square of the shifted integer `A+s` has a divisor congruent to
>
> \[
> 3s+2\pmod{4s+3}.
> \]

A finite set of `s` values would give a finite universal fab menu if proved sufficient. An expanding-set descent would also suffice.

This is a substantially simpler arithmetic target than the original two-parameter fab conditions.
