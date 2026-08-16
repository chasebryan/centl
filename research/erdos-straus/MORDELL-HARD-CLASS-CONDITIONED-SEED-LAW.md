# Class-conditioned forced-seed law on the Mordell-hard skeleton

**Status:** proved elementary theorem  
**Date:** 2026-08-16  
**Depends on:** `MORDELL-HARD-FORCED-SEED-LAW.md`  
**Regression:** `verify_mordell_hard_class_conditioned_seeds.py`  
**Claim boundary:** this identifies the maximal divisor forced by one fixed Mordell-hard residue class modulo 840. It is an arithmetic-skeleton theorem, not a fixed-shift coverage theorem and not a proof of Erdős–Straus.

## 1. From the six-class seed to a single-class seed

The Mordell-hard residue skeleton is

\[
\boxed{
\mathcal H=\{1,121,169,289,361,529\}\pmod{840}.
}
\]

Fix one class

\[
p\equiv h\pmod{840},\qquad h\in\mathcal H,
\]

and write

\[
p=840r+h.
\]

For an admissible shift

\[
k\equiv3\pmod4,
\]

the companion is

\[
C_k=\frac{p+k}{4}
=210r+\frac{h+k}{4}.
\]

Define

\[
\boxed{
g_{k,h}:=\gcd\!\left(210,\frac{h+k}{4}\right).}
\]

Then `g_{k,h}` divides both terms and therefore

\[
\boxed{g_{k,h}\mid C_k}
\]

for every integer, and hence every prime, in the fixed hard class `h mod 840`.

## 2. Maximality inside one complete hard class

As `r` varies through all integers, the values of the companion form the arithmetic progression

\[
210r+c,
\qquad
c=\frac{h+k}{4}.
\]

The gcd of the complete progression is exactly

\[
\gcd(210,c).
\]

Thus:

### Theorem — maximal class-conditioned seed

For every hard residue class `h in H` and every admissible fixed shift `k`, the greatest integer dividing `C_k` for every integer `p=840r+h` is

\[
\boxed{
g_{k,h}=\gcd\!\left(210,\frac{h+k}{4}\right).}
\]

No larger divisor can be forced from that congruence class alone.

This theorem is stronger than the six-class seed law because it conditions on information already known about every Mordell-hard prime: its exact residue class modulo 840.

## 3. Exact factorization of the seed refinement

Every hard residue satisfies

\[
h\equiv1\pmod{24}.
\]

Write

\[
k=4u-1.
\]

Then

\[
\frac{h+k}{4}\equiv\frac{1+k}{4}=u\pmod6.
\]

Therefore the `2,3` part of `g_{k,h}` is exactly the universal seed

\[
g_k=\gcd(6,u).
\]

Since

\[
210=6\cdot35,
\qquad
\gcd(6,35)=1,
\]

one gets the exact product decomposition

\[
\boxed{
g_{k,h}=g_k\,e_{k,h},}
\]

where

\[
\boxed{
e_{k,h}:=\gcd\!\left(35,\frac{h+k}{4}\right)
\in\{1,5,7,35\}.}
\]

So the refinement is conceptually simple:

- the universal hard seed supplies all forced `2` and `3` content;
- the exact hard residue class may independently force `5`, `7`, or both.

## 4. The class-conditioned seed is always a unit modulo `k`

Every prime divisor of `g_{k,h}` belongs to

\[
\{2,3,5,7\}.
\]

The hard residues are units modulo 840, so no prime in `{2,3,5,7}` divides `h`.

Suppose a prime `q in {2,3,5,7}` divided both `g_{k,h}` and `k`. Since `q|g_{k,h}`, it divides `(h+k)/4`; multiplying by 4 gives

\[
q\mid h+k.
\]

Together with `q|k`, this would imply `q|h`, contradiction.

Hence

\[
\boxed{\gcd(g_{k,h},k)=1.}
\]

Every class-conditioned forced factor may therefore be consumed as an ordinary exact state transition at the fixed modulus.

## 5. Periodicity

For fixed `h`, increasing `k` by 840 increases `(h+k)/4` by 210. Therefore

\[
\boxed{g_{k+840,h}=g_{k,h}.}
\]

The class-conditioned seed wheel has exact period 840 in the shift.

The universal seed is the coarser period-24 projection obtained by taking the gcd across all six hard classes.

## 6. Quantitative refinement through `k<=5000`

