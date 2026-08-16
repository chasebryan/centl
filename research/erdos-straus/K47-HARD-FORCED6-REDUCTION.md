# Hard-prime forced-6 reduction at the prime shift `k=47`

**Status:** proved finite-state reduction / corollary of the exact `k=47` classifier  
**Date:** 2026-08-16  
**Depends on:** `K47-TWO-TARGET-FILTER.md`, `FIXED-SHIFT-JACOBI-PARITY.md`, `ES-TWO-TARGET-DIVISOR-SQUARE.md`  
**Machine certificate:** `classify_k47_forced6_states.py`  
**Independent finite regression:** `verify_k47_structure.py` plus the preserved CBX 10M standalone relation  
**Claim boundary:** this is a range-free reduction of the abstract fixed-47 state space using a factor forced for every Mordell-hard prime. It does not assert that every state in the reduced closure is realized by a prime, does not prove the cross-shift exclusion candidate, and does not prove Erdős–Straus.

---

## 1. Universal factor `6`

Let `p` be Mordell-hard. Then

\[
\boxed{p\equiv1\pmod{24}.}
\]

Write

\[
p=24m+1.
\]

At shift `47`,

\[
C_{47}=\frac{p+47}{4}=\frac{24m+48}{4}=6m+12.
\]

Therefore

\[
\boxed{6\mid C_{47}.}
\]

So every actual hard-prime factorization state at `k=47` contains at least one valuation occurrence of `2` and one of `3`.

This is stronger than starting the exact state automaton from the empty divisor box.

---

## 2. Logarithmic seed

Use the same primitive-root coordinate as `K47-TWO-TARGET-FILTER.md`:

\[
G=(\mathbb Z/47\mathbb Z)^\times\cong C_{46},
\qquad
\lambda(x)=\log_5x\pmod{46}.
\]

The exact state transition for one valuation occurrence of log `a` is

\[
T_a(D,c)=\left(D+\{0,a,2a\},\ c+a\right).
\]

The hard-prime state automaton therefore starts not from `({0},0)` but from

\[
\boxed{S_6=T_{\lambda(3)}T_{\lambda(2)}(\{0\},0).}
\]

Both `2` and `3` are quadratic residues modulo `47`, so their logs are even. Thus the forced seed itself carries positive quadratic character.

After this seed, arbitrary additional prime-valuation occurrences are still represented by the same 46 exact transition maps. Hence closing from `S_6` gives a range-free superset of every factorization state actually realizable by a Mordell-hard prime at `k=47`.

---

## 3. Exact forced-seed closure

`classify_k47_forced6_states.py` closes the automaton from `S_6` under every logarithmic direction.

The least closed set contains exactly

\[
\boxed{1,079\text{ states}.}
\]

This is a sharp state-space compression relative to the generic fixed-47 closure:

\[
\boxed{61,134\longrightarrow1,079.}
\]

The reduction factor is approximately

\[
\boxed{56.7\times.}
\]

No prime-range bound is used in either number. The difference comes only from imposing the universal hard-prime factor `6` before the closure is formed.

---

## 4. Hit and miss states

The two exact targets remain

\[
\tau_I=33
\]

and

\[
\tau_{II}=c+23
\]

in the base-5 logarithmic coordinate.

Testing those targets on the complete forced-seed closure gives

\[
\boxed{883\text{ hit states}}
\]

and

\[
\boxed{196\text{ combined-miss states}.}
\]

Therefore every Mordell-hard prime that misses at `k=47` must land in this explicit 196-state set.

This is a necessary condition on an actual hard-prime miss. The closure is deliberately an algebraic superset: it does not claim that all 196 states occur for prime inputs.

---

## 5. Pure quadratic branch

Close the same forced seed using only even logarithmic directions.

The resulting pure-quadratic closure contains exactly

\[
\boxed{66\text{ states},}
\]

and all 66 miss both exact targets.

Thus the universal pure-QR trap survives the forced-factor reduction, but its abstract state count drops from the generic 1,498 states to only 66 states compatible with the mandatory `2` and `3` packet.

