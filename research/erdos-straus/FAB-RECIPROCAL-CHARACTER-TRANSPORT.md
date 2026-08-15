# Quadratic-character transport in the forward and reciprocal fab lanes

**Status:** proved exact theorem  
**Date:** 2026-08-15  
**Depends on:** `FAB-RECIPROCAL-SIGNED-TARGET.md`  
**Claim boundary:** this is a structural character theorem. It does not prove that either lane succeeds universally.

## 1. Setup

Let `p` be a Mordell-hard prime. In particular

\[
\boxed{p\equiv1\pmod8.}
\]

Let `d` be an odd squarefree positive integer with

\[
\boxed{d\equiv3\pmod4,\qquad \gcd(p,d)=1.}
\]

Define the paired linear forms

\[
\boxed{
X_d=\frac{p+d}{4},
\qquad
Y_d=\frac{pd+1}{4}.
}
\]

Both are positive integers.

## 2. Odd prime factors of the forward form

Let `r` be an odd prime factor of `X_d`. Then

\[
p\equiv-d\pmod r.
\]

Therefore

\[
\left(\frac pr\right)
=\left(\frac{-d}{r}\right)
=\left(\frac{-1}{r}\right)\left(\frac d r\right).
\]

Because `d=3 mod4`, quadratic reciprocity for the Jacobi symbol gives

\[
\left(\frac d r\right)
=
\left(\frac r d\right)
\left(\frac{-1}{r}\right).
\]

The two sign factors cancel, so

\[
\left(\frac pr\right)=\left(\frac r d\right).
\]

Since `p=1 mod4`, reciprocity between `p` and `r` introduces no sign:

\[
\left(\frac pr\right)=\left(\frac r p\right).
\]

Hence

\[
\boxed{
\left(\frac r p\right)=\left(\frac r d\right)
}
\]

for every odd prime factor `r|X_d`.

## 3. Odd prime factors of the reciprocal form

Let `r` be an odd prime factor of `Y_d`. Then

\[
pd\equiv-1\pmod r.
\]

Taking quadratic characters gives

\[
\left(\frac pr\right)
\left(\frac d r\right)
=
\left(\frac{-1}{r}\right).
\]

Again

\[
\left(\frac d r\right)
=
\left(\frac r d\right)
\left(\frac{-1}{r}\right),
\]

so cancellation yields

\[
\left(\frac pr\right)
\left(\frac r d\right)=1.
\]

Every symbol here is `+1` or `-1`, hence

\[
\left(\frac pr\right)=\left(\frac r d\right).
\]

Using `p=1 mod4` once more,

\[
\boxed{
\left(\frac r p\right)=\left(\frac r d\right)
}
\]

for every odd prime factor `r|Y_d`.

## 4. The factor 2

If `2` divides either `X_d` or `Y_d`, then `d=7 mod8` because `p=1 mod8`.

The supplementary law gives

\[
\left(\frac2p\right)=+1,
\qquad
\left(\frac2d\right)=+1.
\]

Thus the same character equality holds for the factor `2` whenever it occurs.

## 5. Character-transport theorem

Combining the cases gives:

### Theorem

For a Mordell-hard prime `p` and odd squarefree `d=3 mod4`, every prime factor `r` of either paired form

\[
X_d=\frac{p+d}{4}
\qquad\text{or}\qquad
Y_d=\frac{pd+1}{4}
\]

satisfies

\[
\boxed{
\left(\frac r p\right)=\left(\frac r d\right).
}
\]

Thus both fab lanes transport the quadratic character of every moving prime factor from the chosen parameter `d` to the target prime `p`.

This is stronger than merely comparing the total Jacobi symbols of the two linear forms.

## 6. Total-character consequences

Because

\[
X_d\equiv p4^{-1}\pmod d,
\]

we have

\[
\boxed{
\left(\frac{X_d}{d}\right)=\left(\frac p d\right)=\left(\frac d p\right).
}
\]

Thus if `d` is a quadratic nonresidue of `p`, the forward form contains an odd total valuation contribution from prime factors that are nonresidues simultaneously modulo `d` and modulo `p`.

By contrast

\[
Y_d\equiv4^{-1}\pmod d,
\]

so

\[
\boxed{
\left(\frac{Y_d}{d}\right)=+1.
}
\]

The reciprocal form therefore contains an even total nonresidue contribution with respect to the same transported character.

This parity contrast is exactly what the signed targets see:

- the forward signed target is `-p`;
- the reciprocal signed target is `-1`.

## 7. The d=15 corollary

Take

\[
\boxed{d=15.}
\]

The unit group is

\[
(\mathbf Z/15\mathbf Z)^\times
=
\{1,2,4,7,8,11,13,14\}.
\]

The reciprocal base satisfies

\[
Y_{15}\equiv4\pmod{15},
\]

and the signed target is

\[
-1\equiv14\pmod{15}.
\]

The exact state automaton from `fab_signed_state_analyzer.py` has only three reciprocal failure states, whose signed-reach sets are

\[
\{1,4\},
\qquad
\{1,2,4,8\},
\qquad
\{1,4,7,13\}.
\]

The latter two are the character kernels

\[
\boxed{
H_{15}=\left\{r:\left(\frac r{15}\right)=+1\right\}
=\{1,2,4,8\},
}
\]

and

\[
\boxed{
H_3=\left\{r:\left(\frac r3\right)=+1\right\}
=\{1,4,7,13\}.
}
\]

Their intersection is `{1,4}`.

Therefore:

### Corollary — exact reciprocal m=15 failure

The reciprocal `m=15` lane fails **if and only if** the complete prime support of

\[
\boxed{Y_{15}=\frac{15p+1}{4}}
\]

is contained wholly in one of the two index-two subgroups

\[
\boxed{H_{15}}
\qquad\text{or}\qquad
\boxed{H_3}.
\]

Equivalently, failure means either

1. every prime factor `r|Y_15` satisfies
   \[
   \left(\frac r{15}\right)=+1,
   \]
   and by character transport also
   \[
   \left(\frac r p\right)=+1;
   \]

or

2. every prime factor of `Y_15` is `1 mod3`.

Unlike the reciprocal `m=7` classification, there is no isolated exceptional two-factor atom outside these character kernels.

## 8. Why this matters

The hard-prime obstruction is now being squeezed from two directions:

- `FAB-HARD-NONRESIDUE-BRIDGE.md` says a successful coprime certificate must import a genuine external nonresidue of `p`;
- the reciprocal `m=15` failure theorem says one entire failure branch contains **no p-nonresidue prime factor at all** in `Y_15`, while the other branch forces complete Eisenstein splitting modulo `3`.

This makes `m=15` a natural junction between the old small-prime shield and the new external-nonresidue program.
