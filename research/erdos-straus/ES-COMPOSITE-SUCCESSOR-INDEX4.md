# Composite successor `3r`: index-four defect elimination

**Status:** proved universal theorem  
**Date:** 2026-08-15  
**Depends on:** `ES-COMPOSITE-SUCCESSOR-3R.md`, `ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md`, `FAB-KNESER-FULL-STABILIZER-DEFECT.md`  
**Claim boundary:** eliminates full-stabilizer index four for a failed `3r` successor. It does not eliminate the Eisenstein-split branch or all higher even indices and therefore does not prove Erdős--Straus.

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

Use the natural admissible composite successor

\[
\boxed{k=3r}
\]

and put

\[
C=\frac{p+3r}{4}.
\]

Let

\[
G=(\mathbb Z/3r\mathbb Z)^\times,
\qquad
R=\mathcal R_{3r}(C),
\qquad
H=\operatorname{Stab}(R).
\]

Assume both exact solution targets miss:

\[
-p^{-1}\notin R,
\qquad
-1\notin R.
\]

By inversion symmetry,

\[
-p\notin R.
\]

We prove that

\[
\boxed{[G:H]\ne4.}
\]

---

## 2. General full-stabilizer order gap

Pass to the quotient

\[
\bar G=G/H,
\qquad
\bar R=R/H.
\]

Because `H` is the full stabilizer, `bar R` has trivial stabilizer.

For every prime-power factor

\[
s^e\parallel C
\]

whose image `sH` is nontrivial, the full-stabilizer theorem gives

\[
\boxed{
\operatorname{ord}_{\bar G}(sH)>2e+1.
}
\]

If `|bar G|=4`, the only possible nontrivial projected order exceeding three is order four, and it can occur only for

\[
\boxed{e=1.}
\]

Thus every factor outside `H`, if one exists, is a simple order-four atom.

---

## 3. Two order-four atoms already fill the quotient

A quotient group of order four containing an element of order four is cyclic:

\[
\bar G\cong C_4.
\]

For a simple order-four atom `x`, its signed local set is

\[
\{0,x,-x\}
\]

in additive notation.

Two such local sets sum to all of `C_4`:

\[
\{0,\pm1\}+\{0,\pm1\}=C_4.
\]

That would make `bar R=bar G` and hit both targets.

Therefore a failed index-four box has at most one nontrivial quotient atom.

So there are only two abstract cases:

1. no prime factor of `C` lies outside `H`, hence `bar R={0}`;
2. exactly one simple order-four factor lies outside `H`, hence
   \[
   \bar R=\{0,1,3\},
   \]
   after orienting the generator.

We eliminate both.

---

## 4. The one-atom case is impossible

Assume

\[
\bar R=\{0,1,3\}\subset C_4.
\]

Its unique missing class is `2`.

Since all three natural excluded residues miss the box, they must all lie in that one class:

\[
\boxed{
[-1]=[-p^{-1}]=[-p]=2.
}
\]

Dividing the first two classes gives

\[
[p^{-1}]=0,
\]

so

\[
\boxed{p\in H.}
\]

Now use the exact identity

\[
4C=p+3r.
\]

Modulo `3r`,

\[
\boxed{4C\equiv p.}
\]

Passing to `C_4`, and writing `b=[2]`, gives

\[
2b+[C]=[p]=0.
\]

But the product `C` contains exactly one nontrivial quotient atom, so

\[
[C]=1\text{ or }3,
\]

an element of order four.

Thus

\[
2b=-[C]
\]

would make a doubled element of `C_4` equal to an element of order four.

That is impossible: every double in `C_4` is class `0` or `2` and has order at most two.

Therefore the one-atom index-four defect cannot occur.

---

## 5. The subgroup-box case forces p into H

Now assume every prime factor of `C` lies in `H`.

Then

\[
R\subseteq H.
\]

But `1 in R` and `R` is `H`-periodic, so

\[
H\subseteq R.
\]

Hence

\[
\boxed{R=H.}
\]

The identity `4C≡p` and `C in H` show that

\[
[p]=[4]=2[2]
\]

is a square in the order-four quotient.

The image of `-1` is nontrivial of order two, since `-1` is missed. Therefore in any order-four quotient its class is an order-two element.

If `[p]` were the nontrivial order-two class, then

\[
[-p^{-1}]=[-1]-[p]=0,
\]

so the Type-I target would lie in `H=R`, contradiction.

Thus target failure forces

\[
\boxed{[p]=0,\quad p\in H.}
\]

We now show that no index-four subgroup of `G` can contain `p`.

---

## 6. A quadratic nonresidue p cannot lie in an index-four subgroup

CRT gives

\[
G
\cong
C_2\times C_{r-1}.
\]

Choose a generator `g` of the cyclic `r`-component and write

\[
p\equiv g^a\pmod r.
\]

Because `r≡1 mod4` and `(r/p)=-1`, quadratic reciprocity gives

\[
\left(\frac pr\right)=-1.
\]

Therefore

\[
\boxed{a\text{ is odd}.}
\]

The mod-`3` coordinate of hard `p` is `+1`, so the order of `p` in `G` is exactly its order in the cyclic `r`-component:

\[
\operatorname{ord}_G(p)
=\frac{r-1}{\gcd(a,r-1)}.
\]

Since `a` is odd,

\[
\gcd(a,r-1)
\]

is odd. Hence `ord_G(p)` contains the **entire 2-primary part** of `r-1`.

Because `r≡1 mod4`, write

\[
2^v\parallel r-1,
\qquad v\ge2.
\]

Then

\[
2^v\mid\operatorname{ord}_G(p).
\]

If `H` had index four, its order would be

\[
|H|
=\frac{|G|}{4}
=\frac{2(r-1)}4
=\frac{r-1}{2},
\]

whose 2-primary part is only

\[
2^{v-1}.
\]

By Lagrange's theorem, an element of order divisible by `2^v` cannot lie in a subgroup whose order has only `2^{v-1}`.

Therefore

\[
\boxed{p\notin H.}
\]

This contradicts the subgroup-box failure condition from Section 5.

---

## 7. Theorem

Both possible index-four quotient geometries are impossible.

Hence:

### Composite-successor index-four elimination

For every Mordell-hard prime `p` and every external nonresidue prime

\[
r\equiv1\pmod4,
\qquad
(r/p)=-1,
\]

a failed exact two-target signed box at the natural successor shift

\[
k=3r
\]

cannot have full stabilizer index four:

\[
\boxed{
\{-p^{-1},-1\}\cap\mathcal R_{3r}((p+3r)/4)=\varnothing
\Longrightarrow
[(\mathbb Z/3r\mathbb Z)^\times:H]\ne4.
}
\]

Combined with `ES-COMPOSITE-SUCCESSOR-3R.md`:

- odd index is impossible;
- index two is possible only in the pure Eisenstein-split obstruction;
- **index four is impossible universally**.

Therefore in the non-Eisenstein-split branch, the first possible full-stabilizer defect is index at least six.

---

## 8. Next target

Finite proof-mining shows genuine index-six `3r` defects do occur, so the next theorem must classify rather than simply exclude them.

The natural target is a composite analogue of `FAB-INDEX6-COMBINED-DEFECT.md`: classify the order-six quotient under the mod-3 parity constraint and determine whether its unique primitive atom is again the forced external-nonresidue successor.
