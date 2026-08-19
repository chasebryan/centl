# Exact two-target filter at the composite shift `k=27`

**Status:** proved exact combined Type-I/Type-II classification  
**Date:** 2026-08-16  
**Depends on:** `K27-TWO-TARGET-STRUCTURE.md`, `ES-TWO-TARGET-DIVISOR-SQUARE.md`, `ES-BINARY-LANE-I-EQUIVALENCE.md`  
**Machine certificate:** `classify_k27_even_packets.py`  
**Independent finite regression:** `verify_k27_structure.py`  
**Claim boundary:** this closes the fixed Lane-I shift `k=27` for Mordell-hard primes by an exact finite-group classification. It does not prove that every earlier-shift survivor must hit at `27`, does not give a universal finite shift bound, and does not prove Erdős–Straus.

---

## 1. Setup

Let `p` be Mordell-hard and write

\[
P=\frac{p-1}{4}.
\]

Then

\[
P\equiv0\pmod6.
\]

At shift `k=27`, put

\[
\boxed{C=\frac{p+27}{4}=P+7.}
\]

Hence

\[
\boxed{C\equiv1\pmod6,}
\]

so `gcd(C,27)=1`.

The unit group

\[
(\mathbb Z/27\mathbb Z)^\times
\]

is cyclic of order `18`; take `2` as primitive root and write all unit residues as discrete logs modulo `18`.

The quadratic residues are exactly the even-log classes. Equivalently, among units modulo `27`,

\[
\boxed{x\text{ is QR mod }27\iff x\equiv1\pmod3.}
\]

---

## 2. The two exact targets

Let

\[
\mathcal D(C)
=
\left\{
\sum_i f_i\log_2 q_i\pmod{18}:
0\le f_i\le2e_i
\right\}
\]

be the divisor-log set of `C^2`, where

\[
C=\prod_i q_i^{e_i}.
\]

By the exact divisor-square formulation:

### Type I

`4d == -1 (mod 27)` with `d|C^2`.

Since

\[
-4^{-1}\equiv20\pmod{27}
\]

and

\[
\log_2 20=7,
\]

Type I is exactly

\[
\boxed{7\in\mathcal D(C).}
\]

### Type II

Let

\[
c=\log_2 C\pmod{18}.
\]

The signed-box target `-1` is equivalent in divisor-log coordinates to

\[
\boxed{9+c\in\mathcal D(C).}
\]

Thus the combined fixed-shift test is an exact two-target membership problem in `C_18`.

---

## 3. Nonresidue valuation is forced even

A prime factor of `C` is a quadratic nonresidue modulo `27` exactly when it is `2 mod 3`.

Define

\[
\boxed{
E_{NR}(C)
=
\sum_{q^e\parallel C,\ q\equiv2\ (3)}e.
}
\]

Because

\[
C\equiv1\pmod3,
\]

the number of `2 mod 3` factors counted with multiplicity is even. Therefore

\[
\boxed{E_{NR}(C)\equiv0\pmod2.}
\]

There are no odd packet sizes to classify.

---

## 4. Split the QR and nonresidue data

Write

\[
C=C_QC_N,
\]

where `C_Q` contains the quadratic-residue prime powers and `C_N` the nonresidue prime powers.

### QR state

Every QR prime has an even log. Divide those logs by `2` and work in

\[
C_9=\mathbb Z/9\mathbb Z.
\]

For the QR part define the state

\[
\boxed{(A,s)}
\]

where

- `A` is the half-log divisor set of `C_Q^2`;
- `s` is half of `log C_Q`.

For a QR prime-power contribution with half-log `a` and exponent `e`, the local state is

\[
\left(
\{0,a,2a,\ldots,2ea\},
\ ea
\right)
\pmod9.
\]

This local state space is finite for exact algebraic reasons:

- `a=0` is trivial;
- `a=3,6` has order `3`, so `e=1,2,3` exhausts the possibilities;
- every other nonzero `a` has order `9`;
- for those order-9 classes, `e=1,2,3` gives local divisor sets of sizes `3,5,7`, while `e>=4` fills all of `C_9`; after saturation only the center `ea mod 9` remains, and nine consecutive exponents exhaust it.

Therefore `e=1,...,12` exhausts every possible local QR prime-power state.

Closing those exact local states under multiplication/Minkowski sum yields

