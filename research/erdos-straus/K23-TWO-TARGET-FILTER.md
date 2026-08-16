# Exact two-target filter at the prime shift `k=23`

**Status:** proved exact combined Type-I/Type-II classification  
**Date:** 2026-08-16  
**Depends on:** `STRONG-ES-Q23-EXACT-FILTER.md`, `ES-TWO-TARGET-DIVISOR-SQUARE.md`, `ES-BINARY-LANE-I-EQUIVALENCE.md`  
**Claim boundary:** this closes the fixed shift `k=23` for Mordell-hard primes. It does not prove that a smaller-shift survivor must hit at `23`, does not give a universal finite shift bound, and does not prove Erdős–Straus.

---

## 1. Setup

Let `p` be Mordell-hard and put

\[
\boxed{C=\frac{p+23}{4}.}
\]

Since every Mordell-hard prime satisfies

\[
p\equiv1\pmod{24},
\]

we have

\[
\boxed{6\mid C.}
\]

Thus `2` and `3` are forced factors of `C`.

The existing `STRONG-ES-Q23-EXACT-FILTER.md` gives an exact classification of failure of the Type-II target

\[
-1\in\mathcal R_{23}(C).
\]

The remaining task is to determine exactly when the Type-I target rescues one of those Type-II failures.

---

## 2. Type I is a fixed divisor-square residue

By `ES-TWO-TARGET-DIVISOR-SQUARE.md`, Type I at shift `23` succeeds if and only if there exists

\[
d\mid C^2
\]

with

\[
4d\equiv-1\pmod{23}.
\]

Since

\[
4^{-1}\equiv6\pmod{23},
\]

the Type-I divisor target is the fixed residue

\[
\boxed{d\equiv17\pmod{23}.}
\]

Use `5` as a primitive root modulo `23`. Then

\[
\boxed{\log_5(17)=7\pmod{22}.}
\]

In these coordinates Type I asks whether the divisor-log set of `C^2` contains the odd class `7`.

---

## 3. Recall the exact Type-II miss branches

The existing q=23 theorem proves that Type II misses exactly in one of two branches.

### Branch A: pure quadratic splitting

Every prime factor of `C` is a quadratic residue modulo `23`.

### Branch B: forced-6 thin defect

All of the following hold:

1. \[
   v_2(C)=v_3(C)=1;
   \]
2. every other quadratic-residue prime factor is actually `1 mod 23`;
3. the only quadratic-nonresidue prime-factor classes are
   \[
   \boxed{5,14\pmod{23}};
   \]
4. if
   \[
   e_+=\sum_{q^e\parallel C,\ q\equiv5\ (23)}e,
   \qquad
   e_- =\sum_{q^e\parallel C,\ q\equiv14\ (23)}e,
   \]
   then
   \[
   \boxed{e_++e_-\le2.}
   \]

No other Type-II miss geometry is possible.

---

## 4. Branch A also forces Type-I failure

The quadratic-residue subgroup modulo `23` is the even-log subgroup of `C_22`.

If every prime factor of `C` is a quadratic residue, then every divisor of `C^2` also has even discrete log modulo `22`.

But the Type-I target `17` has log

\[
7,
\]

which is odd.

Therefore:

### Theorem A

On the pure quadratic-splitting branch,

\[
\boxed{
\text{Type II misses}
\quad\text{and}\quad
\text{Type I misses}.}
\]

Thus every Branch-A q=23 miss is automatically a combined two-target miss.

---

## 5. Forced divisor logs on the thin branch

Now assume Branch B.

In primitive-root-`5` coordinates,

\[
\log_5(2)=2,
\qquad
\log_5(3)=16.
\]

Because `v_2(C)=v_3(C)=1`, a divisor of `C^2` may use exponent `0`, `1`, or `2` of each forced factor. Their possible combined divisor logs are therefore

\[
S
=
\{2a+16b\pmod{22}:a,b\in\{0,1,2\}\}.
\]

Directly,

\[
\boxed{
S=\{0,2,4,10,12,14,16,18,20\}.}
\]

Every other quadratic-residue factor in Branch B is `1 mod23`, so it contributes log `0` and does not enlarge this set.

The allowed nonresidue classes satisfy

\[
\log_5(5)=1,
\qquad
\log_5(14)=-1\pmod{22}.
\]

Hence their divisor-log contribution is

\[
\boxed{
I(e_+,e_-)
=\{i-j\pmod{22}:
0\le i\le2e_+,
0\le j\le2e_-\}.}
\]

Type I succeeds exactly when

\[
\boxed{7\in S+I(e_+,e_-).}
\]

---

## 6. Exact Type-I behavior inside Branch B

Because Branch B already forces

\[
e_++e_-\le2,
\]

there are only six possible valuation pairs.

### `(e_+,e_-)=(0,0)`

Then `I={0}`. Since `7 notin S`, Type I misses.

### `(1,0)`

Then

\[
I=\{0,1,2\}.
\]

