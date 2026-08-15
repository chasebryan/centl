# q=3 Fiber Injectivity and Three-Layer Minimum

**Status:** proved universal theorem  
**Date:** 2026-08-15  
**Depends on:** `REDUCED-PARAMETER-DOMAIN.md`, `Q3-ABSORPTION.md`, `Q3-WEAK-REDUNDANCY.md`, `Q3-POINTWISE-ABSORPTION.md`  
**Claim boundary:** proves that every q=3 Type A/B pullback is a singleton or empty and therefore that a corrected-domain q=3 cover needs at least three distinct layers. It does not rule out such a three-layer cover universally and does not prove DSC-P, López-all-primes, or Erdős-Straus.

---

## 1. Setup

Let

\[
m=4j-1
\]

and assume

\[
3\mid m.
\]

Put

\[
\boxed{n=m/3.}
\]

The Type A/B trap set is

\[
T_j=\{-e,-4e\pmod m:e\mid j\}.
\]

It is convenient to negate it:

\[
S_j=-T_j=\{e,4e\pmod m:e\mid j\}.
\]

Since

\[
4j=m+1=3n+1,
\]

we have

\[
\boxed{j=(3n+1)/4<n}
\]

for every nontrivial case.

---

## 2. Theorem — trap reduction modulo n is injective

### Theorem

The natural reduction map

\[
\boxed{T_j\longrightarrow\mathbb Z/n\mathbb Z}
\]

is injective.

Equivalently, if two Type A/B traps agree modulo `n=m/3`, then they were already the same trap modulo `m`.

### Proof

Work with the normalized set `S_j=-T_j`.

For every divisor `e|j`:

- the plain value `e` satisfies `1<=e<=j<n`;
- if `e<j`, then `e<=j/2`, hence
  \[
  4e\le2j=(3n+1)/2<2n;
  \]
- if `e=j`, then
  \[
  4e=4j=m+1\equiv1\pmod m,
  \]
  which is already the same normalized trap as the divisor `1`.

Thus every distinct element of `S_j` has a representative in `[1,2n)`.

Suppose two distinct representatives are congruent modulo `n`. Their difference must therefore be exactly `n` or `-n`.

There are only three structural cases.

### Case A: plain/plain

If

\[
e-f=\pm n,
\]

then `|e-f|<n` because `e,f<n`, impossible.

### Case B: fourfold/fourfold

If

\[
4e-4f=\pm n,
\]

then the left side is divisible by `4`, while `n` is odd. Impossible.

### Case C: fourfold/plain

The only potentially nontrivial equation is

\[
4e-f=n.
\]

(The opposite sign would force the plain divisor to exceed `n>j`; the other mixed orientation is symmetric.)

Since `f>0`, this gives

\[
4e>n>\frac{4j-1}{3},
\]

so

\[
e>j/3-1/12.
\]

As `e` is a proper divisor of `j` in a genuinely distinct mixed pair, the integer quotient `j/e` is at least `2`. The displayed lower bound forces

\[
\boxed{j/e=2},
\]

so `e=j/2`.

Substituting into `4e-f=n` gives

\[
f=2j-n
=2j-\frac{4j-1}{3}
=\frac{2j+1}{3}.
\]

For `j>1`, this satisfies

\[
\frac j2<f<j.
\]

But a positive proper divisor of `j` cannot lie strictly between `j/2` and `j`. Contradiction.

The tiny endpoint is checked by the same formulas and produces no distinct trap collision.

Therefore no two distinct normalized traps can agree modulo `n`. Negation is a bijection, so the same is true for `T_j`. QED.

---

## 3. Corollary — every q=3 pullback is empty or singleton

Fix a candidate progression

\[
x(s)=r+Ls
\]

with

\[
q_j=\frac{m_j}{\gcd(L,m_j)}=3.
\]

Then

\[
\gcd(L,m_j)=n=m_j/3.
\]

The three parameter classes modulo `3` map bijectively to the three lifts modulo `m_j` above the single residue `r mod n`.

By the theorem, at most one of those three lifts can belong to `T_j`.

Hence

\[
\boxed{|R_j|\le1.}
\]

This is universal. No hard-class assumption, finite search, or primitivity assumption is needed.

---

## 4. Corollary — corrected q=3 coverage needs at least three layers

For the Mordell-hard Type A/B program,

\[
3\mid840\mid L.
\]

The exact Dirichlet condition therefore imposes **no forbidden parameter class modulo 3** merely for reducedness. The local reduced domain is the full ring

\[
\boxed{\mathbb Z/3\mathbb Z=\{0,1,2\}.}
\]

Since every q=3 layer forbids at most one class, any q=3 cover of the corrected domain requires at least three distinct nonempty layers:

\[
\boxed{
\bigcup_jR_j=\mathbb Z/3\mathbb Z
\Longrightarrow
\#\{j:R_j\ne\varnothing\}\ge3.
}
\]

In particular, the old two-singleton `R={1}` / `R={2}` complementary-pair obstruction was an artifact of restricting the parameter to units modulo 3. In the exact Dirichlet domain it leaves the third class.

---

## 5. Combination with the absorption hierarchy

On a directly novel candidate:

1. **strong q=3 descendants** cannot be nonempty (`Q3-ABSORPTION.md`);
2. **weak q=3 descendants** add no new residue (`Q3-WEAK-REDUNDANCY.md`);
3. every actually used trap must be **pointwise primitive** (`Q3-POINTWISE-ABSORPTION.md`);
4. by this theorem, every surviving layer contributes at most one class.

Therefore a genuine directly novel q=3 obstruction has the exact form

\[
\boxed{
\text{three or more pointwise-primitive base singleton rows}
\text{ whose classes cover }\{0,1,2\}.
}
\]

That is now the residual q=3 theorem target.

---

## 6. Proof-mining observation

A direct reconstruction of the corrected primitive system through target depth `k<=100000` found no admissible candidate with three primitive q=3 classes simultaneously present. This observation is **not** promoted here as a certificate because the present file is a universal theorem note; it is recorded only as motivation for the next independently replayed finite attack.

The theorem burden is now much narrower than the former shared-factor problem: explain why three pointwise-primitive base singleton rows cannot align on one directly novel admissible target, or find the first such alignment and analyze it.
