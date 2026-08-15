# Primitive sextic defect chains and the neighbor-square recurrence

**Status:** proved local transition theorem with exact finite witness  
**Date:** 2026-08-15  
**Depends on:** `ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md`, `FAB-TWO-TARGET-KNESER.md`, `FAB-INDEX6-COMBINED-DEFECT.md`, `EXTERNAL-NR-FACTOR-CYCLE.md`  
**Claim boundary:** this gives an exact recurrence for consecutive primitive index-six failures at `3 mod 4` external prime shifts. Consecutive primitive failures do occur, so this note does not prove Erdős--Straus.

---

## 1. Primitive index-six edge

Let `p` be Mordell-hard and let

\[
q\equiv3\pmod4,
\qquad
\left(\frac qp\right)=-1.
\]

Assume the exact two-target signed box at the prime shift `k=q` misses both Type I and Type II and has full stabilizer index six.

Then `FAB-INDEX6-COMBINED-DEFECT.md` gives

\[
\boxed{
\frac{p+q}{4}=rS
}
\]

where

- `r` is a simple prime factor;
- `r` is the unique quadratic-nonresidue factor relative to `p`;
- modulo `q`, the class of `r` generates
  \[
  (\mathbb Z/q\mathbb Z)^\times/((\mathbb Z/q\mathbb Z)^\times)^6\cong C_6;
  \]
- every prime factor of `S` is a sixth power modulo `q`.

Thus the external factor edge is forced:

\[
\boxed{q\longrightarrow r.}
\]

If the source itself has index six, then necessarily

\[
\boxed{q\equiv7\pmod{12}.}
\]

---

## 2. What the previous vertex becomes at the successor

Assume now that the forced successor also satisfies

\[
r\equiv3\pmod4
\]

and that the exact two-target box at `k=r` also has a primitive index-six failure.

Because `r` divides `(p+q)/4`,

\[
p+q\equiv0\pmod r.
\]

Therefore

\[
\boxed{q\equiv-p\pmod r.}
\]

But `-p` is the inverse orientation of the exact Type-I target at the successor modulus `r`.

For an index-six combined failure, the quotient box occupies the classes

\[
0,\ \pm1
\]

while the inverse Type-I targets occupy

\[
\boxed{\pm2}
\]

and Type II occupies class `3`.

Hence the previous vertex has exact quotient order three:

\[
\boxed{
q\,((\mathbb Z/r\mathbb Z)^\times)^6
\text{ has order }3.}
\]

Equivalently,

\[
\boxed{
q\text{ is a quadratic residue but a cubic nonresidue modulo }r.}
\]

By contrast, the forward exceptional factor at the previous vertex has quotient order six:

\[
\boxed{
r\text{ is both a quadratic and cubic nonresidue modulo }q.}
\]

Thus a consecutive primitive edge has the asymmetric sextic signature

\[
\boxed{
\begin{array}{c|cc}
 & \text{quadratic} & \text{cubic}\\
\hline
r\pmod q & - & -\\
q\pmod r & + & -
\end{array}}
\]

which is consistent with ordinary quadratic reciprocity for two `3 mod 4` primes.

---

## 3. Three consecutive primitive vertices

Suppose one step farther that

\[
q_-\longrightarrow q\longrightarrow q_+
\]

are three consecutive external primes, all congruent to `3 mod 4`, and the exact two-target signed box has primitive index-six failure at the middle vertex `q`.

The forward exceptional factor `q_+` occupies one of the quotient classes

\[
\pm1.
\]

The previous vertex satisfies

\[
q_-\equiv-p\pmod q
\]

and therefore occupies one of the inverse Type-I classes

\[
\pm2.
\]

In the cyclic quotient `C_6`, every class `±2` is the square or inverse square of a class `±1`.

Therefore:

### Theorem — neighbor-square recurrence

There exists a sign

\[
\varepsilon\in\{+1,-1\}
\]

and a unit `u mod q` such that

\[
\boxed{
q_-
\equiv
q_+^{\,2\varepsilon}u^6
\pmod q.}
\]

Equivalently,

\[
\boxed{
q_-\,q_+^{-2\varepsilon}
\in
((\mathbb Z/q\mathbb Z)^\times)^6.}
\]

Thus every internal primitive sextic vertex obeys an exact second-neighbor recurrence modulo sixth powers.

This is stronger than the pair of quadratic/cubic character statements: it identifies the complete quotient relation in `C_6`.

---

## 4. Concrete consecutive-defect witness

Consecutive combined primitive defects genuinely occur.

Take

\[
\boxed{p=808369.}
\]

This is Mordell-hard because

\[
808369\equiv289\pmod{840}.
\]

### Vertex q = 43

\[
\frac{p+43}{4}
=202103
=11\cdot19\cdot967.
\]

The exact two-target signed box misses both targets and has full stabilizer index

\[
\boxed{6.}
\]

The unique external nonresidue factor is

\[
\boxed{19,}
\]

so the edge is

\[
43\to19.
\]

With primitive root `3 mod 43`, quotient exponents modulo six may be chosen so that

\[
19\mapsto1,
\]

while

\[
-p^{-1}\mapsto2,
\qquad
-1\mapsto3,
\qquad
-p\mapsto4.
\]

### Vertex q = 19

\[
\frac{p+19}{4}
=202097
=7\cdot28871.
\]

Again the exact two-target signed box misses both targets and has full stabilizer index

\[
\boxed{6.}
\]

The unique external factor is

\[
\boxed{28871,}
\]

so

\[
19\to28871.
\]

With primitive root `2 mod 19`, the quotient classes modulo six satisfy

\[
28871\mapsto5,
\]

and the previous vertex

\[
43\equiv-p\pmod{19}
\]

has class

\[
\boxed{4=2\cdot5\pmod6.}
\]

Thus the neighbor-square recurrence holds explicitly.

### Next vertex

At

\[
q=28871,
\]

the exact two-target box still misses, but the full stabilizer index jumps to

\[
\boxed{28870,}
\]

rather than remaining six.

So the finite chain begins

\[
\boxed{
43\xrightarrow{\,6\,}19\xrightarrow{\,6\,}28871\xrightarrow{\,28870\,}\cdots
}
\]

where the labels indicate the defect index at the source vertex.

---

## 5. Consequence for the proof search

The conjecture

\[
\text{“primitive index six cannot occur twice consecutively”}
\]

is false.

The correct local object is the recurrence

\[
q_{i-1}\equiv q_{i+1}^{\pm2}\cdot(\text{sixth power})\pmod{q_i}.
\]

A cycle-level proof must therefore exploit one of:

1. higher reciprocity for the complete sextic quotient data;
2. incompatibility of these recurrences around a closed cycle;
3. forced growth or inflation of the full stabilizer index;
4. a transition to the composite `3r` parity-fibre regime when a successor is `1 mod 4`.

The exact witness above shows why a one-edge contradiction is too strong, but also shows the phenomenon to explain: primitive sextic behavior can repeat locally and then collapse into a much larger defect quotient.
