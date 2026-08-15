# Forced positive-kernel detectors

**Status:** proved exact theorem family  
**Date:** 2026-08-15  
**Depends on:** `FAB-RECIPROCAL-SIGNED-TARGET.md`, `FAB-RECIPROCAL-CHARACTER-TRANSPORT.md`, `FAB-SIX-FORM-NONRESIDUE-DETECTOR.md`  
**Claim boundary:** these are exact local detector theorems. They do not prove that one detector fires for every Mordell-hard prime.

## 1. Signed divisor reach

For an odd squarefree integer

\[
d\equiv3\pmod4,
\]

write

\[
\chi_d(u)=\left(\frac ud\right)
\]

for the Jacobi character on the unit group, and let

\[
\boxed{H_d=\ker\chi_d.}
\]

For a positive integer `n` coprime to `d`, with

\[
n=\prod_r r^{e_r},
\]

define

\[
\Sigma_d(n)
=
\left\{
\prod_r r^{z_r}\pmod d:
-e_r\le z_r\le e_r
\right\}.
\]

This is the bounded signed divisor set used by the forward and reciprocal fab criteria.

## 2. Forced-kernel lemma

Suppose a lane base `B` has a known divisor `F|B` such that

1. every prime factor of `F` has Jacobi character `+1` modulo `d`; and
2. the signed reach of the forced divisor fills the complete positive kernel:
   \[
   \boxed{H_d\subseteq\Sigma_d(F).}
   \]

Then any prime factor `r|B` with

\[
\chi_d(r)=-1
\]

forces every negative-character target to occur in `Sigma_d(B)`.

### Proof

Let `T` be any unit with

\[
\chi_d(T)=-1.
\]

If `r|B` has `chi_d(r)=-1`, then

\[
\chi_d(Tr^{-1})=+1,
\]

so

\[
Tr^{-1}\in H_d\subseteq\Sigma_d(F).
\]

Use one available occurrence of `r` with signed exponent `+1`; it is disjoint from the forced positive-character support. Multiplying gives

\[
(Tr^{-1})r=T.
\]

Hence `T in Sigma_d(B)`. QED.

Conversely, if every prime factor of `B` has positive character, then every signed product also has positive character, so no negative-character target can occur.

Therefore:

### Theorem — exact forced-kernel detector

Under the two hypotheses above, for any negative-character signed target `T`,

\[
\boxed{
T\in\Sigma_d(B)
\iff
B\text{ has a prime factor }r\text{ with }\chi_d(r)=-1.
}
\]

For a Mordell-hard prime `p`, character transport converts the right side into

\[
\boxed{
\left(\frac rp\right)=-1.
}
\]

Thus a lane satisfying the forced-kernel hypotheses becomes an exact detector for an external quadratic nonresidue of `p`.

## 3. Forward versus reciprocal targets

For the reciprocal base

\[
Y_d=\frac{pd+1}{4},
\]

the signed target is always

\[
\boxed{-1,}
\]

which has negative Jacobi character because `d=3 mod4`.

So the forced-kernel theorem applies directly whenever its hypotheses hold.

For the forward base

\[
X_d=\frac{p+d}{4},
\]

the signed target is

\[
\boxed{-p\pmod d.}
\]

Its Jacobi character is negative exactly when

\[
\boxed{\left(\frac pd\right)=+1.}
\]

Hence the same exact detector conclusion holds in the forward lane whenever `p` is a quadratic/Jacobi residue modulo `d` and the forced kernel is saturated.

## 4. Detector at d = 11

Modulo `11`, the quadratic-residue kernel is

\[
\boxed{H_{11}=\{1,3,4,5,9\}.}
\]

One occurrence each of the residues `3` and `5` already saturates it:

\[
\boxed{
\Sigma_{11}(3\cdot5)=H_{11}.
}
\]

Indeed

\[
\{1,3,3^{-1}\}\{1,5,5^{-1}\}
=\{1,3,4,5,9\}.
\]

Every Mordell-hard prime is `1 mod24`, so `3` divides both

\[
X_{11}=\frac{p+11}{4}
\qquad\text{and}\qquad
Y_{11}=\frac{11p+1}{4}.
\]

If

\[
p\equiv9\pmod{20},
\]
then `5` divides both forms as well.

Among the six hard classes modulo `840`, this occurs exactly for

\[
\boxed{p\equiv169,289,529\pmod{840}.}
\]

For these three classes, `p` is also a quadratic residue modulo `11`:

