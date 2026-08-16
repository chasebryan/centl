# Exact two-target filter at the composite shift `k=51`

**Status:** exact computer-assisted finite-group classification  
**Date:** 2026-08-16  
**Depends on:** `FIXED-SHIFT-JACOBI-PARITY.md`, `ES-TWO-TARGET-DIVISOR-SQUARE.md`, `ES-BINARY-LANE-I-EQUIVALENCE.md`  
**Machine certificate:** `classify_k51_states.py`  
**Independent finite regression:** `verify_k51_structure.py`  
**Claim boundary:** this closes the fixed Lane-I shift `k=51`. It does not prove a universal finite shift ceiling and does not prove Erdős–Straus.

## 1. Group and hard-prime center

Let `p` be Mordell-hard and put

\[
C=\frac{p+51}{4}.
\]

Since every Mordell-hard prime satisfies `p = 1 mod 3`, one has

\[
C\equiv1\pmod3.
\]

The unit group is

\[
(\mathbb Z/51\mathbb Z)^\times\cong C_{16}\times C_2.
\]

Use coordinates

\[
x=35^\varepsilon 37^a\pmod{51},\qquad
\varepsilon\in C_2,\ a\in C_{16}.
\]

Here `37` has order 16, `35` is an involution, and

\[
H=\{x:x\equiv1\pmod3\}=\{(0,a):a\in C_{16}\}.
\]

Thus every hard-prime center lies in `H`.

## 2. Exact targets

The divisor-square Type-I target is

\[
-4^{-1}\equiv38\pmod{51},
\]

whose coordinate is

\[
(1,12).
\]

Also

\[
-1=(1,8).
\]

If the center is `(0,c)`, the Type-II target `-C` is therefore

\[
(1,c+8).
\]

Both targets lie outside `H`.

For a factorization of `C`, one valuation occurrence in coordinate `g` acts by the exact divisor-square transition

\[
T_g(D,c)=\left(D+\{0,g,2g\},c+g\right).
\]

Closing the empty state under all 32 unit directions exhausts arbitrary factorization residue states.

## 3. Exact finite closure

The least closed state space contains exactly

\[
\boxed{6217}
\]

states. Of these,

\[
\boxed{2907}
\]

have hard-prime-admissible center in `H`.

Applying the two targets gives

\[
\boxed{2000\text{ hit states}}
\]

and

\[
\boxed{907\text{ combined-miss states}.}
\]

Therefore the emitted 907-state miss table is the complete fixed-`k=51` obstruction geometry. This statement is range-free: it is closure inside the finite unit group, not extrapolation from a prime bound.

## 4. Pure-H branch

Closing only the 16 directions in `H` produces exactly

\[
\boxed{293}
\]

states. Since both targets are outside `H`, every pure-H state misses:

\[
\boxed{293/293.}
\]

The other

\[
\boxed{614}
\]

miss states use outside-H support.

## 5. Four-unit outside-H cutoff

For each exact state, minimize lexicographically

\[
(\text{outside-H valuation units},\ \text{total valuation units}).
\]

Among all 907 misses the exact distribution is

\[
\begin{array}{c|r}
\text{minimum outside-H units}&\text{miss states}\\
\hline
0&293\\
2&602\\
4&12
\end{array}
\]

Hence

\[
\boxed{\text{every fixed-51 miss state has a state-equivalent representative using at most four outside-H valuation units}.}
\]

Only even packet counts occur because the final hard-prime center must return to `H`.

## 6. Character split

Modulo 17, the chosen generator `37` reduces to primitive root `3`. Since `4` is a square and `51 = 0 mod 17`, the parity of the `C16` center coordinate is exactly the quadratic character of `p` modulo 17. Because `17 = 1 mod 4`, quadratic reciprocity gives

\[
(-1)^c=\left(\frac{17}{p}\right).
\]

The exact 907 miss states split as

\[
\boxed{463\text{ with }(17/p)=+1}
\]

and

\[
\boxed{444\text{ with }(17/p)=-1.}
\]

Both character branches contain fixed-shift misses.

## 7. Target-preserving symmetry

The four automorphisms

\[
(\varepsilon,a)\mapsto(\varepsilon,ma),
\qquad m\in\{1,5,9,13\},
\]

fix both `(1,12)` and the `-1` translation `(1,8)`. They preserve the complete miss set.

The 907 misses collapse to

\[
\boxed{273\text{ symmetry orbits},}
\]

with orbit-size histogram

```text
size 1 :  31
size 2 :  46
size 4 : 196
```

This is the smaller canonical object for later cross-shift mining.

## 8. Independent regression

`verify_k51_structure.py` independently generates Mordell-hard primes, factors `C`, builds the divisor residue set of `C^2` directly modulo 51, and compares direct target membership with the finite-state classifier.

The Fedora-sized regression through `100,000` gives

```text
hard primes     273
k=51 hits        54
k=51 misses     219
mismatches        0
```

During derivation an independent direct signed-box census through `100,000,000` gave

```text
hard primes     179,468
k=51 hits        59,424
k=51 misses     120,044
mismatches             0
```

Character outcomes on that finite 100M census were

```text
(17/p)=+1 : 18,070 hits, 71,205 misses
(17/p)=-1 : 41,354 hits, 48,839 misses
```

These population counts are finite evidence. The fixed-shift theorem is the closed finite-group state system above.

## 9. Corrected 100M corridor

Using a complete hard-prime universe, rather than the union of hit rows, exactly 29 hard primes through 100M survive every classified shift through `k=47`.

At `k=51`:

```text
hits      7
misses   22
```

with character split

```text
(17/p)=+1 : 5 hits, 18 misses
(17/p)=-1 : 2 hits,  4 misses
```

The 22 remaining primes first hit later at `k=55`, `59`, `63`, or `107`. This is finite theorem-mining evidence only.

## 10. Reproduction

```sh
python3 research/erdos-straus/classify_k51_states.py --json
python3 research/erdos-straus/verify_k51_structure.py --limit 100000 --json
```

The complete 907-row miss table is emitted by

```sh
python3 research/erdos-straus/classify_k51_states.py --json --table
```

Hard regression constants are

```text
total states                 6,217
admissible states            2,907
hit states                   2,000
miss states                    907
pure-H states                  293
pure-H misses                  293
nonpure misses                 614
symmetry orbits                273
Legendre(17/p) split     {+1:463, -1:444}
minimum outside-H       {0:293, 2:602, 4:12}
```

Erdős–Straus remains open. Fixed `k=51` is now completely classified; the corrected corridor moves next to `k=55`.
