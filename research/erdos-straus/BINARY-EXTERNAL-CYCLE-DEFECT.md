# Binary defects on the full external-nonresidue factor cycle

**Status:** proved local classification for both parity types of external prime vertices  
**Date:** 2026-08-15  
**Depends on:** `EXTERNAL-NR-FACTOR-CYCLE.md`, `BINARY-R-DIVISOR-COLLISION.md`, `BINARY-R-KNESER-DEFECT.md`  
**Claim boundary:** puts every vertex of the external-nonresidue factor cycle into a binary-rescue defect framework and exactly classifies the only index-two defect that can occur at a `1 mod 4` vertex. It does not yet prove that a full cycle cannot consist entirely of failed vertices and therefore does not prove Erdős-Straus.

---

## 1. One binary numerator for every external prime vertex

Let `p` be Mordell-hard and let

\[
q<p,
\qquad
q\text{ prime},
\qquad
\left(\frac qp\right)=-1.
\]

Define

\[
\sigma(q)=
\begin{cases}
1,&q\equiv3\pmod4,\\
3,&q\equiv1\pmod4,
\end{cases}
\]

and put

\[
\boxed{R_q=\sigma(q)q.}
\]

Then

\[
\boxed{R_q\equiv3\pmod4.}
\]

The associated binary first denominator is

\[
\boxed{
A_q=rac{p+R_q}{4}
=rac{p+\sigma(q)q}{4},
}
\]

exactly the shifted factor used in `EXTERNAL-NR-FACTOR-CYCLE.md`.

Since `q<p`,

\[
A_q<p.
\]

Also

\[
\gcd(R_q,pA_q)=1.
\]

Therefore the exact binary divisor-collision theorem applies at **every** external-prime vertex, not only at the `3 mod4` vertices.

Put

\[
N_q=pA_q.
\]

The vertex is binary-rescued exactly when the signed divisor box of `N_q` modulo `R_q` contains `-1`.

---

## 2. Odd full-stabilizer quotient is impossible for every binary modulus

This statement does not require a prime modulus.

Let `G=(Z/R_q Z)^*`, let `B` be the signed divisor box, and let

\[
H=\operatorname{Stab}(B).
\]

If `B` misses `-1`, the quotient `G/H` cannot have odd order.

Indeed, the image of `-1` has order dividing `2`. In an odd-order quotient its image would be trivial, so

\[
-1\in H.
\]

Since `1 in B` and `B` is `H`-periodic,

\[
H\subseteq B,
\]

forcing `-1 in B`, contradiction.

Thus:

### Theorem — every binary cycle defect is even

At every external-prime cycle vertex,

\[
\boxed{
\text{binary failure}
\Longrightarrow
2\mid [G:H].
}
\]

This is true for both `R_q=q` and `R_q=3q`.

---

## 3. The q == 3 mod 4 branch

If

\[
q\equiv3\pmod4,
\]

then

\[
R_q=q
\]

is prime and `BINARY-R-KNESER-DEFECT.md` applies directly.

Every failure satisfies

\[
\boxed{
[G:H]\ge6,
\qquad
[G:H]\equiv2\pmod4.
}
\]

Every quadratic-nonresidue prime factor of

\[
A_q=\frac{p+q}{4}
\]

is visible outside `H`, and the sharp mass bound holds.

So a `3 mod4` cycle vertex has **no index-two escape hatch**.

---

## 4. The q == 1 mod 4 branch

Now assume

\[
q\equiv1\pmod4.
\]

Then

\[
R_q=3q.
\]

By CRT,

\[
G=(\mathbb Z/3q\mathbb Z)^\times
\cong
(\mathbb Z/3\mathbb Z)^\times
\times
(\mathbb Z/q\mathbb Z)^\times.
\]

There are three nontrivial quadratic characters on `G`:

\[
\varepsilon(x)=\left(\frac x3\right),
\qquad
\lambda(x)=\left(\frac xq\right),
\qquad
\chi(x)=\varepsilon(x)\lambda(x).
\]

Since `p` is Mordell-hard,

\[
p\equiv1\pmod3,
\]

and because `p≡1 mod4`, reciprocity gives

\[
\left(\frac pq\right)
=
\left(\frac qp\right)
=-1.
\]

Hence

\[
\boxed{
\varepsilon(p)=+1,
\qquad
\lambda(p)=-1,
\qquad
\chi(p)=-1.
}
\]

For the target `-1`:

\[
\boxed{
\varepsilon(-1)=-1,
\qquad
\lambda(-1)=+1,
\qquad
\chi(-1)=-1.
}
\]

