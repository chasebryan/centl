# The reciprocal 3-7-15 nonresidue-detector triad

**Status:** proved exact theorem  
**Date:** 2026-08-15  
**Depends on:** `FAB-HARD-FIRST-FILTERS.md`, `FAB-RECIPROCAL-M7-CLASSIFICATION.md`, `FAB-RECIPROCAL-CHARACTER-TRANSPORT.md`  
**Claim boundary:** this identifies three exact sufficient-and-necessary local detector criteria. It does not prove that one of the three detectors fires for every Mordell-hard prime.

## 1. Setup

Let `p` be a Mordell-hard prime. Then

\[
\boxed{p\equiv1\pmod8.}
\]

For

\[
d\in\{3,7,15\},
\]

put

\[
\boxed{Y_d=\frac{pd+1}{4}.}
\]

The reciprocal fixed-`d` fab lane succeeds exactly when the bounded signed divisor set of `Y_d` modulo `d` contains `-1`.

The character-transport theorem gives, for every prime factor `r|Y_d`,

\[
\boxed{
\left(\frac r p\right)=\left(\frac r d\right),
}
\]

with the Jacobi symbol on the right when `d=15`.

## 2. Detector d=3

Since

\[
Y_3\equiv1\pmod3,
\]

the reciprocal `d=3` lane fails exactly when every prime factor of `Y_3` is

\[
1\pmod3.
\]

Equivalently it succeeds exactly when `Y_3` contains a prime factor

\[
r\equiv2\pmod3.
\]

By character transport this is exactly

\[
\boxed{
\left(\frac r p\right)=-1.
}
\]

Therefore

\[
\boxed{
\text{reciprocal }d=3\text{ succeeds}
\iff
Y_3\text{ has a }p\text{-quadratic-nonresidue prime factor}.
}
\]

## 3. Detector d=7

The exact reciprocal `d=7` failure classification has two formal families:

1. every prime factor lies in the quadratic-residue classes `{1,2,4} mod 7`;
2. exactly two prime-factor occurrences are `3 mod7` and every remaining occurrence is `1 mod7`.

But for a hard prime

\[
p\equiv1\pmod8,
\qquad
7\equiv7\pmod8,
\]

so

\[
7p+1\equiv0\pmod8
\]

and hence

\[
\boxed{2\mid Y_7.}
\]

Residue `2 mod7` is incompatible with the exceptional second failure family. Therefore that family can never occur on a Mordell-hard prime.

Thus reciprocal `d=7` fails exactly when every prime factor `r|Y_7` is a quadratic residue modulo `7`.

By character transport,

\[
\boxed{
\text{reciprocal }d=7\text{ succeeds}
\iff
Y_7\text{ has a prime factor }r
\text{ with }
\left(\frac r p\right)=-1.
}
\]

## 4. Detector d=15

The exact reciprocal `d=15` failure automaton has only two maximal failure kernels:

\[
H_{15}=\left\{r:\left(\frac r{15}\right)=+1\right\}
=\{1,2,4,8\},
\]

and

\[
H_3=\left\{r:\left(\frac r3\right)=+1\right\}
=\{1,4,7,13\}.
\]

The lane fails iff the complete prime support of `Y_15` is contained in one of these two kernels.

Again hard-prime parity removes one branch. Since

\[
15p+1\equiv0\pmod8,
\]

we have

\[
\boxed{2\mid Y_{15}.}
\]

But

\[
2\notin H_3.
\]

Therefore the `H_3` failure branch is impossible for every Mordell-hard prime.

The only surviving failure condition is

\[
\boxed{
\left(\frac r{15}\right)=+1
\quad\text{for every prime }r\mid Y_{15}.
}
\]

Character transport converts this to

\[
\boxed{
\left(\frac r p\right)=+1
\quad\text{for every prime }r\mid Y_{15}.
}
\]

Hence

\[
\boxed{
\text{reciprocal }d=15\text{ succeeds}
\iff
Y_{15}\text{ has a }p\text{-quadratic-nonresidue prime factor}.
}
\]

## 5. Triad theorem

Combining the three cases gives:

### Theorem — 3-7-15 nonresidue detectors

For every Mordell-hard prime `p` and each

\[
\boxed{d\in\{3,7,15\},}
\]

the reciprocal fixed-`d` fab lane succeeds **if and only if**

\[
\boxed{
\frac{pd+1}{4}
\text{ has a prime divisor }r
\text{ with }
\left(\frac r p\right)=-1.
}
\]

Thus these three fab lanes are not merely divisor-residue tests. They are exact detectors for the presence of an external quadratic nonresidue of the target prime inside three short linear forms.

## 6. Counterexample consequence

A hypothetical Mordell-hard prime counterexample must force

\[
\boxed{
\text{every prime factor of each of }
\frac{3p+1}{4},
\frac{7p+1}{4},
\frac{15p+1}{4}
\text{ to be a quadratic residue modulo }p.
}
\]

The three bases are all congruent modulo `p`:

\[
\frac{pd+1}{4}\equiv4^{-1}\pmod p,
\]

but their rational factorizations are different and have only fixed pairwise common support because

\[
\gcd\left(\frac{pd+1}{4},\frac{pe+1}{4}\right)
\mid\frac{|d-e|}{4}
\]

for `d,e=3 mod4`.

For the detector triad specifically,

\[
\gcd(Y_3,Y_7)=1,
\qquad
\gcd(Y_7,Y_{15})\mid2,
\qquad
\gcd(Y_3,Y_{15})\mid3.
\]

So, apart from the fixed tiny support `{2,3}`, a hypothetical counterexample requires three essentially disjoint linear forms to factor entirely into prime quadratic residues of `p`.

## 7. New proof target

The universal wall has therefore sharpened to a concrete statement:

> Prove that for every Mordell-hard prime `p`, at least one of
>
> \[
> \frac{3p+1}{4},
> \qquad
> \frac{7p+1}{4},
> \qquad
> \frac{15p+1}{4}
> \]
>
> contains a prime quadratic nonresidue modulo `p`,
>
> **or** prove a controlled extension of the detector set with the same exact property.

No assertion is made here that the three-element detector set is universally sufficient. The theorem is the exact detector equivalence, not the unresolved existence statement.
