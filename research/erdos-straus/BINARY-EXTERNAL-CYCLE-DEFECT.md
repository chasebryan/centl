# Binary defects on the full external-nonresidue factor cycle

**Status:** proved local reductions for both parity types of external prime vertices  
**Date:** 2026-08-15  
**Depends on:** `EXTERNAL-NR-FACTOR-CYCLE.md`, `BINARY-R-DIVISOR-COLLISION.md`, `BINARY-R-KNESER-DEFECT.md`  
**Claim boundary:** puts every vertex of the external-nonresidue factor cycle into a binary-rescue defect framework and gives a necessary classification of any full-stabilizer index-two defect at a `1 mod 4` vertex. The broader Eisenstein support condition is an exact sufficient condition for binary failure, but it does **not** imply that the full stabilizer has index two. The file does not prove that a full cycle cannot consist entirely of failed vertices and does not prove Erdős-Straus.

---

## 1. One binary numerator for every external prime vertex

Let `p` be Mordell-hard and let

\[
q<p,
\qquad q\text{ prime},
\qquad \left(\frac qp\right)=-1.
\]

Define

\[
\sigma(q)=
\begin{cases}
1,&q\equiv3\pmod4,\\
3,&q\equiv1\pmod4,
\end{cases}
\qquad
R_q=\sigma(q)q.
\]

Then `R_q=3 mod 4`. Put

\[
\boxed{A_q=\frac{p+R_q}{4}=\frac{p+\sigma(q)q}{4}},
\qquad
N_q=pA_q.
\]

Since `q<p`, one has `A_q<p`, and `gcd(R_q,N_q)=1`. Therefore the exact binary divisor-collision theorem applies at every external-prime vertex. The vertex is binary-rescued exactly when the signed divisor box of `N_q` modulo `R_q` contains `-1`.

---

## 2. Odd full-stabilizer quotient is impossible for every binary modulus

Let

\[
G=(\mathbb Z/R_q\mathbb Z)^\times,
\]

let `B` be the signed divisor box, and let

\[
H=\operatorname{Stab}(B).
\]

If `B` misses `-1`, the quotient `G/H` cannot have odd order. Indeed, the image of `-1` has order dividing two. In an odd-order quotient its image is trivial, so `-1 in H`. Since `1 in B` and `B` is `H`-periodic, `H subseteq B`, forcing `-1 in B`, contradiction.

Hence

\[
\boxed{
\text{binary failure}\Longrightarrow 2\mid[G:H].
}
\]

This holds for both `R_q=q` and `R_q=3q`.

---

## 3. The q = 3 mod 4 branch

If

\[
q\equiv3\pmod4,
\]

then `R_q=q` is prime and `BINARY-R-KNESER-DEFECT.md` applies directly. Every failure satisfies

\[
\boxed{[G:H]\ge6,\qquad [G:H]\equiv2\pmod4.}
\]

Every quadratic-nonresidue prime factor of

\[
A_q=\frac{p+q}{4}
\]

is visible outside `H`, and the sharp Kneser valuation-mass bound holds. Thus a `3 mod 4` cycle vertex has no index-two defect.

---

## 4. The q = 1 mod 4 branch

Now assume

\[
q\equiv1\pmod4.
\]

Then `R_q=3q`, and CRT gives

\[
G\cong(\mathbb Z/3\mathbb Z)^\times\times(\mathbb Z/q\mathbb Z)^\times.
\]

There are three nontrivial quadratic characters

\[
\varepsilon(x)=\left(\frac x3\right),
\qquad
\lambda(x)=\left(\frac xq\right),
\qquad
\chi(x)=\varepsilon(x)\lambda(x).
\]

For hard `p`,

\[
\varepsilon(p)=+1,
\qquad
\lambda(p)=-1,
\qquad
\chi(p)=-1.
\]

For the target `-1`,

\[
\varepsilon(-1)=-1,
\qquad
\lambda(-1)=+1,
\qquad
\chi(-1)=-1.
\]

---

## 5. Necessary classification of a full-stabilizer index-two defect

Assume a binary failure has **full stabilizer** of index two.

An index-two subgroup is the kernel of one of the three quadratic characters above.

### `H = ker(lambda)` is impossible

Since `lambda(-1)=+1`, the target lies in `H`, hence in `B`, contradiction.

### `H = ker(chi)` is impossible

Since `chi(p)=-1`, the exponent-one local set `{p^{-1},1,p}` already fills the two-element quotient. Thus the target quotient class is hit, contradiction.

### Only `H = ker(epsilon)` can survive

