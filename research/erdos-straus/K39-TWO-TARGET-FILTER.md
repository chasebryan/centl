# Exact two-target filter at the composite shift `k=39`

**Status:** exact computer-assisted finite-group classification by conjugacy  
**Date:** 2026-08-16  
**Depends on:** `K35-TWO-TARGET-FILTER.md`, `FIXED-SHIFT-JACOBI-PARITY.md`, `ES-TWO-TARGET-DIVISOR-SQUARE.md`, `ES-BINARY-LANE-I-EQUIVALENCE.md`  
**Machine certificate:** `classify_k39_states.py` reusing the exact `C12 x C2` closure engine in `classify_k35_states.py`  
**Claim boundary:** this closes the fixed Lane-I shift `k=39`. It does not prove a universal finite shift ceiling and does not prove Erdős–Straus.

---

## 1. Setup

Let `p` be Mordell-hard and put

\[
\boxed{C=\frac{p+39}{4}.}
\]

Since every hard prime satisfies

\[
p\equiv1\pmod3,
\]

and `4=1 mod3`, one has

\[
\boxed{C\equiv1\pmod3.}
\]

Thus `C` always lies in the order-twelve subgroup of units modulo 39 that are `1 mod3`.

---

## 2. Exact group coordinates

CRT gives

\[
(\mathbb Z/39\mathbb Z)^\times
\cong
(\mathbb Z/3\mathbb Z)^\times
\times
(\mathbb Z/13\mathbb Z)^\times
\cong C_2\times C_{12}.
\]

Choose

\[
\boxed{h=28}
\]

with

\[
h\equiv1\pmod3,
\qquad
h\equiv2\pmod{13},
\]

so `h` has order 12. Choose

\[
\boxed{s=14}
\]

with

\[
s\equiv-1\pmod3,
\qquad
s\equiv1\pmod{13},
\]

so `s` is an involution outside the order-twelve subgroup.

Every unit is uniquely

\[
\boxed{x=s^\varepsilon h^a=14^\varepsilon28^a\pmod{39},}
\]

with

\[
(\varepsilon,a)\in C_2\times C_{12}.
\]

Because `C=1 mod3`, its center is always

\[
\boxed{c(C)=(0,c).}
\]

---

## 3. The exact targets

The fixed Type-I divisor-square target is

\[
-4^{-1}\equiv29\pmod{39}.
\]

In the coordinates above,

\[
\boxed{29=(1,4).}
\]

Also

\[
\boxed{-1=38=(1,6).}
\]

Therefore if `C=(0,c)`, the Type-II divisor target `-C` is

\[
\boxed{(1,c+6).}
\]

So the exact two-target test is

\[
\boxed{
(1,4)\in D(C)
\quad\text{or}\quad
(1,c+6)\in D(C),}
\]

where `D(C)` is the divisor-coordinate set of `C^2`.

---

## 4. The `k=35` state space transfers exactly

At `k=35`, the same abstract group `C_2 x C_12` has targets

\[
(1,8)
\quad\text{and}\quad
(1,c+6).
\]

Consider the automorphism

\[
\boxed{\Phi(\varepsilon,a)=(\varepsilon,5a).}
\]

Since `5` is a unit modulo 12,

\[
\Phi
\]

is an automorphism of `C_2 x C_12`. It satisfies

\[
\boxed{\Phi(1,8)=(1,4),}
\]

\[
\boxed{\Phi(1,6)=(1,6),}
\]

and, for every center `c`,

\[
\Phi(1,c+6)
=(1,5c+30)
=(1,5c+6).
\]

Thus it carries the `k=35` Type-I target to the `k=39` Type-I target while preserving the `-1` translation law.

The exact valuation transition

\[
(D,c)\mapsto(D+\{0,g,2g\},c+g)
\]

is functorial under every group automorphism. Hence `Phi` carries the entire closed factorization-state system at 35 to the corresponding system at 39.

### Conjugacy theorem

A state is a combined miss in the `k=35` abstract model if and only if its image under `Phi` is a combined miss in the `k=39` model.

This is an exact bijection of complete state spaces, not a numerical resemblance.

---

## 5. Complete finite-state classification

`classify_k39_states.py` independently reconstructs the admissible target set and verifies the full conjugacy against the `k=35` closure.

The exact constants are therefore

\[
\boxed{1298\text{ total closed states},}
\]

\[
\boxed{650\text{ hard-center admissible states},}
\]

\[
\boxed{418\text{ hit states},}
\]

and

\[
\boxed{232\text{ combined-miss states}.}
\]

Define the emitted 232-row table to be

\[
\boxed{\mathcal M_{39}.}
\]

### Theorem — exact fixed-`k=39` filter

For a Mordell-hard prime `p`, put

\[
C=\frac{p+39}{4}
\]

and form its exact divisor state `S(C)=(D(C),c(C))` in the coordinates above.

Then

\[
\boxed{
k=39\text{ misses both exact Lane-I targets}
\iff
S(C)\in\mathcal M_{39}.}
\]

