# Prime-index spectrum of the square-completed Type-II layers

**Status:** proved exact classification  
**Date:** 2026-08-15  
**Depends on:** `ES-SQUARE-COMPLETION-TRAP-GEOMETRY.md`, `ES-SQUARE-COMPLETION-BACKBONE.md`, `THEORY.md`  
**Claim boundary:** classifies square-completed minimal-depth realizability when the layer index itself is prime. It does not classify composite layer indices and does not prove universal Erdős--Straus coverage.

---

## 1. Setup

For every positive layer index `a`, put

\[
m_a=4a-1
\]

and define the square-completed Type-II trap

\[
\boxed{
S_a=\{-4D\pmod{m_a}:D\mid a^2\}.}
\]

Call `a` an **exact completed depth** if there exists a prime `p` whose first hit among the layers `S_1,S_2,...` occurs exactly at `a`.

The prime-modulus backbone already proves that every `a` with `m_a` prime greater than `7` is realized infinitely often, including by Mordell-hard primes.

Here we prove the converse when `a` itself is prime.

---

## 2. A prime-index completed layer has only three parameters

Let

\[
\boxed{a\text{ be prime}.}
\]

Then

\[
\operatorname{Div}(a^2)=\{1,a,a^2\}.
\]

Therefore

\[
S_a
=
\{-4,-4a,-4a^2\}
\pmod{m_a}.
\]

Since

\[
4a\equiv1\pmod{m_a},
\]

we have

\[
-4a\equiv-1
\]

and

\[
-4a^2
=-a(4a)
\equiv-a.
\]

Hence:

### Lemma — three-point prime layer

For prime `a`,

\[
\boxed{
S_a=\{-4,-1,-a\}\pmod{4a-1}.}
\]

---

## 3. Reduction along every modulus-ancestry edge

Suppose

\[
1\le j<a
\]

and

\[
\boxed{m_j=4j-1\mid m_a=4a-1.}
\]

Since both

\[
4a\equiv1\pmod{m_j}
\]

and

\[
4j\equiv1\pmod{m_j},
\]

subtracting gives

\[
4(a-j)\equiv0\pmod{m_j}.
\]

The modulus `m_j` is odd, so `4` is invertible modulo it. Thus

\[
\boxed{a\equiv j\pmod{m_j}.}
\]

Reducing the three-point prime layer gives

\[
S_a\bmod m_j
=
\{-4,-1,-j\}.
\]

But all three residues lie in the earlier completed layer `S_j`:

- `D=1` gives `-4`;
- `D=j` gives
  \[
  -4j\equiv-1;
  \]
- `D=j^2` gives
  \[
  -4j^2\equiv-j.
  \]

Therefore:

### Theorem — prime-index ancestry absorption

If `a` is prime and

\[
4j-1\mid4a-1,
\]

then

\[
\boxed{
S_a\bmod(4j-1)
\subseteq
S_j.}
\]

In fact the reduction is exactly the three canonical residues

\[
\boxed{\{-4,-1,-j\}.}
\]

Thus **every modulus-ancestry edge into a prime-index completed layer is a complete direct shadow**.

---

## 4. Every composite modulus 4a-1 has an earlier 3 mod 4 prime divisor

Assume now that

\[
a\text{ is prime}
\]

and

\[
m_a=4a-1
\]

is composite.

Because

\[
m_a\equiv3\pmod4,
\]

its prime factorization contains at least one prime factor

\[
q\equiv3\pmod4
\]

with odd total multiplicity.

Since `m_a` is composite, such a prime factor may be chosen with

\[
q<m_a.
\]

Write

\[
\boxed{q=4j-1}
\]

with

\[
j=\frac{q+1}{4}.
\]

Then

\[
1\le j<a
\]

and

\[
4j-1=q\mid4a-1.
\]

By the prime-index ancestry theorem,

\[
S_a\bmod q\subseteq S_j.
\]

Therefore every candidate captured by layer `a` is already captured by the earlier layer `j`.

Hence:

### Corollary — composite-modulus prime layers are structural gaps

If

\[
\boxed{a\text{ is prime},
\qquad
4a-1\text{ is composite},}
\]

then `a` cannot be a minimal square-completed depth for any integer, and in particular for any prime.

The entire layer is directly redundant.

---

## 5. Converse: prime modulus gives infinitely many exact first hits

If instead

\[
\boxed{4a-1>7\text{ is prime},}
\]

`ES-SQUARE-COMPLETION-BACKBONE.md` applies the CRT, the neutral-residue theorem

\[
1\notin S_j,
\]

and Dirichlet's theorem to produce infinitely many primes whose first completed hit is exactly `a`.

Those primes may all be chosen in the Mordell-hard class

\[
\boxed{p\equiv1\pmod{840}.}
\]

---

## 6. Exact classification

Combining the two directions gives the main result.

### Theorem — prime-index completed spectrum

Let `a` be prime. Then

\[
\boxed{
a\text{ is an exact square-completed first-hit depth}
\iff
4a-1\text{ is prime}.}
\]

Moreover, in the positive case the depth is realized by infinitely many Mordell-hard primes.

In the negative case the whole completed layer is directly shadowed by an earlier layer associated with any `3 mod 4` prime divisor of `4a-1`.

---

## 7. Relation to the prime-modulus backbone

The prime-modulus backbone is therefore not merely a sufficient infinite family inside the completed spectrum.

Among **prime-valued layer indices**, it is complete.

The remaining completed-depth spectrum problem is entirely concentrated on composite layer indices:

\[
\boxed{
\text{new completed spectrum beyond the backbone}
\subseteq
\{a:\ a\text{ composite}\}.}
\]

This is a substantial sharpening of the spectrum geometry.

---

## 8. Why the completed layer makes the proof short

The theorem depends crucially on the square completion.

At a prime index `a`, the full Type-II square layer contains the three natural divisor parameters

\[
1,\ a,\ a^2,
\]

which reduce along ancestry to

\[
1,\ j,\ j^2.
\]

Those are automatically available in every earlier completed layer `S_j`.

In centered signed-box language, the prime layer is the one-dimensional box

\[
\{-1,0,1\}
\]

and ancestry sends its three points directly into the canonical three-point subset of the earlier box.

This is the first exact theorem obtained by combining the new square-completed internal geometry with the old modulus-ancestry shadow framework.

---

## 9. Next theorem target

The natural next question is the composite-index analogue:

> For which composite `a` does every completed signed exponent vector reduce into an earlier completed layer along some ancestry divisor of `4a-1`?

The prime-index theorem suggests separating the composite spectrum by the factorization of both

\[
a
\]

and

\[
4a-1.
\]

The most promising first families are:

1. semiprime `a=uv`, where the mixed region has low dimension;
2. prime powers, where `S_a=T_a` and no mixed completion occurs;
3. indices whose modulus `4a-1` has a small `3 mod4` prime divisor, giving a strong ancestry coordinate.
