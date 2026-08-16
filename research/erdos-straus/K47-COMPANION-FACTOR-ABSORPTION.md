# Exact companion-factor absorption from `k=47`

**Status:** proved exact cross-shift reduction  
**Date:** 2026-08-16  
**Depends on:** `ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md`, `K47-FORCED6-HARD-REDUCTION.md`, `K47-ONE-PACKET-COMPANION-FILTER.md`  
**Claim boundary:** this proves a generic Type-I divisor trigger and applies it to remove two center classes from the negative-character fixed-`k=47` miss family. It does not prove that the remaining states are eliminated, does not prove Erdős–Straus, and makes no literature-priority claim.

---

## 1. Generic divisor trigger

Let

\[
p\equiv1\pmod4,
\qquad
k\equiv3\pmod4,
\qquad
\gcd(p,k)=1,
\]

and put

\[
C_k=\frac{p+k}{4}.
\]

Suppose `d` is a positive divisor of `C_k` satisfying

\[
\boxed{4d\equiv-1\pmod k.}
\]

Then

\[
\boxed{-p^{-1}\in\mathcal R_k(C_k).}
\]

Hence the fixed shift `k` gives a Type-I Erdős–Straus solution.

### Proof

Write

\[
C_k=\prod_i r_i^{e_i},
\qquad
d=\prod_i r_i^{f_i},
\qquad 0\le f_i\le e_i.
\]

Then

\[
\frac d{C_k}
=
\prod_i r_i^{f_i-e_i}.
\]

Every exponent `f_i-e_i` lies in `[-e_i,0]`, so

\[
\boxed{dC_k^{-1}\in\mathcal R_k(C_k).}
\]

Also

\[
p=4C_k-k\equiv4C_k\pmod k,
\]

therefore

\[
-p^{-1}
\equiv
-(4C_k)^{-1}
\equiv
(-4^{-1})C_k^{-1}
\pmod k.
\]

The hypothesis `4d ≡ -1 (mod k)` says `d ≡ -4^{-1} (mod k)`. Thus

\[
\boxed{
\frac d{C_k}
\equiv
-p^{-1}
\pmod k,
}
\]

which is exactly the Type-I signed-box target. ∎

---

## 2. Explicit Type-I parameters

Write

\[
C_k=dt.
\]

The proof above uses the signed ratio

\[
\rho=\frac1t.
\]

In the factor realization of `ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md`, take

\[
B=1,
\qquad D=t,
\qquad T=d.
\]

Since `4d ≡ -1 (mod k)`, we have

\[
p=4dt-k\equiv-t\pmod k,
\]

so

\[
A=\frac{t+p}{k}
\]

is an integer. The corresponding decomposition is

\[
\boxed{
\frac4p
=
\frac1{Adp}
+
\frac1{dt}
+
\frac1{Adt}.
}
\]

Thus the divisor trigger is not merely a residue-box certificate; it gives explicit Type-I parameters.

---

## 3. Companion-modulus bridge

Let `q` and `k` both be `3 mod 4`, with `q>k`, and define

\[
C_q=\frac{p+q}{4},
\qquad
C_k=\frac{p+k}{4}.
\]

Then

\[
\boxed{
C_k=C_q-\frac{q-k}{4}.
}
\]

Therefore

\[
q\mid C_k
\quad\Longleftrightarrow\quad
C_q\equiv\frac{q-k}{4}\pmod q
\quad\Longleftrightarrow\quad
p\equiv-k\pmod q.
\]

If, in addition,

\[
\boxed{k\mid 4q+1,}
\]

then `d=q` satisfies the generic divisor trigger because

\[
4q\equiv-1\pmod k.
\]

Hence:

> **Companion-factor absorption lemma.**  
> If `q ≡ k ≡ 3 (mod 4)`, `q>k`, `k | (4q+1)`, and `p ≡ -k (mod q)`, then `q | C_k` and the fixed shift `k` is a Type-I hit.

This statement is range-free.

---

## 4. Specialization to `q=47`

For `q=47`,

\[
4q+1=189=3^3\cdot7.
\]

