# Hard-prime forced-3 reduction at `k=59`

**Status:** exact computer-assisted hard-prime state reduction  
**Date:** 2026-08-16  
**Depends on:** `K59-TWO-TARGET-FILTER.md`  
**Machine certificate:** `classify_k59_forced3_states.py`  
**Independent finite regression:** `verify_k59_forced3_structure.py`  
**Claim boundary:** every Mordell-hard prime state at fixed `k=59` lies in the reduced closure proved here. The closure is a hard-prime superset, not a claim that every abstract reduced state is realized by a prime. This does not prove Erdős–Straus.

## 1. A universal factor was hidden in the hard-prime coordinate

Every Mordell-hard prime has

\[
p=24m+1.
\]

At shift `k=59`,

\[
C_{59}=\frac{p+59}{4}
=\frac{24m+60}{4}
=6m+15
=3(2m+5).
\]

Therefore

\[
\boxed{3\mid C_{59}}
\]

for every Mordell-hard prime.

This is range-free arithmetic. It does not depend on a finite prime census.

## 2. Forced starting state

The fixed-59 unit group is

\[
(\mathbb Z/59\mathbb Z)^\times\cong C_{58},
\]

with primitive root `2` as in `K59-TWO-TARGET-FILTER.md`.

The forced factor has log

\[
\boxed{\log_2 3=50\pmod{58}.}
\]

One mandatory valuation occurrence therefore changes the empty state from

\[
(\{0\},0)
\]

to

\[
\boxed{S_3=T_{50}(\{0\},0).}
\]

The divisor-log set in this seed has size three, corresponding to the exact local packet

\[
\{0,50,100\}\pmod{58}.
\]

Every actual Mordell-hard `C59` factorization is obtained from this seed by applying the ordinary exact transitions for the remaining prime-valuation occurrences. Thus every hard-prime state lies in the closure of `S3`.

## 3. Exact reduced closure

The generic fixed-59 closure contains

\[
291,907
\]

states and 61,215 miss states.

Starting instead from the universally forced factor-3 seed and closing under all 58 possible subsequent directions gives exactly

\[
\boxed{35,740\text{ states}.}
\]

Among them,

\[
\boxed{29,871\text{ hit states}}
\]

and

\[
\boxed{5,869\text{ combined-miss states}.}
\]

So the hard-prime arithmetic compresses the exact obstruction space from

\[
61,215\longrightarrow5,869
\]

before any finite prime bound is introduced.

### Theorem — forced-3 hard containment

For every Mordell-hard prime `p`, the exact fixed-59 state of

\[
C_{59}=\frac{p+59}{4}
\]

belongs to this 35,740-state closure.

Consequently every actual hard-prime fixed-59 miss belongs to the emitted 5,869-state reduced miss table.

The reverse realization statement is not asserted.

## 4. The forced factor is quadratic-residue support

Because the forced log is even,

\[
50\equiv0\pmod2,
\]

the mandatory factor `3` is a quadratic residue modulo 59.

Thus the seed does not flip center parity and does not change the interpretation

\[
(-1)^c=\left(\frac{59}{p}\right).
\]

The 5,869 reduced miss states split as

\[
\boxed{3,148\text{ with }(59/p)=+1}
\]

and

\[
\boxed{2,721\text{ with }(59/p)=-1.}
\]

Both character branches remain possible in the reduced hard superset.

## 5. The apparent five-packet breach disappears

The generic k=59 closure has 283 miss states whose smallest state-equivalent representative needs five nonresidue valuation units.

After the universally forced factor 3 is imposed, minimize only the **additional** odd-log valuation units needed beyond the seed. The exact reduced histogram is

```text
minimum added NR units   miss states
0                            900
1                          2,263
2                          2,185
3                            458
4                             63
```

No reduced miss needs five added nonresidue units.

Hence

\[
\boxed{\text{every hard-prime k=59 miss state has a state-equivalent forced-3 representative with at most four additional NR units}.}
\]

This restores the four-unit hard-state ceiling that appeared at the earlier classified shifts. It does **not** prove that four is a universal ceiling for arbitrary future shifts.

## 6. Pure quadratic-residue branch

Starting from the forced-3 seed and allowing only even-log directions produces exactly

\[
\boxed{900}
\]

states. Every one is a miss:

\[
\boxed{900/900.}
\]

This is the forced-seed version of the generic pure-QR miss branch.

## 7. Independent finite regression

`verify_k59_forced3_structure.py` independently generates Mordell-hard primes, proves `3|C59` for each generated prime, factors `C59`, consumes one mandatory factor 3, reconstructs the reduced state, and compares it with the direct divisor-square target test.

The Fedora regression through `100,000` has the same finite fixed-59 outcomes as the generic verifier:

```text
hard primes     273
k=59 hits       117
k=59 misses     156
mismatches        0
```

The finite regression checks realization inside the exact closure. The reduction theorem itself comes from the identity `C59=3(2m+5)` and exhaustive finite-group closure from the forced seed.

## 8. Reproduction

```sh
python3 research/erdos-straus/classify_k59_forced3_states.py --json
python3 research/erdos-straus/verify_k59_forced3_structure.py --limit 100000 --json
```

The full 5,869-row reduced miss table is emitted with `--table`.

Hard regression constants:

```text
forced factor                    3
forced log                      50
forced seed divisor-set size     3
reduced states              35,740
reduced hits                29,871
reduced misses               5,869
pure-QR states                 900
pure-QR misses                 900
Legendre split        {+1:3148, -1:2721}
minimum added NR      {0:900, 1:2263, 2:2185, 3:458, 4:63}
```

Erdős–Straus remains open. The significance is that the generic k=59 obstruction geometry is much larger than the state space available to Mordell-hard primes once their universally forced factor is respected.
