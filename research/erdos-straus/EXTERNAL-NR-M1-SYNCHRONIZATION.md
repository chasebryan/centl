# External-nonresidue m=1 character synchronization

**Status:** proved universal theorem  
**Date:** 2026-08-15  
**Depends on:** `FAB-UNBOUNDED-DIVISOR-RATIO-CERTIFICATE.md`, `FAB-HARD-NONRESIDUE-BRIDGE.md`  
**Claim boundary:** this removes the quadratic-character obstruction for the `m=1` external-prime lane and identifies the exact sign structure of the shifted factor. It does not prove the remaining divisor-ratio placement theorem and therefore does not prove Erdős–Straus.

---

## 1. Setup

Let `p` be a Mordell-hard prime. Hence

\[
p\equiv1\pmod8
\]

and

\[
\left(\frac2p\right)
=\left(\frac3p\right)
=\left(\frac5p\right)
=\left(\frac7p\right)=+1.
\]

Let `ell` be an odd prime satisfying

\[
\boxed{\ell\equiv3\pmod4}
\]

and assume `ell` is external to `p`:

\[
\boxed{\left(\frac\ell p\right)=-1.}
\]

Set

\[
\boxed{k=\ell},
\qquad
\boxed{C=\frac{p+\ell}{4}}.
\]

Since `p==1 mod4` and `ell==3 mod4`, `C` is an integer. Also

\[
\gcd(C,p\ell)=1.
\]

The fixed-k strong certificate theorem asks whether

\[
\exists u\mid C^2:
\qquad
4u\equiv-1\pmod\ell.
\]

Equivalently, in divisor-ratio form,

\[
\exists a,b\mid C:
\qquad
\boxed{\frac ba\equiv-p^{-1}\pmod\ell}.
\]

---

## 2. The whole shifted factor is a nonresidue on both sides

Modulo `p`,

\[
C\equiv \ell\,4^{-1}\pmod p.
\]

Since `4` is a square,

\[
\boxed{\left(\frac Cp\right)=\left(\frac\ell p\right)=-1.}
\]

Modulo `ell`,

\[
C\equiv p\,4^{-1}\pmod\ell,
\]

so

\[
\left(\frac C\ell\right)=\left(\frac p\ell\right).
\]

Because `p==1 mod4`, quadratic reciprocity gives

\[
\left(\frac p\ell\right)=\left(\frac\ell p\right)=-1.
\]

Therefore

\[
\boxed{
\left(\frac Cp\right)
=
\left(\frac C\ell\right)
=-1.
}
\]

Thus the shifted factor automatically contains an odd total amount of external nonresidue support. No separate search is needed to manufacture the missing quadratic sign.

---

## 3. Prime-by-prime synchronization

### Theorem

For every odd prime `q|C`,

\[
\boxed{
\left(\frac qp\right)
=
\left(\frac q\ell\right).
}
\]

### Proof

Since `q|C`,

\[
p+\ell\equiv0\pmod q,
\]

hence

\[
p\equiv-\ell\pmod q.
\]

Because `p==1 mod4`, reciprocity between `p` and `q` contributes no sign:

\[
\left(\frac qp\right)=\left(\frac pq\right).
\]

Thus

\[
\left(\frac qp\right)
=
\left(\frac{-\ell}{q}\right)
=
\left(\frac{-1}{q}\right)
\left(\frac\ell q\right).
\]

Since `ell==3 mod4`, reciprocity between `ell` and `q` gives

\[
\left(\frac\ell q\right)
=
\left(\frac{-1}{q}\right)
\left(\frac q\ell\right).
\]

The two `(-1/q)` factors cancel, yielding

\[
\boxed{
\left(\frac qp\right)
=
\left(\frac q\ell\right).
}
\]

QED.

### Dyadic factor

If `2|C`, then

\[
p+\ell\equiv0\pmod8.
\]

Since hard `p==1 mod8`, necessarily

\[
\ell\equiv7\pmod8.
\]

Therefore