---

## 5. Exact index-two classification at a 1 mod 4 vertex

Assume a binary failure has full stabilizer of index two.

An index-two subgroup is the kernel of one of the three quadratic characters above.

### H = ker(lambda) is impossible

Since

\[
\lambda(-1)=+1,
\]

we would have

\[
-1\in H\subseteq B,
\]

contradiction.

### H = ker(chi) is impossible

Here

\[
\chi(p)=-1,
\]

so the exponent-one local set

\[
\{p^{-1},1,p\}
\]

already projects onto both classes of `G/H`.

Therefore the full signed box projects onto the entire quotient, including the target class. Contradiction.

### Only H = ker(epsilon) can survive

Thus any index-two failure must have

\[
\boxed{H=\ker\varepsilon.}
\]

If any prime factor `s|N_q` satisfies

\[
s\equiv2\pmod3,
\]

then `epsilon(s)=-1`, and its local signed set again fills the two-element quotient, forcing rescue.

The hard prime `p` itself is `1 mod3`. Therefore index-two failure requires

\[
\boxed{
\ell\mid A_q,\ \ell\text{ prime}
\Longrightarrow
\ell\equiv1\pmod3.
}
\]

Conversely, if every prime factor of `A_q` is `1 mod3`, then every divisor of

\[
N_q=pA_q
\]

is `1 mod3`, so every signed divisor ratio lies in

\[
\ker\varepsilon.
\]

But

\[
-1\equiv2\pmod3.
\]

Hence the target is impossible.

Therefore:

### Theorem — Eisenstein index-two defect

For an external prime

\[
q\equiv1\pmod4,
\]

the binary collision modulo `3q` has full stabilizer index two **if and only if**

\[
\boxed{
\text{every prime factor of }
A_q=\frac{p+3q}{4}
\text{ is }1\pmod3.
}
\]

The defect subgroup is exactly

\[
\boxed{H=\ker(x/3).}
\]

This is the only possible index-two geometry on the `1 mod4` branch.

---

## 6. Consequence for the outgoing factor-cycle edge

At a `1 mod4` source vertex, `EXTERNAL-NR-FACTOR-CYCLE.md` chooses a prime factor

\[
s\mid A_q
\]

with

\[
\left(\frac sp\right)=-1.
\]

The edge-character theorem there gives

\[
\left(\frac sq\right)
=-\left(\frac{-3}{s}\right).
\]

For odd prime `s!=3`, quadratic reciprocity gives the standard identity

\[
\left(\frac{-3}{s}\right)
=\left(\frac s3\right).
\]

Hence

\[
\boxed{
\left(\frac sq\right)
=-\left(\frac s3\right).
}
\]

If the source vertex is in the index-two Eisenstein defect, every factor of `A_q` is `1 mod3`. In particular the chosen outgoing external edge satisfies

\[
\left(\frac s3\right)=+1.
\]

Therefore

\[
\boxed{
\left(\frac sq\right)=-1.
}
\]

So even though this edge is hidden by the mod-3 stabilizer, it remains a quadratic nonresidue modulo both `p` and the source prime `q`.

---

## 7. Local alphabet for a failed factor cycle

Every failed vertex on an external-nonresidue factor cycle now has one of only two broad forms.

### Type I: q == 3 mod 4

\[
\boxed{
\text{even Kneser defect of index at least 6, with every q-nonresidue factor visible.}
}
\]

### Type II: q == 1 mod 4

Either

\[
\boxed{
\text{index-two Eisenstein defect: all factors of }(p+3q)/4\text{ are }1\pmod3,
}
\]

or a higher even Kneser defect.

There are no odd-index defects anywhere on the binary cycle.

Thus a hypothetical all-failure cycle is no longer arbitrary. It is a finite cyclic word in a tightly constrained alphabet of even multiplicative defects, with only one exceptional low-index letter.

---

## 8. Next universal target

The remaining cycle theorem can be stated precisely:

> Prove that no directed external-nonresidue factor cycle can carry binary failure at every vertex when each vertex is constrained by the local defect classification above.

The lowest-hanging obstruction is the Eisenstein index-two sector. If a cycle contains a run of `1 mod4` index-two vertices, every corresponding shifted factorization is supported on primes `1 mod3`, while each outgoing edge remains a quadratic nonresidue to the source. A reciprocity/descent argument that forbids a closed run, or forces entry into a high-index visible defect whose Kneser room grows, would materially advance the all-prime proof.
