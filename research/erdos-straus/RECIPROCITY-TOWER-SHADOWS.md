# Reciprocity tower shadows

**Status:** proved theorem family inside the Type A/B minimal-depth program  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this does not prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture. It gives three exact infinite families of fully shadowed Type A/B layers.

Read with:

- [QUADRATIC-TRAP-SIGNATURE.md](QUADRATIC-TRAP-SIGNATURE.md)
- [CHARACTER-SHIELD-COMPLETENESS.md](CHARACTER-SHIELD-COMPLETENESS.md)
- [SQUARE-LIFT-TOWERS.md](SQUARE-LIFT-TOWERS.md)
- [DYADIC-TRAP-LATTICE.md](DYADIC-TRAP-LATTICE.md)
- [MULTIPLICATIVE-TRAP-QUOTIENT.md](MULTIPLICATIVE-TRAP-QUOTIENT.md)

## 1. Jacobi-saturated layers

For a Type A/B depth `j`, put

\[
m=4j-1
\]

and let

\[
N_m^-=
\left\{
u\in(\mathbb Z/m\mathbb Z)^\times:
\left(\frac{u}{m}\right)=-1
\right\}.
\]

The quadratic trap theorem gives

\[
T_j\subseteq N_m^-.
\]

Call the layer **Jacobi-saturated** if

\[
\boxed{T_j=N_m^-.}
\]

At such a layer, the single Jacobi bit already describes the exact Type A/B trap set.

## 2. Classification theorem

### Theorem

The Jacobi-saturated Type A/B layers are exactly

\[
\boxed{j\in\{1,2,4\}.}
\]

Equivalently,

```text
j = 1,  m = 3
j = 2,  m = 7
j = 4,  m = 15
```

are the only layers for which every Jacobi-negative unit is an exact Type A/B trap.

### Proof

Suppose `T_j=N_m^-`.

From the multiplicative trap-coset theorem,

\[
T_j\subseteq-D_j\subseteq N_m^-.
\]

Hence equality at the two ends forces

\[
T_j=-D_j=N_m^-.
\]

The full multiplicative saturation classification in [DYADIC-TRAP-LATTICE.md](DYADIC-TRAP-LATTICE.md) therefore implies

\[
j=2^a
\]

for some `a>=0`.

The endpoint `a=0` gives `j=1`, and direct inspection gives

\[
T_1=\{2\}=N_3^-.
\]

Now let `a>=1` and write

\[
r=a+2,
\qquad
m=2^r-1.
\]

The dyadic theorem gives

\[
D_j=\langle2\rangle,
\qquad
|D_j|=r.
\]

If the layer is Jacobi-saturated, then `D_j` is the complete Jacobi-positive kernel, whose size is `phi(m)/2`. Thus every Jacobi-positive unit would have to be one of

\[
1,2,2^2,\ldots,2^{r-1}\pmod m.
\]

For `r=3` and `r=4`, this is true:

\[
j=2,\quad m=7,
\]

and

\[
j=4,\quad m=15.
\]

We show it fails for every `r>=5` by explicitly producing a Jacobi-positive unit below `m` that is not a power of two.

Write

\[
r=2^s u,
\qquad u\text{ odd}.
\]

### Case 1: r is odd

Take

\[
x=9=3^2.
\]

Since `r` is odd,

\[
3\nmid2^r-1,
\]

so `x` is a unit modulo `m`. It is a square, hence Jacobi-positive. Also

\[
9<m
\]

for `r>=5`, and `9` is not a power of two. Thus `x notin D_j`.

### Case 2: u>1

Take

\[
t=2^s,
\qquad
x=(2^t+1)^2.
\]

Here

\[
\frac r{\gcd(r,t)}=u
\]

is odd. The standard gcd identity

\[
\gcd(2^r-1,2^t+1)=1
\]

therefore shows that `x` is a unit modulo `m`.

Because `u>=3`,

\[
r\ge3t,
\]

and for `t>=2`,

\[
(2^t+1)^2<2^{3t}-1\le2^r-1=m.
\]

The smallest relevant case `t=1,r>=6` gives `x=9<63<=m` directly.

Again `x` is a square, hence Jacobi-positive, and is visibly not a power of two. So `x notin D_j`.

