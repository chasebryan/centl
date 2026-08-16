# Fixed-shift Jacobi parity law for the signed-box corridor

**Status:** proved corollary of the composite reciprocity-transfer theorem  
**Date:** 2026-08-16  
**Depends on:** `FAB-MIRROR-CHARACTER-OBSTRUCTION.md`, `ES-TWO-TARGET-DIVISOR-SQUARE.md`, `ES-INDEX-TWO-TWO-TARGET-PACKET.md`  
**Claim boundary:** this is a structural parity/character law for each admissible fixed shift. It does not prove that either exact target is attained and does not prove Erdős–Straus. The prime-factor reciprocity transfer used here was already proved in `FAB-MIRROR-CHARACTER-OBSTRUCTION.md`; the contribution here is the product-level corridor synthesis.

---

## 1. Setup

Let `p` be Mordell-hard and let

\[
\boxed{k\equiv3\pmod4}
\]

be odd with

\[
\gcd(k,p)=1.
\]

Put

\[
\boxed{C_k=\frac{p+k}{4}.}
\]

Then

\[
k=4C_k-p,
\]

so this is exactly the mirror setup of `FAB-MIRROR-CHARACTER-OBSTRUCTION.md`.

---

## 2. Prime-factor reciprocity, recalled

That theorem proves that for every odd prime

\[
q\mid C_k,
\]

one has

\[
\boxed{
\left(\frac qk\right)
=
\left(\frac qp\right),
}
\]

where the left symbol is Jacobi when `k` is composite.

If `2|C_k`, the same equality holds for `q=2` on the Mordell-hard lane:

\[
\boxed{
\left(\frac2k\right)
=
\left(\frac2p\right)=+1.
}
\]

Thus **every prime-factor occurrence of `C_k` has the same quadratic character sign relative to `k` and to `p`.**

---

## 3. Product-level identity

Multiply the prime-factor equalities with valuation.

Since the Jacobi and Legendre symbols are completely multiplicative in the numerator,

\[
\boxed{
\left(\frac{C_k}{k}\right)
=
\left(\frac{C_k}{p}\right).
}
\]

But modulo `p`,

\[
C_k\equiv4^{-1}k\pmod p.
\]

The factor `4^{-1}` is a square modulo `p`, so

\[
\left(\frac{C_k}{p}\right)
=
\left(\frac{k}{p}\right).
\]

Therefore

\[
\boxed{
\left(\frac{C_k}{k}\right)
=
\left(\frac{k}{p}\right).
}
\]

This is the fixed-shift Jacobi parity law.

---

## 4. External-nonresidue parity

Define

\[
E_k
=
\sum_{q^e\parallel C_k,\ (q/k)=-1}e.
\]

By the prime-factor transfer theorem the same factors are exactly the external quadratic nonresidues modulo `p`:

\[
\left(\frac qk\right)=-1
\iff
\left(\frac qp\right)=-1.
\]

Hence

\[
\left(\frac{C_k}{k}\right)=(-1)^{E_k}.
\]

Combining with Section 3 gives

\[
\boxed{
(-1)^{E_k}
=
\left(\frac{k}{p}\right).
}
\]

Equivalently,

\[
\boxed{
E_k\equiv
\frac{1-(k/p)}2
\pmod2.
}
\]

Thus:

- if `(k/p)=+1`, the shifted integer `C_k` contains an **even** total valuation of external nonresidue factors;
- if `(k/p)=-1`, it contains an **odd** total valuation.

This parity is forced before any factorization is performed.

---

## 5. Character of the two exact divisor targets

The exact divisor-square targets are

\[
\tau_I=-4^{-1}\pmod k,
\qquad
\tau_{II}=-C_k\pmod k.
\]

Because

\[
k\equiv3\pmod4,
\]

one has

\[
\left(\frac{-1}{k}\right)=-1.
\]

Since `4` is a square,

\[
\boxed{
\left(\frac{\tau_I}{k}\right)=-1.
}
\]

For Type II,

\[
\left(\frac{\tau_{II}}{k}\right)
=
-\left(\frac{C_k}{k}\right)
=
-\left(\frac{k}{p}\right).
\]

Therefore

\[
\boxed{
\left(\frac{\tau_{II}}{k}\right)
=-\left(\frac{k}{p}\right).
}
\]

The complete character picture is consequently

\[
\boxed{
\begin{array}{c|c|c|c}
(k/p)&E_k\bmod2&\tau_I&\tau_{II}\\
\hline
+1&0&\text{Jacobi }-1&\text{Jacobi }-1\\
-1&1&\text{Jacobi }-1&\text{Jacobi }+1
\end{array}
}
\]

This is exactly the even/odd split in `ES-INDEX-TWO-TWO-TARGET-PACKET.md`, now canonically tied to the Legendre symbol of the shift itself.

---

## 6. Immediate corridor examples

### `k=27`

Hard primes have

\[
\left(\frac3p\right)=+1,
\]

so

\[
\left(\frac{27}{p}\right)=+1.
\]

Hence `E_27` is even. The first non-pure packet has size two, exactly as in `K27-TWO-TARGET-FILTER.md`.

### `k=35`

Hard primes have

\[
\left(\frac5p\right)=
\left(\frac7p\right)=+1,
\]

so

\[
\left(\frac{35}{p}\right)=+1.
\]

Again `E_35` is even, recovering the parity theorem in `K35-TWO-TARGET-STRUCTURE.md`.

### `k=39`

Since

\[
\left(\frac3p\right)=+1,
\]

one gets

\[
\boxed{
\left(\frac{39}{p}\right)
=
\left(\frac{13}{p}\right).
}
\]

Therefore the `k=39` packet parity is controlled entirely by whether `13` is an external nonresidue of `p`:

- `(13/p)=+1` gives the even-packet branch;
- `(13/p)=-1` gives the odd-packet branch.

This explains the two distinct geometries seen in the exact finite residual without introducing a modulus-specific character by hand.

---

## 7. Research consequence

For a hypothetical counterexample, every admissible shift is now assigned a forced packet parity by the Legendre sequence

\[
\boxed{
\left(\frac{3}{p}\right),
\left(\frac{7}{p}\right),
\left(\frac{11}{p}\right),
\left(\frac{15}{p}\right),
\ldots
}
\]

or equivalently by

\[
\boxed{
\left(\frac{k}{p}\right),
\qquad k\equiv3\pmod4.
}
\]

The local fixed-shift problem is therefore not an arbitrary sequence of factorizations. It is a sequence of external-nonresidue packets whose parity is prescribed globally by one quadratic character modulo `p`.

Combined with the index-two packet lemma, the remaining global proof target becomes:

> show that the Legendre-prescribed packet sequence cannot keep every kernel divisor set thin enough to miss both exact targets for all admissible shifts.

That is a sharper cross-shift formulation than searching for a universal finite shift ceiling.

---

Erdős–Straus remains open. This is a parity/character synthesis, not the missing global expansion theorem.
