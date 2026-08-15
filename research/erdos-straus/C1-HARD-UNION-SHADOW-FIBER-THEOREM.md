# Hard-class union shadows and the five-of-nine C1 3-adic fiber theorem

**Status:** proved exact row-domination and conditioned-fiber theorem  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this theorem applies to the stated Mordell-hard residue classes and the stated C1 residual row pattern. It proves the exact 3-adic extension lower bound for that pattern. It does not prove full C1, universal DSC-P, López universal coverage, or the Erdős-Straus conjecture.

Read with:

- [C1-ANCHOR-ROW-DOMINATION.md](C1-ANCHOR-ROW-DOMINATION.md)
- [C1-CONDITIONED-FIBER-31113.md](C1-CONDITIONED-FIBER-31113.md)
- [ANCESTRY-DIVISOR-CHILD-THEOREM.md](ANCESTRY-DIVISOR-CHILD-THEOREM.md)
- [CLASS-C-CENSUS-K1500.md](CLASS-C-CENSUS-K1500.md)

## 1. Hard residue facts

Let

\[
H=\{1,121,169,289,361,529\}\pmod{840}.
\]

Every `h in H` satisfies

\[
\boxed{h\equiv1\pmod3.}
\]

Modulo `21`, the six hard classes occupy only

\[
\boxed{H\pmod{21}=\{1,4,16\}.}
\]

These two elementary facts are enough to turn several apparently independent residual rows into exact union shadows.

## 2. The j=520 row is union-shadowed by j=3 and j=25

The relevant moduli are

\[
m_3=11,
\qquad
m_{25}=99,
\qquad
m_{520}=2079=21\cdot99.
\]

The trap sets needed below are

\[
T_3=\{7,8,10\}\pmod{11}
\]

and

\[
T_{25}=\{74,79,94,95,98\}\pmod{99}.
\]

Since

\[
\gcd(840,2079)=21,
\]

a trap at layer `520` can occur on a Mordell-hard integer only if its residue modulo `21` is one of `1,4,16`.

The complete hard-compatible portion of `T_520` is:

| `t in T_520` | `t mod 21` | `t mod 99 in T_25` | `t mod 11 in T_3` |
|---:|---:|:---:|:---:|
| 1975 | 1  | yes | no  |
| 2059 | 1  | yes | no  |
| 1663 | 4  | yes | no  |
| 1999 | 4  | no  | yes |
| 2053 | 16 | no  | yes |
| 2074 | 16 | yes | no  |

There are no other `T_520` residues in the three hard-compatible classes modulo `21`.

Therefore:

### Theorem 1: hard union shadow at j=520

For every integer `x` with

\[
x\pmod{840}\in H,
\]

\[
\boxed{
x\bmod2079\in T_{520}
\Longrightarrow
\left(
x\bmod99\in T_{25}
\quad\text{or}\quad
x\bmod11\in T_3
\right).}
\]

Thus, on every Mordell-hard progression, once layers `3` and `25` are avoided, layer `520` is automatically avoided.

This is stronger than the previously observed projected relation between the `j=25` and `j=520` parameter fibers. It is an exact two-anchor union shadow in `x`-space.

## 3. Exact one-class fiber at j=25

The hard condition gives

\[
x\equiv1\pmod3.
\]

The only traps in `T_25` compatible with that condition are

\[
\boxed{79,94.}
\]

Their residues modulo `11` are

\[
79\equiv2\pmod{11},
\qquad
94\equiv6\pmod{11}.
\]

They are distinct.

Hence:

### Lemma 2

After fixing the 11-coordinate of a hard-compatible parameter class, layer `j=25` can contribute at most one compatible trap.

In the common C1 residual regime

\[
\gcd(L,99)=3,
\qquad
q_{25}=33=3\cdot11,
\]

the affine pullback is a coordinatewise bijection. Therefore, after fixing the parameter modulo `11`, the `j=25` row forbids at most

\[
\boxed{1}
\]

residue modulo `3`.

Equivalently, when lifted to modulo `9`, it removes at most three of the nine classes.

## 4. Exact one-class fiber at j=88

Now

\[
m_{88}=351=27\cdot13.
\]

Again hard compatibility requires trap residue `1 mod 3`.

The complete compatible trap fiber is

\[
\boxed{
\{175,307,319,340,343,349\}.
}
\]

Their residues modulo `13` are respectively

\[
\boxed{6,8,2,5,11,7,}
\]

all distinct.

Therefore:

### Lemma 3

After fixing the 13-coordinate of a hard-compatible parameter class, layer `j=88` can contribute at most one compatible trap.

In the recurring C1 regime

\[
\gcd(L,351)=3,
\qquad
q_{88}=117=9\cdot13,
\]

the affine pullback preserves this fiber multiplicity. Thus after fixing the parameter modulo `13`, layer `j=88` forbids at most

\[
\boxed{1}
\]

residue modulo `9`.

## 5. Other apparent 3-adic rows are exact redundancies

The recurring `{3,11,13}` residual systems also display rows

