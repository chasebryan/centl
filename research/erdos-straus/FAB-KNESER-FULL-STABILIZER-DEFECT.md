# Full-stabilizer compression of FAB Kneser defects

**Status:** proved universal strengthening of `FAB-KNESER-DIVISOR-DEFECT.md`  
**Date:** 2026-08-15  
**Depends on:** `FAB-KNESER-DIVISOR-DEFECT.md`  
**Claim boundary:** compresses every failed fixed-k FAB product box once its full stabilizer is taken. It does not prove that some auxiliary k must always succeed and therefore does not prove Erdős-Straus.

---

## 1. Setup

Let

\[
C=\frac{p+k}{4}=\prod_i r_i^{e_i}
\]

and let

\[
R=\prod_i
\{r_i^{-e_i},\ldots,r_i^{-1},1,r_i,\ldots,r_i^{e_i}\}
\subseteq G_k=(\mathbb Z/k\mathbb Z)^\times
\]

be the fixed-k signed divisor box.

Assume its exact FAB target is missed.

Let

\[
\boxed{H=\operatorname{Stab}(R)}
\]

be the **full** stabilizer, and put

\[
\bar G=G_k/H,
\qquad
n=|\bar G|=[G_k:H].
\]

Write

\[
\bar R=R/H.
\]

By construction,

\[
\boxed{\operatorname{Stab}_{\bar G}(\bar R)=\{1\}.}
\]

For each prime factor define

\[
d_i=\operatorname{ord}_{\bar G}(r_iH).
\]

---

## 2. No local factor may fill its projected subgroup

Suppose `r_i notin H`, so `d_i>1`.

Its local signed set in the quotient is

\[
\bar A_i
=\{(r_iH)^z:-e_i\le z\le e_i\}.
\]

If

\[
2e_i+1\ge d_i,
\]

then the consecutive exponent interval contains representatives of every residue modulo `d_i`. Therefore

\[
\boxed{\bar A_i=\langle r_iH\rangle.}
\]

But then

\[
\bar R
=\bar A_i\prod_{j\ne i}\bar A_j
\]

is invariant under multiplication by the nontrivial subgroup

\[
\langle r_iH\rangle.
\]

That contradicts the trivial stabilizer of `\bar R`.

Hence:

### Theorem — projected-order gap

For every prime-power factor outside the full stabilizer,

\[
\boxed{
\operatorname{ord}_{G_k/H}(r_iH)
>2e_i+1.
}
\]

Equivalently,

\[
\boxed{d_i\ge2e_i+2.}
\]

This conclusion uses the **exact** stabilizer, not merely the Kneser size inequality.

---

## 3. Universal exceptional-valuation bound

`FAB-KNESER-DIVISOR-DEFECT.md` proves the Kneser budget

\[
\sum_i
\left(
\min(2e_i+1,d_i)-1
\right)
\le n-2.
\]

For every `r_i notin H`, the projected-order theorem gives

\[
2e_i+1<d_i,
\]

so its contribution is exactly

\[
2e_i.
\]

For every `r_i in H`, the contribution is zero.

Therefore the entire Kneser budget collapses to

\[
\boxed{
2\sum_{r_i\notin H}e_i
\le n-2.
}
\]

Hence:

### Theorem — full-stabilizer defect mass

Every failed fixed-k FAB signed divisor box satisfies

\[
\boxed{
\sum_{
 r^e\parallel C,
 r\notin H
}e
\le
\left\lfloor\frac{[G_k:H]-2}{2}\right\rfloor.
}
\]

Thus the total prime-factor valuation visible outside the stabilizer is universally bounded by half the quotient size.

No primality assumption on the quotient index is needed.

---

## 4. Interpretation

Write

\[
C=C_H\,C_{\mathrm{exc}},
\]

where `C_H` contains all prime powers with residue class in `H`, and `C_exc` contains the rest.

Then every failed exact placement has two simultaneous properties:

### Large hidden background

All prime-power factors of `C_H` are invisible in the quotient defect.

### Tiny visible defect

The total valuation

\[
\Omega(C_{\mathrm{exc}})
=\sum_{r^e\parallel C_{\mathrm{exc}}}e
\]

satisfies

\[
\boxed{
\Omega(C_{\mathrm{exc}})
\le\left\lfloor\frac{n-2}{2}\right\rfloor.
}
\]

Moreover every exceptional prime has projected order strictly larger than twice its exponent plus one.

So a target miss is possible only when almost all shifted-factor mass collapses into one stabilizer subgroup and the visible quotient is supported by a short list of high-order atoms.

---

## 5. Recovery of earlier classifications

### Index 3

The mass bound gives

\[
\Omega(C_{\mathrm{exc}})\le0,
\]

so every factor lies in `H`.

### Index 5

\[
\Omega(C_{\mathrm{exc}})\le1.
\]

Thus there is at most one simple exceptional factor.

### Index 6

\[
\Omega(C_{\mathrm{exc}})\le2.
\]

The projected-order gap excludes quotient orders `2` and `3` for every exceptional factor. Only order `6` remains. The external-nonresidue parity then reduces the possibilities further to the unique-simple-defect theorem in `FAB-KNESER-INDEX6-CLASSIFICATION.md`.

### Index 10

\[
\boxed{\Omega(C_{\mathrm{exc}})\le4.}
\]

Every exceptional factor must have quotient order exceeding `2e+1`. In the cyclic order-ten quotient this immediately excludes:

- all order-two projections;
- order-five projections of exponent at least two;
- order-ten projections of exponent at least five.

This sharply reduces the next mixed classification before any case analysis begins.

---

## 6. Contrapositive expansion criterion

For any candidate subgroup `H<=G_k`, if the prime factorization of `C=(p+k)/4` has too much valuation outside `H`, namely

\[
\boxed{
2\sum_{r^e\parallel C,\ r\notin H}e
>[G_k:H]-2,
}
\]

then `H` cannot be the full stabilizer of a failed divisor box.

Likewise, if any factor outside `H` has

\[
\operatorname{ord}_{G_k/H}(rH)\le2e+1,
\]

then `H` cannot be the full defect stabilizer.

Thus a proof can eliminate candidate defect subgroups using only:

1. quotient orders of the actual shifted prime factors;
2. their valuations.

No exhaustive enumeration of all signed divisors is required.

---

## 7. Entropy-or-descent formulation

At an external-nonresidue factor-cycle vertex, the same shifted integer carries both:

- a guaranteed external nonresidue factor for the descent edge;
- a hypothetical Kneser defect subgroup if exact placement fails.

The full-stabilizer theorem says that the failure subgroup must hide almost all factor valuation, leaving only a bounded collection of high-order visible atoms.

Therefore the universal program can be stated more sharply as:

\[
\boxed{
\text{either shifted-factor residue entropy escapes every proper stabilizer,}
\quad\text{or the factor cycle transports a tiny high-order defect.}
}
\]

The remaining all-prime task is to prove that such a tiny high-order defect cannot persist around every external-nonresidue cycle.
