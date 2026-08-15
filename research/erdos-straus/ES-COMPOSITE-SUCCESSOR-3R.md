# Composite successor `3r`: parity-constrained signed-box theorem

**Status:** proved exact local reduction and index-two classification  
**Date:** 2026-08-15  
**Depends on:** `ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md`, `FAB-TWO-TARGET-KNESER.md`, `FAB-INDEX6-COMBINED-DEFECT.md`, `FAB-HARD-FIRST-FILTERS.md`  
**Claim boundary:** this treats the natural composite successor when the forced external-nonresidue prime has residue `1 mod 4`. It does not prove that the successor shift must hit a target and therefore does not prove Erdős--Straus.

---

## 1. Why `3r` is the natural successor

Let `p` be a Mordell-hard prime. Then

\[
\boxed{p\equiv1\pmod{12}.}
\]

Let `r<p` be an external quadratic-nonresidue prime for `p` with

\[
\boxed{r\equiv1\pmod4,
\qquad
\left(\frac rp\right)=-1.}
\]

The prime shift `k=r` is not admissible in the two-target formulation because it is `1 mod 4`.

Multiply by the hard-residue prime `3` and put

\[
\boxed{k=3r.}
\]

Then

\[
k\equiv3\pmod4,
\qquad
\gcd(k,p)=1.
\]

Set

\[
\boxed{C=\frac{p+3r}{4}.}
\]

Because `p≡1 mod3`,

\[
\boxed{C\equiv1\pmod3,}
\]

and because `r\ne p`,

\[
\boxed{\gcd(C,3r)=1.}
\]

Thus the exact two-target signed box is defined at the composite shift `3r`.

---

## 2. CRT split of the signed box

Factor

\[
C=\prod_i s_i^{e_i}.
\]

CRT gives

\[
\boxed{
(\mathbb Z/3r\mathbb Z)^\times
\cong
(\mathbb Z/3\mathbb Z)^\times
\times
(\mathbb Z/r\mathbb Z)^\times.}
\]

The first factor has order two. For every prime divisor `s_i` of `C`, define

\[
\boxed{
\epsilon_i=
\begin{cases}
+1,&s_i\equiv1\pmod3,\\
-1,&s_i\equiv2\pmod3.
\end{cases}}
\]

For a signed exponent vector

\[
z=(z_i),
\qquad
-e_i\le z_i\le e_i,
\]

the mod-`3` coordinate of the corresponding signed divisor is

\[
\boxed{\epsilon(z)=\prod_i\epsilon_i^{z_i}\in\{+1,-1\}.}
\]

Define the two parity fibres projected to the prime modulus `r`:

\[
\boxed{
\mathcal R_{r}^{\pm}(C)
=
\left\{
\prod_i s_i^{z_i}\pmod r:
-e_i\le z_i\le e_i,
\quad
\epsilon(z)=\pm1
\right\}.}
\]

The full signed box modulo `3r` is exactly the CRT union of these two fibres.

---

## 3. All three natural targets lie in the negative parity fibre

The exact two-target theorem uses

\[
\tau_I=-p^{-1},
\qquad
\tau_{II}=-1,
\]

and inversion symmetry adds

\[
\tau_I^{-1}=-p.
\]

Since `p≡1 mod3`, all three satisfy

\[
\boxed{
-p^{-1}\equiv-p\equiv-1\equiv-1\pmod3.}
\]

Therefore target membership modulo `3r` reduces exactly to the negative parity fibre modulo `r`:

\[
\boxed{
-p^{-1}\in\mathcal R_{3r}(C)
\iff
-p^{-1}\pmod r\in\mathcal R_r^{-}(C),}
\]

\[
\boxed{
-1\in\mathcal R_{3r}(C)
\iff
-1\pmod r\in\mathcal R_r^{-}(C).}
\]

By inversion symmetry the same holds for `-p`.

### Theorem — exact composite-successor fibre criterion

The shift `k=3r` produces an Erdős--Straus certificate if and only if

\[
\boxed{
\mathcal R_r^{-}(C)
\cap
\{-p^{-1},-1\}
\ne\varnothing,
\qquad
C=\frac{p+3r}{4}.}
\]

Thus the composite modulus introduces only **one binary parity constraint** beyond a prime-modulus signed divisor problem.

---

## 4. The empty-fibre obstruction is exactly Eisenstein splitting

The negative fibre is empty precisely when no signed exponent vector has odd mod-`3` parity.

If every prime factor of `C` is `1 mod 3`, then every `epsilon_i=+1`, so

\[
\boxed{\mathcal R_r^{-}(C)=\varnothing.}
\]

Conversely, if some prime factor

\[
s\mid C
\]

satisfies

\[
s\equiv2\pmod3,
\]

then choosing exponent `z_s=1` and all other exponents zero gives a negative-parity element. Hence

\[
\boxed{
\mathcal R_r^{-}(C)=\varnothing
\iff
\text{every prime factor of }C\text{ is }1\pmod3.}
\]

So the first obstruction at the composite successor is exactly another simultaneous-splitting condition in the Eisenstein direction already visible in `FAB-HARD-FIRST-FILTERS.md`.

---

## 5. Target character positions modulo r

