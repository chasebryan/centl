# Mirror character obstruction for fixed-k fab rescue

**Status:** proved universal theorem on the Mordell-hard prime lane  
**Date:** 2026-08-15  
**Depends on:** `FAB-UNBOUNDED-DIVISOR-RATIO-CERTIFICATE.md`, `FAB-HARD-NONRESIDUE-BRIDGE.md`  
**Claim boundary:** this rules out a broad class of tempting fixed-k constructions. It does not by itself prove that a rescue always exists and therefore does not prove Erdős-Straus.

---

## 1. Setup

Let `p` be a Mordell-hard prime. In particular

\[
p\equiv1\pmod8.
\]

Let `C>0` satisfy

\[
\gcd(C,p)=1
\]

and put

\[
\boxed{k=4C-p.}
\]

Assume `k>1`. Then

\[
\boxed{k\equiv3\pmod4}
\]

and

\[
\gcd(C,k)=1.
\]

The fixed-k divisor-square theorem says that this `k` supplies a sufficient fab certificate exactly when there is a divisor

\[
u\mid C^2
\]

such that

\[
\boxed{4u\equiv-1\pmod k.}
\]

We now show that a `C` assembled entirely from quadratic residues modulo `p` can never do this.

---

## 2. Reciprocity transfer lemma

### Lemma

For every odd prime `r|C`,

\[
\boxed{\left(\frac r k\right)=\left(\frac r p\right),}
\]

where the left symbol is Jacobi when `k` is composite.

### Proof

Because `r|C`,

\[
k=4C-p\equiv-p\pmod r.
\]

Since `k\equiv3 mod4`, quadratic reciprocity gives

\[
\left(\frac r k\right)
=
\left(\frac{-1}{r}\right)
\left(\frac k r\right).
\]

But

\[
\left(\frac k r\right)
=
\left(\frac{-p}{r}\right)
=
\left(\frac{-1}{r}\right)
\left(\frac p r\right).
\]

The two `(-1/r)` factors cancel, so

\[
\left(\frac r k\right)=\left(\frac p r\right).
\]

Finally `p\equiv1 mod4`, hence reciprocity between `p` and `r` contributes no sign:

\[
\left(\frac p r\right)=\left(\frac r p\right).
\]

QED.

### The factor 2

If `2|C`, then `C` is even and

\[
k=4C-p\equiv-p\equiv7\pmod8.
\]

Therefore

\[
\left(\frac2k\right)=+1.
\]

On the hard-prime lane `p\equiv1 mod8`, so also

\[
\left(\frac2p\right)=+1.
\]

Thus the same residue sign is preserved for the dyadic factor as well.

---

## 3. Mirror obstruction theorem

### Theorem

Assume every prime factor `r` of `C` is a quadratic residue modulo `p`:

\[
\boxed{
 r\mid C\Longrightarrow
 \left(\frac r p\right)=+1.
}
\]

Then there is **no** divisor `u|C^2` satisfying

\[
4u\equiv-1\pmod k,
\qquad k=4C-p>1.
\]

Consequently this `k` cannot supply a fixed-k sufficient fab certificate.

### Proof

By the reciprocity-transfer lemma, every prime divisor of `C` is also Jacobi-positive modulo `k`. Hence every divisor

\[
u\mid C^2
\]

satisfies

\[
\boxed{\left(\frac u k\right)=+1.}
\]

If instead

\[
4u\equiv-1\pmod k,
\]

then, since `4` is a square modulo odd `k`,

\[
\left(\frac u k\right)
=
\left(\frac{-4^{-1}}k\right)
=
\left(\frac{-1}k\right).
\]

But `k\equiv3 mod4`, so

\[
\boxed{\left(\frac{-1}k\right)=-1.}
\]

This contradicts `(u/k)=+1`. Therefore no such divisor exists. QED.

---

## 4. Structural interpretation

The theorem says that the fixed-k rescue mechanism cannot be obtained by simply taking a nearby integer `C` whose complete prime support has already been forced onto the quadratic-residue side of `p`, and then reflecting it through

\[
\boxed{k=4C-p.}
\]

That construction preserves the residue sign of every prime factor of `C`, while the fixed-k target

\[
-4^{-1}\pmod k
\]

is Jacobi-negative.

Thus any successful interior divisor-square rescue must import genuine nonresidue support:

\[
\boxed{
\exists r\mid C:
\left(\frac r p\right)=-1.
}
\]

This is the fixed-k mirror of the external-nonresidue theorem in `FAB-HARD-NONRESIDUE-BRIDGE.md`.

---

## 5. Exact corollaries for the current counterexample sieve

The theorem kills several seductive but structurally impossible one-line constructions.

### Corollary A — mirror of the `p+1` spine

Let

\[
C=\frac{p+1}{2},
\qquad
k=p+2.
\]

If the simplest `p+1` filter has failed, every odd prime factor of `C` is `1 mod4`; hence every such factor is a quadratic residue modulo hard `p`. The factor `2`, when present, is also a residue because `p\equiv1 mod8`.

Therefore the reflected choice

\[
\boxed{k=p+2}
\]

cannot rescue a hard-prime survivor through the fixed-k divisor-square criterion.

### Corollary B — mirror of the Eisenstein neighbour

Let

\[
A=\frac{p+3}{4}.
\]

If the exact `k=3` filter has failed, every prime factor of `A` is `1 mod3`. For hard `p`, reciprocity gives those factors quadratic-residue sign relative to the corresponding mirror construction. Hence taking a fixed-k construction obtained merely by reflecting this already-residue-safe support cannot supply the missing nonresidue target.

The same principle applies to the other shifted-factor filters whenever their failure theorem has already forced every prime divisor of the chosen `C` to be a quadratic residue modulo `p`.

---

## 6. Research consequence

This theorem prunes an entire family of false proof strategies.

The next successful construction must **not** be a mirror of an already-safe shifted factor. It must deliberately incorporate a prime or factor carrying

\[
\boxed{\left(\frac r p\right)=-1.}
\]

For Mordell-hard primes the small shield gives

\[
\left(\frac2p\right)
=
\left(\frac3p\right)
=
\left(\frac5p\right)
=
\left(\frac7p\right)=+1,
\]

so the first possible genuinely new prime support begins at the external boundary

\[
\boxed{11,13,17,\ldots}
\]

depending on `p`.

This explains why the one-shot search should now construct `k` **from external nonresidue data**, rather than reflect any of the already-proved residue-safe neighbouring forms.
