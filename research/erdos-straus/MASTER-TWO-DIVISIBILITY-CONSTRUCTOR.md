# Two-divisibility constructor for the fab master equation

**Status:** proved exact sufficient construction  
**Date:** 2026-08-15  
**Depends on:** `FAB-DUAL-DESCENT-SYSTEM.md`, `FAB-UNBOUNDED-DIVISOR-RATIO-CERTIFICATE.md`  
**Claim boundary:** this converts one four-variable certificate search into two elementary divisibilities and generates explicit congruence families. It does not prove that one such family covers every Mordell-hard prime and therefore does not prove Erdős-Straus.

---

## 1. Constructor

Let `p` be a positive odd integer. Choose positive integers

\[
B,Q,s
\]

such that

\[
\boxed{s\mid pQ+B}
\]

and

\[
\boxed{4BQ\mid p+s.}
\]

Define

\[
\boxed{A=\frac{pQ+B}{s}}
\]

and

\[
\boxed{c=\frac{p+s}{4BQ}}.
\]

Then `A,c` are positive integers.

The two defining divisibilities imply the exact master identity

\[
\boxed{4ABcQ=B+p(A+Q).}
\]

### Proof

Because `sA=pQ+B`,

\[
A(p+s)
=pA+sA
=pA+pQ+B
=B+p(A+Q).
\]

But `p+s=4BQc`, so

\[
A(p+s)=4ABQc.
\]

Therefore

\[
4ABcQ=B+p(A+Q).
\]

QED.

---

## 2. Immediate Erdős-Straus certificate

Put

\[
\boxed{k=4ABc-p.}
\]

From the master identity,

\[
Qk
=Q(4ABc-p)
=B+pA.
\]

Hence

\[
\boxed{k\mid B+pA}
\]

with quotient exactly `Q`.

Also

\[
\boxed{p+k=4ABc.}
\]

Thus the unbounded sufficient fab identity applies with

\[
a=B,
\qquad b=A,
\qquad q=Q,
\qquad t=c.
\]

The resulting positive decomposition is

\[
\boxed{
\frac4p
=
\frac1{ABc}
+
\frac1{BQc}
+
\frac1{ApQc}.
}
\]

Therefore:

### Two-divisibility rescue theorem

If there exist positive `B,Q,s` satisfying

\[
\boxed{
s\mid pQ+B,
\qquad
4BQ\mid p+s,
}
\]

then `p` satisfies the Erdős-Straus equation.

No primality condition on `s`, `Q`, or the resulting `k` is required.

---

## 3. Congruence-family form

For fixed `B,Q,s`, the two conditions are simply

\[
\boxed{p\equiv-s\pmod{4BQ}}
\]

and

\[
\boxed{Qp\equiv-B\pmod s.}
\]

Thus every fixed triple `(B,Q,s)` defines either an empty congruence system or an explicit arithmetic progression of integers solved by one closed formula.

If

\[
g=\gcd(Q,s),
\]

the second congruence is soluble exactly when

\[
\boxed{g\mid B.}
\]

After division by `g`, it becomes one residue class modulo `s/g`; compatibility with the first congruence is then an ordinary CRT test.

This gives a systematic generator of exact ES congruence families directly from the master equation.

---

## 4. Relation to the dual system

The variables are exactly the dual variables already present in `FAB-DUAL-DESCENT-SYSTEM.md`.

The relation

\[
sA=pQ+B
\]

is equivalent to

\[
\boxed{A+Q=Bd}
\]

for the hidden dual cofactor after the corresponding variable identification, while

\[
p+s=4BQc
\]

supplies the square-overlap side of the same certificate geometry.

The point of the present theorem is operational: instead of searching four positive variables subject to

\[
4ABcQ=B+p(A+Q),
\]

one may choose the three simpler variables `B,Q,s` and check only two divisibilities.

---

## 5. Finite-cover falsification checkpoint

As a theorem-mining test, small triples were generated and converted to their exact CRT progressions. Restricting to families whose combined moduli divide

\[
840\cdot11\cdot13\cdot17\cdot19,
\]

a search over `B,Q<=30` and `s<=100` produced `3,126` distinct compatible progression families in that modulus envelope.

Their union does **not** cover the six Mordell-hard progressions. Large exact residue cores remain in every hard class.

This finite negative result is not a theorem that no finite covering exists. It only rules out the tempting small-parameter cover tested here and prevents confusing the constructor itself with a completed proof.

---

## 6. Research use

The theorem creates a clean fork for the remaining attack:

1. **covering route:** find a genuinely complete finite or structured infinite family of triples `(B,Q,s)`;
2. **descent route:** assume the two divisibilities fail throughout a controlled family and translate that failure into factor/character restrictions;
3. **external-nonresidue route:** choose `s` or the resulting certificate divisor from the synchronized external-nonresidue packet and use the hard shield to force the second divisibility.

The useful object is now the pair

\[
\boxed{
s\mid pQ+B,
\qquad
p\equiv-s\pmod{4BQ},
}
\]

rather than the original four-variable master equation.