Therefore any full-stabilizer index-two failure must have

\[
\boxed{H=\ker\varepsilon.}
\]

If a prime factor `s|N_q` satisfies `s=2 mod 3`, then its local signed set fills the two-element quotient. Since hard `p=1 mod3`, index-two failure therefore requires

\[
\boxed{
\ell\mid A_q,\ \ell\text{ prime}
\Longrightarrow
\ell\equiv1\pmod3.
}
\]

This implication is universal:

\[
\boxed{
\text{full stabilizer index }2
\Longrightarrow
\text{all prime factors of }A_q\text{ are }1\pmod3.
}
\]

---

## 6. Eisenstein support is an exact coarse failure condition

There is a converse statement about **binary failure**, but not about the exact full-stabilizer index.

Assume every prime factor of

\[
A_q=\frac{p+3q}{4}
\]

is `1 mod3`. Since hard `p` is also `1 mod3`, every divisor of `N_q=pA_q` is `1 mod3`. Hence every signed divisor ratio lies in `ker epsilon`, while `-1=2 mod3`. Therefore

\[
\boxed{-1\notin B.}
\]

So Eisenstein support proves binary failure.

However, the full stabilizer of the failed box may be a proper subgroup of `ker epsilon`, giving a much larger quotient index. Thus the correct logic is

\[
\boxed{
\text{full index-2 defect}
\Longrightarrow
\text{all factors of }A_q\text{ are }1\pmod3
\Longrightarrow
\text{binary failure},
}
\]

and neither reverse implication is asserted for the full stabilizer index.

### Regression example

Take

\[
\boxed{p=1009,\qquad q=73}.
\]

Then

\[
A_q=\frac{1009+3\cdot73}{4}=307,
\]

and `307=1 mod3`. Hence Eisenstein support proves binary failure. Direct reconstruction of the signed box gives full-stabilizer quotient index

\[
\boxed{144,}
\]

not `2`.

This example is a permanent guard against conflating a coarse character obstruction with the exact stabilizer.

---

## 7. Parity refinement of the Eisenstein obstruction

If every prime factor of `A_q` is `1 mod3`, then `A_q` is odd, since `2=2 mod3`.

For hard `p=1 mod8` and `q=1 mod4`,

\[
A_q=\frac{p+3q}{4}
\]

is odd exactly when

\[
\boxed{q\equiv1\pmod8.}
\]

Thus every Eisenstein-support failure satisfies `q=1 mod8`. If `q=5 mod8`, then `A_q` is even, so the literal factor `2=2 mod3` is present and the coarse mod-3 obstruction cannot occur.

---

## 8. Consequence for the outgoing factor-cycle edge under Eisenstein support

At a `1 mod4` source vertex, `EXTERNAL-NR-FACTOR-CYCLE.md` chooses a prime factor

\[
s\mid A_q
\]

with `(s/p)=-1`. The edge-character theorem gives

\[
\left(\frac sq\right)=-\left(\frac{-3}{s}\right)
=-\left(\frac s3\right).
\]

Under Eisenstein support, `s=1 mod3`, so

\[
\boxed{\left(\frac sq\right)=-1.}
\]

Thus even when the mod-3 support obstruction already proves binary failure, the outgoing edge remains a quadratic nonresidue modulo both `p` and the source prime `q`.

---

## 9. Correct local alphabet for a failed factor cycle

Every failed external-nonresidue cycle vertex now has one of the following forms.

### Type I: `q = 3 mod 4`

An even Kneser defect of index at least six, with every `q`-nonresidue factor visible.

### Type II: `q = 1 mod 4`

The full stabilizer quotient is even. If it is exactly two, Eisenstein support is necessary. More generally, Eisenstein support itself is a sufficient binary-failure obstruction and can coexist with a much larger full-stabilizer quotient.

There are no odd-index full-stabilizer defects anywhere on the binary cycle.

---

## 10. Remaining cycle target

The remaining cycle theorem must not identify Eisenstein support with full index two.

A valid closure target is:

> Prove that no directed external-nonresidue factor cycle can carry binary failure at every vertex when every vertex has an even full-stabilizer defect, the `3 mod4` vertices obey the visible-nonresidue Kneser bounds, and any Eisenstein-support `1 mod4` vertex forces all factors of `(p+3q)/4` into `1 mod3` while its outgoing edge remains a quadratic nonresidue to the source.

This cycle program remains supplementary to the stronger exact two-target signed-box reformulation of the prime problem. The latter is now the preferred global frontier because either the Type-I target `-p^{-1}` or the Type-II target `-1` suffices.
