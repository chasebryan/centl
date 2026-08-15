# Cubic-surface form of the gcd-square rescue

**Status:** proved exact reformulation and square obstruction  
**Date:** 2026-08-15  
**Depends on:** `FAB-GCD-SQUARE-CRITERION.md`  
**Claim boundary:** this sharpens the exact rescue target. It does not prove universal existence and therefore does not prove Erdős–Straus.

## 1. Replace the two `3 mod 4` integers by depth coordinates

Write

\[
\boxed{k=4u-1,\qquad d=4v-1}
\]

with `u,v>=1`.

Then

\[
kd-1
=(4u-1)(4v-1)-1
=4(4uv-u-v).
\]

Define

\[
\boxed{w=4uv-u-v.}
\]

For a prime `p≡1 mod4`, also define

\[
\boxed{A_u=\frac{p+4u-1}{4}.}
\]

Then

\[
p+k=4A_u,
\qquad
M=kd-1=4w.
\]

Hence

\[
G=\gcd(p+k,M)
=4\gcd(A_u,w).
\]

The gcd-square criterion

\[
4M\mid G^2
\]

therefore becomes exactly

\[
\boxed{
w\mid\gcd(A_u,w)^2.}
\]

---

## 2. Square-root closure

For a positive integer

\[
w=\prod_\ell \ell^{e_\ell},
\]

define its least square-root closure

\[
\boxed{
\operatorname{src}(w)
:=\prod_\ell \ell^{\lceil e_\ell/2\rceil}.
}
\]

This is the least positive integer `h` such that

\[
w\mid h^2.
\]

Then

\[
w\mid\gcd(A_u,w)^2
\iff
\boxed{\operatorname{src}(w)\mid A_u}.
\]

Thus:

### Surface rescue criterion

If there exist `u,v>=1` such that, with

\[
w=4uv-u-v,
\]

one has

\[
\boxed{
\operatorname{src}(w)
\mid
\frac{p+4u-1}{4},
}
\]

then `p` satisfies the Erdős–Straus equation.

This is exactly the gcd-square construction in the coordinates naturally attached to the shifted cubic surface.

---

## 3. Explicit recovered parameters

Put

\[
g=\gcd(A_u,w).
\]

When `w|g^2`, the parameters in `FAB-GCD-SQUARE-CRITERION.md` become

\[
\boxed{
a=\frac{A_u}{g},
\qquad
b=\frac{w}{g},
\qquad
c=\frac{g^2}{w}.}
\]

Thus the leftover `c` is precisely the square-overlap excess.

The auxiliary quotient is

\[
q
=\frac{(4v-1)p+1}{4g}.
\]

The resulting positive decomposition is

\[
\frac4p
=
\frac1{abc}
+
\frac1{aqc}
+
\frac1{bpqc}.
\]

---

## 4. The seductive perfect-square move is impossible

The strongest possible compression would be to make

\[
w=s^2,
\]

because then

\[
\operatorname{src}(w)=s.
\]

But this can never happen for positive `u,v`.

Indeed,

\[
(4u-1)(4v-1)
=4w+1.
\]

If `w=s^2`, then

\[
\boxed{(4u-1)(4v-1)=4s^2+1.}
\]

Every odd prime divisor `r` of `4s^2+1` satisfies

\[
(2s)^2\equiv-1\pmod r,
\]

so `-1` is a quadratic residue modulo `r`; hence

\[
\boxed{r\equiv1\pmod4.}
\]

Therefore every positive divisor of `4s^2+1` is `1 mod4`.

But both

\[
4u-1\equiv4v-1\equiv3\pmod4,
\]

contradiction.

Hence

\[
\boxed{4uv-u-v\text{ is never a perfect square}.}
\]

This is an exact structural obstruction, not a search observation.

---

## 5. The unavoidable defect is the useful object

Write schematically

\[
w=c s^2
\]

when the valuation pattern permits a square part `s^2` and a squarefree defect `c` (or use the squarefree kernel when exponents are not exactly `0/1 mod 2`).

Then the square-root closure contains the defect:

\[
\operatorname{src}(w)\supseteq c s.
\]

So the surface criterion can succeed only when the non-square defect is absorbed into `A_u`.

This aligns exactly with `FAB-HARD-NONRESIDUE-BRIDGE.md`: on a Mordell-hard prime, a genuine coprime fab certificate cannot have its leftover squareclass supported only on the hard quadratic-residue primes `2,3,5,7`; it must import an external quadratic nonresidue.

Thus the failed perfect-square idea is not wasted. It identifies the actual object that must be controlled:

\[
\boxed{
\text{square part of }w
\quad+\quad
\text{one unavoidable nonresidue defect}.
}
\]

The remaining theorem target is to force that square-root closure into `A_u` for some adaptive surface point `(u,v)`.

---

## 6. A useful infinite near-square subfamily

The congruence condition for `u^2 | w` has an exact polynomial family. Since

\[
w=v(4u-1)-u,
\]

requiring `u^2|w` gives

\[
v\equiv u(u-1)\pmod{u^2}.
\]

Taking the least positive representative

\[
\boxed{v=u(u-1)}
\]

yields

\[
\boxed{
w=u^2(4u-5).}
\]

More generally,

\[
\boxed{v=u(nu-1)}
\]

gives

\[
\boxed{
w=u^2\bigl(4nu-n-4\bigr).}
\]

These families isolate a large square automatically and expose a single linear defect. They are therefore natural theorem-mining families for the next stage, although no claim is made that they alone cover all hard primes.