\[
169\equiv4,
\qquad289\equiv3,
\qquad529\equiv1
\pmod{11}.
\]

Therefore:

### Theorem — d = 11 class detectors

For every Mordell-hard prime in one of the classes

\[
\boxed{169,289,529\pmod{840},}
\]
**both** the forward and reciprocal `d=11` lanes succeed if and only if their respective base contains a prime factor `r` with

\[
\boxed{\left(\frac rp\right)=-1.}
\]

## 5. Detector at d = 19

The quadratic-residue kernel modulo `19` is

\[
\boxed{H_{19}=\{1,4,5,6,7,9,11,16,17\}.}
\]

One occurrence each of `5` and `7` saturates it exactly:

\[
\boxed{
\Sigma_{19}(5\cdot7)=H_{19}.
}
\]

### Forward class 121

If

\[
p\equiv121\pmod{840},
\]
then

\[
5\mid X_{19}
\]

because `p=1 mod20`, and

\[
7\mid X_{19}
\]

because `p=9 mod28`.

Also

\[
p\equiv7\pmod{19},
\]
which is a quadratic residue modulo `19`.

Hence the forward `d=19` lane is an exact nonresidue detector on hard class `121 mod840`.

### Reciprocal class 361

If

\[
p\equiv361\pmod{840},
\]
then

\[
5\mid Y_{19}
\]

because `p=1 mod20`, and

\[
7\mid Y_{19}
\]

because `p=25 mod28`.

Therefore the reciprocal `d=19` lane is an exact nonresidue detector on hard class `361 mod840`.

So:

\[
\boxed{
\begin{aligned}
p\equiv121\pmod{840}:&\quad
\text{forward }d=19\text{ fires iff }X_{19}\text{ contains a }p\text{-nonresidue prime},\\
p\equiv361\pmod{840}:&\quad
\text{reciprocal }d=19\text{ fires iff }Y_{19}\text{ contains a }p\text{-nonresidue prime}.
\end{aligned}}
\]

## 6. Detector at d = 31

The quadratic-residue kernel modulo `31` has fifteen elements:

\[
\boxed{
H_{31}=\{1,2,4,5,7,8,9,10,14,16,18,19,20,25,28\}.
}
\]

One occurrence each of `2`, `5`, and `7` saturates it:

\[
\boxed{
\Sigma_{31}(2\cdot5\cdot7)=H_{31}.
}
\]

### Forward class 529

For

\[
p\equiv529\pmod{840},
\]
we have

\[
2\mid X_{31}
\]
from `p=1 mod8`,

\[
5\mid X_{31}
\]
from `p=9 mod20`, and

\[
7\mid X_{31}
\]
from `p=25 mod28`.

Moreover

\[
p\equiv2\pmod{31},
\]
and `2` is a quadratic residue modulo `31`.

Therefore the forward `d=31` lane is an exact nonresidue detector on hard class `529 mod840`.

### Reciprocal class 289

For

\[
p\equiv289\pmod{840},
\]
we have

\[
2\mid Y_{31},
\qquad
5\mid Y_{31},
\qquad
7\mid Y_{31}.
\]

Indeed the three divisibilities follow respectively from

\[
p\equiv1\pmod8,
\qquad
p\equiv9\pmod{20},
\qquad
p\equiv9\pmod{28}.
\]

Hence the reciprocal `d=31` lane is an exact nonresidue detector on hard class `289 mod840`.

Thus:

\[
\boxed{
\begin{aligned}
p\equiv529\pmod{840}:&\quad
\text{forward }d=31\text{ fires iff }X_{31}\text{ contains a }p\text{-nonresidue prime},\\
p\equiv289\pmod{840}:&\quad
\text{reciprocal }d=31\text{ fires iff }Y_{31}\text{ contains a }p\text{-nonresidue prime}.
\end{aligned}}
\]

## 7. Structural consequence

The detector architecture is no longer limited to the universal `d=3,7,15` triad.

The Mordell-hard residue class itself can force enough positive-character factors into a moving linear form to saturate the full positive kernel at a larger modulus. Once that happens, **any single external nonresidue prime factor is automatically selectable into the fab target**.

The next theorem target is therefore not merely "find more good constants." It is:

> classify the pairs `(hard class h, modulus d)` for which hard-class congruences force a divisor `F` whose signed reach equals `H_d`, and then prove that one of the corresponding moving bases must import a `p`-nonresidue prime.

This separates the local group-theoretic problem, which is finite and exact, from the remaining global factor-existence problem.
