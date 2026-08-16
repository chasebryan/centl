# Forced-6 hard-prime reduction at `k=47`

**Status:** proved universal reduction plus exact finite-group state closure  
**Date:** 2026-08-16  
**Depends on:** `K47-TWO-TARGET-FILTER.md`, `STRONG-ES-PRIME-SHIFT-KNESER-DICHOTOMY.md`, `FIXED-SHIFT-JACOBI-PARITY.md`  
**Machine certificate:** `classify_k47_forced6_states.py`  
**Claim boundary:** this sharply reduces the fixed-47 state universe for Mordell-hard primes. It does not prove the cross-shift exclusion candidate and does not prove Erdős–Straus.

---

## 1. Universal forced factor

Every Mordell-hard prime satisfies

\[
p\equiv1\pmod{24}.
\]

Hence

\[
p+47\equiv48\equiv0\pmod{24},
\]

so

\[
\boxed{6\mid C_{47}:=\frac{p+47}{4}.}
\]

Thus every actual hard-prime state at shift 47 contains at least one factor `2` and at least one factor `3`.

In the primitive-root-5 coordinate modulo 47,

\[
\boxed{\lambda(2)=18,\qquad\lambda(3)=20.}
\]

Both are even, so both forced factors are quadratic residues.

---

## 2. Forced starting state

The generic exact state machine begins at the empty state and allows every possible factor direction.

For a hard prime we can instead begin after one mandatory `2` and one mandatory `3` occurrence.

The exact forced starting state is obtained by the two transitions

\[
T_{18}T_{20}(\{0\},0).
\]

Its divisor-log set has size

\[
\boxed{9}
\]

and its center log is

\[
\boxed{38\pmod{46}.}
\]

From that state, allowing all additional valuation directions still covers every possible hard-prime factorization because further powers of 2 and 3 are simply additional occurrences of the same transitions.

---

## 3. Exact hard-prime state closure

Close the forced starting state under all 46 valuation directions.

The least closed system contains only

\[
\boxed{1,079}
\]

states, compared with 61,134 states in the completely generic fixed-47 closure.

Testing the exact two targets gives

\[
\boxed{883\text{ hit states}}
\]

and

\[
\boxed{196\text{ combined-miss states}.}
\]

### Theorem — forced-6 hard-state reduction

For every Mordell-hard prime `p`, the exact `k=47` state of `(p+47)/4` belongs to this 1,079-state closure.

Therefore every actual hard-prime miss at 47 belongs to the exact 196-row forced-6 miss table.

This is range-free. No finite prime bound enters the reduction.

---

## 4. Pure quadratic branch shrinks to 66 states

Restrict all additional factor directions to quadratic residues, i.e. even logs.

Starting from the forced `2·3` packet gives exactly

\[
\boxed{66}
\]

pure-QR states.

All 66 miss both targets.

Thus the pure splitting branch of the safe-prime Kneser dichotomy is represented by a very small exact state family once the hard congruence is imposed.

---

## 5. Only one- and two-packet nonresidue defects remain

Minimize the number of **additional** odd-log valuation occurrences needed to represent each forced-6 miss state.

The exact distribution is

\[
\boxed{
\begin{array}{c|r}
\text{minimum added NR units}&\text{miss states}\\
\hline
0&66\\
1&80\\
2&50
\end{array}}
\]

No forced-6 miss state needs three or more additional nonresidue units in a minimum representative.

This is much sharper than the generic fixed-47 state table, whose minimum representative can require up to four nonresidue units.

The parity split is exactly the Jacobi law:

\[
\boxed{116\text{ misses with }(47/p)=+1,}
\]

\[
\boxed{80\text{ misses with }(47/p)=-1.}
\]

The negative-character branch is therefore **exactly a one-packet state problem** in this reduced coordinate.

That is the key compression for the cross-shift proof search.

---

## 6. Safe-prime interpretation

Since

\[
47=2\cdot23+1
\]

is a safe prime, `STRONG-ES-PRIME-SHIFT-KNESER-DICHOTOMY.md` says every Type-II miss is either:

1. pure quadratic splitting; or
2. a trivial-stabilizer aperiodic defect.

The forced-6 closure refines this for the combined two-target problem:

- 66 exact pure-QR miss states;
- 80 one-nonresidue negative-character miss states;
- 50 two-nonresidue positive-character miss states.

So all non-pure hard-prime failure geometry at 47 is concentrated into at most a two-packet core.

---

## 7. Connection to the 10M cross-shift signal

`K47-NEGATIVE-LEGENDRE-CORRIDOR-10M.md` shows that the preserved 10M earlier corridor realizes **none** of the 80 negative-character forced-6 miss states after shift 39.

The proof target can therefore be stated in its smallest current form:

> Show that the exact failure conditions at shifts `3,7,11,15,19,23,27,31,35,39` are incompatible with all 80 one-packet negative-character miss states in the forced-6 `k=47` table.

This is still open.

But the target is now finite on the `k=47` side and symbolic on the earlier-corridor side. It is no longer “explain thousands of arbitrary 47 states.”

---

## 8. Reproduction

```sh
python3 research/erdos-straus/classify_k47_forced6_states.py --json
python3 research/erdos-straus/classify_k47_forced6_states.py --json --table
```

Hard constants are

```text
forced factors                    2,3
forced logs                      18,20
forced starting D size               9
forced starting center              38
closed states                     1079
hit states                         883
miss states                        196
pure-QR states                      66
pure-QR misses                      66
Legendre miss split       {+1:116, -1:80}
minimum added NR histogram   {0:66, 1:80, 2:50}
```

---

Erdős–Straus remains open. The important new object is the 80-state negative-character packet family, which is small enough to attack against the earlier exact corridor one state family at a time.
