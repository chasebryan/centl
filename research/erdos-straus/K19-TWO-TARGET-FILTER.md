# Exact two-target filter at the prime shift `k=19`

**Status:** proved exact group-theoretic filter  
**Date:** 2026-08-15  
**Depends on:** `ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md`, `K15-TWO-TARGET-FILTER.md`, `Q11-TYPE-I-COMPANION.md`  
**Claim boundary:** classifies both exact targets at the next corridor prime after `15`. It does not prove that a `3,7,11,15` survivor must hit at `19`, and therefore does not prove Erdős--Straus.

---

## 1. Setup

Let `p` be Mordell-hard and `p\neq19`. Put

\[
C=\frac{p+19}{4}.
\]

Then `C` is an integer. Because every hard class satisfies `p\equiv1\pmod8`,

\[
p+19\equiv20\equiv4\pmod8,
\]

so `C` is odd. Also `p\not\equiv0\pmod{19}`, hence `19\nmid C` and every prime factor of `C` is a unit modulo `19`.

Unlike `q=7` (forced factor `2`) and `q=11` (forced factor `3`), there is **no prime that divides `C` for every hard class**. The six classes give

\[
\begin{array}{c|c|c}
p\bmod840 & C\bmod210 & \text{forced primes}\\
\hline
1 & 5 & 5\\
121 & 35 & 5,7\\
169 & 47 & \text{none}\\
289 & 77 & 7\\
361 & 95 & 5\\
529 & 137 & \text{none}
\end{array}
\]

The classification is therefore by the residue support of `C`, not by a single forced generator.

---

## 2. The unit group and the two targets

The group \((\mathbb Z/19\mathbb Z)^\times\) is cyclic of order eighteen. The residue `2` is a primitive root. Quadratic residues are

\[
\boxed{
Q=\{1,4,5,6,7,9,11,16,17\}.
}
\]

The complementary nonresidues are

\[
N=\{2,3,8,10,12,13,14,15,18\}.
\]

Since `19\equiv3\pmod4`, `-1` is a nonresidue:

\[
-1\equiv18\pmod{19}.
\]

That is the Type-II target. The Type-I target is `-p^{-1}\bmod{19}`. Quadratic reciprocity of the Jacobi symbol gives

\[
\Bigl(\frac{-p^{-1}}{19}\Bigr)
=
\Bigl(\frac{-1}{19}\Bigr)
\Bigl(\frac p{19}\Bigr)
=
-\Bigl(\frac p{19}\Bigr).
\]

Thus the Type-I target lies in `Q` if and only if `p` is a nonresidue modulo `19`. Explicitly:

\[
\begin{array}{c|c|c}
p\bmod19 & -p^{-1}\bmod19 & \text{side}\\
\hline
1 & 18 & N\\
4 & 14 & N\\
5 & 15 & N\\
6 & 3 & N\\
7 & 8 & N\\
9 & 2 & N\\
11 & 12 & N\\
16 & 13 & N\\
17 & 10 & N\\
2 & 9 & Q\\
3 & 6 & Q\\
8 & 7 & Q\\
10 & 17 & Q\\
12 & 11 & Q\\
13 & 16 & Q\\
14 & 4 & Q\\
15 & 5 & Q\\
18 & 1 & Q
\end{array}
\]

The nine residue classes in the first block are exactly `Q`. On those classes both exact targets are nonresidues.

---

## 3. The QR-trap

Write \(\mathcal R_{19}(C)\) for the signed divisor box of `C` modulo `19`. Write `K` for the signed box of the quadratic-residue part of `C` (so `K=\{1\}` if every prime factor is a nonresidue).

### Theorem — QR-trap misses Type II

If every prime factor of `C` lies in `Q`, then \(\mathcal R_{19}(C)\subseteq Q\), hence

\[
\boxed{-1\notin\mathcal R_{19}(C).}
\]

### Proof

`Q` is a subgroup. Every generator is already in `Q`, so the signed box they generate stays in `Q`. The Type-II target `18` lies outside `Q`. QED.

### Theorem — QR-trap Type I

Under the same hypothesis,

\[
\boxed{
-p^{-1}\notin\mathcal R_{19}(C)
\quad\text{whenever}\quad
\Bigl(\frac p{19}\Bigr)=+1.
}
\]

If instead \(\bigl(\frac p{19}\bigr)=-1\), the Type-I target lies in `Q`, and Type I hits if and only if that residue already lies in the (possibly thin) box `K`.

### Proof

On a residue class the Type-I target is a nonresidue, by the table in Section 2, hence cannot lie in a box contained in `Q`. On a nonresidue class the target is in `Q`, so membership is exactly membership in `K`. QED.

In particular, if the QR box is the full subgroup `Q`, then a QR-trap combined miss occurs if and only if `p` itself is a residue modulo `19`. Type I then contributes extra coverage precisely on the nine nonresidue classes of `p`.

---

## 4. Forced `5` and `7` fill `Q` on one hard class

Both `5` and `7` are quadratic residues modulo `19`. Their simple local sets are

\[
\{5^{-1},1,5\}=\{1,4,5\},
\qquad
\{7^{-1},1,7\}=\{1,7,11\}.
\]

The product is already the whole subgroup:

