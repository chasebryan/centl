# Index-two character packet lemma for exact two-target shifts

**Status:** proved reusable finite-group lemma  
**Date:** 2026-08-16  
**Depends on:** `ES-TWO-TARGET-DIVISOR-SQUARE.md`, `ES-BINARY-LANE-I-EQUIVALENCE.md`  
**Claim boundary:** this is an elementary structural lemma for one fixed admissible shift equipped with an order-two character. It organizes several corridor filters but does not prove that such a shift must hit, and does not prove Erdős–Straus. No literature-priority claim is made for the underlying character/group facts.

---

## 1. Fixed-shift divisor-square form

Let

\[
k\equiv3\pmod4
\]

be an odd admissible shift and let

\[
p\equiv1\pmod4
\]

be prime with

\[
\gcd(p,k)=1.
\]

Put

\[
\boxed{C=\frac{p+k}{4}.}
\]

Then `gcd(C,k)=1`. Let

\[
G=(\mathbb Z/k\mathbb Z)^\times.
\]

By the exact divisor-square form of the two-target theorem, write

\[
D(C^2)=\{d\bmod k:d\mid C^2\}\subseteq G.
\]

The two targets are

\[
\boxed{\tau_I=-4^{-1}\pmod k}
\]

and

\[
\boxed{\tau_{II}=-C\pmod k.}
\]

The shift hits exactly when

\[
\boxed{D(C^2)\cap\{\tau_I,\tau_{II}\}\ne\varnothing.}
\]

---

## 2. An order-two character

Let

\[
\chi:G\to\{\pm1\}
\]

be a nontrivial multiplicative character satisfying

\[
\boxed{\chi(-1)=-1.}
\]

Put

\[
\boxed{H=\ker\chi.}
\]

Then `H` has index two in `G`.

Because `4` is a square in `G`,

\[
\chi(4^{-1})=+1.
\]

Therefore the fixed Type-I target always lies outside the kernel:

\[
\boxed{\chi(\tau_I)=-1.}
\]

For Type II,

\[
\boxed{\chi(\tau_{II})=-\chi(C).}
\]

Thus Type II always lies in the character class opposite to `C`.

---

## 3. Outside-factor parity is fixed by `C`

Factor

\[
C=\prod_iq_i^{e_i}.
\]

Call a prime-factor occurrence **outside** when

\[
q_i\bmod k\notin H.
\]

Define

\[
\boxed{
E_{\rm out}(C)
=\sum_{q^e\parallel C,\ q\notin H}e.
}
\]

Since every outside occurrence has character `-1`,

\[
\boxed{
\chi(C)=(-1)^{E_{\rm out}(C)}.
}
\]

Hence:

- if `C in H`, then `E_out(C)` is even;
- if `C notin H`, then `E_out(C)` is odd.

This parity law is exact and requires no factor-size or primality assumptions beyond the fixed-shift setup.

---

## 4. Kernel and outside divisor factors

Write

\[
C=C_HC_N,
\]

where `C_H` contains all prime powers in `H` and `C_N` all outside prime powers.

Define the exact kernel divisor set

\[
\boxed{
D_H=D(C_H^2)\subseteq H.
}
\]

The full divisor set factors as the set product

\[
\boxed{D(C^2)=D_H\,D_N}
\]

where

\[
D_N=D(C_N^2).
\]

All target questions can therefore be reduced to the pieces of `D_N` in the two character cosets, translated by `D_H`.

---

## 5. Pure-kernel trap

Assume

\[
\boxed{C\in H}
\]

and

\[
\boxed{E_{\rm out}(C)=0.}
\]

Then every divisor of `C^2` lies in `H`, while both targets lie outside `H`:

\[
\chi(\tau_I)=-1,
\qquad
\chi(\tau_{II})=-\chi(C)=-1.
\]

### Theorem A — pure-kernel combined miss

If `C in H` and every prime factor of `C` lies in `H`, then

\[
\boxed{\text{Type I and Type II both miss}.}
\]

This is the common character-trap mechanism behind several exact corridor filters.

---

## 6. Full kernel divisor mass forces a hit once an outside factor exists

Suppose

\[
\boxed{D_H=H}
\]

and

\[
E_{\rm out}(C)>0.
\]

Then `D_N` contains at least one outside element `u`, obtained by selecting divisor exponent one for any outside occurrence. Thus

\[
D_Hu=Hu=G\setminus H.
\]

It also contains `1`, so

\[
D_H\subseteq D(C^2).
\]

Therefore the full divisor set contains **both character cosets**.

### Theorem B — full-kernel fill

If `D_H=H` and at least one outside prime-factor occurrence is present, then

\[
\boxed{\tau_I,\tau_{II}\in D(C^2).}
\]

In particular both Type I and Type II hit.

