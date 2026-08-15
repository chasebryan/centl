# Exact anchor-row domination inside the C1 residual core

**Status:** proved row-domination lemmas; hard-class union-shadow lemma for `j=322`  
**Date:** 2026-08-15  
**Project:** Free Computation Foundation / CENTL  
**Claim boundary:** these lemmas remove specific earlier rows from any simultaneous residual system once their anchors are avoided. They do not prove full C1, universal DSC-P, López coverage, or Erdős-Straus.

Read with:

- [ANCESTRY-DIVISOR-CHILD-THEOREM.md](ANCESTRY-DIVISOR-CHILD-THEOREM.md)
- [C1-CONDITIONED-FIBER-31113.md](C1-CONDITIONED-FIBER-31113.md)
- [CLASS-C-CENSUS-K1500.md](CLASS-C-CENSUS-K1500.md)

## 1. Pullback-domination principle

Let `a<b` be earlier Type A/B layers with moduli

\[
m_a=4a-1,
\qquad
m_b=4b-1.
\]

Suppose

\[
m_a\mid m_b
\]

and

\[
\boxed{T_b\bmod m_a\subseteq T_a.}
\]

Then for every integer `x`,

\[
x\bmod m_b\in T_b
\Longrightarrow
x\bmod m_a\in T_a.
\]

Therefore in **any** target progression `x=r+Ls`, once layer `a` is avoided, layer `b` is automatically avoided.

At parameter level the child forbidden pullback is consequently dominated by the ancestor pullback after projection to the common parameter line.

This is an exact logical implication, independent of probability, fiber bounds, or a finite search range.

## 2. The `j=179` row is dominated by `j=36`

We have

\[
4(179)-1=715=5\cdot143=5(4(36)-1).
\]

This is ancestry shift `s=1`, and the child depth

\[
179
\]

is prime.

By the prime-child theorem,

\[
\boxed{T_{179}\bmod143\subseteq T_{36}.}
\]

Hence every exact `j=179` hit is already a `j=36` hit.

So after the `j=36` mixed 11/13 row is avoided, `j=179` contributes no new restriction.

This explains its complete redundancy in the two `{11,13}` C1 systems and throughout the recurring `{3,11,13}` family.

## 3. The `j=205` row is dominated by `j=10`

We have

\[
4(205)-1=819=21\cdot39=21(4(10)-1).
\]

Here the ancestry shift is `s=5` because

\[
21=4(5)+1.
\]

Also

\[
205=5\cdot41,
\]

with `41` prime, and

\[
5\mid\gcd(10,5).
\]

The divisor-child theorem therefore gives

\[
\boxed{T_{205}\bmod39\subseteq T_{10}.}
\]

Thus the `j=205` 3/13 row is exactly redundant once the unary `j=10` row is avoided.

This is why it contributes no surviving conditioned 3-adic restriction in the `{3,11,13}` systems.

## 4. The `j=790` row is dominated by `j=10`

Likewise

\[
4(790)-1=3159=81\cdot39=81(4(10)-1).
\]

Now

\[
81=4(20)+1,
\]

so the ancestry shift is `s=20`.

The child depth factors as

\[
790=10\cdot79,
\]

with `79` prime, and

\[
10\mid\gcd(10,20).
\]

The divisor-child theorem gives

\[
\boxed{T_{790}\bmod39\subseteq T_{10}.}
\]

Therefore the apparently finer row whose residual 3-part reaches

\[
3^4=81
\]

is completely dominated by the `j=10` anchor.

Once `j=10` is avoided, `j=790` can introduce **no** new 3-adic obstruction at any depth or target progression where both rows are present.

This converts the finite observation

> the fine `3^4` row adds zero new hits

into an exact ancestry theorem.

## 5. Hard-compatible union domination of `j=322`

The common triple row is

\[
j=322,
\qquad
m_{322}=1287=9\cdot11\cdot13.
\]

It is not fully shadowed by either `j=3` or `j=10` individually.

However, the Mordell-hard target classes satisfy

\[
\boxed{h\equiv1\pmod3.}
\]

Because

\[
\gcd(840,1287)=3,
\]

