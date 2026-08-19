# Exact structural reduction at the composite shift `k=27`

**Status:** proved structural reduction; full combined-miss classification still open  
**Date:** 2026-08-16  
**Depends on:** `ES-TWO-TARGET-DIVISOR-SQUARE.md`, `ES-BINARY-LANE-I-EQUIVALENCE.md`, `K23-TWO-TARGET-FILTER.md`  
**Claim boundary:** this proves the hard-prime wheel law, the pure-QR combined-miss branch, a full-QR-part hit criterion, and an exact four-companion criterion when the total nonresidue valuation is two. It does not yet classify every `k=27` miss and does not prove Erdős–Straus.

---

## 1. Setup

Let `p` be Mordell-hard and write

\[
P=\frac{p-1}{4}.
\]

Every Mordell-hard prime satisfies

\[
p\equiv1\pmod{24},
\]

so

\[
\boxed{P\equiv0\pmod6.}
\]

At shift `k=27`, put

\[
\boxed{C=\frac{p+27}{4}=P+7.}
\]

Hence

\[
\boxed{C\equiv1\pmod6.}
\]

In particular, `C` is odd and coprime to `27`.

---

## 2. Logarithmic coordinates modulo 27

The unit group

\[
G=(\mathbb Z/27\mathbb Z)^\times
\]

is cyclic of order `18`, with primitive root `2`.

Write

\[
\log x=\log_2 x\pmod{18}
\]

for unit residues modulo `27`.

The powers of `2` are

\[
1,2,4,8,16,5,10,20,13,26,25,23,19,11,22,17,7,14.
\]

Thus

\[
\boxed{\log(-1)=9.}
\]

The quadratic-residue subgroup is the even-log subgroup

\[
\boxed{Q=2\mathbb Z/18\mathbb Z}
\]

of order `9`.

There is also a particularly simple arithmetic description:

\[
\boxed{
x\in Q
\iff
x\equiv1\pmod3
}
\]

for every unit `x mod27`.

Indeed every square unit is `1 mod3`, and there are exactly nine unit classes `1 mod3`, equal to the size of `Q`.

---

## 3. The hard-prime wheel forces even nonresidue valuation

Let

\[
C=\prod_i q_i^{e_i}.
\]

A prime factor `q_i` is a quadratic nonresidue modulo `27` exactly when

\[
q_i\equiv2\pmod3.
\]

Define the total nonresidue valuation

\[
\boxed{
E_{NR}(C)
=
\sum_{q^e\parallel C,\ q\equiv2\ (3)}e.
}
\]

Since

\[
C\equiv1\pmod3,
\]

the number of `2 mod3` factors counted with multiplicity must be even. Therefore

\[
\boxed{E_{NR}(C)\equiv0\pmod2.}
\]

So the `k=27` corridor cannot contain exactly one nonresidue valuation unit. It moves from pure QR support directly to packets of size `2,4,6,...`.

---

## 4. The two exact targets in C18 coordinates

Let

\[
c=\log C\pmod{18}.
\]

The signed Lane-I box in log coordinates is

\[
\mathcal S(C)
=
\left\{
\sum_i z_i\log q_i:
-e_i\le z_i\le e_i
\right\}
\subseteq C_{18}.
\]

### Type II

Type II asks for `-1` in the signed box, hence

\[
\boxed{9\in\mathcal S(C).}
\]

### Type I

By the divisor-square theorem, Type I asks for a divisor `d|C^2` satisfying

\[
4d\equiv-1\pmod{27}.
\]

Because

\[
4^{-1}\equiv7\pmod{27},
\]

the fixed divisor residue is

\[
\boxed{d\equiv20\pmod{27}.}
\]

And

\[
\boxed{\log20=7.}
\]

Therefore, in divisor-log coordinates, Type I is the fixed odd target

\[
\boxed{7.}
\]

For comparison, in signed-box coordinates `p==4C mod27`, so

\[
\log(-p^{-1})
=9-(2+c)
=\boxed{7-c}.
\]

---

## 5. Divisor-log box

Let

\[
\mathcal D(C)
=
\left\{
\sum_i f_i\log q_i:
0\le f_i\le2e_i
\right\}.
\]

This is exactly the log set of the divisors of `C^2`.

Since the interval `[0,2e_i]` is the translate by `e_i` of `[-e_i,e_i]`,

\[
\boxed{
\mathcal D(C)=c+\mathcal S(C).
}
\]

Thus the two exact targets are

\[
\boxed{7\in\mathcal D(C)}
\]

for Type I and

\[
\boxed{9+c\in\mathcal D(C)}
\]

for Type II.

The parity law from Section 3 implies `c` is even, so both divisor-log targets are odd.

---

## 6. Pure-QR trap

### Theorem — pure quadratic support misses both targets

If every prime factor of `C` is a quadratic residue modulo `27`, then

\[
\boxed{\text{Type I misses and Type II misses at }k=27.}
\]

### Proof

Every prime-factor log is even, so every element of `D(C)` is even. Both targets `7` and `9+c` are odd. Therefore neither target lies in `D(C)`. QED.

So pure QR support is an exact combined-miss branch, not merely a Type-II obstruction.

---

## 7. Full QR divisor mass plus any nonresidue forces a hit

Factor

\[
C=C_QC_N,
\]

