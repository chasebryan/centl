# Asymptotic skeleton of Type A/B ancestry shadows

**Status:** proved universal structural theorem  
**Date:** 2026-08-14  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this theorem classifies the prime-factor skeleton of unrestricted full-shadow ancestry children. It does not classify all smooth exceptional children, prove universal Direct-Shadow Completeness, López Type A/B coverage, or the Erdős-Straus conjecture.

Read with:

- [ANCESTRY-DIVISOR-CHILD-THEOREM.md](ANCESTRY-DIVISOR-CHILD-THEOREM.md)
- [PRIME-CHILD-SHADOWS.md](PRIME-CHILD-SHADOWS.md)
- [QUOTIENT-9-RIGIDITY.md](QUOTIENT-9-RIGIDITY.md)

## 1. Setup

Fix positive integers `s` and `j`, set

\[
Q=4s+1,
\qquad
K=Qj-s,
\qquad
m=4j-1.
\]

Then

\[
4K-1=Qm
\]

and

\[
\boxed{K=sm+j}.
\]

Hence

\[
K\equiv j\pmod m
\]

and

\[
\boxed{\gcd(j,K)=\gcd(j,s).}
\]

Let

\[
S_j=-T_j=\{e,4e\pmod m:e\mid j\}.
\]

Full unrestricted shadowing is equivalent to

\[
\boxed{
E\bmod m\in S_j
\quad\text{for every divisor }E\mid K.
}
\]

Assume throughout the main theorem that

\[
\boxed{j\ge s+1.}
\]

This simple range is not claimed optimal; it is chosen because it makes the size separation uniform.

## 2. Size separation

### Lemma 1

For `j>=s+1`,

\[
\boxed{m>s}
\]

and

\[
\boxed{K<m^2.}
\]

### Proof

The first inequality is immediate:

\[
m=4j-1\ge4s+3>s.
\]

For the second,

\[
\begin{aligned}
m^2-K
&=(4j-1)^2-((4s+1)j-s)\\
&=16j^2-(4s+9)j+(s+1).
\end{aligned}
\]

At `j=s+1` this equals

\[
(s+1)(12s+8)>0.
\]

The quadratic is increasing for `j>=s+1` because

\[
32j-(4s+9)>0.
\]

Thus `K<m^2`. QED.

## 3. Small new prime factors cannot occur

### Lemma 2

Assume full shadowing. If a prime

\[
\ell\mid K
\]

satisfies

\[
1<\ell<m,
\]

then

\[
\boxed{\ell\mid j}
\]

and therefore

\[
\boxed{\ell\mid s}.
\]

### Proof

Because `ell` is prime and lies strictly between `1` and `m`, membership in `S_j` can occur only as a plain divisor of `j`.

Indeed:

- if `ell` is odd, it cannot equal `4e` for an integer `e`;
- if `ell=2`, it also cannot equal `4e`;
- for a proper divisor `e<j`, `4e<m` and is divisible by `4`;
- the endpoint `e=j` gives `4j mod m = 1`.

Thus full shadowing forces `ell|j`.

But `ell|K` as well, so

\[
ell\mid\gcd(j,K)=\gcd(j,s),
\]

and hence `ell|s`. QED.

## 4. At most one prime outside the shift support

Call a prime factor of `K` **external** if it does not divide `s`.

### Lemma 3

Under full shadowing and `j>=s+1`, there is at most one external prime factor of `K`, counted with multiplicity.

### Proof

By Lemma 2, every external prime factor is at least `m`.

If two external prime factors occurred, including two copies of the same prime, then

\[
K\ge m^2,
\]

contradicting Lemma 1. QED.

Therefore either:

1. `K` is `s`-smooth; or
2. there is a unique external prime `p`, appearing to exponent one, and
   \[
   \boxed{K=Bp}
   \]
   where every prime factor of `B` divides `s`.

Since `p>=m`,

\[
B=K/p\le K/m=s+j/m<s+1.
\]

Hence

\[
\boxed{B\le s.}
\]

This is a strong finite bound on the entire shift-supported cofactor.

## 5. Odd prime exponents in the cofactor

Assume the nonsmooth case

\[
K=Bp.
\]

### Lemma 4

For every odd prime `r|s`,

\[
\boxed{v_r(B)\le v_r(s).}
\]

### Proof

Suppose

\[
v_r(B)>v_r(s)=a.
\]

Then

\[
x=r^{a+1}
\]

is a divisor of `K`.

Because `x<=B<=s<m`, full shadowing requires `x in S_j` as an ordinary integer residue.

From

\[
\gcd(j,K)=\gcd(j,s),
\]

the common `r`-valuation is at most `a`. Therefore

\[
x\nmid j.
\]

But `x` is odd, so it cannot equal `4e` for a divisor `e|j`. Hence `x notin S_j`, contradiction. QED.

Thus no odd shift prime can occur in `B` to an exponent larger than its exponent in `s`.

## 6. The only possible exponent defect is dyadic

Let

\[
a=v_2(s).
\]

If `s` is odd, there is no dyadic issue and Lemma 4 already gives

\[
\boxed{B\mid s.}
\]

If `s` is even, suppose

\[
b=v_2(B)>a.
\]