Because both `p` and `r` are `1 mod 4`, quadratic reciprocity gives

\[
\left(\frac pr\right)
=
\left(\frac rp\right)
=-1.
\]

Also

\[
\left(\frac{-1}{r}\right)=+1.
\]

Therefore, modulo `r`,

\[
\boxed{
\left(\frac{-p^{-1}}r\right)=-1,
\qquad
\left(\frac{-p}r\right)=-1,
\qquad
\left(\frac{-1}r\right)=+1.}
\]

So the two Type-I orientations and Type II still occupy opposite quadratic sides, but the roles are reversed from the `q≡3 mod4` prime-shift case.

---

## 6. Odd stabilizer index still cannot support failure

Let

\[
\widetilde G=(\mathbb Z/3r\mathbb Z)^\times
\]

and let

\[
H=\operatorname{Stab}(\mathcal R_{3r}(C)).
\]

If

\[
[\widetilde G:H]
\]

is odd, then the quotient `\widetilde G/H` has odd order. Every element of order two in `\widetilde G` must therefore map to the identity.

In particular the element `-1 mod 3r` lies in `H`.

Since the signed box contains `1` and is `H`-periodic,

\[
H\subseteq\mathcal R_{3r}(C).
\]

Hence

\[
-1\in\mathcal R_{3r}(C),
\]

which is a Type-II hit.

Therefore:

\[
\boxed{
\text{combined failure at }3r
\Longrightarrow
[\widetilde G:H]\text{ is even}.}
\]

The odd-index collapse is not a prime-modulus accident.

---

## 7. Exact index-two classification

Assume now

\[
\boxed{[\widetilde G:H]=2}
\]

and that both exact targets are missed.

Because

\[
\widetilde G
\cong C_2\times(\mathbb Z/r\mathbb Z)^\times
\]

with the second factor cyclic of even order, there are exactly three nontrivial quadratic characters on `\widetilde G`:

1. the mod-`3` parity character `epsilon`;
2. the Legendre character `eta=(\cdot/r)`;
3. their product `epsilon eta`.

Thus the three index-two subgroups are the kernels of these characters.

The target signatures are

\[
\boxed{
\begin{array}{c|ccc}
 & \epsilon & \eta & \epsilon\eta\\
\hline
-p^{-1} & -1 & -1 & +1\\
-p      & -1 & -1 & +1\\
-1      & -1 & +1 & -1
\end{array}}
\]

because `p≡1 mod3`, `(p/r)=-1`, and `(-1/r)=+1`.

### Case 1: H = ker eta

Then `-1` has `eta=+1`, so

\[
-1\in H\subseteq\mathcal R_{3r}(C),
\]

a Type-II hit. Impossible.

### Case 2: H = ker(epsilon eta)

Then `-p^{-1}` has `epsilon eta=+1`, so

\[
-p^{-1}\in H\subseteq\mathcal R_{3r}(C),
\]

a Type-I hit. Impossible.

### Case 3: H = ker epsilon

This is the only index-two subgroup that contains neither solution target.

But if any prime factor `s|C` satisfies

\[
s\equiv2\pmod3,
\]

then the signed box contains the element represented by exponent `z_s=1`, which lies outside `H=ker epsilon`.

Since the box is `H`-periodic, contains `H`, and `H` has index two, one element outside `H` forces

\[
\mathcal R_{3r}(C)=\widetilde G,
\]

contradicting target failure.

Therefore every prime factor of `C` must be `1 mod3`.

### Theorem — index-two successor defect is pure Eisenstein splitting

If the composite successor shift `k=3r` misses both exact targets and its signed box has stabilizer index two, then necessarily

\[
\boxed{
H=\ker\epsilon
}
\]

and

\[
\boxed{
\text{every prime factor of }
\frac{p+3r}{4}
\text{ is }1\pmod3.}
\]

Equivalently, the entire negative parity fibre is empty.

Thus **every non-Eisenstein-split composite successor automatically eliminates the index-two defect**.

---

## 8. New successor dichotomy

For a forced external-nonresidue successor `r≡1 mod4`, the natural admissible shift `3r` therefore has a clean first dichotomy:

### Split obstruction

If

\[
\frac{p+3r}{4}
\]

is composed entirely of primes `1 mod3`, then the negative target fibre is empty and the shift cannot solve `p`.

### Non-split regime

If the shifted integer has even one prime factor `2 mod3`, then the negative fibre is nonempty and **stabilizer index two is impossible**. Any combined failure must move to a finer even quotient.

This is the composite analogue of the earlier prime-shift Kneser collapse.

---

## 9. Next theorem target

The forced-successor problem has now split into two precise cases:

1. eliminate or descend through the Eisenstein-split condition
   \[
   \operatorname{supp}\left(\frac{p+3r}{4}\right)\subseteq\{\ell:\ell\equiv1\pmod3\};
   \]
2. in the non-split case, classify the first possible even stabilizer defect above index two inside
   \[
   (\mathbb Z/3r\mathbb Z)^\times,
   \]
   using the same three-target symmetry and Kneser expansion.

The important reduction is that a `1 mod4` successor no longer requires a general composite-modulus search. It is a **prime-r divisor-placement problem with one parity bit**.
