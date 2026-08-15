# Composite successor `3r`: exact index-six defect classification

**Status:** proved theorem  
**Date:** 2026-08-15  
**Depends on:** `ES-COMPOSITE-SUCCESSOR-3R.md`, `ES-COMPOSITE-SUCCESSOR-INDEX4.md`, `ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md`, `FAB-KNESER-FULL-STABILIZER-DEFECT.md`, `EXTERNAL-NR-FACTOR-CYCLE.md`  
**Claim boundary:** classifies every full-stabilizer index-six failure at the natural composite successor `k=3r`. Genuine index-six failures exist, so this does not prove Erdős--Straus.

---

## 1. Setup

Let `p` be Mordell-hard and let

\[
r<p,
\qquad
r\equiv1\pmod4,
\qquad
\left(\frac rp\right)=-1.
\]

Use the natural admissible shift

\[
\boxed{k=3r}
\]

and put

\[
\boxed{C=\frac{p+3r}{4}.}
\]

Let

\[
G=(\mathbb Z/3r\mathbb Z)^\times,
\qquad
R=\mathcal R_{3r}(C),
\qquad
H=\operatorname{Stab}(R).
\]

Assume both exact targets miss and

\[
\boxed{[G:H]=6.}
\]

Then

\[
\bar G=G/H\cong C_6.
\]

Because an index-three quotient must exist in the `r`-component,

\[
\boxed{r\equiv1\pmod3.}
\]

Together with `r≡1 mod4`,

\[
\boxed{r\equiv1\pmod{12}.}
\]

Also hard `p≡1 mod3`, so

\[
\boxed{C\equiv1\pmod3.}
\]

---

## 2. The three quadratic characters

CRT gives

\[
G
\cong
(\mathbb Z/3\mathbb Z)^\times
\times
(\mathbb Z/r\mathbb Z)^\times.
\]

Define the three nontrivial quadratic characters

\[
\varepsilon(x)=\left(\frac x3\right),
\qquad
\eta(x)=\left(\frac xr\right),
\qquad
\chi(x)=\varepsilon(x)\eta(x).
\]

For hard `p` and external `r`,

\[
\boxed{
\varepsilon(p)=+1,
\qquad
\eta(p)=-1,
\qquad
\chi(p)=-1.}
\]

For `-1`, since `r≡1 mod4`,

\[
\boxed{
\varepsilon(-1)=-1,
\qquad
\eta(-1)=+1,
\qquad
\chi(-1)=-1.}
\]

The order-three quotient is the unique cubic-residue quotient of the `r`-component. Write its character abstractly as

\[
\kappa:G\to C_3.
\]

Because `r≡1 mod12`, `-1` is a cube modulo `r`, so

\[
\boxed{\kappa(-1)=0.}
\]

Every index-six subgroup with cyclic quotient is the intersection of the kernel of one of the three quadratic characters with the cubic-residue kernel.

---

## 3. The eta branch is impossible

Suppose the order-two quotient coordinate were `eta`.

Then

\[
\eta(-1)=+1
\]

and

\[
\kappa(-1)=0.
\]

Thus

\[
-1\in H.
\]

Since `1∈R` and `R` is `H`-periodic,

\[
H\subseteq R,
\]

so Type II would hit.

Therefore

\[
\boxed{H\text{ cannot use the quadratic character }\eta.}
\]

Only the `epsilon` and `chi=epsilon eta` branches remain.

---

## 4. Branch A: chi-cubic primitive defect

Assume

\[
\boxed{H=\ker\chi\cap\ker\kappa.}
\]

Since

\[
\chi(p)=-1,
\]

the image of `p` has nontrivial order-two coordinate.

If `p` were a cubic residue modulo `r`, its image in `C_6` would be the unique order-two class `3`. But then

\[
[-p^{-1}]=[-1]-[p]=3-3=0,
\]

so the Type-I target would lie in `H⊆R`.

Hence failure forces

\[
\boxed{p\text{ is a cubic nonresidue modulo }r.}
\]

Therefore the image of `p` has order six. Orient `C_6` so that

\[
[p]=1\text{ or }5.
\]

Then the three natural excluded target classes are exactly

\[
\boxed{2,3,4.}
\]

Thus the quotient box occupies at most three classes.

### Full-stabilizer atom restriction

For every prime-power factor

\[
s^e\parallel C
\]

outside `H`, the full-stabilizer theorem gives

\[
\operatorname{ord}_{\bar G}(sH)>2e+1.
\]

Inside `C_6`, this forces order six. If `e>=2`, its local signed set already has at least five quotient classes, impossible because the box may occupy at most three.

Hence every exceptional atom is simple and contributes two units to the Kneser budget.

Three distinct missing target cosets give the combined budget

\[
\sum(s_i-1)\le2.
\]

Therefore exactly one exceptional atom exists.

### Theorem — primitive mixed-character normal form

In Branch A there is a unique simple prime factor

\[
\boxed{s\mid C}
\]

outside `H`, with

\[
\boxed{v_s(C)=1,}
\]

and

\[
\boxed{
\chi(s)=-1,
\qquad
s\text{ is a cubic nonresidue modulo }r.}
\]

Every other prime factor of `C` lies in `H`, hence satisfies

\[
\chi=+1
\]

and is a cubic residue modulo `r`.

The quotient box is exactly

\[
\boxed{\bar R=\{0,1,5\}.}
\]

This is the direct composite analogue of the primitive sextic defect at a `3 mod4` prime shift.

---

## 5. The unique primitive atom is the external successor in Branch A

