# Type-I companion to the exact `q=11` filter

**Status:** proved exact companion  
**Date:** 2026-08-15  
**Depends on:** `STRONG-ES-Q11-EXACT-FILTER.md`, `ES-TWO-TARGET-SIGNED-BOX-EQUIVALENCE.md`, `HARD-Q7-TYPE-I-NO-RESCUE.md`  
**Claim boundary:** classifies when Type I rescues a hard-prime Type-II miss at shift `11`. It does not prove that one of the two targets always hits, and therefore does not prove Erdős--Straus.

---

## 1. Forced factor and the two boxes

Let `p` be Mordell-hard and

\[
C=\frac{p+11}{4}.
\]

Then `3\mid C` and `C` is odd. Write `Q` for the quadratic-residue subgroup modulo `11`:

\[
Q=\{1,3,4,5,9\}.
\]

The forced prime `3` generates `Q`. Its simple local set is

\[
\{3^{-1},1,3\}=\{4,1,3\}.
\]

Call this the **thin QR box**

\[
Q_{\mathrm{thin}}=\{1,3,4\}.
\]

The complementary QR classes are `5` and `9`. The existing Type-II theorem says that if the total nontrivial QR valuation of `C` is at least two, then the signed box contains all of `Q`.

---

## 2. Location of the Type-I target

Because `11≡3\pmod4` and `p≡1\pmod4`,

\[
\Bigl(\frac{-p^{-1}}{11}\Bigr)
=
-\Bigl(\frac p{11}\Bigr).
\]

Thus the Type-I target is a quadratic residue if and only if `p` is a nonresidue modulo `11`. The ten nonzero classes give:

\[
\begin{array}{c|c|c}
p\bmod11 & -p^{-1}\bmod11 & \text{side}\\
\hline
1 & 10 & \mathrm{NR}\\
2 & 5 & \mathrm{QR}\\
3 & 7 & \mathrm{NR}\\
4 & 8 & \mathrm{NR}\\
5 & 2 & \mathrm{NR}\\
6 & 9 & \mathrm{QR}\\
7 & 3 & \mathrm{QR}\\
8 & 4 & \mathrm{QR}\\
9 & 6 & \mathrm{NR}\\
10 & 1 & \mathrm{QR}
\end{array}
\]

The Type-II target is always `10`.

---

## 3. Full-QR Type-II misses

### Theorem — full-QR rescue

Suppose every prime factor of `C` is a quadratic residue modulo `11`, and the nontrivial QR valuation is at least two. Then the signed box equals `Q`, Type II misses, and Type I hits if and only if

\[
\boxed{\Bigl(\frac p{11}\Bigr)=-1,}
\]

equivalently `p\equiv2,6,7,8,10\pmod{11}`.

### Proof

Valuation at least two fills `Q` by the existing `q=11` lemma. The Type-II target `10` lies outside `Q`. The Type-I target lies in `Q` precisely on the nonresidue classes listed above. QED.

---

## 4. Thin QR Type-II misses

### Theorem — thin-QR rescue

Suppose `v_3(C)=1` and every other prime factor of `C` is `1\bmod{11}`. Then the signed box equals the thin QR box `{1,3,4}`, Type II misses, and Type I hits if and only if

\[
\boxed{p\equiv7,8,10\pmod{11}.}
\]

### Proof

The local set of `3` is exactly `{1,3,4}`, and primes `1\bmod{11}` do not enlarge it. The Type-I target lies in that three-element set precisely for the three rows `p\equiv7,8,10` of the table. QED.

The two remaining nonresidue classes `p\equiv2,6` have Type-I targets `5` and `9`, which lie in `Q\setminus Q_{\mathrm{thin}}`. Those classes are rescued only when extra QR valuation fills the whole subgroup.

---

## 5. Combined `q=11` miss

Combining the Type-II classification with the two rescue theorems:

### Theorem — combined hard-prime miss at `11`

A Mordell-hard prime misses both exact targets at shift `11` if and only if it is a Type-II miss of one of the following kinds:

1. **full-QR miss with residue side:** every prime factor of `C` is QR modulo `11`, the QR box is full, and `p` is itself a quadratic residue modulo `11`;
2. **thin-QR miss outside `{7,8,10}`:** `v_3(C)=1`, every other QR prime is `1\bmod{11}`, there is no primitive nonresidue packet, and `p\not\equiv7,8,10\pmod{11}`;
3. **thin primitive Branch B:** the existing Type-II Branch B holds, and the Type-I target additionally avoids the resulting signed box.

In particular Type I **does** contribute new hard-prime coverage at `q=11`, unlike `q=3` and `q=7`.

---

## 6. Finite signal

Through `2{,}000{,}000` there are `4519` Mordell-hard primes. After the exact `q=3` and `q=7` combined misses, the Type-II `q=11` filter solves `1057` further primes, and the Type-I companion solves an additional `13` primes that Type II missed. The remaining combined `3,7,11` core has size `711`.

Those `13` Type-I-only rescues are the first concrete corridor primes at which the second target is essential for original Erdős--Straus rather than for the strong/Type-II conjecture.