### Case 3: u=1

Then `r` is a power of two. Since `r>=5`, in fact

\[
r\ge8.
\]

Take

\[
x=49=7^2.
\]

The order of `2 mod 7` is `3`, which does not divide a power of two. Hence

\[
7\nmid2^r-1,
\]

so `x` is a unit modulo `m`.

Also

\[
49<2^8-1\le m,
\]

and `49` is not a power of two. Again this is a Jacobi-positive unit outside `D_j`.

Thus no `r>=5` is Jacobi-saturated.

Therefore the only Jacobi-saturated depths are

\[
\boxed{1,2,4.}
\]

QED.

## 3. Reciprocity tower lemma

Let `j` be any Type A/B layer and put

\[
m=4j-1.
\]

For any positive odd integer `c`, define the square-lift depth

\[
\boxed{
K_c=\frac{mc^2+1}{4}.
}
\]

Then

\[
4K_c-1=mc^2.
\]

### Lemma

For every divisor `e|K_c`,

\[
\boxed{
\left(\frac e m\right)=+1.
}
\]

### Proof

First,

\[
4K_c=mc^2+1
\]

shows

\[
\gcd(K_c,m)=1.
\]

Let `ell` be an odd prime divisor of `K_c`. Then

\[
mc^2\equiv-1\pmod\ell.
\]

Also `ell` cannot divide `c`, since otherwise the same congruence would give `0=-1 mod ell`.

Thus

\[
-m\equiv c^{-2}\pmod\ell,
\]

so

\[
\left(\frac{-m}{\ell}\right)=+1.
\]

Because

\[
m\equiv3\pmod4,
\]

quadratic reciprocity gives the identity

\[
\left(\frac{-m}{\ell}\right)
=
\left(\frac{\ell}{m}\right).
\]

Therefore

\[
\left(\frac{\ell}{m}\right)=+1.
\]

If `2|K_c`, then `c^2=1 mod 8` and

\[
mc^2+1\equiv0\pmod8,
\]

so

\[
m\equiv7\pmod8.
\]

Hence

\[
\left(\frac2m\right)=+1.
\]

Every prime divisor of `K_c` therefore has Jacobi symbol `+1 mod m`. Multiplicativity gives

\[
\left(\frac e m\right)=+1
\]

for every `e|K_c`. QED.

## 4. Reciprocity tower shadow theorem

### Theorem

If the base layer `j` is Jacobi-saturated, then every odd square lift `K_c` is fully shadowed by `j`:

\[
\boxed{
T_{K_c}\bmod m
\subseteq
T_j.
}
\]

For `c>1`, this is a genuine earlier-to-later direct shadow relation.

### Proof

Take any target trap residue at the lifted layer. It is of the form

\[
-e
\]

or

\[
-4e
\]

with `e|K_c`.

By the reciprocity tower lemma,

\[
\left(\frac e m\right)=+1.
\]

Since `m=3 mod 4`,

\[
\left(\frac{-1}{m}\right)=-1,
\]

and since `4` is a square,

\[
\left(\frac4m\right)=+1.
\]

Therefore

\[
\left(\frac{-e}{m}\right)
=
\left(\frac{-4e}{m}\right)
=-1.
\]

The base is Jacobi-saturated, so every Jacobi-negative unit modulo `m` lies in `T_j`. Hence both reduced trap residues lie in `T_j`.

Thus

\[
T_{K_c}\bmod m\subseteq T_j.
\]

QED.

## 5. The three universal shadow towers

By the classification theorem, the only possible bases are

\[
j=1,2,4.
\]

Therefore every positive odd `c` gives the exact shadow families

\[
\boxed{
K_c^{(1)}=\frac{3c^2+1}{4},
}
\]

\[
\boxed{
K_c^{(2)}=\frac{7c^2+1}{4},
}
\]

and

\[
\boxed{
K_c^{(4)}=\frac{15c^2+1}{4}.
}
\]

For every odd `c>1`, respectively,

\[
\boxed{
T_{K_c^{(1)}}\bmod3\subseteq T_1,
}
\]

\[
\boxed{
T_{K_c^{(2)}}\bmod7\subseteq T_2,
}
\]

