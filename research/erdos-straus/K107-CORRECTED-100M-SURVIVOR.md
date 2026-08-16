# Corrected 100M corridor survivor and its exact `k=107` witness

**Status:** exact finite certificate  
**Date:** 2026-08-16  
**Machine certificate:** `verify_k107_survivor.py`  
**Claim boundary:** this concerns one prime in the corrected hard-prime census through `100,000,000`. It is not a universal shift bound and does not prove Erdős–Straus.

## 1. The corrected survivor

After the exact fixed-shift corridor through `k=63`, the corrected 100M hard-prime census has one remaining prime:

\[
\boxed{p=8,803,369.}
\]

Direct signed-box evaluation shows that this prime misses every admissible shift

\[
3,7,11,\ldots,103
\]

and first hits, among the configured shifts through 107, at

\[
\boxed{k=107.}
\]

This corrects the earlier finite attribution: `90,108,841` is the prime captured at `k=63`; `8,803,369` is the survivor that persists to 107.

## 2. The opening at 107

Put

\[
C_{107}=\frac{p+107}{4}.
\]

Then

\[
\boxed{C_{107}=2,200,869}
\]

with exact factorization

\[
\boxed{C_{107}=3^2\cdot11^2\cdot43\cdot47.}
\]

Choose the Type-II signed-box factors

\[
B=3^2\cdot43\cdot47=18,189,
\qquad
D=1,
\qquad
T=11^2=121.
\]

They satisfy

\[
BDT=C_{107}
\]

and, crucially,

\[
\boxed{B=18,189=107\cdot170-1.}
\]

Hence

\[
\boxed{BD^{-1}\equiv-1\pmod{107}.}
\]

This is exactly the Type-II target in the signed-box theorem.

Equivalently, in divisor-square coordinates the complementary divisor is

\[
d=11^2=121
\]

and

\[
d\equiv-C_{107}\pmod{107}.
\]

## 3. Exact Type-II reconstruction

Since

\[
107\mid B+D,
\]

put

\[
A=\frac{B+D}{107}=170.
\]

The standard Type-II identity gives

\[
\frac4p
=
\frac1{BDT}
+
\frac1{pADT}
+
\frac1{pABT}.
\]

For this prime:

\[
\boxed{
\frac4{8,803,369}
=
\frac1{2,200,869}
+
\frac1{181,085,300,330}
+
\frac1{3,293,760,527,702,370}.}
\]

`verify_k107_survivor.py` checks this equality with exact rational arithmetic.

## 4. Companion sequence immediately before the hit

For the same prime, the shifted companions from 63 through 107 are:

```text
k=63   C=2,200,858 = 2 * 11 * 71 * 1409             miss
k=67   C=2,200,859 = 719 * 3061                      miss
k=71   C=2,200,860 = 2^2 * 3^2 * 5 * 12227          miss
k=75   C=2,200,861 = 13 * 79 * 2143                  miss
k=79   C=2,200,862 = 2 * 601 * 1831                  miss
k=83   C=2,200,863 = 3 * 7 * 104803                  miss
k=87   C=2,200,864 = 2^5 * 68777                     miss
k=91   C=2,200,865 = 5 * 19 * 23167                  miss
k=95   C=2,200,866 = 2 * 3 * 366811                  miss
k=99   C=2,200,867 = 2200867                         miss
k=103  C=2,200,868 = 2^2 * 29 * 18973                miss
k=107  C=2,200,869 = 3^2 * 11^2 * 43 * 47           HIT Type II
```

The 107 opening is therefore not caused merely by an unusually smooth companion: several earlier companions are comparably structured. What is special is the exact multiplicative relation

\[
3^2\cdot43\cdot47\equiv-1\pmod{107}.
\]

That relation is the next theorem-mining object.

## 5. Research implication

The corrected finite corridor no longer suggests that `k=47` or any nearby character branch alone supplies a universal closure. Instead it exhibits a long chain of exact fixed-shift misses terminating in one particularly sparse Type-II congruence at 107.

The next useful question is not “is 107 a bound?” The finite data cannot justify that. The useful question is:

> what arithmetic restrictions imposed by the prior miss states make a later relation of the form `B ≡ -D mod k` unavoidable?

That is a cross-shift factorization-compatibility problem.

## 6. Reproduction

```sh
python3 research/erdos-straus/verify_k107_survivor.py
```

The certificate asserts the exact first-hit sequence through 107, the factorization of `C107`, the Type-II parameters `(A,B,D,T)=(170,18189,1,121)`, and the exact three-denominator identity.

Erdős–Straus remains open.
