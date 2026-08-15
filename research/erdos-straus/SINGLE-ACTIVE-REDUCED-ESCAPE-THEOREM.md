# Universal reduced escape for a unique active fixed-negative row

**Status:** proved universal theorem  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** this theorem resolves the unique active fixed-negative row **locally**. It does not by itself solve the simultaneous nonfixed residual system, universal DSC-P, López Type A/B coverage, or Erdős-Straus.

Read with:

- [SINGLE-ACTIVE-EXCESS-PRIME-POWER.md](SINGLE-ACTIVE-EXCESS-PRIME-POWER.md)
- [SINGLE-ACTIVE-LOCAL-ESCAPE.md](SINGLE-ACTIVE-LOCAL-ESCAPE.md)
- [CLASS-C-CENSUS-K1500.md](CLASS-C-CENSUS-K1500.md)
- [TRAP-FIBER-BOUND.md](TRAP-FIBER-BOUND.md)

## 1. Setup

Fix a directly novel target candidate

\[
x=r+Ls,
\qquad
L=\operatorname{lcm}(840,4k-1),
\qquad
\gcd(r,L)=1.
\]

Suppose the active fixed-negative core has exactly one layer `j`.

Put

\[
m=4j-1,
\qquad
g=\gcd(L,m),
\qquad
q=m/g.
\]

Let

\[
R\subseteq\mathbb Z/q\mathbb Z
\]

be the exact forbidden pullback of `T_j` to the parameter `s`.

Direct novelty gives

\[
\boxed{R\ne\mathbb Z/q\mathbb Z.}
\]

The previously proved unique-active valuation theorem gives

\[
\boxed{q=p\text{ or }p^2}
\]

for one odd prime `p`.

## 2. Exact pullback injection

The compatible trap residues are

\[
U=\{u\in T_j:u\equiv r\pmod g\}.
\]

The pullback map is

\[
u\longmapsto
\frac{u-r}{g}
\left(\frac Lg\right)^{-1}
\pmod q.
\]

### Lemma 1

This map is injective on `U`.

### Proof

If two compatible trap residues `u_1,u_2` have the same pullback class, then

\[
\frac{u_1-u_2}{g}\equiv0\pmod q.
\]

Hence

\[
u_1-u_2\equiv0\pmod{gq}=0\pmod m.
\]

But `u_1,u_2` are residues modulo `m`, so they are equal. QED.

Therefore

\[
\boxed{|R|=|U|.}
\]

No trap residue “multiplies” into several parameter classes at one layer. The pullback is an affine relabeling of the compatible trap fiber.

## 3. Class A case

Assume

\[
p\mid L.
\]

This is Operator-02 Class A valuation excess.

Since `R` is proper, choose any

\[
s_0\notin R.
\]

Then the exact Type A/B condition at the unique active row is avoided.

Reducedness at `p` is automatic because

\[
r+Ls_0\equiv r\pmod p
\]

and

\[
p\mid L,
\qquad
\gcd(r,L)=1.
\]

Thus

\[
p\nmid r+Ls_0.
\]

So every Class-A unique active row has a reduced exact local escape.

This recovers and extends the earlier Class-A note.

## 4. Class B shape

Assume now

\[
p\nmid L.
\]

The unique-active prime-power theorem forces

\[
\boxed{q=p^2.}
\]

Because

\[
840\mid L,
\]

we also have

\[
p\notin\{2,3,5,7\}.
\]

All Type A/B moduli are odd, so `p` is odd and therefore

\[
\boxed{p\ge11.}
\]

We now bound the exact forbidden fiber.

## 5. Universal Class-B fiber bound

Since

\[
m=g p^2=4j-1,
\]

we have

\[
\boxed{j=\frac{gp^2+1}{4}}.
\]

Because `p^2=1 mod 4` and `m=3 mod 4`,

\[
g\equiv3\pmod4.
\]

Hence

\[
\frac jg
=
\frac{p^2}{4}+\frac{1}{4g}
\]

lies strictly between

\[
\frac{p^2}{4}
\quad\text{and}\quad
\frac{p^2}{4}+\frac1{12}.
\]

Since `p` is odd,