There are 1,250 admissible shifts and six hard residue classes, giving

\[
7,500
\]

class-shift pairs.

The exact class-conditioned seed histogram is

```text
seed   class-shift pairs
1             1,717
2             1,714
3               854
5               427
6               858
7               287
10              430
14              287
15              216
21              142
30              214
35               71
42              141
70               71
105              36
210              35
```

Thus

\[
\boxed{5,783/7,500}
\]

class-shift pairs carry a nontrivial forced divisor.

Relative to the universal seed, the extra multiplier distribution is

```text
extra multiplier 1     5,143 pairs
extra multiplier 5     1,287 pairs
extra multiplier 7       857 pairs
extra multiplier 35      213 pairs
```

Therefore the exact hard residue class strictly strengthens the universal seed in

\[
\boxed{2,357/7,500}
\]

class-shift pairs.

## 7. Current fixed-shift examples

The refinement is not cosmetic.

### `k=39`

The universal seed is `2`, but the six class-conditioned seeds are

```text
h=1      -> 10
h=121    -> 10
h=169    ->  2
h=289    ->  2
h=361    -> 10
h=529    ->  2
```

Three hard classes therefore carry a mandatory factor `5` in addition to the universal factor `2`.

### `k=47`

The universal seed is `6`:

```text
h=1      ->  6
h=121    -> 42
h=169    ->  6
h=289    -> 42
h=361    ->  6
h=529    ->  6
```

Two hard classes force an additional factor `7`.

### `k=51`

The universal seed is trivial, but the class refinement is not:

```text
h=1      -> 1
h=121    -> 1
h=169    -> 5
h=289    -> 5
h=361    -> 1
h=529    -> 5
```

Thus half of the hard classes at k=51 have a mandatory factor `5` even though the six-class universal seed is `1`.

### `k=55`

The universal seed is `2`:

```text
h=1      -> 14
h=121    ->  2
h=169    -> 14
h=289    ->  2
h=361    ->  2
h=529    ->  2
```

Two classes carry a mandatory `7` as well.

### `k=59`

This is the strongest current example. The universal seed is only `3`, while the six conditioned seeds are

```text
h=1      ->  15
h=121    ->  15
h=169    ->   3
h=289    ->   3
h=361    -> 105
h=529    ->  21
```

So:

- two classes force `3*5`;
- two classes retain only `3`;
- one class forces `3*5*7=105`;
- one class forces `3*7=21`.

This predicts a much smaller class-resolved k=59 state atlas than the already-reduced 5,869-state universal forced-3 miss table.

### `k=63`

All six classes have seed `2`; there is no additional 5/7 refinement at this shift.

## 8. Relation to the residual wheel

The six-companion residual wheel strips only the maximal seed common to all hard classes. Conditioning on `h mod 840` can strip further factors `5` and `7` from individual residuals.

For example, in the `(55,59,63)` block:

\[
C_{55}=2A,
\qquad
C_{59}=3B,
\qquad
C_{63}=2D,
\]

with

\[
3B=2A+1,
\qquad
D=A+1.
\]

The class-conditioned theorem explains exact branch-specific factors visible in those residuals:

- some hard classes force `7|A`;
- some force `5|B`;
- some force `7|B`;
- one class forces `35|B`.

These are congruence-skeleton facts, not finite-prime accidents.

## 9. Correct state-analysis workflow

For a fixed shift and a known hard residue class, the strongest arithmetic seed available before factorization is now:

1. identify `h=p mod 840`;
2. compute
   \[
   g_{k,h}=\gcd\!\left(210,\frac{h+k}{4}\right);
   \]
3. consume the complete prime-valuation content of `g_{k,h}` as mandatory state transitions;
4. close only over the remaining factor directions;
5. retain any additional center/Jacobi restrictions appropriate to the modulus.

The earlier universal-seed closure remains useful when one wants a single class-independent theorem, but the class-conditioned closure is the natural object for the six actual Mordell-hard branches.

## 10. Reproduction

```sh
python3 research/erdos-straus/verify_mordell_hard_class_conditioned_seeds.py \
  --max-k 5000 --json
```

The verifier checks the formula, factorization through the universal seed, unit condition, exact 840-periodicity, histogram, and selected fixed-shift ledgers.

Erdős–Straus remains open. This theorem extracts all forced `2,3,5,7` divisibility available from the full Mordell-hard residue-class information before any actual factorization is performed.