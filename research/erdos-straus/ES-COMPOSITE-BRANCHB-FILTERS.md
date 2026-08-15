# Additional filters on the parity-cubic `3r` index-six defect

**Status:** proved corollaries of the Branch-B normal form  
**Date:** 2026-08-15  
**Depends on:** `ES-COMPOSITE-SUCCESSOR-INDEX6.md`  
**Claim boundary:** these restrictions sharpen the remaining parity-cubic index-six branch but do not eliminate it and therefore do not prove Erdős--Straus.

---

## 1. Branch-B setup

Let `p` be Mordell-hard and let

\[
r<p,
\qquad
r\equiv1\pmod4,
\qquad
\left(\frac rp\right)=-1.
\]

At the natural composite shift

\[
k=3r,
\qquad
C=\frac{p+3r}{4},
\]

assume a combined full-stabilizer index-six failure in Branch B of `ES-COMPOSITE-SUCCESSOR-INDEX6.md`.

Then

\[
\boxed{
H=\ker\varepsilon\cap\ker\kappa,}
\]

where

\[
\varepsilon(x)=\left(\frac x3\right)
\]

is the mod-3 parity character and `kappa` is the cubic-residue quotient modulo `r`.

The quotient is

\[
\bar G=G/H\cong C_6.
\]

The Branch-B theorem gives:

1. `p∈H`, so `p` is a cubic residue modulo `r`;
2. every exceptional prime has order six in `bar G`;
3. every exceptional prime is `2 mod 3` and a cubic nonresidue modulo `r`;
4. the total exceptional valuation mass is exactly two;
5. every hidden factor is `1 mod 3` and cubic-residue-side;
6. the quotient box is
   \[
   \bar R=C_6\setminus\{3\}.
   \]

We now exploit the exact identity

\[
\boxed{4C\equiv p\pmod{3r}.}
\]

Since `p∈H`, this becomes in the quotient

\[
\boxed{2[2]+[C]=0.}
\]

---

## 2. The shifted integer C must be odd

Suppose

\[
2\mid C.
\]

Because

\[
\varepsilon(2)=-1,
\]

the prime `2` cannot lie in `H`. Hence it is one of the exceptional factors.

Every exceptional factor has quotient order six. Therefore

\[
\boxed{[2]\text{ has order }6.}
\]

Let

\[
e=v_2(C).
\]

The total exceptional valuation mass is exactly two, so

\[
e\in\{1,2\}.
\]

### Case e = 2

Then `2` uses the entire exceptional mass. All other factors lie in `H`, so

\[
[C]=2[2].
\]

The identity `2[2]+[C]=0` gives

\[
4[2]=0.
\]

But an element of order six is not annihilated by four. Contradiction.

### Case e = 1

Then there is exactly one further simple exceptional prime `s`, whose quotient class also has order six.

Thus

\[
[C]=[2]+[s].
\]

The same identity gives

\[
3[2]+[s]=0.
\]

For an order-six element, `3[2]` is the unique element of order two, namely class `3` in `C_6`. Hence

\[
[s]=3,
\]

which has order two rather than six. Contradiction.

Therefore:

### Theorem — Branch B is odd

\[
\boxed{2\nmid C.}
\]

So every parity-cubic Branch-B defect satisfies

\[
\boxed{C\text{ is odd}.}
\]

---

## 3. The source prime satisfies r = 1 mod 24

Mordell-hard primes satisfy

\[
p\equiv1\pmod8.
\]

Since

\[
C=\frac{p+3r}{4}
\]

is odd, we must have

\[
p+3r\equiv4\pmod8.
\]

With `p≡1 mod8`, this gives

\[
3r\equiv3\pmod8,
\]

so

\[
\boxed{r\equiv1\pmod8.}
\]

The index-six classification already gives

\[
r\equiv1\pmod3.
\]

Therefore:

### Corollary — exact source congruence

\[
\boxed{r\equiv1\pmod{24}.}
\]

Thus the parity-cubic defect occupies only one of the six odd residue classes modulo `24` available to a general external prime.

---

## 4. The class of 2 records the exceptional orientation

Although `2` does not divide `C`, its quotient class still enters through

\[
2[2]+[C]=0.
\]

Because

\[
\varepsilon(2)=-1,
\]

the class `[2]` is one of the odd classes

\[
1,3,5
\]

in `C_6`.

The exceptional valuation mass two has two structural possibilities.

### Configuration I: opposite simple atoms

Suppose there are two distinct simple exceptional primes with quotient classes

\[
1\quad\text{and}\quad5.
\]

Then their total contribution to `C` is zero:

\[
[C]=0.
\]

Hence

\[
2[2]=0.
\]

Among the odd classes of `C_6`, only class `3` is killed by multiplication by two. Thus

\[
\boxed{[2]=3.}
\]

So `2` has trivial cubic coordinate:

\[
\boxed{2\text{ is a cubic residue modulo }r.}
\]

### Configuration II: aligned mass

If instead the exceptional contribution is

\[
[C]=2
\quad\text{or}\quad
[C]=4,
\]

which happens either when the two simple atoms have the same orientation or when one exceptional prime occurs to exponent two, then

\[
2[2]=-[C]
\]

forces

\[
[2]=1
\quad\text{or}\quad
[2]=5.
\]

Therefore

\[
\boxed{2\text{ is a cubic nonresidue modulo }r.}
\]

We obtain:

### Theorem — cubic character of 2 distinguishes the two Branch-B shapes

In a parity-cubic Branch-B defect:

\[
\boxed{
2\text{ cubic residue mod }r
\iff
\text{the two simple exceptional classes are opposite}.}
\]

If `2` is a cubic nonresidue modulo `r`, then the exceptional valuation is aligned in one of the two classes `±1`: either one squared exceptional prime or two simple exceptional primes with the same orientation.

---

## 5. Strengthened Branch-B normal form

Every Branch-B index-six defect at `k=3r` therefore satisfies all of the following:

\[
\boxed{
r\equiv1\pmod{24},
\qquad
C=\frac{p+3r}{4}\text{ odd}.}
\]

Moreover:

- `p` is a cubic residue modulo `r`;
- exactly two units of factor valuation are carried by primes `2 mod 3` that are cubic nonresidues modulo `r`;
- every other factor is `1 mod 3` and cubic-residue-side;
- the cubic character of `2` modulo `r` determines whether the two visible order-six atoms cancel or align in the quotient.

The remaining branch is now a simultaneous cubic splitting problem involving

\[
p,\quad 2,\quad\text{and the complete factorization of }\frac{p+3r}{4}.
\]

---

## 6. Next target

The most concrete closure targets are now:

1. use cubic reciprocity to compare the condition
   \[
   p\in((\mathbb Z/r\mathbb Z)^\times)^3
   \]
   with the prescribed cubic characters of the two inert-mod-3 exceptional primes;
2. use an explicit criterion for the cubic character of `2 mod r` together with
   \[
   r\equiv1\pmod{24}
   \]
   to separate or eliminate the aligned and cancelling configurations;
3. show that either configuration forces a new exact Type-I or Type-II divisor-square hit at a related admissible shift.

This is substantially narrower than the original composite-successor problem: the first non-primitive index-six obstruction now lives on one congruence class of source primes and only two units of visible factor valuation.
