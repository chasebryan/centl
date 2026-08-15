# Prime-power stabilizer dichotomy: only powers of two are periodic

**Status:** proved exact theorem  
**Date:** 2026-08-15  
**Depends on:** `ES-SQUARE-TRAP-SIGNED-BOX-IDENTITY.md`, `MERSENNE-SHADOW-LATTICE.md`, `STRONG-ES-SHADOW-TOWER-STRUCTURAL-GAPS.md`  
**Claim boundary:** classifies the full stabilizer of every prime-power completed strong/Type-II layer. It does not classify non-prime-power stabilizers or prove universal Type-II coverage.

---

## 1. Prime-power completed layer

Let

\[
\boxed{a=\ell^E}
\]

with `ell` prime and

\[
E\ge1.
\]

Put

\[
\boxed{m=4\ell^E-1.}
\]

Because prime-power layers have no mixed orthants, the completed signed box is

\[
\boxed{
R_a
=
\{\ell^z\pmod m:-E\le z\le E\}.}
\]

Let

\[
d=\operatorname{ord}_m(\ell).
\]

The box is a consecutive symmetric exponent interval inside the cyclic subgroup

\[
\langle\ell\rangle\cong C_d.
\]

---

## 2. Stabilizer of a cyclic interval

Because

\[
1\in R_a,
\]

every stabilizer element belongs to `R_a`, hence to `\langle ell\rangle`.

If

\[
d>2E+1,
\]

then the exponent interval `[-E,E]` is a proper interval of length `2E+1` in `C_d`.

A proper consecutive interval in a cyclic group has trivial translation stabilizer.

Therefore

\[
\boxed{d>2E+1\Longrightarrow\operatorname{Stab}(R_a)=\{1\}.}
\]

If instead

\[
d\le2E+1,
\]

the consecutive interval covers every residue class modulo `d`, so

\[
R_a=\langle\ell\rangle
\]

and

\[
\boxed{\operatorname{Stab}(R_a)=\langle\ell\rangle.}
\]

Thus the prime-power stabilizer problem reduces exactly to the order comparison

\[
\boxed{d\le2E+1?}
\]

---

## 3. Binary case

Let

\[
\ell=2.
\]

Then

\[
\boxed{m=2^{E+2}-1.}
\]

By definition

\[
2^{E+2}\equiv1\pmod m.
\]

No smaller positive exponent can give `1`, because if `d<E+2` then

\[
0<2^d-1<2^{E+2}-1=m,
\]

so `m` cannot divide `2^d-1`.

Therefore

\[
\boxed{\operatorname{ord}_m(2)=E+2.}
\]

Since

\[
E+2\le2E+1
\]

for every `E>=1`, the completed box saturates the cyclic subgroup:

\[
\boxed{R_{2^E}=\langle2\rangle.}
\]

Hence

\[
\boxed{\operatorname{Stab}(R_{2^E})=\langle2\rangle.}
\]

This is exactly the periodic Mersenne family.

---

## 4. Odd-prime case: the order must exceed E

Now let

\[
\boxed{\ell\ge3\text{ be prime}.}
\]

Suppose for contradiction that

\[
\boxed{d\le2E+1.}
\]

Since

\[
\ell^E<m=4\ell^E-1,
\]

no exponent `d<=E` can satisfy

\[
m\mid\ell^d-1.
\]

Therefore

\[
\boxed{d=E+s}
\]

for some

\[
\boxed{1\le s\le E+1.}
\]

---

## 5. Combine the order relation with 4 ell^E = 1

Modulo `m`,

\[
4\ell^E\equiv1.
\]

Also

\[
\ell^{E+s}\equiv1.
\]

Substituting the first relation into the second gives

\[
\frac{\ell^s}{4}\equiv1\pmod m,
\]

hence

\[
\boxed{\ell^s\equiv4\pmod m.}
\]

We split by `s`.

---

## 6. The case s <= E is impossible by size

If

\[
s\le E,
\]

then

\[
0<\ell^s<m.
\]

Also

\[
0<4<m
\]

for every odd prime-power layer.

Thus the congruence

\[
\ell^s\equiv4\pmod m
\]

forces equality

\[
\ell^s=4.
\]

No odd prime power equals `4`.

Contradiction.

Therefore the only remaining possibility is

\[
\boxed{s=E+1.}
\]

---

## 7. The endpoint s = E+1 also fails

The congruence becomes

\[
\ell^{E+1}\equiv4\pmod m.
\]

Hence for some positive integer `t`,

\[
\boxed{
\ell^{E+1}-4
=t(4\ell^E-1).}
\]

Because

\[
4\ell^E-1>\ell^E
\]

and

\[
\ell^{E+1}-4<\ell^{E+1},
\]

we get

\[
\boxed{0<t<\ell.}
\]

Reduce the equation modulo `ell`:

\[
-4\equiv-t\pmod\ell.
\]

Thus

\[
\boxed{t\equiv4\pmod\ell.}
\]

For odd prime `ell>=5`, the size bound `0<t<ell` forces

\[
\boxed{t=4.}
\]

Substituting gives

\[
\ell^{E+1}-4
=16\ell^E-4,
\]

so

\[
\boxed{\ell=16,}
\]

impossible.

For `ell=3`, one has

\[
\ell^{E+1}<4\ell^E-1=m
\]

and the congruence would again force `3^{E+1}=4`, impossible.

Therefore no odd prime can satisfy

\[
d\le2E+1.
\]

---

## 8. Exact dichotomy

We have proved:

### Theorem — prime-power stabilizer dichotomy

For every prime `ell` and integer `E>=1`, let

\[
a=\ell^E.
\]

Then

\[
\boxed{
\operatorname{Stab}(R_a)\ne\{1\}
\iff
\ell=2.}
\]

More precisely:

### Powers of two

\[
\boxed{
\operatorname{Stab}(R_{2^E})
=\langle2\rangle,}
\]

with

\[
\operatorname{ord}_{2^{E+2}-1}(2)=E+2.
\]

### Odd prime powers

\[
\boxed{
\operatorname{Stab}(R_{\ell^E})
=\{1\}
\qquad(\ell\text{ odd prime}).}
\]

Thus the binary/Mersenne family is uniquely periodic among all prime-power completed layers.

---

## 9. Shadow consequence

The shadow-tower theorem says an ancestor stabilizer creates infinite multiplicative structural-gap descendants.

For odd prime-power bases there is no nontrivial stabilizer direction. Their multiplicative shadow descendants can therefore arise only from identity-class extension primes

\[
r\equiv1\pmod{4\ell^E-1}.
\]

For powers of two, every prime residue in the cyclic subgroup

\[
\langle2\rangle
\]

is a stabilizer direction and can participate in the larger Mersenne shadow tower.

This sharply separates binary prime powers from all odd prime powers in the completed ancestry graph.

---

## 10. Relation to the computational signal

Finite computation had suggested that nontrivial completed full stabilizers are rare and, through the tested range, appeared only at powers of two.

The theorem proves that observation **completely on the prime-power locus**.

The remaining open stabilizer question is therefore restricted to genuinely multi-prime layer indices.