\[
205,322,790.
\]

They contribute no independent 3-adic obstruction once the anchor rows are safe:

### j=205

\[
4(205)-1=21(4(10)-1),
\qquad
205=5\cdot41.
\]

By the divisor-child theorem,

\[
\boxed{T_{205}\bmod39\subseteq T_{10}.}
\]

### j=790

\[
4(790)-1=81(4(10)-1),
\qquad
790=10\cdot79.
\]

Again the divisor-child theorem gives

\[
\boxed{T_{790}\bmod39\subseteq T_{10}.}
\]

So the fine `3^4` row at `j=790` is completely redundant after layer `10` is avoided.

### j=322

The exact hard-compatible union-shadow theorem already proved in [C1-ANCHOR-ROW-DOMINATION.md](C1-ANCHOR-ROW-DOMINATION.md) gives

\[
\boxed{
x\equiv1\pmod3,\ x\bmod1287\in T_{322}
\Longrightarrow
x\bmod11\in T_3
\text{ or }
x\bmod39\in T_{10}.}
\]

Hence `j=322` is redundant after the unary anchors `j=3` and `j=10` are avoided.

### j=520

Theorem 1 above removes `j=520` after `j=3` and `j=25` are avoided.

Thus the entire 3-adic stage of this row pattern reduces exactly to

\[
\boxed{j=25\quad\text{and}\quad j=88.}
\]

## 6. Five-of-nine theorem

Fix a Mordell-hard progression in the recurring C1 row pattern and suppose the relevant 11- and 13-coordinates have already been chosen to avoid their unary anchors and the preceding pair stage.

By Lemma 2, `j=25` forbids at most one residue modulo `3`. Lifted to modulo `9`, this removes at most

\[
3
\]

classes.

By Lemma 3, `j=88` forbids at most one additional residue modulo `9`.

All other 3-adic rows are redundant by Section 5.

Therefore the total number of forbidden residue classes modulo `9` is at most

\[
3+1=4.
\]

Hence:

### Theorem 4: conditioned five-of-nine extension

For every Mordell-hard C1 residual system whose 3-coupled rows are the recurring pattern

\[
\{25,88,205,322,520,790\}
\]

or any subset thereof, after the anchor-safe 11/13 assignment is fixed,

\[
\boxed{
\#\{\text{safe 3-adic classes mod }9\}\ge5.
}
\]

In particular a 3-adic extension always exists.

If the residual 3-coordinate is actually modulo

\[
3^4=81,
\]

the only row reaching that precision is `j=790`, already dominated by `j=10`. Therefore every safe mod-9 class lifts freely to all nine classes modulo `81` above it, giving at least

\[
\boxed{45}
\]

safe full 3-adic values.

## 7. This exactly explains the finite conditioned-fiber spectrum

The frozen `k<=1500` `{3,11,13}` family exhibited safe full 3-fiber sizes

\[
\{5,6,8,9,45,54,72,81\}.
\]

The theorem explains the structure:

- the base values `5,6,8,9` are the possible surviving counts modulo `9`;
- the values `45,54,72,81` are exactly ninefold lifts when the coordinate extends to modulo `81`;
- the universal lower bound within this row pattern is `5`.

Thus the empirically observed minimum `5` is no longer merely a finite statistic. It follows from exact trap geometry plus exact ancestry/union-shadow domination.

## 8. A second hard union shadow: j=465

The same mechanism explains the fine `13^2` pair row.

Here

\[
m_{465}=1859=11\cdot13^2.
\]

For any hard integer `x`, we again have `x=1 mod 3`. Since `m_465` contains both `11` and `13`, a trap residue `t in T_465` determines `x mod11` and `x mod13`; together with `x=1 mod3`, the latter determines `x mod39`.

Direct enumeration of the 15 exact traps gives:

\[
\boxed{
x\bmod1859\in T_{465},\ x\equiv1\pmod3
\Longrightarrow
\left(
x\bmod143\in T_{36}
\ 	ext{or}\ 
x\bmod11\in T_3
\ 	ext{or}\ 
x\bmod39\in T_{10}
\right).}
\]

The only traps not already caught by `j=36` or `j=3` have 13-residues whose hard-compatible CRT lift modulo `39` is one of

\[
\boxed{19,31,34,37,}
\]

all belonging to `T_10`.

Therefore `j=465` is an exact three-anchor union shadow after `j=3`, `j=10`, and `j=36` are avoided.

This proves, rather than merely observes, why the fine `13^2` row introduces no new obstruction in the recurring conditioned-fiber family.

## 9. Where the remaining C1 work now sits

Two large chunks of the conditioned-fiber certificate have moved from computation into theorem:

1. the fine `13^2` row `j=465` is anchor-dominated;
2. the entire 3-adic stage has a proved five-of-nine lower bound.

The unresolved recurring pair-stage is therefore concentrated mainly in the coarse rows

\[
\boxed{j=36\quad\text{and, when present, }j=608,}
\]

after unary 11- and 13-adic constraints are imposed.

This is the next proof target.
