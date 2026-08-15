# Exact two-target filter at the composite shift `k=15`

**Status:** proved exact group-theoretic filter  
**Date:** 2026-08-15  
**Depends on:** `ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md`, `FAB-HARD-FIRST-FILTERS.md`  
**Claim boundary:** classifies the next corridor position after `3,7,11`. It does not prove that a `3,7,11` survivor must hit at `15`, and therefore does not prove Erdős--Straus.

---

## 1. Setup

Let `p` be Mordell-hard and put

\[
C=\frac{p+15}{4}=A+3,
\qquad
A=\frac{p+3}{4}.
\]

Then `C` is an integer. Because `p≡1\pmod8`,

\[
p+15\equiv0\pmod8,
\]

so

\[
\boxed{2\mid C.}
\]

Hard residues modulo `5` are `1` or `4`, so `5\nmid C`. Also `C\equiv1\pmod3` whenever `A` is supported on primes `1\bmod3`, and in any case `3` need not divide `C`. Thus every odd prime factor of `C` is a unit modulo `15`.

---

## 2. The two-primary subgroup

The unit group

\[
(\mathbb Z/15\mathbb Z)^\times
=
\{1,2,4,7,8,11,13,14\}
\]

has order eight. The residue `2` generates a cyclic subgroup of order four:

\[
\boxed{
H=\langle2\rangle=\{1,2,4,8\}.
}
\]

The two exact targets live outside `H`:

\[
-1\equiv14\pmod{15}.
\]

The six hard classes occupy only two residues modulo `15`. Each is compatible with `p≡1\pmod3` and `p\equiv1` or `4\pmod5`:

\[
\boxed{p\equiv1\text{ or }4\pmod{15}.}
\]

The Type-I targets are then

\[
\begin{array}{c|c}
p\bmod15 & -p^{-1}\bmod15\\
\hline
1 & 14\\
4 & 11
\end{array}
\]

Neither `14` nor `11` lies in `H`.

---

## 3. The signed box stays in `H` exactly on `H`-supported factorizations

### Theorem — `H`-trap

The signed divisor box of `C` modulo `15` is contained in `H` if and only if every prime factor of `C` is congruent to `1,2,4`, or `8` modulo `15`.

In that case the box equals `H` as soon as `v_2(C)\ge2`, and equals `{1,2,4,8}` or the three-element set `{1,2,8}` according as `4` is or is not independently generated; in all such cases

\[
\boxed{
H_{\mathrm{thin}}\subseteq\mathcal R_{15}(C)\subseteq H,
}
\]

where `H_{\mathrm{thin}}=\{1,2,8\}` is the simple local set of the forced factor `2`.

### Proof

Every prime `r\equiv1,2,4,8\pmod{15}` is already an element of `H`, so the signed box they generate stays in `H`. Conversely a prime outside `H` contributes a residue in `{7,11,13,14}` and the box meets the complement. QED.

---

## 4. Combined miss on the `H`-trap

### Theorem — `H`-trap misses both targets

If every prime factor of `C` lies in `{1,2,4,8}\bmod{15}`, then

\[
\boxed{
-1\notin\mathcal R_{15}(C)
\qquad\text{and}\qquad
-p^{-1}\notin\mathcal R_{15}(C).
}
\]

### Proof

The box lies in `H`, while both hard-class Type-I targets and the Type-II target lie in `{11,14}=(\mathbb Z/15\mathbb Z)^\times\setminus H`. QED.

Thus on the `H`-trap, Type I contributes no extra coverage.

---

## 5. Prime factors outside `H` are almost always immediate hits

Let `r` be an odd prime divisor of `C`.

### `r\equiv14\pmod{15}`

Then `-1` itself lies in the signed box. Type II hits.

### `r\equiv7\pmod{15}`

One has `7^{-1}\equiv13`, so the local set is `{1,7,13}`. The forced factor `2` multiplies `7` to `14`. Type II hits.

### `r\equiv13\pmod{15}`

The local set is again `{1,7,13}`, and `2\cdot7\equiv14`. Type II hits.

### `r\equiv11\pmod{15}`

Here `11^{-1}\equiv11`, so the local set is `{1,11}`.

- If `v_2(C)\ge2`, then `4` lies in the box and `4\cdot11\equiv14`. Type II hits.
- If `v_2(C)=1` and every other prime factor lies in `H`, the box contains
  \[
  \{1,2,8\}\cdot\{1,11\}=\{1,2,7,8,11,13\}
  \]
  and misses `14`. Type II therefore misses. Type I hits if and only if the target is `11`, i.e. if and only if
  \[
  \boxed{p\equiv4\pmod{15}.}
  \]
  For `p\equiv1\pmod{15}` both targets miss.

The last bullet is the only combined-miss geometry that uses a prime outside `H`.

---

## 6. Exact combined miss theorem

### Theorem

For a Mordell-hard prime `p`, both exact targets miss at `k=15` if and only if one of the following holds:

1. **`H`-trap:** every prime factor of `(p+15)/4` is `1,2,4`, or `8\bmod{15}`;
2. **thin `11`-packet:** `v_2(C)=1`, `p\equiv1\pmod{15}`, every nonresidue prime factor of `C` is `11\bmod{15}`, and there is no prime factor `7,13,14\bmod{15}`.

In every other case at least one of `-1` and `-p^{-1}` lies in the signed box, and `p` satisfies Erdős--Straus.

---

## 7. Corridor position

The integer `(p+15)/4` is the consecutive neighbour

\[
A+3
\]

of the three already-classified forms `A`, `A+1`, `A+2`. A hypothetical counterexample that has escaped `q=3,7,11` must therefore place four consecutive integers in prescribed multiplicative semigroups, of which the fourth is the `H`-trap or the thin `11`-packet above.

---

## 8. Finite signal

Through `500{,}000`, every Mordell-hard `3,7,11` residual that misses `k=15` does so by the `H`-trap; the thin `11`-packet did not occur in that range. Through `2{,}000{,}000` the first two-target hit after a combined `3,7,11` miss is supported on

\[
\{15,19,23,27,31,35,39,43,47,51,55,59\},
\]

with `15`, `19`, and `23` accounting for the great majority. No residual in that range was unresolved by shift `59`.

This is finite evidence only. The next exact target is a combined classification of the prime shift `k=19`.