The divisor

\[
x=2^b
\]

satisfies

\[
x\le B\le s<m.
\]

By the gcd identity, `x` does not divide `j`. Therefore its only possible membership in `S_j` is through

\[
x=4e,
\qquad e=2^{b-2}\mid j.
\]

But again the gcd identity gives

\[
v_2(j)\le a,
\]

so

\[
b-2\le a.
\]

Hence

\[
\boxed{b\le a+2.}
\]

Combining with Lemma 4:

### Theorem 1: general cofactor bound

In the nonsmooth case under full shadowing and `j>=s+1`,

\[
\boxed{K=Bp}
\]

with `p` prime, `p>=m`, and

\[
\boxed{B\le s,\qquad B\mid4s.}
\]

Every prime divisor of `B` also divides `j`.

Thus the only way `B` can fail to divide `s` is by carrying one or two additional powers of `2` beyond the dyadic exponent already present in `s`.

## 7. Odd-shift converse skeleton

When `s` is odd, the dyadic defect disappears.

Then

\[
B\mid s.
\]

Since every prime divisor of `B` divides `j`, and the exponent bound from Lemma 4 is already no larger than in `s`, we still need to ensure the full exponent occurs in `j`.

But `B|K` and `B|s`, so reducing

\[
K=(4s+1)j-s
\]

modulo `B` gives

\[
0\equiv j\pmod B.
\]

Therefore

\[
\boxed{B\mid j}.
\]

Hence

\[
\boxed{B\mid\gcd(j,s).}
\]

We obtain:

### Theorem 2: odd-shift asymptotic skeleton

Let `s` be odd and `j>=s+1`. If

\[
T_K\bmod(4j-1)\subseteq T_j,
\qquad
K=(4s+1)j-s,
\]

then exactly one of the following holds:

1. **smooth case:** every prime factor of `K` divides `s`;
2. **divisor-child case:**
   \[
   \boxed{K=a p}
   \]
   where
   \[
   \boxed{a\mid\gcd(j,s)}
   \]
   and `p` is prime.

The second case is exactly the family proved sufficient in [ANCESTRY-DIVISOR-CHILD-THEOREM.md](ANCESTRY-DIVISOR-CHILD-THEOREM.md).

Thus for odd ancestry shifts, above the explicit elementary threshold `j>=s+1`, the divisor-child family is the **only nonsmooth full-shadow mechanism**.

## 8. Consequences for the quotient ladder

### s = 1, Q = 5

The shift is odd and has no nontrivial smooth primes. The theorem leaves only

\[
K=p,
\]

recovering the `q=5` prime-only rigidity for all `j>=2`. Tiny `j` is checked separately in the existing exact theorem.

### s = 3, Q = 13

For `j>=4`, full shadowing implies either:

\[
K=3^u
\]

or

\[
K=p\quad\text{or}\quad K=3p
\]

with the `3p` case requiring `3|j`.

Operator-02's exact `q=13` classification proves that no smooth power exception survives, completing the finite small/smooth residue of the general theorem.

### s = 5, Q = 21

Without any dedicated `q=21` computation, the theorem already gives for `j>=6`:

\[
\boxed{
\text{full shadow}
\Longrightarrow
K=5^u
\text{ or }
K=p
\text{ or }
K=5p\ (5|j).
}
\]

This is a new theorem-level prediction for the next odd-shift ancestry quotient.

### s = 7, Q = 29

For `j>=8`:

\[
\boxed{
\text{full shadow}
\Longrightarrow
K=7^u
\text{ or }
K=p
\text{ or }
K=7p\ (7|j).
}
\]

Again no quotient-specific search is needed to obtain the skeleton.

## 9. Even shifts

For even `s`, Theorem 1 gives

\[
K=Bp,
\qquad
B\le s,
\qquad
B\mid4s,
\]

in every nonsmooth full-shadow case.

The observed `q=9` and `q=17` classifications show that the extra dyadic possibilities are usually eliminated, leaving `B|s`, with rare smooth power-of-two exceptions.

The remaining general even-shift theorem target is therefore sharply finite:

> classify whether a cofactor `B<=s` with `B|4s` but `B not|s` can ever occur in a nonsmooth full-shadow child, and classify the purely `s`-smooth children.

For fixed `s`, this is a finite set of cofactor shapes.

## 10. Why this matters

The ancestry shadow graph originally appeared to require a separate classification at each quotient

\[
5,9,13,17,21,25,29,\ldots
\]

The divisor-child theorem provided a universal sufficient family.

The present theorem supplies the converse skeleton:

\[
\boxed{
\text{full ancestry shadow}
\Longrightarrow
\begin{cases}
\text{shift-smooth child},\quad\text{or}\\
\text{one large prime}\times\text{a tiny shift-supported cofactor}.
\end{cases}
}
\]

For odd shifts, that tiny cofactor is exactly a divisor of `gcd(j,s)`.

So an infinite collection of quotient-by-quotient shadow problems has collapsed into:

1. one universal prime-times-divisor law;
2. one finite smooth-exception problem for each shift;
3. a small dyadic correction for even shifts.

This is a structural theorem about the ancestry skeleton of the Type A/B shadow graph.