\[
p^2\equiv1\pmod4,
\]

so every fixed residue class modulo `g` contains at most

\[
\boxed{\frac{p^2+3}{4}}
\]

integers in the interval `1<=e<=j`.

Now split the Type A/B trap set into its two divisor families:

\[
T_j=\{-e:e\mid j\}\cup\{-4e:e\mid j\}.
\]

For a trap `-e` to lie in the compatible fiber `u=r mod g`, the divisor `e` must occupy one fixed residue class modulo `g`.

For a trap `-4e`, multiplication by `4` is invertible modulo odd `g`, so `e` again occupies one fixed residue class modulo `g`.

Therefore each family contributes at most

\[
\frac{p^2+3}{4}
\]

compatible traps.

By Lemma 1,

### Lemma 2

\[
\boxed{
|R|
\le
\frac{p^2+3}{2}.
}
\]

This bound does not use the divisor condition beyond the fact that divisors lie in `[1,j]`; actual trap fibers are often much smaller.

## 6. Reduced parameter classes in Class B

Since `p∤L`, the non-reduced condition is

\[
r+Ls\equiv0\pmod p.
\]

Because `L` is invertible modulo `p`, this excludes exactly one residue class modulo `p`.

Thus among the `p^2` parameter classes modulo `p^2`, the number that remain reduced is exactly

\[
\boxed{p^2-p=p(p-1).}
\]

For every

\[
p\ge5,
\]

\[
\frac{p^2+3}{2}<p^2-p,
\]

because the difference is

\[
\frac{(p-3)(p+1)}2>0.
\]

Class B has `p>=11`, so the inequality is strict.

Consequently the forbidden set `R` is too small to contain all reduced parameter classes.

There exists at least one

\[
s_0\pmod{p^2}
\]

such that simultaneously

\[
s_0\notin R
\]

and

\[
p\nmid r+Ls_0.
\]

## 7. Main theorem

### Theorem

For every directly novel candidate with

\[
\boxed{|\mathcal N^{\rm act}_{k,r}|=1,}
\]

the unique active fixed-negative layer admits an exact reduced local escape.

This holds in both valuation regimes:

\[
\boxed{
\begin{array}{ll}
\text{Class A:}&\text{direct novelty + fixed reducedness},\\[1mm]
\text{Class B:}&q=p^2,\ p\ge11,\ |R|<(p^2-p).
\end{array}}
\]

Therefore the unique active fixed-negative row is **never by itself a reduced covering obstruction**.

QED.

## 8. What this does and does not prove

This closes the local gap that had previously been phrased as:

> could a proper Type A/B pullback still contain every reduced parameter class?

For a unique active fixed-negative row, the answer is now:

\[
\boxed{\text{No.}}
\]

But C1 contains a second layer of difficulty.

The independently verified `k<=1500` census showed that after fiber peeling, the residual system is dominated by **nonfixed earlier rows**:

```text
single-active candidates:                       2,770
nonempty final fiber kernels:                   1,480
unique active row survives final kernel:            18
nonfixed residual edge incidences:             69,672
```

So the remaining C1 problem is not local escape from the active row.

It is:

\[
\boxed{
\text{coordinate the guaranteed active-row escape}
\text{ with all surviving nonfixed exact rows.}
}
\]

That is the correct next theorem target.

## 9. Falsifier

A counterexample to this theorem would require either:

1. a unique-active quotient not of shape `p` or `p^2`, contradicting the earlier theorem;
2. a Class-A row where reducedness changes with `s`, contradicting `p|L`;
3. a Class-B exact trap fiber with more than `(p^2+3)/2` compatible trap residues;
4. or an arithmetic error in the parameter-fiber injection.

Each condition is explicit and independently testable.

## 10. Significance

The Class-C program has now separated two logically different phenomena:

\[
\boxed{
\text{fixed-negative activity}
\ne
\text{final exact residual obstruction}.
}
\]

The first is completely locally escapable in the single-active regime.

The unresolved structure therefore lives in the interaction graph of the remaining nonfixed exact rows, not in a mysterious local failure of the unique character-negative row.

This removes one entire candidate obstruction mechanism from C1.