The external factor-cycle theorem guarantees a prime factor

\[
t\mid C
\]

with

\[
\left(\frac tp\right)=-1.
\]

For a `1 mod4` source `r`, the exact transfer law gives

\[
\left(\frac tr\right)
=-\left(\frac{-3}{t}\right).
\]

For every odd prime `t!=3`, quadratic reciprocity gives the elementary identity

\[
\boxed{
\left(\frac{-3}{t}\right)
=\left(\frac t3\right)
=\varepsilon(t).}
\]

Since `C≡1 mod3`, the prime `3` does not divide `C`. Therefore

\[
\eta(t)
=\left(\frac tr\right)
=-\varepsilon(t),
\]

and hence

\[
\boxed{
\chi(t)=\varepsilon(t)\eta(t)=-1.}
\]

But every hidden factor in Branch A has `chi=+1`. Thus every external nonresidue factor lies outside `H`.

There is only one exceptional factor.

Therefore:

\[
\boxed{
\text{the unique primitive atom }s
\text{ is the unique external-nonresidue factor of }C.}
\]

So Branch A again has a forced descent edge

\[
\boxed{r\longrightarrow s.}
\]

---

## 6. Branch B: epsilon-cubic parity defect

Assume instead

\[
\boxed{H=\ker\varepsilon\cap\ker\kappa.}
\]

Here

\[
\varepsilon(p)=+1.
\]

If `p` were a cubic nonresidue modulo `r`, then its image in `C_6` would have order three, i.e. class `2` or `4`.

The Type-II target is class `3`, while the two Type-I orientations would then be classes `1` and `5`.

A symmetric quotient box avoiding `1,3,5` could only lie inside

\[
\{0,2,4\},
\]

but that is the order-three subgroup of `C_6` and has nontrivial stabilizer, contradicting the definition of the full quotient.

Therefore failure forces

\[
\boxed{p\in H.}
\]

Equivalently,

\[
\boxed{p\text{ is a cubic residue modulo }r.}
\]

All three natural solution targets then collapse to the single quotient class

\[
\boxed{3.}
\]

because `[-p]=[-p^{-1}]=[-1]` modulo `H`.

---

## 7. Exceptional valuation mass in Branch B is exactly two

Since only class `3` is forced missing, the one-target full-stabilizer mass bound at index six gives

\[
\boxed{
\sum_{s^e\parallel C,\ s\notin H}e\le2.}
\]

Aperiodicity of the quotient box requires at least one factor outside `H`.

Every nontrivial factor again must have projected order six. Hence every exceptional prime has

\[
\boxed{
\varepsilon(s)=-1
}
\]

and is a cubic nonresidue modulo `r`.

Thus every exceptional prime is

\[
\boxed{s\equiv2\pmod3.}
\]

But

\[
C\equiv1\pmod3.
\]

All hidden factors have `epsilon=+1`, so the total valuation mass of the `epsilon=-1` exceptional factors must be even.

It is positive and at most two. Therefore

\[
\boxed{
\sum_{s^e\parallel C,\ s\notin H}e=2.}
\]

There are exactly two possibilities:

1. one exceptional prime with exponent two;
2. two distinct simple exceptional primes.

In either case the quotient signed box is

\[
\boxed{\bar R=\{0,1,2,4,5\}=C_6\setminus\{3\}.}
\]

### Theorem — parity-cubic double-defect normal form

Branch B is characterized by:

\[
\boxed{
H=\ker\varepsilon\cap\ker\kappa,
\qquad
p\in H,}
\]

with exactly two units of exceptional valuation, each carried by primes

\[
\boxed{
 s\equiv2\pmod3
}
\]

that are cubic nonresidues modulo `r`.

Every hidden prime factor is `1 mod3` and a cubic residue modulo `r`.

Unlike Branch A, the external-nonresidue factor supplied by the factor-cycle theorem need not be the unique visible atom; it may lie in the hidden background because this branch does not constrain the quadratic character `eta` separately.

---

## 8. Complete index-six dichotomy

Every combined full-stabilizer index-six failure at the natural composite successor `k=3r` is exactly one of the following:

### A. Primitive mixed-character defect

\[
\boxed{
H=\ker(\varepsilon\eta)\cap\ker\kappa}
\]

with:

- `p` cubic-nonresidue modulo `r`;
- exactly one simple order-six exceptional prime;
- that prime is the unique external-nonresidue factor and forces the next descent edge;
- quotient box `C_6\setminus\{2,3,4\}`.

### B. Parity-cubic double defect

\[
\boxed{
H=\ker\varepsilon\cap\ker\kappa}
\]

with:

- `p` cubic-residue modulo `r`;
- exceptional valuation mass exactly two;
- every exceptional prime is `2 mod3` and cubic-nonresidue modulo `r`;
- quotient box `C_6\setminus\{3\}`.

No third index-six geometry is possible.

---

## 9. Research consequence

Combined with the preceding `3r` theorems:

- odd full-stabilizer index is impossible;
- index two is restricted to the pure Eisenstein-split obstruction;
- index four is impossible;
- index six is now completely classified into the two normal forms above.

The next direct target is Branch B. Branch A still transports a unique primitive atom and can be joined to the sextic-chain machinery. Branch B is qualitatively different: it is the first place where the external descent edge can hide inside the stabilizer while exactly two inert-mod-3 cubic defects remain visible.

A closure theorem for the parity-cubic double defect would remove the first genuinely new composite obstruction beyond the prime-shift primitive sextic geometry.