any hard-compatible `j=322` trap must therefore satisfy

\[
t\equiv1\pmod3.
\]

### Exact trap table

The 15 distinct residues in `T_322` are:

| `t` | `t mod 3` | `t mod 11 in T_3` | `t mod 39 in T_10` |
|---:|---:|:---:|:---:|
| 643  | 1 | no  | yes |
| 965  | 2 | yes | yes |
| 1103 | 2 | no  | no  |
| 1126 | 1 | no  | yes |
| 1195 | 1 | yes | no  |
| 1231 | 1 | yes | no  |
| 1241 | 2 | no  | no  |
| 1259 | 2 | no  | no  |
| 1264 | 1 | yes | no  |
| 1273 | 1 | yes | no  |
| 1279 | 1 | no  | yes |
| 1280 | 2 | no  | no  |
| 1283 | 2 | yes | yes |
| 1285 | 1 | no  | yes |
| 1286 | 2 | yes | yes |

Every residue in `T_322` that is `1 mod 3` is caught by at least one of the two anchors:

\[
\boxed{
\{t\in T_{322}:t\equiv1\pmod3\}
\subseteq
\pi_{11}^{-1}(T_3)
\cup
\pi_{39}^{-1}(T_{10}).
}
\]

The only residues missed by both anchors are

\[
1103,1241,1259,1280,
\]

and all four are

\[
2\pmod3.
\]

### Hard-class union-shadow theorem

For every integer `x` with

\[
x\equiv1\pmod3,
\]

\[
\boxed{
x\bmod1287\in T_{322}
\Longrightarrow
\left(
x\bmod11\in T_3
\quad\text{or}\quad
x\bmod39\in T_{10}
\right).}
\]

Therefore, once the unary anchor rows `j=3` and `j=10` are avoided, the triple row `j=322` is automatically avoided for every Mordell-hard-compatible progression.

This is a genuine **two-anchor union shadow**, not a single-layer direct shadow.

## 6. Consequence for the `{3,11,13}` conditioned fiber

Before these lemmas, the recurring 3-coordinate appeared to receive restrictions from rows including

\[
25,88,205,322,520,790.
\]

The exact domination theorems remove:

\[
\boxed{205,322,790}
\]

once the unary anchors are safe.

The effective 3-adic rows are therefore reduced to

\[
\boxed{25,88,520}
\]

inside the frozen `{3,11,13}` C1 family.

This explains a substantial part of the observed overlap:

- `j=205` contributes no new restriction because it is a divisor-child of `j=10`;
- `j=790` contributes no fine `3^4` restriction because it is another divisor-child of `j=10`;
- `j=322` contributes no restriction on hard-compatible unary-safe pairs because its compatible trap fiber is union-shadowed by `j=3` and `j=10`.

## 7. The remaining 3-adic question is tiny

The entire finite mod-3/mod-9 extension problem is now concentrated in three rows:

1. `j=25`, residual support `3·11`;
2. `j=88`, residual support `3^2·13`;
3. `j=520`, residual support `3^2·11`.

The finite conditioned-fiber certificate shows:

- `j=25` supplies at most one forbidden residue modulo `3` after conditioning on the 11-coordinate;
- `j=520` never introduces a mod-3 class outside the class already forbidden by `j=25`;
- `j=88` can add at most one further residue modulo `9`.

Therefore at most four of the nine mod-9 classes are removed, leaving at least five.

The first and third bounds are small exact fiber statements. The middle containment is now the highest-value remaining row relation to prove universally in the relevant hard-compatible residual geometry.

## 8. New theorem target: projected ancestry domination

Although `j=520` is not fully shadowed by `j=25`, their moduli satisfy

\[
4(520)-1=21(4(25)-1).
\]

The finite C1 data indicate a weaker projection law:

> after the shared fixed factors are removed, every compatible `j=520` restriction on the mod-3 coordinate lies inside the mod-3 class already forbidden by `j=25`.

This is a **projected ancestry shadow** rather than full trap shadowing.

Proving that relation would turn the entire 3-adic conditioned-fiber lower bound of `5/9` from finite evidence into a theorem for this residual row pattern.

That is the next local algebra target.
