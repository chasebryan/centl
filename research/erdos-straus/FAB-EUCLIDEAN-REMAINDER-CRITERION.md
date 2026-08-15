# Euclidean remainder criterion for coprime fab certificates

**Status:** exact equivalence proved; naive descent explicitly refuted  
**Date:** 2026-08-15  
**Depends on:** `FAB-RECIPROCAL-DUALITY.md`  
**Claim boundary:** this does not prove universal existence. The final section records explicit cycles that rule out the most obvious descent map.

## 1. Canonical Bezout pair

Let

\[
p\equiv1\pmod4
\]

be prime. Choose any positive integer

\[
\boxed{M\equiv0\pmod4,
\qquad \gcd(M,p)=1.}
\]

Let `q` be the least positive inverse of `M mod p`:

\[
\boxed{1\le q<p,
\qquad Mq\equiv1\pmod p.}
\]

Define

\[
\boxed{d=\frac{Mq-1}{p}.}
\]

Then

\[
\boxed{Mq-pd=1.}
\]

Because `q<p`,

\[
0<d<M.
\]

Reducing the Bezout identity modulo `4` gives

\[
-pd\equiv1\pmod4.
\]

Since `p=1 mod4`,

\[
\boxed{d\equiv3\pmod4.}
\]

Thus every admissible `M` canonically creates a smaller `3 mod4` integer `d`.

## 2. The next negative remainder

Write the negative Euclidean division of `q` by `d` as

\[
\boxed{q=ad-b,
\qquad 0<b<d.}
\]

Equivalently,

\[
\boxed{b=\langle-q\rangle_d.}
\]

More generally, every positive integer `b'` satisfying

\[
d\mid q+b'
\]

lies in the single residue class

\[
\boxed{b'\equiv b\pmod d.}
\]

## 3. Exact divisor criterion on M/4

Suppose there exists a positive divisor

\[
\boxed{b'\mid M/4}
\]

such that

\[
\boxed{b'\equiv-q\pmod d.}
\]

Define

\[
\boxed{c=\frac{M}{4b'},
\qquad a=\frac{q+b'}{d}.}
\]

Finally put

\[
\boxed{k=Ma-p.}
\]

Then

\[
kd
=d(Ma-p)
=M(q+b')-pd
=1+Mb'
=1+4b'^2c.
\]

Hence `k>0`. Since `d=3 mod4` and `kd=1 mod4`, also

\[
\boxed{k\equiv3\pmod4.}
\]

Moreover

\[
p+k=Ma=4ab'c,
\]

and

\[
kq
=(Ma-p)q
=a(Mq)-pq
=a(pd+1)-pq
=a+p(ad-q)
=a+b'p.
\]

Therefore all reciprocal-fab skeleton identities hold and

\[
\boxed{
\frac4p
=
\frac1{ab'c}
+
\frac1{acq}
+
\frac1{b'cpq}.
}
\]

Conversely, any coprime fab certificate defines `M=4bc`, satisfies `Mq-pd=1`, and its `b` is a divisor of `M/4` in the residue class `-q mod d`.

Thus:

### Theorem — Euclidean remainder criterion

For prime `p=1 mod4` and fixed `M=0 mod4` coprime to `p`, let

\[
Mq-pd=1,
\qquad 1\le q<p,
\qquad 0<d<M.
\]

Then a reciprocal/coprime fab certificate with `M=4bc` exists if and only if

\[
\boxed{
\exists b\mid M/4:
\quad b\equiv-q\pmod d.
}
\]

The original search over `(a,b,c,k,q)` has therefore collapsed, at fixed `M`, to one divisor-in-one-residue-class question after a single extended-Euclidean computation.

## 4. Continued-fraction interpretation

The identity

\[
Mq-pd=1
\]

means the fractions

\[
\frac pM
\qquad\text{and}\qquad
\frac qd
\]

are Farey neighbours, with

\[
\frac qd-\frac pM=\frac1{Md}>0.
\]

The certificate condition asks whether the next **negative** Euclidean remainder

\[
b=ad-q
\]

(or another positive member of its residue class modulo `d`) occurs among the divisors of `M/4`.

This makes the missing universal theorem a compatibility statement between:

1. the continued-fraction/Bezout geometry of `(p,M)`; and
2. the divisor geometry of `M/4`.

## 5. The tempting map M -> 4b does not descend universally

A natural attempt is:

1. start from `M`;
2. compute the least negative remainder `b=< -q >_d`;
3. if `b` does not divide `M/4`, replace
   \[
   M\mapsto4b
   \]
   so the old remainder is forced to divide the new `M/4`;
4. repeat.

This is **not** a valid universal descent. The newly computed Bezout pair changes, and explicit cycles occur.

For example, for

\[
\boxed{p=2521}
\]

starting at `M=12`, the exact map produces

```text
12 -> 40 -> 152 -> 184 -> 104 -> 240 -> 236
   -> 136 -> 176 -> 192 -> 80 -> 76 -> 116 -> 16 -> 12.
```

No state in this cycle satisfies the divisor fixed-point condition for its own newly computed remainder.

For the finite Type A/B record prime

\[
p=9658489,
\]

the same naive map enters the shorter cycle

```text
40 -> 96 -> 68 -> 100 -> 40.
```

Therefore any successful descent proof must use a different monotone invariant or permit a controlled choice among divisors in the residue class, rather than blindly replacing `M` by four times the least remainder.

This negative result should be retained: it prevents a seductive but false Euclidean-descent proof from being rediscovered later.