\[
\boxed{31\text{ local QR states}}
\]

and exactly

\[
\boxed{40\text{ reachable aggregate QR states }(A,s).}
\]

`classify_k27_even_packets.py` constructs this closure directly and emits every state used below.

### Nonresidue packet

Every nonresidue prime has an odd log modulo `18`.

Split each exponent-`e` nonresidue prime power into `e` identical valuation units. This loses no divisor information because sums of `e` choices from `{0,1,2}` fill every exponent from `0` through `2e`.

Thus a nonresidue packet of size

\[
E=E_{NR}(C)
\]

is represented by an unordered multiset

\[
\boxed{U=(\alpha_1,\ldots,\alpha_E),
\qquad
\alpha_i\in\{1,3,5,7,9,11,13,15,17\}.}
\]

Let

\[
\mathcal O(U)
\]

be the set of odd divisor-log contributions obtainable from that packet.

---

## 5. Exact hit criterion for one structural state

Lift the QR half-log set back to even logs:

\[
2A=\{2a:a\in A\}\subset C_{18}.
\]

The full center is

\[
\boxed{
c=2s+\sum_{\alpha\in U}\alpha\pmod{18}.}
\]

Because both exact targets are odd, only odd contributions from the nonresidue packet can complete them.

Therefore:

### Type I

\[
\boxed{
\text{Type I hits}
\iff
\exists o\in\mathcal O(U):
7-o\in2A.}
\]

### Type II

\[
\boxed{
\text{Type II hits}
\iff
\exists o\in\mathcal O(U):
9+c-o\in2A.}
\]

Consequently a structural state `(A,s,U)` is a combined miss if and only if **both** intersections are empty.

This criterion is exact. No prime search or probabilistic assumption enters it.

---

## 6. Exhaustive packet classification

Since `E_NR` is even, evaluate packet sizes

\[
E=0,2,4,6,8,10.
\]

For each `E`, every unordered multiset of `E` odd logs is combined with every one of the 40 reachable QR states and tested by the exact criterion above.

The complete exhaustion is:

| `E_NR` | nonresidue multisets | structural cases | exact miss configurations | miss-capable QR states |
|---:|---:|---:|---:|---:|
| 0 | 1 | 40 | **40** | 40 |
| 2 | 45 | 1,800 | **95** | 21 |
| 4 | 495 | 19,800 | **46** | 12 |
| 6 | 3,003 | 120,120 | **16** | 6 |
| 8 | 12,870 | 514,800 | **3** | 1 |
| 10 | 43,758 | 1,750,320 | **0** | 0 |

The classifier emits the complete miss table:

\[
\boxed{200\text{ exact miss rows total}}
\]

of which

\[
\boxed{160\text{ are non-pure-QR rows}.}
\]

The remaining 40 rows are the pure-QR `E=0` states.

These are not sampled examples. They are the entire finite-group exception table for packet sizes through `10`.

---

## 7. Pure-QR branch

When

\[
E_{NR}=0,
\]

every divisor log is even while both targets are odd. Hence every reachable QR state misses:

\[
\boxed{E_{NR}=0\Longrightarrow\text{combined miss at }k=27.}
\]

This accounts for the 40 `E=0` table rows without any enumeration beyond the QR-state closure itself.

---

## 8. Universal cutoff at ten nonresidue valuation units

The `E=10` exhaustion has

\[
\boxed{0\text{ combined miss configurations}.}
\]

This immediately yields a universal cutoff for larger packets.

### Theorem — nonresidue cutoff

If

\[
\boxed{E_{NR}(C)\ge10,}
\]

then the `k=27` Lane-I test hits.

### Proof

Choose any ten nonresidue valuation units from `C`, retaining the entire QR part. The exact `E=10` table says this subconfiguration has either a Type-I or a Type-II witness.

If it is Type I, the witness is a divisor

\[
d\mid C'^2,
\qquad
d\equiv20\pmod{27}.
\]

After restoring the omitted factors, `d` remains a divisor of `C^2`, so the Type-I witness survives unchanged.

If it is Type II, the witness is a signed-box exponent vector giving `-1 mod 27`. After restoring the omitted factors, extend that vector by assigning exponent `0` to every restored factor. The same Type-II witness survives unchanged.

Thus adjoining additional factors cannot destroy the subconfiguration witness. Therefore every packet with at least ten nonresidue valuation units hits. QED.