The positive divisors below 47 that are `3 mod 4` are

\[
\boxed{k=3,7,27.}
\]

Their companion gaps and base-5 center logs modulo 47 are

| earlier `k` | gap `(47-k)/4` | base-5 log of gap mod 47 | consequence |
|---:|---:|---:|---|
| 3 | 11 | 7 | center log 7 forces `47 | C_3`, hence a `k=3` Type-I hit |
| 7 | 10 | 19 | center log 19 forces `47 | C_7`, hence a `k=7` Type-I hit |
| 27 | 5 | 1 | center log 1 forces `47 | C_27`, hence a `k=27` Type-I hit |

Equivalently, for primes `p ≡ 1 (mod 4)`, the three congruence classes are

\[
\boxed{
\begin{aligned}
p&\equiv185\pmod{188} &&\Longrightarrow k=3\text{ hit},\\
p&\equiv181\pmod{188} &&\Longrightarrow k=7\text{ hit},\\
p&\equiv161\pmod{188} &&\Longrightarrow k=27\text{ hit}.
\end{aligned}}
\]

No finite search is used in these implications.

---

## 5. Effect on the exact negative-character `k=47` miss family

The forced-6 closure has exactly 80 negative-character fixed-`k=47` miss states.

Their center-log multiplicities are

\[
\boxed{
\begin{array}{c|rrrrrrrrrrr}
\text{center log}&1&3&9&11&19&21&27&29&37&39&45\\
\hline
\text{states}&13&2&7&9&13&3&3&11&10&6&3
\end{array}}
\]

In particular:

- center log `7` does not occur at all in the abstract negative-miss family;
- center log `19` contributes exactly 13 states, all absorbed universally by `k=7`;
- center log `1` contributes exactly 13 states, all absorbed universally by `k=27`.

Therefore the exact cross-shift reduction is

\[
\boxed{
80\longrightarrow54
}
\]

negative-character abstract miss states.

This is a theorem-level reduction. It is not inferred from the 10M prime census.

Direction by direction, the surviving abstract one-packet state counts become

| one-packet log `r` | before | removed by `k=7`/`27` | after |
|---:|---:|---:|---:|
| 1 | 7 | 1 | 6 |
| 7 | 2 | 1 | 1 |
| 9 | 13 | 6 | 7 |
| 11 | 3 | 1 | 2 |
| 17 | 6 | 1 | 5 |
| 19 | 10 | 3 | 7 |
| 27 | 11 | 5 | 6 |
| 29 | 3 | 0 | 3 |
| 35 | 3 | 0 | 3 |
| 37 | 13 | 5 | 8 |
| 45 | 9 | 3 | 6 |
| **total** | **80** | **26** | **54** |

---

## 6. Finite 10M cross-check, separated from the proof

In the complete Mordell-hard prime census through `10,000,000`:

- 822 primes miss fixed `k=47` with negative character;
- 102 of those have center log `1`, and every one hits `k=27`;
- 95 have center log `19`, and every one hits `k=7`;
- thus this exact symbolic absorption accounts for 197 of the 822 finite targets, leaving 625 for the next theorem-mining stage.

The same implications hold more broadly in the complete hard-prime census through 10M:

- all 441 hard primes with `C_47 ≡ 5 (mod 47)` hit `k=27`;
- all 449 with `C_47 ≡ 10 (mod 47)` hit `k=7`;
- all 464 with `C_47 ≡ 11 (mod 47)` hit `k=3`.

These finite counts are regression evidence only. The proofs are the divisor-trigger and companion-factor arguments above.

---

## 7. New frontier

The negative-character fixed-`k=47` proof target is no longer the full 80-state family.

After exact companion-factor absorption, the remaining range-free target is

\[
\boxed{54\text{ abstract miss states}.}
\]

The next search should look for analogous forced divisors of earlier companions `C_k=C_47-d`, possibly using divisors other than 47, and for small exact state conditions that force a divisor `d_k | C_k` with

\[
4d_k\equiv-1\pmod k.
\]

That is the structural version of the finite singleton-state signal.

Erdős–Straus remains open.
