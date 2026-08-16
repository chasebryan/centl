# Exact structural reduction at the composite shift `k=35`

**Status:** proved structural reduction; full combined-miss classification still open  
**Date:** 2026-08-16  
**Depends on:** `ES-TWO-TARGET-DIVISOR-SQUARE.md`, `ES-BINARY-LANE-I-EQUIVALENCE.md`, `K31-V2-ONE-LIFT-CLASSIFICATION.md`  
**Claim boundary:** this proves the hard-prime Jacobi trap, even outside-subgroup valuation, the pure-subgroup combined-miss branch, a full-subgroup hit criterion, and an exact four-companion criterion when the outside valuation is two. It does not classify every `k=35` miss and does not prove Erdős–Straus.

---

## 1. Setup

Let `p` be Mordell-hard and put

\[
\boxed{C=\frac{p+35}{4}}.
\]

Every hard prime is a quadratic residue modulo both `5` and `7`:

\[
\left(\frac p5\right)=+1,
\qquad
\left(\frac p7\right)=+1.
\]

Indeed the six hard classes modulo `840` reduce to `1,4 mod 5` and `1,2,4 mod 7`.

Since `4` is a square modulo both primes,

\[
C\equiv4^{-1}p\pmod{35}
\]

has the same two Legendre symbols. Therefore

\[
\boxed{
\left(\frac C5\right)
\left(\frac C7\right)=+1.
}
\]

---

## 2. The index-two subgroup

The unit group has order

\[
\varphi(35)=24.
\]

The residue `3` has order `12`, so

\[
\boxed{H=\langle3\rangle}
\]

is an index-two subgroup. Explicitly

\[
\boxed{
H=\{1,3,4,9,11,12,13,16,17,27,29,33\}.
}
\]

It is exactly the Jacobi-`+1` kernel

\[
\boxed{
H=\left\{x:\left(\frac x5\right)\left(\frac x7\right)=+1\right\}.
}
\]

Hence every Mordell-hard prime satisfies

\[
\boxed{C\in H.}
\]

The residue `6` is an involution outside `H`. Consequently

\[
\boxed{
(\mathbb Z/35\mathbb Z)^\times
=\langle3\rangle\times\langle6\rangle
\cong C_{12}\times C_2.
}
\]

Write every unit uniquely as

\[
\boxed{x=6^\varepsilon3^a,\qquad \varepsilon\in\{0,1\},\ a\in\mathbb Z/12\mathbb Z.}
\]

We call `(epsilon,a)` its coordinates.

---

## 3. Exact target coordinates

The Type-I divisor-square target is

\[
-4^{-1}\pmod{35}.
\]

Since

\[
4^{-1}\equiv9\pmod{35},
\]

this target is

\[
\boxed{26}.
\]

In the coordinates above,

\[
\boxed{26=(1,8).}
\]

Also

\[
\boxed{-1=34=(1,6).}
\]

Because `C in H`, write

\[
\boxed{C=(0,c).}
\]

Then the Type-II divisor target `-C` has coordinate

\[
\boxed{(1,c+6).}
\]

Thus both exact targets lie in the nontrivial `C_2` coset.

---

## 4. Even outside-subgroup valuation

Factor

\[
C=\prod_iq_i^{e_i}.
\]

Call a prime-factor occurrence **outside** when

\[
q_i\bmod35\notin H.
\]

Define

\[
\boxed{
E_{\rm out}(C)=
\sum_{q^e\parallel C,\ q\bmod35\notin H}e.
}
\]

Every outside occurrence contributes `epsilon=1`, while every `H` occurrence contributes `epsilon=0`. Since the product `C` has `epsilon=0`,

\[
\boxed{E_{\rm out}(C)\equiv0\pmod2.}
\]

So the `k=35` corridor moves directly from pure `H` support to outside packets of size `2,4,6,...`.

---

## 5. Pure-`H` trap

### Theorem — pure subgroup support misses both targets

If every prime factor of `C` lies in `H`, then every divisor of `C^2` also lies in `H`. Both exact targets lie outside `H`. Therefore

\[
\boxed{\text{Type I and Type II both miss at }k=35.}
\]

This is a universal branch, not a finite-census pattern.

---

## 6. Divisor-coordinate split

Write

\[
C=C_HC_N,
\]

where `C_H` contains all prime powers whose residues lie in `H`, and `C_N` contains all outside prime powers.

For a prime factor in `H`, write its coordinate as `(0,a)`. Define the `H`-part divisor-coordinate set

