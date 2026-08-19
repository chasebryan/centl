# External `q ≡ 3 mod 4` binary rescue census through 10,000,000

**Status:** exact finite census / theorem-mining record  
**Date:** 2026-08-16  
**Depends on:** `BINARY-R-KNESER-DEFECT.md`, `ES-BINARY-LANE-I-EQUIVALENCE.md`, `FAB-MIRROR-CHARACTER-OBSTRUCTION.md`, `external_q3_rescue_census.py`  
**Claim boundary:** this is finite exact evidence. It does **not** prove that `q<=419`, or any fixed bound, works for every Mordell-hard prime. It does not prove Erdős–Straus.

---

## 1. Restricted external-prime question

Let `p` be Mordell-hard. Restrict attention to auxiliary primes

\[
\boxed{
q\equiv3\pmod4,
\qquad q<p,
\qquad \left(\frac qp\right)=-1.
}
\]

Put

\[
\boxed{C_q=\frac{p+q}{4}.}
\]

Because `q` itself is an admissible Lane-I shift, the exact fixed-shift test is

\[
\boxed{
D_q(C_q^2)
\cap
\left\{-4^{-1},-C_q\right\}
\ne\varnothing,
}
\]

where

\[
D_q(C_q^2)
=\{d\bmod q:d\mid C_q^2\}.
\]

By `ES-BINARY-LANE-I-EQUIVALENCE.md`, this is exactly the external binary-`q` rescue criterion.

The finite question tested here is:

> For every Mordell-hard prime `p<=10^7`, does some external prime `q==3 mod4`, `q<=419`, rescue `p`?

---

## 2. Independent direct method

`external_q3_rescue_census.py` does **not** consume CBX hit tables.

It independently:

1. sieves all primes through the chosen `p` bound;
2. selects the six Mordell-hard classes modulo `840`;
3. enumerates primes `q==3 mod4` through the chosen `q` ceiling;
4. tests externality using quadratic reciprocity:
   \[
   \left(\frac qp\right)=\left(\frac pq\right)
   \]
   because `p==1 mod4`;
5. factors `C_q=(p+q)/4` exactly;
6. constructs the exact divisor residues of `C_q^2 mod q`;
7. records the first external `q` for which either exact target is present;
8. stores a literal divisor witness for each attained target.

This gives an independent replay of the same mathematical object measured by the CBX standalone hit corpus.

---

## 3. Exact finite result

The hard-prime population through

\[
\boxed{10,000,000}
\]

is

\[
\boxed{20,513}.
\]

With external primes

\[
q\equiv3\pmod4,
\qquad q\le419,
\]

the result is

\[
\boxed{20,513/20,513\text{ rescued},}
\]

with

\[
\boxed{0\text{ unresolved}.}
\]

The direct scanner paid for only

\[
\boxed{24,485}
\]

external-`q` fixed-shift tests in total before first success.

Again, this is finite coverage, not a universal ceiling theorem.

---

## 4. First-success histogram

The exact first successful external prime distribution is:

| first external `q` | hard primes |
|---:|---:|
| 11 | 9,626 |
| 19 | 4,027 |
| 23 | 3,455 |
| 31 | 1,570 |
| 43 | 271 |
| 47 | 752 |
| 59 | 319 |
| 67 | 34 |
| 71 | 217 |
| 79 | 88 |
| 83 | 50 |
| 103 | 22 |
| 107 | 15 |
| 127 | 9 |
| 131 | 12 |
| 139 | 10 |
| 151 | 9 |
| 163 | 1 |
| 167 | 9 |
| 179 | 5 |
| 191 | 5 |
| 199 | 3 |
| 223 | 1 |
| 311 | 1 |
| 383 | 1 |
| 419 | 1 |

The counts sum to

\[
\boxed{20,513}.
\]

The tail is extremely sparse on this finite range, but no asymptotic claim is inferred from that observation.

---

## 5. Unique deepest finite case

The unique target whose first successful external `q==3 mod4` is `419` is

\[
\boxed{p=8,925,841.}
\]