---

## 6. Legendre split

Because the forced logs are even, the parity of the final center is exactly the parity of the **additional** nonresidue valuation packet.

By the fixed-shift Jacobi parity law,

\[
(-1)^{c(C_{47})}=\left(\frac{47}{p}\right).
\]

The 196 forced-seed miss states split as

\[
\boxed{116\text{ states with }(47/p)=+1,}
\]

\[
\boxed{80\text{ states with }(47/p)=-1.}
\]

So the negative-character branch is not eliminated locally. It remains a genuine fixed-47 possibility, but it has been reduced from 6,848 generic miss states to only 80 hard-prime-compatible abstract states.

This is the correct local target for the cross-shift exclusion program.

---

## 7. Minimum additional nonresidue core

Minimize, among all exact transition paths from the forced seed to a miss state,

\[
(\text{number of added odd-log valuation units},\ \text{total added valuation units}).
\]

The exact histogram is

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

No forced-seed miss state requires three or more additional nonresidue valuation units in a minimum representative.

Therefore

\[
\boxed{\text{every hard-prime-compatible fixed-47 miss state has a state-equivalent core with at most two added NR units}.}
\]

Moreover the parity branches separate exactly:

- `(47/p)=+1` uses minimum added NR count `0` or `2`;
- `(47/p)=-1` uses minimum added NR count `1`.

Thus every negative-character hard-state miss has a **one-nonresidue-packet representative** after the universal `2·3` seed.

This is substantially sharper than the generic four-nonresidue-core statement.

---

## 8. Relation to the 10M cross-shift signal

The preserved 10M standalone relation contains

\[
\boxed{822}
\]

hard primes that simultaneously

1. miss fixed `k=47`, and
2. satisfy `(47/p)=-1`.

Every one of those 822 primes is captured by an earlier classified Lane-I shift by `k=39`.

The exact finite elimination sequence is

\[
822\to558\to302\to118\to81\to48\to13\to7\to2\to1\to0
\]

under the ordered shifts

\[
3,7,11,15,19,23,27,31,35,39.
\]

A minimum finite cover of that 10M population uses seven shifts:

\[
\boxed{\{3,7,15,23,27,31,39\}.}
\]

These are finite observations only. They do **not** prove that the 80 abstract negative-character forced-seed miss states are globally incompatible with all hard primes.

The theorem target is now precise:

> combine the exact failure laws at the earlier shifts with the 80-state one-nonresidue `k=47` branch and prove that no Mordell-hard prime can realize the joint state system.

---

## 9. Why this reduction matters

The original fixed-47 theorem is intentionally complete for arbitrary factorization states and therefore has a large exception table.

The hard-prime arithmetic removes almost all of that entropy before any cross-shift argument begins:

\[
\boxed{
14,474\text{ generic misses}
\longrightarrow
196\text{ hard-seed misses}
\longrightarrow
80\text{ negative-character hard-seed misses}.
}
\]

And those 80 states are all one-nonresidue-packet states after the forced `2·3` packet.

So the next useful proof problem is not “understand 14,474 states.” It is a small compatibility problem between:

- the earlier exact corridor failure laws;
- the forced seed `{2,3}` at `47`;
- one added nonresidue direction modulo `47`;
- and the center-character condition `(47/p)=-1`.

That is small enough to attack symbolically.

---

## 10. Reproducibility

Run

```sh
python3 research/erdos-straus/classify_k47_forced6_states.py --json
```

The certificate enforces the regression constants

```text
states                          1079
hit states                       883
miss states                      196
pure QR states                    66
pure QR miss states               66
Legendre +1 miss states          116
Legendre -1 miss states           80
minimum added NR histogram  0:66 1:80 2:50
maximum minimum added NR           2
```

`verify_k47_structure.py` remains an independent direct divisor-box regression for the underlying fixed-47 state theorem.

---

Erdős–Straus remains open. This note compresses the exact `k=47` hard-prime state space and isolates a small negative-character compatibility target; it does not establish the required cross-shift impossibility theorem.