\[
\left(\frac2\ell\right)=+1
=\left(\frac2p\right).
\]

So the same synchronization statement holds for the prime `2` whenever it occurs in `C`.

---

## 4. Exact target sign

The divisor-ratio target is

\[
\boxed{T=-p^{-1}\pmod\ell.}
\]

Its Legendre symbol is

\[
\left(\frac T\ell\right)
=
\left(\frac{-1}{\ell}\right)
\left(\frac{p^{-1}}\ell\right).
\]

Because `ell==3 mod4`,

\[
\left(\frac{-1}{\ell}\right)=-1.
\]

And because

\[
\left(\frac p\ell\right)=-1,
\]

taking an inverse does not change the symbol:

\[
\left(\frac{p^{-1}}\ell\right)=-1.
\]

Hence

\[
\boxed{
\left(\frac T\ell\right)=+1.
}
\]

So the exact target lies in the quadratic-residue subgroup modulo `ell`.

This is the decisive sign separation:

\[
\boxed{
C\text{ is NQR mod }\ell,
\qquad
T=-p^{-1}\text{ is QR mod }\ell.
}
\]

The external prime supplies the required nonresidue content to `C`, while the final exact ratio must be assembled from an even amount of nonresidue support, or entirely from residue-side factors.

---

## 5. Hard-shield factors remain residue-side

Let

\[
q\in\{2,3,5,7\}
\]

and suppose `q|C`. Every such `q` is a quadratic residue modulo hard `p`.

By the synchronization theorem,

\[
\boxed{\left(\frac q\ell\right)=+1.}
\]

Therefore every signed ratio generated solely by the available powers of

\[
2,3,5,7
\]

inside `C` lies in the same quadratic-residue subgroup as the exact target `T`.

This explains structurally why the finite external-nonresidue probe is so often solved by tiny hard-shield ratios: those coordinates are automatically on the correct character side once they divide the constructed `C`.

It does **not** prove exact equality with `T`; the remaining problem is placement inside the quadratic-residue subgroup.

---

## 6. Strong m=1 theorem target

The `m=1` route is now reduced to the exact statement:

> For every Mordell-hard prime `p`, there exists a prime
> \[
> \ell\equiv3\pmod4,
> \qquad
> \left(\frac\ell p\right)=-1,
> \]
> such that, with
> \[
> C=\frac{p+\ell}{4},
> \]
> the signed divisor-ratio box
> \[
> \mathcal R_\ell(C)
> =
> \left\{
> \prod_{q\mid C}q^{z_q}\bmod\ell:
> -v_q(C)\le z_q\le v_q(C)
> \right\}
> \]
> contains
> \[
> \boxed{-p^{-1}\pmod\ell.}
> \]

All scalar quadratic-character obstructions to this target have already vanished.

The remaining wall is **exact multiplicative placement**, not sign existence.

---

## 7. Shield-only sharpened target

Finite theorem-mining suggests a still narrower statement may suffice. Define the available hard-shield ratio box

\[
\boxed{
\mathcal H_\ell(C)
=
\left\{
2^{z_2}3^{z_3}5^{z_5}7^{z_7}\bmod\ell:
-v_q(C)\le z_q\le v_q(C)
\right\},
}
\]

where missing primes have exponent range `{0}`.

A successful shield-only certificate is exactly

\[
\boxed{-p^{-1}\in\mathcal H_\ell(C).}
\]

Equivalently, there are coprime `210`-smooth integers `A,B` with

\[
AB\mid C
\]

such that

\[
\boxed{\ell\mid pA+B.}
\]

Indeed the ratio condition `A/B == -p^{-1} (mod ell)` is precisely `pA+B == 0 (mod ell)`.

This is now the most compressed candidate theorem emerging from the finite data:

\[
\boxed{
\text{external }\ell\text{ supplies the nonresidue modulus/sign}
\quad+\quad
\{2,3,5,7\}\text{ supplies the exact ratio}.
}
\]

No universal existence claim is made here until the shield-only theorem is proved.
