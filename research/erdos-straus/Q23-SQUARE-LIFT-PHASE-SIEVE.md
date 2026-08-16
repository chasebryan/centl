# q23 square-lift canonical Type-II phase sieve

**Status:** exact modular phase theorem plus independently pinned earliest realized anchors  
**Date:** 2026-08-16  
**Primary classifier:** `classify_q23_square_lift_phase_sieve.py`  
**Independent verifier:** `verify_q23_square_lift_phase_sieve.py`  
**Depends on:** `PERIODIC-ROUTE-VALUATION-LADDER.md`, `K19-K23-REALIZED-SURVIVOR-COUPLING.md`, full signed-box Type-II geometry policy  
**Claim boundary:** this theorem controls only the canonical divisor `d=23^2` at the first-period q23 square lift. A blocked canonical phase may still hit by Type I or by a different Type-II divisor. An allowed phase does not guarantee a prime, a simultaneous earlier survivor, or a hit beyond the canonical congruence.

## 1. The next small state after k19/k23 coupling

Both realized h169 survivor routes contain the routed factor23 in

`C19=(p+19)/4`.

The q23 periodic route is

`k_n = 19 + 92n`.

Writing

`C19 = 23M`,

the landed valuation theorem gives

`C_{k_n} = 23(M+n)`.

Exactly one n modulo23 makes

`23 | M+n`,

so exactly one first-period representative has

`23^2 | C_{k_n}`.

At that square lift write

`C_{k_n} = 23^2 Q`.

The valuation theorem supplies the canonical divisor

`d=23^2`.

The full Type-II divisor-square target is reached by this divisor exactly when

`Q = -1 mod k_n`.

The question is therefore not whether the square lift exists. It always does. The question is which valuation phases are even arithmetically compatible with this canonical Type-II quotient congruence on the Mordell-hard class h169.

## 2. Canonical event equation

If

`Q = k s - 1`,

then

`C_k = 23^2(ks-1)`.

Since

`p = 4C_k-k`,

we obtain

`p = k(2116s-1)-2116`,

where

`2116=4*23^2`.

This is an exact parametrization of the canonical `d=23^2` Type-II event at the q23 square lift.

## 3. Hard-class phase obstruction

Impose

`p = 169 mod840`.

Substituting the canonical equation gives the linear congruence

`2116 k s = 169+k+2116 mod840`.

For

`k=k_n=19+92n`,

the right side is

`2304+92n = 4(576+23n)`.

Also

`gcd(2116k,840)=4*gcd(k,210)`,

because 529 is coprime to210.

Therefore the congruence is solvable if and only if

`gcd(k_n,210) | 576+23n`.

This is the exact phase sieve.

## 4. Exactly 13 allowed phases

For n modulo23, the canonical `d=23^2` Type-II event is arithmetically possible on h169 exactly for

```text
n = 0,3,5,6,8,11,12,14,15,17,18,20,21.
```

It is impossible for

```text
n = 1,2,4,7,9,10,13,16,19,22.
```

Thus the hard class eliminates 10 of the 23 first-period q23 valuation phases before primality, factorization, k19 mode, k23 support, or any other theorem is consulted.

The theorem is range-free.

## 5. Route A progressions: q17+q23 -> k19

The realized route additionally requires

`p mod17 = 15`.

For every allowed phase there is exactly one progression

`s = s0 mod T`.

The exact table is

```text
n   k      s0     T
0   19     2406   3570
3   295    387    714
5   479    1541   3570
6   571    126    3570
8   755    482    714
11  1031   731    3570
12  1123   666    3570
14  1307   446    3570
15  1399   951    3570
17  1583   3341   3570
18  1675   654    714
20  1859   1526   3570
21  1951   2721   3570
```

For any positive s in one of these progressions,

`p=k(2116s-1)-2116`

has the h169 hard class and the required q17 route residue; `p mod23=4` is automatic from the q23 route class.

This is a candidate parametrization, not a primality theorem.

## 6. Route B progressions: q23+q47 -> k19

