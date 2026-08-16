# Exact factor-residue shape of the `k=47` state `r7-s02`

**Status:** proved exact fixed-shift finite-state lemma  
**Date:** 2026-08-16  
**Verifier:** `verify_k47_r7_s02_shape.py`  
**Depends on:** `K47-FORCED6-HARD-REDUCTION.md`, `K47-ONE-PACKET-COMPANION-FILTER.md`  
**Claim boundary:** this note characterizes one exact fixed-47 miss state and its conditional CRT residue. It does not prove that an earlier shift hits universally and does not prove Erdős–Straus.

---

## 1. The state

Use primitive root `5 mod 47`. The universally forced hard-prime seed comes from one valuation unit of 2 and one of 3:

\[
\lambda(2)=18,
\qquad
\lambda(3)=20.
\]

Let `S_6` be the resulting state. The exact abstract miss state named `r7-s02` is

\[
\boxed{S_{7,2}=T_7(S_6)},
\]

where `T_a` is the valuation-unit transition in the fixed-47 signed-box state machine.

Its center log is

\[
\boxed{45},
\]

and its divisor-log mask has size

\[
\boxed{27}.
\]

It is a negative-character combined miss.

---

## 2. Monotonicity makes the predecessor problem finite

For a state `(M,c)`, adding a valuation unit of log `a` sends the mask to

\[
M\cup(M+a)\cup(M+2a).
\]

Therefore masks only grow.

Any valuation-unit sequence ending exactly at `S_{7,2}` must have every intermediate mask contained in the final 27-point mask. This gives a finite constrained transition graph.

The verifier enumerates all 46 possible log transitions from every state reachable from `S_6` without leaving the target mask.

Exactly three states are reachable inside that mask:

1. the forced seed `S_6`, with center 38 and mask size 9;
2. one dead intermediate obtained by an extra log-20 unit, with center 12 and mask size 15;
3. the target `S_{7,2}`, with center 45 and mask size 27.

Reverse reachability from the target shows that only the seed and target lie on a productive path.

The only productive nonzero edge is

\[
\boxed{S_6\xrightarrow{\,7\,}S_{7,2}}.
\]

Log `0` is state-neutral and may be inserted arbitrarily.

---

## 3. Exact factor shape

A prime-power valuation unit with log 0 is exactly a prime factor congruent to 1 modulo 47.

A log-7 unit is a prime factor congruent to

\[
5^7\equiv11\pmod{47}.
\]

Since the only productive nonzero addition after the forced seed is one log-7 unit, any integer realizing `r7-s02` has the exact form

\[
\boxed{C_{47}=6qS},
\]

with the following conditions:

\[
\boxed{q\equiv11\pmod{47}},
\]

`q` is prime and occurs with valuation exactly one, while every prime divisor `r` of `S` satisfies

\[
\boxed{r\equiv1\pmod{47}}.
\]

Also

\[
\boxed{v_2(C_{47})=v_3(C_{47})=1}.
\]

This is stronger and more precise than saying the state has a one-packet representative: it characterizes every factor-residue multiset that realizes this exact state.

---

## 4. The prime residue is fixed

Because the center log is 45,

\[
C_{47}\equiv5^{45}\equiv19\pmod{47}.
\]

Since

\[
p=4C_{47}-47,
\]

we obtain

\[
\boxed{p\equiv29\pmod{47}}.
\]

Thus `(47/p)=-1` is built directly into this state.

---

## 5. The surviving 10M hard cell

The direction/state/hard-residue census leaves one finite cell with minimum earlier-shift cover size four:

\[
\boxed{\texttt{r7-s02}\quad\text{and}\quad p\equiv1\pmod{840}}.
\]

Combining

\[
p\equiv1\pmod{840}
\]

and

\[
p\equiv29\pmod{47}
\]

gives

\[
\boxed{p\equiv9241\pmod{39480}}.
\]

Writing `C47=6qS`, this is equivalently

\[
\boxed{qS\equiv387\pmod{1645}}.
\]

These congruences are universal **conditional on membership in this exact hard cell**. The fact that the cell is the unique four-shift survivor is finite 10M evidence.

---

## 6. Why `S=1` is false as a universal strengthening

All ten 10M members of this cell happen to satisfy

\[
S=1,
\]

so their centers are `C47=6q`. That pattern is not forced by the state.

A concrete larger realization is

\[
\boxed{p=537,647,881},
\]

with

\[
q=79,159,
\qquad
S=283,
\]

and

\[
C_{47}=6\cdot79,159\cdot283.
\]

Here

\[
79,159\equiv11\pmod{47},
\qquad
283\equiv1\pmod{47},
\]

`p`, `q`, and `283` are prime, and the reconstructed fixed-47 state is exactly `r7-s02` and is a combined miss.

The verifier retains this example specifically as a regression against the false stronger conjecture `S=1`.

---

## 7. Companion form for cross-shift work

Let

\[
Q=qS,
\qquad C_{47}=6Q.
\]

For earlier admissible shifts `k=3,7,...,39`, the companion centers are

\[
C_k=C_{47}-\frac{47-k}{4}.
\]

Hence

\[
\begin{array}{c|c}
k & C_k\\
\hline
3 & 6Q-11\\
7 & 6Q-10\\
11 & 6Q-9\\
15 & 6Q-8\\
19 & 6Q-7\\
23 & 6Q-6\\
27 & 6Q-5\\
31 & 6Q-4\\
35 & 6Q-3\\
39 & 6Q-2
\end{array}
\]

Inside the hard cell,

\[
Q\equiv387\pmod{1645},
\]

so these ten neighboring integers inherit fixed congruence information modulo `5`, `7`, and `47`-compatible CRT data.

The next symbolic task is to exploit those forced companion divisibilities together with the exact signed-box criterion to prove a universal earlier hit, or to determine precisely what additional factorization obstruction remains.

---

Erdős–Straus remains open. This lemma isolates the exact factor-residue anatomy of the smallest finite cross-shift hard cell without extrapolating its finite cover to a theorem.