where `C_Q` contains all QR prime powers and `C_N` all nonresidue prime powers.

Let

\[
\mathcal D_Q
\]

be the divisor-log set of `C_Q^2`. It is contained in the even subgroup.

### Theorem — full-QR fill

If

\[
\boxed{\mathcal D_Q=2\mathbb Z/18\mathbb Z}
\]

and

\[
E_{NR}(C)>0,
\]

then both odd target classes occur in `D(C)`. In particular `k=27` hits.

### Proof

A nonresidue prime factor has odd log. Choosing exponent `1` of that factor in a divisor of `C_N^2` produces at least one odd class `o`. Adding the full even subgroup `D_Q` to `o` gives the entire odd coset of `C_18`. Both `7` and `9+c` are odd, hence both occur. QED.

Therefore every non-pure combined miss must have a **thin QR divisor-log box**.

---

## 8. Exact four-companion criterion when E_NR=2

The first possible non-pure case is

\[
\boxed{E_{NR}(C)=2.}
\]

Split the two nonresidue valuation units into odd log classes

\[
\alpha,\beta\in\{1,3,5,7,9,11,13,15,17\},
\]

allowing

\[
\alpha=\beta
\]

when the same residue class supplies both valuation units.

Each valuation unit contributes divisor exponent `0,1,2`. Therefore the nonresidue divisor-log contribution is

\[
\{u\alpha+v\beta:
 u,v\in\{0,1,2\}\}.
\]

The odd elements of this set are exactly

\[
\boxed{
\mathcal O(\alpha,\beta)
=
\{\alpha,\beta,\alpha+2\beta,2\alpha+\beta\}
\pmod{18}.
}
\]

When `alpha=beta`, this collapses to the two-element set

\[
\{\alpha,3\alpha\}.
\]

Because `D_Q` is even and both targets are odd, only these odd nonresidue contributions can participate in a hit.

### Theorem — four companions

Assume `E_NR(C)=2`. Let `c=log C`. Then:

Type I hits if and only if

\[
\boxed{
\mathcal D_Q
\cap
\bigl(7-\mathcal O(\alpha,\beta)\bigr)
\ne\varnothing.
}
\]

Type II hits if and only if

\[
\boxed{
\mathcal D_Q
\cap
\bigl(9+c-\mathcal O(\alpha,\beta)\bigr)
\ne\varnothing.
}
\]

Hence both targets miss if and only if

\[
\boxed{
\mathcal D_Q
\cap
\bigl(7-\mathcal O(\alpha,\beta)\bigr)
=
\mathcal D_Q
\cap
\bigl(9+c-\mathcal O(\alpha,\beta)\bigr)
=
\varnothing.
}
\]

### Proof

Write

\[
\mathcal D(C)=\mathcal D_Q+\mathcal D_N.
\]

Both exact targets are odd. Since `D_Q` is even, a representation of either target must use an odd element of `D_N`. Under total nonresidue valuation two, those odd elements are exactly `O(alpha,beta)`. Rearranging the two target equations gives the displayed intersections. QED.

This converts the first non-pure `k=27` branch into at most four explicit even companion tests.

---

## 9. Finite 10M signal on the full hard-prime universe

On the preserved `p<=10,000,000` Mordell-hard corpus (`20,513` primes), the exact standalone `k=27` hit relation and independent factorization give:

| E_NR(C) | hits | misses |
|---:|---:|---:|
| 0 | 0 | 11,926 |
| 2 | 6,063 | 2,401 |
| 4 | 117 | 6 |

No larger `E_NR` occurs in that finite range.

The first row is explained universally by the pure-QR theorem. The other rows are finite counts only.

In particular, the six observed `E_NR=4` misses show that **nonresidue valuation four is not automatically sufficient**. A full `k=27` theorem must still control thin QR mass and higher nonresidue packets rather than asserting a false valuation cutoff.

---

## 10. Finite signal after the six classified shifts

The first six exact Lane-I shifts

\[
3,7,11,15,19,23
\]

leave exactly

\[
\boxed{308}
\]

hard primes through `10^7`.

At `k=27`, those 308 split as:

\[
\boxed{185\text{ pure-QR misses}},
\]

\[
\boxed{91\text{ non-pure hits}},
\]

and

\[
\boxed{32\text{ non-pure misses}}.
\]

Every non-pure member of this six-shift residual has

\[
E_{NR}(C)=2
\]

on this finite domain. Thus the new four-companion theorem exactly contains the entire observed non-pure residual geometry after `k=23`.

This last statement is finite evidence, not a proof that six-shift survivors universally satisfy `E_NR<=2`.

---

## 11. What remains for a full k=27 classification

The exact remaining task is now narrow:

1. classify the possible thin QR divisor-log sets `D_Q` in `C_18`;
2. combine them with the four-companion criterion for `E_NR=2`;
3. classify the analogous odd contribution sets for `E_NR>=4`;
4. determine whether the six earlier shift-failure laws impose additional restrictions on these packets.

The most promising route is **not** to enumerate residue classes of `p`. It is to classify the small additive subsets of the even subgroup `C_9` that can occur as `D_Q`, then test their translated companion sets.

---

Erdős–Straus remains open. This note reduces the next layer to a finite-group packet problem without claiming that the packet problem is already solved.