It belongs to the hard class

\[
\boxed{p\equiv1\pmod{840}.}
\]

At

\[
\boxed{q=419}
\]

we have

\[
C
=\frac{8,925,841+419}{4}
=2,231,565
\]

with factorization

\[
\boxed{
C=3\cdot5\cdot7\cdot53\cdot401.
}
\]

The two exact divisor targets modulo `419` are

\[
\boxed{
\tau_I=-4^{-1}\equiv314\pmod{419},
}
\]

and

\[
\boxed{
\tau_{II}=-C\equiv29\pmod{419}.
}
\]

Type II misses. Type I hits.

A literal witness is

\[
\boxed{d=127,836,795.}
\]

It satisfies

\[
\boxed{d\mid C^2}
\]

and

\[
\boxed{d\equiv314\equiv-4^{-1}\pmod{419}.}
\]

Thus the deepest observed first success is exact, not a probabilistic or sampled hit.

---

## 6. Why this restricted lane matters

This census uses only the clean branch of `BINARY-R-KNESER-DEFECT.md`:

\[
q\text{ prime},
\qquad
q\equiv3\pmod4,
\qquad
\left(\frac qp\right)=-1.
\]

On a failed vertex that theorem gives:

\[
\boxed{n\ge6,\qquad n\equiv2\pmod4,}
\]

for the full stabilizer quotient index, together with the visible-nonresidue valuation bound

\[
\boxed{
n\ge2E_q\left(\frac{p+q}{4}\right)+4.}
\]

There is no odd-index defect escape hatch in this branch.

The finite census therefore supports a cleaner global target than the broader external-cycle strategy:

\[
\boxed{
\text{For every Mordell-hard prime }p,
\text{ prove that some external prime }q\equiv3\pmod4
\text{ has a binary rescue.}
}
\]

That statement would directly prove the prime Erdős–Straus case, but it remains open.

---

## 7. Relation to the failed-cycle counterexample

`EXTERNAL-NR-FAILED-CYCLE-COUNTEREXAMPLE.md` proves that a chosen external-nonresidue factor cycle can fail at every cycle vertex. Thus a **cycle-local contradiction** is false as a universal bridge.

That does not contradict the restricted census here. A prime may have a fully failed cycle and still possess another successful external prime outside that cycle.

For example,

\[
\boxed{p=118,801}
\]

has the fully failed cycle

\[
113\to37\to929\to113,
\]

but the external prime

\[
\boxed{q=59}
\]

rescues it.

So the surviving existence target is

\[
\boxed{\exists\text{ successful external }q,}
\]

not

\[
\boxed{\text{every chosen external cycle contains a success}.}
\]

---

## 8. Reproduction

Small replay:

```sh
python3 research/erdos-straus/external_q3_rescue_census.py \
  --limit 100000 \
  --q-max 419 \
  --require-complete \
  --json
```

Full preserved finite replay:

```sh
python3 research/erdos-straus/external_q3_rescue_census.py \
  --limit 10000000 \
  --q-max 419 \
  --require-complete \
  --json
```

To emit one witness record for every covered target, add

```text
--hits
```

The direct code uses only the Python standard library.

---

## 9. Next theorem target

The main question is no longer whether external nonresidues exist. They do, and the finite census says a very small external prime usually succeeds.

A useful universal route would combine:

1. the exact failure quotient restrictions from `BINARY-R-KNESER-DEFECT.md`;
2. reciprocity transfer
   \[
   (r/q)=(r/p)
   \]
   for prime factors `r|(p+q)/4`;
3. the odd external-nonresidue valuation of `(p+q)/4` at every external `q`;
4. arithmetic restrictions on the divisor structure of `q-1`.

One concrete target is:

> show that the family of external primes `q==3 mod4` cannot all support the required even Kneser defects for the same hard prime `p`.

Unlike the now-falsified cycle-only bridge, this quantifies over **all** eligible external prime vertices.

---

Erdős–Straus remains open. The `q<=419` result is exact finite evidence through `p<=10^7`, not a universal bound.
