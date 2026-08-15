# External-nonresidue shield certificates carry a synchronized nonresidue triple

**Status:** proved universal theorem for shield-supported strong certificates  
**Date:** 2026-08-15  
**Depends on:** `EXTERNAL-NR-M1-SYNCHRONIZATION.md`, `FAB-HARD-NONRESIDUE-BRIDGE.md`, `FAB-DUAL-DESCENT-SYSTEM.md`  
**Claim boundary:** this proves a character conservation law inside every shield-supported certificate. It does not prove that such a certificate exists for every hard prime and therefore does not prove Erdős-Straus.

---

## 1. Setup

Let `p` be Mordell-hard. Let `A,B` be coprime positive integers supported only on

\[
\{2,3,5,7\}.
\]

Suppose an odd prime `ell` gives a shield-supported strong certificate:

\[
\boxed{\ell\mid pA+B}
\]

and

\[
\boxed{4AB\mid p+\ell.}
\]

Write

\[
\boxed{\ell q=pA+B}
\]

and

\[
\boxed{p+\ell=4ABc}
\]

with positive integers `q,c`.

Because the hard classes satisfy

\[
\left(\frac2p\right)
=\left(\frac3p\right)
=\left(\frac5p\right)
=\left(\frac7p\right)=+1,
\]

every shield-supported integer has quadratic character `+1` modulo `p` after removing square factors.

---

## 2. The overlap defect has the same sign as ell

Reduce

\[
p+\ell=4ABc
\]

modulo `p`:

\[
\ell\equiv4ABc\pmod p.
\]

The factor `4AB` is quadratic-residue-side modulo `p`. Hence

\[
\boxed{
\left(\frac\ell p\right)
=
\left(\frac c p\right).
}
\]

Thus an external `ell` forces the overlap defect `c` to be external as well.

This recovers the hard-nonresidue bridge directly in the shield-supported lane.

---

## 3. The complementary cofactor has the same sign as ell

Reduce

\[
\ell q=pA+B
\]

modulo `p`:

\[
\ell q\equiv B\pmod p.
\]

Since `B` is shield-supported,

\[
\left(\frac Bp\right)=+1.
\]

Therefore

\[
\left(\frac\ell p\right)
\left(\frac q p\right)=+1.
\]

Every nonzero quadratic character is its own inverse, so

\[
\boxed{
\left(\frac q p\right)
=
\left(\frac\ell p\right).
}
\]

Here `(q/p)` is the Jacobi symbol, equivalently the product of prime-factor Legendre symbols with valuation parity.

---

## 4. Triple conservation theorem

Combining the two identities gives

\[
\boxed{
\left(\frac\ell p\right)
=
\left(\frac q p\right)
=
\left(\frac c p\right).
}
\]

Hence if the chosen certificate modulus is external,

\[
\boxed{
\left(\frac\ell p\right)=-1,
}
\]

then automatically

\[
\boxed{
\left(\frac q p\right)
=
\left(\frac c p\right)=-1.
}
\]

So every external shield-supported certificate carries a synchronized **nonresidue triple**

\[
\boxed{(\ell,q,c)}.
\]

In particular `q` contains an odd valuation contribution from at least one prime that is external to `p`.

---

## 5. Relation to the dual descent system

In the master variables of `FAB-DUAL-DESCENT-SYSTEM.md`, take

\[
a=B,
\qquad b=A.
\]

The certificate identities become

\[
4ABcq=B+p(A+q),
\]

and the hidden `3 mod 4` cofactor `d` is defined by

\[
\boxed{A+q=Bd.}
\]

Then

\[
\boxed{pd+1=4Acq.}
\]

The new theorem says that the two factors `c` and `q` on the right already carry the same external sign modulo `p` as `ell`.

Thus the external-prime lane and the dual-descent lane are not separate mechanisms. The shield certificate automatically feeds external nonresidue content into the dual factorization.

When `c` is odd, the existing dual theorem further gives

\[
\boxed{\left(\frac c d\right)=-1.}
\]

So the same defect `c` is a nonresidue simultaneously across the original hard prime and the hidden dual cofactor.

---

## 6. Research consequence

The cap-free shield-ratio target should no longer be viewed as

> find one lucky external prime.

A successful hit creates a rigid packet

\[
\boxed{
\ell q=pA+B,
\qquad
p+\ell=4ABc,
\qquad
A+q=Bd,
\qquad
pd+1=4Acq,
}
\]

with synchronized nonresidue data.

This suggests an actual descent target:

1. assume a hard prime has no shield-supported external certificate;
2. study the external prime factors forced into the complementary cofactors of the linear forms `pA+B`;
3. show that avoiding the target residue at every external factor would force a closed nonresidue packet under the `(p,d)` dual transfer;
4. rule out such a closed packet by size, parity, or a finite character quotient.

The theorem proved here supplies the conservation law needed for that program. The closure step remains open.
