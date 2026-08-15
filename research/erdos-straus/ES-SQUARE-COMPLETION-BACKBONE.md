# Prime-modulus backbone and unbounded depth for the square-completed Type-II layers

**Status:** proved theorem  
**Date:** 2026-08-15  
**Depends on:** `ES-SQUARE-COMPLETION-TRAP-GEOMETRY.md`, `ES-SQUARE-TRAP-SIGNED-BOX-IDENTITY.md`, `PRIME-MODULUS-BACKBONE.md`  
**Imported classical tools:** Chinese remainder theorem and Dirichlet's theorem on primes in reduced arithmetic progressions  
**Claim boundary:** proves arbitrarily large exact finite first-hit depths for the square-completed Type-II congruence system. It does not imply failure of universal Type-II coverage and does not prove Erdős--Straus.

---

## 1. Completed trap layers

For

\[
a\ge1
\]

put

\[
\boxed{m_a=4a-1}
\]

and define the square-completed Type-II trap

\[
\boxed{
S_a
=
\{-4D\pmod{m_a}:D\mid a^2\}.}
\]

The ordinary López trap satisfies

\[
T_a\subseteq S_a.
\]

The first question is whether the much larger completed layers might accidentally contain the neutral residue `1`, which would destroy the old CRT exact-depth construction.

They do not.

---

## 2. The neutral residue is never trapped

### Theorem

For every

\[
a\ge1,
\]

one has

\[
\boxed{1\notin S_a.}
\]

### Proof

Suppose instead that there exists

\[
D\mid a^2
\]

with

\[
-4D\equiv1\pmod{4a-1}.
\]

Then for some positive integer `q`,

\[
\boxed{4D+1=q(4a-1).}
\]

Because the left side is `1 mod 4` and `4a-1≡3 mod4`,

\[
\boxed{q\equiv3\pmod4.}
\]

Write the canonical squarefree-root factorization

\[
D=sb^2,
\qquad
 a=sbc,
\]

with `s,b,c` positive.

The assumed equation becomes

\[
1+4sb^2=(4sbc-1)q.
\]

Rearrange:

\[
1+q
=4sbcq-4sb^2
=4sb(cq-b).
\]

Put

\[
\boxed{t=cq-b.}
\]

Since the left side is positive,

\[
\boxed{t>0.}
\]

Thus

\[
\boxed{q=4sbt-1.}
\]

But from the definition of `t`,

\[
\boxed{b+t=cq\ge q.}
\]

On the other hand, for positive integers `s,b,t`,

\[
q=4sbt-1
\ge4bt-1
>b+t.
\]

The last strict inequality holds for all `b,t>=1`.

This is a contradiction. Therefore

\[
\boxed{1\notin S_a.}
\]

QED.

---

## 3. The target residue -1 is always trapped

Take

\[
D=a.
\]

Since

\[
a\mid a^2,
\]

this is a valid square divisor.

Moreover

\[
-4D=-4a\equiv-1\pmod{4a-1}.
\]

Hence

\[
\boxed{-1\in S_a\quad\text{for every }a.}
\]

So every layer contains the familiar central Type-A/B spine while still excluding the neutral residue.

---

## 4. Exact-depth theorem at a prime target modulus

Let `a` be such that

\[
\boxed{q=4a-1}
\]

is a prime greater than `7`.

Define

\[
L_{a-1}
=
\operatorname{lcm}
\left(
840,
\{4j-1:1\le j<a\}
\right).
\]

Since `q` is prime and larger than every earlier modulus, it divides none of them. Since `q>7`, it also does not divide `840`.

Therefore

\[
\boxed{\gcd(q,L_{a-1})=1.}
\]

By CRT there is a unique residue class modulo `qL_{a-1}` satisfying

\[
\boxed{
x\equiv1\pmod{L_{a-1}},
\qquad
x\equiv-1\pmod q.}
\]

This residue is reduced modulo `qL_{a-1}`.

Dirichlet's theorem therefore gives infinitely many primes `p` in this class.

For every earlier layer `j<a`,

\[
p\equiv1\pmod{4j-1}.
\]

By the neutral-residue theorem,

\[
1\notin S_j,
\]

so no earlier completed layer captures `p`.

At the target layer,

\[
p\equiv-1\pmod q
\]

and

\[
-1\in S_a.
\]

Thus the first square-completed Type-II congruence hit occurs exactly at `a`.

Finally, `840|L_{a-1}`, so all these primes satisfy

\[
\boxed{p\equiv1\pmod{840}.}
\]

Therefore:

### Theorem — square-completed prime-modulus exact depth

Whenever

\[
4a-1>7
\]

is prime, there exist infinitely many Mordell-hard primes whose first square-completed Type-II layer is exactly `a`.

---

## 5. Unbounded completed depth

There are infinitely many primes

\[
q\equiv3\pmod4.
\]

Every such prime `q>7` has the form

\[
q=4a-1
\]

for

\[
a=\frac{q+1}{4}.
\]

Applying the exact-depth theorem gives arbitrarily large finite first-hit depths.

Hence:

### Corollary

\[
\boxed{
\text{the square-completed Type-II first-hit depth is unbounded}.}
\]

This remains true even when restricted to primes in the single Mordell-hard class

\[
\boxed{p\equiv1\pmod{840}.}
\]

---

## 6. The completed prime-modulus backbone

Define

\[
\boxed{
\mathcal B_{\rm sq}
=
\left\{
\frac{q+1}{4}:
q>7\text{ prime},
\ q\equiv3\pmod4
\right\}.}
\]

Then every depth in `B_sq` is realized infinitely often as an exact square-completed first-hit depth among Mordell-hard primes.

This is the same index set as the old López prime-modulus backbone, but it now belongs to the complete symmetric Type-II layer.

The completion can dramatically reduce the depth of individual primes, but it cannot produce a universal constant ceiling.

---

## 7. Finite census versus theorem

A finite search can therefore show substantial compression without suggesting boundedness.

The current exact finite census through

\[
p\le50,000,000
\]

finds all `93,457` Mordell-hard primes captured by square-completed layers no deeper than

\[
\boxed{a=624.}
\]

The unique deepest observed prime is

\[
\boxed{p=2,031,121.}
\]

Its completed witness is

\[
\boxed{
a=624,
\qquad
D=576,
\qquad
m_a=2495.}
\]

Indeed

\[
576\mid624^2
\]

and

\[
2,031,121+4\cdot576
=2,033,425
=2495\cdot815.
\]

The divisor `576` is mixed relative to

\[
624=2^4\cdot3\cdot13:
\]

\[
576=2^6\cdot3^2
\]

lies above the midpoint in the `2` and `3` coordinates and below it in the `13` coordinate.

For comparison, the first López Type-A/B hit for the same prime is

\[
\boxed{1403.}
\]

Thus square completion more than halves the observed depth of this finite record prime.

These are finite computational facts, not a bound theorem. The exact-depth result above proves that later primes must eventually exceed every fixed depth.

---

## 8. Strategic consequence

The completed system has two simultaneous features:

1. **strong finite compression:** mixed-sign square divisors can solve hard primes much earlier than the López boundary orthants;
2. **provable unbounded latency:** prime-modulus CRT coordinates force arbitrarily large exact first-hit depths.

Therefore the all-prime proof cannot be a bounded-depth theorem.

The right target is structural coverage:

\[
\boxed{
\text{prove every prime has some completed layer, while accepting that the first such layer is unbounded}.}
\]

This matches the lesson already learned from the López depth spectrum, now in the complete square-completed Type-II geometry.