The second realized route requires

`p mod47=28`.

Its canonical progressions are

```text
n   k      s0     T
0   19     9546   9870
3   295    513    1974
5   479    281    9870
6   571    126    9870
8   755    230    1974
11  1031   101    9870
12  1123   9696   9870
14  1307   6536   9870
15  1399   2421   9870
17  1583   7541   9870
18  1675   696    1974
20  1859   1526   9870
21  1951   6921   9870
```

Again each row is an exact arithmetic progression of canonical-event integers, not a promise that the values are prime or survive k19 and k23.

## 7. Earliest realized Route-A anchor

The independent verifier exhausts every canonical Route-A candidate below and including

`p=3,051,374,929`.

There are only38 such candidates across all13 allowed phases.

The earliest prime candidate that also misses both k19 and k23 is

`p=3,051,374,929`.

It occurs at

`n=8`,

`k=755`,

`s=1910`.

Its earlier survivor state is

`C19 = 762,843,737 = 17*23*1,951,007`,

with full QR(19) mask, and

`C23 = 762,843,738 = 2*3*71*1,790,713`,

with the rigid full QR(23) mask.

At the square-lift destination,

`C755 = 762,843,921 = 3*7*23^2*68,669`.

The quotient is

`Q=1,442,049`,

and

`Q = -1 mod755`.

Therefore `d=23^2=529` is exactly the Type-II target divisor.

At this anchor the Type-I target is absent, so the lift is **Type-II-only**.

This corrects the earlier phase-ordered exploratory impression that n=3 supplied the earliest Route-A event. The earlier probe stopped after collecting several n=3 examples and did not establish global minimality across phases.

## 8. Earliest realized Route-B anchor

The independent verifier similarly exhausts every canonical Route-B candidate below and including

`p=13,874,535,529`.

There are60 candidates across the allowed phases through this bound.

The earliest prime candidate that also misses k19 and k23 is

`p=13,874,535,529`.

It occurs at

`n=3`,

`k=295`,

`s=22,227`.

The earlier survivor state is

`C19 = 3,468,633,887 = 23*47*3,208,727`,

with full QR(19) mask, and

`C23 = 3,468,633,888 = 2^5*3*277*130,439`,

with full QR(23) mask.

At the lift,

`C295 = 3,468,633,956 = 2^2*23^2*1,639,241`.

The quotient is

`Q=6,556,964`,

with

`Q=-1 mod295`.

The canonical Type-II divisor therefore hits. Here the Type-I target is also present, so the lift is an **I+II** hit.

## 9. Why this matters

The same valuation mechanism can terminate in different exact signed-box geometries:

- Route A earliest anchor: Type II only;
- Route B earliest anchor: Type I and Type II simultaneously.

This is a concrete reason not to reduce the later search to López, a single Type-II boundary family, or a valuation-only criterion.

The valuation phase is one coordinate of the survivor state. The complete signed-box mask remains decisive.

## 10. What the sieve does and does not give

The theorem gives an exact modular pruning rule:

> if the q23 square-lift phase is one of the ten blocked n classes, the canonical divisor `d=23^2` cannot be the Type-II target on h169.

It does **not** say the destination misses.

A blocked phase may still hit by

- Type I;
- another Type-II divisor;
- both.

Likewise, an allowed phase merely admits the canonical congruence. It does not force the corresponding p to be prime, to enter either pair route, or to survive k19/k23.

This distinction should be preserved in CBX telemetry.

## 11. Next target

The current compact survivor object now contains

```text
k19 mode: FULL_QR | BARE
R support: QR19 | ONE19
k23 support: QR23
gcd(B,R)=1
q23 lift phase: n mod23
canonical phase allowed: yes | no
```

The next useful theorem question is whether the BARE support restriction `R primes =1 mod19`, together with the exact affine relation `6B-SR=1`, forbids some of the 13 canonical phases or forces a non-canonical signed-box hit on the ten blocked phases.

That is a genuinely smaller problem than the original character route graph.

Erdős-Straus remains open.
