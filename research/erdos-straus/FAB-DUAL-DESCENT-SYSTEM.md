# Dual descent system behind sufficient fab certificates

**Status:** proved exact algebraic structure  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Depends on:** `FAB-UNBOUNDED-DIVISOR-RATIO-CERTIFICATE.md`, `FAB-HARD-NONRESIDUE-BRIDGE.md`  
**Claim boundary:** these identities expose a hidden duality and reciprocity package inside every certificate. They do not prove that a certificate exists for every hard prime.

---

## 1. Master equation

Let `p` be a prime with

\[
p\equiv1\pmod4.
\]

Suppose positive integers `a,b,k` give a sufficient certificate:

\[
k\mid a+bp,
\qquad
4ab\mid p+k.
\]

Write

\[
q=\frac{a+bp}{k},
\qquad
c=\frac{p+k}{4ab}.
\]

Then

\[
kq=a+bp,
\qquad
k=4abc-p.
\]

Substituting gives

\[
(4abc-p)q=a+bp,
\]

hence

\[
\boxed{4abcq=a+p(b+q).}
\]

This is the symmetric master equation.

---

## 2. Hidden prime cofactor

Rearrange the master equation as

\[
a(4bcq-1)=p(b+q).
\]

Set

\[
D=4bcq-1.
\]

For positive `b,c,q`,

\[
4bcq-1>b+q.
\]

Indeed

\[
4bcq-1-(b+q)
\ge4bq-1-b-q>0.
\]

Because

\[
aD=p(b+q)
\]

and `p` is prime, `p` must divide `D`. Otherwise `gcd(D,p)=1` would force

\[
D\mid b+q,
\]

contradicting `D>b+q`.

Therefore there is a positive integer `s` such that

\[
\boxed{4bcq-1=ps.}
\]

Cancelling `p` in the master equation gives

\[
\boxed{b+q=as.}
\]

Thus every certificate has the exact dual form

\[
\boxed{
ps+1=4bcq,
\qquad
b+q=as.
}
\]

Since

\[
ps=4bcq-1\equiv3\pmod4
\]

and `p≡1 mod4`,

\[
\boxed{s\equiv3\pmod4.}
\]

Also `D>b+q` gives

\[
ps>as,
\]

so

\[
\boxed{a<p.}
\]

This is automatic; it need not be assumed for a sufficient certificate.

---

## 3. Automatic coprimalities

From

\[
ps+1=4bcq,
\]

no prime divisor of `p` or `s` can divide `b`, `c`, or `q`. Hence

\[
\boxed{
\gcd(ps,bcq)=1.
}
\]

In particular

\[
\gcd(p,b)=
\gcd(p,c)=
\gcd(p,q)=1
\]

and the same holds with `p` replaced by `s`.

---

## 4. Swap duality

The master equation is symmetric in `b` and `q`.

Define

\[
\boxed{k'=4acq-p.}
\]

Then

\[
k'b
=(4acq-p)b
=4abcq-bp
=a+pq.
\]

Thus

\[
\boxed{b\mid a+pq.}
\]

More precisely,

\[
\boxed{k'b=a+pq.}
\]

Also

\[
p+k'=4acq,
\]

so `k'` is a valid sufficient-certificate divisor for the swapped parameter pair `(a,q)`.

Therefore every certificate has a dual certificate

\[
\boxed{
(a,b;k,q)
\longleftrightarrow
(a,q;k',b).
}
\]

Both divisors satisfy

\[
k\equiv k'\equiv3\pmod4.
\]

---

## 5. Norm factorization

The two dual divisors multiply to

\[
\boxed{
kk'=p^2+4a^2c.
}
\]

Proof:

\[
\begin{aligned}
kk'
&=(4abc-p)(4acq-p)\\
&=16a^2b c^2q-4acp(b+q)+p^2.
\end{aligned}
\]

Using

\[
4abcq=a+p(b+q),
\]

we have

\[
16a^2bc^2q
=4ac(a+p(b+q)),
\]

which cancels the mixed term and leaves

\[
p^2+4a^2c.
\]

Thus every certificate factors the quadratic norm-like quantity

\[
\boxed{p^2+4a^2c}
\]

into two positive `3 mod4` factors.

This is the exact algebraic bridge to the repository's quadratic-field / norm machinery.

---

## 6. Reciprocity consequence on the hard-prime coprime-fab lane

Now assume additionally that the certificate lies in the coprime hard-prime `fab` lane where `FAB-HARD-NONRESIDUE-BRIDGE.md` proves

\[
\boxed{\left(\frac cp\right)=-1.}
\]

From

\[
ps+1=4bcq
\]

and the automatic coprimalities,

\[
\left(\frac bp\right)
\left(\frac cp\right)
\left(\frac qp\right)=1.
\]

Therefore

\[
\boxed{
\left(\frac bp\right)
\left(\frac qp\right)=-1.
}
\]

So exactly one of the symmetric side factors `b,q` carries the nonresidue sign modulo `p`.

### Odd-c dual nonresidue

If `c` is odd, then the same `c` is also a Jacobi nonresidue modulo the hidden cofactor `s`:

\[
\boxed{\left(\frac cs\right)=-1.}
\]

Indeed, from

\[
ps\equiv-1\pmod c
\]

we get

\[
\left(\frac pc\right)
\left(\frac sc\right)
=
\left(\frac{-1}{c}\right).
\]

Because `p≡1 mod4`, reciprocity gives

\[
\left(\frac pc\right)
=
\left(\frac cp\right)
=-1.
\]

Hence

\[
\left(\frac sc\right)
=-\left(\frac{-1}{c}\right).
\]

Since `s≡3 mod4`, quadratic reciprocity between `s` and odd `c` contributes exactly the factor `(-1/c)`, giving

\[
\left(\frac cs\right)=-1.
\]

Thus the external nonresidue factor is not attached only to the original prime `p`; it propagates across the dual system to the new `3 mod4` cofactor `s`.

---

## 7. Current descent target

The exact certificate geometry can now be written as

\[
\boxed{
\begin{array}{rcl}
4abcq&=&a+p(b+q),\\
ps+1&=&4bcq,\\
b+q&=&as,\\
k&=&4abc-p,\\
k'&=&4acq-p,\\
kk'&=&p^2+4a^2c.
\end{array}
}
\]

with

\[
p\equiv1\pmod4,
\qquad
s,k,k'\equiv3\pmod4.
\]

On the hard coprime-fab lane, `c` is a nonresidue modulo both `p` and, for odd `c`, `s`.

The next proof target is an actual descent/closure theorem on this dual system, not another large exact-depth scan. A successful route would show that a hypothetical all-prime failure cannot remain closed under the `(b,q)` duality and the `(p,s)` reciprocity transfer.