No other miss state exists.

By `ES-BINARY-LANE-I-EQUIVALENCE.md`, this also closes the fixed binary selector `r=39`.

---

## 6. Pure `1 mod 3` support is an exact trap

If every prime factor of `C` is itself `1 mod3`, then every divisor of `C^2` remains in the subgroup

\[
\varepsilon=0.
\]

Both exact targets have

\[
\varepsilon=1.
\]

Hence pure subgroup support is an automatic combined miss.

The state closure contains exactly

\[
\boxed{92}
\]

pure-subgroup states and

\[
\boxed{92/92}
\]

miss.

The remaining

\[
\boxed{140}
\]

miss states are non-pure.

---

## 7. Outside-core compression transfers from `k=35`

Under the exact conjugacy, the minimum number of outside-subgroup valuation units needed to represent each miss state has the same distribution:

\[
\boxed{
\begin{array}{c|c}
\text{minimum outside units}&\text{miss states}\\
\hline
0&92\\
2&138\\
4&2
\end{array}}
\]

Thus every `k=39` miss state has a state-equivalent core using at most four factors that are `2 mod3`, counted with valuation.

As at 35, this is a statement about a minimum **state representative**, not a bound on the actual number of outside prime-factor occurrences in `C`.

The two minimum-four states again have 21 of the 24 divisor coordinates filled and have coincident Type-I and Type-II targets.

Their common center coordinate is

\[
\boxed{c=(0,10),}
\]

for which

\[
(1,c+6)=(1,4)=\tau_I.
\]

One four-unit core uses outside residues

\[
\boxed{32,32,17,23\pmod{39},}
\]

while the other uses

\[
\boxed{23,23,2,2\pmod{39}.}
\]

---

## 8. The fixed-shift Jacobi parity becomes the parity of `c`

Because `h=28` reduces to the primitive root `2 mod13`, the quadratic character modulo 13 is simply the parity of the `C_12` log:

\[
\boxed{
\left(\frac C{13}\right)=(-1)^c.}
\]

Also

\[
C\equiv4^{-1}p\pmod{13},
\]

and `4` is a square, so

\[
\left(\frac C{13}\right)
=
\left(\frac p{13}\right)
=
\left(\frac{13}{p}\right).
\]

Therefore

\[
\boxed{(-1)^c=\left(\frac{13}{p}\right).}
\]

This is exactly the `k=39` specialization of `FIXED-SHIFT-JACOBI-PARITY.md`:

- even `c` corresponds to `(13/p)=+1` and an even outside-nonresidue packet;
- odd `c` corresponds to `(13/p)=-1` and an odd packet.

Among the exact 232 miss states, the split is

\[
\boxed{122\text{ states with }(13/p)=+1,}
\]

\[
\boxed{110\text{ states with }(13/p)=-1.}
\]

Thus both parity branches are genuinely present in the complete fixed-shift exception table.

---

## 9. Independent 10M regression

The preserved CBX standalone relation through

\[
p\le10^7
\]

contains

\[
\boxed{20,513}
\]

Mordell-hard primes.

An independent factorization/state reconstruction at `k=39` gives

```text
direct CBX k=39 hits      12,769
state-classifier hits     12,769
mismatches                     0
```

The finite population splits by the Legendre branch as

```text
(13/p) = -1 :  9,247 hits, 1,161 misses
(13/p) = +1 :  3,522 hits, 6,583 misses
```

These are finite population counts only. The exact theorem is the complete state conjugacy and closure above.

---

## 10. Corridor consequence

After the completely classified shifts through

\[
3,7,11,15,19,23,27,31,35,
\]

the preserved 10M corpus leaves

\[
\boxed{48}
\]

hard primes entering `k=39`.

They split as

```text
(13/p)=+1 : 11 hits, 24 misses
(13/p)=-1 : 11 hits,  2 misses
```

so shift 39 removes

\[
\boxed{22}
\]

and leaves

\[
\boxed{26}
\]

finite corridor survivors.

Their next first-hit distribution is

```text
k=43    5
k=47   15
k=51    1
k=55    2
k=59    2
k=107   1
```

Again, this is theorem-hunting evidence, not a universal bound.

The next local fixed-shift target is

\[
\boxed{k=43.}
\]

---

## 11. Reproduction

Run

```sh
python3 research/erdos-straus/classify_k39_states.py --json
```

or emit the entire exact table with

```sh
python3 research/erdos-straus/classify_k39_states.py --json --table
```

Hard regression constants are:

```text
total states                 1298
admissible states              650
hit states                     418
miss states                    232
pure-subgroup states            92
pure-subgroup misses             92
non-pure miss states           140
miss symmetry orbits           149
minimum-outside histogram   {0:92, 2:138, 4:2}
Legendre miss split         {+1:122, -1:110}
k35 conjugacy verified        true
```

---

Erdős–Straus remains open. Fixed `k=39` is now completely classified, and the exact equivalence with the `k=35` state geometry exposes a reusable conjugacy pattern for future composite corridor layers.