\[
\{1,4,5\}\cdot\{1,7,11\}
=
Q.
\]

### Theorem — class `121`

If `p\equiv121\pmod{840}`, then `5\mid C` and `7\mid C`, so `K=Q`. Consequently:

1. if every prime factor of `C` is a quadratic residue modulo `19`, then Type II misses, and Type I hits if and only if \(\bigl(\frac p{19}\bigr)=-1\);
2. if some prime factor of `C` is a nonresidue, then `Q` translated by that nonresidue fills the nonresidue coset, so Type II hits and `p` satisfies Erdős--Straus at `k=19`.

Combined miss on this class is therefore exactly

\[
\boxed{
\text{every prime factor of }C\text{ is in }Q
\quad\text{and}\quad
\Bigl(\frac p{19}\Bigr)=+1.
}
\]

### Proof

`p=840t+121` gives `C=210t+35=5\cdot7\cdot(6t+1)`. The product of the two local sets is `Q` as computed above. A nonresidue factor multiplies `Q` onto `N`, which contains `18`. The QR-trap case is Section 3 with `K=Q`. QED.

On the other four classes that force only `5` or only `7`, the QR box contains `{1,4,5}` or `{1,7,11}` respectively and need not be all of `Q`.

---

## 5. A single nonresidue inverse pair

The nonresidues pair under inversion:

\[
\{2,10\},\quad\{3,13\},\quad\{8,12\},\quad\{14,15\},\quad\{18\}.
\]

A prime `r\equiv18\pmod{19}` contributes `-1` itself, so Type II hits.

For each of the other four pairs, a single such prime to the first power has local set of size three, none of which is `18`. Type II then hits if and only if the QR box already contains a definite companion residue.

### Theorem — one inverse pair

Suppose every nonresidue prime factor of `C` is congruent to `r` or `r^{-1}` modulo `19`, for a single `r\in N\setminus\{18\}`, and write `K` for the QR box. Then

\[
-1\in\mathcal R_{19}(C)
\quad\Longleftrightarrow\quad
\gamma(r)\in K,
\]

where

\[
\begin{array}{c|c}
r\bmod19 & \gamma(r)\\
\hline
2 & 9\\
10 & 17\\
3 & 6\\
13 & 16\\
8 & 7\\
12 & 11\\
14 & 4\\
15 & 5
\end{array}
\]

### Proof

The nonresidue elements of the box are `{r,r^{-1}}\cdot K`. This set contains `18` if and only if `K` contains `18\cdot r^{-1}` or `18\cdot r`. Those two companions are the displayed values of `\gamma` (they coincide with the two rows of each inverse pair). QED.

Two distinct inverse pairs, with no extra QR mass, produce only four nonresidue residues and still miss `18`, because a product of two nonresidues is a residue. Extra QR mass or a factor `18\bmod{19}` is required to finish Type II in that case.

---

## 6. Combined miss theorem

### Theorem

For a Mordell-hard prime `p\neq19`, both exact targets miss at `k=19` if and only if `-1` and `-p^{-1}` both lie outside \(\mathcal R_{19}(C)\). Structurally this is one of the following:

1. **QR-trap, residue side:** every prime factor of `C` is in `Q`, and \(\bigl(\frac p{19}\bigr)=+1\);
2. **QR-trap, thin nonresidue side:** every prime factor of `C` is in `Q`, \(\bigl(\frac p{19}\bigr)=-1\), and the Type-I target does not lie in the thin QR box `K`;
3. **nonresidue packet that misses `18`:** the nonresidue support of `C` does not place `18` in the signed box (Section 5), and the Type-I target also misses that box.

In every other case at least one target hits, and `p` satisfies Erdős--Straus.

On the single hard class `p\equiv121\pmod{840}`, cases 2 and 3 with a nonresidue factor cannot occur: case 2 is absorbed into a full-`Q` Type-I hit, and a nonresidue factor is a Type-II hit. Combined miss on that class is exactly case 1.

---

## 7. Corridor position

The integer `(p+19)/4` is the next neighbour after the four already-classified forms

\[
A,\quad A+1,\quad A+2,\quad A+3
\qquad\bigl(A=(p+3)/4\bigr).
\]

A hypothetical counterexample that has escaped `q=3,7,11` and `k=15` must place this fifth consecutive integer into a QR-trap of residue type, a thin QR box that misses the Type-I target, or a nonresidue packet that misses both `18` and `-p^{-1}`.

Type I **does** contribute extra coverage at `k=19`, unlike `q=3` and `q=7`, and like `q=11`. The extra coverage is exactly the QR-trap on nonresidue classes of `p` for which the QR box contains the Type-I target, together with those nonresidue packets whose box happens to contain `-p^{-1}` but not `18`.

---

## 8. Finite signal

Through `400{,}000` there are `1005` Mordell-hard primes above `19`. Of these, `331` are QR-traps and `500` are a single nonresidue inverse pair. The QR-trap Type-II lemma, the class-`121` filling of `Q`, and the companion table `\gamma` have no exceptions in that range. The identities are proved above; the count is only a census.

The next exact corridor target is the Type-I companion to the existing `q=23` Type-II theorem.

Independent checks live in `verify_two_target_companions.py`.