and

\[
\boxed{
T_{K_c^{(4)}}\bmod15\subseteq T_4.
}
\]

These are three explicit infinite families of later Type A/B layers that contribute no new exact trap information beyond one fixed earlier layer.

## 6. Polynomial form of the depth families

Writing

\[
c=2n+1,
\qquad n\ge0,
\]

the three depth families become

\[
\boxed{
K_n^{(1)}=3n^2+3n+1,
}
\]

\[
\boxed{
K_n^{(2)}=7n^2+7n+2,
}
\]

and

\[
\boxed{
K_n^{(4)}=15n^2+15n+4.
}
\]

For `n>=1`, each is fully shadowed by the corresponding base layer `1`, `2`, or `4`.

The first few values are:

```text
base j=1:  7, 19, 37, 61, 91, ...
base j=2: 16, 44, 86, 142, 212, ...
base j=4: 34, 94, 184, 304, 454, ...
```

## 7. Relation to square-lift towers

The modulus relation is exactly

\[
4K_c-1=(4j-1)c^2.
\]

So these are square-lift towers in the sense of [SQUARE-LIFT-TOWERS.md](SQUARE-LIFT-TOWERS.md).

The new theorem identifies the precise reason that these three towers are universally shadowed:

> every divisor of the lifted depth is forced by quadratic reciprocity into the Jacobi-positive class of the base modulus, and at the three saturated bases the negative Jacobi class is already the exact trap set.

This is stronger than merely observing modulus divisibility.

## 8. Relation to the dyadic lattice

The base layers `1`, `2`, and `4` are also exactly the first three multiplicatively saturated dyadic layers.

But the reciprocity tower theorem is not the same as the dyadic Mersenne shadow lattice.

For example,

\[
j=2,\quad c=3
\]

gives

\[
K_c=16,
\]

which lies in both structures.

Meanwhile

\[
j=4,\quad c=3
\]

gives

\[
K_c=34,
\]

which is not dyadic at all, yet it is still completely shadowed by layer `4`.

Thus quadratic-reciprocity square lifts generate a substantially broader infinite shadow mechanism.

## 9. Immediate exact-depth consequence

No prime can have its **first** Type A/B hit at a layer belonging to one of these towers once the corresponding earlier layer is among the imposed history.

In the unrestricted Type A/B system, for every odd `c>1`,

\[
\boxed{
C_{AB}(p)\ne K_c^{(1)},
\quad
C_{AB}(p)\ne K_c^{(2)},
\quad
C_{AB}(p)\ne K_c^{(4)}
}
\]

for every prime `p` for which the congruence comparison is prime-compatible.

More precisely, any prime landing in the lifted trap layer necessarily already lands in the corresponding earlier trap layer, so the lifted layer can never be a new first hit.

## 10. Why this matters

The shadow graph now contains at least two proved infinite algebraic mechanisms:

1. **Mersenne/dyadic cyclic ancestry**, controlled by exponent divisibility;
2. **quadratic-reciprocity square-lift towers**, controlled by Jacobi saturation.

So the large finite shadow map is no longer merely a collection of computational coincidences. Distinct infinite theorem families are beginning to emerge from different algebraic causes.

That is exactly the kind of decomposition needed for a structural classification of the irredundant Type A/B core.

## 11. Next theorem targets

1. classify square-lift shadows from non-saturated bases by replacing the Jacobi bit with the full local quadratic-signature quotient;
2. classify them again using the stronger multiplicative quotient `Gamma_j`;
3. determine whether every observed square-lift direct shadow is explained by one of these quotient mechanisms;
4. prove a general quotient-tower shadow criterion;
5. fold the resulting infinite families into an algebraic description of the exact-depth structural gaps.

## 12. Novelty boundary

Quadratic reciprocity, Jacobi symbols, and the algebraic identity `4K-1=(4j-1)c^2` are classical. López's Type A/B congruences are prior art.

The candidate contribution is the **Jacobi-saturation classification and resulting three infinite reciprocity-driven Type-A/B direct-shadow towers inside the minimal-depth/shadow framework**.

A targeted arXiv search on 2026-08-14 did not locate this exact formulation. That negative search does not establish publication priority.
