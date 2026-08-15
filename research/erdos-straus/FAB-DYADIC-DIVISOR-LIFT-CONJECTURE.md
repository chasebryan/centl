# Adaptive dyadic divisor-lift conjecture — falsified

**Status:** exact algebraic family retained; proposed universal existence statement **false**  
**Date:** 2026-08-15  
**Depends on:** `FAB-RECIPROCAL-DUALITY.md`, `FAB-RECIPROCAL-SIGNED-TARGET.md`, `FAB-RECIPROCAL-CHARACTER-TRANSPORT.md`  
**Counterexample:** `FAB-DYADIC-DIVISOR-LIFT-COUNTEREXAMPLE.md`

## 1. The exact adaptive family remains valid

Let `p` be Mordell-hard and put

\[
V=\frac{p-1}{2}.
\]

For any divisor `t|V`, define

\[
d_t=4t-1.
\]

Writing `V=ts` gives

\[
p=2ts+1,
\]

and the paired fab bases factor as

\[
\boxed{
X_t=\frac{p+d_t}{4}=\frac{t(s+2)}2,
}
\]

\[
\boxed{
Y_t=\frac{pd_t+1}{4}=\frac{t(d_t s+2)}2.
}
\]

If `epsilon=gcd(t,2)` and `g=t/epsilon`, then

\[
\boxed{g|X_t,\qquad g|Y_t.}
\]

Every prime factor of `g` divides `p-1` and is therefore a quadratic residue modulo `p`. The adaptive construction remains a useful exact way to inject known residue-side factors into both fab lanes.

## 2. The proposed universal statement

The now-falsified conjecture asserted that every Mordell-hard prime has some

\[
t\mid\frac{p-1}{2}
\]

for which at least one of

\[
\exists D\mid X_t^2:\quad4D\equiv-1\pmod{d_t}
\]

or

\[
\exists D\mid Y_t^2:\quad4D\equiv-1\pmod{d_t}
\]

holds.

This statement survived the complete hard-prime population through `50,000,000` and random much-higher probes, but it is false.

## 3. Exact counterexample

The Mordell-hard prime

\[
\boxed{p=9,078,191,439,529}
\]

satisfies

\[
\boxed{p\equiv289\pmod{840}.}
\]

Its adaptive dividend has the deliberately sparse factorization

\[
\boxed{
\frac{p-1}{2}
=4,539,095,719,764
=12\cdot378,257,976,647,
}
\]

where

\[
\boxed{378,257,976,647\text{ is prime}.}
\]

Hence the complete divisor lattice has only twelve nodes:

\[
1,2,3,4,6,12,
 r,2r,3r,4r,6r,12r,
\qquad r=378,257,976,647.
\]

Both the forward and reciprocal square-divisor criteria fail at **every one** of these twelve nodes.

Therefore the adaptive divisor-lift conjecture is false.

## 4. Why the counterexample is diagnostically valuable

The same prime is not difficult for the broader reciprocal-double-sieve language. It is solved already at

\[
\boxed{d=31,}
\]

in the forward lane.

Since

\[
31=4\cdot8-1,
\]

the rescuing parameter is

\[
\boxed{t=8.}
\]

But `8` does **not** divide `(p-1)/2`; it does divide `p-1`.

So the counterexample identifies the exact missing move:

\[
\boxed{
\text{the divisor lattice of }(p-1)/2
\text{ can be one dyadic level too shallow.}
}
\]

This mirrors the earlier finite failures of the still-smaller rule `t|(p-1)/4`, which were rescued by the first extra dyadic node `t=4`.

The evidence therefore suggests a dyadic-lift hierarchy, not the falsified fixed lattice.

## 5. Retained finite result

The statement

> every Mordell-hard prime `p<=50,000,000` has a successful node `t|(p-1)/2`

remains a valid finite computational result. In that cohort:

- hard primes: `93,457`;
- unresolved: `0`;
- largest first-success `t`: `38`;
- corresponding `d`: `151`;
- record specimen: `p=42,486,889`.

Those finite facts must not be promoted to the falsified universal conjecture.

## 6. Next target

The immediate replacement question is whether a controlled **dyadic closure** of the divisor lattice is sufficient:

\[
\boxed{
 t\mid 2^j\frac{p-1}{2}
}
\]

for a bounded or structurally selected `j`, with `d=4t-1`.

The new counterexample requires `j=1` because its rescue node is `t=8`.

No universal claim is made for `j=1` or any bounded `j`. It must be attacked adversarially before being elevated to a theorem target.