\[
\boxed{
D_H
=
\left\{
\sum_i f_i a_i\pmod{12}:
0\le f_i\le2e_i
\right\}
\subseteq C_{12}.
}
\]

This is the exact second-coordinate set of divisors of `C_H^2`.

### Theorem — full-`H` fill

If

\[
\boxed{D_H=C_{12}}
\]

and

\[
E_{\rm out}(C)>0,
\]

then both exact targets occur in the divisor box of `C^2`.

### Proof

An outside prime-factor occurrence can be chosen to divisor exponent `1`, producing at least one divisor in the `epsilon=1` coset. Adding the full `C_12` set from `D_H` fills the entire outside coset. Both `(1,8)` and `(1,c+6)` therefore occur. QED.

Hence every non-pure combined miss must have a thin `H`-part divisor set.

---

## 7. Exact four-companion criterion for `E_out=2`

The first possible non-pure case is

\[
\boxed{E_{\rm out}(C)=2.}
\]

Represent the two outside valuation units as

\[
\boxed{(1,\alpha),\qquad(1,\beta),\qquad \alpha,\beta\in C_{12},}
\]

allowing `alpha=beta` when one residue class supplies both valuation units.

Each valuation unit contributes divisor exponent `0,1,2`. A divisor lies in the outside coset exactly when the total selected outside exponent is odd. Therefore the possible outside second-coordinate contributions are

\[
\boxed{
O(\alpha,\beta)
=\{\alpha,\beta,\alpha+2\beta,2\alpha+\beta\}
\pmod{12}.
}
\]

If `alpha=beta`, this collapses to

\[
\boxed{O(\alpha,\alpha)=\{\alpha,3\alpha\}.}
\]

Let

\[
C=(0,c).
\]

### Theorem — four companions

Assume `E_out(C)=2`. Then Type I hits if and only if

\[
\boxed{
D_H\cap\bigl(8-O(\alpha,\beta)\bigr)\ne\varnothing.
}
\]

Type II hits if and only if

\[
\boxed{
D_H\cap\bigl(c+6-O(\alpha,\beta)\bigr)\ne\varnothing.
}
\]

Hence both targets miss exactly when

\[
\boxed{
D_H\cap\bigl(8-O(\alpha,\beta)\bigr)=\varnothing
}
\]

and

\[
\boxed{
D_H\cap\bigl(c+6-O(\alpha,\beta)\bigr)=\varnothing.
}
\]

### Proof

Every outside-coset divisor coordinate is the sum of one element of `D_H` and one odd-parity outside contribution. Under total outside valuation two, the latter are exactly the elements of `O(alpha,beta)`. Rearranging the two target equations gives the displayed intersections. QED.

Thus the entire first non-pure branch is reduced to at most four exact companion tests in `C_12`.

---

## 8. Finite signal after the classified corridor through `k=31`

On the preserved Mordell-hard corpus through

\[
p\le10^7,
\]

the classified shifts

\[
3,7,11,15,19,23,27,31
\]

leave exactly

\[
\boxed{65}
\]

targets.

At `k=35`, those 65 split as

\[
\boxed{46\text{ pure-}H\text{ misses}},
\]

\[
\boxed{17\text{ }E_{\rm out}=2\text{ hits}},
\]

and

\[
\boxed{2\text{ }E_{\rm out}=2\text{ misses}}.
\]

No larger outside valuation occurs on that finite residual.

The two finite two-packet misses are

```text
p=878641
C=219669=3*37*1979
outside coordinates: (1,11), (1,2)
next first hit: k=43

p=7559161
C=1889799=3*661*953
outside coordinates: (1,4), (1,9)
next first hit: k=47
```

These counts and examples are theorem-hunting evidence only. The subgroup, parity, pure-trap, full-fill, and four-companion statements above are universal exact results.

---

## 9. Research consequence

The post-`31` finite residual is now almost completely explained at `35` by one character obstruction:

\[
\boxed{
C_{35}\in\ker\left(\frac{\cdot}{5}\right)\left(\frac{\cdot}{7}\right).
}
\]

The first escape from that character trap must occur in a two-nontrivial-coset packet, and the exact success test for that packet is a four-point companion condition in `C_12`.

A useful next theorem target is not a larger raw finite scan. It is to combine the earlier `P+1,...,P+8` failure laws with this `P+9` Jacobi packet and prove additional restrictions on `D_H` or on the two outside coordinates.

---

Erdős–Straus remains open. This note reduces the next corridor layer without asserting a universal finite-shift ceiling.