Hence every non-pure miss must have a thin kernel divisor set.

---

## 7. First even packet: four companions

Assume

\[
\boxed{C\in H}
\]

and the first non-pure possibility

\[
\boxed{E_{\rm out}(C)=2.}
\]

Represent the two outside valuation units by

\[
u,v\in G\setminus H,
\]

allowing `u=v` if one residue class supplies both valuation units.

Each unit has divisor exponent `0,1,2`. An outside-coset divisor uses odd total selected outside exponent. The complete outside-coset contribution set is therefore

\[
\boxed{
O(u,v)=\{u,v,uv^2,u^2v\}.
}
\]

When `u=v`, this collapses to

\[
\boxed{O(u,u)=\{u,u^3\}.}
\]

Because both targets lie outside `H`, only these outside contributions can hit them.

### Theorem C — four-companion criterion

If `C in H` and `E_out(C)=2`, then for either target

\[
\tau\in\{\tau_I,\tau_{II}\},
\]

one has

\[
\boxed{
\tau\in D(C^2)
\iff
D_H\cap\tau\,O(u,v)^{-1}\ne\varnothing.
}
\]

Thus a two-occurrence escape packet requires at most four exact companion tests inside `H`.

### Proof

The outside part of any divisor that can equal `tau` must lie in the outside coset. Under exactly two outside valuation units those residues are precisely `O(u,v)`. Writing `tau=h o` with `h in D_H` and `o in O(u,v)` is equivalent to `h=tau o^{-1}`. QED.

---

## 8. First odd packet: one plus two companions

Now assume

\[
\boxed{C\notin H}
\]

and the first possible outside valuation

\[
\boxed{E_{\rm out}(C)=1.}
\]

Let the unique outside valuation unit be

\[
u\in G\setminus H.
\]

Its divisor exponents `0,1,2` contribute

\[
\boxed{\{1,u,u^2\}.}
\]

The Type-I target is outside `H`, so only the exponent-one contribution can reach it:

\[
\boxed{
\tau_I\text{ hits}
\iff
D_H\cap\{\tau_Iu^{-1}\}\ne\varnothing.
}
\]

The Type-II target now lies **inside** `H`, because

\[
\chi(\tau_{II})=-\chi(C)=+1.
\]

It may use outside exponent zero or two. Hence

\[
\boxed{
\tau_{II}\text{ hits}
\iff
D_H\cap\{\tau_{II},\tau_{II}u^{-2}\}\ne\varnothing.
}
\]

### Theorem D — first odd packet

If `C notin H` and `E_out(C)=1`, the complete fixed-shift two-target test reduces to one Type-I kernel companion and two Type-II kernel companions.

---

## 9. Applications already present in the corridor

### `k=27`

Take the quadratic character on the cyclic unit group modulo `27`. Its kernel is the quadratic-residue subgroup, equivalently the unit residues `1 mod 3`. Hard primes give

\[
C_{27}\equiv1\pmod3,
\]

so `C_{27} in H` and outside valuation is even. Theorem A is the pure-QR branch, while Theorem C is exactly the four-companion reduction in `K27-TWO-TARGET-STRUCTURE.md`.

### `k=35`

Take

\[
\chi(x)=\left(\frac x5\right)\left(\frac x7\right).
\]

Then

\[
H=\langle3\rangle
\]

and every hard `C_{35}` lies in `H`. Theorems A and C give the Jacobi trap and four-companion packet in `K35-TWO-TARGET-STRUCTURE.md`.

### `k=39`

The order-twelve subgroup

\[
H=\langle2\rangle\subset(\mathbb Z/39\mathbb Z)^\times
\]

has index two and excludes `-1`. Here `C_{39}` may lie in either character class. Therefore both parity branches occur: Theorem C applies when `C_{39} in H`, and Theorem D applies when `C_{39} notin H` with one outside valuation unit.

This explains why the `k=39` finite residual naturally separates into pure-kernel, two-packet, and one-packet geometries.

---

## 10. Research consequence

The recurring corridor pattern is not three unrelated modular coincidences. It is one finite-group mechanism:

\[
\boxed{
\text{order-two character}
+\chi(-1)=-1
+\text{thin kernel divisor mass}
+\text{small outside packet}.
}
\]

The fixed-shift proof problem can therefore be split into two pieces:

1. **character layer:** determine `chi(C)` and hence the parity/cosets of possible targets and outside factor packets;
2. **kernel layer:** determine whether `D_H` meets the small companion set forced by that packet.

For cross-shift work, the important object is no longer the raw factorization of each consecutive `P+u`. It is the sequence of character parities and thin kernel divisor sets attached to those translates.

That sequence is the natural target for a simultaneous incompatibility theorem.

---

Erdős–Straus remains open. This lemma organizes fixed-shift misses; it does not eliminate all of them.
