# Forced positive-kernel detectors

**Status:** proved exact theorem family; corrected forward-character split  
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

## 2. Forced-kernel lemma

Suppose a lane base `B` has a known divisor `F|B` such that

1. every prime factor of `F` has Jacobi character `+1` modulo `d`; and
2. its signed reach fills the complete positive kernel:
   \[
   \boxed{H_d\subseteq\Sigma_d(F).}
   \]

Then any negative-character target `T` occurs in `Sigma_d(B)` if and only if `B` has at least one prime factor `r` with

\[
\chi_d(r)=-1.
\]

### Proof

If every prime factor of `B` has positive character, every signed product has positive character, so a negative target is impossible.

Conversely let `r|B` have negative character. Then for a negative target `T`,

\[
\chi_d(Tr^{-1})=+1,
\]

so

\[
Tr^{-1}\in H_d\subseteq\Sigma_d(F).
\]

The negative prime `r` cannot belong to the positive-character forced support. Use one occurrence of it with exponent `+1` and multiply:

\[
(Tr^{-1})r=T.
\]

QED.

Thus:

### Theorem — negative-target detector

Under the forced-kernel hypotheses,

\[
\boxed{
\chi_d(T)=-1
\Longrightarrow
\left[
T\in\Sigma_d(B)
\iff
\exists r\mid B:\ \chi_d(r)=-1
\right].
}
\]

For a Mordell-hard prime `p`, character transport converts

\[
\chi_d(r)=-1
\]

for a prime factor of `X_d` or `Y_d` into

\[
\boxed{\left(\frac rp\right)=-1.}
\]

## 3. Reciprocal and forward consequences

### Reciprocal lane

For

\[
Y_d=\frac{pd+1}{4},
\]

the signed target is always

\[
\boxed{-1.}
\]

Since `d=3 mod4`,

\[
\chi_d(-1)=-1.
\]

Therefore whenever the forced kernel is saturated,

\[
\boxed{
\text{reciprocal lane succeeds}
\iff
Y_d\text{ contains a prime }r\text{ with }(r/p)=-1.
}
\]

### Forward lane

For

\[
X_d=\frac{p+d}{4},
\]

the signed target is

\[
\boxed{-p\pmod d,}
\]

with character

\[
\chi_d(-p)
=-\chi_d(p).
\]

Therefore the forced-kernel conclusion has two cases:

#### If `chi_d(p) = -1`

Then the target `-p` has **positive** character, hence already lies in

\[
H_d\subseteq\Sigma_d(F).
\]

So the forward lane succeeds **automatically**, without needing an additional nonresidue factor.

#### If `chi_d(p) = +1`

Then the target `-p` has negative character, and the detector theorem gives

\[
\boxed{
\text{forward lane succeeds}
\iff
X_d\text{ contains a prime }r\text{ with }(r/p)=-1.
}
\]

This correction is important: a hard residue class modulo `840` does not in general determine `p mod d` for primes `d` such as `11,19,31`.

## 4. Forced kernel at d = 11

Modulo `11`,

\[
\boxed{H_{11}=\{1,3,4,5,9\}.}
\]

One occurrence each of `3` and `5` saturates it:

\[
\boxed{
\Sigma_{11}(3\cdot5)=H_{11}.
}
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
then `5` divides both forms as well. Among the six hard classes modulo `840`, this occurs exactly for

\[
\boxed{p\equiv169,289,529\pmod{840}.}
\]

Hence for these three hard classes:

### Reciprocal d = 11

\[
\boxed{
\text{reciprocal }d=11\text{ succeeds}
\iff
Y_{11}\text{ contains a prime }r\text{ with }(r/p)=-1.
}
\]

### Forward d = 11

\[
\boxed{
\left(\frac p{11}\right)=-1
\Longrightarrow
\text{forward }d=11\text{ succeeds automatically},
}
\]

while

\[
\boxed{
\left(\frac p{11}\right)=+1
\Longrightarrow
\left[
\text{forward }d=11\text{ succeeds}
\iff
X_{11}\text{ contains a }p\text{-nonresidue prime}
\right].
}
\]

## 5. Forced kernel at d = 19

Modulo `19`,

\[
\boxed{H_{19}=\{1,4,5,6,7,9,11,16,17\},}
\]

and one occurrence each of `5` and `7` saturates it:

\[
\boxed{
\Sigma_{19}(5\cdot7)=H_{19}.
}
\]

### Forward hard class 121

For

\[
p\equiv121\pmod{840},
\]
we have

\[
5\mid X_{19}
\]

from `p=1 mod20`, and

\[
7\mid X_{19}
\]

from `p=9 mod28`.

Therefore

\[
\boxed{
\left(\frac p{19}\right)=-1
\Longrightarrow
\text{forward }d=19\text{ succeeds automatically},
}
\]

and if `(p/19)=+1`, the forward lane succeeds exactly when `X_19` contains a `p`-nonresidue prime factor.

### Reciprocal hard class 361

For

\[
p\equiv361\pmod{840},
\]
we have

\[
5\mid Y_{19}
\]

from `p=1 mod20`, and

\[
7\mid Y_{19}
\]

from `p=25 mod28`.

Thus

\[
\boxed{
\text{reciprocal }d=19\text{ succeeds}
\iff
Y_{19}\text{ contains a prime }r\text{ with }(r/p)=-1.
}
\]

## 6. Forced kernel at d = 31

Modulo `31`,

\[
\boxed{
H_{31}=\{1,2,4,5,7,8,9,10,14,16,18,19,20,25,28\},
}
\]

and

\[
\boxed{
\Sigma_{31}(2\cdot5\cdot7)=H_{31}.
}
\]

### Forward hard class 529

For

\[
p\equiv529\pmod{840},
\]
we have

\[
2\mid X_{31},
\qquad5\mid X_{31},
\qquad7\mid X_{31},
\]

from respectively `p=1 mod8`, `p=9 mod20`, and `p=25 mod28`.

Therefore

\[
\boxed{
\left(\frac p{31}\right)=-1
\Longrightarrow
\text{forward }d=31\text{ succeeds automatically},
}
\]

and if `(p/31)=+1`, the lane succeeds exactly when `X_31` contains a `p`-nonresidue prime factor.

### Reciprocal hard class 289

For

\[
p\equiv289\pmod{840},
\]
we have

\[
2\mid Y_{31},
\qquad5\mid Y_{31},
\qquad7\mid Y_{31},
\]

from respectively `p=1 mod8`, `p=9 mod20`, and `p=9 mod28`.

Thus

\[
\boxed{
\text{reciprocal }d=31\text{ succeeds}
\iff
Y_{31}\text{ contains a prime }r\text{ with }(r/p)=-1.
}
\]

## 7. Structural consequence

The hard residue class can force enough positive-character factors into a moving linear form to saturate the entire positive kernel at a larger modulus.

Once that happens:

- reciprocal lanes become exact external-nonresidue detectors;
- forward lanes either solve immediately when `p` is a nonresidue modulo `d`, or become exact external-nonresidue detectors when `p` is a residue modulo `d`.

The next global target is to classify `(hard class, d, lane)` triples with forced kernel saturation and then prove that some corresponding lane must fire. This separates a finite local group problem from the remaining universal factor-existence problem.