Because `E_NR` is even, no packet size above `8` remains capable of missing.

---

## 9. Exact combined-miss theorem at k=27

### Theorem

For a Mordell-hard prime `p`, put

\[
C=\frac{p+27}{4}.
\]

Construct its exact QR state `(A,s)` and nonresidue log multiset `U` as above.

Then both Lane-I targets miss at `k=27` if and only if:

1. \[
   E_{NR}(C)\in\{0,2,4,6,8\};
   \]
2. the structural row `(A,s,U)` occurs in the complete miss table emitted by
   `classify_k27_even_packets.py`.

Equivalently:

\[
\boxed{
\delta_{27}(C)>0
\iff
(A,s,U)\in\mathcal M_{27},}
\]

where `M_27` is the explicit 200-row table generated by the exact finite-group classifier.

For

\[
E_{NR}\ge10,
\]

combined failure is impossible.

This is a complete fixed-shift classification.

---

## 10. The extreme E_NR=8 edge

At `E_NR=8`, only **three** structural misses survive, and all three require the trivial QR state

\[
\boxed{A=\{0\},\qquad s=0.}
\]

Thus every QR prime factor must contribute log `0`, i.e. residue `1 mod 27`.

The three nonresidue log multisets are exactly

```text
(1,1,1,17,17,17,17,17)
(5,5,13,13,13,13,13,13)
(11,11,11,11,11,11,11,11)
```

In each case the attainable odd contribution set is

\[
\{1,3,5,9,11,13,15,17\},
\]

which is every odd log class except `7`.

This is the final miss layer before the universal `E_NR>=10` hit cutoff.

---

## 11. Independent finite regression

The exact structural identities were independently replayed on Mordell-hard primes using `verify_k27_structure.py`, without invoking CBX.

On the preserved full `p<=10,000,000` corpus:

| `E_NR(C)` | hits at k=27 | misses at k=27 |
|---:|---:|---:|
| 0 | 0 | 11,926 |
| 2 | 6,063 | 2,401 |
| 4 | 117 | 6 |

No larger nonresidue packet occurs in that finite range.

These population counts are finite regression evidence only. The exact theorem is the group classification above.

On the six-shift residual after

\[
3,7,11,15,19,23,
\]

there are 308 hard primes through `10^7`. At `k=27` they split as:

\[
185\text{ pure-QR misses},
\qquad
91\text{ non-pure hits},
\qquad
32\text{ non-pure misses}.
\]

Every observed non-pure member of that six-shift residual has `E_NR=2`, so the exact `E=2` table contains the entire observed thin residual geometry there.

Again, this last population statement is finite evidence, not a universal theorem about six-shift survivors.

---

## 12. Verification and reproducibility

The exact table is generated by:

```sh
python3 research/erdos-straus/classify_k27_even_packets.py --json
```

The program checks as hard regression constants:

```text
QR local states       31
QR reachable states   40

E=0   misses          40
E=2   misses          95
E=4   misses          46
E=6   misses          16
E=8   misses           3
E=10  misses           0

total miss rows      200
non-pure miss rows   160
```

The Fedora CI gate independently requires the same counts, requires every emitted table length to equal its exact miss count, and requires the universal cutoff to report

```text
E_NR_at_least = 10
combined_miss_possible = false
```

The structural verifier separately checks:

- the hard-prime wheel law;
- `QR mod 27 iff 1 mod 3` for units;
- even nonresidue valuation;
- signed-box/divisor-log coordinate equivalence;
- the pure-QR combined miss theorem;
- the full-QR-mass hit theorem;
- the exact `E_NR=2` companion criterion.

---

## 13. Corridor status

The exact consecutive Lane-I corridor is now classified through

\[
\boxed{k=3,7,11,15,19,23,27.}
\]

By `ES-BINARY-LANE-I-EQUIVALENCE.md`, these are simultaneously exact consecutive binary-selector classifications.

The next shift is

\[
\boxed{k=31,}
\]

where a separate quotient/`v_2` analysis is already underway. The theorem-mining priority is no longer to revisit `k=27`; it is to combine the seven exact failure laws and compress the residual entering `k=31`.

---

Erdős–Straus remains open. This closes one fixed shift by exact finite-group exhaustion and a universal packet cutoff; it does not supply the missing universal existence argument across shifts.