None of `7,6,5` lies in `S`, so Type I misses.

### `(0,1)`

Then

\[
I=\{0,-1,-2\}.
\]

None of `7,8,9` lies in `S`, so Type I misses.

### `(1,1)`

Then

\[
I=\{-2,-1,0,1,2\}.
\]

Again `7-I` misses `S`, so Type I misses.

### `(2,0)`

Now

\[
I=\{0,1,2,3,4\}.
\]

Since

\[
4\in S,
\qquad
3\in I,
\qquad
4+3=7,
\]

Type I hits.

### `(0,2)`

Now

\[
I=\{0,-1,-2,-3,-4\}.
\]

Since

\[
10\in S,
\qquad
-3\in I,
\qquad
10-3=7,
\]

Type I hits.

Therefore:

### Theorem B

Inside the forced-6 thin Type-II defect,

\[
\boxed{
\text{Type I hits}
\iff
(e_+,e_-)\in\{(2,0),(0,2)\}.}
\]

Equivalently, Type I rescues the thin defect exactly when the allowed total nonresidue valuation is `2` and both units of valuation lie on the **same** primitive residue class `5` or `14`.

It misses when

\[
\boxed{
(e_+,e_-)
\in
\{(0,0),(1,0),(0,1),(1,1)\}.}
\]

---

## 7. Exact combined-miss theorem at k=23

### Theorem

For a Mordell-hard prime `p`, both exact Lane-I targets miss at `k=23` if and only if one of the following holds.

### Combined Branch A: pure quadratic splitting

Every prime factor of

\[
C=\frac{p+23}{4}
\]

is a quadratic residue modulo `23`.

### Combined Branch B: unresolved forced-6 thin defect

All of the following hold:

1. \[
   v_2(C)=v_3(C)=1;
   \]
2. every other quadratic-residue prime factor is `1 mod23`;
3. every quadratic-nonresidue prime factor is `5` or `14 mod23`;
4. its aggregate valuations satisfy
   \[
   \boxed{
   (e_+,e_-)
   \in
   \{(0,0),(1,0),(0,1),(1,1)\}.}
   \]

In every other case at least one exact target hits, and `p` has an Erdős–Straus decomposition at shift `23`.

---

## 8. What Type I adds beyond the strong q=23 filter

The strong/Type-II theorem allows six valuation patterns in Branch B:

\[
(0,0),(1,0),(0,1),(2,0),(1,1),(0,2).
\]

The Type-I companion removes exactly

\[
\boxed{(2,0)\text{ and }(0,2).}
\]

Therefore the exact two-target corridor is strictly stronger than the strong/Type-II q=23 filter while preserving its very thin residual structure.

---

## 9. Independent 10M regression

The theorem was independently compared with the exact CBX Lane-I standalone hit set at `k=23` on the preserved Mordell-hard corpus

\[
p\le10,000,000.
\]

Population:

\[
\boxed{20,513\text{ hard primes}.}
\]

Exact `k=23` hits:

\[
\boxed{13,860.}
\]

Exact combined misses:

\[
\boxed{6,653.}
\]

The classification above predicted every hit/miss correctly:

\[
\boxed{0\text{ mismatches}.}
\]

The combined misses split as

\[
\boxed{6,377\text{ Branch A}}
\]

and

\[
\boxed{276\text{ Branch B}.}
\]

The 276 thin combined misses have valuation patterns

```text
(e_+,e_-)=(0,1): 142
(e_+,e_-)=(1,0): 123
(e_+,e_-)=(1,1): 11
```

No `(0,0)` example occurs in this finite range, although the theorem permits it.

The Type-II theorem alone has seven additional finite misses with concentrated valuation two:

```text
(e_+,e_-)=(0,2): 6
(e_+,e_-)=(2,0): 1
```

All seven are rescued by Type I exactly as Theorem B predicts.

These finite counts are regression evidence only. The classification is proved by the group calculation above.

---

## 10. Corridor consequence

The exact consecutive corridor is now classified through

\[
\boxed{k=3,7,11,15,19,23}
\]

at the level needed for the two-target Lane-I predicate.

By `ES-BINARY-LANE-I-EQUIVALENCE.md`, these are simultaneously exact fixed-selector binary classifications.

The next theorem-mining step should use the **simultaneous failure laws** of these six positions rather than reclassifying the same shifts under separate binary, signed-box, or CBX names.

The natural next objects are:

1. the joint multiplicative constraints on the six nearby integers
   \[
   \frac{p+3}{4},
   \frac{p+7}{4},
   \frac{p+11}{4},
   \frac{p+15}{4},
   \frac{p+19}{4},
   \frac{p+23}{4};
   \]
2. exact characterization of primes that fail all six fixed shifts;
3. the first genuinely new layer beyond the classified corridor, `k=27`, if joint incompatibility does not already close the residual.

---

Erdős–Straus remains open. This closes one fixed shift; it does not prove a universal existence statement.
